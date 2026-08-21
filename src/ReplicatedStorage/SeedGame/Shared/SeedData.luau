--!strict
-- Steal a Seed :: SeedData
--
-- Every species: the pod you steal, and the creature it grows into. Balance
-- lives here and nowhere else (Rule 7) -- GameConfig holds structure and the
-- speed curve, never what a thing is worth.
--
--==============================================================================
-- WHAT YOU STEAL IS A POD. WHAT GROWS IS ALIVE.
--
-- The pod is a small rarity-coloured ovoid that VISIBLY WRIGGLES while carried.
-- That wriggle is doing real work: it tells everyone on the road -- you, and the
-- player chasing you -- that there is something alive in there, before it has
-- grown into anything. A seed reads as a pebble; a pod that moves reads as a
-- prize.
--
-- What it grows into is ROOTED. It sways, blinks and turns its head, and it
-- never walks. That single constraint is what makes creatures affordable here:
--
--   * A rooted creature IS a plant mechanically. It occupies one PlantSlot,
--     grows on a timer, and pays income. Not one line of the plot geometry,
--     the slot grid or the save schema changes to accommodate it.
--   * No pathfinding, no Humanoid, no network ownership per creature. Six plots
--     of twelve slots is 72 of these in a server -- as wandering mobs that is a
--     performance problem, as rooted ones it is 72 anchored models a client
--     sways for free.
--
-- So the collection has faces and personality at the cost of a vegetable patch.
--
--==============================================================================
-- RARITY DECIDES THE NUMBERS, SPECIES DECIDES THE LOOK
--
-- Income and growth time come from RARITY, not from the species, so adding a
-- creature is choosing a rarity and some colours rather than inventing a
-- balance point nobody can compare to anything. A species may nudge its income
-- with IncomeScale when it should feel special, and that nudge is visible as a
-- number rather than buried in a bespoke figure.
--
-- BOTH CURVES ARE A FIRST PASS. Nothing has been played yet. They are shaped
-- correctly relative to each other -- roughly 4.5x income per tier against
-- roughly 2x growth time -- so the later tiers are worth the wait, and the
-- absolute values will move once there is a real session to measure.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local SeedData = {}

-- Cash per second once grown. Geometric, so a tier up is always felt.
SeedData.RarityIncome = {
	Common = 2,
	Uncommon = 9,
	Rare = 40,
	Epic = 180,
	Legendary = 800,
	Mythic = 3600,
	Secret = 16000,
	Divine = 72000,
}

-- Seconds from planting to grown. Deliberately much flatter than income: the
-- wait is a vulnerability window, not the cost of the item. A curve as steep as
-- income would make Divine an hours-long nothing.
SeedData.RarityGrowSeconds = {
	Common = 30,
	Uncommon = 55,
	Rare = 100,
	Epic = 180,
	Legendary = 320,
	Mythic = 560,
	Secret = 900,
	Divine = 1500,
}

--==============================================================================
-- THE SPECIES
--
-- Ordered by the road. A biome's creatures are the reason to walk that far, so
-- each one is visibly of its place: Greenhollow's are soft and leafy,
-- Starbloom's are barely solid.
--
-- Height is in studs, grown. It rises with rarity on purpose -- a Divine
-- creature is visible across the field from somebody else's plot, and being
-- seen is most of why a trophy is worth having.
--==============================================================================
export type Species = {
	Id: string,
	Name: string,
	Rarity: string,
	Biome: string,
	-- Multiplies the rarity's income. 1 unless this one should feel special.
	IncomeScale: number,
	Body: Color3,
	Accent: Color3,
	Leaf: Color3,
	Height: number,
	-- How many eyes the face has. Two reads friendly, one reads odd, three
	-- reads wrong -- which is exactly the progression the road should have.
	Eyes: number,
	Glow: boolean,

	--==========================================================================
	-- SILHOUETTE
	--
	-- The first build made every species a cube head on a stem, and eleven
	-- cube heads in different colours is a palette, not a collection. Colour
	-- alone cannot carry identity: half these creatures are seen at distance,
	-- on a phone, in somebody else's plot, where SHAPE is all that survives.
	--
	-- Two knobs, both cheap: what the bulb is, and what radiates off the top of
	-- it. A five-petal ball and a four-spike block are unmistakable from across
	-- the field even in the same colour.
	--==========================================================================
	Shape: string,      -- "block" | "ball" | "cylinder"
	Crown: number,      -- how many petals/spikes radiate from the top
	CrownKind: string,  -- "petal" | "spike" | "none"
}

