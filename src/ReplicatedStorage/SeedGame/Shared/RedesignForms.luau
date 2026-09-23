--!strict
-- Steal a Seed :: RedesignForms  (PREVIEW ONLY -- five pod families, NOT approved)
--
-- Proposed appearances for the five biome pod families, from the concept
-- direction of 2026-09-22. On 2026-09-23 the owner did NOT approve them for
-- production; they stay here, isolated, for a later review.
--
-- NOTHING LIVE CALLS THIS, and no production module may require it.
-- CreatureModel builds every production pod. ArtRedesignMockupRunner is the one
-- caller, and it stands these beside the production pods for comparison.
--
-- The three Starbloom plants that shared the preview -- Novaorb, Cosmospire and
-- Astralhorn -- WERE approved that day and no longer live here: their builders
-- moved unchanged into StarbloomForms, which is the production path.
--
--   BuildPod(species, tier, cf, parent)   the CreatureModel.BuildPod signature:
--                                          `cf` is the BASE, `Shell` is the
--                                          PrimaryPart and the Tool handle, and
--                                          the model carries the same four
--                                          attributes -- so approving one family
--                                          later is a dispatch for that family,
--                                          not a rebuild.
--
--==============================================================================
-- THE THREE SIZES A POD IS JUDGED AGAINST
--
-- Everything below is written in units of D, the tier's PodDiameter, with the
-- base at y = 0. The production envelope this has to stay inside:
--
--   width      no wider than about 1.25 D (the shipped Dustbowl Colossal is
--              1.30 D and the haul clearance is D/2 + 0.4 off a guardian)
--   height     about 1.2 - 1.45 D (the shipped shells run 1.21 - 1.46 D)
--   floor      no part below the base; the runner measures the lowest corner
--   carry      GripForward is D/2 + 0.85, so the Shell must be the mass in the
--              middle of the pod, not a husk off to one side
--
-- Tier is read the way the shipped pods read it: the seam takes the tier colour
-- at every tier, Titan and Colossal tint the shell toward it, Titan wears the
-- vent trail and the aura, Colossal the burst core and the stronger aura, and
-- Colossal stamps PickupSound. Those are the tier's information and effect
-- responsibilities; the geometry under them is what changed.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SeedData = require(Shared:WaitForChild("SeedData"))

local RedesignForms = {}

RedesignForms.PodFamilies = { "greenhollow", "dustbowl", "tanglemire", "emberroot", "starbloom" }

--==============================================================================
-- THE VOCABULARY: the same four primitives, studded unless smooth or lit
--==============================================================================
local SURFACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}

type Opts = {
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	parent: Instance,
	shape: Enum.PartType?,
	wedge: boolean?,
	material: Enum.Material?,
	smooth: boolean?,
}

local function mk(o: Opts): BasePart
	local p: BasePart
	if o.wedge then
		p = Instance.new("WedgePart")
	else
		local b = Instance.new("Part")
		b.Shape = o.shape or Enum.PartType.Block
		p = b
	end
	p.Name = o.name
	p.Size = o.size
	p.CFrame = o.cf
	p.Color = o.color
	p.Material = o.material or Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	local face = if (o.smooth or o.material == Enum.Material.Neon)
		then Enum.SurfaceType.Smooth
		else Enum.SurfaceType.Studs
	for _, f in ipairs(SURFACES) do
		pcall(function()
			(p :: any)[f] = face
		end)
	end
	p.Parent = o.parent
	return p
end

local function rad(d: number): number
	return math.rad(d)
end

-- A tapered plate: (thick, length, width) yawed a quarter turn so the wedge's
-- taper runs across the WIDTH and the plate comes to a leaf tip. `mirror`
-- flips which side the tip leans to; pairs mirror or the set leans one way.
local function plate(name: string, w: number, len: number, thick: number, cf: CFrame,
	color: Color3, parent: Instance, mirror: boolean?, material: Enum.Material?): BasePart
	return mk({ name = name, size = Vector3.new(thick, len, w),
		cf = cf * CFrame.Angles(0, rad(90), 0)
			* (if mirror then CFrame.Angles(0, math.pi, 0) else CFrame.new()),
		color = color, parent = parent, wedge = true, material = material,
		smooth = material == Enum.Material.SmoothPlastic })
end

-- A flat slab facing along Z: a husk segment, a bark plate, a lid.
local function slab(name: string, w: number, len: number, thick: number, cf: CFrame,
	color: Color3, parent: Instance, material: Enum.Material?): BasePart
	return mk({ name = name, size = Vector3.new(w, len, thick), cf = cf,
		color = color, parent = parent, material = material,
		smooth = material == Enum.Material.SmoothPlastic })
end

