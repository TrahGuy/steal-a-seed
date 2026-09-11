--!strict
-- Steal a Seed :: PlantInfo
--
-- What the Bag's information panel says about ONE plant Tool. Pure: a species
-- id, a tier and a hatched flag in, display strings out. No Instances, no
-- clock, no player -- so a spec can hold every line of it to the economy.
--
--==============================================================================
-- NO NUMBER HERE IS WORKED OUT HERE
--
-- Income is `SeedData.IncomePerSecond`, the one calculation EconomyService pays
-- from, times the caller's display multiplier -- which is exactly what the
-- Garden prints for the player's OWN plants (`GameConfig.cashMultiplier`).
-- A plant in your bag is your plant, so it reads the way your garden reads.
-- Sell value is `SeedData.SellPrice`, which is what the stall pays, and the stall
-- is pass-agnostic, so it takes no multiplier.
--
--==============================================================================
-- AN UNHATCHED POD STAYS ???
--
-- CarryService names a banked pod `???` on purpose: which species came out of
-- the shell is the reveal the hatch is for. Rarity would give it away (Epic in
-- Greenhollow is Bellchime) and so would income and price, since both are
-- scaled by rarity. So a pod shows only what the shell already shows -- its
-- size, which is its colour, and its biome, which is its palette.
--
-- Nothing here ever returns a species id, a debug id or a raw tier number.
--==============================================================================

local Shared = script.Parent
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))

local PlantInfo = {}

PlantInfo.Unknown = "???"
PlantInfo.PodTitle = "Unhatched pod"
PlantInfo.PodIncome = "After it hatches"

local QUIET = Color3.fromRGB(198, 176, 152)

export type Info = {
	title: string,
	stage: string,
	biome: string,
	rarity: string,
	rarityColour: Color3,
	size: string,
	sizeColour: Color3,
	income: string,
	incomePerSecond: number?,
	sell: string?,
	sellValue: number?,
}

-- A display multiplier that is missing, NaN or below 1 reads as 1, the same
-- floor `GameConfig.cashMultiplier` applies.
local function displayMultiplier(value: any): number
	local n = tonumber(value)
	if not n or n ~= n or n < 1 then
		return 1
	end
	return n
end

function PlantInfo.Describe(speciesId: any, tier: any, hatched: boolean,
	multiplier: number?): Info
	local species = if type(speciesId) == "string" then SeedData.Get(speciesId) else nil
	local band = SeedData.Tier(tonumber(tier))
	local biome = if species then BiomeData.ById[species.Biome] else nil

	local info: Info = {
		title = PlantInfo.PodTitle,
		stage = PlantInfo.PodTitle,
		biome = if biome then biome.DisplayName else PlantInfo.Unknown,
		rarity = PlantInfo.Unknown,
		rarityColour = QUIET,
		size = band.name,
		sizeColour = band.color,
		income = PlantInfo.PodIncome,
		incomePerSecond = nil,
		sell = nil,
		sellValue = nil,
	}
	if not (hatched and species) then
		return info
	end

	local known = species :: SeedData.Species
	local rate = SeedData.IncomePerSecond(known, band.index) * displayMultiplier(multiplier)
	local price = SeedData.SellPrice(known, band.index)
	info.title = known.Name
	info.stage = "Grown"
	info.rarity = known.Rarity
	info.rarityColour = GameConfig.RarityColor[known.Rarity] or QUIET
	info.income = "+$" .. GameConfig.compact(rate) .. "/s"
	info.incomePerSecond = rate
	info.sell = "$" .. GameConfig.compact(price)
	info.sellValue = price
	return info
end

-- Where the Tool is, in the words a player uses for it.
function PlantInfo.Status(inHand: boolean, hotbarSlot: number?): string
	if inHand then
		return "In hand"
	end
	if hotbarSlot then
		return "Hotbar slot " .. tostring(hotbarSlot)
	end
	return "In your bag"
end

-- The card backdrop: the established biome art, for a grown plant only. A pod
-- gets none, the same rule the Garden follows.
function PlantInfo.Backdrop(speciesId: any, hatched: boolean): string?
	if not hatched or type(speciesId) ~= "string" or not SeedData.Get(speciesId) then
		return nil
	end
	return GameConfig.Card.Art[speciesId]
end

return PlantInfo
