--!strict
-- Steal a Seed :: MapDecor
--
-- Dresses the map. MapService decides where the road IS; this decides what
-- grows beside it -- and, since 2026-09-18, what a nest is made of.
--
-- NOT NAMED "*Service" ON PURPOSE. ServerMain auto-requires and starts every
-- ModuleScript in this folder whose name ends in Service. This is a helper with
-- no lifecycle of its own -- MapService calls it during its own Init -- so it
-- must stay outside that convention. Same reason the previous project called
-- its ore builder `OreModelFactory` rather than `OreService`.
--
--==============================================================================
-- FOUR RULES, ALL OF THEM LOAD-BEARING
--
-- 1. NOTHING IS COLLIDABLE. Every prop here is CanCollide = false, CanTouch =
--    false, CanQuery = false. A player sprinting home at WalkSpeed 150 who
--    catches on a fern has been robbed by the scenery, and in a game whose
--    entire tension is a chase, that is not a small bug. It is the same reason
--    the plot fences are non-collidable. CanQuery = false is what keeps a bat's
--    raycast, a trap's drop test and a pod's prompt from ever seeing any of it.
--
--    That includes the NEST CRADLES. A guardian walks out of its cradle to
--    chase and walks back into it to sleep, and a rim it could snag on would be
--    a chase that ends against a decoration. The cradle is a picture of a nest;
--    the nest itself is still the guardian, the ring of pods and the invisible
--    site marker MapService leaves for NestService.
--
-- 2. HEIGHT FALLS OFF TOWARD THE CENTRE. Tall props only near the walls; the
--    middle of the road gets ground cover and nothing else. Being able to stand
--    at the red line and see all five biomes receding is the entire progression
--    display -- it is WHY the map is one corridor -- and a row of trees down the
--    middle deletes it. Low props are biased toward the walls too, so the road
--    reads as a road with verges rather than a meadow with a line through it.
--
-- 3. PLACEMENT IS DETERMINISTIC. Every scatter runs off a Random seeded from
--    the biome's own name, so every server in the game builds the identical
--    world. `math.random` would give each server its own map, which breaks
--    "the third pod past the big mushroom" as a thing anybody can say. Every
--    builder that varies takes that same Random, so a variant is a seed too.
--
-- 4. SCULPTED, NOT STACKED. The 2026-09-18 pass was built to the owner's
--    approved concept sheet: a tree is a tapered trunk with root flares,
--    branches leaving it at different heights and an asymmetric crown of
--    overlapping leaf masses; a rock is three or four rotated slabs; a flower
--    has a stem, leaves, petal masses and a centre. A Block, Ball or Cylinder
--    left on its own reads as a Block, Ball or Cylinder (the project's
--    organic-form skill), so nothing here is one primitive, and balls are kept
--    for the small round things -- a flower's centre, a bud, a pebble.
--
--    STUDS ON THE BIG SURFACES. Trunks, canopies, rocks, slabs and cradles show
--    studs on every face -- the game's identity, and a SurfaceType rather than
--    a part per stud. Small foliage stays smooth: a stud is a whole stud wide
--    and a petal is not.
--
--    PLASTIC, WITH NEON FOR THE FEW THINGS THAT GLOW AND GLASS FOR WATER. Wood,
--    Grass and Slate each paint their own texture over the studs (the plot beds
--    found this first -- see MapService on why beds are Plastic), and every
--    material is another draw batch on a phone.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))

local MapDecor = {}

local MAP = GameConfig.Map
local Y = MAP.GroundY
local RAD = math.rad
local TAU = math.pi * 2

local BALL = Enum.PartType.Ball
local CYLINDER = Enum.PartType.Cylinder
local WEDGE = Enum.PartType.Wedge

--==============================================================================
-- THE PART HELPER
--
-- Deliberately a second one rather than sharing MapService's. Its defaults are
-- the inverse: solid there, because that is the world; ghostly here, because
-- this is dressing. Sharing one helper would mean every call site here passing
-- three flags and one day forgetting.
--
-- `studs` marks a MAJOR mass: it gets studs on all six faces and casts a
-- shadow, which is what plants a tree on the ground instead of hovering over
-- it. Everything else is smooth and casts nothing -- a hundred petals' shadows
-- are a hundred petals' shadows.
--==============================================================================
type Opts = {
	material: Enum.Material?,
	studs: boolean?,
	shape: Enum.PartType?,
	transparency: number?,
}

