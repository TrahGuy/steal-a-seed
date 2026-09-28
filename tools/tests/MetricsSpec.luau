--!nocheck
--==============================================================================
-- Steal a Seed :: MetricsSpec
--
-- Launch analytics (2026-09-27), against a MOCK sink: nothing here reaches
-- Roblox, and nothing here can -- Studio never sends. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("MetricsSpec"))
--
-- Proves, with the real Metrics module and stand-in players:
--   1. onboarding: only new saves in the cohort, in order, once, and never for
--      a returning, old or temporary profile
--   2. raids: one start, one ending, the right outcome, banked-only step 2
--   3. the chest: confirmed grants only
--   4. who is counted: staff out (or validation only), the master switch
--   5. failures and floods: a throwing sink changes nothing; the budget holds
--   6. the obby: silent while switched off, correct once on
--   7. every hook sits AFTER its success point in the real source
--   8. names and fields stay inside Roblox's limits and carry nothing personal
--   9. Studio is a dry run
--
-- NOT HERE: actual delivery. That needs a published server and Creator Hub's
-- View Events (KB/ANALYTICS.md, "Checking delivery").
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Metrics = require(Server:WaitForChild("Metrics"))

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

--==============================================================================
-- THE MOCK SINK, A CLOCK, AND STAND-IN PLAYERS
--==============================================================================
local sent = {}
local throwing = false
local mock = {
	onboarding = function(player, step, name, fields)
		if throwing then
			error("analytics down")
		end
		table.insert(sent, { kind = "onboarding", player = player, step = step, name = name, fields = fields })
	end,
	funnel = function(player, funnel, session, step, name, fields)
		if throwing then
			error("analytics down")
		end
		table.insert(sent, { kind = "funnel", player = player, funnel = funnel, session = session, step = step,
			name = name, fields = fields })
	end,
	custom = function(player, name, value, fields)
		if throwing then
			error("analytics down")
		end
		table.insert(sent, { kind = "custom", player = player, name = name, value = value, fields = fields })
	end,
}
local now = 1000
local staff = {}

local function fresh(config)
	table.clear(sent)
	throwing = false
	Metrics.reset()
	Metrics.useSink(mock)
	Metrics.useClock(function()
		return now
	end)
	Metrics.useStaffCheck(function(p)
		return staff[p] == true
	end)
	local base = { Enabled = true, ExcludeStaff = true, StaffValidation = false, PerMinute = 1000,
		CohortSince = 5000, Obby = false }
	for k, v in pairs(config or {}) do
		base[k] = v
	end
	Metrics.configure(base)
end

local function count(pred)
	local n = 0
	for _, e in ipairs(sent) do
		if pred(e) then
			n += 1
		end
	end
	return n
end

local function onboardingSteps(player)
	local steps = {}
	for _, e in ipairs(sent) do
		if e.kind == "onboarding" and e.player == player then
			table.insert(steps, e.step)
		end
	end
	return table.concat(steps, ",")
end

local function newPlayer(name)
	return { Name = name }
end

local function progress(done)
	local copy = {}
	for k, v in pairs(done or {}) do
		copy[k] = v
	end
	return { Done = copy, Skipped = false }
end

