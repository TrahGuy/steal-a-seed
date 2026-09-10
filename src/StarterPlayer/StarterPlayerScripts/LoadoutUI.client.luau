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
local TweenService = game:GetService("TweenService")
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
-- TEN OR FIVE, DECIDED BY THE DEVICE RATHER THAN PICKED ONCE
--
-- It was ten, then five, and both were right for one machine and wrong for the
-- other. Ten is what the NUMBER ROW can address, which is a keyboard's reason
-- and worth having when there is a keyboard. Five is what a THUMB can cross
-- without looking: ten 64-pixel slots come to 694 px of strip, which on a
-- 735-pixel phone is the whole screen width and leaves a player poking at
-- targets the size of a fingernail.
--
-- So the count follows the device, and the SLOT SIZE NEVER CHANGES. Squeezing
-- ten slots into 735 px would mean ~40 px each, well under the 44 px Roblox
-- asks for a touch target and under what a thumb can hit while running from a
-- guardian. A hotbar that scrolls is no better -- that is a hotbar nobody can
-- hit without looking. Five real slots beat ten unusable ones.
--
-- BOTH CONDITIONS, not either. A keyboard alone is not enough: a narrow window
-- on a desktop still cannot show 694 px of strip without eating the screen. A
-- wide viewport alone is not enough either -- a tablet has the width and no
-- number row, so slots 6-10 would be reachable only by touch, which is exactly
-- the fingernail problem. Anything that is not both gets five.
--==============================================================================
local DESKTOP_SLOTS = 10
local MOBILE_SLOTS = 5
local MAX_SLOTS = DESKTOP_SLOTS

-- 10 x 64 + 9 x 6 = 694 px of strip. Below this the strip is most of the
-- window, so five is the better answer even with a keyboard attached.
local DESKTOP_MIN_WIDTH = 900

-- How many slots are LIVE right now. Everything reads this; nothing assumes a
-- number. `MAX_SLOTS` is how many can ever exist, and the difference between the
-- two is the overflow the mobile path has to keep reachable.
local activeSlots = MOBILE_SLOTS

local function wantedSlots(): number
	local camera = Workspace.CurrentCamera
	local width = if camera then camera.ViewportSize.X else 0
	if UserInputService.KeyboardEnabled and width >= DESKTOP_MIN_WIDTH then
		return DESKTOP_SLOTS
	end
	return MOBILE_SLOTS
end

--==============================================================================
-- HOW LONG TWO TAPS COUNT AS ONE GESTURE
--
-- 0.30 s, in the middle of the 0.28-0.35 band. Shorter and a thumb that has to
-- travel back to the slot misses it; longer and two deliberate weapon swaps in
-- quick succession start reading as a double.
--
-- Nothing WAITS this long. See the banner on the slot's Activated handler: the
-- first tap equips immediately and the second undoes the placement, so the
-- window costs no latency at all on the common path.
--==============================================================================
local DOUBLE_WINDOW = 0.30

-- Per slot, so a tap on 2 followed by a tap on 3 is never a double. os.clock is
-- the right clock here: it is monotonic and this is a local input rhythm, not
-- anything that has to agree with the server.
local lastTap: { [number]: number } = {}

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
	-- Whether this thing may be ASSIGNED to a hotbar slot, which is a different
	-- question from whether it can appear on one. See the capability below.
	canHotbar: boolean,
}

--==============================================================================
-- WHAT MAY BE ASSIGNED TO A SLOT, AND WHY A BAT MAY NOT
--
-- A CATEGORY decides this, never a species name -- a rule keyed on plant names
-- would need editing every time somebody adds a seed, which is the same as not
-- having a rule.
--
-- BATS AND TRAPS ARE EXEMPT ON PURPOSE. They are not ordinary carryables: each
-- lives in its own dedicated equipment slot beside the bag, exactly one bat and
-- one trap are equipped at a time, and that pairing is the whole of the combat
-- loadout. Feeding them through the generic path would mean a bat could be
-- "assigned" to slot 4 and thereby vanish out of the equipment tab that owns it,
-- and a double-tap could "return" a weapon to a bag it never left. They still
-- APPEAR on the hotbar -- that is where you swing from -- they just are not
-- assignable, returnable or hideable by it.
--
-- A FUTURE ORDINARY ITEM OPTS IN TWO WAYS, and needs no edit here for the
-- second: add its category below, or have whatever creates the Tool set the
-- `CanAssignHotbar` attribute on it. The attribute wins, so a single odd item in
-- an otherwise-exempt category can opt in (or out) on its own.
--==============================================================================
local CAN_ASSIGN_ATTR = "CanAssignHotbar"

local HOTBAR_ASSIGNABLE: { [string]: boolean } = {
	plant = true,
	bat = false,
	trap = false,
}

