--!nocheck
--==============================================================================
-- Steal a Seed :: MiniEventSpec (2026-10-03, the GLOBAL Ticket Disco)
--
-- Edit mode, no Play, no DataStore, no MessagingService:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("MiniEventSpec"))
--
-- SEVERAL "SERVERS" IN ONE STUDIO. Each is a fresh clone of the real
-- MiniEventService and WheelService in a folder of its own, with stand-ins for
-- what WheelService leans on (a PlayerDataService holding profiles built by
-- the real ProfileSchema), all pointed at ONE stand-in shared store (UpdateAsync
-- semantics: a transform over the current value; a queued competing write can
-- land first, as in a real race) and ONE stand-in message bus that delivers
-- only when the spec says so -- late, twice, out of order or never. Every value
-- crossing the store or the bus goes through JSON, as the real ones do.
--
-- Checked: the admins (the real AdminService.Handle: who may, what is
-- refused, the weather still owner-only); one event at a time and a duplicate
-- START that changes nothing; concurrent STARTs and ENDs; END everywhere and
-- its tombstone against late STARTs; duplicate and out-of-order messages;
-- missed messages caught up by the poll; a new server joining for what is left;
-- held messages before the first read; expiry on every server's own clock and
-- its cleanup; honest failures (store down, notice failed, reads failing);
-- tickets dropped, swept up, claimed once, capped at 3 per player per GLOBAL
-- event across servers, rejoin and death; the claims saved with the spins and
-- bounded; the profile schema's new fields; the Studio namespace; the HUD's
-- mini line on five screens; and the client wiring that keeps one owner of
-- Lighting and of the music. And (2026-10-04) the pure DISCO ONLY: its own
-- mode id through the console's verb, no tickets, the old ids unchanged
-- (DiscoPartySpec holds its movement factor).
--
-- NOT here: real MessagingService delivery between real servers, real
-- DataStore contention, and anything a client draws (Play, and live servers).
--==============================================================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local HudLayout = require(Shared.HudLayout)
local WheelData = require(Shared.WheelData)
local Server = game:GetService("ServerScriptService").SeedGameServer
local Scripts = game:GetService("StarterPlayer").StarterPlayerScripts
local ProfileSchema = require(Server.ProfileSchema)