local ok, err = pcall(function()

--==============================================================================
-- 1. ONBOARDING
--==============================================================================
say("-- onboarding --")
fresh()
local p1 = newPlayer("new")
Metrics.profileReady(p1, { CreatedAt = 6000 }, true, true)
check(onboardingSteps(p1) == "1", "a brand-new save in the cohort opens the funnel at step 1", onboardingSteps(p1))

local returning = newPlayer("returning")
Metrics.profileReady(returning, { CreatedAt = 6000 }, false, true)
check(onboardingSteps(returning) == "", "a returning cohort profile does NOT restart it")
local veteran = newPlayer("veteran")
Metrics.profileReady(veteran, { CreatedAt = 100 }, false, true)
Metrics.milestone(veteran, "steal", progress({ steal = true }))
check(count(function(e) return e.player == veteran end) == 0,
	"a save older than the launch is never in the cohort, whatever it does next")
local temp = newPlayer("temporary")
Metrics.profileReady(temp, { CreatedAt = 6000 }, true, false)
check(count(function(e) return e.player == temp end) == 0, "a temporary (unsaveable) profile never counts")

-- Out of order: planting a pod (from somewhere else) before any bank must not
-- credit "stolen" or "banked".
local done = { train = true, speed = true, place = true }
Metrics.milestone(p1, "place", progress(done))
check(onboardingSteps(p1) == "1", "planting before any bank logs nothing -- a funnel would credit steps 2 and 3")
check(count(function(e) return e.name == "TutorialStepDone" and e.fields and e.fields.CustomField01 == "place" end) == 1,
	"(it is still counted as the guide step it is, on its own)")
done.steal = true
Metrics.milestone(p1, "steal", progress(done))
check(onboardingSteps(p1) == "1,2", "the steal is step 2 -- and the walk stops at the missing bank", onboardingSteps(p1))
done.bank = true
Metrics.milestone(p1, "bank", progress(done))
check(onboardingSteps(p1) == "1,2,3,4",
	"the bank is step 3, and the earlier plant is reported only now, as step 4, in order", onboardingSteps(p1))
Metrics.milestone(p1, "steal", progress(done))
Metrics.milestone(p1, "bank", progress(done))
check(onboardingSteps(p1) == "1,2,3,4", "a repeated callback adds nothing")
Metrics.income(p1)
check(onboardingSteps(p1) == "1,2,3,4", "income before the first hatch is not the funnel's last step")
done.hatch = true
Metrics.milestone(p1, "hatch", progress(done))
Metrics.income(p1)
Metrics.income(p1)
check(onboardingSteps(p1) == "1,2,3,4,5,6", "hatch then the first income: steps 5 and 6, once each",
	onboardingSteps(p1))
check(count(function(e) return e.name == "TutorialCompleted" and e.player == p1 end) == 1,
	"the guide's completion is its own event, once, when the last step is done")
check(count(function(e) return e.name == "TutorialStepDone" and e.player == p1 end) == 4,
	"each guide step is counted once (place, steal, bank, hatch)")

-- A new player who left mid-guide comes back (a new session, the same save).
fresh()
local back = newPlayer("rejoined")
Metrics.profileReady(back, { CreatedAt = 6000 }, false, true)
Metrics.milestone(back, "place", progress({ train = true, speed = true, steal = true, bank = true, place = true }))
check(onboardingSteps(back) == "2,3,4",
	"after a rejoin the chain picks up where the save is (Roblox keeps only each step's first instance)",
	onboardingSteps(back))
check(not string.find(onboardingSteps(back), "1", 1, true), "and step 1 is never sent again on a rejoin")

fresh()
local skipper = newPlayer("skipper")
Metrics.profileReady(skipper, { CreatedAt = 6000 }, true, true)
Metrics.tutorialSkipped(skipper, true)
Metrics.tutorialSkipped(skipper, true)
Metrics.tutorialSkipped(skipper, false)
check(count(function(e) return e.name == "TutorialSkipped" end) == 1, "skipping is counted once a session, resuming never")

--==============================================================================
-- 2. RAIDS
--==============================================================================
say("\n-- raids --")
fresh()
local r = newPlayer("raider")
Metrics.profileReady(r, { CreatedAt = 100 }, false, true)
now = 2000
Metrics.raidStarted(r, "dustbowl", 150e6)
local start = sent[#sent]
check(start and start.kind == "funnel" and start.funnel == "GuardianRaid" and start.step == 1
		and start.fields.CustomField01 == "dustbowl" and start.fields.CustomField02 == "near",
	"a nest theft is step 1 with its biome and speed band (150M against 167M: near)")
check(start and type(start.session) == "string" and #start.session >= 32 and not string.find(start.session, "raider"),
	"its session is a GUID, nothing about the player")
now = 2012.34
Metrics.raidEnded(r, "banked")
Metrics.raidEnded(r, "banked")
Metrics.raidEnded(r, "knocked")
check(count(function(e) return e.kind == "funnel" and e.step == 2 end) == 1, "a bank is step 2, once")
local ended = nil
for _, e in ipairs(sent) do
	if e.name == "GuardianRaidEnded" then
		ended = e
	end
end
check(count(function(e) return e.name == "GuardianRaidEnded" end) == 1 and ended ~= nil and ended.value == 12.3
		and ended.fields.CustomField03 == "banked",
	"one ending per raid, with its duration (12.3 s) and outcome", ended and ended.value)

fresh()
local c = newPlayer("caught")
Metrics.raidStarted(c, "starbloom", 1)
Metrics.guardianCaught(c)
Metrics.raidEnded(c, "knocked")
Metrics.raidEnded(c, "captured")
check(count(function(e) return e.name == "GuardianRaidEnded" and e.fields.CustomField03 == "captured" end) == 1
		and count(function(e) return e.kind == "funnel" and e.step == 2 end) == 0,
	"a guardian's catch is one 'captured' -- the throw's drop after it adds nothing, and nothing is banked")
check(count(function(e) return e.name == "GuardianRaidEnded" end) == 1, "no second ending")

fresh()
local nobody = newPlayer("no raid")
Metrics.raidEnded(nobody, "banked")
Metrics.guardianCaught(nobody)
check(#sent == 0, "a carry that was not a raid (a dropped pod picked back up) ends nothing")

fresh()
local l = newPlayer("leaver")
Metrics.raidStarted(l, "tanglemire", 900e6)
Metrics.playerLeft(l)
check(count(function(e) return e.name == "GuardianRaidEnded" and e.fields.CustomField03 == "left" end) == 1,
	"leaving mid-raid ends it as 'left', and only then")
Metrics.raidStarted(l, "nowhere", 0)
check(sent[#sent].fields.CustomField01 == "other", "an unknown biome is 'other', never free text")
Metrics.raidStarted(l, "dustbowl", 0)
check(count(function(e) return e.name == "GuardianRaidEnded" end) == 2,
	"a second theft while one is open closes the first once, never counting it twice")

check(Metrics.speedBand(0, 0) == "none" and Metrics.speedBand(79, 100) == "below"
		and Metrics.speedBand(80, 100) == "near" and Metrics.speedBand(124, 100) == "near"
		and Metrics.speedBand(125, 100) == "above",
	"bands: under 80% below, 80% to under 125% near, 125% up above, no recommendation none")

--==============================================================================
-- 3. THE CHEST
--==============================================================================
say("\n-- the chest --")
fresh()
local ch = newPlayer("chest")
Metrics.chestClaimed(ch, "income")
Metrics.chestClaimed(ch, "training")
Metrics.chestClaimed(ch, "free robux")
check(count(function(e) return e.name == "BonusChestClaimed" end) == 2, "two confirmed grants, two events")
check(count(function(e) return e.name == "BonusChestClaimed" and e.fields.CustomField01 == "free robux" end) == 0,
	"a reward the chest does not have is never recorded")

--==============================================================================
-- 4. WHO IS COUNTED
--==============================================================================
say("\n-- who is counted --")
fresh()
local admin = newPlayer("admin")
staff[admin] = true
Metrics.profileReady(admin, { CreatedAt = 6000 }, true, true)
Metrics.raidStarted(admin, "greenhollow", 0)
Metrics.chestClaimed(admin, "income")
check(#sent == 0, "staff play is left out of every report")
fresh({ StaffValidation = true })
Metrics.profileReady(admin, { CreatedAt = 6000 }, true, true)
Metrics.raidStarted(admin, "greenhollow", 0)
Metrics.raidEnded(admin, "banked")
check(#sent > 0 and count(function(e) return e.name ~= "MetricsValidation" end) == 0,
	"with validation on, staff send ONLY MetricsValidation -- never a real count", #sent)
fresh({ Enabled = false })
local off = newPlayer("switched off")
Metrics.profileReady(off, { CreatedAt = 6000 }, true, true)
Metrics.raidStarted(off, "dustbowl", 0)
Metrics.chestClaimed(off, "income")
check(#sent == 0, "the master switch off sends nothing at all")

--==============================================================================
-- 5. FAILURES AND FLOODS
--==============================================================================
say("\n-- failures and floods --")
fresh()
throwing = true
local f = newPlayer("failing")
local calm = pcall(function()
	Metrics.profileReady(f, { CreatedAt = 6000 }, true, true)
	Metrics.raidStarted(f, "dustbowl", 1)
	Metrics.raidEnded(f, "banked")
	Metrics.chestClaimed(f, "income")
	Metrics.milestone(f, "steal", progress({ steal = true }))
end)
local _, failures = Metrics.health()
check(calm and failures >= 4, "an analytics outage throws into nobody's gameplay; the failures are only counted",
	failures)
fresh({ PerMinute = 5 })
local flood = newPlayer("flood")
for _ = 1, 12 do
	Metrics.chestClaimed(flood, "income")
end
local droppedCount = Metrics.health()
check(#sent == 5 and droppedCount == 7, "the per-server budget holds: 5 of 12 go out, 7 are dropped, none queue",
	#sent .. " / " .. droppedCount)
now += 60
Metrics.chestClaimed(flood, "income")
check(#sent == 6, "and it refills with time")

--==============================================================================
-- 6. THE OBBY
--==============================================================================
say("\n-- the obby --")
fresh()
local o = newPlayer("runner")
Metrics.obbyStarted(o)
Metrics.obbyCheckpoint(o, "main1")
Metrics.obbyEnded(o, "completed")
check(#sent == 0, "switched off, the obby reports nothing -- no run nobody could start")
fresh({ Obby = true })
Metrics.obbyStarted(o)
Metrics.obbyCheckpoint(o, "main2")
Metrics.obbyCheckpoint(o, "main1")
Metrics.obbyCheckpoint(o, "main1")
Metrics.obbyCheckpoint(o, "main2")
Metrics.obbyFell(o)
Metrics.obbyFell(o)
Metrics.obbyFell(o)
now += 75
Metrics.obbyEnded(o, "completed")
Metrics.obbyEnded(o, "completed")
local steps = {}
for _, e in ipairs(sent) do
	if e.kind == "funnel" then
		table.insert(steps, e.step)
	end
end
check(table.concat(steps, ",") == "1,2,3,4",
	"on: start, the checkpoints in course order (an early second one is ignored), the finish", table.concat(steps, ","))
local oe = nil
for _, e in ipairs(sent) do
	if e.name == "ObbyRunEnded" then
		oe = e
	end
end
check(count(function(e) return e.name == "ObbyRunEnded" end) == 1 and oe ~= nil and oe.fields.CustomField01 == "completed"
		and oe.fields.CustomField03 == "3-5" and oe.value == 75,
	"one ending per run -- a second 'completed' is ignored -- with its time and a falls bucket")
fresh({ Obby = true })
Metrics.obbyStarted(o)
Metrics.obbyEnded(o, "exited")
Metrics.obbyStarted(o)
Metrics.playerLeft(o)
check(count(function(e) return e.name == "ObbyRunEnded" and e.fields.CustomField01 == "exited" end) == 1
		and count(function(e) return e.name == "ObbyRunEnded" and e.fields.CustomField01 == "left" end) == 1,
	"a voluntary exit and a disconnect are told apart")

--==============================================================================
-- 7. THE HOOKS SIT AFTER THEIR SUCCESS POINTS (the real source)
--==============================================================================
say("\n-- hooks --")
local function src(name)
	local inst = Server:FindFirstChild(name)
	local okSrc, text = pcall(function()
		return inst.Source
	end)
	return if okSrc then text else ""
end
local function after(text, first, second, within)
	local a = string.find(text, first, 1, true)
	local b = a and string.find(text, second, a, true)
	return a ~= nil and b ~= nil and (within == nil or b - a < within)
end
local pds = src("PlayerDataService")
check(after(pds, "if not TutorialData.Record(entry.profile.Tutorial, milestone) then return false end",
	"Metrics.milestone(player, milestone, entry.profile.Tutorial)", 250),
	"a milestone is reported only after Record says it is the first time")
check(after(pds, "if not TutorialData.SetSkipped(entry.profile.Tutorial, skipped) then return false end",
	"Metrics.tutorialSkipped(player, skipped)", 120), "a skip only after it was recorded")
check(after(pds, "entries[player] = {", "Metrics.profileReady(player, profile, status == \"new\", persistent)", 600),
	"the funnel opens only on a loaded profile, and only a brand-new one")
local econ = src("EconomyService")
check(after(econ, "if PlayerDataService.AddCash(player, amount) then", "Metrics.income(player)", 400),
	"income is reported only when the cash actually landed")
local carry = src("CarryService")
check(after(carry, "PlayerDataService.RecordTutorial(player, \"steal\")", "if nestTheft then", 80)
		and after(carry, "if nestTheft then", "Metrics.raidStarted(player, taken.Biome", 200),
	"a raid starts only after a successful take, and only for a nest pod")
check(after(carry, "PlayerDataService.RecordTutorial(player, \"bank\")", "Metrics.raidEnded(player, \"banked\")", 80),
	"banked only after the bank succeeded -- never on 'no longer chased'")
check(after(carry, "if CarryService.Drop(player,", "Metrics.raidEnded(player, \"knocked\")", 400)
		and after(carry, "humanoid.Died:Connect", "Metrics.raidEnded(player, \"died\")", 400),
	"knocked and died only when a drop actually happened")
check(after(carry, "function CarryService.Confiscate", "Metrics.raidEnded(player, \"captured\")", 500),
	"captured when a guardian confiscates")
local nest = src("NestService")
check(after(nest, "-- They got out of reach during the wind-up. The swing misses.", "Metrics.guardianCaught(player)", 1200),
	"a catch is reported after the miss check, when the swing lands")
local chest = src("BonusChestService")
check(after(chest, "if not (called and saved == true) then", "Metrics.chestClaimed(player, reward)", 900)
		and after(chest, "return false, \"SAVE_FAILED\", nil", "Metrics.chestClaimed(player, reward)"),
	"a chest reward is reported only after its save succeeded")
local metrics = src("Metrics")
local deprecated = {}
for _, word in ipairs({ "FireEvent", "FireCustomEvent", "FireInGameEconomyEvent", "FirePlayerProgressionEvent",
	"FireLogEvent", "ReportEvent" }) do
	if string.find(metrics, word .. "(", 1, true) then
		table.insert(deprecated, word)
	end
end
check(#deprecated == 0 and string.find(metrics, "LogOnboardingFunnelStepEvent", 1, true) ~= nil
		and string.find(metrics, "LogFunnelStepEvent", 1, true) ~= nil
		and string.find(metrics, "LogCustomEvent", 1, true) ~= nil,
	"only the current AnalyticsService methods, none of the deprecated ones", table.concat(deprecated, ", "))
check(not string.find(metrics, "task.wait", 1, true) and not string.find(metrics, ":Wait(", 1, true)
		and not string.find(metrics, "Async(", 1, true),
	"nothing in the layer yields: no gameplay path waits on analytics")

--==============================================================================
-- 8. INSIDE ROBLOX'S LIMITS, AND NOTHING PERSONAL
--==============================================================================
say("\n-- limits --")
local nameCount = 0
for _ in pairs(Metrics.Events) do
	nameCount += 1
end
check(nameCount <= 20, "a handful of custom event names (Roblox allows 100)", nameCount)
local outcomes = 0
for _ in pairs(Metrics.Outcomes) do
	outcomes += 1
end
local combos = 6 * 4 * outcomes
check(combos < 8000, "raid field combinations stay far under Roblox's 8,000 (biomes+other x bands x outcomes)", combos)
check(#Metrics.Onboarding == 6 and Metrics.Onboarding[1].step == 1 and Metrics.Onboarding[6].step == 6,
	"the onboarding funnel is six steps, 1 to 6")
check(GameConfig.Metrics ~= nil and GameConfig.Metrics.Obby == true and GameConfig.Obby ~= nil
		and type(GameConfig.Obby.Enabled) == "boolean",
	"the obby's events are on now that the course exists, behind its own switch")
check(GameConfig.Metrics.CohortSince >= 1790467200 and GameConfig.Metrics.ExcludeStaff == true
		and GameConfig.Metrics.StaffValidation == false,
	"launch settings: cohort from 2026-09-27, staff excluded, validation off")

--==============================================================================
-- 9. STUDIO IS A DRY RUN
--==============================================================================
say("\n-- the dry run --")
Metrics.reset()
Metrics.useSink(nil)
Metrics.configure({ Enabled = true, ExcludeStaff = true, StaffValidation = false, PerMinute = 1000,
	CohortSince = 5000, Obby = false })
Metrics.useStaffCheck(function()
	return false
end)
local stand = Instance.new("Folder")
Metrics.chestClaimed(stand, "income")
local recent = Metrics.recent()
check(game:GetService("RunService"):IsStudio() and #recent == 1 and recent[1].name == "BonusChestClaimed",
	"in Studio an event lands in the dry run's memory and nowhere else", #recent)
stand:Destroy()

end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
Metrics.useSink(nil)
Metrics.configure(nil)
Metrics.useStaffCheck(nil)
Metrics.useClock(nil)
Metrics.reset()

say(string.format("\nMetricsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
