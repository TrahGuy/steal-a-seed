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
		-- The first Mythic form in the game. It is the only plant carrying a
		-- Neon halo, a Glass dew jewel, two emitters and a Highlight, and that
		-- budget is the rarity: nothing below Mythic gets an aura.
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
		Height = 4.60, Form = "orb",
		Body = Color3.fromRGB(39, 37, 82),
		Crown = Color3.fromRGB(158, 128, 255),
		Accent = Color3.fromRGB(110, 230, 255),
		Leaf = STAR_LEAF, Stem = STAR_STEM, Soil = STAR_SOIL,
	},
	{
		Id = "cosmospire", Name = "Cosmospire", Rarity = "Rare", Biome = "starbloom",
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
-- A grown plant pays its kg every second for as long as it stands. Selling the
-- same thing hands over thirty seconds of that and takes it away forever, so
-- anything worth keeping is worth planting and the stall is for clearing out a
-- bag full of pocket change -- which, per the weight histogram above, is what
-- most of a bag actually is.
--
-- ONE NUMBER TUNES IT. Raise SellSeconds and selling starts competing with
-- planting; drop it and the stall stops being worth the walk. It is deliberately
-- not per-species and not per-rarity: a bag is sold in one press, and a price
-- the player cannot work out in their head before pressing is a price that will
-- feel wrong however fair it is.
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
-- weight inside it. Income was kilograms per second, so income per plant lands
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

SeedData.Tiers = {
	{ index = 1, name = "Tiny",       mul = 1.000, weight = 0.5325, value = 4,    girth = 0.82, pod = 1.66, color = Color3.fromRGB(170, 175, 180) },
	{ index = 2, name = "Big",        mul = 1.308, weight = 0.1593, value = 28,   girth = 0.90, pod = 2.59, color = Color3.fromRGB(120, 200, 110) },
	{ index = 3, name = "Huge",       mul = 1.710, weight = 0.1007, value = 140,  girth = 0.98, pod = 3.66, color = Color3.fromRGB( 90, 170, 240) },
	{ index = 4, name = "Mega",       mul = 5.000, weight = 0.0789, value = 530,  girth = 1.07, pod = 4.87, color = Color3.fromRGB(170, 120, 240) },
	{ index = 5, name = "Giant",      mul = 10.000, weight = 0.0592, value = 1650, girth = 1.17, pod = 6.09, color = Color3.fromRGB(255, 160,  60) },
	{ index = 6, name = "Titan",      mul = 20.000, weight = 0.0642, value = 5200, girth = 1.30, pod = 7.94, color = Color3.fromRGB(240,  80,  70) },
	{ index = 7, name = "Colossal",   mul = 50.000, weight = 0.0052, value = 9500, girth = 1.45, pod = 9.04, color = Color3.fromRGB(255, 215,  90) },
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
		local w = if t.index >= 4 then t.weight * bonus else t.weight
		total += w
	end

	local target = roll * total
	local acc = 0
	for _, t in ipairs(SeedData.Tiers) do
		local w = if t.index >= 4 then t.weight * bonus else t.weight
		acc += w
		if target <= acc then
			return t.index
		end
	end
	return 1
end

SeedData.SellSeconds = 30

function SeedData.SellPrice(tier: number?): number
	return math.floor(SeedData.IncomePerSecond(tier) * SeedData.SellSeconds)
end

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
local byId: { [string]: Species } = {}
local byBiome: { [string]: { Species } } = {}

for _, species in ipairs(SeedData.Species) do
	assert(byId[species.Id] == nil, "duplicate species id: " .. species.Id)
	assert(GameConfig.RarityTier[species.Rarity] ~= nil,
		string.format("species %q has unknown rarity %q", species.Id, species.Rarity))
	assert(SeedData.RarityWeight[species.Rarity] ~= nil,
		string.format("rarity %q has no drop weight", species.Rarity))
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
function SeedData.IncomePerSecond(tier: number?): number
	return SeedData.Tier(tier).value * GameConfig.Carry.CashPerValue
end

function SeedData.CarryMultiplier(tier: number?): number
	return GameConfig.carryMultiplierFor(SeedData.Tier(tier).value)
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

function SeedData.GrowSeconds(tier: number?): number
	-- Off the tier's VALUE against the top tier's, which is exactly what the old
	-- curve did with kg against MaxKg. Keying it to ladder POSITION instead was
	-- the first attempt and it put a 7x cliff between the two commonest tiers --
	-- 20 seconds for a Tiny and 145 for a Big -- because the positions are
	-- evenly spaced and the values are not.
	local t = (SeedData.Tier(tier).value / SeedData.Tiers[#SeedData.Tiers].value) ^ GROW_EXP
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
