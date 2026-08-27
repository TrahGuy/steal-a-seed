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
-- WEIGHT IS ROLLED PER POD. SPECIES IS ONLY THE SHAPE.
--
-- Every pod that spawns rolls its own weight, 1 to 10,000 kg, on ONE curve
-- shared by all five species. A 10,000 kg Nubkin is legal. A 12 kg Bellchime is
-- legal. What the species decides is what the thing LOOKS like -- a cube, a
-- bell, a mushroom -- and nothing else.
--
-- That is the whole change from the old design, where each species carried a
-- fixed Kg and a Bellchime was worth 110 because it was a Bellchime. Now the
-- form tells you nothing about the prize, so every pod has to be looked at.
--
-- ONE KILOGRAM IS ONE CASH PER SECOND. A player reads an object's worth
-- straight off its weight and can compare any two things in the game without
-- opening a menu.
--
-- `species.Kg` survives on the sheet as ONE thing only: the fallback weight for
-- a plant saved before weights were rolled. It is not the live stat, and
-- anything that pays out or measures from it after this is a bug.
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
	-- NOT the live weight any more. Every pod rolls its own -- see RollKg -- and
	-- this is only what a plant saved before that rolled gets restored onto,
	-- once, on load. Anything that pays out or measures from it is a bug.
	Kg: number,
	-- The FRAME height in studs AT THE REFERENCE WEIGHT -- the stem-and-head
	-- column the form is built around, not the finished silhouette, and not an
	-- absolute size any more. SizeScale multiplies it by what the pod actually
	-- rolled, so this number says how tall this form stands relative to the
	-- others rather than how tall it stands:
	--
	--     Nubkin     Height 2.4  ->  1.4 studs finished at 2 kg, 14.1 at 10,000
	--     Bellchime  Height 4.0  ->  3.0 studs finished at 2 kg, 33.8 at 10,000
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
	-- Per-species like Leaf and Soil, and for the same reason: it holds a BIOME
	-- constant, not a species one. Greenhollow's five all carry 124,182,92 and
	-- Dustbowl's all carry 178,158,106, and that shared stem is a third of what
	-- makes a biome's plants look related. `SeedData.Stem` still exists and is
	-- still Greenhollow's -- three UI call sites draw a generic sprout icon with
	-- it and have no species to ask.
	Stem: Color3,
	Soil: Color3,
}

local LEAF = Color3.fromRGB(86, 150, 66)
local STEM = Color3.fromRGB(124, 182, 92)
--==============================================================================
-- THE DIRT A PLANT COMES WITH
--
-- 74, 54, 44 -- nearly black -- while it was one big cylinder nobody looked at
-- twice. Now it is a heap of small clods sitting on MapService's bed, which is
-- 158, 82, 52, and at that contrast they read as lumps of coal rather than as
-- soil. Pitched a shade darker and browner than the bed it sits on, so the heap
-- reads as the same dirt shovelled up rather than as a different material.
--==============================================================================
local SOIL = Color3.fromRGB(124, 76, 50)
--==============================================================================
-- FIVE BODIES, FIVE COLOURS
--
-- There used to be TWO. Nubkin and Petalpip were both `GREEN`, Toadcap and
-- Bellchime were both `CREAM`, and Spiretip was 132,186,96 -- fourteen points
-- off Nubkin, which is not a difference anybody can see across a plot. So a bed
-- of five species read as a bed of two, and GardenUI already carried a comment
-- saying exactly that: it had to swatch by CROWN because Body put "two
-- identical cream squares next to each other".
--
-- WHAT STAYS SHARED IS THE PART THAT MAKES IT A BIOME. Stem, leaf and soil are
-- identical on all five and must remain so -- that family resemblance is what
-- makes the fifth one read as a Greenhollow creature rather than a stray. The
-- HEAD is where a species is allowed to be itself.
--
-- Still all greens and creams, deliberately. Greenhollow is the first biome and
-- the four after it need somewhere to go; spending saturated colour here would
-- leave Emberroot and Starbloom nothing to be.
--
--     Nubkin     leaf green        the baseline, and the ordinary one
--     Petalpip   pale yellow-green sunlit, lighter than Nubkin
--     Spiretip   deep pine         the only dark one, and the only cool green
--     Toadcap    warm cream        buttery, under a red cap
--     Bellchime  cool porcelain    blue-white, so it is not Toadcap
--==============================================================================
--==============================================================================
-- BIOME 2: DUSTBOWL
--
-- Same rule as Greenhollow: the STEM, LEAF and SOIL are shared by every species
-- in the biome and must stay so -- that family resemblance is what makes the
-- fifth read as a Dustbowl creature rather than a stray. The HEAD is where a
-- species gets to be itself.
--
-- SOIL is deliberately the SAME 124,76,50 Greenhollow uses. The heap is the
-- player's own bed shovelled up, not biome ground, so it does not change when
-- the biome does.
--==============================================================================
local DUST_LEAF = Color3.fromRGB(128, 122, 78)
local DUST_STEM = Color3.fromRGB(178, 158, 106)

