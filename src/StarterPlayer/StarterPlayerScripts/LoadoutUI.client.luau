--!strict
-- Steal a Seed :: LoadoutUI
--
-- The bag, the two equipment slots, and the hotbar. One script, on purpose.
--
--==============================================================================
-- ONE OWNER FOR "WHAT IS SELECTED"
--
-- These are three surfaces showing the same fact -- what you own, what is in
-- your loadout, and what is in your hands -- and the brief's requirement is that
-- they cannot disagree. The cheapest way to guarantee that is not to synchronise
-- three scripts, it is to have one.
--
-- So there are exactly two sources of truth here and neither of them is local
-- state in this file:
--
--   THE PROFILE PACKET   what is owned, and which id is in the bat slot and the
--                        trap slot. Server-authored, replicated, read-only.
--   THE LIVE TOOLS       what is actually in the Backpack and the Character.
--                        Server-built. The hotbar IS this list, not a mirror
--                        of it, so a Tool that exists always has a slot and a
--                        Tool that does not never does.
--
-- Everything drawn below is a function of those two. There is no "selected"
-- variable: the selected slot is the Tool parented to the Character, which is
-- the same thing the engine and the server already believe.
--
--==============================================================================
-- THE CLIENT DECIDES NOTHING IT IS NOT ALLOWED TO
--
-- Changing a LOADOUT SLOT is a server call -- the shop's own equip verb, with
-- the id, validated against ownership and category on that side. Changing which
-- Tool is IN YOUR HANDS is `Humanoid:EquipTool`, which is a local action on an
-- object the server already gave you and which the server re-checks anyway
-- (CombatService reads the held Tool, never a client's claim about it).
--
-- So a modified copy of this file can put a bat it owns into its own hand, and
-- nothing else.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local WeaponModel = require(Shared:WaitForChild("WeaponModel"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local PANEL = GameConfig.Panel
local RAIL = GameConfig.Rail
local ATTR = GameConfig.Attributes
local W = GameConfig.Weapon
local PANEL_NAME = "Bag"

local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
local CREAM = Color3.fromRGB(242, 238, 206)
local MUTED = Color3.fromRGB(198, 176, 152)

--==============================================================================
-- THE BAG'S OWN BROWNS
--
-- Every one of these is a step off GameConfig.Panel rather than a new colour:
-- the panel fills at (58,38,29) and shades at (38,25,19), so a card sits ABOVE
-- the panel and a well sits BELOW it, and the three read as one surface with
-- things set into it. That is the whole trick of an inventory that looks built
-- rather than drawn.
--
--   CARD_TOP/BOTTOM   the card face, lit from above. Both lighter than the
--                     panel, which is what makes a card look like it is resting
--                     on the panel instead of cut out of it.
--   LIT_TOP/BOTTOM    the same face with the green pushed through it. Not a
--                     different hue -- the same brown warmed toward the equip
--                     green, so an equipped card reads as the SAME card in a
--                     state rather than as a different kind of object.
--   WELL              darker than the panel. Used twice: behind the whole grid
--                     so empty space looks like a tray rather than a hole, and
--                     behind each preview so the item sits IN something.
--   LIP               the light top edge on a card. One pixel of it is what
--                     turns a flat rectangle into a raised one.
--==============================================================================
local CARD_TOP = Color3.fromRGB(86, 58, 43)
local CARD_BOTTOM = Color3.fromRGB(64, 42, 32)
local LIT_TOP = Color3.fromRGB(84, 104, 52)
local LIT_BOTTOM = Color3.fromRGB(56, 74, 36)
local WELL = Color3.fromRGB(40, 26, 20)
local LIP = Color3.fromRGB(140, 104, 82)
local PILL_OFF_TOP = Color3.fromRGB(96, 68, 52)
local PILL_OFF_BOTTOM = Color3.fromRGB(64, 44, 33)
local PILL_ON_TOP = Color3.fromRGB(150, 220, 96)
local PILL_ON_BOTTOM = Color3.fromRGB(92, 168, 56)
local READY = Color3.fromRGB(142, 214, 86)
-- The HOTBAR's held-slot colour. It used to be the bag card's equipped colour
-- too; the cards use green now, and this stays because the hotbar still does.
local PICKED = Color3.fromRGB(250, 214, 108)

local ITEM_ATTR = WeaponModel.ItemAttribute
local READY_AT = "ReadyAt"

--==============================================================================
-- FIVE, AND WHY IT IS NOT TEN
--
-- It was ten, on the reasoning that ten is what the number row can address. That
-- is a KEYBOARD's reason, and this game is mobile first: on a 735-pixel phone
-- ten 64-pixel slots are 700 pixels of hotbar, which is the whole screen width
-- and leaves a player thumbing between targets the size of a fingernail.
--
-- Five is what a thumb can reach without looking, and it is small enough that
-- WHICH five becomes a decision worth making -- which is what the drag below is
-- for. The bag still lists everything; this is the quick-access strip, not the
-- inventory, and a hotbar that scrolls is a hotbar nobody can hit without
-- looking.
--==============================================================================
local HOTBAR_SLOTS = 5

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedLoadout")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedLoadout"
gui.ResetOnSpawn = false
-- Below the rail (40) and the shop panel (34) so a modal covers the hotbar
-- rather than the hotbar poking through it.
gui.DisplayOrder = 30
gui.Parent = playerGui

--==============================================================================
-- REPLACING THE DEFAULT BACKPACK
--
-- Turned off only because the strip below enumerates TOOLS rather than
-- categories: whatever the engine would have shown, this shows, because it is
-- reading the same two containers. That is the brief's condition for hiding it
-- and it is the reason this is safe -- a Tool category invented next month gets
-- a slot without anybody remembering to add one.
--
-- pcall'd because SetCoreGuiEnabled throws while the CoreGui is still coming up
-- on a slow join, and a hotbar that failed to start because it could not turn
-- off somebody else's is worse than two hotbars for a second.
--==============================================================================
task.spawn(function()
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then
			return
		end
		task.wait(0.4)
	end
	warn("[Seed/LoadoutUI] could not hide the default Backpack; there may be two hotbars.")
end)

--==============================================================================
-- WHAT A TOOL IS
--
-- Three kinds reach a player's hands in this game and every one of them has to
-- get a slot: a bat, a trap, and a plant -- which is a banked pod or the
-- creature that hatched out of one.
--
-- THE LABEL COMES OFF THE TOOL, never off the species sheet. CarryService names
-- an unhatched pod `???` on purpose -- pods are coloured by weight, so which
-- species you got is not knowable until it hatches, and the Index says ??? for
-- the same reason. Reading the name rather than looking the species up is what
-- keeps this panel from quietly undoing that.
--==============================================================================
type Slot = {
	tool: Tool,
	kind: string,
	key: string,
	label: string,
	item: WeaponData.Item?,
	rank: number,
}

local function classify(tool: Tool): Slot?
	local weapon = WeaponData.Get(tool:GetAttribute(ITEM_ATTR))
	if weapon then
		return {
			tool = tool,
			kind = weapon.Category,
			key = "w:" .. weapon.Id,
			label = weapon.Name,
			item = weapon,
			rank = if weapon.Category == "bat" then 1 else 2,
		}
	end
	local speciesId = tool:GetAttribute("SpeciesId")
	if type(speciesId) == "string" and SeedData.Get(speciesId) then
		local tier = math.floor(tonumber(tool:GetAttribute(ATTR.CarryingKg)) or 1)
		local hatched = tool:GetAttribute("Hatched") == true
		return {
			tool = tool,
			kind = "plant",
			key = string.format("p:%s:%d:%s", speciesId, tier, tostring(hatched)),
			label = tool.Name,
			item = nil,
			rank = 3,
		}
	end
	return nil
end

--==============================================================================
-- HOW A SLOT DRAWS ITSELF
--
-- Returns a builder for UIKit.itemPreview. Weapons come out of WeaponModel --
-- the same call the shop card makes, so the picture in the bag is the object in
-- the hand. Plants come out of CreatureModel at the stage the Tool says it is:
-- a pod if it has not hatched, the grown creature if it has.
--
-- TAGS ARE STRIPPED. CreatureModel's output is the same geometry that stands in
-- a plot, and anything tagged inside a ViewportFrame would be found by
-- PlantSway and animated as though it were growing in somebody's garden.
--==============================================================================
local function builderFor(slot: Slot): ((Instance) -> Model?)?
	local weapon = slot.item
	if weapon then
		return function(parent)
			return WeaponModel.BuildPreview(weapon, parent)
		end
	end
	local speciesId = slot.tool:GetAttribute("SpeciesId")
	local species = if type(speciesId) == "string" then SeedData.Get(speciesId) else nil
	if not species then
		return nil
	end
	local tier = math.floor(tonumber(slot.tool:GetAttribute(ATTR.CarryingKg)) or 1)
	local hatched = slot.tool:GetAttribute("Hatched") == true
	return function(parent)
		local model = if hatched
			then CreatureModel.BuildCreature(species, tier,
				CreatureModel.STAGE_GROWN, CFrame.new(), parent)
			else CreatureModel.BuildPod(species, tier, CFrame.new(), parent)
		if model then
			for _, d in ipairs(model:GetDescendants()) do
				for _, tag in ipairs(CollectionService:GetTags(d)) do
					CollectionService:RemoveTag(d, tag)
				end
			end
			for _, tag in ipairs(CollectionService:GetTags(model)) do
				CollectionService:RemoveTag(model, tag)
			end
		end
		return model
	end
end

local function previewKind(slot: Slot): string
	return if slot.kind == "plant" then "plant" else slot.kind
end

--==============================================================================
-- THE LIVE TOOL LIST
--
-- Both containers, because equipping MOVES a Tool out of the Backpack and into
-- the Character -- reading one loses whatever is in the player's hands, which
-- is the slot they are most likely to be looking at.
--
-- Ordered bat, trap, then plants: predictable, and stable across a respawn
-- because it is derived from what a Tool IS rather than from what order the
-- engine happened to rebuild them in.
--==============================================================================
local function scanTools(): { Slot }
	local slots: { Slot } = {}
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") then
					local slot = classify(child)
					if slot then
						table.insert(slots, slot)
					end
				end
			end
		end
	end
	table.sort(slots, function(a, b)
		if a.rank ~= b.rank then
			return a.rank < b.rank
		end
		if a.label ~= b.label then
			return a.label < b.label
		end
		return a.tool.Name < b.tool.Name
	end)
	return slots
end

local function heldTool(): Tool?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Tool") else nil
end

--==============================================================================
-- PUTTING SOMETHING IN THE PLAYER'S HAND
--
-- Named `holdTool` rather than `select` because `select` is a Lua builtin, and
-- shadowing it in a file this long is a trap for whoever adds a varargs helper
-- to it later.
--==============================================================================
local function holdTool(tool: Tool?)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	SoundKit.play("CardClick")
	if tool == nil or tool.Parent == character then
		humanoid:UnequipTools()
		return
	end
	humanoid:EquipTool(tool)
end

--==============================================================================
-- STATE OFF THE PROFILE
--==============================================================================
local owned: { [string]: boolean } = {}
local loadout: { [string]: string } = { bat = "", trap = "" }
local heardProfile = false

--==============================================================================
-- THE BAG BUTTON
--
-- On the right rail, one row under the Garden, using the same slab builder the
-- other four use -- so it is the same size, the same outline and the same
-- lattice, and it lands in the shared `SeedRail` layer above every dimmer.
-- Nothing overlaps: the left rail is Index and Shop, the right is Garden and
-- this, and the clock owns the middle.
--==============================================================================
-- Bare, like the Garden button above it and unlike the two slabs on the left.
local bagButton = UIKit.railButton(playerGui, {
	name = "BagButton",
	icon = RAIL.BagIcon,
	wide = false,
	bare = true,
})
-- ANCHORED RIGHT, the same way GardenUI anchors the button above this one.
-- `railButton` does not set one, so a right-edge Position without this puts the
-- button's LEFT edge at the screen edge and half of it off the display --
-- measured, at 1136..1186 on an 1148-wide viewport.
bagButton.AnchorPoint = Vector2.new(1, 0)
bagButton.Position = UDim2.new(1, -RAIL.Inset, 0,
	RAIL.Inset + RAIL.SquareSize.Y + RAIL.Gap)

--==============================================================================
-- THE INVENTORY PANEL
--==============================================================================
local modal = UIKit.modal(gui, {
	name = PANEL_NAME,
	title = "Bag",
	maxWidth = 520,
	maxHeight = 600,
})

-- The close button used to be restyled here, for this panel alone. It is in
-- UIKit.modal now, so all five panels get it and this block would have been a
-- second copy drifting out of step with the first.

local TABS = {
	{ id = "equipment", label = "Equipment" },
	{ id = "plants", label = "Plants" },
}
local activeTab = "equipment"
local tabButtons: { [string]: TextButton } = {}
local tabTints: { [string]: UIGradient } = {}
local tabShades: { [string]: Frame } = {}

local tabRow = Instance.new("Frame")
tabRow.Name = "Tabs"
tabRow.Position = UDim2.fromOffset(12, 58)
tabRow.Size = UDim2.new(1, -24, 0, 34)
tabRow.BackgroundTransparency = 1
tabRow.ZIndex = 4
tabRow.Parent = modal.shell

for i, tab in ipairs(TABS) do
	local b = Instance.new("TextButton")
	b.Name = "Tab" .. tab.id
	b.Position = UDim2.fromScale((i - 1) * 0.5, 0)
	b.Size = UDim2.new(0.5, -4, 1, 0)
	b.BackgroundColor3 = PANEL.Shade
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	b.Text = ""
	b.ZIndex = 5
	UIKit.clicks(b)
	b.Parent = tabRow
	UIKit.corner(b, 9)
	UIKit.stroke(b, BLACK, 2)

	--==========================================================================
	-- A TAB IS A BUTTON, SO IT GETS A BUTTON'S DEPTH
	--
	-- The gradient and the shade bar are the same two tricks the shop's price
	-- pills use, which is why they read as pressable here without inventing a
	-- second button language for this panel.
	--
	-- The shade is only shown on the ACTIVE tab. A raised lip under both of them
	-- would say both are selected, which is the one thing a tab row must not do.
	--==========================================================================
	local tabTint = UIKit.gradient(b, PANEL.Fill, PANEL.Shade)

	local tabShade = Instance.new("Frame")
	tabShade.Name = "Shade"
	tabShade.AnchorPoint = Vector2.new(0.5, 1)
	tabShade.Position = UDim2.new(0.5, 0, 1, 0)
	tabShade.Size = UDim2.new(1, 0, 0, 5)
	tabShade.BackgroundColor3 = Color3.fromRGB(46, 110, 34)
	tabShade.BorderSizePixel = 0
	tabShade.Active = false
	tabShade.Visible = false
	tabShade.ZIndex = 5
	tabShade.Parent = b
	UIKit.corner(tabShade, 9)

	local label = UIKit.outlined(b, "Label", 15, CREAM, 2)
	label.Size = UDim2.fromScale(1, 1)
	label.Text = tab.label
	label.ZIndex = 6
	tabButtons[tab.id] = b
	tabTints[tab.id] = tabTint
	tabShades[tab.id] = tabShade
end

modal.body.Position = UDim2.fromOffset(12, 100)
modal.body.Size = UDim2.new(1, -24, 1, -112)

--==============================================================================
-- THE TRAY
--
-- The body was a transparent hole in the panel, so a bag holding four items was
-- four cards floating over four hundred pixels of nothing. Sunk into a darker
-- well with a lip, the same space reads as a TRAY that happens to be part
-- empty -- which is what an inventory with room left in it should look like.
--
-- Nothing moved to achieve it: the body is exactly where it was and holds
-- exactly what it held.
--==============================================================================
modal.body.BackgroundColor3 = WELL
modal.body.BackgroundTransparency = 0
UIKit.corner(modal.body, 12)
UIKit.stroke(modal.body, BLACK, 2)

--==============================================================================
-- AND IT IS TEXTURED, NOT BLANK
--
-- The panel behind it already carries a lattice; giving the tray a fainter one
-- of its own is what stops a half-empty bag reading as a hole cut in a textured
-- surface. Much fainter than the panel's -- 0.93 against 0.55 -- because this
-- one sits UNDER the items and its whole job is to be noticed only when there
-- is nothing on top of it.
--
-- Inset past the corner radius, for the reason UIKit.slab's own lattice is: a
-- square grid drawn to the edge of a rounded box pokes its chords out through
-- the curve.
--==============================================================================
UIKit.lattice(modal.body, {
	spacing = 26,
	thickness = 2,
	colour = PANEL.Lattice,
	transparency = 0.93,
	inset = 7,
	zIndex = 2,
})

--==============================================================================
-- ONE SOFT SHADOW UNDER THE TOP LIP
--
-- A recess is a lie told by two things: a dark fill and a shadow where the
-- surface above it overhangs. The fill alone reads as a dark rectangle, which is
-- what this was before the gradient went in.
--
-- Top edge only, and fading out over 40 pixels. A shadow on all four sides is a
-- vignette, and a vignette on a small brown panel reads as dirt.
--==============================================================================
do
	local recess = Instance.new("Frame")
	recess.Name = "Recess"
	recess.Size = UDim2.new(1, 0, 0, 40)
	recess.BackgroundColor3 = BLACK
	recess.BorderSizePixel = 0
	recess.Active = false
	recess.ZIndex = 3
	recess.Parent = modal.body
	UIKit.corner(recess, 12)
	local fade = Instance.new("UIGradient")
	fade.Rotation = 90
	fade.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.62),
		NumberSequenceKeypoint.new(1, 1),
	})
	fade.Parent = recess
