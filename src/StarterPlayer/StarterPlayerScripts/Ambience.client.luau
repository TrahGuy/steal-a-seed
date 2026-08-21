--!strict
-- Steal a Seed :: Ambience
--
-- Everything in the world that moves for DECORATION moves here, on each
-- player's own machine.
--
--==============================================================================
-- ONE LOOP, OVER A TAG
--
-- The server builds a thing and tags it; this walks the tagged set once per
-- frame. Not one script per object, not one connection per object -- one
-- Heartbeat over a flat table.
--
-- Nothing here is authoritative and nothing here replicates. It composes each
-- joint's `C0` against a rest pose captured once, and a C0 written on a client
-- is local to that client. So the SERVER owns where Marigold is standing and
-- each CLIENT owns what her wings and limbs are doing, and the two never touch
-- the same property.
--
-- NOT `Motor6D.Transform`, which is the field Roblox's own animator uses and
-- was the obvious choice. Two problems: it is consumed and reset by the
-- animation step, so it does nothing at all outside a running simulation and
-- cannot be checked in Edit; and if the Humanoid ever gains an Animator, that
-- Animator overwrites it every frame and the wings silently stop. C0 is a plain
-- joint property that stays where it is put.
--
-- That split is the whole design: see FairyService for the server half.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local GameConfig = require(SeedGame:WaitForChild("Shared"):WaitForChild("GameConfig"))

local FAIRY_TAG = GameConfig.Tags.Fairy

-- Rest poses are captured ONCE and every frame composes against them. Reading a
-- joint's current C0 to derive the next one feeds each frame's rounding into the
-- next, which is how a limb slowly walks off the body.
type Joint = { motor: Motor6D, rest: CFrame, side: number }

type Fairy = {
	model: Model,
	root: BasePart,
	wings: { Joint },
	-- Named limbs, or nil if this rig is missing one. Nothing here assumes a
	-- complete R6: a rig with no left arm should walk with one arm, not throw
	-- sixty times a second.
	rightShoulder: Joint?,
	leftShoulder: Joint?,
	rightHip: Joint?,
	leftHip: Joint?,
	-- Per-fairy phase, so two of them in one place never move in lockstep.
	phase: number,
	-- How far through her stride she is. Advanced by DISTANCE COVERED rather
	-- than by wall-clock, which is what keeps a foot on the ground: a clock-
	-- driven cycle slides when she is slow and sprints on the spot when she
	-- stops.
	stride: number,
	-- HOW FAR THE WALK IS FADED IN, 0 to 1. It lived in a separate table keyed
	-- by Model, which leaked: the tag-removed handler cleared `fairies` and
	-- could not clear `blend`, because `blend` was declared twenty lines below
	-- it and would have been a nil global there. On the record there is only one
	-- table to forget to clean, and it is already cleaned.
	blend: number,
}

local fairies: { [Model]: Fairy } = {}

local function phaseFor(model: Model): number
	local h = 0
	for i = 1, #model.Name do
		h += string.byte(model.Name, i) * i
	end
	local root = model.PrimaryPart
	if root then
		h += math.floor(math.abs(root.Position.X) + math.abs(root.Position.Z))
	end
	return (h % 628) / 100
end

local function track(model: Instance)
	if not model:IsA("Model") then
		return
	end
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local torso = model:FindFirstChild("Torso")
	if not torso then
		return
	end

	local wings: { Joint } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part1 and d.Part1:GetAttribute("Side") then
			table.insert(wings, {
				motor = d, rest = d.C0, side = d.Part1:GetAttribute("Side") or 1,
			})
		end
	end

	local function joint(name: string): Joint?
		local m = torso:FindFirstChild(name)
		if m and m:IsA("Motor6D") then
			return { motor = m, rest = m.C0, side = 1 }
		end
		return nil
	end

	fairies[model] = {
		model = model,
		root = root,
		wings = wings,
		rightShoulder = joint("Right Shoulder"),
		leftShoulder = joint("Left Shoulder"),
		rightHip = joint("Right Hip"),
		leftHip = joint("Left Hip"),
		phase = phaseFor(model),
		stride = 0,
		blend = 0,
	}
