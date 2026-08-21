--!strict
-- Steal a Seed :: ParentAnim
--
-- Moves the nest parents' limbs. One Heartbeat over a tagged set, same shape as
-- Ambience -- and separate from it because the rigs have nothing in common and
-- a shared loop would be two animations in a trenchcoat.
--
--==============================================================================
-- THE SERVER WALKS IT. THIS DECIDES WHAT ITS LIMBS DO.
--
-- The parent chases, so its position has to be server-simulated or every player
-- sees the monster somewhere different. Its JOINTS are the opposite: nothing
-- about a swinging arm is authoritative, and animating per-client costs the
-- server nothing and replicates nothing.
--
-- The two never write the same property -- the server owns the root's position,
-- each client owns Motor6D.C0 -- which is why they cannot fight.
--
-- NOT Motor6D.Transform. That is the field Roblox's own animator uses and it is
-- consumed and reset by the animation step, so it does nothing outside a
-- running simulation and cannot be checked in Edit; any Animator the Humanoid
-- gains overwrites it every frame too. C0 composed against a rest pose captured
-- once is a plain property that stays where it is put. Marigold cost an
-- afternoon learning this.
--
--==============================================================================
-- IT WALKS WRONG ON PURPOSE
--
-- A clean gait would make it read as a big person. Everything here is
-- deliberately out of step with everything else:
--
--   * The legs are 140 degrees apart, not 180. That is a LIMP -- one leg is
--     always late, and the body never finds a rhythm.
--   * The two legs swing different AMOUNTS, so it favours a side.
--   * The arms run on their own offsets, close enough to look connected to the
--     walk and far enough off that they never quite match it.
--   * The head lolls on a slow clock unrelated to the stride, and rolls as well
--     as nods, so it is never quite facing where it is going.
--   * The jaw chomps on WALL-CLOCK time, tied to nothing at all. It is chewing
--     at the air while it runs at you.
--
-- Stride advances by DISTANCE COVERED, not by wall-clock. A clock-driven cycle
-- slides its feet when slow and sprints on the spot when stopped; distance
-- keeps a foot on the ground at any speed. The jaw is the deliberate exception,
-- because a jaw is not a foot.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local TAG = GameConfig.Tags.NestParent

type Joint = { motor: Motor6D, rest: CFrame }

type Parent = {
	model: Model,
	root: BasePart,
	neck: Joint?,
	jaw: Joint?,
	leftArm: Joint?,
	rightArm: Joint?,
	leftLeg: Joint?,
	rightLeg: Joint?,
	stride: number,
	-- 0 asleep, 1 awake. Blended so waking is a movement rather than a snap.
	wake: number,
	phase: number,
}

local parents: { [Model]: Parent } = {}

local function jointNamed(model: Model, name: string): Joint?
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and d.Name == name then
			return { motor = d, rest = d.C0 }
		end
	end
	return nil
end

--==============================================================================
-- TRACKING HAS TO WAIT FOR THE MODEL TO ARRIVE
--
-- The first version read model.PrimaryPart once and returned if it was nil.
-- That is a silent, permanent failure: a tagged model can replicate to the
-- client before its PrimaryPart or its Motor6Ds do, and GetInstanceAddedSignal
-- will never fire again because the tag was already there when we looked.
--
-- The symptom was a monster that simply never moved, with nothing in the output
-- and every joint sitting exactly at its rest pose -- which reads as "the
-- animation code is wrong" rather than "the animation code never ran".
--==============================================================================
local function track(model: Instance)
	if not model:IsA("Model") or parents[model] then
		return
	end
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		-- Not here yet. Wait for it off the signal thread and try again.
		task.spawn(function()
			local waited = model:WaitForChild("HumanoidRootPart", 10)
			if waited and waited:IsA("BasePart") and model.Parent then
				track(model)
			end
		end)
		return
	end
	-- Seeded off position so two parents in one biome never move in lockstep.
	local p = root.Position
	local neck = jointNamed(model, "Neck")
	if not neck then
		-- The rig is here but its joints are not. Same trap, same fix.
		task.spawn(function()
			task.wait(0.5)
			if model.Parent and not parents[model] then
				track(model)
			end
		end)
		return
	end

	parents[model] = {
		model = model,
		root = root,
		neck = neck,
		jaw = jointNamed(model, "JawJoint"),
		leftArm = jointNamed(model, "LeftShoulder"),
		rightArm = jointNamed(model, "RightShoulder"),
		leftLeg = jointNamed(model, "LeftHip"),
		rightLeg = jointNamed(model, "RightHip"),
		stride = 0,
		wake = 0,
		phase = (math.abs(p.X) + math.abs(p.Z)) % 6.28,
	}
