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
--   3. the shop row west of the road's mouth (2026-10-10, the owner: "transfer
--      them here, shop, rebirth, everything"; Map.Stall's comment): every
--      fixture on the grass inside Map.ShopRow, facing north; the stall's
--      real parts inside the ground it was measured for, Marigold's wander on
--      her riser; 6 studs and more off every plot at every level, walkways
--      between them, clear of the weather screen, every walk and the running
--      line
--   4. the prompts: none of the row's shares ground with another or with any
--      plot's board (the mills' signs: MillPlacementSpec)
--   5. finding the shops: BAT SHOP! and SPIN THE WHEEL! in reach and in sight
--      from the field in front of the row
--   6. the mini events: the tickets' ring outside the plaza, no ticket or
--      dancer zone on the row; both keep-clear lists from the configs,
--      nothing at old spots; no dancer of 400 discos in the plaza
--   7. the sources: built from the config, nothing left at the old spots
--   8. the front fence (2026-10-10, the owner: "add a fence on the edges of
--      the map" -- the front edge, solid): along the red line from the
--      corridor's walls to the field's corners, unclimbable, unjumpable, off
--      every plot at every level, the safe zone unchanged
--
-- Not here, seen in Play instead: the prompts pressed in the row, the routes
-- walked (PathfindingService from every gate and the road's mouth), the row
-- and its words from the field, the fence stopping a player, an event's
-- cleanup leaving it all as it was.
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

--==============================================================================
-- THE SHOP ROW'S FIXTURES (2026-10-10): each one's frame from its own config,
-- the ground it and its customers stand on in that frame -- its builder's
-- sizes: the wheel's arch 18.2 wide over its 15.2 platform, the invite
-- pedestal's pillars 7.9 out beside its 8.4 foot, the shrine's 11 base, the
-- pedestal's 5 foot and 5-wide signs, the chests' 5.6 x 4.4 plinths with the
-- bonus chest's board behind and the community chest's circle 6.5 in front --
-- with 5 studs more for the customers on its front, and its prompt (the
-- community chest's circle, which reaches PadReach). `front` is the side the
-- fixture faces: the stall's and the wheel's +Z, the rest -Z.
--==============================================================================
local function frameOf(position, degrees)
	return CFrame.new(position) * CFrame.Angles(0, math.rad(degrees), 0)
end
local WP = WheelData.Place
local RB = GameConfig.Rebirth
local SC = GameConfig.Sacrifice
local BC = GameConfig.BonusChest
local ROW = {
	{ name = "the stall", frame = stallCF, box = GROUND, front = 1, y = S.Position.Y },
	{ name = "the wheel", frame = frameOf(WP.Position, WP.FacingDegrees), box = { x0 = -9.1, x1 = 9.1, z0 = -7.6, z1 = 13 },
		front = 1, y = WP.Position.Y, prompt = Vector3.new(0, 0, 6.3), reach = WP.PromptDistance },
	{ name = "the invite pedestal", frame = frameOf(INV.Position, INV.FacingDegrees),
		box = { x0 = -7.9, x1 = 7.9, z0 = -9.2, z1 = 4.2 }, front = -1, y = INV.Position.Y, prompt = Vector3.zero,
		reach = INV.PromptDistance },
	{ name = "the rebirth shrine", frame = frameOf(RB.Position, RB.FacingDegrees),
		box = { x0 = -5.5, x1 = 5.5, z0 = -10.5, z1 = 5.5 }, front = -1, y = RB.Position.Y, prompt = Vector3.zero,
		reach = RB.PromptDistance },
	{ name = "the sacrifice pedestal", frame = frameOf(SC.Position, SC.FacingDegrees),
		box = { x0 = -3, x1 = 3, z0 = -8, z1 = 3 }, front = -1, y = SC.Position.Y, prompt = Vector3.zero,
		reach = SC.PromptDistance },
	{ name = "the bonus chest", frame = frameOf(BC.Position, BC.FacingDegrees),
		box = { x0 = -3, x1 = 3, z0 = -7.2, z1 = 3.5 }, front = -1, y = BC.Position.Y, prompt = Vector3.zero,
		reach = BC.PromptDistance },
	{ name = "the community chest", frame = frameOf(CC.Position, CC.FacingDegrees),
		box = { x0 = -3.4, x1 = 3.4, z0 = -11, z1 = 2.6 }, front = -1, y = CC.Position.Y,
		prompt = Vector3.new(0, 0, -CC.PadAhead), reach = CC.PadReach },
}
-- A fixture's ground as a world outline, and points round its edge a stud
-- apart.
local function outlineOf(f)
	local b, out = f.box, {}
	for _, c in ipairs({ { b.x0, b.z0 }, { b.x1, b.z0 }, { b.x1, b.z1 }, { b.x0, b.z1 } }) do
		table.insert(out, flat(f.frame:PointToWorldSpace(Vector3.new(c[1], 0, c[2]))))
	end
	return out
end
local function edgeOf(f)
	local poly, pts = outlineOf(f), {}
	for i = 1, 4 do
		local a, b = poly[i], poly[i % 4 + 1]
		local n = math.max(1, math.ceil((b - a).Magnitude))
		for k = 0, n - 1 do
			table.insert(pts, a + (b - a) * (k / n))
		end
	end
	return pts
end
-- The front fence's field-side face and its runs' inner ends (MapService).
local FENCE_FACE = -MAP.FieldFront + 1.6
local FENCE_FROM = MAP.CorridorWidth * 0.5 + MAP.WallThickness

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
	say("3. The shop row, west of the road's mouth (Map.Stall, Map.ShopRow)")
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
	-- The whole row: every fixture on the grass, facing north into the field,
	-- its ground and its customers' inside Map.ShopRow.
	local row = MAP.ShopRow
	local notIn, notNorth, notGround = {}, {}, {}
	for _, f in ipairs(ROW) do
		for _, p in ipairs(outlineOf(f)) do
			if p.X < row.From.X - 1e-3 or p.X > row.To.X + 1e-3 or p.Y < row.From.Y - 1e-3 or p.Y > row.To.Y + 1e-3 then
				table.insert(notIn, f.name)
				break
			end
		end
		local look = f.frame.LookVector * -f.front
		if look.Z < math.cos(math.rad(1)) then
			table.insert(notNorth, string.format("%s (%.2f, %.2f)", f.name, look.X, look.Z))
		end
		if f.y ~= MAP.GroundY then
			table.insert(notGround, f.name)
		end
	end
	check(#notIn == 0 and #notNorth == 0 and #notGround == 0,
		string.format("all %d fixtures stand on the grass in Map.ShopRow, facing north into the field", #ROW),
		table.concat(notIn, ", ") .. " | " .. table.concat(notNorth, ", ") .. " | " .. table.concat(notGround, ", "))
	-- The row's ground: inside the field, west of the road's mouth (beyond the
	-- corridor's wall line), clear of the front fence, off the deck and far
	-- from the plaza.
	local rowNear = Vector2.new(math.clamp(0, row.From.X, row.To.X), math.clamp(0, row.From.Y, row.To.Y)).Magnitude
	check(row.From.X >= -MAP.FieldWidth * 0.5 + 8 and row.To.X <= -FENCE_FROM and row.From.Y >= FENCE_FACE + 1
			and row.To.Y < -RIM and rowNear > RIM + 1 and MapService.IsInSafeZone(Vector3.new(row.From.X, 0, row.From.Y))
			and MapService.IsInSafeZone(Vector3.new(row.To.X, 0, row.To.Y)),
		"the row's ground: inside the field and the safe zone, west of the road's mouth, off the deck, clear of the "
			.. "front fence", string.format("x %s..%s z %s..%s, %.1f from the middle", tostring(row.From.X),
			tostring(row.To.X), tostring(row.From.Y), tostring(row.To.Y), rowNear))
	-- Every plot, at every level: its fenced footprint (GameConfig.plotFootprint,
	-- the fence's boards 0.8 out) against every fixture and its customers.
	local plotGap, plotAt = math.huge, ""
	for id = 1, nPlots do
		for level = 1, #GameConfig.PlotTiers do
			for _, r in ipairs(GameConfig.plotFootprint(level, id)) do
				local poly = {}
				for _, c in ipairs({ { r.x0 - 0.8, r.d0 - 0.8 }, { r.x1 + 0.8, r.d0 - 0.8 }, { r.x1 + 0.8, r.d1 + 0.8 },
					{ r.x0 - 0.8, r.d1 + 0.8 } }) do
					table.insert(poly, flat((gates[id] * CFrame.new(c[1], 0, c[2])).Position))
				end
				for _, f in ipairs(ROW) do
					local g = polyGap(outlineOf(f), poly)
					if g < plotGap then
						plotGap, plotAt = g, string.format("%s and plot %d at level %d", f.name, id, level)
					end
				end
			end
		end
	end
	check(plotGap >= 6, string.format("6 studs and more off every plot at every level: %.1f to the nearest fence (%s)",
		plotGap, plotAt))
	-- Walkways: every two fixtures' grounds 7 apart and more.
	local wayGap, wayAt = math.huge, ""
	for i = 1, #ROW do
		for j = i + 1, #ROW do
			local g = polyGap(outlineOf(ROW[i]), outlineOf(ROW[j]))
			if g < wayGap then
				wayGap, wayAt = g, ROW[i].name .. " and " .. ROW[j].name
			end
		end
	end
	check(wayGap >= 7, string.format("a walkway between any two: %.1f studs at the narrowest (%s)", wayGap, wayAt))
	-- The weather screen by the mouth (WeatherTeaser, in the map), the walks,
	-- the running line and the Disco Mill's ground.
	local teaser = map and map:FindFirstChild(MAP.PropsFolderName)
	teaser = teaser and teaser:FindFirstChild("WeatherTeaser")
	local tvGap = math.huge
	for _, d in ipairs(if teaser then teaser:GetDescendants() else {}) do
		if d:IsA("BasePart") then
			local h = d.Size * 0.5
			local poly = {}
			for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } }) do
				table.insert(poly, flat(d.CFrame:PointToWorldSpace(Vector3.new(h.X * c[1], 0, h.Z * c[2]))))
			end
			for _, f in ipairs(ROW) do
				tvGap = math.min(tvGap, polyGap(outlineOf(f), poly))
			end
		end
	end
	check(teaser ~= nil and tvGap >= 5, string.format("clear of the weather screen by the mouth: %.1f studs", tvGap))
	local walks = {}
	for id = 1, nPlots do
		local g = flat(gates[id].Position)
		table.insert(walks, { name = "the hub to plot " .. id, a = Vector2.zero, b = g, clear = 7 })
		table.insert(walks, { name = "plot " .. id .. " to the road", a = g, b = MOUTH, clear = 7 })
	end
	table.insert(walks, { name = "the hub to the obby", a = Vector2.zero, b = Vector2.new(246, -24), clear = 12 })
	table.insert(walks, { name = "the running line", a = ROAD_A, b = ROAD_B, clear = 14 })
	local disco
	for _, k in ipairs(GameConfig.MiniEvent.Dancers.KeepClear) do
		if k.Name == "DiscoMill" then
			disco = k
		end
	end
	local walkGap, walkName, discoGap = math.huge, "", math.huge
	for _, f in ipairs(ROW) do
		for _, p in ipairs(edgeOf(f)) do
			for _, w in ipairs(walks) do
				local d = segDist(p, w.a, w.b) - w.clear
				if d < walkGap then
					walkGap, walkName = d, string.format("%s, %s", f.name, w.name)
				end
			end
			discoGap = math.min(discoGap, (p - flat(disco.At)).Magnitude - disco.Radius)
		end
	end
	check(walkGap >= 0 and discoGap >= 7, string.format("on no walk -- 7 studs and more from each walk between the hub, "
		.. "the gates and the road's mouth, 12 from the obby's, 14 from the running line; least to spare %.1f (%s); "
		.. "%.1f from the Disco Mill's circle", walkGap, walkName, discoGap))

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
	-- Every prompt of the row, the stall's three counted apart: a point and a
	-- reach each, Marigold's anywhere in her wander.
	local prompts = {
		{ owner = "the stall", name = "SELL ALL", reach = 12, d = function(p)
			return (p - sellAll).Magnitude
		end },
		{ owner = "the stall", name = "SELL ONE", reach = GameConfig.SellOne.PromptDistance, d = function(p)
			return (p - sellOne).Magnitude
		end },
		{ owner = "the stall", name = "Marigold", reach = GameConfig.Weapon.PromptDistance, d = function(p)
			return rectDist(p, WANDER)
		end },
	}
	for _, f in ipairs(ROW) do
		if f.prompt then
			local at = flat(f.frame:PointToWorldSpace(f.prompt))
			table.insert(prompts, { owner = f.name, name = f.name, at = at, reach = f.reach, d = function(p)
				return (p - at).Magnitude
			end })
		end
	end
	local boards = {}
	for id = 1, nPlots do
		local base = GameConfig.plotSignBase(centres[id], GameConfig.StartingPlotTier)
		table.insert(boards, { name = "plot " .. id .. "'s board", at = flat(base.Position),
			reach = GameConfig.Mill.Sign.PromptRange })
	end
	local spare, spareAt = math.huge, ""
	for i, a in ipairs(prompts) do
		for j, b in ipairs(prompts) do
			if j > i and a.owner ~= b.owner then
				-- A point prompt against the other's own distance rule.
				local d = (if b.at then a.d(b.at) else b.d(a.at)) - a.reach - b.reach
				if d < spare then
					spare, spareAt = d, a.name .. " and " .. b.name
				end
			end
		end
		for _, b in ipairs(boards) do
			local d = a.d(b.at) - a.reach - b.reach
			if d < spare then
				spare, spareAt = d, a.name .. " and " .. b.name
			end
		end
	end
	check(#prompts == 9 and spare > 1, string.format("no prompt of the row shares ground with another fixture's or any "
		.. "plot's board: %.1f studs to spare at the least (%s)", spare, spareAt))
	-- Among themselves they always did (SELL ALL asks a 1.1 s hold; GameConfig
	-- .Weapon): unchanged, the stall's frame moved whole.
	-- (CFrames are single precision.)
	check(math.abs((sellAll - sellOne).Magnitude - S.BoardSide * 2) < 1e-3
			and math.abs(rectDist(sellOne, WANDER) - (S.BoardSide - 6.5)) < 0.01
			and has(sellSrc, "prompt.HoldDuration = 1.1"),
		"(among themselves as before: the boards 31 apart, Marigold 9 from SELL ONE at her nearest, SELL ALL held 1.1 s)")

	--==========================================================================
	say("5. Finding the shops")
	--==========================================================================
	-- BAT SHOP! over the stall's roof, SPIN THE WHEEL! over the wheel's arch
	-- (WheelModel: 3.4 over its 20-stud arch, 1.6 behind its middle).
	local M = GameConfig.Weapon.FloatingWords
	local shopAt = stallCF:PointToWorldSpace(Vector3.new(0, 2.4 + M.Above, M.Front))
	local spinAt = frameOf(WP.Position, WP.FacingDegrees):PointToWorldSpace(Vector3.new(0, 23.4, -1.6))
	-- From the field in front of the row, where the plots' players come from,
	-- on ground no plot ever takes (plot 1 grows toward the row's east end):
	-- eyes 6 studs up west of it, and in the pocket before the stall. Every one
	-- in reach of both words, and nothing of the map between.
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map }
	local eyes = {}
	for x = -255, -195, 10 do
		for _, z in ipairs({ -100, -85 }) do
			table.insert(eyes, Vector3.new(x, MAP.GroundY + 6, z))
		end
	end
	for _, z in ipairs({ -138, -128 }) do
		table.insert(eyes, Vector3.new(-128, MAP.GroundY + 6, z))
	end
	local far, blocked, firstBlock = 0, 0, nil
	for _, eye in ipairs(eyes) do
		for _, word in ipairs({ shopAt, spinAt }) do
			far = math.max(far, (word - eye).Magnitude)
			local hit = Workspace:Raycast(eye, word - eye, params)
			if hit then
				blocked += 1
				firstBlock = firstBlock or string.format("from (%d, %d): %s", eye.X, eye.Z, hit.Instance:GetFullName())
			end
		end
	end
	check(map ~= nil and far < FloatingSign.Distance and blocked == 0, string.format("BAT SHOP! and SPIN THE WHEEL! in "
		.. "reach (%.0f at most; they show to %.0f) and in sight from %d eyes in the field before the row", far,
		FloatingSign.Distance, #eyes), firstBlock)
	-- From the road's mouth, measured, not ruled: the weather screen stands
	-- between it and the row.
	local seenFromMouth, mouthEyes = 0, 0
	for x = -60, 0, 10 do
		for z = -MAP.FieldFront + 6, -MAP.FieldFront + 46, 10 do
			local eye = Vector3.new(x, MAP.GroundY + 5, z)
			mouthEyes += 1
			if (shopAt - eye).Magnitude < FloatingSign.Distance and not Workspace:Raycast(eye, shopAt - eye, params) then
				seenFromMouth += 1
			end
		end
	end
	say(string.format("  NOTE  from the road's mouth BAT SHOP! is in reach and in sight from %d of %d eyes",
		seenFromMouth, mouthEyes))

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
	check(is(entry(dk, "Wheel"), Vector3.new(WP.Position.X, 0, WP.Position.Z), 9)
			and is(entry(dk, "BonusChest"), Vector3.new(BC.Position.X, 0, BC.Position.Z), 8)
			and is(entry(dk, "CommunityChest"), Vector3.new(CC.Position.X, 0, CC.Position.Z), 8)
			and is(entry(dk, "Pedestal"), Vector3.new(SC.Position.X, 0, SC.Position.Z), 8)
			and is(entry(dk, "RebirthShrine"), Vector3.new(RB.Position.X, 0, RB.Position.Z), 8),
		"and keep each shop-row fixture at its own config's spot")
	-- No ticket or dancer zone reaches the row at all.
	local zoneReach, boxOnRow = MINI.Area.MaxRadius, false
	for _, z in ipairs(MINI.Zones) do
		if z.Kind == "ring" then
			zoneReach = math.max(zoneReach, z.MaxRadius)
		elseif z.Kind == "box" and z.X1 >= row.From.X and z.X0 <= row.To.X and z.Z1 >= row.From.Y and z.Z0 <= row.To.Y then
			boxOnRow = true
		end
	end
	for _, z in ipairs(MINI.Dancers.Zones) do
		zoneReach = math.max(zoneReach, z.MaxRadius)
	end
	check(rowNear > zoneReach + 10 and not boxOnRow, string.format("no ticket or dancer zone reaches the row: they end "
		.. "%.0f from the middle, the row starts %.0f out, west of the front box", zoneReach, rowNear))
	local stale = {}
	for _, list in ipairs({ tk, dk }) do
		for _, k in ipairs(list) do
			for _, old in ipairs({ Vector3.new(0, 0, 16), Vector3.new(0, 0, 17), Vector3.new(15.5, 0, 18),
				Vector3.new(-15.5, 0, 18), Vector3.new(0, 0, 38), Vector3.new(-40, 0, -6), Vector3.new(-31, 0, -22),
				Vector3.new(14, 0, -38), Vector3.new(45, 0, 36), Vector3.new(-11, 0, -35), Vector3.new(35.9, 0, -58.7) }) do
				if (k.At - old).Magnitude < 1 then
					table.insert(stale, k.Name)
				end
			end
			if k.Name == "Spawn" and k.At.Magnitude < 1 then
				table.insert(stale, "Spawn at the middle")
			end
		end
	end
	check(#stale == 0, "nothing kept clear at a fixture's or the spawn's old spot", table.concat(stale, ", "))
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
	check(has(obbyUI, "Spin it at the wheel by Marigold's shop.") and not has(obbyUI, "in the square"),
		"the obby's hint sends players to the wheel by Marigold's shop")
	local rebirthSrc = sourceOf(Server, "RebirthService")
	local communitySrc = sourceOf(Server, "CommunityService")
	check(has(rebirthSrc, "local origin = CFrame.new(at) * CFrame.Angles(0, math.rad(CFG.FacingDegrees), 0)")
			and not has(rebirthSrc, "CFrame.lookAt(at, Vector3.new(0, at.Y, 0))")
			and has(communitySrc, "local groundTop = COMMUNITY.Position.Y") and not has(communitySrc, "deckTop"),
		"the shrine turns by its config, not toward the world's middle; the community chest's circle lies on its own "
			.. "ground, not the deck's height")
	local decorSrc = sourceOf(Server, "MapDecor")
	check(has(decorSrc, "if prop and (onAPlot(prop) or inTheWay(prop)) then") and has(decorSrc, "local row = MAP.ShopRow"),
		"the field's decor keeps off the shop row and the front fence")

	--==========================================================================
	say("8. The front fence (MapService)")
	--==========================================================================
	-- Along the red line either side of the road's mouth, from the corridor's
	-- walls to the field's corners: the plot fences' boards with the slot
	-- between them shut flush (no Humanoid climbs it), and an invisible wall over
	-- it to the corridor walls' height (nobody jumps it).
	local props = map and map:FindFirstChild(MAP.PropsFolderName)
	local fence = props and props:FindFirstChild("FrontFence")
	local runs, wrong = {}, {}
	local half = MAP.FieldWidth * 0.5
	for _, d in ipairs(if fence then fence:GetChildren() else {}) do
		if d:IsA("BasePart") then
			local side = if d.Position.X < 0 then -1 else 1
			local key = side .. d.Name
			runs[key] = (runs[key] or 0) + 1
			local lo, hi = d.Position.X - d.Size.X / 2, d.Position.X + d.Size.X / 2
			if d.Name ~= "Post" and (math.abs(math.abs(lo) - FENCE_FROM) > 1e-3 and math.abs(math.abs(hi) - FENCE_FROM) > 1e-3
				or math.abs(math.abs(lo) - half) > 1e-3 and math.abs(math.abs(hi) - half) > 1e-3) then
				table.insert(wrong, d.Name .. " short")
			end
			if math.abs(d.Position.Z - (-MAP.FieldFront + 0.8)) > 1e-3 or math.abs(d.Size.Z - 1.6) > 1e-3 and d.Name ~= "Post"
				or not d.CanCollide or not d.Anchored then
				table.insert(wrong, d.Name .. " off the line or not solid")
			end
		end
	end
	local blockerTop = -math.huge
	for _, d in ipairs(if fence then fence:GetChildren() else {}) do
		if d.Name == "Blocker" then
			blockerTop = math.max(blockerTop, d.Position.Y + d.Size.Y / 2)
			if d.Transparency ~= 1 then
				table.insert(wrong, "Blocker visible")
			end
		end
	end
	check(fence ~= nil and runs["-1Rail"] == 2 and runs["1Rail"] == 2 and runs["-1RailGap"] == 1 and runs["1RailGap"] == 1
			and runs["-1Blocker"] == 1 and runs["1Blocker"] == 1 and (runs["-1Post"] or 0) >= 10 and (runs["1Post"] or 0) >= 10
			and #wrong == 0 and math.abs(blockerTop - (MAP.GroundY + MAP.WallHeight)) < 1e-3,
		"two runs, each the corridor's wall to the field's corner on the field's edge: two boards, the slot shut, posts, "
			.. "and an invisible wall to the corridor walls' height -- all solid",
		table.concat(wrong, ", ", 1, math.min(#wrong, 6)))
	-- The safe zone is what it was: just inside the fence is in, just past it
	-- out.
	check(MapService.IsInSafeZone(Vector3.new(-150, 3, FENCE_FACE + 1)) and MapService.IsInSafeZone(Vector3.new(150, 3,
		FENCE_FACE + 1)) and not MapService.IsInSafeZone(Vector3.new(-150, 3, -MAP.FieldFront - 1)),
		"inside the fence is the safe zone, past it is not: the boundary did not move")
	-- No plot at any level reaches it; the shop row stands clear of it.
	local fenceGap, fenceAt = math.huge, ""
	for id = 1, nPlots do
		for level = 1, #GameConfig.PlotTiers do
			for _, r in ipairs(GameConfig.plotFootprint(level, id)) do
				for _, c in ipairs({ { r.x0 - 0.8, r.d0 - 0.8 }, { r.x1 + 0.8, r.d0 - 0.8 }, { r.x1 + 0.8, r.d1 + 0.8 },
					{ r.x0 - 0.8, r.d1 + 0.8 } }) do
					local w = flat((gates[id] * CFrame.new(c[1], 0, c[2])).Position)
					if math.abs(w.X) >= FENCE_FROM and w.Y - FENCE_FACE < fenceGap then
						fenceGap, fenceAt = w.Y - FENCE_FACE, string.format("plot %d at level %d", id, level)
					end
				end
			end
		end
	end
	check(fenceGap >= 2 and row.From.Y - FENCE_FACE >= 1, string.format("no plot at any level comes within %.1f studs of "
		.. "it (%s); the shop row's ground %.1f", fenceGap, fenceAt, row.From.Y - FENCE_FACE))
	-- The field's decor keeps off the row and the fence.
	local decor = props and props:FindFirstChild("FieldDecor")
	local onRow, onFence = {}, {}
	for _, d in ipairs(if decor then decor:GetDescendants() else {}) do
		if d:IsA("BasePart") then
			local h = d.Size * 0.5
			for _, sx in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					local w = d.CFrame:PointToWorldSpace(Vector3.new(h.X * sx, 0, h.Z * sz))
					if w.X >= row.From.X - 3 and w.X <= row.To.X + 3 and w.Z >= row.From.Y - 3 and w.Z <= row.To.Y + 3 then
						onRow[d.Parent and d.Parent.Name or d.Name] = true
					end
					if math.abs(w.X) >= FENCE_FROM - 3 and w.Z <= FENCE_FACE + 3 then
						onFence[d.Parent and d.Parent.Name or d.Name] = true
					end
				end
			end
		end
	end
	local function names(set)
		local list = {}
		for k in pairs(set) do
			table.insert(list, k)
		end
		return list
	end
	check(decor ~= nil and #names(onRow) == 0 and #names(onFence) == 0,
		"no tree, hedge or flower of the field's stands on the shop row or against the fence",
		table.concat(names(onRow), ", ") .. " | " .. table.concat(names(onFence), ", "))
	check(has(mapSrc, "fence.Name = \"FrontFence\"") and has(mapSrc, "local inner = MAP.CorridorWidth * 0.5 + MAP.WallThickness")
			and has(mapSrc, "local blocker = build({ name = \"Blocker\", size = Vector3.new(length, MAP.WallHeight - FENCE_TOP, FENCE_THICK),"),
		"(MapService builds it from the map's own numbers)")
end

local ok, err = pcall(body)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

say(string.format("\nEventHubSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
