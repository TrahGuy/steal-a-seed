--!strict
--==============================================================================
-- STARBLOOM FORMS (BIOME 5) -- 80% CREATURE / 20% PLANT
--
-- Primitive-sculpted alien cosmic creatures with standing locomotion limbs,
-- bioluminescent alien leaves, and per-species cosmic palettes. Built within the
-- art bible target budget of 25–40 parts per grown plant.
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
-- its approved proportions.
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

--==============================================================================
-- A PART NAMED "Leaf" IS A PROMISE TO PlantSway
--
-- Not decoration. PlantSway.client.luau swings every DIRECT CHILD of a plant
-- named exactly "Leaf" as an arm while the plant walks, and works out which side
-- of the stem each is on from its own X offset. Under any other name it simply
-- never moves.
--
-- THIS HAS BEEN GOT WRONG TWICE. Suncrown's four were authored as SupportLeaf1-4
-- and had to be renamed; these five shipped as "AlienLeaf", "CrownLeaf" and
-- "LeafVein" and no Starbloom plant fluttered until they were renamed either.
-- Rename one of these to something prettier and it goes still, silently, with
-- nothing in the console to say so.
--
-- PAIRED PARTS TAKE THE NAME TOGETHER. Novaorb's blade and its neon vein are
-- both "Leaf": they sit a fraction of a stud apart on the same axis, so they
-- swing about near-identical centres and stay together. Naming only the blade
-- would peel the vein off it on every step.
--
-- Six sites build them, each marked with its own count. Keep those counts
-- honest -- the leaf total is a per-frame cost while a plant is walking.
--==============================================================================

