--!nocheck
--==============================================================================
-- Steal a Seed :: PlotLevelsSpec
--
-- PLOT LEVELS 6 AND 7 (the owner, 2026-10-07): 25 slots for 250,000,000 and 30
-- for 2,500,000,000, on the ground the moved mills freed. Plots 1-5 grow their
-- wing forward into the strip their mills stood in; plot 6, whose mill still
-- stands beside its fence, keeps Level 5's wing and grows deeper. Every plot
-- holds the same number at every level and none has less room than another.
-- Edit mode, built for real -- MapService.ResizePlot at each plot's real place
-- on the ring, with its real id:
--
--   1. the ladder on every plot: Capacity 20 / 25 / 30, the depths, the costs,
--      the board's prices, and the room -- fenced ground and soil -- of each
--   2. clearances, all six plots at every level 1-7, real parts grown 0.25
--      (GetPartsInPart): the other plots' walks and the road's, the deck's rim,
--      the field's edges, both neighbours and their wings (at every pair of
--      levels by footprint, and in 3-D at the top against the top and the
--      bottom), every plot's boards, the night shutter, the obby's entrance
--      and the rain biome's ramp, curtain and landing; the road's empty arc and
--      the Disco Mill's circle no further into than Level 5 / Level 1 already
--      were; every fixed prompt off every plot's ground. The mills, every tier
--      against every level, are MillPlacementSpec's, which builds Levels 6-7 too.
--   3. the field's scatter: dressed around the real ring, it keeps every prop
--      off every plot's every level, and what it keeps is exactly what it rolled
--   4. saves: a Level 5 garden comes back bit for bit on every plot (no frame
--      below Level 6); a Level 7 garden saves and reloads on every plot through
--      ProfileSchema; a garden moved between plot 6 and the others keeps every
--      plant on its owner's ground, and comes back where it was
--   5. the board: at 5 it offers 6 for 250M, at 6 offers 7 for 2.5B, at 7 MAX
--   6. everything else that reads a level, by its source
--
-- Not here, seen in Play instead: the plots built on a running server, the
-- boards' painted words, creatures walking a full Level 7 bed.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local MillModel = require(Shared:WaitForChild("MillModel"))
local PlotShowcase = require(Shared:WaitForChild("PlotShowcase"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local MapService = require(Server:WaitForChild("MapService"))
local MapDecor = require(Server:WaitForChild("MapDecor"))
local PlantWander = require(Server:WaitForChild("PlantWander"))
local GardenFrame = require(Server:WaitForChild("GardenFrame"))
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))
local PlayerDataService = require(Server:WaitForChild("PlayerDataService"))
local PlotUpgradeService = require(Server:WaitForChild("PlotUpgradeService"))