local GREEN = Color3.fromRGB(146, 196, 106)
local CREAM = Color3.fromRGB(242, 238, 206)

-- The cheeks. One shared colour rather than a per-species one: a face is the
-- thing all five have in common and it should read as one family of creature.
local BLUSH = Color3.fromRGB(238, 150, 138)

SeedData.Blush = BLUSH

--==============================================================================
-- THE THREE THAT ARE SHARED, EXPORTED
--
-- Stem, leaf and soil are identical on all five and must remain so -- that
-- family resemblance is what makes the fifth one read as a Greenhollow creature
-- rather than a stray. They are exported because the HUD draws plants too: the
-- Index portraits and the shop's plot art both need the biome's own greens, and
-- reaching them through `Species[1].Leaf` would work right up until somebody
-- reordered the sheet.
--==============================================================================
SeedData.Stem = STEM
SeedData.Leaf = LEAF
SeedData.Soil = SOIL

SeedData.Species = {
	{
		Id = "nubkin", Name = "Nubkin", Rarity = "Common", Biome = "greenhollow",
		Kg = 2, Height = 2.4, Form = "cube",
		-- Crown is the pair of sprout leaves on top of the cube; Accent is
		-- their pale tips. The cube used to have neither and was the only
		-- species with nothing on its head at all.
		Body = GREEN,
		Crown = Color3.fromRGB(176, 214, 128),
		Accent = CREAM, Leaf = LEAF, Stem = STEM, Soil = SOIL,
	},
	{
		Id = "petalpip", Name = "Petalpip", Rarity = "Common", Biome = "greenhollow",
		Kg = 5, Height = 3.0, Form = "orb",
		-- Lifted off Nubkin's green toward yellow. Same family, sunlit.
		Body = Color3.fromRGB(206, 224, 132),
		Crown = Color3.fromRGB(250, 246, 226),
		Accent = Color3.fromRGB(232, 132, 106), Leaf = LEAF, Stem = STEM, Soil = SOIL,
	},
	{
		Id = "spiretip", Name = "Spiretip", Rarity = "Uncommon", Biome = "greenhollow",
		Kg = 14, Height = 3.2, Form = "teardrop",
		-- The dark one. Fourteen points off Nubkin was invisible; this is a
		-- different green, cooler and deeper, and it is the only one in the
		-- biome that reads as shade rather than sunlight.
		Body = Color3.fromRGB(94, 152, 104),
		Crown = Color3.fromRGB(236, 242, 206),
		Accent = Color3.fromRGB(242, 246, 220), Leaf = LEAF, Stem = STEM, Soil = SOIL,
	},
	{
		Id = "toadcap", Name = "Toadcap", Rarity = "Rare", Biome = "greenhollow",
		Kg = 40, Height = 3.6, Form = "mushroom",
		-- Warm cream, against Bellchime's cool one. The red cap does most of
		-- the work at distance; this is what separates them close up.
		Body = Color3.fromRGB(240, 228, 198),
		Crown = Color3.fromRGB(216, 112, 100),
		Accent = Color3.fromRGB(250, 246, 226), Leaf = LEAF, Stem = STEM, Soil = SOIL,
	},
	{
		Id = "bellchime", Name = "Bellchime", Rarity = "Epic", Biome = "greenhollow",
		Kg = 110, Height = 4.0, Form = "bell",
		-- Cool porcelain. The rarest thing in the biome should not be the same
		-- colour as the fourth rarest.
		Body = Color3.fromRGB(214, 226, 242),
		-- The scalloped collar AND the bud tips. On the sheet both are the same
		-- pink; the stalks between them are the Accent green.
		Crown = Color3.fromRGB(240, 150, 168),
		Accent = LEAF, Leaf = LEAF, Stem = STEM, Soil = SOIL,
	},

	--==========================================================================
	-- DUSTBOWL -- biome 2
	--
	-- No Common. The biome carries RarityBonus 1.6 and sits behind a
	-- 167,000,000 speed gate, so its floor is Uncommon and its ceiling is
	-- Legendary -- one tier up from Greenhollow at both ends. `Roll` normalises
	-- over whatever pool a biome has, so a missing tier costs nothing.
	--
	-- Heights keep the same job they do in Greenhollow: a FRAME height at the
	-- reference weight, ordered so a Dunebud stays shorter than a Suncrown at
	-- EVERY weight. 2.6 .. 4.2 sits just above Greenhollow's 2.4 .. 4.0.
	--==========================================================================
	{
		Id = "dunebud", Name = "Dunebud", Rarity = "Uncommon", Biome = "dustbowl",
		Kg = 8, Height = 2.6, Form = "husk",
		-- A sealed bud with ONE plate peeled down at the front, so the face is
		-- recessed inside the husk. The plant is not wearing the husk, it is
		-- looking out of it.
		Body = Color3.fromRGB(246, 220, 152),
		-- The husk plates and the collar ring they spring from.
		Crown = Color3.fromRGB(198, 124, 62),
		-- The knot where the two upper plates meet over the bud.
		Accent = Color3.fromRGB(246, 228, 182),
		Leaf = DUST_LEAF, Stem = DUST_STEM, Soil = SOIL,
	},
	{
		Id = "paddlehop", Name = "Paddlehop", Rarity = "Uncommon", Biome = "dustbowl",
		Kg = 12, Height = 3.0, Form = "pad",
		-- Two Uncommons in one biome have to be told apart at a glance, so the
		-- MASS carries the difference: Dunebud is sand-and-rust, this is
		-- sage-and-olive. Same family, opposite ends of it.
		Body = Color3.fromRGB(168, 180, 96),
		-- EVERY rounded rim, on the main pad and all three buds alike. The eye
		-- reads "edge" once and then reads it everywhere.
		Crown = Color3.fromRGB(122, 134, 68),
		-- The bloom: the most saturated thing in the biome, and one part the
		-- size of a thumbnail. Deliberate -- a desaturated flower would read as
		-- background scenery.
		Accent = Color3.fromRGB(228, 92, 66),
		Leaf = DUST_LEAF, Stem = DUST_STEM, Soil = SOIL,
	},
	{
		Id = "thornwhorl", Name = "Thornwhorl", Rarity = "Rare", Biome = "dustbowl",
		Kg = 35, Height = 3.4, Form = "whorl",
		-- Cold and bleached against both Uncommons: a warm desert-tan core in
		-- weathered driftwood blades. Defensive and wind-carved without reaching
		-- for anything that reads as dangerous.
		Body = Color3.fromRGB(206, 184, 138),
		-- The blade whorl. Two of the five sit darker so it has depth instead of
		-- five identical boards.
		Crown = Color3.fromRGB(172, 104, 68),
		-- The hooks: pale dry ochre, barely above the plate they grow out of,
		-- which is what makes them read as GROWN rather than screwed on.
		Accent = Color3.fromRGB(230, 194, 128),
		Leaf = DUST_LEAF, Stem = DUST_STEM, Soil = SOIL,
	},
	{
		Id = "raincup", Name = "Raincup", Rarity = "Epic", Biome = "dustbowl",
		Kg = 90, Height = 3.8, Form = "cup",
		-- A rain-catching vessel first and a bloom second. The cup is a stepped
		-- goblet, not one wide disc: a Roblox Cylinder seen side-on is a plain
		-- rectangle, and one wide disc read as a box with two horns from the
		-- only angle a player actually has.
		Body = Color3.fromRGB(124, 188, 242),
		-- The focal core: the recessed floor and the pollen boss. Flush with the
		-- rim, never sunk below it -- the engine has no hollow cylinder, so a
		-- floor "recessed" inside a solid rim is simply buried.
		Crown = Color3.fromRGB(255, 216, 84),
		-- The throat of TWO lobes only. Selected, not smeared over all five.
		Accent = Color3.fromRGB(226, 100, 142),
		Leaf = DUST_LEAF, Stem = DUST_STEM, Soil = SOIL,
	},
	{
		Id = "suncrown", Name = "Suncrown", Rarity = "Legendary", Biome = "dustbowl",
		Kg = 240, Height = 4.2, Form = "crown",
		-- The tallest frame in the biome, and the only one whose head is a
		-- radiating crown. Its preview was authored on its OWN size curve
		-- ((kg/110)^0.18); conforming it to the shared SizeScale is what keeps
		-- "a Dunebud stays shorter than a Suncrown at every weight" true.
		Body = Color3.fromRGB(255, 198, 38),
		Crown = Color3.fromRGB(239, 116, 25),
		Accent = Color3.fromRGB(210, 61, 45),
		Leaf = DUST_LEAF, Stem = DUST_STEM, Soil = SOIL,
	},
} :: { Species }

