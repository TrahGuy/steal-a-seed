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
	-- Kept alive while any seam above is still nil, so a rig that streams in
	-- piece by piece gets the rest of its joints as they land. Dropped the
	-- moment the set is complete, and again if the model streams out.
	fill: RBXScriptConnection?,
	-- Where the body sits when fully asleep, already scaled by the builder that
	-- knows the creature's size. Identity for anything that does not set it,
	-- which is what keeps Greenhollow's brute exactly as it was.
	sleepBody: CFrame,
	stride: number,
	lastPos: Vector3,
	-- Eased rather than read straight off the speed, so stopping blends the
	-- run out instead of freezing it mid-step.
	moving: number,
	-- The heading the HEAD is currently pointed at, chasing the body's own.
	headYaw: number,
	-- Whether the head has ever been aimed. A parent tracked mid-turn would
	-- otherwise start with a 180-degree lag and swing its skull round once.
	headSet: boolean,
	-- 0 asleep, 1 awake. Blended so waking is a movement rather than a snap.
	wake: number,
	phase: number,
	sleep: SleepProfile,
}

local parents: { [Model]: Parent } = {}

--==============================================================================
-- THE ONE LIGHT A STRIKE IS ALLOWED TO TOUCH
--
-- Found once at track time. Astralmaw's builder puts a PointLight in its throat;
-- peaking that for a sixth of a second at impact is the whole visual effect
-- budget of the hit, and it is why there is no new emitter anywhere in here.
--==============================================================================
local function glowOf(model: Model): PointLight?
	local throat = model:FindFirstChild("MawThroat")
	if throat then
		return throat:FindFirstChildOfClass("PointLight")
	end
	return nil
end

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
	stride: number, moving: number, attackDt: number)
	local ch = p.mire :: MireChannels
	local asleep = 1 - wake

	--== EVERY SEAM, FROM ONE SCALAR ==--
	for _, row in ipairs(ch.seams) do
		row.motor.C0 = row.rest * row.delta:Lerp(CFrame.identity, wake)
	end

	--== ATTACK SWIPE / BITE ==--
	local attackArmPitch = 0
	local attackJaw = 0
	if attackDt >= 0 and attackDt < 0.85 then
		local pNorm = attackDt / 0.85
		if pNorm < 0.28 then
			local u = pNorm / 0.28
			local ease = math.sin(u * math.pi * 0.5)
			attackArmPitch = -math.rad(60) * ease
			attackJaw = math.rad(20) * ease
		elseif pNorm < 0.60 then
			local u = (pNorm - 0.28) / 0.32
			local ease = math.sin(u * math.pi * 0.5)
			attackArmPitch = -math.rad(60) + math.rad(130) * ease
			attackJaw = math.rad(20) + math.rad(40) * ease
		else
			local u = math.clamp((pNorm - 0.60) / 0.40, 0, 1)
			local ease = 1 - u
			attackArmPitch = math.rad(70) * ease
			attackJaw = math.rad(60) * ease
		end
	end

	--== THE WALK ==--
	-- Distance travelled, not the clock: a clock-driven leg slides, and this
	-- creature does its most important work at a run. `moving` already carries
	-- the wake scalar, so a sleeping Miremaw's legs are still.
	local function swing(row, phase: number, amp: number, extraPitch: number?)
		if row then
			row.motor.C0 = row.motor.C0
				* CFrame.Angles(math.sin(stride + phase) * amp * moving + (extraPitch or 0), 0, 0)
		end
	end
	swing(ch.byName.LeftHip, 0, MIRE_LEG_SWING)
	swing(ch.byName.RightHip, math.pi, MIRE_LEG_SWING)
	-- Arms counter the legs, and by less: it runs with them braced, not pumping.
	swing(ch.byName.RightShoulder, 0, MIRE_ARM_SWING, attackArmPitch)
	swing(ch.byName.LeftShoulder, math.pi, MIRE_ARM_SWING, attackArmPitch)
	if ch.byName.JawJoint then
		ch.byName.JawJoint.motor.C0 = ch.byName.JawJoint.motor.C0 * CFrame.Angles(-attackJaw, 0, 0)
	end

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
			local u = math.clamp((pNorm - 0.60) / 0.40, 0, 1)
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

