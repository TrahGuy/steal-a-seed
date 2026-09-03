--!strict
--==============================================================================
-- EMBERROOT, AS APPROVED
--
-- The five plants were designed as a temporary Edit-mode mockup under
-- `Workspace.EmberrootSpeciesMockup`, reviewed there, and approved there. This
-- file is those plants, lifted verbatim and frozen.
--
-- IT IS ART, NOT ART DIRECTION. Nothing here was redrawn, recoloured or tidied
-- on the way across; every size, CFrame and colour is the number that was
-- approved, and the banners explaining WHY each shape is what it is came with
-- them. A preview folder is a scratchpad that gets deleted, so the approved
-- geometry had to stop living in one -- but "translate it into code" only counts
-- if the translation is lossless.
--
--==============================================================================
-- WHAT IS SHARED, AND WHY
--
-- Cinderpaw's approval fixed the biome's body: a cracked cinder pad, two braced
-- root-legs, a bent three-segment stem with one heat crack, two small fore-limbs
-- and a face bulb with a brow, a hanging jaw and a glowing throat. All five
-- carry it, exactly as Greenhollow's five share a soil heap and Tanglemire's
-- five share a peat hummock. That is the family resemblance.
--
-- What varies is the CROWN and the FACE, because the crown is the dominant mass
-- in every case -- a plant that has limbs, not a creature that has leaves.
--
--==============================================================================
-- HOW IT SCALES, AND WHY AUTHORED IS MEASURED RATHER THAN CHOSEN
--
-- Each plant was drawn at its own size and the FIVE SIZES RELATIVE TO EACH OTHER
-- ARE PART OF THE APPROVAL. Tanglemire settled this precedent: its five were
-- conformed by one shared factor because re-laddering them independently would
-- have reversed Lanterncap and Snapmoss. The same applies here, so AUTHORED
-- records what each plant actually measures and SeedData.Height is that number
-- times one factor shared by all five.
--
-- The spread is wide -- Emberquill is 1.73x Cinderpaw -- and that is the
-- approved shape of the biome, not a mistake. Greenhollow spans 1.67x for the
-- same reason; Tanglemire's narrow 1.12x is the outlier.
--==============================================================================

local EmberrootForms = {}

-- Position scales; rotation does not. Subtracting a CFrame's own position
-- leaves the rotation-only CFrame. The same arithmetic every other builder in
-- the project uses, so nothing grows differently here.
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