SeedData.Species = {
	--== GREENHOLLOW -- soft, leafy, big-eyed ==--
	{
		Id = "sproutling", Name = "Sproutling", Rarity = "Common", Biome = "greenhollow",
		IncomeScale = 1, Height = 2.6, Eyes = 2, Glow = false,
		Shape = "block", Crown = 0, CrownKind = "none",
		Body = Color3.fromRGB(126, 200, 96),
		Accent = Color3.fromRGB(232, 240, 176),
		Leaf = Color3.fromRGB(86, 158, 66),
	},
	{
		Id = "hollowbud", Name = "Hollowbud", Rarity = "Uncommon", Biome = "greenhollow",
		IncomeScale = 1, Height = 3.0, Eyes = 2, Glow = false,
		Shape = "ball", Crown = 5, CrownKind = "petal",
		Body = Color3.fromRGB(238, 176, 208),
		Accent = Color3.fromRGB(255, 232, 244),
		Leaf = Color3.fromRGB(96, 170, 78),
	},

	--== DUSTBOWL -- spiny, sun-bleached, grumpy ==--
	{
		Id = "pricklepup", Name = "Pricklepup", Rarity = "Uncommon", Biome = "dustbowl",
		IncomeScale = 1.15, Height = 3.0, Eyes = 2, Glow = false,
		Shape = "block", Crown = 4, CrownKind = "spike",
		Body = Color3.fromRGB(122, 168, 108),
		Accent = Color3.fromRGB(236, 214, 150),
		Leaf = Color3.fromRGB(206, 178, 120),
	},
	{
		Id = "duststalk", Name = "Duststalk", Rarity = "Rare", Biome = "dustbowl",
		IncomeScale = 1, Height = 3.6, Eyes = 1, Glow = false,
		Shape = "cylinder", Crown = 3, CrownKind = "spike",
		Body = Color3.fromRGB(214, 162, 96),
		Accent = Color3.fromRGB(248, 226, 168),
		Leaf = Color3.fromRGB(168, 130, 74),
	},

	--== TANGLEMIRE -- fungal, damp, too many limbs ==--
	{
		Id = "miregill", Name = "Miregill", Rarity = "Rare", Biome = "tanglemire",
		IncomeScale = 1.2, Height = 3.6, Eyes = 3, Glow = false,
		Shape = "ball", Crown = 0, CrownKind = "none",
		Body = Color3.fromRGB(120, 146, 172),
		Accent = Color3.fromRGB(178, 206, 224),
		Leaf = Color3.fromRGB(86, 116, 104),
	},
	{
		Id = "snarlfang", Name = "Snarlfang", Rarity = "Epic", Biome = "tanglemire",
		IncomeScale = 1, Height = 4.2, Eyes = 2, Glow = false,
		Shape = "block", Crown = 3, CrownKind = "spike",
		Body = Color3.fromRGB(146, 108, 196),
		Accent = Color3.fromRGB(224, 200, 248),
		Leaf = Color3.fromRGB(92, 74, 128),
	},

	--== EMBERROOT -- lit from inside ==--
	{
		Id = "cinderbloom", Name = "Cinderbloom", Rarity = "Epic", Biome = "emberroot",
		IncomeScale = 1.25, Height = 4.2, Eyes = 2, Glow = true,
		Shape = "ball", Crown = 5, CrownKind = "petal",
		Body = Color3.fromRGB(226, 106, 62),
		Accent = Color3.fromRGB(255, 196, 104),
		Leaf = Color3.fromRGB(150, 62, 44),
	},
	{
		Id = "embermaw", Name = "Embermaw", Rarity = "Legendary", Biome = "emberroot",
		IncomeScale = 1, Height = 4.8, Eyes = 1, Glow = true,
		Shape = "block", Crown = 4, CrownKind = "spike",
		Body = Color3.fromRGB(196, 54, 46),
		Accent = Color3.fromRGB(255, 158, 62),
		Leaf = Color3.fromRGB(118, 40, 36),
	},

	--== STARBLOOM -- barely solid ==--
	{
		Id = "starpetal", Name = "Starpetal", Rarity = "Mythic", Biome = "starbloom",
		IncomeScale = 1, Height = 5.2, Eyes = 2, Glow = true,
		Shape = "ball", Crown = 6, CrownKind = "petal",
		Body = Color3.fromRGB(138, 214, 232),
		Accent = Color3.fromRGB(236, 252, 255),
		Leaf = Color3.fromRGB(106, 158, 214),
	},
	{
		Id = "voidblossom", Name = "Voidblossom", Rarity = "Secret", Biome = "starbloom",
		IncomeScale = 1.1, Height = 5.6, Eyes = 3, Glow = true,
		Shape = "ball", Crown = 6, CrownKind = "petal",
		Body = Color3.fromRGB(74, 62, 128),
		Accent = Color3.fromRGB(180, 140, 255),
		Leaf = Color3.fromRGB(48, 40, 84),
	},
	{
		Id = "astralroot", Name = "Astralroot", Rarity = "Divine", Biome = "starbloom",
		IncomeScale = 1, Height = 6.2, Eyes = 2, Glow = true,
		Shape = "ball", Crown = 7, CrownKind = "petal",
		Body = Color3.fromRGB(255, 244, 190),
		Accent = Color3.fromRGB(255, 255, 244),
		Leaf = Color3.fromRGB(226, 196, 120),
	},
} :: { Species }

