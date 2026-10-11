--==============================================================================
-- MistCreaturesSpec (2026-10-11, Enchanted Mist)
--
-- The Mysterious Pod's five new creatures, ported from the owner's
-- "ENCHANTED MIST" models (SeedData.MistSpecies, PlantForms), by the owner's
-- answers of 2026-10-11:
--
--   1. registered, unlisted, the pool's rarities; Snarlbloom untouched
--   2. the rates: the Rain earning ladder off each Tiny, size by size; Gnarlmaw
--      140,000 fixed
--   3. the sizes: one factor for the four, Elderbough's Colossal the road's
--      largest Colossal; Gnarlmaw the folder's display scale undone
--   4. built for real at those sizes, with no script, and drawn on the cards
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SeedData = require(Shared:WaitForChild("SeedData"))
local PlantForms = require(Shared:WaitForChild("PlantForms"))
local SecretForms = require(Shared:WaitForChild("SecretForms"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local MistOddsView = require(Shared:WaitForChild("MistOddsView"))

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

-- The owner's numbers, written out (2026-10-11).
local RATES = {
	mossbristle = { 25000, 28750, 32500, 37500, 45000, 53750, 62500 },
	briarstag = { 60000, 69000, 78000, 90000, 108000, 129000, 150000 },
	hollowl = { 60000, 69000, 78000, 90000, 108000, 129000, 150000 },
	elderbough = { 120000, 138000, 156000, 180000, 216000, 258000, 300000 },
}
-- Drawn heights in studs, Tiny and Colossal, from the owner's sizing.
local HEIGHTS = {
	mossbristle = { 3.93, 29.90 },
	briarstag = { 6.17, 46.90 },
	hollowl = { 4.61, 35.03 },
	elderbough = { 8.86, 67.34 },
}
local SIZED = { "mossbristle", "briarstag", "hollowl", "elderbough" }

local function drawnHeight(model: Model): number
	local lo, hi = math.huge, -math.huge
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d.Transparency < 0.99 then
			local h = d.Size / 2
			for _, x in ipairs({ -1, 1 }) do
				for _, y in ipairs({ -1, 1 }) do
					for _, z in ipairs({ -1, 1 }) do
						local c = d.CFrame:PointToWorldSpace(Vector3.new(h.X * x, h.Y * y, h.Z * z))
						lo = math.min(lo, c.Y)
						hi = math.max(hi, c.Y)
					end
				end
			end
		end
	end
	return hi - lo
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. Registered, unlisted")
	--==========================================================================
	local listed = {}
	for _, s in ipairs(SeedData.Species) do
		listed[s.Id] = true
	end
	for _, s in ipairs(SeedData.InBiome("greenhollow")) do
		listed[s.Id] = true
	end
	local mist = {}
	for _, s in ipairs(SeedData.MistSpecies) do
		mist[s.Id] = s
	end
	local wrong = {}
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		local s = SeedData.Get(e.Id)
		local isNew = e.Id ~= "snarlbloom"
		if not s or s.Rarity ~= e.Rarity or s.Name ~= e.Name or listed[e.Id]
			or (isNew and (mist[e.Id] ~= s or (s :: any).Mist ~= true)) then
			table.insert(wrong, e.Id)
		end
	end
	check(#wrong == 0 and #SeedData.MistSpecies == 5,
		"every pool creature is registered at its pool rarity; the five new are the Mist's own and in no pool or shelf",
		table.concat(wrong, ","))
	local snarl = SeedData.Get("snarlbloom") :: any
	check(snarl and snarl.Secret == true and snarl.FixedIncome == 155000 and snarl.Mist == nil
			and math.abs(SecretForms.Plants.snarlbloom.Height - 47.26) < 1e-3 and mist.snarlbloom == nil,
		"Snarlbloom is the existing Secret, untouched: its id, form, size and $155,000/s")

	--==========================================================================
	say("2. The owner's rates")
	--==========================================================================
	local badRates = {}
	for _, id in ipairs(SIZED) do
		local s = SeedData.Get(id)
		for tier = 1, SeedData.TierCount do
			if SeedData.IncomePerSecond(s, tier) ~= RATES[id][tier] then
				table.insert(badRates, id .. "@" .. tier .. "=" .. tostring(SeedData.IncomePerSecond(s, tier)))
			end
		end
		if (s :: any).FixedIncome ~= nil or (s :: any).Secret == true then
			table.insert(badRates, id .. " fixed/secret")
		end
	end
	check(#badRates == 0, "the four sized ones pay the Rain ladder off their Tiny, size by size, exactly the owner's numbers",
		table.concat(badRates, " "))
	local gnarl = SeedData.Get("gnarlmaw") :: any
	check(gnarl and gnarl.Secret == true and SeedData.Unsized(gnarl) and gnarl.TierIncome == nil
			and SeedData.IncomePerSecond(gnarl, SeedData.SecretTier) == 140000
			and SeedData.IncomePerSecond(gnarl, SeedData.TierCount) == 140000,
		"Gnarlmaw is a Secret: one size and $140,000/s fixed, whatever tier is asked")

	--==========================================================================
	say("3. The owner's sizes")
	--==========================================================================
	local factors = {}
	local badSizes = {}
	for _, id in ipairs(SIZED) do
		local spec = PlantForms.Plants[id]
		local tiny = spec.Height * (PlantForms.Scale(id, SeedData.SizeScale(1)) :: number)
		local colossal = spec.Height * (PlantForms.Scale(id, SeedData.SizeScale(SeedData.TierCount)) :: number)
		table.insert(factors, PlantForms.TinyHeight[id] / spec.Height)
		if math.abs(tiny - HEIGHTS[id][1]) > 0.01 or math.abs(colossal - HEIGHTS[id][2]) > 0.01 then
			table.insert(badSizes, string.format("%s %.3f->%.3f", id, tiny, colossal))
		end
	end
	local same = true
	for _, f in ipairs(factors) do
		same = same and math.abs(f - factors[1]) < 1e-9
	end
	local roadTallest = 0
	for id, tall in pairs(PlantForms.TinyHeight) do
		if not SeedData.Get(id) or (SeedData.Get(id) :: any).Mist ~= true then
			roadTallest = math.max(roadTallest, tall)
		end
	end
	local elder = PlantForms.TinyHeight.elderbough * SeedData.SizeScale(SeedData.TierCount)
	check(#badSizes == 0 and same and math.abs(elder - roadTallest * SeedData.SizeScale(SeedData.TierCount)) < 1e-6,
		"one factor for the four: Tiny 3.93 / 6.17 / 4.61 / 8.86, Colossal 29.90 / 46.90 / 35.03 / 67.34 -- "
			.. "Elderbough's Colossal the road's largest", table.concat(badSizes, " "))
	local g = PlantForms.Plants.gnarlmaw
	local gTall = g.Height * (PlantForms.Scale("gnarlmaw", SeedData.SizeScale(SeedData.SecretTier)) :: number)
	check(math.abs(gTall - 54.34) < 0.01
			and math.abs(gTall / g.Height - SecretForms.Plants.snarlbloom.Height / 38.905174) < 1e-9,
		"Gnarlmaw is the folder's display scale undone (Snarlbloom's copy back to Snarlbloom): 54.34 studs", gTall)

	--==========================================================================
	say("4. Built, scriptless, and on the cards")
	--==========================================================================
	local holder = Instance.new("Folder")
	local built = {}
	local scripts = 0
	for _, case in ipairs({ { "elderbough", SeedData.TierCount, 67.34 }, { "mossbristle", 1, 3.93 },
		{ "gnarlmaw", SeedData.SecretTier, 54.34 } }) do
		local model = CreatureModel.Build(SeedData.Get(case[1]), case[2], CreatureModel.STAGE_GROWN, CFrame.new(), holder)
		local h = drawnHeight(model)
		if math.abs(h - case[3]) > 0.02 then
			table.insert(built, string.format("%s t%d %.3f", case[1], case[2], h))
		end
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("LuaSourceContainer") then
				scripts += 1
			end
		end
	end
	check(#built == 0 and scripts == 0, "built for real at those heights, with none of the models' scripts",
		table.concat(built, " ") .. " scripts " .. scripts)
	local views = {}
	local dark = 0
	for _, e in ipairs(EnchantedMistData.Pool.Entries) do
		local card = MistOddsView.card(holder, e, 1, 140, {}, {}, views)
		if card:FindFirstChild("Unknown", true) then
			dark += 1
		end
	end
	MistOddsView.drawViews(views)
	local drawn = 0
	for _, v in ipairs(views) do
		if v.view:FindFirstChildWhichIsA("Model", true) and v.view.CurrentCamera then
			drawn += 1
		end
	end
	holder:Destroy()
	check(dark == 0 and drawn == #EnchantedMistData.Pool.Entries,
		"every Odds and reel card shows its creature: no \"???\" left", string.format("dark %d drawn %d", dark, drawn))

	--==========================================================================
	say("5. Animated: their idles (the walks are PlantRigsSpec's)")
	--==========================================================================
	local SecretIdle = require(Shared:WaitForChild("SecretIdle"))
	local PlantIdles = require(Shared:WaitForChild("PlantIdles"))
	-- Every joint each idle is written to move -- a name spelled wrong would be
	-- skipped without a word, so the set is pinned.
	local function list(prefix, n, extra)
		local out = table.clone(extra or {})
		for i = 1, n do
			table.insert(out, prefix .. i)
		end
		return out
	end
	local POSED = {
		mossbristle = { "Root", "HipFL", "HipFR", "HipHL", "HipHR", "BackA", "BackB", "BackC", "Head", "EarL", "EarR",
			"Sprout", "Tail1", "Tail2" },
		briarstag = list("Mane", 4, { "Chest", "NeckLower", "NeckUpper", "Head", "Jaw", "EarL", "EarR", "Tail1",
			"Tail2", "Sapling" }),
		hollowl = list("PrimaryR", 3, list("PrimaryL", 3, { "Chest", "Neck", "Head", "TuftL", "TuftR", "WingUpperL",
			"WingUpperR", "Tail", "TailFeatherL", "TailFeatherR" })),
		elderbough = list("VineR", 3, list("VineL", 3, list("FingerR", 3, list("FingerL", 3, { "Spine", "Chest",
			"Neck", "Head", "BrowL", "BrowR", "Jaw", "CanopyTop", "CanopyFront", "CanopyBack", "CanopyL", "CanopyR",
			"BranchL1", "BranchR1", "BranchL2", "BranchR2", "WispHub", "WispA", "WispB", "WispC", "UpperArmL",
			"UpperArmR", "ForearmL", "ForearmR" })))),
		gnarlmaw = list("WhipR", 3, list("WhipL", 3, list("VineR", 4, list("VineL", 4, list("Frond", 6, { "Bulb",
			"Trunk", "Neck1", "Neck2", "Head", "LobeUpper", "LobeLower", "Tongue", "Lure1", "Lure2" }))))),
	}
	local stage = Instance.new("Folder")
	local function snapshot(model)
		local out = {}
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				out[d] = d.CFrame
			end
		end
		return out
	end
	local function worst(a, b)
		local w = 0
		for part, cf in pairs(a) do
			local o = b[part]
			w = math.max(w, (cf.Position - o.Position).Magnitude, (cf.LookVector - o.LookVector).Magnitude,
				(cf.UpVector - o.UpVector).Magnitude)
		end
		return w
	end
	local wrongSets, drift, restOff, moved = {}, 0, 0, {}
	local plateRise = 0
	for _, id in ipairs({ "mossbristle", "briarstag", "hollowl", "elderbough", "gnarlmaw" }) do
		local sp = SeedData.Get(id)
		local tier = if (sp :: any).Secret then SeedData.SecretTier else 1
		local model = CreatureModel.Build(sp, tier, CreatureModel.STAGE_GROWN, CFrame.new(0, 0, 0), stage)
		local rest = snapshot(model)
		local rig = SecretIdle.Rig(model)
		if not (rig and PlantIdles.Idles[id]) then
			table.insert(wrongSets, id .. ": no rig or idle")
			continue
		end
		table.clear(rig.pose)
		PlantIdles.Idles[id](rig, 12.3)
		local got = {}
		for name in pairs(rig.pose) do
			got[name] = true
		end
		for _, name in ipairs(POSED[id]) do
			if not got[name] then
				table.insert(wrongSets, id .. " misses " .. name)
			end
			got[name] = nil
		end
		for name in pairs(got) do
			table.insert(wrongSets, id .. " also " .. name)
		end
		-- Absolute from the clock: the same moment is the same pose, whatever came between.
		SecretIdle.Step(rig, 3)
		local a = snapshot(model)
		for k = 1, 40 do
			SecretIdle.Step(rig, 3 + k * 0.37)
		end
		local mid = snapshot(model)
		SecretIdle.Step(rig, 3)
		drift = math.max(drift, worst(a, snapshot(model)))
		if worst(a, mid) > 1e-3 then
			table.insert(moved, id)
		end
		-- Mossbristle's puff: the bark plates up, 0.3 of its unit at the peak.
		if id == "mossbristle" then
			local at = 0.6 - rig.phase + 80
			SecretIdle.Step(rig, at)
			for _, node in ipairs(rig.nodes) do
				if node.motor == "BackA" then
					plateRise = node.part.Position.Y - rest[node.part].Position.Y
				end
			end
		end
		SecretIdle.Rest(rig)
		restOff = math.max(restOff, worst(rest, snapshot(model)))
		model:Destroy()
	end
	stage:Destroy()
	check(#wrongSets == 0, "each idle moves exactly the joints it is written for (no name skipped)",
		table.concat(wrongSets, "; "))
	check(drift < 1e-4 and #moved == 5 and restOff < 1e-4,
		"they all move, every pose absolute from the clock (no drift), and at rest they are the built model",
		string.format("drift %.1e, rest %.1e, moved %d", drift, restOff, #moved))
	check(plateRise > 0.1, "Mossbristle puffs: at the peak its bark plates stand up", plateRise)
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nMistCreaturesSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
