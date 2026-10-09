--!strict
-- Steal a Seed :: Music
--
-- The background bed. One track on a loop, or a short playlist that wraps.
--
--==============================================================================
-- CLIENT, AND 2D
--
-- Music belongs to the person listening rather than to the world. A Sound
-- parented to SoundService plays flat at full level wherever the camera happens
-- to be pointing, and it survives the character being ragdolled, respawned or
-- thrown across a field by a nest parent -- all three of which happen in this
-- game. Same reasoning AlertUI already wrote down for the alarm.
--
-- Nothing here replicates, and that is the point. Twelve players hear twelve
-- independent copies; a single shared Sound would put everyone at the same
-- position in the same track and drop every late joiner in mid-bar.
--
--==============================================================================
-- A SOUNDGROUP, FOR THE SLIDER THAT DOES NOT EXIST YET
--
-- The level lives on a SoundGroup rather than on the Sound. The day a settings
-- panel wants a music slider or a mute there is then exactly one property to
-- move, instead of a search for every Sound that counts as music. It costs one
-- instance and it is the difference between adding a feature and doing an
-- audit.
--
--==============================================================================
-- SILENT IS A STATE, NOT A FAILURE
--
-- `sfx/` holds the source files and Roblox cannot read any of them: audio has
-- to be uploaded to the asset server and referenced by id. Until that happens
-- GameConfig.Music.Tracks is empty, and this says so once and stops.
--
-- Deliberately not an error, and deliberately not silent about being silent. A
-- missing SoundId does not throw -- it just never plays -- so without the warn
-- the only symptom would be a game that has no music for a reason nobody can
-- see.
--==============================================================================

local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local MUSIC = GameConfig.Music
local ATTR = GameConfig.Attributes
local CYCLE = GameConfig.WorldCycle
local TRACK_NAME = "SeedMusicTrack"

--==============================================================================
-- RE-RUN SAFE
--
-- Rule 10. A Rojo sync re-runs this script while the old Sound is still playing,
-- and two beds a semitone apart is the kind of thing that gets blamed on the
-- track rather than on the reload.
--==============================================================================
--==============================================================================
-- THE TRACK IS DESTROYED, THE BUS IS NOT
--
-- The SoundGroup belongs to SoundKit now -- it is one of four, and the chase bed
-- ducks this one by moving its Volume. Destroying it here would leave whatever
-- is ducking it holding a reference to a group that is not in SoundService any
-- more, which is a bed that never comes back up.
--
-- SoundKit finds an existing bus before it makes one, so a re-sync reuses the
-- group and only the track is rebuilt.
--==============================================================================
local staleTrack = SoundService:FindFirstChild(TRACK_NAME)
if staleTrack then
	staleTrack:Destroy()
end

--==============================================================================
-- WHAT THERE IS TO PLAY
--
-- Filtered rather than trusted: a commented-out id leaves a hole in the list and
-- an empty string in it would set a SoundId that resolves to nothing, which
-- plays no sound and reports no problem.
--==============================================================================
local function usable(list: { string }?): { string }
	local out: { string } = {}
	for _, id in ipairs(list or {}) do
		if type(id) == "string" and id ~= "" then
			table.insert(out, id)
		end
	end
	return out
end

local tracks: { string } = usable(MUSIC.Tracks)
--==============================================================================
-- AND A SECOND LIST, FOR THE FIFTEEN SECONDS THE ROAD IS SHUT
--
-- Empty is a state here too, and a different one from the day list being empty:
-- no night ids means the day bed keeps playing after dusk, which is what this
-- game did until tonight. So it is not warned about and not reported -- there is
-- nothing wrong with a world that has one bed.
--==============================================================================
local nightTracks: { string } = usable((MUSIC :: any).NightTracks)
--==============================================================================
-- AND A THIRD, WHILE THE RAIN FALLS (2026-10-02)
--
-- Music.RainTracks for a Rain or a Thunderstorm -- the server's weather State
-- "opening" or "active", the same reading Weather.client takes -- ahead of night
-- and day. Read off the attribute, so a late joiner starts on it.
--
-- ONLY WHILE IT CAN PLAY. A probe preloads the id (at start, and again when an
-- event begins after a failed answer); until it has answered the track is tried,
-- and a no puts the day/night bed straight back. An id this experience cannot
-- use must never turn the music into silence for the length of a storm.
--==============================================================================
local rainTracks: { string } = usable((MUSIC :: any).RainTracks)
local WEATHER_STATE = GameConfig.Weather.Attributes.State
local rainOk: boolean? = nil
local PROBE_NAME = "SeedMusicRainProbe"
for _, stale in ipairs(SoundService:GetChildren()) do
	if stale.Name == PROBE_NAME then
		stale:Destroy()
	end
