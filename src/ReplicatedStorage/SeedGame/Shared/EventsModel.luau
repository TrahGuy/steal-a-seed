--!strict
--==============================================================================
-- Steal a Seed :: EventsModel (2026-10-04, the EVENTS panel)
--
-- WHAT THE EVENTS PANEL SAYS, decided with no Instance and no service of its
-- own -- EventsUI hands it SocialService, the clock and the timer -- so
-- EventsPanelSpec drives every state in Edit with stand-in answers.
--
--   normalize  one ExperienceEvent -> the fields the panel shows: the
--              localized Display* text first, the id kept a STRING (an event
--              id is wider than a double holds exactly), the first thumbnail
--   utc        a StartTime / EndTime dictionary -> Unix seconds, every field
--              checked (a 31st of April is refused, not read as the 1st of
--              May); nil, never a guess
--   trusted    whether those times agree with Roblox's own HasStarted /
--              HasEnded at fetch. When they do not, no time is shown and the
--              clock never moves the event on: Roblox's flags stand until the
--              next refresh
--   phase      upcoming / live / ended / closed
--   action     the bottom button: NOTIFY ME, NOTIFICATIONS ON, LIVE NOW ...
--   badge      the schedule badge: STARTS IN 2D 4H, LIVE NOW, ENDED
--   feed       the list's cache and the reminder statuses: one request at a
--              time, a bounded retry, stale answers dropped, nothing at all
--              after destroy
--
-- THE PANEL ONLY ADVERTISES. Nothing here starts, schedules or announces
-- anything in the game, and nothing here remembers a reminder: Roblox keeps
-- the RSVP, and the panel only ever shows what Roblox answered.
--==============================================================================
local EventsModel = {}

export type Event = {
	id: string,
	title: string,
	subtitle: string?,
	description: string,
	-- "rbxassetid://<first ThumbnailIds entry>", or nil when there is none.
	image: string?,
	-- Unix seconds, from the UTC dictionaries; nil when a field is invalid.
	startsAt: number?,
	endsAt: number?,
	-- Roblox's own flags, as they were when the list was fetched.
	started: boolean,
	ended: boolean,
	-- Enum.ExperienceEventStatus's name ("Active", "Cancelled", ...).
	status: string,
	-- The times agree with the flags (EventsModel.trusted): shown, and the
	-- clock may move the event on from upcoming to live to ended.
	timed: boolean,
	fetchedAt: number,
}

export type Phase = "upcoming" | "live" | "ended" | "closed"

-- What the panel knows of this player's reminder for one event: a status
-- Roblox answered, or that it is being asked, failed, or was never asked.
export type Rsvp = "unknown" | "reading" | "failed" | "None" | "Going" | "NotGoing"

export type Action = {
	label: string,
	enabled: boolean,
	-- MenuKit.button's face: go, done, idle, live, off.
	style: string,
	-- True for the one action that opens Roblox's reminder prompt.
	prompts: boolean,
}

--==============================================================================
-- THE TIMES: UTC DICTIONARY -> UNIX SECONDS
--==============================================================================
local function whole(v: any, lo: number, hi: number): number?
	if type(v) ~= "number" or v ~= v or v % 1 ~= 0 or v < lo or v > hi then
		return nil
	end
	return v
end

local function monthDays(year: number, month: number): number
	if month == 2 then
		local leap = (year % 4 == 0 and year % 100 ~= 0) or year % 400 == 0
		return if leap then 29 else 28
	end
	return if month == 4 or month == 6 or month == 9 or month == 11 then 30 else 31
end

-- Days since 1970-01-01 of a proleptic Gregorian date (H. Hinnant's
-- days_from_civil): exact integer arithmetic, no time zone anywhere.
local function daysFromCivil(year: number, month: number, day: number): number
	local y = if month <= 2 then year - 1 else year
	local era = (if y >= 0 then y else y - 399) // 400
	local yoe = y - era * 400
	local mp = (month + 9) % 12
	local doy = (153 * mp + 2) // 5 + day - 1
	local doe = yoe * 365 + yoe // 4 - yoe // 100 + doy
	return era * 146097 + doe - 719468
