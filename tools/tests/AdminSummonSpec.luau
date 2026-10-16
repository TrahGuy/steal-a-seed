--!nocheck
--==============================================================================
-- Steal a Seed :: AdminSummonSpec (2026-10-16; KB/ADMIN-SECRET-SUMMON-PLAN.md)
--
-- SUMMON A SECRET, the admin console's: a biome's secret or RANDOM's, on THIS
-- SERVER or ALL SERVERS (ALL SERVERS only behind its YES), by the game's own
-- spawn and its own rules -- refused while a secret is out (named) or a POD
-- RUSH runs -- the secret's usual toast and "{admin} summoned a SECRET!" where
-- it spawned; ALL SERVERS summons here, then one message every other server
-- acts on once, under its own rules. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("AdminSummonSpec"))
--
-- The REAL NestService.SummonSecret on road nests this spec raises (its spec
-- seam), and the REAL AdminService.Handle and ReceiveSummon with the spawn, the
-- publish, the clock and the notices stood in for (its use* seams, a TellEveryone
-- stand-in), on a stand-in admin from the allowlist.
--
-- NOT here, seen in the guarded Play instead: the console on a real screen, the
-- round trip over its RemoteFunction, a real toast. Never here: a real publish
-- to the live game's servers (Studio never publishes).
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local Server = ServerScriptService.SeedGameServer
local GameConfig = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local BiomeData = require(Shared.BiomeData)
local AdminAnnounce = require(Shared.AdminAnnounce)
local ParentModel = require(Server.ParentModel)
local NestService = require(Server.NestService)
local AdminService = require(Server.AdminService)
local Model = require(Server.AdminService.ConsoleModel)

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
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

-- The owner's own account, on a stand-in table.
local ADMIN = { UserId = 4119740186, Name = "nicnicniccoal", DisplayName = "nicnicniccoal" }

local scratch = Instance.new("Folder")
scratch.Name = "ZZAdminSummonSpec"
scratch.Parent = Workspace

