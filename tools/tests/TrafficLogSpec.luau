--!nocheck
--==============================================================================
-- Steal a Seed :: TrafficLogSpec
--
-- The external new-player traffic feed (TrafficLogService, 2026-09-28) against
-- a FAKE SENDER: nothing here makes an HTTP request, and nothing here can --
-- the real sender is never installed. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("TrafficLogSpec"))
--
-- Proves, with the real module, stand-in players, a fake clock and a scripted
-- sender:
--   1. a new persistent profile sends exactly one join and one ending, paired
--   2. returning, staff, Studio and temporary profiles send nothing
--   3. leaving while the profile loads sends nothing
--   4. repeated lifecycle calls send nothing twice
--   5. simultaneous players stay separate; concurrency holds its limit
--   6. a retry resends the same bytes, the same eventId, after backoff
--   7. timeout / 429 / 5xx retry; 4xx is dropped; HTTP off or no secret halts
--   8. the queue, the attempts and the warnings are bounded
--   9. shutdown and PlayerRemoving never both end a session; the flush is bounded
--  10. launch data: only allowlisted tags, anything else "unknown"
--  11. timestamps and durations
--  12. nothing reaches gameplay or native analytics
--  13. disabled means zero requests; the URL stays server-only
--
-- NOT HERE: a real delivery to Make. That is the live check in
-- KB/TRAFFIC_LOG.md, and waits for the owner's authorisation.
--==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local TrafficLogConfig = require(Server:WaitForChild("TrafficLogConfig"))
local TL = require(Server:WaitForChild("TrafficLogService"))

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
-- THE FAKE SENDER, A CLOCK, AND STAND-IN PLAYERS
--==============================================================================
-- `plan` scripts the next responses in order (empty = 200): a number is a
-- status, { status, retryAfter } adds a Retry-After, a string is thrown as the
-- error, and "hold" parks the request until release().
local calls = {}
local routes = {}
local plan = {}
local held = {}
local warns = {}
local staff = {}

local function sender(body, eventType)
	table.insert(calls, body)
	table.insert(routes, eventType)
	local step = table.remove(plan, 1)
	if step == nil then
		return 200
	elseif step == "hold" then
		table.insert(held, coroutine.running())
		return coroutine.yield()
	elseif type(step) == "string" then
		error(step, 0)
	elseif type(step) == "table" then
		return step[1], step[2]
	end
	return step
end

local function release(status)
	local list = table.clone(held)
	table.clear(held)
	for _, thread in ipairs(list) do
		task.spawn(thread, status or 200)
	end
end

local T0 = 1790500000000 -- a fixed UTC instant, in milliseconds
local now, utc = 1000, T0
local function advance(seconds)
	now += seconds
	utc += math.floor(seconds * 1000 + 0.5)
end

local function fresh(config)
	release(200)
	table.clear(calls)
	table.clear(routes)
	table.clear(plan)
	table.clear(warns)
	table.clear(staff)
	now, utc = 1000, T0
	TL.reset()
	TL.useAutoPump(false)
	TL.useSender(sender)
	TL.useStudio(false)
	TL.useClock(function()
		return now
	end)
	TL.useUtc(function()
		return utc
	end)
	TL.useStaffCheck(function(p)
		return staff[p] == true
	end)
	TL.useJoinData(function(p)
		if p.joinThrows then
			error("GetJoinData failed")
		end
		return p.joinData
	end)
	TL.useWarn(function(line)
		table.insert(warns, line)
	end)
	local base = { Enabled = true, CampaignTags = { "spring_ads", "YT-Short" }, QueueCapacity = 64,
		MaxConcurrent = 2, MaxAttempts = 5, BackoffSeconds = 2, MaxBackoffSeconds = 60, Jitter = 0,
		DiagnosticSeconds = 60 }
	for k, v in pairs(config or {}) do
		base[k] = v
	end
	TL.configure(base)
end

local serial = 0
local function player(launchData)
	serial += 1
	return { Name = "TrafficNewbie" .. serial, UserId = 987654320 + serial, AccountAge = 0,
		Parent = Players, joinData = if launchData ~= nil then { LaunchData = launchData } else nil }
end

local function leave(p)
	p.Parent = nil
	TL.left(p)
