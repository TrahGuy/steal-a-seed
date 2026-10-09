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
-- WHAT A SPECIES IS WORTH, AND WHAT THE ROAD TO IT IS WORTH
--
-- Two factors on top of the size tier, and they answer two different questions:
-- WHAT you found, and HOW FAR you went to find it. Kept apart rather than
-- blended into one number per species, because a player can act on each of them
-- independently -- chase a rarer roll, or walk deeper -- and a single figure
-- would hide which lever they were pulling.
--
-- THEY ARE GENTLE ON PURPOSE. Rarity already carries an enormous spread in
-- RarityWeight above: Common is 1000 against Divine's 0.004, a quarter of a
-- million to one. A large income multiplier on top of that would be multiplying
-- a rarity that is already multiplied, and the top of the ladder would stop
-- being a prize and start being the only thing worth planting. 12x at odds of
-- one in 250,000 is a flourish, not a strategy.
--
-- The biome ladder is flatter still -- 1.0 to 1.4 across the whole road --
-- because it applies to EVERYTHING in a segment rather than to one lucky roll.
-- It is there to stop the deeper biomes being a cosmetic choice, not to make
-- Greenhollow worthless.
--
-- Every rarity in RarityWeight has an entry here and every biome in BiomeData
-- has one below, and the asserts at require time keep it that way: a new rarity
-- or a new biome refuses the file rather than quietly paying Common rates.
--==============================================================================
SeedData.RarityMultiplier = {
	Common = 1.00,
	Uncommon = 1.25,
	Rare = 1.50,
	Epic = 2.00,
	Legendary = 3.00,
	Mythic = 5.00,
	Secret = 8.00,
	Divine = 12.00,
}

