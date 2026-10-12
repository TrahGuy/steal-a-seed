--!nocheck
--==============================================================================
-- Steal a Seed :: MistAudioSpec
--
-- The Enchanted Mist's sounds (2026-10-11): the owner's thirteen CrazyCozy
-- Games uploads (sfx/enchanted-mist-sound-prompts.txt), wired to their moments.
-- Edit mode:
--
--   1. the rows: each names its own asset, on its bus, its window inside the
--      length measured off its render in sfx/ (and off the upload's own
--      TimeLength in Studio: every one agreed to the millisecond), its volume
--      the designed level over the measured peak, the berry's twinkle heard
--      near it only, no asset shared with another row
--   2. the bed under the music: AMBIENCE's level well under BGM1's
--   3. the wiring, by source: the bed at the Mist look's level and BEGINS /
--      ENDS once on the state's change (Weather.client); the twinkle AT a new
--      berry, the berry's own notice silent (the owner: "SILENT, EVERY BERRY"),
--      a pick's notice quiet and saying full (EnchantedMistBerryService -- the
--      calls are EnchantedMistBerrySpec's); PICKED / FULL on the pick's own
--      notice (EnchantedMistBerries.client); HELLO, GIVE ALL and the game's
--      Action Blocked in the dialogue (MosskeeperUI); POD EARNED as the bar
--      lands (MosskeeperView); a delivery's notice quiet (MosskeeperService);
--      POD READY when a Mysterious Pod seen growing turns ready (LoadoutUI);
--      the reel's ticks, its landings and A SECRET! (MysteryRevealUI)
--
-- Not here, heard in the guarded Play: the levels by ear, the timings.
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
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name, true)
	if not found then
		return ""
	end
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok then src else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end
local function count(src, text)
	local n, from = 0, 1
	while true do
		local i, j = string.find(src, text, from, true)
		if not i then
			return n
		end
		n += 1
		from = j + 1
	end
end

local CUES = GameConfig.Sfx.Cues
local Server = ServerScriptService.SeedGameServer
local Scripts = StarterPlayer.StarterPlayerScripts

