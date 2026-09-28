--!strict
--==============================================================================
-- Steal a Seed :: ObbyData
--
-- THE FLOATING GARDEN (2026-09-27): a speed-reward obby of floating islands
-- beside the safe field. Numbers and positions only -- ObbyCourse builds it,
-- ObbyService runs it, ObbyUI moves its moving parts and draws its HUD. Every
-- position is relative to Origin, so the whole chain moves with one number.
--
--==============================================================================
-- WHERE IT IS, AND WHY THERE
--
-- Off the field's RIGHT edge (+X), between Plot 5 and Plot 6 -- measured in
-- Play (2026-09-27): six plots ring the hub with their gates at radius 100 and
-- a Level 5 plot reaches ~radius 200 on its own bearing; the road gap is the
-- 62-degree arc toward -Z; the field's back strip (+Z to 265) is the plots'
-- reserved growing room. Past X = 270 there is only sky. So the entrance sits
-- at the field's right edge, clear of every fully upgraded plot, and the
-- islands float out over the void -- nowhere near the road or its view.
--
-- The first island is 70 studs out and 30 up from the field's edge: nobody
-- walks or jumps onto the course. The Start prompt is the only way in.
--
--==============================================================================
-- MOVEMENT ON THE COURSE, FIXED
--
-- WalkSpeed 24 and JumpHeight 7.5 for everybody, whatever their Speed: a run
-- is a test of the course, not of the treadmill. At g = 196.2 that is a 13.3
-- stud flat jump, so gaps are 6 (easy), 8-9 (medium) and 10-11 (hard, the
-- challenge only). Earned Speed is never touched -- CarryService applies this
-- only while the player carries the ObbyCourse attribute, and recomputes the
-- normal speed the moment it goes.
--==============================================================================

local ObbyData = {}

-- The start island's top centre, in world space.
ObbyData.Origin = Vector3.new(330, 30, -20)

ObbyData.WalkSpeed = 24
ObbyData.JumpHeight = 7.5

-- Fall this far below your last checkpoint's floor and you are put back on it.
-- Relative to the checkpoint rather than one plane for the whole course, so a
-- slip on the summit is caught 26 studs down instead of 85: nothing walkable
-- after a checkpoint is lower than the checkpoint itself.
ObbyData.KillBelow = -26

--==============================================================================
-- WHAT THE SERVER PUBLISHES, ON THE PLAYER
--
--   Course         true from Start until Exit/Return/death -- through a
--                  finished run's wait on the summit too. CarryService fixes
--                  the walk speed on it, CombatService spares on it, ObbyUI
--                  draws the run on it.
--   Stage          the stage being run (its id), or "finished"
--   StartedAt      workspace:GetServerTimeNow() at the start
--   EndedAt        the same clock at a validated finish; nil while running
--   Route          "main", or "challenge" once the first twilight stage is done
--   Falls          how many times this run has been put back
--   RewardMain     the server-calculated reward a run would pay NOW, shown on
--   RewardChallenge  the entrance before anybody starts (not a promise: the
--                  run snapshots its own basis when it begins)
--==============================================================================
ObbyData.Attributes = {
	Course = "ObbyCourse",
	Stage = "ObbyStage",
	StartedAt = "ObbyStartedAt",
	EndedAt = "ObbyEndedAt",
	Route = "ObbyRoute",
	Falls = "ObbyFalls",
	-- Where a fall puts you back now: a key of ObbyData.Respawns.
	Checkpoint = "ObbyCheckpoint",
	RewardMain = "ObbyRewardMain",
	RewardChallenge = "ObbyRewardChallenge",
}

-- The course's folder in Workspace, and the tags on its working parts: the
-- server's ObbyCourse stamps them, every client's ObbyUI drives them.
ObbyData.FolderName = "SeedObby"
ObbyData.Tags = {
	Mover = "ObbyMover",
	Spinner = "ObbySpinner",
	Crumble = "ObbyCrumble",
	Launch = "ObbyLaunch",
	-- Scenery that drifts gently up and down (the twilight spires): a Model
	-- with ObbyBobAmp, ObbyBobPeriod and ObbyBobPhase.
	Bob = "ObbyBob",
}

