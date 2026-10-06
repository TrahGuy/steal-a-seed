--!strict
--==============================================================================
-- THE ORDINARY PLANTS' SUPPLIED RIGS, AS DATA (2026-10-03)
--
-- Twenty-five rigged models the owner placed in five Podnappers Workspace
-- folders, one per biome, lifted here by a read-only generator into one child
-- module each. The originals were not moved or changed and are still in the
-- Workspace; verified .rbxm copies (their demo scripts included) are in
-- output/model-backups/2026-10-03-plant-originals.
--
-- ART AND ANIMATION ONLY. A species built from here keeps its id, name,
-- rarity, biome, income, sale price, odds, walk ladder, save rows and Tool
-- exactly as before: CreatureModel draws it from this data instead of its old
-- primitives, and nothing else asks.
--
-- THE MAPPING (folder/model -> species id), by name, confirmed 2026-10-03:
--
--   Greenhollow Plants   Nubkin Petalpip Spiretip Toadcap Bellchime
--   Dustbowl plants      Dunebud Paddlehop Thornwhorl Raincup Suncrown
--   Tanglemire           Bogbonnet Crookreed Snapmoss Lanterncap Gloomlotus
--   Emberroot            Cinderpaw Emberquill Slagbloom Kilnhusk Pyrelotus
--   Starbloom plants     Novaorb Cosmospire Voidpetal Astralhorn SuperNovus
--                        (SuperNovus -> supernovus)
--
-- Guardians, pods, the Secrets and the Rain event's FIRST forms (RainForms)
-- are not here and are not touched.
--
-- AND FOUR RAIN CREATURES (2026-10-05): Squallsnapper, Monsoad, Thundershell
-- and Torrentacle, the owner's "Rain Event 2" models, are built here too,
-- because they are built the way these rigs are -- whole, at each tier's size.
-- They are Rain event creatures in every other respect (SeedData.RainSpecies:
-- no biome pool, shelf or reward). Their pods are RainForms', one supplied
-- model per size.
--
--==============================================================================
-- SIZE: TODAY'S HEIGHT, THE TIER LADDER, ONE NUMBER PER SPECIES
--
-- Each form is built whole -- every part, joint, attachment, light and
-- emitter by the same factor -- at
--
--     TinyHeight[id] / spec.Height  x  SeedData.SizeScale(tier)
--
-- so a Tiny stands exactly as tall as that species' Tiny stood before the
-- swap (TinyHeight is that measured height, 2026-10-03), and every tier above
-- it grows by the same ladder every plant already uses (Tiny 1 .. Colossal
-- 7.6). Nothing is stretched: the supplied proportions are kept at every size.
--
-- EXCEPT TWO, BY THE OWNER'S CHOICE (2026-10-03): at today's height Snapmoss
-- would be 29 studs long as a Tiny and Emberquill 3x its footprint, so those two
-- match today's LONGEST side instead (TinyLongest): their longest drawn side at
-- Tiny is exactly the longest side that species' Tiny had, the supplied
-- proportions kept, and the same ladder on up to Colossal.
--
-- A species in neither table would NOT be built from here and would keep its
-- previous appearance.
--
-- THE RAIN CREATURES ARE THEIR OWN TINY (Supplied, 2026-10-05). They had no
-- size before, so the owner's supplied model IS the Tiny reference: factor 1
-- at Tiny, and the same ladder (x1.38 .. x7.6) on up to Colossal.
--==============================================================================
-- CARRIED OVERHEAD (2026-10-03, the owner's approved carry for these plants)
--
-- A hatched plant built from a supplied rig is carried the way the Secrets are
-- (GameConfig.Carry.OverheadLift): both hands raised beneath it, the whole model
-- above the head. Its POD is not: pods keep the carry they always had.
-- CarriedOverhead is the one question CarryService, CarryPose and the carry
-- camera all ask.
--==============================================================================
local SecretForms = require(script.Parent:WaitForChild("SecretForms"))

local PlantForms = {}

local function load(name: string): SecretForms.FormSpec
	return (require :: any)(script:WaitForChild(name))
end

local IDS = {
	"nubkin", "petalpip", "spiretip", "toadcap", "bellchime",
	"dunebud", "paddlehop", "thornwhorl", "raincup", "suncrown",
	"bogbonnet", "crookreed", "snapmoss", "lanterncap", "gloomlotus",
	"cinderpaw", "emberquill", "slagbloom", "kilnhusk", "pyrelotus",
	"novaorb", "cosmospire", "voidpetal", "astralhorn", "supernovus",
}
-- The Rain event's second family (2026-10-05), built at its supplied size x the
-- tier ladder (Supplied, below).
local RAIN_IDS = { "squallsnapper", "monsoad", "thundershell", "torrentacle" }

PlantForms.Plants = {} :: { [string]: SecretForms.FormSpec }
for _, id in ipairs(IDS) do
	PlantForms.Plants[id] = load(id)
end
for _, id in ipairs(RAIN_IDS) do
	PlantForms.Plants[id] = load(id)
end

-- The forms whose supplied model is their own Tiny: factor = the tier's size
-- scale, exactly (see SIZE above).
PlantForms.Supplied = {
	squallsnapper = true,
	monsoad = true,
	thundershell = true,
	torrentacle = true,
} :: { [string]: boolean }

-- Each species' Tiny height before the swap, in studs (its built bounding box,
-- measured 2026-10-03). Today's Colossal is exactly 7.6 times it.
PlantForms.TinyHeight = {
	nubkin = 3.72,
	petalpip = 4.65,
	spiretip = 4.96,
	toadcap = 5.58,
	bellchime = 6.20,
	dunebud = 4.03,
	paddlehop = 4.65,
	thornwhorl = 5.27,
	raincup = 5.90,
	suncrown = 6.51,
	bogbonnet = 6.07,
	crookreed = 6.18,
	lanterncap = 6.52,
	gloomlotus = 6.82,
	cinderpaw = 4.34,
	slagbloom = 4.67,
	kilnhusk = 6.46,
	pyrelotus = 7.20,
	novaorb = 4.00,
	cosmospire = 8.04,
	voidpetal = 4.67,
	astralhorn = 7.28,
	supernovus = 8.86,
} :: { [string]: number }

