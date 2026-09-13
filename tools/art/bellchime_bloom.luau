--==============================================================================
-- BELLCHIME, THE PORCELAIN DUSK-CHIME -- PREVIEW AND DATA GENERATOR
--
-- A Studio authoring tool, not game code. Loaded in Edit with
--
--     loadstring(HttpService:GetAsync("http://127.0.0.1:8731/tools/art/bellchime_bloom.luau"))()
--
-- it returns { specs, build, effects, measure, serialize }.
--
-- `specs` IS GreenhollowForms.Plants.bellchime. `build` replays it the way
-- CreatureModel.replayPart does at hs = gs = 1, `effects` mirrors
-- CreatureModel.retrofitChimeAura, and `serialize` prints the list in the
-- PartSpec format the forms modules share.
--
-- THE DUSTBOWL CONTRACT, NOT THE EMBERROOT ONE. Greenhollow is replayed through
-- replayPart, which scales geometry only -- so the aura is written here with hs
-- APPLIED (Range = 12 * hs). Emberroot is the other way round: its Build grows
-- the light afterwards, so its numbers are written bare. Getting these two the
-- wrong way round gives a Colossal either no light or hs squared of it.
--
-- Authored in the mockup's own studs: ground at Y = 0, front toward -Z.
--
-- WHAT A WEDGE IS, since every leaf and sepal is one: measured by raycast rather
-- than recalled, a WedgePart is FULL HEIGHT at its local +Z and tapers to a
-- knife edge at local -Z, flat along the bottom and constant across X. So
-- CFrame.lookAt(mid, tip, widthAxis) gives a blade that comes to a point at
-- `tip`, tapering across the axis handed in as the up hint.
--
-- WHAT IT REPLACES. Not the "43-part birdcage" the brief remembers -- measured,
-- the shipped Bellchime is 26 parts and HAS NO BELL: Form = "bell" matches no
-- branch in CreatureModel's head chain, so it fell through to a bare stem, seven
-- soil clods, four leaves and a face, and stood 4.78 studs against a 6.20 frame.
-- The Epic of the starter biome has been a headless stalk.
--==============================================================================

local rad = math.rad
local UP = Vector3.new(0, 1, 0)

--==============================================================================
-- THE PALETTE
--
-- Body, Crown and the biome's own Leaf and Stem come straight out of SeedData,
-- so the bloom is painted in the colours the Almanac and the shop tile already
-- show for it. Cool porcelain is the whole point of this species -- it is the
-- only cold colour in a biome of greens, which is how the Epic announces itself
-- before you have read the word.
--==============================================================================
local PORCELAIN = Color3.fromRGB(214, 226, 242) -- SeedData.Body
local PORCELAIN_DEEP = Color3.fromRGB(182, 198, 224) -- the shaded side of a panel
local PINK = Color3.fromRGB(240, 150, 168) -- SeedData.Crown, the scalloped rim
local LEAF = Color3.fromRGB(86, 150, 66) -- SeedData.Leaf / Accent
local STEM = Color3.fromRGB(124, 182, 92) -- SeedData.Stem
local PEARL = Color3.fromRGB(255, 228, 156) -- the clapper, lit
local THROAT = Color3.fromRGB(255, 212, 150) -- the bell's lit inside
local CREAM = Color3.fromRGB(246, 240, 224) -- the little face
local INK = Color3.fromRGB(58, 48, 54) -- its eyes
local GLINT = Color3.fromRGB(255, 255, 255)
local BRASS = Color3.fromRGB(226, 186, 96) -- the chime buds' tiny clappers

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
		studs = if mat == NEON then false else nil,
	}
	table.insert(specs, s)
	return s
end

--==============================================================================
-- PLACEMENT HELPERS
--==============================================================================
local function beam(name: string, a: Vector3, b: Vector3, w: number, h: number, overrun: number,
	color: Color3, material: Enum.Material?): Spec
	local dir = b - a
	local up = UP
	if math.abs(dir.Unit:Dot(up)) > 0.98 then
		up = Vector3.new(0, 0, 1)
	end
	return add(name, "Block", Vector3.new(w, h, dir.Magnitude + overrun * 2),
		CFrame.lookAt((a + b) * 0.5, b, up), color, material)