end

local grid = Instance.new("ScrollingFrame")
grid.Name = "Items"
grid.Size = UDim2.fromScale(1, 1)
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.CanvasSize = UDim2.new()
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.ScrollBarThickness = 7
grid.ScrollBarImageColor3 = PANEL.Edge
grid.ScrollBarImageTransparency = 0.1
grid.ElasticBehavior = Enum.ElasticBehavior.Always
grid.ZIndex = 4
grid.Parent = modal.body

local gridPad = Instance.new("UIPadding")
-- Even on all four sides now. It was right and bottom only, so the first card
-- sat hard against the top-left corner of the tray while the other two edges had
-- room -- which is the sort of thing that reads as "unfinished" without anybody
-- being able to say why.
gridPad.PaddingLeft = UDim.new(0, 10)
gridPad.PaddingTop = UDim.new(0, 10)
gridPad.PaddingRight = UDim.new(0, 10)
gridPad.PaddingBottom = UDim.new(0, 10)
gridPad.Parent = grid

local gridLayout = Instance.new("UIGridLayout")
-- Tall enough for a two-line name. "CINDERCRACK BAT" does not fit 96 pixels on
-- one line at any size worth reading, and an ellipsis on a product name is the
-- one truncation a bag cannot afford -- it is the only thing telling a player
-- which of two similar silhouettes they are looking at.
gridLayout.CellSize = UDim2.fromOffset(104, 146)
gridLayout.CellPadding = UDim2.fromOffset(10, 10)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
gridLayout.Parent = grid

