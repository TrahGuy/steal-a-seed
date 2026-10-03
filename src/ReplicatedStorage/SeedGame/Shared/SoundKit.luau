--!strict
-- Steal a Seed :: SoundKit
--
-- Every sound in the game that is not the music bed goes through here.
--
--==============================================================================
-- AN EMPTY ID IS A SILENT CUE, NOT A BROKEN ONE
--
-- This is the property the whole design rests on. A call for a cue whose id is
-- blank returns nil and does nothing at all -- no error, no warning at the call
-- site, no half-built Sound with an empty SoundId left in SoundService.
--
-- Every row has an id today, so nothing is currently exercising it. It still
-- matters, because it is what let the nineteen call sites be written and tested
-- BEFORE a single sound existed, and what lets a row be blanked out again --
-- an asset pulled by moderation, a recording being redone -- without the game
-- caring.
--
-- The version of this that does NOT have that property is the one where every
-- call site says `if id ~= "" then`, which is nineteen chances to get it wrong
-- and one guaranteed silent Sound with a blank SoundId sitting in SoundService
-- forever.
--
--==============================================================================
-- FOUR BUSES, BECAUSE THEY ARE FOUR DIFFERENT ARGUMENTS ABOUT VOLUME
--
--   MUSIC   a preference. Some people play with their own music on.
--   CHASE   drama. It is music, but muting the bed must not mute the monster.
--   UI      feedback. Clicks and hovers, and the first thing to go if it nags.
--   WORLD   distance. Everything positional, which is everything with a place.
--
-- One master would make "quieter menus" and "quieter monster" the same setting,
-- and they are not the same setting. Music.client already wrote down why the
-- level lives on a SoundGroup rather than on a Sound -- one property to move the
-- day a settings panel wants a slider, instead of an audit. This is that same
-- argument, three more times.
--
-- The groups are CLIENT-LOCAL. Created in SoundService by whichever client asks
-- first and never replicated, so twelve players have twelve independent mixers
-- and one of them turning the music down is not an event anybody else hears.
--
--==============================================================================
-- WHY SOME ONE-SHOTS ARE PLAYED BY THE SERVER
--
-- The house rule is that the server builds and each client moves -- a roller
-- turning is paint, and paint replicated sixty times a second from six plots is
-- the most expensive thing this game could decide to do.
--
-- A ONE-SHOT IS NOT PAINT. It is one Sound instance that plays once and deletes
-- itself, and the moments it marks -- a parent's hand closing on somebody, a
-- pod coming free of a nest -- are moments every player has to hear at the same
-- instant, from the same place, whether or not they were looking. Doing that
-- client-side means a remote per hit to everyone in earshot, which is strictly
-- more wire traffic than the Sound itself.
--
-- So: LOOPS on tagged world objects are client-side (SoundKit.attach, driven by
-- the same attributes the animation already reads), and one-shots tied to a
-- server-owned moment are server-side (SoundKit.emit).
--
-- The cost is stated rather than hidden: a Sound created on the server cannot
-- reference a client-local SoundGroup, so `emit` bakes the bus level into the
-- Sound's own Volume instead. Both paths land on the same number. Now that the
-- settings panel has sliders, the server's Sound is also tagged with its bus and
-- its unbaked level, and every client puts it through its own group -- see
-- routeServerCue.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local GameConfig = require(script.Parent:WaitForChild("GameConfig"))

local SoundKit = {}

local SFX = GameConfig.Sfx
local MUSIC = GameConfig.Music

export type Cue = {
	id: string,
	volume: number?,
	pitch: number?,
	jitter: number?,
	group: string?,
	looped: boolean?,
	range: number?,
	-- A WINDOW INTO THE ASSET. See below.
	start: number?,
	clip: number?,
	-- The last seconds of the window, faded rather than cut: a render that is
	-- still sounding where its window (or the file) ends. 2D plays only.
	fadeOut: number?,
	-- A LOOP THAT IS NOT THE WHOLE FILE (attach): the Sound's playback and loop
	-- regions, so a render that opens mid-breath loops its clean breath only.
	loopStart: number?,
	loopEnd: number?,
}

