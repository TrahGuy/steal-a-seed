--!strict
-- Steal a Seed :: CreatureModel
--
-- Builds the pod you steal and the creature it grows into, to the Greenhollow
-- reference sheets in KB/biome1-plants.png and KB/biome1-pods.png.
--
-- NOT a *Service. No lifecycle, just geometry -- same as MapDecor and HubFairy.
--
--==============================================================================
-- ROBLOX HAS NO CONE, NO EGG, AND NO DOME
--
-- Four of the five forms on the sheet are shapes the engine cannot make. Every
-- one is approximated from Block, Ball and Cylinder, and the approximations are
-- written down here because the next person will otherwise assume a mesh went
-- missing:
--
--   teardrop  a Ball with two mirrored Wedges above it, which from the front
--             reads as a point rather than as a roof.
--   dome cap  a Cylinder disc with a Ball resting on it. A Ball alone cannot
--             do it -- Roblox sizes a Ball by its SMALLEST axis, so a wide flat
--             sphere is not a thing that exists.
--   bell      three stacked Cylinders widening downward. A cone by staircase.
--   egg       two overlapping Balls, the upper slightly smaller.
--
-- That Ball rule catches everyone once: setting a Ball to (4, 1, 4) does not
-- give a squashed sphere, it gives a sphere of diameter 1.
--
--==============================================================================
-- THE FACE IS THE WHOLE CHARACTER, AND IT IS SEVEN PARTS
--
-- Two black eyes, two white highlights, three blocks of smile. The highlights
-- are what make it read as alive rather than as a hole, and the smile is three
-- parts rather than one because a straight bar reads as a grimace -- offsetting
-- the ends upward by a hair is the entire difference between a creature that
-- looks pleased and one that looks unwell.
--
-- Budget: ~12 parts of body plus 0-8 of crown. Six plots of twelve slots is 72
-- creatures, so roughly 1,200 parts at tier 1. Worth watching as tiers grow.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local CreatureModel = {}

CreatureModel.STAGE_POD = 1
CreatureModel.STAGE_SPROUT = 2
CreatureModel.STAGE_GROWN = 3

export type Stage = number

-- Small enough that growth is obviously incomplete from across the plot, big
-- enough to tell what it is -- because knowing what is nearly ready is what
-- makes somebody else's plot worth watching.
local SPROUT_SCALE = 0.45

local DARK = Color3.fromRGB(38, 34, 40)
local WHITE = Color3.fromRGB(252, 252, 250)

type Opts = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	parent: Instance,
	shape: Enum.PartType?,
	material: Enum.Material?,
	-- Studded unless told otherwise. Only the face opts out.
	studs: boolean?,
}

--==============================================================================
-- STUDS GO ON EVERYTHING, INCLUDING THE ROUND PARTS
--
-- Worth stating because the obvious assumption is wrong: Roblox renders surface
-- studs on Ball and Cylinder parts too, not only on Blocks -- they wrap round
-- the curve. Tested before relying on it, because building the creatures out of
-- blocks to "make studs possible" would have thrown away the shapes.
--
-- Material must be Plastic. SmoothPlastic has no studs at all, and Ground,
-- Grass and WoodPlanks paint their own noise OVER the studs -- which is the
-- trap that made the plot beds look smooth next to a studded field.
--
-- All six faces, not just the top: a creature is seen from every side, and
-- studs on the top alone reads as a manufacturing defect.
--==============================================================================
local STUD_FACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}

local function part(o: Opts): BasePart
	local p = Instance.new("Part")
	p.Name = o.name
	p.Size = o.size
	p.CFrame = o.cframe
	p.Color = o.color
	p.Shape = o.shape or Enum.PartType.Block
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false

	local studded = o.studs ~= false
	p.Material = o.material or (if studded then Enum.Material.Plastic
		else Enum.Material.SmoothPlastic)
	-- Enum.SurfaceType, not Enum.NormalId. Both have a Top, and the wrong one
	-- fails at runtime rather than at compile time.
	local surface = if studded then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	for _, face in ipairs(STUD_FACES) do
		(p :: any)[face] = surface
	end
	p.Parent = o.parent
	return p
end