local C = {
	Basalt     = Color3.fromRGB(52, 40, 38),
	Bark       = Color3.fromRGB(88, 60, 48),
	BarkPale   = Color3.fromRGB(120, 86, 66),
	Ember      = Color3.fromRGB(255, 118, 44),
	EmberDeep  = Color3.fromRGB(198, 68, 24),
	EmberPale  = Color3.fromRGB(255, 166, 78),
	Throat     = Color3.fromRGB(255, 186, 96),
	EyeGlow    = Color3.fromRGB(255, 222, 150),
	Glint      = Color3.fromRGB(255, 255, 255),
	Char       = Color3.fromRGB(30, 24, 23),
	Cinder     = Color3.fromRGB(92, 46, 32),
	-- Per-species accents, still inside the ember family so the biome holds.
	Quill      = Color3.fromRGB(255, 200, 92),
	Slag       = Color3.fromRGB(168, 38, 30),
	SlagDrip   = Color3.fromRGB(255, 96, 30),
	Kiln       = Color3.fromRGB(74, 58, 54),
	KilnGlow   = Color3.fromRGB(255, 148, 40),
	Lotus      = Color3.fromRGB(255, 140, 96),
	LotusDeep  = Color3.fromRGB(214, 62, 74),
	LotusCore  = Color3.fromRGB(255, 236, 176),
	-- Neon renders roughly the part colour at full brightness, so a near-white
	-- core came out as a plain white ball. This is saturated enough to stay
	-- orange under its own light.
	CoreEmber  = Color3.fromRGB(255, 162, 62),
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
	local face = if o.smooth then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
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
-- FIVE BODIES, NOT ONE
--
-- The art bible shares LEAF, STEM and SOIL across a biome and gives each species
-- its own Body, Crown and Accent. The first Emberroot build shared the entire
-- body, so five species read as one plant in five hats.
--
-- Shared now: the cinder pad and the root-legs. That is the ground contact, and
-- it is what still makes these one biome.
--
-- Varying: stem, limbs, bulb, brow, jaw and crown. Each body sits at a
-- different VALUE as well as a different hue, so the five separate in greyscale
-- and not only in colour -- which is the check the skill actually asks for.
--==============================================================================
type Palette = {
	stem: Color3,
	stemPale: Color3,
	bulb: Color3,
	brow: Color3,
	crack: Color3,
}

local PALETTES: { [string]: Palette } = {
	-- Cinderpaw: the approved one. Warm charcoal, mid value.
	cinderpaw = {
		stem = Color3.fromRGB(88, 60, 48), stemPale = Color3.fromRGB(120, 86, 66),
		bulb = Color3.fromRGB(52, 40, 38), brow = Color3.fromRGB(88, 60, 48),
		crack = Color3.fromRGB(198, 68, 24),
	},
	-- Emberquill: dry and pale, the lightest of the five. Bleached ash wood.
	emberquill = {
		stem = Color3.fromRGB(150, 122, 92), stemPale = Color3.fromRGB(188, 162, 128),
		bulb = Color3.fromRGB(96, 78, 62), brow = Color3.fromRGB(150, 122, 92),
		crack = Color3.fromRGB(255, 196, 78),
	},
	-- Slagbloom: crimson-black, the darkest and hottest. Cooling slag.
	slagbloom = {
		stem = Color3.fromRGB(74, 30, 28), stemPale = Color3.fromRGB(104, 44, 38),
		bulb = Color3.fromRGB(38, 18, 18), brow = Color3.fromRGB(74, 30, 28),
		crack = Color3.fromRGB(255, 84, 26),
	},
	-- Kilnhusk: cool grey stone, the only one that is not warm. Fired clay.
	kilnhusk = {
		stem = Color3.fromRGB(96, 92, 88), stemPale = Color3.fromRGB(132, 126, 120),
		bulb = Color3.fromRGB(60, 58, 56), brow = Color3.fromRGB(96, 92, 88),
		crack = Color3.fromRGB(255, 148, 40),
	},
	-- Pyrelotus: violet-charcoal, the only cool-dark. Reads exotic beside the
	-- other four, which is the Mythic doing its job before you read the word.
	--
	-- The first values were too dark to work. The bulb was the darkest of the
	-- five at a relative luminance of 21, and unlike Slagbloom -- which is nearly
	-- as dark but wears a bright crown right above its face -- this species is
	-- violet everywhere, so the face had nothing to sit against and the eyes and
	-- jaw disappeared into the head. The HUE is unchanged, which is what carries
	-- the "only cool-dark" reading; only the value is lifted, to about 44, so the
	-- face is legible at the range a player actually walks past it.
	pyrelotus = {
		stem = Color3.fromRGB(66, 38, 66), stemPale = Color3.fromRGB(96, 62, 94),
		bulb = Color3.fromRGB(52, 32, 56), brow = Color3.fromRGB(66, 38, 66),
		crack = Color3.fromRGB(255, 128, 148),
	},
}

--==============================================================================
-- THE GROUND ROOTS
--
-- WHAT WAS HERE was one part called CinderPad: 2.30 x 0.26 x 2.10, a flat
-- charcoal rectangle under every plant in the biome. It read as a slab at Tiny,
-- and because it scaled with the body it became a black square well over a
-- hundred studs across at Colossal -- the plot paved over, and the one shape in
-- Emberroot that announced itself as a Roblox part.
--
-- WHAT REPLACES IT is a root system sculpted from overlapping tapered masses.
-- Primitive CONSTRUCTION is fine; primitive APPEARANCE is not, and these are the
-- rules that separate the two, in the order they matter:
--
--   NO SEGMENT IS A FINISHED SHAPE. A root is two to four short masses that
--   overlap by about a fifth of their length, so each joint is buried inside the
--   mass before it. One long part reads as a bar however it is angled.
--
--   NOTHING REPEATS. Yaw, pitch, roll, width, thickness and length all change
--   between segments and between roots, driven by a deterministic hash of the
--   root's seed and the segment index. Deterministic rather than random because
--   the server and every client must build the same plant, and because
--   "authored" means the same shape every time -- but never the same recipe
--   twice, and never evenly spaced around the stem.
--
--   IT RISES AND FALLS. Each path lifts at its middle and returns to the ground
--   at its tip, so from the side the system is not a pancake.
--
--   THE TIP IS A WEDGE. A flat rectangular end is the clearest tell that a root
--   is really a box.
--
--   FORKS ARE UNEQUAL and one direction always dominates. A root system with
--   four matching arms is a wheel.
--
-- NAMES AVOID PlantSway'S LEG VOCABULARY on purpose -- no Thigh, Shin, Foot,
-- Toe, Paw or Hoof anywhere in here. These roots travel with the body and must
-- never be picked up as a limb to swing; the walking feet below are the parts
-- that are allowed those words.
--==============================================================================
type RootSpec = {
	yaw: number,      -- degrees around the stem, measured off +Z
	reach: number,    -- how far the whole path runs
	segs: number,     -- 2 .. 4 overlapping masses
	w: number,        -- width where it leaves the knot
	t: number,        -- thickness where it leaves the knot
	taper: number,    -- tip width as a fraction of w
	lift: number,     -- how high the middle of the path rises
	drift: number,    -- degrees the path wanders across its run
	seed: number,
	broken: boolean?, -- snapped short at the tip
}

-- Deterministic irregularity. A hash rather than a Random: the plant has to come
-- out identical wherever it is built, and a shape that changes between the
-- server and the client is not an approved shape at all.
local function wob(seed: number, i: number): number
	local x = math.sin(seed * 12.9898 + i * 78.233) * 43758.5453
	return x - math.floor(x)
end

local function jit(seed: number, i: number, amount: number): number
	return (wob(seed, i) - 0.5) * 2 * amount
end

--==============================================================================
-- SITTING ON THE GROUND, NOT THROUGH IT
--
-- Nothing in the root system may reach below the plant's base plane -- it is
-- planted in soil the player can walk on, and a root corner under the floor is
-- a root corner poking out of somebody's plot from beneath.
--
-- Half the thickness is the right lift only for a box that is not turned. These
-- are all turned, in pitch and in roll, on purpose -- and a rotated box reaches
-- further below its own centre than half its height. Measured before this was
-- added: 0.12 studs through the plane at Tiny and 0.22 at Colossal, on every
-- one of the five.
--
-- The exact reach is the box's three half-extents projected onto world Y, which
-- is what the three axis vectors give. Lifting by precisely that puts the lowest
-- corner ON the plane rather than a guessed distance above it.
--==============================================================================
local function groundLift(size: Vector3, rot: CFrame): number
	return size.X * 0.5 * math.abs(rot.RightVector.Y)
		+ size.Y * 0.5 * math.abs(rot.UpVector.Y)
		+ size.Z * 0.5 * math.abs(rot.LookVector.Y)
end

--==============================================================================
-- ONE ROOT, LAID ALONG AN IRREGULAR PATH
--
-- `place` is the caller's part maker, already carrying the plant's base frame
-- and the GroundRoot tag. Everything here is authored at scale 1; Build applies
-- the damped root scale afterwards.
--==============================================================================
local function layRoot(m: Model, place: (Opts) -> BasePart, spec: RootSpec,
	bark: Color3, dark: Color3)
	local run = spec.reach / spec.segs
	local yaw = rad(spec.yaw)
	-- Start inside the knot rather than at the stem's centre, so the first
	-- segment emerges from a mass instead of from a point.
	local dist = 0.26
	for i = 1, spec.segs do
		local last = i == spec.segs
		local u = (i - 0.5) / spec.segs
		local len = run * (1 + jit(spec.seed, i, 0.30))
		if spec.broken and last then
			-- Snapped. A root that stops mid-stride is worth more than a root
			-- that tapers politely to nothing.
			len *= 0.55
		end
		-- Width and thickness both taper, and deliberately not at the same rate:
		-- a root that thins evenly in both reads as a cone.
		local w = spec.w * (1 - (1 - spec.taper) * u) * (1 + jit(spec.seed, i + 7, 0.20))
		local t = spec.t * (1 - (1 - spec.taper * 0.75) * u) * (1 + jit(spec.seed, i + 13, 0.16))
		-- The path wanders across its run and jitters per segment.
		local a = yaw + rad(spec.drift) * u + rad(jit(spec.seed, i + 3, 15))
		local rise = math.sin(u * math.pi) * spec.lift
		local mid = dist + len * 0.5
		local size = Vector3.new(w, t, len)
		local rot = CFrame.Angles(0, a, 0)
			* CFrame.Angles(rad(jit(spec.seed, i + 5, 7)), 0,
				rad(jit(spec.seed, i + 11, 14)))
		place({
			name = if last then "RootSpurTip" else "RootSpur",
			size = size,
			-- Lifted by the turned box's own reach, plus the arc. See groundLift.
			cf = CFrame.new(math.sin(a) * mid, groundLift(size, rot) + rise,
				math.cos(a) * mid) * rot,
			color = if last then dark else bark,
			wedge = last,
			parent = m,
		})
		-- Overlap, so the joint disappears inside the mass before it.
		dist += len * 0.78
	end
end

--==============================================================================
-- THE KNOT, AND WHY IT IS THREE MASSES
--
-- Where the roots meet the stem is the most-looked-at point of the sculpture,
-- and one Ball or one cube there is the single clearest way to say "primitive".
-- Three overlapping masses at disagreeing angles, none of them centred, none of
-- them the same proportion.
--==============================================================================
local function layKnot(m: Model, place: (Opts) -> BasePart, seed: number)
	local masses = {
		{ Vector3.new(0.94, 0.42, 0.88), 0.03, -0.02,
			CFrame.Angles(rad(5), rad(23 + jit(seed, 1, 12)), rad(-4)), C.Basalt },
		{ Vector3.new(0.72, 0.36, 1.04), -0.15, 0.12,
			CFrame.Angles(rad(-6), rad(-38 + jit(seed, 2, 14)), rad(7)), C.Char },
		{ Vector3.new(0.60, 0.31, 0.68), 0.20, 0.17,
			CFrame.Angles(rad(9), rad(64 + jit(seed, 3, 16)), rad(-11)), C.Basalt },
	}
	for _, mass in ipairs(masses) do
		local size = mass[1] :: Vector3
		local rot = mass[4] :: CFrame
		place({ name = "RootKnot", size = size,
			cf = CFrame.new(mass[2] :: number, groundLift(size, rot), mass[3] :: number) * rot,
			color = mass[5] :: Color3, parent = m })
	end
end

--==============================================================================
-- THE FIVE ROOT PROFILES
--
-- One system, five silhouettes. Each has a DOMINANT direction, a supporting
-- counter-root and one or two shorter or broken branches, and the negative space
-- between them is deliberately uneven -- the gaps are as authored as the roots.
--==============================================================================
local ROOTS: { [string]: { RootSpec } } = {
	-- CINDERPAW: a low, wide, braced stance. Short heavy runs and a broad front
	-- pair, so it reads as crouched and about to move without ever becoming four
	-- animal paws.
	cinderpaw = {
		{ yaw = 22,   reach = 2.05, segs = 3, w = 0.44, t = 0.28, taper = 0.34, lift = 0.07, drift = -26, seed = 11 },
		{ yaw = 196,  reach = 1.62, segs = 3, w = 0.38, t = 0.25, taper = 0.30, lift = 0.05, drift = 20,  seed = 23 },
		{ yaw = 104,  reach = 1.18, segs = 2, w = 0.30, t = 0.21, taper = 0.32, lift = 0.09, drift = 30,  seed = 37, broken = true },
		{ yaw = 288,  reach = 1.02, segs = 2, w = 0.27, t = 0.19, taper = 0.30, lift = 0.04, drift = -22, seed = 51 },
	},
	-- EMBERQUILL: everything dragged one way, like quills scorched flat by a
	-- wind. The single short forward root is what stops the back three reading
	-- as a fan.
	emberquill = {
		{ yaw = 184,  reach = 2.24, segs = 3, w = 0.30, t = 0.19, taper = 0.22, lift = 0.10, drift = 16,  seed = 61 },
		{ yaw = 149,  reach = 1.88, segs = 3, w = 0.25, t = 0.17, taper = 0.20, lift = 0.13, drift = 24,  seed = 73 },
		{ yaw = 217,  reach = 1.54, segs = 2, w = 0.23, t = 0.16, taper = 0.24, lift = 0.08, drift = -18, seed = 89 },
		{ yaw = 6,    reach = 0.86, segs = 2, w = 0.22, t = 0.15, taper = 0.28, lift = 0.03, drift = -34, seed = 97, broken = true },
	},
	-- SLAGBLOOM: three heavy masses and one unequal fork off the dominant one.
	-- Thick, short and partly collapsed -- cooled slag that broke as it set.
	slagbloom = {
		{ yaw = 332,  reach = 1.96, segs = 3, w = 0.52, t = 0.33, taper = 0.40, lift = 0.06, drift = 22,  seed = 103 },
		{ yaw = 302,  reach = 1.14, segs = 2, w = 0.34, t = 0.24, taper = 0.36, lift = 0.11, drift = -26, seed = 113, broken = true },
		{ yaw = 84,   reach = 1.78, segs = 2, w = 0.47, t = 0.31, taper = 0.42, lift = 0.04, drift = -20, seed = 127 },
		{ yaw = 198,  reach = 1.44, segs = 2, w = 0.41, t = 0.28, taper = 0.38, lift = 0.08, drift = 28,  seed = 139, broken = true },
	},
	-- KILNHUSK: architectural, the broadest of the five, braced like a furnace
	-- footing -- but at four UNEQUAL yaws with unequal reach and a broken corner,
	-- because four matching supports is a table and not a plant.
	kilnhusk = {
		{ yaw = 28,   reach = 1.94, segs = 3, w = 0.56, t = 0.31, taper = 0.46, lift = 0.05, drift = -18, seed = 149 },
		{ yaw = 121,  reach = 1.52, segs = 2, w = 0.49, t = 0.28, taper = 0.44, lift = 0.09, drift = 24,  seed = 157 },
		{ yaw = 209,  reach = 1.80, segs = 3, w = 0.52, t = 0.30, taper = 0.42, lift = 0.06, drift = 16,  seed = 167 },
		{ yaw = 303,  reach = 1.22, segs = 2, w = 0.44, t = 0.26, taper = 0.40, lift = 0.11, drift = -30, seed = 179, broken = true },
	},
	-- PYRELOTUS: five directions, and the whole point is that they are NOT five
	-- petals. One dominant, two supporting it at unequal angles, two short and
	-- broken -- an opened lotus that has burnt unevenly.
	pyrelotus = {
		{ yaw = 14,   reach = 2.18, segs = 3, w = 0.34, t = 0.21, taper = 0.26, lift = 0.12, drift = 20,  seed = 191 },
		{ yaw = 86,   reach = 1.66, segs = 2, w = 0.29, t = 0.19, taper = 0.28, lift = 0.09, drift = -24, seed = 199 },
		{ yaw = 296,  reach = 1.58, segs = 2, w = 0.28, t = 0.18, taper = 0.26, lift = 0.14, drift = 26,  seed = 211 },
		{ yaw = 168,  reach = 1.06, segs = 2, w = 0.24, t = 0.16, taper = 0.30, lift = 0.05, drift = -32, seed = 223, broken = true },
		{ yaw = 236,  reach = 0.92, segs = 2, w = 0.22, t = 0.15, taper = 0.32, lift = 0.07, drift = 18,  seed = 227, broken = true },
	},
}

--==============================================================================
-- THE SHARED BODY -- ground contact shared, everything above it per-species
--
-- Returns the crown hub and the head frame, because those are the two places a
-- species is allowed to differ.
--==============================================================================
type Body = { hub: CFrame, head: CFrame }

local function body(m: Model, at: CFrame, stemScale: number, brace: number,
	pal: Palette, roots: { RootSpec }, rootSeed: number): Body
	local function P(o: Opts): BasePart
		o.cf = at * o.cf
		o.parent = m
		return mk(o)
	end

	--== GROUND ROOTS ==--
	-- Tagged rather than named, so Build can scale them on their own curve
	-- without matching on strings. See ROOT_DAMP.
	local function R(o: Opts): BasePart
		o.cf = at * o.cf
		o.parent = m
		local p = mk(o)
		p:SetAttribute("GroundRoot", true)
		return p
	end
	layKnot(m, R, rootSeed)
	for _, spec in ipairs(roots) do
		layRoot(m, R, spec, C.Bark, C.Basalt)
	end
	-- ONE OR TWO FISSURES, AND THEY LIE ALONG THE ROOT. Neon is the loudest
	-- thing available and a glowing ball in the roots would out-shout the face,
	-- so the heat is a thin split following the dominant root's own line -- the
	-- crack the stem already wears, continued into the ground.
	do
		local lead = roots[1]
		local a = rad(lead.yaw + lead.drift * 0.35)
		local fs = Vector3.new(0.06, 0.045, lead.reach * 0.46)
		local fr = CFrame.Angles(0, a, 0) * CFrame.Angles(rad(-4), 0, rad(6))
		R({ name = "RootFissure", size = fs,
			-- Sitting ON the root it splits, not floating over it: the lift is
			-- the fissure's own reach plus most of the root's thickness.
			cf = CFrame.new(math.sin(a) * lead.reach * 0.40,
					groundLift(fs, fr) + lead.t * 0.42,
					math.cos(a) * lead.reach * 0.40) * fr,
			color = pal.crack, material = Enum.Material.Neon, smooth = true, parent = m })
		if #roots >= 4 then
			local b = roots[3]
			local ab = rad(b.yaw - 8)
			local bs = Vector3.new(0.05, 0.04, b.reach * 0.34)
			local br = CFrame.Angles(0, ab, 0) * CFrame.Angles(rad(3), 0, rad(-9))
			R({ name = "RootFissure", size = bs,
				cf = CFrame.new(math.sin(ab) * b.reach * 0.36,
						groundLift(bs, br) + b.t * 0.40,
						math.cos(ab) * b.reach * 0.36) * br,
				color = pal.crack, material = Enum.Material.Neon, smooth = true, parent = m })
		end
	end

	--== ROOT-LEGS ==--
	for i = 0, 1 do
		local side = (i == 0) and -1 or 1
		local tag = (i == 0) and "LeftRoot" or "RightRoot"
		local hip = at * CFrame.new(side * 0.34, 0.92, 0.02)
			* CFrame.Angles(rad(-8), side * rad(14), side * rad(-30 - brace))

		mk({ name = tag .. "Thigh", size = Vector3.new(0.46, 0.78, 0.52),
			cf = hip * CFrame.new(0, -0.30, 0.02) * CFrame.Angles(rad(14), 0, 0),
			color = C.Bark, parent = m })
		mk({ name = tag .. "Shin", size = Vector3.new(0.38, 0.64, 0.44),
			cf = hip * CFrame.new(side * 0.16, -0.42, -0.10)
				* CFrame.Angles(rad(-26), 0, side * rad(-14)),
			color = C.Basalt, parent = m })
		--======================================================================
		-- THE FOOT IS A ROOT TOO
		--
		-- The sole was a 0.52 x 0.24 x 0.72 box with one wedge on the front of
		-- it -- a shoe. It is a splayed root foot now: a narrower sole, a
		-- forward claw, and two tapered toes at unequal angles.
		--
		-- THE TOES CARRY "Toe" IN THEIR NAMES ON PURPOSE. PlantSway matches leg
		-- parts by that vocabulary and clusters them onto the nearest hip, so
		-- naming them this way is what makes them swing WITH this leg instead of
		-- staying behind while it steps. The ground roots above are named to
		-- avoid exactly these words for the opposite reason.
		--======================================================================
		mk({ name = tag .. "Sole", size = Vector3.new(0.42, 0.20, 0.62),
			cf = hip * CFrame.new(side * 0.24, -0.64, -0.24)
				* CFrame.Angles(rad(6), side * rad(16), side * rad(-5)),
			color = C.Basalt, parent = m })
		mk({ name = tag .. "Claw", size = Vector3.new(0.21, 0.17, 0.40),
			cf = hip * CFrame.new(side * 0.20, -0.67, -0.60)
				* CFrame.Angles(rad(-12), side * rad(14), 0),
			color = C.Char, wedge = true, parent = m })
		mk({ name = tag .. "Toe1", size = Vector3.new(0.15, 0.13, 0.34),
			cf = hip * CFrame.new(side * 0.40, -0.68, -0.46)
				* CFrame.Angles(rad(-8), side * rad(42), side * rad(9)),
			color = C.Basalt, wedge = true, parent = m })
		mk({ name = tag .. "Toe2", size = Vector3.new(0.13, 0.11, 0.28),
			cf = hip * CFrame.new(side * 0.06, -0.69, -0.48)
				* CFrame.Angles(rad(-6), side * rad(-27), side * rad(-7)),
			color = C.Char, wedge = true, parent = m })
	end

	--== STEM: three segments that disagree ==--
	local h = stemScale
	P({ name = "StemBase", size = Vector3.new(0.86, 0.80 * h, 0.82),
		cf = CFrame.new(0, 0.62 * h, 0.02) * CFrame.Angles(rad(4), 0, rad(-3)),
		color = pal.stem, parent = m })
	P({ name = "StemMid", size = Vector3.new(0.68, 0.86 * h, 0.66),
		cf = CFrame.new(0.06, 1.34 * h, -0.04) * CFrame.Angles(rad(-6), rad(8), rad(5)),
		color = pal.stem, parent = m })
	P({ name = "StemTop", size = Vector3.new(0.54, 0.74 * h, 0.54),
		cf = CFrame.new(0.02, 2.02 * h, -0.10) * CFrame.Angles(rad(8), rad(-6), rad(-4)),
		color = pal.stemPale, parent = m })
	P({ name = "StemCrack", size = Vector3.new(0.10, 0.92 * h, 0.09),
		cf = CFrame.new(-0.22, 1.32 * h, -0.34) * CFrame.Angles(rad(-4), 0, rad(8)),
		color = pal.crack, material = Enum.Material.Neon, smooth = true, parent = m })

	--== FORE-LIMBS ==--
	for i = 0, 1 do
		local side = (i == 0) and -1 or 1
		local tag = (i == 0) and "LeftLimb" or "RightLimb"
		local reach = (i == 0) and 0 or 14
		local sh = at * CFrame.new(side * 0.36, 1.62 * h, -0.16)
			* CFrame.Angles(rad(34 + reach), side * rad(-22), side * rad(38))

		mk({ name = tag .. "Upper", size = Vector3.new(0.28, 0.56, 0.30),
			cf = sh * CFrame.new(0, -0.22, 0), color = pal.stem, parent = m })
		mk({ name = tag .. "Fore", size = Vector3.new(0.23, 0.50, 0.25),
			cf = sh * CFrame.new(side * 0.05, -0.64, 0.12) * CFrame.Angles(rad(36), 0, 0),
			color = pal.stemPale, parent = m })
		mk({ name = tag .. "Claw", size = Vector3.new(0.17, 0.16, 0.34),
			cf = sh * CFrame.new(side * 0.05, -0.88, 0.30)
				* CFrame.Angles(rad(64), 0, side * rad(12)),
			color = C.Char, wedge = true, parent = m })
	end

	return {
		hub = at * CFrame.new(0.02, 3.24 * h, 0.10),
		head = at * CFrame.new(0.02, 2.44 * h, -0.46) * CFrame.Angles(rad(19), rad(-4), 0),
	}
end

--==============================================================================
-- THE FACE -- shared shape, per-species proportions
--
-- No smile bars and no blush cheeks: the mouth is the GAP between bulb and jaw,
-- with the throat lit inside it. `wide` fattens the whole head for the species
-- that need a heavier read.
--==============================================================================
--==============================================================================
-- THE FACE
--
-- Held to the same rules CreatureModel's addFace states, because a player reads
-- Emberroot's plants next to Greenhollow's and a face that follows different
-- rules looks wrong without them being able to say why. Two of those rules had
-- been broken here, and they were the two the production file calls out by name.
--
-- THE EYE IS DARK AND THE GLINT IS THE HOT PART.
--
-- The eyeball used to be Neon EyeGlow -- 255, 222, 150, near enough to white
-- that it rendered as a flat blown-out disc. The glint then sat on top of an
-- already-white ball and did nothing, so the ONE SHARED LIGHT rule, which
-- CreatureModel describes as "what makes two spheres read as one face lit from
-- one side instead of two googly eyes", had no way to show. Two blank circles
-- is exactly what came out.
--
-- The glow simply moves: the eye takes a dark body and the glint becomes the
-- emissive part. Costs nothing, reads as an eye rather than a disc, and it
-- suits the biome better -- these should look lit from inside. The offset stays
-- the same on BOTH eyes, never mirrored, which is the whole point of the rule.
--
-- THE MOUTH IS THREE BLOCKS, NOT ONE BAR.
--
-- CreatureModel: "still three blocks -- one bar reads as a grimace". This had
-- one, and it read as a letterbox. Three, with the ends lifted a hair, is what
-- the rest of the game's creatures do. It stays Neon in the species' own throat
-- colour, because Cinderpaw's signature IS the ember maw and a dark line would
-- throw that away.
--==============================================================================
--==============================================================================
-- THE FIVE HEAD PROFILES
--
-- One carving system, five silhouettes. Every field exists because some species
-- needed it to stop looking like the others: `long` stretches the snout,
-- `jawSquare` squares the jaw off, `heavySide` picks which cheek carries the
-- mass, `crestSplit` breaks the crown in two, `petals` is Pyrelotus alone.
--==============================================================================
type HeadSpec = {
	long: number, tall: number,
	browDrop: number, browTilt: number,
	jawJut: number, jawSquare: number,
	mouthW: number, mouthH: number, cornerLift: number,
	heavySide: number, chipYaw: number,
	crestSplit: number, petals: number, seed: number,
}

local HEADS: { [string]: HeadSpec } = {
	-- CINDERPAW: broad, low and crouched to match its braced body. Sloped
	-- forehead, one much stronger cheek, and the widest grin of the five.
	cinderpaw = { long = 0.94, tall = 0.92, browDrop = -0.02, browTilt = 7,
		jawJut = 0.16, jawSquare = 0.55, mouthW = 0.52, mouthH = 0.19,
		cornerLift = 1, heavySide = -1, chipYaw = 128, crestSplit = 0,
		petals = 0, seed = 311 },
	-- EMBERQUILL: longer and swept back, with the brow carried forward as a
	-- snout plane. Narrow mouth, one corner up. Long, not beaked -- the depth is
	-- in the cranium, not in a point.
	emberquill = { long = 1.26, tall = 0.86, browDrop = 0.04, browTilt = 14,
		jawJut = 0.22, jawSquare = 0.15, mouthW = 0.36, mouthH = 0.15,
		cornerLift = 1, heavySide = 1, chipYaw = 206, crestSplit = 0,
		petals = 0, seed = 337 },
	-- SLAGBLOOM: lumpy and fractured. The crown splits into two unequal masses
	-- and the mouth is the deepest and least regular -- partly melted, but the
	-- corners still lift, so it reads soft rather than ruined.
	slagbloom = { long = 1.02, tall = 1.00, browDrop = -0.05, browTilt = -6,
		jawJut = 0.10, jawSquare = 0.35, mouthW = 0.48, mouthH = 0.23,
		cornerLift = -1, heavySide = 1, chipYaw = 62, crestSplit = 11,
		petals = 0, seed = 359 },
	-- KILNHUSK: the architectural one. Broad kiln brow, squared jaw, deep
	-- furnace mouth -- and one side deliberately taller, which is what keeps it
	-- off being a cube.
	kilnhusk = { long = 1.00, tall = 1.06, browDrop = 0.06, browTilt = -12,
		jawJut = 0.08, jawSquare = 1.00, mouthW = 0.46, mouthH = 0.24,
		cornerLift = -1, heavySide = -1, chipYaw = 288, crestSplit = 0,
		petals = 0, seed = 373 },
	-- PYRELOTUS: the premium head. Volcanic petal planes layered AROUND a carved
	-- face, leaning one way and no two the same -- a bloom growing off a skull,
	-- never a flower set on top of one.
	pyrelotus = { long = 0.96, tall = 0.94, browDrop = 0.02, browTilt = 4,
		jawJut = 0.12, jawSquare = 0.25, mouthW = 0.40, mouthH = 0.18,
		cornerLift = 1, heavySide = 1, chipYaw = 154, crestSplit = 0,
		petals = 4, seed = 397 },
}

local function face(m: Model, head: CFrame, wide: number, throat: Color3,
	pal: Palette, species: string)
	-- Every carved piece goes through here, so the whole skull can be found
	-- again by attribute rather than by guessing at names.
	local function P2(o: Opts): BasePart
		o.parent = m
		local p = mk(o)
		p:SetAttribute("HeadPiece", true)
		return p
	end
	--==========================================================================
	-- THE SKULL IS CARVED, NOT A BALL WITH A FACE ON IT
	--
	-- What was here: one `Bulb`, a 0.96 Ball, with a brow laid across the top, a
	-- jaw slung under it and three neon bars floating off the front. Every plant
	-- in the biome had the same round outline from every angle, and the mouth was
	-- stuck ON the head rather than cut INTO it -- so the one feature that should
	-- carry the expression read as a decal.
	--
	-- The replacement is planes. A dominant cranial mass, a second crest mass
	-- turned against it so the outline breaks, an overhanging brow, two cheeks
	-- that are deliberately NOT the same size, and an upper and lower jaw that
	-- read as two separate silhouettes with a recessed cavity between them.
	--
	-- NO BALL AND NO CYLINDER in any of it. The eyes below stay spheres, which is
	-- what the art bible asks for -- "spheres sparingly, for eyes, glints and
	-- buds" -- but nothing that decides the SKULL's outline is round.
	--
	-- THE CAVITY IS SET BACK BEHIND THE JAW PLANES that frame it. That is the
	-- whole difference between a carved mouth and a painted one: the opening has
	-- depth, the surrounding material overhangs it, and at garden distance the
	-- shadow is what you read rather than the colour.
	--
	-- Still cute. Big readable mouth, heavy brow, chunky asymmetry -- these are
	-- collectible plants, not the guardian, and the tone is the one thing the
	-- previous face got right.
	--==========================================================================
	local h = HEADS[species] or HEADS.cinderpaw
	local W = wide
	local L = h.long
	local sd = h.seed
	-- The eyes below still measure their depth in D, as they did against the old
	-- Bulb. It is the head's LENGTH now, so a snouted species carries its eyes
	-- further forward instead of sinking them into a longer skull.
	local D = L

	-- 1. THE CRANIUM. Turned off every axis so no face of it is square to the
	-- camera, which is what stops a block reading as a block.
	P2({ name = "Skull", size = Vector3.new(0.90 * W, 0.74 * h.tall, 0.84 * L),
		cf = head * CFrame.new(0.02 * W, 0.02, 0.02 * L)
			* CFrame.Angles(rad(-5 + jit(sd, 1, 4)), rad(5), rad(-4)),
		color = pal.bulb })

	-- 2. THE CREST, turned AGAINST the cranium. Two unequal pieces where the
	-- species wants a split crown; one otherwise. This is the mass that breaks
	-- the round outline from the side and the three-quarter.
	if h.crestSplit > 0 then
		P2({ name = "SkullCrest", size = Vector3.new(0.44 * W, 0.40 * h.tall, 0.58 * L),
			cf = head * CFrame.new(-0.20 * W, 0.30 * h.tall, 0.10 * L)
				* CFrame.Angles(rad(12), rad(-18), rad(9 + h.crestSplit)),
			color = pal.stem })
		P2({ name = "SkullCrest", size = Vector3.new(0.34 * W, 0.30 * h.tall, 0.48 * L),
			cf = head * CFrame.new(0.22 * W, 0.26 * h.tall, 0.04 * L)
				* CFrame.Angles(rad(-8), rad(24), rad(-14 - h.crestSplit)),
			color = pal.bulb })
	else
		P2({ name = "SkullCrest", size = Vector3.new(0.70 * W, 0.40 * h.tall, 0.62 * L),
			cf = head * CFrame.new(0.05 * W, 0.30 * h.tall, 0.12 * L)
				* CFrame.Angles(rad(13 + jit(sd, 2, 5)), rad(-12), rad(7)),
			color = pal.stem })
	end

	-- 3. THE BROW, overhanging. A wedge, so its underside cuts back over the eyes
	-- and the sockets fall into shadow rather than sitting on a flat forehead.
	P2({ name = "BrowPlate", size = Vector3.new(0.86 * W, 0.24, 0.46),
		cf = head * CFrame.new(0, 0.22 + h.browDrop, -0.30 * L)
			* CFrame.Angles(rad(-26 - h.browTilt), rad(jit(sd, 3, 6)), rad(-5)),
		color = pal.brow, wedge = true })

	-- 4. TWO CHEEKS THAT ARE NOT THE SAME. One carries more mass, sits lower and
	-- turns further out; the light one is smaller and set back. A face with
	-- matching cheeks is a face with a mirror line down it.
	local hs = h.heavySide
	P2({ name = "CheekHeavy", size = Vector3.new(0.30 * W, 0.42 * h.tall, 0.46 * L),
		cf = head * CFrame.new(hs * 0.34 * W, -0.08, -0.16 * L)
			* CFrame.Angles(rad(6), rad(hs * -16), rad(hs * 11)),
		color = pal.bulb })
	P2({ name = "CheekLight", size = Vector3.new(0.23 * W, 0.32 * h.tall, 0.38 * L),
		cf = head * CFrame.new(-hs * 0.32 * W, 0.01, -0.13 * L)
			* CFrame.Angles(rad(-4), rad(hs * 13), rad(hs * 7)),
		color = pal.stem })

	-- 5. THE UPPER JAW PLANE, which is the top lip of the carving.
	P2({ name = "UpperJaw", size = Vector3.new(0.66 * W, 0.20, 0.40 * L),
		cf = head * CFrame.new(0, -0.19, -0.33 * L) * CFrame.Angles(rad(-9), 0, rad(2)),
		color = pal.brow })

	-- 6. THE LOWER JAW, a silhouette of its own. It juts, it is squarer or more
	-- tapered by species, and it is the piece that says whether the head is
	-- furnace-heavy or swept.
	P2({ name = "LowerJaw",
		size = Vector3.new((0.54 + 0.10 * h.jawSquare) * W, 0.30,
			(0.44 + h.jawJut) * L),
		cf = head * CFrame.new(0, -0.55, (-0.30 - h.jawJut * 0.34) * L)
			* CFrame.Angles(rad(-14 + jit(sd, 4, 5)), 0, rad(-3 + h.cornerLift * 4)),
		color = pal.bulb })

	--==========================================================================
	-- 7. THE CAVITY, AND WHY ITS Z IS COMPUTED
	--
	-- "Recessed" is a measurement, not a look. The cavity's front face has to sit
	-- BEHIND the front faces of the jaw planes around it, or the dark block is
	-- simply a dark block glued to the front of the head -- which is what the
	-- three neon bars were.
	--
	-- The upper jaw's front reaches (0.33 * L + 0.20) forward. The cavity is
	-- placed so its own front lands a clear 0.06 behind that, and the surrounding
	-- material overhangs it on every side.
	--==========================================================================
	local mouthW = h.mouthW * 0.96 * W
	local mouthH = h.mouthH
	local cavityDepth = 0.26
	local jawFront = 0.33 * L + 0.20
	local cavityFront = jawFront - 0.06
	P2({ name = "MouthCavity", size = Vector3.new(mouthW, mouthH, cavityDepth),
		cf = head * CFrame.new(0, -0.35, -(cavityFront - cavityDepth * 0.5))
			* CFrame.Angles(0, 0, rad(h.cornerLift * 5)),
		color = C.Char, smooth = true })
	-- The heat INSIDE the opening. Thin, set deeper still, and the only neon on
	-- the head -- a lit throat seen through a carved gap, not a glowing mouth
	-- stuck on the outside.
	P2({ name = "ThroatGlow", size = Vector3.new(mouthW * 0.74, mouthH * 0.34, 0.08),
		cf = head * CFrame.new(0, -0.35 + mouthH * 0.06,
				-(cavityFront - cavityDepth * 0.86))
			* CFrame.Angles(0, 0, rad(h.cornerLift * 5)),
		color = throat, material = Enum.Material.Neon, smooth = true })

	-- 8. A BROKEN CORNER. One chip, placed by species, so the skull looks cooled
	-- and fractured rather than moulded.
	P2({ name = "SkullChip", size = Vector3.new(0.26 * W, 0.22, 0.30 * L),
		cf = head * CFrame.new(math.sin(rad(h.chipYaw)) * 0.36 * W, 0.14,
				math.cos(rad(h.chipYaw)) * 0.34 * L)
			* CFrame.Angles(rad(18), rad(h.chipYaw), rad(-22)),
		color = pal.stemPale, wedge = true })

	-- 9. LAYERED PETAL PLANES, Pyrelotus only. Directional and uneven -- they
	-- lean one way and no two are the same size, so they read as a burnt bloom
	-- growing off a skull rather than a flower laid on top of one.
	for i = 1, h.petals do
		local a = rad(-40 + i * 46 + jit(sd, i + 20, 12))
		local k = 1 - (i - 1) * 0.16
		P2({ name = "HeadPetal",
			size = Vector3.new(0.30 * W * k, 0.09, 0.44 * L * k),
			cf = head * CFrame.new(math.sin(a) * 0.40 * W, 0.16 + i * 0.05,
					math.cos(a) * 0.30 * L)
				* CFrame.Angles(rad(24 + i * 7), a, rad(jit(sd, i + 30, 18))),
			color = if i % 2 == 0 then pal.stemPale else pal.brow, wedge = true })
	end

	for i = 0, 1 do
		local side = (i == 0) and -1 or 1
		local tag = (i == 0) and "Left" or "Right"
		-- Centred on the surface at this offset, so half stands proud.
		local eye = head * CFrame.new(side * 0.24 * wide, 0.02, -0.42 * D)
		mk({ name = tag .. "Eye", size = Vector3.new(0.21, 0.21, 0.21),
			cf = eye, color = C.Char, shape = Enum.PartType.Ball,
			smooth = true, parent = m })
		--==================================================================
		-- THE EMBER DOT IS A PUPIL NOW, NOT A GLINT
		--
		-- It used to be a fixed highlight sitting upper-left on both eyes --
		-- the "one shared light" trick, which exists so two spheres read as
		-- one face lit from one side. That rule is for a HIGHLIGHT, and a
		-- highlight is the one thing on a face that can never look alive: it
		-- is pinned to the light, so no matter how the geometry is tuned the
		-- eye keeps staring through you.
		--
		-- So it becomes the pupil instead. Built dead centre, looking straight
		-- ahead, and moved at runtime -- which is what makes an eye read as an
		-- eye without anyone having to keep adjusting its shape.
		--
		-- Hung off the EYE rather than the head, so it travels with the eye's
		-- depth and the runtime only ever has to think in angles.
		--
		-- PLACED ON THE EYEBALL'S SURFACE, not on a flat plane in front of it:
		-- a pupil that slides across a plane detaches from the ball at the
		-- edges. 0.0928 is the eye's radius less a quarter of the pupil's, so
		-- it sits just into the skin and stays there through the full sweep.
		--==================================================================
		mk({ name = tag .. "Pupil", size = Vector3.new(0.098, 0.098, 0.098),
			cf = eye * CFrame.new(0, 0, -0.0928),
			color = C.EyeGlow, material = Enum.Material.Neon,
			shape = Enum.PartType.Ball, smooth = true, parent = m })
	end
end

--==============================================================================
-- SPECIES
--==============================================================================
local function cinderpaw(parent: Instance, at: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Cinderpaw"; m.Parent = parent
	local pal = PALETTES.cinderpaw
	local b = body(m, at, 1.0, 0, pal, ROOTS.cinderpaw, 11)
	face(m, b.head, 1.0, C.Throat, pal, "cinderpaw")
	mk({ name = "CrownHub", size = Vector3.new(0.60, 0.34, 0.58),
		cf = b.hub * CFrame.Angles(rad(-6), 0, 0), color = C.Cinder, parent = m })
	local fronds = {
		{ -28, 1.94, 9, 1.18, C.Ember }, { 34, 1.76, 13, 1.06, C.EmberPale },
		{ -96, 1.52, 6, 0.94, C.EmberDeep }, { 104, 1.64, 4, 1.00, C.Ember },
		{ 178, 1.28, 17, 0.84, C.EmberDeep },
	}
	for i, f in ipairs(fronds) do
		local base = b.hub * CFrame.Angles(0, rad(f[1] :: number), 0)
			* CFrame.Angles(rad(-(f[3] :: number)), 0, 0)
		local L = f[2] :: number
		--======================================================================
		-- RIB AND BLADE, BOTH NAMED "Leaf"
		--
		-- PlantSway swings every direct child named exactly "Leaf" as an arm
		-- while a plant walks. "FrondRib1" and "FrondBlade1" match nothing, so
		-- these fronds have never moved -- the same trap Suncrown fell into with
		-- SupportLeaf1-4. Both halves take the name: they share an axis and sit
		-- within a twentieth of a stud of each other, so they swing as one frond
		-- rather than peeling apart.
		--======================================================================
		mk({ name = "Leaf", size = Vector3.new(0.11, 0.10, L),
			cf = base * CFrame.new(0, 0, -L * 0.5), color = C.Cinder, parent = m })
		mk({ name = "Leaf", size = Vector3.new(f[4] :: number, 0.13, L * 0.86),
			cf = base * CFrame.new(0, 0.045, -L * 0.52)
				* CFrame.Angles(0, 0, rad((i % 2 == 0) and 7 or -6)),
			color = f[5] :: Color3, parent = m })
	end
	return m
end

--==============================================================================
-- EMBERQUILL -- the other Rare, and it must not be mistaken for Cinderpaw.
-- Cinderpaw fans OUT and sits low; this points UP and stands tall, on a longer
-- stem, with narrow quills instead of broad blades. Signature: one central
-- quill taller than the rest, lit at the tip like a wick.
--==============================================================================
local function emberquill(parent: Instance, at: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Emberquill"; m.Parent = parent
	local pal = PALETTES.emberquill
	local b = body(m, at, 1.22, -6, pal, ROOTS.emberquill, 61)
	face(m, b.head, 0.88, C.Throat, pal, "emberquill")
	mk({ name = "CrownHub", size = Vector3.new(0.46, 0.30, 0.46),
		cf = b.hub, color = C.Cinder, parent = m })
	-- Six quills, uneven lean, none vertical: a fence of equal spikes is the
	-- failure the skill names, so lean and length vary across the set.
	local quills = {
		{ -22, 1.62, 52, C.Quill }, { 46, 1.38, 43, C.Ember },
		{ -88, 1.20, 34, C.EmberDeep }, { 118, 1.46, 47, C.EmberPale },
		{ 168, 1.08, 38, C.EmberDeep },
	}
	for i, q in ipairs(quills) do
		local L = q[2] :: number
		local base = b.hub * CFrame.Angles(0, rad(q[1] :: number), 0)
			* CFrame.Angles(rad(-(q[3] :: number)), 0, 0)
		mk({ name = "Quill" .. i, size = Vector3.new(0.19, 0.15, L),
			cf = base * CFrame.new(0, 0, -L * 0.5), color = q[4] :: Color3, parent = m })
	end
	-- THE SIGNATURE: the wick.
	mk({ name = "WickQuill", size = Vector3.new(0.22, 0.20, 1.84),
		cf = b.hub * CFrame.Angles(rad(-84), rad(8), 0) * CFrame.new(0, 0, -0.92),
		color = C.Quill, parent = m })
	mk({ name = "WickTip", size = Vector3.new(0.30, 0.30, 0.30),
		cf = b.hub * CFrame.new(0.12, 1.86, 0.02), color = C.LotusCore,
		material = Enum.Material.Neon, shape = Enum.PartType.Ball,
		smooth = true, parent = m })
	-- A dry husk collar under the crown and two seed beads down the stem: this
	-- is the species that reads as SPENT, so it carries what it has shed.
	for i = 0, 2 do
		local a = -50 + i * 62
		mk({ name = "HuskFlake" .. (i + 1), size = Vector3.new(0.44, 0.11, 0.34),
			cf = b.hub * CFrame.Angles(0, rad(a), 0) * CFrame.new(0, -0.30, -0.34)
				* CFrame.Angles(rad(28), 0, rad((i % 2 == 0) and 8 or -9)),
			color = pal.stemPale, wedge = true, parent = m })
	end
	mk({ name = "SeedBead", size = Vector3.new(0.22, 0.26, 0.22),
		cf = at * CFrame.new(0.30, 1.52, -0.40) * CFrame.Angles(rad(12), 0, rad(-14)),
		color = C.Quill, parent = m })
	return m
end

--==============================================================================
-- SLAGBLOOM -- Epic. Squat and heavy where the Rares are light. The crown
-- DROOPS instead of lifting, four thick petals folding down over the head, and
-- the signature is a molten drip hanging off the lowest one.
--==============================================================================
local function slagbloom(parent: Instance, at: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Slagbloom"; m.Parent = parent
	local pal = PALETTES.slagbloom
	local b = body(m, at, 0.90, 10, pal, ROOTS.slagbloom, 103)
	face(m, b.head, 1.18, C.SlagDrip, pal, "slagbloom")
	mk({ name = "CrownHub", size = Vector3.new(0.78, 0.40, 0.74),
		cf = b.hub * CFrame.Angles(rad(4), 0, 0), color = C.Cinder, parent = m })
	local petals = {
		{ -40, 1.30, -34, 1.26, C.Slag }, { 38, 1.16, -28, 1.14, C.SlagDrip },
		{ -124, 1.04, -22, 1.02, C.Slag }, { 132, 1.10, -30, 1.08, C.EmberDeep },
	}
	for i, p in ipairs(petals) do
		local L = p[2] :: number
		local base = b.hub * CFrame.Angles(0, rad(p[1] :: number), 0)
			* CFrame.Angles(rad(-(p[3] :: number)), 0, 0)
		mk({ name = "PetalRib" .. i, size = Vector3.new(0.14, 0.12, L),
			cf = base * CFrame.new(0, 0, -L * 0.5), color = C.Cinder, parent = m })
		mk({ name = "Petal" .. i, size = Vector3.new(p[4] :: number, 0.20, L * 0.88),
			cf = base * CFrame.new(0, 0.06, -L * 0.5)
				* CFrame.Angles(rad(-14), 0, rad((i % 2 == 0) and 9 or -8)),
			color = p[5] :: Color3, parent = m })
	end
	-- THE SIGNATURE: molten running off one petal and hanging.
	mk({ name = "DripRun", size = Vector3.new(0.13, 0.52, 0.13),
		cf = b.hub * CFrame.new(-0.92, -0.42, -0.66) * CFrame.Angles(rad(6), 0, rad(10)),
		color = C.SlagDrip, material = Enum.Material.Neon, smooth = true, parent = m })
	mk({ name = "DripBead", size = Vector3.new(0.26, 0.26, 0.26),
		cf = b.hub * CFrame.new(-0.96, -0.76, -0.68), color = C.LotusCore,
		material = Enum.Material.Neon, shape = Enum.PartType.Ball,
		smooth = true, parent = m })
	-- Slag crust over the shoulders: this one is the heavy species, and weight
	-- reads as crust rather than as height.
	for i = 0, 1 do
		local side = (i == 0) and -1 or 1
		mk({ name = "SlagCrust" .. (i + 1), size = Vector3.new(0.62, 0.26, 0.54),
			cf = at * CFrame.new(side * 0.44, 2.06, -0.10)
				* CFrame.Angles(rad(-12), side * rad(18), side * rad(-22)),
			color = C.Slag, parent = m })
	end
	return m
end

--==============================================================================
-- KILNHUSK -- Legendary, and the only one built like a BUILDING.
--
-- Every other species in the biome is foliage on a stem. This is a squat stone
-- barrel with an arched mouth and a chimney: no crown, no petals, no fronds. It
-- is the widest and heaviest silhouette on the road, and it is recognisable at
-- distance because nothing else in Emberroot has a straight vertical edge.
--
-- The face sits INSIDE the arch, lit by the furnace behind it, so the head is
-- framed rather than crowned.
--==============================================================================
local function kilnhusk(parent: Instance, at: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Kilnhusk"; m.Parent = parent
	local pal = PALETTES.kilnhusk
	local b = body(m, at, 0.86, -18, pal, ROOTS.kilnhusk, 149)
	face(m, b.head, 1.0, C.KilnGlow, pal, "kilnhusk")

	--== THE BARREL: three stacked courses, standing BEHIND the head ==--
	-- The first build put these boxes straight through the face. Each course was
	-- centred near z = 0 and cut nearly three studs deep, so it reached further
	-- forward than the brow, the jaw and the arch posts alike, across exactly the
	-- height band the face occupies. The species advertises "the face sits inside
	-- the arch" and what stood on the road was a stack of blocks with the face
	-- walled in behind it.
	--
	-- The mass now starts at z = +0.18 and grows backwards, which leaves the head
	-- standing clear in the arch opening with the furnace glowing between them.
	-- The Y turns are also cut from 13/-9 to 8/-6: a wide box swings its corners
	-- forward as it rotates, and at the old angles that alone reached past the
	-- face even after the box was moved back.
	--
	-- Turning each course still stops the stack reading as one extruded box, and
	-- the narrowing is what makes it a kiln rather than a crate.
	local BARREL_Z = 1.10
	local rings = {
		{ 2.16, 3.34, 0.78, 0 }, { 2.86, 3.02, 0.70, 8 }, { 3.44, 2.54, 0.58, -6 },
	}
	for i, r in ipairs(rings) do
		mk({ name = "KilnCourse" .. i,
			size = Vector3.new(r[2] :: number, r[3] :: number, (r[2] :: number) * 0.55),
			cf = at * CFrame.new(0, r[1] :: number, BARREL_Z)
				* CFrame.Angles(0, rad(r[4] :: number), rad((i == 2) and 3 or -2)),
			color = if i == 2 then C.Basalt else C.Kiln, parent = m })
	end

	--== THE ARCH: two jambs and a lintel, framing the face ==--
	-- These were 0.40 deep and sat a stud proud of everything, so they read as
	-- two loose slats rather than as the mouth of a kiln. They are now driven
	-- back far enough to meet the barrel's front face, which turns the arch into
	-- a real opening with depth to it -- the face sits IN the recess rather than
	-- in front of a wall.
	for i = 0, 1 do
		local side = (i == 0) and -1 or 1
		mk({ name = (i == 0 and "ArchLeft" or "ArchRight"),
			size = Vector3.new(0.34, 1.24, 1.60),
			cf = at * CFrame.new(side * 0.86, 2.46, -0.55)
				* CFrame.Angles(rad(4), side * rad(-6), 0),
			color = C.Kiln, parent = m })
	end
	mk({ name = "ArchLintel", size = Vector3.new(2.10, 0.40, 1.50),
		cf = at * CFrame.new(0, 3.18, -0.55) * CFrame.Angles(rad(-8), 0, rad(2)),
		color = C.Basalt, parent = m })

	--== THE CHIMNEY, OFF CENTRE ==--
	-- Off centre and leaning, because a chimney on the axis would make the whole
	-- thing symmetrical and dead.
	mk({ name = "Chimney", size = Vector3.new(0.56, 1.44, 0.54),
		cf = at * CFrame.new(0.46, 4.24, 1.02) * CFrame.Angles(rad(6), rad(14), rad(-9)),
		color = C.Kiln, parent = m })
	mk({ name = "ChimneyCap", size = Vector3.new(0.76, 0.24, 0.72),
		cf = at * CFrame.new(0.50, 4.98, 1.06) * CFrame.Angles(rad(4), rad(14), rad(-7)),
		color = C.Basalt, parent = m })
	mk({ name = "ChimneyMouth", size = Vector3.new(0.30, 0.16, 0.28),
		cf = at * CFrame.new(0.50, 5.08, 1.06), color = C.KilnGlow,
		material = Enum.Material.Neon, smooth = true, parent = m })

	--== THE SIGNATURE: the furnace, seen through the arch ==--
	local furnace = mk({ name = "Furnace", size = Vector3.new(0.42, 0.42, 0.42),
		cf = at * CFrame.new(0, 2.62, -0.10), color = C.KilnGlow,
		material = Enum.Material.Neon, shape = Enum.PartType.Ball,
		smooth = true, parent = m })
	mk({ name = "KilnSplit", size = Vector3.new(0.15, 1.30, 0.13),
		cf = at * CFrame.new(-0.74, 2.90, -0.62) * CFrame.Angles(rad(-6), 0, rad(11)),
		color = C.KilnGlow, material = Enum.Material.Neon, smooth = true, parent = m })
	local light = Instance.new("PointLight")
	light.Name = "FurnaceGlow"
	light.Color = C.Ember
	light.Brightness = 1.8
	light.Range = 11
	light.Shadows = false
	light.Parent = furnace
	return m
end

--==============================================================================
-- PYRELOTUS -- Mythic, and the only one with a HOLE in its silhouette.
--
-- Three ribs rise off the crown and arc inward until they almost touch, leaving
-- a hollow with the burning core suspended in it. Nothing else in Emberroot is
-- hollow: Cinderpaw fans, Slagbloom droops, Emberquill spikes, Kilnhusk stacks.
-- A cage cannot be mistaken for any of them, at any distance or angle.
--
-- The brightest thing on the model is seen THROUGH the form rather than on it,
-- which is what makes it worth walking up to -- and the face sits low at the
-- cage mouth, so the plant reads as carrying the ember rather than wearing it.
--
-- The rarity is the budget: nothing below Mythic gets a light, a halo and an
-- emitter, and nothing else gets an enclosing form at all.
--==============================================================================
local function pyrelotus(parent: Instance, at: CFrame): Model
	local m = Instance.new("Model"); m.Name = "Pyrelotus"; m.Parent = parent
	local pal = PALETTES.pyrelotus
	local b = body(m, at, 0.94, 8, pal, ROOTS.pyrelotus, 191)
	face(m, b.head, 0.92, C.LotusCore, pal, "pyrelotus")

	--== THE CAGE MOUTH ==--
	-- A flared collar the ribs spring from, so they look grown rather than
	-- planted in the top of the stem.
	mk({ name = "CageMouth", size = Vector3.new(1.34, 0.30, 1.28),
		cf = at * CFrame.new(0.02, 3.06, 0.04) * CFrame.Angles(rad(-5), rad(11), 0),
		color = C.Cinder, parent = m })

	--==========================================================================
	-- THREE RIBS, WALKED RATHER THAN PLACED
	--
	-- The first attempt positioned each segment by its own height and radius,
	-- which guaranteed nothing about whether one met the next -- and they did
	-- not. It read as a sunburst of loose blocks.
	--
	-- Each rib is now walked with a CURSOR. A segment is laid along the cursor's
	-- own forward axis, then the cursor advances the whole segment length and
	-- turns inward. Built that way an arc cannot come apart, because every
	-- segment starts exactly where the last one finished.
	--
	-- Three ribs, not four or six: the anti-overgeometry rule warns against
	-- rings of identical parts, and three is the fewest that still encloses. The
	-- bearings are uneven and each rib closes by a different amount, so the cage
	-- is lopsided the way a grown thing is.
	--==========================================================================
	local ribs = {
		{ bearing = -34, close = 1.00, tint = C.LotusDeep },
		{ bearing = 78, close = 0.88, tint = C.Lotus },
		{ bearing = 196, close = 0.94, tint = C.LotusDeep },
	}
	-- length, how far to turn inward AFTER it, thickness
	local segments = {
		{ 1.05, 30, 0.30 },
		{ 0.95, 34, 0.26 },
		{ 0.80, 38, 0.22 },
	}
	for i, rib in ipairs(ribs) do
		-- Start at the collar rim, already leaning out a little so the cage
		-- flares before it closes.
		local cursor = at * CFrame.new(0.02, 3.16, 0.04)
			* CFrame.Angles(0, rad(rib.bearing), 0)
			* CFrame.new(0, 0, -0.62 * rib.close)
			* CFrame.Angles(rad(-16), 0, 0)
		for k, sg in ipairs(segments) do
			local len = (sg[1] :: number) * rib.close
			local turn = sg[2] :: number
			local thick = sg[3] :: number
			-- Laid along the cursor's LOCAL Y, centred half a length along it.
			mk({ name = string.format("Rib%d_%d", i, k),
				size = Vector3.new(thick, len, thick * 1.35),
				cf = cursor * CFrame.new(0, len * 0.5, 0),
				color = rib.tint, parent = m })
			-- Advance the full length, then turn inward for the next segment.
			cursor = cursor * CFrame.new(0, len, 0) * CFrame.Angles(rad(turn), 0, 0)
		end
	end

	--== THE CROWN KNOT ==--
	-- Where the three ribs nearly meet. Offset from the axis so the cage does
	-- not close symmetrically, which would read as machined.
	mk({ name = "CageKnot", size = Vector3.new(0.38, 0.30, 0.36),
		cf = at * CFrame.new(0.12, 5.18, -0.06) * CFrame.Angles(rad(12), rad(24), rad(-8)),
		color = C.Cinder, parent = m })

	--==========================================================================
	-- THE SIGNATURE: THE CORE, HUNG IN THE HOLLOW
	--==========================================================================
	local core = mk({ name = "Core", size = Vector3.new(0.54, 0.54, 0.54),
		cf = at * CFrame.new(0.04, 4.10, -0.02), color = C.CoreEmber,
		material = Enum.Material.Neon, shape = Enum.PartType.Ball,
		smooth = true, parent = m })
	mk({ name = "Halo", size = Vector3.new(1.42, 0.08, 1.42),
		cf = at * CFrame.new(0.04, 4.10, -0.02) * CFrame.Angles(rad(9), 0, rad(90)),
		color = C.Lotus, material = Enum.Material.Neon,
		shape = Enum.PartType.Cylinder, smooth = true, parent = m })
	--==========================================================================
	-- WHAT THE MYTHIC SPENDS ITS EXTRA PARTS ON
	--
	-- This species runs over the 25-40 band on purpose. Every addition below is
	-- held to the same test the rest of the model is -- change the silhouette,
	-- explain anatomy, make a colour region, carry an animation seam, or be a
	-- close-range focal detail -- and anything that failed it was cut.
	--
	-- The cost is real: a bed of twelve at this count is over 570 parts, where
	-- twelve Cinderpaws is 456. It is affordable because a Mythic is a 0.2%
	-- roll, so a plot will almost never hold two.
	--==========================================================================

	--== COLLAR PETALS: a colour region where there was a bare plate ==--
	local collar = { { -18, 0.62 }, { 104, 0.54 }, { 226, 0.58 } }
	for i, cp in ipairs(collar) do
		mk({ name = "Collar" .. i,
			size = Vector3.new(cp[2] :: number, 0.12, 0.54),
			cf = at * CFrame.new(0.02, 3.02, 0.04)
				* CFrame.Angles(0, rad(cp[1] :: number), 0)
				* CFrame.new(0, 0.02, -0.62)
				* CFrame.Angles(rad(-22), 0, rad((i % 2 == 0) and 8 or -7)),
			color = C.Lotus, parent = m })
	end

	--== ORBIT MOTES: three beads hung inside the cage ==--
	-- Different radii, heights and bearings, so they read as caught in the
	-- updraught rather than as a bracelet. Each is its own animation seam.
	local motes = { { 34, 0.52, 3.72 }, { 158, 0.66, 4.34 }, { 268, 0.44, 4.02 } }
	for i, mo in ipairs(motes) do
		mk({ name = "Mote" .. i, size = Vector3.new(0.16, 0.16, 0.16),
			cf = at * CFrame.Angles(0, rad(mo[1] :: number), 0)
				* CFrame.new(0, mo[3] :: number, -(mo[2] :: number)),
			color = C.EmberPale, material = Enum.Material.Neon,
			shape = Enum.PartType.Ball, smooth = true, parent = m })
	end

	--== HUNG SEEDS: two, uneven, breaking the arc outline ==--
	mk({ name = "HungSeed1", size = Vector3.new(0.19, 0.26, 0.19),
		cf = at * CFrame.new(-0.74, 4.02, -0.34) * CFrame.Angles(rad(9), 0, rad(-12)),
		color = C.LotusDeep, parent = m })
	mk({ name = "HungSeed2", size = Vector3.new(0.15, 0.21, 0.15),
		cf = at * CFrame.new(0.58, 4.62, 0.42) * CFrame.Angles(rad(-7), 0, rad(10)),
		color = C.LotusDeep, parent = m })

	--==========================================================================
	-- THE AURA -- WHAT MAKES IT READ AS MYTHIC BEFORE YOU READ THE WORD
	--
	-- Everything here is Attachments and ParticleEmitters, so it costs the part
	-- budget NOTHING. That matters: the model is already over the band on
	-- geometry, and this is the one way left to add presence without adding to
	-- that number.
	--
	-- Three emitters, because one at a high rate just looks like smoke. They work
	-- at different speeds and different heights, and the eye reads the layering
	-- as "this thing is radiating" rather than "this thing is on fire":
	--
	--   Motes   a slow churn filling the cage hollow. NOT a column: the first
	--           tuning gave these 4 studs/s and 3.2 of upward acceleration and
	--           they shot eight studs clear of the plant, which read as a smoke
	--           plume -- a thing on fire, colliding with Kilnhusk's furnace and
	--           Emberquill's torch. Dragged and barely accelerated, they stay in
	--           the hollow and the cage looks FULL instead of venting.
	--   Aura    a slow, wide, near-still haze hanging AROUND and ABOVE the crown.
	--           Long lifetime and heavy drag, so it hangs rather than rises. This
	--           is the halo you see from across the plot.
	--   Sparks  small, bright, quick pinpricks in every direction. Punctuation on
	--           top of the haze, so the aura glitters instead of sitting flat.
	--   Crown   a hovering cloud of DISTINCT dots above the cage. The other three
	--           blur into one glow at any distance, which is the right read for
	--           a halo but means you never actually count particles. These are
	--           kept small and slow on purpose: small enough that they never
	--           merge, slow enough that they hang there and can be counted.
	--
	-- All three run LightInfluence = 0 and LightEmission = 1, which is what keeps
	-- them bright at night and under the biome's dark ambient -- the whole point
	-- of a rarity tell is that it survives bad lighting.
	--
	-- COST: about 220 live particles per plant. That is affordable only because a
	-- Mythic is a 0.2% roll and a plot will almost never hold two. If it ever
	-- does need trimming, Aura.Rate is the dial -- it owns roughly half the total
	-- and it is the cheapest to thin without losing the read.
	--==========================================================================
	local light = Instance.new("PointLight")
	light.Name = "CoreGlow"
	light.Color = C.Ember
	-- Wider than it is bright: this should wash the ground around the plant
	-- rather than blow out the core, which is what the old 2.2 was doing.
	light.Brightness = 1.45
	light.Range = 16
	light.Shadows = false
	light.Parent = core

	--== MOTES: the rising column ==--
	local att = Instance.new("Attachment")
	att.Name = "CoreAttachment"
	att.Parent = core
	local em = Instance.new("ParticleEmitter")
	em.Name = "Motes"
	em.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.LotusCore),
		ColorSequenceKeypoint.new(0.45, C.EmberPale),
		ColorSequenceKeypoint.new(1, C.Ember),
	})
	-- Grows just after birth, so the column has a waist rather than being a
	-- uniform stream of identical dots.
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.10),
		NumberSequenceKeypoint.new(0.3, 0.40),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(0.7, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(1.0, 1.7)
	em.Rate = 38
	-- Slow and heavily dragged, so they hang in the cage instead of venting.
	em.Speed = NumberRange.new(0.4, 1.1)
	em.Drag = 2.4
	em.SpreadAngle = Vector2.new(55, 55)
	em.Acceleration = Vector3.new(0, 0.7, 0)
	em.EmissionDirection = Enum.NormalId.Top
	em.Rotation = NumberRange.new(0, 360)
	em.RotSpeed = NumberRange.new(-40, 40)
	em.LightEmission = 1
	em.LightInfluence = 0
	em.Parent = att

	--== AURA: the slow haze that hangs above the crown ==--
	-- The core is an unrotated ball, so an offset on ITS attachment is a clean
	-- world-space offset -- putting this above the cage knot without inheriting
	-- the knot's tilt.
	local auraAtt = Instance.new("Attachment")
	auraAtt.Name = "AuraAttachment"
	auraAtt.Position = Vector3.new(0, 0.95, 0)
	auraAtt.Parent = core
	local aura = Instance.new("ParticleEmitter")
	aura.Name = "Aura"
	aura.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.EmberPale),
		ColorSequenceKeypoint.new(0.5, C.Ember),
		ColorSequenceKeypoint.new(1, C.LotusDeep),
	})
	aura.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.25, 1.05),
		NumberSequenceKeypoint.new(1, 0.20),
	})
	-- Fades in AND out, so nothing ever pops into or out of existence.
	aura.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.30),
		NumberSequenceKeypoint.new(0.8, 0.44),
		NumberSequenceKeypoint.new(1, 1),
	})
	aura.Lifetime = NumberRange.new(2.0, 3.2)
	aura.Rate = 34
	-- Dragged to a near stop with NO upward pull at all. Any acceleration here
	-- and the haze drifts off the plant and becomes a second, weaker plume; at
	-- zero it sits on the crown like a worn halo, which is the whole point.
	aura.Speed = NumberRange.new(0.15, 0.55)
	aura.Drag = 3.4
	aura.Acceleration = Vector3.new(0, 0, 0)
	aura.SpreadAngle = Vector2.new(180, 180)
	aura.Rotation = NumberRange.new(0, 360)
	aura.RotSpeed = NumberRange.new(-22, 22)
	aura.LightEmission = 1
	aura.LightInfluence = 0
	-- Pushed behind the geometry so the cage ribs stay crisp through the haze.
	aura.ZOffset = -0.6
	aura.Parent = auraAtt

	--== SPARKS: the glitter on top ==--
	local sparkAtt = Instance.new("Attachment")
	sparkAtt.Name = "SparkAttachment"
	sparkAtt.Position = Vector3.new(0, 0.85, 0)
	sparkAtt.Parent = core
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Color = ColorSequence.new(C.Glint, C.EmberPale)
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.14),
		NumberSequenceKeypoint.new(1, 0),
	})
	sparks.Transparency = NumberSequence.new(0.1, 1)
	sparks.Lifetime = NumberRange.new(0.7, 1.3)
	sparks.Rate = 16
	-- Fast off the mark but dragged hard, so each spark darts a short way and
	-- stops -- a shell of glitter around the crown rather than a fountain.
	sparks.Speed = NumberRange.new(1.4, 2.8)
	sparks.Drag = 3.6
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Acceleration = Vector3.new(0, 0.25, 0)
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Parent = sparkAtt

	--== CROWN: the cloud of separate motes hanging over the plant ==--
	-- Sits just clear of the tallest geometry (the model is 5.77 tall and the
	-- core is at 4.10, so +1.9 puts this at about 6.0) -- above the plant, which
	-- is the point, but close enough that it still reads as belonging to it.
	local crownAtt = Instance.new("Attachment")
	crownAtt.Name = "CrownAttachment"
	crownAtt.Position = Vector3.new(0, 1.90, 0)
	crownAtt.Parent = core
	local crown = Instance.new("ParticleEmitter")
	crown.Name = "Crown"
	crown.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, C.LotusCore),
		ColorSequenceKeypoint.new(0.6, C.EmberPale),
		ColorSequenceKeypoint.new(1, C.Ember),
	})
	-- Deliberately SMALL and near-constant. A mote that swells is a mote that
	-- merges with its neighbours, and then this is just more haze.
	crown.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.04),
		NumberSequenceKeypoint.new(0.15, 0.19),
		NumberSequenceKeypoint.new(0.85, 0.17),
		NumberSequenceKeypoint.new(1, 0),
	})
	crown.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.08),
		NumberSequenceKeypoint.new(0.85, 0.12),
		NumberSequenceKeypoint.new(1, 1),
	})
	crown.Lifetime = NumberRange.new(2.2, 3.6)
	crown.Rate = 24
	crown.Speed = NumberRange.new(0.35, 1.10)
	-- Enough drag to stop them dispersing, a whisper of lift so the cloud
	-- breathes upward instead of sitting dead still.
	crown.Drag = 2.2
	crown.Acceleration = Vector3.new(0, 0.30, 0)
	crown.SpreadAngle = Vector2.new(180, 180)
	crown.Rotation = NumberRange.new(0, 360)
	crown.RotSpeed = NumberRange.new(-30, 30)
	crown.LightEmission = 1
	crown.LightInfluence = 0
	crown.Parent = crownAtt
	return m
