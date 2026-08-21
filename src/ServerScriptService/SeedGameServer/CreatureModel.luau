--!strict
-- Steal a Seed :: CreatureModel
--
-- Builds the three things a species can be: the pod you steal, the sprout it
-- becomes when planted, and the creature it grows into.
--
-- NOT a *Service. No lifecycle, just geometry -- same as MapDecor and HubFairy.
--
--==============================================================================
-- ONE BULB WITH A FACE, NOT A BODY AND A HEAD
--
-- The obvious build is root, stem, body, head, face. This merges body and head
-- into a single bulb that carries the face, and that is not only a part count
-- saving. A separate head on a small creature reads as a lump on a stick; a
-- bulb with eyes reads as a character immediately, at any size, from any angle,
-- on a phone screen, across a field.
--
-- Ten parts for two eyes. Seventy-two of these in a server is the budget that
-- made rooted creatures possible at all, so the number matters.
--
--==============================================================================
-- ROOTED IS A PROMISE, NOT A LIMITATION
--
-- Nothing here has a Humanoid, a PrimaryPart that moves, or any network
-- ownership. A creature is an anchored model in a slot. Every bit of life it
-- has -- sway, blink, the head turning as you walk past -- is composed on each
-- CLIENT against the rest pose captured here, exactly like the fairy's wings.
--
-- The server owns where it is. The client owns what it is doing. They never
-- write the same property, which is why they cannot fight.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local CreatureModel = {}

export type Stage = number -- 1 pod, 2 sprout, 3 grown

CreatureModel.STAGE_POD = 1
CreatureModel.STAGE_SPROUT = 2
CreatureModel.STAGE_GROWN = 3

-- How big a sprout is relative to its grown self. Small enough that growth is
-- obviously incomplete from across the plot, big enough to tell what it is --
-- because knowing what is nearly ready is what makes a plot worth raiding.
local SPROUT_SCALE = 0.45

type PartOpts = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	parent: Instance,
	material: Enum.Material?,
	shape: Enum.PartType?,
	transparency: number?,
	glow: boolean?,
}

local function build(o: PartOpts): BasePart
	local part = Instance.new("Part")
	part.Name = o.name
	part.Size = o.size
	part.CFrame = o.cframe
	part.Color = o.color
	part.Material = o.material or Enum.Material.SmoothPlastic
	part.Shape = o.shape or Enum.PartType.Block
	part.Transparency = o.transparency or 0
	part.Anchored = true
	part.CanCollide = false
	-- Nothing here is ever queried by a raycast except through its model, and 72
	-- creatures is 720 parts the mouse would otherwise have to consider.
	part.CanQuery = false
	part.CanTouch = false
	-- Enum.SurfaceType, NOT Enum.NormalId -- they both have a Top and the
	-- assignment fails at runtime rather than at compile time. Smooth on
	-- purpose: the field and the beds are studded, but studs on a face at this
	-- size read as acne.
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = o.parent
	return part
end

