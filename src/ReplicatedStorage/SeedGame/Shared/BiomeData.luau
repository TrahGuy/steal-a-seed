--!strict
-- Steal a Seed :: BiomeData
--
-- The five segments of the road: what they look like, what they cost in Speed
-- to enter, and how good the seeds are.
--
--==============================================================================
-- THE NAMES ARE OURS
--
-- Forest / Desert / Jungle / Volcano / Cosmic is the generic simulator ladder
-- and every game in the genre uses it. These are the same ladder read as a
-- garden going progressively wrong, which is the game actually being made here:
--
--   Greenhollow -> Dustbowl -> Tanglemire -> Emberroot -> Starbloom
--
-- A player should be able to guess the difficulty order from the words alone,
-- and should not be able to confuse this game's map with anybody else's.
--
--==============================================================================
-- ONE WORD AND A FACE
--
-- The reference game labels a biome entrance with a single yellow word and an
-- emoji -- "Snow 😟" -- and nothing else. No stat block, no rarity table, no
-- paragraph. A player sprinting past reads a word and a facial expression and
-- knows whether they are ready.
--
-- Copy that restraint. `DisplayName` and `Mood` are the whole sign. The
-- SpeedGate number appears only when you are actually blocked by it.
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local BiomeData = {}

export type Biome = {
	Id: string,
	DisplayName: string,
	-- The face on the sign. Difficulty, communicated the way the reference
	-- does it -- as a feeling rather than a number.
	Mood: string,
	-- Order along the field's far edge, left to right. Also progression order.
	Order: number,
	-- Speed score required to pass the gate. 0 is the starter lane.
	SpeedGate: number,
	GroundColor: Color3,
	WallColor: Color3,
	AccentColor: Color3,
	-- Ambient light level in the lane, 0..1. Cosmic is dark on purpose.
	Brightness: number,
	-- How many NESTS stand in this segment, and how many pods ring each one.
	--
	-- A nest is a sleeping parent with its pods around it, so these two replace
	-- the old flat pod count. Fewer, denser clusters is a better shape than pods
	-- dotted evenly down a wall: a cluster is a DECISION -- how many can I grab
	-- before it wakes -- where a lone pod is just a pickup.
	Nests: number,
	PodsPerNest: number,
	-- Weight multiplier on the Epic-and-above bands. 1.0 is the base table.
	RarityBonus: number,
	-- Phase A only builds Forest's pods live. The rest are geometry and a gate
	-- until Phase C, which is deliberate: the lanes have to EXIST from the
	-- start so the map reads correctly and the gates mean something, but
	-- content in four biomes nobody can reach yet is content built on spec.
	LiveInPhaseA: boolean,
}

--==============================================================================
-- THE FIVE
--
-- SpeedGate is the Speed SCORE needed to pass that biome's arch (and, when
-- raid checks land, to steal from its parent without an instant catch).
-- Same relative spacing as the old 0 / 2.5k / 12k / 45k / 150k ladder, scaled
-- so Starbloom is 10 billion — the reference leaderboard's order of magnitude,
-- not a few minutes of milling. Greenhollow stays ungated.
--==============================================================================
BiomeData.Biomes = {
	{
		Id = "greenhollow",
		DisplayName = "Greenhollow",
		Mood = "🙂",
		Order = 1,
		SpeedGate = 0,
		GroundColor = Color3.fromRGB(104, 190, 88),
		WallColor = Color3.fromRGB(126, 92, 62),
		AccentColor = Color3.fromRGB(74, 148, 66),
		Brightness = 1.0,
		Nests = 1,
		PodsPerNest = 5,
		RarityBonus = 1.0,
		LiveInPhaseA = true,
	},
	{
		Id = "dustbowl",
		DisplayName = "Dustbowl",
		Mood = "😐",
		Order = 2,
		SpeedGate = 167_000_000,
		GroundColor = Color3.fromRGB(226, 198, 138),
		WallColor = Color3.fromRGB(186, 142, 92),
		AccentColor = Color3.fromRGB(212, 158, 78),
		Brightness = 1.0,
		Nests = 1,
		PodsPerNest = 3,
		RarityBonus = 1.6,
		-- Biome 2 has its art now: five species in SeedData, the Dust Husk pod
		-- and Brambleback on the nest. Note this flag is NOT what turns a biome
		-- on -- NestService gates on whether SeedData has species for it, and
		-- MapService only copies this onto a Live attribute. It is a statement
		-- of record, so it should stop saying the opposite of the truth.
		LiveInPhaseA = true,
	},
	{
		Id = "tanglemire",
		DisplayName = "Tanglemire",
		Mood = "😟",
		Order = 3,
		SpeedGate = 800_000_000,
		GroundColor = Color3.fromRGB(58, 116, 96),
		WallColor = Color3.fromRGB(40, 74, 62),
		AccentColor = Color3.fromRGB(168, 214, 96),
		Brightness = 0.78,
		Nests = 1,
		PodsPerNest = 3,
		RarityBonus = 2.6,
		LiveInPhaseA = false,
	},
	{
		Id = "emberroot",
		DisplayName = "Emberroot",
		Mood = "😨",
		Order = 4,
		SpeedGate = 3_000_000_000,
		GroundColor = Color3.fromRGB(74, 54, 50),
		WallColor = Color3.fromRGB(50, 36, 34),
		AccentColor = Color3.fromRGB(255, 118, 44),
		Brightness = 0.55,
		Nests = 1,
		PodsPerNest = 3,
		RarityBonus = 4.5,
		LiveInPhaseA = false,
	},
	{
		Id = "starbloom",
		DisplayName = "Starbloom",
		Mood = "💀",
		Order = 5,
		SpeedGate = 10_000_000_000,
		GroundColor = Color3.fromRGB(30, 24, 60),
		WallColor = Color3.fromRGB(20, 16, 42),
		AccentColor = Color3.fromRGB(158, 128, 255),
		Brightness = 0.3,
		Nests = 1,
		PodsPerNest = 2,
		RarityBonus = 9.0,
		LiveInPhaseA = false,
	},
} :: { Biome }