-- Verbs on the GameEvent remote. Exit carries nothing; the result carries the
-- run's time and what it paid (see ObbyService.finish).
ObbyData.Actions = {
	Exit = "ObbyExit",
	Result = "ObbyResult",
}

--==============================================================================
-- THE REWARD: SECONDS OF THE PLAYER'S OWN MILL, SNAPSHOT AT THE START
--
-- The basis is TreadmillService.RateOf -- the mill tier, overclock and rebirth
-- product the belt pays at 1x -- read once when the run starts, so upgrading
-- mid-run changes nothing and the Bonus Chest's training boost (which only the
-- belt tick applies) is never in it. Paid through TreadmillService.PayReward,
-- the one Speed faucet.
--
-- WHY THESE SECONDS. A full training rush is ~315 base-rate seconds for 90 s
-- on the belt, and takes 180 s off the belt to recharge. A ~75 s main run pays
-- 90 base-seconds -- a little better than walking the belt at 1x for the same
-- time, far short of a rush -- and the rush refills while you run. So the
-- course is worth doing between rushes and while pods hatch, never instead of
-- training. The challenge route's extra ~30 s of harder play adds 60.
--==============================================================================
ObbyData.Reward = {
	MainSeconds = 90,
	ChallengeSeconds = 60,
}

--==============================================================================
-- WHAT A REAL RUN LOOKS LIKE (server validation)
--
-- Gates in order, checkpoints reached, and no faster than a body can move:
-- the whole run has a floor well under the fastest measured clear, and the
-- finish must be inside the pavilion. A run that breaks any of these ends
-- without a reward.
--==============================================================================
ObbyData.Validation = {
	-- The whole main route cannot be done faster than this. Measured
	-- 2026-09-27 with the physics bot (perfect inputs, no hesitation): 32.7 s
	-- from the start island, and it walks to every gate's centre, which a
	-- speedrunner would not -- so the floor sits well under that. The real
	-- guard against a teleport is the per-tick movement check (ObbyService);
	-- this only catches what that cannot.
	MinRunSeconds = 24,
	-- How far past a gate's radius still counts as passing it.
	GateSlack = 2,
}

-- Seconds before the same player may start again after a finish or exit.
ObbyData.ReplaySeconds = 3

--==============================================================================
-- THE ENTRANCE, ON THE FIELD (world space)
--==============================================================================
ObbyData.Entrance = {
	At = Vector3.new(246, 0, -24),
	-- Facing +X, out over the edge toward the islands.
	FacingDegrees = -90,
	PromptDistance = 12,
}

--==============================================================================
-- PALETTES: one per stage, so a screenshot of any island says which it is.
-- Grass/soil/rock form the island; `accent` and `flower` dress it; `pad` is
-- the colour of what you stand on, kept apart from anything decorative.
--==============================================================================
export type Palette = {
	grass: Color3,
	soil: Color3,
	rock: Color3,
	pad: Color3,
	accent: Color3,
	flower: Color3,
}

