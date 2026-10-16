--!nocheck
--==============================================================================
-- Steal a Seed :: PodRushHourlySpec (2026-10-16; KB/POD-RUSH-HOURLY-PLAN.md)
--
-- The owner's answers: a POD RUSH every hour at :30, for 5 minutes, on every
-- server at once from the clock; a 1-minute warning; an admin's event running
-- at :30 takes that hour; the Mist left alone; players still in their first
-- loop spared the warning, the start pop-up, an empty end card and other
-- people's GOLD; the levels, rewards and words the rush's own; PodRushEnded
-- tagged scheduled or admin; one What's New entry.
--
-- Edit mode, no Play, no DataStore, no MessagingService:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PodRushHourlySpec"))
--
-- Each "server" is a fresh clone of the real MiniEventService (and the
-- WheelService it requires) in a folder of its own, as MiniEventSpec builds
-- them, on one spec clock and one stand-in store, stepped as the live loop
-- steps it (HourlyStep, then Step). PodRushService's rules run through its Hooks
-- with stand-ins, as PodRushSpec drives them.
--
-- NOT here: real servers' clocks, a live publish, and what a screen draws.
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local PodRush = require(Shared.PodRush)
local Notice = require(Shared.Notice)
local SeedData = require(Shared.SeedData)
local UpdateLog = require(Shared.UpdateLog)
local Server = game:GetService("ServerScriptService").SeedGameServer
local Scripts = game:GetService("StarterPlayer").StarterPlayerScripts
local ProfileSchema = require(Server.ProfileSchema)

local M = GameConfig.MiniEvent
local ATTR = M.Attributes
local RUSH = GameConfig.PodRush
local AUTO = RUSH.Auto
local QUIET = GameConfig.FirstHatch.QuietAttribute
local ADMIN = { UserId = 4119740186, Name = "nicnicniccoal", DisplayName = "nicnicniccoal" }

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
local function sourceOf(parent, name)
	local node = parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return node.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end
