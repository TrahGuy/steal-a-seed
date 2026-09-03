--!strict
-- Steal a Seed :: GameConfig
--
-- Names, capacity and map geometry. Replicated to clients, so treat everything
-- in it as public. Balance numbers do NOT live here -- seeds and plants go in
-- SeedData, biome content in BiomeData.

local GameConfig = {}

GameConfig.ProjectName = "Steal a Seed"
GameConfig.Version = "0.1.0"
GameConfig.Phase = 1

--==============================================================================
-- CAPACITY
--
-- Plots and players are ONE number. ServerMain warns at boot if
-- Players.MaxPlayers disagrees -- it is a place setting a script cannot change,
-- so the only honest thing code can do is refuse to be quiet about it.
--==============================================================================
GameConfig.MaxPlots = 6
GameConfig.MaxPlayers = 6

--==============================================================================
-- THE SHAPE OF THE MAP, AND WHY IT IS THIS SHAPE
--
-- Read off footage of the reference game rather than assumed. The first plan
-- had a hub with bases ringed around it and biomes as distant islands. That was
-- wrong, and wrong in a way that mattered.
--
-- ONE ROAD. THE FURTHER OUT, THE RARER THE SEED.
--
--     FIELD ══ FOREST ─── DESERT ─── JUNGLE ─── VOLCANO ─── COSMIC
--     (safe)    easy                                        endgame
--       ▲
--     the red line
--
-- The biomes are SEGMENTS OF ONE CORRIDOR, laid end to end, not five separate
-- lanes side by side. That single change is the whole risk curve of the game
-- expressed as geometry:
--
--   * Distance IS difficulty. Nothing has to be explained -- the rarer seed is
--     visibly further away, and you can see how far.
--   * THE RUN HOME GETS LONGER AS THE PRIZE GETS BETTER. A Cosmic seed is
--     1,500 studs from safety through every other biome. That is the entire
--     risk/reward of the game and it costs nothing to implement, because it is
--     just where the walls are.
--   * Everyone shares one road, so PvP happens on the way past rather than
--     having to be arranged. Five parallel lanes let players miss each other
--     completely.
--   * A speed gate at each boundary is a door on the road you are already
--     running down, not a menu of five destinations.
--
-- Pods sit ALONG THE WALLS, never in the middle. Grabbing one costs you the
-- racing line, which is a real decision when somebody is behind you.
--
-- Everything is derived from FieldWidth, FieldDepth, CorridorWidth and
-- SegmentLength. Moving the whole map is editing GroundY.
--==============================================================================
GameConfig.Map = {
	FolderName = "SeedMap",
	FieldName = "TheField",
	PlotsFolderName = "Plots",
	LanesFolderName = "Lanes",
	PropsFolderName = "Props",

	-- World Y of the field's walking surface. Everything is derived from it.
	GroundY = 0,

	-- The shared safe field.
	--
	-- ASYMMETRIC, AND THAT IS THE WHOLE EXPANSION STORY. The field is measured
	-- separately in each direction from the origin:
	--
	--   FieldFront  toward the road. TIGHT ON PURPOSE -- an early build put the
	--               plots 246 studs from the road and every run began and ended
	--               with a long walk across empty grass. Dead time, and the
	--               first thing a new player experiences. This number is the one
	--               that must never grow.
	--   FieldBack   away from the road. DELIBERATELY OVERSIZED. It is empty
	--               grass today and it is reserved room for plots to grow into.
	--
	-- Plots ring the hub (see THE RING below) and grow OUTWARD from it. Their
	-- gates all sit on one radius, so expanding a plot never moves the point its
	-- owner walks in through -- the same property an earlier row layout got from
	-- a fixed front edge, kept through the change of shape.
	FieldWidth = 540,   -- X
	FieldFront = 170,   -- Z toward the road
	FieldBack = 265,    -- Z away from it
	FieldThickness = 6,

	--==========================================================================
	-- THE RING
	--
	-- Plots are arranged around a central hub rather than in a row, from the
	-- owner's second sketch. It is a better shape and the reason is expansion:
	--
	--   A RING GIVES MORE ROOM THE FURTHER OUT YOU GROW. Plots expand OUTWARD,
	--   so their inner edges never move and the gaps between them there never
	--   change -- while the arc at their outer edge gets longer as the radius
	--   does. A row can only expand into space reserved up front; a ring makes
	--   room as it goes.
	--
	-- It also puts the hub the same distance from every plot, which a row never
	-- did: in a row the end plots were 145 studs from the centre and the middle
	-- ones were 29.
	--
	-- HubRadius is the shop circle in the middle. PlotRingInner is where every
	-- plot's GATE sits -- identical for all of them, at every tier.
	--==========================================================================
	HubRadius = 46,
	PlotRingInner = 100,
	-- The arc left empty for the road, centred on the road's own axis. Nothing
	-- is built inside it.
	RoadGapDegrees = 62,

	-- THE RED LINE. A stripe painted flat on the grass at the field's far edge
	-- with SAFE ZONE written on it. Not a dome, not a forcefield, not a
	-- billboard -- the reference game uses a floor decal and it is readable at
	-- thirty studs while sprinting, which is the entire requirement. Anything
	-- fancier is worse at the only job it has.
	SafeLineThickness = 2.5,
	SafeLineColor = Color3.fromRGB(226, 58, 58),

	-- The road. One corridor, five segments long.
	CorridorWidth = 140,
	-- Per biome. Five of these end to end is the whole journey, so this number
	-- is the pacing of the entire game: how long a Forest round trip takes at
	-- WalkSpeed 16, and how long a Cosmic one takes at 150.
	SegmentLength = 300,
	WallHeight = 46,
	WallThickness = 10,
	-- How far a pod sits in from the wall. Far enough to walk behind, close
	-- enough that stepping out to it visibly costs you the middle.
	PodInset = 26,

	OverflowSpawnName = "OverflowSpawn",
	SellStandName = "SellStand",
}

--==============================================================================
-- A PLOT
--
-- Sits ON the field behind a low fence, exactly as the reference does. The
-- fence is decoration and a property line -- it is deliberately NOT collidable,
-- because a player sprinting home at WalkSpeed 120 who clips a fence post and
-- stops dead has been robbed by the scenery.
--==============================================================================
GameConfig.Plot = {
	NamePrefix = "Plot_",
	-- Width never changes. Only depth does -- see Tiers.
	Width = 48,
	-- There is no FrontZ any more. It was the row layout's anchor -- one world Z
	-- every plot's front edge sat on -- and on a ring the anchor is a RADIUS
	-- (Map.PlotRingInner) which every gate sits at instead. Keeping a dead
	-- coordinate around is keeping a number that looks authoritative and is not.
	-- Kept for the fit check. Plots are on a ring now, so this is no longer what
	-- spaces them -- the angle is -- but two plots closer together than this
	-- would still be too close, and MapService checks the arc against it.
	Pitch = 58,

	FloorName = "Ground",
	-- The soil part. It says "Soil" because that is what MapService actually
	-- names it -- this said "Planter" while the part was called Soil, and only a
	-- fallback in PlantService hid the mismatch.
	PlanterName = "Soil",
	TreadmillName = "Treadmill",
	SpawnPadName = "SpawnPad",
	RuntimeFolderName = "Runtime",
	PlantsFolderName = "Plants",

	-- THE GAP IN THE FRONT FENCE.
	--
	-- The fence encloses all four sides, and without this there was no way IN --
	-- not physically, since the fence is non-collidable and you walk through it,
	-- but visually, which is the part that matters. A fully sealed rectangle
	-- reads as a pen. A gap with two taller posts either side reads as a garden
	-- gate, and it tells a player where their plot begins without a word.
	--
	-- It faces the road, so the opening is on the side every run comes home
	-- through -- you arrive at your gate rather than at the back of a fence.
	GateWidth = 13,

	SpawnHeightOffset = 4,

	--==========================================================================
	-- THE BED
	--
	-- ONE continuous bed of soil inside a raised wooden border, from the owner's
	-- photo reference. An earlier version split it into two framed blocks with
	-- visible row divisions; the reference is a single plain rectangle and it is
	-- the better read -- soil is soil, and drawing rows on it before anything
	-- grows there is labelling an empty field.
	--
	-- The grid still exists, it is just invisible: plant slots are laid out
	-- Columns x rows across the surface. A ROW IS STILL A SLOT ROW, so the plant
	-- count and the bed's depth cannot drift apart.
	--
	-- ELEVATION IS 0.5. It was 2.2, which made every plot a platform you climbed
	-- rather than a bed set into the lawn.
	--==========================================================================
	BedColumns = 3,
	RowDepth = 11,
	RowGap = 1.2,
	-- Grass between the bed's FRAME and the fence.
	BedMargin = 6,
	BedInsetX = 5,
	-- How far the soil surface stands above the grass, and how far the wooden
	-- border stands above the soil. Both deliberately small: the border only has
	-- to read as an edge, not as a wall.
	BedHeight = 0.5,
	BedFrameLip = 0.25,
	BedFrameWidth = 2,

	--==========================================================================
	-- THE SIDE BED: ROOM, NOT CAPACITY
	--
	-- From Level 3 a plot grows a wing on ONE side. It holds a second bed and
	-- adds no slots whatsoever -- capacity stays 10 / 15 / 20 and lives in
	-- PlotTiers. This is floor space for twenty walking creatures, which a
	-- single 34-stud strip does not have.
	--
	-- ALWAYS THE SAME LOCAL SIDE, on every plot. Two neighbours flaring toward
	-- each other would meet in the gap between them; flaring the same way makes
	-- every wing point into the gap its neighbour just vacated, and the whole
	-- ring stays evenly spaced.
	--
	-- REAR-ANCHORED, which is what makes it fit at all. Plots sit on a ring, so
	-- the arc between two of them GROWS with distance from the hub: the chord
	-- between neighbouring centre lines is 0.84 * r, which is 84 studs at the
	-- gate and 165 at the back of a Level 5 plot. The wing starts where that
	-- extra room actually exists and the front edge never widens -- the gate
	-- stays exactly as narrow as it was, so nothing changes at the ring radius
	-- where the plots are tightest.
	--
	-- Rows here are PHYSICAL rows of soil. They are deliberately fewer than the
	-- main bed's at the same level, because the wing is shorter than the plot
	-- is deep -- it starts behind the gate, not at it.
	--==========================================================================
	SideBed = {
		-- How much wider the plot gets, on the +X local side.
		--
		-- WIDE RATHER THAN LONG, and that is the treadmill's doing. Measured in
		-- Edit, every plot's mill occupies local X 24.6 to 43.8 at Z -43.4 to
		-- -19 -- the same side as this wing, in the plot's front half. A wing
		-- reaching forward past Z = -19 fenced the mill in: the first build of
		-- this came out with 0.93 studs between plot and treadmill.
		--
		-- So the wing starts BEHIND the mill and takes its area back across
		-- instead. Sideways is the direction with room -- the ring's arc grows
		-- with radius and the neighbour clearance measured 26.7 studs at 28
		-- wide, which is slack this can spend.
		WingWidth = 40,
		-- Grass inside the wing's fence before the bed's frame starts.
		WingMargin = 3,
		--==================================================================
		-- THE WING'S FENCE MAY NOT REACH FORWARD OF THIS
		--
		-- The mill's rear face is at local Z = -19. This is that, plus room to
		-- walk between the two, and it is what caps the row counts below.
		--==================================================================
		WingFrontZ = -15,
		-- Physical soil rows per level. Nothing below Level 3 has a wing.
		--
		-- Rear-anchored and capped by WingFrontZ, which is why these are 2/3/4
		-- rather than the 2/4/7 a plot with no mill beside it could carry:
		-- at Level 5 the bed may span 52.1 studs and five rows need 59.8.
		RowsByLevel = { 0, 0, 2, 3, 4 },
		-- Named so PlantService can find it, and so a save can say where a
		-- plant stands without the name being a position.
		Name = "SoilSide",
	},
	--==========================================================================
	-- THE FENCE IS A REAL BOUNDARY NOW
	--
	-- It was non-collidable throughout, on the reasoning that "the gap is not
	-- what lets you in -- you could always walk through the rails. It is what
	-- SHOWS you the way in, and a sealed rectangle read as a pen rather than as
	-- a garden." Asked to make it solid, so it is: the gate is now the way in
	-- because it is the ONLY way in.
	--
	--======================================================================
	-- THE FENCE IS THE FENCE, AND THERE IS NO INVISIBLE SLAB
	--
	-- FenceColliderThickness and FenceColliderHeight lived here, sizing a pane
	-- down the middle of each run: the rails were decoration and that pane did
	-- the stopping, eleven studs tall so it was ABOVE A JUMP.
	--
	-- The worry behind it was sound -- a 0.6 stud rail is thinner than one
	-- frame of travel at high WalkSpeed, so a sprinting player would pass
	-- through a merely-collidable one. But the answer to that is a thicker
	-- fence, not an invisible wall, and the wall cost something real: you could
	-- not hop your own fence.
	--
	-- MapService now builds two 1.6-stud boards topping out at 5.0. Wider than
	-- a frame of travel up to about 96 WalkSpeed, and low enough to jump. If a
	-- corner ever gets clipped, thicken the board there -- do not bring the
	-- pane back.
	--======================================================================

	--==========================================================================
	-- THE BED IS TILLED, NOT PAINTED
	--
	-- The soil was ONE PART in ONE COLOUR: a 34 x 121 stud slab of flat brown at
	-- the biggest tier, which is the largest single surface a player looks at in
	-- this game and had less going on than the grass beside it.
	--
	-- The rows already exist in the data -- RowDepth and RowGap have decided
	-- where plants stand since the first build -- and nothing drew them. So the
	-- gaps become FURROWS: a darker strip, set slightly below the surface, one
	-- per gap. That is the bed's own structure made visible rather than a
	-- texture invented on top of it, which is why it lines up with the planting
	-- for free and keeps lining up if the rows are ever retuned.
	--
	-- CLODS in the furrows on top of that, for small-scale break-up. In the
	-- furrows specifically because plants stand in row CENTRES -- a clod there
	-- would end up inside somebody's Bellchime.
	--
	-- COUNTED, because this game is mobile-first and the bed is not the budget:
	-- a four-row plot gains 3 furrows and 4 clods, a ten-row plot 9 and 10. At
	-- six plots of the largest tier that is 114 parts against a 1,563-part map.
	--==========================================================================
	--======================================================================
	-- THE ROWS ARE RAISED, THE GAPS ARE WHAT IS LEFT
	--
	-- The first attempt SANK a darker strip into the gaps and it was invisible:
	-- the soil is one opaque slab and a part below its surface is simply inside
	-- it. Nothing showed but the clods.
	--
	-- So it is the other way up, which is also how a real bed is built. The slab
	-- itself is darkened to the furrow tone and never moves -- PlantService
	-- derives every plant's height from `soil.Size.Y * 0.5`, so touching its size
	-- or its CFrame would lift or sink every garden in the game. The ROWS are
	-- added on top in the lighter earth, and the dark base showing between them
	-- IS the furrow. Real relief, no z-fighting, and nothing planted moves.
	--
	-- A plant therefore stands 0.18 below the crown of its own row. On a
	-- creature between 1.2 and 33 studs tall that is not a thing anybody can
	-- see, and it is the price of not moving the surface the save is measured
	-- against.
	--======================================================================
	SoilRowRise = 0.18,
	SoilClodsPerFurrow = 2,
	-- Every other furrow gets clods. All of them read as gravel rather than as
	-- broken earth.
	SoilClodStride = 2,
	SoilClodSize = 1.1,
}

--==============================================================================
-- PLOT TIERS
--
-- THE SYSTEM THAT SPENDS THESE IS PHASE D. THE SPACE THEY NEED IS RESERVED NOW,
-- and that ordering is not laziness in one direction or over-engineering in the
-- other -- it is the only order that works.
--
-- An upgrade button is a day's work whenever it is wanted. Plot GEOMETRY is
-- not: pitch, field size and the fixed front edge are baked into the map, and
-- a plot that has to grow with no room reserved forces every other plot to
-- move. Everybody's saved plot id then points at a different patch of ground.
--
-- So the tiers are decided today and only tier 1 is built. `MapService` reads
-- `depth` from here, so shipping tier 2 is changing a player's stored tier
-- number and rebuilding their plot -- no map surgery, no repacking the row.
--
-- Depth grows, width never does. Six long strips side by side is what an
-- allotment actually looks like, which is a happy accident of the constraint
-- that keeps the run home constant.
--
-- Slot counts are a first pass and will move once a plant model exists and
-- there is something real to space.
--==============================================================================
-- ROWS, not depth. Depth is derived from them, so a tier cannot be defined with
-- a size that does not fit a whole number of beds.
--==============================================================================
-- AND WHAT EACH ONE COSTS
--
-- `cost` is what the SHOP charges to move UP to that tier, in cash. Tier 1 is
-- where everybody starts, so its cost is 0 and is never shown.
--
-- FIRST-PASS NUMBERS, NOT TUNED. They are here because a shop cannot be drawn
-- without prices, and a placeholder in the data file is honest where a
-- placeholder buried in UI code would not be. Rough shape: each tier is about
-- ten times the last, so the first one is reachable in a session and the last
-- one is a goal.
--
-- For scale: one grown Nubkin pays 2/sec and one Bellchime pays 110/sec, so a
-- starting plot of twelve mixed plants is somewhere around 100-400/sec.
--==============================================================================
--==============================================================================
-- CAPACITY IS WRITTEN DOWN, NOT DERIVED
--
-- It used to be `rows * BedColumns` -- the invisible planting grid doubling as
-- the gameplay limit. That tied two things that have no business moving
-- together: how DEEP the plot looks and how MANY plants it holds. Widening the
-- bed by a column would silently have handed every player in the game three
-- more slots per row, and a ladder nobody can read off the table is a ladder
-- nobody can balance.
--
-- So `capacity` is the number, `rows` is the geometry, and the two are allowed
-- to disagree. Level 5 is seven rows for twenty plants precisely because the
-- plot has to LOOK like the biggest one without the count following the grid.
--
-- A planted pod and a grown creature each take one space. A creature being
-- carried takes none -- it is not in the ground.
--==============================================================================
GameConfig.PlotTiers = {
	{ capacity = 5,  rows = 2, cost = 0 },
	{ capacity = 7,  rows = 3, cost = 25000 },
	{ capacity = 10, rows = 4, cost = 250000 },
	{ capacity = 15, rows = 5, cost = 2500000 },
	{ capacity = 20, rows = 7, cost = 25000000 },
}

--==============================================================================
-- WHAT VERSION 1 PLOTS WERE, KEPT FOR THE MIGRATION AND NOTHING ELSE
--
-- The old ladder was four levels of 4, 6, 8 and 10 rows, and capacity came out
-- of `rows * 3`. A saved garden's Z coordinates were measured against THAT
-- plot's depth, so migrating a profile needs the old depth to convert them --
-- see ProfileSchema. Nothing else may read this.
--==============================================================================
GameConfig.LegacyPlotRowsV1 = { 4, 6, 8, 10 }

-- What a plot is built at before anything is bought.
GameConfig.StartingPlotTier = 1

--==============================================================================
-- ONE ACTION NAME, AND THE CLIENT SENDS NOTHING ELSE
--
-- The Shop fires GameEvent with this and no payload worth forging: not a level,
-- not a price, not a plot id. The server reads the sender -- which is
-- engine-stamped -- looks up what they own, and decides everything. A client
-- that could name its own target level could buy Level 5 for the price of two.
--==============================================================================
GameConfig.PlotUpgradeAction = "PlotUpgrade"

