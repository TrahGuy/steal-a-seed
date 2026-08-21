--!strict
-- Steal a Seed :: AlertUI
--
-- The alarm. Taking a pod is the most dramatic thing that happens in this game
-- and it used to happen in silence -- a monster woke up somewhere behind you and
-- nothing on screen said so.
--
--==============================================================================
-- THREE LAYERS, AND THEY DO DIFFERENT JOBS
--
--   THE STINGER      one loud moment, so the theft has a beat.
--   THE WORD         "RUN" -- an instruction, not a status. It says what to do
--                    rather than what happened, because a player mid-theft has
--                    no attention spare for reading.
--   THE VIGNETTE     stays up for as long as you are carrying. The stinger
--                    tells you it started; the vignette is what keeps you
--                    nervous the whole way home.
--
-- The vignette PULSES rather than sitting still, because a static red border
-- stops being visible within about two seconds -- the eye filters anything that
-- does not change. A slow throb never quite becomes wallpaper.
--
--==============================================================================
-- IT IS BUILT FROM FRAMES, NOT AN IMAGE
--
-- Four edge gradients rather than a vignette texture. No asset to upload, no
-- asset to 404, and it scales to any aspect ratio for free -- a single vignette
-- image would be stretched wrong on ultrawide and cropped on a phone.
--
--==============================================================================
-- BANKING HAS TO BE ITS OWN SIGNAL
--
-- From the client, losing a pod and banking one look identical: CarryingSpecies
-- goes nil. So the server bumps a BankedCount, and the difference between "I
-- made it" and "I was mugged" is a counter rather than a guess.
--==============================================================================

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local GameConfig = require(ReplicatedStorage:WaitForChild("SeedGame")
	:WaitForChild("Shared"):WaitForChild("GameConfig"))
local ATTR = GameConfig.Attributes

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DANGER = Color3.fromRGB(226, 46, 46)
local SAFE = Color3.fromRGB(126, 216, 86)
local PAPER = Color3.fromRGB(252, 250, 246)

-- Every one of these ships with the client. Verified present rather than
-- assumed: two of the ids tried alongside them load as nothing at all.
local PING = "rbxasset://sounds/electronicpingshort.wav"
local BOOM = "rbxasset://sounds/bass.mp3"

--==============================================================================
-- SOUND
--==============================================================================
local function makeSound(id: string, volume: number, pitch: number): Sound
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = pitch
	-- SoundService, not the character: a 2D alert should not get quieter when
	-- the camera swings, and it must survive the character being ragdolled.
	s.Parent = SoundService
	return s
end

local sounds = {
	stinger = makeSound(BOOM, 0.55, 1.45),
	alarmLow = makeSound(PING, 0.42, 0.55),
	alarmHigh = makeSound(PING, 0.42, 0.78),
	banked = makeSound(PING, 0.5, 1.55),
}
task.spawn(function()
	local list = {}
	for _, s in pairs(sounds) do
		table.insert(list, s)
	end
	pcall(function()
		ContentProvider:PreloadAsync(list)
	end)
end)

local function alarm()
	sounds.stinger:Play()
	task.spawn(function()
		-- Two tones, alternating. One repeated note is a beep; two is an alarm.
		for i = 1, 4 do
			local s = if i % 2 == 1 then sounds.alarmLow else sounds.alarmHigh
			s:Play()
			task.wait(0.19)
		end
	end)
end

--==============================================================================
-- THE SCREEN
--==============================================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SeedAlert"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = playerGui

local edges: { Frame } = {}
local THICKNESS = 0.17

local function edge(name: string, size: UDim2, pos: UDim2, rotation: number)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = DANGER
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.ZIndex = 1
	f.Parent = gui

	local grad = Instance.new("UIGradient")
	grad.Rotation = rotation
	-- Opaque at the screen edge, gone by the time it reaches the middle. The
	-- transparency ramp does the work; the frame's own transparency scales the
	-- whole thing when it pulses.
	grad.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	grad.Parent = f
	table.insert(edges, f)
	return f
end

