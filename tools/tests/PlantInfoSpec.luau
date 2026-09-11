--!strict
--==============================================================================
-- Steal a Seed :: PlantInfoSpec
--
-- The Bag's plant information panel, held to the economy. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PlantInfoSpec"))
--
-- Pure data: every species at every tier, grown and unhatched, against the same
-- calls EconomyService pays from, the Garden prints, and the stall prices with.
-- The panel's layout, selection and animation are verified in Play.
--==============================================================================
local Shared = game.ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local BiomeData = require(Shared.BiomeData)
local PlantInfo = require(Shared.PlantInfo)

local pass = 0
local fails: { string } = {}
local function check(ok: boolean, label: string)
	if ok then
		pass += 1
	else
		table.insert(fails, label)
	end
end

local function fields(info: PlantInfo.Info): { string }
	return { info.title, info.stage, info.biome, info.rarity, info.size, info.income, info.sell or "" }
end

--== 1. GROWN: every species x tier x multiplier ==============================
local combos, wrong = 0, {}
for _, species in ipairs(SeedData.Species) do
	for tier = 1, SeedData.TierCount do
		for _, mult in ipairs({ 1, 2 }) do
			combos += 1
			local info = PlantInfo.Describe(species.Id, tier, true, mult)
			local rate = SeedData.IncomePerSecond(species, tier) * mult
			local why: string? = nil
			if info.incomePerSecond ~= rate then
				why = "income number"
			elseif info.income ~= "+$" .. GameConfig.compact(rate) .. "/s" then
				why = "income text"
			elseif info.sellValue ~= SeedData.SellPrice(species, tier)
				or info.sell ~= "$" .. GameConfig.compact(SeedData.SellPrice(species, tier)) then
				why = "sell value"
			elseif info.title ~= species.Name or info.rarity ~= species.Rarity or info.stage ~= "Grown" then
				why = "title/rarity/stage"
			elseif info.size ~= SeedData.TierName(tier) or info.sizeColour ~= SeedData.ColorForTier(tier) then
				why = "size"
			elseif info.biome ~= BiomeData.ById[species.Biome].DisplayName then
				why = "biome"
			elseif info.rarityColour ~= GameConfig.RarityColor[species.Rarity] then
				why = "rarity colour"
			end
			for _, text in ipairs(fields(info)) do
				if not why and string.find(text, species.Id, 1, true) then
					why = "internal id shown"
				end
			end
			if not why and string.match(info.size, "%d") then
				why = "raw tier number shown"
			end
			if why then
				table.insert(wrong, string.format("%s t%d x%d: %s", species.Id, tier, mult, why))
			end
		end
	end
end
check(combos == #SeedData.Species * SeedData.TierCount * 2, "covered every species, tier and multiplier")
check(#wrong == 0, "grown plants match IncomePerSecond x multiplier, SellPrice and the sheet ("
	.. #wrong .. " wrong: " .. table.concat(wrong, "; ", 1, math.min(#wrong, 3)) .. ")")

--== 2. THE GARDEN'S CONVENTION, EXACTLY ======================================
do
	local fakePlayer: any = { GetAttribute = function() return 2 end }
	local mult = GameConfig.cashMultiplier(fakePlayer)
	local species = SeedData.Get("novaorb") or SeedData.Species[1]
	local info = PlantInfo.Describe(species.Id, 4, true, mult)
	check(mult == 2 and info.incomePerSecond == SeedData.IncomePerSecond(species, 4) * mult,
		"same product the Garden prints: IncomePerSecond x cashMultiplier")
	local plain = PlantInfo.Describe(species.Id, 4, true, GameConfig.cashMultiplier(nil))
	check(plain.incomePerSecond == SeedData.IncomePerSecond(species, 4), "no pass: the plant's own rate")
end

--== 3. UNHATCHED PODS LEAK NOTHING ===========================================
local leaks = {}
for _, species in ipairs(SeedData.Species) do
	for tier = 1, SeedData.TierCount do
		local info = PlantInfo.Describe(species.Id, tier, false, 2)
		local why: string? = nil
		if info.title ~= PlantInfo.PodTitle or info.rarity ~= PlantInfo.Unknown then
			why = "title/rarity"
		elseif info.incomePerSecond ~= nil or info.sell ~= nil or info.sellValue ~= nil then
			why = "priced"
		elseif string.find(info.income, "%$") or string.match(info.income, "%d") then
			why = "income number"
		elseif info.size ~= SeedData.TierName(tier) then
			why = "size"
		end
		for _, text in ipairs(fields(info)) do
			if not why and (string.find(text, species.Name, 1, true) or string.find(text, species.Id, 1, true)) then
				why = "species named"
			end
			if not why and text == species.Rarity then
				why = "rarity named"
			end
		end
		if why then
			table.insert(leaks, string.format("%s t%d: %s", species.Id, tier, why))
		end
	end
end
check(#leaks == 0, "a pod shows only size and biome (" .. #leaks .. " leaks: "
	.. table.concat(leaks, "; ", 1, math.min(#leaks, 3)) .. ")")

--== 4. BAD INPUT ==============================================================
do
	local species = SeedData.Species[1]
	local base = SeedData.IncomePerSecond(species, 1)
	for _, m in ipairs({ 0, 0.5, -3 }) do
		check(PlantInfo.Describe(species.Id, 1, true, m).incomePerSecond == base,
			"multiplier " .. tostring(m) .. " reads as 1")
	end
	check(PlantInfo.Describe(species.Id, 1, true, nil).incomePerSecond == base, "nil multiplier reads as 1")
	check(PlantInfo.Describe(species.Id, 1, true, 0 / 0).incomePerSecond == base, "NaN multiplier reads as 1")
	for _, t in ipairs({ 0, 99, -4 }) do
		local ok, info = pcall(PlantInfo.Describe, species.Id, t, true, 1)
		check(ok and SeedData.Tier(t).name == info.size, "tier " .. tostring(t) .. " clamps to a named size")
	end
	local okNil, nilInfo = pcall(PlantInfo.Describe, species.Id, nil, true, 1)
	check(okNil and nilInfo.size == SeedData.TierName(1), "nil tier reads as the smallest size")
	local okUnknown, unknown = pcall(PlantInfo.Describe, "not_a_species", 3, true, 1)
	check(okUnknown and unknown.incomePerSecond == nil and unknown.rarity == PlantInfo.Unknown,
		"an unknown species is priced at nothing and named nothing")
end

--== 5. STATUS AND BACKDROP ===================================================
check(PlantInfo.Status(true, 3) == "In hand", "in hand outranks a hotbar slot")
check(PlantInfo.Status(false, 3) == "Hotbar slot 3", "an auto-filled slot is named")
check(PlantInfo.Status(false, nil) == "In your bag", "otherwise it is in the bag")
local missingArt = {}
for _, species in ipairs(SeedData.Species) do
	if PlantInfo.Backdrop(species.Id, true) ~= GameConfig.Card.Art[species.Id]
		or GameConfig.Card.Art[species.Id] == nil then
		table.insert(missingArt, species.Id)
	end
	check(PlantInfo.Backdrop(species.Id, false) == nil, species.Id .. " pod has no backdrop")
end
check(#missingArt == 0, "every grown species has its biome backdrop (" .. table.concat(missingArt, ", ") .. ")")
check(PlantInfo.Backdrop("not_a_species", true) == nil, "unknown species has no backdrop")

if #fails > 0 then
	return ("PlantInfoSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails, table.concat(fails, "\n  "))
end
return ("PlantInfoSpec: %d passed, 0 failed (%d grown combinations)"):format(pass, combos)
