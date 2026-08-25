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
-- THE FACE IS MOULDED, NOT PRINTED
--
-- Every piece of it used to be 0.08 studs thick and smooth: two Eye cards, two
-- Glints, two Cheeks and three Smile bars, all lying flat against the front of
-- the head. That is a DECAL made of parts. It disappeared from any angle off
-- dead centre -- and now that plants walk and each one stands on its own
-- bearing, dead centre is exactly where the player usually is not.
--
-- The comment that used to live here said a stud on a 0.3-stud eye is a
-- blister rather than a texture. That was true OF A CARD. It is not true of a
-- ball: a creature in this game is moulded plastic, and its eyes are lumps of
-- the same plastic, not stickers on it.
--
--     eyes     dark balls, centred ON the surface so half stands proud
--     glints   smaller balls sitting on the eyes
--     cheeks   balls, outboard and low
--     smile    still three blocks -- one bar reads as a grimace -- but deep
--
-- ONE SHARED LIGHT. The glint sits upper-LEFT on BOTH eyes rather than being
-- mirrored. That is what makes two spheres read as one face lit from one side
-- instead of two googly eyes.
--
-- `front` is the surface the face sits on and it is per-form for a reason: the
-- widest part of a head is not always the part the face is on. The bell proved
-- it once already, with a smile inside its own skirt.
--==============================================================================
local function addFace(model: Model, headCF: CFrame, width: number, front: number)
	local eyeD = width * 0.23
	local gap = width * 0.23

	for _, side in ipairs({ -1, 1 }) do
		-- Centred on the surface, so half the ball is outside the head. No
		-- fudge factor: the radius IS the proudness.
		local eyeCF = headCF * CFrame.new(side * gap, width * 0.06, -front)
		ball("Eye", eyeD, eyeCF, DARK, model)
		-- Smooth, and only this. A glint is the one thing on a creature that is
		-- meant to look wet.
		ball("Glint", eyeD * 0.34,
			eyeCF * CFrame.new(-eyeD * 0.26, eyeD * 0.24, -eyeD * 0.30),
			WHITE, model, false)
	end

	--==========================================================================
	-- CHEEKS SIT CLOSE, BECAUSE THE HEAD IS ROUND
	--
	-- `front` is the surface distance at the CENTRE of the face. Four of the
	-- five heads are spheres, so the real surface falls away as you move out --
	-- at 1.9 gaps from centre on an orb it has dropped 0.19 of a head width
	-- behind `front`, and a ball placed there hangs in the air beside the head.
	--
	-- It got away with that as a flat card because a card that thin reads as
	-- part of the outline from the front and is invisible from the side. A
	-- sphere does not: it is visible from everywhere, floating included.
	--
	-- 1.45 gaps is the furthest out the error stays under a cheek's own radius
	-- on every one of the five, and 0.88 of `front` sets it just into the skin.
	-- No per-form parameter needed, which is worth more than the extra reach.
	--==========================================================================
	for _, side in ipairs({ -1, 1 }) do
		ball("Cheek", width * 0.15,
			headCF * CFrame.new(side * gap * 1.45, -width * 0.08, -front * 0.88),
			SeedData.Blush, model)
	end

	-- Lifting the ends by a hair is the whole difference between pleased and
	-- unwell. Smooth, like the eyes' glints -- a mouth is a line, and studs on
	-- one really would be a blister.
	local mw = width * 0.10
	for _, spec in ipairs({ { -1, 0.030 }, { 0, 0 }, { 1, 0.030 } }) do
		local sx: number, lift: number = spec[1], spec[2]
		part({
			name = "Smile",
			size = Vector3.new(mw, width * 0.05, width * 0.07),
			cframe = headCF * CFrame.new(sx * mw * 0.92,
				-width * 0.15 + lift * width, -front * 0.99),
			color = DARK,
			parent = model,
			studs = false,
		})
	end
end

