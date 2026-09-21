--!strict
-- WeatherTeaserSpec: the teaser screen is pure decoration, stands clear of the
-- road, the red line, the night shutter and every plot at its MAX level, and
-- plays a loop that moves visibly, flickers briefly, wraps seamlessly and holds
-- still under Reduced FX. Pure fixture; never starts services or opens a profile.
local Shared = game.ReplicatedStorage.SeedGame.Shared
local Teaser = require(Shared.WeatherTeaser)
local Config = require(Shared.GameConfig)
local Map = require(game.ServerScriptService.SeedGameServer.MapService)
local pass = 0
local failures: { string } = {}
local function check(ok: boolean, message: string)
	if ok then pass += 1 else table.insert(failures, message) end
end

-- A part's footprint on the ground, as four corners in XZ.
local function footprint(p: BasePart): { Vector2 }
	local pts = {}
	for _, x in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -1, 1 }) do
			local v = p.CFrame:PointToWorldSpace(p.Size * Vector3.new(x, 0, z) * 0.5)
			table.insert(pts, Vector2.new(v.X, v.Z))
		end
	end
	return pts
end

-- Exact 2D separating-axis gap between two rectangles (negative = overlap).
local function edges(poly: { Vector2 }): { Vector2 }
	local out = {}
	local order = { 1, 2, 4, 3 }
	for i = 1, 4 do
		local e = poly[order[i % 4 + 1]] - poly[order[i]]
		if e.Magnitude > 1e-6 then
			table.insert(out, Vector2.new(-e.Y, e.X).Unit)
		end
	end
	return out
end
local function gap(a: { Vector2 }, b: { Vector2 }): number
	local axes = edges(a)
	for _, v in ipairs(edges(b)) do
		table.insert(axes, v)
	end
	local best = -math.huge
	for _, ax in ipairs(axes) do
		local amin, amax, bmin, bmax = math.huge, -math.huge, math.huge, -math.huge
		for _, p in ipairs(a) do
			local d = p:Dot(ax)
			amin, amax = math.min(amin, d), math.max(amax, d)
		end
		for _, p in ipairs(b) do
			local d = p:Dot(ax)
			bmin, bmax = math.min(bmin, d), math.max(bmax, d)
		end
		best = math.max(best, bmin - amax, amin - bmax)
	end
	return best
end

-- How far a plot at its top level must stay from the board. The failure this
-- guards against is a real one: the first placement lost 14.7 studs to Plot_06.
local PLOT_CLEARANCE = 8

