--!strict
--==============================================================================
-- Steal a Seed :: PodGuideStand (2026-10-09; GameConfig.PodGuide)
--
-- ONE BIOME'S POD STAND: where it stands, what it is built of, and the
-- carousel's five pods. PodGuideUI builds them on each client -- nothing here
-- replicates or talks to the server -- and PodGuideView letters the board.
--
--   THE FRAME     the carousel's centre on the ground just inside the biome's
--                 arch (Spots), facing the road: its LookVector points at the
--                 road's middle, so the board behind it reads from the road.
--   THE STAND     a turntable, the board on two posts behind it, a light rim
--                 round the board -- TOP CREATURES' woods. Inert, like that
--                 board: nothing collides, is queried or touched (the camera
--                 never pops in front of it).
--   THE CAROUSEL  the biome's five pods at PodTier, each Radius out from the
--                 centre on the turntable, facing out: the game's own pod
--                 builder (CreatureModel.BuildPod), marked PodShowcase so
--                 PodMotion idles them, never SeedPod (that is loot). turn()
--                 stands them round at an angle.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))

local CFG = GameConfig.PodGuide
local MAP = GameConfig.Map

local PodGuideStand = {}

-- The lettered plank's name, and the attribute naming a stand's biome.
PodGuideStand.BOARD = "Board"
PodGuideStand.BIOME_ATTRIBUTE = "BiomeId"

local OAK = Color3.fromRGB(126, 88, 54)
local OAK_DARK = Color3.fromRGB(92, 62, 38)
local PLANK = Color3.fromRGB(72, 54, 40)
local STONE = Color3.fromRGB(118, 112, 104)
local CAP = Color3.fromRGB(196, 186, 168)

export type Carousel = {
	pods: { Model },
	-- Each pod's pivot (its Shell) in its base's frame: turn() stands the base.
	offsets: { CFrame },
}

-- The stand's frame for a biome, or nil for one with no spot.
function PodGuideStand.frame(biomeId: string): CFrame?
	local biome = BiomeData.ById[biomeId]
	local spot = (CFG.Spots :: any)[biomeId]
	if not (biome and spot) then
		return nil
	end
	local nearZ = BiomeData.SegmentBounds(biome)
	local at = Vector3.new(spot.X, MAP.GroundY, nearZ - spot.In)
	return CFrame.lookAt(at, at + Vector3.new(-math.sign(spot.X), 0, 0))
end

-- The board's centre in a stand's frame: BoardBack behind the carousel.
function PodGuideStand.boardFrame(frame: CFrame): CFrame
	return frame * CFrame.new(0, CFG.BoardTopY - CFG.BoardSize.Y * 0.5, CFG.BoardBack)
end

local function part(name: string, size: Vector3, cframe: CFrame, colour: Color3, material: Enum.Material,
	parent: Instance): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = colour
	p.Material = material
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function disc(name: string, tall: number, radius: number, cframe: CFrame, colour: Color3,
	material: Enum.Material, parent: Instance): Part
	local p = part(name, Vector3.new(tall, radius * 2, radius * 2), cframe * CFrame.Angles(0, 0, math.pi / 2), colour,
		material, parent)
	p.Shape = Enum.PartType.Cylinder
	return p
end

-- The stand for a biome, in `parent`, or nil for one with no spot.
function PodGuideStand.build(biomeId: string, parent: Instance): Model?
	local frame = PodGuideStand.frame(biomeId)
	if not frame then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "PodGuide_" .. biomeId
	model:SetAttribute(PodGuideStand.BIOME_ATTRIBUTE, biomeId)
	local h = CFG.TurntableHeight
	disc("Turntable", h, CFG.TurntableRadius, frame * CFrame.new(0, h * 0.5, 0), STONE, Enum.Material.Slate, model)
	disc("Cap", 0.1, CFG.TurntableRadius - 0.35, frame * CFrame.new(0, h + 0.04, 0), CAP, Enum.Material.SmoothPlastic,
		model)
	-- The board on two posts, reaching up into its lower edge from behind.
	local board = PodGuideStand.boardFrame(frame)
	local size = CFG.BoardSize
	local bottom = CFG.BoardTopY - size.Y
	local postTall = bottom + 0.5
	local postBack = CFG.PostWidth * 0.5 - size.Z * 0.5 + 0.02
	for i, side in ipairs({ -1, 1 }) do
		part("Post" .. i, Vector3.new(CFG.PostWidth, postTall, CFG.PostWidth),
			frame * CFrame.new(side * (size.X * 0.5 - 1.4), postTall * 0.5, CFG.BoardBack + postBack), OAK_DARK,
			Enum.Material.Wood, model)
	end
	part(PodGuideStand.BOARD, size, board, PLANK, Enum.Material.WoodPlanks, model)
	part("Rim", size + Vector3.new(CFG.RimStuds * 2, CFG.RimStuds * 2, -0.1), board, OAK, Enum.Material.Wood, model)
	model.Parent = parent
	return model
end

-- The carousel's pod bases at `angle` (radians): each Radius out from the
-- centre on the turntable's top, facing out. The angle is brought into one
-- turn HERE, in double precision: the clock's angle is in the hundreds of
-- millions, and CFrame.Angles keeps a float's seven digits -- steps of thirty
-- radians, a carousel that never moved (seen in Play, 2026-10-09).
function PodGuideStand.podFrames(frame: CFrame, count: number, angle: number): { CFrame }
	local out: { CFrame } = {}
	local top = frame * CFrame.new(0, CFG.TurntableHeight, 0)
	for i = 1, count do
		local a = (angle + (i - 1) * 2 * math.pi / count) % (2 * math.pi)
		table.insert(out, top * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -CFG.Radius))
	end
	return out
end

-- The biome's five pods on a stand, in `parent`: the game's own pods, idled by
-- PodMotion (PodShowcase), never loot.
function PodGuideStand.buildPods(biomeId: string, frame: CFrame, parent: Instance): Carousel
	local plants = SeedData.InBiome(biomeId)
	local bases = PodGuideStand.podFrames(frame, #plants, 0)
	local carousel: Carousel = { pods = {}, offsets = {} }
	for i, sp in ipairs(plants) do
		local ok, model = pcall(CreatureModel.BuildPod, sp, CFG.PodTier, bases[i], parent)
		if ok and model then
			model.Name = "GuidePod_" .. sp.Id
			model:SetAttribute(GameConfig.PodModels.Motion.ShowcaseAttribute, true)
			table.insert(carousel.pods, model)
			table.insert(carousel.offsets, bases[i]:ToObjectSpace(model:GetPivot()))
		end
	end
	return carousel
end

-- The carousel stood round to `angle`.
function PodGuideStand.turn(carousel: Carousel, frame: CFrame, angle: number)
	local bases = PodGuideStand.podFrames(frame, #carousel.pods, angle)
	for i, pod in ipairs(carousel.pods) do
		if pod.Parent then
			pod:PivotTo(bases[i] * carousel.offsets[i])
		end
	end
end

return PodGuideStand
