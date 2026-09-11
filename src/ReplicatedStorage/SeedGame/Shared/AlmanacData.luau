--!strict
-- Steal a Seed :: AlmanacData
--
-- The almanac's arithmetic, shared by the Index and by the server that pays for
-- it: which species a biome's shelf holds and in what order, how many of them a
-- player has grown, and what finishing a shelf is worth. Pure -- tables in,
-- answers out, no Instances -- so AlmanacService, IndexUI and a spec all read the
-- same answers.
--
--==============================================================================
-- A SHELF IS FINISHED WHEN EVERY SPECIES ON IT HAS GROWN
--
-- Grown means the Almanac bit PlantService writes when a plant reaches its grown
-- stage on the player's own plot. Nothing else counts: not a pod carried home,
-- not a sprout.
--
--==============================================================================
-- THE BIOME HARVEST IS CLAIMED ONCE PER BIOME
--
-- `mastery` is the profile's set of biome ids already paid. A claim is a request
-- the SERVER settles (AlmanacService); this module is how both ends agree on
-- whether the answer can be yes.
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))

local AlmanacData = {}

export type ClaimState = "locked" | "ready" | "claimed" | "unknown"

-- The biomes in road order: the order of the tabs and of the journey.
function AlmanacData.Biomes(): { BiomeData.Biome }
	local list = table.clone(BiomeData.Biomes)
	table.sort(list, function(a, b)
		return a.Order < b.Order
	end)
	return list
end

-- A biome's species, commonest first, so a shelf reads from the plant everybody
-- finds to the one almost nobody does. Ties fall back to the name, so the order
-- never depends on how the sheet happens to be written.
function AlmanacData.SpeciesIn(biomeId: string): { SeedData.Species }
	local list = table.clone(SeedData.InBiome(biomeId))
	table.sort(list, function(a, b)
		local ta = GameConfig.RarityTier[a.Rarity] or 0
		local tb = GameConfig.RarityTier[b.Rarity] or 0
		if ta ~= tb then
			return ta < tb
		end
		return a.Name < b.Name
	end)
	return list
end

-- How many of a biome's species this almanac holds, out of how many there are.
function AlmanacData.Progress(almanac: { [string]: boolean }?, biomeId: string): (number, number)
	local grown, total = 0, 0
	for _, species in ipairs(SeedData.InBiome(biomeId)) do
		total += 1
		if almanac and almanac[species.Id] == true then
			grown += 1
		end
	end
	return grown, total
end

-- The same count across every biome.
function AlmanacData.TotalProgress(almanac: { [string]: boolean }?): (number, number)
	local grown = 0
	for _, species in ipairs(SeedData.Species) do
		if almanac and almanac[species.Id] == true then
			grown += 1
		end
	end
	return grown, #SeedData.Species
end

-- What finishing a biome pays: (cash, speed), straight off BiomeData.
function AlmanacData.Reward(biomeId: string): (number, number)
	local biome = BiomeData.ById[biomeId]
	if not biome then
		return 0, 0
	end
	return biome.MasteryCash, biome.MasterySpeed
end

--==============================================================================
-- WHERE A BIOME'S HARVEST STANDS
--
--   unknown   not a biome
--   claimed   already paid, whatever the almanac says now
--   ready     every species grown, not yet paid
--   locked    still growing
--==============================================================================
function AlmanacData.ClaimState(almanac: { [string]: boolean }?,
	mastery: { [string]: boolean }?, biomeId: any): ClaimState
	if type(biomeId) ~= "string" or not BiomeData.ById[biomeId] then
		return "unknown"
	end
	if mastery and mastery[biomeId] == true then
		return "claimed"
	end
	local grown, total = AlmanacData.Progress(almanac, biomeId)
	if total > 0 and grown >= total then
		return "ready"
	end
	return "locked"
end

return AlmanacData