--==============================================================================
-- WHAT A PORTRAIT NEEDS, IN ONE PLACE
--
-- The HUD draws plants in two panels -- the Index almanac and the Garden bed --
-- and both want the same seven colours plus the form. Assembling that table at
-- each call site is how one of them ends up passing the wrong green six months
-- from now, so the sheet hands it out itself.
--
-- Deliberately a plain table rather than the Species row: a portrait has no
-- business seeing `Kg`, and the two shared colours it needs are module locals
-- rather than fields.
--==============================================================================
export type PortraitSpec = {
	form: string,
	body: Color3,
	crown: Color3,
	accent: Color3,
	leaf: Color3,
	stem: Color3,
	soil: Color3,
	blush: Color3,
}

function SeedData.PortraitSpec(species: Species): PortraitSpec
	return {
		form = species.Form,
		body = species.Body,
		crown = species.Crown,
		accent = species.Accent,
		leaf = species.Leaf,
		stem = species.Stem,
		soil = species.Soil,
		blush = BLUSH,
	}
end

--==============================================================================
-- THE WEIGHT ROLL
--
-- One curve for all five species. Heavy is rare, and rare is very rare.
--
--     kg = MaxKg ^ (u ^ CURVE)      u uniform on [0, 1)
--
-- A plain log-uniform roll (CURVE = 1) puts a quarter of all pods over 10 kg
-- and a quarter over 100 -- far too generous at the top. Raising the exponent
-- bends the mass down toward the floor while still leaving the whole range
-- reachable, and one number tunes the entire economy.
--
-- Measured over 10,000 samples at CURVE = 2.2, and printed at boot so it can
-- never quietly drift:
--
--     kg <=     10    ~53%      most pods are pocket change
--     kg <=    110    ~74%      and most of the rest are ordinary
--     kg >=  1,000    ~12%      uncommon
--     kg >=  5,000     ~3.5%    rare
--     kg >=  9,000     ~0.5%    vanishing
--
-- If the histogram ever shows 10,000 as common, or nothing over 100, this is
-- the number to move. Do not flatten it.
--==============================================================================
local KG_CURVE = 2.2