local function ball(name: string, dia: number, cf: CFrame, color: Color3, parent: Instance,
	smooth: boolean?): BasePart
	return mk({ name = name, size = Vector3.new(dia, dia, dia), cf = cf, color = color,
		parent = parent, shape = Enum.PartType.Ball, smooth = smooth })
end

-- An upright cylinder: `height` along world Y.
local function drum(name: string, height: number, dia: number, cf: CFrame, color: Color3,
	parent: Instance, smooth: boolean?): BasePart
	return mk({ name = name, size = Vector3.new(height, dia, dia),
		cf = cf * CFrame.Angles(0, 0, rad(90)), color = color, parent = parent,
		shape = Enum.PartType.Cylinder, smooth = smooth })
end

-- A rod between two points, thick `dia`: a stalk segment, a root, a rib.
local function rod(name: string, from: Vector3, to: Vector3, dia: number, color: Color3,
	parent: Instance, smooth: boolean?): BasePart
	local len = (to - from).Magnitude
	local cf = CFrame.lookAt((from + to) * 0.5, to) * CFrame.Angles(0, rad(90), 0)
	return mk({ name = name, size = Vector3.new(len, dia, dia), cf = cf, color = color,
		parent = parent, shape = Enum.PartType.Cylinder, smooth = smooth })
end

-- A frame tangent to a circle of radius `r` about the pod's axis, at height `y`
-- and azimuth `az`: its -Z faces outward, +Y up. `pitch` > 0 leans the top in
-- toward the axis; `roll` turns it about its own outward normal.
local function around(cf: CFrame, az: number, y: number, r: number, pitch: number,
	roll: number): CFrame
	return cf * CFrame.Angles(0, rad(az), 0) * CFrame.new(0, y, -r)
		* CFrame.Angles(rad(pitch), 0, rad(roll))
end

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

--==============================================================================
-- POD TIER TREATMENT, SHARED BY THE FIVE FAMILIES
--
--   Tiny .. Huge      the clean closed shell, husks seated on the seed
--   Mega, Giant       husks stand `sep` further off the seed and the seam runs
--                     deeper, so the layering reads across a nest
--   Titan, Colossal   husks stand off again and an inner seam in the tier
--                     colour shows between them; the seed inside stays closed
--
-- The seam takes the tier colour at every tier, which is the tier's one fixed
-- home, exactly as on the shipped pods.
--==============================================================================
type PodCtx = {
	D: number,
	tier: number,
	tierColor: Color3,
	sep: number,
	seamDepth: number,
	inner: boolean,
	model: Model,
	cf: CFrame,
}

local function podContext(model: Model, cf: CFrame, tier: number): PodCtx
	local sep = if tier >= 6 then 0.075 elseif tier >= 4 then 0.035 else 0
	return {
		D = SeedData.PodDiameter(tier),
		tier = tier,
		tierColor = SeedData.ColorForTier(tier),
		sep = sep,
		seamDepth = if tier >= 6 then 1.8 elseif tier >= 4 then 1.35 else 1,
		inner = tier >= 6,
		model = model,
		cf = cf,
	}
end

--==============================================================================
-- THE EFFECTS ARE THE SHIPPED ONES, MOVED HERE UNCHANGED
--
-- Titan: a vent trail off the crown and the field aura on the shell. Colossal:
-- the burst core with its own light, the aura turned up and hung on the core.
-- Same emitter, same two strengths, same PickupSound stamp.
--==============================================================================
local function addAura(model: Model, host: BasePart, D: number, hue: Color3, tail: Color3,
	reach: number, rate: number, bright: number)
	local att = Instance.new("Attachment")
	att.Name = "AuraAttachment"
	att.Parent = host
	local halo = Instance.new("ParticleEmitter")
	halo.Name = "AuraPulse"
	halo.Color = ColorSequence.new(hue, tail)
	halo.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, D * 0.30 * reach),
		NumberSequenceKeypoint.new(1, D * 1.30 * reach),
	})
	halo.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.62),
		NumberSequenceKeypoint.new(1, 1),
	})
	halo.Lifetime = NumberRange.new(2.2, 2.6)
	halo.Rate = rate
	halo.Speed = NumberRange.new(0, 0)
	halo.LightEmission = 1
	halo.LightInfluence = 0
	halo.Parent = att
	local glow = Instance.new("PointLight")
	glow.Name = "AuraGlow"
	glow.Color = hue
	glow.Brightness = bright
	glow.Range = D * 2.0 * reach
	glow.Shadows = false
	glow.Parent = host
end

