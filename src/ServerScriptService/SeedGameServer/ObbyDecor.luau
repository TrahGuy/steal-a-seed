--!strict
--==============================================================================
-- Steal a Seed :: ObbyDecor
--
-- The Floating Garden's art (2026-09-27 art pass). ObbyCourse builds what you
-- stand on; this builds everything you only look at. NOT a *Service: ObbyCourse
-- calls it while it builds.
--
--==============================================================================
-- THE SAME WORLD AS THE ROAD
--
-- Every prop is MapDecor's vocabulary -- its approved props (oak, daisies,
-- ferns, boulders, the Starbloom fan trees) and its four sculpting moves --
-- lent out through MapDecor.Kit, so the islands read as the same place the
-- guardians live in. The props below that MapDecor does not have (a flower
-- arch, a pond, reeds, dome mushrooms, a grove trunk, the Bloomheart) are
-- built from the same moves, in the same studded plastic, under the same four
-- rules (MapDecor's header):
--
--   1. NOTHING HERE IS COLLIDABLE, QUERYABLE OR TOUCHABLE. The kit's `piece`
--      makes every part a ghost. What you can stand on is ObbyCourse's, and
--      only ObbyCourse's -- so no flower can catch a foot, a camera or a ray,
--      and no decoration is ever a platform that is not one.
--   2. TALL THINGS STAND OFF THE LINE. The route runs along +X near z = 0;
--      trees, trunks and spires stand well to the side or far below, so the
--      camera behind a runner never meets them. Low things frame the edges.
--   3. DETERMINISTIC. One Random per stage, seeded from its id.
--   4. SCULPTED, NOT STACKED. A mushroom is a stalk, gills, two cap tiers and
--      a crown; an island is a turf top on a soil lip on a torn clod of rock.
--
-- Big shapes frame each view, medium plants ring the island edges, small
-- detail sits by the rest spots -- the brief's order. Glow is spent in three
-- places only: the twilight route's flower pearls, the checkpoint lanterns,
-- and the Bloomheart's heart. Each stage hands a little of its look to the
-- next -- reeds at Sunpetal's end, a mushroom in the grove, amber flowers on
-- the rest island's east edge -- so the chain reads as one garden.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local MapDecor = require(script.Parent:WaitForChild("MapDecor"))

local K = MapDecor.Kit
local P = MapDecor.Props
local GH = MapDecor.Palettes.GH
local TM = MapDecor.Palettes.TM
local SB = MapDecor.Palettes.SB

local piece = K.piece
local group = K.group
local chain = K.chain
local radial = K.radial
local flatWedge = K.flatWedge
local blade = K.blade
local column = K.column
local disc = K.disc
local jitter = K.jitter

local STUDDED = K.Opts.STUDDED
local SMOOTH = K.Opts.SMOOTH
local NEON = K.Opts.NEON
local BALL_SMOOTH = K.Opts.BALL_SMOOTH
local BALL_NEON = K.Opts.BALL_NEON
local CYL_SMOOTH = K.Opts.CYL_SMOOTH
local CYL_STUDDED = K.Opts.CYL_STUDDED

local RAD = math.rad
local TAU = math.pi * 2

local ObbyDecor = {}

-- A decoration the clients bob gently (ObbyUI): the twilight spires.
ObbyDecor.BobTag = ObbyData.Tags.Bob

local CREAM = Color3.fromRGB(250, 242, 214)
local BUTTER = Color3.fromRGB(255, 226, 120)
local GOLD = Color3.fromRGB(250, 200, 70)
local TURQUOISE = Color3.fromRGB(72, 200, 206)
local REED = Color3.fromRGB(110, 150, 70)
local CATTAIL = Color3.fromRGB(118, 78, 48)
local BARK = Color3.fromRGB(122, 84, 54)
local BARK_DARK = Color3.fromRGB(92, 62, 42)
local CORAL = Color3.fromRGB(244, 128, 108)
local ORANGE = Color3.fromRGB(250, 154, 70)
local PINK = Color3.fromRGB(242, 150, 196)
local STALK = Color3.fromRGB(246, 236, 214)
local GILL = Color3.fromRGB(236, 206, 178)
local AMBER = Color3.fromRGB(246, 168, 58)
local RUST = Color3.fromRGB(206, 92, 52)
local SCARLET = Color3.fromRGB(214, 70, 56)
local LANTERN = Color3.fromRGB(255, 214, 140)
local SUMMIT_PINK = Color3.fromRGB(246, 150, 186)

--==============================================================================
-- SMALL HELPERS
--==============================================================================
-- A ground frame at a course-relative point, turned `yaw` degrees.
local function at(x: number, y: number, z: number, yaw: number?): CFrame
	return CFrame.new(ObbyData.world(Vector3.new(x, y, z))) * CFrame.Angles(0, RAD(yaw or 0), 0)
end

-- A block from p0 to p1: how a vine, a root or an arch rib is drawn.
local function beam(parent: Instance, name: string, p0: Vector3, p1: Vector3, thick: number, color: Color3,
	studs: boolean?): BasePart
	local len = (p1 - p0).Magnitude
	return piece(parent, name, Vector3.new(thick, thick, len + thick * 0.35), CFrame.lookAt((p0 + p1) / 2, p1),
		color, if studs then STUDDED else SMOOTH)
end

-- A flower head facing along `face`'s +Y: petals radiating from a centre
-- ball, each tipped up by `cup` degrees. (radial's frame looks outward, and a
-- flat wedge's tip runs along -Z, so each petal points away from the heart.)
local function bloom(parent: Instance, face: CFrame, petals: number, len: number, width: number,
	petal: Color3, heart: Color3, cup: number?)
	for i = 1, petals do
		local a = (i - 1) / petals * TAU
		flatWedge(parent, "Petal", radial(face, a, len * 0.2) * CFrame.Angles(RAD(cup or 12), 0, 0),
			width, 0.22, len, petal, SMOOTH)
	end
	piece(parent, "Heart", Vector3.new(1, 1, 1) * (len * 0.55), face * CFrame.new(0, 0.2, 0), heart, BALL_SMOOTH)
end

--==============================================================================
-- THE ISLAND'S BODY: soil lip, torn rock, hanging roots
--
-- The walkable turf (and its rim lobes) are ObbyCourse's. Below it: a soil
-- band a shade wider than the turf, then rock in three offset tiers, each
-- narrower, with slabs leaning out of the top tier so the silhouette is a torn
-- clod rather than a stack of coins, and a root or three hanging from it.
-- Slab size is capped, so the summit's big island never grows one that breaks
-- back up through its own lawn (the blockout's did).
--==============================================================================
function ObbyDecor.islandBody(parent: Instance, spec: any, pal: ObbyData.Palette, rng: Random)
	local top = ObbyData.world(spec.at)
	local r = spec.radius
	local depth = spec.depth
	column(parent, "Soil", CFrame.new(top - Vector3.new(0, 3.4, 0)), 3.0, r * 2.06, pal.soil, CYL_STUDDED)
	-- Three tiers, each a cluster of rotated blocks rather than one cylinder:
	-- the silhouette is a torn clod from every side, not a stack of coins.
	local y = top.Y - 3.4
	local tiers = { { 0.9, 0.28, 4 }, { 0.66, 0.30, 3 }, { 0.4, 0.30, 3 } }
	local cx, cz = top.X, top.Z
	for i, tier in ipairs(tiers) do
		local h = depth * tier[2]
		local d = r * 2 * tier[1]
		cx += jitter(rng, r * 0.06)
		cz += jitter(rng, r * 0.06)
		local color = if i == 2 then pal.soil:Lerp(pal.rock, 0.55) else pal.rock
		for k = 1, tier[3] do
			local a = (k - 1) / tier[3] * TAU + jitter(rng, RAD(25))
			local off = d * 0.16
			local bh = h * rng:NextNumber(1.0, 1.2)
			piece(parent, "Rock", Vector3.new(d * 0.64, bh, d * 0.58),
				CFrame.new(cx + math.cos(a) * off, y - bh * 0.5 - (if i == 1 then 0.1 else 0), cz + math.sin(a) * off)
					* CFrame.Angles(jitter(rng, RAD(7)), a + jitter(rng, RAD(20)), jitter(rng, RAD(7))),
				if k % 2 == 0 then color else color:Lerp(pal.soil, 0.18), STUDDED)
		end
		y -= h * 0.8
	end
	local slabs = math.clamp(math.floor(r / 3.5), 3, 7)
	local slab = math.min(r * 0.42, 6)
	for i = 1, slabs do
		local a = (i - 1) / slabs * TAU + jitter(rng, RAD(20))
		local d = r * rng:NextNumber(0.62, 0.78)
		local h = slab * rng:NextNumber(1.1, 1.5)
		local cf = CFrame.new(top.X + math.cos(a) * d, top.Y - 3.6 - h * 0.62, top.Z + math.sin(a) * d)
			* CFrame.Angles(0, -a, 0) * CFrame.Angles(RAD(jitter(rng, 10)), 0, RAD(-14 + jitter(rng, 8)))
		piece(parent, "Slab", Vector3.new(slab * 0.8, h, slab * 0.9), cf,
			pal.rock:Lerp(pal.soil, rng:NextNumber(0, 0.35)), STUDDED)
	end
	local roots = math.clamp(math.floor(r / 7), 1, 3)
	for _ = 1, roots do
		local a = rng:NextNumber(0, TAU)
		local from = Vector3.new(top.X + math.cos(a) * r * 0.7, top.Y - 4.5, top.Z + math.sin(a) * r * 0.7)
		local mid = from + Vector3.new(jitter(rng, 1.5), -rng:NextNumber(3, 5), jitter(rng, 1.5))
		local tip = mid + Vector3.new(jitter(rng, 1.5), -rng:NextNumber(2.5, 4), jitter(rng, 1.5))
		beam(parent, "Root", from, mid, 0.7, BARK_DARK)
		beam(parent, "Root", mid, tip, 0.45, BARK_DARK)
	end
end

--==============================================================================
-- THE PROPS MAPDECOR DOES NOT HAVE
--==============================================================================
-- A sun bloom: a tall bent stem, one leaf, six petals round a gold heart.
-- Sunpetal's flower, and in other colours the course's. 10 parts.
local function sunBloom(parent: Instance, cf: CFrame, s: number, rng: Random, petal: Color3?): Model
	local m = group(parent, "SunBloom")
	local tip = chain(m, "Stem", cf * CFrame.Angles(0, rng:NextNumber(0, TAU), 0), 2, 2.4 * s, 0.35 * s, 0.9,
		Vector3.new(RAD(12), 0, 0), GH.Stem, SMOOTH)
	flatWedge(m, "Leaf", cf * CFrame.new(0, 0.9 * s, 0) * CFrame.Angles(0, rng:NextNumber(0, TAU), 0)
		* CFrame.Angles(RAD(24), 0, 0), 0.9 * s, 0.16, 2.0 * s, GH.Fern, SMOOTH)
	bloom(m, tip * CFrame.Angles(RAD(-20), 0, 0), 6, 1.9 * s, 1.0 * s, petal or CREAM, GOLD)
	return m
end

-- The Sunpetal arch: two ribs rising either side of the path and bending to
-- meet overhead, leaves along them, and three big blooms -- one at the crown,
-- one on each shoulder -- all turned toward whoever is about to go through.
-- `cf` stands at the arch's middle on the ground, its -Z along the route.
local function flowerArch(parent: Instance, cf: CFrame, span: number, rise: number, rng: Random): Model
	local m = group(parent, "FlowerArch")
	local half = span / 2
	local steps = 7
	local shoulders = {}
	for _, side in ipairs({ -1, 1 }) do
		local prev = (cf * CFrame.new(side * half, 0, 0)).Position
		for k = 1, steps do
			local t = k / steps * (math.pi / 2)
			local p = (cf * CFrame.new(side * half * math.cos(t), rise * math.sin(t), 0)).Position
			beam(m, "Rib", prev, p, 1.5 - k * 0.1, if k % 2 == 0 then GH.LeafDeep else GH.Stem, true)
			if k == 2 or k == 4 or k == 6 then
				flatWedge(m, "Leaf", CFrame.new(p) * CFrame.Angles(0, rng:NextNumber(0, TAU), 0) * CFrame.Angles(RAD(-30), 0, 0),
					1.4, 0.2, 2.6, if k == 4 then GH.LeafLight else GH.Leaf, SMOOTH)
			end
			if k == 4 then
				table.insert(shoulders, p)
			end
			prev = p
		end
	end
	local back = -cf.LookVector
	local crown = (cf * CFrame.new(0, rise + 0.6, 0)).Position
	bloom(m, CFrame.lookAt(crown, crown + back) * CFrame.Angles(RAD(-90), 0, 0), 8, 3.4, 1.7, CREAM, GOLD)
	for i, p in ipairs(shoulders) do
		local side = if i == 1 then -1 else 1
		local face = CFrame.lookAt(p, p + back + cf.RightVector * side * 0.6) * CFrame.Angles(RAD(-90), 0, 0)
		bloom(m, face * CFrame.new(0, 0.8, 0), 6, 2.4, 1.3, BUTTER, GOLD)
	end
	return m
end

-- Reeds: four thin blades and two cattails on stalks. 8 parts.
local function reeds(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "Reeds")
	for i = 1, 4 do
		local a = (i - 1) / 4 * TAU + jitter(rng, RAD(30))
		blade(m, "Reed", radial(cf, a, 0.3 * s), 0.35 * s, 0.25 * s, rng:NextNumber(4.2, 6.0) * s,
			RAD(rng:NextNumber(6, 16)), if i % 2 == 0 then REED else GH.Fern, SMOOTH)
	end
	for i = 1, 2 do
		local base = radial(cf, (i - 1) * RAD(170) + jitter(rng, RAD(30)), 0.6 * s)
		local h = rng:NextNumber(5.0, 6.6) * s
		piece(m, "Stalk", Vector3.new(0.22 * s, h, 0.22 * s), base * CFrame.new(0, h * 0.5, 0), REED, SMOOTH)
		column(m, "Cattail", base * CFrame.new(0, h - 0.4 * s, 0), 1.4 * s, 0.55 * s, CATTAIL, CYL_SMOOTH)
	end
	return m
end

-- A lotus on its own pad: five pink blades cupped up and a gold core.
local function lotus(parent: Instance, cf: CFrame, s: number): Model
	local m = group(parent, "Lotus")
	disc(m, "Pad", cf, 0.2, 3.4 * s, TM.Pad, CYL_SMOOTH)
	local head = cf * CFrame.new(0, 0.3, 0)
	for k = 1, 5 do
		blade(m, "Petal", radial(head, k / 5 * TAU, 0.35 * s), 0.9 * s, 0.3 * s, 1.5 * s, RAD(-30), TM.Lotus, SMOOTH)
	end
	piece(m, "Core", Vector3.new(0.6, 0.6, 0.6) * s, head * CFrame.new(0, 0.45 * s, 0), TM.LotusCore, BALL_SMOOTH)
	return m
end

-- A pond set into a lawn: turquoise glass a hair above the grass, a rim of
-- flat mossy stones, lily pads and a lotus. Walk-through: never deeper than
-- its own paint, so it cannot trip, slow or float anybody.
local function pond(parent: Instance, cf: CFrame, d: number, rng: Random): Model
	local m = group(parent, "Pond")
	disc(m, "Water", cf * CFrame.new(0, 0.02, 0), 0.14, d, TURQUOISE, { shape = Enum.PartType.Cylinder,
		material = Enum.Material.Glass, transparency = 0.2 })
	for i = 1, 6 do
		local a = (i - 1) / 6 * TAU + jitter(rng, RAD(14))
		piece(m, "Stone", Vector3.new(2.4, 0.5, 1.6) * rng:NextNumber(0.8, 1.2),
			radial(cf, a, d * 0.5) * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, jitter(rng, RAD(30)), 0),
			if i % 2 == 0 then TM.Stone else TM.Moss, STUDDED)
	end
	for i = 1, 2 do
		disc(m, "LilyPad", radial(cf, i * RAD(140), d * 0.24) * CFrame.new(0, 0.18, 0), 0.16, 2.6, TM.Pad, CYL_SMOOTH)
	end
	lotus(m, radial(cf, RAD(40), d * 0.22) * CFrame.new(0, 0.18, 0), 0.9)
	return m
end

-- A dome mushroom -- decorative, and never mistaken for a spring: a round
-- dome in coral, orange or pink with cream spots, on a pale stalk with gills
-- under the rim. A spring cap is flat, teal and ringed in white. 8 parts.
local function mushroom(parent: Instance, cf: CFrame, s: number, cap: Color3, rng: Random): Model
	local m = group(parent, "Mushroom")
	local lean = cf * CFrame.Angles(jitter(rng, RAD(6)), rng:NextNumber(0, TAU), jitter(rng, RAD(6)))
	local h = 3.2 * s
	column(m, "Stalk", lean, h, 1.3 * s, STALK, CYL_SMOOTH)
	local rim = lean * CFrame.new(0, h, 0)
	disc(m, "Gills", rim * CFrame.new(0, -0.35 * s, 0), 0.35 * s, 3.6 * s, GILL, CYL_SMOOTH)
	disc(m, "Cap", rim, 1.0 * s, 4.0 * s, cap, CYL_STUDDED)
	disc(m, "Cap", rim * CFrame.new(0, 0.9 * s, 0), 0.8 * s, 2.9 * s, cap, CYL_STUDDED)
	piece(m, "Crown", Vector3.new(1.9, 1.9, 1.9) * s, rim * CFrame.new(0, 1.8 * s, 0),
		cap:Lerp(Color3.new(1, 1, 1), 0.08), BALL_SMOOTH)
	for i = 1, 3 do
		local a = i / 3 * TAU + jitter(rng, RAD(20))
		disc(m, "Spot", radial(rim * CFrame.new(0, 1.0 * s, 0), a, 1.7 * s), 0.1, 0.8 * s, CREAM, CYL_SMOOTH)
	end
	return m
end

-- A vine hanging from `top`: a bent run of thin segments with a few leaves.
local function hangingVine(parent: Instance, top: Vector3, len: number, rng: Random): Model
	local m = group(parent, "Vine")
	local p = top
	for i = 1, 3 do
		local nextP = p + Vector3.new(jitter(rng, 0.9), -len / 3, jitter(rng, 0.9))
		beam(m, "Vine", p, nextP, 0.4, if i % 2 == 0 then GH.LeafDeep else GH.Fern)
		flatWedge(m, "Leaf", CFrame.new(nextP) * CFrame.Angles(0, rng:NextNumber(0, TAU), 0) * CFrame.Angles(RAD(-35), 0, 0),
			0.8, 0.14, 1.4, GH.Leaf, SMOOTH)
		p = nextP
	end
	return m
end

-- A grove trunk: a thick twisting trunk rising out of its own floating clod,
-- roots trailing below, two branches turned away from the route, and a broad
-- crown high and to the side. The Root Grove's frame.
local function groveTrunk(parent: Instance, cf: CFrame, s: number, rng: Random, crownColors: { Color3 },
	away: number): Model
	local m = group(parent, "GroveTrunk")
	-- The clod it grows from, and roots dangling out of it.
	piece(m, "Clod", Vector3.new(9, 5, 8) * s, cf * CFrame.new(0, -1.5 * s, 0) * CFrame.Angles(0, RAD(20), RAD(6)),
		GH.StoneDark, STUDDED)
	piece(m, "Clod", Vector3.new(6, 5, 6) * s, cf * CFrame.new(0.5 * s, -5 * s, 0) * CFrame.Angles(0, RAD(-15), RAD(-8)),
		GH.Stone, STUDDED)
	for i = 1, 3 do
		local a = (i - 1) / 3 * TAU + jitter(rng, RAD(25))
		local from = (cf * CFrame.new(math.cos(a) * 2 * s, -6 * s, math.sin(a) * 2 * s)).Position
		beam(m, "Root", from, from + Vector3.new(math.cos(a) * 2 * s, -rng:NextNumber(5, 8) * s, math.sin(a) * 2 * s),
			0.9 * s, BARK_DARK, true)
	end
	local top = chain(m, "Trunk", cf * CFrame.Angles(0, 0, jitter(rng, RAD(3))), 5, 6.4 * s, 3.2 * s, 0.86,
		Vector3.new(RAD(4), RAD(22), RAD(-2)), BARK, STUDDED)
	for _, spec in ipairs({ { 0.5, away + RAD(40), RAD(30) }, { 0.78, away - RAD(50), RAD(36) } }) do
		local height = 6.4 * s * 3.5 * spec[1]
		chain(m, "Branch", K.aim(cf * CFrame.new(0, height, 0), spec[2], spec[3]), 2, 4.6 * s, 1.3 * s, 0.7,
			Vector3.new(0, 0, RAD(-10)), BARK_DARK, STUDDED)
	end
	local crown = top * CFrame.new(0, 1.2 * s, 0)
	local masses = {
		{ Vector3.new(15, 5, 13), Vector3.new(0, 0, 0) },
		{ Vector3.new(11, 4.5, 10), Vector3.new(-5.5, 2.4, 3) },
		{ Vector3.new(10, 4, 9), Vector3.new(5.5, 2.8, -2) },
		{ Vector3.new(9, 4, 8), Vector3.new(-2, 1.6, -5.5) },
		{ Vector3.new(8, 3.6, 8), Vector3.new(3, 1.2, 6) },
		{ Vector3.new(7.5, 3.5, 7.5), Vector3.new(1, 4.8, 1.5) },
	}
	for i, mass in ipairs(masses) do
		piece(m, "Crown", mass[1] * s, crown * CFrame.new(mass[2] * s) * CFrame.Angles(0, jitter(rng, RAD(30)), 0),
			crownColors[((i - 1) % #crownColors) + 1], STUDDED)
	end
	return m
end

-- An autumn tree: an oak's build in amber, rust and scarlet. 13 parts.
local function autumnTree(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "AutumnTree")
	local top = chain(m, "Trunk", cf * CFrame.Angles(0, 0, jitter(rng, RAD(4))), 3, 4.2 * s, 2.4 * s, 0.8,
		Vector3.new(jitter(rng, RAD(5)), RAD(30), 0), BARK, STUDDED)
	for i = 1, 4 do
		flatWedge(m, "Root", radial(cf, (i - 1) / 4 * TAU + jitter(rng, RAD(18)), 0.9 * s) * CFrame.new(0, -0.2, 0),
			1.1 * s, 1.5 * s, 2.6 * s, BARK_DARK, STUDDED)
	end
	local crown = top * CFrame.new(0, -0.4 * s, 0)
	local masses = {
		{ Vector3.new(10, 6, 9), Vector3.new(0.4, 1.2, -0.4), AMBER },
		{ Vector3.new(8, 5.4, 8), Vector3.new(-3.4, 3.2, 1.6), RUST },
		{ Vector3.new(7.5, 5, 7), Vector3.new(3.6, 3.8, 2.2), SCARLET },
		{ Vector3.new(6, 4.4, 6), Vector3.new(-0.6, 6, -1.8), AMBER },
		{ Vector3.new(4.6, 3.6, 4.4), Vector3.new(1.4, 8, 0.6), ORANGE },
	}
	for _, mass in ipairs(masses) do
		piece(m, "Crown", mass[1] * s, crown * CFrame.new(mass[2] * s) * CFrame.Angles(0, jitter(rng, RAD(30)), 0),
			mass[3], STUDDED)
	end
	return m
end

-- A checkpoint lantern: a post, a warm lamp and a soft light, so the rest
-- spots still read at night without touching the world's lighting.
local function lanternPost(parent: Instance, cf: CFrame): Model
	local m = group(parent, "Lantern")
	piece(m, "Post", Vector3.new(0.6, 5, 0.6), cf * CFrame.new(0, 2.5, 0), BARK_DARK, STUDDED)
	piece(m, "Arm", Vector3.new(1.8, 0.4, 0.4), cf * CFrame.new(0.7, 4.8, 0), BARK_DARK, SMOOTH)
	local lamp = piece(m, "Lamp", Vector3.new(0.9, 1.1, 0.9), cf * CFrame.new(1.4, 4.1, 0), LANTERN, NEON)
	local light = Instance.new("PointLight")
	light.Color = LANTERN
	light.Range = 18
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = lamp
	return m
end

-- A floating spire: a dark rock hanging in the air, broken top and bottom,
-- with one glowing flower on its crown. The twilight route's silhouette,
-- bobbed gently by every client (ObbyBob).
local function spire(parent: Instance, cf: CFrame, s: number, rng: Random): Model
	local m = group(parent, "Spire")
	-- Atomic: every client moves it whole, so it must never arrive in halves.
	m.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	-- Up: four shards, each narrower, each turned and leaning a little further,
	-- so the top reads as a broken crag. Down: two shards tapering to a point.
	local up = { { Vector3.new(6, 7, 5.4), 0 }, { Vector3.new(4.6, 6, 4), 5.5 }, { Vector3.new(3.2, 5, 2.8), 10 },
		{ Vector3.new(1.8, 4, 1.6), 13.8 } }
	local lean = 0
	for i, b in ipairs(up) do
		lean += RAD(rng:NextNumber(3, 7))
		piece(m, "Crag", b[1] * s, cf * CFrame.new(math.sin(lean) * b[2] * 0.3 * s, b[2] * s, 0)
			* CFrame.Angles(0, rng:NextNumber(0, TAU), lean), if i % 2 == 0 then SB.RockLight else SB.Rock, STUDDED)
	end
	for i, drop in ipairs({ { Vector3.new(4.4, 5, 3.8), -5 }, { Vector3.new(2.2, 4.5, 2), -9 } }) do
		piece(m, "Root", drop[1] * s, cf * CFrame.new(jitter(rng, 0.4) * s, drop[2] * s, jitter(rng, 0.4) * s)
			* CFrame.Angles(jitter(rng, RAD(12)), rng:NextNumber(0, TAU), jitter(rng, RAD(12))),
			if i == 1 then SB.Rock else SB.Indigo, STUDDED)
	end
	-- A tuft of twilight ribbons and one glowing flower on the crag's shoulder.
	local shoulder = cf * CFrame.new(0.6 * s, 9 * s, 0.4 * s)
	for k = 1, 3 do
		blade(m, "Ribbon", radial(shoulder, k / 3 * TAU, 0.4 * s), 0.4 * s, 0.2 * s, 2.4 * s, RAD(30), SB.Lavender, SMOOTH)
	end
	local head = shoulder * CFrame.new(0, 1.6 * s, 0)
	for k = 1, 4 do
		blade(m, "Petal", radial(head, k / 4 * TAU, 0.4 * s), 0.9 * s, 0.25 * s, 1.4 * s, RAD(-24),
			if k % 2 == 0 then SB.CyanPale else SB.Pink, SMOOTH)
	end
	piece(m, "Pearl", Vector3.new(0.8, 0.8, 0.8) * s, head * CFrame.new(0, 0.5 * s, 0), SB.Cyan, BALL_NEON)
	m:SetAttribute("ObbyBobAmp", 0.8 + rng:NextNumber(0, 0.6))
	m:SetAttribute("ObbyBobPeriod", rng:NextNumber(5.5, 8))
	m:SetAttribute("ObbyBobPhase", rng:NextNumber(0, 1))
	CollectionService:AddTag(m, ObbyDecor.BobTag)
	return m
end

-- The Bloomheart: the summit's centrepiece, a flower taller than the
-- pavilion. A thick curving stem, four great leaves, and a head of three
-- petal rings -- summit pink outside, Sunpetal cream, then Autumn amber --
-- round a gold heart that glows softly. It faces back down the course, so it
-- is the thing you run toward.
local function bloomheart(parent: Instance, cf: CFrame, s: number): Model
	local m = group(parent, "Bloomheart")
	local tip = chain(m, "Stem", cf, 4, 6 * s, 2.2 * s, 0.9, Vector3.new(RAD(-5), 0, 0), GH.Stem, STUDDED)
	for i = 1, 4 do
		local a = (i - 1) / 4 * TAU + RAD(45)
		flatWedge(m, "Leaf", radial(cf * CFrame.new(0, (1.5 + i * 1.6) * s, 0), a, 0.8 * s) * CFrame.Angles(RAD(30), 0, 0),
			3.2 * s, 0.4 * s, 7.5 * s, if i % 2 == 0 then GH.LeafLight else GH.Leaf, STUDDED)
	end
	-- A quarter turn so the head looks west (the route comes from -X), then
	-- tipped back so its face is up toward the runner as well as at them.
	local head = tip * CFrame.Angles(0, RAD(90), 0) * CFrame.Angles(RAD(-65), 0, 0)
	local rings = {
		{ 10, 7.5, 3.2, SUMMIT_PINK, 10 },
		{ 8, 5.2, 2.6, CREAM, 18 },
		{ 6, 3.2, 1.8, AMBER, 28 },
	}
	for ring, spec in ipairs(rings) do
		for k = 1, spec[1] do
			local a = (k - 1) / spec[1] * TAU + (ring - 1) * 0.3
			flatWedge(m, "Petal", radial(head * CFrame.new(0, ring * 0.35 * s, 0), a, spec[2] * 0.18 * s)
				* CFrame.Angles(RAD(spec[5]), 0, 0), spec[3] * s, 0.4 * s, spec[2] * s, spec[4], SMOOTH)
		end
	end
	local heart = piece(m, "Heart", Vector3.new(3.4, 3.4, 3.4) * s, head * CFrame.new(0, 1.6 * s, 0), GOLD, BALL_SMOOTH)
	local glow = Instance.new("PointLight")
	glow.Color = BUTTER
	glow.Range = 24
	glow.Brightness = 0.9
	glow.Shadows = false
	glow.Parent = heart
	for k = 1, 5 do
		piece(m, "Stamen", Vector3.new(0.35 * s, 1.9 * s, 0.35 * s), radial(head * CFrame.new(0, 2.6 * s, 0), k / 5 * TAU, 1.0 * s),
			BUTTER, SMOOTH)
	end
	return m
end

-- An invisible host with a few restrained particles over a stage.
local function drift(parent: Instance, name: string, where: CFrame, size: Vector3, colors: { Color3 },
	rate: number, glow: number, speed: NumberRange, lifetime: NumberRange, fall: number)
	local host = piece(parent, name, size, where, Color3.new(1, 1, 1), SMOOTH)
	host.Transparency = 1
	host.CastShadow = false
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	local keys = {}
	for i, c in ipairs(colors) do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), c))
	end
	emitter.Color = ColorSequence.new(keys)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.35) })
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.15),
		NumberSequenceKeypoint.new(0.8, 0.3), NumberSequenceKeypoint.new(1, 1) })
	emitter.Lifetime = lifetime
	emitter.Speed = speed
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -fall, 0)
	emitter.Drag = 1
	emitter.Rate = rate
	emitter.LightEmission = glow
	emitter.RotSpeed = NumberRange.new(-60, 60)
	emitter.Parent = host
