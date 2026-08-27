--!strict
--==============================================================================
-- Starbloom Guardian Live Studio Preview Runner
--
-- Automatically spawns and animates the high-detail Astralmaw guardian in
-- workspace so you can inspect and test it live without typing any commands.
--==============================================================================

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local SeedGameServer = ServerScriptService:WaitForChild("SeedGameServer")
local AstralmawModel = require(SeedGameServer:WaitForChild("AstralmawModel"))

-- Clean up any previous preview instance
local existing = workspace:FindFirstChild("Parent_starbloom_Preview")
if existing then
	existing:Destroy()
end

-- Spawn Position in front of Origin
local spawnCF = CFrame.new(0, 2, -28)
local H = 16

local model = AstralmawModel.Build(spawnCF, H, workspace)
model.Name = "Parent_starbloom_Preview"
model:SetAttribute("Asleep", false)

local root = model:WaitForChild("HumanoidRootPart") :: BasePart
local torso = model:WaitForChild("Torso") :: BasePart
local head = model:WaitForChild("Head") :: BasePart

local rootJoint = root:WaitForChild("RootJoint") :: Motor6D
local neck = torso:WaitForChild("Neck") :: Motor6D
local jaw = head:WaitForChild("JawJoint") :: Motor6D
local lShoulder = torso:WaitForChild("LeftShoulder") :: Motor6D
local rShoulder = torso:WaitForChild("RightShoulder") :: Motor6D
local lHip = torso:WaitForChild("LeftHip") :: Motor6D
local rHip = torso:WaitForChild("RightHip") :: Motor6D

local throat = head:FindFirstChild("MawThroat") :: BasePart?
local throatLight = throat and throat:FindFirstChildOfClass("PointLight")

local t0 = os.clock()

RunService.Heartbeat:Connect(function()
	if not model.Parent then return end

	local elapsed = os.clock() - t0
	local isAsleep = model:GetAttribute("Asleep") == true

	if isAsleep then
		-- Sleeping pose with rhythmic deep breathing
		local breath = math.sin(elapsed * 1.6) * 0.04
		rootJoint.C0 = root.CFrame:ToObjectSpace(spawnCF * CFrame.new(0, -H * 0.16 + breath * H, 0) * CFrame.Angles(math.rad(-65), math.rad(10), 0))
		neck.C0 = CFrame.new(0, H * 0.32, -H * 0.15) * CFrame.Angles(math.rad(-22 + math.sin(elapsed * 1.6) * 4), math.rad(-14), 0)
		jaw.C0 = CFrame.new(0, -H * 0.16, H * 0.08) * CFrame.Angles(math.rad(-4), 0, 0)
		lShoulder.C0 = CFrame.new(-H * 0.26, H * 0.10, -H * 0.04) * CFrame.Angles(math.rad(-45), math.rad(25), math.rad(-30))
		rShoulder.C0 = CFrame.new(H * 0.26, H * 0.10, -H * 0.04) * CFrame.Angles(math.rad(-55), math.rad(-20), math.rad(25))
		if throatLight then
			throatLight.Brightness = 1.4 + math.sin(elapsed * 1.6) * 0.6
		end
	else
		-- Active Predatory Prowl & Jaw Snapping
		local stride = math.sin(elapsed * 3.2)
		local headBob = math.cos(elapsed * 3.2) * math.rad(7)
		local jawSnap = math.max(0, math.sin(elapsed * 2.4)) * math.rad(26)

		rootJoint.C0 = root.CFrame:ToObjectSpace(spawnCF * CFrame.new(0, math.abs(stride) * 0.5, 0))
		neck.C0 = CFrame.new(0, H * 0.32, -H * 0.15) * CFrame.Angles(headBob, math.sin(elapsed * 1.2) * math.rad(10), 0)
		jaw.C0 = CFrame.new(0, -H * 0.16, H * 0.08) * CFrame.Angles(-jawSnap, 0, 0)
		lShoulder.C0 = CFrame.new(-H * 0.26, H * 0.10, -H * 0.04) * CFrame.Angles(stride * math.rad(26), 0, math.rad(-12))
		rShoulder.C0 = CFrame.new(H * 0.26, H * 0.10, -H * 0.04) * CFrame.Angles(-stride * math.rad(26), 0, math.rad(12))
		lHip.C0 = CFrame.new(-H * 0.16, -H * 0.18, H * 0.06) * CFrame.Angles(-stride * math.rad(18), 0, math.rad(-6))
		rHip.C0 = CFrame.new(H * 0.16, -H * 0.18, H * 0.06) * CFrame.Angles(stride * math.rad(18), 0, math.rad(6))
		if throatLight then
			throatLight.Brightness = 3.0 + math.sin(elapsed * 6.5) * 0.8
		end
	end
end)