GameConfig.Attributes = {
	PlotId = "PlotId",
	OwnerUserId = "OwnerUserId",
	-- The owner's NAME as well as their id, so a client can label a plot without
	-- a GetNameFromUserIdAsync round trip per plot. Attributes replicate on
	-- their own, so this is also why "who owns this" needs no remote.
	OwnerName = "OwnerName",
	Claimed = "Claimed",
	BiomeId = "BiomeId",
	-- Phase A+
	-- What the player is holding. Set on the PLAYER, not the character, so it
	-- survives a respawn boundary and replicates to every client for free --
	-- the prompt UI reads it to decide whether to draw itself at all.
	--
	-- These were "CarryingSeed" here while CarryService wrote CarryingSpecies
	-- and CarryingKg. Two names for one fact is a bug waiting for whoever trusts
	-- the wrong one.
	CarryingSpecies = "CarryingSpecies",
	CarryingKg = "CarryingKg",
	--==========================================================================
	-- WHICH LEFT-RAIL PANEL IS OPEN, IF ANY
	--
	-- The Index and the Shop both dock on the LEFT and both are full height, so
	-- they occupy the same rectangle and cannot both be open. Rather than have
	-- one script reach into the other's ScreenGui, each writes its own name here
	-- when it opens and clears it when it closes, and each closes itself when it
	-- sees a name that is not its own.
	--
	-- The Garden is deliberately NOT part of this. It docks on the RIGHT, it
	-- never overlaps either of them, and being able to read your own dirt while
	-- looking at a shop price is the point of having two rails.
	--==========================================================================
	OpenPanel = "OpenPanel",
	-- Bumped every time a pod is banked at the red line. A COUNTER rather than a
	-- flag, because two banks in a row have to be two events -- setting a flag
	-- true twice changes nothing and the second one would go unnoticed. The
	-- client watches it to tell "I made it" apart from "I lost it", which from
	-- the client's side otherwise look identical: CarryingSpecies goes nil.
	BankedCount = "BankedCount",
	SeedInstanceId = "SeedInstanceId",
	InSafeZone = "InSafeZone",
	-- Set while the owner is standing on their own mill and earning. On the
	-- PLAYER, so it replicates to everybody for free -- which is what lets each
	-- client play the run cycle on somebody else's character without a remote.
	OnTreadmill = "OnTreadmill",
	--==========================================================================
	-- WHAT TRAINING RUSH IS DOING, PUBLISHED READ-ONLY
	--
	-- The multiplier the SERVER actually paid on, and the rested charge left, so
	-- the HUD can show both without computing either. A client that derived them
	-- would be a client that could disagree with its own payout -- and one that
	-- could be talked into showing 4x forever.
	--
	-- On the player, written only when the rounded value changes, so a training
	-- session is a handful of replications rather than one per tick.
	--==========================================================================
	TrainingRush = "TrainingRush",
	TrainingCharge = "TrainingCharge",
	--==========================================================================
	-- PARKED ON YOUR OWN MILL
	--
	-- Set by TreadmillService when it catches a player crossing their belt, read
	-- by CarryService to hold them at a standstill. On the PLAYER rather than the
	-- character so it survives nothing in particular -- a respawn clears the mount
	-- anyway -- but so that every client can see who is training without a remote.
	--==========================================================================
	MillMounted = "MillMounted",
	--==========================================================================
	-- HOW FAST THIS PLAYER LOOKS, TO EVERY OTHER CLIENT
	--
	-- 0 for a trail only, 1..3 for the afterimage tiers. An ATTRIBUTE and not a
	-- number in the profile packet, because the client that has to draw your
	-- ghosts is everybody ELSE'S -- and their clients must never be handed your
	-- profile to find out you are fast.
	--
	-- One small integer, replicated by the engine, meaningless on its own.
	--==========================================================================
	SpeedVisualTier = "SpeedVisualTier",
	--==========================================================================
	-- HOW MUCH THE LOAD IS COSTING THEM, 0.30 TO 1
	--
	-- Exactly the multiplier CarryService applies to WalkSpeed, published so the
	-- afterimage can dim and thin itself on somebody ELSE'S screen. Server-owned
	-- and never re-derived on the client: a client that computed this from a
	-- replicated weight is a client that could lie about it, and the entire
	-- purpose is that running home rich cannot be made to look fast.
	--==========================================================================
	CarrySpeedMultiplier = "CarrySpeedMultiplier",
	--==========================================================================
	-- THE DEEPEST BIOME THIS PLAYER HAS EVER EARNED
	--
	-- Published so the client can grey a gate it cannot pass and say what it
	-- wants, without a remote and without being trusted: the SERVER decides who
	-- crosses, and this is only what the HUD reads.
	--==========================================================================
	HighestBiomeOrder = "HighestBiomeOrder",
	--==========================================================================
	-- THE WORLD CLOCK, ON THE WORKSPACE
	--
	-- Three read-only facts every client and every service reads the same way.
	-- On the WORKSPACE rather than on a player, because they are true of the
	-- world and not of anybody in it -- and because that makes a late joiner
	-- correct on their first frame without being sent anything.
	--
	-- A client writing these changes only its own view; nothing on the server
	-- ever reads them back off a client.
	--==========================================================================
	WorldPhase = "WorldPhase",
	WorldPhaseEndsAt = "WorldPhaseEndsAt",
	WorldCycleIndex = "WorldCycleIndex",
}

GameConfig.Tags = {
	Plot = "Plot",
	PlotSpawn = "PlotSpawn",
	Planter = "Planter",
	Treadmill = "Treadmill",
	PlantSlot = "PlantSlot",
	SafeZone = "SafeZone",
	Lane = "Lane",
	WildPatch = "WildPatch",
	SeedPod = "SeedPod",
	BiomeGate = "BiomeGate",
	-- A pod in somebody's hands. Tagged separately from SeedPod because a pod on
	-- the road is scenery you may take and a pod being carried is a target.
	CarriedPod = "CarriedPod",
	-- Planted and growing, or grown. Built and tagged by the server, SWAYED by
	-- each client -- same split as the fairy, and the reason a creature costs
	-- roughly what a plant costs.
	Creature = "Creature",
	-- Built and tagged by the server, MOVED by each client. See HubFairy.
	Fairy = "Fairy",
	-- The nest guardian. Unlike everything else that moves for decoration, this
	-- one is server-simulated: it chases, and a chase every player sees in a
	-- different place is not a chase.
	NestParent = "NestParent",
	-- GROWING IN SOMEBODY'S PLOT. The opposite of SeedPod, and the reason both
	-- exist: a pod in a nest is loot, and the identical model standing in a plot
	-- is somebody's property mid-hatch. Nothing tagged Planted is ever takeable,
	-- and CarryService refuses it even if a stale prompt survives on it.
	Planted = "Planted",
	-- One arrow painted on a treadmill belt. Server builds them where they
	-- belong; each client scrolls its own copies, same split as the fairy.
	MillChevron = "MillChevron",
	--==========================================================================
	-- THE REST OF THE MILL'S MOVING PARTS
	--
	-- Same split as the chevrons and the fairy: the SERVER builds them, each
	-- CLIENT moves them. A roller turning is paint, and paint replicated sixty
	-- times a second from six plots is the single most expensive thing this game
	-- could decide to do.
	--==========================================================================
	--==========================================================================
	-- THE TREADS
	--
	-- The thing that actually makes a treadmill read as one. Arrows painted on a
	-- surface say "this is meant to move"; slats sliding under your feet say it
	-- is moving. Scrolled by the same client clock the chevrons use.
	--==========================================================================
	MillSlat = "MillSlat",
	MillRoller = "MillRoller",
	-- Turns the other way from whatever it is geared to, at its own ratio.
	MillGear = "MillGear",
	-- An arm driven off the belt: goes round, so the mill has something with a
	-- stroke to it rather than only things that spin.
	MillCrank = "MillCrank",
	-- Cloth. Sways on its own slow cycle whether or not anybody is training,
	-- because a flag in a garden does.
	MillBanner = "MillBanner",
	-- Neon that breathes. Slow and shallow when idle, quick and bright under
	-- load -- which is most of how a premium mill says somebody is on it.
	MillPulse = "MillPulse",
	MillWheel = "MillWheel",
	MillLeaf = "MillLeaf",
	MillSign = "MillSign",
	MillJaw = "MillJaw",
	MillHolo = "MillHolo",
	MillWing = "MillWing",
	-- An empty marker MapService leaves behind saying "a nest belongs here".
	-- NestService builds the actual nest on top of it, because a nest has state
	-- and the map deliberately has none.
	NestSite = "NestSite",
	-- The shutter across the mouth of the road. Tagged rather than found by
	-- name because MapService rebuilds the whole map and the cycle service must
	-- find whichever barrier exists now, not the one that existed at boot.
	NightBarrier = "NightBarrier",
}

--==============================================================================
-- THE DEBUG CONSOLE, AND WHO IS ALLOWED TO OPEN IT
--
-- This tool sets Speed and Cash directly. In a game whose entire progression IS
-- Speed and Cash, that is not a convenience -- it is every exploit at once, in
-- one RemoteEvent. So the gate is the feature.
--
-- ALLOWED: anyone in Studio (which is a private session by definition), and the
-- place owner on a live server. Nothing else, ever. The check runs on the SERVER
-- before the payload is even read: a client that hides the panel is a courtesy,
-- and a rule enforced only on the client is not a rule.
--
-- UserIds is for a trusted tester who is not the owner. It is deliberately empty
-- rather than pre-filled -- an id in here is a person who can mint themselves a
-- quadrillion, and that should be a decision somebody typed on purpose.
--
-- A GROUP-OWNED PLACE has a CreatorId that is the GROUP, not a person, so the
-- owner check cannot match anybody. Put the ids in UserIds if this game ever
-- moves to a group.
--==============================================================================
GameConfig.Debug = {
	Enabled = true,
	UserIds = {} :: { number },
	-- Opens and closes the panel. F4 rather than a letter, so it cannot fire
	-- while somebody is typing into a text box.
	ToggleKey = "F4",
}

GameConfig.Remotes = {
	PlotAssigned = "PlotAssigned",
	-- The debug console. Created like every other remote, and REFUSED like no
	-- other: DebugService drops anything from a player who is not the owner
	-- and not in Studio, before it looks at the payload at all.
	DebugCommand = "DebugCommand",
	ProfileUpdated = "ProfileUpdated",
	-- Sent once when a profile is ready, or when it could not be loaded. A
	-- client that never hears this must not pretend the player has 0 cash --
	-- that is indistinguishable from a real new account.
	ProfileReady = "ProfileReady",
	CarryStateChanged = "CarryStateChanged",
	-- The parent's hit. Server -> victim: a direction and a speed. Victim ->
	-- server: "I have stopped."
	--
	-- It has to be a message rather than the server just applying the impulse,
	-- because a player's character is simulated by THAT PLAYER. A velocity
	-- written on the server is overwritten by the owner's next update, which is
	-- exactly what made the first ragdoll invisible.
	ThrowVictim = "ThrowVictim",
	DropSeedRequest = "DropSeedRequest",
	-- Server -> client. Fired when the player enters a non-starter biome so the
	-- HUD can show that biome's advisory Speed target.
	BiomeRecommendation = "BiomeRecommendation",
	GameEvent = "GameEvent",
}

--==============================================================================
-- RARITY
--
-- Canonical order, index = tier. Everything that sorts, colours or compares
-- rarity reads this, so there is one place where "is Epic above Rare" is
-- answered.
--==============================================================================
GameConfig.Rarities = {
	"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Divine",
}

local rarityTier: { [string]: number } = {}
for index, name in ipairs(GameConfig.Rarities) do
	rarityTier[name] = index
end
GameConfig.RarityTier = rarityTier

-- Sampled off the pod artwork rather than picked, so the pods in the world are
-- the pods that were designed. The first five are the ones the reference sheet
-- actually shows; the last three follow its logic outward.
GameConfig.RarityColor = {
	Common    = Color3.fromRGB(238, 235, 226),
	Uncommon  = Color3.fromRGB(142, 196, 62),
	Rare      = Color3.fromRGB(108, 168, 214),
	Epic      = Color3.fromRGB(146, 62, 158),
	Legendary = Color3.fromRGB(250, 198, 48),
	Mythic    = Color3.fromRGB(232, 92, 132),
	Secret    = Color3.fromRGB(120, 240, 236),
	Divine    = Color3.fromRGB(255, 246, 194),
}

--==============================================================================
-- SPEED
--
-- SPEED IS A SCORE. WalkSpeed IS A CURVE. This is an engine constraint, not a
-- balance preference: Roblox character physics degrades badly past roughly 200
-- studs/second -- characters tunnel through thin geometry, network ownership
-- thrashes as the humanoid outruns its own replication, and the camera cannot
-- keep up.
--
-- The reference game's live leaderboard showed a player at 3.2 BILLION Speed.
-- That number can never reach WalkSpeed. So it does not: the score feeds a
-- curve, the player watches an unbounded number climb, and the simulation never
-- sees past MaxWalkSpeed.
--
--==============================================================================
-- MILESTONES, NOT AN ASYMPTOTE
--
-- It was `Base + (Max - Base) * (1 - e^(-Speed / Scale))` with Scale = 20,000.
-- That is a fine shape and completely the wrong RANGE for this game. Measured
-- against the ladder it was supposed to serve:
--
--     Speed        150,000   ->  WalkSpeed 149.99
--     Speed    167,000,000   ->  WalkSpeed 150.00   <- Dustbowl target
--     Speed 10,000,000,000   ->  WalkSpeed 150.00   <- Starbloom target
--
-- The curve finished before the FIRST biome recommendation. Every biome, every
-- mill tier above the third, and the entire billions ladder the game is built
-- around all landed on the same 150 -- so the one stat the whole game grinds
-- stopped changing anything a player could feel, four orders of magnitude
-- before the content did.
--
-- ANCHORS FIX THAT BY BEING A DESIGN STATEMENT RATHER THAN A SHAPE. Each pair
-- below is "at this score, you move this fast", and the biome recommendations
-- are ON the list -- 167M is 42, 800M is 54, 3B is 68, 10B is 82. Reaching a
-- recommendation is worth a visible step because its number also moves the
-- legs faster.
--
-- INTERPOLATED IN LOG SPACE, because the score is logarithmic and linear
-- interpolation between 1M and 167M would leave 99% of that span in the last
-- few walk-speed points. log(x + 1) rather than log(x), so the zero anchor
-- needs no special case.
--
-- MONOTONIC BY CONSTRUCTION: both columns strictly increase and log
-- interpolation between two increasing points cannot dip. More speed is never
-- slower, which is the one property that must survive any retune.
--
-- To retune, move a row. Do not add a formula.
--==============================================================================
GameConfig.Speed = {
	BaseWalkSpeed = 16,
	MaxWalkSpeed = 150,

	--==========================================================================
	-- { Speed score, WalkSpeed }
	--
	-- Must stay sorted and strictly increasing in BOTH columns. The last row is
	-- the cap and must equal MaxWalkSpeed; the first must equal BaseWalkSpeed.
	-- Verified on load below, because a typo here is a game that silently walks
	-- backwards at one particular score.
	--==========================================================================
	Anchors = {
		{ 0, 16 },
		{ 1e3, 22 },
		{ 1e4, 27 },
		{ 1e6, 32 },
		-- The long climb from 1M to Dustbowl is the emptiest stretch on the
		-- ladder, so it gets a waypoint of its own: 100M is a round number a
		-- player passes on the way and a visible +8 for having done it.
		{ 100e6, 40 },
		--== the biome recommendations ==--
		{ 167e6, 42 },
		{ 800e6, 54 },
		{ 3e9, 68 },
		{ 10e9, 82 },
		--== past the last recommendation, where the idle game actually lives ==--
		{ 100e9, 96 },
		{ 1e12, 110 },
		{ 10e12, 124 },
		{ 100e12, 138 },
		{ 1e15, 150 },
	},
}

--==============================================================================
-- THE DAY, AND THE NIGHT THAT RESTOCKS IT
--
-- Greenhollow holds ONE nest of five pods. Under the old rule a taken slot grew
-- a new pod 22 seconds later, which meant the nest was never really empty and
-- clearing it meant nothing -- you could stand beside it and farm the same ring
-- forever. The scarcity the whole road is built around existed on the map and
-- not in the game.
--
-- So the supply is a BATCH, not a trickle. Every live nest is stocked once at
-- dawn, a taken slot stays empty for the rest of the day, and an emptied nest
-- stays emptied. What is left at dusk is destroyed rather than carried over, so
-- a hoarded nest is not a way to start tomorrow ahead.
--
--     420s day     five pods for up to six players, then nothing until dawn
--      60s night   the road is shut and the world is reset
--      45s warning enough to decide whether to go in or turn round
--
-- SEVEN MINUTES IS THE NUMBER TO TUNE. It is the whole supply curve: five pods
-- per eight-minute cycle across the whole server. Shorten the day and the road
-- gets busier; lengthen it and the nest sits empty longer.
--
--==============================================================================
-- THE PHASE IS AN ATTRIBUTE ON THE WORKSPACE, NOT A REMOTE
--
-- Three read-only facts, replicated by the engine, that every client and every
-- service reads the same way:
--
--     WorldPhase        "Day" or "Night"
--     WorldPhaseEndsAt  workspace:GetServerTimeNow() of the next change
--     WorldCycleIndex   bumped at every dawn
--
-- A countdown is a SUBTRACTION, not a broadcast. The client works out the number
-- on its own clock from the deadline, so a seven-minute day costs three
-- attribute writes rather than 420 remote calls per player, and a player who
-- joins at 03:12 is correct on their first frame with nothing sent to them.
--
-- Nothing reads this off a client. The client is told; it never asks and it is
-- never believed.
--==============================================================================
GameConfig.WorldCycle = {
	DaySeconds = 420,
	NightSeconds = 60,
	-- How long before dusk the HUD starts saying so.
	WarnSeconds = 45,

	PhaseDay = "Day",
	PhaseNight = "Night",

	--==========================================================================
	-- THE ROAD IS SHUT BY A WALL, NOT BY THE DARK
	--
	-- Darkness and fog are a LOOK, and a look is not a rule: a player can turn
	-- their graphics down, and anybody who does would be able to see straight
	-- down a corridor that is supposed to be closed. The barrier is a real part
	-- across the mouth -- opaque and collidable at night, invisible and
	-- non-collidable by day -- so concealment does not depend on how somebody
	-- has their settings.
	--
	-- It is also why the nests are EMPTIED at dusk rather than merely hidden.
	-- Nothing waits behind it to be revealed.
	--==========================================================================
	Barrier = {
		Name = "Nightfall",
		-- Thin, but thick enough that a fast player cannot end a frame inside it.
		Thickness = 4,
		-- Above the corridor walls, so there is no gap to see over from the
		-- field or to hop across.
		HeightPad = 14,
		-- Wider than the corridor by a wall thickness on each side, so there is
		-- no seam at the wall line.
		WidthPad = 24,
		Colour = Color3.fromRGB(18, 22, 46),
		--======================================================================
		-- FULLY OPAQUE, AND 0.08 WAS NOT
		--
		-- It was 0.08 on the theory that a hint of the road beyond reads as
		-- "shut" rather than as the world ending. Measured in a playtest, and it
		-- leaked: the biome arch's name plate is a SurfaceGui with
		-- LightInfluence = 0, so it is drawn at FULL brightness regardless of
		-- the night lighting, and eight percent of full brightness against a
		-- black corridor is perfectly legible. "Greenhollow" was floating in the
		-- middle of a wall that is supposed to be opaque.
		--
		-- Anything unlit behind this would do the same, which is the general
		-- form of the bug: a barrier that is nearly opaque conceals things in
		-- proportion to how dark they happen to be, and unlit UI is never dark.
		-- Concealment cannot be a matter of degree.
		--======================================================================
		NightTransparency = 0,
	},

	--==========================================================================
	-- NIGHT IS BLUE, NOT BLACK
	--
	-- The plots stay usable: people plant, harvest and stand on their mills
	-- through the night, and a night that made their own garden unreadable would
	-- be a night they wait out staring at a wall. Every one of these is a target
	-- for the CLIENT to tween towards -- the server never touches Lighting, so
	-- the transition costs nothing and cannot desync anybody.
	--
	-- Dawn restores MapService's exact daytime values, which are captured once
	-- rather than typed here, so the two can never drift apart.
	--==========================================================================
	Night = {
		ClockTime = 0,
		Brightness = 1.1,
		Ambient = Color3.fromRGB(58, 66, 96),
		OutdoorAmbient = Color3.fromRGB(66, 78, 116),
		EnvironmentDiffuseScale = 0.7,
		ExposureCompensation = 0.25,
		FadeSeconds = 3.0,
	},
}

