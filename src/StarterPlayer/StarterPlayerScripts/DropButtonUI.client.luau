--!strict
-- Steal a Seed :: DropButtonUI
--
--==============================================================================
-- THE DROP BUTTON, IN THE HOTBAR'S PLACE (2026-10-10)
--
-- Michael, on v1047, passed on by the owner: "Once you steal an egg from a
-- nest, a red 'Drop' button appears at the bottom of the screen. Pressing it
-- leaves the egg on the ground, allowing any other player in the server to pick
-- it up." And the owner: "we can remove the hotbar while the drop button
-- appears, so the button will replace hotbar position".
--
-- WHILE A RAID POD IS CARRIED -- the server's own replicated CarryingSpecies,
-- never a Bag pod held as a Tool (Q / B put that one away) -- the owner's
-- picture (GameConfig.ContextSlot.Drop) stands centred in the strip's rect
-- (HudLayout.contextButton), as tall as the strip. The hands are full then
-- (CarryService puts every Tool away on a take), so the strip has nothing to
-- offer: this raises the client-local YieldPrefix .. "Drop" attribute and
-- LoadoutUI hides the strip, its number keys and LB / RB until it goes.
--
-- A PRESS -- a click, a tap, Backspace, or B on a controller while no panel or
-- HUD selection has it -- asks the server for the GameEvent verb Action. The
-- server checks the carry and drops the pod at the player's feet, the
-- knock-down's own drop (CarryService.Drop): anyone may take it, until dusk.
-- Presses closer than PressGap count once. It asks; it decides nothing.
--==============================================================================

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))
local PadInput = require(Shared:WaitForChild("PadInput"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local channel = SeedGame:WaitForChild("Remotes"):WaitForChild(GameConfig.Remotes.GameEvent) :: RemoteEvent

local ATTR = GameConfig.Attributes
local CS = GameConfig.ContextSlot
local D = CS.Drop
local YIELD = CS.YieldPrefix .. "Drop"
local ACTION = "SeedDropPod"

local stale = playerGui:FindFirstChild("SeedDropButton")
if stale then
	stale:Destroy()
end

-- The strip's own gui settings (LoadoutUI): the same safe space, the same TV
-- scale, the same place in the order.
local gui = Instance.new("ScreenGui")
gui.Name = "SeedDropButton"
gui.ResetOnSpawn = false
gui.DisplayOrder = 30
UIKit.tenFoot(gui)
gui.Parent = playerGui

local button = Instance.new("ImageButton")
button.Name = "Drop"
button.BackgroundTransparency = 1
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Image = D.Image
button.ScaleType = Enum.ScaleType.Fit
button.Visible = false
button.Parent = gui
UIKit.clicks(button)

local function carrying(): boolean
	return player:GetAttribute(ATTR.CarryingSpecies) ~= nil
end

local function place()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local r = HudLayout.contextButton(layout, D.Aspect)
	button.Position = HudLayout.place(r, Vector2.zero, layout.safe)
	button.Size = UDim2.fromOffset(r.w, r.h)
end

local lastPress = -math.huge
local function press()
	local now = os.clock()
	if not carrying() or now - lastPress < D.PressGap then
		return
	end
	lastPress = now
	SoundKit.play("CardClick")
	channel:FireServer(D.Action)
end
button.Activated:Connect(press)

-- Backspace and B. A controller's B belongs to an open panel or a HUD selection
-- first (PadFocus closes or clears), so it passes then.
local function onKey(_name: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult?
	if state ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if input.KeyCode == Enum.KeyCode.ButtonB and (PadInput.panelOpen() or GuiService.SelectedObject ~= nil) then
		return Enum.ContextActionResult.Pass
	end
	press()
	return Enum.ContextActionResult.Sink
end

local shown = false
local function refresh()
	local want = carrying()
	if want == shown then
		return
	end
	shown = want
	if want then
		place()
		ContextActionService:BindActionAtPriority(ACTION, onKey, false, Enum.ContextActionPriority.High.Value,
			table.unpack(D.Keys))
	else
		ContextActionService:UnbindAction(ACTION)
	end
	button.Visible = want
	player:SetAttribute(YIELD, if want then true else nil)
end

player:GetAttributeChangedSignal(ATTR.CarryingSpecies):Connect(refresh)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	if shown then
		place()
	end
end)
refresh()