--==============================================================================
-- THE CROWNS
--==============================================================================
--==============================================================================
-- A FLOWER WITH A BACK TO IT
--
-- Five petals lying flat in one plane is a paper daisy: edge-on from the side
-- it vanishes to five lines, and there was nothing underneath it at all -- the
-- flower simply started in mid-air above a bald orb.
--
-- Three changes, no extra petals: they TILT UP so the flower is a shallow bowl
-- rather than a disc, they are thicker, and a ring of three SEPALS sits under
-- them in the leaf colour. The sepals are what make it grow out of the head
-- instead of resting on it.
--==============================================================================
local function addFlower(model: Model, sp: SeedData.Species, top: CFrame, w: number)
	-- Under the petals and offset half a step round, so they show through the
	-- gaps rather than hiding directly behind.
	for i = 1, 3 do
		local a = (i - 1) / 3 * math.pi * 2 + math.pi / 5
		part({
			name = "Sepal",
			size = Vector3.new(w * 0.20, w * 0.09, w * 0.34),
			cframe = top
				* CFrame.Angles(0, a, 0)
				* CFrame.new(0, -w * 0.11, -w * 0.20)
				* CFrame.Angles(math.rad(24), 0, 0),
			color = sp.Leaf,
			parent = model,
		})
	end
	for i = 1, 5 do
		local a = (i - 1) / 5 * math.pi * 2
		part({
			name = "Petal",
			size = Vector3.new(w * 0.38, w * 0.13, w * 0.32),
			cframe = top
				* CFrame.Angles(0, a, 0)
				* CFrame.new(0, 0, -w * 0.28)
				-- Cupped. Every petal lifts its outer edge by the same amount,
				-- which turns five flat cards into one shallow bowl.
				* CFrame.Angles(math.rad(-17), 0, 0),
			color = sp.Crown,
			parent = model,
		})
	end
	ball("FlowerCentre", w * 0.26, top * CFrame.new(0, w * 0.04, 0), sp.Accent, model)
end

--==============================================================================
-- SIX SPIKES, NOT THREE
--
-- Three big ones in a flat row read as a fan seen edge-on: from the side the
-- Spiretip had a crest, from the front it had a stick. The sheet has a RING of
-- smaller ones round the crown, which reads the same from every angle -- which
-- matters more now that plants walk and face different ways.
--
-- Turned as well as tilted, so each leans OUT from the centre rather than all
-- of them leaning within one plane.
--==============================================================================
local SPIRE_SPIKES = {
	-- turn round the crown, height, lean out
	{ 0.00, 1.00, 6 },
	{ 0.17, 0.72, 22 },
	{ 0.33, 0.86, 15 },
	{ 0.50, 0.66, 24 },
	{ 0.67, 0.90, 13 },
	{ 0.84, 0.74, 20 },
}