ObbyData.Palettes = {
	sunpetal = {
		grass = Color3.fromRGB(132, 196, 84),
		soil = Color3.fromRGB(150, 98, 60),
		rock = Color3.fromRGB(150, 138, 118),
		pad = Color3.fromRGB(98, 170, 74),
		accent = Color3.fromRGB(255, 214, 92),
		flower = Color3.fromRGB(255, 236, 140),
	},
	lilywater = {
		grass = Color3.fromRGB(104, 184, 128),
		soil = Color3.fromRGB(122, 96, 72),
		rock = Color3.fromRGB(122, 136, 140),
		pad = Color3.fromRGB(86, 176, 96),
		accent = Color3.fromRGB(120, 196, 232),
		flower = Color3.fromRGB(246, 176, 210),
	},
	rootgrove = {
		grass = Color3.fromRGB(96, 150, 78),
		soil = Color3.fromRGB(112, 76, 52),
		rock = Color3.fromRGB(108, 100, 92),
		pad = Color3.fromRGB(150, 104, 68),
		accent = Color3.fromRGB(178, 128, 82),
		flower = Color3.fromRGB(214, 236, 150),
	},
	mushroom = {
		grass = Color3.fromRGB(122, 178, 110),
		soil = Color3.fromRGB(128, 88, 70),
		rock = Color3.fromRGB(140, 124, 132),
		pad = Color3.fromRGB(236, 224, 200),
		accent = Color3.fromRGB(226, 86, 78),
		flower = Color3.fromRGB(184, 150, 222),
	},
	autumn = {
		grass = Color3.fromRGB(196, 170, 86),
		soil = Color3.fromRGB(132, 86, 56),
		rock = Color3.fromRGB(138, 118, 100),
		pad = Color3.fromRGB(232, 118, 56),
		accent = Color3.fromRGB(214, 72, 52),
		flower = Color3.fromRGB(250, 186, 70),
	},
	summit = {
		grass = Color3.fromRGB(140, 206, 110),
		soil = Color3.fromRGB(146, 96, 70),
		rock = Color3.fromRGB(160, 150, 150),
		pad = Color3.fromRGB(120, 196, 96),
		accent = Color3.fromRGB(246, 120, 150),
		flower = Color3.fromRGB(255, 196, 214),
	},
	twilight = {
		grass = Color3.fromRGB(96, 104, 176),
		soil = Color3.fromRGB(78, 70, 118),
		rock = Color3.fromRGB(92, 92, 128),
		pad = Color3.fromRGB(140, 160, 236),
		accent = Color3.fromRGB(170, 132, 240),
		flower = Color3.fromRGB(150, 226, 255),
	},
} :: { [string]: Palette }

--==============================================================================
-- THE PIECES
--
--   Island   { at, radius, depth }        walkable top at `at`; the rock under
--                                         it tapers down `depth` studs
--   Pad      { at, size, yaw? }           a static walk surface (leaf, stone,
--                                         root); `size` is X x Z, top at `at`
--   Mover    { at, size, axis, amplitude, period, phase }
--                                         a pad sliding along `axis`, driven
--                                         on every client from server time
--   Spinner  { at, length, width, degPerSecond, phase }
--                                         a log turning about its centre
--   Crumble  { at, size, yaw? }           shakes ShakeSeconds after you land,
--                                         gone GoneSeconds, then back
--   Launch   { at, radius, target, peak } a spring mushroom's cap; it throws you
--                                         onto `target`, rising `peak` studs
--                                         above it (see launchVelocity)
--   Gate     { id, at, radius }           passing it is progress (server)
--   Checkpoint { id, at, facing }         where a fall puts you back
--==============================================================================
-- How long a falling leaf warns before it drops, and how long it stays gone.
-- A stage may shorten the warning with `crumbleShake` (the twilight route's
-- "leaves that will not wait").
ObbyData.Crumble = { ShakeSeconds = 0.8, GoneSeconds = 3 }
ObbyData.PadThickness = 1.2
-- A spring cap's top stands this far above its island: a step, not a jump.
ObbyData.LaunchCapRise = 0.8

export type Stage = {
	id: string,
	name: string,
	palette: string,
	islands: { any },
	pads: { any }?,
	movers: { any }?,
	spinners: { any }?,
	crumbles: { any }?,
	crumbleShake: number?,
	launches: { any }?,
	gate: { id: string, at: Vector3, radius: number },
	checkpoint: { id: string, at: Vector3, facing: number }?,
	route: string,
}

local V = Vector3.new

