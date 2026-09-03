--!nocheck
-- Steal a Seed :: the five-level plot ladder, and the v1 -> v2 save migration
--
--   python -m http.server 8731        (repo root)
--   local run = loadstring(game:GetService("HttpService"):GetAsync(
--       "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--   print(run("PlotSpec"))
--
-- Edit mode is enough. Nothing here needs a live server: the ladder is a table
-- and the migration is a pure function of a raw table.
--
-- What is NOT covered here, and is checked in a playtest instead: the upgrade
-- transaction itself (it destroys and rebuilds real Instances), the Shop's
-- click path, and whether a rebuilt plot's gate still lines up in world space.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local ProfileSchema = require(
	ServerScriptService:WaitForChild("SeedGameServer"):WaitForChild("ProfileSchema"))

local out = {}
local pass, fail = 0, 0

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label,
			if detail then "  <- " .. tostring(detail) else ""))
	end
end

local function near(a, b, eps)
	return math.abs(a - b) <= (eps or 1e-4)
end

-- Any real species. The migration must not care which.
local SPECIES = next(SeedData.ById)

--==============================================================================
-- 1. THE LADDER
--==============================================================================
say("\n-- ladder --")

local T = GameConfig.PlotTiers
check(#T == 5, "five levels", #T)

local wantCap = { 5, 7, 10, 15, 20 }
local wantCost = { 0, 25000, 250000, 2500000, 25000000 }
local capOk, costOk = true, true
for i = 1, 5 do
	if not T[i] or T[i].capacity ~= wantCap[i] then capOk = false end
	if not T[i] or T[i].cost ~= wantCost[i] then costOk = false end
end
check(capOk, "capacities 5 / 7 / 10 / 15 / 20")
check(costOk, "costs 0 / 25k / 250k / 2.5M / 25M")

local depths = {}
local rising = true
for i = 1, #T do
	depths[i] = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(i))
	if i > 1 and depths[i] <= depths[i - 1] then rising = false end
end
check(rising, "depth strictly increases with level",
	table.concat(depths, " "))

