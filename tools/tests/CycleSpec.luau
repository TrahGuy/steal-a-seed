--!strict
-- Steal a Seed :: CycleSpec
--
-- The day/night cycle's tests. Run it with the shared runner:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("CycleSpec"))
--
--==============================================================================
-- WHAT IS HERE AND WHAT IS IN A PLAYTEST
--
-- A cycle is a statement about a running server: pods existing, a barrier
-- turning solid, a player being moved off a road. None of that can be asserted
-- from a module, and mocking it would be testing the mock.
--
-- So this covers the part that CAN be wrong quietly -- the numbers, the shape of
-- the config, and the two arithmetic facts the whole system rests on -- and the
-- behaviour is proven in a Play session instead, with the observed timings
-- written into the commit message rather than into an assertion nobody runs.
--
-- The one thing worth saying about coverage: the value of these is that they
-- fail when somebody retunes the day and forgets the warning is measured against
-- it, or removes a species and leaves a nest expecting pods.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local passed = 0
local failures: { string } = {}
local lines: { string } = {}

local function ok(name: string, condition: boolean, detail: string?)
	if condition then
		passed += 1
	else
		table.insert(failures, name .. (if detail then "  -- " .. detail else ""))
	end
end

local function section(title: string)
	table.insert(lines, "")
	table.insert(lines, "== " .. title .. " ==")
end

local CYCLE = GameConfig.WorldCycle

--==============================================================================
-- 1. THE LOCKED NUMBERS
--==============================================================================
section("the cycle")
ok("the day is 420 seconds", CYCLE.DaySeconds == 420, tostring(CYCLE.DaySeconds))
ok("the night is 60 seconds", CYCLE.NightSeconds == 60, tostring(CYCLE.NightSeconds))
ok("the warning is 45 seconds", CYCLE.WarnSeconds == 45, tostring(CYCLE.WarnSeconds))
ok("the warning fits inside the day", CYCLE.WarnSeconds < CYCLE.DaySeconds)
ok("the night is shorter than the day", CYCLE.NightSeconds < CYCLE.DaySeconds)
ok("the phases are the two strings everything compares against",
	CYCLE.PhaseDay == "Day" and CYCLE.PhaseNight == "Night")
table.insert(lines, string.format(
	"  %ds day + %ds night = a %.1f minute cycle, warning at %ds",
	CYCLE.DaySeconds, CYCLE.NightSeconds,
	(CYCLE.DaySeconds + CYCLE.NightSeconds) / 60, CYCLE.WarnSeconds))

--==============================================================================
-- 2. THE PHASE READ, WHICH TWO SERVICES DEPEND ON BEFORE IT EXISTS
--
-- CarryService and BiomeGateService both ask this, and both Start before
-- WorldCycleService does. An unset attribute therefore has to mean DAY -- a
-- server whose cycle service failed to start must be a server where the game
-- works, not one where every pod is unreachable and nobody can find out why.
--==============================================================================
section("the phase read")
do
	local before = workspace:GetAttribute(GameConfig.Attributes.WorldPhase)
	workspace:SetAttribute(GameConfig.Attributes.WorldPhase, nil)
	ok("unset reads as Day", GameConfig.isDay() == true)
	workspace:SetAttribute(GameConfig.Attributes.WorldPhase, CYCLE.PhaseNight)
	ok("Night reads as not-Day", GameConfig.isDay() == false)
	workspace:SetAttribute(GameConfig.Attributes.WorldPhase, CYCLE.PhaseDay)
	ok("Day reads as Day", GameConfig.isDay() == true)
	workspace:SetAttribute(GameConfig.Attributes.WorldPhase, "nonsense")
	ok("an unknown string is not Night", GameConfig.isDay() == true)
	workspace:SetAttribute(GameConfig.Attributes.WorldPhase, before)
	table.insert(lines, "  restored the live attribute after poking it")
end

--==============================================================================
-- 3. THE THREE REPLICATED FACTS
--==============================================================================
section("what is published")
ok("there is a phase attribute name",
	type(GameConfig.Attributes.WorldPhase) == "string")
ok("there is a deadline attribute name",
	type(GameConfig.Attributes.WorldPhaseEndsAt) == "string")
ok("there is a cycle index attribute name",
	type(GameConfig.Attributes.WorldCycleIndex) == "string")
ok("the three names are distinct",
	GameConfig.Attributes.WorldPhase ~= GameConfig.Attributes.WorldPhaseEndsAt
		and GameConfig.Attributes.WorldPhase ~= GameConfig.Attributes.WorldCycleIndex
		and GameConfig.Attributes.WorldPhaseEndsAt ~= GameConfig.Attributes.WorldCycleIndex)
