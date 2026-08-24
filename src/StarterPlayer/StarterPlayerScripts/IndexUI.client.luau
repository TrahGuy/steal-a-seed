--!strict
-- Steal a Seed :: IndexUI
--
-- The almanac: what Greenhollow has, and which of it you have actually grown.
--
-- What is in your dirt right now is GardenUI. This is the sheet.
--
--==============================================================================
-- A GRID OF PLANTS, NOT A LIST OF SWATCHES
--
-- This was five 46-pixel rows, each a coloured square beside a name. The square
-- was the FORM RARITY colour, so a bed of five species read as a column of five
-- TIERS -- cream, cream, green, blue, purple -- and there was no plant anywhere
-- on the panel. An almanac whose entries are indistinguishable from a legend is
-- not an almanac.
--
-- Cards now, in a wrapping grid, each showing the SILHOUETTE: cube, orb,
-- teardrop, mushroom, bell. That is what a player recognises across a plot, and
-- it is the only thing on this panel that could not be printed on a receipt.
--
-- Drawn from frames by UIKit.plantPortrait, not a ViewportFrame -- five live
-- creatures at 29 to 40 parts each is 170 parts of camera work behind a panel,
-- on a phone, for a picture that never moves.
--
--==============================================================================
-- THE RARITY WORD LIVES HERE, AND IT MEANS THE FORM
--
-- Nowhere in the world says it. A pod is COLOURED by what it WEIGHS, so the word
-- out there would be describing a different thing entirely. This lists FORMS:
-- how often a cube turns up against a bell. That is all Rarity has ever decided.
--
-- NO KG AND NO $/S ON A CARD, and not for tidiness. Every pod rolls its own
-- weight, so there is no such thing as "what a Bellchime weighs" -- one number
-- here would be quietly wrong for every Bellchime in the game. What a given one
-- is worth is on the pod, in your hands, and in the Garden row.
--
-- AND NO WEIGHT-BAND COLOUR. `ColorForKg` never touches this panel. The Index is
-- the one surface that must not be tinted by kg: it lists shapes, and a shape's
-- colour is how often that shape drops.
--
--==============================================================================
-- SEEN MEANS GROWN, ON A PLOT YOU OWNED
--
-- Not carried, not stolen. Pods are coloured by WEIGHT, so the shell says
-- nothing about which form is inside; the HATCH is the reveal and PlantService
-- writes the Almanac at exactly that moment.
--
-- An unseen card is a GHOST of the right form -- so you can see there is a fifth
-- thing -- with the name "???" and NO TIER, spelled or tinted. Epic means
-- Bellchime in Greenhollow, so a rarity on a locked card names the species
-- through the back door.
--
--==============================================================================
-- NO NEW REMOTE
--
-- Almanac rides down inside the profile ProfileUpdated already pushes four times
-- a second, and ProfileReady announces the first one.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local SHOP = GameConfig.Shop
local ATTR = GameConfig.Attributes
local PANEL_NAME = "Index"

local WHITE = Color3.fromRGB(255, 255, 255)
-- Grey paper: an undiscovered card is present but not lit.
local GHOST = Color3.fromRGB(116, 120, 136)
local CARD = Color3.fromRGB(38, 42, 58)
local CARD_LOCKED = Color3.fromRGB(29, 31, 44)

--==============================================================================
-- GREENHOLLOW ONLY, AND THE DENOMINATOR IS COUNTED NOT TYPED
--
-- The other four biomes are geometry with no species in them yet, so an Index
-- listing them would be four empty shelves. When they get their art they get
-- their cards, and `#SPECIES` picks that up without anybody editing a header.
--==============================================================================
local BIOME = "greenhollow"
local SPECIES = SeedData.InBiome(BIOME)

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
	face = RAIL.IndexFace,
	shade = RAIL.IndexShade,
	label = "Index",
	wide = true,
})
button.Position = UDim2.new(0, RAIL.Inset, 0, RAIL.Inset)
UIKit.bookIcon(button, RAIL.IconSize, RAIL.IndexShade)