local function addSpikes(model: Model, sp: SeedData.Species, top: CFrame, w: number, h: number)
	for _, spec in ipairs(SPIRE_SPIKES) do
		local turn: number, scale: number, lean: number = spec[1], spec[2], spec[3]
		part({
			name = "Spike",
			size = Vector3.new(w * 0.13, h * 0.26 * scale, w * 0.11),
			cframe = top
				* CFrame.Angles(0, turn * math.pi * 2, 0)
				* CFrame.new(0, h * 0.11 * scale, -w * 0.24)
				* CFrame.Angles(math.rad(-lean), 0, 0),
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

--==============================================================================
-- THE DIRT IT GROWS OUT OF
--
-- What was here before was ONE CYLINDER, 0.66 of the frame height across, and it
-- read as a hockey puck. Worse, it scaled with the frame: a 10,000 kg Bellchime
-- stood on a twenty-four stud brown pancake, so the biggest thing you could
-- grow was also the one that looked most like furniture.
--
-- The reference sheet has no plinth. It has a LOOSE HEAP -- a few clods of dirt
-- shoved up around the stem, irregular enough that no angle shows a circle, low
-- enough that the leaves hang over it. That is what this builds.
--
-- SEVEN BLOCKS, deterministic, overlapping and part-buried. Not spheres: a
-- Roblox Ball takes its diameter from its smallest axis, so a squashed lump is
-- not available without a mesh, and a tilted block reads as a clod perfectly
-- well. Not random: every other decoration in this file is a literal table for
-- the same reason -- two servers must build the same creature, and a bug report
-- that says "the third one looked wrong" has to mean something.
--
-- The first pass used six, spaced, sitting flat on the surface. They read as
-- separate BRICKS with gaps between them, which is worse than the puck was. It
-- takes overlap, a fifth of each clod buried, and a few degrees of tilt before
-- the eye stops counting them and starts seeing a heap.
--
-- Nine became seven when the heads were remodelled. Seven still overlaps into
-- one heap; the two it cost bought a brow, a collar and a set of sepals, which
-- are at eye level rather than under the leaves.
--
-- Sized off the STEM, not off the frame. That is the whole fix: dirt belongs to
-- the thing growing out of it, and a heavier plant gets a thicker stem and a
-- proportionally bigger heap rather than a bigger pancake.
--
-- Smooth, against a studded bed. The heap is the one thing here that is not
-- moulded plastic, and dropping the studs is what says so.
--==============================================================================
-- turn round the stem, distance out, width, height, yaw, and a tilt
local SOIL_CLODS = {
	-- Highest at the stem and thinning outward, so the heap has a peak rather
	-- than being a ring of debris.
	{ 0.00, 0.00, 1.70, 0.95, 0, 0 },
	{ 0.09, 0.80, 1.35, 0.80, 18, 7 },
	{ 0.24, 1.34, 1.05, 0.58, -34, -5 },
	{ 0.38, 0.60, 1.20, 0.88, 41, 9 },
	{ 0.53, 1.42, 0.95, 0.62, -12, 6 },
	{ 0.68, 0.84, 1.40, 0.82, 27, -8 },
	{ 0.84, 1.30, 1.00, 0.60, -39, 5 },
}

local function addSoil(model: Model, sp: SeedData.Species, cf: CFrame, stemW: number)
	for _, clod in ipairs(SOIL_CLODS) do
		local turn: number, out: number = clod[1], clod[2]
		local wide: number, tall: number = clod[3], clod[4]
		local yaw: number, tilt: number = clod[5], clod[6]
		local w = stemW * wide
		local h = stemW * tall
		part({
			name = "Soil",
			-- Deeper than wide by a fifth, so even the silhouette of one clod
			-- is not square.
			size = Vector3.new(w, h, w * 0.8),
			cframe = cf
				* CFrame.Angles(0, turn * math.pi * 2, 0)
				-- 0.38 rather than 0.5: each clod is a fifth buried, which is
				-- what merges nine boxes into one heap instead of nine boxes.
				--
				-- The tilt sinks the low corner further -- 1.2 studs under the
				-- surface on a 10,000 kg Bellchime. That is deliberate and it
				-- is not visible: planted, it is inside the bed; carried, the
				-- base rides below foot height so the overhang is inside the
				-- floor. PlantSway's anchor drops with it and the walk carries
				-- that same Y through, so nothing sinks or floats.
				* CFrame.new(0, h * 0.38, -stemW * out)
				* CFrame.Angles(math.rad(tilt * 0.6), math.rad(yaw), math.rad(tilt)),
			color = sp.Soil,
			parent = model,
			studs = false,
		})
	end
end

local function addBuds(model: Model, sp: SeedData.Species, top: CFrame, w: number)
	-- A ring of stalked buds, as on the Bellchime. Four rather than seven: two
	-- parts each makes this the most expensive decoration in the file, and the
	-- bell is already the busiest form. Four still reads as a ring and the
	-- alternating lean keeps it from looking like a compass rose.
	for i = 1, 4 do
		local a = (i - 1) / 4 * math.pi * 2
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
-- An invisible pivot plate, a heap of dirt clods, stem, two leaves, a head that
-- depends on the form, a face, and a crown. The CFrame handed in is the BASE --
-- where it meets the ground.
--==============================================================================
--==============================================================================
-- WEIGHT IS AN ARGUMENT NOW, NOT A PROPERTY OF THE SPECIES
--
-- `kg` is the weight THIS pod rolled. It decides how big the thing is, what it
-- earns and what colour its shell was. The species decides only the form.
--
-- Nothing here may read `sp.Kg`. That field is the fallback for a plant saved
-- before weights were rolled, and a spawn that used it would be a creature
-- whose size disagreed with its own price tag.
--==============================================================================
function CreatureModel.BuildCreature(sp: SeedData.Species, kg: number, stage: Stage,
	cf: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Creature_" .. sp.Id
	model:SetAttribute("SpeciesId", sp.Id)
	-- The FORM's drop tier, for anything listing shapes. What this one is worth
	-- is its Kg, and its band is SeedData.RarityForKg.
	model:SetAttribute("Rarity", sp.Rarity)
	model:SetAttribute("Kg", kg)
	model:SetAttribute("Stage", stage)
	model.Parent = parent

	local scale = if stage == CreatureModel.STAGE_SPROUT then SPROUT_SCALE else 1
	-- The species frame, scaled by what this one weighs.
	local H = SeedData.FrameHeight(sp, kg) * scale
	--==========================================================================
	-- TWO SCALARS, NOT ONE. H IS TALLNESS, G IS FATNESS.
	--
	-- Every horizontal dimension used to be a fraction of H, so bulk tracked
	-- HEIGHT and nothing at all tracked WEIGHT -- a 2 kg Nubkin and a 110 kg
	-- Bellchime came out 1.67x apart in width across a 55x weight range, and
	-- the Bellchime was proportionally the slimmer of the two.
	--
	-- G multiplies the width terms only. It is applied in THREE places now --
	-- stem, leaves, headW -- because every other horizontal measurement in the
	-- forms below is already derived from one of them, so they inherit it for
	-- free. The dirt heap comes off the stem width, which already carries it.
	--==========================================================================
	local G = SeedData.Girth(kg)

	local stemW = H * 0.13 * G

	--==========================================================================
	-- THE PIVOT IS A PLATE NOBODY SEES
	--
	-- Everything downstream needs a part at the creature's ground contact and
	-- needs it to be the PrimaryPart: PlantService places by that pivot,
	-- PlantSway leans and walks about it, CarryService welds it low in the
	-- hands, and the Hatch and Pick Up prompts hang off it.
	--
	-- None of that requires it to be VISIBLE, and the old mound was only ever
	-- visible by accident -- it was the pivot and the decoration at once, so
	-- getting rid of the puck meant getting rid of the anchor for four systems.
	-- Splitting them costs one invisible part and settles it.
	--
	-- A BLOCK, NOT A ROLLED CYLINDER, AND THAT IS A FIX. `upright` builds its
	-- cylinders rotated ninety degrees about Z so their length runs up the
	-- world Y -- which meant the model's pivot had its local X pointing at the
	-- sky. Harmless while the plant is in the ground, because PlantSway leans
	-- about a computed upright anchor rather than about the pivot. NOT harmless
	-- when carried: giveTool sets `handle.CFrame = root.CFrame * grip` and
	-- everything else is welded to it, so a rolled handle carried the whole
	-- plant on its side. This is axis-aligned, so a held creature stands up.
	--==========================================================================
	local base = part({
		name = "Base",
		size = Vector3.new(stemW * 1.2, 0.06, stemW * 1.2),
		cframe = cf * CFrame.new(0, 0.03, 0),
		color = sp.Soil,
		parent = model,
		studs = false,
	})
	base.Transparency = 1

	--== THE DIRT ==--
	addSoil(model, sp, cf, stemW)

	--==========================================================================
	-- THE STEM STARTS AT THE BED
	--
	-- It used to start at `moundH * 0.7`, sunk three tenths into the puck so it
	-- did not look planted on top of one. With the puck gone that offset would
	-- be a stem hovering a fraction of a stud over the soil, so the base goes
	-- to zero and the stem grows the difference.
	--
	-- 0.417 is not a new number: it is exactly what `moundH * 0.7 + H * 0.34`
	-- came to. The head therefore sits at precisely the height it sat at
	-- before, every finished-height figure on the SeedData sheet still holds,
	-- and the boot report prints the same table. Only the plinth is gone.
	--==========================================================================
	local stemH = H * 0.417
	local stemBase = 0
	upright("Stem", stemH, stemW, cf * CFrame.new(0, stemBase + stemH * 0.5, 0),
		SeedData.Stem, model)

	--==========================================================================
	-- A LEAF AND A LEAFLET, NOT TWO PROPELLERS
	--
	-- Two blades, one per side, at the same height and the same angle: from
	-- above it was a rotor. A second smaller leaflet higher up the stem and
	-- turned the OTHER way breaks that -- there is no viewpoint left where the
	-- four line up.
	--
	-- Both are still named "Leaf". PlantSway swings every part with that name
	-- as an arm while a plant walks, and works out which side each is on from
	-- its own offset, so a leaflet joins in for free.
	--==========================================================================
	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "Leaf",
			-- X and Z are the leaf's length and width and take G; Y is its
			-- thickness and does not.
			size = Vector3.new(H * 0.27 * G, H * 0.05, H * 0.12 * G),
			cframe = cf
				-- 0.51 of a stem that is now 23% longer, which lands the leaves
				-- at the same height above the soil they have always been at --
				-- low, with the heap coming up around them.
				* CFrame.new(side * H * 0.16 * G, stemBase + stemH * 0.51, 0)
				-- Down and out. Level bars read as propellers, which is exactly
				-- what the first build looked like.
				* CFrame.Angles(0, side * math.rad(16), side * math.rad(-13)),
			color = sp.Leaf,
			parent = model,
		})
		part({
			name = "Leaf",
			size = Vector3.new(H * 0.16 * G, H * 0.045, H * 0.08 * G),
			cframe = cf
				* CFrame.new(side * H * 0.105 * G, stemBase + stemH * 0.74, 0)
				-- Swept back and lifted, against the big blade's forward droop.
				* CFrame.Angles(0, side * math.rad(-27), side * math.rad(-34)),
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
		--==================================================================
		-- BREAK THE BOX
		--
		-- One cube is a die with a face drawn on it. Two things fix that
		-- without stopping it being a cube, which is the whole silhouette:
		--
		--   THE BROW   a bar across the top of the face, standing a little
		--              proud. It gives the eyes something to sit under, and
		--              it is the single part that stops the front reading as
		--              a flat panel.
		--   THE NUBS   two small blocks on the upper corners. From the side
		--              -- which is where a walking plant usually is -- they
		--              are the difference between a box and a head.
		--==================================================================
		part({
			name = "Brow",
			size = Vector3.new(headW * 0.74, headW * 0.11, headW * 0.10),
			cframe = headCF * CFrame.new(0, headW * 0.24, -headW * 0.49),
			color = sp.Crown,
			parent = model,
		})
		for _, side in ipairs({ -1, 1 }) do
			part({
				name = "Nub",
				size = Vector3.new(headW * 0.16, headW * 0.18, headW * 0.16),
				cframe = headCF
					* CFrame.new(side * headW * 0.46, headW * 0.40, 0)
					* CFrame.Angles(0, 0, side * math.rad(14)),
				color = sp.Body,
				parent = model,
			})
		end
		--==================================================================
		-- A SPROUT, BECAUSE THE CUBE HAD NOTHING
		--
		-- Every other form carries something on its head -- a flower, spikes,
		-- a cap, buds -- and reads as a plant because of it. The cube was a
		-- green box with a face, and its Crown and Accent colours were the
		-- only two fields on the sheet that nothing anywhere used.
		--
		-- Two small leaves and a pale tip. Deliberately tiny: a Nubkin is the
		-- Common, it is often the smallest thing in the bed, and giving it a
		-- crown to rival a Bellchime's would be a lie about what it is worth.
		--==================================================================
		for _, side in ipairs({ -1, 1 }) do
			part({
				name = "Sprout",
				size = Vector3.new(headW * 0.30, headW * 0.09, headW * 0.17),
				cframe = topCF
					* CFrame.new(side * headW * 0.15, headW * 0.05, 0)
					* CFrame.Angles(0, side * math.rad(22), side * math.rad(-30)),
				color = sp.Crown,
				parent = model,
			})
		end
		ball("SproutTip", headW * 0.13, topCF * CFrame.new(0, headW * 0.10, 0),
			sp.Accent, model)

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
		-- A banded collar where the head meets the stem. Without it the
		-- teardrop is a balloon with sticks in the top and nothing explaining
		-- where it joins the plant.
		upright("Collar", headW * 0.13, headW * 0.62,
			headCF * CFrame.new(0, -headW * 0.42, 0), sp.Crown, model)
		addSpikes(model, sp, topCF * CFrame.new(0, headW * 0.38, 0), headW, H)

	elseif sp.Form == "mushroom" then
		ball("Head", headW * 0.86, headCF, sp.Body, model)
		faceW = headW * 0.86
		front = headW * 0.42
		local capY = headW * 0.42
		--==================================================================
		-- GILLS
		--
		-- The underside of the cap was a flat disc in the same red as the top,
		-- so from anywhere below eye level -- which is most of the time, since
		-- these are on the ground -- a Toadcap was a red plate on a stalk. Six
		-- pale radial blocks set just under the rim give it an inside.
		--
		-- Under the disc rather than inside it, and pale rather than red, so
		-- the two faces of the cap read as two different things.
		--==================================================================
		for i = 1, 4 do
			part({
				name = "Gill",
				-- A bar through the centre covers BOTH sides, so four of them at
				-- 45 degree steps give eight spokes. Long enough to reach 0.52
				-- of the way out against the cap's own 0.66 radius -- they stop
				-- just inside the rim rather than poking past it.
				size = Vector3.new(headW * 0.08, headW * 0.10, headW * 1.05),
				cframe = headCF
					* CFrame.new(0, capY - headW * 0.10, 0)
					* CFrame.Angles(0, (i - 1) / 4 * math.pi, 0),
				color = sp.Accent,
				parent = model,
				studs = false,
			})
		end
		upright("CapDisc", headW * 0.16, headW * 1.32,
			headCF * CFrame.new(0, capY, 0), sp.Crown, model)
		ball("CapDome", headW * 1.10, headCF * CFrame.new(0, capY + headW * 0.10, 0),
			sp.Crown, model)
		-- Spots, set into the dome's upper face.
		for i = 1, 4 do
			local a = (i - 1) / 4 * math.pi * 2
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
		-- A fifth step at the hem, wider and shallower than the rest: the
		-- skirt now finishes on a RIDGE rather than just stopping, which is
		-- what the sheet's flared lip does.
		local tiers = {
			{ 0.50, 0.40 }, { 0.74, 0.16 }, { 1.00, -0.08 },
			{ 1.20, -0.30 }, { 1.32, -0.44 },
		}
		for _, t in ipairs(tiers) do
			local d: number, dy: number = t[1], t[2]
			upright("BellTier", headW * 0.28, headW * d,
				headCF * CFrame.new(0, dy * headW, 0), sp.Body, model)
		end
		--==================================================================
		-- A SCALLOPED COLLAR, NOT A NAPKIN RING
		--
		-- This was one plain cylinder in the Accent green. The sheet has a ring
		-- of overlapping PINK petals where the skirt meets the stem -- the
		-- single most recognisable thing about a Bellchime after its shape --
		-- and a smooth ring threw all of it away.
		--
		-- Five blocks round the rim, alternating slightly in size so the
		-- outline scallops instead of stepping evenly. Crown, not Accent: on
		-- the sheet the collar and the bud tips are the same pink and the
		-- stalks between them are the green.
		--==================================================================
		for i = 1, 5 do
			local big = (i % 2 == 0)
			local petal = headW * (if big then 0.34 else 0.28)
			part({
				name = "CollarPetal",
				size = Vector3.new(petal, headW * 0.13, petal * 0.72),
				cframe = headCF
					* CFrame.new(0, headW * 0.54, 0)
					* CFrame.Angles(0, (i - 1) / 5 * math.pi * 2, 0)
					* CFrame.new(0, 0, -headW * 0.29)
					* CFrame.Angles(math.rad(-14), 0, 0),
				color = sp.Crown,
				parent = model,
				studs = false,
			})
		end
		addBuds(model, sp, headCF * CFrame.new(0, headW * 0.60, 0), headW)
		-- The face rides the WIDE lower skirt, which is where the sheet puts it,
		-- so `front` is that tier's radius rather than the head's.
		faceCF = headCF * CFrame.new(0, -headW * 0.10, 0)
		faceW = headW * 1.00
		front = headW * 0.60
	end

	-- No +0.04 any more. That was the sticker being pushed a hair clear of the
	-- head so it did not z-fight; a ball centred on the surface needs no help.
	addFace(model, faceCF, faceW, front)

	-- PrimaryPart is the BASE plate: a creature's pivot is where it meets the
	-- soil, so planting one is placing its pivot on the dirt rather than working
	-- out how tall it is first. It is invisible, and deliberately so -- see the
	-- block where it is built.
	model.PrimaryPart = base
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
function CreatureModel.BuildPod(sp: SeedData.Species, kg: number, cf: CFrame,
	parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Pod_" .. sp.Id
	model:SetAttribute("SpeciesId", sp.Id)
	model:SetAttribute("Rarity", sp.Rarity)
	model:SetAttribute("Kg", kg)
	model:SetAttribute("Stage", CreatureModel.STAGE_POD)
	model.Parent = parent

	-- THE CFRAME IS THE BASE, not the centre -- same contract as BuildCreature,
	-- because two builders in one file meaning different things by the same
	-- argument is a trap for every caller.
	-- Size comes from weight, so the pod tells you what it will cost to carry
	-- before you commit to the hold. See SeedData.PodDiameter.
	local D = SeedData.PodDiameter(kg)
	--==========================================================================
	-- THE SHELL IS COLOURED BY WEIGHT, NOT BY SPECIES
	--
	-- This is the whole reason weight is rolled. A Nubkin shell glowing Divine
	-- is a 9,000 kg cube, and the only way to know is to look at the pod --
	-- which is what makes a nest worth walking into rather than pattern-matching
	-- on shape from the road.
	--==========================================================================
	local color = SeedData.ColorForKg(kg)
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

function CreatureModel.Build(sp: SeedData.Species, kg: number, stage: Stage,
	cf: CFrame, parent: Instance): Model
	if stage == CreatureModel.STAGE_POD then
		return CreatureModel.BuildPod(sp, kg, cf, parent)
	end
	return CreatureModel.BuildCreature(sp, kg, stage, cf, parent)
end

return CreatureModel
