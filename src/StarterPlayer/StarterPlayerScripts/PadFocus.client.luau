--!strict
-- Steal a Seed :: PadFocus
--
-- A controller in the centre panels: where the selection goes when one opens,
-- where it may go while it is open, what B does, and where it goes back to.
--
--==============================================================================
-- WHY ONE SCRIPT AND NOT A CHANGE IN EVERY PANEL
--
-- Every centre panel is a UIKit.modal, and PadInput already knows the moment
-- any of them opens or shuts (its dimmer showing or hiding). So this watches
-- that one signal and does the same four things for all of them -- Index, Shop,
-- Garden, Settings, the Bag, Marigold, Sell and the offline card -- instead of
-- eight copies drifting apart.
--
-- THE ADMIN CONSOLE IS LEFT ALONE. It moves its own selection, binds its own B
-- and steps back through its own pages; a second focus system on top of it
-- would fight it for the selection. Any gui listed in OWN_FOCUS is skipped
-- here entirely -- except that it still counts as "a panel is open" for the
-- world actions (PadInput), so nothing behind it moves either.
--
--==============================================================================
-- OPENED BY A CONTROLLER, SO THE CONTROLLER IS PUT INSIDE IT
--
-- Only when the last input was a gamepad: a mouse or a finger opening the
-- Shop does not want a selection frame appearing on its first card. The
-- control chosen is the panel's own pick if it names one (an ObjectValue
-- called PadFirst under the panel's Shell), otherwise the first control in
-- reading order inside the panel's body -- the first tab, the first product,
-- the first slider -- and the close button only when the body has nothing.
--
-- AFTER THE BUTTON THAT OPENED IT IS LET GO. The A that pressed the rail button
-- is still down when the panel appears; moving the selection under a held A
-- would let its release land on the new control, and one press would have done
-- two things.
--
--==============================================================================
-- INSIDE IT UNTIL IT SHUTS
--
-- The panel's Shell is made a selection group that stops at every edge, so the
-- D-pad walks the panel and never wanders out to the HUD behind the dimmer.
--
--==============================================================================
-- B CLOSES, AND FOCUS GOES BACK
--
-- The six panels on the OpenPanel mutex each close themselves the moment the
-- attribute stops naming them, so clearing it is one close for all six. A panel
-- that is not on the mutex and has its own B (Sell, Marigold) answers first --
-- they bind above this. The offline card has no close on purpose, so B there
-- does nothing rather than skip the claim.
--
-- On the way out the selection goes back to whatever had it before the panel
-- opened -- the rail button, usually -- if that is still on screen and still
-- selectable; otherwise nowhere, which hands the stick back to the character.
-- From there, one more B clears the selection off the HUD and the stick is
-- the character's again.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local PadInput = require(Shared:WaitForChild("PadInput"))
-- Only to ask whether the screen is a TV (the ring is thicker there).
local HudLayout = require(Shared:WaitForChild("HudLayout"))

local ATTR = GameConfig.Attributes
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Guis that run their own controller focus. Never touched here.
local OWN_FOCUS: { [string]: boolean } = {
	SeedAdmin = true,
}

--==============================================================================
-- A SELECTION YOU CAN SEE FROM THE SOFA
--
-- The engine's own selection frame is a thin pale line, which on a television
-- ten feet away is easy to lose -- an Xbox tester lost it. So every selected
-- control, in every panel and on the HUD, gets this instead: a thick gold ring
-- standing just outside the control with a dark keyline inside it, readable on
-- the pale shop cards and on the dark belt alike. It only ever appears when
-- something is SELECTED -- a controller or keyboard navigation -- so a phone,
-- which never selects anything, never sees it.
--==============================================================================
local SELECTION_GOLD = Color3.fromRGB(255, 208, 64)
local SELECTION_INK = Color3.fromRGB(26, 24, 30)

local selectionRing = Instance.new("Frame")
selectionRing.Name = "PadSelection"
selectionRing.BackgroundTransparency = 1
selectionRing.BorderSizePixel = 0
-- Relative to the selected control: its own size plus 7 px all round.
selectionRing.Size = UDim2.new(1, 14, 1, 14)
selectionRing.Position = UDim2.fromOffset(-7, -7)
local ringCorner = Instance.new("UICorner")
ringCorner.CornerRadius = UDim.new(0, 12)
ringCorner.Parent = selectionRing
local ringGold = Instance.new("UIStroke")
ringGold.Color = SELECTION_GOLD
ringGold.Thickness = 4
ringGold.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
ringGold.Parent = selectionRing