--==============================================================================
-- BIOME ENTRANCES ARE ADVISORY; NIGHT STILL CLOSES THE ROAD
--
-- MapService builds an arch at every biome boundary. The Speed number on it is
-- a recommendation for the chase ahead, not a lock: every player may enter
-- every biome during the day. The same geometric check remains valuable at
-- night, when the entire road closes for the restock cycle.
--
--==============================================================================
-- A PLANE, NOT A PART
--
-- The visible night barrier can be clipped at high WalkSpeed, so the server
-- also checks which side of the road entrance a player occupies.
--
-- The road mouth is one plane. During the day it is open; at night a player on
-- the biome side is put back in the field. That rule cannot be missed at any
-- speed or frame rate because it checks where the player is, not a touch event.
--
--==============================================================================
-- NIGHT EJECTION
--
-- At night the smallest correction that works is a short push across the road
-- mouth. CarryService separately forfeits the active pod, preserving the cost
-- of failing to return before the shutdown.
--==============================================================================
GameConfig.Gate = {
	-- How far into the field a player caught on the road at night is placed.
	PushBackStuds = 8,
	-- Server poll for entry recommendations and the nighttime closure.
	PollSeconds = 0.1,
	-- Throttles repeated night-ejection diagnostics.
	NoticeCooldown = 3,
}

--==============================================================================
-- THE AFTERIMAGE
--
-- Seven tiers, from a single faint echo at a thousand Speed to a flowing rainbow
-- at the save cap. It is the only thing in the game that says how far up the
-- ladder somebody is without a number, and it is the reward for the one stat
-- this game is entirely about.
--
--==============================================================================
-- THE SCORE QUALIFIES. THE MOVEMENT EMITS. THEY ARE NOT THE SAME QUESTION.
--
-- A player standing still, ragdolled, mid-throw, dead, or crawling home under a
-- 9,000 kg pod must produce NOTHING at any tier. An afterimage is a statement
-- about motion; one that appears while you are pinned to the floor reads as a
-- bug and cheapens it everywhere else.
--
--==============================================================================
-- HIGHER TIERS BUY COLOUR, NEVER INSTANCES
--
-- The ghost count stops at four and stays there from tier 4 up. Everything above
-- it is spent on the SAME four ghosts looking better: a gradient down the body,
-- a wave travelling through it, a hue wheel turning, a pulse, an expansion. That
-- is the whole performance strategy -- an eighth ghost costs fifteen more parts
-- per player per frame forever, and a hue that moves costs one Color3 write at
-- twelve hertz.
--
-- Which is also why a phone can have every tier. It gets fewer ghosts, not a
-- worse rainbow.
--
--==============================================================================
-- EMITTED BY DISTANCE, NOT BY FRAMES
--
-- A frame counter spaces ghosts by frame rate, so the same run leaves twice as
-- many on a 120 Hz machine as on a 60 Hz one. Studs travelled is the same
-- picture everywhere, and it is what makes the spacing numbers below mean
-- something a person can see.
--==============================================================================
GameConfig.Afterimage = {
	--==========================================================================
	-- A RIBBON, NOT A CROWD OF COPIES
	--
	-- This used to emit cloned character limbs -- up to four echoes at a time,
	-- fifteen parts each, respawned every few studs for as long as you ran. It
	-- read well and it capped hard: a fifth ghost cost fifteen more parts, so
	-- the count stopped at four and every tier above the fourth was spent on
	-- making the SAME four echoes look better. That is why the top half of the
	-- ladder had nothing structural left to give.
	--
	-- One Trail per character has no such cap. Length, width, brightness and
	-- animation are all free to keep climbing, so every step up the ladder is
	-- visibly more than the one below it in the SHAPE of the thing and not only
	-- in its colour.
	--
	-- THE RIBBON NO LONGER STEPS BACK. There was a TrailTransparencyFloor here
	-- that held the streak deliberately faint so the echoes had room to read
	-- inside it. With the echoes gone the ribbon carries the whole reading, so
	-- it gets STRONGER with tier -- the exact inverse of what it used to do.
	--==========================================================================
	QualityAttribute = "SeedAfterimageQuality",

	--== movement gates ==--
	-- Standing still at a high WalkSpeed must not smear a ribbon across a plot,
	-- and a respawn must not draw one across the map.
	MinGroundSpeed = 2,
	TeleportStuds = 24,
	-- Past this, somebody else's ribbon is not worth driving. Checked before the
	-- work rather than by MaxDistance, because the point is to skip COMPUTING
	-- it, not merely to skip drawing it.
	RemoteMaxStuds = 120,

	-- How often the animated tiers are repainted. A wave that moved at the frame
	-- rate would run at a different speed on every machine.
	ColourInterval = 1 / 30,

	--==========================================================================
	-- WHAT A LOAD DOES TO IT
	--
	-- Read off the SERVER'S carry multiplier, never re-derived from a size --
	-- a client that worked it out for itself is a client that could decide not
	-- to. Above CarryFullAbove nothing changes; below CarryReducedAbove the
	-- ribbon goes out entirely, which is what guarantees a Colossal haul is
	-- silent at every tier, the void at the top included.
	--==========================================================================
	CarryFullAbove = 0.92,
	CarryReducedAbove = 0.55,
	CarryLifetimeScale = 0.45,
	CarryWidthScale = 0.60,
	CarryFadeAdd = 0.18,

	-- Phones get a shorter, narrower ribbon rather than a different effect. The
	-- whole point of moving off ghosts is that every machine can have every
	-- tier.
	ReducedLifetimeScale = 0.55,
	ReducedWidthScale = 0.85,

	--==========================================================================
	-- THE TEN
	--
	--   From              the Speed score that unlocks it
	--   Lifetime          how long the ribbon persists behind you, in seconds
	--   WidthStuds        the separation of the two attachments, which IS the
	--                     ribbon's width -- a Trail draws between a pair
	--   HeadTransparency  how solid it is where it leaves the body
	--   LightEmission     how much it ignores world lighting
	--   Palette           the colours it cycles through
	--   Wave              palette travel per second (0 is static)
	--   Shimmer           fast, shallow brightness flicker
	--   Particle          the emitter that rides with it: Texture, Color, Rate,
	--                     Speed, Size, and an optional LightEmission
	--   CoreColor         optional. The inner blade is white at full emission
	--                     unless a tier names its own colour
	--
	-- THE SHAPE OF IT CLIMBS AT EVERY STEP: Lifetime, WidthStuds and
	-- HeadTransparency are strictly monotonic from 1 to 10, so no tier is ever
	-- shorter, narrower or fainter than the one below it. That is the guarantee
	-- the ghost ladder could not make once its count capped at four.
	--
	-- THE ANIMATION DIALS DELIBERATELY DO NOT. Wave and Shimmer are set by
	-- THEME, not by rank -- Thunder Strike flickers harder than the Violet
	-- Phantom above it because that is what those two things are. Do not
	-- "correct" them into a ramp; the monotonic guarantee lives in the three
	-- columns above and nowhere else.
	--
	-- AND TIER 10 BREAKS LightEmission ON PURPOSE. Every tier climbs toward
	-- light; Void Singularity is the one that takes it away, which only reads
	-- as an ending because the nine below it went the other way.
	--
	-- THAT IS ALSO WHY THERE IS NO LONGER A Rainbow COLUMN. The old top tier
	-- ended the ladder by abandoning its palette for the whole hue wheel. The
	-- void ends it by going the other way instead, so nothing set the flag, and
	-- a branch no row can reach is a branch nobody tests. It went with it. If a
	-- future tier wants the hue wheel back, it is in the history -- do not leave
	-- a dead column here waiting for it.
	--==========================================================================
	Tiers = {
		{
			From = 1e3,
			Name = "Breeze Whisper",
			Lifetime = 0.25,
			WidthStuds = 1.20,
			HeadTransparency = 0.55,
			LightEmission = 0.40,
			Palette = {
				Color3.fromRGB(190, 250, 210),
				Color3.fromRGB(130, 230, 160),
			},
			Wave = 0.15,
			Shimmer = 0,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(150, 240, 170),
				Rate = 16,
				Speed = 2.4,
				Size = 0.65,
			},
		},
		{
			From = 10e3,
			Name = "Aqua Surge",
			Lifetime = 0.35,
			WidthStuds = 1.50,
			HeadTransparency = 0.48,
			LightEmission = 0.50,
			Palette = {
				Color3.fromRGB(130, 245, 255),
				Color3.fromRGB(60, 170, 255),
			},
			Wave = 0.20,
			Shimmer = 0.05,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(110, 225, 255),
				Rate = 20,
				Speed = 3.0,
				Size = 0.80,
			},
		},
		{
			From = 1e6,
			Name = "Thunder Strike",
			Lifetime = 0.45,
			WidthStuds = 1.80,
			HeadTransparency = 0.42,
			LightEmission = 0.68,
			Palette = {
				Color3.fromRGB(255, 245, 110),
				Color3.fromRGB(90, 230, 255),
			},
			Wave = 0.38,
			Shimmer = 0.16,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(255, 235, 90),
				Rate = 24,
				Speed = 3.8,
				Size = 0.95,
			},
		},
		{
			From = 100e6,
			Name = "Violet Phantom",
			Lifetime = 0.55,
			WidthStuds = 2.10,
			HeadTransparency = 0.36,
			LightEmission = 0.78,
			Palette = {
				Color3.fromRGB(245, 170, 255),
				Color3.fromRGB(150, 70, 250),
			},
			Wave = 0.25,
			Shimmer = 0.08,
			Particle = {
				Texture = "rbxasset://textures/particles/smoke_main.dds",
				Color = Color3.fromRGB(210, 110, 255),
				Rate = 22,
				Speed = 3.2,
				Size = 1.15,
			},
		},
		{
			From = 1e9,
			Name = "Solar Flare",
			Lifetime = 0.65,
			WidthStuds = 2.45,
			HeadTransparency = 0.30,
			LightEmission = 0.86,
			Palette = {
				Color3.fromRGB(255, 255, 220),
				Color3.fromRGB(255, 180, 40),
				Color3.fromRGB(255, 100, 15),
			},
			Wave = 0.32,
			Shimmer = 0.12,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(255, 210, 60),
				Rate = 28,
				Speed = 4.2,
				Size = 1.25,
			},
		},
		{
			From = 10e9,
			Name = "Glacial Frostbite",
			Lifetime = 0.75,
			WidthStuds = 2.80,
			HeadTransparency = 0.26,
			LightEmission = 0.92,
			Palette = {
				Color3.fromRGB(230, 255, 255),
				Color3.fromRGB(110, 230, 255),
				Color3.fromRGB(70, 160, 255),
			},
			Wave = 0.38,
			Shimmer = 0.10,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(190, 250, 255),
				Rate = 32,
				Speed = 4.6,
				Size = 1.40,
			},
		},
		{
			From = 100e9,
			Name = "Heartwood Bloom",
			Lifetime = 0.85,
			WidthStuds = 3.15,
			HeadTransparency = 0.22,
			LightEmission = 0.94,
			Palette = {
				Color3.fromRGB(110, 255, 170),
				Color3.fromRGB(255, 130, 230),
				Color3.fromRGB(255, 240, 110),
			},
			Wave = 0.45,
			Shimmer = 0.08,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(255, 170, 240),
				Rate = 35,
				Speed = 4.8,
				Size = 1.50,
			},
		},
		{
			From = 1e12,
			Name = "Hellfire Inferno",
			Lifetime = 0.95,
			WidthStuds = 3.50,
			HeadTransparency = 0.18,
			LightEmission = 0.97,
			Palette = {
				Color3.fromRGB(255, 240, 90),
				Color3.fromRGB(255, 90, 20),
				Color3.fromRGB(180, 20, 8),
				Color3.fromRGB(40, 24, 28),
			},
			Wave = 0.55,
			Shimmer = 0.15,
			Particle = {
				Texture = "rbxasset://textures/particles/fire_main.dds",
				Color = Color3.fromRGB(255, 120, 25),
				Rate = 40,
				Speed = 5.4,
				Size = 1.75,
			},
		},
		{
			From = 10e12,
			Name = "Seraphic Divinity",
			Lifetime = 1.05,
			WidthStuds = 3.85,
			HeadTransparency = 0.15,
			LightEmission = 0.99,
			Palette = {
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(255, 240, 150),
				Color3.fromRGB(210, 245, 255),
				Color3.fromRGB(255, 220, 100),
			},
			Wave = 0.62,
			Shimmer = 0.10,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(255, 250, 190),
				Rate = 45,
				Speed = 5.6,
				Size = 1.90,
			},
		},
		{
			From = 100e12,
			Name = "Void Singularity",
			Lifetime = 1.25,
			WidthStuds = 4.40,
			HeadTransparency = 0.05,
			LightEmission = 0.00,
			Palette = {
				Color3.fromRGB(0, 0, 0),
				Color3.fromRGB(18, 12, 26),
				Color3.fromRGB(42, 16, 58),
				Color3.fromRGB(0, 0, 0),
			},
			CoreColor = Color3.fromRGB(10, 6, 16),
			Wave = 0.65,
			Shimmer = 0.25,
			Particle = {
				Texture = "rbxasset://textures/particles/sparkles_main.dds",
				Color = Color3.fromRGB(15, 10, 24),
				Rate = 60,
				Speed = 7.0,
				Size = 2.50,
				LightEmission = 0.00,
			},
		},
	},
}

--==============================================================================
-- WEIGHT IS THE WHOLE RISK/REWARD, AND IT IS ONE NUMBER
--
-- A creature's KILOGRAMS decide both what it earns and what it costs to get
-- home with. Rarity decides only how OFTEN you find one. That split is the
-- entire design of a theft game expressed as a single stat:
--
--   the fat pod is the one worth taking, and the one that gets you caught.
--
-- ONE KILOGRAM IS ONE CASH PER SECOND. No conversion, no table, no tooltip
-- maths -- a player reads an object's worth straight off its weight, and can
-- compare any two things in the game at a glance without opening anything.
-- Scale comes later from multipliers and Rebirth, never from bending this.
--
-- The slow curve is deliberately flat at the bottom and brutal at the top:
--
--       2 kg  ->  99.6% speed   (a starter pod is free to carry)
--     110 kg  ->  95.4%         (noticeable, not punishing)
--   1,000 kg  ->  82.4%
--  10,000 kg  ->  30.0%         (a crawl, and a very long walk home)
--
-- Flat at the bottom matters: a new player must never feel taxed for picking up
-- the only thing they can find. Brutal at the top is what makes an endgame
-- carry a decision rather than a formality.
--==============================================================================
--==============================================================================
-- THE PARENT
--
-- Every wild patch is a NEST: pods spawn in a ring around a big hostile parent
-- creature that guards them. It ignores you until a pod is taken, then chases
-- whoever took it, and on catching them it GRABS and THROWS.
--
-- Throwing rather than damaging is the right punishment for this game. Damage
-- would mean health bars, respawns and a death loop; a throw costs you the one
-- thing the whole design is already about -- the length of the walk home -- and
-- it is funny to watch, which matters more than it sounds for a game people
-- clip.
--
-- THROW DISTANCE SCALES WITH THE BIOME, so the parent guarding a 1,500-stud
-- Starbloom nest hurls you far further than the one in the starter field. That
-- keeps the punishment proportional to the prize without needing a second
-- mechanic: the deep biomes are not more dangerous because the parent hits
-- harder, they are more dangerous because being thrown there costs more walking.
--
-- Numbers are a first pass and cannot be anything else until a parent exists to
-- be run away from.
--==============================================================================
GameConfig.Parent = {
	--==========================================================================
	-- IT SLEEPS, AND THE DELAY IS THE GAME
	--
	-- The parent is asleep beside its pods until one is taken. It then wakes on
	-- a SHORT DELAY -- not instantly -- and that delay is the entire skill of a
	-- raid. It is your head start, it is what makes grabbing the near pod
	-- different from grabbing the far one, and it is why a player creeps in and
	-- then sprints out rather than just running in a straight line.
	--
	-- Instant aggro would delete all of that and make the mechanic a tax.
	--==========================================================================
	WakeDelaySeconds = 1.2,

	--==========================================================================
	-- ITS SPEED IS THE GATE, AND THE TREADMILL IS THE ANSWER
	--
	-- This is what the treadmill was always for. The player trains on it to earn
	-- Speed per second; Speed feeds the WalkSpeed curve; WalkSpeed is measured
	-- against THIS number. So "can I loot Emberroot yet" is not a menu check, it
	-- is a footrace you either win or feel yourself losing.
	--
	-- Biome 1 sits just above a fresh player's 16 -- you WILL be caught on your
	-- first raid, and that is the lesson. Each biome further out is faster.
	--==========================================================================
	-- FAST. At 19 against a fresh player's 16 the parent was technically faster
	-- and felt like a slow-moving hazard you could stroll away from. A guard
	-- that never quite catches you is scenery.
	-- How much faster than the biome's own recommendation the guardian runs
	-- against a player who MEETS that recommendation. See parentWalkSpeedFor:
	-- 10 is what Greenhollow already had, so the shipped value falls out of the
	-- formula instead of being special-cased.
	SpeedMargin = 10,

	--==========================================================================
	-- AND HOW MUCH FASTER AGAIN AGAINST SOMEBODY WHO TURNED UP UNDERGEARED
	--
	-- Added on a sliding scale: in full at Speed 0, and not at all once you meet
	-- the recommendation. It exists because THE SPEED CURVE IS LOGARITHMIC and
	-- SpeedMargin alone could not express "you should not be here yet".
	--
	-- Measured at Dustbowl, whose bar is 167M:
	--
	--     score     your walk    old parent   closing    time to catch
	--         0        16.0          52.0       36.0          2.5s
	--        10M       36.5          52.0       15.5          4.9s
	--        80.5M     40.6          52.0       11.4          6.2s
	--       167M       42.0          52.0       10.0          7.1s
	--
	-- Half the recommended score buys you three per cent of a walk speed. A
	-- player at 80.5M -- less than half the bar -- ran only 1.4 slower than one
	-- who had earned their way in, so the guardian treated them identically and
	-- the recommendation meant nothing. The gate was removed from the road on
	-- purpose; this is what replaced it, and it was not carrying the weight.
	--
	-- Sliding rather than a threshold, because a cliff at 166,999,999 would be a
	-- check wearing a footrace's clothes -- and the first claim this file makes
	-- is that the matter is settled by running.
	--
	-- 30 is set so a player at half the bar is caught in about three seconds
	-- instead of six, and one who walked in with nothing is caught almost at
	-- once. It is deliberately NOT enough to touch anybody at or above the
	-- recommendation: that race is unchanged, and overshooting the bar still
	-- buys a clean escape.
	--==========================================================================
	UnderSpeedMargin = 30,

	--==========================================================================
	-- IT GETS ANGRIER
	--
	-- Every theft from the same nest before it gets back to sleep adds speed.
	-- Being caught and coming back for the same pod is the obvious way to farm a
	-- nest safely -- lose it, wait, collect -- so the second attempt has to be
	-- harder than the first, and the fourth harder again.
	--
	-- It resets on sleep, so a nest left alone forgives. The escalation punishes
	-- pestering, not the player.
	--==========================================================================
	RageSpeedPerTake = 5,
	MaxRageStacks = 4,
	-- Rage FADES, it does not vanish the moment the parent lies down. Resetting
	-- on sleep sounded right and made the mechanic almost unreachable: a caught
	-- player is thrown clear, the parent walks home and sleeps in a couple of
	-- seconds, and the pod is still on the ground -- so by the time anyone picks
	-- it back up the anger is already gone. Measured: two thefts in a row, both
	-- at 31, when the second should have been 36.
	--
	-- Held for this long after it settles, so coming back for a dropped pod is
	-- the case that stacks. Leave the nest alone and it forgives.
	RageForgetSeconds = 45,

	-- How far a biome-1 parent throws you, in studs.
	BaseThrowStuds = 60,
	-- Added per biome further down the road. Starbloom throws 240.
	ThrowPerBiome = 45,
	-- Upward component, as a fraction of the horizontal throw. Enough to arc.
	ThrowLift = 0.45,
	-- It only wakes when a pod leaves its nest.
	AggroOnTheftOnly = true,
	--==========================================================================
	-- THE BACKSTOP, NOT THE RULE
	--
	-- This was 220, and it was doing the job the safe-zone check should have
	-- been doing. Every nest sits 240 studs from its own biome's near edge, so
	-- a 220 radius meant a parent gave up TWENTY STUDS SHORT of the boundary --
	-- in every biome, identically, because the nests are placed to a pattern.
	-- Step across the line and the chase ended, which made a road that is
	-- deliberately one continuous corridor behave like five separate rooms.
	--
	-- "So a parent can never be kited into the safe field" is now enforced
	-- where it belongs: NestService tests the PARENT's own position against the
	-- safe zone every tick. That is the actual rule, and a radius only ever
	-- approximated it.
	--
	-- What is left here is a backstop -- sized for the full 5-biome corridor
	-- (1500+ studs) -- so a normal cross-biome chase from Emberroot or Starbloom
	-- can reach the red line / safe zone, while a broken chase off-map cannot
	-- run forever.
	--==========================================================================
	LeashStuds = 2000,
	-- Close enough to grab.
	GrabStuds = 7,

	--==========================================================================
	-- HOW FAR PAST YOU THE PARENT AIMS WHILE IT IS CHASING
	--
	-- Not decoration, and not pathfinding. A Humanoid told to MoveTo a point
	-- DECELERATES as it arrives, and a chase asks it to arrive at a point that
	-- keeps moving away -- so it spends the whole run braking for a destination
	-- it never reaches. Measured against a target running 40.6:
	--
	--     chase speed   closest it EVER gets
	--         45.0            13.99
	--         52.0            13.64
	--         67.5            12.50
	--         82.0            13.60
	--
	-- Thirteen studs, at every speed, against a GrabStuds of 7. A player running
	-- in a straight line was UNCATCHABLE, and no amount of parent speed could
	-- have fixed it -- the standoff does not shrink when the chaser gets faster,
	-- which is why two rounds of making the parent quicker changed nothing. Stop
	-- running and the point stops receding, the arrival completes, and it hits
	-- you: exactly the "it only catches me when I stand still" that found this.
	--
	-- Aiming past the target means the goal is never within braking distance, so
	-- the Humanoid runs flat out until it makes contact. 60 is comfortably clear
	-- of the ~14 stud braking envelope with room for a faster biome.
	--
	-- CHASING ONLY. The walk home still uses a plain MoveTo, because arriving
	-- and stopping is precisely what it wants.
	--==========================================================================
	ChaseOvershootStuds = 60,
	-- Seconds it holds you before the throw. Long enough to read what happened.
}

