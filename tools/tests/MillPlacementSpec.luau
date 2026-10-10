--!nocheck
--==============================================================================
-- Steal a Seed :: MillPlacementSpec
--
-- EVERY PLOT'S MILL, AT EVERY TIER AND EVERY LEVEL, CLEAR OF EVERYTHING IT
-- MUST BE
--
-- The owner's report, 2026-09-30: "the mills overlap the plot fences". Measured
-- then: on a Level 3 or 4 plot the side wing's fence ran through the back 4.5
-- studs of every tier, and tier 1's compost bin cut 0.18 into the right fence.
-- The mills moved forward and a stud out.
--
-- 2026-10-06, the owner's choices: plots 1-5's mills stand IN FRONT of their
-- plots (option B of the front placement study: the gate's frame x 37.5, 24.5
-- in front, turned 90 degrees so the console looks along the plot's front at
-- its own walk line), every tier 1-14; plot 6's stays beside its right-hand
-- fence, where tiers 12-14 -- the owner's own mills -- reach past its gate line
-- and into the road's empty arc by the owner's leave, softened
-- (MillModel.Soften). This spec holds all of it, permanently.
--
-- Built for real, in Edit: each plot of the ring grown to each level by
-- MapService.ResizePlot (its own fences, wing, beds and gate), every tier by
-- MillModel.Build at GameConfig.millCFrameFor -- the formula MapService places
-- the real mills with -- its sign by MillModel.BuildSign at MillModel.SignBase,
-- and plot 6's softened as TreadmillService.Rebuild does it. Every part is
-- asked, INFLATED by the clearance, what it touches (Workspace:GetPartsInPart:
-- real shapes, not boxes).
--
--   the placement   by plot, its inverse, and the calls MapService and
--                   TreadmillService make
--   its own plot    0.25 clear of every part of its plot at every level; on
--                   plot 6 the tier-13 parts that touch its fence are exactly
--                   the listed ones (Mill.Place.BesideTouch), softened
--   neighbours      clear of both neighbours' plots, at Level 1 and the top
--   the mills       clear of the next plot's mills, every tier on every tier
--   the boards      clear of every plot's upgrade board, TOP CREATURES board
--                   and stats sign
--   the walk        below 8 studs, clear of every plot's walk from the hub to
--                   its gate, the road corridor, the deck and its rim step and
--                   the Disco Mill's circle -- every plot, plot 6 included --
--                   with the clearances printed
--   the gate line   plots 1-5 wholly in front of their gate lines and out of the
--                   road's empty arc; plot 6 behind its gate line and out of the
--                   arc to tier 11, and tiers 12-14 by exactly the overhang
--                   measured on 2026-10-06, every part of it softened
--   the prompts     every mill sign's clear of every other's, of every plot
--                   board's and of the hub deck's
--   a rebuild       stays put
--
-- Not here: the motion Ambience and MillFormMotion play on each client (decor
-- that never collides; everything here is measured at rest), and Play.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local MillModel = require(Shared:WaitForChild("MillModel"))
local PlotShowcase = require(Shared:WaitForChild("PlotShowcase"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local MapService = require(Server:WaitForChild("MapService"))

local MAP, MILL = GameConfig.Map, GameConfig.Mill
local DANCERS = GameConfig.MiniEvent.Dancers
local CLEAR = 0.25
-- Walk zones block what stands below this many studs above the ground.
local LOW = 8
local TIERS = #MILL.Tiers
local REACH = MILL.Sign.PromptRange

--==============================================================================
-- PLOT 6'S ONE EXCEPTION, MEASURED 2026-10-06 AND PINNED
--
-- How far each tall tier's visible or colliding parts reach past plot 6's gate
-- line, and into the road's empty arc below LOW (studs: the angle inside the
-- arc times the radius). Equal to within TOLERANCE either way, so it can
-- neither grow nor quietly change. (Tier 14's invisible DiskField reaches 7.26;
-- softened with the rest, it is not counted here.) Its sign for those tiers
-- stands SIGN_PAST past the line (Mill.Sign.BesideTallOffset). And what touches
-- plot 6's own fence, by level: tier 13's spire at every level, a snow bank and
-- an ice boulder behind the step in the Level 3-4 wing's front fence
-- (Mill.Place.BesideTouch).
--==============================================================================
local OVERHANG = {
	[12] = { past = 3.90, arc = 1.28 },
	[13] = { past = 3.90, arc = 1.49 },
	[14] = { past = 7.22, arc = 0 },
}
local SIGN_PAST = 4.00
local TOLERANCE = 0.02
-- Levels 6-7 (2026-10-07): plot 6 keeps Level 5's wing and grows deeper, so
-- its fence meets the spire alone, as at Level 5.
local TOUCH = {
	[1] = "Spire", [2] = "Spire", [3] = "IceBoulder,SnowBank,Spire", [4] = "IceBoulder,SnowBank,Spire", [5] = "Spire",
	[6] = "Spire", [7] = "Spire",
}

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

local fixture = Instance.new("Folder")
fixture.Name = "MillPlacementSpecFixture"
fixture.Archivable = false
fixture.Parent = Workspace

--==============================================================================
-- THE RING, AS MapService.Init LAYS IT OUT
--==============================================================================
local n = GameConfig.MaxPlots
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

local function newPlot(id, level)
	local model = Instance.new("Model")
	model.Name = string.format("SpecPlot%02d", id)
	-- Its REAL id: the id decides the plot's shape at Levels 6-7 -- plot 6,
	-- whose mill stands beside it, grows deeper instead of forward
	-- (GameConfig.plotLayoutFor). The model is untagged, so nothing that finds
	-- plots by tag sees it.
	model:SetAttribute(GameConfig.Attributes.PlotId, id)
	model:SetAttribute(GameConfig.Attributes.OwnerUserId, 0)
	model:SetAttribute(GameConfig.Attributes.Claimed, false)
	model:SetAttribute("PlotCF", centres[id])
	model:SetAttribute("Depth", startDepth)
	model:SetAttribute("Level", GameConfig.StartingPlotTier)
	model.Parent = fixture
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

-- Every tier and its sign at a plot's real mill frame, softened where the
-- plot's mill stands beside it -- the calls MapService and TreadmillService.Rebuild
-- make.
local function millsFor(id)
	local gate = gateOf(id)
	local cf = GameConfig.millCFrameFor(gate, id)
	local beside = GameConfig.millStandsBeside(id)
	local mills = {}
	for tier = 1, TIERS do
		local model = MillModel.Build(tier, cf, fixture)
		model.Name = string.format("SpecMill%02d_T%02d", id, tier)
		if beside then
			MillModel.Soften(model, GameConfig.millGateFor(cf, id), tier)
		end
		local sign = MillModel.BuildSign(MillModel.SignBase(cf, tier, beside), model)
		sign.Name = "SpecSign"
		mills[tier] = model
	end
	return mills
end

local function destroyAll(list)
	for _, m in pairs(list) do
		m:Destroy()
	end
end

-- What `part`, grown by CLEAR on every side, touches among `against`.
local probe = Instance.new("Part")
probe.Anchored = true
probe.CanCollide = false
probe.CanTouch = false
probe.Transparency = 1
probe.Name = "SpecProbe"
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

-- The world box of a set of parts, for skipping parts nowhere near them.
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

-- Every { part, hit } between `mill` (its visible or colliding parts; below
-- LOW only if `lowOnly`) and `against`. Parts nowhere near `against` are
-- skipped before they are asked.
local function overlapsOf(mill, against, lowOnly)
	local targets = {}
	for _, a in ipairs(against) do
		for _, p in ipairs(partsOf(a)) do
			table.insert(targets, p)
		end
	end
	local tlo, thi = boxOf(targets)
	local found = {}
	for _, part in ipairs(partsOf(mill)) do
		if part.Transparency < 1 or part.CanCollide then
			local plo, phi = boxOf({ part })
			if (not lowOnly or plo.Y < MAP.GroundY + LOW) and boxesMeet(plo, phi, tlo, thi, CLEAR + 0.1) then
				for _, hit in ipairs(touches(part, against)) do
					table.insert(found, { part = part, hit = hit })
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
	return table.concat(names, ", ", 1, math.min(#names, limit or 6))
end

-- Is `part` one of plot 6's listed fence-touching parts for `tier`?
local function listedTouch(part, tier, millCF)
	for _, t in ipairs(MILL.Place.BesideTouch[tier] or {}) do
		if part.Name == t.Name and (millCF:PointToObjectSpace(part.Position) - t.At).Magnitude < 0.05 then
			return true
		end
	end
	return false
end

-- The road's empty arc: how far a world point stands inside it (degrees; <= 0
-- outside), polar about the hub with the road at -Z.
local function intoArc(w)
	local a = math.atan2(w.X, w.Z) % (math.pi * 2)
	return math.deg(gap * 0.5 - math.abs(a - math.pi))
end

local ok, err = pcall(function()
	--==========================================================================
	say("-- the placement --")
	--==========================================================================
	local formulaOk, roundTrip, besideIds = true, 0, {}
	for id = 1, n do
		local gate = gateOf(id)
		local cf = GameConfig.millCFrameFor(gate, id)
		local P = MILL.Place
		local want = if GameConfig.millStandsBeside(id)
			then gate * CFrame.new(GameConfig.Plot.Width * 0.5 + P.Beside.Side, P.Lift, P.Beside.Behind)
				* CFrame.Angles(0, math.rad(P.Beside.Yaw), 0)
			else gate * CFrame.new(P.Front.Out, P.Lift, -P.Front.Ahead) * CFrame.Angles(0, math.rad(P.Front.Yaw), 0)
		formulaOk = formulaOk and (cf.Position - want.Position).Magnitude < 1e-4
			and (cf.LookVector - want.LookVector).Magnitude < 1e-5
		local back = GameConfig.millGateFor(cf, id)
		roundTrip = math.max(roundTrip, (back.Position - gate.Position).Magnitude, (back.LookVector - gate.LookVector).Magnitude)
		if GameConfig.millStandsBeside(id) then
			table.insert(besideIds, id)
		end
	end
	check(formulaOk and #besideIds == 1 and besideIds[1] == 6,
		string.format("millCFrameFor puts plots 1-5's mills in front (x %.1f, %.1f ahead, turned %d) and plot 6's beside "
			.. "its right-hand fence (%.0f out, %.1f back)", MILL.Place.Front.Out, MILL.Place.Front.Ahead,
			MILL.Place.Front.Yaw, MILL.Place.Beside.Side, MILL.Place.Beside.Behind),
		"beside: " .. table.concat(besideIds, ","))
	check(roundTrip < 1e-4, "millGateFor is its exact inverse on every plot (TreadmillService rebuilds with it)", roundTrip)
	local mapSource = (Server:FindFirstChild("MapService") :: any).Source
	local millSource = (Server:FindFirstChild("TreadmillService") :: any).Source
	check(mapSource:find("buildTreadmill(id, GameConfig.millCFrameFor(cf * CFrame.new(0, 0, -startDepth * 0.5), id), plots)",
			1, true) ~= nil
			and mapSource:find("MillModel.SignBase(cf, GameConfig.Mill.StartingTier, beside)", 1, true) ~= nil,
		"MapService places every real mill with that formula, by plot, and its sign by SignBase")
	check(millSource:find("MillModel.Soften(model, GameConfig.millGateFor(cf, plotId), tier)", 1, true) ~= nil
			and millSource:find("MillModel.SignBase(cf, tier, beside)", 1, true) ~= nil,
		"and TreadmillService.Rebuild softens plot 6's tall tiers and places the sign the same way")

	--==========================================================================
	-- EVERY PLOT, EVERY LEVEL, EVERY TIER: NOTHING OF THE MILL WITHIN 0.25 OF
	-- ANY PART OF ITS OWN PLOT -- plot 6's listed tier-13 parts aside
	--==========================================================================
	say("\n-- its own plot, every level --")
	local levels = #GameConfig.PlotTiers
	local worst, touchBad, touchSeen, unsoftened = {}, {}, {}, {}
	for id = 1, n do
		local mills = millsFor(id)
		local plot = newPlot(id, 1)
		local beside = GameConfig.millStandsBeside(id)
		for level = 1, levels do
			if level > 1 then
				MapService.ResizePlot(plot, level)
			end
			local bad = {}
			local listed = {}
			for tier, mill in ipairs(mills) do
				local millCF = mill:GetPivot()
				for _, o in ipairs(overlapsOf(mill, { plot })) do
					if beside and listedTouch(o.part, tier, millCF) then
						listed[o.part.Name] = true
						if o.part.CanCollide or o.part.CanQuery then
							table.insert(unsoftened, string.format("T%d %s", tier, o.part.Name))
						end
					else
						table.insert(bad, string.format("T%d %s x %s", tier, o.part.Name, o.hit.Name))
					end
				end
			end
			if #bad > 0 then
				table.insert(worst, string.format("plot %d L%d: %s", id, level, table.concat(bad, ", ", 1, math.min(#bad, 6))))
			end
			if beside then
				local names = {}
				for name in pairs(listed) do
					table.insert(names, name)
				end
				table.sort(names)
				local got = table.concat(names, ",")
				touchSeen[level] = got
				if got ~= (TOUCH[level] or "") then
					table.insert(touchBad, string.format("L%d %s (want %s)", level, got, TOUCH[level] or "none"))
				end
			end
		end
		plot:Destroy()
		destroyAll(mills)
	end
	check(#worst == 0, string.format("every tier's mill and sign stay %.2f clear of every part of their plot -- its "
		.. "fences, wing, beds and gate -- at every level, on all %d plots", CLEAR, n), table.concat(worst, " | "))
	check(#touchBad == 0, "plot 6's fence is touched by exactly the listed tier-13 parts and no more: the spire at every "
		.. "level, a snow bank and an ice boulder at Levels 3-4", table.concat(touchBad, " | "))
	check(#unsoftened == 0, "and those parts neither collide nor answer queries there", table.concat(unsoftened, ", "))
	local seenLine = {}
	for level = 1, levels do
		table.insert(seenLine, string.format("L%d %s", level, if touchSeen[level] and touchSeen[level] ~= ""
			then touchSeen[level] else "none"))
	end
	say("  (plot 6's fence touches by level: " .. table.concat(seenLine, "; ") .. ")")

	--==========================================================================
	-- THE NEIGHBOURS: each mill against the plots either side, at their
	-- smallest and their largest
	--==========================================================================
	say("\n-- the neighbours --")
	local near = {}
	for _, level in ipairs({ 1, levels }) do
		local plots = {}
		for id = 1, n do
			plots[id] = newPlot(id, level)
		end
		for id = 1, n do
			local mills = millsFor(id)
			local others = {}
			for _, other in ipairs({ id - 1, id + 1 }) do
				if plots[other] then
					table.insert(others, plots[other])
				end
			end
			for tier, mill in ipairs(mills) do
				local found = overlapsOf(mill, others)
				if #found > 0 then
					table.insert(near, string.format("plot %d T%d L%d: %s", id, tier, level, describe(found, 3)))
				end
			end
			destroyAll(mills)
		end
		destroyAll(plots)
	end
	check(#near == 0, "and clear of both neighbours' plots, at Level 1 and at Level " .. levels,
		table.concat(near, " | ", 1, math.min(#near, 8)))

	--==========================================================================
	-- THE MILLS: each plot's every tier against the next plot's every tier
	--==========================================================================
	say("\n-- the mills --")
	local clash = {}
	local holders = {}
	for id = 1, n do
		local holder = Instance.new("Folder")
		holder.Name = "SpecMills" .. id
		holder.Parent = fixture
		for _, mill in ipairs(millsFor(id)) do
			mill.Parent = holder
		end
		holders[id] = holder
	end
	for id = 1, n do
		local other = id % n + 1
		for _, mill in ipairs(holders[id]:GetChildren()) do
			local found = overlapsOf(mill, { holders[other] })
			if #found > 0 then
				table.insert(clash, string.format("plot %d %s x plot %d: %s", id, mill.Name, other, describe(found, 2)))
			end
		end
	end
	check(#clash == 0, "no tier of any plot's mill or sign comes within 0.25 of any tier of the next plot's",
		table.concat(clash, " | ", 1, math.min(#clash, 6)))

	--==========================================================================
	-- THE BOARDS: every plot's upgrade board, TOP CREATURES board and stats sign
	-- (the client builds that one: a 5.6 x 5.9 board at x 11.12, 1.6 in front
	-- of its gate, stood in for here)
	--==========================================================================
	say("\n-- the boards --")
	local boards = Instance.new("Folder")
	boards.Name = "SpecBoards"
	boards.Parent = fixture
	for id = 1, n do
		MillModel.BuildSign(GameConfig.plotSignBase(centres[id], GameConfig.StartingPlotTier), boards).Name = "PlotSign" .. id
		PlotShowcase.build(GameConfig.plotShowcaseBase(centres[id], GameConfig.StartingPlotTier), boards).Name =
			"PlotShowcase" .. id
		local stats = Instance.new("Part")
		stats.Name = "StatsSign" .. id
		stats.Anchored = true
		stats.CanCollide = false
		stats.Size = Vector3.new(5.6, 5.9, 0.6)
		stats.CFrame = gateOf(id) * CFrame.new(11.12, 2.95, -1.6)
		stats.Parent = boards
	end
	local onBoards = {}
	for id = 1, n do
		for _, mill in ipairs(holders[id]:GetChildren()) do
			local found = overlapsOf(mill, { boards })
			if #found > 0 then
				table.insert(onBoards, string.format("plot %d %s: %s", id, mill.Name, describe(found, 2)))
			end
		end
	end
	check(#onBoards == 0, "no tier of any mill or its sign comes within 0.25 of any plot's upgrade board, TOP "
		.. "CREATURES board or stats sign", table.concat(onBoards, " | ", 1, math.min(#onBoards, 6)))

	--==========================================================================
	-- THE WALK: below LOW studs, clear of every plot's walk from the hub to its
	-- gate, the road corridor, the deck and its rim step, and the Disco Mill's
	-- circle -- the dancers' own corridors and keep-clear circles
	-- (GameConfig.MiniEvent.Dancers), which is what a walk is in this game
	--==========================================================================
	say("\n-- the walk from the hub --")
	local zones = Instance.new("Folder")
	zones.Name = "SpecZones"
	zones.Parent = fixture
	local function zone(name, size, cf, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.Transparency = 1
		if shape then
			p.Shape = shape
		end
		p.Size = size
		p.CFrame = cf
		p.Parent = zones
		return p
	end
	local walks = {}
	for _, c in ipairs(DANCERS.Corridors) do
		if c.Name == "Road" or string.match(c.Name, "^Plot_%d+$") then
			local a = Vector3.new(c.From.X, MAP.GroundY + LOW * 0.5, c.From.Z)
			local b = Vector3.new(c.To.X, MAP.GroundY + LOW * 0.5, c.To.Z)
			zone("Walk" .. c.Name, Vector3.new(c.HalfWidth * 2, LOW, (b - a).Magnitude), CFrame.lookAt((a + b) * 0.5, b))
			table.insert(walks, c)
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
	zone("DeckRim", Vector3.new(LOW, rim * 2, rim * 2), CFrame.new(0, MAP.GroundY + LOW * 0.5, 0)
		* CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
	zone("DiscoMillCircle", Vector3.new(LOW, disco.Radius * 2, disco.Radius * 2),
		CFrame.new(disco.At.X, MAP.GroundY + LOW * 0.5, disco.At.Z) * CFrame.Angles(0, 0, math.rad(90)), Enum.PartType.Cylinder)
	-- Marigold's stall beside the road's approach (Map.Stall, 2026-10-10), plot
	-- 6's mill its nearest: the stall's ground and its customers' in its own
	-- frame (EventHubSpec's rectangle: out past both boards, from the riser's
	-- back to 7 studs in front of the floor).
	local stallCF = GameConfig.hubStallCFrame()
	local stallHalf = MAP.Stall.BoardSide + 7.2 / 2 + 0.4
	local stallCorners = {}
	for _, c in ipairs({ { -stallHalf, -9 }, { stallHalf, -9 }, { stallHalf, 12 }, { -stallHalf, 12 } }) do
		table.insert(stallCorners, stallCF:PointToWorldSpace(Vector3.new(c[1], 0, c[2])))
	end
	local function toStall(w)
		local q = stallCF:PointToObjectSpace(Vector3.new(w.X, stallCF.Position.Y, w.Z))
		local dx = math.max(-stallHalf - q.X, 0, q.X - stallHalf)
		local dz = math.max(-9 - q.Z, 0, q.Z - 12)
		return math.sqrt(dx * dx + dz * dz)
	end
	local function fromStall(part)
		local best = math.huge
		local h = part.Size * 0.5
		for _, c in ipairs(stallCorners) do
			local q = part.CFrame:PointToObjectSpace(Vector3.new(c.X, part.Position.Y, c.Z))
			local w = part.CFrame:PointToWorldSpace(Vector3.new(math.clamp(q.X, -h.X, h.X), math.clamp(q.Y, -h.Y, h.Y),
				math.clamp(q.Z, -h.Z, h.Z)))
			best = math.min(best, Vector2.new(w.X - c.X, w.Z - c.Z).Magnitude)
		end
		return best
	end
	local inWalk = {}
	local clearance = {}
	local stallLeast, stallAt = math.huge, ""
	for id = 1, n do
		local m = { walk = math.huge, rim = math.huge, disco = math.huge }
		for _, mill in ipairs(holders[id]:GetChildren()) do
			local found = overlapsOf(mill, { zones }, true)
			if #found > 0 then
				table.insert(inWalk, string.format("plot %d %s: %s", id, mill.Name, describe(found, 3)))
			end
			for _, part in ipairs(partsOf(mill)) do
				if part.Transparency < 1 or part.CanCollide then
					local low = false
					for _, w in ipairs(cornersOf(part)) do
						if w.Y - MAP.GroundY < LOW then
							low = true
							local flat = Vector3.new(w.X, 0, w.Z)
							for _, c in ipairs(walks) do
								local a, b = Vector3.new(c.From.X, 0, c.From.Z), Vector3.new(c.To.X, 0, c.To.Z)
								local ab = b - a
								local t = math.clamp((flat - a):Dot(ab) / ab:Dot(ab), 0, 1)
								m.walk = math.min(m.walk, (flat - (a + ab * t)).Magnitude - c.HalfWidth)
							end
							m.rim = math.min(m.rim, flat.Magnitude - rim)
							m.disco = math.min(m.disco, (flat - Vector3.new(disco.At.X, 0, disco.At.Z)).Magnitude - disco.Radius)
							local d = toStall(w)
							if d < stallLeast then
								stallLeast, stallAt = d, string.format("plot %d's %s %s", id, mill.Name, part.Name)
							end
						end
					end
					if low then
						local d = fromStall(part)
						if d < stallLeast then
							stallLeast, stallAt = d, string.format("plot %d's %s %s", id, mill.Name, part.Name)
						end
					end
				end
			end
		end
		clearance[id] = m
	end
	check(#inWalk == 0, string.format("below %d studs, no tier of any plot's mill or sign stands in a walk from the hub "
		.. "to a gate, the road corridor, the deck's rim (%.0f) or the Disco Mill's circle (%.0f)", LOW, rim, disco.Radius),
		table.concat(inWalk, " | ", 1, math.min(#inWalk, 6)))
	for id = 1, n do
		local m = clearance[id]
		say(string.format("  (plot %d, every tier and its sign: %.2f from the nearest walk's edge, %.2f outside the rim, "
			.. "%.2f outside the Disco Mill's circle)", id, m.walk, m.rim, m.disco))
	end
	check(stallLeast >= 7, string.format("and every tier of every mill, its sign too, stands %.1f studs clear of "
		.. "Marigold's stall and its customers' ground at the closest (%s)", stallLeast, stallAt))

	--==========================================================================
	-- THE GATE LINE AND THE ROAD'S EMPTY ARC
	--==========================================================================
	say("\n-- the gate line and the road's empty arc --")
	local frontBad, besideBad, arcBad, unsoft = {}, {}, {}, {}
	local measured = {}
	local frontNear = math.huge
	for id = 1, n do
		local gate = gateOf(id)
		local beside = GameConfig.millStandsBeside(id)
		for _, mill in ipairs(holders[id]:GetChildren()) do
			local tier = mill:GetAttribute("MillTier")
			local pin = if beside then OVERHANG[tier] else nil
			local past, depth, signPast, nearest = -math.huge, 0, -math.huge, math.huge
			local sign = mill:FindFirstChild("SpecSign")
			for _, part in ipairs(partsOf(mill)) do
				local isSign = sign ~= nil and part:IsDescendantOf(sign)
				local reaches = false
				for _, w in ipairs(cornersOf(part)) do
					local z = gate:PointToObjectSpace(w).Z
					local into = intoArc(w)
					if isSign then
						signPast = math.max(signPast, -z)
						nearest = math.min(nearest, -z)
					elseif part.Transparency < 1 or part.CanCollide then
						past = math.max(past, -z)
						nearest = math.min(nearest, -z)
						if into > 0 and w.Y - MAP.GroundY < LOW then
							depth = math.max(depth, math.rad(into) * Vector3.new(w.X, 0, w.Z).Magnitude)
						end
					end
					if z < 0 or into > 0 then
						reaches = true
					end
				end
				if pin and reaches and not isSign and (part.CanCollide or part.CanQuery) then
					table.insert(unsoft, string.format("T%d %s", tier, part.Name))
				end
			end
			if not beside then
				frontNear = math.min(frontNear, nearest)
				if nearest < CLEAR then
					table.insert(frontBad, string.format("plot %d T%d %.2f", id, tier, nearest))
				end
				if depth > 0 then
					table.insert(arcBad, string.format("plot %d T%d %.2f", id, tier, depth))
				end
			elseif pin then
				measured[tier] = { past = past, arc = depth, sign = signPast }
			else
				if past > 0 or signPast > 0 then
					table.insert(besideBad, string.format("T%d %.2f", tier, math.max(past, signPast)))
				end
				if depth > 0 then
					table.insert(arcBad, string.format("plot %d T%d %.2f", id, tier, depth))
				end
			end
		end
	end
	check(#frontBad == 0, string.format("plots 1-5: every tier and its sign stand wholly in front of the gate line, "
		.. "%.2f clear of it at the least", frontNear), table.concat(frontBad, ", ", 1, math.min(#frontBad, 6)))
	check(#besideBad == 0, "plot 6, tiers 1-11: nothing of the mill or its sign reaches forward of the gate line",
		table.concat(besideBad, ", "))
	check(#arcBad == 0, string.format("no mill below %d studs stands in the road's empty arc but plot 6's tiers 12-14",
		LOW), table.concat(arcBad, ", ", 1, math.min(#arcBad, 6)))
	local pinBad = {}
	for tier, want in pairs(OVERHANG) do
		local got = measured[tier]
		if not got or math.abs(got.past - want.past) > TOLERANCE or math.abs(got.arc - want.arc) > TOLERANCE
			or math.abs(got.sign - SIGN_PAST) > TOLERANCE then
			table.insert(pinBad, string.format("T%d past %.2f arc %.2f sign %.2f (pinned %.2f / %.2f / %.2f)", tier,
				got and got.past or -1, got and got.arc or -1, got and got.sign or -1, want.past, want.arc, SIGN_PAST))
		end
	end
	check(#pinBad == 0, string.format("plot 6, tiers 12-14: exactly the overhang measured on 2026-10-06 -- %.2f, %.2f "
		.. "and %.2f past the gate line, %.2f, %.2f and %.2f into the arc, the sign %.2f past -- and no more",
		OVERHANG[12].past, OVERHANG[13].past, OVERHANG[14].past, OVERHANG[12].arc, OVERHANG[13].arc, OVERHANG[14].arc,
		SIGN_PAST), table.concat(pinBad, " | "))
	check(#unsoft == 0, "and every part of them that reaches past the gate line or into the arc neither collides nor "
		.. "answers queries", table.concat(unsoft, ", ", 1, math.min(#unsoft, 8)))
	for tier = 12, 14 do
		local got = measured[tier]
		if got then
			say(string.format("  (plot 6 T%d: %.3f past the gate line, %.3f into the arc; its sign %.3f past)",
				tier, got.past, got.arc, got.sign))
		end
	end

	--==========================================================================
	-- THE PROMPTS: no two share ground (each mill sign's reaches REACH)
	--==========================================================================
	say("\n-- the prompts --")
	local signPrompts = {}
	for id = 1, n do
		for _, mill in ipairs(holders[id]:GetChildren()) do
			local sign = mill:FindFirstChild("SpecSign")
			local prompt = sign and sign:FindFirstChildWhichIsA("ProximityPrompt", true)
			if prompt then
				table.insert(signPrompts, { id = id, at = prompt.Parent.Position, reach = prompt.MaxActivationDistance,
					tier = tonumber(string.match(mill.Name, "_T(%d+)$")) })
			end
		end
	end
	local closest, closestAt = math.huge, ""
	for i = 1, #signPrompts do
		for j = i + 1, #signPrompts do
			local a, b = signPrompts[i], signPrompts[j]
			if a.id ~= b.id then
				local d = (a.at - b.at).Magnitude
				if d < closest then
					closest, closestAt = d, string.format("plots %d/%d", a.id, b.id)
				end
			end
		end
	end
	local boardNear, boardAt = math.huge, ""
	for _, b in ipairs(boards:GetChildren()) do
		local prompt = b:FindFirstChildWhichIsA("ProximityPrompt", true)
		if prompt then
			for _, s in ipairs(signPrompts) do
				local d = (prompt.Parent.Position - s.at).Magnitude - prompt.MaxActivationDistance
				if d < boardNear then
					boardNear, boardAt = d, string.format("plot %d's mill and %s", s.id, b.Name)
				end
			end
		end
	end
	local hubNear = math.huge
	for _, s in ipairs(signPrompts) do
		hubNear = math.min(hubNear, Vector3.new(s.at.X, 0, s.at.Z).Magnitude - rim)
	end
	-- Marigold's stall stands off the deck, beside the road's approach, since
	-- 2026-10-10 (Map.Stall): its three prompts are measured on their own --
	-- the boards' over their feet, Marigold's anywhere in her wander (6.5
	-- either side of her spot, 2.2 to and fro: FairyService), in the stall's
	-- own frame.
	local S = MAP.Stall
	local stallFrame = GameConfig.hubStallCFrame()
	local function inWander(at)
		local q = stallFrame:PointToObjectSpace(Vector3.new(at.X, stallFrame.Position.Y, at.Z))
		local dx = math.max(-6.5 - q.X, 0, q.X - 6.5)
		local dz = math.max(-5.5 - 2.2 - q.Z, 0, q.Z - (-5.5 + 2.2))
		return math.sqrt(dx * dx + dz * dz)
	end
	local function from(point)
		return function(at)
			return (Vector3.new(at.X, 0, at.Z) - Vector3.new(point.X, 0, point.Z)).Magnitude
		end
	end
	local stallPrompts = {
		{ "SELL ALL", from(GameConfig.hubStallPoint(-S.BoardSide, S.BoardFront - 2)), GameConfig.SellOne.PromptDistance },
		{ "SELL ONE", from(GameConfig.hubStallPoint(S.BoardSide, S.BoardFront - 2)), GameConfig.SellOne.PromptDistance },
		{ "Marigold", inWander, GameConfig.Weapon.PromptDistance },
	}
	local stallNear, stallAt = math.huge, ""
	local tall = {}
	for _, s in ipairs(signPrompts) do
		for _, p in ipairs(stallPrompts) do
			local spare = p[2](s.at) - REACH - p[3]
			if s.id == 6 and s.tier and s.tier >= 12 then
				tall[p[1]] = math.min(tall[p[1]] or math.huge, spare)
			elseif spare < stallNear then
				stallNear, stallAt = spare, string.format("plot %d's T%s sign and %s", s.id, tostring(s.tier), p[1])
			end
		end
	end
	-- PLOT 6'S TALL-TIER SIGN AND THE STALL (2026-10-10, measured and pinned):
	-- its sign for tiers 12-14 stands SIGN_PAST past the gate line, behind the
	-- stall's back corner, and shares a sliver of ground there with SELL ALL
	-- and with Marigold's wander -- at the one spot that keeps every other rule
	-- (GameConfig.Map.Stall). Equal to within TOLERANCE, so it can neither grow
	-- nor quietly change; SELL ONE stays clear of it.
	local TALL_SHARE = { ["SELL ALL"] = -2.450, Marigold = -2.207 }
	check(tall["SELL ALL"] ~= nil and math.abs(tall["SELL ALL"] - TALL_SHARE["SELL ALL"]) <= TOLERANCE
			and tall.Marigold ~= nil and math.abs(tall.Marigold - TALL_SHARE.Marigold) <= TOLERANCE
			and (tall["SELL ONE"] or -1) > 1,
		string.format("plot 6's tiers 12-14 sign shares with the stall exactly the sliver measured on 2026-10-10 -- "
			.. "%.2f with SELL ALL, %.2f with Marigold's wander -- and SELL ONE %.1f clear", tall["SELL ALL"] or -99,
			tall.Marigold or -99, tall["SELL ONE"] or -99))
	check(#signPrompts == n * TIERS and closest > REACH * 2, string.format("every mill sign's prompt is %.1f from "
		.. "another plot's at the closest (%s), more than twice its %d reach", closest, closestAt, REACH))
	check(boardNear > REACH, string.format("and %.1f clear of the nearest plot board's reach (%s) -- more than its own %d",
		boardNear, boardAt, REACH))
	check(hubNear > REACH, string.format("and %.1f outside the deck's rim, where every hub prompt but the stall's "
		.. "stands -- more than its %d reach", hubNear, REACH))
	check(stallNear > 0, string.format("and every other sign %.1f to spare from the stall's three by the road's approach "
		.. "(%s): further than the two reaches added", stallNear, stallAt))

	destroyAll(holders)
	boards:Destroy()
	zones:Destroy()

	--==========================================================================
	-- A REBUILD STAYS PUT: TreadmillService rebuilds from the model's own
	-- pivot, so the placement survives every upgrade, in front and beside
	--==========================================================================
	say("\n-- a rebuild stays put --")
	local drift = 0
	for _, id in ipairs({ 1, 6 }) do
		local cf = GameConfig.millCFrameFor(gateOf(id), id)
		local model = MillModel.Build(1, cf, fixture)
		local again = MillModel.Build(TIERS, model:GetPivot(), fixture)
		drift = math.max(drift, (model:GetPivot().Position - cf.Position).Magnitude,
			(again:GetPivot().Position - cf.Position).Magnitude)
		model:Destroy()
		again:Destroy()
	end
	check(drift < 1e-3, "a mill's pivot is the frame it was built at, so a rebuild at the pivot puts it back in the same "
		.. "place, in front of a plot and beside one", string.format("%.5f", drift))

	--==========================================================================
	-- NOT A CHECK: the way east to the obby (Dancers.Corridors "Obby") crosses
	-- plot 5's mill -- as it crossed it beside the plot, before 2026-10-06.
	-- Printed so the record says so.
	--==========================================================================
	for _, c in ipairs(DANCERS.Corridors) do
		if c.Name == "Obby" then
			local cf = GameConfig.millCFrameFor(gateOf(5), 5)
			local flat = Vector3.new(cf.Position.X, 0, cf.Position.Z)
			local a, b = Vector3.new(c.From.X, 0, c.From.Z), Vector3.new(c.To.X, 0, c.To.Z)
			local ab = b - a
			local t = math.clamp((flat - a):Dot(ab) / ab:Dot(ab), 0, 1)
			say(string.format("  (not checked: plot 5's mill centre stands %.1f from the centre of the way east to the "
				.. "obby, half-width %d -- in it, as it was beside the plot)", (flat - (a + ab * t)).Magnitude, c.HalfWidth))
		end
	end
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

fixture:Destroy()
probe:Destroy()

say(string.format("\nMillPlacementSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