-- An upright cylinder. Roblox cylinders run along their LOCAL X, so standing
-- one up is a 90-degree roll, and the caller should not have to remember that.
local function upright(name: string, height: number, diameter: number, cf: CFrame,
	color: Color3, parent: Instance, studs: boolean?): BasePart
	return part({
		name = name,
		size = Vector3.new(height, diameter, diameter),
		cframe = cf * CFrame.Angles(0, 0, math.rad(90)),
		color = color,
		shape = Enum.PartType.Cylinder,
		parent = parent,
		studs = studs,
	})
end

local function ball(name: string, diameter: number, cf: CFrame, color: Color3,
	parent: Instance, studs: boolean?): BasePart
	return part({
		name = name,
		size = Vector3.new(diameter, diameter, diameter),
		cframe = cf,
		color = color,
		shape = Enum.PartType.Ball,
		parent = parent,
		studs = studs,
	})
end

local function wedge(name: string, size: Vector3, cf: CFrame, color: Color3,
	parent: Instance): BasePart
	local p = Instance.new("WedgePart")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	for _, face in ipairs(STUD_FACES) do
		pcall(function()
			(p :: any)[face] = Enum.SurfaceType.Studs
		end)
	end
	p.Parent = parent
	return p
end

--==============================================================================
-- THE FACE
--
-- Placed on the front of whatever head the form produced. `front` is the local
-- -Z offset of the head's surface, because -Z is the facing direction.
--==============================================================================
local function addFace(model: Model, headCF: CFrame, width: number, front: number)
	local eyeW = width * 0.17
	local eyeH = width * 0.21
	local gap = width * 0.21

	for _, side in ipairs({ -1, 1 }) do
		local eyeCF = headCF * CFrame.new(side * gap, width * 0.06, -front)
		part({
			name = "Eye",
			size = Vector3.new(eyeW, eyeH, 0.08),
			cframe = eyeCF,
			color = DARK,
			parent = model,
			-- The face is the one thing that stays smooth. A stud on a
			-- 0.3-stud eye is a blister, not a texture.
			studs = false,
		})
		-- The glint. Upper-LEFT of each eye on both sides, not mirrored --
		-- a shared light source is what makes two eyes read as one face.
		part({
			name = "Glint",
			size = Vector3.new(eyeW * 0.34, eyeH * 0.30, 0.08),
			cframe = eyeCF * CFrame.new(-eyeW * 0.22, eyeH * 0.24, -0.02),
			color = WHITE,
			parent = model,
			studs = false,
		})
	end

	-- Three blocks of smile. A single bar reads as a grimace; lifting the ends
	-- by a hair is the whole difference between pleased and unwell.
	local mw = width * 0.10
	for i, spec in ipairs({ { -1, 0.030 }, { 0, 0 }, { 1, 0.030 } }) do
		local sx: number, lift: number = spec[1], spec[2]
		part({
			name = "Smile",
			size = Vector3.new(mw, width * 0.045, 0.08),
			cframe = headCF * CFrame.new(sx * mw * 0.92, -width * 0.15 + lift * width, -front),
			color = DARK,
			parent = model,
			studs = false,
		})
	end
end

--==============================================================================
-- THE CROWNS
--==============================================================================
local function addFlower(model: Model, sp: SeedData.Species, top: CFrame, w: number)
	-- Five petals flat around a centre, as on the sheet.
	for i = 1, 5 do
		local a = (i - 1) / 5 * math.pi * 2
		part({
			name = "Petal",
			size = Vector3.new(w * 0.38, w * 0.11, w * 0.30),
			cframe = top * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -w * 0.28),
			color = sp.Crown,
			parent = model,
		})
	end
	ball("FlowerCentre", w * 0.24, top, sp.Accent, model)
end

local function addSpikes(model: Model, sp: SeedData.Species, top: CFrame, w: number, h: number)
	-- Three upright leaf-spikes: one tall in the middle, two shorter leaning out.
	for _, spec in ipairs({ { 0, 1.0, 0 }, { -1, 0.68, 26 }, { 1, 0.68, -26 } }) do
		local sx: number, scale: number, tilt: number = spec[1], spec[2], spec[3]
		part({
			name = "Spike",
			size = Vector3.new(w * 0.16, h * 0.30 * scale, w * 0.13),
			cframe = top
				* CFrame.new(sx * w * 0.28, h * 0.13 * scale, 0)
				* CFrame.Angles(0, 0, math.rad(tilt)),
			color = sp.Crown,
			parent = model,
		})
	end