end

local function blade(name: string, from: Vector3, tip: Vector3, width: number, thick: number,
	color: Color3, widthAxis: Vector3, material: Enum.Material?): Spec
	local len = (tip - from).Magnitude
	return add(name, "Wedge", Vector3.new(thick, width, len),
		CFrame.lookAt((from + tip) * 0.5, tip, widthAxis), color, material)
end

-- Around the bell's own axis: bearing in degrees, radius out, height up.
local BELL = Vector3.new(0.02, 0, -2.10)
local function ring(bearing: number, r: number, y: number): Vector3
	local a = rad(bearing)
	return BELL + Vector3.new(math.sin(a) * r, y, math.cos(a) * r)
end

--==============================================================================
-- THE STEM, WALKED RATHER THAN STACKED
--
-- Five segments out of the soil, each starting exactly where the last finished,
-- leaning further forward as they rise until the last one is nearly horizontal
-- and the flower hangs off the end of it. That arc is the species: a bell that
-- sits upright on a post is a lamp, and this one has to look like it is being
-- carried.
--==============================================================================
-- IT HAS TO GO RIGHT OVER. The first pass drifted 1.5 studs forward across six
-- of rise, which is a lean, and the bell ended up sitting ON the post like a
-- lampshade. The concept bends the stem almost flat at the top so the flower
-- hangs a clear two studs out in front of its own root -- that overhang IS the
-- species, and it is what makes the bloom read as being carried rather than
-- balanced.
local S0 = Vector3.new(0, 0.08, 0.34)
local S1 = Vector3.new(0.02, 1.86, 0.30)
local S2 = Vector3.new(0.06, 3.48, 0.12)
local S3 = Vector3.new(0.08, 4.78, -0.38)
local S4 = Vector3.new(0.06, 5.75, -1.18)
local S5 = Vector3.new(0.02, 6.02, -2.02)

beam("StemBase", S0, S1, 0.58, 0.58, 0.10, STEM)
beam("StemMid", S1, S2, 0.50, 0.50, 0.09, STEM)
beam("StemArch1", S2, S3, 0.44, 0.44, 0.08, STEM)
beam("StemArch2", S3, S4, 0.38, 0.38, 0.07, STEM)
beam("StemArch3", S4, S5, 0.32, 0.32, 0.06, STEM)

-- Where the flower is hung. A collar rather than a butt joint: the stem stops
-- being a stem here and the bell has to look grown onto it.
add("Collar", "Block", Vector3.new(0.50, 0.28, 0.48),
	CFrame.new(BELL + Vector3.new(0, 5.90, 0)) * CFrame.Angles(rad(14), rad(20), 0), LEAF)

-- Two tufts at the foot, which is all this biome's soil heap is reduced to. The
-- shared footing is skipped when a species answers with its own geometry, and
-- seven clods around a plant this delicate read as rubble.
for i, spec in ipairs({ { -128, 0.52, 0.62 }, { 62, 0.44, 0.50 } }) do
	local a = rad(spec[1] :: number)
	local root = Vector3.new(math.sin(a) * 0.34, 0.06, math.cos(a) * 0.34 + 0.24)
	local tip = root + Vector3.new(math.sin(a) * (spec[2] :: number), spec[3] :: number,
		math.cos(a) * (spec[2] :: number))
	blade("Sprout" .. i, root, tip, 0.26, 0.10, LEAF, UP)
end

--==============================================================================
-- THE CALYX
--
-- Three sepals gripping the top of the bell, pointing down and out. Three and
-- not six: a ring of identical parts is the thing to avoid, and three at uneven
-- bearings reads as a grip rather than as a collar.
--==============================================================================
for i, bearing in ipairs({ 24, 148, 262 }) do
	local root = ring(bearing, 0.18, 5.82)
	local tip = ring(bearing, 0.70, 5.34)
	local a = rad(bearing)
	local tangent = Vector3.new(math.cos(a), 0, -math.sin(a))
	blade("Sepal" .. i, root, tip, 0.34, 0.14, LEAF, tangent)
end

