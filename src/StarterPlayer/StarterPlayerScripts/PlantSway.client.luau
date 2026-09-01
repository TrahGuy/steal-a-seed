--!strict
-- Steal a Seed :: PlantSway
--
-- The idle sway on anything growing in a plot. Grown creatures and sprouts were
-- statues: a bed of twelve looked like a shelf of ornaments rather than a row of
-- living things.
--
--==============================================================================
-- GROWN PLANTS WALK. PODS DO NOT.
--
-- This block used to say "a plant that WALKS is a performance bug wearing a
-- costume", and it was right about the thing it was refusing: seventy-two
-- HUMANOIDS on a full server, each running a state machine and a floor
-- raycast, to move things planted in the ground.
--
-- That is still refused. What is added is not a Humanoid -- it is one more term
-- in the CFrame this script was already writing. A grown plant picks a point
-- near its planted home, walks there over a few seconds, stops, waits, picks
-- another. No Humanoid, no pathfinding, no raycast, no server traffic, and the
-- per-plant cost is unchanged: one PivotTo, on the same 20 Hz slice.
--
-- Three rules hold the whole thing together:
--
--   THEY NEVER LEAVE THE BED. Targets are chosen in the SOIL's object space and
--   clamped to its rectangle, exactly the way PlantService clamps a click. Not
--   a floor test -- a bounds test -- so there is nothing to fall through and
--   nothing to path around. The road is unreachable by construction.
--
--   THEY DO NOT STEER. Each plant has its own bearing, stamped by
--   PlantService off its placement id, and it walks sideways and backwards
--   rather than turning to face where it is going. Steering would make a bed
--   into a flock all pointing one way -- the thing free placement exists to
--   stop -- and it would spin every plant on the spot at the start of each leg.
--
--   IT DOES LOOK AROUND. On top of that fixed bearing, a standing plant turns
--   slowly through a few tens of degrees and back. Independent of the walk, and
--   only WHILE STANDING: the phase stops advancing mid-step, so it never turns
--   and travels at once, and it picks up again where it left off when it
--   stops. That is what keeps a bed from reading as a set of ornaments that
--   happen to be facing different ways.
--
--   PODS STAY PUT. An egg does not stroll. Pods are in this set only for the
--   hatch shake, and their idle amplitude is zero.
--
-- The lean is still here and still does the breathing. The walk is a
-- translation of the same anchor the lean pivots about, so the two compose
-- instead of fighting.
--
--==============================================================================
-- CLIENT ONLY, SAME SPLIT AS THE FAIRY
--
-- The server builds the plant, tags it, and never moves it again. Every client
-- leans its own local copy. Plant parts are ANCHORED, so a CFrame written here
-- is local to this machine and there is nothing for the server to fight with --
-- exactly the arrangement Ambience uses for Marigold's wings.
--
--==============================================================================
-- ONE PivotTo PER PLANT, AND NOT EVERY PLANT EVERY FRAME
--
-- A grown creature is fifteen-odd parts. Writing every part's CFrame would be a
-- thousand property writes a frame on a full server, which is exactly the kind
-- of thing the mobile-first rule exists to stop.
--
-- Instead: one PivotTo per plant -- a single engine call that moves the whole
-- model -- and the set is walked in SLICES, so each plant updates about twenty
-- times a second rather than sixty. The sway has a six-to-ten second period; at
-- 20 Hz each step is a fraction of a degree and nothing looks stepped.
--
--==============================================================================
-- HEAVY THINGS MOVE LESS, AND SLOWER
--
-- Sized in STUDS OF HEAD TRAVEL, not in degrees. Degrees are the wrong unit for
-- a set of models that run from 1.7 to 6.4 studs tall: the same angle is a
-- twitch on one and a swing on the other. So the travel is chosen and the angle
-- solved from it -- travel = 2 * h * sin(amp).
--
-- A 2 kg Nubkin's head covers about 0.67 studs a cycle, a 110 kg Bellchime's
-- about 0.35 and more slowly. That is the same fact the silhouette carries --
-- weight -- said a second way.
--
-- Never enough to look like it will fall over. This is breathing, not toppling.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local PLANTED = GameConfig.Tags.Planted

--==============================================================================
-- PODS ARE TRACKED NOW, AND STILL DO NOT SWAY
--
-- A pod is an egg lying on the soil. The sway is a stem leaning, and a thing
-- with no stem leaning reads as a wobble -- so a pod's idle amplitude is zero
-- and this used to skip them entirely.
--
-- It cannot skip them any more, because a pod is the ONLY thing that shakes.
-- Holding E on a ready one has to make the shell rattle itself apart, and this
-- is the script that already moves every planted model on every client, every
-- frame, for free. Doing it on the server would push a CFrame down the wire per
-- pod per frame to animate a thing one player is looking at.
--
-- So: pods are in the set with amp 0, and two attributes wake them up.
--
--     Ready      the clock has run out. A slow, small breathing wobble, so a
--                bed reads as "these two are done" from the gate.
--     Hatching   the prompt is being held. Fast, violent, and it wins.
--==============================================================================
local STAGE_POD = 1

-- Radians. Deliberately far past anything the idle does -- the point is that it
-- looks like it is coming apart.
local SHAKE_AMP = math.rad(13)
local SHAKE_HZ = 27
-- How much a ready pod breathes, as a fraction of a full-grown plant's lean.
local READY_SCALE = 0.35

--==============================================================================
-- THE WALK
--
-- Every number is a curve in kg, for the same reason every other number in this
-- game is: a 2 kg Nubkin and a 10,000 kg Bellchime are the same creature at
-- opposite ends of one scale, and the heavy one has to LOOK heavy without a
-- second set of constants to keep in step.
--
--     kg        radius   speed    pause     what it reads as
--          1       6.0      2.6     2.2s     skittering
--          2       5.5      2.3     2.3s     bustling around its patch
--        110       3.3      1.2     2.8s     ambling
--      1,000       2.4      0.8     3.2s     lumbering
--     10,000       1.8      0.5     3.7s     a boulder shifting its weight
--
-- For scale: a tier-1 bed is 34 by 47.6 studs, so even the lightest plant's
-- 6-stud radius is a patch it works rather than a lap of the garden. Radius is
-- clamped for that reason -- a plant that crosses the whole plot in one leg
-- reads as a glitch, not a stroll. The soil clamp is the hard limit; this is
-- the one that makes it look deliberate.
--==============================================================================
-- THESE TAKE A TIER AND LOOK UP ITS VALUE. Every curve here was fitted
-- against a weight spanning 1 .. 10,000, and a tier index spans 1 .. 7 --
-- feeding one straight in flattens the whole set. wanderRadius alone would
-- go from a 6.0 .. 1.2 spread to 6.0 .. 4.7, and a Colossal would potter
-- about like a Tiny. The tier's `value` is the weight it replaced, so the
-- curves keep the shape they were tuned to.
local function tierValue(tier: number): number
	return SeedData.Tier(tier).value
end