--==============================================================================
-- ASTRALMAW: THE LAST GUARDIAN ON THE ROAD
--
-- THE BUG THIS EXISTS FOR IS A RATE, NOT AN AMPLITUDE. The shared walk advances
-- its stride by SWING_PER_STUD = 0.40 radians per stud travelled -- one full
-- cycle every 15.7 studs -- and that was tuned against WalkSpeed 19, where it
-- gives a comfortable 1.2 strides a second. Astralmaw runs at ninety-odd.
-- Measured in a real chase: one complete stride every 0.24 seconds, 4.2 Hz,
-- 13.6 frames per cycle at 57 fps and barely seven on a phone. Legs oscillating
-- that fast do not read as a stride at all; they read as a vibration, or as
-- nothing, which is the report.
--
-- SO THE STRIDE GETS LONGER INSTEAD OF FASTER. Real animals lengthen their
-- stride far more than they quicken it, and it is also the only model that
-- keeps a foot on the ground: amplitude rises with speed, the cycle stays
-- between about 1.1 and 2.5 Hz, and there is no speed at which acceleration
-- makes the feet skate.
--
-- EVERYTHING ELSE IS PREDATOR RATHER THAN LIMP. The shared gait deliberately
-- puts the legs 140 degrees apart and gives them different amplitudes, because
-- Greenhollow's brute is meant to lurch. This one alternates cleanly at 180,
-- counter-swings the shoulders against the hips, and gives the arms half again
-- the amplitude of the legs with a trailing phase -- heavy things arrive late.
--==============================================================================
local ASTRAL_STRIDE_BASE = 12.0
local ASTRAL_STRIDE_PER_SPEED = 0.30
local ASTRAL_STRIDE_MAX = 48.0
-- The speed at which the gait is at full amplitude. Below it the creature takes
-- shorter steps rather than the same step more slowly.
local ASTRAL_FULL_GAIT_AT = 90.0
local ASTRAL_HIP_SWING = math.rad(34)
local ASTRAL_ARM_SWING = math.rad(46)
-- Radians of phase the arms trail the legs by. Not a whole beat -- a lag.
local ASTRAL_ARM_LAG = 0.55
local ASTRAL_LEAN = math.rad(13)
local ASTRAL_BOB = 0.55
local ASTRAL_ROLL = math.rad(4.5)
local ASTRAL_HEAD_LAG_TAU = 0.16
local ASTRAL_HEAD_LAG_MAX = math.rad(26)
local ASTRAL_MOVE_TAU = 0.18
-- How much of the chase gait the walk home keeps. It still animates; it stops
-- looking like it wants something.
local ASTRAL_RETURN_CALM = 0.55
local ASTRAL_JAW_IDLE = math.rad(9)

--==============================================================================
-- THE STRIKE, AND IT STARTS AT THE IMPACT
--
-- `windup` is how long the server waits after stamping AttackSwipe before it
-- applies the impulse, replicated as an attribute so this does not have to
-- guess. Astralmaw's is ZERO, on purpose and after playing it: a coil before
-- the launch reads as lag rather than as anticipation, and the chase itself was
-- already the anticipation. Every other guardian has always been zero too.
--
-- SO THE SWEEP CANNOT START FROM A POSE THE ARM NEVER REACHED. With a wind-up
-- the arm is drawn 84 degrees back by the time the sweep begins; without one it
-- is wherever the run left it, and starting the sweep at -84 would snap the
-- shoulder backwards on the impact frame -- the pop this `coil` scalar exists
-- to prevent. At zero the strike opens 18 degrees back and is through you in a
-- seventh of a second.
--
-- Which arm strikes is derived from the attack's own timestamp rather than
-- rolled, so every client draws the same shoulder swinging.
--==============================================================================
local ASTRAL_SWEEP = 0.14
local ASTRAL_RECOVER = 0.36