end

local function rainFalling(): boolean
	local state = Workspace:GetAttribute(WEATHER_STATE)
	return state == "opening" or state == "active"
end

--==============================================================================
-- AND A FOURTH, WHILE THE DISCO PLAYS (2026-10-03)
--
-- Music.DiscoTracks (the owner's disco track), while a disco mode of the global
-- mini event runs here (MiniEventState "running", a mode with Disco: Ticket
-- Disco and Disco Only, never Ticket Shower Only) -- ahead of the rain, night
-- and day beds, on this same one Sound, so never two beds at once; looping
-- (one id loops itself in the engine); and STARTED AT THE GLOBAL EVENT'S OWN
-- POSITION -- (server time - MiniEventStartedAt) wrapped by its length -- so a
-- late joiner, or a server that heard about the event late, plays the bar
-- everyone else is on. When it ends the bed the world asks for (the rain's in
-- a storm, else night or day) fades back. Never the rain BGM. An id that will
-- not load is probed, reported and skipped the way the rain's is.
--==============================================================================
local discoTracks: { string } = usable((MUSIC :: any).DiscoTracks)
local MINI = GameConfig.MiniEvent
local MINI_MODES: { [string]: any } = MINI.Modes :: any
local discoOk: boolean? = nil
local DISCO_PROBE = "SeedMusicDiscoProbe"
for _, stale in ipairs(SoundService:GetChildren()) do
	if stale.Name == DISCO_PROBE then
		stale:Destroy()
	end
end

local function discoPlaying(): boolean
	if Workspace:GetAttribute(MINI.Attributes.State) ~= "running" then
		return false
	end
	local mode = MINI_MODES[Workspace:GetAttribute(MINI.Attributes.Mode) or ""]
	return mode ~= nil and mode.Disco == true
end

--==============================================================================
-- AND A FIFTH, WHILE A POD RUSH RUNS (2026-10-09, the owner: the rush needs
-- music)
--
-- Music.PodRushTrack while the global mini event is a running POD RUSH (a mode
-- with PodRush): the disco's place in the order -- the two are both mini
-- events and never run at once -- on this same one Sound, so the chase bed
-- ducks it as it ducks any bed; started at the rush's own position like the
-- disco's, probed and skipped like the rain's. "" keeps the bed that was
-- playing.
--==============================================================================
local rushTracks: { string } = usable({ (MUSIC :: any).PodRushTrack })
local rushOk: boolean? = nil
local RUSH_PROBE = "SeedMusicRushProbe"
for _, stale in ipairs(SoundService:GetChildren()) do
	if stale.Name == RUSH_PROBE then
		stale:Destroy()
	end
end

local function rushPlaying(): boolean
	if Workspace:GetAttribute(MINI.Attributes.State) ~= "running" then
		return false
	end
	local mode = MINI_MODES[Workspace:GetAttribute(MINI.Attributes.Mode) or ""]
	return mode ~= nil and mode.PodRush == true
end

--==============================================================================
-- AND A SIXTH, WHILE THIS PLAYER PLAYS SPROUT DASH (2026-10-09, the owner:
-- "sprout rush")
--
-- GameConfig.SproutDash.Music while THIS player has the minigame's screen open
-- (the LocalPlayer's SproutDash Open attribute, which SproutDashUI writes and
-- no other client sees). FIRST in the order -- the player is in the game,
-- whatever the world is doing -- on this same one Sound, so the music level,
-- mute and the chase bed's duck apply as to any bed; looping; crossfaded over
-- its own FadeSeconds, from its start each time the screen opens; at its own
-- Volume on the beds' scale (levelFor). Probed and skipped like the rain's: an
-- id that cannot load keeps the bed that was playing.
--==============================================================================
local SPROUT = GameConfig.SproutDash
local SPROUT_MUSIC: { [string]: any } = (SPROUT :: any).Music or {}
local sproutTracks: { string } = usable({ SPROUT_MUSIC.Id })
local sproutOk: boolean? = nil
local SPROUT_PROBE = "SeedMusicSproutProbe"
for _, stale in ipairs(SoundService:GetChildren()) do
	if stale.Name == SPROUT_PROBE then
		stale:Destroy()
	end
end
local localPlayer = Players.LocalPlayer

local function sproutOpen(): boolean
	return localPlayer ~= nil and localPlayer:GetAttribute(SPROUT.Attributes.Open) == true
end

if #tracks == 0 then
	warn("[Seed/Music] No ids in GameConfig.Music.Tracks, so there is no music. "
		.. "The pieces in sfx/ are files on disk and Roblox can only play "
		.. "uploaded assets -- convert them to MP3 or OGG, upload them, and "
		.. "paste the ids into GameConfig.Music.Tracks. Nothing else is wrong.")
	return
end

--==============================================================================
-- THE MIXER AND THE TRACK
--==============================================================================
-- Starts silent and is faded up below, so joining does not begin with a slam.
-- SoundKit builds the music bus at zero for exactly that reason; the other three
-- have nothing to fade in from and start at their configured level.
local group = SoundKit.group("Music")
if not group then
	warn("[Seed/Music] No music bus. Nothing will play.")
	return
end

local sound = Instance.new("Sound")
sound.Name = TRACK_NAME
sound.SoundGroup = group
-- The GROUP carries the level. Left at 1 here so there is one number in one
-- place deciding how loud the music is.
sound.Volume = 1
--==============================================================================
-- ONE TRACK LOOPS ITSELF. TWO TAKE TURNS.
--
-- With a single id the engine does the looping, which is seamless in a way
-- nothing written here could be -- restarting a Sound from Lua costs at least a
-- frame and you can hear it. With more than one, Looped has to be off or
-- `Ended` never fires and the second track never gets a turn.
--==============================================================================
sound.Parent = SoundService

--==============================================================================
-- WRAPPING, NOT STOPPING
--
-- `index % #tracks + 1` rather than an if: at the end of the list it returns to
-- the first track, which is what makes a two-track playlist a loop rather than
-- three minutes of music followed by silence for the rest of the session.
--
--==============================================================================
-- Play() DOES NOT REWIND. STOP() IS WHAT REWINDS.
--
-- Measured, because the first version of this did not do it and the playlist
-- ate itself. `Ended` leaves TimePosition at the end of the track that just
-- finished; assigning a new SoundId does not move it, and Play() resumes from
-- wherever the playhead already is. So track two started at track one's ending
-- position -- and if that was past its own length it ended instantly, advanced
-- again, and the two tracks flipped several times a second, forever:
--
--     0.63s  Ended    139171047150584   pos 153.28
--     0.63s  SoundId  140195397978848   pos 153.28   <- inherited, not reset
--     0.65s  Ended    140195397978848   pos   0.00   <- 0.02s later
--     0.65s  SoundId  139171047150584               ... and around again
--
-- Stop() is the call documented as returning TimePosition to zero, so the swap
-- goes stop, change, rewind, play. The explicit zero after it is not redundant:
-- an id that has not finished loading can ignore the reset, and being wrong
-- about this costs a silent track rather than an error.
--
-- None of this can happen with ONE track, because the engine does that loop and
-- `Ended` is never connected -- which is exactly why it would have shipped
-- unnoticed until the second id was pasted in.
--==============================================================================
local index = 1
local current: { string } = tracks

--==============================================================================
-- WHICH LIST THE WORLD IS ASKING FOR
--
-- Workspace.WorldPhase is the one authoritative answer to "is it night" -- the
-- server writes it at dusk and at dawn and it replicates on its own, which is
-- the same signal PlantGlow, PlantSway, WorldClock and the tutorial already read.
-- No remote, no clock of this script's own, and nothing to drift.
--==============================================================================
local function listFor(): { string }
	-- Sprout Dash's own while this player has its screen open (2026-10-09).
	if #sproutTracks > 0 and sproutOk ~= false and sproutOpen() then
		return sproutTracks
	end
	-- The disco next, once it has a track that loads (2026-10-03).
	if #discoTracks > 0 and discoOk ~= false and discoPlaying() then
		return discoTracks
	end
	-- A Pod Rush in the disco's place (2026-10-09): never at the same time.
	if #rushTracks > 0 and rushOk ~= false and rushPlaying() then
		return rushTracks
	end
	-- The rain next: a storm at night is still a storm.
	if #rainTracks > 0 and rainOk ~= false and rainFalling() then
		return rainTracks
	end
	if #nightTracks > 0
		and Workspace:GetAttribute(ATTR.WorldPhase) == CYCLE.PhaseNight then
		return nightTracks
	end
	return tracks
end

-- The Sound's own level under a list: 1 for every bed but Sprout Dash's, whose
-- Volume is on the beds' scale -- Music.Volume is what the bus carries, so its
-- own over that is what the Sound adds.
local function levelFor(list: { string }): number
	if list == sproutTracks then
		local base = tonumber(MUSIC.Volume) or 0
		local own = tonumber(SPROUT_MUSIC.Volume)
		if base > 0 and own then
			return math.clamp(own / base, 0, 3)
		end
	end
	return 1
end

--==============================================================================
-- ONE PLACE THAT CHANGES WHAT IS PLAYING
--
-- Stop, change, rewind, play -- in that order, for the reason written above: a
-- new SoundId inherits the old playhead and Play() does not rewind, and getting
-- that wrong is what made the two-track playlist eat itself.
--
-- `Looped` is set from the list being started rather than once at the top,
-- because the two lists are different lengths: the night bed is one track and
-- loops itself in the engine, the day bed is two and takes turns. It was a
-- constant when there was only one list.
--==============================================================================
local function playTrack(list: { string }, at: number)
	current = list
	index = at
	sound:Stop()
	sound.Looped = #list == 1
	sound.SoundId = list[at]
	sound.TimePosition = 0
	sound:Play()
end

--==============================================================================
-- Ended IS CONNECTED UNCONDITIONALLY NOW
--
-- It used to be skipped when there was one track, because a Looped sound never
-- raises it. That is still true -- but which list is playing can change at dusk,
-- so a connection made once at startup has to be able to serve the OTHER list
-- later. Connecting it costs nothing on a looping track: the event does not fire.
--==============================================================================
sound.Ended:Connect(function()
	playTrack(current, index % #current + 1)
end)

playTrack(listFor(), 1)
sound.Volume = levelFor(current)

--==============================================================================
-- DUSK AND DAWN, AS A CROSSFADE THE SKY IS ALREADY DOING
--
-- On the SOUND'S OWN Volume and not on the bus. The bus is the mixer: the chase
-- duck moves it, the settings slider moves it, and SoundKit.fadeMusic aims it at
-- the player's chosen level. A fade written here that touched the group would
-- fight all three and would end by restoring a level the player had turned down.
-- The Sound underneath it is this script's to move.
--
-- HALF OUT, SWAP, HALF IN, so the change of track lands in the quiet in the
-- middle rather than under the outgoing piece. The token is what stops two dusks
-- in quick succession -- a re-sync, or an admin flipping the phase -- from
-- leaving a fade-in scheduled for a track that is no longer the one playing.
--==============================================================================
local swap = 0
-- Declared here, written with the disco's clock below: a swap calls it, and a
-- local function written after applyPhase would be a nil global to it.
local alignDisco: () -> ()

local function fadeSound(to: number, seconds: number)
	TweenService:Create(sound, TweenInfo.new(seconds, Enum.EasingStyle.Sine), {
		Volume = to,
	}):Play()
end

local function applyPhase()
	local want = listFor()
	if want == current then
		return
	end
	swap += 1
	local token = swap
	-- The rain's bed comes and goes over its own, gentler fade; dusk and dawn
	-- keep the sky's.
	local seconds = if want == sproutTracks or current == sproutTracks
		then tonumber(SPROUT_MUSIC.FadeSeconds) or 1.5
		elseif want == discoTracks or current == discoTracks
		then tonumber((MUSIC :: any).DiscoFadeSeconds) or 3.0
		elseif want == rushTracks or current == rushTracks
		then tonumber((MUSIC :: any).PodRushFadeSeconds) or 3.0
		elseif want == rainTracks or current == rainTracks
		then tonumber((MUSIC :: any).RainFadeSeconds) or 4.0
		else tonumber((MUSIC :: any).PhaseFadeSeconds) or 3.0
	local half = math.max(0.15, seconds * 0.5)
	fadeSound(0, half)
	task.delay(half, function()
		if swap ~= token or not sound.Parent then
			return
		end
		playTrack(want, 1)
		alignDisco()
		fadeSound(levelFor(want), half)
	end)
end

Workspace:GetAttributeChangedSignal(ATTR.WorldPhase):Connect(applyPhase)

--==============================================================================
-- THE DISCO ON THE EVENT'S CLOCK (2026-10-03)
--
-- The track's length is only known once it has loaded, so this waits for it
-- (a few seconds at most) and then moves the playhead to where the global event
-- is: every client starting from the same MiniEventStartedAt lands on the same
-- bar. Dropped if anything else has started playing meanwhile. The Pod Rush's
-- bed (2026-10-09) is put on its event's clock the same way.
--==============================================================================
function alignDisco()
	local started = Workspace:GetAttribute(MINI.Attributes.StartedAt)
	local list = current
	if type(started) ~= "number" or (list ~= discoTracks and list ~= rushTracks) then
		return
	end
	local token = swap
	task.spawn(function()
		local waited = 0
		while sound.TimeLength <= 0 and waited < 10 do
			waited += task.wait(0.1)
			if swap ~= token or current ~= list or not sound.Parent then
				return
			end
		end
		local length = sound.TimeLength
		if length > 0 and swap == token and current == list then
			sound.TimePosition = math.max(0, Workspace:GetServerTimeNow() - started) % length
		end
	end)
end

--==============================================================================
-- ONE PROBE FOR EVERY EVENT BED (2026-10-09)
--
-- A silent Sound preloads a bed's id and its IsLoaded is the answer, handed to
-- `onAnswer`; then it goes. The rain's, the disco's and the rush's each ask it
-- through their own function below, so this client only ever builds its one
-- track Sound and this one probe.
--==============================================================================
local function probeBed(id: string, name: string, onAnswer: (boolean) -> ())
	task.spawn(function()
		local probe = Instance.new("Sound")
		probe.Name = name
		probe.SoundId = id
		probe.Volume = 0
		probe.Parent = SoundService
		pcall(function()
			ContentProvider:PreloadAsync({ probe })
		end)
		local loaded = probe.IsLoaded
		probe:Destroy()
		onAnswer(loaded)
	end)
end

-- The rain's probe: one preload of the id, its answer kept, the bed re-chosen.
local probing = false
local function probeRain()
	if #rainTracks == 0 or probing then
		return
	end
	probing = true
	probeBed(rainTracks[1], PROBE_NAME, function(loaded: boolean)
		probing = false
		if not loaded and rainOk ~= false then
			warn(string.format("[Seed/Music] The rain bed %s did not load, so the day/night bed plays "
				.. "through the weather. An audio asset has to be usable by this experience AND have "
				.. "cleared moderation.", rainTracks[1]))
		end
		rainOk = loaded
		applyPhase()
	end)
end

Workspace:GetAttributeChangedSignal(WEATHER_STATE):Connect(function()
	if rainOk == false and rainFalling() then
		probeRain()
	end
	applyPhase()
end)
probeRain()

-- The disco's probe, the rain's shape; it does nothing while the hook is empty.
local probingDisco = false
local function probeDisco()
	if #discoTracks == 0 or probingDisco then
		return
	end
	probingDisco = true
	probeBed(discoTracks[1], DISCO_PROBE, function(loaded: boolean)
		probingDisco = false
		if not loaded and discoOk ~= false then
			warn(string.format("[Seed/Music] The disco bed %s did not load, so the bed that was playing carries on "
				.. "through the disco.", discoTracks[1]))
		end
		discoOk = loaded
		applyPhase()
	end)
end
-- The rush's probe, the same; nothing while Music.PodRushTrack is "".
local probingRush = false
local function probeRush()
	if #rushTracks == 0 or probingRush then
		return
	end
	probingRush = true
	probeBed(rushTracks[1], RUSH_PROBE, function(loaded: boolean)
		probingRush = false
		if not loaded and rushOk ~= false then
			warn(string.format("[Seed/Music] The Pod Rush bed %s did not load, so the bed that was playing carries "
				.. "on through the rush.", rushTracks[1]))
		end
		rushOk = loaded
		applyPhase()
	end)
end
local function onDisco()
	if discoOk == false and discoPlaying() then
		probeDisco()
	end
	if rushOk == false and rushPlaying() then
		probeRush()
	end
	applyPhase()
end
Workspace:GetAttributeChangedSignal(MINI.Attributes.State):Connect(onDisco)
Workspace:GetAttributeChangedSignal(MINI.Attributes.Mode):Connect(onDisco)
probeDisco()
probeRush()
-- Sprout Dash's probe, the same; nothing while its Music.Id is "". Its screen
-- opening or closing re-chooses the bed (2026-10-09).
local probingSprout = false
local function probeSprout()
	if #sproutTracks == 0 or probingSprout then
		return
	end
	probingSprout = true
	probeBed(sproutTracks[1], SPROUT_PROBE, function(loaded: boolean)
		probingSprout = false
		if not loaded and sproutOk ~= false then
			warn(string.format("[Seed/Music] The Sprout Dash bed %s did not load, so the bed that was playing "
				.. "carries on under the minigame.", sproutTracks[1]))
		end
		sproutOk = loaded
		applyPhase()
	end)
end
if localPlayer then
	localPlayer:GetAttributeChangedSignal(SPROUT.Attributes.Open):Connect(function()
		if sproutOk == false and sproutOpen() then
			probeSprout()
		end
		applyPhase()
	end)
end
probeSprout()
-- Joined during a disco: the first track chosen above was the disco's.
alignDisco()

-- Through SoundKit rather than a tween of its own. The chase duck and the
-- settings panel move this bus too, and all three have to aim at one number:
-- the configured bed times the level the player chose. A private tween here
-- would fade up to the configured bed over a player who had muted it.
SoundKit.fadeMusic(MUSIC.FadeSeconds)

--==============================================================================
-- DID IT ACTUALLY LOAD
--
-- An id that is well-formed but wrong -- a track still in moderation, or one
-- owned by another account -- behaves exactly like a correct one right up until
-- nothing comes out of the speakers. PreloadAsync waits for the answer, and
-- IsLoaded is the answer.
--
-- Spawned, because preloading blocks and the fade above should not wait on the
-- network to start.
--==============================================================================
task.spawn(function()
	local ok = pcall(function()
		ContentProvider:PreloadAsync({ sound })
	end)
	if not ok or not sound.IsLoaded then
		warn(string.format("[Seed/Music] %s did not load. An audio asset has to "
			.. "be owned by the account that owns this place AND have cleared "
			.. "moderation; a pending upload plays nothing and says nothing.",
			sound.SoundId))
	end
end)