local function wanderRadius(tier: number): number
	return math.clamp(6.0 / (tierValue(tier) ^ 0.13), 1.2, 6.0)
end

local function wanderSpeed(tier: number): number
	return math.clamp(2.6 / (tierValue(tier) ^ 0.17), 0.25, 2.6)
end

local function wanderPause(tier: number): number
	return math.clamp(1.2 + tierValue(tier) ^ 0.10, 1.4, 4.5)
end

-- How far the leaves swing as it steps, and how far the body bobs, as a
-- fraction of the plant's own height. Both are scaled by how far through a leg
-- it is, so they settle to nothing when it stops rather than snapping.
-- The same margin PlantService pulls a click inside by, so a plant may walk to
-- exactly the places you are allowed to plant one and no further. Two rules
-- that disagreed about the edge of the bed would show up as a plant standing
-- half in the frame.
local EDGE_MARGIN = GameConfig.Plant.EdgeMarginStuds

--==============================================================================
-- WHAT THE EYES ARE LOOKING AT
--
-- Cached against the clock rather than read per plant: apply() runs for a whole
-- slice under one `now`, so this resolves once a frame instead of two dozen
-- times. A dead or missing character simply returns nil and every plant falls
-- back to idle saccades.
--==============================================================================
local viewerAt: Vector3? = nil
local viewerNow = -1

local function viewerPosition(now: number): Vector3?
	if now ~= viewerNow then
		viewerNow = now
		viewerAt = nil
		local char = Players.LocalPlayer and Players.LocalPlayer.Character
		local head = char and char:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			viewerAt = head.Position
		end
	end
	return viewerAt
end

--==============================================================================
-- THE LOOK-AROUND
--
-- Far enough to be visible on a silhouette, nowhere near far enough to lose
-- which way the plant is meant to be facing. Heavier turns slower, like
-- everything else, and each plant is phased off its placement id so a bed does
-- not sweep in unison.
--
--     2 kg      full sweep every ~12s
--     10,000 kg full sweep every ~26s
--==============================================================================
local LOOK_AMP = math.rad(28)
-- How long the turn takes to mostly finish, in seconds. Short enough that a
-- plant is pointed the right way within the first fifth of a leg -- it should
-- look like it turned and then set off -- and long enough that the turn itself
-- is visible rather than a snap on one frame.
local TURN_TAU = 0.22
-- How far a leg swings fore and aft at the top of a stride. Bigger than the
-- leaf swing because a leg is doing the walking and a leaf is only reacting to
-- it; small enough that the foot does not visibly scythe through the soil.
local LEG_SWING = math.rad(21)

local function lookRate(tier: number): number
	return math.clamp(0.55 / (tierValue(tier) ^ 0.09), 0.18, 0.75)
end

local SWING_AMP = math.rad(19)
local BOB_FRACTION = 0.035
local BOB_CEILING = 0.35
local ROLL_AMP = math.rad(3.5)

-- Roughly how often each plant is refreshed. The set is walked in slices to
-- hit this, whatever the frame rate and however many plants there are. A pod
-- that is actively hatching is exempt -- see the Heartbeat.
--==============================================================================
-- THE EYES FOLLOW YOU
--
-- Everything above makes a plant MOVE. None of it makes one look ALIVE, because
-- a face whose every part is welded to the skull is a mask however well it is
-- shaped. The eyes were tuned four times -- colour, segment count, depth, size
-- -- and stayed dead through all of it, for the reason a fixed highlight is
-- always dead: it is pinned to the light, so it stares through you no matter
-- where it sits.
--
-- WHAT MOVES DEPENDS ON WHAT THE CREATURE HAS, AND NOTHING IS REDESIGNED.
--
--   Pupil rig   a Pupil part travelling across the eyeball's surface. The
--               better of the two, and what Emberroot is built for.
--   Eye rig     no Pupil, so the whole Eye slides on the face and its Glint
--               rides along. Every one of the twenty-five shipped species is
--               this one, and it needs NO art change -- the parts are already
--               there, they simply stop being welded to the bone.
--
-- Deliberately not "give every creature a pupil": production's eye is a dark
-- ball that is already all pupil, so adding one would mean lightening every
-- face in the game to make room. Moving the eye reads as gaze just as well and
-- changes nothing that was already approved.
--
-- SACCADES, NOT GLIDING. Real eyes snap between fixations and then hold. An eye
-- that slides smoothly to each new target is a security camera. So idle gaze
-- holds a point for one to three seconds and flicks between them, and only
-- PURSUIT -- following someone who is actually there -- is smooth.
--
-- WHAT IT COSTS. Two CFrame writes per plant per slice, on top of the PivotTo,
-- exactly like the leaf swing below and affordable for the same reason: two
-- extra CFrames on a fifteen-part model is a rounding error next to the pivot.
--
-- Note it CANNOT be skipped the way the swing is. PivotTo has just rewritten
-- every part to its rest offset, so a held gaze still has to be re-applied
-- afterwards or the eyes snap forward every slice. Only a plant looking dead
-- ahead costs nothing.
--==============================================================================
local GAZE_MAX = math.rad(30)
local GAZE_RANGE = 70
-- Time constants. Pursuit is slow on purpose; being watched should feel
-- unhurried rather than mechanical.
local GAZE_PURSUIT_TAU = 0.13
local GAZE_SACCADE_TAU = 0.045
local GAZE_HOLD_MIN, GAZE_HOLD_MAX = 1.0, 2.8
-- How far an Eye-rig eye slides, as a fraction of its own diameter. Small: the
-- eye is half sunk into a curved head and a big excursion lifts it off the
-- surface at the extremes.
local GAZE_EYE_TRAVEL = 0.55

--==============================================================================
-- THE BLINK
--
-- The eyes are BALLS, and a Roblox Ball renders as a sphere of its SMALLEST
-- axis -- squashing one shut does nothing at all. So every eye carries a lid
-- part, and blinking sweeps it down over the ball.
--
-- The travel is not a constant. It is worked out per lid from where that lid
-- rests and how big its eye is, so Dustbowl -- whose lid already sits low
-- enough to be a permanent squint -- has a short blink, and a wide-open
-- Greenhollow eye has a long one. Both come off the parts, so both stay right
-- at any weight.
--
-- Fast down, slower up, which is what a real blink does and what stops it
-- reading as a mechanical shutter. Intervals are per plant, so a bed never
-- blinks in chorus.
--==============================================================================
local BLINK_DOWN = 0.055
local BLINK_UP = 0.10
local BLINK_GAP_MIN, BLINK_GAP_MAX = 2.6, 7.5

local TARGET_HZ = 20

