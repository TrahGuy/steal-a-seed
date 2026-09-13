--==============================================================================
-- PYRELOTUS, THE OBSIDIAN FIRE-DRAKE LOTUS -- PREVIEW AND DATA GENERATOR
--
-- A Studio authoring tool, not game code. Loaded in Edit with
--
--     loadstring(HttpService:GetAsync("http://127.0.0.1:8731/tools/art/pyrelotus_drake.luau"))()
--
-- it returns { specs, build, effects, measure, serialize }.
--
-- `specs` IS EmberrootForms' PYRELOTUS table. `build` lays them out the way
-- that file's `mk` does, `effects` mirrors its aura, and `serialize` prints the
-- list in the PartSpec shape the module keeps.
--
-- AUTHORED AT SCALE 1, WHICH IS THE EMBERROOT CONTRACT AND NOT THE DUSTBOWL ONE.
-- EmberrootForms.Build takes what a species builder produced and grows the whole
-- thing afterwards -- CFrames, sizes, PointLight.Range, emitter Size, Speed and
-- Acceleration all get multiplied by hs on the way out. So every number written
-- here, the aura's included, is the TIER 1 number: write Range 16, not 16 * hs,
-- or a Colossal gets it twice.
--
-- Authored in the mockup's own studs: ground at Y = 0, front toward -Z.
--
-- WHAT A WEDGE IS, since the claws, petals, horns and spikes are all one:
-- measured by raycast rather than recalled, a WedgePart is FULL HEIGHT at its
-- local +Z and tapers to a knife edge at local -Z, flat along the bottom and
-- constant across X. So `CFrame.lookAt(mid, tip, widthAxis)` -- which puts local
-- -Z on the look direction -- gives a blade that comes to a point at `tip`,
-- tapering across the axis handed in as the up hint.
--==============================================================================

local rad = math.rad
local UP = Vector3.new(0, 1, 0)

--==============================================================================
-- THE PALETTE
--
-- Body, Crown and Accent are lifted straight out of SeedData.pyrelotus, so the
-- drake is painted in the colours the Almanac and the shop tile already show
-- for it. Violet-charcoal is the only cool dark in Emberroot and it is the
-- Mythic doing its job before you have read the word.
--==============================================================================
local OBSIDIAN = Color3.fromRGB(52, 32, 56) -- SeedData.Body, violet charcoal
local BASALT = Color3.fromRGB(38, 24, 42) -- the darker slate under the plates
local PLATE = Color3.fromRGB(88, 62, 98) -- a lit plate face, so armour reads
local MAGMA = Color3.fromRGB(255, 140, 96) -- SeedData.Crown, blazing peach
local MAGMA_DEEP = Color3.fromRGB(255, 90, 30) -- the hotter end of a fissure
local ROSE = Color3.fromRGB(255, 128, 148) -- SeedData.Accent, rose magma
local CORE = Color3.fromRGB(255, 160, 48) -- incandescent fire
local CLAW = Color3.fromRGB(168, 146, 128) -- the one warm pale in the model

local PLASTIC = Enum.Material.Plastic
local NEON = Enum.Material.Neon

type Spec = {
	name: string,
	shape: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	studs: boolean?,
}

local specs: { Spec } = {}

local function add(name: string, shape: string, size: Vector3, cf: CFrame, color: Color3,
	material: Enum.Material?): Spec
	local mat = material or PLASTIC
	local s: Spec = {
		name = name,
		shape = shape,
		size = size,
		cf = cf,
		color = color,
		material = mat,
		-- Neon takes its light from the material, not from a surface, and a
		-- studded neon face reads as a dirty one. Everything else keeps its
		-- studs: matte studded stone against smooth glowing magma IS the look.
		studs = if mat == NEON then false else nil,
	}
	table.insert(specs, s)
	return s
end

--==============================================================================
-- PLACEMENT HELPERS
--==============================================================================

