--!strict
-- Steal a Seed :: SecretIdle
--
-- The idle the owner authored for the two secret plants -- the SnarlbloomIdle
-- and PetalfawnIdle scripts that came in with the models on 2026-10-01 -- played
-- on the CLIENT over the replayed rig (SecretModel). Same joints, same periods,
-- same snap, blink and tap; nothing retimed.
--
--==============================================================================
-- WHY A KINEMATIC TREE AND NOT Motor6D.Transform
--
-- The inserted scripts wrote Motor6D.Transform from a server Script. Transform
-- does not replicate, the animation step consumes it, and any Animator
-- overwrites it (ParentAnim learned this the hard way), so a server idle is one
-- nobody sees. Every plant in this game is also ANCHORED -- PlantFormsSpec,
-- HatchFX's scrub, giveTool, PlantSway all assume it -- and an anchored part is
-- not moved by a joint at all.
--
-- So the joints are read as DATA. At registration the model's Motor6Ds and
-- Welds are walked from the authored Footing into a tree; every frame each
-- part's CFrame is computed from its parent's through the joint --
--
--     child = parent * C0 * pose * C1^-1        (the child is Part1)
--     child = parent * C1 * pose^-1 * C0^-1     (the child is Part0)
--
-- with `pose` the idle's own per-joint CFrame, identity for a Weld -- and
-- written to the anchored part. The result is the rig the owner built, moving
-- as it did, with no physics assembly and no replication.
--
-- The whole-model pivot stays PlantSway's: it leans and rattles the model by
-- PivotTo, and this reads the pivot fresh each frame, so the two never write
-- the same thing.
--==============================================================================
-- AND THEY WALK (2026-10-02)
--
-- A planted Secret roams its plot on the legs PlantService publishes, like any
-- grown creature: PlantSway carries and turns the whole model along the leg,
-- and THIS file steps its legs -- every joint stays this file's alone. The gait
-- is driven by how far the model has actually moved (and turned) since the last
-- frame, never by a clock, so a foot on the ground stays where it was put while
-- the body passes over it: each leg is solved hip-to-ankle (two joints, the
-- authored bend) onto a target that slides back under the body for a planted
-- foot and arcs forward for a lifted one. A turn on the spot marches in place.
-- The walk fades in and out over the idle by its own weight, so the blink, the
-- jaw, the eyes, the petals and the tail never stop; only a PLANTED model walks
-- (`walks`, the Planted tag) -- one carried overhead or in a viewport never does.
--==============================================================================
-- AND THE RAIN EVENT'S EIGHT (2026-10-02)
--
-- Puddlepod, Drizzlet, Lotusling (Pod 1, and their larger Pod 2 forms),
-- Tempestoak and Thundermaw (Pod 3) are the same kind of supplied rig, each
-- with the idle its owner-authored script played (PuddlepodIdle and the rest:
-- same joints, periods, sips, shakes, blooms, roars, blinks and lights, ported
-- below as written). A Pod 2 form plays its Pod 1 creature's idle; the few
-- distances those scripts write in their `Unit` (a bob, a ripple's spread) are
-- taken at the larger form's own size, so it moves exactly as the small one
-- does, only bigger. Their walks use the gait above with two more kinds of leg:
-- the bipeds' hip, knee and ankle chains, whose BODY is the rig's own root
-- part rather than a "Root" joint, and the small forms' FEET, which hang
-- straight off the base or the body and are carried to each step themselves.
--==============================================================================

local SecretIdle = {}

-- The supplied forms' recorded sizes: a Pod 2 form's size over its Pod 1
-- form's is the scale its walk and its idle's distances are taken at.
local RainForms = require(script.Parent:WaitForChild("RainForms"))

type Node = {
	part: BasePart,
	-- The node this one hangs off, or nil for the tree's root and for any part
	-- no joint reaches (those keep `rel` off the pivot).
	parent: number?,
	-- true: this part is the joint's Part1; false: it is Part0 and the parent is Part1.
	forward: boolean,
	c0: CFrame,
	c1: CFrame,
	-- The Motor6D's name, which is what the idle poses by. Nil for a Weld.
	motor: string?,
	-- Rest offset from the model pivot, for the root and unreached parts.
	rel: CFrame,
}

type Sized = { part: BasePart, size: Vector3 }

-- One leg of the gait, resolved once off the rest pose: where its three joints
-- sit (in the model's pivot frame), how long its two bones are in the plane it
-- swings in, which way it bends, and the walk pose it was given this frame.
type Leg = {
	hip: string,
	knee: string,
	ankle: string,
	offset: number,
	hipAt: Vector3,
	ankleAt: Vector3,
	l1: number,
	l2: number,
	thigh0: number,
	shin0: number,
	bend: number,
	walkHip: CFrame,
	walkKnee: CFrame,
	walkAnkle: CFrame,
	swing: number,
	-- The foot's own state. While it is down, where its ankle stands in the
	-- WORLD and which way the foot points (`plantedYaw`, the body's yaw frame):
	-- held there, however the body moves above it. While it is up, where it
	-- left from. `home`: it has stepped back under the body since it stopped.
	down: boolean,
	planted: Vector3?,
	plantedYaw: number,
	liftFrom: Vector3?,
	liftYaw: number,
	home: boolean,
	-- "chain": the hip, knee and ankle above, two bones solved onto the target.
	-- "foot": one joint, the foot itself, carried to the target (the Rain
	-- event's small forms stand on feet hung straight off their base or body).
	kind: string,
	foot: string?,
	-- A limb turned to keep pointing from its own joint at the foot (the
	-- Lotusling's legs, whose feet hang off the body beside them), or nil.
	aim: string?,
	-- Whether the foot's joint hangs off the BODY, which the walk bobs and
	-- leans, or off the base, which the walk never moves.
	onBody: boolean,
}

-- One leg as a profile names it: a chain (hip, knee, ankle) or a foot, with
-- the limb that aims at it.
type LegSpec = {
	hip: string?,
	knee: string?,
	ankle: string?,
	foot: string?,
	aim: string?,
	offset: number,
}

-- A form's walk, as numbers. `reach`: how far a planted foot travels either side
-- of its rest spot (studs); `duty`: the share of a stride a foot is down; `lift`:
-- how high a stepping foot clears the soil; `footSwing`: the foot's own pitch at
-- the top of a step; `bob`/`bobPeak`: the body's rise and where in the stride it
-- tops out; `roll`/`rollPeak`: the weight shift onto the standing side; `lean`:
-- the body's pitch into the walk; `arms`: joints that swing against a leg;
-- `nod`: a joint that nods with each pair of steps; `crouch`: how far the body
-- settles while it walks, so a long stride still reaches the soil on legs that
-- stand nearly straight.
type WalkProfile = {
	legs: { LegSpec },
	-- The body is the rig's own root part rather than a joint called Root (the
	-- Rain event's Lotusling, Tempestoak and Thundermaw): the walk bobs, rolls
	-- and leans the whole tree about where that part stands.
	virtual: boolean?,
	duty: number,
	reach: number,
	lift: number,
	footSwing: number,
	crouch: number,
	bob: number,
	bobPeak: number,
	roll: number,
	rollPeak: number,
	lean: number,
	arms: { { joint: string, leg: number, gain: number } },
	nod: { joint: string, amp: number }?,
}

type Gait = {
	profile: WalkProfile,
	legs: { Leg },
	-- The pose key the body's walk is written under: "Root", or the virtual
	-- body's own key for a rig whose body is its root part.
	bodyKey: string,
	-- Every distance in the profile is multiplied by this: 1, or a Pod 2 form's
	-- size over its Pod 1 form's.
	scale: number,
	-- Every joint the walk poses, cleared before the idle so a joint the idle
	-- does not set this frame blends from rest, not from last frame's walk.
	joints: { string },
	rootAt: Vector3,
	turnRadius: number,
	-- Studs travelled per whole stride: what turns distance into steps.
	stride: number,
	phase: number,
	-- How much of the body's walk shows (its bob, roll, lean, arms, nod), and how
	-- much of the legs is the walk's rather than the idle's.
	weight: number,
	legWeight: number,
	-- Standing again with a foot not yet home: the legs step back under the body.
	settling: boolean,
	-- Walking (or turning) at all, last frame: setting off is where the stride
	-- is started from.
	moving: boolean,
	speed: number,
	-- The share of the travel that is the body moving rather than turning:
	-- one in a straight walk, nothing while it turns on the spot.
	along: number,
	-- Which way it is turning, eased between -1 and 1.
	turnDir: number,
	-- Which way, in its own frame, the body is travelling: forward along a leg,
	-- but sideways too while PlantSway turns it about its footprint's centre
	-- rather than its pivot. A planted foot slides the other way.
	dirX: number,
	dirZ: number,
	lastPos: Vector3?,
	lastYaw: number?,
	lastT: number?,
	lastMoveT: number?,
}

export type Rig = {
	model: Model,
	form: string,
	nodes: { Node },
	-- Node indices in parent-before-child order.
	order: { number },
	pose: { [string]: CFrame },
	phase: number,
	stopped: boolean,
	lastSnap: number,
	-- Snarlbloom's gullet, light and spores; Petalfawn's bud.
	gullet: BasePart?,
	gulletSize: Vector3?,
	light: PointLight?,
	lightBase: number?,
	spores: ParticleEmitter?,
	irises: { Sized },
	eyes: { Sized },
	bud: BasePart?,
	budBase: Color3?,
	budHot: Color3?,
	unit: number,
	-- The walk (nil only for a form with no legs to step), and whether this copy
	-- may walk at all: the client says so each frame from the Planted tag.
	gait: Gait?,
	walks: boolean,
	-- THE RAIN EVENT'S FORMS (2026-10-02). `idle` is the idle played (a Pod 2
	-- form plays its Pod 1 creature's); `scale` its size over that form's;
	-- `bodyAt` where the root part stands for a rig whose body IS its root;
	-- `named` the parts its idle sizes, lights or flickers, by name; `rest` their
	-- authored sizes; `phases` their authored Phase; `emitters` and `lights` by
	-- name, the lights with their authored brightness; `lastEvent` the cycle of
	-- the idle's last one-shot (a sip, a shake, a bloom, a roar).
	idle: string,
	scale: number,
	rootNode: number?,
	bodyAt: Vector3?,
	named: { [string]: { BasePart } },
	rest: { [BasePart]: Vector3 },
	phases: { [BasePart]: number },
	emitters: { [string]: ParticleEmitter },
	lights: { [string]: PointLight },
	lightRest: { [PointLight]: number },
	lastEvent: number,
}

-- The pose key of a virtual body (see WalkProfile.virtual): no Motor6D is ever
-- called this.
local BODY = " body"

local scanRain: (Rig, Model, { BasePart }) -> ()


local IDENTITY = CFrame.identity
local rad, sin, cos, pi, exp = math.rad, math.sin, math.cos, math.pi, math.exp

local function wave(t: number, period: number, lag: number?): number
	return sin(t * 2 * pi / period - (lag or 0))
end

--==============================================================================
-- THE WALK: EACH FORM'S GAIT, AS NUMBERS
--
-- The joint names are the authored rigs' own (SecretForms). Every joint frame
-- of both rigs is square to the model at rest, so a pitch is CFrame.Angles(a,
-- 0, 0) and a positive `a` swings a hanging limb FORWARD (toward -Z, the way
-- both creatures face) -- the convention the idles below already use.
--
--   Snarlbloom   a heavy biped: the legs alternate, the weight rolls onto the
--                standing leg, the body rises over it and dips between steps,
--                it leans into the walk, and the leaf-blade arms swing against
--                the legs. Big, slow steps.
--   Petalfawn    a four-legged walk in the lateral sequence -- back left, front
--                left, back right, front right, a quarter of a stride apart --
--                with three hooves down most of the time, a light bob, the
--                neck nodding with each pair of steps and the hooves curling
--                as they lift.
--==============================================================================
local WALKS: { [string]: WalkProfile } = {
	snarlbloom = {
		legs = {
			{ hip = "HipL", knee = "KneeL", ankle = "AnkleL", offset = 0 },
			{ hip = "HipR", knee = "KneeR", ankle = "AnkleR", offset = 0.5 },
		},
		duty = 0.62,
		reach = 2.2,
		lift = 1.4,
		footSwing = rad(10),
		crouch = 0.15,
		bob = 0.22,
		bobPeak = 0.31,
		roll = rad(2.2),
		rollPeak = 0.31,
		lean = -rad(2.5),
		arms = {
			{ joint = "ShoulderL", leg = 1, gain = -0.6 },
			{ joint = "ShoulderR", leg = 2, gain = -0.6 },
		},
		nod = nil,
	},
	petalfawn = {
		legs = {
			{ hip = "HipBL", knee = "KneeBL", ankle = "AnkleBL", offset = 0 },
			{ hip = "HipFL", knee = "KneeFL", ankle = "AnkleFL", offset = 0.25 },
			{ hip = "HipBR", knee = "KneeBR", ankle = "AnkleBR", offset = 0.5 },
			{ hip = "HipFR", knee = "KneeFR", ankle = "AnkleFR", offset = 0.75 },
		},
		duty = 0.66,
		-- Its legs stand within a fifth of a stud of straight, so its stride is
		-- short and it settles a little to walk: every hoof reaches the soil.
		reach = 1.6,
		lift = 1.2,
		footSwing = -rad(18),
		crouch = 0.3,
		bob = 0.08,
		bobPeak = 0.2,
		roll = rad(0.8),
		rollPeak = 0.45,
		lean = 0,
		arms = {},
		nod = { joint = "Neck1", amp = rad(1.5) },
	},
	--==========================================================================
	-- THE RAIN EVENT'S (2026-10-02). A Pod 2 form walks its Pod 1 creature's
	-- walk at its own size (Gait.scale), so every number here is the small one's.
	--
	--   Puddlepod    a cup on two little feet hung off its base: a waddle --
	--                quick short steps, the cup rolling onto each foot, the
	--                arms swinging against them.
	--   Drizzlet     the same build under its umbrella, a little longer step.
	--   Lotusling    a bud on two stilts, each foot hung off the body beside its
	--                leg: the leg swings to follow its foot.
	--   Tempestoak   a heavy biped on hip, knee and ankle: big slow steps, the
	--                trunk settling and rolling over the standing leg, the arms
	--                swinging against the legs.
	--   Thundermaw   the same, leaning into the walk, the neck nodding with each
	--                pair of steps.
	--==========================================================================
	puddlepod = {
		legs = {
			{ foot = "FootL", offset = 0 },
			{ foot = "FootR", offset = 0.5 },
		},
		duty = 0.6,
		reach = 0.55,
		lift = 0.45,
		footSwing = 0,
		crouch = 0,
		bob = 0.12,
		bobPeak = 0.25,
		roll = rad(4),
		rollPeak = 0.25,
		lean = -rad(3),
		arms = {
			{ joint = "ArmL", leg = 1, gain = -0.6 },
			{ joint = "ArmR", leg = 2, gain = -0.6 },
		},
		nod = nil,
	},
	drizzlet = {
		legs = {
			{ foot = "FootL", offset = 0 },
			{ foot = "FootR", offset = 0.5 },
		},
		duty = 0.6,
		reach = 0.75,
		lift = 0.6,
		footSwing = 0,
		crouch = 0,
		bob = 0.15,
		bobPeak = 0.25,
		roll = rad(3),
		rollPeak = 0.25,
		lean = -rad(2),
		arms = {
			{ joint = "ArmL", leg = 1, gain = -0.6 },
			{ joint = "ArmR", leg = 2, gain = -0.6 },
		},
		nod = nil,
	},
	lotusling = {
		virtual = true,
		legs = {
			{ foot = "FootL", aim = "LegL", offset = 0 },
			{ foot = "FootR", aim = "LegR", offset = 0.5 },
		},
		duty = 0.62,
		reach = 0.9,
		lift = 0.6,
		footSwing = 0,
		crouch = 0.05,
		bob = 0.12,
		bobPeak = 0.25,
		roll = rad(2.5),
		rollPeak = 0.25,
		lean = -rad(2),
		arms = {
			{ joint = "ArmL", leg = 1, gain = -0.5 },
			{ joint = "ArmR", leg = 2, gain = -0.5 },
		},
		nod = nil,
	},
	tempestoak = {
		virtual = true,
		legs = {
			{ hip = "HipL", knee = "KneeL", ankle = "AnkleL", offset = 0 },
			{ hip = "HipR", knee = "KneeR", ankle = "AnkleR", offset = 0.5 },
		},
		duty = 0.64,
		reach = 3.2,
		lift = 2.2,
		footSwing = rad(10),
		crouch = 0.6,
		bob = 0.4,
		bobPeak = 0.31,
		roll = rad(2.2),
		rollPeak = 0.31,
		lean = -rad(2),
		arms = {
			{ joint = "ArmL", leg = 1, gain = -0.45 },
			{ joint = "ArmR", leg = 2, gain = -0.45 },
		},
		nod = nil,
	},
	thundermaw = {
		virtual = true,
		legs = {
			{ hip = "HipL", knee = "KneeL", ankle = "AnkleL", offset = 0 },
			{ hip = "HipR", knee = "KneeR", ankle = "AnkleR", offset = 0.5 },
		},
		duty = 0.6,
		reach = 3,
		lift = 2,
		footSwing = rad(12),
		crouch = 0.5,
		bob = 0.35,
		bobPeak = 0.3,
		roll = rad(1.8),
		rollPeak = 0.3,
		lean = -rad(3),
		arms = {
			{ joint = "ArmL", leg = 1, gain = -0.3 },
			{ joint = "ArmR", leg = 2, gain = -0.3 },
		},
		nod = { joint = "Neck1", amp = rad(1.5) },
	},
}

-- Below MOVING studs a second it is standing; from FULL the gait is all on.
local MOVING, FULL = 0.12, 0.5
-- Seconds: how fast the measured speed follows the motion (PlantSway moves a
-- model on a 20 Hz slice, so a frame's own travel is lumpy), how fast the share
-- of it that is a turn follows, and how fast the walk fades in and out.
local SPEED_TAU, ALONG_TAU = 0.3, 0.1
local WEIGHT_IN, WEIGHT_OUT = 0.15, 0.35
-- Under this the walk is gone: the idle alone.
local WEIGHT_GONE = 0.02
-- Seconds for the legs to become the walk's, and to go back to the idle once
-- every foot is home.
local LEGS_IN, LEGS_OUT = 0.08, 0.3
-- Standing again, a foot is home within HOME_EPS studs of its rest spot; one
-- that is not steps home, a stride every SETTLE_SECONDS.
local HOME_EPS, SETTLE_SECONDS = 0.25, 1.2
-- A planted foot further than this from under its hip (the body was carried,
-- not walked) is set down under it again.
local STRAY = 5
-- Studs in one step that are not travel: a plot rebuilt, a garden restored.
local JUMP = 4
-- A turn is stepped as this share of the arc the feet sweep: how much turning
-- one stride covers. Each foot that is down follows the turn round, so it stays
-- where it stands while the body swings above it.
local TURN_STEP = 0.75

local function smooth01(x: number): number
	local c = math.clamp(x, 0, 1)
	return c * c * (3 - 2 * c)
end

-- The pitch of a limb pointing (forward, up): zero straight down, positive
-- toward the front.
local function pitchOf(forward: number, up: number): number
	return math.atan2(forward, -up)
end

-- Every joint frame at rest, by Motor6D name, in the model's pivot frame: the
-- tree walked once with no pose at all.
local function restJoints(nodes: { Node }, order: { number }): { [string]: CFrame }
	local frames: { [number]: CFrame } = {}
	local joints: { [string]: CFrame } = {}
	for i, node in ipairs(nodes) do
		if node.parent == nil then
			frames[i] = node.rel
		end
	end
	for _, i in ipairs(order) do
		local node = nodes[i]
		local parent = node.parent
		if parent and frames[parent] then
			local p = frames[parent]
			local joint = if node.forward then p * node.c0 else p * node.c1
			frames[i] = if node.forward then joint * node.c1:Inverse() else joint * node.c0:Inverse()
			if node.motor then
				joints[node.motor] = joint
			end
		end
	end
	return joints
end

-- The node a Motor6D of this name moves (the side the tree hangs off it), or
-- nil.
local function motorChild(nodes: { Node }, name: string): number?
	for i, node in ipairs(nodes) do
		if node.motor == name then
			return i
		end
	end
	return nil
end

-- The turn that carries direction `a` onto direction `b`, about the line
-- square to both.
local function turnBetween(a: Vector3, b: Vector3): CFrame
	if a.Magnitude < 1e-6 or b.Magnitude < 1e-6 then
		return IDENTITY
	end
	local ua, ub = a.Unit, b.Unit
	local axis = ua:Cross(ub)
	local s = axis.Magnitude
	if s < 1e-6 then
		return IDENTITY
	end
	return CFrame.fromAxisAngle(axis / s, math.atan2(s, ua:Dot(ub)))
end

-- A foot's forward-and-back as the angle the arms swing against (a chain
-- leg's is its hip's own pitch).
local FOOT_SWING = rad(14)

-- The walk for a rig, or nil when its form has none or a joint it needs is not
-- there (a rig half streamed in is rebuilt when the rest arrives).
local function buildGait(form: string, nodes: { Node }, order: { number }, scale: number): Gait?
	local profile = WALKS[form]
	if not profile then
		return nil
	end
	local joints = restJoints(nodes, order)
	-- The body: the joint called Root, or (virtual) the rig's own root part,
	-- which the walk then moves with the whole tree.
	local bodyKey = if profile.virtual then BODY else "Root"
	local rootAt: Vector3
	local bodyNode: number?
	if profile.virtual then
		local top = order[1]
		if not top then
			return nil
		end
		rootAt = nodes[top].rel.Position
		bodyNode = top
	else
		local root = joints.Root
		if not root then
			return nil
		end
		rootAt = root.Position
		bodyNode = motorChild(nodes, "Root")
	end
	local legs: { Leg } = {}
	local names: { string } = { bodyKey }
	local radius = 0
	for _, spec in ipairs(profile.legs) do
		local footName = spec.foot
		if footName then
			-- A FOOT: one joint, carried to each step itself.
			local foot = joints[footName]
			local aimName = spec.aim
			local aim = if aimName then joints[aimName] else nil
			if not foot or (aimName and not aim) then
				return nil
			end
			local child = motorChild(nodes, footName)
			local parent = if child then nodes[child].parent else nil
			local a = foot.Position
			table.insert(legs, {
				hip = aimName or footName,
				knee = footName,
				ankle = footName,
				offset = spec.offset,
				hipAt = if aim then aim.Position else a,
				ankleAt = a,
				l1 = 0,
				l2 = 0,
				thigh0 = 0,
				shin0 = 0,
				bend = 1,
				walkHip = IDENTITY,
				walkKnee = IDENTITY,
				walkAnkle = IDENTITY,
				swing = 0,
				down = true,
				planted = nil,
				plantedYaw = 0,
				liftFrom = nil,
				liftYaw = 0,
				home = true,
				kind = "foot",
				foot = footName,
				aim = aimName,
				onBody = parent ~= nil and parent == bodyNode,
			})
			table.insert(names, footName)
			if aimName then
				table.insert(names, aimName)
			end
			radius += math.sqrt(a.X * a.X + a.Z * a.Z)
			continue
		end
		local hipName, kneeName, ankleName = spec.hip :: string, spec.knee :: string, spec.ankle :: string
		local hip, knee, ankle = joints[hipName], joints[kneeName], joints[ankleName]
		if not (hip and knee and ankle) then
			return nil
		end
		local h, k, a = hip.Position, knee.Position, ankle.Position
		local thigh, shin, reach = k - h, a - k, a - h
		local thigh0 = pitchOf(-thigh.Z, thigh.Y)
		local shin0 = pitchOf(-shin.Z, shin.Y)
		local toAnkle = pitchOf(-reach.Z, reach.Y)
		table.insert(legs, {
			hip = hipName,
			knee = kneeName,
			ankle = ankleName,
			offset = spec.offset,
			hipAt = h,
			ankleAt = a,
			l1 = math.sqrt(thigh.Y * thigh.Y + thigh.Z * thigh.Z),
			l2 = math.sqrt(shin.Y * shin.Y + shin.Z * shin.Z),
			thigh0 = thigh0,
			shin0 = shin0,
			-- The side of the hip-to-ankle line the knee is authored on, kept
			-- whatever the stride asks of it.
			bend = if thigh0 >= toAnkle then 1 else -1,
			walkHip = IDENTITY,
			walkKnee = IDENTITY,
			walkAnkle = IDENTITY,
			swing = 0,
			down = true,
			planted = nil,
			plantedYaw = 0,
			liftFrom = nil,
			liftYaw = 0,
			home = true,
			kind = "chain",
			foot = nil,
			aim = nil,
			onBody = true,
		})
		table.insert(names, hipName)
		table.insert(names, kneeName)
		table.insert(names, ankleName)
		radius += math.sqrt(a.X * a.X + a.Z * a.Z)
	end
	return {
		profile = profile,
		legs = legs,
		bodyKey = bodyKey,
		scale = scale,
		joints = names,
		rootAt = rootAt,
		turnRadius = radius / math.max(#legs, 1),
		stride = 2 * profile.reach * scale / profile.duty,
		phase = 0,
		weight = 0,
		legWeight = 0,
		settling = false,
		moving = false,
		speed = 0,
		along = 1,
		turnDir = 0,
		dirX = 0,
		dirZ = -1,
		lastPos = nil,
		lastYaw = nil,
		lastT = nil,
		lastMoveT = nil,
	}
end

-- Hip and knee for a leg whose ankle must reach (forward, up) from its hip, in
-- the plane it swings in: the two-bone solution on the authored side.
local function solve(leg: Leg, forward: number, up: number): (number, number)
	local l1, l2 = leg.l1, leg.l2
	local d = math.clamp(math.sqrt(forward * forward + up * up), math.abs(l1 - l2) + 1e-3, l1 + l2 - 1e-3)
	local cosA = (l1 * l1 + d * d - l2 * l2) / (2 * l1 * d)
	local thigh = pitchOf(forward, up) + leg.bend * math.acos(math.clamp(cosA, -1, 1))
	local kneeF, kneeU = l1 * sin(thigh), -l1 * cos(thigh)
	return thigh, pitchOf(forward - kneeF, up - kneeU)
end

-- How far the model has travelled since the last frame -- moving, and turning
-- -- turned into steps, and how much of the walk shows.
local function stepGait(rig: Rig, gait: Gait, now: number)
	local dt = if gait.lastT then math.clamp(now - gait.lastT, 0, 0.5) else 0
	gait.lastT = now
	local target = 0
	if rig.walks then
		local pivot = rig.model:GetPivot()
		local pos = pivot.Position
		local look = pivot.LookVector
		local yaw = math.atan2(look.X, look.Z)
		local last, lastYaw = gait.lastPos, gait.lastYaw
		gait.lastPos, gait.lastYaw = pos, yaw
		if last and lastYaw and dt > 0 then
			local moved = Vector3.new(pos.X - last.X, 0, pos.Z - last.Z).Magnitude
			if moved > JUMP then
				-- Moved, not walked: every foot is set down where it now stands.
				for _, leg in ipairs(gait.legs) do
					leg.planted, leg.liftFrom = nil, nil
				end
			else
				local dyaw = (yaw - lastYaw + pi) % (2 * pi) - pi
				local turned = math.abs(dyaw) * gait.turnRadius * TURN_STEP
				local travel = moved + turned
				gait.speed += (travel / dt - gait.speed) * (1 - exp(-dt / SPEED_TAU))
				if travel > 1e-5 then
					-- By the time since the model last MOVED: PlantSway moves it on a
					-- slice, so most frames carry no travel at all.
					local since = if gait.lastMoveT then now - gait.lastMoveT else 1
					gait.lastMoveT = now
					local k = 1 - exp(-math.max(since, dt) / ALONG_TAU)
					gait.along += (moved / travel - gait.along) * k
					if math.abs(dyaw) > 1e-6 then
						gait.turnDir += ((if dyaw > 0 then 1 else -1) - gait.turnDir) * k
					end
					if moved > 1e-6 then
						local here = pivot.Rotation:Inverse() * Vector3.new(pos.X - last.X, 0, pos.Z - last.Z)
						local x = gait.dirX + (here.X / moved - gait.dirX) * k
						local z = gait.dirZ + (here.Z / moved - gait.dirZ) * k
						local length = math.sqrt(x * x + z * z)
						if length > 1e-4 then
							gait.dirX, gait.dirZ = x / length, z / length
						end
					end
					gait.phase = (gait.phase + travel / gait.stride) % 1
				end
			end
		end
		target = smooth01((gait.speed - MOVING) / (FULL - MOVING))
		if target > 0 then
			if not gait.moving then
				-- SETTING OFF from standing, every foot home under its hip: the
				-- stride starts where that is true -- the feet that are down near
				-- the middle of their step, the rest lifting -- so no foot is left
				-- planted at rest for a whole stride while the body goes on.
				local home = true
				for _, leg in ipairs(gait.legs) do
					home = home and leg.home
				end
				if home then
					local p = gait.profile
					local best, cost = gait.phase, math.huge
					for i = 0, 39 do
						local phase = i / 40
						local worst = 0
						for _, leg in ipairs(gait.legs) do
							local u = (phase + leg.offset) % 1
							if u < p.duty then
								worst = math.max(worst, math.abs(1 - 2 * u / p.duty))
							end
						end
						if worst < cost then
							best, cost = phase, worst
						end
					end
					gait.phase = best
					-- Every foot is where the walk wants it (under its hip), so the
					-- legs are the walk's at once: a fade here would let the body
					-- carry half-planted feet round with it.
					gait.legWeight = 1
				end
				gait.moving = true
			end
			gait.settling = false
			for _, leg in ipairs(gait.legs) do
				leg.home = false
			end
		else
			gait.moving = false
			-- Standing again: a foot not back under the body steps home first, so
			-- the idle gets its legs back without a foot sliding across the soil.
			local toPivot = pivot:Inverse()
			local away = false
			for _, leg in ipairs(gait.legs) do
				if not leg.home then
					local at = if leg.down and leg.planted then toPivot * leg.planted else nil
					if not gait.settling and at
						and Vector3.new(at.X - leg.ankleAt.X, 0, at.Z - leg.ankleAt.Z).Magnitude < HOME_EPS * gait.scale
					then
						leg.home = true
					else
						away = true
					end
				end
			end
			gait.settling = away
			if away then
				gait.phase = (gait.phase + dt / SETTLE_SECONDS) % 1
			end
		end
	else
		gait.lastPos, gait.lastYaw = nil, nil
		gait.speed = 0
		gait.settling = false
		gait.moving = false
		for _, leg in ipairs(gait.legs) do
			leg.planted, leg.liftFrom, leg.down, leg.home = nil, nil, true, true
		end
	end
	if dt > 0 then
		local tau = if target > gait.weight then WEIGHT_IN else WEIGHT_OUT
		gait.weight += (target - gait.weight) * (1 - exp(-dt / tau))
		local legsWanted = if rig.walks and (target > 0 or gait.settling) then 1 else 0
		local legTau = if legsWanted > gait.legWeight then LEGS_IN else LEGS_OUT
		gait.legWeight += (legsWanted - gait.legWeight) * (1 - exp(-dt / legTau))
	end
	if target == 0 and gait.weight < WEIGHT_GONE then
		gait.weight = 0
	end
	if target == 0 and not gait.settling and gait.legWeight < WEIGHT_GONE then
		gait.legWeight = 0
	end
end

-- The walk's pose for this frame, laid over the idle's: the body by the walk's
-- weight, the legs by their own.
local function walkPose(rig: Rig, gait: Gait)
	local w, lw = gait.weight, gait.legWeight
	if w <= 0 and lw <= 0 then
		return
	end
	local p = gait.profile
	local phase = gait.phase
	local pose = rig.pose
	-- THE BODY: it settles, rises over each standing leg and dips between them,
	-- and leans into the walk.
	local scale = gait.scale
	local bob = (p.bob * cos(4 * pi * (phase - p.bobPeak)) - p.crouch) * scale
	local roll = -p.roll * cos(2 * pi * (phase - p.rollPeak))
	local lean = p.lean * gait.along
	local key = gait.bodyKey
	local body = (pose[key] or IDENTITY):Lerp(CFrame.new(0, bob, 0) * CFrame.Angles(lean, 0, roll), w)
	pose[key] = body
	if lw > 0 then
		--======================================================================
		-- THE LEGS, SQUARE TO THE WORLD
		--
		-- Each hip undoes whatever the body above it is doing, so a leg hangs in
		-- the model's own frame and only reaches. A foot that is DOWN is held at
		-- the spot in the world where it touched down, however the body moves or
		-- turns above it; a foot that is UP arcs from where it left to where it
		-- lands -- ahead along the way the body is going and round the way it is
		-- turning, or back under the body while it settles.
		--======================================================================
		local unbody = body.Rotation:Inverse()
		local moved = CFrame.new(gait.rootAt) * body * CFrame.new(-gait.rootAt)
		local pivot = rig.model:GetPivot()
		local toPivot = pivot:Inverse()
		local look = pivot.LookVector
		local yaw = math.atan2(look.X, look.Z)
		local reachFull = p.reach * scale
		local reach = reachFull * gait.along
		local half = 0.5 * gait.turnDir * (1 - gait.along) * p.duty * gait.stride / (gait.turnRadius * TURN_STEP)
		local ch, sh = cos(half), sin(half)
		for _, leg in ipairs(gait.legs) do
			local rest = leg.ankleAt
			local landing, landingYaw = rest, 0
			if not gait.settling then
				landing = Vector3.new(rest.X * ch + rest.Z * sh + gait.dirX * reach, rest.Y,
					-rest.X * sh + rest.Z * ch + gait.dirZ * reach)
				landingYaw = half
			end
			local u = (phase + leg.offset) % 1
			local goal: Vector3
			local footYaw, footPitch = 0, 0
			if u < p.duty or (gait.settling and leg.home) then
				if not leg.planted then
					-- Found standing (a fresh walk): where it is. Touching down: where
					-- it was carried to.
					local spot = if leg.down then rest else landing
					leg.planted = pivot * spot
					leg.plantedYaw = yaw + (if leg.down then 0 else landingYaw)
					if not leg.down and gait.settling then
						leg.home = true
					end
				end
				leg.down = true
				goal = toPivot * (leg.planted :: Vector3)
				footYaw = (leg.plantedYaw - yaw + pi) % (2 * pi) - pi
				if Vector3.new(goal.X - rest.X, 0, goal.Z - rest.Z).Magnitude > STRAY * scale then
					leg.planted = pivot * landing
					leg.plantedYaw = yaw + landingYaw
					goal, footYaw = landing, landingYaw
				end
			else
				if leg.down then
					leg.liftFrom = leg.planted or (pivot * rest)
					leg.liftYaw = if leg.planted then leg.plantedYaw else yaw
					leg.planted = nil
				end
				leg.down = false
				local s = (u - p.duty) / (1 - p.duty)
				local e = smooth01(s)
				local from = leg.liftFrom or (pivot * rest)
				goal = toPivot * from:Lerp(pivot * landing, e) + Vector3.new(0, p.lift * scale * sin(pi * s), 0)
				footPitch = p.footSwing * sin(pi * s)
				local fromYaw = (leg.liftYaw - yaw + pi) % (2 * pi) - pi
				footYaw = fromYaw + (landingYaw - fromYaw) * e
			end
			if leg.kind == "foot" then
				--==============================================================
				-- A FOOT IS CARRIED, NOT SOLVED: its joint's pose is exactly the
				-- move from where it rests to the goal -- from under the body when
				-- it hangs off the body (so the body's bob and lean are undone),
				-- straight off the base otherwise -- flat on the soil, keeping its
				-- own heading. The limb that aims at it turns to follow.
				--==============================================================
				local frame = if leg.onBody then moved * CFrame.new(rest) else CFrame.new(rest)
				leg.walkAnkle = frame:Inverse() * CFrame.new(goal) * CFrame.Angles(0, footYaw, 0)
					* CFrame.Angles(footPitch, 0, 0)
				leg.swing = math.clamp((rest.Z - goal.Z) / math.max(reachFull, 1e-3), -1, 1) * FOOT_SWING
				local footName = leg.foot :: string
				pose[footName] = (pose[footName] or IDENTITY):Lerp(leg.walkAnkle, lw)
				local aimName = leg.aim
				if aimName then
					local toward = (if leg.onBody then moved:Inverse() * goal else goal) - leg.hipAt
					leg.walkHip = turnBetween(rest - leg.hipAt, toward)
					pose[aimName] = (pose[aimName] or IDENTITY):Lerp(leg.walkHip, lw)
				end
				continue
			end
			local rel = goal - moved * leg.hipAt
			-- Sideways, exactly: a pitch never changes how far out the ankle stands
			-- from the hip (`out`, the authored splay), so the hip's roll is the turn
			-- that carries (out, down) onto the goal's (across, down), and the stride
			-- is solved in the leg's own plane at that `down`.
			local out = rest.X - leg.hipAt.X
			local down = -math.sqrt(math.max(rel.X * rel.X + rel.Y * rel.Y - out * out, 1e-4))
			local side = (math.atan2(rel.Y, rel.X) - math.atan2(down, out) + pi) % (2 * pi) - pi
			local thigh, shin = solve(leg, -rel.Z, down)
			local hip = thigh - leg.thigh0
			local knee = shin - leg.shin0
			leg.walkHip = unbody * CFrame.Angles(0, 0, side) * CFrame.Angles(hip, 0, 0)
			leg.walkKnee = CFrame.Angles(knee - hip, 0, 0)
			-- Flat on the soil, keeping its own heading: exactly the turn from where
			-- the shin now points to the foot's wanted pose. Every joint frame is
			-- square at rest.
			leg.walkAnkle = CFrame.Angles(-knee, 0, 0) * CFrame.Angles(0, 0, -side) * CFrame.Angles(0, footYaw, 0)
				* CFrame.Angles(footPitch, 0, 0)
			leg.swing = hip
			pose[leg.hip] = (pose[leg.hip] or IDENTITY):Lerp(leg.walkHip, lw)
			pose[leg.knee] = (pose[leg.knee] or IDENTITY):Lerp(leg.walkKnee, lw)
			pose[leg.ankle] = (pose[leg.ankle] or IDENTITY):Lerp(leg.walkAnkle, lw)
		end
	end
	for _, arm in ipairs(p.arms) do
		local leg = gait.legs[arm.leg]
		if leg then
			pose[arm.joint] = (pose[arm.joint] or IDENTITY) * CFrame.Angles(arm.gain * leg.swing * w, 0, 0)
		end
	end
	local nod = p.nod
	if nod then
		pose[nod.joint] = (pose[nod.joint] or IDENTITY) * CFrame.Angles(nod.amp * w * cos(4 * pi * phase), 0, 0)
	end
end

--==============================================================================
-- WHAT A RAIN FORM'S IDLE TOUCHES BESIDES ITS JOINTS (2026-10-02)
--
-- The parts it sizes or flickers, by name; the emitters and lights it fires
-- and pulses, by name. Every size is the AUTHORED one -- a drop's BaseSize, or
-- the size this copy had when it was first seen, kept on the part (this
-- client's own attribute), so a rig rebuilt mid-swell does not take a swollen
-- drop for its rest.
--==============================================================================
local RAIN_PARTS: { [string]: boolean } = {
	Eye = true, FrillDrop = true, LeafDrop = true, PetalDrop = true, Ripple = true, StormCore = true,
	CloudVein = true, ArcBolt = true, StrikeBolt = true, ManeVein = true,
}
local REST_SIZE = "SeedRestSize"

function scanRain(rig: Rig, model: Model, parts: { BasePart })
	for _, part in ipairs(parts) do
		if RAIN_PARTS[part.Name] then
			local list = rig.named[part.Name]
			if not list then
				list = {}
				rig.named[part.Name] = list
			end
			table.insert(list, part)
			local base = part:GetAttribute("BaseSize")
			local seen = part:GetAttribute(REST_SIZE)
			if typeof(seen) ~= "Vector3" then
				seen = part.Size
				part:SetAttribute(REST_SIZE, seen)
			end
			rig.rest[part] = if typeof(base) == "Vector3" then base else seen :: Vector3
			rig.phases[part] = tonumber(part:GetAttribute("Phase")) or 0
		end
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ParticleEmitter") and not rig.emitters[d.Name] then
			rig.emitters[d.Name] = d
		elseif d:IsA("PointLight") and not rig.lights[d.Name] then
			rig.lights[d.Name] = d
			local base = d:GetAttribute(REST_SIZE)
			if type(base) ~= "number" then
				base = d.Brightness
				d:SetAttribute(REST_SIZE, base)
			end
			rig.lightRest[d] = base :: number
		end
	end
end

--==============================================================================
-- THE TREE
--==============================================================================
function SecretIdle.Rig(model: Model): Rig?
	local pivotPart = model.PrimaryPart
	if not pivotPart then
		return nil
	end
	local pivot = model:GetPivot()
	local parts: { BasePart } = {}
	local index: { [BasePart]: number } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
			index[d] = #parts
		end
	end
	local nodes: { Node } = table.create(#parts)
	for i, part in ipairs(parts) do
		nodes[i] = { part = part, parent = nil, forward = true, c0 = IDENTITY, c1 = IDENTITY, motor = nil,
			rel = pivot:ToObjectSpace(part.CFrame) }
	end
	-- Every joint, as an edge both ways.
	type Edge = { other: number, joint: Instance, forward: boolean }
	local edges: { [number]: { Edge } } = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Motor6D") or d:IsA("Weld") then
			local j = d :: any
			local a, b = index[j.Part0], index[j.Part1]
			if a and b and a ~= b then
				edges[a] = edges[a] or {}
				edges[b] = edges[b] or {}
				table.insert(edges[a], { other = b, joint = d, forward = true })
				table.insert(edges[b], { other = a, joint = d, forward = false })
			end
		end
	end
	-- Breadth first from the AUTHORED ROOT: the part SecretModel marked RigRoot
	-- (2026-10-02 -- a client's GetDescendants order is replication's, and in
	-- Play the first jointed part was a Tempestoak's antler), else the authored
	-- Footing (the part the Root motor hangs off), else the first jointed part.
	local root: number? = nil
	for i, part in ipairs(parts) do
		if part:GetAttribute("RigRoot") == true then
			root = i
			break
		end
	end
	if not root then
		for i, part in ipairs(parts) do
			if part.Name == "Footing" then
				root = i
				break
			end
		end
	end
	if not root then
		for i in ipairs(parts) do
			if edges[i] then
				root = i
				break
			end
		end
	end
	local order: { number } = {}
	if root then
		local seen: { [number]: boolean } = { [root] = true }
		local queue = { root }
		local head = 1
		while head <= #queue do
			local at = queue[head]
			head += 1
			table.insert(order, at)
			for _, edge in ipairs(edges[at] or {}) do
				if not seen[edge.other] then
					seen[edge.other] = true
					local node = nodes[edge.other]
					local j = edge.joint :: any
					node.parent = at
					node.forward = edge.forward
					node.c0 = j.C0
					node.c1 = j.C1
					node.motor = if edge.joint:IsA("Motor6D") then edge.joint.Name else nil
					table.insert(queue, edge.other)
				end
			end
		end
	end
	-- A Rain form plays its Pod 1 creature's idle and walk; a Pod 2 form at its
	-- own size over that one's (every Pod 2 form is its Pod 1 form scaled
	-- whole, so one ratio is the lot).
	local form = tostring(model:GetAttribute("SecretForm"))
	local idleKey, scale = form, 1
	if RainForms.Plants[form] then
		local base = string.gsub(form, "_colossal$", "")
		local small, big = RainForms.Plants[base], RainForms.Plants[form]
		if base ~= form and small and big and small.Size.Y > 0 then
			scale = big.Size.Y / small.Size.Y
		end
		idleKey = base
	end
	local profile = WALKS[idleKey]
	local top = order[1]
	local rig: Rig = {
		model = model,
		form = form,
		nodes = nodes,
		order = order,
		pose = {},
		-- Two of the same plant in one bed should not breathe in lockstep: a
		-- phase off the placement id, or the spot, spreads them out.
		phase = 0,
		stopped = false,
		lastSnap = -1,
		irises = {},
		eyes = {},
		unit = tonumber(model:GetAttribute("Unit")) or 1,
		gait = nil,
		walks = false,
		idle = idleKey,
		scale = scale,
		rootNode = top,
		bodyAt = if profile and profile.virtual and top then nodes[top].rel.Position else nil,
		named = {},
		rest = {},
		phases = {},
		emitters = {},
		lights = {},
		lightRest = {},
		lastEvent = -1,
	}
	rig.gait = buildGait(idleKey, nodes, order, scale)
	local seed = tonumber(model:GetAttribute("PlacementId"))
		or math.floor(math.abs(pivot.Position.X * 13 + pivot.Position.Z * 7))
	rig.phase = (seed % 97) / 97 * 10
	for _, part in ipairs(parts) do
		if part.Name == "Gullet" then
			rig.gullet = part
			local base = part:GetAttribute("BaseSize")
			rig.gulletSize = if typeof(base) == "Vector3" then base else part.Size
			local light = part:FindFirstChild("GulletLight")
			if light and light:IsA("PointLight") then
				rig.light = light
				rig.lightBase = tonumber(light:GetAttribute("BaseBrightness")) or light.Brightness
			end
			local spores = part:FindFirstChild("Spores")
			if spores and spores:IsA("ParticleEmitter") then
				rig.spores = spores
			end
		elseif part.Name == "Iris" then
			table.insert(rig.irises, { part = part, size = part.Size })
		elseif part.Name == "Eye" then
			table.insert(rig.eyes, { part = part, size = part.Size })
		elseif part.Name == "Bud" then
			rig.bud = part
			local hot = part:GetAttribute("HotColor")
			local base = part:GetAttribute("BaseColor")
			if typeof(hot) == "Color3" then
				rig.budHot = hot
				rig.budBase = if typeof(base) == "Color3" then base else part.Color
			end
		end
	end
	if RainForms.Plants[form] then
		scanRain(rig, model, parts)
	end
	return rig
end

--==============================================================================
-- THE TWO IDLES, AS WRITTEN
--==============================================================================
local function set(rig: Rig, name: string, cf: CFrame)
	rig.pose[name] = cf
end

-- Snarlbloom's jaw: a slow breath, and every 6 s a wide gape that snaps shut.
local PERIOD = 6
local function jawAt(t: number): (number, number, number, boolean)
	local breath = 6 * (1 - cos(t * 2 * pi / 3.4)) / 2
	local cycle = math.floor(t / PERIOD)
	local k = t - cycle * PERIOD
	if k < 0.6 then
		return math.max(breath, 28 * sin(k / 0.6 * pi / 2)), 0, cycle, false
	elseif k < 0.7 then
		return 28 * (1 - (k - 0.6) / 0.1), 0, cycle, false
	elseif k < 1.5 then
		return breath * (k - 0.7) / 0.8, exp(-(k - 0.7) * 5), cycle, true
	end
	return breath, 0, cycle, false
end

local function snarlbloom(rig: Rig, t: number)
	local breath = wave(t, 3.4)
	-- weight shifts side to side; the hips lean back so the legs stay put
	local shift = rad(2.2) * wave(t, 4.0)
	set(rig, "Root", CFrame.Angles(0, 0, shift))
	set(rig, "HipL", CFrame.Angles(0, 0, -shift))
	set(rig, "HipR", CFrame.Angles(0, 0, -shift))
	set(rig, "Waist", CFrame.Angles(rad(2) * breath, rad(4) * wave(t, 7.0), -shift * 0.6))
	set(rig, "Neck", CFrame.Angles(rad(-2) * breath, rad(10) * wave(t, 7.0, 0.8), shift * 0.4))
	-- the jaw
	local open, flare, cycle, snapped = jawAt(t)
	set(rig, "UpperJaw", CFrame.Angles(rad(open), 0, 0))
	set(rig, "LowerJaw", CFrame.Angles(-rad(open) * 0.4, 0, 0))
	if snapped and cycle ~= rig.lastSnap then
		rig.lastSnap = cycle
		local spores = rig.spores
		if spores then
			pcall(function()
				spores:Emit(14)
			end)
		end
	end
	local gullet, gulletSize = rig.gullet, rig.gulletSize
	if gullet and gulletSize then
		gullet.Size = gulletSize * (1 + 0.5 * flare)
	end
	local light, lightBase = rig.light, rig.lightBase
	if light and lightBase then
		light.Brightness = lightBase * (0.9 + 0.15 * breath + 2 * flare)
	end
	-- the eye stalks wobble and look around, one a little after the other
	local look = wave(t, 5.5)
	set(rig, "EyeL", CFrame.Angles(rad(8) * wave(t, 2.1), rad(25) * look, rad(-6) * wave(t, 3.3)))
	set(rig, "EyeR", CFrame.Angles(rad(8) * wave(t, 2.1, 0.7), rad(25) * wave(t, 5.5, 0.5), rad(6) * wave(t, 3.3, 0.9)))
	-- the arms sway, the leaf blades a little after
	for i, side in ipairs({ "L", "R" }) do
		local lag = (i - 1) * 1.2
		set(rig, "Shoulder" .. side, CFrame.Angles(rad(6) * wave(t, 3.4, lag), 0, 0))
		set(rig, "Elbow" .. side, CFrame.Angles(rad(8) * wave(t, 3.4, lag + 0.6), 0, 0))
	end
	-- the back vines curl
	for i, side in ipairs({ "L", "R" }) do
		local lag = (i - 1) * 1.6
		set(rig, "Vine" .. side .. "1", CFrame.Angles(rad(8) * wave(t, 2.8, lag), 0, rad(6) * wave(t, 3.9, lag)))
		set(rig, "Vine" .. side .. "2", CFrame.Angles(rad(14) * wave(t, 2.8, lag + 0.7), 0, rad(8) * wave(t, 3.9, lag + 0.7)))
	end
	-- a blink every few seconds
	local lid = if (t % 3.6) < 0.13 then 0.15 else 1
	for _, e in ipairs(rig.irises) do
		e.part.Size = Vector3.new(e.size.X, e.size.Y * lid, e.size.Z)
	end
end

local HIPS = { "HipFL", "HipFR", "HipBL", "HipBR" }
local NODS = { 4, -3, 3 }

local function petalfawn(rig: Rig, t: number)
	local breath = wave(t, 3.2)
	-- the body leans with each breath; the hips lean back so the legs stay put
	set(rig, "Root", CFrame.Angles(rad(1.2) * breath, 0, 0))
	for _, hip in ipairs(HIPS) do
		set(rig, hip, CFrame.Angles(-rad(1.2) * breath, 0, 0))
	end
	-- the neck sways in an S, each joint a little after the one below
	for i = 1, 3 do
		local nod = NODS[i]
		set(rig, "Neck" .. i, CFrame.Angles(rad(nod) * wave(t, 3.2, i * 0.6 - 0.6), 0, rad(2.5) * wave(t, 4.4, i * 0.6 - 0.6)))
	end
	-- the head lingers looking one way, then turns slowly to the other
	local look = wave(t, 9)
	look = look * look * look
	set(rig, "Head", CFrame.Angles(rad(-3) * breath, rad(28) * look, rad(6) * wave(t, 5.3)))
	-- the crown petals open and close together
	local open = wave(t, 2.6)
	set(rig, "BackPetal", CFrame.Angles(rad(5) * open, 0, 0))
	set(rig, "FrontPetal", CFrame.Angles(-rad(5) * open, 0, 0))
	set(rig, "BudJoint", CFrame.new(0, 0.012 * rig.unit * wave(t, 2.6, 0.8), 0) * CFrame.Angles(0, t * 0.9, 0))
	-- the ears flick now and then
	local flick = t % 3.7
	local twitch = if flick < 0.25 then sin(flick / 0.25 * pi) else 0
	set(rig, "EarL", CFrame.Angles(rad(10) * twitch, rad(-6) * breath, 0))
	set(rig, "EarR", CFrame.Angles(rad(10) * twitch * 0.6, rad(6) * breath, 0))
	-- every 7 seconds the front left hoof lifts and taps the ground
	local k = t % 7
	if k < 0.7 then
		local lift = sin(k / 0.7 * pi)
		set(rig, "HipFL", CFrame.Angles(rad(12) * lift - rad(1.2) * breath, 0, 0))
		set(rig, "KneeFL", CFrame.Angles(-rad(26) * lift, 0, 0))
		set(rig, "AnkleFL", CFrame.Angles(rad(14) * lift, 0, 0))
	else
		set(rig, "KneeFL", IDENTITY)
		set(rig, "AnkleFL", IDENTITY)
	end
	-- the tail petals wave, one after another
	for i = 1, 5 do
		set(rig, "Tail" .. i, CFrame.Angles(rad(6) * wave(t, 2.2, i * 0.5), 0, rad(5) * wave(t, 3.1, i * 0.7)))
	end
	-- a blink every few seconds
	local lid = if (t % 4.2) < 0.14 then 0.15 else 1
	for _, e in ipairs(rig.eyes) do
		e.part.Size = Vector3.new(e.size.X, e.size.Y * lid, e.size.Z)
	end
	-- the bud glows hot and back: the inserted script tweened BaseColor to
	-- HotColor over 1.6 s, Sine InOut, reversing forever -- a 3.2 s cosine.
	local bud, base, hot = rig.bud, rig.budBase, rig.budHot
	if bud and base and hot then
		bud.Color = base:Lerp(hot, 0.5 - 0.5 * cos(t * 2 * pi / 3.2))
	end
end

--==============================================================================
-- THE RAIN EVENT'S FIVE IDLES, AS WRITTEN (2026-10-02)
--
-- PuddlepodIdle, DrizzletIdle, LotuslingIdle, TempestoakIdle and ThundermawIdle
-- as the owner's scripts played them: the same joints, periods and lags, the
-- sip, shake, bloom and roars on their own clocks, the blinks, drops, ripples,
-- veins, bolts, lights and bursts. `u` is the scripts' `unit` at this form's
-- size (a Pod 2 form's distances grow with it).
--==============================================================================
local function burst(rig: Rig, name: string, n: number)
	local e = rig.emitters[name]
	if e then
		pcall(function()
			e:Emit(n)
		end)
	end
end

local function glow(rig: Rig, name: string, factor: number)
	local light = rig.lights[name]
	if light then
		light.Brightness = (rig.lightRest[light] or light.Brightness) * factor
	end
end

local function blinkEyes(rig: Rig, t: number, period: number)
	local lid = if (t % period) < 0.12 then 0.15 else 1
	for _, part in ipairs(rig.named.Eye or {}) do
		local size = rig.rest[part]
		if size then
			part.Size = Vector3.new(size.X, size.Y * lid, size.Z)
		end
	end
end

-- Drops that swell and fall on a 2.6 s cycle, each at its own phase.
local function swellDrops(rig: Rig, name: string, t: number)
	for _, part in ipairs(rig.named[name] or {}) do
		local size = rig.rest[part]
		if size then
			local g = ((t + (rig.phases[part] or 0)) % 2.6) / 2.6
			part.Size = size * (0.55 + 0.6 * g)
		end
	end
end

local function flicker(rig: Rig, name: string, t: number, above: number, held: boolean)
	for _, part in ipairs(rig.named[name] or {}) do
		local on = sin(t * 23 + (rig.phases[part] or 0) * 7) > above or held
		part.Transparency = if on then 0 else 0.65
	end
end

local FRILL = { 45, 135, 225, 315 }

local function puddlepod(rig: Rig, t: number)
	local u = rig.unit * rig.scale
	-- the sip: lean back, lid wide, then settle (0 to 1 and back over 1.6 s)
	local k = t % 8
	local sip = if k < 1.6 then sin(k / 1.6 * pi) else 0
	local cycle = math.floor(t / 8)
	if k > 0.8 and k < 1.2 and cycle ~= rig.lastEvent then
		rig.lastEvent = cycle
		burst(rig, "Splash", 12)
	end
	-- the cup bobs; the feet stay where they are
	local bob = 0.01 * u * (1 - cos(t * 2 * pi / 2.4)) / 2
	set(rig, "Root", CFrame.new(0, bob, 0) * CFrame.Angles(rad(2) * wave(t, 3.3) + rad(9) * sip, 0, rad(2) * wave(t, 4.3)))
	set(rig, "Lid", CFrame.Angles(rad(3) * wave(t, 2.9) + rad(26) * sip, 0, rad(2) * wave(t, 4.1, 0.6)))
	set(rig, "Dew", CFrame.Angles(rad(10) * wave(t, 2.2, 0.4) + rad(20) * sip, 0, rad(10) * wave(t, 3.1)))
	set(rig, "Water", CFrame.new(0, 0.004 * u * wave(t, 1.7), 0)
		* CFrame.Angles(rad(4) * wave(t, 1.3) + rad(10) * sip * wave(t, 0.5), 0, rad(4) * wave(t, 1.9, 1)))
	for i, deg in ipairs(FRILL) do
		local a = rad(deg)
		local tilt = rad(6) * wave(t, 2.5, i * 1.3) + rad(10) * sip
		set(rig, "Frill" .. i, CFrame.fromAxisAngle(Vector3.new(-sin(a), 0, cos(a)), tilt))
	end
	swellDrops(rig, "FrillDrop", t)
	-- the arms sway; every 11 s the left arm waves
	local w = t % 11
	local hello = if w < 1.4 then sin(w / 1.4 * pi) else 0
	set(rig, "ArmL", CFrame.Angles(rad(7) * wave(t, 2.6), 0, rad(7) * wave(t, 3.4, 0.7) + rad(60) * hello))
	set(rig, "HandL", CFrame.Angles(rad(14) * wave(t, 2.0, 0.6), 0, rad(30) * hello * sin(t * 16)))
	set(rig, "ArmR", CFrame.Angles(rad(7) * wave(t, 2.6, 1.3), 0, rad(7) * wave(t, 3.4, 2.0)))
	set(rig, "HandR", CFrame.Angles(rad(14) * wave(t, 2.0, 1.4), 0, 0))
	set(rig, "FootL", IDENTITY)
	set(rig, "FootR", IDENTITY)
	-- the vine tail ripples, each piece a little behind the one before
	set(rig, "Tail1", CFrame.Angles(rad(8) * wave(t, 2.2), rad(10) * wave(t, 3.1), 0))
	set(rig, "Tail2", CFrame.Angles(rad(10) * wave(t, 2.2, 0.7), rad(12) * wave(t, 3.1, 0.8), 0))
	set(rig, "Tail3", CFrame.Angles(rad(12) * wave(t, 2.2, 1.4), rad(14) * wave(t, 3.1, 1.6), 0))
	-- two ripples spread out from the feet and fade, half a cycle apart
	for i, part in ipairs(rig.named.Ripple or {}) do
		local size = rig.rest[part]
		if size then
			local p = ((t / 2.6) + (i - 1) * 0.5) % 1
			local d = (0.25 + 0.65 * p) * u
			part.Size = Vector3.new(size.X, d, d)
			part.Transparency = 0.4 + 0.6 * p
		end
	end
	blinkEyes(rig, t, 3.9)
end

local function drizzlet(rig: Rig, t: number)
	local u = rig.unit * rig.scale
	-- the shake: a quick wiggle that dies away, with a spray off the leaf
	local k = t % 7
	local shake = if k < 0.7 then sin(k * 2 * pi * 6) * exp(-k * 4) else 0
	local cycle = math.floor(t / 7)
	if k < 0.7 and cycle ~= rig.lastEvent then
		rig.lastEvent = cycle
		burst(rig, "Splash", 14)
	end
	-- the body bobs; the feet stay where they are
	local bob = 0.012 * u * (1 - cos(t * 2 * pi / 2.2)) / 2
	set(rig, "Root", CFrame.new(0, bob, 0)
		* CFrame.Angles(rad(2) * wave(t, 3.1), rad(16) * shake, rad(2) * wave(t, 4.3) + rad(6) * shake))
	set(rig, "Umbrella", CFrame.Angles(rad(4) * wave(t, 3.3, 0.5), 0, rad(4) * wave(t, 4.1, 0.9) - rad(8) * shake))
	set(rig, "Canopy", CFrame.Angles(0, t * 0.3, 0))
	for i = 1, 6 do
		local rainTap = rad(3) * math.max(0, sin(t * 7.3 + i * 1.7)) ^ 4
		set(rig, "Blade" .. i, CFrame.Angles(rainTap + rad(10) * shake * sin(i), 0, 0))
	end
	swellDrops(rig, "LeafDrop", t)
	-- the cloud bobs and drifts
	set(rig, "Cloud", CFrame.new(0.02 * u * wave(t, 6.0), 0.02 * u * wave(t, 2.8), 0.02 * u * wave(t, 6.0, pi / 2))
		* CFrame.Angles(0, rad(6) * wave(t, 7.0), rad(3) * wave(t, 3.7)))
	-- the arms sway; every 9 s the left arm waves
	local w = t % 9
	local hello = if w < 1.2 then sin(w / 1.2 * pi) else 0
	set(rig, "ArmL", CFrame.Angles(rad(6) * wave(t, 2.6), 0, rad(50) * hello + rad(12) * hello * sin(t * 18)))
	set(rig, "ArmR", CFrame.Angles(rad(6) * wave(t, 2.6, 1.3), 0, 0))
	set(rig, "FootL", IDENTITY)
	set(rig, "FootR", IDENTITY)
	set(rig, "BackLeaf", CFrame.Angles(rad(8) * wave(t, 2.4) + rad(14) * shake, 0, rad(5) * wave(t, 3.5)))
	set(rig, "TailDrip", CFrame.Angles(rad(6) * wave(t, 1.9), 0, rad(10) * shake))
	blinkEyes(rig, t, 3.7)
end

local OUTER = { 0, 45, 90, 135, 180, 225, 270, 315 }
local INNER = { 30, 90, 150, 210, 270, 330 }
local MOTE_SPEED = { 0.9, -0.7, 0.55 }

local function lotusling(rig: Rig, t: number)
	local u = rig.unit * rig.scale
	-- the bloom: 0 to 1 and back over 3 s, once every 10 s
	local k = t % 10
	local bloom = if k < 3 then sin(k / 3 * pi) else 0
	local cycle = math.floor(t / 10)
	if k < 0.4 and cycle ~= rig.lastEvent then
		rig.lastEvent = cycle
		burst(rig, "Splash", 16)
	end
	glow(rig, "SeedLight", 1 + 1.2 * bloom)
	-- the upper body bobs and sways from the hips; the legs and feet stay put
	local bob = 0.012 * u * (1 - cos(t * 2 * pi / 2.4)) / 2
	set(rig, "Spine", CFrame.new(0, bob, 0) * CFrame.Angles(rad(2) * wave(t, 3.3), rad(3) * wave(t, 5.1), rad(2) * wave(t, 4.3)))
	-- the petals breathe, and on a bloom open in a ripple
	for i, deg in ipairs(OUTER) do
		local a = rad(deg)
		local kk = (t - i * 0.08) % 10
		local env = if kk < 3 then sin(kk / 3 * pi) else 0
		set(rig, "Petal" .. i, CFrame.fromAxisAngle(Vector3.new(sin(a), 0, -cos(a)),
			rad(6) * wave(t, 5, i * 0.5) + rad(30) * env))
	end
	for i, deg in ipairs(INNER) do
		local a = rad(deg)
		local kk = (t - i * 0.1) % 10
		local env = if kk < 3 then sin(kk / 3 * pi) else 0
		set(rig, "Inner" .. i, CFrame.fromAxisAngle(Vector3.new(sin(a), 0, -cos(a)),
			rad(4) * wave(t, 4.4, i * 0.7) + rad(14) * env))
	end
	swellDrops(rig, "PetalDrop", t)
	-- the motes orbit the pod, each at its own pace, bobbing as they go
	for i = 1, 3 do
		set(rig, "Mote" .. i, CFrame.new(0, 0.03 * u * wave(t, 2.3 + i * 0.4, i), 0) * CFrame.Angles(0, t * MOTE_SPEED[i], 0))
	end
	-- the arms sway; every 11 s the left arm waves
	local w = t % 11
	local hello = if w < 1.4 then sin(w / 1.4 * pi) else 0
	set(rig, "ArmL", CFrame.Angles(rad(7) * wave(t, 2.6), 0, rad(7) * wave(t, 3.4, 0.7) + rad(60) * hello))
	set(rig, "HandL", CFrame.Angles(rad(14) * wave(t, 2.0, 0.6), 0, rad(30) * hello * sin(t * 16)))
	set(rig, "ArmR", CFrame.Angles(rad(7) * wave(t, 2.6, 1.3), 0, rad(7) * wave(t, 3.4, 2.0)))
	set(rig, "HandR", CFrame.Angles(rad(14) * wave(t, 2.0, 1.4), 0, 0))
	-- the legs shift a little; the feet stay planted
	set(rig, "LegL", CFrame.Angles(rad(3) * wave(t, 3.3), 0, 0))
	set(rig, "LegR", CFrame.Angles(rad(3) * wave(t, 3.3, pi), 0, 0))
	set(rig, "FootL", IDENTITY)
	set(rig, "FootR", IDENTITY)
	blinkEyes(rig, t, 3.9)
end

local function tempestoak(rig: Rig, t: number)
	local u = rig.unit * rig.scale
	-- the roar (rear back, arms wide), then the slam (fists down, a lunge)
	local k = t % 8
	local roar = 0
	if k < 0.8 then
		roar = sin(k / 0.8 * pi / 2)
	elseif k < 1.6 then
		roar = 1
	elseif k < 1.75 then
		roar = 1 - (k - 1.6) / 0.15
	end
	local slam = 0
	if k >= 1.6 and k < 2.1 then
		slam = sin((k - 1.6) / 0.5 * pi / 2)
	elseif k >= 2.1 and k < 3.0 then
		slam = cos((k - 2.1) / 0.9 * pi / 2)
	end
	local tremor = roar * sin(t * 38)
	local strikeWindow = k > 0.85 and k < 1.5
	local cycle = math.floor(t / 8)
	if k > 0.85 and k < 1.2 and cycle ~= rig.lastEvent then
		rig.lastEvent = cycle
		burst(rig, "CloudSparks", 30)
		burst(rig, "RoarSparks", 30)
		burst(rig, "CoreSparks", 24)
	end
	-- the trunk heaves from the hips; the legs and feet stay where they are
	local bob = 0.012 * u * (1 - cos(t * 2 * pi / 2.4)) / 2
	set(rig, "Spine", CFrame.new(0, bob, 0) * CFrame.Angles(rad(1.5) * wave(t, 3.3) + rad(3) * roar - rad(6) * slam,
		rad(1.5) * wave(t, 5.1), rad(1.5) * wave(t, 4.3)))
	set(rig, "Chest", CFrame.Angles(rad(1.5) * wave(t, 3.3, 0.5) + rad(8) * roar - rad(14) * slam,
		rad(3) * wave(t, 5.1, 0.3), rad(1.5) * wave(t, 4.3, 0.4)))
	set(rig, "Neck", CFrame.Angles(rad(2) * wave(t, 3.3, 0.8) + rad(10) * roar - rad(8) * slam, rad(8) * wave(t, 6.2), 0))
	set(rig, "Head", CFrame.Angles(rad(2) * wave(t, 2.9) + rad(14) * roar - rad(12) * slam + rad(1.5) * tremor,
		rad(10) * wave(t, 6.2, 1.0), rad(2) * tremor))
	set(rig, "Jaw", CFrame.Angles(-(rad(3) * (1 + wave(t, 1.3)) / 2 + rad(34) * roar), 0, 0))
	set(rig, "BrowL", CFrame.Angles(0, 0, rad(4) * wave(t, 3.7) + rad(10) * roar))
	set(rig, "BrowR", CFrame.Angles(0, 0, -rad(4) * wave(t, 3.7, 1.0) - rad(10) * roar))
	set(rig, "AntlerL", CFrame.Angles(0, 0, -(rad(2) * wave(t, 3.1) + rad(10) * roar)))
	set(rig, "AntlerR", CFrame.Angles(0, 0, rad(2) * wave(t, 3.1, 1.0) + rad(10) * roar))
	set(rig, "AntlerTipL", CFrame.Angles(0, 0, -(rad(2) * wave(t, 2.5, 0.5) + rad(8) * roar)))
	set(rig, "AntlerTipR", CFrame.Angles(0, 0, rad(2) * wave(t, 2.5, 1.5) + rad(8) * roar))
	-- the cloud churns and swells; its veins crackle, and stay lit on a roar
	set(rig, "Cloud", CFrame.new(0.02 * u * wave(t, 5.0), 0.025 * u * wave(t, 2.6) + 0.06 * u * roar, 0.02 * u * wave(t, 5.0, pi / 2))
		* CFrame.Angles(0, rad(10) * wave(t, 6.0), rad(3) * wave(t, 3.7)))
	flicker(rig, "CloudVein", t, 0.7, roar > 0.3)
	-- the storm heart: the ring of rays spins, the core pulses and flares
	set(rig, "CoreRing", CFrame.Angles(0, 0, t * 1.6 + rad(30) * roar * sin(t * 9)))
	for _, core in ipairs(rig.named.StormCore or {}) do
		local size = rig.rest[core]
		if size then
			core.Size = size * (0.95 + 0.1 * sin(t * 3.2) + 0.45 * roar)
		end
	end
	glow(rig, "CoreLight", 1 + 0.3 * sin(t * 3.2) + 2 * roar)
	glow(rig, "MouthLight", 1 + 3 * roar + 0.2 * sin(t * 9))
	-- the lightning: arcs between the antler tips and a bolt from the cloud
	for _, name in ipairs({ "ArcBolt", "StrikeBolt" }) do
		for _, part in ipairs(rig.named[name] or {}) do
			local on = strikeWindow and sin(t * 61 + (rig.phases[part] or 0) * 5) > -0.2
			part.Transparency = if on then 0 else 1
		end
	end
	local strike = rig.lights.StrikeLight
	if strike then
		strike.Brightness = if strikeWindow then 3 * (0.5 + 0.5 * sin(t * 47)) else 0
	end
	-- the arms sway, fling wide on a roar, slam forward and down
	local spread = rad(8) * wave(t, 3.4, 0.7) + rad(55) * roar
	set(rig, "ArmL", CFrame.Angles(rad(8) * wave(t, 2.6) + rad(45) * slam, 0, spread * (1 - 0.6 * slam)))
	set(rig, "ArmR", CFrame.Angles(rad(8) * wave(t, 2.6, 1.3) + rad(45) * slam, 0,
		-(rad(8) * wave(t, 3.4, 2.0) + rad(55) * roar) * (1 - 0.6 * slam)))
	set(rig, "ForearmL", CFrame.Angles(rad(10) * wave(t, 2.0, 0.6) + rad(25) * roar + rad(20) * slam, 0, 0))
	set(rig, "ForearmR", CFrame.Angles(rad(10) * wave(t, 2.0, 1.4) + rad(25) * roar + rad(20) * slam, 0, 0))
	set(rig, "FistL", CFrame.Angles(rad(10) * wave(t, 1.6, 0.9), 0, 0))
	set(rig, "FistR", CFrame.Angles(rad(10) * wave(t, 1.6, 2.1), 0, 0))
	for i = 1, 3 do
		local curl = rad(8) * wave(t, 1.8, i * 0.4) + rad(30) * roar - rad(45) * slam
		set(rig, "FingerL" .. i, CFrame.Angles(curl, 0, 0))
		set(rig, "FingerR" .. i, CFrame.Angles(curl, 0, 0))
	end
	-- the legs hold still (a slight shift at the hips) so the feet stay planted
	set(rig, "HipL", CFrame.Angles(rad(2) * wave(t, 3.3), 0, 0))
	set(rig, "HipR", CFrame.Angles(rad(2) * wave(t, 3.3, pi), 0, 0))
	set(rig, "KneeL", IDENTITY)
	set(rig, "KneeR", IDENTITY)
	set(rig, "AnkleL", IDENTITY)
	set(rig, "AnkleR", IDENTITY)
	-- the tendrils lash in waves, harder on a roar
	for i = 1, 3 do
		local fa = rad(6 + 2 * i) * wave(t, 2.0, (i - 1) * 0.7) * (1 + roar)
		local latL = rad(8 + 3 * i) * wave(t, 2.4, (i - 1) * 0.8) * (1 + roar) + rad(10) * roar
		local latR = rad(8 + 3 * i) * wave(t, 2.4, (i - 1) * 0.8 + pi) * (1 + roar) - rad(10) * roar
		set(rig, "TendrilL" .. i, CFrame.Angles(fa, 0, latL))
		set(rig, "TendrilR" .. i, CFrame.Angles(fa, 0, latR))
	end
end

local function thundermaw(rig: Rig, t: number)
	local u = rig.unit * rig.scale
	-- the roar: rears back and gapes, holds, snaps shut; then a lunge forward
	local k = t % 7
	local roar = 0
	if k < 0.7 then
		roar = sin(k / 0.7 * pi / 2)
	elseif k < 1.5 then
		roar = 1
	elseif k < 1.65 then
		roar = 1 - (k - 1.5) / 0.15
	end
	local recoil = if k >= 1.5 and k < 2.4 then sin((k - 1.5) / 0.9 * pi) else 0
	local tremor = roar * sin(t * 38)
	local cycle = math.floor(t / 7)
	if k > 0.7 and k < 1.1 and cycle ~= rig.lastEvent then
		rig.lastEvent = cycle
		burst(rig, "RoarSparks", 26)
		burst(rig, "ManeSparks", 20)
	end
	-- a quick small snap of the jaws every few seconds (not during a roar)
	local c = t % 3.1
	local chomp = if c < 0.18 and roar < 0.1 then sin(c / 0.18 * pi) else 0
	-- the trunk heaves from the hips; the legs and feet stay where they are
	local bob = 0.01 * u * (1 - cos(t * 2 * pi / 2.2)) / 2
	set(rig, "Spine", CFrame.new(0, bob, 0) * CFrame.Angles(rad(1.5) * wave(t, 3.3) + rad(5) * roar - rad(9) * recoil,
		rad(2) * wave(t, 5.1), rad(1.5) * wave(t, 4.3)))
	set(rig, "Neck1", CFrame.Angles(rad(2) * wave(t, 3.3, 0.4) + rad(16) * roar - rad(8) * recoil, rad(8) * wave(t, 6.2), 0))
	set(rig, "Neck2", CFrame.Angles(rad(2) * wave(t, 3.3, 0.8) + rad(12) * roar - rad(6) * recoil, rad(6) * wave(t, 6.2, 0.5), 0))
	set(rig, "Head", CFrame.Angles(rad(2) * wave(t, 2.9) + rad(12) * roar - rad(10) * recoil + rad(1.5) * tremor,
		rad(10) * wave(t, 6.2, 1.0), rad(2) * tremor))
	set(rig, "JawU", CFrame.Angles(rad(3) * wave(t, 1.1) + rad(38) * roar - rad(9) * chomp, 0, 0))
	set(rig, "JawL", CFrame.Angles(-rad(3) * wave(t, 1.1) - rad(30) * roar + rad(7) * chomp, 0, 0))
	set(rig, "Tongue1", CFrame.Angles(rad(3) * wave(t, 0.8) + rad(16) * roar, rad(18) * roar * sin(t * 13), 0))
	set(rig, "Tongue2", CFrame.Angles(rad(5) * wave(t, 0.8, 0.6) + rad(18) * roar, rad(26) * roar * sin(t * 13 - 1), 0))
	set(rig, "BrowL", CFrame.Angles(0, 0, rad(4) * wave(t, 3.7) + rad(10) * roar))
	set(rig, "BrowR", CFrame.Angles(0, 0, -rad(4) * wave(t, 3.7, 1.0) - rad(10) * roar))
	set(rig, "Crest", CFrame.Angles(rad(3) * wave(t, 2.2) - rad(18) * roar, 0, 0))
	-- the mane sways and crackles
	set(rig, "Mane", CFrame.Angles(rad(3) * wave(t, 2.7), rad(5) * wave(t, 4.3), rad(3) * wave(t, 3.1)))
	flicker(rig, "ManeVein", t, 0.75, roar > 0.3)
	-- the arms sway and spread on a roar; the forearms flex and the claws open
	set(rig, "ArmL", CFrame.Angles(rad(8) * wave(t, 2.6), 0, rad(8) * wave(t, 3.4, 0.7) + rad(35) * roar))
	set(rig, "ArmR", CFrame.Angles(rad(8) * wave(t, 2.6, 1.3), 0, -rad(8) * wave(t, 3.4, 2.0) - rad(35) * roar))
	set(rig, "ForearmL", CFrame.Angles(rad(10) * wave(t, 2.0, 0.6) + rad(30) * roar, 0, 0))
	set(rig, "ForearmR", CFrame.Angles(rad(10) * wave(t, 2.0, 1.4) + rad(30) * roar, 0, 0))
	set(rig, "ClawL", CFrame.Angles(rad(12) * wave(t, 1.6, 0.9) + rad(22) * roar, 0, 0))
	set(rig, "ClawR", CFrame.Angles(rad(12) * wave(t, 1.6, 2.1) + rad(22) * roar, 0, 0))
	-- the legs hold still (a slight shift at the hips) so the feet stay planted
	set(rig, "HipL", CFrame.Angles(rad(2) * wave(t, 3.3), 0, 0))
	set(rig, "HipR", CFrame.Angles(rad(2) * wave(t, 3.3, pi), 0, 0))
	set(rig, "KneeL", IDENTITY)
	set(rig, "KneeR", IDENTITY)
	set(rig, "AnkleL", IDENTITY)
	set(rig, "AnkleR", IDENTITY)
	-- the tail lashes in a wave, harder on a roar
	for i = 1, 4 do
		set(rig, "Tail" .. i, CFrame.Angles(rad(3 + i) * wave(t, 2.2, (i - 1) * 0.7) * (1 + roar),
			rad(10 + 4 * i) * wave(t, 2.6, (i - 1) * 0.8) * (1 + 1.5 * roar), 0))
	end
	glow(rig, "MouthLight", 1 + 3 * roar + 0.2 * sin(t * 9))
	glow(rig, "BulbLight", 0.8 + 0.4 * sin(t * 3) + 1.5 * roar)
end

local IDLES: { [string]: (Rig, number) -> () } = {
	snarlbloom = snarlbloom,
	petalfawn = petalfawn,
	puddlepod = puddlepod,
	drizzlet = drizzlet,
	lotusling = lotusling,
	tempestoak = tempestoak,
	thundermaw = thundermaw,
}

--==============================================================================
-- ONE FRAME: the poses, then the tree written onto the anchored parts.
--==============================================================================
local function apply(rig: Rig)
	local pivot = rig.model:GetPivot()
	local nodes, pose = rig.nodes, rig.pose
	-- A virtual body (WalkProfile.virtual) moves the root part, and so the whole
	-- tree, about where that part stands.
	local bodyPose, bodyAt = pose[BODY], rig.bodyAt
	local lifted = if bodyPose and bodyAt then pivot * CFrame.new(bodyAt) * bodyPose * CFrame.new(-bodyAt) else pivot
	for i, node in ipairs(nodes) do
		if node.parent == nil then
			node.part.CFrame = (if i == rig.rootNode then lifted else pivot) * node.rel
		end
	end
	for _, i in ipairs(rig.order) do
		local node = nodes[i]
		local parent = node.parent
		if parent then
			local p = nodes[parent].part.CFrame
			local motor = node.motor
			local joint = if motor then (pose[motor] or IDENTITY) else IDENTITY
			if node.forward then
				node.part.CFrame = p * node.c0 * joint * node.c1:Inverse()
			else
				node.part.CFrame = p * node.c1 * joint:Inverse() * node.c0:Inverse()
			end
		end
	end
end

function SecretIdle.Step(rig: Rig, now: number)
	local model = rig.model
	if model:GetAttribute("ProceduralIdle") == false then
		-- Stopped cleanly: every joint back to rest, written once.
		if not rig.stopped then
			rig.stopped = true
			table.clear(rig.pose)
			apply(rig)
		end
		return
	end
	rig.stopped = false
	-- The walk first: how far it went decides how much of it shows. Its joints
	-- are cleared so the idle's pose -- or rest, where the idle sets none -- is
	-- what the walk is laid over, never last frame's walk.
	local gait = rig.gait
	if gait then
		stepGait(rig, gait, now)
		for _, name in ipairs(gait.joints) do
			rig.pose[name] = nil
		end
	end
	local idle = IDLES[rig.idle]
	if idle then
		idle(rig, now + rig.phase)
	end
	if gait then
		walkPose(rig, gait)
	end
	apply(rig)
end

-- Rest, written once: what a stopped rig looks like.
function SecretIdle.Rest(rig: Rig)
	table.clear(rig.pose)
	apply(rig)
end

return SecretIdle