type Sway = {
	model: Model,
	-- Where the model was, so it can be put back exactly.
	rest: CFrame,
	-- AN UPRIGHT FRAME AT THE BASE. Pure translation, so its axes are the
	-- world's: tipping about X or Z is a lean, and nothing is a twist. See the
	-- block above apply().
	anchor: CFrame,
	-- The model's rest pose expressed in the anchor's frame, so the lean can be
	-- applied about the anchor and the model put back on top of it.
	offset: CFrame,
	-- Radians.
	amp: number,
	speed: number,
	phase: number,
	-- Studs from the base to the highest part, which is what turns an angle
	-- into visible movement.
	headHeight: number,
	-- A pod, rather than a placed creature. Only pods react to the two below.
	pod: boolean,
	-- The clock has run out and the hatch prompt is up.
	ready: boolean,
	-- Somebody is holding E on it right now.
	hatching: boolean,
	-- The two attribute watches above, held so forget() can drop them. A plot
	-- churns plants for as long as the session lasts, and a list that only ever
	-- grows is a leak even when every connection in it is already inert.
	watches: { RBXScriptConnection },

	--==========================================================================
	-- THE WALK, ALL OF IT, PER PLANT
	--
	-- Nil on a pod: an egg does not stroll, and the fields would only be dead
	-- weight in a table there are seventy-two of.
	--==========================================================================
	-- The bed it may not leave, and its CFrame at the moment this was measured.
	soil: BasePart?,
	-- Where it was PLANTED, in the soil's object space. Legs are chosen around
	-- this, never around wherever it happens to have wandered to -- otherwise a
	-- random walk drifts and after ten minutes the bed has emptied into a corner.
	homeLocal: Vector3?,
	radius: number,
	walkSpeed: number,
	pause: number,
	-- Per-plant, seeded off PlacementId, so two plants never take the same walk
	-- and a rejoin takes the same one again.
	rng: Random?,
	-- The leg in progress, in world space.
	from: Vector3?,
	to: Vector3?,
	legStart: number,
	legEnd: number,
	-- When the next leg begins. legEnd .. nextLeg is the pause.
	nextLeg: number,
	-- How often a step lands, derived from speed and size.
	strideHz: number,
	bob: number,
	-- The two Leaf parts and where they sit relative to the model's pivot, so
	-- they can be swung as arms after the PivotTo without measuring anything.
	leaves: { { part: BasePart, offset: CFrame, sign: number } },
	-- One entry per LEG PART, already resolved to the hip it hangs from and its
	-- own place on that hip, so a swing is one multiply per part per slice.
	legs: { { part: BasePart, hip: CFrame, rel: CFrame, phase: number } },
	-- The gaze rig, resolved once. `ref` is a face-aligned frame the aim is
	-- measured in; `eyeOffset` and `radius` are set only on the Pupil rig.
	gaze: {
		pupilRig: boolean,
		ref: CFrame,
		parts: { { part: BasePart, offset: CFrame, eyeOffset: CFrame?, local_: CFrame? } },
		lids: { { part: BasePart, eyeOffset: CFrame, local_: CFrame, drop: number } },
		shrink: { { part: BasePart, rest: Vector3 } },
		blinkT: number,
		blinkAt: number,
		travel: number,
		yaw: number, pitch: number,
		tYaw: number, tPitch: number,
		holdUntil: number,
	}?,
	-- The look-around. `lookPhase` ACCUMULATES rather than being derived from
	-- the clock, because it has to stop while the plant is walking and carry on
	-- from where it stopped -- a phase read straight off the clock would jump
	-- forward by however long the leg took.
	lookPhase: number,
	-- Where the plant is actually POINTED, in radians about world Y, measured
	-- from its rest bearing. Eased rather than assigned: it is the difference
	-- between a plant turning to walk and a plant snapping to a heading.
	facing: number,
	lookRate: number,
	-- The clock the last time this entry was touched, so the phase can advance
	-- by real elapsed time. apply() is called on a slice, so the gap between two
	-- visits to the same plant is not the frame time.
	lastNow: number,
}

-- Both an array (to walk in slices) and a map (to find one by model on removal).
local list: { Sway } = {}
local index: { [Model]: number } = {}

local connections: { RBXScriptConnection } = {}
local clock = 0
local cursor = 1

--==============================================================================
-- REGISTERING
--==============================================================================
local function forget(instance: Instance)
	local model = instance :: Model
	local at = index[model]
	if not at then
		return
	end
	-- Put it back where the server built it, so a plant that stops swaying does
	-- not freeze mid-lean.
	local entry = list[at]
	for _, c in ipairs(entry.watches) do
		c:Disconnect()
	end
	table.clear(entry.watches)
	if entry.model.Parent then
		pcall(function()
			entry.model:PivotTo(entry.rest)
		end)
	end
	-- Swap-remove: order does not matter and this keeps removal O(1) rather
	-- than shuffling a table that can hold seventy-two entries.
	local last = #list
	list[at] = list[last]
	index[list[at].model] = at
	list[last] = nil
	index[model] = nil
	if cursor > #list then
		cursor = 1
	end
end