ObbyData.Stages = {
	--==========================================================================
	-- 1. SUNPETAL MEADOWS: leaf to leaf, under a flower arch
	--==========================================================================
	{
		id = "sunpetal",
		name = "Sunpetal Meadows",
		palette = "sunpetal",
		route = "main",
		islands = {
			{ at = V(0, 0, 0), radius = 20, depth = 22 },
			{ at = V(106, 5, 2), radius = 11, depth = 14 },
		},
		pads = {
			{ at = V(30, 1, 1), size = Vector2.new(8, 8), yaw = 12 },
			{ at = V(44, 2, 4), size = Vector2.new(8, 8), yaw = -8 },
			{ at = V(58, 3, 0), size = Vector2.new(8, 8), yaw = 20 },
			{ at = V(72, 4, 3), size = Vector2.new(8, 8), yaw = -14 },
			{ at = V(86, 5, 1), size = Vector2.new(8, 8), yaw = 6 },
		},
		gate = { id = "g1", at = V(106, 5, 2), radius = 7 },
	},
	--==========================================================================
	-- 2. LILYWATER GARDENS: a pond island, then lily pads that drift across
	--==========================================================================
	{
		id = "lilywater",
		name = "Lilywater Gardens",
		palette = "lilywater",
		route = "main",
		islands = {
			{ at = V(132, 5, 2), radius = 15, depth = 18 },
			{ at = V(214, 5, 2), radius = 14, depth = 17 },
		},
		movers = {
			{ at = V(156, 5, 2), size = Vector2.new(8, 8), axis = V(0, 0, 1), amplitude = 7, period = 5, phase = 0 },
			{ at = V(170, 5, 2), size = Vector2.new(8, 8), axis = V(0, 0, 1), amplitude = 7, period = 5, phase = 0.25 },
			{ at = V(184, 5, 2), size = Vector2.new(8, 8), axis = V(0, 0, 1), amplitude = 7, period = 5, phase = 0.5 },
			{ at = V(197, 5, 2), size = Vector2.new(8, 8), axis = V(0, 0, 1), amplitude = 7, period = 5, phase = 0.75 },
		},
		gate = { id = "cp1", at = V(214, 5, 2), radius = 9 },
		checkpoint = { id = "cp1", at = V(214, 5, 2), facing = -90 },
	},
	--==========================================================================
	-- 3. TWISTING ROOT GROVE: root walkways, then two turning logs
	--==========================================================================
	{
		id = "rootgrove",
		name = "Twisting Root Grove",
		palette = "rootgrove",
		route = "main",
		islands = {
			{ at = V(338, 11, 2), radius = 12, depth = 15 },
		},
		pads = {
			-- The walkway: roots from the checkpoint island, winding and rising.
			{ at = V(232, 5.5, 4), size = Vector2.new(14, 5), yaw = -18 },
			{ at = V(246, 6.5, 9), size = Vector2.new(14, 5), yaw = 14 },
			{ at = V(260, 7.5, 5), size = Vector2.new(14, 5), yaw = 34 },
			{ at = V(273, 8.5, -2), size = Vector2.new(13, 5), yaw = 8 },
		},
		-- SCISSORS: the two logs turn opposite ways from the same phase, so every
		-- half-turn they swing together into one straight bridge along the
		-- route, and part again. Measured with the physics bot 2026-09-27: at
		-- -24/+24 with phases 0/90 they never met, and no jump from one reached
		-- the other. At 16 x 5 the careful bot (landing 1.8 studs inside an
		-- edge) could not find the log-to-log hop in 20 s -- a 5-stud log is
		-- a beam, and this is stage 3 -- so they are broad, 18 x 7, and slower.
		spinners = {
			{ at = V(292, 9, -2), length = 18, width = 7, degPerSecond = 16, phase = 0 },
			{ at = V(314, 10, 2), length = 18, width = 7, degPerSecond = -16, phase = 0 },
		},
		gate = { id = "g3", at = V(338, 11, 2), radius = 8 },
	},
	--==========================================================================
	-- 4. MUSHROOM SPRINGS: three spring caps up to the big rest island
	--==========================================================================
	{
		id = "mushroom",
		name = "Mushroom Springs",
		palette = "mushroom",
		route = "main",
		islands = {
			{ at = V(364, 11, 2), radius = 14, depth = 16 },
			{ at = V(398, 29, 6), radius = 9, depth = 12 },
			{ at = V(428, 45, -2), radius = 9, depth = 12 },
			{ at = V(472, 50, 0), radius = 22, depth = 24 },
		},
		-- Each lands you 4.5 studs short of the next cap, so a landing is a
		-- landing and never a second launch; walking onto that cap is the choice.
		launches = {
			{ at = V(372, 11, 2), radius = 4, target = V(394, 29, 6), peak = 5 },
			{ at = V(403, 29, 6), radius = 3.5, target = V(424, 45, -2), peak = 5 },
			{ at = V(432, 45, -2), radius = 3.5, target = V(460, 50, 0), peak = 12 },
		},
		gate = { id = "cp2", at = V(470, 50, 0), radius = 10 },
		checkpoint = { id = "cp2", at = V(466, 50, 0), facing = -90 },
	},
	--==========================================================================
	-- 5. AUTUMN DRIFT: falling leaves that hold for half a second
	--==========================================================================
	{
		id = "autumn",
		name = "Autumn Drift",
		palette = "autumn",
		route = "main",
		islands = {
			{ at = V(604, 57, 0), radius = 11, depth = 14 },
		},
		crumbles = {
			{ at = V(502, 50.5, 2), size = Vector2.new(7, 7), yaw = 20 },
			{ at = V(515, 51.5, -2), size = Vector2.new(7, 7), yaw = -12 },
			{ at = V(528, 52.5, 3), size = Vector2.new(7, 7), yaw = 30 },
			{ at = V(541, 53.5, -1), size = Vector2.new(7, 7), yaw = -24 },
			{ at = V(554, 54.5, 2), size = Vector2.new(7, 7), yaw = 10 },
			{ at = V(567, 55.5, -2), size = Vector2.new(7, 7), yaw = -30 },
			{ at = V(580, 56.5, 1), size = Vector2.new(7, 7), yaw = 16 },
		},
		gate = { id = "g5", at = V(604, 57, 0), radius = 7 },
	},
	--==========================================================================
	-- 6. BLOOMHEART SUMMIT: a drifting pad, two falling leaves, the finish
	--==========================================================================
	{
		id = "summit",
		name = "Bloomheart Summit",
		palette = "summit",
		route = "main",
		islands = {
			{ at = V(690, 63, 0), radius = 26, depth = 30 },
		},
		movers = {
			{ at = V(626, 58, 0), size = Vector2.new(8, 8), axis = V(0, 0, 1), amplitude = 6, period = 4, phase = 0 },
		},
		crumbles = {
			{ at = V(640, 59.5, 2), size = Vector2.new(7, 7), yaw = 14 },
			{ at = V(653, 61, -1), size = Vector2.new(7, 7), yaw = -20 },
		},
		gate = { id = "finish", at = V(682, 63, 0), radius = 6 },
	},
	--==========================================================================
	-- CHALLENGE A: twilight -- narrower leaves on a faster sway
	--==========================================================================
	{
		id = "challengeA",
		name = "Challenge: Moonleaf Sway",
		palette = "twilight",
		route = "challenge",
		islands = {
			{ at = V(474, 52, -124), radius = 8, depth = 12 },
		},
		-- A travelling wave on a quick sway: each leaf an eighth of a sway behind
		-- the last, so the next one is never more than ~4 studs out of line and
		-- lines up with yours twice a sway. Measured 2026-09-27 with the bots:
		-- a third of a sway apart gave windows even the perfect bot often
		-- missed for twenty seconds; a fifth, at 5 x 5 or 6 x 6, still left the
		-- careful bot (landing 1.8 studs inside every edge) no hop at all.
		-- 6 x 6 against the main route's 8 x 8 lily pads; eight of them, so the
		-- twilight route is the brief's half-minute longer than the main one.
		movers = {
			{ at = V(474, 50.5, -30), size = Vector2.new(6, 6), axis = V(1, 0, 0), amplitude = 6, period = 3.4, phase = 0 },
			{ at = V(474, 50.75, -41), size = Vector2.new(6, 6), axis = V(1, 0, 0), amplitude = 6, period = 3.4, phase = 0.12 },
			{ at = V(474, 51, -52), size = Vector2.new(6, 6), axis = V(1, 0, 0), amplitude = 6, period = 3.4, phase = 0.24 },
			{ at = V(474, 51.25, -63), size = Vector2.new(6, 6), axis = V(1, 0, 0), amplitude = 6, period = 3.4, phase = 0.36 },
			{ at = V(474, 51.5, -74), size = Vector2.new(6, 6), axis = V(1, 0, 0), amplitude = 6, period = 3.4, phase = 0.48 },
			{ at = V(474, 51.75, -85), size = Vector2.new(6, 6), axis = V(1, 0, 0), amplitude = 6, period = 3.4, phase = 0.6 },
			{ at = V(474, 52, -96), size = Vector2.new(6, 6), axis = V(1, 0, 0), amplitude = 6, period = 3.4, phase = 0.72 },
			{ at = V(474, 52, -107), size = Vector2.new(6, 6), axis = V(1, 0, 0), amplitude = 6, period = 3.4, phase = 0.84 },
		},
		gate = { id = "ca", at = V(474, 52, -124), radius = 6 },
	},
	--==========================================================================
	-- CHALLENGE B: turning roots and leaves that will not wait
	--==========================================================================
	{
		id = "challengeB",
		name = "Challenge: Starroot Spiral",
		palette = "twilight",
		route = "challenge",
		islands = {
			{ at = V(612, 60, -96), radius = 9, depth = 13 },
		},
		-- The same scissors as the Root Grove's, shorter, narrower and twice as
		-- fast: they meet every 5.6 s and the window is under three.
		spinners = {
			{ at = V(496, 53, -126), length = 14, width = 5, degPerSecond = 32, phase = 0 },
			{ at = V(516, 54, -124), length = 14, width = 5, degPerSecond = -32, phase = 0 },
		},
		crumbleShake = 0.55,
		crumbles = {
			-- The first leaf a short hop off the second log's end when the logs
			-- meet (a rotating take-off carries you sideways), then the chain at an
			-- even 12.6-13 studs: one hop each, and no leaf waits for you.
			{ at = V(533, 55, -122), size = Vector2.new(5.5, 5.5), yaw = 18 },
			{ at = V(545, 56, -118), size = Vector2.new(5.5, 5.5), yaw = -22 },
			{ at = V(557, 57, -114), size = Vector2.new(5.5, 5.5), yaw = 30 },
			{ at = V(569, 58, -109), size = Vector2.new(5.5, 5.5), yaw = -16 },
			{ at = V(581, 58.5, -104), size = Vector2.new(5.5, 5.5), yaw = 22 },
			{ at = V(593, 59, -100), size = Vector2.new(5.5, 5.5), yaw = -10 },
		},
		-- The way back in: seven moonstones on the straight line from the twilight
		-- islet (612, -96) to the summit's nearest rim, 12.2 apart; the second,
		-- fourth and sixth drift three studs either side of the line.
		pads = {
			{ at = V(619.7, 60.5, -86.5), size = Vector2.new(7, 7), yaw = 20 },
			{ at = V(635.1, 61.17, -67.6), size = Vector2.new(7, 7), yaw = 8 },
			{ at = V(650.5, 61.83, -48.6), size = Vector2.new(7, 7), yaw = 12 },
			{ at = V(665.9, 62.5, -29.7), size = Vector2.new(7, 7), yaw = 16 },
		},
		movers = {
			{ at = V(627.4, 60.83, -77.0), size = Vector2.new(7, 7), axis = V(0.776, 0, -0.631), amplitude = 3, period = 4, phase = 0 },
			{ at = V(642.8, 61.5, -58.1), size = Vector2.new(7, 7), axis = V(0.776, 0, -0.631), amplitude = 3, period = 4, phase = 0.33 },
			{ at = V(658.2, 62.17, -39.1), size = Vector2.new(7, 7), axis = V(0.776, 0, -0.631), amplitude = 3, period = 4, phase = 0.66 },
		},
		gate = { id = "cb", at = V(612, 60, -96), radius = 6 },
	},
} :: { Stage }

