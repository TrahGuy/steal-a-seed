--==============================================================================
-- GLOOMLOTUS, THE WALKING MANGROVE STILT TITAN -- PREVIEW AND DATA GENERATOR
--
-- A Studio authoring tool, not game code. Loaded in Edit with
--
--     loadstring(HttpService:GetAsync("http://127.0.0.1:8731/tools/art/gloomlotus_titan.luau"))()
--
-- it returns { specs, build, effects, measure, serialize }.
--
-- `specs` IS TanglemireForms.Plants.gloomlotus. `build` replays it the way
-- CreatureModel.replayPart does at hs = gs = 1 (studs on every face, material
-- last), `effects` mirrors CreatureModel.retrofitGloomAura, and `serialize`
-- prints the list in TanglemireForms' PartSpec format. Change the numbers here,
-- preview, then paste the serialized table over the old one.
--
-- Authored in the mockup's own studs: ground at Y = 0, front toward -Z.
--==============================================================================

local rad = math.rad
local UP = Vector3.new(0, 1, 0)

local WOOD = Color3.fromRGB(68, 52, 40)
local TRUNK = Color3.fromRGB(56, 42, 34)
local PEAT_MOSS = Color3.fromRGB(42, 92, 74)
local FUNGUS = Color3.fromRGB(80, 180, 150)
local WEEP = Color3.fromRGB(52, 108, 80)
local PETAL_DARK = Color3.fromRGB(38, 68, 62)
local PETAL_VIOLET = Color3.fromRGB(50, 38, 70)
local PETAL_INNER = Color3.fromRGB(70, 158, 138)
local WISP = Color3.fromRGB(80, 245, 215)

local PLASTIC = Enum.Material.Plastic
local NEON = Enum.Material.Neon

type Spec = {
	name: string,
	shape: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
}

local specs: { Spec } = {}

local function add(name: string, shape: string, size: Vector3, cf: CFrame, color: Color3,
	material: Enum.Material?): Spec
	local s = { name = name, shape = shape, size = size, cf = cf, color = color,
		material = material or PLASTIC }
	table.insert(specs, s)
	return s
end

-- Bearing in degrees, clockwise from the front (-Z) as seen from above.
local function radial(bearing: number): Vector3
	local b = rad(bearing)
	return Vector3.new(math.sin(b), 0, -math.cos(b))
end

local function at(u: Vector3, r: number, y: number): Vector3
	return u * r + Vector3.new(0, y, 0)
end

-- A block from a to b that overruns both joints; local -Z runs along it and
-- local X stays horizontal. `side` is the up hint for a steep beam.
local function beam(name: string, a: Vector3, b: Vector3, w: number, h: number, overrun: number,
	color: Color3, side: Vector3?): Spec
	local dir = b - a
	local hint = UP
	if side and math.abs(dir.Unit:Dot(UP)) > 0.9 then
		hint = side
	end
	return add(name, "Block", Vector3.new(w, h, dir.Magnitude + overrun * 2),
		CFrame.lookAt((a + b) * 0.5, b, hint), color)
end

-- A wedge hanging from `top` with its thin edge straight down. `yaw` turns its
-- width; -bearing lays the width along the ring.
local function hang(name: string, top: Vector3, len: number, w: number, t: number, yaw: number,
	color: Color3): Spec
	return add(name, "Wedge", Vector3.new(w, t, len),
		CFrame.new(top - Vector3.new(0, len * 0.5, 0)) * CFrame.Angles(0, rad(yaw), 0)
			* CFrame.Angles(rad(-90), 0, 0), color)
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

local function bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: number): Vector2
	local u = 1 - t
	return p0 * (u * u * u) + p1 * (3 * u * u * t) + p2 * (3 * u * t * t) + p3 * (t * t * t)
end

--==============================================================================
-- SUPPORTING MASS: FOUR ARCHED STILT ROOTS
--
-- Each root is one cubic curve in its own vertical plane -- out of the nexus,
-- over a high knee, and down to the plane -- cut into four beams that turn
-- about forty degrees at each joint. The last beam lands on its inner corner;
-- a flared knuckle takes the outer side, so the foot is flat on the ground.
--==============================================================================
add("RootNexus", "Block", Vector3.new(1.30, 1.05, 1.30),
	CFrame.new(0, 1.95, 0) * CFrame.Angles(0, rad(45), 0), WOOD)