end

--==============================================================================
-- THE STAGES
--==============================================================================
local function rngFor(id: string): Random
	return Random.new(K.seedFor("obby:" .. id))
end

local function sunpetal(f: Instance)
	local rng = rngFor("sunpetal")
	local m = group(f, "Decor")
	-- The focal point: a flower arch over the first leap, framing the leaves.
	flowerArch(m, at(13, 0, 0, -90), 18, 15, rng)
	-- A shade oak behind the start and to the side, off the line.
	P.oak(m, at(-14, 0, 16, 30), 1.0, rng)
	for _, spot in ipairs({ { -16, 0, -8 }, { -2, 0, -15 }, { 6, 0, 13 }, { -15, 0, 7 }, { 12, 0, -12 },
		{ 111, 5, -7 } }) do
		sunBloom(m, at(spot[1], spot[2], spot[3]), rng:NextNumber(1.1, 1.5), rng)
	end
	P.daisyCluster(m, at(-6, 0, -11), 0.9, rng)
	P.daisyCluster(m, at(101, 5, 8), 0.8, rng)
	for _, spot in ipairs({ { -18, 0, 0 }, { 4, 0, 16 }, { 16, 0, 9 }, { 98, 5, -5 }, { 114, 5, 6 } }) do
		P.grassTuft(m, at(spot[1], spot[2], spot[3]), 1.2, rng, GH.Leaf, GH.LeafDeep, 2.2)
	end
	P.shrub(m, at(-14, 0, -12), 0.8, rng, GH.LeafDeep, GH.Leaf)
	P.shrub(m, at(104, 5, -8), 0.6, rng, GH.LeafDeep, GH.Leaf)
	-- Toward Lilywater: the far island's east edge starts to grow reeds.
	reeds(m, at(115, 5, -3), 0.8, rng)
