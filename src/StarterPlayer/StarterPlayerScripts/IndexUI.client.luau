--!strict
-- Steal a Seed :: IndexUI
--
-- THE PLANT ALMANAC. Every species in the game, biome by biome on one page, and
-- which of them you have actually grown.
--
-- What is in your dirt right now is GardenUI. This is the sheet.
--
--==============================================================================
-- COMPACT, IN THE INVENTORY'S LOOK (2026-10-03, the owner's redesign)
--
-- It was three panels from the 2026-09-11 mockup: wide biome tabs across the
-- top, a scenery banner, a shelf of five sunlit cards with a trophy slot, and a
-- permanent showcase with a large 3D plant. On a landscape phone the header,
-- the tabs and the banner took most of the height and the collection got what
-- was left. Now, in the approved inventory's forest slate (MenuKit, BagLook):
--
--   header    one short row: the title, a search box, All / Grown / Missing,
--             the close
--   the page  ONE scrolling page since 2026-10-06 (the owner: the Shop's one
--             page, "also apply it on index too"): every biome down it in road
--             order, over the studded baseplate (MenuKit.baseplate). Each
--             biome's heading is its slim row -- "Starbloom · 2/5 Grown", a
--             bar, the biome's harvest (cash + speed) and its own CLAIM -- and
--             under it its small, roughly square cards: the plant (or its
--             silhouette), its name over at most two lines, its rarity, a check
--             once grown. Columns from the width and a readable minimum card
--             (MenuLayout.grid), never a fixed count. A search keeps the biomes
--             it found something in; a filter shows every heading. From
--             2026-10-03 to 2026-10-06 it showed one biome at a time, chosen in
--             a dropdown or a sidebar
--   detail    a tap opens the plant's page IN the panel, with Back: the still
--             3D plant on its moss pedestal, name, rarity, biome, whether it is
--             grown, its base Garden Yield. Back returns to the same filter,
--             search and scroll
--
-- WHERE IT STANDS is MenuLayout's: between the rails on a desktop (they stay
-- pressable), the whole safe area on a phone -- and then the rail layer steps
-- under the panel while it is open (UIKit.coverRail), so Walk Mode, the
-- Garden and Bag buttons and the admin button never stand over it or take its
-- taps. They come back as they were when it closes.
--
--==============================================================================
-- A CARD WEARS ITS RARITY, GROWN OR NOT (the approved rule, 2026-09-11)
--
-- An undiscovered card shows its rarity colour and word and a dark silhouette,
-- so a player can see what KIND of find a biome is still missing. The name and
-- the plant's own colours stay hidden until it has been grown -- and a search
-- never finds a plant by a name the player has not seen (AlmanacView).
--
-- The rarity still means the FORM -- how often that shape drops -- and never
-- ColorForKg, which is what one pod happens to weigh.
--
--==============================================================================
-- SEEN MEANS GROWN, ON A PLOT YOU OWNED
--
-- Not carried, not stolen. PlantService writes the Almanac when a plant hatches
-- on its owner's plot, and it rides down in the profile ProfileUpdated already
-- pushes, beside the Mastery set of biome harvests already paid.
--
--==============================================================================
-- ONE VERB, AND THE SERVER DECIDES
--
-- CLAIM sends GameConfig.Almanac.ClaimAction and a biome id on GameEvent, and
-- nothing else. AlmanacService checks the profile it holds, pays BiomeData's
-- reward through the two faucets and answers on the same remote. This file only
-- ever shows what the profile says.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local AlmanacData = require(Shared:WaitForChild("AlmanacData"))
local AlmanacView = require(Shared:WaitForChild("AlmanacView"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local ShopCatalog = require(Shared:WaitForChild("ShopCatalog"))
-- THE POD GUIDE (2026-10-09, KB/POD-GUIDE-PLAN.md): each plant's chance in its
-- nest, the sizes' odds and worth, and the plant's own pod (ItemArt's picture).
local PodGuide = require(Shared:WaitForChild("PodGuide"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ALMANAC = GameConfig.Almanac
local RAIL = GameConfig.Rail
local CARD = GameConfig.Card
local ATTR = GameConfig.Attributes
local LOOK = MenuKit.Look
local GUIDE = GameConfig.PodGuide
local PANEL_NAME = "Index"

local WHITE = Color3.fromRGB(255, 255, 255)

--==============================================================================
-- THE MEASUREMENTS (logical units; where the blocks go is MenuLayout's)
--==============================================================================
local IDX = MenuLayout.Index
local CARD_GAP = IDX.CardGap
local GRID_INSET = IDX.GridInset
-- How much of its viewport a creature fills on a card and on the detail stage.
local CARD_FILL = 0.84
local STAGE_FILL = 0.6
-- How long a CLAIM waits for the server's answer before letting go.
local CLAIM_PATIENCE = 5

-- ZIndexBehavior is GLOBAL on this ScreenGui. The modal's chrome is 1-3 (its
-- close 4-7); everything here sits above it.
local Z = 6

local road = AlmanacView.road()
-- Each biome's uploaded picture, by its stable id (2026-10-04): beside its name
-- wherever the Almanac names a biome. A picture that never loads leaves the
-- name alone, and MenuKit.picture reports its id once.
local BIOME_ICONS: { [string]: string } = ALMANAC.BiomeIcons
local ICON = 20

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedIndex")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedIndex"
gui.ResetOnSpawn = false
-- ONE ABOVE THE HOTBAR'S 30. Level with it, the engine was free to draw the strip
-- over the open panel, and did. Above it, the panel and its dimmer cover the
-- strip as the Shop (32) always has.
gui.DisplayOrder = 31
gui.Parent = playerGui

--==============================================================================
-- THE BUTTON
--
-- The owner's approved artwork (2026-09-24): the purple book and the word in
-- one square picture, its rim static -- only the Shop's turns. The picture
-- carries its own outline, face and label, so nothing of ours is drawn with it.
--==============================================================================
local button = UIKit.railButton(playerGui, {
	name = "IndexButton",
	art = RAIL.IndexArt,
	-- INDEX on a plate until a picture has loaded here (UIKit.railFallback).
	fallback = RAIL.Words.Index,
})
button.Position = UDim2.new(0, RAIL.Inset, 0, RAIL.Inset)

local badge, badgeCount = UIKit.badge(button, RAIL.Badge)

--==============================================================================
-- WHERE IT SITS IS ASKED OF HudLayout AND APPLIED HERE
--
-- Drawn as the owner's studded picture on every screen (a phone's since
-- 2026-10-05, the rest since 2026-10-06). The top of the left rail on a
-- desktop; on a touch screen the top-right row's left end, beside Garden
-- (HudLayout, THE PHONE'S SIDEBARS), standing in the frame RailDrawerUI hides
-- while a centre panel is open -- still this script's button and badge. The
-- badge is tucked into its top-LEFT corner there, Garden's being just right of
-- it. Asked again only when this ScreenGui's size changes.
--==============================================================================
local function placeButton()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	UIKit.railShape(button, Vector2.new(layout.index.w, layout.index.h))
	UIKit.railPicture(button, RAIL.StuddedIndexArt, 1)
	button.Parent = if layout.sidebar then UIKit.railDock(playerGui) else UIKit.railLayer(playerGui)
	button.Position = HudLayout.place(layout.index, Vector2.zero, layout.safe)
	-- On a phone the owner's small pill on its top-RIGHT corner, level with its
	-- top (2026-10-09); at the top of a desktop's or a TV's right-edge column
	-- tucked into its top-LEFT corner; in compact's top row tucked into its
	-- top-right one (HudLayout.badges).
	local column = layout.column == true
	if layout.sidebar then
		UIKit.railBadge(badge, true, "right", true, true)
	else
		UIKit.railBadge(badge, layout.compact or column, if column then "left" else "right")
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeButton)
placeButton()

--==============================================================================
-- THE PANEL: the Bag's shell, a short header, the plants' own icon by the title
--==============================================================================
-- On the studded kit's green collection band (2026-10-08, the owner: "do the
-- index and bag next"; MenuKit.studdedTheme, GameConfig.StuddedLook.Index).
local menu = MenuKit.modal(gui, PANEL_NAME, "Plant Almanac", GameConfig.BagLook.IconImages.plants, nil, nil, nil,
	MenuKit.studdedTheme(GameConfig.StuddedLook.Index))
-- This gui holds only the panel, so it takes the player's menu size whole.
UIKit.menuGui(gui, Vector2.new(300, 220))
local modal = menu.modal
local body = menu.body

-- A controller's selection starts on the first card (PadFocus reads this).
local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Parent = modal.shell

--==============================================================================
-- STATE
--==============================================================================
local almanac: { [string]: boolean } = {}
local mastery: { [string]: boolean } = {}
-- Biomes whose CLAIM has been sent and not yet answered.
local pending: { [string]: boolean } = {}

local activeBiome: string = road[1].Id
local filterNow: AlmanacView.Filter = "all"
local queryNow = ""
local detailId: string? = nil
local panelOpen = false
local openedBefore = false
local current: { AlmanacView.Entry } = {}
local searching = false

local function stateOf(biomeId: string): string
	return AlmanacData.ClaimState(almanac, mastery, biomeId)
end

--==============================================================================
-- THE HEADER'S CONTROLS (the title and the close are the modal's own)
--==============================================================================
local paint: () -> ()
local relayout: () -> ()
local resetScroll: () -> ()
local requestClaim: (string) -> ()

local search = MenuKit.search(body, Z, "Search")
local filter = MenuKit.segmented(body, Z, AlmanacView.Filters :: { string }, AlmanacView.FilterLabels)

--==============================================================================
-- THE PAGE (2026-10-06): every biome, one list, over the baseplate
--
-- A biome is its heading -- the row that was the one chosen biome's progress
-- row: its picture, "Starbloom · 2/5 Grown", a bar, its harvest (the same two
-- numbers AlmanacService pays, with the cash pack's coins and the catalogue's
-- speed shoe) and its own CLAIM -- and under it a grid of its cards. The
-- biomes follow one another down one scrolling list, in road order. Behind
-- the list, still while it scrolls, the studded baseplate where a plain light
-- well stood.
--==============================================================================
local plate = MenuKit.baseplate(body, Z - 1)
-- The studded kit's white body is the page now (2026-10-08): the plate is
-- still placed with the page, but not drawn, as in the Shop.
plate.Visible = false
local grid = Instance.new("ScrollingFrame")
grid.Name = "Almanac"
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.ScrollBarThickness = 5
grid.ScrollBarImageColor3 = LOOK.PlateEdge
grid.CanvasSize = UDim2.new()
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.ElasticBehavior = Enum.ElasticBehavior.Always
-- The cards are the controller's stops, never the list behind them.
grid.Selectable = false
grid.ZIndex = Z
grid.Parent = body
local gridPad = Instance.new("UIPadding")
gridPad.Parent = grid
local pageList = Instance.new("UIListLayout")
pageList.SortOrder = Enum.SortOrder.LayoutOrder
pageList.Padding = UDim.new(0, IDX.SectionGap)
pageList.Parent = grid

--==============================================================================
-- POD SIZES (the Pod Guide, 2026-10-09): over the first biome, the seven sizes
-- in their colours -- what each earns against Tiny, and its chance from the
-- first biome's nests to the last's (Mega and up grow likelier down the road;
-- each stand by an arch has its own biome's exact odds). Hidden while a search
-- runs. Every number is PodGuide's.
--==============================================================================
local podSizes = MenuKit.frame(grid, "PodSizes", Z + 1, LOOK.Well, LOOK.WellTransparency, 9)
podSizes.LayoutOrder = 0
podSizes.Size = UDim2.new(1, 0, 0, 74)
MenuKit.keyline(podSizes, LOOK.WellEdge, 1, 0.3)
do
	local head = MenuKit.text(podSizes, "Title", 15, LOOK.Text, Z + 2)
	head.Position = UDim2.fromOffset(10, 3)
	head.Size = UDim2.new(1, -20, 0, 18)
	head.TextXAlignment = Enum.TextXAlignment.Left
	local first, last = road[1], road[#road]
	head.Text = string.format("%s  <font color=\"#%s\" size=\"12\">income vs Tiny \u{00B7} chance in %s \u{2192} %s</font>",
		GUIDE.Words.SizesTitle, LOOK.Muted:ToHex(), first.DisplayName, last.DisplayName)
	head.RichText = true
	local fromRows, toRows = PodGuide.sizes(first.Id), PodGuide.sizes(last.Id)
	local count = #fromRows
	for i, s in ipairs(fromRows) do
		local cell = MenuKit.frame(podSizes, "Size" .. i, Z + 2)
		cell.Position = UDim2.new((i - 1) / count, 4, 0, 22)
		cell.Size = UDim2.new(1 / count, -8, 0, 48)
		local name = MenuKit.text(cell, "Name", 13, s.colour, Z + 3)
		name.Size = UDim2.new(1, 0, 0, 15)
		name.TextScaled = true
		local fit = Instance.new("UITextSizeConstraint")
		fit.MaxTextSize = 13
		fit.MinTextSize = 9
		fit.Parent = name
		name.Text = string.upper(s.name)
		local worth = MenuKit.text(cell, "Worth", 15, LOOK.Money, Z + 3)
		worth.Position = UDim2.fromOffset(0, 15)
		worth.Size = UDim2.new(1, 0, 0, 17)
		worth.Text = PodGuide.times(s.worth)
		local odds = MenuKit.body(cell, "Chance", 11, LOOK.Muted, Z + 3)
		odds.Position = UDim2.fromOffset(0, 32)
		odds.Size = UDim2.new(1, 0, 0, 14)
		odds.TextScaled = true
		local oddsFit = Instance.new("UITextSizeConstraint")
		oddsFit.MaxTextSize = 11
		oddsFit.MinTextSize = 8
		oddsFit.Parent = odds
		odds.Text = PodGuide.odds(s.chance) .. "\u{2192}" .. PodGuide.odds(toRows[i].chance)
	end
end

type Section = {
	frame: Frame,
	heading: Frame,
	text: TextLabel,
	icon: Frame?,
	bar: Frame,
	barFill: Frame,
	reward: Frame,
	cashIcon: Frame,
	cashValue: TextLabel,
	speedIcon: Frame,
	speedValue: TextLabel,
	claim: MenuKit.Button,
	shake: () -> (),
	shelf: Frame,
	cells: UIGridLayout,
}
local sections: { [string]: Section } = {}

for order, biome in ipairs(road) do
	local frame = MenuKit.frame(grid, "Biome_" .. biome.Id, Z + 1)
	frame.LayoutOrder = order
	frame.Size = UDim2.new(1, 0, 0, 0)
	frame.AutomaticSize = Enum.AutomaticSize.Y
	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, IDX.HeadingGap)
	list.Parent = frame
	local heading = MenuKit.frame(frame, "Heading", Z + 1, LOOK.Well, LOOK.WellTransparency, 9)
	heading.LayoutOrder = 1
	MenuKit.keyline(heading, LOOK.WellEdge, 1, 0.3)
	local text = MenuKit.text(heading, "Count", 15, LOOK.Text, Z + 2)
	text.TextXAlignment = Enum.TextXAlignment.Left
	text.RichText = true
	local image = BIOME_ICONS[biome.Id]
	local icon: Frame? = nil
	if image then
		local pic = MenuKit.picture(heading, image, nil, Z + 3)
		pic.Name = "BiomeIcon"
		pic.AnchorPoint = Vector2.new(0, 0.5)
		pic.Size = UDim2.fromOffset(ICON, ICON)
		icon = pic
	end
	local bar = MenuKit.frame(heading, "Bar", Z + 2, LOOK.Bar, 0, 4)
	bar.AnchorPoint = Vector2.new(0, 0.5)
	MenuKit.keyline(bar, LOOK.WellEdge, 1, 0.4)
	local barFill = MenuKit.frame(bar, "Fill", Z + 3, LOOK.Green, 0, 4)
	barFill.Size = UDim2.fromScale(0, 1)
	local reward = MenuKit.frame(heading, "Harvest", Z + 2)
	local cashIcon = MenuKit.picture(reward, GameConfig.Store.Icons.cash2, nil, Z + 3)
	cashIcon.AnchorPoint = Vector2.new(0, 0.5)
	cashIcon.Size = UDim2.fromOffset(20, 20)
	local cashValue = MenuKit.text(reward, "Cash", 14, LOOK.Money, Z + 3)
	cashValue.TextXAlignment = Enum.TextXAlignment.Left
	local speedIcon = MenuKit.picture(reward, ShopCatalog.SpeedIcon, GameConfig.Store.Icons.speed1, Z + 3)
	speedIcon.AnchorPoint = Vector2.new(0, 0.5)
	speedIcon.Size = UDim2.fromOffset(20, 20)
	local speedValue = MenuKit.text(reward, "Speed", 14, LOOK.Speed, Z + 3)
	speedValue.TextXAlignment = Enum.TextXAlignment.Left
	-- A reward to take: the studded gold CLAIM (the global UI pass, 2026-10-04),
	-- each biome's its own.
	local claim = MenuKit.button(heading, "Claim", Z + 2, "CLAIM", 15, { studs = true })
	local shake = UIKit.shake(claim.plate)
	local biomeId = biome.Id
	claim.hit.Activated:Connect(function()
		requestClaim(biomeId)
	end)
	local shelf = MenuKit.frame(frame, "Shelf", Z + 1)
	shelf.LayoutOrder = 2
	shelf.Size = UDim2.new(1, 0, 0, 0)
	shelf.AutomaticSize = Enum.AutomaticSize.Y
	local cells = Instance.new("UIGridLayout")
	cells.SortOrder = Enum.SortOrder.LayoutOrder
	cells.HorizontalAlignment = Enum.HorizontalAlignment.Left
	cells.Parent = shelf
	sections[biome.Id] = {
		frame = frame,
		heading = heading,
		text = text,
		icon = icon,
		bar = bar,
		barFill = barFill,
		reward = reward,
		cashIcon = cashIcon,
		cashValue = cashValue,
		speedIcon = speedIcon,
		speedValue = speedValue,
		claim = claim,
		shake = shake,
		shelf = shelf,
		cells = cells,
	}
end

local emptyLabel = MenuKit.body(body, "Empty", 15, LOOK.Muted, Z + 3)
emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
emptyLabel.TextWrapped = true
emptyLabel.Visible = false

resetScroll = function()
	grid.CanvasPosition = Vector2.zero
end

-- The page scrolled so a biome's heading stands at its top.
local function scrollToBiome(biomeId: string)
	local section = sections[biomeId]
	if not section or not section.frame.Visible then
		return
	end
	local k = math.max(HudLayout.scaleOf(grid), 1e-3)
	local y = (section.frame.AbsolutePosition.Y - grid.AbsolutePosition.Y) / k + grid.CanvasPosition.Y - GRID_INSET
	grid.CanvasPosition = Vector2.new(0, math.max(0, y))
end

--==============================================================================
-- ONE CARD PER SPECIES, BUILT THE FIRST TIME IT IS SHOWN
--
-- A card never changes species, so a search or a filter only shows and orders
-- cards that already exist. Its plant -- a real CreatureModel, 29 to 74 parts
-- -- is built the first time the card is ON SCREEN with the panel open, and
-- kept: the same twenty-five models the old shelf built, and never more.
--
-- THE SILHOUETTE IS A TINT. An undiscovered plant is the same model with the
-- viewport's ImageColor3 taken down to near black, so growing one costs no
-- rebuild -- the tint lifts.
--==============================================================================
type Card = {
	holder: Frame,
	button: TextButton,
	edge: UIStroke,
	-- The face's white-to-mint gradient, tinted by the species' rarity.
	tint: UIGradient,
	well: Frame,
	accent: Frame,
	view: ViewportFrame,
	name: TextLabel,
	nameFit: UITextSizeConstraint,
	rarity: TextLabel,
	check: Frame,
	place: Frame,
	fxText: RarityFX.Handle,
	fxEdge: RarityFX.Handle,
	-- A GROWN card's still rarity band, Common to Legendary (2026-10-10).
	ring: Frame,
	species: any,
	built: boolean,
}
local cards: { [string]: Card } = {}
local cardW, cardH, previewH = 130, 130, 78

local openDetail: (any) -> ()

local function tintView(view: ViewportFrame, known: boolean)
	view.ImageColor3 = if known then WHITE else ALMANAC.Silhouette
	view.ImageTransparency = if known then 0 else 0.1
end

local function shapeCard(c: Card)
	c.well.Position = UDim2.fromOffset(4, 4)
	c.well.Size = UDim2.fromOffset(cardW - 8, previewH)
	c.name.Position = UDim2.fromOffset(5, 4 + previewH + 3)
	c.name.Size = UDim2.fromOffset(cardW - 10, 30)
	c.rarity.Position = UDim2.fromOffset(5, cardH - 19)
	c.rarity.Size = UDim2.fromOffset(cardW - 10, 15)
end

local function cardFor(species: any): Card
	local made = cards[species.Id]
	if made then
		return made
	end
	local home = sections[species.Biome] or sections[road[1].Id]
	local holder = MenuKit.frame(home.shelf, "Card_" .. species.Id, Z + 1)
	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromScale(1, 1)
	face.BorderSizePixel = 0
	face.AutoButtonColor = false
	face.Text = ""
	face.ZIndex = Z + 1
	face.Parent = holder
	UIKit.corner(face, 8)
	local tint = MenuKit.cardFace(face)
	local edge = MenuKit.keyline(face, LOOK.CardEdge, 1, LOOK.CardEdgeTransparency)
	-- The plant stands in a DARK display window on the light card, as dark as
	-- the old preview, so an undiscovered plant's silhouette shows no more than
	-- it did.
	local well = MenuKit.frame(face, "Preview", Z + 2, LOOK.Window, 0, 6)
	well.ClipsDescendants = true
	local accent = MenuKit.frame(well, "Accent", Z + 4, WHITE, 0, 1)
	accent.AnchorPoint = Vector2.new(0.5, 1)
	accent.Position = UDim2.new(0.5, 0, 1, -2)
	accent.Size = UDim2.new(0.5, 0, 0, 2)
	-- How often a nest stocks this plant's own pod (the Pod Guide, 2026-10-09),
	-- low in the window, found or not -- what the stand by its arch says.
	local chance = MenuKit.text(well, "Chance", 12, WHITE, Z + 5)
	chance.AnchorPoint = Vector2.new(0, 1)
	chance.Position = UDim2.new(0, 5, 1, -6)
	chance.Size = UDim2.new(1, -10, 0, 14)
	chance.TextXAlignment = Enum.TextXAlignment.Left
	chance.Text = string.format(GUIDE.Words.CardChance, PodGuide.odds(PodGuide.chanceOf(species.Id)))
	local view = Instance.new("ViewportFrame")
	view.Name = "Plant"
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.5)
	view.Size = UDim2.new(1, -4, 1, -4)
	view.BackgroundTransparency = 1
	view.Ambient = CARD.Ambient
	view.LightColor = CARD.LightColour
	view.LightDirection = CARD.LightDirection
	view.ZIndex = Z + 3
	view.Parent = well
	local name = MenuKit.text(face, "Name", 13, LOOK.Text, Z + 5)
	name.TextWrapped = true
	name.TextScaled = true
	name.TextYAlignment = Enum.TextYAlignment.Top
	local nameFit = Instance.new("UITextSizeConstraint")
	nameFit.MaxTextSize = 14
	nameFit.MinTextSize = 10
	nameFit.Parent = name
	local rarity = MenuKit.text(face, "Rarity", 12, WHITE, Z + 5)
	rarity.TextTruncate = Enum.TextTruncate.AtEnd
	local rarityLine = rarity:FindFirstChildOfClass("UIStroke")
	-- Grown: a small green disc with a check, top right.
	local check = MenuKit.frame(face, "Grown", Z + 6, LOOK.Green, 0, 8)
	check.AnchorPoint = Vector2.new(1, 0)
	check.Position = UDim2.new(1, -3, 0, 3)
	check.Size = UDim2.fromOffset(16, 16)
	MenuKit.keyline(check, LOOK.Ink, 1.25)
	local tick = MenuKit.text(check, "Tick", 12, WHITE, Z + 7)
	tick.Size = UDim2.fromScale(1, 1)
	tick.Text = "\u{2713}"
	-- In a search across biomes: the card's biome, top left.
	local place = MenuKit.picture(face, BIOME_ICONS[species.Biome] or "", nil, Z + 6)
	place.Name = "Biome"
	place.Position = UDim2.fromOffset(5, 5)
	place.Size = UDim2.fromOffset(18, 18)
	place.Visible = false
	local fxText = RarityFX.text(rarity, rarityLine)
	local fxEdge = RarityFX.edge(face, 8, Z + 4)
	-- The other five's still band, inside the card's keyline (2026-10-10).
	local ring = RarityFX.ring(face, 8, Z + 4, (GameConfig.RarityEdge :: any).Ring)
	local scale = Instance.new("UIScale")
	scale.Parent = face
	UIKit.cardPop(face, scale, { hoverScale = 1.04, pressScale = 0.97, sound = false })
	local c: Card = {
		holder = holder,
		button = face,
		edge = edge,
		tint = tint,
		well = well,
		accent = accent,
		view = view,
		name = name,
		nameFit = nameFit,
		rarity = rarity,
		check = check,
		place = place,
		fxText = fxText,
		fxEdge = fxEdge,
		ring = ring,
		species = species,
		built = false,
	}
	shapeCard(c)
	MenuKit.tap(face, grid, function()
		SoundKit.play("CardClick")
		openDetail(species)
	end)
	cards[species.Id] = c
	return c
end

local function paintCard(c: Card, entry: AlmanacView.Entry, order: number)
	local known = entry.known
	local face = AlmanacView.face(entry.species, known)
	local colours = ALMANAC.Rarity[face.rarity] or ALMANAC.Rarity.Common
	c.holder.Visible = true
	c.holder.LayoutOrder = order
	c.name.Text = face.name
	c.name.TextColor3 = if known then LOOK.Text else LOOK.Muted
	c.rarity.Text = face.rarity
	RarityFX.setText(c.fxText, face.rarity, colours[1])
	RarityFX.setEdge(c.fxEdge, face.rarity, true)
	local rare = RarityFX.edgeColour(face.rarity)
	c.edge.Color = rare or LOOK.CardEdge
	c.edge.Transparency = if rare then 0.05 else LOOK.CardEdgeTransparency
	-- Common to Legendary (2026-10-10, the owner: "yes, add rarity edges"): a
	-- GROWN card wears its form rarity's still band inside the keyline. A card
	-- not yet grown stays plain: its rarity is already its word and its tint.
	RarityFX.setRing(c.ring, if known and not rare then RarityFX.stillEdge(face.rarity) else nil)
	c.accent.BackgroundColor3 = colours[1]
	-- The rarity is already written on every card, found or not: the tint
	-- says nothing more.
	MenuKit.cardTint(c.tint, GameConfig.RarityColor[face.rarity])
	c.check.Visible = known
	c.place.Visible = searching
	if c.built then
		tintView(c.view, known)
	end
end

-- A card's plant, built only once the card has been on screen with the panel
-- open; its rarity light moving only while it is in view (RarityFX).
local function buildVisible()
	local at, size = grid.AbsolutePosition, grid.AbsoluteSize
	local listing = grid.Visible and panelOpen and detailId == nil
	for _, c in pairs(cards) do
		local p, s = c.holder.AbsolutePosition, c.holder.AbsoluteSize
		local shown = listing and c.holder.Visible
		local near = shown and p.Y + s.Y >= at.Y - 40 and p.Y <= at.Y + size.Y + 40
		if near and not c.built then
			c.built = true
			local species = c.species
			local ok, model = pcall(CreatureModel.Build, species, SeedData.BaseTier,
				CreatureModel.STAGE_GROWN, CFrame.new(), c.view)
			if ok and model then
				local camera = UIKit.framePlant(c.view, model, species.Form, CARD_FILL)
				c.view.CurrentCamera = camera
			end
			tintView(c.view, almanac[species.Id] == true)
		end
		local inView = shown and p.Y + s.Y > at.Y and p.Y < at.Y + size.Y
		RarityFX.setActive(c.fxText, inView)
		RarityFX.setActive(c.fxEdge, inView)
	end
end
grid:GetPropertyChangedSignal("CanvasPosition"):Connect(buildVisible)
pageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	task.defer(buildVisible)
end)
grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	task.defer(buildVisible)
end)

--==============================================================================
-- THE DETAIL PAGE: in the panel, over the page
--==============================================================================
local detail = MenuKit.frame(body, "Detail", Z + 8, LOOK.Sheet, 0.02, 10)
detail.Active = true
detail.Visible = false
MenuKit.keyline(detail, LOOK.WellEdge, 1, 0.3)
local back = MenuKit.button(detail, "Back", Z + 9, "< BACK", 15)
back.style("sky")
local stage = MenuKit.frame(detail, "Stage", Z + 9, ALMANAC.BodyTop, 0, 10)
stage.ClipsDescendants = true
MenuKit.keyline(stage, LOOK.WellEdge, 1)
local stageArt = Instance.new("ImageLabel")
stageArt.Name = "Scenery"
stageArt.Size = UDim2.fromScale(1, 1)
stageArt.BackgroundTransparency = 1
stageArt.ScaleType = Enum.ScaleType.Crop
stageArt.ImageColor3 = CARD.ArtTint
stageArt.ImageTransparency = 0.35
stageArt.Visible = false
stageArt.ZIndex = Z + 9
stageArt.Parent = stage
UIKit.corner(stageArt, 10)
local stageView = Instance.new("ViewportFrame")
stageView.Name = "Plant"
stageView.AnchorPoint = Vector2.new(0.5, 0.5)
stageView.Position = UDim2.fromScale(0.5, 0.5)
stageView.Size = UDim2.new(1, -6, 1, -6)
stageView.BackgroundTransparency = 1
stageView.Ambient = CARD.Ambient
stageView.LightColor = CARD.LightColour
stageView.LightDirection = CARD.LightDirection
stageView.ZIndex = Z + 10
stageView.Parent = stage
-- The plant's own pod, small in the stage's corner (the Pod Guide,
-- 2026-10-09): what to look for in a nest. A pod's look is no secret; the
-- plant over it stays a silhouette until grown.
local stagePod = MenuKit.frame(stage, "Pod", Z + 11, LOOK.Window, 0.2, 8)
stagePod.AnchorPoint = Vector2.new(0, 1)
stagePod.Position = UDim2.new(0, 6, 1, -6)
stagePod.Size = UDim2.fromScale(0.3, 0.3)
do
	local square = Instance.new("UIAspectRatioConstraint")
	square.Parent = stagePod
end
local stagePodPreview = UIKit.itemPreview(stagePod, { name = "Preview", scrim = 1, fit = 0.9 })
stagePodPreview.hero.Ambient = LOOK.PreviewAmbient
for _, d in ipairs(stagePodPreview.holder:GetDescendants()) do
	if d:IsA("GuiObject") then
		d.ZIndex = math.max(d.ZIndex, Z + 12)
	end
end
stagePodPreview.holder.ZIndex = Z + 12

-- The words beside the stage scroll when they outgrow it (a phone's short
-- panel): the Pod Guide's lines made the column taller (2026-10-09).
local info = Instance.new("ScrollingFrame")
info.Name = "Info"
info.BackgroundTransparency = 1
info.BorderSizePixel = 0
info.ScrollingDirection = Enum.ScrollingDirection.Y
info.ScrollBarThickness = 4
info.ScrollBarImageColor3 = LOOK.PlateEdge
info.CanvasSize = UDim2.new()
info.AutomaticCanvasSize = Enum.AutomaticSize.Y
info.Selectable = false
info.ZIndex = Z + 9
info.Parent = detail
local infoList = Instance.new("UIListLayout")
infoList.SortOrder = Enum.SortOrder.LayoutOrder
infoList.Padding = UDim.new(0, 4)
infoList.Parent = info
-- Dark type on the light sheet (2026-10-04): plain, no outline.
local showName = MenuKit.text(info, "Name", 24, LOOK.Text, Z + 10)
showName.LayoutOrder = 1
showName.Size = UDim2.new(1, 0, 0, 30)
showName.TextXAlignment = Enum.TextXAlignment.Left
showName.TextScaled = true
showName.ZIndex = Z + 10
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 26
	fit.MinTextSize = 14
	fit.Parent = showName
end
local showRarity = MenuKit.text(info, "Rarity", 16, WHITE, Z + 10)
showRarity.LayoutOrder = 2
showRarity.Size = UDim2.new(1, 0, 0, 20)
showRarity.TextXAlignment = Enum.TextXAlignment.Left
local showRarityFX = RarityFX.text(showRarity, showRarity:FindFirstChildOfClass("UIStroke"))
showRarityFX.gate = detail
local biomeRow = MenuKit.frame(info, "BiomeRow", Z + 10)
biomeRow.LayoutOrder = 3
biomeRow.Size = UDim2.new(1, 0, 0, ICON)
local showBiome = MenuKit.text(biomeRow, "Biome", 14, LOOK.Muted, Z + 10)
showBiome.Position = UDim2.fromOffset(ICON + 6, 0)
showBiome.Size = UDim2.new(1, -(ICON + 6), 1, 0)
showBiome.TextXAlignment = Enum.TextXAlignment.Left
local biomeIcon: Frame? = nil
local biomeIconFor: string? = nil

-- A biome's picture in `holder`, square, Fit, kept while it is the same biome.
local function biomePicture(holder: Instance, current: Frame?, currentFor: string?, biomeId: string): (Frame?, string?)
	if current and currentFor == biomeId then
		return current, currentFor
	end
	if current then
		current:Destroy()
	end
	local image = BIOME_ICONS[biomeId]
	if not image then
		return nil, nil
	end
	local pic = MenuKit.picture(holder, image, nil, Z + 11)
	pic.Name = "BiomeIcon"
	pic.AnchorPoint = Vector2.new(0, 0.5)
	pic.Position = UDim2.new(0, 0, 0.5, 0)
	pic.Size = UDim2.fromOffset(ICON, ICON)
	return pic, biomeId
end
local showState = MenuKit.body(info, "State", 14, LOOK.Money, Z + 10)
showState.LayoutOrder = 4
showState.Size = UDim2.new(1, 0, 0, 18)
showState.AutomaticSize = Enum.AutomaticSize.Y
showState.TextWrapped = true
showState.TextXAlignment = Enum.TextXAlignment.Left
-- Where it comes from (the Pod Guide, 2026-10-09): its own pod, and how often
-- its biome's nests stock that pod.
local showHatch = MenuKit.body(info, "HatchesFrom", 13, LOOK.Text, Z + 10)
showHatch.LayoutOrder = 5
showHatch.Size = UDim2.new(1, -6, 0, 16)
showHatch.AutomaticSize = Enum.AutomaticSize.Y
showHatch.TextWrapped = true
showHatch.TextXAlignment = Enum.TextXAlignment.Left
-- WHAT IT EARNS AT EVERY SIZE (the Pod Guide, 2026-10-09; it was the Tiny
-- yield alone): each size in its colour, its rate a second.
local yieldRow = MenuKit.frame(info, "Yield", Z + 10, LOOK.Well, LOOK.WellTransparency, 8)
yieldRow.LayoutOrder = 6
yieldRow.Size = UDim2.new(1, -6, 0, 0)
yieldRow.AutomaticSize = Enum.AutomaticSize.Y
MenuKit.keyline(yieldRow, LOOK.WellEdge, 1, 0.3)
do
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 6)
	pad.PaddingLeft = UDim.new(0, 10)
	pad.PaddingRight = UDim.new(0, 10)
	pad.Parent = yieldRow
	local rows = Instance.new("UIListLayout")
	rows.SortOrder = Enum.SortOrder.LayoutOrder
	rows.Padding = UDim.new(0, 2)
	rows.Parent = yieldRow
