--!nocheck
--==============================================================================
-- Steal a Seed :: PlantWanderSpec
--
-- How far a grown creature walks, and that every step of every walk stays on
-- its own plot. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("PlantWanderSpec"))
--
-- The real PlantWander, fresh-required, choosing thousands of legs on plots
-- dressed by the real MapService.ResizePlot at Levels 1, 3 and 5, with the
-- server's own pacing: a 1 s tick, SeedData's pause stretched 0.7-1.7x, and
-- PlantWander.LegSeconds. Walkers start in the middle, in every corner, against
-- the fences, beside the gateway and at the wing's junction, alone and in beds
-- of twenty.
--
-- Every route is checked THREE independent ways, none of which use
-- PlantWander's own geometry:
--   * sampled every 0.2 studs against the region rebuilt here from the plot's
--     attributes and GameConfig;
--   * exactly, against the centre line of every Rail and Post MapService built,
--     which must stay FenceMargin away;
--   * exactly, against the gateway's mouth.
--
-- Not here, verified in Play instead: PlantService's tick itself, the client
-- drawing a leg (PlantSway), feet on the ground, pickup anchors, resize parking.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local PlantWander = require(Server:WaitForChild("PlantWander"))
local MapService = require(Server:WaitForChild("MapService"))

local PLOT = GameConfig.Plot
local W = GameConfig.Plant.Wander

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

local function median(list)
	local n = #list
	if n == 0 then
		return 0
	end
	local sorted = table.clone(list)
	table.sort(sorted)
	if n % 2 == 1 then
		return sorted[(n + 1) / 2]
	end
	return (sorted[n / 2] + sorted[n / 2 + 1]) / 2
end

local TIERS = SeedData.TierCount

--==============================================================================
-- 1. THE LADDER
--==============================================================================
say("\n-- ladder --")
do
	local reachUp, minUp, below, slower = true, true, true, true
	local tbl = ""
	for tier = 1, TIERS do
		local re, mi, sp = SeedData.WanderReach(tier), SeedData.WanderMinLeg(tier), SeedData.WanderSpeed(tier)
		tbl ..= string.format(" %s %.1f/%.1f/%.2f", SeedData.TierName(tier), re, mi, sp)
		if mi >= re then below = false end
		if tier > 1 then
			if re <= SeedData.WanderReach(tier - 1) then reachUp = false end
			if mi <= SeedData.WanderMinLeg(tier - 1) then minUp = false end
			if sp > SeedData.WanderSpeed(tier - 1) + 1e-9 then slower = false end
		end
	end
	check(reachUp, "reach climbs with every tier", tbl)
	check(minUp, "the minimum leg climbs with every tier -- not one shared floor", tbl)
	check(below, "every tier's minimum leg is shorter than its reach", tbl)
	check(slower, "no bigger creature walks faster than a smaller one", tbl)
	check(SeedData.WanderReach(TIERS) >= 2 * SeedData.WanderReach(1),
		"a Colossal's reach is at least twice a Tiny's",
		string.format("%.1f vs %.1f", SeedData.WanderReach(TIERS), SeedData.WanderReach(1)))
	check(SeedData.WanderStallStuds > 0 and SeedData.WanderStallStuds < SeedData.WanderMinLeg(1),
		"the stall floor is positive and below the shortest minimum leg", SeedData.WanderStallStuds)
	local okJunk = pcall(function()
		return SeedData.WanderReach(nil) + SeedData.WanderReach(0 / 0) + SeedData.WanderReach(99)
			+ SeedData.WanderMinLeg(-4) + SeedData.WanderSpeed("x")
	end)
	check(okJunk, "a junk tier reads as a real rung rather than throwing")
	check(W.Attempts >= W.Candidates and W.Attempts <= 64,
		"candidate work is bounded", string.format("%d candidates in at most %d directions",
			W.Candidates, W.Attempts))
end

