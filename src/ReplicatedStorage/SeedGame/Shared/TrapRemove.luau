--!strict
--==============================================================================
-- Steal a Seed :: TrapRemove (2026-10-04, the reusable-trap brief)
--
-- THE OWNER'S TRAP COUNT, AND THE REMOVE BUTTON OVER THEIR TRAP SLOT. Client
-- only; LoadoutUI owns one, out of its own chunk (which is rationed to Luau's
-- 200 top-level locals).
--
-- THE COUNT IS THE SERVER'S. CombatService writes Placed, Capacity and Newest
-- (WeaponData.Trap) on the owner's records gui -- the disabled ScreenGui
-- MarksGuiName in their own PlayerGui, which no other client receives -- after
-- every confirmed placement and removal, and when they join. Nothing here
-- counts traps or guesses: until that gui has spoken, the count is unknown and
-- the hotbar shows none. Available placements are Capacity - Placed, shared by
-- every trap type: "3x" with none out, "0x" with all three out. A removal
-- changes it at once -- and so does a catch (2026-10-05): the trap it consumed
-- is out no longer.
--
-- AND THE TRIGGER COOLDOWN (2026-10-05): the deadline CombatService writes on
-- the same gui (WeaponData.Trap.CooldownAttribute, SERVER time) while one of
-- the owner's traps has just caught somebody. `cooldownUntil` carries it; the
-- strip's Heartbeat counts it down on every trap slot against
-- GetServerTimeNow, and nothing here guesses it.
--
-- THE BUTTON. While at least one trap is out and a trap stands in a shown
-- hotbar slot, a small REMOVE stands just over that slot (LoadoutUI names the
-- slot: the trap in the player's hands if it is on the strip, else the first
-- trap on it -- never a fixed slot number). HudLayout reserves its row and
-- says where it goes (removeButton): the plate is drawn small, the press lands
-- on the whole row over the slot, which on a touch screen is RemoveTouch tall.
-- It is Selectable, so a controller reaches it the way it reaches the HUD's
-- other buttons; up from the trap slot and down back to it.
--
-- A PRESS asks the server to remove the NEWEST trap the records show, naming
-- its id (GameConfig.Weapon.TrapRemoveAction). The server checks it is still
-- this player's newest; a repeat names a trap already gone and does nothing.
-- One request per newest id until the server answers (the records' Newest
-- changes) or a second passes, and no two presses inside PRESS_GAP, so a
-- double tap never takes two traps. The Bag's details ask through the same
-- press when the trap is on no shown slot.
--
-- Nothing here runs per frame: it repaints on the records' attribute changes.
--==============================================================================
local GuiService = game:GetService("GuiService")

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local TrapRemove = {}

local T = WeaponData.Trap
local HOT = GameConfig.Hotbar
local PENDING_SECONDS = 1
-- Presses closer together than this count once (Play, 2026-10-04: a quick
-- double-click took two traps, because the server had already answered the
-- first). A deliberate second press is slower than this.
local PRESS_GAP = 0.35

export type State = {
	-- Whether the server's count has arrived at all.
	known: boolean,
	placed: number,
	capacity: number,
	-- The id of the owner's newest trap, 0 for none.
	newest: number,
	-- Placements still available: capacity - placed, never below 0.
	left: number,
	-- The trigger cooldown's deadline in SERVER time, or nil when none runs.
	cooldownUntil: number?,
}

export type Options = {
	player: Player,
	-- The GameEvent remote, once LoadoutUI has found it.
	channel: () -> RemoteEvent?,
	-- The count changed: repaint the strip (and the Bag, if open).
	changed: () -> (),
}

export type Handle = {
	state: () -> State,
	-- Ask the server to remove the newest trap (the button, the Bag's details).
	press: () -> boolean,
	-- LoadoutUI's three facts: the layout, the slot the trap stands in (nil for
	-- none shown), and whether the strip is on screen and at rest.
	layout: (HudLayout.Layout?) -> (),
	slot: (number?, GuiObject?) -> (),
	strip: (boolean) -> (),
	button: TextButton,
}