-- A dynamic string key into a table of literals is not something strict mode
-- will index, and every one of these rows is a different shape. One cast, here,
-- rather than a cast at every call site.
local CUES: { [string]: Cue } = (SFX.Cues :: any)
local MIXER: { [string]: number } = (SFX.Mixer :: any)
-- Which creature makes which noise. Two levels of string keys and a
-- fallback row, so the same cast applies.
-- A role is a cue name, or a list of names in order of preference.
local VOICES: { [string]: { [string]: any } } = (SFX.ParentVoices :: any)

local GROUP_NAMES: { [string]: string } = {
	Music = "SeedMusic",
	Chase = "SeedChase",
	UI = "SeedUI",
	World = "SeedWorld",
}

-- Stamped on a one-shot the SERVER plays, so each client can put it through its
-- own bus. See routeServerCue.
local BUS_ATTRIBUTE = "SeedBus"
local BASE_VOLUME_ATTRIBUTE = "SeedBaseVolume"
-- When the server played it (workspace:GetServerTimeNow()): a client that
-- receives it later than Sfx.LateCueSeconds does not replay it. See
-- routeServerCue.
local EMITTED_ATTRIBUTE = "SeedEmittedAt"

--==============================================================================
-- THE PLAYER'S OWN LEVELS
--
-- The settings panel's sliders and mutes land here, as a factor on top of the
-- mixer: 0 to 1 per bus, and a mute that keeps the level underneath it.
--
-- A FACTOR, NOT A WRITE TO THE GROUP. The Music bus already has two writers --
-- Music.client's fade and the chase duck -- and a level written straight onto
-- the group would last until the next chase ended and faded the bed back up over
-- somebody who had muted it. Every writer multiplies this in instead, so there
-- is one target and three ways of arriving at it.
--
-- Client-local, like the groups, and for the session only: nothing here saves.
--==============================================================================
local userLevel: { [string]: number } = { Music = 1, Chase = 1, UI = 1, World = 1 }
local userMuted: { [string]: boolean } = {}

local function factor(kind: string): number
	if userMuted[kind] then
		return 0
	end
	return userLevel[kind] or 1
end

--==============================================================================
-- THE BUSES
--
-- Found before created. A Rojo re-sync re-runs every client script while the old
-- groups are still sitting in SoundService, and a second SeedMusic would leave
-- the bed playing through a group nothing can reach to fade.
--==============================================================================
local groups: { [string]: SoundGroup } = {}

function SoundKit.group(kind: string): SoundGroup?
	if not RunService:IsClient() then
		return nil
	end
	local name = GROUP_NAMES[kind]
	if not name then
		return nil
	end
	local cached = groups[kind]
	if cached and cached.Parent then
		return cached
	end
	local existing = SoundService:FindFirstChild(name)
	local group: SoundGroup
	if existing and existing:IsA("SoundGroup") then
		group = existing
	else
		group = Instance.new("SoundGroup")
		group.Name = name
		--======================================================================
		-- THE MUSIC BUS STARTS SILENT AND IS FADED UP BY Music.client
		--
		-- A bed that starts at full level on the loading screen is the first
		-- thing a player mutes. The other three have nothing to fade in from.
		--======================================================================
		group.Volume = if kind == "Music" then 0 else (MIXER[kind] or 1) * factor(kind)
		group.Parent = SoundService
	end
	groups[kind] = group
	return group
end

--==============================================================================
-- READING A CUE
--
-- The one place that decides a cue is unplayable, so "not recorded yet" is one
-- answer rather than nineteen.
--==============================================================================
local function cueOf(name: string): Cue?
	local cue = CUES[name]
	if not cue or type(cue.id) ~= "string" or cue.id == "" then
		return nil
	end
	return cue
end

SoundKit.cue = cueOf

function SoundKit.has(name: string): boolean
	return cueOf(name) ~= nil
end