--==============================================================================
-- 2. REAL PLOTS
--
-- Dressed by MapService.ResizePlot exactly as PlotSpec's handover does, far above
-- the map, and read back through the same attributes the server reads.
--==============================================================================
local plotModel = Instance.new("Model")
plotModel.Name = "PlantWanderSpecPlot"
plotModel.Archivable = false
plotModel:SetAttribute("PreviewOnly", true)
plotModel:SetAttribute(GameConfig.Attributes.PlotId, 98)
plotModel.Parent = workspace
do
	local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
	local centreR = GameConfig.Map.PlotRingInner + startDepth * 0.5
	plotModel:SetAttribute("PlotCF",
		CFrame.lookAt(Vector3.new(0, 700, centreR), Vector3.new(0, 700, 0)))
	plotModel:SetAttribute("Depth", startDepth)
end

-- Everything this spec knows about a level's plot, measured off the built parts.
local function survey(level)
	MapService.ResizePlot(plotModel, level)
	local cf = plotModel:GetAttribute("PlotCF")
	local depth = plotModel:GetAttribute("Depth")
	local g = {
		level = level,
		depth = depth,
		halfW = PLOT.Width * 0.5,
		halfD = depth * 0.5,
		wingW = plotModel:GetAttribute("WingWidth") or 0,
		wingZ0 = plotModel:GetAttribute("WingFrontZ") or 0,
		capacity = plotModel:GetAttribute("Capacity"),
		region = PlantWander.RegionFor(plotModel),
		fence = {},
	}
	g.outerW = g.halfW + g.wingW

	-- The ruler: every plant offset is measured in the main soil's space, so the
	-- fences are only comparable if the soil is centred on the plot and square to
	-- it.
	local soil = plotModel:FindFirstChild(PLOT.PlanterName)
	local rel = cf:ToObjectSpace(soil.CFrame)
	g.soilAligned = math.abs(rel.Position.X) < 1e-3 and math.abs(rel.Position.Z) < 1e-3
		and rel.RightVector:FuzzyEq(Vector3.xAxis, 1e-4) and rel.LookVector:FuzzyEq(-Vector3.zAxis, 1e-4)

	for _, part in ipairs(plotModel:GetChildren()) do
		if part:IsA("BasePart") and (part.Name == "Rail" or part.Name == "Post") then
			local lp = cf:PointToObjectSpace(part.Position)
			if part.Name == "Post" then
				table.insert(g.fence, { ax = lp.X, az = lp.Z, bx = lp.X, bz = lp.Z })
			elseif part.Size.X >= part.Size.Z then
				table.insert(g.fence, { ax = lp.X - part.Size.X * 0.5, az = lp.Z,
					bx = lp.X + part.Size.X * 0.5, bz = lp.Z })
			else
				table.insert(g.fence, { ax = lp.X, az = lp.Z - part.Size.Z * 0.5,
					bx = lp.X, bz = lp.Z + part.Size.Z * 0.5 })
			end
		end
	end
	return g
end

--==============================================================================
-- THE INDEPENDENT CHECKS
--
-- Written from GameConfig and the plot's attributes, deliberately not from
-- PlantWander, so a mistake in its geometry cannot hide behind itself.
--==============================================================================
local GATE_HALF = PLOT.GateWidth * 0.5 + 2

local function insideRegion(g, x, z)
	local m, tol = W.FenceMargin, 1e-4
	local inMain = x >= -g.halfW + m - tol and x <= g.halfW - m + tol
		and z >= -g.halfD + m - tol and z <= g.halfD - m + tol
	local inWing = g.wingW > 0 and x >= g.halfW - m - tol and x <= g.outerW - m + tol
		and z >= g.wingZ0 + m - tol and z <= g.halfD - m + tol
	if not (inMain or inWing) then
		return false
	end
	return not (z < -g.halfD + W.GateMargin - tol and math.abs(x) < GATE_HALF - tol)
end

-- Inside the plot's own fence line at all: its rectangle, plus the wing, minus
-- the missing corner of the L. Nothing outside this is this player's ground.
local function ownGround(g, x, z)
	if x < -g.halfW or x > g.outerW or z < -g.halfD or z > g.halfD then
		return false
	end
	return not (x > g.halfW and z < g.wingZ0)
end