local ringInk = Instance.new("Frame")
ringInk.Name = "Keyline"
ringInk.BackgroundTransparency = 1
ringInk.BorderSizePixel = 0
ringInk.Size = UDim2.new(1, -8, 1, -8)
ringInk.Position = UDim2.fromOffset(4, 4)
ringInk.Parent = selectionRing
local inkCorner = Instance.new("UICorner")
inkCorner.CornerRadius = UDim.new(0, 9)
inkCorner.Parent = ringInk
local inkStroke = Instance.new("UIStroke")
inkStroke.Color = SELECTION_INK
inkStroke.Thickness = 2
inkStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
inkStroke.Parent = ringInk

playerGui.SelectionImageObject = selectionRing

-- ON A TV, HEAVIER. The screen is further away (HudLayout's TEN-FOOT PROFILE),
-- so the gold is 6 px standing 9 px out instead of 4 and 7 -- and the gui it is
-- drawn over is magnified on top of that. Asked on every selection change, which
-- is when it is about to be seen; a desktop keeps 4 and 7 exactly.
local function paintRing()
	local tv = HudLayout.isTenFoot()
	local out = if tv then 9 else 7
	ringGold.Thickness = if tv then 6 else 4
	selectionRing.Size = UDim2.new(1, out * 2, 1, out * 2)
	selectionRing.Position = UDim2.fromOffset(-out, -out)
end
paintRing()

-- Between Medium (2000), where a plant's Put away sits, and High (3000), where
-- the panels with their own B sit: those answer first, and this answers before
-- anything in the world does.
local BACK_PRIORITY = 2500
local BACK_ACTION = "SeedPanelBack"
local RELEASE_WAIT = 1.0

-- What had the selection before the managed panel opened, per panel, and which
-- open panels have been handled (so one is never taken as opened twice).
local restoreFor: { [GuiButton]: GuiObject? } = {}
local handled: { [GuiButton]: boolean } = {}
-- Open panels whose selection the ENGINE moved out when it hid the control
-- (see the watch on SelectedObject below).
local evicted: { [GuiButton]: boolean } = {}

local function managed(gui: Instance?): boolean
	return gui ~= nil and not OWN_FOCUS[gui.Name]
end

local function shellOf(dimmer: GuiButton): GuiObject?
	local shell = dimmer:FindFirstChild("Shell", true)
	return if shell and shell:IsA("GuiObject") then shell else nil
end

-- On screen: every ancestor visible and its gui enabled.
local function onScreen(object: GuiObject): boolean
	local node: Instance? = object
	while node and node ~= playerGui do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		if node:IsA("LayerCollector") and not node.Enabled then
			return false
		end
		node = node.Parent
	end
	return node == playerGui
end

local function canSelect(object: Instance): boolean
	return object:IsA("GuiObject") and object.Selectable and object.AbsoluteSize.X > 0
		and object.AbsoluteSize.Y > 0 and object.Name ~= "ClickBlocker"
		and not string.find(object.Name, "Dimmer", 1, true) and onScreen(object)
end

-- Something a press does something to. A ScrollingFrame is selectable as well,
-- so a pad can scroll it, and it sits above its own first card in reading
-- order: the Shop opened with the ring around the whole list instead of on the
-- x2 card. Controls are looked for first; a bare list is only the fallback.
local function isControl(object: Instance): boolean
	return object:IsA("GuiButton") or object:IsA("TextBox")
end

-- The panel's own pick, else the first control in reading order in its body,
-- else anything selectable in the body (a list to scroll), and the rest of the
-- panel -- the close button -- only when the body has nothing.
local function firstControl(shell: GuiObject): GuiObject?
	local pick = shell:FindFirstChild("PadFirst")
	if pick and pick:IsA("ObjectValue") and pick.Value and canSelect(pick.Value) then
		return pick.Value :: GuiObject
	end
	local best: GuiObject? = nil
	local function scan(root: Instance, controlsOnly: boolean)
		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("GuiObject") and (not controlsOnly or isControl(d)) and canSelect(d) then
				local b = best
				if b == nil then
					best = d
				else
					local y, by = d.AbsolutePosition.Y, b.AbsolutePosition.Y
					-- Rows within a few pixels are one row; then left to right.
					if y < by - 4 or (math.abs(y - by) <= 4 and d.AbsolutePosition.X < b.AbsolutePosition.X) then
						best = d
					end
				end
			end
		end
	end
	local body = shell:FindFirstChild("Body")
	if body then
		scan(body, true)
		if best == nil then
			scan(body, false)
		end
	end
	if best == nil then
		scan(shell, true)
	end
	if best == nil then
		scan(shell, false)
	end
	return best
end

local function contain(shell: GuiObject)
	shell.SelectionGroup = true
	shell.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	shell.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	shell.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	shell.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
end

local function anyAButtonDown(): boolean
	for _, pad in ipairs(UserInputService:GetConnectedGamepads()) do
		if UserInputService:IsGamepadButtonDown(pad, Enum.KeyCode.ButtonA) then
			return true
		end
	end
	return false
end

local function focusInside(dimmer: GuiButton)
	local shell = shellOf(dimmer)
	if not shell then
		return
	end
	local selected = GuiService.SelectedObject
	if selected and selected:IsDescendantOf(shell) then
		return
	end
	local target = firstControl(shell)
	if target then
		GuiService.SelectedObject = target
	end
end

local function opened(dimmer: GuiButton, gui: Instance)
	if handled[dimmer] then
		return
	end
	handled[dimmer] = true
	evicted[dimmer] = nil
	local shell = shellOf(dimmer)
	if shell then
		contain(shell)
	end
	local before = GuiService.SelectedObject
	restoreFor[dimmer] = if before and not before:IsDescendantOf(gui) then before else nil
	if not PadInput.active() then
		return
	end
	task.spawn(function()
		local waited = 0
		while anyAButtonDown() and waited < RELEASE_WAIT do
			waited += task.wait()
		end
		if dimmer.Visible then
			focusInside(dimmer)
		end
	end)
end

local function shut(dimmer: GuiButton, gui: Instance)
	handled[dimmer] = nil
	local back = restoreFor[dimmer]
	restoreFor[dimmer] = nil
	local movedByTheEngine = evicted[dimmer] == true
	evicted[dimmer] = nil
	local selected = GuiService.SelectedObject
	-- Only if the selection is still this panel's (or gone, or pushed out by the
	-- panel hiding): something else may already have taken it, and that is not
	-- ours to undo.
	if selected and not selected:IsDescendantOf(gui) and not movedByTheEngine then
		return
	end
	if PadInput.active() and back and canSelect(back) then
		GuiService.SelectedObject = back
	elseif selected then
		GuiService.SelectedObject = nil
	end