--==============================================================================
-- THE POD
--
-- A rarity-coloured ovoid with a paler seam around its middle. The seam is what
-- makes it read as something that OPENS rather than as a stone, and it costs one
-- part.
--
-- Rarity colour rather than species colour, deliberately: while it is in your
-- hands the only question anybody has is how badly they want it.
--==============================================================================
function CreatureModel.BuildPod(species: SeedData.Species, cframe: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Pod_" .. species.Id
	model:SetAttribute("SpeciesId", species.Id)
	model:SetAttribute("Rarity", species.Rarity)
	model:SetAttribute("Stage", CreatureModel.STAGE_POD)
	model.Parent = parent

	-- THE CFRAME IS THE BASE, NOT THE CENTRE -- same contract as BuildCreature,
	-- whose root sits on the frame it is given. They disagreed at first and
	-- every pod rendered half sunk into the ground, because a caller placing one
	-- on a surface has no reason to expect two builders in one file to mean
	-- different things by the same argument.
	local POD_H = 2.0
	local base = cframe * CFrame.new(0, POD_H * 0.5, 0)

	local color = SeedData.PodColor(species)
	local shell = build({
		name = "Shell",
		size = Vector3.new(1.5, POD_H, 1.5),
		cframe = base,
		color = color,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	build({
		name = "Seam",
		size = Vector3.new(1.58, 0.18, 1.58),
		cframe = base * CFrame.new(0, 0.1, 0),
		color = species.Accent,
		shape = Enum.PartType.Ball,
		parent = model,
	})
	-- A single leaf tip, so even a pod says "plant" before it says "egg".
	build({
		name = "Tip",
		size = Vector3.new(0.35, 0.55, 0.12),
		cframe = base * CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.rad(18)),
		color = species.Leaf,
		parent = model,
	})

	model.PrimaryPart = shell
	if species.Glow then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Brightness = 1.4
		light.Range = 8
		light.Parent = shell
	end
	return model
end

--==============================================================================
-- THE CREATURE
--
-- Root mound, stem, bulb with a face, two leaves. Scaled whole for the sprout
-- stage, so a species is described once and both stages come from it -- a
-- separate sprout model would be a second thing to keep in step for no gain.
--==============================================================================
local function addEyes(model: Model, species: SeedData.Species, bulbCF: CFrame,
	bulbW: number, bulbD: number, bulbH: number, scale: number)
	local count = math.clamp(species.Eyes, 1, 3)
	local eyeR = bulbW * (count == 1 and 0.30 or 0.22)
	local spread = bulbW * 0.26

	for i = 1, count do
		-- Centred when odd, straddling the middle when even.
		local offset = (i - (count + 1) * 0.5) * spread * 2
		local at = bulbCF * CFrame.new(offset, bulbH * 0.12, -(bulbD * 0.5))
		build({
			name = "Eye",
			size = Vector3.new(eyeR, eyeR, eyeR * 0.6),
			cframe = at,
			color = Color3.fromRGB(252, 252, 250),
			shape = Enum.PartType.Ball,
			parent = model,
		})
		build({
			name = "Pupil",
			size = Vector3.new(eyeR * 0.5, eyeR * 0.5, eyeR * 0.5),
			cframe = at * CFrame.new(0, 0, -eyeR * 0.22),
			color = Color3.fromRGB(28, 26, 34),
			shape = Enum.PartType.Ball,
			parent = model,
		})
	end

	-- One dark sliver of a mouth. It does more for personality per part than
	-- anything else on the model.
	build({
		name = "Mouth",
		size = Vector3.new(bulbW * 0.30, bulbH * 0.06, 0.08),
		cframe = bulbCF * CFrame.new(0, -bulbH * 0.16, -(bulbD * 0.5) - 0.02),
		color = Color3.fromRGB(46, 34, 44),
		parent = model,
	})
end

function CreatureModel.BuildCreature(species: SeedData.Species, stage: Stage,
	cframe: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Creature_" .. species.Id
	model:SetAttribute("SpeciesId", species.Id)
	model:SetAttribute("Rarity", species.Rarity)
	model:SetAttribute("Stage", stage)
	model.Parent = parent

	local scale = if stage == CreatureModel.STAGE_SPROUT then SPROUT_SCALE else 1
	local H = species.Height * scale

	local rootH = 0.5 * scale
	local stemH = H * 0.30
	local bulbH = H * 0.55
	local bulbW = H * 0.46
	local bulbD = H * 0.40

	local rootCF = cframe * CFrame.new(0, rootH * 0.5, 0)
	local root = build({
		name = "Root",
		size = Vector3.new(bulbW * 0.9, rootH, bulbW * 0.9),
		cframe = rootCF,
		color = species.Leaf,
		material = Enum.Material.Plastic,
		parent = model,
	})

	build({
		name = "Stem",
		size = Vector3.new(H * 0.13, stemH, H * 0.13),
		cframe = cframe * CFrame.new(0, rootH + stemH * 0.5, 0),
		color = species.Leaf,
		parent = model,
	})

	--== THE BULB ==--
	--
	-- bulbCF stays UNROTATED whatever shape the bulb is, because the face is
	-- placed off it. A cylinder has to be tipped on its side to stand up --
	-- Roblox cylinders run along their local X -- and rotating the reference
	-- frame with it would send the eyes round the back.
	local bulbCF = cframe * CFrame.new(0, rootH + stemH + bulbH * 0.5, 0)

	local shape, bulbSize, bulbSpin = Enum.PartType.Block,
		Vector3.new(bulbW, bulbH, bulbD), CFrame.new()
	if species.Shape == "ball" then
		shape = Enum.PartType.Ball
		-- Balls ignore two of their three dimensions, so a ball bulb is sized
		-- by its width or it renders smaller than the block it replaced.
		bulbSize = Vector3.new(bulbW, bulbW, bulbW)
	elseif species.Shape == "cylinder" then
		shape = Enum.PartType.Cylinder
		bulbSize = Vector3.new(bulbH, bulbW, bulbW)
		bulbSpin = CFrame.Angles(0, 0, math.rad(90))
	end

	local bulb = build({
		name = "Bulb",
		size = bulbSize,
		cframe = bulbCF * bulbSpin,
		color = species.Body,
		-- ALWAYS SmoothPlastic, never Neon, even for glowing species. Neon
		-- clips to white at brightness and takes the face with it -- the fairy
		-- was a featureless white blob for exactly this reason. Glow goes on
		-- the CROWN and a PointLight, where losing detail costs nothing.
		material = Enum.Material.SmoothPlastic,
		shape = shape,
		parent = model,
	})

	--== LEAVES ==--
	-- Low on the stem and angled UP. The first version put them at the bulb
	-- join, small and flat, where they read as tiny shoulders rather than as
	-- leaves. Halfway down and tilted they frame the creature instead.
	for _, side in ipairs({ -1, 1 }) do
		build({
			name = "Leaf",
			size = Vector3.new(bulbW * 0.95, H * 0.07, bulbW * 0.52),
			cframe = cframe
				* CFrame.new(side * bulbW * 0.52, rootH + stemH * 0.5, 0)
				* CFrame.Angles(0, side * math.rad(12), side * math.rad(38)),
			color = species.Leaf,
			parent = model,
		})
	end

	--== THE CROWN ==--
	-- Petals or spikes radiating off the top. This is what stops eleven species
	-- reading as one species in eleven colours: at distance the crown is the
	-- whole silhouette, and a five-petal ball is nothing like a four-spike
	-- block even at the same size and hue.
	local crown = math.clamp(species.Crown or 0, 0, 8)
	if crown > 0 and species.CrownKind ~= "none" then
		local spike = species.CrownKind == "spike"
		local ring = bulbW * (spike and 0.34 or 0.42)
		for i = 1, crown do
			local angle = (i - 1) / crown * math.pi * 2
			local size = if spike
				then Vector3.new(bulbW * 0.16, bulbH * 0.55, bulbW * 0.16)
				else Vector3.new(bulbW * 0.52, H * 0.055, bulbW * 0.46)
			build({
				name = if spike then "Spike" else "Petal",
				size = size,
				cframe = bulbCF
					* CFrame.Angles(0, angle, 0)
					* CFrame.new(0, bulbH * (spike and 0.42 or 0.34), -ring)
					* CFrame.Angles(spike and math.rad(-28) or math.rad(-52), 0, 0),
				color = if spike then species.Accent else species.Accent,
				material = if species.Glow then Enum.Material.Neon
					else Enum.Material.SmoothPlastic,
				parent = model,
			})
		end
	end

	addEyes(model, species, bulbCF, bulbW, bulbD, bulbH, scale)

	if species.Glow then
		local light = Instance.new("PointLight")
		light.Color = species.Accent
		light.Brightness = 1.6
		light.Range = 10 * scale
		light.Parent = bulb
	end

	-- The ROOT is the PrimaryPart, not the bulb: a creature's pivot is where it
	-- meets the soil, so planting one is placing its pivot on a slot rather than
	-- working out how tall it is first.
	model.PrimaryPart = root
	CollectionService:AddTag(model, GameConfig.Tags.Creature)
	return model
end

-- Convenience: whichever shape this species should be at this stage.
function CreatureModel.Build(species: SeedData.Species, stage: Stage,
	cframe: CFrame, parent: Instance): Model
	if stage == CreatureModel.STAGE_POD then
		return CreatureModel.BuildPod(species, cframe, parent)
	end
	return CreatureModel.BuildCreature(species, stage, cframe, parent)
end

return CreatureModel
