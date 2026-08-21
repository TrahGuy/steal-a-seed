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

-- Base walk speed is the floor everybody starts at; the streak is for being
-- meaningfully past it rather than for existing.
local STREAK_AT = GameConfig.walkSpeedFor(0) * 1.55

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
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = ACCENT
	label.Text = ""
	label.Parent = billboard

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
	local want = h.WalkSpeed >= STREAK_AT and h.MoveDirection.Magnitude > 0.1
	if t.Enabled ~= want then
		t.Enabled = want
	end
end)