-- A road nest raised the way buildNest raises one (SecretToastSpec's fixture).
local raised = 0
local function raise(biome)
	raised += 1
	local at = Vector3.new(-38, 5200, 900 + raised * 120)
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

local realTell = AdminService.TellEveryone
local realInterval = AdminService.Config.MinInterval
local told = {}

local ok, err = pcall(function()
	NestService.SpecAnnouncer(function() end)
	--==========================================================================
	say("1. NestService.SummonSecret: the game's own spawn and its own rules")
	--==========================================================================
	local nests = {}
	for _, biome in ipairs(BiomeData.Biomes) do
		table.insert(nests, raise(biome))
	end
	local okT, whyT, biomeT, speciesT = NestService.SummonSecret("tanglemire", "spec", nests)
	check(okT and whyT == nil and biomeT == "tanglemire" and speciesT == "mirehydra" and nests[3].secret ~= nil,
		"a chosen biome's secret stands on its cradle at once", tostring(whyT))
	local okO, whyO, biomeO, speciesO = NestService.SummonSecret("emberroot", "spec", nests)
	check(not okO and whyO == "OUT" and biomeO == "tanglemire" and speciesO == "mirehydra",
		"while it is out, another is refused, and the one out is named", tostring(whyO))
	resolve(nests[3])
	NestService.SetRush(true)
	local okR, whyR = NestService.SummonSecret(nil, "spec", nests)
	check(not okR and whyR == "RUSH", "during a POD RUSH: refused", tostring(whyR))
	NestService.SetRush(false)
	local seen = {}
	for _ = 1, 30 do
		local okRand, _, biomeRand = NestService.SummonSecret(nil, "spec", nests)
		if okRand then
			seen[biomeRand] = true
		end
		for _, nest in ipairs(nests) do
			resolve(nest)
		end
	end
	local kinds = 0
	for _ in pairs(seen) do
		kinds += 1
	end
	check(kinds >= 3, string.format("RANDOM picks a biome as the roll does (%d of 5 seen in 30)", kinds), kinds)
	local okN, whyN, biomeN = NestService.SummonSecret("dustbowl", "spec", { nests[1] })
	check(not okN and whyN == "NO_NEST" and biomeN == "dustbowl", "a biome with no nest here: refused, named", tostring(whyN))
	for _, nest in ipairs(nests) do
		resolve(nest)
	end

	--==========================================================================
	say("2. AdminService: SUMMON, its words, its line, its scope")
	--==========================================================================
	AdminService.Config.MinInterval = 0
	AdminService.TellEveryone = function(title, key, quiet, sender)
		table.insert(told, { title = title, key = key, sender = sender })
	end
	local asked = {}
	local outcome = { true, nil, "tanglemire", "mirehydra" }
	AdminService.useSummon(function(biome, why)
		table.insert(asked, { biome = biome, why = why })
		return table.unpack(outcome, 1, 4)
	end)
	local published = {}
	local publishAnswer = { true, nil }
	AdminService.useSummonPublish(function(payload)
		table.insert(published, payload)
		return table.unpack(publishAnswer, 1, 2)
	end)
	local clockAt = 1000000
	AdminService.useSummonClock(function()
		return clockAt
	end)
	local stranger = { UserId = 90000000777, Name = "SpecStranger", DisplayName = "SpecStranger" }
	local nope = AdminService.Handle(stranger, "SummonSecret", "tanglemire", "server", false)
	check(nope and nope.ok == false and #asked == 0, "a player off the allowlist is refused before anything", nope and nope.message)
	local bad = AdminService.Handle(ADMIN, "SummonSecret", "moonbase", "server", false)
	check(bad.ok == false and has(bad.message, "Choose a biome") and #asked == 0, "an unknown biome is refused", bad.message)
	local badScope = AdminService.Handle(ADMIN, "SummonSecret", "tanglemire", "everywhere", false)
	check(badScope.ok == false and #asked == 0, "an unknown scope is refused", badScope.message)
	local unconfirmed = AdminService.Handle(ADMIN, "SummonSecret", "tanglemire", "all", false)
	check(unconfirmed.ok == false and has(unconfirmed.message, "YES") and #asked == 0 and #published == 0,
		"ALL SERVERS without its YES: refused, nothing summoned or sent", unconfirmed.message)
	local here = AdminService.Handle(ADMIN, "SummonSecret", "tanglemire", "server", false)
	local line = string.format(GameConfig.AdminAnnounce.Words.Secret, "nicnicniccoal")
	check(here.ok == true and here.message == "Summoned Mirehydra in Tanglemire." and #asked == 1
		and asked[1].biome == "tanglemire" and #published == 0,
		"THIS SERVER: summoned by the game's spawn, the reply names it, nothing sent", here.message)
	check(#told == 1 and told[1].title == line and told[1].sender and told[1].sender.name == "nicnicniccoal",
		"and everybody reads \"" .. line .. "\"", told[1] and told[1].title)
	local rnd = AdminService.Handle(ADMIN, "SummonSecret", "random", "server", false)
	check(rnd.ok and asked[2].biome == nil, "RANDOM leaves the biome to the roll's own pick", asked[2] and tostring(asked[2].biome))
	outcome = { false, "OUT", "emberroot", "cinderdrake" }
	local out1 = AdminService.Handle(ADMIN, "SummonSecret", "tanglemire", "server", false)
	check(out1.ok == false and out1.message == "A secret is already out (Cinderdrake in Emberroot). Nothing changed."
		and #told == 2, "a refusal says why, naming the secret out, and nobody is told anything", out1.message)
	outcome = { false, "RUSH", nil, nil }
	local rush = AdminService.Handle(ADMIN, "SummonSecret", "tanglemire", "server", false)
	check(rush.ok == false and has(rush.message, "POD RUSH") and #told == 2, "during a POD RUSH: said so", rush.message)
	outcome = { true, nil, "starbloom", "nebulisk" }
	local all = AdminService.Handle(ADMIN, "SummonSecret", "starbloom", "all", true)
	local sent = published[1]
	check(all.ok and all.message == "Sent to every server. Here: Summoned Nebulisk in Starbloom." and #published == 1
		and sent and type(sent.id) == "string" and sent.biome == "starbloom" and sent.name == "nicnicniccoal"
		and sent.at == clockAt, "ALL SERVERS: summoned here first, then ONE message with the biome and the admin", all.message)
	publishAnswer = { false, "STUDIO" }
	local studio = AdminService.Handle(ADMIN, "SummonSecret", "starbloom", "all", true)
	check(studio.message == "In Studio nothing goes to other servers. Here: Summoned Nebulisk in Starbloom.",
		"in Studio nothing is published, and the reply says so", studio.message)

	--==========================================================================
	say("3. Every other server: once, under its own rules")
	--==========================================================================
	local before, toldBefore = #asked, #told
	check(not AdminService.ReceiveSummon(sent) and #asked == before, "this server never acts on its own message again")
	local message = { id = "spec-other-1", biome = "dustbowl", name = "TappedYou", badge = nil, userId = 1139904972,
		at = clockAt - 5 }
	outcome = { true, nil, "dustbowl", "scourwheel" }
	check(AdminService.ReceiveSummon(message) and #asked == before + 1 and asked[#asked].biome == "dustbowl"
		and #told == toldBefore + 1 and told[#told].title == string.format(GameConfig.AdminAnnounce.Words.Secret, "TappedYou"),
		"another server's message: summoned here, the line names that admin")
	check(not AdminService.ReceiveSummon(message) and #asked == before + 1, "the same message twice: once only")
	local stale = { id = "spec-other-2", biome = "dustbowl", name = "TappedYou", at = clockAt - 120 }
	check(not AdminService.ReceiveSummon(stale) and #asked == before + 1, "a message older than a minute is dropped")
	local junk = { id = "spec-other-3", biome = "moonbase", name = "TappedYou", at = clockAt }
	check(not AdminService.ReceiveSummon(junk) and not AdminService.ReceiveSummon("nonsense")
		and not AdminService.ReceiveSummon({ id = 5, biome = "dustbowl", name = "x", at = clockAt }) and #asked == before + 1,
		"a malformed one, or an unknown biome, does nothing")
	outcome = { false, "OUT", "greenhollow", "grovemaw" }
	local refused = { id = "spec-other-4", biome = "random", name = "TappedYou", at = clockAt }
	check(not AdminService.ReceiveSummon(refused) and #told == toldBefore + 1, "refused there: silently")
	local audit = AdminService.Audit()
	local logged = 0
	for _, entry in ipairs(audit) do
		if type(entry.action) == "string" and string.find(entry.action, "SummonSecret", 1, true) then
			logged += 1
		end
	end
	check(logged >= 3, string.format("every summon is in the console's audit (%d)", logged), logged)

	--==========================================================================
	say("4. The console and the words")
	--==========================================================================
	local a = Model.args.summonSecret("tanglemire", "all", true)
	check(a.n == 4 and a[1] == "SummonSecret" and a[2] == "tanglemire" and a[3] == "all" and a[4] == true,
		"the console asks SummonSecret with the biome, the scope and the YES")
	local ui = Server.AdminService:FindFirstChild("AdminConsoleUI")
	local src = if ui then ui.Source else ""
	check(has(src, 'build.card(page, "Secret")') and has(src, '{ "SummonSecret", "SUMMON" }')
		and has(src, 'build.question(sCard, "SecretQuestion", "full", "YES, ALL SERVERS")')
		and has(src, 'task.spawn(send, Model.args.summonSecret(state.secretBiome, "server", false))')
		and has(src, 'task.spawn(send, Model.args.summonSecret(state.secretBiome, "all", true))'),
		"the Events page's SECRET card: a biome or RANDOM, THIS SERVER at once, ALL SERVERS behind its YES")
	local adminSrc = Server.AdminService.Source
	check(has(adminSrc, "if not RunService:IsStudio() then\n\t\ttask.spawn(function()")
		and has(adminSrc, '\tif RunService:IsStudio() then\n\t\treturn false, "STUDIO"'), "Studio never publishes or subscribes")
	check(GameConfig.AdminAnnounce.Words.Secret == "%s summoned a SECRET!"
		and AdminAnnounce.line("X", { kind = "secret" }) == "X summoned a SECRET!", "the owner's words")
end)

AdminService.TellEveryone = realTell
AdminService.Config.MinInterval = realInterval
AdminService.useSummon(nil)
AdminService.useSummonPublish(nil)
AdminService.useSummonClock(nil)
NestService.SetRush(false)
NestService.SpecAnnouncer(nil)
scratch:Destroy()
if not ok then
	say("  ERROR " .. tostring(err))
	fail += 1
end
return string.format("AdminSummonSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