--==============================================================================
-- LOOKUPS
--
-- Built once at require. Everything that asks "what grows in Dustbowl" or "what
-- is species X" reads one of these rather than walking the list, and the list
-- stays the single place a species is declared.
--==============================================================================
local byId: { [string]: Species } = {}
local byBiome: { [string]: { Species } } = {}

for _, species in ipairs(SeedData.Species) do
	assert(byId[species.Id] == nil, "duplicate species id: " .. species.Id)
	assert(GameConfig.RarityTier[species.Rarity] ~= nil,
		string.format("species %q has unknown rarity %q", species.Id, species.Rarity))
	assert(SeedData.RarityIncome[species.Rarity] ~= nil,
		string.format("rarity %q has no income", species.Rarity))
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

function SeedData.IncomePerSecond(species: Species): number
	return SeedData.RarityIncome[species.Rarity] * species.IncomeScale
end

function SeedData.GrowSeconds(species: Species): number
	return SeedData.RarityGrowSeconds[species.Rarity]
end

-- The pod takes its RARITY colour, not its species colour, and that is
-- deliberate. While it is being carried the only thing that matters to everyone
-- watching is how badly they want it, and rarity is that. What species it is
-- becomes interesting once it is safely in the ground.
function SeedData.PodColor(species: Species): Color3
	return GameConfig.RarityColor[species.Rarity] or Color3.fromRGB(200, 200, 200)
end

--==============================================================================
-- WEIGHTED ROLL
--
-- Rarer species are rarer WITHIN their biome as well as being further down the
-- road. Distance alone is not enough of a filter: without this, walking to
-- Starbloom once would hand out a Divine, and the last biome would be solved in
-- a single trip.
--
-- Weight is the inverse of income WITHIN THE BIOME. Species never compete
-- across biomes, so this is not a global 36,000-to-one against a Sproutling --
-- it is a ratio between the two or three things that grow in one place.
-- Measured over 20,000 Starbloom rolls:
--
--     starpetal    Mythic   79.98%   pays  3,600/s
--     voidblossom  Secret   16.23%   pays 17,600/s
--     astralroot   Divine    3.79%   pays 72,000/s
--
-- Tying weight to income keeps the two curves from drifting apart: rebalancing
-- what something pays cannot silently leave the odds behind.
--
-- ONE IN TWENTY-SIX STARBLOOM PODS IS DIVINE, which is generous and is on the
-- list to tune. It is defensible for now only because Starbloom is 1,500 studs
-- out behind every speed gate in the game -- the filter is currently the
-- journey, not the roll. If the walk ever gets cheap, this needs a steeper
-- exponent before it does.
--==============================================================================
function SeedData.Roll(biomeId: string, rng: Random): Species?
	local pool = byBiome[biomeId]
	if not pool or #pool == 0 then
		return nil
	end
	local total = 0
	for _, species in ipairs(pool) do
		total += 1 / SeedData.IncomePerSecond(species)
	end
	local pick = rng:NextNumber() * total
	for _, species in ipairs(pool) do
		pick -= 1 / SeedData.IncomePerSecond(species)
		if pick <= 0 then
			return species
		end
	end
	return pool[#pool]
end

return SeedData