end
local yieldKey = MenuKit.text(yieldRow, "Key", 13, LOOK.Money, Z + 11)
yieldKey.LayoutOrder = 1
yieldKey.Size = UDim2.new(1, 0, 0, 18)
yieldKey.TextXAlignment = Enum.TextXAlignment.Left
yieldKey.Text = GUIDE.Words.IncomeTitle
local yieldValue = MenuKit.body(yieldRow, "Value", 13, LOOK.Text, Z + 11)
yieldValue.LayoutOrder = 2
yieldValue.Size = UDim2.new(1, 0, 0, 16)
yieldValue.AutomaticSize = Enum.AutomaticSize.Y
yieldValue.TextWrapped = true
yieldValue.RichText = true
yieldValue.TextXAlignment = Enum.TextXAlignment.Left

--==============================================================================
-- THE STAGE'S PEDESTAL
--
-- Moss on a stone foot with a lime ring of Neon between them, which a viewport
-- draws as flat bright colour: the glow without a light. Built before the camera
-- is solved and named "Pedestal", so UIKit.framePlant neither adds its own soil
-- disc nor lets the base into the fit.
--==============================================================================
local function mossPedestal(model: Model)
	local pivot, size = model:GetBoundingBox()
	local groundY = pivot.Position.Y - size.Y * 0.5
	local radius = math.max(size.X, size.Z) * 0.62 + 0.4
	local base = Instance.new("Model")
	base.Name = "Pedestal"
	local function disc(name: string, height: number, r: number, y: number, colour: Color3,
		material: Enum.Material)
		local part = Instance.new("Part")
		part.Name = name
		part.Shape = Enum.PartType.Cylinder
		part.Size = Vector3.new(height, r * 2, r * 2)
		part.CFrame = CFrame.new(pivot.Position.X, y, pivot.Position.Z) * CFrame.Angles(0, 0, math.pi * 0.5)
		part.Color = colour
		part.Material = material
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.Parent = base
	end
	disc("Moss", 0.34, radius, groundY - 0.17, ALMANAC.PedestalMoss, Enum.Material.Grass)
	disc("Glow", 0.12, radius * 1.1, groundY - 0.36, ALMANAC.Lime, Enum.Material.Neon)
	disc("Stone", 0.42, radius * 1.02, groundY - 0.62, ALMANAC.PedestalStone, Enum.Material.Slate)
	base.Parent = model