-- Starbloom Shared Palette Family
local C = {
	VoidBlack      = Color3.fromRGB(14, 10, 24),
	MidnightSlate  = Color3.fromRGB(24, 18, 46),
	Indigo         = Color3.fromRGB(39, 37, 82),
	AmethystDark   = Color3.fromRGB(48, 30, 78),
	Amethyst       = Color3.fromRGB(90, 50, 160),
	AmethystPale   = Color3.fromRGB(158, 128, 255),
	StarlightViolet= Color3.fromRGB(180, 150, 255),
	OrchidPurple   = Color3.fromRGB(214, 140, 255),
	NebulaCyan     = Color3.fromRGB(110, 230, 255),
	NebulaCyanGlow = Color3.fromRGB(180, 245, 255),
	StarIvory      = Color3.fromRGB(242, 238, 255),
	PulsarGold     = Color3.fromRGB(255, 215, 120),
	CoreWhite      = Color3.fromRGB(255, 255, 255),
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
-- 1. NOVAORB (Rare, 4.60 studs) -- Budget: 27 parts (+ 1 Base = 28 parts)
--==============================================================================
--==============================================================================
-- THE VOID EYE, AND WHY IT IS BUILT HERE
--
-- CreatureModel has a per-biome eye system and it already carries an entry for
-- this biome: EYE_STYLE.starbloom = "void", built by addFace. Starbloom has
-- never received it. addFace runs near the end of BuildCreature and the
-- Starbloom branch answers hundreds of lines earlier, exactly as Tanglemire's
-- does -- and Tanglemire got an explicit retrofit where Starbloom got nothing.
-- So these five wore a hand-rolled ball with a glint on it, no pupil and no lid,
-- which is the worst eye treatment in the game.
--
-- THE RIG FALLS OUT OF THE NAMES, so this builds to the same contract addFace
-- does and PlantSway picks it up for free:
--
--   <side>Eye     the eyeball. The suffix "Eye" is what makes it an eye at all.
--   <side>Pupil   the suffix "Pupil" upgrades the whole plant to the PUPIL RIG:
--                 the eyeball swings in its socket and everything mounted on it
--                 rides along, instead of the eye itself sliding about the face.
--                 Two pupils on one eye is legal and both travel -- the doe eye
--                 already does it.
--   <side>Lid     paired to its eye by the prefix they share, and swept over it
--                 to blink. A Ball renders as a sphere of its SMALLEST axis, so
--                 an eye cannot be squashed shut; the lid must be its own part
--                 passing in front of it.
--
-- NO GLINT. That is the void family's whole design and it is deliberate: a
-- highlight is what makes an eye look wet, and withholding it is what makes
-- these look like they are not alive. One cold pinprick, and nothing else.
--
-- WITHIN the family each species gets a different KIND of eye rather than a
-- recolour, so the difference survives being seen small and from across a plot.
-- The Mythic is the exception that proves the rule: it is the only one lit from
-- inside, which is what makes it read hot against four cold ones.
--==============================================================================
--==============================================================================
-- THE EYE GOES ON THE SURFACE, AND THAT IS A MEASUREMENT, NOT A FEELING
--
-- The art bible: "Eyes are dark balls centred ON the surface so half stands
-- proud. The radius IS the proudness; no fudge factor."
--
-- All five of these had eyes placed INBOARD of their own skull face -- the
-- Mythic's sat a fifth of a stud inside a box 2.4 deep -- so the head occluded
-- the eye completely and every one of these faces was a blank slab. It is an
-- easy mistake to keep making, because the offset that buries an eye looks
-- perfectly sensible written down; it is only wrong relative to the size of the
-- part it is measured against.
--
-- So when moving an eye, read the head part's Z size and halve it. That number
-- is where the eye centre goes.
--==============================================================================
local VOID_SCLERA = Color3.fromRGB(14, 12, 20)
local LID_H = 0.72

local function voidEye(m: Instance, tag: string, eyeCF: CFrame, dia: number,
	style: string, lidColor: Color3, droop: number?)
	if style == "mantis" then
		-- A TALL eye, so it cannot be a Ball: a Ball renders as a sphere of its
		-- smallest axis and would come back round however it is sized. Block
		-- sclera, vertical slit.
		mk({ name = tag .. "Eye", size = Vector3.new(dia * 0.52, dia * 1.15, dia * 0.62),
			cf = eyeCF, color = VOID_SCLERA, parent = m, smooth = true })
		mk({ name = tag .. "Pupil", size = Vector3.new(dia * 0.14, dia * 0.78, dia * 0.16),
			cf = eyeCF * CFrame.new(0, 0, -dia * 0.34),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon, smooth = true })

	elseif style == "predator" then
		-- Wide and low, with the horizontal slit of something that hunts along
		-- the ground. The sclera carries a dim amethyst rather than black, which
		-- is the nebula ring without paying two parts for a ring.
		mk({ name = tag .. "Eye", size = Vector3.new(dia * 1.05, dia * 0.58, dia * 0.62),
			cf = eyeCF, color = Color3.fromRGB(38, 20, 62), parent = m, smooth = true })
		mk({ name = tag .. "Pupil", size = Vector3.new(dia * 0.72, dia * 0.15, dia * 0.16),
			cf = eyeCF * CFrame.new(0, 0, -dia * 0.34),
			color = C.OrchidPurple, parent = m, material = Enum.Material.Neon, smooth = true })

	elseif style == "deepset" then
		-- Set back under the brow so the socket shades it. The pupil is a short
		-- upright BAR rather than a point: a bar catches light along its length
		-- and still reads at the distance where a pinprick vanishes.
		mk({ name = tag .. "Eye", size = Vector3.new(dia * 0.86, dia * 0.86, dia * 0.86),
			cf = eyeCF, color = VOID_SCLERA, parent = m,
			shape = Enum.PartType.Ball, smooth = true })
		mk({ name = tag .. "Pupil", size = Vector3.new(dia * 0.13, dia * 0.44, dia * 0.14),
			cf = eyeCF * CFrame.new(0, 0, -dia * 0.36),
			color = C.StarIvory, parent = m, material = Enum.Material.Neon, smooth = true })

	elseif style == "pulsar" then
		-- THE ONLY EYE IN THE BIOME LIT FROM INSIDE. A gold core plus a smaller
		-- ember set off-centre. Both are Pupils, so the rig swings the pair
		-- together and the ember cannot collapse onto the core as it tracks.
		mk({ name = tag .. "Eye", size = Vector3.new(dia * 1.06, dia * 1.06, dia * 1.06),
			cf = eyeCF, color = VOID_SCLERA, parent = m,
			shape = Enum.PartType.Ball, smooth = true })
		mk({ name = tag .. "Pupil", size = Vector3.new(dia * 0.34, dia * 0.34, dia * 0.34),
			cf = eyeCF * CFrame.new(0, 0, -dia * 0.40),
			color = C.PulsarGold, parent = m,
			shape = Enum.PartType.Ball, material = Enum.Material.Neon, smooth = true })
		mk({ name = tag .. "Pupil", size = Vector3.new(dia * 0.15, dia * 0.15, dia * 0.15),
			cf = eyeCF * CFrame.new(dia * 0.22, dia * 0.18, -dia * 0.38),
			color = C.NebulaCyanGlow, parent = m,
			shape = Enum.PartType.Ball, material = Enum.Material.Neon, smooth = true })

	else -- "placid"
		-- The widest, softest eye of the five, and the lid rides low on it. It
		-- is the only one here that could be called friendly, which is what a
		-- Rare at the bottom of the ladder should be.
		mk({ name = tag .. "Eye", size = Vector3.new(dia, dia, dia),
			cf = eyeCF, color = VOID_SCLERA, parent = m,
			shape = Enum.PartType.Ball, smooth = true })
		mk({ name = tag .. "Pupil", size = Vector3.new(dia * 0.26, dia * 0.26, dia * 0.26),
			cf = eyeCF * CFrame.new(0, 0, -dia * 0.42),
			color = C.StarIvory, parent = m,
			shape = Enum.PartType.Ball, material = Enum.Material.Neon, smooth = true })
	end

	-- THE LID SITS ABOVE THE EYE AT REST and sweeps down over it to blink. It
	-- has to stand proud of the face: the eye is centred ON the surface so half
	-- of it is outside, and a lid tucked near the skin closes BEHIND that
	-- hemisphere and covers nothing. `droop` is how far down it rests, so a
	-- lower one reads sleepy.
	mk({ name = tag .. "Lid",
		size = Vector3.new(dia * 1.24, dia * LID_H, dia * 0.62),
		cf = eyeCF * CFrame.new(0, dia * (0.5 + LID_H * 0.5 + (droop or 0.10)), -dia * 0.30),
		color = lidColor, parent = m, smooth = true })
end

local function buildNovaorb(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Novaorb"
	m.Parent = parent

	-- Limbs: 2 Biped Legs (Thigh + Shin + FootClaw = 6 parts) + 1 Tail (1 part) = 7 parts
	for side = -1, 1, 2 do
		local thighCF = baseCF * CFrame.new(side * 0.85, 1.2, -0.1) * CFrame.Angles(rad(-18), rad(side * 15), rad(side * 12))
		mk({ name = "Thigh", size = Vector3.new(0.65, 1.2, 0.75), cf = thighCF,
			color = C.Indigo, parent = m })
		local shinCF = thighCF * CFrame.new(0, -0.65, 0.2) * CFrame.Angles(rad(35), 0, 0)
		mk({ name = "Shin", size = Vector3.new(0.55, 0.9, 0.55), cf = shinCF,
			color = C.AmethystDark, parent = m })
		local footCF = baseCF * CFrame.new(side * 0.95, 0.2, -0.6) * CFrame.Angles(0, rad(side * 10), 0)
		mk({ name = "FootClaw", size = Vector3.new(0.7, 0.4, 0.9), cf = footCF,
			color = C.VoidBlack, parent = m, wedge = true })
	end
	mk({ name = "TailLimb", size = Vector3.new(0.65, 0.8, 0.8), cf = baseCF * CFrame.new(0, 0.4, 0.9) * CFrame.Angles(rad(25), 0, 0),
		color = C.VoidBlack, parent = m })

	-- Torso & Belly (3 parts)
	local bodyCF = baseCF * CFrame.new(0, 2.1, 0)
	mk({ name = "Torso", size = Vector3.new(2.3, 2.1, 2.2), cf = bodyCF,
		color = C.Indigo, parent = m, shape = Enum.PartType.Ball })
	mk({ name = "BellyPlate", size = Vector3.new(1.4, 1.4, 0.3), cf = bodyCF * CFrame.new(0, -0.3, -0.95) * CFrame.Angles(rad(15), 0, 0),
		color = C.MidnightSlate, parent = m })
	mk({ name = "BellyGlow", size = Vector3.new(0.8, 0.8, 0.1), cf = bodyCF * CFrame.new(0, -0.3, -1.05) * CFrame.Angles(rad(15), 0, 0),
		color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })

	-- Face: brow, two void eyes with their lids, jaw (8 parts). The glint went
	-- with the family rule; see the void eye banner above.
	local faceCF = bodyCF * CFrame.new(0, 0.3, -0.85)
	mk({ name = "BrowRidge", size = Vector3.new(1.8, 0.45, 0.7), cf = faceCF * CFrame.new(0, 0.4, 0),
		color = C.AmethystDark, parent = m })
	-- Eyes: placid, and the glint goes. The family forbids a highlight.
	for side = -1, 1, 2 do
		local tag = if side < 0 then "Left" else "Right"
		-- ON the Torso's front face: it is 2.2 deep, so the surface is 1.1 from
		-- bodyCF and faceCF already stands 0.85 of it out.
		voidEye(m, tag, faceCF * CFrame.new(side * 0.45, 0.1, -0.25), 0.52,
			"placid", C.AmethystDark, 0.02)
	end
	mk({ name = "AlienJaw", size = Vector3.new(1.6, 0.5, 1.2), cf = faceCF * CFrame.new(0, -0.4, 0.1) * CFrame.Angles(rad(-10), 0, 0),
		color = C.VoidBlack, parent = m })

	-- Alien Leaves (4 direct children named "Leaf")
	for side = -1, 1, 2 do
		local leafCF = bodyCF * CFrame.new(side * 1.1, 0.8, 0.2) * CFrame.Angles(rad(-20), rad(side * 40), rad(side * 35))
		mk({ name = "Leaf", size = Vector3.new(0.55, 1.6, 0.25), cf = leafCF,
			color = C.AmethystPale, parent = m, wedge = true })
		mk({ name = "Leaf", size = Vector3.new(0.15, 1.5, 0.15), cf = leafCF * CFrame.new(0, 0, 0.1),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	-- Crown Calyx & 3 Spikes (4 parts) + 3 Orbiting Motes (3 parts) = 7 parts
	local crownCF = bodyCF * CFrame.new(0, 1.2, 0)
	mk({ name = "HeadCalyx", size = Vector3.new(0.8, 0.4, 0.8), cf = crownCF,
		color = C.AmethystDark, parent = m, shape = Enum.PartType.Cylinder })
	for i = 1, 3 do
		local a = rad(i * 120 + 30)
		local pCF = crownCF * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.35, 0.35) * CFrame.Angles(rad(35), 0, 0)
		mk({ name = "CrownSpike", size = Vector3.new(0.35, 0.8, 0.2), cf = pCF,
			color = C.AmethystPale, parent = m, wedge = true })
	end
	for i = 1, 3 do
		local a = rad(i * 120 + 20)
		local moteCF = crownCF * CFrame.Angles(rad(15), a, 0) * CFrame.new(0, 0, 1.6)
		mk({ name = "Mote", size = Vector3.new(0.32, 0.32, 0.32), cf = moteCF,
			color = C.StarIvory, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	end

	-- Light
	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyan
	light.Brightness = 1.2
	light.Range = 8
	light.Parent = m:FindFirstChild("Torso") or m

	return m
end

--==============================================================================
-- 2. COSMOSPIRE (Rare, 7.40 studs) -- Budget: 28 parts (+ 1 Base = 29 parts)
--==============================================================================
local function buildCosmospire(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Cosmospire"
	m.Parent = parent

	-- Limbs: 4 Stilt Legs (Femur + Tibia + StiltClaw = 12 parts)
	for _, legSpec in ipairs({
		{ x = -0.7, z = -0.5, pitch = rad(-18), roll = rad(-15), fore =  1 },
		{ x =  0.7, z = -0.5, pitch = rad(-18), roll = rad( 15), fore =  1 },
		{ x = -0.7, z =  0.6, pitch = rad( 20), roll = rad(-15), fore = -1 },
		{ x =  0.7, z =  0.6, pitch = rad( 20), roll = rad( 15), fore = -1 },
	}) do
		local femurCF = baseCF * CFrame.new(legSpec.x, 2.3, legSpec.z) * CFrame.Angles(legSpec.pitch, 0, legSpec.roll)
		mk({ name = "Femur", size = Vector3.new(0.45, 1.9, 0.45), cf = femurCF,
			color = C.MidnightSlate, parent = m })
		local tibiaCF = femurCF * CFrame.new(0, -1.8, 0) * CFrame.Angles(rad(-legSpec.fore * 28), 0, 0)
		mk({ name = "Tibia", size = Vector3.new(0.38, 2.0, 0.38), cf = tibiaCF,
			color = C.AmethystDark, parent = m })
		local clawCF = baseCF * CFrame.new(legSpec.x * 1.6, 0.2, legSpec.z * 1.5)
		mk({ name = "StiltClaw", size = Vector3.new(0.5, 0.4, 0.6), cf = clawCF,
			color = C.VoidBlack, parent = m, wedge = true })
	end

	-- Body, Neck & Raptor Skull (6 parts)
	local thoraxCF = baseCF * CFrame.new(0, 3.2, 0) * CFrame.Angles(rad(-10), 0, 0)
	mk({ name = "Thorax", size = Vector3.new(1.6, 1.8, 1.8), cf = thoraxCF,
		color = C.MidnightSlate, parent = m })
	mk({ name = "Abdomen", size = Vector3.new(1.2, 1.5, 1.4), cf = thoraxCF * CFrame.new(0, -0.4, 1.1) * CFrame.Angles(rad(25), 0, 0),
		color = C.VoidBlack, parent = m })
	local neckCF = thoraxCF * CFrame.new(0, 1.1, -0.7) * CFrame.Angles(rad(-22), 0, 0)
	mk({ name = "Neck", size = Vector3.new(0.7, 1.2, 0.7), cf = neckCF,
		color = C.AmethystDark, parent = m })
	local headCF = neckCF * CFrame.new(0, 0.8, -0.3) * CFrame.Angles(rad(15), 0, 0)
	mk({ name = "AlienSkull", size = Vector3.new(1.2, 0.9, 1.4), cf = headCF,
		color = C.MidnightSlate, parent = m })
	-- Eyes: mantis. Angled outward off the skull, as the old slits were.
	for side = -1, 1, 2 do
		local tag = if side < 0 then "Left" else "Right"
		-- On the front corner of the skull, which is 1.2 wide and 1.4 deep.
		-- Angled outward, because a mantis carries its eyes on the corners of
		-- its head rather than flat on the front of it.
		voidEye(m, tag,
			headCF * CFrame.new(side * 0.50, 0.1, -0.70) * CFrame.Angles(0, rad(side * 20), 0),
			0.40, "mantis", C.MidnightSlate)
	end
	mk({ name = "Mandibles", size = Vector3.new(0.9, 0.4, 0.6), cf = headCF * CFrame.new(0, -0.45, -0.4) * CFrame.Angles(rad(15), 0, 0),
		color = C.VoidBlack, parent = m, wedge = true })

	-- Dorsal Needle & Quasar Tip (2 parts)
	local spireCF = thoraxCF * CFrame.new(0, 2.4, 0.1) * CFrame.Angles(rad(8), 0, 0)
	mk({ name = "DorsalNeedle", size = Vector3.new(0.6, 2.8, 0.6), cf = spireCF,
		color = C.StarlightViolet, parent = m, shape = Enum.PartType.Cylinder })
	local crownTip = mk({ name = "QuasarTip", size = Vector3.new(0.5, 0.7, 0.5), cf = baseCF * CFrame.new(0, 7.3, 0),
		color = C.StarIvory, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })

	-- 4 Alien Leaves (direct children named "Leaf")
	for _, lSpec in ipairs({
		{ side = -1, y = 3.6, pitch = rad(-15), roll = rad(-35) },
		{ side =  1, y = 3.6, pitch = rad(-15), roll = rad( 35) },
		{ side = -1, y = 4.8, pitch = rad(-25), roll = rad(-45) },
		{ side =  1, y = 4.8, pitch = rad(-25), roll = rad( 45) },
	}) do
		local lCF = baseCF * CFrame.new(lSpec.side * 0.6, lSpec.y, 0.2) * CFrame.Angles(lSpec.pitch, 0, lSpec.roll)
		mk({ name = "Leaf", size = Vector3.new(0.45, 1.8, 0.22), cf = lCF,
			color = C.StarlightViolet, parent = m, wedge = true })
	end

	-- 3 Floating Diamond Capacitor Nodes (3 parts)
	for i = 1, 3 do
		local a = rad(i * 120)
		local nodeCF = baseCF * CFrame.new(0, 4.2, 0) * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 1.35) * CFrame.Angles(rad(45), rad(45), 0)
		mk({ name = "CapacitorNode", size = Vector3.new(0.38, 0.38, 0.38), cf = nodeCF,
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyanGlow
	light.Brightness = 1.6
	light.Range = 10
	light.Parent = crownTip

	return m
end

--==============================================================================
-- 3. VOIDPETAL (Epic, 5.60 studs) -- Budget: 26 parts (+ 1 Base = 27 parts)
--==============================================================================
local function buildVoidpetal(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Voidpetal"
	m.Parent = parent

	-- Limbs: 4 Prowling Predator Legs (Haunch + Paw = 8 parts)
	for _, leg in ipairs({
		{ name = "FL", x = -0.85, z = -1.1, pitch = rad(-15), roll = rad(-10) },
		{ name = "FR", x =  0.85, z = -1.1, pitch = rad(-15), roll = rad( 10) },
		{ name = "BL", x = -0.95, z =  1.1, pitch = rad( 22), roll = rad(-12) },
		{ name = "BR", x =  0.95, z =  1.1, pitch = rad( 22), roll = rad( 12) },
	}) do
		local haunchCF = baseCF * CFrame.new(leg.x, 1.4, leg.z) * CFrame.Angles(leg.pitch, 0, leg.roll)
		mk({ name = leg.name .. "_Haunch", size = Vector3.new(0.65, 1.2, 0.75), cf = haunchCF,
			color = C.AmethystDark, parent = m })
		local pawCF = baseCF * CFrame.new(leg.x * 1.1, 0.2, leg.z + (if leg.z < 0 then -0.3 else 0.2))
		mk({ name = leg.name .. "_Paw", size = Vector3.new(0.6, 0.4, 0.75), cf = pawCF,
			color = C.VoidBlack, parent = m })
	end

	-- Panther Torso & Head (6 parts)
	local spineCF = baseCF * CFrame.new(0, 2.2, 0) * CFrame.Angles(rad(-6), 0, 0)
	mk({ name = "SpineTorso", size = Vector3.new(1.8, 1.7, 2.8), cf = spineCF,
		color = C.AmethystDark, parent = m })
	local headCF = baseCF * CFrame.new(0, 2.5, -1.8) * CFrame.Angles(rad(8), 0, 0)
	mk({ name = "PantherSkull", size = Vector3.new(1.5, 1.2, 1.6), cf = headCF,
		color = C.AmethystDark, parent = m })
	mk({ name = "SnoutJaw", size = Vector3.new(1.1, 0.55, 1.1), cf = headCF * CFrame.new(0, -0.4, -0.6) * CFrame.Angles(rad(12), 0, 0),
		color = C.VoidBlack, parent = m })
	local mouthHeart = mk({ name = "MawHeart", size = Vector3.new(0.65, 0.65, 0.65), cf = headCF * CFrame.new(0, -0.2, -0.4),
		color = C.NebulaCyan, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	-- Eyes: predator. Low and wide, the slit lying along the horizon.
	for side = -1, 1, 2 do
		local tag = if side < 0 then "Left" else "Right"
		-- On the skull's face: 1.6 deep, so the surface is 0.8 out.
		voidEye(m, tag, headCF * CFrame.new(side * 0.45, 0.2, -0.80), 0.34,
			"predator", C.AmethystDark)
	end

	-- 6-Petal Flaring Orchid Mane (6 direct children named "Leaf")
	local maneCF = headCF * CFrame.new(0, 0.1, 0.7)
	for i = 1, 6 do
		local a = rad(i * 60)
		local pCF = maneCF * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.4, 0) * CFrame.Angles(rad(28), 0, 0)
		mk({ name = "Leaf", size = Vector3.new(0.65, 1.8, 0.2), cf = pCF,
			color = if i % 2 == 0 then C.OrchidPurple else C.MidnightSlate, parent = m, wedge = true })
	end

	-- 2 Golden Stamen Whiskers (2 parts)
	for side = -1, 1, 2 do
		local stamenCF = maneCF * CFrame.new(side * 0.8, 0.6, -0.2) * CFrame.Angles(rad(15), rad(side * 20), 0)
		mk({ name = "StamenWhisker", size = Vector3.new(0.2, 0.8, 0.2), cf = stamenCF,
			color = C.PulsarGold, parent = m, material = Enum.Material.Neon })
	end

	-- Twin Curled Alien Leaf Tails (2 direct children named "Leaf") + 2 Glow Tips (2 parts) = 4 parts
	for side = -1, 1, 2 do
		local tailCF = baseCF * CFrame.new(side * 0.4, 2.5, 1.6) * CFrame.Angles(rad(35), rad(side * 25), rad(side * 18))
		mk({ name = "Leaf", size = Vector3.new(0.4, 1.6, 0.18), cf = tailCF,
			color = C.OrchidPurple, parent = m, wedge = true })
		mk({ name = "TailGlowTip", size = Vector3.new(0.35, 0.35, 0.35), cf = tailCF * CFrame.new(0, 0.9, 0),
			color = C.PulsarGold, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	end

	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyan
	light.Brightness = 1.6
	light.Range = 9
	light.Parent = mouthHeart

	return m
end

--==============================================================================
-- 4. ASTRALHORN (Legendary, 6.90 studs) -- Budget: 28 parts (+ 1 Base = 29 parts)
--==============================================================================
local function buildAstralhorn(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Astralhorn"
	m.Parent = parent

	-- Limbs: 4 Heavy Pillar Legs (PillarThigh + Hoof = 8 parts)
	for _, leg in ipairs({
		{ name = "FL", x = -1.2, z = -1.1, pitch = rad(-14), roll = rad(-10) },
		{ name = "FR", x =  1.2, z = -1.1, pitch = rad(-14), roll = rad( 10) },
		{ name = "BL", x = -1.2, z =  1.2, pitch = rad( 16), roll = rad(-10) },
		{ name = "BR", x =  1.2, z =  1.2, pitch = rad( 16), roll = rad( 10) },
	}) do
		local thighCF = baseCF * CFrame.new(leg.x, 1.6, leg.z) * CFrame.Angles(leg.pitch, 0, leg.roll)
		mk({ name = leg.name .. "_PillarThigh", size = Vector3.new(0.85, 1.5, 0.9), cf = thighCF,
			color = C.MidnightSlate, parent = m })
		local hoofCF = baseCF * CFrame.new(leg.x * 1.05, 0.25, leg.z + (if leg.z < 0 then -0.2 else 0.2))
		mk({ name = leg.name .. "_Hoof", size = Vector3.new(0.9, 0.5, 1.0), cf = hoofCF,
			color = C.VoidBlack, parent = m })
	end

	-- Torso, Chest, 2 Spine Plates, Skull, Jaw, 2 Eyes (8 parts)
	local torsoCF = baseCF * CFrame.new(0, 2.7, 0) * CFrame.Angles(rad(-6), 0, 0)
	mk({ name = "CarapaceTorso", size = Vector3.new(2.6, 2.4, 3.2), cf = torsoCF,
		color = C.MidnightSlate, parent = m })
	mk({ name = "ChestPlate", size = Vector3.new(2.2, 1.8, 1.4), cf = torsoCF * CFrame.new(0, -0.4, -1.2) * CFrame.Angles(rad(18), 0, 0),
		color = C.VoidBlack, parent = m })
	for i = 1, 2 do
		local spineCF = torsoCF * CFrame.new(0, 1.3, 0.8 - (i - 1) * 1.2)
		mk({ name = "SpinePlate", size = Vector3.new(0.5, 0.7, 0.7), cf = spineCF,
			color = C.AmethystDark, parent = m, wedge = true })
	end
	local headCF = baseCF * CFrame.new(0, 4.1, -1.6) * CFrame.Angles(rad(10), 0, 0)
	mk({ name = "BeastSkull", size = Vector3.new(1.9, 1.5, 2.0), cf = headCF,
		color = C.MidnightSlate, parent = m })
	mk({ name = "HeavyUnderjaw", size = Vector3.new(1.5, 0.7, 1.5), cf = headCF * CFrame.new(0, -0.8, -0.3) * CFrame.Angles(rad(12), 0, 0),
		color = C.VoidBlack, parent = m })
	-- Eyes: deep-set, pulled back into the skull so the brow shades them. The
	-- lid takes the carapace colour rather than black -- on an armoured head
	-- that reads as a plate, where black reads as a hole.
	for side = -1, 1, 2 do
		local tag = if side < 0 then "Left" else "Right"
		-- ON the surface at 1.0, not inboard of it. "Deep-set" is the brow
		-- hanging over the eye, not the eye buried in the skull -- sinking it
		-- does not read as a heavy brow, it reads as no eye at all.
		voidEye(m, tag, headCF * CFrame.new(side * 0.65, 0.1, -1.00), 0.42,
			"deepset", C.MidnightSlate, 0.16)
	end

	-- Dual Crystal Antlers (8 parts)
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

	-- 4 Alien Leaves (direct children named "Leaf")
	for side = -1, 1, 2 do
		local sLeafCF = torsoCF * CFrame.new(side * 1.4, 0.8, -0.6) * CFrame.Angles(rad(-20), rad(side * 45), rad(side * 30))
		mk({ name = "Leaf", size = Vector3.new(0.65, 2.2, 0.25), cf = sLeafCF,
			color = C.AmethystPale, parent = m, wedge = true })
		local fLeafCF = torsoCF * CFrame.new(side * 1.3, 0.4, 0.8) * CFrame.Angles(rad(15), rad(side * 50), rad(side * 25))
		mk({ name = "Leaf", size = Vector3.new(0.55, 1.8, 0.22), cf = fLeafCF,
			color = C.Amethyst, parent = m, wedge = true })
	end

	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyanGlow
	light.Brightness = 1.5
	light.Range = 10
	light.Parent = m:FindFirstChild("BeastSkull") or m

	return m
end

--==============================================================================
-- 5. SUPERNOVUS (Mythic, 8.20 studs) -- Budget: 39 parts (+ 1 Base = 40 parts)
--==============================================================================
local function buildSupernovus(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Supernovus"
	m.Parent = parent

	-- Limbs: 6 Titan Crusher Legs (TitanThigh + TitanClaw = 12 parts)
	for _, leg in ipairs({
		{ name = "FrontLeft",  x = -1.8, z = -1.6, pitch = rad(-18), roll = rad(-15), size = 1.1 },
		{ name = "FrontRight", x =  1.8, z = -1.6, pitch = rad(-18), roll = rad( 15), size = 1.1 },
		{ name = "MidLeft",    x = -2.0, z =  0.1, pitch = rad(  0), roll = rad(-20), size = 1.0 },
		{ name = "MidRight",   x =  2.0, z =  0.1, pitch = rad(  0), roll = rad( 20), size = 1.0 },
		{ name = "RearLeft",   x = -1.8, z =  1.8, pitch = rad( 20), roll = rad(-15), size = 1.2 },
		{ name = "RearRight",  x =  1.8, z =  1.8, pitch = rad( 20), roll = rad( 15), size = 1.2 },
	}) do
		local legCF = baseCF * CFrame.new(leg.x, 1.8, leg.z) * CFrame.Angles(leg.pitch, 0, leg.roll)
		mk({ name = leg.name .. "_TitanThigh", size = Vector3.new(0.9 * leg.size, 1.7 * leg.size, 1.0 * leg.size), cf = legCF,
			color = C.VoidBlack, parent = m })
		local footCF = baseCF * CFrame.new(leg.x * 1.1, 0.25, leg.z + (if leg.z < 0 then -0.3 else 0.3))
		mk({ name = leg.name .. "_TitanClaw", size = Vector3.new(1.1 * leg.size, 0.5, 1.3 * leg.size), cf = footCF,
			color = C.MidnightSlate, parent = m })
	end

	-- Titan Carapace, Dragon Neck & Skull (8 parts)
	local bodyCF = baseCF * CFrame.new(0, 2.8, 0)
	mk({ name = "TitanCarapace", size = Vector3.new(3.8, 2.6, 4.4), cf = bodyCF,
		color = C.VoidBlack, parent = m })
	local neckCF = bodyCF * CFrame.new(0, 0.8, -2.4) * CFrame.Angles(rad(-20), 0, 0)
	mk({ name = "DragonNeck", size = Vector3.new(1.8, 1.8, 2.0), cf = neckCF,
		color = C.MidnightSlate, parent = m })
	local skullCF = neckCF * CFrame.new(0, 0.9, -1.1) * CFrame.Angles(rad(15), 0, 0)
	mk({ name = "DragonSkull", size = Vector3.new(2.2, 1.6, 2.4), cf = skullCF,
		color = C.VoidBlack, parent = m })
	mk({ name = "RoaringJaw", size = Vector3.new(1.8, 0.7, 1.8), cf = skullCF * CFrame.new(0, -0.85, -0.4) * CFrame.Angles(rad(22), 0, 0),
		color = C.MidnightSlate, parent = m })
	mk({ name = "MawCore", size = Vector3.new(1.1, 1.1, 1.1), cf = skullCF * CFrame.new(0, -0.4, -0.5),
		color = C.StarIvory, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	-- Eyes: pulsar. The only lit-from-inside eye in the biome, and the reason
	-- the Mythic reads hot against four cold ones. It is also why this species
	-- sits at 46 parts against a 25-40 band -- a deliberate exception, the same
	-- one Suncrown already carries.
	for side = -1, 1, 2 do
		local tag = if side < 0 then "Left" else "Right"
		-- The skull is 2.4 deep. At -1.0 the eye sat a fifth of a stud INSIDE
		-- it and the whole face was a blank black box.
		voidEye(m, tag, skullCF * CFrame.new(side * 0.75, 0.2, -1.20), 0.50,
			"pulsar", C.VoidBlack)
	end
	mk({ name = "BrowHorn", size = Vector3.new(0.65, 1.8, 0.55), cf = skullCF * CFrame.new(0, 1.0, 0.2) * CFrame.Angles(rad(-25), 0, 0),
		color = C.AmethystPale, parent = m, wedge = true })

	-- 4 Giant Alien Leaves (direct children named "Leaf")
	for _, frond in ipairs({
		{ x = -2.1, z = -0.8, pitch = rad(-25), roll = rad(-40) },
		{ x =  2.1, z = -0.8, pitch = rad(-25), roll = rad( 40) },
		{ x = -2.1, z =  1.2, pitch = rad( 25), roll = rad(-45) },
		{ x =  2.1, z =  1.2, pitch = rad( 25), roll = rad( 45) },
	}) do
		local fCF = bodyCF * CFrame.new(frond.x, 1.2, frond.z) * CFrame.Angles(frond.pitch, 0, frond.roll)
		mk({ name = "Leaf", size = Vector3.new(0.85, 3.2, 0.35), cf = fCF,
			color = C.AmethystPale, parent = m, wedge = true })
	end

	-- Dorsal Galaxy Lotus: Stem + 3 Outer Petals + 3 Inner Petals (7 parts)
	local lotusBaseCF = bodyCF * CFrame.new(0, 1.4, 0.2)
	mk({ name = "LotusStem", size = Vector3.new(1.6, 1.4, 1.6), cf = lotusBaseCF,
		color = C.AmethystDark, parent = m, shape = Enum.PartType.Cylinder })
	local flowerCF = lotusBaseCF * CFrame.new(0, 1.2, 0)
	for i = 1, 3 do
		local a = rad(i * 120)
		local pCF = flowerCF * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.4, 1.5) * CFrame.Angles(rad(38), 0, 0)
		mk({ name = "OuterPetal", size = Vector3.new(1.2, 2.2, 0.28), cf = pCF,
			color = C.MidnightSlate, parent = m, wedge = true })
	end
	for i = 1, 3 do
		local a = rad(i * 120 + 60)
		local pCF = flowerCF * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.9, 0.95) * CFrame.Angles(rad(25), 0, 0)
		mk({ name = "InnerPetal", size = Vector3.new(1.0, 1.9, 0.22), cf = pCF,
			color = C.PulsarGold, parent = m, wedge = true })
	end

	-- Tilted 3-Segment Orbital Ring (3 parts) + 1 Comet Satellite (1 part) = 4 parts
	local ringTilt = flowerCF * CFrame.new(0, 1.4, 0) * CFrame.Angles(rad(22), rad(35), 0)
	for i = 1, 3 do
		local a = rad(i * 120)
		local arcCF = ringTilt * CFrame.Angles(0, a, 0) * CFrame.new(0, 0, 2.2)
		mk({ name = "OrbitalArc", size = Vector3.new(2.8, 0.2, 0.3), cf = arcCF,
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end
	local satCF = ringTilt * CFrame.Angles(0, rad(45), 0) * CFrame.new(0, 0, 2.6)
	mk({ name = "CometSatellite", size = Vector3.new(0.65, 0.65, 0.65), cf = satCF,
		color = C.PulsarGold, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })

	-- Central Supernova Pulsar Core (1 part) + Crown Flares (3 parts) = 4 parts
	local core = mk({ name = "SupernovaCore", size = Vector3.new(2.0, 2.0, 2.0), cf = flowerCF * CFrame.new(0, 1.4, 0),
		color = C.StarIvory, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })
	local flareCF = flowerCF * CFrame.new(0, 2.8, 0)
	mk({ name = "CrownFlareMain", size = Vector3.new(0.55, 1.6, 0.55), cf = flareCF,
		color = C.PulsarGold, parent = m, shape = Enum.PartType.Cylinder, material = Enum.Material.Neon })
	for side = -1, 1, 2 do
		local fCF = flareCF * CFrame.Angles(0, rad(side * 90), 0) * CFrame.new(0, 0.4, 0.45) * CFrame.Angles(rad(25), 0, 0)
		mk({ name = "CrownSpike", size = Vector3.new(0.35, 1.2, 0.25), cf = fCF,
			color = C.StarIvory, parent = m, wedge = true, material = Enum.Material.Neon })
	end

	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyanGlow
	light.Brightness = 3.0
	light.Range = 16
	light.Parent = core

	-- Sparks Attachment
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
	p.Rate = 24
	p.Speed = NumberRange.new(1.5, 3.0)
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
-- `hs` is height: the ratio between the tier's frame and the height this species
-- was authored at. `gs` is the damped horizontal girth spread, and it is
-- optional -- a caller that omits it gets 1 and height-only scaling.
--
-- Girth arriving here at all is the fix for a real gap: this took one scalar, so
-- a Colossal was a uniformly enlarged Tiny -- same silhouette, same proportions,
-- no added heft -- while Tanglemire's creatures were getting broader across the
-- ladder. Measured tier 1 to tier 7, width over height: novaorb +9.5%,
-- cosmospire +7.6%, voidpetal +10.3%, astralhorn +8.9%, supernovus +9.6%.
--
-- MEASURE THAT WITH WORLD EXTENTS, NOT GetBoundingBox. It reports in the PIVOT's
-- frame, and these models pivot on a rolled cylinder, so X and Y come back
-- swapped -- the same trap that once put a Bellchime's name plate inside its own
-- head. A review that used it will report numbers that look plausible and are
-- not this shape.
--==============================================================================
function StarbloomForms.Build(model: Model, id: string, at: CFrame, hs: number, gsOpt: number?): boolean
	local fn = BUILDERS[id]
	if not fn then
		return false
	end
	-- `or 1` alone would pass NaN and negatives straight through into every part
	-- CFrame in the model, where they are unrecoverable.
	local gs = if type(gsOpt) == "number" and gsOpt == gsOpt and gsOpt > 0
		then gsOpt
		else 1
	local scratch = Instance.new("Folder")
	scratch.Parent = model
	local built = fn(scratch, at)

	if math.abs(hs - 1) > 1e-6 or math.abs(gs - 1) > 1e-6 then
		for _, d in ipairs(built:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CFrame = at * scaled(at:ToObjectSpace(d.CFrame), hs, gs)
				d.Size = d.Size * hs
			elseif d:IsA("Attachment") then
				-- An attachment is a point ON a part, so it takes the same
				-- horizontal spread its part just took. Scaling it by height
				-- alone leaves it behind as girth pushes the part outward.
				d.Position = Vector3.new(d.Position.X * hs * gs,
					d.Position.Y * hs, d.Position.Z * hs * gs)
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