local function addVent(shell: BasePart, at: Vector3, D: number, color: Color3, focal: Color3)
	local att = Instance.new("Attachment")
	att.Name = "EmberVent"
	att.Position = shell.CFrame:PointToObjectSpace(at)
	att.Parent = shell
	local em = Instance.new("ParticleEmitter")
	em.Name = "EmberTrail"
	em.Color = ColorSequence.new(color, focal)
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, D * 0.05),
		NumberSequenceKeypoint.new(0.4, D * 0.11),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.9, 1.6)
	em.Rate = 7
	em.Speed = NumberRange.new(D * 0.10, D * 0.22)
	em.Acceleration = Vector3.new(0, D * 0.30, 0)
	em.SpreadAngle = Vector2.new(16, 16)
	em.LightEmission = 1
	em.LightInfluence = 0
	em.Parent = att
end

-- `crownY` is where the family's shell closes, in D above the base; the core
-- breaks through it by a quarter of a diameter, as the shipped Colossal's does.
local function tierEffects(ctx: PodCtx, shell: BasePart, crownY: number, accent: Color3,
	focal: Color3, coreColor: Color3, coreDia: number)
	local D, cf, model = ctx.D, ctx.cf, ctx.model
	if ctx.tier == 6 then
		addVent(shell, (cf * CFrame.new(0, D * (crownY + 0.03), 0)).Position, D, ctx.tierColor, focal)
		addAura(model, shell, D, ctx.tierColor, accent, 0.78, 0.8, 1.1)
	elseif ctx.tier == 7 then
		local core = ball("Core", D * coreDia,
			cf * CFrame.new(0, D * (crownY + 0.24 - coreDia * 0.5), 0), coreColor, model, true)
		core.Material = Enum.Material.Neon
		local glow = Instance.new("PointLight")
		glow.Name = "CoreGlow"
		glow.Color = coreColor
		glow.Brightness = 1.6
		glow.Range = D * 2.4
		glow.Shadows = false
		glow.Parent = core
		addAura(model, core, D, coreColor, accent, 1.0, 1.4, 2.2)
		model:SetAttribute("PickupSound", "ColossalPickup")
	end
end

local function tint(part: BasePart, tier: number, tierColor: Color3, weight: number)
	local mix = if tier == 7 then 0.55 elseif tier == 6 then 0.42 else 0
	if mix > 0 then
		part.Color = part.Color:Lerp(tierColor, mix * weight)
	end
end

--==============================================================================
-- GREENHOLLOW -- WRAPPED SPROUT
--
-- A plump, slightly leaning seed enclosed by three broad overlapping leaves.
-- Woody brown lower shell, fresh green husks with pale upper edges, one curled
-- shoot. The overlaps are the hatch seam; there is no belt.
--==============================================================================
local GH = {
	wood = rgb(118, 74, 42),
	woodDark = rgb(92, 58, 34),
	green = rgb(86, 150, 66),
	greenDeep = rgb(70, 128, 56),
	pale = rgb(176, 214, 128),
	cream = rgb(242, 238, 206),
	shoot = rgb(124, 182, 92),
}

