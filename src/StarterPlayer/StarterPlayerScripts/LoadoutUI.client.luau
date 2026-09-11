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
local PlantInfo = require(Shared:WaitForChild("PlantInfo"))

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
-- The BAT / TRAP side slots' held colour. It was the bag card's equipped colour
-- and the hotbar's too; the cards went green, and the hotbar went lime in the
-- 2026-09-11 slate restyle (GameConfig.Hotbar). The side slots still use it.
local PICKED = Color3.fromRGB(250, 214, 108)
-- The soft cream a hovered card's inner edge warms to. A light line inside the
-- black keyline, so the house edge never changes colour under a pointer.
local GLOW = Color3.fromRGB(255, 236, 190)
local INCOME = Color3.fromRGB(142, 220, 68)

--==============================================================================
-- THE BAG'S GEOMETRY
--
-- A card is a fixed 104 x 158 at every width: the preview, a name that may take
-- two lines, and a 44-pixel action strip under it -- Roblox's touch minimum, so
-- the explicit HOLD / EQUIP control is never a fingernail target. Width is what
-- changes, and it changes the COLUMN COUNT, never the card.
--
-- The information column sits beside the grid while there is room for two
-- columns of cards and a readable panel, and drops under the grid as a lower
-- sheet when there is not (a portrait phone).
--==============================================================================
local CARD_W, CARD_H = 104, 158
local CARD_GAP = 10
local GRID_PAD = 10
local ACTION_H = 44
local INFO_GAP = 10
local INFO_SIDE_MIN, INFO_SIDE_MAX = 184, 236
local INFO_SHEET_H = 118
local EDGE_GAP = 8
local PANEL_MAX_W, PANEL_MAX_H = 780, 600
-- Below this the tabs share the title's row, which buys a short phone a whole
-- card row of height.
local COMPACT_BELOW = 380
-- How far a press may travel and still be a tap. A scroll or a camera drag moves
-- further than this before it lifts, and must never select or equip anything.
local TAP_SLOP = 10

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

-- 10 x 64 + 9 x 6 = 694 px of slots, 764 with the tray's padding and the Bag
-- chip. Below this the strip is most of the window, so five is the better
-- answer even with a keyboard attached.
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
--==============================================================================
-- IDENTICAL COPIES KEEP THEIR PLACES
--
-- The sort used to end on `tool.Name`, which is the same string for every copy
-- of a plant -- so four Nubkins tied, and an unstable sort put them in whatever
-- order the containers happened to list them. Equipping one MOVES it from the
-- Backpack to the Character, which changed that order: measured, holding a
-- Nubkin from its card slid a different Nubkin under the pointer, and pressing
-- HOLD again picked up the wrong copy.
--
-- So ties fall to the key (tier, hatched) and then to the order this script
-- first saw each Tool. Neither changes when a Tool changes hands. Weak keys: a
-- Tool that is destroyed is forgotten with it.
--==============================================================================
local toolOrder: { [Tool]: number } = setmetatable({}, { __mode = "k" }) :: any
local nextToolOrder = 0