local function astralStrike(dt: number, windup: number)
	-- returns: leadPitch, offPitch, coilYaw, jaw, headPitch, glow  (all 0 at rest)
	local total = windup + ASTRAL_SWEEP + ASTRAL_RECOVER
	if dt < 0 or dt >= total then
		return 0, 0, 0, 0, 0, 0
	end
	-- How far back the arm is when the sweep begins. A wind-up earns the full
	-- draw; without one it is a flick of the same swing.
	local coil = if windup > 0 then 1 else 0.22
	local back = -math.rad(84) * coil
	if dt < windup and windup > 0 then
		-- COIL. The striking arm draws back and up, the other braces forward,
		-- the shoulders turn into it and the jaw cracks open.
		local u = dt / windup
		local ease = math.sin(u * math.pi * 0.5)
		return back * ease, math.rad(26) * ease, math.rad(20) * ease,
			math.rad(16) * ease, -math.rad(15) * ease, ease * 0.55
	elseif dt < windup + ASTRAL_SWEEP then
		-- THE SWEEP. Everything unwinds through the impact in a seventh of a
		-- second, which is what makes it read as a strike rather than a push.
		local u = (dt - windup) / ASTRAL_SWEEP
		local ease = u * u
		return back + (math.rad(96) - back) * ease,
			math.rad(26) * coil - math.rad(50) * ease,
			math.rad(20) * coil - math.rad(46) * ease,
			math.rad(16) * coil + math.rad(40) * ease,
			-math.rad(15) * coil + math.rad(34) * ease,
			0.55 * coil + (1 - 0.55 * coil) * ease
	end
	-- FOLLOW THROUGH, then settle.
	local u = math.clamp((dt - windup - ASTRAL_SWEEP) / ASTRAL_RECOVER, 0, 1)
	local ease = 1 - u
	return math.rad(96) * ease, -math.rad(24) * ease, -math.rad(26) * ease,
		math.rad(56) * ease, math.rad(19) * ease, ease
end