local function segDistance(ax, az, bx, bz, px, pz)
	local vx, vz = bx - ax, bz - az
	local len2 = vx * vx + vz * vz
	local t = if len2 > 0 then math.clamp(((px - ax) * vx + (pz - az) * vz) / len2, 0, 1) else 0
	local dx, dz = ax + vx * t - px, az + vz * t - pz
	return math.sqrt(dx * dx + dz * dz)
end

local function cross(ax, az, bx, bz, cx, cz)
	return (bx - ax) * (cz - az) - (bz - az) * (cx - ax)
end

-- Exact distance between two segments in the plane.
local function segSeg(s, ax, az, bx, bz)
	local d1 = cross(ax, az, bx, bz, s.ax, s.az)
	local d2 = cross(ax, az, bx, bz, s.bx, s.bz)
	local d3 = cross(s.ax, s.az, s.bx, s.bz, ax, az)
	local d4 = cross(s.ax, s.az, s.bx, s.bz, bx, bz)
	if ((d1 > 0 and d2 < 0) or (d1 < 0 and d2 > 0)) and ((d3 > 0 and d4 < 0) or (d3 < 0 and d4 > 0)) then
		return 0
	end
	return math.min(
		segDistance(ax, az, bx, bz, s.ax, s.az),
		segDistance(ax, az, bx, bz, s.bx, s.bz),
		segDistance(s.ax, s.az, s.bx, s.bz, ax, az),
		segDistance(s.ax, s.az, s.bx, s.bz, bx, bz))
end

-- How much of a segment lies strictly inside the gateway's mouth.
local function gateLength(g, ax, az, bx, bz)
	local x0, x1 = -GATE_HALF + 1e-6, GATE_HALF - 1e-6
	local z1 = -g.halfD + W.GateMargin - 1e-6
	local t0, t1 = 0, 1
	local dx, dz = bx - ax, bz - az
	local function clip(p, q)
		if math.abs(p) < 1e-12 then
			return q >= 0
		end
		local r = q / p
		if p < 0 then
			if r > t1 then return false end
			if r > t0 then t0 = r end
		else
			if r < t0 then return false end
			if r < t1 then t1 = r end
		end
		return true
	end
	if clip(-dx, ax - x0) and clip(dx, x1 - ax) and clip(dz, z1 - az) then
		if t1 > t0 then
			return (t1 - t0) * math.sqrt(dx * dx + dz * dz)
		end
	end
	return 0
end

-- The route of one leg, every way. Returns nil when it is clean.
local function routeFault(g, a, b)
	local dist = (b - a).Magnitude
	local n = math.max(1, math.ceil(dist / 0.2))
	for i = 0, n do
		local p = a:Lerp(b, i / n)
		if not insideRegion(g, p.X, p.Z) then
			return string.format("sample (%.2f, %.2f) outside the region", p.X, p.Z)
		end
		if not ownGround(g, p.X, p.Z) then
			return string.format("sample (%.2f, %.2f) off the plot", p.X, p.Z)
		end
	end
	for _, s in ipairs(g.fence) do
		local d = segSeg(s, a.X, a.Z, b.X, b.Z)
		if d < W.FenceMargin - 1e-3 then
			return string.format("passes %.2f studs from a fence board", d)
		end
	end
	local inGate = gateLength(g, a.X, a.Z, b.X, b.Z)
	if inGate > 1e-4 then
		return string.format("%.3f studs through the gateway", inGate)
	end
	return nil
end

--==============================================================================
-- THE SERVER'S PACING, WITHOUT THE SERVER
--
-- stepWander's own order on its own tick: arrive and commit, rest for the
-- tier's pause stretched 0.7-1.7x off the entry's Random, then choose.
--==============================================================================
local chooseCalls, chooseSeconds, chooseWorst = 0, 0, 0