local M = GameConfig.MiniEvent
local T = M.Tickets
local ATTR = M.Attributes
local ADMIN_A, ADMIN_B = 4119740186, 11607308004

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
	local node = if name then parent:FindFirstChild(name) else parent
	local ok, src = pcall(function()
		return node.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function json(v)
	if v == nil then
		return nil
	end
	return HttpService:JSONDecode(HttpService:JSONEncode(v))
end

local fixture = Instance.new("Folder")
fixture.Name = "ZZMiniEventSpec"
fixture.Archivable = false
fixture.Parent = ServerStorage

--==============================================================================
-- THE STAND-INS
--==============================================================================
local now = 1790000000
local function clock()
	return now
end

local store = { value = nil, writes = 0, failNext = false, readFails = false, race = nil }
local bus = { sent = {}, fail = false }
local NS = "place_spec"

local function storeSeam()
	return {
		scope = "global",
		note = "spec store",
		ns = NS,
		update = function(transform)
			if store.failNext then
				store.failNext = false
				return false, "spec: the store is down"
			end
			local race = store.race
			store.race = nil
			if race then
				-- A competing write lands first; the transform then runs over it, as
				-- UpdateAsync re-runs a transform that lost a conflict.
				race()
			end
			local nextValue = transform(json(store.value))
			if nextValue ~= nil then
				store.value = json(nextValue)
				store.writes += 1
			end
			return true, nil
		end,
		read = function()
			if store.readFails then
				return false, "spec: reads are failing"
			end
			return true, json(store.value)
		end,
		publish = function(record)
			table.insert(bus.sent, json(record))
			if bus.fail then
				return false, "spec: publish failed"
			end
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

local servers = {}
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
	local tickets = Instance.new("Folder")
	tickets.Name = "Tickets"
	tickets.Parent = folder
	local S = {
		label = label,
		data = require(folder.PlayerDataService),
		wheel = require(wheelModule),
		mini = require(miniModule),
		attrs = attrs,
		tickets = tickets,
		players = {},
		roots = {},
		sent = {},
		spots = {},
	}
	local mini = S.mini
	mini.useShared(storeSeam())
	mini.useClock(clock)
	mini.usePlayers(function()
		return S.players
	end)
	mini.useRoot(function(p)
		return S.roots[p]
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
		return table.remove(S.spots, 1)
	end)
	mini.useWorld(attrs, tickets)
	table.insert(servers, S)
	return S
end

local function standIn(id, name)
	local attrs = {}
	local p = { UserId = id, Name = name, Parent = Players, Character = nil }
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

local function join(S, p, profile)
	table.insert(S.players, p)
	S.data.profiles[p] = profile or ProfileSchema.Default()
end

local function leave(S, p)
	local i = table.find(S.players, p)
	if i then
		table.remove(S.players, i)
	end
	local profile = S.data.profiles[p]
	S.data.profiles[p] = nil
	S.roots[p] = nil
	-- What a server switch carries: the saved record, through the real validator.
	return ProfileSchema.Sanitise(json(profile))
end

local function count(S, action)
	local n = 0
	for _, m in ipairs(S.sent) do
		if m.action == action then
			n += 1
		end
	end
	return n
end

-- Walks the shared clock to `to`, stepping one server or a list in lockstep.
local function step(S, to, dt)
	dt = dt or 0.1
	local list = if S.mini then { S } else S
	while now < to - 1e-9 do
		now = math.min(to, now + dt)
		for _, one in ipairs(list) do
			one.mini.Step(now)
			one.mini.CheckPickups(now)
		end
	end
end

-- Ticket records still waiting to be taken (a collected one lingers a moment,
-- stamped ClaimedBy, for its collector's client).
local function unclaimedRecords(S)
	local folder = S.tickets:FindFirstChild(M.FolderName)
	local n = 0
	if folder then
		for _, r in ipairs(folder:GetChildren()) do
			if r:GetAttribute("ClaimedBy") == nil then
				n += 1
			end
		end
	end
	return n
end

local function deliver(S, record)
	S.mini.OnMessage(json(record))
end

local ok, err = pcall(function()
	--==========================================================================
	say("1. The admins: who may start and end a global event")
	--==========================================================================
	local MiniEventService = require(Server.MiniEventService)
	local AdminService = require(Server.AdminService)
	local adminStore = { value = nil }
	local adminAttrs = Instance.new("Folder")
	adminAttrs.Parent = fixture
	MiniEventService.useShared({
		scope = "global",
		note = "spec admin store",
		ns = "place_spec_admin",
		update = function(transform)
			local v = transform(json(adminStore.value))
			if v ~= nil then
				adminStore.value = json(v)
			end
			return true, nil
		end,
		read = function()
			return true, json(adminStore.value)
		end,
		publish = function()
			return true, nil
		end,
		subscribe = function()
			return true, nil
		end,
	})
	MiniEventService.useClock(clock)
	MiniEventService.usePlayers(function()
		return {}
	end)
	MiniEventService.useBroadcast(function() end)
	MiniEventService.useWorld(adminAttrs, adminAttrs)
	local keptInterval = AdminService.Config.MinInterval
	AdminService.Config.MinInterval = 0
	local stranger = { UserId = 1, Name = "Stranger" }
	local adminA = { UserId = ADMIN_A, Name = "nicnicniccoal" }
	local adminB = { UserId = ADMIN_B, Name = "Teambarnze825" }
	local r = AdminService.Handle(stranger, "MiniEvent", "ticketdisco", 90)
	check(r.ok == false and r.message == "Not authorized." and adminStore.value == nil,
		"somebody off the allowlist is refused on the server, and nothing is written", r.message)
	r = AdminService.Handle(adminB, "MiniEvent", "ticketdisco", 29)
	local r2 = AdminService.Handle(adminB, "MiniEvent", "ticketdisco", 301)
	local r3 = AdminService.Handle(adminB, "MiniEvent", "ticketdisco", 90.5)
	local r4 = AdminService.Handle(adminB, "MiniEvent", "ticketdisco", "90")
	-- ("party" was the unknown mode here until it became DISCO ONLY, 2026-10-04.)
	local r5 = AdminService.Handle(adminB, "MiniEvent", "rave", 90)
	check(not r.ok and not r2.ok and not r3.ok and not r4.ok and not r5.ok and adminStore.value == nil,
		"a duration outside 30..300 whole seconds, or an unknown mode, is refused and nothing is written")
	r = AdminService.Handle(adminB, "MiniEvent", "ticketdisco", 90)
	check(r.ok == true and adminStore.value ~= nil and adminStore.value.byName == "Teambarnze825"
			and adminStore.value.mode == "ticketdisco" and adminStore.value.endsAt - adminStore.value.startedAt == 90,
		"the second allowlisted account (not the owner) starts a global Ticket Disco: id, mode, admin, absolute times",
		r.message)
	local firstId = adminStore.value.id
	r = AdminService.Handle(adminA, "MiniEvent", "disco", 120)
	check(r.ok == false and adminStore.value.id == firstId and adminStore.value.rev == 1
			and string.find(r.message, "already running", 1, true) ~= nil,
		"a second START, by either admin, is refused and changes nothing", r.message)
	r = AdminService.Handle(adminB, "Weather", "start", 60)
	check(r.ok == false and string.find(r.message, "Owner only", 1, true) ~= nil,
		"the weather is still the owner's alone (the mini event made nothing else global)", r.message)
	r = AdminService.Handle(adminA, "MiniEvent", "end", nil)
	r2 = AdminService.Handle(adminA, "MiniEvent", "end", nil)
	check(r.ok and adminStore.value.state == "ended" and adminStore.value.rev == 2 and r2.ok
			and string.find(r2.message, "No global event", 1, true) ~= nil and adminStore.value.rev == 2,
		"END ends it (rev 2, ended); a second END is harmless and writes nothing", r2.message)
	local trail = AdminService.Audit()
	local seen = {}
	for _, e in ipairs(trail) do
		seen[e.action] = true
	end
	check(seen["MiniEvent:ticketdisco:90"] and seen["MiniEvent:end"], "both are on the admin record")
	-- The console's new DISCO ONLY button (2026-10-04) asks with its own verb.
	r = AdminService.Handle(adminA, "MiniEvent", "party", 60)
	check(r.ok == true and adminStore.value.mode == "party" and adminStore.value.state == "running"
			and adminStore.value.rev == 3 and adminAttrs:GetAttribute(ATTR.Mode) == "party"
			and adminAttrs:GetAttribute(ATTR.State) == "running" and adminAttrs:GetAttribute(ATTR.Cap) == nil
			and string.find(r.message, "DISCO ONLY", 1, true) ~= nil
			and string.find(r.message, "tickets per player", 1, true) == nil,
		"START DISCO ONLY (\"party\") goes the same allowlisted global way, as its own mode, with no ticket cap", r.message)
	r = AdminService.Handle(adminB, "MiniEvent", "party", 90)
	r2 = AdminService.Handle(adminB, "MiniEvent", "disco", 90)
	check(not r.ok and not r2.ok and adminStore.value.mode == "party" and adminStore.value.rev == 3
			and adminStore.value.endsAt - adminStore.value.startedAt == 60,
		"a second START of it, or of another mode, is refused and changes nothing (its timer stands)", r.message)
	r = AdminService.Handle(adminA, "MiniEvent", "end", nil)
	check(r.ok and adminStore.value.state == "ended" and adminStore.value.rev == 4
			and adminAttrs:GetAttribute(ATTR.State) == "ending",
		"and END ends it like any other", r.message)
	AdminService.Config.MinInterval = keptInterval
	MiniEventService.Reset()
	MiniEventService.useWorld(nil, nil)
	MiniEventService.useShared(nil)
	MiniEventService.useClock(nil)
	MiniEventService.usePlayers(nil)
	MiniEventService.useBroadcast(nil)
	local scope, ns = MiniEventService.Scope()
	check(ns ~= GameConfig.MiniEvent.Global.KeyPrefix .. tostring(game.PlaceId),
		"in Studio the record is never the live key: " .. scope .. " / " .. ns)

	--==========================================================================
	say("2. One global event, two servers")
	--==========================================================================
	local A = newServer("ServerA")
	local B = newServer("ServerB")
	-- Each server's first read, as at its start (nothing stored yet).
	A.mini.Poll()
	B.mini.Poll()
	local t0 = now
	local okA, msgA = A.mini.StartGlobal(adminA, "ticketdisco", 90)
	local rec1 = json(store.value)
	check(okA and rec1 and rec1.rev == 1 and rec1.state == "running" and rec1.by == ADMIN_A
			and math.abs(rec1.endsAt - (t0 + 90)) < 1e-6 and #rec1.id >= 8,
		"START writes ONE record: unique id, mode, revision 1, absolute start/end, the admin", msgA)
	check(string.find(msgA, "saved to shared storage", 1, true) ~= nil
			and string.find(msgA, "notice to other servers was sent", 1, true) ~= nil
			and string.find(msgA, "everywhere", 1, true) == nil,
		"the admin is told what happened -- saved, notice sent best-effort -- never 'started everywhere'")
	check(A.attrs:GetAttribute(ATTR.State) == "running" and A.attrs:GetAttribute(ATTR.EventId) == rec1.id
			and A.attrs:GetAttribute(ATTR.Scope) == "global" and A.attrs:GetAttribute(ATTR.EndsAt) == rec1.endsAt,
		"the starting server runs it at once, from the record's own times")
	local writes = store.writes
	local okDup, msgDup = B.mini.StartGlobal(adminB, "disco", 300)
	check(not okDup and store.writes == writes and json(store.value).id == rec1.id and json(store.value).rev == 1
			and json(store.value).endsAt == rec1.endsAt,
		"a START on ANOTHER server finds it running and changes nothing (timer, caps, id)", msgDup)
	check(B.mini.State() and B.mini.State().id == rec1.id,
		"and that server, having read the record, joins the same event")
	check(#bus.sent == 1, "exactly one notice went out")

	-- Announcement: once, about two seconds in, per server.
	step(A, t0 + 1.9)
	local early = count(A, M.Events.Opened)
	step(A, t0 + 3)
	check(early == 0 and count(A, M.Events.Opened) == 1, "the announcement comes once, about 2 s in")

	--==========================================================================
	say("3. Tickets: dropped here, swept up, claimed once, capped across servers")
	--==========================================================================
	local alice = standIn(9001, "Alice")
	local bob = standIn(9002, "Bob")
	join(A, alice)
	join(A, bob)
	A.spots = { Vector3.new(30, 0.9, 0), Vector3.new(30, 0.9, 10), Vector3.new(30, 0.9, -10), Vector3.new(20, 0.9, 5),
		Vector3.new(36, 0.9, -5), Vector3.new(25, 0.9, -15) }
	-- Run until two tickets are down and landed.
	step(A, now + T.DropSeconds * 2 + T.FallSeconds + 0.5)
	local st = A.mini.State()
	check(st and #st.tickets >= 2, "tickets drop on this server (" .. tostring(st and #st.tickets) .. " down)")
	local folderCount = #A.tickets:FindFirstChild(M.FolderName):GetChildren()
	check(folderCount == #st.tickets, "each one is a record the clients draw from, and nothing else")
	local first = st.tickets[1]
	-- Both stand on the first ticket in the same frame: one takes it.
	A.roots[alice] = first.at + Vector3.new(0, 3, 0)
	A.roots[bob] = first.at + Vector3.new(1, 3, 0)
	A.mini.CheckPickups(now)
	local aCount = A.wheel.EventClaimCount(alice, rec1.id)
	local bCount = A.wheel.EventClaimCount(bob, rec1.id)
	check(aCount + bCount == 1 and A.data.profiles[alice].WheelEarned + A.data.profiles[bob].WheelEarned == 1,
		"two players on one ticket in one frame: exactly one free spin, one claim")
	A.mini.CheckPickups(now)
	A.mini.CheckPickups(now)
	check(A.wheel.EventClaimCount(alice, rec1.id) + A.wheel.EventClaimCount(bob, rec1.id) == 1,
		"standing on its spot afterwards takes nothing more: the ticket is gone")
	A.roots[bob] = nil
	-- A fast run across the second ticket in one frame is swept; a teleport is not.
	st = A.mini.State()
	local second = st.tickets[1]
	A.roots[alice] = second.at + Vector3.new(-15, 3, 0)
	A.mini.CheckPickups(now)
	A.roots[alice] = second.at + Vector3.new(15, 3, 0)
	local before = A.wheel.EventClaimCount(alice, rec1.id)
	A.mini.CheckPickups(now)
	check(A.wheel.EventClaimCount(alice, rec1.id) == before + 1, "a runner crossing a ticket in one frame takes it (swept)")
	-- Fill alice to the cap on server A.
	while A.wheel.EventClaimCount(alice, rec1.id) < T.PerPlayerCap and now < t0 + 60 do
		step(A, now + 0.5)
		local s = A.mini.State()
		if s and s.tickets[1] and now >= s.tickets[1].landsAt then
			A.roots[alice] = s.tickets[1].at + Vector3.new(0, 3, 0)
			A.mini.CheckPickups(now)
			A.roots[alice] = nil
			A.mini.CheckPickups(now)
		end
	end
	check(A.wheel.EventClaimCount(alice, rec1.id) == T.PerPlayerCap
			and A.data.profiles[alice].WheelEarned == T.PerPlayerCap,
		"three tickets, three free EARNED spins, three claims -- together on the profile")
	check(A.data.profiles[alice].WheelDayCount == 0 and A.data.profiles[alice].WheelDayAt == 0
			and A.data.profiles[alice].CommunityClaimed == false and A.data.profiles[alice].HatchBonusClaimed == false,
		"the obby's daily allowance and the once-only rewards are untouched")
	-- At the cap: the ticket stays where it lies, and she is told (throttled).
	local waiting = nil
	for _ = 1, 30 do
		step(A, now + 0.5)
		local s = A.mini.State()
		for _, t in ipairs(s.tickets) do
			if now >= t.landsAt then
				waiting = t
				break
			end
		end
		if waiting then
			break
		end
	end
	local refusedBefore = count(A, M.Events.Refused)
	if waiting and now >= waiting.landsAt then
		A.roots[alice] = waiting.at + Vector3.new(0, 3, 0)
		A.mini.CheckPickups(now)
		A.mini.CheckPickups(now)
		A.roots[alice] = nil
	end
	local still = A.mini.State().tickets
	local stillThere = false
	for _, t in ipairs(still) do
		if waiting and t.id == waiting.id then
			stillThere = true
		end
	end
	check(waiting ~= nil and stillThere and A.wheel.EventClaimCount(alice, rec1.id) == T.PerPlayerCap
			and count(A, M.Events.Refused) == refusedBefore + 1,
		"at her cap a ticket underfoot stays for somebody else, and she is told once, not every frame")

	-- Alice moves to server B (B joined the event above): her saved claims go with her.
	local carried = leave(A, alice)
	local alice2 = standIn(9001, "Alice")
	join(B, alice2, carried)
	B.spots = { Vector3.new(30, 0.9, 0), Vector3.new(30, 0.9, 12) }
	step(B, now + T.DropSeconds + T.FallSeconds + 0.5)
	local bt = B.mini.State().tickets[1]
	if bt then
		B.roots[alice2] = bt.at + Vector3.new(0, 3, 0)
		B.mini.CheckPickups(now)
	end
	check(bt ~= nil and B.wheel.EventClaimCount(alice2, rec1.id) == T.PerPlayerCap
			and B.data.profiles[alice2].WheelEarned == T.PerPlayerCap and #B.mini.State().tickets >= 1,
		"on ANOTHER server, after a save and a load, she is still at 3: the cap is per GLOBAL event")
	-- Bob: two on server A, then dies (no body) and rejoins A.
	A.roots[bob] = nil
	A.mini.CheckPickups(now)
	local bobProfile = leave(A, bob)
	local bob2 = standIn(9002, "Bob")
	join(A, bob2, bobProfile)
	check(A.wheel.EventClaimCount(bob2, rec1.id) == bCount, "a rejoin to the same server keeps his count too")

	-- Failures that must not duplicate or lose: a save that does not land, a full balance, no saving.
	local carol = standIn(9003, "Carol")
	join(A, carol)
	A.data.failSave = true
	local okG, whyG, nG = A.wheel.GrantEventSpin(carol, rec1.id, T.PerPlayerCap, "spec")
	task.wait(0.05)
	check(okG and nG == 1 and A.data.profiles[carol].WheelEarned == 1,
		"a save that fails keeps the accepted claim and its spin together in memory (dirty; the autosave retries)")
	A.data.failSave = false
	A.data.profiles[carol].WheelEarned = WheelData.MaxEarnedHeld
	local okF, whyF = A.wheel.GrantEventSpin(carol, rec1.id, T.PerPlayerCap, "spec")
	check(not okF and whyF == "FULL" and A.wheel.EventClaimCount(carol, rec1.id) == 1,
		"a full spin balance takes nothing and claims nothing")
	A.data.persistent[carol] = false
	local okN, whyN = A.wheel.GrantEventSpin(carol, rec1.id, T.PerPlayerCap, "spec")
	check(not okN and whyN == "NOT_SAVED", "a profile that is not saving takes nothing")
	-- Bounded claims.
	local dave = standIn(9004, "Dave")
	join(A, dave)
	for i = 1, 12 do
		A.wheel.GrantEventSpin(dave, string.format("evt%02dxxxxxxxx", i), T.PerPlayerCap, "spec")
	end
	local claims = A.data.profiles[dave].EventClaims
	check(#claims == T.ClaimsKept and claims[#claims].Id == "evt12xxxxxxxx" and claims[1].Id == "evt05xxxxxxxx",
		string.format("claims stay bounded: the newest %d events only", T.ClaimsKept))

	--==========================================================================
	say("4. END everywhere, tombstones, duplicate and out-of-order messages")
	--==========================================================================
	local C = newServer("ServerC")
	-- C missed everything so far; it gets the START late, AFTER the END.
	local okEnd, msgEnd = B.mini.EndGlobal(adminB)
	local endRec = json(store.value)
	check(okEnd and endRec.state == "ended" and endRec.rev == 2 and endRec.id == rec1.id
			and table.find(endRec.endedIds, rec1.id) ~= nil and string.find(msgEnd, "everywhere", 1, true) == nil,
		"END on another server ends THE SAME event in storage (rev 2, tombstoned)", msgEnd)
	deliver(A, endRec)
	check(A.mini.State() and A.mini.State().state == "ending" and #A.mini.State().tickets == 0
			and unclaimedRecords(A) == 0,
		"server A hears it: drops stop and every unclaimed ticket is gone at once")
	check(A.wheel.EventClaimCount(bob2, rec1.id) == bCount and A.data.profiles[bob2].WheelEarned == bCount,
		"claimed spins stay saved")
	step(A, now + M.FadeSeconds + 0.2)
	check(A.mini.State() == nil and A.attrs:GetAttribute(ATTR.State) == nil,
		"after the fade the event is gone from server A (attributes cleared)")
	deliver(A, rec1)
	deliver(A, endRec)
	check(A.mini.State() == nil and A.mini.Known().rev == 2,
		"a late START and a duplicate END change nothing: the ended revision wins")
	-- C: END first, then the late START -- out of order. C has not read yet, so they wait; then it reads.
	C.mini.OnMessage(json(endRec))
	C.mini.OnMessage(json(rec1))
	check(C.mini.State() == nil, "a new server holds messages until its first read")
	C.mini.Poll()
	check(C.mini.State() == nil and C.mini.Known().rev == 2, "then reads, applies in revision order, and never runs the ended event")

	--==========================================================================
	say("5. Catch-up: missed messages, new servers, concurrent presses, expiry")
	--==========================================================================
	now += 10
	local t1 = now
	bus.sent = {}
	local okS, msgS = A.mini.StartGlobal(adminA, "disco", 120)
	local rec3 = json(store.value)
	check(okS and rec3.rev == 3 and rec3.mode == "disco" and table.find(rec3.endedIds, rec1.id) ~= nil,
		"a new START after an END: a new id, rev 3, the old id still tombstoned", msgS)
	-- B never gets the notice; its poll catches up.
	now += 20
	B.mini.Poll()
	check(B.mini.State() and B.mini.State().id == rec3.id and B.mini.State().endsAt == rec3.endsAt,
		"a server that missed the notice joins on its next read, with the SAME end time")
	-- A brand-new server, 40 s in, joins for what is left -- silently.
	now = t1 + 40
	local D = newServer("ServerD")
	D.mini.Poll()
	local ds = D.mini.State()
	check(ds and ds.id == rec3.id and math.abs((ds.endsAt - now) - 80) < 1e-6 and ds.announced == true,
		"a new server joins for the remaining 80 s (not a fresh duration) and does not announce it")
	step(D, now + 3)
	check(count(D, M.Events.Opened) == 0, "no late announcement there")
	-- Concurrent START: B's lands first inside A's write.
	local okEnd2 = A.mini.EndGlobal(adminA)
	deliver(B, json(store.value))
	deliver(D, json(store.value))
	step(B, now + M.FadeSeconds + 0.2)
	step(D, now + M.FadeSeconds + 0.2)
	writes = store.writes
	local okB, okA2, msgA2
	store.race = function()
		okB = B.mini.StartGlobal(adminB, "tickets", 60)
	end
	okA2, msgA2 = A.mini.StartGlobal(adminA, "ticketdisco", 90)
	local raced = json(store.value)
	check(okEnd2 and okB == true and okA2 == false and store.writes == writes + 1 and raced.mode == "tickets"
			and A.mini.State() and A.mini.State().id == raced.id,
		"two STARTs at once on two servers make ONE event; the loser is told and joins the winner's", msgA2)
	-- Concurrent END.
	writes = store.writes
	local okE1, msgE1, ended1, okE2, msgE2, ended2
	store.race = function()
		okE1, msgE1, ended1 = B.mini.EndGlobal(adminB)
	end
	okE2, msgE2, ended2 = A.mini.EndGlobal(adminA)
	check(ended1 == true and ended2 == false and store.writes == writes + 1 and json(store.value).state == "ended",
		"two ENDs at once write ONE end; the other is harmless", msgE2)
	-- Expiry, on every server's own clock, through the same close.
	deliver(B, json(store.value))
	step(A, now + M.FadeSeconds + 0.2)
	step(B, now + M.FadeSeconds + 0.2)
	local okX = A.mini.StartGlobal(adminA, "ticketdisco", 30)
	local recX = json(store.value)
	deliver(B, recX)
	A.spots = { Vector3.new(30, 0.9, 0) }
	local writesX = store.writes
	step({ A, B }, recX.endsAt - 0.05)
	check(okX and A.mini.State().state == "running" and B.mini.State().state == "running",
		"a 30 s event runs on both servers")
	step({ A, B }, recX.endsAt + 0.2)
	check(A.mini.State().state == "ending" and B.mini.State().state == "ending" and unclaimedRecords(A) == 0
			and store.writes == writesX,
		"at the shared end time both close by the timer -- the same close as END -- with no write and no message")
	step({ A, B }, now + M.FadeSeconds + 0.2)
	check(A.mini.State() == nil and B.mini.State() == nil and A.attrs:GetAttribute(ATTR.State) == nil
			and B.attrs:GetAttribute(ATTR.State) == nil, "and both are clean after the fade")
	local okEndX, msgEndX = A.mini.EndGlobal(adminA)
	check(okEndX and string.find(msgEndX, "already ended by its timer", 1, true) ~= nil,
		"END after expiry says so and writes nothing", msgEndX)
	local okY = A.mini.StartGlobal(adminA, "disco", 45)
	check(okY and table.find(json(store.value).endedIds, recX.id) ~= nil,
		"a START after an expiry is allowed, and the expired id joins the tombstones")
	A.mini.EndGlobal(adminA)

	--==========================================================================
	say("6. Honest failures")
	--==========================================================================
	step(A, now + M.FadeSeconds + 0.2)
	store.failNext = true
	local okD, msgD = A.mini.StartGlobal(adminA, "ticketdisco", 90)
	check(not okD and A.mini.State() == nil and string.find(msgD, "NO global event was started", 1, true) ~= nil,
		"the store unreachable: nothing starts, and the admin is told so", msgD)
	bus.fail = true
	local okP, msgP = A.mini.StartGlobal(adminA, "ticketdisco", 90)
	check(okP and string.find(msgP, "FAILED", 1, true) ~= nil and A.mini.State() ~= nil,
		"the notice failing: saved and running here, and the admin is told the other servers will be late", msgP)
	bus.fail = false
	A.mini.EndGlobal(adminA)
	store.readFails = true
	local polled = B.mini.Poll()
	check(polled == false and string.find(B.mini.StatusLine(), "FAILING", 1, true) ~= nil,
		"a failing read is reported in the admins' status line (and retried with backoff)", B.mini.StatusLine())
	store.readFails = false
	B.mini.Poll()
	check(string.find(B.mini.StatusLine(), "storage OK", 1, true) ~= nil, "and clears when reads work again")

	--==========================================================================
	say("7. The real ticket picker, ALL OVER the map in this Studio (2026-10-04)")
	--==========================================================================
	if Workspace:FindFirstChild(GameConfig.Map.FolderName) then
		local E = newServer("ServerE")
		E.mini.useSpot(nil)
		local WA = GameConfig.Weather.Attributes
		local phaseAttr = GameConfig.Attributes.WorldPhase
		local hadPhase, hadRain = Workspace:GetAttribute(phaseAttr), Workspace:GetAttribute(WA.State)
		Workspace:SetAttribute(phaseAttr, nil)
		Workspace:SetAttribute(WA.State, nil)
		local function valid(at, zoneName)
			local reasons = {}
			if zoneName and not E.mini.InZone(zoneName, at) then
				table.insert(reasons, "outside, in " .. tostring(E.mini.ZoneOf(at)))
			end
			if not E.mini.ClearOfKept(at) then
				table.insert(reasons, "kept")
			end
			if E.mini.InPlot(at) then
				table.insert(reasons, "plot")
			end
			if E.mini.PropAt(at) then
				table.insert(reasons, "prop")
			end
			if math.abs(at.Y - GameConfig.Map.GroundY) > M.Area.FloorTolerance then
				table.insert(reasons, "off the floor")
			end
			return #reasons == 0, table.concat(reasons, "+")
		end
		-- 1. Every open zone, by day, no rain: a good spot in each.
		local open = {}
		for _, zone in ipairs(E.mini.Zones()) do
			table.insert(open, zone.name)
		end
		check(table.concat(open, ",") == "Hub,Field,Front,greenhollow,dustbowl,tanglemire,emberroot,starbloom",
			"by day with no rain the zones are the hub, the field, the front and the five biomes", table.concat(open, ","))
		local fake = { globalId = "spec0000spec0000", mode = "tickets", tickets = {} }
		local missing, wrong = {}, {}
		for _, name in ipairs(open) do
			local found = 0
			for _ = 1, 8 do
				local at = E.mini.PickIn(name, fake)
				if at then
					found += 1
					local ok2, why = valid(at, name)
					if not ok2 then
						table.insert(wrong, string.format("%s (%.0f,%.0f): %s", name, at.X, at.Z, why))
					end
				end
			end
			if found < 6 then
				table.insert(missing, name .. " " .. found .. "/8")
			end
		end
		check(#missing == 0 and #wrong == 0,
			"every open zone gives spots (6+ of 8), each in its zone, on the floor, out of every plot, clear of props and "
				.. "of the stall, chests, pedestal, wheel, obby and Disco Mill",
			table.concat(missing, "; ") .. " | " .. table.concat(wrong, "; "))
		-- 2. The drops themselves, spread over the zones.
		local zonesHit, picked = {}, 0
		fake.tickets = {}
		for _ = 1, 120 do
			local at = E.mini.PickSpot(fake)
			if at then
				picked += 1
				zonesHit[E.mini.ZoneOf(at) or "?"] = true
				table.insert(fake.tickets, { at = at })
				if #fake.tickets >= T.MaxUnclaimed then
					fake.tickets = {}
				end
			end
		end
		local spread = 0
		for _ in pairs(zonesHit) do
			spread += 1
		end
		check(picked >= 110 and spread >= 6 and zonesHit["?"] == nil,
			string.format("%d of 120 drops found a spot, in %d different zones, none outside them", picked, spread))
		-- 3. A disco's dancers keep their ground.
		local discoFake = { globalId = "spec1111spec1111", mode = "ticketdisco", tickets = {} }
		local DancerPlacement = require(Shared.DancerPlacement)
		local troupe = DancerPlacement.Picks(discoFake.globalId)
		local onDancer = 0
		for _ = 1, 80 do
			local at = E.mini.PickIn("Field", discoFake)
			if at then
				for _, pick in ipairs(troupe) do
					if (Vector3.new(at.X, 0, at.Z) - pick.at).Magnitude < pick.radius + 2 then
						onDancer += 1
					end
				end
			end
		end
		check(#troupe > 0 and onDancer == 0, "during a disco no ticket falls on a dancer's ground",
			string.format("%d dancers, %d hits", #troupe, onDancer))
		-- 4. Known ground: a plot, a prop, open grass.
		local plotted = false
		for _, plot in ipairs(game:GetService("CollectionService"):GetTagged(GameConfig.Tags.Plot)) do
			local cf = plot:GetAttribute("PlotCF")
			if typeof(cf) == "CFrame" then
				plotted = E.mini.InPlot(cf.Position)
				break
			end
		end
		check(plotted and not E.mini.InPlot(Vector3.new(0, 0, -100)) and E.mini.PropAt(Vector3.new(-104, 0, -148))
				and not E.mini.PropAt(Vector3.new(10, 0, -120)),
			"a plot's middle is a plot, the weather screen's housing is a prop, the open front is neither")
		-- 5. Night shuts the biomes; their tickets go with them.
		Workspace:SetAttribute(phaseAttr, GameConfig.WorldCycle.PhaseNight)
		local nightZones = {}
		for _, zone in ipairs(E.mini.Zones()) do
			table.insert(nightZones, zone.name)
		end
		check(table.concat(nightZones, ",") == "Hub,Field,Front" and not E.mini.ZoneOpen("greenhollow")
				and E.mini.ZoneOpen("Field") and E.mini.ZoneOpen(nil),
			"at night no ticket falls in a biome, and one lying there is taken away", table.concat(nightZones, ","))
		Workspace:SetAttribute(phaseAttr, nil)
		-- 6. The rain biome, while it is open (a stand-in floor, far off the map).
		local rainFolder = Instance.new("Folder")
		rainFolder.Name = GameConfig.Weather.Biome.FolderName
		local floorPart = Instance.new("Part")
		floorPart.Name = "RoomFloor1"
		floorPart.Anchored = true
		floorPart.Size = Vector3.new(60, 1, 60)
		floorPart.Position = Vector3.new(1400, GameConfig.Map.GroundY - 0.5, 1400)
		floorPart.Parent = rainFolder
		rainFolder.Parent = Workspace
		Workspace:SetAttribute(WA.State, "opening")
		local shutWhileOpening = E.mini.PickIn("Rain", fake) == nil and not E.mini.ZoneOpen("Rain")
		Workspace:SetAttribute(WA.State, "active")
		local rainSpots, rainGood = 0, 0
		for _ = 1, 10 do
			local at = E.mini.PickIn("Rain", fake)
			if at then
				rainSpots += 1
				if math.abs(at.X - 1400) <= 30 and math.abs(at.Z - 1400) <= 30 and math.abs(at.Y - GameConfig.Map.GroundY) < 0.01 then
					rainGood += 1
				end
			end
		end
		local openNow = E.mini.ZoneOpen("Rain")
		Workspace:SetAttribute(WA.State, "closing")
		local closedNow = not E.mini.ZoneOpen("Rain")
		rainFolder:Destroy()
		Workspace:SetAttribute(WA.State, hadRain)
		Workspace:SetAttribute(phaseAttr, hadPhase)
		check(shutWhileOpening and rainSpots >= 8 and rainGood == rainSpots and openNow and closedNow,
			"the rain biome takes tickets only while it is open, on its own floors; closing takes them away",
			string.format("opening shut %s, %d/%d on its floor, open %s, closed %s", tostring(shutWhileOpening),
				rainGood, rainSpots, tostring(openNow), tostring(closedNow)))
	else
		say("  SKIP  the map is not built in this Edit session")
	end

	--==========================================================================
	say("8. The saved fields")
	--==========================================================================
	local old = ProfileSchema.Sanitise({ Cash = 5 })
	check(type(old.EventClaims) == "table" and #old.EventClaims == 0 and old.DiscoDance == true,
		"an old save: no claims, and dancing ON")
	local messy = ProfileSchema.Sanitise({
		DiscoDance = false,
		EventClaims = {
			{ Id = "aaaaaaaaaaaaaaaa", Count = 2, At = 5 },
			{ Id = "aaaaaaaaaaaaaaaa", Count = 3, At = 6 },
			{ Id = "bad id!", Count = 1 },
			{ Id = "bbbbbbbbbbbbbbbb", Count = 99 },
			{ Id = "cccccccccccccccc", Count = -4 },
			"junk",
		},
	})
	check(messy.DiscoDance == false and #messy.EventClaims == 3 and messy.EventClaims[1].Count == 2
			and messy.EventClaims[2].Count == T.PerPlayerCap and messy.EventClaims[3].Count == 0,
		"claims sanitised: one row per id, counts whole and within the cap, junk dropped; OFF stays off")

	--==========================================================================
	say("9. The event's icons over the strip, on five screens (2026-10-04)")
	--==========================================================================
	-- The "Tickets: 2/3 · 0:42" / "Disco · 0:42" line became the tickets and
	-- disco icons (BoostIconsSpec holds the whole row); here: which icons each
	-- mode puts up, and that they stand over the strip with the toast over them.
	local BoostIcons = require(Shared.BoostIcons)
	local function iconsFor(mode, state)
		local now = 1000
		local list = BoostIcons.entries({ now = now, miniState = state, miniMode = mode, miniStartedAt = now - 10,
			miniEndsAt = now + 80, miniCap = 3, tickets = 2 })
		local ids = {}
		for i, e in ipairs(list) do
			ids[i] = e.id .. (if e.badge then "[" .. e.badge .. "]" else "")
		end
		return table.concat(ids, ",")
	end
	check(iconsFor("ticketdisco", "running") == "disco,tickets[2/3]" and iconsFor("disco", "running") == "disco"
			and iconsFor("party", "running") == "disco"
			and iconsFor("tickets", "running") == "tickets[2/3]" and iconsFor("ticketdisco", "ending") == "",
		"Ticket Disco shows the disco and the tickets (2/3 on its badge), each single mode its own (DISCO ONLY just the "
			.. "disco, never a ticket count), an ending event none",
		iconsFor("ticketdisco", "running") .. " | " .. iconsFor("disco", "running") .. " | " .. iconsFor("party", "running")
			.. " | " .. iconsFor("tickets", "running"))
	local function screen(w, h, touch, icons)
		return { safe = Vector2.new(w, h), touch = touch, keyboard = not touch, icons = icons,
			viewport = Vector2.new(w, h + 58), topbar = HudLayout.rect(0, 0, w, 58), insetTop = 58 }
	end
	local bad = {}
	for _, case in ipairs({ { "desktop 1920x1080", 1920, 1080, false }, { "small window 800x600", 800, 600, false },
		{ "phone 801x392", 801, 392, true }, { "phone 640x480", 640, 480, true }, { "phone 956x440", 956, 440, true } }) do
		local base = HudLayout.solve(screen(case[2], case[3], case[4], nil))
		local L = HudLayout.solve(screen(case[2], case[3], case[4], 2))
		local row = L.icons
		local band = HudLayout.hotbarBand(L.hotbar)
		local okCase = row ~= nil and base.icons == nil and row.y + row.h <= band.y - 8
			and row.x >= 8 and row.x + row.w <= case[2] - 8
			and HudLayout.gap(L.toast, row) >= 8 and L.toast.y + L.toast.h <= row.y
			and base.hotbar.x == L.hotbar.x and base.cash.y == L.cash.y
		if not okCase then
			table.insert(bad, case[1])
		end
	end
	check(#bad == 0, "two icons stand over the strip's name band, the toast steps over them, nothing else moves",
		table.concat(bad, ", "))
	local desk = HudLayout.solve(screen(1920, 1080, false, nil))
	check(desk.icons == nil, "with nothing running the layout has no row and is exactly as it was")

	--==========================================================================
	say("10. Wiring")
	--==========================================================================
	local miniSrc = sourceOf(Server, "MiniEventService")
	check(string.find(miniSrc, 'WaitForChild("WeatherService")', 1, true) == nil
			and string.find(miniSrc, 'GetService("Lighting")', 1, true) == nil
			and string.find(miniSrc, "OnServerEvent", 1, true) == nil,
		"the server never touches the weather or Lighting, and takes no client input at all")
	check(string.find(miniSrc, "if RunService:IsStudio() then", 1, true) ~= nil
			and string.find(miniSrc, "SAVE.TestStorePattern", 1, true) ~= nil
			and string.find(miniSrc, "G.TopicPrefix .. place", 1, true) ~= nil,
		"live servers use this place's own key and topic; Studio only the throwaway test store's, or none")
	local adminSrc = sourceOf(Server, "AdminService")
	check(string.find(adminSrc, 'if action == "MiniEvent" then', 1, true) ~= nil
			and string.find(adminSrc, "MiniEventService.StartGlobal(admin, verb, seconds)", 1, true) ~= nil
			and string.find(adminSrc, "if not AdminService.IsOwner(admin) then", 1, true) ~= nil,
		"AdminService routes MiniEvent after the allowlist; the weather keeps its owner check")
	local consoleSrc = sourceOf(Server.AdminService, "AdminConsoleUI")
	check(string.find(consoleSrc, '"START GLOBAL EVENT"', 1, true) ~= nil
			and string.find(consoleSrc, '"END GLOBAL EVENT"', 1, true) ~= nil
			and string.find(consoleSrc, '{ id = "events", label = "EVENTS"', 1, true) ~= nil
			and string.find(consoleSrc, '{ id = "weather", label = "WEATHER"', 1, true) ~= nil
			and string.find(consoleSrc, "miniDurationBox.Text = tostring(MINI.DefaultSeconds)", 1, true) ~= nil
			and string.find(consoleSrc, 'remote:InvokeServer("MiniEvent", verb, seconds, nil)', 1, true) ~= nil,
		"the console: EVENTS and WEATHER sections (2026-10-04, the compact console), START/END GLOBAL EVENT, the "
			.. "90 s duration box")
	check(M.DefaultSeconds == 90 and M.MinSeconds == 30 and M.MaxSeconds == 300 and T.PerPlayerCap == 3
			and T.DropSeconds == 2 and T.MaxUnclaimed == 20 and T.ExpireSeconds == 30,
		"the numbers: 90 s (30..300), a ticket every ~2 s, 3 per player -- and the owner's map-wide budget "
			.. "(2026-10-04): 20 at most, 30 s each (were 12 and 15 s)")
	local clockSrc = sourceOf(Scripts, "WorldClock")
	local _, brightness = string.gsub(clockSrc, "Lighting.Brightness = ", "")
	check(brightness == 1 and string.find(clockSrc, "* (1 - (1 - DISCO_LIGHT.Brightness) * disco)", 1, true) ~= nil
			and string.find(clockSrc, "+ DISCO_LIGHT.Exposure * disco", 1, true) ~= nil,
		"WorldClock lays the disco over its own blend: still the ONE owner of Lighting")
	local musicSrc = sourceOf(Scripts, "Music")
	local discoIds = (GameConfig.Music :: any).DiscoTracks
	check(#discoIds == 1 and discoIds[1] == "rbxassetid://118716691317783"
			and discoIds[1] ~= ((GameConfig.Music :: any).RainTracks or {})[1]
			and string.find(musicSrc, "discoTracks", 1, true) ~= nil
			and string.find(musicSrc, "Instance.new(\"Sound\")\nsound.Name = TRACK_NAME", 1, true) ~= nil
			and string.find(musicSrc, "sound.TimePosition = math.max(0, Workspace:GetServerTimeNow() - started) % length", 1, true) ~= nil
			and string.find(musicSrc, "return mode ~= nil and mode.Disco == true", 1, true) ~= nil,
		"the disco bed is the owner's track on Music's one Sound (never the rain BGM), only for disco modes, on the event's clock")
	local fxSrc = sourceOf(Scripts, "MiniEventFX")
	local danceSrc = sourceOf(Scripts, "DiscoDance")
	check(string.find(fxSrc, "StatusText.reducedMotion()", 1, true) ~= nil
			and string.find(fxSrc, "UserInputService.TouchEnabled", 1, true) ~= nil
			and string.find(fxSrc, "part.CanCollide = false", 1, true) ~= nil
			and string.find(fxSrc, "FireServer", 1, true) == nil,
		"the effects respect reduced motion, are lighter on a phone, never collide and send nothing")
	check(string.find(danceSrc, 'character:FindFirstChildOfClass("Tool")', 1, true) ~= nil
			and string.find(danceSrc, "A.CarryingSpecies", 1, true) ~= nil
			and string.find(danceSrc, "A.DiscoDance", 1, true) ~= nil
			and string.find(danceSrc, "StatusText.reducedMotion()", 1, true) ~= nil
			and string.find(danceSrc, "ATTR.StartedAt", 1, true) ~= nil,
		"dancing yields to the carry and every Tool, honours the saved opt-out and reduced motion, beats on the shared start")
	-- The "+1" pop (2026-10-04): drawn only on the Collected event -- which the
	-- server sends only after a grant -- once per event id and count, never on a
	-- refusal or on the count attribute; the per-ticket notice is gone.
	local uiSrc = sourceOf(Scripts, "MiniEventUI")
	local collectedAt = string.find(uiSrc, "elseif action == EVENTS.Collected then", 1, true) or 0
	local refusedAt = string.find(uiSrc, "elseif action == EVENTS.Refused then", collectedAt, true) or 0
	local popCalls = select(2, string.gsub(uiSrc, "\n%s*pop%(id, count%)", ""))
	check(collectedAt > 0 and refusedAt > collectedAt
			and string.find(string.sub(uiSrc, collectedAt, refusedAt), "pop(id, count)", 1, true) ~= nil
			and popCalls == 1
			and string.find(uiSrc, 'local key = eventId .. ":" .. count', 1, true) ~= nil
			and string.find(uiSrc, "if popped[key] then", 1, true) ~= nil
			and string.find(uiSrc, "GetAttributeChangedSignal", 1, true) == nil
			and string.find(uiSrc, "FireServer", 1, true) == nil
			and string.find(uiSrc, "WORDS.Collected", 1, true) == nil
			and string.find(uiSrc, "layout.mini", 1, true) == nil,
		"MiniEventUI pops \"+1\" only for a ticket the server confirmed, once per ticket, never on a refusal or an "
			.. "attribute; no per-ticket notice; no status line")
	local limitOnce = select(2, string.gsub(uiSrc, "limitSaid%[id%] = true", ""))
	check(limitOnce == 2 and string.find(uiSrc, "if not limitSaid[id] then", 1, true) ~= nil
			and string.find(sourceOf(Scripts, "ActionToastUI"),
				"GetAttributeChangedSignal(GameConfig.BoostIcons.Attribute):Connect(place)", 1, true) ~= nil,
		"the limit is said once per event, whichever way it is reached; the notices re-place round the icon row")
	check(string.find(danceSrc, "if player:GetAttribute(A.OnTreadmill) then", 1, true) ~= nil,
		"dancing pauses while the player trains on any belt, the Disco Mill's included")
	-- The four modes on the console (2026-10-04): the new DISCO ONLY first, the
	-- mill's mode under its clearer name with its old verb.
	check(string.find(consoleSrc, '{ "DiscoOnly", "DISCO ONLY" }, { "DiscoMill", "DISCO + MILL" },', 1, true) ~= nil
			and string.find(consoleSrc, '{ "TicketDisco", "TICKET DISCO" }, { "TicketShowerOnly", "TICKET SHOWER ONLY" },', 1, true) ~= nil
			and string.find(consoleSrc, '{ verb = "party", button = modes[1] },', 1, true) ~= nil
			and string.find(consoleSrc, '{ verb = "disco", button = modes[2] },', 1, true) ~= nil
			and string.find(consoleSrc, '{ verb = "ticketdisco", button = modes[3] },', 1, true) ~= nil
			and string.find(consoleSrc, '{ verb = "tickets", button = modes[4] },', 1, true) ~= nil
			and string.find(consoleSrc, "DISCO ONLY: the disco and up to +%d%% movement speed for everyone", 1, true) ~= nil
			and string.find(consoleSrc, "speed is capped at %d, so a player ", 1, true) ~= nil
			and string.find(consoleSrc, "already above %d gains less (no mill, no tickets)", 1, true) ~= nil
			and string.find(consoleSrc, '" (UP TO +%d%% SPEED)"', 1, true) ~= nil
			and string.find(adminSrc, "\tparty = true,\n", 1, true) ~= nil,
		"the console offers DISCO ONLY, DISCO + MILL, TICKET DISCO and TICKET SHOWER ONLY (verbs party, disco, "
			.. "ticketdisco, tickets), says what each gives, and the server accepts the new verb")

	--==========================================================================
	say("11. The pure DISCO ONLY (2026-10-04): a disco and x1.5 movement, no tickets, no mill")
	--==========================================================================
	local modes = M.Modes
	check(modes.ticketdisco and modes.disco and modes.tickets and modes.disco.Disco == true and modes.disco.Mill == true
			and modes.disco.Tickets == false and modes.disco.Name == "DISCO + MILL" and modes.ticketdisco.Mill == true
			and modes.tickets.Mill == false,
		"the old ids all stand (a running record names one): \"disco\" is still the disco with the mill, now called "
			.. "DISCO + MILL")
	local party = modes.party
	check(party and party.Name == "DISCO ONLY" and party.Disco == true and party.Tickets == false and party.Mill == false
			and party.SpeedFactor == 1.5 and party.Announce.Icon == "disco"
			and party.Announce.Detail == "Up to +50% movement speed for everyone!",
		"the new mode has its own id, \"party\": the disco, no tickets, no mill, up to x1.5 movement (\"Up to\": the "
			.. "speed cap)")
	local P = newServer("ServerP")
	P.mini.Poll()
	now += 5
	local tP = now
	local carol = standIn(9101, "Carol")
	join(P, carol)
	P.spots = { Vector3.new(30, 0.9, 0), Vector3.new(30, 0.9, 10), Vector3.new(30, 0.9, -10) }
	local okParty, msgParty = P.mini.StartGlobal(adminA, "party", 60)
	local recP = json(store.value)
	check(okParty and recP.mode == "party" and recP.state == "running" and P.attrs:GetAttribute(ATTR.Mode) == "party"
			and P.attrs:GetAttribute(ATTR.State) == "running" and P.attrs:GetAttribute(ATTR.Cap) == nil
			and string.find(msgParty, "tickets per player", 1, true) == nil,
		"it is one global record in its own mode, running here at once, with no ticket cap", msgParty)
	P.roots[carol] = Vector3.new(30, 3.9, 0)
	step(P, tP + 20)
	local opened = nil
	for _, m in ipairs(P.sent) do
		if m.action == M.Events.Opened then
			opened = m.payload
		end
	end
	check(#P.mini.State().tickets == 0 and unclaimedRecords(P) == 0 and count(P, M.Events.Collected) == 0
			and count(P, M.Events.Refused) == 0 and carol:GetAttribute(ATTR.PlayerTickets) == nil
			and P.data.profiles[carol].WheelEarned == 0,
		"20 s in, with somebody standing on every spot a ticket could fall: not one dropped, collected or counted")
	check(count(P, M.Events.Opened) == 1 and opened and opened.mode == "party",
		"its opening notice goes out once, naming its own mode (the client shows DISCO PARTY!)")
	local recNow = json(store.value)
	local okDup2 = P.mini.StartGlobal(adminB, "ticketdisco", 90)
	check(not okDup2 and json(store.value).rev == recNow.rev and json(store.value).mode == "party",
		"while it runs, a START of any mode is refused and changes nothing")
	P.mini.EndGlobal(adminA)
	check(P.attrs:GetAttribute(ATTR.State) == "ending", "END closes it (the movement factor reads only \"running\")")
	step(P, now + M.FadeSeconds + 0.2)
	check(P.mini.State() == nil and P.attrs:GetAttribute(ATTR.Mode) == nil, "and after the fade it is gone")

	--==========================================================================
	say("12. The owner's ticket budget (2026-10-04): 30 s on the ground, 20 at most, still 3 per player")
	--==========================================================================
	-- A TICKET SHOWER ONLY that nobody collects, on the real service, for
	-- 75 s: how long one ticket lies, and how many lie at once.
	local Q = newServer("ServerQ")
	Q.mini.Poll()
	now += 5
	for i = 1, 80 do
		table.insert(Q.spots, Vector3.new(30 + (i % 10) * 6, 0.9, (i // 10) * 6))
	end
	local tQ = now
	local okQ = Q.mini.StartGlobal(adminA, "tickets", 120)
	local firstSeen, firstGoneAt, maxLying = nil, nil, 0
	while now < tQ + 75 do
		now += 0.1
		Q.mini.Step(now)
		Q.mini.CheckPickups(now)
		local s = Q.mini.State()
		local list = if s then s.tickets else {}
		maxLying = math.max(maxLying, #list)
		if not firstSeen and list[1] then
			firstSeen = list[1]
		end
		if firstSeen and not firstGoneAt then
			local still = false
			for _, t in ipairs(list) do
				if t.id == firstSeen.id then
					still = true
				end
			end
			if not still then
				firstGoneAt = now
			end
		end
	end
	local life = if firstSeen then firstSeen.expiresAt - (firstSeen.landsAt - T.FallSeconds) else 0
	local late = if firstSeen and firstGoneAt then firstGoneAt - firstSeen.expiresAt else -1
	check(okQ and T.PerPlayerCap == 3 and firstSeen ~= nil and math.abs(life - 30) < 1e-6
			and late >= -1e-6 and late <= 0.2,
		"a ticket nobody takes lies for exactly 30 s from its drop, then goes; the cap is still 3",
		string.format("life %.2f s, gone %.2f s after its expiry", life, late))
	check(maxLying <= T.MaxUnclaimed and maxLying > 12,
		string.format("at most %d lie at once (seen %d with nobody collecting: more than the old 12, and the drop "
			.. "rate rather than the ceiling sets the usual count)", T.MaxUnclaimed, maxLying), maxLying)
	Q.mini.EndGlobal(adminA)
	step(Q, now + M.FadeSeconds + 0.2)
	check(Q.mini.State() == nil and unclaimedRecords(Q) == 0, "END clears every one of them")
end)

for _, S in ipairs(servers) do
	pcall(function()
		S.mini.Reset()
	end)
end
fixture:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nMiniEventSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