local function remember(instance: Instance)
	if not instance:IsA("Model") or index[instance :: Model] then
		return
	end
	local model = instance :: Model
	task.spawn(function()
		-- The model can be tagged before its parts have replicated, which is
		-- when PrimaryPart is still nil. ParentAnim drew nothing for a whole
		-- session by reading it once and giving up.
		local deadline = os.clock() + 5
		while not model.PrimaryPart and model.Parent and os.clock() < deadline do
			task.wait(0.1)
		end
		if not (model.Parent and model.PrimaryPart) then
			return
		end
		if not CollectionService:HasTag(model, PLANTED) or index[model] then
			return
		end
		local stage = tonumber(model:GetAttribute("Stage")) or 0
		local species = SeedData.Get(tostring(model:GetAttribute("SpeciesId")))
		if not species then
			return
		end

		-- THIS plant's weight, off the model. Two Nubkins in the same bed can be
		-- 4 kg and 900 kg now, and a heavy one has to sway like a heavy one --
		-- reading the species sheet would give a bed of identical shapes the
		-- identical motion and undo the only thing that told them apart.
		local tier = math.max(tonumber(model:GetAttribute("Tier")) or species.Tier, 0.001)

		--==================================================================
		-- MEASURE THE THING, THEN SIZE THE MOTION TO IT
		--
		-- World-space extents from every part's own corners. GetBoundingBox
		-- reports in the PIVOT's frame and this model pivots on a rolled
		-- cylinder, so it returns axes that are not the world's -- the same
		-- trap that made the creature-size numbers wrong the first time.
		--==================================================================
		local lo = Vector3.new(math.huge, math.huge, math.huge)
		local hi = -lo
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				local h = d.Size * 0.5
				for sx = -1, 1, 2 do
					for sy = -1, 1, 2 do
						for sz = -1, 1, 2 do
							local q = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
							lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
							hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
						end
					end
				end
			end
		end
		local headHeight = math.max(hi.Y - lo.Y, 0.5)
		-- The base of the model, dead centre. This is the soil, and it is what
		-- a plant leans about.
		local anchor = CFrame.new((lo.X + hi.X) * 0.5, lo.Y, (lo.Z + hi.Z) * 0.5)
		local rest = model:GetPivot()

		--==================================================================
		-- THE AMPLITUDE IS DERIVED FROM HOW FAR THE HEAD SHOULD TRAVEL
		--
		-- Not from a fixed angle. A Nubkin is 1.7 studs tall and a Bellchime
		-- 6.4, so one angle gives them wildly different motion -- and the old
		-- fixed ~3 degrees moved a Nubkin's head about five hundredths of a
		-- stud, which is why a bed of them read as furniture.
		--
		-- Pick the TRAVEL, then solve for the angle: travel = 2 * h * sin(amp).
		-- Heavier travels less, which is the same fact the silhouette carries.
		--==================================================================
		local travel = math.clamp(0.75 / (tierValue(tier) ^ 0.16), 0.30, 0.75)
		local amp = math.clamp(travel / (2 * headHeight), 0.006, math.rad(14))

		local entry: Sway = {
			model = model,
			rest = rest,
			anchor = anchor,
			offset = anchor:Inverse() * rest,
			amp = amp,
			-- Heavier is slower. A gentle power of weight, like every other
			-- curve here: 110 kg is fifty-five times 2 kg and nothing should be
			-- fifty-five times anything.
			speed = math.clamp(1.1 / (tierValue(tier) ^ 0.12), 0.35, 1.4),
			-- PHASED BY PLACEMENT, so a bed is not a chorus line. Irrational-ish
			-- multiplier so a dozen plants do not land on a common period. It
			-- was the slot index until slots stopped existing; the placement id
			-- counts the same way and is still unique within a plot.
			phase = (tonumber(model:GetAttribute("PlacementId")) or 0) * 0.9,
			headHeight = headHeight,
			pod = stage == STAGE_POD,
			ready = model:GetAttribute("Ready") == true,
			hatching = model:GetAttribute("Hatching") == true,
			watches = {},

			soil = nil,
			homeLocal = nil,
			radius = wanderRadius(tier),
			walkSpeed = wanderSpeed(tier),
			pause = wanderPause(tier),
			rng = nil,
			from = nil,
			to = nil,
			legStart = 0,
			legEnd = 0,
			nextLeg = 0,
			-- A step lands roughly every time the plant covers a third of its
			-- own height. Small things patter, big things thud.
			strideHz = math.clamp(
				wanderSpeed(tier) / math.max(headHeight * 0.35, 0.25), 0.5, 3.2),
			bob = math.min(headHeight * BOB_FRACTION, BOB_CEILING),
			leaves = {},
			legs = {},
			-- Off the placement id, so no two plants in a bed are looking the
			-- same way at the same moment.
			lookPhase = (tonumber(model:GetAttribute("PlacementId")) or 0) * 1.7,
			facing = 0,
			lookRate = lookRate(tier),
			-- NOT zero. A plant registered ten minutes into a session would
			-- otherwise take its first `dt` as ten minutes and snap to an
			-- arbitrary bearing instead of the one the server stamped.
			lastNow = clock,
		}

		--==============================================================
		-- ONLY A GROWN PLANT GETS A BED AND A PAIR OF ARMS
		--
		-- The soil is found through the model's own parents rather than
		-- being handed down: a plant lives in plot/Plants/, and that is
		-- the only bed it is ever allowed on. If it cannot be found the
		-- plant simply does not walk -- standing still is a fine
		-- failure, wandering with no bounds is not.
		--==============================================================
		if not entry.pod then
			local plants = model.Parent
			local plot = if plants then plants.Parent else nil
			local soil = if plot
				then plot:FindFirstChild(GameConfig.Plot.PlanterName)
				else nil
			if soil and soil:IsA("BasePart") then
				entry.soil = soil
				entry.homeLocal = soil.CFrame:PointToObjectSpace(anchor.Position)
				entry.rng = Random.new(
					(tonumber(model:GetAttribute("PlacementId")) or 1) * 7919)
				entry.from = anchor.Position
				entry.to = anchor.Position
				-- Staggered first step, so a garden restored on join does not
				-- set off as one.
				entry.nextLeg = (entry.rng :: Random):NextNumber(0, entry.pause)
			end

			local pivot = model:GetPivot()
			local inverse = pivot:Inverse()
			for _, d in ipairs(model:GetChildren()) do
				if d:IsA("BasePart") and d.Name == "Leaf" then
					local offset = inverse * d.CFrame
					table.insert(entry.leaves, {
						part = d,
						offset = offset,
						-- Which side of the stem it is on, so the pair swings
						-- in opposition like arms rather than together like a
						-- pair of wings.
						sign = if offset.Position.X < 0 then -1 else 1,
					})
				end
			end

			--==========================================================
			-- RESOLVE THE LEGS
			--
			-- These creatures have legs and the walk never touched them: the
			-- body translated, bobbed, rolled and swung its leaves while the
			-- legs were dragged along underneath as scenery. Feet that do not
			-- move are what makes a walk read as a slide, however well the rest
			-- of the body is animated.
			--
			-- FOUND BY NAME, CLUSTERED BY POSITION. Name alone cannot group
			-- them: Novaorb has two Thighs, two Shins and two FootClaws with no
			-- side in any name, and Cosmospire has four of each. But every part
			-- of one leg sits in the same place in plan view, so clustering the
			-- matched parts by their X/Z offset recovers the legs whatever they
			-- are called -- two for a biped, four for Astralhorn, six for
			-- Supernovus. It also means a species that renames a part keeps
			-- working as long as the word is still in there.
			--
			-- GREENHOLLOW AND TANGLEMIRE MATCH NOTHING, and that is correct:
			-- their plants stand on roots and a bulb, they have no legs to
			-- swing, and their whole-body bob is already their walk.
			--
			-- THE SWING IS ABOUT THE HIP, NOT THE PART. Rotating a thigh about
			-- its own centre swings the top of it backwards while the bottom
			-- goes forward, which reads as a part rocking rather than a limb
			-- stepping -- and it tears the shin off the bottom of it. Each leg
			-- gets ONE hip frame at the top of its highest part, and every part
			-- in that leg is stored relative to it, so the whole limb turns as
			-- one piece. Same shape as the pupil rig below.
			--==========================================================
			local LEG_WORDS = { "Thigh", "Femur", "Haunch", "Shin", "Tibia",
				"Knee", "Hock", "Foot", "Hoof", "Paw", "Toe", "Stilt", "Pillar" }
			local legParts = {}
			for _, d in ipairs(model:GetChildren()) do
				if d:IsA("BasePart") then
					for _, w in ipairs(LEG_WORDS) do
						if string.find(d.Name, w) then
							table.insert(legParts, { part = d, cf = inverse * d.CFrame })
							break
						end
					end
				end
			end
			--==========================================================
			-- NO THIGH, NO LEG
			--
			-- Dustbowl's five match on "RootFoot" and have nothing above it:
			-- four roots around a stem, which is a root ball and not a pair of
			-- legs. Clustered, they collapse into one group and all four swing
			-- together -- a hop, and a worse read than leaving them still.
			--
			-- A limb is a thing that hangs FROM something. Requiring an upper
			-- part is what separates Emberroot's root-THIGH, which really is a
			-- leg, from Dustbowl's root-FOOT, which is a toe on a stump.
			--==========================================================
			local hasUpper = false
			for _, it in ipairs(legParts) do
				local n = it.part.Name
				if string.find(n, "Thigh") or string.find(n, "Femur")
					or string.find(n, "Haunch") then
					hasUpper = true
					break
				end
			end
			if #legParts > 0 and hasUpper then
				--==================================================
				-- FIND THE HIPS, THEN HANG EVERYTHING ON THE NEAREST ONE
				--
				-- Grouping every leg part by how far along the body it sits
				-- confuses two different things: which leg a part belongs to,
				-- and how far forward that part reaches. A foot projects
				-- FORWARD of the hip it hangs from, so Novaorb's FootClaw banded
				-- with the opposite leg and came out in antiphase with its own
				-- thigh -- which would have swung the foot off the end of the
				-- leg every stride. Cosmospire's four stilts merged into two.
				--
				-- A HIP IS ONE PER LEG BY CONSTRUCTION. Take the parts in the
				-- upper half of the leg geometry, cluster those, and the count
				-- that falls out is the number of legs. Every remaining part --
				-- shin, tibia, paw, hoof, toe -- then joins whichever hip it is
				-- nearest in plan view, which is always its own.
				--==================================================
				local spread = math.max(hi.X - lo.X, hi.Z - lo.Z)

				local yLo, yHi = math.huge, -math.huge
				for _, it in ipairs(legParts) do
					local y = it.cf.Position.Y
					yLo = math.min(yLo, y)
					yHi = math.max(yHi, y)
				end
				-- A single-part leg (Supernovus is thighs and nothing else) has
				-- no spread in Y, and every part is its own hip. The >= is what
				-- makes that fall out rather than needing a special case.
				local hipLine = yLo + (yHi - yLo) * 0.55

				local hips = {}
				local hipNear = math.max(spread * 0.12, 0.25)
				for _, it in ipairs(legParts) do
					if it.cf.Position.Y >= hipLine then
						local p = it.cf.Position
						local found = nil
						for _, h in ipairs(hips) do
							local dx, dz = h.x - p.X, h.z - p.Z
							if dx * dx + dz * dz <= hipNear * hipNear then
								found = h
								break
							end
						end
						if found then
							local n = found.n
							found.x = (found.x * n + p.X) / (n + 1)
							found.z = (found.z * n + p.Z) / (n + 1)
							found.top = math.max(found.top, p.Y + it.part.Size.Y * 0.5)
							found.n = n + 1
						else
							table.insert(hips, { x = p.X, z = p.Z, n = 1,
								top = p.Y + it.part.Size.Y * 0.5, items = {} })
						end
					end
				end

				if #hips > 0 then
					-- Rank the hips along the body, so opposite corners can
					-- share a phase. Legs abreast share a rank; a gap in Z
					-- starts a new one.
					local ranked = table.clone(hips)
					table.sort(ranked, function(a, b)
						return a.z < b.z
					end)
					local bandGap = math.max(spread * 0.15, 0.30)
					local rank, prevZ = 0, nil
					for _, h in ipairs(ranked) do
						if prevZ == nil or h.z - prevZ > bandGap then
							rank += 1
						end
						prevZ = h.z
						-- DIAGONALS, out of one line: rank along the body plus
						-- which side it is on. A quadruped trots, a hexapod
						-- falls into alternating tripods, a biped alternates.
						h.phase = math.pi * ((rank + (if h.x < 0 then 0 else 1)) % 2)
					end

					-- Every leg part joins its nearest hip in plan view.
					for _, it in ipairs(legParts) do
						local p = it.cf.Position
						local best, bestD = nil, math.huge
						for _, h in ipairs(hips) do
							local dx, dz = h.x - p.X, h.z - p.Z
							local d = dx * dx + dz * dz
							if d < bestD then
								bestD, best = d, h
							end
						end
						table.insert((best :: any).items, it)
					end

					for _, h in ipairs(hips) do
						local hip = CFrame.new(h.x, h.top, h.z)
						local invHip = hip:Inverse()
						for _, it in ipairs(h.items) do
							table.insert(entry.legs, {
								part = it.part,
								hip = hip,
								rel = invHip * it.cf,
								phase = h.phase,
							})
						end
					end
				end
			end

			--==========================================================
			-- RESOLVE THE GAZE RIG
			--
			-- Matched by name suffix rather than by an exact string, so
			-- both naming conventions in the game are picked up: the
			-- shipped species name their parts "Eye" and "Glint", and
			-- Emberroot names them "LeftEye" / "LeftPupil".
			--
			-- A pod falls through with no eyes and gets no rig, which is
			-- correct -- an egg has no face to look out of.
			--==========================================================
			local pupils, eyes, glints = {}, {}, {}
			for _, d in ipairs(model:GetChildren()) do
				if d:IsA("BasePart") then
					local n = d.Name
					if n:sub(-5) == "Pupil" then
						table.insert(pupils, d)
					elseif n:sub(-3) == "Eye" then
						table.insert(eyes, d)
					elseif n:sub(-5) == "Glint" then
						table.insert(glints, d)
					end
				end
			end

			if #eyes > 0 then
				local parts = {}
				local pupilRig = false
				if #pupils > 0 then
					-- Pair each pupil to its own eye by the prefix they
					-- share, so a mismatched pair is dropped rather than
					-- guessed at.
					local byPrefix: { [string]: BasePart } = {}
					for _, e in ipairs(eyes) do
						byPrefix[e.Name:sub(1, -4)] = e
					end
					for _, p in ipairs(pupils) do
						local e = byPrefix[p.Name:sub(1, -6)]
						if e then
							table.insert(parts, {
								part = p,
								offset = inverse * p.CFrame,
								eyeOffset = inverse * e.CFrame,
								-- Its rest place ON the eye. The gaze
								-- ROTATES the eyeball and carries this
								-- along, rather than computing a point on
								-- the sphere -- which is what lets one eye
								-- hold several marks (Greenhollow has two
								-- highlights) without them collapsing onto
								-- each other.
								local_ = e.CFrame:ToObjectSpace(p.CFrame),
							})
						end
					end
					pupilRig = #parts > 0
				end
				if not pupilRig then
					-- The eyes slide, and their glints ride along so the
					-- highlight stays put on the eye it belongs to.
					for _, d in ipairs(eyes) do
						table.insert(parts, { part = d, offset = inverse * d.CFrame })
					end
					for _, d in ipairs(glints) do
						table.insert(parts, { part = d, offset = inverse * d.CFrame })
					end
				end
				--== LIDS, for the blink ==--
				local lids = {}
				for _, d in ipairs(model:GetChildren()) do
					if d:IsA("BasePart") and d.Name:sub(-3) == "Lid" then
						local e = eyes[1]
						for _, cand in ipairs(eyes) do
							if cand.Name:sub(1, -4) == d.Name:sub(1, -4) then e = cand end
						end
						local lv = e.CFrame:ToObjectSpace(d.CFrame)
						-- Centre onto centre. Matching the lower EDGES was
						-- the first attempt and it only ever covered as much
						-- of the eye as the lid was tall -- the bottom 56%,
						-- with the top half still staring out. The lid is
						-- taller than the eye now, so putting the two centres
						-- together covers it by construction.
						local drop = lv.Position.Y
						table.insert(lids, {
							part = d,
							eyeOffset = inverse * e.CFrame,
							local_ = lv,
							drop = math.max(drop, 0),
						})
					end
				end

				-- Everything that has to close: the eyeballs and everything
				-- riding on them.
				local shrink = {}
				for _, d in ipairs(eyes) do
					table.insert(shrink, { part = d, rest = d.Size })
				end
				for _, it in ipairs(parts) do
					table.insert(shrink, { part = it.part, rest = it.part.Size })
				end

				if #parts > 0 then
					entry.gaze = {
						pupilRig = pupilRig,
						lids = lids,
						shrink = shrink,
						blinkT = 0,
						blinkAt = clock + BLINK_GAP_MIN,
						-- The first eye's frame. Its rotation is the head's,
						-- which is the only part of it the aim maths uses.
						ref = inverse * eyes[1].CFrame,
						parts = parts,
						travel = eyes[1].Size.X * GAZE_EYE_TRAVEL,
						yaw = 0, pitch = 0, tYaw = 0, tPitch = 0,
						holdUntil = 0,
					}
				end
			end
		end
		--==============================================================
		-- WATCHED, NOT POLLED
		--
		-- apply() runs on every plant on every frame. Reading two attributes
		-- off the instance in there would be two property lookups per plant
		-- per frame to answer a question that changes twice in a pod's life.
		--==============================================================
		if entry.pod then
			table.insert(entry.watches,
				model:GetAttributeChangedSignal("Ready"):Connect(function()
					entry.ready = model:GetAttribute("Ready") == true
				end))
			table.insert(entry.watches,
				model:GetAttributeChangedSignal("Hatching"):Connect(function()
					entry.hatching = model:GetAttribute("Hatching") == true
					if not entry.hatching and model.Parent then
						-- Let go early and it settles rather than freezing
						-- mid-rattle.
						pcall(function()
							model:PivotTo(entry.rest)
						end)
					end
				end))
		end
		local at = #list + 1
		list[at] = entry
		index[model] = at
	end)