local function podGreenhollow(ctx: PodCtx): (BasePart, number)
	local D, cf, m = ctx.D, ctx.cf, ctx.model
	local lean = CFrame.Angles(rad(-4), 0, rad(6))
	-- The seed: a fuller lower half in woody brown, a tapered upper half in the
	-- pale green the husk tips share, so the seam colour reads as the seed's own.
	local shell = ball("Shell", D * 0.80, cf * CFrame.new(0, D * 0.41, 0) * lean, GH.wood, m)
	local top = ball("ShellTop", D * 0.56, cf * CFrame.new(D * 0.02, D * 0.76, -D * 0.01) * lean,
		GH.pale, m)
	tint(shell, ctx.tier, ctx.tierColor, 1)
	tint(top, ctx.tier, ctx.tierColor, 0.62)

	-- Three husks, wrapped in one direction: each base leans in, each tip folds
	-- over the top and hangs past the next husk's edge. The third is the longest
	-- and the first the shortest, so the wrap has a beginning and an end.
	local r = D * (0.36 + ctx.sep)
	for i, h in ipairs({
		{ az = 10,  len = 0.62, tip = 0.34, roll = 9,  dark = false },
		{ az = 128, len = 0.66, tip = 0.38, roll = 7,  dark = true },
		{ az = 244, len = 0.72, tip = 0.44, roll = 11, dark = false },
	}) do
		local baseCF = around(cf, h.az, D * 0.30, r, 20, h.roll)
		-- A tapered plate, not a slab: face-on it is a leaf, and pitched 20
		-- degrees it hugs the seed instead of standing off it as a panel.
		local husk = plate("Husk" .. i, D * 0.58, D * h.len, D * 0.075,
			baseCF * CFrame.new(0, D * h.len * 0.5 - D * 0.10, 0),
			if h.dark then GH.greenDeep else GH.green, m, i == 2)
		tint(husk, ctx.tier, ctx.tierColor, 0.45)
		-- The tip hinges off the top of its base and folds inward over the seed.
		local hinge = baseCF * CFrame.new(0, D * h.len - D * 0.10, 0) * CFrame.Angles(rad(46), 0, 0)
		plate("HuskTip" .. i, D * 0.40, D * h.tip, D * 0.06,
			hinge * CFrame.new(D * 0.06, D * h.tip * 0.5, 0), GH.pale, m, i == 2)
	end

	-- The overlap seam: a cream edge along the leading husk's outer edge, and
	-- at the top tiers the inner seam between husks in the tier colour.
	-- Seam depth widens the edge and lengthens it a little upward; the husk it
	-- follows starts at 0.20 D, so the seam never runs under the shell.
	local seamLen = 0.56 * math.min(ctx.seamDepth, 1.25)
	local seamCF = around(cf, 70, D * (0.42 + (seamLen - 0.56) * 0.5), r + D * 0.045, 12, 0)
	slab("Seam", D * 0.05 * ctx.seamDepth, D * seamLen, D * 0.03, seamCF, ctx.tierColor, m,
		Enum.Material.SmoothPlastic)
	if ctx.inner then
		slab("SeamInner", D * 0.08, D * 0.30, D * 0.03, around(cf, 188, D * 0.52, r - D * 0.02, 14, 0),
			ctx.tierColor, m, Enum.Material.SmoothPlastic)
	end

	-- Woody seam detail on the underside, where the shell shows under the husks.
	drum("SeedFoot", D * 0.06, D * 0.46, cf * CFrame.new(0, D * 0.06, 0), GH.woodDark, m)

	-- One shoot, bending continuously: four short rods each turned on from the
	-- last, so it curls rather than kinks.
	local tipCF = cf * CFrame.new(D * 0.04, D * 0.98, -D * 0.02) * CFrame.Angles(rad(-8), 0, rad(-12))
	local step = D * 0.14
	local dia = D * 0.085
	for i = 1, 4 do
		local nextCF = tipCF * CFrame.new(0, step, 0) * CFrame.Angles(0, 0, rad(34))
		rod("Shoot" .. i, tipCF.Position, nextCF.Position, dia * (1 - (i - 1) * 0.14), GH.shoot, m)
		tipCF = nextCF
	end
	ball("ShootBud", D * 0.11, tipCF, GH.pale, m)

	return shell, 1.02
end

--==============================================================================
-- DUSTBOWL -- SUNBAKED SEED
--
-- A squat, angular desert seed with a thick cracked husk: broad irregular
-- sandstone plates over a dark terracotta core, deep gaps between them, two dry
-- leaf tips folded back against the crown. Low, weighty, no saucer.
--==============================================================================
local DB = {
	sand = rgb(196, 152, 96),
	sandLight = rgb(214, 176, 118),
	ochre = rgb(172, 120, 62),
	terracotta = rgb(128, 72, 46),
	crack = rgb(66, 44, 34),
	husk = rgb(226, 204, 160),
	leaf = rgb(150, 122, 70),
}