local function bodyOf(src, header)
	local i = string.find(src, header, 1, true)
	if not i then
		return ""
	end
	local j = string.find(src, "\nend\n", i, true)
	return string.sub(src, i, j or #src)
end
local function json(v)
	if v == nil then
		return nil
	end
	return HttpService:JSONDecode(HttpService:JSONEncode(v))
end

-- A run that threw before its end leaves its folder: swept first.
for _, stale in ipairs(ServerStorage:GetChildren()) do
	if stale.Name == "ZZPodRushHourlySpec" then
		stale:Destroy()
	end
end
local fixture = Instance.new("Folder")
fixture.Name = "ZZPodRushHourlySpec"
fixture.Archivable = false
fixture.Parent = ServerStorage

--==============================================================================
-- THE STAND-INS
--==============================================================================
local now = 0
local function clock()
	return now
end

local store = { value = nil, writes = 0 }
local NS = "place_hourly_spec"
local function storeSeam()
	return {
		scope = "global",
		note = "spec store",
		ns = NS,
		update = function(transform)
			local nextValue = transform(json(store.value))
			if nextValue ~= nil then
				store.value = json(nextValue)
				store.writes += 1
			end
			return true, nil
		end,
		read = function()
			return true, json(store.value)
		end,
		publish = function()
			return true, nil
		end,
		subscribe = function()
			return true, nil
		end,
	}
end

local function stub(parent, name, source)
	local m = Instance.new("ModuleScript")
	m.Name = name
	m.Source = source
	m.Parent = parent
	return m
end

local PDS_STUB = [[
local P = { profiles = {}, persistent = {}, saves = 0, failSave = false }
function P.Get(p) return P.profiles[p] end
function P.IsReady(p) return P.profiles[p] ~= nil end
function P.IsPersistent(p) return P.profiles[p] ~= nil and P.persistent[p] ~= false end
function P.UpdateWheel(p, change)
	local prof = P.profiles[p]
	if not prof then return false end
	return change(prof) == true
end
function P.Save(p) P.saves += 1 return not P.failSave end
function P.PublishLikeReminder() end
return P
]]
local NOOP_STUB = "return setmetatable({}, { __index = function() return function() return nil end end })"

local function newServer(label)
	local folder = Instance.new("Folder")
	folder.Name = label
	folder.Parent = fixture
	stub(folder, "PlayerDataService", PDS_STUB)
	for _, name in ipairs({ "EconomyService", "TreadmillService", "CarryService", "BonusChestService", "Metrics",
		"WheelModel", "PlantService" }) do
		stub(folder, name, NOOP_STUB)
	end
	local wheelModule = Server.WheelService:Clone()
	wheelModule.Parent = folder
	local miniModule = Server.MiniEventService:Clone()
	miniModule.Parent = folder
	local attrs = Instance.new("Folder")
	attrs.Name = "Attrs"
	attrs.Parent = folder
	local S = {
		label = label,
		data = require(folder.PlayerDataService),
		wheel = require(wheelModule),
		mini = require(miniModule),
		attrs = attrs,
		players = {},
		sent = {},
	}
	local mini = S.mini
	mini.useShared(storeSeam())
	mini.useClock(clock)
	mini.usePlayers(function()
		return S.players
	end)
	mini.useRoot(function()
		return nil
	end)
	mini.useBroadcast(function(action, payload, to)
		table.insert(S.sent, { action = action, payload = payload, to = to })
	end)
	mini.useGrant(function(p, id, cap, src)
		return S.wheel.GrantEventSpin(p, id, cap, src)
	end)
	mini.useCount(function(p, id)
		return S.wheel.EventClaimCount(p, id)
	end)
	mini.useSpot(function()
		return nil
	end)
	mini.useWorld(attrs, attrs)
	return S
end

local function person(id, name, quiet)
	local attrs = {}
	if quiet then
		attrs[QUIET] = true
	end
	local p = { UserId = id, Name = name, DisplayName = name, Parent = Players, Character = nil, attrs = attrs }
	function p:GetAttribute(k)
		return attrs[k]
	end
	function p:SetAttribute(k, v)
		attrs[k] = v
	end
	function p:FindFirstChildOfClass()
		return nil
	end
	return p
end

local function join(S, p)
	table.insert(S.players, p)
	S.data.profiles[p] = ProfileSchema.Default()
end

-- Walks the clock to `to`, each server stepped as its live loop steps it.
local function step(list, to, dt)
	dt = dt or 0.25
	while now < to - 1e-9 do
		now = math.min(to, now + dt)
		for _, S in ipairs(list) do
			S.mini.HourlyStep(now)
			S.mini.Step(now)
		end
	end
end

local function sentOf(S, action)
	local list = {}
	for _, m in ipairs(S.sent) do
		if m.action == action then
			table.insert(list, m)
		end
	end
	return list
end

local function noticesWith(S, prefix)
	local list = {}
	for _, m in ipairs(sentOf(S, Notice.ServerNotice)) do
		if type(m.payload) == "table" and type(m.payload.key) == "string"
			and string.sub(m.payload.key, 1, #prefix) == prefix then
			table.insert(list, m)
		end
	end
	return list
end

-- The next :30 after a fixed moment: every section's slot counts on from it.
local S0 = PodRush.slotAt(1792000000) + AUTO.PeriodSeconds

local ok, err = pcall(function()
	--==========================================================================
	say("1. The owner's numbers")
	--==========================================================================
	check(AUTO.Enabled == true and AUTO.PeriodSeconds == 3600 and AUTO.OffsetSeconds == 1800 and AUTO.WarnSeconds == 60
			and M.Modes[RUSH.Mode].Seconds == 300 and AUTO.Warn.Title == "POD RUSH IN 1 MINUTE!",
		"every hour, at :30, for 5 minutes, warned a minute before")
	local L = RUSH.Levels
	check(#L == 3 and L[1].Pods == 3 and L[2].Pods == 7 and L[3].Pods == 12 and L[1].Spins == 1 and L[2].Spins == 3
			and L[2].Boost == "training" and L[3].Spins == 5 and L[3].PodTier == 6,
		"the levels and rewards are the rush's own: 3 / 7 / 12 pods; 1 spin; 3 and the training boost; 5 and a Titan pod")

	--==========================================================================
	say("2. The slots")
	--==========================================================================
	local t = os.date("!*t", S0)
	check((S0 - 1800) % 3600 == 0 and t.min == 30 and t.sec == 0 and PodRush.slotAt(S0) == S0
			and PodRush.slotAt(S0 + 3599.5) == S0 and PodRush.slotAt(S0 - 0.5) == S0 - 3600,
		"a slot is a whole hour plus :30 UTC: the same number on every server's clock", S0)
	local id = PodRush.autoId(S0)
	check(id == "auto" .. string.format("%d", S0) and PodRush.isAuto(id) and string.match(id, "^[%w]+$") ~= nil
			and #id >= 8 and #id <= 40 and not PodRush.isAuto("3f2a9c0d1e7b4a55") and not PodRush.isAuto("auto")
			and not PodRush.isAuto("autoX12") and not PodRush.isAuto(nil),
		"a slot's rush is named by its start; an admin's GUID-made id never reads as one", id)

	--==========================================================================
	say("3. One server through its hour")
	--==========================================================================
	now = S0 - 120
	local A = newServer("ServerA")
	local lou, quinn = person(90000000001, "Lou"), person(90000000002, "Quinn", true)
	join(A, lou)
	join(A, quinn)
	A.mini.Poll()
	step({ A }, S0 - 60.25)
	check(#noticesWith(A, "podrush:soon:") == 0 and A.mini.State() == nil, "nothing before the minute")
	step({ A }, S0 - 59)
	local warns = noticesWith(A, "podrush:soon:")
	check(#warns == 1 and warns[1].payload.title == AUTO.Warn.Title and warns[1].payload.detail == AUTO.Warn.Detail
			and warns[1].payload.key == "podrush:soon:" .. PodRush.autoId(S0) and type(warns[1].to) == "table"
			and #warns[1].to == 1 and warns[1].to[1] == lou,
		"a minute before, one warning -- to everybody here but the player in their first loop")
	step({ A }, S0 - 0.25)
	check(#noticesWith(A, "podrush:soon:") == 1 and A.mini.State() == nil, "said once; nothing starts before :30")
	step({ A }, S0)
	local st = A.mini.State()
	check(st ~= nil and st.mode == RUSH.Mode and st.id == PodRush.autoId(S0) and st.startedAt == S0
			and st.endsAt == S0 + 300 and st.scheduled == true and st.state == "running"
			and A.attrs:GetAttribute(ATTR.State) == "running" and A.attrs:GetAttribute(ATTR.Mode) == RUSH.Mode
			and A.attrs:GetAttribute(ATTR.EventId) == PodRush.autoId(S0),
		"at :30 the rush runs here, published as any rush is (PodRushService reads it), for 5 minutes",
		st and st.id)
	step({ A }, S0 + 3)
	local opened = sentOf(A, M.Events.Opened)
	check(#opened == 1 and opened[1].payload.mode == RUSH.Mode and opened[1].payload.id == PodRush.autoId(S0)
			and type(opened[1].to) == "table" and #opened[1].to == 1 and opened[1].to[1] == lou,
		"its start pop-up and sting go out once, passing the player in their first loop by")
	check(store.writes == 0 and store.value == nil, "nothing is written to the shared store: every server reads the clock")
	step({ A }, S0 + 300)
	local ending = A.mini.State()
	check(ending ~= nil and ending.state == "ending", "it ends by its timer at :35")
	step({ A }, S0 + 300 + M.FadeSeconds + 0.5)
	check(A.mini.State() == nil and has(A.mini.StatusLine(), "next hourly POD RUSH in"),
		"and is gone after the fade; the console's status line names the next one", A.mini.StatusLine())

	--==========================================================================
	say("4. Every server at once")
	--==========================================================================
	local S1 = S0 + AUTO.PeriodSeconds
	local B = newServer("ServerB")
	join(B, person(90000000003, "Bea"))
	B.mini.Poll()
	step({ A, B }, S1 + 1)
	local a, b = A.mini.State(), B.mini.State()
	check(a ~= nil and b ~= nil and a.id == b.id and a.id == PodRush.autoId(S1) and a.startedAt == b.startedAt
			and a.endsAt == b.endsAt,
		"two servers start the same rush, the same id, at the same moment", a and a.id)
	local bw = noticesWith(B, "podrush:soon:")
	check(#bw == 1 and bw[1].to == nil, "with nobody here in their first loop, the warning goes to everybody at once")
	step({ A, B }, S1 + 120)
	local C = newServer("ServerC")
	join(C, person(90000000004, "Cy"))
	C.mini.HourlyStep(now)
	C.mini.Step(now)
	check(C.mini.State() == nil, "a new server whose first read of the record is still to come starts nothing")
	C.mini.Poll()
	step({ A, B, C }, now + 1)
	local c = C.mini.State()
	check(c ~= nil and c.id == PodRush.autoId(S1) and c.startedAt == S1 and c.endsAt == S1 + 300
			and #sentOf(C, M.Events.Opened) == 0 and #noticesWith(C, "podrush:soon:") == 0,
		"then it joins for what is left: the same rush, unannounced and unwarned", c and c.id)
	step({ A, B, C }, S1 + 300 + M.FadeSeconds + 1)

	--==========================================================================
	say("5. An admin's event and the hour")
	--==========================================================================
	local S2 = S1 + AUTO.PeriodSeconds
	step({ A }, S2 - 100)
	local okStart, msg = A.mini.StartGlobal(ADMIN, "ticketdisco", 300)
	check(okStart == true and has(msg, "that hour has none"),
		"an admin's event that runs past :30 starts, and the console says that hour has none", msg)
	step({ A }, S2 + 1)
	local held = A.mini.State()
	check(#noticesWith(A, "podrush:soon:" .. PodRush.autoId(S2)) == 0 and held ~= nil and held.mode == "ticketdisco",
		"no warning and no rush while it holds the slot", held and held.mode)
	step({ A }, S2 + 260)
	local after = A.mini.State()
	check(after == nil or after.mode ~= RUSH.Mode, "and none later in that hour, after it ends: the hour is skipped",
		after and after.mode)
	local S3 = S2 + AUTO.PeriodSeconds
	step({ A }, S3 - 400)
	local okEarly = A.mini.StartGlobal(ADMIN, "ticketdisco", 300)
	step({ A }, S3 - 59)
	check(okEarly == true and #noticesWith(A, "podrush:soon:" .. PodRush.autoId(S3)) == 1,
		"an admin's event over before :30 leaves the hour its warning")
	step({ A }, S3 - 30)
	local D = newServer("ServerD")
	join(D, person(90000000005, "Di"))
	D.mini.Poll()
	step({ A, D }, S3 + 1)
	local rush = A.mini.State()
	check(rush ~= nil and rush.id == PodRush.autoId(S3) and rush.scheduled == true, "and its rush", rush and rush.id)
	local d = D.mini.State()
	check(d ~= nil and d.id == PodRush.autoId(S3) and #noticesWith(D, "podrush:soon:") == 0,
		"a server that comes up after the warning's moment sends no late warning, and runs the same rush")
	local writes = store.writes
	local okMid, msgMid = A.mini.StartGlobal(ADMIN, "ticketdisco", 90)
	local okEnd, msgEnd, endedAny = A.mini.EndGlobal(ADMIN)
	local still = A.mini.State()
	check(okMid == false and has(msgMid, "hourly POD RUSH is running") and okEnd == false and endedAny == false
			and has(msgEnd, "ends by itself") and store.writes == writes and still ~= nil
			and still.id == PodRush.autoId(S3) and still.state == "running",
		"while it runs, the console starts nothing and ends nothing: one event at a time", msgMid)
	local late = json(store.value)
	late.rev += 1
	late.state = "ended"
	late.endedAt = late.endsAt
	late.endedBy = ADMIN.UserId
	late.endedByName = ADMIN.Name
	late.endedIds = { late.id }
	A.mini.OnMessage(late)
	local kept = A.mini.State()
	check(kept ~= nil and kept.id == PodRush.autoId(S3) and kept.state == "running",
		"a newer record of nothing running (a late END) leaves the hourly rush be")
	step({ A }, S3 + 300 + M.FadeSeconds + 1)

	--==========================================================================
	say("6. The off switch")
	--==========================================================================
	local S4 = S3 + AUTO.PeriodSeconds
	-- GameConfig is frozen: the switch through the service's own seam.
	A.mini.useHourly(setmetatable({ Enabled = false }, { __index = AUTO }))
	step({ A }, S4 + 3)
	local off = A.mini.State()
	check(#noticesWith(A, "podrush:soon:" .. PodRush.autoId(S4)) == 0 and off == nil
			and has(A.mini.StatusLine(), "hourly POD RUSH off"),
		"Enabled = false: no warning, no rush, and the console's status line says it is off")
	A.mini.useHourly(nil)

	--==========================================================================
	say("7. PodRushService: the quiet first loop, and the tag")
	--==========================================================================
	local PodRushService = require(Server.PodRushService)
	local H = PodRushService.Hooks
	local saved = {}
	for k, v in pairs(H) do
		saved[k] = v
	end
	local served, serveErr = pcall(function()
		local at = S0
		local mini = {}
		local sent, metrics, profiles, roster = {}, {}, {}, {}
		H.now = function()
			return at
		end
		H.players = function()
			return roster
		end
		H.state = function()
			return mini
		end
		H.send = function(p, action, payload)
			table.insert(sent, { to = p, action = action, payload = payload })
		end
		H.setUntil = function() end
		H.setRush = function() end
		H.profile = function(p)
			return profiles[p]
		end
		H.update = function(p, change)
			local prof = profiles[p]
			if not prof then
				return false
			end
			return change(prof) == true
		end
		H.spins = function(_, n)
			return n
		end
		H.owe = function() end
		H.boost = function()
			return true
		end
		H.givePod = function()
			return true
		end
		H.carrying = function()
			return nil
		end
		H.metric = function(p, count, level, source)
			table.insert(metrics, { p = p, count = count, level = level, source = source })
		end
		H.random = function()
			return Random.new(7)
		end
		local function sentTo(p, action, prefix)
			local list = {}
			for _, s in ipairs(sent) do
				if s.to == p and s.action == action and (prefix == nil or (type(s.payload.key) == "string"
					and string.sub(s.payload.key, 1, #prefix) == prefix)) then
					table.insert(list, s.payload)
				end
			end
			return list
		end
		local function lastMetric(p)
			local found = nil
			for _, row in ipairs(metrics) do
				if row.p == p then
					found = row
				end
			end
			return found
		end
		local pat, quinn2, gil = person(90000000011, "Pat"), person(90000000012, "Quinn", true), person(90000000013, "Gil")
		roster = { pat, quinn2, gil }
		for _, p in ipairs(roster) do
			profiles[p] = { PodRush = { Id = "", Count = 0, Paid = 0, Top = 0, PodOwed = "" } }
		end
		local species = SeedData.Roll("greenhollow", Random.new(3))
		local function bank(p)
			PodRushService.Banked(p, { species = species, tier = 2, fromNest = "Nest_spec", stolenAt = at - 1 })
		end
		PodRushService.Reset()
		local ID = PodRush.autoId(S0)
		mini = { state = "running", mode = RUSH.Mode, id = ID, startedAt = S0, endsAt = S0 + 300 }
		at = S0 + 2
		PodRushService.Step(at)
		bank(pat)
		for _ = 1, RUSH.Levels[3].Pods do
			at += 1
			bank(gil)
		end
		check(#sentTo(pat, Notice.ServerNotice, "podrush:gold:") == 1 and #sentTo(quinn2, Notice.ServerNotice, "podrush:gold:") == 0,
			"someone's GOLD is said to everybody else here -- but not to a player in their first loop")
		mini = { state = "ending", mode = RUSH.Mode, id = ID, startedAt = S0, endsAt = S0 + 300, endingAt = S0 + 300 }
		at = S0 + 300
		PodRushService.Step(at)
		at = S0 + 300 + RUSH.GraceSeconds + 1
		PodRushService.Step(at)
		local overPat, overQuinn = sentTo(pat, RUSH.Events.Over), sentTo(quinn2, RUSH.Events.Over)
		check(#overPat == 1 and overPat[1].count == 1 and #overQuinn == 0,
			"the end card: to a player who took part; none to one in their first loop who banked nothing")
		local mp, mq, mg = lastMetric(pat), lastMetric(quinn2), lastMetric(gil)
		check(mp and mp.source == "scheduled" and mq and mq.count == 0 and mq.level == "none" and mq.source == "scheduled"
				and mg and mg.level == "gold" and mg.source == "scheduled",
			"PodRushEnded still goes for every player, field 02 \"scheduled\"")
		local ADMIN_ID = "3f2a9c0d1e7b4a55"
		mini = { state = "running", mode = RUSH.Mode, id = ADMIN_ID, startedAt = at, endsAt = at + 300 }
		local began = at
		at += 1
		PodRushService.Step(at)
		bank(quinn2)
		mini = { state = "ending", mode = RUSH.Mode, id = ADMIN_ID, startedAt = began, endsAt = began + 300,
			endingAt = at + 1 }
		at += 2
		PodRushService.Step(at)
		at += RUSH.GraceSeconds + 1
		PodRushService.Step(at)
		local overQ = sentTo(quinn2, RUSH.Events.Over)
		local mq2 = lastMetric(quinn2)
		check(#overQ == 1 and overQ[1].count == 1 and mq2 and mq2.source == "admin",
			"a player in their first loop who banks a pod gets their end card -- and an admin's rush is tagged admin")
	end)
	for k, v in pairs(saved) do
		H[k] = v
	end
	PodRushService.Reset()
	check(served, "PodRushService's stand-ins ran", serveErr)

	--==========================================================================
	say("8. PodRushEnded's field 02")
	--==========================================================================
	local Metrics = require(Server.Metrics)
	local got = {}
	Metrics.reset()
	Metrics.useSink({
		onboarding = function() end,
		funnel = function() end,
		custom = function(_player, name, _value, fields)
			if name == Metrics.Events.PodRushEnded then
				table.insert(got, (fields and fields.CustomField01 or "?") .. "/" .. (fields and fields.CustomField02 or "?"))
			end
		end,
	})
	Metrics.useClock(function()
		return 1000
	end)
	Metrics.useStaffCheck(function()
		return false
	end)
	Metrics.configure({ Enabled = true, ExcludeStaff = true, StaffValidation = false, PerMinuteBase = 1000,
		PerMinutePerPlayer = 0, ReserveShare = 0.25, CohortSince = 5000, Obby = false })
	Metrics.useHeadcount(function()
		return 0
	end)
	local someone = { Name = "Someone" }
	Metrics.profileReady(someone, { CreatedAt = 6000 }, true, true)
	Metrics.podRushEnded(someone, 4, "bronze", "scheduled")
	Metrics.podRushEnded(someone, 0, "none", "admin")
	Metrics.podRushEnded(someone, 2, "none", "weird")
	Metrics.podRushEnded(someone, 1, "none")
	local line = table.concat(got, ",")
	check(line == "bronze/scheduled,none/admin,none/admin,none/admin",
		"\"scheduled\" for the hourly rush, \"admin\" for an admin's -- and for anything else, as every rush was", line)
	Metrics.useSink(nil)
	Metrics.configure(nil)
	Metrics.useStaffCheck(nil)
	Metrics.useClock(nil)
	Metrics.useHeadcount(nil)
	Metrics.reset()

	--==========================================================================
	say("9. The wiring")
	--==========================================================================
	local miniSrc = sourceOf(Server, "MiniEventService")
	local stepBody = bodyOf(miniSrc, "function MiniEventService.Step(now: number)")
	local autoBody = bodyOf(miniSrc, "function MiniEventService.HourlyStep(now: number)")
	check(has(miniSrc, "local okHourly, errHourly = pcall(MiniEventService.HourlyStep, now)") and stepBody ~= ""
			and not has(stepBody, "HourlyStep") and autoBody ~= "" and not has(autoBody, "Mist"),
		"the live loop runs the schedule and Step never does; it never asks after the Mist (both may run)")
	check(has(miniSrc, "if shape and shape.PodRush == true then loudPlayers() else nil"),
		"every POD RUSH's start pop-up passes a player in their first loop by, an admin's too")
	local ui = sourceOf(Scripts, "PodRushUI")
	check(has(ui, "if showing and player:GetAttribute(GameConfig.FirstHatch.QuietAttribute) == true\n"
			.. "\t\tand myCount(if running then id else player:GetAttribute(ATTR.Id)) == 0\n"
			.. "\t\tand player:GetAttribute(ATTR.Carrying) ~= true then\n\t\tshowing = false"),
		"their tracker waits until a pod of theirs counts, or would")

	--==========================================================================
	say("10. What's New")
	--==========================================================================
	-- One of the newest shown (the same day's biome secrets lead it since 2026-10-16).
	local newest = nil
	for _, entry in ipairs(UpdateLog.shown()) do
		if entry.id == "2026-10-16-hourly-rush" then
			newest = entry
		end
	end
	local problems = UpdateLog.problems()
	check(newest ~= nil and newest.title == "POD RUSH every hour" and #newest.bullets == 2 and #problems == 0,
		"What's New shows it, in the panel's own shape", table.concat(problems, "; "))
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
fixture:Destroy()

say(string.format("\nPodRushHourlySpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