-- The state off the records gui, or "unknown" without one.
function TrapRemove.read(marks: Instance?): State
	if not marks then
		return { known = false, placed = 0, capacity = T.MaxActivePerPlayer, newest = 0,
			left = T.MaxActivePerPlayer, cooldownUntil = nil }
	end
	local cooling = marks:GetAttribute(T.CooldownAttribute)
	local capacity = marks:GetAttribute(T.CapacityAttribute)
	local placed = marks:GetAttribute(T.PlacedAttribute)
	local newest = tonumber(marks:GetAttribute(T.NewestAttribute)) or 0
	local known = type(capacity) == "number" and type(placed) == "number"
	local cap = if type(capacity) == "number" then capacity else T.MaxActivePerPlayer
	local out = if type(placed) == "number" then math.max(0, math.floor(placed)) else 0
	return {
		known = known,
		placed = out,
		capacity = cap,
		newest = if newest == newest and newest >= 1 then math.floor(newest) else 0,
		left = WeaponData.TrapsLeft(out, cap),
		cooldownUntil = if type(cooling) == "number" and cooling == cooling then cooling else nil,
	}
end

function TrapRemove.new(gui: ScreenGui, opts: Options): Handle
	local player = opts.player
	local current: State = TrapRemove.read(nil)
	local marks: Instance? = nil
	local marksConns: { RBXScriptConnection } = {}
	local layout: HudLayout.Layout? = nil
	local slotIndex: number? = nil
	local slotButton: GuiObject? = nil
	local stripShown = true
	local pendingFor, pendingUntil = 0, 0
	local lastPress = -math.huge
	local rowWanted: boolean? = nil

	--==========================================================================
	-- THE BUTTON: a clear press area over the slot, a small plate at its foot
	--==========================================================================
	local button = Instance.new("TextButton")
	button.Name = "TrapRemove"
	button.BackgroundTransparency = 1
	button.BorderSizePixel = 0
	button.AutoButtonColor = false
	button.Text = ""
	button.Selectable = true
	button.Visible = false
	button.ZIndex = 12
	button.Parent = gui

	-- The family's red (the global UI pass, 2026-10-04): REMOVE is destructive,
	-- so it wears the danger face -- red with its darker foot and a deep red
	-- keyline -- with the word white and ink-lined.
	local LOOK = GameConfig.BagLook
	local plate = Instance.new("Frame")
	plate.Name = "Plate"
	plate.BackgroundColor3 = Color3.new(1, 1, 1)
	plate.BackgroundTransparency = 0.12
	plate.BorderSizePixel = 0
	plate.Active = false
	plate.ZIndex = 13
	plate.Parent = button
	UIKit.corner(plate, 6)
	local face = Instance.new("UIGradient")
	face.Rotation = 90
	face.Color = UIKit.footColours(LOOK.DangerTop, LOOK.DangerBottom, LOOK.DangerEdge)
	face.Parent = plate
	local edge = UIKit.stroke(plate, LOOK.DangerEdge, 1.5, 0)
	edge.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local plateScale = Instance.new("UIScale")
	plateScale.Parent = plate

	local words = Instance.new("TextLabel")
	words.Name = "Words"
	words.Size = UDim2.fromScale(1, 1)
	words.BackgroundTransparency = 1
	words.Font = Enum.Font.FredokaOne
	words.TextSize = HOT.RemoveText
	words.TextColor3 = Color3.new(1, 1, 1)
	words.Text = HOT.RemoveWords
	words.ZIndex = 14
	words.Parent = plate
	UIKit.stroke(words, HOT.Ink, 1.2)

	UIKit.cardPop(button, plateScale, {
		hoverScale = 1.06,
		pressScale = 0.94,
		sound = false,
	})

	local function paint()
		local waiting = pendingFor ~= 0 and os.clock() < pendingUntil
		plate.BackgroundTransparency = if waiting then 0.45 else 0.12
		words.TextTransparency = if waiting then 0.45 else 0
	end

	--==========================================================================
	-- WHERE IT STANDS, AND WHETHER
	--
	-- Shown only with a trap out, a trap slot named, a layout that reserved the
	-- row, and the strip on screen and at rest. Publishing the row is what makes
	-- HudLayout reserve it -- for every HUD owner at once -- so it is published
	-- from the facts that do not depend on the layout: a trap out and a trap
	-- slot shown.
	--==========================================================================
	local function place()
		local want = current.known and current.placed >= 1 and slotIndex ~= nil
		if rowWanted ~= want then
			rowWanted = want
			player:SetAttribute(HOT.RemoveRowAttribute, if want then true else nil)
		end
		local L = layout
		local press, drawn = nil, nil
		if want and L and slotIndex then
			press, drawn = HudLayout.removeButton(L, slotIndex)
		end
		local show = want and stripShown and press ~= nil and drawn ~= nil
		if show and L and press and drawn then
			button.Position = HudLayout.place(press, Vector2.zero, L.safe)
			button.Size = UDim2.fromOffset(press.w, press.h)
			plate.Position = UDim2.fromOffset(drawn.x - press.x, drawn.y - press.y)
			plate.Size = UDim2.fromOffset(drawn.w, drawn.h)
			words.TextSize = L.hot.RemoveText or HOT.RemoveText
		end
		if button.Visible ~= show then
			button.Visible = show
			-- A controller's selection on a button that just went goes back down
			-- to the trap's slot rather than nowhere.
			if not show and GuiService.SelectedObject == button then
				GuiService.SelectedObject = slotButton :: any
			end
		end
		-- A controller steps up from the trap's slot onto REMOVE, and back down.
		button.NextSelectionDown = slotButton
		if slotButton then
			(slotButton :: any).NextSelectionUp = if show then button else nil
		end
		paint()
	end

	--==========================================================================
	-- THE RECORDS GUI: found when it arrives, read when it changes
	--==========================================================================
	local function reread()
		local was = current
		current = TrapRemove.read(marks)
		if current.newest ~= pendingFor then
			pendingFor = 0
		end
		place()
		if was.known ~= current.known or was.placed ~= current.placed or was.capacity ~= current.capacity
			or was.newest ~= current.newest or was.cooldownUntil ~= current.cooldownUntil then
			opts.changed()
		end
	end

	local function follow(found: Instance?)
		for _, c in ipairs(marksConns) do
			c:Disconnect()
		end
		table.clear(marksConns)
		marks = found
		if found then
			for _, name in ipairs({ T.PlacedAttribute, T.CapacityAttribute, T.NewestAttribute, T.CooldownAttribute }) do
				table.insert(marksConns, found:GetAttributeChangedSignal(name):Connect(reread))
			end
			table.insert(marksConns, found.AncestryChanged:Connect(function()
				if not found:IsDescendantOf(game) and marks == found then
					follow(nil)
				end
			end))
		end
		reread()
	end

	local playerGui = player:WaitForChild("PlayerGui")
	follow(playerGui:FindFirstChild(T.MarksGuiName))
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == T.MarksGuiName then
			follow(child)
		end
	end)

	--==========================================================================
	-- THE PRESS
	--==========================================================================
	local function press(): boolean
		local s = current
		if not (s.known and s.placed >= 1 and s.newest >= 1) then
			return false
		end
		if pendingFor == s.newest and os.clock() < pendingUntil then
			return false
		end
		if os.clock() - lastPress < PRESS_GAP then
			return false
		end
		local remote = opts.channel()
		if not remote then
			return false
		end
		lastPress = os.clock()
		pendingFor = s.newest
		pendingUntil = os.clock() + PENDING_SECONDS
		remote:FireServer(GameConfig.Weapon.TrapRemoveAction, s.newest)
		SoundKit.play("CardClick")
		paint()
		task.delay(PENDING_SECONDS, paint)
		return true
	end
	button.Activated:Connect(function()
		press()
	end)

	return {
		state = function(): State
			return current
		end,
		press = press,
		layout = function(L: HudLayout.Layout?)
			layout = L
			place()
		end,
		slot = function(index: number?, slotObject: GuiObject?)
			if slotButton and slotButton ~= slotObject then
				(slotButton :: any).NextSelectionUp = nil
			end
			slotIndex = index
			slotButton = slotObject
			place()
		end,
		strip = function(shown: boolean)
			stripShown = shown
			place()
		end,
		button = button,
	}
end

return TrapRemove
