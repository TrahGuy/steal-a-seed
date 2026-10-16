--!nocheck
--==============================================================================
-- Steal a Seed :: BiomeSecretsSpec (2026-10-16; KB/BIOME-SECRETS-PLAN.md)
--
-- A secret in every biome, as the owner answered it: the five new secrets in
-- Snarlbloom's and Petalfawn's place (owned ones kept); ONE in the whole
-- server at a time; one roll a cycle for the whole server at
-- GameConfig.Secret.CycleChance, on a hit a random biome, never in a POD RUSH;
-- the rain biome's toast; Storm Strider's chase while the secret is carried;
-- the income ladder; a sixth Index card outside CLAIM; full size everywhere,
-- the Cinderdrake and the Mirehydra without their Aura spheres and on their
-- feet; the owner's scripts played over the replays; What's New.
--
-- Edit mode, no Play, no DataStore:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("BiomeSecretsSpec"))
--
-- The roll is NestService's own (SpecRollSecret) over road nests this spec
-- raises the way buildNest raises them, on a stand-in die that says exactly
-- what it rolls. The chase is the real provoke and chase speed on nest records
-- (SpecProvoke, SpecChaseSpeed), as FirstMinuteSpec drives them.
--
-- NOT here, seen in the guarded Play instead: the cradle, the toast and the
-- idles on a real screen; a real chase, steal, bank and hatch; the decor kept
-- off the new cradle spots in the rebuilt map.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local BiomeData = require(Shared.BiomeData)
local BiomeSecretForms = require(Shared.BiomeSecretForms)
local SecretModel = require(Shared.SecretModel)
local SecretIdle = require(Shared.SecretIdle)
local SecretPodMotion = require(Shared.SecretPodMotion)
local AlmanacView = require(Shared.AlmanacView)
local AlmanacData = require(Shared.AlmanacData)
local PodGuide = require(Shared.PodGuide)
local UpdateLog = require(Shared.UpdateLog)
local ParentModel = require(Server.ParentModel)
local NestService = require(Server.NestService)

local SECRET = GameConfig.Secret
local P = GameConfig.Parent

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
	return if found then found.Source else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

-- The owner's answers, as numbers.
local SECRETS = {
	greenhollow = { id = "grovemaw", income = 155000 },
	dustbowl = { id = "scourwheel", income = 165000 },
	tanglemire = { id = "mirehydra", income = 172000 },
	emberroot = { id = "cinderdrake", income = 180000 },
	starbloom = { id = "nebulisk", income = 189000 },
}

local scratch = Instance.new("Folder")
scratch.Name = "ZZBiomeSecretsSpec"
scratch.Parent = Workspace

local function biomeOf(id)
	return BiomeData.ById[id]
end

