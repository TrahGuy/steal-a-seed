--!nocheck
--==============================================================================
-- Steal a Seed :: RainFamilySpec
--
-- The Rain event's second family (2026-10-05, the owner's "Rain Event 2"):
-- Squallsnapper, Monsoad, Thundershell and Torrentacle, each ONE species at all
-- seven sizes, built whole from the owner's supplied rig at its supplied size
-- times the tier ladder; the owner's seven supplied pods, one per size, matched
-- BY NAME and never scaled again; the owner's 28 unboosted rates, paid once
-- through EconomyService with every boost applied once; 3 h / 6 h growth; and
-- the owner's even split -- an ordinary slot Pod 1 / rainpod4 1:1, the one
-- Colossal a Rain (5% of Rains since 2026-10-06; it was 10 in 100 a slot)
-- Pod 2 / rainpod5 1:1 -- with the family's creatures 40 / 25 / 25 / 10. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("RainFamilySpec"))
--
-- The first family, the Thunderstorm and the event nest's lifecycle are
-- RainPodsSpec's. Not here, seen in the guarded Play instead: a real nest,
-- carry, drop, bank, plant, hatch, pickup and rejoin on a throwaway profile,
-- and how the walks and the shells look.
--==============================================================================
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local PlantForms = require(Shared.PlantForms)
local PlantIdles = require(Shared.PlantIdles)
local RainForms = require(Shared.RainForms)
local SecretModel = require(Shared.SecretModel)
local SecretIdle = require(Shared.SecretIdle)
local CreatureModel = require(Shared.CreatureModel)
local PlantInfo = require(Shared.PlantInfo)
local InventoryModel = require(Shared.InventoryModel)
local PlantAura = require(Shared.PlantAura)
local EconomyService = require(Server.EconomyService)
local PlotService = require(Server.PlotService)
local PlantService = require(Server.PlantService)
local PassService = require(Server.PassService)
local BonusChestService = require(Server.BonusChestService)
local SacrificeService = require(Server.SacrificeService)
local WeatherService = require(Server.WeatherService)
local NestService = require(Server.NestService)
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
	local found = parent and parent:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-6)
end

--==============================================================================
-- THE OWNER'S TABLES
--==============================================================================
local IDS = { "squallsnapper", "monsoad", "thundershell", "torrentacle" }
-- id -> name, rarity, supplied model, the 28 rates.
local OWNER = {
	squallsnapper = { "Squallsnapper", "Epic", "SquallsnapLow (epic) (Tiny)",
		{ 20000, 23000, 26000, 30000, 36000, 43000, 50000 } },
	monsoad = { "Monsoad", "Legendary", "Monsoad (Legendary) (tiny)",
		{ 30000, 34500, 39000, 45000, 54000, 64500, 75000 } },
	thundershell = { "Thundershell", "Legendary", "Thundershell (tiny)(Legendary)",
		{ 35000, 40250, 45500, 52500, 63000, 75250, 87500 } },
	torrentacle = { "Torrentacle", "Mythic", "Torrentacle (tiny)(Mythic)",
		{ 60000, 69000, 78000, 90000, 108000, 129000, 150000 } },
}
local LADDER = { 1, 1.15, 1.3, 1.5, 1.8, 2.15, 2.5 }
-- Tier -> the owner's supplied pod, by its NAME (Mega is tier 4, Giant 5), and its drawn height as supplied.
local PODS = {
	{ "rain2pod_tiny", "Pod (Tiny)", 2.6425 },
	{ "rain2pod_big", "Pod (big)", 7.5519 },
	{ "rain2pod_huge", "Pod (huge)", 9.5121 },
	{ "rain2pod_mega", "Pod (Mega)", 12.5103 },
	{ "rain2pod_giant", "Pod (Giant)", 16.5103 },
	{ "rain2pod_titan", "Pod (Titan)", 19.3000 },
	{ "rain2pod_colossal", "Pod (Colossal)", 22.5000 },
}
local GROW = { 10800, 10800, 10800, 10800, 10800, 10800, 21600 }

local auraBefore = Workspace:FindFirstChild("SeedPlantAura")
local scratch = Instance.new("Folder")
scratch.Name = "ZZRainFamilySpec"
scratch.Archivable = false
scratch.Parent = Workspace

-- The drawn (visible) extents in `frame`'s space.
local function drawn(model, frame)
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.999 then
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

-- How far the worst joint is from agreeing with the parts it holds.
local function jointDisagreement(model)
	local worst = 0
	for _, d in ipairs(model:GetDescendants()) do
		if (d:IsA("Motor6D") or d:IsA("Weld")) and d.Part0 and d.Part1 then
			local a = d.Part0.CFrame * d.C0
			local b = d.Part1.CFrame * d.C1
			worst = math.max(worst, (a.Position - b.Position).Magnitude + (a.LookVector - b.LookVector).Magnitude
				+ (a.UpVector - b.UpVector).Magnitude)
		end
	end
	return worst
end

-- Every part of a model, by name, colour, material, size and place relative to its pivot: what it LOOKS like.
local function look(model)
	local pivot = model:GetPivot()
	local lines = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local rel = pivot:ToObjectSpace(d.CFrame)
			table.insert(lines, string.format("%s|%s|%s|%.3f,%.3f,%.3f|%.3f,%.3f,%.3f|%.3f", d.Name, tostring(d.Color),
				d.Material.Name, d.Size.X, d.Size.Y, d.Size.Z, rel.Position.X, rel.Position.Y, rel.Position.Z, d.Transparency))
		end
	end
	table.sort(lines)
	return table.concat(lines, "\n")
end

local plots: any, plants: any, passes: any = PlotService, PlantService, PassService
local chest: any, sacrifice: any, weather: any = BonusChestService, SacrificeService, WeatherService
local real = {
	PlotOf = plots.PlotOf, OwnerOf = plots.OwnerOf, GrownIn = plants.GrownIn,
	CashMultiplier = passes.CashMultiplier, Chest = chest.Multiplier, Sacrifice = sacrifice.Multiplier,
	IncomeFactor = weather.IncomeFactor,
}

