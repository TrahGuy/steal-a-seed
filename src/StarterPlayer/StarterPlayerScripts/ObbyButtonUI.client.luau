--!strict
-- Steal a Seed :: ObbyButtonUI
--
-- OBBY: one button right beside TELEPORT TO PLOT (2026-09-27), while the player
-- is alive, standing in the Safe Zone and not already on the course. A press
-- asks for the Floating Garden's ENTRANCE -- in front of the arch, where Return
-- and a fall already land -- never a checkpoint or the finish, and it grants
-- nothing: a run still starts at the Start prompt, like any other.
--
--==============================================================================
-- THE CLIENT SHOWS IT. THE SERVER DECIDES IT.
--
-- One verb on GameEvent and nothing else. ObbyService.TeleportToEntrance
-- checks every press with TELEPORT TO PLOT's own rules and its shared cooldown
-- (PlotService.TeleportTo) -- alive, in the Safe Zone, no raided pod, not
-- trapped or knocked down, ground under the landing -- and on top of those,
-- never during a chase and never with the obby switched off. A refusal a player
-- can act on comes back as a notice (ActionToastUI).
--
--==============================================================================
-- WHERE, AND HOW IT LOOKS
--
-- HudLayout's `obby` rect: TELEPORT's own row and height, 8 px off it, drawn at
-- TELEPORT's scale -- so on a phone it stands up under the clock with it. The
-- plate is TELEPORT's, built the same way one level down from the touch area,
-- in the Index tile's slate with a sky-blue rim so the two never read as one
-- button; the icon is three rising platforms and a pennant, drawn from frames,
-- and the word is OBBY. Where there is only room for the word, only the word;
-- where a screen has no room beside TELEPORT at all, the rect is empty and the
-- button stays hidden rather than cover anything.
--
-- A CONTROLLER presses it with D-pad Right while it shows (TELEPORT has Up),
-- bound only then, and never while a panel is open or the selection is out on
-- the HUD -- that D-pad Right is the UI's (PlotTeleportUI's rule).
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local HudLayout = require(Shared:WaitForChild("HudLayout"))
local UIKit = require(Shared:WaitForChild("UIKit"))
local PadInput = require(Shared:WaitForChild("PadInput"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local WheelData = require(Shared:WaitForChild("WheelData"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local RAIL = GameConfig.Rail
local ATTR = GameConfig.Attributes
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
local GRASS = Color3.fromRGB(132, 222, 104)
local PENNANT = Color3.fromRGB(255, 206, 84)
local PAD_ACTION = "SeedTeleportToObby"

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedObbyButton")
if existing then
	existing:Destroy()
end
ContextActionService:UnbindAction(PAD_ACTION)

-- No course, no button.
if not GameConfig.Obby.Enabled then
	return
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedObbyButton"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
-- TELEPORT TO PLOT's own order: over the world and the prompts, under every panel.
gui.DisplayOrder = 26
-- Drawn bigger on a TV (HudLayout's TEN-FOOT PROFILE); nothing changes elsewhere.
UIKit.tenFoot(gui)
gui.Parent = playerGui

--==============================================================================
-- THE BUTTON: the touch area is HudLayout's `obby` rect and draws nothing; the
-- PLATE inside it is drawn at the layout's `teleportScale`, like TELEPORT's.
--==============================================================================
local button = Instance.new("TextButton")
button.Name = "TeleportToObby"
button.AnchorPoint = Vector2.new(0.5, 0)
button.BackgroundTransparency = 1
button.BorderSizePixel = 0
button.AutoButtonColor = false
button.Selectable = true
button.Text = ""
button.Visible = false
button.Parent = gui
UIKit.clicks(button)

-- The HUD's plate button (UIKit.hudPlate, the global UI pass 2026-10-04): the
-- outline on the BORDER (it never drew on the old text-less label), the
-- family's darker foot, the inner rim, the icon and the outlined word.
local hud = UIKit.hudPlate(button, {
	top = RAIL.TileTop,
	bottom = RAIL.TileBottom,
	rim = RAIL.IndexEdge,
	text = "OBBY",
})
local plate = hud.plate
local plateScale = hud.scale
local rim = hud.rim
local icon = hud.icon
local label = hud.label
-- Three rising platforms and a pennant on the highest: an obby, in 28 px.
for i, at in ipairs({ { 0.2, 0.8 }, { 0.5, 0.58 }, { 0.8, 0.36 } }) do
	local step = UIKit.piece(icon, "Step" .. i, at[1], at[2], 0.34, 0.17, GRASS, 0.3)
	UIKit.stroke(step, BLACK, 1.5)
end
local pole = UIKit.piece(icon, "Pole", 0.88, 0.13, 0.07, 0.3, WHITE, 0.3)
UIKit.stroke(pole, BLACK, 1)
local pennant = UIKit.piece(icon, "Pennant", 0.74, 0.06, 0.22, 0.13, PENNANT, 0.2)
UIKit.stroke(pennant, BLACK, 1)


local scale = Instance.new("UIScale")
scale.Parent = button
UIKit.cardPop(button, scale, { hoverScale = 1.04, pressScale = 0.96, sound = false })

--==============================================================================
-- WHERE IT SITS: HudLayout's `obby`, asked when the screen or the topbar's free
-- span changes -- exactly when TELEPORT TO PLOT asks for its own.
--==============================================================================
local roomy = false
local refresh: () -> ()

local function place()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local r = layout.obby
	roomy = r.w > 0
	if roomy then
		button.Position = HudLayout.place(r, button.AnchorPoint, layout.safe)
		button.Size = UDim2.fromOffset(r.w, r.h)
	end
	plateScale.Scale = layout.teleportScale
	-- The plate before its scale (2026-10-05): its touch area's own size, but on a
	-- phone's even row exactly its touch area once drawn (HudLayout's obbyPlate).
	if roomy then
		plate.Size = UDim2.fromOffset(layout.obbyPlate.X, layout.obbyPlate.Y)
	end
	icon.Visible = layout.obbyWide
	if layout.obbyWide then
		label.Position = UDim2.new(0, 42, 0.5, 1)
		label.Size = UDim2.new(1, -50, 0, 22)
	else
		label.Position = UDim2.new(0, 6, 0.5, 1)
		label.Size = UDim2.new(1, -12, 0, 22)
	end
	refresh()
end

--==============================================================================
-- THE PRESS: guarded only against a double tap sending two requests; the
-- cooldown that matters is the server's, shared with TELEPORT TO PLOT.
--==============================================================================
local channel: RemoteEvent? = nil
local lastPress = 0

local function request()
	local remote = channel
	if not (remote and button.Visible) then
		return
	end
	local now = os.clock()
	if now - lastPress < 0.35 then
		return
	end
	lastPress = now
	remote:FireServer(WheelData.Actions.ObbyTeleport)
	-- A note for this client's own ObbyCamera, which turns the camera to the
	-- arch once if the body does land there. It never leaves this machine.
	player:SetAttribute(ObbyData.LocalAttributes.EntranceAsked, now)
end

button.Activated:Connect(request)

-- LIT BY THE GUIDE, ITS D-PAD KEY STILL PRESSES IT (2026-10-08): D-pad Right,
-- only while TutorialUI's spotlight has it lit (GuideLit) and selected --
-- PlotTeleportUI's listener, and its reasons, word for word.
UserInputService.InputBegan:Connect(function(input: InputObject)
	if input.KeyCode == Enum.KeyCode.DPadRight and button.Visible and button:GetAttribute(ATTR.GuideLit) == true
		and GuiService.SelectedObject == button and not PadInput.panelOpen() then
		request()
	end
end)

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
	else
		warn("[Seed/ObbyButtonUI] No GameEvent remote; the button cannot ask for anything.")
	end
end)

--==============================================================================
-- SHOWN OR NOT
--==============================================================================
local padBound = false

local function bindPad(want: boolean)
	if want == padBound then
		return
	end
	padBound = want
	if want then
		ContextActionService:BindAction(PAD_ACTION, function(_, state: Enum.UserInputState)
			-- Passed on while the UI has the buttons: the engine's navigation then
			-- moves the selection right as it would unbound.
			if state == Enum.UserInputState.Begin
				and not (PadInput.panelOpen() or GuiService.SelectedObject ~= nil) then
				request()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, Enum.KeyCode.DPadRight)
	else
		ContextActionService:UnbindAction(PAD_ACTION)
	end
end

local function alive(): boolean
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return humanoid ~= nil and humanoid.Health > 0
end

refresh = function()
	-- Never on the course (RETURN TO PLOT is the way off it), and never where
	-- the screen had no room for it.
	local want = roomy and alive()
		and player:GetAttribute(ATTR.InSafeZone) == true
		and player:GetAttribute(ObbyData.Attributes.Course) ~= true
	button.Visible = want
	bindPad(want)
end

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(place)
local topbarWatch = GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)
gui.Destroying:Once(function()
	topbarWatch:Disconnect()
	ContextActionService:UnbindAction(PAD_ACTION)
end)

player:GetAttributeChangedSignal(ATTR.InSafeZone):Connect(refresh)
player:GetAttributeChangedSignal(ObbyData.Attributes.Course):Connect(refresh)

local bodyConnections: { RBXScriptConnection } = {}

local function watchBody(character: Model)
	for _, c in ipairs(bodyConnections) do
		c:Disconnect()
	end
	table.clear(bodyConnections)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
		or character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") and character.Parent then
		table.insert(bodyConnections, humanoid.Died:Connect(refresh))
		table.insert(bodyConnections, humanoid.HealthChanged:Connect(refresh))
	end
	refresh()
end

player.CharacterAdded:Connect(watchBody)
player.CharacterRemoving:Connect(function()
	button.Visible = false
	bindPad(false)
end)
if player.Character then
	task.spawn(watchBody, player.Character)
end
place()