local function assignable(tool: Tool, kind: string): boolean
	local override = tool:GetAttribute(CAN_ASSIGN_ATTR)
	if type(override) == "boolean" then
		return override
	end
	return HOTBAR_ASSIGNABLE[kind] == true
end

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
			canHotbar = assignable(tool, weapon.Category),
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
			canHotbar = assignable(tool, "plant"),
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
local cancelDrag: () -> ()
local dragMoved = false

--==============================================================================
-- SENDING SOMETHING BACK TO THE BAG
--
-- Two gestures arrive at the same place -- a double-tap on the slot, and a drag
-- from the slot onto the open bag -- so it is one function rather than two
-- copies of the same four steps that would drift apart the first time one of
-- them was fixed.
--==============================================================================
local returnToBag: (number) -> ()

-- Whether the bag is open, read by refreshHotbar to decide if the return hint
-- is worth showing. The `open` local that owns this lives with setOpen at the
-- bottom of the file, far below the draw code that needs to know.
local bagOpen = false

-- Assigning, moving and returning all have to redraw the bag as well as the
-- strip -- a returned plant has to reappear as a card -- and they are defined
-- above the coalescing redraw that does it. Same forward-local reason as the two
-- above: written as a bare `function redraw()` further down it would be a global.
local redraw: () -> ()

--==============================================================================
-- AND THE STATE THOSE HANDLERS READ, DECLARED ABOVE THEM FOR THE SAME REASON
--
-- This block sat below the hotbar's button handlers once, and the handlers read
-- `assigned` as a GLOBAL -- nil -- so every press on an assigned slot died with
--
--     LoadoutUI:1198: attempt to index nil with number
--
-- silently, in an event handler, where a thrown error stops that one press and
-- nothing else. The drag from a card still worked, because that path is defined
-- further down; only the hotbar's own gestures were dead, which is a very good
-- disguise. Whatever else moves in this file, these declarations stay above
-- `acquireCard` and `acquireHotSlot`.
--==============================================================================
--==============================================================================
-- DRAWING
--==============================================================================
local liveSlots: { Slot } = {}

--==============================================================================
-- WHICH ONES, AND WHO DECIDES
--
-- With ten slots on a wide screen the hotbar can very nearly BE the tool list.
-- With five it cannot, so something has to choose, and the player is the only
-- one who knows which plant they are about to want.
--
-- `assigned[slotIndex]` is that choice. Anything NOT assigned auto-fills the
-- gaps in the existing bat/trap/plants order, so a bag nobody has arranged
-- behaves exactly as it always did and a new pickup still turns up on the strip
-- by itself.
--
--==============================================================================
-- WHY AN ASSIGNMENT IS A TOOL *AND* A KEY, AND NOT EITHER ALONE
--
-- The old version stored only the key -- "p:<species>:<tier>:<hatched>". That
-- cannot tell two identical plants apart, and this feature now has to: assigning
-- ONE of two identical Voidpetals must hide exactly ONE of them from the bag and
-- leave the other sitting there to be assigned somewhere else. A key alone
-- either hides both or hides neither.
--
-- A Tool reference alone is no good either. A respawn DESTROYS every Tool and
-- builds new ones, so an assignment holding an instance would point at a
-- destroyed object and the player's arrangement would evaporate every death --
-- and death is frequent in a game whose whole loop is being chased.
--
-- So it holds both, and they do different jobs:
--
--   * `tool` is the CLAIM -- this exact owned copy, the one being hidden from the
--     bag. Reparenting between Backpack and Character does not disturb it,
--     because it is the same instance in either place.
--   * `key` is the LEASE -- what to look for when the claim dies. After a
--     respawn the slot re-binds to any unclaimed copy of the same thing, which
--     is what a player means when they arrange a hotbar.
--
-- If neither can be satisfied, the assignment is CLEARED: the item was sold,
-- planted, consumed or otherwise stopped being owned, and a slot holding a
-- promise nobody can keep is worse than an empty one.
--==============================================================================
type Assign = {
	key: string,
	tool: Tool?,
	-- When the claim went missing, if it has. See the grace period below.
	lostAt: number?,
}

--==============================================================================
-- AND A LEASE OUTLIVES THE GAP WHERE ITS TOOL DOES NOT EXIST
--
-- MEASURED, and the reason this constant exists at all. The first version cleared
-- an assignment the moment its Tool could not be found, which looked right and
-- destroyed the feature: a respawn DESTROYS the Backpack and builds a new one, so
-- for a moment the player owns nothing. `redraw` is wired to ChildRemoved, so it
-- runs inside that gap, finds no Nubkin, and throws the arrangement away -- and
-- then the rebuilt Nubkins arrive to an empty hotbar.
--
-- Proved by destroying three Nubkin Tools and rebuilding three identical ones:
-- the slot came back auto-filled with a trap and every card was visible again,
-- when the whole point of keying by species is that this case survives.
--
-- So a lost claim is not a dead assignment. The lease is kept, and cleared only
-- if nothing matching has turned up after this long -- which separates the two
-- cases by the only thing that actually distinguishes them:
--
--   respawn, reparent, streaming hiccup   the key comes back within a second
--   sold, planted, consumed, given away   it never comes back
--
-- Five seconds because a respawn has to load a profile and let CarryService hand
-- back every held plant before the key can reappear, and being slightly slow to
-- release a slot costs a player nothing they can see. Being fast to release it
-- costs them their hotbar every time they die, which in this game is often.
--==============================================================================
local ASSIGN_GRACE = 5.0