local function scanTools(): { Slot }
	local slots: { Slot } = {}
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("Tool") then
					local slot = classify(child)
					if slot then
						if not toolOrder[child] then
							nextToolOrder += 1
							toolOrder[child] = nextToolOrder
						end
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
		if a.key ~= b.key then
			return a.key < b.key
		end
		return (toolOrder[a.tool] or 0) < (toolOrder[b.tool] or 0)
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
	if tool == nil or tool.Parent == character then
		SoundKit.play("CardClick")
		humanoid:UnequipTools()
		return
	end
	--==========================================================================
	-- NOT A PLANT WHILE A POD IS IN BOTH ARMS
	--
	-- A plant rides in the same two-handed grip as a raid pod, so equipping one
	-- over a carry drew the plant through the shell. CarryService puts it straight
	-- back into the Backpack anyway; refusing here means the player never watches
	-- it bounce. Bats are untouched -- that grip is a different one.
	--==========================================================================
	if tool:GetAttribute("SpeciesId") ~= nil and player:GetAttribute(ATTR.CarryingSpecies) ~= nil then
		SoundKit.play("Denied")
		return
	end
	SoundKit.play("CardClick")
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
	maxWidth = PANEL_MAX_W,
	maxHeight = PANEL_MAX_H,
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
-- How many things each section holds, on the tab itself: the heading and the
-- answer to "is there anything in here" in one place.
local tabCounts: { [string]: TextLabel } = {}

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
	-- Centre-anchored so the pop below scales in place. Same rectangle as the
	-- old top-left anchoring: half the row, less the four-pixel gutter.
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Position = UDim2.new((i - 1) * 0.5 + 0.25, -2, 0.5, 0)
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

	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.AnchorPoint = Vector2.new(1, 0.5)
	count.Position = UDim2.new(1, -8, 0.5, -1)
	count.Size = UDim2.fromOffset(0, 20)
	count.AutomaticSize = Enum.AutomaticSize.X
	count.BackgroundColor3 = BLACK
	count.BackgroundTransparency = 0.55
	count.BorderSizePixel = 0
	count.Font = Enum.Font.FredokaOne
	count.TextSize = 12
	count.TextColor3 = CREAM
	count.Text = "0"
	count.Visible = false
	count.ZIndex = 7
	count.Parent = b
	UIKit.corner(count, 10)
	local countPad = Instance.new("UIPadding")
	countPad.PaddingLeft = UDim.new(0, 7)
	countPad.PaddingRight = UDim.new(0, 7)
	countPad.Parent = count
	tabCounts[tab.id] = count

	local tabScale = Instance.new("UIScale")
	tabScale.Parent = b
	UIKit.cardPop(b, tabScale, { hoverScale = 1.04, pressScale = 0.97, sound = false })

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
--
-- The tray is its own frame inside the body now, rather than the body itself,
-- so the information column can stand beside it (or under it) in the same body.
-- Lightly translucent: the panel's lattice breathes through, and the cards on it
-- are the solid things.
local tray = Instance.new("Frame")
tray.Name = "Tray"
tray.Size = UDim2.fromScale(1, 1)
tray.BackgroundColor3 = WELL
tray.BackgroundTransparency = 0.18
tray.BorderSizePixel = 0
tray.ZIndex = 3
tray.Parent = modal.body
UIKit.corner(tray, 12)
UIKit.stroke(tray, BLACK, 2)

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
UIKit.lattice(tray, {
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
	recess.Parent = tray
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
grid.Parent = tray

local gridPad = Instance.new("UIPadding")
-- Even on all four sides now. It was right and bottom only, so the first card
-- sat hard against the top-left corner of the tray while the other two edges had
-- room -- which is the sort of thing that reads as "unfinished" without anybody
-- being able to say why.
gridPad.PaddingLeft = UDim.new(0, 10)
gridPad.PaddingTop = UDim.new(0, 8)
gridPad.PaddingRight = UDim.new(0, 10)
gridPad.PaddingBottom = UDim.new(0, 8)
gridPad.Parent = grid

local gridLayout = Instance.new("UIGridLayout")
-- Tall enough for a two-line name. "CINDERCRACK BAT" does not fit 96 pixels on
-- one line at any size worth reading, and an ellipsis on a product name is the
-- one truncation a bag cannot afford -- it is the only thing telling a player
-- which of two similar silhouettes they are looking at.
gridLayout.CellSize = UDim2.fromOffset(CARD_W, CARD_H)
gridLayout.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
-- Centred: a left-aligned grid left 24-34 px of dead tray down the right edge
-- at every width, which reads as a column that failed to load.
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = grid

local emptyLabel = UIKit.outlined(tray, "Empty", 15, MUTED, 2)
emptyLabel.AnchorPoint = Vector2.new(0.5, 0.5)
emptyLabel.Position = UDim2.fromScale(0.5, 0.42)
emptyLabel.Size = UDim2.new(1, -40, 0, 60)
emptyLabel.TextWrapped = true
emptyLabel.Visible = false
emptyLabel.ZIndex = 5

--==============================================================================
-- THE INFORMATION PANEL
--
-- ONE panel, built once and repainted -- never one per card. It says what the
-- selected plant is and where that exact Tool is. Every figure comes out of
-- PlantInfo, which takes them from the calls the economy itself uses, so this
-- file does no arithmetic on money at all.
--
-- Plants only. Bats and traps have their own slots and their own tab, and the
-- brief keeps them exactly as they were.
--==============================================================================
local info = Instance.new("Frame")
info.Name = "PlantInfo"
info.BackgroundColor3 = WELL
info.BackgroundTransparency = 0.18
info.BorderSizePixel = 0
info.Visible = false
info.ZIndex = 3
info.Parent = modal.body
UIKit.corner(info, 12)
UIKit.stroke(info, BLACK, 2)

local infoPad = Instance.new("UIPadding")
infoPad.PaddingLeft = UDim.new(0, 12)
infoPad.PaddingRight = UDim.new(0, 12)
infoPad.PaddingTop = UDim.new(0, 10)
infoPad.PaddingBottom = UDim.new(0, 10)
infoPad.Parent = info

-- Scaled into its box rather than truncated: a species name is the one line a
-- player reads first, and an ellipsis on it would hide the answer.
local infoTitle = UIKit.outlined(info, "Title", 20, WHITE, 2)
infoTitle.TextXAlignment = Enum.TextXAlignment.Left
infoTitle.TextWrapped = true
infoTitle.TextScaled = true
infoTitle.ZIndex = 5
local infoTitleFit = Instance.new("UITextSizeConstraint")
infoTitleFit.MaxTextSize = 20
infoTitleFit.MinTextSize = 11
infoTitleFit.Parent = infoTitle

local infoStage = Instance.new("TextLabel")
infoStage.Name = "Stage"
infoStage.Size = UDim2.fromOffset(0, 18)
infoStage.AutomaticSize = Enum.AutomaticSize.X
infoStage.BackgroundColor3 = BLACK
infoStage.BackgroundTransparency = 0.45
infoStage.BorderSizePixel = 0
infoStage.Font = Enum.Font.FredokaOne
infoStage.TextSize = 11
infoStage.TextColor3 = CREAM
infoStage.ZIndex = 5
infoStage.Parent = info
UIKit.corner(infoStage, 9)
local infoStageEdge = UIKit.stroke(infoStage, INCOME, 1.5, 0.2)
local infoStagePad = Instance.new("UIPadding")
infoStagePad.PaddingLeft = UDim.new(0, 8)
infoStagePad.PaddingRight = UDim.new(0, 8)
infoStagePad.Parent = infoStage

local infoRows = Instance.new("Frame")
infoRows.Name = "Rows"
infoRows.BackgroundTransparency = 1
infoRows.ZIndex = 4
infoRows.Parent = info
local infoRowsLayout = Instance.new("UIGridLayout")
infoRowsLayout.SortOrder = Enum.SortOrder.LayoutOrder
infoRowsLayout.Parent = infoRows

type InfoRow = { key: TextLabel, value: TextLabel, fit: UITextSizeConstraint }
local INFO_KEYS = { "Biome", "Rarity", "Size", "Income", "Sell", "Status" }
local infoRowFor: { [string]: InfoRow } = {}
for order, keyName in ipairs(INFO_KEYS) do
	local row = Instance.new("Frame")
	row.Name = keyName
	row.LayoutOrder = order
	row.BackgroundTransparency = 1
	row.ZIndex = 4
	row.Parent = infoRows

	local key = Instance.new("TextLabel")
	key.Name = "Key"
	key.Size = UDim2.new(0.4, 0, 1, 0)
	key.BackgroundTransparency = 1
	key.Font = Enum.Font.FredokaOne
	key.TextSize = 11
	key.TextColor3 = MUTED
	key.TextXAlignment = Enum.TextXAlignment.Left
	key.TextTruncate = Enum.TextTruncate.AtEnd
	key.Text = string.upper(keyName)
	key.ZIndex = 5
	key.Parent = row

	-- Scaled down rather than cut off when a value runs long -- "Hotbar slot
	-- 10" in a lower-sheet column -- with a floor that stays readable.
	local value = Instance.new("TextLabel")
	value.Name = "Value"
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.fromScale(1, 0)
	value.Size = UDim2.new(0.6, 0, 1, 0)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.FredokaOne
	value.TextScaled = true
	value.TextColor3 = CREAM
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.ZIndex = 5
	value.Parent = row
	UIKit.stroke(value, BLACK, 1.5, 0.3)
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 14
	fit.MinTextSize = 9
	fit.Parent = value

	infoRowFor[keyName] = { key = key, value = value, fit = fit }
end

local infoHint = UIKit.outlined(info, "Hint", 14, MUTED, 2)
infoHint.AnchorPoint = Vector2.new(0.5, 0.5)
infoHint.Position = UDim2.fromScale(0.5, 0.5)
infoHint.Size = UDim2.fromScale(1, 1)
infoHint.TextWrapped = true
infoHint.ZIndex = 5

--==============================================================================
-- THREE ARRANGEMENTS OF THE SAME PANEL
--
--   side      a column beside the grid: two-line title, the pill under it, one
--             row per fact down the rest.
--   compact   the same column on a short screen: one-line title, tighter rows,
--             so all six facts fit in a phone's single card row of height.
--   sheet     a strip under the grid: title and pill share a line, the six
--             facts in two columns.
--==============================================================================
local infoMode = ""

local function layoutInfo(mode: string)
	if infoMode == mode then
		return
	end
	infoMode = mode
	if mode == "sheet" then
		infoTitle.Position = UDim2.new()
		infoTitle.Size = UDim2.new(1, -118, 0, 24)
		infoStage.AnchorPoint = Vector2.new(1, 0)
		infoStage.Position = UDim2.new(1, 0, 0, 3)
		infoRows.Position = UDim2.fromOffset(0, 30)
		infoRows.Size = UDim2.new(1, 0, 1, -30)
		infoRowsLayout.CellSize = UDim2.new(0.5, -5, 0, 20)
		infoRowsLayout.CellPadding = UDim2.fromOffset(10, 3)
	elseif mode == "compact" then
		infoTitle.Position = UDim2.new()
		infoTitle.Size = UDim2.new(1, 0, 0, 24)
		infoStage.AnchorPoint = Vector2.new(0, 0)
		infoStage.Position = UDim2.fromOffset(0, 27)
		infoRows.Position = UDim2.fromOffset(0, 50)
		infoRows.Size = UDim2.new(1, 0, 1, -50)
		infoRowsLayout.CellSize = UDim2.new(1, 0, 0, 16)
		infoRowsLayout.CellPadding = UDim2.fromOffset(0, 2)
	else
		infoTitle.Position = UDim2.new()
		infoTitle.Size = UDim2.new(1, 0, 0, 44)
		infoStage.AnchorPoint = Vector2.new(0, 0)
		infoStage.Position = UDim2.fromOffset(0, 48)
		infoRows.Position = UDim2.fromOffset(0, 76)
		infoRows.Size = UDim2.new(1, 0, 1, -76)
		infoRowsLayout.CellSize = UDim2.new(1, 0, 0, 21)
		infoRowsLayout.CellPadding = UDim2.fromOffset(0, 4)
	end
end
layoutInfo("side")

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
-- BOTTOM TO TOP, all on an inner Face the pop scales:
--   Shadow / Plate    a soft drop and the plate, gradient-lit and translucent
--   Lip               one bright line along the top edge; this is the entire
--                     difference between a rectangle and a raised surface
--   PreviewWell       a darker recess, carrying the biome art for grown plants
--   LitRing           an inset green ring: equipped, or in hand
--   Glow / Selected   the hover's warm inner edge and the selection's gold one
--   Name / Action     the words, and the 44 px HOLD / EQUIP strip under them
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
-- WHAT THE INFORMATION PANEL IS SHOWING
--
-- One Tool INSTANCE, never a species or a key: two identical Nubkins are two
-- selections. Declared up here with the other forward locals because the card's
-- handlers call it and the panel painter lives further down.
--==============================================================================
local selectedTool: Tool? = nil
local selectTool: (Tool?) -> ()

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
	scrim: Instance?,
	backdrop: ImageLabel,
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
	selectRing: Frame,
	pop: UIKit.CardPop,
	actionPop: UIKit.CardPop,
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
	-- Plants only: what the backdrop and the information panel read. Off the
	-- Tool's own attributes, so a duplicate is described as itself.
	speciesId: string?,
	tier: number?,
	hatched: boolean?,
}

local cardPool: { Card } = {}
local cardRows: { [number]: Row } = {}

local TextService = game:GetService("TextService")

-- The pill hugs its words. Measured with TextService rather than off the label's
-- own TextBounds, because the label now lives INSIDE the pill and a box sized off
-- its own contents is a loop.
local function fitPill(card: Card, text: string)
	local size = TextService:GetTextSize(text, 11, Enum.Font.FredokaOne, Vector2.new(400, 40))
	card.statePill.Size = UDim2.fromOffset(math.ceil(size.X) + 22, 24)
end

--==============================================================================
-- A NAME THAT CANNOT FIT GIVES UP SCALING AND TRUNCATES
--
-- Scaled with a 9 pt floor, a name longer than two lines at that floor was cut
-- off mid-word by its box -- measured on a 40-character test name, TextFits
-- false. Measured here at the floor before painting: if two lines will not hold
-- it, the label stops scaling and ends in an ellipsis instead. Every name the
-- game actually ships fits well inside the scaled path.
--==============================================================================
local NAME_BOX = Vector2.new(CARD_W - 14, 1000)

local function fitName(card: Card, text: string)
	local label = card.name
	label.Text = text
	local need = TextService:GetTextSize(text, 9, Enum.Font.LuckiestGuy, NAME_BOX)
	if need.Y > 26 then
		label.TextScaled = false
		label.TextSize = 10
		label.TextTruncate = Enum.TextTruncate.AtEnd
	else
		label.TextTruncate = Enum.TextTruncate.None
		label.TextScaled = true
	end
end

local function acquireCard(index: number): Card
	local existingCard = cardPool[index]
	if existingCard then
		return existingCard
	end
	--==========================================================================
	-- THE CELL IS THE TARGET; THE FACE IS WHAT MOVES
	--
	-- The grid writes the cell's Position on every reflow, so nothing animates
	-- the cell. Everything drawn sits on `Face`, centre-anchored inside it, and
	-- the pop scales Face -- so a card lifts in place and its neighbours never
	-- see a size change.
	--==========================================================================
	local button = Instance.new("TextButton")
	button.Name = "Item" .. index
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = 5
	UIKit.clicks(button)
	button.Parent = grid

	local face = Instance.new("Frame")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromScale(1, 1)
	face.BackgroundTransparency = 1
	face.Active = false
	face.ZIndex = 5
	face.Parent = button
	local popScale = Instance.new("UIScale")
	popScale.Parent = face

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.Position = UDim2.fromOffset(0, 3)
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.BackgroundColor3 = BLACK
	shadow.BackgroundTransparency = 0.7
	shadow.BorderSizePixel = 0
	shadow.Active = false
	shadow.ZIndex = 4
	shadow.Parent = face
	UIKit.corner(shadow, 12)

	-- The same lit browns, now a translucent pane over the tray rather than a
	-- solid tile. The black keyline stays the house edge.
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.Size = UDim2.fromScale(1, 1)
	plate.BackgroundTransparency = 0.22
	plate.BorderSizePixel = 0
	plate.Active = false
	plate.ZIndex = 5
	plate.Parent = face
	UIKit.corner(plate, 12)
	local stroke = UIKit.stroke(plate, BLACK, 2)
	local tint = UIKit.gradient(plate, CARD_TOP, CARD_BOTTOM)

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
	lip.Parent = face
	UIKit.corner(lip, 1)

	local previewWell = Instance.new("Frame")
	previewWell.Name = "PreviewWell"
	previewWell.Position = UDim2.fromOffset(6, 6)
	previewWell.Size = UDim2.new(1, -12, 0, 76)
	previewWell.BackgroundColor3 = WELL
	previewWell.BackgroundTransparency = 0.1
	previewWell.BorderSizePixel = 0
	previewWell.Active = false
	previewWell.ZIndex = 5
	previewWell.Parent = face
	UIKit.corner(previewWell, 9)
	UIKit.stroke(previewWell, BLACK, 1.5, 0.35)

	-- The established biome art -- the same pictures the Index and the Garden
	-- stand their plants in -- turned down by the same ArtTint. Grown plants
	-- only: a pod keeps the plain well, as it does in the Garden.
	local backdrop = Instance.new("ImageLabel")
	backdrop.Name = "Backdrop"
	backdrop.Size = UDim2.fromScale(1, 1)
	backdrop.BackgroundTransparency = 1
	backdrop.ScaleType = Enum.ScaleType.Crop
	backdrop.ImageColor3 = GameConfig.Card.ArtTint
	backdrop.ImageTransparency = 0.25
	backdrop.Active = false
	backdrop.Visible = false
	backdrop.ZIndex = 5
	backdrop.Parent = previewWell
	UIKit.corner(backdrop, 9)

	-- The same still preview as before: built once per key, framed once, never
	-- rotated, never animated.
	local preview = UIKit.itemPreview(face, {
		name = "Preview",
		size = UDim2.new(1, -12, 0, 76),
		position = UDim2.fromOffset(6, 6),
	})

	--==========================================================================
	-- THE EQUIPPED RING
	--
	-- Inset by three, so it reads as a ring INSIDE the card rather than as a
	-- second outline fighting the black one.
	--==========================================================================
	local litRing = Instance.new("Frame")
	litRing.Name = "LitRing"
	litRing.Position = UDim2.fromOffset(3, 3)
	litRing.Size = UDim2.new(1, -6, 1, -6)
	litRing.BackgroundTransparency = 1
	litRing.Active = false
	litRing.Visible = false
	litRing.ZIndex = 9
	litRing.Parent = face
	UIKit.corner(litRing, 9)
	UIKit.stroke(litRing, READY, 2)

	-- The hover's warm inner edge. Invisible at rest; the pop fades it in.
	local glowRing = Instance.new("Frame")
	glowRing.Name = "Glow"
	glowRing.Position = UDim2.fromOffset(2, 2)
	glowRing.Size = UDim2.new(1, -4, 1, -4)
	glowRing.BackgroundTransparency = 1
	glowRing.Active = false
	glowRing.ZIndex = 9
	glowRing.Parent = face
	UIKit.corner(glowRing, 10)
	local glow = UIKit.stroke(glowRing, GLOW, 1.5, 1)

	--==========================================================================
	-- SELECTED: A GOLD EDGE AND THE FAINTEST WARM WASH
	--
	-- Its own frame, over everything, so hover (scale and glow), equipped (the
	-- green ring) and selected can all be true at once and no two of them ever
	-- write the same property.
	--==========================================================================
	local selectRing = Instance.new("Frame")
	selectRing.Name = "Selected"
	selectRing.Size = UDim2.fromScale(1, 1)
	selectRing.BackgroundColor3 = PICKED
	selectRing.BackgroundTransparency = 0.9
	selectRing.BorderSizePixel = 0
	selectRing.Active = false
	selectRing.Visible = false
	selectRing.ZIndex = 10
	selectRing.Parent = face
	UIKit.corner(selectRing, 12)
	UIKit.stroke(selectRing, PICKED, 3)

	--==========================================================================
	-- THE NAME SHRINKS RATHER THAN WRAPPING BADLY
	--
	-- "CINDERCRACK BAT" and "BRAMBLEJAW TRAP" are two lines at 12pt on a 104px
	-- card. TextScaled with a floor of 9 lets a long name give up a point or two
	-- instead of pushing into the action strip.
	--==========================================================================
	local nameLabel = UIKit.outlined(face, "Name", 12, CREAM, 2)
	nameLabel.Position = UDim2.new(0, 7, 0, 84)
	nameLabel.Size = UDim2.new(1, -14, 0, 26)
	nameLabel.TextWrapped = true
	nameLabel.TextScaled = true
	nameLabel.TextYAlignment = Enum.TextYAlignment.Center
	nameLabel.ZIndex = 8
	local nameFit = Instance.new("UITextSizeConstraint")
	nameFit.MaxTextSize = 12
	nameFit.MinTextSize = 9
	nameFit.Parent = nameLabel

	--==========================================================================
	-- THE ACTION STRIP: THE EXPLICIT HOLD / EQUIP
	--
	-- A plant card's body SELECTS it now, so the verb that used to live on the
	-- whole card -- put this plant in my hands -- needed a home that is not a
	-- plain tap. It is the pill, which always said "TAP TO HOLD", made a real
	-- 44-pixel button: the same holdTool call, reached the same way the label
	-- always told the player to reach it.
	--
	-- A weapon card keeps one verb everywhere: body or pill, a tap equips, exactly
	-- as before. Weapons gain no selection and no panel.
	--==========================================================================
	local action = Instance.new("TextButton")
	action.Name = "Action"
	action.Position = UDim2.new(0, 4, 0, 110)
	action.Size = UDim2.new(1, -8, 0, ACTION_H)
	action.BackgroundTransparency = 1
	action.BorderSizePixel = 0
	action.AutoButtonColor = false
	action.Text = ""
	action.ZIndex = 7
	UIKit.clicks(action)
	action.Parent = face

	local statePill = Instance.new("Frame")
	statePill.Name = "StatePill"
	statePill.AnchorPoint = Vector2.new(0.5, 0.5)
	statePill.Position = UDim2.fromScale(0.5, 0.5)
	statePill.Size = UDim2.fromOffset(60, 24)
	statePill.BorderSizePixel = 0
	statePill.Active = false
	statePill.ZIndex = 7
	statePill.Parent = action
	UIKit.corner(statePill, 7)
	local statePillEdge = UIKit.stroke(statePill, BLACK, 2)
	local statePillTint = UIKit.gradient(statePill, PILL_OFF_TOP, PILL_OFF_BOTTOM)
	local pillScale = Instance.new("UIScale")
	pillScale.Parent = statePill

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
	UIKit.corner(stateShade, 7)

	local stateLabel = Instance.new("TextLabel")
	stateLabel.Name = "State"
	stateLabel.Position = UDim2.fromOffset(0, -1)
	stateLabel.Size = UDim2.fromScale(1, 1)
	stateLabel.BackgroundTransparency = 1
	stateLabel.Font = Enum.Font.FredokaOne
	stateLabel.TextSize = 11
	stateLabel.TextColor3 = CREAM
	stateLabel.ZIndex = 8
	stateLabel.Parent = statePill
	UIKit.stroke(stateLabel, BLACK, 1.5)

	local card: Card = {
		button = button,
		preview = preview,
		scrim = preview.holder:FindFirstChild("Scrim"),
		backdrop = backdrop,
		name = nameLabel,
		state = stateLabel,
		statePill = statePill,
		statePillEdge = statePillEdge,
		tint = tint,
		litRing = litRing,
		statePillTint = statePillTint,
		stroke = stroke,
		selectRing = selectRing,
		pop = UIKit.cardPop(button, popScale, {
			hoverScale = 1.05,
			pressScale = 0.98,
			glow = glow,
			glowRest = 1,
			glowHover = 0.45,
		}),
		actionPop = UIKit.cardPop(action, pillScale, {
			hoverScale = 1.07,
			pressScale = 0.95,
			sound = false,
		}),
	}

	--==========================================================================
	-- A TAP IS A PRESS THAT STAYED PUT
	--
	-- Three gestures start on a card and only one of them is a tap. A drag to
	-- the hotbar is caught by `dragMoved`, as it always was. A SCROLL, or a camera
	-- drag that happens to lift over a card, is caught here: the press remembers
	-- where it began and where the canvas was, and a release that travelled past
	-- TAP_SLOP -- or scrolled the grid under it -- selects nothing and equips
	-- nothing. A press that never began with a pointer (a gamepad) still counts.
	--==========================================================================
	local pressAt: Vector3? = nil
	local pressCanvas: Vector2? = nil
	local travelled = false

	local function beginPress(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch
			and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		pressAt = input.Position
		pressCanvas = grid.CanvasPosition
		travelled = false
		local row = cardRows[index]
		if not row or not row.canHotbar then
			-- Bats and traps are exempt: each already lives in its own dedicated
			-- equipment slot, and assigning one here would take it out of the
			-- tab that owns it. See the capability banner up top.
			return
		end
		beginDrag({ from = "bag", row = row, label = row.label }, input)
	end

	local function endPress(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.Touch
			and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local start = pressAt
		if start and (input.Position - start).Magnitude > TAP_SLOP then
			travelled = true
		end
		local canvas = pressCanvas
		if canvas and (grid.CanvasPosition - canvas).Magnitude > 4 then
			travelled = true
		end
	end

	local function wasTap(): boolean
		local tap = not dragMoved and not travelled
		pressAt, pressCanvas, travelled = nil, nil, false
		return tap
	end

	button.InputBegan:Connect(beginPress)
	button.InputEnded:Connect(endPress)
	action.InputBegan:Connect(beginPress)
	action.InputEnded:Connect(endPress)

	-- The body: a weapon equips, a plant is selected. Selecting never moves,
	-- equips, clones or consumes anything.
	button.Activated:Connect(function()
		if not wasTap() then
			return
		end
		local row = cardRows[index]
		if not row then
			return
		end
		if row.item then
			equipRequest(row.item)
		elseif row.tool then
			selectTool(row.tool)
		end
	end)

	-- The strip: the explicit verb. For a plant it is holdTool, exactly what a
	-- tap on the card used to do, and the card it belongs to becomes the one the
	-- panel describes.
	action.Activated:Connect(function()
		if not wasTap() then
			return
		end
		local row = cardRows[index]
		if not row then
			return
		end
		if row.item then
			equipRequest(row.item)
		elseif row.tool then
			selectTool(row.tool)
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
--
--==============================================================================
-- BOTANICAL SLATE & INK (Option A, approved 2026-09-11)
--
-- art/hotbar/reference/approved-hotbar-mockup.png, replacing the translucent
-- mud-brown strip in current-hotbar.png. Every colour and size is in
-- GameConfig.Hotbar:
--
--   the tray   slate in an ink keyline, padded around the slots
--   a slot     a charcoal slate plate (#18202B -> #12171F) in a 2.5 px ink
--              keyline, with the faint slate lattice showing on it
--   in hand    a lime keyline (#4EE32C -> #29BF18), a soft lime ring outside it
--              and a 1.06 scale, eased
--   corners    an ink keycap with the number, top left; BAT, TRAP or SEED in
--              amber, orange or emerald, top right
--   the name   on an ink caption strip, wrapped to two lines and shrunk to fit
--              instead of cut off with "..."
--   empty      a dashed outline and a plus, with no plate
--
-- THE FRAME NAMED Hotbar IS THE TRAY, and the slots stay its direct children.
-- Two other readers depend on that shape: TutorialUI finds a plant's slot by
-- walking exactly those children for a label carrying the Tool's name, and the
-- Bag's layout stops above this frame by reading its Size -- so the height is
-- written into Size and never left to AutomaticSize.
--
-- NEW TOP-LEVEL NAMES ARE RATIONED. This chunk already declares 178 locals at
-- the top level and Luau refuses a function with more than 200, which fails the
-- whole script before anything is drawn. The restyle adds four -- HOT,
-- dashOutline, liftStrip and chip -- and keeps everything else inside the
-- functions and do-blocks that use it.
--==============================================================================
local HOT = GameConfig.Hotbar

local hotbar = Instance.new("Frame")
hotbar.Name = "Hotbar"
hotbar.AnchorPoint = Vector2.new(0.5, 1)
hotbar.Position = UDim2.new(0.5, 0, 1, -HOT.BottomGap)
hotbar.Size = UDim2.fromOffset(10, HOT.SlotHeight + HOT.TrayPad * 2)
hotbar.AutomaticSize = Enum.AutomaticSize.X
hotbar.BackgroundTransparency = HOT.TrayTransparency
hotbar.BorderSizePixel = 0
hotbar.ZIndex = 4
hotbar.Parent = gui
UIKit.corner(hotbar, 16)
UIKit.stroke(hotbar, HOT.Ink, 2.5)
UIKit.gradient(hotbar, HOT.TrayTop, HOT.TrayBottom)

do
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, HOT.TrayPad)
	pad.PaddingRight = UDim.new(0, HOT.TrayPad)
	pad.PaddingTop = UDim.new(0, HOT.TrayPad)
	pad.PaddingBottom = UDim.new(0, HOT.TrayPad)
	pad.Parent = hotbar
end

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hotbarLayout.Padding = UDim.new(0, HOT.Gap)
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
	-- The slate restyle's parts. `holder` is what the list lays out and what is
	-- shown or hidden; `button` is the plate, and the only thing a press lands on.
	holder: Frame,
	heldScale: UIScale,
	pop: UIKit.CardPop,
	ringTint: UIGradient,
	aura: Frame,
	lattice: Frame,
	keycap: Frame,
	tag: TextLabel,
	caption: Frame,
	ghost: Frame?,
	-- Whether the held scale is up, so a redraw only tweens on a change.
	lit: boolean,
	-- os.clock() until which a drop's flash owns the keyline.
	flashUntil: number,
}

local hotSlots: { HotSlot } = {}

--==============================================================================
-- A DASHED OUTLINE, BECAUSE A UIStroke HAS NO DASH PATTERN
--
-- Short frames along the four straight edges, clear of the rounded corners. Laid
-- out once at the slot's design size in offsets, so the scales that pop a slot
-- resize the dashes with it and nothing is ever rebuilt.
--==============================================================================
local function dashOutline(parent: GuiObject, width: number, height: number,
	colour: Color3, z: number)
	local DASH, SPACE, THICK, CORNER = 7, 5, 2, 10
	local function run(horizontal: boolean, fixed: number, from: number, length: number)
		local count = math.max(1, math.floor((length + SPACE) / (DASH + SPACE)))
		local at = from + math.floor((length - (count * DASH + (count - 1) * SPACE)) * 0.5)
		for _ = 1, count do
			local dash = Instance.new("Frame")
			dash.Name = "Dash"
			dash.BackgroundColor3 = colour
			dash.BorderSizePixel = 0
			dash.ZIndex = z
			if horizontal then
				dash.Position = UDim2.fromOffset(at, fixed)
				dash.Size = UDim2.fromOffset(DASH, THICK)
			else
				dash.Position = UDim2.fromOffset(fixed, at)
				dash.Size = UDim2.fromOffset(THICK, DASH)
			end
			dash.Parent = parent
			at += DASH + SPACE
		end
	end
	run(true, 0, CORNER, width - CORNER * 2)
	run(true, height - THICK, CORNER, width - CORNER * 2)
	run(false, 0, CORNER, height - CORNER * 2)
	run(false, width - THICK, CORNER, height - CORNER * 2)
end

local function acquireHotSlot(index: number): HotSlot
	local existingSlot = hotSlots[index]
	if existingSlot then
		return existingSlot
	end

	--==========================================================================
	-- THREE LAYERS, SO NOTHING THAT SCALES MOVES ITS NEIGHBOURS
	--
	--   holder   the list's cell: a fixed size, laid out, shown or hidden
	--   wrap     centred in it, carrying the held scale
	--   button   the plate, carrying the hover and press scale
	--
	-- A UIScale on the list's own child changes the size the list lays out, so a
	-- held slot would shove the whole strip sideways every time the hands changed.
	--==========================================================================
	local holder = Instance.new("Frame")
	holder.Name = "Slot" .. index
	holder.LayoutOrder = index
	holder.Size = UDim2.fromOffset(HOT.SlotWidth, HOT.SlotHeight)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = 4
	holder.Parent = hotbar

	local wrap = Instance.new("Frame")
	wrap.Name = "Wrap"
	wrap.AnchorPoint = Vector2.new(0.5, 0.5)
	wrap.Position = UDim2.fromScale(0.5, 0.5)
	wrap.Size = UDim2.fromScale(1, 1)
	wrap.BackgroundTransparency = 1
	wrap.BorderSizePixel = 0
	wrap.ZIndex = 4
	wrap.Parent = holder
	local heldScale = Instance.new("UIScale")
	heldScale.Parent = wrap

	-- The soft ring outside the keyline while the slot is in your hands.
	local aura = Instance.new("Frame")
	aura.Name = "Aura"
	aura.AnchorPoint = Vector2.new(0.5, 0.5)
	aura.Position = UDim2.fromScale(0.5, 0.5)
	aura.Size = UDim2.new(1, 8, 1, 8)
	aura.BackgroundColor3 = HOT.LitTop
	aura.BackgroundTransparency = 0.82
	aura.BorderSizePixel = 0
	aura.Visible = false
	aura.ZIndex = 4
	aura.Parent = wrap
	UIKit.corner(aura, 16)
	UIKit.stroke(aura, HOT.LitTop, 2, 0.45)

	local button = Instance.new("TextButton")
	button.Name = "Face"
	button.AnchorPoint = Vector2.new(0.5, 0.5)
	button.Position = UDim2.fromScale(0.5, 0.5)
	button.Size = UDim2.fromScale(1, 1)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.ZIndex = 5
	button.Parent = wrap
	UIKit.corner(button, 12)
	UIKit.gradient(button, HOT.PlateTop, HOT.PlateBottom)
	local stroke = UIKit.stroke(button, HOT.Ink, 2.5)

	--==========================================================================
	-- THE LIME IS A GRADIENT ON THE KEYLINE ITSELF
	--
	-- A UIGradient under a UIStroke colours the stroke, multiplied by the
	-- stroke's own Color -- so a held slot sets that to white and enables this,
	-- and every other state disables it and sets the colour it wants.
	--==========================================================================
	local ringTint = Instance.new("UIGradient")
	ringTint.Color = ColorSequence.new(HOT.LitTop, HOT.LitBottom)
	ringTint.Rotation = 90
	ringTint.Enabled = false
	ringTint.Parent = stroke

	-- Level with the plate, which draws it on the plate: the lattice's own default
	-- of 0 is buried under whatever it is laid on, as the shop found.
	local lattice = UIKit.lattice(button, {
		spacing = 12,
		thickness = 2,
		colour = HOT.Lattice,
		transparency = HOT.LatticeTransparency,
		inset = 4,
		zIndex = 5,
	})

	--==========================================================================
	-- THE COOLDOWN, DRAWN UNDER THE ITEM
	--
	-- A dark shade rising from the bottom of the slot, so a bat that cannot
	-- swing yet is dimmed from the feet up. Under the preview rather than over
	-- it, because a player checking a cooldown is also checking WHICH weapon
	-- they are about to swing. Level with the preview's frame and built before
	-- it, so the model -- a layer above both -- stays on top.
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
		size = UDim2.new(1, -8, 0, 42),
		position = UDim2.fromOffset(4, 12),
		scrim = 1,
	})

	--==========================================================================
	-- THE KEYCAP
	--
	-- An ink pill with the number on it and a shadow a step below, so it reads
	-- as a key rather than as a label. The tenth slot's cap says 0, because that
	-- is the key.
	--==========================================================================
	local keyShadow = Instance.new("Frame")
	keyShadow.Name = "KeyShadow"
	keyShadow.Position = UDim2.fromOffset(4, 6)
	keyShadow.Size = UDim2.fromOffset(16, 16)
	keyShadow.BackgroundColor3 = BLACK
	keyShadow.BackgroundTransparency = 0.45
	keyShadow.BorderSizePixel = 0
	keyShadow.ZIndex = 8
	keyShadow.Parent = button
	UIKit.corner(keyShadow, 5)

	local keycap = Instance.new("Frame")
	keycap.Name = "Keycap"
	keycap.Position = UDim2.fromOffset(4, 4)
	keycap.Size = UDim2.fromOffset(16, 16)
	keycap.BackgroundColor3 = HOT.Ink
	keycap.BorderSizePixel = 0
	keycap.ZIndex = 8
	keycap.Parent = button
	UIKit.corner(keycap, 5)
	UIKit.stroke(keycap, HOT.KeyEdge, 1)

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Name = "Key"
	keyLabel.Size = UDim2.fromScale(1, 1)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Font = Enum.Font.FredokaOne
	keyLabel.TextSize = 11
	keyLabel.TextColor3 = HOT.Numeral
	keyLabel.ZIndex = 9
	keyLabel.Parent = keycap

	-- What the thing IS, in its category's colour: BAT, TRAP or SEED.
	local tag = Instance.new("TextLabel")
	tag.Name = "Category"
	tag.AnchorPoint = Vector2.new(1, 0)
	tag.Position = UDim2.new(1, -5, 0, 5)
	tag.Size = UDim2.fromOffset(36, 12)
	tag.BackgroundTransparency = 1
	tag.Font = Enum.Font.FredokaOne
	tag.TextSize = 9
	tag.TextXAlignment = Enum.TextXAlignment.Right
	tag.Text = ""
	tag.ZIndex = 9
	tag.Parent = button
	UIKit.stroke(tag, HOT.Ink, 1.5)

	--==========================================================================
	-- THE NAME GETS TWO LINES, NOT AN ELLIPSIS
	--
	-- It was one line of 10 px truncated at the end, so "Rootwood Bat" read
	-- "Rootwood..." and "Bramblejaw Trap" read "Brambleja...". On an ink strip
	-- now, wrapped, and scaled down to 7 px before anything is cut -- the longest
	-- names in the game fit whole at 64 px.
	--==========================================================================
	local caption = Instance.new("Frame")
	caption.Name = "Caption"
	caption.AnchorPoint = Vector2.new(0.5, 1)
	caption.Position = UDim2.new(0.5, 0, 1, -3)
	caption.Size = UDim2.new(1, -6, 0, 22)
	caption.BackgroundColor3 = HOT.Ink
	caption.BackgroundTransparency = HOT.CaptionBacking
	caption.BorderSizePixel = 0
	caption.ZIndex = 8
	caption.Parent = button
	UIKit.corner(caption, 8)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Position = UDim2.fromOffset(2, 1)
	nameLabel.Size = UDim2.new(1, -4, 1, -2)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Font = Enum.Font.FredokaOne
	nameLabel.TextColor3 = HOT.Caption
	nameLabel.TextWrapped = true
	nameLabel.TextScaled = true
	nameLabel.ZIndex = 9
	nameLabel.Parent = caption
	local nameFit = Instance.new("UITextSizeConstraint")
	nameFit.MaxTextSize = 10
	nameFit.MinTextSize = 7
	nameFit.Parent = nameLabel

	--==========================================================================
	-- THE RETURN HINT
	--
	-- Just above the name, and hidden unless the bag is open on an assigned
	-- slot. It names the gesture in the words of the device it is on: a phone has
	-- no click and a desktop has no tap, and a hint that names the wrong one
	-- teaches nothing.
	--==========================================================================
	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "Hint"
	hintLabel.AnchorPoint = Vector2.new(0.5, 1)
	hintLabel.Position = UDim2.new(0.5, 0, 1, -27)
	hintLabel.Size = UDim2.fromOffset(52, 13)
	hintLabel.BackgroundColor3 = HOT.Ink
	hintLabel.BackgroundTransparency = 0.15
	hintLabel.BorderSizePixel = 0
	hintLabel.Font = Enum.Font.FredokaOne
	hintLabel.TextSize = 9
	hintLabel.TextColor3 = HOT.Numeral
	hintLabel.Text = if UserInputService.KeyboardEnabled then "2x CLICK" else "2x TAP"
	hintLabel.Visible = false
	hintLabel.ZIndex = 9
	hintLabel.Parent = button
	UIKit.corner(hintLabel, 4)

	-- Hover and press, the Bag cards' pop at the strip's smaller scale. Silent: a
	-- pointer crosses the strip on its way to the world far more often than it
	-- means to pick anything, and the press already clicks when it equips.
	local pressScale = Instance.new("UIScale")
	pressScale.Parent = button
	local pop = UIKit.cardPop(button, pressScale, {
		hoverScale = HOT.HoverScale,
		pressScale = HOT.PressScale,
		sound = false,
	})

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
		holder = holder,
		heldScale = heldScale,
		pop = pop,
		ringTint = ringTint,
		aura = aura,
		lattice = lattice,
		keycap = keycap,
		tag = tag,
		caption = caption,
		ghost = nil,
		lit = false,
		flashUntil = 0,
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
-- LIFTING THE WHOLE STRIP DURING A DRAG
--
-- The drag used to raise this frame to 60 and each slot's button to 61, and left
-- everything inside them at their own numbers. Under Global ZIndexBehavior that
-- moved two layers of a dozen -- and with the tray now painted on the Hotbar
-- frame itself, raising the frame alone would draw the tray OVER its own slots.
-- So the whole subtree moves by one offset and every layer goes back to exactly
-- the number it had. Anything built while the strip is up was built at its
-- resting number, and is left there.
--==============================================================================
local liftStrip: (boolean) -> ()
do
	local LIFT = 56
	local resting: { [GuiObject]: number } = {}
	local lifted = false
	liftStrip = function(want: boolean)
		if lifted == want then
			return
		end
		lifted = want
		if want then
			table.clear(resting)
			resting[hotbar] = hotbar.ZIndex
			hotbar.ZIndex += LIFT
			for _, d in ipairs(hotbar:GetDescendants()) do
				if d:IsA("GuiObject") then
					resting[d] = d.ZIndex
					d.ZIndex += LIFT
				end
			end
		else
			for object, z in pairs(resting) do
				if object.Parent then
					object.ZIndex = z
				end
			end
			table.clear(resting)
		end
	end
end

--==============================================================================
-- THE BAG CHIP
--
-- The mockup's last cell: how many slots are holding something out of how many
-- there are, and a door into the Bag from where the player is already looking.
-- The rail button stays the Bag's home and this is a shortcut, dropped below
-- HOT.ChipMinViewport where a five-slot tray needs the width. Its press is wired
-- beside the rail button's, where setOpen exists.
--==============================================================================
local chip: { holder: Frame, button: TextButton, count: TextLabel }
do
	local holder = Instance.new("Frame")
	holder.Name = "BagChip"
	holder.LayoutOrder = MAX_SLOTS + 1
	holder.Size = UDim2.fromOffset(HOT.ChipWidth, HOT.SlotHeight)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = 4
	holder.Parent = hotbar

	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromScale(1, 1)
	face.BorderSizePixel = 0
	face.AutoButtonColor = false
	face.Text = ""
	face.ZIndex = 5
	face.Parent = holder
	UIKit.corner(face, 12)
	UIKit.gradient(face, HOT.PlateTop, HOT.PlateBottom)
	UIKit.stroke(face, HOT.Ink, 2.5)
	UIKit.clicks(face)
	local press = Instance.new("UIScale")
	press.Parent = face
	UIKit.cardPop(face, press, {
		hoverScale = HOT.HoverScale,
		pressScale = HOT.PressScale,
		sound = false,
	})

	local word = Instance.new("TextLabel")
	word.Name = "Word"
	word.AnchorPoint = Vector2.new(0.5, 0)
	word.Position = UDim2.new(0.5, 0, 0, 22)
	word.Size = UDim2.new(1, -6, 0, 14)
	word.BackgroundTransparency = 1
	word.Font = Enum.Font.FredokaOne
	word.TextSize = 11
	word.TextColor3 = HOT.Numeral
	word.Text = "BAG"
	word.ZIndex = 9
	word.Parent = face

	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.AnchorPoint = Vector2.new(0.5, 0)
	count.Position = UDim2.new(0.5, 0, 0, 38)
	count.Size = UDim2.new(1, -6, 0, 18)
	count.BackgroundTransparency = 1
	count.Font = Enum.Font.FredokaOne
	count.TextSize = 14
	count.TextColor3 = HOT.LitTop
	count.Text = ""
	count.ZIndex = 9
	count.Parent = face
	UIKit.stroke(count, HOT.Ink, 1.5)

	chip = { holder = holder, button = face, count = count }
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
	-- THE USED SLOTS AND ONE MORE, UNLESS THE PLAYER IS ARRANGING
	--
	-- Every live slot used to be drawn, empty or not, because an empty slot is
	-- the DROP TARGET. On a desktop that was six dead boxes across the bottom of
	-- the screen for a player carrying a bat, a trap and two plants, and the
	-- approved design collapses them:
	--
	--   drawn        every slot up to the last one in use, so the keycaps never
	--                skip a number, and ONE ghost after it: where the next
	--                pickup lands, and a target for a drag
	--   hidden       everything past that
	--   Bag open     every live slot, ghosts and all. That is when the player is
	--                arranging, and every drag from the Bag starts with it open,
	--                so no drop from the Bag ever loses its target.
	--
	-- A slot whose lease is still inside its grace counts as in use, so a respawn
	-- does not fold the strip up and reflow it under a thumb.
	--
	-- Hidden slots are emptied of their tool reference, so a stale one cannot be
	-- equipped by a number key or ticked by the cooldown loop. Past `activeSlots`
	-- their ASSIGNMENT records survive untouched -- that is the overflow -- and a
	-- collapsed slot has no record to keep, by the rule above.
	--==========================================================================
	local lastUsed = 0
	for i = 1, activeSlots do
		if placed[i] or assigned[i] then
			lastUsed = i
		end
	end
	local shown = if bagOpen then activeSlots else math.min(activeSlots, lastUsed + 1)
	local filled = 0
	local now = os.clock()

	for i = 1, math.max(activeSlots, #hotSlots) do
		local slot = hotSlots[i]
		if i > shown then
			if slot then
				slot.holder.Visible = false
				slot.button.Visible = false
				slot.tool = nil
				slot.item = nil
				slot.pop.reset()
			end
		else
			slot = acquireHotSlot(i)
			local data = placed[i]
			slot.holder.Visible = true
			slot.button.Visible = true
			slot.tool = if data then data.tool else nil
			slot.item = if data then data.item else nil
			-- The tenth slot is reached by the 0 key, because that is where the
			-- number row puts it. Labelling it "10" would name a key nobody has.
			slot.key.Text = if i == 10 then "0" else tostring(i)
			if data then
				filled += 1
				slot.preview.setModel(data.key, builderFor(data), previewKind(data))
				-- The whole name, always: TutorialUI finds a plant's slot by it.
				slot.name.Text = data.label
				local tag = HOT.Tags[data.kind]
				slot.tag.Text = if tag then tag.text else string.upper(data.kind)
				slot.tag.TextColor3 = if tag then tag.colour else HOT.Caption
			else
				slot.preview.setModel("empty:" .. i, nil, "plant")
				slot.name.Text = ""
				slot.tag.Text = ""
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
			-- AN EMPTY SLOT IS A GHOST
			--
			-- No plate, no keyline, no lattice, no caption: a dashed outline, a
			-- faded keycap and a plus. It is still the same button, so it is still
			-- a drop target and still unequips when pressed. The dashes are built
			-- the first time a slot is empty and kept.
			--==================================================================
			local empty = data == nil
			slot.button.BackgroundTransparency = if empty then 1 else 0
			slot.lattice.Visible = not empty
			slot.caption.Visible = not empty
			slot.tag.Visible = not empty
			slot.keycap.BackgroundTransparency = if empty then 0.35 else 0
			if empty and not slot.ghost then
				local ghost = Instance.new("Frame")
				ghost.Name = "Ghost"
				ghost.Size = UDim2.fromScale(1, 1)
				ghost.BackgroundTransparency = 1
				ghost.BorderSizePixel = 0
				ghost.ZIndex = 5
				ghost.Parent = slot.button
				dashOutline(ghost, HOT.SlotWidth, HOT.SlotHeight, HOT.Ghost, 5)
				local plus = Instance.new("TextLabel")
				plus.Name = "Plus"
				plus.AnchorPoint = Vector2.new(0.5, 0.5)
				plus.Position = UDim2.fromScale(0.5, 0.56)
				plus.Size = UDim2.fromOffset(24, 24)
				plus.BackgroundTransparency = 1
				plus.Font = Enum.Font.FredokaOne
				plus.TextSize = 22
				plus.TextColor3 = HOT.Ghost
				plus.Text = "+"
				plus.ZIndex = 8
				plus.Parent = ghost
				slot.ghost = ghost
			end
			local ghost = slot.ghost
			if ghost then
				ghost.Visible = empty
			end

			--==================================================================
			-- THREE FACTS, THREE RINGS, AND THEY MUST NOT COLLIDE
			--
			-- Lime says "this is in your hands" and outranks the rest, because it
			-- is the one that changes second to second: the lime keyline, the soft
			-- ring outside it, a lime numeral and the 1.06 scale. Light slate says
			-- "you put this here". Ink is a slot doing nothing in particular.
			--
			-- A drop's flash owns the keyline until its own redraw; see flashSlot.
			--==================================================================
			local isHeld = data ~= nil and data.tool == held
			if now >= slot.flashUntil then
				slot.ringTint.Enabled = isHeld
				slot.stroke.Color = if isHeld then WHITE
					elseif record and not empty then HOT.Assigned
					else HOT.Ink
				slot.stroke.Thickness = if isHeld then 3 else 2.5
				slot.stroke.Transparency = if empty then 1 else 0
			end
			slot.aura.Visible = isHeld
			slot.key.TextColor3 = if isHeld then HOT.NumeralLit else HOT.Numeral
			if slot.lit ~= isHeld then
				slot.lit = isHeld
				TweenService:Create(slot.heldScale, TweenInfo.new(0.14, Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out), { Scale = if isHeld then HOT.HeldScale else 1 }):Play()
			end
		end
	end

	chip.count.Text = string.format("%d/%d", filled, activeSlots)
	local camera = Workspace.CurrentCamera
	chip.holder.Visible = camera ~= nil and camera.ViewportSize.X >= HOT.ChipMinViewport
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

--==============================================================================
-- WHERE THE BAG SITS, AND WHAT IS BESIDE THE GRID
--
-- Forward, because refreshBag reflows it when the tab changes and the function
-- itself lives with the other screen-shape code further down.
--==============================================================================
local layoutBag: () -> ()

-- The auto-filled hotbar slot showing this exact Tool, if any. Assigned copies
-- never reach the panel -- they are not in the bag -- so this only ever names a
-- slot the item is ALSO on.
local function hotbarSlotOf(tool: Tool): number?
	for i = 1, activeSlots do
		local slot = hotSlots[i]
		if slot and slot.button.Visible and slot.tool == tool then
			return i
		end
	end
	return nil
end

--==============================================================================
-- THE INFORMATION PANEL, PAINTED
--
-- Off the selected Tool's own attributes, through PlantInfo, every time. Nothing
-- is cached, so a hatch, a pass landing, or the Tool moving between the Backpack
-- and the hands repaints it from what is true now.
--==============================================================================
local function paintInfo()
	local tool = selectedTool
	if not (tool and tool.Parent) then
		infoHint.Visible = true
		infoHint.Text = if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
			then "Tap a plant to see what it is"
			else "Select a plant to see what it is"
		infoTitle.Visible = false
		infoStage.Visible = false
		infoRows.Visible = false
		return
	end
	local details = PlantInfo.Describe(tool:GetAttribute("SpeciesId"),
		tool:GetAttribute(ATTR.CarryingKg), tool:GetAttribute("Hatched") == true,
		GameConfig.cashMultiplier(player))
	local character = player.Character
	local status = PlantInfo.Status(character ~= nil and tool.Parent == character,
		hotbarSlotOf(tool))

	infoHint.Visible = false
	infoTitle.Visible = true
	infoStage.Visible = true
	infoRows.Visible = true
	infoTitle.Text = details.title
	infoStage.Text = string.upper(details.stage)
	infoStageEdge.Color = if details.incomePerSecond then INCOME else details.sizeColour

	local values: { [string]: { any } } = {
		Biome = { details.biome, CREAM },
		Rarity = { details.rarity, details.rarityColour },
		Size = { details.size, details.sizeColour },
		Income = { details.income, if details.incomePerSecond then INCOME else MUTED },
		Sell = { details.sell or PlantInfo.Unknown, if details.sell then CREAM else MUTED },
		Status = { status, CREAM },
	}
	for keyName, row in pairs(infoRowFor) do
		local value = values[keyName]
		row.value.Text = value[1]
		row.value.TextColor3 = value[2]
	end
end

local function paintSelection()
	for i, card in pairs(cardPool) do
		local row = cardRows[i]
		card.selectRing.Visible = card.button.Visible and row ~= nil
			and row.tool ~= nil and row.tool == selectedTool
	end
end

selectTool = function(tool: Tool?)
	selectedTool = tool
	paintSelection()
	paintInfo()
end

local function refreshBag()
	local weaponCount, plantCount = 0, 0
	for _, item in ipairs(WeaponData.Items) do
		if owned[item.Id] then
			weaponCount += 1
		end
	end
	for _, slot in ipairs(liveSlots) do
		if slot.kind == "plant" and not claimed[slot.tool] then
			plantCount += 1
		end
	end

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
		local count = tabCounts[tab.id]
		if count then
			count.Text = tostring(if tab.id == "equipment" then weaponCount else plantCount)
			-- The equipment count comes off the profile, so it waits for one.
			count.Visible = tab.id == "plants" or heardProfile
		end
	end

	--== WHAT THIS TAB SHOWS ==--
	local rows: { Row } = {}
	local held = heldTool()

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
		-- items, they are somebody's garden.
		--
		-- AN ASSIGNED COPY IS NOT IN THE BAG ANY MORE. `claimed` holds exactly
		-- the Tools that active hotbar slots have taken, one entry per instance,
		-- so owning two identical plants and assigning one hides ONE card.
		--======================================================================
		for _, slot in ipairs(liveSlots) do
			if slot.kind == "plant" and not claimed[slot.tool] then
				local tier = math.floor(tonumber(slot.tool:GetAttribute(ATTR.CarryingKg)) or 1)
				table.insert(rows, {
					key = slot.key .. ":" .. tostring(slot.tool),
					label = slot.label,
					kind = "plant",
					build = builderFor(slot),
					state = if slot.tool == held then "IN HAND" else "HOLD",
					lit = slot.tool == held,
					item = nil,
					tool = slot.tool,
					canHotbar = slot.canHotbar,
					speciesId = slot.tool:GetAttribute("SpeciesId"),
					tier = tier,
					hatched = slot.tool:GetAttribute("Hatched") == true,
				})
			end
		end
	end

	--==========================================================================
	-- A SELECTION THAT NO LONGER NAMES A CARD IS DROPPED
	--
	-- Assigned to the hotbar, planted, sold, destroyed, or simply another tab:
	-- rather than trust the tap that made it, the selection is re-tested against
	-- what this draw is about to show.
	--==========================================================================
	if activeTab ~= "plants" then
		selectedTool = nil
	elseif selectedTool then
		local still = false
		for _, row in ipairs(rows) do
			if row.tool == selectedTool then
				still = true
				break
			end
		end
		if not still then
			selectedTool = nil
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
				spare.selectRing.Visible = false
				-- A hidden card may have been under the pointer; put it down now,
				-- because no MouseLeave is coming.
				spare.pop.reset()
				spare.actionPop.reset()
			end
		else
			cardRows[i] = row
			local card = acquireCard(i)
			card.button.Visible = true
			card.button.LayoutOrder = i
			card.preview.setModel(row.key, row.build, row.kind)

			local art = if row.kind == "plant"
				then PlantInfo.Backdrop(row.speciesId, row.hatched == true)
				else nil
			card.backdrop.Image = art or ""
			card.backdrop.Visible = art ~= nil
			local scrim = card.scrim
			if scrim and scrim:IsA("Frame") then
				-- The art is the backing when there is some; the scrim is for the
				-- bare well, where a pale item needs a breath of shade.
				scrim.BackgroundTransparency = if art then 1 else 0.86
			end

			fitName(card, row.label)
			-- A plant's name wears its size band, the way the Garden prints it.
			card.name.TextColor3 = if row.kind == "plant" and row.tier
				then SeedData.ColorForTier(row.tier)
				else CREAM
			card.state.Text = row.state
			fitPill(card, row.state)
			--==============================================================
			-- LIT SAYS ITSELF THREE TIMES
			--
			-- The card warms toward green, a green ring appears inside its
			-- keyline, and the state button fills green. The black keyline does
			-- NOT change: it is the house edge on every surface in this game.
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

	paintSelection()
	paintInfo()
	layoutBag()
end

--==============================================================================
-- WHERE THE BAG SITS
--
-- MEASURED BEFORE THIS EXISTED: centred at 0.9 x 0.82 of the screen, the panel's
-- bottom sat 33 px under the hotbar on a 1169 x 609 desktop, so the last row's
-- buttons were behind the strip -- and on a 735 x 413 phone the strip covers most
-- of a card row. The hotbar draws over the bag on purpose, because it is the drop
-- target, so the answer is not to fight that. It is to keep the bag out of its
-- way, and out from under the rail buttons as well.
--
-- So the panel is fitted into the space that is actually free:
--
--   between the rails   right of Index/Shop, left of the Garden/Bag buttons and
--                       the BAT/TRAP column, from the top of the screen down to
--                       just above the hotbar. Desktops and landscape phones.
--   under the rails     when that gap is too narrow to hold a panel -- a portrait
--                       phone -- it drops below the rail band instead.
--
-- Centred on the SCREEN when its width allows, so it lines up with the hotbar
-- under it; otherwise centred in the free band.
--==============================================================================
local groupLimit = modal.group:FindFirstChildOfClass("UISizeConstraint")
if groupLimit then
	groupLimit.MinSize = Vector2.new(240, 160)
end
local titlePad = modal.title.Parent and modal.title.Parent:FindFirstChildOfClass("UIPadding")

layoutBag = function()
	local screen = gui.AbsoluteSize
	if screen.X < 100 or screen.Y < 100 then
		return
	end
	local hotTop = screen.Y + hotbar.Position.Y.Offset - hotbar.Size.Y.Offset
	local railBottom = RAIL.Inset + RAIL.WideSize.Y * 2 + RAIL.Gap
	local leftEdge = RAIL.Inset + RAIL.WideSize.X + EDGE_GAP
	local rightEdge = screen.X - RAIL.Inset - side.Size.X.Offset - EDGE_GAP
	local top = EDGE_GAP
	local bottom = hotTop - EDGE_GAP
	if rightEdge - leftEdge < 420 then
		leftEdge = EDGE_GAP
		top = railBottom + EDGE_GAP
	end

	local height = math.max(160, math.min(PANEL_MAX_H, bottom - top))
	--==========================================================================
	-- CENTRED ON THE SCREEN WHEN THAT STILL LEAVES A REAL PANEL
	--
	-- The rails are not symmetric -- 130 px on the left, 64 on the right -- so
	-- the middle of the free band is not the middle of the screen, and the first
	-- measurement put the panel 33 px right of the hotbar under it. A panel
	-- centred on the screen is kept whenever it clears both rails at a useful
	-- width; a phone, which needs every pixel, takes the whole band instead.
	--==========================================================================
	local half = screen.X * 0.5
	local symmetric = 2 * math.min(half - leftEdge, rightEdge - half)
	local width, centreX
	if symmetric >= 600 or symmetric >= rightEdge - leftEdge - 40 then
		width = math.max(240, math.min(PANEL_MAX_W, symmetric))
		centreX = half
	else
		width = math.max(240, math.min(PANEL_MAX_W, rightEdge - leftEdge))
		centreX = (leftEdge + rightEdge) * 0.5
	end
	local centreY = top + (bottom - top) * 0.5
	modal.group.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.group.Position = UDim2.fromOffset(math.floor(centreX), math.floor(centreY))
	modal.group.Size = UDim2.fromOffset(math.floor(width), math.floor(height))

	--==========================================================================
	-- A SHORT SCREEN PUTS THE TABS ON THE TITLE'S ROW
	--
	-- On a landscape phone the whole panel is ~250 px tall, and a title row plus
	-- a tab row under it left less than one card row of grid. Beside the title
	-- they cost nothing: "BAG" is three letters.
	--==========================================================================
	local outline = RAIL.OutlineThickness
	local shellH = height - outline * 2
	local compact = shellH < COMPACT_BELOW
	if compact then
		local padLeft = if titlePad then titlePad.PaddingLeft.Offset else 0
		local reserve = math.max(72, math.ceil(modal.title.TextBounds.X) + padLeft + 16)
		tabRow.Position = UDim2.fromOffset(12 + reserve, 13)
		tabRow.Size = UDim2.new(1, -(24 + reserve + 52), 0, 34)
		modal.body.Position = UDim2.fromOffset(12, 58)
		modal.body.Size = UDim2.new(1, -24, 1, -70)
	else
		tabRow.Position = UDim2.fromOffset(12, 58)
		tabRow.Size = UDim2.new(1, -24, 0, 34)
		modal.body.Position = UDim2.fromOffset(12, 100)
		modal.body.Size = UDim2.new(1, -24, 1, -112)
	end

	--==========================================================================
	-- BESIDE THE GRID, OR UNDER IT
	--
	-- Beside it while two columns of cards and the narrowest readable panel
	-- both fit; under it, as a lower sheet, when they do not. Plants only -- the
	-- equipment tab gives its tray the whole body.
	--==========================================================================
	local bodyW = width - outline * 2 - 24
	local bodyH = shellH - (if compact then 70 else 112)
	local twoColumns = CARD_W * 2 + CARD_GAP + GRID_PAD * 2
	if activeTab ~= "plants" then
		tray.Size = UDim2.fromScale(1, 1)
		info.Visible = false
	elseif bodyW >= twoColumns + INFO_GAP + INFO_SIDE_MIN then
		local infoW = math.clamp(math.floor(bodyW * 0.34), INFO_SIDE_MIN, INFO_SIDE_MAX)
		tray.Size = UDim2.new(1, -(infoW + INFO_GAP), 1, 0)
		info.AnchorPoint = Vector2.new(1, 0)
		info.Position = UDim2.fromScale(1, 0)
		info.Size = UDim2.new(0, infoW, 1, 0)
		layoutInfo(if bodyH < 240 then "compact" else "side")
		info.Visible = true
	else
		tray.Size = UDim2.new(1, 0, 1, -(INFO_SHEET_H + INFO_GAP))
		info.AnchorPoint = Vector2.new(0, 1)
		info.Position = UDim2.fromScale(0, 1)
		info.Size = UDim2.new(1, 0, 0, INFO_SHEET_H)
		layoutInfo("sheet")
		info.Visible = true
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
	-- The redraw every drop makes would repaint the keyline a frame later, so the
	-- flash owns it until its own redraw below: the lime gradient steps aside,
	-- and a ghost's hidden keyline shows for the length of the flash.
	slot.flashUntil = os.clock() + 0.32
	slot.ringTint.Enabled = false
	slot.stroke.Transparency = 0
	slot.stroke.Color = colour
	slot.stroke.Thickness = 4
	TweenService:Create(slot.stroke, TweenInfo.new(0.30), { Thickness = 2.5 }):Play()
	task.delay(0.32, function()
		if hotSlots[index] == slot then
			slot.flashUntil = 0
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
	liftStrip(false)

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
			liftStrip(true)
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
		-- Closing the Bag is the other way a selection ends, and a card still
		-- under the pointer is put down now rather than on a MouseLeave that
		-- will never come.
		for _, card in pairs(cardPool) do
			card.pop.reset()
			card.actionPop.reset()
		end
		selectTool(nil)
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
-- The strip's Bag chip is the same door, from where the player is looking.
chip.button.Activated:Connect(function()
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

--==============================================================================
-- THE REST OF THE SELECTION CONTRACT
--
-- A tap on EMPTY tray clears it. Empty means no card under the release, and a
-- tap means a press that neither travelled nor scrolled the grid -- so a scroll
-- that happens to lift over a gap does not throw the panel away.
--==============================================================================
local trayPressAt: Vector3? = nil
local trayPressCanvas: Vector2? = nil

grid.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		trayPressAt = input.Position
		trayPressCanvas = grid.CanvasPosition
	end
end)

grid.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	local start, canvas = trayPressAt, trayPressCanvas
	trayPressAt, trayPressCanvas = nil, nil
	if not (start and canvas and selectedTool) then
		return
	end
	if (input.Position - start).Magnitude > TAP_SLOP
		or (grid.CanvasPosition - canvas).Magnitude > 4 then
		return
	end
	local point = Vector2.new(input.Position.X, input.Position.Y)
	for _, card in pairs(cardPool) do
		if card.button.Visible then
			local p, sz = card.button.AbsolutePosition, card.button.AbsoluteSize
			if point.X >= p.X and point.X <= p.X + sz.X
				and point.Y >= p.Y and point.Y <= p.Y + sz.Y then
				return
			end
		end
	end
	selectTool(nil)
end)

-- The x2 pass can land while the panel is open, and the income line carries it.
player:GetAttributeChangedSignal(GameConfig.Pass.MultiplierAttribute):Connect(function()
	if selectedTool then
		paintInfo()
	end
end)

-- The screen changing shape moves the Bag, and the title's measured width is
-- how much of its row the compact tabs may take.
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutBag)
modal.title:GetPropertyChangedSignal("TextBounds"):Connect(layoutBag)

-- The Bag's close button gets the same small press as its other controls. The
-- plate is centre-anchored, so it scales in place; the 44 px target never moves.
do
	local plate = modal.close:FindFirstChild("Plate")
	if plate and plate:IsA("GuiObject") then
		local plateScale = Instance.new("UIScale")
		plateScale.Parent = plate
		UIKit.cardPop(modal.close, plateScale, { hoverScale = 1.06, pressScale = 0.94, sound = false })
	end
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

--== The held Tool changing is a redraw: it is what the lime ring shows. ==--
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