end

-- One plant on the stage at a time; the last one is destroyed, not kept.
local stageShown: string? = nil
local function showStage(species: any)
	if stageShown == species.Id then
		return
	end
	stageShown = species.Id
	stageView:ClearAllChildren()
	stageView.CurrentCamera = nil
	local ok, model = pcall(CreatureModel.Build, species, SeedData.BaseTier,
		CreatureModel.STAGE_GROWN, CFrame.new(), stageView)
	if ok and model then
		mossPedestal(model)
		UIKit.framePlant(stageView, model, species.Form, STAGE_FILL)
	end
end

local function paintDetail()
	local id = detailId
	if not id then
		return
	end
	local species = SeedData.ById[id]
	if not species then
		return
	end
	local known = almanac[id] == true
	local face = AlmanacView.face(species, known)
	local colours = ALMANAC.Rarity[face.rarity] or ALMANAC.Rarity.Common
	showName.Text = face.name
	showRarity.Text = face.rarity
	RarityFX.setText(showRarityFX, face.rarity, colours[1])
	RarityFX.setActive(showRarityFX, panelOpen)
	local biome = BiomeData.ById[species.Biome] or BiomeData.ById[activeBiome]
	local biomeId = biome and biome.Id or ""
	biomeIcon, biomeIconFor = biomePicture(biomeRow, biomeIcon, biomeIconFor, biomeId)
	showBiome.Text = string.format("%s \u{00B7} Biome %d", biome and biome.DisplayName or "", biome and biome.Order or 0)
	showState.Text = if known then "\u{2713} Grown on your plot"
		else "Not grown yet: hatch one on your own plot to discover it."
	showState.TextColor3 = if known then LOOK.Money else LOOK.Muted
	--==========================================================================
	-- THE YIELD AT EVERY SIZE, AND UNMULTIPLIED (the Pod Guide, 2026-10-09)
	--
	-- What one of this species pays standing grown at each size:
	-- SeedData.IncomePerSecond (PodGuide.incomes), the calculation the faucet
	-- itself runs. The x2 pass is a fact about the player, not about the plant.
	-- Still ??? until grown, as the Tiny yield alone was.
	--==========================================================================
	if known then
		local parts = {}
		for i, rate in ipairs(PodGuide.incomes(id)) do
			local tier = SeedData.Tiers[i]
			-- The size's colour a quarter darker and bold: the pale ones (Tiny's
			-- grey, Colossal's gold) read faint on the light sheet (seen in Play).
			table.insert(parts, string.format("<b><font color=\"#%s\">%s</font></b> $%s/s",
				tier.color:Lerp(Color3.new(0, 0, 0), 0.25):ToHex(), tier.name, GameConfig.compact(rate)))
		end
		yieldValue.Text = table.concat(parts, "  \u{00B7}  ")
	else
		yieldValue.Text = "???"
	end
	showHatch.Text = string.format(GUIDE.Words.HatchesFrom, PodGuide.odds(PodGuide.chanceOf(id)),
		biome and biome.DisplayName or "")
	local podKey = "pod|p:" .. id .. "|" .. tostring(GUIDE.PodTier)
	local podArt: ItemArt.Art = { kind = "pod", speciesId = id, tier = GUIDE.PodTier }
	local podBuilder, podKind = ItemArt.builder(podKey, podArt)
	stagePodPreview.setModel(podKey, podBuilder, podKind)
	stageArt.Image = if known then (CARD.Art[id] or "") else ""
	stageArt.Visible = known
	if panelOpen then
		showStage(species)
		tintView(stageView, known)
	end