-- Every level must fit between the ring and the back of the field, or the
-- biggest plot silently overlaps whatever is behind it.
local reach = GameConfig.Map.PlotRingInner + depths[#depths]
check(reach < GameConfig.Map.FieldBack,
	"level 5 fits the field",
	string.format("reach %.1f vs back %d", reach, GameConfig.Map.FieldBack))

--==============================================================================
-- 2. CAPACITY LOOKUPS
--==============================================================================
say("\n-- capacity --")

check(GameConfig.plotCapacityForTier(1) == 5, "level 1 holds 5")
check(GameConfig.plotCapacityForTier(5) == 20, "level 5 holds 20")
check(GameConfig.plotCapacityForTier(nil) == 5, "nil level falls back to start")
check(GameConfig.plotCapacityForTier(0 / 0) == 5, "NaN level falls back to start")
check(GameConfig.plotCapacityForTier(99) == 20, "over-max level clamps to 5")
check(GameConfig.plotCapacityForTier(-3) == 5, "under-min level clamps to 1")

local lvlWant = { [0] = 1, [5] = 1, [6] = 2, [7] = 2, [8] = 3, [12] = 4,
	[15] = 4, [16] = 5, [20] = 5, [23] = 5, [500] = 5 }
local lvlOk, lvlBad = true, ""
for n, want in pairs(lvlWant) do
	local got = GameConfig.plotLevelForPlants(n)
	if got ~= want then
		lvlOk = false
		lvlBad ..= string.format(" %d->%d(want %d)", n, got, want)
	end
end
check(lvlOk, "smallest level that holds N plants", lvlBad)

--==============================================================================
-- 3. THE MIGRATION
--
-- A v1 profile is built by hand, run through Sanitise, and checked on the two
-- things that actually matter: every plant survived, and no plant moved.
--==============================================================================
say("\n-- migration v1 -> v2 --")

-- Build a v1 raw profile: `tier` is the OLD PlotTier, `zs` are OLD local Z.
local function v1(tier, zs)
	local plants = {}
	for i, z in ipairs(zs) do
		plants[i] = {
			SpeciesId = SPECIES, Tier = 1, PlantedAt = 1000 + i,
			X = 0, Z = z, Stage = 3, Facing = 0,
		}
	end
	return { Version = 1, Cash = 0, PlotTier = tier, Plants = plants }
end

local function oldDepthOf(tier)
	return GameConfig.plotDepthFor(GameConfig.LegacyPlotRowsV1[tier])
end

-- 3a. Nothing is ever discarded, at any size.
do
	local sizes = { 1, 5, 6, 12, 15, 20, 25, 40 }
	local kept, bad = true, ""
	for _, n in ipairs(sizes) do
		local zs = {}
		for i = 1, n do zs[i] = 0 end
		local p = ProfileSchema.Sanitise(v1(1, zs))
		if #p.Plants ~= n then
			kept = false
			bad ..= string.format(" %d->%d", n, #p.Plants)
		end
	end
	check(kept, "no valid plant is ever discarded", bad)
end

-- 3b. The level rises to hold the garden.
do
	local cases = { [3] = 1, [5] = 1, [6] = 2, [12] = 4, [20] = 5, [30] = 5 }
	local ok, bad = true, ""
	for n, want in pairs(cases) do
		local zs = {}
		for i = 1, n do zs[i] = 0 end
		local p = ProfileSchema.Sanitise(v1(1, zs))
		if p.PlotTier < want then
			ok = false
			bad ..= string.format(" %d plants -> L%d (want >= L%d)", n, p.PlotTier, want)
		end
	end
	check(ok, "level rises to hold the garden", bad)
end

-- 3c. Over twenty plants: level 5, over capacity, still all there.
do
	local zs = {}
	for i = 1, 25 do zs[i] = 0 end
	local p = ProfileSchema.Sanitise(v1(1, zs))
	check(p.PlotTier == 5 and #p.Plants == 25,
		"25 plants -> level 5, all 25 kept",
		string.format("L%d, %d plants", p.PlotTier, #p.Plants))
	check(#p.Plants > GameConfig.plotCapacityForTier(p.PlotTier),
		"over capacity is allowed to persist")
end

-- 3d. THE PLANTS DO NOT MOVE -- as far as the new ladder can reach.
--
-- Local -Z faces the gate, so distance from the gate is `z + depth/2`: how far
-- up the bed the plant sits, independent of which ladder built the plot. Every
-- plant the new bed can reach must keep that number exactly.
--
-- It cannot reach all of them. v2's deepest level is 96.2 studs against v1's
-- 132.8, so a plant more than `far` from the gate has nowhere to stand and is
-- clamped to the back of the bed instead. That is asserted below rather than
-- glossed over -- it is a real thing a deep old garden will see.
do
	local worst, bad = 0, ""
	local clamped, inside = 0, 0
	for tier = 1, 4 do
		local od = oldDepthOf(tier)
		local half = od * 0.5
		local zs = { -half + 1, -half * 0.5, 0, half * 0.5, half - 1 }
		local p = ProfileSchema.Sanitise(v1(tier, zs))
		local rows = GameConfig.plotRowsForTier(p.PlotTier)
		local nearR, farR = GameConfig.plotGateReach(rows)
		local nd = GameConfig.plotDepthFor(rows)
		for i, oldZ in ipairs(zs) do
			local wantDist = math.clamp(oldZ + od * 0.5, nearR, farR)
			local gotDist = p.Plants[i].Z + nd * 0.5
			local err = math.abs(gotDist - wantDist)
			if err > worst then worst = err end
			if err > 1e-3 then
				bad ..= string.format(" T%d[%d] %.2f vs %.2f", tier, i, gotDist, wantDist)
			end
			if oldZ + od * 0.5 > farR then clamped += 1 else inside += 1 end
		end
	end
	check(worst <= 1e-3,
		"every reachable plant keeps its exact distance from the gate",
		string.format("worst %.4f%s", worst, bad))
	check(inside > 0 and clamped > 0,
		"the sample covers both reachable and out-of-reach plants",
		string.format("%d inside, %d clamped", inside, clamped))
end

-- 3e. Every migrated plant lands somewhere a plant may legally stand -- inside
-- the soil, EdgeMargin clear of the rim. If this fails, PlantService would move
-- it again on restore and the save would not be settled.
do
	local ok, bad = true, ""
	for tier = 1, 4 do
		local od = oldDepthOf(tier)
		local half = od * 0.5
		local zs = { -half + 1, -half * 0.5, 0, half * 0.5, half - 1, half + 40 }
		local p = ProfileSchema.Sanitise(v1(tier, zs))
		local rows = GameConfig.plotRowsForTier(p.PlotTier)
		local nearR, farR = GameConfig.plotGateReach(rows)
		local nd = GameConfig.plotDepthFor(rows)
		for i, plant in ipairs(p.Plants) do
			local d = plant.Z + nd * 0.5
			if d < nearR - 1e-3 or d > farR + 1e-3 then
				ok = false
				bad ..= string.format(" T%d[%d] d=%.2f not in [%.2f, %.2f]",
					tier, i, d, nearR, farR)
			end
		end
	end
	check(ok, "every migrated plant lands on plantable soil", bad)
end

-- 3f. The level still rises to reach a deep garden wherever the ladder allows
-- it. An old tier-1 bed (59.6) fits inside several v2 levels, so a plant at its
-- back must NOT be clamped -- the level must grow instead.
do
	local od = oldDepthOf(1)
	local p = ProfileSchema.Sanitise(v1(1, { od * 0.5 - 1 }))
	local rows = GameConfig.plotRowsForTier(p.PlotTier)
	local _, farR = GameConfig.plotGateReach(rows)
	check(farR >= od - 1,
		"the level grows to reach a deep garden when the ladder can",
		string.format("L%d reach %.1f vs needed %.1f", p.PlotTier, farR, od - 1))
end

-- 3g. Exactly once. Sanitise is called on every load; converting twice would
-- walk the garden toward the gate a little further each session.
do
	local zs = { -10, 0, 10 }
	local a = ProfileSchema.Sanitise(v1(1, zs))
	check(a.Version == 2, "version is stamped 2", a.Version)

	-- Feed the migrated profile back in, the way the next login would.
	local raw = { Version = a.Version, Cash = a.Cash, PlotTier = a.PlotTier, Plants = {} }
	for i, pl in ipairs(a.Plants) do
		raw.Plants[i] = { SpeciesId = pl.SpeciesId, Tier = pl.Tier,
			PlantedAt = pl.PlantedAt, X = pl.X, Z = pl.Z, Stage = pl.Stage,
			Facing = pl.Facing }
	end
	local b = ProfileSchema.Sanitise(raw)

	local same = b.PlotTier == a.PlotTier and #b.Plants == #a.Plants
	for i = 1, #a.Plants do
		if not near(b.Plants[i].Z, a.Plants[i].Z) then same = false end
	end
	check(same, "re-running the migration changes nothing")
end

-- 3h. A brand new profile is born at version 2 and never migrates.
do
	local d = ProfileSchema.Default()
	check(d.Version == GameConfig.Save.CurrentVersion,
		"a fresh profile carries the current version",
		string.format("%s vs %s", tostring(d.Version),
			tostring(GameConfig.Save.CurrentVersion)))
	check(GameConfig.Save.CurrentVersion == 2, "save version is 2",
		GameConfig.Save.CurrentVersion)
end

-- 3i. Junk in a v1 save still migrates rather than throwing.
do
	local ok, err = pcall(function()
		return ProfileSchema.Sanitise({
			Version = 1, PlotTier = "banana",
			Plants = { { SpeciesId = "no_such_species", Z = 5 }, "not a table",
				{ SpeciesId = SPECIES, Tier = 1, PlantedAt = 1, X = 0, Z = 0, Stage = 3 } },
		})
	end)
	check(ok, "a corrupt v1 profile migrates without throwing", err)
end

--==============================================================================
-- 4. THE GATE STAYS PUT
--
-- The geometric contract of an upgrade. A plot is placed by its CENTRE and its
-- depth is measured from the gate backwards, so growing it at a fixed centre
-- would drive the gate into the hub ring and swallow the walkway. It has to
-- grow the other way -- away from the hub, into the empty field behind.
--
-- This is the arithmetic MapService.ResizePlot runs, checked against every
-- ordered pair of levels. Whether the parts land where the arithmetic says is a
-- playtest question; whether the arithmetic is right is this one.
--==============================================================================
say("\n-- resize geometry --")

do
	local worstGate, worstBack = 0, 0
	local grew = true
	for from = 1, #T do
		for to = 1, #T do
			local oldDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(from))
			local newDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(to))

			-- A plot on the ring, facing the hub: local -Z at the gate.
			local centreR = GameConfig.Map.PlotRingInner + oldDepth * 0.5
			local oldCF = CFrame.lookAt(
				Vector3.new(0, 0, centreR), Vector3.new(0, 0, 0))

			local gateCF = oldCF * CFrame.new(0, 0, -oldDepth * 0.5)
			local newCF = gateCF * CFrame.new(0, 0, newDepth * 0.5)
			local newGate = newCF * CFrame.new(0, 0, -newDepth * 0.5)

			local moved = (newGate.Position - gateCF.Position).Magnitude
			if moved > worstGate then worstGate = moved end

			-- And the back edge must move outward exactly the depth difference.
			local oldBack = (oldCF * CFrame.new(0, 0, oldDepth * 0.5)).Position
			local newBack = (newCF * CFrame.new(0, 0, newDepth * 0.5)).Position
			local grewBy = (newBack - oldBack).Magnitude
			local wantGrew = math.abs(newDepth - oldDepth)
			if math.abs(grewBy - wantGrew) > worstBack then
				worstBack = math.abs(grewBy - wantGrew)
			end

			if to > from and newDepth <= oldDepth then grew = false end
		end
	end
	check(worstGate <= 1e-3, "the gate never moves, at any level pair",
		string.format("worst %.5f", worstGate))
	check(worstBack <= 1e-3, "the back edge moves by exactly the depth change",
		string.format("worst %.5f", worstBack))
	check(grew, "a higher level is always a deeper plot")
end

-- Reach has to grow with the level too, or an upgrade could strand a plant
-- that was legal a moment ago.
do
	local rising = true
	local prev = -1
	local report = {}
	for i = 1, #T do
		local nearR, farR = GameConfig.plotGateReach(GameConfig.plotRowsForTier(i))
		if farR <= prev then rising = false end
		prev = farR
		table.insert(report, string.format("L%d %.1f-%.1f", i, nearR, farR))
	end
	check(rising, "plantable reach grows with the level",
		table.concat(report, "  "))
end

-- The near edge is the same at every level: the bed always starts the same
-- distance behind the gate, so an upgrade never strands the FRONT row either.
do
	local first = GameConfig.plotGateReach(GameConfig.plotRowsForTier(1))
	local same = true
	for i = 2, #T do
		local nearR = GameConfig.plotGateReach(GameConfig.plotRowsForTier(i))
		if not near(nearR, first) then same = false end
	end
	check(same, "the front of the bed is the same distance from the gate at every level",
		string.format("%.2f", first))
end

--==============================================================================
-- 5. THE PRICE OF THE LADDER
--==============================================================================
say("\n-- pricing --")

do
	local rising = true
	for i = 2, #T do
		if T[i].cost <= T[i - 1].cost then rising = false end
	end
	check(rising, "every rung costs more than the one below it")
	check(T[1].cost == 0, "the level everyone starts on is free", T[1].cost)
end

do
	-- Buying rung by rung must cost the same as the sum of the rungs -- there is
	-- no bulk purchase and no way to skip one, so the ladder's total IS the sum.
	local total = 0
	for i = 2, #T do
		total += T[i].cost
	end
	check(total == 27775000, "the whole ladder costs 27,775,000", total)
end

--==============================================================================
-- 6. THE HANDOVER, AS GEOMETRY
--
-- A plot changing hands is three resizes in a row: the old owner's level, down
-- to Level 1 on release, and up to the new owner's level on assignment. This
-- drives the REAL MapService.ResizePlot through that sequence on a real Model
-- and checks what has to survive it.
--
-- WHAT THIS CANNOT COVER: `drainQueue` picking the first waiting player, and
-- two queued players not receiving the same plot. Both need real Player
-- instances, which cannot be constructed -- `Instance.new("Player")` is
-- blocked. Those two are verified by reading PlotService, and the reasoning is
-- in the report rather than asserted here.
--==============================================================================
say("\n-- handover --")

do
	local MapService = require(
		ServerScriptService:WaitForChild("SeedGameServer"):WaitForChild("MapService"))
	local PLOT = GameConfig.Plot

	-- A plot standing on the ring, facing the hub, exactly as MapService places
	-- one. Built by asking ResizePlot to dress an empty Model.
	local plot = Instance.new("Model")
	plot.Name = "SpecPlot"
	plot.Archivable = false
	plot:SetAttribute("PreviewOnly", true)
	plot:SetAttribute(GameConfig.Attributes.PlotId, 99)
	plot.Parent = workspace

	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(4))
	local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
	plot:SetAttribute("PlotCF",
		CFrame.lookAt(Vector3.new(0, 500, centreR), Vector3.new(0, 500, 0)))
	plot:SetAttribute("Depth", startDepth)

	local ok, err = pcall(function()
		--== the previous owner, at Level 4 ==--
		MapService.ResizePlot(plot, 4)

		local function gate()
			local cf = plot:GetAttribute("PlotCF")
			return (cf * CFrame.new(0, 0, -plot:GetAttribute("Depth") * 0.5)).Position
		end
		local startGate = gate()

		local plants = plot:FindFirstChild(PLOT.PlantsFolderName)
		local runtime = plot:FindFirstChild(PLOT.RuntimeFolderName)
		check(plants ~= nil and runtime ~= nil, "a dressed plot has both folders")

		-- Ownership marks and a garden, as a live plot would carry.
		plot:SetAttribute(GameConfig.Attributes.OwnerUserId, 1111)
		plot:SetAttribute(GameConfig.Attributes.OwnerName, "OldOwner")
		plot:SetAttribute(GameConfig.Attributes.Claimed, true)
		for i = 1, 3 do
			local m = Instance.new("Model")
			m.Name = "FakePlant" .. i
			m.Parent = plants
		end
		local leftover = Instance.new("Folder")
		leftover.Name = "FakeRuntimeThing"
		leftover.Parent = runtime

		check(plot:GetAttribute("Level") == 4
			and plot:GetAttribute("Capacity") == 15
			and plot:GetAttribute("Rows") == 5,
			"the outgoing owner's plot is L4 / 15 / 5 rows")

		--== RELEASE: the folders are emptied, then it drops to Level 1 ==--
		-- Exactly PlotService's order: clearPlot first, resize second.
		plants:ClearAllChildren()
		runtime:ClearAllChildren()
		plot:SetAttribute(GameConfig.Attributes.OwnerUserId, 0)
		plot:SetAttribute(GameConfig.Attributes.OwnerName, "")
		plot:SetAttribute(GameConfig.Attributes.Claimed, false)
		MapService.ResizePlot(plot, GameConfig.StartingPlotTier)

		check((gate() - startGate).Magnitude <= 1e-3,
			"the gate does not move on release",
			string.format("%.6f", (gate() - startGate).Magnitude))
		check(plot:GetAttribute("Level") == 1 and plot:GetAttribute("Capacity") == 5,
			"an idle release returns the plot to Level 1",
			string.format("L%s cap %s", tostring(plot:GetAttribute("Level")),
				tostring(plot:GetAttribute("Capacity"))))
		check(plot:FindFirstChild(PLOT.PlantsFolderName) == plants
			and plot:FindFirstChild(PLOT.RuntimeFolderName) == runtime,
			"the same two folder instances survive the release resize")
		check(#plants:GetChildren() == 0 and #runtime:GetChildren() == 0,
			"Plants and Runtime are empty",
			string.format("%d / %d", #plants:GetChildren(), #runtime:GetChildren()))
		check(plot:GetAttribute(GameConfig.Attributes.PlotId) == 99,
			"the plot keeps its identity across a rebuild")

		--== ASSIGN: straight to the new owner's saved level, in one build ==--
		MapService.ResizePlot(plot, 3)
		plot:SetAttribute(GameConfig.Attributes.OwnerUserId, 2222)
		plot:SetAttribute(GameConfig.Attributes.OwnerName, "NewOwner")
		plot:SetAttribute(GameConfig.Attributes.Claimed, true)

		check((gate() - startGate).Magnitude <= 1e-3,
			"the gate does not move on assignment either",
			string.format("%.6f", (gate() - startGate).Magnitude))

		-- Every number the new owner's plot reports has to describe the SAME
		-- level. A plot claiming L3 with L1 capacity is the shape of bug that
		-- lets a panel advertise slots the server will refuse.
		local level = plot:GetAttribute("Level")
		local consistent = level == 3
			and plot:GetAttribute("Capacity") == GameConfig.plotCapacityForTier(3)
			and plot:GetAttribute("Rows") == GameConfig.plotRowsForTier(3)
			and math.abs(plot:GetAttribute("Depth")
				- GameConfig.plotDepthFor(GameConfig.plotRowsForTier(3))) < 1e-3
		check(consistent, "Level, Capacity, Rows and Depth all describe Level 3",
			string.format("L%s cap %s rows %s depth %s", tostring(level),
				tostring(plot:GetAttribute("Capacity")),
				tostring(plot:GetAttribute("Rows")),
				tostring(plot:GetAttribute("Depth"))))
		check(plot:GetAttribute(GameConfig.Attributes.OwnerUserId) == 2222
			and plot:GetAttribute(GameConfig.Attributes.Claimed) == true,
			"ownership marks describe the new owner")
		check(#plants:GetChildren() == 0,
			"the new owner inherits an empty bed, not the old owner's plants",
			#plants:GetChildren())

		-- Reusable: the things every other service looks up by name.
		check(plot.PrimaryPart ~= nil, "PrimaryPart was replaced with the new floor")
		local pad = plot:FindFirstChild(PLOT.SpawnPadName)
		check(pad ~= nil and pad:IsA("SpawnLocation"),
			"the SpawnLocation exists again after the rebuild")
		check(plot:FindFirstChild(PLOT.PlanterName) ~= nil, "the soil exists again")

		-- The soil has to be able to hold the new owner's garden BEFORE their
		-- plants are restored into it -- PlotService resizes ahead of firing
		-- onAssigned for exactly this reason.
		local soil = plot:FindFirstChild(PLOT.PlanterName)
		local wantSpan = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(3))
			- PLOT.BedMargin * 2
		check(math.abs(soil.Size.Z - wantSpan) < 1e-3,
			"the soil is the new owner's size before anything is restored into it",
			string.format("%.2f vs %.2f", soil.Size.Z, wantSpan))
	end)

	plot:Destroy()
	check(ok, "the handover sequence ran without error", err)
end

--==============================================================================
-- 7. THE SIDE BED
--
-- Room, not capacity. Everything here is about the plot having somewhere to put
-- twenty walking creatures; not one assertion in it may change what a level
-- HOLDS, which is why the capacity and price checks in sections 1 and 2 are the
-- guard rail for this whole feature.
--==============================================================================
say("\n-- side bed --")

do
	local SIDE = GameConfig.Plot.SideBed
	local rows = {}
	for lvl = 1, #T do
		rows[lvl] = GameConfig.plotSideRowsForTier(lvl)
	end
	check(rows[1] == 0 and rows[2] == 0,
		"levels 1 and 2 have no side bed",
		string.format("L1=%d L2=%d", rows[1], rows[2]))
	check(rows[3] > 0 and rows[4] > 0 and rows[5] > 0,
		"levels 3, 4 and 5 all have one",
		string.format("L3=%d L4=%d L5=%d", rows[3], rows[4], rows[5]))
	check(rows[3] <= rows[4] and rows[4] <= rows[5],
		"it never gets shorter as the plot grows",
		table.concat(rows, " "))
	check(GameConfig.plotHasSideBed(2) == false and GameConfig.plotHasSideBed(3) == true,
		"plotHasSideBed agrees with the row table")

	-- Rear-anchored: the back edge lines up with the main bed's, and the front
	-- never reaches the gate.
	local aligned, clears = true, true
	local detail = ""
	for lvl = 3, #T do
		local f, b = GameConfig.plotSideBedZ(lvl)
		local mainRows = GameConfig.plotRowsForTier(lvl)
		local mainBack = (mainRows * GameConfig.Plot.RowDepth
			+ (mainRows - 1) * GameConfig.Plot.RowGap) * 0.5
		if math.abs((b :: number) - mainBack) > 1e-3 then aligned = false end
		-- The fence steps out WingMargin + a frame width ahead of the bed, and
		-- that step may never pass the treadmill line.
		local fence = (f :: number) - SIDE.WingMargin - GameConfig.Plot.BedFrameWidth
		if fence < SIDE.WingFrontZ - 1e-3 then clears = false end
		detail ..= string.format(" L%d[%.1f..%.1f fence %.1f]", lvl, f, b, fence)
	end
	check(aligned, "the side bed's back edge lines up with the main bed's", detail)
	check(clears, "its fence never reaches forward of the treadmill line",
		string.format("limit %.1f;%s", SIDE.WingFrontZ, detail))

	-- The wing must not eat the gate. The front fence is at -depth/2, and the
	-- step-out has to sit well behind it.
	local behind = true
	local gap = ""
	for lvl = 3, #T do
		local f = GameConfig.plotSideBedZ(lvl)
		local fence = (f :: number) - SIDE.WingMargin - GameConfig.Plot.BedFrameWidth
		local halfD = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(lvl)) * 0.5
		local behindGate = fence + halfD
		gap ..= string.format(" L%d=%.1f", lvl, behindGate)
		if behindGate < 10 then behind = false end
	end
	check(behind, "the wing starts at least 10 studs behind the gate", gap)
end

-- The plot's front edge is the same width at every level: the wing is a REAR
-- flare, and widening the front is what would push into a neighbour.
do
	local width = GameConfig.Plot.Width
	check(width == 48, "the plot's front width is unchanged", width)
	check(GameConfig.Plot.SideBed.WingWidth > 0,
		"the wing has a width to add", GameConfig.Plot.SideBed.WingWidth)
end

--==============================================================================
-- 8. WANDER PACING
--
-- The curves live in SeedData and the SERVER is their only caller. A client
-- keeping its own copy is the bug these assertions exist to catch.
--==============================================================================
say("\n-- wander --")

do
	local W = GameConfig.Plant.Wander
	check(W.FenceMargin > 0 and W.GateMargin > W.FenceMargin,
		"a creature is kept off the fence, and further out of the gateway",
		string.format("fence %.1f gate %.1f", W.FenceMargin, W.GateMargin))
	check(W.Candidates >= 3, "several destinations are considered", W.Candidates)
	check(W.SeparationStuds > 0 and W.SeparationStuds < 100,
		"the separation target is bounded -- a Colossal must not make every "
		.. "destination illegal", W.SeparationStuds)

	-- Heavier creatures move slower, rest longer and cover less ground.
	local slower, longer, shorter = true, true, true
	local tbl = ""
	local prevS, prevP, prevR = math.huge, -math.huge, math.huge
	for tier = 1, SeedData.TierCount do
		local sp = SeedData.WanderSpeed(tier)
		local pa = SeedData.WanderPause(tier)
		local re = SeedData.WanderReach(tier)
		tbl ..= string.format(" %s:%.2f/%.1f/%.0f", SeedData.TierName(tier), sp, pa, re)
		if sp > prevS + 1e-6 then slower = false end
		if pa < prevP - 1e-6 then longer = false end
		if re > prevR + 1e-6 then shorter = false end
		prevS, prevP, prevR = sp, pa, re
	end
	check(slower, "bigger creatures walk slower", tbl)
	check(longer, "bigger creatures rest longer", tbl)
	check(shorter, "bigger creatures cover less ground per leg", tbl)

	-- A leg has to be worth taking, and shorter than the plot.
	local reachOk = SeedData.WanderReach(1) > W.MinLegStuds
		and SeedData.WanderReach(1) < GameConfig.Plot.Width
	check(reachOk, "the longest leg is longer than the shortest and still fits the plot",
		string.format("%.1f in (%.1f, %d)", SeedData.WanderReach(1),
			W.MinLegStuds, GameConfig.Plot.Width))
end

say(string.format("\n%d passed, %d failed", pass, fail))
return table.concat(out, "\n")
