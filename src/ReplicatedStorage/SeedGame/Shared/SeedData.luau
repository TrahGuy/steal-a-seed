--!strict
-- Steal a Seed :: SeedData
--
-- Every species: the pod you steal, and the creature it grows into. Balance
-- lives here and nowhere else (Rule 7) -- GameConfig holds structure and the
-- curves, never what a thing is worth.
--
-- BIOME 1 ONLY. Greenhollow is designed from the reference sheets in
-- KB/biome1-plants.png and KB/biome1-pods.png. The other four biomes get the
-- same treatment one at a time, from their own artwork.
--
-- An earlier pass invented eleven species across all five biomes with no art
-- and it was discarded. Filling four biomes from imagination is how a game ends
-- up with forty things nobody designed.
--
--==============================================================================
-- WEIGHT IS THE STAT. RARITY IS ONLY THE DROP RATE.
--
-- Kilograms decide what a creature EARNS and what it COSTS to carry home.
-- Rarity decides only how often you find one. That is the whole risk/reward of
-- a theft game in a single number:
--
--     the fat pod is the one worth taking, and the one that gets you caught.
--
-- ONE KILOGRAM IS ONE CASH PER SECOND. A player reads an object's worth
-- straight off its weight and can compare any two things in the game without
-- opening a menu.
--
--==============================================================================
-- FIVE SPECIES, FOUR RARITIES, ON PURPOSE
--
-- Greenhollow runs Common to Epic, so two of its five share a tier. Since the
-- POD is coloured by rarity, those two arrive in identical pods -- and that is a
-- feature rather than a collision. The pod tells you how excited to be while
-- you are running; WHICH of the two you got stays hidden until it grows. A free
-- reveal at the end of every run home, costing no extra art and no extra code.
--==============================================================================

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local SeedData = {}

--==============================================================================
-- HOW OFTEN, BY RARITY
--
-- Relative weights within a biome's pool, not percentages, so adding a species
-- to a biome does not mean rebalancing every other number in it.
--==============================================================================
SeedData.RarityWeight = {
	Common = 1000,
	Uncommon = 260,
	Rare = 55,
	Epic = 9,
	Legendary = 1.4,
	Mythic = 0.22,
	Secret = 0.03,
	Divine = 0.004,
}

--==============================================================================
-- THE SPECIES -- GREENHOLLOW
--
-- Straight off the reference sheet, left to right. Each is described by its
-- FORM rather than by a pile of measurements: the form is what the builder
-- switches on and what a player recognises at distance.
--
-- They share a stem, leaf and soil colour deliberately. It is one biome, and
-- that family resemblance is what makes the fifth one read as a Greenhollow
-- creature rather than as a stray from somewhere else.
--==============================================================================
export type Species = {
	Id: string,
	Name: string,
	Rarity: string,
	Biome: string,
	-- Earns this many cash per second, and slows you by this much to carry.
	Kg: number,
	-- The FRAME height in studs -- the mound-stem-head column the form is built
	-- around, not the finished silhouette. Girth widens the head, and a wider
	-- head is also a taller one, so a heavy species finishes above this number
	-- and a light one below it:
	--
	--     Nubkin     Height 2.4  ->  1.74 studs finished
	--     Bellchime  Height 4.0  ->  6.41 studs finished
	--
	-- DECIDED, do not re-open: this stays a frame height. Pinning the finished
	-- silhouette to it exactly would mean decoupling every form's vertical
	-- extent from its width, and that collapses the width spread back to 1.78x
	-- -- which is the problem the girth curve exists to fix.
	--
	-- Visible weight at a glance beats 2.4 finishing at 2.4. Weight is allowed
	-- to make a thing bigger in both directions.
	Height: number,
	-- "cube" | "orb" | "teardrop" | "mushroom" | "bell"
	Form: string,
	Body: Color3,
	-- Cap, petals or buds, depending on the form.
	Crown: Color3,
	-- The small contrasting detail: flower centre, cap spots, bud tips.
	Accent: Color3,
	Leaf: Color3,
	Soil: Color3,
}

