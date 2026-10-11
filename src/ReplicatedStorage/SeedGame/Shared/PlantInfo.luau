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
-- An Invite a Friend reward's Sell line (2026-10-06): no stall buys one.
PlantInfo.NoSale = "Can't be sold"

local QUIET = Color3.fromRGB(198, 176, 152)

export type Info = {
	title: string,
	stage: string,
	biome: string,
	rarity: string,
	rarityColour: Color3,
	size: string,
	sizeColour: Color3,
	-- False for a Secret, which has no size tier: `size` is empty and a caller
	-- shows no size row or badge at all (2026-10-02).
	sized: boolean,
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

--==============================================================================
-- A SECRET HAS ITS RARITY AND NO SIZE TIER (the owner's rule, 2026-10-02)
--
-- One authored size and a fixed income (SeedData FixedIncome); the tier its
-- Tool carries is implementation-only (SeedData.SecretTier). So every list, tag
-- and line asks these instead of reading a tier itself: a Secret's colour is
-- the Secret rarity colour and it has no size word at all.
--==============================================================================
function PlantInfo.IsSecret(speciesId: any): boolean
	local species = if type(speciesId) == "string" then SeedData.Get(speciesId) else nil
	return species ~= nil and species.Secret == true
end

-- The same rule for the Rain event's Pod 1 and Pod 3 forms (2026-10-02): one
-- authored size, no size word, and their RARITY's colour where a size colour
-- would go. Pod 2's forms are sized: they show Colossal like any Colossal.
function PlantInfo.IsUnsized(speciesId: any): boolean
	return SeedData.Unsized(if type(speciesId) == "string" then SeedData.Get(speciesId) else nil)
end

function PlantInfo.SizeColour(speciesId: any, tier: any): Color3
	if PlantInfo.IsUnsized(speciesId) then
		local species = SeedData.Get(speciesId) :: SeedData.Species
		return GameConfig.RarityColor[species.Rarity] or QUIET
	end
	return SeedData.ColorForTier(tonumber(tier))
end

-- nil for a Secret, or an unsized Rain form: there is no size to name.
function PlantInfo.SizeWord(speciesId: any, tier: any): string?
	if PlantInfo.IsUnsized(speciesId) then
		return nil
	end
	return SeedData.TierName(tonumber(tier))
end

function PlantInfo.Describe(speciesId: any, tier: any, hatched: boolean,
	multiplier: number?): Info
	local species = if type(speciesId) == "string" then SeedData.Get(speciesId) else nil
	local band = SeedData.Tier(tonumber(tier))
	local biome = if species then BiomeData.ById[species.Biome] else nil
	local secret = species ~= nil and species.Secret == true
	local unsized = SeedData.Unsized(species)
	local rainPod = SeedData.RainPodOf(species)

	local info: Info = {
		title = PlantInfo.PodTitle,
		stage = PlantInfo.PodTitle,
		-- The Rain event's temporary biome is in no BiomeData list: its working
		-- label, rather than ???.
		biome = if biome then biome.DisplayName
			elseif rainPod then GameConfig.Weather.Biome.Label
			else PlantInfo.Unknown,
		rarity = PlantInfo.Unknown,
		rarityColour = QUIET,
		size = if unsized then "" else band.name,
		sizeColour = if unsized then PlantInfo.SizeColour(speciesId, tier) else band.color,
		sized = not unsized,
		income = PlantInfo.PodIncome,
		incomePerSecond = nil,
		sell = nil,
		sellValue = nil,
	}
	-- An ordinary pod is named by its biome (2026-10-09, the Pod Guide:
	-- "Greenhollow pod", GameConfig.PodGuide.Words.BagTitle) -- what its own
	-- look already says. Still no plant and no rarity.
	if biome and not secret and not rainPod then
		info.title = string.format(GameConfig.PodGuide.Words.BagTitle, biome.DisplayName)
	end
	if species and (species :: any).Mystery == true and not hatched then
		-- The Mysterious Pod (Enchanted Mist stage 4): one shell for every
		-- creature, so its name and nothing else -- no biome, no rarity, no size,
		-- no colour: any of them could name what is inside.
		info.title = (species :: SeedData.Species).Name
		info.biome = PlantInfo.Unknown
	elseif secret and not hatched then
		-- A Secret's pod is its own model: its look already says what it is, so
		-- it reads Secret -- never a size, and never pretends to be ???.
		local known = species :: SeedData.Species
		info.title = "Secret pod"
		info.rarity = known.Rarity
		info.rarityColour = GameConfig.RarityColor[known.Rarity] or QUIET
	elseif rainPod and not hatched then
		-- A Rain pod is its own model too, and its look says only WHICH POD:
		-- its name and rarity, shared by every creature it can hold. Which one
		-- is inside -- and so its income and price -- stays for the hatch.
		local pod = rainPod :: SeedData.RainPod
		info.title = pod.Name
		-- The second family's creatures differ in rarity (2026-10-05), so its
		-- pods carry none and the line stays ???, like an ordinary pod's: a
		-- rarity there would name the creature inside. Its size still shows.
		local rarity = pod.Rarity
		if rarity then
			info.rarity = rarity
			info.rarityColour = GameConfig.RarityColor[rarity] or QUIET
		end
	end
	if not (hatched and species) then
		return info
	end

	local known = species :: SeedData.Species
	local rate = SeedData.IncomePerSecond(known, band.index) * displayMultiplier(multiplier)
	info.title = known.Name
	info.stage = "Grown"
	info.rarity = known.Rarity
	info.rarityColour = GameConfig.RarityColor[known.Rarity] or QUIET
	info.income = "+$" .. GameConfig.compact(rate) .. "/s"
	info.incomePerSecond = rate
	if SeedData.Sellable(known) then
		local price = SeedData.SellPrice(known, band.index)
		info.sell = "$" .. GameConfig.compact(price)
		info.sellValue = price
	else
		-- No price: what the stall pays for it is nothing, because it never buys it.
		info.sell = PlantInfo.NoSale
	end
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

--==============================================================================
-- THE SORTS THE BAG AND THE GARDEN OFFER (2026-09-26)
--
-- One comparator for both lists, so "income, highest first" cannot mean two
-- different things in two menus -- and it lives HERE because the rule that
-- matters most in it is this file's: an unhatched pod stays ???. A pod has no
-- income, rarity or name a sort is allowed to read, so under every sort the
-- pods follow the grown plants, among themselves in the caller's stable order.
-- Nothing about the species inside a shell can be read off where it lands.
--
-- "default" is the caller's own order, returned untouched: choosing a sort is
-- the only thing that changes what a player is used to.
--
-- EVERY TIE FALLS TO THE CALLER'S STABLE ID -- a PlacementId in the Garden, the
-- order the Bag first saw each Tool -- so two equal plants never trade places
-- between one repaint and the next, and a selection can follow its plant.
-- The numbers are the ones already used everywhere else: IncomePerSecond, the
-- faucet's own rate with no multiplier (a sort compares plants, not wallets),
-- and GameConfig.RarityTier, the one rarity order.
--==============================================================================
PlantInfo.SortModes = { "default", "incomeHigh", "incomeLow", "rarity", "name" }

-- What the Sort button says under its word SORT. Plain words: the arrow glyphs
-- that would say "descending" are a tofu risk in these fonts.
PlantInfo.SortLabels = {
	default = "DEFAULT",
	incomeHigh = "INCOME HIGH",
	incomeLow = "INCOME LOW",
	rarity = "RAREST",
	name = "NAME A-Z",
} :: { [string]: string }

function PlantInfo.NextSort(mode: string): string
	local modes = PlantInfo.SortModes
	local at = table.find(modes, mode) or 1
	return modes[at % #modes + 1]
end

-- What a caller says about one entry. `hatched` false means a pod, whatever
-- species id the caller happens to know for it.
export type SortKey = {
	speciesId: any,
	tier: any,
	hatched: boolean,
	id: number,
}

type Ranked = {
	known: boolean,
	income: number,
	rarity: number,
	name: string,
	id: number,
}

local function ranked(key: SortKey): Ranked
	local species = if key.hatched and type(key.speciesId) == "string"
		then SeedData.Get(key.speciesId)
		else nil
	if not species then
		return { known = false, income = 0, rarity = 0, name = "", id = key.id }
	end
	local known = species :: SeedData.Species
	return {
		known = true,
		income = SeedData.IncomePerSecond(known, SeedData.Tier(tonumber(key.tier)).index),
		rarity = GameConfig.RarityTier[known.Rarity] or 0,
		name = string.lower(known.Name),
		id = key.id,
	}
end

-- Sorts `list` in place under `mode` and returns it. `keyOf` reads each entry.
function PlantInfo.Sort<T>(list: { T }, mode: string, keyOf: (T) -> SortKey): { T }
	if mode == "default" or not table.find(PlantInfo.SortModes, mode) then
		return list
	end
	local rank: { [any]: Ranked } = {}
	for _, entry in ipairs(list) do
		rank[entry] = ranked(keyOf(entry))
	end
	table.sort(list, function(a: T, b: T): boolean
		local ra, rb = rank[a], rank[b]
		if ra.known ~= rb.known then
			return ra.known
		end
		if ra.known then
			if mode == "incomeHigh" and ra.income ~= rb.income then
				return ra.income > rb.income
			elseif mode == "incomeLow" and ra.income ~= rb.income then
				return ra.income < rb.income
			elseif mode == "rarity" and ra.rarity ~= rb.rarity then
				return ra.rarity > rb.rarity
			elseif mode == "name" and ra.name ~= rb.name then
				return ra.name < rb.name
			end
		end
		return ra.id < rb.id
	end)
	return list
end

-- A card's base income, for the Bag's thumbnails: the plant's own rate with
-- its permanent factors (tier, rarity, biome, flat bonus -- IncomePerSecond
-- is all of them) and no boost of any kind. nil for a pod, which has none
-- anybody may be told yet.
function PlantInfo.BaseIncome(speciesId: any, tier: any, hatched: boolean): number?
	local species = if hatched and type(speciesId) == "string" then SeedData.Get(speciesId) else nil
	if not species then
		return nil
	end
	return SeedData.IncomePerSecond(species :: SeedData.Species, SeedData.Tier(tonumber(tier)).index)
end

return PlantInfo