end

--==============================================================================
-- PAINTING
--
-- Words, colours and states are pennies and always repaint. The models are the
-- expensive half and are only built while somebody is looking.
--==============================================================================
local function paintHeadings()
	for _, biome in ipairs(road) do
		local s = sections[biome.Id]
		if s then
			local grown, total = AlmanacData.Progress(almanac, biome.Id)
			local cash, speed = AlmanacData.Reward(biome.Id)
			s.cashValue.Text = "$" .. GameConfig.compact(cash)
			s.speedValue.Text = "+" .. GameConfig.compact(speed)
			s.text.Text = string.format("%s \u{00B7} <font color=\"#%s\">%d/%d Grown</font>", biome.DisplayName,
				(if total > 0 and grown >= total then LOOK.Premium else LOOK.Money):ToHex(), grown, total)
			s.barFill.Size = UDim2.fromScale(if total > 0 then grown / total else 0, 1)
			s.barFill.BackgroundColor3 = if total > 0 and grown >= total then ALMANAC.Gold else LOOK.Green
			local state = stateOf(biome.Id)
			-- CLAIM: the warm gold reward face when it can be claimed, the owned gold
			-- with a check once claimed, flat grey while it cannot (not every plant
			-- grown, or the claim on its way).
			local claim = s.claim
			if pending[biome.Id] and state == "ready" then
				claim.style("off")
				claim.set("CLAIMING...")
			elseif state == "claimed" then
				claim.style("done")
				claim.set("\u{2713} CLAIMED")
			elseif state == "ready" then
				claim.style("claim")
				claim.set("CLAIM")
			else
				claim.style("off")
				claim.set(string.format("CLAIM %d/%d", grown, total))
			end
			s.bar.Visible = s.bar.Size.X.Offset > 0
			s.reward.Visible = s.reward.Size.X.Offset > 0
		end
	end
