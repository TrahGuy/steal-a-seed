--!strict
-- Steal a Seed :: IndexUI
--
-- THE PLANT ALMANAC. Every species in the game, one biome at a time, and which
-- of them you have actually grown.
--
-- What is in your dirt right now is GardenUI. This is the sheet.
--
--==============================================================================
-- THREE PANELS, FROM THE OWNER'S APPROVED MOCKUP (2026-09-11)
--
-- Biome tabs across the top pick a shelf. On the left, that biome's card: its
-- scenery, its name and how much of it is grown. In the middle, the shelf: the
-- biome's five species on sunlit rarity cards, a sixth slot for the Biome
-- Mastery trophy, and a five-step progress bar. On the right, the showcase for
-- whichever card was tapped: a large still 3D copy of the plant on a moss
-- pedestal, its name, rarity and base Garden Yield, and the biome's one-time
-- harvest reward with its CLAIM button. A footer counts the whole kingdom.
--
-- It was one scrolling grid of all twenty-five cards. Twenty-five is a wall;
-- five is a shelf you can read at a glance, and the tabs are the road.
--
-- NARROW SCREENS STACK. Below WIDE_AT the three panels become one column --
-- banner, shelf, showcase, footer -- in the same scroll, so a phone keeps every
-- card at a thumb's width instead of squeezing three columns into it.
--
--==============================================================================
-- A CARD WEARS ITS RARITY, GROWN OR NOT
--
-- This file used to hold the opposite rule: nothing on a locked card carried the
-- tier, because Epic means Bellchime in Greenhollow. The approved mockup reverses
-- that on purpose. An undiscovered card shows its rarity colour and word, a dark
-- silhouette and "???", so a player can see what KIND of find a shelf is still
-- missing. The name, the scenery and the plant's own colours stay hidden until
-- it has been grown.
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
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local AlmanacData = require(Shared:WaitForChild("AlmanacData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ALMANAC = GameConfig.Almanac
local RAIL = GameConfig.Rail
local CARD = GameConfig.Card
local ATTR = GameConfig.Attributes
local PANEL_NAME = "Index"

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
local INK = ALMANAC.Ink

--==============================================================================
-- THE MEASUREMENTS
--
-- Gui pixels. The two side columns are fixed and the shelf takes what is left,
-- because the shelf is the one with something to gain from width: every pixel
-- there is card. Every control a finger presses is at least 44 tall.
--==============================================================================
local MAX_WIDTH = 740
local MAX_HEIGHT = 620
-- Content width at which the three columns fit side by side.
local WIDE_AT = 600
local GAP = 10
local TOP_PAD = 8
local BOTTOM_PAD = 4
-- Room for the scroll bar, which draws over the content rather than beside it.
local SCROLL_GUTTER = 8
local TAB_HEIGHT = 44
local TAB_STRIP = TAB_HEIGHT + 8
local TAB_GAP = 6
local TAB_NARROW = 138
local LEFT_WIDTH = 124
local RIGHT_WIDTH = 214
local BANNER_HEIGHT = 84
local CARD_GUTTER = 8
local CARD_PAD = 6
-- A card is its diorama plus the name strip above it and the rarity tag below.
local CARD_CHROME = 56
local PROGRESS_HEIGHT = 36
local HARVEST_HEIGHT = 136
local FOOTER_WIDE = 56
local FOOTER_NARROW = 84
-- How much of its viewport a creature fills. A shelf diorama crops into its soil
-- the way the Garden's cards do; the showcase leaves room for the whole pedestal.
local CARD_FILL = 0.8
local STAGE_FILL = 0.6
-- How long a CLAIM waits for the server's answer before letting go.
local CLAIM_PATIENCE = 5

-- ZIndexBehavior is GLOBAL on these ScreenGuis, so these are compared across the
-- whole panel. The modal's own chrome sits at 1-3 and its click blocker at 2.
local Z_SCROLL = 3
local Z_PANEL = 4
local Z_FACE = 5
local Z_INSET = 6
local Z_VIEW = 7
local Z_TEXT = 8
local Z_RING = 9

--==============================================================================
-- THE ROAD, READ ONCE
--
-- Tab order is road order and a shelf is commonest first; both come from
-- AlmanacData, which the server's claim reads too.
--==============================================================================
local road = AlmanacData.Biomes()
local shelves: { [string]: { any } } = {}
local SEGMENTS = 0
for _, biome in ipairs(road) do
	shelves[biome.Id] = AlmanacData.SpeciesIn(biome.Id)
	SEGMENTS = math.max(SEGMENTS, #shelves[biome.Id])
end

--==============================================================================
-- SMALL BUILDERS
--==============================================================================
local function label(parent: Instance, name: string, size: number, colour: Color3,
	z: number): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.BackgroundTransparency = 1
	l.BorderSizePixel = 0
	l.Font = Enum.Font.FredokaOne
	l.TextSize = size
	l.TextColor3 = colour
	l.Text = ""
	l.ZIndex = z
	l.Parent = parent
	return l
end

-- The house display face (UIKit.outlined), keylined in this panel's ink.
local function display(parent: Instance, name: string, size: number, colour: Color3,
	z: number, thickness: number?): TextLabel
	local l = UIKit.outlined(parent, name, size, colour, thickness or 2)
	local line = l:FindFirstChildOfClass("UIStroke")
	if line then
		line.Color = INK
	end
	l.ZIndex = z
	return l
end

-- Scales a label down to fit its box, never up past `largest`. Names run from
-- "Nubkin" to "Supernovus" in the same card.
local function shrinkToFit(l: TextLabel, largest: number, smallest: number)
	l.TextScaled = true
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = largest
	limit.MinTextSize = smallest
	limit.Parent = l
end

local function well(parent: Instance, name: string, z: number, fill: Color3,
	transparency: number?, radius: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.BackgroundColor3 = fill
	f.BackgroundTransparency = transparency or 0
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Parent = parent
	UIKit.corner(f, radius or 12)
	return f
end

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
gui.DisplayOrder = 30
gui.Parent = playerGui

--==============================================================================
-- THE BUTTON
--
-- Blue slab, a book, and the word. All three are instances -- the crop that used
-- to carry them baked the label into a PNG and clipped its own border.
--==============================================================================
local button = UIKit.railButton(playerGui, {
	name = "IndexButton",
	icon = RAIL.IndexIcon,
	face = RAIL.IndexFace,
	shade = RAIL.IndexShade,
	label = "Index",
	wide = true,
})
button.Position = UDim2.new(0, RAIL.Inset, 0, RAIL.Inset)

local badge, badgeCount = UIKit.badge(button, RAIL.Badge)

--==============================================================================
-- THE PANEL
--
-- The shop's chrome in the almanac's colours: a leaf-green header banner, a red
-- close plate, and a deep moss body. Every colour is GameConfig.Almanac.
--==============================================================================
local modal = UIKit.modal(gui, {
	name = PANEL_NAME,
	title = "Plant Almanac",
	maxWidth = MAX_WIDTH,
	maxHeight = MAX_HEIGHT,
	titleColour = WHITE,
	theme = {
		fill = ALMANAC.BodyTop,
		shade = ALMANAC.BodyBottom,
		outline = INK,
		lattice = ALMANAC.BodyLattice,
		latticeTransparency = ALMANAC.BodyLatticeTransparency,
		latticeZIndex = 1,
		headerTop = ALMANAC.HeaderTop,
		headerBottom = ALMANAC.HeaderBottom,
		headerRule = INK,
		titleStroke = INK,
		titleStrokeThickness = 2,
		closeTop = ALMANAC.CloseTop,
		closeBottom = ALMANAC.CloseBottom,
		closeShade = ALMANAC.CloseShade,
		closeRadius = 8,
	},
})

local titleBar = modal.title.Parent :: Frame
modal.title.TextSize = 28
modal.title.Position = UDim2.new(0, 50, 0.5, 0)
modal.title.Size = UDim2.new(1, -104, 1, 0)

-- The open book, on a leaf tile of its own so it reads against the banner.
local mark = well(titleBar, "AlmanacMark", 4, WHITE, 0, 10)
mark.AnchorPoint = Vector2.new(0, 0.5)
mark.Position = UDim2.new(0, 0, 0.5, 0)
mark.Size = UDim2.fromOffset(38, 38)
UIKit.stroke(mark, INK, 2)
UIKit.gradient(mark, ALMANAC.MarkTop, ALMANAC.MarkBottom)
local markGlyph = label(mark, "Glyph", 22, WHITE, 5)
markGlyph.Size = UDim2.fromScale(1, 1)
markGlyph.Text = "📖"

--==============================================================================
-- STUDS ON THE MOSS
--
-- One tiled texture instead of the modal's lattice, which is diagonal lines and
-- not the dotted ground the mockup has. Tiled means one instance for the whole
-- body however large the panel is. With no upload recorded, the lattice stays.
--==============================================================================
if ALMANAC.DotTexture ~= "" then
	local lattice = modal.shell:FindFirstChild("Lattice")
	if lattice and lattice:IsA("GuiObject") then
		lattice.Visible = false
	end
	local studs = Instance.new("ImageLabel")
	studs.Name = "Studs"
	studs.Size = UDim2.fromScale(1, 1)
	studs.BackgroundTransparency = 1
	studs.BorderSizePixel = 0
	studs.Image = ALMANAC.DotTexture
	studs.ImageColor3 = ALMANAC.DotColour
	studs.ImageTransparency = ALMANAC.DotTransparency
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(ALMANAC.DotTile, ALMANAC.DotTile)
	studs.ZIndex = 1
	studs.Parent = modal.shell
	UIKit.corner(studs, 16)
end

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "Almanac"
scroll.Size = UDim2.fromScale(1, 1)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollingDirection = Enum.ScrollingDirection.Y
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = ALMANAC.WellEdge
scroll.VerticalScrollBarInset = Enum.ScrollBarInset.None
scroll.CanvasSize = UDim2.new()
scroll.Selectable = false
scroll.ZIndex = Z_SCROLL
scroll.Parent = modal.body

local content = Instance.new("Frame")
content.Name = "Content"
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ZIndex = Z_SCROLL
content.Parent = scroll

--==============================================================================
-- THE BIOME TABS
--
-- A strip that scrolls sideways when it has to: five equal tabs on a wide panel,
-- and fixed-width tabs a thumb can drag through on a phone.
--==============================================================================
local tabStrip = well(content, "Biomes", Z_PANEL, ALMANAC.Well, 0.1, 12)
UIKit.stroke(tabStrip, ALMANAC.WellEdge, 1.5)

local tabScroll = Instance.new("ScrollingFrame")
tabScroll.Name = "Tabs"
tabScroll.Position = UDim2.fromOffset(4, 4)
tabScroll.Size = UDim2.new(1, -8, 1, -8)
tabScroll.BackgroundTransparency = 1
tabScroll.BorderSizePixel = 0
tabScroll.ScrollingDirection = Enum.ScrollingDirection.X
tabScroll.ScrollBarThickness = 0
tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
tabScroll.CanvasSize = UDim2.new()
tabScroll.Selectable = false
tabScroll.ZIndex = Z_PANEL
tabScroll.Parent = tabStrip

local tabList = Instance.new("UIListLayout")
tabList.FillDirection = Enum.FillDirection.Horizontal
tabList.VerticalAlignment = Enum.VerticalAlignment.Center
tabList.SortOrder = Enum.SortOrder.LayoutOrder
tabList.Padding = UDim.new(0, TAB_GAP)
tabList.Parent = tabScroll

type Tab = {
	button: TextButton,
	tint: UIGradient,
	edge: UIStroke,
	text: TextLabel,
	textLine: UIStroke,
	ready: Frame,
}
local tabs: { [string]: Tab } = {}

for _, biome in ipairs(road) do
	local hit = Instance.new("TextButton")
	hit.Name = biome.Id
	hit.LayoutOrder = biome.Order
	hit.Size = UDim2.fromOffset(TAB_NARROW, TAB_HEIGHT)
	hit.BackgroundTransparency = 1
	hit.BorderSizePixel = 0
	hit.AutoButtonColor = false
	hit.Text = ""
	hit.ZIndex = Z_FACE
	hit.Parent = tabScroll

	local face = well(hit, "Face", Z_FACE, WHITE, 0, 10)
	face.Size = UDim2.fromScale(1, 1)
	face.Active = false
	local tint = UIKit.gradient(face, ALMANAC.TabIdleTop, ALMANAC.TabIdleBottom)
	local edge = UIKit.stroke(face, ALMANAC.WellEdge, 2)

	local text = label(face, "Label", 15, ALMANAC.Cream, Z_TEXT)
	text.Position = UDim2.fromOffset(6, 0)
	text.Size = UDim2.new(1, -12, 1, 0)
	text.Text = string.format("%s %d. %s", ALMANAC.TabIcons[biome.Id] or "", biome.Order,
		biome.DisplayName)
	shrinkToFit(text, 15, 10)
	local textLine = UIKit.stroke(text, INK, 1.5)

	-- A harvest waiting on this biome: a gold dot on its corner, so the tab says
	-- so even while another shelf is on show.
	local ready = well(face, "Ready", Z_RING, ALMANAC.Gold, 0, 6)
	ready.AnchorPoint = Vector2.new(0.5, 0.5)
	ready.Position = UDim2.new(1, -7, 0, 7)
	ready.Size = UDim2.fromOffset(12, 12)
	ready.Visible = false
	UIKit.stroke(ready, INK, 2)

	UIKit.clicks(hit)
	tabs[biome.Id] = {
		button = hit,
		tint = tint,
		edge = edge,
		text = text,
		textLine = textLine,
		ready = ready,
	}
end

--==============================================================================
-- THE BIOME CARD
--
-- The biome's own painted backdrop -- the same plate its species' cards stand
-- in front of in the Garden -- darkened at both ends so the words on it read.
--==============================================================================
local biomeCard = well(content, "Biome", Z_PANEL, ALMANAC.Well, 0, 14)
UIKit.stroke(biomeCard, INK, 2.5)

local biomeArt = Instance.new("ImageLabel")
biomeArt.Name = "Scenery"
biomeArt.Size = UDim2.fromScale(1, 1)
biomeArt.BackgroundTransparency = 1
biomeArt.BorderSizePixel = 0
biomeArt.ScaleType = Enum.ScaleType.Crop
biomeArt.ImageColor3 = CARD.ArtTint
biomeArt.ZIndex = Z_FACE
biomeArt.Parent = biomeCard
UIKit.corner(biomeArt, 14)

local biomeShade = well(biomeCard, "Shade", Z_INSET, BLACK, 0, 14)
biomeShade.Size = UDim2.fromScale(1, 1)
local biomeFade = Instance.new("UIGradient")
biomeFade.Rotation = 90
biomeFade.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.2),
	NumberSequenceKeypoint.new(0.35, 0.82),
	NumberSequenceKeypoint.new(0.65, 0.82),
	NumberSequenceKeypoint.new(1, 0.2),
})
biomeFade.Parent = biomeShade

local biomeKicker = label(biomeCard, "Kicker", 13, ALMANAC.Lime, Z_TEXT)
UIKit.stroke(biomeKicker, INK, 1.5)
local biomeName = display(biomeCard, "Name", 22, WHITE, Z_TEXT, 2)
shrinkToFit(biomeName, 22, 12)

local biomeStatus = well(biomeCard, "Harvested", Z_VIEW, ALMANAC.Well, 0.15, 10)
UIKit.stroke(biomeStatus, ALMANAC.Lime, 2, 0.1)
local statusTitle = label(biomeStatus, "Title", 11, ALMANAC.Cream, Z_TEXT)
statusTitle.Position = UDim2.fromOffset(4, 7)
statusTitle.Size = UDim2.new(1, -8, 0, 14)
shrinkToFit(statusTitle, 11, 8)
local statusValue = label(biomeStatus, "Value", 16, ALMANAC.Lime, Z_TEXT)
statusValue.Position = UDim2.fromOffset(4, 23)
statusValue.Size = UDim2.new(1, -8, 0, 24)
shrinkToFit(statusValue, 16, 10)
UIKit.stroke(statusValue, INK, 1.5)

local function layoutBiome(wide: boolean)
	-- Dark at both ends of the long axis: top and bottom on the column, left and
	-- right on the phone's banner.
	biomeFade.Rotation = if wide then 90 else 0
	if wide then
		biomeKicker.Position = UDim2.fromOffset(6, 12)
		biomeKicker.Size = UDim2.new(1, -12, 0, 16)
		biomeKicker.TextXAlignment = Enum.TextXAlignment.Center
		biomeName.Position = UDim2.fromOffset(6, 30)
		biomeName.Size = UDim2.new(1, -12, 0, 28)
		biomeName.TextXAlignment = Enum.TextXAlignment.Center
		biomeStatus.AnchorPoint = Vector2.new(0.5, 1)
		biomeStatus.Position = UDim2.new(0.5, 0, 1, -10)
		biomeStatus.Size = UDim2.new(1, -16, 0, 54)
	else
		biomeKicker.Position = UDim2.fromOffset(14, 16)
		biomeKicker.Size = UDim2.new(1, -170, 0, 16)
		biomeKicker.TextXAlignment = Enum.TextXAlignment.Left
		biomeName.Position = UDim2.fromOffset(14, 34)
		biomeName.Size = UDim2.new(1, -170, 0, 32)
		biomeName.TextXAlignment = Enum.TextXAlignment.Left
		biomeStatus.AnchorPoint = Vector2.new(1, 0.5)
		biomeStatus.Position = UDim2.new(1, -12, 0.5, 0)
		biomeStatus.Size = UDim2.fromOffset(136, 54)
	end
end

--==============================================================================
-- THE SHELF
--==============================================================================
local shelf = Instance.new("Frame")
shelf.Name = "Shelf"
shelf.BackgroundTransparency = 1
shelf.BorderSizePixel = 0
shelf.ZIndex = Z_PANEL
shelf.Parent = content

--==============================================================================
-- FIVE CARDS, BUILT ONCE, REFILLED PER TAB
--
-- A slot never changes shape, only what it shows, so the tabs repaint five cards
-- rather than building five more. Each slot keeps ONE ViewportFrame for its whole
-- life and the plants move in and out of it -- see showPortrait.
--==============================================================================
type Card = {
	holder: Frame,
	button: ImageButton,
	tint: UIGradient,
	name: TextLabel,
	inset: Frame,
	art: ImageLabel,
	view: ViewportFrame,
	hidden: TextLabel,
	rarity: TextLabel,
	ring: Frame,
	shown: string?,
	species: any,
}
local cards: { Card } = {}

for slot = 1, SEGMENTS do
	local holder = Instance.new("Frame")
	holder.Name = "Card" .. slot
	holder.AnchorPoint = Vector2.new(0.5, 0.5)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = Z_PANEL
	holder.Parent = shelf

	local pop = Instance.new("UIScale")
	pop.Scale = 1
	pop.Parent = holder

	local shadow = well(holder, "Shadow", Z_PANEL, BLACK, 0.55, 12)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.fromOffset(0, 4)

	local face = Instance.new("ImageButton")
	face.Name = "Face"
	face.Size = UDim2.fromScale(1, 1)
	face.BorderSizePixel = 0
	face.AutoButtonColor = false
	face.ZIndex = Z_FACE
	face.Parent = holder
	UIKit.corner(face, 12)
	local edge = UIKit.stroke(face, INK, 2.5)
	local tint = UIKit.gradient(face, ALMANAC.Rarity.Common[1], ALMANAC.Rarity.Common[2])

	-- Sun on the top half of the card: a white wash that fades out by the middle.
	local sheen = well(face, "Sheen", Z_FACE, WHITE, 0, 12)
	sheen.Size = UDim2.new(1, 0, 0.5, 0)
	sheen.Active = false
	local sheenFade = Instance.new("UIGradient")
	sheenFade.Rotation = 90
	sheenFade.Transparency = NumberSequence.new(0.7, 1)
	sheenFade.Parent = sheen

	local name = display(face, "Name", 15, WHITE, Z_TEXT, 2)
	name.AnchorPoint = Vector2.new(0.5, 0)
	name.Position = UDim2.new(0.5, 0, 0, 5)
	name.Size = UDim2.new(1, -8, 0, 20)
	shrinkToFit(name, 15, 9)

	local inset = well(face, "Diorama", Z_INSET, ALMANAC.Well, 0, 10)
	inset.AnchorPoint = Vector2.new(0.5, 0)
	inset.Position = UDim2.new(0.5, 0, 0, 27)
	inset.Active = false
	UIKit.stroke(inset, INK, 2)

	local art = Instance.new("ImageLabel")
	art.Name = "Scenery"
	art.Size = UDim2.fromScale(1, 1)
	art.BackgroundTransparency = 1
	art.BorderSizePixel = 0
	art.ScaleType = Enum.ScaleType.Crop
	art.ImageColor3 = CARD.ArtTint
	art.Visible = false
	art.ZIndex = Z_INSET
	art.Parent = inset
	UIKit.corner(art, 10)

	-- Inset a few pixels so a pedestal edge never paints over the rounded corner.
	local view = Instance.new("ViewportFrame")
	view.Name = "Plant"
	view.AnchorPoint = Vector2.new(0.5, 0.5)
	view.Position = UDim2.fromScale(0.5, 0.5)
	view.Size = UDim2.new(1, -6, 1, -6)
	view.BackgroundTransparency = 1
	view.BorderSizePixel = 0
	view.Ambient = CARD.Ambient
	view.LightColor = CARD.LightColour
	view.LightDirection = CARD.LightDirection
	view.ZIndex = Z_VIEW
	view.Parent = inset

	local hidden = label(inset, "Undiscovered", 10, ALMANAC.Cream, Z_TEXT)
	hidden.AnchorPoint = Vector2.new(0.5, 1)
	hidden.Position = UDim2.new(0.5, 0, 1, -3)
	hidden.Size = UDim2.new(1, -6, 0, 13)
	hidden.Text = "UNDISCOVERED"
	shrinkToFit(hidden, 10, 6)
	UIKit.stroke(hidden, INK, 1.5)

	-- The rarity tag: a dark pill sized to its word, the word in the rarity's
	-- own light colour.
	local tag = well(face, "Tag", Z_INSET, INK, 0.3, 6)
	tag.AnchorPoint = Vector2.new(0.5, 1)
	tag.Position = UDim2.new(0.5, 0, 1, -5)
	tag.Size = UDim2.fromOffset(0, 18)
	tag.AutomaticSize = Enum.AutomaticSize.X
	tag.Active = false
	local tagPad = Instance.new("UIPadding")
	tagPad.PaddingLeft = UDim.new(0, 7)
	tagPad.PaddingRight = UDim.new(0, 7)
	tagPad.Parent = tag
	local rarity = label(tag, "Rarity", 12, WHITE, Z_TEXT)
	rarity.Size = UDim2.fromScale(0, 1)
	rarity.AutomaticSize = Enum.AutomaticSize.X

	local ring = Instance.new("Frame")
	ring.Name = "Selected"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.new(1, 8, 1, 8)
	ring.BackgroundTransparency = 1
	ring.BorderSizePixel = 0
	ring.Visible = false
	ring.ZIndex = Z_RING
	ring.Parent = holder
	UIKit.corner(ring, 15)
	UIKit.stroke(ring, ALMANAC.Gold, 3)

	UIKit.clicks(face)
	UIKit.popOnHover(holder, pop, { stroke = edge })

	cards[slot] = {
		holder = holder,
		button = face,
		tint = tint,
		name = name,
		inset = inset,
		art = art,
		view = view,
		hidden = hidden,
		rarity = rarity,
		ring = ring,
		shown = nil,
		species = nil,
	}
end

--==============================================================================
-- THE SIXTH SLOT: BIOME MASTERY
--
-- A gold dashed outline around a trophy. Roblox strokes have no dash pattern, so
-- the dashes are short frames laid along the four straight edges, rebuilt only
-- when the slot changes size.
--==============================================================================
local trophy = Instance.new("Frame")
trophy.Name = "Mastery"
trophy.AnchorPoint = Vector2.new(0.5, 0.5)
trophy.BackgroundTransparency = 1
trophy.BorderSizePixel = 0
trophy.ZIndex = Z_PANEL
trophy.Parent = shelf

local trophyFace = well(trophy, "Face", Z_FACE, ALMANAC.Well, 0.3, 12)
trophyFace.Size = UDim2.fromScale(1, 1)

local trophyDashes = Instance.new("Frame")
trophyDashes.Name = "Dashes"
trophyDashes.Size = UDim2.fromScale(1, 1)
trophyDashes.BackgroundTransparency = 1
trophyDashes.BorderSizePixel = 0
trophyDashes.ZIndex = Z_INSET
trophyDashes.Parent = trophy

local trophyCup = label(trophy, "Cup", 30, WHITE, Z_TEXT)
trophyCup.AnchorPoint = Vector2.new(0.5, 0)
trophyCup.Position = UDim2.fromScale(0.5, 0.07)
trophyCup.Size = UDim2.fromScale(1, 0.26)
trophyCup.Text = "🏆"
shrinkToFit(trophyCup, 30, 16)

local trophyTitle = label(trophy, "Title", 14, ALMANAC.Gold, Z_TEXT)
trophyTitle.AnchorPoint = Vector2.new(0.5, 0)
trophyTitle.Position = UDim2.fromScale(0.5, 0.35)
trophyTitle.Size = UDim2.new(1, -10, 0.14, 0)
trophyTitle.Text = "Biome Mastery"
shrinkToFit(trophyTitle, 14, 8)
UIKit.stroke(trophyTitle, INK, 1.5)

local trophyStatus = label(trophy, "Status", 11, ALMANAC.Cream, Z_TEXT)
trophyStatus.AnchorPoint = Vector2.new(0.5, 0)
trophyStatus.Position = UDim2.fromScale(0.5, 0.52)
trophyStatus.Size = UDim2.new(1, -14, 0.42, 0)
trophyStatus.TextWrapped = true
trophyStatus.TextYAlignment = Enum.TextYAlignment.Top
shrinkToFit(trophyStatus, 11, 7)

local trophyHit = Instance.new("TextButton")
trophyHit.Name = "Hit"
trophyHit.Size = UDim2.fromScale(1, 1)
trophyHit.BackgroundTransparency = 1
trophyHit.BorderSizePixel = 0
trophyHit.AutoButtonColor = false
trophyHit.Text = ""
trophyHit.ZIndex = Z_RING
trophyHit.Parent = trophy

local dashedFor = Vector2.zero

local function dashTrophy(width: number, height: number)
	if math.abs(dashedFor.X - width) < 1 and math.abs(dashedFor.Y - height) < 1 then
		return
	end
	dashedFor = Vector2.new(width, height)
	trophyDashes:ClearAllChildren()

	local DASH, SPACE, THICK, CORNER = 9, 6, 3, 12
	local function run(horizontal: boolean, fixed: number, from: number, length: number)
		local count = math.max(1, math.floor((length + SPACE) / (DASH + SPACE)))
		local at = from + math.floor((length - (count * DASH + (count - 1) * SPACE)) * 0.5)
		for _ = 1, count do
			local dash = Instance.new("Frame")
			dash.Name = "Dash"
			dash.BackgroundColor3 = ALMANAC.Gold
			dash.BorderSizePixel = 0
			dash.ZIndex = Z_INSET
			if horizontal then
				dash.Position = UDim2.fromOffset(at, fixed)
				dash.Size = UDim2.fromOffset(DASH, THICK)
			else
				dash.Position = UDim2.fromOffset(fixed, at)
				dash.Size = UDim2.fromOffset(THICK, DASH)
			end
			dash.Parent = trophyDashes
			at += DASH + SPACE
		end
	end
	run(true, 0, CORNER, width - CORNER * 2)
	run(true, height - THICK, CORNER, width - CORNER * 2)
	run(false, 0, CORNER, height - CORNER * 2)
	run(false, width - THICK, CORNER, height - CORNER * 2)
end

--==============================================================================
-- THE PROGRESS BAR UNDER THE SHELF
--==============================================================================
local progressWell = well(shelf, "Progress", Z_PANEL, ALMANAC.Well, 0.05, 12)
UIKit.stroke(progressWell, ALMANAC.WellEdge, 1.5)

local track = Instance.new("Frame")
track.Name = "Track"
track.AnchorPoint = Vector2.new(0, 0.5)
track.Position = UDim2.new(0, 10, 0.5, 0)
track.Size = UDim2.new(1, -80, 0, 14)
track.BackgroundTransparency = 1
track.BorderSizePixel = 0
track.ZIndex = Z_FACE
track.Parent = progressWell

local trackList = Instance.new("UIListLayout")
trackList.FillDirection = Enum.FillDirection.Horizontal
trackList.SortOrder = Enum.SortOrder.LayoutOrder
trackList.Padding = UDim.new(0, 5)
trackList.Parent = track

local segments: { UIGradient } = {}
for i = 1, SEGMENTS do
	local step = well(track, "Step" .. i, Z_FACE, WHITE, 0, 5)
	step.LayoutOrder = i
	-- Equal shares of the track once the gaps between them are paid for.
	step.Size = UDim2.new(1 / SEGMENTS, -math.ceil(5 * (SEGMENTS - 1) / SEGMENTS), 1, 0)
	segments[i] = UIKit.gradient(step, ALMANAC.SlateDeep, ALMANAC.SlateDeep)
end

local progressText = label(progressWell, "Count", 17, WHITE, Z_TEXT)
progressText.AnchorPoint = Vector2.new(1, 0.5)
progressText.Position = UDim2.new(1, -10, 0.5, 0)
progressText.Size = UDim2.fromOffset(60, 24)
progressText.TextXAlignment = Enum.TextXAlignment.Right
UIKit.stroke(progressText, INK, 1.5)

--==============================================================================
-- THE SHOWCASE
--==============================================================================
local showcase = well(content, "Showcase", Z_PANEL, ALMANAC.Well, 0.1, 14)
UIKit.stroke(showcase, ALMANAC.WellEdge, 2)

local stage = well(showcase, "Stage", Z_FACE, ALMANAC.BodyTop, 0, 12)
stage.ClipsDescendants = true
UIKit.stroke(stage, ALMANAC.WellEdge, 2)

local stageArt = Instance.new("ImageLabel")
stageArt.Name = "Scenery"
stageArt.Size = UDim2.fromScale(1, 1)
stageArt.BackgroundTransparency = 1
stageArt.BorderSizePixel = 0
stageArt.ScaleType = Enum.ScaleType.Crop
stageArt.ImageColor3 = CARD.ArtTint
stageArt.ImageTransparency = 0.35
stageArt.Visible = false
stageArt.ZIndex = Z_FACE
stageArt.Parent = stage
UIKit.corner(stageArt, 12)

-- A soft lime pool of light where the pedestal stands.
local glow = well(stage, "Glow", Z_INSET, ALMANAC.Lime, 0, 999)
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.8)
local glowFade = Instance.new("UIGradient")
glowFade.Rotation = 90
glowFade.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.5, 0.55),
	NumberSequenceKeypoint.new(1, 1),
})
glowFade.Parent = glow

