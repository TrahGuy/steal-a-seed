--!strict
-- Steal a Seed :: SpeedFX
--
-- Two pieces of feedback for the one stat you grind: a `+N` that pops off the
-- character when the treadmill pays, and a streak behind you when you are
-- actually moving fast.
--
--==============================================================================
-- NO SECOND REMOTE
--
-- The pop is driven by DIFFING profile.Speed off the ProfileUpdated packet that
-- already arrives four times a second. The server does not announce "you earned
-- 2"; the client notices the number went up and says so. One less remote, and
-- it is automatically correct for any source of Speed added later.
--
--==============================================================================
-- THE STREAK IS READ OFF WalkSpeed, NOT OFF THE SCORE
--
-- Speed SCORE is what you own; WalkSpeed is what you are doing. The streak is
-- about motion, so it watches the humanoid -- which means it also appears when
-- a heavy pod is slowing you down and does not, and that is correct: it should
-- reflect how fast you are actually going home.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local ACCENT = Color3.fromRGB(142, 196, 62)
local INK = Color3.fromRGB(26, 24, 30)
-- The shoe is blue on purpose: it is the only thing in this palette that is not
-- ink, paper or green, which is what makes a +2 read as SPEED at a glance
-- rather than as another cash tick.
local SHOE = Color3.fromRGB(96, 164, 232)

--==============================================================================
-- THE GATE IS AN ABSOLUTE MARGIN, NOT A MULTIPLIER
--
-- It was walkSpeedFor(0) * 1.55 = 24.8, and the curve is far flatter than that
-- assumed -- Scale is 20,000, so:
--
--     Speed   180  ->  WalkSpeed 17.20
--     Speed   400  ->  WalkSpeed 18.65
--     Speed 1,265  ->  WalkSpeed 24.80   <- where the old gate sat
--
-- Twenty-one minutes of milling before the streak ever appeared once, which is
-- why the lane trail was never seen. A margin ABOVE the floor scales with the
-- curve instead of fighting it: base + 1.2 lands at ~180 Speed, about ninety
-- seconds on the belt, so a first session gets the hint it is meant to get.
--
-- Still strictly above base 16, so it is off for a player who has never milled,
-- and the MoveDirection test below keeps it off when standing still.
--==============================================================================
local STREAK_AT = GameConfig.walkSpeedFor(0) + 1.2
-- Fully opaque by this much over the gate, so it starts as a hint and grows.
local STREAK_FULL_AT = STREAK_AT + 14

--==============================================================================
-- RE-RUN SAFE
--==============================================================================
local existing = playerGui:FindFirstChild("SeedSpeedFX")
if existing then
	existing:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "SeedSpeedFX"
gui.ResetOnSpawn = false
gui.DisplayOrder = 25
gui.Parent = playerGui

--==============================================================================
-- THE POP
--
-- A small POOL rather than one Instance.new per payout. The treadmill pays once
-- a second for as long as somebody stands on it, which over a long session is
-- thousands of billboards created and collected for no reason.
--==============================================================================
local POOL_SIZE = 5
local pool: { BillboardGui } = {}
local nextInPool = 1

