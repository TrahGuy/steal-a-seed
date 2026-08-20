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
	-- TIGHT ON PURPOSE. The first build put the plots 246 studs from the road,
	-- which meant every single run began and ended with a long walk across empty
	-- grass. That is dead time, it is the first thing a new player experiences,
	-- and none of it is the game.
	--
	-- The field only has to be big enough to hold the plots, the shops and a
	-- readable gap before the red line. Everything past that is distance the
	-- BIOMES are supposed to provide -- and they do, at 300 studs a segment.
	FieldWidth = 400,   -- X
	FieldDepth = 170,   -- Z
	FieldThickness = 6,

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
	Size = 48,
	-- Distance from the field's near edge to the plot centres. Larger moves the
	-- plots TOWARD the road.
	InsetFromEdge = 40,
	Pitch = 58,

	FloorName = "Ground",
	SignName = "OwnerSign",
	SignLabelName = "OwnerLabel",
	PlanterName = "Planter",
	TreadmillName = "Treadmill",
	SpawnPadName = "SpawnPad",
	RuntimeFolderName = "Runtime",
	PlantsFolderName = "Plants",
	UnclaimedText = "UNCLAIMED",

	SpawnHeightOffset = 4,
	-- Phase D grows this. Built now so a plant has somewhere to stand the day
	-- PlantService exists, rather than being a map change later.
	StartingPlantSlots = 6,
}

GameConfig.Attributes = {
	PlotId = "PlotId",
	OwnerUserId = "OwnerUserId",
	Claimed = "Claimed",
	BiomeId = "BiomeId",
	-- Phase A+
	CarryingSeed = "CarryingSeed",
	SeedInstanceId = "SeedInstanceId",
	InSafeZone = "InSafeZone",
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
}

GameConfig.Remotes = {
	PlotAssigned = "PlotAssigned",
	ProfileUpdated = "ProfileUpdated",
	CarryStateChanged = "CarryStateChanged",
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

GameConfig.RarityColor = {
	Common    = Color3.fromRGB(196, 200, 206),
	Uncommon  = Color3.fromRGB(118, 206, 106),
	Rare      = Color3.fromRGB(92, 146, 232),
	Epic      = Color3.fromRGB(158, 116, 226),
	Legendary = Color3.fromRGB(255, 176, 62),
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

function GameConfig.walkSpeedFor(speedScore: number): number
	local S = GameConfig.Speed
	if type(speedScore) ~= "number" or speedScore ~= speedScore or speedScore <= 0 then
		return S.BaseWalkSpeed
	end
	return S.BaseWalkSpeed
		+ (S.MaxWalkSpeed - S.BaseWalkSpeed) * (1 - math.exp(-speedScore / S.Scale))
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
}

local function deepFreeze(target: { [any]: any }): { [any]: any }
	for _, value in pairs(target) do
		if type(value) == "table" then
			deepFreeze(value)
		end
	end
	return table.freeze(target)
end

return deepFreeze(GameConfig)
