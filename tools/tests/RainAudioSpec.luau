--!nocheck
--==============================================================================
-- Steal a Seed :: RainAudioSpec
--
-- The Rain event's sounds (2026-10-02): the owner's four ids wired to their
-- triggers -- the rain's bed in Music.client's lists, the rain's loop, a
-- Thunderstorm's opening and its strikes in Weather.client, a catch's strike in
-- NestService -- on the buses the settings panel moves. Config, buses and
-- source wiring; whether the ids LOAD, and what plays in a running client, are
-- checked in Studio and in the guarded Play session. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("RainAudioSpec"))
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local SoundKit = require(Shared.SoundKit)

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
		say("  FAIL  " .. label .. (detail ~= nil and ("  <- " .. tostring(detail)) or ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function count(src, needle)
	local n, at = 0, 1
	while true do
		local i = string.find(src, needle, at, true)
		if not i then
			return n
		end
		n += 1
		at = i + #needle
	end
end

local MUSIC = GameConfig.Music
local CUES = GameConfig.Sfx.Cues
local AUDIO = GameConfig.Weather.Audio
local Scripts = StarterPlayer.StarterPlayerScripts
local Server = ServerScriptService.SeedGameServer

--==============================================================================
say("1. The four ids, on the rows that play them")
--==============================================================================
check(#MUSIC.RainTracks == 1 and MUSIC.RainTracks[1] == "rbxassetid://70930849303265",
	"the rain's bed is the Rain Event BGM (the group upload)", MUSIC.RainTracks[1])
local amb = CUES.RainAmbience
check(amb ~= nil and amb.id == "rbxassetid://138018201261517" and amb.looped == true and amb.group == "World"
	and amb.pitch == nil and amb.jitter == nil, "the rain's loop: its own id, looped, World bus, played at speed 1")
local open = CUES.ThunderstormOpening
check(open ~= nil and open.id == "rbxassetid://110362720818059" and open.looped ~= true and open.group == "World",
	"a Thunderstorm's opening: a one-shot on the World bus")
local clap, strike = CUES.ThunderClap, CUES.StormstriderStrike
check(clap ~= nil and strike ~= nil and clap.id == "rbxassetid://79835427265580" and strike.id == clap.id
	and clap.group == "World" and strike.group == "World" and clap.looped ~= true and strike.looped ~= true,
	"a weather strike and a catch's strike: the lightning recording, World bus, one-shots")
check(clap ~= nil and strike ~= nil and (clap.range or 0) >= 300 and (strike.range or 0) >= 200,
	"both fall off with distance over a sensible range", string.format("%s / %s", tostring(clap and clap.range), tostring(strike and strike.range)))
check(SoundKit.has("RainAmbience") and SoundKit.has("ThunderstormOpening") and SoundKit.has("ThunderClap")
	and SoundKit.has("StormstriderStrike"), "all four resolve in SoundKit")
check(CUES.ThunderstormBed == nil and AUDIO.ThunderstormBed == nil,
	"the old storm-only rain loop is gone: one rain loop, never two")
check(CUES.StormstriderHit ~= nil and CUES.StormstriderHit.id == "" and SoundKit.parentCue("rain", "Hit") == "ParentHit",
	"the catch's voice is unchanged: the Hit hook still waits, a catch keeps the generic claw")

--==============================================================================
say("2. Levels: conservative, the rain under the music")
--==============================================================================
local stormAmb = (amb and amb.volume or 1) * AUDIO.StormAmbience
check(type(AUDIO.StormAmbience) == "number" and AUDIO.StormAmbience > 1 and AUDIO.StormAmbience <= 1.5,
	"a Thunderstorm plays the same loop a little louder", AUDIO.StormAmbience)
check(stormAmb < MUSIC.Volume, "even a storm's rain sits under the music bed's level", stormAmb)
for _, name in ipairs({ "ThunderstormOpening", "ThunderClap", "StormstriderStrike" }) do
	local cue = CUES[name]
	check(cue ~= nil and type(cue.volume) == "number" and cue.volume > 0 and cue.volume <= 0.5,
		name .. " at a conservative level", cue and cue.volume)
end
check(type(MUSIC.RainFadeSeconds) == "number" and MUSIC.RainFadeSeconds >= 2 and MUSIC.RainFadeSeconds <= 8,
	"the rain's bed fades in and out gently", MUSIC.RainFadeSeconds)

--==============================================================================
say("3. The buses: MUSIC moves the bed only, SOUND FX moves the rain and the thunder")
--==============================================================================
local settingsSrc = sourceOf(Scripts, "SettingsUI")
check(string.find(settingsSrc, 'local FX_BUSES = { "Chase", "UI", "World" }', 1, true) ~= nil,
	"the SOUND FX control moves the World bus, which every rain and thunder cue rides")
local music, world = SoundKit.group("Music"), SoundKit.group("World")
local mLevel, mMuted = SoundKit.level("Music")
local wLevel, wMuted = SoundKit.level("World")
if music and world then
	SoundKit.setLevel("World", 1, false)
	SoundKit.setLevel("Music", nil, true)
	check(world.Volume > 0, "muting the music leaves the rain's loop and the thunder audible", world.Volume)
	SoundKit.setLevel("Music", nil, false)
	SoundKit.setLevel("World", nil, true)
	check(world.Volume == 0, "muting sound effects silences the rain and the thunder", world.Volume)
	SoundKit.setLevel("Music", mLevel, mMuted)
	SoundKit.setLevel("World", wLevel, wMuted)
else
	check(false, "the buses exist in Edit")
end

--==============================================================================
say("4. Music.client: the rain's bed in the one track, ahead of night and day, only while it can play")
--==============================================================================
local musicSrc = sourceOf(Scripts, "Music")
local rainAt = string.find(musicSrc, "if #rainTracks > 0 and rainOk ~= false and rainFalling() then", 1, true)
local nightAt = string.find(musicSrc, "if #nightTracks > 0", 1, true)
check(rainAt ~= nil and nightAt ~= nil and rainAt < nightAt,
	"listFor answers the rain's bed first while it falls (a storm at night is still a storm)")
check(string.find(musicSrc, 'return state == "opening" or state == "active"', 1, true) ~= nil
	and string.find(musicSrc, "Workspace:GetAttributeChangedSignal(WEATHER_STATE)", 1, true) ~= nil,
	"it follows the server's weather State -- in at the start, out the moment it starts closing, a late joiner on it")
check(count(musicSrc, 'Instance.new("Sound")') == 2 and string.find(musicSrc, "probe.Volume = 0", 1, true) ~= nil,
	"one track Sound per client (the other Sound is a silent load probe)")
check(string.find(musicSrc, "ContentProvider:PreloadAsync({ probe })", 1, true) ~= nil
	and string.find(musicSrc, "rainOk = loaded", 1, true) ~= nil,
	"an id that cannot load hands the music back to the day/night bed, never silence")
check(string.find(musicSrc, "RainFadeSeconds", 1, true) ~= nil and string.find(musicSrc, "PlaybackSpeed", 1, true) == nil,
	"the bed crossfades over its own fade and is never sped up or slowed")

--==============================================================================
say("5. Weather.client: one loop, one opening, one sound per strike")
--==============================================================================
local wsrc = sourceOf(Scripts, "Weather")
check(count(wsrc, "SoundKit.play(AUDIO.RainAmbience") == 1
	and string.find(wsrc, "local want = (cue.volume or 0.5) * level * (if thunder then AUDIO.StormAmbience else 1)", 1, true) ~= nil
	and string.find(wsrc, "SoundKit.stop(AUDIO.RainAmbience)", 1, true) ~= nil,
	"the rain's loop is started once, follows the rain's own fade level, a storm's a little louder, and stops at nothing")
check(string.find(wsrc, "stepAmbience(thunder)", 1, true) ~= nil and string.find(wsrc, "ThunderstormBed", 1, true) == nil,
	"it plays under a Rain and a Thunderstorm alike, and nothing plays a second rain loop")
check(string.find(wsrc, "local heardEvent: any = Workspace:GetAttribute(ATTR.EventId)", 1, true) ~= nil
	and string.find(wsrc, 'if mode == "thunder" and type(started) == "number"', 1, true) ~= nil
	and string.find(wsrc, "<= AUDIO.OpeningSeconds", 1, true) ~= nil
	and count(wsrc, "SoundKit.play(AUDIO.ThunderstormOpening)") == 1,
	"a Thunderstorm's opening plays once, for a start this client saw: never a Rain, a late joiner, a re-run or a refused start")
check(count(wsrc, "SoundKit.emit(AUDIO.ThunderClap, spot)") == 1 and string.find(wsrc, "SoundKit.play(AUDIO.ThunderClap", 1, true) == nil
	and string.find(wsrc, "strikeSound(landed)", 1, true) ~= nil,
	"each bolt sounds once, where it landed, through SoundKit's positional one-shot")
check(string.find(wsrc, "while #strikeSpots >= AUDIO.MaxStrikeSounds do", 1, true) ~= nil and AUDIO.MaxStrikeSounds >= 1
	and AUDIO.MaxStrikeSounds <= 3, "at most a couple of strikes sound at once, and each goes with its part")

--==============================================================================
say("6. A catch: one strike, from the server, only for a confirmed catch")
--==============================================================================
local nestSrc = sourceOf(Server, "NestService")
local branch = string.find(nestSrc, "if strikeProf and strikeProf.CatchLightning == true then", 1, true)
local emitAt = string.find(nestSrc, "SoundKit.emit(GameConfig.Weather.Audio.StormstriderStrike, nest.root)", 1, true)
local grab = string.find(nestSrc, "if reach <= P.GrabStuds then", 1, true)
check(count(nestSrc, "Weather.Audio.StormstriderStrike") == 1 and branch ~= nil and emitAt ~= nil and grab ~= nil
	and grab < branch and branch < emitAt and emitAt - branch < 300,
	"NestService emits the catch's strike exactly once, inside the confirmed-contact branch of a lightning guardian")
check(string.find(sourceOf(Shared, "StormstriderRun"), "SoundKit", 1, true) == nil
	and string.find(sourceOf(Scripts, "ParentAnim"), "SoundKit", 1, true) == nil,
	"the clients' catch bolt is silent, so a catch never sounds twice")

--==============================================================================
say("7. Stormstrider's voice: one growl per real wake, one sleeping loop while it sleeps")
--==============================================================================
local wake, sleepCue = CUES.StormstriderWake, CUES.StormstriderSleep
check(wake ~= nil and wake.id == "rbxassetid://113193227101300" and wake.looped ~= true and wake.group == "World"
	and (wake.range or 0) >= 150 and wake.pitch == nil and wake.jitter == nil and wake.clip == nil,
	"the growl: its own id, a positional one-shot on the World bus, played whole at speed 1")
check(sleepCue ~= nil and sleepCue.id == "rbxassetid://82607848172654" and sleepCue.looped == true
	and sleepCue.group == "World" and (sleepCue.range or 999) <= 80 and sleepCue.pitch == nil and sleepCue.jitter == nil,
	"the sleeping breath: its own id, a positional loop on the World bus heard only near it, at speed 1")
check(sleepCue ~= nil and type(sleepCue.volume) == "number" and sleepCue.volume > 0 and sleepCue.volume <= 0.5
	and wake ~= nil and type(wake.volume) == "number" and wake.volume > 0 and wake.volume <= 0.5,
	"both at conservative levels (the quiet sleep render at 0.45, the hot growl at 0.35)")
check(SoundKit.parentCue("rain", "Wake") == "StormstriderWake" and SoundKit.parentCue("rain", "Sleep") == "StormstriderSleep",
	"the rain guardian's Wake and Sleep resolve to its own two")
local roarAt = string.find(nestSrc, 'local roar = SoundKit.parentCue(nest.biome.Id, "Wake")', 1, true)
local asleepAt = string.find(nestSrc, 'if nest.state == "asleep" then\n\t\t--==', 1, true)
local returningAt = string.find(nestSrc, 'elseif nest.state == "returning" or nest.state == "hauling" then', 1, true)
check(count(nestSrc, 'SoundKit.parentCue(nest.biome.Id, "Wake")') == 1 and roarAt ~= nil and asleepAt ~= nil
	and returningAt ~= nil and asleepAt < roarAt and roarAt < returningAt,
	"the growl is the server's one roar per wake: only out of sleep -- never a re-chase, a new target or a queued thief")
check(string.find(nestSrc, 'Id = "rain",', 1, true) ~= nil, "the event nest's guardian speaks as the rain biome")
local cuesSrc = sourceOf(Scripts, "SoundCues")
check(count(cuesSrc, "SoundKit.attach(sleepName, root)") == 1
	and string.find(cuesSrc, 'string.sub(existing.Name, 1, 9) == "SeedLoop_"', 1, true) ~= nil
	and string.find(cuesSrc, 'then shownState == "asleep"', 1, true) ~= nil
	and string.find(cuesSrc, "voice.sleep:Destroy()", 1, true) ~= nil,
	"SoundCues: ONE sleeping loop per guardian, on while ParentState is asleep, faded on waking, gone with the guardian")
-- The late guard, for real (nothing is played: both probes stay silent).
local late = Instance.new("Sound")
late.Name = "RainAudioSpecLate"
late.SoundId = wake and wake.id or ""
late.Volume = 0.35
late:SetAttribute("SeedBus", "World")
late:SetAttribute("SeedBaseVolume", 0.35)
late:SetAttribute("SeedEmittedAt", workspace:GetServerTimeNow() - 5)
local fresh = late:Clone()
fresh.Name = "RainAudioSpecFresh"
fresh.Volume = 0
fresh:SetAttribute("SeedEmittedAt", workspace:GetServerTimeNow())
SoundKit.routeServerCue(late)
SoundKit.routeServerCue(fresh)
check(late.Volume == 0 and late.SoundGroup == nil and not late.IsPlaying,
	"a server one-shot that reaches a client late (streamed in, joined after) is silenced, not replayed")
check(math.abs(fresh.Volume - 0.35) < 1e-4 and fresh.SoundGroup ~= nil and fresh.SoundGroup.Name == "SeedWorld",
	"one that arrives in time goes through the player's World bus as before")
late:Destroy()
fresh:Destroy()
check(type(GameConfig.Sfx.LateCueSeconds) == "number" and GameConfig.Sfx.LateCueSeconds >= 0.5
	and GameConfig.Sfx.LateCueSeconds <= 2, "the late limit is one number, well past ordinary replication",
	GameConfig.Sfx.LateCueSeconds)

say(string.format("\nRainAudioSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