local fixture = Instance.new("Folder")
local ok, err = pcall(function()
	local board = Teaser.Build(fixture)
	local parts, lights, sounds = 0, 0, 0
	local min = Vector3.new(math.huge, math.huge, math.huge)
	local max = Vector3.new(-math.huge, -math.huge, -math.huge)
	local boardPrints: { { Vector2 } } = {}
	for _, child in ipairs(board:GetDescendants()) do
		if child:IsA("Light") then lights += 1 end
		if child:IsA("Sound") then sounds += 1 end
		if child:IsA("BasePart") then
			parts += 1
			check(child.Anchored and not child.CanCollide and not child.CanQuery and not child.CanTouch,
				child.Name .. " cannot obstruct walking, combat or touches")
			for _, x in ipairs({ -1, 1 }) do for _, y in ipairs({ -1, 1 }) do for _, z in ipairs({ -1, 1 }) do
				local p = child.CFrame:PointToWorldSpace(child.Size * Vector3.new(x, y, z) * 0.5)
				min = min:Min(p); max = max:Max(p)
			end end end
			table.insert(boardPrints, footprint(child))
		end
	end
	check(parts == 7 and lights == 0 and sounds == 0, "seven parts, no lights or sounds")
	local shutterHalf = (Config.Map.CorridorWidth + Config.WorldCycle.Barrier.WidthPad) * 0.5
	check(min.X > shutterHalf or max.X < -shutterHalf,
		"entire board outside the road AND the night shutter's width, on either side")
	check(min.Z > -Config.Map.FieldFront + Config.Map.SafeLineThickness, "entire board on safe side of red line")
	check(min.Y >= Config.Map.GroundY - 0.001, "feet above ground")

	local state = assert(Teaser.Bind(board))
	check(state.gui.CanvasSize == Vector2.new(960, 540) and not state.gui.AlwaysOnTop,
		"bounded 16:9 canvas, no through-wall overlay")
	check(state.gui.MaxDistance == Teaser.Reach, "the screen draws exactly as far as the client plays it")
	check(#state.rain == Teaser.Drops and #state.lobes == 4, "every drop and cloud lobe binds")
	check(not state.bolt.Visible and state.flash.BackgroundTransparency == 1,
		"a freshly built board shows the still card, not a flash")

	-- MOVEMENT YOU CAN SEE FROM THE PATH: whole pixels, not fractions of one.
	-- The rain is compared 0.2 s apart because one drop's fall is 2/3 s, so any
	-- two times a whole number of seconds apart can land on the same frame.
	Teaser.Paint(state, 2, false)
	local cloudAt = state.cloud.Position
	local rainAt = state.rain[1].Position
	Teaser.Paint(state, 2.2, false)
	local rainMoved = math.abs((rainAt - state.rain[1].Position).Y.Offset) >= 10
	Teaser.Paint(state, 6, false)
	check(math.abs(cloudAt.X.Offset - state.cloud.Position.X.Offset) >= 6 and rainMoved,
		"clouds and rain visibly move")

	-- THE FLICKER: sampled across the whole loop at the client's own rate.
	local samples, lit, full = 0, 0, 0
	local boltMatches = true
	local t = 0
	while t < Teaser.Period do
		Teaser.Paint(state, t, false)
		local strike = Teaser.StrikeAt(t)
		samples += 1
		if strike > 0 then lit += 1 end
		if strike >= 1 then full += 1 end
		if state.bolt.Visible ~= (strike > 0) then boltMatches = false end
		t += Teaser.Interval
	end
	check(boltMatches, "the bolt shows exactly while a strike is lit")
	check(lit > 0 and full > 0 and lit / samples < 0.1,
		string.format("lightning is a brief beat, not a strobe (%d of %d frames lit)", lit, samples))
	check(Teaser.StrikeAt(6) == 0, "the storm is dark most of the loop")

	-- REDUCED FX: the still card, and it stays still.
	Teaser.Paint(state, 9.5, true)
	local still = state.cloud.Position
	local stillRain = state.rain[1].Position
	Teaser.Paint(state, 100, true)
	check(still == state.cloud.Position and stillRain == state.rain[1].Position
		and not state.scan.Visible and not state.bolt.Visible
		and state.flash.BackgroundTransparency == 1, "Reduced FX is static, with no flash, and keeps the message")

	-- THE LOOP: deterministic, and the rain does not jump at the wrap.
	Teaser.Paint(state, 2, false)
	local loopStart = state.rain[1].Position
	Teaser.Paint(state, 2 + Teaser.Period, false)
	check(state.rain[1].Position == loopStart, "loop wraps deterministically")
	-- GUI offsets are whole pixels, so "no jump" is a difference of at most one.
	Teaser.Paint(state, Teaser.Period - 0.001, false)
	local before = state.rain[1].Position
	Teaser.Paint(state, 0, false)
	check(math.abs((before - state.rain[1].Position).Y.Offset) <= 1, "rain is seamless across the wrap")

	-- EVERY PLOT AT ITS TOP LEVEL, placed exactly as MapService.Init places them.
	local gapRad = math.rad(Config.Map.RoadGapDegrees)
	local step = (2 * math.pi - gapRad) / Config.MaxPlots
	local depth = Config.plotDepthFor(Config.plotRowsForTier(1))
	for i = 1, Config.MaxPlots do
		local angle = math.pi + gapRad * 0.5 + (i - 0.5) * step
		local r = Config.Map.PlotRingInner + depth * 0.5
		local pos = Vector3.new(math.sin(angle) * r, Config.Map.GroundY, math.cos(angle) * r)
		local plot = Instance.new("Model")
		plot.Parent = fixture
		plot:SetAttribute(Config.Attributes.PlotId, i)
		plot:SetAttribute("PlotCF", CFrame.lookAt(pos, Vector3.new(0, pos.Y, 0)))
		plot:SetAttribute("Depth", depth)
		Map.ResizePlot(plot, #Config.PlotTiers)
		local nearest = math.huge
		for _, p in ipairs(plot:GetDescendants()) do
			if p:IsA("BasePart") then
				local fp = footprint(p)
				for _, bp in ipairs(boardPrints) do
					nearest = math.min(nearest, gap(fp, bp))
				end
			end
		end
		check(nearest >= PLOT_CLEARANCE, string.format(
			"screen stands %d+ studs clear of max-level plot %d (%.1f)", PLOT_CLEARANCE, i, nearest))
		plot:Destroy()
	end

	local replacement = Teaser.Build(fixture)
	check(board.Parent == nil and #fixture:GetChildren() == 1, "rebuild replaces, never duplicates")
	check(Teaser.Bind(replacement) ~= nil, "rebuilt screen still binds")
	local incomplete = Instance.new("Model")
	check(Teaser.Bind(incomplete) == nil, "incomplete streaming model can retry")
	incomplete:Destroy()
end)
fixture:Destroy()
if not ok then table.insert(failures, tostring(err)) end
return ("WeatherTeaserSpec: %d passed, %d failed%s"):format(pass, #failures,
	if #failures > 0 then "\n" .. table.concat(failures, "\n") else "")
