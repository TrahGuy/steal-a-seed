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
-- A TAPERED PLATE, WHICH IS NOT THE SAME AS A WEDGE
--
-- `wedge` above takes a raw Vector3 and applies no rotation of its own. Every
-- Dustbowl plate -- root feet, sepals, husk plates, blades, lobes -- was
-- authored against a different convention: size (thick, length, width) PLUS a
-- 90-degree yaw, which is what makes the plate taper to a point across its
-- WIDTH. Sized the other way it tapers the THICKNESS and reads as a rectangle
-- from every angle, which is what the first Dunebud pass looked like.
--
-- The taper is a RIGHT triangle, so pairs must mirror or the whole set leans
-- one way.
--
-- A separate helper, not a change to `wedge`: five shipped Greenhollow forms
-- call that one and none of them should move today.
--==============================================================================
-- A disc lying in the XY plane, facing FORWARD along Z -- a coin seen face-on,
-- not `upright`'s pancake seen edge-on. Paddlehop's pad is a flat slab and its
-- rounded rims are these; without them the pad is a rectangle with corners.
local function coin(name: string, diameter: number, thick: number, cf: CFrame,
	color: Color3, parent: Instance): BasePart
	return part({
		name = name,
		size = Vector3.new(thick, diameter, diameter),
		cframe = cf * CFrame.Angles(0, math.rad(90), 0),
		color = color,
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
end

local function plate(name: string, width: number, length: number, thick: number,
	cf: CFrame, color: Color3, parent: Instance, mirror: boolean?): BasePart
	return wedge(name, Vector3.new(thick, length, width),
		cf * CFrame.Angles(0, math.rad(90), 0)
			* (if mirror then CFrame.Angles(0, math.pi, 0) else CFrame.new()),
		color, parent)
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
-- THE DUSTBOWL FOOTING
--
-- What every Dustbowl species stands on, and it is identical on all five --
-- same rule as the shared stem and leaf colour. It replaces the seven soil
-- clods with four broad root feet spreading from one crown, plus a neck ring
-- that hides the head-to-stem join.
--
--   greenhollow  Base 1 + Soil 7 + Stem 1 + Leaf 4                     = 13
--   dustbowl     Base 1 + RootCrown 1 + RootFoot 4 + Stem 1 + Leaf 2
--                + Neck 1 + Sepal 2                                    = 12
--
-- FEET ARE BROAD AND THIN: 0.38-0.50 of head width across, 0.09-0.11 thick.
-- The first cut of this used 0.18-0.22 thick and produced four beams and a
-- block -- a stool, not a root system.
--
-- TWO LEAVES, NOT FOUR, AND THEY MUST BE DIRECT CHILDREN. PlantSway swings
-- parts named "Leaf" as opposed arms and finds them with model:GetChildren() --
-- direct children only -- working out which side each is on from its own X
-- offset. One per side is exactly what that wants.
--
-- The tables are literal and deterministic. Two servers must build the same
-- creature, and a bug report saying "the third one looked wrong" has to mean
-- something.
--==============================================================================
local DUST_FEET = {
	-- yaw, length, width, splay, tipCurl, thick
	{ 24, 0.72, 0.50, 82, 12, 0.11 },   -- the long front one, tip turns up
	{ 108, 0.52, 0.44, 85, 4, 0.10 },
	{ 200, 0.60, 0.48, 83, 7, 0.105 },
	{ 296, 0.34, 0.38, 88, 2, 0.09 },   -- the short chipped one
}
local DUST_SEPALS = { { 52, 0.62, 0.34 }, { 214, 0.46, 0.28 } }
local DUST_LEAVES = {
	-- side, long, wide, up, yaw, roll
	{ -1, 0.34, 0.15, 0.52, 18, -14 },
	{ 1, 0.26, 0.12, 0.68, -24, -30 },
}

local function addDustbowlFooting(model: Model, sp: SeedData.Species, cf: CFrame,
	H: number, G: number, stemW: number, stemH: number)
	local W = H * 0.46 * G

	-- Visible, unlike Base. This is the woody knot the feet spread from, and it
	-- is what the eye reads as the plant meeting the ground.
	part({
		name = "RootCrown",
		size = Vector3.new(stemW * 1.50, stemW * 0.44, stemW * 1.50),
		cframe = cf * CFrame.new(0, stemW * 0.22, 0),
		color = sp.Soil,
		parent = model,
	})

	for i, t in ipairs(DUST_FEET) do
		local yaw, length, width = t[1], t[2], t[3]
		local splay, curl, thick = t[4], t[5], t[6]
		local footCF = cf
			* CFrame.Angles(0, math.rad(yaw), 0)
			-- starts INSIDE the crown, not beside it, so it reads as emerging
			* CFrame.new(0, stemW * 0.30, -stemW * 0.28)
			* CFrame.Angles(math.rad(-splay + curl), 0, 0)
		plate("RootFoot", W * width, W * length, W * thick,
			footCF * CFrame.new(0, W * length * 0.5, 0), sp.Soil, model, i % 2 == 0)
	end

	upright("Stem", stemH, stemW, cf * CFrame.new(0, stemH * 0.5, 0), sp.Stem, model)

	for _, lf in ipairs(DUST_LEAVES) do
		local side, long, wide, up, yaw, roll = lf[1], lf[2], lf[3], lf[4], lf[5], lf[6]
		part({
			name = "Leaf",
			-- X and Z take G; Y is thickness and does not.
			size = Vector3.new(H * long * G, H * 0.055, H * wide * G),
			cframe = cf * CFrame.new(side * H * long * 0.52 * G, stemH * up, 0)
				* CFrame.Angles(0, side * math.rad(yaw), side * math.rad(roll)),
			color = sp.Leaf,
			parent = model,
		})
	end

	--==========================================================================
	-- THE NECK EARNS ITS PLACE TWICE
	--
	-- It hides the join where a head meets a cylinder, which every one of these
	-- species previously left as a hard edge. And in GREYSCALE it is the value
	-- break -- dark olive against a bright head and a mid-tan stem -- that keeps
	-- the two separate when colour is taken away. Raincup's cup blue and the
	-- stem tan land 17 luma apart and meet at exactly this point.
	--==========================================================================
	upright("Neck", W * 0.16, stemW * 2.40, cf * CFrame.new(0, stemH + W * 0.02, 0),
		sp.Leaf, model)
	for i, sd in ipairs(DUST_SEPALS) do
		local yaw, long, wide = sd[1], sd[2], sd[3]
		plate("Sepal", stemW * wide * 2.2, stemW * long * 2.2, stemW * 0.26,
			cf * CFrame.Angles(0, math.rad(yaw), 0)
				* CFrame.new(0, stemH + W * 0.04, -stemW * 0.82)
				* CFrame.Angles(math.rad(-26), 0, 0)
				* CFrame.new(0, stemW * long * 1.1, 0),
			sp.Leaf, model, i % 2 == 0)
	end
end

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

	local stemH = H * 0.417
	local stemBase = 0

	--==========================================================================
	-- THE BODY IS PER-BIOME FROM HERE DOWN
	--
	-- Greenhollow's five stand in a heap of seven soil clods. Dustbowl's five
	-- stand on four broad root feet with nothing shovelled around them -- the
	-- crown, not a plinth, owns the ground silhouette. That is not a style
	-- preference: a ring of clods says "this was planted" where the plant should
	-- say "this grew", and it was the single biggest thing making the two biomes
	-- look like different games.
	--
	-- `Base` is built ABOVE this branch and stays shared. It is the pivot four
	-- systems depend on -- PlantService places by it, PlantSway leans about it,
	-- CarryService welds it low in the hands, both prompts hang off it -- and a
	-- per-biome pivot would be a per-biome bug.
	--==========================================================================
	if sp.Form == "crown" then
		--==================================================================
		-- SUNCROWN BUILDS ITS OWN GROUND, AND THAT IS DELIBERATE
		--
		-- It is the one species that already had real anatomy down here before
		-- the shared footing existed: a central taproot, two rear heels and
		-- THREE COLOURED ROOTS in coral, orange and gold. Handing it four
		-- identical tan feet would delete the thing that makes it the
		-- Legendary, so its form branch does the whole job -- roots, stem,
		-- neck and leaves -- and nothing is built here.
		--
		-- Everything else in the biome shares the footing, which is the point
		-- of the footing. One exception, stated out loud, is not a crack in
		-- the rule.
		--==================================================================
	elseif sp.Biome == "dustbowl" then
		addDustbowlFooting(model, sp, cf, H, G, stemW, stemH)
	else
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

	--==========================================================================
	-- DUSTBOWL FORMS
	--
	-- Ported from the approved Studio previews. Every one of them was authored
	-- against `W = H * 0.46 * G` with a head centre at `stemH + W * 0.46` --
	-- which are headW and headCentreY here, the same two numbers -- so the
	-- shapes transfer without re-proportioning.
	--
	-- Each branch sets faceCF / faceW / front and stops. addFace below builds
	-- the same nine parts for all ten species: the previews copied its
	-- arithmetic verbatim, so there is nothing per-form left to do.
	--==========================================================================
	elseif sp.Form == "husk" then
		--==================================================================
		-- DUNEBUD: a sealed bud with ONE plate peeled down at the front
		--
		-- The brief ruled out "a plain ball or an egg", and a cream sphere in
		-- a rust collar IS an egg in a cape -- so the husk closes OVER the top
		-- and the face is recessed inside it. The plant is not wearing the
		-- husk, it is looking out of it.
		--
		-- The whole head is canted: six degrees into the wind and five of
		-- roll. That tilt is why it reads as weathered rather than placed.
		--==================================================================
		local hCF = headCF * CFrame.Angles(math.rad(-6), 0, math.rad(5))
		local function plateCF(yawDeg: number, out: number, baseYOff: number,
			length: number, tiltDeg: number): CFrame
			return hCF
				* CFrame.Angles(0, math.rad(yawDeg), 0)
				-- yaw 0 is the FRONT (-Z)
				* CFrame.new(0, baseYOff, -out)
				-- tip the top OUTWARD
				* CFrame.Angles(math.rad(-tiltDeg), 0, 0)
				-- a wedge's origin is its middle, not its root
				* CFrame.new(0, length * 0.5, 0)
		end

		upright("Collar", headW * 0.16, headW * 0.82,
			hCF * CFrame.new(0, -headW * 0.46, 0), sp.Crown, model)
		local budD = headW * 0.62
		ball("Bud", budD, hCF * CFrame.new(0, -headW * 0.02, 0), sp.Body, model)

		-- The low pair either side of the face SET THE WINDOW; the upper pair
		-- turn IN and meet at the knot over the bud. At 132 degrees with
		-- outward tilt they rose off the back of the head like two horns and
		-- did nothing for the bud. At 112, tilted 20 inward, their tips land
		-- just over the bud's crown -- a husk closing, not a pair of ears.
		for _, side in ipairs({ 1, -1 }) do
			plate("HuskLow", headW * 0.52, headW * 0.76, headW * 0.15,
				plateCF(side * 78, headW * 0.31, -headW * 0.50, headW * 0.76, 8),
				sp.Crown, model, side > 0)
			plate("HuskUp", headW * 0.50, headW * 0.62, headW * 0.15,
				plateCF(side * 112, headW * 0.37, -headW * 0.28, headW * 0.62, -20),
				sp.Crown, model, side > 0)
		end
		plate("HuskBack", headW * 0.56, headW * 0.72, headW * 0.15,
			plateCF(180, headW * 0.26, -headW * 0.48, headW * 0.72, 6),
			sp.Crown, model, false)

		-- A BLOCK, not a wedge. A wedge's taper is a RIGHT triangle: fine on a
		-- mirrored pair, wrong on a single plate dead centre, where it read as
		-- a sash tied across the mouth.
		part({
			name = "Peel",
			size = Vector3.new(headW * 0.50, headW * 0.36, headW * 0.12),
			cframe = plateCF(0, headW * 0.24, -headW * 0.54, headW * 0.36, 26),
			color = sp.Crown,
			parent = model,
		})
		ball("Knot", headW * 0.22, hCF * CFrame.new(0, headW * 0.22, 0),
			sp.Accent, model)

		faceW = headW * 0.54
		front = budD * 0.5
		faceCF = hCF
		-- The single part that stops the front reading as a flat panel: it
		-- gives the eyes something to sit under.
		part({
			name = "Brow",
			size = Vector3.new(headW * 0.42, headW * 0.10, headW * 0.12),
			cframe = hCF * CFrame.new(0, faceW * 0.30, -front * 0.74)
				* CFrame.Angles(math.rad(-16), 0, 0),
			color = sp.Crown,
			parent = model,
		})

	elseif sp.Form == "pad" then
		--==================================================================
		-- PADDLEHOP: a flat prickly-pear pad, three buds, one bloom
		--
		-- ONE RULE makes the beige legible rather than stripey: every rounded
		-- RIM is the dark olive, on the main pad and all three buds alike. The
		-- eye reads "edge" once and then reads it everywhere. Before that,
		-- core, edges and buds were one colour and three overlapping pads read
		-- as one lumpy mass -- cardboard, not a plant.
		--
		-- The bloom is the most saturated thing in the biome and it is one
		-- part the size of a thumbnail. Deliberate: a desaturated flower would
		-- read as background scenery.
		--==================================================================
		local padW, padH, padD = headW * 0.84, headW * 0.98, headW * 0.38
		part({
			name = "PadCore",
			size = Vector3.new(padW * 0.94, padH, padD),
			cframe = headCF, color = sp.Body, parent = model,
		})
		coin("PadEdge", padW, padD * 0.34, headCF * CFrame.new(0, padH * 0.5, 0),
			sp.Crown, model)
		coin("PadEdge", padW, padD * 0.28, headCF * CFrame.new(0, -padH * 0.5, 0),
			sp.Crown, model)

		-- Three buds, no two alike in size, lean, height or depth.
		local PADS = {
			-- sign, out, up, roll, blockH, wide, deep, z, yaw
			{ -1, 0.42, 0.18, 17, 0.68, 0.60, 0.26, 0.42, 0 },
			{ 1, 0.56, -0.16, 44, 0.16, 0.48, 0.22, 0.86, 62 },
			{ -1, 0.38, -0.44, 58, 0.14, 0.40, 0.14, -0.74, 38 },
		}
		local firstTip = headCF
		for i, d in ipairs(PADS) do
			local sign, out, up, roll = d[1], d[2], d[3], d[4]
			local blockH, wide, deep, z, yaw = d[5], d[6], d[7], d[8], d[9]
			local rootCF = headCF
				* CFrame.new(sign * headW * out, headW * up, padD * z)
				* CFrame.Angles(0, math.rad(sign * yaw), 0)
				* CFrame.Angles(0, 0, math.rad(-sign * roll))
			part({
				name = "PadBud",
				size = Vector3.new(headW * wide * 0.94, headW * blockH, headW * deep),
				cframe = rootCF * CFrame.new(0, headW * blockH * 0.5, 0),
				color = sp.Body:Lerp(sp.Crown, 0.32), parent = model,
			})
			local tipCF = rootCF * CFrame.new(0, headW * blockH, 0)
			coin("PadEdge", headW * wide, headW * deep * 0.55, tipCF, sp.Crown, model)
			if i == 1 then
				firstTip = tipCF * CFrame.new(0, headW * wide * 0.5, 0)
			end
		end

		local pale = sp.Accent:Lerp(WHITE, 0.62)
		coin("Bract", headW * 0.30, headW * 0.07,
			firstTip * CFrame.new(0, headW * 0.10, 0), pale, model)
		ball("Bloom", headW * 0.24, firstTip * CFrame.new(0, headW * 0.14, 0),
			sp.Accent, model)
		ball("Glow", headW * 0.09,
			firstTip * CFrame.new(-headW * 0.09, headW * 0.02, -headW * 0.06),
			pale, model)

		-- Four surface marks on the pad face. Smooth, because they are
		-- markings ON the pad rather than lumps of it.
		local frontZ = -padD * 0.5
		local DETAIL = {
			{ "Rib", 0.05, 0.46, 0.160, -0.26, 0.20, 9 },
			{ "Areole", 0.11, 0.08, 0.130, 0.22, 0.14, 0 },
			{ "Areole", 0.08, 0.06, 0.100, -0.30, -0.10, 0 },
			{ "Scar", 0.22, 0.05, 0.070, 0.30, 0.40, -21 },
		}
		for _, d in ipairs(DETAIL) do
			part({
				name = d[1] :: string,
				size = Vector3.new(headW * (d[2] :: number), headW * (d[3] :: number),
					headW * (d[4] :: number)),
				cframe = headCF
					* CFrame.new(padW * (d[5] :: number), padH * (d[6] :: number), frontZ)
					* CFrame.Angles(0, 0, math.rad(d[7] :: number)),
				color = sp.Crown, parent = model, studs = false,
			})
		end

		faceW = headW * 0.70
		front = padD * 0.5

	elseif sp.Form == "whorl" then
		--==================================================================
		-- THORNWHORL: five weathered blades spiralling off a bone core
		--
		-- The 26 degrees of shared twist about each blade's own length is what
		-- makes the ring a SPIRAL rather than a gear. Without it, five plates
		-- at even angles is a hub with spokes.
		--
		-- Two of the five are pulled darker and flatter so the whorl has depth
		-- instead of five identical boards, and `up` spans -0.14 to +0.26 so
		-- the SIDE view gets separated layers rather than one dense stack of
		-- boards at eye level.
		--==================================================================
		upright("Collar", headW * 0.15, headW * 0.94,
			headCF * CFrame.new(0, -headW * 0.30, 0), sp.Crown, model)
		local coreD = headW * 0.74
		ball("CoreBody", coreD, headCF, sp.Body, model)

		local BLADES = {
			-- yaw, out, up, back, splay, length, width, hook, dark
			{ 85, 0.40, -0.14, 0.02, 88, 0.62, 0.80, 34, false },
			{ 130, 0.38, 0.16, 0.02, 78, 0.56, 0.78, 30, true },
			{ 180, 0.36, -0.04, 0.02, 92, 0.66, 0.90, 38, false },
			{ 230, 0.42, 0.26, 0.02, 46, 0.98, 0.96, 26, false },
			{ 275, 0.42, 0.06, 0.02, 84, 0.52, 0.74, 36, true },
		}
		local bladeDark = sp.Crown:Lerp(Color3.new(0, 0, 0), 0.16)
		for i, b in ipairs(BLADES) do
			local yaw, out, up, back = b[1] :: number, b[2] :: number,
				b[3] :: number, b[4] :: number
			local splay, length = b[5] :: number, b[6] :: number
			local width, hook = b[7] :: number, b[8] :: number
			local rootCF = headCF
				* CFrame.Angles(0, math.rad(yaw), 0)
				* CFrame.new(0, headW * up, headW * back - headW * out)
				-- lean out from vertical
				* CFrame.Angles(math.rad(-splay), 0, 0)
				-- THE SPIRAL
				* CFrame.Angles(0, 0, math.rad(26))
			-- Hoisted rather than inlined as an expression-if: two of the five
			-- blades are the darker tone, and the choice reads better named.
			local plateColour = if b[9] then bladeDark else sp.Crown
			plate("Plate", headW * width, headW * length, headW * 0.15,
				rootCF * CFrame.new(0, headW * length * 0.5, 0),
				plateColour, model, i % 2 == 0)
			-- Pale ochre, barely above the plate it grows out of, which is what
			-- makes it read as GROWN rather than as a cap screwed on the end.
			plate("Hook", headW * width * 0.34, headW * length * 0.22, headW * 0.15,
				rootCF * CFrame.new(0, headW * length * 0.94, 0)
					* CFrame.Angles(math.rad(hook), 0, 0),
				sp.Accent, model, i % 2 == 0)
		end

		local crownCF = headCF * CFrame.new(0, headW * 0.34, headW * 0.04)
			* CFrame.Angles(math.rad(-16), math.rad(20), 0)
		plate("Spur", headW * 0.34, headW * 0.62, headW * 0.13,
			crownCF * CFrame.new(0, headW * 0.31, 0), sp.Crown, model, false)
		plate("SpurTip", headW * 0.22, headW * 0.22, headW * 0.13,
			crownCF * CFrame.new(0, headW * 0.58, 0) * CFrame.Angles(math.rad(52), 0, 0),
			sp.Accent, model, false)

		faceW = headW * 0.66
		front = coreD * 0.5

	elseif sp.Form == "cup" then
		--==================================================================
		-- RAINCUP: a stepped goblet, and the steps are the whole point
		--
		-- A Roblox Cylinder seen side-on is a plain RECTANGLE. One wide disc
		-- read as a cup only from directly overhead; from the front -- the
		-- angle a player actually has -- it was a blue box with two horns.
		-- Three discs widening upward, 0.52 -> 0.92 -> 1.26, carry the
		-- silhouette because the STEPS do; each disc alone is a rectangle.
		--
		-- The yellow floor is FLUSH with the rim and never sunk below it. The
		-- engine has no hollow cylinder, so a floor "recessed" inside a solid
		-- rim is simply buried, and the focal colour of the whole model
		-- disappears from every angle including from above.
		--==================================================================
		upright("CupFoot", headW * 0.20, headW * 0.52,
			headCF * CFrame.new(0, -headW * 0.34, 0),
			sp.Body:Lerp(Color3.new(0, 0, 0), 0.28), model)
		upright("CupWall", headW * 0.26, headW * 0.92,
			headCF * CFrame.new(0, -headW * 0.13, 0), sp.Body, model)
		upright("CupRim", headW * 0.34, headW * 1.26,
			headCF * CFrame.new(0, headW * 0.09, 0), sp.Body, model)
		upright("CupInner", headW * 0.12, headW * 0.72,
			headCF * CFrame.new(0, headW * 0.22, 0), sp.Crown, model)
		ball("CupCore", headW * 0.24, headCF * CFrame.new(0, headW * 0.30, 0),
			sp.Crown, model)

		-- Five lobes, ONE plate each. The first design spent fifteen parts on
		-- five petals x (outer + liner + rim bar) -- three concentric rings of
		-- five, which is a gear. They root at 0.52-0.56, inside the rim's 0.63
		-- edge, so they rise FROM the rim and continue its flare.
		local LOBES = {
			-- yaw, out, splay, length, width
			{ 50, 0.54, 20, 0.80, 0.80 },   -- the long one, and the most upright
			{ 116, 0.52, 16, 0.74, 0.74 },
			{ 192, 0.54, 24, 0.74, 0.76 },
			{ 264, 0.52, 18, 0.76, 0.72 },
			{ 322, 0.56, 44, 0.42, 0.68 },  -- lower, partly folded, widest reach
		}
		local ribColour = sp.Body:Lerp(Color3.new(0, 0, 0), 0.34)
		for i, d in ipairs(LOBES) do
			local yaw, out = d[1] :: number, d[2] :: number
			local splay, length, width = d[3] :: number, d[4] :: number, d[5] :: number
			local L = headW * length * (0.92 + 0.10 * G)
			local rootCF = headCF
				* CFrame.Angles(0, math.rad(yaw), 0)
				* CFrame.new(0, headW * 0.20, -headW * out)
				* CFrame.Angles(math.rad(-splay), 0, 0)
			plate("Lobe", headW * width, L, headW * 0.20,
				rootCF * CFrame.new(0, L * 0.5, 0), sp.Body, model, i % 2 == 0)
			-- The rib PASSES THROUGH: 0.28 against the lobe's 0.20, so it stands
			-- proud on BOTH faces and details the inner ones too. On the outer
			-- face only it detailed the half of the crown facing away.
			--
			-- Darker than the lobe, never brighter. A bright vein out-values the
			-- core and steals the focal point the hierarchy is built around.
			part({
				name = "LobeRib",
				size = Vector3.new(headW * width * 0.16, L * 0.72, headW * 0.28),
				cframe = rootCF * CFrame.new(0, L * 0.40, 0),
				color = ribColour, parent = model,
			})
			-- The throat of TWO lobes only. A wedge, not a block: as a rectangle
			-- its corners hung past the tapering edges of the lobe it was meant
			-- to be colouring, and it read as a pink card standing in the cup.
			if i == 1 or i == 3 then
				plate("LobeBlush", headW * width * 0.70, L * 0.34, headW * 0.06,
					rootCF * CFrame.new(0, L * 0.19, headW * 0.085),
					sp.Accent, model, i % 2 == 0)
			end
		end

		-- The caught drop. OPAQUE -- Roblox sorts transparency per part and the
		-- bead is not allowed to be a second transparent layer -- and floored in
		-- size so it is still visible at 1 kg, where the whole plant is about
		-- two and a half studs tall.
		local beadD = math.max(headW * 0.24 * (0.86 + 0.14 * G), 0.34)
		local beadCF = headCF
			* CFrame.new(-headW * 0.26, headW * 0.17 + beadD * 0.5, headW * 0.04)
		ball("Bead", beadD, beadCF, Color3.fromRGB(74, 172, 246), model, false)
		ball("BeadGlint", beadD * 0.36,
			beadCF * CFrame.new(-beadD * 0.26, beadD * 0.30, -beadD * 0.24),
			Color3.fromRGB(206, 236, 248), model, false)

		faceW = headW * 0.60
		-- On the RIM, the widest step. On the wall below it the rim ledge
		-- overhung the face and dropped it into a shadow unreadable at distance.
		front = headW * 1.26 * 0.5
		faceCF = headCF * CFrame.new(0, headW * 0.09, 0)

	elseif sp.Form == "crown" then
		--==================================================================
		-- SUNCROWN: a nine-ray sun on a face disc
		--
		-- The only head in either biome that is RADIAL on purpose, so the usual
		-- warning against a ring of identical parts does not apply -- but the
		-- rays still earn it: three lengths, three widths, three colours, and
		-- only three of the nine carry a crimson accent.
		--
		-- IT ALSO BUILDS ITS OWN FOOTING, and that is why this branch is longer
		-- than the other four. Suncrown is the one species that already had real
		-- anatomy at the ground -- a central taproot, two rear heels and THREE
		-- COLOURED ROOTS -- before the shared footing existed. Handing it four
		-- identical tan feet would delete the thing that makes it the Legendary,
		-- so `addDustbowlFooting` is skipped for this form and the roots below
		-- stand in for it.
		--
		-- IT WAS AUTHORED ON ITS OWN SIZE CURVE, (kg/110)^0.18, where
		-- heightScale is 1.0 at 110 kg. headW on the sheet's shared curve is
		-- 4.2306 studs at that same weight, so ONE factor carries the approved
		-- proportions onto the shared frame and nothing else here has to know
		-- the preview used different maths. Conforming it is what keeps "a
		-- Dunebud stays shorter than a Suncrown at every weight" true: two
		-- curves crossing would break that at one end or the other.
		--==================================================================
		local hs = (headW / 4.2306) * 0.95
		local gs = math.clamp(G, 0.68, 2.60)
		local ws = hs * (1.14 + 0.16 * gs)
		local ds = hs * (0.85 + 0.15 * gs)
		local sunStemH = 2.30 * hs
		local sunStemD = 1.02 * ds
		local faceD = 2.90 * hs * (0.88 + 0.12 * gs)
		local faceThick = 0.72 * ds

		-- A plate lying flat on the GROUND, splayed along a compass bearing.
		-- fromMatrix, not lookAt: this states RightVector / UpVector directly,
		-- which is what a tangent frame needs.
		local function groundCF(pos: Vector3, radial: Vector3, roll: number): CFrame
			local tangent = Vector3.yAxis:Cross(radial).Unit
			return CFrame.fromMatrix(pos, Vector3.yAxis, radial.Unit, tangent)
				* CFrame.Angles(0, 0, math.rad(roll))
		end
		-- The same idea stood upright against the crown disc.
		local function crownCF(pos: Vector3, radial: Vector3): CFrame
			local tangent = Vector3.new(-radial.Y, radial.X, 0).Unit
			return CFrame.fromMatrix(pos, Vector3.zAxis, radial.Unit, tangent)
		end
		local origin = cf.Position

		--== THE TAPROOT AND FIVE SPREADING ROOTS ==--
		local tapH = 0.82 * hs
		wedge("CentralTaproot",
			Vector3.new(0.95 * ws, tapH, 1.00 * ds),
			cf * CFrame.new(0, tapH * 0.47, -0.03 * ds), sp.Soil, model)
		for _, d in ipairs({
			-- name, bearing, length, width, colour, roll
			{ "RearHeelL", 38, 2.18, 0.86, sp.Soil, 3 },
			{ "RearHeelR", 322, 2.18, 0.86, sp.Soil, -3 },
			{ "FrontCoral", 144, 1.86, 0.72, sp.Accent, 4 },
			{ "FrontOrange", 180, 2.12, 0.75, sp.Crown, 0 },
			{ "FrontGold", 216, 1.86, 0.72, sp.Body, -4 },
		}) do
			local angle = math.rad(d[2] :: number)
			local radial = Vector3.new(math.sin(angle), 0, math.cos(angle))
			local len = (d[3] :: number) * ws
			local wid = (d[4] :: number) * ds
			local rootH = 0.40 * hs
			local pos = origin + radial * (len * 0.43) + Vector3.new(0, rootH * 0.47, 0)
			wedge(d[1] :: string, Vector3.new(rootH, len, wid),
				groundCF(pos, radial, d[6] :: number), d[5] :: Color3, model)
		end

		--== STEM AND NECK ==--
		upright("Stem", sunStemH, sunStemD,
			cf * CFrame.new(0, sunStemH * 0.50, 0.05 * ds), sp.Stem, model)
		upright("Neck", sunStemH * 0.12, sunStemD * 2.35,
			cf * CFrame.new(0, sunStemH * 0.90, 0.05 * ds), sp.Leaf, model)

		--==================================================================
		-- FOUR SUPPORT LEAVES, AND THEY ARE NAMED "Leaf" ON PURPOSE
		--
		-- The preview called them SupportLeaf1-4. PlantSway swings every part
		-- named "Leaf" as an arm while a plant walks and works out which side
		-- each is on from its own X offset -- and it finds them with
		-- GetChildren(), direct children only. Under the preview's name they
		-- would simply never move. Two point one way and two the other, so they
		-- swing in opposition exactly as Greenhollow's four do.
		--==================================================================
		local leafSocketY = sunStemH * 0.60
		for _, d in ipairs({
			{ 58, 1.82, 0.74, 10, 1 },
			{ 126, 1.94, 0.78, 13, -1 },
			{ 234, 1.90, 0.76, -12, 1 },
			{ 302, 1.78, 0.72, -9, -1 },
		}) do
			local angle = math.rad(d[1] :: number)
			local radial = Vector3.new(math.sin(angle), 0, math.cos(angle))
			local len = (d[2] :: number) * ws
			local wid = (d[3] :: number) * ds
			local thick = 0.23 * hs
			-- Two tiers, a third of a thickness apart, so overlapping leaves
			-- never share a plane -- two coincident faces sliding against each
			-- other is exactly what flickers.
			local tierY = thick * 0.30 * (d[5] :: number)
			local pos = origin
				+ Vector3.new(0, leafSocketY + tierY, 0)
				+ radial * (sunStemD * 0.34 + len * 0.40)
			wedge("Leaf", Vector3.new(thick, len, wid),
				groundCF(pos, radial, d[4] :: number), sp.Leaf, model)
		end

		--== THE FACE DISC: five rows, widening to the middle ==--
		local faceCentre = cf * CFrame.new(0, sunStemH + faceD * 0.48, 0)
		for i, r in ipairs({
			{ 0.58, 0.40 }, { 0.86, 0.20 }, { 1.00, 0.00 },
			{ 0.86, -0.20 }, { 0.58, -0.40 },
		}) do
			part({
				name = if i == 3 then "FaceCore" else "FaceRow",
				size = Vector3.new(faceD * (r[1] :: number), faceD * 0.203, faceThick),
				cframe = faceCentre * CFrame.new(0, faceD * (r[2] :: number), 0),
				color = sp.Body, parent = model,
			})
		end
		for _, side in ipairs({ -1, 1 }) do
			part({
				name = "FaceNotch",
				size = Vector3.new(faceD * 0.11, faceD * 0.30, faceThick * 0.62),
				cframe = faceCentre * CFrame.new(side * faceD * 0.44, 0, -faceThick * 0.32),
				color = sp.Crown, parent = model,
			})
		end
		local backThick = faceThick * 0.80
		for _, r in ipairs({ { 0.74, 0.203 }, { 0.90, 0.0 }, { 0.74, -0.203 } }) do
			part({
				name = "FaceBack",
				size = Vector3.new(faceD * (r[1] :: number), faceD * 0.203, backThick),
				cframe = faceCentre
					* CFrame.new(0, faceD * (r[2] :: number),
						faceThick * 0.20 + backThick * 0.50),
				color = sp.Crown, parent = model,
			})
		end

		--== NINE RAYS ==--
		-- Wings are longest and widest and sit outermost; the peak is the
		-- crimson one dead centre; the two inner pairs are short fillers that
		-- close the gaps without competing for the eye.
		local CRIMSON = Color3.fromRGB(142, 42, 48)
		local FILLER = sp.Body:Lerp(sp.Crown, 0.5)
		local wings: { CFrame } = {}
		for _, d in ipairs({
			-- bearing, length, width, colour, accent, principal
			{ -84, 3.70, 1.28, sp.Accent, false, true },
			{ -58, 3.20, 1.44, sp.Body, false, true },
			{ -34, 3.40, 1.27, sp.Crown, true, true },
			{ -18, 2.05, 0.86, FILLER, false, false },
			{ 0, 3.90, 1.43, CRIMSON, true, true },
			{ 18, 2.05, 0.86, FILLER, false, false },
			{ 34, 3.40, 1.27, sp.Crown, true, true },
			{ 58, 3.20, 1.44, sp.Body, false, true },
			{ 84, 3.70, 1.28, sp.Accent, false, true },
		}) do
			local bearing = d[1] :: number
			local principal = d[6] :: boolean
			local angle = math.rad(bearing)
			local radial = Vector3.new(math.sin(angle), math.cos(angle), 0)
			local len = (d[2] :: number) * (if principal then ws else hs)
			local wid = (d[3] :: number) * ds
			local thick = (if principal then 0.34 else 0.27) * ds
			-- Principals sit a layer proud, so the fillers read as BEHIND them
			-- rather than as part of one flat ring.
			local layer = if principal then 0.65 else 0.48
			local rootPos = (faceCentre * CFrame.new(0, faceD * 0.06, 0)).Position
				+ radial * (faceD * (if principal then 0.35 else 0.30))
				+ Vector3.new(0, 0, faceThick * layer)
			-- A bar plus a round cap, and the bar gives up exactly the cap's
			-- radius, so overall ray length is unchanged by the cap.
			local capR = wid * 0.5
			local plateCF = crownCF(rootPos + radial * (len * 0.44), radial)
			part({
				name = "Ray",
				size = Vector3.new(thick, len - capR, wid),
				cframe = plateCF * CFrame.new(0, -capR * 0.5, 0),
				color = d[4] :: Color3, parent = model,
			})
			part({
				name = "RayTip",
				size = Vector3.new(thick * 0.78, wid, wid),
				cframe = plateCF * CFrame.new(0, (len - capR) * 0.5 - capR * 0.5, 0),
				color = d[4] :: Color3, shape = Enum.PartType.Cylinder, parent = model,
			})
			if d[5] then
				local at = math.max(0.05, thick * 0.26)
				part({
					name = "RayAccent",
					size = Vector3.new(at, len * 0.56, wid * 0.24),
					cframe = plateCF * CFrame.new(
						-(thick + at) * 0.50 - math.max(0.04, 0.05 * ds),
						-len * 0.04, 0),
					color = CRIMSON, parent = model,
				})
			end
			if bearing == -84 or bearing == 84 then
				table.insert(wings, crownCF(rootPos + radial * (len * 0.70), radial))
			end
		end

		--==================================================================
		-- FOUR PENDANTS, TWO PER WING
		--
		-- RIGID IN GAME. They swung on four independent phases in the preview
		-- and that motion does not survive integration: PlantSway moves a whole
		-- plant with ONE PivotTo and swings the leaves, and nothing else. The
		-- geometry is kept because it is approved and it is most of what makes
		-- the wings read as loaded rather than bare.
		--==================================================================
		for _, w in ipairs(wings) do
			for _, drop in ipairs({ -0.10, 0.18 }) do
				local top = w * CFrame.new(0, drop * faceD, 0)
				local rodL = 0.62 * hs
				local rodD = math.max(0.06, 0.095 * ds)
				local beadD = 0.42 * hs * (0.92 + 0.08 * gs)
				upright("PendantRod", rodL, rodD,
					top * CFrame.new(0, -rodL * 0.5, 0), sp.Body, model)
				local beadCF = top * CFrame.new(0, -rodL - beadD * 0.10, 0)
				ball("SunCore", beadD, beadCF, sp.Body, model)
				local barL, barT = beadD * 1.45, math.max(0.06, beadD * 0.23)
				part({ name = "SunRay", size = Vector3.new(barL, barT, barT),
					cframe = beadCF, color = sp.Body, parent = model })
				part({ name = "SunRay", size = Vector3.new(barT, barL, barT),
					cframe = beadCF, color = sp.Body, parent = model })
			end
		end

		--== THE COLLAR: five cool blocks under the face ==--
		-- The only cool note on a creature that is otherwise entirely hot, and
		-- what stops the gold reading as one flat mass.
		local CYAN = Color3.fromRGB(36, 183, 207)
		local BLUE = Color3.fromRGB(30, 91, 180)
		for i, d in ipairs({
			{ -0.38, 18, CYAN }, { -0.19, 9, BLUE }, { 0.00, 0, CYAN },
			{ 0.19, -9, BLUE }, { 0.38, -18, CYAN },
		}) do
			local px = (d[1] :: number) * faceD
			-- Arched: the middle block rides highest, so the row reads as a
			-- collar rather than as a straight bar of five.
			local arch = (1 - math.abs(d[1] :: number) / 0.38) * faceD * 0.035
			part({
				name = "Collar" .. i,
				size = Vector3.new(faceD * 0.235, faceD * 0.19, faceThick * 0.40),
				cframe = faceCentre
					* CFrame.new(px, -faceD * 0.46 - arch, -faceThick * 0.56)
					* CFrame.Angles(0, 0, math.rad(d[2] :: number)),
				color = d[3] :: Color3, parent = model,
			})
		end

		faceW = faceD
		front = faceThick * 0.5
		faceCF = faceCentre

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
	--======================================================================
	-- WHAT SITS ON TOP IS THE BIOME'S, NOT THE SPECIES'
	--
	-- The shell is coloured by the WEIGHT BAND and sized by the weight, and
	-- neither of those changes per biome -- that is the whole readout and it has
	-- to mean the same thing on every road. What changes is the dry matter
	-- around it, because that is where a biome gets to look like itself.
	--
	-- The hatch stays unspoiled either way: no species id, no form rarity, no
	-- label. Greenhollow means five possible shapes and Dustbowl means five
	-- others, and a pod that named which would answer the only question an
	-- unhatched pod exists to ask.
	--======================================================================
	if sp.Biome == "dustbowl" then
		--==================================================================
		-- THE DUST HUSK
		--
		-- Greenhollow's pod curls four green tendrils off its crown: alive,
		-- growing. This one splits instead -- a cracked seam round the belly,
		-- four dry bracts wrapping the lower half, three snapped bristles on
		-- top. Same slot, opposite reading, and one part cheaper.
		--
		-- THE BRACTS ARE TANGENT, SHORT AND SUNK. An earlier pass flared them
		-- and produced horizontal planks: a tip standing 3.4 studs off a 4.6
		-- stud radius is not a flare, it is a propeller. A flat plate tangent to
		-- a sphere touches at ONE point and its corners stand off by
		-- (half-length)^2 / 2R -- geometry, not a tunable -- so shortening the
		-- plate shrinks the standoff with the SQUARE of half-length. At 0.50 D
		-- long and sunk to 0.91 R, the corners sit 13-21% of R proud across the
		-- whole band table.
		--==================================================================
		local R = D * 0.5
		upright("Split", D * 0.085, D * 1.02, baseCF,
			color:Lerp(Color3.new(0, 0, 0), 0.34), model)

		for _, b in ipairs({ { 45, false }, { -45, true }, { 135, false }, { -135, true } }) do
			local az = math.rad(b[1] :: number)
			-- Four plates of width 0.54 D at this latitude cover about 72% of the
			-- circumference: enough to read as a cup, short of a sealed collar
			-- that would hide the band colour the pod exists to show.
			local th = math.rad(-16)
			local ca, sa = math.cos(az), math.sin(az)
			local ct, st = math.cos(th), math.sin(th)
			local outward = Vector3.new(sa * ct, st, ca * ct)
			local meridian = Vector3.new(-sa * st, ct, -ca * st)
			-- fromMatrix, not lookAt: this needs a TANGENT frame on the sphere,
			-- and RightVector / UpVector is how you state one.
			local cfb = CFrame.fromMatrix(
				baseCF.Position + outward * (R * 0.91), outward, meridian)
			if b[2] then
				cfb = cfb * CFrame.Angles(0, math.rad(180), 0)
			end
			wedge("Bract", Vector3.new(D * 0.05, D * 0.50, D * 0.54), cfb,
				Color3.fromRGB(178, 158, 106), model)
		end

		-- Three snapped stubs where Greenhollow curls four living tendrils.
		-- Straight, uneven, leaning apart: dead and dry, the same silhouette
		-- slot doing the opposite job.
		local LEAN = { -22, 0, 22 }
		for i = 1, 3 do
			part({
				name = "Bristle",
				size = Vector3.new(D * 0.055, D * 0.34, D * 0.055),
				cframe = baseCF * CFrame.new(0, D * 0.66, 0)
					* CFrame.Angles(0, math.rad((i - 2) * 34), 0)
					* CFrame.Angles(math.rad(LEAN[i]), 0, 0),
				color = Color3.fromRGB(128, 122, 78),
				parent = model,
			})
		end
	else
		upright("Seam", D * 0.07, D * 1.02, baseCF * CFrame.new(0, D * 0.02, 0),
			color:Lerp(Color3.new(0, 0, 0), 0.18), model)
		local tip = baseCF * CFrame.new(0, D * 0.62, 0)
		for _ = 1, 4 do
			tip = tip * CFrame.new(0, D * 0.13, 0) * CFrame.Angles(0, 0, math.rad(38))
			part({
				name = "Tendril",
				size = Vector3.new(D * 0.10, D * 0.16, D * 0.10),
				cframe = tip,
				color = Color3.fromRGB(104, 158, 62),
				parent = model,
			})
		end
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
