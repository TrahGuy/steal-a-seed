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
local TanglemireForms = require(SeedGame.Shared:WaitForChild("TanglemireForms"))

local TAG = GameConfig.Tags.NestParent

type Joint = { motor: Motor6D, rest: CFrame }

-- Declared here because the Parent type below carries one. The VALUES live down
-- with the other numbers, where they can be read next to the swing amplitudes.
type SleepProfile = {
	armFold: number,
	armSplay: number,
	neckDroop: number,
	neckTilt: number,
	hipTurn: number,
	breath: number,
	breathRate: number,
}

type Parent = {
	model: Model,
	root: BasePart,
	neck: Joint?,
	jaw: Joint?,
	leftArm: Joint?,
	rightArm: Joint?,
	leftLeg: Joint?,
	rightLeg: Joint?,
	-- The seventh seam. Its socket is the model ORIGIN, so driving it moves the
	-- whole creature about the point it stands on -- which is how the approved
	-- sleep pose was authored and why it drops in unchanged.
	rootJoint: Joint?,
	-- Where the body sits when fully asleep, already scaled by the builder that
	-- knows the creature's size. Identity for anything that does not set it,
	-- which is what keeps Greenhollow's brute exactly as it was.
	sleepBody: CFrame,
	stride: number,
	lastPos: Vector3,
	-- 0 asleep, 1 awake. Blended so waking is a movement rather than a snap.
	wake: number,
	phase: number,
	sleep: SleepProfile,
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
--==============================================================================
-- DECLARED HERE, NOT DOWN WITH THE OTHER NUMBERS, AND THAT IS LOAD-BEARING
--
-- `track` reads SLEEP_BY_SPECIES, and track runs at the bottom of this file
-- against every already-tagged parent. Left in THE NUMBERS section below,
-- these locals were still nil at that moment: track threw on the first
-- parent, NO parent was ever registered, and the Heartbeat loop early-outed
-- on an empty table. Both creatures stood frozen -- no sleep pose, no
-- breath, no walk cycle -- and nothing about it looked like an ordering
-- mistake from the outside.
--==============================================================================
--==============================================================================
-- SLEEP IS A POSE *AND* A MOVEMENT, AND IT ONLY HAD THE POSE
--
-- Asleep, every term in the loop below is multiplied by `wake`, so at wake = 0
-- the only things left were two constants: a 9-degree arm slump and a
-- 26-degree neck droop. Correct as far as it went, and completely still. A
-- sleeping creature that does not breathe is a statue lying down, which is the
-- same critique the plants got.
--
-- PER SPECIES, because ParentAnim drives every parent on the road and the two
-- are not the same animal. Greenhollow's brute keeps EXACTLY the numbers it
-- shipped with -- its profile is the old constants and a breath of zero -- so
-- nothing about an approved creature changes because a second one arrived.
--
-- Brambleback's numbers are lifted from its approved preview's `sleepExtras`:
-- arms folded right up across the chest, neck down and forward, hips turned
-- out, jaw shut. The preview also pitched the whole BODY back 68 degrees to lie
-- it down; that is not reachable from here and is noted at the call site.
--==============================================================================
local GREENHOLLOW_SLEEP: SleepProfile = {
	armFold = math.rad(9),
	armSplay = 0,
	neckDroop = math.rad(26),
	neckTilt = 0,
	hipTurn = 0,
	breath = 0,
	breathRate = 0,
}

local BRAMBLEBACK_SLEEP: SleepProfile = {
	-- 123 and 128 degrees in the preview. Folded that far the forearms cross
	-- the chest, which is what makes it read as CURLED rather than as standing
	-- with its arms down.
	armFold = math.rad(125),
	armSplay = math.rad(18),
	neckDroop = math.rad(29),
	neckTilt = math.rad(-3),
	hipTurn = math.rad(10),
	breath = math.rad(2.6),
	breathRate = 1.1,
}

local FORGEMAW_SLEEP: SleepProfile = {
	armFold = math.rad(16),
	armSplay = math.rad(-6),
	neckDroop = math.rad(24),
	neckTilt = math.rad(-3),
	hipTurn = math.rad(14),
	breath = math.rad(3.6),
	breathRate = 0.82,
}

local SLEEP_BY_SPECIES: { [string]: SleepProfile } = {
	brambleback = BRAMBLEBACK_SLEEP,
	forgemaw = FORGEMAW_SLEEP,
}

--==============================================================================
-- MIREMAW: THE APPROVED PERFORMANCE, NOT AN IMPRESSION OF IT
--
-- Greenhollow's brute and Brambleback both sleep by ANGLES -- fold the arms
-- this many degrees, droop the neck that many -- which works because their
-- sleeping poses were described that way. Miremaw's was not described, it was
-- DEMONSTRATED: an eighteen-second loop in Edit that nobody wrote down.
--
-- So it was measured instead. Both endpoints were captured keyed to the
-- mockup's own PreviewState attribute, and TanglemireForms carries the result
-- as one delta per seam plus the property channels. Everything below drives
-- those from the same wake scalar the other two parents use, so the whole body
-- arrives together and every value in between is a real interpolation.
--
-- THREE OF THE CHANNELS ARE NOT JOINTS, and a joint-only animator would drop
-- them silently: the throat SHRINKS, the throat light DIMS, and the eyes close
-- by transparency with the lids recolouring. They are lerped here beside the
-- seams rather than snapped at either end.
--
-- Miremaw takes this path INSTEAD OF the shared limb code, not on top of it.
-- Two writers on one Motor6D.C0 is the bug that would look like jitter and
-- read as a physics problem.
--==============================================================================
type MireChannels = {
	seams: { { motor: Motor6D, rest: CFrame, delta: CFrame } },
	sizes: { { part: BasePart, awake: Vector3, asleep: Vector3 } },
	fades: { { part: BasePart, awake: number, asleep: number } },
	tints: { { part: BasePart, awake: Color3, asleep: Color3 } },
	light: { light: PointLight, awake: number, asleep: number }?,
	fronds: { { motor: Motor6D, rest: CFrame, delta: CFrame } },
	byName: { [string]: { motor: Motor6D, rest: CFrame, delta: CFrame } },
	throat: { part: BasePart, awake: Vector3 }?,
	eyes: { BasePart },
}

local function mireChannels(model: Model, scale: number): MireChannels?
	local byName: { [string]: BasePart } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			byName[d.Name] = d
		end
	end

	local ch: MireChannels = {
		seams = {}, sizes = {}, fades = {}, tints = {},
		light = nil, fronds = {}, throat = nil, eyes = {}, byName = {},
	}

	-- Translations were authored at the mockup's scale; angles must not be
	-- touched. Same rule the builder follows.
	local function scaledDelta(c: CFrame): CFrame
		local p = c.Position
		return CFrame.new(p.X * scale, p.Y * scale, p.Z * scale) * (c - p)
	end

	for _, seam in ipairs(TanglemireForms.MiremawSeams) do
		local delta = TanglemireForms.MiremawSleep[seam.seam]
		local motor: Motor6D? = nil
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("Motor6D") and d.Name == seam.seam then
				motor = d
				break
			end
		end
		if motor and delta then
			local row = { motor = motor, rest = motor.C0, delta = scaledDelta(delta) }
			table.insert(ch.seams, row)
			ch.byName[seam.seam] = row
			if string.sub(seam.seam, 1, 5) == "Frond" then
				table.insert(ch.fronds, row)
			end
		end
	end

	for name, asleepSize in pairs(TanglemireForms.MiremawSleepSize) do
		local p = byName[name]
		if p then
			table.insert(ch.sizes,
				{ part = p, awake = p.Size, asleep = asleepSize * scale })
			if name == "ThroatSac" then
				ch.throat = { part = p, awake = p.Size }
			end
		end
	end
	for name, asleepT in pairs(TanglemireForms.MiremawSleepTransparency) do
		local p = byName[name]
		if p then
			table.insert(ch.fades, { part = p, awake = p.Transparency, asleep = asleepT })
			table.insert(ch.eyes, p)
		end
	end
	for name, asleepC in pairs(TanglemireForms.MiremawSleepColor) do
		local p = byName[name]
		if p then
			table.insert(ch.tints, { part = p, awake = p.Color, asleep = asleepC })
		end
	end

	--==========================================================================
	-- THE THROAT LIGHT IS BUILT HERE, NOT BY THE RIG
	--
	-- It is pure decoration and the server has no use for it, so the client owns
	-- it outright -- one PointLight per Miremaw, created once at track time
	-- rather than replicated to everybody.
	--==========================================================================
	local spec = TanglemireForms.MiremawThroatLight
	local host = byName[spec.Part]
	if host then
		local existing = host:FindFirstChildOfClass("PointLight")
		local light = existing or Instance.new("PointLight")
		light.Name = "MireDetail_ThroatLight"
		light.Color = spec.Color
		light.Range = spec.Range * scale
		light.Shadows = false
		light.Parent = host
		ch.light = { light = light, awake = spec.Awake, asleep = spec.Asleep }
	end

	if #ch.seams == 0 then
		return nil
	end
	return ch
end

--==============================================================================
-- Awake it keeps breathing, blinking, working its throat and stirring its
-- fronds. All of it rides on `wake`, so a sleeping Miremaw is still and a
-- waking one picks these up as it rises rather than switching them on.
--==============================================================================
local MIRE_BLINK_EVERY = 4.3
local MIRE_BLINK_FOR = 0.13
local MIRE_THROAT_RATE = 1.35
local MIRE_THROAT_DEPTH = 0.035
local MIRE_FROND_RATE = 0.7
local MIRE_FROND_SWAY = math.rad(2.4)
-- Shallower than Brambleback's. Miremaw is the taller creature and a big
-- mass swinging a big angle reads as flailing rather than as weight.
local MIRE_LEG_SWING = math.rad(21)
local MIRE_ARM_SWING = math.rad(11)

local function animateMiremaw(p: any, wake: number, t: number,
	stride: number, moving: number)
	local ch = p.mire :: MireChannels
	local asleep = 1 - wake

	--== EVERY SEAM, FROM ONE SCALAR ==--
	for _, row in ipairs(ch.seams) do
		row.motor.C0 = row.rest * row.delta:Lerp(CFrame.identity, wake)
	end

	--== THE WALK ==--
	-- Distance travelled, not the clock: a clock-driven leg slides, and this
	-- creature does its most important work at a run. `moving` already carries
	-- the wake scalar, so a sleeping Miremaw's legs are still.
	local function swing(row, phase: number, amp: number)
		if row then
			row.motor.C0 = row.motor.C0
				* CFrame.Angles(math.sin(stride + phase) * amp * moving, 0, 0)
		end
	end
	swing(ch.byName.LeftHip, 0, MIRE_LEG_SWING)
	swing(ch.byName.RightHip, math.pi, MIRE_LEG_SWING)
	-- Arms counter the legs, and by less: it runs with them braced, not pumping.
	swing(ch.byName.RightShoulder, 0, MIRE_ARM_SWING)
	swing(ch.byName.LeftShoulder, math.pi, MIRE_ARM_SWING)

	--== THE FRONDS LAG ==--
	-- Each one on its own phase offset, so four fronds stirring never reads as
	-- one plank with three copies.
	for i, row in ipairs(ch.fronds) do
		local lag = p.phase + i * 1.31
		row.motor.C0 = row.motor.C0
			* CFrame.Angles(math.sin(t * MIRE_FROND_RATE + lag) * MIRE_FROND_SWAY * wake, 0, 0)
	end

	--== THE THROAT: SIZE FIRST, THEN A WAKING PULSE ON TOP ==--
	for _, row in ipairs(ch.sizes) do
		row.part.Size = row.asleep:Lerp(row.awake, wake)
	end
	if ch.throat then
		local pulse = 1 + math.sin(t * MIRE_THROAT_RATE + p.phase) * MIRE_THROAT_DEPTH * wake
		ch.throat.part.Size = ch.throat.part.Size * pulse
	end

	--== THE EYES ==--
	-- Shut asleep, and awake they blink: brief, and off a phase seeded from the
	-- nest so two Miremaws never blink together.
	local blink = 0
	if wake > 0.5 then
		local cycle = (t + p.phase) % MIRE_BLINK_EVERY
		if cycle < MIRE_BLINK_FOR then
			blink = math.sin(cycle / MIRE_BLINK_FOR * math.pi)
		end
	end
	for _, row in ipairs(ch.fades) do
		local open = row.asleep + (row.awake - row.asleep) * wake
		row.part.Transparency = math.clamp(open + (row.asleep - row.awake) * blink, 0, 1)
	end
	for _, row in ipairs(ch.tints) do
		row.part.Color = row.asleep:Lerp(row.awake, wake)
	end

	--== THE THROAT LIGHT ==--
	if ch.light then
		local lit = ch.light.asleep + (ch.light.awake - ch.light.asleep) * wake
		-- The same slow pulse the sac swells on, so light and mass agree.
		ch.light.light.Brightness = lit
			* (1 + math.sin(t * MIRE_THROAT_RATE + p.phase) * 0.10 * wake)
	end

	--== BREATHING, WHICH NEVER STOPS ==--
	-- Deeper and slower asleep, shallow and quicker awake: a big mass moving a
	-- little, which is what says heavy.
	if p.neck then
		local rate = 0.85 + 0.55 * wake
		local depth = math.rad(1.9) * (0.45 + 0.55 * asleep)
		p.neck.motor.C0 = p.neck.motor.C0
			* CFrame.Angles(math.sin(t * rate + p.phase) * depth, 0, 0)
	end
end

--==============================================================================
-- FORGEMAW: VOLCANIC KNUCKLE-WALKER KINEMATICS
--
-- A heavy 4-legged beast with long pillar forelimbs and folded hind legs.
-- Knuckle stride uses diagonal pairing (Left Arm + Right Leg vs Right Arm + Left Leg),
-- with dynamic torso spine flexion/bobbing, lunging neck thrust, and wide snapping jaws.
--==============================================================================
local FORGE_ARM_SWING = math.rad(42)
local FORGE_ARM_LIFT = math.rad(15)
local FORGE_LEG_SWING = math.rad(46)
local FORGE_TORSO_BOB = 0.65
local FORGE_TORSO_PITCH = math.rad(8.5)
local FORGE_TORSO_ROLL = math.rad(6.0)
local FORGE_TORSO_YAW = math.rad(5.0)

local function animateForgemaw(p: any, wake: number, t: number,
	stride: number, moving: number, attackDt: number)
	local asleep = 1 - wake
	local sleep = p.sleep

	--== VOLCANIC BREATHING & IDLE WEIGHT TRANSFER ==--
	local breath = 0
	if sleep.breath > 0 then
		breath = math.sin(t * sleep.breathRate + p.phase) * sleep.breath * asleep
	end
	local idleWeight = (1 - moving * 0.7) * wake
	local idleArmRoll = math.sin(t * 1.8 + p.phase) * math.rad(4.0) * idleWeight
	local idleArmPitch = math.cos(t * 1.8 + p.phase) * math.rad(3.5) * idleWeight
	local idleLegPitch = math.sin(t * 1.8 + p.phase) * math.rad(3.0) * idleWeight
	local idleTorsoSway = math.sin(t * 1.3 + p.phase) * math.rad(2.5) * idleWeight

	--== ATTACK SWIPE / KNUCKLE SLAM ==--
	local attackArmPitch = 0
	local attackArmYaw = 0
	local attackArmRoll = 0
	local attackJaw = 0
	local attackHead = 0

	if attackDt >= 0 and attackDt < 0.85 then
		local pNorm = attackDt / 0.85
		if pNorm < 0.28 then
			-- Phase 1: High Knuckle Windup (rear back and lift heavy arms)
			local u = pNorm / 0.28
			local ease = math.sin(u * math.pi * 0.5)
			attackArmPitch = -math.rad(65) * ease
			attackArmRoll = math.rad(24) * ease
			attackHead = -math.rad(16) * ease
			attackJaw = math.rad(16) * ease
		elseif pNorm < 0.60 then
			-- Phase 2: Explosive Knuckle Slam & Furnace Lunge
			local u = (pNorm - 0.28) / 0.32
			local ease = math.sin(u * math.pi * 0.5)
			attackArmPitch = -math.rad(65) + math.rad(140) * ease
			attackArmYaw = math.rad(28) * ease
			attackArmRoll = math.rad(24) - math.rad(36) * ease
			attackHead = -math.rad(16) + math.rad(30) * ease
			attackJaw = math.rad(16) + math.rad(36) * ease
		else
			-- Phase 3: Recovery / Re-plant
			local u = (pNorm - 0.60) / 0.25
			local ease = 1 - u
			attackArmPitch = math.rad(75) * ease
			attackArmYaw = math.rad(28) * ease
			attackArmRoll = -math.rad(12) * ease
			attackHead = math.rad(14) * ease
			attackJaw = math.rad(52) * ease
		end
	end

	--== 1. TORSO & SPINE HEAVE (RootJoint) ==--
	-- Knuckle-walking gallop/prowl causes the heavy body to pitch, bob, and roll
	if p.rootJoint then
		local bob = -math.abs(math.sin(stride)) * FORGE_TORSO_BOB * moving
		local pitch = (math.sin(stride * 2) * FORGE_TORSO_PITCH * moving) + idleTorsoSway
		local roll = (math.sin(stride) * FORGE_TORSO_ROLL * moving) + (idleTorsoSway * 0.5)
		local yaw = -math.sin(stride) * FORGE_TORSO_YAW * moving
		local sleepOffset = p.sleepBody:Lerp(CFrame.identity, wake)
		p.rootJoint.motor.C0 = p.rootJoint.rest
			* sleepOffset
			* CFrame.new(0, bob, 0)
			* CFrame.Angles(pitch, yaw, roll)
	end

	--== 2. FORELIMBS / KNUCKLE ARMS ==--
	-- Diagonal stride: Left Arm alternates with Right Arm
	local armL_sin = math.sin(stride)
	local armR_sin = math.sin(stride + math.pi)
	local liftL = math.max(0, math.cos(stride)) * FORGE_ARM_LIFT * moving
	local liftR = math.max(0, -math.cos(stride)) * FORGE_ARM_LIFT * moving
	local fold = asleep * sleep.armFold
	local splay = asleep * sleep.armSplay

	if p.leftArm then
		p.leftArm.motor.C0 = p.leftArm.rest * CFrame.Angles(
			armL_sin * FORGE_ARM_SWING * moving - liftL + fold + breath + idleArmPitch + attackArmPitch,
			math.sin(stride) * math.rad(8) * moving + attackArmYaw,
			splay + idleArmRoll + attackArmRoll)
	end
	if p.rightArm then
		p.rightArm.motor.C0 = p.rightArm.rest * CFrame.Angles(
			armR_sin * FORGE_ARM_SWING * moving - liftR + fold + breath - idleArmPitch + attackArmPitch,
			-math.sin(stride) * math.rad(8) * moving - attackArmYaw,
			-splay - idleArmRoll - attackArmRoll)
	end

	--== 3. HIND LEGS ==--
	-- Diagonal pairing: Left Leg pairs with Right Arm (phase pi), Right Leg pairs with Left Arm (phase 0)
	local legL_sin = math.sin(stride + math.pi)
	local legR_sin = math.sin(stride)
	local hipTurn = asleep * sleep.hipTurn

	if p.leftLeg then
		p.leftLeg.motor.C0 = p.leftLeg.rest
			* CFrame.Angles(legL_sin * FORGE_LEG_SWING * moving + idleLegPitch, -hipTurn * 0.7, -hipTurn)
	end
	if p.rightLeg then
		p.rightLeg.motor.C0 = p.rightLeg.rest
			* CFrame.Angles(legR_sin * FORGE_LEG_SWING * moving - idleLegPitch, hipTurn * 0.7, hipTurn)
	end

	--== 4. NECK & HEAD ==--
	-- Lunging thrust with stride + predatory yaw tracking
	if p.neck then
		local droop = asleep * sleep.neckDroop
		local loll = wake * math.sin(t * 1.5 + p.phase) * math.rad(12)
		local nod = wake * math.sin(stride * 2 + 1.2) * math.rad(10.0) * moving
		p.neck.motor.C0 = p.neck.rest
			* CFrame.Angles(droop + nod - breath * 0.5 + attackHead,
				loll * 0.8, loll * 0.5 + asleep * sleep.neckTilt)
	end

	--== 5. SNAPPING UNDERSLUNG JAW ==--
	-- Active furnace chomp while pursuing
	if p.jaw then
		local chomp = (math.sin(t * 3.4 + p.phase) * 0.5 + 0.5) ^ 1.6
		p.jaw.motor.C0 = p.jaw.rest
			* CFrame.Angles(-chomp * math.rad(30) * wake - attackJaw, 0, 0)
	end
end

local function track(model: Instance)
	if not model:IsA("Model") or parents[model] then
		return
	end

	local function tryTrack(): boolean
		if parents[model] or not model.Parent then
			return true
		end
		local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if not (root and root:IsA("BasePart")) then
			return false
		end
		local neck = jointNamed(model, "Neck")
		if not neck then
			return false
		end

		local p = root.Position
		parents[model] = {
			model = model,
			root = root,
			neck = neck,
			jaw = jointNamed(model, "JawJoint"),
			leftArm = jointNamed(model, "LeftShoulder"),
			rightArm = jointNamed(model, "RightShoulder"),
			leftLeg = jointNamed(model, "LeftHip"),
			rightLeg = jointNamed(model, "RightHip"),
			rootJoint = jointNamed(model, "RootJoint"),
			sleepBody = (model:GetAttribute("SleepBodyPose") :: CFrame?) or CFrame.identity,
			stride = 0,
			lastPos = root.Position,
			wake = 0,
			phase = (math.abs(p.X) + math.abs(p.Z)) % 6.28,
			-- Read once at track time, not per frame. The attribute is set by the
			-- builder and never changes for the life of the rig.
			sleep = SLEEP_BY_SPECIES[tostring(model:GetAttribute("Species"))]
				or GREENHOLLOW_SLEEP,
			-- Populated only for Miremaw. Nil for every other guardian, which
			-- is what keeps this whole path off Greenhollow and Brambleback.
			mire = if tostring(model:GetAttribute("Species")) == "miremaw"
				then mireChannels(model, (model:GetAttribute("RigScale") :: number?) or 1)
				else nil,
		}
		return true
	end

	if not tryTrack() then
		local conn: RBXScriptConnection? = nil
		conn = model.DescendantAdded:Connect(function()
			if tryTrack() and conn then
				conn:Disconnect()
				conn = nil
			end
		end)
	end
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

			--==============================================================
			-- MIREMAW TAKES ITS OWN PATH, AND TAKES IT INSTEAD
			--
			-- Its sleeping pose is measured per seam rather than described in
			-- angles, so running the shared limb code as well would put two
			-- writers on one Motor6D.C0 -- which shows up as jitter and reads
			-- as a physics problem rather than as an animation one.
			--==============================================================
			--== SPEED FROM DELTA-POSITION & VELOCITY ==--
			-- Server-moved Humanoids replicate position via CFrame interpolation,
			-- so AssemblyLinearVelocity is often 0 on the client. Deriving speed from
			-- actual displacement between frames guarantees the walk cycle runs.
			local curPos = p.root.Position
			local dp = curPos - p.lastPos
			local flatDist = Vector3.new(dp.X, 0, dp.Z).Magnitude
			local posSpeed = if dt > 0.0001 then flatDist / dt else 0
			p.lastPos = curPos

			local fv = p.root.AssemblyLinearVelocity
			local physSpeed = Vector3.new(fv.X, 0, fv.Z).Magnitude
			local speed = math.max(physSpeed, posSpeed)

			local attackTime = (model:GetAttribute("AttackSwipe") :: number?) or 0
			local attackDt = t - attackTime

			if p.mire then
				p.stride += speed * dt * SWING_PER_STUD
				animateMiremaw(p, wake, t, p.stride + p.phase,
					math.clamp(speed / 6, 0, 1) * wake)
				continue
			end

			if tostring(model:GetAttribute("Species")) == "forgemaw" then
				p.stride += speed * dt * SWING_PER_STUD
				animateForgemaw(p, wake, t, p.stride + p.phase,
					math.clamp(speed / 6, 0, 1) * wake, attackDt)
				continue
			end

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

			--==============================================================
			-- THE BODY GOES DOWN FIRST
			--
			-- Driven before the limbs because everything else is measured
			-- against a torso this moves. Lerped on the SAME wake scalar the
			-- limbs use, so lying down and getting up are one continuous
			-- movement rather than a pose that snaps at either end -- and any
			-- value in between has to look right, not just the two ends.
			--
			-- A creature with no SleepBodyPose has sleepBody = identity, so
			-- this lerps identity to identity and costs one CFrame a frame.
			--==============================================================
			if p.rootJoint then
				p.rootJoint.motor.C0 = p.rootJoint.rest
					* p.sleepBody:Lerp(CFrame.identity, wake)
			end

			--==============================================================
			-- THE BREATH
			--
			-- Rides on (1 - wake), so it is at full depth asleep and gone the
			-- moment the thing is up -- awake it has a walk cycle and a lolling
			-- head to carry it, and a breath on top of those is noise.
			--
			-- Its own slow clock, unrelated to stride and offset per parent by
			-- `phase`, so two sleeping in one biome are never in time with each
			-- other. Greenhollow's profile sets breath = 0, so the brute is
			-- exactly as still as it has always been.
			--==============================================================
			local sleep = p.sleep
			local asleep = 1 - wake
			local breath = 0
			if sleep.breath > 0 then
				breath = math.sin(t * sleep.breathRate + p.phase) * sleep.breath * asleep
			end

			--== ATTACK SWIPE / CATCH ANIMATION ==--
			local attackTime = (model:GetAttribute("AttackSwipe") :: number?) or 0
			local attackDt = t - attackTime
			local attackArmPitch = 0
			local attackArmYaw = 0
			local attackArmRoll = 0
			local attackJaw = 0
			local attackHead = 0

			if attackDt >= 0 and attackDt < 0.85 then
				local pNorm = attackDt / 0.85
				if pNorm < 0.28 then
					-- Phase 1: High Windup (pull arms back & up, head rears back)
					local u = pNorm / 0.28
					local ease = math.sin(u * math.pi * 0.5)
					attackArmPitch = -math.rad(75) * ease
					attackArmRoll = math.rad(30) * ease
					attackHead = -math.rad(18) * ease
					attackJaw = math.rad(12) * ease
				elseif pNorm < 0.60 then
					-- Phase 2: Explosive Forward Claw Slash & Snap (violently swing arms forward)
					local u = (pNorm - 0.28) / 0.32
					local ease = math.sin(u * math.pi * 0.5)
					attackArmPitch = -math.rad(75) + math.rad(165) * ease
					attackArmYaw = math.rad(35) * ease
					attackArmRoll = math.rad(30) - math.rad(45) * ease
					attackHead = -math.rad(18) + math.rad(32) * ease
					attackJaw = math.rad(12) + math.rad(32) * ease
				else
					-- Phase 3: Recovery / Follow-through blend back
					local u = (pNorm - 0.60) / 0.25
					local ease = 1 - u
					attackArmPitch = math.rad(90) * ease
					attackArmYaw = math.rad(35) * ease
					attackArmRoll = -math.rad(15) * ease
					attackHead = math.rad(14) * ease
					attackJaw = math.rad(44) * ease
				end
			end

			--== ARMS: near the beat, never on it + attack swipe ==--
			-- Asleep they fold, by however much this species folds them.
			local fold = asleep * sleep.armFold
			local splay = asleep * sleep.armSplay
			if p.leftArm then
				p.leftArm.motor.C0 = p.leftArm.rest * CFrame.Angles(
					math.sin(s + ARM_OFFSET_L) * ARM_SWING * moving + fold + breath + attackArmPitch,
					attackArmYaw, splay + attackArmRoll)
			end
			if p.rightArm then
				p.rightArm.motor.C0 = p.rightArm.rest * CFrame.Angles(
					math.sin(s + ARM_OFFSET_R) * ARM_SWING * moving + fold + breath + attackArmPitch,
					-attackArmYaw, -splay - attackArmRoll)
			end

			--== HIPS SETTLE OUTWARD AS IT SLEEPS ==--
			-- Only if the species asks for it; the legs are otherwise driven
			-- entirely by the stride above, which is zero while asleep.
			if sleep.hipTurn > 0 then
				local turn = asleep * sleep.hipTurn
				if p.leftLeg then
					p.leftLeg.motor.C0 = p.leftLeg.motor.C0 * CFrame.Angles(0, -turn, -turn * 0.7)
				end
				if p.rightLeg then
					p.rightLeg.motor.C0 = p.rightLeg.motor.C0 * CFrame.Angles(0, turn, turn * 0.7)
				end
			end

			--== HEAD: lolling on its own clock + attack thrust ==--
			-- Asleep it hangs forward and down. Awake it sways, on a slow cycle
			-- unrelated to the stride, so it is never facing where it is going.
			if p.neck then
				local droop = asleep * sleep.neckDroop
				local loll = wake * math.sin(t * 0.9 + p.phase) * math.rad(13)
				local nod = wake * math.sin(s * 0.5 + 1.1) * math.rad(7) * moving
				p.neck.motor.C0 = p.neck.rest
					* CFrame.Angles(droop + nod - breath * 0.5 + attackHead,
						loll * 0.7, loll + asleep * sleep.neckTilt)
			end

			--== JAW: chewing the air + aggressive bite snap on attack ==--
			-- Wall-clock, tied to nothing. Shut while it sleeps.
			if p.jaw then
				local chomp = (math.sin(t * 3.1 + p.phase) * 0.5 + 0.5) ^ 2
				p.jaw.motor.C0 = p.jaw.rest
					* CFrame.Angles(-chomp * math.rad(19) * wake - attackJaw, 0, 0)
			end
		end
	end
end)