end

--==============================================================================
-- THE ENGINE MOVES THE SELECTION FIRST
--
-- Hide the selected control and Roblox re-homes the selection straight away,
-- onto whatever selectable is nearest -- measured in Studio Play on 2026-09-24,
-- closing the Shop put it on hotbar slot 2, in the same frame and BEFORE the
-- panel's shut reached this script. shut() then saw a selection outside
-- the panel, took it for somebody else's and stood aside, and focus never went
-- back to the Shop button.
--
-- So a move is told apart by what it moved FROM: out of an open managed panel,
-- from a control that is no longer on screen, is the engine clearing up after a
-- hide -- that panel's to put right when it shuts. A move from a control still
-- showing was made on purpose and is left alone, as before.
--==============================================================================
local lastSelection: GuiObject? = GuiService.SelectedObject
GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
	paintRing()
	local was = lastSelection
	local now = GuiService.SelectedObject
	lastSelection = now
	if was == nil or onScreen(was) then
		return
	end
	for dimmer in pairs(handled) do
		local gui = dimmer.Parent
		if gui and was:IsDescendantOf(gui) and not (now and now:IsDescendantOf(gui)) then
			evicted[dimmer] = true
		end
	end
end)

PadInput.PanelChanged:Connect(function(dimmer: GuiButton, isOpen: boolean)
	local gui = dimmer.Parent
	if not managed(gui) then
		return
	end
	if isOpen then
		opened(dimmer, gui :: Instance)
	else
		shut(dimmer, gui or playerGui)
	end
end)
PadInput.watch()
-- A panel already up before this was listening -- the offline card at join,
-- if another script started the watch first -- is taken as opened now.
do
	local dimmer, gui = PadInput.openPanel()
	if dimmer and gui and managed(gui) then
		opened(dimmer, gui)
	end
end

-- Picking the controller up while a panel is already open puts it inside the
-- panel, the same as opening it with the controller would have.
PadInput.Changed:Connect(function(onPad: boolean)
	if not onPad then
		return
	end
	local dimmer, gui = PadInput.openPanel()
	if dimmer and managed(gui) then
		focusInside(dimmer)
	end
end)

ContextActionService:BindActionAtPriority(BACK_ACTION, function(_, state: Enum.UserInputState)
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local dimmer, gui = PadInput.openPanel()
	if not (dimmer and managed(gui)) then
		-- No panel up, but the selection is out on the HUD -- where closing a
		-- panel puts it back, on the rail button. B steps out of the HUD: the
		-- stick goes back to the character and the planting reticle, which
		-- hides while the HUD has the selection, comes back. Not while a panel
		-- this script leaves alone (the admin console) is open: that is its B.
		if dimmer == nil and not PadInput.panelOpen() and GuiService.SelectedObject ~= nil then
			GuiService.SelectedObject = nil
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end
	if player:GetAttribute(ATTR.OpenPanel) ~= nil then
		player:SetAttribute(ATTR.OpenPanel, nil)
	end
	-- Sunk either way: with a panel up, B is the panel's and nothing behind it
	-- may act on it -- not even for the offline card, which has no close.
	return Enum.ContextActionResult.Sink
end, false, BACK_PRIORITY, Enum.KeyCode.ButtonB)