-- A block spanning a to b, overrunning both ends so neither joint is a visible
-- butt seam. Local -Z runs along it.
local function beam(name: string, a: Vector3, b: Vector3, w: number, h: number, overrun: number,
	color: Color3, hint: Vector3?): Spec
	local dir = b - a
	local up = hint or UP
	if math.abs(dir.Unit:Dot(up)) > 0.98 then
		up = Vector3.new(0, 0, 1)
	end
	return add(name, "Block", Vector3.new(w, h, dir.Magnitude + overrun * 2),
		CFrame.lookAt((a + b) * 0.5, b, up), color)
end

-- A wedge that comes to a point at `tip`, tapering across `widthAxis`.
local function blade(name: string, from: Vector3, tip: Vector3, width: number, thick: number,
	color: Color3, widthAxis: Vector3, material: Enum.Material?): Spec
	local len = (tip - from).Magnitude
	return add(name, "Wedge", Vector3.new(thick, width, len),
		CFrame.lookAt((from + tip) * 0.5, tip, widthAxis), color, material)
end

local function lowestOf(s: Spec): number
	local h = s.size * 0.5
	local y = math.huge
	for sx = -1, 1, 2 do
		for sy = -1, 1, 2 do
			for sz = -1, 1, 2 do
				y = math.min(y, (s.cf * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position.Y)
			end
		end
	end
	return y
end

-- Sits a part on the plane: its lowest corner at exactly Y = 0.
local function plant(s: Spec)
	s.cf = s.cf + Vector3.new(0, -lowestOf(s), 0)
end

--==============================================================================
-- SUPPORTING MASS: FOUR PILLAR LEGS
--
-- Low and heavy, the way the concept stands: the belly is barely a stud clear
-- of the ground and the hips sit at a quarter of the total height, with
-- everything the silhouette has spent upward on the caldera instead.
--
-- Thigh into shin into footpad, each joint swallowed by the next rather than
-- butted against it. The names carry PlantSway's LEG_WORDS -- Thigh, Shin, Foot,
-- Toe -- and the walker clusters them BY PLAN POSITION, so four widely separated
-- groups become four legs and the diagonal trot falls out of it: front-left with
-- rear-right against front-right with rear-left.
--
-- THE CLAWS ARE CALLED Toe FOR THAT REASON AND NOT FOR ANATOMY. A part named
-- "Claw" carries no leg word, so the rig would leave it standing in the soil
-- while the leg it belongs to swung away over the top of it.
--==============================================================================
local LEGS = {
	-- tag, x, z, how far the whole leg yaws out, how far it leans
	{ "FrontLeft", -0.94, -1.06, 13, -4 },
	{ "FrontRight", 0.94, -1.06, -13, -4 },
	{ "RearLeft", -0.99, 1.32, 8, 7 },
	{ "RearRight", 0.99, 1.32, -8, 7 },
}

for _, leg in ipairs(LEGS) do
	local tag = leg[1] :: string
	local x = leg[2] :: number
	local z = leg[3] :: number
	local yaw = leg[4] :: number
	local lean = leg[5] :: number
	local side = if x < 0 then -1 else 1
	local front = z < 0

	add(tag .. "_Thigh", "Block", Vector3.new(0.72, 1.10, 0.86),
		CFrame.new(x, 1.52, z) * CFrame.Angles(rad(lean), rad(yaw), rad(-side * 5)), OBSIDIAN)

	add(tag .. "_Shin", "Block", Vector3.new(0.60, 0.94, 0.70),
		CFrame.new(x + side * 0.05, 0.76, z + (if front then -0.06 else 0.08))
			* CFrame.Angles(rad(-lean * 0.6), rad(yaw), 0), BASALT)

	local foot = add(tag .. "_Foot", "Block", Vector3.new(0.82, 0.34, 1.02),
		CFrame.new(x + side * 0.07, 0.17, z + (if front then -0.20 else 0.16))
			* CFrame.Angles(0, rad(yaw), 0), BASALT)
	plant(foot)

	-- Two talons off the front of each pad, KEPT BACK UNDER THE HIP. The leg rig
	-- swings a whole leg rigidly about one hip with no ankle in it, so anything
	-- reaching far forward of that hip scoops DOWN through the soil as the leg
	-- swings back -- and girth spreads horizontal offsets without lengthening the
	-- drop, so the scoop gets worse at every tier.
	for i = 1, 2 do
		local off = if i == 1 then -0.21 else 0.21
		local root = Vector3.new(x + side * 0.07 + off, 0.15,
			z + (if front then -0.58 else -0.22))
		local tip = root + Vector3.new(off * 0.5, -0.01, -0.40)
		local claw = blade(tag .. "_ToeClaw" .. i, root, tip, 0.26, 0.24, CLAW, UP)
		plant(claw)
	end
end

--==============================================================================
-- DOMINANT MASS: THE VAULTED BASALT CARAPACE
--
-- Long and low and arched: four courses running fore and aft rather than
-- stacked, because this one is a quadruped and its dominant axis is Z. The
-- shoulder course rises to carry the caldera, which is the whole reason the
-- spine arches at all.
--==============================================================================
add("TorsoLower", "Block", Vector3.new(1.72, 1.22, 1.36),
	CFrame.new(0, 1.88, 1.30) * CFrame.Angles(rad(6), 0, 0), OBSIDIAN)
add("TorsoMid", "Block", Vector3.new(1.86, 1.28, 1.90),
	CFrame.new(0, 2.06, 0.22), OBSIDIAN)
add("TorsoUpper", "Block", Vector3.new(1.74, 1.06, 1.62),
	CFrame.new(0, 2.44, -0.86) * CFrame.Angles(rad(-9), 0, 0), OBSIDIAN)
add("Belly", "Block", Vector3.new(1.50, 0.72, 2.10),
	CFrame.new(0, 1.36, 0.30), BASALT)

-- Angled shoulder plates. Rolled out and pitched down, which is what turns a
-- box into a carapace.
for _, side in ipairs({ -1, 1 }) do
	local tag = if side < 0 then "L" else "R"
	add("Mantle" .. tag, "Block", Vector3.new(0.54, 1.02, 1.66),
		CFrame.new(side * 0.96, 2.42, -0.42) * CFrame.Angles(rad(-6), 0, rad(side * 24)), PLATE)
end

--==============================================================================
-- THE MAGMA FISSURES
--
-- Thin neon strips laid in the gaps BETWEEN plates rather than painted on them:
-- each one sits a hair proud of the stone it splits, so the light reads as
-- coming out of the seam and not as a stripe stuck to the flank. Six, at six
-- different angles -- a fissure that repeats is a texture, and a texture is the
-- thing this technique exists to avoid.
--==============================================================================
-- EVERY ONE OF THESE STANDS PROUD OF THE STONE IT SPLITS. The first pass put
-- them at the torso's own half-width, which is exactly where the mantle plates
-- are, so all six were sealed inside the armour and the drake had no fissures at
-- all. A seam has to clear the widest thing at its own height or it is not a
-- seam, it is a filling.
local SEAMS = {
	-- x, y, z, length, thickness, yaw, roll, colour
	{ -0.99, 1.78, 0.24, 1.66, 0.12, -4, 18, MAGMA },
	{ 0.99, 1.72, 0.46, 1.44, 0.11, 5, -14, MAGMA_DEEP },
	{ -0.94, 1.86, 1.34, 0.92, 0.10, 16, 40, MAGMA_DEEP },
	{ 0.96, 1.80, 1.40, 0.84, 0.10, -14, -36, MAGMA },
	{ 0.00, 2.50, 1.30, 1.26, 0.13, 0, 90, MAGMA },
	{ -0.32, 2.86, -1.40, 1.00, 0.11, 20, 74, ROSE },
}
for i, s in ipairs(SEAMS) do
	add("MagmaSeam" .. i, "Block",
		Vector3.new(s[5] :: number, s[5] :: number, s[4] :: number),
		CFrame.new(s[1] :: number, s[2] :: number, s[3] :: number)
			* CFrame.Angles(0, rad(s[6] :: number), rad(s[7] :: number)),
		s[8] :: Color3, NEON)
end

--==============================================================================
-- THE SIGNATURE: THE DORSAL LOTUS CALDERA
--
-- A crater rim across the arched shoulders, eight obsidian petals fanning out
-- of it, four flame petals standing up inside those, and the core hung in the
-- middle of the bowl.
--
-- WIDE AT THE ROOT. Each obsidian petal is 0.78 across at the rim against the
-- 0.72 of arc it owns there, so the eight overlap into a closed collar and only
-- come apart as they taper. Petals that only touch at their tips read as a
-- crown of spikes, which is the failure this shape is one bad number away from.
--
-- The rim is TWO parts and not a ring of twelve: a ring of identical parts is
-- the thing the sculpting rules warn about, and two arcs meeting off-axis do
-- the same job with a seam that looks grown.
--==============================================================================
local RIM = Vector3.new(0, 3.30, 0.10)
local TILT = rad(-13) -- the bowl leans back, the way the concept opens it

for _, side in ipairs({ -1, 1 }) do
	local tag = if side < 0 then "L" else "R"
	add("CalderaRim" .. tag, "Block", Vector3.new(1.86, 0.34, 1.12),
		CFrame.new(RIM + Vector3.new(0, 0, side * 0.44))
			* CFrame.Angles(TILT, rad(side * 7), 0), BASALT)
end

-- Eight obsidian blades, fanning up and out. Bearings are uneven by a couple of
-- degrees each so the flower is grown rather than machined.
local OUTER = { 0, 46, 92, 137, 180, 224, 268, 314 }
for i, deg in ipairs(OUTER) do
	local a = rad(deg + (if i % 2 == 0 then 3 else -2))
	-- Out of the rim in plan, and up: a cone about 52 degrees off vertical.
	local flat = Vector3.new(math.sin(a), 0, math.cos(a))
	local root = RIM + flat * 0.54 + Vector3.new(0, 0.14, 0)
	-- SPLAYED, NOT STOOD UP. At a 45 degree fan the petal facing the camera
	-- stands square in front of the bowl and hides everything the flower is
	-- for. The concept opens these almost flat, like a sunflower disc, and the
	-- fire is what goes vertical.
	local rise = if i % 2 == 0 then 0.52 else 0.86
	local tip = RIM + flat * 2.24 + Vector3.new(0, rise, 0)
	-- Tilt the whole flower back with the rim.
	root = Vector3.new(root.X, root.Y, root.Z) + Vector3.new(0, -flat.Z * 0.10, 0)
	tip = Vector3.new(tip.X, tip.Y, tip.Z) + Vector3.new(0, -flat.Z * 0.34, 0)
	-- A SLAB, NOT A SPIKE. The obsidian petals in the concept are flat angular
	-- plates with cut ends; a wedge tapering to a point turns the flower into a
	-- crown of thorns, which is what the first two passes of this were. beam
	-- lays a block along the petal axis with its width across the ring and its
	-- thickness through the plane, which is a petal.
	beam("OuterPetal" .. i, root, tip, 1.06, 0.20, 0.04,
		if i % 3 == 0 then PLATE else OBSIDIAN)
end

-- Four flame petals standing INSIDE the obsidian ones, steeper and hotter.
local INNER = { 24, 112, 200, 292 }
for i, deg in ipairs(INNER) do
	local a = rad(deg)
	local flat = Vector3.new(math.sin(a), 0, math.cos(a))
	-- Stood off the axis far enough to leave the core its own space: at a 0.40
	-- root these four ran straight through a ball of radius 0.5 and the whole
	-- middle of the flower fused into one orange lump.
	local root = RIM + flat * 0.66 + Vector3.new(0, 0.24, 0)
	local tip = RIM + flat * 1.06 + Vector3.new(0, 2.94, -flat.Z * 0.34)
	local tangent = Vector3.new(math.cos(a), 0, -math.sin(a))
	local hand = if i % 2 == 0 then 1 else -1
	blade("InnerPetal" .. i, root, tip, 0.98, 0.20,
		if i % 2 == 0 then MAGMA else MAGMA_DEEP, tangent * hand)
end

--==============================================================================
-- THE MOLTEN SINGULARITY
--
-- The core sits DOWN IN the bowl rather than on top of it -- the rim and the
-- four flame petals stand above it, so the light climbs out of a crater. The
-- collar is the ring of heat on the bowl floor it is sitting in.
--==============================================================================
add("FlameCollar", "Cylinder", Vector3.new(0.22, 1.40, 1.40),
	CFrame.new(RIM + Vector3.new(0, 0.26, 0)) * CFrame.Angles(TILT, 0, rad(90)), MAGMA_DEEP, NEON)
add("MoltenCore", "Ball", Vector3.new(1.00, 1.00, 1.00),
	CFrame.new(RIM + Vector3.new(0, 0.74, -0.04)), CORE, NEON)

--==============================================================================
-- THE DRACONIC SKULL
--
-- Slung forward and LOW off the shoulder course, which is what makes a
-- quadruped read as a predator rather than as a horse. The maw is carved rather
-- than drawn: the snout above and the jaw below leave a real gap between them,
-- and the heat sits at the back of that gap so the light comes out of the
-- throat.
--==============================================================================
local HEAD = Vector3.new(0, 2.22, -2.02)

add("HeadBase", "Block", Vector3.new(1.24, 1.04, 1.26),
	CFrame.new(HEAD) * CFrame.Angles(rad(-6), 0, 0), OBSIDIAN)
add("BrowPlate", "Block", Vector3.new(1.28, 0.38, 0.84),
	CFrame.new(HEAD + Vector3.new(0, 0.50, -0.26)) * CFrame.Angles(rad(14), 0, 0), PLATE)
add("Snout", "Block", Vector3.new(0.92, 0.48, 0.96),
	CFrame.new(HEAD + Vector3.new(0, 0.06, -0.94)) * CFrame.Angles(rad(5), 0, 0), OBSIDIAN)
-- Parted, not shut: the jaw hangs a fifth of a stud below the snout and pitches
-- down away from it, so the gap opens toward the front.
add("JawLower", "Block", Vector3.new(0.72, 0.30, 0.86),
	CFrame.new(HEAD + Vector3.new(0, -0.40, -0.84)) * CFrame.Angles(rad(-13), 0, 0), BASALT)
-- The heat at the back of the throat, sunk between the two so it is never a
-- flat panel on the front of the face.
add("MawGlow", "Block", Vector3.new(0.60, 0.30, 0.66),
	CFrame.new(HEAD + Vector3.new(0, -0.17, -0.74)) * CFrame.Angles(rad(-4), 0, 0), MAGMA, NEON)

-- Swept horns, arching back over the neck.
for _, side in ipairs({ -1, 1 }) do
	local tag = if side < 0 then "Left" else "Right"
	local root = HEAD + Vector3.new(side * 0.44, 0.42, 0.20)
	local tip = root + Vector3.new(side * 0.62, 0.98, 1.62)
	blade(tag .. "Horn", root, tip, 0.56, 0.30, BASALT, UP)
end

-- Eye and Pupil, the two names PlantSway's gaze rig matches by suffix. The gaze
-- turns the eyeball and carries the pupil along, so the pupil is placed ON the
-- sphere rather than floating in front of the face.
local EYE = HEAD + Vector3.new(0, 0.20, -0.52)
add("Eye", "Ball", Vector3.new(0.34, 0.34, 0.34), CFrame.new(EYE), MAGMA, NEON)
add("Pupil", "Block", Vector3.new(0.09, 0.20, 0.09),
	CFrame.new(EYE + Vector3.new(0, 0, -0.13)), ROSE, NEON)

--==============================================================================
-- THE SEGMENTED TAIL
--
-- Three segments walked out of the hips with a cursor: each one starts exactly
-- where the last finished and turns a fixed amount, so the arc cannot come
-- apart however the numbers are tuned. Two dorsal spikes ride the bend and a
-- magma tuft finishes the tip.
--==============================================================================
-- KEPT SHORT ON PURPOSE. This creature is a quadruped and its long axis is Z,
-- so depth is the dimension that runs away with it: the tier curve takes a
-- Colossal to 8.7x and girth spreads horizontal offsets on top, which turned an
-- 8.66 stud mockup into 84 studs of drake -- nearly twice the longest thing the
-- game ships, and half again its own planting cell. The arc is tucked in rather
-- than the creature shrunk, so the silhouette keeps its sweep.
local TAIL_A = Vector3.new(0, 2.14, 1.82)
local TAIL_B = Vector3.new(0.06, 2.80, 2.44)
local TAIL_C = Vector3.new(0.14, 3.04, 2.98)
local TAIL_D = Vector3.new(0.22, 2.80, 3.42)
beam("Tail1", TAIL_A, TAIL_B, 0.76, 0.76, 0.16, OBSIDIAN)
beam("Tail2", TAIL_B, TAIL_C, 0.58, 0.58, 0.13, OBSIDIAN)
beam("Tail3", TAIL_C, TAIL_D, 0.42, 0.42, 0.10, BASALT)

blade("TailSpike1", TAIL_B + Vector3.new(0, 0.18, 0),
	TAIL_B + Vector3.new(-0.10, 0.82, 0.20), 0.30, 0.20, BASALT, UP)
blade("TailSpike2", TAIL_C + Vector3.new(0, 0.14, 0),
	TAIL_C + Vector3.new(0.12, 0.68, 0.24), 0.26, 0.18, BASALT, UP)
blade("TailFlame", TAIL_D + Vector3.new(0, 0.02, 0.08),
	TAIL_D + Vector3.new(0.06, 0.78, 0.46), 0.38, 0.22, MAGMA, UP, NEON)

--==============================================================================
-- PREVIEW, EFFECTS, MEASUREMENT, SERIALIZATION
--==============================================================================
local FACES = { "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface",
	"BackSurface" }

local function build(parent: Instance, base: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "PyrelotusDrake"
	model.Archivable = false
	for _, s in ipairs(specs) do
		local p: BasePart
		if s.shape == "Wedge" then
			p = Instance.new("WedgePart")
		else
			local block = Instance.new("Part")
			block.Shape = (Enum.PartType :: any)[s.shape]
			p = block
		end
		p.Name = s.name
		p.Size = s.size
		p.CFrame = base * s.cf
		p.Color = s.color
		p.Anchored = true
		p.CanCollide = false
		local surface = if s.studs == false then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
		for _, face in ipairs(FACES) do
			pcall(function()
				(p :: any)[face] = surface
			end)
		end
		p.Material = s.material
		p.Archivable = false
		p.Parent = model
	end
	model.Parent = parent
	return model
end

--==============================================================================
-- ONE LIGHT AND ONE EMITTER, AT TIER 1 VALUES
--
-- The birdcage this replaces carried three emitters and owned roughly half the
-- species' whole particle budget. One of each is what the rebuild asked for, and
-- both hang on the core because that is the thing the light is meant to be
-- coming from.
--
-- No hs here on purpose: EmberrootForms.Build multiplies Range, emitter Size,
-- Speed and Acceleration by hs on its way out, so these are the Tiny numbers.
-- The tool passes hs only so a standalone preview can be shown at another size.
--==============================================================================
local function effects(model: Model, hs: number)
	local core = model:FindFirstChild("MoltenCore")
	if not (core and core:IsA("BasePart")) then
		return
	end
	local glow = Instance.new("PointLight")
	glow.Name = "PyreGlow"
	glow.Color = Color3.fromRGB(255, 150, 50)
	glow.Brightness = 2.6
	glow.Range = 16 * hs
	glow.Shadows = false
	glow.Parent = core

	local att = Instance.new("Attachment")
	att.Name = "PyreAttachment"
	att.Parent = core

	local motes = Instance.new("ParticleEmitter")
	motes.Name = "PyreMotes"
	motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	motes.Color = ColorSequence.new(Color3.fromRGB(255, 168, 72), Color3.fromRGB(255, 128, 148))
	motes.LightEmission = 1
	motes.LightInfluence = 0
	motes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.10 * hs),
		NumberSequenceKeypoint.new(0.3, 0.34 * hs),
		NumberSequenceKeypoint.new(1, 0),
	})
	motes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.6, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	motes.Lifetime = NumberRange.new(1.2, 2.4)
	motes.Rate = 16
	motes.Speed = NumberRange.new(0.7 * hs, 1.8 * hs)
	motes.Drag = 1.1
	motes.Acceleration = Vector3.new(0, 1.4 * hs, 0)
	motes.EmissionDirection = Enum.NormalId.Top
	motes.SpreadAngle = Vector2.new(40, 40)
	motes.Rotation = NumberRange.new(0, 360)
	motes.RotSpeed = NumberRange.new(-45, 45)
	motes.Parent = att
