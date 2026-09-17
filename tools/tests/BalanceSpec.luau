--!nocheck
--==============================================================================
-- Steal a Seed :: BalanceSpec
--
-- Two owner-approved price lists, pinned: what every plant earns, and what an
-- Overclock costs. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("BalanceSpec"))
--
-- WHY A SPEC AND NOT A COMMENT. Both lists are numbers a player feels and nobody
-- reads: a plant that pays a dollar less than approved looks fine, and an
-- Overclock priced below the mill it upgrades still works -- it is just free.
-- The whole of the protection is that these tables are written down twice, here
-- and in the source, and that a change has to agree with both.
--
-- Every number below was approved on 2026-09-17. The income table is the TINY
-- rate, which is the one the Index prints and the one a player compares.
--
-- Not here: the payout actually arriving (that is EconomyService in Play), and
-- the sign drawing the price (Play).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local PlantInfo = require(Shared:WaitForChild("PlantInfo"))

local out = {}
local pass, fail = 0, 0

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

--==============================================================================
-- THE APPROVED TINY EARNINGS, ALL TWENTY-FIVE
--==============================================================================
local TINY = {
	{ "greenhollow", "nubkin",     4 },
	{ "greenhollow", "petalpip",   5 },
	{ "greenhollow", "spiretip",   5 },
	{ "greenhollow", "toadcap",    6 },
	{ "greenhollow", "bellchime",  8 },
	{ "dustbowl",    "dunebud",    6 },
	{ "dustbowl",    "paddlehop",  7 },
	{ "dustbowl",    "thornwhorl", 7 },
	{ "dustbowl",    "raincup",    9 },
	{ "dustbowl",    "suncrown",  13 },
	{ "tanglemire",  "bogbonnet",  7 },
	{ "tanglemire",  "crookreed",  8 },
	{ "tanglemire",  "snapmoss",  10 },
	{ "tanglemire",  "lanterncap", 14 },
	{ "tanglemire",  "gloomlotus", 24 },
	{ "emberroot",   "cinderpaw",  8 },
	{ "emberroot",   "emberquill", 9 },
	{ "emberroot",   "slagbloom", 10 },
	{ "emberroot",   "kilnhusk",  16 },
	{ "emberroot",   "pyrelotus", 26 },
	{ "starbloom",   "novaorb",    9 },
	{ "starbloom",   "cosmospire",10 },
	{ "starbloom",   "voidpetal", 11 },
	{ "starbloom",   "astralhorn",17 },
	{ "starbloom",   "supernovus",28 },
}

-- The six the owner singled out, and the flat dollars they add.
local BONUS = {
	petalpip = 1, paddlehop = 1, crookreed = 1,
	emberquill = 1, novaorb = 1, cosmospire = 2,
}