local badge, badgeCount = UIKit.badge(button, RAIL.Badge)

--==============================================================================
-- THE PANEL
--==============================================================================
local modal = UIKit.modal(gui, {
	name = PANEL_NAME,
	title = "INDEX",
	maxWidth = 480,
	maxHeight = 540,
})

local titleBar = modal.title.Parent :: Frame
UIKit.bookIcon(titleBar, 30, RAIL.IndexShade)
modal.title.Position = UDim2.new(0, 46, 0.5, 0)
modal.title.Size = UDim2.new(1, -98, 1, 0)

local list = Instance.new("ScrollingFrame")
list.Name = "Cards"
list.Size = UDim2.fromScale(1, 1)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = SHOP.PanelEdge
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ZIndex = 3
list.Parent = modal.body

local grid = Instance.new("UIGridLayout")
grid.FillDirection = Enum.FillDirection.Horizontal
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
grid.Parent = list

--==============================================================================
-- TWO COLUMNS ON A PHONE, THREE WHEN THERE IS ROOM
--
-- Measured off the panel rather than typed, because the modal is a fraction of
-- the screen with a cap on it -- the same script has to lay out at 248 pixels
-- and at 480. Never one column: a single stack of cards is the row list this
-- panel just stopped being.
--==============================================================================
local GUTTER = 10