end

local function paintGrid()
	searching = AlmanacView.normalise(queryNow) ~= ""
	local list: { AlmanacView.Entry } = {}
	if searching then
		-- A search spans every biome (AlmanacView), each card still on its biome.
		list = (AlmanacView.list(almanac, road[1].Id, filterNow, queryNow))
	else
		for _, biome in ipairs(road) do
			for _, entry in ipairs((AlmanacView.list(almanac, biome.Id, filterNow, ""))) do
				table.insert(list, entry)
			end
		end
	end
	current = list
	local seen: { [string]: boolean } = {}
	local found: { [string]: number } = {}
	for i, entry in ipairs(list) do
		local c = cardFor(entry.species)
		paintCard(c, entry, i)
		seen[entry.species.Id] = true
		found[entry.biomeId] = (found[entry.biomeId] or 0) + 1
	end
	for id, c in pairs(cards) do
		if not seen[id] then
			c.holder.Visible = false
			RarityFX.setActive(c.fxText, false)
			RarityFX.setActive(c.fxEdge, false)
		end
	end
	-- Every biome's heading stands, whatever the filter; a search keeps only the
	-- biomes it found something in.
	for _, biome in ipairs(road) do
		local s = sections[biome.Id]
		if s then
			s.frame.Visible = not searching or (found[biome.Id] or 0) > 0
		end
	end
	podSizes.Visible = not searching
	local first = list[1]
	padFirst.Value = if first then cards[first.species.Id].button else nil
	if searching and #list == 0 then
		emptyLabel.Text = "No matches. Only plants you have grown can be found by name."
		emptyLabel.Visible = detailId == nil
	else
		emptyLabel.Visible = false
	end
	task.defer(buildVisible)
