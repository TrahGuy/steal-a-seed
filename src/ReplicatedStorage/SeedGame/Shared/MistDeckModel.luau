--!strict
--==============================================================================
-- Steal a Seed :: MistDeckModel (2026-10-11, Enchanted Mist stage 3)
--
-- THE HUB DECK'S DRESS (EnchantedMistConfig.Deck, the owner's pick of the
-- previews: A's moss carpet with C's mushroom fairy ring, and the grove). A
-- moss carpet over the round deck, under the plaza's floor; a ring of
-- mint-spotted mushrooms near the deck's edge, the road's side left open.
-- Overlays only: every part anchored, none collides, is found by a ray or
-- touches. Built once by MosskeeperService with the surround, and left
-- standing, Mist or not (the owner, 2026-10-11).
--==============================================================================
local GameConfig = require(script.Parent:WaitForChild("GameConfig"))
local EnchantedMistConfig = require(script.Parent:WaitForChild("EnchantedMistConfig"))

local MistDeckModel = {}

local D = EnchantedMistConfig.Deck
local MAP = GameConfig.Map

-- A point at radius r round the hub's centre, at angle a from the road (-Z),
-- turning toward +X.
local function at(r: number, a: number, y: number): Vector3
	return Vector3.new(r * math.sin(a), y, -r * math.cos(a))
end

-- Whether an angle (from the road) is inside the road's open gap.
function MistDeckModel.onRoad(a: number): boolean
	local d = math.abs(((a + math.pi) % (2 * math.pi)) - math.pi)
	return d < math.rad(D.RoadGapDegrees)
end

-- The deck's top (MapService: the hub deck is 0.9 thick on GroundY).
function MistDeckModel.DeckTop(): number
	return MAP.GroundY + MAP.EventHub.FloorY
end