--==============================================================================
-- WHOSE VOICE, FOR A CUE THAT BELONGS TO ONE CREATURE
--
-- Four roles -- Sleep, Step, Wake, Hit -- resolved against the parent's biome
-- and then against Default, and the answer is a CUE NAME rather than a Cue, so
-- a caller can hand it straight to play, emit or attach and get the windowing,
-- the bus and the range that row asked for.
--
-- A NAME THAT DOES NOT RESOLVE IS nil, NOT A GUESS. Every step of the way it is
-- cueOf that decides -- so a role pointing at a row with a blank id falls
-- through to Default exactly as a missing role does, and a blank Default is
-- silence. That is the same property the whole table rests on, one level up: a
-- creature with no roar makes no noise when it wakes, and nothing anywhere has
-- to check for that.
--
-- A ROLE CAN BE A LIST (2026-09-27): names in order of preference, the first
-- that resolves wins. Astralmaw's Wake is { its rage, its old wake } -- the rage
-- while it has an id, the old roar until then; one roar either way.
--==============================================================================
local function firstPlayable(named: any): string?
	if type(named) == "string" then
		return if cueOf(named) then named else nil
	end
	if type(named) == "table" then
		for _, name in ipairs(named) do
			if type(name) == "string" and cueOf(name) then
				return name
			end
		end
	end
	return nil
end

function SoundKit.parentCue(biomeId: string?, role: string): string?
	local row = if typeof(biomeId) == "string" then VOICES[biomeId] else nil
	local own = firstPlayable(if row then row[role] else nil)
	if own then
		return own
	end
	return firstPlayable(if VOICES.Default then VOICES.Default[role] else nil)
end

--==============================================================================
-- THE WALK HOME'S ONE-SHOT: WHAT A STATE CHANGE DOES TO IT (2026-09-27)
--
-- A guardian's ParentState (NestService, replicated) moving from `old` to `new`
-- says "play" (start its Return cue), "fade" (take down one still sounding) or
-- nil. `at` is GameConfig.Sfx.ReturnCueAt: "leave" plays as it gives up and
-- turns for home, "arrive" as it lies down.
--
--   first sight of a guardian (old nil)     nothing -- it did not just happen
--   chasing/waking -> returning/hauling     play (leave)
--   returning <-> hauling                   nothing: one walk home, one cue
--   returning/hauling -> asleep             play (arrive), else fade
--   anything -> chasing/waking              fade: a fresh chase cuts it off
--   anything else -> asleep                 fade
--
-- Pure, so SoundCueSpec drives every row without a guardian.
--==============================================================================
local HOMEWARD: { [string]: boolean } = { returning = true, hauling = true }
local HUNTING: { [string]: boolean } = { chasing = true, waking = true }

function SoundKit.returnCueStep(old: string?, new: string, at: string): string?
	if old == nil or old == new then
		return nil
	end
	if HOMEWARD[new] then
		if HUNTING[old] and at ~= "arrive" then
			return "play"
		end
		return nil
	end
	if HUNTING[new] then
		return "fade"
	end
	if new == "asleep" then
		if HOMEWARD[old] and at == "arrive" then
			return "play"
		end
		return "fade"
	end
	return nil
end

--==============================================================================
-- MISSING IDS, SAID ONCE
--
-- Deliberately not an error and deliberately not silent about being silent --
-- the same call Music.client makes, for the same reason. A cue with no id plays
-- nothing and reports nothing, so without this the only symptom of a forgotten
-- row is a game that is quieter than intended for a reason nobody can see.
--==============================================================================
function SoundKit.report(): { string }
	local missing: { string } = {}
	for name, cue in pairs(CUES) do
		if type(cue.id) ~= "string" or cue.id == "" then
			table.insert(missing, name)
		end
	end
	table.sort(missing)
	return missing
end