local function animateAstralmaw(p: any, wake: number, t: number, dt: number,
	speed: number, state: string, attackDt: number, windup: number)
	--==========================================================================
	-- STRIDE: DISTANCE OVER A STRIDE LENGTH THAT GROWS WITH SPEED
	--==========================================================================
	local strideStuds = math.min(
		ASTRAL_STRIDE_BASE + speed * ASTRAL_STRIDE_PER_SPEED, ASTRAL_STRIDE_MAX)
	p.stride += speed * dt * (math.pi * 2 / strideStuds)
	local s = p.stride + p.phase

	local calm = if state == "returning" then ASTRAL_RETURN_CALM else 1.0
	local target = math.clamp(speed / ASTRAL_FULL_GAIT_AT, 0, 1) * wake
	p.moving += (target - p.moving) * math.min(1, dt / ASTRAL_MOVE_TAU)
	local gait = p.moving * calm
	local asleep = 1 - wake
	local sleep = p.sleep
	local breath = 0
	if sleep.breath > 0 then
		breath = math.sin(t * sleep.breathRate + p.phase) * sleep.breath * asleep
	end

	--== WHICH ARM, AND WHERE IN THE STRIKE ==--
	local leadPitch, offPitch, coilYaw, jawOpen, headPitch, glow =
		astralStrike(attackDt, windup)
	local leadLeft = (math.floor((p.attackAt or 0) * 4) % 2) == 0

	--==========================================================================
	-- 1. THE BODY LEANS INTO IT
	--
	-- On RootJoint, which is socketed at the point the creature stands on --
	-- never on HumanoidRootPart, which the server owns and the physics solver
	-- would fight over.
	--==========================================================================
	if p.rootJoint then
		local bob = -math.abs(math.sin(s)) * ASTRAL_BOB * gait
		local lean = -ASTRAL_LEAN * gait
		local roll = math.sin(s) * ASTRAL_ROLL * gait
		local sleepOffset = p.sleepBody:Lerp(CFrame.identity, wake)
		p.rootJoint.motor.C0 = p.rootJoint.rest
			* sleepOffset
			* CFrame.new(0, bob, 0)
			* CFrame.Angles(lean, coilYaw * 0.35, roll)
	end

	--==========================================================================
	-- 2. HIPS, CLEANLY ALTERNATING
	--==========================================================================
	local fold = asleep * sleep.armFold
	local splay = asleep * sleep.armSplay
	if p.leftLeg then
		p.leftLeg.motor.C0 = p.leftLeg.rest
			* CFrame.Angles(math.sin(s) * ASTRAL_HIP_SWING * gait, 0, 0)
	end
	if p.rightLeg then
		p.rightLeg.motor.C0 = p.rightLeg.rest
			* CFrame.Angles(math.sin(s + math.pi) * ASTRAL_HIP_SWING * gait, 0, 0)
	end

	--==========================================================================
	-- 3. SHOULDERS COUNTER-SWING, AND CARRY MORE
	--
	-- Opposite the hip on the same side, trailing it by a fraction of a beat,
	-- and half again the amplitude. That is the whole difference between a
	-- creature walking and a creature coming for you.
	--==========================================================================
	local lp = math.sin(s + math.pi + ASTRAL_ARM_LAG) * ASTRAL_ARM_SWING * gait
	local rp = math.sin(s + ASTRAL_ARM_LAG) * ASTRAL_ARM_SWING * gait
	if p.leftArm then
		p.leftArm.motor.C0 = p.leftArm.rest * CFrame.Angles(
			lp + fold + breath + (if leadLeft then leadPitch else offPitch),
			coilYaw, splay)
	end
	if p.rightArm then
		p.rightArm.motor.C0 = p.rightArm.rest * CFrame.Angles(
			rp + fold + breath + (if leadLeft then offPitch else leadPitch),
			-coilYaw, -splay)
	end
	if sleep.hipTurn > 0 then
		local turn = asleep * sleep.hipTurn
		if p.leftLeg then
			p.leftLeg.motor.C0 = p.leftLeg.motor.C0 * CFrame.Angles(0, -turn, -turn * 0.7)
		end
		if p.rightLeg then
			p.rightLeg.motor.C0 = p.rightLeg.motor.C0 * CFrame.Angles(0, turn, turn * 0.7)
		end
	end

	--==========================================================================
	-- 4. THE HEAD KEEPS LOOKING AT YOU, A BEAT LATE
	--
	-- The Humanoid's AutoRotate already turns the BODY at the target, so the
	-- honest way to make the head "track with restrained lag" is to let it trail
	-- the body's own heading and catch up -- no target position has to cross the
	-- wire for it, and it is right in both directions: chasing, the skull swings
	-- in behind the turn; walking home, it drifts.
	--==========================================================================
	local lag = 0
	do
		local look = p.root.CFrame.LookVector
		local yaw = math.atan2(-look.X, -look.Z)
		if not p.headSet then
			p.headYaw = yaw
			p.headSet = true
		end
		local d = (yaw - p.headYaw + math.pi) % (math.pi * 2) - math.pi
		p.headYaw += d * (1 - math.exp(-dt / ASTRAL_HEAD_LAG_TAU))
		lag = math.clamp((p.headYaw - yaw + math.pi) % (math.pi * 2) - math.pi,
			-ASTRAL_HEAD_LAG_MAX, ASTRAL_HEAD_LAG_MAX) * wake
	end
	if p.neck then
		local droop = asleep * sleep.neckDroop
		local nod = math.sin(s * 2 + 0.9) * math.rad(5.5) * gait
		p.neck.motor.C0 = p.neck.rest
			* CFrame.Angles(droop + nod - breath * 0.5 + headPitch,
				lag, asleep * sleep.neckTilt)
	end

	--==========================================================================
	-- 5. THE JAW, AND THE GLOW IT DRAGS WITH IT
	--
	-- A low idle working of the jaw rather than the shared chomp: constant
	-- chewing on a creature this size is noise, and the mouth has one job here
	-- which is to be wide open at the moment of impact.
	--==========================================================================
	if p.jaw then
		local idle = (math.sin(t * 1.7 + p.phase) * 0.5 + 0.5) * ASTRAL_JAW_IDLE * wake
		p.jaw.motor.C0 = p.jaw.rest * CFrame.Angles(-(idle + jawOpen), 0, 0)
	end

	--==========================================================================
	-- 6. THE VOID FACE PEAKS AT IMPACT AND NOWHERE ELSE
	--
	-- One brightness write on one light, and only while a strike is running --
	-- not a particle system turned up, and nothing every frame the rest of the
	-- time. Restored to the value the builder set the moment the strike ends.
	--==========================================================================
	if p.glow then
		local want = p.glowRest * (1 + glow * 1.6)
		if math.abs(p.glow.Brightness - want) > 0.01 then
			p.glow.Brightness = want
		end
	end
