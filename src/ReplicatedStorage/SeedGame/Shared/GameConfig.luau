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
GameConfig.PlotTiers = {
	{ rows = 4, cost = 0 },
	{ rows = 6, cost = 25000 },
	{ rows = 8, cost = 250000 },
	{ rows = 10, cost = 2000000 },
}

-- What a plot is built at before anything is bought.
GameConfig.StartingPlotTier = 1

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
	-- PARKED ON YOUR OWN MILL
	--
	-- Set by TreadmillService when it catches a player crossing their belt, read
	-- by CarryService to hold them at a standstill. On the PLAYER rather than the
	-- character so it survives nothing in particular -- a respawn clears the mount
	-- anyway -- but so that every client can see who is training without a remote.
	--==========================================================================
	MillMounted = "MillMounted",
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
	-- An empty marker MapService leaves behind saying "a nest belongs here".
	-- NestService builds the actual nest on top of it, because a nest has state
	-- and the map deliberately has none.
	NestSite = "NestSite",
}

GameConfig.Remotes = {
	PlotAssigned = "PlotAssigned",
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
-- That number can never reach WalkSpeed. So it does not: it feeds a curve that
-- asymptotes, the player watches an unbounded number climb, and the simulation
-- never sees past MaxWalkSpeed.
--
--     WalkSpeed = Base + (Max - Base) * (1 - e^(-Speed / Scale))
--
-- Scale is what decides where the curve bends, and it is the one number to tune
-- when the game feels slow early or flat late.
--==============================================================================
GameConfig.Speed = {
	BaseWalkSpeed = 16,
	MaxWalkSpeed = 150,
	Scale = 20000,
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
	BaseWalkSpeed = 26,
	WalkSpeedPerBiome = 12,

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
	-- Gives up past this from its nest, so a parent can never be kited into the
	-- safe field.
	LeashStuds = 220,
	-- Close enough to grab.
	GrabStuds = 7,
	-- Seconds it holds you before the throw. Long enough to read what happened.
}

function GameConfig.parentWalkSpeedFor(biomeOrder: number): number
	local P = GameConfig.Parent
	local order = math.max(1, math.floor(tonumber(biomeOrder) or 1))
	return P.BaseWalkSpeed + P.WalkSpeedPerBiome * (order - 1)
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
	-- floor. What a given mill actually pays is GameConfig.Mill.Tiers[n].Speed.
	SpeedPerSecond = 2,
	-- Only pays while you are actually standing on it, alive.
	TickSeconds = 1,
}

--==============================================================================
-- THE MILL, IN SEVEN STEPS
--
-- One per plot, and yours only. The ladder exists because the base rate above
-- is deliberately a FLOOR -- the comment on it says the pacing was always meant
-- to come from upgrades multiplying a slow number rather than from a fast one
-- being clawed back.
--
-- WHAT THE RATES ARE MEASURED AGAINST. The speed needed to out-run each biome's
-- parent is 453 / 2,208 / 4,133 / 6,260 / 8,636. At tier 1 the whole ladder is
-- about 72 minutes of standing still; at tier 7 it is about three. Twenty-five
-- times faster at the top, and a quarter of a billion in cash to get there --
-- which is the point: the mill is what you spend a mature garden's income on.
--
-- COSTS CLIMB FASTER THAN RATES. Each step is roughly seven times the last
-- while the rate is under two, so no tier is ever an obvious skip and the last
-- one is a genuine goal rather than a formality.
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
	Tiers = {
		{ name = "Compost Walk", speed = 2, cost = 0, beltStuds = 13 },
		{ name = "Garden Path", speed = 4, cost = 10000, beltStuds = 15 },
		{ name = "Trellis Trot", speed = 7, cost = 75000, beltStuds = 17 },
		{ name = "Millstone", speed = 12, cost = 500000, beltStuds = 19 },
		{ name = "Glasshouse", speed = 20, cost = 3500000, beltStuds = 21 },
		{ name = "Sunwheel", speed = 32, cost = 25000000, beltStuds = 24 },
		{ name = "Heartroot", speed = 50, cost = 150000000, beltStuds = 27 },
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
}