-- Not four right angles: from the front the back pair peeks past the front pair.
local ROOTS = {
	{ bearing = 40, knee = 3.20, foot = 3.95, prop = 0.62 },
	{ bearing = 132, knee = 3.10, foot = 3.80, prop = 0.66 },
	{ bearing = 222, knee = 3.26, foot = 4.05, prop = 0.60 },
	{ bearing = 316, knee = 3.14, foot = 3.90, prop = 0.64 },
}
local SAMPLES = { 0, 0.28, 0.55, 0.79, 1 }
local SEGMENTS = {
	{ "RootRise", 0.86, 0.80 },
	{ "RootArch", 0.76, 0.72 },
	{ "RootDescent", 0.70, 0.68 },
	{ "RootAnchor", 0.76, 0.74 },
}

for i, root in ipairs(ROOTS) do
	local u = radial(root.bearing)
	local p0 = Vector2.new(0.42, 2.02)
	local p1 = Vector2.new(1.05, root.knee)
	local p2 = Vector2.new(root.foot - 0.40, root.knee)
	local p3 = Vector2.new(root.foot, 0)
	local pts = {}
	for k, t in ipairs(SAMPLES) do
		local q = bezier(p0, p1, p2, p3, t)
		pts[k] = at(u, q.X, q.Y)
	end
	local segs = {}
	for k, seg in ipairs(SEGMENTS) do
		segs[k] = beam(seg[1] .. i, pts[k], pts[k + 1], seg[2], seg[3], 0.20, WOOD, u)
	end
	plant(segs[4])

	local knuckle = at(u, root.foot + 0.20, 0.29)
	add("RootKnuckle" .. i, "Wedge", Vector3.new(0.74, 0.58, 0.95),
		CFrame.lookAt(knuckle, knuckle + u, UP), WOOD)

	add("RootMoss" .. i, "Block", Vector3.new(0.62, 0.12, segs[2].size.Z * 0.70),
		segs[2].cf * CFrame.new(0, SEGMENTS[2][3] * 0.5 + 0.04, 0), PEAT_MOSS)

	local q = bezier(p0, p1, p2, p3, root.prop)
	local prop = beam("PropRoot" .. i, at(u, q.X - 0.22, 0), at(u, q.X, q.Y - 0.10), 0.30, 0.30, 0, WOOD, u)
	plant(prop)
end

hang("AerialRootlet1", Vector3.new(0.26, 1.52, -0.20), 0.80, 0.16, 0.18, 20, WOOD)
hang("AerialRootlet2", Vector3.new(-0.24, 1.52, 0.30), 0.62, 0.14, 0.16, -35, WOOD)

--==============================================================================
-- DOMINANT MASS: THE TWISTING TRUNK AND ITS FUNGI
--==============================================================================
local TRUNK_SLICES = {
	{ c = Vector3.new(0.12, 2.80, 0.02), size = Vector3.new(0.90, 1.02, 0.84), yaw = 0, roll = -11 },
	{ c = Vector3.new(0.30, 3.50, -0.04), size = Vector3.new(0.80, 0.98, 0.76), yaw = 26, roll = 13 },
	{ c = Vector3.new(0.06, 4.16, 0.05), size = Vector3.new(0.72, 0.94, 0.68), yaw = 51, roll = 15 },
	{ c = Vector3.new(-0.14, 4.76, 0.00), size = Vector3.new(0.66, 0.80, 0.64), yaw = 76, roll = -7 },
}
local slices: { Spec } = {}
for i, t in ipairs(TRUNK_SLICES) do
	slices[i] = add("TwistTrunk" .. i, "Block", t.size,
		CFrame.new(t.c) * CFrame.Angles(0, rad(t.yaw), 0) * CFrame.Angles(0, 0, rad(t.roll)), TRUNK)
end

-- A bracket fungus: a disc centred ON a trunk face, so half of it stands proud.
-- Three faces and three heights, never a level pair: two glowing discs side by
-- side on a dark trunk read as a pair of eyes.
local function bracket(name: string, slice: Spec, localDir: Vector3, dy: number, d: number, tilt: number)
	local surface = slice.cf * Vector3.new(localDir.X * slice.size.X * 0.5, dy, localDir.Z * slice.size.Z * 0.5)
	local outward = slice.cf:VectorToWorldSpace(localDir)
	outward = Vector3.new(outward.X, 0, outward.Z).Unit
	local pos = surface + outward * 0.02
	add(name, "Cylinder", Vector3.new(0.10, d, d),
		CFrame.lookAt(pos, pos + outward, UP) * CFrame.Angles(rad(tilt), 0, 0) * CFrame.Angles(0, 0, rad(90)),
		FUNGUS, NEON)
end
bracket("ShelfFungus1", slices[3], Vector3.new(1, 0, 0), 0.10, 0.56, 6)
bracket("ShelfFungus2", slices[2], Vector3.new(0, 0, 1), -0.15, 0.50, 4)
bracket("ShelfFungus3", slices[1], Vector3.new(-1, 0, 0), -0.05, 0.46, 8)

