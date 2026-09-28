--!strict
-- Steal a Seed :: PadInput
--
-- The three questions every controller path asks, answered once: is the player
-- on a gamepad right now, is a panel open, and what does this button look like
-- on the controller in their hands. Client only; nothing here draws or moves
-- anything on screen, and nothing runs on a clock.
--
--==============================================================================
-- ON A GAMEPAD IS STICKY
--
-- GetLastInputType flickers through Focus and None whenever the window gains or
-- loses focus, and a controller path that read it raw would hide its reticle
-- every time the player alt-tabbed. So the answer only changes on a DELIBERATE
-- input: any gamepad input turns it on; the mouse or a finger turns it off.
--
-- The keyboard changes nothing. A player with a controller in their hands who
-- brushes a key has not stopped using the controller, and Studio's Controller
-- Emulator is driven FROM a keyboard -- a mapping that flipped this off on every
-- emulated press would make the emulator useless for testing the pad paths.
--
--==============================================================================
-- A PANEL IS OPEN WHEN ITS DIMMER IS SHOWING
--
-- Every centre panel in the game is a UIKit.modal, and every modal parks a
-- full-screen `<name>Dimmer` button directly under its ScreenGui that is
-- visible exactly while the panel is up. Reading those covers the panels that
-- write OpenPanel (Index, Shop, Garden, Settings, the Bag, Marigold) AND the
-- ones that do not (Sell, the offline card, the admin console) with one rule,
-- and no panel has to register with anything.
--==============================================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared"):WaitForChild("GameConfig"))

local ATTR = GameConfig.Attributes

local PadInput = {}

--==============================================================================
-- ON A GAMEPAD
--==============================================================================
local POINTER: { [Enum.UserInputType]: boolean } = {
	[Enum.UserInputType.MouseButton1] = true,
	[Enum.UserInputType.MouseButton2] = true,
	[Enum.UserInputType.MouseButton3] = true,
	[Enum.UserInputType.MouseWheel] = true,
	[Enum.UserInputType.MouseMovement] = true,
	[Enum.UserInputType.Touch] = true,
}

local function isGamepad(kind: Enum.UserInputType): boolean
	return string.sub(kind.Name, 1, 7) == "Gamepad"
end
PadInput.isGamepad = isGamepad

local padMode = isGamepad(UserInputService:GetLastInputType())
local changed = Instance.new("BindableEvent")

-- Fires with the new answer, and only when it actually changes.
PadInput.Changed = changed.Event

local function consider(kind: Enum.UserInputType)
	local want: boolean? = nil
	if isGamepad(kind) then
		want = true
	elseif POINTER[kind] then
		want = false
	end
	if want ~= nil and want ~= padMode then
		padMode = want
		changed:Fire(want)
	end
end
UserInputService.LastInputTypeChanged:Connect(consider)

function PadInput.active(): boolean
	return padMode
end

--==============================================================================
-- IS A PANEL OPEN
--
-- Watched, not scanned: the placement reticle asks every frame, and a walk over
-- the PlayerGui every frame is an allocation every frame. Each dimmer is found
-- once, as it arrives, and its Visible is followed from then on -- so the
-- question is a table lookup, and `PanelChanged` can tell the focus script the
-- moment a panel comes or goes.
--==============================================================================
local DIMMER_SUFFIX = "Dimmer"

local openDimmers: { [GuiButton]: boolean } = {}
local panelChanged = Instance.new("BindableEvent")

-- Fires (dimmer, isOpen) whenever any panel opens or shuts.
PadInput.PanelChanged = panelChanged.Event

local function follow(dimmer: GuiButton)
	local function update()
		local want = dimmer.Visible and dimmer.Parent ~= nil
		if want == (openDimmers[dimmer] == true) then
			return
		end
		openDimmers[dimmer] = if want then true else nil
		panelChanged:Fire(dimmer, want)
	end
	dimmer:GetPropertyChangedSignal("Visible"):Connect(update)
	dimmer.AncestryChanged:Connect(update)
	update()
