--!nocheck
--==============================================================================
-- Steal a Seed :: InviteAudioSpec
--
-- The owner's ten Invite a Friend sounds (2026-10-06), by arithmetic and by
-- their own modules, in Edit:
--
--   1. the ids: exactly the owner's ten, each once, each a SoundKit cue on the
--      player's own bus (Settings' volume and mute), Volume only tuned
--   2. which moment plays which: send, joined, tick, badge, welcome, evolve, and
--      the four unlocks by the forms' rarities
--   3. the rules: a refreshed +1 INVITE is silent, at most three ticks in a row,
--      nothing over an unlock -- and an unlock stops any invite sound playing
--   4. INVITE FRIENDS with Roblox's dialog STUBBED (never opened from a test):
--      the send sound only when the dialog was allowed; the blocked notice
--      otherwise
--   5. the hatch reveal's fanfares exactly as they were committed
--   6. the wiring the scripts' source shows: where each is played
--
-- Not here, seen in Play instead: a clip actually loading and playing
-- (IsLoaded and a moving TimePosition), and nothing about how it sounds -- no
-- tool hears it.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local SoundKit = require(Shared.SoundKit)
local InviteSounds = require(Shared.InviteSounds)
local InviteSend = require(Shared.InviteSend)
local InviteRewards = require(Shared.InviteRewards)
local Notice = require(Shared.Notice)

local CONFIG = GameConfig.InviteRewards
local CUES = GameConfig.Sfx.Cues

local out = {}
local pass, fail = 0, 0
local function say(s)
	table.insert(out, s)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name, true)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, needle)
	return string.find(src, needle, 1, true) ~= nil
end

-- The owner's table (2026-10-06), word for word.
local OWNER = {
	{ "Send", "InviteSend", "rbxassetid://77331637660005" },
	{ "Joined", "InviteJoined", "rbxassetid://89247518748364" },
	{ "Tick", "InviteTick", "rbxassetid://83632422237204" },
	{ "BadgePop", "InviteBadgePop", "rbxassetid://91054387401588" },
	{ "Welcome", "InviteWelcome", "rbxassetid://111245625596729" },
	{ "Evolve", "InviteEvolve", "rbxassetid://118129555423964" },
	{ "UnlockEpic", "InviteUnlockEpic", "rbxassetid://70816923180534" },
	{ "UnlockLegendary", "InviteUnlockLegendary", "rbxassetid://79976838694273" },
	{ "UnlockMythic", "InviteUnlockMythic", "rbxassetid://88512685687885" },
	{ "UnlockSecret", "InviteUnlockSecret", "rbxassetid://116733502135083" },
}