-- The main route's gates in order, and the challenge's (between cp2 and finish).
ObbyData.MainGates = { "g1", "cp1", "g3", "cp2", "g5", "finish" }
ObbyData.ChallengeGates = { "ca", "cb" }

-- The run begins here, on the start island, facing the first leaf.
ObbyData.Start = { at = Vector3.new(-12, 0, 0), facing = -90 }

-- The finish pavilion: where the reward is shown and Replay / Return stand.
ObbyData.Finish = {
	at = Vector3.new(682, 63, 0),
	replayAt = Vector3.new(676, 63, -8),
	returnAt = Vector3.new(676, 63, 8),
}

-- The challenge route's sign, on the second checkpoint island.
ObbyData.ChallengeSign = { at = Vector3.new(474, 50, -16) }

-- World position of a course-relative point.
function ObbyData.world(p: Vector3): Vector3
	return ObbyData.Origin + p
end

--==============================================================================
-- WHERE A FALL PUTS YOU BACK, BY THE LAST CHECKPOINT REACHED
--
-- "start" until cp1; "finished" is the summit's pavilion, for a player who
-- has finished and is still up there.
--==============================================================================
ObbyData.Respawns = {
	start = { at = ObbyData.Start.at, facing = ObbyData.Start.facing },
	cp1 = { at = Vector3.new(214, 5, 2), facing = -90 },
	cp2 = { at = Vector3.new(466, 50, 0), facing = -90 },
	finished = { at = Vector3.new(674, 63, 0), facing = -90 },
}

