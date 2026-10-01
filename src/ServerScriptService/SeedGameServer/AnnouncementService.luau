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
-- sender against its allowlist and its one-a-second limit, and only then calls
-- Send. Nothing else reaches Send -- no remote of this service's own exists.
-- Send then checks, in order, before anything is shown:
--
--   1. THIS SERVER ("server") or ALL SERVERS ("all"); "all" only confirmed
--   2. the words: text, trimmed, not empty, at most MaxChars characters
--   3. the cooldown: one announcement per admin every CooldownSeconds,
--      started by an announcement that goes out
--   4. Roblox's text filter, for public display (GetNonChatStringForBroadcast)
--      -- a filter that fails, or leaves nothing but #s, sends NOTHING
--
-- Then it is shown here at once (the Workspace attributes every client reads),
-- and for ALL SERVERS published once through MessagingService with an id, the
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

-- Server only. Exposed so AnnouncementSpec can shorten the cooldown.
AnnouncementService.Config = {
	CooldownSeconds = 15,
	-- A cross-server announcement older than this is dropped on arrival.
	TtlSeconds = 60,
	-- Clock skew allowed between two servers' idea of "now".
	SkewSeconds = 30,
	Topic = "SeedAnnouncements",
	SubscribeTries = 3,
}

local serviceConnections: { RBXScriptConnection } = {}
local lastSent: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
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

local clock: () -> number = unixNow
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
-- SHOWING ONE, HERE
--==============================================================================
-- The sender's name before the id: the client chimes on a new id, and the
-- name and words it reads then must already be this announcement's.
local function showHere(id: string, text: string, from: string)
	board:SetAttribute(ATTR.From, from)
	board:SetAttribute(ATTR.Text, text)
	board:SetAttribute(ATTR.Until, Workspace:GetServerTimeNow() + ANNOUNCE.ShowSeconds)
	board:SetAttribute(ATTR.Id, id)
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
	local now = clock()
	local last = lastSent[sender]
	local cooldown = AnnouncementService.Config.CooldownSeconds
	if last and now - last < cooldown then
		return false, string.format("Wait %d s before another announcement.", math.ceil(cooldown - (now - last)))
	end

	local userId = 0
	pcall(function()
		userId = sender.UserId
	end)
	local okFilter, filtered = filter(words, userId)
	if not okFilter or type(filtered) ~= "string" then
		warn("[Seed/AnnouncementService] the text filter failed; nothing was announced: " .. tostring(filtered))
		return false, "Roblox's text filter couldn't check the message, so nothing was sent."
	end
	local shown = clean(filtered) or ""
	if (string.gsub(shown, "[#%s]", "")) == "" then
		return false, "Roblox's text filter blocked this message. Nothing was sent."
	end
	-- The cooldown starts with an announcement that is going out: a filter that
	-- failed or blocked it costs no wait (AdminService's one request a second
	-- still paces the filter).
	lastSent[sender] = now

	local id = HttpService:GenerateGUID(false)
	local from = senderName(sender)
	seen[id] = now + AnnouncementService.Config.TtlSeconds
	forgetOld(now)
	showHere(id, shown, from)
	if scope == "server" then
		log(string.format("announcement %s shown in this server (%d characters).", id, utf8.len(shown) or 0))
		return true, "Shown to everyone in this server.", id
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
		return false, "Shown in THIS server only: sending to other servers failed (" .. tostring(err) .. ").", id
	end
	log(string.format("announcement %s shown here and published to every server (best-effort).", id))
	return true, "Shown here and sent to the other servers. Delivery to every server is best-effort, not guaranteed.",
		id
end

--==============================================================================
-- RECEIVE: one MessagingService message's Data, from any server
--
-- "shown", or why not: "invalid", "duplicate", "expired". Nothing about it is
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
	seen[id] = expiresAt
	forgetOld(now)
	showHere(id, words, from)
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
		lastSent[player] = nil
	end))
	-- Never waited for in Start.
	task.spawn(subscribe)
	log("Ready. Announcements from the admin console; restart notices from ServerRestartScheduled.")
end

return AnnouncementService