local stageView = Instance.new("ViewportFrame")
stageView.Name = "Plant"
stageView.AnchorPoint = Vector2.new(0.5, 0.5)
stageView.Position = UDim2.fromScale(0.5, 0.5)
stageView.BackgroundTransparency = 1
stageView.BorderSizePixel = 0
stageView.Ambient = CARD.Ambient
stageView.LightColor = CARD.LightColour
stageView.LightDirection = CARD.LightDirection
stageView.ZIndex = Z_VIEW
stageView.Parent = stage

--==============================================================================
-- SPARKLES, AND THE ONLY THINGS HERE THAT MOVE
--
-- Four glints breathing in and out, each on its own period so they never pulse
-- together. Engine tweens made once and only played while the panel is open, so
-- nothing is allocated per frame and nothing runs behind a closed panel.
--==============================================================================
local SPARKLES = {
	{ x = 0.12, y = 0.17, size = 16, period = 1.4 },
	{ x = 0.88, y = 0.22, size = 13, period = 1.9 },
	{ x = 0.84, y = 0.72, size = 11, period = 1.6 },
	{ x = 0.18, y = 0.68, size = 10, period = 2.2 },
}
local twinkles: { Tween } = {}
for i, spot in ipairs(SPARKLES) do
	local glint = label(stage, "Sparkle" .. i, spot.size, WHITE, Z_RING)
	glint.AnchorPoint = Vector2.new(0.5, 0.5)
	glint.Position = UDim2.fromScale(spot.x, spot.y)
	glint.Size = UDim2.fromOffset(spot.size + 8, spot.size + 8)
	glint.Text = "✨"
	glint.TextTransparency = 0.2
	table.insert(twinkles, TweenService:Create(glint,
		TweenInfo.new(spot.period, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ TextTransparency = 0.75 }))