--==============================================================================
-- THE PARENT IS AS FAST AS THE BIOME ASKS YOU TO BE, PLUS A MARGIN
--
-- It used to be Base + PerBiome * (order - 1): 26, 38, 50, 62, 74. Measured
-- against what a player who MEETS each biome's own RecommendedSpeed actually
-- runs at -- 16, 42, 54, 68, 82 -- only Greenhollow's parent could catch
-- anyone. Every deeper biome had a guardian SLOWER than the player it exists to
-- threaten, and the shortfall grew with depth: -4, -4, -6, -8. That is exactly
-- backwards. The further you are from safety, the more the run home should
-- cost, and a monster you can stroll away from is scenery.
--
-- Deriving the speed FROM the recommendation ties the two together, so a biome
-- whose difficulty is retuned can never leave its guardian behind -- there is
-- no second number to remember.
--
--     biome         player at rec   parent   was
--     Greenhollow            16.0     26.0    26   unchanged
--     Dustbowl               42.0     52.0    38   could not catch
--     Tanglemire             54.0     64.0    50   could not catch
--     Emberroot              68.0     78.0    62   could not catch
--     Starbloom              82.0     92.0    74   could not catch
--
-- Rage still stacks on top of all of these (+5 each, four deep), and a player
-- carrying a heavy pod is far slower than any of it -- 12.6 at Dustbowl with
-- 10,000 kg in their arms. Being caught is meant to be what happens when you
-- get greedy, not what happens because you turned up.
--
-- IT TAKES THE RECOMMENDATION, NOT THE BIOME: BiomeData requires GameConfig, so
-- GameConfig cannot require BiomeData back. `walkSpeedFor` is declared further
-- down this file and that is safe -- it is a table field resolved when this is
-- CALLED, not an upvalue captured where it is defined.
--==============================================================================
--
-- THE SECOND ARGUMENT IS WHO IT IS CHASING, AND IT IS OPTIONAL
--
-- Omitted -- or from a player whose profile has not loaded -- this is exactly
-- the flat margin it has always been. Unknown means UNCHANGED rather than
-- unqualified: a mid-load player is not evidence of anything, and guessing
-- against them would put the harshest speed in the game behind a race
-- condition.
--==============================================================================
function GameConfig.parentWalkSpeedFor(
	recommendedSpeed: number,
	targetSpeedScore: number?
): number
	local rec = tonumber(recommendedSpeed) or 0
	-- NaN fails every comparison, so test it directly rather than clamping.
	if rec ~= rec or rec < 0 then
		rec = 0
	end
	local base = GameConfig.walkSpeedFor(rec) + GameConfig.Parent.SpeedMargin

	local score = tonumber(targetSpeedScore)
	-- rec == 0 is Greenhollow, which recommends nothing and therefore cannot
	-- have anybody fall short of it. Dividing by it would be a NaN, and the
	-- tutorial biome keeping its shipped 26 is the point.
	if score == nil or score ~= score or rec <= 0 then
		return base
	end
	local shortfall = math.clamp(1 - math.max(score, 0) / rec, 0, 1)
	return base + GameConfig.Parent.UnderSpeedMargin * shortfall
end

--==============================================================================
-- THE TREADMILL
--
-- Speed per second while you stand on it. The only faucet for Speed, the same
-- way EconomyService is the only faucet for cash -- one source is what keeps a
-- number auditable when a dozen systems want to grant it.
--==============================================================================
--==============================================================================
-- PLANTING
--
-- Structure, not balance: WHEN a plant changes shape as a fraction of its own
-- grow time, not how long any particular species takes -- that is SeedData's.
--
-- Here rather than inside PlantService because THE CLIENT NEEDS IT. The hatch
-- timer counts down to the next stage, so it has to compute the same thresholds
-- the server does, from the same numbers. A private constant in the service
-- would have meant the countdown and the transition disagreeing.
--==============================================================================
GameConfig.Plant = {
	-- How far through its growth a pod becomes a sprout.
	--
	-- DEAD NOW, and kept only so an old save's stage maths still reads. Nothing
	-- in the ground sprouts any more: a planted pod stays a pod until its owner
	-- hatches it by hand, and what comes out is already the creature. The stage
	-- between them had no decision in it -- it was a thing you watched.
	SproutAt = 0.35,
	TickSeconds = 1,
	-- How close you must stand to plant, and to reach the point you clicked.
	-- Generous -- a convenience, not a skill check.
	RangeStuds = 26,

	--==========================================================================
	-- YOU PUT IT WHERE YOU CLICK
	--
	-- The bed used to be an invisible 3-by-N grid and planting snapped to the
	-- nearest free cell. That made a plot a form to fill in. Free placement
	-- makes it a garden you arrange -- which is the only reason to look at
	-- somebody else's.
	--
	-- The grid attachments still exist in MapService, but only as the table
	-- that says where a PRE-FREE-PLACEMENT save lands. Nothing places into
	-- them any more.
	--==========================================================================
	-- How far inside the soil's edge a click is pulled, so nothing is planted
	-- half-way through the bed frame. A click outside the bed is CLAMPED rather
	-- than refused: "exactly where I clicked" should stop being exact only at
	-- the rim, and a refusal there reads as the game being broken.
	EdgeMarginStuds = 1.6,
	--==========================================================================
	-- WANDERING, WHICH THE SERVER DECIDES AND THE CLIENT ONLY DRAWS
	--
	-- A grown creature walks its owner's whole plot. A POD DOES NOT MOVE: it
	-- sits where it was planted until it is hatched, because a seed that
	-- strolled off would be a seed you could not find again.
	--
	-- The server picks each destination and stamps four facts on the model --
	-- where from, where to, when it starts, when it arrives. Every client
	-- interpolates the same four numbers against Workspace:GetServerTimeNow(),
	-- so a plant is in the same place on every screen. The alternative, which
	-- this replaced, was each client rolling its own dice: cheap, and wrong the
	-- moment two people look at the same garden.
	--
	-- Four attribute writes per creature per LEG -- roughly one every five to
	-- twelve seconds -- and no CFrame ever crosses the wire.
	--==========================================================================
	Wander = {
		-- How far inside the fence a creature may walk. The fence boards are
		-- 1.6 thick and stand at the plot edge, so this keeps a body off them.
		FenceMargin = 4.5,
		-- Extra room kept clear in front of the gate, so nothing loiters in the
		-- doorway looking like it is about to leave.
		GateMargin = 7,
		-- Candidate destinations generated per leg. Enough that the least
		-- crowded of them is meaningfully better than the first; small enough
		-- that twenty plants scoring them is nothing.
		Candidates = 6,
		-- How far apart the scorer TRIES to keep them. Bounded on purpose: a
		-- Colossal is currently hundreds of studs tall, and scoring against its
		-- real size would make every destination illegal at once. This is a
		-- logical spacing, not a physical one.
		SeparationStuds = 14,
		-- A leg is at least this long, so a creature never twitches in place.
		MinLegStuds = 6,
		-- Recomputed only when a leg ends. Between legs the server does nothing
		-- at all for that plant.
		TickSeconds = 0.5,
		-- How often the authoritative offset is written back to the profile.
		-- Committed at the END of a leg rather than continuously -- a creature
		-- mid-stride has no saved position worth having, and a profile write
		-- per frame is the thing this exists to avoid.
		CommitOnArrival = true,
	},

	-- Hold to hatch. Long enough that the pod visibly shakes and the hatch is a
	-- thing you did, short enough that a full bed is not a chore.
	HatchHoldSeconds = 1.1,
	-- How long the shell burst lasts before its pieces are gone.
	BurstSeconds = 0.45,

	--==========================================================================
	-- ONE VERB ON ONE EXISTING REMOTE
	--
	-- Tool.Activated fires on the server with no idea WHERE the player clicked,
	-- and neither does ClickDetector. A click position can only come across the
	-- wire. Rather than add a remote, this rides GameEvent -- which ServerMain
	-- has always created and nothing has ever used.
	--
	-- The position is a claim by the client and is treated as one: the server
	-- re-checks the plot is theirs, the point is on their own soil, and they
	-- are standing within RangeStuds of it.
	--==========================================================================
	PlaceAction = "PlantAt",
	--==========================================================================
	-- TAKING ONE BACK, FROM THE PANEL
	--
	-- The world already has a way: walk over and hold E on the Pick Up prompt.
	-- This is the same act reached from the Garden panel, which is the only
	-- place a player can see the whole bed at once.
	--
	-- A SECOND ACTION ON THE SAME REMOTE, not a second remote. GameEvent already
	-- carries PlantAt and the argument after the action string is already
	-- treated as a claim rather than as an instruction; one more verb costs
	-- nothing and keeps the validation in one place.
	--==========================================================================
	PickUpAction = "PickUp",
}

GameConfig.Treadmill = {
	--==========================================================================
	-- THIS IS A BASE RATE AND IT IS MEANT TO LOOK SLOW
	--
	-- The whole speed ladder measured against the parents:
	--
	--     out-run biome 1 (19)     453 Speed    ~4 min
	--     out-run biome 2 (30)   2,208 Speed   ~18 min
	--     out-run biome 3 (41)   4,133 Speed   ~34 min
	--     out-run biome 4 (52)   6,260 Speed   ~52 min
	--     out-run biome 5 (63)   8,636 Speed   ~72 min
	--
	-- At the 12/sec this started as, that entire ladder was TWELVE MINUTES, and
	-- a progression game whose progression is over before the first session is
	-- not a progression game. Dropped to 2 and left there.
	--
	-- The number is low because it is a BASE. Upgrades and Rebirth multiply it,
	-- which is where the actual pacing will come from -- and it is much easier
	-- to add multipliers on top of a slow floor than to claw back a fast one
	-- from players who already have the speed.
	--
	-- Also worth knowing: speed is not a hard gate on biome 1. The parent's
	-- wake delay means a quick raid on a near pod succeeds at WalkSpeed 16. You
	-- buy speed to stop being nervous, not to be allowed in.
	--==========================================================================
	-- The tier-1 rate, kept here because TreadmillService still reads it as the
	-- floor when a tier index falls off the end of the table. It must MATCH
	-- Tiers[1].speed -- a fallback that disagrees with the row it stands in for
	-- is a silent wrong answer at exactly the moment something else is already
	-- wrong. Asserted below the table.
	SpeedPerSecond = 20,
	-- Only pays while you are actually standing on it, alive.
	TickSeconds = 1,
}