local function podDustbowl(ctx: PodCtx): (BasePart, number)
	local D, cf, m = ctx.D, ctx.cf, ctx.model
	-- The core is dark: the recessed cracks are the core showing through gaps.
	-- A round clod, not a barrel: the plates wrap a ball.
	local shell = ball("Shell", D * 0.82, cf * CFrame.new(0, D * 0.42, 0), DB.crack, m)
	local under = drum("ShellUnder", D * 0.20, D * 0.92, cf * CFrame.new(0, D * 0.11, 0),
		DB.terracotta, m)
	tint(shell, ctx.tier, ctx.tierColor, 0.5)
	tint(under, ctx.tier, ctx.tierColor, 1)

	-- Six broad plates of unequal height and lean, none at even spacing, with
	-- the gaps between them left open over the dark core. Every other one is a
	-- tapered plate, so the ring of them is not a ring of boxes, and all lean
	-- in at the top to follow the clod.
	local r = D * (0.43 + ctx.sep)
	for i, p in ipairs({
		{ az = 0,   y = 0.20, w = 0.46, len = 0.50, pitch = 19, roll = -6, c = DB.sand },
		{ az = 66,  y = 0.24, w = 0.36, len = 0.58, pitch = 24, roll = 5,  c = DB.ochre },
		{ az = 121, y = 0.18, w = 0.50, len = 0.46, pitch = 17, roll = -3, c = DB.sandLight },
		{ az = 190, y = 0.22, w = 0.40, len = 0.54, pitch = 22, roll = 8,  c = DB.sand },
		{ az = 248, y = 0.17, w = 0.44, len = 0.44, pitch = 16, roll = -8, c = DB.ochre },
		{ az = 306, y = 0.25, w = 0.38, len = 0.56, pitch = 25, roll = 4,  c = DB.sandLight },
	}) do
		local f = around(cf, p.az, D * p.y, r, p.pitch, p.roll)
		local at = f * CFrame.new(0, D * p.len * 0.5, 0)
		local husk = if i % 2 == 0
			then plate("HuskPlate" .. i, D * p.w, D * p.len, D * 0.09, at, p.c, m, i == 4)
			else slab("HuskPlate" .. i, D * p.w, D * p.len, D * 0.09, at, p.c, m)
		tint(husk, ctx.tier, ctx.tierColor, 0.45)
	end

	-- The crown: a low off-centre cap the plates close under, and two dry leaf
	-- tips folded back against it.
	slab("Cap", D * 0.44, D * 0.30, D * 0.09,
		cf * CFrame.new(-D * 0.05, D * 0.86, D * 0.03) * CFrame.Angles(rad(84), rad(20), 0),
		DB.sand, m)
	for i, l in ipairs({ { az = 40, len = 0.30, mirror = false }, { az = 215, len = 0.24, mirror = true } }) do
		local f = around(cf, l.az, D * 0.82, D * 0.16, -58, 0)
		plate("LeafTip" .. i, D * 0.16, D * l.len, D * 0.05, f * CFrame.new(0, D * l.len * 0.5, 0),
			DB.leaf, m, l.mirror)
	end

	-- Pale husk edges on two plates, and the seam: the deepest crack, in the tier
	-- colour, where two plates fail to meet.
	-- On the plates' outer faces (the plates lean in, so the edges lean with them).
	slab("HuskEdge1", D * 0.05, D * 0.40, D * 0.04, around(cf, 24, D * 0.24, r + D * 0.02, 19, 0),
		DB.husk, m, Enum.Material.SmoothPlastic)
	slab("HuskEdge2", D * 0.05, D * 0.34, D * 0.04, around(cf, 160, D * 0.22, r + D * 0.02, 20, 0),
		DB.husk, m, Enum.Material.SmoothPlastic)
	slab("Seam", D * 0.06, D * 0.42 * ctx.seamDepth, D * 0.035, around(cf, 96, D * 0.44, r - D * 0.03, 11, 0),
		ctx.tierColor, m, Enum.Material.SmoothPlastic)
	if ctx.inner then
		slab("SeamInner", D * 0.07, D * 0.28, D * 0.035, around(cf, 275, D * 0.46, r - D * 0.04, 10, 0),
			ctx.tierColor, m, Enum.Material.SmoothPlastic)
	end

	return shell, 0.90
end

--==============================================================================
-- TANGLEMIRE -- MIRE LANTERN
--
-- A drooping teardrop seed with an uneven shoulder, wrapped by a few thick
-- branching roots with real gaps, muted turquoise inner shell showing through
-- selected gaps, moss on one shoulder, one bent stalk.
--==============================================================================
local TM = {
	peat = rgb(46, 36, 30),
	peatLight = rgb(64, 50, 40),
	root = rgb(36, 82, 58),
	rootLight = rgb(58, 110, 74),
	moss = rgb(104, 140, 74),
	mossDeep = rgb(78, 112, 60),
	turquoise = rgb(96, 168, 156),
}