end

local showName = display(showcase, "Name", 22, WHITE, Z_TEXT, 2)
shrinkToFit(showName, 22, 12)

local showRarity = label(showcase, "Rarity", 15, WHITE, Z_TEXT)
UIKit.stroke(showRarity, INK, 1.5)

local yieldRow = well(showcase, "Yield", Z_FACE, ALMANAC.BodyBottom, 0, 10)
UIKit.stroke(yieldRow, ALMANAC.WellEdge, 1.5)
local yieldKey = label(yieldRow, "Key", 13, ALMANAC.Lime, Z_TEXT)
yieldKey.Position = UDim2.fromOffset(10, 0)
yieldKey.Size = UDim2.new(0.55, -10, 1, 0)
yieldKey.TextXAlignment = Enum.TextXAlignment.Left
yieldKey.Text = "Garden Yield:"
shrinkToFit(yieldKey, 13, 9)
local yieldValue = label(yieldRow, "Value", 16, WHITE, Z_TEXT)
yieldValue.AnchorPoint = Vector2.new(1, 0)
yieldValue.Position = UDim2.new(1, -10, 0, 0)
yieldValue.Size = UDim2.new(0.45, -4, 1, 0)
yieldValue.TextXAlignment = Enum.TextXAlignment.Right
shrinkToFit(yieldValue, 16, 9)
UIKit.stroke(yieldValue, INK, 1.5)

