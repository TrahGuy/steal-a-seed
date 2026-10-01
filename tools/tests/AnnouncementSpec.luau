--!nocheck
--==============================================================================
-- Steal a Seed :: AnnouncementSpec
--
-- ADMIN ANNOUNCEMENTS AND RESTART NOTICES (2026-10-01, the owner's brief).
-- Edit mode: the REAL AnnouncementService behind the REAL AdminService.Handle,
-- with a stand-in text filter, a FAKE messaging publisher (nothing reaches
-- MessagingService), a moved clock, and a fixture folder in place of Workspace
-- for the published notice. The owner's checks:
--
--   authorization     only the allowlist reaches Send, a forged name included
--   filtering         a filter that fails or blocks sends nothing anywhere
--   cooldown          one announcement per admin per CooldownSeconds
--   duplicates        an id is shown once, this server's own included;
--                     expired and malformed cross-server messages are dropped
--   restart notice    the custom message or the default, the time, the
--                     countdown wording, and text that stays text
--
-- Not here: real delivery between servers, a real restart, and the banner on
-- a screen -- the Play check covers the banner and a late join.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Announce = require(Server:WaitForChild("AnnouncementService"))
local Admin = require(Server:WaitForChild("AdminService"))

local A = GameConfig.Announce
local ATTR = A.Attributes
-- The allowlisted ids appear only on stand-in tables, as in AdminSpec.
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

local board = Instance.new("Folder")
board.Name = "AnnouncementSpecBoard"
board.Parent = game:GetService("ServerStorage")

local now = 1_000_000
local filterCalls, filterMode = {}, "pass"
local published = {}
local publishWorks = true
local realInterval = Admin.Config.MinInterval

local ok, err = pcall(function()
	Announce.Init()
	Announce.useBoard(board)
	Announce.useClock(function()
		return now
	end)
	Announce.useFilter(function(text, userId)
		table.insert(filterCalls, { text = text, userId = userId })
		if filterMode == "fail" then
			return false, "HTTP 503 (spec)"
		elseif filterMode == "block" then
			return true, string.rep("#", #text)
		end
		return true, text
	end)
	Announce.usePublisher(function(topic, payload)
		table.insert(published, { topic = topic, payload = payload })
		if publishWorks then
			return true, nil
		end
		return false, "spec publish failure"
	end)
	Admin.Config.MinInterval = 0

	local function person(id, name)
		return { UserId = id, Name = name }
	end
	local function send(who, scope, text, confirmed)
		return Admin.Handle(who, "Announce", scope, text, confirmed)
	end

	--==========================================================================
	-- 1. WHO MAY
	--==========================================================================
	say("-- who may --")
	local stranger = person(77, "Stranger")
	-- An allowlisted stand-in's name on a stranger's id: names grant nothing.
	local forged = person(78, "SpecAdminA")
	local r = send(stranger, "server", "free robux here")
	local r2 = send(forged, "all", "free robux here", true)
	check(not r.ok and r.message == "Not authorized." and not r2.ok and r2.message == "Not authorized."
			and #filterCalls == 0 and #published == 0 and board:GetAttribute(ATTR.Text) == nil,
		"anybody off the allowlist -- a borrowed name included -- is refused before the filter, the publisher or the "
			.. "screen", r.message)
	local adminA = person(ADMIN_A, "SpecAdminA")
	r = send(adminA, "server", "  Welcome to the\nupdate!  ")
	check(r.ok and r.message == "Shown to everyone in this server." and board:GetAttribute(ATTR.Text) == "Welcome to the update!"
			and #published == 0,
		"an admin's THIS SERVER message is shown here, on one tidy line, and published nowhere", r.message)
	local untilAt = board:GetAttribute(ATTR.Until)
	check(type(untilAt) == "number" and math.abs(untilAt - (Workspace:GetServerTimeNow() + A.ShowSeconds)) < 2
			and filterCalls[1].userId == ADMIN_A and filterCalls[1].text == "Welcome to the update!",
		"for ShowSeconds, after the filter saw the cleaned words with the admin's UserId")

	--==========================================================================
	-- 2. THE WORDS
	--==========================================================================
	say("\n-- the words --")
	now += 100
	local adminB = person(ADMIN_B, "SpecAdminB")
	local before = #filterCalls
	local bad = {}
	for _, case in ipairs({
		{ "", "empty" }, { "   \n\t ", "blank" }, { 42, "a number" }, { { "x" }, "a table" },
		{ string.rep("a", A.MaxChars + 1), "181 characters" },
	}) do
		local reply = send(adminB, "server", case[1])
		if reply.ok then
			table.insert(bad, case[2])
		end
	end
	local scoped = send(adminB, "everyone", "hello")
	local unconfirmed = send(adminB, "all", "hello", nil)
	check(#bad == 0 and not scoped.ok and not unconfirmed.ok and #filterCalls == before and #published == 0,
		"empty, blank, not text, over 180, an unknown scope and an unconfirmed ALL SERVERS are refused before "
			.. "the filter", table.concat(bad, ", "))
	check(string.find(send(adminB, "server", string.rep("é", A.MaxChars + 1)).message, "181", 1, true) ~= nil,
		"the limit counts characters, not bytes, and says how long it was")
	r = send(adminB, "server", string.rep("é", A.MaxChars))
	check(r.ok, "exactly 180 characters goes", r.message)

	--==========================================================================
	-- 3. THE FILTER
	--==========================================================================
	say("\n-- the filter --")
	now += 100
	local adminC = person(ADMIN_A, "SpecAdminA2")
	local shownBefore = board:GetAttribute(ATTR.Id)
	filterMode = "fail"
	r = send(adminC, "all", "the filter is down", true)
	check(not r.ok and string.find(r.message, "nothing was sent", 1, true) ~= nil
			and board:GetAttribute(ATTR.Id) == shownBefore and #published == 0,
		"a filter that fails: nothing shown here, nothing published", r.message)
	filterMode = "block"
	r = send(adminC, "all", "something rude", true)
	check(not r.ok and string.find(r.message, "blocked", 1, true) ~= nil
			and board:GetAttribute(ATTR.Id) == shownBefore and #published == 0,
		"a filter that leaves only #s: nothing shown, nothing published", r.message)
	filterMode = "pass"
	r = send(adminC, "server", "after the outage")
	check(r.ok, "and neither started the cooldown: the next good message goes at once", r.message)

	--==========================================================================
	-- 4. THE COOLDOWN
	--==========================================================================
	say("\n-- the cooldown --")
	now += 5
	r = send(adminC, "server", "too soon")
	check(not r.ok and string.find(r.message, "Wait 10 s", 1, true) ~= nil and board:GetAttribute(ATTR.Text) == "after the outage",
		"five seconds later the same admin waits ten more", r.message)
	local other = person(ADMIN_B, "SpecAdminB2")
	check(send(other, "server", "the other admin").ok, "another admin is not held by it")
	now += Announce.Config.CooldownSeconds
	check(send(adminC, "server", "now it goes").ok, "and after the cooldown it goes")

	--==========================================================================
	-- 5. ALL SERVERS
	--==========================================================================
	say("\n-- all servers --")
	now += 100
	r = send(adminA, "all", "Double cash this weekend", true)
	local sent = published[#published]
	check(r.ok and #published == 1 and sent.topic == Announce.Config.Topic and type(sent.payload.id) == "string"
			and sent.payload.text == "Double cash this weekend" and sent.payload.sentAt == now
			and sent.payload.expiresAt == now + Announce.Config.TtlSeconds,
		"confirmed, it is published once: an id, the filtered words, when it was sent and when it stops mattering")
	check(board:GetAttribute(ATTR.Id) == sent.payload.id and string.find(r.message, "best-effort", 1, true) ~= nil,
		"shown here at once, and the reply never claims every server got it", r.message)
	check(Announce.Receive(sent.payload) == "duplicate",
		"when it comes back through this server's own subscription it is not shown twice")
	now += 100
	publishWorks = false
	r = send(adminA, "all", "Publishing is down", true)
	publishWorks = true
	check(not r.ok and string.find(r.message, "THIS server only", 1, true) ~= nil
			and board:GetAttribute(ATTR.Text) == "Publishing is down",
		"a publish that fails is said plainly: shown in this server only", r.message)
	local audit = Admin.Audit()
	check(audit[#audit].action == "Announce:all:here-only", "and the admin log records it as here-only", audit[#audit].action)

	--==========================================================================
	-- 6. ARRIVING FROM ANOTHER SERVER
	--==========================================================================
	say("\n-- arriving from another server --")
	local fresh = { id = "1F2E3D4C-0000-4000-8000-ABCDEF012345", text = "From\tanother server", from = "Other Admin",
		sentAt = now - 2, expiresAt = now + 58 }
	check(Announce.Receive(fresh) == "shown" and board:GetAttribute(ATTR.Text) == "From another server",
		"a valid one is shown, on one line")
	check(Announce.Receive(fresh) == "duplicate", "the same id again is not")
	check(Announce.Receive({ id = "OLD0000000000001", text = "late", from = "Other Admin", sentAt = now - 70,
		expiresAt = now - 10 }) == "expired",
		"one past its expiry is dropped")
	local malformed = {
		"just a string", 42,
		{ text = "no id", sentAt = now, expiresAt = now + 30 },
		{ id = "bad id with spaces!", text = "x", sentAt = now, expiresAt = now + 30 },
		{ id = "ABCDEFGH12345678", text = 7, sentAt = now, expiresAt = now + 30 },
		{ id = "ABCDEFGH12345679", text = "", sentAt = now, expiresAt = now + 30 },
		{ id = "ABCDEFGH12345680", text = string.rep("x", 300), sentAt = now, expiresAt = now + 30 },
		{ id = "ABCDEFGH12345681", text = "x", sentAt = "now", expiresAt = now + 30 },
		{ id = "ABCDEFGH12345682", text = "x", sentAt = now, expiresAt = now + 3600 },
		{ id = "ABCDEFGH12345683", text = "x", sentAt = now + 600, expiresAt = now + 630 },
		{ id = "ABCDEFGH12345684", text = "x", sentAt = 0 / 0, expiresAt = now + 30 },
	}
	local let = {}
	for i, data in ipairs(malformed) do
		if Announce.Receive(data) ~= "invalid" then
			table.insert(let, tostring(i))
		end
	end
	check(#let == 0 and board:GetAttribute(ATTR.Text) == "From another server",
		"malformed ones -- no table, no id, a bad id, no text, too long, bad times, too long a life, from the future, "
			.. "NaN -- are dropped and change nothing", table.concat(let, ","))

	--==========================================================================
	-- 7. A SCHEDULED RESTART
	--==========================================================================
	say("\n-- a scheduled restart --")
	local function scheduled(seconds, attributes)
		Announce.OnRestartScheduled(DateTime.fromUnixTimestampMillis((now + seconds) * 1000),
			Enum.CloseReason.DeveloperUpdate, attributes)
		return board:GetAttribute(ATTR.RestartTitle), board:GetAttribute(ATTR.RestartAt) - Workspace:GetServerTimeNow()
	end
	local title, left = scheduled(300, { message = "Guardian fixes" })
	check(title == "SERVER UPDATE — Guardian fixes" and math.abs(left - 300) < 2,
		"the custom message: SERVER UPDATE — Guardian fixes, five minutes out", string.format("%q %.1f", title, left))
	check(GameConfig.restartCountdown(left) == "Restarting in 05:00" or GameConfig.restartCountdown(left) == "Restarting in 04:59",
		"counted down as Restarting in 05:00", GameConfig.restartCountdown(left))
	local defaults = true
	for _, attributes in ipairs({ {}, { message = 42 }, { message = "   " }, { message = { "x" } } }) do
		if scheduled(120, attributes) ~= A.RestartDefault then
			defaults = false
		end
	end
	check(defaults and scheduled(120, nil) == "Server restarting for an update.",
		"no message, a number, blanks, a table or no payload at all: Server restarting for an update.")
	check(scheduled(60, { message = "Line one\nline two" }) == "SERVER UPDATE — Line one line two",
		"a message is one line of plain text")
	local long = scheduled(60, { message = string.rep("ü", 200) })
	check(utf8.len(long) == utf8.len(A.RestartLead) + A.RestartMaxChars + 1 and string.sub(long, -3) == "…",
		"cut to RestartMaxChars on a character, with an ellipsis", utf8.len(long))
	check(scheduled(60, { message = "require(game.ServerStorage.Kick)" })
			== "SERVER UPDATE — require(game.ServerStorage.Kick)",
		"words that look like code are only words")
	Announce.OnRestartScheduled(nil, Enum.CloseReason.DeveloperUpdate, { message = "No time" })
	local shortly = board:GetAttribute(ATTR.RestartAt) - Workspace:GetServerTimeNow()
	check(math.abs(shortly) < 2 and GameConfig.restartCountdown(shortly - 0.5) == "Restarting shortly…",
		"no usable time: shown as Restarting shortly…")
	check(GameConfig.restartCountdown(61.2) == "Restarting in 01:02" and GameConfig.restartCountdown(0) == "Restarting shortly…"
			and GameConfig.restartCountdown(-30) == "Restarting shortly…" and GameConfig.restartCountdown(0 / 0) == "Restarting shortly…",
		"the countdown rounds up, and from zero on says shortly -- never that it happened")

	--==========================================================================
	-- 8. WHO SAID IT (follow-up, 2026-10-01): the sender's DisplayName, read off
	-- the authorized Player on the server, carried to every server
	--==========================================================================
	say("\n-- who said it --")
	now += 100
	local named = { UserId = ADMIN_A, Name = "specadmin_a", DisplayName = "Spec Admin" }
	r = Admin.Handle(named, "Announce", "server", "Hello from the owner", false, "Somebody Else")
	check(r.ok and board:GetAttribute(ATTR.From) == "Spec Admin" and board:GetAttribute(ATTR.Text) == "Hello from the owner",
		"the banner names the sender by the DisplayName on their Player -- an extra name in the request is ignored",
		board:GetAttribute(ATTR.From))
	now += 100
	r = Admin.Handle(named, "Announce", "all", "Hello every server", true)
	check(r.ok and published[#published].payload.from == "Spec Admin",
		"and every server is sent that same name with the words")
	check(Announce.SenderName({ Name = "fallback_name", DisplayName = "" }) == "fallback_name"
			and Announce.SenderName({ Name = "fallback_name", DisplayName = string.rep("x", A.MaxNameChars + 1) })
				== "fallback_name"
			and Announce.SenderName({ Name = "two\nlines", DisplayName = "Line\none" }) == "Line one",
		"an unusable DisplayName falls back to the username; a name is one line of plain text")
	local arrivals = {
		{ from = nil, want = "invalid" }, { from = 7, want = "invalid" }, { from = "", want = "invalid" },
		{ from = string.rep("n", A.MaxNameChars + 1), want = "invalid" }, { from = "Far Admin", want = "shown" },
	}
	local wrong = {}
	for i, case in ipairs(arrivals) do
		local got = Announce.Receive({ id = string.format("NAMECASE%08d", i), text = "hello", from = case.from,
			sentAt = now, expiresAt = now + 30 })
		if got ~= case.want then
			table.insert(wrong, string.format("%d:%s", i, got))
		end
	end
	check(#wrong == 0 and board:GetAttribute(ATTR.From) == "Far Admin",
		"an arriving broadcast must carry a usable name -- none, a number, blank or too long is dropped",
		table.concat(wrong, ","))
	local restartBefore = board:GetAttribute(ATTR.RestartTitle)
	scheduled(300, {})
	check(board:GetAttribute(ATTR.RestartTitle) == A.RestartDefault and restartBefore ~= nil
			and not string.find(board:GetAttribute(ATTR.RestartTitle), "Admin", 1, true),
		"a restart notice is still Roblox's: no admin's name on it")

	--==========================================================================
	-- 9. ONE CHIME A BROADCAST
	--==========================================================================
	say("\n-- one chime a broadcast --")
	local heard = {}
	local first = GameConfig.announceChime(heard, "AAAA0001", false)
	local again = GameConfig.announceChime(heard, "AAAA0001", false)
	local second = GameConfig.announceChime(heard, "AAAA0002", false)
	check(first and not again and second, "a new broadcast chimes once; the same id never again; the next one does")
	local joiner = {}
	local atStart = GameConfig.announceChime(joiner, "AAAA0003", true)
	local later = GameConfig.announceChime(joiner, "AAAA0003", false)
	check(not atStart and not later, "one already up when the client starts is read in silence, and stays silent")
	check(not GameConfig.announceChime({}, nil, false) and not GameConfig.announceChime({}, "", false)
			and not GameConfig.announceChime({}, 42, false), "nothing that is not an id chimes")
	local untilBefore = board:GetAttribute(ATTR.Until)
	local idBefore = board:GetAttribute(ATTR.Id)
	local echo = Announce.Receive({ id = idBefore, text = "hello", from = "Far Admin", sentAt = now, expiresAt = now + 30 })
	check(echo == "duplicate" and board:GetAttribute(ATTR.Until) == untilBefore and board:GetAttribute(ATTR.Id) == idBefore,
		"a duplicate delivery touches nothing a client watches, so nothing can replay")
	local cue = GameConfig.Sfx.Cues[A.Chime]
	local info = GameConfig.Sfx.Cues.NoticeInfo
	check(A.Chime == "AdminBroadcast" and cue and cue.id == "rbxassetid://119120354459025" and cue.group == "UI"
			and type(cue.volume) == "number" and cue.volume > 0 and cue.volume <= 1,
		"the chime is the owner's own sound, on the UI bus the player's SOUND FX setting controls")
	check(info and info.id == "rbxassetid://80357294905654" and info.volume == 0.47,
		"and the notices keep their own information ping, unchanged")

	--==========================================================================
	-- 10. THE WIRING A STAND-IN CANNOT REACH
	--==========================================================================
	say("\n-- wiring --")
	local service = Server.AnnouncementService.Source
	local ui = StarterPlayer.StarterPlayerScripts:FindFirstChild("AnnouncementUI").Source
	check(string.find(service, "if RunService:IsStudio() then\n\t\treturn false, \"publishing is off in Studio", 1, true) ~= nil
			and string.find(service, "ServerRestartScheduled", 1, true) ~= nil
			and string.find(service, "TeleportService", 1, true) == nil and string.find(service, ":Kick(", 1, true) == nil,
		"Studio never publishes to live servers; the restart is only listened to -- no teleport, no kick")
	check(string.find(ui, "label.RichText = false", 1, true) ~= nil and string.find(ui, "gui.ResetOnSpawn = false", 1, true) ~= nil
			and string.find(ui, "-- silence: the chime is for a broadcast arriving, not for joining.\nrefresh()\nstarting = false",
				1, true) ~= nil
			and string.find(ui, "loadstring", 1, true) == nil and string.find(service, "loadstring", 1, true) == nil,
		"the banner is plain text, survives a respawn, and reads what is already up when it starts")
	check(string.find(ui, "Active = true", 1, true) == nil and string.find(ui, "TextButton", 1, true) == nil,
		"and nothing in it takes input")
	local _, plays = string.gsub(ui, "SoundKit%.play%(", "")
	check(plays == 1 and string.find(ui, "if GameConfig.announceChime(heard, Workspace:GetAttribute(ATTR.Id), starting) then\n"
			.. "\t\t\tSoundKit.play(ANNOUNCE.Chime)", 1, true) ~= nil,
		"the banner plays one sound, only where announceChime says a new broadcast arrived")
	check(string.find(ui, "broadcast.BackgroundTransparency = 1", 1, true) ~= nil
			and string.find(ui, "block.BackgroundTransparency = 1", 1, true) ~= nil
			and string.find(ui, "local FACE = Enum.Font.FredokaOne", 1, true) ~= nil
			and string.find(ui, "label.Font = FACE\n\tlabel.TextSize = style.size", 1, true) ~= nil
			and string.find(ui, "restartFrame.BackgroundTransparency = 0.25", 1, true) ~= nil
			and string.find(ui, "TweenService", 1, true) == nil and string.find(ui, "RenderStepped", 1, true) == nil,
		"a broadcast is one panel-less line in one rounded face and size; the restart notice keeps its plate")
	check(string.find(ui, "if not StatusText.reducedMotion() then", 1, true) ~= nil
			and string.find(ui, "fill.Color = RAINBOW", 1, true) ~= nil
			and string.find(ui, "glowRainbow.Color = RAINBOW", 1, true) ~= nil
			and string.find(ui, "run(row, \"Colon\", \":\", 2)", 1, true) ~= nil,
		"the name's rainbow and its glow drift together, and stand still under reduced motion; the colon is plain")
end)

Announce.useBoard(nil)
Announce.useClock(nil)
Announce.useFilter(nil)
Announce.usePublisher(nil)
Announce.Init()
Admin.Config.MinInterval = realInterval
board:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nAnnouncementSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
