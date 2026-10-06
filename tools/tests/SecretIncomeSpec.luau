--!nocheck
--==============================================================================
-- Steal a Seed :: SecretIncomeSpec
--
-- The owner's approved FIXED rates for the two Secrets (2026-10-02): a
-- Snarlbloom pays $155,000/s and a Petalfawn $189,000/s, final and unboosted,
-- whatever tier its Tool or row carries -- never multiplied again by size,
-- rarity or biome. Boosts apply once, in EconomyService.RateFor (the x2 pass:
-- $310,000/s and $378,000/s). The sale follows the existing rule (SellPrice:
-- thirty seconds of income). The displays show the Secret rarity and no size.
-- A saved Secret row comes back with its identity, and earns the same rate,
-- once, under the offline rule. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("SecretIncomeSpec"))
--
-- The pay rate runs the REAL EconomyService.RateFor with its lookups (the plot,
-- the garden, the pass, the two boosts) answered by stand-ins and put back.
-- Not here: a real plot paying in Play (the throwaway-store Play does that).
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local PlantInfo = require(Shared.PlantInfo)
local EconomyService = require(Server.EconomyService)
local PlotService = require(Server.PlotService)
local PlantService = require(Server.PlantService)
local PassService = require(Server.PassService)
local BonusChestService = require(Server.BonusChestService)
local SacrificeService = require(Server.SacrificeService)
local ProfileSchema = require(Server.ProfileSchema)
local OfflineEarnings = require(Server.OfflineEarnings)

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (detail ~= nil and ("  <- " .. tostring(detail)) or ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end

local SNARL, PETAL = SeedData.Get("snarlbloom"), SeedData.Get("petalfawn")
local plots: any, plants: any, passes: any = PlotService, PlantService, PassService
local chest: any, sacrifice: any = BonusChestService, SacrificeService
local real = {
	PlotOf = plots.PlotOf, OwnerOf = plots.OwnerOf, GrownIn = plants.GrownIn,
	CashMultiplier = passes.CashMultiplier, Chest = chest.Multiplier, Sacrifice = sacrifice.Multiplier,
}

local ok, err = pcall(function()
	--==========================================================================
	say("1. The approved rates, at every tier")
	--==========================================================================
	check(SNARL.FixedIncome == 155000 and PETAL.FixedIncome == 189000,
		"the balance data holds the approved rates: Snarlbloom 155,000, Petalfawn 189,000 ($/s)")
	local everyTier = true
	for tier = 1, SeedData.TierCount do
		if SeedData.IncomePerSecond(SNARL, tier) ~= 155000 or SeedData.IncomePerSecond(PETAL, tier) ~= 189000 then
			everyTier = false
		end
	end
	check(everyTier, "IncomePerSecond answers exactly the rate at every tier a Tool or a saved row can carry -- "
		.. "no size, rarity or biome factor on top")
	local fixedListed = 0
	for _, species in ipairs(SeedData.Species) do
		if species.FixedIncome ~= nil then
			fixedListed += 1
		end
	end
	check(fixedListed == 0, "no listed species has a fixed rate: normal income is untouched", fixedListed)
	local nubkin = SeedData.Get("nubkin")
	check(SeedData.IncomePerSecond(nubkin, 1) == 4 and SeedData.IncomePerSecond(nubkin, SeedData.TierCount) == 9500,
		"an ordinary plant still pays by its tier (Nubkin: $4/s Tiny, $9,500/s Colossal)")
	check(SeedData.SecretTier == 1, "the Secrets' internal tier is still the one tier (implementation only)")

	--==========================================================================
	say("2. The sale follows the existing rule: thirty seconds of income")
	--==========================================================================
	check(SeedData.SellSeconds == 30 and SeedData.SellPrice(SNARL, 1) == 155000 * 30
			and SeedData.SellPrice(PETAL, 1) == 189000 * 30 and SeedData.SellPrice(PETAL, 7) == 189000 * 30,
		string.format("SellPrice is IncomePerSecond x SellSeconds: Snarlbloom $%d, Petalfawn $%d, at any tier",
			SeedData.SellPrice(SNARL, 1), SeedData.SellPrice(PETAL, 1)))

	--==========================================================================
	say("3. Paid once, through EconomyService.RateFor")
	--==========================================================================
	local payer = { Name = "SpecPayer", UserId = 9001 }
	local plot = Instance.new("Model")
	local grown = {}
	local passMul, chestMul, sacrificeMul = 1, 1, 1
	plots.PlotOf = function(p)
		return if p == payer then plot else nil
	end
	plots.OwnerOf = function(m)
		return if m == plot then payer else nil
	end
	plants.GrownIn = function(m)
		return if m == plot then grown else {}
	end
	passes.CashMultiplier = function()
		return passMul
	end
	chest.Multiplier = function()
		return chestMul
	end
	sacrifice.Multiplier = function()
		return sacrificeMul
	end
	grown = { { species = SNARL, tier = 1 } }
	local snarlRate = EconomyService.RateFor(payer)
	grown = { { species = PETAL, tier = 1 } }
	local petalRate = EconomyService.RateFor(payer)
	check(snarlRate == 155000 and petalRate == 189000, "unboosted: $155,000/s and $189,000/s",
		snarlRate .. " / " .. petalRate)
	passMul = 2
	grown = { { species = SNARL, tier = 1 } }
	local snarlPass = EconomyService.RateFor(payer)
	grown = { { species = PETAL, tier = 1 } }
	local petalPass = EconomyService.RateFor(payer)
	check(snarlPass == 310000 and petalPass == 378000, "with the permanent x2 pass: $310,000/s and $378,000/s",
		snarlPass .. " / " .. petalPass)
	grown = { { species = SNARL, tier = 7 }, { species = PETAL, tier = 4 } }
	local mixed = EconomyService.RateFor(payer)
	check(mixed == (155000 + 189000) * 2,
		"copies carrying other tiers (an older save) pay the same approved rates", mixed)
	chestMul = 1.25
	grown = { { species = SNARL, tier = 1 } }
	local boosted = EconomyService.RateFor(payer)
	check(boosted == 155000 * 2 * 1.25, "a temporary boost still applies once, on top of the pass", boosted)
	plot:Destroy()

	--==========================================================================
	say("4. What the screens say: Secret rarity, the right income, no size")
	--==========================================================================
	local plantInfo = PlantInfo.Describe("snarlbloom", 1, true, 2)
	check(plantInfo.incomePerSecond == 310000 and plantInfo.rarity == "Secret" and plantInfo.sized == false
			and plantInfo.size == "" and plantInfo.sellValue == 155000 * 30,
		"a grown Snarlbloom in the Bag: Secret, +$310K/s under the pass, no size row, the stall's price",
		plantInfo.income .. " " .. tostring(plantInfo.size))
	local olderCopy = PlantInfo.Describe("petalfawn", 7, true, 1)
	check(olderCopy.incomePerSecond == 189000 and olderCopy.sized == false,
		"an older Petalfawn saved at another tier reads the same rate and no size")
	local secretPod = PlantInfo.Describe("snarlbloom", 1, false, 1)
	check(secretPod.title == "Secret pod" and secretPod.rarity == "Secret" and secretPod.sized == false
			and secretPod.incomePerSecond == nil,
		"a Secret pod reads Secret pod, its rarity, no size, and no income until it hatches")
	local ordinary = PlantInfo.Describe("nubkin", 1, true, 1)
	check(ordinary.sized == true and ordinary.size == SeedData.TierName(1) and ordinary.incomePerSecond == 4,
		"an ordinary plant's card is unchanged (its size row, its tier's income)")
	check(PlantInfo.SizeWord("snarlbloom", 1) == nil and PlantInfo.SizeWord("nubkin", 1) == SeedData.TierName(1)
			and PlantInfo.SizeColour("petalfawn", 1) == GameConfig.RarityColor.Secret
			and PlantInfo.SizeColour("nubkin", 1) == SeedData.ColorForTier(1),
		"one helper says a Secret has no size word and wears the Secret colour; everything else its tier's")
	local carrySrc = sourceOf(Server, "CarryService")
	check(string.find(carrySrc, 'then (if hatched then "Secret" else "Secret pod")', 1, true) ~= nil,
		"a Secret's Tool tooltip says Secret or Secret pod -- no tier")
	local hatchSrc = sourceOf(Scripts, "HatchFX")
	-- Since 2026-10-02 the rule is "unsized" (a Secret, or the Rain event's Pod 1
	-- and Pod 3 forms), and every Secret is unsized.
	check(string.find(hatchSrc, "if SeedData.Unsized(species) then species.Rarity:upper()", 1, true) ~= nil
			and SeedData.Unsized(SeedData.Get("snarlbloom")) and SeedData.Unsized(SeedData.Get("petalfawn"))
			and not SeedData.Unsized(SeedData.Get("nubkin")),
		"the hatch reveal's line says SECRET, with no size word")
	local gardenSrc = sourceOf(Scripts, "GardenUI")
	-- MY PLANTS (2026-10-04) draws every card with the Bag's own face, so a
	-- Secret's card reads its rarity and no size, and its pod its own shell
	-- (InventoryModel, checked just below).
	check(string.find(gardenSrc, "face = InventoryModel.face(item)", 1, true) ~= nil
			and string.find(gardenSrc, "local function creature(speciesId: string, tier: number, hatched: boolean)", 1, true) ~= nil,
		"MY PLANTS shows a Secret through the Bag's face: no weight tag, its own pod")
	local sellSrc = sourceOf(Scripts, "SellUI")
	check(string.find(sellSrc, "metaLabel.Text = if info.sized", 1, true) ~= nil,
		"SELL ONE's line shows a Secret's rarity alone")
	-- The compact Bag (2026-10-03): its tiles and details come from InventoryModel.
	local InventoryModel = require(game:GetService("ReplicatedStorage").SeedGame.Shared.InventoryModel)
	local secretItem = { ref = "i:1", kind = "plant", speciesId = "snarlbloom", tier = 1, hatched = true, sealed = false,
		restoring = false, count = 1, worn = false, favourite = false, order = 1 }
	local secretFace = InventoryModel.face(secretItem)
	local sizeLine = false
	for _, line in ipairs(InventoryModel.details(secretItem, secretFace, nil, nil, false)) do
		if line.key == "Size" then
			sizeLine = true
		end
	end
	check(not sizeLine and secretFace.variant == "Secret"
			and secretFace.variantColour == PlantInfo.SizeColour("snarlbloom", 1),
		"the Bag shows a Secret no Size line, and names its rarity in the rarity's colour")

	--==========================================================================
	say("5. A saved Secret comes back as itself")
	--==========================================================================
	local raw = ProfileSchema.Sanitise(nil)
	raw.Held = {
		{ Id = "snarlbloom", Tier = 1, Hatched = false },
		{ Id = "petalfawn", Tier = 7, Hatched = true },
	}
	raw.Plants = {
		{ SpeciesId = "petalfawn", Tier = 1, Stage = 3, X = 2, Z = -3, PlantedAt = 1000, HatchAt = 1030, Facing = 0 },
	}
	local back = ProfileSchema.Sanitise(raw)
	local held = back.Held or {}
	local garden = back.Plants or {}
	check(#held == 2 and held[1].Id == "snarlbloom" and held[1].Hatched == false and held[2].Id == "petalfawn"
			and held[2].Hatched == true and held[2].Tier == 7,
		"the bag's Secret rows survive the validator with their species, form and saved tier", #held)
	check(#garden == 1 and garden[1].SpeciesId == "petalfawn"
			and SeedData.IncomePerSecond(SeedData.Get(garden[1].SpeciesId), garden[1].Tier) == 189000,
		"a planted Secret survives it too, and pays the approved rate when it is back in the ground", #garden)

	--==========================================================================
	say("6. Away from the game: the same rate, once, under the existing offline rule")
	--==========================================================================
	local OFF = SeedData.Offline
	local GROWN = require(Shared.CreatureModel).STAGE_GROWN
	local away = OfflineEarnings.garden({
		{ SpeciesId = "snarlbloom", Tier = 4, Stage = GROWN },
		{ SpeciesId = "petalfawn", Tier = 1, Stage = GROWN - 1 },
	})
	check(away.rate == 155000 and away.grown == 1,
		"the offline garden counts a grown Snarlbloom at $155,000/s and a Secret still in its pod at nothing",
		away.rate)
	local profile = { LastSeen = 10000, Plants = { { SpeciesId = "snarlbloom", Tier = 1, Stage = GROWN } } }
	local cash, seconds = OfflineEarnings.accrue(profile, 10000 + 3600)
	check(cash == 155000 * 3600 * OFF.Efficiency and seconds == 3600,
		string.format("an hour away credits $%d (the rate x %s efficiency, before the pass, which the claim applies)",
			cash, tostring(OFF.Efficiency)), cash)
end)

plots.PlotOf, plots.OwnerOf, plants.GrownIn = real.PlotOf, real.OwnerOf, real.GrownIn
passes.CashMultiplier, chest.Multiplier, sacrifice.Multiplier = real.CashMultiplier, real.Chest, real.Sacrifice
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("SecretIncomeSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