--==============================================================================
-- A WINDOW INTO AN ASSET THAT WAS NEVER TRIMMED
--
-- WHAT WAS UPLOADED IS NOT WHAT SHOULD PLAY. Every cue in this game came out of
-- a generator as a several-second render: `CARD HOVER POP` is five seconds
-- holding THIRTEEN separate pops, `CARD CLICK` opens with 140ms of silence
-- before the click, and `PANEL OPEN` has a lead-in and then a second take of
-- itself a second later.
--
-- So a cue may name a start offset and a length, and this plays that slice. It
-- is exact, it costs one property and one delayed Stop, and it means a raw
-- upload is usable the moment its id is pasted in.
--
-- IT IS NOT A SUBSTITUTE FOR TRIMMING. A trimmed re-upload is a smaller asset
-- that starts instantly and needs neither field. This is what makes the
-- untrimmed one work in the meantime.
--
--==============================================================================
-- THE STOP HAS TO KNOW WHICH PLAY SCHEDULED IT
--
-- There is one Sound per 2D cue and it is retriggered rather than duplicated, so
-- a pointer swept down a grid of cards starts the hover pop ten times in a
-- second. Without the token, the stop scheduled by the FIRST of those would fire
-- 140ms later and cut the TENTH one off mid-pop -- a hover that goes silent the
-- faster you move, which is the opposite of what it is for.
--
-- The delay is divided by PlaybackSpeed because pitch changes duration: a cue
-- jittered 6% sharp is 6% shorter, and a fixed delay would clip the sharp ones
-- and leave a tail on the flat ones.
--==============================================================================
local windowToken: { [string]: number } = {}
-- A keyed cue's fade still running when it plays again is cancelled, so the
-- new play is not pulled down by the old one's last 80 ms.
local windowFade: { [string]: Tween } = {}

local function window(sound: Sound, cue: Cue, key: string?)
	if cue.start and cue.start > 0 then
		sound.TimePosition = cue.start
	end
	local clip = cue.clip
	if not clip or clip <= 0 then
		return
	end
	local seconds = clip / math.max(0.05, sound.PlaybackSpeed)
	-- A FADE, NOT A CUT, where the row asks for one (fadeOut): the level goes
	-- to nothing over the window's last seconds and then it stops. The next
	-- play sets the level again (play and emit both write Volume first).
	local fade = cue.fadeOut
	local fadeFor = if type(fade) == "number" and fade > 0
		then math.min(fade, clip) / math.max(0.05, sound.PlaybackSpeed)
		else 0
	if key == nil then
		-- A one-shot emitted into the world owns its Sound outright, so there is
		-- nothing for a later play to interrupt.
		if fadeFor > 0 then
			task.delay(seconds - fadeFor, function()
				if sound.Parent then
					TweenService:Create(sound, TweenInfo.new(fadeFor, Enum.EasingStyle.Quad,
						Enum.EasingDirection.In), { Volume = 0 }):Play()
				end
			end)
		end
		task.delay(seconds, function()
			if sound.Parent then
				sound:Stop()
			end
		end)
		return
	end
	local token = (windowToken[key] or 0) + 1
	windowToken[key] = token
	local running = windowFade[key]
	if running then
		running:Cancel()
		windowFade[key] = nil
	end
	if fadeFor > 0 then
		task.delay(seconds - fadeFor, function()
			if windowToken[key] == token and sound.Parent then
				local tween = TweenService:Create(sound, TweenInfo.new(fadeFor, Enum.EasingStyle.Quad,
					Enum.EasingDirection.In), { Volume = 0 })
				windowFade[key] = tween
				tween:Play()
			end
		end)
	end
	task.delay(seconds, function()
		if windowToken[key] == token and sound.Parent then
			sound:Stop()
		end
	end)
end

--==============================================================================
-- PITCH JITTER
--
-- A hover that plays at exactly the same pitch every time turns into a
-- woodpecker the moment somebody sweeps the pointer down a grid of cards. The
-- fix is not a quieter sound, it is a sound that is never quite the same twice.
--==============================================================================
local function speedOf(cue: Cue, override: number?): number
	local base = override or cue.pitch or 1
	local jitter = cue.jitter or 0
	if jitter <= 0 then
		return base
	end
	return base * (1 + (math.random() * 2 - 1) * jitter)
end

