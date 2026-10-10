--!strict
-- Steal a Seed :: LoadoutUI
--
-- The Bag and the hotbar. One script, on purpose.
--
--==============================================================================
-- ONE OWNER FOR "WHAT IS IN YOUR HANDS"
--
-- Two surfaces showing the same facts -- what you own and what is in your hands
-- -- and they cannot disagree, because there is one script and its sources of
-- truth are not local state:
--
--   THE PROFILE PACKET   what is owned (the saved plants and pods, by item id;
--                        the bats and traps; the Spin Tickets), the HOTBAR --
--                        ten shortcuts saved by item id -- and the hearts.
--                        Server-authored, replicated.
--   THE LIVE TOOLS       what is actually in the Backpack and the Character.
--
-- What is in the hands is the Tool parented to the Character: no "selected"
-- variable. The one thing this file keeps of its own is an EDIT the server has
-- not answered yet (the bar a drag just made, a heart just pressed), drawn at
-- once and dropped for the server's copy when that comes back.
--
--==============================================================================
-- THE FREELY ASSIGNABLE HOTBAR (2026-10-03, the owner's spec)
--
-- Any eligible item can sit in any slot: ten on a desktop (keys 1-9 and 0),
-- five on a phone. A slot is a SHORTCUT to something owned (HotbarSlots), never
-- a copy: an item on the bar stands in the grid too, wearing its slot's number
-- (2026-10-10; left out of it before). The bar is saved on the server by item id, so it
-- survives a respawn and a rejoin; arrivals -- a hatch, a pickup, a banked pod,
-- a prize, a new bat -- go to the first empty shown slot (or the faint slot
-- waiting for their kind), else into the grid. The Bag is a compact grid of
-- small tiles (InventoryPanel), with categories, search and a favourites heart.
--
--==============================================================================
-- THE CLIENT DECIDES NOTHING IT IS NOT ALLOWED TO
--
-- The bar and the hearts are a server write (InventoryService), checked against
-- what is owned there. Equipping a bat or a trap is the shop's own verb
-- (WeaponShopService). Changing which Tool is IN YOUR HANDS is `EquipTool` on an
-- object the server already gave you, which the server re-checks anyway.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
-- Whether a hatched plant may be named yet: while its roll runs it is drawn as
-- the pod it came out of (2026-09-29).
local HatchRoll = require(Shared:WaitForChild("HatchRoll"))
-- Where the strip, the Bag button and the Bag sit on this screen, and how many
-- slots it gets. Numbers only; see layoutHud near the bottom of this file.
local HudLayout = require(Shared:WaitForChild("HudLayout"))
-- How one slot is drawn (HotbarCard), the hotbar's grammar (HotbarSlots), what
-- the Bag shows (InventoryModel) and draws (InventoryPanel), the pictures
-- (ItemArt) and what a press meant (PressGesture). Out of this chunk, which is
-- rationed to 200 locals.
local HotbarCard = require(Shared:WaitForChild("HotbarCard"))
local HotbarSlots = require(Shared:WaitForChild("HotbarSlots"))
local InventoryModel = require(Shared:WaitForChild("InventoryModel"))
local InventoryPanel = require(Shared:WaitForChild("InventoryPanel"))
local MenuKit = require(Shared:WaitForChild("MenuKit"))
local ItemArt = require(Shared:WaitForChild("ItemArt"))
local PressGesture = require(Shared:WaitForChild("PressGesture"))
local RarityFX = require(Shared:WaitForChild("RarityFX"))
-- A trap's placements ("3x") and the REMOVE button over its slot (2026-10-04):
-- the server's count off the owner's trap records, and the press.
local TrapRemove = require(Shared:WaitForChild("TrapRemove"))
-- What the Instant Hatch product costs THIS player (2026-10-09, the Bag's button).
local RobuxPrice = require(Shared:WaitForChild("RobuxPrice"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local ATTR = GameConfig.Attributes
local W = GameConfig.Weapon
-- Pods hatch in the Bag (2026-10-09): the verbs, words and icons.
local HATCH_BAG = GameConfig.HatchInBag
local INV = GameConfig.Inventory
local PANEL_NAME = "Bag"
local CREAM = Color3.fromRGB(242, 238, 206)
local READY_AT = "ReadyAt"
local BAG = HudLayout.Config.Bag

--==============================================================================
-- TEN OR FIVE, DECIDED BY HudLayout
--
-- Ten on a desktop and a TV (keys 1-9 and 0); five on a touch screen, which is
-- what a thumb can cross without looking at 52 px a slot; a small desktop
-- window ten while the compact strip fits, else five. Read off the same answer
-- that places the strip, so the count and the shape never disagree. The rule
-- below is only the stand-in for the moment before the ScreenGui has a size.
--==============================================================================
local DESKTOP_SLOTS = HudLayout.Config.DesktopSlots
local MOBILE_SLOTS = HudLayout.Config.MobileSlots
local MAX_SLOTS = DESKTOP_SLOTS

-- How many slots are LIVE right now. Everything reads this; nothing assumes a
-- number. Slots past it are hidden, and their items show in the Bag's grid with
-- a slot badge.
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

local function heldTool(): Tool?
	local character = player.Character
	return if character then character:FindFirstChildOfClass("Tool") else nil
end

--==============================================================================
-- PUTTING SOMETHING IN THE PLAYER'S HAND
--
-- The ONE place this client equips anything. Named `holdTool` rather than
-- `select` because `select` is a Lua builtin. `nil`, or the Tool already in
-- hand, puts it away. Answers whether the hands changed.
--==============================================================================
local function holdTool(tool: Tool?): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return false
	end
	if tool == nil or tool.Parent == character then
		SoundKit.play("CardClick")
		humanoid:UnequipTools()
		return true
	end
	--==========================================================================
	-- NOTHING WHILE A POD IS IN BOTH ARMS
	--
	-- A plant rides in the same two-handed grip as a raid pod, so equipping one
	-- over a carry drew the plant through the shell; and since 2026-10-10 (the
	-- owner, on Michael's v1047 report) the bat and the traps wait too: a
	-- carrier's hands are full, and the server puts back anything equipped onto
	-- a carry (CarryService.PutToolsAway). Said, not just buzzed: the toast
	-- names the rule (ActionToastUI), off the server's own replicated
	-- CarryingSpecies. Required here rather than at the top: names are rationed.
	--==========================================================================
	if player:GetAttribute(ATTR.CarryingSpecies) ~= nil then
		require(Shared:WaitForChild("ActionRefusal")).raise("CARRYING_POD")
		return false
	end
	--==========================================================================
	-- NOT A PLANT WHOSE ROLL IS STILL RUNNING (2026-09-29)
	--
	-- In the hands it is the plant itself, at full size, for everybody to see:
	-- the one thing its roll is keeping back. The server puts it in their hands
	-- when the reveal is over.
	--==========================================================================
	if HatchRoll.sealed(tool) then
		SoundKit.play("CardClick")
		return false
	end
	SoundKit.play("CardClick")
	humanoid:EquipTool(tool)
	return true
end

--==============================================================================
-- STATE OFF THE PROFILE, AND THE EDITS THE SERVER HAS NOT ANSWERED YET
--
-- `prof` is the last packet's: the rows, the weapons, the ticket balance, the
-- hearts, the refs it owned (the baseline arrivals are found against), and the
-- wheel prizes waiting for room. `bar` is the server's saved bar with the
-- client's pending edit on top; `favPending` the hearts pressed and not yet
-- answered. `equipPending` a weapon asked of the server, to be held when its
-- Tool lands. `assign` a phone's "Assign to slot". `sealedUntil` remembers each
-- item's RevealAt across a respawn (InventoryModel.collect fills it).
--==============================================================================
local prof = {
	heard = false,
	held = nil :: { any }?,
	weapons = {} :: { [string]: boolean },
	tickets = 0,
	favourites = {} :: { [string]: boolean },
	owned = nil :: { [string]: boolean }?,
	-- Creatures in the ground: their slots give way to an arrival (HotbarSlots.arrive).
	planted = {} :: { [string]: boolean },
	waiting = 0,
}
local bar = { server = HotbarSlots.empty(), pending = nil :: { string }?, seq = 0, queued = false }
local favPending: { [string]: boolean } = {}
local equipPending = { id = nil :: string?, untilAt = 0 }
local assign = { ref = nil :: string?, name = "" }
-- Pods hatch in the Bag (2026-10-09): the Instant Hatch product's price for THIS
-- player (RobuxPrice; nil until Roblox has said, and then no price is shown),
-- how many pods were READY at the last redraw, and whether any still grows.
local podsNow = { price = nil :: number?, ready = 0, growing = false, readyKeys = "", nextTick = 0 }
local sealedUntil: { [string]: number } = {}
-- What the last redraw collected: every owned item, by ref, and the Bag's
-- groups by key.
local view = {
	items = {} :: { InventoryModel.Item },
	byRef = {} :: { [string]: InventoryModel.Item },
	byKey = {} :: { [string]: InventoryModel.Group },
}

local function shownBar(): { string }
	return bar.pending or bar.server
end

local function slotWord(i: number): string
	return if i == 10 then "0" else tostring(i)
end

--==============================================================================
-- THE BAG BUTTON (centre left, under Garden -- beside it on a phone), and THE PANEL
--==============================================================================
local bagButton = UIKit.railButton(playerGui, {
	name = "BagButton",
	icon = RAIL.BagIcon,
	wide = false,
	bare = true,
	-- BAG on a plate until the satchel has loaded here (UIKit.railFallback).
	fallback = RAIL.Words.Bag,
})
-- Anchored the way GardenUI anchors Garden's; HudLayout places both (layoutHud).
bagButton.AnchorPoint = Vector2.new(1, 0)
bagButton.Position = UDim2.new(1, -RAIL.Inset, 0,
	RAIL.Inset + RAIL.SquareSize.Y + RAIL.Gap)

-- The Bag's shell is the studded kit's (2026-10-08, the owner: "do the index
-- and bag next"): the kit's cyan Trade Inventory band with the satchel and a
-- white title, a white studded body and a base in the band's edge colour
-- (MenuKit.studdedTheme, GameConfig.StuddedLook.Bag). A band has no lift, so
-- InventoryPanel's layout takes nothing back off its rects.
local modal = UIKit.modal(gui, {
	name = PANEL_NAME,
	title = "Bag",
	maxWidth = BAG.MaxW,
	maxHeight = BAG.MaxH,
	titleColour = GameConfig.StuddedLook.Title,
	theme = MenuKit.studdedTheme(GameConfig.StuddedLook.Bag),
})

--==============================================================================
-- FORWARD-DECLARED, AND THAT IS NOT STYLE
--
-- Handlers built near the top call these, and they are defined further down.
-- Written as bare `function x()` they would be GLOBALS, resolved as such by the
-- closures above them -- which works right up until somebody moves a line.
--==============================================================================
local redraw: () -> ()
local layoutBag: () -> ()
local beginDrag: (any, InputObject) -> ()
local cancelDrag: () -> ()
local editBar: ({ string }) -> ()
local holdRef: (string) -> boolean
local activateKey: (string, string) -> ()
local openMenuFor: (string?, number?, HudLayout.Rect) -> ()
local endAssign: () -> ()
local bagOpen = false
local dragMoved = false
local channel: RemoteEvent? = nil
-- Made once `redraw` exists, below THE STRIP, PAINTED.
local trapRemove: TrapRemove.Handle? = nil

local panel = InventoryPanel.build(gui, modal, GameConfig.Hotbar, {
	activate = function(key: string, by: string)
		activateKey(key, by)
	end,
	menu = function(key: string, anchor: HudLayout.Rect)
		openMenuFor(key, nil, anchor)
	end,
	canDrag = function(key: string): boolean
		local group = view.byKey[key]
		local item = if group then InventoryModel.pick(group) else nil
		return item ~= nil and item.ref ~= nil and not item.restoring
	end,
	dragBegin = function(key: string, input: InputObject)
		local group = view.byKey[key]
		local item = if group then InventoryModel.pick(group) else nil
		if item and item.ref then
			beginDrag({ from = "bag", ref = item.ref, label = group.face.name }, input)
		end
	end,
	describe = function(key: string): (string?, { InventoryModel.Line }?)
		local group = view.byKey[key]
		local item = if group then InventoryModel.pick(group) else nil
		if not (group and item) then
			return nil, nil
		end
		local held = heldTool()
		return group.face.name, InventoryModel.details(item, group.face, nil,
			if item.ref then HotbarSlots.slotOf(shownBar(), item.ref) else nil,
			held ~= nil and item.tool == held, Workspace:GetServerTimeNow())
	end,
	changed = function()
		redraw()
	end,
	-- HATCH ALL, held to the end (2026-10-09): every READY pod in the Bag.
	hatchAll = function()
		local remote = channel
		if remote then
			remote:FireServer(HATCH_BAG.HatchAll)
		end
	end,
})

--==============================================================================
-- THE HOTBAR (the owner's reference look, 2026-10-01)
--
-- Bottom centre: ten slots on a keyboard, five on a phone, and the Bag cell.
-- A slot is HotbarCard's square: translucent charcoal, a thin light edge, the
-- item large in the middle, a small white number top left (0 for the tenth).
-- An empty slot is a faint empty square in its place, and a FAINT slot waiting
-- for the first bat, trap or tickets says so in small type.
--
-- THE FRAME NAMED Hotbar IS THE STRIP, and the slots stay its direct children:
-- TutorialUI finds a plant's slot by walking exactly those children for a label
-- carrying the Tool's name -- the card's hidden Name label -- and the Bag's
-- layout stops above this frame by reading its Size.
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
-- long as a mouse rests on a slot -- and, on a phone assigning, the line saying
-- which item is waiting for a slot. `announce` is defined at the bottom.
--==============================================================================
local namePopup = UIKit.outlined(gui, "NamePopup", HOT.NamePopupText, CREAM, 1.5)
namePopup.AnchorPoint = Vector2.new(0.5, 1)
namePopup.Size = UDim2.fromOffset(10, HOT.NamePopupHeight)
namePopup.AutomaticSize = Enum.AutomaticSize.X
namePopup.Font = Enum.Font.FredokaOne
namePopup.Visible = false
namePopup.ZIndex = 9
local announce: (string?, boolean) -> ()
-- The slot a mouse is resting on, so a repaint changes the name shown for it.
local hoveredSlot: number? = nil

type HotSlot = {
	card: HotbarCard.Card,
	button: TextButton,
	holder: Frame,
	cooldown: Frame,
	preview: any,
	name: TextLabel,
	pop: any,
	-- What the slot holds now: its ref, the live Tool, and the weapon (for the
	-- cooldown tick).
	ref: string,
	tool: Tool?,
	item: WeaponData.Item?,
	shownKey: string,
}

local hotSlots: { HotSlot } = {}

-- The name a player knows an item by: the visible face's, never a pod's species.
local function visibleName(item: InventoryModel.Item?): string
	return if item then InventoryModel.face(item).name else ""
end

local function acquireHotSlot(index: number): HotSlot
	local existingSlot = hotSlots[index]
	if existingSlot then
		return existingSlot
	end
	local card = HotbarCard.build(hotbar, index, HOT, 4)
	-- A rarity's light never moves on a strip that is not on screen.
	card.fxEdge.gate = hotbar
	local slot: HotSlot = {
		card = card,
		button = card.button,
		holder = card.holder,
		cooldown = card.cooldown,
		preview = card.preview,
		name = card.name,
		pop = card.pop,
		ref = "",
		tool = nil,
		item = nil,
		shownKey = "",
	}
	local button = card.button
	local press: PressGesture.Press? = nil
	-- One press, one action: a click may arrive as InputBegan, Activated,
	-- InputEnded or with Activated last (InventoryPanel's rule, the same here).
	local handled = false
	local lastHandled = 0

	--==========================================================================
	-- ONE PRESS: what PressGesture says it was
	--
	--   tap (a click, a thumb, A on a pad)   hold what the slot names, or put it
	--                                        away -- or, while a phone assigns,
	--                                        put the waiting item here
	--   a mouse dragged 8 px                 carry the shortcut: onto another
	--                                        slot swaps, onto the Bag removes it
	--   a thumb held 0.45 s, a right-click   the slot's menu (the only way a
	--                                        phone can take a shortcut away)
	--==========================================================================
	local function pressSlot()
		if index > activeSlots then
			return
		end
		local waiting = assign.ref
		if waiting then
			local new = HotbarSlots.assign(shownBar(), waiting, index)
			editBar(new)
			endAssign()
			return
		end
		local ref = slot.ref
		local kind, category = HotbarSlots.parse(ref)
		if kind == "placeholder" then
			-- A faint slot holds nothing; it says what it is waiting for.
			SoundKit.play("CardClick")
			local words = { bat = "your bat", trap = "your trap", ticket = "your Spin Tickets" }
			announce("Slot for " .. (words[category or ""] or "an item"), false)
			return
		end
		if ref ~= "" then
			holdRef(ref)
		end
	end
	button.InputBegan:Connect(function(input)
		local kind = input.UserInputType
		local by = if kind == Enum.UserInputType.Touch then "touch"
			elseif kind == Enum.UserInputType.MouseButton1 then "mouse"
			else nil
		if not by or index > activeSlots then
			return
		end
		local p = PressGesture.begin(by, Vector2.new(input.Position.X, input.Position.Y), Vector2.zero,
			os.clock(), by == "mouse" and slot.ref ~= "" and assign.ref == nil)
		press = p
		handled = false
		if by == "touch" then
			task.delay(PressGesture.LongPress, function()
				if press == p and not handled and PressGesture.step(p, nil, nil, os.clock()) == "long"
					and assign.ref == nil then
					handled = true
					openMenuFor(nil, index, { x = button.AbsolutePosition.X / UIKit.scaleOf(gui),
						y = button.AbsolutePosition.Y / UIKit.scaleOf(gui), w = HOT.SlotWidth, h = HOT.SlotHeight })
				end
			end)
		end
	end)
	button.InputChanged:Connect(function(input)
		local p = press
		local kind = input.UserInputType
		if not p or handled or (kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseMovement) then
			return
		end
		local was = p.state
		if PressGesture.step(p, Vector2.new(input.Position.X, input.Position.Y), nil, os.clock()) == "drag"
			and was ~= "drag" then
			handled = true
			beginDrag({ from = "slot", index = index, label = visibleName(view.byRef[slot.ref]) }, input)
		end
	end)
	button.InputEnded:Connect(function(input)
		local kind = input.UserInputType
		if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1 then
			return
		end
		local p = press
		press = nil
		if not p then
			return
		end
		lastHandled = os.clock()
		if handled then
			return
		end
		handled = true
		if not dragMoved and PressGesture.release(p, Vector2.new(input.Position.X, input.Position.Y), nil,
			os.clock()) == "tap" then
			pressSlot()
		end
	end)
	button.Activated:Connect(function()
		local p = press
		if p then
			-- Mid-press: answered here only while it is still a plain press.
			if handled or dragMoved or PressGesture.step(p, nil, nil, os.clock()) ~= "pressing" then
				return
			end
			handled = true
			pressSlot()
			return
		end
		-- No press: a controller's A on a selected slot, unless one just ended.
		if os.clock() - lastHandled < 0.15 or dragMoved then
			return
		end
		pressSlot()
	end)
	button.MouseButton2Click:Connect(function()
		if index <= activeSlots and slot.ref ~= "" then
			openMenuFor(nil, index, { x = button.AbsolutePosition.X / UIKit.scaleOf(gui),
				y = button.AbsolutePosition.Y / UIKit.scaleOf(gui), w = HOT.SlotWidth, h = HOT.SlotHeight })
		end
	end)

	-- Under a mouse the name shows for as long as the pointer rests there.
	button.MouseEnter:Connect(function()
		hoveredSlot = index
		local item = view.byRef[slot.ref]
		if item and index <= activeSlots then
			announce(visibleName(item), true)
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
-- LIFTING THE WHOLE STRIP OVER THE BAG
--
-- While a tile is carried to it, and while a phone picks a slot for an item
-- (assign mode), the strip is the target: the whole subtree moves up by one
-- offset and every layer goes back to exactly the number it had. Anything built
-- while the strip is up was built at its resting number, and is left there.
--
-- ON TOUCH, THE STRIP STEPS ASIDE WHILE THE BAG IS OPEN: HudLayout runs the
-- panel down to the safe area's bottom edge on exactly this condition
-- (`layout.touch`). Only Visible changes; the strip comes back for a lift.
--==============================================================================
local liftStrip: (boolean) -> ()
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
		-- REMOVE stands with the strip, and steps aside while the strip is a
		-- drop target (a drag, a phone's assignment).
		local remove = trapRemove
		if remove then
			remove.strip(hotbar.Visible and not lifted)
		end
	end
end

--==============================================================================
-- THE BAG CELL
--
-- One more square after a small gap: the approved Bag icon over plant
-- storage's count -- the saved rows plus the raid pod in both arms, out of
-- Save.MaxHeld (HotbarSlots.storage) -- green with room, a calm amber when
-- full, and "…" in slate until the profile has arrived. A door into the Bag,
-- and a drop target: a shortcut dragged onto it is taken off the bar.
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
	-- The slots' thin edge, drawn: a TextButton's default strokes its text.
	faceStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
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

	-- The rail's own approved Bag artwork, so the two doors look like one --
	-- or, once uploaded, the satchel of the approved category art (2026-10-03).
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
	-- BAG where the icon stands until a picture has loaded here (2026-10-09,
	-- the owner: "some buttons are invisible like the garden and inventory"):
	-- hidden once the rail's art or the satchel has loaded, kept for good if
	-- neither ever does. A child the icon's size, so the restyle moves it too.
	local iconWord = UIKit.outlined(icon, "Word", RAIL.FallbackTextMax, Color3.new(1, 1, 1), 1.5)
	iconWord.Size = UDim2.fromScale(1, 1)
	iconWord.TextScaled = true
	iconWord.Text = RAIL.Words.Bag
	iconWord.ZIndex = icon.ZIndex + 2
	do
		local fit = Instance.new("UITextSizeConstraint")
		fit.MaxTextSize = RAIL.FallbackTextMax
		fit.MinTextSize = RAIL.FallbackTextMin
		fit.Parent = iconWord
	end
	UIKit.whenPictureLoads(icon, function(loaded: boolean)
		if loaded then
			iconWord.Visible = false
		end
	end)
	-- THE OWNER'S TILE IS THE CELL (2026-10-09, the owner: "yes, hotbar bag
	-- cell too", and drop the cell's plate "so only the owner's tile shows").
	-- BagIconImage is a whole studded button, so it is drawn square, centred
	-- and as large as the cell, over the plate and the rail's satchel and under
	-- the count and READY. Once it has loaded here the plate, its edge, the
	-- satchel and BAG go; until then they stay, and for good if it never loads
	-- or the slot is "" -- a picture is never hidden on a timeout. Sized off
	-- the cell itself, so the restyle needs nothing more for it.
	if HOT.BagIconImage ~= "" then
		local tile = Instance.new("ImageLabel")
		tile.Name = "Satchel"
		tile.AnchorPoint = Vector2.new(0.5, 0.5)
		tile.Position = UDim2.fromScale(0.5, 0.5)
		tile.Size = UDim2.fromScale(1, 1)
		tile.BackgroundTransparency = 1
		tile.Image = HOT.BagIconImage
		tile.ScaleType = Enum.ScaleType.Fit
		tile.ZIndex = icon.ZIndex - 1
		tile.Parent = face
		local square = Instance.new("UIAspectRatioConstraint")
		square.AspectRatio = 1
		square.Parent = tile
		UIKit.whenPictureLoads(tile, function(loaded: boolean)
			if loaded then
				icon.ImageTransparency = 1
				iconWord.Visible = false
				face.BackgroundTransparency = 1
				faceStroke.Transparency = 1
			end
		end)
	end

	local count = Instance.new("TextLabel")
	count.Name = "Count"
	count.AnchorPoint = Vector2.new(0.5, 0)
	count.Position = UDim2.new(0.5, 0, 0, HOT.BagCountTop)
	count.Size = UDim2.new(1, -4, 0, HOT.BagCountSize + 4)
	count.BackgroundTransparency = 1
	count.Font = Enum.Font.FredokaOne
	count.TextSize = HOT.BagCountSize
	count.TextColor3 = HOT.CountLoading
	count.TextScaled = true
	count.Text = ""
	count.ZIndex = 9
	count.Parent = face
	UIKit.stroke(count, HOT.Ink, HOT.NumeralOutline)
	local countFit = Instance.new("UITextSizeConstraint")
	countFit.MaxTextSize = HOT.BagCountSize
	countFit.MinTextSize = 8
	countFit.Parent = count

	-- READY (2026-10-09, pods hatch in the Bag): the owner's green check on the
	-- cell's top-right corner while a pod in the Bag can be hatched -- the door
	-- to HATCH. A green disc while the icon's id is "".
	local readyBadge = Instance.new("ImageLabel")
	readyBadge.Name = "ReadyBadge"
	readyBadge.AnchorPoint = Vector2.new(0.5, 0.5)
	readyBadge.Position = UDim2.new(1, -3, 0, 3)
	readyBadge.Size = UDim2.fromOffset(20, 20)
	readyBadge.BackgroundColor3 = Color3.fromRGB(74, 158, 58)
	readyBadge.BackgroundTransparency = if HATCH_BAG.Icons.Ready ~= "" then 1 else 0
	readyBadge.ScaleType = Enum.ScaleType.Fit
	readyBadge.Visible = false
	readyBadge.ZIndex = 10
	readyBadge.Parent = face
	if HATCH_BAG.Icons.Ready ~= "" then
		readyBadge.Image = HATCH_BAG.Icons.Ready
		readyBadge.ImageRectOffset = HATCH_BAG.IconCropOffset
		readyBadge.ImageRectSize = HATCH_BAG.IconCropSize
	else
		UIKit.corner(readyBadge, 10)
	end

	chip = { holder = holder, spacer = spacer, button = face, count = count, faceCorner = faceCorner,
		faceStroke = faceStroke, rimCorner = rimCorner, icon = icon, bump = bump, bumpTween = nil }
end

local function bumpChip()
	if player:GetAttribute("SeedAfterimageQuality") == "Off" then
		return
	end
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

--==============================================================================
-- A CHANGE OF FACE
--
-- HudLayout's answer carries the card's numbers as `hot`, and layoutHud swaps
-- HOT for them when the mode changes. Everything already built from the old
-- numbers is resized here (HotbarCard.restyle). Called from layoutHud and
-- nowhere else; nothing here runs per frame.
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
-- THE FLASH: ONE TWEEN, NO LOOP
--
-- HotbarCard colours the edge and eases its thickness back, then one redraw puts
-- the real edge back. Deliberately NOT a RenderStepped pulse: this HUD runs on
-- phones, and the repo rule is no per-frame allocation.
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
			redraw()
		end
	end)
end

--==============================================================================
-- THE STRIP, PAINTED
--
-- Every live slot is drawn in its place from the bar (the server's, with a
-- pending edit on top): the item it names, faint while it is restoring after a
-- respawn, a soft amber edge while a weapon's equip is at the server, a faint
-- word for a placeholder, and a bright edge on every slot while a phone
-- assigns. A slot past `activeSlots` is hidden and emptied, so no key, bumper
-- or cooldown tick reaches it.
--==============================================================================
local function refreshHotbar()
	local held = heldTool()
	local heldRef = HotbarSlots.refOfTool(held)
	local still = player:GetAttribute("SeedAfterimageQuality") == "Off"
	local shown = shownBar()
	--==========================================================================
	-- A TRAP'S PLACEMENTS, AND WHERE REMOVE STANDS (2026-10-04)
	--
	-- Every trap slot shows the same count -- the three placements are shared
	-- by every trap type -- once the server's count is in. REMOVE follows the
	-- trap's ACTUAL slot: the trap whose Tool the player has (the one they set
	-- traps with) if it is on the strip, else the first trap that is.
	--==========================================================================
	local traps = if trapRemove then trapRemove.state() else nil
	local trapSlot, anyTrapSlot = nil :: number?, nil :: number?
	for i = 1, math.max(activeSlots, #hotSlots) do
		local slot = hotSlots[i]
		if i > activeSlots then
			if slot then
				slot.holder.Visible = false
				slot.ref = ""
				slot.tool = nil
				slot.item = nil
				slot.pop.reset()
				RarityFX.setActive(slot.card.fxEdge, false)
			end
		else
			slot = acquireHotSlot(i)
			local ref = shown[i] or ""
			local item = view.byRef[ref]
			local kind, category = HotbarSlots.parse(ref)
			slot.holder.Visible = true
			slot.ref = ref
			slot.tool = if item then item.tool else nil
			slot.item = if item and item.weaponId then WeaponData.Get(item.weaponId) else nil
			local isHeld = item ~= nil and ((heldRef ~= nil and heldRef == ref) or (held ~= nil and item.tool == held))
			local face = if item then InventoryModel.face(item) else nil
			local shownKey = if face then face.visual else "empty:" .. i
			if slot.shownKey ~= shownKey then
				if face then
					local builder, previewKind = ItemArt.builder(face.visual, face.art)
					slot.preview.setModel(shownKey, builder, previewKind)
				else
					slot.preview.setModel(shownKey, nil, "plant")
				end
				slot.shownKey = shownKey
			end
			local ghost = if kind == "placeholder" and category and HOT.Tags[category]
				then HOT.Tags[category].text else nil
			local isTrap = slot.item ~= nil and (slot.item :: WeaponData.Item).Category == "trap"
			if isTrap then
				anyTrapSlot = anyTrapSlot or i
				if item and item.tool and item.tool.Parent then
					trapSlot = trapSlot or i
				end
			end
			HotbarCard.paint(slot.card, HOT, {
				empty = item == nil,
				held = isHeld,
				number = slotWord(i),
				-- The stack's count: the wheel's earned balance.
				stack = if item and item.kind == "ticket" then "x" .. tostring(item.count) else nil,
				-- A grown plant's rarity colour; a pod's is the hatch's to show.
				accent = if item and item.kind == "plant" and face then face.accent else nil,
				-- The Tool's own name ("???" for a pod, and while a roll runs), for
				-- TutorialUI's pointer.
				name = if item and item.tool then HatchRoll.shownName(item.tool) elseif face then face.name else "",
				ghost = ghost,
				restoring = item ~= nil and item.restoring,
				pending = item ~= nil and item.weaponId ~= nil and item.weaponId == equipPending.id,
				target = assign.ref ~= nil,
				-- Only what the face may say: a pod's is its shell's or nothing.
				rarity = if face then face.rarity else nil,
				-- A trap's placements still available, the server's own count.
				uses = if isTrap and traps and traps.known then WeaponData.TrapsLeftText(traps.left) else nil,
				usesEmpty = isTrap and traps ~= nil and traps.left == 0,
				-- A pod on the bar (2026-10-09): READY, or the time it has left.
				podReady = item ~= nil and item.kind == "pod" and not item.hatched and item.hatchAt ~= nil
					and Workspace:GetServerTimeNow() >= (item.hatchAt :: number),
				podClock = if item and item.kind == "pod" and not item.hatched and item.hatchAt
						and Workspace:GetServerTimeNow() < (item.hatchAt :: number)
					then InventoryModel.clock((item.hatchAt :: number) - Workspace:GetServerTimeNow())
					else nil,
			})
			RarityFX.setActive(slot.card.fxEdge, true)
			HotbarCard.lift(slot.card, isHeld, still, HOT)
			if hoveredSlot == i then
				announce(if item then visibleName(item) else nil, true)
			end
		end
	end

	local remove = trapRemove
	if remove then
		local at = trapSlot or anyTrapSlot
		local slotButton = if at and hotSlots[at] then hotSlots[at].button else nil
		remove.slot(at, slotButton)
	end

	--==========================================================================
	-- THE BAG CELL'S COUNT: plant storage, as the server counts it. Dropped
	-- where HudLayout says the cell does not fit.
	--==========================================================================
	-- The PLANT rows (2026-10-09): pods have a room of their own, and a pod in
	-- the arms keeps its place there, not in this count.
	local rows: number? = nil
	if prof.held then
		rows = 0
		for _, row in ipairs(prof.held :: { any }) do
			if type(row) == "table" and row.Hatched == true then
				rows = (rows :: number) + 1
			end
		end
	end
	local text, full, known = HotbarSlots.storage(rows, false, GameConfig.Save.MaxHeld)
	chip.count.Text = text
	chip.count.TextColor3 = if not known then HOT.CountLoading
		elseif full then HOT.CountFull
		else HOT.CountOpen
	local badge = chip.button:FindFirstChild("ReadyBadge")
	if badge and badge:IsA("GuiObject") then
		badge.Visible = podsNow.ready > 0
	end
	local layout = hud
	local camera = Workspace.CurrentCamera
	local roomForBag = if layout then layout.chip
		else camera ~= nil and camera.ViewportSize.X >= HOT.ChipMinViewport
	chip.holder.Visible = roomForBag
	chip.spacer.Visible = roomForBag
end

--==============================================================================
-- THE BAG, PAINTED (only while it is open)
--
-- InventoryModel groups what is owned -- EVERY bar item in the grid too, its
-- slot's number on a badge (2026-10-10, Michael on v1047: "Maybe they should
-- appear in the bag as well but with a frame and icon for the hotbar number";
-- until then the shown slots' items were left out and only a phone's hidden
-- 6-0 were there). So a controller reaches every bar item from the Bag (its
-- menu's Remove from hotbar), a pod's size shows on its tile, and a bar pod
-- hatches from it. Filtered by the panel's category, search words and heart;
-- InventoryPanel draws the tiles.
--==============================================================================
local function refreshBag()
	local held = heldTool()
	local groups = InventoryModel.groups(view.items, shownBar(), 0, HotbarSlots.refOfTool(held), held)
	table.clear(view.byKey)
	for _, group in ipairs(groups) do
		view.byKey[group.key] = group
	end
	if not bagOpen then
		return
	end
	local state = panel.state
	local list = InventoryModel.filter(groups, state.category, state.search, state.favouritesOnly)
	local entries = {}
	local now = Workspace:GetServerTimeNow()
	for _, group in ipairs(list) do
		local face = group.face
		-- A pod tile's READY, or the time left on the pod due first (2026-10-09).
		local podReady, podLeft = InventoryModel.podState(group, now)
		table.insert(entries, {
			key = group.key,
			art = face.art,
			artKey = face.visual,
			paint = {
				name = face.name,
				variant = face.variant,
				variantColour = face.variantColour,
				count = if group.count > 1 or group.category == "tickets" then "x" .. tostring(group.count) else nil,
				badge = if group.badge then slotWord(group.badge) else nil,
				favourite = group.favourite,
				held = group.held,
				restoring = group.restoring,
				accent = if group.category == "plants" then face.accent else nil,
				rarity = face.rarity,
				variantIsRarity = face.variantIsRarity,
				studs = face.studs,
				podReady = podReady == true,
				podClock = if podReady == false and podLeft then InventoryModel.clock(podLeft) else nil,
			},
		})
	end
	local counts = InventoryModel.counts(view.items)
	-- TWO ROOMS (2026-10-09): the plants' 24, which a carried pod no longer
	-- takes, and the pods' own, where it keeps its place.
	local plantRows, podRows = nil :: number?, nil :: number?
	if prof.held then
		plantRows, podRows = 0, 0
		for _, row in ipairs(prof.held :: { any }) do
			if type(row) == "table" and row.Hatched == true then
				plantRows = (plantRows :: number) + 1
			elseif type(row) == "table" then
				podRows = (podRows :: number) + 1
			end
		end
	end
	local carrying = player:GetAttribute(ATTR.CarryingSpecies) ~= nil
	local text, full, known = InventoryModel.storage(plantRows, false, GameConfig.Save.MaxHeld, prof.waiting)
	local podText, podsFull = InventoryModel.podStorage(podRows, carrying, GameConfig.Save.MaxPods)
	local filtered = state.search ~= "" or state.favouritesOnly
	panel.paint({
		entries = entries,
		counts = counts,
		footer = text .. "  ·  " .. podText,
		footerColour = if not known then HOT.CountLoading elseif full or podsFull then HOT.CountFull else HOT.CountOpen,
		-- The bar beside the words: the plants stored, of their limit.
		footerFill = if plantRows then plantRows / GameConfig.Save.MaxHeld else nil,
		empty = if #entries == 0 then InventoryModel.emptyText(state.category, counts[state.category] or 0, filtered)
			else nil,
		compact = hud ~= nil and (hud :: HudLayout.Layout).compact,
		readyPods = podsNow.ready,
	})
end

--==============================================================================
-- ONE REDRAW, COALESCED
--
-- Tools arrive in bursts -- equipping reparents, respawning rebuilds the whole
-- Backpack -- so a redraw per event would rebuild the same strip five times in
-- a frame. Deferred and collapsed. It also hands a weapon the server has just
-- equipped into the hands, once its Tool is here.
--==============================================================================
local redrawPending = false

redraw = function()
	if redrawPending then
		return
	end
	redrawPending = true
	task.defer(function()
		redrawPending = false
		local tools: { Tool } = {}
		for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
			if container then
				for _, child in ipairs(container:GetChildren()) do
					if child:IsA("Tool") then
						table.insert(tools, child)
					end
				end
			end
		end
		local favourites = table.clone(prof.favourites)
		for ref, on in pairs(favPending) do
			favourites[ref] = if on then true else nil
		end
		local WheelData = require(Shared:WaitForChild("WheelData"))
		view.items = InventoryModel.collect({
			held = prof.held,
			tools = tools,
			weapons = prof.weapons,
			tickets = prof.tickets,
			trailOwned = player:GetAttribute(WheelData.Attributes.TrailOwned) == true,
			trailWorn = player:GetAttribute(WheelData.Attributes.Trail) == WheelData.Trail.Id,
			favourites = favourites,
			sealedUntil = sealedUntil,
			now = Workspace:GetServerTimeNow(),
		})
		table.clear(view.byRef)
		-- The Bag's pods (2026-10-09): how many are READY, which ones (so the
		-- clock below knows when one turns), and whether any still grows.
		local now = Workspace:GetServerTimeNow()
		local readyKeys = {}
		podsNow.growing = false
		for _, item in ipairs(view.items) do
			if item.ref then
				view.byRef[item.ref :: string] = item
			end
			if item.kind == "pod" and not item.hatched and item.hatchAt then
				if now >= (item.hatchAt :: number) then
					table.insert(readyKeys, tostring(item.ref))
				else
					podsNow.growing = true
				end
			end
		end
		podsNow.ready = InventoryModel.readyCount(view.items, now)
		podsNow.readyKeys = table.concat(readyKeys, ",")
		-- A weapon asked of the server goes into the hands once its Tool lands.
		local waitingFor = equipPending.id
		if waitingFor then
			local item = view.byRef[HotbarSlots.weapon(waitingFor)]
			if os.clock() > equipPending.untilAt then
				equipPending.id = nil
			elseif item and item.tool and item.tool.Parent then
				equipPending.id = nil
				holdTool(item.tool)
			end
		end
		refreshHotbar()
		refreshBag()
	end)
end

--==============================================================================
-- THE TRAP COUNT AND REMOVE (2026-10-04, the reusable-trap brief)
--
-- TrapRemove reads the server's count off this player's trap records and owns
-- the REMOVE button; this file tells it the layout, the trap's slot and
-- whether the strip is showing, and repaints the "3x" when the count changes.
--==============================================================================
trapRemove = TrapRemove.new(gui, {
	player = player,
	channel = function(): RemoteEvent?
		return channel
	end,
	changed = function()
		redraw()
	end,
})

--==============================================================================
-- THE WIRE
--==============================================================================
local remotes = SeedGame:WaitForChild("Remotes", 20)
if remotes then
	local ev = remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20)
	if ev and ev:IsA("RemoteEvent") then
		channel = ev
	end
end

--==============================================================================
-- AN EDIT TO THE BAR: drawn now, sent once per frame, answered by the server
--
-- The whole bar goes over (HotbarSet); the server cleans it against what is
-- owned THEN and pushes the profile back. If no push follows within two
-- seconds -- refused, rate-limited, or a no-op -- the server's copy is shown
-- again: the client never keeps a bar the server did not take.
--==============================================================================
editBar = function(new: { string })
	if HotbarSlots.same(new, shownBar()) then
		return
	end
	bar.pending = HotbarSlots.normalise(new)
	bar.seq += 1
	local seq = bar.seq
	if not bar.queued then
		bar.queued = true
		task.defer(function()
			bar.queued = false
			local remote = channel
			local pending = bar.pending
			if remote and pending then
				remote:FireServer(INV.SetAction, pending)
			end
		end)
	end
	task.delay(2, function()
		if bar.seq == seq and bar.pending then
			bar.pending = nil
			redraw()
		end
	end)
	SoundKit.play("UIClick")
	redraw()
end

-- A heart on every copy in `refs`, or off. Drawn now, sent in requests of at
-- most MaxPerRequest, and forgotten for the server's word within two seconds.
local function editFavourite(refs: { string }, on: boolean)
	local remote = channel
	if not remote or #refs == 0 then
		return
	end
	for _, ref in ipairs(refs) do
		favPending[ref] = on
	end
	for start = 1, #refs, INV.MaxPerRequest do
		remote:FireServer(INV.FavouriteAction, table.move(refs, start, math.min(#refs, start + INV.MaxPerRequest - 1),
			1, {}), on)
	end
	task.delay(2, function()
		for _, ref in ipairs(refs) do
			if favPending[ref] == on then
				favPending[ref] = nil
			end
		end
		redraw()
	end)
	SoundKit.play("UIClick")
	redraw()
end

--==============================================================================
-- HOLD WHAT A REF NAMES
--
-- A plant, a pod or the tickets: its Tool, through holdTool and its guards. A
-- bat or a trap that is not out: the shop's own equip verb (WeaponShopService
-- checks ownership and category), and the new Tool goes into the hands when it
-- lands (redraw). Something still being restored after a respawn: nothing yet.
-- Answers whether anything was done.
--==============================================================================
holdRef = function(ref: string): boolean
	local item = view.byRef[ref]
	if not item then
		return false
	end
	if item.restoring then
		SoundKit.play("CardClick")
		return false
	end
	local tool = item.tool
	if tool and tool.Parent then
		return holdTool(tool)
	end
	local weaponId = item.weaponId
	local remote = channel
	if weaponId and remote then
		equipPending.id = weaponId
		equipPending.untilAt = os.clock() + 4
		remote:FireServer(W.EquipAction, weaponId)
		SoundKit.play("CardClick")
		redraw()
		return true
	end
	return false
end

--==============================================================================
-- A TILE PRESSED (a click, a tap, A)
--
-- The copy a press means is the one in hand, else the lowest id. In hand: put
-- away. Otherwise HOLD it -- the guards first: carrying a pod, a roll still
-- running, something still restoring refuse it, and then nothing else happens
-- either -- and if it has no shortcut, give it its kind's faint slot or the
-- first empty shown one; a full bar only holds. The trail is worn, not held.
--==============================================================================
activateKey = function(key: string, by: string)
	if assign.ref then
		endAssign()
		return
	end
	local group = view.byKey[key]
	local held = heldTool()
	local item = if group then InventoryModel.pick(group, HotbarSlots.refOfTool(held), held) else nil
	if not item then
		return
	end
	-- A POD IN THE BAG OPENS ITS MENU (2026-10-09, pods hatch in the Bag): HATCH,
	-- held, once it is READY; Instant Hatch while it grows; and "Hold in hands",
	-- the tap's old job, for selling or a sacrifice.
	local tile = if item.kind == "pod" and not item.hatched and by ~= "menu" then panel.tileButton(key) else nil
	if tile then
		local k = UIKit.scaleOf(gui)
		openMenuFor(key, nil, { x = tile.AbsolutePosition.X / k, y = tile.AbsolutePosition.Y / k,
			w = tile.AbsoluteSize.X / k, h = tile.AbsoluteSize.Y / k })
		return
	end
	if item.kind == "trail" then
		local WheelData = require(Shared:WaitForChild("WheelData"))
		local remote = channel
		if remote then
			remote:FireServer(WheelData.Actions.Equip, not item.worn)
			SoundKit.play("CardClick")
		end
		return
	end
	if item.tool and held == item.tool then
		holdTool(nil)
		return
	end
	local ref = item.ref
	local done = if ref then holdRef(ref) elseif item.tool then holdTool(item.tool) else false
	if not (done and ref) or HotbarSlots.slotOf(shownBar(), ref) then
		return
	end
	local new, at = HotbarSlots.arrive(shownBar(), ref, activeSlots, prof.planted)
	if at then
		editBar(new)
		flashSlot(at, HOT.FlashArrived)
		if hud and (hud :: HudLayout.Layout).touch then
			panel.say("→ slot " .. slotWord(at), 2)
		end
	end
end

--==============================================================================
-- ASSIGN TO SLOT (a phone's way to place an item; a menu's on a desktop too)
--
-- The strip rises over the dimmed panel, every slot wears a bright edge, and
-- the line over the strip names the item waiting. Tapping a slot puts it there
-- (a displaced item goes back to the grid); a tap anywhere else, B, closing the
-- Bag, a respawn or a carry cancels. Tiles ignore taps meanwhile.
--==============================================================================
local function startAssign(ref: string, name: string)
	assign.ref = ref
	assign.name = name
	liftStrip(true)
	panel.dim(true)
	announce("Tap a slot for " .. name, true)
	hotbar.SelectionGroup = true
	local first = hotSlots[1]
	if first and UserInputService:GetLastInputType().Name:find("Gamepad") then
		GuiService.SelectedObject = first.button
	end
	ContextActionService:BindActionAtPriority("SeedAssignBack", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			endAssign()
		end
		return Enum.ContextActionResult.Sink
	end, false, 3000, Enum.KeyCode.ButtonB)
	redraw()
end

endAssign = function()
	if not assign.ref then
		return
	end
	assign.ref = nil
	ContextActionService:UnbindAction("SeedAssignBack")
	hotbar.SelectionGroup = false
	liftStrip(false)
	panel.dim(false)
	announce(nil, true)
	redraw()
end

-- A tap that is on no slot cancels an assignment (read, never swallowed).
UserInputService.InputBegan:Connect(function(input: InputObject)
	if not assign.ref then
		return
	end
	local kind = input.UserInputType
	if kind ~= Enum.UserInputType.Touch and kind ~= Enum.UserInputType.MouseButton1 then
		return
	end
	local point = Vector2.new(input.Position.X, input.Position.Y)
	for i = 1, activeSlots do
		local slot = hotSlots[i]
		if slot and slot.holder.Visible then
			local at, size = slot.holder.AbsolutePosition, slot.holder.AbsoluteSize
			if point.X >= at.X and point.X <= at.X + size.X and point.Y >= at.Y and point.Y <= at.Y + size.Y then
				return
			end
		end
	end
	endAssign()
end)

--==============================================================================
-- THE MENU: a long press, a right-click, RT -- on a tile (`key`) or a slot
--
-- The details (InventoryModel.details: visible facts only) and what can be done:
-- Assign to slot, Remove from hotbar (an item on a slot), Favourite / Remove
-- favourite (every copy of a tile at once; a slot's one copy), Wear / Take off
-- for the trail.
--==============================================================================
openMenuFor = function(key: string?, slotIndex: number?, anchor: HudLayout.Rect)
	local shown = shownBar()
	local item: InventoryModel.Item? = nil
	local refs: { string } = {}
	if key then
		local group = view.byKey[key]
		if group then
			item = InventoryModel.pick(group, HotbarSlots.refOfTool(heldTool()), heldTool())
			refs = InventoryModel.refsOf(group)
		end
	elseif slotIndex then
		item = view.byRef[shown[slotIndex] or ""]
		if item and item.ref then
			refs = { item.ref :: string }
		end
	end
	local it = item
	if not it then
		return
	end
	local face = InventoryModel.face(it)
	local ref = it.ref
	local slot = if ref then HotbarSlots.slotOf(shown, ref) else nil
	local held = heldTool()
	local actions: { { id: string, label: string } } = {}
	if ref and not it.restoring then
		table.insert(actions, { id = "assign", label = "Assign to slot" })
	end
	if slot then
		table.insert(actions, { id = "remove", label = "Remove from hotbar" })
	end
	if #refs > 0 then
		table.insert(actions, { id = "favourite", label = if it.favourite then "Remove favourite" else "Favourite" })
	end
	if it.kind == "trail" then
		table.insert(actions, { id = "wear", label = if it.worn then "Take off" else "Wear" })
	end
	--==========================================================================
	-- A POD IN THE BAG (2026-10-09, pods hatch in the Bag)
	--
	-- READY: HOLD TO HATCH first -- the bed prompt's own hold, with the shell's
	-- rattle. Still growing: Instant Hatch, FREE while a saved one is held, else
	-- with THIS player's price (none shown until Roblox has said). And "Hold in
	-- hands", which a tap on a pod no longer does.
	--==========================================================================
	local now = Workspace:GetServerTimeNow()
	local podDue = if it.kind == "pod" and not it.hatched and it.ref and not it.restoring then it.hatchAt else nil
	if podDue then
		if now >= podDue then
			table.insert(actions, 1, { id = "hatch", label = HATCH_BAG.Words.HoldHatch,
				hold = GameConfig.Plant.HatchHoldSeconds, icon = HATCH_BAG.Icons.Hatch })
		else
			local credits = tonumber(player:GetAttribute(HATCH_BAG.CreditsAttribute)) or 0
			local price = podsNow.price
			table.insert(actions, 1, { id = "instant", icon = HATCH_BAG.Icons.InstantHatch,
				label = if credits > 0 then HATCH_BAG.Words.SavedInstant
					elseif price then string.format("%s  R$%s", HATCH_BAG.Words.Instant, RobuxPrice.format(price))
					else HATCH_BAG.Words.Instant })
		end
		table.insert(actions, { id = "hold", label = "Hold in hands" })
		-- WHAT'S INSIDE? (the Pod Guide, 2026-10-09): the Almanac at the plant
		-- this pod's own look already shows -- an ordinary pod's only, one of
		-- its biome's five (HatchRoll.candidates); never a Secret's or a Rain's.
		local biomeFive = if it.speciesId then HatchRoll.candidates(it.speciesId) else {}
		if #biomeFive > 1 and table.find(biomeFive, it.speciesId) then
			table.insert(actions, { id = "inside", label = GameConfig.PodGuide.Words.WhatsInside })
		end
	end
	local lines = InventoryModel.details(it, face, nil, slot, held ~= nil and it.tool == held, now)
	--==========================================================================
	-- A TRAP'S PLACEMENTS, AND REMOVE WHEREVER IT IS (2026-10-04)
	--
	-- How many are out, of the three every trap type shares -- and the same
	-- REMOVE the strip's button does (the newest trap first), so a trap on no
	-- shown slot can still take one back.
	--==========================================================================
	local weapon = if it.weaponId then WeaponData.Get(it.weaponId) else nil
	local traps = if weapon and weapon.Category == "trap" and trapRemove then trapRemove.state() else nil
	if traps and traps.known then
		table.insert(lines, math.max(1, #lines), { key = "Placed", value = string.format("%d of %d (%s left)", traps.placed,
			traps.capacity, WeaponData.TrapsLeftText(traps.left)) })
		-- The trigger cooldown (2026-10-05): what a catch costs, and the wait
		-- now if one is running -- the same deadline the strip counts down.
		local cooling = if traps.cooldownUntil then traps.cooldownUntil - Workspace:GetServerTimeNow() else 0
		table.insert(lines, math.max(1, #lines), { key = "After a catch", value = string.format(
			"%ds before any trap", WeaponData.Trap.TriggerCooldownSeconds) })
		if cooling > 0 then
			table.insert(lines, math.max(1, #lines), { key = "Cooldown", value = string.format(
				"ready in %ds", math.ceil(cooling)) })
		end
		if traps.placed >= 1 then
			table.insert(actions, 1, { id = "removetrap", label = "Remove newest trap" })
		end
	end
	panel.openMenu(anchor, { title = face.name, lines = lines, actions = actions }, function(id: string)
		if id == "assign" and ref then
			startAssign(ref, face.name)
		elseif id == "remove" and slot then
			editBar(HotbarSlots.remove(shownBar(), slot))
		elseif id == "favourite" then
			editFavourite(refs, not it.favourite)
		elseif id == "wear" and key then
			activateKey(key, "menu")
		elseif id == "removetrap" and trapRemove then
			trapRemove.press()
		elseif (id == "hatch" or id == "instant") and ref then
			-- The pod's own item id; the server checks everything again.
			local remote = channel
			local item = string.match(ref, "^i:(.+)$")
			if remote and item then
				remote:FireServer(if id == "hatch" then HATCH_BAG.Hatch else HATCH_BAG.Instant, item)
			end
		elseif id == "hold" and ref then
			holdRef(ref)
		elseif id == "inside" and it.speciesId then
			-- IndexUI's own OpenAt (one panel at a time: the Bag steps aside).
			local almanac = playerGui:FindFirstChild("SeedIndex")
			local openAt = almanac and almanac:FindFirstChild("OpenAt")
			if openAt and openAt:IsA("BindableEvent") then
				openAt:Fire(it.speciesId)
			end
		end
	end)
end

--==============================================================================
-- THE DRAG (a mouse only: a thumb scrolls, long-presses and taps)
--
-- POSITIONS ARE COMPARED RAW, AND THAT WAS MEASURED RATHER THAN ASSUMED:
-- InputObject.Position is already in this gui's space (it does not ignore the
-- inset), so it is compared with AbsolutePosition untouched, against the slots'
-- fixed holders -- never the lifting faces. Divided by the TV scale only to
-- become an Offset, for the label that follows the pointer.
--
--   tile -> slot     assign: a displaced item goes back to the grid, a faint
--                    slot in the way is dropped
--   slot -> slot     swap, or move into an empty one
--   slot -> the Bag  (the open panel, or the Bag cell) the shortcut goes
--   anywhere else    nothing at all
--==============================================================================
local dragGhost: TextLabel? = nil
local dragSource: any = nil
local dragConns: { RBXScriptConnection } = {}

local function endDrag(dropAt: Vector2?)
	for _, c in ipairs(dragConns) do
		c:Disconnect()
	end
	table.clear(dragConns)
	if dragGhost then
		dragGhost:Destroy()
		dragGhost = nil
	end
	if not assign.ref then
		liftStrip(false)
	end
	local source = dragSource
	dragSource = nil
	if not (source and dropAt) then
		return
	end
	local slots: { PressGesture.Rect } = {}
	for i = 1, activeSlots do
		local slot = hotSlots[i]
		if slot and slot.holder.Visible then
			local at, size = slot.holder.AbsolutePosition, slot.holder.AbsoluteSize
			slots[i] = { x = at.X, y = at.Y, w = size.X, h = size.Y }
		else
			slots[i] = { x = 0, y = 0, w = 0, h = 0 }
		end
	end
	local bags: { PressGesture.Rect } = {}
	local targets: { GuiObject } = {}
	if bagOpen then
		table.insert(targets, modal.group)
	end
	if chip.holder.Visible then
		table.insert(targets, chip.holder)
	end
	for _, object in ipairs(targets) do
		local at, size = object.AbsolutePosition, object.AbsoluteSize
		table.insert(bags, { x = at.X, y = at.Y, w = size.X, h = size.Y })
	end
	local target, index = PressGesture.dropTarget(dropAt, slots, bags, 2)
	local shown = shownBar()
	if target == "slot" and index then
		if source.from == "bag" then
			editBar((HotbarSlots.assign(shown, source.ref, index)))
			flashSlot(index, HOT.FlashArrived)
		elseif index ~= source.index then
			editBar(HotbarSlots.swap(shown, source.index, index))
			flashSlot(index, HOT.FlashArrived)
		end
	elseif target == "bag" and source.from == "slot" then
		editBar(HotbarSlots.remove(shown, source.index))
		flashSlot(source.index, HOT.FlashCleared)
	end
end

--==============================================================================
-- AND ANYTHING THAT ENDS THE MOMENT ENDS THE DRAG
--
-- The Bag shutting under it, the character going, a pod landing in both arms, a
-- trap closing, a fall, the slot count changing: none fires an input event, and
-- each would leave the label in the air and the strip lifted. Dropped with no
-- point, so it cancels rather than assigns. The same moments end a phone's
-- assignment and close the menu and the tooltip.
--==============================================================================
cancelDrag = function()
	if dragSource then
		endDrag(nil)
	end
	dragMoved = false
	endAssign()
	panel.closeMenu()
	panel.hideTooltip()
end

beginDrag = function(source: any, input: InputObject)
	if dragSource then
		return
	end
	dragSource = source
	dragMoved = true
	liftStrip(true)
	local k = UIKit.scaleOf(gui)
	local ghost = UIKit.outlined(gui, "DragGhost", 14, CREAM, 2)
	ghost.AnchorPoint = Vector2.new(0.5, 1)
	ghost.Size = UDim2.fromOffset(150, 22)
	ghost.ZIndex = 70
	ghost.Text = string.upper(source.label or "ITEM")
		.. (if source.from == "slot" then "  ->  BAG" else "  ->  HOTBAR")
	ghost.Position = UDim2.fromOffset(input.Position.X / k, input.Position.Y / k - 12)
	dragGhost = ghost
	table.insert(dragConns, UserInputService.InputChanged:Connect(function(moved)
		if moved.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local label = dragGhost
		if label then
			label.Position = UDim2.fromOffset(moved.Position.X / k, moved.Position.Y / k - 12)
		end
	end))
	table.insert(dragConns, UserInputService.InputEnded:Connect(function(over)
		if over.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		endDrag(Vector2.new(over.Position.X, over.Position.Y))
		-- Cleared on the next frame: Activated fires AFTER InputEnded, and the
		-- guard must still be up when it does, or a drop would also hold.
		task.defer(function()
			dragMoved = false
		end)
	end))
end

--==============================================================================
-- WHAT THE PROFILE SAYS
--
-- The rows, the weapons, the tickets, the hearts and the saved bar. A pending
-- edit the server has now taken -- the same bar, or the same bar less what is
-- no longer owned -- is dropped for the server's copy.
--
-- ARRIVALS are what is owned now and was not in the last packet (the first
-- packet is only the baseline, and a respawn changes no rows): each goes to its
-- kind's faint slot or the first empty shown one, else a shown slot a planted
-- creature keeps (HotbarSlots.arrive, option A, 2026-10-08); a plant or a pod
-- that still finds no room slides the plant slots and pushes the oldest off
-- (the owner, 2026-10-08). Only a weapon with no room goes into the grid, where
-- the Bag cell pops. A creature picked up out of the garden is an arrival too.
--==============================================================================
local function receive(profile: any)
	if type(profile) ~= "table" then
		return
	end
	prof.heard = true
	prof.held = if type(profile.Held) == "table" then profile.Held else prof.held
	table.clear(prof.weapons)
	if type(profile.Weapons) == "table" then
		for id, on in pairs(profile.Weapons) do
			if on == true and type(id) == "string" then
				prof.weapons[id] = true
			end
		end
	end
	local earned = tonumber(profile.WheelEarned)
	prof.tickets = if earned and earned == earned then math.floor(earned) else 0
	prof.favourites = if type(profile.Favourites) == "table" then table.clone(profile.Favourites) else {}
	for ref, on in pairs(favPending) do
		if (prof.favourites[ref] == true) == on then
			favPending[ref] = nil
		end
	end
	-- The wheel's prizes waiting for room: pods it could not hand over yet.
	prof.waiting = 0
	if type(profile.WheelPending) == "table" then
		local WheelData = require(Shared:WaitForChild("WheelData"))
		for _, row in ipairs(profile.WheelPending) do
			local prize = type(row) == "table" and WheelData.ById[tostring(row.Prize)]
			if prize and prize.kind == "pod" then
				prof.waiting += 1
			end
		end
	end
	if type(profile.Hotbar) == "table" then
		bar.server = HotbarSlots.normalise(profile.Hotbar)
		local pending = bar.pending
		if pending and (HotbarSlots.same(pending, bar.server)
			or HotbarSlots.same(HotbarSlots.clean(profile, pending, HotbarSlots.placeholdersIn(pending)), bar.server)) then
			bar.pending = nil
		end
	end
	local now = HotbarSlots.owned(profile)
	local before = prof.owned
	local wasPlanted = prof.planted
	prof.owned = now
	prof.planted = HotbarSlots.planted(profile)
	if before then
		local arrived = HotbarSlots.arrivals(before, now)
		-- A creature picked up out of the garden comes to the bar like a banked
		-- pod (the owner, 2026-10-08).
		for _, ref in ipairs(HotbarSlots.pickedUp(wasPlanted, prof.planted, now)) do
			table.insert(arrived, ref)
		end
		if #arrived > 0 then
			local working = shownBar()
			local landed: { string } = {}
			for _, ref in ipairs(arrived) do
				local new, at, pushed = HotbarSlots.arrive(working, ref, activeSlots, prof.planted, true)
				if at then
					working = new
					table.insert(landed, ref)
				end
				-- Into the grid, or one pushed off the bar to make room: the Bag pops.
				if not at or pushed then
					bumpChip()
				end
			end
			if #landed > 0 then
				editBar(working)
				local still = player:GetAttribute("SeedAfterimageQuality") == "Off"
				local final = working
				task.defer(function()
					-- Where each one stands once every slide is done.
					for _, ref in ipairs(landed) do
						local at = HotbarSlots.slotOf(final, ref)
						if at then
							local slot = hotSlots[at]
							if slot then
								HotbarCard.bump(slot.card, still, HOT)
							end
							flashSlot(at, HOT.FlashArrived)
						end
					end
				end)
			end
		end
	end
	redraw()
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
-- A refused equip only clears the wait: MarigoldShopUI already plays Denied for
-- every refusal of that verb, and a second sound here would be noise.
if channel then
	channel.OnClientEvent:Connect(function(action: any, ok: any)
		if action == W.EquipAction and ok == false and equipPending.id then
			equipPending.id = nil
			redraw()
		end
	end)
end

-- The Bloomrunner Trail follows WheelService's two attributes; the bag's
-- restore its HeldRestored word.
do
	local WheelData = require(Shared:WaitForChild("WheelData"))
	for _, name in ipairs({ WheelData.Attributes.TrailOwned, WheelData.Attributes.Trail, ATTR.HeldRestored }) do
		player:GetAttributeChangedSignal(name):Connect(redraw)
	end
end

--==============================================================================
-- WATCHING THE CONTAINERS
--
-- The Backpack is DESTROYED and rebuilt on every respawn, so a connection to the
-- one that exists at login is a connection to an instance the engine will throw
-- away: watch the player for a new Backpack as well as the Backpack for Tools.
-- A Tool that changes what it is -- told its item id, its roll over (RevealAt
-- comes off), its ticket count -- repaints, once per Tool however often it moves.
--==============================================================================
local containerConns: { RBXScriptConnection } = {}
local watched: { [Tool]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function watchTools(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") and not watched[child] then
			watched[child] = true
			child.AttributeChanged:Connect(function(name: string)
				if name == "SpeciesId" or name == ATTR.CarryingKg or name == "Hatched" or name == "TicketCount"
					or name == ATTR.ItemId or name == HATCH_BAG.Attribute or name == HatchRoll.Attribute then
					redraw()
				end
			end)
		end
	end
end

local function watchContainer(container: Instance)
	watchTools(container)
	table.insert(containerConns, container.ChildAdded:Connect(function()
		watchTools(container)
		redraw()
	end))
	table.insert(containerConns, container.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") and dragSource then
			-- A drag whose subject has just been destroyed has nothing to drop.
			-- Checked after a frame so a reparent is not mistaken for a deletion.
			task.defer(function()
				if child.Parent == nil and dragSource then
					local item = view.byRef[dragSource.ref or ""]
					if item and item.tool == child then
						cancelDrag()
					end
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
player.CharacterRemoving:Connect(function()
	cancelDrag()
	equipPending.id = nil
end)
rebindContainers()

--==============================================================================
-- THE COUNT FOLLOWS THE DEVICE, AND CHANGING IT IS A REDRAW
--
-- Nothing is released when it shrinks: the bar is saved, ten long, and a slot
-- past the count is only hidden -- its item shows in the Bag with a badge -- so
-- a window that widens again gets every shortcut back where it was. A drag in
-- flight is cancelled: it was aimed at a strip about to change shape.
--==============================================================================
local function applySlotCount()
	local want = wantedSlots()
	if want == activeSlots then
		return
	end
	cancelDrag()
	activeSlots = want
	redraw()
end

--==============================================================================
-- WHERE THE STRIP, THE BAG BUTTON AND THE BAG SIT -- AND HOW MANY SLOTS
--
-- One question to HudLayout and one answer, applied to the things this script
-- owns on the HUD, with the slot count read off the same answer. Asked when
-- this ScreenGui's size changes and when a keyboard or a touch screen comes or
-- goes. Never per frame.
--==============================================================================
local function layoutHud()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local chipWas = if hud then hud.chip else nil
	hud = layout
	local restyled = layout.hot ~= HOT
	if restyled then
		HOT = layout.hot
		restyleHotbar()
	end
	bagButton.Position = HudLayout.place(layout.bag, bagButton.AnchorPoint, layout.safe)
	-- Its size is the layout's: the rail's 50 x 50, or a phone column's 34-40
	-- (2026-10-09), the satchel no larger than the button.
	UIKit.railShape(bagButton, Vector2.new(layout.bag.w, layout.bag.h), math.min(RAIL.IconBare, layout.bag.w))
	-- The owner's studded Bag picture IS the button once it has loaded
	-- (2026-10-09, GameConfig.Rail.StuddedBagArt); the satchel and BAG stay
	-- under it until then, and for good if it never does.
	UIKit.railPicture(bagButton, RAIL.StuddedBagArt, 1)
	hotbar.Position = HudLayout.place(layout.hotbar, hotbar.AnchorPoint, layout.safe)
	namePopup.Position = HudLayout.place(layout.namePopup, namePopup.AnchorPoint, layout.safe)
	local remove = trapRemove
	if remove then
		remove.layout(layout)
	end
	local count = activeSlots
	applySlotCount()
	if count == activeSlots and (restyled or (chipWas ~= nil and chipWas ~= layout.chip)) then
		redraw()
	end
	showStrip()
	layoutBag()
end

--==============================================================================
-- WHERE THE BAG SITS
--
-- Fitted into the space that is actually free: between the rails and above the
-- strip on a desktop, the whole screen under the top rows on a phone (where the
-- strip steps aside), centred when the width allows. The panel draws at the
-- player's menu size on its own (the hotbar's place is the owner's), keeping
-- exactly the footprint HudLayout gave it. Inside: InventoryPanel.layout.
--==============================================================================
local groupLimit = modal.group:FindFirstChildOfClass("UISizeConstraint")
if groupLimit then
	groupLimit.MinSize = Vector2.new(BAG.MinW, BAG.MinH)
end
layoutBag = function()
	-- In the gui's own units (its pixels / its TV scale, 1 off a TV), which is
	-- what the strip's Offsets and HudLayout's answer are in.
	local screen = gui.AbsoluteSize / UIKit.scaleOf(gui)
	if screen.X < 100 or screen.Y < 100 then
		return
	end
	local layout = hud or HudLayout.solve(HudLayout.measure(gui))
	local bag = HudLayout.bag(layout, {
		-- The strip's top, and the name popup's band over it (2026-10-01) --
		-- over a trap's REMOVE row too, while that stands (2026-10-04).
		hotTop = layout.namePopup.y,
		stripHidden = layout.touch,
		scale = UIKit.menuScale(),
		-- A phone draws the Bag smaller, short of the edges (2026-10-08).
		phone = UIKit.phoneMenuScale(),
	})
	modal.group.AnchorPoint = Vector2.new(0.5, 0.5)
	modal.group.Position = UDim2.fromOffset(bag.centre.X, bag.centre.Y)
	modal.group.Size = UDim2.fromOffset(bag.panel.w / bag.scale, bag.panel.h / bag.scale)
	modal.setUserScale(bag.scale)
	panel.layout(bag, modal.title.TextBounds.X / (UIKit.scaleOf(gui) * bag.scale))
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(layoutHud)
UserInputService:GetPropertyChangedSignal("KeyboardEnabled"):Connect(layoutHud)
UserInputService:GetPropertyChangedSignal("TouchEnabled"):Connect(layoutHud)
-- The REMOVE row starting or stopping (TrapRemove publishes it): the name band
-- and the Bag's foot move over it.
player:GetAttributeChangedSignal(GameConfig.Hotbar.RemoveRowAttribute):Connect(layoutHud)
-- The x2 card coming or going (2026-10-05): on a narrow phone the belt keeps 8 px
-- off it beside the cash line (HudLayout's `buff`).
player:GetAttributeChangedSignal(GameConfig.Pass.MultiplierAttribute):Connect(layoutHud)
layoutHud()
-- Before the ScreenGui has a size there is still a count to settle on.
applySlotCount()

-- The screen, the menu size, the title's measured width and the header's
-- padding (UIKit.modal steps it clear of a rail button AFTER the panel moves)
-- each move the Bag's insides.
UIKit.onMenuSize(layoutBag)
modal.title:GetPropertyChangedSignal("TextBounds"):Connect(layoutBag)
do
	local titlePad = modal.title.Parent and modal.title.Parent:FindFirstChildOfClass("UIPadding")
	if titlePad then
		titlePad:GetPropertyChangedSignal("PaddingLeft"):Connect(layoutBag)
		titlePad:GetPropertyChangedSignal("PaddingRight"):Connect(layoutBag)
	end
end

--==============================================================================
-- AND THE REST OF THE WAYS A DRAG STOPS MATTERING
--
--   a pod in both arms   CarryPose owns the hands and the Bag is unusable
--   the jaws close       the player is held still and being hit
--   ragdolled or dead    thrown by a guardian or a bat; re-hooked per character
--==============================================================================
player:GetAttributeChangedSignal(ATTR.CarryingSpecies):Connect(function()
	cancelDrag()
	redraw()
end)
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
--
-- Closing the Bag ends a drag, an assignment, the menu and the tooltip, and
-- clears the search words -- the category and the heart filter stay as they
-- were for the next time.
--==============================================================================
local open = false

local function setOpen(want: boolean)
	if open == want then
		return
	end
	open = want
	bagOpen = want
	showStrip()
	panel.setOpen(want)
	if not want then
		cancelDrag()
		panel.reset()
	end
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

--==============================================================================
-- WHAT A BAG HATCH ANSWERED (2026-10-09, pods hatch in the Bag)
--
-- A HATCH, a HATCH ALL or an Instant Hatch that went through closes the Bag, so
-- the hatch moment plays in the world -- at the bed the plant went into, or in
-- front of the player -- and an Instant Hatch's purchase dialog is not stacked
-- on it. A refusal is said INSIDE the Bag, where a toast would hide under the
-- panel. What changed in the Bag arrives as Tools and the profile, as always.
--==============================================================================
if channel then
	channel.OnClientEvent:Connect(function(action: any, reply: any)
		if action ~= HATCH_BAG.Reply or type(reply) ~= "table" then
			return
		end
		if reply.ok == true then
			setOpen(false)
		elseif reply.code == "STORAGE_FULL" then
			panel.say("No free bed, and no room for another plant.", 3)
		elseif reply.code == "NOT_READY" then
			panel.say("Not ready yet.", 2)
		end
		redraw()
	end)
end

-- The Instant Hatch product's price for THIS player (RobuxPrice), for the Bag's
-- button; none is shown until Roblox has said.
for _, item in ipairs(GameConfig.Store.InWorld or {}) do
	local id = tonumber(item.product) or 0
	if item.kind == "hatch" and id > 0 then
		RobuxPrice.watch("product", id, function(state: RobuxPrice.State, price: number?)
			podsNow.price = if state == "ready" then price else nil
		end)
	end
end
-- The strip's Bag cell is the same door, from where the player is looking.
chip.button.Activated:Connect(function()
	if not dragMoved then
		setOpen(not open)
	end
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

-- The Bag's close button gets the same small press as its other controls.
do
	local plate = modal.close:FindFirstChild("Plate")
	if plate and plate:IsA("GuiObject") then
		local plateScale = Instance.new("UIScale")
		plateScale.Parent = plate
		UIKit.cardPop(modal.close, plateScale, { hoverScale = 1.06, pressScale = 0.94, sound = false })
	end
end

--==============================================================================
-- THE NUMBER ROW
--
-- Keys 1-9 and 0 for the ten slots. Bound here because turning the CoreGui
-- Backpack off takes its bindings with it; ContextActionService so a text box
-- has priority and typing "1" in chat swaps nothing. A key for a slot that is
-- not on screen does nothing at all: a key that holds something invisible is
-- worse than a dead key.
--==============================================================================
local KEYS = {
	Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five,
	Enum.KeyCode.Six, Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine, Enum.KeyCode.Zero,
}

ContextActionService:BindAction("SeedHotbarKeys", function(_, state, input)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	for i, key in ipairs(KEYS) do
		if input.KeyCode == key then
			if i <= activeSlots then
				local ref = shownBar()[i] or ""
				if ref ~= "" and not HotbarSlots.isPlaceholder(ref) then
					holdRef(ref)
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
-- They walk the SAME strip the number row reads, in its on-screen order: the
-- next or previous slot that holds something, wrapping at either end, held the
-- moment it is reached. One step per press. Nothing while a panel is up -- the
-- Bag's own LB / RB step its categories instead (InventoryPanel).
--==============================================================================
do
	local PadInput = require(Shared:WaitForChild("PadInput"))

	local function occupiedSlots(): { number }
		local out: { number } = {}
		for i = 1, activeSlots do
			local slot = hotSlots[i]
			local item = if slot then view.byRef[slot.ref] else nil
			if slot and slot.button.Visible and item and not item.restoring
				and ((item.tool and item.tool.Parent) or item.weaponId) then
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
		local heldRef = HotbarSlots.refOfTool(held)
		-- From the slot in the hands, or from just outside either end when the
		-- hands are empty (or hold something the strip is not showing).
		local at = if heldRef then HotbarSlots.slotOf(shownBar(), heldRef) else nil
		local target = PadInput.nextSlot(occupiedSlots(), if at and at <= activeSlots then at else nil,
			if input.KeyCode == Enum.KeyCode.ButtonR1 then 1 else -1)
		if not target then
			return Enum.ContextActionResult.Sink
		end
		local slot = hotSlots[target]
		if slot and slot.ref ~= heldRef then
			holdRef(slot.ref)
			redraw()
		end
		return Enum.ContextActionResult.Sink
	end, false, Enum.KeyCode.ButtonL1, Enum.KeyCode.ButtonR1)
end

--==============================================================================
-- THE COOLDOWN TICK
--
-- One loop for the whole strip, and it only does anything while a BAT on it is
-- recovering or the owner's TRAPS are cooling down. The clock is the SERVER'S:
-- a bat's `ReadyAt` is stamped in server time by CombatService, and so is the
-- trigger cooldown's deadline on the trap records' gui (2026-10-05, read by
-- TrapRemove); `GetServerTimeNow()` is the same clock here. A trap slot shows
-- its placements ("3x", painted with the strip) and, while the owner's
-- cooldown runs, the dim, the shade and the seconds left on EVERY trap slot
-- (HotbarCard.cool) -- one wait for every trap, so no slot looks like a way
-- round it.
--
-- It also steps RarityFX (2026-10-03): the one clock for every Mythic, Divine
-- and Secret light in the Bag and on the strip. RarityFX moves only what is on
-- screen and returns at once when nothing is, at most 30 times a second.
--==============================================================================
RunService.Heartbeat:Connect(function()
	RarityFX.step(os.clock())
	-- Pods hatch in the Bag (2026-10-09): while one still grows, the strip and
	-- an open Bag are drawn again once a second -- every countdown moves, and a
	-- pod whose time has come says READY within the second.
	if podsNow.growing and os.clock() >= (podsNow :: any).nextTick then
		(podsNow :: any).nextTick = os.clock() + 1
		redraw()
	end
	local now = Workspace:GetServerTimeNow()
	local traps = if trapRemove then trapRemove.state() else nil
	local trapLeft = if traps and traps.cooldownUntil then traps.cooldownUntil - now else 0
	for _, slot in ipairs(hotSlots) do
		local isTrap = slot.item ~= nil and (slot.item :: WeaponData.Item).Category == "trap"
		if isTrap or slot.card.cooling then
			HotbarCard.cool(slot.card, HOT, if isTrap and slot.button.Visible then trapLeft else 0,
				WeaponData.Trap.TriggerCooldownSeconds)
		elseif slot.button.Visible and slot.tool and slot.item and slot.item.Category ~= "trap" then
			local readyAt = tonumber(slot.tool:GetAttribute(READY_AT))
			local total = slot.item.Cooldown
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

-- Reduced effects puts a lifted in-hand card back at rest, now.
player:GetAttributeChangedSignal("SeedAfterimageQuality"):Connect(function()
	redraw()
end)

--==============================================================================
-- THE NAME POPUP (2026-10-01)
--
-- `announce(text, sticky)`: sticky is a mouse resting on a slot (or a phone's
-- assignment) -- the name stays until it is taken away -- and not sticky is an
-- equip, which stays NamePopupSeconds. Reduced motion: no fade.
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
			return (GuiService :: any).ReducedMotionEnabled
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
-- And the feedback: the item's visible name over the strip, and a pop on its
-- slot (none under reduced motion).
task.spawn(function()
	local lastHeld: Tool? = nil
	while true do
		local held = heldTool()
		if held ~= lastHeld then
			lastHeld = held
			redraw()
			if held then
				local ref = HotbarSlots.refOfTool(held)
				local item = if ref then view.byRef[ref] else nil
				announce(if item then visibleName(item) else HatchRoll.shownName(held), false)
				local at = if ref then HotbarSlots.slotOf(shownBar(), ref) else nil
				local slot = if at and at <= activeSlots then hotSlots[at] else nil
				if slot then
					HotbarCard.bump(slot.card, player:GetAttribute("SeedAfterimageQuality") == "Off", HOT)
				end
			end
		end
		task.wait(0.15)
	end
end)

redraw()