local ok, err = pcall(function()
	--==========================================================================
	say("-- 1. the ids --")
	local count = 0
	for _ in pairs(CONFIG.Sounds) do
		count += 1
	end
	check(count == #OWNER, "InviteRewards.Sounds holds exactly ten sounds", count)
	for _, row in ipairs(OWNER) do
		local s = CONFIG.Sounds[row[1]]
		check(s ~= nil and s.Id == row[3] and type(s.Volume) == "number" and s.Volume > 0 and s.Volume <= 1,
			string.format("%s is the owner's %s, at Volume %s", row[1], row[3], s and tostring(s.Volume) or "?"),
			s and s.Id)
		local cue = CUES[row[2]]
		check(cue ~= nil and s ~= nil and cue.id == row[3] and cue.volume == s.Volume and SoundKit.has(row[2]),
			row[2] .. ": a SoundKit cue with that id and Volume (preloaded with every cue)")
		local bus = if row[1] == "Evolve" then "World" else "UI"
		check(cue ~= nil and cue.group == bus and cue.pitch == nil and cue.jitter == nil and cue.start == nil
				and cue.clip == nil,
			row[2] .. ": on the " .. bus .. " bus, never pitched, jittered or trimmed")
	end
	check(CUES.InviteEvolve.range == CONFIG.EvolveRange and CONFIG.EvolveRange >= 40 and CONFIG.EvolveRange <= 120,
		"the evolve carries " .. tostring(CONFIG.EvolveRange) .. " studs from the pedestal: the deck, not the map")
	-- No other cue uses one of these ids, and no invite cue uses another.
	local owners = {}
	for _, row in ipairs(OWNER) do
		owners[row[3]] = row[2]
	end
	local strays = {}
	for name, cue in pairs(CUES) do
		local id = cue.id
		if owners[id] and owners[id] ~= name then
			table.insert(strays, name)
		end
		if string.sub(name, 1, 6) == "Invite" and not owners[id] then
			table.insert(strays, name)
		end
	end
	check(#strays == 0, "the ten ids are the invite cues' alone, and the invite cues use only them",
		table.concat(strays, ", "))

	--==========================================================================
	say("-- 2. which moment plays which --")
	local want = { send = "InviteSend", joined = "InviteJoined", tick = "InviteTick", badge = "InviteBadgePop",
		welcome = "InviteWelcome", evolve = "InviteEvolve" }
	local same = true
	for moment, cue in pairs(want) do
		same = same and InviteSounds.Cues[moment] == cue
	end
	for moment in pairs(InviteSounds.Cues) do
		same = same and want[moment] ~= nil
	end
	check(same, "send, joined, tick, badge, welcome, evolve: each its own sound")
	local byForm = { "InviteUnlockEpic", "InviteUnlockLegendary", "InviteUnlockMythic", "InviteUnlockSecret" }
	for tier = 1, InviteRewards.Count do
		local r = InviteRewards.reward(tier)
		check(InviteSounds.unlockCue(r.rarity) == byForm[tier],
			string.format("%s (%s): its card enters with %s", r.name, r.rarity, byForm[tier]),
			InviteSounds.unlockCue(r.rarity))
	end

	--==========================================================================
	say("-- 3. the rules --")
	local s = InviteSounds.newState()
	check(InviteSounds.allow(s, "joined", 100) and not InviteSounds.allow(s, "joined", 100 + CONFIG.JoinedQuiet - 0.5)
			and InviteSounds.allow(s, "joined", 100 + CONFIG.JoinedQuiet * 2 + 1),
		"+1 INVITE sounds; the same notice refreshed soon after is silent; a later one sounds again")
	s = InviteSounds.newState()
	local ticks = 0
	for n = 0, 9 do
		if InviteSounds.allow(s, "tick", 200 + n * 0.15) then
			ticks += 1
		end
	end
	check(ticks == CONFIG.TickRun and CONFIG.TickRun == 3, "ten bar steps in a row: three ticks, then silent", ticks)
	check(InviteSounds.allow(s, "tick", 200 + 1.5 + CONFIG.TickQuiet + 0.1), "after a quiet spell the ticks come back")
	s = InviteSounds.newState()
	check(InviteSounds.allow(s, "unlock", 300), "an unlock always plays")
	local skipped = not InviteSounds.allow(s, "tick", 300.2) and not InviteSounds.allow(s, "badge", 300.5)
		and not InviteSounds.allow(s, "evolve", 301)
	check(skipped, "a tick, a badge pop or an evolve due while the unlock plays is skipped")
	check(InviteSounds.allow(s, "tick", 300 + InviteSounds.UnlockHold + 0.1)
			and InviteSounds.allow(s, "badge", 300 + InviteSounds.UnlockHold + 0.2),
		"and allowed again once the unlock has finished")
	-- The unlock stops any invite sound still playing (SoundKit stood in: no
	-- sound is made in Edit).
	local made, stopped = {}, {}
	local realPlay, realEmit = SoundKit.play, SoundKit.emit
	local function fake(cue)
		local f = { Parent = true, IsPlaying = true, Name = cue }
		function f.Stop(self)
			self.IsPlaying = false
			table.insert(stopped, self.Name)
		end
		table.insert(made, cue)
		return f
	end
	SoundKit.play = function(cue)
		return fake(cue)
	end
	SoundKit.emit = function(cue)
		return fake(cue)
	end
	local ok2, why = pcall(function()
		InviteSounds.play("joined")
		InviteSounds.emit("evolve", workspace)
		InviteSounds.play("unlock", "Legendary")
	end)
	SoundKit.play, SoundKit.emit = realPlay, realEmit
	check(ok2 and table.concat(made, ",") == "InviteJoined,InviteEvolve,InviteUnlockLegendary"
			and table.concat(stopped, ",") == "InviteJoined,InviteEvolve",
		"an unlock stops the +1 INVITE and the evolve still playing: only the unlock is heard",
		tostring(why or "") .. " made " .. table.concat(made, ",") .. " stopped " .. table.concat(stopped, ","))

	--==========================================================================
	say("-- 4. INVITE FRIENDS, the dialog stubbed --")
	local realHooks = { canSend = InviteSend.Hooks.canSend, prompt = InviteSend.Hooks.prompt }
	local realSounds, realPost = InviteSounds.play, Notice.post
	local prompted, played, posted = 0, {}, {}
	InviteSounds.play = function(moment)
		table.insert(played, moment)
	end
	Notice.post = function(post)
		table.insert(posted, post.title)
	end
	local okRun, runWhy = pcall(function()
		InviteSend.Hooks.canSend = function()
			return true
		end
		InviteSend.Hooks.prompt = function()
			prompted += 1
		end
		check(InviteSend.prompt() == true and prompted == 1 and table.concat(played, ",") == "send" and #posted == 0,
			"allowed: the dialog asked for once, invite_send plays, no notice", table.concat(played, ","))
		played, posted = {}, {}
		InviteSend.Hooks.canSend = function()
			return false
		end
		check(InviteSend.prompt() == false and prompted == 1 and #played == 0
				and posted[1] == CONFIG.Words.CantSend,
			"refused: no dialog, no invite_send, the blocked notice CAN'T SEND INVITES", posted[1])
		played, posted = {}, {}
		InviteSend.Hooks.canSend = function()
			error("CanSendGameInviteAsync failed")
		end
		check(InviteSend.prompt() == false and prompted == 1 and #played == 0 and posted[1] == CONFIG.Words.CantSend,
			"the check failing (as it does in Studio): the same blocked notice, silent")
		played, posted = {}, {}
		InviteSend.Hooks.canSend = function()
			return true
		end
		InviteSend.Hooks.prompt = function()
			error("PromptGameInvite failed")
		end
		check(InviteSend.prompt() == false and #played == 0 and posted[1] == CONFIG.Words.CantSend,
			"the dialog failing to open: blocked, and no send sound")
	end)
	InviteSend.Hooks.canSend, InviteSend.Hooks.prompt = realHooks.canSend, realHooks.prompt
	InviteSounds.play, Notice.post = realSounds, realPost
	check(okRun, "the stubbed presses ran", runWhy)

	--==========================================================================
	say("-- 5. the hatch reveal's fanfares, as committed --")
	local committed = {
		RevealCommon = { "rbxassetid://74338267139417", 4.45 },
		RevealRare = { "rbxassetid://99776609601370", 0.42 },
		RevealEpic = { "rbxassetid://83653226797020", 1.52 },
		RevealLegendary = { "rbxassetid://73136314922937", 0.64 },
		RevealAccentRare = { "rbxassetid://75401177703541", 0.55 },
	}
	for name, row in pairs(committed) do
		local cue = CUES[name]
		check(cue ~= nil and cue.id == row[1] and cue.volume == row[2], name .. " unchanged", cue and cue.id)
	end
	local reveal = GameConfig.Sfx.RevealFor
	check(reveal.Epic == "RevealEpic" and reveal.Legendary == "RevealLegendary" and reveal.Mythic == "RevealLegendary"
			and reveal.Secret == "RevealLegendary" and GameConfig.Sfx.RevealAccentFor.Rare == "RevealAccentRare",
		"the hatch still picks its fanfare by rarity as it did")
	local hatch = sourceOf(StarterPlayer, "HatchFX")
	check(not has(hatch, "InviteUnlock") and not has(hatch, "InviteSounds"),
		"the hatch reveal plays none of the invite sounds")

	--==========================================================================
	say("-- 6. where each is played --")
	local ui = sourceOf(StarterPlayer, "InviteUI")
	local reward = sourceOf(StarterPlayer, "InviteRewardUI")
	local hub = sourceOf(StarterPlayer, "InviteHub")
	local send = sourceOf(Shared, "InviteSend")
	local snd = sourceOf(Shared, "InviteSounds")
	local server = sourceOf(ServerScriptService, "InviteService")
	check(has(send, 'InviteSounds.play("send")') and has(send, "if opened then"),
		"invite_send: only when the dialog was allowed to open (InviteSend)")
	local joined = InviteRewards.notice({ kind = "joined", name = "Fern", count = 1 })
	check(has(ui, "local words = InviteRewards.notice(payload)") and has(ui, "quiet = words.quiet }, words.sound)")
			and joined.key == "InviteJoined" and joined.quiet and joined.sound == "joined" and joined.title == "+1 INVITE",
		"invite_friend_joined: with +1 INVITE, one key so a quick second is the same notice refreshed")
	check(has(ui, 'InviteSounds.play, "tick"') and has(hub, 'InviteSounds.play, "tick"') and has(hub, "signInView()"),
		"invite_progress_tick: the panel's bar while open, the hub sign's while in view")
	check(has(ui, 'InviteSounds.play("badge")') and has(ui, "granted > state.badgeBase")
			and has(ui, "os.clock() - state.readyAt > BANG.QuietAfterJoin"),
		"invite_badge_pop: only when the \"!\" comes up for a form given while playing")
	local welcome = InviteRewards.notice({ kind = "welcome", name = "Hostess" })
	check(has(ui, "if welcomed then") and welcome.sound == "welcome" and welcome.quiet
			and has(server, 'tell(joiner, { kind = "welcome", name = nameOf(inviter) })'),
		"invite_welcome: the invited friend's WELCOME!, once")
	check(has(hub, 'InviteSounds.emit("evolve", holder)'), "invite_evolve: in the world, on the pedestal's burst")
	check(has(reward, 'InviteSounds.play("unlock", c.rarity)') and not has(reward, "RevealFor")
			and not has(reward, "RevealLegendary"),
		"invite_unlock_<rarity>: the reward card's entrance, in place of a hatch fanfare")
	check(has(snd, 'if moment == "unlock" then\n\t\thush()'), "an unlock hushes the others first")
	check(has(server, "elseif action == CONFIG.ReadyAction then") and has(server, "listening[player]"),
		"nothing said before a client listens is lost: held until its READY")
end)

if not ok then
	fail += 1
	say("  FAIL  THREW: " .. tostring(err))
end
say(string.format("InviteAudioSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