end

local function lilywater(f: Instance)
	local rng = rngFor("lilywater")
	local m = group(f, "Decor")
	-- The pond island: water on its north half, off the line of travel.
	pond(m, at(131, 5, 9, 0), 9, rng)
	reeds(m, at(125, 5, 14), 1.0, rng)
	reeds(m, at(138, 5, 14), 0.9, rng)
	reeds(m, at(139, 5, -9), 1.1, rng)
	P.boulder(m, at(124, 5, -8, 20), 0.6, rng, TM.Stone, TM.StoneDark, TM.Moss)
	P.broadLeaves(m, at(130, 5, -11), 1.0, rng)
	P.orchidPair(m, at(143, 5, 9), 0.9, rng)
	-- A thin fall of water off the pond island's north lip, into the sky.
	local lip = ObbyData.world(Vector3.new(131, 3.6, 17))
	for i = 1, 2 do
		local p0 = lip + Vector3.new((i - 1.5) * 2.2, 0, 0.4)
		local fall = piece(m, "Waterfall", Vector3.new(1.6, 14, 0.3), CFrame.new(p0 - Vector3.new(0, 7, 0)), TURQUOISE,
			SMOOTH)
		fall.Material = Enum.Material.Glass
		fall.Transparency = 0.35
	end
	-- The rest platform: a lantern by the checkpoint and a ring of lotus.
	lanternPost(m, at(219, 5, -6, 0))
	lotus(m, at(207, 5, -7), 1.0)
	lotus(m, at(222, 5, 10), 0.9)
	P.boulder(m, at(205, 5, 9, -40), 0.55, rng, TM.Stone, TM.StoneDark, TM.Moss)
	reeds(m, at(226, 5, -2), 0.8, rng)