end

for _, m in ipairs(CollectionService:GetTagged(TAG)) do
	track(m)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(m)
	parents[m :: Model] = nil
end)

--==============================================================================
-- THE NUMBERS
--==============================================================================
-- Radians of swing per stud walked. Tuned against WalkSpeed 19: a whole stride
-- every ~4 studs, which is about a step per leg length on a creature this size.
local SWING_PER_STUD = 0.40
-- The limp. 180 degrees is a walk; this is not 180 degrees.
local LEG_OFFSET = math.rad(140)
local LEG_SWING_L = math.rad(30)
local LEG_SWING_R = math.rad(21)
local ARM_SWING = math.rad(26)
local ARM_OFFSET_L = 0.7
local ARM_OFFSET_R = 3.9
local BLEND_RATE = 3.5

RunService.Heartbeat:Connect(function(dt)
	if next(parents) == nil then
		return
	end
	local t = os.clock()

	for model, p in pairs(parents) do
		if not p.root.Parent then
			parents[model] = nil
		else
			--== AWAKE OR NOT ==--
			-- The attribute is set by NestService and replicates, so the client
			-- knows without being told.
			local target = if model:GetAttribute("Asleep") == false then 1 else 0
			p.wake += (target - p.wake) * math.min(1, dt * BLEND_RATE)
			local wake = p.wake

			--== SPEED FROM VELOCITY, NOT MoveDirection ==--
			-- MoveDirection is intent and stays set while it is wedged against
			-- scenery, which would leave it running on the spot forever.
			local v = p.root.AssemblyLinearVelocity
			local speed = Vector3.new(v.X, 0, v.Z).Magnitude
			p.stride += speed * dt * SWING_PER_STUD

			local s = p.stride + p.phase
			local moving = math.clamp(speed / 6, 0, 1) * wake

			--== LEGS: out of phase by the wrong amount, and uneven ==--
			if p.leftLeg then
				p.leftLeg.motor.C0 = p.leftLeg.rest
					* CFrame.Angles(math.sin(s) * LEG_SWING_L * moving, 0, 0)
			end
			if p.rightLeg then
				p.rightLeg.motor.C0 = p.rightLeg.rest
					* CFrame.Angles(math.sin(s + LEG_OFFSET) * LEG_SWING_R * moving, 0, 0)
			end

			--== ARMS: near the beat, never on it ==--
			-- Asleep they hang a little forward, as if slumped.
			local slump = (1 - wake) * math.rad(9)
			if p.leftArm then
				p.leftArm.motor.C0 = p.leftArm.rest * CFrame.Angles(
					math.sin(s + ARM_OFFSET_L) * ARM_SWING * moving + slump, 0, 0)
			end
			if p.rightArm then
				p.rightArm.motor.C0 = p.rightArm.rest * CFrame.Angles(
					math.sin(s + ARM_OFFSET_R) * ARM_SWING * moving + slump, 0, 0)
			end

			--== HEAD: lolling on its own clock ==--
			-- Asleep it hangs forward and down. Awake it sways, on a slow cycle
			-- unrelated to the stride, so it is never facing where it is going.
			if p.neck then
				local droop = (1 - wake) * math.rad(26)
				local loll = wake * math.sin(t * 0.9 + p.phase) * math.rad(13)
				local nod = wake * math.sin(s * 0.5 + 1.1) * math.rad(7) * moving
				p.neck.motor.C0 = p.neck.rest
					* CFrame.Angles(droop + nod, loll * 0.7, loll)
			end

			--== JAW: chewing the air ==--
			-- Wall-clock, tied to nothing. Shut while it sleeps.
			if p.jaw then
				local chomp = (math.sin(t * 3.1 + p.phase) * 0.5 + 0.5) ^ 2
				-- Negative X opens it: the hinge is behind, so the front of the
				-- jaw drops. Positive would clamp it up through the skull.
				p.jaw.motor.C0 = p.jaw.rest
					* CFrame.Angles(-chomp * math.rad(19) * wake, 0, 0)
			end
		end
	end
end)