end

local function addFronds(model: Model, sp: SeedData.Species, top: CFrame, w: number)
	-- The drooping green fronds over the mushroom cap.
	for i = 1, 3 do
		local a = (i - 1) / 3 * math.pi * 2
		local arm = top * CFrame.Angles(0, a, 0)
		part({
			name = "Frond",
			size = Vector3.new(w * 0.09, w * 0.42, w * 0.09),
			cframe = arm * CFrame.new(0, w * 0.20, -w * 0.10),
			color = sp.Leaf,
			parent = model,
		})
		part({
			name = "FrondTip",
			size = Vector3.new(w * 0.22, w * 0.09, w * 0.16),
			cframe = arm * CFrame.new(0, w * 0.36, -w * 0.30)
				* CFrame.Angles(math.rad(-38), 0, 0),
			color = sp.Leaf,
			parent = model,
		})
	end
end

local function addBuds(model: Model, sp: SeedData.Species, top: CFrame, w: number)
	-- A ring of stalked buds, as on the Bellchime.
	for i = 1, 7 do
		local a = (i - 1) / 7 * math.pi * 2
		local lean = (i % 2 == 0) and 1.0 or 0.76
		local arm = top * CFrame.Angles(0, a, 0)
		local reach = w * 0.26
		part({
			name = "BudStalk",
			size = Vector3.new(w * 0.05, w * 0.40 * lean, w * 0.05),
			cframe = arm * CFrame.new(0, w * 0.20 * lean, -reach * 0.7)
				* CFrame.Angles(math.rad(-11), 0, 0),
			color = sp.Accent,
			parent = model,
		})
		ball("Bud", w * 0.18, arm * CFrame.new(0, w * 0.42 * lean, -reach), sp.Crown, model)
	end
end