function SeedData.RollKg(rng: Random): number
	local u = rng:NextNumber()
	local kg = GameConfig.Carry.MaxKg ^ (u ^ KG_CURVE)
	return math.clamp(math.floor(kg + 0.5), 1, GameConfig.Carry.MaxKg)
end

--==============================================================================
-- WHAT A WEIGHT LOOKS LIKE
--
-- The pod's colour is its WEIGHT band, not its species tier. That is the whole
-- point of rolling: a Nubkin shell glowing Divine is an 9,000 kg cube, and the
-- player has to read the pod rather than recognise the shape.
--
-- The sheet's `Rarity` field still exists and still means what it always meant
-- -- how often that FORM turns up in the pool. The Index spells that word. It
-- has nothing to do with what a given pod is worth any more.
--==============================================================================
local KG_BANDS = {
	{ 9000, "Divine" },
	{ 5000, "Secret" },
	{ 1500, "Mythic" },
	{ 400, "Legendary" },
	{ 100, "Epic" },
	{ 30, "Rare" },
	{ 10, "Uncommon" },
	{ 0, "Common" },
}

function SeedData.RarityForKg(kg: number): string
	local n = if type(kg) == "number" and kg == kg then kg else 0
	for _, band in ipairs(KG_BANDS) do
		if n >= (band[1] :: number) then
			return band[2] :: string
		end
	end
	return "Common"