local emptyLabel = UIKit.outlined(modal.body, "Empty", 15, MUTED, 2)
emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
emptyLabel.Position = UDim2.fromScale(0.5, 0.42)
emptyLabel.Size = UDim2.new(1, -40, 0, 60)
emptyLabel.TextWrapped = true
emptyLabel.Visible = false
emptyLabel.ZIndex = 5

--==============================================================================
-- AN INVENTORY CARD
--
-- THIS USED TO HAVE NO BACKPLATE, ON PURPOSE, AND THE OWNER HAS SINCE ASKED FOR
-- ONE. The old note argued that a plate behind every item turns a bag into a
-- grid of tiles when what a player scans for is the SHAPE. That was a real
-- concern and it is answered rather than ignored: the plate is a dark, low
-- contrast brown and the item sits in a WELL cut into it, so the silhouette is
-- still the brightest thing on the card and the plate is the thing it sits on.
--
-- What the plate buys is everything a floating outline could not: a card can now
-- be lit, shaded, raised and grouped, and an empty bag looks like a tray with
-- room in it instead of a hole with nothing in it.
--
-- FIVE LAYERS, BOTTOM TO TOP:
--   the button        the plate itself, gradient-lit from above
--   Lip               one bright line along the top edge; this is the entire
--                     difference between a rectangle and a raised surface
--   PreviewWell       a darker recess the item stands in
--   LitRing           an inset green ring, shown only when equipped
--   name / state      the words, which stay the loudest thing on the card
--==============================================================================
--==============================================================================
-- FORWARD-DECLARED, AND THAT IS NOT STYLE
--
-- A card's click handler calls this and the card pool is built above the wire
-- that defines it. Written as a plain `function equipRequest()` further down it
-- would be a GLOBAL, and the closure up here would resolve it as one -- which
-- works right up until somebody moves a line, and is the exact trap ShopUI's
-- own comment records paying for.
--==============================================================================
local equipRequest: (WeaponData.Item) -> ()

--==============================================================================
-- CARRYING A CARD TO THE HOTBAR
--
-- Declared before the card pool because `acquireCard` connects to it, and
-- defined further down because it needs `hotSlots` and `refreshAll`. Two
-- forward locals rather than one big function in the middle of the layout code.
--==============================================================================
local beginDrag: (any, InputObject) -> ()
local dragMoved = false

type Card = {
	button: TextButton,
	preview: UIKit.ItemPreview,
	name: TextLabel,
	state: TextLabel,
	statePill: Frame,
	statePillEdge: UIStroke,
	-- The card face's own gradient, the green ring over it, and the state
	-- button's gradient. All three say the same thing -- equipped or not -- in
	-- three registers, which is what makes it readable at a glance across a grid.
	tint: UIGradient,
	litRing: Frame,
	statePillTint: UIGradient,
	stroke: UIStroke,
}

