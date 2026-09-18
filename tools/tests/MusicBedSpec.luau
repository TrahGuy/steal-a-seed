--!nocheck
--==============================================================================
-- Steal a Seed :: MusicBedSpec
--
-- The beds: one list by day, one at night, and the chase. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("MusicBedSpec"))
--
-- MUSIC IS NOT A CUE, so it is not in SFX.Cues and SfxWiringSpec does not cover
-- it: the day and night beds are plain lists of ids that Music.client plays, and
-- the only thing in this game that decides between them is Workspace.WorldPhase.
--
-- WHAT WOULD ACTUALLY GO WRONG, in the order it would hurt:
--
--   1. THE NIGHT LIST STOPS THE DAY ONE. Music.client has to fall back to the day
--      bed when there are no night ids, because that is what this game did before
--      the list existed and an empty list must not be silence.
--   2. THE FADE TOUCHES THE BUS. The music GROUP is the mixer -- the chase duck,
--      the settings slider and the join fade all aim at it. A dusk crossfade
--      written onto the group would fight all three and end by restoring a level
--      the player had turned down. It has to move the Sound underneath it.
--   3. Looped IS SET ONCE. It used to be a constant because there was one list;
--      with two lists of different lengths it has to be set per track, or the
--      two-track day bed never advances and the one-track night bed never repeats.
--
-- Not here: whether the beds SOUND right together, and the crossfade itself,
-- which needs a dusk (Play, and a sixty-second night every seven minutes).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local pass, fails = 0, {}
local out = {}

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		table.insert(fails, label)
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

local MUSIC = GameConfig.Music
local CYCLE = GameConfig.WorldCycle

--==============================================================================
-- 1. THE TWO LISTS
--==============================================================================
say("-- the lists --")

local function idsOf(list)
	local ids = {}
	for _, id in ipairs(list or {}) do
		if type(id) == "string" and id ~= "" then
			table.insert(ids, id)
		end
	end
	return ids
end

local day = idsOf(MUSIC.Tracks)
local night = idsOf(MUSIC.NightTracks)

check(#day == 2, "two takes of the garden bed, played in turn", #day)
check(#night == 1, "one piece at night", #night)
check(day[1] == "rbxassetid://133940553394248" and day[2] == "rbxassetid://70722559996799",
	"the day bed is the two Garden at First Light takes")
check(night[1] == "rbxassetid://115368148164882",
	"the night bed is Night Background Music", night[1])

local seen, overlap = {}, {}
for _, id in ipairs(day) do
	seen[id] = "day"
end
for _, id in ipairs(night) do
	if seen[id] then
		table.insert(overlap, id)
	end
end
check(#overlap == 0, "no track is in both lists -- dusk always changes something",
	table.concat(overlap, ", "))

for _, id in ipairs({ day[1], day[2], night[1] }) do
	check(type(id) == "string" and string.match(id, "^rbxassetid://%d+$") ~= nil,
		"well-formed id: " .. tostring(id))
end

--==============================================================================
-- 2. THE CROSSFADE IS THE SKY'S, BY VALUE
--
-- Two durations for one event is two events to anybody standing in the road, so
-- this is asserted rather than described. Change one and this line makes somebody
-- decide about the other.
--==============================================================================
say("\n-- dusk --")

check(MUSIC.PhaseFadeSeconds == CYCLE.Night.FadeSeconds,
	"the bed crossfades over exactly as long as the lighting does",
	string.format("%s vs %s", tostring(MUSIC.PhaseFadeSeconds),
		tostring(CYCLE.Night.FadeSeconds)))
check(type(MUSIC.PhaseFadeSeconds) == "number" and MUSIC.PhaseFadeSeconds > 0
		and MUSIC.PhaseFadeSeconds < CYCLE.NightSeconds * 0.25,
	"and is a fraction of the night, not a chunk of it",
	MUSIC.PhaseFadeSeconds)
check(CYCLE.PhaseNight == "Night" and CYCLE.PhaseDay == "Day",
	"the phase names the client compares against are unchanged")

--==============================================================================
-- 3. THE CHASE BED
--==============================================================================
say("\n-- the chase --")

local chase = GameConfig.Sfx.Cues.ChaseBed
check(chase ~= nil and chase.id == "rbxassetid://97007444825023",
	"the chase bed is the 2026-09-17 recording", chase and chase.id)
check(chase ~= nil and chase.id ~= "rbxassetid://86935894428393",
	"and not the 5.56s loop recovered out of the inventory")
check(chase ~= nil and chase.id ~= "rbxassetid://110892791280400",
	"nor the second tier, which is still waiting for a state to escalate on")
check(chase ~= nil and chase.looped == true, "it loops", chase and tostring(chase.looped))
check(chase ~= nil and chase.group == "Chase",
	"on its own bus, so muting the music does not mute the monster", chase and chase.group)
check(chase ~= nil and chase.clip == nil and chase.start == nil,
	"and carries no window -- a bed is not a hit with a decay")
check(chase ~= nil and type(chase.volume) == "number"
		and chase.volume > 0 and chase.volume <= 1.5,
	"at a level inside the band", chase and chase.volume)
check(SoundKit.cue("ChaseBed") ~= nil, "and it resolves")

--==============================================================================
-- 4. WHAT MUSIC.CLIENT ACTUALLY DOES
--
-- Source-level, because every one of these needs a running client and a dusk.
-- They are the three failures named at the top of this file.
--==============================================================================
say("\n-- the client --")

local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local music = scripts and scripts:FindFirstChild("Music")
local src = nil
if music then
	local ok, value = pcall(function()
		return (music :: any).Source
	end)
	src = if ok then value else nil
end

check(src ~= nil, "Music.client is in the tree")
check(src ~= nil and src:find("ATTR.WorldPhase", 1, true) ~= nil,
	"it reads the world's phase rather than keeping a clock of its own")
check(src ~= nil and src:find("GetAttributeChangedSignal(ATTR.WorldPhase)", 1, true) ~= nil,
	"and listens for the change rather than polling it")
check(src ~= nil and src:find("#nightTracks > 0", 1, true) ~= nil,
	"an empty night list falls back to the day bed instead of silence")
check(src ~= nil and src:find("TweenService:Create(sound", 1, true) ~= nil,
	"the crossfade moves the Sound")
check(src ~= nil and src:find("TweenService:Create(group", 1, true) == nil
		and src:find("group.Volume =", 1, true) == nil,
	"and never the bus, which belongs to the duck and the slider")
check(src ~= nil and src:find("sound.Looped = #list == 1", 1, true) ~= nil,
	"Looped is decided by the list that is starting, not once at the top")
check(src ~= nil and src:find("sound.Ended:Connect", 1, true) ~= nil
		and src:find("if not sound.Looped then", 1, true) == nil,
	"Ended is connected unconditionally, so the other list is served too")
check(src ~= nil and src:find("sound:Stop()", 1, true) ~= nil
		and src:find("sound.TimePosition = 0", 1, true) ~= nil,
	"and a swap still goes stop, change, rewind, play")

if #fails > 0 then
	return ("MusicBedSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails,
		table.concat(fails, "\n  "))
end
return ("MusicBedSpec: %d passed, 0 failed"):format(pass)