--==============================================================================
-- SIGNATURE SHAPE: THE DARK LOTUS AND ITS WILL-O'-WISP JEWEL
--==============================================================================
add("LotusCalyx", "Cylinder", Vector3.new(0.50, 1.70, 1.70),
	CFrame.new(0, 5.00, 0) * CFrame.Angles(0, 0, rad(90)), PETAL_VIOLET)

-- The petal's own frame: -Z runs out along its midrib, +Y is its upper face.
local function petalFrame(bearing: number, baseR: number, baseY: number, tilt: number): CFrame
	local u = radial(bearing)
	local base = at(u, baseR, baseY)
	return CFrame.lookAt(base, base + u, UP) * CFrame.Angles(rad(tilt), 0, 0)
end

-- Half a petal: a wedge laid on its side so it tapers ACROSS its width, from a
-- full base down to a point on the midrib. `side` +1 puts it on the petal's +X.
local function halfPetal(name: string, F: CFrame, side: number, len: number, halfW: number, t: number,
	fold: number, color: Color3): Spec
	return add(name, "Wedge", Vector3.new(t, halfW, len),
		F * CFrame.Angles(0, 0, rad(fold * side)) * CFrame.new(side * (halfW * 0.5 - 0.03), 0, -len * 0.5)
			* CFrame.Angles(0, 0, rad(-90 * side)), color)
end

-- bearing, base radius, base height, length, width, thickness, tilt. Thirty
-- degrees off the front, so the front camera looks between two petals at the
-- jewel instead of at the back of one.
local OUTER = {
	{ 28, 0.40, 5.10, 3.10, 1.36, 0.20, 22 },
	{ 91, 0.40, 5.06, 2.85, 1.42, 0.20, 19 },
	{ 149, 0.40, 5.10, 3.00, 1.34, 0.20, 24 },
	{ 212, 0.40, 5.05, 2.80, 1.40, 0.20, 18 },
	{ 268, 0.40, 5.09, 2.95, 1.36, 0.20, 23 },
	{ 331, 0.40, 5.06, 2.88, 1.40, 0.20, 20 },
}
-- A broad outer petal: a flat seafoam blade, closed to a point by a violet
-- diamond -- a square turned 45 degrees whose side corners meet the blade's
-- edges. The diamond is a hair thinner so the two never share a face.
local outerFrames: { CFrame } = {}
for i, p in ipairs(OUTER) do
	local F = petalFrame(p[1], p[2], p[3], p[7])
	outerFrames[i] = F
	local len, w, t = p[4], p[5], p[6]
	local blade = len - w * 0.5
	add("OuterPetal" .. i, "Block", Vector3.new(w, t, blade), F * CFrame.new(0, 0, -blade * 0.5), PETAL_DARK)
	add("OuterPetalTip" .. i, "Block", Vector3.new(w / math.sqrt(2), t * 0.9, w / math.sqrt(2)),
		F * CFrame.new(0, 0, -blade) * CFrame.Angles(0, rad(45), 0), PETAL_VIOLET)
end

-- bearing, length, half width, tilt, side: single jagged points, alternating hands.
local INNER = {
	{ 358, 1.30, 0.62, 50, 1 }, { 62, 1.18, 0.58, 46, -1 }, { 118, 1.36, 0.64, 53, 1 },
	{ 182, 1.22, 0.60, 48, -1 }, { 238, 1.32, 0.62, 52, 1 }, { 302, 1.15, 0.58, 45, -1 },
}
for i, p in ipairs(INNER) do
	local F = petalFrame(p[1], 0.34, 5.26, p[4])
	halfPetal("InnerPetal" .. i, F, p[5], p[2], p[3], 0.20, 0, PETAL_INNER)
end

-- A cube balanced on one corner: its body diagonal is vertical, so it has a
-- point at the top and the bottom and a faceted outline from every side. It
-- floats clear of the calyx with its lowest point level with the inner tips.
local diag = Vector3.new(1, 1, 1).Unit
local ax = Vector3.new(1, -1, 0).Unit
local bz = ax:Cross(diag)
local onVertex = CFrame.fromMatrix(Vector3.zero,
	Vector3.new(ax.X, diag.X, bz.X), Vector3.new(ax.Y, diag.Y, bz.Y), Vector3.new(ax.Z, diag.Z, bz.Z))
add("WispJewel", "Block", Vector3.new(0.70, 0.70, 0.70),
	CFrame.new(0, 6.72, 0) * CFrame.Angles(0, rad(18), 0) * onVertex, WISP, NEON)

