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
--
-- One exception, section 8: the admin console's forced night and day. WHEN the
-- loop wakes after one, and how many times the nests are restocked, is that
-- file's logic alone, so it is run through WorldCycleService's real source with
-- stand-ins for the world, on a day of a second or so.
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
-- 60 until 2026-09-23, when the owner cut it to 15.
ok("the night is 15 seconds", CYCLE.NightSeconds == 15, tostring(CYCLE.NightSeconds))
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
	--==========================================================================
	-- AT LEAST ONE, NOT EXACTLY ONE
	--
	-- This asserted `#live == 1`, which was true and worth guarding while
	-- Greenhollow was the only biome with art. Four have shipped since --
	-- Dustbowl, Tanglemire, Emberroot and Starbloom each went live in their own
	-- commit -- so the check had been failing on the game working as intended.
	--
	-- What still matters is above: every live biome must have species to roll,
	-- or its nests produce nothing at dawn with no error to explain it. That
	-- guard is per-biome and unaffected. This one only has to catch the case
	-- where NOTHING is live, which is a game with no pods in it at all.
	--==========================================================================
	ok("at least one biome is live", #live >= 1, table.concat(live, ", "))
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
-- 7. A FIFTEEN-SECOND NIGHT STILL DOES ALL OF ITS WORK
--
-- The night was cut from 60 s to 15 on 2026-09-23. What has to stay true is
-- that nothing a night does waits on how long it is: every step happens at an
-- edge, in an order that closes a race, and every fade finishes well inside it.
-- The order is read from WorldCycleService's own source, because it is the
-- whole correctness argument and a reordering would pass every other check.
--==============================================================================
section("a fifteen-second night")
do
	local N = CYCLE.Night
	local MUSIC = GameConfig.Music :: any
	ok("the sky's fade is under a quarter of the night", N.FadeSeconds < CYCLE.NightSeconds * 0.25,
		string.format("%.1fs of %ds", N.FadeSeconds, CYCLE.NightSeconds))
	ok("so is the music's crossfade",
		(tonumber(MUSIC.PhaseFadeSeconds) or 3) < CYCLE.NightSeconds * 0.25,
		tostring(MUSIC.PhaseFadeSeconds))
	ok("the wall's last-seconds colour starts inside the night",
		CYCLE.Barrier.Screen.SoonSeconds < CYCLE.NightSeconds,
		tostring(CYCLE.Barrier.Screen.SoonSeconds))
	ok("the road poll runs many times a night",
		GameConfig.Gate.PollSeconds * 20 <= CYCLE.NightSeconds, tostring(GameConfig.Gate.PollSeconds))

	local Server = game:GetService("ServerScriptService"):WaitForChild("SeedGameServer")
	local source = (Server:WaitForChild("WorldCycleService") :: ModuleScript).Source
	local function order(body: string, steps: { string }): boolean
		local at = 0
		for _, step in ipairs(steps) do
			local found = string.find(body, step, at + 1, true)
			if not found then
				return false
			end
			at = found
		end
		return true
	end
	local dusk = string.match(source, "local function toNight%(%)(.-)\nend") or ""
	local dawn = string.match(source, "local function toDay%(%)(.-)\nend") or ""
	ok("dusk: the phase, then the wall, then the people, then the world",
		order(dusk, { "publish(CYCLE.PhaseNight", "SetNightBarrier(true)", "ejectEveryone()",
			"ClearForNight()", "clearLoosePods()", "ResetParents()" }))
	ok("dawn: the batch is built while it is still night, then Day, then the wall opens",
		order(dawn, { "StockAll()", "publish(CYCLE.PhaseDay", "SetNightBarrier(false)" }))
	ok("the deadline is published with the phase, in one frame",
		order(source, { "Workspace:SetAttribute(ATTR.WorldPhaseEndsAt",
			"Workspace:SetAttribute(ATTR.WorldPhase," }))
	ok("the loop sleeps out the phase in one wait and never counts on the server",
		string.find(source, "task.wait(left)", 1, true) ~= nil
			and not string.find(source, "Heartbeat:Connect", 1, true)
			and not string.find(source, "RenderStepped", 1, true))

	local scripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")
	local clock = (scripts:WaitForChild("WorldClock") :: LocalScript).Source
	ok("the HUD clock holds a phase whose deadline has not arrived yet, and the reverse",
		string.find(clock, "if not settled(phase, endsAt, now) then", 1, true) ~= nil
			and string.find(clock, "(phase ~= lastPhase) ~= (endsAt ~= lastEndsAt)", 1, true) ~= nil)
	ok("and a joiner at night is lit for night on their first frame",
		string.find(clock, "applyLight(if Workspace:GetAttribute(ATTR.WorldPhase) == CYCLE.PhaseNight then 1 else 0)",
			1, true) ~= nil)
	table.insert(lines, string.format("  %ds night: %.1fs sky fade, %.1fs music crossfade, the wall turns amber at %ds",
		CYCLE.NightSeconds, N.FadeSeconds, tonumber(MUSIC.PhaseFadeSeconds) or 3,
		CYCLE.Barrier.Screen.SoonSeconds))
end

--==============================================================================
-- 8. A FORCED NIGHT OR DAY IS THE NORMAL ONE, AND THE CYCLE CARRIES ON
--
-- The admin console's Start Night and Start Day, through WorldCycleService's
-- REAL source, loaded here with a thawed copy of the config whose day and night
-- last a second or so, and with stand-ins for what a transition does to the
-- world that write down what they were asked: the nests (clear, parents,
-- restock), the barrier and the road's sweep. Under test is what only that file
-- owns -- which transition runs, how often, in what order, and when the loop
-- wakes next. Nothing in the place is touched: the loose-pod sweep is pointed
-- at a tag only this section's own part carries, and the three phase
-- attributes it writes on the Workspace are put back as they were.
--==============================================================================
section("a forced night or day")
do
	local CollectionService = game:GetService("CollectionService")
	local ServerStorage = game:GetService("ServerStorage")
	local Workspace = game:GetService("Workspace")
	local ATTR = GameConfig.Attributes
	local configScript = Shared:WaitForChild("GameConfig")
	local moduleScript = game:GetService("ServerScriptService"):WaitForChild("SeedGameServer")
		:WaitForChild("WorldCycleService") :: ModuleScript

	local function thaw(value: any): any
		if type(value) ~= "table" then
			return value
		end
		local copy = {}
		for k, v in pairs(value) do
			copy[k] = thaw(v)
		end
		return copy
	end
	local config = thaw(GameConfig)
	local LOOSE_TAG = "CycleSpecLoosePod"
	config.Tags.SeedPod = LOOSE_TAG
	local C = config.WorldCycle

	local trail: { { what: string, at: number } } = {}
	local slowStock, brokenStock = false, false
	local function mark(what: string)
		table.insert(trail, { what = what, at = os.clock() })
	end
	local function count(what: string): number
		local n = 0
		for _, entry in ipairs(trail) do
			if entry.what == what then
				n += 1
			end
		end
		return n
	end
	local function inOrder(steps: { string }): boolean
		local at = 0
		for _, step in ipairs(steps) do
			local found: number? = nil
			for i = at + 1, #trail do
				if trail[i].what == step then
					found = i
					break
				end
			end
			if not found then
				return false
			end
			at = found
		end
		return true
	end

	local standIns: { [string]: any } = {
		MapService = {
			SetNightBarrier = function(closed: boolean)
				mark(if closed then "Shut" else "Open")
			end,
			GetNightBarrier = function()
				return nil
			end,
		},
		NestService = {
			ClearForNight = function()
				mark("Clear")
				return 5
			end,
			ResetParents = function()
				mark("Parents")
				return 1
			end,
			StockAll = function()
				if brokenStock then
					error("CycleSpec: a restock that throws")
				end
				mark("Stock")
				if slowStock then
					-- A restock that takes a moment: the window a second press lands in.
					task.wait(0.3)
				end
				return 5, 5
			end,
			PodCount = function()
				return 5, 5
			end,
			NestCount = function()
				return 1
			end,
		},
		CarryService = {
			IsCarrying = function()
				return false
			end,
			-- A running Rain event's pod (2026-10-02): dusk leaves it to the event.
			IsLiveEventPod = function(pod: Instance)
				return pod:GetAttribute("EventId") ~= nil
			end,
		},
		BiomeGateService = {
			OrderAt = function()
				return 0
			end,
			SweepNow = function()
				mark("Sweep")
				return 0
			end,
		},
	}
	local function standInRequire(target: Instance): any
		if target == configScript then
			return config
		end
		local standIn = standIns[target.Name]
		assert(standIn ~= nil, "WorldCycleService asked for " .. target:GetFullName() .. ", which has no stand-in")
		return standIn
	end
	local chunk, loadErr = loadstring(moduleScript.Source, "=WorldCycleService")
	assert(chunk, tostring(loadErr))
	setfenv(chunk, setmetatable({ script = moduleScript, require = standInRequire }, { __index = getfenv(1) }))
	local W: any = chunk()

	local names = { ATTR.WorldPhase, ATTR.WorldPhaseEndsAt, ATTR.WorldCycleIndex }
	local before: { any } = {}
	for i, name in ipairs(names) do
		before[i] = Workspace:GetAttribute(name)
	end
	local fixture = Instance.new("Folder")
	fixture.Name = "CycleSpecFixture"
	fixture.Archivable = false
	fixture.Parent = ServerStorage

	local ran, err = pcall(function()
		--== the phase already running: nothing ==--
		C.DaySeconds, C.NightSeconds = 4, 0.8
		W.Init()
		W.Start()
		table.clear(trail)
		local startIndex = W.CycleIndex()
		local done, why = W.StartDay()
		ok("Start Day by day changes nothing: ALREADY_DAY, no restock",
			done == false and why == "ALREADY_DAY" and #trail == 0 and W.IsDay(), tostring(why))

		--== a forced night is the normal night ==--
		local pod = Instance.new("Part")
		pod.Name = "LoosePod"
		pod.Parent = fixture
		CollectionService:AddTag(pod, LOOSE_TAG)
		local eventPod = Instance.new("Part")
		eventPod.Name = "EventPod"
		eventPod:SetAttribute("EventId", 1)
		eventPod.Parent = fixture
		CollectionService:AddTag(eventPod, LOOSE_TAG)
		local forcedAt = os.clock()
		done, why = W.StartNight()
		ok("Start Night by day starts the night",
			done == true and why == "OK" and Workspace:GetAttribute(ATTR.WorldPhase) == C.PhaseNight, tostring(why))
		ok("the normal dusk, in its order: the wall, the road, the nests, the parents",
			#trail == 4 and inOrder({ "Shut", "Sweep", "Clear", "Parents" }))
		ok("and the pods lying loose are gone", pod.Parent == nil)
		ok("but a running Rain event's pod is the event's, and stays", eventPod.Parent == fixture)
		eventPod:Destroy()
		local left = W.SecondsLeft()
		ok("the night's deadline is the configured night, not what was left of the day",
			left > C.NightSeconds - 0.25 and left <= C.NightSeconds, string.format("%.2fs", left))
		done, why = W.StartNight()
		ok("Start Night by night changes nothing: ALREADY_NIGHT",
			done == false and why == "ALREADY_NIGHT" and count("Clear") == 1, tostring(why))

		--== and the cycle carries on from it ==--
		-- Expected: dawn at 0.8 s, dusk at 2.3, dawn at 3.1, the next dusk at 4.6.
		-- The loop left asleep on the OLD 4-second day wakes at 4.0 and must go.
		C.DaySeconds = 1.5
		task.wait(4.3)
		local edges: { { what: string, at: number } } = {}
		local shown: { string } = {}
		for _, entry in ipairs(trail) do
			if entry.what == "Clear" or entry.what == "Stock" then
				table.insert(edges, { what = entry.what, at = entry.at - forcedAt })
				table.insert(shown, string.format("%s@%.2f", entry.what, entry.at - forcedAt))
			end
		end
		local seen = table.concat(shown, " ")
		local function gap(i: number): number
			return if edges[i] and edges[i - 1] then edges[i].at - edges[i - 1].at else -1
		end
		ok("the forced night ended by itself after its own 0.8 s -- the old day still had 4 s",
			edges[2] ~= nil and edges[2].what == "Stock" and gap(2) >= 0.7 and gap(2) < 1.4, seen)
		ok("then the cycle carried on at the configured lengths: a 1.5 s day, a 0.8 s night",
			edges[3] ~= nil and edges[3].what == "Clear" and gap(3) >= 1.4 and gap(3) < 2.1
				and edges[4] ~= nil and edges[4].what == "Stock" and gap(4) >= 0.7 and gap(4) < 1.4, seen)
		ok("and the loop asleep on the old day's deadline woke at 4 s and did nothing", #edges == 4, seen)
		ok("exactly one restock per new day",
			count("Stock") == 2 and W.CycleIndex() == startIndex + 2,
			string.format("%d restock(s), %d dawn(s)", count("Stock"), W.CycleIndex() - startIndex))

		--== a forced dawn restocks once, and a second press does not ==--
		C.DaySeconds, C.NightSeconds = 30, 30
		W.Init()
		W.Start()
		W.StartNight()
		table.clear(trail)
		local nightIndex = W.CycleIndex()
		slowStock = true
		local first: any = nil
		task.spawn(function()
			first = table.pack(W.StartDay())
		end)
		-- That press is inside its restock now, waiting there on purpose.
		local again, whyAgain = W.StartDay()
		local dusk, whyDusk = W.StartNight()
		ok("a second press while the dawn is still restocking is refused as BUSY -- either button",
			again == false and whyAgain == "BUSY" and dusk == false and whyDusk == "BUSY",
			tostring(whyAgain) .. " / " .. tostring(whyDusk))
		task.wait(0.6)
		slowStock = false
		ok("the first press made the day, restocked: 5 of 5",
			first ~= nil and first[1] == true and first[2] == "OK" and first[3] == 5 and first[4] == 5 and W.IsDay(),
			first and tostring(first[2]))
		ok("one restock, then Day, then the wall opens",
			count("Stock") == 1 and W.CycleIndex() == nightIndex + 1 and inOrder({ "Stock", "Open" }),
			string.format("%d restock(s)", count("Stock")))
		done, why = W.StartDay()
		ok("pressed again by day, it restocks nothing: ALREADY_DAY",
			done == false and why == "ALREADY_DAY" and count("Stock") == 1, tostring(why))
		left = W.SecondsLeft()
		ok("and the forced day is a whole configured day", left > C.DaySeconds - 1 and left <= C.DaySeconds,
			string.format("%.1fs", left))

		--== a dawn that throws: said so, and the cycle still turns ==--
		C.DaySeconds, C.NightSeconds = 30, 0.6
		W.Init()
		W.Start()
		W.StartNight()
		table.clear(trail)
		brokenStock = true
		done, why = W.StartDay()
		brokenStock = false
		left = W.SecondsLeft()
		ok("a dawn that throws is reported FAILED, never OK", done == false and why == "FAILED", tostring(why))
		ok("and the night it left behind still has a deadline", not W.IsDay() and left > 0.35 and left <= 0.6,
			string.format("%.2fs", left))
		task.wait(1)
		ok("which the restarted loop keeps: the next dawn came by itself",
			W.IsDay() and count("Stock") == 1, string.format("%d restock(s)", count("Stock")))
	end)

	-- Every loop this started wakes, finds it is not the newest, and goes.
	W.Init()
	for i, name in ipairs(names) do
		Workspace:SetAttribute(name, before[i])
	end
	fixture:Destroy()
	if not ran then
		ok("the forced-change tests ran to the end", false, tostring(err))
	end
	table.insert(lines, "  forced changes, on a 0.8 s night and a 1.5 s day here (the game's are "
		.. CYCLE.NightSeconds .. " s and " .. CYCLE.DaySeconds .. " s)")
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
