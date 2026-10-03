--!strict
-- Steal a Seed :: RainClouds
--
-- The Rain event's white clouds, as arithmetic (NOT a renderer): where every
-- bank stands, how its balls overlap into one billowing mass, and how solid
-- each zone is at each moment of the event. Weather.client builds exactly
-- this on every client; RainEventSpec holds it. Numbers are
-- GameConfig.Weather.Clouds'.
--
-- WHY BALLS HERE, WHEN THE NIGHT FOG IS BLOCKS: the night fog stands inside
-- the road's walls, where a block reads as weather in a canyon
-- (GameConfig.WorldCycle.Fog). These stand against the open sky round the
-- island, and a lone block there is a crate. A Ball takes the diameter of its
-- SMALLEST axis, so every puff is a true sphere, and a bank is five to seven
-- of them overlapping -- round, soft at the edges through their transparency,
-- and three-dimensional from any side -- with one or two smaller ones riding
-- on top so it billows upward.
--
-- EVERY CLIENT BUILDS ITS OWN from the same seed, so a late joiner has the
-- same sky as everybody else on its first frame and the server holds none of
-- it. Nothing here collides, is queried, or shortens the world's visibility.
--
-- ZONES, and how solid each is (RainClouds.targets):
--   perimeter  round the island, the road's mouth left open
--   road       down the road outside its walls, above them
--   biome      along the temporary biome and over its wide rooms: solid
--              while it OPENS (the biome emerges from cloud), thinning once
--              it is open, thickening again as it closes, then gone with it
--   entrance   the bank the bridge passes through and the one over its gap:
--              thinning through the opening so the entrance reads before
--              the gate lifts
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))
local BiomeData = require(script.Parent:WaitForChild("BiomeData"))

local W = GameConfig.Weather
local CL = W.Clouds
local B = W.Biome
local MAP = GameConfig.Map
local Y = MAP.GroundY
local T = B.WallThickness

local RainClouds = {}

export type Puff = { offset: Vector3, diameter: number }
export type Bank = { name: string, zone: string, at: Vector3, yaw: number, puffs: { Puff } }
export type Targets = { perimeter: number, road: number, biome: number, entrance: number, gone: number }

-- One bank: Puffs balls along its length, the biggest in the middle, each
-- overlapping the next; one or two smaller ones riding on top. Its length
-- runs along its local X; `yaw` turns that.
local function bank(rng: Random, name: string, zone: string, x: number, z: number, yaw: number,
	height: number, scale: number): Bank
	local count = rng:NextInteger(CL.Puffs.Min, CL.Puffs.Max)
	local length = rng:NextNumber(CL.Length.Min, CL.Length.Max) * scale
	local puffs: { Puff } = {}
	for i = 1, count do
		local t = (i - 0.5) / count
		local mid = 1 - math.abs(t - 0.5) * 2
		local d = (CL.Diameter.Min + (CL.Diameter.Max - CL.Diameter.Min) * (0.35 + 0.65 * mid)) * scale
			* rng:NextNumber(0.88, 1.08)
		table.insert(puffs, {
			offset = Vector3.new((t - 0.5) * length, d * 0.1 + mid * 4 * scale + rng:NextNumber(-1.5, 1.5),
				rng:NextNumber(-0.16, 0.16) * length),
			diameter = d,
		})
	end
	for _ = 1, rng:NextInteger(1, 2) do
		local under = puffs[rng:NextInteger(2, math.max(2, count - 1))]
		table.insert(puffs, {
			offset = under.offset + Vector3.new(rng:NextNumber(-4, 4) * scale, under.diameter * 0.42,
				rng:NextNumber(-3, 3) * scale),
			diameter = under.diameter * rng:NextNumber(0.5, 0.65),
		})
	end
	return { name = name, zone = zone, at = Vector3.new(x, Y + height, z), yaw = yaw, puffs = puffs }
end

local cache: { Bank }? = nil

-- Every bank, in a fixed order, the same on every client and every event.
function RainClouds.banks(): { Bank }
	if cache then
		return cache
	end
	local rng = Random.new(CL.Seed)
	local list: { Bank } = {}
	local function jitter(amount: number): number
		return rng:NextNumber(-amount, amount)
	end
	local halfW = MAP.FieldWidth / 2
	local inset, step = CL.Inset, CL.Spacing
	local deck = B.Deck
	-- Round the island; the road's mouth stays open.
	for x = -halfW + 20, halfW - 20, step do
		table.insert(list, bank(rng, "North", "perimeter", x + jitter(8), MAP.FieldBack + inset, 0, CL.Height.Perimeter, 1))
		if math.abs(x) > MAP.CorridorWidth / 2 + 24 then
			table.insert(list, bank(rng, "South", "perimeter", x + jitter(8), -MAP.FieldFront - inset, 0, CL.Height.Perimeter, 1))
		end
	end
	for z = -MAP.FieldFront + 20, MAP.FieldBack - 20, step do
		table.insert(list, bank(rng, "West", "perimeter", -halfW - inset, z + jitter(8), math.pi / 2, CL.Height.Perimeter, 1))
		local atBridge = math.abs(z - deck.Z) < deck.Width / 2 + 10
		table.insert(list, bank(rng, if atBridge then "Entrance" else "East", if atBridge then "entrance" else "perimeter",
			halfW + inset, z + jitter(8), math.pi / 2, CL.Height.Perimeter, 1))
	end
	-- Down the road, outside both walls and above them, to the last biome's end.
	local roadEnd = -MAP.FieldFront - MAP.SegmentLength * #BiomeData.Biomes
	local roadX = MAP.CorridorWidth / 2 + MAP.WallThickness + CL.RoadOffset
	local z = -MAP.FieldFront - CL.RoadSpacing / 2
	while z > roadEnd do
		for _, side in ipairs({ -1, 1 }) do
			table.insert(list, bank(rng, "Road", "road", side * roadX + jitter(6), z + jitter(20), math.pi / 2, CL.Height.Road, 1))
		end
		z -= CL.RoadSpacing
	end
	-- Along the temporary biome: either side of every corridor beyond its
	-- wall, over every wide room, and one over the bridge's gap.
	local route = B.Route
	for i = 1, #route - 1 do
		local n0, n1 = route[i], route[i + 1]
		local a = Vector3.new(n0.x, 0, n0.z)
		local d = Vector3.new(n1.x, 0, n1.z) - a
		local len = d.Magnitude
		local dir = d.Unit
		local side = Vector3.new(-dir.Z, 0, dir.X)
		local yaw = -math.atan2(dir.Z, dir.X)
		local count = math.max(1, math.round(len / CL.RouteSpacing))
		for k = 1, count do
			local p = a + dir * (len * (k - 0.5) / count)
			for _, s in ipairs({ -1, 1 }) do
				local q = p + side * (s * (n0.w / 2 + T + CL.RouteOffset))
				table.insert(list, bank(rng, "Biome", "biome", q.X, q.Z, yaw, CL.Height.Biome, CL.RouteScale))
			end
		end
	end
	for _, n in ipairs(route) do
		if n.r >= 90 then
			table.insert(list, bank(rng, "BiomeRoom", "biome", n.x, n.z, 0, CL.Height.Room, CL.RouteScale))
		end
	end
	table.insert(list, bank(rng, "Bridge", "entrance", (deck.X0 + deck.X1) / 2 + 10, deck.Z, 0, CL.Height.Entrance, 0.9))
	cache = list
	return list
