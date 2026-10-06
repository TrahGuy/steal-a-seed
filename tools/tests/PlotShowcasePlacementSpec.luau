--!nocheck
--==============================================================================
-- Steal a Seed :: PlotShowcasePlacementSpec (2026-10-05, the TOP CREATURES board)
--
-- THE BOARD STANDS BESIDE THE UPGRADE BOARD AND IN NOTHING'S WAY, ON EVERY
-- PLOT, AT EVERY LEVEL -- MillPlacementSpec's method, for the board.
--
-- Built for real, in Edit: each of the ring's plots grown to each level by
-- MapService.ResizePlot (its own fences, wing and beds), every mill tier and
-- its sign by MillModel.Build / BuildSign at GameConfig.millCFrameFor, the
-- upgrade board by MillModel.BuildSign at GameConfig.plotSignBase, and the
-- board by PlotShowcase.build at GameConfig.plotShowcaseBase -- the formulas
-- MapService builds the real ones with. Every part of the board is asked,
-- INFLATED by the clearance, what it touches (Workspace:GetPartsInPart: real
-- shapes, not boxes).
--
--   beside      the upgrade board's OUTER side, Gap between them, the same
--               facing, front face and top
--   the plot    clear of every part of its own plot at every level
--   neighbours  clear of both neighbours' plots at Level 1 and the top level
--   the mills   clear of every tier of its own mill and both neighbours',
--               their signs included
--   the walk    out of the gate's opening and the walk from the hub (the
--               ring's plot corridors), just outside the fence, and short of
--               the road's empty arc
--   prompts     it carries none, stands on no prompt's board and clear of the
--               upgrade board's
--   signage     anchored, never collides, never touched, never queried; the
--               post's foot on the ground; the same world spot at every level
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

local MAP, MILL, PLOT = GameConfig.Map, GameConfig.Mill, GameConfig.Plot
local SC = PLOT.Showcase
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
fixture.Name = "PlotShowcasePlacementSpecFixture"
fixture.Archivable = false
fixture.Parent = Workspace

--==============================================================================
-- THE RING, AS MapService.Init LAYS IT OUT (MillPlacementSpec's)
--==============================================================================
local n = GameConfig.MaxPlots
local start = GameConfig.StartingPlotTier
local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(start))
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
	model:SetAttribute(GameConfig.Attributes.PlotId, 900 + id)
	model:SetAttribute(GameConfig.Attributes.OwnerUserId, 0)
	model:SetAttribute(GameConfig.Attributes.Claimed, false)
	model:SetAttribute("PlotCF", centres[id])
	model:SetAttribute("Depth", startDepth)
	model:SetAttribute("Level", start)
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

local function showcaseFor(id)
	local model = PlotShowcase.build(GameConfig.plotShowcaseBase(centres[id], start), fixture)
	model.Name = string.format("SpecShowcase%02d", id)
	return model
end

local function upgradeSignFor(id)
	local model = MillModel.BuildSign(GameConfig.plotSignBase(centres[id], start), fixture)
	model.Name = string.format("SpecUpgradeSign%02d", id)
	return model
end

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

local function overlapsOf(model, against)
	local found = {}
	for _, part in ipairs(partsOf(model)) do
		for _, hit in ipairs(touches(part, against)) do
			if hit.Transparency < 1 or hit.CanCollide then
				table.insert(found, string.format("%s x %s", part.Name, hit.Name))
			end
		end
	end
	return found
end