--==============================================================================
-- 2D, ON THE CLIENT
--
-- ONE Sound PER CUE, REUSED. Play() on a Sound that is already playing restarts
-- it, which for a hover or a cash tick is not a limitation but the correct
-- behaviour: eight overlapping copies of a card pop is a noise, and the newest
-- one is always the one the player just caused.
--
-- The cues where overlap WOULD be wanted -- a reveal, a bank -- cannot overlap
-- with themselves anyway, because you cannot hatch twice in the same frame.
--==============================================================================
export type PlayOptions = {
	volume: number?,
	pitch: number?,
}

local flat: { [string]: Sound } = {}

function SoundKit.play(name: string, options: PlayOptions?): Sound?
	local cue = cueOf(name)
	if not cue or not RunService:IsClient() then
		return nil
	end
	local sound = flat[name]
	if not sound or not sound.Parent then
		sound = Instance.new("Sound")
		sound.Name = "SeedCue_" .. name
		sound.SoundId = cue.id
		sound.SoundGroup = SoundKit.group(cue.group or "UI")
		sound.Looped = cue.looped == true
		sound.Parent = SoundService
		flat[name] = sound
	end
	local opts = options or {}
	sound.Volume = opts.volume or cue.volume or 0.5
	sound.PlaybackSpeed = speedOf(cue, opts.pitch)
	sound:Play()
	-- After Play, not before: TimePosition on a Sound that has not started is
	-- reset by the start itself.
	window(sound, cue, name)
	return sound
end

function SoundKit.stop(name: string)
	local sound = flat[name]
	if sound and sound.Parent then
		sound:Stop()
	end
end

--==============================================================================
-- POSITIONAL, ONE-SHOT, EITHER SIDE OF THE WIRE
--
-- A BasePart and not a Vector3: every caller has a part -- the belt, the pod,
-- the parent's torso, the mill -- and a Sound needs somewhere to live anyway.
-- Taking a position would mean inventing a part to hang it on, which is an
-- instance nobody asked for and one more thing to clean up.
--
-- Debris rather than an Ended connection. Ended never fires for an id that
-- failed to load, and a Sound that is waiting forever for an event that is not
-- coming is a leak with a plausible explanation.
--==============================================================================
function SoundKit.emit(name: string, at: BasePart, options: PlayOptions?): Sound?
	local cue = cueOf(name)
	if not cue or not at.Parent then
		return nil
	end
	local opts = options or {}
	local bus = cue.group or "World"

	local sound = Instance.new("Sound")
	sound.Name = "SeedCue_" .. name
	sound.SoundId = cue.id
	sound.PlaybackSpeed = speedOf(cue, opts.pitch)
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMaxDistance = cue.range or 120
	-- Half the max, so the level is still falling across most of the distance a
	-- player can hear it from. The default 10 makes anything past a few studs
	-- effectively silent, which on a 1500-stud road is every sound in the game.
	sound.RollOffMinDistance = math.max(6, (cue.range or 120) * 0.25)

	local group = SoundKit.group(bus)
	if group then
		sound.Volume = opts.volume or cue.volume or 0.5
		sound.SoundGroup = group
	else
		-- Server side. See the note at the top: no client-local group to route
		-- through, so the bus level is baked in and both paths land on the same
		-- number.
		sound.Volume = (opts.volume or cue.volume or 0.5) * (MIXER[bus] or 1)
		-- And named, so each client can take the baked level back off and put
		-- the Sound through its own bus, where the player's settings are.
		sound:SetAttribute(BUS_ATTRIBUTE, bus)
		sound:SetAttribute(BASE_VOLUME_ATTRIBUTE, opts.volume or cue.volume or 0.5)
		-- And when, so a client that only receives it later (streamed in, joined
		-- after) does not replay it.
		sound:SetAttribute(EMITTED_ATTRIBUTE, Workspace:GetServerTimeNow())
		CollectionService:AddTag(sound, GameConfig.Tags.ServerCue)
	end

	sound.Parent = at
	sound:Play()
	window(sound, cue, nil)
	Debris:AddItem(sound, 12)
	return sound
end

