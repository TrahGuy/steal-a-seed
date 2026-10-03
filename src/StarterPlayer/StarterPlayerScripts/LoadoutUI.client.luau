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
-- Whether a hatched plant may be named yet: while its roll runs it is drawn as
-- the pod it came out of (2026-09-29).
local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
-- Where the strip, the Bag button and BAT/TRAP sit on this screen, and how many
-- slots it gets. Numbers only; see layoutHud at the bottom of this file.
local HudLayout = require(Shared:WaitForChild("HudLayout"))
-- The hotbar's roles and its two plant shortcuts (pure), and how one slot is
-- drawn (2026-10-01). Out of this chunk, which is rationed to 200 locals.
local HotbarRoles = require(Shared:WaitForChild("HotbarRoles"))
local HotbarCard = require(Shared:WaitForChild("HotbarCard"))

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
--
-- ON A PHONE -- HudLayout's compact mode -- the card is 112 x 170 and the grid
-- runs sideways in whole rows; see layoutBag. The numbers live in
-- HudLayout.Config.Bag, where the arithmetic that places the panel lives, so a
-- spec can drive it at every screen size. These are read back from there.
--==============================================================================
local BAG = HudLayout.Config.Bag
local CARD_W, CARD_H = BAG.Card.X, BAG.Card.Y
local CARD_GAP = BAG.CardGap
local ACTION_H = BAG.ActionH
local INFO_GAP = BAG.InfoGap
local INFO_SHEET_H = BAG.InfoSheetH
local PANEL_MAX_W, PANEL_MAX_H = BAG.MaxW, BAG.MaxH
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
-- without looking: ten 64-pixel slots come to 685 px of strip, which on a
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
-- on a desktop still cannot show 685 px of strip without eating the screen. A
-- wide viewport alone is not enough either -- a tablet has the width and no
-- number row, so slots 6-10 would be reachable only by touch, which is exactly
-- the fingernail problem. Anything that is not both gets five.
--
-- SINCE 2026-09-18 THE ANSWER IS HudLayout's, read off the same layout that
-- places the strip: ten only in its desktop mode, with a keyboard, and five on
-- ANY touch screen. That last part is new and it is the point -- Studio's
-- emulator reports a keyboard, so a 956-wide emulated phone was getting ten.
-- The rule below is only the stand-in for the moment before the ScreenGui has
-- a size, and it answers five for anything with a touch screen.
--==============================================================================
-- SINCE 2026-10-01 THE SLOTS ARE ROLES (HotbarRoles): five on a desktop, four
-- on a phone -- HudLayout.Config's numbers, read here only for the moment
-- before the ScreenGui has a size.
local DESKTOP_SLOTS = HudLayout.Config.DesktopSlots
local MOBILE_SLOTS = HudLayout.Config.MobileSlots
local MAX_SLOTS = DESKTOP_SLOTS

-- How many slots are LIVE right now. Everything reads this; nothing assumes a
-- number. `MAX_SLOTS` is how many can ever exist, and the difference between the
-- two is the overflow the mobile path has to keep reachable.
local activeSlots = MOBILE_SLOTS

-- HudLayout's last answer for this screen. nil until the ScreenGui below has a
-- size; layoutHud keeps it current.
local hud: HudLayout.Layout? = nil

local function wantedSlots(): number
	local layout = hud
	if layout then
		return layout.slots
	end
	if not UserInputService.TouchEnabled then
		return DESKTOP_SLOTS
	end
	return MOBILE_SLOTS
end


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
-- Below the rail (40) and every panel -- Index, Garden and Settings at 31, the
-- Shop at 32, Marigold at 34 -- so a modal covers the hotbar rather than the
-- hotbar poking through it. The Bag is the one panel in THIS ScreenGui, and it
-- fits itself above the strip instead, because the strip is its drop target.
gui.DisplayOrder = 30
-- Drawn bigger on a TV (HudLayout's TEN-FOOT PROFILE) -- before anything is laid
-- out in it; the Bag's UIKit.modal asks again and finds it done.
UIKit.tenFoot(gui)
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
-- WHAT MAY BE CHOSEN FOR A SHORTCUT, AND WHY A BAT MAY NOT
--
-- Only plants and pods: keys 4 and 5 are the two plant shortcuts (HotbarRoles),
-- and the bat, the trap and the Spin Tickets each have a fixed slot of their
-- own, so there is nothing to choose for them. A CATEGORY decides this, never
-- a species name.
--==============================================================================
local function assignable(_tool: Tool, kind: string): boolean
	return kind == "plant"
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
	local species = if type(speciesId) == "string" then SeedData.Get(speciesId) else nil
	if species then
		local tier = math.floor(tonumber(tool:GetAttribute(ATTR.CarryingKg)) or 1)
		--======================================================================
		-- A PLANT WHOSE ROLL IS STILL RUNNING IS THE POD IT CAME OUT OF
		--
		-- The hatch has happened and the Tool is the player's, but its reveal is
		-- a few seconds off (HatchRoll): until then this card is ???, a pod, and
		-- nothing about it says which plant -- not its name, not its picture,
		-- and not where it sorts, which is why its key carries the pod's biome
		-- and never the species. The Tool says when that ends (RevealAt), and
		-- the card repaints as the plant the moment it does.
		--======================================================================
		if HatchRoll.sealed(tool) then
			return {
				tool = tool,
				kind = "plant",
				key = string.format("p:~%s:%d:sealed", species.Biome, tier),
				label = HatchRoll.Unknown,
				item = nil,
				rank = 3,
				canHotbar = assignable(tool, "plant"),
			}
		end
		local hatched = tool:GetAttribute("Hatched") == true
		return {
			tool = tool,
			kind = "plant",
			key = string.format("p:%s:%d:%s", speciesId :: string, tier, tostring(hatched)),
			label = tool.Name,
			item = nil,
			rank = 3,
			canHotbar = assignable(tool, "plant"),
		}
	end
	--==========================================================================
	-- THE SPIN TICKETS (2026-10-01; GameConfig.Community)
	--
	-- One stacked Tool the server keeps equal to the wheel's earned balance
	-- (WheelService, SPIN TICKETS); its count is on its card's chip. First in
	-- the order, so the belt's auto-fill gives it the first free slot; where the
	-- player has pinned every slot it is in the Bag. Never a plant: no storage.
	--==========================================================================
	if tool:GetAttribute("SpinTicket") == true then
		return {
			tool = tool,
			kind = "ticket",
			key = "t:spin",
			label = tool.Name,
			item = nil,
			rank = 0,
			canHotbar = assignable(tool, "ticket"),
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
	-- A Spin Ticket: a gold ticket in blocks, with the wheel's colours on its stub.
	if slot.kind == "ticket" then
		return function(parent)
			local model = Instance.new("Model")
			model.Name = "SpinTicketPreview"
			local function block(name: string, size: Vector3, cf: CFrame, colour: Color3)
				local p = Instance.new("Part")
				p.Name = name
				p.Anchored = true
				p.Size = size
				p.CFrame = cf
				p.Color = colour
				p.Material = Enum.Material.SmoothPlastic
				p.Parent = model
				return p
			end
			local body = block("Ticket", Vector3.new(3.2, 1.8, 0.2), CFrame.new(), Color3.fromRGB(255, 206, 84))
			block("Stub", Vector3.new(0.8, 1.6, 0.24), CFrame.new(1.05, 0, 0), Color3.fromRGB(240, 120, 90))
			block("Band", Vector3.new(1.9, 0.3, 0.24), CFrame.new(-0.45, 0.45, 0), Color3.fromRGB(90, 176, 255))
			block("Band", Vector3.new(1.9, 0.3, 0.24), CFrame.new(-0.45, -0.45, 0), Color3.fromRGB(110, 220, 110))
			model.PrimaryPart = body
			model.Parent = parent
			return model
		end
	end
	local speciesId = slot.tool:GetAttribute("SpeciesId")
	local species = if type(speciesId) == "string" then SeedData.Get(speciesId) else nil
	if not species then
		return nil
	end
	local tier = math.floor(tonumber(slot.tool:GetAttribute(ATTR.CarryingKg)) or 1)
	-- A pod, too, while its roll runs: BuildPod reads the species for its biome
	-- and nothing else, so the picture is the shell the player just opened.
	local hatched = HatchRoll.shownHatched(slot.tool)
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
		-- Said, not just buzzed: the toast names the rule and plays the denial
		-- with it (ActionToastUI), once however often the card is pressed. The
		-- reason is the server's own replicated CarryingSpecies, not a guess.
		-- Required here rather than at the top: this chunk's names are rationed.
		require(Shared:WaitForChild("ActionRefusal")).raise("CARRYING_POD")
		return
	end
	--==========================================================================
	-- NOT A PLANT WHOSE ROLL IS STILL RUNNING (2026-09-29)
	--
	-- In the hands it is the plant itself, at full size, for everybody to see:
	-- the one thing its roll is keeping back. The server puts it in their hands
	-- when the reveal is over; until then the card is pressed for nothing, and
	-- says so with the press sound it always makes and no more.
	--==========================================================================
	if HatchRoll.sealed(tool) then
		SoundKit.play("CardClick")
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
--==============================================================================
-- THE PLANTS TAB'S SORT, AND THE NOTE OVER ITS CARDS (2026-09-26)
--
-- One table, because this file is a handful of names short of Luau's 200.
--   mode     which PlantInfo sort the plant cards are in. "default" is the order
--            scanTools has always produced, untouched until a player chooses.
--   button   the Sort button at the right end of the tab row, Plants tab only.
--   note     the one line over the cards saying what their $/s is.
--   watched  Tools whose data this file listens to, so a card repaints if a
--            Tool's species, size or hatched state ever changes under it.
-- The sort orders the CARDS and nothing else: scanTools and liveSlots -- what
-- the hotbar fills and re-binds from -- keep their own order, and no Tool moves.
--==============================================================================
local bagSort: {
	mode: string,
	button: UIKit.CycleButton?,
	note: TextLabel?,
	watched: { [Tool]: boolean },
} = { mode = "default", button = nil, note = nil, watched = setmetatable({}, { __mode = "k" }) :: any }
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

-- The tabs take the row less the Sort button's own width at its right end
-- (HudLayout's Bag.SortW), so each is still 120+ wide on the narrowest phone.
local tabsArea = Instance.new("Frame")
tabsArea.Name = "TabsArea"
tabsArea.Size = UDim2.new(1, -(BAG.SortW + BAG.SortGap), 1, 0)
tabsArea.BackgroundTransparency = 1
tabsArea.ZIndex = 4
tabsArea.Parent = tabRow

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
	b.Parent = tabsArea
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

do
	-- Pressing it is wired below, with the tabs, once refreshBag exists.
	local sort = UIKit.cycleButton(tabRow, "SORT", 5)
	sort.button.AnchorPoint = Vector2.new(1, 0.5)
	sort.button.Position = UDim2.fromScale(1, 0.5)
	sort.button.Size = UDim2.new(0, BAG.SortW, 1, 0)
	sort.button.Visible = false
	sort.set(PlantInfo.SortLabels[bagSort.mode])
	bagSort.button = sort
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

do
	--==========================================================================
	-- SAID ONCE, OVER THE CARDS: WHAT THEIR $/s IS
	--
	-- Each grown plant's card carries its income, and it is the BASE rate --
	-- the plant's own, with its permanent factors and no boost -- where the
	-- panel beside it and the Garden print what the player is actually paid,
	-- pass included. Without this line a pass owner sees two numbers for one
	-- plant and reads a bug. The grid starts under it (layoutBag), and
	-- HudLayout counts it out of the tray before it counts whole rows.
	--==========================================================================
	local note = Instance.new("TextLabel")
	note.Name = "IncomeNote"
	note.BackgroundTransparency = 1
	note.Position = UDim2.fromOffset(12, 3)
	note.Size = UDim2.new(1, -24, 0, BAG.NoteH - 4)
	note.Font = Enum.Font.FredokaOne
	note.TextColor3 = MUTED
	note.TextXAlignment = Enum.TextXAlignment.Left
	note.TextScaled = true
	note.Text = "$/s on a card is its base income, before boosts"
	note.Visible = false
	note.ZIndex = 5
	note.Parent = tray
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 12
	fit.MinTextSize = 8
	fit.Parent = note
	bagSort.note = note
end

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
-- CHOOSING A PLANT FOR THE ACTIVE SHORTCUT
--
-- The Bag's HOLD does it, and the card handlers are built long before the
-- strip code that defines it (with flashSlot), so a forward local.
--==============================================================================
local chooseShortcut: (Tool) -> ()

-- Whether the bag is open: on touch the strip steps aside while it is. The
-- `open` local that owns this lives with setOpen at the bottom of the file.
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
-- THE TWO PLANT SHORTCUTS (HotbarRoles, 2026-10-01)
--
-- Which stored plant or pod keys 4 and 5 reach. Client memory, never saved,
-- as the arrangement before it was: each a Tool AND a key -- the exact copy,
-- so two identical Nubkins are two items, and what to look for when the copy
-- dies, because a respawn destroys and rebuilds every Tool. A lost copy is
-- re-leased by key within HotbarRoles.Grace; after that the slot is let go.
--==============================================================================
local shortcuts: HotbarRoles.State = {}

-- Guards the grace re-check against stacking one timer per redraw while a
-- shortcut is waiting -- a respawn fires several redraws in a frame.
local gracePending = false

-- Plant storage as the profile last said it: the saved rows, for the Bag
-- cell's count (HotbarRoles.storage). nil until the profile has arrived.
local heldRows: number? = nil

-- Tools that have just arrived (watchContainer), to be answered by the next
-- paint with a pop on their slot or on the Bag -- except for a few seconds
-- after a spawn, when every Tool arrives at once.
local pendingArrivals: { [Tool]: boolean } = {}
local quietUntil = os.clock() + 3

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
	-- A grown plant's base $/s, in the preview well's bottom corner.
	income: TextLabel,
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
-- Whether the cards are drawn at the compact size. Set by layoutBag, off
-- HudLayout's mode; read by everything below that sizes a card's insides.
local bagCompact = false

local function fitPill(card: Card, text: string)
	-- On a phone the button IS the strip: the whole 44 px, edge to edge, instead
	-- of a 24 px pill floating inside an invisible target.
	if bagCompact then
		card.statePill.Size = UDim2.new(1, -4, 1, 0)
		return
	end
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
	-- Compact: a 98 x 32 box, 12 to 14 pt. Every name the game ships wraps to two
	-- lines at 14 pt there (the longest word, THORNWHORL, is 96 px), so the
	-- ellipsis stays what it was -- the answer for a name nobody has written yet.
	local floor = if bagCompact then 12 else 9
	local box = if bagCompact then Vector2.new(BAG.CardCompact.X - 14, 1000) else NAME_BOX
	local need = TextService:GetTextSize(text, floor, Enum.Font.LuckiestGuy, box)
	if need.Y > (if bagCompact then 32 else 26) then
		label.TextScaled = false
		label.TextSize = if bagCompact then 12 else 10
		label.TextTruncate = Enum.TextTruncate.AtEnd
	else
		label.TextTruncate = Enum.TextTruncate.None
		label.TextScaled = true
	end
end

--==============================================================================
-- ONE CARD, TWO SIZES
--
-- The grid's CellSize is the card's size; this is everything inside it that is
-- not a fraction of it. Desktop: the name 26 tall at 9-12 pt, the action strip
-- at 110 with its 24 px pill. Compact: the name 32 tall at 12-14 pt, the strip
-- at 120 with the button filling all 44 px and its word at 15 pt. The same
-- instances either way, so a relayout never duplicates a card or a connection.
--==============================================================================
local function shapeCard(card: Card)
	card.name.Size = UDim2.new(1, -14, 0, if bagCompact then 32 else 26)
	local fit = card.name:FindFirstChildOfClass("UITextSizeConstraint")
	if fit then
		fit.MaxTextSize = if bagCompact then 14 else 12
		fit.MinTextSize = if bagCompact then 12 else 9
	end
	local action = card.statePill.Parent
	if action and action:IsA("GuiObject") then
		action.Position = UDim2.new(0, 4, 0, if bagCompact then 120 else 110)
	end
	card.state.TextSize = if bagCompact then 15 else 11
	fitName(card, card.name.Text)
	fitPill(card, card.state.Text)
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
	-- ITS BASE INCOME, IN THE WELL'S CORNER
	--
	-- Inside the preview well, bottom right: clear of the name under the well,
	-- the action strip under that, and both rings, which run round the card's
	-- edge outside the well. Hugs its figure; hidden for pods, which have no
	-- income anybody may be told yet, and for weapons.
	--==========================================================================
	local income = Instance.new("TextLabel")
	income.Name = "Income"
	income.AnchorPoint = Vector2.new(1, 1)
	income.Position = UDim2.new(1, -10, 0, 79)
	income.Size = UDim2.fromOffset(0, 18)
	income.AutomaticSize = Enum.AutomaticSize.X
	income.BackgroundColor3 = BLACK
	income.BackgroundTransparency = 0.35
	income.BorderSizePixel = 0
	income.Font = Enum.Font.FredokaOne
	income.TextSize = 12
	income.TextColor3 = INCOME
	income.Text = ""
	income.Visible = false
	income.Active = false
	income.ZIndex = 8
	income.Parent = face
	UIKit.corner(income, 7)
	local incomePad = Instance.new("UIPadding")
	incomePad.PaddingLeft = UDim.new(0, 6)
	incomePad.PaddingRight = UDim.new(0, 6)
	incomePad.Parent = income

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
		income = income,
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
			-- A plant chosen here becomes the active shortcut, key 4, before it
			-- goes into the hands (2026-10-01).
			if row.kind == "plant" then
				chooseShortcut(row.tool)
			end
			holdTool(row.tool)
		end
	end)

	if bagCompact then
		shapeCard(card)
	end
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
	label: TextLabel, stroke: UIStroke, tint: UIGradient, cool: Frame } } = {}