--==============================================================================
-- THE COROLLA
--
-- A cap, six porcelain panels splaying down and out, and six scalloped pink
-- lobes turning outward at the mouth.
--
-- THE PANELS OVERLAP AT THE SHOULDER AND ONLY PART AT THE HEM. Each is 0.70
-- across against the 0.33 of arc it owns up at radius 0.32, so the six close
-- into a solid dome there and open into a skirt as they descend -- which is what
-- a bell flower does, and what six evenly spaced blades of constant width
-- conspicuously do not.
--==============================================================================
add("BellCap", "Ball", Vector3.new(1.12, 1.12, 1.12),
	CFrame.new(BELL + Vector3.new(0, 5.52, 0)), PORCELAIN)

for i = 1, 6 do
	local bearing = (i - 1) * 60 + (if i % 2 == 0 then 4 else -3)
	local top = ring(bearing, 0.38, 5.46)
	local hem = ring(bearing, 0.94, 4.22)
	beam("BellPanel" .. i, top, hem, 0.86, 0.18, 0.05,
		if i % 3 == 0 then PORCELAIN_DEEP else PORCELAIN)
end

for i = 1, 6 do
	local bearing = (i - 1) * 60 + 30 + (if i % 2 == 0 then -5 else 4)
	local lip = ring(bearing, 0.82, 4.34)
	-- Turned OUT and slightly UP: the concept's hem curls back on itself, and a
	-- lobe that only points down reads as a torn edge.
	local out = ring(bearing, 1.26, 4.02)
	beam("RimPetal" .. i, lip, out, 0.72, 0.20, 0.04, PINK)
end

-- The lit inside, seen up into. Neon because the light is meant to be coming
-- from in there and a plastic disc in shadow just reads as a hole.
add("BellThroat", "Cylinder", Vector3.new(0.16, 1.30, 1.30),
	CFrame.new(BELL + Vector3.new(0, 4.58, 0)) * CFrame.Angles(0, 0, rad(90)), THROAT, NEON)

--==============================================================================
-- THE CLAPPER
--
-- A pearl on a short filament, hung so it sits BELOW the hem. Above it, it is a
-- light in a cup; below it, it is the thing the flower is holding -- and the
-- concept is unambiguous that you can see it.
--==============================================================================
add("PearlStem", "Cylinder", Vector3.new(1.10, 0.12, 0.12),
	CFrame.new(BELL + Vector3.new(0, 5.02, 0)) * CFrame.Angles(0, 0, rad(90)), CREAM)
-- Hung so it clears the hem: inside the cup it is a light in a bowl, and the
-- concept is unambiguous that the pearl is the thing you see first.
add("Pearl", "Ball", Vector3.new(0.84, 0.84, 0.84),
	CFrame.new(BELL + Vector3.new(0, 4.14, 0)), PEARL, NEON)

--==============================================================================
-- THE FACE, WHICH LOOKS OUT FROM UNDER THE HEM
--
-- Left/Right Eye and Pupil are the names PlantSway's gaze rig pairs by prefix,
-- and it ROTATES the eyeball and carries the pupil along -- so each pupil is
-- placed on the surface of its own eye rather than floating in front of the
-- face.
--==============================================================================
-- Tucked up under the pearl so the two touch: any lower and the head is a
-- floating ball, any higher and it eclipses the light it is lit by.
local FACE = BELL + Vector3.new(0, 3.30, -0.20)
add("FaceOrb", "Ball", Vector3.new(0.84, 0.84, 0.84), CFrame.new(FACE), CREAM)
for _, side in ipairs({ -1, 1 }) do
	local tag = if side < 0 then "Left" else "Right"
	local eye = FACE + Vector3.new(side * 0.21, 0.06, -0.36)
	add(tag .. "Eye", "Ball", Vector3.new(0.23, 0.23, 0.23), CFrame.new(eye), INK)
	add(tag .. "Pupil", "Ball", Vector3.new(0.09, 0.09, 0.09),
		CFrame.new(eye + Vector3.new(side * 0.03, 0.05, -0.08)), GLINT)
