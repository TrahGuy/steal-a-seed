--!nocheck
--==============================================================================
-- Steal a Seed :: RainPodsSpec
--
-- The Rain event's supplied pods, creatures and guardian (2026-10-02): the
-- exact name-to-pod mapping and rates; Pod 2 as the same three creatures at
-- their larger forms, shown Colossal; fixed incomes and growth times; one batch
-- per event -- three slots each drawn on its own, Pod 1 90% / the Colossal Pod 2
-- 10% (the owner's odds, 2026-10-05; a coin flip before), or one Pod
-- 3 -- and each pod's creature drawn evenly; the shell naming only its pod;
-- the event-only silhouette-roll bypass; Pod 3's half-speed carry; the event
-- nest laid, guarded by Stormstrider at its supplied size, kept out of the
-- road's restock, dusk and counts, and taken down whole; Stormstrider's chase
-- at 2.5 x Astralmaw's, and its sleeping body ON the floor (first lie-down
-- and again after a walk home); every form built at its supplied size whatever its
-- tier, walking on its own legs and resting exactly as authored; the save
-- keeping every form; and the console's START THUNDERSTORM. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("RainPodsSpec"))
--
-- Not here, seen in the guarded Play session instead: the real theft, chase,
-- catch, drop and banking; Pod 3's WalkSpeed on a real character; the
-- thunderstorm's look on screen; a hatch, a placement and a walk in a garden.
--==============================================================================
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local PlantInfo = require(Shared.PlantInfo)
local RainForms = require(Shared.RainForms)
local SecretIdle = require(Shared.SecretIdle)
local SecretModel = require(Shared.SecretModel)
local CreatureModel = require(Shared.CreatureModel)
local NestService = require(Server.NestService)
local WeatherService = require(Server.WeatherService)
local ProfileSchema = require(Server.ProfileSchema)

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
local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-6)
end

local W = GameConfig.Weather
local scratch = Instance.new("Folder")
scratch.Name = "ZZRainPodsSpec"
scratch.Parent = Workspace

-- The owner's table, as approved: pod -> { creature id, display name, $/s }.
local MAPPING = {
	rainpod1 = { { "puddlepod", "Puddlepod", 80000 }, { "drizzlet", "Drizzlet", 85000 }, { "lotusling", "Lotusling", 90000 } },
	rainpod2 = { { "puddlepod_colossal", "Puddlepod", 120000 }, { "drizzlet_colossal", "Drizzlet", 135000 },
		{ "lotusling_colossal", "Lotusling", 150000 } },
	rainpod3 = { { "tempestoak", "Tempestoak", 250000 }, { "thundermaw", "Thundermaw", 265000 } },
}
local POD = {
	rainpod1 = { rarity = "Mythic", tier = 1, sized = false, grow = 10800 },
	rainpod2 = { rarity = "Mythic", tier = 7, sized = true, grow = 21600 },
	rainpod3 = { rarity = "Divine", tier = 1, sized = false, grow = 32400 },
}

