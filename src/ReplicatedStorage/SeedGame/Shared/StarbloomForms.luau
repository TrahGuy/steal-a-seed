--!strict
--==============================================================================
-- STARBLOOM FORMS (BIOME 5) -- 80% CREATURE / 20% PLANT
--
-- Rebuilt as true living alien cosmic creatures with articulated walking limbs,
-- creature anatomies (bipeds, stilt striders, prowling quadrupeds, behemoths,
-- and hexapod dragon titans), bioluminescent alien leaves, and NO static slabs!
--
-- Species:
--   1. Novaorb     (Rare)       - 4.60 studs - Rotund alien toad-biped with shoulder leaf fronds & orbiting motes
--   2. Cosmospire  (Rare)       - 7.40 studs - Tall 4-legged stilt mantis with dorsal spire & crystal leaf wings
--   3. Voidpetal   (Epic)       - 5.60 studs - Prowling void panther predator with 6-petal orchid neck mane & leaf tails
--   4. Astralhorn  (Legendary)  - 6.90 studs - Heavy 4-legged armored stag-beast with spine fronds & crystal antlers
--   5. Supernovus  (Mythic)     - 8.20 studs - Hexapod cosmic dragon titan with dorsal galaxy lotus, alien leaves & orbital ring
--==============================================================================

local StarbloomForms = {}

StarbloomForms.AuthoredHeight = {
	novaorb    = 4.60,
	cosmospire = 7.40,
	voidpetal  = 5.60,
	astralhorn = 6.90,
	supernovus = 8.20,
}

--==============================================================================
-- ONE PART, MOVED OUT AND SIZED UP
--
-- `s` is the height scale and applies to all three axes. `gs` is GIRTH, and it
-- is horizontal only -- see the banner on CreatureModel.BuildCreature: two
-- thirds of the approved parts are rotated off-axis, and scaling a rotated box
-- along world X and Z does not widen it, it SHEARS it. So girth never touches a
-- part's SIZE here. It spreads the parts apart and leaves every one of them at
-- its approved proportions, which is the same restraint Tanglemire's replayPart
-- already works under.
--
-- The rotation rides through untouched: `c - p` is the orientation with the
-- translation subtracted out.
--==============================================================================
local function scaled(c: CFrame, s: number, gs: number): CFrame
	local p = c.Position
	return CFrame.new(p.X * s * gs, p.Y * s, p.Z * s * gs) * (c - p)
end

local function scaleSequence(seq: NumberSequence, s: number): NumberSequence
	local pts = {}
	for _, k in ipairs(seq.Keypoints) do
		table.insert(pts, NumberSequenceKeypoint.new(k.Time, k.Value * s, k.Envelope * s))
	end
	return NumberSequence.new(pts)
end

local C = {
	VoidBlack     = Color3.fromRGB(14, 10, 24),
	MidnightSlate = Color3.fromRGB(24, 18, 46),
	Indigo        = Color3.fromRGB(39, 37, 82),
	AmethystDark  = Color3.fromRGB(48, 30, 78),
	Amethyst      = Color3.fromRGB(90, 50, 160),
	AmethystPale  = Color3.fromRGB(158, 128, 255),
	NebulaCyan    = Color3.fromRGB(110, 230, 255),
	NebulaCyanGlow= Color3.fromRGB(180, 245, 255),
	StarIvory     = Color3.fromRGB(242, 238, 255),
	PulsarGold    = Color3.fromRGB(255, 225, 120),
	CoreWhite     = Color3.fromRGB(255, 255, 255),
}

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

--==============================================================================
-- AN ALIEN LEAF, AND ITS VEIN, AND BOTH ARE NAMED "Leaf"
--
-- Not decoration: PlantSway swings every DIRECT CHILD named exactly "Leaf" as
-- an arm while a plant walks, and works out which side each is on from its own
-- X offset. Under any other name they simply never move -- which is what
-- "AlienLeaf" and "LeafVein" bought, and it is the same trap Suncrown fell into
-- when its four were called SupportLeaf1-4.
--
-- The vein takes the name too. It sits a fraction of a stud off the blade on the
-- blade's own axis, so the two swing about near-identical centres and stay
-- together; leaving it behind would peel the vein off the leaf on every step.
--==============================================================================
local function mkAlienLeaf(parent: Instance, cf: CFrame, size: Vector3, leafColor: Color3, veinColor: Color3)
	-- Main leaf blade
	mk({
		name = "Leaf",
		size = size,
		cf = cf,
		color = leafColor,
		parent = parent,
		wedge = true,
	})
	-- Neon vein rib
	mk({
		name = "Leaf",
		size = Vector3.new(size.X * 0.22, size.Y * 0.95, size.Z * 0.25),
		cf = cf * CFrame.new(0, 0, size.Z * 0.3),
		color = veinColor,
		parent = parent,
		material = Enum.Material.Neon,
	})
end

