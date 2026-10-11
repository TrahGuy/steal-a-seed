--!strict
-- Steal a Seed :: RainBiome
--
-- The Rain event's temporary terrain, built and taken down by WeatherService
-- (NOT a *Service: geometry and a few pure answers, no lifecycle).
--
--==============================================================================
-- WHAT IT BUILDS, AND WHERE
--
-- Off the island's EAST edge (+X), square to the -Z road -- no part of
-- Starbloom and no sixth segment. Every number is GameConfig.Weather.Biome's:
--
--   the RAMP     a wedge up from the grass inside the hedge line, 60 wide
--   the DECK     a railed bridge, 9 studs up, over the hedges and the gap
--   the DESCENT  a wedge down into the first room
--   the ROUTE    round rooms joined by straight corridors (Biome.Route), every
--                corridor the ROAD'S OWN USABLE WIDTH (Map.CorridorWidth, the
--                clear floor between a biome's walls) under the road's own
--                wall height: the ENTRANCE (the mouth and the long approach),
--                the RAIN GARDEN (the pond room and the corridor out of it),
--                the OVERGROWN PASSAGE (a hollow and the last corridor) and
--                the NEST CLEARING. It bends gently, keeps north of the obby's
--                course, and is about as long as Greenhollow and Dustbowl
--                together.
--   the NEST     a visible, EMPTY moss-bedded platform ringed with stones and
--                roots at the clearing's CENTRE; the EncounterSite marker at
--                its own centre is the extension point for the guardian, the
--                Secret Egg and the plant the owner supplies later, and an
--                open ring of floor round it is the guardian's room. Nothing
--                here spawns, rewards or fights, and nothing is collectible.
--   the SCENERY  rain-soaked dressing from MapDecor's own sculpting kit: broad
--                leaves held up to the rain, drooping reeds, hanging vines and
--                vine arches, ferns, mossy roots, pale-blue flower patches,
--                puddles, runoff down the walls, fallen branches and
--                moss-covered stones -- clustered along the walls and round
--                the rooms' rims, the middle of the route (the guardian's
--                lane) kept open. Never collidable, never queried, never
--                touched.
--   the GATE     a curtain across the top of the ramp -- solid while the
--                biome is opening and closing, gone while it is open
--
-- The white clouds are NOT built here: every client builds its own from
-- Shared/RainClouds (Weather.client), so the server holds no part of them.
--
-- All of it lives in ONE folder under Workspace, Archivable = false like the
-- map, so a Publish or a save can never carry it, and WeatherService destroys
-- the folder whole. Every part is tagged (RainTerrain, RainGate or
-- RainEncounterSite), so every client fades the whole biome away together
-- when the rain ends. Nothing of the island is touched: no part of the map is
-- moved, hidden or rebuilt, and the deck simply passes over the hedges.
--
-- WHY A WEDGE RAMP AND NOT A GAP IN THE HEDGE: the hedges along the field's
-- edge are MapDecor's and the map is not this file's to change. The ramp rises
-- 9 studs over 18 -- a 27-degree slope a Humanoid walks without noticing -- and
-- the deck clears the 7-stud hedge with room to spare.
--
-- HOW THE ROUTE CLOSES: a corridor's two walls run from where they meet one
-- room's circle to where they meet the next; a room's wall is a ring of
-- panels with an opening for each corridor (and, in the first room, for the
-- bridge's foot, measured off its corners); a pillar stands at every joint.
-- The floor is a disc under each ring and a slab between the discs' chords,
-- so nothing overlaps and nothing gapes. RainEventSpec walks the built
-- route: floor under every step, nothing solid in the guardian's lane.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local MapDecor = require(script.Parent:WaitForChild("MapDecor"))
local SafeZoneMarking = require(script.Parent:WaitForChild("SafeZoneMarking"))

local W = GameConfig.Weather
local B = W.Biome
local TAGS = W.Tags
local MAP = GameConfig.Map
local Y = MAP.GroundY
local C = B.Colours
local T = B.WallThickness
local H = B.WallHeight
local Kit, Props = MapDecor.Kit, MapDecor.Props
local RAD = math.rad
local TAU = math.pi * 2

local RainBiome = {}

--==============================================================================
-- THE ROUTE, AS ARITHMETIC
--==============================================================================
type Node = { x: number, z: number, r: number, w: number, section: string }
export type Segment = {
	i: number,
	a: Vector3,
	b: Vector3,
	dir: Vector3,
	side: Vector3,
	length: number,
	w: number,
	-- Half the corridor's width plus half a wall: where a wall's centre runs.
	hw: number,
	section: string,
}
export type Box = { name: string, x0: number, x1: number, z0: number, z1: number }

local ROUTE: { Node } = B.Route
local SEGS: { Segment } = {}
for i = 1, #ROUTE - 1 do
	local n0, n1 = ROUTE[i], ROUTE[i + 1]
	local a = Vector3.new(n0.x, Y, n0.z)
	local b = Vector3.new(n1.x, Y, n1.z)
	local d = b - a
	local dir = d.Unit
	table.insert(SEGS, {
		i = i,
		a = a,
		b = b,
		dir = dir,
		side = Vector3.new(-dir.Z, 0, dir.X),
		length = d.Magnitude,
		w = n0.w,
		hw = n0.w / 2 + T / 2,
		section = n0.section,
	})
end

-- Where a line `half` studs off a circle's centre meets the circle: its
-- distance along the centreline. Zero when the line misses it.
local function chord(radius: number, half: number): number
	return math.sqrt(math.max(0, radius * radius - half * half))
end

function RainBiome.Segments(): { Segment }
	return SEGS
end

-- The usable width of every corridor: the road's own.
function RainBiome.CorridorWidth(): number
	return ROUTE[1].w
end

-- The walk from the foot of the ramp to the nest: the bridge, the descent's
-- foot to the first room, every corridor, and the clearing to the nest.
function RainBiome.RouteLength(): number
	local total = B.Descent.X1 - B.Ramp.X0
	local first = ROUTE[1]
	total += (Vector3.new(first.x, 0, first.z) - Vector3.new(B.Descent.X1, 0, B.Deck.Z)).Magnitude
	for _, s in ipairs(SEGS) do
		total += s.length
	end
	local last = ROUTE[#ROUTE]
	total += (Vector3.new(B.Nest.X, 0, B.Nest.Z) - Vector3.new(last.x, 0, last.z)).Magnitude
	return total
end

-- Every room's and corridor's footprint, wall included, as world x/z boxes.
function RainBiome.Footprints(): { Box }
	local boxes: { Box } = {}
	for j, n in ipairs(ROUTE) do
		local reach = n.r + T
		table.insert(boxes, { name = string.format("room %d (%s)", j, n.section),
			x0 = n.x - reach, x1 = n.x + reach, z0 = n.z - reach, z1 = n.z + reach })
	end
	for _, s in ipairs(SEGS) do
		local half = s.hw + T / 2
		local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
		for _, c in ipairs({ s.a + s.side * half, s.a - s.side * half, s.b + s.side * half, s.b - s.side * half }) do
			x0, x1 = math.min(x0, c.X), math.max(x1, c.X)
			z0, z1 = math.min(z0, c.Z), math.max(z1, c.Z)
		end
		table.insert(boxes, { name = string.format("corridor %d (%s)", s.i, s.section), x0 = x0, x1 = x1, z0 = z0, z1 = z1 })
	end
	return boxes
end

-- Points down the middle of the route, `step` studs apart, from the descent's
-- foot to the edge of the nest's own ring in the clearing, each with the
-- leg's clear half-width there and the leg's sideways direction. The floor
-- runs at least that wide the whole way: a corridor's slab under its walls,
-- a room's disc under its ring.
function RainBiome.Centreline(step: number): { { at: Vector3, half: number, side: Vector3 } }
	local points = {}
	local first = Vector3.new(ROUTE[1].x, Y, ROUTE[1].z)
	local foot = Vector3.new(B.Descent.X1, Y, B.Deck.Z)
	local run = { { a = foot, b = first, half = B.Deck.Width / 2 } }
	for _, s in ipairs(SEGS) do
		local b = s.b
		if s.i == #SEGS then
			b = s.b - s.dir * (B.Nest.ClearRing.Inner + 4)
		end
		table.insert(run, { a = s.a, b = b, half = s.w / 2 })
	end
	for _, leg in ipairs(run) do
		local d = leg.b - leg.a
		local dir = d.Unit
		local n = math.max(1, math.floor(d.Magnitude / step))
		for k = 0, n do
			table.insert(points, { at = leg.a + d * (k / n), half = leg.half, side = Vector3.new(-dir.Z, 0, dir.X) })
		end
	end
	return points
end

--==============================================================================
-- PURE ANSWERS
--==============================================================================
local function nearRoute(x: number, z: number): boolean
	local reach = B.Reach
	for _, n in ipairs(ROUTE) do
		local dx, dz = x - n.x, z - n.z
		local r = n.r + T + reach
		if dx * dx + dz * dz <= r * r then
			return true
		end
	end
	for _, s in ipairs(SEGS) do
		local px, pz = x - s.a.X, z - s.a.Z
		local t = px * s.dir.X + pz * s.dir.Z
		if t >= 0 and t <= s.length then
			local u = px * s.side.X + pz * s.side.Z
			if math.abs(u) <= s.hw + T / 2 + reach then
				return true
			end
		end
	end
	return false
end

-- Is a world position on the event's terrain -- the ramp, the bridge, a
-- corridor or a room? Within the walls (and a little beyond them) and within
-- a band of height, so a player in the air over the bridge counts and one
-- who has fallen off it does not.
function RainBiome.Contains(position: Vector3): boolean
	if position.Y < Y - B.Height.Below or position.Y > Y + B.Height.Above then
		return false
	end
	local D = B.Deck
	if position.X >= B.Ramp.X0 and position.X <= B.Descent.X1
		and math.abs(position.Z - D.Z) <= D.Width / 2 + B.Reach then
		return true
	end
	return nearRoute(position.X, position.Z)
end

function RainBiome.LandingCount(): number
	return B.Landing.Columns * B.Landing.Rows
end

-- The i-th landing spot (1-based): a grid on the grass before the ramp,
-- Spread studs apart, every one on permanent island ground and facing the
-- biome. Past the grid it wraps, which only a server fuller than the grid
-- could reach.
function RainBiome.LandingSpot(i: number): CFrame
	local L = B.Landing
	local index = (math.max(1, math.floor(i)) - 1) % RainBiome.LandingCount()
	local col = index % L.Columns
	local row = math.floor(index / L.Columns)
	local z = L.Z + (col - (L.Columns - 1) / 2) * L.Spread
	local x = L.X - row * L.Spread
	local at = Vector3.new(x, Y + 3.2, z)
	return CFrame.lookAt(at, at + Vector3.new(10, 0, 0))
end

-- Is a landing spot free to stand on: nothing solid in a body's room there
-- (ignoring `ignore`, the evacuee's own character), and ground under it.
function RainBiome.SpotClear(cf: CFrame, ignore: { Instance }): boolean
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = ignore
	overlap.RespectCanCollide = true
	local blocking = Workspace:GetPartBoundsInBox(cf * CFrame.new(0, 0.2, 0), Vector3.new(4, 5.6, 4), overlap)
	if #blocking > 0 then
		return false
	end
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = ignore
	ray.RespectCanCollide = true
	return Workspace:Raycast(cf.Position, Vector3.new(0, -12, 0), ray) ~= nil
end

--==============================================================================
-- THE STRUCTURE: floors, walls, pillars, the bridge, the gate, the nest
--==============================================================================
type PartOpts = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	collide: boolean?,
	transparency: number?,
	parent: Instance,
	studs: boolean?,
	shape: Enum.PartType?,
}

-- MapService's own recipe, so the biome is the same plastic as the island it
-- hangs off -- smooth and faintly reflective here, because it is wet.
local function build(o: PartOpts): BasePart
	local p = Instance.new("Part")
	p.Name = o.name
	if o.shape then
		p.Shape = o.shape
	end
	p.Size = o.size
	p.CFrame = o.cframe
	p.Color = o.color
	p.Material = o.material or Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = o.collide ~= false
	p.Transparency = o.transparency or 0
	p.TopSurface = (o.studs ~= false) and Enum.SurfaceType.Studs or Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = o.parent
	return p
end

local function terrainPart(o: PartOpts): BasePart
	local p = build(o)
	CollectionService:AddTag(p, TAGS.Terrain)
	return p
end

local SLATE = Enum.Material.SmoothPlastic

local function buildFloors(parent: Instance)
	-- A disc under every room, out to the foot of its ring.
	for j, n in ipairs(ROUTE) do
		local d = (n.r + T) * 2
		local disc = terrainPart({
			name = "RoomFloor" .. j,
			shape = Enum.PartType.Cylinder,
			size = Vector3.new(MAP.FieldThickness, d, d),
			cframe = CFrame.new(n.x, Y - MAP.FieldThickness / 2, n.z) * CFrame.Angles(0, 0, math.pi / 2),
			color = if j == #ROUTE then C.Room else C.Floor,
			material = SLATE,
			parent = parent,
			studs = false,
		})
		disc.Reflectance = 0.06
	end
	-- A slab for every corridor, from one disc's chord to the next's, so the
	-- two never overlap and never part.
	for _, s in ipairs(SEGS) do
		local half = s.w / 2 + T
		local p0 = s.a + s.dir * chord(ROUTE[s.i].r + T, half)
		local p1 = s.b - s.dir * chord(ROUTE[s.i + 1].r + T, half)
		local mid = (p0 + p1) / 2
		local slab = terrainPart({
			name = "CorridorFloor" .. s.i,
			size = Vector3.new(half * 2, MAP.FieldThickness, (p1 - p0).Magnitude),
			cframe = CFrame.lookAt(mid, mid + s.dir) * CFrame.new(0, -MAP.FieldThickness / 2, 0),
			color = C.Floor,
			material = SLATE,
			parent = parent,
			studs = false,
		})
		slab.Reflectance = 0.06
	end
end

-- A wall slab, T thick and H tall, standing on the ground from p to q, studded
-- on the face the player sees like the road's own.
local function wallBetween(parent: Instance, name: string, p: Vector3, q: Vector3)
	local d = q - p
	local mid = (p + q) / 2 + Vector3.new(0, H / 2, 0)
	local wall = terrainPart({
		name = name,
		size = Vector3.new(T, H, d.Magnitude),
		cframe = CFrame.lookAt(mid, mid + d.Unit),
		color = C.Wall,
		material = SLATE,
		parent = parent,
		studs = false,
	})
	wall.LeftSurface = Enum.SurfaceType.Studs
	wall.RightSurface = Enum.SurfaceType.Studs
end

-- A pillar at every joint, placed once however many walls meet there.
local function pillarMaker(parent: Instance): (Vector3) -> ()
	local placed: { [string]: boolean } = {}
	return function(at: Vector3)
		local key = string.format("%d:%d", math.round(at.X * 2), math.round(at.Z * 2))
		if placed[key] then
			return
		end
		placed[key] = true
		local dia = T + 6
		local h = H + 1.5
		terrainPart({
			name = "Pillar",
			shape = Enum.PartType.Cylinder,
			size = Vector3.new(h, dia, dia),
			cframe = CFrame.new(at.X, Y + h / 2, at.Z) * CFrame.Angles(0, 0, math.pi / 2),
			color = C.Pillar,
			material = SLATE,
			parent = parent,
			studs = false,
		})
	end
end

-- `bare`: no corridor wall meets the ring at this opening's edges (the
-- bridge's), so the panels end clean and no pillar narrows the bridge.
type Opening = { a: number, h: number, bare: boolean? }

-- A room's openings: the corridor in, the corridor out, and in the first room
-- the bridge's foot, from its two corners. Angles round the room's centre (0
-- along +X, a quarter turn along +Z), each with the half-angle it subtends.
local function openingsOf(j: number): { Opening }
	local n = ROUTE[j]
	local list: { Opening } = {}
	if j == 1 then
		local D = B.Deck
		local a1 = math.atan2(D.Z - D.Width / 2 - n.z, B.Descent.X1 - n.x)
		local a2 = math.atan2(D.Z + D.Width / 2 - n.z, B.Descent.X1 - n.x)
		if a2 - a1 > math.pi then
			a1 += TAU
		elseif a1 - a2 > math.pi then
			a2 += TAU
		end
		local mid = (a1 + a2) / 2
		if mid > math.pi then
			mid -= TAU
		end
		table.insert(list, { a = mid, h = math.abs(a2 - a1) / 2 + math.asin(math.min(1, 2 / n.r)), bare = true })
	else
		local s = SEGS[j - 1]
		table.insert(list, { a = math.atan2(-s.dir.Z, -s.dir.X), h = math.asin(math.min(1, s.hw / n.r)) })
	end
	if j < #ROUTE then
		local s = SEGS[j]
		table.insert(list, { a = math.atan2(s.dir.Z, s.dir.X), h = math.asin(math.min(1, s.hw / n.r)) })
	end
	table.sort(list, function(p, q)
		return p.a < q.a
	end)
	return list
end

local function onCircle(n: Node, angle: number, radius: number): Vector3
	return Vector3.new(n.x + math.cos(angle) * radius, Y, n.z + math.sin(angle) * radius)
end

-- The ring round a room: panels along every arc between two openings, a
-- pillar at each joint; the arcs' ends are at the room's own radius, where
-- the corridors' walls end, so the same pillar closes both.
local function buildRing(parent: Instance, j: number, pillar: (Vector3) -> ())
	local n = ROUTE[j]
	local ringR = n.r + T / 2
	local list = openingsOf(j)
	for k = 1, #list do
		local from = list[k].a + list[k].h
		local nxt = list[k % #list + 1]
		local to = nxt.a - nxt.h + (if k == #list then TAU else 0)
		if to - from > 0.03 then
			local count = math.max(1, math.ceil((to - from) * ringR / B.PanelLength))
			local span = (to - from) / count
			for m = 0, count - 1 do
				local a0 = from + m * span
				local mid = a0 + span / 2
				local centre = onCircle(n, mid, ringR) + Vector3.new(0, H / 2, 0)
				local tangent = Vector3.new(-math.sin(mid), 0, math.cos(mid))
				local panel = terrainPart({
					name = "RingWall",
					size = Vector3.new(T, H, 2 * ringR * math.sin(span / 2) + 1.2),
					cframe = CFrame.lookAt(centre, centre + tangent),
					color = C.Wall,
					material = SLATE,
					parent = parent,
					studs = false,
				})
				panel.LeftSurface = Enum.SurfaceType.Studs
				panel.RightSurface = Enum.SurfaceType.Studs
				if m > 0 then
					pillar(onCircle(n, a0, ringR))
				end
			end
			if not list[k].bare then
				pillar(onCircle(n, from, n.r))
			end
			if not nxt.bare then
				pillar(onCircle(n, to, n.r))
			end
		end
	end
end

local function buildWalls(parent: Instance)
	local pillar = pillarMaker(parent)
	-- Each corridor's two walls, from one room's circle to the next's.
	for _, s in ipairs(SEGS) do
		local a0 = chord(ROUTE[s.i].r, s.hw)
		local a1 = chord(ROUTE[s.i + 1].r, s.hw)
		if a0 + a1 < s.length - 1 then
			for _, side in ipairs({ -1, 1 }) do
				local p = s.a + s.dir * a0 + s.side * (side * s.hw)
				local q = s.b - s.dir * a1 + s.side * (side * s.hw)
				wallBetween(parent, "CorridorWall" .. s.i, p, q)
				pillar(p)
				pillar(q)
			end
		end
	end
	for j = 1, #ROUTE do
		buildRing(parent, j, pillar)
	end
end

-- A wedge from the grass up to the deck's height (or down from it): its thin
-- edge at local -Z, its full height at local +Z, so a quarter turn points the
-- rise toward +X and three quarters points it back toward -X.
local function wedge(parent: Instance, name: string, x0: number, x1: number, rise: number, risesEast: boolean)
	local w = Instance.new("WedgePart")
	w.Name = name
	w.Size = Vector3.new(B.Deck.Width, rise, x1 - x0)
	w.CFrame = CFrame.new((x0 + x1) / 2, Y + rise / 2, B.Deck.Z)
		* CFrame.Angles(0, if risesEast then math.rad(90) else math.rad(-90), 0)
	w.Color = C.Deck
	w.Material = Enum.Material.Plastic
	w.Anchored = true
	w.CanCollide = true
	w.TopSurface = Enum.SurfaceType.Smooth
	w.BottomSurface = Enum.SurfaceType.Smooth
	w.Parent = parent
	CollectionService:AddTag(w, TAGS.Terrain)
end

--==============================================================================
-- THE SAFE LINE AT THE BRIDGE (2026-10-02)
--
-- The road's own red line (GameConfig.Map SafeLine*), painted across the deck
-- where the safe zone ends -- MapService.IsInSafeZone's edge, x = half the
-- field's width -- with its OUTER edge exactly on that boundary, as the road's
-- is, so the paint and the check never disagree. The island side is safe and
-- says so on the deck. Built with the biome and faded and removed with it.
--==============================================================================
function RainBiome.SafeLineX(): number
	return MAP.FieldWidth * 0.5
end

local function buildSafeLine(parent: Instance)
	local deck = B.Deck
	local edge = RainBiome.SafeLineX()
	local line = terrainPart({
		name = "SafeLine",
		size = Vector3.new(MAP.SafeLineThickness, 0.4, deck.Width),
		cframe = CFrame.new(edge - MAP.SafeLineThickness * 0.5, Y + deck.Y + 0.2, deck.Z),
		color = MAP.SafeLineColor,
		material = Enum.Material.SmoothPlastic,
		collide = false,
		parent = parent,
		studs = false,
	})
	line.CanQuery = false
	-- The words on the safe side: the road's own SAFE ZONE marking, shields and
	-- all (the owner, 2026-10-11: like the general biomes'), at
	-- W.SafeLine.PixelsPerStud so it fits between the deck's safe end and the
	-- line, and turned to read left to right for a runner coming home along -X.
	local safeFrom, safeTo = deck.X0, edge - MAP.SafeLineThickness
	local mark = SafeZoneMarking.build(parent, CFrame.new((safeFrom + safeTo) * 0.5, Y + deck.Y + 0.15, deck.Z)
		* CFrame.Angles(0, -math.pi / 2, 0), W.SafeLine.PixelsPerStud)
	CollectionService:AddTag(mark, TAGS.Terrain)
end

local function buildBridge(parent: Instance)
	local R, deck, D = B.Ramp, B.Deck, B.Descent
	wedge(parent, "Ramp", R.X0, R.X1, R.Rise, true)
	wedge(parent, "Descent", D.X0, D.X1, deck.Y, false)
	terrainPart({
		name = "Deck",
		size = Vector3.new(deck.X1 - deck.X0, deck.Thickness, deck.Width),
		cframe = CFrame.new((deck.X0 + deck.X1) / 2, Y + deck.Y - deck.Thickness / 2, deck.Z),
		color = C.Deck,
		parent = parent,
	})
	-- A rail and its posts down both sides of the deck.
	for _, side in ipairs({ -1, 1 }) do
		local z = deck.Z + side * (deck.Width / 2 - 0.5)
		terrainPart({
			name = "Rail",
			size = Vector3.new(deck.X1 - deck.X0, 0.5, 0.7),
			cframe = CFrame.new((deck.X0 + deck.X1) / 2, Y + deck.Y + B.RailHeight, z),
			color = C.Rail,
			parent = parent,
			studs = false,
		})
		for x = deck.X0 + 2, deck.X1 - 2, 8 do
			terrainPart({
				name = "Post",
				size = Vector3.new(0.8, B.RailHeight + 0.5, 0.8),
				cframe = CFrame.new(x, Y + deck.Y + (B.RailHeight + 0.5) / 2, z),
				color = C.Rail,
				parent = parent,
				studs = false,
			})
		end
	end
end

local function buildGate(parent: Instance): BasePart
	local G = B.Gate
	local gate = build({
		name = "Gate",
		size = Vector3.new(1.5, G.Height, G.Width),
		cframe = CFrame.new(G.X, Y + G.Height / 2, B.Deck.Z),
		color = C.Gate,
		material = SLATE,
		transparency = 0.5,
		parent = parent,
		studs = false,
	})
	gate.CanTouch = false
	gate.CastShadow = false
	CollectionService:AddTag(gate, TAGS.Gate)
	return gate
end

-- The reserved site's marker at the nest's centre: invisible, nothing to walk
-- into, and tagged for whatever is placed there later. Reserved = true says
-- nothing has been.
local function buildSite(parent: Instance)
	local N = B.Nest
	local site = build({
		name = B.EncounterSiteName,
		size = Vector3.new(40, 1, 40),
		cframe = CFrame.new(N.X, Y + 0.5, N.Z),
		color = C.Room,
		transparency = 1,
		collide = false,
		parent = parent,
		studs = false,
	})
	site.CanQuery = false
	site.CanTouch = false
	site:SetAttribute("Reserved", true)
	site:SetAttribute("Label", B.Label)
	site:SetAttribute("NestRadius", N.Radius)
	CollectionService:AddTag(site, TAGS.Site)
end

-- The nest: one low moss-bedded disc anybody can step onto (the only solid
-- piece of dressing), a darker bowl inset in it, stones round the rim with
-- moss on every third and the odd bloom, a moss bed, and four roots arching
-- in over the rim -- none from the side the route comes in.
local function buildNest(parent: Instance, rng: Random)
	local N = B.Nest
	local at = CFrame.new(N.X, Y, N.Z)
	terrainPart({
		name = "NestPlatform",
		shape = Enum.PartType.Cylinder,
		size = Vector3.new(1, N.Radius * 2, N.Radius * 2),
		cframe = at * CFrame.new(0, 0.5, 0) * CFrame.Angles(0, 0, math.pi / 2),
		color = C.NestBed,
		material = SLATE,
		parent = parent,
		studs = false,
	})
	local m = Kit.group(parent, "NestDressing")
	Kit.disc(m, "Bowl", at * CFrame.new(0, 1, 0), 0.22, (N.Radius - 4) * 2, C.NestBowl, Kit.Opts.CYL_SMOOTH)
	for i = 1, N.Stones do
		local a = (i - 1) / N.Stones * TAU + Kit.jitter(rng, RAD(6))
		local f = Kit.radial(at, a, N.Radius - 0.6)
		local s = rng:NextNumber(1, 1.5)
		Kit.piece(m, "RimStone", Vector3.new(3.2, 2.2, 2.6) * s,
			f * CFrame.new(0, 1 + 0.8 * s, 0)
				* CFrame.Angles(RAD(rng:NextNumber(-12, 12)), Kit.jitter(rng, RAD(25)), RAD(rng:NextNumber(-10, 10))),
			if i % 2 == 0 then C.Stone else C.StoneDark, Kit.Opts.STUDDED)
		if i % 3 == 0 then
			Kit.piece(m, "Moss", Vector3.new(2.2, 0.45, 1.8) * s, f * CFrame.new(0, 1 + 1.7 * s, 0), C.Moss, Kit.Opts.SMOOTH)
		elseif i % 4 == 0 then
			Kit.piece(m, "Bloom", Vector3.new(0.7, 0.7, 0.7), f * CFrame.new(0.6, 1 + 1.9 * s, 0.3), C.Flower, Kit.Opts.BALL_SMOOTH)
		end
	end
	for i = 1, 6 do
		Kit.piece(m, "Bed", Vector3.new(5, 0.3, 2.6), Kit.radial(at, (i - 0.5) / 6 * TAU, N.Radius - 4.4) * CFrame.new(0, 1.1, 0),
			C.MossPale, Kit.Opts.SMOOTH)
	end
	for i = 1, 4 do
		local a = RAD(45 + (i - 1) * 90) + Kit.jitter(rng, RAD(10))
		local start = Kit.radial(at, a, N.Radius + 6) * CFrame.Angles(0, math.pi, 0)
		Kit.chain(m, "Root", start * CFrame.Angles(-RAD(55), 0, 0), 4, 3, 1.3, 0.82,
			Vector3.new(RAD(-26), 0, 0), C.Root, Kit.Opts.STUDDED)
	end
end

--==============================================================================
-- THE SCENERY: non-collectible dressing from MapDecor's kit, in the rain's
-- palette. Each builder is a few parts; the placements below are literal.
--==============================================================================
-- Four broad leaves held up to the rain round a short stem, one caught drop.
local function broadLeaves(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = Kit.group(parent, "BroadLeaves")
	Kit.column(m, "Stem", cf, 1.1 * s, 0.5 * s, C.Reed, Kit.Opts.CYL_SMOOTH)
	for i = 1, 4 do
		local a = (i - 1) / 4 * TAU + Kit.jitter(rng, RAD(22))
		Kit.blade(m, "Leaf", Kit.radial(cf * CFrame.new(0, 0.7 * s, 0), a, 0.4 * s),
			rng:NextNumber(2.6, 3.4) * s, 0.35 * s, rng:NextNumber(3.6, 4.8) * s,
			RAD(rng:NextNumber(24, 40)), if i % 2 == 0 then C.Teal else C.Leaf, Kit.Opts.SMOOTH)
	end
	Kit.piece(m, "Drop", Vector3.new(0.5, 0.5, 0.5) * s, cf * CFrame.new(1.4 * s, 2.3 * s, -1 * s), C.Accent,
		{ shape = Enum.PartType.Ball, transparency = 0.25 })
	return m
end

-- Three reeds, each two bending segments drooping over, a seed head at the tip.
local function reeds(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = Kit.group(parent, "Reeds")
	for i = 1, 3 do
		local a = (i - 1) / 3 * TAU + Kit.jitter(rng, RAD(30))
		local base = Kit.radial(cf, a, rng:NextNumber(0.4, 1.1) * s)
		local h = rng:NextNumber(4.2, 6.4) * s
		local tip = Kit.chain(m, "Reed", base * CFrame.Angles(RAD(rng:NextNumber(4, 12)), 0, 0), 2, h * 0.5, 0.32 * s,
			0.82, Vector3.new(RAD(rng:NextNumber(28, 46)), 0, 0), C.Reed, Kit.Opts.SMOOTH)
		Kit.piece(m, "Head", Vector3.new(0.34, 0.9, 0.34) * s, tip * CFrame.new(0, 0.3 * s, 0), C.Bark, Kit.Opts.SMOOTH)
	end
	return m
end

-- Three vines hanging from a wall's top (`top` on its inner face, -Z into the
-- route), each two segments and a leaf.
local function vineCurtain(parent: Instance, top: CFrame, s: number, rng: Random, drop: number): Model
	local m = Kit.group(parent, "Vines")
	for i = 1, 3 do
		local start = top * CFrame.new((i - 2) * 1.6 * s, -0.2, -0.35) * CFrame.Angles(math.pi, 0, 0)
		local len = drop * rng:NextNumber(0.7, 1) / 2
		local tip = Kit.chain(m, "Vine",
			start * CFrame.Angles(RAD(rng:NextNumber(-6, 6)), 0, RAD(rng:NextNumber(-8, 8))), 2, len, 0.36 * s, 0.9,
			Vector3.new(RAD(rng:NextNumber(-10, 10)), 0, RAD(rng:NextNumber(-8, 8))), C.LeafDeep, Kit.Opts.SMOOTH)
		Kit.piece(m, "Leaf", Vector3.new(1.1, 0.14, 1.6) * s, tip * CFrame.new(0, 0.2, 0), C.Teal, Kit.Opts.SMOOTH)
	end
	return m
end

-- A beam across the whole corridor with eight vines off it, the four over
-- the middle kept short so the lane keeps its headroom.
local function vineArch(parent: Instance, s: Segment, t: number, rng: Random): Model
	local m = Kit.group(parent, "VineArch")
	local centre = s.a + s.dir * (s.length * t)
	local mid = Vector3.new(centre.X, Y + 20, centre.Z)
	Kit.piece(m, "Beam", Vector3.new(1.3, 1.3, s.w + T), CFrame.lookAt(mid, mid + s.side), C.Bark, Kit.Opts.STUDDED)
	for k = 1, 8 do
		local u = (k - 4.5) * (s.w / 9)
		local top = CFrame.new(mid + s.side * u) * CFrame.Angles(math.pi, 0, 0)
		local len = rng:NextNumber(1.6, 2.6) * (if math.abs(u) < s.w / 4 then 0.6 else 1)
		local tip = Kit.chain(m, "Vine", top * CFrame.Angles(RAD(rng:NextNumber(-8, 8)), 0, RAD(rng:NextNumber(-8, 8))),
			2, len, 0.34, 0.9, Vector3.new(RAD(rng:NextNumber(-8, 8)), 0, 0), C.LeafDeep, Kit.Opts.SMOOTH)
		Kit.piece(m, "Leaf", Vector3.new(0.9, 0.16, 1.3), tip * CFrame.new(0, 0.2, 0), C.Teal, Kit.Opts.SMOOTH)
	end
	return m
end

-- Three roots out of a wall's foot (`cf` on its inner face, -Z into the
-- route), diving into the floor, moss on two of them.
local function mossyRoots(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = Kit.group(parent, "Roots")
	for i = 1, 3 do
		local a = (i - 2) * RAD(28) + Kit.jitter(rng, RAD(12))
		local start = cf * CFrame.new(0, 1.8 * s, 0) * CFrame.Angles(0, a, 0) * CFrame.Angles(-math.pi / 2 - RAD(18), 0, 0)
		local tip = Kit.chain(m, "Root", start, 3, 2.2 * s, 0.9 * s, 0.8, Vector3.new(RAD(-16), 0, 0), C.Root, Kit.Opts.STUDDED)
		if i ~= 2 then
			Kit.piece(m, "Moss", Vector3.new(1.2, 0.35, 1) * s, tip * CFrame.new(0, -0.6 * s, -0.4 * s), C.Moss, Kit.Opts.SMOOTH)
		end
	end
	return m
end

-- A fern from the kit, in the rain's green.
local function fernCluster(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	return Props.fern(parent, cf, s, rng, if rng:NextNumber() < 0.5 then C.Leaf else C.Teal)
end

-- A low mound with five pale-blue blooms on it.
local function flowerPatch(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = Kit.group(parent, "Flowers")
	Kit.piece(m, "Mound", Vector3.new(3.2, 1.4, 2.8) * s,
		cf * CFrame.new(0, 0.35 * s, 0) * CFrame.Angles(0, Kit.jitter(rng, RAD(40)), 0), C.LeafDeep, Kit.Opts.STUDDED)
	for i = 1, 5 do
		local a = (i - 1) / 5 * TAU + Kit.jitter(rng, RAD(25))
		local at = Kit.radial(cf, a, rng:NextNumber(0.4, 1.2) * s)
		Kit.piece(m, "Bloom", Vector3.new(0.62, 0.62, 0.62) * s, at * CFrame.new(0, rng:NextNumber(0.9, 1.4) * s, 0),
			if i == 3 then C.FlowerDeep else C.Flower, Kit.Opts.BALL_SMOOTH)
	end
	return m
end

-- A shallow puddle: one glass disc just above the floor.
local function puddle(parent: Instance, cf: CFrame, d: number): Model
	local m = Kit.group(parent, "Puddle")
	Kit.disc(m, "Water", cf * CFrame.new(0, 0.05, 0), 0.12, d, C.Water, Kit.Opts.WATER)
	return m
end

-- Runoff: a wet streak down a wall's inner face (`foot` at its base, -Z into
-- the route) and the small pool it feeds.
local function runoff(parent: Instance, foot: CFrame, h: number): Model
	local m = Kit.group(parent, "Runoff")
	local streak = Kit.piece(m, "Streak", Vector3.new(1.1, h, 0.16), foot * CFrame.new(0, h / 2, -0.1), C.Wet,
		{ material = SLATE })
	streak.Reflectance = 0.3
	Kit.disc(m, "Pool", foot * CFrame.new(0, 0.05, -2.6), 0.12, 5, C.Water, Kit.Opts.WATER)
	return m
end

-- A moss-covered stone: two slate blocks and a moss slab.
local function mossStone(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = Kit.group(parent, "MossStone")
	local yaw = Kit.jitter(rng, RAD(40))
	Kit.piece(m, "Rock", Vector3.new(3.4, 2.4, 2.8) * s, cf * CFrame.new(0, 1 * s, 0) * CFrame.Angles(RAD(8), yaw, RAD(-7)),
		C.Stone, Kit.Opts.STUDDED)
	Kit.piece(m, "Rock", Vector3.new(2, 1.5, 1.8) * s,
		cf * CFrame.new(1.6 * s, 0.6 * s, 0.9 * s) * CFrame.Angles(RAD(-10), yaw + RAD(35), RAD(6)), C.StoneDark, Kit.Opts.STUDDED)
	Kit.piece(m, "Moss", Vector3.new(2.6, 0.45, 2) * s,
		cf * CFrame.new(-0.2 * s, 2.2 * s, -0.2 * s) * CFrame.Angles(RAD(8), yaw, RAD(-7)), C.Moss, Kit.Opts.SMOOTH)
	return m
end

-- A bigger one: the kit's boulder in slate, with moss.
local function boulder(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	return Props.boulder(parent, cf, s, rng, C.Stone, C.StoneDark, C.Moss)
end

-- The garden's pond: a wide puddle with three moss pads floating on it.
local function pond(parent: Instance, cf: CFrame, d: number, rng: Random): Model
	local m = puddle(parent, cf, d)
	m.Name = "Pond"
	for i = 1, 3 do
		local at = Kit.radial(cf, RAD(40 + i * 110) + Kit.jitter(rng, RAD(20)), d * rng:NextNumber(0.2, 0.34)) * CFrame.new(0, 0.2, 0)
		Kit.disc(m, "Pad", at, 0.2, rng:NextNumber(3, 4.4), C.MossPale, Kit.Opts.CYL_SMOOTH)
	end
	return m
end

local function grass(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	return Props.grassTuft(parent, cf, s, rng, C.Reed, C.LeafDeep, 2.4)
end

local function log(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	return Props.fallenLog(parent, cf, s, rng)
end

-- Frames along the route. A corridor point `t` of the way along segment `s`,
-- `u` studs to the side (positive along s.side), facing the middle.
local function segFrame(s: Segment, t: number, u: number): CFrame
	local p = s.a + s.dir * (s.length * t) + s.side * u
	local facing = if u > 0 then -s.side elseif u < 0 then s.side else s.dir
	return CFrame.lookAt(p, p + facing)
end

-- A room point `dist` out from room `j`'s centre along `angleDeg` (0 along +X,
-- 90 along +Z), facing the centre.
local function roomFrame(j: number, angleDeg: number, dist: number): CFrame
	local n = ROUTE[j]
	local p = onCircle(n, RAD(angleDeg), dist)
	return CFrame.lookAt(p, Vector3.new(n.x, Y, n.z))
end

-- A point round the nest, facing it: `beyond` studs out past its rim, so the
-- foliage stays round the nest however wide it is (2026-10-02: grown to hold
-- the Rain event's pods).
local function nestFrame(angleDeg: number, beyond: number): CFrame
	local N = B.Nest
	local a = RAD(angleDeg)
	local dist = N.Radius + beyond
	local p = Vector3.new(N.X + math.cos(a) * dist, Y, N.Z + math.sin(a) * dist)
	return CFrame.lookAt(p, Vector3.new(N.X, Y, N.Z))
end

-- On a corridor wall's inner face: at its top, or at its foot, -Z into the route.
local function wallFace(s: Segment, t: number, side: number, atTop: boolean): CFrame
	local p = s.a + s.dir * (s.length * t) + s.side * (side * s.w / 2) + Vector3.new(0, if atTop then H else 0, 0)
	return CFrame.lookAt(p, p - s.side * side)
end

-- On a room's ring, inner face, at the floor, facing the centre; and at its top.
local function ringFace(j: number, angleDeg: number): CFrame
	return roomFrame(j, angleDeg, ROUTE[j].r - 0.2)
end
local function ringTop(j: number, angleDeg: number): CFrame
	return ringFace(j, angleDeg) * CFrame.new(0, H, 0)
end

-- A corridor's walls run only between the rooms' circles (from one chord to
-- the next), so anything that stands against a wall is placed where the wall
-- is; inside a room the dressing keeps to the rim, off the lanes in and out.
-- Corridor props stand 46..64 studs off the middle (the walls are at 70), so
-- the middle 80 studs stay the guardian's.

-- The mouth, and the long approach into the garden (its walls from t 0.11
-- to 0.67).
local function dressEntrance(parent: Instance, rng: Random)
	local s = SEGS[1]
	reeds(parent, roomFrame(1, 100, 62), 1.3, rng)
	mossStone(parent, roomFrame(1, 120, 64), 1.2, rng)
	fernCluster(parent, roomFrame(1, 80, 60), 1.4, rng)
	broadLeaves(parent, roomFrame(1, 290, 62), 1.4, rng)
	boulder(parent, roomFrame(1, 270, 66), 1.6, rng)
	flowerPatch(parent, roomFrame(1, 310, 60), 1.2, rng)
	grass(parent, roomFrame(1, 140, 64), 1.2, rng)
	runoff(parent, ringFace(1, 100), 16)
	runoff(parent, ringFace(1, 280), 14)
	vineCurtain(parent, ringTop(1, 110), 1.2, rng, 14)
	vineCurtain(parent, ringTop(1, 262), 1.2, rng, 12)
	puddle(parent, roomFrame(1, 60, 40), 12)
	puddle(parent, roomFrame(1, 330, 44), 9)
	puddle(parent, roomFrame(1, 180, 30), 8)
	fernCluster(parent, segFrame(s, 0.15, 52), 1.3, rng)
	broadLeaves(parent, segFrame(s, 0.22, -54), 1.4, rng)
	puddle(parent, segFrame(s, 0.2, 8), 12)
	mossyRoots(parent, wallFace(s, 0.25, 1, false), 1.1, rng)
	mossStone(parent, segFrame(s, 0.3, 58), 1.1, rng)
	flowerPatch(parent, segFrame(s, 0.33, -50), 1.2, rng)
	vineArch(parent, s, 0.38, rng)
	reeds(parent, segFrame(s, 0.4, 56), 1.3, rng)
	grass(parent, segFrame(s, 0.42, -56), 1.1, rng)
	runoff(parent, wallFace(s, 0.45, -1, false), 16)
	boulder(parent, segFrame(s, 0.5, -58), 1.5, rng)
	puddle(parent, segFrame(s, 0.5, -14), 10)
	fernCluster(parent, segFrame(s, 0.55, 50), 1.2, rng)
	vineCurtain(parent, wallFace(s, 0.6, 1, true), 1.2, rng, 14)
	log(parent, segFrame(s, 0.62, -52) * CFrame.Angles(0, RAD(30), 0), 1, rng)
	grass(parent, segFrame(s, 0.65, 54), 1.2, rng)
end

-- The pond room, and the corridor out of it (walls from t 0.34 to 0.82).
local function dressGarden(parent: Instance, rng: Random)
	local s = SEGS[2]
	pond(parent, roomFrame(2, 110, 50), 30, rng)
	broadLeaves(parent, roomFrame(2, 95, 78), 1.5, rng)
	broadLeaves(parent, roomFrame(2, 140, 76), 1.3, rng)
	broadLeaves(parent, roomFrame(2, 60, 80), 1.3, rng)
	reeds(parent, roomFrame(2, 120, 84), 1.5, rng)
	reeds(parent, roomFrame(2, 160, 82), 1.2, rng)
	flowerPatch(parent, roomFrame(2, 70, 72), 1.3, rng)
	flowerPatch(parent, roomFrame(2, 240, 78), 1.2, rng)
	flowerPatch(parent, roomFrame(2, 290, 74), 1.1, rng)
	fernCluster(parent, roomFrame(2, 300, 80), 1.4, rng)
	fernCluster(parent, roomFrame(2, 40, 82), 1.3, rng)
	boulder(parent, roomFrame(2, 250, 84), 1.8, rng)
	boulder(parent, roomFrame(2, 318, 86), 1.4, rng)
	mossStone(parent, roomFrame(2, 36, 86), 1.1, rng)
	log(parent, roomFrame(2, 85, 64), 1, rng)
	grass(parent, roomFrame(2, 265, 84), 1.2, rng)
	grass(parent, roomFrame(2, 130, 86), 1.1, rng)
	runoff(parent, ringFace(2, 110), 18)
	runoff(parent, ringFace(2, 260), 16)
	vineCurtain(parent, ringTop(2, 90), 1.3, rng, 16)
	vineCurtain(parent, ringTop(2, 300), 1.2, rng, 14)
	mossyRoots(parent, ringFace(2, 150), 1.2, rng)
	mossyRoots(parent, ringFace(2, 320), 1.1, rng)
	puddle(parent, roomFrame(2, 320, 50), 10)
	puddle(parent, roomFrame(2, 180, 40), 9)
	puddle(parent, roomFrame(2, 230, 56), 8)
	puddle(parent, roomFrame(2, 10, 58), 11)
	fernCluster(parent, segFrame(s, 0.38, 52), 1.2, rng)
	grass(parent, segFrame(s, 0.4, -56), 1.1, rng)
	mossyRoots(parent, wallFace(s, 0.42, 1, false), 1.1, rng)
	broadLeaves(parent, segFrame(s, 0.45, -54), 1.3, rng)
	puddle(parent, segFrame(s, 0.5, 6), 12)
	mossStone(parent, segFrame(s, 0.5, 56), 1, rng)
	flowerPatch(parent, segFrame(s, 0.55, -50), 1.1, rng)
	vineArch(parent, s, 0.58, rng)
	reeds(parent, segFrame(s, 0.6, 54), 1.2, rng)
	runoff(parent, wallFace(s, 0.65, -1, false), 14)
	boulder(parent, segFrame(s, 0.7, -56), 1.4, rng)
	vineCurtain(parent, wallFace(s, 0.75, 1, true), 1.2, rng, 14)
	log(parent, segFrame(s, 0.78, -52) * CFrame.Angles(0, RAD(-25), 0), 0.9, rng)
end

-- The passage's hollow, and the last corridor into the clearing (walls from
-- t 0.21 to 0.48).
local function dressPassage(parent: Instance, rng: Random)
	local s = SEGS[3]
	mossyRoots(parent, ringFace(3, 100), 1.2, rng)
	mossyRoots(parent, ringFace(3, 250), 1.1, rng)
	mossyRoots(parent, ringFace(3, 300), 1.2, rng)
	vineCurtain(parent, ringTop(3, 80), 1.3, rng, 16)
	vineCurtain(parent, ringTop(3, 120), 1.2, rng, 14)
	vineCurtain(parent, ringTop(3, 240), 1.2, rng, 15)
	vineCurtain(parent, ringTop(3, 290), 1.3, rng, 16)
	fernCluster(parent, roomFrame(3, 70, 64), 1.3, rng)
	fernCluster(parent, roomFrame(3, 270, 66), 1.2, rng)
	reeds(parent, roomFrame(3, 110, 66), 1.2, rng)
	broadLeaves(parent, roomFrame(3, 310, 64), 1.3, rng)
	boulder(parent, roomFrame(3, 60, 68), 1.5, rng)
	mossStone(parent, roomFrame(3, 240, 66), 1, rng)
	log(parent, roomFrame(3, 300, 60), 0.9, rng)
	flowerPatch(parent, roomFrame(3, 130, 64), 1.1, rng)
	grass(parent, roomFrame(3, 280, 68), 1.1, rng)
	runoff(parent, ringFace(3, 70), 16)
	puddle(parent, roomFrame(3, 160, 46), 10)
	puddle(parent, roomFrame(3, 30, 50), 9)
	puddle(parent, roomFrame(3, 220, 40), 8)
	vineCurtain(parent, wallFace(s, 0.25, -1, true), 1.2, rng, 16)
	fernCluster(parent, segFrame(s, 0.28, 52), 1.2, rng)
	vineArch(parent, s, 0.3, rng)
	broadLeaves(parent, segFrame(s, 0.33, -56), 1.2, rng)
	mossyRoots(parent, wallFace(s, 0.35, 1, false), 1.1, rng)
	puddle(parent, segFrame(s, 0.35, -10), 12)
	reeds(parent, segFrame(s, 0.4, -54), 1.2, rng)
	runoff(parent, wallFace(s, 0.4, -1, false), 14)
	vineCurtain(parent, wallFace(s, 0.42, 1, true), 1.2, rng, 15)
	mossStone(parent, segFrame(s, 0.45, 54), 1, rng)
	flowerPatch(parent, segFrame(s, 0.46, -50), 1.1, rng)
end

-- The clearing: the nest at its centre with its own foliage close round it
-- (none from the side the route comes in), the rim dressed, and the open
-- ring between them -- the guardian's room -- holding nothing but puddles.
local function dressNest(parent: Instance, rng: Random)
	buildNest(parent, rng)
	broadLeaves(parent, nestFrame(20, 10), 1.5, rng)
	broadLeaves(parent, nestFrame(340, 10), 1.4, rng)
	broadLeaves(parent, nestFrame(110, 9), 1.3, rng)
	broadLeaves(parent, nestFrame(265, 9), 1.2, rng)
	reeds(parent, nestFrame(60, 13), 1.4, rng)
	reeds(parent, nestFrame(300, 13), 1.3, rng)
	reeds(parent, nestFrame(90, 11), 1.2, rng)
	reeds(parent, nestFrame(270, 11), 1.2, rng)
	fernCluster(parent, nestFrame(0, 6), 1.4, rng)
	fernCluster(parent, nestFrame(80, 6), 1.3, rng)
	fernCluster(parent, nestFrame(280, 6), 1.3, rng)
	fernCluster(parent, nestFrame(130, 8), 1.2, rng)
	flowerPatch(parent, nestFrame(40, 4), 1.2, rng)
	flowerPatch(parent, nestFrame(320, 4), 1.1, rng)
	flowerPatch(parent, nestFrame(120, 5), 1, rng)
	flowerPatch(parent, nestFrame(260, 5), 1, rng)
	mossStone(parent, nestFrame(135, 12), 1, rng)
	mossStone(parent, nestFrame(255, 12), 1, rng)
	-- The rim.
	boulder(parent, roomFrame(4, 60, 100), 2, rng)
	boulder(parent, roomFrame(4, 300, 100), 1.8, rng)
	boulder(parent, roomFrame(4, 120, 102), 1.6, rng)
	boulder(parent, roomFrame(4, 240, 102), 1.5, rng)
	boulder(parent, roomFrame(4, 20, 104), 1.4, rng)
	fernCluster(parent, roomFrame(4, 30, 102), 1.5, rng)
	fernCluster(parent, roomFrame(4, 90, 102), 1.4, rng)
	fernCluster(parent, roomFrame(4, 150, 104), 1.3, rng)
	fernCluster(parent, roomFrame(4, 270, 102), 1.4, rng)
	fernCluster(parent, roomFrame(4, 330, 102), 1.5, rng)
	broadLeaves(parent, roomFrame(4, 75, 100), 1.6, rng)
	broadLeaves(parent, roomFrame(4, 285, 100), 1.5, rng)
	broadLeaves(parent, roomFrame(4, 160, 104), 1.3, rng)
	reeds(parent, roomFrame(4, 105, 102), 1.5, rng)
	reeds(parent, roomFrame(4, 255, 102), 1.4, rng)
	reeds(parent, roomFrame(4, 45, 102), 1.3, rng)
	reeds(parent, roomFrame(4, 315, 102), 1.3, rng)
	mossyRoots(parent, ringFace(4, 50), 1.3, rng)
	mossyRoots(parent, ringFace(4, 130), 1.2, rng)
	mossyRoots(parent, ringFace(4, 230), 1.2, rng)
	mossyRoots(parent, ringFace(4, 310), 1.3, rng)
	vineCurtain(parent, ringTop(4, 70), 1.3, rng, 16)
	vineCurtain(parent, ringTop(4, 110), 1.2, rng, 14)
	vineCurtain(parent, ringTop(4, 250), 1.2, rng, 15)
	vineCurtain(parent, ringTop(4, 290), 1.3, rng, 16)
	vineCurtain(parent, ringTop(4, 165), 1.2, rng, 14)
	mossStone(parent, roomFrame(4, 150, 105), 1, rng)
	mossStone(parent, roomFrame(4, 10, 105), 1.1, rng)
	grass(parent, roomFrame(4, 100, 106), 1.2, rng)
	grass(parent, roomFrame(4, 260, 106), 1.2, rng)
	log(parent, roomFrame(4, 320, 98), 1, rng)
	log(parent, roomFrame(4, 140, 100), 0.9, rng)
	runoff(parent, ringFace(4, 90), 18)
	runoff(parent, ringFace(4, 270), 16)
	-- Puddles in the open ring.
	puddle(parent, roomFrame(4, 60, 60), 12)
	puddle(parent, roomFrame(4, 300, 60), 11)
	puddle(parent, roomFrame(4, 170, 55), 10)
	puddle(parent, roomFrame(4, 205, 70), 9)
	puddle(parent, roomFrame(4, 215, 50), 8)
	puddle(parent, roomFrame(4, 120, 75), 10)
	puddle(parent, roomFrame(4, 240, 75), 9)
	puddle(parent, roomFrame(4, 0, 70), 12)
end

-- Every part of the dressing fades and goes with the rest.
local function tagAll(folder: Instance)
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") then
			CollectionService:AddTag(d, TAGS.Terrain)
		end
	end
end

local function buildScenery(parent: Instance)
	local rng = Random.new(B.Scenery.Seed)
	local sections = {
		{ "Entrance", dressEntrance },
		{ "Garden", dressGarden },
		{ "Passage", dressPassage },
		{ "Nest", dressNest },
	}
	for _, entry in ipairs(sections) do
		local folder = Instance.new("Folder")
		folder.Name = entry[1]
		folder.Parent = parent;
		(entry[2] :: (Instance, Random) -> ())(folder, rng)
	end
	tagAll(parent)
end

--==============================================================================
-- THE BUILD
--==============================================================================
-- Everything, in one folder, with the entrance SHUT. The surfaces exist the
-- moment this returns; WeatherService opens the gate later.
function RainBiome.Build(parent: Instance): Folder
	local previous = parent:FindFirstChild(B.FolderName)
	if previous then
		previous:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = B.FolderName
	folder.Archivable = false
	folder:SetAttribute("Label", B.Label)

	local terrain = Instance.new("Folder")
	terrain.Name = "Terrain"
	terrain.Parent = folder
	buildFloors(terrain)
	buildWalls(terrain)
	buildSite(terrain)

	local bridge = Instance.new("Folder")
	bridge.Name = "Bridge"
	bridge.Parent = folder
	buildBridge(bridge)
	buildSafeLine(bridge)

	buildGate(folder)

	local scenery = Instance.new("Folder")
	scenery.Name = "Scenery"
	scenery.Parent = folder
	buildScenery(scenery)

	RainBiome.SetEntry(folder, false)
	folder.Parent = parent
	return folder
end

-- Open: the curtain is gone and nothing stops a player walking in. Shut: a
-- solid, visible wall across the ramp's top.
function RainBiome.SetEntry(folder: Instance, open: boolean)
	local gate = folder:FindFirstChild("Gate")
	if gate and gate:IsA("BasePart") then
		gate.CanCollide = not open
		gate.CanQuery = not open
		gate.Transparency = if open then 1 else 0.5
	end
	folder:SetAttribute("EntryOpen", open)
end

--==============================================================================
-- WHERE THE EVENT'S NEST GOES (2026-10-02; NestService.OpenEventNest)
--
-- The nest's centre at the top of its bowl, where pods stand; the floor its
-- guardian sleeps on; the walk home -- the rooms' centres from the entrance in
-- (NestService adds the guardian's own spot); and where a body thrown out of
-- the world is set down: the entrance room, on the way out. `folder` is the
-- built biome, which the nest lives in and goes with.
--==============================================================================
function RainBiome.NestSite(folder: Instance): { centre: Vector3, floorY: number, route: { Vector3 },
	setDown: Vector3, parent: Instance }
	local N = B.Nest
	local route: { Vector3 } = {}
	for i = 1, #ROUTE - 1 do
		local n = ROUTE[i]
		table.insert(route, Vector3.new(n.x, Y, n.z))
	end
	local first = ROUTE[1]
	return {
		centre = Vector3.new(N.X, Y + 1.11, N.Z),
		floorY = Y,
		route = route,
		setDown = Vector3.new(first.x, Y, first.z),
		parent = folder,
	}
end

function RainBiome.IsEntryOpen(folder: Instance): boolean
	return folder:GetAttribute("EntryOpen") == true
end

-- How many parts the folder holds (the spec's budget check).
function RainBiome.PartCount(folder: Instance): number
	local n = 0
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

return RainBiome