--==============================================================================
-- THE BIOME HARVEST BOX
--
-- What finishing this biome pays, read off BiomeData through AlmanacData -- the
-- same numbers AlmanacService pays -- and the button that asks for it.
--==============================================================================
local harvest = well(showcase, "Harvest", Z_FACE, ALMANAC.BodyTop, 0, 12)
UIKit.stroke(harvest, ALMANAC.Lime, 2, 0.35)

local harvestTitle = label(harvest, "Title", 13, ALMANAC.Cream, Z_TEXT)
harvestTitle.Position = UDim2.fromOffset(10, 6)
harvestTitle.Size = UDim2.new(1, -76, 0, 20)
harvestTitle.TextXAlignment = Enum.TextXAlignment.Left
harvestTitle.Text = "🌾 BIOME HARVEST"
shrinkToFit(harvestTitle, 13, 8)

local harvestCount = label(harvest, "Count", 14, ALMANAC.Gold, Z_TEXT)
harvestCount.AnchorPoint = Vector2.new(1, 0)
harvestCount.Position = UDim2.new(1, -10, 0, 6)
harvestCount.Size = UDim2.fromOffset(60, 20)
harvestCount.TextXAlignment = Enum.TextXAlignment.Right
UIKit.stroke(harvestCount, INK, 1.5)