--==========================================================================
-- NO REMOTE CARRIES THE CYCLE
--
-- The whole design is three attribute writes per phase instead of a broadcast
-- per second. If a cycle remote ever appears in GameConfig.Remotes, somebody has
-- started sending what the client can already work out.
--==========================================================================
do
	local suspect = {}
	for _, name in pairs(GameConfig.Remotes) do
		local lower = string.lower(name)
		if string.find(lower, "phase") or string.find(lower, "cycle")
			or string.find(lower, "night") or string.find(lower, "day") then
			table.insert(suspect, name)
		end
	end
	ok("no remote is named for the cycle", #suspect == 0, table.concat(suspect, ", "))
	table.insert(lines, string.format("  %d remote(s) exist, none of them for the clock",
		(function() local n = 0 for _ in pairs(GameConfig.Remotes) do n += 1 end return n end)()))
end

--==============================================================================
-- 4. THE BARRIER'S GEOMETRY
--
-- It has to cover the corridor from the floor to above the walls, or there is a
-- gap to see over or hop through. Checked as arithmetic against the map's own
-- dimensions rather than against typed numbers, so widening the corridor cannot
-- silently leave the barrier too narrow.
--==============================================================================
section("the barrier")
do
	local B = CYCLE.Barrier
	local MAP = GameConfig.Map
	ok("it is wider than the corridor", B.WidthPad > 0)
	ok("it clears the corridor walls on both sides",
		MAP.CorridorWidth + B.WidthPad >= MAP.CorridorWidth + MAP.WallThickness * 2,
		string.format("%d vs %d", MAP.CorridorWidth + B.WidthPad,
			MAP.CorridorWidth + MAP.WallThickness * 2))
	ok("it stands above the walls", B.HeightPad > 0)
	ok("it is thick enough not to be stepped through at speed",
		B.Thickness >= 2, tostring(B.Thickness))
	--======================================================================
	-- OPAQUE, NOT NEARLY OPAQUE
	--
	-- 0.08 was tried and it leaked: the biome arch's name plate is a SurfaceGui
	-- with LightInfluence = 0, so it renders at full brightness whatever the
	-- lighting does, and eight percent of that against a black corridor is
	-- perfectly readable. Anything unlit behind the barrier would do the same.
	--======================================================================
	ok("it is fully opaque at night", B.NightTransparency == 0,
		tostring(B.NightTransparency))
	table.insert(lines, string.format(
		"  %d x %d studs across a %d-stud corridor with %d-stud walls, %d thick",
		MAP.CorridorWidth + B.WidthPad, MAP.WallHeight + B.HeightPad,
		MAP.CorridorWidth, MAP.WallHeight, B.Thickness))
end

--==============================================================================
-- 5. THE SUPPLY, STATED OUT LOUD
--
-- The number the owner has to approve before it changes. One nest of five pods
-- per cycle is the entire Greenhollow economy for up to six players.
--==============================================================================
section("the supply")
do
	local live, nests, pods = {}, 0, 0
	for _, biome in ipairs(BiomeData.Biomes) do
		if biome.LiveInPhaseA then
			nests += biome.Nests
			pods += biome.Nests * biome.PodsPerNest
			table.insert(live, biome.Id)
		end
		local species = SeedData.InBiome(biome.Id)
		--==================================================================
		-- A BIOME WITHOUT SPECIES CANNOT BE LIVE
		--
		-- growPod rolls a species and gives up if there is none, so a live biome
		-- with an empty pool would produce a nest of nothing every dawn and no
		-- error to explain it. This is the assertion that would fail the day
		-- somebody flips LiveInPhaseA on Dustbowl before its art exists.
		--==================================================================
		if biome.LiveInPhaseA then
			ok(biome.Id .. " has species to roll", #species > 0,
				tostring(#species) .. " species")
		end
		table.insert(lines, string.format("  %-12s live=%-5s species=%d  %d nest(s) x %d pod(s)",
			biome.Id, tostring(biome.LiveInPhaseA), #species,
			biome.Nests, biome.PodsPerNest))
	end
	ok("exactly one biome is live", #live == 1, table.concat(live, ", "))
	table.insert(lines, string.format(
		"  SERVER SUPPLY: %d pod(s) per %.1f-minute cycle, across %d nest(s), for up to %d players",
		pods, (CYCLE.DaySeconds + CYCLE.NightSeconds) / 60, nests, GameConfig.MaxPlayers))
	table.insert(lines, string.format(
		"  that is one pod per %.1f player-minutes at a full server",
		(GameConfig.MaxPlayers * (CYCLE.DaySeconds + CYCLE.NightSeconds) / 60) / math.max(pods, 1)))
end

--==============================================================================
-- 6. THE NIGHT LOOK
--
-- Readable, not black. The plots stay usable through the night, and a night that
-- made a player's own garden unreadable would be a night they wait out looking
-- at a wall.
--==============================================================================
section("night lighting")
do
	local N = CYCLE.Night
	ok("night is dimmer than day", N.Brightness < 2.4, tostring(N.Brightness))
	ok("but not dark", N.Brightness > 0.5, tostring(N.Brightness))
	ok("night ambient is blue, not grey",
		N.Ambient.B > N.Ambient.R, "blue channel must lead")
	ok("the fade is long enough to read as a transition", N.FadeSeconds >= 1)
	ok("and short enough to finish well inside the night",
		N.FadeSeconds < CYCLE.NightSeconds * 0.25,
		string.format("%.1fs of a %ds night", N.FadeSeconds, CYCLE.NightSeconds))
	table.insert(lines, string.format(
		"  brightness %.1f -> %.1f, ambient blue %d, over %.1fs",
		2.4, N.Brightness, N.Ambient.B * 255, N.FadeSeconds))
end

--==============================================================================
-- THE TAIL
--==============================================================================
table.insert(lines, "")
table.insert(lines, string.rep("-", 62))
if #failures == 0 then
	table.insert(lines, string.format("PASS -- %d assertions", passed))
else
	table.insert(lines, string.format("FAIL -- %d passed, %d FAILED", passed, #failures))
	for _, f in ipairs(failures) do
		table.insert(lines, "  x " .. f)
	end
end

return table.concat(lines, "\n")