edge("Top", UDim2.fromScale(1, THICKNESS), UDim2.fromScale(0, 0), 90)
edge("Bottom", UDim2.fromScale(1, THICKNESS), UDim2.fromScale(0, 1 - THICKNESS), 270)
edge("Left", UDim2.fromScale(THICKNESS * 0.62, 1), UDim2.fromScale(0, 0), 0)
edge("Right", UDim2.fromScale(THICKNESS * 0.62, 1),
	UDim2.fromScale(1 - THICKNESS * 0.62, 0), 180)

local word = Instance.new("TextLabel")
word.Name = "Word"
word.AnchorPoint = Vector2.new(0.5, 0.5)
word.Position = UDim2.fromScale(0.5, 0.32)
word.Size = UDim2.fromScale(0.6, 0.16)
word.BackgroundTransparency = 1
word.Font = Enum.Font.GothamBlack
word.TextScaled = true
word.TextColor3 = PAPER
word.TextTransparency = 1
word.ZIndex = 3
word.Parent = gui

local wordStroke = Instance.new("UIStroke")
wordStroke.Thickness = 4
wordStroke.Color = Color3.fromRGB(24, 12, 12)
wordStroke.Transparency = 1
wordStroke.Parent = word

--==============================================================================
-- STATE
--==============================================================================
local carrying = false
local pulse = 0
local intensity = 0
local targetIntensity = 0

local function say(text: string, colour: Color3, hold: number)
	word.Text = text
	word.TextColor3 = colour
	word.Size = UDim2.fromScale(0.85, 0.23)
	word.TextTransparency = 0
	wordStroke.Transparency = 0

	TweenService:Create(word, TweenInfo.new(0.22, Enum.EasingStyle.Back,
		Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.6, 0.16) }):Play()

	task.delay(hold, function()
		if word.Text ~= text then
			-- Something else has already claimed the label. Leave it alone.
			return
		end
		TweenService:Create(word, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(wordStroke, TweenInfo.new(0.4), { Transparency = 1 }):Play()
	end)
end

RunService.RenderStepped:Connect(function(dt)
	intensity += (targetIntensity - intensity) * math.min(1, dt * 6)
	if intensity < 0.002 and targetIntensity == 0 then
		if edges[1].BackgroundTransparency < 1 then
			for _, f in ipairs(edges) do
				f.BackgroundTransparency = 1
			end
		end
		return
	end
	pulse += dt
	-- A slow throb. Static red stops registering within a couple of seconds
	-- because the eye filters anything that does not change.
	local throb = 0.78 + 0.22 * math.sin(pulse * 4.2)
	local alpha = intensity * throb
	for _, f in ipairs(edges) do
		f.BackgroundTransparency = 1 - alpha * 0.62
	end
end)

--==============================================================================
-- TRIGGERS
--==============================================================================
local function onCarryChanged()
	local nowCarrying = player:GetAttribute(ATTR.CarryingSpecies) ~= nil
	if nowCarrying == carrying then
		return
	end
	carrying = nowCarrying

	if carrying then
		targetIntensity = 1
		-- Snap to full rather than easing in: the alarm is the moment, and an
		-- alarm that fades up has already missed it.
		intensity = 1
		for _, f in ipairs(edges) do
			f.BackgroundColor3 = DANGER
		end
		say("RUN", PAPER, 1.0)
		alarm()
	else
		targetIntensity = 0
	end
end

player:GetAttributeChangedSignal(ATTR.CarryingSpecies):Connect(onCarryChanged)

player:GetAttributeChangedSignal(ATTR.BankedCount):Connect(function()
	-- Fires just before or after CarryingSpecies clears, depending on ordering,
	-- so it sets its own word rather than assuming the carry handler ran first.
	targetIntensity = 0
	for _, f in ipairs(edges) do
		f.BackgroundColor3 = SAFE
	end
	say("SAFE", SAFE, 0.7)
	sounds.banked:Play()
end)

-- A respawn clears the carry without the attribute necessarily changing, so
-- resync rather than trusting the last thing seen.
player.CharacterAdded:Connect(function()
	task.defer(onCarryChanged)
end)

onCarryChanged()