--==============================================================================
-- ON A TOUCH SCREEN THIS COLUMN IS THE RIGHT SIDEBAR
--
-- The approved mobile redesign (HudLayout, THE PHONE'S SIDEBARS): BATS over
-- TRAPS on slate tiles in a panel that matches the dock, the equipped item's
-- model in each, and a press that opens a small CHOOSER beside it instead of
-- the Bag. The same two buttons, re-dressed by layoutHud and refreshSide; the
-- chooser is built further down, where the Bag's own controls are, and this
-- table is the one name it adds at the top level of a chunk rationed to 200.
-- The belt shows pods and plants only there, because the weapons live here.
--==============================================================================
local chooser: any = {}

local side = Instance.new("Frame")
side.Name = "Equipment"
side.AnchorPoint = Vector2.new(1, 0)
side.Position = UDim2.new(1, -RAIL.Inset, 0,
	RAIL.Inset + (RAIL.SquareSize.Y + RAIL.Gap) * 2 + 6)
side.Size = UDim2.fromOffset(64, 152)
side.BackgroundTransparency = 1
side.ZIndex = 4
side.Parent = gui
-- The sidebar's panel: the dock's fill and teal edge, drawn only on a touch
-- screen (layoutHud); transparent and edgeless everywhere else, as it was.
side.BackgroundColor3 = RAIL.DockFill
UIKit.corner(side, 14)
UIKit.stroke(side, RAIL.DockEdge, 1.5, 0.15).Enabled = false

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

	-- The sidebar's slate face, off until a touch screen asks for it; the
	-- column's own brown is the button's colour underneath. And the cooldown,
	-- which the belt's weapon cards drew until the weapons left the belt.
	local tint = UIKit.gradient(button, RAIL.TileTop, RAIL.TileBottom)
	tint.Enabled = false
	button.BackgroundColor3 = PANEL.Shade
	local cool = Instance.new("Frame")
	cool.Name = "Cooldown"
	cool.AnchorPoint = Vector2.new(0, 1)
	cool.Position = UDim2.fromScale(0, 1)
	cool.Size = UDim2.fromScale(1, 0)
	cool.BackgroundColor3 = BLACK
	cool.BackgroundTransparency = GameConfig.Hotbar.CooldownShade
	cool.BorderSizePixel = 0
	cool.Active = false
	cool.ZIndex = 7
	cool.Parent = button
	UIKit.corner(cool, 12)

	sideSlots[category] = { button = button, preview = preview,
		label = label, stroke = stroke, tint = tint, cool = cool }
end

--==============================================================================
-- THE HOTBAR (2026-10-01: roles, and the owner's reference look)
--
-- Bottom centre: five slots on a keyboard, four on a phone, and the Bag. The
-- slots are ROLES (HotbarRoles), so a key always means the same thing and an
-- empty role is a faint empty slot in its place -- nothing ever renumbers or
-- slides under a thumb:
--
--   1 bat   2 trap   3 Spin Tickets   4 the active plant or pod   5 the previous
--
-- The look is HotbarCard's, to the owner's reference image: square translucent
-- charcoal slots with a thin light edge, the item large in the middle, a small
-- white number top left, no tray, no names. Every number is GameConfig.Hotbar
-- (HOT), the compact belt laid over it on a phone (HudLayout.hotMetrics);
-- layoutHud swaps HOT on a change of face and restyleHotbar resizes what is
-- already built.
--
-- THE FRAME NAMED Hotbar IS THE STRIP, and the slots stay its direct children.
-- Two other readers depend on that shape: TutorialUI finds a plant's slot by
-- walking exactly those children for a label carrying the Tool's name -- the
-- card's hidden Name label -- and the Bag's layout stops above this frame by
-- reading its Size, so the height is written into Size and never left to
-- AutomaticSize.
--
-- NEW TOP-LEVEL NAMES ARE RATIONED: Luau refuses a chunk with more than 200
-- locals. The slot's drawing is HotbarCard's and the roles are HotbarRoles'
-- for exactly that reason; what is left here is wiring.
--==============================================================================
local HOT: any = GameConfig.Hotbar

local hotbar = Instance.new("Frame")
hotbar.Name = "Hotbar"
hotbar.AnchorPoint = Vector2.new(0.5, 1)
hotbar.Position = UDim2.new(0.5, 0, 1, -HOT.BottomGap)
hotbar.Size = UDim2.fromOffset(10, HOT.SlotHeight + HOT.TrayPad * 2)
hotbar.AutomaticSize = Enum.AutomaticSize.X
hotbar.BackgroundTransparency = 1
hotbar.BorderSizePixel = 0
hotbar.ZIndex = 4
hotbar.Parent = gui

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hotbarLayout.Padding = UDim.new(0, HOT.Gap)
hotbarLayout.Parent = hotbar

--==============================================================================
-- THE ITEM'S NAME, ABOVE THE STRIP
--
-- No name sits on a slot (the reference), so the name comes up over the strip
-- instead: for NamePopupSeconds when something goes into the hands, and for as
-- long as a mouse rests on a slot. One label in HudLayout's namePopup band,
-- which notices and the cash block keep clear of. Reduced motion: it appears
-- and goes with no fade. `announce` is defined with the held-Tool poll at the
-- bottom of the file.
--==============================================================================
local namePopup = UIKit.outlined(gui, "NamePopup", HOT.NamePopupText, CREAM, 1.5)
namePopup.AnchorPoint = Vector2.new(0.5, 1)
namePopup.Size = UDim2.fromOffset(10, HOT.NamePopupHeight)
namePopup.AutomaticSize = Enum.AutomaticSize.X
namePopup.Font = Enum.Font.FredokaOne
namePopup.Visible = false
namePopup.ZIndex = 9
local announce: (string?, boolean) -> ()
-- The slot a mouse is resting on, so a repaint that changes what it holds
-- (a sale, a respawn, a choice in the Bag) changes the name shown for it.
local hoveredSlot: number? = nil

type HotSlot = {
	card: HotbarCard.Card,
	-- The card's parts this script reads by name, so the older readers below
	-- (the cooldown tick, the drop test, LB/RB, TutorialUI) are unchanged.
	button: TextButton,
	holder: Frame,
	cooldown: Frame,
	preview: UIKit.ItemPreview,
	name: TextLabel,
	pop: UIKit.CardPop,
	tool: Tool?,
	item: WeaponData.Item?,
	-- What the preview was last set to, so a redraw builds nothing twice.
	shownKey: string,
}

local hotSlots: { HotSlot } = {}

local function acquireHotSlot(index: number): HotSlot
	local existingSlot = hotSlots[index]
	if existingSlot then
		return existingSlot
	end
	local card = HotbarCard.build(hotbar, index, HOT, 4)
	local slot: HotSlot = {
		card = card,
		button = card.button,
		holder = card.holder,
		cooldown = card.cooldown,
		preview = card.preview,
		name = card.name,
		pop = card.pop,
		tool = nil,
		item = nil,
		shownKey = "",
	}
	local button = card.button

	--==========================================================================
	-- A PLANT SLOT CAN BE PICKED UP
	--
	-- Only the two plant shortcuts: dragging one onto the other swaps them.
	-- A weapon's or the tickets' slot is a fixed role and goes nowhere.
	--==========================================================================
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.Touch
			and input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if index > activeSlots or not slot.tool then
			return
		end
		local role = HotbarRoles.roleOf(index)
		if role ~= "active" and role ~= "previous" then
			return
		end
		beginDrag({ from = "hot", index = index, label = slot.name.Text }, input)
	end)

	-- One press puts the slot's Tool in the hands; pressing the slot that is in
	-- the hands puts it away (holdTool's toggle). An empty slot does nothing.
	button.Activated:Connect(function()
		if dragMoved or index > activeSlots or not slot.tool then
			return
		end
		holdTool(slot.tool)
	end)

	-- Under a mouse the name shows for as long as the pointer rests there.
	button.MouseEnter:Connect(function()
		hoveredSlot = index
		if slot.tool and index <= activeSlots then
			announce(slot.name.Text, true)
		end
	end)
	button.MouseLeave:Connect(function()
		if hoveredSlot == index then
			hoveredSlot = nil
		end
		announce(nil, true)
	end)

	hotSlots[index] = slot
	return slot
end

--==============================================================================
-- LIFTING THE WHOLE STRIP DURING A DRAG
--
-- The drag used to raise this frame to 60 and each slot's button to 61, and left
-- everything inside them at their own numbers. Under Global ZIndexBehavior that
-- moved two layers of a dozen. So the whole subtree moves by one offset -- the
-- strip's and the painted tray's behind it, together -- and every layer goes
-- back to exactly the number it had. Anything built while the strip is up was
-- built at its resting number, and is left there.
--==============================================================================
local liftStrip: (boolean) -> ()
--==============================================================================
-- ON TOUCH, THE STRIP STEPS ASIDE WHILE THE BAG IS OPEN
--
-- On a phone the Bag needs the strip's height: HudLayout runs the panel down to
-- the safe area's bottom edge on exactly this condition (`layout.touch`), so
-- there is no strip-shaped hole left behind. Only Visible changes -- the slots,
-- their assignments, what is in the hand and every Tool reference are the same
-- objects throughout, and closing the Bag shows the same strip again at once.
--
-- It comes back for one thing: a card lifted out of the Bag. The strip is the
-- drop target, so while a card is in the air it shows, lifted over the Bag as
-- it always was, and steps aside again when the card lands. A desktop never
-- hides it at all.
--==============================================================================
local showStrip: () -> ()
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
			for _, root in ipairs({ hotbar }) do
				if root and root:IsA("GuiObject") then
					resting[root] = root.ZIndex
					root.ZIndex += LIFT
					for _, d in ipairs(root:GetDescendants()) do
						if d:IsA("GuiObject") then
							resting[d] = d.ZIndex
							d.ZIndex += LIFT
						end
					end
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
		showStrip()
	end

	showStrip = function()
		local layout = hud
		hotbar.Visible = not (bagOpen and not lifted and layout ~= nil and layout.touch)
	end
end

--==============================================================================
-- THE BAG CELL
--
-- One more square after a small gap: the approved Bag icon over plant
-- storage's count -- the saved rows plus the raid pod in both arms, out of
-- Save.MaxHeld (HotbarRoles.storage) -- green with room, a calm amber when
-- full, and "…" in slate until the profile has arrived. Tickets, bats and
-- traps never count. A door into the Bag from where the player is looking;
-- the rail button stays the Bag's home, so the Bag is reachable even with no
-- slot drawn. Dropped below HOT.ChipMinViewport.
--==============================================================================
local chip: { holder: Frame, spacer: Frame, button: TextButton, count: TextLabel,
	faceCorner: UICorner, faceStroke: UIStroke, rimCorner: UICorner, icon: ImageLabel, bump: UIScale,
	bumpTween: Tween? }
do
	local spacer = Instance.new("Frame")
	spacer.Name = "BagGap"
	spacer.LayoutOrder = MAX_SLOTS + 1
	spacer.Size = UDim2.fromOffset(HOT.BagGap, HOT.SlotHeight)
	spacer.BackgroundTransparency = 1
	spacer.BorderSizePixel = 0
	spacer.ZIndex = 4
	spacer.Parent = hotbar

	local holder = Instance.new("Frame")
	holder.Name = "BagChip"
	holder.LayoutOrder = MAX_SLOTS + 2
	holder.Size = UDim2.fromOffset(HOT.ChipWidth, HOT.SlotHeight)
	holder.BackgroundTransparency = 1
	holder.BorderSizePixel = 0
	holder.ZIndex = 4
	holder.Parent = hotbar
	local bump = Instance.new("UIScale")
	bump.Parent = holder

	local face = Instance.new("TextButton")
	face.Name = "Face"
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromScale(1, 1)
	face.BackgroundColor3 = HOT.Plate
	face.BackgroundTransparency = HOT.PlateTransparency
	face.BorderSizePixel = 0
	face.AutoButtonColor = false
	face.Text = ""
	face.ZIndex = 5
	face.Parent = holder
	local faceCorner = UIKit.corner(face, HOT.CardCorner)
	local faceStroke = UIKit.stroke(face, HOT.Edge, HOT.CardStroke, HOT.EdgeTransparency)
	UIKit.clicks(face)

	local rim = Instance.new("Frame")
	rim.Name = "Rim"
	rim.AnchorPoint = Vector2.new(0.5, 0.5)
	rim.Position = UDim2.fromScale(0.5, 0.5)
	rim.Size = UDim2.new(1, -3, 1, -3)
	rim.BackgroundTransparency = 1
	rim.BorderSizePixel = 0
	rim.ZIndex = 5
	rim.Parent = face
	local rimCorner = UIKit.corner(rim, math.max(1, HOT.CardCorner - 1.5))
	local rimStroke = UIKit.stroke(rim, HOT.Edge, 1, 1)

	local press = Instance.new("UIScale")
	press.Parent = face
	UIKit.cardPop(face, press, {
		hoverScale = HOT.HoverScale,
		pressScale = HOT.PressScale,
		glow = rimStroke,
		glowRest = 1,
		glowHover = HOT.HoverEdgeTransparency,
		lift = HOT.HoverLift,
		sound = false,
	})

	-- The rail's own approved Bag artwork, so the two doors look like one.
	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.AnchorPoint = Vector2.new(0.5, 0)
	icon.Position = UDim2.new(0.5, 0, 0, HOT.BagIconTop)
	icon.Size = UDim2.fromOffset(HOT.BagIcon, HOT.BagIcon)
	icon.BackgroundTransparency = 1
	icon.Image = RAIL.BagIcon
	icon.ScaleType = Enum.ScaleType.Fit
	icon.ZIndex = 8
	icon.Parent = face

	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.AnchorPoint = Vector2.new(0.5, 0)
	count.Position = UDim2.new(0.5, 0, 0, HOT.BagCountTop)
	count.Size = UDim2.new(1, -4, 0, HOT.BagCountSize + 4)
	count.BackgroundTransparency = 1
	count.Font = Enum.Font.FredokaOne
	count.TextSize = HOT.BagCountSize
	count.TextColor3 = HOT.CountLoading
	count.Text = ""
	count.ZIndex = 9
	count.Parent = face
	UIKit.stroke(count, HOT.Ink, HOT.NumeralOutline)

	chip = { holder = holder, spacer = spacer, button = face, count = count, faceCorner = faceCorner,
		faceStroke = faceStroke, rimCorner = rimCorner, icon = icon, bump = bump, bumpTween = nil }
end

--==============================================================================
-- A CHANGE OF FACE
--
-- HudLayout's answer carries the card's numbers as `hot`, and layoutHud swaps
-- HOT for them when the mode changes -- a phone's compact belt, or a desktop
-- window crossing into compact and back. Everything already built from the
-- old numbers is resized here: the strip's gap, the Bag cell, the popup and
-- every card made so far (HotbarCard.restyle). The previews keep their models.
-- Called from layoutHud and nowhere else; nothing here runs per frame.
--==============================================================================
local function restyleHotbar()
	hotbar.Size = UDim2.fromOffset(10, HOT.SlotHeight + HOT.TrayPad * 2)
	hotbarLayout.Padding = UDim.new(0, HOT.Gap)
	chip.spacer.Size = UDim2.fromOffset(HOT.BagGap, HOT.SlotHeight)
	chip.holder.Size = UDim2.fromOffset(HOT.ChipWidth, HOT.SlotHeight)
	chip.faceCorner.CornerRadius = UDim.new(0, HOT.CardCorner)
	chip.faceStroke.Thickness = HOT.CardStroke
	chip.rimCorner.CornerRadius = UDim.new(0, math.max(1, HOT.CardCorner - 1.5))
	chip.icon.Position = UDim2.new(0.5, 0, 0, HOT.BagIconTop)
	chip.icon.Size = UDim2.fromOffset(HOT.BagIcon, HOT.BagIcon)
	chip.count.Position = UDim2.new(0.5, 0, 0, HOT.BagCountTop)
	chip.count.TextSize = HOT.BagCountSize
	namePopup.TextSize = HOT.NamePopupText
	namePopup.Size = UDim2.fromOffset(10, HOT.NamePopupHeight)
	for _, slot in pairs(hotSlots) do
		HotbarCard.restyle(slot.card, HOT)
	end
end

--==============================================================================
-- RECONCILIATION, ONCE PER REDRAW
--
-- HotbarRoles against the Tools that exist right now: the exact copies kept,
-- lost copies re-leased by key within the grace, an empty active slot filled
-- with the newest plant. One timer, only while something is waiting out its
-- grace -- a task.delay rather than a loop, so a player standing in their
-- garden pays nothing for it.
--==============================================================================
local function reconcile(live: { Slot }): { HotbarRoles.Live }
	local entries: { HotbarRoles.Live } = {}
	for _, data in ipairs(live) do
		table.insert(entries, { tool = data.tool, key = data.key, kind = data.kind,
			order = toolOrder[data.tool] or 0 })
	end
	local waiting = HotbarRoles.reconcile(shortcuts, entries, os.clock())
	if waiting and not gracePending then
		gracePending = true
		task.delay(HotbarRoles.Grace + 0.1, function()
			gracePending = false
			redraw()
		end)
	end
	return entries
end

--==============================================================================
-- THE STRIP, PAINTED
--
-- Every live slot is drawn, empty or not, in its place: the bat, the trap,
-- the tickets, the active plant, the previous one (HotbarRoles.entryFor). A
-- slot past `activeSlots` -- the desktop's fifth, on a phone -- is hidden and
-- emptied of its Tool, so no key, bumper or cooldown tick reaches it.
--==============================================================================
local function refreshHotbar()
	local held = heldTool()
	local entries = reconcile(liveSlots)
	local still = player:GetAttribute("SeedAfterimageQuality") == "Off"
	local byTool: { [Tool]: Slot } = {}
	for _, data in ipairs(liveSlots) do
		byTool[data.tool] = data
	end

	for i = 1, math.max(activeSlots, #hotSlots) do
		local slot = hotSlots[i]
		if i > activeSlots then
			if slot then
				slot.holder.Visible = false
				slot.tool = nil
				slot.item = nil
				slot.pop.reset()
			end
		else
			slot = acquireHotSlot(i)
			local entry = HotbarRoles.entryFor(shortcuts, entries, i)
			local data: Slot? = if entry then byTool[entry.tool] else nil
			slot.holder.Visible = true
			slot.tool = if data then data.tool else nil
			slot.item = if data then data.item else nil
			local empty = data == nil
			local isHeld = data ~= nil and data.tool == held
			local stack: string? = nil
			local accent: Color3? = nil
			local shownKey = if data then data.key .. "|" .. tostring(data.tool) else "empty:" .. i
			if data then
				if slot.shownKey ~= shownKey then
					slot.preview.setModel(shownKey, builderFor(data), previewKind(data))
				end
				--==============================================================
				-- THE ACCENT COMES OFF THE TOOL, NEVER OFF A GUESS
				--
				-- A hatched plant's bar is its form's rarity colour. A pod has
				-- none: CarryService names a banked pod ??? because the species
				-- is the hatch's reveal, and a colour would name it through the
				-- back door. A plant mid-roll is a pod here too.
				--==============================================================
				if data.kind == "plant" then
					if not HatchRoll.shownHatched(data.tool) then
						accent = nil
					else
						local species = SeedData.Get(tostring(data.tool:GetAttribute("SpeciesId")))
						accent = if species then GameConfig.RarityColor[species.Rarity] else nil
					end
				elseif data.kind == "ticket" then
					-- The stack's count: the wheel's earned balance.
					stack = "x" .. tostring(math.floor(tonumber(data.tool:GetAttribute("TicketCount")) or 0))
				end
			elseif slot.shownKey ~= shownKey then
				slot.preview.setModel(shownKey, nil, "plant")
			end
			slot.shownKey = shownKey
			HotbarCard.paint(slot.card, HOT, {
				empty = empty,
				held = isHeld,
				number = tostring(i),
				stack = stack,
				accent = accent,
				name = if data then data.label else "",
			})
			HotbarCard.lift(slot.card, isHeld, still, HOT)
			-- The name under a resting mouse follows what the slot holds now.
			if hoveredSlot == i then
				announce(if data then data.label else nil, true)
			end
		end
	end

	--==========================================================================
	-- ARRIVALS: a plant that landed on a slot pops and flashes there; one that
	-- went into the Bag pops the Bag cell. Quiet after a spawn, when every
	-- Tool is rebuilt at once. Nothing under reduced motion.
	--==========================================================================
	if next(pendingArrivals) ~= nil then
		local quiet = os.clock() < quietUntil
		for tool in pairs(pendingArrivals) do
			local shown: HotSlot? = nil
			for i = 1, activeSlots do
				local candidate = hotSlots[i]
				if candidate and candidate.tool == tool then
					shown = candidate
				end
			end
			if quiet then
				-- Nothing to say: the strip is being rebuilt, not added to.
			elseif shown then
				HotbarCard.bump(shown.card, still, HOT)
				local seconds = HotbarCard.flash(shown.card, HOT.FlashArrived, HOT)
				task.delay(seconds, function()
					shown.card.flashUntil = 0
					redraw()
				end)
			elseif not still and tool:GetAttribute("SpeciesId") ~= nil then
				local running = chip.bumpTween
				if running then
					running:Cancel()
				end
				chip.bump.Scale = HOT.BumpScale
				local tween = TweenService:Create(chip.bump, TweenInfo.new(HOT.BumpSeconds,
					Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
				chip.bumpTween = tween
				tween:Play()
			end
		end
		table.clear(pendingArrivals)
	end

	--==========================================================================
	-- THE BAG CELL'S COUNT: plant storage, as the server counts it
	--==========================================================================
	local text, full, known = HotbarRoles.storage(heldRows,
		player:GetAttribute(ATTR.CarryingSpecies) ~= nil, GameConfig.Save.MaxHeld)
	chip.count.Text = text
	chip.count.TextColor3 = if not known then HOT.CountLoading
		elseif full then HOT.CountFull
		else HOT.CountOpen
	-- HudLayout's call: on a desktop the old width rule, on a phone whether the
	-- cell still fits between the thumbstick and the jump button.
	local layout = hud
	local camera = Workspace.CurrentCamera
	local roomForBag = if layout then layout.chip
		else camera ~= nil and camera.ViewportSize.X >= HOT.ChipMinViewport
	chip.holder.Visible = roomForBag
	chip.spacer.Visible = roomForBag
end

local function refreshSide()
	local docked = hud ~= nil and hud.sidebar
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
		-- On a phone the tile names the whole shelf -- it opens a chooser of
		-- every one owned -- and its edge wears the belt chip's colour.
		ui.label.Text = if docked then string.upper(category) .. "S" else string.upper(category)
		if item then
			ui.preview.setModel("w:" .. item.Id, function(parent)
				return WeaponModel.BuildPreview(item, parent)
			end, item.Category)
			ui.label.TextColor3 = CREAM
			ui.stroke.Color = if docked then HOT.Tags[category].colour else PANEL.Edge
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
		elseif docked and chooser.category == category then
			-- Its chooser is open beside it.
			ui.stroke.Color = WHITE
			ui.stroke.Thickness = 2.5
		else
			ui.stroke.Thickness = 2.5
		end
	end
	-- The chooser draws from the same two sources on the same redraw, and a
	-- weapon it just equipped goes into the hands once its Tool is here.
	if chooser.settle then
		chooser.settle()
		chooser.paint()
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
		tool:GetAttribute(ATTR.CarryingKg), HatchRoll.shownHatched(tool),
		GameConfig.incomeMultiplier(player))
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
		-- A Secret has no size tier (2026-10-02): no Size row for it at all.
		local holder = row.key.Parent
		if holder and holder:IsA("GuiObject") then
			holder.Visible = keyName ~= "Size" or details.sized
		end
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
	-- The reward wheel's Bloomrunner Trail shares the equipment shelf (below).
	-- Required here, not at the top: that chunk is rationed to 200 locals.
	local WheelData = require(Shared:WaitForChild("WheelData"))
	local trailOwned = player:GetAttribute(WheelData.Attributes.TrailOwned) == true
	if trailOwned then
		weaponCount += 1
	end
	for _, slot in ipairs(liveSlots) do
		if slot.kind == "plant" then
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
	local sortButton = bagSort.button
	if sortButton then
		sortButton.button.Visible = activeTab == "plants"
	end
	--==========================================================================
	-- THE PAD'S FOCUS STAYS ON THE PLANT IT WAS ON
	--
	-- Cards are pooled by position, so a re-sort -- a new order chosen, or a
	-- plant arriving in the middle of one -- would leave the focus ring on the
	-- same slot showing a different plant. Noted here by the Tool it was on and
	-- put back on that Tool's new card below.
	--==========================================================================
	local focusTool: Tool? = nil
	local focusOnAction = false
	do
		local focus = game:GetService("GuiService").SelectedObject
		if focus then
			for i, card in pairs(cardPool) do
				local row = cardRows[i]
				if row and (focus == card.button or focus == card.statePill.Parent) then
					focusTool = row.tool
					focusOnAction = focus ~= card.button
					break
				end
			end
		end
	end

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
		--======================================================================
		-- THE BLOOMRUNNER TRAIL (2026-09-27)
		--
		-- The reward wheel's rarest prize, worn or taken off here: this shelf is
		-- where everything a player owns and wears already lives. Read off the
		-- attributes WheelService publishes from the saved profile, so it is
		-- here after a rejoin exactly as it was left. Its row carries a stand-in
		-- item whose Category is "trail"; equipRequest sends WheelService one
		-- boolean for it, and WheelService checks ownership itself.
		--======================================================================
		if trailOwned then
			local trail = WheelData.Trail
			local worn = player:GetAttribute(WheelData.Attributes.Trail) == trail.Id
			table.insert(rows, {
				key = "c:" .. trail.Id,
				label = trail.Name,
				kind = "trail",
				-- A ribbon running mint to gold to leaf, and four petals: the trail
				-- as TrailFX draws it behind a runner, in parts for the viewport.
				build = function(parent: Instance): Model?
					local model = Instance.new("Model")
					model.Name = "BloomrunnerPreview"
					local shades = { trail.Leaf, trail.Mint, trail.Mint:Lerp(trail.Gold, 0.5), trail.Gold,
						trail.Gold:Lerp(trail.Mint, 0.4), trail.Mint }
					local pieces: { { Vector3 | CFrame | Color3 } } = {}
					for i, colour in ipairs(shades) do
						local t = i * 0.9
						table.insert(pieces, { Vector3.new(0.95, 0.56 - math.abs(i - 3.5) * 0.06, 0.08),
							CFrame.new((i - 3.5) * 0.9, math.sin(t) * 0.45, 0) * CFrame.Angles(0, 0, math.cos(t) * 0.45),
							colour })
					end
					for i, at in ipairs({ Vector3.new(-2.2, 0.9, 0.2), Vector3.new(-0.6, -0.85, 0.1),
						Vector3.new(1.1, 0.95, -0.1), Vector3.new(2.5, -0.5, 0.2) }) do
						table.insert(pieces, { Vector3.new(0.42, 0.22, 0.06),
							CFrame.new(at) * CFrame.Angles(0, 0, math.rad(30 * i)),
							if i % 2 == 0 then trail.Gold else trail.Mint })
					end
					for i, p in ipairs(pieces) do
						local part = Instance.new("Part")
						part.Name = "Piece" .. i
						part.Anchored = true
						part.CanCollide = false
						part.CanQuery = false
						part.CanTouch = false
						part.CastShadow = false
						part.Material = Enum.Material.SmoothPlastic
						part.Size = p[1] :: Vector3
						part.CFrame = p[2] :: CFrame
						part.Color = p[3] :: Color3
						part.Parent = model
					end
					model.Parent = parent
					return model
				end,
				state = if worn then "WEARING" else "TAP TO WEAR",
				lit = worn,
				item = ({ Id = trail.Id, Category = "trail", Name = trail.Name } :: any),
				tool = nil,
				canHotbar = false,
			})
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
		-- EVERY STORED PLANT IS IN THE BAG, the two on the hotbar's shortcuts
		-- included (2026-10-01): a slot points at a card, it never takes one.
		--======================================================================
		for _, slot in ipairs(liveSlots) do
			if slot.kind == "plant" then
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
					-- False while its roll runs, so PlantInfo keeps its backdrop,
					-- income and place in a sort back with a pod's.
					hatched = HatchRoll.shownHatched(slot.tool),
				})
			end
		end
		--======================================================================
		-- THE CHOSEN ORDER, IF ONE HAS BEEN CHOSEN
		--
		-- PlantInfo.Sort, the Garden's own comparator: pods after grown plants
		-- under every order, never ranked by what is inside them. Ties fall to
		-- the order this script first saw each Tool -- the one stable identity a
		-- Tool has, and one that says nothing about its species.
		--======================================================================
		PlantInfo.Sort(rows, bagSort.mode, function(row: Row): PlantInfo.SortKey
			return {
				speciesId = row.speciesId,
				tier = row.tier,
				hatched = row.hatched == true,
				id = if row.tool then toolOrder[row.tool] or 0 else 0,
			}
		end)
		-- THE SPIN TICKETS (2026-10-01), first: on the strip's own slot and
		-- here too, so the Bag always lists everything.
		for _, slot in ipairs(liveSlots) do
			if slot.kind == "ticket" then
				local count = tonumber(slot.tool:GetAttribute("TicketCount")) or 0
				table.insert(rows, 1, {
					key = slot.key,
					label = string.format("%s x%d", slot.label, count),
					kind = "ticket",
					build = builderFor(slot),
					state = if slot.tool == held then "IN HAND" else "HOLD",
					lit = slot.tool == held,
					item = nil,
					tool = slot.tool,
					canHotbar = slot.canHotbar,
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
			-- Its base income, grown plants only (PlantInfo.BaseIncome is nil for
			-- a pod and for anything that is not a plant).
			local base = if row.kind == "plant"
				then PlantInfo.BaseIncome(row.speciesId, row.tier, row.hatched == true)
				else nil
			card.income.Visible = base ~= nil
			card.income.Text = if base then "$" .. GameConfig.compact(base) .. "/s" else ""
			-- A plant's name wears its size band, the way the Garden prints it --
			-- and a Secret, which has no size tier, the Secret colour (PlantInfo).
			card.name.TextColor3 = if row.kind == "plant" and row.tier
				then PlantInfo.SizeColour(row.speciesId, row.tier)
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

	-- Put the pad's focus back on the plant it was on (see focusTool above).
	if focusTool then
		for i, row in pairs(cardRows) do
			if row.tool == focusTool then
				local card = cardPool[i]
				local target = if focusOnAction then card.statePill.Parent else card.button
				local GuiService = game:GetService("GuiService")
				if target and target:IsA("GuiObject") and GuiService.SelectedObject ~= target then
					GuiService.SelectedObject = target
				end
				break
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
	groupLimit.MinSize = Vector2.new(BAG.MinW, BAG.MinH)
end
local titlePad = modal.title.Parent and modal.title.Parent:FindFirstChildOfClass("UIPadding")

do
	--==========================================================================
	-- THE GRID: DOWNWARD ON A DESKTOP, SIDEWAYS IN WHOLE ROWS ON A PHONE
	--
	-- A vertical scroller shorter than one card row is what clipped the phone's
	-- cards: whichever way it was scrolled, part of every card was under the
	-- header or past the tray's bottom edge. Sideways, the rows are only ever
	-- whole -- HudLayout counts how many fit the tray's height, at least one --
	-- and they sit centred in it, so nothing can be cut at the top or bottom.
	-- A part card at the right edge is what says "there is more this way".
	--
	-- The scroll goes back to the start whenever the direction changes, as it
	-- already does on a tab switch and when a side slot opens the Bag.
	--==========================================================================
	local sideways: boolean? = nil

	local function shapeGrid(bag: HudLayout.Bag)
		gridLayout.FillDirectionMaxCells = if bag.horizontal then bag.rows else 0
		if sideways == bag.horizontal then
			return
		end
		sideways = bag.horizontal
		bagCompact = bag.horizontal
		grid.CanvasPosition = Vector2.zero
		grid.ScrollingDirection = if bag.horizontal
			then Enum.ScrollingDirection.X
			else Enum.ScrollingDirection.Y
		grid.AutomaticCanvasSize = if bag.horizontal
			then Enum.AutomaticSize.X
			else Enum.AutomaticSize.Y
		gridLayout.FillDirection = if bag.horizontal
			then Enum.FillDirection.Vertical
			else Enum.FillDirection.Horizontal
		gridLayout.HorizontalAlignment = if bag.horizontal
			then Enum.HorizontalAlignment.Left
			else Enum.HorizontalAlignment.Center
		gridLayout.VerticalAlignment = if bag.horizontal
			then Enum.VerticalAlignment.Center
			else Enum.VerticalAlignment.Top
		gridLayout.CellSize = UDim2.fromOffset(bag.card.X, bag.card.Y)
		for _, card in pairs(cardPool) do
			shapeCard(card)
		end
	end

	layoutBag = function()
		-- In the gui's own units (its pixels / its TV scale, 1 off a TV), which
		-- is what the strip's Offsets and HudLayout's answer are in.
		local screen = gui.AbsoluteSize / UIKit.scaleOf(gui)
		if screen.X < 100 or screen.Y < 100 then
			return
		end
		local layout = hud or HudLayout.solve(HudLayout.measure(gui))
		local bag = HudLayout.bag(layout, {
			-- The strip's top, and the name popup's band over it (2026-10-01).
			hotTop = screen.Y + hotbar.Position.Y.Offset - hotbar.Size.Y.Offset
				- HOT.NamePopupGap - HOT.NamePopupHeight,
			stripHidden = layout.touch,
			plants = activeTab == "plants",
			sideWidth = side.Size.X.Offset,
			scale = UIKit.menuScale(),
		})
		modal.group.AnchorPoint = Vector2.new(0.5, 0.5)
		modal.group.Position = UDim2.fromOffset(bag.centre.X, bag.centre.Y)
		--======================================================================
		-- THE PLAYER'S MENU SIZE, ON THIS PANEL ONLY
		--
		-- This gui is also the hotbar's, and the hotbar's place is the owner's,
		-- so the size goes on the panel: drawn bag.scale times larger and sized
		-- that many times smaller, it keeps exactly the footprint HudLayout gave
		-- it -- the free space between the rails and above the strip.
		--======================================================================
		modal.group.Size = UDim2.fromOffset(bag.panel.w / bag.scale, bag.panel.h / bag.scale)
		modal.setUserScale(bag.scale)

		--======================================================================
		-- A SHORT SCREEN PUTS THE TABS ON THE TITLE'S ROW
		--
		-- On a landscape phone a title row plus a tab row under it left less
		-- than one card row of grid. Beside the title they cost nothing: "BAG"
		-- is three letters. They stop short of the close button wherever the
		-- header has stepped it in from a rail button, not only at its resting
		-- 52 px -- on a phone the Bag button's row pushes it 27-31 px further
		-- in, which is where the Plants tab used to run under it.
		--======================================================================
		if bag.compactHeader then
			local padLeft = if titlePad then titlePad.PaddingLeft.Offset else 0
			local padRight = if titlePad then titlePad.PaddingRight.Offset else 0
			local reserve = math.max(72,
				math.ceil(modal.title.TextBounds.X / (UIKit.scaleOf(gui) * bag.scale)) + padLeft + 16)
			tabRow.Position = UDim2.fromOffset(12 + reserve, 13)
			tabRow.Size = UDim2.new(1, -(24 + reserve + 52 + padRight), 0, 34)
			modal.body.Position = UDim2.fromOffset(12, BAG.BodyTopCompact)
			modal.body.Size = UDim2.new(1, -24, 1, -BAG.BodyTrimCompact)
		else
			tabRow.Position = UDim2.fromOffset(12, 58)
			tabRow.Size = UDim2.new(1, -24, 0, 34)
			modal.body.Position = UDim2.fromOffset(12, BAG.BodyTop)
			modal.body.Size = UDim2.new(1, -24, 1, -BAG.BodyTrim)
		end

		--======================================================================
		-- BESIDE THE GRID, OR UNDER IT
		--
		-- Beside it while two columns of cards and the narrowest readable panel
		-- both fit; under it, as a lower sheet, when they do not. Plants only --
		-- the equipment tab gives its tray the whole body.
		--======================================================================
		-- The Plants tab's note strip sits over the grid, inside the tray.
		grid.Position = UDim2.fromOffset(0, bag.note)
		grid.Size = UDim2.new(1, 0, 1, -bag.note)
		local note = bagSort.note
		if note then
			note.Visible = bag.note > 0
		end

		local infoRect = bag.infoRect
		if bag.info == "none" or not infoRect then
			tray.Size = UDim2.fromScale(1, 1)
			info.Visible = false
		elseif bag.info == "sheet" then
			tray.Size = UDim2.new(1, 0, 1, -(INFO_SHEET_H + INFO_GAP))
			info.AnchorPoint = Vector2.new(0, 1)
			info.Position = UDim2.fromScale(0, 1)
			info.Size = UDim2.new(1, 0, 0, INFO_SHEET_H)
			layoutInfo("sheet")
			info.Visible = true
		else
			tray.Size = UDim2.new(1, -(infoRect.w + INFO_GAP), 1, 0)
			info.AnchorPoint = Vector2.new(1, 0)
			info.Position = UDim2.fromScale(1, 0)
			info.Size = UDim2.new(0, infoRect.w, 1, 0)
			layoutInfo(bag.info)
			info.Visible = true
		end

		shapeGrid(bag)
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
-- THE FLASH: ONE TWEEN, NO LOOP
--
-- HotbarCard colours the edge and eases its thickness back, then one redraw
-- puts the real edge back. Deliberately NOT a RenderStepped pulse: this HUD
-- runs on phones, and the repo rule is no per-frame allocation.
--==============================================================================
local function flashSlot(index: number, colour: Color3)
	local slot = hotSlots[index]
	if not slot then
		return
	end
	local seconds = HotbarCard.flash(slot.card, colour, HOT)
	task.delay(seconds, function()
		if hotSlots[index] == slot then
			slot.card.flashUntil = 0
			refreshHotbar()
		end
	end)
end

--==============================================================================
-- CHOOSING A PLANT IN THE BAG
--
-- HOLD on a plant's card makes it the active shortcut (key 4); what was active
-- becomes the previous (key 5). Nothing is moved, sold, cloned or dropped: the
-- card stays in the Bag, and the slot points at it. A plant already on a slot
-- stays where it is.
--==============================================================================
chooseShortcut = function(tool: Tool)
	for _, data in ipairs(liveSlots) do
		if data.tool == tool then
			if not data.canHotbar or HotbarRoles.holding(shortcuts, tool) ~= nil then
				return
			end
			HotbarRoles.choose(shortcuts, data.key, data.tool)
			local activeIndex = table.find(HotbarRoles.Roles, "active")
			if activeIndex then
				flashSlot(activeIndex, HOT.FlashArrived)
			end
			redraw()
			return
		end
	end
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
	if not target then
		return
	end
	local role = HotbarRoles.roleOf(target)
	if role ~= "active" and role ~= "previous" then
		return
	end

	if source.from == "bag" then
		-- The live SLOT record, not the Row: a Row key carries the tool instance
		-- so that two identical plants get separate cards, and what belongs in
		-- the shortcut is the current classification of that one copy.
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
		if role == "active" then
			HotbarRoles.choose(shortcuts, data.key, data.tool)
		else
			HotbarRoles.setPrevious(shortcuts, data.key, data.tool)
		end
		SoundKit.play("UIClick")
		flashSlot(target, HOT.FlashArrived)
		redraw()
		return
	end

	-- A plant slot dropped on the other plant slot: the two swap.
	if target ~= source.index then
		HotbarRoles.swap(shortcuts)
		SoundKit.play("UIClick")
		flashSlot(target, HOT.FlashArrived)
		redraw()
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
	-- The Bloomrunner Trail's stand-in (refreshBag): wear it if it is off, take
	-- it off if it is on. WheelService refuses it to anybody who does not own it.
	if (item :: any).Category == "trail" then
		local WheelData = require(Shared:WaitForChild("WheelData"))
		channel:FireServer(WheelData.Actions.Equip,
			player:GetAttribute(WheelData.Attributes.Trail) ~= WheelData.Trail.Id)
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
	-- Plant storage's count, for the Bag cell: the saved rows, which the server
	-- keeps one per stored plant or pod (CarryService, "snapshots only add").
	if type(profile.Held) == "table" and #profile.Held ~= heldRows then
		heldRows = #profile.Held
		changed = true
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

-- The Bloomrunner Trail's row follows WheelService's two attributes: won, and worn.
do
	local WheelData = require(Shared:WaitForChild("WheelData"))
	for _, name in ipairs({ WheelData.Attributes.TrailOwned, WheelData.Attributes.Trail }) do
		player:GetAttributeChangedSignal(name):Connect(redraw)
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

--==============================================================================
-- A TOOL THAT CHANGES WHAT IT IS REPAINTS ITS CARD
--
-- Species, size and hatched are stamped when a Tool is made and, today, never
-- change after -- but the card's name, art and income all come from them, so a
-- change must not leave a card describing what the Tool used to be. Once per
-- Tool, however often it moves between the Backpack and the hands.
--==============================================================================
local function watchTools(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") and not bagSort.watched[child] then
			bagSort.watched[child] = true
			child.AttributeChanged:Connect(function(name: string)
				-- RevealAt comes off the Tool when its roll is over: the card
				-- that was ??? is the plant from that repaint on.
				if name == "TicketCount" then
					-- The stack grew or shrank: the tickets' slot pops.
					pendingArrivals[child] = true
				end
				if name == "SpeciesId" or name == ATTR.CarryingKg or name == "Hatched" or name == "TicketCount"
					or name == HatchRoll.Attribute then
					redraw()
				end
			end)
		end
	end
end

local function watchContainer(container: Instance)
	watchTools(container)
	table.insert(containerConns, container.ChildAdded:Connect(function(child)
		watchTools(container)
		-- A Tool never seen before is an arrival (a plant hatched, a pod banked,
		-- a prize given): the next paint answers it. A Tool moving between the
		-- Backpack and the hands has an order already and is not one.
		if child:IsA("Tool") and not toolOrder[child] then
			pendingArrivals[child] = true
		end
		redraw()
	end))
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
	-- Every Tool is about to be rebuilt: none of them is an arrival.
	quietUntil = os.clock() + 3
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
	-- SINCE 2026-10-01 nothing is released. The slots are roles: a phone's
	-- four are the desktop's first four, and the previous-plant shortcut the
	-- fifth would show is kept in memory while it is hidden, so a window that
	-- widens again gets it back. The redraw hides and empties the slots past
	-- the count; no key renumbers.
	activeSlots = want
	redraw()
end

--==============================================================================
-- WHERE THE STRIP, THE BAG BUTTON AND BAT/TRAP SIT -- AND HOW MANY SLOTS
--
-- One question to HudLayout and one answer, applied to the four things this
-- script owns on the HUD, with the slot count read off the same answer -- so
-- the count and the shape can never disagree. The desktop answer is the old
-- geometry to the pixel. The compact one is a phone's: five slots of the
-- compact belt centred between the thumbstick and the jump button, the Bag in
-- the top-right corner, and BAT over TRAP against the right edge, 8 px above
-- the jump button. The answer's `hot` says which cards to draw, and a change
-- of it is a change of face (restyleHotbar).
--
-- Asked when this ScreenGui's size changes -- the viewport, the inset and a
-- rotation all land there, which is why this no longer follows the camera --
-- and when a keyboard or a touch screen comes or goes. Never per frame.
--
-- Rotating or resizing a phone keeps it compact, so the count stays five and
-- no assignment moves. Only a desktop window crossing into compact takes 6-10
-- away, and applySlotCount's rule for that is unchanged.
--==============================================================================
local function layoutHud()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local chipWas = if hud then hud.chip else nil
	local dockedWas = if hud then hud.sidebar else nil
	hud = layout
	local restyled = layout.hot ~= HOT
	if restyled then
		HOT = layout.hot
		restyleHotbar()
	end
	bagButton.Position = HudLayout.place(layout.bag, bagButton.AnchorPoint, layout.safe)
	side.Position = HudLayout.place(layout.equipment, side.AnchorPoint, layout.safe)
	-- 152 on a desktop, which is the frame it always had: 8 px of it under TRAP.
	side.Size = UDim2.fromOffset(layout.equipment.w,
		if layout.compact then layout.equipment.h else layout.equipment.h + 8)
	-- On a phone the column is the right sidebar: its panel shows, and the two
	-- tiles stand inside its padding on the dock's slate. `equipPad` is 0 and
	-- everything else as it was on a desktop and in compact.
	local pad = layout.equipPad
	side.BackgroundTransparency = if layout.sidebar then 0.2 else 1
	local sideEdge = side:FindFirstChildOfClass("UIStroke")
	if sideEdge then
		sideEdge.Enabled = layout.sidebar
	end
	for i, category in ipairs({ "bat", "trap" }) do
		local slot = sideSlots[category]
		slot.button.Position = UDim2.fromOffset(pad, pad + (i - 1) * (layout.equipSlot + layout.equipGap))
		slot.button.Size = UDim2.fromOffset(layout.equipment.w - pad * 2, layout.equipSlot)
		slot.tint.Enabled = layout.sidebar
		slot.button.BackgroundColor3 = if layout.sidebar then WHITE else PANEL.Shade
		slot.button.BackgroundTransparency = if layout.sidebar then 0.05 else 0.25
		if not layout.sidebar then
			slot.cool.Size = UDim2.fromScale(1, 0)
		end
	end
	if chooser.place then
		chooser.place(layout)
	end
	hotbar.Position = HudLayout.place(layout.hotbar, hotbar.AnchorPoint, layout.safe)
	namePopup.Position = HudLayout.place(layout.namePopup, namePopup.AnchorPoint, layout.safe)
	local count = activeSlots
	applySlotCount()
	-- applySlotCount redraws when the count changed; the Bag cell's visibility
	-- and a new face's names, chips and ghosts are drawn by the same redraw, so
	-- a change to either alone asks for one too -- and so does the belt giving
	-- up, or taking back, the weapons as the screen becomes a phone or stops.
	if count == activeSlots and (restyled or (chipWas ~= nil and chipWas ~= layout.chip)
		or (dockedWas ~= nil and dockedWas ~= layout.sidebar)) then
		redraw()
	end
	showStrip()
	layoutBag()
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutHud)
UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(layoutHud)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(layoutHud)
layoutHud()
-- Before the ScreenGui has a size there is still a count to settle on.
applySlotCount()

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
	showStrip()
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
-- SORT: ONE PRESS, THE NEXT ORDER
--
-- Default, income high, income low, rarest, name -- and round again. It orders
-- the cards and nothing else; the selection is a Tool, so it stays on its plant
-- wherever that plant lands, and refreshBag keeps the pad's focus on it too.
-- The scroll is left where it is: the player is looking at the list.
--==============================================================================
do
	local sort = bagSort.button
	if sort then
		sort.button.Activated:Connect(function()
			bagSort.mode = PlantInfo.NextSort(bagSort.mode)
			sort.set(PlantInfo.SortLabels[bagSort.mode])
			refreshBag()
		end)
	end
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
-- So can a Bonus Chest income boost starting or running out.
for _, attribute in ipairs({ GameConfig.Pass.MultiplierAttribute, GameConfig.BonusChest.Attributes.Boost,
	GameConfig.BonusChest.Attributes.EndsAt }) do
	player:GetAttributeChangedSignal(attribute):Connect(function()
		if selectedTool then
			paintInfo()
		end
	end)
end

-- The screen changing shape moves the Bag, and the title's measured width is
-- how much of its row the compact tabs may take.
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutBag)
UIKit.onMenuSize(layoutBag)
modal.title:GetPropertyChangedSignal("TextBounds"):Connect(layoutBag)
-- UIKit.modal pads the title bar clear of the rail AFTER the panel moves, so the
-- compact tab row, which is fitted between those pads, follows them.
if titlePad then
	titlePad:GetPropertyChangedSignal("PaddingLeft"):Connect(layoutBag)
	titlePad:GetPropertyChangedSignal("PaddingRight"):Connect(layoutBag)
end

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

--== A SIDE SLOT OPENS THE BAG ON ITS OWN TAB -- OR, ON A PHONE, ITS CHOOSER ==--
for _, category in ipairs({ "bat", "trap" }) do
	sideSlots[category].button.Activated:Connect(function()
		local layout = hud
		if layout and layout.sidebar then
			chooser.toggle(category)
			return
		end
		activeTab = "equipment"
		grid.CanvasPosition = Vector2.zero
		setOpen(true)
		refreshBag()
	end)
end

--==============================================================================
-- THE CHOOSER
--
-- On a touch screen BATS and TRAPS each open a small panel out of the right
-- sidebar's left side: every bat, or every trap, the player OWNS -- off the
-- profile, exactly the Bag's equipment tab -- and which one is equipped and
-- which one is in their hands. A card is one press:
--
--   EQUIP      into the slot through the one equip verb there is (the same
--              equipRequest the Bag and Marigold send, which WeaponShopService
--              validates), and into the hands the moment the server's new Tool
--              arrives. On a phone a weapon has no card on the belt, so choosing
--              one is choosing to hold it.
--   EQUIPPED   out of the Backpack and into the hands, as its belt card did.
--   IN HAND    put away.
--
-- Any press closes it, and so does a tap outside it and the sidebar, the Bag
-- or any centre panel opening, the character going, and the screen stopping
-- being a phone. It is drawn from the profile and the live Tools on every
-- redraw and keeps no copy of either.
--
-- NOTHING HERE DECIDES ANYTHING. The slot and ownership are the server's; the
-- hands are Humanoid:EquipTool on a Tool the server made, which CombatService
-- reads again on every swing and every placement.
--
-- Built inside a function, because this chunk is rationed to 200 names at the
-- top level and a do-block's names count against it while it runs.
--==============================================================================
chooser.category = nil
chooser.pending = nil
chooser.cards = {}

chooser.build = function()
	local C = HudLayout.Config.Chooser
	local frame = Instance.new("Frame")
	frame.Name = "Chooser"
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.BackgroundTransparency = 0.06
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = 4
	frame.Parent = gui
	UIKit.corner(frame, 14)
	UIKit.stroke(frame, RAIL.DockEdge, 1.5, 0.15)
	UIKit.gradient(frame, RAIL.TileTop, RAIL.DockFill)

	local title = UIKit.outlined(frame, "Title", 15, CREAM, 2)
	title.Position = UDim2.fromOffset(C.Pad, C.Pad - 3)
	title.Size = UDim2.new(1, -(C.Pad + C.Spine), 0, C.Title)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 8

	-- One row of cards, sideways; past three it scrolls, and the part card at
	-- the edge is what says so.
	local row = Instance.new("ScrollingFrame")
	row.Name = "Cards"
	row.Position = UDim2.fromOffset(C.Pad, C.Pad + C.Title)
	row.Size = UDim2.new(1, -(C.Pad + C.Spine), 0, C.Card.Y)
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.CanvasSize = UDim2.new()
	row.AutomaticCanvasSize = Enum.AutomaticSize.X
	row.ScrollingDirection = Enum.ScrollingDirection.X
	row.ScrollBarThickness = 0
	row.ElasticBehavior = Enum.ElasticBehavior.Always
	row.ZIndex = 5
	row.Parent = frame
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Horizontal
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Center
	list.Padding = UDim.new(0, C.Gap)
	list.Parent = row

	local empty = UIKit.outlined(frame, "Empty", 12, MUTED, 1.5)
	empty.Font = Enum.Font.FredokaOne
	empty.Position = row.Position
	empty.Size = row.Size
	empty.TextWrapped = true
	empty.Visible = false
	empty.ZIndex = 8

	-- The chevron down the edge toward the sidebar, which says "this shuts
	-- that way" and does.
	local spine = Instance.new("TextButton")
	spine.Name = "Close"
	spine.AnchorPoint = Vector2.new(1, 0)
	spine.Position = UDim2.fromScale(1, 0)
	spine.Size = UDim2.new(0, C.Spine, 1, 0)
	spine.BackgroundTransparency = 1
	spine.BorderSizePixel = 0
	spine.AutoButtonColor = false
	spine.Text = ""
	spine.ZIndex = 6
	spine.Parent = frame
	UIKit.clicks(spine)
	local mark = UIKit.outlined(spine, "Chevron", 16, RAIL.DockHandle, 1.5)
	mark.Font = Enum.Font.FredokaOne
	mark.Size = UDim2.fromScale(1, 1)
	mark.Text = ">"
	mark.ZIndex = 7
	spine.Activated:Connect(function()
		chooser.close()
	end)

	chooser.frame = frame
	chooser.title = title
	chooser.row = row
	chooser.empty = empty
end

-- A card, made the first time there are that many to show and kept.
chooser.card = function(i: number): any
	local made = chooser.cards[i]
	if made then
		return made
	end
	local C = HudLayout.Config.Chooser
	local button = Instance.new("TextButton")
	button.Name = "Card" .. i
	button.Size = UDim2.fromOffset(C.Card.X, C.Card.Y)
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.LayoutOrder = i
	button.ZIndex = 5
	button.Parent = chooser.row
	UIKit.corner(button, 10)
	local edge = UIKit.stroke(button, BLACK, 2)
	local tint = UIKit.gradient(button, RAIL.TileTop, RAIL.TileBottom)

	local preview = UIKit.itemPreview(button, {
		name = "Preview",
		size = UDim2.new(1, -8, 0, 44),
		position = UDim2.fromOffset(4, 4),
		scrim = 1,
	})

	-- Two lines at most, shrunk to fit before it is cut: "Cindercrack Bat" is
	-- the one that has to be read to tell two bats apart.
	local name = Instance.new("TextLabel")
	name.Name = "Name"
	name.Position = UDim2.fromOffset(3, 49)
	name.Size = UDim2.new(1, -6, 0, 23)
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.FredokaOne
	name.TextColor3 = CREAM
	name.TextScaled = true
	name.TextWrapped = true
	name.ZIndex = 8
	name.Parent = button
	UIKit.stroke(name, BLACK, 1.5, 0.2)
	local fit = Instance.new("UITextSizeConstraint")
	fit.MaxTextSize = 11
	fit.MinTextSize = 7
	fit.Parent = name

	local pill = Instance.new("Frame")
	pill.Name = "State"
	pill.AnchorPoint = Vector2.new(0.5, 1)
	pill.Position = UDim2.new(0.5, 0, 1, -4)
	pill.Size = UDim2.new(1, -8, 0, 18)
	pill.BorderSizePixel = 0
	pill.Active = false
	pill.ZIndex = 7
	pill.Parent = button
	UIKit.corner(pill, 9)
	local pillTint = UIKit.gradient(pill, PILL_ON_TOP, PILL_ON_BOTTOM)
	local word = UIKit.outlined(pill, "Text", 11, WHITE, 1.5)
	word.Font = Enum.Font.FredokaOne
	word.Size = UDim2.fromScale(1, 1)
	word.ZIndex = 8

	local card = { button = button, edge = edge, tint = tint, preview = preview,
		name = name, pillTint = pillTint, word = word, item = nil }
	button.Activated:Connect(function()
		local item = card.item
		if item then
			chooser.choose(item)
		end
	end)
	chooser.cards[i] = card
	return card
end

chooser.paint = function()
	local category = chooser.category
	local frame = chooser.frame
	if not (category and frame) then
		return
	end
	local C = HudLayout.Config.Chooser
	-- The mockup's EQUIP blue: a button that is not yet anything.
	local equipTop, equipBottom = Color3.fromRGB(70, 138, 240), Color3.fromRGB(38, 92, 196)
	chooser.title.Text = if category == "bat" then "CHOOSE BAT" else "CHOOSE TRAP"
	local held = heldTool()
	local heldItem = if held then WeaponData.Get(held:GetAttribute(ITEM_ATTR)) else nil
	local shown = 0
	for _, item in ipairs(WeaponData.Items) do
		if item.Category == category and owned[item.Id] then
			shown += 1
			local card = chooser.card(shown)
			card.item = item
			card.button.Visible = true
			card.preview.setModel("w:" .. item.Id, function(parent)
				return WeaponModel.BuildPreview(item, parent)
			end, item.Category)
			card.name.Text = item.Name
			local equipped = loadout[category] == item.Id
			local inHand = equipped and heldItem ~= nil and heldItem.Id == item.Id
			card.word.Text = if inHand then "IN HAND" elseif equipped then "EQUIPPED" else "EQUIP"
			card.pillTint.Color = if inHand then ColorSequence.new(PICKED, Color3.fromRGB(214, 160, 52))
				elseif equipped then ColorSequence.new(PILL_ON_TOP, PILL_ON_BOTTOM)
				else ColorSequence.new(equipTop, equipBottom)
			card.tint.Color = if equipped then ColorSequence.new(LIT_TOP, LIT_BOTTOM)
				else ColorSequence.new(RAIL.TileTop, RAIL.TileBottom)
			card.edge.Color = if inHand then PICKED elseif equipped then PILL_ON_TOP else BLACK
			card.edge.Thickness = if inHand then 3 else 2
		end
	end
	for i = shown + 1, #chooser.cards do
		local spare = chooser.cards[i]
		spare.button.Visible = false
		spare.item = nil
	end
	chooser.empty.Visible = shown == 0
	chooser.empty.Text = if category == "bat"
		then "No bats yet.\nMarigold sells them at her stall."
		else "No traps yet.\nMarigold sells them at her stall."

	-- As wide as what it shows, from the same right edge, never wider than
	-- HudLayout's; an empty one keeps room for its sentence.
	local layout = hud
	local most = if layout and layout.chooser then layout.chooser else nil
	if most then
		local cards = if shown == 0 then 2 else shown
		local want = C.Pad + cards * C.Card.X + (cards - 1) * C.Gap + C.Spine
		frame.Size = UDim2.fromOffset(math.min(most.w, want), most.h)
	end
end

chooser.place = function(layout: HudLayout.Layout?)
	local frame = chooser.frame
	if not frame then
		return
	end
	local most = if layout and layout.sidebar then layout.chooser else nil
	if not (layout and most) then
		chooser.close()
		return
	end
	frame.Position = HudLayout.place(most, Vector2.new(1, 0), layout.safe)
	chooser.paint()
end

chooser.open = function(category: string)
	if not chooser.frame then
		return
	end
	-- The Bag and the chooser are two ways to the same shelf; one at a time.
	if open then
		setOpen(false)
	end
	chooser.category = category
	chooser.row.CanvasPosition = Vector2.zero
	chooser.frame.Visible = true
	chooser.place(hud)
	refreshSide()
end

chooser.close = function()
	if chooser.category == nil then
		return
	end
	chooser.category = nil
	if chooser.frame then
		chooser.frame.Visible = false
	end
	refreshSide()
end

chooser.toggle = function(category: string)
	if chooser.category == category then
		chooser.close()
	else
		chooser.open(category)
	end
end

chooser.choose = function(item: WeaponData.Item)
	chooser.close()
	if loadout[item.Category] == item.Id then
		-- Already in the slot: its Tool into the hands, or out of them.
		for _, slot in ipairs(liveSlots) do
			if slot.item and slot.item.Id == item.Id then
				holdTool(slot.tool)
				redraw()
				return
			end
		end
		return
	end
	-- Into the slot, and into the hands once the server's Tool is here (settle).
	chooser.pending = { id = item.Id, before = os.clock() + 4 }
	SoundKit.play("CardClick")
	equipRequest(item)
end

-- A weapon equipped from the chooser goes into the hands when its Tool lands,
-- once, and not at all if the server said no and no Tool ever comes.
chooser.settle = function()
	local want = chooser.pending
	if not want then
		return
	end
	if os.clock() > want.before then
		chooser.pending = nil
		return
	end
	for _, slot in ipairs(liveSlots) do
		if slot.item and slot.item.Id == want.id then
			chooser.pending = nil
			if slot.tool.Parent ~= player.Character then
				holdTool(slot.tool)
			end
			return
		end
	end
end

chooser.build()
chooser.place(hud)

--==============================================================================
-- WHAT SHUTS IT, BESIDES A CHOICE AND ITS OWN CHEVRON
--
-- A tap outside it and the sidebar, read off UserInputService so the tap still
-- reaches whatever it was for -- the world, the jump button, the belt -- rather
-- than being swallowed by an invisible layer over the screen. The Bag or any
-- centre panel opening. The character going.
--==============================================================================
UserInputService.InputBegan:Connect(function(input: InputObject)
	if chooser.category == nil then
		return
	end
	local kind = input.UserInputType
	if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1 then
		return
	end
	local point = Vector2.new(input.Position.X, input.Position.Y)
	for _, keep in ipairs({ chooser.frame, side }) do
		local at, size = keep.AbsolutePosition, keep.AbsoluteSize
		if point.X >= at.X and point.X <= at.X + size.X
			and point.Y >= at.Y and point.Y <= at.Y + size.Y then
			return
		end
	end
	chooser.close()
end)
player:GetAttributeChangedSignal(ATTR.OpenPanel):Connect(function()
	if player:GetAttribute(ATTR.OpenPanel) ~= nil then
		chooser.close()
	end
end)
player.CharacterRemoving:Connect(function()
	chooser.close()
end)

--==============================================================================
-- THE NUMBER ROW
--
-- Bound here because turning the CoreGui Backpack off takes its bindings with
-- it. ContextActionService rather than UserInputService so a text box has
-- priority over this and typing "1" in chat does not swap weapons.
--==============================================================================
-- Five keys for five roles (2026-10-01); 6 to 0 are not bound at all.
local KEYS = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four,
	Enum.KeyCode.Five,
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
-- LB AND RB: THE NUMBER ROW, FOR A CONTROLLER
--
-- Turning the CoreGui Backpack off took its bumpers with it, exactly as it took
-- the number keys, and only the keys were put back -- so a controller had no way
-- at all to change what was in the player's hands. These walk the SAME strip
-- the number row reads, in its on-screen order: the next or previous slot that
-- actually holds something, wrapping at either end, equipped the moment it is
-- reached.
--
-- ONE STEP PER PRESS. Bound on Begin only, so a held bumper does not spin the
-- strip. A slot already in the hands is not toggled off when it is the only
-- thing on the strip -- a bumper walks, it never puts away.
--
-- NOTHING WHILE A PANEL IS UP. A bumper pressed with the Shop, the Bag or any
-- other centre panel open must not swap the tool behind it; PadInput answers
-- "is a panel open" for every panel, including the ones not on OpenPanel.
--
-- In a do-block because this chunk's local names are rationed.
--==============================================================================
do
	local PadInput = require(Shared:WaitForChild("PadInput"))

	local function occupiedSlots(): { number }
		local out: { number } = {}
		for i = 1, activeSlots do
			local slot = hotSlots[i]
			if slot and slot.button.Visible and slot.tool and slot.tool.Parent then
				table.insert(out, i)
			end
		end
		return out
	end

	ContextActionService:BindAction("SeedHotbarCycle", function(_, state, input)
		if state ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end
		if PadInput.panelOpen() then
			return Enum.ContextActionResult.Pass
		end
		local held = heldTool()
		-- From the slot in the hands, or from just outside either end when the
		-- hands are empty (or hold something the strip is not showing).
		local target = PadInput.nextSlot(occupiedSlots(), if held then hotbarSlotOf(held) else nil,
			if input.KeyCode == Enum.KeyCode.ButtonR1 then 1 else -1)
		if not target then
			return Enum.ContextActionResult.Sink
		end
		local slot = hotSlots[target]
		if slot and slot.tool and slot.tool ~= held then
			holdTool(slot.tool)
			redraw()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
end

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
			--==========================================================
			-- THE TRAP'S OWN COOLDOWN, NOT "THE TRAP'S"
			--
			-- Five traps, five cooldowns, from 15 seconds to 30. The bar drains
			-- over the one this slot's item actually has, so a Starlock does not
			-- draw a Bramblejaw's clock.
			--==========================================================
			local total = slot.item.Cooldown
			if slot.item.Category == "trap" then
				local spec = WeaponData.TrapSpec(slot.item)
				total = if spec then spec.PlaceCooldownSeconds else 0
			end
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
	--==========================================================================
	-- AND ON A PHONE, THE SIDEBAR'S TWO TILES
	--
	-- The weapons left the belt there, and their cooldown came with them: the
	-- same drain, off the equipped Tool's own ReadyAt and its own cooldown, in
	-- this same pass. Nothing is allocated for it.
	--==========================================================================
	local layout = hud
	if layout and layout.sidebar then
		for category, ui in pairs(sideSlots) do
			local left, total = 0, 0
			for _, live in ipairs(liveSlots) do
				local item = live.item
				if item and item.Category == category then
					total = item.Cooldown
					if category == "trap" then
						local spec = WeaponData.TrapSpec(item)
						total = if spec then spec.PlaceCooldownSeconds else 0
					end
					local readyAt = tonumber(live.tool:GetAttribute(READY_AT))
					left = if readyAt then readyAt - now else 0
					break
				end
			end
			local share = if left > 0 and total > 0 then math.min(1, left / total) else 0
			if ui.cool.Size.Y.Scale ~= share then
				ui.cool.Size = UDim2.fromScale(1, share)
			end
		end
	end
end)

-- Reduced effects puts a lifted in-hand card back at rest, now rather than at
-- the next time the hands change.
player:GetAttributeChangedSignal("SeedAfterimageQuality"):Connect(function()
	redraw()
end)

--==============================================================================
-- THE NAME POPUP (2026-10-01)
--
-- `announce(text, sticky)`: sticky is a mouse resting on a slot -- the name
-- stays until the pointer leaves -- and not sticky is an equip, which stays
-- NamePopupSeconds. Reduced motion (the game's REDUCED FX, or Roblox's own
-- setting): no fade, it is simply there and then not.
--==============================================================================
do
	local shownUntil = 0
	local hovering: string? = nil
	local fade: Tween? = nil
	local edge = namePopup:FindFirstChildOfClass("UIStroke")

	local function still(): boolean
		if player:GetAttribute("SeedAfterimageQuality") == "Off" then
			return true
		end
		local ok, value = pcall(function()
			return (game:GetService("GuiService") :: any).ReducedMotionEnabled
		end)
		return ok and value == true
	end
	local function show(text: string)
		if fade then
			fade:Cancel()
			fade = nil
		end
		namePopup.Text = text
		namePopup.TextTransparency = 0
		if edge then
			edge.Transparency = 0
		end
		namePopup.Visible = true
	end
	local function hide()
		if fade then
			fade:Cancel()
			fade = nil
		end
		if still() then
			namePopup.Visible = false
			return
		end
		local tween = TweenService:Create(namePopup, TweenInfo.new(0.2), { TextTransparency = 1 })
		if edge then
			TweenService:Create(edge, TweenInfo.new(0.2), { Transparency = 1 }):Play()
		end
		fade = tween
		tween.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Completed then
				namePopup.Visible = false
			end
		end)
		tween:Play()
	end
	announce = function(text: string?, sticky: boolean)
		if sticky then
			hovering = text
			if text then
				show(text)
			elseif os.clock() >= shownUntil then
				hide()
			end
			return
		end
		if text == nil or text == "" then
			return
		end
		show(text)
		shownUntil = os.clock() + HOT.NamePopupSeconds
		task.delay(HOT.NamePopupSeconds, function()
			if os.clock() < shownUntil then
				return
			end
			local over = hovering
			if over then
				show(over)
			else
				hide()
			end
		end)
	end
end

--== The held Tool changing is a redraw: it is what the warm ring shows. ==--
-- And since 2026-10-01 the feedback: the item's name over the strip, and a
-- pop on its slot (none under reduced motion).
task.spawn(function()
	local lastHeld: Tool? = nil
	while true do
		local held = heldTool()
		if held ~= lastHeld then
			lastHeld = held
			redraw()
			if held then
				announce(held.Name, false)
				local still = player:GetAttribute("SeedAfterimageQuality") == "Off"
				local at = hotbarSlotOf(held)
				local slot = if at then hotSlots[at] else nil
				if slot then
					HotbarCard.bump(slot.card, still, HOT)
				end
			end
		end
		task.wait(0.15)
	end
end)

redraw()