--==============================================================================
-- A SPRING CAP'S THROW, SOLVED FROM WHERE IT MUST LAND
--
-- The data names the landing spot and how high above it the arc peaks; this
-- turns that into the one velocity that gets there, under `gravity`. ObbyUI
-- sets it and then holds the horizontal part for the whole flight, so the
-- Humanoid's own air control cannot bend the arc: every launch from a cap
-- lands on the same spot, whatever the stick is doing. Positions are feet --
-- the root rides the same height above both ends, so it cancels.
--==============================================================================
--
-- `feet` is where the thrown body actually stands on the cap; nil means the
-- cap's centre. Solving from the real spot is what makes an off-centre step
-- land on the target too, instead of up to a cap's radius beside it.
function ObbyData.launchVelocity(spec: any, gravity: number, feet: Vector3?): (Vector3, number)
	local from = feet or (ObbyData.world(spec.at) + Vector3.new(0, ObbyData.LaunchCapRise, 0))
	local to = ObbyData.world(spec.target)
	local g = math.max(gravity, 1)
	local top = math.max(to.Y, from.Y) + spec.peak
	local up = top - from.Y
	local vy = math.sqrt(2 * g * up)
	local flight = vy / g + math.sqrt(2 * (top - to.Y) / g)
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z) / flight
	return Vector3.new(flat.X, vy, flat.Z), flight
end

function ObbyData.stage(id: string): Stage?
	for _, stage in ipairs(ObbyData.Stages) do
		if stage.id == id then
			return stage
		end
	end
	return nil
end

-- Which stage a gate closes.
function ObbyData.stageForGate(gateId: string): Stage?
	for _, stage in ipairs(ObbyData.Stages) do
		if stage.gate.id == gateId then
			return stage
		end
	end
	return nil
end

return ObbyData