local ok, err = pcall(function()
	--==========================================================================
	say("1. The rows")
	--==========================================================================
	-- name, asset, the render's length (s), its measured peak (of full scale),
	-- the designed level, the bus.
	-- (The AMBIENCE, 91905968261795, is the Mist's MUSIC since 2026-10-12, item 19:
	-- Music.MistTrack, section 2 -- not a row.)
	local ROWS = {
		{ "MistBegins", "107597832765081", 3.48, 0.98, 0.45, "UI" },
		{ "MistEnds", "105565685427294", 2.28, 0.26, 0.30, "UI" },
		{ "MistBerryAppears", "93161571928576", 0.48, 0.21, 0.625, "World" },
		{ "MistBerryPicked", "105691434133252", 0.48, 0.42, 0.30, "UI" },
		{ "MistBerriesFull", "101482706102921", 0.48, 0.79, 0.35, "UI" },
		{ "MistHello", "96949680041955", 1.2, 0.94, 0.30, "UI" },
		{ "MistGiveAll", "97066727639042", 1.48, 0.92, 0.35, "UI" },
		{ "MistPodEarned", "81157512493666", 2.28, 0.96, 0.50, "UI" },
		{ "MistPodReady", "105177825016817", 1.0, 1.0, 0.35, "UI" },
		{ "MistReelTick", "88081217369132", 0.48, 1.0, 0.20, "UI" },
		{ "MistCardLands", "106515846422089", 0.48, 0.34, 0.35, "UI" },
		{ "MistSecret", "106270956432929", 2.48, 1.0, 0.55, "UI" },
	}
	local bad = {}
	local mine = {}
	for _, r in ipairs(ROWS) do
		local name, id, seconds, peak, designed, bus = r[1], r[2], r[3], r[4], r[5], r[6]
		local cue = CUES[name]
		mine[name] = true
		local why = {}
		if not cue then
			table.insert(why, "no row")
		else
			if cue.id ~= "rbxassetid://" .. id or SoundKit.cue(name) == nil then
				table.insert(why, "asset " .. tostring(cue.id))
			end
			if (cue.group or "UI") ~= bus then
				table.insert(why, "bus " .. tostring(cue.group))
			end
			local start = cue.start or 0
			if start < 0 or start >= seconds or (cue.clip and start + cue.clip > seconds + 0.001) then
				table.insert(why, string.format("window %.3f + %s past %.3f", start, tostring(cue.clip), seconds))
			end
			if cue.fadeOut and not cue.clip then
				table.insert(why, "a fade with no window")
			end
			if designed and math.abs(cue.volume - designed / peak) > 0.05 * (designed / peak) + 0.01 then
				table.insert(why, string.format("volume %.2f, designed/peak %.2f", cue.volume, designed / peak))
			end
			-- Clean through its bus (2026-10-12, the twinkle made 2.5x louder): the
			-- measured peak times the volume and the bus's level stays under full
			-- scale, as the disco's level was checked.
			local busLevel = (GameConfig.Sfx :: any).Mixer[bus] or 1
			if type(cue.volume) ~= "number" or cue.volume <= 0 or cue.volume * peak * busLevel > 1 then
				table.insert(why, string.format("volume %s peaks at %.2f through %s", tostring(cue.volume),
					(tonumber(cue.volume) or 0) * peak * busLevel, bus))
			end
		end
		if #why > 0 then
			table.insert(bad, name .. ": " .. table.concat(why, ", "))
		end
	end
	check(#bad == 0, "twelve rows, each its own asset on its bus, its window inside the render, its volume the "
		.. "designed level over the measured peak", table.concat(bad, " | "))
	local shared = {}
	for name, cue in pairs(CUES) do
		if not mine[name] then
			for _, r in ipairs(ROWS) do
				if cue.id == "rbxassetid://" .. r[2] then
					table.insert(shared, name .. " uses " .. r[1] .. "'s asset")
				end
			end
		end
	end
	check(#shared == 0, "no other row plays any of them", table.concat(shared, "; "))
	local twinkle = CUES.MistBerryAppears
	check(twinkle and twinkle.range == 80 and twinkle.volume and twinkle.volume * 0.21 >= 0.6
			and twinkle.volume * 0.21 * ((GameConfig.Sfx :: any).Mixer.World or 1) <= 1,
		"the twinkle AT a berry, louder and wider (the owner, 2026-10-12: 2.5x, heard to 80 studs): it peaks clean "
			.. "through the World bus", twinkle and twinkle.range)
	-- THE BED IS THE MUSIC (2026-10-12, the owner's item 19: "the mist replaces the music"): no cue plays the
	-- AMBIENCE any more -- it is Music.MistTrack, so it can never sound twice.
	local MUSIC = GameConfig.Music :: any
	local ambienceCues = {}
	for name, cue in pairs(CUES) do
		if cue.id == "rbxassetid://91905968261795" then
			table.insert(ambienceCues, name)
		end
	end
	check(MUSIC.MistTrack == "rbxassetid://91905968261795" and #ambienceCues == 0 and CUES.MistAmbience == nil
			and type(MUSIC.MistStart) == "number" and MUSIC.MistStart >= 2 and MUSIC.MistStart < 2.2
			and type(MUSIC.MistFadeSeconds) == "number" and MUSIC.MistFadeSeconds > 0,
		"the AMBIENCE is the Mist's music (Music.MistTrack), past its 2.14 s of quiet -- no cue plays it",
		table.concat(ambienceCues, ", "))
	local tick = CUES.MistReelTick
	check(tick and tick.start == 0.05 and tick.clip and tick.clip <= 0.1 and (tick.jitter or 0) > 0,
		"the tick: only its 0.052-0.124 s of sound, a little pitch jitter (it plays many in a row)")

	--==========================================================================
	say("2. The bed as the music (2026-10-12, the owner's item 19)")
	--==========================================================================
	-- On the Music bus at the beds' level: RMS off the renders, AMBIENCE -15.6 dB to BGM1's -14.7 -- as loud as
	-- the music it replaces, within 1.5 dB.
	local music = sourceOf(Scripts, "Music")
	local function at(text)
		return string.find(music, text, 1, true) or math.huge
	end
	local listStart = at("local function listFor(): { string }")
	local rainAt, mistAt = at("rainOk ~= false and rainFalling() then"), at("mistOk ~= false and mistActive() then")
	local nightAt, rushAt = at("and Workspace:GetAttribute(ATTR.WorldPhase) == CYCLE.PhaseNight then"),
		at("rushOk ~= false and rushPlaying() then")
	check(math.abs(-15.6 - -14.7) <= 1.5 and listStart < rushAt and rushAt < rainAt and rainAt < mistAt
			and mistAt < nightAt and nightAt < at("local function levelFor("),
		"the Mist's bed in the music's own order: Sprout Dash, the disco = the Pod Rush, the rain, THE MIST, night, "
			.. "day -- on the one Sound, the Music bus (its slider and mute), at the beds' level")
	check(has(music, "hold = started + BEGINS_SECONDS - Workspace:GetServerTimeNow()")
			and has(music, "elseif current == mistTracks and not mistActive() then\n\t\thold = ENDS_SECONDS")
			and has(music, "task.delay(math.max(half, hold), function()")
			and has(music, "local BEGINS_SECONDS = tonumber(((SoundKit.cue(\"MistBegins\") or {}) :: any).clip) or 3.5"),
		"BEGINS alone: the bed it replaces fades out under it and the Mist's waits for its end; ENDS alone: the day "
			.. "or night bed waits for it")
	check(has(music, "local into = math.max(0, Workspace:GetServerTimeNow() - started - BEGINS_SECONDS)")
			and has(music, "sound.TimePosition = ((tonumber((MUSIC :: any).MistStart) or 0) + into) % length")
			and has(music, "\t\tplayTrack(want, 1)\n\t\talignDisco()\n\t\talignMist()\n")
			and has(music, "alignDisco()\nalignMist()\n")
			and has(music, "probeBed(mistTracks[1], MIST_PROBE, function(loaded: boolean)")
			and has(music, "Workspace:GetAttributeChangedSignal(MIST_ATTR.State):Connect(function()"),
		"on the Mist's own clock from BEGINS' end -- a late joiner, or the Mist's bed back after a rain, on the same "
			.. "bar -- and an id that cannot load keeps the day/night bed")

	--==========================================================================
	say("3. The wiring")
	--==========================================================================
	local weather = sourceOf(Scripts, "Weather")
	check(not has(weather, "MistAmbience") and not has(weather, "stepMistBed"),
		"Weather.client plays no bed of its own any more: the music does (never twice)")
	check(has(weather, "if now == active and mistWas ~= active and type(started) == \"number\"\n"
				.. "\t\tand Workspace:GetServerTimeNow() - started <= 5 and eventId ~= mistBegunId then\n"
				.. "\t\tmistBegunId = eventId\n\t\tSoundKit.play(\"MistBegins\")")
			and has(weather, "elseif now ~= active and mistWas == active then\n\t\tSoundKit.play(\"MistEnds\")"),
		"BEGINS once a Mist as it starts -- never twice for one event id, never for a state that arrives late -- and "
			.. "ENDS once as it leaves")
	local berryServer = sourceOf(Server, "EnchantedMistBerryService")
	check(has(berryServer, "\t\tHooks.sound(\"MistBerryAppears\", root)\n")
			and has(berryServer, "\tsound = function(name: string, at: BasePart)\n\t\tSoundKit.emit(name, at)\n")
			and has(berryServer, "\t\tquiet = true,\n\t\tfull = full,\n"),
		"the berries' server: the twinkle AT each new berry (a server one-shot); a pick's notice quiet, saying full")
	check(has(berryServer, "local payload = { title = W.Appeared, detail = berry.where, key = B.NoticeKeys.Appeared, "
			.. "quiet = true,\n\t\ticon = \"mist\" }"),
		"the owner (2026-10-11): \"A Dewberry appeared!\" SILENT, every berry -- updating in place, the twinkle the "
			.. "spawn's only sound")
	local berries = sourceOf(Scripts, "EnchantedMistBerries")
	check(has(berries, "payload.key == B.NoticeKeys.Picked then\n"
			.. "\t\t\tSoundKit.play(if payload.full == true then \"MistBerriesFull\" else \"MistBerryPicked\")"),
		"PICKED, or FULL on the fifth, on the pick's own notice -- never on a count stamped at a join")
	local dialogue = sourceOf(Scripts, "MosskeeperUI")
	check(has(dialogue, "\t\tsetOpen(true)\n\t\tSoundKit.play(\"MistHello\")")
			and has(dialogue, "SoundKit.play(\"MistGiveAll\")") and has(dialogue, "SoundKit.play(\"NoticeBlocked\")"),
		"the dialogue: HELLO as it opens, GIVE ALL on a delivery taken, the game's Action Blocked on one refused")
	local bar = sourceOf(Scripts, "MosskeeperView")
	check(has(bar, "\t\tdraw(PER_POD)\n") and has(bar, "SoundKit.play(\"MistPodEarned\")")
			and has(bar, "task.delay(if StatusText.reducedMotion() then 0 else 0.45, function()"),
		"POD EARNED as his bar lands on 10/10")
	local keeper = sourceOf(Server, "MosskeeperService")
	check(has(keeper, "\t\t\tkey = CFG.NoticeKey,\n\t\t\t-- The delivery makes its own sound on the client (GIVE ALL, "
			.. "POD EARNED).\n\t\t\tquiet = true,\n"),
		"a delivery's notice quiet: its own sounds play")
	local reveal = sourceOf(Scripts, "MysteryRevealUI")
	check(has(reveal, "local i = math.floor((-strip.Position.X.Offset - width / 2) / pitch + 0.5) + 1")
			and has(reveal, "SoundKit.play(\"MistReelTick\")")
			and count(reveal, "SoundKit.play(\"MistCardLands\")") == 3
			and has(reveal, "if state == Enum.PlaybackState.Completed then")
			and has(reveal, "\t\t\t\ttitle.Text = W.Secret\n\t\t\t\tSoundKit.play(\"MistSecret\")")
			-- OPEN ALL's grid (2026-10-12, item 17): one landing for the grid, A SECRET! if one is in it.
			and has(reveal, "\tSoundKit.play(\"MistCardLands\")\n\tif secret then\n\t\tSoundKit.play(\"MistSecret\")\n\tend"),
		"the reveal: a tick for every card centred, a landing on each reel (reduced motion too), A SECRET! on a Secret; "
			.. "OPEN ALL's grid lands once, with A SECRET! when it holds one")
	local loadout = sourceOf(Scripts, "LoadoutUI")
	check(has(loadout, "if mist and podsNow.mistGrowing[tostring(item.ref)] then\n\t\t\t\t\t\tSoundKit.play(\"MistPodReady\")")
			and has(loadout, "\t\tpodsNow.mistGrowing = mistGrowing\n"),
		"POD READY when a Mysterious Pod this Bag saw growing turns ready -- none for one ready at a join")
	local config = sourceOf(Shared, "EnchantedMistConfig")
	check(not has(config, "no approved Mist audio exists"), "the Mist's config no longer says it has no sound")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nMistAudioSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