local ok, err = pcall(function()
	--==========================================================================
	say("1. The four, as the owner supplied them")
	--==========================================================================
	local dataBad = {}
	for _, id in ipairs(IDS) do
		local sp = SeedData.Get(id)
		local want = OWNER[id]
		local spec = PlantForms.Plants[id]
		if not (sp and spec and sp.Name == want[1] and sp.Rarity == want[2] and sp.Biome == "rain" and sp.Event == "rain"
			and sp.Secret ~= true and sp.Unsized == nil and sp.SkipHatchRoll == true and sp.Carry == "overhead"
			and sp.Animator == "secret" and sp.Pod == "rainpod4" and sp.FixedIncome == nil and sp.FixedGrowSeconds == nil
			and sp.IncomeBonus == nil and sp.CarrySpeedFactor == nil and sp.WanderTier == nil
			and spec.Source == "Rain Event 2/" .. want[3] and spec.Kind == "plant" and #spec.Parts == spec.PartCount
			and spec.Parts[spec.Base] ~= nil and spec.Parts[spec.Base].n == "Footing" and near(sp.Height, spec.Height, 0.01)
			and PlantForms.Supplied[id] == true and PlantForms.Has(id)) then
			table.insert(dataBad, id)
		end
	end
	check(#dataBad == 0, "each is one sized species from its supplied model: Squallsnapper Epic, Monsoad and Thundershell "
		.. "Legendary, Torrentacle Mythic -- a Rain creature, not a Secret, never unsized", table.concat(dataBad, ", "))
	local counts = {}
	for _, id in ipairs(IDS) do
		local spec = PlantForms.Plants[id]
		local motors, scripts = 0, 0
		for _, j in ipairs(spec.Joints) do
			if j.k == "Motor6D" then
				motors += 1
			end
		end
		table.insert(counts, string.format("%s %d parts %d joints (%d motors) %d lights %d emitters", id, #spec.Parts,
			#spec.Joints, motors, #spec.Lights, #spec.Emitters))
	end
	local P = PlantForms.Plants
	check(#P.squallsnapper.Parts == 46 and #P.monsoad.Parts == 96 and #P.thundershell.Parts == 79
		and #P.torrentacle.Parts == 95 and #P.squallsnapper.Joints == 45 and #P.monsoad.Joints == 95
		and #P.thundershell.Joints == 78 and #P.torrentacle.Joints == 94,
		"every supplied part and joint came across: " .. table.concat(counts, "; "))

	--==========================================================================
	say("2. The 28 rates, exactly, and nothing on top")
	--==========================================================================
	local rateBad = {}
	for _, id in ipairs(IDS) do
		local sp = SeedData.Get(id)
		local want = OWNER[id][4]
		for tier = 1, SeedData.TierCount do
			local got = SeedData.IncomePerSecond(sp, tier)
			if got ~= want[tier] or got ~= sp.TierIncome[tier] or not near(want[tier], want[1] * LADDER[tier], 1e-6)
				or SeedData.SellPrice(sp, tier) ~= want[tier] * SeedData.SellSeconds then
				table.insert(rateBad, id .. "@" .. tier .. "=" .. tostring(got))
			end
		end
		-- Anything a Tool or a saved row could carry lands on a real rung.
		if SeedData.IncomePerSecond(sp, 0) ~= want[1] or SeedData.IncomePerSecond(sp, 99) ~= want[7]
			or SeedData.IncomePerSecond(sp, 0 / 0) ~= want[1] or SeedData.IncomePerSecond(sp, nil) ~= want[1] then
			table.insert(rateBad, id .. " clamp")
		end
	end
	check(#rateBad == 0, "all 28: IncomePerSecond is the owner's rate for the size -- the event ladder 1 / 1.15 / 1.3 / "
		.. "1.5 / 1.8 / 2.15 / 2.5 off each Tiny -- with no rarity, biome or tier value factor; the sale is 30 s of it",
		table.concat(rateBad, ", "))

	local payer = { Name = "SpecPayer", UserId = 9002 }
	local plot = Instance.new("Model")
	local grown = {}
	local passMul, chestMul, sacrificeMul, rainMul = 1, 1, 1, 1
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
	weather.IncomeFactor = function()
		return rainMul
	end
	local paidBad = {}
	for _, id in ipairs(IDS) do
		for tier = 1, SeedData.TierCount do
			grown = { { species = SeedData.Get(id), tier = tier } }
			if EconomyService.RateFor(payer) ~= OWNER[id][4][tier] then
				table.insert(paidBad, id .. "@" .. tier)
			end
		end
	end
	check(#paidBad == 0, "unboosted, EconomyService.RateFor pays exactly the owner's 28 numbers", table.concat(paidBad, ", "))
	grown = { { species = SeedData.Get("torrentacle"), tier = 7 }, { species = SeedData.Get("squallsnapper"), tier = 1 } }
	passMul = 2
	local withPass = EconomyService.RateFor(payer)
	chestMul, sacrificeMul = 1.25, 1.5
	local withBoosts = EconomyService.RateFor(payer)
	rainMul = SeedData.Rain.IncomeFactor
	local withRain = EconomyService.RateFor(payer)
	local base = 150000 + 20000
	check(withPass == base * 2 and near(withBoosts, base * 2 * 1.75, 1e-6)
		and near(withRain, base * 2 * 1.75 * SeedData.Rain.IncomeFactor, 1e-6),
		string.format("boosts compose once, as for every plant: x2 pass %d, + chest and sacrifice %d, + the rain %d "
			.. "(on $%d)", withPass, withBoosts, withRain, base))
	plot:Destroy()
	local profile = { LastSeen = 10000, Plants = { { SpeciesId = "monsoad", Tier = 6, Stage = CreatureModel.STAGE_GROWN } } }
	local cash, seconds = OfflineEarnings.accrue(profile, 10000 + 3600)
	check(cash == 64500 * 3600 * SeedData.Offline.Efficiency and seconds == 3600,
		"the offline garden counts a grown Titan Monsoad at its own $64,500/s", cash)
	local shown = PlantInfo.Describe("thundershell", 5, true, 2)
	check(shown.incomePerSecond == 63000 * 2 and shown.sellValue == 63000 * 30 and shown.rarity == "Legendary"
		and shown.size == "Giant" and shown.sized == true and shown.title == "Thundershell",
		"the label and the Bag read the same contract: a Giant Thundershell, Legendary, +$126K/s under the pass, "
			.. "sold for 30 s of $63,000", shown.income)

	--==========================================================================
	say("3. Growth: 3 h for Tiny .. Titan, 6 h for Colossal; nothing else's moved")
	--==========================================================================
	local growBad = {}
	for _, id in ipairs(IDS) do
		local sp = SeedData.Get(id)
		for tier = 1, SeedData.TierCount do
			if SeedData.GrowSecondsFor(sp, tier) ~= GROW[tier] then
				table.insert(growBad, id .. "@" .. tier)
			end
		end
	end
	check(#growBad == 0 and SeedData.GrowSecondsFor(SeedData.Get("puddlepod"), 1) == 10800
		and SeedData.GrowSecondsFor(SeedData.Get("lotusling_colossal"), 7) == 21600
		and SeedData.GrowSecondsFor(SeedData.Get("thundermaw"), 1) == 32400
		and SeedData.GrowSecondsFor(SeedData.Get("nubkin"), 7) == 4500,
		"the second family grows 3 h / 6 h; Pod 1 3 h, Pod 2 6 h, Pod 3 9 h and the road's ladder are unchanged",
		table.concat(growBad, ", "))

	--==========================================================================
	say("4. Every size built whole: the supplied model x the ladder, on the soil, joints and effects with it")
	--==========================================================================
	local sizeBad, contractBad, jointBad, fxBad = {}, {}, {}, {}
	local lineup = {}
	for _, id in ipairs(IDS) do
		local sp = SeedData.Get(id)
		local spec = PlantForms.Plants[id]
		local row = {}
		for tier = 1, SeedData.TierCount do
			local mul = SeedData.SizeScale(tier)
			local cf = CFrame.new(tier * 90, 600, 2000)
			local model = CreatureModel.BuildCreature(sp, tier, CreatureModel.STAGE_GROWN, cf, scratch)
			local lo, hi = drawn(model, cf)
			local size = hi - lo
			local want = spec.Size * mul
			if not (near(size.X, want.X, want.X * 0.002) and near(size.Y, want.Y, want.Y * 0.002)
				and near(size.Z, want.Z, want.Z * 0.002) and math.abs(lo.Y) < 0.01) then
				table.insert(sizeBad, string.format("%s@%d %.2f/%.2f low %.3f", id, tier, size.Y, want.Y, lo.Y))
			end
			table.insert(row, string.format("%.1f", size.Y))
			local basePart = model.PrimaryPart
			local anchoredAll, parts, joints, scripts = true, 0, 0, 0
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("BasePart") then
					parts += 1
					if not d.Anchored or d.CanCollide or d.CanQuery or d.CanTouch then
						anchoredAll = false
					end
				elseif d:IsA("Motor6D") or d:IsA("Weld") then
					joints += 1
				elseif d:IsA("LuaSourceContainer") then
					scripts += 1
				end
			end
			if not (basePart and basePart.Name == "Base" and basePart.Transparency == 1 and anchoredAll and scripts == 0
				and parts == #spec.Parts + 1 and joints == #spec.Joints
				and model:GetAttribute("SpeciesId") == id and model:GetAttribute("Tier") == tier
				and model:GetAttribute("Rarity") == sp.Rarity and model:GetAttribute("Stage") == CreatureModel.STAGE_GROWN
				and model:GetAttribute("SecretForm") == id
				and near(model:GetAttribute("RigScale") or 0, mul, 1e-9)
				and CollectionService:HasTag(model, GameConfig.Tags.Creature)
				and CollectionService:HasTag(model, SecretModel.RIG_TAG)) then
				table.insert(contractBad, id .. "@" .. tier)
			end
			if jointDisagreement(model) > 1e-3 * mul then
				table.insert(jointBad, string.format("%s@%d %.4f", id, tier, jointDisagreement(model)))
			end
			-- The light's reach and the emitter's size and speed grow with it.
			local light = model:FindFirstChildWhichIsA("PointLight", true)
			local emitter = model:FindFirstChildWhichIsA("ParticleEmitter", true)
			local wantRange = spec.Lights[1].range * mul
			if not (light and emitter and near(light.Range, wantRange, 0.01)
				and near(emitter.Size.Keypoints[1].Value, spec.Emitters[1].size.Keypoints[1].Value * mul, 1e-3)
				and near(emitter.Speed.Max, spec.Emitters[1].speed.Max * mul, 1e-3)) then
				table.insert(fxBad, id .. "@" .. tier)
			end
			model:Destroy()
		end
		table.insert(lineup, id .. " " .. table.concat(row, "/"))
	end
	check(#sizeBad == 0, "every size is the supplied model x 1 / 1.38 / 1.9 / 2.65 / 3.7 / 5.1 / 7.6, standing on the "
		.. "soil -- heights " .. table.concat(lineup, "; "), table.concat(sizeBad, ", "))
	check(#contractBad == 0, "on the creature contract at every size: an invisible Base pivot, every part anchored and "
		.. "inert, every supplied part and joint, no script, the rig tag and its RigScale", table.concat(contractBad, ", "))
	check(#jointBad == 0, "every joint, C0 and C1 scaled, agrees with the parts it holds at every size",
		table.concat(jointBad, ", "))
	check(#fxBad == 0, "the glow's range and the particles' size and speed grow with the creature (the property keeps "
		.. "the full range; how far a light can reach on screen is the engine's own limit)", table.concat(fxBad, ", "))

	--==========================================================================
	say("5. The seven supplied pods, by NAME, at the size each was supplied -- never scaled again")
	--==========================================================================
	local podBad, podLook = {}, {}
	local heights = {}
	for tier, row in ipairs(PODS) do
		local form, model, height = row[1], row[2], row[3]
		local spec = RainForms.Pods[form]
		local shown = SeedData.PodFormOf(SeedData.Get("monsoad"), tier)
		if not (spec and shown == form and spec.Source == "Rain Event 2/" .. model and spec.Kind == "pod"
			and spec.Base == 0 and near(spec.Size.Y, height, 0.001)) then
			table.insert(podBad, tier .. " " .. tostring(shown))
		end
		heights[tier] = spec and spec.Size.Y or 0
		-- Built: exactly its supplied size, never times the ladder; on a Shell at its base.
		local looks = {}
		for _, id in ipairs(IDS) do
			local cf = CFrame.new(tier * 60, 600, 2400)
			local pod = CreatureModel.BuildPod(SeedData.Get(id), tier, cf, scratch)
			local lo, hi = drawn(pod, cf)
			local size = hi - lo
			if not (spec and near(size.Y, spec.Size.Y, 0.01) and near(size.X, spec.Size.X, 0.01)
				and near(size.Z, spec.Size.Z, 0.01) and math.abs(lo.Y) < 0.01 and pod.PrimaryPart
				and pod.PrimaryPart.Name == "Shell" and pod:GetAttribute("SecretForm") == form
				and pod:GetAttribute("Tier") == tier and pod:GetAttribute("Stage") == CreatureModel.STAGE_POD) then
				table.insert(podBad, string.format("%s@%d %.2f", id, tier, size.Y))
			end
			table.insert(looks, look(pod))
			pod:Destroy()
		end
		-- Which creature is inside changes nothing about the shell.
		for i = 2, #looks do
			if looks[i] ~= looks[1] then
				table.insert(podLook, tier)
				break
			end
		end
	end
	local rising = true
	for tier = 2, #heights do
		rising = rising and heights[tier] > heights[tier - 1]
	end
	check(#podBad == 0, "tier 1..7 build Pod (Tiny), (big), (huge), (Mega), (Giant), (Titan), (Colossal) -- matched by "
		.. "name, each exactly as tall as supplied, on its base Shell", table.concat(podBad, ", "))
	check(heights[4] < heights[5] and SeedData.Get("monsoad").PodForms[4] == "rain2pod_mega"
		and SeedData.Get("monsoad").PodForms[5] == "rain2pod_giant" and rising,
		string.format("Mega is tier 4 (%.2f studs) and Giant tier 5 (%.2f), and the seven rise with the size",
			heights[4], heights[5]))
	check(not near(heights[7], heights[1] * SeedData.SizeScale(7), 0.5)
		and not near(heights[7], RainForms.Pods.rain2pod_colossal.Size.Y * SeedData.SizeScale(7), 0.5),
		string.format("no double scaling: the Colossal pod is its supplied %.2f studs -- not the Tiny x 7.6 (%.2f) nor "
			.. "itself x 7.6 (%.2f)", heights[7], heights[1] * 7.6, heights[7] * 7.6))
	check(#podLook == 0, "at every size the shell is the same whichever of the four is inside", table.concat(podLook, ", "))

	--==========================================================================
	say("6. Before the hatch, a shell: its size, never its creature or its rarity")
	--==========================================================================
	local leak = {}
	local faces = {}
	for _, id in ipairs(IDS) do
		for tier = 1, SeedData.TierCount do
			local info = PlantInfo.Describe(id, tier, false, 2)
			local text = string.lower(info.title .. " " .. info.rarity .. " " .. info.size .. " " .. info.income)
			if info.title ~= "Rain pod" or info.rarity ~= PlantInfo.Unknown or info.sized ~= true
				or info.size ~= SeedData.TierName(tier) or info.incomePerSecond ~= nil or info.sell ~= nil
				or info.sellValue ~= nil or string.find(text, string.lower(OWNER[id][1]), 1, true)
				or string.find(text, string.lower(OWNER[id][2]), 1, true) then
				table.insert(leak, id .. "@" .. tier)
			end
			local f = InventoryModel.face({ ref = "i:1", kind = "pod", speciesId = id, tier = tier, hatched = false,
				sealed = false, restoring = false, count = 1, worn = false, favourite = false, order = 1 })
			local key = table.concat({ f.name, f.variant, f.visual, tostring(f.rarity), f.search, f.category }, "|")
			faces[tier] = faces[tier] or key
			if key ~= faces[tier] or f.rarity ~= nil or f.name ~= "Rain pod" or f.variant ~= SeedData.TierName(tier)
				or string.find(string.lower(key), id, 1, true) then
				table.insert(leak, "face " .. id .. "@" .. tier)
			end
		end
	end
	check(#leak == 0, "every unhatched pod reads Rain pod, ??? and its size word in the garden panel, the Bag and the "
		.. "hotbar -- the same face for all four -- with no income or price", table.concat(leak, ", "))
	local carrySrc = sourceOf(Server, "CarryService")
	check(string.find(carrySrc, 'elseif rainPod and not hatched and not podRarity then string.format("%s  ·  %d tier", '
		.. "rainPod.Name, tier)", 1, true) ~= nil and SeedData.RainPods.rainpod4.Rarity == nil
		and SeedData.RainPods.rainpod5.Rarity == nil,
		"the Tool's tooltip names the pod and its size only: neither pod has a rarity to show")
	local hatchedInfo = PlantInfo.Describe("torrentacle", 7, true, 1)
	check(hatchedInfo.title == "Torrentacle" and hatchedInfo.rarity == "Mythic" and hatchedInfo.size == "Colossal"
		and hatchedInfo.incomePerSecond == 150000,
		"the hatch reveals it: Torrentacle, Mythic, Colossal, $150K/s")
	check(PlantService ~= nil and string.find(sourceOf(Server, "PlantService"),
		"local revealAt = if entry.species.SkipHatchRoll == true then now else HatchRoll.revealAt(now)", 1, true) ~= nil,
		"and, like the first family, straight into the reveal (no silhouette roll)")

	--==========================================================================
	say("7. The draw: a Colossal in 5% of Rains, the even split, the creatures 40/25/25/10")
	--==========================================================================
	local batch = SeedData.RainBatches.rain
	local W, CW = batch.Weights, batch.ColossalWeights or {}
	local total, ctotal = 0, 0
	for _, w in pairs(W) do
		total += w
	end
	for _, w in pairs(CW) do
		ctotal += w
	end
	-- Per egg (the owner, 2026-10-06): ONE Colossal draw a Rain, 5 in 100, on one
	-- slot of three -- so a slot is the Colossal one 5% / 3 of the time.
	local colossalSlot = (batch.ColossalChance or 0) / batch.Slots
	local share4 = (1 - colossalSlot) * (W.rainpod4 or 0) / total
	local share5 = colossalSlot * (CW.rainpod5 or 0) / math.max(ctotal, 1)
	local p4, p5 = SeedData.RainPods.rainpod4, SeedData.RainPods.rainpod5
	local tierTotal = 0
	for t = 1, #p4.Tiers do
		tierTotal += p4.Tiers[t]
	end
	local oddsTotal = 40 + 25 + 25 + 10
	-- Per egg, in % (Tiny .. Titan, then Colossal), under the rule of 2026-10-06:
	-- 5% a Rain on one slot of three, each half 50/50, the creatures 40/25/25/10,
	-- the sizes the global ladder's. Under the old per-slot rule (2026-10-05) the
	-- owner's table ran from Tiny Squallsnapper 9.635% to Colossal Torrentacle 0.5%.
	local TABLE = {
		squallsnapper = { 10.527, 3.149, 1.991, 1.560, 1.170, 1.269, 0.333 },
		monsoad = { 6.580, 1.968, 1.244, 0.975, 0.731, 0.793, 0.208 },
		thundershell = { 6.580, 1.968, 1.244, 0.975, 0.731, 0.793, 0.208 },
		torrentacle = { 2.632, 0.787, 0.498, 0.390, 0.293, 0.317, 0.083 },
	}
	local oddsBad = {}
	for i, id in ipairs(IDS) do
		local share = p4.Weights[i] / oddsTotal
		for tier = 1, 6 do
			local got = share4 * share * p4.Tiers[tier] / tierTotal * 100
			if not near(got, TABLE[id][tier], 0.0006) then
				table.insert(oddsBad, string.format("%s@%d %.4f", id, tier, got))
			end
		end
		local gotC = share5 * p5.Weights[i] / oddsTotal * 100
		if not near(gotC, TABLE[id][7], 0.0006) then
			table.insert(oddsBad, string.format("%s@7 %.4f", id, gotC))
		end
	end
	check(#oddsBad == 0 and table.concat(p4.Weights, ",") == "40,25,25,10" and table.concat(p5.Weights, ",") == "40,25,25,10"
		and #p4.Tiers == 6 and p5.Tier == 7 and near(share4 + share5, 0.5, 1e-12),
		"per egg, exactly the table: Squallsnapper 20%, Monsoad 12.5%, Thundershell 12.5%, Torrentacle 5% "
			.. "(Tiny Squallsnapper 10.527% .. Colossal Torrentacle 0.083%), the old family 50%", table.concat(oddsBad, ", "))
	local tierW = {}
	for t = 1, 6 do
		tierW[t] = p4.Tiers[t] == SeedData.Tiers[t].weight
	end
	check(not table.find(tierW, false) and p4.Tiers[7] == nil,
		"rainpod4's sizes are the global ladder's own weights, Tiny .. Titan, and never Colossal")
	-- The draws themselves, at their boundaries.
	local PW = SeedData.PickWeighted
	check(PW({ 40, 25, 25, 10 }, 0) == 1 and PW({ 40, 25, 25, 10 }, 0.3999999) == 1 and PW({ 40, 25, 25, 10 }, 0.4) == 2
		and PW({ 40, 25, 25, 10 }, 0.6499999) == 2 and PW({ 40, 25, 25, 10 }, 0.65) == 3
		and PW({ 40, 25, 25, 10 }, 0.8999999) == 3 and PW({ 40, 25, 25, 10 }, 0.9) == 4 and PW({ 40, 25, 25, 10 }, 1) == 4
		and PW({ 0, 1 }, 0) == 2 and PW({ 1, 0 }, 1) == 1,
		"the creature draw: below 0.40 Squallsnapper, to 0.65 Monsoad, to 0.90 Thundershell, from 0.90 Torrentacle; "
			.. "a weight of 0 never draws")
	local cut = 0
	local cuts = {}
	for t = 1, 6 do
		cut += p4.Tiers[t] / tierTotal
		cuts[t] = cut
	end
	local tierOk = PW(p4.Tiers, 0) == 1 and PW(p4.Tiers, cuts[1] - 1e-7) == 1 and PW(p4.Tiers, cuts[1] + 1e-7) == 2
		and PW(p4.Tiers, cuts[5] + 1e-7) == 6 and PW(p4.Tiers, 1) == 6
	check(tierOk, string.format("the size draw: Tiny below %.4f, then Big, Huge, Mega, Giant, Titan to 1 -- never Colossal",
		cuts[1]))
	-- Scripted: the batch's Colossal draw first (0.01, a hit; the pick slot 2).
	-- Slot 1 lands on rainpod4 and draws its creature, then its size; slot 2,
	-- the Colossal one, lands on rainpod5 and draws its creature only; slot 3 is
	-- an old Rain pod.
	local draws, used, ints = { 0.01, 0.70, 0.66, 0.99, 0.96, 0.95, 0.10 }, 0, 0
	local scripted = {
		NextNumber = function()
			used += 1
			return draws[used]
		end,
		NextInteger = function(_, lo)
			ints += 1
			return if ints == 1 then 2 else lo
		end,
	}
	local seq = SeedData.RollRainBatch("rain", scripted)
	check(#seq == 3 and seq[1].pod == "rainpod4" and seq[1].species.Id == "thundershell" and seq[1].tier == 6
		and seq[2].pod == "rainpod5" and seq[2].species.Id == "torrentacle" and seq[2].tier == 7
		and seq[3].pod == "rainpod1" and seq[3].tier == 1 and used == 7 and ints == 2,
		"a hit (0.01) on slot 2: draws 0.70 / 0.66 / 0.99 lay a Titan Thundershell in rainpod4; the Colossal slot "
			.. "0.96 / 0.95 a Colossal Torrentacle in rainpod5; 0.10 an old Rain pod",
		string.format("%s %s %s, %d draws", tostring(seq[1].species.Id), tostring(seq[2].species.Id),
			tostring(seq[3].pod), used))
	-- A seeded sample; every tolerance four standard errors of its own sample size.
	local function close(share, p, n)
		return n > 0 and math.abs(share - p) <= 4 * math.sqrt(p * (1 - p) / n) + 1e-9
	end
	local rng = Random.new(20261006)
	local N, slots, colossal, perSpecies, perTier = 8000, 0, 0, {}, {}
	for _ = 1, N do
		for _, roll in ipairs(SeedData.RollRainBatch("rain", rng)) do
			slots += 1
			if roll.tier == SeedData.TierCount then
				colossal += 1
			end
			if roll.pod == "rainpod4" or roll.pod == "rainpod5" then
				perSpecies[roll.species.Id] = (perSpecies[roll.species.Id] or 0) + 1
				perTier[roll.tier] = (perTier[roll.tier] or 0) + 1
			end
		end
	end
	local fam = 0
	for _, n in pairs(perSpecies) do
		fam += n
	end
	local tinyShare = share4 / (share4 + share5) * p4.Tiers[1] / tierTotal
	check(close(colossal / slots, colossalSlot, slots) and close(fam / slots, 0.5, slots)
		and close((perSpecies.squallsnapper or 0) / math.max(fam, 1), 0.40, fam)
		and close((perSpecies.torrentacle or 0) / math.max(fam, 1), 0.10, fam)
		and close((perTier[1] or 0) / math.max(fam, 1), tinyShare, fam) and (perTier[6] or 0) > 0,
		string.format("seeded sample of %d slots: Colossal %.2f%% (%.2f%% asked), the family %.1f%%, Squallsnapper "
			.. "%.1f%% of it, Torrentacle %.1f%%, Tiny %.1f%%", slots, colossal / slots * 100, colossalSlot * 100,
			fam / slots * 100, (perSpecies.squallsnapper or 0) / math.max(fam, 1) * 100,
			(perSpecies.torrentacle or 0) / math.max(fam, 1) * 100, (perTier[1] or 0) / math.max(fam, 1) * 100))

	--==========================================================================
	say("8. At the nest: laid once by the server, in its size's own shell")
	--==========================================================================
	local site = {
		centre = Vector3.new(0, 501.11, 2600),
		floorY = 500,
		route = { Vector3.new(-300, 500, 2600), Vector3.new(-150, 500, 2600) },
		setDown = Vector3.new(-300, 500, 2600),
		parent = scratch,
	}
	local seenFamily, shellBad, laidBad = 0, {}, 0
	for attempt = 1, 12 do
		local laid = NestService.OpenEventNest(900 + attempt, "rain", site)
		local info = NestService.EventNest()
		if laid ~= 3 or not info or #info.pods ~= 3 then
			laidBad += 1
		else
			for _, p in ipairs(info.pods) do
				local sp = SeedData.Get(p.species)
				if p.pod == "rainpod4" or p.pod == "rainpod5" then
					seenFamily += 1
					local spec = RainForms.Pods[SeedData.PodFormOf(sp, p.tier)]
					local lo, hi = drawn(p.model, p.model:GetPivot())
					if not (spec and p.model:GetAttribute("SecretForm") == SeedData.PodFormOf(sp, p.tier)
						and p.model:GetAttribute("RainPod") == p.pod and p.model:GetAttribute("Tier") == p.tier
						and near((hi - lo).Y, spec.Size.Y, 0.02)) then
						table.insert(shellBad, p.species .. "@" .. p.tier)
					end
				end
			end
		end
		NestService.CloseEventNest(900 + attempt)
	end
	check(laidBad == 0 and seenFamily > 0 and #shellBad == 0,
		string.format("twelve Rains: always three pods; %d of the 36 were the new family, each in its size's own shell, "
			.. "pod and tier stamped on it", seenFamily), table.concat(shellBad, ", "))

	--==========================================================================
	say("9. The old Rain, the Thunderstorm and the road are as they were")
	--==========================================================================
	local R = SeedData.RainPods
	check(R.rainpod1.Rarity == "Mythic" and R.rainpod1.Tier == 1 and R.rainpod1.Sized == false
		and R.rainpod1.GrowSeconds == 10800 and table.concat(R.rainpod1.Species, ",") == "puddlepod,drizzlet,lotusling"
		and R.rainpod2.Rarity == "Mythic" and R.rainpod2.Tier == 7 and R.rainpod2.Sized == true
		and R.rainpod2.GrowSeconds == 21600
		and table.concat(R.rainpod2.Species, ",") == "puddlepod_colossal,drizzlet_colossal,lotusling_colossal"
		and R.rainpod3.Rarity == "Divine" and R.rainpod3.Tier == 1 and R.rainpod3.GrowSeconds == 32400
		and table.concat(R.rainpod3.Species, ",") == "tempestoak,thundermaw" and R.rainpod1.Weights == nil
		and R.rainpod2.Weights == nil and R.rainpod3.Weights == nil,
		"Pods 1, 2 and 3: the same rosters, rarities, tiers, sizes and growth, each creature still equally likely")
	local oldRates = { puddlepod = 80000, drizzlet = 85000, lotusling = 90000, puddlepod_colossal = 120000,
		drizzlet_colossal = 135000, lotusling_colossal = 150000, tempestoak = 250000, thundermaw = 265000 }
	local oldBad = {}
	for id, rate in pairs(oldRates) do
		local sp = SeedData.Get(id)
		if not sp or sp.FixedIncome ~= rate or SeedData.IncomePerSecond(sp, 4) ~= rate or sp.TierIncome ~= nil
			or sp.PodForms ~= nil or SeedData.PodFormOf(sp, 4) ~= sp.Pod then
			table.insert(oldBad, id)
		end
	end
	check(#oldBad == 0 and SeedData.RainBatches.thunder.Slots == 1 and SeedData.RainBatches.thunder.Weights.rainpod3 == 1
		and GameConfig.Secret.Toast.WeatherEggs.rainpod3 == true and GameConfig.Secret.Toast.WeatherEggs.rainpod4 == nil
		and GameConfig.Secret.Toast.WeatherEggs.rainpod5 == nil
		and SeedData.Get("tempestoak").CarrySpeedFactor == 0.5,
		"the first family's fixed rates and one shell each; a Thunderstorm still one Pod 3 at half carry speed, the "
			.. "only weather egg with a toast -- a new Mythic or Colossal is plain Rain", table.concat(oldBad, ", "))
	local secrets = SeedData.Get("snarlbloom")
	check(secrets and SeedData.PodFormOf(secrets, 1) == secrets.Pod and SeedData.PodFormOf(SeedData.Get("nubkin"), 3) == nil,
		"a Secret keeps its one shell; an ordinary species has none (the road's egg)")

	--==========================================================================
	say("10. In no pool, shelf or reward")
	--==========================================================================
	local listed = {}
	for _, sp in ipairs(SeedData.Species) do
		if OWNER[sp.Id] then
			table.insert(listed, sp.Id)
		end
	end
	for biome, list in pairs(SeedData.ByBiome) do
		for _, sp in ipairs(list) do
			if OWNER[sp.Id] then
				table.insert(listed, biome .. ":" .. sp.Id)
			end
		end
	end
	local drawnRoad = {}
	local rr = Random.new(77)
	for biome in pairs(SeedData.ByBiome) do
		for _ = 1, 400 do
			local sp = SeedData.Roll(biome, rr)
			if sp and OWNER[sp.Id] then
				table.insert(drawnRoad, biome)
				break
			end
		end
	end
	check(#listed == 0 and #drawnRoad == 0 and #SeedData.Species == 25 and #SeedData.InBiome("rain") == 0,
		"not in the 25 listed species, any biome's pool or roll, or the Index (which lists those)",
		table.concat(listed, ",") .. " / " .. table.concat(drawnRoad, ","))
	local poolHits = {}
	for _, inst in ipairs(Shared:GetDescendants()) do
		if inst:IsA("ModuleScript") and (inst.Name == "WheelData" or inst.Name == "BiomeData" or inst.Name == "AlmanacData"
			or inst.Name == "RewardData") then
			for _, id in ipairs(IDS) do
				if string.find(inst.Source, '"' .. id .. '"', 1, true) then
					table.insert(poolHits, inst.Name .. ":" .. id)
				end
			end
		end
	end
	local adminSrc = sourceOf(Server, "AdminService")
	for _, id in ipairs(IDS) do
		if string.find(adminSrc, id, 1, true) then
			table.insert(poolHits, "AdminService:" .. id)
		end
	end
	check(#poolHits == 0, "no wheel, biome-reward, Almanac or admin-grant table names any of them",
		table.concat(poolHits, ", "))

	--==========================================================================
	say("11. The save keeps species, size and stage, through JSON")
	--==========================================================================
	local raw = ProfileSchema.Default()
	raw.Plants, raw.Held = {}, {}
	for _, id in ipairs(IDS) do
		local sp = SeedData.Get(id)
		for tier = 1, SeedData.TierCount do
			table.insert(raw.Held, { Id = id, Tier = tier, Hatched = false })
			table.insert(raw.Held, { Id = id, Tier = tier, Hatched = true })
			table.insert(raw.Plants, { SpeciesId = id, PlantedAt = 1000, HatchAt = 1000 + SeedData.GrowSecondsFor(sp, tier),
				Tier = tier, X = 1, Z = 2, Stage = 1, Facing = 3 })
		end
	end
	local round = ProfileSchema.Sanitise(HttpService:JSONDecode(HttpService:JSONEncode(ProfileSchema.Sanitise(raw))))
	local kept = #round.Held == #raw.Held and #round.Plants == #raw.Plants
	for i, row in ipairs(raw.Held) do
		local back = round.Held[i]
		kept = kept and back ~= nil and back.Id == row.Id and back.Tier == row.Tier and back.Hatched == row.Hatched
			and type(back.Item) == "string"
	end
	for i, row in ipairs(raw.Plants) do
		local back = round.Plants[i]
		kept = kept and back ~= nil and back.SpeciesId == row.SpeciesId and back.Tier == row.Tier
			and back.HatchAt == row.HatchAt
	end
	check(kept, "all 4 x 7 sizes, pod and plant, in the bag and in the ground, come back exactly -- with an item id each",
		string.format("%d/%d held, %d/%d planted", #round.Held, #raw.Held, #round.Plants, #raw.Plants))

	--==========================================================================
	say("12. Carried, held and framed as the Rain forms are")
	--==========================================================================
	local carryBad = {}
	for _, id in ipairs(IDS) do
		local sp = SeedData.Get(id)
		if not (PlantForms.CarriedOverhead(sp, false) and PlantForms.CarriedOverhead(sp, true)) then
			table.insert(carryBad, id .. " overhead")
		end
		for tier = 1, SeedData.TierCount do
			local podSize = SecretModel.Size(SeedData.PodFormOf(sp, tier))
			local plantSize = PlantForms.SizeAt(id, SeedData.SizeScale(tier))
			if not (podSize and podSize == RainForms.Pods[PODS[tier][1]].Size and plantSize
				and (plantSize - PlantForms.Plants[id].Size * SeedData.SizeScale(tier)).Magnitude < 1e-6) then
				table.insert(carryBad, id .. "@" .. tier)
			end
		end
	end
	local cameraSrc = sourceOf(Scripts, "SecretCarryCamera")
	check(#carryBad == 0 and string.find(carrySrc, 'if species and (species :: any).Carry == "overhead" then', 1, true) ~= nil
		and string.find(cameraSrc, "local form = if hatched then species.Id else SeedData.PodFormOf(species, tonumber(tier))",
			1, true) ~= nil
		and string.find(cameraSrc, "if hatched and PlantForms.Has(species.Id) then", 1, true) ~= nil,
		"pod and plant ride over the head; the carry camera frames the size's own shell, or the plant at its size",
		table.concat(carryBad, ", "))
	check(string.find(carrySrc, 'if type(form) == "string" and PlantForms.Plants[form] then', 1, true) ~= nil
		and PlantForms.Plants.torrentacle ~= nil,
		"a held copy drops its joints, as every PlantForms rig's does (these have parts called Head and Torso)")
	check(string.find(sourceOf(Server, "PlantService"), "SeedData.PodFormOf(entry.species, entry.tier) ~= nil", 1, true) ~= nil
		and string.find(sourceOf(Shared, "CreatureModel"), "local secretPod = SeedData.PodFormOf(sp, tier)", 1, true) ~= nil,
		"a planted pod stands at the replayed pods' fixed facing, built from its saved size's shell")

	--==========================================================================
	say("13. They walk on their own legs; Thundershell moves on its sole")
	--==========================================================================
	local LAST = {
		squallsnapper = { "HipL", "HipR" },
		monsoad = { "AnkleL", "WristL", "AnkleR", "WristR" },
		torrentacle = { "AnkleFL", "AnkleSR", "AnkleBL", "AnkleFR", "AnkleSL", "AnkleBR" },
	}
	local walkBad = {}
	for _, id in ipairs(IDS) do
		local profile = PlantIdles.Walks[id]
		if id == "thundershell" then
			if profile ~= nil then
				table.insert(walkBad, "thundershell has a walk")
			end
			continue
		end
		if not profile or profile.nod ~= nil or #profile.arms ~= 0 then
			table.insert(walkBad, id .. " profile")
			continue
		end
		for _, tier in ipairs({ 1, 7 }) do
			local cf = CFrame.new(0, 700, 3200 + tier * 200)
			local model = CreatureModel.BuildCreature(SeedData.Get(id), tier, CreatureModel.STAGE_GROWN, cf, scratch)
			local rig = SecretIdle.Rig(model)
			if not (rig and rig.gait and #rig.gait.legs == #LAST[id]) then
				table.insert(walkBad, id .. "@" .. tier .. " no gait")
				model:Destroy()
				continue
			end
			local feet = {}
			for _, name in ipairs(LAST[id]) do
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA("Motor6D") and d.Name == name then
						table.insert(feet, d.Part1)
					end
				end
			end
			rig.walks = true
			local pivot0 = model:GetPivot()
			local speed = SeedData.WanderSpeed(tier)
			local lowest, swung, frames, lastAt = math.huge, 0, 0, {}
			local t = 0
			for i = 1, 300 do
				t += 1 / 30
				model:PivotTo(pivot0 * CFrame.new(0, 0, -speed * t))
				SecretIdle.Step(rig, t)
				if i > 30 then
					local lo = drawn(model, cf * CFrame.new(0, 0, -speed * t))
					lowest = math.min(lowest, lo.Y)
					for k, foot in ipairs(feet) do
						if lastAt[k] then
							frames += 1
							if (foot.Position - lastAt[k]).Magnitude > speed / 30 * 1.2 then
								swung += 1
							end
						end
					end
				end
				for k, foot in ipairs(feet) do
					lastAt[k] = foot.Position
				end
			end
			rig.walks = false
			model:PivotTo(pivot0)
			SecretIdle.Rest(rig)
			local worst = 0
			for _, node in ipairs(rig.nodes) do
				worst = math.max(worst, (pivot0:ToObjectSpace(node.part.CFrame).Position - node.rel.Position).Magnitude)
			end
			-- A swing leg dips its sole as it turns (the road's Spiretip and Toadcap: 0.24 and 0.5 of their
			-- size); a solved leg stays on the soil.
			local floor = if id == "squallsnapper" then -0.2 * rig.scale else -0.01 * rig.scale
			if lowest < floor or swung < frames * 0.2 or worst > 1e-3 * rig.scale then
				table.insert(walkBad, string.format("%s@%d low %.3f swung %d/%d rest %.4f", id, tier, lowest, swung, frames,
					worst))
			end
			model:Destroy()
		end
	end
	check(#walkBad == 0, "Squallsnapper steps on two swing legs, Monsoad on four solved legs, Torrentacle on six solved "
		.. "tentacles -- on the soil, Tiny and Colossal, and back to rest exactly; no nod or arm swing to drift",
		table.concat(walkBad, ", "))

	--==========================================================================
	say("14. A Colossal one crackles; nothing smaller does")
	--==========================================================================
	local cfA = CFrame.new(0, 700, 5000)
	local colossalModel = CreatureModel.BuildCreature(SeedData.Get("torrentacle"), 7, CreatureModel.STAGE_GROWN, cfA, scratch)
	local titanModel = CreatureModel.BuildCreature(SeedData.Get("monsoad"), 6, CreatureModel.STAGE_GROWN,
		cfA * CFrame.new(80, 0, 0), scratch)
	local state = PlantAura.Prepare(colossalModel, 20, "rain", SeedData.TierCount, 0, Random.new(3))
	local none = PlantAura.Prepare(titanModel, 20, "rain", SeedData.TierCount, 0, Random.new(4))
	check(state ~= nil and none == nil, "a Colossal Torrentacle gets the crackle's state; a Titan Monsoad does not")
	PlantAura.Forget(state)
end)

plots.PlotOf, plots.OwnerOf, plants.GrownIn = real.PlotOf, real.OwnerOf, real.GrownIn
passes.CashMultiplier, chest.Multiplier, sacrifice.Multiplier = real.CashMultiplier, real.Chest, real.Sacrifice
weather.IncomeFactor = real.IncomeFactor
pcall(function()
	NestService.CloseEventNest(nil)
end)
scratch:Destroy()
if not auraBefore then
	local made = Workspace:FindFirstChild("SeedPlantAura")
	if made then
		made:Destroy()
	end
end
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("RainFamilySpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
