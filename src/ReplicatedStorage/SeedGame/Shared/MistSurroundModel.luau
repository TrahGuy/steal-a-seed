--!strict
--==============================================================================
-- Steal a Seed :: MistSurroundModel (2026-10-11, Enchanted Mist stage 3)
--
-- THE ENCHANTED MIST SURROUND, built in code from the owner's own builder
-- (D:/KAPE/EnchantedMistSurround/enchanted_mist_surround_paste.luau, preview
-- beside it; brief KB/EVENT-NPC-SURROUND-CLAUDE-PROMPT.md): a woodland alcove
-- for Mosskeeper -- a 12-stud octagonal pad 0.3 studs up, a branch-and-leaf arch
-- behind him about 18 studs wide, root supports, a rear crescent of mossy rocks
-- and leaf bushes, two mint Dewdrop lanterns. Its configuration, layout tables
-- and build sequence are the builder's own, copied verbatim (gen_surround.py);
-- left out are its Workspace sweep, its parenting and its measurement report
-- (the measurements are MosskeeperSpec's).
--
-- `build(pivot)`: `pivot` is the floor under the NPC, local -Z the open front.
-- Every part is anchored; only the pad collides and is found by a ray; nothing
-- touches. The NPCAnchor (the PrimaryPart) sits on the pad, feet level, facing
-- local -Z.
--==============================================================================
local MistSurroundModel = {}

local MODEL_NAME = "EnchantedMistSurround"
local BUILDER_TAG = "EnchantedMistSurround.v1" -- stored on the model; reruns replace only models with this tag
local TAG_ATTRIBUTE = "BuilderTag"

-- limits the final checks measure against
local MAX_RADIUS = 20 -- studs, horizontal, from the NPC (40-stud footprint)
local MAX_HEIGHT = 14 -- studs above the placement floor
local PARTS_TARGET_MIN = 60
local PARTS_TARGET_MAX = 90
local PARTS_HARD_MAX = 100
local APPROACH_WIDTH = 12 -- clear corridor in front of the NPC (local -Z), studs
local NPC_CLEAR_RADIUS = 2.5 -- keep-clear box around the NPC, studs from the anchor
local NPC_CLEAR_HEIGHT = 9 -- ... and this tall (the NPC plus his staff)
local ARCH_SPAN_TARGET = 18 -- studs, outer width of the arch beams
local ARCH_SPAN_TOLERANCE = 1.5

-- standing pad (an octagon: two crossed slabs plus four chamfer wedges)
local PAD_WIDTH = 12
local PAD_HEIGHT = 0.3
local PAD_CHAMFER = 2 -- corner cut, studs
local ANCHOR_SIZE = Vector3.new(1, 0.2, 1)

-- arch beams: { x, y, z, width, depth } per joint, base -> apex (x right, y up, z back)
local ARCH_RIGHT: { { number } } = {
	{ 8.0, 0.4, 4.8, 2.0, 2.2 },
	{ 7.8, 3.6, 4.6, 2.0, 2.2 },
	{ 6.9, 6.8, 4.5, 1.8, 2.0 },
	{ 4.9, 9.4, 4.7, 1.6, 1.8 },
	{ 2.3, 11.0, 4.5, 1.4, 1.6 },
	{ 0.2, 11.6, 4.6, 1.3, 1.5 },
}
local ARCH_LEFT: { { number } } = {
	{ -8.3, 0.4, 4.4, 2.0, 2.2 },
	{ -8.4, 3.2, 4.7, 2.0, 2.2 },
	{ -7.3, 6.2, 4.8, 1.9, 2.0 },
	{ -5.3, 9.0, 4.6, 1.6, 1.8 },
	{ -2.6, 11.0, 4.4, 1.4, 1.6 },
	{ 0.2, 11.6, 4.6, 1.3, 1.5 },
}
local ARCH_JOINT_OVERLAP = 0.35 -- beams run this far past each joint so bends stay closed

-- root supports: { ax, ay, az, bx, by, bz, width, depth, flat }  (flat = lies on the ground)
local ROOTS: { { number } } = {
	{ 8.0, 0.56, 4.8, 11.0, 0.56, 2.2, 1.6, 1.1, 1 },
	{ 8.0, 0.56, 4.8, 9.6, 0.56, 9.0, 1.5, 1.0, 1 },
	{ 6.0, 0.7, 6.6, 7.7, 4.4, 5.0, 1.3, 1.3, 0 },
	{ -8.3, 0.56, 4.4, -11.2, 0.56, 2.8, 1.6, 1.1, 1 },
	{ -8.3, 0.56, 4.4, -9.9, 0.56, 8.8, 1.5, 1.0, 1 },
	{ -6.1, 0.7, 6.4, -7.8, 4.3, 4.9, 1.3, 1.3, 0 },
}
-- root knots at the arch feet: { x, z, sizeX, sizeY, sizeZ, yawDegrees }
local ROOT_KNOTS: { { number } } = {
	{ 8.0, 4.8, 3.2, 1.6, 3.4, 12 },
	{ -8.3, 4.4, 3.4, 1.6, 3.2, -9 },
}

-- leaf cards on the arch: { x, y, z, angleDeg (in the arch plane), length, width, rollDeg, colourIndex, side (-1 front / +1 back) }
local LEAVES: { { number } } = {
	{ 8.9, 2.2, 3.3, 78, 3.2, 1.7, -12, 2, -1 },
	{ 8.2, 5.4, 3.2, 62, 3.0, 1.8, 10, 3, -1 },
	{ 6.2, 8.4, 3.3, 50, 2.9, 1.7, -8, 2, -1 },
	{ 3.8, 10.2, 3.3, 38, 2.6, 1.6, 12, 3, -1 },
	{ 7.2, 6.2, 3.1, 250, 2.6, 1.5, 14, 1, -1 },
	{ -9.0, 2.6, 3.2, 100, 3.4, 1.7, 10, 3, -1 },
	{ -8.0, 5.8, 3.3, 118, 3.0, 1.8, -10, 2, -1 },
	{ -6.0, 8.8, 3.2, 132, 2.8, 1.7, 8, 3, -1 },
	{ -3.4, 10.6, 3.3, 142, 2.5, 1.6, -12, 2, -1 },
	{ -7.0, 6.6, 3.1, 285, 2.6, 1.5, -14, 1, -1 },
	{ 0.6, 10.9, 3.3, 72, 2.0, 1.5, -6, 3, -1 },
	{ -0.6, 10.9, 3.4, 108, 2.0, 1.5, 6, 2, -1 },
	-- back of the arch (so it is leafy from behind too)
	{ 7.6, 4.6, 6.0, 80, 3.0, 1.7, 10, 2, 1 },
	{ -7.4, 4.8, 6.1, 100, 3.0, 1.7, -10, 3, 1 },
	{ 5.2, 9.0, 5.9, 55, 2.6, 1.6, -8, 3, 1 },
	{ -4.6, 9.4, 5.9, 125, 2.6, 1.6, 8, 2, 1 },
}
-- rear crescent rocks: { angleDeg from local +Z toward +X, radius, sizeX, sizeY, sizeZ, yawDeg, mossCapHeight }
local ROCKS: { { number } } = {
	{ -64, 12.8, 4.4, 2.6, 3.4, 40, 0.55 },
	{ -38, 13.8, 3.8, 3.2, 3.2, -10, 0.6 },
	{ -12, 14.4, 5.0, 2.2, 3.6, 8, 0.5 },
	{ 14, 13.9, 4.2, 3.4, 3.4, -25, 0.6 },
	{ 40, 13.2, 3.6, 2.4, 3.0, 15, 0.5 },
	{ 65, 12.6, 4.6, 2.8, 3.4, -35, 0.55 },
}
-- broad leaf bushes in front of the rocks: { angleDeg, radius, sizeX, sizeY, sizeZ, yawDeg }
local BUSHES: { { number } } = {
	{ -32, 11.2, 3.8, 1.5, 2.8, 20 },
	{ -8, 11.8, 3.4, 1.6, 2.6, -15 },
	{ 16, 11.6, 3.6, 1.5, 2.6, 10 },
	{ 36, 11.4, 3.8, 1.4, 2.8, -30 },
}

-- Dewdrop lanterns: { bracketStartX, Y, Z, hangX, hangY, hangZ }  (hang = under the bracket tip)
local LANTERNS: { { number } } = {
	{ 5.9, 8.5, 4.4, 4.3, 8.05, 3.1 },
	{ -6.1, 8.3, 4.6, -4.5, 7.7, 3.0 },
}
local LANTERN_BALL = 1.2 -- Dewdrop diameter
local LANTERN_TIP = 0.55
local LANTERN_LIGHT = true -- a soft mint PointLight inside each lantern (set false to skip)
local APEX_GEM = Vector3.new(0.2, 11.3, 3.75) -- one restrained mint highlight on the arch front
local APEX_GEM_SIZE = 0.9

-- palette (forest green, warm brown, muted stone, restrained mint)
local LEAF_DARK = Color3.fromRGB(44, 94, 52)
local LEAF_MID = Color3.fromRGB(66, 126, 62)
local LEAF_LIGHT = Color3.fromRGB(96, 158, 76)
local ROOT_DARK = Color3.fromRGB(82, 54, 38)
local ROOT_MID = Color3.fromRGB(110, 74, 48)
local ROOT_LIGHT = Color3.fromRGB(138, 96, 64)
local STONE = Color3.fromRGB(116, 120, 110)
local STONE_DARK = Color3.fromRGB(92, 96, 90)
local PAD_STONE = Color3.fromRGB(124, 128, 114)
local MOSS = Color3.fromRGB(92, 140, 66)
local MINT = Color3.fromRGB(150, 255, 200)
local MINT_LIGHT_COLOR = Color3.fromRGB(160, 255, 210)

local LEAF_COLOURS: { Color3 } = { LEAF_DARK, LEAF_MID, LEAF_LIGHT }

type Role = "pad" | "deco" | "glow" | "anchor"


MistSurroundModel.Name = MODEL_NAME
MistSurroundModel.BuilderTag = BUILDER_TAG
MistSurroundModel.TagAttribute = TAG_ATTRIBUTE
MistSurroundModel.PadHeight = PAD_HEIGHT
MistSurroundModel.PadWidth = PAD_WIDTH
-- The builder's own limits, for the spec to measure against.
MistSurroundModel.Limits = {
	MaxRadius = MAX_RADIUS,
	MaxHeight = MAX_HEIGHT,
	PartsMin = PARTS_TARGET_MIN,
	PartsMax = PARTS_TARGET_MAX,
	PartsHardMax = PARTS_HARD_MAX,
	ApproachWidth = APPROACH_WIDTH,
	NpcClearRadius = NPC_CLEAR_RADIUS,
	NpcClearHeight = NPC_CLEAR_HEIGHT,
	ArchSpan = ARCH_SPAN_TARGET,
	ArchSpanTolerance = ARCH_SPAN_TOLERANCE,
}

-- `pivot`: the floor under the NPC, local -Z the open front. Without a
-- `parent` the model is left unparented, for the caller to finish first.
function MistSurroundModel.build(pivot: CFrame, parent: Instance?): Model
	local PIVOT = pivot
	local model = Instance.new("Model")
	model.Name = MODEL_NAME
	model:SetAttribute(TAG_ATTRIBUTE, BUILDER_TAG)

	local folders: { [string]: Folder } = {}
	local function folder(name: string): Folder
		local existing: Folder? = folders[name]
		if existing then
			return existing
		end
		local f = Instance.new("Folder")
		f.Name = name
		f.Parent = model
		folders[name] = f
		return f
	end

	local function style(p: BasePart, color: Color3, role: Role)
		local surface = Enum.SurfaceType.Studs
		if role == "glow" or role == "anchor" then
			surface = Enum.SurfaceType.Smooth
		end
		p.TopSurface = surface
		p.BottomSurface = surface
		p.LeftSurface = surface
		p.RightSurface = surface
		p.FrontSurface = surface
		p.BackSurface = surface
		p.Anchored = true
		p.Color = color
		p.Material = if role == "glow" then Enum.Material.Neon else Enum.Material.Plastic
		p.CastShadow = role ~= "glow" and role ~= "anchor"
		p.CanCollide = role == "pad" -- only the standing pad collides
		p.CanTouch = false
		p.CanQuery = role == "pad"
	end

	local function place(p: BasePart, name: string, group: string, size: Vector3, localCF: CFrame, color: Color3, role: Role): BasePart
		p.Name = name
		p.Size = size
		p.CFrame = PIVOT * localCF
		style(p, color, role)
		p.Parent = folder(group)
		return p
	end

	local function block(name: string, group: string, size: Vector3, localCF: CFrame, color: Color3, role: Role): BasePart
		return place(Instance.new("Part"), name, group, size, localCF, color, role)
	end

	local function ball(name: string, group: string, diameter: number, at: Vector3, color: Color3, role: Role): BasePart
		local p = Instance.new("Part")
		p.Shape = Enum.PartType.Ball
		return place(p, name, group, Vector3.new(diameter, diameter, diameter), CFrame.new(at), color, role)
	end

	-- a right-triangle prism: right angle at a, legs a->b and a->c, thickness t (needs a->b perpendicular to a->c)
	local function tri(name: string, group: string, a: Vector3, b: Vector3, c: Vector3, t: number, color: Color3, role: Role): BasePart
		local y = b - a
		local zv = -(c - a)
		assert(math.abs(y.Unit:Dot(zv.Unit)) < 1e-3, name .. ": triangle legs are not perpendicular")
		local x = y:Cross(zv).Unit
		local center = a + y * 0.5 + (c - a) * 0.5
		local cf = CFrame.fromMatrix(center, x, y.Unit, zv.Unit)
		return place(Instance.new("WedgePart"), name, group, Vector3.new(t, y.Magnitude, zv.Magnitude), cf, color, role)
	end

	-- an oriented box running from a to b; zref picks which way the depth faces
	local function beam(name: string, group: string, a: Vector3, b: Vector3, w: number, d: number, zref: Vector3, over0: number, over1: number, color: Color3): BasePart
		local dir = b - a
		local y = dir.Unit
		local x = y:Cross(zref).Unit
		local z = x:Cross(y)
		local a2 = a - y * over0
		local b2 = b + y * over1
		local cf = CFrame.fromMatrix((a2 + b2) * 0.5, x, y, z)
		return block(name, group, Vector3.new(w, dir.Magnitude + over0 + over1, d), cf, color, "deco")
	end

	local UP = Vector3.new(0, 1, 0)
	local BACK = Vector3.new(0, 0, 1)

	-- 1. standing pad -------------------------------------------------------------
	local padFolder = folder("Pad")
	local half = PAD_WIDTH / 2
	local inner = half - PAD_CHAMFER
	block("PadSlabWide", "Pad", Vector3.new(PAD_WIDTH, PAD_HEIGHT, PAD_WIDTH - 2 * PAD_CHAMFER), CFrame.new(0, PAD_HEIGHT / 2, 0), PAD_STONE, "pad")
	block("PadSlabDeep", "Pad", Vector3.new(PAD_WIDTH - 2 * PAD_CHAMFER, PAD_HEIGHT, PAD_WIDTH), CFrame.new(0, PAD_HEIGHT / 2, 0), PAD_STONE, "pad")
	local cornerNames = { "PadCornerNE", "PadCornerNW", "PadCornerSE", "PadCornerSW" }
	local cornerSigns = { { 1, 1 }, { -1, 1 }, { 1, -1 }, { -1, -1 } }
	for i, s in ipairs(cornerSigns) do
		local sx, sz = s[1], s[2]
		local yMid = PAD_HEIGHT / 2
		tri(
			cornerNames[i],
			"Pad",
			Vector3.new(inner * sx, yMid, inner * sz),
			Vector3.new(half * sx, yMid, inner * sz),
			Vector3.new(inner * sx, yMid, half * sz),
			PAD_HEIGHT,
			PAD_STONE,
			"pad"
		)
	end

	-- NPC anchor: invisible, feet level on the pad, faces local -Z --------------------
	local anchor = block("NPCAnchor", "Anchor", ANCHOR_SIZE, CFrame.new(0, PAD_HEIGHT, 0), PAD_STONE, "anchor")
	anchor.Transparency = 1

	-- 2. arch ---------------------------------------------------------------------
	local function archSide(label: string, points: { { number } })
		for i = 1, #points - 1 do
			local p, q = points[i], points[i + 1]
			local over0 = if i == 1 then 0 else ARCH_JOINT_OVERLAP
			local color = if i == 1 then ROOT_DARK elseif i % 2 == 0 then ROOT_MID else ROOT_LIGHT
			beam(`Arch{label}{i}`, "Arch", Vector3.new(p[1], p[2], p[3]), Vector3.new(q[1], q[2], q[3]), p[4], p[5], BACK, over0, ARCH_JOINT_OVERLAP, color)
		end
	end
	archSide("R", ARCH_RIGHT)
	archSide("L", ARCH_LEFT)

	-- 3. roots -------------------------------------------------------------------
	for i, r in ipairs(ROOTS) do
		local zref = if r[9] == 1 then UP else BACK
		local color = if r[9] == 1 then ROOT_DARK else ROOT_MID
		beam(`Root{i}`, "Roots", Vector3.new(r[1], r[2], r[3]), Vector3.new(r[4], r[5], r[6]), r[7], r[8], zref, 0, 0.2, color)
	end
	for i, k in ipairs(ROOT_KNOTS) do
		block(`RootKnot{i}`, "Roots", Vector3.new(k[3], k[4], k[5]), CFrame.new(k[1], k[4] / 2, k[2]) * CFrame.Angles(0, math.rad(k[6]), 0), ROOT_DARK, "deco")
	end

	-- 4. leaf cards on the arch (each = body slab + one pointed wedge tip) -------------
	for i, l in ipairs(LEAVES) do
		local base = Vector3.new(l[1], l[2], l[3])
		local ang = math.rad(l[4])
		local len, wid, roll = l[5], l[6], math.rad(l[7])
		local d = Vector3.new(math.cos(ang), math.sin(ang), 0)
		local face = Vector3.new(0, 0, l[9]) -- the card faces forward (-Z) or backward (+Z)
		local s0 = d:Cross(face) -- in-plane, perpendicular to the leaf's length
		local n = (face * math.cos(roll) + s0 * math.sin(roll)).Unit
		local s = d:Cross(n)
		local thick = 0.35
		local bodyLen = len * 0.62
		local color = LEAF_COLOURS[l[8]]
		local bodyCF = CFrame.fromMatrix(base + d * (bodyLen * 0.5), s, d, n)
		block(`LeafCard{i}`, "Foliage", Vector3.new(wid, bodyLen, thick), bodyCF, color, "deco")
		local a = base + d * bodyLen - s * (wid * 0.5)
		tri(`LeafTip{i}`, "Foliage", a, a + d * (len - bodyLen), a + s * wid, thick, color, "deco")
	end

	-- 5. rear crescent: moss-capped rocks and leaf bushes --------------------------------
	for i, r in ipairs(ROCKS) do
		local th = math.rad(r[1])
		local size = Vector3.new(r[3], r[4], r[5])
		local cf = CFrame.new(r[2] * math.sin(th), size.Y / 2, r[2] * math.cos(th)) * CFrame.Angles(0, math.rad(r[6]), 0)
		block(`Rock{i}`, "Rocks", size, cf, if i % 2 == 0 then STONE_DARK else STONE, "deco")
		local capH = r[7]
		local capCF = cf * CFrame.new(0.15, size.Y / 2 + capH / 2 - 0.08, 0.1) * CFrame.Angles(0, 0.2, math.rad(5))
		block(`RockMoss{i}`, "Rocks", Vector3.new(size.X * 0.86, capH, size.Z * 0.86), capCF, MOSS, "deco")
	end
	for i, b in ipairs(BUSHES) do
		local th = math.rad(b[1])
		local size = Vector3.new(b[3], b[4], b[5])
		local cf = CFrame.new(b[2] * math.sin(th), size.Y / 2, b[2] * math.cos(th)) * CFrame.Angles(0, math.rad(b[6]), 0)
		block(`BushLow{i}`, "Foliage", size, cf, LEAF_DARK, "deco")
		local upCF = cf * CFrame.new(0.2, size.Y / 2 + 0.4, -0.1) * CFrame.Angles(0, 0.5, math.rad(-6))
		block(`BushTop{i}`, "Foliage", Vector3.new(size.X * 0.7, 0.9, size.Z * 0.72), upCF, if i % 2 == 0 then LEAF_LIGHT else LEAF_MID, "deco")
	end

	-- 6. Dewdrop lanterns ------------------------------------------------------------
	for i, l in ipairs(LANTERNS) do
		local start = Vector3.new(l[1], l[2], l[3])
		local hang = Vector3.new(l[4], l[5], l[6])
		beam(`LanternBranch{i}`, "Lanterns", start, hang, 0.7, 0.7, UP, 0, 0.35, ROOT_MID)
		local capY = hang.Y - 0.4
		block(`LanternCap{i}`, "Lanterns", Vector3.new(0.9, 0.3, 0.9), CFrame.new(hang.X, capY, hang.Z), ROOT_DARK, "deco")
		local ballY = capY - 0.15 - LANTERN_BALL / 2 + 0.1
		local drop = ball(`LanternDew{i}`, "Lanterns", LANTERN_BALL, Vector3.new(hang.X, ballY, hang.Z), MINT, "glow")
		ball(`LanternDewTip{i}`, "Lanterns", LANTERN_TIP, Vector3.new(hang.X, ballY - LANTERN_BALL / 2 - LANTERN_TIP / 2 + 0.15, hang.Z), MINT, "glow")
		if LANTERN_LIGHT then
			local light = Instance.new("PointLight")
			light.Name = "DewGlow"
			light.Color = MINT_LIGHT_COLOR
			light.Brightness = 0.9
			light.Range = 14
			light.Shadows = false
			light.Parent = drop
		end
	end
	ball("ArchGem", "Arch", APEX_GEM_SIZE, APEX_GEM, MINT, "glow")

	-- finish ------------------------------------------------------------------------
	model.PrimaryPart = anchor
	if parent then
		model.Parent = parent
	end
	return model
end

return MistSurroundModel