--==============================================================================
-- POSITIONAL, LOOPING, CLIENT SIDE
--
-- The caller owns what comes back and decides when it is Playing -- because the
-- thing that knows whether a parent is asleep is the loop already reading that
-- attribute to swing its arms, not this.
--==============================================================================
function SoundKit.attach(name: string, to: BasePart): Sound?
	local cue = cueOf(name)
	if not cue or not RunService:IsClient() or not to.Parent then
		return nil
	end
	local sound = Instance.new("Sound")
	sound.Name = "SeedLoop_" .. name
	sound.SoundId = cue.id
	sound.Volume = cue.volume or 0.5
	sound.PlaybackSpeed = cue.pitch or 1
	-- A loop unless the row says otherwise (every attached row was a loop
	-- until the walk-home one-shots, 2026-09-27).
	sound.Looped = cue.looped ~= false
	-- Only the clean part of a render, round and round (loopStart/loopEnd).
	-- Through pcall: an engine without playback regions loops the whole file.
	local a, b = cue.loopStart, cue.loopEnd
	if type(a) == "number" and type(b) == "number" and b > a then
		pcall(function()
			sound.PlaybackRegionsEnabled = true
			sound.PlaybackRegion = NumberRange.new(a, b)
			sound.LoopRegion = NumberRange.new(a, b)
		end)
	end
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMaxDistance = cue.range or 120
	sound.RollOffMinDistance = math.max(6, (cue.range or 120) * 0.25)
	sound.SoundGroup = SoundKit.group(cue.group or "World")
	sound.Parent = to
	return sound
end

--==============================================================================
-- THE CHASE BED, AND THE GARDEN BED GETTING OUT OF ITS WAY
--
-- ONE CALL, because they are one decision. Two calls is how the bed ends up
-- ducked with no chase running -- the state where the game is quiet, sounds
-- broken, and nothing in the log says why.
--
-- The duck is a bus move, not a Sound move: Music.client deliberately leaves its
-- track at Volume 1 so that exactly one number decides how loud the music is,
-- and reaching past that to the Sound would put a second number in play.
--==============================================================================
local ducked = false

--==============================================================================
-- WHERE THE MUSIC BUS IS MEANT TO BE
--
-- The configured bed, times the player's level, ducked while a chase runs. The
-- join fade, the duck and the settings panel all aim at this, and all three move
-- the bus through moveMusic, which cancels whichever of them was still moving
-- it. Two tweens on one property is a bus that lands wherever the last one to
-- finish happened to be heading.
--==============================================================================
function SoundKit.musicLevel(): number
	local full = MUSIC.Volume * (MIXER.Music or 1) * factor("Music")
	return if ducked then full * SFX.MusicDuck else full
end

local musicTween: Tween? = nil

local function moveMusic(seconds: number, style: Enum.EasingStyle)
	local group = SoundKit.group("Music")
	if not group then
		return
	end
	if musicTween then
		musicTween:Cancel()
		musicTween = nil
	end
	local want = SoundKit.musicLevel()
	if seconds <= 0 then
		group.Volume = want
		return
	end
	local tween = TweenService:Create(group, TweenInfo.new(seconds, style,
		Enum.EasingDirection.Out), { Volume = want })
	musicTween = tween
	tween:Play()
end

-- The join fade, from silence up to wherever the bus is meant to be.
function SoundKit.fadeMusic(seconds: number)
	moveMusic(seconds, Enum.EasingStyle.Linear)
end

local function duckMusic(on: boolean, seconds: number)
	if ducked == on then
		return
	end
	ducked = on
	moveMusic(seconds, Enum.EasingStyle.Quad)
end

--==============================================================================
-- THE BED LEAVES BY FADING, AND A CHASE THAT RESUMES KEEPS ITS PLACE
--
-- It used to stop dead: the escape was a hard cut to the garden bed, which is
-- the player hearing the SYSTEM switch tracks rather than the danger passing.
--
-- `chaseFade` is the one tween allowed on the bed's own Volume, and every call
-- bumps `chaseToken`. A fade-out that finishes stops the track only if nothing
-- has called since it began, so a pursuit that lands during the tail keeps the
-- music instead of being cut off by the chase before it.
--
-- A RESUME NEVER CALLS PLAY. Play restarts a looped bed from its first bar, so
-- a guardian picking the chase straight back up would restart the song; the
-- one still sounding is brought back up where it is instead. The Sound's own
-- Volume is what fades, never the Chase bus -- the bus is the player's SOUND FX
-- level, and a fade that wrote it would overwrite their setting.
--==============================================================================
local chaseToken = 0
local chaseFade: Tween? = nil

