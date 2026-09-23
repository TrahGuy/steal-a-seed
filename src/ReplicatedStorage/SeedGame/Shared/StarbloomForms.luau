--!strict
--==============================================================================
-- STARBLOOM FORMS (BIOME 5) -- 80% CREATURE / 20% PLANT
--
-- Primitive-sculpted alien cosmic creatures with standing locomotion limbs,
-- bioluminescent alien leaves, and per-species cosmic palettes.
--
-- THE PART BUDGET, HONESTLY. The art bible band is 25-40 per grown plant.
--
--     novaorb 30    cosmospire 38    voidpetal 39    astralhorn 47
--     supernovus 81
--
-- Three sit inside it. Two do not, and both are documented exceptions.
--
-- Supernovus never did: the Mythic was 46 for its eyes and crown, 70 once its
-- six legs got real feet, and it is 81 as the Cosmic Star Colossus -- inside the
-- 70-85 the owner set for that rebuild on 2026-09-11. Its builder's banner says
-- what every part is for.
--
-- Astralhorn has been 47 since the Mooncrest Stag replaced the pillar-legged
-- beast, and the owner approved it at 47 in the redesign preview (fba9ed0).
-- Sixteen of those are four jointed legs, and seven are the curved neck and the
-- two antlers that make the crescent the whole design is about.
--
-- Species:
--   1. Novaorb     (Rare)       - Moonbulb Prowler: forward-leaning pear bulb on four short root legs, recessed face under a petal brow
--   2. Cosmospire  (Rare)       - Crescent Reedwalker: four stilt legs, an S-shaped stalk, a split crown around a lit seed chamber
--   3. Voidpetal   (Epic)       - Prowling void panther predator with 6-petal orchid neck mane & leaf tails
--   4. Astralhorn  (Legendary)  - Mooncrest Stag: chest and curved neck, four jointed legs, two unequal antlers framing a crescent
--   5. Supernovus  (Mythic)     - Armored cosmic star colossus: obsidian mantles & pulsar geodes, crescent tusks, 4 pillar legs & a galaxy halo
--
-- Novaorb, Cosmospire and Astralhorn were redesigned on 2026-09-22 and approved
-- by the owner on 2026-09-23 -- those three only. The pod redesigns shown in the
-- same preview were NOT approved; they live in RedesignForms, which nothing in
-- production requires.
--==============================================================================

local StarbloomForms = {}