end

local function decode(body)
	return HttpService:JSONDecode(body)
end

-- Every distinct event sent (retries collapse onto their eventId), in order.
local function events()
	local seen, list = {}, {}
	for _, body in ipairs(calls) do
		local e = decode(body)
		if not seen[e.eventId] then
			seen[e.eventId] = true
			table.insert(list, e)
		end
	end
	return list
end

local function ofType(eventType)
	local list = {}
	for _, e in ipairs(events()) do
		if e.eventType == eventType then
			table.insert(list, e)
		end
	end
	return list
end

local function iso(ms)
	return DateTime.fromUnixTimestampMillis(ms):ToIsoDate()
end

local GUID = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"
local JOIN_KEYS = { "schemaVersion", "eventType", "eventId", "sessionId", "occurredAtUtc",
	"sessionStartedAtUtc", "placeVersion", "campaignTag" }

local function keysAre(e, extra)
	local want = {}
	for _, k in ipairs(JOIN_KEYS) do
		want[k] = true
	end
	if extra then
		want[extra] = true
	end
	for k in pairs(e) do
		if not want[k] then
			return false, "unexpected key " .. k
		end
	end
	for k in pairs(want) do
		if e[k] == nil then
			return false, "missing key " .. k
		end
	end
	return true
end

local J, E = TL.Events.Joined, TL.Events.Ended

