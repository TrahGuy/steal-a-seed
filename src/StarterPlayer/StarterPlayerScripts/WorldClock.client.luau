--!strict
-- Steal a Seed :: WorldClock
--
-- The countdown at the top of the screen, and the night the world falls into.
--
--==============================================================================
-- THE COUNTDOWN IS A SUBTRACTION, NOT A BROADCAST
--
-- The server publishes three attributes on the Workspace and nothing else:
--
--     WorldPhase        "Day" or "Night"
--     WorldPhaseEndsAt  an absolute workspace:GetServerTimeNow()
--     WorldCycleIndex   bumped at every dawn
--
-- This subtracts one from the other every frame it draws. A seven-minute day
-- therefore costs the server three attribute writes instead of 420 remote calls
-- per player, and -- the part that actually matters -- somebody who joins at
-- 03:12 is CORRECT ON THEIR FIRST FRAME. There is no join handshake to miss, no
-- window where the HUD says the wrong thing, and no packet that can arrive late.
--
-- GetServerTimeNow is the same clock on every machine, so two players watching
-- the same countdown see the same number.
--
--==============================================================================
-- NIGHT IS BLUE, NOT BLACK
--
-- People plant, harvest and stand on their mills through the night. A night that
-- made a player's own garden unreadable would be a night they wait out looking
-- at a wall, so the plots stay usable and the drop is in colour temperature far
-- more than in brightness.
--
-- THE DAY VALUES ARE CAPTURED, NOT TYPED. MapService sets the daytime lighting
-- and this reads whatever it finds at boot, so "restore the exact daytime
-- visibility at dawn" is true by construction rather than by two files agreeing
-- about eight numbers. Retune MapService and this follows.
--
-- Entirely client-side. The server never touches Lighting -- which is why the
-- transition costs it nothing and cannot desync anybody -- and the one thing
-- concealment actually depends on is a real part across the road, not this.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local CYCLE = GameConfig.WorldCycle
local ATTR = GameConfig.Attributes
local NIGHT = CYCLE.Night

local INK = Color3.fromRGB(26, 24, 30)
local PAPER = Color3.fromRGB(248, 246, 240)
local WARN = Color3.fromRGB(255, 186, 84)
local NIGHT_INK = Color3.fromRGB(150, 196, 255)

--==============================================================================
-- RE-RUN SAFE
--
-- Rule 10. A Rojo sync re-runs this while the old readout is still on screen,
-- and two countdowns a frame apart is the kind of thing that gets blamed on the
-- clock rather than on the reload.
--==============================================================================
local existing = playerGui:FindFirstChild("SeedWorldClock")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedWorldClock"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 30
gui.Parent = playerGui

--==============================================================================
-- TOP CENTRE, AND SIZED IN SCALE
--
-- Scale rather than offset so it is the same fraction of a phone screen as of a
-- monitor, with a pixel cap so it does not become a banner on an ultrawide.
-- IgnoreGuiInset is on, so this sits clear of the Roblox topbar on every device
-- rather than under it on some.
--==============================================================================
local plate = Instance.new("Frame")
plate.Name = "Plate"
plate.AnchorPoint = Vector2.new(0.5, 0)
plate.Position = UDim2.new(0.5, 0, 0, 8)
plate.Size = UDim2.new(0.44, 0, 0, 34)
plate.BackgroundColor3 = Color3.fromRGB(24, 26, 32)
plate.BackgroundTransparency = 0.25
plate.BorderSizePixel = 0
plate.Parent = gui

local cap = Instance.new("UISizeConstraint")
cap.MinSize = Vector2.new(190, 28)
cap.MaxSize = Vector2.new(360, 40)
cap.Parent = plate

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = plate

local edge = Instance.new("UIStroke")
edge.Color = INK
edge.Thickness = 2.5
edge.Parent = plate

local text = Instance.new("TextLabel")
text.Name = "Text"
text.Size = UDim2.new(1, -16, 1, -8)
text.Position = UDim2.fromOffset(8, 4)
text.BackgroundTransparency = 1
text.Font = Enum.Font.GothamBlack
text.TextScaled = true
text.TextColor3 = PAPER
text.Text = ""
text.Parent = plate

local textEdge = Instance.new("UIStroke")
textEdge.Color = INK
textEdge.Thickness = 2
textEdge.Parent = text