end

function EventsModel.utc(t: any): number?
	if type(t) ~= "table" then
		return nil
	end
	local year = whole(t.Year, 2000, 2200)
	local month = whole(t.Month, 1, 12)
	local hour = whole(t.Hour, 0, 23)
	local minute = whole(t.Minute, 0, 59)
	-- Seconds and milliseconds are listed too; absent, they are zero.
	local second = whole(if t.Second == nil then 0 else t.Second, 0, 59)
	local milli = whole(if t.Millisecond == nil then 0 else t.Millisecond, 0, 999)
	if not (year and month and hour and minute and second and milli) then
		return nil
	end
	local day = whole(t.Day, 1, monthDays(year, month))
	if not day then
		return nil
	end
	return daysFromCivil(year, month, day) * 86400 + hour * 3600 + minute * 60 + second + milli / 1000
end

--==============================================================================
-- ONE EVENT
--==============================================================================
local function firstText(...: any): string?
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if type(v) == "string" then
			local trimmed = string.match(v, "^%s*(.-)%s*$")
			if trimmed and trimmed ~= "" then
				return trimmed
			end
		end
	end
	return nil
end

local function enumName(v: any): string?
	if typeof(v) == "EnumItem" then
		return (v :: EnumItem).Name
	end
	if type(v) == "string" and v ~= "" then
		return v
	end
	return nil
end
EventsModel.enumName = enumName

local function imageOf(ids: any): string?
	if type(ids) ~= "table" then
		return nil
	end
	local first = ids[1]
	if type(first) == "number" and first == first and first % 1 == 0 and first > 0 and first < 2 ^ 53 then
		return string.format("rbxassetid://%d", first)
	end
	if type(first) == "string" and string.match(first, "^%d+$") then
		return "rbxassetid://" .. first
	end
	return nil
end

function EventsModel.trusted(e: Event, at: number, slack: number): boolean
	local s, f = e.startsAt, e.endsAt
	if not s or not f or f <= s then
		return false
	end
	-- Roblox's flags were true at `at`. The times must say the same, give or
	-- take the slack: a list a little old, a clock a little off.
	if e.started ~= (at >= s) and math.abs(at - s) > slack then
		return false
	end
	if e.ended ~= (at >= f) and math.abs(at - f) > slack then
		return false
	end
	return true
end

function EventsModel.normalize(raw: any, fetchedAt: number, slack: number?): Event?
	if type(raw) ~= "table" then
		return nil
	end
	-- A string, as Roblox sends it. A number has already been rounded by the
	-- double it arrived in, and a prompt for it would name some other event.
	local id = raw.Id
	if type(id) ~= "string" or #id == 0 or #id > 64 or string.find(id, "%s") then
		return nil
	end
	local e: Event = {
		id = id,
		title = firstText(raw.DisplayTitle, raw.Title) or "Event",
		subtitle = firstText(raw.DisplaySubtitle, raw.Subtitle),
		description = firstText(raw.DisplayDescription, raw.Description) or "",
		image = imageOf(raw.ThumbnailIds),
		startsAt = EventsModel.utc(raw.StartTime),
		endsAt = EventsModel.utc(raw.EndTime),
		started = raw.HasStarted == true,
		ended = raw.HasEnded == true,
		status = enumName(raw.Status) or "Unknown",
		timed = false,
		fetchedAt = fetchedAt,
	}
	e.timed = EventsModel.trusted(e, fetchedAt, slack or 120)
	return e
end