-- Depth along the one road. Order matches BiomeData.Biomes, and the step is
-- deliberately even: a player should be able to guess the next one.
SeedData.BiomeMultiplier = {
	greenhollow = 1.00,
	dustbowl = 1.10,
	tanglemire = 1.20,
	emberroot = 1.30,
	starbloom = 1.40,
	-- The Rain event's temporary biome (2026-10-02). Its creatures pay a FIXED
	-- income that no multiplier touches; this entry exists only because every
	-- registered species must name a biome that has one.
	rain = 1.00,
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
	--==========================================================================
	-- A FLAT PER-SECOND BONUS, FOR THE ONES THAT WOULD OTHERWISE BE TWINS
	--
	-- Income is the size tier scaled by rarity and by biome depth, and that made
	-- every species in the same biome AT THE SAME RARITY earn exactly the same:
	-- Nubkin and Petalpip both $4/s, Novaorb and Cosmospire both $8/s. Two
	-- different plants with two different silhouettes paying one number reads as
	-- a placeholder, and a player comparing them has nothing to compare.
	--
	-- So six species carry a small flat bonus, approved by the owner on
	-- 2026-09-17, ADDED AFTER the rounding and multiplied by nothing:
	--
	--     Petalpip, Paddlehop, Crookreed, Emberquill, Novaorb   +$1/s
	--     Cosmospire                                            +$2/s
	--
	-- FLAT AT EVERY TIER ON PURPOSE. A bonus that scaled with the tier would be
	-- a second rarity ladder, and at Colossal it would swamp the one the rarity
	-- multiplier already draws. A dollar is a nudge at Tiny and a rounding error
	-- at Colossal, which is exactly the job: it separates two twins at the size
	-- where a player is choosing between them.
	--
	-- Absent means zero. Validated at require -- finite, whole, not negative --
	-- and the x2 Earn pass still doubles the TOTAL once, further down the
	-- economy, exactly as it always did.
	IncomeBonus: number?,
	--==========================================================================
	-- THE SECRET SPECIES' FLAGS (2026-10-01) -- absent on every listed species.
	-- See SeedData.SecretSpecies below for what a secret is.
	--==========================================================================
	-- "secret": SecretIdle (client) drives the replayed rig by forward kinematics
	-- and PlantSway leaves the limbs, eyes and lids alone.
	Animator: string?,
	-- "overhead": carried over the head in both hands, pod and plant alike.
	-- (A hatched plant built from the owner's supplied rigs is carried overhead
	-- too, without this flag: PlantForms.CarriedOverhead, 2026-10-03.)
	Carry: string?,
	-- Which rung of the walk ladder (SeedData.WanderLadder) a planted one walks
	-- on when it is not its own tier's (SeedData.WanderTierOf). The Secrets carry
	-- one internal tier (SecretTier) but stand at their authored, Colossal-scale
	-- size, so they walk the Colossal rung -- reach, shortest leg, speed and pause
	-- -- like every other creature their size (2026-10-02). Implementation only:
	-- never shown, never a size. Absent on every listed species.
	WanderTier: number?,
	-- The SecretForms pod replayed for this species' pod, by form id. A Rain
	-- species' Pod is also its pod in RainPods (the same name, for the first
	-- family's three); the second family's is RainPods' rainpod4, and its shell
	-- is the size's own, PodForms below (PodFormOf answers both).
	Pod: string?,
	-- True for a species that is in no biome pool, no Index shelf, no hatch-roll
	-- silhouette and no Biome Harvest. Reachable by id only.
	Secret: boolean?,
	-- A FIXED income in $/s (the Secrets, the owner's approved rates of
	-- 2026-10-02): IncomePerSecond answers exactly this, whatever the tier, with
	-- no tier, rarity or biome factor on top. Boosts still apply once, later, in
	-- EconomyService (the x2 pass, the chest, the sacrifice). Absent on every
	-- listed species, whose income is unchanged.
	FixedIncome: number?,
	--==========================================================================
	-- THE RAIN EVENT'S FLAGS (2026-10-02) -- absent on every other species.
	-- See SeedData.RainSpecies below.
	--==========================================================================
	-- Which weather event's nest hands this one out ("rain"). Unlisted: in no
	-- biome pool, no Index shelf, no hatch-roll silhouette, no reward pool.
	Event: string?,
	-- A FIXED growth time in seconds for its pod (GrowSecondsFor), whatever the
	-- tier. Absent: the tier's ladder (GrowSeconds), as every species has.
	FixedGrowSeconds: number?,
	-- While an UNBANKED pod of this species is carried, movement is exactly this
	-- share of the carrier's earned speed, in place of the ordinary carry
	-- multiplier, before traps and Walk Mode (CarryService.RefreshWalkSpeed).
	CarrySpeedFactor: number?,
	-- Shows no size word or size colour anywhere, like a Secret (Unsized): one
	-- authored size, and its tier is implementation only.
	Unsized: boolean?,
	-- Hatches straight into the reveal with no silhouette roll (PlantService
	-- hatch); every other species rolls as before.
	SkipHatchRoll: boolean?,
	--==========================================================================
	-- THE RAIN EVENT'S SECOND FAMILY (2026-10-05) -- absent on every other
	-- species. Squallsnapper, Monsoad, Thundershell and Torrentacle: one species
	-- each at all seven sizes. See SeedData.RainSpecies below.
	--==========================================================================
	-- The owner's unboosted $/s at each size, Tiny .. Colossal: IncomePerSecond
	-- answers exactly TierIncome[tier] -- no tier, rarity or biome factor on top;
	-- the pass, the chest, the sacrifice and the weather apply once, later, in
	-- EconomyService. Never alongside FixedIncome or IncomeBonus.
	TierIncome: { number }?,
	-- Its pod's growth time in seconds at each size, Tiny .. Colossal
	-- (GrowSecondsFor). Never alongside FixedGrowSeconds.
	TierGrowSeconds: { number }?,
	-- The replayed pod shell at each size, Tiny .. Colossal: the owner's seven
	-- supplied pods (RainForms.Pods), each ALREADY at its size and never scaled
	-- again (PodFormOf). Absent: the one `Pod` form, whatever the size.
	PodForms: { string }?,
	--==========================================================================
	-- THE INVITE A FRIEND REWARDS' FLAGS (2026-10-06) -- absent on every other
	-- species. See SeedData.InviteSpecies below.
	--==========================================================================
	-- An invite reward: given by InviteService and by nothing else; unlisted.
	Invite: boolean?,
	-- No stall buys it and no screen prices it (SeedData.Sellable).
	Unsellable: boolean?,
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

--==============================================================================
-- BIOME 3: TANGLEMIRE
--
-- ONE FACTOR CONFORMS THE WHOLE BIOME, AND IT HAD TO BE ONE
--
-- The approved mockups carry no weight attribute, so nothing records what
-- weight they were drawn at. Taken at face value they made a Tanglemire plant
-- about 1.6x a Dustbowl one of the same weight -- 6.07 to 6.81 against a ladder
-- that had reached 4.2 -- which is not a progression step, it is a different
-- scale.
--
-- Every Height below is its mockup height times 0.646109, chosen so the biome's
-- tallest lands on 4.4 and the top of each band still steps by two tenths:
--
--     greenhollow  2.40 3.00 3.20 3.60 4.00
--     dustbowl     2.60 3.00 3.40 3.80 4.20
--     tanglemire   3.92 3.99 4.35 4.21 4.40
--
-- ONE factor rather than a per-species ladder, because the five were approved
-- TOGETHER. Their heights relative to each other are part of what was signed
-- off -- Lanterncap is deliberately shorter than Snapmoss, which a tidy
-- ascending ladder would have quietly reversed. Scaling the set preserves every
-- one of those relationships to within a thousandth; re-laddering them would
-- have been a redesign wearing a balance change as a hat.
--
-- The GEOMETRY did not move. TanglemireForms still holds the mockups part for
-- part, and PreviewHeight still holds what they were drawn at; the builder's
-- conformance factor is Height / PreviewHeight, so changing Height here is the
-- whole of the change.
--
-- Same rule a third time: STEM, LEAF and SOIL are shared by all five, and the
-- head is where a species gets to be itself.
--
-- These three are SAMPLED OFF THE APPROVED MOCKUPS rather than chosen. The mire
-- green appears in all five approved plants twenty-three times, the muted stem
-- thirteen, and every one of the five stands on a peat hummock of exactly
-- 72,56,44. Picking a nicer green here would put the sheet and the art in
-- disagreement on day one.
--
-- SOIL IS NOT THE SHARED BROWN THIS TIME, and that is deliberate. Greenhollow
-- and Dustbowl both heap the player's own bed around the stem, so their soil is
-- the bed's colour. A Tanglemire plant stands on peat it grew out of -- the
-- approved footing is part of the plant, not a heap shovelled round it.
--==============================================================================
--==============================================================================
-- EMBERROOT SHARES ITS GROUND, NOT ITS BODY
--
-- Leaf, Stem and Soil are the biome's; Body, Crown and Accent are the species'.
-- Emberroot pushes that further than the other three: only the cinder pad and
-- the root-legs are shared, because an earlier pass shared the whole body and
-- the five read as one plant in five hats. Soil is that pad -- cold clinker,
-- not earth.
--==============================================================================
local EMBER_LEAF = Color3.fromRGB(92, 46, 32)
local EMBER_STEM = Color3.fromRGB(120, 86, 66)
local EMBER_CINDER = Color3.fromRGB(46, 34, 32)

local STAR_LEAF = Color3.fromRGB(158, 128, 255)
local STAR_STEM = Color3.fromRGB(48, 30, 78)
local STAR_SOIL = Color3.fromRGB(16, 12, 32)

local MIRE_LEAF = Color3.fromRGB(70, 128, 88)
local MIRE_STEM = Color3.fromRGB(82, 112, 76)
local MIRE_PEAT = Color3.fromRGB(72, 56, 44)

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

-- Tanglemire's three, for the same reason: the HUD draws plants too.
SeedData.MireLeaf = MIRE_LEAF
SeedData.MireStem = MIRE_STEM
SeedData.MirePeat = MIRE_PEAT

SeedData.Species = {
	{
		Id = "nubkin", Name = "Nubkin", Rarity = "Common", Biome = "greenhollow",
		Height = 3.72, Form = "cube",
		-- Crown is the pair of sprout leaves on top of the cube; Accent is
		-- their pale tips. The cube used to have neither and was the only
		-- species with nothing on its head at all.
		Body = GREEN,
		Crown = Color3.fromRGB(176, 214, 128),
		Accent = CREAM, Leaf = LEAF, Stem = STEM, Soil = SOIL,
	},
	{
		Id = "petalpip", Name = "Petalpip", Rarity = "Common", Biome = "greenhollow",
		IncomeBonus = 1,
		Height = 4.65, Form = "orb",
		-- Lifted off Nubkin's green toward yellow. Same family, sunlit.
		Body = Color3.fromRGB(206, 224, 132),
		Crown = Color3.fromRGB(250, 246, 226),
		Accent = Color3.fromRGB(232, 132, 106), Leaf = LEAF, Stem = STEM, Soil = SOIL,
	},
	{
		Id = "spiretip", Name = "Spiretip", Rarity = "Uncommon", Biome = "greenhollow",
		Height = 4.96, Form = "teardrop",
		-- The dark one. Fourteen points off Nubkin was invisible; this is a
		-- different green, cooler and deeper, and it is the only one in the
		-- biome that reads as shade rather than sunlight.
		Body = Color3.fromRGB(94, 152, 104),
		Crown = Color3.fromRGB(236, 242, 206),
		Accent = Color3.fromRGB(242, 246, 220), Leaf = LEAF, Stem = STEM, Soil = SOIL,
	},
	{
		Id = "toadcap", Name = "Toadcap", Rarity = "Rare", Biome = "greenhollow",
		Height = 5.58, Form = "mushroom",
		-- Warm cream, against Bellchime's cool one. The red cap does most of
		-- the work at distance; this is what separates them close up.
		Body = Color3.fromRGB(240, 228, 198),
		Crown = Color3.fromRGB(216, 112, 100),
		Accent = Color3.fromRGB(250, 246, 226), Leaf = LEAF, Stem = STEM, Soil = SOIL,
	},
	{
		Id = "bellchime", Name = "Bellchime", Rarity = "Epic", Biome = "greenhollow",
		Height = 6.20, Form = "bell",
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
		Height = 4.03, Form = "husk",
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
		IncomeBonus = 1,
		Height = 4.65, Form = "pad",
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
		Height = 5.27, Form = "whorl",
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
		Height = 5.89, Form = "cup",
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
		Height = 6.51, Form = "crown",
		-- The tallest frame in the biome, and the only one whose head is a
		-- radiating crown. Its preview was authored on its OWN size curve
		-- ((kg/110)^0.18); conforming it to the shared SizeScale is what keeps
		-- "a Dunebud stays shorter than a Suncrown at every weight" true.
		Body = Color3.fromRGB(255, 198, 38),
		Crown = Color3.fromRGB(239, 116, 25),
		Accent = Color3.fromRGB(210, 61, 45),
		Leaf = DUST_LEAF, Stem = DUST_STEM, Soil = SOIL,
	},
	{
		Id = "bogbonnet", Name = "Bogbonnet", Rarity = "Rare", Biome = "tanglemire",
		Height = 6.07, Form = "bonnet",
		Body = Color3.fromRGB(42, 92, 74),
		Crown = Color3.fromRGB(196, 210, 162),
		Accent = Color3.fromRGB(168, 214, 96),
		Leaf = MIRE_LEAF, Stem = MIRE_STEM, Soil = MIRE_PEAT,
	},
	{
		Id = "crookreed", Name = "Crookreed", Rarity = "Rare", Biome = "tanglemire",
		IncomeBonus = 1,
		Height = 6.18, Form = "reed",
		-- The second Rare, and the only one whose dominant mass is BROWN. Two
		-- Rares in one biome is a first, so they had to be told apart by
		-- silhouette and by palette at once rather than by rarity word.
		Body = Color3.fromRGB(144, 98, 68),
		Crown = Color3.fromRGB(70, 128, 88),
		Accent = Color3.fromRGB(42, 92, 74),
		Leaf = MIRE_LEAF, Stem = MIRE_STEM, Soil = MIRE_PEAT,
	},
	{
		Id = "snapmoss", Name = "Snapmoss", Rarity = "Epic", Biome = "tanglemire",
		Height = 6.74, Form = "moss",
		Body = Color3.fromRGB(42, 92, 74),
		Crown = Color3.fromRGB(204, 94, 88),
		Accent = Color3.fromRGB(168, 214, 96),
		Leaf = MIRE_LEAF, Stem = MIRE_STEM, Soil = MIRE_PEAT,
	},
	{
		Id = "lanterncap", Name = "Lanterncap", Rarity = "Legendary", Biome = "tanglemire",
		Height = 6.52, Form = "lantern",
		Body = Color3.fromRGB(238, 188, 78),
		Crown = Color3.fromRGB(220, 218, 176),
		Accent = Color3.fromRGB(168, 214, 96),
		Leaf = MIRE_LEAF, Stem = MIRE_STEM, Soil = MIRE_PEAT,
	},
	{
		Id = "gloomlotus", Name = "Gloomlotus", Rarity = "Mythic", Biome = "tanglemire",
		Height = 6.82, Form = "lotus",
		-- The first Mythic form in the game, and since 2026-09-11 a walking
		-- mangrove stilt titan. It is the only plant in its biome that carries
		-- its own light -- a Neon wisp jewel with a PointLight and a spore
		-- emitter -- and that budget is the rarity: nothing below Mythic gets
		-- one. Its colours live in TanglemireForms; Body, Crown and Accent
		-- below reach none of its parts.
		Body = Color3.fromRGB(146, 232, 204),
		Crown = Color3.fromRGB(188, 224, 108),
		Accent = Color3.fromRGB(92, 172, 154),
		Leaf = MIRE_LEAF, Stem = MIRE_STEM, Soil = MIRE_PEAT,
	},
	{
		Id = "cinderpaw", Name = "Cinderpaw", Rarity = "Rare", Biome = "emberroot",
		Height = 4.33, Form = "paw",
		Body = Color3.fromRGB(52, 40, 38),
		Crown = Color3.fromRGB(255, 118, 44),
		Accent = Color3.fromRGB(198, 68, 24),
		Leaf = EMBER_LEAF, Stem = EMBER_STEM, Soil = EMBER_CINDER,
	},
	{
		Id = "emberquill", Name = "Emberquill", Rarity = "Rare", Biome = "emberroot",
		IncomeBonus = 1,
		Height = 7.47, Form = "quill",
		-- The second Rare, and the tallest plant in the game. Two Rares in a
		-- biome is Tanglemire's precedent, and the same rule applies: they are
		-- told apart by SILHOUETTE, not by the word. Cinderpaw fans OUT and sits
		-- low; this points UP. They are also the shortest and the tallest of the
		-- five, so the pair cannot be confused at any distance.
		Body = Color3.fromRGB(96, 78, 62),
		Crown = Color3.fromRGB(255, 200, 92),
		Accent = Color3.fromRGB(255, 196, 78),
		Leaf = EMBER_LEAF, Stem = EMBER_STEM, Soil = EMBER_CINDER,
	},
	{
		Id = "slagbloom", Name = "Slagbloom", Rarity = "Epic", Biome = "emberroot",
		Height = 4.66, Form = "slag",
		Body = Color3.fromRGB(38, 18, 18),
		Crown = Color3.fromRGB(168, 38, 30),
		Accent = Color3.fromRGB(255, 84, 26),
		Leaf = EMBER_LEAF, Stem = EMBER_STEM, Soil = EMBER_CINDER,
	},
	{
		Id = "kilnhusk", Name = "Kilnhusk", Rarity = "Legendary", Biome = "emberroot",
		Height = 6.48, Form = "kiln",
		-- The only cool grey in a biome of warm charcoal. Fired clay, and the
		-- one species whose crown is a housing rather than foliage.
		Body = Color3.fromRGB(60, 58, 56),
		Crown = Color3.fromRGB(255, 148, 40),
		Accent = Color3.fromRGB(255, 148, 40),
		Leaf = EMBER_LEAF, Stem = EMBER_STEM, Soil = EMBER_CINDER,
	},
	{
		Id = "pyrelotus", Name = "Pyrelotus", Rarity = "Mythic", Biome = "emberroot",
		Height = 7.20, Form = "pyre",
		-- Violet-charcoal: the only cool-dark in the biome, which is the Mythic
		-- doing its job before you have read the word.
		Body = Color3.fromRGB(52, 32, 56),
		Crown = Color3.fromRGB(255, 140, 96),
		Accent = Color3.fromRGB(255, 128, 148),
		Leaf = EMBER_LEAF, Stem = EMBER_STEM, Soil = EMBER_CINDER,
	},
	--==========================================================================
	-- STARBLOOM -- biome 5
	--
	-- The cosmic climax of the road. RarityBonus 9.0. Rare to Mythic.
	-- Void-carapace foundations, amethyst crystal petals, neon nebula cores.
	--
	-- Leaf, Stem, Soil are the biome's; Body, Crown and Accent are the species'.
	-- Each species sits at a different VALUE and HUE along the cosmic ladder:
	--
	--   Novaorb    cosmic indigo       Body 39,37,82   Crown 158,128,255 Accent 110,230,255
	--   Cosmospire midnight slate      Body 24,18,46   Crown 180,150,255 Accent 110,230,255
	--   Voidpetal  amethyst dark       Body 48,30,78   Crown 214,140,255 Accent 255,140,180
	--   Astralhorn void obsidian       Body 28,22,54   Crown 130,100,220 Accent 242,238,255
	--   Supernovus singularity void    Body 20,14,38   Crown 255,215,120 Accent 180,245,255
	--==========================================================================
	{
		Id = "novaorb", Name = "Novaorb", Rarity = "Rare", Biome = "starbloom",
		IncomeBonus = 1,
		Height = 4.60, Form = "orb",
		Body = Color3.fromRGB(39, 37, 82),
		Crown = Color3.fromRGB(158, 128, 255),
		Accent = Color3.fromRGB(110, 230, 255),
		Leaf = STAR_LEAF, Stem = STAR_STEM, Soil = STAR_SOIL,
	},
	{
		Id = "cosmospire", Name = "Cosmospire", Rarity = "Rare", Biome = "starbloom",
		IncomeBonus = 2,
		Height = 7.40, Form = "spire",
		Body = Color3.fromRGB(24, 18, 46),
		Crown = Color3.fromRGB(180, 150, 255),
		Accent = Color3.fromRGB(110, 230, 255),
		Leaf = STAR_LEAF, Stem = STAR_STEM, Soil = STAR_SOIL,
	},
	{
		Id = "voidpetal", Name = "Voidpetal", Rarity = "Epic", Biome = "starbloom",
		Height = 5.60, Form = "petal",
		Body = Color3.fromRGB(48, 30, 78),
		Crown = Color3.fromRGB(214, 140, 255),
		Accent = Color3.fromRGB(255, 140, 180),
		Leaf = STAR_LEAF, Stem = STAR_STEM, Soil = STAR_SOIL,
	},
	{
		Id = "astralhorn", Name = "Astralhorn", Rarity = "Legendary", Biome = "starbloom",
		Height = 6.90, Form = "horn",
		Body = Color3.fromRGB(28, 22, 54),
		Crown = Color3.fromRGB(130, 100, 220),
		Accent = Color3.fromRGB(242, 238, 255),
		Leaf = STAR_LEAF, Stem = STAR_STEM, Soil = STAR_SOIL,
	},
	{
		Id = "supernovus", Name = "Supernovus", Rarity = "Mythic", Biome = "starbloom",
		Height = 8.20, Form = "supernova",
		Body = Color3.fromRGB(20, 14, 38),
		Crown = Color3.fromRGB(255, 215, 120),
		Accent = Color3.fromRGB(180, 245, 255),
		Leaf = STAR_LEAF, Stem = STAR_STEM, Soil = STAR_SOIL,
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

--==============================================================================
-- WHAT A BAG ITEM IS WORTH AT THE STALL
--
-- Selling is a CONVENIENCE, not a strategy, and the price says so out loud.
--
-- A grown plant pays its adjusted rate every second for as long as it stands.
-- Selling the
-- same thing hands over thirty seconds of that and takes it away forever, so
-- anything worth keeping is worth planting and the stall is for clearing out a
-- bag full of pocket change -- which, per the weight histogram above, is what
-- most of a bag actually is.
--
-- ONE NUMBER TUNES IT. Raise SellSeconds and selling starts competing with
-- planting; drop it and the stall stops being worth the walk.
--
-- IT IS THIRTY SECONDS OF THE ADJUSTED RATE, so a rarer plant and a deeper
-- biome are worth more at the stall in exactly the proportion they are worth
-- more in the ground. The number the player has to hold in their head is still
-- one number -- "thirty seconds" -- which was always the point; what it is
-- thirty seconds OF is now worth knowing.
--
-- Floored, because cash is whole numbers everywhere else in the game.
--==============================================================================
--==============================================================================
-- SIZE TIERS -- THE KILOGRAM IS GONE
--
-- Seven named tiers replace a continuous weight. A plant is TINY or TITAN, not
-- 4,812 kg, and the name is the whole stat: it decides how big it stands, how
-- much it pays, how long it grows, how big its pod is, and how much it slows
-- you carrying it.
--
-- THE NUMBERS ARE CUT FROM THE OLD DISTRIBUTION, NOT INVENTED.
--
-- Weight rolled as MaxKg^(u^2.2) over 1 .. 10,000, which put 53% of pods at
-- 10 kg or under and half a percent over 9,000. Each tier takes one band of
-- that curve: `weight` is how often the band came up and `value` is the mean
-- weight inside it. Income was kilograms per second, so the BASE rate per plant lands
-- where it already was and every mill price, sell price and progression gate
-- keeps working untouched. That is the whole reason for deriving the numbers
-- instead of picking seven round ones.
--
-- `mul` is the size ladder, and it is NOT geometric any more. The bottom three
-- are locked where they were and the top four are set by hand:
--
--     Tiny 1     Big 1.308     Huge 1.710  |  Mega 5     Giant 10     Titan 20     Colossal 50
--
-- The step from Huge to Mega is 2.9x where the ones before it are 1.31x, so the
-- ladder has a deliberate CLIFF a third of the way up: the bottom three are a
-- gentle spread of ordinary plants and everything above Huge is an event. That
-- is a design choice, not an oversight -- do not "fix" it back to geometric.
--
-- TINY IS THE LOCKED END, not COLOSSAL. The ladder used to be cut downward from
-- the approved art; it is now pinned at the BOTTOM and grows upward, so the top
-- is whatever five times gives you.
--
-- At 5x the tallest forms pass 46 studs -- Suncrown reaches 49.5 and Bellchime
-- 46.9 -- and 46 is GameConfig.Map.WallHeight, which is why that number kept
-- being treated as a ceiling. It is not one for plants. Those walls bound the
-- ROAD, where pods are stolen; plants grow on plot beds, and a raycast straight
-- up from a plot finds nothing within 120 studs. Open sky.
--
-- It IS a real ceiling for the nest guardians, which do stand in the lanes. If
-- a parent ever grows past 46, that is a clipping bug; a Colossal plant at 49
-- is just a tall plant.
--
-- `girth` and `pod` are the old curves sampled at each tier's own value, so a
-- Titan is as thick, and carries as big a pod, as a 5,200 kg plant used to.
--==============================================================================
export type Tier = {
	index: number,
	name: string,
	mul: number,
	weight: number,
	value: number,
	girth: number,
	pod: number,
	color: Color3,
}

--==============================================================================
-- THE SIZE LADDER
--
-- `mul` scales the species FRAME height, and everything visible descends from
-- it: body, limbs, roots, feet, the invisible Base and the girth spread. One
-- number, applied uniformly, which is what keeps a Colossal the same creature
-- as a Tiny rather than a differently-proportioned one.
--
-- REPLACED 2026-09-08. The old ladder was 1 / 1.308 / 1.71 / 5 / 10 / 20 / 50,
-- and it had two faults. The three bottom tiers were near-identical -- 31% apart
-- -- so Tiny, Big and Huge read as one creature; then Huge -> Mega was a 2.92x
-- CLIFF that launched the top of the ladder past anything the map could hold.
-- Measured on the real builders, a Colossal stood 217 (Nubkin) to 460
-- (Supernovus) studs against 46-stud corridor walls and a 16 x 13.7 planting
-- cell, with a footprint up to 382 studs across its own feet.
--
-- The ladder below is near-even, with the FINAL step deliberately the largest so
-- Colossal stays the thing worth chasing:
--
--     x1.38  x1.38  x1.39  x1.40  x1.38  x1.49
--
-- What that builds, measured, not predicted:
--
--     species      Tiny   Big   Huge   Mega  Giant  Titan  COLOSSAL
--     nubkin        3.1   4.5    6.5    9.6   14.1   20.7      33.0
--     bellchime     6.3   9.1   13.2   19.5   28.9   42.9      69.0
--     cinderpaw     4.3   5.9    8.1   11.4   15.9   21.9      32.6
--     cosmospire    7.7  10.6   14.5   20.3   28.3   39.0      58.1
--     supernovus    9.2  12.7   17.5   24.4   34.0   46.9      69.9
--
-- Tiny to Colossal is 10.6x in height and about 1,200x in volume; the tallest
-- Colossals stand half again as high as the corridor wall and thirteen avatars
-- tall. Verified as a PURE UNIFORM RESCALE of what shipped -- every measured
-- dimension of every species came out at 7.60/50 = 0.1520 of its old value,
-- worst deviation 0.37% -- so anatomy, root-to-foot contact, mouth depth and
-- animation sockets are the same geometry at a different size.
--
-- `girth` is NOT part of this and was not touched: it is a proportion, not a
-- size, and it is what keeps a broad creature broad.
--==============================================================================
SeedData.Tiers = {
	{ index = 1, name = "Tiny",       mul = 1.000, weight = 0.5325, value = 4,    girth = 0.82, pod = 1.66, color = Color3.fromRGB(170, 175, 180) },
	{ index = 2, name = "Big",        mul = 1.380, weight = 0.1593, value = 28,   girth = 0.90, pod = 2.59, color = Color3.fromRGB(120, 200, 110) },
	{ index = 3, name = "Huge",       mul = 1.900, weight = 0.1007, value = 140,  girth = 0.98, pod = 3.66, color = Color3.fromRGB( 90, 170, 240) },
	{ index = 4, name = "Mega",       mul = 2.650, weight = 0.0789, value = 530,  girth = 1.07, pod = 4.87, color = Color3.fromRGB(170, 120, 240) },
	{ index = 5, name = "Giant",      mul = 3.700, weight = 0.0592, value = 1650, girth = 1.17, pod = 6.09, color = Color3.fromRGB(255, 160,  60) },
	{ index = 6, name = "Titan",      mul = 5.100, weight = 0.0642, value = 5200, girth = 1.30, pod = 7.94, color = Color3.fromRGB(240,  80,  70) },
	{ index = 7, name = "Colossal",   mul = 7.600, weight = 0.0052, value = 9500, girth = 1.45, pod = 9.04, color = Color3.fromRGB(255, 215,  90) },
} :: { Tier }

SeedData.TierCount = #SeedData.Tiers
SeedData.BaseTier = 1

-- Anything arriving here with rubbish gets TINY rather than an error: a corrupt
-- save should plant a small creature, not refuse to load a garden.
function SeedData.Tier(index: number?): Tier
	local i = tonumber(index) or 1
	if i ~= i then
		i = 1
	end
	return SeedData.Tiers[math.clamp(math.floor(i), 1, #SeedData.Tiers)]
end

function SeedData.TierName(index: number?): string
	return SeedData.Tier(index).name
end

--==============================================================================
-- ROLLING ONE
--
-- A straight weighted pick off the table, so the odds live in ONE place beside
-- the tier they belong to rather than inside a curve somebody has to solve
-- before they can read them.
--==============================================================================
-- A size's weight in a biome's nests: a biome's RarityBonus multiplies the
-- weights of Mega and up. ONE rule for the roll below and for the Pod Guide's
-- odds (PodGuide), so the two cannot drift.
function SeedData.TierWeight(t: Tier, rarityBonus: number?): number
	local bonus = math.max(1, rarityBonus or 1)
	return if t.index >= 4 then t.weight * bonus else t.weight
end

function SeedData.RollTier(rng: Random, rarityBonus: number?): number
	local bonus = math.max(1, rarityBonus or 1)
	local roll = rng:NextNumber()
	if bonus <= 1 then
		local acc = 0
		for _, t in ipairs(SeedData.Tiers) do
			acc += t.weight
			if roll <= acc then
				return t.index
			end
		end
		return 1
	end

	local total = 0
	for _, t in ipairs(SeedData.Tiers) do
		total += SeedData.TierWeight(t, bonus)
	end

	local target = roll * total
	local acc = 0
	for _, t in ipairs(SeedData.Tiers) do
		acc += SeedData.TierWeight(t, bonus)
		if target <= acc then
			return t.index
		end
	end
	return 1
end

--==============================================================================
-- HOW A CREATURE OF THIS SIZE GETS AROUND ITS GARDEN
--
-- A LADDER THAT CLIMBS. The bigger the creature, the further one leg carries
-- it, because a leg is read against the body taking it: the same eight studs is
-- a stroll for a Tiny Nubkin and a shuffle for a Colossal that stands thirty
-- studs tall. The curve this replaced FELL with size -- 18.4 studs of reach at
-- Tiny down to 6.7 at Colossal, on a shared six-stud minimum -- so the biggest
-- things in the game took the smallest steps. Measured on Level 5 before the
-- change, the median leg went 13.6 studs at Tiny to 6.6 at Colossal.
--
--     tier       reach   min leg   speed    median leg, L5   median leg time
--     Tiny        11.5      6.0     2.05        9.7              4.7 s     short local walks
--     Big         13.5      7.5     1.95       11.5              5.9 s
--     Huge        16.0      9.0     1.85       14.0              7.6 s
--     Mega        20.0     11.0     1.75       17.5             10.0 s     across a real part of the plot
--     Giant       24.0     13.0     1.70       20.9             12.3 s
--     Titan       28.0     15.0     1.65       24.5             14.8 s
--     Colossal    32.5     17.5     1.60       28.9             18.1 s     long, heavy journeys
--
-- The medians are MEASURED, over thousands of simulated legs from the real
-- PlantWander chooser on real plot geometry -- corners, fences, the gateway, the
-- wing's junction and a crowded bed of twenty (tools/tests/PlantWanderSpec).
-- Level 3 lands within a stud of these. Level 1 is a 39 by 26 stud bed, so a
-- Colossal's median there is shorter, 25 studs, because the plot is.
--
-- REACH is the most one leg may carry it; MIN LEG is the least. The server
-- throws away any direction with less straight-line room than the minimum,
-- rather than shortening it -- see PlantWander.Choose -- so a Colossal against
-- a fence is not handed a two-stud shuffle.
--
-- SPEED falls with size, but gently, and it is studs per second, not body
-- lengths. A Colossal at 1.6 moves about a twentieth of its own height a second
-- and a Tiny Nubkin about two thirds of its own, so the big ones still read as
-- the heavy ones. The old ladder went down to 0.55 studs a second, which only
-- worked because the old legs were short: carried over the new distances it
-- would have meant fifty-second legs, a creature that looks frozen.
--
-- PAUSE is not part of the ladder and did not change: 2.3 s at Tiny rising to
-- 3.7 s at Colossal, stretched 0.7-1.7x per stop by the server. A plot of twenty
-- things never at rest reads as an infestation; a stop between walks is what
-- keeps it reading as a garden.
--
-- THE SERVER IS THE ONLY CALLER. Clients derive the speed they draw from the
-- leg they were handed -- distance over duration -- so there is no second copy
-- of these numbers to fall out of step with this one.
--==============================================================================
export type WanderRung = { reach: number, minLeg: number, speed: number }

SeedData.WanderLadder = {
	{ reach = 11.5, minLeg = 6.0, speed = 2.05 }, -- Tiny
	{ reach = 13.5, minLeg = 7.5, speed = 1.95 }, -- Big
	{ reach = 16.0, minLeg = 9.0, speed = 1.85 }, -- Huge
	{ reach = 20.0, minLeg = 11.0, speed = 1.75 }, -- Mega
	{ reach = 24.0, minLeg = 13.0, speed = 1.70 }, -- Giant
	{ reach = 28.0, minLeg = 15.0, speed = 1.65 }, -- Titan
	{ reach = 32.5, minLeg = 17.5, speed = 1.60 }, -- Colossal
} :: { WanderRung }

-- The shortest walk worth taking at all. When no straight line on the plot is
-- this long -- a creature boxed into a corner by geometry alone -- it rests
-- instead of twitching.
SeedData.WanderStallStuds = 1.5

assert(#SeedData.WanderLadder == SeedData.TierCount,
	"SeedData.WanderLadder needs one rung per tier")

local function tierValue(tier: number?): number
	return SeedData.Tier(tier).value
end

local function wanderRung(tier: number?): WanderRung
	return SeedData.WanderLadder[SeedData.Tier(tier).index]
end

function SeedData.WanderReach(tier: number?): number
	return wanderRung(tier).reach
end

function SeedData.WanderMinLeg(tier: number?): number
	return wanderRung(tier).minLeg
end

function SeedData.WanderSpeed(tier: number?): number
	return wanderRung(tier).speed
end

function SeedData.WanderPause(tier: number?): number
	return math.clamp(1.2 + tierValue(tier) ^ 0.10, 1.4, 4.5)
end

-- The tier whose rung a planted creature WALKS on: its species' WanderTier when
-- it has one (the Secrets: the Colossal rung for their authored size), its own
-- tier otherwise -- so every listed species walks exactly as it always has.
function SeedData.WanderTierOf(species: Species?, tier: number?): number?
	local own = if species then species.WanderTier else nil
	return if type(own) == "number" then own else tier
end

SeedData.SellSeconds = 30

--==============================================================================
-- THE SACRIFICE PEDESTAL (2026-09-28; SacrificeService)
--
-- One banked, unhatched pod buys a short burst of ONLINE garden income. Any
-- pod, of any size: the price is the pod and the prize does not depend on it.
-- The cooldown starts with the sacrifice, so the boost runs inside it and the
-- pedestal is back 135 s after the boost ends. No paid levels, no products.
--
-- WHAT THESE THREE NUMBERS ADD UP TO. Used at every chance the boost is up a
-- quarter of the time, which is +12.5% garden income on average, for one pod
-- every three minutes. One sacrifice is worth 22.5 s of the WHOLE garden's
-- income; the same pod sold is worth 30 s of ITS OWN plant's
-- (SeedData.SellSeconds). So past the first couple of plants a small pod is
-- worth more on the pedestal than at the stall, and the gap grows with the
-- garden. That is the design as asked for -- a use for pods nobody wants to
-- grow -- and it is the number to look at first if the stall stops being used.
--==============================================================================
SeedData.Sacrifice = {
	Multiplier = 1.5,
	DurationSeconds = 45,
	CooldownSeconds = 180,
}

--==============================================================================
-- THE RAIN (2026-10-02; WeatherService)
--
-- The owner's approved +25% on ONLINE planted income while it rains: one
-- factor, applied once, in EconomyService.RateFor -- on the pass and the
-- temporary boosts, like a weather multiplier on the whole garden, Secrets
-- included. Sale prices, base rates, offline earnings, growth, size and rarity
-- never see it. GameConfig.Weather holds everything about the event that is
-- not this number.
--==============================================================================
SeedData.Rain = {
	IncomeFactor = 1.25,
}
assert(SeedData.Rain.IncomeFactor > 1 and SeedData.Rain.IncomeFactor <= 2,
	"SeedData.Rain.IncomeFactor must be a bonus, and a modest one")
-- Checked on load, like the chest's: a boost that outlived its cooldown would
-- let a second sacrifice land on top of the first.
assert(SeedData.Sacrifice.Multiplier > 1, "the sacrifice must raise income")
assert(SeedData.Sacrifice.DurationSeconds > 0 and SeedData.Sacrifice.CooldownSeconds > 0,
	"the sacrifice's times must be positive")
assert(SeedData.Sacrifice.CooldownSeconds >= SeedData.Sacrifice.DurationSeconds,
	"a sacrifice's boost must end before the pedestal is ready again")

-- What a saved sacrifice is worth to garden income at one moment: the
-- multiplier while `now` is before `endsAt`, exactly 1 otherwise. Pure, so the
-- faucet, the attributes and a spec all ask the same question.
function SeedData.sacrificeMultiplier(endsAt: any, now: number): number
	local ends = tonumber(endsAt)
	if not ends or ends ~= ends or now >= ends then
		return 1
	end
	return SeedData.Sacrifice.Multiplier
end

-- Whether a stall may buy it (2026-10-06): every plant and pod but an invite
-- reward, which was earned by inviting friends and cannot be earned again. SELL
-- ONE refuses one, SELL ALL leaves it in the bag, and no screen prices it --
-- every one of them asks this, never the flag.
function SeedData.Sellable(species: Species?): boolean
	return type(species) == "table" and (species :: any).Unsellable ~= true
end

function SeedData.SellPrice(species: Species?, tier: number?): number
	-- Exactly SellSeconds of what the same plant pays standing up, and it takes
	-- the same species so the two can never drift apart. Income is already a
	-- whole number, so this multiplication is exact and wants no second
	-- rounding -- and the player can still check it in their head.
	return SeedData.IncomePerSecond(species, tier) * SeedData.SellSeconds
end

--==============================================================================
-- WHAT A GARDEN EARNS WHILE ITS OWNER IS AWAY
--
-- Balance, so it lives here. A player who has been gone at least MinAwaySeconds
-- comes back to a claim: every GROWN plant they left in the ground pays
-- Efficiency of its normal IncomePerSecond for the time they were gone, up to
-- MaxCreditSeconds in total. Pods earn nothing until hatched by hand, online or
-- off. The x2 pass applies when the claim is paid, exactly as it does online.
--
--   MinAwaySeconds    20 minutes: a server hop or a crash-and-rejoin is not
--                     "away", and it is also the time Roblox takes to
--                     disconnect an idle player.
--   MaxCreditSeconds  8 hours, the same horizon the mill's training charge
--                     refills over; a week away cannot buy more than a night.
--   Efficiency        half: time in the game is always worth more than time out
--                     of it, or nobody would run the road.
--
-- OfflineEarnings (server) does the arithmetic; OfflineUI only reads these to
-- say them.
--==============================================================================
SeedData.Offline = {
	MinAwaySeconds = 20 * 60,
	MaxCreditSeconds = 8 * 3600,
	Efficiency = 0.5,
}

function SeedData.RollKg(rng: Random): number
	-- GONE. Kept only as a loud failure for anything still asking for weight,
	-- because silently returning a number would let a caller keep working with
	-- a stat that no longer exists.
	error("SeedData.RollKg is gone -- use SeedData.RollTier", 2)
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

function SeedData.RarityForTier(tier: number?): string
	return SeedData.Tier(tier).name
end

function SeedData.ColorForTier(tier: number?): Color3
	return SeedData.Tier(tier).color
end

--==============================================================================
-- LOOKUPS, AND THE CHECKS THAT RUN AT REQUIRE
--==============================================================================
--==============================================================================
-- THE SECRET SPECIES -- 2026-10-01
--
-- Two plants the owner inserted by hand, one per biome, replayed from
-- SecretForms at their authored size (SecretModel). They are NOT in
-- SeedData.Species: that list is the biome pools, the Index shelves, the hatch
-- roll's silhouettes, the wheel's pod pools and the Biome Harvest, and the
-- owner's rule is that a secret joins none of them -- it spawns by NestService's
-- own 5% roll, in addition to the regular pods. They ARE reachable by id
-- (SeedData.Get), which is what planting, carrying, hatching and the Tool need.
--
-- Height is the model's authored height, recorded for the carry camera; the
-- builder does not scale by it. The colours only feed
-- the UI and the invisible Base plate -- the geometry carries its own.
--==============================================================================
SeedData.SecretSpecies = {
	{
		Id = "snarlbloom", Name = "Snarlbloom", Rarity = "Secret", Biome = "greenhollow",
		Height = 47.26, Form = "secret",
		Body = Color3.fromRGB(60, 118, 62),
		Crown = Color3.fromRGB(196, 255, 110),
		Accent = Color3.fromRGB(255, 120, 190), Leaf = LEAF, Stem = STEM, Soil = SOIL,
		Animator = "secret", Carry = "overhead", WanderTier = SeedData.TierCount, Pod = "greenhollowsecretpod",
		Secret = true,
		-- The owner's approved fixed rate (2026-10-02): $155,000/s, $310,000/s under the x2 pass.
		FixedIncome = 155000,
	},
	{
		Id = "petalfawn", Name = "Petalfawn", Rarity = "Secret", Biome = "starbloom",
		Height = 38.76, Form = "secret",
		Body = Color3.fromRGB(39, 37, 82),
		Crown = Color3.fromRGB(170, 120, 255),
		Accent = Color3.fromRGB(110, 224, 255),
		Leaf = Color3.fromRGB(91, 70, 164), Stem = Color3.fromRGB(58, 42, 112), Soil = Color3.fromRGB(40, 28, 84),
		Animator = "secret", Carry = "overhead", WanderTier = SeedData.TierCount, Pod = "starbloomsecretpod",
		Secret = true,
		-- The owner's approved fixed rate (2026-10-02): $189,000/s, $378,000/s under the x2 pass.
		FixedIncome = 189000,
	},
} :: { Species }

--==============================================================================
-- THE ONE TIER EVERY SECRET CARRIES, WHEREVER IT CAME FROM (2026-10-02)
--
-- IMPLEMENTATION ONLY. A Secret has its Secret rarity and no size tier: one
-- authored size, and a FIXED income (FixedIncome) that no tier touches. The
-- engine still keeps a tier on every Tool, saved row and planted entry, so the
-- Secrets carry this one -- NestService's spawn builds its pod at it and the
-- admin grant (AdminService, SECRET ITEMS) gives it -- and it decides only what
-- is not size or money: how long a Secret pod grows (GrowSeconds) and what a
-- carried one weighs. No screen shows it as a size word or colour.
--==============================================================================
SeedData.SecretTier = 1

-- Which secret a biome's nest may spawn, by biome id. Absent means none.
SeedData.SecretByBiome = {
	greenhollow = "snarlbloom",
	starbloom = "petalfawn",
} :: { [string]: string }

--==============================================================================
-- THE RAIN EVENT'S CREATURES -- 2026-10-02
--
-- Eight forms the owner supplied in the Podnappers Workspace folder "Rain
-- Event", replayed from RainForms part for part at the size they were
-- supplied (SecretModel). Like the Secrets they are in SeedData.Species' place
-- nowhere -- no biome pool, Index shelf, hatch-roll silhouette, wheel pool,
-- reward pool or Biome Harvest -- and reachable by id, which is all planting,
-- carrying, hatching, the Tool and the save need. Only the Rain event's own
-- nest lays their pods (NestService's event nest, stocked by WeatherService).
--
-- THE MAPPING (the supplied model -> the species id; RainForms holds the same
-- table), and the owner's fixed, final, UNBOOSTED rates:
--
--   Pod 1  "pod1"  Mythic, no size word, 3 h (10,800 s)
--          Puddlepod POD1 -> puddlepod            $80,000/s
--          Drizzlet POD1  -> drizzlet             $85,000/s
--          Lotusling POD1 -> lotusling            $90,000/s
--   Pod 2  "pod2"  Mythic, shows Colossal, 6 h (21,600 s)
--          Puddlepod POD2 -> puddlepod_colossal  $120,000/s
--          Drizzlet POD 3 -> drizzlet_colossal   $135,000/s  (labelled POD 3;
--                                                  the owner confirmed Pod 2)
--          Lotusling POD2 -> lotusling_colossal  $150,000/s
--   Pod 3  "pod3"  Divine, no size word, 9 h (32,400 s)
--          Tempestoak POD 3 -> tempestoak        $250,000/s
--          Thundermaw POD 3 -> thundermaw        $265,000/s
--          (the owner's approved pool is exactly these two, 1/2 each)
--
-- RATES FOLLOW THE CREATURE, AND THE CREATURE'S SIZE. Pod 1's three rise with
-- how much creature each one is (drawn bounding volume: Puddlepod 587,
-- Drizzlet 1,045, Lotusling 2,248 cubic studs), and Pod 2 keeps the SAME order
-- by name, so Puddlepod is the low rate in both pods and Lotusling the high
-- one. Pod 3 likewise: Tempestoak (89,600) below Thundermaw (107,600).
--
-- Pod 2's three are the SAME three creatures (Name) in their larger supplied
-- forms; their own ids only because their form, income and growth differ.
-- "Colossal" is what they SHOW (tier 7) -- nothing builds them bigger: every
-- form is replayed at scale 1 whatever the tier. Pod 1's and Pod 3's tier is
-- implementation only (Unsized): no size word, no size colour.
--
-- Income is FixedIncome, the whole answer (IncomePerSecond): no tier, rarity
-- or biome factor ever multiplies it; the pass, the chest, the sacrifice and
-- the weather apply once, in EconomyService, as they do for every plant. The
-- sale price follows from it (SellPrice), as every plant's does.
--==============================================================================
local RAIN_SOIL = Color3.fromRGB(58, 70, 86)
local function rainSpecies(id: string, name: string, rarity: string, tier: number, height: number,
	pod: string, income: number, grow: number, walkTier: number, body: Color3, crown: Color3, accent: Color3): Species
	return {
		Id = id, Name = name, Rarity = rarity, Biome = "rain",
		Height = height, Form = "secret",
		Body = body, Crown = crown, Accent = accent,
		Leaf = Color3.fromRGB(46, 104, 72), Stem = Color3.fromRGB(70, 134, 122), Soil = RAIN_SOIL,
		Animator = "secret", Carry = "overhead", WanderTier = walkTier, Pod = pod,
		Event = "rain", Unsized = tier ~= SeedData.TierCount or nil, SkipHatchRoll = true,
		FixedIncome = income, FixedGrowSeconds = grow,
		-- Pod 3 only: half speed while its pod is carried unbanked.
		CarrySpeedFactor = if pod == "rainpod3" then 0.5 else nil,
	} :: any
end

local PUDDLE = { Color3.fromRGB(74, 170, 150), Color3.fromRGB(118, 204, 176), Color3.fromRGB(232, 110, 140) }
local DRIZZLE = { Color3.fromRGB(86, 164, 230), Color3.fromRGB(242, 246, 252), Color3.fromRGB(84, 176, 92) }
local LOTUS = { Color3.fromRGB(140, 200, 130), Color3.fromRGB(250, 190, 214), Color3.fromRGB(230, 246, 220) }
local TEMPEST = { Color3.fromRGB(74, 58, 48), Color3.fromRGB(138, 112, 86), Color3.fromRGB(112, 120, 150) }
local THUNDER = { Color3.fromRGB(58, 92, 80), Color3.fromRGB(84, 92, 116), Color3.fromRGB(104, 136, 116) }

-- Heights are each form's DRAWN height in studs (RainForms Size.Y), recorded
-- like the Secrets' for the carry camera; the builder never scales by them.
SeedData.RainSpecies = {
	rainSpecies("puddlepod", "Puddlepod", "Mythic", 1, 9.99, "rainpod1", 80000, 10800, 5, PUDDLE[1], PUDDLE[2], PUDDLE[3]),
	rainSpecies("drizzlet", "Drizzlet", "Mythic", 1, 16.01, "rainpod1", 85000, 10800, 5, DRIZZLE[1], DRIZZLE[2], DRIZZLE[3]),
	rainSpecies("lotusling", "Lotusling", "Mythic", 1, 13.23, "rainpod1", 90000, 10800, 5, LOTUS[1], LOTUS[2], LOTUS[3]),
	rainSpecies("puddlepod_colossal", "Puddlepod", "Mythic", 7, 35.43, "rainpod2", 120000, 21600, 7,
		PUDDLE[1], PUDDLE[2], PUDDLE[3]),
	rainSpecies("drizzlet_colossal", "Drizzlet", "Mythic", 7, 48.15, "rainpod2", 135000, 21600, 7,
		DRIZZLE[1], DRIZZLE[2], DRIZZLE[3]),
	rainSpecies("lotusling_colossal", "Lotusling", "Mythic", 7, 30.10, "rainpod2", 150000, 21600, 7,
		LOTUS[1], LOTUS[2], LOTUS[3]),
	rainSpecies("tempestoak", "Tempestoak", "Divine", 1, 70.88, "rainpod3", 250000, 32400, 7,
		TEMPEST[1], TEMPEST[2], TEMPEST[3]),
	rainSpecies("thundermaw", "Thundermaw", "Divine", 1, 51.77, "rainpod3", 265000, 32400, 7,
		THUNDER[1], THUNDER[2], THUNDER[3]),
} :: { Species }

--==============================================================================
-- THE RAIN EVENT'S SECOND FAMILY -- 2026-10-05 (the owner's "Rain Event 2")
--
-- Four creatures the owner supplied in the Podnappers Workspace folder "Rain
-- Event 2", each ONE species at all seven sizes, built whole from its supplied
-- rig (PlantForms.Supplied: the supplied model is its Tiny, and every size is
-- that times the tier ladder, 1 .. 7.6). They come out of the same Rain nest as
-- the first family, and are in no biome pool, shelf or reward either.
--
--   supplied model                    species        rarity     $/s Tiny / Big / Huge / Mega / Giant / Titan / Colossal
--   SquallsnapLow (epic) (Tiny)    -> squallsnapper  Epic       20,000 / 23,000 / 26,000 / 30,000 / 36,000 / 43,000 / 50,000
--   Monsoad (Legendary) (tiny)     -> monsoad        Legendary  30,000 / 34,500 / 39,000 / 45,000 / 54,000 / 64,500 / 75,000
--   Thundershell (tiny)(Legendary) -> thundershell   Legendary  35,000 / 40,250 / 45,500 / 52,500 / 63,000 / 75,250 / 87,500
--   Torrentacle (tiny)(Mythic)     -> torrentacle    Mythic     60,000 / 69,000 / 78,000 / 90,000 / 108,000 / 129,000 / 150,000
--
-- (The Epic model is "SquallsnapLow" in Studio; the owner's brief and rates
-- name it Squallsnapper.)
--
-- THE RATES ARE THE OWNER'S, SIZE BY SIZE (TierIncome): an event earning
-- ladder of 1 / 1.15 / 1.3 / 1.5 / 1.8 / 2.15 / 2.5 off each Tiny. Not the size
-- multipliers, not tier.value, and no rarity or biome factor. The pass, the
-- chest, the sacrifice and the weather apply once, in EconomyService, and the
-- sale price is SellSeconds of the rate (SellPrice), as for every plant.
--
-- THEIR PODS are the owner's seven supplied shells, one per size and each
-- already at that size (PodForms; RainForms.Pods). A shell shows its size and
-- nothing of the creature or its rarity.
--
-- GROWTH, the owner's choice (2026-10-05): 3 h Tiny .. Titan, 6 h Colossal --
-- the first family's times.
--==============================================================================
local RAIN2_GROW = { 10800, 10800, 10800, 10800, 10800, 10800, 21600 }
local RAIN2_PODS = {
	"rain2pod_tiny", "rain2pod_big", "rain2pod_huge", "rain2pod_mega",
	"rain2pod_giant", "rain2pod_titan", "rain2pod_colossal",
}
local function rain2Species(id: string, name: string, rarity: string, height: number, income: { number },
	body: Color3, crown: Color3, accent: Color3): Species
	return {
		Id = id, Name = name, Rarity = rarity, Biome = "rain",
		Height = height, Form = "secret",
		Body = body, Crown = crown, Accent = accent,
		Leaf = Color3.fromRGB(46, 104, 72), Stem = Color3.fromRGB(70, 134, 122), Soil = RAIN_SOIL,
		Animator = "secret", Carry = "overhead", Pod = "rainpod4",
		Event = "rain", SkipHatchRoll = true,
		TierIncome = income, TierGrowSeconds = RAIN2_GROW, PodForms = RAIN2_PODS,
	} :: any
end

-- Heights: each supplied model's DRAWN height in studs (its Tiny; PlantForms
-- Size.Y). The colours are its own body, crown and accent parts'.
for _, species in ipairs({
	rain2Species("squallsnapper", "Squallsnapper", "Epic", 4.94,
		{ 20000, 23000, 26000, 30000, 36000, 43000, 50000 },
		Color3.fromRGB(70, 118, 172), Color3.fromRGB(172, 186, 212), Color3.fromRGB(255, 226, 80)),
	rain2Species("monsoad", "Monsoad", "Legendary", 4.99,
		{ 30000, 34500, 39000, 45000, 54000, 64500, 75000 },
		Color3.fromRGB(92, 66, 150), Color3.fromRGB(116, 194, 72), Color3.fromRGB(255, 146, 66)),
	rain2Species("thundershell", "Thundershell", "Legendary", 4.97,
		{ 35000, 40250, 45500, 52500, 63000, 75250, 87500 },
		Color3.fromRGB(66, 134, 80), Color3.fromRGB(66, 56, 128), Color3.fromRGB(255, 232, 110)),
	rain2Species("torrentacle", "Torrentacle", "Mythic", 4.47,
		{ 60000, 69000, 78000, 90000, 108000, 129000, 150000 },
		Color3.fromRGB(78, 90, 118), Color3.fromRGB(150, 164, 190), Color3.fromRGB(255, 108, 98)),
}) do
	table.insert(SeedData.RainSpecies, species)
end

--==============================================================================
-- THE THREE RAIN PODS: what each holds, and how a nest is stocked with them
--
-- A pod's creature is drawn ON THE SERVER, once, when the pod is laid in the
-- event nest (RollRainPod): every creature in its roster equally likely. From
-- then on it is simply that pod's species id, carried, dropped, retaken,
-- banked, planted and saved like every pod's -- nothing draws again, and the
-- shell shows only which pod it is (PlantInfo), never which creature.
--
-- `Tier` is what its items carry: 7 for Pod 2, which SHOWS Colossal; 1 for the
-- unsized two (never shown). `Sized` says whether the size word shows.
--
-- AND THE SECOND FAMILY'S TWO (2026-10-05). Its four creatures come in two
-- pods: rainpod4 draws its size, Tiny .. Titan, on the global ladder's own
-- relative weights (Tiers); rainpod5 is the same family at Colossal (Family).
-- They are two slots in the batch so that whether a slot is Colossal is the
-- BATCH's call alone, made once -- never a second Colossal roll inside a pod.
-- Their creatures differ in rarity, so neither shell names one (no Rarity: it
-- reads ??? until the hatch, like an ordinary pod), and they come up 40 / 25 /
-- 25 / 10 (Weights), the owner's odds.
--==============================================================================
export type RainPod = {
	Id: string,
	Name: string,
	-- Every creature's rarity, shown on the shell; absent for a pod whose
	-- creatures differ in rarity, where it would name what is inside.
	Rarity: string?,
	-- The one tier its items carry; absent for a pod that draws its size.
	Tier: number?,
	-- A pod that draws its size: relative weights, Tiny first. Never Colossal.
	Tiers: { number }?,
	Sized: boolean,
	GrowSeconds: number,
	Species: { string },
	-- Relative odds of its creatures, in Species order; absent: each equally.
	Weights: { number }?,
	-- The pod whose creatures this one holds at Colossal (rainpod5 -> rainpod4).
	Family: string?,
}

-- The second family's sizes below Colossal, weighted exactly as the global
-- ladder weighs them (the owner's choice: those weights, normalised over Tiny ..
-- Titan -- Tiny 53.5%, Big 16.0%, Huge 10.1%, Mega 7.9%, Giant 6.0%, Titan 6.5%).
local RAIN2_TIERS: { number } = {}
for i = 1, SeedData.TierCount - 1 do
	RAIN2_TIERS[i] = SeedData.Tiers[i].weight
end
local RAIN2_ROSTER = { "squallsnapper", "monsoad", "thundershell", "torrentacle" }
-- Epic, Legendary, Legendary, Mythic: the owner's 40 / 25 / 25 / 10.
local RAIN2_ODDS = { 40, 25, 25, 10 }

SeedData.RainPods = {
	rainpod1 = { Id = "rainpod1", Name = "Rain pod", Rarity = "Mythic", Tier = 1, Sized = false,
		GrowSeconds = 10800, Species = { "puddlepod", "drizzlet", "lotusling" } },
	rainpod2 = { Id = "rainpod2", Name = "Rain pod", Rarity = "Mythic", Tier = 7, Sized = true,
		GrowSeconds = 21600, Species = { "puddlepod_colossal", "drizzlet_colossal", "lotusling_colossal" } },
	rainpod3 = { Id = "rainpod3", Name = "Thunderstorm pod", Rarity = "Divine", Tier = 1, Sized = false,
		GrowSeconds = 32400, Species = { "tempestoak", "thundermaw" } },
	rainpod4 = { Id = "rainpod4", Name = "Rain pod", Tiers = RAIN2_TIERS, Sized = true,
		GrowSeconds = 10800, Species = RAIN2_ROSTER, Weights = RAIN2_ODDS },
	rainpod5 = { Id = "rainpod5", Name = "Rain pod", Tier = SeedData.TierCount, Sized = true, Family = "rainpod4",
		GrowSeconds = 21600, Species = RAIN2_ROSTER, Weights = RAIN2_ODDS },
} :: { [string]: RainPod }

--==============================================================================
-- ONE BATCH PER EVENT (the owner's rule): an ordinary Rain lays exactly three
-- pods -- one Colossal draw for the whole batch, then each ordinary slot drawn
-- on its own; a Thunderstorm lays exactly one Pod 3.
-- Nothing ever restocks it -- not a theft, a banking, a catch, a pickup, a
-- rebuilt guardian or a second START. Rolled once, on the server, when the
-- event's nest is laid (NestService.OpenEventNest), for the console's weather
-- and the automatic weather alike.
--
-- THE WEIGHTS (2026-10-06, the owner's odds): EXACTLY 5% PER RAIN. A Rain
-- makes ONE Colossal draw, 5 in 100 (ColossalChance). A hit makes exactly one
-- of its three slots -- picked at random -- a Colossal pod (ColossalWeights:
-- the old family's Pod 2 or the new family's Colossal, 50/50) and the other
-- two ordinary; a miss makes all three ordinary. An ordinary slot is Pod 1 or
-- the new family's Tiny .. Titan pod, 50/50, each drawn on its own (Weights).
-- So at most one Colossal a Rain: at least one in 5% of Rains, 0.05 a batch
-- on average; two or three in one Rain never happen. The draw and the slot
-- pick come from the batch roll's own server RNG (RollRainBatch, called by
-- NestService.OpenEventNest for the console's weather and the automatic
-- weather alike). A pod already laid or saved keeps what it was laid as.
--
-- HISTORY. 2026-10-05: each slot drawn on its own, ordinary 90 in 100 and
-- Colossal 10 -- a Rain with at least one Colossal 27.1% of the time (it had
-- been a coin flip a slot, 87.5%), 0.3 a batch, all three 0.1%. The same day
-- the second family split both halves evenly: Pod 1 45 / Pod 2 5 / rainpod4
-- 45 / rainpod5 5.
--
-- Relative weights, any positive total; a weight of 0 never draws. A batch
-- without ColossalWeights (the Thunderstorm's) makes no Colossal draw at all.
-- Checked when this loads (ValidRainBatch): ColossalChance in [0, 1], every
-- pod named exists, a Colossal pod never among the ordinary Weights and only
-- Colossal pods among the ColossalWeights.
--==============================================================================
export type RainBatch = {
	Slots: number,
	Weights: { [string]: number },
	-- The batch's one Colossal draw: this chance, and the Colossal pods the hit
	-- slot draws from. Both absent: no Colossal draw.
	ColossalChance: number?,
	ColossalWeights: { [string]: number }?,
}

SeedData.RainBatches = {
	rain = {
		Slots = 3,
		ColossalChance = 0.05,
		Weights = { rainpod1 = 1, rainpod4 = 1 },
		ColossalWeights = { rainpod2 = 1, rainpod5 = 1 },
	},
	thunder = { Slots = 1, Weights = { rainpod3 = 1 } },
} :: { [string]: RainBatch }

--==============================================================================
-- THE INVITE A FRIEND REWARDS -- 2026-10-06
--
-- Four forms the owner supplied in the Podnappers Workspace, replayed from
-- InviteForms part for part at the size they were supplied (SecretModel). A
-- player is GIVEN one -- grown, ready to place -- when their count of friends
-- who joined through their invites reaches its threshold (InviteService;
-- GameConfig.InviteRewards holds the thresholds, 1 / 5 / 10 / 20). Like the
-- Secrets they are in SeedData.Species' place nowhere -- no biome pool, Index
-- shelf, hatch-roll silhouette, wheel pool, reward pool, Rain nest or Biome
-- Harvest -- and reachable by id, which is all planting, carrying, the Tool
-- and the save need.
--
-- THE OWNER'S NUMBERS (2026-10-06), fixed, final and UNBOOSTED:
--
--     invites  species      rarity      $/s
--     1        Dustthorn    Epic          5,000
--     5        Thornbrute   Legendary    25,000
--     10       Pharaothorn  Mythic       75,000
--     20       Heliothorn   Secret      175,000
--
-- Income is FixedIncome, the whole answer (IncomePerSecond): no tier, rarity
-- or biome factor ever multiplies it; the pass, the chest, the sacrifice and
-- the weather apply once, in EconomyService, as they do for every plant.
--
-- UNSELLABLE (the owner's rule): earned by inviting friends and never earned
-- again, so no stall buys one -- SELL ONE refuses it, SELL ALL leaves it in
-- the bag, and no screen prices it (SeedData.Sellable).
--
-- ONE SIZE, NO SIZE WORD (Unsized): its tier is implementation only, like a
-- Secret's (SeedData.InviteTier). WALKS on the rung its height matches (a
-- typical Tiny is 3.7-8.9 studs tall, x1.38 .. x7.6 up the ladder): Dustthorn
-- 4.06 Tiny, Thornbrute 9.26 Huge, Pharaothorn 15.20 Mega, Heliothorn 26.57
-- Titan. Carried overhead like the Secrets. Biome: Dustbowl, whose sand and
-- sun their art wears; it decides nothing else here.
--==============================================================================
SeedData.InviteSpecies = {
	{
		Id = "dustthorn", Name = "Dustthorn", Rarity = "Epic", Biome = "dustbowl",
		Height = 4.06, Form = "secret",
		Body = Color3.fromRGB(122, 150, 88),
		Crown = Color3.fromRGB(222, 140, 80),
		Accent = Color3.fromRGB(222, 196, 140),
		Leaf = DUST_LEAF, Stem = DUST_STEM, Soil = SOIL,
		Animator = "secret", Carry = "overhead", WanderTier = 1,
		Invite = true, Unsellable = true, Unsized = true,
		FixedIncome = 5000,
	},
	{
		Id = "thornbrute", Name = "Thornbrute", Rarity = "Legendary", Biome = "dustbowl",
		Height = 9.26, Form = "secret",
		Body = Color3.fromRGB(118, 148, 86),
		Crown = Color3.fromRGB(212, 140, 150),
		Accent = Color3.fromRGB(226, 200, 144),
		Leaf = DUST_LEAF, Stem = DUST_STEM, Soil = SOIL,
		Animator = "secret", Carry = "overhead", WanderTier = 3,
		Invite = true, Unsellable = true, Unsized = true,
		FixedIncome = 25000,
	},
	{
		Id = "pharaothorn", Name = "Pharaothorn", Rarity = "Mythic", Biome = "dustbowl",
		Height = 15.2, Form = "secret",
		Body = Color3.fromRGB(110, 150, 92),
		Crown = Color3.fromRGB(44, 92, 176),
		Accent = Color3.fromRGB(226, 200, 148),
		Leaf = DUST_LEAF, Stem = DUST_STEM, Soil = SOIL,
		Animator = "secret", Carry = "overhead", WanderTier = 4,
		Invite = true, Unsellable = true, Unsized = true,
		FixedIncome = 75000,
	},
	{
		Id = "heliothorn", Name = "Heliothorn", Rarity = "Secret", Biome = "dustbowl",
		Height = 26.57, Form = "secret",
		Body = Color3.fromRGB(122, 150, 84),
		Crown = Color3.fromRGB(255, 214, 92),
		Accent = Color3.fromRGB(196, 48, 40),
		Leaf = DUST_LEAF, Stem = DUST_STEM, Soil = SOIL,
		Animator = "secret", Carry = "overhead", WanderTier = 6,
		Invite = true, Unsellable = true, Unsized = true,
		FixedIncome = 175000,
	},
} :: { Species }

-- IMPLEMENTATION ONLY, like SecretTier: the one tier every invite reward
-- carries on its Tool, saved row and planted entry. No screen shows it.
SeedData.InviteTier = 1

local byId: { [string]: Species } = {}
local byBiome: { [string]: { Species } } = {}

-- The same checks for a listed species and a secret one; only a listed species
-- joins its biome's pool.
local function register(species: Species, listed: boolean)
	assert(byId[species.Id] == nil, "duplicate species id: " .. species.Id)
	assert(GameConfig.RarityTier[species.Rarity] ~= nil,
		string.format("species %q has unknown rarity %q", species.Id, species.Rarity))
	assert(SeedData.RarityWeight[species.Rarity] ~= nil,
		string.format("rarity %q has no drop weight", species.Rarity))
	-- Income has two more tables to stay in step with. Refusing the file here
	-- is the whole reason IncomePerSecond can fall back to 1.00x quietly: the
	-- fallback is for a legacy save, and this is what stops it ever covering
	-- for a species we actually ship.
	assert(SeedData.RarityMultiplier[species.Rarity] ~= nil,
		string.format("rarity %q has no income multiplier", species.Rarity))
	assert(SeedData.BiomeMultiplier[species.Biome] ~= nil,
		string.format("species %q sits in biome %q, which has no income multiplier",
			species.Id, species.Biome))
	--======================================================================
	-- A BONUS IS A WHOLE NUMBER OF DOLLARS, OR THE FILE DOES NOT LOAD
	--
	-- It is added to a figure the client and the server both round to a whole
	-- number and then print. A fraction would show up as two different readouts
	-- of the same plant; a negative would make a species pay less than its own
	-- rarity says; a NaN would poison every sum the garden panel adds it into.
	--======================================================================
	-- A fixed income is paid as it stands, so it is checked the same way a
	-- bonus is: whole, finite, and here more than nothing.
	local fixedIncome = (species :: any).FixedIncome
	if fixedIncome ~= nil then
		assert(type(fixedIncome) == "number" and fixedIncome == fixedIncome and fixedIncome ~= math.huge
				and fixedIncome > 0 and math.floor(fixedIncome) == fixedIncome,
			string.format("species %q has a FixedIncome of %s: it must be a whole, finite, positive number of "
				.. "dollars per second", species.Id, tostring(fixedIncome)))
	end
	-- A fixed growth time is a whole, positive number of seconds; a carry speed
	-- factor a share of the carrier's speed, more than nothing and at most all.
	local grow = (species :: any).FixedGrowSeconds
	if grow ~= nil then
		assert(type(grow) == "number" and grow == grow and grow ~= math.huge and grow > 0 and math.floor(grow) == grow,
			string.format("species %q has a FixedGrowSeconds of %s: it must be a whole, positive number of seconds",
				species.Id, tostring(grow)))
	end
	-- The second family's per-size numbers (2026-10-05): one whole, finite,
	-- positive rate and growth time for EVERY size, and a pod shell named for
	-- every size, no two alike -- a short list or a repeated shell would build
	-- some size at another size's pod. Never alongside the one-number flags
	-- they replace, so no species can answer two ways.
	local function wholeLadder(list: any): boolean
		if type(list) ~= "table" or #list ~= SeedData.TierCount then
			return false
		end
		for i = 1, SeedData.TierCount do
			local x = list[i]
			if not (type(x) == "number" and x == x and x ~= math.huge and x > 0 and math.floor(x) == x) then
				return false
			end
		end
		return true
	end
	local tierIncome = (species :: any).TierIncome
	if tierIncome ~= nil then
		assert(wholeLadder(tierIncome) and fixedIncome == nil and (species :: any).IncomeBonus == nil,
			string.format("species %q has a bad TierIncome: one whole, finite, positive $/s per size (%d), and never "
				.. "with FixedIncome or IncomeBonus", species.Id, SeedData.TierCount))
	end
	local tierGrow = (species :: any).TierGrowSeconds
	if tierGrow ~= nil then
		assert(wholeLadder(tierGrow) and grow == nil,
			string.format("species %q has a bad TierGrowSeconds: one whole, positive time per size (%d), and never "
				.. "with FixedGrowSeconds", species.Id, SeedData.TierCount))
	end
	local podForms = (species :: any).PodForms
	if podForms ~= nil then
		local seen = {}
		local good = type(podForms) == "table" and #podForms == SeedData.TierCount
		if good then
			for i = 1, SeedData.TierCount do
				local form = podForms[i]
				good = good and type(form) == "string" and form ~= "" and not seen[form]
				if type(form) == "string" then
					seen[form] = true
				end
			end
		end
		assert(good, string.format("species %q has bad PodForms: one distinct shell per size (%d)", species.Id,
			SeedData.TierCount))
	end
	local carryFactor = (species :: any).CarrySpeedFactor
	if carryFactor ~= nil then
		assert(type(carryFactor) == "number" and carryFactor > 0 and carryFactor <= 1,
			string.format("species %q has a CarrySpeedFactor of %s: it must be in (0, 1]", species.Id,
				tostring(carryFactor)))
	end
	local walkTier = (species :: any).WanderTier
	if walkTier ~= nil then
		assert(type(walkTier) == "number" and walkTier >= 1 and walkTier <= SeedData.TierCount
				and math.floor(walkTier) == walkTier,
			string.format("species %q has a WanderTier of %s: it must name a rung of the walk ladder", species.Id,
				tostring(walkTier)))
	end
	local bonus = (species :: any).IncomeBonus
	if bonus ~= nil then
		assert(type(bonus) == "number" and bonus == bonus and bonus ~= math.huge
				and bonus >= 0 and math.floor(bonus) == bonus,
			string.format("species %q has an IncomeBonus of %s: it must be a whole, "
				.. "finite, non-negative number of dollars per second",
				species.Id, tostring(bonus)))
	end
	byId[species.Id] = species
	if not listed then
		return
	end
	local list = byBiome[species.Biome]
	if not list then
		list = {}
		byBiome[species.Biome] = list
	end
	table.insert(list, species)
end

for _, species in ipairs(SeedData.Species) do
	register(species, true)
end
for _, species in ipairs(SeedData.SecretSpecies) do
	assert(species.Secret == true, "a secret species must say so: " .. species.Id)
	register(species, false)
end
for biomeId, speciesId in pairs(SeedData.SecretByBiome) do
	local species = byId[speciesId]
	assert(species and species.Secret and species.Biome == biomeId,
		string.format("SecretByBiome.%s names %q, which is not that biome's secret", biomeId, speciesId))
end
-- The Rain event's twelve: unlisted, like the Secrets, and every one in its
-- pod's roster at that pod's tier (or tiers), rarity and growth time. The
-- first family's eight each sit in exactly one pod; the second family's four
-- sit in rainpod4 and in rainpod5, its Colossal pod.
for _, species in ipairs(SeedData.RainSpecies) do
	assert(species.Event == "rain" and species.Secret ~= true, "a rain species is an event species: " .. species.Id)
	register(species, false)
end
-- The Invite a Friend rewards' four (2026-10-06): unlisted, like the Secrets;
-- each an invite reward that no stall buys, one size, a fixed rate, and built
-- from its own supplied form -- never a Secret's flags or an event's.
for _, species in ipairs(SeedData.InviteSpecies) do
	local s = species :: any
	assert(s.Invite == true and s.Unsellable == true and s.Unsized == true and s.Secret ~= true and s.Event == nil
			and type(s.FixedIncome) == "number" and s.Carry == "overhead",
		"an invite reward is unlisted, unsellable, unsized, fixed-rate and carried overhead: " .. species.Id)
	register(species, false)
end
-- Relative weights: finite, none below 0, some above; exactly `n` when given.
local function goodWeights(list: any, n: number?): boolean
	if type(list) ~= "table" or #list == 0 or (n ~= nil and #list ~= n) then
		return false
	end
	local total = 0
	for _, w in ipairs(list) do
		if type(w) ~= "number" or w ~= w or w < 0 or w == math.huge then
			return false
		end
		total += w
	end
	return total > 0
end
local inRoster: { [string]: boolean } = {}
for podId, pod in pairs(SeedData.RainPods) do
	assert(pod.Id == podId and #pod.Species >= 1, "RainPods." .. podId .. " is malformed")
	-- One size, or sizes to draw from -- never both, never neither.
	assert((pod.Tier ~= nil) ~= (pod.Tiers ~= nil), "RainPods." .. podId .. ": one Tier, or Tiers to draw, not both")
	local lays: { number } = {}
	if pod.Tier ~= nil then
		assert(pod.Sized == (pod.Tier == SeedData.TierCount), "RainPods." .. podId .. ": only a Colossal pod is sized")
		lays = { pod.Tier :: number }
	else
		-- A pod that draws its size shows it, and never draws Colossal: whether a
		-- slot is Colossal is the batch's call alone, made once.
		local tiers = pod.Tiers :: { number }
		assert(pod.Sized == true and goodWeights(tiers) and #tiers < SeedData.TierCount,
			"RainPods." .. podId .. ": a pod that draws its size shows it, and draws only below Colossal")
		for t, w in ipairs(tiers) do
			if w > 0 then
				table.insert(lays, t)
			end
		end
	end
	if pod.Weights ~= nil then
		assert(goodWeights(pod.Weights, #pod.Species), "RainPods." .. podId .. ": one odds weight per creature")
	end
	-- A family's Colossal pod: its family's creatures, odds, name and rarity, at Colossal.
	local home = pod.Family or podId
	if pod.Family ~= nil then
		local base = SeedData.RainPods[pod.Family]
		assert(base ~= nil and base.Family == nil and base.Name == pod.Name and base.Rarity == pod.Rarity
				and pod.Tier == SeedData.TierCount
				and table.concat(base.Species, ",") == table.concat(pod.Species, ",")
				and table.concat(base.Weights or {}, ",") == table.concat(pod.Weights or {}, ","),
			"RainPods." .. podId .. ": a family's Colossal pod holds that family's creatures, at Colossal")
	end
	local rarities, kinds = {}, 0
	for _, speciesId in ipairs(pod.Species) do
		local species = byId[speciesId] :: any
		-- Its growth at every size this pod lays is the pod's.
		local growOk = species ~= nil
		if species then
			for _, t in ipairs(lays) do
				local grows = if species.TierGrowSeconds then species.TierGrowSeconds[t] else species.FixedGrowSeconds
				growOk = growOk and grows == pod.GrowSeconds
			end
		end
		assert(species and species.Event == "rain" and species.Pod == home
				and (pod.Rarity == nil or species.Rarity == pod.Rarity)
				and (species.Unsized == true) == not pod.Sized and growOk,
			string.format("RainPods.%s lists %q, which is not one of its creatures", podId, speciesId))
		inRoster[speciesId] = true
		if not rarities[species.Rarity] then
			rarities[species.Rarity] = true
			kinds += 1
		end
	end
	-- No rarity on the shell only where there is no single one to show.
	assert(pod.Rarity ~= nil or kinds > 1, "RainPods." .. podId .. ": a pod whose creatures share one rarity shows it")
end
for _, species in ipairs(SeedData.RainSpecies) do
	assert(inRoster[species.Id], "the rain species " .. species.Id .. " is in no pod's roster")
end
-- A batch's pod weights: each names a Rain pod with a finite weight of 0 or
-- more, and at least one is above 0. Answers why not, for the assert and the spec.
function SeedData.ValidRainWeights(weights: any): (boolean, string?)
	if type(weights) ~= "table" then
		return false, "no weights"
	end
	local total = 0
	for podId, weight in pairs(weights) do
		if type(podId) ~= "string" or not SeedData.RainPods[podId] then
			return false, string.format("an unknown pod %q", tostring(podId))
		end
		if type(weight) ~= "number" or weight ~= weight or weight < 0 or weight == math.huge then
			return false, string.format("%s has a bad weight %s", podId, tostring(weight))
		end
		total += weight
	end
	if total <= 0 then
		return false, "no pod has any weight"
	end
	return true, nil
end

-- A pod always laid at the Colossal size.
local function colossalPod(podId: string): boolean
	local pod = SeedData.RainPods[podId]
	return pod ~= nil and pod.Tier == SeedData.TierCount
end

-- A whole batch (2026-10-06): its slots, its ordinary Weights -- no Colossal
-- pod among them -- and, where it has one, its Colossal draw: a ColossalChance
-- in [0, 1] and ColossalWeights naming only Colossal pods (a chance above 0
-- needs them; the Thunderstorm has neither). Every pod named exists. Answers
-- why not, for the assert and the spec.
function SeedData.ValidRainBatch(batch: any): (boolean, string?)
	if type(batch) ~= "table" then
		return false, "no batch"
	end
	if type(batch.Slots) ~= "number" or batch.Slots < 1 or batch.Slots ~= math.floor(batch.Slots) then
		return false, "no slots"
	end
	local ok, why = SeedData.ValidRainWeights(batch.Weights)
	if not ok then
		return false, "Weights: " .. tostring(why)
	end
	for podId in pairs(batch.Weights) do
		if colossalPod(podId) then
			return false, string.format("the Colossal pod %s is among the ordinary Weights", podId)
		end
	end
	local chance = batch.ColossalChance
	if chance ~= nil and (type(chance) ~= "number" or chance ~= chance or chance < 0 or chance > 1) then
		return false, string.format("ColossalChance %s is not in [0, 1]", tostring(chance))
	end
	local colossal = batch.ColossalWeights
	if colossal ~= nil then
		local cok, cwhy = SeedData.ValidRainWeights(colossal)
		if not cok then
			return false, "ColossalWeights: " .. tostring(cwhy)
		end
		for podId in pairs(colossal) do
			if not colossalPod(podId) then
				return false, string.format("%s among the ColossalWeights is not a Colossal pod", podId)
			end
		end
	elseif chance ~= nil and chance > 0 then
		return false, "a ColossalChance with no ColossalWeights"
	end
	return true, nil
end

for mode, batch in pairs(SeedData.RainBatches) do
	local ok, why = SeedData.ValidRainBatch(batch)
	assert(ok, string.format("RainBatches.%s: %s", mode, tostring(why)))
end

SeedData.ById = byId
SeedData.ByBiome = byBiome

function SeedData.Get(id: string): Species?
	return byId[id]
end

--==============================================================================
-- THE RAIN PODS' DRAWS (server). `rng` is the caller's Random; a spec passes a
-- seeded one, the event nest the server's own.
--==============================================================================
-- The pod a species hatches from, or nil for every species that is not the
-- Rain event's.
function SeedData.RainPodOf(species: Species?): RainPod?
	local podId = if type(species) == "table" and (species :: any).Event == "rain" then (species :: any).Pod else nil
	return if type(podId) == "string" then SeedData.RainPods[podId] else nil
end

-- The index a draw `r` in [0, 1) lands on in a list of relative weights, laid
-- end to end in order; a weight of 0 is never drawn. Pure, like PickRainPod.
function SeedData.PickWeighted(weights: { number }, r: number): number
	local total = 0
	for _, w in ipairs(weights) do
		total += w
	end
	local at = math.clamp(r, 0, 1) * total
	local acc, last = 0, 1
	for i, w in ipairs(weights) do
		if w > 0 then
			acc += w
			last = i
			if at < acc then
				return i
			end
		end
	end
	-- r at (or rounding to) 1: the last entry that can be drawn.
	return last
end

-- The creature a newly laid pod holds: one of its roster, each equally likely
-- -- or, for a pod with Weights (the second family), at those odds.
function SeedData.RollRainPod(podId: string, rng: Random): Species
	local pod = SeedData.RainPods[podId]
	assert(pod, "RollRainPod: unknown pod " .. tostring(podId))
	if pod.Weights then
		return byId[pod.Species[SeedData.PickWeighted(pod.Weights, rng:NextNumber())]]
	end
	return byId[pod.Species[rng:NextInteger(1, #pod.Species)]]
end

-- The size a newly laid pod is: its one Tier, or (rainpod4) a draw from its
-- Tiers, Tiny .. Titan. Drawn once, here, and from then on carried on the
-- item like every pod's tier -- nothing draws it again.
function SeedData.RollRainTier(podId: string, rng: Random): number
	local pod = SeedData.RainPods[podId]
	assert(pod, "RollRainTier: unknown pod " .. tostring(podId))
	if pod.Tiers then
		return SeedData.PickWeighted(pod.Tiers, rng:NextNumber())
	end
	return pod.Tier :: number
end

-- The pod a draw `r` in [0, 1) lands on: the weights laid end to end in pod
-- id order, so the same draw always gives the same pod (a Rain's ordinary
-- slot: below 0.5 Pod 1, rainpod4 from 0.5; its Colossal slot: below 0.5 Pod
-- 2, rainpod5 from 0.5). A pod weighted 0 is never drawn. Pure.
function SeedData.PickRainPod(weights: { [string]: number }, r: number): string
	local ids: { string } = {}
	local total = 0
	for podId, weight in pairs(weights) do
		table.insert(ids, podId)
		total += weight
	end
	table.sort(ids)
	local at = math.clamp(r, 0, 1) * total
	local acc = 0
	local last = ids[1]
	for _, podId in ipairs(ids) do
		local weight = weights[podId]
		if weight > 0 then
			acc += weight
			last = podId
			if at < acc then
				return podId
			end
		end
	end
	-- r at (or rounding to) 1: the last pod that can be drawn.
	return last
end

-- One event's whole batch, slot by slot: { pod id, species, tier }. First the
-- batch's ONE Colossal draw, where it has one (2026-10-06): a hit picks one
-- slot at random to draw its pod from the ColossalWeights; every other slot
-- draws its pod on its own from the Weights. Then each slot's creature and --
-- for the one pod that draws its size -- its size. Every draw is `rng`'s, the
-- caller's (the server's own, at the nest); a batch with no Colossal draw (the
-- Thunderstorm's) takes exactly the draws it always did.
function SeedData.RollRainBatch(mode: string, rng: Random): { { pod: string, species: Species, tier: number } }
	local batch = SeedData.RainBatches[mode]
	assert(batch, "RollRainBatch: unknown mode " .. tostring(mode))
	local chance, colossal = batch.ColossalChance, batch.ColossalWeights
	local colossalSlot = 0
	if colossal and chance and chance > 0 and rng:NextNumber() < chance then
		colossalSlot = rng:NextInteger(1, batch.Slots)
	end
	local out = {}
	for slot = 1, batch.Slots do
		local weights = if slot == colossalSlot and colossal then colossal else batch.Weights
		local podId = SeedData.PickRainPod(weights, rng:NextNumber())
		local species = SeedData.RollRainPod(podId, rng)
		table.insert(out, { pod = podId, species = species, tier = SeedData.RollRainTier(podId, rng) })
	end
	return out
end

-- True for anything that shows NO size word or size colour: a Secret, and the
-- Rain event's Pod 1 and Pod 3 forms. Their tier is implementation only.
function SeedData.Unsized(species: Species?): boolean
	return type(species) == "table" and ((species :: any).Secret == true or (species :: any).Unsized == true)
end

-- The replayed shell for this species' pod at this size: the size's own
-- supplied pod (PodForms, the second family's seven, each already at its size)
-- or the species' one Pod form; nil for every species with no replayed pod.
-- What CreatureModel builds, PlantService turns to face the gate and the carry
-- camera sizes -- one answer, so the three can never disagree.
function SeedData.PodFormOf(species: Species?, tier: number?): string?
	if type(species) ~= "table" then
		return nil
	end
	local forms = (species :: any).PodForms
	if type(forms) == "table" then
		return forms[SeedData.Tier(tier).index]
	end
	local pod = (species :: any).Pod
	return if type(pod) == "string" then pod else nil
end

function SeedData.InBiome(biomeId: string): { Species }
	return byBiome[biomeId] or {}
end

--==============================================================================
-- WHAT IT IS WORTH, AND WHAT IT COSTS
--
-- ONE CALCULATION, AND EVERY CALLER USES IT. EconomyService pays from this, the
-- garden panel and the world pop display it, the hatch reveal prints it, and the
-- stall prices from it. A second copy anywhere is a readout that can disagree
-- with the payout, and the player believes the readout.
--
-- THE SPECIES IS THE ARGUMENT NOW, not the tier alone. Rarity and biome both
-- come off it and neither can be recovered from a number -- and every caller
-- already had a species in hand, so nothing needed new plumbing to find one.
--
-- THREE THINGS DECIDE IT, NOT TWO: the size tier, the species' rarity, the depth
-- of its biome -- and then a flat per-species bonus, added after the rounding,
-- which is what stops two plants of the same rarity in the same biome being
-- worth the identical number. See IncomeBonus on the Species type.
--
-- AN UNKNOWN SPECIES PAYS THE BASE RATE. Not zero, which would stop a plant
-- that is visibly standing in the ground from paying and look like the tick had
-- died; and not an invented multiplier either. Anything the tables do not know
-- is worth exactly 1.00x. The require-time asserts are what stop that fallback
-- ever being reached by a species this file ships -- it exists for a legacy
-- save, not for a typo.
--
-- HALF-UP, AND SPELLED OUT. floor(x + 0.5) rather than a rounding helper,
-- because the client and the server must land on the same whole number every
-- time: the pop over the plant and the cash in the profile are the same figure
-- or the game looks broken.
--==============================================================================
local function factorsFor(species: Species?): (number, number)
	-- A `type` test rather than a truth test: a legacy caller that still passes
	-- the tier as the first argument arrives here as a NUMBER, and indexing a
	-- number would throw inside the pay loop rather than fall back.
	if type(species) ~= "table" then
		return 1, 1
	end
	local rarity = SeedData.RarityMultiplier[(species :: Species).Rarity]
	local biome = SeedData.BiomeMultiplier[(species :: Species).Biome]
	return rarity or 1, biome or 1
end

-- Whatever this species adds on top, flat, or zero. Guarded the same way
-- factorsFor is: a legacy caller passing a tier number must land on 0 rather
-- than throw inside the pay loop.
local function bonusFor(species: Species?): number
	if type(species) ~= "table" then
		return 0
	end
	local bonus = (species :: any).IncomeBonus
	if type(bonus) ~= "number" or bonus ~= bonus or bonus < 0 or bonus == math.huge then
		return 0
	end
	return math.floor(bonus)
end

function SeedData.IncomePerSecond(species: Species?, tier: number?): number
	-- A FIXED rate is the whole answer (the Secrets, 2026-10-02): the owner's
	-- final unboosted $/s, never multiplied again by a tier, rarity or biome
	-- factor. Validated at load: a whole, positive number.
	if type(species) == "table" then
		-- And so is the owner's rate for THIS size, for a species that has one
		-- per size (the Rain event's second family, 2026-10-05). Validated at
		-- load: seven whole, positive numbers.
		local bySize = (species :: Species).TierIncome
		if type(bySize) == "table" then
			return bySize[SeedData.Tier(tier).index]
		end
		local fixed = (species :: Species).FixedIncome
		if type(fixed) == "number" then
			return fixed
		end
	end
	local base = SeedData.Tier(tier).value * GameConfig.Carry.CashPerValue
	local rarity, biome = factorsFor(species)
	-- AFTER the rounding, and multiplied by nothing: the bonus is the same dollar
	-- at Tiny and at Colossal. The x2 Earn pass doubles the total later, in the
	-- economy, and never here.
	return math.floor(base * rarity * biome + 0.5) + bonusFor(species)
end

function SeedData.CarryMultiplier(tier: number?): number
	return GameConfig.carryMultiplierFor(SeedData.Tier(tier).value)
end

--==============================================================================
-- GROWING: SEVEN NUMBERS THE OWNER WROTE DOWN, NOT A CURVE
--
-- The owner approved this ladder on 2026-09-17, and it IS the timer. It used to
-- be a curve off the tier's value -- 20 + 280 * (value / topValue) ^ 0.45, which
-- ran 34 s to 300 s -- and a curve is the wrong shape for this: it is impossible
-- to say out loud, it moves every tier whenever the value sheet is re-cut, and
-- the whole range fit inside five minutes, so a Colossal cost no more patience
-- than a Big.
--
--     1 Tiny          30 s
--     2 Big           60 s          1m
--     3 Huge         150 s          2m 30s
--     4 Mega         360 s          6m
--     5 Giant        900 s         15m
--     6 Titan      2,100 s         35m
--     7 Colossal   4,500 s      1h 15m
--
-- ABSOLUTE TIME, NOT A COUNTDOWN. PlantService turns this into a per-pod
-- deadline once, when the pod goes in the ground, and saves that deadline; see
-- HatchAt there. So growth continues while the player is offline, and re-cutting
-- this ladder never moves a pod that is already planted.
--
-- ONE SOURCE. The server plants with this; the client draws the deadline the
-- server stamped on the model and never re-derives it from here. Nothing else in
-- the repository writes a hatch time.
--==============================================================================
local GROW_SECONDS = { 30, 60, 150, 360, 900, 2100, 4500 }

-- ASSERTED AT LOAD, because these are the owner's numbers: a typo in them is a
-- change to the game that nobody asked for, and it would be invisible -- every
-- pod would simply hatch at the wrong time. A require that fails is louder than
-- a garden that is subtly wrong.
assert(table.concat(GROW_SECONDS, ",") == "30,60,150,360,900,2100,4500",
	"SeedData: the approved hatch ladder has been edited. The owner set "
		.. "30 / 60 / 150 / 360 / 900 / 2100 / 4500 on 2026-09-17.")
assert(#GROW_SECONDS == #SeedData.Tiers,
	"SeedData: the hatch ladder needs exactly one entry per tier.")
for i = 2, #GROW_SECONDS do
	assert(GROW_SECONDS[i] > GROW_SECONDS[i - 1],
		"SeedData: the hatch ladder must rise with the tier.")
end

function SeedData.GrowSeconds(tier: number?): number
	return GROW_SECONDS[SeedData.Tier(tier).index]
end

-- How long THIS species' pod grows: its FixedGrowSeconds when it has one (the
-- Rain event's pods, 2026-10-02: 3 h, 6 h and 9 h), its time for this size
-- when it has one per size (the second family, 2026-10-05: 3 h Tiny .. Titan,
-- 6 h Colossal), else its tier's rung of the ladder above, exactly as before.
-- PlantService stamps the deadline from this once, at planting, and saves it.
function SeedData.GrowSecondsFor(species: Species?, tier: number?): number
	local bySize = if type(species) == "table" then (species :: any).TierGrowSeconds else nil
	if type(bySize) == "table" then
		return bySize[SeedData.Tier(tier).index]
	end
	local fixed = if type(species) == "table" then (species :: any).FixedGrowSeconds else nil
	if type(fixed) == "number" and fixed > 0 then
		return fixed
	end
	return SeedData.GrowSeconds(tier)
end

--==============================================================================
-- AND THE CURVE THE LADDER REPLACED, WHICH OLD PODS ARE STILL OWED
--
-- A pod planted before 2026-09-17 was promised at most five minutes, and it was
-- saved with nothing but the time it went in. Reading the new ladder for it would
-- silently add over an hour to a Colossal somebody left in the ground overnight.
--
-- So PlantService grandfathers a saved pod that has no deadline of its own
-- through this, and writes the result back as its deadline. NOTHING ELSE MAY
-- CALL IT: it is the old promise, kept, and not a second timer.
--==============================================================================
local LEGACY_BASE = 20
local LEGACY_SPAN = 280
local LEGACY_EXP = 0.45

function SeedData.LegacyGrowSeconds(tier: number?): number
	local t = (SeedData.Tier(tier).value / SeedData.Tiers[#SeedData.Tiers].value) ^ LEGACY_EXP
	return LEGACY_BASE + LEGACY_SPAN * t
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
function SeedData.PodDiameter(tier: number?): number
	return SeedData.Tier(tier).pod
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
--==============================================================================
-- THE CEILING CAME BACK DOWN WHEN THE SIZE CURVE CHANGED
--
-- 0.70 .. 2.40 was set when SizeScale ran 0.67 .. 4.22 -- a 6.3x spread -- and
-- against that, girth was the smaller of the two and really was proportion.
-- SizeScale is now clamped to 0.75 .. 1.30, a 1.73x spread, and girth at 3.4x
-- became the DOMINANT driver of how big a plant looks. That is backwards
-- against this block's own title, and it showed: with the size clamp doing its
-- job perfectly on Tanglemire, a Nubkin still ranged 6.2 to 21.4 studs, and
-- Suncrown reached 56.7 -- ten studs THROUGH the 46-stud corridor wall.
--
-- Back to a range that sits just either side of the size curve's, so the two
-- read as one change of scale rather than fighting each other.
--
--     1 kg -> 0.82      14 kg -> 1.00      1,000 kg -> 1.45      10,000 -> 1.45
--==============================================================================

function SeedData.Girth(tier: number?): number
	return SeedData.Tier(tier).girth
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
-- THESE NUMBERS ARE FROM THE OLD 7.5 kg REFERENCE AND ARE KEPT AS A RECORD OF
-- WHAT CHANGED. Under the current sheet a plant stands at its Height at 1,000
-- kg, the clamp holds the range to 0.75 .. 1.30 of that, and ServerMain still
-- rebuilds the Nubkin and Bellchime columns at every boot -- read the log, not
-- this block.
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
--==============================================================================
-- THE REFERENCE IS 1,000 kg NOW, NOT THE MEDIAN
--
-- It used to be 7.5 -- the MEDIAN roll -- so a typical pod stood at exactly its
-- sheet size and the sheet meant "how tall a middling one is". The default is
-- now 1,000 kg, and every Height on the sheet was raised to match: a default
-- plant today stands where the heaviest roll in the game used to.
--
-- The factor is 4.21697 x 1.29. The first is exactly the old scale at 10,000
-- kg; the second makes up for the girth ceiling coming down at the same time,
-- which shrank everything by about a fifth. Both are measured against the
-- heights ServerMain prints at boot, not derived -- the finished height of a
-- plant is its frame PLUS a head whose size rides on girth, so no closed form
-- predicts it.
--
-- MaxKg is unchanged at 10,000, so a lucky roll still grows past the default
-- and a big weight is still worth having.
--
-- THE FLOOR IS ON THE SIZE, NOT ON THE WEIGHT
--
-- Without a clamp a 1 kg pod would come out at (1/1000)^0.20 = 0.251 -- a
-- quarter of default, which is the "tiny one" this is meant to be rid of. The
-- obvious fix is to stop rolling small weights, and it is the wrong one:
-- income is LINEAR in kg, so moving the roll moves every price in the game.
-- Clamping the SIZE leaves RollKg, income, sell prices, mill costs and every
-- progression gate exactly as balanced as they already are.
--
-- The ceiling exists for a harder reason than taste. The corridor walls are
-- GameConfig.Map.WallHeight = 46 studs, and unclamped, 10,000 kg would put the
-- tallest form well through them.
--==============================================================================

--==============================================================================
-- THE REFERENCE WEIGHT, EXPORTED
--
-- The Index lists FORMS and has no weight to show one at -- `species.Kg` is the
-- old-save fallback and sizing anything from it is a bug (see the top of this
-- file). The DEFAULT weight is the honest answer: a plant built at 1,000 kg
-- stands at exactly its sheet size, so an almanac card shows the shape as
-- drawn and at the size a player will usually meet it.
--==============================================================================

function SeedData.SizeScale(tier: number?): number
	return SeedData.Tier(tier).mul
end

-- How tall this form stands at this weight, before the builder adds a head.
function SeedData.FrameHeight(species: Species, tier: number?): number
	return species.Height * SeedData.SizeScale(tier)
end

--==============================================================================
-- How far in front of the root a pod of this weight rides. ONE definition:
-- CarryService welds with it, CarryPose aims the arms with it. It follows the
-- pod's DIAMETER, so a boulder is held further out than a pebble and the offset
-- is never written down twice.
--==============================================================================
function SeedData.GripForward(tier: number?): number
	return GameConfig.Carry.GripForwardBase + SeedData.PodDiameter(tier) * 0.5
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