end

--==============================================================================
-- THE LEAN
--
-- Two axes at different rates, so the top traces a slow lopsided oval instead of
-- swinging flat like a metronome. Nothing is allocated here: the CFrames are
-- temporaries the VM reuses, and there is not an Instance.new in sight.
--==============================================================================
local function apply(entry: Sway, now: number)
	--==========================================================================
	-- A POD IS STILL, UNTIL IT IS NOT
	--
	-- Three states, checked in the order they matter. Hatching wins outright:
	-- while somebody is holding E the shell is coming apart and nothing else it
	-- might have been doing is interesting.
	--==========================================================================
	if entry.hatching then
		local t = now * SHAKE_HZ
		-- Two prime-ish rates and an offset, so it rattles rather than swings.
		local sx = SHAKE_AMP * math.sin(t)
		local sz = SHAKE_AMP * math.sin(t * 1.41 + 1.7)
		-- A small hop on top of the rattle. Rectified, so it only ever leaves
		-- the soil -- a pod sinking into the bed reads as a bug.
		local hop = math.abs(math.sin(t * 0.5)) * math.min(entry.headHeight * 0.10, 0.35)
		entry.model:PivotTo(entry.anchor
			* CFrame.new(0, hop, 0)
			* CFrame.Angles(sx, 0, sz)
			* entry.offset)
		return
	end
	if entry.pod and not entry.ready then
		return
	end

	local t = now * entry.speed + entry.phase
	local amp = if entry.pod then entry.amp * READY_SCALE else entry.amp
	local ax = amp * math.sin(t)
	-- 0.73 rather than 0.5 or 2.0: a rational ratio would close the oval into a
	-- repeating figure and the eye picks that up as machinery.
	local az = amp * 0.62 * math.sin(t * 0.73 + entry.phase * 1.3)
	-- ABOUT THE ANCHOR, NOT THE PIVOT. `rest * CFrame.Angles(ax, 0, az)` reads
	-- like a lean and is not one. When this was written the model's pivot was
	-- the Mound, which upright() builds as a cylinder rolled ninety degrees, so
	-- the pivot's local X pointed at the sky. Measured on a live Bellchime:
	--
	--     6 deg about pivot-local X -> highest part moves 0.0821 studs
	--     6 deg about pivot-local Z -> highest part moves 0.6224 studs
	--
	-- The dominant `ax` term was spinning the plant about its own stem, which on
	-- a round head is invisible, and the only real lean was the 0.62x term at a
	-- degree or two. A bed of these was measurably swaying and visibly still.
	--
	-- The pivot is an axis-aligned plate now and that trap is gone, but the
	-- anchor stays: it is a pure translation at the ground contact, so leaning
	-- about it is a world-axis tip whatever the pivot's own orientation turns
	-- out to be. This code should not have an opinion about how the builder
	-- happens to orient its base part.
	--
	-- The anchor is a pure translation at the base, so its axes are the world's:
	-- X and Z both tip, nothing twists.
	--==========================================================================
	-- THE LEG
	--
	-- Targets are picked around HOME, never around where it currently stands.
	-- A random walk that steps from wherever it is drifts, and after ten minutes
	-- an entire bed has piled into one corner -- which is both wrong and
	-- impossible to tell from a bug. Anchoring every leg to the planted spot
	-- makes the whole thing a bounded jitter that always comes back.
	--
	-- Nothing here raycasts, and nothing here can leave the bed: the point is
	-- chosen in the SOIL's object space and clamped to its rectangle before it
	-- is ever turned into a world position.
	--==========================================================================
	local base = entry.anchor
	local moveT = 0
	local soil, rng, homeLocal = entry.soil, entry.rng, entry.homeLocal
	local from, to = entry.from, entry.to
	if soil and rng and homeLocal and from and to then
		if now >= entry.nextLeg then
			entry.from = to
			from = to
			local halfX = math.max(soil.Size.X * 0.5 - EDGE_MARGIN, 0)
			local halfZ = math.max(soil.Size.Z * 0.5 - EDGE_MARGIN, 0)
			-- Uniform over the DISC rather than over the radius -- sqrt is what
			-- stops every target clustering near the middle.
			local a = rng:NextNumber(0, math.pi * 2)
			local r = entry.radius * math.sqrt(rng:NextNumber())
			local lx = math.clamp(homeLocal.X + math.cos(a) * r, -halfX, halfX)
			local lz = math.clamp(homeLocal.Z + math.sin(a) * r, -halfZ, halfZ)
			-- Y is the home's own Y, so it stays exactly on the soil surface
			-- whatever the plot's rotation. No floor test, because there is no
			-- floor to test -- the bed is flat and this never leaves it.
			to = soil.CFrame:PointToWorldSpace(Vector3.new(lx, homeLocal.Y, lz))
			entry.to = to
			local dist = (to - from).Magnitude
			entry.legStart = now
			entry.legEnd = now + math.max(dist / entry.walkSpeed, 0.05)
			entry.nextLeg = entry.legEnd + entry.pause * rng:NextNumber(0.6, 1.6)
		end

		local span = entry.legEnd - entry.legStart
		local raw = if span > 0 then math.clamp((now - entry.legStart) / span, 0, 1) else 1
		-- Smoothstep: it leans into the step and settles out of it rather than
		-- starting and stopping at full speed like a dragged icon.
		local eased = raw * raw * (3 - 2 * raw)
		local pos = from:Lerp(to, eased)
		-- Zero at both ends of a leg and one in the middle, so the bob, the roll
		-- and the arms all fade in and out with the step. Nothing snaps on the
		-- frame a leg begins or ends, and a standing plant is perfectly still
		-- apart from its breathing.
		moveT = 4 * raw * (1 - raw)
		local stride = now * entry.strideHz
		pos += Vector3.new(0,
			math.abs(math.sin(stride * math.pi)) * entry.bob * moveT, 0)
		base = CFrame.new(pos)
		-- Rolls with the stride. The anchor is a pure translation so this is a
		-- world-axis tip, exactly like the lean it is added to.
		az += math.sin(stride * math.pi * 2) * ROLL_AMP * moveT
	end

	--==========================================================================
	-- THE LOOK-AROUND
	--
	-- The phase only advances while the plant is STANDING, which is what makes
	-- this a look-around rather than a wobble: `1 - moveT` is one when it is
	-- still, zero at the middle of a step, and smooth at both ends -- so it eases
	-- to a stop as the plant sets off and picks up again where it left off when
	-- it arrives. Nothing turns and travels at the same time.
	--
	-- Advanced by REAL elapsed time for this entry, not by frame time: apply()
	-- runs on a slice, so the gap between two visits to one plant is whatever
	-- the round robin gave it.
	--
	-- The yaw goes on the LEFT of the lean so the lean tips in the plant's own
	-- frame -- it leans the way it is looking, which is what a thing turning to
	-- look at something does.
	--==========================================================================
	local dt = math.max(now - entry.lastNow, 0)
	entry.lastNow = now
	local yaw = 0
	if not entry.pod then
		entry.lookPhase += dt * entry.lookRate * (1 - moveT)
		yaw = math.sin(entry.lookPhase) * LOOK_AMP
	end

	--==========================================================================
	-- IT FACES WHERE IT IS GOING
	--
	-- `yaw` above is the look-around and nothing else -- an oscillation about
	-- the plant's rest bearing, deliberately frozen while it travels. The
	-- direction of the LEG never entered this pivot, so a plant crossing its bed
	-- crabbed sideways or reversed into the target while still facing wherever
	-- it had last looked. The leaves swung the whole time, which made it worse:
	-- the arms said walking and the body said dragged.
	--
	-- MEASURED AGAINST THE REST BEARING, because that is what `entry.offset`
	-- applies on the right of this expression. The yaw here is a world-Y turn
	-- through the anchor, and the anchor is a pure translation -- so the number
	-- this needs is the signed angle from where the plant natively points to
	-- where the leg is going, not the heading's absolute bearing.
	--
	-- EASED, NOT ASSIGNED, and eased on a time constant rather than a fraction
	-- of a frame, so the turn takes the same real time whatever the slice gave
	-- this plant. It settles back onto the look-around when the leg is over,
	-- which is what stops the bed freezing in whatever direction it last walked.
	--
	-- The exponential never quite arrives, so a plant that is standing still is
	-- carrying a fraction of a degree of old heading forever. That is invisible
	-- and it is cheaper than a special case to zero it.
	--==========================================================================
	if not entry.pod then
		local heading = yaw
		local walking = entry.to and entry.from and now < entry.legEnd
		if walking then
			local d = (entry.to :: Vector3) - (entry.from :: Vector3)
			local flat = Vector3.new(d.X, 0, d.Z)
			-- A leg with no horizontal length has no heading to face. It can
			-- happen: the target is clamped to the soil rectangle, and a plant
			-- already against an edge can be handed its own position back.
			if flat.Magnitude > 1e-3 then
				local dir = flat.Unit
				local restLook = entry.rest.LookVector
				local restFlat = Vector3.new(restLook.X, 0, restLook.Z)
				if restFlat.Magnitude > 1e-3 then
					local ref = restFlat.Unit
					heading = math.atan2(ref:Cross(dir).Y, ref:Dot(dir))
				end
			end
		end
		-- Wrap into (-pi, pi] before easing, or a plant turning past the seam
		-- takes the long way round -- 359 degrees of spin to correct one.
		local delta = (heading - entry.facing + math.pi) % (math.pi * 2) - math.pi
		entry.facing += delta * (1 - math.exp(-dt / TURN_TAU))
		yaw = entry.facing
	end

	local target = base * CFrame.Angles(0, yaw, 0) * CFrame.Angles(ax, 0, az) * entry.offset
	entry.model:PivotTo(target)

	--==========================================================================
	-- ONE PivotTo, AND THE ARMS
	--
	-- PivotTo has already placed the leaves; these two writes then swing them
	-- about their own axes on top of it. Two extra CFrames on a fifteen-part
	-- model is a rounding error next to the pivot itself, and it is the
	-- difference between a plant that walks and a plant that slides.
	--
	-- Skipped entirely when it is standing: swing is zero there, and zero swing
	-- is exactly what PivotTo already wrote.
	--==========================================================================
	if moveT > 0.02 then
		local phase = now * entry.strideHz * math.pi * 2
		local swing = math.sin(phase) * SWING_AMP * moveT
		for _, leaf in ipairs(entry.leaves) do
			leaf.part.CFrame = target * leaf.offset * CFrame.Angles(swing * leaf.sign, 0, 0)
		end
		--======================================================================
		-- AND THE LEGS
		--
		-- Same stride the body is bobbing to, so the step and the bounce land
		-- together instead of beating against each other. Each leg carries its
		-- own phase, which is what makes the pair alternate rather than hop.
		--
		-- Guarded by the same moveT as the arms: a standing plant's legs are
		-- exactly where PivotTo just put them, and rewriting them to the same
		-- value every slice is the cost this file exists to avoid.
		--======================================================================
		for _, leg in ipairs(entry.legs) do
			local a = math.sin(phase + leg.phase) * LEG_SWING * moveT
			leg.part.CFrame = target * leg.hip * CFrame.Angles(a, 0, 0) * leg.rel
		end
	end

	--==========================================================================
	-- AND THE EYES
	--
	-- After the PivotTo, always: the pivot has just put every part back at its
	-- rest offset, so a gaze that is merely being HELD still has to be written
	-- again or the eyes snap forward on every slice.
	--==========================================================================
	local g = entry.gaze
	if g then
		local viewer = viewerPosition(now)
		local tracking = false
		if viewer then
			local face = target * g.ref
			local rel = face:PointToObjectSpace(viewer)
			local dist = rel.Magnitude
			if dist > 0.01 and dist < GAZE_RANGE then
				local d = rel / dist
				local yaw = math.atan2(-d.X, -d.Z)
				-- Only what is roughly in FRONT of the face. A plant does not
				-- roll its eyes back into its own skull to follow someone
				-- standing behind it.
				if math.abs(yaw) < math.rad(85) then
					g.tYaw = math.clamp(yaw, -GAZE_MAX, GAZE_MAX)
					g.tPitch = math.clamp(math.asin(math.clamp(d.Y, -1, 1)), -GAZE_MAX, GAZE_MAX)
					tracking = true
				end
			end
		end
		if not tracking and now >= g.holdUntil then
			-- A new fixation. Narrower in pitch than in yaw: eyes range much
			-- further side to side than up and down.
			local rng = entry.rng
			local u1 = if rng then rng:NextNumber(-1, 1) else math.random() * 2 - 1
			local u2 = if rng then rng:NextNumber(-1, 1) else math.random() * 2 - 1
			local u3 = if rng then rng:NextNumber() else math.random()
			g.tYaw = u1 * GAZE_MAX * 0.8
			g.tPitch = u2 * GAZE_MAX * 0.45
			g.holdUntil = now + GAZE_HOLD_MIN + u3 * (GAZE_HOLD_MAX - GAZE_HOLD_MIN)
		end

		local a = 1 - math.exp(-dt / (if tracking then GAZE_PURSUIT_TAU else GAZE_SACCADE_TAU))
		g.yaw += (g.tYaw - g.yaw) * a
		g.pitch += (g.tPitch - g.pitch) * a

		local cy, sy = math.cos(g.yaw), math.sin(g.yaw)
		local cp, sp = math.cos(g.pitch), math.sin(g.pitch)
		if g.pupilRig then
			-- Turn the EYEBALL and let everything on it ride, rather than
			-- placing each mark at a computed point. Same result for a single
			-- pupil, and the only thing that works for an eye wearing more
			-- than one.
			local swing = CFrame.Angles(g.pitch, g.yaw, 0)
			for _, it in ipairs(g.parts) do
				it.part.CFrame = target * (it.eyeOffset :: CFrame) * swing
					* (it.local_ :: CFrame)
			end
		else
			-- The eyes and their glints all take the same slide, in the face's
			-- own frame, so the pair stays a pair.
			local slide = CFrame.new(-sy * g.travel, sp * g.travel, 0)
			for _, it in ipairs(g.parts) do
				it.part.CFrame = target * it.offset * slide
			end
		end

		--======================================================================
		-- AND THE BLINK
		--
		-- Down fast, up slower. A symmetric blink reads as a shutter; the
		-- asymmetry is most of what makes it look like an eyelid.
		--======================================================================
		--== THE EYE CLOSES WITH IT ==--
		-- A Ball cannot be squashed, but it CAN be scaled, and an eye that
		-- shrinks as the lid arrives is what turns a plate sliding over a
		-- sphere into a blink. It also means the lid can be small: it is
		-- covering a closing eye, not a wide open one.
		if #g.lids > 0 then
			local since = now - g.blinkAt
			local t = 0
			if since >= 0 then
				if since < BLINK_DOWN then
					t = since / BLINK_DOWN
				elseif since < BLINK_DOWN + BLINK_UP then
					t = 1 - (since - BLINK_DOWN) / BLINK_UP
				else
					g.blinkAt = now + BLINK_GAP_MIN
						+ math.random() * (BLINK_GAP_MAX - BLINK_GAP_MIN)
				end
			end
			for _, it in ipairs(g.lids) do
				-- Down the EYE's own axis, not the world's, so a lid on a
				-- leaning plant still closes across its eye.
				it.part.CFrame = target * it.eyeOffset
					* CFrame.new(0, -it.drop * t, 0) * it.local_
			end
			-- Never quite to nothing: a part at zero size is a Roblox error, and
			-- a sliver left behind reads as the lash line anyway.
			--
			-- ONLY WRITTEN WHILE THE VALUE IS CHANGING. A blink is 155ms against
			-- a gap of three to seven seconds, so for about 97% of a plant's
			-- life this is a no-op -- and writing Size on six parts every slice
			-- for all of it is exactly the cost this file exists to avoid. The
			-- last value is remembered so the frame that returns to rest still
			-- gets written once.
			if t ~= g.blinkT then
				g.blinkT = t
				local k = 1 - 0.88 * t
				for _, it in ipairs(g.shrink) do
					it.part.Size = it.rest * k
				end
			end
		end
	end