local LEAF = Color3.fromRGB(86, 150, 66)
local STEM = Color3.fromRGB(124, 182, 92)
local SOIL = Color3.fromRGB(74, 54, 44)
local GREEN = Color3.fromRGB(146, 196, 106)
local CREAM = Color3.fromRGB(242, 238, 206)

SeedData.Stem = STEM

SeedData.Species = {
	{
		Id = "nubkin", Name = "Nubkin", Rarity = "Common", Biome = "greenhollow",
		Kg = 2, Height = 2.4, Form = "cube",
		Body = GREEN, Crown = GREEN, Accent = CREAM, Leaf = LEAF, Soil = SOIL,
	},
	{
		Id = "petalpip", Name = "Petalpip", Rarity = "Common", Biome = "greenhollow",
		Kg = 5, Height = 3.0, Form = "orb",
		Body = GREEN, Crown = CREAM,
		Accent = Color3.fromRGB(226, 138, 116), Leaf = LEAF, Soil = SOIL,
	},
	{
		Id = "spiretip", Name = "Spiretip", Rarity = "Uncommon", Biome = "greenhollow",
		Kg = 14, Height = 3.2, Form = "teardrop",
		Body = Color3.fromRGB(132, 186, 96),
		Crown = Color3.fromRGB(168, 208, 122), Accent = CREAM, Leaf = LEAF, Soil = SOIL,
	},
	{
		Id = "toadcap", Name = "Toadcap", Rarity = "Rare", Biome = "greenhollow",
		Kg = 40, Height = 3.6, Form = "mushroom",
		Body = CREAM,
		Crown = Color3.fromRGB(216, 112, 100), Accent = CREAM, Leaf = LEAF, Soil = SOIL,
	},
	{
		Id = "bellchime", Name = "Bellchime", Rarity = "Epic", Biome = "greenhollow",
		Kg = 110, Height = 4.0, Form = "bell",
		Body = CREAM,
		Crown = Color3.fromRGB(234, 158, 158), Accent = LEAF, Leaf = LEAF, Soil = SOIL,
	},
} :: { Species }

--==============================================================================
-- LOOKUPS, AND THE CHECKS THAT RUN AT REQUIRE
--==============================================================================
local byId: { [string]: Species } = {}
local byBiome: { [string]: { Species } } = {}

for _, species in ipairs(SeedData.Species) do
	assert(byId[species.Id] == nil, "duplicate species id: " .. species.Id)
	assert(GameConfig.RarityTier[species.Rarity] ~= nil,
		string.format("species %q has unknown rarity %q", species.Id, species.Rarity))
	assert(SeedData.RarityWeight[species.Rarity] ~= nil,
		string.format("rarity %q has no drop weight", species.Rarity))
	assert(species.Kg > 0 and species.Kg <= GameConfig.Carry.MaxKg,
		string.format("species %q weighs %g, outside 0..%d",
			species.Id, species.Kg, GameConfig.Carry.MaxKg))
	byId[species.Id] = species
	local list = byBiome[species.Biome]
	if not list then
		list = {}
		byBiome[species.Biome] = list
	end
	table.insert(list, species)
end

SeedData.ById = byId
SeedData.ByBiome = byBiome

function SeedData.Get(id: string): Species?
	return byId[id]
end

function SeedData.InBiome(biomeId: string): { Species }
	return byBiome[biomeId] or {}
end

--==============================================================================
-- WHAT IT IS WORTH, AND WHAT IT COSTS
--==============================================================================
function SeedData.IncomePerSecond(species: Species): number
	return species.Kg * GameConfig.Carry.CashPerKg
end

function SeedData.CarryMultiplier(species: Species): number
	return GameConfig.carryMultiplierFor(species.Kg)
end

--==============================================================================
-- GROWING
--
-- Also from weight, because weight is the stat. A gentle curve on purpose: the
-- heaviest thing in the game takes five minutes, not an afternoon. The wait is
-- a vulnerability window -- somebody can see what is nearly ready in your plot
-- -- and a window nobody is awake for is not a window.
--==============================================================================
local GROW_BASE = 20
local GROW_SPAN = 280
local GROW_EXP = 0.45

