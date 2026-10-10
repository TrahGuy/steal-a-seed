--!nocheck
--==============================================================================
-- Steal a Seed :: EventHubSpec
--
-- THE EVENT HUB (2026-10-10, the owner: the hub's middle becomes a permanent
-- event plaza and Marigold's stall moves to its edge; KB/EVENT-HUB-CLAUDE-
-- PROMPT.md). Edit mode:
--
--   1. the plaza (Map.EventHub): the deck's middle; the event NPC's anchor on
--      the deck's top looking down the road; an open front; a quiet floor
--   2. nothing permanent in it: every fixture's ground from its config, and
--      every part of the map MapService builds -- built fresh here, twice, as
--      the SeedMapBuilder plugin builds it, so the Edit preview ends current
--      and a rebuild is shown to change nothing
--   3. Marigold's stall beside the road's approach (Map.Stall): its real parts
--      inside the ground the placement was measured for; off the deck, inside
--      the safe area, off the running line and every walk; facing the way in;
--      clear of every fixture and every plot at every level; her wander on
--      her riser
--   4. the prompts: the stall's three share ground with no other prompt in the
--      square nor any plot's board (the mills' signs: MillPlacementSpec)
--   5. finding it: BAT SHOP! in reach and in sight all the way up the road
--   6. the mini events: the tickets' ring outside the plaza; both keep-clear
--      lists from the config, nothing at the old spots; no dancer of 400
--      discos in the plaza, on the stall's ground or on the overflow spawn
--   7. the sources: built from the config, nothing left at the old spot
--
-- Not here, seen in Play instead: the prompts pressed at the stall, the
-- routes walked (PathfindingService from every gate and the road's mouth),
-- the stall and its words from the road, an event's cleanup leaving the
-- square as it was.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local Scripts = StarterPlayer:WaitForChild("StarterPlayerScripts")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local FloatingSign = require(Shared:WaitForChild("FloatingSign"))
local DancerPlacement = require(Shared:WaitForChild("DancerPlacement"))

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
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end
local function sourceOf(parent, name)
	local found = parent and parent:FindFirstChild(name)
	if not found then
		return ""
	end
	local ok, src = pcall(function()
		return found.Source
	end)
	return if ok then src else ""
end
local function has(src, text)
	return string.find(src, text, 1, true) ~= nil
end

local MAP = GameConfig.Map
local E = MAP.EventHub
local S = MAP.Stall
local stallCF = GameConfig.hubStallCFrame()
-- MapService's DeckRim: R * 2 + 5 across.
local RIM = MAP.HubRadius + 2.5
local MOUTH = Vector2.new(0, -MAP.FieldFront)
-- The running line from the deck to the mouth (the placement search's road
-- walk).
local ROAD_A, ROAD_B = Vector2.new(0, -40), MOUTH

local function flat(v)
	return Vector2.new(v.X, v.Z)
end
-- The stall's own frame (front +Z) to the world's ground plane, and back.
local function stallPoint(x, z)
	local p = stallCF:PointToWorldSpace(Vector3.new(x, 0, z))
	return Vector2.new(p.X, p.Z)
end
local function inStall(p2)
	local q = stallCF:PointToObjectSpace(Vector3.new(p2.X, stallCF.Position.Y, p2.Y))
	return q.X, q.Z
end
local function segDist(p, a, b)
	local ab = b - a
	local t = math.clamp((p - a):Dot(ab) / ab:Dot(ab), 0, 1)
	return (p - (a + ab * t)).Magnitude
end
-- How far a world point is from a rectangle drawn in the stall's frame.
local function rectDist(p2, r)
	local x, z = inStall(p2)
	local dx = math.max(r.x0 - x, 0, x - r.x1)
	local dz = math.max(r.z0 - z, 0, z - r.z1)
	return math.sqrt(dx * dx + dz * dz)
end
-- Points over such a rectangle, `step` apart or closer, its edges included.
local function samples(r, step)
	local pts = {}
	local nx = math.max(2, math.ceil((r.x1 - r.x0) / step) + 1)
	local nz = math.max(2, math.ceil((r.z1 - r.z0) / step) + 1)
	for i = 0, nx - 1 do
		for j = 0, nz - 1 do
			table.insert(pts, stallPoint(r.x0 + (r.x1 - r.x0) * i / (nx - 1), r.z0 + (r.z1 - r.z0) * j / (nz - 1)))
		end
	end
	return pts
end
local function cornersOf(r)
	return { stallPoint(r.x0, r.z0), stallPoint(r.x1, r.z0), stallPoint(r.x1, r.z1), stallPoint(r.x0, r.z1) }
end
-- The gap between two convex outlines (corners in order); 0 if one reaches
-- into the other.
local function inside(p, poly)
	local sign = 0
	for i = 1, #poly do
		local a, b = poly[i], poly[i % #poly + 1]
		local cross = (b.X - a.X) * (p.Y - a.Y) - (b.Y - a.Y) * (p.X - a.X)
		if math.abs(cross) > 1e-9 then
			local s = if cross > 0 then 1 else -1
			if sign == 0 then
				sign = s
			elseif s ~= sign then
				return false
			end
		end
	end
	return true
end
local function polyGap(p, q)
	for _, v in ipairs(p) do
		if inside(v, q) then
			return 0
		end
	end
	for _, v in ipairs(q) do
		if inside(v, p) then
			return 0
		end
	end
	local best = math.huge
	for _, pair in ipairs({ { p, q }, { q, p } }) do
		for _, v in ipairs(pair[1]) do
			for i = 1, #pair[2] do
				best = math.min(best, segDist(v, pair[2][i], pair[2][i % #pair[2] + 1]))
			end
		end
	end
	return best
end

--==============================================================================
-- THE STALL'S GROUND, in its own frame (front +Z): MapService's floor, riser,
-- counter and crates, and SellService's two boards out to their far edges
-- (BoardSide, half a 7.2-wide board, its depth), from the riser's back (-9) to
-- the floor's front (+5). Its customers use the 7 studs in front. These are
-- the rectangles the placement search measured (2026-10-10); section 3 checks
-- the real stall's parts stay inside the first. Marigold walks 6.5 either side
-- of her spot on the riser and 2.2 to and fro (FairyService), her prompt with
-- her.
--==============================================================================
local HALF = S.BoardSide + 7.2 / 2 + 0.4
local SOLID = { x0 = -HALF, x1 = HALF, z0 = -9, z1 = 5 }
local CUSTOMERS = { x0 = -HALF, x1 = HALF, z0 = 5, z1 = 12 }
local GROUND = { x0 = -HALF, x1 = HALF, z0 = -9, z1 = 12 }
local WANDER = { x0 = -6.5, x1 = 6.5, z0 = -5.5 - 2.2, z1 = -5.5 + 2.2 }
local solidPts, customerPts = samples(SOLID, 0.5), samples(CUSTOMERS, 0.5)

-- The square's other fixtures, at their configs, by the size their builders
-- give them: the wheel's platform 15.2 across, the chests' plinths 5.6 x 4.4,
-- the pedestals' feet 5 and 8.4 square, the invite sign's 20-stud plate and
-- pillars over its pedestal, the shrine's base 11 across, the community
-- chest's step pad. A circle round each.
local function corner(w, d)
	return math.sqrt((w / 2) ^ 2 + (d / 2) ^ 2)
end
local CC = GameConfig.Community
local padAt = (CFrame.new(CC.Position) * CFrame.Angles(0, math.rad(CC.FacingDegrees), 0)):PointToWorldSpace(
	Vector3.new(0, 0, -CC.PadAhead))
local INV = GameConfig.InviteRewards
local fixtures = {
	{ name = "the wheel", at = flat(WheelData.Place.Position), r = 15.2 / 2 },
	{ name = "the bonus chest", at = flat(GameConfig.BonusChest.Position), r = corner(5.6, 4.4) },
	{ name = "the community chest", at = flat(CC.Position), r = corner(5.6, 4.4) },
	{ name = "its step pad", at = flat(padAt), r = CC.PadRadius },
	{ name = "the sacrifice pedestal", at = flat(GameConfig.Sacrifice.Position), r = corner(5, 5) },
	{ name = "the invite pedestal", at = flat(INV.Position), r = corner(INV.Pedestal.Foot.X, INV.Pedestal.Foot.Z) },
	{ name = "the invite sign", at = flat(INV.Position), r = INV.Sign.Width / 2 + INV.Sign.PillarWidth },
	{ name = "the rebirth shrine", at = flat(GameConfig.Rebirth.Position), r = 11 / 2 },
}

-- The ring of plots as MapService.Init lays it out (PlotLevelsSpec's): each
-- gate's frame, local -Z toward the hub.
local nPlots = 6
local startDepth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(GameConfig.StartingPlotTier))
local gates, centres = {}, {}
do
	local gap = math.rad(MAP.RoadGapDegrees)
	local step = (math.pi * 2 - gap) / nPlots
	local first = math.pi + gap * 0.5
	for id = 1, nPlots do
		local angle = first + (id - 0.5) * step
		local r = MAP.PlotRingInner + startDepth * 0.5
		local pos = Vector3.new(math.sin(angle) * r, MAP.GroundY, math.cos(angle) * r)
		centres[id] = CFrame.lookAt(pos, Vector3.new(0, MAP.GroundY, 0))
		gates[id] = centres[id] * CFrame.new(0, 0, -startDepth * 0.5)
	end
end

local function body()
	--==========================================================================
	say("1. The event plaza (Map.EventHub)")
	--==========================================================================
	local mapSrc = sourceOf(Server, "MapService")
	check(has(mapSrc, "deck.Size = Vector3.new(0.9, R * 2, R * 2)")
			and has(mapSrc, "deck.CFrame = CFrame.new(0, Y + 0.45, 0) * CFrame.Angles(0, 0, math.rad(90))")
			and has(mapSrc, "rim.Size = Vector3.new(0.6, R * 2 + 5, R * 2 + 5)"),
		"(the deck is still a 0.9-thick disc of HubRadius at the origin, its rim 2.5 wider)")
	check(E.Centre == Vector3.new(0, 0, 0) and E.Radius > 0 and E.Radius < MAP.HubRadius and E.FloorY == 0.9,
		"the plaza is the deck's middle, inside its edge, its floor the deck's top",
		string.format("r %s of the deck's %s", tostring(E.Radius), tostring(MAP.HubRadius)))
	local anchor = E.NpcAnchor
	check((flat(anchor.Position) - flat(E.Centre)).Magnitude + 6 <= E.Radius
			and math.abs(anchor.Position.Y - (MAP.GroundY + E.FloorY)) < 1e-6
			and anchor.LookVector:Dot(Vector3.new(0, 0, -1)) > 0.9999 and math.abs(anchor.UpVector.Y - 1) < 1e-6,
		"an event's NPC stands on its anchor: in the plaza with room round it, feet on the deck's top, upright, "
			.. "looking down the road (-Z)", tostring(anchor))
	check(E.ApproachWidth >= 12 and E.ApproachWidth <= E.Radius * 2 and E.MaxHeight > 0 and E.MaxHeight <= 14,
		"an open front at least 12 wide toward the road, and nothing an event builds over 14 tall (the surround "
			.. "brief's)", string.format("%s wide, %s tall", tostring(E.ApproachWidth), tostring(E.MaxHeight)))
	check(E.Floor.Rise > 0 and E.Floor.Rise <= 0.1 and E.Floor.EdgeWidth > 0 and E.Floor.EdgeWidth < E.Radius / 4,
		"the floor: a hair over the deck, a thin darker edge -- no machine, no monument")

	--==========================================================================
	say("2. Nothing permanent stands in it")
	--==========================================================================
	local clearOf = {}
	local nearest, nearestName = math.huge, ""
	for _, f in ipairs(fixtures) do
		local gap = (f.at - flat(E.Centre)).Magnitude - f.r - E.Radius
		if gap < nearest then
			nearest, nearestName = gap, f.name
		end
		if gap < 3 then
			table.insert(clearOf, string.format("%s (%.1f)", f.name, gap))
		end
	end
	local stallIn = math.huge
	for _, list in ipairs({ solidPts, customerPts }) do
		for _, p in ipairs(list) do
			stallIn = math.min(stallIn, (p - flat(E.Centre)).Magnitude - E.Radius)
		end
	end
	check(#clearOf == 0 and stallIn >= 20, string.format("every fixture's ground is 3 studs or more outside the plaza "
		.. "(nearest: %s, %.1f); the stall, Marigold, both boards and their customers %.1f", nearestName, nearest, stallIn),
		table.concat(clearOf, ", "))
	local spawnAt = Vector2.new(MAP.OverflowSpawn.X, MAP.OverflowSpawn.Z)
	-- The marker is a 10-stud square, centred there (MapService).
	local padNear = math.sqrt(math.max(math.abs(spawnAt.X) - 5, 0) ^ 2 + math.max(math.abs(spawnAt.Y) - 5, 0) ^ 2)
	check((spawnAt - flat(E.Centre)).Magnitude >= E.Radius + 5 and padNear > E.Radius
			and spawnAt.Magnitude < MAP.HubRadius - 5,
		"the overflow spawn: on the deck, a player's arrival 5 studs and more outside the plaza, its marker wholly out",
		string.format("at %.1f from the middle, the marker's nearest edge %.1f", spawnAt.Magnitude, padNear))

	-- THE MAP ITSELF, built as the SeedMapBuilder plugin builds it: MapService's
	-- Init in Edit, twice. A rebuild must change nothing.
	local MapService = require(Server:WaitForChild("MapService"))
	local function survey()
		local map = Workspace:FindFirstChild(MAP.FolderName)
		local s = { parts = 0, names = {}, at = {}, map = map }
		if not map then
			return s
		end
		for _, d in ipairs(map:GetDescendants()) do
			if d:IsA("BasePart") then
				s.parts += 1
				s.names[d.Name] = (s.names[d.Name] or 0) + 1
				if d.Parent and d.Parent.Name == "Hub" then
					table.insert(s.at, d.Name .. "@" .. tostring(d.CFrame))
				end
			end
		end
		table.sort(s.at)
		return s
	end
	local okA, errA = pcall(MapService.Init)
	local first = survey()
	local okB, errB = pcall(MapService.Init)
	local second = survey()
	check(okA and okB and first.parts > 1000 and first.parts == second.parts
			and table.concat(first.at, "|") == table.concat(second.at, "|"),
		"the map builds in Edit, and a second build is the first again: as many parts, the hub's each where it was",
		string.format("%s / %s; %d then %d parts", tostring(errA or "ok"), tostring(errB or "ok"), first.parts,
			second.parts))
	local map = second.map
	local n = second.names
	check(n.SellStand == 1 and n.StallFloor == 1 and n.StallRiser == 1 and n.CounterTop == 1
			and n[MAP.OverflowSpawnName] == 1 and n.EventPlaza == 1 and n.EventPlazaEdge == 1,
		"one stall, one overflow spawn, one plaza floor: no duplicates",
		string.format("SellStand %s, StallFloor %s, OverflowSpawn %s, EventPlaza %s", tostring(n.SellStand),
			tostring(n.StallFloor), tostring(n[MAP.OverflowSpawnName]), tostring(n.EventPlaza)))
	local fairy, fairies = nil, 0
	for _, m in ipairs(CollectionService:GetTagged(GameConfig.Tags.Fairy)) do
		if map and m:IsDescendantOf(map) then
			fairy = m
			fairies += 1
		end
	end
	check(fairies == 1, "one Marigold (a second Fairy would be a second shop: WeaponShopService prompts every one)",
		fairies)

	-- Every part of the map within the plaza's cylinder -- inside its radius,
	-- from just under the deck's top to MaxHeight over it -- is the floor.
	local deckTop = MAP.GroundY + E.FloorY
	local FLOOR = { Deck = true, DeckRim = true, EventPlaza = true, EventPlazaEdge = true }
	local inPlaza = {}
	if map then
		for _, d in ipairs(map:GetDescendants()) do
			if d:IsA("BasePart") and not FLOOR[d.Name] then
				local half = d.Size * 0.5
				local hit = false
				for h = deckTop - 0.4, deckTop + E.MaxHeight, 0.5 do
					local q = d.CFrame:PointToObjectSpace(Vector3.new(E.Centre.X, h, E.Centre.Z))
					local c = Vector3.new(math.clamp(q.X, -half.X, half.X), math.clamp(q.Y, -half.Y, half.Y),
						math.clamp(q.Z, -half.Z, half.Z))
					local w = d.CFrame:PointToWorldSpace(c)
					if (flat(w) - flat(E.Centre)).Magnitude < E.Radius and w.Y > deckTop - 0.4
						and w.Y < deckTop + E.MaxHeight then
						hit = true
						break
					end
				end
				if hit then
					table.insert(inPlaza, d:GetFullName())
				end
			end
		end
	end
	check(map ~= nil and #inPlaza == 0, "in the map, nothing but the deck and its floor stands in the plaza, to "
		.. E.MaxHeight .. " studs up", table.concat(inPlaza, ", ", 1, math.min(#inPlaza, 6)))
	local hub = map and map:FindFirstChild(MAP.PropsFolderName)
	hub = hub and hub:FindFirstChild("Hub")
	local plazaParts = {}
	for _, name in ipairs({ "EventPlazaEdge", "EventPlaza" }) do
		local p = hub and hub:FindFirstChild(name)
		if p then
			table.insert(plazaParts, p)
		end
	end
	local floorOk = #plazaParts == 2
	for i, p in ipairs(plazaParts) do
		local diameter = if i == 1 then E.Radius * 2 else (E.Radius - E.Floor.EdgeWidth) * 2
		local top = p.Position.Y + p.Size.X / 2
		floorOk = floorOk and p.Shape == Enum.PartType.Cylinder and not p.CanCollide and not p.CanQuery
			and not p.CanTouch and math.abs(p.Size.Y - diameter) < 1e-3 and math.abs(p.Size.Z - diameter) < 1e-3
			and p.CFrame.RightVector.Y > 0.9999 and (flat(p.Position) - flat(E.Centre)).Magnitude < 1e-3
			and top > deckTop and top <= deckTop + E.Floor.Rise + 0.03
	end
	check(floorOk, "its floor: two flat discs a hair over the deck, edge and middle, that nothing collides with, "
		.. "queries or touches")

	--==========================================================================
	say("3. Marigold's stall, beside the road's approach (Map.Stall)")
	--==========================================================================
	check(S.Position.Y == MAP.GroundY and S.FacingDegrees >= 0 and S.FacingDegrees < 360,
		"on the ground, facing one way (its origin the counter's centre)")
	local stand = hub and hub:FindFirstChild(MAP.SellStandName)
	check(stand ~= nil and (stand.CFrame.Position - (stallCF * CFrame.new(0, 2.4, 0)).Position).Magnitude < 1e-3
			and stand.CFrame.LookVector:Dot(stallCF.LookVector) > 0.9999,
		"the map's counter stands on the stall's frame", stand and tostring(stand.CFrame))
	-- Every part of the stall inside SOLID; Marigold at her spot.
	local outside, stallParts = {}, 0
	if hub then
		for _, d in ipairs(hub:GetDescendants()) do
			if d:IsA("BasePart") and not FLOOR[d.Name] and not (fairy and d:IsDescendantOf(fairy)) then
				stallParts += 1
				local h = d.Size * 0.5
				for _, sx in ipairs({ -1, 1 }) do
					for _, sy in ipairs({ -1, 1 }) do
						for _, sz in ipairs({ -1, 1 }) do
							local w = (d.CFrame * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
							if rectDist(flat(w), SOLID) > 1e-3 then
								table.insert(outside, d.Name)
							end
						end
					end
				end
			end
		end
	end
	check(stallParts >= 20 and #outside == 0, string.format("all %d of its parts stand inside the ground it was placed "
		.. "by (%.1f x 14)", stallParts, HALF * 2), table.concat(outside, ", ", 1, math.min(#outside, 6)))
	local herAt = fairy and fairy.PrimaryPart and flat(fairy.PrimaryPart.Position)
	check(herAt ~= nil and (herAt - stallPoint(0, -5.5)).Magnitude < 0.05,
		"Marigold starts on her spot on the riser, behind the counter's middle", herAt)
	-- The boards: SellService's, from Map.Stall -- each BoardSide off the
	-- floor's middle (2 back of the origin) and BoardFront toward the front,
	-- turned to the point BoardFocus out in front.
	local boardsIn = true
	for _, side in ipairs({ -1, 1 }) do
		local foot = Vector2.new(side * S.BoardSide, -2 + S.BoardFront)
		local toward = (Vector2.new(0, S.BoardFocus) - foot).Unit
		local across = Vector2.new(toward.Y, -toward.X) * (7.2 / 2)
		for _, e in ipairs({ foot + across, foot - across }) do
			boardsIn = boardsIn and math.abs(e.X) <= HALF and e.Y >= SOLID.z0 and e.Y <= SOLID.z1
		end
	end
	check(boardsIn, "both boards, turned toward their customers, inside it too")
	-- Her wander on the riser (22 x 7 at -5.5): her 2-stud body never off it.
	check(WANDER.x0 - 1 >= -11 and WANDER.x1 + 1 <= 11 and WANDER.z0 - 0.5 >= -9 and WANDER.z1 + 0.5 <= -2,
		"her whole wander, her body's width included, is on her riser behind the counter")
	local rimGap = math.huge
	for _, p in ipairs(solidPts) do
		rimGap = math.min(rimGap, p.Magnitude - RIM)
	end
	check(rimGap >= 1, string.format("wholly off the deck, on the grass: %.1f studs past the rim", rimGap))
	local fieldGap = math.huge
	for _, list in ipairs({ solidPts, customerPts }) do
		for _, p in ipairs(list) do
			fieldGap = math.min(fieldGap, MAP.FieldWidth * 0.5 - math.abs(p.X), p.Y + MAP.FieldFront, MAP.FieldBack - p.Y)
		end
	end
	check(fieldGap >= 8 and MapService.IsInSafeZone(stallCF.Position),
		string.format("inside the safe area, %.1f studs in from its edge", fieldGap))
	check(S.Position.Z < -MAP.HubRadius and S.Position.Z > -MAP.FieldFront and math.abs(S.Position.X) <= 50,
		"beside the road's approach: between the deck and the mouth, within 50 studs of the running line")
	local runGap, custGap = math.huge, math.huge
	for _, p in ipairs(solidPts) do
		runGap = math.min(runGap, segDist(p, ROAD_A, ROAD_B))
	end
	for _, p in ipairs(customerPts) do
		custGap = math.min(custGap, segDist(p, ROAD_A, ROAD_B))
	end
	check(runGap >= 14 and custGap >= 8, string.format("off the running line: the stall %.1f studs from it, its "
		.. "customers %.1f (14 and 8 asked)", runGap, custGap))
	-- The walks: the hub to each gate, each gate to the road's mouth, the hub
	-- to the obby -- 7 studs clear, the sacrifice pedestal's own rule (12 for
	-- the obby's).
	local walks = {}
	for id = 1, nPlots do
		local g = flat(gates[id].Position)
		table.insert(walks, { name = "the hub to plot " .. id, a = Vector2.zero, b = g, clear = 7 })
		table.insert(walks, { name = "plot " .. id .. " to the road", a = g, b = MOUTH, clear = 7 })
	end
	table.insert(walks, { name = "the hub to the obby", a = Vector2.zero, b = Vector2.new(246, -24), clear = 12 })
	local walkGap, walkName = math.huge, ""
	for _, w in ipairs(walks) do
		for _, p in ipairs(solidPts) do
			local d = segDist(p, w.a, w.b) - w.clear
			if d < walkGap then
				walkGap, walkName = d, w.name
			end
		end
	end
	check(walkGap >= 0, string.format("on no walk: 7 studs and more from each (12 from the obby's); least to spare "
		.. "%.2f (%s)", walkGap, walkName))
	-- Facing the way in: its front looks across the running line and up into
	-- the square.
	local front = Vector2.new(math.sin(math.rad(S.FacingDegrees)), math.cos(math.rad(S.FacingDegrees)))
	local function off(target)
		local d = (target - flat(stallCF.Position)).Unit
		return math.deg(math.acos(math.clamp(front:Dot(d), -1, 1)))
	end
	local crossZ = S.Position.Z + front.Y * (-S.Position.X / front.X)
	check(front.X * S.Position.X < 0 and crossZ < 0 and crossZ > -MAP.FieldFront
			and off(Vector2.new(0, S.Position.Z)) <= 30 and off(flat(E.Centre)) <= 45,
		"its counter faces the way players arrive: across the running line, and up into the square",
		string.format("crosses the line at z %.1f; %.0f off square to it, %.0f off the plaza", crossZ,
			off(Vector2.new(0, S.Position.Z)), off(flat(E.Centre))))
	-- Every fixture of the square, and the Disco Mill's ground.
	local fixGap, fixName = math.huge, ""
	for _, f in ipairs(fixtures) do
		local d = math.min(rectDist(f.at, SOLID), rectDist(f.at, CUSTOMERS)) - f.r
		if d < fixGap then
			fixGap, fixName = d, f.name
		end
	end
	local disco
	for _, k in ipairs(GameConfig.MiniEvent.Dancers.KeepClear) do
		if k.Name == "DiscoMill" then
			disco = k
		end
	end
	local discoGap = math.min(rectDist(flat(disco.At), SOLID), rectDist(flat(disco.At), CUSTOMERS)) - disco.Radius
	check(fixGap >= 7 and discoGap >= 7, string.format("clear of every fixture in the square, its customers' ground "
		.. "too: %.1f studs from the nearest (%s), %.1f from the Disco Mill's circle", fixGap, fixName, discoGap))
	-- Every plot, at every level: its fenced footprint (GameConfig.plotFootprint,
	-- the fence's boards 0.8 out) against the stall and its customers.
	local groundPoly = cornersOf(GROUND)
	local plotGap, plotAt = math.huge, ""
	for id = 1, nPlots do
		for level = 1, #GameConfig.PlotTiers do
			for _, r in ipairs(GameConfig.plotFootprint(level, id)) do
				local poly = {}
				for _, c in ipairs({ { r.x0 - 0.8, r.d0 - 0.8 }, { r.x1 + 0.8, r.d0 - 0.8 }, { r.x1 + 0.8, r.d1 + 0.8 },
					{ r.x0 - 0.8, r.d1 + 0.8 } }) do
					table.insert(poly, flat((gates[id] * CFrame.new(c[1], 0, c[2])).Position))
				end
				local g = polyGap(groundPoly, poly)
				if g < plotGap then
					plotGap, plotAt = g, string.format("plot %d, level %d", id, level)
				end
			end
		end
	end
	check(plotGap >= 20, string.format("clear of every plot at every level: %.1f studs to the nearest fence (%s)",
		plotGap, plotAt))

	--==========================================================================
	say("4. The prompts: no two share ground")
	--==========================================================================
	-- Each further from another than their reaches added (memory: hub deck
	-- prompt map). The boards' prompts over their feet; Marigold's on her,
	-- anywhere in her wander.
	local sellAll = stallPoint(-S.BoardSide, S.BoardFront - 2)
	local sellOne = stallPoint(S.BoardSide, S.BoardFront - 2)
	local sellSrc = sourceOf(Server, "SellService")
	local shopSrc = sourceOf(Server, "WeaponShopService")
	check(has(sellSrc, "prompt.MaxActivationDistance = 12")
			and has(sellSrc, "prompt.MaxActivationDistance = SELL_ONE.PromptDistance")
			and has(sellSrc, "local base = stall.CFrame * CFrame.new(side * SIDE_OFFSET, 0, FRONT_OFFSET)")
			and has(sellSrc, "prompt.Parent = board")
			and has(shopSrc, "local anchor = fairy:FindFirstChild(\"Torso\") or fairy.PrimaryPart"),
		"(SELL ALL reaches 12, SELL ONE its config's, both on their boards; Marigold's prompt rides her Torso)")
	local ours = {
		{ name = "SELL ALL", reach = 12, d = function(p)
			return (p - sellAll).Magnitude
		end },
		{ name = "SELL ONE", reach = GameConfig.SellOne.PromptDistance, d = function(p)
			return (p - sellOne).Magnitude
		end },
		{ name = "Marigold", reach = GameConfig.Weapon.PromptDistance, d = function(p)
			return rectDist(p, WANDER)
		end },
	}
	local theirs = {
		{ name = "the wheel", at = flat(WheelData.Place.Position) + Vector2.new(0, 6.3),
			reach = WheelData.Place.PromptDistance },
		{ name = "the bonus chest", at = flat(GameConfig.BonusChest.Position),
			reach = GameConfig.BonusChest.PromptDistance },
		{ name = "the sacrifice pedestal", at = flat(GameConfig.Sacrifice.Position),
			reach = GameConfig.Sacrifice.PromptDistance },
		{ name = "the invite pedestal", at = flat(INV.Position), reach = INV.PromptDistance },
		{ name = "the rebirth shrine", at = flat(GameConfig.Rebirth.Position), reach = GameConfig.Rebirth.PromptDistance },
		{ name = "the community chest's pad", at = flat(padAt), reach = CC.PadReach },
	}
	for id = 1, nPlots do
		local base = GameConfig.plotSignBase(centres[id], GameConfig.StartingPlotTier)
		table.insert(theirs, { name = "plot " .. id .. "'s board", at = flat(base.Position),
			reach = GameConfig.Mill.Sign.PromptRange })
	end
	local spare, spareAt = math.huge, ""
	for _, a in ipairs(ours) do
		for _, b in ipairs(theirs) do
			local d = a.d(b.at) - a.reach - b.reach
			if d < spare then
				spare, spareAt = d, a.name .. " and " .. b.name
			end
		end
	end
	check(spare > 1, string.format("the stall's three share ground with no other prompt in the square or any plot's "
		.. "board: %.1f studs to spare at the least (%s)", spare, spareAt))
	-- Among themselves they always did (SELL ALL asks a 1.1 s hold; GameConfig
	-- .Weapon): unchanged, the stall's frame moved whole.
	-- (CFrames are single precision.)
	check(math.abs((sellAll - sellOne).Magnitude - S.BoardSide * 2) < 1e-3
			and math.abs(rectDist(sellOne, WANDER) - (S.BoardSide - 6.5)) < 0.01
			and has(sellSrc, "prompt.HoldDuration = 1.1"),
		"(among themselves as before: the boards 31 apart, Marigold 9 from SELL ONE at her nearest, SELL ALL held 1.1 s)")

	--==========================================================================
	say("5. Finding it from the road")
	--==========================================================================
	local M = GameConfig.Weapon.FloatingWords
	local shopAt = stallCF:PointToWorldSpace(Vector3.new(0, 2.4 + M.Above, M.Front))
	local farthest = 0
	for z = -MAP.FieldFront, -MAP.HubRadius, 2 do
		farthest = math.max(farthest, (shopAt - Vector3.new(0, MAP.GroundY + 5, z)).Magnitude)
	end
	check(farthest < FloatingSign.Distance - 10, string.format("BAT SHOP! is in reach from the road's mouth on: %.0f "
		.. "studs at most, it shows to %.0f", farthest, FloatingSign.Distance))
	-- Eyes on the running line and either edge of it, from just inside the
	-- mouth (the night shutter stands at it) to the deck.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map }
	local blocked, rays, firstBlock = 0, 0, nil
	for z = -MAP.FieldFront + 4, -MAP.HubRadius, 4 do
		for _, x in ipairs({ -12, 0, 12 }) do
			local eye = Vector3.new(x, MAP.GroundY + 5, z)
			local hit = Workspace:Raycast(eye, shopAt - eye, params)
			rays += 1
			if hit then
				blocked += 1
				firstBlock = firstBlock or string.format("from (%d, %d): %s", x, z, hit.Instance:GetFullName())
			end
		end
	end
	check(map ~= nil and rays > 90 and blocked == 0,
		string.format("and nothing of the map stands between it and any of %d eyes on the running line", rays), firstBlock)

	--==========================================================================
	say("6. The mini events keep clear of it all")
	--==========================================================================
	local MINI = GameConfig.MiniEvent
	check(MINI.Area.Centre == E.Centre and MINI.Area.MinRadius >= E.Radius + MINI.Area.Clearance,
		"the tickets' hub ring starts outside the plaza, its clearance included",
		string.format("from %s", tostring(MINI.Area.MinRadius)))
	local function entry(list, name)
		for _, k in ipairs(list) do
			if k.Name == name then
				return k
			end
		end
		return nil
	end
	local function is(k, at, radius)
		return k ~= nil and (k.At - at).Magnitude < 1e-6 and k.Radius == radius
	end
	local spawn3 = Vector3.new(MAP.OverflowSpawn.X, 0, MAP.OverflowSpawn.Z)
	local invite3 = Vector3.new(INV.Position.X, 0, INV.Position.Z)
	local tk = MINI.KeepClear
	check(is(entry(tk, "Stall"), GameConfig.hubStallPoint(0, -2), 16)
			and is(entry(tk, "SellAll"), GameConfig.hubStallPoint(-S.BoardSide, S.BoardFront - 2), 4)
			and is(entry(tk, "SellOne"), GameConfig.hubStallPoint(S.BoardSide, S.BoardFront - 2), 4)
			and is(entry(tk, "Spawn"), spawn3, 9) and is(entry(tk, "EventHub"), E.Centre, E.Radius)
			and is(entry(tk, "InvitePedestal"), invite3, 8),
		"the tickets keep off the stall, both boards, the overflow spawn, the plaza and the invite pedestal -- each "
			.. "from the config")
	local dk = MINI.Dancers.KeepClear
	check(is(entry(dk, "Spawn"), spawn3, 14) and is(entry(dk, "EventHub"), E.Centre, E.Radius)
			and is(entry(dk, "Stall"), GameConfig.hubStallPoint(0, -2), 22) and is(entry(dk, "InvitePedestal"), invite3, 8),
		"the dancers likewise")
	local stale = {}
	for _, list in ipairs({ tk, dk }) do
		for _, k in ipairs(list) do
			for _, old in ipairs({ Vector3.new(0, 0, 16), Vector3.new(0, 0, 17), Vector3.new(15.5, 0, 18),
				Vector3.new(-15.5, 0, 18) }) do
				if (k.At - old).Magnitude < 1 then
					table.insert(stale, k.Name)
				end
			end
			if k.Name == "Spawn" and k.At.Magnitude < 1 then
				table.insert(stale, "Spawn at the middle")
			end
		end
	end
	check(#stale == 0, "nothing kept clear at the stall's or the spawn's old spots", table.concat(stale, ", "))
	local onGround, seen, firstOn = 0, 0, nil
	for i = 1, 400 do
		for _, pick in ipairs(DancerPlacement.Picks(string.format("eventhub%04dspec", i))) do
			seen += 1
			local at = flat(pick.at)
			local why = nil
			if (at - flat(E.Centre)).Magnitude < E.Radius + pick.radius then
				why = "the plaza"
			elseif rectDist(at, GROUND) < pick.radius then
				why = "the stall's ground"
			elseif math.max(math.abs(at.X - spawnAt.X), math.abs(at.Y - spawnAt.Y)) < 5 + pick.radius then
				why = "the overflow spawn"
			end
			if why then
				onGround += 1
				firstOn = firstOn or string.format("%s at (%.1f, %.1f)", why, at.X, at.Y)
			end
		end
	end
	check(seen > 2000 and onGround == 0, string.format("no dancer of 400 discos (%d) stands in the plaza, on the "
		.. "stall's or its customers' ground or on the overflow spawn", seen), firstOn)

	--==========================================================================
	say("7. Built from the config: nothing left at the old spot")
	--==========================================================================
	check(has(mapSrc, "local stallCF = GameConfig.hubStallCFrame()") and not has(mapSrc, "CFrame.new(0, Y, 15)")
			and has(mapSrc, "cframe = CFrame.new(MAP.OverflowSpawn.X, Y + MAP.OverflowSpawn.Y, MAP.OverflowSpawn.Z),")
			and has(mapSrc, "return CFrame.new(MAP.OverflowSpawn.X, Y + MAP.OverflowSpawn.Y + 5, MAP.OverflowSpawn.Z)")
			and has(mapSrc, "local E = MAP.EventHub") and has(mapSrc, "cframe = stallCF * CFrame.new(0, 0.3, -2)")
			and has(mapSrc, "HubFairy.build(stallCF * CFrame.new(0, 2, -5.5) * CFrame.Angles(0, math.pi, 0), hub)"),
		"MapService: the stall from Map.Stall, the spawn from Map.OverflowSpawn, the plaza from Map.EventHub")
	check(has(sellSrc, "local SIDE_OFFSET = STALL.BoardSide") and has(sellSrc, "local FRONT_OFFSET = STALL.BoardFront")
			and has(sellSrc, "GameConfig.hubStallCFrame():PointToWorldSpace(Vector3.new(0, 0, STALL.BoardFocus))")
			and not has(sellSrc, "Vector3.new(0, ground.Y, 0) - ground"),
		"SellService: the boards from Map.Stall, turned to its customers, not to the world's middle")
	local nestSrc = sourceOf(Server, "NestService")
	check(has(nestSrc, "local hub = GameConfig.Map.EventHub.Centre - nest.origin")
			and not has(nestSrc, "GetOverflowCFrame().Position - nest.origin"),
		"NestService pushes toward the hub's centre, not the spawn's marker (flattened, the same way as before)")
	local fairySrc = sourceOf(Server, "FairyService")
	check(has(fairySrc, "local WANDER_X = 6.5") and has(fairySrc, "local WANDER_Z = 2.2"),
		"(FairyService still wanders her 6.5 x 2.2, the box measured above)")
	local obbyUI = sourceOf(Scripts, "ObbyUI")
	check(has(obbyUI, "Spin it at the wheel in the square.") and not has(obbyUI, "by Marigold"),
		"the obby's hint no longer puts the wheel by Marigold")
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

say(string.format("\nEventHubSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