end

local function consider(child: Instance)
	if child:IsA("GuiButton") and string.sub(child.Name, -#DIMMER_SUFFIX) == DIMMER_SUFFIX then
		follow(child)
	end
end

local function watchGui(gui: Instance)
	if not gui:IsA("LayerCollector") then
		return
	end
	for _, child in ipairs(gui:GetChildren()) do
		consider(child)
	end
	gui.ChildAdded:Connect(consider)
end

-- Started on the first question rather than at require time, and without
-- waiting: a CAS handler must never yield, and the PlayerGui exists long before
-- anybody can open a panel.
local watching = false
local function watch()
	if watching then
		return
	end
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end
	watching = true
	for _, gui in ipairs(playerGui:GetChildren()) do
		watchGui(gui)
	end
	playerGui.ChildAdded:Connect(watchGui)
end

-- The open panel's dimmer and the ScreenGui it lives in, or nil. Two centre
-- panels are never up at once (OpenPanel is a mutex); the one that is not on
-- that mutex -- the admin console -- is its own gui, and is reported like any
-- other so nothing behind it acts either.
function PadInput.openPanel(): (GuiButton?, LayerCollector?)
	watch()
	for dimmer in pairs(openDimmers) do
		local gui = dimmer.Parent
		if gui and gui:IsA("LayerCollector") and gui.Enabled then
			return dimmer, gui
		end
	end
	return nil, nil
end

function PadInput.panelOpen(): boolean
	local player = Players.LocalPlayer
	if player and player:GetAttribute(ATTR.OpenPanel) ~= nil then
		return true
	end
	return (PadInput.openPanel()) ~= nil
end

-- For a script that wants PanelChanged from the start rather than from its
-- first question.
PadInput.watch = watch

--==============================================================================
-- WHAT THE BUTTON LOOKS LIKE
--
-- The engine's own art for the controller that is actually connected -- Xbox
-- glyphs on an Xbox, PlayStation shapes on a PlayStation pad -- so a hint never
-- tells somebody to press a button their controller does not have. The short
-- name is the fallback for when the engine has no image.
--==============================================================================
local SHORT: { [Enum.KeyCode]: string } = {
	[Enum.KeyCode.ButtonA] = "A",
	[Enum.KeyCode.ButtonB] = "B",
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.ButtonL1] = "LB",
	[Enum.KeyCode.ButtonR1] = "RB",
	[Enum.KeyCode.ButtonL2] = "LT",
	[Enum.KeyCode.ButtonR2] = "RT",
	[Enum.KeyCode.ButtonSelect] = "VIEW",
	[Enum.KeyCode.ButtonStart] = "MENU",
}

function PadInput.glyph(key: Enum.KeyCode): string
	local ok, image = pcall(function()
		return UserInputService:GetImageForKeyCode(key)
	end)
	return if ok and type(image) == "string" then image else ""
end

function PadInput.short(key: Enum.KeyCode): string
	return SHORT[key] or key.Name
end

--==============================================================================
-- WHERE A BUMPER LANDS
--
-- `occupied` is the strip's filled slot numbers in on-screen order; `current`
-- is the slot in the hands (nil when the hands are empty or hold something the
-- strip is not showing); `step` is +1 for RB and -1 for LB. The answer is the
-- next filled slot that way, wrapping at either end -- or, from outside the
-- strip, the first (RB) or the last (LB). nil only for an empty strip. Pure, so
-- ControllerSpec can walk every case without a Play session.
--==============================================================================
function PadInput.nextSlot(occupied: { number }, current: number?, step: number): number?
	local n = #occupied
	if n == 0 then
		return nil
	end
	local position: number? = nil
	if current then
		for k, slot in ipairs(occupied) do
			if slot == current then
				position = k
				break
			end
		end
	end
	if position then
		return occupied[((position - 1 + (if step >= 0 then 1 else -1)) % n) + 1]
	end
	return if step >= 0 then occupied[1] else occupied[n]
end

return PadInput