function MistDeckModel.build(parent: Instance?): Model
	local model = Instance.new("Model")
	model.Name = D.ModelName
	local top = MistDeckModel.DeckTop()

	local function part(name: string, size: Vector3, cf: CFrame, colour: Color3, shape: Enum.PartType?,
		neon: boolean?, parent: Instance?): Part
		local p = Instance.new("Part")
		if shape then
			p.Shape = shape
		end
		p.Name = name
		p.Size = size
		p.CFrame = cf
		p.Color = colour
		p.Material = if neon then Enum.Material.Neon else Enum.Material.Plastic
		p.TopSurface = if neon then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = parent or model
		return p
	end

	-- The moss carpet: a disc a hair over the deck, under the plaza's floor.
	local radius = MAP.HubRadius - D.CarpetInset
	local carpetTop = top + D.CarpetLift
	local carpet = part("MossCarpet", Vector3.new(D.CarpetThickness, radius * 2, radius * 2),
		CFrame.new(MAP.EventHub.Centre.X, carpetTop - D.CarpetThickness / 2, MAP.EventHub.Centre.Z)
			* CFrame.Angles(0, 0, math.rad(90)), D.CarpetColour, Enum.PartType.Cylinder)
	model.PrimaryPart = carpet

	-- The fairy ring.
	local centre = MAP.EventHub.Centre
	for i = 0, D.Count - 1 do
		local a = i / D.Count * 2 * math.pi + math.pi / D.Count
		if not MistDeckModel.onRoad(a) then
			local base = at(D.RingRadius, a, top) + Vector3.new(centre.X, 0, centre.Z)
			local h = if i % 2 == 0 then D.StemTall else D.StemShort
			part("Stem" .. i, Vector3.new(D.StemWidth, h, D.StemWidth), CFrame.new(base + Vector3.new(0, h / 2, 0)),
				D.StemColour)
			part("Cap" .. i, Vector3.new(D.CapThickness, D.CapWidth, D.CapWidth),
				CFrame.new(base + Vector3.new(0, h + 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
				D.CapColours[(i % #D.CapColours) + 1], Enum.PartType.Cylinder)
			for k = 1, 3 do
				local s = (k - 2) * 0.55
				local spot = part("Spot" .. i .. "_" .. k, Vector3.new(D.SpotSize, D.SpotSize, D.SpotSize),
					CFrame.new(base + Vector3.new(s, h + 0.45, (k % 2) * 0.3 - 0.15)), D.SpotColour,
					Enum.PartType.Ball, true)
				spot:SetAttribute("MistGlow", true)
			end
		end
	end

	--==========================================================================
	-- THE GROVE (EnchantedMistConfig.Deck.Grove): trees round him, glowing
	-- flowers between them, a stepping-stone path to his open front.
	--==========================================================================
	local G = D.Grove
	local grove = Instance.new("Folder")
	grove.Name = "Grove"
	grove.Parent = model
	local function g(name: string, size: Vector3, cf: CFrame, colour: Color3, shape: Enum.PartType?,
		neon: boolean?): Part
		local p = part(name, size, cf, colour, shape, neon, grove)
		if neon then
			p:SetAttribute("MistGlow", true)
		end
		return p
	end
	local up = Vector3.new(0, 1, 0)
	for i, deg in ipairs(G.TreeAngles) do
		local a = math.rad(deg)
		local base = at(G.TreeRadius, a, top) + Vector3.new(centre.X, 0, centre.Z)
		local rng = Random.new(20261011 + i)
		local trunkH = 5.5 + rng:NextNumber() * 1.5
		local name = "Tree" .. i
		g(name .. "Trunk", Vector3.new(1.2, trunkH, 1.2), CFrame.new(base + up * (trunkH / 2))
			* CFrame.Angles(0, math.rad(rng:NextNumber(0, 90)), 0), G.Trunk)
		for k = 0, 2 do
			local yaw = math.rad(k * 120 + deg)
			g(name .. "Root" .. k, Vector3.new(0.5, 0.4, 1.6), CFrame.new(base + up * 0.2)
				* CFrame.Angles(0, yaw, 0) * CFrame.new(0, 0, -0.9) * CFrame.Angles(math.rad(-12), 0, 0), G.TrunkDark)
		end
		local tiers = { { 4.6, 2.0, 0.6, 12 }, { 3.8, 1.8, 2.2, 40 }, { 2.6, 1.6, 3.6, 70 } }
		for k, t in ipairs(tiers) do
			g(name .. "Canopy" .. k, Vector3.new(t[1], t[2], t[1]), CFrame.new(base + up * (trunkH + t[3]))
				* CFrame.Angles(0, math.rad(t[4] + deg), 0), G.Leaves[k])
		end
		for k, s in ipairs({ -1, 1 }) do
			g(name .. "Fruit" .. k, Vector3.new(0.5, 0.5, 0.5), CFrame.new(base + up * (trunkH - 0.6)
				+ Vector3.new(math.cos(a) * 1.4 * s, 0, math.sin(a) * 1.4 * s)), G.Mint, Enum.PartType.Ball, true)
		end
	end
	for i, deg in ipairs(G.FlowerAngles) do
		local a = math.rad(deg)
		local base = at(G.FlowerRadius, a, top) + Vector3.new(centre.X, 0, centre.Z)
		local name = "Flowers" .. i
		g(name .. "Pad", Vector3.new(0.12, 1.6, 1.6), CFrame.new(base + up * 0.06) * CFrame.Angles(0, 0, math.rad(90)),
			G.Moss, Enum.PartType.Cylinder)
		for k = 1, 3 do
			local off = Vector3.new(math.cos(k * 2.1) * 0.45, 0, math.sin(k * 2.1) * 0.45)
			local h = 0.7 + k * 0.15
			g(name .. "Stem" .. k, Vector3.new(0.12, h, 0.12), CFrame.new(base + off + up * (h / 2)), G.Leaves[2])
			g(name .. "Bloom" .. k, Vector3.new(0.42, 0.42, 0.42), CFrame.new(base + off + up * (h + 0.1)),
				if k == 2 then G.Petal else G.Mint, Enum.PartType.Ball, true)
		end
	end
	-- The path: stepping stones down the approach, moss either side, lanterns
	-- just outside it.
	local stoneTop = top + 0.1
	local step = (G.PathFrom - G.PathTo) / G.PathStones
	for i = 1, G.PathStones do
		local r = G.PathFrom - (i - 0.5) * step
		local yaw = math.rad(if i % 2 == 0 then 5 else -4)
		g("PathStone" .. i, Vector3.new(G.PathWidth, 0.12, step * 0.82),
			CFrame.new(centre.X, stoneTop - 0.06, centre.Z - r) * CFrame.Angles(0, yaw, 0), G.Stone)
	end
	for _, side in ipairs({ -1, 1 }) do
		local length = G.PathFrom - G.PathTo
		g(if side < 0 then "PathMossL" else "PathMossR", Vector3.new(0.4, 0.1, length),
			CFrame.new(centre.X + side * (G.PathWidth / 2 + 0.35), stoneTop - 0.05,
				centre.Z - (G.PathFrom + G.PathTo) / 2), G.Moss)
		for k = 1, G.LanternCount do
			local r = G.PathFrom - 2 - (k - 1) * (G.PathFrom - G.PathTo - 4) / math.max(1, G.LanternCount - 1)
			local foot = Vector3.new(centre.X + side * G.LanternSide, top, centre.Z - r)
			local name = "Lantern" .. (if side < 0 then "L" else "R") .. k
			g(name .. "Post", Vector3.new(0.4, 2.6, 0.4), CFrame.new(foot + up * 1.3), G.Trunk)
			g(name .. "Cap", Vector3.new(0.8, 0.25, 0.8), CFrame.new(foot + up * 2.75), G.TrunkDark)
			g(name .. "Glow", Vector3.new(0.7, 0.7, 0.7), CFrame.new(foot + up * 2.35), G.Mint, Enum.PartType.Ball, true)
		end
	end

	--==========================================================================
	-- THE DETAIL (EnchantedMistConfig.Deck.Detail): grass tufts, wildflowers,
	-- ferns, bushes, little mushrooms, mossy rocks, a fallen log, and the pond
	-- with its rim, lily pads, reeds and fireflies. Each piece turned and sized
	-- by its own seeded Random, so every server builds the same.
	--==========================================================================
	local T = D.Detail
	local detail = Instance.new("Folder")
	detail.Name = "Detail"
	detail.Parent = model
	local function dt(name: string, size: Vector3, cf: CFrame, colour: Color3, shape: Enum.PartType?,
		neon: boolean?): Part
		local p = part(name, size, cf, colour, shape, neon, detail)
		if neon then
			p:SetAttribute("MistGlow", true)
		end
		return p
	end
	-- A grass blade: a thin wedge, its point at the top of its back edge.
	local function blade(name: string, size: Vector3, cf: CFrame, colour: Color3)
		local w = Instance.new("WedgePart")
		w.Name = name
		w.Size = size
		w.CFrame = cf
		w.Color = colour
		w.Material = Enum.Material.Plastic
		w.TopSurface = Enum.SurfaceType.Smooth
		w.BottomSurface = Enum.SurfaceType.Smooth
		w.Anchored = true
		w.CanCollide = false
		w.CanQuery = false
		w.CanTouch = false
		w.CastShadow = false
		w.Parent = detail
	end
	local function spotAt(spot: { number }): Vector3
		return at(spot[2], math.rad(spot[1]), top) + Vector3.new(centre.X, 0, centre.Z)
	end
	-- Turned `yaw` about up: a flat offset (x, z).
	local function turned(yaw: number, x: number, z: number): Vector3
		return Vector3.new(math.cos(yaw) * x - math.sin(yaw) * z, 0, math.sin(yaw) * x + math.cos(yaw) * z)
	end

	-- Grass tufts: three blades leaning out.
	for i, spot in ipairs(T.Tufts) do
		local base = spotAt(spot)
		local rng = Random.new(20261012 + i)
		for k = 0, 2 do
			local h = 0.95 + rng:NextNumber() * 0.35
			blade("Tuft" .. i .. "Blade" .. k, Vector3.new(0.26, h, 0.6), CFrame.new(base)
				* CFrame.Angles(0, math.rad(k * 120 + rng:NextNumber(0, 40)), 0) * CFrame.new(0, 0, 0.18)
				* CFrame.Angles(math.rad(12), 0, 0) * CFrame.new(0, h / 2, 0), T.Grass[k + 1])
		end
	end
	-- Wildflowers: three on stems, two of the cluster's colour and a white or
	-- (every other cluster) a glowing mint one.
	local colours = { G.Petal, T.Lilac, T.Butter }
	for i, spot in ipairs(T.Flowers) do
		local base = spotAt(spot)
		local rng = Random.new(20261013 + i)
		local name = "Wildflowers" .. i
		for k = 1, 3 do
			local off = turned(k * 2.1 + rng:NextNumber(), 0.5, 0)
			local h = 0.55 + rng:NextNumber() * 0.45
			local glow = k == 3 and i % 2 == 0
			dt(name .. "Stem" .. k, Vector3.new(0.12, h, 0.12), CFrame.new(base + off + up * (h / 2)), G.Leaves[2])
			dt(name .. "Bloom" .. k, Vector3.new(0.52, 0.52, 0.52), CFrame.new(base + off + up * (h + 0.12)),
				if glow then G.Mint elseif k == 3 then G.Petal else colours[(i - 1) % #colours + 1],
				Enum.PartType.Ball, glow)
		end
	end
	-- Ferns: five fronds arching low, up and out.
	for i, spot in ipairs(T.Ferns) do
		local base = spotAt(spot)
		local rng = Random.new(20261014 + i)
		for k = 0, 4 do
			local len = 1.6 + rng:NextNumber() * 0.4
			dt("Fern" .. i .. "Frond" .. k, Vector3.new(0.5, 0.1, len), CFrame.new(base + up * 0.15)
				* CFrame.Angles(0, math.rad(k * 72 + rng:NextNumber(0, 30)), 0)
				* CFrame.Angles(math.rad(20 + rng:NextNumber() * 10), 0, 0) * CFrame.new(0, 0, -len / 2),
				G.Leaves[(k % 2) + 1])
		end
	end
	-- Bushes: two studded leafy blocks, the grove's canopies in little, two
	-- glowing mint berries on the lower one's sides.
	for i, spot in ipairs(T.Bushes) do
		local base = spotAt(spot)
		local rng = Random.new(20261015 + i)
		local low = CFrame.new(base + up * 0.65) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
		dt("Bush" .. i .. "Leaves1", Vector3.new(2.4, 1.3, 2.4), low, G.Leaves[2])
		dt("Bush" .. i .. "Leaves2", Vector3.new(1.7, 1, 1.7), low * CFrame.new(0.1, 1, -0.1)
			* CFrame.Angles(0, math.rad(40), 0), G.Leaves[3])
		dt("Bush" .. i .. "Berry1", Vector3.new(0.3, 0.3, 0.3), low * CFrame.new(1.22, 0.2, 0.45), G.Mint,
			Enum.PartType.Ball, true)
		dt("Bush" .. i .. "Berry2", Vector3.new(0.3, 0.3, 0.3), low * CFrame.new(-0.4, 0.3, -1.22), G.Mint,
			Enum.PartType.Ball, true)
	end
	-- Clover patches: a lighter blob on the carpet (a disc and a smaller one
	-- off its side, a hair under it), its top level with the plaza's floor (a
	-- hair over the carpet), with two low blooms.
	for i, spot in ipairs(T.Clover) do
		local base = spotAt(spot)
		local rng = Random.new(20261020 + i)
		local size = spot[3] * 2
		local lie = MAP.EventHub.Floor.Rise - 0.02
		dt("Clover" .. i, Vector3.new(0.04, size, size), CFrame.new(base + up * lie) * CFrame.Angles(0, 0, math.rad(90)),
			T.CloverColour, Enum.PartType.Cylinder)
		dt("Clover" .. i .. "Lobe", Vector3.new(0.04, size * 0.65, size * 0.65), CFrame.new(base
			+ turned(rng:NextNumber() * math.pi * 2, spot[3] * 0.7, 0) + up * (lie - 0.004))
			* CFrame.Angles(0, 0, math.rad(90)), T.CloverColour, Enum.PartType.Cylinder)
		for k = 1, 2 do
			local off = turned(rng:NextNumber() * math.pi * 2, spot[3] * (0.3 + rng:NextNumber() * 0.4), 0)
			dt("Clover" .. i .. "Bloom" .. k, Vector3.new(0.32, 0.32, 0.32), CFrame.new(base + off + up * 0.2),
				if k == 1 then G.Petal else T.Lilac, Enum.PartType.Ball)
		end
	end
	-- Little mushrooms: a pair from the ring's colours, one glowing spot.
	for i, spot in ipairs(T.Shrooms) do
		local base = spotAt(spot)
		local rng = Random.new(20261016 + i)
		local yaw = rng:NextNumber() * math.pi * 2
		for k, m in ipairs({ { 0, 0, 0.75, 1.1 }, { 0.65, 0.35, 0.5, 0.8 } }) do
			local foot = base + turned(yaw, m[1], m[2])
			dt("Shrooms" .. i .. "Stem" .. k, Vector3.new(0.3, m[3], 0.3), CFrame.new(foot + up * (m[3] / 2)), D.StemColour)
			dt("Shrooms" .. i .. "Cap" .. k, Vector3.new(0.26, m[4], m[4]), CFrame.new(foot + up * (m[3] + 0.1))
				* CFrame.Angles(0, 0, math.rad(90)), D.CapColours[k], Enum.PartType.Cylinder)
		end
		dt("Shrooms" .. i .. "Spot", Vector3.new(0.22, 0.22, 0.22), CFrame.new(base + up * 0.98), D.SpotColour,
			Enum.PartType.Ball, true)
	end
	-- Mossy rocks: a stone, a little sunk, moss on its top.
	for i, spot in ipairs(T.Rocks) do
		local rng = Random.new(20261017 + i)
		local cf = CFrame.new(spotAt(spot) + up * 0.35) * CFrame.Angles(0, rng:NextNumber() * math.pi * 2, 0)
			* CFrame.Angles(math.rad(rng:NextNumber(-6, 6)), 0, math.rad(rng:NextNumber(-6, 6)))
		dt("Rock" .. i, Vector3.new(1.7, 0.9, 1.3), cf, G.Stone)
		dt("Rock" .. i .. "Moss", Vector3.new(1.2, 0.16, 0.95), cf * CFrame.new(0.15, 0.5, 0.05), G.Moss)
	end
	-- A fallen log along the turn: cut ends, moss on its back, a glowing
	-- shelf fungus on its side.
	for i, spot in ipairs(T.Logs) do
		local cf = CFrame.new(spotAt(spot) + up * 0.45) * CFrame.Angles(0, -math.rad(spot[1]) + math.rad(12), 0)
		local name = "Log" .. i
		dt(name, Vector3.new(4.4, 1.1, 1.1), cf, G.TrunkDark, Enum.PartType.Cylinder)
		dt(name .. "EndA", Vector3.new(0.06, 0.86, 0.86), cf * CFrame.new(-2.21, 0, 0), T.LogEnd, Enum.PartType.Cylinder)
		dt(name .. "EndB", Vector3.new(0.06, 0.86, 0.86), cf * CFrame.new(2.21, 0, 0), T.LogEnd, Enum.PartType.Cylinder)
		dt(name .. "Moss", Vector3.new(2.6, 0.14, 0.7), cf * CFrame.new(-0.3, 0.55, 0), G.Moss)
		dt(name .. "Shelf", Vector3.new(0.12, 0.75, 0.75), cf * CFrame.new(0.9, 0.1, -0.5) * CFrame.Angles(0, 0, math.rad(90)),
			G.Mint, Enum.PartType.Cylinder, true)
	end

	-- THE POND: its water a flush surface of overlapping discs (each a hair
	-- under the last, so no two faces fight), a deeper middle, a stone rim
	-- round the edge they make, lily pads, reeds on its far side and a few
	-- fireflies over it.
	local P = T.Pond
	local pa = math.rad(P.Angle)
	local pc = at(P.Radius, pa, top) + Vector3.new(centre.X, 0, centre.Z)
	local outward = Vector3.new(math.sin(pa), 0, -math.cos(pa))
	local along = Vector3.new(math.cos(pa), 0, math.sin(pa))
	local function pondAt(u: number, v: number, y: number): Vector3
		return pc + outward * u + along * v + up * y
	end
	local flat = CFrame.Angles(0, 0, math.rad(90))
	local function water(name: string, diameter: number, u: number, v: number, surface: number, colour: Color3)
		local p = dt(name, Vector3.new(0.04, diameter, diameter), CFrame.new(pondAt(u, v, surface - 0.02)) * flat, colour,
			Enum.PartType.Cylinder)
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.Reflectance = 0.12
	end
	for k, lobe in ipairs(P.Lobes) do
		water("PondWater" .. k, lobe[3] * 2, lobe[1], lobe[2], P.Rise - (k - 1) * 0.004, T.Water)
	end
	local main = P.Lobes[1]
	water("PondDeep", main[3] * 2 * P.Deep, main[1], main[2], P.Rise + 0.02, T.WaterDeep)
	local stones = 0
	for k, lobe in ipairs(P.Lobes) do
		local steps = math.max(3, math.floor(2 * math.pi * lobe[3] / P.RimStep + 0.5))
		for s = 0, steps - 1 do
			local rng = Random.new(20261018 + k * 100 + s)
			-- Spaced unevenly round the edge, like stones set by hand.
			local t = (s + 0.5 * (k - 1) + rng:NextNumber(-0.22, 0.22)) / steps * 2 * math.pi
			local u, v = lobe[1] + math.cos(t) * lobe[3], lobe[2] + math.sin(t) * lobe[3]
			local covered = false
			for j, other in ipairs(P.Lobes) do
				if j ~= k and math.sqrt((u - other[1]) ^ 2 + (v - other[2]) ^ 2) < other[3] + 0.4 then
					covered = true
				end
			end
			if not covered then
				stones += 1
				local h = 0.32 + rng:NextNumber() * 0.16
				local edge = outward * -math.sin(t) + along * math.cos(t)
				dt("PondRim" .. stones, Vector3.new(1 + rng:NextNumber() * 0.45, h, 0.75 + rng:NextNumber() * 0.2),
					CFrame.new(pondAt(u, v, h / 2 - 0.05)) * CFrame.Angles(0, math.atan2(-edge.Z, edge.X)
						+ rng:NextNumber(-0.3, 0.3), 0), if stones % 2 == 0 then G.Stone else T.StoneLight)
			end
		end
	end
	for k, pad in ipairs(P.Pads) do
		dt("PondPad" .. k, Vector3.new(0.05, pad[3], pad[3]), CFrame.new(pondAt(pad[1], pad[2], P.Rise + 0.055)) * flat,
			G.Leaves[3], Enum.PartType.Cylinder)
	end
	local pad1, pad2 = P.Pads[1], P.Pads[2]
	dt("PondBlossom1", Vector3.new(0.45, 0.45, 0.45), CFrame.new(pondAt(pad1[1] + 0.2, pad1[2], P.Rise + 0.25)), G.Petal,
		Enum.PartType.Ball)
	dt("PondBlossom2", Vector3.new(0.34, 0.34, 0.34), CFrame.new(pondAt(pad2[1], pad2[2] + 0.15, P.Rise + 0.2)), G.Mint,
		Enum.PartType.Ball, true)
	for k, reed in ipairs(P.Reeds) do
		local rng = Random.new(20261019 + k)
		local h = reed[3]
		local stem = CFrame.new(pondAt(reed[1], reed[2], 0))
			* CFrame.Angles(math.rad(rng:NextNumber(-7, 7)), 0, math.rad(rng:NextNumber(-7, 7)))
		dt("PondReed" .. k, Vector3.new(0.14, h, 0.14), stem * CFrame.new(0, h / 2, 0), G.Leaves[2])
		if k % 2 == 1 then
			dt("PondCattail" .. k, Vector3.new(0.7, 0.3, 0.3), stem * CFrame.new(0, h - 0.45, 0) * flat, G.TrunkDark,
				Enum.PartType.Cylinder)
		end
	end
	for k, f in ipairs(P.Fireflies) do
		dt("PondFirefly" .. k, Vector3.new(0.2, 0.2, 0.2), CFrame.new(pondAt(f[1], f[2], f[3])), G.Mint,
			Enum.PartType.Ball, true)
	end

	if parent then
		model.Parent = parent
	end
	return model
end

return MistDeckModel
