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
local function wanderRadius(kg: number): number
	return math.clamp(6.0 / (kg ^ 0.13), 1.2, 6.0)
end

local function wanderSpeed(kg: number): number
	return math.clamp(2.6 / (kg ^ 0.17), 0.25, 2.6)
end

local function wanderPause(kg: number): number
	return math.clamp(1.2 + kg ^ 0.10, 1.4, 4.5)
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

local function lookRate(kg: number): number
	return math.clamp(0.55 / (kg ^ 0.09), 0.18, 0.75)
end

local SWING_AMP = math.rad(19)
local BOB_FRACTION = 0.035
local BOB_CEILING = 0.35
local ROLL_AMP = math.rad(3.5)

-- Roughly how often each plant is refreshed. The set is walked in slices to
-- hit this, whatever the frame rate and however many plants there are. A pod
-- that is actively hatching is exempt -- see the Heartbeat.
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
	-- The look-around. `lookPhase` ACCUMULATES rather than being derived from
	-- the clock, because it has to stop while the plant is walking and carry on
	-- from where it stopped -- a phase read straight off the clock would jump
	-- forward by however long the leg took.
	lookPhase: number,
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
		local kg = math.max(tonumber(model:GetAttribute("Kg")) or species.Kg, 0.001)

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
		local travel = math.clamp(0.75 / (kg ^ 0.16), 0.30, 0.75)
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
			speed = math.clamp(1.1 / (kg ^ 0.12), 0.35, 1.4),
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
			radius = wanderRadius(kg),
			walkSpeed = wanderSpeed(kg),
			pause = wanderPause(kg),
			rng = nil,
			from = nil,
			to = nil,
			legStart = 0,
			legEnd = 0,
			nextLeg = 0,
			-- A step lands roughly every time the plant covers a third of its
			-- own height. Small things patter, big things thud.
			strideHz = math.clamp(
				wanderSpeed(kg) / math.max(headHeight * 0.35, 0.25), 0.5, 3.2),
			bob = math.min(headHeight * BOB_FRACTION, BOB_CEILING),
			leaves = {},
			-- Off the placement id, so no two plants in a bed are looking the
			-- same way at the same moment.
			lookPhase = (tonumber(model:GetAttribute("PlacementId")) or 0) * 1.7,
			lookRate = lookRate(kg),
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
		local swing = math.sin(now * entry.strideHz * math.pi * 2) * SWING_AMP * moveT
		for _, leaf in ipairs(entry.leaves) do
			leaf.part.CFrame = target * leaf.offset * CFrame.Angles(swing * leaf.sign, 0, 0)
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
