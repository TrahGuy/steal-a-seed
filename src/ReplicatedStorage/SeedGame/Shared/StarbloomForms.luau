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
--     supernovus 70
--
-- Four sit inside it. Supernovus does not and never did -- it was already 46 for
-- its eyes and its crown, a documented exception -- and rebuilding its feet has
-- taken it to 70.
--
-- SIX LEGS IS WHAT MAKES THAT EXPENSIVE. The ankle, sole, heel and two toes each
-- foot needs come to thirty parts before the thighs are counted, and there is no
-- cheaper way to make a hexapod titan stand on something than to build it six
-- feet. It is the one number in this file worth arguing about; the leg block
-- below says what every part is doing, and dropping the separate heel would
-- bring it to 64 at the cost of the counterweight the silhouette leans on.
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
-- 5. SUPERNOVUS (Mythic, 8.20 studs) -- 69 parts (+ 1 Base = 70), 36 of them limb
--==============================================================================
local function buildSupernovus(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Supernovus"
	m.Parent = parent

	--==========================================================================
	-- SIX LEGS, AND SIX FEET THAT ACTUALLY CARRY THEM
	--
	-- WHAT WAS WRONG. Each leg was one thigh and a flat slab, and the slab was
	-- positioned from the plant's origin rather than from the leg, so the thigh
	-- stopped in mid-air above it. Measured at authored scale, the daylight
	-- between the two ran 0.0376 studs at the rear pair, 0.1493 at the front and
	-- 0.3474 at the middle -- a titan hovering over six loose tiles, and at
	-- Colossal, where the height scale is 50x, between 1.9 and 17.4 studs of
	-- open air under a creature that is meant to be standing on them.
	--
	-- It was invisible in the RIG as well. PlantSway finds limb parts by an
	-- anatomy vocabulary -- Thigh, Shin, Hock, Foot, Toe and the rest -- and
	-- "TitanClaw" is in none of it, so the six pads were never leg parts at all.
	-- PlantSway says so itself: "a single-part leg (Supernovus is thighs and
	-- nothing else)". The thighs stepped; the feet stayed where they were.
	--
	-- WHAT IT IS NOW, PER LEG: the thigh, an ankle, a sole, a heel and two
	-- unequal toes. Every one of them carries a word the rig knows, so the whole
	-- foot swings with the leg it belongs to.
	--
	-- THE THIGH IS EXTENDED, NOT MOVED. Its top is exactly where it was -- that
	-- is the creature's height and its stance -- and only the lower end grows, by
	-- however much it takes to put its cut face INSIDE the sole. That distance is
	-- computed from the box's own rotated corner reach rather than typed in,
	-- because the six legs sit at three pitches and two rolls and a single number
	-- would bury one and strand another.
	--
	-- THE FEET STAND SLIGHTLY OUT OF LINE WITH THE HIPS, deliberately and twice
	-- over. It reads as a planted hexapod stance -- front feet ahead, rear feet
	-- behind -- and it is also what keeps each foot in its own rig cluster:
	-- PlantSway hangs every limb part on the nearest hip in plan view, and with
	-- 1.7 studs between neighbouring hips a foot placed straight under its own
	-- thigh puts its HEEL nearer the next leg along. Measured before the offset,
	-- the front heel came out 1.07:1 toward the middle leg -- the wrong side, and
	-- the middle leg walks in antiphase, so the foot would have torn off the leg
	-- every stride.
	--==========================================================================
	for _, leg in ipairs({
		{ name = "FrontLeft",  x = -1.8, z = -1.6, pitch = rad(-18), roll = rad(-15),
			size = 1.1, yaw = rad( 16), reach = -0.45, heel = 1.00,
			toes = { { len = 1.00, w = 1.00, yaw = rad( 26) },
				{ len = 0.84, w = 0.86, yaw = rad(-19) } } },
		{ name = "FrontRight", x =  1.8, z = -1.6, pitch = rad(-18), roll = rad( 15),
			size = 1.1, yaw = rad(-14), reach = -0.45, heel = 0.94,
			toes = { { len = 0.96, w = 0.94, yaw = rad(-28) },
				{ len = 0.88, w = 0.90, yaw = rad( 16) } } },
		{ name = "MidLeft",    x = -2.0, z =  0.1, pitch = rad(  0), roll = rad(-20),
			size = 1.0, yaw = rad( 19), reach =  0.00, heel = 0.96,
			toes = { { len = 0.92, w = 0.96, yaw = rad( 30) },
				{ len = 0.80, w = 0.82, yaw = rad(-16) } } },
		{ name = "MidRight",   x =  2.0, z =  0.1, pitch = rad(  0), roll = rad( 20),
			size = 1.0, yaw = rad(-21), reach =  0.00, heel = 1.02,
			toes = { { len = 0.86, w = 0.88, yaw = rad(-24) },
				{ len = 0.94, w = 0.98, yaw = rad( 21) } } },
		{ name = "RearLeft",   x = -1.8, z =  1.8, pitch = rad( 20), roll = rad(-15),
			size = 1.2, yaw = rad( 15), reach =  0.55, heel = 1.06,
			toes = { { len = 0.90, w = 1.02, yaw = rad( 23) },
				{ len = 1.02, w = 0.90, yaw = rad(-25) } } },
		{ name = "RearRight",  x =  1.8, z =  1.8, pitch = rad( 20), roll = rad( 15),
			size = 1.2, yaw = rad(-17), reach =  0.55, heel = 0.98,
			toes = { { len = 1.00, w = 0.94, yaw = rad(-20) },
				{ len = 0.86, w = 1.00, yaw = rad( 27) } } },
	}) do
		local s = leg.size
		local legCF = baseCF * CFrame.new(leg.x, 1.8, leg.z)
			* CFrame.Angles(leg.pitch, 0, leg.roll)
		local rot = legCF - legCF.Position
		-- Deliberately the SHALLOWEST and NARROWEST mass in the foot. It began as
		-- a 1.34 x 0.42 x 1.20 brick with toes thinner than itself, and the whole
		-- thing read as one flat rectangular pad -- the exact shape this rebuild
		-- exists to stop being. Pulled in to 1.22 x 0.34 x 1.14 with 0.50-deep
		-- toes standing proud of it, the outline that reaches the ground is
		-- knuckles and a heel rather than a tile.
		local padSize = Vector3.new(1.22 * s, 0.34 * s, 1.14 * s)

		-- How far this thigh must grow to put its lowest corner inside the sole.
		-- `groundLift` is the box's reach below its own centre, and lengthening
		-- by `ext` drops that corner by exactly `ext` times the leg's own
		-- up-vector -- the centre falls half of it and the half-extent takes the
		-- other half.
		local plainSize = Vector3.new(0.9 * s, 1.7 * s, 1.0 * s)
		local lowest = 1.8 - groundLift(plainSize, rot)
		local ext = math.max((lowest - padSize.Y * 0.55) / rot.UpVector.Y, 0.10)
		mk({ name = leg.name .. "_TitanThigh",
			size = Vector3.new(0.9 * s, 1.7 * s + ext, 1.0 * s),
			cf = legCF * CFrame.new(0, -ext * 0.5, 0),
			color = C.VoidBlack, parent = m })

		-- The plant's own level frame, at this leg's foot. Turned, never tipped.
		local legEnd = baseCF:ToObjectSpace(legCF
			* CFrame.new(0, -(0.85 * s + ext), 0)).Position
		local footCF = baseCF * CFrame.new(legEnd.X, 0, legEnd.Z + leg.reach)
			* CFrame.Angles(0, leg.yaw, 0)

		--======================================================================
		-- THE SOLE, FLAT AND FULL ON THE GROUND
		--
		-- No pitch and no roll on this one part, on purpose. Everything else in
		-- the foot is lifted by its own rotated corner reach so its lowest point
		-- touches the plane; the sole is the one mass whose whole underside is
		-- meant to be down there, and a degree of tilt would stand it on an edge.
		--======================================================================
		mk({ name = leg.name .. "_TitanFootPad", size = padSize,
			cf = footCF * CFrame.new(0, padSize.Y * 0.5, -0.10 * s),
			color = C.MidnightSlate, parent = m })

		--======================================================================
		-- THE ANKLE IS A COLLAR, AND IT IS A BLOCK ON PURPOSE
		--
		-- The first cut made it a WedgePart with its deep end facing backward,
		-- reasoning that a wedge is by definition a taper. On screen it was a
		-- shark fin: a wedge is full height along one edge only, so all of its
		-- mass stacked up behind the leg and the taper ran out to a blade over
		-- the toes. Nothing about it read as an ankle.
		--
		-- A block does, because the taper that matters here is the one BETWEEN
		-- the three masses: the thigh is 0.90 x 1.00 across, this is 1.10 x 1.14,
		-- and the sole below flares to 1.34 x 1.20. Leg, collar, foot. It does
		-- not need to hide the thigh's cut end either -- the thigh is extended
		-- until that face is inside the SOLE, well below this.
		--
		-- It leans with the leg at half the roll, so it turns the limb toward
		-- level instead of stopping it dead.
		--======================================================================
		local hockTop = legEnd.Y + 0.34 * s
		local hockBot = padSize.Y * 0.40
		mk({ name = leg.name .. "_TitanHock",
			size = Vector3.new(1.10 * s, math.max(hockTop - hockBot, 0.32 * s), 1.14 * s),
			cf = baseCF * CFrame.new(legEnd.X, (hockTop + hockBot) * 0.5, legEnd.Z)
				* CFrame.Angles(0, leg.yaw, leg.roll * 0.5),
			color = C.AmethystDark, parent = m })

		--======================================================================
		-- THE HEEL, AND TWO TOES THAT DO NOT MATCH
		--
		-- The heel is the counterweight: taller than the sole, set behind the
		-- ankle, tapering away to the rear. The toes taper the other way, from
		-- inside the sole out to a point on the ground. Lengths, widths and splay
		-- are per foot and written down rather than rolled -- two servers have to
		-- build the same creature, and "the third one looked wrong" has to be
		-- able to mean something.
		--======================================================================
		local heelSize = Vector3.new(1.00 * s, 0.56 * s, 0.70 * s * leg.heel)
		mk({ name = leg.name .. "_TitanFootHeel", size = heelSize,
			cf = footCF * CFrame.new(0.06 * s, heelSize.Y * 0.5, 0.40 * s)
				* CFrame.Angles(0, math.pi, 0),
			color = C.VoidBlack, parent = m, wedge = true })

		-- TALONS, NOT FLIPPERS. The first cut ran them 0.40 wide and 0.38 tall
		-- over 0.86 of length and they came out as thin flat flaps off the front
		-- of a slab. Broader, taller and shorter reads as a toe carrying weight,
		-- and standing them PROUD of the sole -- 0.46 against its 0.36 -- turns
		-- the front of the foot into knuckles instead of an edge.
		for ti, toe in ipairs(leg.toes) do
			local toeSize = Vector3.new(0.58 * s * toe.w, 0.50 * s, 0.92 * s * toe.len)
			mk({ name = leg.name .. "_TitanToe" .. ti, size = toeSize,
				cf = footCF * CFrame.Angles(0, toe.yaw, 0)
					* CFrame.new(0, toeSize.Y * 0.5, -0.60 * s),
				color = C.MidnightSlate, parent = m, wedge = true })
		end
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