function SeedData.GrowSeconds(species: Species): number
	local t = math.clamp(species.Kg / GameConfig.Carry.MaxKg, 0, 1) ^ GROW_EXP
	return GROW_BASE + GROW_SPAN * t
end

--==============================================================================
-- THE POD TAKES ITS RARITY COLOUR
--
-- While it is in your hands the only question anybody has -- you, and whoever is
-- behind you -- is how badly they want it. That is rarity. Which species it
-- turns out to be is a question for after you are safe.
--==============================================================================
--==============================================================================
-- A POD IS AS BIG AS IT IS HEAVY
--
-- Every pod used to be the same size, which threw away the one piece of
-- information the player most needs before committing to a hold: how much this
-- is going to cost to carry. Weight already decides the income and the slow;
-- making it decide the SILHOUETTE means a player reads the trade before
-- pressing anything, from across the nest, with no UI at all.
--
-- kg^0.28 rather than a straight ratio, because straight would make a 110 kg
-- Bellchime fifty-five times the size of a Nubkin. Clamped at both ends: below
-- 1.3 a pod is hard to see on studded grass, and above 4.5 it stops fitting in
-- a nest ring -- which matters once the 10,000 kg end of the range exists.
--
--     2 kg -> 1.45      14 kg -> 2.16      110 kg -> 3.72
--     5 kg -> 1.72      40 kg -> 2.85   10,000 kg -> clamped to 4.5
--==============================================================================
function SeedData.PodDiameter(species: Species): number
	return math.clamp(1.2 * (species.Kg ^ 0.28), 1.3, 4.5)
end

--==============================================================================
-- A GROWN CREATURE IS AS FAT AS IT IS HEAVY
--
-- Height already came from Height. Everything HORIZONTAL was a fixed fraction
-- of that height, which meant bulk tracked height and nothing tracked weight --
-- so across a 55x weight range the five species differed by 2.21x in height and
-- 1.67x in width, and a Bellchime came out proportionally SLIMMER than a Nubkin
-- (1.73 tall-to-wide against 1.30). Weight read backwards.
--
-- Same curve family as PodDiameter, for the same reason: a straight ratio would
-- make the Bellchime fifty-five times the Nubkin. Referenced against 14 kg --
-- the middle species -- so Spiretip is 1.00 and the curve spreads either side
-- of something that already looked right.
--
--     2 kg -> 0.70 (clamped)    14 kg -> 1.00     110 kg -> 1.64
--     5 kg -> 0.78              40 kg -> 1.29
--
-- Clamped at both ends because this multiplies a width that is already small:
-- below 0.70 a Nubkin's stem stops being visible against studded soil, and the
-- ceiling keeps the 10,000 kg end of the range from growing wider than its slot.
--==============================================================================
local GIRTH_REF_KG = 14
local GIRTH_EXP = 0.24

function SeedData.Girth(species: Species): number
	return math.clamp((species.Kg / GIRTH_REF_KG) ^ GIRTH_EXP, 0.70, 1.75)
end

-- How far in front of the root this species rides. ONE definition: CarryService
-- welds with it, CarryPose aims the arms with it.
function SeedData.GripForward(species: Species): number
	return GameConfig.Carry.GripForwardBase + SeedData.PodDiameter(species) * 0.5
end

function SeedData.PodColor(species: Species): Color3
	return GameConfig.RarityColor[species.Rarity] or Color3.fromRGB(200, 200, 200)
end

--==============================================================================
-- WEIGHTED ROLL
--
-- By RARITY weight, within the biome. Rarity is the only thing deciding how
-- often something turns up; weight decides what it is worth. The two are
-- deliberately independent, so a heavy Common stays findable and a light Epic
-- stays rare.
--==============================================================================
function SeedData.Roll(biomeId: string, rng: Random): Species?
	local pool = byBiome[biomeId]
	if not pool or #pool == 0 then
		return nil
	end
	local total = 0
	for _, species in ipairs(pool) do
		total += SeedData.RarityWeight[species.Rarity]
	end
	local pick = rng:NextNumber() * total
	for _, species in ipairs(pool) do
		pick -= SeedData.RarityWeight[species.Rarity]
		if pick <= 0 then
			return species
		end
	end
	return pool[#pool]
end

return SeedData