local function fadeBed(sound: Sound, to: number, seconds: number): Tween?
	if chaseFade then
		chaseFade:Cancel()
		chaseFade = nil
	end
	if seconds <= 0 then
		sound.Volume = to
		return nil
	end
	local tween = TweenService:Create(sound, TweenInfo.new(seconds, Enum.EasingStyle.Linear), {
		Volume = to,
	})
	chaseFade = tween
	tween:Play()
	return tween
end

function SoundKit.chase(on: boolean)
	if not RunService:IsClient() then
		return
	end
	chaseToken += 1
	local bed = flat.ChaseBed
	local sounding = bed ~= nil and bed.Parent ~= nil and bed.IsPlaying
	if on then
		local cue = cueOf("ChaseBed")
		local full = if cue then cue.volume or 0.5 else 0.5
		if sounding then
			fadeBed(bed :: Sound, full, SFX.ChaseFadeInSeconds)
			duckMusic(true, SFX.DuckSeconds)
			return
		end
		local sound = SoundKit.play("ChaseBed", { volume = 0 })
		if sound then
			fadeBed(sound, full, SFX.ChaseFadeInSeconds)
			-- Only duck if there is actually a chase bed to duck FOR. With no id
			-- recorded, ducking would just make the game quieter during a raid
			-- and put nothing in the hole.
			duckMusic(true, SFX.DuckSeconds)
		end
	else
		local tween = if sounding then fadeBed(bed :: Sound, 0, SFX.ChaseFadeOutSeconds) else nil
		if tween then
			local token = chaseToken
			tween.Completed:Connect(function(state: Enum.PlaybackState)
				if state == Enum.PlaybackState.Completed and token == chaseToken then
					SoundKit.stop("ChaseBed")
				end
			end)
		else
			SoundKit.stop("ChaseBed")
		end
		-- Back up over the same length the bed goes down over: a cross, not a gap.
		duckMusic(false, SFX.ChaseFadeOutSeconds)
	end
end

--==============================================================================
-- THE SETTINGS PANEL'S HALF
--
-- A nil `level` leaves the level alone and a nil `muted` leaves the mute alone,
-- so a slider and a mute button each say only what they changed. Clamped here
-- rather than by the caller: this is the last stop before a bus, and a slider
-- dragged past its end must not make a bus louder than the mix was built at.
--
-- INSTANT, NOT TWEENED. A slider being dragged is already its own fade, and a
-- tween per drag event would trail the thumb the whole way along the track.
--==============================================================================
function SoundKit.setLevel(kind: string, level: number?, muted: boolean?)
	if not GROUP_NAMES[kind] then
		return
	end
	if type(level) == "number" and level == level then
		userLevel[kind] = math.clamp(level, 0, 1)
	end
	if type(muted) == "boolean" then
		userMuted[kind] = muted
	end
	if kind == "Music" then
		moveMusic(0, Enum.EasingStyle.Linear)
		return
	end
	local group = SoundKit.group(kind)
	if group then
		group.Volume = (MIXER[kind] or 1) * factor(kind)
	end
end

function SoundKit.level(kind: string): (number, boolean)
	return userLevel[kind] or 1, userMuted[kind] == true
end

