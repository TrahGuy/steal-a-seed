--!nocheck
--==============================================================================
-- Steal a Seed :: EventsPanelSpec (2026-10-04, the EVENTS panel)
--
-- What the panel says, and where it stands, for every state the owner listed
-- -- several events, none, a failed load and its retry, a reminder cancelled,
-- confirmed or failing, an event starting and ending while open -- driven
-- through the real EventsModel with STAND-IN answers in place of
-- SocialService, on a hand-turned clock. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("EventsPanelSpec"))
--
-- WHAT IT CANNOT DO is ask Roblox: the real list, the RSVP read and the native
-- prompt answer only a live client, and the prompt only a real account. The
-- shapes here are the documented ones (SocialService, 2026-10-04); the live
-- answers are the owner's acceptance check.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EventsModel = require(Shared:WaitForChild("EventsModel"))
local MenuLayout = require(Shared:WaitForChild("MenuLayout"))

local pass, fails = 0, {}
local out = {}
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		table.insert(fails, label)
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

local ok, err = pcall(function()

--==============================================================================
-- 1. THE TIMES: EventsModel.utc against DateTime's own UTC
--==============================================================================
say("-- the times --")
local function t(y, mo, d, h, mi, s, ms)
	return { Year = y, Month = mo, Day = d, Hour = h, Minute = mi, Second = s, Millisecond = ms }
end
local agree = true
local notes = {}
for _, d in ipairs({ t(2026, 10, 4, 12, 30, 15, 250), t(2026, 12, 31, 23, 59, 59, 999), t(2027, 1, 1, 0, 0, 0, 0),
	t(2028, 2, 29, 6, 5, 4, 3), t(2031, 3, 30, 1, 0, 0, 0) }) do
	local mine = EventsModel.utc(d)
	local theirs = DateTime.fromUniversalTime(d.Year, d.Month, d.Day, d.Hour, d.Minute, d.Second, d.Millisecond)
	local back = DateTime.fromUnixTimestampMillis(math.floor(mine * 1000 + 0.5)):ToUniversalTime()
	local same = math.floor(mine * 1000 + 0.5) == theirs.UnixTimestampMillis
		and back.Year == d.Year and back.Month == d.Month and back.Day == d.Day and back.Hour == d.Hour
		and back.Minute == d.Minute and back.Second == d.Second and back.Millisecond == d.Millisecond
	if not same then
		agree = false
		table.insert(notes, string.format("%d-%d-%d", d.Year, d.Month, d.Day))
	end
end
check(agree, "a StartTime / EndTime dictionary is read as UTC: the same instant DateTime.fromUniversalTime gives, "
	.. "and it reads back field for field", table.concat(notes, ", "))
check(EventsModel.utc(t(2026, 2, 29, 0, 0, 0, 0)) == nil and EventsModel.utc(t(2026, 4, 31, 0, 0, 0, 0)) == nil
		and EventsModel.utc(t(2026, 13, 1, 0, 0, 0, 0)) == nil and EventsModel.utc(t(2026, 1, 1, 24, 0, 0, 0)) == nil
		and EventsModel.utc(t(2026, 1, 1, 1.5, 0, 0, 0)) == nil and EventsModel.utc(t(1999, 1, 1, 0, 0, 0, 0)) == nil
		and EventsModel.utc("2026-10-04") == nil and EventsModel.utc(nil) == nil,
	"an impossible date or time is refused, never rolled over into another one")
do
	local c = EventsModel.clock("en-us")
	local at = EventsModel.utc(t(2026, 10, 11, 18, 0, 0, 0))
	local day, time = c.day(at), c.time(at)
	local odd = EventsModel.clock("xx-not-a-locale")
	check(type(day) == "string" and day:find("Oct", 1, true) ~= nil and type(time) == "string" and time ~= ""
			and odd.day(at) ~= "" and odd.time(at) ~= "",
		"times are written in the device's zone and the player's language (a locale DateTime refuses falls back to en-us)",
		tostring(day) .. " / " .. tostring(time))
end

--==============================================================================
-- 2. ONE EVENT, AS ROBLOX SENDS IT
--==============================================================================
say("-- one event --")
local NOW = EventsModel.utc(t(2026, 10, 4, 12, 0, 0, 0))
local function raw(over)
	local r = {
		Id = "4321098765432109876",
		Title = "Plain title", DisplayTitle = "Localized title",
		Subtitle = "Plain sub", DisplaySubtitle = "",
		Description = "Plain words", DisplayDescription = "Localized words",
		ThumbnailIds = { 1234567890 },
		StartTime = t(2026, 10, 5, 18, 0, 0, 0), EndTime = t(2026, 10, 5, 20, 0, 0, 0),
		HasStarted = false, HasEnded = false,
		Status = Enum.ExperienceEventStatus.Active,
		UserRsvpStatus = Enum.RsvpStatus.Going,
	}
	for k, v in pairs(over or {}) do
		if v == "NIL" then
			r[k] = nil
		else
			r[k] = v
		end
	end
	return r
end
local e = EventsModel.normalize(raw(), NOW)
check(e ~= nil and e.id == "4321098765432109876" and type(e.id) == "string",
	"the id stays the string Roblox sent (19 digits: a double would round it)")
check(EventsModel.normalize(raw({ Id = 4321098765432109876 }), NOW) == nil,
	"a numeric id is refused: it would prompt for some other event")
check(e.title == "Localized title" and e.description == "Localized words" and e.subtitle == "Plain sub",
	"the localized Display* text comes first, the plain field where it is empty")
check(e.image == "rbxassetid://1234567890" and EventsModel.normalize(raw({ ThumbnailIds = {} }), NOW).image == nil,
	"the picture is the first ThumbnailIds entry, and none is none (never an invented one)")
check(e.status == "Active" and e.timed, "the status is read off the real enum, and consistent times are trusted")
local skew = EventsModel.normalize(raw({ StartTime = t(2026, 10, 3, 12, 0, 0, 0), EndTime = t(2026, 10, 6, 0, 0, 0, 0) }), NOW)
check(not skew.timed and EventsModel.when(skew, EventsModel.clock("en-us")) == nil
		and EventsModel.phase(skew, NOW + 10 ^ 6) == "upcoming",
	"times that contradict HasStarted are not shown and never move the event on: no time beats a wrong one")

--==============================================================================
-- 3. SEVERAL EVENTS, NONE, AND THE ORDER
--==============================================================================
say("-- the list --")
local L = EventsModel.list({
	raw({ Id = "later", StartTime = t(2026, 10, 9, 0, 0, 0, 0), EndTime = t(2026, 10, 9, 1, 0, 0, 0) }),
	raw({ Id = "soon" }),
	raw({ Id = "soon", Title = "a duplicate" }),
	"not an event",
	raw({ Id = 77 }),
	raw({ Id = "live", HasStarted = true, StartTime = t(2026, 10, 4, 11, 0, 0, 0), EndTime = t(2026, 10, 4, 13, 0, 0, 0) }),
}, NOW)
check(#L == 3 and L[1].id == "live" and L[2].id == "soon" and L[3].id == "later",
	"several events: valid ones only, each once, soonest start first",
	#L .. ": " .. table.concat((function()
		local ids = {}
		for _, x in ipairs(L) do
			table.insert(ids, x.id)
		end
		return ids
	end)(), ","))