local function relayout()
	local width = list.AbsoluteSize.X
	if width <= 0 then
		return
	end
	local columns = if width >= 400 then 3 else 2
	local cell = math.floor((width - GUTTER * (columns - 1) - 6) / columns)
	local cellHeight = math.floor(cell * 1.32)
	grid.CellSize = UDim2.fromOffset(cell, cellHeight)
	grid.CellPadding = UDim2.fromOffset(GUTTER, GUTTER)

	-- Five cards in a panel sized for twelve garden rows is two thirds empty,
	-- and empty is what a broken panel looks like. Height it to the rows it
	-- actually has -- which is three on a phone and two on a desktop, so this
	-- cannot be a constant either.
	local rows = math.ceil(#SPECIES / columns)
	modal.fitContent(rows * cellHeight + (rows - 1) * GUTTER)
end

list:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
relayout()

--==============================================================================
-- ONE CARD PER SPECIES, BUILT ONCE
--
-- The cards never change shape, only their contents, so they are built at start
-- and refilled. The PORTRAIT is the exception -- a ghost and a coloured plant
-- are different instances -- so it is rebuilt only on the transition, which
-- happens at most five times in a save's life.
--==============================================================================
type Card = {
	frame: Frame,
	border: UIStroke,
	art: Frame,
	name: TextLabel,
	tier: TextLabel,
	drawn: boolean?,
}

local built: { [string]: Card } = {}

local function specFor(species: SeedData.Species): UIKit.PlantSpec
	return {
		form = species.Form,
		body = species.Body,
		crown = species.Crown,
		accent = species.Accent,
		leaf = species.Leaf,
		stem = SeedData.Stem,
		soil = species.Soil,
		blush = SeedData.Blush,
	}
end

for index, species in ipairs(SPECIES) do
	local frame = Instance.new("Frame")
	frame.Name = species.Id
	frame.LayoutOrder = index
	frame.BackgroundColor3 = CARD
	frame.BorderSizePixel = 0
	frame.ZIndex = 3
	frame.Parent = list
	UIKit.corner(frame, 12)
	local border = UIKit.stroke(frame, GHOST, 2.5)

	local art = Instance.new("Frame")
	art.Name = "Art"
	art.AnchorPoint = Vector2.new(0.5, 0)
	art.Position = UDim2.new(0.5, 0, 0, 6)
	art.Size = UDim2.new(1, -12, 0.66, 0)
	art.BackgroundTransparency = 1
	art.ZIndex = 4
	art.Parent = frame

	local name = UIKit.outlined(frame, "Name", 16, WHITE, 2)
	name.AnchorPoint = Vector2.new(0.5, 1)
	name.Position = UDim2.new(0.5, 0, 1, -22)
	name.Size = UDim2.new(1, -8, 0, 20)
	name.TextXAlignment = Enum.TextXAlignment.Center
	name.TextScaled = false
	name.ZIndex = 5

	local tier = UIKit.outlined(frame, "Tier", 13, GHOST, 2)
	tier.AnchorPoint = Vector2.new(0.5, 1)
	tier.Position = UDim2.new(0.5, 0, 1, -5)
	tier.Size = UDim2.new(1, -8, 0, 16)
	tier.TextXAlignment = Enum.TextXAlignment.Center
	tier.ZIndex = 5

	built[species.Id] = {
		frame = frame,
		border = border,
		art = art,
		name = name,
		tier = tier,
	}
end

--==============================================================================
-- FILLING IT IN
--==============================================================================
local almanac: { [string]: boolean } = {}

local function draw(card: Card, species: SeedData.Species, seen: boolean)
	if card.drawn == seen then
		return
	end
	card.drawn = seen
	card.art:ClearAllChildren()
	UIKit.plantPortrait(card.art, specFor(species), if seen then nil else GHOST)
end

local function paint()
	local seen = 0
	for _, species in ipairs(SPECIES) do
		local card = built[species.Id]
		if card then
			local known = almanac[species.Id] == true
			draw(card, species, known)
			if known then
				seen += 1
				card.frame.BackgroundColor3 = CARD
				-- The FORM's drop tier, and the only colour on this panel. It is
				-- never ColorForKg: that is what a pod weighs, not what a shape
				-- is worth finding.
				card.border.Color = SeedData.FormColor(species)
				card.name.Text = species.Name
				card.name.TextColor3 = WHITE
				card.tier.Text = species.Rarity
				card.tier.TextColor3 = GameConfig.RarityColor[species.Rarity] or GHOST
			else
				card.frame.BackgroundColor3 = CARD_LOCKED
				-- Grey, not the form colour. A tinted border would spell the
				-- tier in another alphabet, and Epic means Bellchime here.
				card.border.Color = GHOST
				card.name.Text = "???"
				card.name.TextColor3 = GHOST
				card.tier.Text = "Undiscovered"
				card.tier.TextColor3 = GHOST
			end
		end
	end

	modal.title.Text = string.format("INDEX  %d/%d", seen, #SPECIES)

	local missing = #SPECIES - seen
	badge.Visible = missing > 0
	badgeCount.Text = tostring(missing)
end

paint()

--==============================================================================
-- THE PROFILE
--==============================================================================
local function receive(profile: any)
	if type(profile) ~= "table" then
		return
	end
	local incoming = profile.Almanac
	if type(incoming) ~= "table" then
		return
	end
	local changed = false
	for id, value in pairs(incoming) do
		if value == true and type(id) == "string" and not almanac[id] then
			almanac[id] = true
			changed = true
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
		warn("[Seed/IndexUI] No ProfileUpdated; the Index will stay unfilled.")
	end
	local ready = remotes:WaitForChild(GameConfig.Remotes.ProfileReady, 20)
	if ready and ready:IsA("RemoteEvent") then
		ready.OnClientEvent:Connect(function(ok: boolean, profile: any)
			if ok then
				receive(profile)
			end
		end)
	end
else
	warn("[Seed/IndexUI] No Remotes folder; the Index will stay unfilled.")
end

--==============================================================================
-- OPEN AND SHUT
--
-- ONE CENTRE PANEL AT A TIME. All three now open in the same rectangle, so all
-- three are in the mutex -- the Garden used to be excluded because it docked on
-- the opposite rail and could not overlap. It can now.
--
-- Each writes its own name to the OpenPanel attribute and closes itself on
-- seeing a name that is not its own, so no script has to know the others exist.
--==============================================================================
local open = false

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
	elseif player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
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
	local holder = player:GetAttribute(ATTR.OpenPanel)
	if open and holder ~= PANEL_NAME then
		setOpen(false)
	end
end)

-- No tick. Nothing on this panel changes on its own: the almanac only moves when
-- a profile packet says a species has been discovered, and `receive` repaints on
-- that. GardenUI is the one with clocks to keep.
