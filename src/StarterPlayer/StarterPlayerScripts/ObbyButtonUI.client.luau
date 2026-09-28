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

local plate = Instance.new("TextLabel")
plate.Name = "Plate"
plate.AnchorPoint = Vector2.new(0.5, 0.5)
plate.Position = UDim2.fromScale(0.5, 0.5)
plate.Size = UDim2.fromScale(1, 1)
plate.BackgroundColor3 = WHITE
plate.BorderSizePixel = 0
plate.Text = ""
plate.Active = false
plate.Parent = button
UIKit.corner(plate, 12)
UIKit.stroke(plate, BLACK, 2.5)
UIKit.gradient(plate, RAIL.TileTop, RAIL.TileBottom)
local plateScale = Instance.new("UIScale")
plateScale.Parent = plate

local rim = Instance.new("Frame")
rim.Name = "Rim"
rim.AnchorPoint = Vector2.new(0.5, 0.5)
rim.Position = UDim2.fromScale(0.5, 0.5)
rim.Size = UDim2.new(1, -5, 1, -5)
rim.BackgroundTransparency = 1
rim.BorderSizePixel = 0
rim.Active = false
rim.Parent = plate
UIKit.corner(rim, 10)
UIKit.stroke(rim, RAIL.IndexEdge, 1.5, 0.2)

-- Three rising platforms and a pennant on the highest: an obby, in 28 px.
local icon = Instance.new("Frame")
icon.Name = "Icon"
icon.AnchorPoint = Vector2.new(0, 0.5)
icon.Position = UDim2.new(0, 8, 0.5, 0)
icon.Size = UDim2.fromOffset(28, 28)
icon.BackgroundTransparency = 1
icon.Active = false
icon.Parent = plate
for i, at in ipairs({ { 0.2, 0.8 }, { 0.5, 0.58 }, { 0.8, 0.36 } }) do
	local step = UIKit.piece(icon, "Step" .. i, at[1], at[2], 0.34, 0.17, GRASS, 0.3)
	UIKit.stroke(step, BLACK, 1.5)
end
local pole = UIKit.piece(icon, "Pole", 0.88, 0.13, 0.07, 0.3, WHITE, 0.3)
UIKit.stroke(pole, BLACK, 1)
local pennant = UIKit.piece(icon, "Pennant", 0.74, 0.06, 0.22, 0.13, PENNANT, 0.2)
UIKit.stroke(pennant, BLACK, 1)

local label = UIKit.outlined(plate, "Label", 16, WHITE, 2)
label.AnchorPoint = Vector2.new(0, 0.5)
label.TextScaled = true
label.TextXAlignment = Enum.TextXAlignment.Center
label.Text = "OBBY"
local fit = Instance.new("UITextSizeConstraint")
fit.MaxTextSize = 16
fit.MinTextSize = 10
fit.Parent = label

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
end

button.Activated:Connect(request)

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