end

local function rootgrove(f: Instance)
	local rng = rngFor("rootgrove")
	local m = group(f, "Decor")
	local crown = { GH.LeafDeep, GH.Leaf, TM.Leaf, GH.LeafLight }
	-- Two great trunks out of their own clods below the route, one each side,
	-- branches turned away, crowns high and wide of the logs.
	groveTrunk(m, at(254, -14, 32, 0), 1.5, rng, crown, RAD(90))
	groveTrunk(m, at(304, -12, -32, 0), 1.45, rng, crown, RAD(-90))
	-- Vines down from the crowns' inner edges, beside the route, never on it.
	for _, spot in ipairs({ { 256, 26, 19 }, { 264, 27, 17 }, { 272, 26, 18 }, { 294, 28, -18 }, { 303, 27, -17 },
		{ 312, 28, -19 } }) do
		hangingVine(m, ObbyData.world(Vector3.new(spot[1], spot[2], spot[3])), rng:NextNumber(10, 15), rng)
	end
	-- Curling roots off the walkway's edges, low.
	for _, spot in ipairs({ { 238, 5.5, -3, -1 }, { 252, 6.5, 14, 1 }, { 266, 7.5, 11, 1 } }) do
		local base = ObbyData.world(Vector3.new(spot[1], spot[2] - 0.6, spot[3]))
		local p1 = base + Vector3.new(0.8, 2.6, spot[4] * 1.2)
		local p2 = p1 + Vector3.new(1.4, 1.6, spot[4] * 1.6)
		beam(m, "Curl", base, p1, 1.0, BARK, true)
		beam(m, "Curl", p1, p2, 0.7, BARK_DARK, true)
	end
	-- Dappled light: pale warm patches lying on the walk.
	for _, spot in ipairs({ { 211, 5, 8 }, { 246, 6.5, 9 }, { 338, 11, -4 }, { 334, 11, 7 }, { 364, 11, -7 } }) do
		local patch = disc(m, "Dapple", at(spot[1], spot[2] + 0.03, spot[3]), 0.06, rng:NextNumber(2.5, 4.5),
			Color3.fromRGB(255, 240, 170), CYL_SMOOTH)
		patch.Transparency = 0.55
	end
	for _, spot in ipairs({ { 331, 11, -7 }, { 344, 11, 9 }, { 346, 11, -6 }, { 206, 5, -4 }, { 327, 11, 4 },
		{ 340, 11, -9 } }) do
		P.fern(m, at(spot[1], spot[2], spot[3]), rng:NextNumber(1.0, 1.4), rng, if spot[1] > 300 then GH.Fern else TM.Fern)
	end
	P.fallenLog(m, at(332, 11, 9, 70), 0.8, rng)
	-- A first small mushroom: the next stage, arriving.
	mushroom(m, at(346, 11, 8), 0.6, CORAL, rng)