local function podTanglemire(ctx: PodCtx): (BasePart, number)
	local D, cf, m = ctx.D, ctx.cf, ctx.model
	-- The seed droops: the lower mass is full and set a little back, the
	-- shoulder is uneven, and the crown tapers up and over to one side.
	local shell = ball("Shell", D * 0.74, cf * CFrame.new(0, D * 0.38, D * 0.02), TM.peat, m)
	local shoulder = ball("ShellShoulder", D * 0.54,
		cf * CFrame.new(-D * 0.07, D * 0.68, -D * 0.03), TM.peatLight, m)
	tint(shell, ctx.tier, ctx.tierColor, 1)
	tint(shoulder, ctx.tier, ctx.tierColor, 0.62)
	for i, w in ipairs({ { x = -0.10, roll = 24, mirror = false }, { x = 0.06, roll = -18, mirror = true } }) do
		plate("Crown" .. i, D * 0.30, D * 0.40, D * 0.12,
			cf * CFrame.new(D * w.x, D * 0.96, 0) * CFrame.Angles(rad(6), rad(-20), rad(w.roll)),
			TM.peatLight, m, w.mirror)
	end

	-- Turquoise inner shell, showing only where the roots leave it uncovered.
	for i, t in ipairs({ { az = 52, y = 0.30, w = 0.16, len = 0.20 }, { az = 178, y = 0.40, w = 0.13, len = 0.16 },
		{ az = 300, y = 0.26, w = 0.12, len = 0.14 } }) do
		slab("InnerShell" .. i, D * t.w, D * t.len, D * 0.03,
			around(cf, t.az, D * t.y, D * 0.355, 6, 0), TM.turquoise, m, Enum.Material.SmoothPlastic)
	end

	-- Four roots, grown around the seed: each rises from the base up a flank and
	-- branches over the shoulder. Unequal reach and azimuth; none at even
	-- spacing, and the gaps between them are the point.
	local r = D * (0.39 + ctx.sep)
	for i, rt in ipairs({
		{ az = 20,  h = 0.58, branch = 0.30, lean = 34, dia = 0.11, light = false },
		{ az = 118, h = 0.50, branch = 0.24, lean = 28, dia = 0.095, light = true },
		{ az = 222, h = 0.66, branch = 0.34, lean = 40, dia = 0.12, light = false },
		{ az = 318, h = 0.44, branch = 0.20, lean = 22, dia = 0.09, light = true },
	}) do
		local foot = (cf * CFrame.Angles(0, rad(rt.az), 0) * CFrame.new(D * 0.03, D * rt.dia * 0.5, -r - D * 0.02)).Position
		local knee = (cf * CFrame.Angles(0, rad(rt.az + 8), 0) * CFrame.new(0, D * rt.h, -r)).Position
		local colour = if rt.light then TM.rootLight else TM.root
		rod("RootRise" .. i, foot, knee, D * rt.dia, colour, m)
		-- The branch turns in over the shoulder toward the crown.
		local over = (cf * CFrame.Angles(0, rad(rt.az + rt.lean), 0)
			* CFrame.new(0, D * (rt.h + rt.branch * 0.55), -(r - D * rt.branch * 0.8))).Position
		rod("RootBranch" .. i, knee, over, D * rt.dia * 0.72, colour, m)
	end

	-- Moss on the high shoulder only.
	ball("Moss1", D * 0.26, cf * CFrame.new(-D * 0.22, D * 0.80, -D * 0.10), TM.moss, m)
	ball("Moss2", D * 0.18, cf * CFrame.new(-D * 0.30, D * 0.66, D * 0.06), TM.mossDeep, m)

	-- One bent stalk off the crown, and the seam: the split under the crown, in
	-- the tier colour, with its inner run at the top tiers.
	local s0 = (cf * CFrame.new(D * 0.02, D * 1.06, 0)).Position
	local s1 = s0 + Vector3.new(D * 0.10, D * 0.16, -D * 0.04)
	local s2 = s1 + Vector3.new(D * 0.16, D * 0.06, -D * 0.06)
	rod("Stalk1", s0, s1, D * 0.06, TM.rootLight, m)
	rod("Stalk2", s1, s2, D * 0.045, TM.rootLight, m)
	slab("Seam", D * 0.06, D * 0.34 * ctx.seamDepth, D * 0.03,
		around(cf, 270, D * 0.62, D * 0.34, 16, -14), ctx.tierColor, m, Enum.Material.SmoothPlastic)
	if ctx.inner then
		slab("SeamInner", D * 0.07, D * 0.24, D * 0.03, around(cf, 78, D * 0.58, D * 0.33, 14, 10),
			ctx.tierColor, m, Enum.Material.SmoothPlastic)
	end

	return shell, 1.12
end

--==============================================================================
-- EMBERROOT -- CINDER HEART
--
-- A compressed volcanic seed in overlapping charcoal bark plates that curl in
-- near the crown, three major fissures showing a narrow orange inner surface,
-- a broad heavy lower body. Only the fissures are lit.
--==============================================================================
local ER = {
	char = rgb(54, 48, 50),
	ash = rgb(84, 76, 76),
	ashLight = rgb(112, 104, 100),
	redBrown = rgb(92, 46, 34),
	inner = rgb(120, 40, 22),
	fissure = rgb(255, 92, 12),
}