local function simulate(g, walkers, seconds, legs, samples)
	local byPlot, ids = {}, {}
	for _, w in ipairs(walkers) do
		byPlot[w.id] = { id = w.id, tier = w.tier, offset = w.offset,
			rng = Random.new(w.id * 7919 + 13 + (w.seed or 0)) }
		table.insert(ids, w.id)
	end
	table.sort(ids)
	for now = 0, seconds do
		for _, id in ipairs(ids) do
			local e = byPlot[id]
			if e.legEnd and now >= e.legEnd then
				if legs then
					table.insert(legs, { tier = e.tier, from = e.legFrom, to = e.legTo,
						dist = (e.legTo - e.legFrom).Magnitude, dur = e.legEnd - e.legStart,
						how = e.how, startedInside = insideRegion(g, e.legFrom.X, e.legFrom.Z) })
				end
				e.offset = e.legTo
				e.legEnd = nil
				e.restUntil = now + SeedData.WanderPause(e.tier) * e.rng:NextNumber(0.7, 1.7)
			end
			if not e.legEnd and now >= (e.restUntil or 0) then
				local clock = os.clock()
				local to, how = PlantWander.Choose(g.region, e.offset, e.tier, byPlot, e.id, e.rng)
				local spent = os.clock() - clock
				chooseCalls += 1
				chooseSeconds += spent
				if spent > chooseWorst then chooseWorst = spent end
				if how == "stay" then
					e.restUntil = now + SeedData.WanderPause(e.tier)
					if legs then
						table.insert(legs, { tier = e.tier, how = "stay", dist = 0, dur = 0 })
					end
				else
					e.legFrom, e.legTo, e.legStart = e.offset, to, now
					e.legEnd = now + PlantWander.LegSeconds(e.tier, (to - e.offset).Magnitude)
					e.how = how
				end
			end
		end
		if samples and now >= 60 and now % 10 == 0 then
			local list = {}
			for _, id in ipairs(ids) do
				local e = byPlot[id]
				table.insert(list, if e.legEnd then e.legTo else e.offset)
			end
			table.insert(samples, list)
		end
	end
end

local function spacing(list)
	local sumNN, piled = 0, 0
	for i = 1, #list do
		local nn, near = math.huge, 0
		for j = 1, #list do
			if i ~= j then
				local d = (list[i] - list[j]).Magnitude
				if d < nn then nn = d end
				if d < 8 then near += 1 end
			end
		end
		sumNN += nn
		if near >= 2 then piled += 1 end
	end
	return sumNN / #list, piled / #list
end

local function randomInside(g, rng)
	local p
	repeat
		p = Vector3.new(rng:NextNumber(-g.halfW, g.outerW), 0, rng:NextNumber(-g.halfD, g.halfD))
	until insideRegion(g, p.X, p.Z)
	return p
end

local function startsFor(g)
	local m = W.FenceMargin
	local x0, x1, z0, z1 = -g.halfW + m, g.halfW - m, -g.halfD + m, g.halfD - m
	local list = {
		{ "centre", Vector3.new(0, 0, 0) },
		{ "front-left corner", Vector3.new(x0, 0, z0) },
		{ "front-right corner", Vector3.new(x1, 0, z0) },
		{ "back-left corner", Vector3.new(x0, 0, z1) },
		{ "back fence", Vector3.new(0, 0, z1) },
		{ "left fence", Vector3.new(x0, 0, 0) },
		{ "beside the gateway, left", Vector3.new(-GATE_HALF, 0, z0) },
		{ "beside the gateway, right", Vector3.new(GATE_HALF, 0, z0) },
		{ "behind the gateway", Vector3.new(0, 0, -g.halfD + W.GateMargin) },
	}
	if g.wingW > 0 then
		local wz0 = g.wingZ0 + m
		table.insert(list, { "the L's inside corner", Vector3.new(x1, 0, wz0) })
		table.insert(list, { "just in front of the step", Vector3.new(x1, 0, wz0 - 0.5) })
		table.insert(list, { "wing front-outer corner", Vector3.new(g.outerW - m, 0, wz0) })
		table.insert(list, { "wing back-outer corner", Vector3.new(g.outerW - m, 0, z1) })
	else
		table.insert(list, { "back-right corner", Vector3.new(x1, 0, z1) })
	end
	return list
end

local function body()
--==============================================================================
-- 3. THE REGION AND ITS CLAMP
--==============================================================================
local levels = {}
local ok, err = pcall(function()
	for _, level in ipairs({ 1, 3, 5 }) do
		levels[level] = survey(level)
	end
end)
check(ok, "plots dressed at Levels 1, 3 and 5", err)

