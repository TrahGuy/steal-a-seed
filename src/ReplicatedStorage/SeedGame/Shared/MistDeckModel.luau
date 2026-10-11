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
		neon: boolean?): Part
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
		p.Parent = model
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

	if parent then
		model.Parent = parent
	end
	return model
end

return MistDeckModel