function GameConfig.parentThrowStudsFor(biomeOrder: number): number
	local P = GameConfig.Parent
	local order = math.max(1, math.floor(tonumber(biomeOrder) or 1))
	return P.BaseThrowStuds + P.ThrowPerBiome * (order - 1)
end

GameConfig.Carry = {
	-- The heaviest thing in the game. Biome 1 tops out at ~110.
	MaxKg = 10000,
	-- Speed multiplier when carrying MaxKg.
	MinMultiplier = 0.30,
	-- Below 1 flattens the low end. 0.6 keeps small pods nearly free.
	Exponent = 0.6,
	CashPerKg = 1,

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
function GameConfig.carryMultiplierFor(kg: number): number
	local C = GameConfig.Carry
	if type(kg) ~= "number" or kg ~= kg or kg <= 0 then
		return 1
	end
	local t = math.clamp(kg / C.MaxKg, 0, 1) ^ C.Exponent
	return 1 - (1 - C.MinMultiplier) * t
end

function GameConfig.walkSpeedFor(speedScore: number): number
	local S = GameConfig.Speed
	if type(speedScore) ~= "number" or speedScore ~= speedScore or speedScore <= 0 then
		return S.BaseWalkSpeed
	end
	return S.BaseWalkSpeed
		+ (S.MaxWalkSpeed - S.BaseWalkSpeed) * (1 - math.exp(-speedScore / S.Scale))
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
-- ONE COMPACTOR, NOT THREE
--
-- Three places want to shorten a number -- the rate on a grown plant, the `+$N`
-- that pops off it, and the Index row -- and three hand-rolled versions is how
-- the same plant ends up reading $1.5K in one place and $2K in another. It sits
-- here because here is the module all three already require.
--
-- Not balance, so Rule 7 is intact: this decides how a number is SPELLED, never
-- what it is.
--
--     110      ->  110          1500  ->  1.5K       39000  ->  39K
--     2000     ->  2K         100000  ->  100K     553000000 -> 553M
--
-- One decimal below ten, none above it, and a trailing .0 is dropped -- so 2000
-- is "2K" rather than "2.0K". Straight off the reference clip, which shows
-- $3.5K and $39K side by side.
--==============================================================================
local COMPACT_UNITS = {
	{ 1e12, "T" },
	{ 1e9, "B" },
	{ 1e6, "M" },
	{ 1e3, "K" },
}

function GameConfig.compact(n: number): string
	if type(n) ~= "number" or n ~= n then
		return "0"
	end
	local sign = if n < 0 then "-" else ""
	local v = math.abs(n)
	for _, unit in ipairs(COMPACT_UNITS) do
		local divisor = unit[1] :: number
		local suffix = unit[2] :: string
		if v >= divisor then
			local scaled = v / divisor
			local text = if scaled < 10
				then string.format("%.1f", scaled)
				else string.format("%d", math.floor(scaled))
			-- Parenthesised: gsub returns the count as a second value, and
			-- returning it would make this function two-valued.
			return sign .. (string.gsub(text, "%.0$", "")) .. suffix
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
	CurrentVersion = 1,
	AutosaveSeconds = 90,
	MinWriteGap = 7,
	RetryAttempts = 4,

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
	SessionLockSeconds = 45,
	LoadAttempts = 5,
	LoadRetryGap = 3,
}

-- How deep a plot with this many bed rows has to be. One expression, read by
-- the tier table, the map builder and the field-size check alike.
function GameConfig.plotDepthFor(rows: number): number
	local P = GameConfig.Plot
	return P.BedMargin * 2 + rows * P.RowDepth + (rows - 1) * P.RowGap
end

function GameConfig.plotSlotsFor(rows: number): number
	return rows * GameConfig.Plot.BedColumns
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