end

for _, instance in ipairs(CollectionService:GetTagged(PLANTED)) do
	remember(instance)
end
table.insert(connections, CollectionService:GetInstanceAddedSignal(PLANTED):Connect(remember))
table.insert(connections, CollectionService:GetInstanceRemovedSignal(PLANTED):Connect(forget))

table.insert(connections, RunService.Heartbeat:Connect(function(dt)
	clock += dt
	local n = #list
	if n == 0 then
		return
	end
	-- How many to touch this frame to give every plant ~TARGET_HZ. Rounded up so
	-- a small bed still updates every plant every frame rather than none of them.
	--==========================================================================
	-- WHAT IS HATCHING IS NEVER SLICED
	--
	-- The round robin gives each plant about TARGET_HZ, which is plenty for a
	-- lean and nowhere near enough for a rattle -- a 27 Hz shake sampled at 20
	-- turns into a slow stagger. There is at most a handful of these at once
	-- and they are the thing the player is looking at.
	--==========================================================================
	for _, entry in ipairs(list) do
		if entry.hatching and entry.model.Parent then
			apply(entry, clock)
		end
	end

	local slice = math.min(n, math.max(1, math.ceil(n * TARGET_HZ * dt)))
	for _ = 1, slice do
		if cursor > #list then
			cursor = 1
		end
		local entry = list[cursor]
		if not entry then
			break
		end
		if not entry.model.Parent then
			-- Destroyed without the tag signal arriving first.
			forget(entry.model)
		elseif entry.hatching then
			-- Already done above, and applying twice in a frame just costs a
			-- PivotTo.
			cursor += 1
		else
			apply(entry, clock)
			cursor += 1
		end
	end
end))

--==============================================================================
-- RE-RUN SAFE
--
-- A LocalScript re-running would otherwise leave the old Heartbeat and both tag
-- signals connected, and two loops pivoting the same plants against two
-- different rest poses is a plant that shakes.
--==============================================================================
script.Destroying:Connect(function()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	for _, entry in ipairs(list) do
		if entry.model.Parent then
			pcall(function()
				entry.model:PivotTo(entry.rest)
			end)
		end
	end
	table.clear(list)
	table.clear(index)
end)