end

local function mushroomSprings(f: Instance)
	local rng = rngFor("mushroom")
	local m = group(f, "Decor")
	-- Round the islands, clear of every spring and every landing.
	for _, spot in ipairs({
		{ 358, 11, 11, 1.1, CORAL }, { 368, 11, 12, 0.8, PINK }, { 356, 11, -7, 0.9, ORANGE },
		{ 372, 11, -9, 1.2, PINK }, { 374, 11, 9, 0.7, ORANGE },
		{ 394, 29, 12, 0.7, CORAL }, { 403, 29, -1, 0.6, PINK },
		{ 424, 45, 4, 0.7, ORANGE }, { 432, 45, -8, 0.6, CORAL },
	}) do
		mushroom(m, at(spot[1], spot[2], spot[3]), spot[4], spot[5], rng)
	end
	P.broadLeaves(m, at(361, 11, -10), 1.6, rng)
	P.broadLeaves(m, at(376, 11, 7), 1.3, rng)
	P.coralBells(m, at(353, 11, 9), 1.0, rng)
	-- The rest island: a giant landmark mushroom on its north edge, and the
	-- split marked in colour -- twilight flowers toward the challenge route
	-- (south), amber toward Autumn Drift (east).
	mushroom(m, at(470, 50, 17), 4.2, CORAL, rng)
	mushroom(m, at(456, 50, 12), 1.4, PINK, rng)
	mushroom(m, at(488, 50, 13), 1.1, ORANGE, rng)
	P.cupStalks(m, at(466, 50, -17), 0.9, rng, 2)
	P.ribbonGrass(m, at(482, 50, -18), 1.0, rng)
	P.spiralFern(m, at(461, 50, -12), 1.0, rng)
	lanternPost(m, at(462, 50, 5, 180))
	for _, spot in ipairs({ { 490, 50, -6 }, { 491, 50, 6 } }) do
		sunBloom(m, at(spot[1], spot[2], spot[3]), 1.2, rng, AMBER)
	end
