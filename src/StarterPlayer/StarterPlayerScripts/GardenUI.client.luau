--!strict
-- Steal a Seed :: GardenUI -- MY PLANTS
--
-- The player's creatures: the ones standing on their plot, and the ones stored
-- in their Bag. Its button is the pot on the right of the HUD (HudLayout's
-- `garden` rect); the panel opens in the middle of the screen.
--
--==============================================================================
-- MY PLANTS (2026-10-04, the owner's menu) REPLACES THE GARDEN PANEL
--
-- The Garden panel was a window onto the bed: one row per occupant, clocks
-- running, a PICK UP, and -- deliberately -- no Equip / Unequip / Equip Best.
-- The owner has asked for exactly that pattern now, adapted to this game's
-- plots rather than to a pet that follows you:
--
--   EQUIPPED   planted on the player's own plot: walking, earning
--   STORED     a fully hatched creature in the Bag: earning nothing
--   a hotbar shortcut is only a shortcut for holding something; it is not a
--   third place a creature can be
--
-- One compact panel in the approved inventory's look (MenuKit): a short header
-- with the title, PLANTED / STORED, the plot's count (occupied / capacity) and
-- the close; small creature cards (picture, name, size or rarity, income per
-- second -- a pod's own countdown instead); and a footer that never scrolls
-- away: the garden's income right now, the selected card's ONE action (PLANT
-- for a stored creature, RETURN TO BAG for a planted one), EQUIP BEST and
-- UNEQUIP ALL (with a confirmation).
--
-- A GROWING POD is shown with its clock and is never moved by any of this: it
-- is hatched where it stands, by hand, as it always was.
--
--==============================================================================
-- THE CLIENT ONLY ASKS
--
-- Four verbs on GameEvent (GameConfig.Plant.MyPlants), each a request the
-- SERVER settles (PlantService: its checks, its order, its answer). What the
-- panel shows is read off the world and the profile the server already pushes:
-- the tagged plant models in the player's plot (PlacementId, SpeciesId, Tier,
-- Stage, HatchAt, ItemId), the plot's Capacity and GardenIncome attributes
-- (EconomyService: the rate actually paid, the pass, boosts and rain inside
-- it), and the profile's Held rows, favourites and hotbar.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))
local InventoryModel = require(Shared:WaitForChild("InventoryModel"))
local InventoryTile = require(Shared:WaitForChild("InventoryTile"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
local HotbarSlots = require(Shared:WaitForChild("HotbarSlots"))
local Notice = require(Shared:WaitForChild("Notice"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
-- A ready pod's card names the hatch, and on a controller that is X.
local PadInput = require(Shared:WaitForChild("PadInput"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local ATTR = GameConfig.Attributes
local PLANTING = GameConfig.Plant
local MY = PLANTING.MyPlants
local LOOK = MenuKit.Look
local HOT = GameConfig.Hotbar
local PL = MenuLayout.Plants
-- The OpenPanel name is the Garden's: every panel takes turns by it.
local PANEL_NAME = "Garden"

local WHITE = Color3.fromRGB(255, 255, 255)
-- The studded cards' own numbers (GameConfig.BagLook: StudWords, StudMoney).
local STUD_LOOK = GameConfig.BagLook
local Z = 6
-- How long a request waits for the server's answer before letting go.
local PATIENCE = 4

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedGarden")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedGarden"
gui.ResetOnSpawn = false
-- ONE ABOVE THE HOTBAR'S 30, so the panel and its dimmer cover the strip.
gui.DisplayOrder = 31
gui.Parent = playerGui

--==============================================================================
-- THE BUTTON: the owner's studded Garden picture (the pot under it until that
-- loads), centre left (HudLayout's `garden`; top right until 2026-10-09), and
-- its badge counting the pods still growing.
--==============================================================================
local button = UIKit.railButton(playerGui, {
	name = "GardenButton",
	icon = RAIL.GardenIcon,
	wide = false,
	bare = true,
	-- GARDEN on a plate until the pot has loaded here (UIKit.railFallback).
	fallback = RAIL.Words.Garden,
})
button.AnchorPoint = Vector2.new(1, 0)
button.Position = UDim2.new(1, -RAIL.Inset, 0, RAIL.Inset)

local badge, badgeLabel = UIKit.badge(button, RAIL.Badge)
badge.Position = UDim2.new(0, 0, 0, 0)

local function placeButton()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	button.Position = HudLayout.place(layout.garden, button.AnchorPoint, layout.safe)
	-- Its size is the layout's: the rail's 50 x 50, or a phone column's 34-40
	-- (2026-10-09), the pot no larger than the button.
	UIKit.railShape(button, Vector2.new(layout.garden.w, layout.garden.h),
		math.min(RAIL.IconBare, layout.garden.w))
	-- The owner's studded Garden picture IS the button once it has loaded
	-- (2026-10-09, GameConfig.Rail.StuddedGardenArt); the pot and GARDEN stay
	-- under it until then, and for good if it never does.
	UIKit.railPicture(button, RAIL.StuddedGardenArt, 1)
	-- On a phone the owner's small pill on its top-RIGHT corner, over the gap
	-- above it (2026-10-09). In a desktop's or a TV's right-edge column tucked
	-- into its top-LEFT corner, toward the middle. In compact on its top-RIGHT
	-- corner at the left edge, or its top-LEFT where a small window keeps
	-- Garden top right (HudLayout.badges).
	if layout.sidebar then
		UIKit.railBadge(badge, true, "right", false, true)
	elseif layout.column then
		UIKit.railBadge(badge, true, "left")
	else
		UIKit.railBadge(badge, layout.compact, if layout.gardenRight then "left" else "right")
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(placeButton)
placeButton()

--==============================================================================
-- THE PANEL
--==============================================================================
local menu = MenuKit.modal(gui, PANEL_NAME, "MY PLANTS", RAIL.GardenIcon, nil)
UIKit.menuGui(gui, Vector2.new(300, 220))
local modal = menu.modal
local body = menu.body

local padFirst = Instance.new("ObjectValue")
padFirst.Name = "PadFirst"
padFirst.Parent = modal.shell

--==============================================================================
-- STATE
--==============================================================================
local open = false
local tab = "planted"
local selectedKey: string? = nil
-- The request at the server, if any: one at a time.
local pending: string? = nil
local pendingToken = 0
-- The profile's parts this reads (the server's push).
local prof = { held = nil :: { any }?, favourites = {} :: { [string]: boolean }, hotbar = {} :: { string } }

local refresh: () -> ()

--==============================================================================
-- THE HEADER: PLANTED / STORED, and the plot's count
--==============================================================================
local tabs = MenuKit.segmented(body, Z, { "planted", "stored" }, { planted = "PLANTED", stored = "STORED" })
local count = MenuKit.frame(body, "Count", Z, LOOK.Well, LOOK.WellTransparency, 9)
MenuKit.keyline(count, LOOK.WellEdge, 1, 0.3)
local countLabel = MenuKit.text(count, "Label", 15, LOOK.Text, Z + 1)
countLabel.Size = UDim2.fromScale(1, 1)
countLabel.RichText = true
-- SORT (2026-10-10, the owner): Rarity, Income, Newest -- the earners' order and
-- the stored creatures', saved per player (GameConfig.Sort.Plants). A sent
-- press waits for its own echo (plantsSortPending), as the Bag's does.
local sortButton = MenuKit.sortButton(body, Z)
local plantsSort: string = GameConfig.Sort.Default
local plantsSortPending: string? = nil
sortButton.set(plantsSort)

--==============================================================================
-- THE GRID
--==============================================================================
local grid = Instance.new("ScrollingFrame")
grid.Name = "Creatures"
grid.BackgroundColor3 = LOOK.Well
grid.BackgroundTransparency = LOOK.WellTransparency
grid.BorderSizePixel = 0
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.ScrollBarThickness = 5
grid.ScrollBarImageColor3 = LOOK.WellEdge
grid.CanvasSize = UDim2.new()
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.ElasticBehavior = Enum.ElasticBehavior.Always
grid.Selectable = false
grid.ZIndex = Z
grid.Parent = body
UIKit.corner(grid, 10)
MenuKit.keyline(grid, LOOK.WellEdge, 1, 0.3)
local gridPad = Instance.new("UIPadding")
gridPad.Parent = grid
local gridLayout = Instance.new("UIGridLayout")
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
gridLayout.Parent = grid

local emptyLabel = MenuKit.body(body, "Empty", 15, LOOK.Muted, Z + 3)
emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
emptyLabel.TextWrapped = true
emptyLabel.Visible = false

--==============================================================================
-- THE FOOTER: outside the scroll, always there
--==============================================================================
local income = MenuKit.frame(body, "Income", Z, LOOK.Well, LOOK.WellTransparency, 9)
MenuKit.keyline(income, LOOK.WellEdge, 1, 0.3)
local incomeLabel = MenuKit.text(income, "Label", 15, LOOK.Text, Z + 1)
incomeLabel.Position = UDim2.fromOffset(10, 0)
incomeLabel.Size = UDim2.new(1, -16, 1, 0)
incomeLabel.TextXAlignment = Enum.TextXAlignment.Left
incomeLabel.RichText = true
incomeLabel.TextScaled = true
do
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 15
	fit.MinTextSize = 10
	fit.Parent = incomeLabel
end
local action = MenuKit.button(body, "Action", Z, "SELECT A PLANT", 14)
-- The panel's call to action wears the studs (the global UI pass, 2026-10-04).
local best = MenuKit.button(body, "EquipBest", Z, "EQUIP BEST", 14, { studs = true })
best.style("go")
local clear = MenuKit.button(body, "UnequipAll", Z, "UNEQUIP ALL", 14)
clear.style("sky")

--==============================================================================
-- UNEQUIP ALL ASKS FIRST: a small sheet over the grid, its own two buttons.
--==============================================================================
local confirm = MenuKit.frame(body, "Confirm", Z + 8, LOOK.Sheet, 0.02, 10)
confirm.Active = true
confirm.Visible = false
MenuKit.keyline(confirm, LOOK.SheetEdge, 1.5, 0.15)
local confirmText = MenuKit.body(confirm, "Text", 16, LOOK.Text, Z + 9)
confirmText.Position = UDim2.fromOffset(14, 10)
confirmText.Size = UDim2.new(1, -28, 0, 56)
confirmText.TextWrapped = true
local confirmNo = MenuKit.button(confirm, "Cancel", Z + 9, "CANCEL", 15)
confirmNo.style("sky")
-- Taking every plant off the plot: the red remove face.
local confirmYes = MenuKit.button(confirm, "Yes", Z + 9, "UNEQUIP ALL", 15)
confirmYes.style("danger")

--==============================================================================
-- ONE CARD PER CREATURE, POOLED BY KEY ("p:<placementId>", "i:<item>")
--==============================================================================
type Card = {
	holder: Frame,
	button: TextButton,
	edge: UIStroke,
	-- The face's white-to-mint gradient, tinted by a grown plant's rarity.
	tint: UIGradient,
	ring: UIStroke,
	innerRing: UIStroke,
	preview: UIKit.ItemPreview,
	name: TextLabel,
	variant: TextLabel,
	rate: TextLabel,
	heart: InventoryTile.Heart,
	slot: TextLabel,
	-- The studded background and the quiet backing under the words (2026-10-04).
	studs: UIKit.StudCard,
	words: Frame,
	fxText: RarityFX.Handle,
	fxEdge: RarityFX.Handle,
	-- A Mythic, Divine or Secret card's shine over its studs (2026-10-10).
	fxShine: RarityFX.Handle,
	shownKey: string,
	art: any,
	artKey: string,
}
local cards: { [string]: Card } = {}
local cardW, cardH, previewH = 130, 130, 72

type Entry = {
	key: string,
	kind: string, -- "planted" | "pod" | "stored"
	item: any,
	face: any,
	id: number?, -- a placement id
	itemId: string?,
	hatchAt: number?,
	rate: number,
	restoring: boolean,
	ref: string?,
}
local entries: { Entry } = {}
local byKey: { [string]: Entry } = {}

local function shapeCard(c: Card)
	c.preview.holder.Position = UDim2.fromOffset(4, 4)
	c.preview.holder.Size = UDim2.fromOffset(cardW - 8, previewH)
	c.name.Position = UDim2.fromOffset(5, 4 + previewH + 2)
	c.name.Size = UDim2.fromOffset(cardW - 10, 18)
	c.variant.Position = UDim2.fromOffset(5, 4 + previewH + 20)
	c.variant.Size = UDim2.fromOffset(cardW - 10, 15)
	c.rate.Position = UDim2.fromOffset(5, 4 + previewH + 36)
	c.rate.Size = UDim2.fromOffset(cardW - 10, 16)
	c.words.Position = UDim2.fromOffset(3, 4 + previewH + 1)
	c.words.Size = UDim2.fromOffset(cardW - 6, 53)
	c.heart.frame.Position = UDim2.fromOffset(cardW - 18, previewH - 12)
end

local function select(key: string?)
	if selectedKey ~= key then
		selectedKey = key
		SoundKit.play("CardClick")
		refresh()
	end
end

local function cardFor(key: string): Card
	local made = cards[key]
	if made then
		return made
	end
	local holder = MenuKit.frame(grid, "Card_" .. key, Z + 1)
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
	-- THE COLOURFUL STUDDED CARD (2026-10-04): a grown creature's card wears the
	-- upload nearest its rarity's own colour (InventoryModel.face's `studs`;
	-- UIKit.studCard, the solid colour until the picture has loaded), its words
	-- on a quiet ink backing so the name, the rarity's own word and the income
	-- read on any colour. A Common and a pod keep the plain card.
	local studs = UIKit.studCard(face, 8, Z + 1)
	-- The three rarest's shine (2026-10-10): right after the studs, so over
	-- them and under the picture and words made after it.
	local fxShine = RarityFX.shine(face, 8, Z + 1)
	local words = MenuKit.frame(face, "Words", Z + 4, STUD_LOOK.StudWords, STUD_LOOK.StudWordsTransparency, 6)
	words.Visible = false
	-- The selection: a lit ring standing just outside the card.
	local ringFrame = MenuKit.frame(face, "Selected", Z + 6)
	ringFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	ringFrame.Position = UDim2.fromScale(0.5, 0.5)
	ringFrame.Size = UDim2.new(1, 4, 1, 4)
	UIKit.corner(ringFrame, 10)
	local ring = MenuKit.keyline(ringFrame, HOT.LitTop, 2.5)
	ring.Enabled = false
	-- And a white line ON the card's edge (2026-10-04): the gold ring outside
	-- reads on the light panel, the white one on any studded colour -- the gold
	-- card's too -- so a selection is never colour on colour.
	local innerFrame = MenuKit.frame(face, "SelectedInner", Z + 6)
	innerFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	innerFrame.Position = UDim2.fromScale(0.5, 0.5)
	innerFrame.Size = UDim2.new(1, -2, 1, -2)
	UIKit.corner(innerFrame, 7)
	local innerRing = MenuKit.keyline(innerFrame, WHITE, 2)
	innerRing.Enabled = false
	local preview = UIKit.itemPreview(face, { name = "Preview", scrim = 1, fit = 0.9 })
	preview.hero.Ambient = LOOK.PreviewAmbient
	for _, d in ipairs(preview.holder:GetDescendants()) do
		if d:IsA("GuiObject") then
			d.ZIndex = math.max(d.ZIndex, Z + 2)
		end
	end
	local name = MenuKit.text(face, "Name", 14, LOOK.Text, Z + 5)
	name.TextScaled = true
	do
		local fit = Instance.new("UITextSizeConstraint")
		fit.MaxTextSize = 14
		fit.MinTextSize = 10
		fit.Parent = name
	end
	local variant = MenuKit.text(face, "Variant", 12, LOOK.Muted, Z + 5)
	variant.TextTruncate = Enum.TextTruncate.AtEnd
	-- A size or rarity word keeps its ink line whatever its colour (a gold
	-- Legendary on white needs it); RarityFX tunes that same line.
	MenuKit.keepInk(variant)
	local rate = MenuKit.text(face, "Rate", 13, LOOK.Money, Z + 5)
	rate.TextTruncate = Enum.TextTruncate.AtEnd
	local heart = InventoryTile.heart(face, 12, Z + 6)
	heart.frame.Visible = false
	-- The hotbar slot a stored creature is a shortcut on, top left.
	local slot = MenuKit.text(face, "Slot", 12, HOT.NumeralLit, Z + 6)
	slot.Position = UDim2.fromOffset(4, 3)
	slot.Size = UDim2.fromOffset(18, 16)
	slot.BackgroundColor3 = LOOK.Ink
	slot.BackgroundTransparency = 0.2
	UIKit.corner(slot, 5)
	slot.Visible = false
	local scale = Instance.new("UIScale")
	scale.Parent = face
	UIKit.cardPop(face, scale, { hoverScale = 1.04, pressScale = 0.97, sound = false })
	local c: Card = {
		holder = holder,
		button = face,
		edge = edge,
		tint = tint,
		ring = ring,
		innerRing = innerRing,
		preview = preview,
		name = name,
		variant = variant,
		rate = rate,
		heart = heart,
		slot = slot,
		studs = studs,
		words = words,
		fxText = RarityFX.text(variant, variant:FindFirstChildOfClass("UIStroke")),
		fxEdge = RarityFX.edge(face, 8, Z + 4),
		fxShine = fxShine,
		shownKey = "",
		art = nil,
		artKey = "",
	}
	shapeCard(c)
	MenuKit.tap(face, grid, function()
		select(if selectedKey == key then nil else key)
	end)
	cards[key] = c
	return c
end

-- A card's picture, built only once it has been on screen with the panel open;
-- its rarity light moving only while it is in view.
local function buildVisible()
	local at, size = grid.AbsolutePosition, grid.AbsoluteSize
	for _, c in pairs(cards) do
		local p, s = c.holder.AbsolutePosition, c.holder.AbsoluteSize
		local shown = open and grid.Visible and c.holder.Visible
		local near = shown and p.Y + s.Y >= at.Y - 40 and p.Y <= at.Y + size.Y + 40
		if near and c.art and c.shownKey ~= c.artKey then
			local builder, kind = ItemArt.builder(c.artKey, c.art)
			c.preview.setModel(c.artKey, builder, kind)
			c.shownKey = c.artKey
		end
		local inView = shown and p.Y + s.Y > at.Y and p.Y < at.Y + size.Y
		RarityFX.setActive(c.fxText, inView)
		RarityFX.setActive(c.fxEdge, inView)
		RarityFX.setActive(c.fxShine, inView)
	end
end
grid:GetPropertyChangedSignal("CanvasPosition"):Connect(buildVisible)
gridLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	task.defer(buildVisible)
end)

-- A card that takes a controller's focus is scrolled into view whole.
GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
	local sel = GuiService.SelectedObject
	if not (open and sel and sel:IsDescendantOf(grid)) then
		return
	end
	local k = UIKit.scaleOf(gui)
	local top = (sel.AbsolutePosition.Y - grid.AbsolutePosition.Y) / k + grid.CanvasPosition.Y
	local bottom = top + sel.AbsoluteSize.Y / k
	local view = grid.AbsoluteSize.Y / k
	local total = gridLayout.AbsoluteContentSize.Y / k + PL.GridInset * 2
	grid.CanvasPosition = Vector2.new(0, UIKit.scrollToShow(grid.CanvasPosition.Y, view, top - 6, bottom + 6, total))
end)

--==============================================================================
-- READING THE DIRT AND THE BAG
--==============================================================================
local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local function clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds))
	if s >= 3600 then
		return string.format("%d:%02d:%02d", s // 3600, (s % 3600) // 60, s % 60)
	end
	return string.format("%d:%02d", s // 60, s % 60)
end

local function myPlot(): Model?
	for _, instance in ipairs(CollectionService:GetTagged(GameConfig.Tags.Plot)) do
		if instance:IsA("Model") and instance:GetAttribute(ATTR.OwnerUserId) == player.UserId then
			return instance
		end
	end
	return nil
end

local function passMultiplier(): number
	local m = tonumber(player:GetAttribute(GameConfig.Pass.MultiplierAttribute))
	return if m and m == m and m >= 1 then m else 1
end

-- The Bag-style item for a creature, so its face (name, size or rarity, art)
-- is the Bag's own (InventoryModel.face).
local function creature(speciesId: string, tier: number, hatched: boolean): any
	return {
		ref = nil,
		kind = if hatched then "plant" else "pod",
		tool = nil,
		restoring = false,
		speciesId = speciesId,
		tier = tier,
		hatched = hatched,
		sealed = false,
		weaponId = nil,
		count = 1,
		worn = false,
		favourite = false,
		order = 0,
	}
end

-- Which of two creatures comes first under the player's sort (2026-10-10):
-- `rarity` the rarer (GameConfig.RarityTier), `newest` the larger `fresh` (a
-- placement or an item id: they only grow); then -- and always for `income` --
-- the better earner, and the smaller `fresh` on a tie.
local TIER: { [string]: number } = (GameConfig.RarityTier :: any)
local function before(a: Entry, b: Entry, fresh: (Entry) -> number): boolean
	if plantsSort == "rarity" then
		local ta, tb = TIER[a.face.rarity or ""] or 0, TIER[b.face.rarity or ""] or 0
		if ta ~= tb then
			return ta > tb
		end
	elseif plantsSort == "newest" then
		local fa, fb = fresh(a), fresh(b)
		if fa ~= fb then
			return fa > fb
		end
	end
	if a.rate ~= b.rate then
		return a.rate > b.rate
	end
	return fresh(a) < fresh(b)
end
local function placedOf(e: Entry): number
	return e.id or 0
end
local function itemOf(e: Entry): number
	return tonumber(e.itemId) or 0
end

local function plantedEntries(plot: Model?): ({ Entry }, number, number)
	local out: { Entry } = {}
	local growingPods, grown = 0, 0
	local folder = plot and plot:FindFirstChild(GameConfig.Plot.PlantsFolderName)
	if not folder then
		return out, 0, 0
	end
	local now = serverNow()
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and CollectionService:HasTag(model, GameConfig.Tags.Planted) then
			local species = SeedData.Get(tostring(model:GetAttribute("SpeciesId")))
			local tier = tonumber(model:GetAttribute("Tier"))
			local id = tonumber(model:GetAttribute("PlacementId"))
			local stage = tonumber(model:GetAttribute("Stage"))
			if species and tier and id and stage then
				local isGrown = stage ~= 1
				local item = creature(species.Id, tier, isGrown)
				local hatchAt = tonumber(model:GetAttribute("HatchAt"))
				local itemId = model:GetAttribute(ATTR.ItemId)
				if isGrown then
					grown += 1
				elseif hatchAt and hatchAt > now then
					growingPods += 1
				end
				table.insert(out, {
					key = "p:" .. id,
					kind = if isGrown then "planted" else "pod",
					item = item,
					face = InventoryModel.face(item),
					id = id,
					itemId = if type(itemId) == "string" then itemId else nil,
					hatchAt = hatchAt,
					rate = if isGrown then SeedData.IncomePerSecond(species, tier) * passMultiplier() else 0,
					restoring = false,
					ref = if type(itemId) == "string" then HotbarSlots.item(itemId) else nil,
				})
			end
		end
	end
	-- Earners first, in the player's sort (`before`; newest = last planted);
	-- then the pods, soonest first, whatever the sort.
	table.sort(out, function(a: Entry, b: Entry): boolean
		if (a.kind == "pod") ~= (b.kind == "pod") then
			return a.kind ~= "pod"
		end
		if a.kind == "pod" then
			return (a.hatchAt or 0) < (b.hatchAt or 0)
		end
		return before(a, b, placedOf)
	end)
	return out, growingPods, grown
end

local function toolsNow(): { Instance }
	local list: { Instance } = {}
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs((container :: Instance):GetChildren()) do
				if child:IsA("Tool") then
					table.insert(list, child)
				end
			end
		end
	end
	return list
end

-- Every stored, fully hatched creature the profile has -- shortcut or not.
local function storedEntries(): { Entry }
	local out: { Entry } = {}
	if prof.held == nil then
		return out
	end
	local items = InventoryModel.collect({
		held = prof.held,
		tools = toolsNow(),
		weapons = nil,
		tickets = 0,
		trailOwned = false,
		trailWorn = false,
		favourites = prof.favourites,
		sealedUntil = {},
		now = serverNow(),
	} :: any)
	for _, item in ipairs(items) do
		local ref = item.ref
		if item.kind == "plant" and item.hatched and not item.sealed and ref then
			local _, itemId = HotbarSlots.parse(ref)
			local species = SeedData.Get(item.speciesId or "")
			if species and itemId then
				table.insert(out, {
					key = "i:" .. itemId,
					kind = "stored",
					item = item,
					face = InventoryModel.face(item),
					id = nil,
					itemId = itemId,
					hatchAt = nil,
					rate = SeedData.IncomePerSecond(species, item.tier) * passMultiplier(),
					restoring = item.restoring,
					ref = ref,
				})
			end
		end
	end
	-- In the player's sort (`before`; newest = the latest item).
	table.sort(out, function(a: Entry, b: Entry): boolean
		return before(a, b, itemOf)
	end)
	return out
end

local function slotOf(ref: string?): number?
	if not ref then
		return nil
	end
	for i, r in ipairs(prof.hotbar) do
		if r == ref then
			return i
		end
	end
	return nil
end

--==============================================================================
-- PAINTING
--==============================================================================
local function money(n: number): string
	return "$" .. GameConfig.compact(n) .. "/s"
end

local function paintCard(c: Card, e: Entry, order: number)
	local face = e.face
	local selected = e.key == selectedKey
	c.holder.Visible = true
	c.holder.LayoutOrder = order
	c.name.Text = face.name
	c.art = face.art
	c.artKey = face.visual
	c.ring.Enabled = selected
	c.innerRing.Enabled = selected
	if e.kind == "pod" then
		RarityFX.setText(c.fxText, nil, face.variantColour or LOOK.Muted)
		c.variant.Text = face.variant
		local left = (e.hatchAt or 0) - serverNow()
		c.rate.Text = if left > 0 then "Growing " .. clock(left) else "READY TO HATCH"
		c.rate.TextColor3 = if left > 0 then LOOK.Muted else LOOK.Premium
		RarityFX.setEdge(c.fxEdge, nil, false)
		c.edge.Color = LOOK.CardEdge
		-- A pod's card stays plain: it says nothing a pod does not.
		MenuKit.cardTint(c.tint, nil)
		c.studs.set(nil)
		RarityFX.setShine(c.fxShine, nil)
		c.words.Visible = false
		MenuKit.ink(c.name, LOOK.Text)
	else
		c.variant.Text = face.variant
		RarityFX.setText(c.fxText, if face.variantIsRarity then face.rarity else nil, face.variantColour or LOOK.Muted)
		c.rate.Text = if e.restoring then "Restoring…" else money(e.rate)
		local spec = c.studs.set(face.studs)
		local studded = spec ~= nil
		c.words.Visible = studded
		-- The white card (2026-10-10): its words on a denser band, and the
		-- selection's line on its edge dark, where a white one would vanish.
		c.words.BackgroundTransparency = if spec and spec.words then spec.words else STUD_LOOK.StudWordsTransparency
		c.innerRing.Color = if spec and spec.light then LOOK.Ink else WHITE
		RarityFX.setShine(c.fxShine, if studded and not e.restoring then face.rarity else nil)
		MenuKit.ink(c.name, if studded then WHITE else LOOK.Text)
		c.rate.TextColor3 = if e.restoring then (if studded then LOOK.Cream else LOOK.Muted)
			elseif studded then STUD_LOOK.StudMoney
			else LOOK.Money
		RarityFX.setEdge(c.fxEdge, face.rarity, not selected)
		local rare = RarityFX.edgeColour(face.rarity)
		c.edge.Color = rare or (if studded then LOOK.Ink else LOOK.CardEdge)
		MenuKit.cardTint(c.tint, if face.rarity then GameConfig.RarityColor[face.rarity] else nil)
	end
	c.heart.frame.Visible = e.ref ~= nil and prof.favourites[e.ref :: string] == true
	local slot = slotOf(e.ref)
	c.slot.Visible = slot ~= nil
	c.slot.Text = if slot then (if slot == 10 then "0" else tostring(slot)) else ""
end

-- The server's answer, said IN the panel for a few seconds where the income
-- line is: the notices are drawn under an open panel, so a player looking at
-- MY PLANTS would otherwise never see why a press did nothing.
local sayText: string? = nil
local sayUntil = 0

local function paintFooter(plot: Model?, total: number, capacity: number)
	local rate = if plot then tonumber(plot:GetAttribute(ATTR.GardenIncome)) else nil
	if sayText and os.clock() < sayUntil then
		incomeLabel.Text = sayText :: string
	else
		sayText = nil
		incomeLabel.Text = string.format('Garden <font color="#%s">%s</font>', LOOK.Money:ToHex(),
			money(rate or 0))
	end
	countLabel.Text = string.format('Plot <font color="#%s">%d/%d</font>',
		(if total >= capacity then LOOK.Premium else LOOK.Money):ToHex(), total, capacity)
	local sel = if selectedKey then byKey[selectedKey :: string] else nil
	-- A button that cannot do anything now is flat grey (`off`), the main
	-- actions green, UNEQUIP ALL the secondary sky blue.
	if pending then
		action.style("off")
		action.set("WORKING...")
	elseif not sel then
		action.style("off")
		action.set(if tab == "stored" then "SELECT TO PLANT" else "SELECT A PLANT")
	elseif sel.kind == "stored" then
		action.style(if sel.restoring then "off" else "go")
		action.set(if sel.restoring then "RESTORING..." else "PLANT")
	elseif sel.kind == "planted" then
		action.style("go")
		action.set("RETURN TO BAG")
	else
		local left = (sel.hatchAt or 0) - serverNow()
		action.style("off")
		-- A ready pod is hatched by hand AT the pod, as it always was: the
		-- key that works there, on this device.
		action.set(if left > 0 then "GROWING " .. clock(left)
			elseif PadInput.active() then "HOLD [" .. PadInput.short(Enum.KeyCode.ButtonX) .. "] AT THE POD"
			elseif UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then "HOLD AT THE POD"
			else "HOLD [E] AT THE POD")
	end
	best.style(if pending then "off" else "go")
	clear.style(if pending then "off" else "sky")
end

local function paintBadge(growingPods: number)
	badge.Visible = growingPods > 0
	badgeLabel.Text = tostring(growingPods)
end

refresh = function()
	local plot = myPlot()
	local planted, growingPods, _grown = plantedEntries(plot)
	paintBadge(growingPods)
	local capacity = tonumber(plot and plot:GetAttribute("Capacity")) or 0
	if not open then
		paintFooter(plot, #planted, capacity)
		return
	end
	local stored = storedEntries()
	entries = if tab == "planted" then planted else stored
	table.clear(byKey)
	for _, e in ipairs(planted) do
		byKey[e.key] = e
	end
	for _, e in ipairs(stored) do
		byKey[e.key] = e
	end
	-- A selection that has gone (planted, returned, sold) is let go.
	if selectedKey and not byKey[selectedKey :: string] then
		selectedKey = nil
	end
	local seen: { [string]: boolean } = {}
	for i, e in ipairs(entries) do
		local c = cardFor(e.key)
		paintCard(c, e, i)
		seen[e.key] = true
	end
	for key, c in pairs(cards) do
		if not seen[key] then
			c.holder.Visible = false
			RarityFX.setActive(c.fxText, false)
			RarityFX.setActive(c.fxEdge, false)
			RarityFX.setActive(c.fxShine, false)
		end
	end
	local first = entries[1]
	padFirst.Value = if first then cards[first.key].button else tabs.buttons[tab]
	emptyLabel.Visible = #entries == 0
	emptyLabel.Text = if tab == "planted"
		then "Nothing planted yet. Plant a creature from STORED, or press EQUIP BEST."
		else "No hatched creatures in your Bag."
	paintFooter(plot, #planted, capacity)
	task.defer(buildVisible)
end

--==============================================================================
-- LAYOUT: MenuLayout's answer, applied (the gui's own units)
--==============================================================================
local function relayout()
	local k = UIKit.scaleOf(gui)
	local safe = gui.AbsoluteSize / UIKit.scaleOf(gui)
	if safe.X < 100 or safe.Y < 100 then
		return
	end
	local hud = HudLayout.solve(HudLayout.measure(gui))
	local camera = Workspace.CurrentCamera
	local hudScale = if HudLayout.isTenFoot() and camera then HudLayout.tenFootScale(camera.ViewportSize) else 1
	local f = k / hudScale
	local p = MenuLayout.plantsPanel({
		safe = safe,
		compact = hud.compact,
		railRight = hud.railRight / f,
		rightLeft = hud.rightLeft / f,
		-- A phone draws this gui smaller (UIKit.menuScaleFor): the panel keeps its room.
		fill = math.min(1, k),
		keyboardTop = nil,
	}, RAIL.OutlineThickness)
	menu.place(p)
	local b = MenuLayout.blocks(p)
	local gap = MenuLayout.Config.Gap
	local touch = MenuLayout.Config.Touch
	local rowY = math.floor((p.header - touch) / 2)
	local row = MenuLayout.plantsHeader(p, MenuKit.titleWidth(menu, p.short))
	local tr = row.tabs
	tabs.frame.Position = UDim2.fromOffset(tr.x, rowY + 2)
	tabs.frame.Size = UDim2.fromOffset(tr.w, touch - 4)
	local cr = row.count
	count.Visible = cr ~= nil
	if cr then
		count.Position = UDim2.fromOffset(cr.x, rowY + 4)
		count.Size = UDim2.fromOffset(cr.w, touch - 8)
	end
	local sr = row.sort
	sortButton.button.Visible = sr ~= nil
	if sr then
		sortButton.button.Position = UDim2.fromOffset(sr.x, rowY + 2)
		sortButton.button.Size = UDim2.fromOffset(sr.w, touch - 4)
	end
	-- The grid over the footer; the footer at the main block's foot.
	local main = b.main
	local footerY = main.y + main.h - PL.FooterH
	grid.Position = UDim2.fromOffset(main.x, main.y)
	grid.Size = UDim2.fromOffset(main.w, main.h - PL.FooterH - gap)
	local cg = MenuLayout.plantsCards(p, main.w - grid.ScrollBarThickness)
	cardW, cardH, previewH = cg.cardW, cg.cardH, cg.previewH
	gridLayout.CellSize = UDim2.fromOffset(cardW, cardH)
	gridLayout.CellPadding = UDim2.fromOffset(PL.CardGap, PL.CardGap)
	gridPad.PaddingLeft = UDim.new(0, PL.GridInset)
	gridPad.PaddingRight = UDim.new(0, PL.GridInset)
	gridPad.PaddingTop = UDim.new(0, PL.GridInset)
	gridPad.PaddingBottom = UDim.new(0, PL.GridInset)
	for _, c in pairs(cards) do
		shapeCard(c)
	end
	emptyLabel.Position = UDim2.fromOffset(main.x + main.w / 2, main.y + math.min((main.h - PL.FooterH) * 0.4, 70))
	emptyLabel.Size = UDim2.fromOffset(math.max(80, main.w - 40), 50)
	local foot = MenuLayout.plantsFooter(main.w)
	local function put(obj: GuiObject, r: MenuLayout.Rect)
		obj.Position = UDim2.fromOffset(main.x + r.x, footerY)
		obj.Size = UDim2.fromOffset(r.w, PL.FooterH)
	end
	put(income, foot.income)
	income.Size = UDim2.fromOffset(foot.income.w, PL.FooterH - 8)
	income.Position = UDim2.fromOffset(main.x + foot.income.x, footerY + 4)
	put(action.hit, foot.action)
	put(best.hit, foot.best)
	put(clear.hit, foot.clear)
	-- The confirmation over the grid, centred.
	local cw, ch = math.min(main.w - 24, 380), 132
	confirm.Position = UDim2.fromOffset(main.x + (main.w - cw) / 2, main.y + math.max(4, (main.h - PL.FooterH - ch) / 2))
	confirm.Size = UDim2.fromOffset(cw, ch)
	confirmNo.hit.Position = UDim2.fromOffset(14, ch - 56)
	confirmNo.hit.Size = UDim2.fromOffset((cw - 40) / 2, 44)
	confirmYes.hit.Position = UDim2.fromOffset(26 + (cw - 40) / 2, ch - 56)
	confirmYes.hit.Size = UDim2.fromOffset((cw - 40) / 2, 44)
	UIKit.coverRail(playerGui, PANEL_NAME, open and p.covers)
	task.defer(buildVisible)
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
UIKit.onMenuSize(relayout)
relayout()

--==============================================================================
-- ASKING THE SERVER
--==============================================================================
local gameEvent: RemoteEvent? = nil

local function ask(op: string, payload: any)
	local channel = gameEvent
	if pending or not channel then
		SoundKit.play("Denied")
		return
	end
	pending = op
	pendingToken += 1
	local token = pendingToken
	SoundKit.play("CardClick")
	channel:FireServer(op, payload)
	refresh()
	task.delay(PATIENCE, function()
		if pendingToken == token and pending then
			pending = nil
			refresh()
		end
	end)
end

-- The server's answer, in words. A refusal changed nothing; say what would help.
local WORDS: { [string]: { kind: string, title: string, detail: string? } } = {
	PLANTED = { kind = "success", title = "PLANTED", detail = "It's earning on your plot." },
	RETURNED = { kind = "success", title = "RETURNED TO BAG", detail = "It's stored and no longer earning." },
	UNCHANGED = { kind = "info", title = "ALREADY YOUR BEST", detail = "Your best earners are already planted." },
	NOTHING = { kind = "info", title = "NOTHING TO UNEQUIP", detail = "No grown plants on your plot." },
	PLOT_FULL = { kind = "blocked", title = "GARDEN FULL", detail = "Return a plant or upgrade your plot." },
	STORAGE_FULL = { kind = "blocked", title = "PLANT STORAGE FULL", detail = "Not enough Bag room for that swap." },
	STORAGE_FULL_ALL = { kind = "blocked", title = "NOT ENOUGH BAG ROOM",
		detail = "Your Bag can't hold every plant. Nothing was moved." },
	NOT_READY = { kind = "blocked", title = "PLOT NOT READY", detail = "Try again in a moment." },
	NO_PLOT = { kind = "blocked", title = "NO PLOT YET" },
	NOT_STORED = { kind = "blocked", title = "NOT IN YOUR BAG", detail = "It may have been planted or sold." },
	NOT_PLANTED = { kind = "blocked", title = "NOT ON YOUR PLOT" },
	GROWING = { kind = "blocked", title = "STILL A POD", detail = "Hatch it at your plot first." },
	INCOMPLETE = { kind = "warning", title = "NOT EVERYTHING MOVED", detail = "Nothing was lost; some stayed where they were." },
	NOT_RECORDED = { kind = "blocked", title = "NOT SAVED YET", detail = "Nothing was moved. Try again." },
}

local SAY_COLOURS: { [string]: Color3 } = {
	success = LOOK.Money,
	info = LOOK.Text,
	warning = LOOK.Premium,
	blocked = Color3.fromRGB(196, 52, 40),
}

local function say(kind: string, title: string, detail: string?)
	Notice.post({ kind = kind :: any, title = title, detail = detail, key = "myplants:" .. title })
	sayText = string.format('<font color="#%s">%s</font>%s', (SAY_COLOURS[kind] or LOOK.Text):ToHex(), title,
		if detail then "  " .. detail else "")
	sayUntil = os.clock() + 3.5
	task.delay(3.6, refresh)
end

local function onReply(reply: any)
	if type(reply) ~= "table" then
		return
	end
	pending = nil
	local code = tostring(reply.code)
	local words = WORDS[code]
	if code == "EQUIPPED" then
		local planted, returned = tonumber(reply.planted) or 0, tonumber(reply.returned) or 0
		say("success", "BEST PLANTS EQUIPPED", string.format("%d in, %d to your Bag.", planted, returned))
	elseif code == "UNEQUIPPED" then
		say("success", "ALL PLANTS RETURNED",
			string.format("%d to your Bag. Pods stay planted.", tonumber(reply.returned) or 0))
	elseif words then
		say(words.kind, words.title, words.detail)
	end
	if reply.ok == true then
		selectedKey = nil
	end
	refresh()
end

MenuKit.tap(action.hit, nil, function()
	local sel = if selectedKey then byKey[selectedKey :: string] else nil
	if not sel or pending then
		SoundKit.play("Denied")
		return
	end
	if sel.kind == "stored" and not sel.restoring and sel.itemId then
		ask(MY.Plant, sel.itemId)
	elseif sel.kind == "planted" and sel.id then
		ask(MY.Return, sel.id)
	else
		SoundKit.play("Denied")
	end
end)
MenuKit.tap(best.hit, nil, function()
	ask(MY.Best, nil)
end)

local function showConfirm(want: boolean)
	confirm.Visible = want
	if want then
		local _, _, grown = plantedEntries(myPlot())
		confirmText.Text = string.format("Return all %d grown plant%s to your Bag? Growing pods stay planted.",
			grown, if grown == 1 then "" else "s")
		MenuKit.bindBack("SeedPlantsConfirm", function()
			showConfirm(false)
		end)
		if MenuKit.onPad() then
			GuiService.SelectedObject = confirmNo.hit
		end
	else
		MenuKit.unbind("SeedPlantsConfirm")
		if MenuKit.onPad() then
			GuiService.SelectedObject = clear.hit
		end
	end
end
MenuKit.tap(clear.hit, nil, function()
	if pending then
		SoundKit.play("Denied")
		return
	end
	SoundKit.play("CardClick")
	showConfirm(true)
end)
MenuKit.tap(confirmNo.hit, nil, function()
	SoundKit.play("CardClick")
	showConfirm(false)
end)
MenuKit.tap(confirmYes.hit, nil, function()
	showConfirm(false)
	ask(MY.Clear, nil)
end)

tabs.changed(function(id: string)
	tab = id
	selectedKey = nil
	grid.CanvasPosition = Vector2.zero
	refresh()
end)

-- SORT steps to the next order at once and asks the server to keep it; the
-- saved attribute (PlayerDataService) is followed whenever it is not the echo
-- of an older press.
sortButton.button.Activated:Connect(function()
	plantsSort = GameConfig.nextSort(plantsSort)
	sortButton.set(plantsSort)
	plantsSortPending = plantsSort
	local channel = gameEvent
	if channel then
		channel:FireServer(GameConfig.Sort.Plants.Action, plantsSort)
	end
	grid.CanvasPosition = Vector2.zero
	refresh()
end)
local function applyPlantsSort()
	local id = player:GetAttribute(GameConfig.Sort.Plants.Attribute)
	if plantsSortPending ~= nil then
		if id ~= plantsSortPending then
			return
		end
		plantsSortPending = nil
	end
	local want = GameConfig.sortOption(id) or GameConfig.Sort.Default
	if want ~= plantsSort then
		plantsSort = want
		sortButton.set(want)
		refresh()
	end
end
player:GetAttributeChangedSignal(GameConfig.Sort.Plants.Attribute):Connect(applyPlantsSort)
applyPlantsSort()

--==============================================================================
-- OPEN AND SHUT (the OpenPanel mutex; LB / RB switch the tabs)
--==============================================================================
local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		MenuKit.bindBumpers("SeedPlantsPad", function()
			tab = if tab == "planted" then "stored" else "planted"
			tabs.set(tab)
			selectedKey = nil
			grid.CanvasPosition = Vector2.zero
			SoundKit.play("CardClick")
			refresh()
		end)
	else
		if player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
			player:SetAttribute(ATTR.OpenPanel, nil)
		end
		showConfirm(false)
		selectedKey = nil
		MenuKit.unbind("SeedPlantsPad")
		for _, c in pairs(cards) do
			RarityFX.setActive(c.fxText, false)
			RarityFX.setActive(c.fxEdge, false)
			RarityFX.setActive(c.fxShine, false)
		end
	end
	relayout()
	refresh()
	modal.setOpen(want)
end

button.Activated:Connect(function()
	setOpen(not open)
end)
modal.close.Activated:Connect(function()
	setOpen(false)
end)
modal.dimmer.Activated:Connect(function()
	setOpen(false)
end)
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if open and player:GetAttribute(ATTR.OpenPanel) ~= PANEL_NAME then
		setOpen(false)
	end
end)
gui.Destroying:Connect(function()
	UIKit.coverRail(playerGui, PANEL_NAME, false)
	MenuKit.unbind("SeedPlantsPad")
	MenuKit.unbind("SeedPlantsConfirm")
end)

--==============================================================================
-- KEEPING UP
--
-- The plant tags arriving and leaving, the plot's attributes, the Bag's Tools
-- and the profile's push each repaint at once; the pods' clocks once a second,
-- and only the badge while the panel is shut.
--==============================================================================
local since = 0
RunService.Heartbeat:Connect(function(dt)
	since += dt
	if since < PLANTING.TickSeconds then
		return
	end
	since = 0
	refresh()
end)

local function soon()
	task.defer(refresh)
end
CollectionService:GetInstanceAddedSignal(GameConfig.Tags.Planted):Connect(soon)
CollectionService:GetInstanceRemovedSignal(GameConfig.Tags.Planted):Connect(soon)

local function watchContainer(container: Instance?)
	if container then
		container.ChildAdded:Connect(soon)
		container.ChildRemoved:Connect(soon)
	end
end
watchContainer(player:FindFirstChildOfClass("Backpack"))
player.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then
		watchContainer(child)
		soon()
	end
end)
if player.Character then
	watchContainer(player.Character)
end
player.CharacterAdded:Connect(function(character)
	watchContainer(character)
	soon()
end)

local function receive(profile: any)
	if type(profile) ~= "table" then
		return
	end
	if type(profile.Held) == "table" then
		prof.held = profile.Held
	end
	if type(profile.Favourites) == "table" then
		prof.favourites = profile.Favourites
	end
	if type(profile.Hotbar) == "table" then
		prof.hotbar = profile.Hotbar
	end
	soon()
end

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	if not remotes then
		warn("[Seed/GardenUI] No Remotes folder; MY PLANTS cannot ask for anything.")
		return
	end
	local updated = remotes:WaitForChild(GameConfig.Remotes.ProfileUpdated, 20)
	if updated and updated:IsA("RemoteEvent") then
		updated.OnClientEvent:Connect(receive)
	end
	local ready = remotes:WaitForChild(GameConfig.Remotes.ProfileReady, 20)
	if ready and ready:IsA("RemoteEvent") then
		ready.OnClientEvent:Connect(function(ok: boolean, profile: any)
			if ok then
				receive(profile)
			end
		end)
	end
	local channel = remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20)
	if channel and channel:IsA("RemoteEvent") then
		gameEvent = channel
		channel.OnClientEvent:Connect(function(verb: any, payload: any)
			if verb == MY.Reply then
				onReply(payload)
			end
		end)
	else
		warn("[Seed/GardenUI] No GameEvent remote; MY PLANTS cannot ask for anything.")
	end
end)

-- The plot's own numbers change under the panel (a hatch, an upgrade, a boost).
task.spawn(function()
	local watched: Model? = nil
	while gui.Parent do
		local plot = myPlot()
		if plot ~= watched then
			watched = plot
			if plot then
				plot:GetAttributeChangedSignal(ATTR.GardenIncome):Connect(soon)
				plot:GetAttributeChangedSignal("Capacity"):Connect(soon)
			end
		end
		task.wait(2)
	end
end)

refresh()