--==============================================================================
-- A CARD REMEMBERS ITS ROW BY INDEX, NOT BY NAME
--
-- The first version stashed the item id and the Tool NAME on the button and
-- looked the Tool back up by name on click. That is broken for exactly the
-- items this tab is full of: CarryService names every unhatched pod `???`, so
-- a bag with three pods in it has three Tools with the same name and the click
-- would hold whichever one came first.
--
-- The row table is the handle instead, keyed by the slot's position in the
-- grid, which is the one thing a click already knows.
--==============================================================================
type Row = {
	key: string,
	label: string,
	kind: string,
	build: ((Instance) -> Model?)?,
	state: string,
	lit: boolean,
	item: WeaponData.Item?,
	tool: Tool?,
}

local cardPool: { Card } = {}
local cardRows: { [number]: Row } = {}

local function acquireCard(index: number): Card
	local existingCard = cardPool[index]
	if existingCard then
		return existingCard
	end
	local button = Instance.new("TextButton")
	button.Name = "Item" .. index
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = 5
	UIKit.clicks(button)
	button.Parent = grid
	UIKit.corner(button, 12)
	-- Black, always. The keyline is the game's house edge and it is what stops a
	-- brown card on a brown panel from dissolving into it; the equipped state is
	-- said by the green ring inside, not by removing the outline.
	local stroke = UIKit.stroke(button, BLACK, 2)
	local tint = UIKit.gradient(button, CARD_TOP, CARD_BOTTOM)

	local lip = Instance.new("Frame")
	lip.Name = "Lip"
	lip.AnchorPoint = Vector2.new(0.5, 0)
	lip.Position = UDim2.new(0.5, 0, 0, 3)
	lip.Size = UDim2.new(1, -16, 0, 2)
	lip.BackgroundColor3 = LIP
	lip.BackgroundTransparency = 0.45
	lip.BorderSizePixel = 0
	lip.Active = false
	lip.ZIndex = 6
	lip.Parent = button
	UIKit.corner(lip, 1)

	local previewWell = Instance.new("Frame")
	previewWell.Name = "PreviewWell"
	previewWell.Position = UDim2.fromOffset(6, 6)
	previewWell.Size = UDim2.new(1, -12, 0, 74)
	previewWell.BackgroundColor3 = WELL
	previewWell.BorderSizePixel = 0
	previewWell.Active = false
	previewWell.ZIndex = 5
	previewWell.Parent = button
	UIKit.corner(previewWell, 9)
	UIKit.stroke(previewWell, BLACK, 1.5, 0.35)

	local preview = UIKit.itemPreview(button, {
		name = "Preview",
		size = UDim2.new(1, -12, 0, 74),
		position = UDim2.fromOffset(6, 6),
	})

	--==========================================================================
	-- THE EQUIPPED RING
	--
	-- Inset by three, so it reads as a ring INSIDE the card rather than as a
	-- second outline fighting the black one. A green card fill alone was not
	-- enough at this size -- the cards are 104 wide and a tint that small reads
	-- as a lighting difference; the ring is the part you actually notice.
	--==========================================================================
	local litRing = Instance.new("Frame")
	litRing.Name = "LitRing"
	litRing.Position = UDim2.fromOffset(3, 3)
	litRing.Size = UDim2.new(1, -6, 1, -6)
	litRing.BackgroundTransparency = 1
	litRing.Active = false
	litRing.Visible = false
	litRing.ZIndex = 9
	litRing.Parent = button
	UIKit.corner(litRing, 9)
	UIKit.stroke(litRing, READY, 2)

	--==========================================================================
	-- THE NAME SHRINKS RATHER THAN WRAPPING BADLY
	--
	-- "CINDERCRACK BAT" and "BRAMBLEJAW TRAP" are two lines at 12pt on a 104px
	-- card and they were fitting only just. TextScaled with a floor of 9 lets a
	-- long name give up a point or two instead of pushing its second line into
	-- the state button, and a short name still draws at the full 12.
	--==========================================================================
	local nameLabel = UIKit.outlined(button, "Name", 12, CREAM, 2)
	nameLabel.Position = UDim2.new(0, 7, 0, 84)
	nameLabel.Size = UDim2.new(1, -14, 0, 30)
	nameLabel.TextWrapped = true
	nameLabel.TextScaled = true
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.ZIndex = 8
	local nameFit = Instance.new("UITextSizeConstraint")
	nameFit.MaxTextSize = 12
	nameFit.MinTextSize = 9
	nameFit.Parent = nameLabel

	--==========================================================================
	-- THE STATE GETS A PILL
	--
	-- EQUIPPED and TAP TO EQUIP were 11pt muted text on a transparent card, at
	-- the bottom of a column of previews -- the one thing on the card a player
	-- actually has to read to know what pressing it will do, and the quietest
	-- thing on it. Boxed, it reads at a glance.
	--
	-- The pill hugs the words rather than spanning the card: EQUIPPED and TAP TO
	-- EQUIP are different lengths, and a full-width box behind a short word looks
	-- like a broken background rather than a label.
	--==========================================================================
	local statePill = Instance.new("Frame")
	statePill.Name = "StatePill"
	statePill.AnchorPoint = Vector2.new(0.5, 0)
	statePill.Position = UDim2.new(0.5, 0, 0, 117)
	statePill.Size = UDim2.fromOffset(60, 20)
	statePill.BorderSizePixel = 0
	statePill.Active = false
	statePill.ZIndex = 7
	statePill.Parent = button
	UIKit.corner(statePill, 6)
	local statePillEdge = UIKit.stroke(statePill, BLACK, 2)
	local statePillTint = UIKit.gradient(statePill, PILL_OFF_TOP, PILL_OFF_BOTTOM)

	--==========================================================================
	-- IT LOOKS LIKE A BUTTON BECAUSE IT IS THE THING YOU PRESS
	--
	-- Strictly the whole CARD is the click target and this is a label on it --
	-- but it is the label that says what pressing will do, so it is the part
	-- that has to look pressable. Gradient, black keyline and a shade bar under
	-- it: the same three things the shop's price pills use, so the game has one
	-- button language rather than two.
	--==========================================================================
	local stateShade = Instance.new("Frame")
	stateShade.Name = "Shade"
	stateShade.AnchorPoint = Vector2.new(0.5, 1)
	stateShade.Position = UDim2.new(0.5, 0, 1, 0)
	stateShade.Size = UDim2.new(1, 0, 0, 5)
	stateShade.BackgroundColor3 = Color3.fromRGB(44, 30, 22)
	stateShade.BorderSizePixel = 0
	stateShade.Active = false
	stateShade.ZIndex = 7
	stateShade.Parent = statePill
	UIKit.corner(stateShade, 6)

	local stateLabel = Instance.new("TextLabel")
	stateLabel.Name = "State"
	stateLabel.AnchorPoint = Vector2.new(0.5, 0)
	stateLabel.Position = UDim2.new(0.5, 0, 0, 120)
	stateLabel.Size = UDim2.new(1, -8, 0, 15)
	stateLabel.BackgroundTransparency = 1
	stateLabel.Font = Enum.Font.FredokaOne
	stateLabel.TextSize = 11
	stateLabel.TextColor3 = CREAM
	stateLabel.TextTruncate = Enum.TextTruncate.AtEnd
	stateLabel.ZIndex = 8
	stateLabel.Parent = button
	UIKit.stroke(stateLabel, BLACK, 1.5)

	-- Rides TextBounds so the pill follows the words without every caller having
	-- to remember to resize it.
	stateLabel:GetPropertyChangedSignal("TextBounds"):Connect(function()
		statePill.Size = UDim2.fromOffset(math.ceil(stateLabel.TextBounds.X) + 20, 20)
	end)

	local card: Card = {
		button = button,
		preview = preview,
		name = nameLabel,
		state = stateLabel,
		statePill = statePill,
		statePillEdge = statePillEdge,
		tint = tint,
		litRing = litRing,
		statePillTint = statePillTint,
		stroke = stroke,
	}
	--==========================================================================
	-- TAP TO USE, DRAG TO PIN
	--
	-- One finger, two verbs, told apart by whether it MOVED. Under
	-- DRAG_THRESHOLD it is a tap and does what tapping a card has always done;
	-- past it the card is being carried to the hotbar and the tap is cancelled.
	--
	-- Activated is NOT how the tap is detected any more. Roblox fires it on
	-- release over the button, which a drag that curves back would also satisfy,
	-- so the two verbs would both run. `dragMoved` is the guard.
	--==========================================================================
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch
			and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local row = cardRows[index]
		if not row or row.kind ~= "plant" then
			-- Only plants are pinnable: a bat and a trap live in their own two
			-- slots beside the bag and are not part of this strip.
			return
		end
		beginDrag(row, input)
	end)

	button.Activated:Connect(function()
		if dragMoved then
			return
		end
		local row = cardRows[index]
		if not row then
			return
		end
		if row.item then
			equipRequest(row.item)
		elseif row.tool then
			holdTool(row.tool)
		end
	end)
	cardPool[index] = card
	return card
