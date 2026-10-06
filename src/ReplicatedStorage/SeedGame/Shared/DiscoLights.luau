--!strict
-- Steal a Seed :: DiscoLights
--
-- The disco's colours, and WHERE its lights go on the map (2026-10-03). Pure:
-- no instances are made here and nothing connects to anything. MiniEventFX
-- lights the stations; WorldClock and MiniEventFX colour everything with the
-- same palette, so the whole map moves through one set of colours together.
--
--==============================================================================
-- THE STATIONS COME FROM THE MAP, NOT FROM A LIST OF GUESSES
--
--   hub      a ring round the deck (Map.HubRadius); the ball stays the focus
--   field    a ring between the deck and the plots, clear of the road's gap
--            (Map.PlotRingInner, Map.RoadGapDegrees)
--   road     down the road from the deck to the corridor's mouth
--            (Map.FieldFront), alternating sides
--   plots    one pool on every player plot that is in this client's world
--            (the Plot tag's models, as they stream in and out)
--   biomes   every permanent biome's segment, from BiomeData.SegmentBounds and
--            Map.CorridorWidth -- the same numbers MapService builds it from,
--            so a biome far beyond streaming range still has its stations
--   rain     the temporary rain biome while it stands: its own built floors
--            (RoomFloor*, CorridorFloor*), read off the parts themselves
--
-- A station is a ground point, a kind ("pool" or "spot") and a colour offset,
-- so neighbours never show the same colour at once.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))

local DiscoLights = {}

local MAP = GameConfig.Map
local DISCO = GameConfig.MiniEvent.Disco
local LAYOUT = DISCO.Map

export type Station = {
	at: Vector3, -- the ground point under the light
	kind: string, -- "pool" | "spot"
	offset: number, -- where on the palette's cycle this one is, 0..1
	source: string, -- "hub" | "field" | "road" | "plot" | biome id | "rain"
	-- Stable across rebuilds of the list: the same spot is the same station, so
	-- a light keeps its place while the list is recomputed around it.
	key: string,
}

--==============================================================================
-- THE COLOUR AT A MOMENT
--
-- `t` seconds into the event, `offset` round the cycle: the palette blended
-- smoothly between neighbours (smoothstep), a whole turn in CycleSeconds.
--==============================================================================
function DiscoLights.colourAt(t: number, offset: number): Color3
	local palette = DISCO.Palette
	local n = #palette
	local u = ((t / DISCO.CycleSeconds + offset) % 1) * n
	local i = math.floor(u)
	local f = u - i
	f = f * f * (3 - 2 * f)
	local a = palette[(i % n) + 1]
	local b = palette[((i + 1) % n) + 1]
	return a:Lerp(b, f)
end

-- A stable 0..1 offset for a position, so a station keeps its colour phase
-- however the list is rebuilt.
local function offsetFor(at: Vector3): number
	local h = math.sin(at.X * 0.0213 + at.Z * 0.0371) * 43758.5453
	return h - math.floor(h)
end

local function station(at: Vector3, kind: string, source: string): Station
	return {
		at = at,
		kind = kind,
		offset = offsetFor(at),
		source = source,
		key = string.format("%s:%s:%d:%d", source, kind, math.round(at.X * 4), math.round(at.Z * 4)),
	}
end

local GROUND = MAP.GroundY

--==============================================================================
-- THE FIXED STATIONS: hub, field, road and the five biomes.
--==============================================================================
function DiscoLights.fixedStations(): { Station }
	local list: { Station } = {}
	-- Hub: a ring round the deck. Angles start a quarter-turn off the road.
	local hubR = MAP.HubRadius * LAYOUT.HubRadiusFraction
	for i = 1, LAYOUT.HubPools do
		local a = (i - 0.5) / LAYOUT.HubPools * math.pi * 2
		table.insert(list, station(Vector3.new(math.cos(a) * hubR, GROUND, math.sin(a) * hubR), "pool", "hub"))
	end
	-- Field: a ring between the deck and the plots, spread over the arc that is
	-- NOT the road's gap (the road runs toward -Z, angle -90 degrees).
	local gap = math.rad(MAP.RoadGapDegrees)
	local roadAngle = -math.pi / 2
	local arc = math.pi * 2 - gap
	for i = 1, LAYOUT.FieldPools do
		local a = roadAngle + gap / 2 + (i - 0.5) / LAYOUT.FieldPools * arc
		table.insert(list, station(Vector3.new(math.cos(a) * LAYOUT.FieldRadius, GROUND,
			math.sin(a) * LAYOUT.FieldRadius), "pool", "field"))
	end
	-- Road: from the deck's edge to the corridor's mouth, alternating sides.
	local fromZ = -(MAP.HubRadius + LAYOUT.RoadSpacing * 0.5)
	local toZ = -MAP.FieldFront
	local k = 0
	local z = fromZ
	while z >= toZ do
		local side = if k % 2 == 0 then 1 else -1
		table.insert(list, station(Vector3.new(side * LAYOUT.RoadOffset, GROUND, z), "pool", "road"))
		k += 1
		z -= LAYOUT.RoadSpacing
	end
	-- Every permanent biome's segment.
	local half = MAP.CorridorWidth * 0.5
	for _, biome in ipairs(BiomeData.Biomes) do
		local nearZ, farZ = BiomeData.SegmentBounds(biome)
		local length = nearZ - farZ
		for i, f in ipairs(LAYOUT.PoolsAt) do
			local side = if i % 2 == 0 then 1 else -1
			table.insert(list, station(Vector3.new(side * half * LAYOUT.SideFraction, GROUND, nearZ - f * length),
				"pool", biome.Id))
		end
		for _, f in ipairs(LAYOUT.SpotsAt) do
			table.insert(list, station(Vector3.new(0, GROUND, nearZ - f * length), "spot", biome.Id))
		end
	end
	return list