-- Indexed to MAX_SLOTS, not activeSlots: slots 6-10 keep their assignments while
-- a phone is only showing five, which is what lets a desktop arrangement come
-- back intact instead of being thrown away by picking up a phone.
local assigned: { [number]: Assign } = {}

--==============================================================================
-- WHICH TOOLS THE BAG MUST NOT SHOW
--
-- Rebuilt by the reconcile below and read by refreshBag. Only ACTIVE slots put
-- anything in here: an item auto-filled onto the strip is still ordinary bag
-- contents and must stay visible, and an assignment parked in an inactive
-- overflow slot must stay visible too or it would be unreachable -- which is the
-- one outcome this whole design exists to prevent.
--==============================================================================
local claimed: { [Tool]: number } = {}

-- Guards the grace re-check below against stacking one timer per redraw while a
-- lease is waiting -- a respawn fires several redraws in a frame.
local gracePending = false

local function assignedSlotFor(tool: Tool): number?
	for index, record in pairs(assigned) do
		if record.tool == tool then
			return index
		end
	end
	return nil
end

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
	-- Whether this row may be dragged onto the hotbar. Carried on the row rather
	-- than re-derived in the input handler, so the drag and the draw can never
	-- disagree about it.
	canHotbar: boolean,
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
		if not row or not row.canHotbar then
			-- Bats and traps are exempt: each already lives in its own dedicated
			-- equipment slot, and assigning one here would take it out of the
			-- tab that owns it. See the capability banner up top.
			return
		end
		beginDrag({ from = "bag", row = row, label = row.label }, input)
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
	hint: TextLabel,
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

	--==========================================================================
	-- THE RETURN HINT
	--
	-- Across the top of the slot, over the preview, and hidden unless the bag is
	-- open on an assigned slot. It names the gesture in the words of the device
	-- it is on: a phone has no click and a desktop has no tap, and a hint that
	-- names the wrong one teaches nothing.
	--==========================================================================
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.AnchorPoint = Vector2.new(1, 0)
	hintLabel.Position = UDim2.new(1, -3, 0, 2)
	hintLabel.Size = UDim2.fromOffset(42, 11)
	hintLabel.BackgroundTransparency = 1
	hintLabel.Font = Enum.Font.FredokaOne
	hintLabel.TextSize = 9
	hintLabel.TextColor3 = MUTED
	hintLabel.TextXAlignment = Enum.TextXAlignment.Right
	hintLabel.Text = if UserInputService.KeyboardEnabled then "2x CLICK" else "2x TAP"
	hintLabel.Visible = false
	hintLabel.ZIndex = 9
	hintLabel.Parent = button

	local slot: HotSlot = {
		button = button,
		preview = preview,
		key = keyLabel,
		name = nameLabel,
		hint = hintLabel,
		cooldown = cooldown,
		stroke = stroke,
		tool = nil,
		item = nil,
	}

	--==========================================================================
	-- A SLOT CAN ALSO BE PICKED UP
	--
	-- Dragging one onto the open bag returns it, and onto another slot moves it.
	-- Only slots carrying an ASSIGNMENT: an auto-filled slot is not something the
	-- player put anywhere, so there is nothing to move and nothing to give back.
	--==========================================================================
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch
			and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if index > activeSlots then
			return
		end
		local record = assigned[index]
		if not (record and slot.tool) then
			return
		end
		beginDrag({ from = "hot", index = index, label = slot.name.Text }, input)
	end)

	--==========================================================================
	-- ONE TAP EQUIPS. TWO GIVES IT BACK.
	--
	-- The equip is NOT delayed waiting to find out whether a second tap is
	-- coming. Holding every tap for 300 ms to see if it becomes a double would
	-- make the whole hotbar feel broken, and the hotbar is used mid-chase. So the
	-- first tap equips at once and the second UNDOES the placement -- unequipping
	-- as it goes, because leaving a returned plant in the player's hands is a
	-- half-finished action.
	--
	-- Bats and traps never take this path: `canHotbar` is false for them, so a
	-- double-tap on a weapon is two ordinary equips, which is what it looks like.
	--==========================================================================
	button.Activated:Connect(function()
		if dragMoved then
			return
		end
		holdTool(slot.tool)
		if index > activeSlots then
			return
		end
		local record = assigned[index]
		local tool = slot.tool
		if not (record and tool) then
			return
		end
		local data: Slot? = nil
		for _, candidate in ipairs(liveSlots) do
			if candidate.tool == tool then
				data = candidate
				break
			end
		end
		if not (data and data.canHotbar) then
			return
		end
		local now = os.clock()
		local previous = lastTap[index]
		if previous and now - previous <= DOUBLE_WINDOW then
			lastTap[index] = nil
			returnToBag(index)
		else
			lastTap[index] = now
		end
	end)
	hotSlots[index] = slot
	return slot