end

--==============================================================================
-- THE SEAMS THAT MAY ARRIVE LATE
--
-- Neck is not in here: it is the seam tryTrack refuses to register without, so
-- an entry always has one. Everything else is read once at registration and may
-- legitimately still be in flight, so it is absorbed as it lands.
--
-- WAITING FOR ALL SIX IS THE WRONG STOPPING CONDITION, and it is worth writing
-- down why. Only Astralmaw, Forgemaw and the shared ParentModel build the whole
-- seven-seam contract. TanglemireForms has no RootJoint, BramblebackModel has
-- three seams, and MiremawModel has one -- it drives everything else through
-- mireChannels. So "keep looking until nothing is nil" never terminates for
-- three of the five, which turns a bounded retry into a permanent one.
--
-- The seam is therefore taken off the SIGNAL instead of searched for. A
-- Motor6D that has just arrived is handed to the handler, so absorbing it is a
-- name compare rather than a walk of the model, and a rig that will never own
-- a RootJoint costs the same as one that already does.
--==============================================================================
local FILL_SEAMS = {
	{ field = "jaw", seam = "JawJoint" },
	{ field = "leftArm", seam = "LeftShoulder" },
	{ field = "rightArm", seam = "RightShoulder" },
	{ field = "leftLeg", seam = "LeftHip" },
	{ field = "rightLeg", seam = "RightHip" },
	{ field = "rootJoint", seam = "RootJoint" },
}

-- How long after a model appears its seams are still expected to be arriving.
-- Generous: streaming a rig in takes a small number of frames, and the cost of
-- being wrong in this direction is one idle connection.
local FILL_WINDOW = 10

-- One arrived Motor6D against the seams still missing. No search.
local function absorbSeam(p: Parent, d: Instance)
	if not d:IsA("Motor6D") then
		return
	end
	local entry = p :: any
	for _, f in ipairs(FILL_SEAMS) do
		if f.seam == d.Name and entry[f.field] == nil then
			entry[f.field] = { motor = d, rest = d.C0 }
			return
		end
	end
end

local function seamsComplete(p: Parent): boolean
	local entry = p :: any
	for _, f in ipairs(FILL_SEAMS) do
		if entry[f.field] == nil then
			return false
		end
	end
	return true
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
			moving = 0,
			headYaw = 0,
			headSet = false,
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
			-- The throat light Astralmaw's builder already made, found once so
			-- the strike can peak it without searching the model per frame.
			glow = glowOf(model),
			glowRest = (function()
				local g = glowOf(model)
				return if g then g.Brightness else 0
			end)(),
			attackAt = 0,
		}
		return true
	end

	--==================================================================
	-- REGISTERING IS NOT THE SAME AS BEING COMPLETE
	--
	-- tryTrack gates on the root and the Neck, then reads the other six
	-- seams ONCE, and the retry used to disconnect the first time the entry
	-- existed. With StreamingEnabled a rig arrives in pieces, so a model
	-- whose Neck lands before its LeftHip registers with leftLeg = nil --
	-- and because the entry now exists, nothing ever looked again. That leg
	-- was frozen until the next stream cycle, with nothing in the output.
	--
	-- Same shape as the bug written up at the top of this file, and as the
	-- stream-out one below: a snapshot taken before the model had finished
	-- arriving. So the retry now stays armed past registration and absorbs
	-- seams as they land, and it stops on whichever comes first -- the
	-- contract being complete, or the arrival window closing.
	--==================================================================
	local conn: RBXScriptConnection? = nil
	local openUntil = os.clock() + FILL_WINDOW

	local function release()
		if conn then
			conn:Disconnect()
			conn = nil
		end
		local q = parents[model]
		if q then
			q.fill = nil
		end
	end

	-- true once there is nothing left worth waiting for.
	local function arrived(d: Instance?): boolean
		if not model.Parent then
			return true
		end
		if not tryTrack() then
			return os.clock() > openUntil
		end
		local p = parents[model]
		if not p then
			return true
		end
		if d then
			absorbSeam(p, d)
		end
		return seamsComplete(p) or os.clock() > openUntil
	end

	if not arrived(nil) then
		conn = model.DescendantAdded:Connect(function(d)
			if arrived(d) then
				release()
			end
		end)
		-- Held on the entry so that dropping the entry drops the connection.
		local p = parents[model]
		if p then
			p.fill = conn
		end
	end