--==============================================================================
-- THE CREATURE
--
-- Soil mound, stem, two leaves, a head that depends on the form, a face, and a
-- crown. The CFrame handed in is the BASE -- where it meets the ground.
--==============================================================================
function CreatureModel.BuildCreature(sp: SeedData.Species, stage: Stage,
	cf: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Creature_" .. sp.Id
	model:SetAttribute("SpeciesId", sp.Id)
	model:SetAttribute("Rarity", sp.Rarity)
	model:SetAttribute("Kg", sp.Kg)
	model:SetAttribute("Stage", stage)
	model.Parent = parent

	local scale = if stage == CreatureModel.STAGE_SPROUT then SPROUT_SCALE else 1
	local H = sp.Height * scale
	--==========================================================================
	-- TWO SCALARS, NOT ONE. H IS TALLNESS, G IS FATNESS.
	--
	-- Every horizontal dimension used to be a fraction of H, so bulk tracked
	-- HEIGHT and nothing at all tracked WEIGHT -- a 2 kg Nubkin and a 110 kg
	-- Bellchime came out 1.67x apart in width across a 55x weight range, and
	-- the Bellchime was proportionally the slimmer of the two.
	--
	-- G multiplies the width terms only. It is applied in FOUR places -- mound,
	-- stem, leaves, headW -- because every other horizontal measurement in the
	-- forms below is already derived from headW, so they inherit it for free.
	--==========================================================================
	local G = SeedData.Girth(sp)

	--== MOUND ==--
	local moundH = H * 0.11
	local mound = upright("Mound", moundH, H * 0.66 * G, cf * CFrame.new(0, moundH * 0.5, 0),
		sp.Soil, model)

	--== STEM ==--
	local stemH = H * 0.34
	local stemBase = moundH * 0.7
	upright("Stem", stemH, H * 0.13 * G, cf * CFrame.new(0, stemBase + stemH * 0.5, 0),
		SeedData.Stem, model)

	--== LEAVES ==--
	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "Leaf",
			-- X and Z are the leaf's length and width and take G; Y is its
			-- thickness and does not.
			size = Vector3.new(H * 0.27 * G, H * 0.05, H * 0.12 * G),
			cframe = cf
				* CFrame.new(side * H * 0.16 * G, stemBase + stemH * 0.40, 0)
				-- Down and out. Level bars read as propellers, which is exactly
				-- what the first build looked like.
				* CFrame.Angles(0, side * math.rad(16), side * math.rad(-13)),
			color = sp.Leaf,
			parent = model,
		})
	end

	--== HEAD ==--
	-- The one that matters: the head, the cap, the bell tiers, the flower, the
	-- spikes, the buds, the fronds and the face are all measured off headW.
	local headW = H * 0.46 * G
	local headCentreY = stemBase + stemH + headW * 0.46
	local headCF = cf * CFrame.new(0, headCentreY, 0)
	local topCF = headCF * CFrame.new(0, headW * 0.5, 0)

	-- WHERE THE FACE GOES IS PER-FORM, and it has to be, because the widest
	-- part of a head is not always the part the face sits on. The bell proved
	-- it: one shared `front` put the smile at local z -0.78 inside a skirt of
	-- radius 0.99, so the creature had eyes and no mouth and nobody could see
	-- why. Each branch sets these three explicitly now.
	local faceCF = headCF
	local faceW = headW
	local front = headW * 0.5

	if sp.Form == "cube" then
		part({ name = "Head", size = Vector3.new(headW, headW, headW),
			cframe = headCF, color = sp.Body, parent = model })

	elseif sp.Form == "orb" then
		ball("Head", headW, headCF, sp.Body, model)
		front = headW * 0.46
		addFlower(model, sp, topCF * CFrame.new(0, headW * 0.06, 0), headW)

	elseif sp.Form == "teardrop" then
		ball("Head", headW, headCF, sp.Body, model)
		front = headW * 0.46
		-- Two mirrored wedges make a point from the front rather than a roof.
		for _, side in ipairs({ -1, 1 }) do
			wedge("HeadPoint", Vector3.new(headW * 0.5, headW * 0.52, headW * 0.5),
				headCF * CFrame.new(side * headW * 0.25, headW * 0.44, 0)
					* CFrame.Angles(0, side > 0 and 0 or math.pi, 0),
				sp.Body, model)
		end
		addSpikes(model, sp, topCF * CFrame.new(0, headW * 0.38, 0), headW, H)

	elseif sp.Form == "mushroom" then
		ball("Head", headW * 0.86, headCF, sp.Body, model)
		faceW = headW * 0.86
		front = headW * 0.42
		local capY = headW * 0.42
		upright("CapDisc", headW * 0.16, headW * 1.32,
			headCF * CFrame.new(0, capY, 0), sp.Crown, model)
		ball("CapDome", headW * 1.10, headCF * CFrame.new(0, capY + headW * 0.10, 0),
			sp.Crown, model)
		-- Spots, set into the dome's upper face.
		for i = 1, 5 do
			local a = (i - 1) / 5 * math.pi * 2
			upright("Spot", headW * 0.05, headW * 0.24,
				headCF * CFrame.Angles(0, a, 0)
					* CFrame.new(0, capY + headW * 0.36, -headW * 0.40),
				sp.Accent, model)
		end
		addFronds(model, sp, headCF * CFrame.new(0, capY + headW * 0.44, 0), headW)

	else -- "bell"
		-- A cone by staircase. Four tiers rather than three, and a wider spread
		-- top to bottom: at 0.62-to-1.08 the flare was too slight to read as a
		-- skirt and the whole thing looked like a lump.
		local tiers = { { 0.50, 0.40 }, { 0.74, 0.16 }, { 1.00, -0.08 }, { 1.20, -0.30 } }
		for _, t in ipairs(tiers) do
			local d: number, dy: number = t[1], t[2]
			upright("BellTier", headW * 0.28, headW * d,
				headCF * CFrame.new(0, dy * headW, 0), sp.Body, model)
		end
		upright("Collar", headW * 0.16, headW * 0.58,
			headCF * CFrame.new(0, headW * 0.54, 0), sp.Accent, model)
		addBuds(model, sp, headCF * CFrame.new(0, headW * 0.60, 0), headW)
		-- The face rides the WIDE lower skirt, which is where the sheet puts it,
		-- so `front` is that tier's radius rather than the head's.
		faceCF = headCF * CFrame.new(0, -headW * 0.10, 0)
		faceW = headW * 1.00
		front = headW * 0.60
	end

	addFace(model, faceCF, faceW, front + 0.04)

	-- PrimaryPart is the MOUND: a creature's pivot is where it meets the soil,
	-- so planting one is placing its pivot on a slot rather than working out how
	-- tall it is first.
	model.PrimaryPart = mound
	CollectionService:AddTag(model, GameConfig.Tags.Creature)
	return model