local function podEmberroot(ctx: PodCtx): (BasePart, number)
	local D, cf, m = ctx.D, ctx.cf, ctx.model
	-- The heavy lower body in dark reddish brown, and the inner seed the plates
	-- close over, which is what the fissures show.
	-- The lower body is charred too; only the inner seed is red, and only the
	-- fissures are lit.
	local shell = drum("Shell", D * 0.40, D * 0.84, cf * CFrame.new(0, D * 0.22, 0), rgb(60, 52, 52), m)
	local inner = ball("ShellInner", D * 0.70, cf * CFrame.new(0, D * 0.60, 0), ER.inner, m)
	tint(shell, ctx.tier, ctx.tierColor, 1)
	tint(inner, ctx.tier, ctx.tierColor, 0.5)

	-- Bark plates: seven, at unequal heights and leans, curling in toward the
	-- crown. They lean just enough to meet the inner seed's surface near their
	-- tops (any steeper and they vanish inside it). Three gaps are left
	-- deliberately -- the fissures go there.
	local r = D * (0.45 + ctx.sep)
	for i, p in ipairs({
		{ az = 0,   y = 0.10, w = 0.40, len = 0.62, pitch = 12, roll = -4, c = ER.char },
		{ az = 58,  y = 0.16, w = 0.30, len = 0.54, pitch = 15, roll = 6,  c = ER.ash },
		{ az = 104, y = 0.08, w = 0.42, len = 0.70, pitch = 13, roll = -7, c = ER.char },
		{ az = 168, y = 0.14, w = 0.34, len = 0.58, pitch = 16, roll = 5,  c = ER.ashLight },
		{ az = 214, y = 0.10, w = 0.38, len = 0.64, pitch = 11, roll = -5, c = ER.char },
		{ az = 268, y = 0.18, w = 0.28, len = 0.50, pitch = 17, roll = 8,  c = ER.ash },
		{ az = 316, y = 0.12, w = 0.40, len = 0.66, pitch = 14, roll = -6, c = ER.char },
	}) do
		local f = around(cf, p.az, D * p.y, r, p.pitch, p.roll)
		local at = f * CFrame.new(0, D * p.len * 0.5, 0)
		-- Every third plate tapers, so the bark is not seven boxes.
		local bark = if i % 3 == 0
			then plate("BarkPlate" .. i, D * p.w, D * p.len, D * 0.085, at, p.c, m, i == 6)
			else slab("BarkPlate" .. i, D * p.w, D * p.len, D * 0.085, at, p.c, m)
		tint(bark, ctx.tier, ctx.tierColor, 0.45)
	end
	-- The crown closes as a tight bud: two curled tips over the top.
	for i, t in ipairs({ { az = 30, mirror = false }, { az = 200, mirror = true } }) do
		local f = around(cf, t.az, D * 0.94, D * 0.12, 62, 0)
		plate("BudTip" .. i, D * 0.22, D * 0.26, D * 0.07, f * CFrame.new(0, D * 0.13, 0), ER.ash, m, t.mirror)
	end

	-- Three fissures, narrow and orange, each set in one of the gaps; the third
	-- is the seam and takes the tier colour at its foot.
	for i, g in ipairs({ { az = 82, y = 0.30, len = 0.42, roll = 10 }, { az = 190, y = 0.34, len = 0.36, roll = -12 },
		{ az = 292, y = 0.28, len = 0.46, roll = 8 } }) do
		local fis = slab("Fissure" .. i, D * 0.05, D * g.len, D * 0.03,
			around(cf, g.az, D * g.y + D * g.len * 0.5, D * 0.36, 8, g.roll), ER.fissure, m, Enum.Material.Neon)
		fis.Material = Enum.Material.Neon
	end
	-- Deeper seams grow upward from 0.09 D, clear of the base.
	slab("Seam", D * 0.06, D * 0.22 * ctx.seamDepth, D * 0.03,
		around(cf, 292, D * (0.09 + 0.11 * ctx.seamDepth), D * 0.44, 4, 8), ctx.tierColor, m,
		Enum.Material.SmoothPlastic)
	if ctx.inner then
		slab("SeamInner", D * 0.07, D * 0.24, D * 0.03, around(cf, 140, D * 0.62, D * 0.36, 20, 0),
			ctx.tierColor, m, Enum.Material.SmoothPlastic)
	end

	return shell, 0.96
end

--==============================================================================
-- STARBLOOM -- ECLIPSE SEED
--
-- A tilted, faceted, slightly elongated seed enclosed by three sweeping
-- crescent husks, one raised above the other two, a narrow cyan seam between
-- selected overlaps. No orbiting debris.
--==============================================================================
local SB = {
	indigo = rgb(36, 32, 78),
	indigoDeep = rgb(26, 22, 58),
	violet = rgb(104, 72, 176),
	violetDeep = rgb(80, 54, 140),
	lavender = rgb(196, 178, 240),
	cyan = rgb(120, 232, 255),
}