end

for _, m in ipairs(CollectionService:GetTagged(FAIRY_TAG)) do
	track(m)
end
CollectionService:GetInstanceAddedSignal(FAIRY_TAG):Connect(track)
CollectionService:GetInstanceRemovedSignal(FAIRY_TAG):Connect(function(m)
	fairies[m] = nil
end)

--==============================================================================
-- THE LOOP
--
-- Wings flap constantly and fast. Limbs swing only while she is actually
-- moving, and settle back to rest when she stops -- a walk cycle that keeps
-- running on a stationary character is the single most obvious tell that an NPC
-- is faked.
--==============================================================================
local FLAP_RATE = 19
local FLAP_ANGLE = math.rad(32)
-- Radians of limb swing per stud walked. Tuned against WalkSpeed 5: a whole
-- stride every ~2.6 studs, which is roughly a step per leg length.
local SWING_PER_STUD = 0.62
local SWING_ANGLE = math.rad(26)
local ARM_SHARE = 0.7
-- How fast the swing fades in and out. Without it, arms snap to rest the frame
-- she stops.
local BLEND_RATE = 6

RunService.Heartbeat:Connect(function(dt)
	if next(fairies) == nil then
		return
	end
	local t = os.clock()

	for model, f in pairs(fairies) do
		if not f.root.Parent then
			-- Despawned without the removed signal firing, so the table cannot
			-- grow without bound.
			fairies[model] = nil
		else
			--== WINGS ==--
			local flap = math.sin(t * FLAP_RATE + f.phase) * FLAP_ANGLE
			for _, w in ipairs(f.wings) do
				-- About local Z, also measured: X does nothing at all on a wing
				-- (it spins the panel about its own long axis) and Y sweeps it
				-- flat sideways. Z is the one that beats up and down.
				--
				-- Composed AFTER the rest pose, so the beat happens about the
				-- wing's own hinge rather than about the torso -- the sweep the
				-- rest pose carries stays intact.
				w.motor.C0 = w.rest * CFrame.Angles(0, 0, flap * w.side)
			end

			--== WALK ==--
			-- Speed from the ROOT'S VELOCITY, not from Humanoid.MoveDirection:
			-- MoveDirection is intent and stays set while she is wedged against
			-- something, which would leave her walking on the spot.
			local speed = Vector3.new(
				f.root.AssemblyLinearVelocity.X, 0,
				f.root.AssemblyLinearVelocity.Z).Magnitude

			f.stride += speed * dt * SWING_PER_STUD
			local target = speed > 0.4 and 1 or 0
			f.blend += (target - f.blend) * math.min(1, dt * BLEND_RATE)

			local swing = math.sin(f.stride) * SWING_ANGLE * f.blend
			-- ABOUT LOCAL Z, AND THAT WAS MEASURED RATHER THAN GUESSED. R6 bakes
			-- a 90-degree yaw into every shoulder and hip C0, so the joint's axes
			-- are not the torso's and the obvious X is wrong: rotating a shoulder
			-- about X slides the arm SIDEWAYS (dX -0.50, dZ 0.00), while Z swings
			-- it forward and back (dZ -0.35). The first version used X and she
			-- walked doing star jumps.
			local function pose(j: Joint?, amount: number)
				if j then
					j.motor.C0 = j.rest * CFrame.Angles(0, 0, amount)
				end
			end
			-- BOTH SIDES TAKE THE SAME SIGN, which looks wrong and is right.
			-- R6 mirrors its left joints with a -90 degree yaw in C0 against the
			-- right's +90, so the two sides' local Z axes ALREADY point opposite
			-- ways in the world. Passing opposite signs cancels that mirroring
			-- out and both legs swing forward together -- measured, and it walked
			-- doing star jumps.
			pose(f.rightHip, swing)
			pose(f.leftHip, swing)
			-- Arms counter the legs, which is what walking is.
			pose(f.rightShoulder, -swing * ARM_SHARE)
			pose(f.leftShoulder, -swing * ARM_SHARE)
		end
	end
end)