--==============================================================================
-- THE MILL, IN TEN STEPS
--
-- One per plot, and yours only.
--
-- THE RATES ARE PRICED OFF THE BIOME RECOMMENDATIONS, NOT OFF EACH OTHER.
-- Each tier is sized so that the milestone it is meant to serve takes tens of
-- minutes rather than tens of hours:
--
--     T1     20/s    1K in 50s          the first trail, inside a minute
--     T2    100/s    10K in 100s        an immediate reward for the first buy
--     T3      1K/s   1M in 17 min       the early-session goal
--     T4      8K/s                      the bridge to Dustbowl
--     T5     50K/s   167M in 56 min     Dustbowl
--     T6    300K/s   800M in 44 min     Tanglemire
--     T7      2M/s   3B in 25 min       Emberroot
--     T8     12M/s   10B in 14 min      Starbloom
--     T9     70M/s                      post-Starbloom
--     T10   400M/s   1e15 in 29 days    post-Starbloom, and why Overclock
--                                       still exists
--
-- THE OLD LADDER RAN 2 TO 160 AND WAS NOT A LADDER. It spanned 80x while the
-- score ladder it feeds spans a QUADRILLION, so every tier past the third was
-- indistinguishable in practice and the whole of the pacing had been pushed
-- onto Overclock. This one spans 20 million times, which is the same shape as
-- the thing it is climbing.
--
-- COSTS ARE UNCHANGED. They already climbed faster than the old rates and they
-- climb slower than these, which is deliberate: a tier now buys a visible jump
-- rather than a rounding error, so no step is an obvious skip.
--
-- BeltStuds is how fast the surface travels, and it is not decoration: the run
-- animation is driven from the same number (see SpeedFX), so a faster mill has
-- visibly faster feet. Roblox authors its run cycle for 16 studs a second, so
-- that is the number a track speed of 1.0 corresponds to.
--
-- NOT BALANCE IN THE Rule 7 SENSE -- this is the speed curve, which GameConfig
-- has always owned, sitting next to the curve it multiplies.
--==============================================================================
GameConfig.Mill = {
	--==========================================================================
	-- THE ONE AUTHORITATIVE RATE TABLE
	--
	-- `speed` is Speed SCORE per second, not studs. Everything that prints a
	-- rate -- the mill sign, the upgrade board, the showroom placards, the
	-- startup log -- reads this row through TreadmillService, so a number
	-- changed here is a number changed everywhere.
	--
	-- BeltStuds is the only studs-per-second column and drives the belt
	-- animation and the run cycle. It is untouched by this pass.
	--==========================================================================
	Tiers = {
		{ name = "Compost Walk", speed = 20, cost = 0, beltStuds = 13 },
		{ name = "Garden Path", speed = 100, cost = 10000, beltStuds = 15 },
		{ name = "Trellis Trot", speed = 1000, cost = 75000, beltStuds = 17 },
		{ name = "Millstone", speed = 8000, cost = 500000, beltStuds = 19 },
		{ name = "Glasshouse", speed = 50000, cost = 3500000, beltStuds = 21 },
		{ name = "Sunwheel", speed = 300000, cost = 25000000, beltStuds = 24 },
		{ name = "Heartroot", speed = 2000000, cost = 150000000, beltStuds = 27 },
		{ name = "Inferno Forge", speed = 12000000, cost = 1000000000, beltStuds = 31 },
		{ name = "Celestial Ascent", speed = 70000000, cost = 10000000000, beltStuds = 35 },
		{ name = "Astral Singularity", speed = 400000000, cost = 100000000000, beltStuds = 40 },
	},
	StartingTier = 1,

	-- What the belt creeps at with nobody on it. Not zero: a dead mill reads as
	-- broken, and a slow drift says "this is a machine and it is waiting".
	IdleStuds = 1.6,

	--==========================================================================
	-- THE ANIMATION IS NOT AUTHORED AT ONE SPEED
	--
	-- Roblox's own Animate script scales the run cycle by speed/16, which is
	-- what keeps feet on the ground when a character actually moves. A mill
	-- character does not move, so the same division has to be done by hand --
	-- and doing it from the SAME BeltStuds the chevrons use is what stops the
	-- belt crawling under sprinting legs.
	--==========================================================================
	RunCycleStuds = 16,

	--==========================================================================
	-- WHAT THE BELT DOES, TIER BY TIER
	--
	-- One row per mill, and the ladder is meant to be read DOWN a column: every
	-- tier is the tier below it plus exactly one new behaviour. That constraint
	-- is the whole design. Seven belts that each do a different clever thing
	-- would be seven belts a player cannot rank; seven belts that visibly ACCRUE
	-- are a progression somebody can feel themselves climbing.
	--
	--   1  scroll .............. it moves, and nothing else
	--   2  + breathe ........... the set brightens and dims: it is powered
	--   3  + chase ............. arrows light in sequence along the run
	--   4  + rake .............. they lean into the travel, harder when faster
	--   5  + bloom ............. a band of light sweeps the belt through them
	--                           -- painted as brightness, not built as a part
	--   6  + bob and shimmer ... they ride a wave, the plate catches the light
	--   7  + rainbow ........... a spectrum runs the surface itself
	--
	-- Rung 7 needs one thing none of the others do. A belt is a single part, so
	-- its colour is one colour -- there is no varying anything ALONG it, at any
	-- price -- and a plate that merely cycles hues is a plate that is lilac, and
	-- then is blue. That is not a rainbow. A rainbow is all the hues at once, in
	-- order, and the only way to have one on a single belt is to lay flat bands
	-- on it and let them scroll through a spectrum that stays where it is. Which
	-- is what Bands is for, and why it exists on exactly one tier.
	--
	-- Every amplitude here is multiplied by how hard the belt is WORKING, which
	-- is what "animate as the player uses it" actually means: an unoccupied
	-- tier-7 mill idles as a slow green drift, and lights up as a rainbow the
	-- moment somebody steps on. A mill that put on its whole show to an empty
	-- garden would spend most of its life spoiling its own best moment.
	--
	-- Arrows is the only column the SERVER reads -- it builds that many chevron
	-- pairs and stamps the count on each. Everything else is paint and is
	-- applied per client in Ambience, because sixty parts changing colour on the
	-- server is sixty parts of replication a second for something nobody can
	-- interact with.
	--==========================================================================
	Belt = {
		-- Arrows is PAIRS: a chevron is two arms and lights as one. Bands are
		-- flat strips lying on the plate, and only rung 7 has any.
		{ Arrows = 2, Bands = 0, Neon = false, Breathe = 0, Chase = 0, Rake = 0, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0 },
		{ Arrows = 3, Bands = 0, Neon = false, Breathe = 0.30, Chase = 0, Rake = 0, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0 },
		{ Arrows = 4, Bands = 0, Neon = false, Breathe = 0.30, Chase = 0.85, Rake = 0, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0 },
		{ Arrows = 5, Bands = 0, Neon = false, Breathe = 0.30, Chase = 0.85, Rake = 0.30, Bloom = 0, Bob = 0, Shimmer = 0, Rainbow = 0 },
		{ Arrows = 5, Bands = 0, Neon = true, Breathe = 0.35, Chase = 0.70, Rake = 0.26, Bloom = 0.90, Bob = 0, Shimmer = 0, Rainbow = 0 },
		{ Arrows = 6, Bands = 0, Neon = true, Breathe = 0.35, Chase = 0.70, Rake = 0.22, Bloom = 0.90, Bob = 0.45, Shimmer = 0.35, Rainbow = 0 },
		{ Arrows = 7, Bands = 9, Neon = true, Breathe = 0.40, Chase = 0.60, Rake = 0.18, Bloom = 1.00, Bob = 0.60, Shimmer = 0.50, Rainbow = 1 },
		{ Arrows = 7, Bands = 0, Neon = true, Breathe = 0.65, Chase = 0.95, Rake = 0.35, Bloom = 1.20, Bob = 0.80, Shimmer = 0.90, Rainbow = 0 },
		{ Arrows = 8, Bands = 0, Neon = true, Breathe = 0.60, Chase = 0.80, Rake = 0.20, Bloom = 1.00, Bob = 0.50, Shimmer = 0.80, Rainbow = 0 },
		{ Arrows = 8, Bands = 12, Neon = true, Breathe = 0.70, Chase = 0.95, Rake = 0.25, Bloom = 1.00, Bob = 0.80, Shimmer = 1.00, Rainbow = 1 },
	},

	--==========================================================================
	-- ARROWS DO NOT POP IN AND OUT AT THE WRAP
	--
	-- Every arrow teleports from the front of the belt to the back once a lap.
	-- Unfaded that is a visible blink, and a blink reads as a bug rather than as
	-- tier 1 being humble. This is the fraction of the run over which one fades,
	-- and it applies to every tier for that reason -- it is correctness, not a
	-- rung on the ladder.
	--==========================================================================
	BeltEdgeFade = 0.12,

	Action = "MillUpgrade",

	--==========================================================================
	-- WHERE THE SIGN STANDS, AND WHICH WAY IT LOOKS
	--
	-- It used to sit at (8.6, -6) in the mill's own frame -- the OUTER side,
	-- away from the plot -- facing the same way the walker does. Two problems,
	-- and they are the same problem: a player coming out of their own gate saw
	-- the BACK of it, and a player standing on the belt saw it edge-on. The one
	-- board in the game that has to be read was the one nobody was ever pointed
	-- at.
	--
	-- AT THE FRONT OF THE MILL. It spent a while out on the fence line, angled
	-- at the plot gate, which put it where somebody walking out of their garden
	-- met it first -- and left it looking sideways at the machine it belongs to.
	-- The front is where the mill already points: the console is there, the
	-- mount turns a player to face it, and it is the end everybody approaches
	-- from because the road and the hub are both that way.
	--
	-- The mill's body ends at z = -8.6, so this stands four studs clear of it,
	-- square on, with no yaw at all. YAW ZERO IS THE POINT rather than an
	-- omission: the board's front already faces -Z, which is the mill's own
	-- facing, so it needs no angle of its own and swings round with the plot for
	-- free.
	--
	-- BOTH FACES EARN THEIR KEEP HERE. Front to whoever is walking up; back to
	-- the player standing on the belt, who is turned to face exactly this way by
	-- the mount.
	--==========================================================================
	Sign = {
		Offset = Vector3.new(0, -0.6, -12.6),
		YawDegrees = 0,
		--======================================================================
		-- SLIGHTLY SMALLER
		--
		-- At full size the board is nine studs wide and stands where the mill
		-- used to be visible, so walking up to your own machine meant looking at
		-- a fence-height hoarding with the machine behind it. Three quarters is
		-- enough to still read the price across the plot and small enough that
		-- the mill is the thing you see.
		--
		-- Everything the builder places scales together -- post, board, bolts,
		-- and their offsets -- because a board that shrank while its post did
		-- not would be a lollipop.
		--======================================================================
		Scale = 0.76,
		--======================================================================
		-- FAR ENOUGH TO REACH FROM THE BELT
		--
		-- The sign is 15.3 studs from the belt centre now, and it was 10.5. At
		-- the old 14 a mounted player -- who is held at WalkSpeed zero by the
		-- mount -- could no longer buy the upgrade they are standing on the
		-- thing to afford. Eighteen covers the belt and still will not open from
		-- inside somebody's bed.
		--======================================================================
		PromptRange = 18,
	},

	--==========================================================================
	-- OVERCLOCK: WHAT A TIER-TEN MILL DOES NEXT
	--
	-- Overclock is the ladder that continues past the last machine, and it is
	-- deliberately NOT more tiers: ten mills are ten distinct silhouettes with
	-- ten sets of particles, and an eleventh would have to be built, not typed.
	-- An overclock is the SAME Astral Singularity running harder. No new model,
	-- no new art, no new belt.
	--
	--     TrainingRate = tier.speed * Multiplier^level * rebirth
	--
	--==========================================================================
	-- TWO PER LEVEL, NOT FOUR, AND THAT IS A CONSEQUENCE OF THE RATE PASS
	--
	-- Four was correct when the tier ladder spanned 2 to 160. It had to be:
	-- eighty times was nothing against a score ladder that runs to a
	-- quadrillion, so ALL of the pacing lived here and 4^10 = 1,048,576x was
	-- what carried it.
	--
	-- The tiers now span 20 to 400,000,000 -- twenty million times -- and carry
	-- their own pacing. Left at four, this would multiply a rate that is already
	-- correct by another million: tier 10 overclocked would pay 4.19e14 a
	-- second and cross the entire score ladder, quadrillion and all, in TWO AND
	-- A HALF SECONDS. Every biome recommendation, every trail threshold and the
	-- whole WalkSpeed curve would be consumed between two ticks.
	--
	-- Two per level is 2^10 = 1,024x, which puts a fully overclocked tier 10 at
	-- 409.6 billion a second -- the cap in about forty minutes, which is what an
	-- endgame ceiling should cost.
	--
	-- It also makes the two ladders PRICE-COMPARABLE rather than one dominating.
	-- Cumulative overclock to level 5 is 142M and turns a Glasshouse into
	-- 1.6M/sec; tier 7 costs 150M and pays 2M/sec. Near enough that buying
	-- either is defensible. At four per level the same 142M bought 51.2M/sec and
	-- the tier ladder was strictly the wrong purchase at every price.
	--
	--     level  0    400M / sec         level  6   25.6B / sec
	--     level  1    800M / sec         level  7   51.2B / sec
	--     level  2    1.6B / sec         level  8    102B / sec
	--     level  3    3.2B / sec         level  9    205B / sec
	--     level  4    6.4B / sec         level 10    410B / sec
	--     level  5   12.8B / sec
	--
	--==========================================================================
	-- CASH IS THE ONLY REQUIREMENT
	--
	-- Levels 6-10 used to need a biome ON RECORD before they could be bought --
	-- level 6 wanted Dustbowl -- and the sign advertised that by printing the
	-- biome's name where the price goes until you had been there. That gate is
	-- gone. Every level is on sale the moment the ladder reaches it, and the
	-- price is the whole of the requirement.
	--
	-- It went because it made the upgrade board REFUSE MONEY. A player standing
	-- at the sign holding 180 million was being told to go and do something
	-- else, and a board that sends you away is not doing the job an upgrade
	-- board exists for. Robux is the second currency this ladder will take,
	-- when it takes one. A biome is not a currency.
	--
	-- The pacing that gate was doing is already in the Costs below, which climb
	-- faster than the rates they buy -- see the note under this one.
	--
	--==========================================================================
	-- THE COSTS ARE PRICED OFF THE GARDEN, NOT OFF EACH OTHER
	--
	-- Cash comes from grown plants: a size-tier base rate scaled by the species'
	-- rarity and by how deep its biome sits, so a plot is worth the sum of what
	-- is standing in it. See SeedData.IncomePerSecond -- the figures below were
	-- sized against the older tier-only rate and a curated deep-biome bed now
	-- earns rather more than the 80-150K/sec they assume.
	--
	-- Sized so CASH AND SCORE ARRIVE TOGETHER rather than one waiting on the
	-- other. Cumulative to level 8 -- the last one the five biomes need -- is
	-- 1.62B, which is about three hours at 150K/sec; the score side from zero to
	-- Starbloom at the matching rates is about 3.1 hours. Neither is the wall.
	--
	-- Levels 9 and 10 are past the last gate and priced as endgame: 6.5B more,
	-- against a garden that cannot exceed 300K/sec.
	--
	-- BALANCE, so this is the exception Rule 7 already carries for the tier
	-- ladder directly above it -- the two are one price list and splitting them
	-- across two files would be worse.
	--==========================================================================
	Overclock = {
		-- Multiplier ^ level, applied to the tier's own rate. See the note
		-- above before changing it: this number is sized against the SPREAD of
		-- the tier ladder, not chosen on its own.
		Multiplier = 2,
		MaxLevel = 10,
		-- Level N costs Costs[N], and that is the entire requirement.
		Costs = {
			3_000_000,
			7_000_000,
			16_000_000,
			36_000_000,
			80_000_000,
			180_000_000,
			400_000_000,
			900_000_000,
			2_000_000_000,
			4_500_000_000,
		},
		-- Shown on the mill sign in place of the tier name once the tier ladder
		-- is finished.
		Label = "Overclock",
	},

	--==========================================================================
	-- TRAINING RUSH: A REASON TO LEAVE THE MILL
	--
	-- Standing on a belt for an hour is not the loop this game wants. The loop
	-- is: train briefly, raid, plant, come back to a mill that is fresh again.
	-- Training Rush is what makes the fourth step worth anything -- a rested
	-- charge that pays up to four times the base rate while it lasts and
	-- nothing extra once it is spent.
	--
	-- IT IS NOT A SECOND FAUCET. TreadmillService still mints every point of
	-- Speed in the game; this is one more multiplier inside the product it
	-- already computes, alongside Overclock:
	--
	--     paid = tier.speed x Multiplier^overclock x rebirth x rush
	--
	-- AND IT IS NOT OVERCLOCK. Overclock is bought once and is permanent, which
	-- is why it is a profile field and a price list. This is spent and refills,
	-- which is why it is a clock. They multiply; neither replaces the other, and
	-- an overclocked mill rushes exactly as hard as a fresh one.
	--
	--==========================================================================
	-- WHY THESE FIVE NUMBERS
	--
	-- A full charge is 90 seconds of boosted training. The first 30 of those are
	-- spent climbing from 1x to 4x, so a full charge is worth about 315 seconds
	-- of base rate rather than 360 -- the ramp is a real cost, and it is what
	-- stops a player tapping on and off the belt to skim only the peak.
	--
	-- Refilling a full charge takes 180 seconds AWAY from the belt, which is
	-- roughly one raid and one planting round. That ratio is the whole design:
	-- three minutes of game earns ninety seconds of boosted mill.
	--
	-- The ramp DECAYS off the belt at the rate it builds, so a player who steps
	-- off for a moment keeps most of their climb and one who leaves to raid
	-- comes back at 1x. Nothing here can be gamed by remounting: charge is
	-- restored from a timestamp against real elapsed time, so the only way to
	-- gain charge is to actually spend time not training.
	--==========================================================================
	Training = {
		-- Seconds of boosted training a full charge is worth. New profiles start
		-- full, so a player's first mill session is their fastest.
		MaxChargeSeconds = 90,
		-- What the multiplier reaches at the top of the ramp.
		PeakMultiplier = 4,
		-- How long the climb from 1x to PeakMultiplier takes, in seconds of
		-- boosted training.
		RampSeconds = 30,
		-- Charge restored per second spent off the belt. Half real time, so a
		-- full 90 costs 180 seconds away.
		RestorePerSecond = 0.5,
		-- The ramp falls at this per second off the belt. Equal to the rate it
		-- builds, so leaving costs exactly what it bought.
		RampDecayPerSecond = 1,
		--======================================================================
		-- THE OFFLINE CLAMP
		--
		-- Charge is capped at MaxChargeSeconds, so a week away cannot buy more
		-- than three minutes away could -- there is no unbounded offline Speed
		-- here even without this. It exists so the ARITHMETIC is bounded too: an
		-- absent or corrupted timestamp must not produce a multi-million-second
		-- elapsed to multiply, and a documented ceiling is easier to reason
		-- about than one that happens to be safe.
		--======================================================================
		MaxOfflineRestoreSeconds = 8 * 3600,
	},
}

--==============================================================================
-- THE FLOOR MUST MATCH THE ROW IT STANDS IN FOR
--
-- GameConfig.Treadmill.SpeedPerSecond -- a DIFFERENT table from the one above,
-- which is half the reason this check exists -- is what TreadmillService pays
-- when a tier index falls off the end of Tiers. Left disagreeing with Tiers[1]
-- it would answer a different wrong number at exactly the moment something else
-- had already gone wrong, which is the hardest kind of bug to see.
--==============================================================================
assert(GameConfig.Treadmill.SpeedPerSecond == GameConfig.Mill.Tiers[1].speed,
	"GameConfig.Treadmill.SpeedPerSecond must equal GameConfig.Mill.Tiers[1].speed")


function GameConfig.parentThrowStudsFor(biomeOrder: number): number
	local P = GameConfig.Parent
	local order = math.max(1, math.floor(tonumber(biomeOrder) or 1))
	return P.BaseThrowStuds + P.ThrowPerBiome * (order - 1)
end

GameConfig.Carry = {
	-- The heaviest thing in the game. Biome 1 tops out at ~110.
	TopTierValue = 9500,
	-- Speed multiplier when carrying MaxKg.
	MinMultiplier = 0.30,
	-- Below 1 flattens the low end. 0.6 keeps small pods nearly free.
	Exponent = 0.6,
	CashPerValue = 1,

	--==========================================================================
	-- TAKING A POD IS HELD, NOT TAPPED
	--
	-- An instant take made a raid a drive-by: run through a nest, tap, gone. A
	-- hold is what puts the player STILL and EXPOSED next to a sleeping monster
	-- for a moment, which is the only part of the raid that has any tension in
	-- it -- and it is what makes the wake delay mean something, since the timer
	-- and the head start now overlap.
	--==========================================================================
	TakeHoldSeconds = 0.7,
	--==========================================================================
	-- WHERE A POD RIDES, AND WHY IT LIVES HERE
	--
	-- CarryService owns the weld, but the CLIENT needs the same numbers to point
	-- the arms at the thing. Two copies of "how far in front" is the two-names-
	-- for-one-fact bug in another coat.
	--
	-- Unchanged values, new home: a Nubkin lands 1.58 studs out and a Bellchime
	-- 3.09, which is settled and not to be retuned.
	--==========================================================================
	GripForwardBase = 0.85,
	GripDrop = -0.35,

}

-- What a carried weight does to your WalkSpeed, as a multiplier.
function GameConfig.carryMultiplierFor(tier: number): number
	local C = GameConfig.Carry
	if type(tier) ~= "number" or tier ~= tier or tier <= 0 then
		return 1
	end
	local t = math.clamp(tier / C.TopTierValue, 0, 1) ^ C.Exponent
	return 1 - (1 - C.MinMultiplier) * t
end