-- Every corner of every part in `parts`, in `frame`'s space.
local function cornersOf(parts, frame)
	local list = {}
	for _, part in ipairs(parts) do
		local h = part.Size * 0.5
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					table.insert(list, frame:PointToObjectSpace((part.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position))
				end
			end
		end
	end
	return list
end

local function corners(model, frame)
	return cornersOf(partsOf(model), frame)
end

local function boundsOf(parts, frame)
	local lo, hi = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, c in ipairs(cornersOf(parts, frame)) do
		lo = Vector3.new(math.min(lo.X, c.X), math.min(lo.Y, c.Y), math.min(lo.Z, c.Z))
		hi = Vector3.new(math.max(hi.X, c.X), math.max(hi.Y, c.Y), math.max(hi.Z, c.Z))
	end
	return lo, hi
end

local function bounds(model, frame)
	return boundsOf(partsOf(model), frame)
end

-- The half-width of the walk from the hub to this plot's gate: the ring's own
-- plot corridors (MiniEvent.Dancers.Corridors, the one consumer of a "walk").
local function walkHalf(id)
	local dancers = GameConfig.MiniEvent and GameConfig.MiniEvent.Dancers
	for _, c in ipairs(dancers and dancers.Corridors or {}) do
		if c.Name == string.format("Plot_%02d", id) then
			return c.HalfWidth
		end
	end
	return 12
end

local ok, err = pcall(function()
	say("-- the placement --")
	local signHalf = 9 * MILL.Sign.Scale * 0.5
	local wantX = PLOT.Sign.OffsetX - signHalf - SC.Gap - SC.RimStuds - SC.BoardSize.X * 0.5
	check(math.abs(GameConfig.plotShowcaseX() - wantX) < 1e-9 and typeof(GameConfig.plotShowcaseBase(CFrame.new())) == "CFrame",
		string.format("GameConfig.plotShowcaseBase stands it %.2f across the gate's frame: the upgrade board's outer "
			.. "edge, the gap, the rim and half the plank", GameConfig.plotShowcaseX()))
	local mapSource = (Server:FindFirstChild("MapService") :: any).Source
	check(mapSource:find("PlotShowcase.build(\n\t\t\tGameConfig.plotShowcaseBase(cf, GameConfig.StartingPlotTier), plots)",
			1, true) ~= nil,
		"MapService builds every real board with that same formula, in `plots`, off the plot's gate")

	--==========================================================================
	say("\n-- beside the upgrade board --")
	--==========================================================================
	local worstGap, worstFace, worstTop, outer = math.huge, 0, 0, true
	for id = 1, n do
		local gate = gateOf(id)
		local board = showcaseFor(id)
		local sign = upgradeSignFor(id)
		local bLo, bHi = bounds(board, gate)
		local sLo, sHi = bounds(sign, gate)
		worstGap = math.min(worstGap, sLo.X - bHi.X)
		local pLo, pHi = boundsOf({ board:FindFirstChild("Board") }, gate)
		local qLo, qHi = boundsOf({ sign:FindFirstChild("Board") }, gate)
		worstFace = math.max(worstFace, math.abs(pLo.Z - qLo.Z))
		worstTop = math.max(worstTop, math.abs(pHi.Y - qHi.Y))
		outer = outer and bHi.X < sLo.X and (bLo.X + bHi.X) * 0.5 < (sLo.X + sHi.X) * 0.5
		board:Destroy()
		sign:Destroy()
	end
	check(outer and worstGap >= SC.Gap - 1e-3 and worstGap <= SC.Gap + 0.05,
		string.format("on the upgrade board's OUTER side, away from the gate, %.2f studs from it on every plot "
			.. "(Gap %.2f)", worstGap, SC.Gap))
	check(worstFace < 0.05 and worstTop < 0.01,
		string.format("the same facing and front face as the upgrade board (%.3f apart) and the same top (%.3f)",
			worstFace, worstTop))

	--==========================================================================
	say("\n-- its own plot, every level --")
	--==========================================================================
	local levels = #GameConfig.PlotTiers
	local worst = {}
	for id = 1, n do
		local board = showcaseFor(id)
		local plot = newPlot(id, 1)
		for level = 1, levels do
			if level > 1 then
				MapService.ResizePlot(plot, level)
			end
			local bad = overlapsOf(board, { plot })
			if #bad > 0 then
				table.insert(worst, string.format("plot %d L%d: %s", id, level, table.concat(bad, ", ", 1, math.min(#bad, 6))))
			end
		end
		plot:Destroy()
		board:Destroy()
	end
	check(#worst == 0, string.format("the board stays %.2f clear of every part of its plot -- its fences, wing and "
		.. "beds -- at every level, on all %d plots", CLEAR, n), table.concat(worst, " | "))

	--==========================================================================
	say("\n-- the neighbours --")
	--==========================================================================
	local near = {}
	for _, level in ipairs({ 1, levels }) do
		local plots = {}
		for id = 1, n do
			plots[id] = newPlot(id, level)
		end
		for id = 1, n do
			local board = showcaseFor(id)
			local others = {}
			for _, other in ipairs({ id - 1, id + 1 }) do
				if plots[other] then
					table.insert(others, plots[other])
				end
			end
			for _, what in ipairs(overlapsOf(board, others)) do
				table.insert(near, string.format("plot %d L%d: %s", id, level, what))
			end
			board:Destroy()
		end
		for _, p in pairs(plots) do
			p:Destroy()
		end
	end
	check(#near == 0, "and clear of both neighbours' plots, at Level 1 and at Level " .. levels,
		table.concat(near, " | ", 1, math.min(#near, 8)))

	--==========================================================================
	say("\n-- the mills --")
	--==========================================================================
	local millBad = {}
	local millsById = {}
	for id = 1, n do
		millsById[id] = millsFor(id)
	end
	for id = 1, n do
		local board = showcaseFor(id)
		for _, owner in ipairs({ id - 1, id, id + 1 }) do
			local mills = millsById[owner]
			if mills then
				for tier, mill in ipairs(mills) do
					for _, what in ipairs(overlapsOf(board, { mill })) do
						table.insert(millBad, string.format("plot %d vs mill %d T%d: %s", id, owner, tier, what))
					end
				end
			end
		end
		board:Destroy()
	end
	for _, mills in pairs(millsById) do
		for _, mill in ipairs(mills) do
			mill:Destroy()
		end
	end
	check(#millBad == 0, string.format("clear of every one of the %d mill tiers -- deck, belt, decor and sign -- of "
		.. "its own plot and both neighbours", #MILL.Tiers), table.concat(millBad, " | ", 1, math.min(#millBad, 8)))

	--==========================================================================
	say("\n-- the walk, the gate and the road --")
	--==========================================================================
	local inWalk, inGate, outside, arc = {}, {}, true, {}
	local nearest, farthest = math.huge, -math.huge
	local REACH = 8
	local half = gap * 0.5
	for id = 1, n do
		local gate = gateOf(id)
		local board = showcaseFor(id)
		local w = walkHalf(id)
		for _, c in ipairs(corners(board, gate)) do
			local ax = math.abs(c.X)
			nearest = math.min(nearest, ax)
			if ax < w then
				table.insert(inWalk, string.format("plot %d x %.2f", id, c.X))
			end
			if ax <= PLOT.GateWidth * 0.5 then
				table.insert(inGate, string.format("plot %d x %.2f", id, c.X))
			end
			-- In front of the fence line, and no further out than the standoff and
			-- the plank: beside the fence, not out on the approach.
			farthest = math.max(farthest, -c.Z)
			if c.Z >= 0 or -c.Z > SC.Standoff + SC.BoardSize.Z then
				outside = false
			end
		end
		for _, part in ipairs(partsOf(board)) do
			local h = part.Size * 0.5
			for _, sx in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					local wpos = (part.CFrame * CFrame.new(h.X * sx, -h.Y, h.Z * sz)).Position
					local a = math.atan2(wpos.X, wpos.Z) % (math.pi * 2)
					if math.deg(half - math.abs(a - math.pi)) > 0 and wpos.Y - MAP.GroundY < REACH then
						table.insert(arc, string.format("plot %d %s", id, part.Name))
					end
				end
			end
		end
		board:Destroy()
	end
	check(#inGate == 0 and #inWalk == 0, string.format("out of the gate's opening and the walk from the hub: its "
		.. "nearest edge %.2f across the gate's frame, the walk %.0f either side", nearest, walkHalf(1)),
		table.concat(inWalk, ", ", 1, math.min(#inWalk, 6)))
	check(outside, string.format("just outside the fence line, at most %.2f out (Standoff %.2f + the plank)",
		farthest, SC.Standoff))
	check(#arc == 0, "and nothing of it stands in the road's empty arc", table.concat(arc, ", ", 1, math.min(#arc, 6)))

	--==========================================================================
	say("\n-- prompts --")
	--==========================================================================
	local board = showcaseFor(1)
	local sign = upgradeSignFor(1)
	local prompts = 0
	for _, d in ipairs(board:GetDescendants()) do
		if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
			prompts += 1
		end
	end
	local signPrompt = sign:FindFirstChildWhichIsA("ProximityPrompt", true)
	local onIt = #overlapsOf(board, { sign })
	check(prompts == 0 and signPrompt ~= nil and onIt == 0,
		"it carries no prompt (so it shares ground with none), and stands clear of the upgrade board, whose prompt "
			.. "it is beside", string.format("%d prompts, %d touches", prompts, onIt))
	check(signPrompt and signPrompt.RequiresLineOfSight == false,
		"and that prompt never needs a line of sight, so the board can never come between it and a player")
	sign:Destroy()

	--==========================================================================
	say("\n-- signage --")
	--==========================================================================
	local flags = {}
	for _, part in ipairs(partsOf(board)) do
		if not part.Anchored or part.CanCollide or part.CanTouch or part.CanQuery or part.CastShadow then
			table.insert(flags, part.Name)
		end
	end
	check(#flags == 0, "every part anchored, and never collides, is touched, is queried or casts a shadow: it "
		.. "cannot stop a runner or catch a planting click", table.concat(flags, ", "))
	local base = GameConfig.plotShowcaseBase(centres[1], start)
	local post = board:FindFirstChild("Post")
	local footY = post and (post.Position.Y - post.Size.Y * 0.5)
	check((board:GetPivot().Position - base.Position).Magnitude < 1e-4 and post
			and math.abs(footY - MAP.GroundY - SC.GroundY) < 1e-3 and math.abs(base.Position.Y - MAP.GroundY) < 1e-4,
		"its pivot is the post's foot, on the ground at the frame it was built at", footY)
	-- Nothing stands in front of the lettered face (Play, 2026-10-05: a centred
	-- post, thicker than the plank, stood proud of it over both cards).
	local plank = board:FindFirstChild("Board")
	local faceZ = plank.CFrame:PointToObjectSpace(plank.Position).Z - plank.Size.Z * 0.5
	local proud = {}
	for _, part in ipairs(partsOf(board)) do
		if part ~= plank then
			for _, c in ipairs(cornersOf({ part }, plank.CFrame)) do
				if c.Z < faceZ - 1e-4 and math.abs(c.X) < plank.Size.X * 0.5 and math.abs(c.Y) < plank.Size.Y * 0.5 then
					table.insert(proud, string.format("%s %.3f", part.Name, faceZ - c.Z))
					break
				end
			end
		end
	end
	check(#proud == 0, "no part of the board stands in front of its lettered face (the post is set back)",
		table.concat(proud, ", "))
	board:Destroy()
	-- Placed once: the frame off a plot grown to any level is the same world spot.
	local drift = 0
	local gate = gateOf(1)
	for level = 1, levels do
		local depth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(level))
		local centre = gate * CFrame.new(0, 0, depth * 0.5)
		drift = math.max(drift, (GameConfig.plotShowcaseBase(centre, level).Position - base.Position).Magnitude)
	end
	check(drift < 1e-4, "placed off the gate, which never moves: the same world spot at every level, so it is built "
		.. "once and never moves with an upgrade", drift)
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

fixture:Destroy()
probe:Destroy()

say(string.format("\nPlotShowcasePlacementSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
