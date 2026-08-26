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
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local MUSIC = GameConfig.Music
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
local tracks: { string } = {}
for _, id in ipairs(MUSIC.Tracks) do
	if type(id) == "string" and id ~= "" then
		table.insert(tracks, id)
	end
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
sound.Looped = #tracks == 1
sound.SoundId = tracks[1]
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

if not sound.Looped then
	sound.Ended:Connect(function()
		index = index % #tracks + 1
		sound:Stop()
		sound.SoundId = tracks[index]
		sound.TimePosition = 0
		sound:Play()
	end)
end

sound:Play()

TweenService:Create(group, TweenInfo.new(MUSIC.FadeSeconds,
	Enum.EasingStyle.Linear), { Volume = MUSIC.Volume }):Play()

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
