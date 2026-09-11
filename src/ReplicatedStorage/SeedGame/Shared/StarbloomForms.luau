--!strict
--==============================================================================
-- STARBLOOM FORMS (BIOME 5) -- 80% CREATURE / 20% PLANT
--
-- Primitive-sculpted alien cosmic creatures with standing locomotion limbs,
-- bioluminescent alien leaves, and per-species cosmic palettes.
--
-- THE PART BUDGET, HONESTLY. The art bible band is 25-40 per grown plant.
--
--     novaorb 30    cosmospire 37    voidpetal 39    astralhorn 37
--     supernovus 81
--
-- Four sit inside it. Supernovus does not and never did: the Mythic is a
-- documented exception. It was 46 for its eyes and crown, 70 once its six legs
-- got real feet, and it is 81 as the Cosmic Star Colossus -- inside the 70-85 the
-- owner set for that rebuild on 2026-09-11. Its builder's banner says what every
-- part is for.
--
-- Species:
--   1. Novaorb     (Rare)       - 4.60 studs - Rotund alien toad-biped with shoulder leaf fronds & orbiting motes
--   2. Cosmospire  (Rare)       - 7.40 studs - Tall 4-legged stilt mantis with dorsal spire & crystal leaf wings
--   3. Voidpetal   (Epic)       - 5.60 studs - Prowling void panther predator with 6-petal orchid neck mane & leaf tails
--   4. Astralhorn  (Legendary)  - 6.90 studs - Heavy 4-legged armored stag-beast with spine fronds & crystal antlers
--   5. Supernovus  (Mythic)     - 8.20 studs - Armored cosmic star colossus: obsidian mantles & pulsar geodes, crescent tusks, 4 pillar legs & a galaxy halo
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
-- SITTING ON THE PLANE, NOT THROUGH IT
--
-- Half the thickness is the right lift only for a box that is not turned. Every
-- foot below is turned, and a rotated box reaches further below its own centre
-- than half its height -- the reach is its three half-extents projected onto
-- world Y, which is what the three axis vectors give.
--
-- The same four lines EmberrootForms works its roots out with. Copied rather
-- than shared because that file is approved art and this one has no business
-- reaching into it for a formula; if a third form needs it, that is the moment
-- it earns a home of its own.
--==============================================================================
local function groundLift(size: Vector3, rot: CFrame): number
	return size.X * 0.5 * math.abs(rot.RightVector.Y)
		+ size.Y * 0.5 * math.abs(rot.UpVector.Y)
		+ size.Z * 0.5 * math.abs(rot.LookVector.Y)
end