-- A road nest raised the way buildNest raises one (SecretToastSpec's fixture).
local HIGH = 4800
local raised = 0
local function raise(biome)
	raised += 1
	local at = Vector3.new(-38, HIGH, 900 + raised * 120)
	local folder = Instance.new("Folder")
	folder.Name = string.format("Nest_spec_%s_%02d", biome.Id, raised)
	folder.Parent = scratch
	local buildAt = CFrame.new(at) * CFrame.Angles(0, math.pi * 0.5, 0)
	local model = ParentModel.Build(buildAt, 15, biome.Id, folder)
	local slots = {}
	for i = 1, biome.PodsPerNest or 5 do
		local a = (i - 1) / (biome.PodsPerNest or 5) * math.pi * 2
		slots[i] = CFrame.new(at + Vector3.new(math.sin(a) * 16, 0, math.cos(a) * 16))
	end
	return {
		id = folder.Name, biome = biome, origin = at, homeCFrame = model.PrimaryPart.CFrame,
		parent = model, humanoid = model:FindFirstChildOfClass("Humanoid"), root = model.PrimaryPart,
		folder = folder, slots = slots, pods = {}, state = "asleep", target = nil, stateUntil = 0,
		busy = false, rage = 0, calmSince = 0, chaseSince = 0, haul = nil, sample = nil, thieves = {},
		secret = nil, marked = {}, buildAt = buildAt, rigId = biome.Id, lastSeen = model.PrimaryPart.Position,
		event = nil, route = nil, setDown = nil,
	}
end

-- A die that rolls what it is told and remembers what it was asked.
local function die(number, pick)
	local asked = {}
	return {
		asked = asked,
		NextNumber = function()
			table.insert(asked, "number")
			return number
		end,
		NextInteger = function(_, a, b)
			table.insert(asked, string.format("%d..%d", a, b))
			return math.clamp(pick, a, b)
		end,
	}
end

local function out_(nests)
	local list = {}
	for _, nest in ipairs(nests) do
		if nest.secret then
			table.insert(list, nest)
		end
	end
	return list
end

local function resolve(nest)
	local secret = nest.secret
	if secret then
		if secret.pod then
			secret.pod:Destroy()
		end
		if secret.platform then
			secret.platform:Destroy()
		end
		nest.secret = nil
	end
end

-- Every visible part's lowest point above the base it was built on.
local function lowest(model, base)
	local low = math.huge
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 0.999 then
			local half = p.Size / 2
			for _, sx in ipairs({ -1, 1 }) do
				for _, sy in ipairs({ -1, 1 }) do
					for _, sz in ipairs({ -1, 1 }) do
						local y = base:PointToObjectSpace((p.CFrame * CFrame.new(half.X * sx, half.Y * sy, half.Z * sz)).Position).Y
						low = math.min(low, y)
					end
				end
			end
		end
	end
	return low
end

local told = {}
local ok, err = pcall(function()
	NestService.SpecAnnouncer(function(id, biome, event)
		table.insert(told, { id = id, biome = biome, event = event })
	end)

	--==========================================================================
	say("1. A secret in every biome: the owner's five, their ladder, their chase")
	--==========================================================================
	check(SECRET.Enabled == true and SECRET.CycleChance == 0.05,
		"natural secrets are on again, at 5% a cycle for the whole server", SECRET.CycleChance)
	local everyBiome, ladder, routed, chase, still = true, true, true, true, true
	for _, biome in ipairs(BiomeData.Biomes) do
		local want = SECRETS[biome.Id]
		local id = SeedData.SecretByBiome[biome.Id]
		local sp = SeedData.Get(id or "")
		local cfg = (biome :: any).Secret
		everyBiome = everyBiome and want ~= nil and id == want.id and sp ~= nil and sp.Secret == true
			and sp.Rarity == "Secret" and sp.Biome == biome.Id
		ladder = ladder and sp ~= nil and sp.FixedIncome == want.income
		routed = routed and SecretModel.HasPlant(id) and SecretModel.HasPod(SeedData.PodFormOf(sp, SeedData.SecretTier))
			and BiomeSecretForms.Plants[id] ~= nil
		chase = chase and cfg ~= nil and cfg.Chase == "stormstrider" and cfg.SpotX == 42 and cfg.SpawnChance == nil
		still = still and sp ~= nil and sp.Still == true
	end
	check(everyBiome, "every biome's secret is its new one (Grovemaw, Scourwheel, Mirehydra, Cinderdrake, Nebulisk)")
	check(ladder, "the income ladder: $155K, $165K, $172K, $180K, $189K a second")
	check(routed, "each is built from the owner's model, and so is its pod")
	check(chase, "each biome's encounter names Storm Strider's chase, on the cradle 42 studs across the road")
	check(still, "planted, each stands still until its walk is built (step 2)")
	local snarl, fawn = SeedData.Get("snarlbloom"), SeedData.Get("petalfawn")
	local spawnsOld = false
	for _, id in pairs(SeedData.SecretByBiome) do
		spawnsOld = spawnsOld or id == "snarlbloom" or id == "petalfawn"
	end
	check(snarl ~= nil and fawn ~= nil and not spawnsOld, "Snarlbloom and Petalfawn spawn no more, and the ones owned are still known")
	local storm = GameConfig.guardianProfile("stormstrider")
	check(storm and storm.OpeningSpeed * storm.SpeedScale == 195 and storm.TopSpeed * storm.SpeedScale == 240,
		"Storm Strider's chase: 195 studs/s at the start, 240 at the top")

	--==========================================================================
	say("2. Full size, on their feet: the owner's ten models replayed")
	--==========================================================================
	local at = CFrame.new(0, HIGH + 300, 0)
	local indexed, counts = true, true
	for id, spec in pairs(BiomeSecretForms.Plants) do
		local model = Instance.new("Model")
		local base = Instance.new("Part")
		base.Name = "Base"
		base.Anchored = true
		base.Size = Vector3.new(6, 0.06, 6)
		base.CFrame = at
		base.Transparency = 1
		base.Parent = model
		model.PrimaryPart = base
		SecretModel.BuildPlant(id, at, model)
		model.Parent = scratch
		local parts, seen = 0, {}
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and p ~= base then
				parts += 1
				local i = p:GetAttribute(SecretModel.INDEX_ATTRIBUTE)
				indexed = indexed and type(i) == "number" and not seen[i]
				if type(i) == "number" then
					seen[i] = true
				end
			end
		end
		counts = counts and parts == spec.PartCount and #spec.Parts == spec.PartCount
		local low = lowest(model, at)
		check(math.abs(low) < 0.05, string.format("%s stands on its own feet (lowest point %.3f)", id, low), low)
		if id == "cinderdrake" or id == "mirehydra" then
			check(model:FindFirstChild("Aura") == nil and table.find(spec.Removed or {}, "Aura") ~= nil
				and SeedData.Get(id).Height == spec.Height,
				string.format("%s has no Aura sphere (the owner: \"if not necesarry we should remove it\"), height %.1f",
					id, spec.Height))
		end
		if id == "cinderdrake" then
			check(spec.Size.Y < 51 and spec.Size.X < 79 and spec.Size.Z < 80,
				"the Cinderdrake's box is his body and wings, 78 x 51 x 80, not the 90-stud sphere", spec.Size)
		end
		model:Destroy()
	end
	local atomic = true
	for id, spec in pairs(BiomeSecretForms.Pods) do
		local model = Instance.new("Model")
		local shell = SecretModel.BuildPod(id, at, model)
		model.PrimaryPart = shell
		atomic = atomic and model.ModelStreamingMode == Enum.ModelStreamingMode.Atomic
		local parts = 0
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and p ~= shell then
				parts += 1
				indexed = indexed and type(p:GetAttribute(SecretModel.INDEX_ATTRIBUTE)) == "number"
			end
		end
		counts = counts and parts == spec.PartCount
		model:Destroy()
	end
	check(counts, "every part of all ten is replayed")
	check(atomic, "each pod streams in and out whole, as its client animates it (seen in Play: a far cradle pod came without its Shell)")
	check(indexed, "every replayed part carries its index in the owner's model (FormIndex), once")

	--==========================================================================
	say("3. The roll: one secret in the whole server, 5% a cycle, a random biome")
	--==========================================================================
	local nests = {}
	for _, biome in ipairs(BiomeData.Biomes) do
		table.insert(nests, raise(biome))
	end
	local miss = die(SECRET.CycleChance, 1)
	NestService.SpecRollSecret(nests, "spec", miss)
	check(#out_(nests) == 0 and #told == 0 and #miss.asked == 1,
		"a roll of exactly 5% is a miss: nothing spawns, and it asks one number", table.concat(miss.asked, ","))
	local hit = die(SECRET.CycleChance - 1e-6, 3)
	NestService.SpecRollSecret(nests, "spec", hit)
	local spawned = out_(nests)
	check(#spawned == 1 and spawned[1] == nests[3] and hit.asked[2] == "1..5",
		"just under 5% is a hit: ONE secret, in the biome picked from all five", table.concat(hit.asked, ","))
	check(#told == 1 and told[1].biome == nests[3].biome.Id and told[1].event == nil
		and told[1].id == nests[3].secret.id,
		"and the rain biome's toast goes out once, naming its biome", #told)
	local pod = nests[3].secret and nests[3].secret.pod
	check(pod and pod:GetAttribute(SecretModel.FORM_ATTRIBUTE) == SECRETS[nests[3].biome.Id].id .. "pod",
		"its cradle holds its own pod", pod and pod:GetAttribute(SecretModel.FORM_ATTRIBUTE))
	local again = die(0, 1)
	NestService.SpecRollSecret(nests, "spec", again)
	check(#out_(nests) == 1 and #told == 1 and #again.asked == 0,
		"while it is out, no roll is even made: one at a time, server-wide", #out_(nests))
	resolve(nests[3])
	NestService.SetRush(true)
	local rush = die(0, 1)
	NestService.SpecRollSecret(nests, "spec", rush)
	check(#out_(nests) == 0 and #rush.asked == 0, "during a POD RUSH nothing spawns (the owner: \"they should not spawn during pod rush\")")
	NestService.SetRush(false)
	-- Every biome, each picked once (the die's pick is the candidate's place).
	local each = true
	for k = 1, #nests do
		NestService.SpecRollSecret(nests, "spec", die(0, k))
		local now = out_(nests)
		each = each and #now == 1 and now[1] == nests[k]
		resolve(nests[k])
	end
	check(each and #told == 1 + #nests, "every biome can be the one: each spawns its own pod on its cradle", #told)
	nests[1].event = 1
	local skip = die(0, 1)
	NestService.SpecRollSecret(nests, "spec", skip)
	check(skip.asked[2] == "1..4" and nests[1].secret == nil and #out_(nests) == 1,
		"the weather event's nest is never a candidate", table.concat(skip.asked, ","))
	for _, nest in ipairs(nests) do
		resolve(nest)
	end
	nests[1].event = nil
	local guide = PodGuide.secret("emberroot")
	check(guide and guide.speciesId == "cinderdrake" and math.abs(guide.chance - 0.01) < 1e-9,
		"the guide's odds: a fifth of the 5% roll for each biome, 1% a dawn", guide and guide.chance)

	--==========================================================================
	say("4. The chase: Storm Strider's, only while the secret is carried")
	--==========================================================================
	local fixture = Instance.new("Folder")
	fixture.Name = "BiomeSecretsSpecFixture"
	fixture.Parent = scratch
	local serial = 0
	local function record(biome)
		serial += 1
		local model = Instance.new("Model")
		model.Parent = fixture
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Anchored = true
		root.Position = Vector3.new(serial * 30, HIGH + 600, 0)
		root.Parent = model
		return {
			id = "Nest_biomesecrets_" .. serial, biome = biome, origin = root.Position,
			homeCFrame = CFrame.new(root.Position), parent = model, root = root, folder = fixture,
			slots = {}, pods = {}, humanoid = { WalkSpeed = 0, MoveTo = function() end },
			state = "returning", target = nil, stateUntil = 0, busy = false, rage = 0, calmSince = 0,
			chaseSince = 0, haul = nil, sample = nil, thieves = {},
		}
	end
	local thief = { Name = "SpecThief", UserId = 90000000301, Parent = Players }
	local want = (storm.OpeningSpeed + P.RageSpeedPerTake) * storm.SpeedScale
	NestService.SpecStealDone(function()
		return true
	end)
	local fast, plain = true, true
	for _, biome in ipairs(BiomeData.Biomes) do
		local carried = record(biome)
		carried.secret = { id = "spec-secret" }
		NestService.SpecProvoke(carried, thief, true, "spec-secret")
		local speed = NestService.SpecChaseSpeed(carried)
		fast = fast and math.abs(speed - want) < 1
		local ring = record(biome)
		NestService.SpecProvoke(ring, thief, true)
		local usual = NestService.SpecChaseSpeed(ring)
		plain = plain and usual < 150
		say(string.format("        %s: the secret's thief %.1f, a ring pod's %.1f", biome.Id, speed, usual))
	end
	NestService.SpecStealDone(nil)
	check(fast, string.format("in every biome the secret's thief meets Storm Strider's opening (%.1f with one rage)", want))
	check(plain, "and a ring pod's thief the biome's own guardian, as before")

	--==========================================================================
	say("5. The Index: a sixth card on each row, outside its CLAIM")
	--==========================================================================
	local shelves, claims = true, true
	for _, biome in ipairs(BiomeData.Biomes) do
		local shelf = AlmanacView.shelf(biome.Id)
		local listed = AlmanacData.SpeciesIn(biome.Id)
		shelves = shelves and #shelf == #listed + 1 and shelf[#shelf].Id == SECRETS[biome.Id].id
		local all = {}
		for _, sp in ipairs(shelf) do
			all[sp.Id] = true
		end
		local got, total = AlmanacData.Progress(all, biome.Id)
		claims = claims and total == #listed and got == #listed
	end
	check(shelves, "each row ends on its biome's secret")
	check(claims, "and its CLAIM counts the five without it")
	local words = GameConfig.PodGuide.Words
	check(words.SecretCardChance == "%s dawns" and words.SecretIncomeTitle == "Income"
		and has(words.SecretHatchesFrom, "SECRET pod"), "the card's words: its odds a dawn, one Income, its pod across the road")
	check(GameConfig.Almanac.Rarity.Secret ~= nil, "the Secret background")

	--==========================================================================
	say("6. Animated in the world, still in the Index")
	--==========================================================================
	local neb = Instance.new("Model")
	local nbase = Instance.new("Part")
	nbase.Anchored = true
	nbase.Size = Vector3.new(6, 0.06, 6)
	nbase.CFrame = at * CFrame.new(200, 0, 0)
	nbase.Parent = neb
	neb.PrimaryPart = nbase
	SecretModel.BuildPlant("nebulisk", nbase.CFrame, neb)
	neb.Parent = scratch
	local tongue = nil
	for _, d in ipairs(neb:GetDescendants()) do
		if d:IsA("Motor6D") and d.Name == "Tongue" then
			tongue = d
		end
	end
	local rig = SecretIdle.Rig(neb)
	-- 0.175 s into its 2.3 s cycle the tongue is all the way out. Its reach is
	-- the joint's own pose (Part1 = Part0 * C0 * pose * C1^-1), whatever the head
	-- above it is doing.
	SecretIdle.Step(rig, 0.175 - rig.phase)
	local reach = if tongue
		then ((tongue.Part0.CFrame * tongue.C0):Inverse() * tongue.Part1.CFrame * tongue.C1).Position.Magnitude
		else 0
	local unit = BiomeSecretForms.Plants.nebulisk.Unit * BiomeSecretForms.Plants.nebulisk.ModelScale
	check(#rig.glows == 44 and #(rig.named.Eye or {}) == 2 and math.abs(reach - 0.07 * unit) < 0.01,
		string.format("NebuliskIdle plays: 44 glows, 2 eyes, the tongue out %.2f studs (0.07 x its unit at today's size, %.2f)",
			reach, 0.07 * unit), reach)
	SecretIdle.Rest(rig)
	-- The two auras' pulses, staggered as their scripts staggered them.
	local function lagsOf(id)
		local m = Instance.new("Model")
		local b = Instance.new("Part")
		b.Anchored = true
		b.CFrame = at * CFrame.new(0, 0, -200)
		b.Parent = m
		m.PrimaryPart = b
		SecretModel.BuildPlant(id, b.CFrame, m)
		m.Parent = scratch
		local r = SecretIdle.Rig(m)
		local lags = {}
		for _, g in ipairs(r.glows) do
			table.insert(lags, g.lag)
		end
		m:Destroy()
		return lags
	end
	local mire = lagsOf("mirehydra")
	check(#mire == 3 and math.abs(mire[1] - 0.4) < 1e-9 and math.abs(mire[2] - 0.8) < 1e-9 and math.abs(mire[3] - 1.2) < 1e-9,
		"MirehydraAura's three pulses 0.4 s apart, in the owner's order", table.concat(mire, " "))
	local cinder = lagsOf("cinderdrake")
	local lo, hi = math.huge, -math.huge
	for _, lag in ipairs(cinder) do
		lo, hi = math.min(lo, lag), math.max(hi, lag)
	end
	check(#cinder == 13 and math.abs(lo) < 1e-9 and math.abs(hi - 1.4) < 1e-9,
		"CinderdrakeAura's thirteen, rippling over 1.4 s from the tail to the head", string.format("%d %.2f..%.2f", #cinder, lo, hi))
	local idleSrc = sourceOf(Shared, "SecretIdle")
	check(has(idleSrc, "\tnebulisk = nebulisk,") and has(idleSrc, "\tmirehydra = mirehydra,")
		and has(idleSrc, "\tcinderdrake = cinderdrake,") and has(idleSrc, "burst(rig, \"AuraBurst\", 36)")
		and has(idleSrc, "burst(rig, \"AuraBurst\", 40)"),
		"the three creature scripts are idles, flares and all")
	local maw = Instance.new("Model")
	local shell = SecretModel.BuildPod("nebuliskpod", at * CFrame.new(-200, 0, 0), maw)
	maw.PrimaryPart = shell
	maw.Parent = scratch
	local built = {}
	for _, p in ipairs(maw:GetChildren()) do
		if p:IsA("BasePart") then
			built[p] = p.CFrame
		end
	end
	local pr = SecretPodMotion.Rig(maw)
	SecretPodMotion.Step(pr, 0.5 - pr.phase)
	local moved = 0
	for p, cf in pairs(built) do
		if (p.Position - cf.Position).Magnitude > 0.05 then
			moved += 1
		end
	end
	SecretPodMotion.Rest(pr, true)
	local back = 0
	for p, cf in pairs(built) do
		back = math.max(back, (p.Position - cf.Position).Magnitude)
	end
	check(#pr.jaw == 30 and #pr.strands == 2 and moved >= 30 and back < 1e-3,
		"MawPulse plays on the cradle: the jaw gapes, the strands stretch, and rest is exactly as built",
		string.format("%d moved, back %.4f", moved, back))
	-- The lid in the hands: giveTool's shape, every part welded to the Handle.
	local holder = Instance.new("Model")
	local lidShell = SecretModel.BuildPod("grovemawpod", at * CFrame.new(0, 0, 200), holder)
	local tool = Instance.new("Tool")
	tool.Parent = scratch
	for _, d in ipairs(holder:GetDescendants()) do
		if d:IsA("BasePart") and d ~= lidShell then
			local w = Instance.new("WeldConstraint")
			w.Part0 = lidShell
			w.Part1 = d
			w.Parent = lidShell
			d.Parent = tool
		end
	end
	lidShell.Name = "Handle"
	lidShell.Parent = tool
	holder:Destroy()
	local lid = SecretPodMotion.Lid(tool)
	SecretPodMotion.SetLid(lid, 1)
	local on = 0
	for _, w in ipairs(lid.holds) do
		if w.Enabled then
			on += 1
		end
	end
	local _, angle = (lid.rest:Inverse() * lid.hinge.C0):ToAxisAngle()
	check(#lid.holds == 11 and on == 0 and math.abs(math.deg(angle) - 70) < 0.01,
		"Grovemaw's lid, held: its 11 parts let go of the Handle and swung 70 degrees on the hinge", #lid.holds)
	local clientSrc = sourceOf(Scripts, "SecretPodMotion")
	check(has(clientSrc, "HATCH_AT") and has(clientSrc, "GetServerTimeNow") and has(clientSrc, "IsDescendantOf(Workspace)"),
		"and it opens once the pod's HatchAt has come, in the world only")
	local plantSrc = sourceOf(Server, "PlantService")
	check(has(plantSrc, "not (entry.species and entry.species.Still == true)"), "a Still secret is never sent wandering")

	--==========================================================================
	say("7. What's New")
	--==========================================================================
	local entry = UpdateLog.Entries[1]
	check(entry.id == "2026-10-16-biome-secrets" and #UpdateLog.problems() == 0,
		"the newest entry is the secrets', and the list keeps every rule", table.concat(UpdateLog.problems(), "; "))
end)

NestService.SpecAnnouncer(nil)
NestService.SpecStealDone(nil)
NestService.SetRush(false)
scratch:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("BiomeSecretsSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
