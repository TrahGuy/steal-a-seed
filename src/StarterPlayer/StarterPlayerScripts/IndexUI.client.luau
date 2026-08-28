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
-- A STILL 3D COPY of the real CreatureModel, in a ViewportFrame. This was flat
-- frames for a pass, on the argument that five live creatures at 29 to 40 parts
-- each is camera work behind a panel for a picture that never moves. Two things
-- overturned it: the flat version needed rotated frames, which a ScrollingFrame
-- will not clip, and a drawing of a Bellchime is a second Bellchime that can
-- drift away from the first. The cost is real and it is paid once -- the models
-- are keyed and the camera is set when one is built, never per frame.
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
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local UIKit = require(Shared:WaitForChild("UIKit"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local PANEL = GameConfig.Panel
local ATTR = GameConfig.Attributes
local PANEL_NAME = "Index"

local WHITE = Color3.fromRGB(255, 255, 255)
-- Grey paper: an undiscovered card is present but not lit.
local GHOST = Color3.fromRGB(150, 148, 154)
--==============================================================================
-- THE CARD IS A DIORAMA, AND THIS FILE ONLY DECIDES WHAT IT SAYS
--
-- UIKit.plantCard owns the backdrop, the viewport and the still 3D plant. What
-- lives here is the almanac's vocabulary: which species, whether it has been
-- grown, the FORM's rarity word, and the FORM's colour on the border.
--==============================================================================

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

-- The cards carry a rotated lattice, which a ScrollingFrame will not clip. See
-- UIKit.rotationSafeClip.
local clip = UIKit.rotationSafeClip(modal.body, "CardsClip", UDim2.fromScale(1, 1))

local list = Instance.new("ScrollingFrame")
list.Name = "Cards"
list.Size = UDim2.fromScale(1, 1)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.ScrollBarImageColor3 = PANEL.Edge
list.CanvasSize = UDim2.new()
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.ZIndex = 3
list.Parent = clip

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
local CARD_ASPECT = 1.30

local function relayout()
	local width = list.AbsoluteSize.X
	if width <= 0 then
		return
	end
	local columns = if width >= 400 then 3 else 2
	local cell = math.floor((width - GUTTER * (columns - 1) - 6) / columns)
	-- 1.30, the same as the Garden. The card's horizon is arithmetic off the
	-- aspect ratio (GameConfig.Card.Horizon), so two panels on two ratios would
	-- put the plant on the dirt in one and slightly above it in the other.
	local cellHeight = math.floor(cell * CARD_ASPECT)
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
type Card = UIKit.PlantCard

local built: { [string]: Card } = {}

for index, species in ipairs(SPECIES) do
	built[species.Id] = UIKit.plantCard(list, {
		name = species.Id,
		layoutOrder = index,
		nameSize = 15,
		subSize = 12,
	})
end

--==============================================================================
-- FILLING IT IN
--==============================================================================
local almanac: { [string]: boolean } = {}

local function paint()
	local seen = 0
	for _, species in ipairs(SPECIES) do
		local card = built[species.Id]
		if card then
			local known = almanac[species.Id] == true

			--==========================================================
			-- BUILT AT THE REFERENCE WEIGHT, NOT AT species.Kg
			--
			-- The almanac lists FORMS and has no weight to show one at.
			-- `species.Kg` is the old-save fallback and sizing anything
			-- from it is a bug; the median roll is the honest stand-in, so
			-- a card shows the shape at exactly its sheet size.
			--
			-- Keyed on the state, so a model is built on a discovery and
			-- never on a repaint.
			--==========================================================
			card.setModel(if known then "seen:" .. species.Id else "ghost:" .. species.Id,
				function(into)
					local model = CreatureModel.Build(species,
						SeedData.BaseTier, CreatureModel.STAGE_GROWN,
						CFrame.new(), into)
					if not known then
						--==========================================
						-- A GHOST IS THE FORM AND NOTHING ELSE
						--
						-- Same model, drained to one flat grey. The
						-- silhouette is the point -- you can see there
						-- IS a fifth thing and roughly what shape it
						-- is -- and colour is what would name it.
						--==========================================
						for _, part in ipairs(model:GetDescendants()) do
							if part:IsA("BasePart") then
								part.Color = GHOST
								part.Material = Enum.Material.SmoothPlastic
							end
						end
					end
					return model
				end)
			-- The species' own place, but only once it has been grown. See
			-- GameConfig.Card: a backdrop is identity.
			card.setBackdrop(if known then species.Id else nil)

			if known then
				seen += 1
				-- The FORM's drop tier, and the only colour on this panel. It is
				-- never ColorForKg: that is what a pod weighs, not what a shape
				-- is worth finding.
				card.border.Color = SeedData.FormColor(species)
				card.name.Text = species.Name
				card.name.TextColor3 = WHITE
				card.sub.Text = species.Rarity
				card.sub.TextColor3 = GameConfig.RarityColor[species.Rarity] or GHOST
			else
				--==========================================================
				-- NOTHING ON A LOCKED CARD MAY CARRY THE TIER
				--
				-- Not the word, not the border, and not the sky -- the stage
				-- goes to dusk GREY rather than to the form's colour for the
				-- same reason the word is withheld. Epic means Bellchime in
				-- Greenhollow, so a rarity-tinted card names the species
				-- through the back door in a different alphabet.
				--==========================================================
				card.border.Color = GHOST
				card.name.Text = "???"
				card.name.TextColor3 = GHOST
				card.sub.Text = "Undiscovered"
				card.sub.TextColor3 = GHOST
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