say("\n-- region --")
if ok then
	-- The clamp that shipped before this change, verbatim, as the reference.
	local function legacyClamp(g, x, z)
		local m = W.FenceMargin
		local mainX = math.clamp(x, -g.halfW + m, g.halfW - m)
		local mainZ = math.clamp(z, -g.halfD + m, g.halfD - m)
		local bx, bz = mainX, mainZ
		if g.wingW > 0 then
			local wx = math.clamp(x, g.halfW - m, g.halfW + g.wingW - m)
			local wz = math.clamp(z, g.wingZ0 + m, g.halfD - m)
			local dMain = (Vector2.new(x, z) - Vector2.new(mainX, mainZ)).Magnitude
			local dWing = (Vector2.new(x, z) - Vector2.new(wx, wz)).Magnitude
			if dWing < dMain then bx, bz = wx, wz end
		end
		if bz < -g.halfD + W.GateMargin and math.abs(bx) < GATE_HALF then
			bz = -g.halfD + W.GateMargin
		end
		return bx, bz
	end

	for _, level in ipairs({ 1, 3, 5 }) do
		local g = levels[level]
		check(g.soilAligned, string.format("L%d: the main soil is centred on the plot and square to it", level))
		check(#g.fence >= (if g.wingW > 0 then 14 else 10),
			string.format("L%d: the fence was found (%d boards and posts)", level, #g.fence), #g.fence)

		-- Every corner of the walkable region stands FenceMargin off the real fence.
		local worst = math.huge
		local r = g.region
		local boxes = { r.main }
		if r.wing then table.insert(boxes, r.wing) end
		for _, b in ipairs(boxes) do
			for _, c in ipairs({ { b.x0, b.z0 }, { b.x1, b.z0 }, { b.x0, b.z1 }, { b.x1, b.z1 } }) do
				for _, s in ipairs(g.fence) do
					local d = segDistance(s.ax, s.az, s.bx, s.bz, c[1], c[2])
					if d < worst then worst = d end
				end
			end
		end
		check(worst >= W.FenceMargin - 1e-3,
			string.format("L%d: the region's corners keep FenceMargin off every board", level),
			string.format("closest %.3f", worst))

		local rng = Random.new(level * 31)
		local same, legal, bad = 0, 0, ""
		for _ = 1, 4000 do
			local x = rng:NextNumber(-g.halfW - 30, g.outerW + 30)
			local z = rng:NextNumber(-g.halfD - 30, g.halfD + 30)
			local v = Vector3.new(x, 0, z)
			local c = PlantWander.Clamp(r, v)
			local lx, lz = legacyClamp(g, v.X, v.Z)
			-- Compared as the Vector3 the old function returned, so both sides
			-- carry the same single-precision rounding.
			if c == Vector3.new(lx, 0, lz) then
				same += 1
			elseif #bad < 200 then
				bad ..= string.format(" (%.1f,%.1f)->%.2f,%.2f vs %.2f,%.2f", x, z, c.X, c.Z, lx, lz)
			end
			if insideRegion(g, c.X, c.Z) and PlantWander.Inside(r, c) then
				legal += 1
			end
		end
		check(same == 4000, string.format("L%d: Clamp is exactly the clamp that shipped, 4000 points", level), bad)
		check(legal == 4000, string.format("L%d: every clamped point is legal", level), legal)

		-- Inside agrees with the independent test away from the boundary.
		local agree, total = 0, 0
		for _ = 1, 4000 do
			local x = rng:NextNumber(-g.halfW - 5, g.outerW + 5)
			local z = rng:NextNumber(-g.halfD - 5, g.halfD + 5)
			total += 1
			if PlantWander.Inside(r, Vector3.new(x, 0, z)) == insideRegion(g, x, z) then
				agree += 1
			end
		end
		check(agree == total, string.format("L%d: Inside agrees with the independent region test", level),
			string.format("%d of %d", agree, total))

		-- Room: the stretch it reports is inside all the way, and it is the
		-- whole stretch -- one step past it is outside.
		local clean, maximal, rays, fault = 0, 0, 0, ""
		for _ = 1, 1500 do
			local p = randomInside(g, rng)
			local a = rng:NextNumber(0, math.pi * 2)
			local dx, dz = math.cos(a), math.sin(a)
			local room = PlantWander.Room(r, p, dx, dz)
			rays += 1
			local q = p + Vector3.new(dx, 0, dz) * room
			if routeFault(g, p, q) == nil then
				clean += 1
			elseif #fault < 200 then
				fault ..= " " .. tostring(routeFault(g, p, q))
			end
			local past = p + Vector3.new(dx, 0, dz) * (room + 0.05)
			if not insideRegion(g, past.X, past.Z) then
				maximal += 1
			end
		end
		check(clean == rays, string.format("L%d: every stretch Room reports is inside end to end (%d rays)", level, rays), fault)
		check(maximal >= rays * 0.995, string.format("L%d: Room reports the whole stretch", level),
			string.format("%d of %d end at the boundary", maximal, rays))
	end
end

--==============================================================================
-- 4. THOUSANDS OF LEGS
--==============================================================================
local stats = {}
if ok then
	say("\n-- legs --")
	local SOLO_SECONDS, CROWD_RUNS, CROWD_SECONDS = 300, 3, 900
	for _, level in ipairs({ 1, 3, 5 }) do
		local g = levels[level]
		local legs = {}
		local seed = 0
		for tier = 1, TIERS do
			for _, s in ipairs(startsFor(g)) do
				seed += 1
				simulate(g, { { id = 1, tier = tier, offset = s[2], seed = seed * 101 } }, SOLO_SECONDS, legs, nil)
			end
		end
		-- A bed of twenty, whatever the level holds.
		local crowdSamples = {}
		for run = 1, CROWD_RUNS do
			local rng = Random.new(level * 1000 + run)
			local walkers = {}
			for i = 1, 20 do
				table.insert(walkers, { id = i, tier = (i - 1) % TIERS + 1, offset = randomInside(g, rng), seed = run * 17 })
			end
			simulate(g, walkers, CROWD_SECONDS, legs, crowdSamples)
		end
		-- And a bed at the level's own capacity.
		local capSamples = {}
		for run = 1, CROWD_RUNS do
			local rng = Random.new(level * 2000 + run)
			local walkers = {}
			for i = 1, g.capacity do
				table.insert(walkers, { id = i, tier = (i - 1) % TIERS + 1, offset = randomInside(g, rng), seed = run * 29 })
			end
			simulate(g, walkers, CROWD_SECONDS, legs, capSamples)
		end

		-- Route checks and per-tier numbers.
		local faults, firstFault = 0, nil
		local perTier = {}
		for tier = 1, TIERS do
			perTier[tier] = { dist = {}, dur = {}, longest = 0, stay = 0, recover = 0, short = 0, belowMin = 0 }
		end
		for _, l in ipairs(legs) do
			local t = perTier[l.tier]
			if l.how == "stay" then
				t.stay += 1
			else
				table.insert(t.dist, l.dist)
				table.insert(t.dur, l.dur)
				if l.how == "longest" then t.longest += 1 end
				if l.how == "recover" then t.recover += 1 end
				if l.dist < SeedData.WanderStallStuds then t.short += 1 end
				if l.dist < SeedData.WanderMinLeg(l.tier) - 1e-6 and l.how ~= "longest" then t.belowMin += 1 end
				if l.startedInside then
					local fault = routeFault(g, l.from, l.to)
					if fault then
						faults += 1
						firstFault = firstFault or string.format("%s leg %s", SeedData.TierName(l.tier), fault)
					end
				end
			end
		end

		say(string.format("\n  Level %d  (%d x %.1f plot, wing %d)", level, PLOT.Width, g.depth, g.wingW))
		say("  tier        reach  min leg     legs   min   median   max    speed  median time  max time")
		local levelStats = {}
		for tier = 1, TIERS do
			local t = perTier[tier]
			local mn, mx = math.huge, 0
			for _, d in ipairs(t.dist) do
				if d < mn then mn = d end
				if d > mx then mx = d end
			end
			local maxDur = 0
			for _, d in ipairs(t.dur) do
				if d > maxDur then maxDur = d end
			end
			local row = { n = #t.dist, min = mn, median = median(t.dist), max = mx,
				medDur = median(t.dur), maxDur = maxDur, longest = t.longest, stay = t.stay,
				recover = t.recover, short = t.short, belowMin = t.belowMin }
			levelStats[tier] = row
			say(string.format("  %-9s  %5.1f  %6.1f   %6d  %5.1f  %6.1f  %5.1f   %5.2f   %6.1f s   %6.1f s%s",
				SeedData.TierName(tier), SeedData.WanderReach(tier), SeedData.WanderMinLeg(tier), row.n,
				row.min, row.median, row.max, SeedData.WanderSpeed(tier), row.medDur, row.maxDur,
				if row.longest + row.stay > 0 then string.format("  (%d fallback, %d stay)", row.longest, row.stay) else ""))
		end
		stats[level] = levelStats

		check(faults == 0, string.format("L%d: every route inside the region, off the fence, out of the gateway, on its own plot (%d legs)", level, #legs), firstFault)

		local twitch, belowMin, fallbacks, total = 0, 0, 0, 0
		for tier = 1, TIERS do
			local row = levelStats[tier]
			twitch += row.short
			belowMin += row.belowMin
			fallbacks += row.longest + row.stay
			total += row.n + row.stay
		end
		check(twitch == 0, string.format("L%d: no leg shorter than the stall floor", level), twitch)
		check(belowMin == 0, string.format("L%d: no normal leg shorter than its tier's minimum", level), belowMin)
		check(fallbacks <= total * 0.01, string.format("L%d: fallbacks are rare", level),
			string.format("%d of %d", fallbacks, total))

		local rising, detail = true, ""
		for tier = 1, TIERS do
			detail ..= string.format(" %.1f", levelStats[tier].median)
			if tier > 1 and levelStats[tier].median <= levelStats[tier - 1].median then rising = false end
		end
		check(rising, string.format("L%d: the median leg climbs with every tier", level), detail)
		local ratio = levelStats[TIERS].median / levelStats[1].median
		if level >= 3 then
			check(ratio >= 1.7, string.format("L%d: a Colossal's median leg is at least 1.7x a Tiny's", level),
				string.format("%.2fx", ratio))
		else
			say(string.format("  (L1 is a %.0f by %.0f stud bed: Colossal/Tiny median %.2fx)",
				PLOT.Width - 2 * W.FenceMargin, g.depth - 2 * W.FenceMargin, ratio))
		end
		local slowest = 0
		for tier = 1, TIERS do
			slowest = math.max(slowest, levelStats[tier].medDur)
		end
		check(slowest <= 20, string.format("L%d: no tier's median leg takes longer than 20 s", level),
			string.format("%.1f s", slowest))

		-- Spreading out. Measured on where each plant rests or is headed, against
		-- the same count scattered uniformly at random.
		local function spread(samples)
			local nns, piles = {}, 0
			for _, list in ipairs(samples) do
				local nn, piled = spacing(list)
				table.insert(nns, nn)
				piles += piled
			end
			return median(nns), piles / math.max(#samples, 1)
		end
		local function scatter(count)
			local rng = Random.new(level * 77 + count)
			local nns, piles = {}, 0
			for _ = 1, 300 do
				local list = {}
				for i = 1, count do list[i] = randomInside(g, rng) end
				local nn, piled = spacing(list)
				table.insert(nns, nn)
				piles += piled
			end
			return median(nns), piles / 300
		end
		local capNN, capPiles = spread(capSamples)
		local capRandNN, capRandPiles = scatter(g.capacity)
		local crowdNN, crowdPiles = spread(crowdSamples)
		local crowdRandNN, crowdRandPiles = scatter(20)
		say(string.format("  spacing at capacity (%d): nearest %.1f studs (random %.1f), in a pile of 3 inside 8 studs %.1f%% (random %.1f%%)",
			g.capacity, capNN, capRandNN, capPiles * 100, capRandPiles * 100))
		say(string.format("  spacing with twenty: nearest %.1f studs (random %.1f), in a pile %.1f%% (random %.1f%%)",
			crowdNN, crowdRandNN, crowdPiles * 100, crowdRandPiles * 100))
		check(capNN >= capRandNN * 1.25 and capPiles <= 0.02,
			string.format("L%d: a bed at capacity spreads out rather than piling up", level),
			string.format("nearest %.1f vs random %.1f, piles %.1f%%", capNN, capRandNN, capPiles * 100))
		check(crowdNN >= crowdRandNN * 1.1,
			string.format("L%d: a bed of twenty stays better spread than a random scatter", level),
			string.format("nearest %.1f vs random %.1f", crowdNN, crowdRandNN))
	end
end

--==============================================================================
-- 5. EDGES
--==============================================================================
if ok then
	say("\n-- edges --")
	local g = levels[3]

	-- The same walker, the same seed: the same walk.
	local a, b = {}, {}
	simulate(g, { { id = 7, tier = 7, offset = Vector3.new(10, 0, 5), seed = 3 } }, 200, a, nil)
	simulate(g, { { id = 7, tier = 7, offset = Vector3.new(10, 0, 5), seed = 3 } }, 200, b, nil)
	local same = #a == #b and #a > 0
	for i = 1, math.min(#a, #b) do
		if a[i].how ~= b[i].how or (a[i].to and not a[i].to:FuzzyEq(b[i].to, 1e-9)) then same = false end
	end
	check(same, "deterministic: the same seed walks the same legs", string.format("%d vs %d", #a, #b))

	-- Standing somewhere it may not: the first leg brings it back, and every leg
	-- after that is an ordinary one.
	local rec = {}
	simulate(g, { { id = 3, tier = 5, offset = Vector3.new(0, 0, -g.halfD + 1), seed = 9 } }, 120, rec, nil)
	local firstBack = rec[1] and rec[1].how == "recover" and insideRegion(g, rec[1].to.X, rec[1].to.Z)
	local thenNormal = #rec > 2
	for i = 2, #rec do
		if rec[i].how == "recover" or not rec[i].startedInside then thenNormal = false end
	end
	check(firstBack, "a creature standing in the gateway is walked back onto legal ground", rec[1] and rec[1].how)
	check(thenNormal, "and walks ordinary legs from there", #rec)

	-- A space with no room for any walk at all: bounded, and it rests.
	local tiny = { main = { x0 = 0, x1 = 1, z0 = 0, z1 = 1 }, wing = nil,
		gate = { x0 = 100, x1 = 101, z0 = -math.huge, z1 = -100 } }
	local clock = os.clock()
	local to, how = PlantWander.Choose(tiny, Vector3.new(0.5, 0, 0.5), 7, {}, 1, Random.new(1))
	local spent = os.clock() - clock
	check(how == "stay" and to:FuzzyEq(Vector3.new(0.5, 0, 0.5), 1e-9) and spent < 0.05,
		"no room anywhere: it rests, and the search ends", string.format("%s in %.2f ms", tostring(how), spent * 1000))

	-- A corridor shorter than the Colossal minimum but longer than the stall
	-- floor: the longest line on offer.
	local corridor = { main = { x0 = 0, x1 = 12, z0 = 0, z1 = 0.5 }, wing = nil,
		gate = { x0 = 100, x1 = 101, z0 = -math.huge, z1 = -100 } }
	local to2, how2 = PlantWander.Choose(corridor, Vector3.new(1, 0, 0.25), 7, {}, 1, Random.new(2))
	check(how2 == "longest" and (to2 - Vector3.new(1, 0, 0.25)).Magnitude >= 10.9,
		"a corridor too short for the minimum: the longest line on offer, not a shuffle",
		string.format("%s, %.2f studs", tostring(how2), (to2 - Vector3.new(1, 0, 0.25)).Magnitude))

	say(string.format("\n  decision cost: %d choices, mean %.1f us, worst %.2f ms",
		chooseCalls, chooseSeconds / math.max(chooseCalls, 1) * 1e6, chooseWorst * 1000))
end
end

-- Whatever happens inside, the plot this spec built does not outlive it.
local bodyOk, bodyErr = pcall(body)
plotModel:Destroy()
check(bodyOk, "the spec ran to the end", bodyErr)

say(string.format("\nPlantWanderSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