--==============================================================================
-- THE HEIGHT EACH BUILD WAS AUTHORED AT
--
-- Build divides the tier's frame height by this, so it is what pins a species to
-- the ladder: change one and that species moves, and nothing else does.
--
-- Voidpetal and Supernovus were drawn to their sheet heights. The three
-- redesigns carry the height their approved build MEASURES at scale 1, which
-- the preview chose so that each would stand as tall as the creature it
-- replaced at every tier. Novaorb and Astralhorn do (4.0 and 7.3 at Tiny).
-- Cosmospire's crown bracts were enlarged after its number was set, so it stands
-- 6.5% taller than its predecessor -- 8.0 at Tiny, 61.1 at Colossal -- and that
-- is the build the owner approved. Re-deriving it from the geometry would
-- shrink the approved creature; leave it.
--==============================================================================
StarbloomForms.AuthoredHeight = {
	novaorb    = 4.82,
	cosmospire = 9.71,
	voidpetal  = 5.60,
	astralhorn = 8.88,
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
-- PAIRED PARTS TAKE THE NAME TOGETHER. Novaorb's rear leaf is a blade and a
-- curled tip, and both are "Leaf": they sit on the same side of the body, so
-- they take the same swing and move as one leaf. Naming only the blade would
-- leave the tip standing still while the blade swung away from it.
--
-- Six sites build them, each marked with its own count. Keep those counts
-- honest -- the leaf total is a per-frame cost while a plant is walking.
--==============================================================================

-- Starbloom Shared Palette Family
local C = {
	VoidBlack      = Color3.fromRGB(14, 10, 24),
	MidnightSlate  = Color3.fromRGB(24, 18, 46),
	Indigo         = Color3.fromRGB(39, 37, 82),
	-- A shade under Indigo, for bark, thighs and the second value of a body.
	IndigoBark     = Color3.fromRGB(30, 26, 62),
	AmethystDark   = Color3.fromRGB(48, 30, 78),
	Amethyst       = Color3.fromRGB(90, 50, 160),
	AmethystPale   = Color3.fromRGB(158, 128, 255),
	StarlightViolet= Color3.fromRGB(180, 150, 255),
	-- The pale edge of a petal: Novaorb's leaf tip, Astralhorn's upper petals.
	Lavender       = Color3.fromRGB(186, 164, 240),
	OrchidPurple   = Color3.fromRGB(214, 140, 255),
	NebulaCyan     = Color3.fromRGB(110, 230, 255),
	NebulaCyanGlow = Color3.fromRGB(180, 245, 255),
	StarIvory      = Color3.fromRGB(242, 238, 255),
	-- Warmer and duller than StarIvory: antler bone, not light.
	Ivory          = Color3.fromRGB(228, 222, 210),
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
-- THREE SHAPES THE REDESIGNED THREE ARE MADE OF
--
-- `plate` is a WedgePart turned a quarter about Y, so its taper runs across the
-- WIDTH and the part comes to an edge rather than a ramp: a sepal, a bract, a
-- petal, a jaw. It is `thick` through, `len` along its own Y and `w` across.
-- `mirror` turns it half a turn more so the thin edge falls on the other side --
-- a pair that never mirrors leans the same way, and reads as a pattern.
--
-- `slab` is a flat block facing along Z: a bark plate.
--
-- `rod` is a Cylinder from one point to another. A Roblox Cylinder is round only
-- across its length, which is exactly what a stalk segment is.
--
-- Studded unless smooth, like everything `mk` makes.
--==============================================================================
local function plate(name: string, w: number, len: number, thick: number, cf: CFrame,
	color: Color3, parent: Instance, mirror: boolean?, material: Enum.Material?): BasePart
	return mk({ name = name, size = Vector3.new(thick, len, w),
		cf = cf * CFrame.Angles(0, rad(90), 0)
			* (if mirror then CFrame.Angles(0, math.pi, 0) else CFrame.new()),
		color = color, parent = parent, wedge = true, material = material,
		smooth = material == Enum.Material.SmoothPlastic })
end

local function slab(name: string, w: number, len: number, thick: number, cf: CFrame,
	color: Color3, parent: Instance, material: Enum.Material?): BasePart
	return mk({ name = name, size = Vector3.new(w, len, thick), cf = cf,
		color = color, parent = parent, material = material,
		smooth = material == Enum.Material.SmoothPlastic })
end

local function rod(name: string, from: Vector3, to: Vector3, dia: number, color: Color3,
	parent: Instance, smooth: boolean?): BasePart
	local len = (to - from).Magnitude
	local cf = CFrame.lookAt((from + to) * 0.5, to) * CFrame.Angles(0, rad(90), 0)
	return mk({ name = name, size = Vector3.new(len, dia, dia), cf = cf, color = color,
		parent = parent, shape = Enum.PartType.Cylinder, smooth = smooth })
end

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
		-- The roundest, softest eye of the five, and the lid rides low on it. It
		-- is the only one here that could be called friendly, which is what a
		-- Rare at the bottom of the ladder should be. The pupil is a FOCUSED
		-- cyan point, a little larger than a pinprick, so the curiosity the
		-- Moonbulb Prowler was approved on still reads from under its brow.
		mk({ name = tag .. "Eye", size = Vector3.new(dia, dia, dia),
			cf = eyeCF, color = VOID_SCLERA, parent = m,
			shape = Enum.PartType.Ball, smooth = true })
		mk({ name = tag .. "Pupil", size = Vector3.new(dia * 0.30, dia * 0.30, dia * 0.30),
			cf = eyeCF * CFrame.new(0, 0, -dia * 0.40),
			color = C.NebulaCyan, parent = m,
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

--==============================================================================
-- 1. NOVAORB -- THE MOONBULB PROWLER (Rare) -- 29 parts (+ 1 Base = 30)
--
-- ONE SENTENCE. A low, broad alien bulb-creature walking on four short root
-- legs: a pear-shaped bulb leaning forward, broad violet sepals overlapping
-- across the back and shoulders, a heavy petal brow over a small recessed face
-- with focused cyan eyes, one curled rear leaf balancing the lean. Curious, a
-- little mischievous -- the compact, approachable one of the three.
--
--   dominant   the bulb, in four masses: lower, upper, rear, belly plate
--   support    four short legs, a thigh and a foot each, planted under it
--   signature  the petal brow over the recessed face
--
-- Built exactly as the owner approved it in the redesign preview (fba9ed0):
-- the same parts, sizes, frames and colours.
--
-- THE NAMES ARE THE RIG. PlantSway reads this creature by name alone:
--   * FL/FR/BL/BR_Thigh and _Foot carry leg words, and the four thighs are the
--     only upper-leg words on it, so the legs come back as four hips.
--   * BulbRear is NOT "Haunch". Haunch is a leg word, and a body mass carrying
--     it becomes a hip the legs hang from -- the preview measured the rig
--     collapsing to a single hip before the rename.
--   * both rear-leaf parts are "Leaf" (see the banner at the top).
--   * Left/Right Eye, Pupil and Lid drive the gaze and the blink.
-- Nothing else carries a rig word -- not the brow, the cheeks, the jaw, the
-- face plate or the sepals -- so all of it rides the body's one PivotTo and
-- cannot come away from it.
--==============================================================================
local function buildNovaorb(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Novaorb"
	m.Parent = parent

	-- THE BULB. Four masses: a full lower body set back, a smaller upper body
	-- forward, a rear mass that fills the pear's back shoulder, and the belly
	-- plate under the face. Leans forward 12 degrees.
	local lean = CFrame.Angles(rad(12), 0, 0)
	local bodyCF = baseCF * CFrame.new(0, 1.95, 0.15) * lean
	mk({ name = "BulbLower", size = Vector3.new(2.5, 2.3, 2.5), cf = bodyCF * CFrame.new(0, -0.15, 0.10),
		color = C.Indigo, parent = m, shape = Enum.PartType.Ball })
	mk({ name = "BulbUpper", size = Vector3.new(1.75, 1.75, 1.75), cf = bodyCF * CFrame.new(0, 0.85, -0.42),
		color = C.Indigo, parent = m, shape = Enum.PartType.Ball })
	-- Not "Haunch": see the banner.
	mk({ name = "BulbRear", size = Vector3.new(1.9, 1.3, 1.5),
		cf = bodyCF * CFrame.new(0, 0.55, 0.70) * CFrame.Angles(rad(-22), 0, 0),
		color = C.IndigoBark, parent = m })
	mk({ name = "BellyPlate", size = Vector3.new(1.5, 1.2, 0.36),
		cf = bodyCF * CFrame.new(0, -0.55, -1.02) * CFrame.Angles(rad(22), 0, 0),
		color = C.MidnightSlate, parent = m })

	-- SEPALS. Four broad violet plates overlapping across the back and
	-- shoulders, the rear pair larger, none mirrored exactly.
	for i, s in ipairs({
		{ x = -0.55, y = 0.95, z = 0.55, w = 1.30, len = 1.55, pitch = -38, yaw = 22, roll = -14, c = C.Amethyst },
		{ x = 0.62, y = 0.90, z = 0.50, w = 1.20, len = 1.45, pitch = -42, yaw = -26, roll = 12, c = C.AmethystDark },
		{ x = -1.05, y = 0.30, z = 0.05, w = 0.95, len = 1.25, pitch = -10, yaw = 58, roll = -34, c = C.AmethystDark },
		{ x = 1.08, y = 0.25, z = 0.00, w = 0.90, len = 1.15, pitch = -6, yaw = -62, roll = 36, c = C.Amethyst },
	}) do
		plate("Sepal" .. i, s.w, s.len, 0.16,
			bodyCF * CFrame.new(s.x, s.y, s.z) * CFrame.Angles(rad(s.pitch), rad(s.yaw), rad(s.roll)),
			s.c, m, i % 2 == 0)
	end

	-- THE FACE, RECESSED. A heavy petal brow shelters it; two cheek masses and a
	-- jaw stand proud of a slate face plate set back between them, so the face
	-- is a cavity with depth rather than a mark on the bulb.
	local faceCF = bodyCF * CFrame.new(0, 0.70, -1.05)
	mk({ name = "FacePlate", size = Vector3.new(1.20, 0.95, 0.30), cf = faceCF * CFrame.new(0, 0, 0.16),
		color = C.MidnightSlate, parent = m, smooth = true })
	-- A hood, not a brim: narrow, and pitched down over the eyes.
	plate("PetalBrow", 1.20, 0.66, 0.18,
		faceCF * CFrame.new(0, 0.56, -0.22) * CFrame.Angles(rad(-44), 0, rad(-8)), C.Amethyst, m)
	for side = -1, 1, 2 do
		mk({ name = if side < 0 then "CheekLeft" else "CheekRight", size = Vector3.new(0.42, 0.70, 0.55),
			cf = faceCF * CFrame.new(side * 0.72, -0.05, 0.05) * CFrame.Angles(0, rad(-side * 18), 0),
			color = C.Indigo, parent = m })
	end
	mk({ name = "Jaw", size = Vector3.new(1.30, 0.42, 0.62),
		cf = faceCF * CFrame.new(0, -0.62, 0.02) * CFrame.Angles(rad(-14), 0, 0),
		color = C.IndigoBark, parent = m })
	for side = -1, 1, 2 do
		local tag = if side < 0 then "Left" else "Right"
		-- ON the face plate's front, which is 0.30 deep: its surface is 0.01
		-- in front of faceCF, so the eye centre sits there and half stands out.
		voidEye(m, tag, faceCF * CFrame.new(side * 0.34, 0.06, -0.01), 0.42, "placid", C.AmethystDark, 0.04)
	end

	-- FOUR SHORT ROOT LEGS. A thigh angled out from the bulb and a tapered foot
	-- that receives it; the feet are planted under the body, toes out, and each
	-- is lifted by its rotated corner reach so the sole rests ON the plane.
	for _, leg in ipairs({
		{ n = "FL", x = -0.95, z = -0.55, pitch = -16, roll = -14, yaw = 14, toe = 1.00 },
		{ n = "FR", x = 0.95, z = -0.50, pitch = -16, roll = 14, yaw = -12, toe = 0.94 },
		{ n = "BL", x = -1.00, z = 0.80, pitch = 14, roll = -14, yaw = 16, toe = 1.06 },
		{ n = "BR", x = 1.00, z = 0.85, pitch = 14, roll = 14, yaw = -14, toe = 0.98 },
	}) do
		local hipCF = baseCF * CFrame.new(leg.x, 1.25, leg.z) * CFrame.Angles(rad(leg.pitch), 0, rad(leg.roll))
		shaft(leg.n .. "_Thigh", hipCF, 0.85, 0.55, 0.20, 0.58, 0.62, C.IndigoBark, m)
		local ankle = baseCF:ToObjectSpace(hipCF * CFrame.new(0, -0.85, 0)).Position
		local footSize = Vector3.new(0.62, 0.40, 1.05 * leg.toe)
		local footRot = CFrame.Angles(0, rad(leg.yaw), 0)
		mk({ name = leg.n .. "_Foot", size = footSize,
			cf = baseCF * CFrame.new(ankle.X, 0, ankle.Z) * footRot
				* CFrame.new(0, groundLift(footSize, footRot), -footSize.Z * 0.28),
			color = C.VoidBlack, parent = m, wedge = true })
	end

	-- THE REAR LEAF. One curled blade off the back of the bulb, two parts both
	-- named Leaf so the walk swings them together; it balances the forward lean.
	local leafCF = bodyCF * CFrame.new(0.15, 1.05, 1.15) * CFrame.Angles(rad(-58), rad(8), rad(10))
	plate("Leaf", 0.62, 1.60, 0.14, leafCF, C.AmethystPale, m)
	plate("Leaf", 0.42, 0.85, 0.12, leafCF * CFrame.new(0.05, 1.45, 0) * CFrame.Angles(rad(48), 0, 0),
		C.Lavender, m, true)

	-- The one light, on the face plate: PlantGlow keeps it dark by day.
	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyan
	light.Brightness = 1.2
	light.Range = 8
	light.Parent = m:FindFirstChild("FacePlate") or m
	return m
end

--==============================================================================
-- 2. COSMOSPIRE -- THE CRESCENT REEDWALKER (Rare) -- 37 parts (+ 1 Base = 38)
--
-- ONE SENTENCE. A tall, narrow botanical creature: four tapering stilt legs
-- under a compact lower body, a long S-shaped stalk, a small face below the
-- crown, and two unequal spear-shaped bracts rising around a recessed, lit seed
-- chamber. Watchful, elegant, slightly strange.
--
--   dominant   the split crown -- two bracts and the lit chamber
--   support    the stalk and the four stilt legs
--   signature  the S of the stalk, and the brightest accent inside the crown
--
-- Built exactly as the owner approved it in the redesign preview (fba9ed0).
-- Rig words: Femur, Knee, Tibia and StiltClaw on the legs, "Leaf" on the three
-- stalk blades, Left/Right Eye, Pupil and Lid on the face. Nothing else --
-- stalk, skull, mandible, bracts, chamber -- carries one, so the crown rides the
-- body and cannot come away from it.
--==============================================================================
local function buildCosmospire(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Cosmospire"
	m.Parent = parent

	--==========================================================================
	-- FOUR STILT LEGS, BUILT DOWN A SKELETON RATHER THAN PLACED BESIDE ONE
	--
	-- The chain these legs were rebuilt around, kept through the redesign:
	-- hip -> femur -> knee -> shank -> claw. Each joint is a CFrame, each mass
	-- is built from the joint above it, and every segment runs PAST the joint at
	-- both of its ends (`shaft`) so the seam sits inside the next mass in any
	-- pose. Before it, the knee stood open, each claw sat a stud and a half from
	-- the end of its own shank, and the shanks finished under the floor.
	--
	-- WHERE THE KNEE SITS IS A RIG DECISION. PlantSway takes the leg parts in the
	-- upper 45% of the legs' height as hip anchors and hangs everything else on
	-- the nearest one. A knee above that line would become an anchor of its own
	-- and four legs would come back as eight; FEMUR_DROP 1.35 keeps every knee
	-- below it, as a ratio, so it holds on both scale curves.
	--
	-- THE SHANK COUNTER-BENDS back toward vertical instead of continuing the
	-- femur's lean, which is what a stilt-walker's leg does and what keeps each
	-- foot nearest its own hip. The legs of a diagonal pair swing in antiphase,
	-- so a shank that joined the wrong hip would be torn off every stride.
	--
	-- THE CLAW IS THE FOOT. Level, because a foot lies on the ground rather than
	-- carrying the leg's roll; its thick +Z end receives the shank, so the ankle
	-- is inside the deepest part of the wedge; lifted by its rotated corner
	-- reach so the sole rests ON the plane. The rear pair turn half round so the
	-- stance opens instead of huddling. Toe-out is spent sparingly, because it
	-- is paid for in width.
	--
	-- The four are not four copies -- splay, claw length and toe-out differ per
	-- leg, from the table rather than rolled, because two servers must build
	-- the same creature.
	--==========================================================================
	local FEMUR_DROP, KNEE_BEND, TIBIA_DROP = 1.35, rad(16), 0.66
	for _, legSpec in ipairs({
		{ x = -0.7, z = -0.5, pitch = rad(-18), roll = rad(-15), fore = 1, yaw = rad(13), spin = 0, claw = 1.06, kneeYaw = rad(-4) },
		{ x = 0.7, z = -0.5, pitch = rad(-18), roll = rad(15), fore = 1, yaw = rad(-10), spin = 0, claw = 0.97, kneeYaw = rad(3) },
		{ x = -0.7, z = 0.6, pitch = rad(20), roll = rad(-15), fore = -1, yaw = rad(16), spin = math.pi, claw = 0.92, kneeYaw = rad(5) },
		{ x = 0.7, z = 0.6, pitch = rad(20), roll = rad(15), fore = -1, yaw = rad(-12), spin = math.pi, claw = 1.01, kneeYaw = rad(-6) },
	}) do
		local hipCF = baseCF * CFrame.new(legSpec.x, 2.30, legSpec.z) * CFrame.Angles(legSpec.pitch, 0, legSpec.roll)
		local kneeCF = hipCF * CFrame.new(0, -FEMUR_DROP, 0)
		local shinCF = kneeCF * CFrame.Angles(legSpec.fore * KNEE_BEND, 0, 0)
		local ankleCF = shinCF * CFrame.new(0, -TIBIA_DROP, 0)
		shaft("Femur", hipCF, FEMUR_DROP, 0.80, 0.30, 0.44, 0.40, C.MidnightSlate, m)
		-- The knuckle takes the shank's colour, so the leg reads in two zones --
		-- dark thigh, pale lower leg -- and the joint is a change of SHAPE.
		mk({ name = "Knee", size = Vector3.new(0.50, 0.60, 0.62),
			cf = kneeCF * CFrame.Angles(legSpec.fore * KNEE_BEND * 0.5, legSpec.kneeYaw, 0),
			color = C.AmethystDark, parent = m })
		shaft("Tibia", shinCF, TIBIA_DROP, 0.30, 0.30, 0.32, 0.36, C.AmethystDark, m)
		local ankleL = baseCF:ToObjectSpace(ankleCF).Position
		local clawLen = 1.06 * legSpec.claw
		local clawSize = Vector3.new(0.46, 0.34, clawLen)
		local clawRot = CFrame.Angles(0, legSpec.yaw + legSpec.spin, 0)
		mk({ name = "StiltClaw", size = clawSize,
			cf = baseCF * CFrame.new(ankleL.X, 0, ankleL.Z) * clawRot
				* CFrame.new(0, groundLift(clawSize, clawRot), -clawLen * 0.30),
			color = C.VoidBlack, parent = m, wedge = true })
	end

	-- A COMPACT LOWER BODY: the thorax the legs hang from, and a short abdomen
	-- behind it that the stalk rises out of.
	local thoraxCF = baseCF * CFrame.new(0, 3.05, 0) * CFrame.Angles(rad(-8), 0, 0)
	mk({ name = "Thorax", size = Vector3.new(1.45, 1.35, 1.65), cf = thoraxCF, color = C.MidnightSlate, parent = m })
	plate("Abdomen", 1.20, 1.30, 0.95, thoraxCF * CFrame.new(0, -0.35, 1.05) * CFrame.Angles(rad(122), 0, 0),
		C.VoidBlack, m)
	mk({ name = "Collar", size = Vector3.new(1.05, 0.55, 1.05), cf = thoraxCF * CFrame.new(0, 0.85, -0.25),
		color = C.AmethystDark, parent = m })

	-- THE STALK, IN AN S. Three segments turned on from each other: forward,
	-- back, forward again, each thinner than the last.
	local s0 = thoraxCF * CFrame.new(0, 0.95, -0.30) * CFrame.Angles(rad(-24), 0, rad(-4))
	local segs = { { len = 1.25, w = 0.62, bend = 34 }, { len = 1.15, w = 0.52, bend = -30 }, { len = 1.05, w = 0.44, bend = 8 } }
	local cursor = s0
	for i, s in ipairs(segs) do
		-- Round segments, each overrunning its joint by 0.15 so the S has no gaps.
		rod("Stalk" .. i, (cursor * CFrame.new(0, -0.15, 0)).Position,
			(cursor * CFrame.new(0, s.len + 0.15, 0)).Position, s.w,
			if i == 2 then C.AmethystDark else C.IndigoBark, m)
		cursor = cursor * CFrame.new(0, s.len, 0) * CFrame.Angles(rad(s.bend), 0, 0)
	end
	local neckTop = cursor

	-- A SMALL FACE BELOW THE CROWN: a narrow skull on the stalk's top, mantis
	-- eyes on its front corners, a small plate of mandibles under it.
	local headCF = neckTop * CFrame.new(0, 0.30, -0.10) * CFrame.Angles(rad(10), 0, 0)
	mk({ name = "Skull", size = Vector3.new(1.00, 0.80, 1.10), cf = headCF, color = C.MidnightSlate, parent = m })
	for side = -1, 1, 2 do
		local tag = if side < 0 then "Left" else "Right"
		voidEye(m, tag, headCF * CFrame.new(side * 0.42, 0.06, -0.55) * CFrame.Angles(0, rad(side * 18), 0),
			0.36, "mantis", C.MidnightSlate)
	end
	plate("Mandible", 0.72, 0.42, 0.34, headCF * CFrame.new(0, -0.44, -0.36) * CFrame.Angles(rad(104), 0, 0),
		C.VoidBlack, m)

	-- THE CROWN. Two unequal spear-shaped bracts rising off the skull, the seed
	-- chamber recessed between them: a dark socket with the lit seed set back
	-- in it, so the light sits in a cavity rather than on a tip.
	local crownCF = headCF * CFrame.new(0, 0.55, 0.15)
	plate("BractLong", 0.84, 2.80, 0.20, crownCF * CFrame.new(-0.30, 1.25, 0) * CFrame.Angles(rad(-6), rad(8), rad(12)),
		C.StarlightViolet, m)
	plate("BractShort", 0.72, 2.05, 0.20, crownCF * CFrame.new(0.34, 0.90, 0.05) * CFrame.Angles(rad(-10), rad(-6), rad(-16)),
		C.AmethystPale, m, true)
	mk({ name = "ChamberSocket", size = Vector3.new(0.70, 0.90, 0.55), cf = crownCF * CFrame.new(0.02, 0.62, 0.08),
		color = C.VoidBlack, parent = m, smooth = true })
	local chamber = mk({ name = "SeedChamber", size = Vector3.new(0.34, 0.54, 0.30),
		cf = crownCF * CFrame.new(0.02, 0.62, -0.12), color = C.NebulaCyan, parent = m,
		material = Enum.Material.Neon, smooth = true })

	-- A RESTRAINED LEAF CLUSTER on the lower stalk: three unequal blades, all
	-- named Leaf so the walk moves them.
	for i, l in ipairs({
		{ x = -0.42, y = 0.55, pitch = -22, yaw = 30, roll = -48, len = 1.55 },
		{ x = 0.44, y = 0.35, pitch = -18, yaw = -34, roll = 44, len = 1.25 },
		{ x = -0.20, y = 1.35, pitch = -30, yaw = 12, roll = -30, len = 1.05 },
	}) do
		plate("Leaf", 0.42, l.len, 0.16,
			s0 * CFrame.new(l.x, l.y, 0.05) * CFrame.Angles(rad(l.pitch), rad(l.yaw), rad(l.roll)),
			if i == 2 then C.Amethyst else C.StarlightViolet, m, i == 2)
	end

	-- The one light, in the seed chamber: PlantGlow keeps it dark by day.
	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyanGlow
	light.Brightness = 1.6
	light.Range = 10
	light.Parent = chamber
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
-- 4. ASTRALHORN -- THE MOONCREST STAG (Legendary) -- 46 parts (+ 1 Base = 47)
--
-- ONE SENTENCE. A proud botanical quadruped leaning forward: a distinct head on
-- a curved neck, a substantial chest and a narrower rear on four connected
-- root-like legs, and two unequal antler growths framing an open crescent above
-- the face. Sweeping shoulder petals, a few broad bark plates, a recessed
-- muzzle, heavy lids. Majestic and strong.
--
--   dominant   the chest and the curved neck carrying the head
--   support    four legs of thigh, shin, hoof and toe
--   signature  the open crescent of the two antlers
--
-- Over the art bible's 25-40 band, as approved: see the budget at the top.
-- Built exactly as the owner approved it in the redesign preview (fba9ed0).
--==============================================================================
local function buildAstralhorn(parent: Instance, baseCF: CFrame): Model
	local m = Instance.new("Model")
	m.Name = "Astralhorn"
	m.Parent = parent

	--==========================================================================
	-- FOUR LEGS THAT BEND, EVERY PART OF ONE NEARER ITS OWN HIP
	--
	-- A thigh angled out and down, a shin counter-bent back under the hip, a
	-- hoof with a toe wall; every joint overrun (`shaft`) so no pose opens it.
	-- Positive pitch drops the thigh forward. The front pair reach forward and
	-- their shins come back nearly straight; the rear pair counter-bend hard --
	-- a hock -- and their hooves sit behind the ankle.
	--
	-- THAT RAKE IS FOR THE RIG. PlantSway joins every leg part to the hip it is
	-- nearest in plan view, and the preview's first rear leg left its toe
	-- almost equidistant from both hips (1.04:1) -- a toe that could swing with
	-- the wrong leg. Re-raked, every part sits well inside its own leg.
	--
	-- The names carry it: _Thigh is the upper-leg word that makes a hip; _Shin,
	-- _Hoof and _Toe are leg words that hang from one. Nothing on the body --
	-- Withers included -- carries one.
	--==========================================================================
	local HOOF = Vector3.new(1.10, 0.56, 1.30)
	for _, leg in ipairs({
		{ n = "FL", x = -1.10, z = -1.05, pitch = 22, bend = 1.15, back = 0, roll = -9, yaw = 10, toe = 1.00 },
		{ n = "FR", x = 1.10, z = -1.05, pitch = 22, bend = 1.15, back = 0, roll = 9, yaw = -8, toe = 0.94 },
		{ n = "BL", x = -1.10, z = 1.25, pitch = 24, bend = 1.60, back = 0.25, roll = -9, yaw = 12, toe = 1.05 },
		{ n = "BR", x = 1.10, z = 1.25, pitch = 24, bend = 1.60, back = 0.25, roll = 9, yaw = -10, toe = 0.98 },
	}) do
		local hipCF = baseCF * CFrame.new(leg.x, 2.45, leg.z) * CFrame.Angles(rad(leg.pitch), 0, rad(leg.roll))
		local kneeCF = hipCF * CFrame.new(0, -1.15, 0)
		local shinCF = kneeCF * CFrame.Angles(rad(-leg.pitch * leg.bend), 0, 0)
		shaft(leg.n .. "_Thigh", hipCF, 1.15, 0.70, 0.30, 0.78, 0.86, C.IndigoBark, m)
		shaft(leg.n .. "_Shin", shinCF, 1.05, 0.30, 0.25, 0.56, 0.62, C.MidnightSlate, m)
		local ankleL = baseCF:ToObjectSpace(shinCF * CFrame.new(0, -1.05, 0)).Position
		local groundCF = baseCF * CFrame.new(ankleL.X * 0.92, 0, ankleL.Z + leg.back)
		mk({ name = leg.n .. "_Hoof", size = HOOF,
			cf = groundCF * CFrame.Angles(0, rad(leg.yaw), 0) * CFrame.new(0, HOOF.Y * 0.5, 0.08),
			color = C.VoidBlack, parent = m })
		-- The toe wall off the front of the hoof, so a foot is not a plain pad.
		local toeSize = Vector3.new(0.92, 0.46, 0.78 * leg.toe)
		local toeRot = CFrame.Angles(0, rad(leg.yaw), 0)
		mk({ name = leg.n .. "_Toe", size = toeSize,
			cf = groundCF * toeRot * CFrame.new(0, groundLift(toeSize, toeRot),
				-(HOOF.Z * 0.5 + toeSize.Z * 0.5 - 0.30)),
			color = C.AmethystDark, parent = m, wedge = true })
	end

	-- THE BODY: a substantial chest forward, a narrower rear body, a belly
	-- wedge under the join, a shoulder mass the neck rises from.
	local bodyCF = baseCF * CFrame.new(0, 3.05, 0.10) * CFrame.Angles(rad(-5), 0, 0)
	mk({ name = "Chest", size = Vector3.new(2.45, 2.15, 2.30), cf = bodyCF * CFrame.new(0, 0.10, -0.75),
		color = C.IndigoBark, parent = m })
	mk({ name = "RearBody", size = Vector3.new(1.95, 1.75, 2.10), cf = bodyCF * CFrame.new(0, -0.05, 1.20) * CFrame.Angles(rad(6), 0, 0),
		color = C.MidnightSlate, parent = m })
	plate("Belly", 1.80, 1.60, 0.90, bodyCF * CFrame.new(0, -0.95, 0.25) * CFrame.Angles(rad(96), 0, 0), C.VoidBlack, m)
	mk({ name = "Withers", size = Vector3.new(1.75, 1.10, 1.50), cf = bodyCF * CFrame.new(0, 1.05, -0.95) * CFrame.Angles(rad(-18), 0, 0),
		color = C.IndigoBark, parent = m })
	-- Three bark plates: one over the withers, one along each flank, unequal.
	slab("BarkPlate1", 1.35, 1.40, 0.22, bodyCF * CFrame.new(0.10, 1.50, 0.15) * CFrame.Angles(rad(-84), rad(6), 0), C.AmethystDark, m)
	slab("BarkPlate2", 1.10, 1.55, 0.22, bodyCF * CFrame.new(-1.28, 0.55, 0.20) * CFrame.Angles(rad(8), rad(84), rad(-12)), C.AmethystDark, m)
	slab("BarkPlate3", 0.95, 1.30, 0.22, bodyCF * CFrame.new(1.25, 0.40, 0.55) * CFrame.Angles(rad(-6), rad(-80), rad(10)), C.MidnightSlate, m)

	-- THE NECK, CURVED: two segments rising forward and up, the second turning
	-- to carry the head level.
	local n0 = bodyCF * CFrame.new(0, 1.15, -1.35) * CFrame.Angles(rad(-46), 0, 0)
	mk({ name = "NeckLow", size = Vector3.new(1.10, 1.55, 1.10), cf = n0 * CFrame.new(0, 0.55, 0), color = C.IndigoBark, parent = m })
	local n1 = n0 * CFrame.new(0, 1.15, 0) * CFrame.Angles(rad(30), 0, 0)
	mk({ name = "NeckHigh", size = Vector3.new(0.92, 1.35, 0.95), cf = n1 * CFrame.new(0, 0.50, 0), color = C.MidnightSlate, parent = m })

	-- THE HEAD: a skull, a muzzle projecting forward with its recess set back
	-- between the cheeks, a lower jaw under it, heavy lids over deep-set eyes.
	local headCF = n1 * CFrame.new(0, 1.00, -0.25) * CFrame.Angles(rad(22), 0, 0)
	mk({ name = "Skull", size = Vector3.new(1.55, 1.30, 1.55), cf = headCF, color = C.MidnightSlate, parent = m })
	mk({ name = "Muzzle", size = Vector3.new(1.00, 0.72, 1.20), cf = headCF * CFrame.new(0, -0.32, -1.05) * CFrame.Angles(rad(4), 0, 0),
		color = C.IndigoBark, parent = m })
	mk({ name = "MuzzleRecess", size = Vector3.new(0.72, 0.30, 0.30), cf = headCF * CFrame.new(0, -0.52, -1.30),
		color = C.VoidBlack, parent = m, smooth = true })
	plate("LowerJaw", 0.86, 1.05, 0.34, headCF * CFrame.new(0, -0.84, -0.75) * CFrame.Angles(rad(98), 0, 0), C.VoidBlack, m)
	for side = -1, 1, 2 do
		local tag = if side < 0 then "Left" else "Right"
		-- On the skull's front face: it is 1.55 deep, so the surface is 0.775 out.
		voidEye(m, tag, headCF * CFrame.new(side * 0.50, 0.12, -0.775), 0.40, "deepset", C.IndigoBark, 0.02)
	end

	-- THE ANTLERS: two unequal growths, three segments each, curving up and in
	-- to frame an open crescent above the face; the right carries a tine.
	for side = -1, 1, 2 do
		local long = side > 0
		local h1 = headCF * CFrame.new(side * 0.62, 0.62, 0.20) * CFrame.Angles(rad(-10), rad(side * 22), rad(side * 34))
		mk({ name = "AntlerBase" .. (if long then "R" else "L"), size = Vector3.new(0.42, 1.30, 0.42), cf = h1 * CFrame.new(0, 0.55, 0),
			color = C.Amethyst, parent = m })
		local h2 = h1 * CFrame.new(0, 1.10, 0) * CFrame.Angles(rad(12), 0, rad(-side * 40))
		mk({ name = "AntlerMid" .. (if long then "R" else "L"), size = Vector3.new(0.34, if long then 1.45 else 1.10, 0.34),
			cf = h2 * CFrame.new(0, (if long then 1.45 else 1.10) * 0.5, 0), color = C.AmethystPale, parent = m })
		local h3 = h2 * CFrame.new(0, if long then 1.35 else 1.00, 0) * CFrame.Angles(rad(-18), 0, rad(-side * 36))
		plate("AntlerTip" .. (if long then "R" else "L"), 0.30, if long then 1.05 else 0.80, 0.24,
			h3 * CFrame.new(0, (if long then 1.05 else 0.80) * 0.5, 0), C.Ivory, m, not long)
		if long then
			plate("AntlerTine", 0.26, 0.70, 0.22, h1 * CFrame.new(side * 0.12, 0.95, -0.18) * CFrame.Angles(rad(38), 0, rad(side * 26)),
				C.Ivory, m)
		end
	end

	-- SHOULDER PETALS: two per side sweeping back along the body, named Leaf so
	-- the walk lags them. The upper pair is the larger.
	for side = -1, 1, 2 do
		plate("Leaf", 0.72, 2.20, 0.18, bodyCF * CFrame.new(side * 1.30, 1.05, -0.55) * CFrame.Angles(rad(62), rad(side * 28), rad(side * 22)),
			C.Lavender, m, side > 0)
		plate("Leaf", 0.58, 1.65, 0.16, bodyCF * CFrame.new(side * 1.30, 0.35, 0.35) * CFrame.Angles(rad(58), rad(side * 36), rad(side * 18)),
			C.AmethystPale, m, side < 0)
	end

	-- The one light, in the skull: PlantGlow keeps it dark by day.
	local light = Instance.new("PointLight")
	light.Color = C.NebulaCyanGlow
	light.Brightness = 1.5
	light.Range = 10
	light.Parent = m:FindFirstChild("Skull") or m
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
-- cosmospire +7.6%, voidpetal +10.3%, astralhorn +8.9%, supernovus +9.6% -- the
-- first three on the builds they replaced. The 2026-09-23 redesigns measure
-- novaorb +9.1%, cosmospire +9.6%, astralhorn +8.2%.
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