end

--==============================================================================
-- THE SIDE EQUIPMENT PANEL
--
-- Two slots, stacked, down the right edge under the bag. Compact on purpose:
-- it is a readout of the loadout with a way to change it, not a third inventory.
--
-- Clicking a slot opens the bag on the tab that slot lives in, with the slot
-- remembered -- so choosing "another owned item in that category" is the same
-- grid the player already knows rather than a second chooser to learn.
--==============================================================================
local sideSlots: { [string]: { button: TextButton, preview: UIKit.ItemPreview,
	label: TextLabel, stroke: UIStroke } } = {}

local side = Instance.new("Frame")
side.Name = "Equipment"
side.AnchorPoint = Vector2.new(1, 0)
side.Position = UDim2.new(1, -RAIL.Inset, 0,
	RAIL.Inset + (RAIL.SquareSize.Y + RAIL.Gap) * 2 + 6)
side.Size = UDim2.fromOffset(64, 152)
side.BackgroundTransparency = 1
side.ZIndex = 4
side.Parent = gui

for i, category in ipairs({ "bat", "trap" }) do
	local button = Instance.new("TextButton")
	button.Name = "Slot" .. category
	button.Position = UDim2.fromOffset(0, (i - 1) * 76)
	button.Size = UDim2.fromOffset(64, 68)
	button.BackgroundColor3 = PANEL.Shade
	button.BackgroundTransparency = 0.25
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = 5
	UIKit.clicks(button)
	button.Parent = side
	UIKit.corner(button, 12)
	local stroke = UIKit.stroke(button, BLACK, 2.5)

	local preview = UIKit.itemPreview(button, {
		name = "Preview",
		size = UDim2.new(1, -6, 1, -18),
		position = UDim2.fromOffset(3, 2),
		scrim = 1,
	})

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.AnchorPoint = Vector2.new(0.5, 1)
	label.Position = UDim2.new(0.5, 0, 1, -2)
	label.Size = UDim2.new(1, -6, 0, 14)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 10
	label.TextColor3 = MUTED
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Text = string.upper(category)
	label.ZIndex = 8
	label.Parent = button

	sideSlots[category] = { button = button, preview = preview,
		label = label, stroke = stroke }
end

--==============================================================================
-- THE HOTBAR
--
-- Bottom centre, one slot per live Tool, in a stable order. It replaces the
-- engine's own because it has to look like the rest of this HUD -- but it is
-- built from the same two containers the engine reads, so nothing it could show
-- is missing from this.
--==============================================================================
local hotbar = Instance.new("Frame")
hotbar.Name = "Hotbar"
hotbar.AnchorPoint = Vector2.new(0.5, 1)
hotbar.Position = UDim2.new(0.5, 0, 1, -12)
hotbar.Size = UDim2.fromOffset(10, 74)
hotbar.AutomaticSize = Enum.AutomaticSize.X
hotbar.BackgroundTransparency = 1
hotbar.ZIndex = 4
hotbar.Parent = gui

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
hotbarLayout.Padding = UDim.new(0, 6)
hotbarLayout.Parent = hotbar

type HotSlot = {
	button: TextButton,
	preview: UIKit.ItemPreview,
	key: TextLabel,
	name: TextLabel,
	cooldown: Frame,
	stroke: UIStroke,
	tool: Tool?,
	item: WeaponData.Item?,
}

local hotSlots: { HotSlot } = {}

local function acquireHotSlot(index: number): HotSlot
	local existingSlot = hotSlots[index]
	if existingSlot then
		return existingSlot
	end
	local button = Instance.new("TextButton")
	button.Name = "Slot" .. index
	button.LayoutOrder = index
	button.Size = UDim2.fromOffset(64, 68)
	button.BackgroundColor3 = PANEL.Shade
	button.BackgroundTransparency = 0.3
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = 5
	button.Parent = hotbar
	UIKit.corner(button, 12)
	local stroke = UIKit.stroke(button, BLACK, 2.5)

	--==========================================================================
	-- THE COOLDOWN, DRAWN UNDER THE ITEM
	--
	-- A dark shade rising from the bottom of the slot, so a bat that cannot
	-- swing yet is dimmed from the feet up. Under the preview rather than over
	-- it, because a player checking a cooldown is also checking WHICH weapon
	-- they are about to swing.
	--==========================================================================
	local cooldown = Instance.new("Frame")
	cooldown.Name = "Cooldown"
	cooldown.AnchorPoint = Vector2.new(0, 1)
	cooldown.Position = UDim2.fromScale(0, 1)
	cooldown.Size = UDim2.fromScale(1, 0)
	cooldown.BackgroundColor3 = BLACK
	cooldown.BackgroundTransparency = 0.45
	cooldown.BorderSizePixel = 0
	cooldown.ZIndex = 6
	cooldown.Parent = button
	UIKit.corner(cooldown, 12)

	local preview = UIKit.itemPreview(button, {
		name = "Preview",
		size = UDim2.new(1, -6, 1, -16),
		position = UDim2.fromOffset(3, 1),
		scrim = 1,
	})

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "Key"
	keyLabel.Position = UDim2.fromOffset(4, 2)
	keyLabel.Size = UDim2.fromOffset(14, 14)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Font = Enum.Font.FredokaOne
	keyLabel.TextSize = 11
	keyLabel.TextColor3 = MUTED
	keyLabel.TextXAlignment = Enum.TextXAlignment.Left
	keyLabel.ZIndex = 9
	keyLabel.Parent = button

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.AnchorPoint = Vector2.new(0.5, 1)
	nameLabel.Position = UDim2.new(0.5, 0, 1, -1)
	nameLabel.Size = UDim2.new(1, -6, 0, 13)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextSize = 10
	nameLabel.TextColor3 = CREAM
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.ZIndex = 9
	nameLabel.Parent = button

	local slot: HotSlot = {
		button = button,
		preview = preview,
		key = keyLabel,
		name = nameLabel,
		cooldown = cooldown,
		stroke = stroke,
		tool = nil,
		item = nil,
	}
	button.Activated:Connect(function()
		holdTool(slot.tool)
	end)
	hotSlots[index] = slot
	return slot
end