local function rewardTile(name: string, right: boolean, icon: string, key: string,
	colour: Color3): TextLabel
	local tile = well(harvest, name, Z_INSET, ALMANAC.Well, 0, 8)
	tile.AnchorPoint = Vector2.new(if right then 1 else 0, 0)
	tile.Position = if right then UDim2.new(1, -8, 0, 30) else UDim2.fromOffset(8, 30)
	tile.Size = UDim2.new(0.5, -11, 0, 46)
	UIKit.stroke(tile, ALMANAC.WellEdge, 1.5)

	local image = Instance.new("ImageLabel")
	image.Name = "Icon"
	image.AnchorPoint = Vector2.new(0, 0.5)
	image.Position = UDim2.new(0, 4, 0.5, 0)
	image.Size = UDim2.fromOffset(30, 30)
	image.BackgroundTransparency = 1
	image.Image = icon
	image.ScaleType = Enum.ScaleType.Fit
	image.ZIndex = Z_TEXT
	image.Parent = tile

	local keyLabel = label(tile, "Key", 10, ALMANAC.Muted, Z_TEXT)
	keyLabel.Position = UDim2.fromOffset(38, 6)
	keyLabel.Size = UDim2.new(1, -42, 0, 12)
	keyLabel.TextXAlignment = Enum.TextXAlignment.Left
	keyLabel.Text = key

	local value = label(tile, "Value", 15, colour, Z_TEXT)
	value.Position = UDim2.fromOffset(38, 19)
	value.Size = UDim2.new(1, -42, 0, 20)
	value.TextXAlignment = Enum.TextXAlignment.Left
	shrinkToFit(value, 15, 8)
	UIKit.stroke(value, INK, 1.5)
	return value
end

local cashValue = rewardTile("Cash", false, GameConfig.Store.Icons.cash2, "CASH", ALMANAC.Lime)
local speedValue = rewardTile("Speed", true, GameConfig.Store.Icons.speed1, "SPEED", ALMANAC.Sky)

--==============================================================================
-- THE CLAIM BUTTON
--
-- The house button -- lit face, darker foot, ink keyline -- in three states:
-- lime when there is something to take, slate while there is not (or while the
-- server is answering), and gold once it has been taken. The target is the full
-- width of the box and 44 tall.
--==============================================================================
local claimButton = Instance.new("TextButton")
claimButton.Name = "Claim"
claimButton.Position = UDim2.fromOffset(8, 84)
claimButton.Size = UDim2.new(1, -16, 0, 44)
claimButton.BackgroundTransparency = 1
claimButton.BorderSizePixel = 0
claimButton.AutoButtonColor = false
claimButton.Text = ""
claimButton.ZIndex = Z_INSET
claimButton.Parent = harvest