-- The two matched on their longest side instead: each species' longest Tiny
-- side before the swap, in studs (its built bounding box, 2026-10-03; both
-- were their height -- Snapmoss 5.06 x 6.74 x 3.81, Emberquill 2.54 x 7.46 x 3.27).
-- Emberquill's body was replaced by the owner's NEW rig later the same day
-- (2.12 x 7.98 x 5.00 as supplied, standing upright); the rule did not change:
-- its longest side, which for this rig is its height, is 7.46 at Tiny.
PlantForms.TinyLongest = {
	snapmoss = 6.74,
	emberquill = 7.46,
} :: { [string]: number }

-- Whether a species is built from its supplied rig.
function PlantForms.Has(id: string): boolean
	return (PlantForms.TinyHeight[id] ~= nil or PlantForms.TinyLongest[id] ~= nil or PlantForms.Supplied[id] == true)
		and PlantForms.Plants[id] ~= nil
end

-- The whole-model factor the species is built at for a tier's size scale
-- (SeedData.SizeScale), or nil when it is not built from here.
function PlantForms.Scale(id: string, sizeScale: number): number?
	local spec = PlantForms.Plants[id]
	if not spec then
		return nil
	end
	-- Its supplied size is its Tiny: the ladder and nothing else.
	if PlantForms.Supplied[id] == true then
		return sizeScale
	end
	local tall = PlantForms.TinyHeight[id]
	if tall and spec.Height > 0 then
		return tall / spec.Height * sizeScale
	end
	local long = PlantForms.TinyLongest[id]
	local side = math.max(spec.Size.X, spec.Size.Y, spec.Size.Z)
	if long and side > 0 then
		return long / side * sizeScale
	end
	return nil
end

-- Whether this is carried over the head: a species flagged for it (the Secrets
-- and the Rain forms, pod and plant alike), or a HATCHED plant built from a
-- supplied rig. `species` is a SeedData species; anything else is false.
function PlantForms.CarriedOverhead(species: any, hatched: boolean?): boolean
	if type(species) ~= "table" then
		return false
	end
	if species.Carry == "overhead" then
		return true
	end
	return hatched == true and type(species.Id) == "string" and PlantForms.Has(species.Id)
end

-- How big a hatched rigged plant of this size scale is (its drawn extents), for
-- the carry camera; nil when the species is not built from here.
function PlantForms.SizeAt(id: string, sizeScale: number): Vector3?
	local scale = PlantForms.Scale(id, sizeScale)
	local spec = PlantForms.Plants[id]
	if not scale or not spec then
		return nil
	end
	return spec.Size * scale
end

return PlantForms