-- Every part's corners, in `frame`'s space: the drawn (visible) extents.
local function extents(model, frame, visibleOnly)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and (not visibleOnly or d.Transparency < 0.999) then
			local h = d.Size / 2
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local c = frame:PointToObjectSpace((d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position)
						lo = lo:Min(c)
						hi = hi:Max(c)
					end
				end
			end
		end
	end
	return lo, hi
end

-- How far the worst joint is from agreeing with the parts it holds: a joint
-- that disagrees would move a part off its authored spot the moment anything
-- poses the rig.
local function jointDisagreement(model)
	local worst = 0
	for _, d in ipairs(model:GetDescendants()) do
		if (d:IsA("Motor6D") or d:IsA("Weld")) and d.Part0 and d.Part1 then
			local a = d.Part0.CFrame * d.C0
			local b = d.Part1.CFrame * d.C1
			worst = math.max(worst, (a.Position - b.Position).Magnitude)
		end
	end
	return worst
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The mapping, the rates, the rarities, the growth -- as the owner set them")
	--==========================================================================
	local bad = {}
	for podId, roster in pairs(MAPPING) do
		local pod = SeedData.RainPods[podId]
		local want = POD[podId]
		if not pod or pod.Rarity ~= want.rarity or pod.Tier ~= want.tier or pod.Sized ~= want.sized
			or pod.GrowSeconds ~= want.grow or #pod.Species ~= #roster then
			table.insert(bad, podId .. " pod row")
		end
		for i, row in ipairs(roster) do
			local sp = SeedData.Get(row[1])
			if not sp then
				table.insert(bad, row[1] .. " missing")
				continue
			end
			if pod and pod.Species[i] ~= row[1] then
				table.insert(bad, row[1] .. " roster order")
			end
			if sp.Name ~= row[2] or sp.FixedIncome ~= row[3] or sp.Pod ~= podId or sp.Rarity ~= want.rarity
				or sp.FixedGrowSeconds ~= want.grow or sp.Event ~= "rain" or sp.SkipHatchRoll ~= true
				or sp.Carry ~= "overhead" or sp.Animator ~= "secret" or sp.Secret == true
				or (sp.Unsized == true) == want.sized or not RainForms.Plants[row[1]] then
				table.insert(bad, row[1])
			end
			-- Final and unboosted: every tier pays exactly the owner's rate, and
			-- the stall pays its usual SellSeconds of it.
			for tier = 1, SeedData.TierCount do
				if SeedData.IncomePerSecond(sp, tier) ~= row[3] or SeedData.GrowSecondsFor(sp, tier) ~= want.grow then
					table.insert(bad, row[1] .. " tier " .. tier)
					break
				end
			end
			if SeedData.SellPrice(sp, want.tier) ~= row[3] * SeedData.SellSeconds then
				table.insert(bad, row[1] .. " sell")
			end
		end
	end
	check(#bad == 0, "Pod 1 Puddlepod/Drizzlet/Lotusling $80k/$85k/$90k Mythic 3 h; Pod 2 the same three $120k/$135k/$150k "
		.. "Mythic Colossal 6 h; Pod 3 Tempestoak/Thundermaw $250k/$265k Divine 9 h -- at every tier", table.concat(bad, ", "))
	-- Pod 2's are Pod 1's creatures, and the rates rise by the same creature in both.
	local same = true
	for i = 1, 3 do
		same = same and SeedData.Get(MAPPING.rainpod1[i][1]).Name == SeedData.Get(MAPPING.rainpod2[i][1]).Name
			and MAPPING.rainpod1[i][3] < MAPPING.rainpod2[i][3]
	end
	check(same and MAPPING.rainpod1[1][3] < MAPPING.rainpod1[2][3] and MAPPING.rainpod2[1][3] < MAPPING.rainpod2[2][3],
		"Pod 2 holds the same three creatures by name, each rate matched to its Pod 1 identity")
	check(SeedData.GrowSecondsFor(SeedData.Get("nubkin"), 7) == 4500 and SeedData.GrowSeconds(7) == 4500,
		"every other pod still grows on the approved ladder")
	local listed = false
	for _, sp in ipairs(SeedData.Species) do
		listed = listed or sp.Event ~= nil
	end
	for _, list in pairs(SeedData.ByBiome) do
		for _, sp in ipairs(list) do
			listed = listed or sp.Event ~= nil
		end
	end
	check(not listed and #SeedData.InBiome("rain") == 0, "no rain creature is in a biome pool, the species list or the Index")
	check(SeedData.Get("tempestoak").CarrySpeedFactor == 0.5 and SeedData.Get("thundermaw").CarrySpeedFactor == 0.5
		and SeedData.Get("puddlepod_colossal").CarrySpeedFactor == nil and SeedData.Get("nubkin").CarrySpeedFactor == nil,
		"only Pod 3's carry is half speed")

	--==========================================================================
	say("2. One batch: three slots and ONE Colossal draw, 5% a Rain; one Pod 3 for a thunderstorm")
	--==========================================================================
	-- The owner's odds (2026-10-06): exactly 5% PER RAIN. One Colossal draw a
	-- batch, 5 in 100: a hit makes one slot, picked at random, a Colossal pod
	-- (Pod 2 or the second family's Colossal, 50/50) and the other two ordinary;
	-- a miss makes all three ordinary. An ordinary slot is Pod 1 or rainpod4,
	-- 50/50, each on its own. History (2026-10-05): each slot 90/10 on its own,
	-- a Colossal in 27.1% of Rains, 0.3 a batch. RainFamilySpec holds the second
	-- family's own numbers.
	local RB = SeedData.RainBatches
	local rain, thunder = RB.rain, RB.thunder
	local rainW, colW, thunderW = rain.Weights, rain.ColossalWeights or {}, thunder.Weights
	local function count(t)
		local n = 0
		for _ in pairs(t) do
			n += 1
		end
		return n
	end
	check(rain.Slots == 3 and rain.ColossalChance == 0.05 and count(rainW) == 2 and rainW.rainpod1 == 1
			and rainW.rainpod4 == 1 and count(colW) == 2 and colW.rainpod2 == 1 and colW.rainpod5 == 1
			and rain.Choices == nil,
		"the rain's batch: three slots, ColossalChance 0.05, ordinary Pod 1 / rainpod4 1:1, Colossal Pod 2 / rainpod5 1:1")
	check(thunder.Slots == 1 and count(thunderW) == 1 and thunderW.rainpod3 ~= nil and thunderW.rainpod3 > 0
			and thunder.ColossalChance == nil and thunder.ColossalWeights == nil,
		"the thunderstorm's batch is unchanged: one slot, Pod 3 alone, no Colossal draw")
	-- No Colossal pod among the ordinary weights; only Colossal pods in the draw.
	local ordinaryOk, colossalOk = true, true
	for podId in pairs(rainW) do
		ordinaryOk = ordinaryOk and SeedData.RainPods[podId].Tier ~= SeedData.TierCount
	end
	for podId in pairs(colW) do
		colossalOk = colossalOk and SeedData.RainPods[podId].Tier == SeedData.TierCount
	end
	local chance = rain.ColossalChance :: number
	check(ordinaryOk and colossalOk and near(chance, 0.05, 1e-12),
		string.format("so a Rain has a Colossal %.0f%% of the time (was 27.1%%), %.2f a batch on average (was 0.3); "
			.. "the ordinary slots never draw one", chance * 100, chance))

	-- The draw: the weights end to end in pod id order, the same draw always the same pod.
	local P = SeedData.PickRainPod
	check(P(rainW, 0) == "rainpod1" and P(rainW, 0.4999999) == "rainpod1" and P(rainW, 0.5) == "rainpod4"
			and P(rainW, 0.9999999) == "rainpod4" and P(rainW, 1) == "rainpod4" and P(colW, 0) == "rainpod2"
			and P(colW, 0.4999999) == "rainpod2" and P(colW, 0.5) == "rainpod5" and P(colW, 1) == "rainpod5",
		"the boundaries: an ordinary slot below 0.5 Pod 1, from 0.5 (1 included) rainpod4; the Colossal slot below "
			.. "0.5 Pod 2, from 0.5 rainpod5")
	check(P(thunderW, 0) == "rainpod3" and P(thunderW, 0.5) == "rainpod3" and P(thunderW, 0.9999999) == "rainpod3",
		"a thunderstorm's draw is Pod 3 whatever it is")
	check(P({ rainpod1 = 0, rainpod2 = 1 }, 0) == "rainpod2" and P({ rainpod1 = 1, rainpod2 = 0 }, 0.9999999) == "rainpod1"
		and P({ rainpod1 = 1, rainpod2 = 0 }, 1) == "rainpod1" and P({ rainpod1 = 3, rainpod2 = 1 }, 0.74) == "rainpod1"
		and P({ rainpod1 = 3, rainpod2 = 1 }, 0.75) == "rainpod2",
		"a pod weighted 0 is never drawn, at either end; any positive total works (3:1 splits at 0.75)")
	local V = SeedData.ValidRainWeights
	local bad = {
		{ nil, "nil" }, { {}, "empty" }, { { rainpod1 = -1, rainpod2 = 2 }, "negative" },
		{ { rainpod1 = 0 / 0 }, "NaN" }, { { rainpod1 = math.huge }, "infinite" }, { { nope = 1 }, "unknown pod" },
		{ { rainpod1 = "90" }, "a string" }, { { rainpod1 = 0, rainpod2 = 0 }, "all zero" },
	}
	local let = {}
	for _, case in ipairs(bad) do
		if V(case[1]) then
			table.insert(let, case[2])
		end
	end
	check(#let == 0 and V(rainW) and V(colW) and V(thunderW) and V({ rainpod1 = 0, rainpod2 = 1 }),
		"the weights are validated when SeedData loads: nil, empty, negative, NaN, infinite, unknown pods, "
			.. "strings and an all-zero table are refused", table.concat(let, ", "))
	local VB = SeedData.ValidRainBatch
	local one, big = { rainpod1 = 1 }, { rainpod2 = 1 }
	local badBatches = {
		{ { Slots = 3, Weights = { rainpod1 = 1, rainpod2 = 1 } }, "a Colossal pod among the ordinary weights" },
		{ { Slots = 3, Weights = one, ColossalChance = 1.5, ColossalWeights = big }, "a chance above 1" },
		{ { Slots = 3, Weights = one, ColossalChance = -0.1, ColossalWeights = big }, "a negative chance" },
		{ { Slots = 3, Weights = one, ColossalChance = 0 / 0, ColossalWeights = big }, "a NaN chance" },
		{ { Slots = 3, Weights = one, ColossalChance = "0.05", ColossalWeights = big }, "a string chance" },
		{ { Slots = 3, Weights = one, ColossalChance = 0.05 }, "a chance with no Colossal weights" },
		{ { Slots = 3, Weights = one, ColossalChance = 0.05, ColossalWeights = { rainpod1 = 1 } },
			"an ordinary pod in the Colossal draw" },
		{ { Slots = 3, Weights = one, ColossalChance = 0.05, ColossalWeights = { nope = 1 } }, "an unknown Colossal pod" },
		{ { Slots = 0, Weights = one }, "no slots" },
		{ { Slots = 3, Weights = { nope = 1 } }, "an unknown ordinary pod" },
	}
	local letB = {}
	for _, case in ipairs(badBatches) do
		if VB(case[1]) then
			table.insert(letB, case[2])
		end
	end
	check(#letB == 0 and VB(rain) and VB(thunder)
			and VB({ Slots = 3, Weights = one, ColossalChance = 0, ColossalWeights = big })
			and VB({ Slots = 3, Weights = one, ColossalChance = 1, ColossalWeights = { rainpod5 = 1 } }),
		"the batches are validated when SeedData loads: a chance outside [0, 1], NaN or a string, a chance with no "
			.. "Colossal weights, a Colossal pod among the ordinary ones, an ordinary or unknown pod in the Colossal "
			.. "draw and no slots are refused; 0 and 1 are fine", table.concat(letB, ", "))

	-- Scripted draws. The batch's Colossal draw comes first; a hit then picks
	-- its slot (an integer draw); each slot then draws its pod, its creature (an
	-- integer draw for the first family, a number for the second) and rainpod4
	-- its size.
	local function scripted(numbers, integers)
		local used, ints = 0, 0
		return {
			NextNumber = function()
				used += 1
				return numbers[used]
			end,
			NextInteger = function(_, lo)
				ints += 1
				return integers[ints] or lo
			end,
		}, function()
			return used, ints
		end
	end
	-- A hit: 0.01 is under 0.05 and the pick is slot 2. Slot 1 draws 0.10 (Pod
	-- 1); slot 2, the Colossal one, 0.97 (rainpod5) and its creature 0.0; slot 3
	-- 0.60 (rainpod4), its creature 0.95 and its size 0.0.
	local rngHit, usedHit = scripted({ 0.01, 0.10, 0.97, 0.0, 0.60, 0.95, 0.0 }, { 2 })
	local hit = SeedData.RollRainBatch("rain", rngHit)
	local nHit, iHit = usedHit()
	check(#hit == 3 and hit[1].pod == "rainpod1" and hit[1].tier == POD.rainpod1.tier and hit[2].pod == "rainpod5"
			and hit[2].tier == SeedData.TierCount and hit[2].species.Id == "squallsnapper" and hit[3].pod == "rainpod4"
			and hit[3].species.Id == "torrentacle" and hit[3].tier == 1 and nHit == 7 and iHit == 2,
		"a hit (0.01, under 0.05) makes the picked slot -- the second -- Colossal and only it: Pod 1, a Colossal "
			.. "Squallsnapper, a Tiny Torrentacle", string.format("%d numbers, %d integers", nHit, iHit))
	-- A miss: 0.05 itself is not under 0.05. No slot pick; three ordinary slots,
	-- the last at 0.9999999.
	local rngMiss, usedMiss = scripted({ 0.05, 0.4999999, 0.5, 0.0, 0.0, 0.9999999, 0.5, 0.5 }, {})
	local miss = SeedData.RollRainBatch("rain", rngMiss)
	local nMiss, iMiss = usedMiss()
	local missBig = false
	for _, roll in ipairs(miss) do
		missBig = missBig or roll.tier == SeedData.TierCount
	end
	check(#miss == 3 and not missBig and miss[1].pod == "rainpod1" and miss[2].pod == "rainpod4"
			and miss[3].pod == "rainpod4" and nMiss == 8 and iMiss == 1,
		"a miss (0.05 itself) picks no slot and lays three ordinary pods -- no Colossal at any draw",
		string.format("%d numbers, %d integers", nMiss, iMiss))
	local rngThunder, usedThunder = scripted({ 0.5 }, {})
	local storm1 = SeedData.RollRainBatch("thunder", rngThunder)
	local nThunder, iThunder = usedThunder()
	check(#storm1 == 1 and storm1[1].pod == "rainpod3" and nThunder == 1 and iThunder == 1,
		"a thunderstorm takes exactly the draws it always did: its pod, then its creature -- no Colossal draw",
		string.format("%d numbers, %d integers", nThunder, iThunder))

	-- A seeded sample. Every tolerance is four standard errors of its own sample
	-- size, so no seed of this size lands outside it by chance; the seed makes it
	-- repeatable as well.
	local function close(share, p, n)
		return n > 0 and math.abs(share - p) <= 4 * math.sqrt(p * (1 - p) / n) + 1e-9
	end
	local rng = Random.new(20261006)
	local N = 20000
	local slots, withBig, twoBig, big2, big5, ordinary, ord1, wrong = 0, 0, 0, 0, 0, 0, 0, 0
	local creature = {}
	for _ = 1, N do
		local batch = SeedData.RollRainBatch("rain", rng)
		if #batch ~= 3 then
			wrong += 1
		end
		local bigs = 0
		for _, roll in ipairs(batch) do
			slots += 1
			local pod = SeedData.RainPods[roll.pod]
			if not pod or (rainW[roll.pod] == nil and colW[roll.pod] == nil) then
				wrong += 1
				continue
			end
			if roll.tier == SeedData.TierCount then
				bigs += 1
				if roll.pod == "rainpod2" then
					big2 += 1
				elseif roll.pod == "rainpod5" then
					big5 += 1
				else
					wrong += 1
				end
			else
				ordinary += 1
				if roll.pod == "rainpod1" then
					ord1 += 1
				end
			end
			local tierOk = if pod.Tier then roll.tier == pod.Tier else roll.tier >= 1 and roll.tier < SeedData.TierCount
			if roll.species.Pod ~= (pod.Family or roll.pod) or not tierOk then
				wrong += 1
			end
			creature[roll.species.Id] = (creature[roll.species.Id] or 0) + 1
		end
		if bigs >= 1 then
			withBig += 1
		end
		if bigs >= 2 then
			twoBig += 1
		end
	end
	check(wrong == 0 and slots == 3 * N,
		"every rain batch is exactly three pods, each one of the four with its own creature and tier", wrong)
	local bigs = big2 + big5
	check(twoBig == 0 and bigs == withBig and close(withBig / N, 0.05, N),
		string.format("seeded sample of %d Rains: a Colossal in %.2f%% of them (5%% asked), never two in one Rain",
			N, withBig / N * 100), string.format("%d with two or more", twoBig))
	check(close(big2 / math.max(bigs, 1), 0.5, bigs) and close(ord1 / math.max(ordinary, 1), 0.5, ordinary),
		string.format("a Colossal is Pod 2 %.1f%% / rainpod5 %.1f%% of the time (%d of them); an ordinary slot Pod 1 "
			.. "%.1f%%", big2 / math.max(bigs, 1) * 100, big5 / math.max(bigs, 1) * 100, bigs,
			ord1 / math.max(ordinary, 1) * 100))
	local even = true
	for _, podId in ipairs({ "rainpod1", "rainpod2" }) do
		local total3 = 0
		for _, row in ipairs(MAPPING[podId]) do
			total3 += creature[row[1]] or 0
		end
		for _, row in ipairs(MAPPING[podId]) do
			even = even and close((creature[row[1]] or 0) / math.max(total3, 1), 1 / 3, total3)
		end
	end
	check(even, "each pod still holds one of its three creatures, a third each")
	local thunderWrong, storm = 0, {}
	for _ = 1, 3000 do
		local batch = SeedData.RollRainBatch("thunder", rng)
		if #batch ~= 1 or batch[1].pod ~= "rainpod3" then
			thunderWrong += 1
		else
			storm[batch[1].species.Id] = (storm[batch[1].species.Id] or 0) + 1
		end
	end
	check(thunderWrong == 0 and math.abs((storm.tempestoak or 0) / 3000 - 0.5) < 0.03,
		string.format("a thunderstorm lays exactly one Pod 3, never Pod 1 or 2; Tempestoak %d / Thundermaw %d",
			storm.tempestoak or 0, storm.thundermaw or 0), thunderWrong)
	-- One roll per event, in one place: the event nest, for both ways weather starts.
	local rollers = {}
	for _, inst in ipairs(Server:GetDescendants()) do
		if inst:IsA("LuaSourceContainer") then
			local _, n = string.gsub(inst.Source, "RollRainBatch%(", "")
			if n > 0 then
				table.insert(rollers, inst.Name .. "=" .. n)
			end
		end
	end
	local nestSrc2 = sourceOf(Server, "NestService")
	check(#rollers == 1 and rollers[1] == "NestService=1"
		and string.find(nestSrc2, "local batch = SeedData.RollRainBatch(mode, Random.new())", 1, true) ~= nil,
		"the batch is rolled in ONE place, OpenEventNest, once per nest -- the console's weather and the automatic "
			.. "weather both lay it there; nothing re-rolls it", table.concat(rollers, ", "))

	--==========================================================================
	say("3. The shell names only its pod; the size word only for Pod 2")
	--==========================================================================
	local pod1Info = PlantInfo.Describe("lotusling", 1, false, 1)
	local pod2Info = PlantInfo.Describe("drizzlet_colossal", 7, false, 1)
	local pod3Info = PlantInfo.Describe("thundermaw", 1, false, 1)
	check(pod1Info.title == "Rain pod" and pod1Info.rarity == "Mythic" and pod1Info.sized == false
		and pod1Info.incomePerSecond == nil and pod1Info.sell == nil and pod1Info.biome == W.Biome.Label,
		"an unhatched Pod 1 reads Rain pod, Mythic, no size, no income or price", pod1Info.title)
	check(pod2Info.title == "Rain pod" and pod2Info.sized == true and pod2Info.size == "Colossal" and pod2Info.incomePerSecond == nil,
		"an unhatched Pod 2 shows Colossal and nothing of its creature", pod2Info.size)
	check(pod3Info.title == "Thunderstorm pod" and pod3Info.rarity == "Divine" and pod3Info.sized == false,
		"an unhatched Pod 3 reads Thunderstorm pod, Divine, no size")
	local grown1 = PlantInfo.Describe("puddlepod", 1, true, 1)
	local grown2 = PlantInfo.Describe("puddlepod_colossal", 7, true, 2)
	check(grown1.title == "Puddlepod" and grown1.sized == false and grown1.incomePerSecond == 80000
		and PlantInfo.SizeWord("puddlepod", 1) == nil and PlantInfo.SizeWord("tempestoak", 1) == nil,
		"a hatched Pod 1 or Pod 3 form has no size word")
	check(grown2.title == "Puddlepod" and grown2.size == "Colossal" and grown2.incomePerSecond == 240000,
		"a hatched Pod 2 form shows Colossal and its rate (doubled here, as the pass shows it)", grown2.incomePerSecond)

	--==========================================================================
	say("4. No silhouette roll for an event pod, and only for one")
	--==========================================================================
	local plantSrc = sourceOf(Server, "PlantService")
	check(string.find(plantSrc, "local revealAt = if entry.species.SkipHatchRoll == true then now else HatchRoll.revealAt(now)",
		1, true) ~= nil, "the hatch reveals an event pod at once; every other pod still asks HatchRoll")
	local skips = 0
	for _, sp in ipairs(SeedData.Species) do
		if sp.SkipHatchRoll then
			skips += 1
		end
	end
	for _, sp in ipairs(SeedData.SecretSpecies) do
		if sp.SkipHatchRoll then
			skips += 1
		end
	end
	check(skips == 0, "no ordinary or Secret species skips its roll")
	check(string.find(plantSrc, "SeedData.GrowSecondsFor(species, tier)", 1, true) ~= nil
		and string.find(plantSrc, "function PlantService.DebugReady(player: Player): number", 1, true) ~= nil
		and string.find(plantSrc, 'if not game:GetService("RunService"):IsStudio() then\n\t\treturn 0', 1, true) ~= nil,
		"a planted pod's deadline is its species' fixed time; the test-only ready hook is Studio-only")

	--==========================================================================
	say("5. Pod 3 carries at half speed, in place of the weight rule; dusk leaves a live event alone")
	--==========================================================================
	local carrySrc = sourceOf(Server, "CarryService")
	check(string.find(carrySrc, "local factor = if held then (held.species :: any).CarrySpeedFactor else nil", 1, true) ~= nil
		and string.find(carrySrc, "local speed = base * multiplier", 1, true) ~= nil
		and string.find(carrySrc, "speed *= slow", 1, true) ~= nil
		and string.find(carrySrc, "speed = math.min(speed, GameConfig.WalkMode.CapStuds)", 1, true) ~= nil,
		"the factor replaces the carry multiplier on the earned speed, before the trap and Walk Mode")
	check(string.find(carrySrc, "loose:SetAttribute(EVENT_ID, held.eventId)", 1, true) ~= nil
		and string.find(carrySrc, "model:SetAttribute(EVENT_ID, eventId)", 1, true) ~= nil
		and string.find(carrySrc, "eventId = eventId,", 1, true) ~= nil,
		"a dropped event pod keeps its event; the carried one carries it")
	check(string.find(sourceOf(Server, "WorldCycleService"), "if pod.Parent and not CarryService.IsLiveEventPod(pod) then", 1, true) ~= nil,
		"dusk clears every loose pod but a running event's")

	--==========================================================================
	say("6. Stormstrider: 2.5 x Astralmaw's chase, everything else Astralmaw's")
	--==========================================================================
	local storm = GameConfig.guardianProfile("stormstrider")
	local astral = GameConfig.guardianProfile("astralmaw")
	check(storm and storm.SpeedScale == 2.5 and storm.OpeningSpeed == astral.OpeningSpeed and storm.TopSpeed == astral.TopSpeed
		and storm.RampSeconds == astral.RampSeconds and storm.ReturnSpeed == astral.ReturnSpeed
		and storm.ThrowSpeed == astral.ThrowSpeed and storm.ThrowLift == astral.ThrowLift and storm.CatchLightning == true
		and storm.GrabStuds == astral.GrabStuds and storm.WakeSeconds == astral.WakeSeconds
		and astral.SpeedScale == nil and astral.CatchLightning == nil,
		"its profile is Astralmaw's with SpeedScale 2.5 and the catch's bolt -- the same ramp, wake, catch range, "
			.. "return and throw; Astralmaw's is untouched")
	check(near(storm.OpeningSpeed * storm.SpeedScale, 195, 1e-9) and near(storm.TopSpeed * storm.SpeedScale, 240, 1e-9),
		"opening 195, top 240 studs a second before rage and shortfall")
	local others = {}
	for species, prof in pairs(GameConfig.Parent.Guardians) do
		if species ~= "stormstrider" and type(prof) == "table" and prof.SpeedScale ~= nil then
			table.insert(others, species)
		end
	end
	check(#others == 0, "no other guardian carries a SpeedScale", table.concat(others, ", "))
	check(GameConfig.confiscateProfile("rain") == nil, "no Confiscate profile: a catch never takes an event pod")
	local nestSrc = sourceOf(Server, "NestService")
	check(string.find(nestSrc, "local scale = tonumber(prof.SpeedScale) or 1", 1, true) ~= nil
		and string.find(nestSrc, "+ rage + shortfall) * scale", 1, true) ~= nil,
		"the scale multiplies the whole ramp, rage and shortfall: 2.5 x what Astralmaw runs at the same player")
	check(string.find(nestSrc, "local parentTravel = MAX_TICK_TRAVEL * math.max(1, tonumber(sweepProf and sweepProf.SpeedScale) or 1)", 1, true) ~= nil
		and string.find(nestSrc, "MAX_TICK_TRAVEL, SAMPLE_MAX_AGE, parentTravel) then", 1, true) ~= nil,
		"its sweep keeps up: its own per-tick allowance widened by the same factor, the target's untouched")

	--==========================================================================
	say("7. The event nest: one batch, guarded, outside the road's cycle, taken down whole")
	--==========================================================================
	local site = {
		centre = Vector3.new(0, 501.11, 2000),
		floorY = 500,
		route = { Vector3.new(-300, 500, 2000), Vector3.new(-150, 500, 2000) },
		setDown = Vector3.new(-300, 500, 2000),
		parent = scratch,
	}
	local roadPods, roadCap = NestService.PodCount()
	local roadNests = NestService.NestCount()
	local laid, why = NestService.OpenEventNest(41, "rain", site)
	local info = NestService.EventNest()
	local okPods = info ~= nil and #info.pods == 3
	if info then
		for _, p in ipairs(info.pods) do
			local sp = SeedData.Get(p.species)
			-- Its pod's one tier, or (the second family's rainpod4) a size it
			-- draws below Colossal; and the shell at the nest is that size's own.
			local pod = SeedData.RainPods[p.pod]
			local tierOk = pod ~= nil and (if pod.Tier then p.tier == pod.Tier else p.tier >= 1 and p.tier < SeedData.TierCount)
			okPods = okPods and sp ~= nil and pod ~= nil and sp.Pod == (pod.Family or p.pod) and tierOk
				and p.model:GetAttribute("EventId") == 41
				and p.model:GetAttribute("NestId") == info.id and CollectionService:HasTag(p.model, GameConfig.Tags.SeedPod)
				and p.model:GetAttribute("SecretForm") == SeedData.PodFormOf(sp, p.tier)
		end
	end
	check(laid == 3 and okPods, "a rain event lays three pods, each stamped with its event and its pod, in its size's shell",
		why)
	local again = NestService.OpenEventNest(42, "thunder", site)
	check(again == 0 and NestService.EventNest().event == 41, "a second event nest is refused while one stands")
	NestService.StockAll()
	NestService.ClearForNight()
	NestService.ResetParents()
	local live, cap = NestService.PodCount()
	check(#NestService.EventNest().pods == 3 and live == roadPods and cap == roadCap and NestService.NestCount() == roadNests,
		"the road's restock, dusk and reset never touch it, and the road's counts never include it")
	local guardian = nil
	for _, m in ipairs(scratch:GetDescendants()) do
		if m:IsA("Model") and m:GetAttribute("Species") == "stormstrider" then
			guardian = m
		end
	end
	local colliders, anchored, parts = 0, 0, 0
	if guardian then
		for _, d in ipairs(guardian:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
				if d.CanCollide then
					colliders += 1
				end
				if d.Anchored then
					anchored += 1
				end
			end
		end
	end
	local humanoid = guardian and guardian:FindFirstChildOfClass("Humanoid")
	check(guardian ~= nil and guardian:GetAttribute("BiomeId") == "rain" and CollectionService:HasTag(guardian, GameConfig.Tags.NestParent)
		and guardian:GetAttribute("Asleep") == true and humanoid ~= nil and humanoid.WalkSpeed == 0 and humanoid.HipHeight > 5
		and colliders == 1 and anchored == 0 and parts == #RainForms.Guardian.Parts + 1
		and guardian.PrimaryPart ~= nil and guardian.PrimaryPart.Name == "HumanoidRootPart",
		string.format("Stormstrider guards it on the guardian contract: one collider, nothing anchored, %d parts", parts))
	if guardian then
		local root = guardian.PrimaryPart
		local frame = CFrame.new(root.Position.X, site.floorY, root.Position.Z) * root.CFrame.Rotation
		local lo, hi = extents(guardian, frame, true)
		local size = hi - lo
		local want = RainForms.Guardian.Size
		check(near(size.X, want.X, 0.02) and near(size.Y, want.Y, 0.02) and near(size.Z, want.Z, 0.02) and near(lo.Y, 0, 0.02),
			string.format("at its supplied size, %.2f x %.2f x %.2f, paws on the floor", size.X, size.Y, size.Z), lo.Y)
		local worst = jointDisagreement(guardian)
		check(worst < 1e-3, "every one of its joints agrees with the parts it holds: nothing moves when it is posed", worst)

		--== ASLEEP, ON THE FLOOR (the 2026-10-02 fix) ==--
		local StormstriderRun = require(Shared.StormstriderRun)
		local CLEAR = StormstriderRun.CLEARANCE
		local floor = Instance.new("Part")
		floor.Name = "RainPodsSpecFloor"
		floor.Anchored = true
		floor.CanCollide = true
		floor.Size = Vector3.new(400, 2, 400)
		floor.CFrame = CFrame.new(root.Position.X, site.floorY - 1, root.Position.Z)
		floor.Parent = Workspace
		local rig = StormstriderRun.Rig(guardian)
		check(rig ~= nil, "the guardian rigs")
		if rig then
			local floorRS = site.floorY - root.Position.Y
			local authored = RainForms.Guardian.Pose.DropStuds
			check(near(rig.restLow, floorRS, 0.05), "standing, its lowest point is the floor its HipHeight holds the paws on",
				rig.restLow - floorRS)
			check(rig.sleepLow - authored - floorRS > 5,
				string.format("THE CAUSE: with the authored DropStuds %.2f its lying silhouette hung %.2f studs above the floor",
					authored, rig.sleepLow - authored - floorRS))
			local lowAt, highAt = math.huge, -math.huge
			local lastT = 10
			for i = 0, 50 do
				lastT = 10 + i * 0.087
				StormstriderRun.Step(rig, 1 / 60, lastT, 0, true, false)
				local l = StormstriderRun.Lowest(rig) - site.floorY
				lowAt, highAt = math.min(lowAt, l), math.max(highAt, l)
			end
			check(rig.sleep == 1 and lowAt >= CLEAR - 0.01 and highAt <= 0.4,
				string.format("asleep it rests ON the floor through every breath: lowest part %.3f..%.3f studs above it (drop %.2f)",
					lowAt, highAt, rig.drop))
			-- One real frame later (the clock continues), told to wake.
			local before = rig.rootJoint.C0.Position.Y
			StormstriderRun.Step(rig, 1 / 60, lastT + 1 / 60, 0, false, false)
			local after = rig.rootJoint.C0.Position.Y
			check(after > before and after - before < rig.drop * 0.1,
				"waking lifts the body gradually from where it lay, never a snap", after - before)
			for i = 1, 400 do
				StormstriderRun.Step(rig, 1 / 30, 15 + i / 30, 0, false, false)
			end
			check(rig.sleep == 0 and rig.measured == false and near(rig.rootJoint.C0.Position.Y, 0, 1e-6),
				"fully awake it stands at its supplied height and forgets the floor it lay on")
			floor.CFrame += Vector3.new(0, 2, 0)
			for i = 1, 400 do
				StormstriderRun.Step(rig, 1 / 30, 30 + i / 30, 0, true, false)
			end
			local again2 = StormstriderRun.Lowest(rig) - (site.floorY + 2)
			check(rig.sleep == 1 and again2 >= CLEAR - 0.01 and again2 <= 0.4,
				"lying down again (home after a chase) it measures afresh: on a floor two studs higher it rests on that one",
				again2)
		end
		floor:Destroy()
	end
	local removed = NestService.CloseEventNest(41)
	check(removed == 3 and NestService.EventNest() == nil and #scratch:GetChildren() == 0,
		"closing takes the unclaimed pods and the guardian with it", removed)
	local thunderLaid = NestService.OpenEventNest(43, "thunder", site)
	local tInfo = NestService.EventNest()
	check(thunderLaid == 1 and tInfo ~= nil and #tInfo.pods == 1 and tInfo.pods[1].pod == "rainpod3",
		"a thunderstorm's nest holds exactly one Pod 3")
	NestService.CloseEventNest(nil)

	--==========================================================================
	say("8. Every form at its supplied size, whatever its tier; the walk on its own legs; rest as authored")
	--==========================================================================
	local sizeBad, walkBad, restBad, jointBad = {}, {}, {}, {}
	for formId, spec in pairs(RainForms.Plants) do
		local sp = SeedData.Get(formId)
		local tier = SeedData.RainPods[sp.Pod].Tier
		local holder = Instance.new("Model")
		holder.Parent = scratch
		local model = CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN, CFrame.new(0, 500, 3000), holder)
		local lo, hi = extents(model, CFrame.new(0, 500, 3000), true)
		local size = hi - lo
		if not (near(size.X, spec.Size.X, 0.02) and near(size.Y, spec.Size.Y, 0.02) and near(size.Z, spec.Size.Z, 0.02)) then
			table.insert(sizeBad, string.format("%s %.2f/%.2f", formId, size.Y, spec.Size.Y))
		end
		local disagree = jointDisagreement(model)
		if disagree > 1e-3 then
			table.insert(jointBad, string.format("%s %.4f", formId, disagree))
		end
		-- The walk: carry the model forward at the Colossal rung's pace and
		-- watch a foot. Planted feet hold still in the world while the body
		-- passes over them; lifted ones swing forward.
		local rig = SecretIdle.Rig(model)
		local foot = nil
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Name == "Foot" then
				foot = d
				break
			end
		end
		if not (rig and rig.gait and foot) then
			table.insert(walkBad, formId .. " no gait")
		else
			rig.walks = true
			local base = model:GetPivot()
			local held, swung, frames = 0, 0, 0
			local lastFoot = nil
			local t = 0
			for i = 1, 240 do
				t += 1 / 30
				model:PivotTo(base * CFrame.new(0, 0, -1.6 * t))
				SecretIdle.Step(rig, t)
				local at = foot.Position
				if lastFoot and i > 30 then
					frames += 1
					local step = (at - lastFoot).Magnitude
					if step < 0.01 then
						held += 1
					elseif step > 1.6 / 30 * 1.2 then
						swung += 1
					end
				end
				lastFoot = at
			end
			if held < frames * 0.25 or swung < frames * 0.05 then
				table.insert(walkBad, string.format("%s held %d swung %d of %d", formId, held, swung, frames))
			end
			-- Back to rest: every part exactly where it was built.
			rig.walks = false
			model:PivotTo(base)
			SecretIdle.Rest(rig)
			local worst = 0
			local origin = model:GetPivot()
			for _, node in ipairs(rig.nodes) do
				local off = origin:ToObjectSpace(node.part.CFrame).Position
				worst = math.max(worst, (off - node.rel.Position).Magnitude)
			end
			if worst > 1e-3 then
				table.insert(restBad, string.format("%s %.4f", formId, worst))
			end
		end
		holder:Destroy()
	end
	check(#sizeBad == 0, "all eight forms build at the size they were supplied -- Pod 2's larger at tier 7, never scaled again",
		table.concat(sizeBad, ", "))
	check(#jointBad == 0, "every form's joints agree with its parts as supplied", table.concat(jointBad, ", "))
	check(#walkBad == 0, "every form walks on its own legs: feet planted while the body passes, swung forward between",
		table.concat(walkBad, ", "))
	check(#restBad == 0, "and at rest every part is exactly where it was authored", table.concat(restBad, ", "))
	local podBad = {}
	for _, podId in ipairs({ "rainpod1", "rainpod2", "rainpod3" }) do
		local spec = RainForms.Pods[podId]
		local sp = SeedData.Get(SeedData.RainPods[podId].Species[1])
		local holder = Instance.new("Model")
		holder.Parent = scratch
		local model = CreatureModel.BuildPod(sp, SeedData.RainPods[podId].Tier, CFrame.new(0, 500, 3000), holder)
		local lo, hi = extents(model, CFrame.new(0, 500, 3000), true)
		local size = hi - lo
		if not (near(size.Y, spec.Size.Y, 0.02) and near(size.X, spec.Size.X, 0.02)) or model.PrimaryPart == nil then
			table.insert(podBad, podId)
		end
		holder:Destroy()
	end
	check(#podBad == 0, "the three pods build at their supplied sizes, on a base Shell", table.concat(podBad, ", "))

	-- THE ROOT IS THE AUTHORED ONE, WHATEVER ORDER THE PARTS ARRIVE IN (found in Play, 2026-10-02: a client
	-- receives a model's parts in replication's order, and a Tempestoak's tree started at an antler). The
	-- parts are re-parented in reverse, as a client might see them, and the model is walked TURNED and on
	-- PlantSway's 20 Hz slices.
	local orderBad = {}
	for _, formId in ipairs({ "lotusling", "lotusling_colossal", "tempestoak", "thundermaw" }) do
		local sp = SeedData.Get(formId)
		local holder = Instance.new("Model")
		holder.Parent = scratch
		local model = CreatureModel.Build(sp, SeedData.RainPods[sp.Pod].Tier, CreatureModel.STAGE_GROWN,
			CFrame.new(0, 500, 3000) * CFrame.Angles(0, math.rad(-98), 0), holder)
		local kids = model:GetChildren()
		local park = Instance.new("Folder")
		for _, k in ipairs(kids) do
			if k:IsA("BasePart") and k ~= model.PrimaryPart then
				k.Parent = park
			end
		end
		local parked = park:GetChildren()
		for i = #parked, 1, -1 do
			parked[i].Parent = model
		end
		park:Destroy()
		local rig = SecretIdle.Rig(model)
		local rootPart = rig and rig.nodes[rig.order[1]].part
		local marked = rootPart and rootPart:GetAttribute("RigRoot") == true and rootPart.Name == "Body"
		local foot = nil
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Name == "Foot" then
				foot = d
				break
			end
		end
		if not (rig and rig.gait and marked and foot) then
			table.insert(orderBad, formId .. " root " .. (rootPart and rootPart.Name or "none"))
		else
			rig.walks = true
			local base = model:GetPivot()
			local worst = 0
			local t = 0
			for i = 1, 300 do
				t += 1 / 60
				-- On a slice: the model moves every third frame, as PlantSway moves it.
				if i % 3 == 0 then
					model:PivotTo(base * CFrame.new(0, 0, -1.6 * t))
				end
				SecretIdle.Step(rig, t)
				local rel = model:GetPivot():PointToObjectSpace(foot.Position)
				worst = math.max(worst, Vector3.new(rel.X, 0, rel.Z).Magnitude)
			end
			-- A foot never wanders further from the body than a leg can reach.
			local reach = SecretModel.Size(formId).X
			if worst > reach then
				table.insert(orderBad, string.format("%s foot %.1f studs out", formId, worst))
			end
		end
		holder:Destroy()
	end
	check(#orderBad == 0, "with its parts in any order and walked turned on slices, every rig roots at its marked Body "
		.. "and keeps its feet within reach", table.concat(orderBad, ", "))

	--==========================================================================
	say("9. The save keeps every form, pod and creature, through JSON")
	--==========================================================================
	local raw = ProfileSchema.Default()
	raw.Plants = {}
	raw.Held = {}
	for _, sp in ipairs(SeedData.RainSpecies) do
		-- The first family at its pod's one tier; the second family (2026-10-05)
		-- at every size it comes in, each deadline its size's own.
		local one = SeedData.RainPods[sp.Pod].Tier
		local tiers = if one then { one } else { 1, 2, 3, 4, 5, 6, 7 }
		for _, tier in ipairs(tiers) do
			table.insert(raw.Held, { Id = sp.Id, Tier = tier, Hatched = false })
			table.insert(raw.Held, { Id = sp.Id, Tier = tier, Hatched = true })
			table.insert(raw.Plants, { SpeciesId = sp.Id, PlantedAt = 1000, HatchAt = 1000 + SeedData.GrowSecondsFor(sp, tier),
				Tier = tier, X = 1, Z = 2, Stage = 1, Facing = 3 })
		end
	end
	local round = ProfileSchema.Sanitise(HttpService:JSONDecode(HttpService:JSONEncode(ProfileSchema.Sanitise(raw))))
	local kept = #round.Held == #raw.Held and #round.Plants == #raw.Plants
	for i, row in ipairs(raw.Held) do
		local back = round.Held[i]
		kept = kept and back ~= nil and back.Id == row.Id and back.Tier == row.Tier and back.Hatched == row.Hatched
	end
	for i, row in ipairs(raw.Plants) do
		local back = round.Plants[i]
		kept = kept and back ~= nil and back.SpeciesId == row.SpeciesId and back.Tier == row.Tier and back.HatchAt == row.HatchAt
	end
	check(kept, "every rain pod and creature, in the bag and in the ground, comes back exactly -- deadline included")

	--==========================================================================
	say("10. START THUNDERSTORM: the same event, one at a time, one +25%, its own one batch")
	--==========================================================================
	local now = 50000
	local opened, closed = {}, {}
	WeatherService.useClock(function()
		return now
	end)
	WeatherService.usePlayers(function()
		return {}
	end)
	WeatherService.useTerrain({
		build = function(parent)
			local f = Instance.new("Folder")
			f.Name = "ZZStandInTerrain"
			f.Parent = scratch
			return f
		end,
		setEntry = function() end,
		destroy = function(terrain)
			if terrain then
				terrain:Destroy()
			end
		end,
	})
	WeatherService.useBroadcast(function() end)
	WeatherService.useMover(function()
		return true
	end)
	WeatherService.useNest({
		open = function(id, mode)
			table.insert(opened, mode)
			return if mode == "thunder" then 1 else 3
		end,
		close = function(id)
			table.insert(closed, id)
			return 0
		end,
	})
	WeatherService.Init()
	local okT, msgT = WeatherService.StartThunderstorm({ Name = "owner" }, 60)
	local state = WeatherService.State()
	check(okT and state ~= nil and state.mode == "thunder" and state.laid == 1 and #opened == 1 and opened[1] == "thunder"
		and Workspace:GetAttribute(W.Attributes.Mode) == "thunder" and WeatherService.IncomeFactor() == SeedData.Rain.IncomeFactor,
		"a thunderstorm starts as the one event, lays its one batch, and pays the same single +25%", msgT)
	local okR, msgR = WeatherService.StartRain({ Name = "owner" }, 60)
	local okT2 = WeatherService.StartThunderstorm({ Name = "owner" }, 60)
	check(not okR and not okT2 and string.find(msgR, "already raging", 1, true) ~= nil and #opened == 1
		and WeatherService.State().mode == "thunder",
		"a rain or a second thunderstorm is refused while it rages: never converted, never a second batch", msgR)
	local _, msgE = WeatherService.EndRain({ Name = "owner" })
	local okC, msgC = WeatherService.StartRain({ Name = "owner" }, 60)
	check(not okC and string.find(msgC, "still clearing", 1, true) ~= nil and #closed == 1 and state ~= nil
		and closed[1] == state.id and WeatherService.IncomeFactor() == 1,
		"END closes it and its nest at once; nothing starts while it clears", msgE)
	now += W.ThickenSeconds + W.FadeSeconds + 1
	WeatherService.Step(now)
	check(WeatherService.State() == nil and Workspace:GetAttribute(W.Attributes.Mode) == nil and #closed == 2,
		"once faded the event is gone, the mode with it, and the nest asked to close once more")
	local adminSrc = sourceOf(Server, "AdminService")
	local consoleSrc = sourceOf(Server.AdminService, "AdminConsoleUI")
	check(string.find(adminSrc, 'if verb == "start" or verb == "thunder" then', 1, true) ~= nil
		and string.find(adminSrc, "WeatherService.StartThunderstorm(admin, seconds)", 1, true) ~= nil
		-- The redesigned console (2026-10-07): THUNDERSTORM beside START RAIN and STOP, asked in place.
		and string.find(consoleSrc, '{ "StartThunder", "THUNDERSTORM" }', 1, true) ~= nil
		and string.find(consoleSrc, 'askWeather("thunder")', 1, true) ~= nil
		and string.find(consoleSrc, 'setAsking("weather", verb)', 1, true) ~= nil,
		"the console's WEATHER section has THUNDERSTORM, asked in place like the rest (every admin's since 2026-10-07)")
	check(GameConfig.Secret.Enabled == true, "natural Secret spawning is on (the owner, 2026-10-09)")
end)

WeatherService.useClock(nil)
WeatherService.usePlayers(nil)
WeatherService.useTerrain(nil)
WeatherService.useBroadcast(nil)
WeatherService.useMover(nil)
WeatherService.useNest(nil)
WeatherService.Init()
pcall(NestService.CloseEventNest, nil)
scratch:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("RainPodsSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
