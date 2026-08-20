--!strict
-- Steal a Seed :: BiomeData
--
-- The five lanes: what they look like, what they cost in Speed to enter, and
-- how good the seeds at the far end are.
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
	-- How many seed pods stand in the Wild Patch at the end.
	Pods: number,
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
-- SpeedGate values are placeholders and are KNOWN to be wrong. The reference
-- game's leaderboard runs to 3.2 billion Speed, so the real ladder is several
-- orders of magnitude above anything here. They are spaced correctly relative
-- to each other, which is what the map needs today; the absolute numbers get
-- set when the treadmill exists and there is a measured rate to scale against.
--==============================================================================
BiomeData.Biomes = {
	{
		Id = "forest",
		DisplayName = "Forest",
		Mood = "🙂",
		Order = 1,
		SpeedGate = 0,
		GroundColor = Color3.fromRGB(104, 190, 88),
		WallColor = Color3.fromRGB(126, 92, 62),
		AccentColor = Color3.fromRGB(74, 148, 66),
		Brightness = 1.0,
		Pods = 8,
		RarityBonus = 1.0,
		LiveInPhaseA = true,
	},
	{
		Id = "desert",
		DisplayName = "Desert",
		Mood = "😐",
		Order = 2,
		SpeedGate = 2500,
		GroundColor = Color3.fromRGB(232, 206, 142),
		WallColor = Color3.fromRGB(198, 156, 104),
		AccentColor = Color3.fromRGB(214, 170, 96),
		Brightness = 1.0,
		Pods = 7,
		RarityBonus = 1.6,
		LiveInPhaseA = false,
	},
	{
		Id = "jungle",
		DisplayName = "Jungle",
		Mood = "😟",
		Order = 3,
		SpeedGate = 12000,
		GroundColor = Color3.fromRGB(58, 138, 78),
		WallColor = Color3.fromRGB(48, 92, 58),
		AccentColor = Color3.fromRGB(196, 214, 74),
		Brightness = 0.78,
		Pods = 6,
		RarityBonus = 2.6,
		LiveInPhaseA = false,
	},
	{
		Id = "volcano",
		DisplayName = "Volcano",
		Mood = "😨",
		Order = 4,
		SpeedGate = 45000,
		GroundColor = Color3.fromRGB(72, 58, 58),
		WallColor = Color3.fromRGB(52, 40, 40),
		AccentColor = Color3.fromRGB(255, 112, 48),
		Brightness = 0.55,
		Pods = 5,
		RarityBonus = 4.5,
		LiveInPhaseA = false,
	},
	{
		Id = "cosmic",
		DisplayName = "Cosmic",
		Mood = "💀",
		Order = 5,
		SpeedGate = 150000,
		GroundColor = Color3.fromRGB(26, 26, 52),
		WallColor = Color3.fromRGB(18, 18, 38),
		AccentColor = Color3.fromRGB(150, 122, 255),
		Brightness = 0.3,
		Pods = 4,
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
	local mouth = -MAP.FieldDepth * 0.5
	local nearZ = mouth - (biome.Order - 1) * MAP.SegmentLength
	return nearZ, nearZ - MAP.SegmentLength
end

-- How far a biome's far edge is from the safe line. This is the number that
-- makes a Cosmic seed frightening to carry, and it is worth being able to read
-- directly rather than deriving it at three call sites.
function BiomeData.DistanceFromSafety(biome: Biome): number
	local _, farZ = BiomeData.SegmentBounds(biome)
	return math.abs(farZ) - GameConfig.Map.FieldDepth * 0.5
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
function BiomeData.PodCFrames(biome: Biome): { CFrame }
	local out: { CFrame } = {}
	local count = biome.Pods
	if count <= 0 then
		return out
	end

	local MAP = GameConfig.Map
	local nearZ = select(1, BiomeData.SegmentBounds(biome))
	local x = MAP.CorridorWidth * 0.5 - MAP.PodInset

	for index = 1, count do
		-- Spread down the segment with a half step of padding at each end, so
		-- no pod sits flush against a biome boundary.
		local t = (index - 0.5) / count
		local z = nearZ - t * MAP.SegmentLength
		local side = (index % 2 == 0) and 1 or -1
		out[index] = CFrame.new(side * x, GameConfig.Map.GroundY, z)
			-- Facing the middle of the road, so the pod presents its front to
			-- somebody running past rather than its back.
			* CFrame.Angles(0, side > 0 and math.pi * 0.5 or -math.pi * 0.5, 0)
	end
	return out
end

return BiomeData