end

--==============================================================================
-- THE BADGE
--
-- Gold "!" while any biome has a harvest waiting to be claimed -- that is the
-- one thing in here worth interrupting a player for. Otherwise the red count of
-- species not yet grown, as it has always been.
--==============================================================================
local function paintBadge()
	for _, biome in ipairs(road) do
		if stateOf(biome.Id) == "ready" then
			badge.BackgroundColor3 = ALMANAC.Gold
			badgeCount.Text = "!"
			badge.Visible = true
			return
		end
	end
	local grown, total = AlmanacData.TotalProgress(almanac)
	badge.BackgroundColor3 = RAIL.Badge
	badgeCount.Text = tostring(total - grown)
	badge.Visible = total - grown > 0
end

paint = function()
	paintGrid()
	paintHeadings()
	paintDetail()
	paintBadge()
end

--==============================================================================
-- LAYOUT: MenuLayout's answer, applied
--
-- In the gui's own units: its pixels divided by its scale. HudLayout answers
-- the rails in ITS units (the window's, or a TV's canvas), which the menu size
-- divides once more.
--==============================================================================
local layoutNow: MenuLayout.Panel? = nil

local function keyboardTop(): number?
	if not UserInputService.OnScreenKeyboardVisible then
		return nil
	end
	local ok, at = pcall(function()
		return UserInputService.OnScreenKeyboardPosition
	end)
	if not ok or typeof(at) ~= "Vector2" or at.Y <= 0 then
		return nil
	end
	local inset = GuiService:GetGuiInset().Y
	return (at.Y - inset) / UIKit.scaleOf(gui)
end