end

function SeedData.ColorForKg(kg: number): Color3
	return GameConfig.RarityColor[SeedData.RarityForKg(kg)]
		or Color3.fromRGB(200, 200, 200)
end

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
	-- Kg is only the old-save fallback now, but it still has to be sane:
	-- a plant restored onto a nonsense weight would pay a nonsense rate.
	assert(species.Kg > 0 and species.Kg <= GameConfig.Carry.MaxKg,
		string.format("species %q has fallback weight %g, outside 0..%d",
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
function SeedData.IncomePerSecond(kg: number): number
	return kg * GameConfig.Carry.CashPerKg
end

function SeedData.CarryMultiplier(kg: number): number
	return GameConfig.carryMultiplierFor(kg)
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

function SeedData.GrowSeconds(kg: number): number
	local t = math.clamp(kg / GameConfig.Carry.MaxKg, 0, 1) ^ GROW_EXP
	return GROW_BASE + GROW_SPAN * t
end

--==============================================================================
-- HOW BIG A POD IS
--
-- Every pod used to be the same size, which threw away the one piece of
-- information the player most needs before committing to a hold: how much this
-- is going to cost to carry. Weight already decides the income and the slow;
-- making it decide the SILHOUETTE means a player reads the trade before
-- pressing anything, from across the nest, with no UI at all.
--
-- THE CEILING HAD TO COME OFF. This clamped at 4.5, which was right when the
-- heaviest thing in the game was a 110 kg Bellchime. Now that any pod can roll
-- 10,000, a 4.5 clamp would make every pod over 400 kg look identical -- and
-- the top of the range is exactly where a player needs to be able to tell.
--
-- The EXPONENT came down as the ceiling went up, 0.28 -> 0.23, chosen so the
-- whole 1 .. 10,000 range lands inside 1.3 .. 10 without ever reaching the
-- clamp. The clamp is a rail now rather than a limiter.
--
--     1 kg -> 1.30      110 kg -> 3.54      5,000 kg -> 8.51
--     2 kg -> 1.41    1,000 kg -> 5.88     10,000 kg -> 9.98
--
-- Ten studs is a boulder at arm's length: it fills the screen, it rides five
-- studs in front of the chest (see GripForward), and it still does not swallow
-- the player carrying it.
--==============================================================================
function SeedData.PodDiameter(kg: number): number
	return math.clamp(1.2 * (kg ^ 0.23), 1.3, 10.5)
end

--==============================================================================
-- GIRTH IS PROPORTION, NOT SIZE
--
-- This used to be the ONLY thing weight changed, so it carried the whole "a
-- heavy thing looks heavy" job by itself and ran 0.70 to 1.75 across the old
-- 2 .. 110 kg range. SizeScale does that job now, and the two MULTIPLY: left at
-- its old slope of 0.24 a 10,000 kg creature would be four times taller and
-- five times wider than its sheet entry, which is not colossal, it is a puddle.
--
-- So the slope halves to 0.12 and the CEILING goes up instead, 1.75 -> 2.40.
-- The reference stays 14 kg -- Spiretip's weight, the middle of the sheet -- so
-- the species that already looked right still returns exactly 1.00 and the
-- curve spreads either side of something known good.
--
--     1 kg -> 0.73      14 kg -> 1.00      1,000 kg -> 1.67
--     2 kg -> 0.79     110 kg -> 1.28     10,000 kg -> 2.20
--
-- The floor stays 0.70: below it a Nubkin's stem stops being visible against
-- studded soil.
--==============================================================================
local GIRTH_REF_KG = 14
local GIRTH_EXP = 0.12

function SeedData.Girth(kg: number): number
	local n = if type(kg) == "number" and kg == kg and kg > 0 then kg else 1
	return math.clamp((n / GIRTH_REF_KG) ^ GIRTH_EXP, 0.70, 2.40)
end

--==============================================================================
-- SIZE FOLLOWS THE WEIGHT, ON EVERY FORM
--
-- A multiplier on the species' FRAME height, so the shape stays the species'
-- and the scale is the pod's. `Height` on the sheet now literally means "how
-- tall this form stands at the reference weight", and the reference is 7.5 kg
-- -- the MEDIAN ROLL. A median pod stands at exactly its sheet size, so the
-- sheet keeps meaning what it always meant.
--
-- FINISHED height, soil to crown -- what a player actually sees, and the same
-- measurement the Height field is documented in:
--
--     kg        Nubkin  Petalpip  Spiretip  Toadcap  Bellchime
--          1       1.2      1.6       2.5      2.4       2.5
--          2       1.4      1.9       2.9      2.9       3.0
--         14       2.3      3.2       4.8      5.0       5.2
--        110       4.0      5.6       8.1      9.0       9.2
--      1,000       7.4     10.3      14.7     17.0      17.3
--     10,000      14.1     19.9      27.7     33.4      33.8
--
-- Measured off models actually built, not read off this formula -- ServerMain
-- rebuilds the Nubkin and Bellchime columns at every boot for that reason.
--
-- A Nubkin stays shorter than a Bellchime at every weight, which is what keeps
-- the form readable while the weight decides how much of it there is.
--
-- WHY THESE ARE NOT THE NUMBERS THAT WERE ASKED FOR
--
-- The brief wanted 2 kg to look like today's Nubkin (1.74), 110 kg like today's
-- Bellchime (6.41), and 10,000 kg to land in 18 .. 28 on every form. Those
-- cannot all hold at once, and it is worth writing down why so nobody re-opens
-- it expecting a better exponent to exist:
--
--   * 1.74 and 6.41 are 3.7x apart across a 55x weight range, and nearly all of
--     that gap is the HEIGHT SHEET (2.4 against 4.0) plus the bell's crown, not
--     the weight. Pin both and the weight curve left over is almost flat --
--     exponent 0.03 -- and 10,000 kg finishes at four studs. Pin either one
--     together with the landmark and the other misses by about 40%.
--
--   * 18 .. 28 is a 1.56x band, but the five forms are 2.4x apart at the SAME
--     weight, because a cube ends at its head while a bell carries a skirt and
--     a ring of buds. No exponent narrows that. It is the sheet, not the curve.
--
-- So SIZE_EXP is a least-squares fit to all four written targets at once, which
-- misses each by roughly the same amount instead of nailing one and abandoning
-- the rest: 2 kg finishes at 1.4 against 1.7, 110 kg at 9.2 against 6.4, and
-- 10,000 kg spans 14 .. 34 against 18 .. 28. Raising SIZE_EXP trades the small
-- end away for the big one and lowering it does the reverse. There is no value
-- that satisfies both, so pick which end matters and move this one number.
--==============================================================================
local SIZE_REF_KG = 7.5
local SIZE_EXP = 0.20

--==============================================================================
-- THE REFERENCE WEIGHT, EXPORTED
--
-- The Index lists FORMS and has no weight to show one at -- `species.Kg` is the
-- old-save fallback and sizing anything from it is a bug (see the top of this
-- file). The median roll is the honest answer: a plant built at 7.5 kg stands
-- at exactly its sheet size, so an almanac card shows the shape as drawn rather
-- than at some weight nobody rolled.
--==============================================================================
SeedData.SizeReferenceKg = SIZE_REF_KG

function SeedData.SizeScale(kg: number): number
	local n = if type(kg) == "number" and kg == kg and kg > 0 then kg else 1
	return (n / SIZE_REF_KG) ^ SIZE_EXP
end

-- How tall this form stands at this weight, before the builder adds a head.
function SeedData.FrameHeight(species: Species, kg: number): number
	return species.Height * SeedData.SizeScale(kg)
end

--==============================================================================
-- How far in front of the root a pod of this weight rides. ONE definition:
-- CarryService welds with it, CarryPose aims the arms with it. It follows the
-- pod's DIAMETER, so a boulder is held further out than a pebble and the offset
-- is never written down twice.
--==============================================================================
function SeedData.GripForward(kg: number): number
	return GameConfig.Carry.GripForwardBase + SeedData.PodDiameter(kg) * 0.5
end

-- The FORM's drop tier as a colour. Kept for the Index, which lists shapes and
-- still colours them by how often each turns up. Anything looking at a real pod
-- wants ColorForKg -- the band of what THAT ONE weighs.
function SeedData.FormColor(species: Species): Color3
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
