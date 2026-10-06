--!nocheck
--==============================================================================
-- Steal a Seed :: DiscoLightsSpec
--
-- The disco across the whole map (2026-10-03): the palette blends smoothly
-- (never a flash), the stations come from the map's own layout and reach the
-- hub, the field, the road, every permanent biome, the plots and the rain
-- biome, only the nearest few within the budget are lit (fewer on a phone,
-- none under Reduced FX), and the wiring keeps WorldClock the one owner of
-- Lighting with Ticket Shower Only left alone. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("DiscoLightsSpec"))
--
-- Not here, seen in Play instead: the lights on screen, the fades, a late
-- joiner, the rain biome built for real, the end of the event.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage.SeedGame.Shared
local Scripts = StarterPlayer.StarterPlayerScripts
local GameConfig = require(Shared.GameConfig)
local BiomeData = require(Shared.BiomeData)
local DiscoLights = require(Shared.DiscoLights)

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

local MAP = GameConfig.Map
local DISCO = GameConfig.MiniEvent.Disco
local LAYOUT = DISCO.Map

local scratch = Instance.new("Folder")
scratch.Name = "ZZDiscoLightsSpec"
scratch.Archivable = false
scratch.Parent = workspace

local ok, err = pcall(function()
	--==========================================================================
	say("1. The palette: six colours, blended smoothly, never a flash")
	--==========================================================================
	local palette = DISCO.Palette
	check(#palette == 6, "purple, pink, warm gold, green, cyan, blue", #palette)
	local exact = true
	for i, c in ipairs(palette) do
		local got = DiscoLights.colourAt(0, (i - 1) / #palette)
		if math.abs(got.R - c.R) + math.abs(got.G - c.G) + math.abs(got.B - c.B) > 1e-3 then
			exact = false
		end
	end
	check(exact, "each palette colour is reached exactly, in order")
	local worst = 0
	for k = 0, math.floor(DISCO.CycleSeconds * 20) do
		local a = DiscoLights.colourAt(k * 0.05, 0.3)
		local b = DiscoLights.colourAt(k * 0.05 + 0.05, 0.3)
		worst = math.max(worst, math.abs(a.R - b.R), math.abs(a.G - b.G), math.abs(a.B - b.B))
	end
	check(worst < 0.03, string.format("no flash or strobe: at most %.3f of a channel per 50 ms over a whole cycle (%d s)",
		worst, DISCO.CycleSeconds))

	--==========================================================================
	say("2. The stations come from the map and reach all of it")
	--==========================================================================
	local fixed = DiscoLights.fixedStations()
	local by = {}
	for _, s in ipairs(fixed) do
		by[s.source] = by[s.source] or {}
		table.insert(by[s.source], s)
	end
	local hubOk = by.hub and #by.hub == LAYOUT.HubPools
	for _, s in ipairs(by.hub or {}) do
		if Vector3.new(s.at.X, 0, s.at.Z).Magnitude > MAP.HubRadius then
			hubOk = false
		end
	end
	check(hubOk, string.format("the hub: %d pools round the deck, inside its %d-stud radius", LAYOUT.HubPools, MAP.HubRadius))
	local fieldOk = by.field and #by.field == LAYOUT.FieldPools
	for _, s in ipairs(by.field or {}) do
		local a = math.deg(math.atan2(s.at.Z, s.at.X))
		-- The road runs toward -Z (-90 degrees): no field pool within its gap.
		if math.abs(((a + 90 + 180) % 360) - 180) < MAP.RoadGapDegrees / 2 then
			fieldOk = false
		end
	end
	check(fieldOk, string.format("the field: %d pools between the deck and the plots, none in the road's %d-degree gap",
		LAYOUT.FieldPools, MAP.RoadGapDegrees))
	local roadOk = by.road and #by.road >= 1
	for _, s in ipairs(by.road or {}) do
		if s.at.Z > -MAP.HubRadius or s.at.Z < -MAP.FieldFront or math.abs(s.at.X) > MAP.CorridorWidth / 2 then
			roadOk = false
		end
	end
	check(roadOk, string.format("the road: %d pools from the deck to the corridor's mouth", by.road and #by.road or 0))
	for _, biome in ipairs(BiomeData.Biomes) do
		local nearZ, farZ = BiomeData.SegmentBounds(biome)
		local list = by[biome.Id] or {}
		local pools, spots, inside = 0, 0, true
		for _, s in ipairs(list) do
			if s.kind == "spot" then
				spots += 1
			else
				pools += 1
			end
			if s.at.Z > nearZ or s.at.Z < farZ or math.abs(s.at.X) > MAP.CorridorWidth / 2 then
				inside = false
			end
		end
		check(pools == #LAYOUT.PoolsAt and spots == #LAYOUT.SpotsAt and inside,
			string.format("%s: %d pools and %d spots along its segment (z %d..%d), inside the corridor", biome.Id, pools,
				spots, nearZ, farZ))
	end
	local keys, unique = {}, true
	for _, s in ipairs(fixed) do
		if keys[s.key] then
			unique = false
		end
		keys[s.key] = true
	end
	check(unique and #fixed < 60, string.format("%d fixed stations, every one with its own key (not hundreds)", #fixed))

	-- The plots: the real ones on this map if the Edit preview has them, else a stand-in.
	local plots = CollectionService:GetTagged(GameConfig.Tags.Plot)
	local plot = plots[1]
	if not plot then
		plot = Instance.new("Model")
		plot.Name = "Plot_Standin"
		local soil = Instance.new("Part")
		soil.Name = GameConfig.Plot.PlanterName
		soil.Anchored = true
		soil.Size = Vector3.new(30, 0.5, 20)
		soil.CFrame = CFrame.new(120, 0.25, 40)
		soil.Parent = plot
		plot.Parent = scratch
	end
	local ps = DiscoLights.plotStation(plot)
	local soil = plot:FindFirstChild(GameConfig.Plot.PlanterName, true)
	check(ps ~= nil and soil ~= nil and math.abs(ps.at.X - soil.Position.X) < 0.01 and math.abs(ps.at.Z - soil.Position.Z) < 0.01,
		string.format("a plot's pool sits over the middle of its soil (%s, %d plots on this map)", plot.Name, #plots))

	-- The rain biome: a stand-in with its two kinds of floor.
	local rain = Instance.new("Folder")
	rain.Name = "RainStandin"
	local room = Instance.new("Part")
	room.Name = "RoomFloor1"
	room.Shape = Enum.PartType.Cylinder
	room.Size = Vector3.new(6, 60, 60)
	room.CFrame = CFrame.new(400, -3, -200) * CFrame.Angles(0, 0, math.pi / 2)
	room.Anchored = true
	room.Parent = rain
	local corridor = Instance.new("Part")
	corridor.Name = "CorridorFloor1"
	corridor.Size = Vector3.new(40, 6, 210)
	corridor.CFrame = CFrame.lookAt(Vector3.new(400, -3, -340), Vector3.new(420, -3, -500))
	corridor.Anchored = true
	corridor.Parent = rain
	rain.Parent = scratch
	local rs = DiscoLights.rainStations(rain)
	local roomPools, roomSpots, corridorPools, onFloor = 0, 0, 0, true
	for _, s in ipairs(rs) do
		if math.abs(s.at.Y - 0) > 0.01 then
			onFloor = false
		end
		if (Vector3.new(s.at.X, 0, s.at.Z) - Vector3.new(400, 0, -200)).Magnitude < 1 then
			if s.kind == "spot" then
				roomSpots += 1
			else
				roomPools += 1
			end
		else
			corridorPools += 1
			local rel = corridor.CFrame:PointToObjectSpace(Vector3.new(s.at.X, -3, s.at.Z))
			if math.abs(rel.Z) > 105 or math.abs(rel.X) > 20 then
				onFloor = false
			end
		end
	end
	check(roomPools == 1 and roomSpots == 1 and corridorPools == math.floor(210 / LAYOUT.RainSpacing) and onFloor,
		string.format("the rain biome: a pool and a spot on each room, %d pools along a 210-stud corridor, all on the floors' tops",
			corridorPools))

	--==========================================================================
	say("3. Only the nearest few are lit, within the budget")
	--==========================================================================
	local fullP, fullS = DiscoLights.budget("Full")
	local redP, redS = DiscoLights.budget("Reduced")
	local offP, offS = DiscoLights.budget("Off")
	check(fullP + fullS <= 16 and redP + redS < fullP + fullS and offP + offS == 0,
		string.format("budgets: %d+%d lights on Full, %d+%d on a phone, none under Reduced FX", fullP, fullS, redP, redS))
	local all = table.clone(fixed)
	table.insert(all, ps)
	for _, s in ipairs(rs) do
		table.insert(all, s)
	end
	local function lit(focusAt, pools, spots)
		local chosen = DiscoLights.pick(all, focusAt, pools, spots)
		local n, p, sp, far, sources = 0, 0, 0, 0, {}
		for s in pairs(chosen) do
			n += 1
			if s.kind == "spot" then
				sp += 1
			else
				p += 1
			end
			if (Vector3.new(s.at.X, 0, s.at.Z) - Vector3.new(focusAt.X, 0, focusAt.Z)).Magnitude > LAYOUT.ActivationRadius then
				far += 1
			end
			sources[s.source] = (sources[s.source] or 0) + 1
		end
		return n, p, sp, far, sources
	end
	local places = {
		{ "the hub", Vector3.new(0, 0, 0), "hub" },
		{ "a plot", ps.at, "plot" },
	}
	for _, biome in ipairs(BiomeData.Biomes) do
		local nearZ, farZ = BiomeData.SegmentBounds(biome)
		table.insert(places, { biome.Id, Vector3.new(0, 0, (nearZ + farZ) / 2), biome.Id })
	end
	table.insert(places, { "the rain biome (stand-in)", Vector3.new(400, 0, -260), "rain" })
	for _, place in ipairs(places) do
		local n, p, sp, far, sources = lit(place[2], fullP, fullS)
		local np, nsp = 0, 0
		do
			local _, rp, rsp = lit(place[2], redP, redS)
			np, nsp = rp, rsp
		end
		check(n > 0 and p <= fullP and sp <= fullS and far == 0 and (sources[place[3]] or 0) > 0 and np <= redP and nsp <= redS,
			string.format("%s: %d lit (%d pools, %d spots) incl. its own, none beyond %d studs; a phone %d+%d", place[1], n,
				p, sp, LAYOUT.ActivationRadius, np, nsp))
	end
	local nowhere = DiscoLights.pick(all, Vector3.new(5000, 0, 5000), fullP, fullS)
	check(next(nowhere) == nil, "far from every station: nothing is lit")

	--==========================================================================
	say("4. Wired through the existing owners")
	--==========================================================================
	local clockSrc = sourceOf(Scripts, "WorldClock")
	local _, brightness = string.gsub(clockSrc, "Lighting.Brightness = ", "")
	check(brightness == 1 and string.find(clockSrc, "discoColour = DiscoLights.colourAt(t, 0)", 1, true) ~= nil
			and string.find(clockSrc, ":Lerp(discoAmbient, discoMix)", 1, true) ~= nil
			and string.find(clockSrc, "return if mode and mode.Disco then 1 else 0", 1, true) ~= nil,
		"WorldClock alone writes Lighting: the palette's tint and ambient over day/night/rain, only for disco modes")
	local fxSrc = sourceOf(Scripts, "MiniEventFX")
	check(string.find(fxSrc, 'GetService("Lighting")', 1, true) == nil
			and string.find(fxSrc, "local on = eventRunning() and mode.Disco and quality() ~= \"Off\"", 1, true) ~= nil
			and string.find(fxSrc, "light.Shadows = false", 1, true) ~= nil
			and string.find(fxSrc, "local function destroyMap(ml: MapLights)", 1, true) ~= nil
			and string.find(fxSrc, "ml.folder:Destroy()", 1, true) ~= nil
			and string.find(fxSrc, "made.level = if want == 1 then joinLevel() else 0", 1, true) ~= nil
			and string.find(fxSrc, "d.level = if want == 1 then joinLevel() else 0", 1, true) ~= nil,
		"MiniEventFX: map lights only for disco modes and not under Reduced FX, shadows off, torn down at the end, late joiners at full")
	check(string.find(fxSrc, "if m.calm", 1, true) ~= nil and string.find(fxSrc, "if kind == \"spot\" and not calm then", 1, true) ~= nil,
		"reduced motion: the spots stand still and draw no shafts, the colours hold")
end)

scratch:Destroy()
if not ok then
	check(false, "the spec threw", err)
end
table.insert(out, string.format("\nDiscoLightsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
