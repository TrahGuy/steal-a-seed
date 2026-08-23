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
	-- How far through its growth a pod becomes a sprout. Early on purpose: a
	-- plot that still looks like bare pods reads as empty from a distance, and
	-- the sprout is what says "something is happening here".
	SproutAt = 0.35,
	TickSeconds = 1,
	-- How close you must stand to plant. Generous -- a convenience, not a skill
	-- check, and fighting the camera to hit a slot is nobody's idea of a game.
	RangeStuds = 26,
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
	SpeedPerSecond = 2,
	-- Only pays while you are actually standing on it, alive.
	TickSeconds = 1,
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
-- THE HUD RAIL IS ARTWORK NOW, NOT A DRAWN PLATE
--
-- Cropped from the owner's `shop index.png` and uploaded. The gold studded plate
-- that used to live here is gone: it was a code drawing of a look, and this is
-- the look itself.
--
--     rail-shop.png    123 x 49   green slab, cart and "Shop" baked in
--     rail-index.png   123 x 48   blue slab, book and "Index" baked in
--     rail-slab.png     49 x 49   the same skin, blank, hue-rotated to amber
--
-- The sources are committed under `art/` so the crops can be redone. The Index
-- crop needed repair -- the reference has a red "9" badge baked over its
-- top-right corner and the count is dynamic, so that region was rebuilt by
-- mirroring the slab VERTICALLY. It is symmetric top-to-bottom: matching
-- borders, a cross-hatch lattice, a centred label, and the only glyph inside the
-- damage is the final `x` of "Index", which is itself symmetric.
--
-- The Garden button has no reference of its own, so it borrows the family's
-- skin: strictly clean columns of the Shop slab -- no cart, no letters, checked
-- by luminance rather than by eye -- mirror-tiled so the diagonal lattice has no
-- seam, then hue-rotated so three buttons read as three things and not two.
--
-- SIZES ARE NATIVE AND DISPLAYED 1:1. The source screenshot is 170 x 152, so
-- there is no resolution to spare; scaling these up would only blur them.
--==============================================================================
GameConfig.Rail = {
	ShopImage = "rbxassetid://98659233032073",
	ShopSize = Vector2.new(123, 49),
	IndexImage = "rbxassetid://125233705163038",
	IndexSize = Vector2.new(123, 48),
	SlabImage = "rbxassetid://130383639526295",
	SlabSize = Vector2.new(49, 49),

	-- Left rail: Index at the top, Shop under it, panels below both.
	Inset = 12,
	Gap = 6,
	PanelTop = 126,
}

--==============================================================================
-- THE SHOP'S PALETTE, SAMPLED OFF THE OWNER'S THREE REFERENCE SHOTS
--
-- `shop ui 1.png`, `shop ui 2.png`, `shop ui 3.png` in the repo root. Every
-- value here came out of those files with a pixel sampler rather than off a
-- first impression -- the same discipline the corner HUD needed, and for the
-- same reason.
--
--     panel        rgb( 26, 28, 41)   very dark navy, black outline
--     panel edge   rgb( 48, 50, 61)   the lighter inner lip
--     card cyan    rgb(  0,247,237) -> rgb(  0,116,229)   vertical gradient
--     card green   rgb(  4,229, 17) -> rgb( 19,126,  1)
--     buy button   rgb( 31,246,  0)   flat, with rgb(22,143,0) under it
--     close        rgb(255,  0,  0)   white X, black outline
--
-- The panel texture in the reference is a faint diagonal lattice with only ~5
-- units of luminance spread -- barely there. Ours is STUDDED instead, because
-- this game is blocky studded plastic (Rule 8) and a studded panel is the same
-- idea said in our own accent. Kept at the reference's contrast: any louder and
-- it competes with the cards it is behind.
--
-- These are NOT ink / paper / accent, exactly like the corner HUD is not. A shop
-- panel is a full-screen-ish surface with its own internal contrast to manage.
--==============================================================================
GameConfig.Shop = {
	Panel = Color3.fromRGB(26, 28, 41),
	PanelEdge = Color3.fromRGB(48, 50, 61),
	Outline = Color3.fromRGB(0, 0, 0),
	Stud = Color3.fromRGB(72, 78, 104),
	CardTop = Color3.fromRGB(0, 247, 237),
	CardBottom = Color3.fromRGB(0, 116, 229),
	CardBorder = Color3.fromRGB(0, 116, 229),
	SoldTop = Color3.fromRGB(4, 229, 17),
	SoldBottom = Color3.fromRGB(19, 126, 1),
	Buy = Color3.fromRGB(31, 246, 0),
	BuyShade = Color3.fromRGB(22, 143, 0),
	Close = Color3.fromRGB(255, 0, 0),
	Title = Color3.fromRGB(255, 255, 255),
	-- The section headings in the reference are each a different colour: yellow
	-- for PASSES, cyan for SPEED. One per section, so a long shop reads as a
	-- list of shelves rather than one wall.
	Heading = Color3.fromRGB(0, 232, 237),
	Locked = Color3.fromRGB(120, 124, 140),
	-- The panel's studs stay far quieter than the rail's: there are cards
	-- sitting on this and texture must never compete with them. No rim here --
	-- a dark ring on an already-dark panel adds nothing but instances. Lifted
	-- from rgb(52,56,76) at 0.82, which measured a luminance delta of 5 and was
	-- as invisible as the rail's first attempt.
	StudTransparency = 0.7,
	-- Studs every this many pixels. 38 keeps a full-height panel near 150 of
	-- them, which is built once and never touched again -- the alternative was
	-- an image asset, and nothing in this repo is placed by hand.
	StudPitch = 38,
	StudSize = 11,
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