end

--==============================================================================
-- WHAT EACH APPROVED PLANT ACTUALLY MEASURES
--
-- The true silhouette height over the ROTATED corners of every part, taken off
-- the approved mockup. Not a design dial: change one of these and the plant
-- comes out the wrong size relative to its four siblings, which is the one
-- thing the approval fixed.
--==============================================================================
EmberrootForms.AuthoredHeight = {
	cinderpaw = 3.474,
	slagbloom = 3.736,
	kilnhusk = 5.196,
	pyrelotus = 5.775,
	emberquill = 5.994,
} :: { [string]: number }

local BUILDERS: { [string]: (Instance, CFrame) -> Model } = {
	cinderpaw = cinderpaw,
	emberquill = emberquill,
	slagbloom = slagbloom,
	kilnhusk = kilnhusk,
	pyrelotus = pyrelotus,
}

--==============================================================================
-- A NumberSequence DOES NOT SCALE ITSELF
--
-- Pyrelotus is the only plant in the game that carries particles, and a
-- Colossal is fifty times a Tiny. Left alone, its aura would be a pinprick of
-- glitter beside a fifteen-stud flower -- the effect would simply stop reading
-- at exactly the tier it is supposed to celebrate.
--==============================================================================
local function scaleSequence(seq: NumberSequence, s: number): NumberSequence
	local pts = {}
	for _, k in ipairs(seq.Keypoints) do
		table.insert(pts, NumberSequenceKeypoint.new(k.Time, k.Value * s, k.Envelope * s))
	end
	return NumberSequence.new(pts)