end

--==============================================================================
-- THE POD
--
-- Egg, jagged seam, curled tendril -- the pod sheet. Rarity colour, not species
-- colour: while it is in your hands the only question anybody has is how badly
-- they want it.
--==============================================================================
function CreatureModel.BuildPod(sp: SeedData.Species, cf: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Pod_" .. sp.Id
	model:SetAttribute("SpeciesId", sp.Id)
	model:SetAttribute("Rarity", sp.Rarity)
	model:SetAttribute("Kg", sp.Kg)
	model:SetAttribute("Stage", CreatureModel.STAGE_POD)
	model.Parent = parent

	-- THE CFRAME IS THE BASE, not the centre -- same contract as BuildCreature,
	-- because two builders in one file meaning different things by the same
	-- argument is a trap for every caller.
	-- Size comes from weight, so the pod tells you what it will cost to carry
	-- before you commit to the hold. See SeedData.PodDiameter.
	local D = SeedData.PodDiameter(sp)
	local color = SeedData.PodColor(sp)
	local baseCF = cf * CFrame.new(0, D * 0.5, 0)

	-- Egg: two overlapping balls, the upper smaller. A Ball is sized by its
	-- smallest axis, so a single elongated one is not available.
	local shell = ball("Shell", D, baseCF, color, model)
	ball("Crown", D * 0.84, baseCF * CFrame.new(0, D * 0.34, 0), color, model)

	-- The seam. A disc a hair proud of the shell, slightly darkened -- the
	-- sheet's zigzag is not worth twenty parts to reproduce, and at a distance
	-- what reads is that there IS a seam.
	upright("Seam", D * 0.07, D * 1.02, baseCF * CFrame.new(0, D * 0.02, 0),
		color:Lerp(Color3.new(0, 0, 0), 0.18), model)

	-- The curled tendril, four blocks around a quarter turn.
	local tip = baseCF * CFrame.new(0, D * 0.62, 0)
	for i = 1, 4 do
		local t = (i - 1) / 4
		tip = tip * CFrame.new(0, D * 0.13, 0) * CFrame.Angles(0, 0, math.rad(38))
		part({
			name = "Tendril",
			size = Vector3.new(D * 0.10, D * 0.16, D * 0.10),
			cframe = tip,
			color = Color3.fromRGB(104, 158, 62),
			parent = model,
		})
	end

	model.PrimaryPart = shell
	--==========================================================================
	-- IT DOES NOT TAG ITSELF SeedPod. THE CALLER DECIDES WHAT A POD MEANS.
	--
	-- This used to add the tag here, which quietly made every pod in the game
	-- loot -- including the three that are not. Five callers, and only two want
	-- it: a nest pod and a dropped pod are takeable; a pod welded to your head,
	-- a pod being used as a Tool handle, and a pod HATCHING IN SOMEBODY'S PLOT
	-- are not.
	--
	-- The plot case was a live bug: a planted pod grew a Take prompt, and taking
	-- it ran the whole raid alarm -- RUN, then SAFE -- in the middle of the safe
	-- zone, for a pod the player had just carried home themselves.
	--
	-- Whether a thing is loot is a gameplay claim. A geometry builder has no
	-- business making it.
	--==========================================================================
	return model
end

function CreatureModel.Build(sp: SeedData.Species, stage: Stage, cf: CFrame,
	parent: Instance): Model
	if stage == CreatureModel.STAGE_POD then
		return CreatureModel.BuildPod(sp, cf, parent)
	end
	return CreatureModel.BuildCreature(sp, stage, cf, parent)
end

return CreatureModel