local claimPlate = well(claimButton, "Plate", Z_INSET, WHITE, 0, 10)
claimPlate.Size = UDim2.fromScale(1, 1)
claimPlate.Active = false
UIKit.stroke(claimPlate, INK, 2.5)
local claimTint = UIKit.gradient(claimPlate, ALMANAC.Slate, ALMANAC.SlateDeep)

local claimFoot = well(claimPlate, "Shade", Z_INSET, ALMANAC.SlateShade, 0, 10)
claimFoot.AnchorPoint = Vector2.new(0.5, 1)
claimFoot.Position = UDim2.fromScale(0.5, 1)
claimFoot.Size = UDim2.new(1, 0, 0, 5)
claimFoot.Active = false

local claimText = display(claimPlate, "Label", 18, WHITE, Z_TEXT, 2)
claimText.Position = UDim2.fromOffset(6, 0)
claimText.Size = UDim2.new(1, -12, 1, -5)
shrinkToFit(claimText, 18, 10)

local shakeClaim = UIKit.shake(claimButton)

local function styleClaim(top: Color3, bottom: Color3, foot: Color3, words: string,
	colour: Color3)
	claimTint.Color = ColorSequence.new(top, bottom)
	claimFoot.BackgroundColor3 = foot
	claimText.Text = words
	claimText.TextColor3 = colour
end

--==============================================================================
-- THE FOOTER: THE WHOLE KINGDOM
--==============================================================================
local footer = well(content, "Kingdom", Z_PANEL, ALMANAC.Well, 0.05, 12)
UIKit.stroke(footer, ALMANAC.WellEdge, 1.5)

local sproutTile = well(footer, "Sprout", Z_FACE, WHITE, 0, 9)
sproutTile.Position = UDim2.fromOffset(10, 10)
sproutTile.Size = UDim2.fromOffset(36, 36)
UIKit.stroke(sproutTile, INK, 2)
UIKit.gradient(sproutTile, ALMANAC.Lime, ALMANAC.LimeDeep)
local sproutGlyph = label(sproutTile, "Glyph", 20, WHITE, Z_TEXT)
sproutGlyph.Size = UDim2.fromScale(1, 1)
sproutGlyph.Text = "🌱"

local footerKicker = label(footer, "Kicker", 11, ALMANAC.Lime, Z_TEXT)
footerKicker.TextXAlignment = Enum.TextXAlignment.Left
footerKicker.Text = "TOTAL KINGDOM FLORA"

local footerLine = label(footer, "Discovered", 16, WHITE, Z_TEXT)
footerLine.TextXAlignment = Enum.TextXAlignment.Left
shrinkToFit(footerLine, 16, 10)

local footerTrack = well(footer, "Track", Z_FACE, ALMANAC.SlateDeep, 0, 7)
local footerFill = well(footerTrack, "Fill", Z_INSET, WHITE, 0, 7)
footerFill.Size = UDim2.fromScale(0, 1)
local footerTint = Instance.new("UIGradient")
footerTint.Color = ColorSequence.new(ALMANAC.Lime, ALMANAC.Gold)
footerTint.Parent = footerFill

local function layoutFooter(width: number, wide: boolean): number
	if wide then
		local bar = math.floor(math.min(280, width * 0.38))
		footerKicker.Position = UDim2.fromOffset(56, 10)
		footerKicker.Size = UDim2.fromOffset(width - 86 - bar, 14)
		footerLine.Position = UDim2.fromOffset(56, 25)
		footerLine.Size = UDim2.fromOffset(width - 86 - bar, 22)
		footerTrack.AnchorPoint = Vector2.new(1, 0.5)
		footerTrack.Position = UDim2.new(1, -14, 0.5, 0)
		footerTrack.Size = UDim2.fromOffset(bar, 14)
		return FOOTER_WIDE
	end
	footerKicker.Position = UDim2.fromOffset(56, 10)
	footerKicker.Size = UDim2.fromOffset(width - 66, 14)
	footerLine.Position = UDim2.fromOffset(56, 25)
	footerLine.Size = UDim2.fromOffset(width - 66, 22)
	footerTrack.AnchorPoint = Vector2.zero
	footerTrack.Position = UDim2.fromOffset(12, 58)
	footerTrack.Size = UDim2.fromOffset(width - 24, 14)
	return FOOTER_NARROW
end