local function podStarbloom(ctx: PodCtx): (BasePart, number)
	local D, cf, m = ctx.D, ctx.cf, ctx.model
	-- The whole bud is tilted, about a point up the seed so nothing dips below
	-- the base; the runner measures the lowest corner.
	local tiltCF = cf * CFrame.new(0, D * 0.40, 0) * CFrame.Angles(rad(10), rad(-12), rad(-9))
		* CFrame.new(0, -D * 0.40, 0)
	-- An elongated seed: a full lower ball and a narrower upper one, the whole
	-- thing tilted, so the eclipse reads as a dark moon and not a crate.
	local shell = ball("Shell", D * 0.62, tiltCF * CFrame.new(0, D * 0.38, 0), SB.indigo, m)
	local top = ball("ShellTop", D * 0.46, tiltCF * CFrame.new(D * 0.02, D * 0.70, -D * 0.02),
		SB.indigoDeep, m)
	tint(shell, ctx.tier, ctx.tierColor, 1)
	tint(top, ctx.tier, ctx.tierColor, 0.62)

	-- Three crescent husks, each a tapered plate sweeping up and a fold over;
	-- the second stands highest. Pale lavender inner edge on every husk.
	local r = D * (0.36 + ctx.sep)
	for i, h in ipairs({
		{ az = 0,   y = 0.14, len = 0.62, over = 0.36, w = 0.40, pitch = 16, roll = 12, c = SB.violet },
		{ az = 125, y = 0.10, len = 0.80, over = 0.44, w = 0.46, pitch = 12, roll = -9, c = SB.violetDeep },
		{ az = 240, y = 0.18, len = 0.56, over = 0.32, w = 0.36, pitch = 19, roll = 14, c = SB.violet },
	}) do
		local f = around(tiltCF, h.az, D * h.y, r, h.pitch, h.roll)
		local crescent = plate("Crescent" .. i, D * h.w, D * h.len, D * 0.075,
			f * CFrame.new(0, D * h.len * 0.5, 0), h.c, m, i ~= 2)
		tint(crescent, ctx.tier, ctx.tierColor, 0.45)
		local hinge = f * CFrame.new(0, D * h.len, 0) * CFrame.Angles(rad(52), 0, 0)
		plate("CrescentOver" .. i, D * h.w * 0.72, D * h.over, D * 0.06,
			hinge * CFrame.new(D * 0.04, D * h.over * 0.5, 0), h.c, m, i == 2)
		slab("InnerEdge" .. i, D * 0.045, D * h.len * 0.82, D * 0.03,
			f * CFrame.new(-D * h.w * 0.46, D * h.len * 0.48, D * 0.02), SB.lavender, m,
			Enum.Material.SmoothPlastic)
	end

	-- The cyan seam between the raised husk and the next, and the seam proper in
	-- the tier colour on the far side.
	local cyanSeam = slab("SeamCyan", D * 0.035, D * 0.44, D * 0.03,
		around(tiltCF, 184, D * 0.42, r - D * 0.01, 5, 0), SB.cyan, m, Enum.Material.Neon)
	cyanSeam.Material = Enum.Material.Neon
	slab("Seam", D * 0.05, D * 0.40 * ctx.seamDepth, D * 0.03,
		around(tiltCF, 62, D * 0.38, r - D * 0.005, 6, 0), ctx.tierColor, m, Enum.Material.SmoothPlastic)
	if ctx.inner then
		slab("SeamInner", D * 0.06, D * 0.26, D * 0.03, around(tiltCF, 300, D * 0.52, r - D * 0.03, 8, 0),
			ctx.tierColor, m, Enum.Material.SmoothPlastic)
	end

	return shell, 1.06
end

local POD_BUILDERS: { [string]: (PodCtx) -> (BasePart, number) } = {
	greenhollow = podGreenhollow,
	dustbowl = podDustbowl,
	tanglemire = podTanglemire,
	emberroot = podEmberroot,
	starbloom = podStarbloom,
}

-- Per family: the accent and focal the effects read, and the Colossal core.
local POD_EFFECT_PALETTE = {
	greenhollow = { accent = rgb(104, 158, 62), focal = rgb(242, 238, 206), core = rgb(255, 240, 190), coreDia = 0.56 },
	dustbowl = { accent = rgb(191, 119, 65), focal = rgb(242, 178, 91), core = rgb(255, 210, 145), coreDia = 0.52 },
	tanglemire = { accent = rgb(65, 126, 89), focal = rgb(126, 236, 222), core = rgb(158, 255, 223), coreDia = 0.50 },
	emberroot = { accent = rgb(108, 50, 34), focal = rgb(255, 92, 12), core = rgb(255, 174, 92), coreDia = 0.54 },
	starbloom = { accent = rgb(91, 70, 164), focal = rgb(120, 232, 255), core = rgb(222, 210, 255), coreDia = 0.48 },
}

--==============================================================================
-- BUILD A POD -- the CreatureModel.BuildPod contract
--==============================================================================
function RedesignForms.BuildPod(sp: SeedData.Species, tier: number, cf: CFrame, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Pod_" .. sp.Id
	model:SetAttribute("SpeciesId", sp.Id)
	model:SetAttribute("Rarity", sp.Rarity)
	model:SetAttribute("Tier", tier)
	model:SetAttribute("Stage", 1)
	model:SetAttribute("Redesign", true)
	model.Parent = parent

	local build = POD_BUILDERS[sp.Biome]
	local ctx = podContext(model, cf, tier)
	local shell: BasePart
	local crownY = 1
	if build then
		shell, crownY = build(ctx)
	else
		shell = ball("Shell", ctx.D, cf * CFrame.new(0, ctx.D * 0.5, 0), ctx.tierColor, model)
	end
	local fx = POD_EFFECT_PALETTE[sp.Biome]
	if fx then
		tierEffects(ctx, shell, crownY, fx.accent, fx.focal, fx.core, fx.coreDia)
	end
	model.PrimaryPart = shell
	return model
end

return RedesignForms
