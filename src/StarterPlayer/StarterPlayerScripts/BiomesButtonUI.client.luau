--!strict
-- Steal a Seed :: BiomesButtonUI
--
-- BIOMES (2026-09-30, the owner's brief): one light-blue button beside
-- TELEPORT TO PLOT, on a phone's top row and on a desktop alike, while the
-- player is alive, standing in the Safe Zone and not on the obby course. A
-- press asks for ONE place -- the GREENHOLLOW ENTRANCE, where the biome road
-- begins -- and nothing else: there is no menu, and no other biome is a
-- destination. The rest of the road is walked.
--
--==============================================================================
-- THE CLIENT SHOWS IT. THE SERVER DECIDES IT.
--
-- One verb on GameEvent and nothing after it -- no biome, no position.
-- PlotService.TeleportToBiomes names the landing itself (BiomesLanding: the
-- road's centre line just inside the red line, facing down the road) and checks
-- every press with TELEPORT TO PLOT's own rules and its shared cooldown
-- (PlotService.TeleportTo): alive, in the Safe Zone, no raided pod in the arms,
-- not trapped or knocked down, ground under the landing. A refusal a player can
-- act on comes back as a notice (ActionToastUI).
--
--==============================================================================
-- WHERE, AND HOW IT LOOKS
--
-- HudLayout's `biomes` rect: TELEPORT's own row and height, drawn at TELEPORT's
-- scale -- first on a phone's top row, right after Roblox's buttons; on
-- TELEPORT's other side from OBBY everywhere else. The plate is OBBY's and
-- TELEPORT's, built the same way one level down from the touch area, in a sky
-- blue with a pale rim; the icon is a small tree, drawn from frames, and the
-- word is BIOMES. Where there is only room for the word, only the word; where a
-- screen has no room at all, the rect is empty and the button stays hidden
-- rather than cover anything.
--
-- A CONTROLLER presses it with D-pad Left while it shows (TELEPORT has Up, OBBY
-- has Right), bound only then, and never while a panel is open or the selection
-- is out on the HUD -- that D-pad Left is the UI's (PlotTeleportUI's rule). The
-- button is Selectable, so the UI's own navigation reaches it too.
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

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ATTR = GameConfig.Attributes
local PLOT = GameConfig.Plot
local WHITE = Color3.fromRGB(255, 255, 255)
local BLACK = Color3.fromRGB(0, 0, 0)
-- The light blue of the owner's screenshot, in the plates' own two-tone way.
local SKY_TOP = Color3.fromRGB(120, 200, 255)
local SKY_BOTTOM = Color3.fromRGB(56, 144, 222)
local SKY_EDGE = Color3.fromRGB(214, 242, 255)
local LEAF = Color3.fromRGB(122, 214, 98)
local LEAF_DARK = Color3.fromRGB(64, 160, 72)
local BARK = Color3.fromRGB(134, 88, 52)
local PAD_ACTION = "SeedTeleportToBiomes"

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedBiomesButton")
if existing then
	existing:Destroy()
end
ContextActionService:UnbindAction(PAD_ACTION)

local gui = Instance.new("ScreenGui")
gui.Name = "SeedBiomesButton"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
-- TELEPORT TO PLOT's own order: over the world and the prompts, under every panel.
gui.DisplayOrder = 26
-- Drawn bigger on a TV (HudLayout's TEN-FOOT PROFILE); nothing changes elsewhere.
UIKit.tenFoot(gui)
gui.Parent = playerGui

--==============================================================================
-- THE BUTTON: the touch area is HudLayout's `biomes` rect and draws nothing;
-- the PLATE inside it is drawn at the layout's `teleportScale`, like TELEPORT's.
--==============================================================================
local button = Instance.new("TextButton")
button.Name = "TeleportToBiomes"
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
UIKit.gradient(plate, SKY_TOP, SKY_BOTTOM)
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
UIKit.stroke(rim, SKY_EDGE, 1.5, 0.2)

-- A small round tree on its trunk: the green start of the road, in 28 px.
local icon = Instance.new("Frame")
icon.Name = "Icon"
icon.AnchorPoint = Vector2.new(0, 0.5)
icon.Position = UDim2.new(0, 8, 0.5, 0)
icon.Size = UDim2.fromOffset(28, 28)
icon.BackgroundTransparency = 1
icon.Active = false
icon.Parent = plate
local trunk = UIKit.piece(icon, "Trunk", 0.5, 0.8, 0.16, 0.34, BARK, 0.3)
UIKit.stroke(trunk, BLACK, 1.5)
local crown = UIKit.piece(icon, "Crown", 0.5, 0.4, 0.72, 0.62, LEAF_DARK, 1)
UIKit.stroke(crown, BLACK, 1.5)
UIKit.piece(icon, "Shine", 0.4, 0.32, 0.3, 0.26, LEAF, 1, nil, 3)

local label = UIKit.outlined(plate, "Label", 16, WHITE, 2)
label.AnchorPoint = Vector2.new(0, 0.5)
label.TextScaled = true
label.TextXAlignment = Enum.TextXAlignment.Center
label.Text = "BIOMES"
-- 9 at the least, drawn: the word alone on a 640-px phone's row (HudLayout's
-- `Tight`, drawn at the phone's 0.75) has 36 px for its 33.
local fit = Instance.new("UITextSizeConstraint")
fit.MaxTextSize = 16
fit.MinTextSize = 9
fit.Parent = label

local scale = Instance.new("UIScale")
scale.Parent = button
UIKit.cardPop(button, scale, { hoverScale = 1.04, pressScale = 0.96, sound = false })

--==============================================================================
-- WHERE IT SITS: HudLayout's `biomes`, asked when the screen or the topbar's
-- free span changes -- exactly when TELEPORT TO PLOT asks for its own.
--==============================================================================
local roomy = false
local refresh: () -> ()

local function place()
	if gui.AbsoluteSize.X <= 0 then
		return
	end
	local layout = HudLayout.solve(HudLayout.measure(gui))
	local r = layout.biomes
	roomy = r.w > 0
	if roomy then
		button.Position = HudLayout.place(r, button.AnchorPoint, layout.safe)
		button.Size = UDim2.fromOffset(r.w, r.h)
	end
	plateScale.Scale = layout.teleportScale
	icon.Visible = layout.biomesWide
	if layout.biomesWide then
		label.Position = UDim2.new(0, 42, 0.5, 1)
		label.Size = UDim2.new(1, -50, 0, 22)
	else
		label.Position = UDim2.new(0, 4, 0.5, 1)
		label.Size = UDim2.new(1, -8, 0, 22)
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
	remote:FireServer(PLOT.BiomesAction)
end

button.Activated:Connect(request)

task.spawn(function()
	local remotes = SeedGame:WaitForChild("Remotes", 20)
	local found = if remotes then remotes:WaitForChild(GameConfig.Remotes.GameEvent, 20) else nil
	if found and found:IsA("RemoteEvent") then
		channel = found
	else
		warn("[Seed/BiomesButtonUI] No GameEvent remote; the button cannot ask for anything.")
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
			-- moves the selection left as it would unbound.
			if state == Enum.UserInputState.Begin
				and not (PadInput.panelOpen() or GuiService.SelectedObject ~= nil) then
				request()
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, Enum.KeyCode.DPadLeft)
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
