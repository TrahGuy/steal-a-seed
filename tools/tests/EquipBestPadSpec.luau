--!nocheck
--==============================================================================
-- Steal a Seed :: EquipBestPadSpec (2026-10-13, the owner's backlog item 1)
--
-- THE EQUIP BEST PAD STANDS ON THE LEFT GRASS STRIP, IN NOTHING'S WAY, ON
-- EVERY PLOT AT EVERY LEVEL, AND RUNS THE MENU'S OWN EQUIP BEST ONCE A STEP.
--
-- Built for real, in Edit: each of the ring's plots grown through every level
-- by MapService.ResizePlot (its own fences, wing and beds), the pad built by
-- EquipBestPad.build at EquipBestPad.cframeFor the plot's PlotCF -- exactly
-- what EquipBestPad.client does. PlotShowcasePlacementSpec's method.
--
--   the strip    the left side (never the wing's), the whole rim inside the
--                fence's inner face and outside every creature's walk
--                (Plant.Wander.FenceMargin), halfway along the main bed
--   the plot     clear of every part of its own plot at every level
--   the prompts  it carries none and stands on no fixture prompt's ground:
--                the upgrade board's and every mill tier's
--   inert        anchored, never collides, touched, queried or shadowed
--   standing     onPad's reach across, under and over
--   the hold     one run per HoldSeconds on it; a slow frame never fills it;
--                stepping off empties it; spent until the body steps off;
--                nothing again inside CooldownSeconds
--   the wiring   the client sends the Garden menu's own verb, on this
--                player's own plot only
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local EquipBestPad = require(Shared:WaitForChild("EquipBestPad"))
local MillModel = require(Shared:WaitForChild("MillModel"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local MapService = require(Server:WaitForChild("MapService"))

local MAP, MILL, PLOT = GameConfig.Map, GameConfig.Mill, GameConfig.Plot
local PAD = GameConfig.EquipBestPad
local CLEAR = 0.25
-- The fence's boards are 1.6 thick on the fence line (MapService FENCE_THICK).
local FENCE_HALF = 0.8

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
fixture.Name = "EquipBestPadSpecFixture"
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
	model:SetAttribute(GameConfig.Attributes.PlotId, id)
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

local function padOn(plot)
	local frame = plot:GetAttribute("PlotCF")
	return EquipBestPad.build(EquipBestPad.cframeFor(frame), fixture), frame
end

local ok, err = pcall(function()
	local levels = #GameConfig.PlotTiers
	local halfW = PLOT.Width * 0.5

	--==========================================================================
	say("-- the strip --")
	--==========================================================================
	local here = EquipBestPad.localCFrame()
	local fenceFace = -halfW + FENCE_HALF
	local walkEdge = -halfW + GameConfig.Plant.Wander.FenceMargin
	check(here.X < 0 and math.abs(here.Z) < 1e-9 and math.abs(here.Y) < 1e-9
			and (EquipBestPad.cframeFor(centres[1]).Position - (centres[1] * here).Position).Magnitude < 1e-9,
		string.format("on the LEFT side of the plot's frame (x %.2f; the wing grows on +x), halfway along it (z 0), "
			.. "on the ground", here.X))
	check(here.X - PAD.RimRadius >= fenceFace + CLEAR - 1e-9,
		string.format("the whole rim inside the left fence's inner face: %.2f clear of it (at least %.2f)",
			here.X - PAD.RimRadius - fenceFace, CLEAR))
	check(here.X + PAD.RimRadius <= walkEdge - CLEAR + 1e-9,
		string.format("and outside every creature's walk (FenceMargin %.1f): %.2f clear of where a base may stand",
			GameConfig.Plant.Wander.FenceMargin, walkEdge - here.X - PAD.RimRadius))
	check(PAD.TriggerRadius >= PAD.RimRadius and PAD.PadRadius < PAD.RimRadius,
		"a body counts as on it anywhere over its rim: TriggerRadius reaches past RimRadius")

	local offMid, offBed, outOfBed = 0, {}, {}
	for id = 1, n do
		local plot = newPlot(id, 1)
		for level = 1, levels do
			if level > 1 then
				MapService.ResizePlot(plot, level)
			end
			local frame = plot:GetAttribute("PlotCF")
			local at = EquipBestPad.cframeFor(frame)
			local soil = plot:FindFirstChild(PLOT.PlanterName)
			if not soil then
				table.insert(offBed, string.format("plot %d L%d: no main bed", id, level))
			else
				local local_ = soil.CFrame:PointToObjectSpace(at.Position)
				offMid = math.max(offMid, math.abs(local_.Z))
				if math.abs(local_.Z) + PAD.RimRadius > soil.Size.Z * 0.5 then
					table.insert(outOfBed, string.format("plot %d L%d", id, level))
				end
				-- Left of the bed: the bed's own -X edge, its frame beyond it.
				if local_.X + PAD.RimRadius > -soil.Size.X * 0.5 - PLOT.BedFrameWidth - CLEAR then
					table.insert(offBed, string.format("plot %d L%d: x %.2f", id, level, local_.X))
				end
			end
		end
		plot:Destroy()
	end
	check(offMid < 1e-3 and #offBed == 0,
		string.format("on every one of the %d plots at every level 1-%d (plot 6's deeper Levels 6-7 too): beside the "
			.. "main bed's left frame, level with the bed's middle (off it by %.4f at most)", n, levels, offMid),
		table.concat(offBed, " | ", 1, math.min(#offBed, 6)))
	check(#outOfBed == 0, "and alongside the bed, never past its ends, as the plot grows",
		table.concat(outOfBed, " | ", 1, math.min(#outOfBed, 6)))

	--==========================================================================
	say("\n-- its own plot, every level --")
	--==========================================================================
	local worst = {}
	for id = 1, n do
		local plot = newPlot(id, 1)
		for level = 1, levels do
			if level > 1 then
				MapService.ResizePlot(plot, level)
			end
			local built = padOn(plot)
			local bad = overlapsOf(built.model, { plot })
			if #bad > 0 then
				table.insert(worst, string.format("plot %d L%d: %s", id, level, table.concat(bad, ", ", 1, math.min(#bad, 6))))
			end
			built.model:Destroy()
		end
		plot:Destroy()
	end
	check(#worst == 0, string.format("%.2f clear of every part of its plot -- fences, beds, frames and wing -- at every "
		.. "level, on all %d plots", CLEAR, n), table.concat(worst, " | ", 1, math.min(#worst, 6)))

	--==========================================================================
	say("\n-- the prompts --")
	--==========================================================================
	local carried = 0
	do
		local plot = newPlot(1, 1)
		local built = padOn(plot)
		for _, d in ipairs(built.model:GetDescendants()) do
			if d:IsA("ProximityPrompt") or d:IsA("ClickDetector") then
				carried += 1
			end
		end
		built.model:Destroy()
		plot:Destroy()
	end
	check(carried == 0, "it carries no prompt and no click detector")
	local crowded, seen = {}, 0
	for id = 1, n do
		local fixtures = {}
		for _, level in ipairs({ 1, levels }) do
			local plot = newPlot(id, level)
			local frame = plot:GetAttribute("PlotCF")
			local at = EquipBestPad.cframeFor(frame)
			local sign = MillModel.BuildSign(GameConfig.plotSignBase(frame, level, id), fixture)
			table.insert(fixtures, sign)
			local millCF = GameConfig.millCFrameFor(gateOf(id), id)
			local mill = MillModel.Build(#MILL.Tiers, millCF, fixture)
			MillModel.BuildSign(MillModel.SignBase(millCF, #MILL.Tiers, GameConfig.millStandsBeside(id)), mill)
			table.insert(fixtures, mill)
			for _, thing in ipairs({ sign, mill }) do
				for _, d in ipairs(thing:GetDescendants()) do
					if d:IsA("ProximityPrompt") then
						seen += 1
						local holder = d.Parent
						local where = if holder:IsA("BasePart") then holder.Position
							elseif holder:IsA("Attachment") then holder.WorldPosition
							else nil
						if where then
							local reach = d.MaxActivationDistance + PAD.TriggerRadius
							local apart = (Vector2.new(where.X, where.Z) - Vector2.new(at.Position.X, at.Position.Z)).Magnitude
							if apart < reach then
								table.insert(crowded, string.format("plot %d L%d: %s %.1f < %.1f", id, level, d.Name,
									apart, reach))
							end
						end
					end
				end
			end
			plot:Destroy()
		end
		for _, f in ipairs(fixtures) do
			f:Destroy()
		end
	end
	check(seen > 0 and #crowded == 0,
		string.format("on no fixture prompt's ground: %d prompts (the upgrade board's, the top mill tier's) each "
			.. "further from it than its reach plus the pad's, on every plot at Level 1 and %d", seen, levels),
		table.concat(crowded, " | ", 1, math.min(#crowded, 6)))

	--==========================================================================
	say("\n-- inert --")
	--==========================================================================
	local built = EquipBestPad.build(CFrame.new(0, MAP.GroundY, 0), fixture)
	local flags, offBand = {}, {}
	for _, part in ipairs(partsOf(built.model)) do
		if not part.Anchored or part.CanCollide or part.CanTouch or part.CanQuery or part.CastShadow then
			table.insert(flags, part.Name)
		end
	end
	for _, seg in ipairs(built.segments) do
		local d = Vector2.new(seg.Position.X, seg.Position.Z).Magnitude
		if d < PAD.PadRadius or d > PAD.RimRadius then
			table.insert(offBand, string.format("%s %.2f", seg.Name, d))
		end
	end
	check(#flags == 0, "every part anchored, and never collides, is touched, is queried or casts a shadow: it cannot "
		.. "stop a runner or catch a planting click", table.concat(flags, ", "))
	check(#built.segments == PAD.Segments and #offBand == 0,
		string.format("%d ring segments, all on the band between the disc's edge and the rim's", PAD.Segments),
		table.concat(offBand, ", "))
	local top = 0
	for _, part in ipairs(partsOf(built.model)) do
		local up = if part.Shape == Enum.PartType.Cylinder then part.Size.X * 0.5 else part.Size.Y * 0.5
		top = math.max(top, part.Position.Y + up - MAP.GroundY)
	end
	check(top <= 0.25, string.format("low: nothing of it stands more than %.2f studs off the ground", top))
	built.model:Destroy()

	--==========================================================================
	say("\n-- standing on it --")
	--==========================================================================
	local at = CFrame.new(10, MAP.GroundY, -4) * CFrame.Angles(0, 0.7, 0)
	local function onAt(x, y, z)
		return EquipBestPad.onPad((at * CFrame.new(x, y, z)).Position, at)
	end
	check(onAt(0, 3, 0) and onAt(PAD.TriggerRadius - 0.05, 3, 0) and onAt(0, 3, -(PAD.TriggerRadius - 0.05)),
		"a root over the pad, out to TriggerRadius across, counts as on it")
	check(not onAt(PAD.TriggerRadius + 0.05, 3, 0) and not onAt(0, 3, PAD.TriggerRadius + 0.05),
		"just past TriggerRadius does not")
	check(not onAt(0, PAD.ReachAbove + 0.5, 0) and not onAt(0, -PAD.ReachBelow - 0.5, 0) and onAt(0, PAD.ReachAbove - 0.1, 0),
		string.format("nor a root more than %.1f over it (a jump over it) or %.1f under it", PAD.ReachAbove, PAD.ReachBelow))

	--==========================================================================
	say("\n-- the hold --")
	--==========================================================================
	local TICK = 1 / 30
	local function run(hold, on, seconds, now, dt)
		local fired = 0
		local t = now
		local d = dt or TICK
		while t < now + seconds - 1e-9 do
			t += d
			if EquipBestPad.step(hold, on, d, t) then
				fired += 1
			end
		end
		return fired, t
	end
	local hold = EquipBestPad.new()
	local firedAt = nil
	local t = 0
	for _ = 1, 200 do
		t += TICK
		if EquipBestPad.step(hold, true, TICK, t) then
			firedAt = t
			break
		end
	end
	check(firedAt ~= nil and firedAt >= PAD.HoldSeconds - 1e-6 and firedAt <= PAD.HoldSeconds + 2 * TICK + 1e-6,
		string.format("standing on it runs it once the fill reaches HoldSeconds (%.2f s): ran at %.3f s",
			PAD.HoldSeconds, firedAt or -1))
	local again = run(hold, true, PAD.CooldownSeconds * 4, t)
	check(again == 0, string.format("then nothing more while the body stays on it, for %.0f s and past the cooldown",
		PAD.CooldownSeconds * 4), again)

	local fresh = EquipBestPad.new()
	local hitch = EquipBestPad.step(fresh, true, 2, 1)
	local hitchFill = EquipBestPad.progress(fresh, 1)
	check(not hitch and math.abs(hitchFill - PAD.MaxStep / PAD.HoldSeconds) < 1e-9,
		string.format("a two-second frame fills at most MaxStep (%.2f s) of it, never the whole hold", PAD.MaxStep))
	local nan = EquipBestPad.new()
	check(not EquipBestPad.step(nan, true, 0 / 0, 1) and EquipBestPad.progress(nan, 1) == 0,
		"and a NaN step adds nothing")

	local leave = EquipBestPad.new()
	run(leave, true, PAD.HoldSeconds * 0.6, 0)
	local midFill = EquipBestPad.progress(leave, 1)
	EquipBestPad.step(leave, false, TICK, 1)
	local emptied = EquipBestPad.progress(leave, 1)
	local backOn = run(leave, true, PAD.HoldSeconds * 0.6, 1)
	check(midFill > 0.5 and emptied == 0 and backOn == 0,
		"stepping off mid-fill empties it, so two short steps never add up to a run",
		string.format("%.2f then %.2f, ran %d", midFill, emptied, backOn))

	local cool = EquipBestPad.new()
	local _, t1 = run(cool, true, PAD.HoldSeconds + 0.1, 0)
	EquipBestPad.step(cool, false, TICK, t1 + TICK)
	local early = run(cool, true, PAD.CooldownSeconds - 0.5, t1 + TICK)
	check(early == 0, string.format("stepping off and back on inside the cooldown (%.0f s) runs nothing",
		PAD.CooldownSeconds), early)
	local later, t2 = run(cool, true, 0.5 + PAD.HoldSeconds + 0.2, t1 + TICK + PAD.CooldownSeconds - 0.5)
	check(later == 1, "and once it is over, a body that stepped back on runs it once more, a full hold later",
		string.format("ran %d by %.2f s", later, t2))

	local fill0, cool0 = EquipBestPad.progress(EquipBestPad.new(), 0)
	local c = EquipBestPad.new()
	local _, tc = run(c, true, PAD.HoldSeconds + 0.05, 0)
	local _, coolNow = EquipBestPad.progress(c, tc)
	local _, coolHalf = EquipBestPad.progress(c, tc + PAD.CooldownSeconds * 0.5)
	local _, coolDone = EquipBestPad.progress(c, tc + PAD.CooldownSeconds + 0.01)
	check(fill0 == 0 and cool0 == 0 and coolNow > 0.95 and math.abs(coolHalf - 0.5) < 0.05 and coolDone == 0,
		"progress: an empty ring at rest; the cooldown counts out from full to nothing over CooldownSeconds",
		string.format("%.2f %.2f %.2f", coolNow, coolHalf, coolDone))
	check(EquipBestPad.lit(0) == 0 and EquipBestPad.lit(0.5) == math.floor(PAD.Segments / 2)
			and EquipBestPad.lit(1) == PAD.Segments and EquipBestPad.lit(0 / 0) == 0 and EquipBestPad.lit(2) == PAD.Segments,
		string.format("the ring lights 0 to %d segments as the fill goes 0 to 1, and never more", PAD.Segments))

	--==========================================================================
	say("\n-- the wiring --")
	--==========================================================================
	local scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
	local client = scripts:FindFirstChild("EquipBestPad")
	local garden = scripts:FindFirstChild("GardenUI")
	local src = client and client.Source or ""
	local gardenSrc = garden and garden.Source or ""
	check(client ~= nil and string.find(src, "FireServer(MY.Best, nil)", 1, true) ~= nil
			and string.find(src, "local MY = GameConfig.Plant.MyPlants", 1, true) ~= nil
			and string.find(gardenSrc, "ask(MY.Best, nil)", 1, true) ~= nil,
		"the client sends the Garden menu's own EQUIP BEST verb (Plant.MyPlants.Best), the one GardenUI's button asks "
			.. "for, on GameEvent")
	check(string.find(src, "GetAttribute(ATTR.OwnerUserId) == player.UserId", 1, true) ~= nil
			and string.find(src, "EquipBestPad.cframeFor(frame)", 1, true) ~= nil
			and string.find(src, 'GetAttribute("PlotCF")', 1, true) ~= nil,
		"on this player's own plot only (its OwnerUserId), placed off the plot's PlotCF and placed again when it changes")
	check(string.find(gardenSrc, "if verb == MY.Reply then", 1, true) ~= nil,
		"and GardenUI hears every answer to that verb, so the pad's run is said in the button's own words")
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

fixture:Destroy()
probe:Destroy()

say(string.format("\nEquipBestPadSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