--==============================================================================
-- DRAWING
--==============================================================================
local liveSlots: { Slot } = {}

--==============================================================================
-- WHICH FIVE, AND WHO DECIDES
--
-- With ten slots the hotbar could simply BE the tool list -- everything fitted,
-- so no choice had to be made and none was offered. Five is smaller than most
-- players' bags, so something has to choose, and the player is the only one who
-- knows which plant they are about to want.
--
-- `pinned` is that choice: slot index -> the item KEY the player dropped there.
-- Anything not pinned is filled in the existing order, so a bag that has never
-- been arranged behaves exactly as it did and a new pickup still appears.
--
-- KEYED BY WHAT A THING IS, NOT BY WHICH TOOL INSTANCE IT IS. `Slot.key` is
-- "p:<species>:<tier>:<hatched>", so a pin survives a respawn -- which destroys
-- and rebuilds every Tool -- and two identical Voidpetals are interchangeable,
-- which is what a player means when they pin one.
--
-- SESSION-LOCAL, DELIBERATELY. Making this outlive a rejoin means a field on the
-- profile, a schema version and a migration, and none of that should be decided
-- by the feature that needed it first. Noted in HANDOFF as the follow-up.
--==============================================================================
local pinned: { [number]: string } = {}

local function pinnedSlotFor(key: string): number?
	for index, k in pairs(pinned) do
		if k == key then
			return index
		end
	end
	return nil
end