relayout = function()
	local k = UIKit.scaleOf(gui)
	local safe = gui.AbsoluteSize / UIKit.scaleOf(gui)
	if safe.X < 100 or safe.Y < 100 then
		return
	end
	local hud = HudLayout.solve(HudLayout.measure(gui))
	local camera = workspace.CurrentCamera
	local hudScale = if HudLayout.isTenFoot() and camera then HudLayout.tenFootScale(camera.ViewportSize) else 1
	local f = k / hudScale
	-- The whole page's size, whatever the filter: every biome's every plant.
	local counts: { number } = {}
	for _, biome in ipairs(road) do
		table.insert(counts, #AlmanacView.shelf(biome.Id))
	end
	local p = MenuLayout.indexPanel({
		safe = safe,
		compact = hud.compact,
		railRight = hud.railRight / f,
		rightLeft = hud.rightLeft / f,
		-- A phone draws this gui smaller (UIKit.menuScaleFor): the panel keeps its room.
		fill = math.min(1, k),
		keyboardTop = keyboardTop(),
	}, RAIL.OutlineThickness, counts)
	layoutNow = p
	menu.place(p)
	local b = MenuLayout.blocks(p)
	local gap = MenuLayout.Config.Gap
	local touch = MenuLayout.Config.Touch
	local rowY = math.floor((p.header - touch) / 2)

	-- THE HEADER: after the title, before the close button.
	local function header(titleWidth: number): { [string]: MenuLayout.Rect }
		return MenuLayout.indexHeader(p, titleWidth)
	end
	modal.title.Text = "Plant Almanac"
	local row = header(MenuKit.titleWidth(menu, p.short))
	if not row.search then
		modal.title.Text = "Almanac"
		row = header(MenuKit.titleWidth(menu, p.short))
	end
	menu.place(p)
	local function put(obj: GuiObject, r: MenuLayout.Rect?, inset: number)
		obj.Visible = r ~= nil
		if r then
			obj.Position = UDim2.fromOffset(r.x, rowY + inset)
			obj.Size = UDim2.fromOffset(r.w, touch - inset * 2)
		end
	end
	put(search.frame, row.search, 2)
	put(filter.frame, row.filter, 2)

	-- THE PAGE, over the baseplate.
	local main = b.main
	plate.Position = UDim2.fromOffset(main.x, main.y)
	plate.Size = UDim2.fromOffset(main.w, main.h)
	grid.Position = UDim2.fromOffset(main.x, main.y)
	grid.Size = UDim2.fromOffset(main.w, main.h)
	gridPad.PaddingLeft = UDim.new(0, GRID_INSET)
	gridPad.PaddingRight = UDim.new(0, GRID_INSET)
	gridPad.PaddingTop = UDim.new(0, GRID_INSET)
	gridPad.PaddingBottom = UDim.new(0, GRID_INSET)
	local cg = MenuLayout.indexCards(p, main.w - grid.ScrollBarThickness)
	cardW, cardH, previewH = cg.cardW, cg.cardH, cg.previewH
	for _, c in pairs(cards) do
		shapeCard(c)
	end

	-- EVERY BIOME'S HEADING: its picture before its words, then the bar, the
	-- harvest and CLAIM, across the page's own width.
	local ph = if p.short then IDX.ProgressShort else IDX.ProgressTall
	local headW = main.w - grid.ScrollBarThickness - GRID_INSET * 2
	local textW = math.ceil(MenuKit.textWidth("Greenhollow \u{00B7} 5/5 Grown", 15)) + 4 + ICON + 6
	local cashW = math.ceil(MenuKit.textWidth("$250M", 14)) + 2
	local speedW = math.ceil(MenuKit.textWidth("+1B", 14)) + 2
	local rewardW = 22 + cashW + 10 + 22 + speedW
	local inner = MenuLayout.pack(8, headW - 4, 10, {
		{ id = "text", w = textW },
		{ id = "bar", grow = true, minW = 40, maxW = 220, drop = 2 },
		{ id = "reward", w = rewardW, drop = 1 },
		{ id = "claim", w = 112 },
	})
	local mid = ph / 2
	for _, s in pairs(sections) do
		s.heading.Size = UDim2.new(1, 0, 0, ph)
		s.cells.CellSize = UDim2.fromOffset(cardW, cardH)
		s.cells.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
		local t = inner.text
		local icon = s.icon
		if icon then
			icon.Position = UDim2.new(0, t.x, 0.5, 0)
		end
		s.text.Position = UDim2.fromOffset(t.x + ICON + 6, 0)
		s.text.Size = UDim2.fromOffset(t.w - ICON - 6, ph)
		local br = inner.bar
		s.bar.Size = UDim2.fromOffset(if br then br.w else 0, 8)
		if br then
			s.bar.Position = UDim2.fromOffset(br.x, mid)
		end
		local rw = inner.reward
		s.reward.Size = UDim2.fromOffset(if rw then rw.w else 0, ph)
		if rw then
			s.reward.Position = UDim2.fromOffset(rw.x, 0)
			s.cashIcon.Position = UDim2.new(0, 0, 0.5, 0)
			s.cashValue.Position = UDim2.fromOffset(22, 0)
			s.cashValue.Size = UDim2.fromOffset(cashW, ph)
			s.speedIcon.Position = UDim2.new(0, 22 + cashW + 10, 0.5, 0)
			s.speedValue.Position = UDim2.fromOffset(22 + cashW + 10 + 22, 0)
			s.speedValue.Size = UDim2.fromOffset(speedW, ph)
		end
		local cr = inner.claim
		s.claim.hit.Position = UDim2.fromOffset(cr.x, math.floor((ph - 44) / 2))
		s.claim.hit.Size = UDim2.fromOffset(cr.w, 44)
		s.claim.plate.Size = UDim2.new(1, 0, 0, math.min(30, ph - 4))
	end
	emptyLabel.Position = UDim2.fromOffset(main.x + main.w / 2, main.y + math.min(main.h * 0.4, 70))
	emptyLabel.Size = UDim2.fromOffset(math.max(80, main.w - 40), 50)

	-- THE DETAIL PAGE: over the page.
	detail.Position = UDim2.fromOffset(main.x, main.y)
	detail.Size = UDim2.fromOffset(main.w, main.h)
	back.hit.Position = UDim2.fromOffset(6, 2)
	back.hit.Size = UDim2.fromOffset(104, 44)
	local wide = main.w >= 420
	local top = 50
	if wide then
		local side = math.max(80, math.min(main.h - top - 8, math.floor(main.w * 0.46)))
		stage.Position = UDim2.fromOffset(8, top)
		stage.Size = UDim2.fromOffset(side, main.h - top - 8)
		info.Position = UDim2.fromOffset(8 + side + 14, top)
		info.Size = UDim2.fromOffset(main.w - side - 30, main.h - top - 8)
	else
		local side = math.max(80, math.min(math.floor((main.h - top) * 0.5), main.w - 16))
		stage.Position = UDim2.fromOffset(8, top)
		stage.Size = UDim2.fromOffset(main.w - 16, side)
		info.Position = UDim2.fromOffset(10, top + side + 8)
		info.Size = UDim2.fromOffset(main.w - 20, main.h - top - side - 14)
	end
	UIKit.coverRail(playerGui, PANEL_NAME, panelOpen and p.covers)
	paintHeadings()
	task.defer(buildVisible)
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
UserInputService:GetPropertyChangedSignal("OnScreenKeyboardVisible"):Connect(function()
	task.defer(relayout)
end)
UIKit.onMenuSize(relayout)
relayout()

--==============================================================================
-- THE DETAIL PAGE, OPEN AND SHUT
--
-- The page is hidden, never rebuilt or scrolled, so Back finds it exactly as it
-- was: the same filter, search and scroll.
--==============================================================================
local backName = "SeedIndexBack"

local function closeDetail()
	local id = detailId
	if not id then
		return
	end
	detailId = nil
	detail.Visible = false
	-- The plate stays hidden: the studded body is the page (2026-10-08).
	grid.Visible = true
	RarityFX.setActive(showRarityFX, false)
	MenuKit.unbind(backName)
	paintGrid()
	local c = cards[id]
	if c and MenuKit.onPad() and c.holder.Visible then
		GuiService.SelectedObject = c.button
	end
end

openDetail = function(species: any)
	detailId = species.Id
	plate.Visible = false
	grid.Visible = false
	emptyLabel.Visible = false
	detail.Visible = true
	paintDetail()
	buildVisible()
	MenuKit.bindBack(backName, closeDetail)
	if MenuKit.onPad() then
		GuiService.SelectedObject = back.hit
	end
end

MenuKit.tap(back.hit, nil, function()
	SoundKit.play("CardClick")
	closeDetail()
end)

--==============================================================================
-- WHERE THE PANEL OPENS
--
-- The first open of a session scrolls the page to where the action is: a biome
-- with a harvest waiting, else the furthest biome with anything grown in it.
-- After that the page stays where it was left.
--==============================================================================
local function openingBiome(): string
	for _, biome in ipairs(road) do
		if stateOf(biome.Id) == "ready" then
			return biome.Id
		end
	end
	local furthest = road[1].Id
	for _, biome in ipairs(road) do
		local grown = AlmanacData.Progress(almanac, biome.Id)
		if grown > 0 then
			furthest = biome.Id
		end
	end
	return furthest
end

--==============================================================================
-- THE CLAIM
--==============================================================================
local gameEvent: RemoteEvent? = nil

requestClaim = function(biomeId: string)
	local section = sections[biomeId]
	local state = stateOf(biomeId)
	if state == "claimed" then
		SoundKit.play("CardClick")
		return
	end
	local channel = gameEvent
	if state ~= "ready" or pending[biomeId] or not channel then
		SoundKit.play("Denied")
		if section then
			section.shake()
		end
		return
	end
	pending[biomeId] = true
	SoundKit.play("CardClick")
	paint()
	channel:FireServer(ALMANAC.ClaimAction, biomeId)
	-- The answer normally lands within a frame or two. If it never does, stop
	-- showing "claiming" rather than leaving the button stuck.
	task.delay(CLAIM_PATIENCE, function()
		if pending[biomeId] then
			pending[biomeId] = nil
			paint()
		end
	end)
end

local function onReply(action: any, biomeId: any, ok: any, reason: any)
	if action ~= ALMANAC.ClaimAction then
		return
	end
	if type(biomeId) == "string" then
		pending[biomeId] = nil
		-- The server has recorded it either way; the profile packet that follows
		-- says the same thing a quarter of a second later.
		if ok == true or reason == "claimed" then
			mastery[biomeId] = true
		end
	end
	if ok == true then
		SoundKit.play("Banked")
	elseif reason ~= "busy" then
		SoundKit.play("Denied")
	end
	paint()
end


--==============================================================================
-- THE SEARCH AND THE FILTER
--==============================================================================
search.changed(function(text: string)
	if queryNow ~= text then
		queryNow = text
		resetScroll()
		paintGrid()
		paintHeadings()
	end
end)
filter.changed(function(id: string)
	filterNow = id :: AlmanacView.Filter
	resetScroll()
	paintGrid()
	paintHeadings()
end)

--==============================================================================
-- OPEN AND SHUT
--
-- ONE CENTRE PANEL AT A TIME. Each panel writes its own name to the OpenPanel
-- attribute and closes itself on seeing a name that is not its own, so no script
-- has to know the others exist. While open, LB / RB jump the page to the
-- previous or next biome's heading (one page since 2026-10-06; they stepped the
-- chosen biome before), with that biome's first card selected.
--==============================================================================
local function stepBiome(step: number)
	if detailId ~= nil then
		return
	end
	local shown: { any } = {}
	for _, biome in ipairs(road) do
		local s = sections[biome.Id]
		if s and s.frame.Visible then
			table.insert(shown, biome)
		end
	end
	if #shown == 0 then
		return
	end
	-- The biome the view is in: the last whose heading is at or above its top.
	local at = 1
	for i, biome in ipairs(shown) do
		if sections[biome.Id].frame.AbsolutePosition.Y <= grid.AbsolutePosition.Y + 2 then
			at = i
		end
	end
	local target = shown[(at - 1 + step) % #shown + 1]
	activeBiome = target.Id
	scrollToBiome(target.Id)
	SoundKit.play("CardClick")
	if MenuKit.onPad() then
		local pick: Card? = nil
		for _, c in pairs(cards) do
			if c.species.Biome == target.Id and c.holder.Visible
				and (pick == nil or c.holder.LayoutOrder < (pick :: Card).holder.LayoutOrder) then
				pick = c
			end
		end
		if pick then
			GuiService.SelectedObject = pick.button
		end
	end
end

local function setOpen(want: boolean)
	if panelOpen == want then
		return
	end
	panelOpen = want
	local first = false
	if want then
		if not openedBefore then
			openedBefore = true
			first = true
			activeBiome = openingBiome()
		end
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		MenuKit.bindBumpers("SeedIndexPad", stepBiome)
	else
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		closeDetail()
		search.box:ReleaseFocus()
		MenuKit.unbind("SeedIndexPad")
	end
	-- Laid out and painted before the panel shows, so its first frame is the
	-- finished grid; the rail steps under it (or back) in the same pass.
	relayout()
	paint()
	if not want then
		for _, c in pairs(cards) do
			RarityFX.setActive(c.fxText, false)
			RarityFX.setActive(c.fxEdge, false)
		end
		RarityFX.setActive(showRarityFX, false)
	end
	modal.setOpen(want)
	if first then
		-- Once the page has its size: the biome that opened it at the top.
		task.defer(function()
			scrollToBiome(activeBiome)
		end)
	end
end

button.Activated:Connect(function()
	setOpen(not panelOpen)
end)
modal.close.Activated:Connect(function()
	setOpen(false)
end)
modal.dimmer.Activated:Connect(function()
	setOpen(false)
end)

player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	local holder = player:GetAttribute(ATTR.OpenPanel)
	if panelOpen and holder ~= PANEL_NAME then
		setOpen(false)
	end
end)
gui.Destroying:Connect(function()
	UIKit.coverRail(playerGui, PANEL_NAME, false)
	MenuKit.unbind("SeedIndexPad")
	MenuKit.unbind(backName)
end)