end

local function autumn(f: Instance)
	local rng = rngFor("autumn")
	local m = group(f, "Decor")
	autumnTree(m, at(607, 57, 9, 20), 0.9, rng)
	P.shrub(m, at(598, 57, -7), 0.7, rng, RUST, AMBER)
	-- Toward the summit: its pink, arriving.
	sunBloom(m, at(612, 57, -5), 1.1, rng, SUMMIT_PINK)
	-- Fallen petals lying flat on the island: tiny, flush, and nothing like the
	-- big floating leaves you jump on.
	for i = 1, 9 do
		local a = rng:NextNumber(0, TAU)
		local d = rng:NextNumber(2, 9)
		piece(m, "Fallen", Vector3.new(0.9, 0.08, 0.6), at(604 + math.cos(a) * d, 57.04, math.sin(a) * d,
			rng:NextNumber(0, 360)), if i % 3 == 0 then SCARLET elseif i % 3 == 1 then AMBER else ORANGE, SMOOTH)
	end
	-- Hanging roots under the drift, well below where anybody lands.
	for _, spot in ipairs({ { 494, 42, 8 }, { 494, 42, -9 }, { 612, 50, -6 } }) do
		local p = ObbyData.world(Vector3.new(spot[1], spot[2], spot[3]))
		local mid = p + Vector3.new(jitter(rng, 1.5), -6, jitter(rng, 1.5))
		beam(m, "HangingRoot", p, mid, 0.8, BARK_DARK)
		beam(m, "HangingRoot", mid, mid + Vector3.new(jitter(rng, 1.5), -5, jitter(rng, 1.5)), 0.5, BARK_DARK)
	end
	-- A slow few leaves drifting down across the stage, amber and rust.
	drift(m, "LeafDrift", at(545, 72, 0), Vector3.new(80, 1, 22), { AMBER, RUST, SCARLET }, 5, 0,
		NumberRange.new(1, 3), NumberRange.new(5, 8), 3)
