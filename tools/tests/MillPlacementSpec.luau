--!nocheck
--==============================================================================
-- Steal a Seed :: MillPlacementSpec
--
-- THE MILL CLEARS EVERY FENCE, ON EVERY PLOT, AT EVERY LEVEL, IN EVERY TIER
--
-- The owner's report, 2026-09-30: "the mills overlap the plot fences". Measured
-- then: on a Level 3 or 4 plot the side wing's fence, 25.4 studs behind the
-- gate, ran through the back 4.5 studs of every tier (the mill stood 6.1 to
-- 29.1 back), and tier 1's compost bin cut 0.18 into the right fence at every
-- level. The owner chose to move every mill forward and a stud out
-- (GameConfig.Mill.Place); tier 2's stones, which trailed behind the step, lie
-- beside it now.
--
-- Built for real, in Edit: each of the ring's plots grown to each level by
-- MapService.ResizePlot (its own fences, wing, beds and gate), and every mill
-- tier by MillModel.Build at GameConfig.millCFrameFor -- the formula MapService
-- places the real mills with -- and the mill's sign by MillModel.BuildSign.
-- Every part of each mill is then asked, INFLATED by the clearance, which parts
-- of the plot it touches (Workspace:GetPartsInPart: the parts' real shapes, not
-- their boxes), and the same against both neighbours.
--
-- Also: nothing of a mill reaches forward of the gate line, where the walk from
-- the hub runs; nothing of the plots beside the road stands in the road's empty
-- arc; and MapService places its mills with that same formula.
--
-- Not here: Ambience's flap of tier 9's wings (a client animation, above the
-- fence's top at rest -- measured with the rest pose), and Play.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local MillModel = require(Shared:WaitForChild("MillModel"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local MapService = require(Server:WaitForChild("MapService"))

local MAP, MILL = GameConfig.Map, GameConfig.Mill
local CLEAR = 0.25

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
local start = math.pi + gap * 0.5
local centres = {}
for id = 1, n do
	local angle = start + (id - 0.5) * step
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
	model:SetAttribute(GameConfig.Attributes.PlotId, 900 + id)
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

-- Every mill tier and its sign, at a plot's real mill frame.
local function millsFor(id)
	local cf = GameConfig.millCFrameFor(gateOf(id))
	local mills = {}
	for tier = 1, #MILL.Tiers do
		local model = MillModel.Build(tier, cf, fixture)
		model.Name = string.format("SpecMill%02d_T%02d", id, tier)
		local sign = MillModel.BuildSign(MillModel.SignBase(cf), model)
		sign.Name = "SpecSign"
		mills[tier] = model
	end
	return mills
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

-- The fixture's own parts are what a mill is asked against: a query that only
-- ever sees them cannot be confused by the preview map standing in the same
-- place in Edit.
local function overlapsOf(mill, plotModels)
	local found = {}
	for _, part in ipairs(partsOf(mill)) do
		if part.Transparency < 1 or part.CanCollide then
			for _, hit in ipairs(touches(part, plotModels)) do
				table.insert(found, string.format("%s x %s", part.Name, hit.Name))
			end
		end
	end
	return found
end

local ok, err = pcall(function()
	say("-- the placement --")
	check(type(MILL.Place) == "table" and MILL.Place.Side > 0 and MILL.Place.Behind > 0
			and typeof(GameConfig.millCFrameFor(CFrame.new())) == "CFrame",
		"GameConfig.Mill.Place and millCFrameFor exist: the mill is placed from the gate")
	local mapSource = (Server:FindFirstChild("MapService") :: any).Source
	check(mapSource:find("buildTreadmill(id, GameConfig.millCFrameFor(cf * CFrame.new(0, 0, -startDepth * 0.5)), plots)",
			1, true) ~= nil,
		"MapService places every real mill with that same formula, from the plot's gate")

	--==========================================================================
	-- EVERY PLOT, EVERY LEVEL, EVERY TIER: NOTHING OF THE MILL WITHIN 0.25 OF
	-- ANY PART OF ITS OWN PLOT
	--==========================================================================
	say("\n-- its own plot, every level --")
	local levels = #GameConfig.PlotTiers
	local worst = {}
	for id = 1, n do
		local mills = millsFor(id)
		local plot = newPlot(id, 1)
		for level = 1, levels do
			if level > 1 then
				MapService.ResizePlot(plot, level)
			end
			local bad = {}
			for tier, mill in ipairs(mills) do
				for _, what in ipairs(overlapsOf(mill, { plot })) do
					table.insert(bad, string.format("T%d %s", tier, what))
				end
			end
			if #bad > 0 then
				table.insert(worst, string.format("plot %d L%d: %s", id, level,
					table.concat(bad, ", ", 1, math.min(#bad, 6))))
			end
		end
		plot:Destroy()
		for _, mill in ipairs(mills) do
			mill:Destroy()
		end
	end
	check(#worst == 0, string.format("every tier's mill and sign stay %.2f clear of every part of their plot -- its "
		.. "fences, wing, beds and gate -- at every level, on all %d plots", CLEAR, n),
		table.concat(worst, " | "))

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
				for _, what in ipairs(overlapsOf(mill, others)) do
					table.insert(near, string.format("plot %d T%d L%d: %s", id, tier, level, what))
				end
				mill:Destroy()
			end
		end
		for _, p in pairs(plots) do
			p:Destroy()
		end
	end
	check(#near == 0, "and clear of both neighbours' plots, at Level 1 and at Level " .. levels,
		table.concat(near, " | ", 1, math.min(#near, 8)))

	--==========================================================================
	-- THE GATE LINE AND THE ROAD'S EMPTY ARC
	--==========================================================================
	say("\n-- the walk from the hub, and the road --")
	-- THE ROAD'S EMPTY ARC is kept clear where it matters to a body: nothing of
	-- a mill below REACH studs stands in it. Tier 9's wings are the one thing a
	-- forward mill brings over its edge on the plot beside the road -- a feather
	-- tip 14.8 up, measured 2026-09-30 at 1.42 degrees (2.9 studs) inside it --
	-- and the deepest such airborne reach is printed rather than hidden.
	local REACH = 8
	local forward, inArc = math.huge, {}
	local airborne, airborneAt = -math.huge, "none"
	local half = gap * 0.5
	for id = 1, n do
		local gate = gateOf(id)
		local mills = millsFor(id)
		for tier, mill in ipairs(mills) do
			for _, part in ipairs(partsOf(mill)) do
				if part.Transparency < 1 then
					local h = part.Size * 0.5
					for _, sx in ipairs({ -1, 1 }) do
						for _, sy in ipairs({ -1, 1 }) do
							for _, sz in ipairs({ -1, 1 }) do
								local w = (part.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
								forward = math.min(forward, gate:PointToObjectSpace(w).Z)
								local a = math.atan2(w.X, w.Z) % (math.pi * 2)
								local into = math.deg(half - math.abs(a - math.pi))
								if into > 0 then
									if w.Y - MAP.GroundY < REACH then
										table.insert(inArc, string.format("plot %d T%d %s", id, tier, part.Name))
									elseif into > airborne then
										airborne = into
										airborneAt = string.format("plot %d tier %d %s, %.1f up", id, tier, part.Name,
											w.Y - MAP.GroundY)
									end
								end
							end
						end
					end
				end
			end
			mill:Destroy()
		end
	end
	check(forward >= 0, "nothing of any mill or its sign reaches forward of its plot's gate line",
		string.format("%.2f studs behind it at the least", forward))
	say(string.format("  (the front-most part stands %.2f behind the gate line)", forward))
	local seen, unique = {}, {}
	for _, s in ipairs(inArc) do
		if not seen[s] then
			seen[s] = true
			table.insert(unique, s)
		end
	end
	check(#unique == 0, string.format("and nothing of any mill within %d studs of the ground stands in the road's "
		.. "empty arc", REACH), table.concat(unique, ", ", 1, math.min(#unique, 6)))
	say(string.format("  (above that, the deepest reach into the arc: %s)", if airborne > 0
		then string.format("%.2f degrees, %s", airborne, airborneAt) else "none"))

	--==========================================================================
	-- A REBUILD STAYS PUT: TreadmillService rebuilds from the model's own
	-- pivot, so the placement survives every upgrade
	--==========================================================================
	say("\n-- a rebuild stays put --")
	local cf = GameConfig.millCFrameFor(gateOf(1))
	local model = MillModel.Build(1, cf, fixture)
	local drift = (model:GetPivot().Position - cf.Position).Magnitude
	local again = MillModel.Build(#MILL.Tiers, model:GetPivot(), fixture)
	local drift2 = (again:GetPivot().Position - cf.Position).Magnitude
	model:Destroy()
	again:Destroy()
	check(drift < 1e-3 and drift2 < 1e-3, "a mill's pivot is the frame it was built at, so a rebuild at the pivot "
		.. "puts it back in the same place", string.format("%.5f / %.5f", drift, drift2))
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

fixture:Destroy()
probe:Destroy()

say(string.format("\nMillPlacementSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