end

--==============================================================================
-- A PLOT'S STATION: the middle of its soil if it has one, else its pivot.
--==============================================================================
function DiscoLights.plotStation(plot: Instance): Station?
	if not plot:IsA("Model") then
		return nil
	end
	local soil = plot:FindFirstChild(GameConfig.Plot.PlanterName, true)
	local at: Vector3
	if soil and soil:IsA("BasePart") then
		at = Vector3.new(soil.Position.X, soil.Position.Y + soil.Size.Y * 0.5, soil.Position.Z)
	else
		local pivot = plot:GetPivot().Position
		at = Vector3.new(pivot.X, GROUND, pivot.Z)
	end
	return station(at, "pool", "plot")
end

-- The top of a floor part, wherever it is turned.
local function topOf(part: BasePart): number
	local h = part.Size * 0.5
	local top = -math.huge
	for sx = -1, 1, 2 do
		for sy = -1, 1, 2 do
			for sz = -1, 1, 2 do
				top = math.max(top, (part.CFrame * Vector3.new(h.X * sx, h.Y * sy, h.Z * sz)).Y)
			end
		end
	end
	return top
end

--==============================================================================
-- THE RAIN BIOME'S STATIONS, from its own floors: a pool and a spot on every
-- room floor, and a pool every RainSpacing studs along each corridor floor
-- (its longest flat side).
--==============================================================================
function DiscoLights.rainStations(folder: Instance): { Station }
	local list: { Station } = {}
	for _, part in ipairs(folder:GetDescendants()) do
		if not part:IsA("BasePart") then
			continue
		end
		local name = part.Name
		if string.sub(name, 1, 9) == "RoomFloor" then
			local at = Vector3.new(part.Position.X, topOf(part), part.Position.Z)
			table.insert(list, station(at, "pool", "rain"))
			table.insert(list, station(at, "spot", "rain"))
		elseif string.sub(name, 1, 13) == "CorridorFloor" then
			-- The longer of the part's two flat axes, in the world.
			local cf = part.CFrame
			local axes = { { cf.RightVector, part.Size.X }, { cf.UpVector, part.Size.Y }, { cf.LookVector, part.Size.Z } }
			local best, length = nil :: Vector3?, 0
			for _, pair in ipairs(axes) do
				local dir, size = pair[1] :: Vector3, pair[2] :: number
				if math.abs(dir.Y) < 0.5 and size > length then
					best, length = dir, size
				end
			end
			if best then
				local flat = Vector3.new(best.X, 0, best.Z).Unit
				local count = math.max(1, math.floor(length / LAYOUT.RainSpacing))
				local y = topOf(part)
				for i = 1, count do
					local along = (i - 0.5) / count - 0.5
					local p = part.Position + flat * (along * length)
					table.insert(list, station(Vector3.new(p.X, y, p.Z), "pool", "rain"))
				end
			end
		end
	end
	return list
end

--==============================================================================
-- WHICH ARE LIT: the nearest of each kind to `focus` within the activation
-- radius, at most `pools` and `spots` of them. Returns a set keyed by station.
--==============================================================================
function DiscoLights.pick(stations: { Station }, focus: Vector3, pools: number, spots: number): { [Station]: true }
	local radius = LAYOUT.ActivationRadius
	local near: { { s: Station, d: number } } = {}
	for _, s in ipairs(stations) do
		local d = (Vector3.new(s.at.X, 0, s.at.Z) - Vector3.new(focus.X, 0, focus.Z)).Magnitude
		if d <= radius then
			table.insert(near, { s = s, d = d })
		end
	end
	table.sort(near, function(a, b)
		return a.d < b.d
	end)
	local chosen: { [Station]: true } = {}
	local p, sp = 0, 0
	for _, e in ipairs(near) do
		if e.s.kind == "spot" then
			if sp < spots then
				sp += 1
				chosen[e.s] = true
			end
		elseif p < pools then
			p += 1
			chosen[e.s] = true
		end
	end
	return chosen
end

-- The budget for a quality ("Full" / "Reduced"; "Off" lights nothing).
function DiscoLights.budget(quality: string?): (number, number)
	if quality == "Off" then
		return 0, 0
	end
	local b = if quality == "Reduced" then LAYOUT.Budget.Reduced else LAYOUT.Budget.Full
	return b.Pools, b.Spots
end

return DiscoLights