end

for _, m in ipairs(CollectionService:GetTagged(TAG)) do
	track(m)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(track)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(m)
	local p = parents[m :: Model]
	if p and p.fill then
		p.fill:Disconnect()
		p.fill = nil
	end
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
			--==============================================================
			-- STREAMING TOOK ITS PARTS, AND THIS USED TO BE PERMANENT
			--
			-- Dropping the entry is right -- the parts it held are destroyed.
			-- Not asking for the model back is not: with StreamingEnabled the
			-- MODEL persists on the client as a two-child stub and keeps its
			-- tag, so GetInstanceRemovedSignal never fires, GetInstanceAdded
			-- never fires again either, and the DescendantAdded retry that
			-- `track` arms was disconnected the first time it succeeded.
			--
			-- So the FIRST time a player walked out of range of a guardian and
			-- came back, that guardian stopped animating for the rest of the
			-- session. Measured in Play, from spawn, after one walk down the
			-- road: four of the five parents reported 0 of 7 motors changing
			-- over 0.4 seconds, and Astralmaw's LeftHip sat at exactly -0.00
			-- degrees through an entire chase. Only Emberroot's still moved,
			-- and only because it is far enough out that the whole MODEL
			-- streams rather than just its parts, so the tag signal did fire.
			--
			-- That is the report -- "its limbs do not visibly animate while
			-- chasing" -- and it was never in the animation code at all.
			--
			-- Re-arming costs one deferred call per stream-out. `track` bails
			-- immediately if the entry is back or the model has really gone,
			-- and it re-reads every rest C0 from the freshly streamed motors,
			-- which is correct: the server never writes C0, so what comes back
			-- is the builder's rest pose.
			--==============================================================
			if p.fill then
				p.fill:Disconnect()
				p.fill = nil
			end
			parents[model] = nil
			if model.Parent then
				task.defer(track, model)
			end
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
			local attackDt = workspace:GetServerTimeNow() - attackTime

			if p.mire then
				p.stride += speed * dt * SWING_PER_STUD
				animateMiremaw(p, wake, t, p.stride + p.phase,
					math.clamp(speed / 6, 0, 1) * wake, attackDt)
				continue
			end

			if tostring(model:GetAttribute("Species")) == "forgemaw" then
				p.stride += speed * dt * SWING_PER_STUD
				animateForgemaw(p, wake, t, p.stride + p.phase,
					math.clamp(speed / 6, 0, 1) * wake, attackDt)
				continue
			end

			--==============================================================
			-- ASTRALMAW TAKES ITS OWN PATH, AND TAKES IT INSTEAD
			--
			-- Same rule as Miremaw: one writer per Motor6D.C0. It advances its
			-- own stride because the shared rate is the thing it is replacing.
			--==============================================================
			if tostring(model:GetAttribute("Species")) == "astralmaw" then
				p.attackAt = attackTime
				animateAstralmaw(p, wake, t, dt, speed,
					tostring(model:GetAttribute("ParentState")), attackDt,
					(model:GetAttribute("AttackWindup") :: number?) or 0)
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
			local attackDt = workspace:GetServerTimeNow() - attackTime
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
					local u = math.clamp((pNorm - 0.60) / 0.40, 0, 1)
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
