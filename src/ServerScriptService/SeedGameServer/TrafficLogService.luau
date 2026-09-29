--!strict
--==============================================================================
-- Steal a Seed :: TrafficLogService
--
-- The external new-player traffic feed (2026-09-28): two events per genuinely
-- new player, POSTed server-side to two webhook routes the owner configures
-- (Michael's Make.com scenarios, feeding a shared Google Sheet). OFF until the owner turns
-- it on (TrafficLogConfig.Enabled). KB/TRAFFIC_LOG.md is the guide: payload,
-- owner setup, receiver rules, what it cannot count.
--
--   new_player_joined          the profile system confirmed a brand-new,
--                              persistent save (SaveService.Load said "new")
--   new_player_session_ended   that same session ended, with the elapsed
--                              connection time since PlayerAdded
--
-- It SUPPLEMENTS Metrics (Roblox's own analytics) and shares nothing with it.
-- MEASUREMENT ONLY: nothing here grants, blocks or waits for anything. Every
-- lifecycle call is pcall-fenced and never yields; requests run on their own
-- threads, and a dead webhook costs the game nothing but a bounded queue.
--
-- NEVER: Studio, staff (AdminService's allowlist), a temporary profile, a
-- returning player. NOTHING PERSONAL: no name, UserId, account age, chat or
-- inventory -- a random session id is the only thing pairing the two events.
--==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CONFIG: any = require(script.Parent:WaitForChild("TrafficLogConfig"))

local TrafficLogService = {}
-- Before PlayerDataService (20), whose join path calls classified().
TrafficLogService.Priority = 15

-- THE CONTRACT. Bump SchemaVersion for any change a receiver would notice.
TrafficLogService.SchemaVersion = 1
TrafficLogService.Events = {
	Joined = "new_player_joined",
	Ended = "new_player_session_ended",
}
TrafficLogService.UnknownCampaign = "unknown"

local EVENTS = TrafficLogService.Events
local UNKNOWN = TrafficLogService.UnknownCampaign
local LAUNCH_DATA_MAX = 200 -- Roblox's own cap on launch data
local TAG_MAX = 40

--==============================================================================
-- CONFIGURATION: TrafficLogConfig, or a spec's overrides
--==============================================================================
local overrides: { [string]: any } = {}

local function setting(key: string): any
	local value = overrides[key]
	if value ~= nil then
		return value
	end
	return CONFIG[key]
end

local function number(key: string, low: number, fallback: number): number
	local n = tonumber(setting(key))
	if n == nil or n ~= n then
		return fallback
	end
	return math.max(low, n)
end

--==============================================================================
-- SEAMS: the live pieces, and a spec's stand-ins for them
--==============================================================================
-- A sender POSTs one JSON body to the endpoint for its event type and returns
-- the HTTP status (and optional Retry-After seconds). It throws on no response.
export type Sender = (body: string, eventType: string) -> (number, number?)

local senderOverride: Sender? = nil
local staffOverride: ((any) -> boolean)? = nil
local studioOverride: boolean? = nil
local joinDataOverride: ((any) -> any)? = nil
local warnOverride: ((string) -> ())? = nil
local autoPump = true

local clock: () -> number = os.clock
local function defaultUtc(): number
	return DateTime.now().UnixTimestampMillis
end
local utcMillis: () -> number = defaultUtc

-- THE ONLY PLACE A REQUEST IS MADE. Both URLs are experience secrets, fetched
-- by name and handed to RequestAsync as Secrets: never strings in this module.
local secretUrls: { [string]: any } = {}

local function liveSend(body: string, eventType: string): (number, number?)
	-- Resolve both before the first request. A missing duration endpoint must
	-- not leave the receiver with joins that can never get matching endings.
	for _, route in ipairs({ EVENTS.Joined, EVENTS.Ended }) do
		if secretUrls[route] == nil then
			local secretName = if route == EVENTS.Joined then "JoinSecretName" else "DurationSecretName"
			local ok, secret = pcall(function(): any
				return HttpService:GetSecret(tostring(setting(secretName)))
			end)
			if not ok then
				local message = string.lower(tostring(secret))
				error(if string.find(message, "not enabled", 1, true) then "http not enabled" else "cannot find secret", 0)
			end
			secretUrls[route] = secret
		end
	end
	local secretUrl = secretUrls[eventType]
	if secretUrl == nil then
		error("unknown traffic event route", 0)
	end
	local response = HttpService:RequestAsync({
		Url = secretUrl,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = body,
	} :: any)
	local headers: any = response.Headers or {}
	return response.StatusCode, tonumber(headers["retry-after"] or headers["Retry-After"])
end

--==============================================================================
-- DIAGNOSTICS: fixed words and counts only -- never a URL, a body or a raw
-- error text -- and at most one warning of each kind per DiagnosticSeconds.
--==============================================================================
local lastWarned: { [string]: number } = {}
local suppressed: { [string]: number } = {}

local function diag(kind: string, text: string)
	local now = clock()
	local last = lastWarned[kind]
	if last and now - last < number("DiagnosticSeconds", 1, 60) then
		suppressed[kind] = (suppressed[kind] or 0) + 1
		return
	end
	lastWarned[kind] = now
	local extra = suppressed[kind]
	suppressed[kind] = nil
	local line = "[Seed/TrafficLog] " .. text
	if extra then
		line ..= string.format(" (+%d more since the last warning)", extra)
	end
	pcall(warnOverride or warn, line)
end

--==============================================================================
-- WHO IS COUNTED
--==============================================================================
local function isStudio(): boolean
	if studioOverride ~= nil then
		return studioOverride
	end
	return RunService:IsStudio()
end

-- Set when sending can never work on this server (HTTP requests off, no
-- secret): from then on nothing is tracked or queued.
local halted: string? = nil

local function active(): boolean
	return setting("Enabled") == true and halted == nil and not isStudio()
end

-- A real Player; a spec's stand-in table only while a spec's sender is set.
local function acceptable(player: any): boolean
	if typeof(player) == "Instance" then
		return player:IsA("Player")
	end
	return type(player) == "table" and senderOverride ~= nil
end

-- The same staff list Metrics leaves out (AdminService's allowlist), asked
-- lazily for the same reason: AdminService requires PlayerDataService, which
-- requires this.
local function isStaff(player: any): boolean
	local check = staffOverride
	if check then
		local ok, answer = pcall(check, player)
		return ok and answer == true
	end
	local ok, admin = pcall(function(): any
		local found = script.Parent:FindFirstChild("AdminService")
		return if found and found:IsA("ModuleScript") then require(found) :: any else nil
	end)
	if ok and type(admin) == "table" and type(admin.IsAdmin) == "function" then
		local okAsk, answer = pcall(admin.IsAdmin, player)
		return okAsk and answer == true
	end
	return false
end

--==============================================================================
-- CAMPAIGN TAG: an allowlisted launch-data value, or "unknown". Raw launch
-- data never leaves this function. A tag says how the join URL was built, not
-- that anybody clicked an ad: tagged links can be shared.
--==============================================================================
local function normaliseTag(value: any): string?
	if type(value) ~= "string" or #value > LAUNCH_DATA_MAX then
		return nil
	end
	local trimmed = string.lower(string.match(value, "^%s*(.-)%s*$") or "")
	if #trimmed == 0 or #trimmed > TAG_MAX or not string.match(trimmed, "^[a-z0-9_%-]+$") then
		return nil
	end
	return trimmed
end

local function campaignTag(player: any): string
	local ok, tag = pcall(function(): string?
		local read = joinDataOverride
		local data = if read then read(player) else player:GetJoinData()
		return if type(data) == "table" then normaliseTag(data.LaunchData) else nil
	end)
	if not ok or tag == nil or tag == UNKNOWN then
		return UNKNOWN
	end
	local tags = setting("CampaignTags")
	if type(tags) == "table" then
		for _, entry in ipairs(tags) do
			if normaliseTag(entry) == tag then
				return tag
			end
		end
	end
	return UNKNOWN
end

--==============================================================================
-- THE QUEUE AND THE SENDER
--
-- Bounded (a full queue drops the newest event), at most MaxConcurrent requests
-- in flight, at most MaxAttempts tries per event with doubling, jittered
-- backoff. 2xx is delivered; 408, 429, 5xx and no response at all are retried;
-- any other status is a permanent refusal and is dropped. An event's body --
-- eventId included -- is built once, so every retry sends the same bytes.
--==============================================================================
type Item = {
	eventId: string,
	eventType: string,
	body: string,
	attempts: number,
	nextAt: number,
	inFlight: boolean,
	flushTried: boolean,
}

local queue: { Item } = {}
local known: { [string]: boolean } = {}
local inFlight = 0
local pumping = false
local flushing = false
local rng = Random.new()

local stats = {
	queued = 0, -- events accepted into the queue
	requests = 0, -- attempts made (a retry is another request)
	delivered = 0,
	retries = 0,
	droppedFull = 0,
	droppedRejected = 0,
	droppedExhausted = 0,
	droppedHalted = 0,
	duplicates = 0, -- repeated lifecycle calls and repeated events, ignored
}

local function remove(item: Item)
	local index = table.find(queue, item)
	if index then
		table.remove(queue, index)
	end
end

local function halt(reason: string)
	if halted then
		return
	end
	halted = reason
	stats.droppedHalted += #queue
	table.clear(queue)
	diag("halted", "sending stopped on this server (" .. reason .. "); events dropped")
end

-- A thrown error, reduced to a fixed word: the raw text is never printed.
local function failureKind(err: any): string
	local text = string.lower(tostring(err))
	if string.find(text, "not enabled", 1, true) then
		return "http-disabled"
	elseif string.find(text, "find secret", 1, true) then
		return "secret-missing"
	elseif string.find(text, "timedout", 1, true) or string.find(text, "timed out", 1, true)
		or string.find(text, "timeout", 1, true) then
		return "timeout"
	end
	return "no-response"
end

local function backoff(attempts: number, retryAfter: any): number
	local cap = number("MaxBackoffSeconds", 0, 60)
	local wait = math.min(cap, number("BackoffSeconds", 0, 2) * 2 ^ (attempts - 1))
	local jitter = math.clamp(number("Jitter", 0, 0.2), 0, 1)
	if jitter > 0 then
		wait *= 1 + (rng:NextNumber() * 2 - 1) * jitter
	end
	-- A server's Retry-After is honoured, within the same ceiling.
	local asked = tonumber(retryAfter)
	if asked and asked > wait then
		wait = math.min(cap, asked)
	end
	return math.max(0, wait)
end

local function attempt(item: Item)
	item.inFlight = true
	item.attempts += 1
	inFlight += 1
	stats.requests += 1
	local ok, status, retryAfter = pcall(senderOverride or liveSend, item.body, item.eventType)
	inFlight = math.max(0, inFlight - 1)
	item.inFlight = false

	local code = if ok then tonumber(status) else nil
	if code and code >= 200 and code < 300 then
		remove(item)
		stats.delivered += 1
		return
	end
	if halted or not table.find(queue, item) then
		return
	end
	local kind = if ok then (if code then "HTTP " .. code else "bad-response") else failureKind(status)
	if kind == "http-disabled" or kind == "secret-missing" then
		halt(kind)
		return
	end
	local transient = not ok or code == nil or code == 408 or code == 429 or (code >= 500 and code <= 599)
	if not transient then
		remove(item)
		stats.droppedRejected += 1
		diag("rejected", "the webhook refused an event (" .. kind .. "); dropped, not retried")
		return
	end
	if item.attempts >= math.floor(number("MaxAttempts", 1, 5)) then
		remove(item)
		stats.droppedExhausted += 1
		diag("exhausted", string.format("an event failed %d times (last: %s); dropped", item.attempts, kind))
		return
	end
	item.nextAt = clock() + backoff(item.attempts, if ok then retryAfter else nil)
	stats.retries += 1
	diag("retrying", "delivery failed (" .. kind .. "); retrying with backoff")
end

-- One pass: starts every due event, up to the concurrency limit. The live loop
-- calls it while the queue is non-empty; specs call it by hand.
function TrafficLogService.pump()
	pcall(function()
		local limit = math.floor(number("MaxConcurrent", 1, 2))
		local now = clock()
		for _, item in ipairs(table.clone(queue)) do
			if halted or inFlight >= limit then
				break
			end
			local due = if flushing then not item.flushTried else item.nextAt <= now
			if not item.inFlight and due and table.find(queue, item) then
				item.flushTried = flushing
				task.spawn(attempt, item)
			end
		end
	end)
end

-- Only while there is something to send: no queue, no loop, no per-frame work.
local function startPump()
	if pumping or not autoPump then
		return
	end
	pumping = true
	task.defer(function()
		while #queue > 0 and halted == nil do
			TrafficLogService.pump()
			task.wait(number("PumpSeconds", 0.05, 0.5))
		end
		pumping = false
	end)
end

local function enqueue(item: Item)
	if known[item.eventId] then
		stats.duplicates += 1
		return
	end
	if #queue >= math.floor(number("QueueCapacity", 1, 64)) then
		stats.droppedFull += 1
		diag("full", "queue full; an event was dropped")
		return
	end
	known[item.eventId] = true
	table.insert(queue, item)
	stats.queued += 1
	startPump()
end

--==============================================================================
-- SESSIONS: one per connection, from PlayerAdded to PlayerRemoving. Nothing
-- is saved: a crash loses what was open.
--==============================================================================
type Session = {
	sessionId: string,
	startedMs: number, -- UTC, for the timestamps
	startedAt: number, -- monotonic, for the duration
	campaignTag: string,
	classified: boolean,
	qualifies: boolean,
}

local sessions: { [any]: Session } = {}
-- Left already: a profile result that lands after this is ignored.
local departed: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any

local function open(player: any): Session
	local s = sessions[player]
	if not s then
		s = {
			sessionId = HttpService:GenerateGUID(false),
			startedMs = utcMillis(),
			startedAt = clock(),
			campaignTag = campaignTag(player),
			classified = false,
			qualifies = false,
		}
		sessions[player] = s
	end
	return s :: Session
end

local function iso(ms: number): string
	return DateTime.fromUnixTimestampMillis(ms):ToIsoDate()
end

local function build(eventType: string, s: Session, durationSeconds: number?): Item
	local payload: { [string]: any } = {
		schemaVersion = TrafficLogService.SchemaVersion,
		eventType = eventType,
		eventId = HttpService:GenerateGUID(false),
		sessionId = s.sessionId,
		occurredAtUtc = iso(utcMillis()),
		sessionStartedAtUtc = iso(s.startedMs),
		placeVersion = game.PlaceVersion,
		campaignTag = s.campaignTag,
	}
	if durationSeconds ~= nil then
		payload.sessionDurationSeconds = durationSeconds
	end
	return {
		eventId = payload.eventId,
		eventType = eventType,
		body = HttpService:JSONEncode(payload),
		attempts = 0,
		nextAt = -math.huge,
		inFlight = false,
		flushTried = false,
	}
end

--==============================================================================
-- THE LIFECYCLE
--==============================================================================
-- PlayerAdded: the session starts now, whatever the profile turns out to be.
function TrafficLogService.arrived(player: any)
	pcall(function()
		if active() and acceptable(player) and not departed[player] then
			open(player)
		end
	end)
end

-- PlayerDataService, the moment a profile loaded: `isNew` is SaveService's
-- "new", `persistent` that the save can be written. Only a new, persistent,
-- non-staff profile sends anything.
function TrafficLogService.classified(player: any, isNew: boolean, persistent: boolean)
	pcall(function()
		if not active() or not acceptable(player) then
			return
		end
		-- Left while the profile loaded: nothing to report, nobody to open for.
		if departed[player] or player.Parent ~= Players then
			return
		end
		-- Opened here if PlayerAdded was missed; the start is then this moment.
		local s = open(player)
		if s.classified then
			stats.duplicates += 1
			return
		end
		s.classified = true
		if isNew ~= true or persistent ~= true or isStaff(player) then
			return
		end
		s.qualifies = true
		enqueue(build(EVENTS.Joined, s, nil))
	end)
end

-- PlayerRemoving, and every open session at shutdown: the ending event, once.
function TrafficLogService.left(player: any)
	pcall(function()
		if not active() or not acceptable(player) then
			return
		end
		if departed[player] then
			stats.duplicates += 1
			return
		end
		departed[player] = true
		local s = sessions[player]
		sessions[player] = nil
		if s and s.qualifies then
			local elapsed = math.max(0, math.floor(clock() - s.startedAt + 0.5))
			enqueue(build(EVENTS.Ended, s, elapsed))
		end
	end)
end

-- Server closing: end what is open, then a short best-effort send -- one more
-- try for each queued event, bounded by FlushSeconds (or `seconds`).
function TrafficLogService.shutdown(seconds: number?)
	pcall(function()
		for player in pairs(table.clone(sessions)) do
			TrafficLogService.left(player)
		end
		if #queue == 0 or halted then
			return
		end
		flushing = true
		local deadline = os.clock() + (seconds or number("FlushSeconds", 0, 4))
		repeat
			TrafficLogService.pump()
			if #queue == 0 or halted then
				break
			end
			task.wait(0.05)
		until os.clock() >= deadline
	end)
end

function TrafficLogService.Start()
	if not active() then
		print(string.format("[Seed/TrafficLog] external traffic feed off (%s).",
			if setting("Enabled") ~= true then "TrafficLogConfig.Enabled is false" else "Studio"))
		return
	end
	Players.PlayerAdded:Connect(TrafficLogService.arrived)
	Players.PlayerRemoving:Connect(TrafficLogService.left)
	for _, player in ipairs(Players:GetPlayers()) do
		TrafficLogService.arrived(player)
	end
	game:BindToClose(function()
		TrafficLogService.shutdown()
	end)
	print("[Seed/TrafficLog] external traffic feed on.")
end

--==============================================================================
-- FOR SPECS AND FOR LOOKING
--==============================================================================
function TrafficLogService.health(): { [string]: any }
	local out: { [string]: any } = table.clone(stats) :: any
	local count = 0
	for _ in pairs(sessions) do
		count += 1
	end
	out.pending = #queue
	out.inFlight = inFlight
	out.sessions = count
	out.halted = halted
	out.active = active()
	return out
end

function TrafficLogService.useSender(fn: Sender?)
	senderOverride = fn
end

function TrafficLogService.configure(values: { [string]: any }?)
	overrides = values or {}
end

function TrafficLogService.useStaffCheck(fn: ((any) -> boolean)?)
	staffOverride = fn
end

function TrafficLogService.useStudio(value: boolean?)
	studioOverride = value
end

function TrafficLogService.useJoinData(fn: ((any) -> any)?)
	joinDataOverride = fn
end

function TrafficLogService.useWarn(fn: ((string) -> ())?)
	warnOverride = fn
end

function TrafficLogService.useClock(fn: (() -> number)?)
	clock = fn or os.clock
end

function TrafficLogService.useUtc(fn: (() -> number)?)
	utcMillis = fn or defaultUtc
end

function TrafficLogService.useAutoPump(on: boolean)
	autoPump = on
end

function TrafficLogService.reset()
	table.clear(sessions)
	departed = setmetatable({}, { __mode = "k" }) :: any
	table.clear(queue)
	table.clear(known)
	table.clear(lastWarned)
	table.clear(suppressed)
	for key in pairs(stats) do
		(stats :: any)[key] = 0
	end
	inFlight, pumping, flushing, halted = 0, false, false, nil
	table.clear(secretUrls)
end

return TrafficLogService
