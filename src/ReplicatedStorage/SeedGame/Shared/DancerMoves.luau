--!strict
-- Steal a Seed :: DancerMoves
--
-- The eight disco dancers' dances (2026-10-03): the owner's preview scripts
-- (CocolocoDance, DiscopuffDance, ... -- in the backups, never run in the game)
-- ported line for line. Each dance is a function of the BEAT -- the global
-- event's elapsed time x DanceBPM / 60 x RateScale -- so every dancer on every
-- client is on the same beat, the way the scripts' "troupe" was when the place
-- started them together. DiscoDancers (client) plays them on a kinematic tree
-- of anchored, non-colliding parts; nothing here touches an instance.
--
--==============================================================================
-- WHAT IS THE SCRIPTS' AND WHAT IS NOT
--
-- Every period, amplitude, phase lag and routine (A for 8 beats, B for 8) is
-- the script's. Two things are the game's:
--
--   DISTANCE  The scripts moved the Pelvis by studs written for a model at the
--             size they were authored (Pricklepop's, scale 1); the owner's
--             Scale tool then grew the others up to 5x without touching the
--             numbers. Here a translation is taken at THIS copy's size --
--             the authored stud x the model's Scale-tool factor x the copy's
--             own 0.7-1.3 -- so a big dancer moves exactly like a small one.
--   GROUND    The scripts dipped the whole model on every beat, feet and all,
--             into the floor. The dip is kept for the body, and the hips are
--             raised by the same amount, so the feet stay on the ground.
--             The two-beat hip roll still tips one rigid leg's foot a little
--             below the floor (about 2% of the dancer's height); Lift (below)
--             raises the posed dancer by exactly that, so the low foot stays
--             planted and the other comes off the floor -- the weight shift.
--==============================================================================

local DancerMoves = {}

local sin, cos, abs, pi, rad, clamp = math.sin, math.cos, math.abs, math.pi, math.rad, math.clamp

export type Pose = {
	-- The Pelvis's move off its rest frame.
	root: CFrame,
	-- Each Motor6D's pose (C0 * pose * C1^-1), by name.
	joints: { [string]: CFrame },
}

-- The parts every script shares: the bounce, the two-beat sway and the root
-- move; the waist counter-sway and the head nod; the step-tap at the hips.
local function core(bt: number, energy: number, k: number, bounce: number, sway: number, roll: number,
	twist: number): (number, number, number, number, CFrame)
	local beatBounce = abs(sin(bt * pi)) * bounce * energy
	local swayPhase = sin(bt * pi * 0.5)
	local hipSwayX = swayPhase * sway * energy
	local hipRollZ = swayPhase * roll * energy
	local hipTwistY = cos(bt * pi * 0.5) * twist * energy
	local root = CFrame.new(hipSwayX * k, -beatBounce * k, 0) * CFrame.Angles(0, hipTwistY, -hipRollZ)
	return beatBounce, swayPhase, hipRollZ, hipTwistY, root
end

local function hips(joints: { [string]: CFrame }, bt: number, energy: number, k: number, beatBounce: number,
	swayPhase: number, hipRollZ: number, lift: number)
	local tap = abs(sin(bt * pi))
	local stepLiftL = clamp(swayPhase, 0, 1) * tap * lift * energy
	local stepLiftR = clamp(-swayPhase, 0, 1) * tap * lift * energy
	-- Raised by the body's dip (see GROUND above), so the feet stay down.
	local up = CFrame.new(0, beatBounce * k, 0)
	joints.HipL = up * CFrame.Angles(stepLiftL, 0, hipRollZ * 0.8)
	joints.HipR = up * CFrame.Angles(stepLiftR, 0, hipRollZ * 0.8)
end

local function arms(joints: { [string]: CFrame }, lp: number, lr: number, rp: number, rr: number)
	joints.ShoulderL = CFrame.Angles(lp, 0, lr)
	joints.ShoulderR = CFrame.Angles(rp, 0, rr)
end

local DANCES: { [string]: (number, number, number) -> Pose } = {}

-- COCOLOCO: Calypso Coconut Hop & Dip; a 2-beat rolling palm sway; the
-- coconut-and-frond canopy whips behind; Bongo Taps, then Palm Frond Breeze.
DANCES.cocoloco = function(bt, energy, k)
	local j = {}
	local bounce, swayPhase, hipRollZ, hipTwistY, root = core(bt, energy, k, 0.14, 0.26, 0.15, 0.14)
	j.Waist = CFrame.Angles(sin(bt * pi) * 0.08 * energy, -hipTwistY * 0.5, -hipRollZ * 1.3)
	j.Neck = CFrame.Angles(sin(bt * pi) * 0.16 * energy + 0.04, -hipTwistY * 0.4, swayPhase * 0.12 * energy)
	j.CanopyJoint = CFrame.Angles(-sin((bt - 0.18) * pi * 2) * 0.26 * energy, 0,
		-cos((bt - 0.22) * pi * 0.5) * 0.32 * energy)
	if math.floor(bt / 8) % 2 == 0 then
		local tapL = sin(bt * pi * 2) * 0.4 * energy
		arms(j, rad(-30) + tapL, rad(-25) + swayPhase * 0.2, rad(-30) - tapL, rad(25) + swayPhase * 0.2)
	else
		local breeze = sin(bt * pi * 0.5) * 0.6 * energy
		local nod = sin(bt * pi) * 0.22 * energy
		arms(j, rad(-25) + nod, rad(-45) + breeze, rad(-25) - nod, rad(45) + breeze)
	end
	hips(j, bt, energy, k, bounce, swayPhase, hipRollZ, 0.46)
	return { root = root, joints = j }
end

-- DISCOPUFF: Disco Fever Dip & Bounce; the afro puffs lag with spring
-- inertia; the Saturday Night Fever point (up to the stars, down across the
-- hip), then the Double Disco Roll & Ceiling Push.
DANCES.discopuff = function(bt, energy, k)
	local j = {}
	local bounce, swayPhase, hipRollZ, hipTwistY, root = core(bt, energy, k, 0.15, 0.28, 0.16, 0.14)
	j.Waist = CFrame.Angles(sin(bt * pi) * 0.08 * energy, -hipTwistY * 0.5, -hipRollZ * 1.3)
	j.Neck = CFrame.Angles(sin(bt * pi) * 0.18 * energy + 0.05, -hipTwistY * 0.4, swayPhase * 0.12 * energy)
	j.AfroJoint = CFrame.Angles(-sin((bt - 0.18) * pi * 2) * 0.28 * energy, 0,
		-cos((bt - 0.22) * pi * 0.5) * 0.32 * energy)
	if math.floor(bt / 8) % 2 == 0 then
		if sin(bt * pi * 0.5) > 0 then
			arms(j, rad(25), rad(-35), rad(-115) + sin(bt * pi) * 0.2 * energy, rad(45))
		else
			arms(j, rad(-35), rad(-45), rad(-20) - sin(bt * pi) * 0.2 * energy, rad(-35))
		end
	else
		local roll = sin(bt * pi * 2) * 0.45 * energy
		local pump = sin(bt * pi) * 0.35 * energy
		arms(j, rad(-65) + roll + pump, rad(-35) + swayPhase * 0.2, rad(-65) - roll + pump, rad(35) + swayPhase * 0.2)
	end
	hips(j, bt, energy, k, bounce, swayPhase, hipRollZ, 0.46)
	return { root = root, joints = j }
end

-- TURNIPOP: Bouncy Turnip Hop & Dip; the twin sprout pigtails twirl like a
-- helicopter; Mitten Clap & Wave, then Shaking Maraca Mitten Shuffles.
DANCES.turnipop = function(bt, energy, k)
	local j = {}
	local bounce, swayPhase, hipRollZ, hipTwistY, root = core(bt, energy, k, 0.15, 0.26, 0.15, 0.12)
	j.Waist = CFrame.Angles(sin(bt * pi) * 0.08 * energy, -hipTwistY * 0.5, -hipRollZ * 1.3)
	j.Neck = CFrame.Angles(sin(bt * pi) * 0.16 * energy + 0.04, -hipTwistY * 0.4, swayPhase * 0.12 * energy)
	j.SproutJoint = CFrame.Angles(sin(bt * pi * 2) * 0.35 * energy, 0,
		cos(bt * pi * 2) * 0.35 * energy + swayPhase * 0.2)
	if math.floor(bt / 8) % 2 == 0 then
		local wave = sin(bt * pi) * 0.58 * energy
		arms(j, rad(-45) + wave, rad(-25) + swayPhase * 0.22, rad(-45) - wave, rad(25) + swayPhase * 0.22)
	else
		local shake = sin(bt * pi * 2) * 0.32 * energy
		local side = sin(bt * pi * 0.5) * 0.45 * energy
		arms(j, rad(-20) + shake, rad(-35) + side, rad(-20) - shake, rad(35) + side)
	end
	hips(j, bt, energy, k, bounce, swayPhase, hipRollZ, 0.46)
	return { root = root, joints = j }
end

-- BANANABOP: Tropical Island Hula Bounce; the banana-frond canopy billows
-- behind; Hula Leaf-Palm Waves, then Tropical Limbo / Island Groove Sway.
DANCES.bananabop = function(bt, energy, k)
	local j = {}
	local bounce, swayPhase, hipRollZ, hipTwistY, root = core(bt, energy, k, 0.14, 0.26, 0.15, 0.14)
	j.Waist = CFrame.Angles(sin(bt * pi) * 0.08 * energy, -hipTwistY * 0.5, -hipRollZ * 1.3)
	j.Neck = CFrame.Angles(sin(bt * pi) * 0.16 * energy + 0.04, -hipTwistY * 0.4, swayPhase * 0.12 * energy)
	j.CanopyJoint = CFrame.Angles(-sin((bt - 0.18) * pi * 2) * 0.25 * energy, 0,
		-cos((bt - 0.22) * pi * 0.5) * 0.32 * energy)
	if math.floor(bt / 8) % 2 == 0 then
		local wave = sin(bt * pi) * 0.55 * energy
		arms(j, rad(-45) + wave, rad(-25) + swayPhase * 0.25, rad(-45) - wave, rad(25) + swayPhase * 0.25)
	else
		local swayWave = sin(bt * pi * 0.5) * 0.6 * energy
		local nod = sin(bt * pi) * 0.22 * energy
		arms(j, rad(-25) + nod, rad(-45) + swayWave, rad(-25) - nod, rad(45) + swayWave)
	end
	hips(j, bt, energy, k, bounce, swayPhase, hipRollZ, 0.46)
	return { root = root, joints = j }
end

-- SHROOMHOP (128 BPM): Bouncy Mushroom Hop & Dip; the heavy cap tips and lags
-- with floppy inertia; alternating Stubby Pumps, then both arms cheering.
DANCES.shroomhop = function(bt, energy, k)
	local j = {}
	local bounce, swayPhase, hipRollZ, hipTwistY, root = core(bt, energy, k, 0.15, 0.28, 0.16, 0.14)
	j.Waist = CFrame.Angles(sin(bt * pi) * 0.08 * energy, -hipTwistY * 0.6, -hipRollZ * 1.4)
	j.Neck = CFrame.Angles(sin(bt * pi) * 0.16 * energy + 0.04, -hipTwistY * 0.3, swayPhase * 0.12 * energy)
	j.CapJoint = CFrame.Angles(-sin((bt - 0.18) * pi) * 0.28 * energy, 0,
		-cos((bt - 0.22) * pi * 0.5) * 0.32 * energy)
	if math.floor(bt / 8) % 2 == 0 then
		local pump = sin(bt * pi) * 0.65 * energy
		arms(j, rad(-55) + pump, rad(-25) + swayPhase * 0.2, rad(-55) - pump, rad(25) + swayPhase * 0.2)
	else
		local cheer = sin(bt * pi) * 0.55 * energy
		arms(j, rad(-65) + cheer, rad(-40) + swayPhase * 0.25, rad(-65) + cheer, rad(40) + swayPhase * 0.25)
	end
	hips(j, bt, energy, k, bounce, swayPhase, hipRollZ, 0.48)
	return { root = root, joints = j }
end

-- PRICKLEPOP: Chunky Cactus Stomp Bounce; the desert flower crown wobbles;
-- alternating Saguaro Pumps, then the Arm Swing & Windmill Rock.
DANCES.pricklepop = function(bt, energy, k)
	local j = {}
	local bounce, swayPhase, hipRollZ, hipTwistY, root = core(bt, energy, k, 0.14, 0.26, 0.15, 0.12)
	j.Waist = CFrame.Angles(sin(bt * pi) * 0.08 * energy, -hipTwistY * 0.5, -hipRollZ * 1.3)
	j.Neck = CFrame.Angles(sin(bt * pi) * 0.16 * energy + 0.04, -hipTwistY * 0.4, swayPhase * 0.12 * energy)
	j.CrownJoint = CFrame.Angles(-sin((bt - 0.16) * pi * 2) * 0.26 * energy, 0,
		-cos((bt - 0.20) * pi * 0.5) * 0.24 * energy)
	if math.floor(bt / 8) % 2 == 0 then
		local pump = sin(bt * pi) * 0.58 * energy
		arms(j, rad(-40) + pump, rad(-20) + swayPhase * 0.25, rad(-40) - pump, rad(20) + swayPhase * 0.25)
	else
		local swing = sin(bt * pi * 0.5) * 0.55 * energy
		local nod = sin(bt * pi) * 0.25 * energy
		arms(j, rad(-15) + nod, rad(-35) + swing, rad(-15) - nod, rad(35) + swing)
	end
	hips(j, bt, energy, k, bounce, swayPhase, hipRollZ, 0.45)
	return { root = root, joints = j }
end

-- GROOVEROOT: a crisp dip and rebound on every downbeat; the stamen pom-pom
-- spring-whips; the Leaf-Frond Roof Pump, then the Frond Windmill Groove.
DANCES.grooveroot = function(bt, energy, k)
	local j = {}
	local bounce, swayPhase, hipRollZ, hipTwistY, root = core(bt, energy, k, 0.14, 0.25, 0.14, 0.12)
	j.Waist = CFrame.Angles(sin(bt * pi) * 0.08 * energy, -hipTwistY * 0.6, -hipRollZ * 1.5)
	j.Neck = CFrame.Angles(sin(bt * pi) * 0.18 * energy + 0.05, -hipTwistY * 0.4, swayPhase * 0.12 * energy)
	j.StamenJoint = CFrame.Angles(-sin((bt - 0.18) * pi * 2) * 0.35 * energy, 0,
		-cos((bt - 0.18) * pi * 0.5) * 0.32 * energy)
	if math.floor(bt / 8) % 2 == 0 then
		local pump = sin(bt * pi) * 0.55 * energy
		arms(j, rad(-55) + pump, rad(-30) + swayPhase * 0.25, rad(-55) - pump, rad(30) + swayPhase * 0.25)
	else
		local waveRoll = sin(bt * pi * 0.5) * 0.65 * energy
		local waveBob = sin(bt * pi) * 0.25 * energy
		arms(j, rad(-20) + waveBob, rad(-45) + waveRoll, rad(-20) - waveBob, rad(45) + waveRoll)
	end
	hips(j, bt, energy, k, bounce, swayPhase, hipRollZ, 0.45)
	return { root = root, joints = j }
end

-- FLORASWAY (120 BPM): Bouncy Blossom Waltz; the two-segment stem undulates
-- in an S (the lower stem leans with the hips, the upper counters); the petal
-- frame pulses; Leaf Fan Waves, then the side-to-side Floral Waltz.
DANCES.florasway = function(bt, energy, k)
	local j = {}
	local bounce, swayPhase, hipRollZ, hipTwistY, root = core(bt, energy, k, 0.13, 0.24, 0.12, 0.12)
	j.Waist = CFrame.Angles(sin(bt * pi) * 0.08 * energy, -hipTwistY * 0.5, -hipRollZ * 1.3)
	j.Chest = CFrame.Angles(-sin(bt * pi) * 0.06 * energy, hipTwistY * 0.3, hipRollZ * 1.6)
	j.Neck = CFrame.Angles(sin(bt * pi) * 0.16 * energy + 0.04, -hipTwistY * 0.4, -swayPhase * 0.15 * energy)
	j.PetalJoint = CFrame.Angles(sin(bt * pi) * 0.12 * energy, 0, 0)
	if math.floor(bt / 8) % 2 == 0 then
		local fan = sin(bt * pi) * 0.52 * energy
		arms(j, rad(-50) + fan, rad(-30) + swayPhase * 0.28, rad(-50) - fan, rad(30) + swayPhase * 0.28)
	else
		local side = sin(bt * pi * 0.5) * 0.65 * energy
		local nod = sin(bt * pi) * 0.22 * energy
		arms(j, rad(-25) + nod, rad(-45) + side, rad(-25) - nod, rad(45) + side)
	end
	hips(j, bt, energy, k, bounce, swayPhase, hipRollZ, 0.45)
	return { root = root, joints = j }
end

DancerMoves.Dances = DANCES

-- The pose of dancer `id` at beat `bt`, its DanceEnergy `energy`, translations
-- taken at factor `k`; nil for an id with no dance.
function DancerMoves.Pose(id: string, bt: number, energy: number, k: number): Pose?
	local dance = DANCES[id]
	if not dance then
		return nil
	end
	return dance(bt, energy, k)
end

export type Foot = { index: number, half: Vector3 }

-- How far a posed dancer must rise so none of `feet` (each a part's index in
-- `cframes` and half its size) dips below `ground`, the height its rest pose
-- stands on; 0 when none does. It never lowers one.
function DancerMoves.Lift(cframes: { CFrame }, feet: { Foot }, ground: number): number
	local low = math.huge
	for _, f in ipairs(feet) do
		local _, y, _, _, _, _, r10, r11, r12 = cframes[f.index]:GetComponents()
		local h = f.half
		low = math.min(low, y - (abs(r10) * h.X + abs(r11) * h.Y + abs(r12) * h.Z))
	end
	return if low < ground then ground - low else 0
end

return DancerMoves