--==============================================================================
-- LAYOUT
--
-- Measured off the scroll rather than typed, because the modal is a fraction of
-- the screen with a cap on it. Every block is placed by offset from the top, and
-- the total is what the modal is asked to fit.
--==============================================================================
local function layoutShelf(width: number, height: number?): number
	local cellW = math.max(64, math.floor((width - CARD_PAD * 2 - CARD_GUTTER * 2) / 3))
	local side = cellW - 14
	local cellH = side + CARD_CHROME
	if height then
		local room = height - CARD_PAD * 2 - PROGRESS_HEIGHT - GAP
		local tallest = math.floor((room - CARD_GUTTER) / 2)
		if cellH > tallest then
			cellH = tallest
			side = cellH - CARD_CHROME
		end
	end

	local function place(holder: Frame, index: number)
		local column = (index - 1) % 3
		local row = math.floor((index - 1) / 3)
		holder.Size = UDim2.fromOffset(cellW, cellH)
		holder.Position = UDim2.fromOffset(
			CARD_PAD + column * (cellW + CARD_GUTTER) + math.floor(cellW / 2),
			CARD_PAD + row * (cellH + CARD_GUTTER) + math.floor(cellH / 2))
	end
	for index, card in ipairs(cards) do
		place(card.holder, index)
		card.inset.Size = UDim2.fromOffset(side, side)
	end
	place(trophy, #cards + 1)
	dashTrophy(cellW, cellH)

	local total = height or (CARD_PAD + cellH * 2 + CARD_GUTTER + GAP + PROGRESS_HEIGHT + CARD_PAD)
	progressWell.Position = UDim2.fromOffset(CARD_PAD, total - CARD_PAD - PROGRESS_HEIGHT)
	progressWell.Size = UDim2.fromOffset(width - CARD_PAD * 2, PROGRESS_HEIGHT)
	return total
end

local function layoutShowcase(width: number, wide: boolean): number
	local pad = 8
	local inner = width - pad * 2
	local stageH = if wide then 138 else math.clamp(math.floor(inner * 0.56), 120, 190)
	stage.Position = UDim2.fromOffset(pad, pad)
	stage.Size = UDim2.fromOffset(inner, stageH)
	local viewSide = stageH - 6
	stageView.Size = UDim2.fromOffset(viewSide, viewSide)
	glow.Size = UDim2.fromOffset(math.floor(viewSide * 1.05), math.floor(viewSide * 0.34))

	local y = pad + stageH + 6
	showName.Position = UDim2.fromOffset(pad, y)
	showName.Size = UDim2.fromOffset(inner, 26)
	y += 26
	showRarity.Position = UDim2.fromOffset(pad, y)
	showRarity.Size = UDim2.fromOffset(inner, 18)
	y += 22
	yieldRow.Position = UDim2.fromOffset(pad, y)
	yieldRow.Size = UDim2.fromOffset(inner, 34)
	y += 40
	harvest.Position = UDim2.fromOffset(pad, y)
	harvest.Size = UDim2.fromOffset(inner, HARVEST_HEIGHT)
	return y + HARVEST_HEIGHT + pad
end

local function relayout()
	local width = math.floor(scroll.AbsoluteSize.X) - SCROLL_GUTTER
	if width < 200 then
		return
	end
	local wide = width >= WIDE_AT
	local y = TOP_PAD

	tabStrip.Position = UDim2.fromOffset(0, y)
	tabStrip.Size = UDim2.fromOffset(width, TAB_STRIP)
	local tabWidth = if wide
		then math.floor((width - 8 - TAB_GAP * (#road - 1)) / #road)
		else TAB_NARROW
	for _, tab in pairs(tabs) do
		tab.button.Size = UDim2.fromOffset(tabWidth, TAB_HEIGHT)
	end
	y += TAB_STRIP + GAP

	layoutBiome(wide)
	if wide then
		local mainHeight = layoutShowcase(RIGHT_WIDTH, true)
		biomeCard.Position = UDim2.fromOffset(0, y)
		biomeCard.Size = UDim2.fromOffset(LEFT_WIDTH, mainHeight)
		showcase.Position = UDim2.fromOffset(width - RIGHT_WIDTH, y)
		showcase.Size = UDim2.fromOffset(RIGHT_WIDTH, mainHeight)
		local shelfWidth = width - LEFT_WIDTH - RIGHT_WIDTH - GAP * 2
		shelf.Position = UDim2.fromOffset(LEFT_WIDTH + GAP, y)
		shelf.Size = UDim2.fromOffset(shelfWidth, mainHeight)
		layoutShelf(shelfWidth, mainHeight)
		y += mainHeight + GAP
	else
		biomeCard.Position = UDim2.fromOffset(0, y)
		biomeCard.Size = UDim2.fromOffset(width, BANNER_HEIGHT)
		y += BANNER_HEIGHT + GAP
		local shelfHeight = layoutShelf(width, nil)
		shelf.Position = UDim2.fromOffset(0, y)
		shelf.Size = UDim2.fromOffset(width, shelfHeight)
		y += shelfHeight + GAP
		local showHeight = layoutShowcase(width, false)
		showcase.Position = UDim2.fromOffset(0, y)
		showcase.Size = UDim2.fromOffset(width, showHeight)
		y += showHeight + GAP
	end

	local footerHeight = layoutFooter(width, wide)
	footer.Position = UDim2.fromOffset(0, y)
	footer.Size = UDim2.fromOffset(width, footerHeight)
	y += footerHeight + BOTTOM_PAD

	content.Size = UDim2.fromOffset(width, y)
	scroll.CanvasSize = UDim2.fromOffset(0, y)
	modal.fitContent(y)
end

scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
-- A screen that only got taller or shorter leaves the scroll's width alone but
-- moves the modal's ceiling, so the fit is asked again.
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
relayout()

--==============================================================================
-- THE PLANTS ARE BUILT WHEN THE PANEL IS OPEN, NOT WHEN THE GAME STARTS
--
-- A real CreatureModel is 29 to 74 parts. Nothing is built at join: a shelf's
-- five are built the first time that shelf is shown with the panel open, and
-- kept, so flicking back to a tab costs nothing. Opening every tab once is the
-- same twenty-five models the old grid built on its first open, and no more.
--
-- A SLOT KEEPS ITS VIEWPORT; THE PLANTS MOVE. A species always sits in the same
-- slot of its own shelf, so swapping tabs parents the new species' model and
-- camera into the slot's ViewportFrame and takes the old ones out. The frame
-- itself never changes, which keeps the hover lift and every ZIndex stable.
--
-- THE SILHOUETTE IS A TINT. An undiscovered plant is the same model with the
-- viewport's ImageColor3 taken down to near black, so growing one costs no
-- rebuild -- the tint lifts.
--==============================================================================
type Portrait = { model: Model, camera: Camera }
local portraits: { [string]: Portrait } = {}

local function tintView(view: ViewportFrame, known: boolean)
	view.ImageColor3 = if known then WHITE else ALMANAC.Silhouette
	view.ImageTransparency = if known then 0 else 0.1
end

local function showPortrait(card: Card, species: any)
	if card.shown == species.Id then
		return
	end
	local previous = if card.shown then portraits[card.shown :: string] else nil
	if previous then
		previous.model.Parent = nil
		previous.camera.Parent = nil
	end
	card.shown = species.Id

	local entry = portraits[species.Id]
	if entry then
		entry.model.Parent = card.view
		entry.camera.Parent = card.view
	else
		local model = CreatureModel.Build(species, SeedData.BaseTier,
			CreatureModel.STAGE_GROWN, CFrame.new(), card.view)
		local camera = UIKit.framePlant(card.view, model, species.Form, CARD_FILL)
		entry = { model = model, camera = camera }
		portraits[species.Id] = entry
	end
	card.view.CurrentCamera = entry.camera
end

--==============================================================================
-- THE SHOWCASE PEDESTAL
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
		part.CFrame = CFrame.new(pivot.Position.X, y, pivot.Position.Z)
			* CFrame.Angles(0, 0, math.pi * 0.5)
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
	local model = CreatureModel.Build(species, SeedData.BaseTier,
		CreatureModel.STAGE_GROWN, CFrame.new(), stageView)
	mossPedestal(model)
	UIKit.framePlant(stageView, model, species.Form, STAGE_FILL)
end

--==============================================================================
-- WHAT THE PROFILE SAYS
--==============================================================================
local almanac: { [string]: boolean } = {}
local mastery: { [string]: boolean } = {}
-- Biomes whose CLAIM has been sent and not yet answered.
local pending: { [string]: boolean } = {}

local activeBiome: string = road[1].Id
local chosenIn: { [string]: string } = {}
local panelOpen = false
local openedBefore = false

local function stateOf(biomeId: string): string
	return AlmanacData.ClaimState(almanac, mastery, biomeId)
end

-- The card the showcase is about: the one tapped on this shelf, else the first
-- one grown, else the first one.
local function chosenSpecies(): any
	local list = shelves[activeBiome]
	local want = chosenIn[activeBiome]
	for _, species in ipairs(list) do
		if species.Id == want then
			return species
		end
	end
	local pick = list[1]
	for _, species in ipairs(list) do
		if almanac[species.Id] then
			pick = species
			break
		end
	end
	chosenIn[activeBiome] = pick.Id
	return pick
end

--==============================================================================
-- PAINTING
--
-- Words, colours and states are pennies and always repaint. The models are the
-- expensive half and are only touched while somebody is looking; opening the
-- panel repaints, which builds whatever the shelf on show still owes.
--==============================================================================
local function paintTabs()
	for _, biome in ipairs(road) do
		local tab = tabs[biome.Id]
		local active = biome.Id == activeBiome
		tab.tint.Color = if active
			then ColorSequence.new(ALMANAC.HeaderTop, ALMANAC.LimeDeep)
			else ColorSequence.new(ALMANAC.TabIdleTop, ALMANAC.TabIdleBottom)
		tab.edge.Color = if active then INK else ALMANAC.WellEdge
		tab.text.TextColor3 = if active then WHITE else ALMANAC.Cream
		tab.textLine.Transparency = if active then 0 else 1
		tab.ready.Visible = stateOf(biome.Id) == "ready"
	end
end

local function paintBiome()
	local biome = BiomeData.ById[activeBiome]
	local list = shelves[activeBiome]
	biomeArt.Image = if list[1] then (CARD.Art[list[1].Id] or "") else ""
	biomeKicker.Text = string.format("🌿 BIOME %d", biome.Order)
	biomeName.Text = biome.DisplayName
	local grown, total = AlmanacData.Progress(almanac, activeBiome)
	statusTitle.Text = if stateOf(activeBiome) == "claimed" then "🏆 MASTERED" else "HARVESTED"
	statusValue.Text = string.format("%d / %d Grown", grown, total)
	statusValue.TextColor3 = if total > 0 and grown >= total then ALMANAC.Gold else ALMANAC.Lime
end

local function paintShelf()
	local list = shelves[activeBiome]
	local chosen = chosenSpecies()
	for slot, card in ipairs(cards) do
		local species = list[slot]
		card.species = species
		card.holder.Visible = species ~= nil
		if species then
			local known = almanac[species.Id] == true
			local colours = ALMANAC.Rarity[species.Rarity] or ALMANAC.Rarity.Common
			card.tint.Color = ColorSequence.new(colours[1], colours[2])
			card.name.Text = if known then species.Name else "???"
			card.rarity.Text = string.upper(species.Rarity)
			card.rarity.TextColor3 = colours[1]
			-- Grown: the biome's scenery behind the plant. Not yet: the card's own
			-- colour, darkened, behind a silhouette.
			card.inset.BackgroundColor3 = if known then ALMANAC.Well else BLACK
			card.inset.BackgroundTransparency = if known then 0 else 0.5
			card.art.Image = if known then (CARD.Art[species.Id] or "") else ""
			card.art.Visible = known
			card.hidden.Visible = not known
			card.ring.Visible = species.Id == chosen.Id
			if panelOpen then
				showPortrait(card, species)
				tintView(card.view, known)
			end
		end
	end

	local grown, total = AlmanacData.Progress(almanac, activeBiome)
	for i, step in ipairs(segments) do
		local frame = step.Parent :: Frame
		frame.Visible = i <= total
		step.Color = if i <= grown
			then ColorSequence.new(ALMANAC.Lime, ALMANAC.LimeDeep)
			else ColorSequence.new(ALMANAC.SlateDeep, ALMANAC.SlateDeep)
	end
	progressText.Text = string.format("%d / %d", grown, total)

	local state = stateOf(activeBiome)
	if state == "claimed" then
		trophyStatus.Text = "Harvest claimed!"
		trophyStatus.TextColor3 = ALMANAC.Gold
	elseif state == "ready" then
		trophyStatus.Text = if pending[activeBiome]
			then "Claiming..."
			else "All grown! Tap to claim the harvest"
		trophyStatus.TextColor3 = ALMANAC.Gold
	else
		trophyStatus.Text = string.format("Collect all %d to claim harvest bonus!", total)
		trophyStatus.TextColor3 = ALMANAC.Cream
	end
	trophyFace.BackgroundTransparency = if state == "ready" then 0.05 else 0.3
end

local function paintHarvest()
	local cash, speed = AlmanacData.Reward(activeBiome)
	cashValue.Text = "$" .. GameConfig.compact(cash)
	speedValue.Text = "+" .. GameConfig.compact(speed)
	local grown, total = AlmanacData.Progress(almanac, activeBiome)
	harvestCount.Text = string.format("%d/%d", grown, total)

	local state = stateOf(activeBiome)
	if pending[activeBiome] and state == "ready" then
		styleClaim(ALMANAC.Slate, ALMANAC.SlateDeep, ALMANAC.SlateShade, "CLAIMING...", ALMANAC.Cream)
	elseif state == "claimed" then
		styleClaim(ALMANAC.Gold, ALMANAC.GoldDeep, ALMANAC.GoldShade, "✓ CLAIMED", WHITE)
	elseif state == "ready" then
		styleClaim(ALMANAC.Lime, ALMANAC.LimeDeep, ALMANAC.LimeShade, "CLAIM", WHITE)
	else
		styleClaim(ALMANAC.Slate, ALMANAC.SlateDeep, ALMANAC.SlateShade,
			string.format("CLAIM (%d/%d)", grown, total), ALMANAC.Cream)
	end
end

local function paintShowcase()
	local species = chosenSpecies()
	local known = almanac[species.Id] == true
	local colours = ALMANAC.Rarity[species.Rarity] or ALMANAC.Rarity.Common
	showName.Text = if known then species.Name else "???"
	showRarity.Text = species.Rarity
	showRarity.TextColor3 = colours[1]
	stageArt.Image = if known then (CARD.Art[species.Id] or "") else ""
	stageArt.Visible = known
	--==========================================================================
	-- THE YIELD AT THE BASE TIER, AND UNMULTIPLIED
	--
	-- What one of this species pays standing grown at the tier every pod starts
	-- from: SeedData.IncomePerSecond, the calculation the faucet itself runs. A
	-- bigger roll pays more, which is the Garden row's number to show, and the
	-- x2 pass is a fact about the player, not about the plant.
	--==========================================================================
	yieldValue.Text = if known
		then "+$" .. GameConfig.compact(SeedData.IncomePerSecond(species, SeedData.BaseTier)) .. "/s"
		else "???"
	if panelOpen then
		showStage(species)
		tintView(stageView, known)
	end
	paintHarvest()
end

local function paintFooter()
	local grown, total = AlmanacData.TotalProgress(almanac)
	footerLine.Text = string.format("Discovered: %d / %d Species", grown, total)
	local share = if total > 0 then grown / total else 0
	footerFill.Size = UDim2.fromScale(share, 1)
	footerFill.Visible = share > 0
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

local function paint()
	paintTabs()
	paintBiome()
	paintShelf()
	paintShowcase()
	paintFooter()
	paintBadge()
end

paint()

-- Keeps the active tab inside the strip when the strip has to scroll.
local function revealTab()
	local tab = tabs[activeBiome]
	if not tab then
		return
	end
	local canvasX = tabScroll.CanvasPosition.X
	local left = tab.button.AbsolutePosition.X - tabScroll.AbsolutePosition.X + canvasX
	local right = left + tab.button.AbsoluteSize.X
	local view = tabScroll.AbsoluteSize.X
	if left < canvasX then
		canvasX = left
	elseif right > canvasX + view then
		canvasX = right - view
	end
	tabScroll.CanvasPosition = Vector2.new(math.max(0, canvasX), 0)
end

--==============================================================================
-- WHERE THE PANEL OPENS
--
-- The first open of a session goes where the action is: a biome with a harvest
-- waiting, else the furthest biome with anything grown in it. After that the
-- panel remembers the tab it was left on.
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

local function requestClaim()
	local biomeId = activeBiome
	local state = stateOf(biomeId)
	if state == "claimed" then
		SoundKit.play("CardClick")
		return
	end
	local channel = gameEvent
	if state ~= "ready" or pending[biomeId] or not channel then
		SoundKit.play("Denied")
		shakeClaim()
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
-- OPEN AND SHUT
--
-- ONE CENTRE PANEL AT A TIME. Each panel writes its own name to the OpenPanel
-- attribute and closes itself on seeing a name that is not its own, so no script
-- has to know the others exist.
--==============================================================================
local function setOpen(want: boolean)
	if panelOpen == want then
		return
	end
	panelOpen = want
	if want then
		if not openedBefore then
			openedBefore = true
			activeBiome = openingBiome()
		end
		-- Before the panel shows, so the first frame of the open is the finished
		-- shelf rather than empty dioramas filling in behind it.
		paint()
		task.defer(revealTab)
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
	elseif player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
	for _, twinkle in ipairs(twinkles) do
		if want then
			twinkle:Play()
		else
			twinkle:Pause()
		end
	end
	modal.setOpen(want)
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

for _, biome in ipairs(road) do
	local id = biome.Id
	tabs[id].button.Activated:Connect(function()
		if activeBiome == id then
			return
		end
		activeBiome = id
		paint()
		task.defer(revealTab)
	end)
end

for _, card in ipairs(cards) do
	card.button.Activated:Connect(function()
		local species = card.species
		if not species or chosenIn[activeBiome] == species.Id then
			return
		end
		chosenIn[activeBiome] = species.Id
		paintShelf()
		paintShowcase()
	end)
end

trophyHit.Activated:Connect(function()
	if stateOf(activeBiome) == "ready" then
		requestClaim()
	else
		SoundKit.play("CardClick")
	end
end)
claimButton.Activated:Connect(requestClaim)

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
		for id, value in pairs(profile.Almanac) do
			if value == true and type(id) == "string" and not almanac[id] then
				almanac[id] = true
				changed = true
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

-- No tick. Nothing here changes on its own except the sparkles, which are engine
-- tweens: the almanac moves when a profile packet or a claim answer says so, and
-- each of those repaints.