local function piece(parent: Instance, name: string, size: Vector3, cf: CFrame,
	color: Color3, opts: Opts?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	if opts and opts.shape then
		p.Shape = opts.shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = (opts and opts.material) or Enum.Material.Plastic
	p.Transparency = (opts and opts.transparency) or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	local major = opts ~= nil and opts.studs == true
	p.CastShadow = major
	local surface = if major then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	p.TopSurface = surface
	p.BottomSurface = surface
	p.FrontSurface = surface
	p.BackSurface = surface
	p.LeftSurface = surface
	p.RightSurface = surface
	p.Parent = parent
	return p
end

-- One Model per prop, so a tree streams in as a tree and the Explorer reads
-- "Oak, Oak, Boulder" rather than three hundred loose parts.
local function group(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

local STUDDED: Opts = { studs = true }
local SMOOTH: Opts = {}
local NEON: Opts = { material = Enum.Material.Neon }
local BALL_SMOOTH: Opts = { shape = BALL }
local BALL_NEON: Opts = { shape = BALL, material = Enum.Material.Neon }
local CYL_SMOOTH: Opts = { shape = CYLINDER }
local CYL_STUDDED: Opts = { shape = CYLINDER, studs = true }
local WATER: Opts = { shape = CYLINDER, material = Enum.Material.Glass, transparency = 0.25 }

--==============================================================================
-- A DETERMINISTIC SEED FROM A STRING
--
-- Mod-p polynomial hash. NOT FNV-1a, which is the obvious choice and the wrong
-- one in Luau: `h * 16777619` exceeds the double mantissa and silently loses
-- precision, so it stops being reproducible at exactly the point you are
-- relying on it being reproducible. This stays exact.
--==============================================================================
local function seedFor(text: string): number
	local h = 5381
	for i = 1, #text do
		h = (h * 33 + string.byte(text, i)) % 2147483647
	end
	return h
end

--==============================================================================
-- THE SCULPTING VOCABULARY
--
-- Four moves, and every prop below is made of them:
--
--   chain      a tapered run of blocks along a frame's Y axis, each segment bent
--              a little further than the last. Trunks, branches, stilt roots,
--              curved stalks. Segments overlap by eight percent so the joints
--              are inside the wood rather than showing daylight.
--   flatWedge  a wedge lying with its thick end at the frame and its tip `len`
--              away along the frame's -Z. Root flares, petals, leaves, sepals.
--   blade      a wedge standing on its thick end, tip up, leaning toward the
--              frame's -Z. Grass, ferns, upright petals, the Starbloom slabs.
--   radial     a frame `r` out from a centre along azimuth `a`, facing outward
--              -- so a fan of anything is one loop over azimuths.
--
-- Wedge geometry, measured rather than assumed (2026-09-18): the full-height
-- face is at +Z and the thin edge at -Z; a Cylinder's axis runs along X.
--==============================================================================
local function chain(parent: Instance, name: string, start: CFrame, count: number,
	length: number, thick: number, taper: number, bend: Vector3, color: Color3,
	opts: Opts?): CFrame
	local cur = start
	local len, th = length, thick
	for _ = 1, count do
		piece(parent, name, Vector3.new(th, len, th), cur * CFrame.new(0, len * 0.5, 0), color, opts)
		cur = cur * CFrame.new(0, len * 0.92, 0) * CFrame.Angles(bend.X, bend.Y, bend.Z)
		len *= taper
		th *= taper
	end
	return cur
end

-- A frame at `cf` whose Y axis points `elevation` above the horizontal along
-- `azimuth`. Where a branch leaves a trunk.
local function aim(cf: CFrame, azimuth: number, elevation: number): CFrame
	return cf * CFrame.Angles(0, azimuth, 0) * CFrame.Angles(0, 0, -(math.pi * 0.5 - elevation))
end

local function radial(cf: CFrame, azimuth: number, r: number): CFrame
	return cf * CFrame.Angles(0, azimuth, 0) * CFrame.new(0, 0, -r)
end

local function flatWedge(parent: Instance, name: string, cf: CFrame, width: number,
	height: number, len: number, color: Color3, opts: Opts?): BasePart
	local o: Opts = { shape = WEDGE, studs = opts and opts.studs, material = opts and opts.material }
	return piece(parent, name, Vector3.new(width, height, len),
		cf * CFrame.new(0, height * 0.5, -len * 0.5), color, o)
end

local function blade(parent: Instance, name: string, base: CFrame, width: number,
	thick: number, len: number, lean: number, color: Color3, opts: Opts?): BasePart
	local o: Opts = { shape = WEDGE, studs = opts and opts.studs, material = opts and opts.material }
	local cf = base * CFrame.Angles(math.pi * 0.5 - lean, 0, 0)
	return piece(parent, name, Vector3.new(width, thick, len), cf * CFrame.new(0, 0, -len * 0.5), color, o)
end

-- A cylinder standing on end: `h` tall, `d` across, its foot at `cf`.
local function column(parent: Instance, name: string, cf: CFrame, h: number, d: number,
	color: Color3, opts: Opts?): BasePart
	local o: Opts = { shape = CYLINDER, studs = opts and opts.studs,
		material = opts and opts.material, transparency = opts and opts.transparency }
	return piece(parent, name, Vector3.new(h, d, d), cf * CFrame.new(0, h * 0.5, 0)
		* CFrame.Angles(0, 0, math.pi * 0.5), color, o)
end

-- A cylinder lying flat as a disc, `t` thick and `d` across, its underside at `cf`.
local function disc(parent: Instance, name: string, cf: CFrame, t: number, d: number,
	color: Color3, opts: Opts?): BasePart
	local o: Opts = { shape = CYLINDER, studs = opts and opts.studs,
		material = opts and opts.material, transparency = opts and opts.transparency }
	return piece(parent, name, Vector3.new(t, d, d), cf * CFrame.new(0, t * 0.5, 0)
		* CFrame.Angles(0, 0, math.pi * 0.5), color, o)
end

local function jitter(rng: Random, amount: number): number
	return rng:NextNumber(-amount, amount)
end

--==============================================================================
-- PALETTES
--
-- Sampled from the approved concept sheet, then pulled toward what already
-- exists: a biome's ground and wall colours are BiomeData's and were not
-- moved, so the new scenery had to sit on the old floor. Saturation is spent
-- where the sheet spends it -- Emberroot's amber and Starbloom's cyan are the
-- only glows -- and Greenhollow stays greens, creams and one coral, for the
-- same reason the plant art bible keeps the first biome quiet.
--==============================================================================
local GH = {
	Bark = Color3.fromRGB(112, 78, 52),
	BarkDark = Color3.fromRGB(84, 58, 40),
	Leaf = Color3.fromRGB(86, 176, 74),
	LeafLight = Color3.fromRGB(118, 200, 92),
	LeafDeep = Color3.fromRGB(64, 148, 62),
	Fern = Color3.fromRGB(74, 152, 68),
	Stem = Color3.fromRGB(84, 156, 74),
	Cream = Color3.fromRGB(248, 240, 214),
	Gold = Color3.fromRGB(250, 208, 70),
	Coral = Color3.fromRGB(240, 128, 104),
	Stone = Color3.fromRGB(134, 142, 122),
	StoneDark = Color3.fromRGB(104, 112, 96),
	Moss = Color3.fromRGB(98, 164, 84),
}

local DB = {
	Bark = Color3.fromRGB(150, 108, 72),
	BarkDark = Color3.fromRGB(118, 82, 54),
	Crown = Color3.fromRGB(150, 168, 118),
	CrownLight = Color3.fromRGB(172, 188, 132),
	Cactus = Color3.fromRGB(104, 152, 88),
	CactusLight = Color3.fromRGB(126, 170, 104),
	Pink = Color3.fromRGB(236, 118, 172),
	Grass = Color3.fromRGB(214, 184, 110),
	GrassDark = Color3.fromRGB(190, 158, 92),
	Sandstone = Color3.fromRGB(210, 162, 106),
	Terracotta = Color3.fromRGB(196, 112, 72),
	Ochre = Color3.fromRGB(216, 164, 82),
	Rust = Color3.fromRGB(168, 88, 56),
	Clay = Color3.fromRGB(184, 124, 88),
	Sand = Color3.fromRGB(232, 208, 150),
}

local TM = {
	Bark = Color3.fromRGB(70, 58, 46),
	BarkLight = Color3.fromRGB(92, 76, 58),
	Leaf = Color3.fromRGB(56, 128, 96),
	LeafLight = Color3.fromRGB(78, 150, 108),
	LeafDeep = Color3.fromRGB(40, 100, 88),
	Moss = Color3.fromRGB(112, 164, 82),
	MossPale = Color3.fromRGB(150, 186, 120),
	Fern = Color3.fromRGB(68, 140, 90),
	Violet = Color3.fromRGB(154, 110, 196),
	VioletDeep = Color3.fromRGB(120, 78, 168),
	Lip = Color3.fromRGB(236, 224, 244),
	Stone = Color3.fromRGB(96, 110, 100),
	StoneDark = Color3.fromRGB(70, 84, 78),
	Water = Color3.fromRGB(48, 96, 90),
	Pad = Color3.fromRGB(86, 160, 96),
	Lotus = Color3.fromRGB(236, 150, 200),
	LotusCore = Color3.fromRGB(250, 228, 150),
}

local EM = {
	Char = Color3.fromRGB(38, 34, 34),
	CharLight = Color3.fromRGB(58, 50, 48),
	Basalt = Color3.fromRGB(78, 74, 74),
	BasaltDark = Color3.fromRGB(56, 52, 52),
	Burnt = Color3.fromRGB(96, 66, 56),
	Rust = Color3.fromRGB(160, 84, 48),
	Ash = Color3.fromRGB(128, 118, 112),
	Amber = Color3.fromRGB(255, 150, 48),
	Ember = Color3.fromRGB(255, 104, 36),
	Petal = Color3.fromRGB(154, 34, 30),
	PetalDark = Color3.fromRGB(112, 26, 24),
}

local SB = {
	Indigo = Color3.fromRGB(58, 38, 110),
	IndigoLight = Color3.fromRGB(84, 58, 148),
	Violet = Color3.fromRGB(112, 74, 178),
	VioletLight = Color3.fromRGB(140, 104, 204),
	Lavender = Color3.fromRGB(170, 142, 222),
	LavenderPale = Color3.fromRGB(198, 178, 236),
	Cyan = Color3.fromRGB(120, 236, 255),
	CyanPale = Color3.fromRGB(176, 232, 244),
	Pink = Color3.fromRGB(240, 176, 226),
	Rock = Color3.fromRGB(70, 48, 116),
	RockLight = Color3.fromRGB(104, 76, 160),
	Vine = Color3.fromRGB(118, 84, 176),
}

--==============================================================================
-- THE BUILDERS
--
-- Every builder takes the same four things -- a parent, a ground frame with the
-- scatter's yaw already in it, a scale, and the biome's Random -- and returns
-- the Model it built. The Random is for variation WITHIN a prop (which way an
-- acacia bends, where the third branch leaves the trunk), never for whether
-- the prop exists or where it stands; those are the scatter's.
--==============================================================================

--------------------------------------------------------------------------------
-- GREENHOLLOW
--------------------------------------------------------------------------------

-- An oak: three-segment tapered trunk with a slight lean, five root flares,
-- three branches leaving at different heights, and a crown of five overlapping
-- leaf masses that is wider on one side. 19 parts.
local function oak(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "Oak")
	local lean = jitter(rng, RAD(4))
	local top = chain(m, "Trunk", cf * CFrame.Angles(0, 0, lean), 3, 4.4 * s, 2.7 * s, 0.8,
		Vector3.new(jitter(rng, RAD(5)), RAD(30), -lean * 0.6), GH.Bark, STUDDED)
	for i = 1, 5 do
		local a = (i - 1) / 5 * TAU + jitter(rng, RAD(18))
		flatWedge(m, "Root", radial(cf, a, 0.9 * s) * CFrame.new(0, -0.2, 0),
			1.2 * s, 1.7 * s, 3.0 * s, GH.BarkDark, STUDDED)
	end
	local h = 4.4 * s * 0.92 * (1 + 0.8 + 0.64)
	for _, spec in ipairs({ { 0.5, RAD(40), RAD(38) }, { 0.7, RAD(160), RAD(46) }, { 0.86, RAD(270), RAD(30) } }) do
		local az = spec[2] + jitter(rng, RAD(25))
		chain(m, "Branch", aim(cf * CFrame.new(0, h * spec[1], 0), az, spec[3]), 2, 3.4 * s, 1.1 * s, 0.7,
			Vector3.new(0, 0, RAD(-14)), GH.Bark, STUDDED)
	end
	local crown = top * CFrame.new(0, -0.6 * s, 0)
	local masses = {
		{ Vector3.new(11, 6.4, 10), Vector3.new(0.6, 1.4, -0.4), GH.Leaf, RAD(8) },
		{ Vector3.new(8.5, 5.8, 8.5), Vector3.new(-3.6, 3.4, 1.8), GH.LeafDeep, RAD(-22) },
		{ Vector3.new(8, 5.4, 7.5), Vector3.new(3.9, 4.0, 2.4), GH.LeafLight, RAD(31) },
		{ Vector3.new(6.5, 4.8, 6.5), Vector3.new(-0.8, 6.4, -2.0), GH.Leaf, RAD(-9) },
		{ Vector3.new(5, 4, 4.8), Vector3.new(1.6, 8.6, 0.6), GH.LeafLight, RAD(18) },
	}
	for _, mass in ipairs(masses) do
		piece(m, "Crown", mass[1] * s, crown * CFrame.new(mass[2] * s)
			* CFrame.Angles(0, mass[4] + jitter(rng, RAD(8)), 0), mass[3], STUDDED)
	end
	return m
end

-- Three studded masses and a leaf tuft. The field's undergrowth and
-- Greenhollow's.
local function shrub(parent: Instance, cf: CFrame, s: number, rng: Random, dark: Color3, light: Color3): Model
	local m = group(parent, "Shrub")
	piece(m, "Mass", Vector3.new(5.6, 3.6, 5) * s, cf * CFrame.new(0, 1.7 * s, 0) * CFrame.Angles(0, jitter(rng, RAD(20)), 0), dark, STUDDED)
	piece(m, "Mass", Vector3.new(4, 3, 3.8) * s, cf * CFrame.new(2.3 * s, 1.3 * s, 1.2 * s) * CFrame.Angles(0, RAD(35), RAD(6)), light, STUDDED)
	piece(m, "Mass", Vector3.new(3.4, 2.6, 3.2) * s, cf * CFrame.new(-2 * s, 1.1 * s, -1.4 * s) * CFrame.Angles(0, RAD(-28), RAD(-5)), dark, STUDDED)
	blade(m, "Tuft", cf * CFrame.new(-0.4 * s, 3.2 * s, 0.6 * s) * CFrame.Angles(0, RAD(70), 0), 1.6 * s, 0.5 * s, 2.2 * s, RAD(30), light)
	return m
end

-- A boulder: three overlapping slabs rotated on every axis, a broken facet, a
-- moss patch that follows the top, and a pebble. 5-7 parts.
local function boulder(parent: Instance, cf: CFrame, s: number, rng: Random,
	body: Color3, dark: Color3, moss: Color3?): Model
	local m = group(parent, "Boulder")
	local yaw = jitter(rng, RAD(30))
	piece(m, "Rock", Vector3.new(5.4, 3.4, 4.6) * s,
		cf * CFrame.new(0, 1.5 * s, 0) * CFrame.Angles(RAD(7), yaw, RAD(10)), body, STUDDED)
	piece(m, "Rock", Vector3.new(3.6, 2.6, 3.4) * s,
		cf * CFrame.new(2.4 * s, 1 * s, 1.3 * s) * CFrame.Angles(RAD(-6), yaw + RAD(38), RAD(-12)), dark, STUDDED)
	piece(m, "Rock", Vector3.new(3, 2, 3.2) * s,
		cf * CFrame.new(-2.2 * s, 0.8 * s, -1.2 * s) * CFrame.Angles(RAD(12), yaw - RAD(24), RAD(4)), body, STUDDED)
	flatWedge(m, "Facet", cf * CFrame.new(0.8 * s, 2.6 * s, 1.4 * s) * CFrame.Angles(RAD(-20), yaw + RAD(200), RAD(8)),
		2.6 * s, 1.4 * s, 2.4 * s, dark, STUDDED)
	if moss then
		piece(m, "Moss", Vector3.new(3.6, 0.5, 2.8) * s,
			cf * CFrame.new(-0.6 * s, 3.2 * s, -0.5 * s) * CFrame.Angles(RAD(7), yaw, RAD(10)), moss, SMOOTH)
		piece(m, "Moss", Vector3.new(1.8, 0.4, 1.6) * s,
			cf * CFrame.new(2.6 * s, 2.3 * s, 1.6 * s) * CFrame.Angles(RAD(-6), yaw + RAD(38), RAD(-12)), moss, SMOOTH)
	end
	piece(m, "Pebble", Vector3.new(1.1, 1.1, 1.1) * s, cf * CFrame.new(3.6 * s, 0.4 * s, -1.6 * s), dark, BALL_SMOOTH)
	return m
end

-- A daisy is a stem, a leaf, four crossed petal slabs (eight lobes) and a
-- centre. Clustered three to a prop at different heights and spacings, so no
-- two read as a copy.
local function daisyCluster(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "Daisies")
	for i = 1, 3 do
		local a = (i - 1) / 3 * TAU + jitter(rng, RAD(30))
		local d = if i == 1 then 0 else rng:NextNumber(1.6, 2.6) * s
		local hs = s * rng:NextNumber(0.75, 1.15)
		local base = radial(cf, a, d)
		local height = 2.8 * hs
		piece(m, "Stem", Vector3.new(0.3, height, 0.3), base * CFrame.new(0, height * 0.5, 0)
			* CFrame.Angles(jitter(rng, RAD(8)), 0, jitter(rng, RAD(8))), GH.Stem, SMOOTH)
		flatWedge(m, "Leaf", base * CFrame.new(0, 0.6 * hs, 0) * CFrame.Angles(RAD(20), RAD(50), 0),
			0.7 * hs, 0.14, 1.5 * hs, GH.Fern, SMOOTH)
		local head = base * CFrame.new(0, height, 0)
		for k = 0, 3 do
			piece(m, "Petals", Vector3.new(3.1 * hs, 0.16, 0.85 * hs),
				head * CFrame.Angles(0, RAD(45 * k), 0), GH.Cream, SMOOTH)
		end
		piece(m, "Centre", Vector3.new(0.9, 0.9, 0.9) * hs, head * CFrame.new(0, 0.2, 0), GH.Gold, BALL_SMOOTH)
	end
	return m
end

-- Coral bells: a bent stalk with three bells hanging off it and a leaf at the
-- foot. Two stalks a prop. The bell is a cylinder mouth-down, which is the
-- shape a bellflower actually has.
local function coralBells(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "CoralBells")
	for i = 1, 2 do
		local base = radial(cf, (i - 1) * RAD(150) + jitter(rng, RAD(30)), if i == 1 then 0 else 2 * s)
		local hs = s * rng:NextNumber(0.85, 1.1)
		local tip = chain(m, "Stalk", base * CFrame.Angles(0, jitter(rng, RAD(60)), 0), 2, 2.2 * hs, 0.3, 0.85,
			Vector3.new(RAD(24), 0, 0), GH.Stem, SMOOTH)
		flatWedge(m, "Leaf", base * CFrame.new(0, 0.5 * hs, 0) * CFrame.Angles(RAD(25), RAD(-40), 0),
			0.9 * hs, 0.16, 1.8 * hs, GH.Fern, SMOOTH)
		for k = 1, 3 do
			local along = base:Lerp(tip, 0.5 + k * 0.18)
			column(m, "Bell", along * CFrame.new(0.4 * (k % 2 == 0 and 1 or -1) * hs, -1.0 * hs, 0),
				1.0 * hs, 0.9 * hs, GH.Coral, CYL_SMOOTH)
		end
	end
	return m
end

-- A fern is six fronds rising from one point, leaning out at different
-- angles. The lean is what makes it a rosette instead of a star.
local function fern(parent: Instance, cf: CFrame, s: number, rng: Random, color: Color3): Model
	local m = group(parent, "Fern")
	local base = cf * CFrame.new(0, 0.2, 0)
	for i = 1, 6 do
		local a = (i - 1) / 6 * TAU + jitter(rng, RAD(14))
		local lean = RAD(rng:NextNumber(38, 62))
		blade(m, "Frond", radial(base, a, 0.3 * s), 1.1 * s, 0.5 * s, rng:NextNumber(2.8, 4.2) * s, lean, color, SMOOTH)
	end
	return m
end

-- Four blades, low, leaning different ways, with ground showing between them.
local function grassTuft(parent: Instance, cf: CFrame, s: number, rng: Random,
	color: Color3, dark: Color3, tall: number): Model
	local m = group(parent, "Grass")
	for i = 1, 4 do
		local a = (i - 1) / 4 * TAU + jitter(rng, RAD(40))
		local c = if i % 2 == 0 then dark else color
		blade(m, "Blade", radial(cf, a, 0.35 * s), 0.7 * s, 0.4 * s, rng:NextNumber(0.8, 1.15) * tall * s,
			RAD(rng:NextNumber(14, 34)), c, SMOOTH)
	end
	return m
end

-- Fallen wood: two log segments at a slight angle and a stub. 3 parts.
local function fallenLog(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "FallenLog")
	local a = cf * CFrame.new(0, 0.9 * s, 0) * CFrame.Angles(0, 0, RAD(90 + jitter(rng, 6)))
	piece(m, "Log", Vector3.new(1.9 * s, 5 * s, 1.9 * s), a * CFrame.new(0, 2.4 * s, 0), GH.BarkDark, STUDDED)
	piece(m, "Log", Vector3.new(1.6 * s, 4 * s, 1.6 * s), a * CFrame.new(0, -1.8 * s, 0) * CFrame.Angles(RAD(7), 0, 0), GH.Bark, STUDDED)
	piece(m, "Stub", Vector3.new(0.8 * s, 1.8 * s, 0.8 * s), a * CFrame.new(0.9 * s, 1.2 * s, 0) * CFrame.Angles(0, 0, RAD(-70)), GH.BarkDark, STUDDED)
	return m
end

--------------------------------------------------------------------------------
-- DUSTBOWL
--------------------------------------------------------------------------------

-- Wind-bent acacia: the trunk leans one way in three steps and the crown is
-- flat and sparse, four thin wide slabs at the top. 12 parts.
local function acacia(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "Acacia")
	local bend = RAD(rng:NextNumber(11, 17))
	local top = chain(m, "Trunk", cf * CFrame.Angles(0, 0, RAD(6)), 3, 4 * s, 2.0 * s, 0.8,
		Vector3.new(0, RAD(20), bend), DB.Bark, STUDDED)
	for i = 1, 3 do
		flatWedge(m, "Root", radial(cf, (i - 1) / 3 * TAU + jitter(rng, RAD(30)), 0.7 * s),
			1.0 * s, 1.2 * s, 2.4 * s, DB.BarkDark, STUDDED)
	end
	chain(m, "Branch", aim(cf * CFrame.new(0, 6.2 * s, 0), RAD(200) + jitter(rng, RAD(40)), RAD(28)), 2, 2.8 * s, 0.9 * s, 0.7,
		Vector3.new(0, 0, RAD(-16)), DB.Bark, STUDDED)
	local crown = top * CFrame.new(0, -0.4 * s, 0)
	local slabs = {
		{ Vector3.new(9, 0.9, 6), Vector3.new(0.4, 0.4, 0), DB.Crown, RAD(4) },
		{ Vector3.new(7, 0.8, 5), Vector3.new(-2.8, 1.1, 1.8), DB.CrownLight, RAD(-24) },
		{ Vector3.new(6.5, 0.8, 4.4), Vector3.new(3.2, 1.3, -1.2), DB.Crown, RAD(28) },
		{ Vector3.new(4.4, 0.7, 3.4), Vector3.new(0.6, 2.1, 0.8), DB.CrownLight, RAD(-8) },
	}
	for _, slab in ipairs(slabs) do
		piece(m, "Crown", slab[1] * s, crown * CFrame.new(slab[2] * s) * CFrame.Angles(0, slab[4], 0), slab[3], STUDDED)
	end
	return m
end

-- Paddle cactus: a standing base pad, two or three pads growing off its
-- corners at angles, and a pink flower on one. 4-6 parts.
local function paddleCactus(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "PaddleCactus")
	local pad = Vector3.new(2.8, 3.6, 1.0) * s
	local base = cf * CFrame.new(0, 1.6 * s, 0) * CFrame.Angles(0, 0, jitter(rng, RAD(8)))
	piece(m, "Pad", pad, base, DB.Cactus, STUDDED)
	local arms = { { 1.3, 2.9, RAD(-34) }, { -1.2, 3.1, RAD(38) }, { 0.4, 4.4, RAD(-8) } }
	local count = rng:NextInteger(2, 3)
	for i = 1, count do
		local arm = arms[i]
		piece(m, "Pad", pad * rng:NextNumber(0.62, 0.8),
			base * CFrame.new(arm[1] * s, arm[2] * s - 1.6 * s, jitter(rng, 0.3) * s) * CFrame.Angles(0, jitter(rng, RAD(20)), arm[3]),
			if i == 2 then DB.CactusLight else DB.Cactus, STUDDED)
	end
	if rng:NextNumber() < 0.6 then
		local arm = arms[count]
		piece(m, "Flower", Vector3.new(1.0, 1.0, 1.0) * s,
			base * CFrame.new(arm[1] * s * 1.3, arm[2] * s + 0.4 * s, 0), DB.Pink, BALL_SMOOTH)
	end
	return m
end

-- A column cactus: a body with two elbowed arms. 5 parts.
local function columnCactus(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "Cactus")
	local h = 8 * s
	column(m, "Body", cf, h, 2.4 * s, DB.Cactus, CYL_SMOOTH)
	for i, side in ipairs({ 1, -1 }) do
		local at = h * (if i == 1 then 0.55 else 0.7)
		local yaw = jitter(rng, RAD(30))
		local elbow = cf * CFrame.Angles(0, yaw, 0) * CFrame.new(side * 1.9 * s, at, 0)
		piece(m, "Arm", Vector3.new(2.4 * s, 1.5 * s, 1.5 * s), elbow * CFrame.new(-side * 0.4 * s, 0, 0), DB.Cactus, CYL_SMOOTH)
		column(m, "Arm", elbow * CFrame.new(side * 0.6 * s, 0.2 * s, 0), (if i == 1 then 3.6 else 2.6) * s, 1.5 * s, DB.CactusLight, CYL_SMOOTH)
	end
	return m
end

-- Layered sandstone: four flat slabs stacked with offsets, alternating ochre
-- and terracotta, plus one broken wedge. 5 parts.
local function outcrop(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "Outcrop")
	local layers = {
		{ Vector3.new(7.5, 1.6, 6), 0.8, DB.Sandstone, Vector2.new(0, 0), RAD(0) },
		{ Vector3.new(6.5, 1.4, 5.2), 2.3, DB.Terracotta, Vector2.new(0.8, -0.5), RAD(9) },
		{ Vector3.new(5.4, 1.5, 4.4), 3.75, DB.Ochre, Vector2.new(-0.6, 0.7), RAD(-7) },
		{ Vector3.new(3.8, 1.2, 3.2), 5.1, DB.Sandstone, Vector2.new(0.9, 0.4), RAD(16) },
	}
	local yaw = jitter(rng, RAD(25))
	for _, l in ipairs(layers) do
		piece(m, "Slab", l[1] * s, cf * CFrame.new(l[4].X * s, l[2] * s, l[4].Y * s)
			* CFrame.Angles(RAD(2), yaw + l[5], RAD(-3)), l[3], STUDDED)
	end
	flatWedge(m, "Break", cf * CFrame.new(3.4 * s, 1.6 * s, 2.2 * s) * CFrame.Angles(0, yaw + RAD(220), 0),
		2.6 * s, 1.6 * s, 2.6 * s, DB.Rust, STUDDED)
	return m
end

-- Cracked clay: three thin plates with the ground showing between them.
local function clayPlates(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "ClayPlates")
	for i = 1, 3 do
		local a = (i - 1) / 3 * TAU + jitter(rng, RAD(25))
		piece(m, "Plate", Vector3.new(rng:NextNumber(2.4, 3.6), 0.26, rng:NextNumber(2, 3)) * s,
			radial(cf, a, 1.9 * s) * CFrame.new(0, 0.13, 0) * CFrame.Angles(0, jitter(rng, RAD(30)), 0),
			if i == 2 then DB.Rust else DB.Clay, STUDDED)
	end
	return m
end

--------------------------------------------------------------------------------
-- TANGLEMIRE
--------------------------------------------------------------------------------

-- A mangrove stands on six stilt roots, each a two-step chain from the trunk's
-- foot down to the ground, under a broad flat canopy with moss hanging off its
-- edges. 22 parts, the most expensive prop on the road and the biome's signature.
local function mangrove(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "Mangrove")
	local foot = 3.4 * s
	local base = cf * CFrame.new(0, foot, 0)
	for i = 1, 6 do
		local a = (i - 1) / 6 * TAU + jitter(rng, RAD(16))
		local start = aim(base * CFrame.new(0, -0.4 * s, 0), a, RAD(-rng:NextNumber(36, 52)))
		chain(m, "Stilt", start, 2, 2.6 * s, 1.0 * s, 0.85, Vector3.new(0, 0, RAD(-18)), TM.Bark, STUDDED)
	end
	local top = chain(m, "Trunk", base * CFrame.Angles(0, 0, jitter(rng, RAD(5))), 2, 4.2 * s, 2.2 * s, 0.82,
		Vector3.new(RAD(6), RAD(40), 0), TM.BarkLight, STUDDED)
	chain(m, "Branch", aim(base * CFrame.new(0, 5.0 * s, 0), RAD(120) + jitter(rng, RAD(60)), RAD(24)), 2, 3.0 * s, 0.9 * s, 0.7,
		Vector3.new(0, 0, RAD(-12)), TM.Bark, STUDDED)
	local crown = top * CFrame.new(0, -0.3 * s, 0)
	local slabs = {
		{ Vector3.new(12, 2.2, 10), Vector3.new(0.5, 0.8, 0), TM.Leaf, RAD(6) },
		{ Vector3.new(9, 2, 8), Vector3.new(-3.6, 2.4, 2.2), TM.LeafDeep, RAD(-30) },
		{ Vector3.new(8, 1.8, 7), Vector3.new(3.8, 2.8, -1.8), TM.LeafLight, RAD(26) },
		{ Vector3.new(6, 1.6, 5.5), Vector3.new(0.4, 4.2, 1.4), TM.Leaf, RAD(-12) },
		{ Vector3.new(4.4, 1.4, 4), Vector3.new(-1.2, 5.5, -1), TM.LeafLight, RAD(40) },
	}
	for _, slab in ipairs(slabs) do
		piece(m, "Crown", slab[1] * s, crown * CFrame.new(slab[2] * s) * CFrame.Angles(0, slab[4], 0), slab[3], STUDDED)
	end
	for i = 1, 3 do
		local a = RAD(i * 110) + jitter(rng, RAD(30))
		local len = rng:NextNumber(3.2, 5.4) * s
		piece(m, "HangingMoss", Vector3.new(0.7 * s, len, 0.45 * s),
			radial(crown, a, 5.2 * s) * CFrame.new(0, 0.4 * s - len * 0.5, 0), TM.MossPale, SMOOTH)
	end
	return m
end

-- An orchid: a bending stem, two flat lateral petals, one upright dorsal
-- petal, a pale lip and a leaf at the foot. Two to a prop. 14 parts.
local function orchidPair(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "Orchids")
	for i = 1, 2 do
		local hs = s * rng:NextNumber(0.85, 1.1)
		local base = radial(cf, (i - 1) * RAD(140) + jitter(rng, RAD(40)), if i == 1 then 0 else 2.2 * s)
		local tip = chain(m, "Stem", base * CFrame.Angles(0, jitter(rng, RAD(90)), 0), 2, 2.4 * hs, 0.3, 0.9,
			Vector3.new(RAD(16), 0, 0), TM.Fern, SMOOTH)
		flatWedge(m, "Leaf", base * CFrame.new(0, 0.3 * hs, 0) * CFrame.Angles(RAD(18), RAD(60), 0),
			1.0 * hs, 0.16, 2.4 * hs, TM.Fern, SMOOTH)
		local head = tip * CFrame.new(0, 0.1 * hs, 0)
		flatWedge(m, "Petal", head * CFrame.Angles(RAD(10), RAD(70), 0), 1.1 * hs, 0.18, 1.7 * hs, TM.Violet, SMOOTH)
		flatWedge(m, "Petal", head * CFrame.Angles(RAD(10), RAD(-70), 0), 1.1 * hs, 0.18, 1.7 * hs, TM.Violet, SMOOTH)
		blade(m, "Petal", head * CFrame.Angles(0, RAD(180), 0), 1.0 * hs, 0.3 * hs, 1.6 * hs, RAD(-12), TM.VioletDeep, SMOOTH)
		piece(m, "Lip", Vector3.new(0.7, 0.7, 0.7) * hs, head * CFrame.new(0, -0.1 * hs, -0.5 * hs), TM.Lip, BALL_SMOOTH)
	end
	return m
end

-- Three broad wetland leaves rising from one root. 3 parts.
local function broadLeaves(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "BroadLeaves")
	for i = 1, 3 do
		local a = (i - 1) / 3 * TAU + jitter(rng, RAD(25))
		blade(m, "Leaf", radial(cf, a, 0.4 * s), rng:NextNumber(2.0, 2.8) * s, 0.5 * s, rng:NextNumber(3.6, 5.0) * s,
			RAD(rng:NextNumber(30, 48)), if i == 2 then TM.LeafLight else TM.Leaf, SMOOTH)
	end
	return m
end

-- A side pool: a glass disc at the verge with three lily pads on it, one of
-- them carrying a lotus. Flat, decorative water -- nothing to swim in.
local function pool(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "Pool")
	local d = 15 * s
	disc(m, "Water", cf, 0.18, d, TM.Water, WATER)
	for i = 1, 3 do
		local a = (i - 1) / 3 * TAU + jitter(rng, RAD(40))
		local pd = rng:NextNumber(2.6, 4.2) * s
		local at = radial(cf, a, rng:NextNumber(0.2, 0.34) * d) * CFrame.new(0, 0.2, 0)
		disc(m, "LilyPad", at, 0.22, pd, TM.Pad, CYL_SMOOTH)
		if i == 1 then
			local head = at * CFrame.new(0, 0.4, 0)
			for k = 1, 4 do
				blade(m, "Lotus", radial(head, k / 4 * TAU + RAD(20), 0.35 * s), 0.9 * s, 0.3 * s, 1.5 * s, RAD(-28), TM.Lotus, SMOOTH)
			end
			piece(m, "LotusCore", Vector3.new(0.6, 0.6, 0.6) * s, head * CFrame.new(0, 0.5 * s, 0), TM.LotusCore, BALL_SMOOTH)
		end
	end
	return m
end

--------------------------------------------------------------------------------
-- EMBERROOT
--------------------------------------------------------------------------------

-- A charred tree: dark tapered trunk, two forking limbs that fork again, no
-- leaves, and two ember tips where the wood is still burning. 14 parts.
local function charredTree(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "CharredTree")
	local top = chain(m, "Trunk", cf * CFrame.Angles(0, 0, jitter(rng, RAD(6))), 2, 5 * s, 2.2 * s, 0.78,
		Vector3.new(RAD(8), RAD(30), 0), EM.Char, STUDDED)
	for i = 1, 3 do
		flatWedge(m, "Root", radial(cf, (i - 1) / 3 * TAU + jitter(rng, RAD(30)), 0.8 * s),
			1.0 * s, 1.4 * s, 2.6 * s, EM.CharLight, STUDDED)
	end
	local tips = {}
	for i, spec in ipairs({ { RAD(30), RAD(48) }, { RAD(200), RAD(40) } }) do
		local az = spec[1] + jitter(rng, RAD(30))
		local limb = chain(m, "Limb", aim(top * CFrame.new(0, -1.4 * s, 0), az, spec[2]), 2, 3.6 * s, 1.3 * s, 0.7,
			Vector3.new(0, 0, RAD(-20)), EM.Char, STUDDED)
		tips[i] = limb
		chain(m, "Twig", limb * CFrame.Angles(RAD(30), 0, RAD(35 * (i == 1 and 1 or -1))), 1, 2.4 * s, 0.6 * s, 1,
			Vector3.zero, EM.CharLight, STUDDED)
	end
	chain(m, "Twig", aim(top * CFrame.new(0, -0.3 * s, 0), RAD(110) + jitter(rng, RAD(40)), RAD(70)), 1, 2.8 * s, 0.8 * s, 1,
		Vector3.zero, EM.Char, STUDDED)
	for i = 1, 2 do
		piece(m, "EmberTip", Vector3.new(0.5, 0.9, 0.5) * s, tips[i] * CFrame.new(0, 0.2 * s, 0), EM.Amber, NEON)
	end
	return m
end

-- Fractured basalt: five columns of different heights leaning a little, and
-- on the marked ones an amber seam glowing between two of them -- the neon is
-- a block BEHIND the gap, so the light is a fissure rather than a lamp.
local function basaltOutcrop(parent: Instance, cf: CFrame, s: number, rng: Random, crack: boolean): Model
	local m = group(parent, "Basalt")
	local cols = {
		{ Vector2.new(0, 0), 4.6, 2.4, EM.Basalt },
		{ Vector2.new(2.3, 0.6), 3.4, 2.0, EM.BasaltDark },
		{ Vector2.new(-2.2, 0.9), 3.8, 2.2, EM.Basalt },
		{ Vector2.new(0.9, -2.1), 2.6, 1.9, EM.BasaltDark },
		{ Vector2.new(-1.1, 2.4), 2.2, 1.8, EM.Burnt },
	}
	local yaw = jitter(rng, RAD(30))
	for _, c in ipairs(cols) do
		local h = c[2] * s * rng:NextNumber(0.9, 1.1)
		piece(m, "Column", Vector3.new(c[3] * s, h, c[3] * s),
			cf * CFrame.Angles(0, yaw, 0) * CFrame.new(c[1].X * s, h * 0.5 - 0.3, c[1].Y * s)
				* CFrame.Angles(jitter(rng, RAD(7)), RAD(15), jitter(rng, RAD(7))), c[4], STUDDED)
	end
	if crack then
		piece(m, "Seam", Vector3.new(0.5 * s, 2.2 * s, 2.6 * s),
			cf * CFrame.Angles(0, yaw, 0) * CFrame.new(1.15 * s, 1.0 * s, 0.3 * s), EM.Ember, NEON)
	end
	return m
end

-- Ember lily: a stem, two dark leaves, four dark-red petals cupped upward and
-- a bright amber centre -- the only neon on the plant. Two to a prop.
local function emberLilies(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "EmberLilies")
	for i = 1, 2 do
		local hs = s * rng:NextNumber(0.85, 1.1)
		local base = radial(cf, (i - 1) * RAD(160) + jitter(rng, RAD(40)), if i == 1 then 0 else 2.2 * s)
		local height = 2.6 * hs
		piece(m, "Stem", Vector3.new(0.32, height, 0.32), base * CFrame.new(0, height * 0.5, 0)
			* CFrame.Angles(jitter(rng, RAD(8)), 0, jitter(rng, RAD(8))), EM.CharLight, SMOOTH)
		for k = 1, 2 do
			flatWedge(m, "Leaf", base * CFrame.new(0, 0.4 * hs, 0) * CFrame.Angles(RAD(22), RAD(k * 130), 0),
				0.8 * hs, 0.16, 1.8 * hs, EM.Burnt, SMOOTH)
		end
		local head = base * CFrame.new(0, height, 0)
		for k = 1, 4 do
			blade(m, "Petal", radial(head, k / 4 * TAU + jitter(rng, RAD(10)), 0.35 * hs), 1.0 * hs, 0.3 * hs, 1.6 * hs,
				RAD(-36), if k % 2 == 0 then EM.Petal else EM.PetalDark, SMOOTH)
		end
		piece(m, "Core", Vector3.new(0.6, 0.6, 0.6) * hs, head * CFrame.new(0, 0.5 * hs, 0), EM.Amber, BALL_NEON)
	end
	return m
end

--------------------------------------------------------------------------------
-- STARBLOOM
--------------------------------------------------------------------------------

-- A fan tree: one studded base, two trunk arms that sweep apart in three
-- curved steps, and a fan of three stacked discs on the end of each. 13 parts,
-- and nothing on it is a tree shape from any other biome.
local function fanTree(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "FanTree")
	piece(m, "Base", Vector3.new(3.4, 2.6, 3.0) * s, cf * CFrame.new(0, 1.2 * s, 0) * CFrame.Angles(0, jitter(rng, RAD(20)), 0), SB.Indigo, STUDDED)
	local split = cf * CFrame.new(0, 2.0 * s, 0) * CFrame.Angles(0, jitter(rng, RAD(40)), 0)
	for i, side in ipairs({ 1, -1 }) do
		local sweep = RAD(rng:NextNumber(12, 18)) * side
		local tip = chain(m, "Arm", split * CFrame.Angles(0, 0, side * RAD(14)), 3, (if i == 1 then 4.2 else 3.4) * s, 1.8 * s, 0.84,
			Vector3.new(0, 0, sweep), SB.Violet, STUDDED)
		local fan = tip * CFrame.new(0, -0.4 * s, 0) * CFrame.Angles(RAD(6), 0, -sweep * 1.5)
		local discs = { { 7.4, 0.9, SB.Lavender }, { 5.6, 0.8, SB.VioletLight }, { 3.8, 0.7, SB.LavenderPale } }
		local lift = 0
		for k, d in ipairs(discs) do
			disc(m, "Fan", fan * CFrame.new(jitter(rng, 0.5) * s, lift, jitter(rng, 0.5) * s) * CFrame.Angles(RAD(3 * k), 0, 0),
				d[2] * s, d[1] * s, d[3], CYL_STUDDED)
			lift += d[2] * s * 0.85
		end
	end
	return m
end

-- A cup blossom: a curved stalk with a four-petal cup on the end and a neon
-- pearl at its centre. The petals are pale plastic, not neon -- the glow is the
-- centre, and it is what makes the cup read as a lantern instead of a lamp.
local function cupStalks(parent: Instance, cf: CFrame, s: number, rng: Random, count: number): Model
	local m = group(parent, "CupBlossoms")
	for i = 1, count do
		local hs = s * rng:NextNumber(0.8, 1.15)
		local base = radial(cf, (i - 1) / count * TAU + jitter(rng, RAD(40)), if i == 1 then 0 else rng:NextNumber(1.8, 2.8) * s)
		local tip = chain(m, "Stalk", base * CFrame.Angles(0, jitter(rng, RAD(90)), 0), 3, 2.2 * hs, 0.42, 0.9,
			Vector3.new(RAD(rng:NextNumber(10, 18)), 0, 0), SB.Vine, SMOOTH)
		local cup = tip * CFrame.new(0, -0.2 * hs, 0)
		for k = 1, 4 do
			blade(m, "Petal", radial(cup, k / 4 * TAU + RAD(45), 0.5 * hs) * CFrame.Angles(0, math.pi, 0),
				1.1 * hs, 0.3 * hs, 1.7 * hs, RAD(-22), if k % 2 == 0 then SB.CyanPale else SB.Pink, SMOOTH)
		end
		piece(m, "Pearl", Vector3.new(1.0, 1.0, 1.0) * hs, cup * CFrame.new(0, 0.6 * hs, 0), SB.Cyan, BALL_NEON)
	end
	return m
end

-- A spiral fern: one curled frond in four steps, tightening as it goes. 4 parts.
local function spiralFern(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "SpiralFern")
	local cur = cf * CFrame.Angles(0, jitter(rng, math.pi), 0) * CFrame.Angles(RAD(-20), 0, 0)
	local len, w = 2.6 * s, 1.3 * s
	for i = 1, 4 do
		blade(m, "Curl", cur, w, 0.45 * s, len, 0, if i % 2 == 0 then SB.Lavender else SB.VioletLight, SMOOTH)
		cur = cur * CFrame.new(0, len * 0.12, -len * 0.9) * CFrame.Angles(RAD(-34 - i * 6), 0, 0)
		len *= 0.72
		w *= 0.8
	end
	return m
end

-- Ribbon grass: four tall thin blades bending over. 4 parts.
local function ribbonGrass(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "RibbonGrass")
	for i = 1, 4 do
		local a = (i - 1) / 4 * TAU + jitter(rng, RAD(35))
		blade(m, "Ribbon", radial(cf, a, 0.3 * s), 0.55 * s, 0.3 * s, rng:NextNumber(3.6, 5.6) * s,
			RAD(rng:NextNumber(26, 46)), if i % 2 == 0 then SB.Vine else SB.Lavender, SMOOTH)
	end
	return m
end

--==============================================================================
-- SCATTER
--
-- Places `count` props inside the two side bands of the road, alternating
-- sides, never in the middle, and never on top of a nest.
--
-- `tall` props are pushed to the outer third of the band, which is what
-- enforces rule 2 -- the sightline down the centre stays open because anything
-- with height is physically unable to be placed near it. Low props may come as
-- far in as CENTRE_CLEAR, but are biased toward the wall (the square root),
-- so the verges are where the density is and the road stays a road.
--==============================================================================
type Ctx = {
	parent: Instance,
	rng: Random,
	nearZ: number,
	farZ: number,
	taken: { { x: number, z: number, r: number } },
}

local CENTRE_CLEAR = 24   -- studs either side of the road's centre line
-- A nest's clearing: the cradle's outer dressing reaches 34 from the centre.
local NEST_CLEAR = 38

local function tooClose(ctx: Ctx, x: number, z: number, r: number): boolean
	for _, t in ipairs(ctx.taken) do
		local dx, dz = t.x - x, t.z - z
		if dx * dx + dz * dz < (t.r + r) * (t.r + r) then
			return true
		end
	end
	return false
end

local function scatter(ctx: Ctx, count: number, radius: number, tall: boolean,
	place: (Instance, CFrame, number) -> (), footprint: number?)
	local halfW = MAP.CorridorWidth * 0.5
	-- A tree's radius is its CROWN, which is what must stay off the racing
	-- line; its FOOTPRINT is its trunk and roots, which is all that another
	-- prop has to keep out of. Spacing trees by their crowns left Starbloom's
	-- verges empty under the fans (measured: 225 parts built of 350 asked).
	local spacing = footprint or (if tall then radius else radius * 0.75)
	-- PLUS THE PROP'S OWN RADIUS, and that is not a fudge factor. A prop is
	-- placed by its ANCHOR, but its pieces are offset from that anchor -- a rock
	-- carries a second block three studs to one side. Guarding only the anchor
	-- lets a prop sitting exactly on the boundary spill its far half over it,
	-- which is precisely what a check caught: a rock anchored at X=24 with a
	-- block at X=22.9, inside the racing line.
	--
	-- A TALL prop's radius is its crown, twenty studs up, which may overhang
	-- the band's inner edge (the anchor stays in the outer third, so the crown
	-- still clears the racing line) but must not push into the wall -- the
	-- wall is solid and a crown inside it is parts nobody sees.
	local minX = if tall then halfW * 0.62 else CENTRE_CLEAR + radius
	local maxX = halfW - 2 - radius

	for i = 1, count do
		local placed = false
		-- Bounded retries. A scatter that cannot find room must give up rather
		-- than spin -- a map that sometimes takes four seconds to build is
		-- worse than a map with one fewer bush.
		for _ = 1, 24 do
			local side = (i % 2 == 0) and 1 or -1
			local u = ctx.rng:NextNumber()
			if not tall then
				u = math.sqrt(u)
			end
			local x = side * (minX + (maxX - minX) * u)
			local z = ctx.rng:NextNumber(ctx.farZ + 12, ctx.nearZ - 12)
			if not tooClose(ctx, x, z, spacing) then
				table.insert(ctx.taken, { x = x, z = z, r = spacing })
				local scale = ctx.rng:NextNumber(0.8, 1.25)
				place(ctx.parent, CFrame.new(x, Y, z)
					* CFrame.Angles(0, ctx.rng:NextNumber(0, TAU), 0), scale)
				placed = true
				break
			end
		end
		if not placed then
			break
		end
	end
end

-- Flat markings on the floor. 0.2 studs tall, so they cannot obscure a
-- sightline or catch a runner. `verge` keeps them out of the racing line --
-- Emberroot's cracks and Starbloom's glow belong at the edges -- while
-- Dustbowl's sand drifts may still cross the whole road.
local function groundStreaks(ctx: Ctx, count: number, color: Color3, material: Enum.Material, verge: boolean)
	local halfW = MAP.CorridorWidth * 0.5 - 8
	for i = 1, count do
		local x
		if verge then
			x = ((i % 2 == 0) and 1 or -1) * ctx.rng:NextNumber(CENTRE_CLEAR + 4, halfW)
		else
			x = ctx.rng:NextNumber(-halfW, halfW)
		end
		local z = ctx.rng:NextNumber(ctx.farZ + 10, ctx.nearZ - 10)
		piece(ctx.parent, "Streak",
			Vector3.new(ctx.rng:NextNumber(6, 22), 0.2, ctx.rng:NextNumber(1.4, 3.4)),
			CFrame.new(x, Y + 0.15, z) * CFrame.Angles(0, ctx.rng:NextNumber(0, math.pi), 0),
			color, { material = material })
	end
end

-- Hung on the inside face of both walls. Cheap, and it is what stops a
-- 46-stud wall of flat colour being the largest thing in every screenshot. A
-- vine gets a leaf clump at its tip when `clump` is given.
local function wallGrowth(ctx: Ctx, count: number, color: Color3,
	material: Enum.Material, fromTop: boolean, clump: Color3?, breadth: number?, maxLen: number?)
	local innerX = MAP.CorridorWidth * 0.5 - 0.6
	local wide = breadth or 6
	local longest = maxLen or 26
	for i = 1, count do
		local side = (i % 2 == 0) and 1 or -1
		local z = ctx.rng:NextNumber(ctx.farZ + 6, ctx.nearZ - 6)
		local length = ctx.rng:NextNumber(longest * 0.35, longest)
		local y = fromTop and (MAP.WallHeight - length * 0.5) or (length * 0.5)
		piece(ctx.parent, "Growth",
			Vector3.new(1.2, length, ctx.rng:NextNumber(wide * 0.5, wide)),
			CFrame.new(side * innerX, Y + y, z),
			color, { material = material })
		if clump then
			local tipY = fromTop and (MAP.WallHeight - length) or length
			piece(ctx.parent, "Growth", Vector3.new(3.2, 3.4, ctx.rng:NextNumber(wide * 0.7, wide * 1.3)),
				CFrame.new(side * (innerX - 0.8), Y + tipY, z) * CFrame.Angles(0, 0, side * RAD(12)),
				clump, { material = material, studs = true })
		end
	end
end

--==============================================================================
-- THE NEST CRADLES
--
-- A picture of a nest around the real one. NestService's geometry is untouched:
-- the guardian sleeps at the site marker, the pods stand on their 16-stud
-- ring, the tutorial's reserved pod stands 24 out along the road. Every cradle
-- is built in the SITE'S OWN FRAME, whose -Z faces the road, and keeps to
-- three rules:
--
--   * the rim starts at radius 25 -- a Colossal shell on the ring reaches 22
--     -- and wraps only the wall-side 140 degrees. The road side is open, which
--     is the "low open front" the sheet draws, the way the guardian walks out,
--     and where the reserved pod stands;
--   * the bedding is a 0.16-stud disc, so nothing on the ring is buried;
--   * every part is a prop: non-collidable, non-queryable. The guardian's
--     return walk goes through the picture, not around it.
--
-- `arc(a, r)` is a frame `r` out along azimuth `a` from the BACK (+Z, toward
-- the wall), turned so its X runs along the rim and its +Z points outward.
--==============================================================================
local function arc(site: CFrame, a: number, r: number, y: number): CFrame
	return site * CFrame.new(math.sin(a) * r, y, math.cos(a) * r) * CFrame.Angles(0, a, 0)
end

local RIM = 26.5
local ARC = RAD(70)
-- Where the tufts that finish each end of a rim stand: past the rim, so their
-- blades cannot lean into the ring's clearance, and short of the road axis,
-- where the tutorial's reserved pod stands 24 out.
local FLANK = ARC + RAD(4)
local FLANK_R = RIM + 3

local NESTS: { [string]: (Instance, CFrame, Random) -> Model } = {}

-- Greenhollow: a root-woven cradle grown out of an old stump. Two interwoven
-- courses of root segments, moss bedding, three fern tufts at the ends.
NESTS.greenhollow = function(parent, site, rng)
	local m = group(parent, "NestCradle")
	disc(m, "Bedding", site, 0.16, 42, GH.Moss, CYL_SMOOTH)
	for i = 0, 8 do
		local a = -ARC + i / 8 * ARC * 2
		local low = arc(site, a, RIM, 0.75)
		piece(m, "Root", Vector3.new(7.4, 3.0, 3.0), low * CFrame.Angles(RAD(6), RAD(9), RAD((i % 2 == 0) and 7 or -7)), GH.BarkDark, STUDDED)
		if i < 8 then
			local high = arc(site, a + ARC / 8, RIM + 1.2, 3.6)
			piece(m, "Root", Vector3.new(7.2, 2.6, 2.6), high * CFrame.Angles(RAD(-8), RAD(-11), RAD((i % 2 == 0) and -9 or 9)), GH.Bark, STUDDED)
		end
	end
	local stump = arc(site, RAD(24), RIM + 1.8, 0)
	column(m, "Stump", stump, 5.2, 7.4, GH.Bark, CYL_STUDDED)
	disc(m, "StumpTop", stump * CFrame.new(0, 5.1, 0), 0.4, 6.4, GH.BarkDark, CYL_SMOOTH)
	-- Sideways and back: a root aimed at the ring would cross the clearance
	-- a Colossal shell needs.
	for _, az in ipairs({ RAD(100), RAD(180), RAD(255) }) do
		flatWedge(m, "StumpRoot", radial(stump, az, 2.4), 1.8, 2.6, 4.6, GH.BarkDark, STUDDED)
	end
	fern(m, arc(site, -FLANK, FLANK_R, 0), 1.8, rng, GH.Fern)
	fern(m, arc(site, FLANK, FLANK_R, 0), 1.6, rng, GH.Fern)
	fern(m, arc(site, RAD(-30), RIM + 4.5, 0), 1.9, rng, GH.Fern)
	return m
end

-- Dustbowl: a broken-clay sun basin. Sandy centre, a rim of overlapping
-- terracotta slabs at different tilts, three stacked sandstone slabs as the
-- backing, and dry grass where the rim ends.
NESTS.dustbowl = function(parent, site, rng)
	local m = group(parent, "NestCradle")
	disc(m, "Bedding", site, 0.16, 42, DB.Sand, CYL_SMOOTH)
	for i = 0, 7 do
		local a = -ARC + i / 7 * ARC * 2
		local h = rng:NextNumber(2.0, 3.6)
		local c = if i % 3 == 0 then DB.Rust elseif i % 3 == 1 then DB.Terracotta else DB.Clay
		piece(m, "Slab", Vector3.new(rng:NextNumber(7, 8.6), h, 3.2), arc(site, a, RIM + 0.6, h * 0.5 - 0.3)
			* CFrame.Angles(RAD(rng:NextNumber(4, 18)), RAD(jitter(rng, 10)), RAD(jitter(rng, 6))), c, STUDDED)
	end
	for i = 1, 3 do
		flatWedge(m, "Crack", arc(site, RAD(-40 + i * 26), 14, 0) * CFrame.Angles(0, RAD(180), 0), 2.6, 0.26, 5, DB.Clay, STUDDED)
	end
	local back = arc(site, 0, RIM + 3.2, 0)
	piece(m, "Backing", Vector3.new(16, 3.4, 3.6), back * CFrame.new(0, 1.7, 0), DB.Sandstone, STUDDED)
	piece(m, "Backing", Vector3.new(12.6, 3.0, 3.2), back * CFrame.new(1.4, 4.8, 0.3) * CFrame.Angles(0, RAD(6), RAD(3)), DB.Ochre, STUDDED)
	piece(m, "Backing", Vector3.new(8.4, 2.8, 2.8), back * CFrame.new(-1.8, 7.5, 0.2) * CFrame.Angles(0, RAD(-9), RAD(-4)), DB.Terracotta, STUDDED)
	grassTuft(m, arc(site, -FLANK, FLANK_R, 0), 2.0, rng, DB.Grass, DB.GrassDark, 3.2)
	grassTuft(m, arc(site, FLANK, FLANK_R, 0), 1.8, rng, DB.Grass, DB.GrassDark, 3.2)
	return m
end

-- Tanglemire: a low oval cradle of thick roots, two courses interwoven and
-- wetter and darker than Greenhollow's, moss bedding, and water-lily leaves
-- lying around the outside.
NESTS.tanglemire = function(parent, site, rng)
	local m = group(parent, "NestCradle")
	disc(m, "Bedding", site, 0.16, 42, TM.Moss, CYL_SMOOTH)
	for i = 0, 9 do
		local a = -ARC - RAD(6) + i / 9 * (ARC + RAD(6)) * 2
		local r = RIM + (if i % 2 == 0 then 0 else 1.2)
		local low = arc(site, a, r, 0.9)
		piece(m, "Root", Vector3.new(6.8, 2.6, 2.6), low * CFrame.Angles(RAD(jitter(rng, 10)), RAD(12), RAD((i % 2 == 0) and 10 or -10)), TM.Bark, STUDDED)
		if i < 9 then
			piece(m, "Root", Vector3.new(6.4, 2.2, 2.2), arc(site, a + RAD(8), r - 0.4, 3.4)
				* CFrame.Angles(RAD(jitter(rng, 8)), RAD(-14), RAD((i % 2 == 0) and -12 or 12)), TM.BarkLight, STUDDED)
		end
	end
	for i = 1, 4 do
		local a = RAD(-56 + (i - 1) * 37) + jitter(rng, RAD(6))
		disc(m, "LilyLeaf", arc(site, a, RIM + 5.4, 0), 0.24, rng:NextNumber(5.6, 8.0), TM.Pad, CYL_SMOOTH)
	end
	broadLeaves(m, arc(site, -FLANK, FLANK_R, 0), 1.3, rng)
	broadLeaves(m, arc(site, FLANK, FLANK_R, 0), 1.2, rng)
	return m
end

-- Emberroot: a fractured basalt cradle, a small caldera. Dark bedding, a rim
-- of angular slabs leaning outward at different heights, three amber seams
-- set between slabs at the back, and three basalt columns as the backing.
NESTS.emberroot = function(parent, site, rng)
	local m = group(parent, "NestCradle")
	disc(m, "Bedding", site, 0.16, 42, EM.BasaltDark, CYL_SMOOTH)
	local seams = { [2] = true, [5] = true, [7] = true }
	for i = 0, 8 do
		local a = -ARC + i / 8 * ARC * 2
		local h = rng:NextNumber(2.2, 4.2)
		piece(m, "Slab", Vector3.new(rng:NextNumber(6.4, 8), h, 2.6), arc(site, a, RIM + 0.4, h * 0.5 - 0.3)
			* CFrame.Angles(RAD(rng:NextNumber(8, 22)), RAD(jitter(rng, 8)), RAD(jitter(rng, 8))),
			if i % 2 == 0 then EM.Basalt else EM.BasaltDark, STUDDED)
		if seams[i] then
			piece(m, "Seam", Vector3.new(4.2, 0.4, 0.6), arc(site, a - ARC / 8, RIM + 0.4, 0.2), EM.Ember, NEON)
		end
	end
	local back = arc(site, 0, RIM + 3.6, 0)
	for i, c in ipairs({ { -4.4, 7.4, 3.2 }, { 0.4, 9.6, 3.8 }, { 5.0, 6.2, 2.8 } }) do
		piece(m, "Column", Vector3.new(c[3], c[2], c[3]), back * CFrame.new(c[1], c[2] * 0.5 - 0.3, 0)
			* CFrame.Angles(RAD(jitter(rng, 5)), RAD(12 * i), RAD(jitter(rng, 5))), if i == 2 then EM.Basalt else EM.BasaltDark, STUDDED)
	end
	piece(m, "Seam", Vector3.new(0.5, 3.6, 0.5), back * CFrame.new(-2.0, 1.9, 0.6), EM.Amber, NEON)
	grassTuft(m, arc(site, -FLANK, FLANK_R, 0), 1.8, rng, EM.Ash, EM.Rust, 2.6)
	grassTuft(m, arc(site, FLANK, FLANK_R, 0), 1.8, rng, EM.Rust, EM.Ash, 2.6)
	return m
end

-- Starbloom: a partially opened flower. A pale seed bed, a crescent of six
-- dark petal slabs standing on a low plinth and leaning back, three broad
-- sepals lying behind them, and two neon pearls on the tallest tips.
NESTS.starbloom = function(parent, site, rng)
	local m = group(parent, "NestCradle")
	disc(m, "Bedding", site, 0.16, 42, SB.LavenderPale, CYL_SMOOTH)
	for i = 0, 1 do
		piece(m, "Plinth", Vector3.new(17, 1.8, 4.4), arc(site, RAD(-28 + i * 56), RIM - 0.2, 0.7) * CFrame.Angles(0, 0, RAD(i == 0 and 3 or -3)), SB.Indigo, STUDDED)
	end
	local heights = { 10, 12.5, 14, 13, 12, 9.5 }
	for i = 1, 6 do
		local a = -ARC + (i - 1) / 5 * ARC * 2
		-- The base frame is turned to face the centre, so a blade's positive
		-- lean -- toward its own -Z -- is AWAY from it: the petals open outward,
		-- over the plinth and the sepals, never over the pods.
		local base = arc(site, a, RIM + 0.8, 0.8) * CFrame.Angles(0, math.pi, 0)
		-- 18 degrees: the wall is 32 studs behind the site, and a 14-stud slab
		-- leaning further would put its pearl inside it.
		local lean = RAD(18)
		blade(m, "PetalSlab", base, 8.2 + (i % 2) * 1.6, 2.6, heights[i], lean, if i % 2 == 0 then SB.Violet else SB.IndigoLight, STUDDED)
		if i == 3 or i == 4 then
			local tip = base * CFrame.Angles(math.pi * 0.5 - lean, 0, 0) * CFrame.new(0, 0, -heights[i])
			piece(m, "Pearl", Vector3.new(1.4, 1.4, 1.4), tip, SB.Cyan, BALL_NEON)
		end
	end
	for i = 1, 3 do
		local a = RAD(-34 + (i - 1) * 34)
		flatWedge(m, "Sepal", arc(site, a, RIM + 4.6, 0.3) * CFrame.Angles(RAD(40), 0, 0), 10.5, 2.2, 8, SB.Rock, STUDDED)
	end
	spiralFern(m, arc(site, -FLANK, FLANK_R + 5, 0), 2.0, rng)
	spiralFern(m, arc(site, FLANK, FLANK_R + 5, 0), 1.8, rng)
	return m
end

--==============================================================================
-- THE KITS
--
-- One per biome. Each is a short recipe rather than a list of coordinates,
-- which is what keeps a biome's identity readable in twelve lines and
-- re-tunable without moving anything by hand. Counts were set against a
-- budget of 520 decor parts a biome -- about one plot's bed of twelve grown
-- plants -- and the built totals are printed by dressSegment.
--==============================================================================
local KITS: { [string]: (Ctx, BiomeData.Biome) -> () } = {}

KITS.greenhollow = function(ctx, biome)
	scatter(ctx, 6, 18, true, function(p, cf, s)
		oak(p, cf, math.min(s, 1.1) * 2.1, ctx.rng)
	end, 7)
	scatter(ctx, 6, 8, false, function(p, cf, s)
		boulder(p, cf, s * 1.6, ctx.rng, GH.Stone, GH.StoneDark, GH.Moss)
	end)
	scatter(ctx, 6, 7, false, function(p, cf, s)
		shrub(p, cf, s * 1.7, ctx.rng, GH.LeafDeep, GH.Leaf)
	end)
	scatter(ctx, 6, 6, false, function(p, cf, s)
		daisyCluster(p, cf, s * 1.7, ctx.rng)
	end)
	scatter(ctx, 5, 5, false, function(p, cf, s)
		coralBells(p, cf, s * 1.7, ctx.rng)
	end)
	scatter(ctx, 6, 6, false, function(p, cf, s)
		fern(p, cf, s * 1.8, ctx.rng, GH.Fern)
	end)
	scatter(ctx, 8, 4, false, function(p, cf, s)
		grassTuft(p, cf, s * 1.8, ctx.rng, GH.LeafLight, GH.Leaf, 2.2)
	end)
	scatter(ctx, 3, 8, false, function(p, cf, s)
		fallenLog(p, cf, s * 1.6, ctx.rng)
	end)
	wallGrowth(ctx, 14, Color3.fromRGB(78, 158, 70), Enum.Material.Plastic, true, GH.LeafLight, 7, 30)
end

KITS.dustbowl = function(ctx, biome)
	scatter(ctx, 6, 16, true, function(p, cf, s)
		acacia(p, cf, math.min(s, 1.1) * 2.0, ctx.rng)
	end, 6)
	scatter(ctx, 5, 6, true, function(p, cf, s)
		columnCactus(p, cf, s * 1.8, ctx.rng)
	end)
	scatter(ctx, 7, 9, false, function(p, cf, s)
		outcrop(p, cf, s * 1.7, ctx.rng)
	end)
	scatter(ctx, 8, 5, false, function(p, cf, s)
		paddleCactus(p, cf, s * 1.8, ctx.rng)
	end)
	scatter(ctx, 12, 4, false, function(p, cf, s)
		grassTuft(p, cf, s * 1.8, ctx.rng, DB.Grass, DB.GrassDark, 3.2)
	end)
	scatter(ctx, 6, 6, false, function(p, cf, s)
		clayPlates(p, cf, s * 1.6, ctx.rng)
	end)
	groundStreaks(ctx, 10, Color3.fromRGB(196, 162, 116), Enum.Material.Sand, true)
end

KITS.tanglemire = function(ctx, biome)
	scatter(ctx, 6, 17, true, function(p, cf, s)
		mangrove(p, cf, math.min(s, 1.1) * 1.9, ctx.rng)
	end, 9)
	scatter(ctx, 4, 9, false, function(p, cf, s)
		pool(p, cf, s, ctx.rng)
	end)
	scatter(ctx, 6, 8, false, function(p, cf, s)
		boulder(p, cf, s * 1.6, ctx.rng, TM.Stone, TM.StoneDark, TM.Moss)
	end)
	scatter(ctx, 5, 6, false, function(p, cf, s)
		orchidPair(p, cf, s * 1.7, ctx.rng)
	end)
	scatter(ctx, 6, 6, false, function(p, cf, s)
		fern(p, cf, s * 1.8, ctx.rng, TM.Fern)
	end)
	scatter(ctx, 7, 6, false, function(p, cf, s)
		broadLeaves(p, cf, s * 1.8, ctx.rng)
	end)
	scatter(ctx, 6, 4, false, function(p, cf, s)
		grassTuft(p, cf, s * 1.8, ctx.rng, TM.Moss, TM.Fern, 2.4)
	end)
	wallGrowth(ctx, 16, Color3.fromRGB(78, 128, 74), Enum.Material.Plastic, true, TM.MossPale, 7, 34)
end

KITS.emberroot = function(ctx, biome)
	scatter(ctx, 8, 14, true, function(p, cf, s)
		charredTree(p, cf, math.min(s, 1.1) * 1.9, ctx.rng)
	end, 6)
	local cracked = 0
	scatter(ctx, 8, 9, false, function(p, cf, s)
		-- Three landmarks glow; the rest are dark. Counted rather than rolled,
		-- so the number of lit seams a biome carries is a decision, not a draw.
		cracked += 1
		basaltOutcrop(p, cf, s * 1.7, ctx.rng, cracked % 3 == 1)
	end)
	scatter(ctx, 6, 6, false, function(p, cf, s)
		emberLilies(p, cf, s * 1.7, ctx.rng)
	end)
	scatter(ctx, 16, 4, false, function(p, cf, s)
		grassTuft(p, cf, s * 1.8, ctx.rng, EM.Ash, EM.Rust, 2.6)
	end)
	groundStreaks(ctx, 8, EM.Ember, Enum.Material.Neon, true)
	-- Thin seams, low on the wall: a fissure, not a doorway.
	wallGrowth(ctx, 10, EM.Ember, Enum.Material.Neon, false, nil, 1.4, 9)
end

KITS.starbloom = function(ctx, biome)
	scatter(ctx, 7, 16, true, function(p, cf, s)
		fanTree(p, cf, math.min(s, 1.1) * 2.0, ctx.rng)
	end, 7)
	scatter(ctx, 6, 8, false, function(p, cf, s)
		boulder(p, cf, s * 1.6, ctx.rng, SB.Rock, SB.RockLight, nil)
	end)
	scatter(ctx, 7, 8, false, function(p, cf, s)
		cupStalks(p, cf, s * 2.3, ctx.rng, 2)
	end)
	scatter(ctx, 8, 5, false, function(p, cf, s)
		spiralFern(p, cf, s * 1.8, ctx.rng)
	end)
	scatter(ctx, 9, 4, false, function(p, cf, s)
		ribbonGrass(p, cf, s * 1.8, ctx.rng)
	end)
	groundStreaks(ctx, 6, Color3.fromRGB(122, 96, 220), Enum.Material.Neon, true)
	wallGrowth(ctx, 14, SB.Vine, Enum.Material.Plastic, true, SB.Lavender, 6, 30)
end

--==============================================================================
-- DRESS A SEGMENT
--==============================================================================
function MapDecor.dressSegment(biome: BiomeData.Biome, model: Model)
	local kit = KITS[biome.Id]
	if not kit then
		-- Not fatal, and worth saying out loud: a new biome with no kit is a
		-- bare corridor, which looks like a bug rather than a missing recipe.
		warn(string.format("[Seed/MapDecor] No kit for biome '%s'. It will be undressed.", biome.Id))
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "Decor"
	folder.Parent = model

	local nearZ, farZ = BiomeData.SegmentBounds(biome)
	local ctx: Ctx = {
		parent = folder,
		rng = Random.new(seedFor(biome.Id)),
		nearZ = nearZ,
		farZ = farZ,
		taken = {},
	}

	-- NESTS are claimed before anything scatters, so no decoration is ever
	-- placed on top of the thing the player is trying to reach -- and the
	-- cradle is built here, in the site's own frame, before the kit runs.
	local cradle = NESTS[biome.Id]
	for _, nestCF in ipairs(BiomeData.NestCFrames(biome)) do
		table.insert(ctx.taken, { x = nestCF.X, z = nestCF.Z, r = NEST_CLEAR })
		if cradle then
			cradle(folder, nestCF, ctx.rng)
		end
	end

	kit(ctx, biome)

	--== SELF-CHECK ==--
	-- Rule 2 is easy to break by adding a prop whose pieces reach further from
	-- its anchor than its declared radius, and impossible to notice by reading.
	-- Checking the parts that were ACTUALLY placed is the only honest test.
	local intruders, parts = 0, 0
	local worst: string? = nil
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
			-- Vertical extent, not Size.Y: a disc lies on its side and a blade
			-- leans, so the size along the world's up is what a runner meets.
			local up = d.CFrame:VectorToObjectSpace(Vector3.yAxis)
			local height = math.abs(d.Size.X * up.X) + math.abs(d.Size.Y * up.Y) + math.abs(d.Size.Z * up.Z)
			if height > 1 and math.abs(d.Position.X) < CENTRE_CLEAR then
				intruders += 1
				worst = string.format("%s at X=%.1f", d.Name, d.Position.X)
			end
		end
	end
	if intruders > 0 then
		warn(string.format(
			"[Seed/MapDecor] %s: %d tall prop part(s) inside the %d-stud racing line (e.g. %s). " ..
			"Raise that prop's scatter radius -- its pieces reach further from its anchor than " ..
			"the radius claims.", biome.Id, intruders, CENTRE_CLEAR, worst or "?"))
	end
	print(string.format("[Seed/MapDecor] %s dressed: %d parts.", biome.Id, parts))
end

--==============================================================================
-- DRESS THE FIELD
--
-- The safe zone is a garden, not a lawn. It is also the first thing anybody
-- sees, and it has to say "plant game" before the player has read one word of
-- UI. It is dressed in Greenhollow's kit, because the road out of it IS
-- Greenhollow and a garden that changed style at the red line would say the
-- road was somewhere else.
--==============================================================================
function MapDecor.dressField(parent: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "FieldDecor"
	folder.Parent = parent

	local rng = Random.new(seedFor("thefield"))
	local halfW = MAP.FieldWidth * 0.5
	local front, back = -MAP.FieldFront, MAP.FieldBack

	-- Hedges down both side edges. They frame the field and, more usefully,
	-- they point: the only gap in them is the road.
	for _, side in ipairs({ -1, 1 }) do
		local z = front + 10
		while z < back - 10 do
			local len = rng:NextNumber(14, 26)
			piece(folder, "Hedge", Vector3.new(6, 7, len),
				CFrame.new(side * (halfW - 5), Y + 3.5, z + len * 0.5),
				Color3.fromRGB(72, 148, 76), STUDDED)
			z += len + rng:NextNumber(2, 7)
		end
	end

	-- Corner trees, well clear of the plots and the run.
	for _, sx in ipairs({ -1, 1 }) do
		for _, z in ipairs({ front + 22, back - 22 }) do
			oak(folder, CFrame.new(sx * (halfW - 24), Y, z) * CFrame.Angles(0, rng:NextNumber(0, TAU), 0), 2.2, rng)
		end
	end

	--== EVERYTHING ELSE GOES OUTSIDE THE RING ==--
	--
	-- On a ring the empty ground is the outer field, and the ground that must
	-- stay empty is everything inside the plot ring: the hub, the walkway
	-- between the hub and the gates, and the plots themselves.
	--
	-- So decoration is placed by RADIUS. Nothing inside the ring's outer reach,
	-- and nothing in the arc the road comes out of -- which is the one direction
	-- a player is looking when they sprint in.
	local outer = GameConfig.Plot.MaxReach + 18
	local roadHalf = RAD(MAP.RoadGapDegrees * 0.5)

	local function outsideTheRing(count: number, place: (CFrame, number) -> ())
		for _ = 1, count do
			for _ = 1, 14 do
				local x = rng:NextNumber(-halfW + 20, halfW - 20)
				local z = rng:NextNumber(front + 20, back - 20)
				local r = math.sqrt(x * x + z * z)
				if r > outer then
					-- Angle from +Z, matching how the plots are placed. Anything
					-- within the road's arc AND north of the ring is in the way.
					local a = math.atan2(x, z)
					local toRoad = math.abs((a - math.pi + math.pi) % TAU - math.pi)
					if toRoad > roadHalf or z > 0 then
						place(CFrame.new(x, Y, z)
							* CFrame.Angles(0, rng:NextNumber(0, TAU), 0),
							rng:NextNumber(0.9, 1.35))
						break
					end
				end
			end
		end
	end

	outsideTheRing(7, function(cf, s2)
		daisyCluster(folder, cf, s2 * 1.6, rng)
	end)
	outsideTheRing(4, function(cf, s2)
		coralBells(folder, cf, s2 * 1.6, rng)
	end)
	outsideTheRing(7, function(cf, s2)
		shrub(folder, cf, s2 * 1.6, rng, GH.LeafDeep, GH.Leaf)
	end)
	outsideTheRing(6, function(cf, s2)
		fern(folder, cf, s2 * 1.7, rng, GH.Fern)
	end)
	outsideTheRing(5, function(cf, s2)
		oak(folder, cf, s2 * 1.9, rng)
	end)
end

return MapDecor