--==============================================================================
-- A LIMB SHAFT THAT OVERRUNS BOTH OF ITS OWN JOINTS
--
-- `from` is the joint at the top of the segment, `drop` is how far down that
-- frame's own -Y the next joint sits, and the two `over` values are how far the
-- MASS runs past each of them.
--
-- THE OVERRUN IS THE WHOLE FIX. A segment sized exactly joint-to-joint meets the
-- next one face to face, and a face-to-face meeting is a seam: it opens the
-- moment the girth curve spreads the parts apart, and it opens again anywhere
-- the two segments are not perfectly parallel -- which at a bend is everywhere.
-- Running past puts the seam INSIDE the adjoining mass, where no pose can show
-- it. Cosmospire's four legs were built the other way and its knee was measured
-- open before this.
--
-- It also means a segment's LENGTH is derived from the skeleton rather than
-- typed in beside it, so moving a joint moves the metal with it instead of
-- leaving a gap for somebody to find later.
--==============================================================================
local function shaft(name: string, from: CFrame, drop: number, overTop: number,
	overBot: number, w: number, d: number, colour: Color3, parent: Instance): BasePart
	local len = drop + overTop + overBot
	return mk({ name = name, size = Vector3.new(w, len, d),
		cf = from * CFrame.new(0, overTop - len * 0.5, 0),
		color = colour, parent = parent })
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
-- The Mythic's is the exception that proves the rule: the only eye that is a
-- slit of cyan light under a brow rather than a mark on a dark ball.
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

	elseif style == "titan" then
		-- A SLIT OF LIGHT UNDER A BROW. The colossus's eye is a narrow cyan cut,
		-- the only line of light in a family of marks on dark balls, and a line
		-- still reads across a plot where a pinprick is gone. Block sclera,
		-- because a Ball renders as a sphere of its smallest axis and can never
		-- be a slit. `eyeCF` carries the roll that angles the pair into a frown.
		mk({ name = tag .. "Eye", size = Vector3.new(dia * 1.30, dia * 0.46, dia * 0.60),
			cf = eyeCF, color = VOID_SCLERA, parent = m, smooth = true })
		mk({ name = tag .. "Pupil", size = Vector3.new(dia * 1.06, dia * 0.16, dia * 0.14),
			cf = eyeCF * CFrame.new(0, 0, -dia * 0.30),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon, smooth = true })

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
	-- The slit is wider than the eye it replaced, so its lid is too: a blink
	-- that left the two ends of a line of light showing would not be a blink.
	mk({ name = tag .. "Lid",
		size = Vector3.new(dia * (if style == "titan" then 1.44 else 1.24), dia * LID_H, dia * 0.62),
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
-- 2. COSMOSPIRE (Rare, 7.40 studs) -- 36 parts (+ 1 Base = 37), 16 of them limb
--==============================================================================
local function buildCosmospire(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Cosmospire"
	m.Parent = parent

	--==========================================================================
	-- FOUR STILT LEGS, BUILT DOWN A SKELETON RATHER THAN PLACED BESIDE ONE
	--
	-- WHAT WAS WRONG, IN MEASURED STUDS. Three parts hung off the hip frame with
	-- no relationship between them: a femur; a tibia rotated 28 degrees about a
	-- point 0.85 studs BELOW the femur's own bottom face; and a claw positioned
	-- from the plant's origin and not from the leg at all.
	--
	--   * The knee stood 0.0104 studs OPEN at authored scale -- a hairline at
	--     Tiny and half a stud of daylight at Colossal, where the height scale
	--     is 50x.
	--   * The claw was not at the end of the leg. It sat 1.538 studs (front) and
	--     1.660 (rear) from its own shank's tip, stuck against the SIDE of the
	--     shank and forward of the hip, while the shank reached backward past
	--     it. The nearest claw to a front shank's tip was the REAR leg's, 0.383
	--     studs away.
	--   * The shank tips finished 0.0196 studs UNDER the base plane, so the
	--     whole model's lowest corner was -0.2002 and the legs stood in the
	--     floor rather than on it.
	--
	-- It was a rig fault as well as an art one. The shank kicked so far back
	-- that its centre came within 1.03:1 of the OPPOSITE hip -- PlantSway hangs
	-- every limb part on the nearest hip in plan view, and the two legs of a
	-- diagonal pair walk in antiphase, so three per cent more lean would have
	-- torn the shank off its own femur on every stride.
	--
	-- WHAT IT IS NOW. A chain: hip -> femur -> knee -> shank -> claw. Each joint
	-- is a CFrame, each mass is built from the joint above it, and every segment
	-- runs PAST the joint at both of its ends so the seam is inside the next
	-- mass (see `shaft`). The bend is a knuckle that is thicker than either
	-- shaft and turns half the angle itself, so the leg changes direction
	-- through a joint rather than at a butt weld between two rods.
	--
	-- The counter-bend is the other half of the fix. The shank now turns BACK
	-- toward vertical instead of continuing the femur's lean, which is what a
	-- stilt-walker's leg does and what puts each foot under its own hip: the
	-- nearest-hip margin is 1.97:1 at the claw and 1.32:1 at the shank.
	--
	-- The four legs are not four copies. Splay, claw length and toe-out differ
	-- per leg from the table -- deliberately, and written down rather than
	-- rolled, because two servers have to build the same creature.
	--==========================================================================
	--==========================================================================
	-- WHERE THE KNEE SITS IS A RIG DECISION, NOT ONLY A DRAWING ONE
	--
	-- PlantSway takes the leg parts in the upper 45% of the leg's own height as
	-- the hip anchors and hangs everything else on the nearest one. A knee that
	-- drifts above that line becomes an anchor of its own, and four legs would
	-- come back as eight. 1.35 keeps every knee below it with 0.08 studs to
	-- spare at authored scale -- and the margin is a RATIO, so it survives both
	-- scale curves.
	--==========================================================================
	local FEMUR_DROP, KNEE_BEND, TIBIA_DROP = 1.35, rad(16), 0.66
	for _, legSpec in ipairs({
		{ x = -0.7, z = -0.5, pitch = rad(-18), roll = rad(-15), fore =  1,
			yaw = rad( 13), spin = 0, claw = 1.06, kneeYaw = rad(-4) },
		{ x =  0.7, z = -0.5, pitch = rad(-18), roll = rad( 15), fore =  1,
			yaw = rad(-10), spin = 0, claw = 0.97, kneeYaw = rad( 3) },
		{ x = -0.7, z =  0.6, pitch = rad( 20), roll = rad(-15), fore = -1,
			yaw = rad( 16), spin = math.pi, claw = 0.92, kneeYaw = rad( 5) },
		{ x =  0.7, z =  0.6, pitch = rad( 20), roll = rad( 15), fore = -1,
			yaw = rad(-12), spin = math.pi, claw = 1.01, kneeYaw = rad(-6) },
	}) do
		local hipCF = baseCF * CFrame.new(legSpec.x, 2.30, legSpec.z)
			* CFrame.Angles(legSpec.pitch, 0, legSpec.roll)
		local kneeCF = hipCF * CFrame.new(0, -FEMUR_DROP, 0)
		local shinCF = kneeCF * CFrame.Angles(legSpec.fore * KNEE_BEND, 0, 0)
		local ankleCF = shinCF * CFrame.new(0, -TIBIA_DROP, 0)

		-- SLIMMER THAN THE ROD IT REPLACES, not thicker. The first cut ran 0.52
		-- x 0.46 against an authored 0.45 square and the four legs came back as
		-- a pair of trousers -- this is a spire, and the brief for it is light
		-- and elegant, so the connection is bought with overlap and a knuckle
		-- rather than with mass.
		--
		-- Flattened across the body rather than square, and buried 0.80 studs
		-- into the thorax so the shoulder stays shut through the whole swing --
		-- this is the one joint in the leg whose two halves do not move
		-- together, because the body does not turn with the limb.
		shaft("Femur", hipCF, FEMUR_DROP, 0.80, 0.30, 0.46, 0.42,
			C.MidnightSlate, m)

		-- The knuckle: wider than either shaft, turning half the bend itself so
		-- neither meets it square.
		--
		-- IT TAKES THE SHANK'S COLOUR, NOT ITS OWN. The first cut painted it
		-- Indigo, a step lighter than both neighbours, and a light band across a
		-- dark leg reads as a cuff or a bracelet however well it is shaped --
		-- worse here, because PlantSway's hip line forces the knee low and a
		-- bright band low on a leg is an ankle. In the shank's colour the leg
		-- reads in two zones, dark thigh and pale lower leg, and the joint is a
		-- change of SHAPE where they meet.
		mk({ name = "Knee", size = Vector3.new(0.52, 0.62, 0.64),
			cf = kneeCF * CFrame.Angles(legSpec.fore * KNEE_BEND * 0.5,
				legSpec.kneeYaw, 0),
			color = C.AmethystDark, parent = m })

		-- Slimmer again, and deeper than it is wide, so the two shafts are not
		-- the same rod twice. It ends inside the claw, never above it.
		shaft("Tibia", shinCF, TIBIA_DROP, 0.30, 0.30, 0.34, 0.38,
			C.AmethystDark, m)

		--======================================================================
		-- THE CLAW IS THE FOOT, AND IT RECEIVES THE SHANK
		--
		-- LEVEL, AND YAWED OUTWARD RATHER THAN FOLLOWING THE LEG'S ROLL. A foot
		-- lies on the ground; a sole carrying the leg's fifteen degrees of roll
		-- stands on one edge with daylight under the other. So the claw is built
		-- in a frame that is turned but never tipped, and only the ankle's X and
		-- Z come down the leg.
		--
		-- ITS THICK END IS THE SOCKET. A WedgePart is solid at +Z and tapers to a
		-- knife edge at -Z, so setting the shank into the +Z end buries the joint
		-- inside the deepest part of the foot and leaves the taper pointing
		-- forward as the claw. The offset is 0.30 of the length rather than half
		-- of it, which leaves the ankle 0.20 of the length in from the back face
		-- -- just past the shank's own half-depth of 0.21, and therefore just
		-- enough to keep its rear corners from poking out of the heel.
		--
		-- Lifted by the box's rotated corner reach, not by half its height, so
		-- the sole rests ON the plane rather than a guessed distance above it.
		--======================================================================
		-- THE BACK PAIR POINT BACKWARD. Four feet all facing forward put the rear
		-- claws' tips within a tenth of a stud of the front claws' heels -- the
		-- stance closed up into a huddle, which is neither how a four-legged
		-- thing stands nor what the ring of hips underneath it says. Half a turn
		-- on the rear pair opens it and costs nothing: a WedgePart is symmetric
		-- about that axis, so the ankle is still in the thick end and the taper
		-- simply trails the other way.
		--
		-- TOE-OUT IS PAID FOR IN WIDTH, so it is spent sparingly. A foot turned
		-- out by an angle marches outward by roughly 0.8 of its own length times
		-- the sine of it, twice over -- once for the forward offset and once for
		-- its own half-length -- and this is a tall spire, not a guardian. The
		-- first cut ran 26 and 31 degrees and measured 3.85 studs across against
		-- an authored 3.20; these read as turned out and cost a fifteenth of it.
		local ankleL = baseCF:ToObjectSpace(ankleCF).Position
		local clawLen = 1.06 * legSpec.claw
		local clawSize = Vector3.new(0.48, 0.36, clawLen)
		local clawRot = CFrame.Angles(0, legSpec.yaw + legSpec.spin, 0)
		mk({ name = "StiltClaw", size = clawSize,
			cf = baseCF * CFrame.new(ankleL.X, 0, ankleL.Z) * clawRot
				* CFrame.new(0, groundLift(clawSize, clawRot), -clawLen * 0.30),
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
-- 3. VOIDPETAL (Epic, 5.60 studs) -- 38 parts (+ 1 Base = 39), 16 of them limb
--==============================================================================
local function buildVoidpetal(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Voidpetal"
	m.Parent = parent

	--==========================================================================
	-- FOUR CAT LEGS, AIMED AT THEIR OWN PAWS
	--
	-- WHAT WAS WRONG. One haunch and one flat pad per leg, and the pad was
	-- positioned from the plant's origin rather than from the leg -- the same
	-- fault Cosmospire and Supernovus carried. Measured at authored scale the
	-- haunch's lowest corner stopped 0.2777 studs above its pad at the front and
	-- 0.2527 at the rear, on all four legs: at Colossal, where the height scale
	-- is 50x, between 12.6 and 13.9 studs of daylight under a prowling panther.
	--
	-- The haunch also leaned AWAY from its own paw. The front pair pitch back by
	-- fifteen degrees, so the bottom of the haunch travels backward as it
	-- descends, while the pad sat 0.3 studs FORWARD of the hip. Nothing about
	-- the leg pointed at the foot it was supposed to end in.
	--
	-- WHAT IT IS NOW: haunch -> shin -> pad -> claw, four parts per leg.
	--
	-- THE SHIN IS AIMED, NOT ANGLED. Its direction is solved from two points --
	-- the hock at the bottom of the haunch, and where the paw actually stands --
	-- rather than typed in as a rotation and hoped over. That is what keeps the
	-- foot under the leg when either end moves, and it is why a leg here can
	-- carry a strong bend without opening: the shaft is built along the line
	-- between its own joints by construction.
	--
	-- IT ALSO BUYS THE POSE FOR FREE. The front haunch leans back and its shin
	-- reaches forward; the rear haunch leans forward and its shin tucks back
	-- under the body. Two bends in opposite directions is the reaching foreleg
	-- and the folded hind leg of a cat, and neither is an angle anybody had to
	-- pick -- they fall out of where the four paws are planted.
	--
	-- ONE CLAW PER PAW, NOT THREE. The pad is 0.68 studs across on a creature
	-- 5.6 studs tall; at that size a second and third toe are two more dark
	-- pieces inside the same silhouette, which the art bible calls visual static
	-- rather than detail. One broad tapered claw, splayed differently on each
	-- foot, is what actually reads -- and it keeps this species inside the
	-- 25-40 band at 39 rather than pushing it to 47.
	--==========================================================================
	--==========================================================================
	-- THE ANKLE SITS HIGHER THAN IT LOOKS LIKE IT NEEDS TO
	--
	-- A shin raked thirty-seven degrees reaches much further below its own end
	-- than half its thickness: its DEPTH half-extent projects 0.56 onto world Y
	-- at that angle, and the first cut put the rear-right shin's bottom corner
	-- 0.0226 studs under the base plane -- 1.13 studs at Colossal, a leg through
	-- the floor of somebody's plot. 0.34 with a 0.15 overrun clears it by 0.07
	-- and still buries the shin 0.17 under the pad's top surface.
	--==========================================================================
	local HAUNCH_DROP, ANKLE_Y = 0.62, 0.34
	for _, leg in ipairs({
		{ name = "FL", x = -0.85, z = -1.1, pitch = rad(-15), roll = rad(-10),
			pawX = -0.96, pawZ = -1.32, yaw = rad( 10), toeYaw = rad( 13), claw = 1.00 },
		{ name = "FR", x =  0.85, z = -1.1, pitch = rad(-15), roll = rad( 10),
			pawX =  0.94, pawZ = -1.28, yaw = rad(-8),  toeYaw = rad(-16), claw = 0.94 },
		{ name = "BL", x = -0.95, z =  1.1, pitch = rad( 22), roll = rad(-12),
			pawX = -1.06, pawZ =  1.22, yaw = rad( 13), toeYaw = rad(-11), claw = 1.06 },
		{ name = "BR", x =  0.95, z =  1.1, pitch = rad( 22), roll = rad( 12),
			pawX =  1.04, pawZ =  1.26, yaw = rad(-11), toeYaw = rad( 15), claw = 0.98 },
	}) do
		local hipCF = baseCF * CFrame.new(leg.x, 1.40, leg.z)
			* CFrame.Angles(leg.pitch, 0, leg.roll)

		-- Broad at the shoulder, and buried 0.36 into the torso so the one joint
		-- whose halves do not move together stays shut through the swing.
		shaft(leg.name .. "_Haunch", hipCF, HAUNCH_DROP, 0.36, 0.24, 0.62, 0.72,
			C.AmethystDark, m)

		-- The hock, and the line from it to the ground.
		local hockL = baseCF:ToObjectSpace(hipCF * CFrame.new(0, -HAUNCH_DROP, 0)).Position
		local footL = Vector3.new(leg.pawX, ANKLE_Y, leg.pawZ)
		local reach = (hockL - footL)
		local upv = reach.Unit
		-- Cross with the plant's own +Z: `upv` is close to vertical on every leg,
		-- so this can never be the degenerate case that a lookAt would hit.
		local right = upv:Cross(Vector3.new(0, 0, 1)).Unit
		local shinCF = baseCF * CFrame.fromMatrix(hockL, right, upv, right:Cross(upv))
		shaft(leg.name .. "_Shin", shinCF, reach.Magnitude, 0.22, 0.15, 0.42, 0.46,
			C.MidnightSlate, m)

		--======================================================================
		-- THE PAD, AND ONE CLAW
		--
		-- Level and yawed: a paw lies on the ground, and a pad carrying the leg's
		-- ten degrees of roll stands on one edge. The shin ends INSIDE it, 0.15
		-- studs past the ankle and 0.17 below the pad's top surface, so there is
		-- no cut face anywhere on the outside of the foot.
		--
		-- Each claw is lifted by its own rotated corner reach rather than by half
		-- its height, so the tip rests ON the plane instead of a guessed distance
		-- above it, and each is splayed and sized differently: a row of four
		-- identical feet is the thing that makes a quadruped read as furniture.
		--======================================================================
		local pawSize = Vector3.new(0.68, 0.38, 0.82)
		local groundCF = baseCF * CFrame.new(leg.pawX, 0, leg.pawZ)
		mk({ name = leg.name .. "_Paw", size = pawSize,
			cf = groundCF * CFrame.Angles(0, leg.yaw, 0)
				* CFrame.new(0, pawSize.Y * 0.5, -0.06),
			color = C.VoidBlack, parent = m })

		local toeSize = Vector3.new(0.56, 0.26, 0.62 * leg.claw)
		local toeRot = CFrame.Angles(0, leg.yaw + leg.toeYaw, 0)
		mk({ name = leg.name .. "_Toe", size = toeSize,
			cf = groundCF * toeRot * CFrame.new(0, groundLift(toeSize, toeRot),
				-(pawSize.Z * 0.5 + toeSize.Z * 0.5 - 0.28)),
			color = C.MidnightSlate, parent = m, wedge = true })
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
-- 4. ASTRALHORN (Legendary, 6.90 studs) -- 36 parts (+ 1 Base = 37), 12 of them limb
--==============================================================================
local function buildAstralhorn(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Astralhorn"
	m.Parent = parent

	--==========================================================================
	-- FOUR PILLAR LEGS, AND FOUR HOOVES THAT ARE ON THE END OF THEM
	--
	-- WHAT WAS WRONG, and it is the same thing a fourth time: the hoof was
	-- positioned from the plant's origin rather than from the leg. Measured at
	-- authored scale the column's lowest corner stopped +0.2029 studs above its
	-- hoof at the front and +0.1950 at the rear -- 10.1 and 9.8 studs of daylight
	-- at Colossal -- and the column's own bottom centre sat 0.38 studs from the
	-- hoof's in Z, in the direction AWAY from it.
	--
	-- WHAT IT IS NOW: column -> hoof -> toe, three parts per leg.
	--
	-- THREE, NOT FOUR, AND NO SECOND SHAFT. A pillar leg is meant to have no
	-- visible bend -- that is what "pillar" means, and it is the difference
	-- between this and the mantis two species up. So the parts go on the FOOT,
	-- where the read was actually missing, and Astralhorn lands at 37 rather than
	-- 41: inside the art bible band, which Cosmospire and Voidpetal also stayed
	-- inside and only Supernovus could not.
	--
	-- THE COLUMN IS EXTENDED, NOT MOVED. Its top is exactly where it was, and its
	-- lower end grows by however much it takes to put its cut face inside the
	-- hoof -- computed from the box's own rotated corner reach, because the front
	-- and rear pairs sit at different pitches.
	--
	-- THE HOOF IS DEEP BECAUSE THE COLUMN IS OFFSET. The stance is authored, so
	-- the foot goes where the foot went and the column arrives off-centre in it;
	-- a hoof only 1.0 deep would have left a third of the column's cut face
	-- hanging out of the back with daylight under it. At 1.44 deep with the
	-- offset held to 0.27, the column's rear edge lands exactly on the hoof's,
	-- and the ground the four feet cover is the same 3.70 studs it always was.
	--==========================================================================
	local HOOF = Vector3.new(1.24, 0.62, 1.44)
	for _, leg in ipairs({
		{ name = "FL", x = -1.2, z = -1.1, pitch = rad(-14), roll = rad(-10),
			reach = -0.27, yaw = rad( 11), toe = 1.00, toeYaw = rad(  6) },
		{ name = "FR", x =  1.2, z = -1.1, pitch = rad(-14), roll = rad( 10),
			reach = -0.27, yaw = rad(-9),  toe = 0.94, toeYaw = rad( -8) },
		{ name = "BL", x = -1.2, z =  1.2, pitch = rad( 16), roll = rad(-10),
			reach =  0.28, yaw = rad( 12), toe = 1.05, toeYaw = rad( -5) },
		{ name = "BR", x =  1.2, z =  1.2, pitch = rad( 16), roll = rad( 10),
			reach =  0.28, yaw = rad(-10), toe = 0.98, toeYaw = rad(  7) },
	}) do
		local thighCF = baseCF * CFrame.new(leg.x, 1.6, leg.z)
			* CFrame.Angles(leg.pitch, 0, leg.roll)
		local rot = thighCF - thighCF.Position

		local plain = Vector3.new(0.85, 1.5, 0.9)
		local lowest = 1.6 - groundLift(plain, rot)
		local ext = math.max((lowest - HOOF.Y * 0.55) / rot.UpVector.Y, 0.10)
		mk({ name = leg.name .. "_PillarThigh",
			size = Vector3.new(0.85, 1.5 + ext, 0.9),
			cf = thighCF * CFrame.new(0, -ext * 0.5, 0),
			color = C.MidnightSlate, parent = m })

		--======================================================================
		-- THE HOOF, LEVEL AND FLARED
		--
		-- Wider and deeper than the column standing in it, so the leg visibly
		-- flares into the ground rather than stopping on a tile, and level rather
		-- than carrying the leg's ten degrees of roll -- a hoof stands on its
		-- whole underside, not on one edge.
		--
		-- Pulled 12% inboard of the column, because the column's own bottom has
		-- drifted outward with the extension and the foot has no reason to follow
		-- it out there. Measured at 5%: the toes came out 2.25 studs from the
		-- centreline against the widest leaf's 2.08, so the FEET became this
		-- creature's widest point and it gained 8% across. At 12% they sit inside
		-- the crown again and the width is the authored 4.15.
		--======================================================================
		local legEnd = baseCF:ToObjectSpace(thighCF
			* CFrame.new(0, -(0.75 + ext), 0)).Position
		local groundCF = baseCF * CFrame.new(legEnd.X * 0.88, 0, legEnd.Z + leg.reach)
		mk({ name = leg.name .. "_Hoof", size = HOOF,
			cf = groundCF * CFrame.Angles(0, leg.yaw, 0) * CFrame.new(0, HOOF.Y * 0.5, 0),
			color = C.VoidBlack, parent = m })

		-- The toe wall, tapering forward off the front of it. Without this the
		-- hoof finishes as a plain rectangular pad, which is the one shape the
		-- art bible names for feet -- and it is what breaks the outline so the
		-- foot reads as a foot from above as well as from the side.
		-- It has to be BIG to do that job. The first cut ran 0.86 x 0.66 against a
		-- 1.24 x 1.44 hoof and read as a chip on the front of a plank; at 1.02 x
		-- 0.86 it covers most of the hoof's front face and juts past it, which is
		-- what actually changes the outline. It takes the antler purple rather
		-- than the hoof's black, so the two masses separate at a glance.
		local toeSize = Vector3.new(1.02, 0.50, 0.86 * leg.toe)
		local toeRot = CFrame.Angles(0, leg.yaw + leg.toeYaw, 0)
		mk({ name = leg.name .. "_Toe", size = toeSize,
			cf = groundCF * toeRot * CFrame.new(0, groundLift(toeSize, toeRot),
				-(HOOF.Z * 0.5 + toeSize.Z * 0.5 - 0.32)),
			color = C.AmethystDark, parent = m, wedge = true })
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
-- 5. SUPERNOVUS (Mythic, 8.20 studs) -- THE COSMIC STAR COLOSSUS
--    80 parts (+ 1 Base = 81): limbs 22, head 18, halo 13, armour 13, tusks 8,
--    fissures 4, leaves 2. Two emitters and three lights.
--
-- Rebuilt 2026-09-11 from the owner's choice of three concepts:
-- art/creatures/supernovus/reference/supernovus-option2-colossus.jpg, compared
-- in supernovus-lineup-comparison.png. It replaces the hexapod dragon.
--
-- ONE SENTENCE. A low, broad obsidian colossus on four pillar legs, whose glowing
-- crescent tusks and overhead galaxy halo announce the Mythic while cyan fissures
-- leak starlight from under its armour.
--
-- THREE MASSES, in the order the eye takes them:
--
--   dominant    the carapace and its two shoulder mantles: one wide, arched,
--               stepped armour mass with a pulsar geode set in each mantle
--   supporting  four short pillar legs, the front pair broader
--   signature   the tusks -- ivory at the root, cyan light at the tip -- curving
--               out, down and up in a crescent either side of the snout
--
-- WHAT WAS TAKEN FROM THE PICTURE. Observed: the flared mantles and gold gems,
-- a studded brow crest between two swept horns, cyan eye slits, the crescent
-- tusks, three claws a foot, cyan cracks in dark armour, a tilted galaxy disk
-- overhead. Inferred, because a front view never shows it: a lower rump behind
-- the shoulders.
--
-- AND WHAT WAS NOT: the hero shot's width. Drawn to its proportions the tusks
-- span about 1.4 times the creature's height, and Supernovus already overran the
-- 48-stud plot at Colossal. The crescent is pulled in so the whole silhouette,
-- tusk tips and mantles included, stays inside the old model's 7.06 studs.
--
-- STILL A PLANT. Two alien leaves sweep back off the rump and swing as it walks,
-- and the halo is its bloom.
--
-- COLOUR IN ZONES. Void black on the body and skull. Indigo and midnight slate
-- on the mantles, brow, snout and legs -- a value step up, so the armour still
-- separates from the body in greyscale. Amethyst on the claws, horn tips and
-- leaves. The light is kept to the tusks, the eye slits, the fissures, the halo
-- and the two gold geodes.
--
-- MOTION IS PlantSway's, BY NAME. The legs trot on diagonals, the two parts
-- named Leaf swing, and the slit eyes track and blink. The halo rides the body
-- and does not spin: nothing in PlantSway spins a part, and one species is not
-- worth a new per-frame channel.
--==============================================================================
local function buildSupernovus(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Supernovus"
	m.Parent = parent

	-- A tapering point. The wedge's full end sits on `from` and it narrows to an
	-- edge `len` studs along from's own +Y; `t` is the thickness that tapers
	-- away, laid along from's +Z, which is the inside of a curve for a tusk.
	local function spike(name: string, from: CFrame, len: number, w: number, t: number,
		colour: Color3, material: Enum.Material?): BasePart
		return mk({ name = name, size = Vector3.new(w, t, len),
			cf = from * CFrame.new(0, len * 0.5, 0) * CFrame.Angles(rad(90), 0, 0),
			color = colour, parent = m, wedge = true, material = material, smooth = true })
	end

	--==========================================================================
	-- FOUR PILLAR LEGS, AND THE NAMES ARE THE RIG
	--
	-- Every limb part carries a word from PlantSway's anatomy vocabulary --
	-- Thigh, Hock, Foot, Toe -- so the whole leg swings about one hip as the
	-- plant walks. Nothing else on the creature may carry one of those words;
	-- StarbloomLimbSpec reads the vocabulary out of PlantSway and fails on a
	-- stray.
	--
	-- Per leg, top to bottom, each mass wider than the one above it:
	--
	--   thigh   from inside the carapace down past the ankle. `shaft` overruns
	--           both joints, so no pose can open a seam at either end
	--   hock    the ankle collar, at a fixed height
	--   pad     level and flat on the plane: leg, collar, foot
	--   toes    claws off the pad's front edge, their undersides on the plane.
	--           Three on a front foot and two on a rear one, and one front claw
	--           a side is short
	--
	-- The front pair is broader and stands out under the mantles; the rear pair
	-- is narrower and stands a little behind its hips, the counterweight. Each
	-- leg splays a few degrees and its pad follows the ANKLE, not the hip, so the
	-- foot is under its own leg in plan view -- which is also how PlantSway
	-- decides which leg a foot belongs to.
	--
	-- THE ANKLE SITS LOW BECAUSE THE RIG SAYS SO. PlantSway takes limb parts
	-- whose centres lie in the upper 45% of the limb band as hip anchors, and
	-- only a Thigh may be one. The collar's centre at 0.68 is well under a hip
	-- line near 1.0.
	--==========================================================================
	local ANKLE_Y = 0.68
	local CLAW_H = 0.42
	for _, leg in ipairs({
		{ name = "FrontLeft", x = -1.72, z = -1.25, hipY = 2.50,
			pitch = rad(5), roll = rad(-7), yaw = rad(9), reach = -0.08,
			thigh = Vector2.new(1.24, 1.32), hock = Vector3.new(1.46, 0.72, 1.50),
			pad = Vector3.new(1.62, 0.40, 1.66),
			toes = {
				{ x = -0.50, len = 0.66, w = 0.44, yaw = rad(20) },
				{ x = 0.02, len = 0.78, w = 0.48, yaw = rad(3) },
				{ x = 0.50, len = 0.50, w = 0.40, yaw = rad(-17) },
			} },
		{ name = "FrontRight", x = 1.72, z = -1.25, hipY = 2.50,
			pitch = rad(5), roll = rad(7), yaw = rad(-8), reach = -0.08,
			thigh = Vector2.new(1.24, 1.32), hock = Vector3.new(1.46, 0.72, 1.50),
			pad = Vector3.new(1.62, 0.40, 1.66),
			toes = {
				{ x = -0.50, len = 0.52, w = 0.40, yaw = rad(17) },
				{ x = -0.02, len = 0.76, w = 0.48, yaw = rad(-2) },
				{ x = 0.50, len = 0.66, w = 0.44, yaw = rad(-21) },
			} },
		{ name = "RearLeft", x = -1.58, z = 1.55, hipY = 2.35,
			pitch = rad(-5), roll = rad(-6), yaw = rad(7), reach = 0.10,
			thigh = Vector2.new(1.12, 1.20), hock = Vector3.new(1.30, 0.72, 1.36),
			pad = Vector3.new(1.46, 0.38, 1.50),
			toes = {
				{ x = -0.30, len = 0.62, w = 0.46, yaw = rad(12) },
				{ x = 0.30, len = 0.56, w = 0.42, yaw = rad(-10) },
			} },
		{ name = "RearRight", x = 1.58, z = 1.55, hipY = 2.35,
			pitch = rad(-5), roll = rad(6), yaw = rad(-6), reach = 0.10,
			thigh = Vector2.new(1.12, 1.20), hock = Vector3.new(1.30, 0.72, 1.36),
			pad = Vector3.new(1.46, 0.38, 1.50),
			toes = {
				{ x = -0.30, len = 0.58, w = 0.44, yaw = rad(10) },
				{ x = 0.30, len = 0.62, w = 0.46, yaw = rad(-13) },
			} },
	}) do
		local hipCF = baseCF * CFrame.new(leg.x, leg.hipY, leg.z)
			* CFrame.Angles(leg.pitch, 0, leg.roll)
		local rot = hipCF - hipCF.Position
		-- The ankle is a fixed height off the plane, so the distance to it along
		-- the leg's own tilted axis is the vertical drop over that axis's rise.
		local drop = (leg.hipY - ANKLE_Y) / rot.UpVector.Y
		shaft(leg.name .. "_TitanThigh", hipCF, drop, 0.45, 0.30,
			leg.thigh.X, leg.thigh.Y, C.MidnightSlate, m)

		-- The collar turns with the foot and leans half as far as the leg, so the
		-- limb comes toward level instead of stopping dead on the pad.
		local ankle = baseCF:ToObjectSpace(hipCF * CFrame.new(0, -drop, 0)).Position
		mk({ name = leg.name .. "_TitanHock", size = leg.hock,
			cf = baseCF * CFrame.new(ankle.X, ANKLE_Y, ankle.Z)
				* CFrame.Angles(0, leg.yaw, leg.roll * 0.5),
			color = C.VoidBlack, parent = m })

		-- Turned, never tipped: its whole underside is meant to be on the plane.
		local padCF = baseCF * CFrame.new(ankle.X, 0, ankle.Z + leg.reach)
			* CFrame.Angles(0, leg.yaw, 0)
		mk({ name = leg.name .. "_TitanFootPad", size = leg.pad,
			cf = padCF * CFrame.new(0, leg.pad.Y * 0.5, 0),
			color = C.Indigo, parent = m })

		-- Each claw's thick end is buried 0.24 inside the pad's front edge and it
		-- tapers forward to a point. 0.17 measured only 0.03 of overlap at
		-- Colossal, where girth spreads the claws away from a pad that does not
		-- grow with them.
		--
		-- Amethyst on an indigo pad is two value steps: Voidpetal's claws sit one
		-- step off their pads and vanish across a plot. The palest lavender was
		-- tried first and pulled the eye down to the feet, away from the tusks.
		for ti, toe in ipairs(leg.toes) do
			local toeSize = Vector3.new(toe.w, CLAW_H, toe.len + 0.48)
			mk({ name = leg.name .. "_TitanToe" .. ti, size = toeSize,
				cf = padCF * CFrame.new(toe.x, CLAW_H * 0.5, -leg.pad.Z * 0.5 + 0.24)
					* CFrame.Angles(0, toe.yaw, 0) * CFrame.new(0, 0, -toeSize.Z * 0.5),
				color = C.Amethyst, parent = m, wedge = true })
		end
	end

	--==========================================================================
	-- THE CARAPACE: ONE ARCHED MASS FROM FIVE PIECES
	--
	-- Never one box. The main shell tips up toward the shoulders, the rump drops
	-- lower and narrower behind it, a studded hump rises between the mantles
	-- and a spine ridge runs the arch back down. The chest plate leans back under
	-- the head and is the back wall of the mouth.
	--==========================================================================
	local carapaceCF = baseCF * CFrame.new(0, 3.25, 0.05) * CFrame.Angles(rad(4), 0, 0)
	mk({ name = "TitanCarapace", size = Vector3.new(3.70, 2.60, 4.00), cf = carapaceCF,
		color = C.VoidBlack, parent = m })
	mk({ name = "RearCarapace", size = Vector3.new(3.30, 2.10, 1.90),
		cf = baseCF * CFrame.new(0, 2.95, 1.95) * CFrame.Angles(rad(10), 0, 0),
		color = C.VoidBlack, parent = m })
	mk({ name = "ShoulderHump", size = Vector3.new(2.60, 0.90, 2.30),
		cf = baseCF * CFrame.new(0, 4.95, -0.45) * CFrame.Angles(rad(4), math.pi, 0),
		color = C.MidnightSlate, parent = m, wedge = true })
	mk({ name = "SpineRidge", size = Vector3.new(1.30, 0.60, 2.40),
		cf = baseCF * CFrame.new(0, 4.35, 1.45) * CFrame.Angles(rad(10), math.pi, 0),
		color = C.MidnightSlate, parent = m, wedge = true })
	local chestCF = baseCF * CFrame.new(0, 2.60, -2.05) * CFrame.Angles(rad(12), 0, 0)
	mk({ name = "ChestPlate", size = Vector3.new(2.40, 1.70, 0.80), cf = chestCF,
		color = C.MidnightSlate, parent = m })

	--==========================================================================
	-- THE FISSURES
	--
	-- Thin cyan cuts centred ON the armour surface, so half of each stands proud
	-- and half is inside: light leaking out of a crack rather than a stripe
	-- painted over one. One run along each flank, unequal in length; the other
	-- two leak down the mantles from under their geodes.
	--
	-- They were a V on the chest plate first. The head and the tusks stand in
	-- front of the chest from every camera that matters, so nobody saw it.
	--==========================================================================
	for s = -1, 1, 2 do
		mk({ name = "FlankSeam", size = Vector3.new(0.10, 0.14, if s < 0 then 2.60 else 2.35),
			cf = carapaceCF * CFrame.new(s * 1.85, if s < 0 then -0.30 else -0.18, 0.55)
				* CFrame.Angles(rad(-8), 0, 0),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	--==========================================================================
	-- THE SHOULDER MANTLES AND THEIR PULSAR GEODES
	--
	-- A tall plate over each front leg, its top leaning in and its skirt flaring
	-- out, with a steeper flare along the bottom edge. The negative space between
	-- the mantle and the head is part of the silhouette; do not fill it.
	--
	-- The geode is a diamond: a dark socket turned 45 degrees and half set into
	-- the plate's outer face, and a tilted gold Neon facet standing proud of it.
	-- Each carries a small light -- two of the three this creature has.
	--==========================================================================
	for s = -1, 1, 2 do
		local mantleCF = baseCF * CFrame.new(s * 2.10, 3.95, -1.05)
			* CFrame.Angles(0, rad(-s * 18), rad(s * 18))
		mk({ name = "ShoulderMantle", size = Vector3.new(1.30, 1.95, 2.40), cf = mantleCF,
			color = C.Indigo, parent = m })
		mk({ name = "MantleFlare", size = Vector3.new(1.30, 0.36, 2.30),
			cf = baseCF * CFrame.new(s * 2.54, 3.02, -1.02)
				* CFrame.Angles(0, rad(-s * 18), rad(s * 40)),
			color = C.MidnightSlate, parent = m })

		-- A frame on the mantle's FRONT face, which the 18-degree turn aims out as
		-- well as forward: where the picture puts the gem, and where the front and
		-- three-quarter cameras can see it. It sat on the outer face first and
		-- showed only from the side.
		local faceCF = mantleCF * CFrame.new(s * 0.12, 0.30, -1.20)
		mk({ name = "GeodeSocket", size = Vector3.new(0.86, 0.86, 0.30),
			cf = faceCF * CFrame.Angles(0, 0, math.pi * 0.25),
			color = C.VoidBlack, parent = m })
		local geode = mk({ name = "PulsarGeode", size = Vector3.new(0.62, 0.62, 0.40),
			cf = faceCF * CFrame.new(0, 0, -0.10) * CFrame.Angles(rad(18), rad(18), math.pi * 0.25),
			color = C.PulsarGold, parent = m, material = Enum.Material.Neon })
		local glow = Instance.new("PointLight")
		glow.Name = "GeodeGlow"
		glow.Color = C.PulsarGold
		glow.Brightness = 1.4
		glow.Range = 6
		glow.Shadows = false
		glow.Parent = geode

		-- The crack the geode leaks into, running down the plate beneath it.
		mk({ name = "MantleSeam", size = Vector3.new(0.12, 0.95, 0.10),
			cf = faceCF * CFrame.new(-s * 0.10, -0.82, 0) * CFrame.Angles(0, 0, rad(s * 14)),
			color = C.NebulaCyan, parent = m, material = Enum.Material.Neon })
	end

	--==========================================================================
	-- THE SKULL, AND A MOUTH THAT IS A HOLE
	--
	-- A heavy brow plate overhangs the skull front and shades the eye slits; a
	-- studded crest rises from it toward the back. The snout ridge comes down
	-- from under the brow and juts forward, the cheek plates angle back either
	-- side of it, and the lower jaw hangs a little open beneath them.
	--
	-- THE MOUTH IS NEGATIVE SPACE, NOT A PLATE. Between the cheeks, under the
	-- snout and over the jaw there is nothing, for about a stud of depth back to
	-- the chest plate; the stellar core hangs inside that recess, behind the lip
	-- line, so the opening changes the outline from the side and glows from
	-- within at the front.
	--==========================================================================
	local headCF = baseCF * CFrame.new(0, 3.90, -2.45) * CFrame.Angles(rad(-6), 0, 0)
	mk({ name = "TitanSkull", size = Vector3.new(1.85, 1.50, 1.90),
		cf = headCF * CFrame.new(0, 0.35, 0.10), color = C.VoidBlack, parent = m })
	mk({ name = "BrowPlate", size = Vector3.new(2.25, 0.50, 1.15),
		cf = headCF * CFrame.new(0, 0.95, -0.55) * CFrame.Angles(rad(-10), 0, 0),
		color = C.Indigo, parent = m })
	mk({ name = "BrowCrest", size = Vector3.new(0.90, 0.75, 1.90),
		cf = headCF * CFrame.new(0, 1.45, 0.05), color = C.MidnightSlate, parent = m, wedge = true })
	mk({ name = "SnoutRidge", size = Vector3.new(0.62, 1.10, 0.70),
		cf = headCF * CFrame.new(0, 0.05, -1.00) * CFrame.Angles(rad(16), 0, 0),
		color = C.Indigo, parent = m })
	for s = -1, 1, 2 do
		mk({ name = "CheekPlate", size = Vector3.new(0.72, 0.95, 1.30),
			cf = headCF * CFrame.new(s * 0.74, -0.55, -0.72) * CFrame.Angles(0, rad(-s * 14), rad(s * 6)),
			color = C.MidnightSlate, parent = m })
	end
	mk({ name = "LowerJaw", size = Vector3.new(1.50, 0.50, 1.35),
		cf = headCF * CFrame.new(0, -1.18, -0.60) * CFrame.Angles(rad(-6), 0, 0),
		color = C.MidnightSlate, parent = m })
	mk({ name = "StellarCore", size = Vector3.new(0.52, 0.52, 0.52),
		cf = headCF * CFrame.new(0, -0.72, -0.55), color = C.NebulaCyan, parent = m,
		shape = Enum.PartType.Ball, material = Enum.Material.Neon })

	-- The slits sit ON the skull's front face (its centre is 0.85 in front of
	-- headCF) and roll inward-down into a frown under the brow.
	for s = -1, 1, 2 do
		local tag = if s < 0 then "Left" else "Right"
		voidEye(m, tag, headCF * CFrame.new(s * 0.50, 0.22, -0.86) * CFrame.Angles(0, 0, rad(s * 14)),
			0.46, "titan", C.VoidBlack)
	end

	--==========================================================================
	-- THE CROWN HORNS
	--
	-- Out, then up, from the brow plate's shoulders: a dark block leaning out 32
	-- degrees and a tapering amethyst tip that turns back up, the right one a
	-- little longer. Two upright blocks read as ears from the front. They stop
	-- clear under the halo.
	--==========================================================================
	for s = -1, 1, 2 do
		local hornCF = headCF * CFrame.new(s * 0.82, 1.20, -0.30)
			* CFrame.Angles(rad(24), 0, rad(-s * 32))
		mk({ name = "CrownHorn", size = Vector3.new(0.50, 1.15, 0.54),
			cf = hornCF * CFrame.new(0, 0.42, 0), color = C.VoidBlack, parent = m })
		spike("CrownHornTip", hornCF * CFrame.new(0, 0.92, 0) * CFrame.Angles(rad(22), 0, rad(s * 16)),
			if s > 0 then 1.05 else 0.95, 0.40, 0.46, C.AmethystDark)
	end

	--==========================================================================
	-- THE CRESCENT TUSKS
	--
	-- Each is a chain: three tapering segments and a wedge tip. The chain starts
	-- inside the cheek plate heading out and down, and every joint turns the next
	-- segment 40 degrees further up about the same bend axis -- out and down,
	-- out, out and up, up -- so the four pieces trace one crescent. Segments
	-- overrun their joints by 0.15 either side, which covers the outside of each
	-- bend.
	--
	-- WHY NOT FOUR WEDGES. A wedge tapers all the way to an edge, so a chain of
	-- them either steps where each new wedge starts full height or thins to a
	-- needle by the third. The tusk in the picture is thick for most of its
	-- length and sharpens only at the end, which is blocks and one wedge.
	--
	-- Ivory where it grows out of the head, turning to cyan light toward the tip.
	--==========================================================================
	for s = -1, 1, 2 do
		local out = Vector3.new(s * 0.944, 0, -0.330)
		local up = Vector3.new(0, 1, 0)
		local bend = out:Cross(up).Unit
		local start = out * math.cos(rad(-30)) + up * math.sin(rad(-30))
		-- A frame whose +Y runs along the tusk and whose X is the bend axis, so
		-- CFrame.Angles about X turns the next segment within the crescent.
		local joint = baseCF * CFrame.new(s * 0.95, 3.10, -3.05)
			* CFrame.fromMatrix(Vector3.zero, bend, start)
		for _, seg in ipairs({
			{ name = "TuskRoot", len = 0.95, w = 0.50, t = 0.62, colour = C.StarIvory,
				material = Enum.Material.SmoothPlastic },
			{ name = "TuskMid", len = 0.90, w = 0.44, t = 0.54, colour = C.StarIvory,
				material = Enum.Material.Neon },
			{ name = "TuskArc", len = 1.00, w = 0.38, t = 0.46, colour = C.NebulaCyanGlow,
				material = Enum.Material.Neon },
		}) do
			mk({ name = seg.name, size = Vector3.new(seg.w, seg.len + 0.30, seg.t),
				cf = joint * CFrame.new(0, seg.len * 0.5, 0), color = seg.colour, parent = m,
				material = seg.material, smooth = true })
			joint = joint * CFrame.new(0, seg.len, 0) * CFrame.Angles(rad(40), 0, 0)
		end
		spike("TuskTip", joint * CFrame.new(0, -0.12, 0), 1.30, 0.32, 0.40,
			C.NebulaCyan, Enum.Material.Neon)
	end

	-- Two alien leaves off the rump, the plant in the colossus. Named "Leaf" so
	-- PlantSway swings them; the two sides are told apart by their X.
	for s = -1, 1, 2 do
		mk({ name = "Leaf", size = Vector3.new(0.62, 2.30, 0.24),
			cf = baseCF * CFrame.new(s * 1.30, 4.25, 2.05)
				* CFrame.Angles(rad(42), rad(s * 12), rad(-s * 30)),
			color = C.AmethystPale, parent = m, wedge = true })
	end

	--==========================================================================
	-- THE GALAXY HALO
	--
	-- A tilted ring of eight Neon arcs, cyan and orchid by turns, around four
	-- shorter spiral arms in gold and violet and a white heart. It floats clear
	-- over the crown and tilts its near edge down, so a camera above and in
	-- front -- the Garden's, the Almanac's -- sees its face rather than its rim.
	--==========================================================================
	local haloCF = baseCF * CFrame.new(0, 7.95, -0.90) * CFrame.Angles(rad(-26), rad(18), rad(8))
	local RING = 1.90
	for i = 0, 7 do
		mk({ name = "HaloArc",
			size = Vector3.new(2 * RING * math.tan(math.pi / 8) + 0.14, 0.12, 0.24),
			cf = haloCF * CFrame.Angles(0, i * math.pi / 4, 0) * CFrame.new(0, 0, -RING),
			color = if i % 2 == 0 then C.NebulaCyan else C.OrchidPurple, parent = m,
			material = Enum.Material.Neon })
	end
	for i = 0, 3 do
		mk({ name = "GalaxyArm", size = Vector3.new(1.15, 0.10, 0.16),
			cf = haloCF * CFrame.Angles(0, i * math.pi / 2 + rad(20), 0)
				* CFrame.new(0, 0.02, -1.02) * CFrame.Angles(0, rad(24), 0),
			color = if i % 2 == 0 then C.PulsarGold else C.StarlightViolet, parent = m,
			material = Enum.Material.Neon })
	end
	local heart = mk({ name = "GalaxyHeart", size = Vector3.new(0.52, 0.52, 0.52), cf = haloCF,
		color = C.StarIvory, parent = m, shape = Enum.PartType.Ball, material = Enum.Material.Neon })

	--==========================================================================
	-- THE AURA, AT THE HEART OF THE HALO
	--
	-- The third light, and the only two emitters: slow starlight sparkles that
	-- drift round the halo, and a thin radial burst of gold stardust. About
	-- thirty live particles together, fewer than the one emitter this replaced.
	-- Both ignore scene lighting, so the rarity reads in the dim biome.
	--==========================================================================
	local light = Instance.new("PointLight")
	light.Name = "StarlightGlow"
	light.Color = C.NebulaCyanGlow
	light.Brightness = 2.5
	light.Range = 16
	light.Shadows = false
	light.Parent = heart

	local aura = Instance.new("Attachment")
	aura.Name = "StarlightAura"
	aura.Parent = heart

	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "StarlightSparkles"
	sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.NebulaCyanGlow),
		ColorSequenceKeypoint.new(0.5, C.StarIvory),
		ColorSequenceKeypoint.new(1, C.OrchidPurple),
	})
	sparkles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.10),
		NumberSequenceKeypoint.new(0.35, 0.42),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparkles.Transparency = NumberSequence.new(0.15, 1)
	sparkles.Lifetime = NumberRange.new(1.2, 2.4)
	sparkles.Rate = 14
	sparkles.Speed = NumberRange.new(0.4, 1.3)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.LightEmission = 1
	sparkles.LightInfluence = 0
	sparkles.Parent = aura

	local flairs = Instance.new("ParticleEmitter")
	flairs.Name = "StardustFlairs"
	flairs.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	flairs.Color = ColorSequence.new(C.PulsarGold, C.StarIvory)
	flairs.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(0.3, 0.22),
		NumberSequenceKeypoint.new(1, 0),
	})
	flairs.Transparency = NumberSequence.new(0.25, 1)
	flairs.Lifetime = NumberRange.new(0.7, 1.3)
	flairs.Rate = 5
	flairs.Speed = NumberRange.new(2.2, 3.4)
	flairs.Drag = 2.5
	flairs.SpreadAngle = Vector2.new(180, 180)
	flairs.LightEmission = 1
	flairs.LightInfluence = 0
	flairs.Parent = aura

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