--==============================================================================
-- 1. NOVAORB (Rare, 4.60 studs) -- Rotund Alien Toad-Biped with Alien Fronds
--==============================================================================
local function buildNovaorb(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Novaorb"
	m.Parent = parent

	--== LIMBS: 2 Muscular Biped Legs + 1 Rear Stabilizer Tail Claws ==--
	for side = -1, 1, 2 do
		-- Upper Thigh
		local thighCF = baseCF * CFrame.new(side * 0.85, 1.2, -0.1) * CFrame.Angles(rad(-18), rad(side * 15), rad(side * 12))
		mk({ name = "Thigh", size = Vector3.new(0.65, 1.2, 0.75), cf = thighCF,
			color = C.MidnightSlate, parent = m })
		-- Lower Shin / Knee
		local shinCF = thighCF * CFrame.new(0, -0.65, 0.2) * CFrame.Angles(rad(35), 0, 0)
		mk({ name = "Shin", size = Vector3.new(0.55, 0.9, 0.55), cf = shinCF,
			color = C.AmethystDark, parent = m })
		-- Foot Claw (Ground level Y = 0.2)
		local footCF = baseCF * CFrame.new(side * 0.95, 0.2, -0.6) * CFrame.Angles(0, rad(side * 10), 0)
		mk({ name = "FootClaw", size = Vector3.new(0.7, 0.4, 0.9), cf = footCF,
			color = C.VoidBlack, parent = m, wedge = true })
		-- Claw Toes (Neon)
		mk({ name = "ClawGlow", size = Vector3.new(0.18, 0.2, 0.3), cf = footCF * CFrame.new(0, 0, -0.45),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	-- Rear Tail Leg / Balance Claws
	local tailCF = baseCF * CFrame.new(0, 0.4, 0.9) * CFrame.Angles(rad(25), 0, 0)
	mk({ name = "TailLimb", size = Vector3.new(0.65, 0.8, 0.8), cf = tailCF,
		color = C.VoidBlack, parent = m })

	--== CREATURE TORSO & HEAD (80%) ==--
	local bodyCF = baseCF * CFrame.new(0, 2.1, 0)
	mk({ name = "Torso", size = Vector3.new(2.3, 2.1, 2.2), cf = bodyCF,
		color = C.MidnightSlate, parent = m, shape = Enum.PartType.Ball })

	-- Glowing Belly Seam
	mk({ name = "BellyPlate", size = Vector3.new(1.4, 1.4, 0.3), cf = bodyCF * CFrame.new(0, -0.3, -0.95) * CFrame.Angles(rad(15), 0, 0),
		color = C.Indigo, parent = m })
	mk({ name = "BellyGlow", size = Vector3.new(0.8, 0.8, 0.1), cf = bodyCF * CFrame.new(0, -0.3, -1.05) * CFrame.Angles(rad(15), 0, 0),
		color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })

	-- Alien Face: Predatory Brow & Visor Eye
	local faceCF = bodyCF * CFrame.new(0, 0.3, -0.85)
	mk({ name = "BrowRidge", size = Vector3.new(1.8, 0.45, 0.7), cf = faceCF * CFrame.new(0, 0.4, 0),
		color = C.AmethystDark, parent = m })

	-- Twin Cyan Alien Eyes
	for side = -1, 1, 2 do
		local eyeCF = faceCF * CFrame.new(side * 0.45, 0.1, -0.2)
		mk({ name = "AlienEye", size = Vector3.new(0.35, 0.35, 0.3), cf = eyeCF,
			color = C.NebulaCyan, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
		mk({ name = "EyeGlint", size = Vector3.new(0.12, 0.12, 0.1), cf = eyeCF * CFrame.new(-0.06, 0.08, -0.12),
			color = C.CoreWhite, parent = m, material = Enum.Material.Neon })
	end

	-- Wide Lower Jaw
	mk({ name = "AlienJaw", size = Vector3.new(1.6, 0.5, 1.2), cf = faceCF * CFrame.new(0, -0.4, 0.1) * CFrame.Angles(rad(-10), 0, 0),
		color = C.VoidBlack, parent = m })

	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyan
	light.Brightness = 1.2
	light.Range = 8
	light.Parent = m:FindFirstChild("Torso") or m

	--== ALIEN LEAVES & PLANT TRAITS (20%) ==--
	-- 2 Sweeping Shoulder Leaf Fronds
	for side = -1, 1, 2 do
		local leafCF = bodyCF * CFrame.new(side * 1.1, 0.8, 0.2) * CFrame.Angles(rad(-20), rad(side * 40), rad(side * 35))
		mkAlienLeaf(m, leafCF, Vector3.new(0.55, 1.6, 0.25), C.AmethystPale, C.NebulaCyan)
	end

	-- Sprouting Head Calyx & Crown Petal
	local crownCF = bodyCF * CFrame.new(0, 1.2, 0)
	mk({ name = "HeadCalyx", size = Vector3.new(0.8, 0.4, 0.8), cf = crownCF,
		color = C.AmethystDark, parent = m, shape = Enum.PartType.Cylinder })
	for i = 1, 3 do
		local a = rad(i * 120 + 30)
		local pCF = crownCF * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.35, 0.35) * CFrame.Angles(rad(35), 0, 0)
		-- "Leaf", so PlantSway swings it. See mkAlienLeaf.
		mk({ name = "Leaf", size = Vector3.new(0.35, 0.8, 0.2), cf = pCF,
			color = C.AmethystPale, parent = m, wedge = true })
	end

	-- 4 Orbiting Stardust Motes
	for i = 1, 4 do
		local a = rad(i * 90 + 20)
		local moteCF = crownCF * CFrame.Angles(rad(15), a, 0) * CFrame.new(0, 0, 1.6)
		mk({ name = "Mote", size = Vector3.new(0.32, 0.32, 0.32), cf = moteCF,
			color = C.StarIvory, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	end

	-- Crown Particle Emitter
	local att = Instance.new("Attachment")
	att.Name = "MoteSpark"
	att.Position = Vector3.new(0, 0.3, 0)
	att.Parent = m:FindFirstChild("HeadCalyx") or m
	local p = Instance.new("ParticleEmitter")
	p.Name = "Stardust"
	p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	p.Color = ColorSequence.new(C.NebulaCyan, C.StarIvory)
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.Transparency = NumberSequence.new(0.2, 1)
	p.Lifetime = NumberRange.new(0.8, 1.6)
	p.Rate = 12
	p.Speed = NumberRange.new(0.6, 1.4)
	p.SpreadAngle = Vector2.new(180, 180)
	p.LightEmission = 1
	p.LightInfluence = 0
	p.Parent = att

	return m
end

--==============================================================================
-- 2. COSMOSPIRE (Rare, 7.40 studs) -- Tall 4-Legged Stilt Mantis / Strider
--==============================================================================
local function buildCosmospire(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Cosmospire"
	m.Parent = parent

	--== LIMBS: 4 Articulated Stilt Legs (Standing tall with zero slab) ==--
	for _, legSpec in ipairs({
		{ side = -1, fore =  1, x = -0.7, z = -0.5, pitch = rad(-18), roll = rad(-15) },
		{ side =  1, fore =  1, x =  0.7, z = -0.5, pitch = rad(-18), roll = rad( 15) },
		{ side = -1, fore = -1, x = -0.7, z =  0.6, pitch = rad( 20), roll = rad(-15) },
		{ side =  1, fore = -1, x =  0.7, z =  0.6, pitch = rad( 20), roll = rad( 15) },
	}) do
		-- Upper Femur
		local femurCF = baseCF * CFrame.new(legSpec.x, 2.3, legSpec.z) * CFrame.Angles(legSpec.pitch, 0, legSpec.roll)
		mk({ name = "Femur", size = Vector3.new(0.45, 1.9, 0.45), cf = femurCF,
			color = C.MidnightSlate, parent = m })
		-- Knee Joint
		mk({ name = "KneeJoint", size = Vector3.new(0.48, 0.48, 0.48), cf = femurCF * CFrame.new(0, -0.95, 0),
			color = C.AmethystDark, parent = m })
		-- Lower Tibia Stilt
		local tibiaCF = femurCF * CFrame.new(0, -1.8, 0) * CFrame.Angles(rad(-legSpec.fore * 28), 0, 0)
		mk({ name = "Tibia", size = Vector3.new(0.38, 2.0, 0.38), cf = tibiaCF,
			color = C.Indigo, parent = m })
		-- Sharp Obsidian Claw (Ground level Y = 0.2)
		local clawCF = baseCF * CFrame.new(legSpec.x * 1.6, 0.2, legSpec.z * 1.5)
		mk({ name = "StiltClaw", size = Vector3.new(0.5, 0.4, 0.6), cf = clawCF,
			color = C.VoidBlack, parent = m, wedge = true })
		mk({ name = "ClawSpike", size = Vector3.new(0.16, 0.2, 0.2), cf = clawCF * CFrame.new(0, 0, -0.3),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	--== CREATURE BODY & RAPTOR HEAD (80%) ==--
	local thoraxCF = baseCF * CFrame.new(0, 3.2, 0) * CFrame.Angles(rad(-10), 0, 0)
	mk({ name = "Thorax", size = Vector3.new(1.6, 1.8, 1.8), cf = thoraxCF,
		color = C.MidnightSlate, parent = m })
	mk({ name = "Abdomen", size = Vector3.new(1.2, 1.5, 1.4), cf = thoraxCF * CFrame.new(0, -0.4, 1.1) * CFrame.Angles(rad(25), 0, 0),
		color = C.VoidBlack, parent = m })

	-- Arched Mantis Neck & Raptor Skull
	local neckCF = thoraxCF * CFrame.new(0, 1.1, -0.7) * CFrame.Angles(rad(-22), 0, 0)
	mk({ name = "Neck", size = Vector3.new(0.7, 1.2, 0.7), cf = neckCF,
		color = C.AmethystDark, parent = m })

	local headCF = neckCF * CFrame.new(0, 0.8, -0.3) * CFrame.Angles(rad(15), 0, 0)
	mk({ name = "AlienSkull", size = Vector3.new(1.2, 0.9, 1.4), cf = headCF,
		color = C.MidnightSlate, parent = m })
	mk({ name = "Mandibles", size = Vector3.new(0.9, 0.4, 0.6), cf = headCF * CFrame.new(0, -0.45, -0.4) * CFrame.Angles(rad(15), 0, 0),
		color = C.VoidBlack, parent = m, wedge = true })

	-- Glowing Cyan Alien Eye Slits
	for side = -1, 1, 2 do
		mk({ name = "AlienEyeSlit", size = Vector3.new(0.18, 0.35, 0.6), cf = headCF * CFrame.new(side * 0.55, 0.1, -0.2) * CFrame.Angles(0, rad(side * 20), 0),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	-- Towering Dorsal Carapace Needle Spire
	local spireCF = thoraxCF * CFrame.new(0, 2.4, 0.1) * CFrame.Angles(rad(8), 0, 0)
	mk({ name = "DorsalNeedle", size = Vector3.new(0.6, 2.8, 0.6), cf = spireCF,
		color = C.AmethystPale, parent = m, shape = Enum.PartType.Cylinder })
	local crownTip = mk({ name = "QuasarTip", size = Vector3.new(0.5, 0.7, 0.5), cf = baseCF * CFrame.new(0, 7.3, 0),
		color = C.StarIvory, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })

	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyanGlow
	light.Brightness = 1.6
	light.Range = 10
	light.Parent = crownTip

	--== ALIEN LEAVES & CAPACITORS (20%) ==--
	-- 4 Multi-tiered Crystal Alien Leaves sprouting off the back
	for _, lSpec in ipairs({
		{ side = -1, y = 3.6, pitch = rad(-15), roll = rad(-35) },
		{ side =  1, y = 3.6, pitch = rad(-15), roll = rad( 35) },
		{ side = -1, y = 4.8, pitch = rad(-25), roll = rad(-45) },
		{ side =  1, y = 4.8, pitch = rad(-25), roll = rad( 45) },
	}) do
		local lCF = baseCF * CFrame.new(lSpec.side * 0.6, lSpec.y, 0.2) * CFrame.Angles(lSpec.pitch, 0, lSpec.roll)
		mkAlienLeaf(m, lCF, Vector3.new(0.45, 1.8, 0.22), C.AmethystPale, C.NebulaCyan)
	end

	-- 4 Floating Diamond Capacitor Nodes
	for i = 1, 4 do
		local a = rad(i * 90)
		local nodeCF = baseCF * CFrame.new(0, 4.2, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 1.35) * CFrame.Angles(rad(45), rad(45), 0)
		mk({ name = "CapacitorNode", size = Vector3.new(0.38, 0.38, 0.38), cf = nodeCF,
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	-- Rising Quasar Spark Stream
	local att = Instance.new("Attachment")
	att.Name = "QuasarBeam"
	att.Position = Vector3.new(0, 0.4, 0)
	att.Parent = crownTip
	local p = Instance.new("ParticleEmitter")
	p.Name = "QuasarMotes"
	p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	p.Color = ColorSequence.new(C.StarIvory, C.NebulaCyan)
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.Transparency = NumberSequence.new(0.1, 1)
	p.Lifetime = NumberRange.new(1.0, 2.0)
	p.Rate = 14
	p.Speed = NumberRange.new(1.2, 2.8)
	p.EmissionDirection = Enum.NormalId.Top
	p.SpreadAngle = Vector2.new(20, 20)
	p.LightEmission = 1
	p.LightInfluence = 0
	p.Parent = att

	return m
end

--==============================================================================
-- 3. VOIDPETAL (Epic, 5.60 studs) -- Prowling Void Panther with 6-Petal Orchid Mane
--==============================================================================
local function buildVoidpetal(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Voidpetal"
	m.Parent = parent

	--== LIMBS: 4 Articulated Prowling Predator Legs ==--
	for _, leg in ipairs({
		{ name = "FL", x = -0.85, z = -1.1, pitch = rad(-15), roll = rad(-10) },
		{ name = "FR", x =  0.85, z = -1.1, pitch = rad(-15), roll = rad( 10) },
		{ name = "BL", x = -0.95, z =  1.1, pitch = rad( 22), roll = rad(-12) },
		{ name = "BR", x =  0.95, z =  1.1, pitch = rad( 22), roll = rad( 12) },
	}) do
		-- Haunch / Upper Leg
		local haunchCF = baseCF * CFrame.new(leg.x, 1.4, leg.z) * CFrame.Angles(leg.pitch, 0, leg.roll)
		mk({ name = leg.name .. "_Haunch", size = Vector3.new(0.65, 1.2, 0.75), cf = haunchCF,
			color = C.MidnightSlate, parent = m })
		-- Shin / Hock
		local shinCF = haunchCF * CFrame.new(0, -0.65, 0.15) * CFrame.Angles(rad(-leg.pitch * 1.5), 0, 0)
		mk({ name = leg.name .. "_Shin", size = Vector3.new(0.5, 0.9, 0.5), cf = shinCF,
			color = C.AmethystDark, parent = m })
		-- Paw Claws (Y = 0.2)
		local pawCF = baseCF * CFrame.new(leg.x * 1.1, 0.2, leg.z + (if leg.z < 0 then -0.3 else 0.2))
		mk({ name = leg.name .. "_Paw", size = Vector3.new(0.6, 0.38, 0.75), cf = pawCF,
			color = C.VoidBlack, parent = m })
		mk({ name = leg.name .. "_ClawNeon", size = Vector3.new(0.35, 0.15, 0.2), cf = pawCF * CFrame.new(0, -0.05, -0.35),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	--== CREATURE BODY (80%): Slinking Predator Torso & Head ==--
	local spineCF = baseCF * CFrame.new(0, 2.2, 0) * CFrame.Angles(rad(-6), 0, 0)
	mk({ name = "SpineTorso", size = Vector3.new(1.8, 1.7, 2.8), cf = spineCF,
		color = C.MidnightSlate, parent = m })
	mk({ name = "SpineRidge", size = Vector3.new(0.35, 0.4, 2.6), cf = spineCF * CFrame.new(0, 0.95, 0),
		color = C.AmethystDark, parent = m, wedge = true })

	-- Beast Skull & Jaws
	local headCF = baseCF * CFrame.new(0, 2.5, -1.8) * CFrame.Angles(rad(8), 0, 0)
	mk({ name = "PantherSkull", size = Vector3.new(1.5, 1.2, 1.6), cf = headCF,
		color = C.MidnightSlate, parent = m })
	mk({ name = "SnoutJaw", size = Vector3.new(1.1, 0.55, 1.1), cf = headCF * CFrame.new(0, -0.4, -0.6) * CFrame.Angles(rad(12), 0, 0),
		color = C.VoidBlack, parent = m })

	-- Glowing Cyan Maw Core Inside Mouth
	local mouthHeart = mk({ name = "MawHeart", size = Vector3.new(0.65, 0.65, 0.65), cf = headCF * CFrame.new(0, -0.2, -0.4),
		color = C.NebulaCyan, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyan
	light.Brightness = 1.6
	light.Range = 9
	light.Parent = mouthHeart

	-- 4 Glowing Predator Eyes
	for _, eyePos in ipairs({
		{ -0.5, 0.25, -0.7 },
		{  0.5, 0.25, -0.7 },
		{ -0.3, -0.05, -0.78 },
		{  0.3, -0.05, -0.78 },
	}) do
		mk({ name = "PredatorEye", size = Vector3.new(0.2, 0.2, 0.2), cf = headCF * CFrame.new(eyePos[1], eyePos[2], eyePos[3]),
			color = C.NebulaCyan, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	end

	--== ALIEN LEAVES & PLANT TRAITS (20%): 6-Petal Orchid Mane & Leaf Tails ==--
	-- 6-Petal Flaring Orchid Neck Mane
	local maneCF = headCF * CFrame.new(0, 0.1, 0.7)
	for i = 1, 6 do
		local a = rad(i * 60)
		local petalColor = if i % 2 == 0 then C.AmethystPale else C.MidnightSlate
		local pCF = maneCF * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.4, 0) * CFrame.Angles(rad(28), 0, 0)
		mkAlienLeaf(m, pCF, Vector3.new(0.65, 1.8, 0.2), petalColor, C.NebulaCyan)
	end

	-- 3 Golden Stamen Whiskers
	for i = 1, 3 do
		local a = rad(i * 120 + 30)
		local stamenCF = maneCF * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.8, -0.2) * CFrame.Angles(rad(15), 0, 0)
		mk({ name = "StamenWhisker", size = Vector3.new(0.2, 0.8, 0.2), cf = stamenCF,
			color = C.PulsarGold, parent = m, material = Enum.Material.Neon })
	end

	-- Twin Curled Alien Leaf Tails
	for side = -1, 1, 2 do
		local tailCF = baseCF * CFrame.new(side * 0.4, 2.5, 1.6) * CFrame.Angles(rad(35), rad(side * 25), rad(side * 18))
		mkAlienLeaf(m, tailCF, Vector3.new(0.4, 1.6, 0.18), C.AmethystPale, C.PulsarGold)
		-- Glowing Tail Tip
		mk({ name = "TailGlowTip", size = Vector3.new(0.35, 0.35, 0.35), cf = tailCF * CFrame.new(0, 0.9, 0),
			color = C.PulsarGold, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	end

	-- Stardust Spore Particles
	local att = Instance.new("Attachment")
	att.Name = "OrchidAura"
	att.Position = Vector3.new(0, 0.4, 0)
	att.Parent = mouthHeart
	local p = Instance.new("ParticleEmitter")
	p.Name = "PollenSparks"
	p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	p.Color = ColorSequence.new(C.AmethystPale, C.NebulaCyan)
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.5, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.Transparency = NumberSequence.new(0.2, 1)
	p.Lifetime = NumberRange.new(1.2, 2.2)
	p.Rate = 15
	p.Speed = NumberRange.new(0.5, 1.2)
	p.SpreadAngle = Vector2.new(180, 180)
	p.LightEmission = 1
	p.LightInfluence = 0
	p.Parent = att

	return m
end

--==============================================================================
-- 4. ASTRALHORN (Legendary, 6.90 studs) -- Armored Stag-Dragon Behemoth
--==============================================================================
local function buildAstralhorn(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Astralhorn"
	m.Parent = parent

	--== LIMBS: 4 Heavy Armored Beast Pillar Legs ==--
	for _, leg in ipairs({
		{ name = "FL", x = -1.2, z = -1.1, pitch = rad(-14), roll = rad(-10) },
		{ name = "FR", x =  1.2, z = -1.1, pitch = rad(-14), roll = rad( 10) },
		{ name = "BL", x = -1.2, z =  1.2, pitch = rad( 16), roll = rad(-10) },
		{ name = "BR", x =  1.2, z =  1.2, pitch = rad( 16), roll = rad( 10) },
	}) do
		-- Heavy Thigh
		local thighCF = baseCF * CFrame.new(leg.x, 1.6, leg.z) * CFrame.Angles(leg.pitch, 0, leg.roll)
		mk({ name = leg.name .. "_PillarThigh", size = Vector3.new(0.85, 1.5, 0.9), cf = thighCF,
			color = C.MidnightSlate, parent = m })
		-- Knee Armor Plate
		mk({ name = leg.name .. "_KneeArmor", size = Vector3.new(0.95, 0.5, 0.95), cf = thighCF * CFrame.new(0, -0.6, -0.1),
			color = C.AmethystDark, parent = m })
		-- Lower Pillar Leg & Claw Hoof (Ground level Y = 0.25)
		local hoofCF = baseCF * CFrame.new(leg.x * 1.05, 0.25, leg.z + (if leg.z < 0 then -0.2 else 0.2))
		mk({ name = leg.name .. "_Hoof", size = Vector3.new(0.9, 0.5, 1.0), cf = hoofCF,
			color = C.VoidBlack, parent = m })
		mk({ name = leg.name .. "_HoofGlow", size = Vector3.new(0.6, 0.15, 0.25), cf = hoofCF * CFrame.new(0, -0.15, -0.45),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	--== CREATURE BODY (80%): Armored Torso, Skull & Antlers ==--
	local torsoCF = baseCF * CFrame.new(0, 2.7, 0) * CFrame.Angles(rad(-6), 0, 0)
	mk({ name = "CarapaceTorso", size = Vector3.new(2.6, 2.4, 3.2), cf = torsoCF,
		color = C.Indigo, parent = m })
	mk({ name = "ChestPlate", size = Vector3.new(2.2, 1.8, 1.4), cf = torsoCF * CFrame.new(0, -0.4, -1.2) * CFrame.Angles(rad(18), 0, 0),
		color = C.MidnightSlate, parent = m })

	-- Constellation Spine Plates
	for i = 1, 4 do
		local spineCF = torsoCF * CFrame.new(0, 1.3, 1.3 - (i - 1) * 0.8)
		mk({ name = "SpinePlate", size = Vector3.new(0.5, 0.7, 0.7), cf = spineCF,
			color = C.AmethystDark, parent = m, wedge = true })
		mk({ name = "SpineGlow", size = Vector3.new(0.22, 0.25, 0.25), cf = spineCF * CFrame.new(0, 0.45, 0),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	-- Beast Skull & Heavy Underjaw
	local headCF = baseCF * CFrame.new(0, 4.1, -1.6) * CFrame.Angles(rad(10), 0, 0)
	mk({ name = "BeastSkull", size = Vector3.new(1.9, 1.5, 2.0), cf = headCF,
		color = C.MidnightSlate, parent = m })
	mk({ name = "HeavyUnderjaw", size = Vector3.new(1.5, 0.7, 1.5), cf = headCF * CFrame.new(0, -0.8, -0.3) * CFrame.Angles(rad(12), 0, 0),
		color = C.VoidBlack, parent = m })

	-- 4 Celestial Eyes
	for _, eyePos in ipairs({
		{ -0.7,  0.2, -1.0 },
		{  0.7,  0.2, -1.0 },
		{ -0.5, -0.2, -1.02 },
		{  0.5, -0.2, -1.02 },
	}) do
		mk({ name = "AstralEye", size = Vector3.new(0.24, 0.24, 0.24), cf = headCF * CFrame.new(eyePos[1], eyePos[2], eyePos[3]),
			color = C.NebulaCyan, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	end

	-- Sweeping Dual Crystalline Antlers
	for side = -1, 1, 2 do
		local h1 = headCF * CFrame.new(side * 0.9, 0.8, 0.1) * CFrame.Angles(rad(-15), rad(side * 35), rad(side * 28))
		mk({ name = "HornBase", size = Vector3.new(0.55, 1.8, 0.55), cf = h1,
			color = C.Amethyst, parent = m })
		local h2 = h1 * CFrame.new(0, 1.3, -0.35) * CFrame.Angles(rad(35), 0, rad(side * 20))
		mk({ name = "HornMid", size = Vector3.new(0.45, 1.5, 0.45), cf = h2,
			color = C.AmethystPale, parent = m })
		local h3 = h2 * CFrame.new(0, 1.2, 0.2) * CFrame.Angles(rad(-25), 0, rad(side * -15))
		mk({ name = "HornTip", size = Vector3.new(0.35, 1.3, 0.35), cf = h3,
			color = C.StarIvory, parent = m, material = Enum.Material.Neon })
		local subTine = h1 * CFrame.new(side * 0.45, 0.7, -0.45) * CFrame.Angles(rad(40), rad(side * 20), 0)
		mk({ name = "SubTine", size = Vector3.new(0.35, 1.0, 0.35), cf = subTine,
			color = C.AmethystPale, parent = m, wedge = true })
	end

	--== ALIEN LEAVES & PLANT TRAITS (20%): Foliage Fronds on Spine & Shoulders ==--
	for side = -1, 1, 2 do
		-- Shoulder Leaf Wings
		local sLeafCF = torsoCF * CFrame.new(side * 1.4, 0.8, -0.6) * CFrame.Angles(rad(-20), rad(side * 45), rad(side * 30))
		mkAlienLeaf(m, sLeafCF, Vector3.new(0.65, 2.2, 0.25), C.AmethystPale, C.NebulaCyan)
		-- Flank Leaf Fronds
		local fLeafCF = torsoCF * CFrame.new(side * 1.3, 0.4, 0.8) * CFrame.Angles(rad(15), rad(side * 50), rad(side * 25))
		mkAlienLeaf(m, fLeafCF, Vector3.new(0.55, 1.8, 0.22), C.Amethyst, C.PulsarGold)
	end

	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyanGlow
	light.Brightness = 1.5
	light.Range = 10
	light.Parent = m:FindFirstChild("BeastSkull") or m

	return m
end

--==============================================================================
-- 5. SUPERNOVUS (Mythic, 8.20 studs) -- Hexapod Cosmic Dragon Titan with Galaxy Lotus
--==============================================================================
local function buildSupernovus(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Supernovus"
	m.Parent = parent

	--== LIMBS: 6 Articulated Dragon-Titan Walking Legs (Hexapod) ==--
	for _, leg in ipairs({
		-- Front Crusher Arms
		{ name = "FrontLeft",  x = -1.8, z = -1.6, pitch = rad(-18), roll = rad(-15), size = 1.1 },
		{ name = "FrontRight", x =  1.8, z = -1.6, pitch = rad(-18), roll = rad( 15), size = 1.1 },
		-- Mid Striders
		{ name = "MidLeft",    x = -2.0, z =  0.1, pitch = rad(  0), roll = rad(-20), size = 1.0 },
		{ name = "MidRight",   x =  2.0, z =  0.1, pitch = rad(  0), roll = rad( 20), size = 1.0 },
		-- Rear Heavy Stompers
		{ name = "RearLeft",   x = -1.8, z =  1.8, pitch = rad( 20), roll = rad(-15), size = 1.2 },
		{ name = "RearRight",  x =  1.8, z =  1.8, pitch = rad( 20), roll = rad( 15), size = 1.2 },
	}) do
		-- Titan Upper Leg
		local legCF = baseCF * CFrame.new(leg.x, 1.8, leg.z) * CFrame.Angles(leg.pitch, 0, leg.roll)
		mk({ name = leg.name .. "_TitanThigh", size = Vector3.new(0.9 * leg.size, 1.7 * leg.size, 1.0 * leg.size), cf = legCF,
			color = C.MidnightSlate, parent = m })
		-- Armored Knee Shell
		mk({ name = leg.name .. "_KneeShell", size = Vector3.new(1.1 * leg.size, 0.6 * leg.size, 1.1 * leg.size), cf = legCF * CFrame.new(0, -0.6, -0.1),
			color = C.AmethystDark, parent = m })
		-- Claw Foot (Ground level Y = 0.25)
		local footCF = baseCF * CFrame.new(leg.x * 1.1, 0.25, leg.z + (if leg.z < 0 then -0.3 else 0.3))
		mk({ name = leg.name .. "_TitanClaw", size = Vector3.new(1.1 * leg.size, 0.5, 1.3 * leg.size), cf = footCF,
			color = C.VoidBlack, parent = m })
		-- Neon Claw Talons
		mk({ name = leg.name .. "_TalonGlow", size = Vector3.new(0.7 * leg.size, 0.2, 0.3), cf = footCF * CFrame.new(0, -0.15, -0.6 * leg.size),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	--== CREATURE BODY (80%): Colossal Titan Carapace & Dragon Skull ==--
	local bodyCF = baseCF * CFrame.new(0, 2.8, 0)
	mk({ name = "TitanCarapace", size = Vector3.new(3.8, 2.6, 4.4), cf = bodyCF,
		color = C.MidnightSlate, parent = m })
	mk({ name = "VentralBelly", size = Vector3.new(3.2, 1.8, 3.8), cf = bodyCF * CFrame.new(0, -0.6, 0),
		color = C.VoidBlack, parent = m })

	-- Long Arched Dragon Neck & Roaring Skull
	local neckCF = bodyCF * CFrame.new(0, 0.8, -2.4) * CFrame.Angles(rad(-20), 0, 0)
	mk({ name = "DragonNeck", size = Vector3.new(1.8, 1.8, 2.0), cf = neckCF,
		color = C.Indigo, parent = m })

	local skullCF = neckCF * CFrame.new(0, 0.9, -1.1) * CFrame.Angles(rad(15), 0, 0)
	mk({ name = "DragonSkull", size = Vector3.new(2.2, 1.6, 2.4), cf = skullCF,
		color = C.MidnightSlate, parent = m })
	mk({ name = "RoaringJaw", size = Vector3.new(1.8, 0.7, 1.8), cf = skullCF * CFrame.new(0, -0.85, -0.4) * CFrame.Angles(rad(22), 0, 0),
		color = C.VoidBlack, parent = m })

	-- Roaring Cosmic Maw Core
	local mawLight = mk({ name = "MawCore", size = Vector3.new(1.1, 1.1, 1.1), cf = skullCF * CFrame.new(0, -0.4, -0.5),
		color = C.StarIvory, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })

	-- 6 Celestial Dragon Eyes
	for _, eyePos in ipairs({
		{ -0.85,  0.35, -0.9 },
		{  0.85,  0.35, -0.9 },
		{ -0.65,  0.05, -1.05 },
		{  0.65,  0.05, -1.05 },
		{ -0.45, -0.25, -1.15 },
		{  0.45, -0.25, -1.15 },
	}) do
		mk({ name = "DragonEye", size = Vector3.new(0.25, 0.25, 0.25), cf = skullCF * CFrame.new(eyePos[1], eyePos[2], eyePos[3]),
			color = C.NebulaCyan, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	end

	-- Dragon Horn Brow Spikes
	for side = -1, 1, 2 do
		local hornCF = skullCF * CFrame.new(side * 0.9, 0.9, 0.3) * CFrame.Angles(rad(-25), rad(side * 28), rad(side * 22))
		mk({ name = "BrowHorn", size = Vector3.new(0.45, 1.6, 0.45), cf = hornCF,
			color = C.AmethystPale, parent = m, wedge = true })
	end

	--== ALIEN LEAVES & PLANT TRAITS (20%): Dorsal Galaxy Lotus & Giant Alien Fronds ==--
	-- 4 Giant Sweeping Alien Fronds fanning out from the carapace shell
	for _, frond in ipairs({
		{ side = -1, fore = -1, x = -2.1, z = -0.8, pitch = rad(-25), roll = rad(-40) },
		{ side =  1, fore = -1, x =  2.1, z = -0.8, pitch = rad(-25), roll = rad( 40) },
		{ side = -1, fore =  1, x = -2.1, z =  1.2, pitch = rad( 25), roll = rad(-45) },
		{ side =  1, fore =  1, x =  2.1, z =  1.2, pitch = rad( 25), roll = rad( 45) },
	}) do
		local fCF = bodyCF * CFrame.new(frond.x, 1.2, frond.z) * CFrame.Angles(frond.pitch, 0, frond.roll)
		mkAlienLeaf(m, fCF, Vector3.new(0.85, 3.2, 0.35), C.AmethystPale, C.NebulaCyan)
	end

	-- Dorsal Galaxy Lotus Blooming Out of Back Shell
	local lotusBaseCF = bodyCF * CFrame.new(0, 1.4, 0.2)
	mk({ name = "LotusStem", size = Vector3.new(1.6, 1.4, 1.6), cf = lotusBaseCF,
		color = C.Indigo, parent = m, shape = Enum.PartType.Cylinder })

	local flowerCF = lotusBaseCF * CFrame.new(0, 1.2, 0)

	-- 8 Outer Void Petals
	for i = 1, 8 do
		local a = rad(i * 45)
		local pCF = flowerCF * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.4, 1.5) * CFrame.Angles(rad(38), 0, 0)
		mk({ name = "OuterPetal", size = Vector3.new(1.0, 2.2, 0.28), cf = pCF,
			color = C.MidnightSlate, parent = m, wedge = true })
	end

	-- 8 Inner Starlight Petals
	for i = 1, 8 do
		local a = rad(i * 45 + 22.5)
		local pCF = flowerCF * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.9, 0.95) * CFrame.Angles(rad(25), 0, 0)
		mk({ name = "InnerPetal", size = Vector3.new(0.8, 1.9, 0.22), cf = pCF,
			color = C.AmethystPale, parent = m, wedge = true })
	end

	-- Tilted 12-Segment Orbital Ring
	local ringTilt = flowerCF * CFrame.new(0, 1.4, 0) * CFrame.Angles(rad(22), rad(35), 0)
	for i = 1, 12 do
		local a = rad(i * 30)
		local arcCF = ringTilt * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 2.2)
		mk({ name = "OrbitalArc", size = Vector3.new(1.1, 0.18, 0.28), cf = arcCF,
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	-- 4 Orbiting Golden Comet Satellites
	for i = 1, 4 do
		local a = rad(i * 90 + 45)
		local satCF = ringTilt * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 2.6)
		mk({ name = "CometSatellite", size = Vector3.new(0.55, 0.55, 0.55), cf = satCF,
			color = C.PulsarGold, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	end

	-- Blinding Central Supernova Pulsar Core
	local core = mk({ name = "SupernovaCore", size = Vector3.new(2.0, 2.0, 2.0), cf = flowerCF * CFrame.new(0, 1.4, 0),
		color = C.StarIvory, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyanGlow
	light.Brightness = 3.0
	light.Range = 16
	light.Parent = core

	-- Vertical Crown Flares & Spikes
	local flareCF = flowerCF * CFrame.new(0, 2.8, 0)
	mk({ name = "CrownFlareMain", size = Vector3.new(0.55, 1.6, 0.55), cf = flareCF,
		color = C.PulsarGold, parent = m, shape = Enum.PartType.Cylinder, material = Enum.Material.Neon })
	for i = 1, 4 do
		local a = rad(i * 90)
		local fCF = flareCF * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.4, 0.45) * CFrame.Angles(rad(25), 0, 0)
		mk({ name = "CrownSpike", size = Vector3.new(0.35, 1.2, 0.25), cf = fCF,
			color = C.StarIvory, parent = m, wedge = true, material = Enum.Material.Neon })
	end

	-- Pulsar Particle Sparks
	local att = Instance.new("Attachment")
	att.Name = "SupernovaSparks"
	att.Position = Vector3.new(0, 1.0, 0)
	att.Parent = core
	local p = Instance.new("ParticleEmitter")
	p.Name = "PulsarFlairs"
	p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	p.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.PulsarGold),
		ColorSequenceKeypoint.new(0.5, C.StarIvory),
		ColorSequenceKeypoint.new(1, C.NebulaCyan),
	})
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.4, 0.6),
		NumberSequenceKeypoint.new(1, 0),
	})
	p.Transparency = NumberSequence.new(0.1, 1)
	p.Lifetime = NumberRange.new(1.4, 2.8)
	p.Rate = 28
	p.Speed = NumberRange.new(1.5, 3.5)
	p.SpreadAngle = Vector2.new(180, 180)
	p.LightEmission = 1
	p.LightInfluence = 0
	p.Parent = att

	return m
end

local BUILDERS: { [string]: (Instance, CFrame) -> Model } = {
	novaorb    = buildNovaorb,
	cosmospire = buildCosmospire,
	voidpetal  = buildVoidpetal,
	astralhorn = buildAstralhorn,
	supernovus = buildSupernovus,
}

--==============================================================================
-- BUILD ONE STARBLOOM SPECIES, CONFORMED TO ITS TIER
--
-- `hs` is height: the ratio between the tier's frame and the height this
-- species was authored at. `gs` is the damped horizontal girth spread, and it
-- is optional -- a caller that omits it gets 1 and the old height-only
-- behaviour, which is exactly what every showroom wants.
--
-- Girth arriving here at all is the fix for a real gap: this took one scalar,
-- so a Colossal was a uniformly enlarged Tiny -- the same silhouette, the same
-- proportions, no added heft, while Tanglemire's creatures were getting broader
-- across the ladder. Girth runs 0.82 to 1.45 and it was reaching two biomes out
-- of the three that need it.
--==============================================================================
function StarbloomForms.Build(model: Model, id: string, at: CFrame, hs: number, gs: number?): boolean
	local fn = BUILDERS[id]
	if not fn then
		return false
	end
	local scratch = Instance.new("Folder")
	scratch.Parent = model
	local built = fn(scratch, at)

	local spread = if type(gs) == "number" and gs == gs and gs > 0 then gs else 1
	if math.abs(hs - 1) > 1e-6 or math.abs(spread - 1) > 1e-6 then
		for _, d in ipairs(built:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CFrame = at * scaled(at:ToObjectSpace(d.CFrame), hs, spread)
				-- Size takes the height scale ALONE. See scaled().
				d.Size = d.Size * hs
			elseif d:IsA("Attachment") then
				-- An attachment is a point on a part, so it travels with the
				-- same spread its part did.
				d.Position = Vector3.new(d.Position.X * hs * spread,
					d.Position.Y * hs, d.Position.Z * hs * spread)
			elseif d:IsA("PointLight") then
				d.Range = d.Range * hs
			elseif d:IsA("ParticleEmitter") then
				d.Size = scaleSequence(d.Size, hs)
				d.Speed = NumberRange.new(d.Speed.Min * hs, d.Speed.Max * hs)
				d.Acceleration = d.Acceleration * hs
			end
		end
	end

	for _, d in ipairs(built:GetChildren()) do
		d.Parent = model
	end
	scratch:Destroy()
	return true
end

return StarbloomForms