--==============================================================================
-- THE SCORE BECOMES A SPEED
--
-- Reads GameConfig.Speed.Anchors and interpolates between the two rows that
-- bracket the score. Nothing here decides what anything is worth -- the table
-- does, and this only walks it.
--
-- EVERY BAD INPUT LANDS ON BASE OR ON CAP, and neither is an error. A profile
-- that failed to load reads nil, a corrupted save can read a string, and NaN
-- propagates silently out of any arithmetic upstream. A game where a bad number
-- freezes the player in place is worse than one where they walk at 16.
--
--     nil / string / NaN / negative / 0   ->  BaseWalkSpeed
--     anything at or past the last anchor ->  MaxWalkSpeed  (math.huge included)
--==============================================================================
function GameConfig.walkSpeedFor(speedScore: number): number
	local S = GameConfig.Speed
	local anchors = S.Anchors
	if type(speedScore) ~= "number" or speedScore ~= speedScore or speedScore <= 0 then
		return S.BaseWalkSpeed
	end
	local last = anchors[#anchors]
	if speedScore >= last[1] then
		-- math.huge included, deliberately: the comparison is true for it and
		-- the cap is the honest answer.
		return S.MaxWalkSpeed
	end
	for i = 1, #anchors - 1 do
		local lo = anchors[i]
		local hi = anchors[i + 1]
		if speedScore < hi[1] then
			--==================================================================
			-- log(x + 1), NOT log(x)
			--
			-- The first anchor is zero and log(0) is -inf, which would make the
			-- entire first span NaN -- the one span every new player is in. The
			-- +1 costs nothing at the scales that matter (it is a 0.04%
			-- distortion at the 1,000 anchor and vanishes above it) and removes
			-- the special case entirely.
			--==================================================================
			local a = math.log(lo[1] + 1)
			local b = math.log(hi[1] + 1)
			local t = if b > a then (math.log(speedScore + 1) - a) / (b - a) else 0
			return lo[2] + (hi[2] - lo[2]) * math.clamp(t, 0, 1)
		end
	end
	return S.MaxWalkSpeed
end

--==============================================================================
-- THE TABLE IS CHECKED ON LOAD, NOT TRUSTED
--
-- A row typed out of order, a duplicated score, or a walk speed that dips is a
-- game where being faster makes you slower at exactly one point on the ladder --
-- which nobody would ever reproduce on purpose and which the curve above would
-- happily serve. Cheap to assert once at require time; impossible to notice
-- otherwise.
--==============================================================================
do
	local anchors = GameConfig.Speed.Anchors
	assert(#anchors >= 2, "GameConfig.Speed.Anchors needs at least two rows")
	assert(anchors[1][1] == 0, "the first Speed anchor must be score 0")
	assert(anchors[1][2] == GameConfig.Speed.BaseWalkSpeed,
		"the first Speed anchor must equal BaseWalkSpeed")
	assert(anchors[#anchors][2] == GameConfig.Speed.MaxWalkSpeed,
		"the last Speed anchor must equal MaxWalkSpeed")
	for i = 2, #anchors do
		assert(anchors[i][1] > anchors[i - 1][1],
			string.format("Speed anchor %d is not above the one before it", i))
		assert(anchors[i][2] > anchors[i - 1][2],
			string.format("Speed anchor %d walks slower than the one before it", i))
	end
end

--==============================================================================
-- IS IT DAY
--
-- Here rather than in the cycle service, and read straight off the attribute,
-- because CarryService and BiomeGateService both need the answer and both run
-- BEFORE the service that sets it. Requiring it from them would be a cycle:
-- WorldCycleService already requires both of them.
--
-- UNSET MEANS DAY. A server whose cycle service failed to start, or one in the
-- moments before Init, is a server where the game works -- not one where every
-- pod is unreachable and nobody can find out why.
--==============================================================================
function GameConfig.isDay(): boolean
	local phase = workspace:GetAttribute(GameConfig.Attributes.WorldPhase)
	return phase ~= GameConfig.WorldCycle.PhaseNight
end

--==============================================================================
-- REBIRTH, WHICH DOES NOT EXIST YET
--
-- A SEAM, not a stub with a TODO. Everything that computes a training rate
-- multiplies by this, so the day rebirth lands there is one function to write
-- and no call sites to find. Until then it answers 1 for everybody, which is
-- exactly what a system that does not exist should contribute.
--
-- Takes the whole profile rather than a level, so adding rebirth does not
-- change this signature.
--==============================================================================
function GameConfig.rebirthMultiplierFor(profile: any): number
	if type(profile) ~= "table" then
		return 1
	end
	return 1
end

--==============================================================================
-- WHAT AN OVERCLOCK LEVEL IS WORTH, AND WHAT IT COSTS
--
-- Level 0 is "no overclock" and is always valid. Anything outside 0..MaxLevel
-- is clamped rather than refused: this is read on the payout path, and a rate
-- of nil once a second is worse than a rate that is merely wrong.
--==============================================================================
function GameConfig.overclockMultiplierFor(level: number): number
	local O = GameConfig.Mill.Overclock
	if type(level) ~= "number" or level ~= level or level <= 0 then
		return 1
	end
	return O.Multiplier ^ math.clamp(math.floor(level), 0, O.MaxLevel)
end

-- nil when there is no such level to buy, which is also how the caller learns
-- the ladder is finished.
function GameConfig.overclockCostFor(level: number): number?
	local O = GameConfig.Mill.Overclock
	if type(level) ~= "number" or level ~= level then
		return nil
	end
	return O.Costs[math.floor(level)]
end

--==============================================================================
-- THE ONE PLACE A TRAINING RATE IS DECIDED
--
--     rate = tier.speed * Multiplier^overclock * rebirth
--
-- Here rather than in TreadmillService because the mill SIGN, the shop and any
-- future UI all want to show the same number the payout uses, and a rate that
-- is computed twice is a rate that reads differently in two places the first
-- time either is touched.
--==============================================================================
function GameConfig.trainingRateFor(tierIndex: number, overclock: number, profile: any): number
	local tiers = GameConfig.Mill.Tiers
	local i = math.clamp(math.floor(if type(tierIndex) == "number" and tierIndex == tierIndex
		then tierIndex else 1), 1, #tiers)
	return tiers[i].speed
		* GameConfig.overclockMultiplierFor(overclock)
		* GameConfig.rebirthMultiplierFor(profile)
end

--==============================================================================
-- WHICH AFTERIMAGE TIER A SCORE EARNS
--
-- 0 is "trail only". Returned as a plain integer because it is published as a
-- player attribute so that every client can render every OTHER player without
-- being handed their profile.
--==============================================================================
--==============================================================================
-- WHAT A RAMP IS WORTH
--
-- Linear from 1x at a cold start to PeakMultiplier at RampSeconds, and flat
-- after that. Shared rather than server-private because the HUD prints the same
-- number the payout uses, and a multiplier derived twice is a display that
-- disagrees with the score the first time either half is touched.
--
-- The CLIENT still never decides it: the server publishes the ramp it actually
-- paid on. This function only spares both sides from writing the same line.
--==============================================================================
function GameConfig.trainingRushMultiplier(rampSeconds: number): number
	local T = GameConfig.Mill.Training
	local r = tonumber(rampSeconds)
	if r == nil or r ~= r or r <= 0 or T.RampSeconds <= 0 then
		return 1
	end
	local t = math.clamp(r / T.RampSeconds, 0, 1)
	return 1 + (T.PeakMultiplier - 1) * t
end

function GameConfig.speedVisualTierFor(speedScore: number): number
	local tiers = GameConfig.Afterimage.Tiers
	if type(speedScore) ~= "number" or speedScore ~= speedScore or speedScore <= 0 then
		return 0
	end
	local tier = 0
	for i, row in ipairs(tiers) do
		if speedScore >= row.From then
			tier = i
		end
	end
	return tier
end

--==============================================================================
-- THE HUD RAIL IS DRAWN AGAIN, IN CODE
--
-- It was three crops of `shop index.png` -- another game's UI, uploaded to the
-- asset server -- for about a day. They looked cropped because they were: the
-- black outline and the diamond lattice were clipped on both sides, the Index
-- badge had to be mirrored out of the artwork, and all three were pinned to the
-- source's native 123 x 48 because a 170 x 152 screenshot has no resolution to
-- spare.
--
-- HANDOFF wrote down where that ends before it was a problem: "redrawing the
-- same look in code carries none of that risk and scales to any size." The
-- lattice, the slab, the icons and the labels are instances again. The image ids
-- are gone and `art/rail-*.png` stays on disk as reference for what the buttons
-- once looked like, not as anything the game loads.
--
-- STRUCTURE AND NAMES, NOT BALANCE. Rule 7 is intact: nothing here decides what
-- a thing is worth, only where it sits and what colour it is.
--==============================================================================
GameConfig.Rail = {
	-- Left rail: Index at the top, Shop under it. Garden sits opposite.
	Inset = 12,
	Gap = 6,

	-- Wide enough for an icon and a word; the square one is icon only. Chosen
	-- rather than inherited now -- 130 x 50 puts Shop's top at 68, exactly where
	-- the 123 x 48 crop left it, so nothing below the rail moved.
	WideSize = Vector2.new(130, 50),
	SquareSize = Vector2.new(50, 50),
	Radius = 12,
	LabelSize = 22,
	IconSize = 28,

	-- Thick, and black. The outline is what made the reference read as a button
	-- rather than as a coloured rectangle, and it is the one part the crops kept
	-- losing at the edges.
	Outline = Color3.fromRGB(0, 0, 0),
	OutlineThickness = 3,

	--==========================================================================
	-- THREE FACES, SO THREE BUTTONS READ AS THREE THINGS
	--
	-- Each is a face and a shade for the gradient under it. Blue, green and
	-- amber: far enough apart to be told apart at a glance in the corner of the
	-- eye, and none of them a Greenhollow plant colour -- chrome should not be
	-- mistakable for something growing.
	--==========================================================================
	IndexFace = Color3.fromRGB(64, 148, 220),
	IndexShade = Color3.fromRGB(36, 102, 168),
	ShopFace = Color3.fromRGB(86, 182, 72),
	ShopShade = Color3.fromRGB(46, 126, 44),
	GardenFace = Color3.fromRGB(236, 160, 52),
	GardenShade = Color3.fromRGB(186, 110, 28),

	-- Red, and one of the few things allowed outside ink / paper / accent: the
	-- job of a badge is to be what the eye finds before it has decided to look.
	Badge = Color3.fromRGB(226, 76, 76),
}

--==============================================================================
-- THE PANEL, WHICH IS NOT A SHOP THING
--
-- Index, Shop and Garden are one modal in three costumes, so the chrome they
-- share lives in its own table rather than inside GameConfig.Shop. It sat there
-- while the shop was the only panel and it stopped being true the moment the
-- other two stopped sliding in from the edges.
--
--==============================================================================
-- IT WAS BLACK, AND A BLACK RECTANGLE IS NOT A SURFACE
--
-- The fill was rgb(26,28,41) -- a very dark navy sampled off the reference
-- shots. Faithful, and on a screen it read as a hole cut out of the game: the
-- diamond lattice was there at 0.55 transparency and simply could not be seen,
-- so three panels of a garden game looked like three empty boxes.
--
-- Warm dark soil instead, shaded. Not invented: SeedData.SOIL is 124,76,50 and
-- MapService lays its beds at 158,82,52, so this is those two taken down into
-- shadow -- the same dirt the plants grow out of, seen from underneath a lid.
--
--     fill    rgb( 58, 38, 29)     shaded soil, the top of the gradient
--     shade   rgb( 38, 25, 19)     and the bottom of it
--     lattice rgb(132, 88, 62)     a soil HIGHLIGHT, lighter than the fill
--
-- DARKER THAN THE CARDS, ALWAYS. A card has to sit ON the panel, so the panel
-- has to be the darkest thing in the modal. Measured as relative luminance:
--
--     panel fill        42          panel shade       27
--     Index locked      50          Index seen        68
--
-- The lattice is a LIGHTER line on a DARKER fill now, which is what makes it
-- legible at all -- the old arrangement was a barely-lighter navy on navy. Pitch
-- comes down from 34 to 22, nearer the rail's 18, so a panel reads as a field of
-- diamonds rather than as four stray scratches. Still quieter than any card or
-- buy button sitting on it: the texture is behind the content, never with it.
--==============================================================================
GameConfig.Panel = {
	Fill = Color3.fromRGB(58, 38, 29),
	Shade = Color3.fromRGB(38, 25, 19),
	Outline = Color3.fromRGB(0, 0, 0),
	Lattice = Color3.fromRGB(132, 88, 62),
	LatticeSpacing = 22,
	LatticeTransparency = 0.55,
	-- The scrollbar and the thin inner lip: light enough to find on the fill.
	Edge = Color3.fromRGB(126, 96, 76),
	Title = Color3.fromRGB(255, 255, 255),
	Close = Color3.fromRGB(255, 0, 0),
}

--==============================================================================
-- THE SHOP'S PALETTE
--
-- The panel, the outline and the close button were sampled off the owner's
-- three reference shots -- `shop ui 1.png`, `shop ui 2.png`, `shop ui 3.png` --
-- with a pixel sampler rather than off a first impression. Those stay.
--
--     panel        rgb( 26, 28, 41)   very dark navy, black outline
--     panel edge   rgb( 48, 50, 61)   the lighter inner lip
--     close        rgb(255,  0,  0)   white X, black outline
--
--==============================================================================
-- THE CARDS ARE NOT CYAN ANY MORE
--
-- They were rgb(0,247,237) -> rgb(0,116,229), sampled straight off the same
-- shots. Faithful, and wrong for this game: a cyan-to-blue tile with a
-- lime-green button is another simulator's shelf, and it sat two panels away
-- from an Index full of Greenhollow greens and creams. One HUD cannot be two
-- games.
--
-- A plot card sells DIRT AND ROWS, so it is green now -- the same leaf-and-stem
-- family the plants are drawn in -- with an amber button, which is the Garden
-- rail's colour and the one warm thing on the panel. Amber against green reads
-- at a glance; lime against green does not.
--
-- OWNED goes SLATE rather than green. When the available card was cyan, green
-- could mean sold; now that available IS green, an owned card has to stop
-- competing some other way, and going grey is what "you already have this"
-- looks like everywhere.
--
-- These are NOT ink / paper / accent, exactly like the corner HUD is not. A shop
-- panel is a large surface with its own internal contrast to manage.
--==============================================================================
GameConfig.Shop = {
	Panel = Color3.fromRGB(26, 28, 41),
	PanelEdge = Color3.fromRGB(48, 50, 61),
	Outline = Color3.fromRGB(0, 0, 0),
	CardTop = Color3.fromRGB(108, 176, 84),
	CardBottom = Color3.fromRGB(56, 112, 52),
	CardBorder = Color3.fromRGB(34, 76, 36),
	SoldTop = Color3.fromRGB(88, 94, 108),
	SoldBottom = Color3.fromRGB(50, 54, 66),
	Buy = Color3.fromRGB(250, 190, 46),
	BuyShade = Color3.fromRGB(186, 130, 20),
	Close = Color3.fromRGB(255, 0, 0),
	Title = Color3.fromRGB(255, 255, 255),
	-- One colour per section, so a long shop reads as a list of shelves rather
	-- than one wall.
	Heading = Color3.fromRGB(250, 214, 108),
	Locked = Color3.fromRGB(120, 124, 140),
}

--==============================================================================
-- THE PLANT CARD
--
-- A card is a little diorama: a painted backdrop, a STILL 3D plant standing in
-- front of it, and two lines of type. The plant is the subject and everything
-- else is scenery.
--
--==============================================================================
-- THE CARD HAS NO TEXTURE OF ITS OWN, AND WILL NOT GET ONE
--
-- It carried a diamond lattice for one pass. The lattice is drawn from ROTATED
-- frames, and a rotated child escapes ClipsDescendants -- which is written up at
-- length in UIKit. Inside a ScrollingFrame that is not cosmetic: a half-scrolled
-- card threw its diamonds 342 pixels past the list and straight over the
-- Garden's footer.
--
-- A CanvasGroup contained it, but containing a bug is not fixing one. The card
-- surface is now a picture and nothing else. NO lattice, no studs, no diagonal
-- anything -- do not put rotated frames inside a scrolling card again.
--
-- The rail buttons and the modal panel keep theirs. Neither of them scrolls.
--
--==============================================================================
-- ONE PICTURE PER SPECIES, AND ONLY WHERE IT IS EARNED
--
-- Five species, five different places -- Nubkin's sunlit rows, Petalpip's
-- meadow, Spiretip's misty pines, Toadcap's rotting log, Bellchime's lanterns
-- at dusk. Drawn by tools/art/card_backdrops.py, which is the source; these ids
-- are its output.
--
-- A backdrop is IDENTITY, so it is withheld wherever identity is withheld: an
-- undiscovered Index card, a Garden pod and an empty hole all get the plain
-- dusk gradient below instead. Painting Bellchime's lanterns behind a ??? would
-- name the species through the back door as surely as printing the word.
--==============================================================================
GameConfig.Card = {
	Art = {
		nubkin = "rbxassetid://100196841981461",
		petalpip = "rbxassetid://109778696165493",
		spiretip = "rbxassetid://90680843858849",
		toadcap = "rbxassetid://110972481430448",
		bellchime = "rbxassetid://106856602665628",
	},

	-- What a card shows when it may not show a place. Grey on purpose: it
	-- carries no information except "not yet".
	DuskTop = Color3.fromRGB(134, 136, 132),
	DuskBottom = Color3.fromRGB(92, 98, 92),

	--==========================================================================
	-- THE VIEWPORT
	--
	-- A still 3D copy of the real CreatureModel, lit from one side and shot from
	-- three-quarters so the form reads as volume rather than as a sticker. The
	-- creature faces -Z, so the camera sits in front of it, to the right and
	-- above.
	--
	-- FRAMED PER MODEL, not at a fixed distance. A Bellchime is more than twice
	-- a Nubkin's height and a fixed camera would leave one filling the card and
	-- the other a speck. Relative height is already told by the sheet and by the
	-- world; a card's job is to show the SHAPE.
	--==========================================================================
	--
	-- Pitch matters more than it sounds. At 0.52 the camera looked down hard
	-- enough to show the top of every head and turn the soil heap into a flat
	-- disc jutting out of the bottom of the frame; 0.28 is a three-quarter view
	-- of a creature rather than an aerial photograph of one.
	CameraOffset = Vector3.new(0.66, 0.28, -1),
	-- 0.94 cropped the soil heap off the bottom of several forms. Just over 1
	-- fits the whole model with a hair of air, which is what a portrait wants:
	-- the box already includes the heap, so there is no need to cut into it.
	CameraFill = 1.02,
	-- The visual mass sits above the geometric centre -- the heap is wide and
	-- low -- so the camera looks a little higher than the middle of the box.
	CameraRise = 0.08,
	Ambient = Color3.fromRGB(132, 134, 146),
	LightColour = Color3.fromRGB(255, 250, 236),
	LightDirection = Vector3.new(-0.45, -1, -0.62),

	--==========================================================================
	-- THE BACKDROP IS TURNED DOWN
	--
	-- Rendered at full strength the pictures competed with the thing standing in
	-- front of them -- worst on Spiretip, whose pale spikes sat against pale
	-- mist and stopped reading. A flat multiply keeps all five recognisable as
	-- places while putting every one of them behind the plant, which is the rule
	-- the art bible states and the reason they were drawn soft to begin with.
	--==========================================================================
	ArtTint = Color3.fromRGB(202, 202, 202),

	Radius = 12,
	--==========================================================================
	-- THE POP
	--
	-- A card lifts under the pointer. 1.07 is enough to read as a lift without
	-- the card colliding with its neighbours at rest, and 0.12s is short enough
	-- that a fast pass across a grid does not leave a wave behind it.
	--==========================================================================
	HoverScale = 1.07,
	HoverSeconds = 0.12,

	--==========================================================================
	-- SELECTED IS NOT HOVERED
	--
	-- A hovered card grows; a SELECTED card gets out of its own way. It shrinks
	-- toward the top of its cell and the strip that frees up at the bottom is
	-- where the action button goes -- so the button belongs to that card, sits
	-- under its plant, and never covers a neighbour.
	--
	-- 0.84 rather than the 0.90 that first suggested itself: a 184-pixel cell
	-- only frees 18 pixels at 0.90, and a button that short cannot hold
	-- LuckiestGuy at a readable size. 0.84 frees 29, which fits a 28-pixel slab
	-- with a pixel to spare.
	--
	-- Hover is switched OFF while a card is selected. Two scales fighting over
	-- one card is how a card ends up stuck at 1.07 with a button under it.
	--==========================================================================
	SelectScale = 0.84,
	ActionHeight = 28,
	ActionFace = Color3.fromRGB(226, 96, 84),
	ActionShade = Color3.fromRGB(168, 56, 48),
	ActionTextSize = 14,
	-- Added to every layer of a hovered card so it draws over the ones beside
	-- it. Bigger than any ZIndex a card uses, so a lifted card clears a resting
	-- one whole rather than interleaving with it.
	HoverLift = 40,
}

--==============================================================================
-- THE MUSIC
--
-- ROBLOX CANNOT PLAY A FILE OFF THE DISK. The pieces live in `sfx/` and none of
-- them is what the game plays: audio has to be uploaded to the asset server
-- first, and what ships is the id that comes back. These are those ids, off the
-- owner's own account.
--
--     BGM1   133940553394248     sfx/Garden at First Light.m4a
--     BGM2    70722559996799     sfx/Garden at First Light_1.m4a
--
-- TWO TAKES OF ONE PIECE. Played in order and wrapped at the end, so the bed
-- runs about three and a quarter minutes before it repeats itself. One id here
-- would loop that one track forever instead; the list decides, not the code.
--
-- Nothing about the player picks a track. It is a bed, not a cue.
--
-- NOT BALANCE, so Rule 7 is intact: names and structure, the same way
-- GameConfig.Rail carried the rail's image ids for as long as it had any.
--==============================================================================
GameConfig.Music = {
	Tracks = {
		"rbxassetid://133940553394248",  -- BGM1
		"rbxassetid://70722559996799",   -- BGM2
	},

	--==========================================================================
	-- UNDER THE GAME, NEVER OVER IT
	--
	-- A bed sits below every cue that means something -- the RUN alarm, the
	-- hatch, the pod landing -- because a player who cannot hear the alarm over
	-- the music turns the music off, and then they cannot hear the music
	-- either. AlertUI's stinger plays at 0.55 and its pings at 0.42, so this
	-- stays well under both.
	--==========================================================================
	Volume = 0.32,

	-- Faded up at join rather than slammed on. A track that starts at full
	-- level on the loading screen is the first thing a player mutes.
	FadeSeconds = 2.5,
}

--==============================================================================
-- EVERY SOUND THAT IS NOT THE MUSIC BED
--
-- ONE CUE PER LINE, AND AN EMPTY ID IS A SILENT CUE RATHER THAN A BROKEN ONE.
-- SoundKit skips any row with no id: no error, no warning at the call site, and
-- the game behaves exactly as it does with the row absent. That is what makes
-- this table fillable ONE ROW AT A TIME, in any order, by somebody who is not
-- reading the code that plays it. Paste an id, hear the cue.
--
-- What was here before was six ids in a flat map that nothing read, kept "so
-- the ids are not lost". Ids that nothing reads rot: five of those six were
-- deleted off the account and this table went on claiming they existed. Every
-- row below has a trigger in a specific script, which is the only thing that
-- makes a wrong id noticeable.
--
--==============================================================================
-- WHAT A ROW MEANS
--
--   id        rbxassetid://N, or "" for not recorded yet.
--   volume    0-1, before the bus level below.
--   pitch     PlaybackSpeed. 1 is the file as recorded.
--   jitter    +/- this much pitch, per play. A hover that plays at exactly the
--             same pitch every time turns into a woodpecker the moment somebody
--             sweeps the pointer down a grid of cards.
--   group     which bus it rides. Decides what a future volume slider moves.
--   looped    for the two that are beds rather than hits.
--   range     studs. Positional cues only; ignored by the 2D ones.
--
-- LEVELS ARE SET AGAINST THE FOUR SOUNDS ALREADY PLAYING. AlertUI's stinger is
-- 0.55 and its alarm pings are 0.42, and the music bed sits under both at 0.32.
--
-- THE RULE IS ABOUT WHAT CAN PLAY WHILE THE ALARM IS UP, not about the loudest
-- number in the table. Anything that can sound DURING a carry -- the hover, the
-- click, the tick, the panels -- stays well under 0.42, because a player who
-- cannot hear the alarm over a card hover is a player who turns the sound off,
-- and then they cannot hear the alarm either.
--
-- Three cues sit above it on purpose. Banked (0.50) plays at the instant the
-- alarm STOPS and is the thing replacing it. RevealEpic and RevealLegendary
-- (0.45, 0.55) happen in your own garden, at the one moment this game reveals
-- anything, and a payoff that has to be quieter than a warning is not a payoff.
--
-- NOT BALANCE, so Rule 7 is intact. How loud a thing is and how far it carries
-- is structure; none of it decides what anything is worth.
--==============================================================================
GameConfig.Sfx = {
	--==========================================================================
	-- FOUR BUSES
	--
	-- Because they are four different arguments about volume: music is a
	-- preference, the chase is drama, the UI is feedback and the world is
	-- distance. One master would make "quieter menus" and "quieter monster" the
	-- same setting, and they are not the same setting.
	--==========================================================================
	Mixer = {
		Music = 1.0,
		Chase = 1.0,
		UI = 1.0,
		World = 1.0,
	},

	--==========================================================================
	-- THE GARDEN BED GETS OUT OF THE CHASE BED'S WAY
	--
	-- Down to a third rather than off. Off is a hole -- the moment the chase
	-- ends the bed slams back in and the player hears the SYSTEM rather than the
	-- game. A third is still there, still keying the garden, and no longer
	-- arguing with the drums.
	--==========================================================================
	MusicDuck = 0.34,
	DuckSeconds = 0.6,

	--==========================================================================
	-- WHICH FILE IN sfx/ BECOMES WHICH ROW
	--
	-- ROBLOX CANNOT PLAY A FILE OFF THE DISK. Everything in sfx/ is a source;
	-- what the game plays is the id that comes back from uploading it. So this
	-- table is the seam between the two, and this is the map across it -- because
	-- "which WAV was CardHover again" is a question that has to be answerable a
	-- month from now, by somebody looking at either end.
	--
	--   CardHover         CARD HOVER POP.wav
	--   CardClick         CARD CLICK.wav
	--   Denied            NOT ENOUGH CASH.wav
	--   PanelOpen         PANEL OPEN.wav
	--   PanelClose        PANEL OPEN.wav again -- the same asset, pitched up 6%
	--                     and cut a third shorter. The reverse was never
	--                     recorded; this is a stand-in, not the answer.
	--   CashTick          CASH TICK.wav
	--   Banked            BANKED -- A POD MADE IT HOME.wav
	--   ChaseBed          Chase bed (Loop) -- the ORIGINAL upload, recovered.
	--                     CHASE BED, SECOND TIER.wav is uploaded and unused: it
	--                     is the escalation, and there is no state to escalate
	--                     on yet.
	--   RevealCommon      Common rarity.wav
	--   RevealRare        rare rarity.wav
	--   RevealEpic        epic rarity.wav
	--   RevealLegendary   legendary rarity.wav
	--   MillMount         MOUNTING belt.wav
	--   MillUpgrade       MILL UPGRADE BOUGHT.wav
	--   ParentSleep       parent sleep sound.wav -- uploaded, and the only row
	--                     below that already has its id.
	--
	-- TakePod, Grab, Throw and ChaseStep have no local WAV -- those five files
	-- were deleted. THE UPLOADED ASSETS WERE NOT, and all five still load, so
	-- they are wired from the account's own audio inventory rather than left
	-- silent. Prompts 15 to 19 in sfx/suno prompts.txt replace any of them.
	--
	-- TITLE  LOADING.wav has no row because it has no trigger: there is no
	-- loading screen to play it under. It is a bed, not a cue -- when there is
	-- somewhere to put it, it goes in GameConfig.Music, not here.
	--==========================================================================
	--==========================================================================
	-- THE NUMBERS ARE MEASURED, NOT GUESSED
	--
	-- Every `volume`, `start` and `clip` below came off the WAV in sfx/ rather
	-- than off a slider, because the uploads are RAW SUNO RENDERS and a raw
	-- render is not a game sound. Two things were wrong with all fourteen and
	-- neither is audible until it is in the game:
	--
	-- THEY ARE NOT TRIMMED. `CARD HOVER POP` is five seconds containing THIRTEEN
	-- separate pops; playing it on hover plays all thirteen. `CARD CLICK` opens
	-- with 140ms of silence, so the click lands a sixth of a second after the
	-- press. `PANEL OPEN` has a 290ms lead-in and a second thump at 1.04s.
	--
	-- THEIR LEVELS ARE ALL OVER THE PLACE. Peak amplitude runs from 7% of full
	-- scale (Common rarity) to 100% (Mill upgrade) -- a 23 dB spread across
	-- sounds that are supposed to sit in one mix. Volume below is therefore the
	-- DESIGNED level divided by the file's measured peak, which is why some of
	-- them are above 1: Banked peaks at 11%, so 0.50 of designed level is 4.37
	-- of gain.
	--
	-- Checked before doing it: the quietest 20ms window in each file is its
	-- noise floor, and after the gain above the worst case (Banked, 8.7x) still
	-- sits at -50 dB. Nothing here surfaces hiss. If a file is ever normalised
	-- and re-uploaded, drop its volume back to the designed number in the
	-- comment beside it.
	--
	-- start/clip are a WINDOW INTO THE ASSET, not a substitute for trimming. It
	-- is exact and it costs nothing, but a trimmed re-upload is smaller, starts
	-- instantly, and lets both fields go away.
	--==========================================================================
	Cues = {
		--======================================================================
		-- THE SCREEN
		--======================================================================
		-- Pop 1 of 13, at 0.088. Fires more often than anything else in the
		-- game, so it is also the quietest thing in the game. Designed 0.20.
		CardHover = {
			id = "rbxassetid://93538481108310",
			volume = 0.24, start = 0.08, clip = 0.14, jitter = 0.06, group = "UI",
		},
		-- 140ms of dead air before the click. Designed 0.30.
		CardClick = {
			id = "rbxassetid://113610810828248",
			volume = 0.30, start = 0.12, clip = 0.20, jitter = 0.04, group = "UI",
		},
		-- Peaks at 18%. Designed 0.30.
		Denied = { id = "rbxassetid://102715407432501", volume = 1.68, group = "UI" },
		-- The swoosh starts at 0.29 and the thump lands at 0.43; the second
		-- thump at 1.04 is a different take and is cut off. Designed 0.28.
		PanelOpen = {
			id = "rbxassetid://131340288435165",
			volume = 0.28, start = 0.27, clip = 0.50, group = "UI",
		},
		--==================================================================
		-- CLOSING IS THE SAME ASSET, PITCHED UP AND CUT SHORT
		--
		-- The reverse was never recorded, so this is the honest version of
		-- what is available: the same gesture, 6% faster and a third
		-- shorter, which reads as quicker without pretending to be a
		-- different sound. It is a stand-in. A reversed upload of its own is
		-- still the right answer.
		--==================================================================
		PanelClose = {
			id = "rbxassetid://131340288435165",
			volume = 0.28, pitch = 1.06, start = 0.27, clip = 0.34, group = "UI",
		},
		-- 130ms late, then a 540ms decay that would ring under a counter
		-- ticking three times a second. Designed 0.15.
		CashTick = {
			id = "rbxassetid://107680742328909",
			volume = 0.23, start = 0.13, clip = 0.16, jitter = 0.03, group = "UI",
		},

		--======================================================================
		-- THE RUN
		--======================================================================
		-- Peaks at 11%, the quietest upload of the fourteen. Designed 0.50.
		Banked = { id = "rbxassetid://90673825356478", volume = 4.37, group = "UI" },
		--==================================================================
		-- THE BASE BED, NOT THE SECOND TIER
		--
		-- There are two chase beds now. This is the original 5.56s loop --
		-- the one written to run for a whole way home. `CHASE BED, SECOND
		-- TIER` (110892791280400, 4.00s) is the more frantic one and has
		-- nowhere to go yet: escalating needs a state that says a chase is
		-- WORSE than usual, and this game does not have one. When it does --
		-- an expensive pod, or a third theft from the same nest -- that id is
		-- what it escalates to.
		--==================================================================
		ChaseBed = {
			id = "rbxassetid://86935894428393",
			volume = 0.40, looped = true, group = "Chase",
		},

		--======================================================================
		-- THE REVEAL
		--
		-- The hatch is the only moment this game reveals anything, so the rarer
		-- it is the longer the sound is allowed to take: 0.77s, 0.17s, 0.49s and
		-- 1.06s of content. Not clipped -- every one of them starts at zero and
		-- a musical tail is the part you would be cutting.
		--======================================================================
		-- Peaks at 7%. Designed 0.30.
		RevealCommon = { id = "rbxassetid://74338267139417", volume = 4.45, group = "UI" },
		-- Peaks at 83%. Designed 0.35.
		RevealRare = { id = "rbxassetid://99776609601370", volume = 0.42, group = "UI" },
		-- Peaks at 30%. Designed 0.45.
		RevealEpic = { id = "rbxassetid://83653226797020", volume = 1.52, group = "UI" },
		-- Peaks at 87%. Designed 0.55.
		RevealLegendary = { id = "rbxassetid://73136314922937", volume = 0.64, group = "UI" },

		--======================================================================
		-- THE MILL
		--
		-- Both positional and both audible from off the plot, on purpose: a
		-- neighbour buying tier 6 is the most persuasive advertisement this game
		-- has, and it is free.
		--======================================================================
		-- 160ms of thud followed by three and a half seconds of nothing.
		-- Designed 0.45.
		MillMount = {
			id = "rbxassetid://137166099826620",
			volume = 0.82, clip = 0.60, range = 90, group = "World",
		},
		-- Designed 0.60, and the file already peaks at full scale.
		MillUpgrade = {
			id = "rbxassetid://102053237936114",
			volume = 0.60, clip = 1.20, range = 140, group = "World",
		},

		--======================================================================
		-- THE NEST
		--
		-- ALL FOUR OF THESE ARE THE ORIGINAL UPLOADS. The local WAVs were
		-- deleted; the ASSETS were not, and all four still load. Recovered out
		-- of the account's own audio inventory rather than left silent, because
		-- the alternative was a monster that chases you without a sound.
		--
		-- Their numbers are the DESIGNED levels and nothing else -- unlike the
		-- fourteen above, there is no local file left to measure, so no trim and
		-- no gain compensation. If any of them turns out to be quiet or to open
		-- with dead air, prompts 15 to 19 in sfx/suno prompts.txt will replace
		-- it and the measurement can be done properly.
		--
		-- Grab is the parent's hand closing on you, a fifth of a second before
		-- Throw. Two beats of one event, so they have to sit together.
		--======================================================================
		TakePod = { id = "rbxassetid://130694487616211", volume = 0.55, range = 90, group = "World" },
		Grab = { id = "rbxassetid://113282797733918", volume = 0.75, range = 140, group = "World" },
		Throw = { id = "rbxassetid://131635221141553", volume = 0.85, range = 160, group = "World" },
		-- 7.72s of running steps. Set looped = false if it turns out to be a
		-- SINGLE step; SoundCues retriggers it per stride in that case.
		ChaseStep = {
			id = "rbxassetid://84880778606132",
			volume = 0.50, range = 110, looped = true, group = "World",
		},
		-- Peaks at 74%. Designed 0.35.
		ParentSleep = {
			id = "rbxassetid://81143161269823",
			volume = 0.47, range = 70, looped = true, group = "World",
		},
	},

	--==========================================================================
	-- WHICH REVEAL A SPECIES GETS
	--
	-- EIGHT RARITIES, FOUR RECORDED CUES. Mapped here rather than in the script
	-- that plays them, so recording a fifth is a line in this table and not a
	-- branch somewhere in a client.
	--
	-- This is the FORM rarity off the species sheet -- how often that shape turns
	-- up -- and not SeedData.RarityForKg, which is the weight band the pod wears
	-- as its colour. Two vocabularies share four words in this game and the
	-- hatch is the one that reveals the SHAPE.
	--==========================================================================
	RevealFor = {
		Common = "RevealCommon",
		Uncommon = "RevealCommon",
		Rare = "RevealRare",
		Epic = "RevealEpic",
		Legendary = "RevealLegendary",
		Mythic = "RevealLegendary",
		Secret = "RevealLegendary",
		Divine = "RevealLegendary",
	},
}

--==============================================================================
-- THE TWO NUMBERS THAT POP OFF THINGS
--
-- A `+$N` rises off every grown plant once a second, and a `+N` rises off the
-- player while they are on a mill. They are the only two floating numbers in the
-- game and they were THE SAME OBJECT: GothamBlack, lime, three-pixel ink
-- outline, rise two and a half studs, fade over 1.1 seconds. The only thing
-- telling them apart was a 22-pixel blue shoe, and at any distance where these
-- are actually read -- across a plot, from the road -- that shoe is four pixels
-- wide.
--
-- So a player watching their own screen could not tell what had just paid them.
-- Which is the entire job of a floating number.
--
--==============================================================================
-- THEY ARE DIFFERENT AT SILHOUETTE, NOT AT COLOUR
--
-- Colour alone does not survive distance, colourblindness, a green plot, or a
-- bright sky. The two differ in the shape of the letters first:
--
--     CASH    LuckiestGuy -- fat, round, upright. Gold into lime, top to
--             bottom, like a coin catching the light. It POPS IN with an
--             overshoot and a slight tilt, because money should land with
--             weight, and it holds full opacity for half its life so the
--             number is readable rather than glimpsed.
--
--     SPEED   Bangers -- narrow, sharp, and slanted by the typeface itself
--             rather than by a rotation. White into blue. No pop-in, a shorter
--             life, and it slides SIDEWAYS as it rises so it reads as being
--             left behind rather than lifting off.
--
-- Round-fat-upright-gold against narrow-sharp-leaning-blue is a difference you
-- can still make at the edge of the 90-stud draw distance, with the text too
-- small to read.
--
-- BOTH FONTS WERE CHECKED FOR TOFU. Most of this engine's symbol range renders
-- as blank boxes -- the shoe beside the speed pop is built from two rounded
-- frames for exactly that reason -- so every glyph these need was rendered and
-- looked at before either was chosen.
--
-- NOT BALANCE. How a number is dressed, never what it is worth.
--==============================================================================
GameConfig.Pops = {
	Cash = {
		Font = Enum.Font.LuckiestGuy,
		-- Gold at the head, the game's lime at the foot. Gold is the one
		-- saturated colour Greenhollow spends, and it is spent here because this
		-- is a HUD readout rather than a plant -- the art bible's warning is
		-- about the world, and a coin that looks like a leaf is not a coin.
		Top = Color3.fromRGB(255, 216, 102),
		Bottom = Color3.fromRGB(142, 196, 62),
		Outline = Color3.fromRGB(26, 24, 30),
		OutlineThickness = 3,
		Width = 108,
		Height = 34,
		RiseStuds = 2.5,
		-- Straight up. Money is not going anywhere.
		DriftStuds = 0,
		Seconds = 1.15,
		--======================================================================
		-- IT LANDS, THEN IT LIFTS
		--
		-- Scales up from small through an overshoot. A number that simply
		-- appears at full size has no impact; one that arrives has weight, and
		-- weight is the whole reading of a payout.
		--======================================================================
		PopFrom = 0.55,
		PopOvershoot = 1.14,
		PopSeconds = 0.22,
		-- Degrees, plus or minus, chosen per pop. LuckiestGuy is dead upright,
		-- and forty of them rising off one bed in a ruler-straight column looks
		-- printed rather than alive.
		TiltJitter = 6,
		-- Fraction of its life at full opacity before the fade starts. Half,
		-- because the number is the point.
		Hold = 0.5,
	},

	Speed = {
		Font = Enum.Font.Bangers,
		-- Slanted by the typeface. Nothing here rotates the label -- a rotated
		-- upright font reads as a mistake, a genuinely italic one reads as fast.
		Top = Color3.fromRGB(240, 250, 255),
		Bottom = Color3.fromRGB(96, 164, 232),
		-- A cooler ink than the cash pop's, so even the outline is a different
		-- temperature.
		Outline = Color3.fromRGB(16, 26, 46),
		OutlineThickness = 3,
		Width = 104,
		Height = 32,
		RiseStuds = 2.0,
		--======================================================================
		-- IT SLIDES AS IT RISES
		--
		-- Sideways as well as up, alternating by pool slot. Two effects at once:
		-- consecutive pops stop stacking into an illegible column, and the
		-- number reads as being LEFT BEHIND, which is the only thing a speed
		-- readout should ever look like.
		--======================================================================
		DriftStuds = 1.1,
		-- Shorter than the cash pop on purpose. Fast things do not linger.
		Seconds = 0.85,
		-- No pop-in. It is already moving.
		PopFrom = 1,
		PopOvershoot = 1,
		PopSeconds = 0,
		TiltJitter = 0,
		Hold = 0.22,
	},
}

--==============================================================================
-- THE TWO PIECES OF TEXT THE WORLD ITSELF CARRIES
--
-- Everything else in this game that says something is on the HUD -- the cash
-- readout, the world clock, the alarm. These two are in the WORLD, attached to a
-- thing, and until now they were the same GothamBold paper-and-lime as the rest
-- of it: a pod's countdown and a prompt's verb were typographically identical to
-- the corner of the screen, so nothing about them said "this belongs to the
-- object you are looking at".
--
--     POD     what a buried pod is doing, and how long is left of it
--     PROMPT  the key, and the verb it performs
--
-- One is a LABEL on a growing thing and the other is a BUTTON. They should not
-- look like each other either, and neither should look like the HUD.
--==============================================================================
GameConfig.Labels = {
	--==========================================================================
	-- THE POD: A SEED PACKET, NOT A PROGRESS BAR
	--
	-- FredokaOne is the roundest face in the project -- already used on the biome
	-- arches -- and round is what a buried seed should read as. It is warm cream
	-- rather than paper white, which is the Crown colour every Greenhollow
	-- creature already wears, so the label looks like it grew there.
	--
	--======================================================================
	-- THE CLOCK RIPENS FROM AMBER TO GREEN
	--
	-- This is the part that is worth more than the typeface. The number already
	-- says how long is left; the COLOUR says it without being read. A pod
	-- crossing a bed at a glance is amber when it has just gone in and green
	-- when it is nearly out, so a player walking their plot knows which square
	-- to stand near without stopping at any of them.
	--
	-- Green at the end and not at the start, because green is what this whole
	-- palette means by "ready" -- it is the colour of the prompt that replaces
	-- this label the moment the clock runs out.
	--======================================================================
	Pod = {
		Font = Enum.Font.FredokaOne,
		WordSize = 13,
		ClockSize = 18,
		-- The Crown cream off the species sheet.
		Word = Color3.fromRGB(242, 238, 206),
		ClockYoung = Color3.fromRGB(255, 190, 90),
		ClockReady = Color3.fromRGB(142, 214, 86),
		Outline = Color3.fromRGB(26, 24, 30),
		OutlineThickness = 2,
		--======================================================================
		-- THE STRINGS
		--
		-- Growing is unreachable today: PlantService rebuilds a plant at every
		-- stage change and nothing in a bed is ever a sprout, so a pod is a pod
		-- until it is grown. It is here because the stage still exists in
		-- CreatureModel and the day it comes back this is where its word lives
		-- -- not buried in a client as a literal nobody can find.
		--======================================================================
		Hatching = "HATCHING",
		Growing = "GROWING",
	},

	--==========================================================================
	-- THE PROMPT: A BUTTON
	--
	-- DenkOne is condensed, geometric and upright -- it reads as a control
	-- rather than as a caption, which is exactly what a prompt is. Distinct from
	-- all four faces already in use: LuckiestGuy is money, Bangers is speed,
	-- FredokaOne is now the pod, GothamBlack is the HUD.
	--
	-- THE VERB IS UPPERCASED HERE rather than in the four places that set an
	-- ActionText. `prompt.ActionText` stays "Pick Up" because that is what it
	-- is; how loudly it is said is this file's business, and a service should
	-- not have to shout to be drawn correctly.
	--==========================================================================
	Prompt = {
		Font = Enum.Font.DenkOne,
		KeySize = 20,
		VerbSize = 21,
		Verb = Color3.fromRGB(248, 246, 240),
		Key = Color3.fromRGB(26, 24, 30),
		Outline = Color3.fromRGB(26, 24, 30),
		OutlineThickness = 2,
		Uppercase = true,
	},
}

--==============================================================================
-- ONE COMPACTOR, NOT THREE
--
-- Four places want to shorten a number -- the rate on a grown plant, the `+$N`
-- that pops off it, the Index row, and now every Speed readout in the game --
-- and four hand-rolled versions is how the same plant ends up reading $1.5K in
-- one place and $2K in another. It sits here because here is the module they
-- all already require.
--
-- Not balance, so Rule 7 is intact: this decides how a number is SPELLED, never
-- what it is.
--
--==============================================================================
-- THREE SIGNIFICANT DIGITS, AND THE LADDER RUNS TO Qa
--
-- It was one decimal below ten and none above, which reads fine for cash and
-- destroys the Speed HUD: the whole billions ladder this game is built on
-- collapsed into "12B" for everything from 12.0B to 12.9B, so a player watching
-- their score climb saw it sit still for the better part of an hour.
--
--     under 10     two decimals    1.25K   3.5K    1T
--     10 to 99     one decimal     12.4B   39K
--     100 and up   none            999B    553M    100K
--
-- Trailing zeros are dropped at every width, so 2,000 is "2K" rather than
-- "2.00K" and 1e15 is "1Qa" rather than "1.00Qa" -- which is what keeps the old
-- cash readouts spelled exactly as they were.
--
--     110    ->  110        1500  ->  1.5K       39000  ->  39K
--     2000   ->  2K       100000  ->  100K   553000000  ->  553M
--     12.4e9 -> 12.4B      999e9  ->  999B        1e12  ->  1T
--     1e15   ->  1Qa
--
-- Qa AND NOT Q. "Q" is ambiguous the moment quintillion exists, and this ladder
-- is one save-cap raise away from needing it. Qa/Qi/Sx is the convention the
-- genre already uses.
--
-- THE SAVE CAP IS STILL 1e15 and this does not change that -- the formatter
-- reaching Qa is what lets the CAP be displayed, not a licence to pass it.
--==============================================================================
local COMPACT_UNITS = {
	{ 1e15, "Qa" },
	{ 1e12, "T" },
	{ 1e9, "B" },
	{ 1e6, "M" },
	{ 1e3, "K" },
}

local function trimZeros(text: string): string
	-- A PLAIN find, so the needle is a full stop and not the PATTERN for one.
	-- It was `"%."` with plain = true, which searches for the two literal
	-- characters percent-full-stop -- never present -- so every value returned
	-- early and the HUD read 1.00K, 3.00B, 1.00Qa. The pattern escape is exactly
	-- what plain mode turns off.
	if not string.find(text, ".", 1, true) then
		return text
	end
	-- Parenthesised: gsub returns the count as a second value, and returning it
	-- would make the caller two-valued.
	text = (string.gsub(text, "0+$", ""))
	return (string.gsub(text, "%.$", ""))
end

function GameConfig.compact(n: number): string
	if type(n) ~= "number" or n ~= n then
		return "0"
	end
	local sign = if n < 0 then "-" else ""
	local v = math.abs(n)
	if v == math.huge then
		-- Not "inf". Nothing in this game is legitimately infinite, so a readout
		-- saying so is a bug report nobody can act on; the cap is the number a
		-- player would actually be at.
		return sign .. GameConfig.compact(GameConfig.Save.MaxSpeedScore)
	end
	for i, unit in ipairs(COMPACT_UNITS) do
		local divisor = unit[1] :: number
		local suffix = unit[2] :: string
		if v >= divisor then
			local scaled = v / divisor
			--==============================================================
			-- 999.6M IS 1B, NOT 1000M
			--
			-- Rounding happens after the unit is chosen, so a value just under
			-- a boundary can round up THROUGH it and print a four-digit
			-- mantissa. Caught here rather than by widening the comparison,
			-- because the comparison is what decides the suffix and it is
			-- correct.
			--==============================================================
			if scaled >= 999.5 and i > 1 then
				local bigger = COMPACT_UNITS[i - 1]
				scaled = v / (bigger[1] :: number)
				suffix = bigger[2] :: string
			end
			local text
			if scaled < 10 then
				text = string.format("%.2f", scaled)
			elseif scaled < 100 then
				text = string.format("%.1f", scaled)
			else
				text = string.format("%.0f", scaled)
			end
			return sign .. trimZeros(text) .. suffix
		end
	end
	return sign .. string.format("%d", math.floor(v))
end

--==============================================================================
-- HOW HIGH A PLANT ACTUALLY REACHES
--
-- Model:GetBoundingBox() REPORTS IN THE PIVOT'S FRAME, and a creature pivots on
-- a cylinder rolled ninety degrees -- so its X and Y come back swapped and the
-- "height" it hands you is the WIDTH. Measured on real grown models:
--
--     Nubkin     bbox (1.74, 1.11, 1.11)      true height 1.74, width 1.11
--     Spiretip   bbox (4.20, 2.11, 2.11)      true height 4.20, width 2.11
--     Bellchime  bbox (6.41, 4.33, 4.33)      true height 6.41, width 4.33
--
-- Those X values are exactly the finished heights SeedData documents. PlantUI
-- placed its billboard at `bbox.Y * 0.5 + 1.4` and so put a Bellchime's label
-- 3.56 studs up on a plant 6.19 studs tall -- a label INSIDE the head of the
-- most valuable thing in the biome, which nobody spotted because on a Nubkin the
-- same wrong sum lands close enough to look right.
--
-- This measures in WORLD SPACE instead, where there is no frame to be wrong
-- about: the vertical reach of a rotated box is the sum of the absolute vertical
-- components of its three half-axes.
--
-- It lives here because two clients want it -- the name plate and the cash pop
-- -- and two hand-rolled copies of a measurement is how they end up disagreeing
-- about where the top of a plant is.
--==============================================================================
function GameConfig.topOfModel(model: Model, anchor: BasePart): number
	local highest = -math.huge
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local cf, size = d.CFrame, d.Size
			local reach = math.abs(cf.UpVector.Y) * size.Y * 0.5
				+ math.abs(cf.RightVector.Y) * size.X * 0.5
				+ math.abs(cf.LookVector.Y) * size.Z * 0.5
			highest = math.max(highest, cf.Position.Y + reach)
		end
	end
	if highest == -math.huge then
		return 2
	end
	return highest - anchor.Position.Y
end

--==============================================================================
-- SAVE
--
-- Forward-only. Never lower CurrentVersion without also changing StoreName: an
-- old server reading a newer profile is the one way to lose an account.
--==============================================================================
GameConfig.Save = {
	StoreName = "StealASeed_v1",
	CurrentVersion = 2,
	AutosaveSeconds = 45,
	MinWriteGap = 7,
	RetryAttempts = 4,
	RetryBackoff = 1,

	--==========================================================================
	-- THE CEILINGS, AND WHY THEY ARE HERE RATHER THAN IN A BALANCE FILE
	--
	-- Luau numbers are IEEE doubles: exact for integers to 2^53 (~9.007e15) and
	-- silently approximate above it. Silently is the whole problem -- no error,
	-- just cash that stops adding up and a profile that round-trips to a
	-- different value than it left as. That makes these a SAVE INTEGRITY
	-- constraint, not a tuning knob, which is why they live next to the schema.
	--
	-- 1e15 leaves an order of magnitude of headroom under the exact range, so
	-- intermediate arithmetic cannot drift either.
	--
	-- The reference game runs at 2.7 BILLION/sec, which would reach this in
	-- about four days. That is not an argument for a bigger number, because
	-- there isn't one -- 9e15 is only 9x further and no cap survives an
	-- unbounded rate. It is an argument about the RATE, which is ours to set:
	-- plant yields get tuned so Rebirth arrives long before the ceiling does.
	--==========================================================================
	MaxCash = 1e15,
	MaxSpeedScore = 1e15,
	--==========================================================================
	-- HOW MANY HELD PLANTS COME BACK
	--
	-- The hotbar is saved now, and a saved list is rebuilt into real Tools with
	-- real geometry on join. Roblox gives a Backpack far more slots than a
	-- player can reach, so the cap is about the WORK: twenty-four creatures at
	-- up to forty parts each is already a thousand parts built at the least
	-- convenient moment there is.
	--
	-- Nothing silently truncates -- ProfileSchema stops at this number and the
	-- restore says how many it dropped.
	--==========================================================================
	MaxHeld = 24,

	--==========================================================================
	-- SESSION LOCK
	--
	-- How long another server's claim on a profile is respected before it is
	-- assumed dead and taken. Too short and a live server gets its profile
	-- stolen mid-session; too long and a player who hops servers waits.
	--
	-- The failure this prevents is the classic one: leave server A, join server
	-- B before A has written, B loads stale data, B saves over A. Progress is
	-- gone and nothing errored.
	--==========================================================================
	SessionLockSeconds = 120,
	LoadAttempts = 5,
	LoadRetryGap = 3,
}

-- How deep a plot with this many bed rows has to be. One expression, read by
-- the tier table, the map builder and the field-size check alike.
function GameConfig.plotDepthFor(rows: number): number
	local P = GameConfig.Plot
	return P.BedMargin * 2 + rows * P.RowDepth + (rows - 1) * P.RowGap
end

--==============================================================================
-- HOW WIDE A PLOT IS AT A GIVEN LEVEL, WING INCLUDED
--
-- Levels 1 and 2 are the plain rectangle they have always been. From Level 3
-- the footprint is an L: full width at the front, wider across the back half.
--==============================================================================
function GameConfig.plotSideRowsForTier(tier: number?): number
	local n = tonumber(tier)
	if n == nil or n ~= n then
		n = GameConfig.StartingPlotTier
	end
	local level = math.clamp(math.floor(n), 1, #GameConfig.PlotTiers)
	return GameConfig.Plot.SideBed.RowsByLevel[level] or 0
end

function GameConfig.plotHasSideBed(tier: number?): boolean
	return GameConfig.plotSideRowsForTier(tier) > 0
end

--==============================================================================
-- WHERE THE WING SITS, IN PLOT-LOCAL Z
--
-- Rear-anchored: its BACK edge lines up with the main bed's back edge, and it
-- reaches forward only as far as its own rows need. Returns front and back Z,
-- or nil when the level has no wing.
--
-- The main bed spans `rows * RowDepth + (rows - 1) * RowGap` centred on the
-- plot, so its back edge is at half that. The wing shares it.
--==============================================================================
function GameConfig.plotSideBedZ(tier: number?): (number?, number?)
	local sideRows = GameConfig.plotSideRowsForTier(tier)
	if sideRows <= 0 then
		return nil, nil
	end
	local P = GameConfig.Plot
	local mainRows = GameConfig.plotRowsForTier(tier)
	local backZ = (mainRows * P.RowDepth + (mainRows - 1) * P.RowGap) * 0.5
	local span = sideRows * P.RowDepth + (sideRows - 1) * P.RowGap
	-- Capped so the wing's FENCE -- which stands WingMargin + a frame width
	-- forward of the bed -- can never reach past the treadmill. RowsByLevel is
	-- already chosen to satisfy this; the clamp is here so that changing a row
	-- count can shorten a bed but can never fence in the mill.
	local minBedFront = P.SideBed.WingFrontZ + P.SideBed.WingMargin + P.BedFrameWidth
	return math.max(backZ - span, minBedFront), backZ
end

--==============================================================================
-- HOW FAR FROM THE GATE A PLANT CAN ACTUALLY STAND
--
-- The gate is the one fixed landmark in a plot: local -Z faces it, so a plant's
-- distance from it is `z + depth/2` -- a number that survives the plot being
-- rebuilt at a different depth, which is exactly what an upgrade does and what
-- the v1 -> v2 migration has to reason about.
--
-- The reachable range is set by the SOIL, not the plot. Soil is centred on the
-- plot and spans `depth - BedMargin * 2`, and PlantService keeps plants
-- EdgeMargin inside that, so both ends come out as a constant inset from the
-- fence. Near edge is `BedMargin + EdgeMargin` at every level -- the bed always
-- starts the same distance behind the gate -- and only the far edge grows.
--
-- Two callers need the same answer and must not each derive it: the migration,
-- deciding whether an old garden reaches, and anything later that has to place
-- a plant against a plot it is not standing in.
--==============================================================================
function GameConfig.plotGateReach(rows: number): (number, number)
	local P = GameConfig.Plot
	local inset = P.BedMargin + GameConfig.Plant.EdgeMarginStuds
	local depth = GameConfig.plotDepthFor(rows)
	return inset, math.max(depth - inset, inset)
end

--==============================================================================
-- THE INVISIBLE GRID, WHICH IS NOT THE CAPACITY
--
-- Still how many attachment points a bed of `rows` rows has, and MapService and
-- PlantService both lay plants out against it. It is NOT how many plants a plot
-- may hold -- that is plotCapacityForTier below, and confusing the two is the
-- bug this pass exists to remove.
--==============================================================================
function GameConfig.plotSlotsFor(rows: number): number
	return rows * GameConfig.Plot.BedColumns
end

--==============================================================================
-- HOW MANY PLANTS A LEVEL HOLDS
--
-- The single answer, for the server that enforces it and the two panels that
-- display it. Clamped rather than nil-returning: a profile carrying a level
-- from a future build, or a corrupted one, must still be able to garden.
--==============================================================================
function GameConfig.plotCapacityForTier(tier: number?): number
	local n = tonumber(tier)
	if n == nil or n ~= n then
		n = GameConfig.StartingPlotTier
	end
	local level = math.clamp(math.floor(n), 1, #GameConfig.PlotTiers)
	return GameConfig.PlotTiers[level].capacity
end

function GameConfig.plotRowsForTier(tier: number?): number
	local n = tonumber(tier)
	if n == nil or n ~= n then
		n = GameConfig.StartingPlotTier
	end
	local level = math.clamp(math.floor(n), 1, #GameConfig.PlotTiers)
	return GameConfig.PlotTiers[level].rows
end

--==============================================================================
-- THE LOWEST LEVEL THAT WOULD HOLD THIS MANY PLANTS
--
-- Used by the migration, which must never decide a saved garden does not fit.
-- Answers the TOP level when nothing fits, because the alternative -- refusing,
-- or silently choosing a level too small -- is how saved plants get discarded.
--==============================================================================
function GameConfig.plotLevelForPlants(count: number?): number
	local n = math.max(math.floor(tonumber(count) or 0), 0)
	for level, tier in ipairs(GameConfig.PlotTiers) do
		if n <= tier.capacity then
			return level
		end
	end
	return #GameConfig.PlotTiers
end

--==============================================================================
-- DERIVED
--
-- Computed rather than typed, so the two halves of the field can never disagree
-- with the whole. Set before the freeze, because after it they cannot be.
--==============================================================================
GameConfig.Map.FieldDepth = GameConfig.Map.FieldFront + GameConfig.Map.FieldBack
-- The field is not centred on the origin any more, so anything placing the slab
-- itself needs this. The ROAD side stays at -FieldFront regardless.
GameConfig.Map.FieldCenterZ = (GameConfig.Map.FieldBack - GameConfig.Map.FieldFront) * 0.5

-- The deepest tier's back edge. MapService checks the field actually contains
-- it -- a reservation nobody verified is not a reservation.
do
	local deepest = 0
	for _, tier in ipairs(GameConfig.PlotTiers) do
		deepest = math.max(deepest, GameConfig.plotDepthFor(tier.rows))
	end
	GameConfig.Plot.MaxDepth = deepest
	-- How far from the hub the deepest tier reaches. The ring equivalent of the
	-- old MaxBackZ, and what the field has to contain.
	GameConfig.Plot.MaxReach = GameConfig.Map.PlotRingInner + deepest
end

local function deepFreeze(target: { [any]: any }): { [any]: any }
	for _, value in pairs(target) do
		if type(value) == "table" then
			deepFreeze(value)
		end
	end
	return table.freeze(target)
end

return deepFreeze(GameConfig)