local byId: { [string]: Biome } = {}
for _, biome in ipairs(BiomeData.Biomes) do
	byId[biome.Id] = biome
end
BiomeData.ById = byId

--==============================================================================
-- WHERE A SEGMENT STARTS AND ENDS
--
-- Biomes are laid end to end down one corridor running in -Z, starting at the
-- field's far edge. Order 1 is nearest home.
--
-- Returns (nearZ, farZ), nearZ always the end closer to safety. Derived rather
-- than listed per biome, so changing SegmentLength repaces the entire game and
-- nothing falls out of step.
--==============================================================================
function BiomeData.SegmentBounds(biome: Biome): (number, number)
	local MAP = GameConfig.Map
	-- The road starts at the field's FRONT edge, which is fixed. The field's
	-- back edge moves as plots grow and must never affect where a biome sits.
	local mouth = -MAP.FieldFront
	local nearZ = mouth - (biome.Order - 1) * MAP.SegmentLength
	return nearZ, nearZ - MAP.SegmentLength
end

-- How far a biome's far edge is from the safe line. This is the number that
-- makes a Cosmic seed frightening to carry, and it is worth being able to read
-- directly rather than deriving it at three call sites.
function BiomeData.DistanceFromSafety(biome: Biome): number
	local _, farZ = BiomeData.SegmentBounds(biome)
	return math.abs(farZ) - GameConfig.Map.FieldFront
end

--==============================================================================
-- WHERE THE PODS SIT
--
-- ALONG BOTH WALLS, ALTERNATING, NEVER IN THE MIDDLE. That is the one rule and
-- it is a gameplay rule rather than a decorative one: the centre of the road
-- stays clear as a running line, so stepping out to take a pod costs you it.
-- With somebody behind you that is a real decision, and it is free -- it is
-- just where the pods are.
--
-- Alternating sides also means a player working a whole segment has to cross
-- the road repeatedly, which keeps them exposed rather than hugging one wall.
--
-- DETERMINISTIC. Derived from the pod index, never from math.random, so every
-- server builds the identical segment and "the third pod on the left" means
-- something in a bug report.
--==============================================================================
--==============================================================================
-- ONE NEST, IN THE FAR CORNER
--
-- Nests used to be spread down the segment, and the first of them sat close
-- enough to the safe line to be raided almost from home. That made the whole
-- length of a biome optional: you could farm the near nest forever and never
-- walk the rest of it.
--
-- One nest, at the FAR corner, makes the segment mean something. To raid
-- Greenhollow you cross Greenhollow. The prize is at the end of the walk,
-- which is the only place a prize can be if the walk is the game.
--
-- Still hard against a wall, because the rule that outlived every layout is
-- unchanged: NOTHING in the racing line. Alternating sides by biome order so a
-- player running the whole road is not hugging one wall the entire way.
--==============================================================================
function BiomeData.NestCFrames(biome: Biome): { CFrame }
	local out: { CFrame } = {}
	if biome.Nests <= 0 then
		return out
	end

	local MAP = GameConfig.Map
	local _, farZ = BiomeData.SegmentBounds(biome)
	-- Clear of the boundary, so the nest belongs to this biome rather than
	-- straddling the gate into the next one.
	local FAR_MARGIN = 55
	local x = MAP.CorridorWidth * 0.5 - MAP.PodInset - 6
	local side = if biome.Order % 2 == 0 then 1 else -1

	for index = 1, biome.Nests do
		-- A second nest, if a biome ever wants one, steps back up the segment
		-- rather than sideways: the far corner is the point.
		local z = farZ + FAR_MARGIN + (index - 1) * 90
		out[index] = CFrame.new(side * x, GameConfig.Map.GroundY, z)
			-- Facing the middle of the road, so the parent looks out at traffic
			-- rather than at the wall behind it.
			* CFrame.Angles(0, side > 0 and math.pi * 0.5 or -math.pi * 0.5, 0)
	end
	return out
end

return BiomeData