end

local function summit(f: Instance)
	local rng = rngFor("summit")
	local m = group(f, "Decor")
	bloomheart(m, at(704, 63, 2, 0), 1.0)
	-- Beds of every stage's flowers round the island's edge, clear of paths.
	for i, spot in ipairs({ { 674, 63, 18 }, { 692, 63, 20 }, { 708, 63, -16 }, { 680, 63, -19 } }) do
		sunBloom(m, at(spot[1], spot[2], spot[3]), 1.3, rng, if i % 2 == 0 then SUMMIT_PINK else CREAM)
	end
	P.daisyCluster(m, at(700, 63, 18), 1.0, rng)
	P.coralBells(m, at(712, 63, 12), 1.0, rng)
	lotus(m, at(669, 63, 10), 1.1)
	mushroom(m, at(714, 63, -6), 1.0, PINK, rng)
	P.orchidPair(m, at(694, 63, -21), 1.0, rng)
	P.cupStalks(m, at(688, 63, -23), 0.8, rng, 2)
	drift(m, "PetalDrift", at(700, 90, 2), Vector3.new(30, 1, 30), { SUMMIT_PINK, CREAM, BUTTER }, 4, 0.1,
		NumberRange.new(0.5, 2), NumberRange.new(6, 9), 2)
end

