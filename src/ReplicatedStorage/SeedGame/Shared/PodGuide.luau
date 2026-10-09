--!strict
-- Steal a Seed :: PodGuide
--
-- WHAT A POD HATCHES, IN NUMBERS (2026-10-09; KB/POD-GUIDE-PLAN.md, approved)
--
-- Michael's playtest: "I still don't know what pods give me better or worse
-- items." The answer is taught OUTSIDE the pod -- on a stand inside each
-- biome's arch, in the Plant Almanac and in the Bag -- never on the pod itself
-- (2026-09-17: a pod carries no words at all). Since the owner's 25 pods
-- (2026-10-09) every plant has its own pod, so a pod's look says which plant
-- it holds; what is left to teach is how often a nest stocks each one, and
-- what its size is worth.
--
-- PURE. Every number here is worked out from SeedData and BiomeData -- the
-- same tables SeedData.Roll and SeedData.RollTier draw from (SeedData.TierWeight
-- is the rolls' own size rule) -- so nothing is typed in twice and nothing can
-- drift from the real rolls. PodGuideSpec holds the two together.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))

local PodGuide = {}

export type PlantOdds = { species: SeedData.Species, chance: number }
export type SizeOdds = { tier: number, name: string, colour: Color3, chance: number, worth: number }
export type SecretOdds = { speciesId: string, chance: number }

-- A biome's plants in the order its nest draws them (SeedData.Roll's pool),
-- each with the chance that a pod it stocks is that plant's.
function PodGuide.plants(biomeId: string): { PlantOdds }
	local pool = SeedData.InBiome(biomeId)
	local total = 0
	for _, sp in ipairs(pool) do
		total += SeedData.RarityWeight[sp.Rarity]
	end
	local out: { PlantOdds } = {}
	for _, sp in ipairs(pool) do
		table.insert(out, {
			species = sp,
			chance = if total > 0 then SeedData.RarityWeight[sp.Rarity] / total else 0,
		})
	end
	return out
end

-- One plant's chance in its biome's nests; 0 for one no nest stocks.
function PodGuide.chanceOf(speciesId: string): number
	local sp = SeedData.Get(speciesId)
	if not sp then
		return 0
	end
	for _, row in ipairs(PodGuide.plants(sp.Biome)) do
		if row.species.Id == speciesId then
			return row.chance
		end
	end
	return 0
end

-- The seven sizes in a biome's nests: each one's chance (the biome's
-- RarityBonus, through SeedData.TierWeight) and what it is worth against Tiny
-- (the sizes' value: x1, x7, x35, x132.5, x412.5, x1300, x2375).
function PodGuide.sizes(biomeId: string): { SizeOdds }
	local biome = BiomeData.ById[biomeId]
	local bonus = if biome then biome.RarityBonus else 1
	local total = 0
	for _, t in ipairs(SeedData.Tiers) do
		total += SeedData.TierWeight(t, bonus)
	end
	local base = SeedData.Tiers[1].value
	local out: { SizeOdds } = {}
	for _, t in ipairs(SeedData.Tiers) do
		table.insert(out, {
			tier = t.index,
			name = t.name,
			colour = t.color,
			chance = if total > 0 then SeedData.TierWeight(t, bonus) / total else 0,
			worth = t.value / base,
		})
	end
	return out
end

-- The secret pod a biome's nest may raise beside its own (BiomeData's Secret),
-- or nil: none for this biome, or secrets switched off (GameConfig.Secret).
function PodGuide.secret(biomeId: string): SecretOdds?
	if not GameConfig.Secret.Enabled then
		return nil
	end
	local biome = BiomeData.ById[biomeId]
	local cfg = biome and (biome :: any).Secret
	local id = SeedData.SecretByBiome[biomeId]
	if not (cfg and type(id) == "string" and type(cfg.SpawnChance) == "number") then
		return nil
	end
	return { speciesId = id, chance = cfg.SpawnChance }
end

-- A chance as the guide writes it: three significant figures, trailing zeros
-- off -- 43%, 11.2%, 2.37%, 0.387%.
function PodGuide.percent(p: number): string
	local pct = p * 100
	if pct ~= pct or pct <= 0 then
		return "0%"
	end
	local places = math.max(2 - math.floor(math.log10(pct)), 0)
	local s = string.format("%." .. places .. "f", pct)
	if string.find(s, ".", 1, true) then
		s = string.gsub(s, "0+$", "")
		s = string.gsub(s, "%.$", "")
	end
	return s .. "%"
end

-- What a size is worth against Tiny, as the guide writes it: x1, x7, x35,
-- x132, x412, x1,300, x2,375 (whole times, rounded down).
function PodGuide.times(worth: number): string
	local digits = string.format("%d", math.max(math.floor(worth), 0))
	local grouped = string.reverse((string.gsub(string.reverse(digits), "(%d%d%d)", "%1,")))
	return "x" .. (string.gsub(grouped, "^,", ""))
end

-- A plant's income at every size, Tiny to Colossal (SeedData.IncomePerSecond).
function PodGuide.incomes(speciesId: string): { number }
	local sp = SeedData.Get(speciesId)
	local out: { number } = {}
	for _, t in ipairs(SeedData.Tiers) do
		table.insert(out, if sp then SeedData.IncomePerSecond(sp, t.index) else 0)
	end
	return out
end

return PodGuide