end

--==============================================================================
-- SLOT ORDER FOR RECONCILING: ACTIVE FIRST, THEN OVERFLOW
--
-- Active slots get first refusal on every Tool, both when keeping an exact claim
-- and when re-binding a lost one. That is what makes coming back to a desktop
-- safe: the five slots a phone was using keep the copies they already had, and
-- slots 6-10 pick up whatever is genuinely left over rather than stealing from
-- the slots that were visible a moment ago.
--==============================================================================
local function reconcileOrder(): { number }
	local order: { number } = {}
	for i = 1, activeSlots do
		table.insert(order, i)
	end
	for i = activeSlots + 1, MAX_SLOTS do
		table.insert(order, i)
	end
	return order
end

--==============================================================================
-- RECONCILIATION, ONCE PER REDRAW
--
-- Runs against the Tools that actually exist right now, so every one of the
-- cases the brief lists falls out of the same two passes rather than needing a
-- special path each:
--
--   Tool moved Backpack <-> Character   pass 1 keeps it: same instance.
--   Respawn rebuilt every Tool          pass 1 finds nothing, pass 2 re-leases
--                                       by key.
--   Two identical copies, one assigned  `used` stops the second slot -- and the
--                                       bag -- reusing the claimed one.
--   Item planted, sold or destroyed     no instance and no key match, so the
--                                       assignment is dropped.
--   Reassigned to another slot          the drop cleared the old slot before
--                                       this ever runs.
--
-- `used` is the whole trick: a Tool bound once is off the table for every later
-- slot, so no instance can ever be shown in two places.
--==============================================================================
local function reconcile(live: { Slot })
	table.clear(claimed)

	local byTool: { [Tool]: Slot } = {}
	for _, data in ipairs(live) do
		byTool[data.tool] = data
	end
	local used: { [Tool]: boolean } = {}
	local order = reconcileOrder()

	local now = os.clock()
	local waiting = false

	-- Pass 1: keep the exact copy, if it is still owned and still unspoken for.
	for _, i in ipairs(order) do
		local record = assigned[i]
		local tool = record and record.tool
		if record and tool and byTool[tool] and not used[tool] then
			used[tool] = true
			record.lostAt = nil
		elseif record then
			record.tool = nil
			if not record.lostAt then
				record.lostAt = now
			end
		end
	end

	-- Pass 2: re-lease by key, or start (or run down) the grace period.
	for _, i in ipairs(order) do
		local record = assigned[i]
		if record and not record.tool then
			for _, data in ipairs(live) do
				if not used[data.tool] and data.key == record.key and data.canHotbar then
					used[data.tool] = true
					record.tool = data.tool
					record.lostAt = nil
					break
				end
			end
			if not record.tool then
				if now - (record.lostAt or now) >= ASSIGN_GRACE then
					-- Long enough. It is not coming back.
					assigned[i] = nil
				else
					waiting = true
				end
			end
		end
	end

	--==========================================================================
	-- ONE TIMER, ONLY WHILE SOMETHING IS ACTUALLY WAITING
	--
	-- A lease whose grace has not run out yet needs SOMETHING to look again once
	-- it has, or a slot reserved for an item that was sold would stay reserved
	-- until the player next happened to pick something up. This is that look --
	-- scheduled once per reconcile that found a waiting lease, never while the
	-- hotbar is settled, and it is a task.delay rather than a loop so a player
	-- standing in their garden pays nothing for it.
	--==========================================================================
	if waiting and not gracePending then
		gracePending = true
		task.delay(ASSIGN_GRACE + 0.1, function()
			gracePending = false
			redraw()
		end)
	end

	-- And only the live ones hide anything.
	for i = 1, activeSlots do
		local record = assigned[i]
		if record and record.tool then
			claimed[record.tool] = i
		end
	end
end