--==============================================================================
-- TWO PASSES, AND THE ORDER MATTERS
--
-- Pinned first, so a player's arrangement wins over the alphabet. Then the
-- leftovers fill whatever is still empty, in the same bat/trap/plants order the
-- strip has always used.
--
-- Each tool is CONSUMED as it is placed, which is what makes two slots pinned to
-- the same key show two different Voidpetals rather than the same one twice --
-- and what stops an unpinned pass re-showing something already pinned further
-- along the strip.
--==============================================================================
local function refreshHotbar()
	local held = heldTool()

	local taken: { [number]: boolean } = {}
	local placed: { [number]: Slot } = {}

	for i = 1, HOTBAR_SLOTS do
		local want = pinned[i]
		if want then
			for j, data in ipairs(liveSlots) do
				if not taken[j] and data.key == want then
					taken[j] = true
					placed[i] = data
					break
				end
			end
		end
	end

	local nextFree = 1
	for i = 1, HOTBAR_SLOTS do
		if not placed[i] and not pinned[i] then
			while nextFree <= #liveSlots and taken[nextFree] do
				nextFree += 1
			end
			if nextFree <= #liveSlots then
				taken[nextFree] = true
				placed[i] = liveSlots[nextFree]
			end
		end
	end

	--==========================================================================
	-- EVERY SLOT IS DRAWN, EMPTY OR NOT
	--
	-- It used to hide the ones with nothing in them, which was right when the
	-- strip was just a list. It is wrong now: an empty slot is the DROP TARGET,
	-- and a drop target nobody can see is a feature nobody finds.
	--==========================================================================
	for i = 1, math.max(HOTBAR_SLOTS, #hotSlots) do
		local slot = hotSlots[i]
		if i > HOTBAR_SLOTS then
			if slot then
				slot.button.Visible = false
				slot.tool = nil
			end
		else
			slot = acquireHotSlot(i)
			local data = placed[i]
			slot.button.Visible = true
			slot.tool = if data then data.tool else nil
			slot.item = if data then data.item else nil
			slot.key.Text = tostring(i)
			if data then
				slot.preview.setModel(data.key, builderFor(data), previewKind(data))
				slot.name.Text = data.label
			else
				slot.preview.setModel("empty:" .. i, nil, "plant")
				slot.name.Text = ""
			end
			local isHeld = data ~= nil and data.tool == held
			slot.stroke.Color = if isHeld then PICKED
				elseif pinned[i] then PANEL.Edge
				else BLACK
			slot.stroke.Thickness = if isHeld then 3 else 2.5
			slot.button.BackgroundTransparency = if isHeld then 0.1
				elseif data then 0.3
				else 0.62
		end
	end
end

local function refreshSide()
	for _, category in ipairs({ "bat", "trap" }) do
		local ui = sideSlots[category]
		local id = loadout[category]
		local item = if id ~= "" then WeaponData.Get(id) else nil
		--======================================================================
		-- THE LABEL NAMES THE SLOT, NOT THE WEAPON IN IT
		--
		-- Sixty-four pixels is four or five characters of LuckiestGuy, so an
		-- item name here is always an ellipsis -- "CINDER CR...", "BRAMBLEJ..."
		-- -- which tells a player less than the word BAT does. The model above
		-- it already says which weapon; this says which slot, and the two
		-- together are the whole readout.
		--======================================================================
		ui.label.Text = string.upper(category)
		if item then
			ui.preview.setModel("w:" .. item.Id, function(parent)
				return WeaponModel.BuildPreview(item, parent)
			end, item.Category)
			ui.label.TextColor3 = CREAM
			ui.stroke.Color = PANEL.Edge
		else
			ui.preview.setModel("empty:" .. category, nil, category)
			ui.label.TextColor3 = MUTED
			ui.stroke.Color = BLACK
		end
		--======================================================================
		-- LIT WHEN THIS SLOT'S ITEM IS THE ONE IN YOUR HANDS
		--
		-- Two different facts share this panel and they must not look the same:
		-- what is EQUIPPED into a slot, and which of the two is SELECTED. The
		-- name says the first; the amber ring says the second.
		--======================================================================
		local held = heldTool()
		local heldItem = if held then WeaponData.Get(held:GetAttribute(ITEM_ATTR)) else nil
		if item and heldItem and heldItem.Id == item.Id then
			ui.stroke.Color = PICKED
			ui.stroke.Thickness = 3
		else
			ui.stroke.Thickness = 2.5
		end
	end
end

local function refreshBag()
	for _, tab in ipairs(TABS) do
		local b = tabButtons[tab.id]
		local on = activeTab == tab.id
		-- The gradient owns the fill now, so the colour is set on it rather than
		-- on the button -- UIKit.gradient leaves the background white and
		-- multiplies, so writing BackgroundColor3 here would do nothing at all.
		local tint = tabTints[tab.id]
		if tint then
			tint.Color = if on
				then ColorSequence.new(RAIL.ShopFace, RAIL.ShopShade)
				else ColorSequence.new(PANEL.Fill, PANEL.Shade)
		end
		local shade = tabShades[tab.id]
		if shade then
			shade.Visible = on
		end
		local label = b:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.TextColor3 = if on then WHITE else MUTED
		end
	end

	--== WHAT THIS TAB SHOWS ==--
	local rows: { Row } = {}

	if activeTab == "equipment" then
		--======================================================================
		-- OWNED, NOT CARRIED
		--
		-- The equipment tab is the shelf a player has bought, so it comes off
		-- the profile rather than off the Backpack -- an owned bat that is not
		-- in a loadout slot has no Tool, and it still belongs in the bag.
		--======================================================================
		for _, item in ipairs(WeaponData.Items) do
			if owned[item.Id] then
				local equipped = loadout[item.Category] == item.Id
				table.insert(rows, {
					key = "w:" .. item.Id,
					label = item.Name,
					kind = item.Category,
					build = function(parent)
						return WeaponModel.BuildPreview(item, parent)
					end,
					state = if equipped then "EQUIPPED" else "TAP TO EQUIP",
					lit = equipped,
					item = item,
					tool = nil,
				})
			end
		end
	else
		--======================================================================
		-- WHAT "PLANT INVENTORY" MEANS HERE
		--
		-- Exactly the banked pods and hatched creatures in the player's hands
		-- and bag -- which is what `profile.Held` saves and what the hotbar
		-- shows. Plants GROWING IN A PLOT are deliberately absent: they are not
		-- items, they are somebody's garden, and turning them into portable
		-- entries would be inventing an inventory the game does not have.
		--======================================================================
		for _, slot in ipairs(liveSlots) do
			if slot.kind == "plant" then
				table.insert(rows, {
					key = slot.key .. ":" .. tostring(slot.tool),
					label = slot.label,
					kind = "plant",
					build = builderFor(slot),
					state = if slot.tool == heldTool() then "IN HAND" else "TAP TO HOLD",
					lit = slot.tool == heldTool(),
					item = nil,
					tool = slot.tool,
				})
			end
		end
	end

	emptyLabel.Visible = #rows == 0
	emptyLabel.Text = if activeTab == "equipment"
		then "Nothing bought yet.\nMarigold sells bats and traps at the stall."
		else "No plants in your bag.\nCarry a pod past the red line to bank it."

	table.clear(cardRows)
	for i = 1, math.max(#rows, #cardPool) do
		local row = rows[i]
		if not row then
			local spare = cardPool[i]
			if spare then
				spare.button.Visible = false
			end
		else
			cardRows[i] = row
			local card = acquireCard(i)
			card.button.Visible = true
			card.button.LayoutOrder = i
			card.preview.setModel(row.key, row.build, row.kind)
			card.name.Text = row.label
			card.state.Text = row.state
			--==============================================================
			-- LIT SAYS ITSELF THREE TIMES
			--
			-- The card warms toward green, a green ring appears inside its
			-- keyline, and the state button fills green. One of those alone is
			-- a shade difference on a 104px card; all three together is a card
			-- you can pick out of a grid without reading a word on it.
			--
			-- The black keyline does NOT change. It is the house edge on every
			-- surface in this game, and swapping it for green would make an
			-- equipped card a different kind of object rather than the same
			-- card in a different state.
			--==============================================================
			card.state.TextColor3 = if row.lit then WHITE else CREAM
			card.tint.Color = if row.lit
				then ColorSequence.new(LIT_TOP, LIT_BOTTOM)
				else ColorSequence.new(CARD_TOP, CARD_BOTTOM)
			card.litRing.Visible = row.lit
			card.statePillTint.Color = if row.lit
				then ColorSequence.new(PILL_ON_TOP, PILL_ON_BOTTOM)
				else ColorSequence.new(PILL_OFF_TOP, PILL_OFF_BOTTOM)
			local shade = card.statePill:FindFirstChild("Shade")
			if shade and shade:IsA("Frame") then
				shade.BackgroundColor3 = if row.lit
					then Color3.fromRGB(52, 118, 34)
					else Color3.fromRGB(44, 30, 22)
			end
		end
	end
end

--==============================================================================
-- THE DRAG, IN FULL
--
-- WHY THE HOTBAR IS A LEGAL TARGET AT ALL. The bag's dimmer is ZIndex 1 and the
-- hotbar is 4, and these ScreenGuis run ZIndexBehavior.Global -- so the strip
-- already draws OVER the open bag. That is lucky rather than designed, and it
-- is what makes "drag it onto the hotbar" possible without moving either one.
-- The lift below only raises it further so it is unmistakably the target.
--
-- POSITIONS ARE COMPARED RAW, AND THAT WAS MEASURED RATHER THAN ASSUMED.
--
-- The first version subtracted GuiService:GetGuiInset() from InputObject.Position
-- on the reasoning that input is screen-space while AbsolutePosition is measured
-- from below the topbar. That is wrong, and it silently broke every drop: on the
-- emulated phone the inset is 58 pixels, which is most of a 68-pixel slot, so the
-- hit test landed in the gap above the strip and found nothing.
--
-- Measured on a real touch against a known card:
--
--     input.Position   526, 217
--     card centre      526, 218      -- delta 0, -1
--
-- InputObject.Position is ALREADY in gui space. No conversion.
--==============================================================================
local DRAG_THRESHOLD = 8
local dragGhost: TextLabel? = nil
local dragRow: any = nil
local dragConns: { RBXScriptConnection } = {}

local function guiPoint(input: InputObject): Vector2
	return Vector2.new(input.Position.X, input.Position.Y)
end

local function slotUnder(point: Vector2): number?
	for i = 1, HOTBAR_SLOTS do
		local slot = hotSlots[i]
		if slot and slot.button.Visible then
			local p, sz = slot.button.AbsolutePosition, slot.button.AbsoluteSize
			if point.X >= p.X and point.X <= p.X + sz.X
				and point.Y >= p.Y and point.Y <= p.Y + sz.Y then
				return i
			end
		end
	end
	return nil
end

local function endDrag(dropAt: Vector2?)
	for _, c in ipairs(dragConns) do
		c:Disconnect()
	end
	table.clear(dragConns)
	if dragGhost then
		dragGhost:Destroy()
		dragGhost = nil
	end
	hotbar.ZIndex = 4
	for i = 1, HOTBAR_SLOTS do
		local slot = hotSlots[i]
		if slot then
			slot.button.ZIndex = 5
		end
	end

	local row = dragRow
	dragRow = nil
	if not (row and dropAt) then
		return
	end
	local index = slotUnder(dropAt)
	if not index then
		return
	end

	--==========================================================================
	-- A DROP IS A MOVE, NOT A COPY
	--
	-- The same plant pinned in two slots would show twice and waste one of five,
	-- so wherever it was before is cleared first. Dropping onto a slot that is
	-- already pinned to something else simply replaces it: the player is looking
	-- at that slot and pointing at it, which is as clear a statement of intent
	-- as this interface gets.
	--==========================================================================
	-- The SLOT key, not the Row key: a Row key carries the tool instance so that
	-- two identical plants get separate cards, and a pin must not care which of
	-- the two it gets.
	local key: string? = nil
	for _, data in ipairs(liveSlots) do
		if data.tool == row.tool then
			key = data.key
			break
		end
	end
	if not key then
		return
	end
	local was = pinnedSlotFor(key)
	if was then
		pinned[was] = nil
	end
	pinned[index] = key
	SoundKit.play("UIClick")
	refreshHotbar()
end

function beginDrag(row: any, input: InputObject)
	if dragRow then
		return
	end
	dragRow = row
	dragMoved = false
	local startAt = guiPoint(input)

	table.insert(dragConns, UserInputService.InputChanged:Connect(function(moved)
		if moved.UserInputType ~= Enum.UserInputType.Touch
			and moved.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local at = guiPoint(moved)
		if not dragMoved then
			if (at - startAt).Magnitude < DRAG_THRESHOLD then
				return
			end
			--==================================================================
			-- PAST THE THRESHOLD: THE CARD IS IN THE AIR
			--
			-- The hotbar lifts above everything in this ScreenGui so there is no
			-- doubt about where the card is going, and a label follows the
			-- finger. A label rather than a copy of the card: a 104-pixel card
			-- under a thumb hides the very slots it is being aimed at.
			--==================================================================
			dragMoved = true
			hotbar.ZIndex = 60
			for i = 1, HOTBAR_SLOTS do
				local slot = hotSlots[i]
				if slot then
					slot.button.ZIndex = 61
				end
			end
			local ghost = UIKit.outlined(gui, "DragGhost", 14, CREAM, 2)
			ghost.AnchorPoint = Vector2.new(0.5, 1)
			ghost.Size = UDim2.fromOffset(150, 22)
			ghost.ZIndex = 70
			ghost.Text = string.upper(row.label) .. "  ->  HOTBAR"
			dragGhost = ghost
		end
		if dragGhost then
			dragGhost.Position = UDim2.fromOffset(at.X, at.Y - 12)
		end
	end))

	table.insert(dragConns, UserInputService.InputEnded:Connect(function(over)
		if over.UserInputType ~= Enum.UserInputType.Touch
			and over.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local at = if dragMoved then guiPoint(over) else nil
		endDrag(at)
		-- Cleared on the next frame, not now: Activated fires AFTER InputEnded,
		-- and the guard has to still be up when it does or a completed drag
		-- would also hold the tool it just pinned.
		task.defer(function()
			dragMoved = false
		end)
	end))
end

--==============================================================================
-- ONE REDRAW, COALESCED
--
-- Tools arrive in bursts -- equipping reparents, respawning rebuilds the whole
-- Backpack -- so a redraw per event would rebuild the same strip five times in
-- a frame. Deferred and collapsed, the same trick CarryService uses for its
-- hotbar snapshot and for the same reason.
--==============================================================================
local redrawPending = false

local function redraw()
	if redrawPending then
		return
	end
	redrawPending = true
	task.defer(function()
		redrawPending = false
		liveSlots = scanTools()
		refreshHotbar()
		refreshSide()
		refreshBag()
	end)
end

--==============================================================================
-- THE WIRE
--==============================================================================
local remotes = SeedGame:WaitForChild("Remotes", 20)
local channel: RemoteEvent? = nil
if remotes then
	local ev = remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20)
	if ev and ev:IsA("RemoteEvent") then
		channel = ev
	end
end

equipRequest = function(item: WeaponData.Item)
	if not channel or not heardProfile then
		SoundKit.play("Denied")
		return
	end
	if not owned[item.Id] then
		SoundKit.play("Denied")
		return
	end
	--==========================================================================
	-- THE SAME VERB THE SHOP SENDS
	--
	-- Not a second equip path: WeaponShopService validates ownership and derives
	-- the slot from the item's own category, so this panel and that one cannot
	-- put a weapon anywhere different.
	--==========================================================================
	if loadout[item.Category] == item.Id then
		channel:FireServer(W.EquipAction, "", item.Category)
	else
		channel:FireServer(W.EquipAction, item.Id)
	end
end

local function receive(profile: any)
	if type(profile) ~= "table" then
		return
	end
	local changed = false
	if type(profile.Weapons) == "table" then
		for _, item in ipairs(WeaponData.Items) do
			local has = profile.Weapons[item.Id] == true
			if has ~= (owned[item.Id] == true) then
				owned[item.Id] = has
				changed = true
			end
		end
	end
	for _, category in ipairs({ "bat", "trap" }) do
		local field = if category == "bat" then "EquippedBat" else "EquippedTrap"
		local value = (profile :: any)[field]
		if type(value) == "string" and value ~= loadout[category] then
			loadout[category] = value
			changed = true
		end
	end
	if not heardProfile then
		heardProfile = true
		changed = true
	end
	if changed then
		redraw()
	end
end

if remotes then
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
end

--==============================================================================
-- WATCHING THE CONTAINERS
--
-- The Backpack is DESTROYED and rebuilt on every respawn, so a connection to
-- the one that exists at login is a connection to an instance the engine will
-- throw away. Same trap CarryService documents, same answer: watch the player
-- for a new Backpack as well as the Backpack for new Tools.
--==============================================================================
local containerConns: { RBXScriptConnection } = {}

local function watchContainer(container: Instance)
	table.insert(containerConns, container.ChildAdded:Connect(redraw))
	table.insert(containerConns, container.ChildRemoved:Connect(redraw))
end

local function rebindContainers()
	for _, c in ipairs(containerConns) do
		c:Disconnect()
	end
	table.clear(containerConns)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack then
		watchContainer(backpack)
	end
	if player.Character then
		watchContainer(player.Character)
	end
	redraw()
end

player.ChildAdded:Connect(function(child)
	if child:IsA("Backpack") then
		rebindContainers()
	end
end)
player.CharacterAdded:Connect(function()
	task.defer(rebindContainers)
end)
rebindContainers()

--==============================================================================
-- OPEN AND SHUT
--==============================================================================
local open = false

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		redraw()
	elseif player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
	modal.setOpen(want)
end

bagButton.Activated:Connect(function()
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

for _, tab in ipairs(TABS) do
	tabButtons[tab.id].Activated:Connect(function()
		if activeTab == tab.id then
			return
		end
		activeTab = tab.id
		grid.CanvasPosition = Vector2.zero
		refreshBag()
	end)
end

--== A SIDE SLOT OPENS THE BAG ON ITS OWN TAB ==--
for _, category in ipairs({ "bat", "trap" }) do
	sideSlots[category].button.Activated:Connect(function()
		activeTab = "equipment"
		grid.CanvasPosition = Vector2.zero
		setOpen(true)
		refreshBag()
	end)
end

--==============================================================================
-- THE NUMBER ROW
--
-- Bound here because turning the CoreGui Backpack off takes its bindings with
-- it. ContextActionService rather than UserInputService so a text box has
-- priority over this and typing "1" in chat does not swap weapons.
--==============================================================================
local KEYS = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,
	Enum.KeyCode.Five, Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight,
	Enum.KeyCode.Nine, Enum.KeyCode.Zero,
}

ContextActionService:BindAction("SeedHotbarKeys", function(_, state, input)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	for i, key in ipairs(KEYS) do
		if input.KeyCode == key then
			local slot = liveSlots[i]
			if slot then
				holdTool(slot.tool)
				redraw()
			end
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end, false, table.unpack(KEYS))

--==============================================================================
-- THE COOLDOWN TICK
--
-- One loop for the whole strip, and it only runs while something is actually
-- cooling down -- a player standing in their garden pays nothing for it.
--
-- The clock is the SERVER'S: `ReadyAt` is stamped in server time by
-- CombatService, and `Workspace:GetServerTimeNow()` is the same clock on this
-- side. A client counting its own seconds would show a bat as ready a frame
-- before it is, which is the one thing a cooldown readout must not do.
--==============================================================================
RunService.Heartbeat:Connect(function()
	local now = Workspace:GetServerTimeNow()
	for _, slot in ipairs(hotSlots) do
		if slot.button.Visible and slot.tool and slot.item then
			local readyAt = tonumber(slot.tool:GetAttribute(READY_AT))
			local total = if slot.item.Category == "trap"
				then WeaponData.Trap.PlaceCooldownSeconds
				else slot.item.Cooldown
			local left = if readyAt then readyAt - now else 0
			if left > 0 and total > 0 then
				slot.cooldown.Size = UDim2.fromScale(1, math.min(1, left / total))
			elseif slot.cooldown.Size.Y.Scale ~= 0 then
				slot.cooldown.Size = UDim2.fromScale(1, 0)
			end
		elseif slot.cooldown.Size.Y.Scale ~= 0 then
			slot.cooldown.Size = UDim2.fromScale(1, 0)
		end
	end
end)

--== The held Tool changing is a redraw: it is what the amber ring shows. ==--
task.spawn(function()
	local lastHeld: Tool? = nil
	while true do
		local held = heldTool()
		if held ~= lastHeld then
			lastHeld = held
			redraw()
		end
		task.wait(0.15)
	end
end)

redraw()