end

--==============================================================================
-- BUILD ONE, GROWN TO THE FRAME HEIGHT ASKED FOR
--
-- The species builders each make their own Model, which is how they were
-- approved and how the mockup still calls them. Rather than rewrite five
-- functions, this builds into a scratch folder, grows what came out, and hands
-- the parts to the caller's model -- so CreatureModel keeps its own pivot and
-- its own tag, and the approved code is never touched.
--==============================================================================
--==============================================================================
-- BUILD ONE EMBERROOT SPECIES, CONFORMED TO ITS TIER
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
--==============================================================================
-- THE ROOTS DO NOT GROW LIKE THE BODY
--
-- Plant height comes off the game's tier curve, where Colossal is fifty times
-- Tiny. That curve is a known problem and it is NOT this file's to fix -- but
-- the footprint is. A root system taking the full multiplier would put a
-- Colossal Emberroot's roots roughly 270 studs across, in a planting cell that
-- is eleven.
--
-- So a tagged ground root takes hs^ROOT_DAMP instead, under a hard ceiling.
-- UNIFORMLY, on all three axes: the whole point is to keep the sculpture's
-- shape -- its taper, its arc, its overlaps -- and change only how much of the
-- plot it covers. Scaling the axes differently would squash it back into the
-- slab this replaced.
--
--     hs        1.25 (Tiny)      62.4 (Colossal)
--     root      1.03             1.94
--
-- The upper body is still on the 50x curve and still wrong. This bounds the
-- ground, not the plant.
--==============================================================================
local ROOT_DAMP = 0.16
local ROOT_MAX_SCALE = 2.0

function EmberrootForms.Build(model: Model, id: string, at: CFrame, hs: number, gs: number?): boolean
	local fn = BUILDERS[id]
	if not fn then
		return false
	end
	local scratch = Instance.new("Folder")
	scratch.Parent = model
	local built = fn(scratch, at)

	local spread = if type(gs) == "number" and gs == gs and gs > 0 then gs else 1
	local rootHs = math.min(hs ^ ROOT_DAMP, ROOT_MAX_SCALE)
	if math.abs(hs - 1) > 1e-6 or math.abs(spread - 1) > 1e-6 then
		for _, d in ipairs(built:GetDescendants()) do
			if d:IsA("BasePart") then
				-- A tagged ground root grows on the damped curve; everything
				-- else is the body and grows with it.
				local s = if d:GetAttribute("GroundRoot") then rootHs else hs
				d.CFrame = at * scaled(at:ToObjectSpace(d.CFrame), s, spread)
				-- Size takes the height scale ALONE. See scaled().
				d.Size = d.Size * s
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

return EmberrootForms