-- OPENED AT ONE PLANT FROM ELSEWHERE (the Pod Guide, 2026-10-09: a Bag pod's
-- WHAT'S INSIDE?): the panel, then that plant's own page. ShopUI's OpenAt.
local openAt = Instance.new("BindableEvent")
openAt.Name = "OpenAt"
openAt.Parent = gui
openAt.Event:Connect(function(speciesId: any)
	local species = if type(speciesId) == "string" then SeedData.ById[speciesId] else nil
	if not (species and PodGuide.chanceOf(speciesId) > 0) then
		return
	end
	setOpen(true)
	openDetail(species)
end)

--==============================================================================
-- THE PROFILE
--
-- Both sets only ever grow on the client: a species is not un-grown and a paid
-- harvest is not un-paid, so a stale packet can never take one away.
--==============================================================================
local function receive(profile: any)
	if type(profile) ~= "table" then
		return
	end
	local changed = false
	if type(profile.Almanac) == "table" then
		--======================================================================
		-- A FIRST DISCOVERY WAITS FOR ITS OWN REVEAL (2026-09-29)
		--
		-- The Almanac learns a species at the hatch, and the hatch shows its
		-- plant three seconds later, where the pod stood (HatchRoll). A
		-- silhouette lifting here, or the badge's count dropping, in those
		-- seconds would name the plant before the world does -- so a species
		-- this player is still waiting to be shown is added when its roll
		-- ends, not before. Only a species that is NEW: one already grown stays
		-- exactly as it is.
		--======================================================================
		local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
		local waiting = HatchRoll.sealedSpecies(player)
		for id, value in pairs(profile.Almanac) do
			if value == true and type(id) == "string" and not almanac[id] then
				local shownAt = waiting[id]
				if shownAt then
					task.delay(math.max(shownAt - workspace:GetServerTimeNow(), 0) + 0.05, function()
						if not almanac[id] then
							almanac[id] = true
							paint()
						end
					end)
				else
					almanac[id] = true
					changed = true
				end
			end
		end
	end
	if type(profile.Mastery) == "table" then
		for id, value in pairs(profile.Mastery) do
			if value == true and type(id) == "string" and not mastery[id] then
				mastery[id] = true
				pending[id] = nil
				changed = true
			end
		end
	end
	if changed then
		paint()
	end
end

paint()

local remotes = SeedGame:WaitForChild("Remotes", 20)
if remotes then
	-- WaitForChild, not FindFirstChild: the folder replicates before the events
	-- inside it, which is how CashUI once sat blank for a whole session.
	local updated = remotes:WaitForChild(GameConfig.Remotes.ProfileUpdated, 20)
	if updated and updated:IsA("RemoteEvent") then
		updated.OnClientEvent:Connect(receive)
	else
		warn("[Seed/IndexUI] No ProfileUpdated; the almanac will stay unfilled.")
	end
	local ready = remotes:WaitForChild(GameConfig.Remotes.ProfileReady, 20)
	if ready and ready:IsA("RemoteEvent") then
		ready.OnClientEvent:Connect(function(ok: boolean, profile: any)
			if ok then
				receive(profile)
			end
		end)
	end
	local event = remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20)
	if event and event:IsA("RemoteEvent") then
		gameEvent = event
		event.OnClientEvent:Connect(onReply)
	else
		warn("[Seed/IndexUI] No GameEvent; biome harvests cannot be claimed from the almanac.")
	end
else
	warn("[Seed/IndexUI] No Remotes folder; the almanac will stay unfilled.")
end

-- No tick of its own. A Mythic's light is stepped by the one RarityFX clock
-- (LoadoutUI), and only while its card is in view with the panel open; the
-- almanac moves when a profile packet or a claim answer says so.