-- The whole answer: valid events only, each id once, soonest start first
-- (Roblox's order where a start is missing).
function EventsModel.list(raw: any, fetchedAt: number, slack: number?): { Event }
	local out: { Event } = {}
	if type(raw) ~= "table" then
		return out
	end
	local seen: { [string]: boolean } = {}
	local order: { [Event]: number } = {}
	for i, item in ipairs(raw) do
		local e = EventsModel.normalize(item, fetchedAt, slack)
		if e and not seen[e.id] then
			seen[e.id] = true
			order[e] = i
			table.insert(out, e)
		end
	end
	table.sort(out, function(a: Event, b: Event): boolean
		local sa, sb = a.startsAt or math.huge, b.startsAt or math.huge
		if sa ~= sb then
			return sa < sb
		end
		return order[a] < order[b]
	end)
	return out
end

--==============================================================================
-- WHAT IT IS NOW, AND WHAT THE PANEL SAYS
--==============================================================================
function EventsModel.phase(e: Event, now: number): Phase
	if e.status ~= "Active" then
		return "closed"
	end
	if e.ended or (e.timed and now >= (e.endsAt :: number)) then
		return "ended"
	end
	if e.started or (e.timed and now >= (e.startsAt :: number)) then
		return "live"
	end
	return "upcoming"
end

function EventsModel.action(phase: Phase, rsvp: Rsvp, pending: boolean): Action
	if phase == "live" then
		return { label = "LIVE NOW", enabled = false, style = "live", prompts = false }
	elseif phase == "ended" then
		return { label = "EVENT ENDED", enabled = false, style = "off", prompts = false }
	elseif phase == "closed" then
		return { label = "UNAVAILABLE", enabled = false, style = "off", prompts = false }
	end
	if rsvp == "reading" then
		return { label = "CHECKING...", enabled = false, style = "idle", prompts = false }
	end
	-- Only a status Roblox ANSWERED says the reminder is on: a cancelled or
	-- failed prompt, or a status not read yet, leaves NOTIFY ME.
	local going = rsvp == "Going"
	return {
		label = if going then "NOTIFICATIONS ON" else "NOTIFY ME",
		enabled = not pending,
		style = if going then "done" else "go",
		prompts = true,
	}
end

-- "2D 4H", "3H 12M", "45M"; nil under a minute.
function EventsModel.countdown(seconds: number): string?
	local s = math.floor(seconds)
	if s < 60 then
		return nil
	end
	local d, h, m = s // 86400, (s % 86400) // 3600, (s % 3600) // 60
	if d > 0 then
		return string.format("%dD %dH", d, h)
	end
	if h > 0 then
		return string.format("%dH %dM", h, m)
	end
	return string.format("%dM", m)
end

function EventsModel.badge(e: Event, phase: Phase, now: number): string
	if phase == "live" then
		return "LIVE NOW"
	elseif phase == "ended" then
		return "ENDED"
	elseif phase == "closed" then
		return if e.status == "Cancelled" then "CANCELLED" else "UNAVAILABLE"
	end
	if e.timed then
		local left = EventsModel.countdown((e.startsAt :: number) - now)
		return if left then "STARTS IN " .. left else "STARTING SOON"
	end
	return "UPCOMING"
end

--==============================================================================
-- THE TIMES IN THE PLAYER'S OWN ZONE AND LANGUAGE
--
-- `day` and `time` format a Unix time for this player: DateTime's local time
-- (the device's own zone) in the player's locale, "Sat, Oct 11" and "6:00 PM".
-- A locale DateTime does not know falls back to en-us rather than to nothing.
--==============================================================================
export type Clock = {
	day: (number) -> string,
	time: (number) -> string,
}

function EventsModel.clock(locale: string?): Clock
	local function format(at: number, pattern: string): string
		local moment = DateTime.fromUnixTimestampMillis(math.floor(at * 1000 + 0.5))
		local ok, text = pcall(function()
			return moment:FormatLocalTime(pattern, locale or "en-us")
		end)
		if ok and type(text) == "string" and text ~= "" then
			return text
		end
		return moment:FormatLocalTime(pattern, "en-us")
	end
	return {
		day = function(at: number): string
			return format(at, "ddd, MMM D")
		end,
		time = function(at: number): string
			return format(at, "LT")
		end,
	}
end

-- "Sat, Oct 11, 6:00 PM - 8:00 PM", or both days where it ends on another.
-- Nil when the times are not trusted: no time beats a wrong one.
function EventsModel.when(e: Event, clock: Clock): string?
	if not e.timed then
		return nil
	end
	local s, f = e.startsAt :: number, e.endsAt :: number
	local sd, fd = clock.day(s), clock.day(f)
	if sd == fd then
		return string.format("%s, %s - %s", sd, clock.time(s), clock.time(f))
	end
	return string.format("%s, %s - %s, %s", sd, clock.time(s), fd, clock.time(f))
end

--==============================================================================
-- THE FEED: THE LIST, ITS CACHE, AND THE REMINDER STATUSES
--
--   refresh    asks for the list when it is stale (CacheSeconds) or forced;
--              never twice at once. A failure retries Retries more times after
--              RetryDelays, then the state is "failed" -- or, over an older
--              list, that list stays, still stale, and the next open asks again
--   readRsvp   GetEventRsvpStatusAsync for one event, once at a time, trusted
--              RsvpSeconds
--   promptRsvp Roblox's own prompt, once at a time per event. Its answer is
--              the status (Roblox returns the old one when the player changed
--              nothing); an error assumes nothing and reads the status again
--
-- Every answer is checked against the request it belongs to: a list request
-- superseded or a feed destroyed drops its answer, a read overtaken by a
-- prompt is dropped, and a status is filed under its own event's id -- so an
-- answer arriving after the player switched events never paints the other one.
--==============================================================================
export type FeedConfig = {
	CacheSeconds: number,
	Retries: number,
	RetryDelays: { number },
	RsvpSeconds: number,
	TrustSlack: number,
}

export type FeedDeps = {
	list: () -> any,
	read: (string) -> any,
	prompt: (string) -> any,
	-- Unix seconds: the same clock the event times are in.
	now: () -> number,
	delay: (number, () -> ()) -> (),
	spawn: (() -> ()) -> (),
	config: FeedConfig,
}

export type FeedState = "idle" | "loading" | "ready" | "failed"

export type Feed = {
	state: () -> FeedState,
	events: () -> { Event },
	find: (string) -> Event?,
	loading: () -> boolean,
	stale: () -> boolean,
	refresh: (force: boolean?) -> boolean,
	rsvp: (string) -> Rsvp,
	pending: (string) -> boolean,
	readRsvp: (string, boolean?) -> boolean,
	promptRsvp: (string) -> boolean,
	-- The last prompt's trouble for this event, if it had any.
	note: (string) -> string?,
	changed: (() -> ()) -> () -> (),
	destroy: () -> (),
}

local STATUSES = { None = true, Going = true, NotGoing = true }

function EventsModel.feed(deps: FeedDeps): Feed
	local C = deps.config
	local state: FeedState = "idle"
	local list: { Event } = {}
	local fetchedAt: number? = nil
	local inFlight = false
	local generation = 0
	local dead = false

	local listeners: { [number]: () -> () } = {}
	local nextListener = 0
	local function emit()
		if dead then
			return
		end
		for _, fn in pairs(listeners) do
			fn()
		end
	end

	local known: { [string]: string } = {}
	local knownAt: { [string]: number } = {}
	local failed: { [string]: boolean } = {}
	-- A failed read is not asked again for RsvpSeconds either, unless forced:
	-- an open panel paints once a second.
	local failedAt: { [string]: number } = {}
	local reading: { [string]: number } = {}
	local prompting: { [string]: boolean } = {}
	local notes: { [string]: string } = {}
	local token = 0

	local function stale(): boolean
		return state ~= "ready" or fetchedAt == nil or deps.now() - (fetchedAt :: number) >= C.CacheSeconds
	end

	local function refresh(force: boolean?): boolean
		if dead or inFlight then
			return false
		end
		if not force and not stale() then
			return false
		end
		inFlight = true
		generation += 1
		local gen = generation
		if #list == 0 then
			state = "loading"
		end
		emit()
		local function attempt(n: number)
			deps.spawn(function()
				local ok, result = pcall(deps.list)
				if dead or gen ~= generation then
					return
				end
				if ok and type(result) == "table" then
					local at = deps.now()
					list = EventsModel.list(result, at, C.TrustSlack)
					fetchedAt = at
					state = "ready"
					inFlight = false
					emit()
					return
				end
				if n <= C.Retries then
					local pause = C.RetryDelays[n] or C.RetryDelays[#C.RetryDelays] or 2
					deps.delay(pause, function()
						if not dead and gen == generation then
							attempt(n + 1)
						end
					end)
					return
				end
				inFlight = false
				state = if #list > 0 then "ready" else "failed"
				emit()
			end)
		end
		attempt(1)
		return true
	end

	local function rsvpOf(id: string): Rsvp
		local status = known[id]
		if status then
			return status :: Rsvp
		end
		if reading[id] then
			return "reading"
		end
		return if failed[id] then "failed" else "unknown"
	end

	local function readRsvp(id: string, force: boolean?): boolean
		if dead or reading[id] or prompting[id] then
			return false
		end
		local at = if known[id] then knownAt[id] else failedAt[id]
		if not force and at and deps.now() - at < C.RsvpSeconds then
			return false
		end
		token += 1
		local mine = token
		reading[id] = mine
		emit()
		deps.spawn(function()
			local ok, result = pcall(deps.read, id)
			if dead or reading[id] ~= mine then
				return
			end
			reading[id] = nil
			local name = if ok then enumName(result) else nil
			if name and STATUSES[name] then
				known[id] = name
				knownAt[id] = deps.now()
				failed[id] = nil
				failedAt[id] = nil
			else
				failed[id] = true
				failedAt[id] = deps.now()
			end
			emit()
		end)
		return true
	end

	local function promptRsvp(id: string): boolean
		if dead or prompting[id] then
			return false
		end
		prompting[id] = true
		-- A read still out is overtaken: the prompt's answer is newer.
		reading[id] = nil
		notes[id] = nil
		emit()
		deps.spawn(function()
			local ok, result = pcall(deps.prompt, id)
			if dead then
				return
			end
			prompting[id] = nil
			local name = if ok then enumName(result) else nil
			if name and STATUSES[name] then
				known[id] = name
				knownAt[id] = deps.now()
				failed[id] = nil
				failedAt[id] = nil
				emit()
				return
			end
			-- An error, or an answer that is not a status: nothing is assumed --
			-- the status stays what Roblox last said, and is asked for again.
			notes[id] = "The reminder could not be set. Try again."
			emit()
			readRsvp(id, true)
		end)
		return true
	end

	return {
		state = function(): FeedState
			return state
		end,
		events = function(): { Event }
			return list
		end,
		find = function(id: string): Event?
			for _, e in ipairs(list) do
				if e.id == id then
					return e
				end
			end
			return nil
		end,
		loading = function(): boolean
			return inFlight
		end,
		stale = stale,
		refresh = refresh,
		rsvp = rsvpOf,
		pending = function(id: string): boolean
			return prompting[id] == true
		end,
		readRsvp = readRsvp,
		promptRsvp = promptRsvp,
		note = function(id: string): string?
			return notes[id]
		end,
		changed = function(fn: () -> ()): () -> ()
			nextListener += 1
			local key = nextListener
			listeners[key] = fn
			return function()
				listeners[key] = nil
			end
		end,
		destroy = function()
			dead = true
			table.clear(listeners)
		end,
	}
end

return EventsModel