end
add("Smile", "Block", Vector3.new(0.20, 0.05, 0.06),
	CFrame.new(FACE + Vector3.new(0, -0.18, -0.40)) * CFrame.Angles(rad(-8), 0, 0), INK)

--==============================================================================
-- THE LEAVES
--
-- TWO OF THEM ARE CALLED `Leaf`, WHICH IS THE RIG. PlantSway swings a part with
-- that exact name about its own centre, in opposition on either side of the
-- stem, and those two are the big sweeping blades the concept leads with. The
-- three low ones keep their own names and stay still, which is right: a plant
-- whose every leaf moves together reads as a flag, not as a breeze.
--==============================================================================
blade("Leaf", Vector3.new(-0.26, 1.46, 0.24), Vector3.new(-1.52, 4.62, 0.58), 0.62, 0.13,
	LEAF, UP)
blade("Leaf", Vector3.new(0.30, 1.30, 0.16), Vector3.new(1.38, 3.86, -0.22), 0.56, 0.13,
	LEAF, UP)
blade("LeafLow1", Vector3.new(-0.24, 0.80, 0.06), Vector3.new(-1.22, 1.42, -0.58), 0.46, 0.11,
	LEAF, UP)
blade("LeafLow2", Vector3.new(0.28, 0.70, 0.12), Vector3.new(1.28, 1.16, -0.44), 0.44, 0.11,
	LEAF, UP)
blade("LeafLow3", Vector3.new(0.04, 0.66, 0.32), Vector3.new(0.38, 1.10, 1.28), 0.40, 0.10,
	LEAF, UP)

--==============================================================================
-- THE TWIN CHIME BUDS
--
-- Both on the same side, at two different lengths, because that is where the
-- concept hangs them and because a symmetric pair either side of the stem would
-- fight the one big bell for the eye. Each is a curled stalk, a porcelain bud, a
-- pink lip and a brass clapper the size of a pea.
--==============================================================================
local BUDS = {
	{ from = Vector3.new(-0.16, 4.28, 0.06), out = Vector3.new(-1.30, 4.58, 0.16), drop = 0.40,
		size = 0.36 },
	{ from = Vector3.new(-0.14, 4.62, 0.02), out = Vector3.new(-0.74, 4.80, 0.12), drop = 0.30,
		size = 0.29 },
}
for i, b in ipairs(BUDS) do
	beam("BudStalk" .. i, b.from, b.out, 0.12, 0.12, 0.05, STEM)
	local hang = b.out + Vector3.new(-0.04, -b.drop, 0.01)
	add("BudBody" .. i, "Ball", Vector3.new(b.size, b.size, b.size), CFrame.new(hang), PORCELAIN)
	add("BudTip" .. i, "Block", Vector3.new(b.size * 0.86, b.size * 0.44, b.size * 0.86),
		CFrame.new(hang + Vector3.new(0, -b.size * 0.52, 0)), PINK)
	add("BudBell" .. i, "Ball", Vector3.new(b.size * 0.36, b.size * 0.36, b.size * 0.36),
		CFrame.new(hang + Vector3.new(0, -b.size * 0.86, 0)), BRASS)
end