end

-- How many balls that is.
function RainClouds.count(): number
	local n = 0
	for _, b in ipairs(RainClouds.banks()) do
		n += #b.puffs
	end
	return n
end

-- How solid each zone is at this moment (a part's transparency: 0 solid,
-- 1 gone) and how far gone the biome itself is. `since` is the time since
-- the state began: the rain's start while opening, the entrance's opening
-- while active, the closing's start while closing.
function RainClouds.targets(state: string?, since: number): Targets
	if state == "opening" then
		local t = math.clamp(since / W.ToastDelaySeconds, 0, 1)
		return { perimeter = CL.Perimeter, road = CL.Road, biome = CL.BiomeConceal,
			entrance = CL.EntranceConceal + (CL.Entrance - CL.EntranceConceal) * t, gone = 0 }
	elseif state == "active" then
		local t = math.clamp(since / CL.EmergeSeconds, 0, 1)
		return { perimeter = CL.Perimeter, road = CL.Road, biome = CL.BiomeConceal + (CL.Biome - CL.BiomeConceal) * t,
			entrance = CL.Entrance, gone = 0 }
	elseif state == "closing" then
		local thicken = math.clamp(since / W.ThickenSeconds, 0, 1)
		local fade = math.clamp((since - W.ThickenSeconds) / W.FadeSeconds, 0, 1)
		local biome = CL.Biome + (CL.Thick - CL.Biome) * thicken
		return { perimeter = CL.Perimeter + (1 - CL.Perimeter) * fade, road = CL.Road + (1 - CL.Road) * fade,
			biome = biome + (1 - biome) * fade, entrance = CL.Entrance + (1 - CL.Entrance) * fade, gone = fade }
	end
	return { perimeter = 1, road = 1, biome = 1, entrance = 1, gone = 0 }
end

-- What a cloud is made of by day, and by night: lit white plastic, or a dim
-- self-lit grey-blue that reads without glare.
--==============================================================================
-- A THUNDERSTORM'S LIGHTNING, THE SAME MOMENTS ON EVERY CLIENT (2026-10-02)
--
-- Flash k happens at the event's start plus gaps drawn from one Random seeded
-- with the event's id (GameConfig.Weather.Thunder.Lightning: every Min..Max
-- seconds), so WorldClock's flash of light and Weather.client's bolt agree on
-- every machine without the server saying anything. Answers how bright the
-- flash is at `now` (0 to 1: a sharp double flicker that decays over Seconds)
-- and which flash it is (0 before the first).
--==============================================================================
local flashCache: { [string]: { number } } = {}

local function flashTimes(eventId: number, startedAt: number): { number }
	local key = tostring(eventId) .. ":" .. tostring(startedAt)
	local list = flashCache[key]
	if list then
		return list
	end
	local L = W.Thunder.Lightning
	local rng = Random.new(CL.Seed + 7919 * eventId)
	list = {}
	local at = startedAt + rng:NextNumber(L.Min, L.Max) * 0.5
	while at < startedAt + W.MaxSeconds + 60 do
		table.insert(list, at)
		at += rng:NextNumber(L.Min, L.Max)
	end
	table.clear(flashCache)
	flashCache[key] = list
	return list
end

function RainClouds.lightning(eventId: number, startedAt: number, now: number): (number, number)
	local L = W.Thunder.Lightning
	local list = flashTimes(eventId, startedAt)
	local k = 0
	for i, at in ipairs(list) do
		if at > now then
			break
		end
		k = i
	end
	if k == 0 then
		return 0, 0
	end
	local u = (now - list[k]) / L.Seconds
	if u >= 1 then
		return 0, k
	end
	local bright = if u < 0.18 then 1 elseif u < 0.32 then 0.25 elseif u < 0.46 then 0.8 else (1 - u) / 0.54 * 0.6
	return bright, k
end

function RainClouds.look(night: boolean): { Color: Color3, Material: Enum.Material }
	return if night then CL.Night else CL.Day
end

return RainClouds