--==============================================================================
-- 1. EVERY TINY RATE IS THE APPROVED ONE
--==============================================================================
say("\n-- the approved Tiny earnings --")
do
	local allOk, biomeOk = true, true
	local detail = ""
	for _, row in ipairs(TINY) do
		local biome, id, want = row[1], row[2], row[3]
		local species = SeedData.Get(id)
		if not species then
			allOk = false
			detail ..= " missing " .. id
		else
			if species.Biome ~= biome then
				biomeOk = false
				detail ..= string.format(" %s in %s", id, species.Biome)
			end
			local got = SeedData.IncomePerSecond(species, 1)
			if got ~= want then
				allOk = false
				detail ..= string.format(" %s=%d want %d", id, got, want)
			end
		end
	end
	check(allOk, "all 25 species pay their approved Tiny rate", detail)
	check(biomeOk, "and each one is in the biome the table says", detail)
	check(#TINY == 25, "the table covers twenty-five species", #TINY)

	-- Nothing else moved: the whole sheet is still whole numbers that rise with
	-- rarity inside a biome.
	local wholeOk = true
	for _, row in ipairs(TINY) do
		local n = SeedData.IncomePerSecond(SeedData.Get(row[2]), 1)
		if math.floor(n) ~= n or n <= 0 then
			wholeOk = false
		end
	end
	check(wholeOk, "every rate is a whole number of dollars")
end

--==============================================================================
-- 2. THE SIX BONUSES, EXACTLY, AND NOBODY ELSE
--==============================================================================
say("\n-- the bonuses --")
do
	local fieldOk, othersOk = true, true
	local detail = ""
	for _, biome in ipairs({ "greenhollow", "dustbowl", "tanglemire", "emberroot", "starbloom" }) do
		for _, species in ipairs(SeedData.InBiome(biome)) do
			local want = BONUS[species.Id] or 0
			local got = (species :: any).IncomeBonus or 0
			if got ~= want then
				if want > 0 then
					fieldOk = false
				else
					othersOk = false
				end
				detail ..= string.format(" %s=%s want %d", species.Id, tostring(got), want)
			end
		end
	end
	check(fieldOk, "Petalpip, Paddlehop, Crookreed, Emberquill and Novaorb carry +$1, "
		.. "Cosmospire +$2", detail)
	check(othersOk, "and every other species carries nothing at all", detail)

	-- The field is optional, so the unaffected ones do not even have it.
	local absent = 0
	for _, biome in ipairs({ "greenhollow", "dustbowl", "tanglemire", "emberroot", "starbloom" }) do
		for _, species in ipairs(SeedData.InBiome(biome)) do
			if (species :: any).IncomeBonus == nil then
				absent += 1
			end
		end
	end
	check(absent == 19, "nineteen species have no IncomeBonus field at all", absent)
end

--==============================================================================
-- 3 AND 4. THE OLD CALCULATION, PLUS A FLAT BONUS, AT EVERY TIER
--
-- The formula is recomputed here from the tier sheet and the two multiplier
-- tables -- deliberately NOT by calling the function under test -- so an
-- unaffected species is proved to be untouched, and a bonused one is proved to
-- add the same dollar at Colossal as at Tiny rather than scaling with the tier.
--==============================================================================
say("\n-- the formula, tier by tier --")
do
	local function expected(species, tier)
		local base = SeedData.Tier(tier).value * GameConfig.Carry.CashPerValue
		local rarity = SeedData.RarityMultiplier[species.Rarity]
		local biome = SeedData.BiomeMultiplier[species.Biome]
		return math.floor(base * rarity * biome + 0.5)
	end

	local plainOk, bonusOk, flatOk = true, true, true
	local detail = ""
	local sampled = 0
	for _, row in ipairs(TINY) do
		local species = SeedData.Get(row[2])
		local want = BONUS[species.Id] or 0
		for tier = 1, SeedData.TierCount do
			local got = SeedData.IncomePerSecond(species, tier)
			local base = expected(species, tier)
			sampled += 1
			if want == 0 then
				if got ~= base then
					plainOk = false
					detail ..= string.format(" %s T%d=%d want %d", species.Id, tier, got, base)
				end
			else
				if got ~= base + want then
					bonusOk = false
					detail ..= string.format(" %s T%d=%d want %d", species.Id, tier, got, base + want)
				end
				if got - base ~= want then
					flatOk = false
				end
			end
		end
	end
	check(plainOk, "the nineteen unaffected species are exactly tier x rarity x biome, rounded", detail)
	check(bonusOk, "and the six are that, plus their flat bonus", detail)
	check(flatOk, "which is the SAME dollar at Colossal as at Tiny -- it does not scale")
	check(sampled == 25 * SeedData.TierCount,
		string.format("checked %d species-tier combinations", sampled))

	-- A Colossal Cosmospire earns two dollars more than the formula, not 2x7.6.
	local cos = SeedData.Get("cosmospire")
	check(SeedData.IncomePerSecond(cos, 7) - expected(cos, 7) == 2,
		"a Colossal Cosmospire is +$2, not +$15",
		SeedData.IncomePerSecond(cos, 7) - expected(cos, 7))

	-- And the bonus survives a junk species or tier without throwing.
	local ok = pcall(function()
		return SeedData.IncomePerSecond(nil, 1) + SeedData.IncomePerSecond(4, 1)
			+ SeedData.IncomePerSecond(cos, nil) + SeedData.IncomePerSecond(cos, 0 / 0)
	end)
	check(ok and SeedData.IncomePerSecond(nil, 1) > 0,
		"an unknown species still pays the base rate rather than throwing or zeroing")
end

--==============================================================================
-- 5. THE STALL FOLLOWS THE RATE
--==============================================================================
say("\n-- sell price --")
do
	local followsOk, bonusOk = true, true
	local detail = ""
	for _, row in ipairs(TINY) do
		local species = SeedData.Get(row[2])
		for tier = 1, SeedData.TierCount do
			local income = SeedData.IncomePerSecond(species, tier)
			if SeedData.SellPrice(species, tier) ~= income * SeedData.SellSeconds then
				followsOk = false
				detail ..= string.format(" %s T%d", species.Id, tier)
			end
		end
	end
	-- A bonused plant is worth SellSeconds more of it at the stall, which is the
	-- whole reason SellPrice is derived rather than written down.
	local petalpip = SeedData.SellPrice(SeedData.Get("petalpip"), 1)
	local nubkin = SeedData.SellPrice(SeedData.Get("nubkin"), 1)
	if petalpip - nubkin ~= SeedData.SellSeconds then
		bonusOk = false
	end
	check(followsOk, "every sell price is exactly SellSeconds of the plant's own rate", detail)
	check(bonusOk, string.format("so Petalpip sells for $%d more than Nubkin, which is %d x $1",
		petalpip - nubkin, SeedData.SellSeconds))
end

--==============================================================================
-- 6. THE x2 PASS DOUBLES THE RESULT, ONCE
--==============================================================================
say("\n-- the x2 Earn pass --")
do
	local species = SeedData.Get("cosmospire")
	local plain = PlantInfo.Describe(species.Id, 4, true, 1)
	local doubled = PlantInfo.Describe(species.Id, 4, true, 2)
	local rate = SeedData.IncomePerSecond(species, 4)
	check(plain.incomePerSecond == rate,
		"with no pass, the readout is the plant's own rate", plain.incomePerSecond)
	check(doubled.incomePerSecond == rate * 2,
		"with the pass, exactly twice it -- bonus included, counted once",
		doubled.incomePerSecond)

	-- SeedData itself must stay pass-agnostic, or the doubling would happen twice.
	local function sourceOf(instance)
		if instance == nil then
			return nil
		end
		local ok, src = pcall(function()
			return (instance :: any).Source
		end)
		return if ok then src else nil
	end
	local seed = sourceOf(Shared:FindFirstChild("SeedData"))
	check(seed ~= nil and not seed:find("CashMultiplier", 1, true),
		"SeedData never reads the pass multiplier")
	local server = ServerScriptService:FindFirstChild("SeedGameServer")
	local economy = sourceOf(server and server:FindFirstChild("EconomyService"))
	local applications = if economy then select(2, economy:gsub("PassService.CashMultiplier", "")) else -1
	check(applications == 1,
		"and the faucet applies it in exactly one place", applications)
end

--==============================================================================
-- 7, 8 AND 9. THE OVERCLOCK LADDER
--==============================================================================
say("\n-- overclock prices --")
local APPROVED = {
	125_000_000_000, 150_000_000_000, 180_000_000_000, 220_000_000_000,
	270_000_000_000, 330_000_000_000, 400_000_000_000, 500_000_000_000,
	650_000_000_000, 850_000_000_000,
}
do
	local tiers = GameConfig.Mill.Tiers
	local topMill = tiers[#tiers].cost
	check(#tiers == 10 and topMill == 100_000_000_000,
		"the tier-10 mill still costs exactly $100B", topMill)

	local O = GameConfig.Mill.Overclock
	check(O.MaxLevel == 10, "there are ten overclock levels", O.MaxLevel)
	check(#O.Costs == 10, "and ten prices", #O.Costs)
	check(O.Multiplier == 2, "each one still doubles the rate", O.Multiplier)

	local exactOk, aboveOk, risingOk = true, true, true
	local detail = ""
	for level, want in ipairs(APPROVED) do
		local got = O.Costs[level]
		if got ~= want then
			exactOk = false
			detail ..= string.format(" %d=%s want %d", level, tostring(got), want)
		end
		if not (got and got > topMill) then
			aboveOk = false
			detail ..= string.format(" %d not above the mill", level)
		end
		if level > 1 and not (got and O.Costs[level - 1] and got > O.Costs[level - 1]) then
			risingOk = false
			detail ..= string.format(" %d not above %d", level, level - 1)
		end
	end
	check(exactOk, "125 / 150 / 180 / 220 / 270 / 330 / 400 / 500 / 650 / 850 billion", detail)
	check(aboveOk, "every level costs more than the mill it runs on", detail)
	check(risingOk, "and more than the level before it", detail)

	local total = 0
	for _, cost in ipairs(O.Costs) do
		total += cost
	end
	check(total == 3_675_000_000_000,
		string.format("all ten cost $%s together", GameConfig.compact(total)), total)

	-- The purchase path and the sign read these and nothing else.
	local costOk = true
	for level = 1, 10 do
		if GameConfig.overclockCostFor(level) ~= APPROVED[level] then
			costOk = false
		end
	end
	check(costOk, "overclockCostFor answers the same list")
	check(GameConfig.overclockCostFor(11) == nil and GameConfig.overclockCostFor(0) == nil,
		"and nothing past the end of it")

	-- WHAT THE MILL SIGN WILL SAY. TreadmillService prints
	-- "$" .. GameConfig.compact(stepInfo.cost), so this is the text itself.
	local signs = {}
	for level = 1, 10 do
		signs[level] = "$" .. GameConfig.compact(O.Costs[level])
	end
	check(signs[1] == "$125B" and signs[10] == "$850B",
		"the sign reads $125B on the first overclock and $850B on the last",
		signs[1] .. " .. " .. signs[10])
	check(table.concat(signs, " ") == "$125B $150B $180B $220B $270B $330B $400B $500B $650B $850B",
		"and every rung in between", table.concat(signs, " "))
end

--==============================================================================
-- 10. WHAT AN OVERCLOCK BUYS IS UNCHANGED
--==============================================================================
say("\n-- overclock rates --")
do
	local multOk, rateOk = true, true
	local detail = ""
	local topSpeed = GameConfig.Mill.Tiers[10].speed
	for level = 0, 10 do
		local want = 2 ^ level
		local got = GameConfig.overclockMultiplierFor(level)
		if got ~= want then
			multOk = false
			detail ..= string.format(" L%d=%s want %s", level, tostring(got), tostring(want))
		end
		if GameConfig.trainingRateFor(10, level, nil) ~= topSpeed * want then
			rateOk = false
			detail ..= string.format(" rate L%d", level)
		end
	end
	check(multOk, "the multiplier is still 2^level, 1x to 1024x", detail)
	check(rateOk, string.format("so a tier-10 mill still runs %s/s to %s/s",
		GameConfig.compact(topSpeed), GameConfig.compact(topSpeed * 1024)), detail)
	check(GameConfig.overclockMultiplierFor(0) == 1
			and GameConfig.overclockMultiplierFor(-3) == 1
			and GameConfig.overclockMultiplierFor(99) == 1024,
		"and a junk level reads as no overclock, or as the last one")
end

say(string.format("\nBalanceSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