check(#EventsModel.list({}, NOW) == 0 and #EventsModel.list(nil, NOW) == 0, "nothing posted: an empty list")

--==============================================================================
-- 4. THE ACTION AND THE BADGE
--==============================================================================
say("-- the button and the badge --")
local function act(phase, rsvp, pending)
	local a = EventsModel.action(phase, rsvp, pending)
	return a.label, a.enabled, a.prompts
end
local l1, e1, p1 = act("upcoming", "unknown", false)
local l2, e2 = act("upcoming", "None", false)
local l3, e3, p3 = act("upcoming", "Going", false)
local l4, e4 = act("upcoming", "None", true)
local l5, e5 = act("upcoming", "Going", true)
check(l1 == "NOTIFY ME" and e1 and p1 and l2 == "NOTIFY ME" and e2 and act("upcoming", "NotGoing", false) == "NOTIFY ME"
		and act("upcoming", "failed", false) == "NOTIFY ME",
	"not subscribed, not known yet, declined or a failed read: NOTIFY ME")
check(l3 == "NOTIFICATIONS ON" and e3 and p3, "a confirmed Going: NOTIFICATIONS ON, and it still opens the prompt to manage it")
check(not e4 and not e5 and l4 == "NOTIFY ME" and l5 == "NOTIFICATIONS ON", "while the prompt is up the button does not press again")
local ll, le, lp = act("live", "Going", false)
local el, ee = act("ended", "Going", false)
local cl, ce = act("closed", "None", false)
check(ll == "LIVE NOW" and not le and not lp, "an event under way: LIVE NOW and no reminder action")
check(not ee and not ce and el == "EVENT ENDED" and cl == "UNAVAILABLE", "ended or cancelled: not actionable")
check(EventsModel.badge(e, "upcoming", NOW) == "STARTS IN 1D 6H" and EventsModel.badge(e, "upcoming", e.startsAt - 30) == "STARTING SOON"
		and EventsModel.badge(skew, "upcoming", NOW) == "UPCOMING"
		and EventsModel.badge(EventsModel.normalize(raw({ Status = Enum.ExperienceEventStatus.Cancelled }), NOW), "closed", NOW) == "CANCELLED",
	"the badge: STARTS IN 1D 6H, STARTING SOON, UPCOMING when the time is not trusted, CANCELLED",
	EventsModel.badge(e, "upcoming", NOW))

--==============================================================================
-- 5. EXPIRY WHILE OPEN: the clock moves a trusted event on
--==============================================================================
say("-- starting and ending while open --")
local s, f = e.startsAt, e.endsAt
check(EventsModel.phase(e, s - 0.001) == "upcoming" and EventsModel.phase(e, s) == "live"
		and EventsModel.phase(e, f - 0.001) == "live" and EventsModel.phase(e, f) == "ended",
	"upcoming until its start, LIVE NOW from it, ended at its end -- read off the clock, no refetch needed")
check(act(EventsModel.phase(e, s), "Going", false) == "LIVE NOW" and not select(2, act(EventsModel.phase(e, f), "Going", false)),
	"so the button turns to LIVE NOW at the start and stops pressing at the end")
check(EventsModel.phase(EventsModel.normalize(raw({ Status = Enum.ExperienceEventStatus.Moderated }), NOW), NOW) == "closed"
		and EventsModel.phase(EventsModel.normalize(raw({ Status = "NIL" }), NOW), NOW) == "closed",
	"a moderated, unpublished or unknown status is closed")

--==============================================================================
-- 6. THE FEED: STAND-IN SocialService ANSWERS ON A HAND-TURNED CLOCK
--==============================================================================
say("-- the feed --")
local queue, timers, clock = {}, {}, NOW
local answers = { list = {}, read = {}, prompt = {} }
local calls = { list = 0, read = 0, prompt = 0 }
local function answer(kind, arg)
	calls[kind] += 1
	local a = table.remove(answers[kind], 1)
	if a == nil then
		error("no stand-in answer for " .. kind)
	end
	if a == "ERR" then
		error("HttpError 500")
	end
	return a
end
local function makeFeed()
	return EventsModel.feed({
		list = function() return answer("list") end,
		read = function(id) return answer("read", id) end,
		prompt = function(id) return answer("prompt", id) end,
		now = function() return clock end,
		delay = function(sec, fn) table.insert(timers, { at = clock + sec, fn = fn }) end,
		spawn = function(fn) table.insert(queue, fn) end,
		config = GameConfig.ExperienceEvents,
	})
end
local function run()
	while #queue > 0 do
		table.remove(queue, 1)()
	end
end
local function advance(sec)
	clock += sec
	local due = {}
	for i = #timers, 1, -1 do
		if timers[i].at <= clock then
			table.insert(due, table.remove(timers, i))
		end
	end
	for _, tm in ipairs(due) do
		tm.fn()
	end
	run()
end
local C = GameConfig.ExperienceEvents

local feed = makeFeed()
answers.list = { { raw({ Id = "a" }), raw({ Id = "b", StartTime = t(2026, 10, 6, 0, 0, 0, 0), EndTime = t(2026, 10, 6, 1, 0, 0, 0) }) } }
check(feed.state() == "idle" and feed.refresh() and feed.state() == "loading" and not feed.refresh(true),
	"opening asks once and shows Loading; a second ask while one is out is not made")
run()
check(feed.state() == "ready" and #feed.events() == 2 and calls.list == 1 and not feed.refresh(),
	"the answer lands; a fresh copy is not asked for again on the next open")
advance(C.CacheSeconds + 1)
answers.list = { "ERR", "ERR", "ERR" }
check(feed.stale() and feed.refresh(), "a stale copy is asked for again on opening")
run()
for _, pause in ipairs(C.RetryDelays) do
	advance(pause)
end
check(calls.list == 2 + C.Retries and not feed.loading() and feed.state() == "ready" and #feed.events() == 2,
	"a failing refresh tries " .. (1 + C.Retries) .. " times in all, then keeps showing the older list", calls.list)
advance(600)
check(calls.list == 2 + C.Retries, "and never tries again on its own: the next open does")

local cold = makeFeed()
answers.list = { "ERR", "ERR", "ERR" }
cold.refresh()
run()
for _, pause in ipairs(C.RetryDelays) do
	advance(pause)
end
check(cold.state() == "failed", "with nothing loaded yet, a failed load is the failed state (RETRY)")
answers.list = { {} }
check(cold.refresh(true), "RETRY asks again")
run()
check(cold.state() == "ready" and #cold.events() == 0, "and an empty answer is the empty state, not an error")

local doomed = makeFeed()
answers.list = { { raw({ Id = "z" }) } }
doomed.refresh()
local heard = 0
doomed.changed(function()
	heard += 1
end)
doomed.destroy()
run()
check(heard == 0 and #doomed.events() == 0, "an answer arriving after the panel is gone is dropped")

say("-- the reminder --")
answers.read = { Enum.RsvpStatus.None }
check(feed.rsvp("a") == "unknown" and feed.readRsvp("a") and feed.rsvp("a") == "reading" and not feed.readRsvp("a"),
	"the status is read once at a time (CHECKING...)")
run()
check(feed.rsvp("a") == "None" and not feed.readRsvp("a"), "None, trusted for RsvpSeconds")
answers.prompt = { Enum.RsvpStatus.None }
check(feed.promptRsvp("a") and feed.pending("a") and not feed.promptRsvp("a"),
	"NOTIFY ME opens the prompt once: a second press while it is up does nothing")
run()
check(feed.rsvp("a") == "None" and not feed.pending("a"), "closed without choosing: still NOTIFY ME, never subscribed")
answers.prompt = { Enum.RsvpStatus.Going }
feed.promptRsvp("a")
run()
check(feed.rsvp("a") == "Going", "confirmed: Roblox's own Going, so NOTIFICATIONS ON")
answers.prompt = { Enum.RsvpStatus.Going }
feed.promptRsvp("a")
run()
check(feed.rsvp("a") == "Going", "closed again without a change: Roblox answers the old status, which is kept")
answers.prompt = { Enum.RsvpStatus.NotGoing }
feed.promptRsvp("a")
run()
check(feed.rsvp("a") == "NotGoing" and act("upcoming", feed.rsvp("a"), false) == "NOTIFY ME",
	"turned off in the prompt: back to NOTIFY ME")
answers.prompt = { "ERR" }
answers.read = { Enum.RsvpStatus.NotGoing }
local before = calls.read
feed.promptRsvp("a")
run()
check(feed.rsvp("a") == "NotGoing" and feed.note("a") ~= nil and calls.read == before + 1,
	"a prompt that errors changes nothing, says so, and reads the status again")
answers.prompt = { "ERR" }
answers.read = { "ERR" }
feed.promptRsvp("b")
run()
check(feed.rsvp("b") == "failed" and act("upcoming", feed.rsvp("b"), false) == "NOTIFY ME",
	"an error with no status known is never shown as subscribed")
local reads = calls.read
check(not feed.readRsvp("b") and calls.read == reads, "and a failed read is not asked again every second")
local race = makeFeed()
answers.read = { Enum.RsvpStatus.Going }
answers.prompt = { Enum.RsvpStatus.NotGoing }
race.readRsvp("q")
race.promptRsvp("q")
run()
check(race.rsvp("q") == "NotGoing", "a read overtaken by the prompt is dropped: the prompt's answer is newer")

--==============================================================================
-- 7. WHERE IT STANDS: desktop, short phones, a portrait phone
--==============================================================================
say("-- the panel's layout --")
local OUTLINE = GameConfig.Rail.OutlineThickness
local shapes = {
	{ "1280x720 desktop", Vector2.new(1280, 662), false, 142, 1280 - 62 },
	{ "1920x1080 desktop", Vector2.new(1920, 1022), false, 142, 1920 - 62 },
	{ "705x338 phone (Studio)", Vector2.new(705, 280), true, 0, 0 },
	{ "640x360 phone", Vector2.new(640, 302), true, 0, 0 },
	{ "772x360 phone", Vector2.new(772, 302), true, 0, 0 },
	{ "844x390 notched", Vector2.new(750, 311), true, 0, 0 },
	{ "801x392 the owner's", Vector2.new(801, 334), true, 0, 0 },
	{ "390x844 portrait", Vector2.new(390, 786), true, 0, 0 },
	{ "700x400 window", Vector2.new(700, 342), true, 0, 0 },
}
local fit, sideOk, notesL = true, true, {}
for _, shape in ipairs(shapes) do
	local p = MenuLayout.eventsPanel({ safe = shape[2], compact = shape[3], railRight = shape[4], rightLeft = shape[5] },
		OUTLINE)
	local m = MenuLayout.blocks(p).main
	local inSafe = p.rect.x >= 0 and p.rect.y >= 0 and p.rect.x + p.rect.w <= shape[2].X and p.rect.y + p.rect.h <= shape[2].Y
	for _, sub in ipairs({ true, false }) do
		local d = MenuLayout.eventDetail(m.w, m.h, sub)
		local a = d.action
		local good = inSafe and a.y >= 0 and a.y + a.h <= m.h and a.x >= 0 and a.x + a.w <= m.w and a.h >= 44 and a.w >= 160
			and d.words.h >= MenuLayout.Events.WordsMin and d.words.y + d.words.h <= a.y
			and (d.banner.h == 0 or math.abs(d.banner.w / d.banner.h - 16 / 9) < 0.02)
			and d.badge.y + d.badge.h <= m.h and d.when.y + d.when.h <= m.h
		if not good then
			fit = false
			table.insert(notesL, string.format("%s main %dx%d words %d action %d,%d %dx%d", shape[1], m.w, m.h,
				d.words.h, a.x, a.y, a.w, a.h))
		end
		if shape[2].X > shape[2].Y and not d.side then
			sideOk = false
			table.insert(notesL, shape[1] .. " is landscape but stacked")
		end
	end
end
check(fit, "on every listed desktop and phone the details fit: the button whole, 44+ tall and pinned under the "
	.. "words, the words at least " .. MenuLayout.Events.WordsMin .. " tall, the picture 16:9", table.concat(notesL, "; "))
check(sideOk, "every landscape screen sets the picture beside the words, so it never pushes them off a short phone",
	table.concat(notesL, "; "))
do
	local d = MenuLayout.eventDetail(658, 200, true)
	check(d.side and d.banner.h <= 200 - 26 - 34 - 12 and d.words.h >= 90,
		"on the 338-px phone the picture gives way first: smaller, and the words keep " .. d.words.h .. " px")
end

--==============================================================================
-- 8. THE SCRIPT: Roblox's own calls, nothing invented, nothing automatic
--==============================================================================
say("-- the wiring --")
local holder = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local eventsScript = holder and holder:FindFirstChild("EventsUI")
local src = if eventsScript then ((eventsScript :: any).Source:gsub("\r\n", "\n")) else ""
-- The code alone, for what it must never DO (its comments name what it avoids).
local code = src:gsub("%-%-[^\n]*", "")
local function has(needle)
	return src:find(needle, 1, true) ~= nil
end
local function count(needle)
	local n, at = 0, 1
	while true do
		local i = src:find(needle, at, true)
		if not i then
			return n
		end
		n += 1
		at = i + #needle
	end
end
check(src ~= "" and has("SocialService:GetUpcomingExperienceEventsAsync()")
		and has("SocialService:GetEventRsvpStatusAsync(id)") and has("SocialService:PromptRsvpToEventAsync(id)"),
	"EventsUI asks SocialService itself: the list, the status and the native prompt")
check(not src:find("rbxassetid://%d") and not src:find("Id%s*=%s*\"") and not src:find("%d%d%d%d%d%d%d%d%d%d")
		and not has("DataStore"),
	"no hardcoded event id, picture or date, and no reminder store of its own")
check(count("setOpen(true)") == 0 and count("setOpen(not open)") == 1
		and has("MenuKit.tap(button, UIKit.railDockScroll(playerGui), function()\n\tsetOpen(not open)"),
	"it opens only when its button is pressed (a tap; a drag on the phone's panel scrolls): no automatic popup")
check(has("player:SetAttribute(ATTR.OpenPanel, PANEL_NAME)") and has("if open and holder ~= PANEL_NAME then")
		and has('padFirst.Name = "PadFirst"') and has("MenuKit.bindBack(BACK_NAME, closeDetail)"),
	"it takes its turn on the OpenPanel mutex, names its controller start, and B steps back to the list")
check(has("feed.destroy()") and has("stopTick()") and has("tick = RunService.Heartbeat:Connect")
		and has("UIKit.coverRail(playerGui, PANEL_NAME, false)"),
	"its one clock runs only while open, and everything is let go when the gui goes")
local quiet = true
for _, word in ipairs({ "Weather", "MiniEvent", "Disco", "Rain", "Thunder", "Ticket", "Announce", "Remotes", "FireServer",
	"InvokeServer", "Admin" }) do
	-- Whole words: "Disconnect" is not the Disco.
	if code:find("%f[%w]" .. word .. "%f[%W]") then
		quiet = false
		say("    mentions " .. word)
	end
end
check(quiet, "it starts nothing in the game: no weather, disco, ticket drop, broadcast, remote or admin call")
check(has("wordsText.RichText = false"), "an event's words are shown as written, never as markup")
do
	-- Every colour it paints is a shared MenuKit token that exists (a missing one
	-- is a nil BackgroundColor3, and the whole list stops painting -- found in
	-- Play 2026-10-04).
	local MenuKit = require(Shared:WaitForChild("MenuKit"))
	local missing = {}
	for name in code:gmatch("LOOK%.(%a+)") do
		if MenuKit.Look[name] == nil then
			table.insert(missing, name)
		end
	end
	check(#missing == 0, "every LOOK token EventsUI paints with exists in MenuKit.Look", table.concat(missing, ", "))
end

end)

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return table.concat(out, "\n") .. ("\nEventsPanelSpec: %d passed, %d FAILED\n  %s"):format(
		pass, #fails, table.concat(fails, "\n  "))
end
return table.concat(out, "\n") .. ("\nEventsPanelSpec: %d passed, 0 failed"):format(pass)