for i = 1, POOL_SIZE do
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Pop" .. i
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(90, 30)
	billboard.Enabled = false
	billboard.MaxDistance = 90
	billboard.Parent = gui

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(1, -26, 1, 0)
	label.Position = UDim2.fromOffset(26, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = ACCENT
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Text = ""
	label.Parent = billboard

	--== THE SHOE ==--
	-- Drawn from two rounded frames rather than set as a glyph. Most of Gotham's
	-- symbol range renders as tofu boxes in this engine -- checked, and a
	-- trainer emoji is one of them -- so a shoe made of rectangles is the only
	-- one guaranteed to be a shoe on every device.
	local shoe = Instance.new("Frame")
	shoe.Name = "Shoe"
	shoe.Size = UDim2.fromOffset(22, 20)
	shoe.Position = UDim2.fromOffset(0, 5)
	shoe.BackgroundTransparency = 1
	shoe.Parent = billboard

	local upper = Instance.new("Frame")
	upper.Name = "Upper"
	upper.Size = UDim2.fromOffset(14, 11)
	upper.Position = UDim2.fromOffset(6, 0)
	upper.BackgroundColor3 = SHOE
	upper.BorderSizePixel = 0
	upper.Parent = shoe
	local upperCorner = Instance.new("UICorner")
	upperCorner.CornerRadius = UDim.new(0, 5)
	upperCorner.Parent = upper

	local sole = Instance.new("Frame")
	sole.Name = "Sole"
	sole.Size = UDim2.fromOffset(22, 7)
	sole.Position = UDim2.fromOffset(0, 10)
	sole.BackgroundColor3 = SHOE
	sole.BorderSizePixel = 0
	sole.Parent = shoe
	local soleCorner = Instance.new("UICorner")
	soleCorner.CornerRadius = UDim.new(0, 3)
	soleCorner.Parent = sole

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3
	stroke.Color = INK
	stroke.Parent = label

	pool[i] = billboard
end

local function pop(amount: number)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not (head and head:IsA("BasePart")) then
		return
	end
	local billboard = pool[nextInPool]
	nextInPool += 1
	if nextInPool > POOL_SIZE then
		nextInPool = 1
	end

	local label = billboard:FindFirstChild("Label") :: TextLabel
	label.Text = string.format("+%d", math.max(1, math.floor(amount + 0.5)))
	label.TextTransparency = 0
	local stroke = label:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Transparency = 0
	end
	billboard.Adornee = head
	-- Sideways jitter by pool slot, so consecutive pops do not stack into one
	-- illegible column.
	billboard.StudsOffset = Vector3.new((nextInPool - 3) * 0.35, 1.6, 0)
	billboard.Enabled = true

	local rise = TweenService:Create(billboard, TweenInfo.new(1.1, Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out), { StudsOffset = billboard.StudsOffset + Vector3.new(0, 2.6, 0) })
	rise:Play()
	TweenService:Create(label, TweenInfo.new(1.1), { TextTransparency = 1 }):Play()
	if stroke then
		TweenService:Create(stroke, TweenInfo.new(1.1), { Transparency = 1 }):Play()
	end
	local shoe = billboard:FindFirstChild("Shoe")
	if shoe then
		for _, piece in ipairs(shoe:GetChildren()) do
			if piece:IsA("Frame") then
				piece.BackgroundTransparency = 0
				TweenService:Create(piece, TweenInfo.new(1.1),
					{ BackgroundTransparency = 1 }):Play()
			end
		end
	end
	task.delay(1.15, function()
		-- Only hide it if nothing else has claimed this slot since.
		if label.TextTransparency >= 1 then
			billboard.Enabled = false
		end
	end)
end

--==============================================================================
-- WATCHING THE SCORE
--==============================================================================
local lastSpeed: number? = nil

local function receive(profile: any)
	if type(profile) ~= "table" or type(profile.Speed) ~= "number" then
		return
	end
	local now = profile.Speed
	local before = lastSpeed
	lastSpeed = now
	-- The first packet is not a gain, it is finding out where you already were.
	if before and now > before + 0.05 then
		pop(now - before)
	end
end

local remotes = SeedGame:WaitForChild("Remotes", 20)
if remotes then
	local updated = remotes:WaitForChild(GameConfig.Remotes.ProfileUpdated, 20)
	if updated and updated:IsA("RemoteEvent") then
		updated.OnClientEvent:Connect(receive)
	else
		warn("[Seed] ProfileUpdated never arrived; the readout will stay blank.")
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

--==============================================================================
-- THE STREAK
--
-- One Trail, built once per character and re-enabled rather than rebuilt. Two
-- attachments on the root: a trail needs a pair and draws the ribbon between
-- them, so their separation is the ribbon's width.
--==============================================================================
local trail: Trail? = nil
local humanoid: Humanoid? = nil

local function fitCharacter(character: Model)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	humanoid = character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "SeedStreakA"
	a0.Position = Vector3.new(-0.9, 0.6, 0.4)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "SeedStreakB"
	a1.Position = Vector3.new(0.9, -0.9, 0.4)
	a1.Parent = root

	local t = Instance.new("Trail")
	t.Name = "SeedStreak"
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Lifetime = 0.32
	t.MinLength = 0.2
	t.LightEmission = 0.4
	t.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	t.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), ACCENT)
	t.Enabled = false
	t.Parent = root
	trail = t