end

local LEG_WORDS = { "Thigh", "Femur", "Haunch", "Shin", "Tibia", "Knee", "Hock", "Foot", "Hoof",
	"Paw", "Toe", "Stilt", "Pillar" }

local function measure(): string
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	local counts = { Block = 0, Wedge = 0, Cylinder = 0, Ball = 0 }
	local neon, legParts = 0, 0
	local names: { [string]: number } = {}
	local groups: { [string]: number } = {}
	for _, s in ipairs(specs) do
		counts[s.shape] = (counts[s.shape] or 0) + 1
		names[s.name] = (names[s.name] or 0) + 1
		if s.material == NEON then
			neon += 1
		end
		for _, w in ipairs(LEG_WORDS) do
			if string.find(s.name, w) then
				legParts += 1
				break
			end
		end
		local g = string.match(s.name, "^(%a-)_") or string.gsub(s.name, "%d+$", "")
		groups[g] = (groups[g] or 0) + 1
		local h = s.size * 0.5
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local q = (s.cf * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
					lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
					hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
				end
			end
		end
	end
	local dupes = {}
	for name, n in pairs(names) do
		if n > 1 then
			table.insert(dupes, string.format("%s x%d", name, n))
		end
	end
	return string.format(
		"%d parts (%d block, %d wedge, %d ball, %d cylinder; %d neon, %d leg-word) | x %.3f..%.3f  y %.4f..%.4f  z %.3f..%.3f | %.2f w x %.4f h x %.2f d%s",
		#specs, counts.Block, counts.Wedge, counts.Ball, counts.Cylinder, neon, legParts,
		lo.X, hi.X, lo.Y, hi.Y, lo.Z, hi.Z, hi.X - lo.X, hi.Y - lo.Y, hi.Z - lo.Z,
		if #dupes > 0 then "\nDUPLICATE NAMES: " .. table.concat(dupes, ", ") else "")
end

local function num(v: number): string
	local s = string.format("%.6f", v)
	s = string.gsub(s, "0+$", "")
	s = string.gsub(s, "%.$", "")
	if s == "-0" then
		s = "0"
	end
	return s
end

local function serialize(): string
	local out = {}
	for _, s in ipairs(specs) do
		local comps = { s.cf:GetComponents() }
		local text = {}
		for i, v in ipairs(comps) do
			text[i] = num(v)
		end
		table.insert(out, "\t{")
		table.insert(out, string.format('\t\tname = "%s",', s.name))
		table.insert(out, string.format('\t\tshape = "%s",', s.shape))
		table.insert(out, string.format("\t\tsize = Vector3.new(%s, %s, %s),", num(s.size.X),
			num(s.size.Y), num(s.size.Z)))
		table.insert(out, string.format("\t\tcf = CFrame.new(%s),", table.concat(text, ", ")))
		table.insert(out, string.format("\t\tcolor = Color3.fromRGB(%d, %d, %d),",
			math.round(s.color.R * 255), math.round(s.color.G * 255), math.round(s.color.B * 255)))
		table.insert(out, string.format("\t\tmaterial = Enum.Material.%s,", s.material.Name))
		if s.studs == false then
			table.insert(out, "\t\tstuds = false,")
		end
		table.insert(out, "\t},")
	end
	return table.concat(out, "\n")
end

return {
	specs = specs,
	build = build,
	effects = effects,
	measure = measure,
	serialize = serialize,
}