local ok, err = pcall(function()

--==============================================================================
-- 1. A NEW PERSISTENT PROFILE: ONE JOIN, ONE ENDING, PAIRED
--==============================================================================
say("-- the pair --")
fresh()
local p = player(nil)
TL.arrived(p)
advance(3)
TL.classified(p, true, true)
check(#calls == 0 and TL.health().pending == 1, "the join is queued the moment the profile qualifies",
	#calls)
TL.pump()
local joins = ofType(J)
check(#calls == 1 and #joins == 1, "and sent on the next pump", #calls)
local join = joins[1]
check(join and keysAre(join), "the join carries exactly the contract's eight fields",
	join and select(2, keysAre(join)))
check(join and join.schemaVersion == 1 and join.eventType == "new_player_joined"
	and string.match(join.eventId, GUID) and string.match(join.sessionId, GUID)
	and join.eventId ~= join.sessionId, "schema 1, the join's name, a GUID eventId and sessionId")
check(join and join.sessionStartedAtUtc == iso(T0) and join.occurredAtUtc == iso(T0 + 3000),
	"started at PlayerAdded, occurred when the profile confirmed it",
	join and (join.sessionStartedAtUtc .. " / " .. join.occurredAtUtc))
check(join and join.placeVersion == game.PlaceVersion and join.campaignTag == "unknown",
	"the place version, and no launch data reads as \"unknown\"", join and join.campaignTag)
advance(125.4)
leave(p)
TL.pump()
local ends = ofType(E)
local ending = ends[1]
check(#calls == 2 and #ends == 1, "leaving sends exactly one ending", #calls)
check(routes[1] == J and routes[2] == E,
	"the join and ending use their separate webhook routes", table.concat(routes, ", "))
check(ending and keysAre(ending, "sessionDurationSeconds"), "the ending adds only sessionDurationSeconds",
	ending and select(2, keysAre(ending, "sessionDurationSeconds")))
check(ending and ending.sessionId == join.sessionId and ending.eventId ~= join.eventId
	and string.match(ending.eventId, GUID), "the same sessionId pairs them; each event has its own eventId")
check(ending and ending.sessionDurationSeconds == 128 and ending.occurredAtUtc == iso(T0 + 128400)
	and ending.sessionStartedAtUtc == iso(T0),
	"the ending measures from the recorded arrival: 3 s + 125.4 s -> 128 s",
	ending and ending.sessionDurationSeconds)
local personal = false
for _, body in ipairs(calls) do
	local lower = string.lower(body)
	if string.find(body, "TrafficNewbie", 1, true) or string.find(body, tostring(p.UserId), 1, true)
		or string.find(lower, "userid", 1, true) or string.find(lower, "accountage", 1, true) then
		personal = true
	end
end
check(not personal, "no name, UserId or account age in either body")
local h = TL.health()
check(h.delivered == 2 and h.pending == 0 and h.sessions == 0, "both delivered; nothing left open",
	string.format("%d/%d/%d", h.delivered, h.pending, h.sessions))

--==============================================================================
-- 2. EXCLUSIONS
--==============================================================================
say("\n-- exclusions --")
fresh()
local returning = player(nil)
TL.arrived(returning)
TL.classified(returning, false, true)
leave(returning)
TL.pump()
check(#calls == 0, "a returning profile (\"ok\") sends nothing, joining or leaving", #calls)

fresh()
local temp = player(nil)
TL.arrived(temp)
TL.classified(temp, false, false)
leave(temp)
local temp2 = player(nil)
TL.arrived(temp2)
TL.classified(temp2, true, false)
leave(temp2)
TL.pump()
check(#calls == 0, "a temporary (non-saving) profile sends nothing, even if marked new", #calls)

fresh()
local admin = player(nil)
staff[admin] = true
TL.arrived(admin)
TL.classified(admin, true, true)
leave(admin)
TL.pump()
check(#calls == 0, "staff send nothing, even on a brand-new save", #calls)

fresh()
TL.useStaffCheck(nil) -- the real check: AdminService's allowlist
local realAdmin = player(nil)
realAdmin.UserId = 11607308004
local realPlayer = player(nil)
TL.arrived(realAdmin)
TL.arrived(realPlayer)
TL.classified(realAdmin, true, true)
TL.classified(realPlayer, true, true)
TL.pump()
check(#calls == 1, "through AdminService itself: the allowlisted account is left out, the other counted",
	#calls)

fresh()
TL.useStudio(true)
local studio = player(nil)
TL.arrived(studio)
TL.classified(studio, true, true)
leave(studio)
TL.shutdown(0)
TL.pump()
check(#calls == 0 and TL.health().sessions == 0 and TL.health().active == false,
	"Studio: no session is even opened, nothing is sent", #calls)

--==============================================================================
-- 3. LEAVING WHILE THE PROFILE LOADS
--==============================================================================
say("\n-- leaving during the load --")
fresh()
local quick = player(nil)
TL.arrived(quick)
advance(4)
leave(quick)
TL.classified(quick, true, true)
TL.pump()
check(#calls == 0 and TL.health().sessions == 0, "gone before the verdict: no join, no ending, no session",
	#calls)
fresh()
local racing = player(nil)
TL.arrived(racing)
TL.left(racing) -- PlayerRemoving ran while the Player still sat under Players
TL.classified(racing, true, true)
TL.pump()
check(#calls == 0 and TL.health().sessions == 0,
	"a verdict landing after PlayerRemoving (Parent not yet cleared) is still ignored", #calls)
fresh()
local neverArrived = player(nil)
leave(neverArrived)
TL.pump()
check(#calls == 0, "leaving with no session at all sends nothing", #calls)

--==============================================================================
-- 4. REPEATED LIFECYCLE CALLS
--==============================================================================
say("\n-- duplicates --")
fresh()
local twice = player(nil)
TL.arrived(twice)
advance(5)
TL.arrived(twice)
TL.classified(twice, true, true)
TL.classified(twice, true, true)
advance(10)
leave(twice)
TL.left(twice)
TL.shutdown(0)
TL.pump()
check(#ofType(J) == 1 and #ofType(E) == 1 and #calls == 2,
	"PlayerAdded x2, the verdict x2, PlayerRemoving x2 and a shutdown: one join, one ending", #calls)
check(ofType(J)[1].sessionStartedAtUtc == iso(T0) and ofType(E)[1].sessionDurationSeconds == 15,
	"the FIRST arrival is the start", ofType(E)[1].sessionDurationSeconds)
check(TL.health().duplicates >= 2, "the repeats are counted as duplicates", TL.health().duplicates)
fresh()
local lazy = player(nil)
advance(2)
TL.classified(lazy, true, true)
TL.pump()
check(#ofType(J) == 1 and ofType(J)[1].sessionStartedAtUtc == iso(T0 + 2000),
	"a verdict with no PlayerAdded seen opens the session there (the start is then that moment)")

--==============================================================================
-- 5. SIMULTANEOUS PLAYERS; THE CONCURRENCY LIMIT
--==============================================================================
say("\n-- many players --")
fresh()
local a, b, c, r, s = player(nil), player(nil), player(nil), player(nil), player(nil)
staff[s] = true
TL.arrived(a)
advance(1)
TL.arrived(b)
TL.arrived(r)
advance(1)
TL.arrived(c)
TL.arrived(s)
TL.classified(b, true, true)
TL.classified(r, false, true)
TL.classified(s, true, true)
TL.classified(a, true, true)
advance(1)
TL.classified(c, true, true)
plan = { "hold", "hold", "hold" }
TL.pump()
check(#calls == 2 and TL.health().inFlight == 2, "three joins due, MaxConcurrent 2: two requests in flight",
	#calls)
TL.pump()
check(#calls == 2, "a second pass starts nothing while both are still in flight", #calls)
release(200)
TL.pump()
check(#calls == 3 and TL.health().inFlight == 1, "a slot frees, the third goes", #calls)
release(200)
check(TL.health().delivered == 3 and TL.health().pending == 0, "all three joins delivered")
advance(20)
leave(c)
advance(5)
leave(a)
leave(r)
leave(s)
advance(5)
leave(b)
TL.pump()
TL.pump()
local sessionsSeen, paired = {}, true
for _, j in ipairs(ofType(J)) do
	sessionsSeen[j.sessionId] = j
end
local durations = {}
for _, e in ipairs(ofType(E)) do
	if not sessionsSeen[e.sessionId] then
		paired = false
	end
	durations[e.sessionId] = e.sessionDurationSeconds
end
local distinct = 0
for _ in pairs(sessionsSeen) do
	distinct += 1
end
check(#ofType(J) == 3 and #ofType(E) == 3 and distinct == 3 and paired,
	"three new players: three distinct sessions, each ending pairs with its own join", #ofType(E))
local byStart = {}
for id, j in pairs(sessionsSeen) do
	byStart[j.sessionStartedAtUtc] = durations[id]
end
check(byStart[iso(T0)] == 28 and byStart[iso(T0 + 1000)] == 32 and byStart[iso(T0 + 2000)] == 21,
	"each duration runs from that player's own arrival (a 28 s, b 32 s, c 21 s)",
	string.format("%s/%s/%s", tostring(byStart[iso(T0)]), tostring(byStart[iso(T0 + 1000)]),
		tostring(byStart[iso(T0 + 2000)])))

--==============================================================================
-- 6. A RETRY IS THE SAME EVENT
--==============================================================================
say("\n-- retries --")
fresh()
local retried = player(nil)
TL.arrived(retried)
TL.classified(retried, true, true)
plan = { 503 }
TL.pump()
check(#calls == 1 and TL.health().pending == 1 and TL.health().retries == 1, "a 503 keeps the event queued")
TL.pump()
check(#calls == 1, "not retried before its backoff", #calls)
advance(2)
TL.pump()
check(#calls == 2 and calls[1] == calls[2] and decode(calls[2]).eventId == decode(calls[1]).eventId,
	"the retry sends byte-identical JSON: the same eventId", #calls)
check(TL.health().delivered == 1 and TL.health().pending == 0, "and is delivered once it succeeds")

fresh()
local doubling = player(nil)
TL.arrived(doubling)
TL.classified(doubling, true, true)
plan = { 500, 500, 500 }
TL.pump() -- fails; next try in 2 s
advance(2)
TL.pump() -- fails; next try in 4 s
advance(3.5)
TL.pump()
local before = #calls
advance(0.5)
TL.pump() -- due now
check(before == 2 and #calls == 3, "backoff doubles: 2 s, then 4 s", string.format("%d then %d", before, #calls))

--==============================================================================
-- 7. FAILURE KINDS
--==============================================================================
say("\n-- failures --")
local function oneEvent(config)
	fresh(config)
	local q = player(nil)
	TL.arrived(q)
	TL.classified(q, true, true)
	return q
end

oneEvent()
plan = { "HttpError: Timedout" }
TL.pump()
check(TL.health().pending == 1 and TL.health().retries == 1, "a timeout (thrown) is retried")
check(#warns == 1 and string.find(warns[1], "timeout", 1, true) ~= nil
	and not string.find(warns[1], "Timedout", 1, true), "reported as the word \"timeout\", not the raw error",
	warns[1])
advance(2)
TL.pump()
check(TL.health().delivered == 1, "and delivered on the retry")

oneEvent()
plan = { { 429, 30 } }
TL.pump()
advance(29)
TL.pump()
local early = #calls
advance(1)
TL.pump()
check(early == 1 and #calls == 2 and TL.health().delivered == 1,
	"429 with Retry-After 30: waits the 30 s it asked for, not the 2 s backoff", early)

oneEvent()
plan = { { 503, 999 } }
TL.pump()
advance(59)
TL.pump()
local capped = #calls
advance(1)
TL.pump()
check(capped == 1 and #calls == 2, "a Retry-After past MaxBackoffSeconds is capped at 60 s", capped)

for _, code in ipairs({ 408, 500, 502, 504 }) do
	oneEvent()
	plan = { code }
	TL.pump()
	advance(2)
	TL.pump()
	check(#calls == 2 and TL.health().delivered == 1, "HTTP " .. code .. " is transient: retried", #calls)
end

for _, code in ipairs({ 400, 401, 403, 404, 410, 413 }) do
	oneEvent()
	plan = { code }
	TL.pump()
	advance(120)
	TL.pump()
	check(#calls == 1 and TL.health().droppedRejected == 1 and TL.health().pending == 0,
		"HTTP " .. code .. " is a permanent refusal: dropped, never retried", #calls)
end

oneEvent()
plan = { "Http requests are not enabled. Enable via game settings" }
local extra = player(nil)
TL.arrived(extra)
TL.classified(extra, true, true)
TL.pump()
check(TL.health().halted == "http-disabled" and TL.health().pending == 0 and TL.health().droppedHalted == 2,
	"HTTP requests switched off: sending halts for this server, the queue is dropped",
	tostring(TL.health().halted))
local haltedAt = #calls
local later = player(nil)
TL.arrived(later)
TL.classified(later, true, true)
leave(extra)
TL.pump()
check(#calls == haltedAt and haltedAt == 1 and TL.health().active == false,
	"and nothing more is tracked or sent", #calls)

oneEvent()
plan = { "Can't find secret with given key" }
TL.pump()
check(TL.health().halted == "secret-missing", "no secret configured: halts the same way",
	tostring(TL.health().halted))

--==============================================================================
-- 8. BOUNDS: THE QUEUE, THE ATTEMPTS, THE WARNINGS
--==============================================================================
say("\n-- bounds --")
fresh({ QueueCapacity = 3 })
for _ = 1, 5 do
	local n = player(nil)
	TL.arrived(n)
	TL.classified(n, true, true)
end
check(TL.health().pending == 3 and TL.health().droppedFull == 2, "a full queue drops the newest (3 kept, 2 dropped)",
	string.format("%d/%d", TL.health().pending, TL.health().droppedFull))
check(#warns == 1, "two drops, one warning (rate-limited)", #warns)
TL.pump()
TL.pump()
check(TL.health().delivered == 3, "the kept three still go")

fresh({ MaxAttempts = 3 })
local doomed = player(nil)
TL.arrived(doomed)
TL.classified(doomed, true, true)
plan = { 500, 500, 500, 500 }
for _ = 1, 6 do
	TL.pump()
	advance(61)
end
check(#calls == 3 and TL.health().droppedExhausted == 1 and TL.health().pending == 0,
	"retries exhausted after MaxAttempts (3): dropped, never tried again", #calls)

fresh()
for _ = 1, 4 do
	local n = player(nil)
	TL.arrived(n)
	TL.classified(n, true, true)
end
plan = { 503, 503, 503, 503 }
TL.pump()
TL.pump()
check(#warns == 1, "four failures inside a minute: one \"retrying\" warning", #warns)
advance(61)
plan = { 503 }
TL.pump()
local lastWarn = warns[#warns] or ""
check(#warns == 2 and string.find(lastWarn, "+3 more", 1, true) ~= nil,
	"a minute later one more, carrying the count it held back", lastWarn)
local leaky = false
for _, line in ipairs(warns) do
	if string.find(line, "://", 1, true) or string.find(line, "{", 1, true)
		or string.match(line, "%x%x%x%x%x%x%x%x%-%x%x%x%x") then
		leaky = true
	end
end
check(not leaky, "no warning carries a URL, a body or an id")

--==============================================================================
-- 9. SHUTDOWN AND PLAYERREMOVING
--==============================================================================
say("\n-- shutdown --")
fresh()
local s1, s2 = player(nil), player(nil)
TL.arrived(s1)
TL.arrived(s2)
TL.classified(s1, true, true)
TL.classified(s2, true, true)
TL.pump()
advance(40)
TL.left(s1) -- PlayerRemoving before BindToClose
TL.shutdown(0.5) -- ends s2 and flushes
TL.left(s2) -- PlayerRemoving after BindToClose
TL.left(s1)
TL.pump()
local shutEnds = ofType(E)
check(#shutEnds == 2 and shutEnds[1].sessionId ~= shutEnds[2].sessionId and TL.health().pending == 0,
	"shutdown and PlayerRemoving overlapping in any order: one ending per session, flushed", #shutEnds)
check(shutEnds[1] and shutEnds[2] and shutEnds[1].sessionDurationSeconds == 40
	and shutEnds[2].sessionDurationSeconds == 40, "the shutdown's ending has the real elapsed time too")

fresh()
local waiting = player(nil)
TL.arrived(waiting)
TL.classified(waiting, true, true)
plan = { 503 }
TL.pump()
advance(0.5)
TL.shutdown(0.5)
check(#calls == 3 and TL.health().delivered == 2 and TL.health().pending == 0,
	"the flush gives a backing-off event its last try at once, alongside the ending", #calls)

fresh()
local stuck = player(nil)
TL.arrived(stuck)
TL.classified(stuck, true, true)
plan = { "hold", "hold", "hold" }
local t0 = os.clock()
TL.shutdown(0.25)
local took = os.clock() - t0
check(took < 1 and TL.health().pending > 0, string.format(
	"a webhook that never answers cannot hold shutdown: returned in %.2f s", took), took)
release(200)

--==============================================================================
-- 10. LAUNCH DATA
--==============================================================================
say("\n-- launch data --")
local function tagFor(launchData, throws, config)
	fresh(config)
	local q = player(launchData)
	q.joinThrows = throws
	TL.arrived(q)
	TL.classified(q, true, true)
	TL.pump()
	local j = ofType(J)[1]
	return j and j.campaignTag, calls[1] or ""
end
check(tagFor("spring_ads") == "spring_ads", "an allowlisted tag is forwarded")
check(tagFor("  Spring_Ads \n") == "spring_ads", "matched ignoring case and surrounding spaces")
check(tagFor("yt-short") == "yt-short", "an allowlist entry written in capitals still matches")
local tag, body = tagFor("summer_ads")
check(tag == "unknown" and not string.find(body, "summer", 1, true),
	"an unrecognised value is \"unknown\" and is not forwarded", tag)
check(tagFor(nil) == "unknown", "no launch data: \"unknown\" (not \"organic\")")
check(tagFor("") == "unknown", "empty launch data: \"unknown\"")
check(tagFor(42) == "unknown", "a non-string: \"unknown\"")
check(tagFor(string.rep("a", 300)) == "unknown", "300 characters: \"unknown\"")
local tag2, body2 = tagFor("{\"campaign\":\"spring_ads\"}")
check(tag2 == "unknown" and not string.find(body2, "spring_ads", 1, true),
	"JSON launch data: \"unknown\", never parsed or forwarded", tag2)
check(tagFor("spring_ads", true) == "unknown", "GetJoinData throwing: \"unknown\", and the join still goes")
check(tagFor("bad tag!", false, { CampaignTags = { "bad tag!" } }) == "unknown",
	"a malformed allowlist entry is ignored")
check(tagFor("unknown", false, { CampaignTags = { "unknown" } }) == "unknown", "\"unknown\" cannot be a tag")
check(tagFor("spring_ads", false, { CampaignTags = {} }) == "unknown", "an empty allowlist (the default) tags nothing")
fresh()
local tagged = player("spring_ads")
TL.arrived(tagged)
tagged.joinData = { LaunchData = "changed_later" }
TL.classified(tagged, true, true)
leave(tagged)
TL.pump()
check(ofType(J)[1].campaignTag == "spring_ads" and ofType(E)[1].campaignTag == "spring_ads",
	"the tag is read once, at arrival, and both events carry it")

--==============================================================================
-- 11. TIMESTAMPS AND DURATIONS
--==============================================================================
say("\n-- time --")
fresh()
local instant = player(nil)
TL.arrived(instant)
TL.classified(instant, true, true)
leave(instant)
TL.pump()
check(ofType(E)[1].sessionDurationSeconds == 0, "leaving in the same instant: 0 s")
fresh()
local backwards = player(nil)
TL.arrived(backwards)
TL.classified(backwards, true, true)
now -= 30
leave(backwards)
TL.pump()
check(ofType(E)[1].sessionDurationSeconds == 0, "a clock that went backwards: 0 s, never negative",
	ofType(E)[1].sessionDurationSeconds)
fresh()
TL.useUtc(nil)
local real = player(nil)
TL.arrived(real)
TL.classified(real, true, true)
TL.pump()
local stamp = ofType(J)[1].occurredAtUtc
check(string.match(stamp, "^%d%d%d%d%-%d%d%-%d%dT%d%d:%d%d:%d%d") ~= nil and string.sub(stamp, -1) == "Z"
	and tonumber(string.sub(stamp, 1, 4)) >= 2026, "real timestamps are ISO 8601 UTC (" .. stamp .. ")", stamp)
check(ofType(J)[1].sessionStartedAtUtc <= stamp, "and the start is never after the join")

--==============================================================================
-- 12. NOTHING REACHES GAMEPLAY OR NATIVE ANALYTICS
--==============================================================================
say("\n-- isolation --")
fresh()
plan = { "hold" }
local caller = player(nil)
local lifecycle = coroutine.create(function()
	TL.arrived(caller)
	TL.classified(caller, true, true)
	TL.pump()
	leave(caller)
	TL.pump()
end)
coroutine.resume(lifecycle)
check(coroutine.status(lifecycle) == "dead" and #held == 1,
	"every lifecycle call returns at once while a request hangs (it runs on its own thread)",
	coroutine.status(lifecycle))
release(200)
fresh()
TL.useSender(function()
	error("anything at all")
end)
local survived = pcall(function()
	local q = player(nil)
	TL.arrived(q)
	TL.classified(q, true, true)
	TL.pump()
	leave(q)
	TL.pump()
	TL.shutdown(0)
	TL.arrived(nil)
	TL.classified(nil, true, true)
	TL.left("not a player")
	TL.classified(12, "yes", {})
end)
check(survived, "a throwing sender and nonsense arguments never reach the caller")

local function src(inst)
	local okSrc, text = pcall(function()
		return inst.Source
	end)
	return if okSrc then text else ""
end
local own = src(Server:FindFirstChild("TrafficLogService"))
local pds = src(Server:FindFirstChild("PlayerDataService"))
local metrics = src(Server:FindFirstChild("Metrics"))
check(#own > 0 and #pds > 0 and #metrics > 0, "the real sources are readable")
local hookAt = string.find(pds, "pcall((TrafficLog :: any).classified, player, status == \"new\", persistent)", 1, true)
local metricsAt = string.find(pds, "Metrics.profileReady(player, profile, status == \"new\", persistent)", 1, true)
check(hookAt ~= nil and metricsAt ~= nil and metricsAt < hookAt and hookAt - metricsAt < 400,
	"PlayerDataService tells the feed right after Metrics, with the same verdict, inside pcall")
check(string.find(pds, "pcall(require, script.Parent:WaitForChild(\"TrafficLogService\"))", 1, true) ~= nil,
	"and requires it inside pcall: a broken logger cannot stop a join")
local _, bare = string.gsub(pds, "TrafficLog[%.:]", "")
local _, fenced = string.gsub(pds, "%(TrafficLog :: any%)", "")
check(bare == 0 and fenced == 1, "that is its only call in PlayerDataService", bare .. "/" .. fenced)
check(not string.find(metrics, "TrafficLog", 1, true), "Metrics (native analytics) is untouched by it")
local reachesOut = false
for _, word in ipairs({ "SetAttribute", "FireClient", "FireAllClients", "RemoteEvent", "RemoteFunction",
	"DataStore", "AnalyticsService", "EconomyService", "PlayerDataService\")", "WheelService", "ObbyService",
	"AddCash", "Kick(" }) do
	if string.find(own, word, 1, true) then
		reachesOut = true
		say("      reaches: " .. word)
	end
end
check(not reachesOut, "the feed writes no attribute, remote, DataStore or analytics call, and touches no gameplay service")

--==============================================================================
-- 13. AN EXPLICIT OFF SWITCH AND STUDIO SEND ZERO; URLS STAY SERVER-ONLY
--==============================================================================
say("\n-- switch, Studio and secrets --")
check(TrafficLogConfig.Enabled == true, "the shipped TrafficLogConfig is enabled for the next publish")
check(type(TrafficLogConfig.CampaignTags) == "table" and #TrafficLogConfig.CampaignTags == 0,
	"and ships with an empty campaign allowlist")
fresh({ Enabled = false })
for _ = 1, 3 do
	local q = player("spring_ads")
	TL.arrived(q)
	TL.classified(q, true, true)
	advance(30)
	leave(q)
end
TL.pump()
TL.shutdown(0)
TL.pump()
local hd = TL.health()
check(#calls == 0 and hd.requests == 0 and hd.queued == 0 and hd.sessions == 0 and hd.active == false,
	"switched off: a full lifecycle for three new players makes zero requests and opens nothing", #calls)
fresh()
TL.configure(nil) -- shipped config, still with the fake sender
TL.useStudio(true)
local shipped = player(nil)
TL.arrived(shipped)
TL.classified(shipped, true, true)
leave(shipped)
TL.pump()
check(#calls == 0 and TL.health().active == false, "Studio sends zero requests even with the shipped switch on", #calls)
TL.useStudio(false)
local liveMock = player(nil)
TL.arrived(liveMock)
TL.classified(liveMock, true, true)
leave(liveMock)
TL.pump()
check(#calls == 2 and routes[1] == J and routes[2] == E,
	"the shipped switch routes both events through the fake sender off Studio", #calls)

local _, requestAt = string.gsub(own, ":RequestAsync%(", "")
local _, secretAt = string.gsub(own, ":GetSecret%(", "")
check(requestAt == 1 and secretAt == 1 and not string.find(own, "PostAsync", 1, true)
	and not string.find(own, "GetAsync", 1, true), "one RequestAsync and one GetSecret: the live sender only",
	requestAt .. "/" .. secretAt)
local configSrc = src(Server:FindFirstChild("TrafficLogConfig"))
check(string.find(configSrc, "PodnappersTrafficJoinWebhook", 1, true)
	and string.find(configSrc, "PodnappersTrafficDurationWebhook", 1, true)
	and not string.find(configSrc, "\n\tSecretName =", 1, true),
	"the shipped config names separate join and duration secrets")
check(#configSrc > 0 and not string.find(own, "://", 1, true) and not string.find(configSrc, "://", 1, true)
	and not string.find(string.lower(configSrc), "make.com/", 1, true),
	"no URL or endpoint is written into either file")
check(Server:FindFirstChild("TrafficLogConfig"):IsDescendantOf(ServerScriptService)
	and rawget(GameConfig, "TrafficLog") == nil and rawget(GameConfig, "Traffic") == nil,
	"the settings live in ServerScriptService (never replicated), not in GameConfig")
local clientMentions = {}
for _, root in ipairs({ ReplicatedStorage, game:GetService("StarterPlayer"), game:GetService("StarterGui"),
	game:GetService("ReplicatedFirst") }) do
	for _, inst in ipairs(root:GetDescendants()) do
		if inst:IsA("LuaSourceContainer") and string.find(src(inst), "TrafficLog", 1, true) then
			table.insert(clientMentions, inst:GetFullName())
		end
	end
end
check(#clientMentions == 0, "no client-visible script mentions the feed", table.concat(clientMentions, ", "))

end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
release(200)
TL.useSender(nil)
TL.configure(nil)
TL.useStaffCheck(nil)
TL.useStudio(nil)
TL.useJoinData(nil)
TL.useWarn(nil)
TL.useClock(nil)
TL.useUtc(nil)
TL.useAutoPump(true)
TL.reset()

say(string.format("\nTrafficLogSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
