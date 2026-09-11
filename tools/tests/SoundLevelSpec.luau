--!strict
--==============================================================================
-- Steal a Seed :: SoundLevelSpec
--
-- The settings panel's audio half, in SoundKit: a level and a mute per bus, the
-- one Music target that the join fade, the chase duck and the panel share, and a
-- server one-shot routed through the client's own bus. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("SoundLevelSpec"))
--
-- The real SoundKit, fresh-required. Edit reports RunService:IsClient() as true,
-- so the buses are real SoundGroups in SoundService: any this spec creates are
-- destroyed at the end, and any already there get their Volume back. play and
-- stop are stubbed for the chase, so no bed starts playing in Studio.
--
-- Not here, verified in Play instead: the panel, a drag, and what is heard.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")

local Shared = game.ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local SoundKit = require(Shared.SoundKit)

local MUSIC = GameConfig.Music
local SFX: any = GameConfig.Sfx
local MIXER: any = SFX.Mixer

local pass = 0
local fails: { string } = {}
local function check(ok: boolean, label: string)
	if ok then
		pass += 1
	else
		table.insert(fails, label)
	end
end

local function near(a: any, b: number): boolean
	return type(a) == "number" and math.abs(a - b) < 1e-4
end

local before: { [Instance]: number } = {}
for _, c in ipairs(SoundService:GetChildren()) do
	if c:IsA("SoundGroup") then
		before[c] = c.Volume
	end
end

local fixture = Instance.new("Folder")
fixture.Name = "SoundLevelSpecFixture"
fixture.Parent = workspace

local kit: any = SoundKit
local realPlay, realStop, realGroup = kit.play, kit.stop, kit.group