--==============================================================================
-- THE THREE THINGS IT CAN SAY
--
--     DAY • 06:59                 the ordinary case
--     BIOMES CLOSE IN 00:45       the last 45 seconds of the day
--     NIGHT • PODS RETURN IN 00:59
--
-- The warning is a different SENTENCE and a different colour, not a colour
-- change alone -- a player who is colourblind or looking at their plot rather
-- than the top of the screen gets the same information from the words.
--==============================================================================
local function clock(seconds: number): string
	local whole = math.max(0, math.floor(seconds))
	return string.format("%02d:%02d", math.floor(whole / 60), whole % 60)
end

local lastText = ""
local lastColour = PAPER

local function draw()
	local phase = Workspace:GetAttribute(ATTR.WorldPhase)
	local endsAt = Workspace:GetAttribute(ATTR.WorldPhaseEndsAt)
	if type(phase) ~= "string" or type(endsAt) ~= "number" then
		-- The cycle service has not published yet. Silent rather than wrong: a
		-- readout guessing at a phase is worse than no readout for one frame.
		plate.Visible = false
		return
	end
	plate.Visible = true

	local left = math.max(0, endsAt - Workspace:GetServerTimeNow())
	local wording: string
	local colour: Color3

	if phase == CYCLE.PhaseNight then
		wording = "NIGHT  •  PODS RETURN IN " .. clock(left)
		colour = NIGHT_INK
	elseif left <= CYCLE.WarnSeconds then
		wording = "BIOMES CLOSE IN " .. clock(left)
		colour = WARN
	else
		wording = "DAY  •  " .. clock(left)
		colour = PAPER
	end

	-- Written only when it changes. TextScaled re-measures on every assignment,
	-- and this draws every frame.
	if wording ~= lastText then
		lastText = wording
		text.Text = wording
	end
	if colour ~= lastColour then
		lastColour = colour
		text.TextColor3 = colour
	end
end

--==============================================================================
-- THE LIGHT
--
-- Captured at boot from whatever MapService set, so dawn restores the real
-- daytime values rather than a second copy of them that could drift.
--==============================================================================
type Look = {
	ClockTime: number,
	Brightness: number,
	Ambient: Color3,
	OutdoorAmbient: Color3,
	EnvironmentDiffuseScale: number,
	ExposureCompensation: number,
}

local day: Look = {
	ClockTime = Lighting.ClockTime,
	Brightness = Lighting.Brightness,
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	ExposureCompensation = Lighting.ExposureCompensation,
}

local night: Look = {
	ClockTime = NIGHT.ClockTime,
	Brightness = NIGHT.Brightness,
	Ambient = NIGHT.Ambient,
	OutdoorAmbient = NIGHT.OutdoorAmbient,
	EnvironmentDiffuseScale = NIGHT.EnvironmentDiffuseScale,
	ExposureCompensation = NIGHT.ExposureCompensation,
}

--==============================================================================
-- BLENDED, NOT TWEENED
--
-- One number carries the whole transition and every property is read off it, so
-- a phase that flips back mid-fade simply reverses -- where six TweenService
-- tweens would have to be found and cancelled, and any that were missed would
-- keep pulling towards a night that is already over.
--
-- ClockTime wraps at 24, so it is moved DOWN from 14 to 0 rather than up through
-- midnight, which would spin the sun the long way round.
--==============================================================================
local blend = 0

local function applyLight(t: number)
	Lighting.ClockTime = day.ClockTime + (night.ClockTime - day.ClockTime) * t
	Lighting.Brightness = day.Brightness + (night.Brightness - day.Brightness) * t
	Lighting.Ambient = day.Ambient:Lerp(night.Ambient, t)
	Lighting.OutdoorAmbient = day.OutdoorAmbient:Lerp(night.OutdoorAmbient, t)
	Lighting.EnvironmentDiffuseScale = day.EnvironmentDiffuseScale
		+ (night.EnvironmentDiffuseScale - day.EnvironmentDiffuseScale) * t
	Lighting.ExposureCompensation = day.ExposureCompensation
		+ (night.ExposureCompensation - day.ExposureCompensation) * t
end

RunService.RenderStepped:Connect(function(dt)
	draw()

	local want = if Workspace:GetAttribute(ATTR.WorldPhase) == CYCLE.PhaseNight then 1 else 0
	if blend ~= want then
		local step = dt / math.max(0.05, NIGHT.FadeSeconds)
		blend = if want > blend
			then math.min(want, blend + step)
			else math.max(want, blend - step)
		applyLight(blend)
	end
end)

draw()
applyLight(if Workspace:GetAttribute(ATTR.WorldPhase) == CYCLE.PhaseNight then 1 else 0)
blend = if Workspace:GetAttribute(ATTR.WorldPhase) == CYCLE.PhaseNight then 1 else 0