--==============================================================================
-- AND THE WHOLE THING SITS ON THE PLANE
--
-- Settled once, at the end, over every rotated corner in the model rather than
-- part by part. A walker needs each foot planted independently; a plant needs
-- its lowest leaf-tip to touch and nothing else to care.
--==============================================================================
local function settle()
	local low = math.huge
	for _, s in ipairs(specs) do
		local h = s.size * 0.5
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					low = math.min(low,
						(s.cf * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position.Y)
				end
			end
		end
	end
	for _, s in ipairs(specs) do
		s.cf = s.cf + Vector3.new(0, -low, 0)
	end
end
settle()

--==============================================================================
-- PREVIEW, EFFECTS, MEASUREMENT, SERIALIZATION
--==============================================================================
local FACES = { "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface",
	"BackSurface" }

local function build(parent: Instance, base: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "BellchimeBloom"
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
-- ONE LIGHT AND ONE EMITTER, AND THE MOTES FALL
--
-- Every other aura in this game rises -- embers off a furnace, sparks off a
-- wisp. This one DRIFTS DOWN out of the bell, because that is what the concept
-- draws and because it is the one cue that says the light is hanging above you
-- rather than burning in front of you. Soft numbers throughout: a dusk chime in
-- the starter biome should glow, not blaze.
--==============================================================================
local function effects(model: Model, hs: number)
	local pearl = model:FindFirstChild("Pearl")
	if not (pearl and pearl:IsA("BasePart")) then
		return
	end
	local glow = Instance.new("PointLight")
	glow.Name = "ChimeGlow"
	glow.Color = Color3.fromRGB(255, 220, 164)
	glow.Brightness = 1.6
	glow.Range = 12 * hs
	glow.Shadows = false
	glow.Parent = pearl

	local att = Instance.new("Attachment")
	att.Name = "ChimeAttachment"
	att.Parent = pearl

	local motes = Instance.new("ParticleEmitter")
	motes.Name = "ChimeMotes"
	motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	motes.Color = ColorSequence.new(Color3.fromRGB(255, 236, 190), Color3.fromRGB(240, 150, 168))
	motes.LightEmission = 1
	motes.LightInfluence = 0
	motes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05 * hs),
		NumberSequenceKeypoint.new(0.35, 0.20 * hs),
		NumberSequenceKeypoint.new(1, 0),
	})
	motes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(0.5, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	motes.Lifetime = NumberRange.new(1.8, 3.2)
	motes.Rate = 10
	motes.Speed = NumberRange.new(0.15 * hs, 0.5 * hs)
	motes.Drag = 2.2
	motes.Acceleration = Vector3.new(0, -0.55 * hs, 0)
	motes.EmissionDirection = Enum.NormalId.Bottom
	motes.SpreadAngle = Vector2.new(38, 38)
	motes.Rotation = NumberRange.new(0, 360)
	motes.RotSpeed = NumberRange.new(-30, 30)
	motes.Parent = att
end

local LEG_WORDS = { "Thigh", "Femur", "Haunch", "Shin", "Tibia", "Knee", "Hock", "Foot", "Hoof",
	"Paw", "Toe", "Stilt", "Pillar" }

local function measure(): string
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	local counts = { Block = 0, Wedge = 0, Cylinder = 0, Ball = 0 }
	local neon, leaves, legParts = 0, 0, 0
	local names: { [string]: number } = {}
	for _, s in ipairs(specs) do
		counts[s.shape] = (counts[s.shape] or 0) + 1
		names[s.name] = (names[s.name] or 0) + 1
		if s.material == NEON then
			neon += 1
		end
		if s.name == "Leaf" then
			leaves += 1
		end
		for _, w in ipairs(LEG_WORDS) do
			if string.find(s.name, w) then
				legParts += 1
				break
			end
		end
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
		if n > 1 and name ~= "Leaf" then
			table.insert(dupes, string.format("%s x%d", name, n))
		end
	end
	return string.format(
		"%d parts (%d block, %d wedge, %d ball, %d cylinder; %d neon, %d Leaf, %d leg-word) | x %.3f..%.3f  y %.4f..%.4f  z %.3f..%.3f | %.2f w x %.4f h x %.2f d%s",
		#specs, counts.Block, counts.Wedge, counts.Ball, counts.Cylinder, neon, leaves, legParts,
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
		table.insert(out, "\t\t{")
		table.insert(out, string.format('\t\t\tname = "%s",', s.name))
		table.insert(out, string.format('\t\t\tshape = "%s",', s.shape))
		table.insert(out, string.format("\t\t\tsize = Vector3.new(%s, %s, %s),", num(s.size.X),
			num(s.size.Y), num(s.size.Z)))
		table.insert(out, string.format("\t\t\tcf = CFrame.new(%s),", table.concat(text, ", ")))
		table.insert(out, string.format("\t\t\tcolor = Color3.fromRGB(%d, %d, %d),",
			math.round(s.color.R * 255), math.round(s.color.G * 255), math.round(s.color.B * 255)))
		table.insert(out, string.format("\t\t\tmaterial = Enum.Material.%s,", s.material.Name))
		if s.studs == false then
			table.insert(out, "\t\t\tstuds = false,")
		end
		table.insert(out, "\t\t},")
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