local ok, err = pcall(function()
	--== 1. DEFAULTS ===========================================================
	local level, muted = SoundKit.level("Music")
	check(level == 1 and muted == false, "every bus starts at full and unmuted")
	local bed = MUSIC.Volume * (MIXER.Music or 1)
	check(near(SoundKit.musicLevel(), bed), "the Music target starts at the configured bed")

	--== 2. A LEVEL AND A MUTE ON ONE BUS ======================================
	SoundKit.setLevel("UI", 0.5)
	local ui = SoundKit.group("UI") :: SoundGroup
	check(near(ui.Volume, (MIXER.UI or 1) * 0.5), "UI at half is the mixer level times 0.5")
	SoundKit.setLevel("UI", nil, true)
	local l2, m2 = SoundKit.level("UI")
	check(near(ui.Volume, 0) and l2 == 0.5 and m2 == true,
		"muting silences the bus and keeps the level under it")
	SoundKit.setLevel("UI", nil, false)
	check(near(ui.Volume, (MIXER.UI or 1) * 0.5), "unmuting puts the half back")

	SoundKit.setLevel("World", 1.7)
	local world = SoundKit.group("World") :: SoundGroup
	check(near(world.Volume, MIXER.World or 1) and (SoundKit.level("World")) == 1,
		"a level past 1 clamps to 1")
	SoundKit.setLevel("World", -3)
	check(near(world.Volume, 0), "a level under 0 clamps to 0")
	SoundKit.setLevel("World", 0 / 0)
	check(near(world.Volume, 0) and (SoundKit.level("World")) == 0, "NaN is ignored")
	check(pcall(SoundKit.setLevel, "Nope", 0.3) and SoundService:FindFirstChild("SeedNope") == nil,
		"an unknown bus is ignored and builds nothing")
	local chase = SoundKit.group("Chase") :: SoundGroup
	check(near(chase.Volume, MIXER.Chase or 1), "Chase is not moved by UI or World")

	--== 3. THE MUSIC TARGET ===================================================
	SoundKit.setLevel("Music", 0.25)
	local music = SoundKit.group("Music") :: SoundGroup
	check(near(SoundKit.musicLevel(), bed * 0.25), "the Music target carries the player's level")
	check(near(music.Volume, bed * 0.25), "and the bus is moved to it at once")
	SoundKit.setLevel("Music", nil, true)
	check(near(music.Volume, 0) and near(SoundKit.musicLevel(), 0),
		"a muted bed is silent and aims at silence")
	SoundKit.setLevel("Music", nil, false)
	music.Volume = 0
	SoundKit.fadeMusic(0)
	check(near(music.Volume, bed * 0.25),
		"the join fade lands on the player's level, not on the configured bed")

	--== 4. THE CHASE DUCK RESPECTS IT =========================================
	local played = 0
	kit.play = function(name: string): any
		played += 1
		return if name == "ChaseBed" then Instance.new("Sound") else nil
	end
	kit.stop = function() end
	SoundKit.chase(true)
	check(played == 1, "the chase asked for its bed")
	check(near(SoundKit.musicLevel(), bed * 0.25 * SFX.MusicDuck),
		"ducked is the duck times the player's level")
	SoundKit.setLevel("Music", 0.5)
	check(near(music.Volume, bed * 0.5 * SFX.MusicDuck),
		"a level change during a chase stays ducked")
	-- TweenService does not advance in Edit -- measured: a 0.6s duck tween had
	-- not moved the bus 0.9s later -- so the un-duck is checked by where it AIMS.
	-- musicLevel is the one target moveMusic tweens to; the landing is Play's.
	SoundKit.chase(false)
	check(near(SoundKit.musicLevel(), bed * 0.5),
		"the chase ending aims back at the player's level, not at full")
	SoundKit.setLevel("Music", nil, true)
	SoundKit.chase(true)
	SoundKit.chase(false)
	check(near(SoundKit.musicLevel(), 0) and near(music.Volume, 0),
		"a chase ending never aims a muted bed back up")

	--== 5. A SERVER ONE-SHOT, ROUTED ==========================================
	local routed = Instance.new("Sound")
	routed.Volume = 0.9
	routed:SetAttribute("SeedBus", "World")
	routed:SetAttribute("SeedBaseVolume", 0.37)
	routed.Parent = fixture
	SoundKit.routeServerCue(routed)
	check(routed.SoundGroup == world and near(routed.Volume, 0.37),
		"a tagged server cue joins its bus at its unbaked volume")
	local stray = Instance.new("Sound")
	stray.Volume = 0.9
	stray.Parent = fixture
	SoundKit.routeServerCue(stray)
	check(stray.SoundGroup == nil and near(stray.Volume, 0.9), "a Sound with no bus is left alone")
	local wrong = Instance.new("Sound")
	wrong:SetAttribute("SeedBus", "Nope")
	wrong.Parent = fixture
	SoundKit.routeServerCue(wrong)
	check(wrong.SoundGroup == nil, "a Sound naming an unknown bus is left alone")
	check(pcall(SoundKit.routeServerCue, fixture), "a non-Sound is ignored")

	--== 6. THE SERVER SIDE OF EMIT TAGS WHAT IT PLAYS =========================
	-- group() answers nil on a server; that is stood in here, and the Sound is
	-- played four thousand studs from any listener and destroyed straight away.
	local cueName: string? = nil
	for name, cue in pairs(SFX.Cues) do
		if type(cue.id) == "string" and cue.id ~= "" and (cue.group == nil or cue.group == "World") then
			cueName = name
			break
		end
	end
	check(cueName ~= nil, "there is a World cue with an id to emit")
	if cueName then
		local anchor = Instance.new("Part")
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.Transparency = 1
		anchor.CFrame = CFrame.new(4000, 4000, 4000)
		anchor.Parent = fixture
		kit.group = function(): any
			return nil
		end
		local sound = SoundKit.emit(cueName, anchor)
		kit.group = realGroup
		local cue = SFX.Cues[cueName]
		local bus = cue.group or "World"
		local base = cue.volume or 0.5
		check(sound ~= nil and CollectionService:HasTag(sound, GameConfig.Tags.ServerCue),
			"a server emit is tagged ServerCue")
		check(sound ~= nil and sound:GetAttribute("SeedBus") == bus, "and names its bus")
		check(sound ~= nil and near(sound:GetAttribute("SeedBaseVolume"), base),
			"and carries its unbaked volume")
		check(sound ~= nil and near(sound.Volume, base * (MIXER[bus] or 1)),
			"and still bakes the mixer in, for a client that never routes it")
		if sound then
			sound:Destroy()
		end
	end
end)

kit.play, kit.stop, kit.group = realPlay, realStop, realGroup
fixture:Destroy()
for _, c in ipairs(SoundService:GetChildren()) do
	if c:IsA("SoundGroup") then
		local was = before[c]
		if was == nil then
			c:Destroy()
		else
			c.Volume = was
		end
	end
end

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return ("SoundLevelSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails, table.concat(fails, "\n  "))
end
return ("SoundLevelSpec: %d passed, 0 failed"):format(pass)
