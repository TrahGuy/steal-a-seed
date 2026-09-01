--!strict
--==============================================================================
-- Steal a Seed :: StarbloomGuardianRunner
--
-- Spawns the high-detail Astralmaw guardian in Workspace and animates it live,
-- so its rig, its sleeping pose and its prowl can be inspected without a nest,
-- a thief, or a running game around it.
--==============================================================================

--==============================================================================
-- NOTHING CALLS THIS, AND THAT IS THE POINT
--
-- It was a Script, so it built a sixteen-stud guardian into Workspace on every
-- server start. A `RunService:IsStudio()` gate fixed the published half and
-- left the playtest half, because a Script cannot run in Edit AT ALL: Roblox
-- only executes scripts in Play/Run. "Studio only" and "not while I am playing"
-- are therefore the same gate, and it can only ever pick the wrong one.
--
-- Same answer MillMockupRunner already gives. As a module it is invoked
-- deliberately instead. Playtests never build it, and Edit finally can -- from
-- the command bar or MCP:
--
--   require(game.ServerScriptService.SeedGameServer.StarbloomGuardianRunner).Build()
--
-- Build() clears the previous preview first, so it is safe to run repeatedly
-- while iterating on the rig.
--==============================================================================

local StarbloomGuardianRunner = {}

local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local SeedGameServer = ServerScriptService:WaitForChild("SeedGameServer")
local AstralmawModel = require(SeedGameServer:WaitForChild("AstralmawModel"))

local MODEL_NAME = "Parent_starbloom_Preview"

-- In front of origin, clear of the road.
local SPAWN_CF = CFrame.new(0, 2, -28)
local H = 16

--==============================================================================
-- THE HEARTBEAT IS STATE, SO IT HAS TO BE CLEARABLE
--
-- The old Script connected one and could never disconnect it, because nothing
-- held the connection and nothing could ask it to stop. Rebuilding therefore
-- left the previous loop running against a destroyed model -- it survived only
-- on the `if not model.Parent then return end` guard at the top, which is a
-- leak wearing a seatbelt. Held here, Clear() actually ends it.
--==============================================================================
local animation: RBXScriptConnection? = nil

--==============================================================================
-- CLEAR
--==============================================================================
function StarbloomGuardianRunner.Clear()
	if animation then
		animation:Disconnect()
		animation = nil
	end
	local existing = workspace:FindFirstChild(MODEL_NAME)
	if existing then
		existing:Destroy()
	end
	print("[Seed/StarbloomGuardianRunner] Cleared " .. MODEL_NAME .. " from Workspace")
end

--==============================================================================
-- BUILD AND ANIMATE
--==============================================================================
function StarbloomGuardianRunner.Build(): Model
	-- Clearing first is what makes this re-runnable: build, look, edit the rig,
	-- build again, without two guardians standing in the same spot and two
	-- Heartbeats fighting over one set of Motor6Ds.
	StarbloomGuardianRunner.Clear()

	local model = AstralmawModel.Build(SPAWN_CF, H, workspace)
	model.Name = MODEL_NAME
	-- Flip this attribute in the Explorer to watch it wake up.
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

	animation = RunService.Heartbeat:Connect(function()
		if not model.Parent then
			StarbloomGuardianRunner.Clear()
			return
		end

		local elapsed = os.clock() - t0
		local isAsleep = model:GetAttribute("Asleep") == true

		if isAsleep then
			-- Sleeping pose with rhythmic deep breathing.
			local breath = math.sin(elapsed * 1.6) * 0.04
			rootJoint.C0 = root.CFrame:ToObjectSpace(SPAWN_CF * CFrame.new(0, -H * 0.16 + breath * H, 0) * CFrame.Angles(math.rad(-65), math.rad(10), 0))
			neck.C0 = CFrame.new(0, H * 0.32, -H * 0.15) * CFrame.Angles(math.rad(-22 + math.sin(elapsed * 1.6) * 4), math.rad(-14), 0)
			jaw.C0 = CFrame.new(0, -H * 0.16, H * 0.08) * CFrame.Angles(math.rad(-4), 0, 0)
			lShoulder.C0 = CFrame.new(-H * 0.26, H * 0.10, -H * 0.04) * CFrame.Angles(math.rad(-45), math.rad(25), math.rad(-30))
			rShoulder.C0 = CFrame.new(H * 0.26, H * 0.10, -H * 0.04) * CFrame.Angles(math.rad(-55), math.rad(-20), math.rad(25))
			if throatLight then
				throatLight.Brightness = 1.4 + math.sin(elapsed * 1.6) * 0.6
			end
		else
			-- Active predatory prowl and jaw snapping.
			local stride = math.sin(elapsed * 3.2)
			local headBob = math.cos(elapsed * 3.2) * math.rad(7)
			local jawSnap = math.max(0, math.sin(elapsed * 2.4)) * math.rad(26)

			rootJoint.C0 = root.CFrame:ToObjectSpace(SPAWN_CF * CFrame.new(0, math.abs(stride) * 0.5, 0))
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

	print("[Seed/StarbloomGuardianRunner] Built " .. MODEL_NAME .. " at " ..
		tostring(SPAWN_CF.Position))
	return model
end

return StarbloomGuardianRunner