--==============================================================================
-- A ONE-SHOT THE SERVER PLAYED, THROUGH THIS CLIENT'S BUS
--
-- emit on the server bakes the mixer into the Sound and tags it with its bus and
-- its unbaked level. Each client that receives it puts that level back and routes
-- it through its own group, so a player who turned sound effects down stops
-- hearing a parent's grab and a pod coming free along with everything else. The
-- writes are local: nobody else's copy of the Sound moves.
--==============================================================================
function SoundKit.routeServerCue(sound: Instance)
	if not sound:IsA("Sound") then
		return
	end
	--==========================================================================
	-- A ONE-SHOT THIS CLIENT DID NOT WITNESS IS NOT REPLAYED (2026-10-02)
	--
	-- It stays in the world for twelve seconds after it played (emit's Debris),
	-- and a Sound that replicates to a client while still marked playing is
	-- started there from the top: a guardian streamed in mid-chase, or a player
	-- who joined just after a roar, would hear a growl from seconds ago. Arriving
	-- later than Sfx.LateCueSeconds after the server played it, this client's
	-- copy is silenced and stopped -- locally; nobody else's moves.
	--==========================================================================
	local emitted = sound:GetAttribute(EMITTED_ATTRIBUTE)
	if type(emitted) == "number" and Workspace:GetServerTimeNow() - emitted > (SFX.LateCueSeconds or 1) then
		sound.Volume = 0
		sound:Stop()
		return
	end
	local bus = sound:GetAttribute(BUS_ATTRIBUTE)
	local group = if type(bus) == "string" then SoundKit.group(bus) else nil
	if not group then
		return
	end
	local base = sound:GetAttribute(BASE_VOLUME_ATTRIBUTE)
	if type(base) == "number" then
		sound.Volume = base
	end
	sound.SoundGroup = group
end

local serverCuesBound = false

--==============================================================================
-- PRELOAD
--
-- An id that is well-formed but wrong -- still in moderation, or owned by
-- another account -- behaves exactly like a correct one right up until nothing
-- comes out of the speakers. This is where that difference gets found.
--==============================================================================
function SoundKit.preload()
	if not RunService:IsClient() then
		return
	end
	--==========================================================================
	-- THE BUSES EXIST FROM THE FIRST FRAME, NOT FROM THE FIRST HOVER
	--
	-- `group` builds them on demand, which means SeedUI does not exist until
	-- something plays a UI cue -- so for the first minute of a session the mixer
	-- is one bus and three absences. Nothing BREAKS: the group is made the
	-- instant it is wanted. But a settings panel enumerating the mixer, or a
	-- person looking at SoundService to see what this game does, finds a
	-- half-built thing and has no way to tell that from a bug.
	--==========================================================================
	for kind in pairs(GROUP_NAMES) do
		SoundKit.group(kind)
	end

	-- Server one-shots, from the first frame: any already playing, then every
	-- one after. Once per client, even if the script that calls this re-runs.
	if not serverCuesBound then
		serverCuesBound = true
		for _, sound in ipairs(CollectionService:GetTagged(GameConfig.Tags.ServerCue)) do
			SoundKit.routeServerCue(sound)
		end
		CollectionService:GetInstanceAddedSignal(GameConfig.Tags.ServerCue)
			:Connect(SoundKit.routeServerCue)
	end

	task.spawn(function()
		local probes: { Sound } = {}
		local holder = Instance.new("Folder")
		holder.Name = "SeedCuePreload"
		holder.Parent = SoundService
		for name, cue in pairs(CUES) do
			if type(cue.id) == "string" and cue.id ~= "" then
				local probe = Instance.new("Sound")
				probe.Name = name
				probe.SoundId = cue.id
				probe.Parent = holder
				table.insert(probes, probe)
			end
		end
		if #probes == 0 then
			holder:Destroy()
			return
		end
		pcall(function()
			ContentProvider:PreloadAsync(probes)
		end)
		local bad: { string } = {}
		for _, probe in ipairs(probes) do
			if not probe.IsLoaded then
				table.insert(bad, probe.Name)
			end
		end
		holder:Destroy()
		if #bad > 0 then
			table.sort(bad)
			warn(string.format("[Seed/SoundKit] %d cue(s) have an id that did not "
				.. "load: %s. An audio asset has to be owned by the account that "
				.. "owns this place AND have cleared moderation; a pending upload "
				.. "plays nothing and says nothing.",
				#bad, table.concat(bad, ", ")))
		end
	end)
end

return SoundKit
