--!strict
--==============================================================================
-- Steal a Seed :: MistDeckModel (2026-10-11, Enchanted Mist stage 3)
--
-- THE HUB DECK DURING A MIST (EnchantedMistConfig.Deck, the owner's pick of
-- the previews: A's moss carpet with C's mushroom fairy ring). A moss carpet
-- over the round deck, under the plaza's floor; a ring of mint-spotted
-- mushrooms near the deck's edge, the road's side left open. Overlays only:
-- every part anchored, none collides, is found by a ray or touches. Built by
-- MosskeeperService with the surround, gone whole with it.
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

	if parent then
		model.Parent = parent
	end
	return model
end

return MistDeckModel