end

if player.Character then
	task.spawn(fitCharacter, player.Character)
end
player.CharacterAdded:Connect(function(character)
	trail = nil
	task.spawn(fitCharacter, character)
end)

RunService.Heartbeat:Connect(function()
	local t, h = trail, humanoid
	if not (t and h and t.Parent) then
		return
	end
	-- Moving AND fast. Standing still at high WalkSpeed should not smear a
	-- ribbon across the plot.
	--
	-- MEASURED OFF VELOCITY, NOT MoveDirection. On the modern physics rig
	-- MoveDirection stayed 0.00 through a 39.2 stud walk, so a gate built on it
	-- never opened once -- the streak was dead for that reason as much as for
	-- the threshold being too high. Velocity is what "moving" actually means.
	local root = h.RootPart
	local v = if root then root.AssemblyLinearVelocity else Vector3.zero
	local ground = Vector3.new(v.X, 0, v.Z).Magnitude
	local want = h.WalkSpeed >= STREAK_AT and ground > 2
	if t.Enabled ~= want then
		t.Enabled = want
	end
	if want then
		-- A HINT at the gate, a real streak well past it. Without this the first
		-- session gets the same ribbon as somebody who has milled for an hour,
		-- and the streak stops meaning anything.
		local strength = math.clamp(
			(h.WalkSpeed - STREAK_AT) / (STREAK_FULL_AT - STREAK_AT), 0, 1)
		t.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.82 - 0.5 * strength),
			NumberSequenceKeypoint.new(1, 1),
		})
	end
end)

--==============================================================================
-- THE RUN CYCLE ON THE MILL
--
-- Occupancy pays without touching a key, which is correct and looks wrong: the
-- character stands on a moving belt like it is a box. So while the OnTreadmill
-- attribute is set, the run animation plays regardless of input.
--
-- The animation id is read off the character's own Animate script rather than
-- hardcoded, so a player with a purchased run animation trains in THEIR run,
-- and there is no asset id in this repo to rot.
--
-- Priority Action, so it beats the idle the default Animate script is playing.
--==============================================================================
local millTrack: AnimationTrack? = nil

local function stopMillRun()
	if millTrack then
		millTrack:Stop(0.2)
		millTrack = nil
	end
end

local function startMillRun()
	if millTrack then
		return
	end
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local animate = character and character:FindFirstChild("Animate")
	local run = animate and (animate:FindFirstChild("run") or animate:FindFirstChild("walk"))
	local source = run and run:FindFirstChildOfClass("Animation")
	if not (animator and source and source.AnimationId ~= "") then
		return
	end
	local clip = Instance.new("Animation")
	clip.AnimationId = source.AnimationId
	local ok, track = pcall(function()
		return (animator :: Animator):LoadAnimation(clip)
	end)
	if not ok or not track then
		return
	end
	track.Priority = Enum.AnimationPriority.Action
	track.Looped = true
	track:Play(0.2)
	millTrack = track
end

player:GetAttributeChangedSignal(GameConfig.Attributes.OnTreadmill):Connect(function()
	if player:GetAttribute(GameConfig.Attributes.OnTreadmill) then
		startMillRun()
	else
		stopMillRun()
	end
end)
player.CharacterAdded:Connect(function()
	-- The old track belonged to the old character's Animator.
	millTrack = nil
end)
