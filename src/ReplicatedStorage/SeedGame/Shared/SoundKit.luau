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
-- Sound's own Volume instead. Both paths land on the same number. The day there
-- is a real slider, the World bus needs the group AND this multiply.
--==============================================================================

local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

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
}

-- A dynamic string key into a table of literals is not something strict mode
-- will index, and every one of these rows is a different shape. One cast, here,
-- rather than a cast at every call site.
local CUES: { [string]: Cue } = (SFX.Cues :: any)
local MIXER: { [string]: number } = (SFX.Mixer :: any)

local GROUP_NAMES: { [string]: string } = {
	Music = "SeedMusic",
	Chase = "SeedChase",
	UI = "SeedUI",
	World = "SeedWorld",
}

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
		group.Volume = if kind == "Music" then 0 else (MIXER[kind] or 1)
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

local function window(sound: Sound, cue: Cue, key: string?)
	if cue.start and cue.start > 0 then
		sound.TimePosition = cue.start
	end
	local clip = cue.clip
	if not clip or clip <= 0 then
		return
	end
	local seconds = clip / math.max(0.05, sound.PlaybackSpeed)
	if key == nil then
		-- A one-shot emitted into the world owns its Sound outright, so there is
		-- nothing for a later play to interrupt.
		task.delay(seconds, function()
			if sound.Parent then
				sound:Stop()
			end
		end)
		return
	end
	local token = (windowToken[key] or 0) + 1
	windowToken[key] = token
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
	sound.Looped = true
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

local function duckMusic(on: boolean)
	if ducked == on then
		return
	end
	ducked = on
	local group = SoundKit.group("Music")
	if not group then
		return
	end
	local full = MUSIC.Volume * (MIXER.Music or 1)
	local want = if on then full * SFX.MusicDuck else full
	TweenService:Create(group, TweenInfo.new(SFX.DuckSeconds, Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out), { Volume = want }):Play()
end

function SoundKit.chase(on: boolean)
	if not RunService:IsClient() then
		return
	end
	if on then
		if SoundKit.play("ChaseBed") then
			-- Only duck if there is actually a chase bed to duck FOR. With no id
			-- recorded, ducking would just make the game quieter during a raid
			-- and put nothing in the hole.
			duckMusic(true)
		end
	else
		SoundKit.stop("ChaseBed")
		duckMusic(false)
	end
end

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
