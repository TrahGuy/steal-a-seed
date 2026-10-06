--!strict
-- Steal a Seed :: AnnouncementService
--
-- ADMIN ANNOUNCEMENTS AND ROBLOX'S RESTART NOTICES (2026-10-01, the owner's
-- brief; GameConfig.Announce)
--
--==============================================================================
-- AN ANNOUNCEMENT
--
-- Asked for through the admin console only: AdminService.Handle checks the
-- sender against its allowlist, and only then calls Send. Nothing else reaches
-- Send -- no remote of this service's own exists. Send then checks, in order,
-- before anything is shown:
--
--   1. THIS SERVER ("server") or ALL SERVERS ("all"); "all" only confirmed
--   2. the words: text, trimmed, not empty, at most MaxChars characters
--   3. the SAFEGUARDS (2026-10-03), which replaced the old 15-second wait
--      between one admin's announcements -- none of them holds up an admin
--      sending one announcement after another:
--        * the same words to the same scope again within DuplicateSeconds
--          (a double press, a resend) are not sent twice
--        * a burst of Burst announcements, then one more every RefillSeconds
--          (a forged client flooding the remote; the filter's and
--          MessagingService's own limits are far above that)
--        * no more than MaxWaiting announcements waiting to be shown here
--   4. Roblox's text filter, for public display (GetNonChatStringForBroadcast)
--      -- a filter that fails, or leaves nothing but #s, sends NOTHING
--
-- Then it joins this server's QUEUE (2026-10-03): announcements are shown one
-- after another in the order they were accepted, never one over another. The
-- one up stays at least MinShowSeconds before the next takes its place; the
-- last one in the queue stays ShowSeconds. The queue -- each one's words,
-- sender and start and end, in server time -- is published as one Workspace
-- attribute every client reads, so every screen and every late joiner shows
-- the same one at the same moment. The single-slot attributes (Id, Text,
-- From, Until) still name the newest. For ALL SERVERS it is also published
-- once through MessagingService with an id, the
-- filtered words, the sender's DisplayName (read off their Player, never sent
-- by a client), when it was sent and when it stops mattering. Every server
-- -- this one too -- gets it back through its subscription: Receive validates
-- it, drops an id it has seen (so this server never shows it twice) and drops
-- one past its expiry. A publish is best-effort and the reply says so: it is
-- never reported as reaching every server.
--
-- IN STUDIO NOTHING IS PUBLISHED OR SUBSCRIBED. MessagingService from a Studio
-- session reaches the live game's servers; an ALL SERVERS test in Studio is
-- shown here and reported as not sent anywhere else.
--
--==============================================================================
-- A RESTART NOTICE
--
-- game.ServerRestartScheduled fires on the servers Roblox has scheduled for a
-- delayed restart (Creator Hub's server management, or Open Cloud), with the
-- restart's time, a CloseReason, and the custom JSON payload as a table. This
-- reads the payload's `message` -- a string, cleaned, cut to RestartMaxChars --
-- or uses RestartDefault, and publishes the title and the time on Workspace,
-- where a late joiner or a respawn reads them like everybody else. Nothing in
-- the payload is ever run, required or parsed: it is words in a TextLabel.
-- Roblox's own restart, its migration and SaveService's save on close are
-- untouched: this service kicks nobody, teleports nobody and restarts nothing.
--==============================================================================

local HttpService = game:GetService("HttpService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local ANNOUNCE = GameConfig.Announce
local ATTR = ANNOUNCE.Attributes

local AnnouncementService = {}
-- Before AdminService (95), whose console asks this.
AnnouncementService.Priority = 90

-- Server only. Exposed so AnnouncementSpec can tighten the safeguards.
AnnouncementService.Config = {
	-- THE SAFEGUARDS (2026-10-03; no wait between an admin's announcements).
	-- The same words, to the same scope, from the same admin, again within
	-- this long: a double press or a resend, answered without a second send.
	DuplicateSeconds = 10,
	-- Spam: this many announcements at once per admin, then one more every
	-- RefillSeconds (at most 20 a minute an admin, inside MessagingService's
	-- per-topic budget of 40 + 80 x servers a minute).
	Burst = 5,
	RefillSeconds = 3,
	-- At most this many accepted announcements waiting to be shown here.
	MaxWaiting = 6,
	-- A cross-server announcement older than this is dropped on arrival.
	TtlSeconds = 60,
	-- Clock skew allowed between two servers' idea of "now".
	SkewSeconds = 30,
	Topic = "SeedAnnouncements",
	SubscribeTries = 3,
}

local serviceConnections: { RBXScriptConnection } = {}
-- Per admin: the spam guard's bucket, and the words lately accepted (or on
-- their way through the filter) with when.
local buckets: { [any]: { tokens: number, at: number } } = setmetatable({}, { __mode = "k" }) :: any
local recent: { [any]: { [string]: number } } = setmetatable({}, { __mode = "k" }) :: any
-- Every announcement id this server has shown or sent, until it expires.
local seen: { [string]: number } = {}
local subscription: RBXScriptConnection? = nil

local function log(message: string)
	print("[Seed/AnnouncementService] " .. message)
end

--==============================================================================
-- THE SEAMS (Studio only), AND WHAT THEY STAND IN FOR
--==============================================================================
-- Unix seconds, the clock every server shares.
local function unixNow(): number
	return DateTime.now().UnixTimestampMillis / 1000
end

local function robloxFilter(text: string, userId: number): (boolean, string?)
	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, userId, Enum.TextFilterContext.PublicChat)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(result) == "string" then
		return true, result
	end
	return false, tostring(result)
end

local function robloxPublish(topic: string, payload: { [string]: any }): (boolean, string?)
	if RunService:IsStudio() then
		return false, "publishing is off in Studio, where it would reach the live game's servers"
	end
	local ok, err = pcall(function()
		MessagingService:PublishAsync(topic, payload)
	end)
	return ok, if ok then nil else tostring(err)
end

local function serverNow(): number
	return Workspace:GetServerTimeNow()
end

local clock: () -> number = unixNow
-- The clock the queue is scheduled on: the one every client reads.
local showClock: () -> number = serverNow
local filter: (string, number) -> (boolean, string?) = robloxFilter
local publish: (string, { [string]: any }) -> (boolean, string?) = robloxPublish
local board: Instance = Workspace

function AnnouncementService.useClock(fn: (() -> number)?): boolean
	if not RunService:IsStudio() then
		return false
	end
	clock = fn or unixNow
	return true
end

function AnnouncementService.useShowClock(fn: (() -> number)?): boolean
	if not RunService:IsStudio() then
		return false
	end
	showClock = fn or serverNow
	return true
end

function AnnouncementService.useFilter(fn: ((string, number) -> (boolean, string?))?): boolean
	if not RunService:IsStudio() then
		return false
	end
	filter = fn or robloxFilter
	return true
end

function AnnouncementService.usePublisher(fn: ((string, { [string]: any }) -> (boolean, string?))?): boolean
	if not RunService:IsStudio() then
		return false
	end
	publish = fn or robloxPublish
	return true
end

-- Where the notices are published: Workspace, or a spec's folder.
function AnnouncementService.useBoard(target: Instance?): boolean
	if not RunService:IsStudio() then
		return false
	end
	board = target or Workspace
	return true
end

--==============================================================================
-- WORDS
--==============================================================================
-- One line of plain text: control characters (newlines included) become
-- spaces, runs of spaces one, the ends trimmed. Nil for anything that is not a
-- string of valid UTF-8.
local function clean(value: any): string?
	if type(value) ~= "string" or #value > 4000 or utf8.len(value) == nil then
		return nil
	end
	local flat = string.gsub(value, "%c", " ")
	flat = string.gsub(flat, "%s+", " ")
	return string.match(flat, "^%s*(.-)%s*$") or ""
end
AnnouncementService.Clean = clean

-- At most `limit` characters, cut on a character, never inside one.
local function cut(text: string, limit: number): string
	local length = utf8.len(text) or 0
	if length <= limit then
		return text
	end
	-- The byte where character limit + 1 starts: everything before it is kept.
	local stop = utf8.offset(text, limit + 1) or (#text + 1)
	return string.sub(text, 1, stop - 1) .. "…"
end

--==============================================================================
-- SHOWING ONE, HERE: THE QUEUE (2026-10-03)
--
-- In the order accepted. A new one waits for the one before it, and the one
-- before it gives way once it has been up MinShowSeconds (at once if it has
-- already been up that long); the last stays ShowSeconds. Nothing is ever
-- drawn over another, and nothing is dropped once it is in.
--==============================================================================
type Entry = { id: string, text: string, from: string, startAt: number, endAt: number }
local queue: { Entry } = {}

local function trim(now: number)
	while queue[1] and queue[1].endAt <= now do
		table.remove(queue, 1)
	end
end

-- How many are accepted but not up yet, and how long until one of them is.
local function waiting(now: number): (number, number)
	local count, soonest = 0, math.huge
	for _, e in ipairs(queue) do
		if e.startAt > now then
			count += 1
			soonest = math.min(soonest, e.startAt - now)
		end
	end
	return count, if count > 0 then soonest else 0
end

local function publishQueue()
	local list = {}
	for _, e in ipairs(queue) do
		table.insert(list, { i = e.id, t = e.text, f = e.from, s = e.startAt, e = e.endAt })
	end
	board:SetAttribute(ATTR.Queue, HttpService:JSONEncode(list))
end

-- Queued, or false when MaxWaiting are already waiting. Also how many were
-- ahead of it and in how many seconds it comes up.
local function showHere(id: string, text: string, from: string): (boolean, number, number)
	local now = showClock()
	trim(now)
	local ahead = #queue
	if waiting(now) >= AnnouncementService.Config.MaxWaiting then
		return false, ahead, 0
	end
	local startAt = now
	local last = queue[#queue]
	if last then
		last.endAt = math.min(last.endAt, math.max(last.startAt + ANNOUNCE.MinShowSeconds, now))
		startAt = last.endAt
	end
	local entry = { id = id, text = text, from = from, startAt = startAt, endAt = startAt + ANNOUNCE.ShowSeconds }
	table.insert(queue, entry)
	publishQueue()
	-- The newest, on the single-slot attributes (the name before the id).
	board:SetAttribute(ATTR.From, from)
	board:SetAttribute(ATTR.Text, text)
	board:SetAttribute(ATTR.Until, entry.endAt)
	board:SetAttribute(ATTR.Id, id)
	return true, ahead, startAt - now
end

-- What is up or waiting, in order, for AnnouncementSpec.
function AnnouncementService.Queue(): { Entry }
	trim(showClock())
	local copy = {}
	for i, e in ipairs(queue) do
		copy[i] = table.clone(e)
	end
	return copy
end

-- A sender's name as shown: one line of plain text, 1 to MaxNameChars
-- characters. Nil for anything else.
local function nameOk(value: any): string?
	local name = clean(value)
	if name == nil or name == "" or (utf8.len(name) or 0) > ANNOUNCE.MaxNameChars then
		return nil
	end
	return name
end

--==============================================================================
-- WHO SENT IT: READ OFF THE AUTHORIZED PLAYER, NEVER ASKED FOR
--
-- The DisplayName the engine holds for the Player AdminService has already
-- checked against its allowlist -- not anything the console sends, which has
-- no slot for a name at all. Their username if the DisplayName is somehow
-- unusable. Shown as plain text, here and on every other server.
--==============================================================================
local function senderName(sender: any): string
	local display, username = nil, nil
	pcall(function()
		display = sender.DisplayName
	end)
	pcall(function()
		username = sender.Name
	end)
	return nameOk(display) or nameOk(username) or ANNOUNCE.Title
end
AnnouncementService.SenderName = senderName

local function forgetOld(now: number)
	for id, expires in pairs(seen) do
		if expires < now then
			seen[id] = nil
		end
	end
end

-- The spam guard's bucket: Burst at once, one more every RefillSeconds.
-- Whether one was taken, or how long until one can be.
local function takeToken(sender: any, now: number): (boolean, number)
	local cfg = AnnouncementService.Config
	local b = buckets[sender]
	if not b then
		b = { tokens = cfg.Burst, at = now }
		buckets[sender] = b
	end
	b.tokens = math.min(cfg.Burst, b.tokens + math.max(0, now - b.at) / cfg.RefillSeconds)
	b.at = now
	if b.tokens < 1 then
		return false, (1 - b.tokens) * cfg.RefillSeconds
	end
	b.tokens -= 1
	return true, 0
end

-- Where it stands in the queue, for the console's line.
local function queuedLine(ahead: number, startsIn: number): string
	if ahead <= 0 or startsIn <= 0.05 then
		return ""
	end
	return string.format(" Queued after %d earlier announcement%s; up in about %d s.", ahead, if ahead == 1 then "" else "s",
		math.ceil(startsIn))
end

--==============================================================================
-- SEND: reached only through AdminService.Handle, after its allowlist
--==============================================================================
-- Returns whether it all went through, the line the console shows, and the id
-- of the announcement if one was shown here at all.
function AnnouncementService.Send(sender: any, scope: any, text: any, confirmed: any): (boolean, string, string?)
	if scope ~= "server" and scope ~= "all" then
		return false, "Choose THIS SERVER or ALL SERVERS."
	end
	local words = clean(text)
	if words == nil then
		return false, "That message can't be sent: it isn't plain text."
	end
	if words == "" then
		return false, "Type a message first."
	end
	local length = utf8.len(words) or 0
	if length > ANNOUNCE.MaxChars then
		return false, string.format("Messages are limited to %d characters (this one is %d).", ANNOUNCE.MaxChars, length)
	end
	if scope == "all" and confirmed ~= true then
		return false, "Confirm ALL SERVERS first. Nothing was sent."
	end
	local cfg = AnnouncementService.Config
	local now = clock()
	-- THE SAFEGUARDS, before the filter is asked (see the top of this file).
	local mine = recent[sender]
	if not mine then
		mine = {}
		recent[sender] = mine
	end
	for k, at in pairs(mine) do
		if now - at >= cfg.DuplicateSeconds then
			mine[k] = nil
		end
	end
	local key = scope .. "\0" .. words
	if mine[key] then
		return false, "That exact message was just sent, so it wasn't sent again."
	end
	local backlog, freesIn = waiting(showClock())
	if backlog >= cfg.MaxWaiting then
		return false, string.format("%d announcements are already waiting to be shown. Try again in %d s. Nothing was sent.",
			backlog, math.max(1, math.ceil(freesIn)))
	end
	local okToken, wait = takeToken(sender, now)
	if not okToken then
		return false, string.format("Too many announcements at once. Try again in %d s. Nothing was sent.",
			math.max(1, math.ceil(wait)))
	end
	-- Held while the filter answers, so a resend in the meantime is caught.
	mine[key] = now

	local userId = 0
	pcall(function()
		userId = sender.UserId
	end)
	local okFilter, filtered = filter(words, userId)
	if not okFilter or type(filtered) ~= "string" then
		mine[key] = nil
		warn("[Seed/AnnouncementService] the text filter failed; nothing was announced: " .. tostring(filtered))
		return false, "Roblox's text filter couldn't check the message, so nothing was sent."
	end
	local shown = clean(filtered) or ""
	if (string.gsub(shown, "[#%s]", "")) == "" then
		mine[key] = nil
		return false, "Roblox's text filter blocked this message. Nothing was sent."
	end

	local id = HttpService:GenerateGUID(false)
	local from = senderName(sender)
	local queued, ahead, startsIn = showHere(id, shown, from)
	if not queued then
		-- Filled while the filter answered.
		mine[key] = nil
		return false, string.format("%d announcements are already waiting to be shown. Try again shortly. Nothing was sent.",
			cfg.MaxWaiting)
	end
	seen[id] = now + cfg.TtlSeconds
	forgetOld(now)
	local place = queuedLine(ahead, startsIn)
	if scope == "server" then
		log(string.format("announcement %s queued in this server (%d characters, %d ahead).", id, utf8.len(shown) or 0, ahead))
		return true, if place == "" then "Shown to everyone in this server." else "Accepted for everyone in this server." .. place,
			id
	end
	local okPublish, err = publish(AnnouncementService.Config.Topic, {
		id = id,
		text = shown,
		from = from,
		sentAt = now,
		expiresAt = now + AnnouncementService.Config.TtlSeconds,
	})
	if not okPublish then
		warn("[Seed/AnnouncementService] announcement " .. id .. " shown here, not published: " .. tostring(err))
		return false, "Shown in THIS server only: sending to other servers failed (" .. tostring(err) .. ")." .. place, id
	end
	log(string.format("announcement %s queued here and published to every server (best-effort).", id))
	return true, (if place == "" then "Shown here" else "Accepted here")
		.. " and sent to the other servers. Delivery to every server is best-effort, not guaranteed." .. place, id
end

--==============================================================================
-- RECEIVE: one MessagingService message's Data, from any server
--
-- "shown" (queued here), or why not: "invalid", "duplicate", "expired", or
-- "busy" when MaxWaiting are already waiting here. Nothing about it is
-- trusted -- the shape, the id, the text, the sender's name and both times are
-- checked here.
--==============================================================================
function AnnouncementService.Receive(data: any): string
	if type(data) ~= "table" then
		return "invalid"
	end
	local id, text, sentAt, expiresAt = data.id, data.text, data.sentAt, data.expiresAt
	if type(id) ~= "string" or #id < 8 or #id > 64 or not string.match(id, "^[%w%-]+$") then
		return "invalid"
	end
	local words = clean(text)
	if words == nil or words == "" or (utf8.len(words) or 0) > ANNOUNCE.MaxChars + 20 then
		return "invalid"
	end
	local from = nameOk(data.from)
	if not from then
		return "invalid"
	end
	if type(sentAt) ~= "number" or type(expiresAt) ~= "number" or sentAt ~= sentAt or expiresAt ~= expiresAt
		or expiresAt <= sentAt or expiresAt - sentAt > AnnouncementService.Config.TtlSeconds then
		return "invalid"
	end
	local now = clock()
	if sentAt > now + AnnouncementService.Config.SkewSeconds then
		return "invalid"
	end
	if now > expiresAt then
		return "expired"
	end
	if seen[id] then
		return "duplicate"
	end
	if not (showHere(id, words, from)) then
		return "busy"
	end
	seen[id] = expiresAt
	forgetOld(now)
	return "shown"
end

--==============================================================================
-- A SCHEDULED RESTART
--==============================================================================
function AnnouncementService.RestartTitle(attributes: any): string
	local message = if type(attributes) == "table" then clean(attributes.message) else nil
	if message == nil or message == "" then
		return ANNOUNCE.RestartDefault
	end
	return ANNOUNCE.RestartLead .. cut(message, ANNOUNCE.RestartMaxChars)
end

function AnnouncementService.OnRestartScheduled(restartTime: any, source: any, attributes: any)
	local now = clock()
	local at: number? = nil
	if typeof(restartTime) == "DateTime" then
		at = (restartTime :: DateTime).UnixTimestampMillis / 1000
	end
	-- A time that is not one, or absurdly far either way, is "shortly".
	if not (at and at == at and at > now - 3600 and at < now + 6 * 3600) then
		at = now
	end
	local title = AnnouncementService.RestartTitle(attributes)
	board:SetAttribute(ATTR.RestartTitle, title)
	board:SetAttribute(ATTR.RestartAt, Workspace:GetServerTimeNow() + ((at :: number) - now))
	log(string.format("restart scheduled in %d s (%s): %q", math.floor((at :: number) - now), tostring(source), title))
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local function subscribe()
	if RunService:IsStudio() then
		log("Studio: not subscribed to cross-server announcements.")
		return
	end
	for attempt = 1, AnnouncementService.Config.SubscribeTries do
		local ok, result = pcall(function()
			return MessagingService:SubscribeAsync(AnnouncementService.Config.Topic, function(message)
				local outcome = AnnouncementService.Receive(if type(message) == "table" then message.Data else nil)
				if outcome ~= "shown" and outcome ~= "duplicate" then
					warn("[Seed/AnnouncementService] dropped a cross-server announcement: " .. outcome)
				end
			end)
		end)
		if ok then
			subscription = result
			log("subscribed to cross-server announcements.")
			return
		end
		warn(string.format("[Seed/AnnouncementService] subscribe attempt %d failed: %s", attempt, tostring(result)))
		task.wait(5 * attempt)
	end
end

function AnnouncementService.Init()
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	local sub = subscription
	if sub then
		sub:Disconnect()
		subscription = nil
	end
	table.clear(seen)
	table.clear(queue)
	table.clear(buckets)
	table.clear(recent)
end

function AnnouncementService.Start()
	local ok, err = pcall(function()
		table.insert(serviceConnections, (game :: any).ServerRestartScheduled:Connect(
			function(restartTime: any, source: any, attributes: any)
				local done, why = pcall(AnnouncementService.OnRestartScheduled, restartTime, source, attributes)
				if not done then
					warn("[Seed/AnnouncementService] restart notice failed: " .. tostring(why))
				end
			end))
	end)
	if not ok then
		warn("[Seed/AnnouncementService] no ServerRestartScheduled here: " .. tostring(err))
	end
	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		buckets[player] = nil
		recent[player] = nil
	end))
	-- Never waited for in Start.
	task.spawn(subscribe)
	log("Ready. Announcements from the admin console; restart notices from ServerRestartScheduled.")
end

return AnnouncementService