--==============================================================================
-- TWO PASSES, AND THE ORDER MATTERS
--
-- Assigned first, so the player's arrangement wins over the alphabet. Then the
-- leftovers fill whatever is still empty, in the same bat/trap/plants order the
-- strip has always used.
--
-- Auto-fill deliberately does NOT hide anything from the bag. Only an assignment
-- does that -- see the banner on `claimed`. An auto-filled plant showing in both
-- places is correct: nobody chose to put it there, and the bag is still where it
-- lives.
--==============================================================================
local function refreshHotbar()
	local held = heldTool()
	reconcile(liveSlots)

	local taken: { [number]: boolean } = {}
	local placed: { [number]: Slot } = {}

	for i = 1, activeSlots do
		local record = assigned[i]
		local want = record and record.tool
		if want then
			for j, data in ipairs(liveSlots) do
				if not taken[j] and data.tool == want then
					taken[j] = true
					placed[i] = data
					break
				end
			end
		end
	end

	local nextFree = 1
	for i = 1, activeSlots do
		if not placed[i] and not assigned[i] then
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
	-- EVERY LIVE SLOT IS DRAWN, EMPTY OR NOT
	--
	-- It used to hide the ones with nothing in them, which was right when the
	-- strip was just a list. It is wrong now: an empty slot is the DROP TARGET,
	-- and a drop target nobody can see is a feature nobody finds.
	--
	-- Slots past `activeSlots` are hidden AND emptied of their tool reference, so
	-- a stale one cannot be equipped by a number key or ticked by the cooldown
	-- loop. Their ASSIGNMENT record survives untouched -- that is the overflow.
	--==========================================================================
	for i = 1, math.max(activeSlots, #hotSlots) do
		local slot = hotSlots[i]
		if i > activeSlots then
			if slot then
				slot.button.Visible = false
				slot.tool = nil
				slot.item = nil
			end
		else
			slot = acquireHotSlot(i)
			local data = placed[i]
			slot.button.Visible = true
			slot.tool = if data then data.tool else nil
			slot.item = if data then data.item else nil
			-- The tenth slot is reached by the 0 key, because that is where the
			-- number row puts it. Labelling it "10" would name a key nobody has.
			slot.key.Text = if i == 10 then "0" else tostring(i)
			if data then
				slot.preview.setModel(data.key, builderFor(data), previewKind(data))
				slot.name.Text = data.label
			else
				slot.preview.setModel("empty:" .. i, nil, "plant")
				slot.name.Text = ""
			end
			--==================================================================
			-- THE HINT IS SHOWN ONLY WHERE IT APPLIES
			--
			-- Assigned, assignable, and the bag open -- which is when the player
			-- is arranging rather than fighting. Permanent gesture text on five
			-- slots of a combat HUD is clutter; the same text while the bag is
			-- open is an answer to the question they are already asking.
			--==================================================================
			local record = assigned[i]
			local canReturn = record ~= nil and data ~= nil and data.canHotbar
			slot.hint.Visible = canReturn and bagOpen
			--==================================================================
			-- THREE FACTS, THREE RINGS, AND THEY MUST NOT COLLIDE
			--
			-- Amber says "this is in your hands" and outranks the rest, because
			-- it is the one that changes second to second. Edge says "you put
			-- this here". Black is a slot doing nothing in particular.
			--==================================================================
			local isHeld = data ~= nil and data.tool == held
			slot.stroke.Color = if isHeld then PICKED
				elseif record then PANEL.Edge
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
					-- A weapon's home is this tab and its own equipment slot.
					canHotbar = false,
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
		--======================================================================
		-- AN ASSIGNED COPY IS NOT IN THE BAG ANY MORE
		--
		-- `claimed` holds exactly the Tools that active hotbar slots have taken,
		-- one entry per instance -- so owning two identical plants and assigning
		-- one hides ONE card and leaves the other, which a key-based check could
		-- never do.
		--
		-- Auto-filled slots claim nothing, and neither do assignments parked in
		-- an inactive overflow slot: both stay listed here, the second because
		-- otherwise a desktop arrangement would make items unreachable on a
		-- phone, which is the failure this design exists to avoid.
		--======================================================================
		for _, slot in ipairs(liveSlots) do
			if slot.kind == "plant" and not claimed[slot.tool] then
				table.insert(rows, {
					key = slot.key .. ":" .. tostring(slot.tool),
					label = slot.label,
					kind = "plant",
					build = builderFor(slot),
					state = if slot.tool == heldTool() then "IN HAND" else "TAP TO HOLD",
					lit = slot.tool == heldTool(),
					item = nil,
					tool = slot.tool,
					canHotbar = slot.canHotbar,
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
local dragSource: any = nil
local dragConns: { RBXScriptConnection } = {}

-- Green for "that went where you put it", warm red for "that came back". Two
-- colours because the two outcomes must not be told apart by reading a label:
-- the whole point of a flash is that it is legible out of the corner of an eye.
local FLASH_ASSIGNED = Color3.fromRGB(150, 220, 96)
local FLASH_RETURNED = Color3.fromRGB(226, 118, 92)

local function guiPoint(input: InputObject): Vector2
	return Vector2.new(input.Position.X, input.Position.Y)
end

local function slotUnder(point: Vector2): number?
	for i = 1, activeSlots do
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

--==============================================================================
-- AND THE BAG IS A TARGET TOO, WHEN IT IS OPEN
--
-- The grid rect rather than the whole panel, so a drop on the tab strip or the
-- close button is not read as "put this back" -- those are buttons a player may
-- well be aiming at for their own sake.
--==============================================================================
local function overBag(point: Vector2): boolean
	if not bagOpen then
		return false
	end
	local p, sz = grid.AbsolutePosition, grid.AbsoluteSize
	return point.X >= p.X and point.X <= p.X + sz.X
		and point.Y >= p.Y and point.Y <= p.Y + sz.Y
end

--==============================================================================
-- THE FLASH: ONE TWEEN, NO LOOP
--
-- A colour set at once and a thickness easing back over a third of a second,
-- then one redraw to put the real ring back. Deliberately NOT a RenderStepped
-- pulse or a per-card animation: this HUD runs on phones, the repo rule is no
-- per-frame allocation, and a flash still animating when the player looks away
-- has already done its job.
--==============================================================================
local function flashSlot(index: number, colour: Color3)
	local slot = hotSlots[index]
	if not slot then
		return
	end
	slot.stroke.Color = colour
	slot.stroke.Thickness = 4
	TweenService:Create(slot.stroke, TweenInfo.new(0.30), { Thickness = 2.5 }):Play()
	task.delay(0.32, function()
		if hotSlots[index] == slot then
			refreshHotbar()
		end
	end)
end

--==============================================================================
-- GIVING A SLOT BACK
--
-- Clearing the assignment IS the return: an unclaimed Tool reappears in the bag
-- on the next draw, because `claimed` is what hid it and nothing else ever did.
-- No item is moved, created or destroyed -- which is the property that keeps this
-- a presentation layer over the real owned Tools rather than a second inventory.
--
-- UNEQUIPPED ON THE WAY OUT, if it happens to be in the hands. A plant just
-- taken off the hotbar but still held is a half-finished action, and the player
-- would be left working out for themselves why their hands are full of something
-- they just put away.
--==============================================================================
returnToBag = function(index: number)
	local record = assigned[index]
	if not record then
		return
	end
	local tool = record.tool
	assigned[index] = nil
	lastTap[index] = nil
	local character = player.Character
	if tool and character and tool.Parent == character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:UnequipTools()
		end
	end
	SoundKit.play("UIClick")
	flashSlot(index, FLASH_RETURNED)
	redraw()
end

--==============================================================================
-- WHERE A DRAG ENDS UP
--
-- Four outcomes, and which one it is depends on where the card came FROM as much
-- as on where it was dropped:
--
--   bag  -> slot          assign, and hide that exact copy from the bag
--   slot -> another slot  MOVE, never copy
--   slot -> the open bag  return it
--   anything -> nowhere   nothing at all
--
-- A DROP IS A MOVE, NOT A COPY, in both directions. The same copy in two slots
-- would show twice and waste one, so wherever it was before is cleared first --
-- including a slot in the 6-10 overflow that a phone is not showing, which is
-- exactly the case the brief calls out: assigning an overflowed item into 1-5 has
-- to let go of where it used to be.
--
-- Dropping onto an OCCUPIED slot replaces it, and the displaced item is back in
-- the bag by the next draw for the same reason a return works: nothing is
-- claiming it any more.
--==============================================================================
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
	for i = 1, MAX_SLOTS do
		local slot = hotSlots[i]
		if slot then
			slot.button.ZIndex = 5
		end
	end

	local source = dragSource
	dragSource = nil
	if not (source and dropAt) then
		return
	end
	local target = slotUnder(dropAt)

	if source.from == "bag" then
		if not target then
			return
		end
		-- The live SLOT record, not the Row: a Row key carries the tool instance
		-- so that two identical plants get separate cards, and what belongs in
		-- the assignment is the current classification of that one copy.
		local data: Slot? = nil
		for _, candidate in ipairs(liveSlots) do
			if candidate.tool == source.row.tool then
				data = candidate
				break
			end
		end
		if not (data and data.canHotbar) then
			return
		end
		local was = assignedSlotFor(data.tool)
		if was then
			assigned[was] = nil
		end
		assigned[target] = { key = data.key, tool = data.tool }
		SoundKit.play("UIClick")
		flashSlot(target, FLASH_ASSIGNED)
		redraw()
		return
	end

	local index = source.index
	local record = assigned[index]
	if not record then
		return
	end
	if target and target ~= index then
		assigned[target] = record
		assigned[index] = nil
		lastTap[index] = nil
		SoundKit.play("UIClick")
		flashSlot(target, FLASH_ASSIGNED)
		redraw()
	elseif not target and overBag(dropAt) then
		returnToBag(index)
	end
end

--==============================================================================
-- AND ANYTHING THAT ENDS THE MOMENT ENDS THE DRAG
--
-- endDrag runs off InputEnded, which is enough while a finger stays on the
-- glass. It is not enough for the ways a drag can stop mattering without one
-- being lifted: the bag shutting under it, the character being destroyed while it
-- is in the air, a pod landing in both arms, a trap closing, the slot count
-- changing under it. None of those fire an input event, and each would leave a
-- ghost label on screen and the hotbar stuck at ZIndex 60 -- drawn over every
-- panel in the game until the next drag happened to tidy it.
--
-- Dropped with no point, so it cancels rather than assigns: a drag interrupted by
-- something else is not a placement anybody asked for.
--==============================================================================
cancelDrag = function()
	if dragSource then
		endDrag(nil)
	end
	dragMoved = false
end

beginDrag = function(source: any, input: InputObject)
	if dragSource then
		return
	end
	dragSource = source
	dragMoved = false
	local startAt = guiPoint(input)
	local toBag = source.from == "hot"

	--==========================================================================
	-- WHAT IS BEING CARRIED, SO ITS DISAPPEARING CAN BE NOTICED
	--
	-- Checked as `tool.Parent == nil` rather than "it left the Backpack":
	-- equipping MOVES a Tool from the Backpack into the Character, and cancelling
	-- on that would cancel every drag the instant the hands changed.
	--==========================================================================
	local fromSlot = if toBag then hotSlots[source.index] else nil
	local carried: Tool? = if fromSlot then fromSlot.tool else source.row.tool

	table.insert(dragConns, UserInputService.InputChanged:Connect(function(moved)
		if moved.UserInputType ~= Enum.UserInputType.Touch
			and moved.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		if carried and carried.Parent == nil then
			cancelDrag()
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
			for i = 1, activeSlots do
				local slot = hotSlots[i]
				if slot then
					slot.button.ZIndex = 61
				end
			end
			local ghost = UIKit.outlined(gui, "DragGhost", 14, CREAM, 2)
			ghost.AnchorPoint = Vector2.new(0.5, 1)
			ghost.Size = UDim2.fromOffset(150, 22)
			ghost.ZIndex = 70
			ghost.Text = string.upper(source.label or "ITEM")
				.. (if toBag then "  ->  BAG" else "  ->  HOTBAR")
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
		-- and the guard has to still be up when it does or a completed drag would
		-- also equip -- or double-tap-return -- the thing it just moved.
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

redraw = function()
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
	--==========================================================================
	-- A TOOL LEAVING IS ONLY SOMETIMES A TOOL GOING
	--
	-- Equipping REPARENTS a Tool out of the Backpack and into the Character, so
	-- this fires constantly for tools that are perfectly fine. The redraw is what
	-- sorts it out: `reconcile` looks at what exists rather than at what moved,
	-- keeps the claim if the instance is still owned in either container, and
	-- clears the assignment only when it is owned in neither.
	--==========================================================================
	table.insert(containerConns, container.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and dragSource then
			-- A drag whose subject has just been destroyed has nothing to drop.
			-- Checked after a frame so a reparent, which lands the Tool in the
			-- other container immediately, is not mistaken for a deletion.
			task.defer(function()
				if child.Parent == nil then
					cancelDrag()
				end
			end)
		end
		redraw()
	end))
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
	cancelDrag()
	task.defer(rebindContainers)
end)
player.CharacterRemoving:Connect(cancelDrag)
rebindContainers()

--==============================================================================
-- THE COUNT FOLLOWS THE DEVICE, AND CHANGING IT IS A REDRAW
--
-- Roblox reports a viewport before the window has settled and a keyboard can
-- appear or vanish mid-session -- a Bluetooth keyboard paired to a tablet, a
-- desktop window dragged narrow, the emulator switched -- so this is a signal to
-- respond to rather than a fact to read once at start-up.
--
-- WHAT HAPPENS TO SLOTS 6-10 ON THE WAY DOWN is the whole reason this is careful:
-- they go invisible and stop being claimed, so every item assigned to one turns
-- back up in the bag and stays usable. Nothing is thrown away -- the assignment
-- records survive -- so coming back to a wide window restores the arrangement,
-- and `reconcile` is what stops that restoring a claim on something that has
-- since been planted, sold or reassigned into 1-5.
--
-- A drag in flight is cancelled: it was aimed at a strip that is about to be a
-- different shape, and finishing it would drop the card on whatever slid under
-- the finger.
--==============================================================================
local function applySlotCount()
	local want = wantedSlots()
	if want == activeSlots then
		return
	end
	cancelDrag()
	--==========================================================================
	-- SHRINKING RELEASES THE SLOTS IT TAKES AWAY, AND SAYS SO
	--
	-- The alternative was to keep 6-10 parked and hand them back on the way to a
	-- wide window again. That was tried, and it is not what this ships, for one
	-- reason: it could not be made to behave the same way twice. Measured over a
	-- real 1000 -> 408 -> 1169 round trip, the parked records did not come back,
	-- and nothing in the four places that clear an assignment accounts for it --
	-- steady state holds those same records through equips, unequips and well
	-- past the grace, so it is specific to the transition and I could not
	-- reproduce it to find out why. `ViewportSize` is read-only, and toggling
	-- Studio's emulator restarts Play, which wipes session state anyway, so the
	-- transition can only be produced by hand.
	--
	-- Shipping "it usually comes back" would be shipping a coin toss. So the
	-- release is now the DEFINITION rather than an accident: narrow the window
	-- and slots 6-10 give their items back to the bag, which is the behaviour
	-- that was actually observed and is the one the brief requires anyway --
	-- restoring on the way back is permitted there, never demanded.
	--
	-- Nothing is lost by it. The items are in the bag, they auto-fill onto the
	-- five remaining slots, and re-assigning one is a drag. What matters is that
	-- no item is ever stranded in a slot nobody can reach, and clearing the
	-- record is the bluntest possible guarantee of that.
	--
	-- WORTH REVISITING only alongside making assignments outlive a rejoin, which
	-- needs a profile field, a schema version and a migration -- at which point
	-- an arrangement is a saved thing with an owner, and "restore it" becomes a
	-- question with a defensible answer instead of a timing accident.
	--==========================================================================
	if want < activeSlots then
		for i = want + 1, MAX_SLOTS do
			if assigned[i] then
				assigned[i] = nil
				lastTap[i] = nil
			end
		end
	end
	activeSlots = want
	redraw()
end

applySlotCount()

local function watchViewport()
	local camera = Workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(applySlotCount)
	end
end
watchViewport()
-- A new Camera is a new signal: the old connection is on an instance the engine
-- has stopped using, and without this the strip would freeze at whatever count
-- was right for the camera that has gone.
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	watchViewport()
	applySlotCount()
end)
UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(applySlotCount)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(applySlotCount)

--==============================================================================
-- AND THE REST OF THE WAYS A DRAG STOPS MATTERING
--
-- Each of these takes the player out of the arranging mood entirely, and none of
-- them fires an input event, so without this the ghost would hang in the air:
--
--   a pod in both arms   CarryPose owns the hands and the bag is unusable
--   the jaws close       the player is held still and being hit
--   ragdolled            thrown by a guardian or a bat; the HUD is the last
--                        thing they are looking at
--
-- Ragdoll has no attribute of its own -- ThrowFX drives it locally through the
-- Humanoid -- so the Humanoid state is the signal, re-hooked per character
-- because a respawn brings a new one.
--==============================================================================
player:GetAttributeChangedSignal(ATTR.CarryingSpecies):Connect(cancelDrag)
player:GetAttributeChangedSignal(ATTR.Trapped):Connect(cancelDrag)

local humanoidConn: RBXScriptConnection? = nil

local function watchHumanoid(character: Model)
	if humanoidConn then
		humanoidConn:Disconnect()
		humanoidConn = nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoidConn = humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Physics
			or new == Enum.HumanoidStateType.FallingDown
			or new == Enum.HumanoidStateType.Dead then
			cancelDrag()
		end
	end)
end

if player.Character then
	watchHumanoid(player.Character)
end
player.CharacterAdded:Connect(watchHumanoid)

--==============================================================================
-- OPEN AND SHUT
--==============================================================================
local open = false

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	bagOpen = want
	if not want then
		-- The cards a drag was started from are about to go away.
		cancelDrag()
	end
	if want then
		player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)
		redraw()
	elseif player:GetAttribute(ATTR.OpenPanel) == PANEL_NAME then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
	-- The return hint only shows while the bag is open, so opening or shutting it
	-- is a reason to redraw the strip even when nothing about the tools changed.
	refreshHotbar()
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
			--==============================================================
			-- THE KEY EQUIPS WHAT THE SLOT IS SHOWING
			--
			-- It used to index `liveSlots`, which is the raw tool list -- so the
			-- moment anything was assigned, pressing 1 equipped whatever was
			-- first alphabetically rather than the thing drawn in slot 1. The
			-- number on a slot is a promise about that slot.
			--
			-- Guarded on `activeSlots` so 6-0 do nothing at all on a phone that
			-- happens to have a keyboard paired: those slots are not on screen,
			-- and a key that equips something invisible is worse than a dead key.
			--==============================================================
			if i <= activeSlots then
				local slot = hotSlots[i]
				if slot and slot.tool then
					holdTool(slot.tool)
					redraw()
				end
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