-- Weeping moss, each strand hung from an outer petal's midrib, on its underside.
-- The two named Leaf hang at the petals nearest dead right and dead left, so
-- PlantSway swings them as a pair. name, petal index, radius, length, width, thickness
local MOSS = {
	{ "Leaf", 2, 1.55, 1.40, 0.28, 0.14 },
	{ "Leaf", 5, 1.45, 1.25, 0.26, 0.14 },
	{ "WeepMoss1", 6, 1.35, 0.95, 0.24, 0.12 },
	{ "WeepMoss2", 3, 1.65, 1.55, 0.28, 0.14 },
}
for _, m in ipairs(MOSS) do
	local P = OUTER[m[2]]
	local along = (m[3] - P[2]) / math.cos(rad(P[7]))
	local top = outerFrames[m[2]] * Vector3.new(0, -P[6] * 0.5 + 0.04, -along)
	hang(m[1], top, m[4], m[5], m[6], -P[1], WEEP)
end

--==============================================================================
-- PREVIEW, EFFECTS, MEASUREMENT, SERIALIZATION
--==============================================================================
local FACES = { "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface" }

local function build(parent: Instance, base: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "GloomlotusTitan"
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
		for _, face in ipairs(FACES) do
			pcall(function()
				(p :: any)[face] = Enum.SurfaceType.Studs
			end)
		end
		p.Material = s.material
		p.Archivable = false
		p.Parent = model
	end
	model.Parent = parent
	return model
end

local function effects(model: Model, hs: number)
	local jewel = model:FindFirstChild("WispJewel")
	if not (jewel and jewel:IsA("BasePart")) then
		return
	end
	local glow = Instance.new("PointLight")
	glow.Name = "WispGlow"
	glow.Color = WISP
	glow.Brightness = 2.2
	glow.Range = 14 * hs
	glow.Shadows = false
	glow.Parent = jewel

	local att = Instance.new("Attachment")
	att.Name = "WispAttachment"
	att.CFrame = jewel.CFrame:ToObjectSpace(CFrame.new(jewel.Position))
	att.Parent = jewel

	local motes = Instance.new("ParticleEmitter")
	motes.Name = "WispMotes"
	motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	motes.Color = ColorSequence.new(WISP, Color3.fromRGB(196, 255, 238))
	motes.LightEmission = 1
	motes.LightInfluence = 0
	motes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08 * hs),
		NumberSequenceKeypoint.new(0.3, 0.42 * hs),
		NumberSequenceKeypoint.new(1, 0),
	})
	motes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.6, 0.6),
		NumberSequenceKeypoint.new(1, 1),
	})
	motes.Lifetime = NumberRange.new(1.6, 3.0)
	motes.Rate = 16
	motes.Speed = NumberRange.new(0.3 * hs, 0.9 * hs)
	motes.Drag = 1.4
	motes.Acceleration = Vector3.new(0, 0.5 * hs, 0)
	motes.EmissionDirection = Enum.NormalId.Top
	motes.SpreadAngle = Vector2.new(55, 55)
	motes.Rotation = NumberRange.new(0, 360)
	motes.RotSpeed = NumberRange.new(-40, 40)
	motes.Parent = att
end

local function measure(): string
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	local counts = { Block = 0, Wedge = 0, Cylinder = 0, Ball = 0 }
	local neon, leaves = 0, 0
	for _, s in ipairs(specs) do
		counts[s.shape] += 1
		if s.material == NEON then
			neon += 1
		end
		if s.name == "Leaf" then
			leaves += 1
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
	return string.format(
		"%d parts (%d block, %d wedge, %d cylinder, %d ball; %d neon, %d Leaf) | x %.3f..%.3f  y %.4f..%.4f  z %.3f..%.3f | %.2f w x %.3f h x %.2f d",
		#specs, counts.Block, counts.Wedge, counts.Cylinder, counts.Ball, neon, leaves,
		lo.X, hi.X, lo.Y, hi.Y, lo.Z, hi.Z, hi.X - lo.X, hi.Y - lo.Y, hi.Z - lo.Z)
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
		table.insert(out, string.format("\t\t\tsize = Vector3.new(%s, %s, %s),", num(s.size.X), num(s.size.Y),
			num(s.size.Z)))
		table.insert(out, string.format("\t\t\tcf = CFrame.new(%s),", table.concat(text, ", ")))
		table.insert(out, string.format("\t\t\tcolor = Color3.fromRGB(%d, %d, %d),", math.round(s.color.R * 255),
			math.round(s.color.G * 255), math.round(s.color.B * 255)))
		table.insert(out, string.format("\t\t\tmaterial = Enum.Material.%s,", s.material.Name))
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