local function challengeA(f: Instance)
	local rng = rngFor("challengeA")
	local m = group(f, "Decor")
	P.fanTree(m, at(478, 52, -130, 30), 0.9, rng)
	P.spiralFern(m, at(468, 52, -127), 1.0, rng)
	P.ribbonGrass(m, at(479, 52, -119), 1.0, rng)
	-- The twilight's dramatic rocks, hanging off both sides of the leaves.
	spire(m, at(446, 38, -60), 1.1, rng)
	spire(m, at(504, 36, -84), 1.0, rng)
	spire(m, at(448, 42, -110), 0.9, rng)
	drift(m, "Fireflies", at(474, 58, -76), Vector3.new(22, 1, 90), { SB.Cyan, SB.Pink }, 3, 1,
		NumberRange.new(0.3, 1.2), NumberRange.new(4, 7), -0.4)
end

local function challengeB(f: Instance)
	local rng = rngFor("challengeB")
	local m = group(f, "Decor")
	P.fanTree(m, at(615, 60, -102, -20), 0.8, rng)
	P.cupStalks(m, at(606, 60, -90), 0.8, rng, 2)
	P.ribbonGrass(m, at(606, 60, -102), 0.9, rng)
	spire(m, at(548, 36, -154), 1.2, rng)
	spire(m, at(600, 42, -132), 1.0, rng)
	spire(m, at(668, 40, -80), 1.1, rng)
	drift(m, "Fireflies", at(560, 64, -114), Vector3.new(60, 1, 24), { SB.Cyan, SB.Lavender }, 3, 1,
		NumberRange.new(0.3, 1.2), NumberRange.new(4, 7), -0.4)
	drift(m, "Fireflies", at(643, 66, -58), Vector3.new(20, 1, 60), { SB.Cyan, SB.Pink }, 2, 1,
		NumberRange.new(0.3, 1.2), NumberRange.new(4, 7), -0.4)
end

local DRESS: { [string]: (Instance) -> () } = {
	sunpetal = sunpetal,
	lilywater = lilywater,
	rootgrove = rootgrove,
	mushroom = mushroomSprings,
	autumn = autumn,
	summit = summit,
	challengeA = challengeA,
	challengeB = challengeB,
}

-- Dresses one stage's folder. A stage nobody wrote art for is left bare
-- rather than failing the build.
function ObbyDecor.dress(stageId: string, folder: Instance)
	local fn = DRESS[stageId]
	if fn then
		fn(folder)
	end
end

--==============================================================================
-- THE ENTRANCE'S FLOWERS AND THE PAVILION'S
--==============================================================================
-- `base` is the arch's frame: local +X across the path, -Z toward the islands.
function ObbyDecor.entrance(parent: Instance, base: CFrame)
	local rng = rngFor("entrance")
	local m = group(parent, "Decor")
	for i, spot in ipairs({ { -8.5, 0, 1 }, { 8.5, 0, 1 }, { -9.5, 0, -2.5 }, { 9.5, 0, -2 } }) do
		sunBloom(m, base * CFrame.new(spot[1], spot[2], spot[3]), 0.9 + (i % 2) * 0.2, rng)
	end
	P.shrub(m, base * CFrame.new(-7.5, 0, 4), 0.6, rng, GH.LeafDeep, GH.Leaf)
	P.shrub(m, base * CFrame.new(7.5, 0, 4), 0.6, rng, GH.LeafDeep, GH.Leaf)
end

function ObbyDecor.pavilion(parent: Instance, center: Vector3)
	local rng = rngFor("pavilion")
	local m = group(parent, "Decor")
	for i = 0, 3 do
		local a = i * math.pi / 2 + math.pi / 4
		local p = center + Vector3.new(math.cos(a) * 7.4, 0, math.sin(a) * 7.4)
		sunBloom(m, CFrame.new(p), 0.8, rng, if i % 2 == 0 then SUMMIT_PINK else CREAM)
	end
end

return ObbyDecor