local MAP, PLOT, MILL = GameConfig.Map, GameConfig.Plot, GameConfig.Mill
local DANCERS = GameConfig.MiniEvent.Dancers
local T = GameConfig.PlotTiers
local LEVELS = #T
local CLEAR = 0.25
-- Walks block what stands below this many studs (MillPlacementSpec's).
local LOW = 8
local n = GameConfig.MaxPlots
local M = GameConfig.Plant.Wander.FenceMargin
-- Any real species: the saves below must not care which.
local SPECIES = next(SeedData.ById)

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say("  FAIL  " .. label .. (if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(inst)
	if not inst then
		return ""
	end
	local ok, src = pcall(function()
		return inst.Source
	end)
	return if ok and type(src) == "string" then src else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

local fixture = Instance.new("Folder")
fixture.Name = "PlotLevelsSpecFixture"
fixture.Archivable = false
fixture.Parent = Workspace

--==============================================================================
-- THE RING, AS MapService.Init LAYS IT OUT
--==============================================================================
local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(GameConfig.StartingPlotTier))
local gap = math.rad(MAP.RoadGapDegrees)
local step = (math.pi * 2 - gap) / n
local first = math.pi + gap * 0.5
local centres = {}
for id = 1, n do
	local angle = first + (id - 0.5) * step
	local r = MAP.PlotRingInner + startDepth * 0.5
	local pos = Vector3.new(math.sin(angle) * r, MAP.GroundY, math.cos(angle) * r)
	centres[id] = CFrame.lookAt(pos, Vector3.new(0, MAP.GroundY, 0))
end
local function gateOf(id)
	return centres[id] * CFrame.new(0, 0, -startDepth * 0.5)
end

-- A plot of the ring at `level`: its real id, at its real place, untagged.
local function newPlot(id, level, parent)
	local model = Instance.new("Model")
	model.Name = string.format("SpecPlot%02d", id)
	model:SetAttribute(GameConfig.Attributes.PlotId, id)
	model:SetAttribute(GameConfig.Attributes.OwnerUserId, 0)
	model:SetAttribute(GameConfig.Attributes.Claimed, false)
	model:SetAttribute("PlotCF", centres[id])
	model:SetAttribute("Depth", startDepth)
	model:SetAttribute("Level", GameConfig.StartingPlotTier)
	model.Parent = parent or fixture
	MapService.ResizePlot(model, level)
	return model
end

local function partsOf(model)
	local list = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function cornersOf(part)
	local h = part.Size * 0.5
	local list = {}
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				table.insert(list, (part.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position)
			end
		end
	end
	return list
end

local probe = Instance.new("Part")
probe.Anchored = true
probe.CanCollide = false
probe.CanTouch = false
probe.Transparency = 1
probe.Name = "SpecProbe"
-- What `part`, grown by CLEAR on every side, touches among `against`.
local function touches(part, against)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = against
	params.RespectCanCollide = false
	local p = probe:Clone()
	if part:IsA("Part") then
		p.Shape = part.Shape
	end
	p.Size = part.Size + Vector3.new(CLEAR * 2, CLEAR * 2, CLEAR * 2)
	p.CFrame = part.CFrame
	p.Parent = fixture
	local hits = Workspace:GetPartsInPart(p, params)
	p:Destroy()
	return hits
end

local function boxOf(parts)
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, part in ipairs(parts) do
		for _, c in ipairs(cornersOf(part)) do
			lo = Vector3.new(math.min(lo.X, c.X), math.min(lo.Y, c.Y), math.min(lo.Z, c.Z))
			hi = Vector3.new(math.max(hi.X, c.X), math.max(hi.Y, c.Y), math.max(hi.Z, c.Z))
		end
	end
	return lo, hi
end
local function boxesMeet(alo, ahi, blo, bhi, pad)
	return alo.X <= bhi.X + pad and ahi.X >= blo.X - pad and alo.Y <= bhi.Y + pad and ahi.Y >= blo.Y - pad
		and alo.Z <= bhi.Z + pad and ahi.Z >= blo.Z - pad
end

-- Every { part, hit } between a model's visible or colliding parts (below LOW
-- only if `lowOnly`) and `against`; parts nowhere near any target's own box
-- are skipped before they are asked.
local function overlapsOf(model, against, lowOnly)
	local targets = {}
	for _, a in ipairs(against) do
		if a:IsA("BasePart") then
			table.insert(targets, a)
		end
		for _, p in ipairs(partsOf(a)) do
			table.insert(targets, p)
		end
	end
	if #targets == 0 then
		return {}
	end
	local boxes = {}
	for _, t in ipairs(targets) do
		local lo, hi = boxOf({ t })
		table.insert(boxes, { lo, hi })
	end
	local found = {}
	for _, part in ipairs(partsOf(model)) do
		if part.Transparency < 1 or part.CanCollide then
			local plo, phi = boxOf({ part })
			if not lowOnly or plo.Y < MAP.GroundY + LOW then
				local near = false
				for _, b in ipairs(boxes) do
					if boxesMeet(plo, phi, b[1], b[2], CLEAR + 0.1) then
						near = true
						break
					end
				end
				if near then
					for _, hit in ipairs(touches(part, against)) do
						table.insert(found, { part = part, hit = hit })
					end
				end
			end
		end
	end
	return found
end
local function describe(list, limit)
	local seen, names = {}, {}
	for _, o in ipairs(list) do
		local s = string.format("%s x %s", o.part.Name, o.hit.Name)
		if not seen[s] then
			seen[s] = true
			table.insert(names, s)
		end
	end
	table.sort(names)
	return table.concat(names, ", ", 1, math.min(#names, limit or 4))
end

-- How far a world point stands inside the road's empty arc: degrees and studs
-- (<= 0 outside), polar about the hub with the road at -Z.
local function intoArc(w)
	local a = math.atan2(w.X, w.Z) % (math.pi * 2)
	local deg = math.deg(gap * 0.5 - math.abs(a - math.pi))
	return deg, math.rad(deg) * Vector3.new(w.X, 0, w.Z).Magnitude
end

-- The plot-frame region a level's plot walks in, rebuilt from GameConfig alone
-- (the wing's back is the back fence itself wherever it reaches it, as
-- MapService stamps it).
local function regionAt(level, id)
	local depth = GameConfig.plotDepthForPlot(level, id)
	local front, back = GameConfig.plotWingZ(level, id)
	local wingBack = if back and back < depth * 0.5 - 1e-6 then back else depth * 0.5
	return PlantWander.RegionOf(depth, if front then PLOT.SideBed.WingWidth else 0, front or 0, wingBack)
end

local ok, err = pcall(function()
	--==========================================================================
	say("\n-- 1. the ladder on every plot --")
	--==========================================================================
	local capBad, depthBad, attrBad = {}, {}, {}
	local room = {}
	local wantDepth = {
		Front = { [5] = 96.2, [6] = 96.2, [7] = 108.4 },
		Beside = { [5] = 96.2, [6] = 120.6, [7] = 145.0 },
	}
	for id = 1, n do
		local layout = GameConfig.plotLayoutFor(id)
		room[id] = {}
		for level = 5, LEVELS do
			local plot = newPlot(id, level)
			local cap = plot:GetAttribute("Capacity")
			if cap ~= T[level].capacity or cap ~= ({ [5] = 20, [6] = 25, [7] = 30 })[level] then
				table.insert(capBad, string.format("plot %d L%d %s", id, level, tostring(cap)))
			end
			local depth = plot:GetAttribute("Depth")
			if math.abs(depth - wantDepth[layout][level]) > 1e-6
				or math.abs(depth - GameConfig.plotDepthForPlot(level, id)) > 1e-9 then
				table.insert(depthBad, string.format("plot %d L%d %.2f", id, level, depth))
			end
			if plot:GetAttribute("Level") ~= level or plot:GetAttribute("Rows") ~= GameConfig.plotRowsFor(level, id) then
				table.insert(attrBad, string.format("plot %d L%d", id, level))
			end
			-- Room: soil from the real beds, fenced ground from the footprint.
			local soil = 0
			for _, part in ipairs(plot:GetChildren()) do
				if part:IsA("BasePart") and CollectionService:HasTag(part, GameConfig.Tags.Planter) then
					soil += part.Size.X * part.Size.Z
				end
			end
			local fenced = 0
			for _, r in ipairs(GameConfig.plotFootprint(level, id)) do
				fenced += (r.x1 - r.x0) * (r.d1 - r.d0)
			end
			room[id][level] = { soil = soil, fenced = fenced }
			plot:Destroy()
		end
	end
	check(#capBad == 0, "every plot, plot 6 included, holds 20 at Level 5, 25 at Level 6 and 30 at Level 7 (its stamped "
		.. "Capacity, which PlantService enforces)", table.concat(capBad, ", "))
	check(#depthBad == 0, "plots 1-5 are 96.2 / 96.2 / 108.4 deep at Levels 5-7 (the wing grows forward at 6); plot 6 "
		.. "96.2 / 120.6 / 145.0", table.concat(depthBad, ", "))
	check(#attrBad == 0, "and each says its own Level and Rows", table.concat(attrBad, ", "))
	check(T[6].cost == 250000000 and T[7].cost == 2500000000 and GameConfig.compact(T[6].cost) == "250M"
			and GameConfig.compact(T[7].cost) == "2.5B",
		"Level 6 costs 250,000,000 and Level 7 2,500,000,000 -- \"$250M\" and \"$2.5B\" on the board")
	local roomBad = {}
	for level = 6, LEVELS do
		local least = { soil = math.huge, fenced = math.huge }
		for id = 1, n - 1 do
			least.soil = math.min(least.soil, room[id][level].soil)
			least.fenced = math.min(least.fenced, room[id][level].fenced)
		end
		local six = room[n][level]
		if six.soil < least.soil - 1e-6 or six.fenced < least.fenced - 1e-6 then
			table.insert(roomBad, string.format("L%d plot 6 %.0f/%.0f vs %.0f/%.0f", level, six.fenced, six.soil,
				least.fenced, least.soil))
		end
		say(string.format("  (L%d room, fenced / soil: plots 1-5 %.0f / %.0f, plot 6 %.0f / %.0f square studs)", level,
			room[1][level].fenced, room[1][level].soil, six.fenced, six.soil))
	end
	check(#roomBad == 0, "no plot is worse to own: plot 6 has no less fenced ground and no less soil than plots 1-5 "
		.. "at Levels 6 and 7", table.concat(roomBad, " | "))

	--==========================================================================
	say("\n-- 2. clearances, all six plots at every level --")
	--==========================================================================
	-- The walks: every plot's walk from the hub to its gate and the road's,
	-- below LOW; the deck's rim ring; the Disco Mill's circle.
	local zones = Instance.new("Folder")
	zones.Name = "SpecZones"
	zones.Parent = fixture
	local function zone(name, size, cf)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = size
		p.CFrame = cf
		p.Parent = zones
		return p
	end
	local walkOf = {}
	local road
	for _, c in ipairs(DANCERS.Corridors) do
		local a = Vector3.new(c.From.X, MAP.GroundY + LOW * 0.5, c.From.Z)
		local b = Vector3.new(c.To.X, MAP.GroundY + LOW * 0.5, c.To.Z)
		local id = tonumber(string.match(c.Name, "^Plot_(%d+)$"))
		if id or c.Name == "Road" then
			local z = zone("Walk" .. c.Name, Vector3.new(c.HalfWidth * 2, LOW, (b - a).Magnitude),
				CFrame.lookAt((a + b) * 0.5, b))
			if id then
				walkOf[id] = z
			else
				road = z
			end
		end
	end
	local rim, disco
	for _, k in ipairs(DANCERS.KeepClear) do
		if k.Name == "RimInside" then
			rim = k.Ring[2]
		elseif k.Name == "DiscoMill" then
			disco = k
		end
	end
	-- The night shutter across the road's mouth (MapService.buildNightBarrier).
	local B = GameConfig.WorldCycle.Barrier
	local shutterH = MAP.WallHeight + B.HeightPad
	local shutter = zone("NightShutter", Vector3.new(MAP.CorridorWidth + B.WidthPad, shutterH, B.Thickness),
		CFrame.new(0, MAP.GroundY + shutterH * 0.5, -MAP.FieldFront + B.Thickness * 0.5))
	-- The rain biome's ramp, its entrance curtain and the evacuees' landing on
	-- the grass before it (GameConfig.Weather.Biome); the obby's entrance
	-- (MiniEventService's 14-stud circle at ObbyData.Entrance).
	local R = GameConfig.Weather.Biome
	local ramp = zone("RainRamp", Vector3.new(R.Ramp.X1 - R.Ramp.X0, R.Deck.Y + 2, R.Deck.Width),
		CFrame.new((R.Ramp.X0 + R.Ramp.X1) * 0.5, MAP.GroundY + (R.Deck.Y + 2) * 0.5, R.Deck.Z))
	local curtain = zone("RainCurtain", Vector3.new(1, R.Gate.Height, R.Gate.Width),
		CFrame.new(R.Gate.X, MAP.GroundY + R.Gate.Height * 0.5, R.Deck.Z))
	local L = R.Landing
	local landing = zone("RainLanding", Vector3.new(L.Rows * L.Spread + 6, LOW, L.Columns * L.Spread + 6),
		CFrame.new(L.X, MAP.GroundY + LOW * 0.5, L.Z))
	local obbyAt = ObbyData.Entrance.At

	-- Every plot's boards, built once off its gate, as MapService builds them
	-- (the stats sign is the client's: a stand-in of its size, MillPlacementSpec's).
	local boards = Instance.new("Folder")
	boards.Name = "SpecBoards"
	boards.Parent = fixture
	local prompts = {}
	for id = 1, n do
		local sign = MillModel.BuildSign(GameConfig.plotSignBase(centres[id], GameConfig.StartingPlotTier), boards)
		sign.Name = "PlotSign" .. id
		PlotShowcase.build(GameConfig.plotShowcaseBase(centres[id], GameConfig.StartingPlotTier), boards).Name =
			"PlotShowcase" .. id
		local stats = Instance.new("Part")
		stats.Name = "StatsSign" .. id
		stats.Anchored = true
		stats.CanCollide = false
		stats.Size = Vector3.new(5.6, 5.9, 0.6)
		stats.CFrame = gateOf(id) * CFrame.new(11.12, 2.95, -1.6)
		stats.Parent = boards
		local prompt = sign:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			table.insert(prompts, { name = "plot " .. id .. "'s upgrade board", at = prompt.Parent.Position })
		end
		-- Every mill tier's sign prompt, where TreadmillService puts it.
		local millCF = GameConfig.millCFrameFor(gateOf(id), id)
		local beside = GameConfig.millStandsBeside(id)
		for tier = 1, #MILL.Tiers do
			local s = MillModel.BuildSign(MillModel.SignBase(millCF, tier, beside), fixture)
			local p = s:FindFirstChildWhichIsA("ProximityPrompt", true)
			if p then
				table.insert(prompts, { name = string.format("plot %d's T%d mill sign", id, tier), at = p.Parent.Position })
			end
			s:Destroy()
		end
	end

	local walkBad, roadBad, fieldBad, boardBad, othersBad = {}, {}, {}, {}, {}
	local arcByLevel, discoByLevel = {}, {}
	local fieldLeast, obbyLeast, rimLeast = math.huge, math.huge, math.huge
	local neighbourBad = {}
	local promptBad, promptLeast, promptAt = {}, math.huge, ""
	local built = {}
	for level = 1, LEVELS do
		arcByLevel[level], discoByLevel[level] = {}, {}
		local plots = {}
		for id = 1, n do
			plots[id] = newPlot(id, level)
		end
		for id = 1, n do
			local plot = plots[id]
			-- Other plots' walks and the road's.
			local others = {}
			for other, z in pairs(walkOf) do
				if other ~= id then
					table.insert(others, z)
				end
			end
			for _, o in ipairs(overlapsOf(plot, others, true)) do
				table.insert(walkBad, string.format("plot %d L%d %s x %s", id, level, o.part.Name, o.hit.Name))
			end
			for _, o in ipairs(overlapsOf(plot, { road }, true)) do
				table.insert(roadBad, string.format("plot %d L%d %s", id, level, o.part.Name))
			end
			-- Its boards and everybody else's; the shutter and the rain biome.
			local hits = overlapsOf(plot, { boards })
			if #hits > 0 then
				table.insert(boardBad, string.format("plot %d L%d: %s", id, level, describe(hits, 3)))
			end
			local more = overlapsOf(plot, { shutter, ramp, curtain, landing })
			if #more > 0 then
				table.insert(othersBad, string.format("plot %d L%d: %s", id, level, describe(more, 3)))
			end
			-- Corner sweeps: the arc, the Disco Mill, the rim, the field, the obby.
			local arcDeg, arcStuds, discoIn = 0, 0, -math.huge
			for _, part in ipairs(partsOf(plot)) do
				if part.Transparency < 1 or part.CanCollide then
					for _, w in ipairs(cornersOf(part)) do
						local flat = Vector3.new(w.X, 0, w.Z)
						if w.Y - MAP.GroundY < LOW then
							local deg, studs = intoArc(w)
							if deg > arcDeg then
								arcDeg, arcStuds = deg, studs
							end
							discoIn = math.max(discoIn,
								disco.Radius - (flat - Vector3.new(disco.At.X, 0, disco.At.Z)).Magnitude)
							rimLeast = math.min(rimLeast, flat.Magnitude - rim)
							obbyLeast = math.min(obbyLeast, (flat - Vector3.new(obbyAt.X, 0, obbyAt.Z)).Magnitude - 14)
						end
						local margin = math.min(MAP.FieldWidth * 0.5 - math.abs(w.X), w.Z + MAP.FieldFront,
							MAP.FieldBack - w.Z)
						fieldLeast = math.min(fieldLeast, margin)
						if margin < 5 then
							table.insert(fieldBad, string.format("plot %d L%d %.1f", id, level, margin))
						end
					end
				end
			end
			arcByLevel[level][id] = { deg = arcDeg, studs = arcStuds }
			discoByLevel[level][id] = discoIn
			-- Fixed prompts: none inside this plot's fence at this level; and how
			-- near any comes to the ground Levels 6-7 add -- plots 1-5's wing,
			-- plot 6's depth past Level 5's back fence.
			local gate = gateOf(id)
			local prints = GameConfig.plotFootprint(level, id)
			local newGround = {}
			if level >= 6 then
				if GameConfig.plotLayoutFor(id) == "Front" then
					newGround = { prints[2] }
				else
					local l5 = GameConfig.plotDepthForPlot(5, id)
					newGround = { { x0 = prints[1].x0, x1 = prints[1].x1, d0 = l5, d1 = prints[1].d1 } }
				end
			end
			local function gapTo(r, lp)
				local dx = math.max(r.x0 - 0.8 - lp.X, 0, lp.X - r.x1 - 0.8)
				local dz = math.max(r.d0 - 0.8 - lp.Z, 0, lp.Z - r.d1 - 0.8)
				return math.sqrt(dx * dx + dz * dz)
			end
			for _, pr in ipairs(prompts) do
				local lp = gate:PointToObjectSpace(pr.at)
				for _, r in ipairs(prints) do
					if gapTo(r, lp) < CLEAR then
						table.insert(promptBad, string.format("%s inside plot %d L%d", pr.name, id, level))
					end
				end
				for _, r in ipairs(newGround) do
					local d = gapTo(r, lp)
					if d < promptLeast then
						promptLeast, promptAt = d, string.format("%s, plot %d L%d", pr.name, id, level)
					end
				end
			end
		end
		-- Neighbours at the same level, in 3-D.
		for id = 1, n do
			local others = {}
			for _, other in ipairs({ id - 1, id + 1 }) do
				if plots[other] then
					table.insert(others, plots[other])
				end
			end
			local found = overlapsOf(plots[id], others)
			if #found > 0 then
				table.insert(neighbourBad, string.format("plot %d L%d: %s", id, level, describe(found, 3)))
			end
		end
		if level == 1 or level == LEVELS then
			built[level] = plots
		else
			for _, p in pairs(plots) do
				p:Destroy()
			end
		end
	end
	-- The top against the bottom, both ways, in 3-D.
	for id = 1, n do
		for _, other in ipairs({ id - 1, id + 1 }) do
			if other >= 1 and other <= n then
				for _, pair in ipairs({ { LEVELS, 1 }, { 1, LEVELS } }) do
					local found = overlapsOf(built[pair[1]][id], { built[pair[2]][other] })
					if #found > 0 then
						table.insert(neighbourBad, string.format("plot %d L%d x plot %d L%d: %s", id, pair[1], other,
							pair[2], describe(found, 3)))
					end
				end
			end
		end
	end
	-- And every pair of levels by footprint: the gap between a plot's fence and
	-- each neighbour's, fence boards included.
	local footLeast, footAt = math.huge, ""
	local function worldRects(id, level)
		local list = {}
		for _, r in ipairs(GameConfig.plotFootprint(level, id)) do
			local cs = {}
			for _, c in ipairs({ { r.x0 - 0.8, r.d0 - 0.8 }, { r.x1 + 0.8, r.d0 - 0.8 }, { r.x1 + 0.8, r.d1 + 0.8 },
				{ r.x0 - 0.8, r.d1 + 0.8 } }) do
				local w = (gateOf(id) * CFrame.new(c[1], 0, c[2])).Position
				table.insert(cs, Vector2.new(w.X, w.Z))
			end
			table.insert(list, cs)
		end
		return list
	end
	local function segDist(p, a, b)
		local ab = b - a
		local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
		return (p - (a + ab * t)).Magnitude
	end
	local function polyGap(p, q)
		local best = math.huge
		for _, pair in ipairs({ { p, q }, { q, p } }) do
			for _, v in ipairs(pair[1]) do
				for i = 1, 4 do
					best = math.min(best, segDist(v, pair[2][i], pair[2][i % 4 + 1]))
				end
			end
		end
		return best
	end
	for id = 1, n - 1 do
		for la = 1, LEVELS do
			for lb = 1, LEVELS do
				for _, pa in ipairs(worldRects(id, la)) do
					for _, pb in ipairs(worldRects(id + 1, lb)) do
						local g = polyGap(pa, pb)
						if g < footLeast then
							footLeast, footAt = g, string.format("plots %d L%d / %d L%d", id, la, id + 1, lb)
						end
					end
				end
			end
		end
	end
	check(#walkBad == 0, "below 8 studs, no plot at any level stands in another plot's walk from the hub to its gate",
		table.concat(walkBad, " | ", 1, math.min(#walkBad, 4)))
	check(#roadBad == 0, "nor in the road's corridor", table.concat(roadBad, " | ", 1, math.min(#roadBad, 4)))
	check(rimLeast > 0, string.format("nor anywhere near the deck's rim (%.0f): %.1f studs outside it at the closest", rim,
		rimLeast))
	check(#neighbourBad == 0, "no plot comes within 0.25 of a neighbour or its wing -- every level against the same "
		.. "level, and the top against the bottom both ways, in 3-D", table.concat(neighbourBad, " | ", 1,
		math.min(#neighbourBad, 4)))
	check(footLeast >= 10, string.format("and at every pair of levels the fences stand %.1f studs apart at the closest "
		.. "(%s)", footLeast, footAt))
	check(#fieldBad == 0, string.format("every plot at every level stands on the field, %.1f studs inside its edge at "
		.. "the closest", fieldLeast), table.concat(fieldBad, ", ", 1, math.min(#fieldBad, 4)))
	check(#boardBad == 0, "no plot at any level comes within 0.25 of any plot's upgrade board, TOP CREATURES board or "
		.. "stats sign", table.concat(boardBad, " | ", 1, math.min(#boardBad, 4)))
	check(#othersBad == 0 and obbyLeast > 0,
		string.format("nor of the night shutter, the rain biome's ramp, curtain and landing, or the obby's entrance "
			.. "(%.1f clear)", obbyLeast), table.concat(othersBad, " | ", 1, math.min(#othersBad, 4)))
	check(#promptBad == 0 and promptLeast > 10, string.format("no fixed prompt -- a plot's upgrade board, any tier's mill "
		.. "sign -- stands in any plot's fence at any level, and the ground Levels 6-7 add is %.1f studs from the "
		.. "nearest (%s)", promptLeast, promptAt), table.concat(promptBad, " | ", 1, math.min(#promptBad, 4)))
	-- The arc and the Disco Mill: pinned against what Levels 1-5 already did.
	local arcBad, arcLine = {}, {}
	for id = 1, n do
		local l5 = arcByLevel[5][id]
		for level = 6, LEVELS do
			local a = arcByLevel[level][id]
			if a.studs > math.max(l5.studs, 0) + 1e-3 then
				table.insert(arcBad, string.format("plot %d L%d %.2f vs L5 %.2f", id, level, a.studs, l5.studs))
			end
		end
		if id ~= n then
			for level = 1, LEVELS do
				if arcByLevel[level][id].deg > 0 then
					table.insert(arcBad, string.format("plot %d L%d %.2f deg", id, level, arcByLevel[level][id].deg))
				end
			end
		end
	end
	for level = 1, LEVELS do
		table.insert(arcLine, string.format("L%d %.2f", level, math.max(arcByLevel[level][n].studs, 0)))
	end
	check(#arcBad == 0, "no plot reaches into the road's empty arc at Levels 6-7 further than it did at Level 5; "
		.. "plots 1-5 never do", table.concat(arcBad, " | "))
	say("  (plot 6's wing in the arc, studs, by level: " .. table.concat(arcLine, ", ")
		.. " -- Levels 3-5 as they always were; Levels 6-7 are Level 5's wing)")
	local discoBad = {}
	for id = 1, n do
		for level = 2, LEVELS do
			if discoByLevel[level][id] > math.max(discoByLevel[1][id], 0) + 1e-3 then
				table.insert(discoBad, string.format("plot %d L%d %.2f", id, level, discoByLevel[level][id]))
			end
		end
	end
	check(#discoBad == 0, "nor into the Disco Mill's circle further than at Level 1", table.concat(discoBad, ", "))
	say(string.format("  (plot 1's front-left fence corner stands %.2f inside the Disco Mill's 35-stud keep-clear "
		.. "circle at every level -- as at Level 1: the gate never moves)", discoByLevel[1][1]))
	for _, level in ipairs({ 1, LEVELS }) do
		for _, p in pairs(built[level]) do
			p:Destroy()
		end
	end

	--==========================================================================
	say("\n-- 3. the field's scatter --")
	--==========================================================================
	-- Dressed twice: around the real ring (a SeedMap-shaped folder with the
	-- six plots, as MapService.Init calls it) and with no plots at all. What
	-- the ring keeps must be exactly what the bare field rolled, every part,
	-- and nothing of it may stand on any plot at any level.
	local mapF = Instance.new("Folder")
	mapF.Name = "SpecMap"
	mapF.Parent = fixture
	local plotsF = Instance.new("Folder")
	plotsF.Name = MAP.PlotsFolderName
	plotsF.Parent = mapF
	for id = 1, n do
		newPlot(id, GameConfig.StartingPlotTier, plotsF)
	end
	local propsF = Instance.new("Folder")
	propsF.Name = MAP.PropsFolderName
	propsF.Parent = mapF
	MapDecor.dressField(propsF)
	local bareHolder = Instance.new("Folder")
	bareHolder.Name = "SpecBareField"
	bareHolder.Parent = fixture
	MapDecor.dressField(bareHolder)
	local function signature(prop)
		local lines = {}
		local list = if prop:IsA("BasePart") then { prop } else partsOf(prop)
		for _, p in ipairs(list) do
			local c = { p.CFrame:GetComponents() }
			for i, v in ipairs(c) do
				c[i] = string.format("%.3f", v)
			end
			table.insert(lines, p.Name .. "|" .. table.concat(c, ",") .. "|" .. string.format("%.3f,%.3f,%.3f", p.Size.X,
				p.Size.Y, p.Size.Z))
		end
		table.sort(lines)
		return prop.Name .. "#" .. table.concat(lines, ";")
	end
	local bare = {}
	for _, prop in ipairs(bareHolder.FieldDecor:GetChildren()) do
		bare[signature(prop)] = prop
	end
	local kept, extra = 0, 0
	local keptSet = {}
	for _, prop in ipairs(propsF.FieldDecor:GetChildren()) do
		local s = signature(prop)
		if bare[s] then
			kept += 1
			keptSet[s] = true
		else
			extra += 1
		end
	end
	local removed = {}
	for s, prop in pairs(bare) do
		if not keptSet[s] then
			local at = if prop:IsA("Model") then prop:GetPivot().Position else prop.Position
			table.insert(removed, string.format("%s (%.0f, %.0f)", prop.Name, at.X, at.Z))
		end
	end
	table.sort(removed)
	check(extra == 0 and kept + #removed == #bareHolder.FieldDecor:GetChildren(),
		string.format("around the ring the field keeps %d of its %d props exactly as rolled -- nothing re-rolled, nothing "
			.. "moved -- and leaves out %d", kept, #bareHolder.FieldDecor:GetChildren(), #removed), extra)
	say("  (left out where a plot will stand: " .. (if #removed > 0 then table.concat(removed, ", ") else "none") .. ")")
	-- Independent of MapDecor's own test: every kept part's corners, in every
	-- plot's gate frame, against every level's footprint and its fence boards.
	local onPlot = {}
	for _, prop in ipairs(propsF.FieldDecor:GetChildren()) do
		local list = if prop:IsA("BasePart") then { prop } else partsOf(prop)
		for _, part in ipairs(list) do
			for id = 1, n do
				local x0, x1, d0, d1 = math.huge, -math.huge, math.huge, -math.huge
				for _, w in ipairs(cornersOf(part)) do
					local lp = gateOf(id):PointToObjectSpace(w)
					x0, x1 = math.min(x0, lp.X), math.max(x1, lp.X)
					d0, d1 = math.min(d0, lp.Z), math.max(d1, lp.Z)
				end
				for level = 1, LEVELS do
					for _, r in ipairs(GameConfig.plotFootprint(level, id)) do
						if x1 >= r.x0 - 0.8 and x0 <= r.x1 + 0.8 and d1 >= r.d0 - 0.8 and d0 <= r.d1 + 0.8 then
							table.insert(onPlot, string.format("%s %s on plot %d L%d", prop.Name, part.Name, id, level))
						end
					end
				end
			end
		end
	end
	check(#onPlot == 0, "and no part of any kept prop stands on any plot's ground, at any level",
		table.concat(onPlot, " | ", 1, math.min(#onPlot, 4)))
	mapF:Destroy()
	bareHolder:Destroy()

	--==========================================================================
	say("\n-- 4. saves --")
	--==========================================================================
	-- A LEVEL 5 GARDEN COMES BACK BIT FOR BIT: below Level 6, and on plots 1-5
	-- at every level, a saved X/Z IS the live offset -- the very Vector3 -- and
	-- the region it is clamped into is the one built from the level's numbers.
	local identityBad = {}
	local rng = Random.new(20261007)
	for id = 1, n do
		for level = 1, LEVELS do
			if level <= 5 or GameConfig.plotLayoutFor(id) == "Front" then
				for _ = 1, 200 do
					local v = Vector3.new(rng:NextNumber(-80, 120), 0, rng:NextNumber(-90, 90))
					if not rawequal(GardenFrame.FromSaved(level, id, v), v)
						or not rawequal(GardenFrame.ToSaved(level, id, v), v) then
						table.insert(identityBad, string.format("plot %d L%d", id, level))
						break
					end
				end
			end
		end
	end
	check(#identityBad == 0, "a Level 1-5 garden, on any plot, and plots 1-5's at every level: saved X/Z are the live "
		.. "offset itself, both ways -- nothing converts", table.concat(identityBad, ", "))
	local l5Bad = {}
	local function sameBox(p, q)
		if p == nil or q == nil then
			return p == q
		end
		return p.x0 == q.x0 and p.x1 == q.x1 and p.z0 == q.z0 and p.z1 == q.z1
	end
	for id = 1, n do
		local plot = newPlot(id, 5)
		local built5 = PlantWander.RegionFor(plot)
		local want = regionAt(5, id)
		if not (sameBox(built5.main, want.main) and sameBox(built5.wing, want.wing) and sameBox(built5.gate, want.gate)) then
			table.insert(l5Bad, "plot " .. id)
		end
		-- Level 5's own numbers, as they stood before Levels 6-7: 96.2 deep, the
		-- wing from 37.6 behind the gate to the back fence.
		if math.abs(plot:GetAttribute("Depth") - 96.2) > 1e-9 or math.abs(plot:GetAttribute("WingFrontZ") + 10.5) > 1e-9
			or plot:GetAttribute("WingBackZ") ~= plot:GetAttribute("Depth") * 0.5 then
			table.insert(l5Bad, "plot " .. id .. " numbers")
		end
		plot:Destroy()
	end
	check(#l5Bad == 0, "every plot's Level 5 is 96.2 deep with its wing 37.6 behind the gate to the back fence, and "
		.. "walks the region those numbers make -- the one a Level 5 garden has always been clamped into",
		table.concat(l5Bad, ", "))

	-- A LEVEL 7 GARDEN SAVES AND RELOADS, ON EVERY PLOT: thirty things at legal
	-- spots -- pods on soil, creatures anywhere they may walk -- written as
	-- PlantService.record writes them, through ProfileSchema as a load does,
	-- and read as PlantService.restore reads them.
	local function gardenOn(plot, count, seed)
		local r = Random.new(seed)
		local region = PlantWander.RegionFor(plot)
		local main = plot:FindFirstChild(PLOT.PlanterName)
		local beds = {}
		for _, part in ipairs(plot:GetChildren()) do
			if part:IsA("BasePart") and CollectionService:HasTag(part, GameConfig.Tags.Planter) then
				table.insert(beds, part)
			end
		end
		local list = {}
		for i = 1, count do
			local offset
			if i % 2 == 1 then
				-- A pod, on a bed, EdgeMargin inside its rim, in the main soil's frame.
				local bed = beds[r:NextInteger(1, #beds)]
				local m = GameConfig.Plant.EdgeMarginStuds
				local local_ = Vector3.new(r:NextNumber(-bed.Size.X * 0.5 + m, bed.Size.X * 0.5 - m), 0,
					r:NextNumber(-bed.Size.Z * 0.5 + m, bed.Size.Z * 0.5 - m))
				local here = main.CFrame:PointToObjectSpace(bed.CFrame:PointToWorldSpace(local_))
				offset = Vector3.new(here.X, 0, here.Z)
			else
				repeat
					offset = Vector3.new(r:NextNumber(-30, 70), 0, r:NextNumber(-80, 80))
				until PlantWander.Inside(region, offset)
			end
			table.insert(list, { offset = offset, pod = i % 2 == 1 })
		end
		return list
	end
	local function saveRows(list, level, id)
		local rows = {}
		for i, p in ipairs(list) do
			local saved = GardenFrame.ToSaved(level, id, p.offset)
			table.insert(rows, { SpeciesId = SPECIES, Tier = 1, PlantedAt = 1000 + i, HatchAt = 2000 + i,
				X = saved.X, Z = saved.Z, Stage = if p.pod then 1 else 3, Facing = 0 })
		end
		return rows
	end
	local function loadOffsets(rows, plot, level, id)
		local profile = ProfileSchema.Sanitise({ Version = 2, PlotTier = level, Plants = rows })
		local region = PlantWander.RegionFor(plot)
		local list = {}
		for _, row in ipairs(profile.Plants) do
			local live = GardenFrame.FromSaved(level, id, Vector3.new(row.X, 0, row.Z))
			table.insert(list, PlantWander.Clamp(region, Vector3.new(live.X, 0, live.Z)))
		end
		return list, profile
	end
	local function asGarden(offsets, like)
		local l = {}
		for i, p in ipairs(offsets) do
			l[i] = { offset = p, pod = like[i].pod }
		end
		return l
	end
	local l7Bad = {}
	for id = 1, n do
		local plot = newPlot(id, LEVELS)
		local garden = gardenOn(plot, 30, id * 97)
		local rows = saveRows(garden, LEVELS, id)
		local back, profile = loadOffsets(rows, plot, LEVELS, id)
		local worst = 0
		for i, p in ipairs(garden) do
			worst = math.max(worst, ((back[i] or Vector3.new(1e9, 0, 0)) - p.offset).Magnitude)
		end
		if profile.PlotTier ~= LEVELS or #profile.Plants ~= 30 or worst > 1e-3 then
			table.insert(l7Bad, string.format("plot %d: L%d, %d plants, moved %.4f", id, profile.PlotTier, #profile.Plants,
				worst))
		end
		plot:Destroy()
	end
	check(#l7Bad == 0, "a full Level 7 garden of thirty saves and reloads on every plot, plot 6 included: Level 7 kept, "
		.. "every plant kept, every one where it stood", table.concat(l7Bad, " | "))

	-- MOVED BETWEEN THE TWO SHAPES (a player is given whichever plot is free):
	-- a garden from plots 1-5 on plot 6 and back, and plot 6's on plots 1-5 and
	-- back. Every plant lands on its owner's ground, and the trip there and back
	-- puts it where it was, give or take the fence margin.
	local moveBad, podsOff, podsTotal, maxShift = {}, 0, 0, 0
	for _, level in ipairs({ 6, 7 }) do
		local front = newPlot(3, level)
		local six = newPlot(6, level)
		local sixSoil = {}
		for _, part in ipairs(six:GetChildren()) do
			if part:IsA("BasePart") and CollectionService:HasTag(part, GameConfig.Tags.Planter) then
				table.insert(sixSoil, part)
			end
		end
		local sixMain = six:FindFirstChild(PLOT.PlanterName)
		local function onSoil(offset)
			local w = sixMain.CFrame:PointToWorldSpace(offset)
			for _, bed in ipairs(sixSoil) do
				local lp = bed.CFrame:PointToObjectSpace(w)
				if math.abs(lp.X) <= bed.Size.X * 0.5 + 1e-3 and math.abs(lp.Z) <= bed.Size.Z * 0.5 + 1e-3 then
					return true
				end
			end
			return false
		end
		local frontRegion = PlantWander.RegionFor(front)
		local sixRegion = PlantWander.RegionFor(six)
		for trial = 1, 6 do
			-- Plots 1-5's garden onto plot 6, and home again.
			local garden = gardenOn(front, 30, level * 1000 + trial)
			local onSix = loadOffsets(saveRows(garden, level, 3), six, level, 6)
			for i, p in ipairs(onSix) do
				if not PlantWander.Inside(sixRegion, p) then
					table.insert(moveBad, string.format("L%d plot 3 -> 6: %s outside", level, tostring(p)))
				end
				if garden[i].pod then
					podsTotal += 1
					if not onSoil(p) then
						podsOff += 1
					end
				end
			end
			local home = loadOffsets(saveRows(asGarden(onSix, garden), level, 6), front, level, 3)
			for i, p in ipairs(garden) do
				local shift = (home[i] - p.offset).Magnitude
				maxShift = math.max(maxShift, shift)
				if shift > 2 * M + 1e-3 then
					table.insert(moveBad, string.format("L%d plot 3 -> 6 -> 3: moved %.2f", level, shift))
				end
			end
			-- Plot 6's garden onto a Front plot, and home again.
			local g6 = gardenOn(six, 30, level * 2000 + trial)
			local onFront = loadOffsets(saveRows(g6, level, 6), front, level, 3)
			for _, p in ipairs(onFront) do
				if not PlantWander.Inside(frontRegion, p) then
					table.insert(moveBad, string.format("L%d plot 6 -> 3: %s outside", level, tostring(p)))
				end
			end
			local home6 = loadOffsets(saveRows(asGarden(onFront, g6), level, 3), six, level, 6)
			for i, p in ipairs(g6) do
				local lp = p.offset
				-- The 4-stud strips down each side of plot 6's extra depth have no
				-- twin on a Front plot; anything there comes home at the wing's edge.
				local d = lp.Z + GameConfig.plotDepthForPlot(level, 6) * 0.5
				local strip = d > GameConfig.plotDepthForPlot(level) and math.abs(lp.X) > PLOT.SideBed.WingWidth * 0.5
				if not strip then
					local shift = (home6[i] - lp).Magnitude
					maxShift = math.max(maxShift, shift)
					if shift > 2 * M + 1e-3 then
						table.insert(moveBad, string.format("L%d plot 6 -> 3 -> 6: moved %.2f", level, shift))
					end
				end
			end
		end
		front:Destroy()
		six:Destroy()
	end
	check(#moveBad == 0, string.format("a Level 6-7 garden moved between plot 6 and plots 1-5 lands wholly on its "
		.. "owner's ground and, there and back, comes home within the fence margin (%.2f studs at most)", maxShift),
		table.concat(moveBad, " | ", 1, math.min(#moveBad, 4)))
	check(podsOff <= podsTotal * 0.1, string.format("and pods stay on soil: %d of %d pods from plots 1-5 land off plot "
		.. "6's beds (the seams where its lawn meets the other shape's soil)", podsOff, podsTotal))
	-- Exactly, away from the fences: a Front garden's every point to plot 6 and
	-- back is the same point.
	local exactBad, exactN = 0, 0
	for _, level in ipairs({ 6, 7 }) do
		local frontRegion = regionAt(level, 3)
		local sixRegion = regionAt(level, 6)
		local r = Random.new(level * 7)
		for _ = 1, 4000 do
			local s = Vector3.new(r:NextNumber(-30, 70), 0, r:NextNumber(-80, 80))
			if PlantWander.Inside(frontRegion, s) then
				local live = GardenFrame.FromSaved(level, 6, s)
				if PlantWander.Inside(sixRegion, live) then
					exactN += 1
					local back = GardenFrame.ToSaved(level, 6, live)
					if (back - s).Magnitude > 1e-3 then
						exactBad += 1
					end
				end
			end
		end
	end
	check(exactBad == 0 and exactN > 1000, string.format("every point of a Front garden that lands inside plot 6 comes "
		.. "back to the very same point (%d points)", exactN), exactBad)

	--==========================================================================
	say("\n-- 5. the board --")
	--==========================================================================
	local data: any = PlayerDataService
	local realGet = data.Get
	local tierOf = {}
	data.Get = function(player)
		local t = tierOf[player]
		return if t then { PlotTier = t, Cash = 0 } else nil
	end
	local stand = {}
	for _, t in ipairs({ 4, 5, 6, 7, 9 }) do
		local p = { Name = "Level" .. t }
		tierOf[p] = t
		stand[t] = p
	end
	local okBoard, s4, s5, s6, s7, s9 = pcall(function()
		return PlotUpgradeService.NextStepFor(stand[4]), PlotUpgradeService.NextStepFor(stand[5]),
			PlotUpgradeService.NextStepFor(stand[6]), PlotUpgradeService.NextStepFor(stand[7]),
			PlotUpgradeService.NextStepFor(stand[9])
	end)
	data.Get = realGet
	check(okBoard and s4.kind == "next" and s4.level == 5 and s4.cost == 25000000, "at 4 the board still offers 5 for 25M")
	check(okBoard and s5.kind == "next" and s5.level == 6 and s5.cost == 250000000,
		"at 5 it offers 6 for 250,000,000", okBoard and string.format("%s %d %s", s5.kind, s5.level, tostring(s5.cost)))
	check(okBoard and s6.kind == "next" and s6.level == 7 and s6.cost == 2500000000,
		"at 6 it offers 7 for 2,500,000,000", okBoard and string.format("%s %d %s", s6.kind, s6.level, tostring(s6.cost)))
	check(okBoard and s7.kind == "max" and s7.level == 7 and s9.kind == "max" and s9.level == 7,
		"at 7 it says MAX -- and a level past the ladder reads as 7")
	local upSrc = sourceOf(Server:FindFirstChild("PlotUpgradeService"))
	check(has(upSrc, "if level >= #TIERS then") and has(upSrc, 'string.format("LEVEL %d  >  LEVEL %d", level, step.level)')
			and has(upSrc, 'string.format("%d  >  %d SLOTS",') and has(upSrc, 'else "MAX"')
			and has(upSrc, "prompt.Enabled = sellable"),
		"the board paints from the ladder's length: LEVEL 5 > LEVEL 6, 20 > 25 SLOTS, $250M; at 7, MAX and no prompt")

	--==========================================================================
	say("\n-- 6. everything else that reads a level --")
	--==========================================================================
	local function src(name)
		return sourceOf(Server:FindFirstChild(name))
	end
	local SPS = StarterPlayer:WaitForChild("StarterPlayerScripts")
	local plotSrc, dataSrc, debugSrc = src("PlotService"), src("PlayerDataService"), src("DebugService")
	local schemaSrc, plantSrc, mapSrc = src("ProfileSchema"), src("PlantService"), src("MapService")
	local placeSrc = sourceOf(SPS:FindFirstChild("PlantPlace"))
	local labelsSrc = sourceOf(SPS:FindFirstChild("PlotOwnerLabels"))
	local gardenSrc = sourceOf(SPS:FindFirstChild("GardenUI"))
	local miniSrc = src("MiniEventService")
	check(has(plotSrc, "math.clamp(math.floor(level), 1, #GameConfig.PlotTiers)")
			and has(dataSrc, "math.clamp(math.floor(tier), 1, #GameConfig.PlotTiers)")
			and has(debugSrc, "math.clamp(math.floor(tier), 1, #GameConfig.PlotTiers)")
			and has(schemaSrc, "number(raw.PlotTier, GameConfig.StartingPlotTier, 1, #GameConfig.PlotTiers)")
			and has(schemaSrc, "local MIGRATION_TOP_LEVEL = 5"),
		"a level is clamped to the ladder's length everywhere it is set or loaded (1..7); the v1 migration alone stops at 5")
	check(has(plantSrc, 'tonumber(plot:GetAttribute("Capacity"))') and has(plantSrc, "< #GameConfig.PlotTiers, hasGrown)")
			and has(placeSrc, 'tonumber(plot:GetAttribute("Capacity"))') and has(placeSrc, "level < #GameConfig.PlotTiers")
			and has(labelsSrc, 'tonumber(plot:GetAttribute("Capacity"))') and has(gardenSrc, 'plot:GetAttribute("Capacity")'),
		"capacity is the plot's stamped number for the server, the planting client, the stats plaque and the HUD; "
			.. "\"upgrade to make room\" is offered below 7")
	check(has(labelsSrc, "local gate = (cf :: CFrame) * CFrame.new(0, 0, -(depth :: number) * 0.5)")
			and has(mapSrc, "GameConfig.plotShowcaseBase(cf, GameConfig.StartingPlotTier), plots)")
			and has(mapSrc, "GameConfig.plotSignBase(cf, GameConfig.StartingPlotTier), plots)"),
		"the owner's badge and the stats plaque stand off the plot's own gate (PlotCF and Depth, any depth); the upgrade "
			.. "and TOP CREATURES boards are built once off the gate, which never moves")
	check(has(plantSrc, "GardenFrame.ToSaved(level, plotId, entry.offset)")
			and has(plantSrc, "GardenFrame.FromSaved(level, plotId, Vector3.new(x, 0, z))")
			and has(plantSrc, "offset = clampToPlotRegion(plot, Vector3.new(x, 0, z)),"),
		"PlantService writes a garden through GardenFrame.ToSaved and reads it through FromSaved, then the clamp -- the "
			.. "chain section 4 runs")
	check(has(mapSrc, "local plotId = tonumber(model:GetAttribute(GameConfig.Attributes.PlotId))")
			and has(mapSrc, 'model:SetAttribute("WingBackZ", wingZ1)')
			and has(mapSrc, "local newDepth = GameConfig.plotDepthForPlot(n, plotId)")
			and has(miniSrc, 'plot:GetAttribute("WingBackZ")')
			and has(src("PlantWander"), 'tonumber(plot:GetAttribute("WingBackZ"))'),
		"MapService builds each plot by its id and stamps where its wing ends; the walk and the mini event's \"in a plot\" "
			.. "read it back")
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

fixture:Destroy()
probe:Destroy()

say(string.format("\nPlotLevelsSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
