--!strict
-- Steal a Seed :: MillModel
--
-- The seven mills, built from parts. NOT a *Service -- no lifecycle, just
-- geometry, same as CreatureModel and ParentModel.
--
--==============================================================================
-- IT IS AN ALLOTMENT, NOT A GYM
--
-- The mill this replaces was a wood slab with a smooth dark belt and grey
-- arrows on it: a treadmill that happened to be in a garden. Every tier here is
-- built out of what Greenhollow is already made of -- planks, packed earth,
-- leaf green, cream porcelain, trellis, moss -- and every surface that is
-- plastic is STUDDED, because Rule 8 is blocky studded plastic and the old belt
-- was the one hero surface in the game that had opted out.
--
-- Deliberately not the reference: no hazard stripes, no chrome, no screen. The
-- reference was read for its LAYOUT -- deck, rails, a sign on a post beside it
-- -- and nothing else.
--
--==============================================================================
-- ONE BUILDER, SEVEN DRESSINGS
--
-- The deck, belt, rollers, rails and chevrons are the same machine at every
-- tier; what climbs is the material, the colour and what is bolted to it. That
-- keeps seven mills in one readable function instead of seven that drift, and
-- it keeps the part count honest -- twenty at the bottom, about thirty-six at
-- the top, on six plots.
--
-- A tier is a LOOK plus a rate, and the rate lives in GameConfig.Mill. Nothing
-- here decides what a mill pays.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local MillModel = {}

local MILL = GameConfig.Mill
local PLOT = GameConfig.Plot

--==============================================================================
-- THE PALETTE
--
-- Greenhollow's own: the plot's planks, the soil the plants grow out of, the
-- leaf and stem greens off the sheet, and the cream that Toadcap and Bellchime
-- are made of. The two premium tiers add gold and a living green, which are the
-- only colours in here that Greenhollow does not already contain -- and they
-- arrive at tier six, where a player has spent twenty-five million to see them.
--==============================================================================
local OAK = Color3.fromRGB(126, 88, 54)
local OAK_DARK = Color3.fromRGB(92, 62, 38)
local EARTH = Color3.fromRGB(124, 76, 50)
local EARTH_DARK = Color3.fromRGB(86, 54, 36)
local LEAF = Color3.fromRGB(86, 150, 66)
local STEM = Color3.fromRGB(124, 182, 92)
local CREAM = Color3.fromRGB(242, 238, 206)
local STONE = Color3.fromRGB(146, 142, 130)
local MOSS = Color3.fromRGB(104, 138, 72)
local GLASS = Color3.fromRGB(206, 232, 226)
local GOLD = Color3.fromRGB(226, 176, 66)
local GOLD_DARK = Color3.fromRGB(160, 116, 34)
local HEART = Color3.fromRGB(150, 226, 150)
local OBSIDIAN = Color3.fromRGB(24, 22, 28)
local MAGMA_CRUST = Color3.fromRGB(44, 26, 24)
local LAVA_ORANGE = Color3.fromRGB(255, 95, 20)
local LAVA_RED = Color3.fromRGB(210, 35, 20)
local BRIMSTONE_YELLOW = Color3.fromRGB(255, 190, 40)
local ALABASTER = Color3.fromRGB(250, 248, 242)
local CELESTIAL_GOLD = Color3.fromRGB(255, 224, 110)
local HOLY_BLUE = Color3.fromRGB(190, 230, 255)
local HALO_WHITE = Color3.fromRGB(255, 255, 255)
local VOID_BLACK = Color3.fromRGB(12, 10, 20)
local NEBULA_PURPLE = Color3.fromRGB(140, 60, 235)
local ASTRAL_CYAN = Color3.fromRGB(60, 220, 255)
local COSMIC_MAGENTA = Color3.fromRGB(240, 50, 160)

export type Dressing = {
	deck: Color3,
	deckMaterial: Enum.Material,
	belt: Color3,
	chevron: Color3,
	rail: Color3,
	railMaterial: Enum.Material,
	roller: Color3,
	-- Treads stay wired and stay at zero. The belt's motion is the arrows, and
	-- what they do is GameConfig.Mill.Belt -- one row per tier, accrued, not a
	-- second set of counts here that can drift from it.
	slats: number,
	-- The console face, which is the one bit of colour a player looks straight
	-- at while standing on the thing.
	console: Color3,
}

--==============================================================================
-- THE EXTRAS USED TO BE FLAGS, AND THAT WAS THE BUG
--
-- This table carried `wheel = true`, `trellis = true`, `glass = true` and the
-- rest, each cumulative, each with exactly ONE builder behind it. Which meant
-- that whatever a wheel looked like, it looked like that on tier 4 and on tier
-- 7 and on everything in between: the top four mills were one machine in four
-- paints, and the paint was the only thing a player could tell apart.
--
-- A boolean can only ever buy you the same object again. So the extras are gone
-- from this table entirely and each tier now has a SIGNATURE -- its own builder,
-- free to put whatever it likes wherever it likes. What survives here is what is
-- genuinely shared: the colours, and the chassis every treadmill needs.
--
-- The cost is that there is no longer one place to add "planters to everything".
-- That is the right cost. Adding one thing to seven mills at once is exactly how
-- seven mills stopped being seven mills.
--==============================================================================

local DRESSING: { Dressing } = {
	-- 1. Compost Walk -- planks and packed earth. What you could build yourself.
	{
		-- EARTH_DARK, not EARTH: the belt and the deck were four RGB points
		-- apart and the mill read as one brown slab with arrows painted on it.
		-- A belt has to look like a separate surface or none of the motion
		-- means anything.
		deck = OAK, deckMaterial = Enum.Material.Wood,
		belt = EARTH_DARK, chevron = CREAM,
		rail = OAK_DARK, railMaterial = Enum.Material.Wood,
		roller = OAK_DARK,
		slats = 0, console = CREAM,
	},
	-- 2. Garden Path -- the belt turns to cut turf and the corners get planters.
	{
		deck = OAK, deckMaterial = Enum.Material.WoodPlanks,
		belt = LEAF, chevron = CREAM,
		rail = OAK_DARK, railMaterial = Enum.Material.Wood,
		roller = OAK_DARK,
		slats = 0, console = LEAF,
	},
	-- 3. Trellis Trot -- an arch over the walker, ivy on it.
	{
		deck = OAK, deckMaterial = Enum.Material.WoodPlanks,
		belt = STEM, chevron = CREAM,
		rail = STEM, railMaterial = Enum.Material.Wood,
		roller = OAK_DARK,
		slats = 0, console = STEM,
	},
	-- 4. Millstone -- the first one that is masonry, with a wheel turning beside
	-- it. This is where a mill stops being furniture.
	{
		deck = STONE, deckMaterial = Enum.Material.Slate,
		belt = EARTH_DARK, chevron = CREAM,
		rail = STONE, railMaterial = Enum.Material.Slate,
		roller = STONE,
		slats = 0, console = MOSS,
	},
	-- 5. Glasshouse -- panels down both sides and a warm lamp. Weather stops
	-- mattering.
	{
		deck = STONE, deckMaterial = Enum.Material.Slate,
		belt = MOSS, chevron = CREAM,
		rail = CREAM, railMaterial = Enum.Material.SmoothPlastic,
		roller = STONE,
		slats = 0, console = GLASS,
	},
	-- 6. Sunwheel -- gilded, with a sun disc turning over the arch.
	{
		deck = OAK_DARK, deckMaterial = Enum.Material.WoodPlanks,
		belt = GOLD_DARK, chevron = GOLD,
		rail = GOLD, railMaterial = Enum.Material.Metal,
		roller = GOLD,
		slats = 0, console = GOLD,
	},
	-- 7. Heartroot -- living wood and spectral rainbow belt.
	{
		deck = HEART, deckMaterial = Enum.Material.Grass,
		belt = LEAF, chevron = HEART,
		rail = HEART, railMaterial = Enum.Material.Grass,
		roller = GOLD,
		slats = 0, console = HEART,
	},
	-- 8. Inferno Forge -- molten liquid lava, volcanic obsidian, and brimstone.
	{
		deck = OBSIDIAN, deckMaterial = Enum.Material.Slate,
		belt = Color3.fromRGB(220, 48, 8), beltMaterial = Enum.Material.Neon,
		chevron = Color3.fromRGB(255, 210, 40),
		rail = OBSIDIAN, railMaterial = Enum.Material.Slate,
		roller = Color3.fromRGB(180, 35, 8),
		slats = 0, console = LAVA_ORANGE,
	},
	-- 9. Celestial Ascent -- pure alabaster, seraphic wings, and divine halo gold.
	{
		deck = ALABASTER, deckMaterial = Enum.Material.SmoothPlastic,
		belt = CELESTIAL_GOLD, chevron = HALO_WHITE,
		rail = CELESTIAL_GOLD, railMaterial = Enum.Material.Metal,
		roller = CELESTIAL_GOLD,
		slats = 0, console = CELESTIAL_GOLD,
	},
	-- 10. Astral Singularity -- void obelisks, gyroscopic astrolabe, and nebula dust.
	{
		deck = VOID_BLACK, deckMaterial = Enum.Material.SmoothPlastic,
		belt = NEBULA_PURPLE, chevron = ASTRAL_CYAN,
		rail = ASTRAL_CYAN, railMaterial = Enum.Material.ForceField,
		roller = VOID_BLACK,
		slats = 0, console = COSMIC_MAGENTA,
	},
}

MillModel.TierCount = #DRESSING

--==============================================================================
-- STUDS ON EVERY SIX FACES, NOT JUST THE TOP
--
-- A mill is seen from every side -- you walk round it to get on -- and the old
-- one had `studs = false` on the belt, which is what made it read as somebody
-- else's asset dropped into the garden.
--==============================================================================
local FACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}

type Opts = {
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	parent: Instance,
	studs: boolean?,
	collide: boolean?,
	transparency: number?,
	shape: Enum.PartType?,
}

--==============================================================================
-- A STUD ONLY RENDERS ON PLASTIC
--
-- This is why the mills came out smooth. Every structural part asked for
-- SurfaceType.Studs and got it -- the property was set, correctly, on all six
-- faces -- and then Wood, WoodPlanks, Slate, Metal, Grass and Ground each drew
-- their own texture straight over the top of it. The surface type survives in
-- the file and never reaches the screen.
--
-- So a part that wants studs IS plastic, and the material argument stops being
-- a free choice. Colour still does all the work of telling oak from stone;
-- Rule 8 is blocky studded plastic, and the mills were the one thing in the
-- game quietly opting out of it while looking like they had not.
--
-- The exceptions are the materials that are an EFFECT rather than a finish --
-- glass you see through, neon that emits, cloth that hangs. Studding those
-- would mean giving up the effect, so they keep their material and lose their
-- studs instead, which is decided here rather than at thirty call sites.
--==============================================================================
local EFFECT_MATERIAL: { [Enum.Material]: boolean } = {
	[Enum.Material.Glass] = true,
	[Enum.Material.Neon] = true,
	[Enum.Material.Fabric] = true,
	[Enum.Material.ForceField] = true,
}

local function part(o: Opts): BasePart
	local p = Instance.new("Part")
	p.Name = o.name
	p.Size = o.size
	p.CFrame = o.cframe
	p.Color = o.color
	p.Anchored = true
	p.CanCollide = if o.collide == nil then true else o.collide
	p.CanQuery = true
	p.Transparency = o.transparency or 0
	if o.shape then
		p.Shape = o.shape
	end
	local studded = if o.studs == nil then true else o.studs
	local material = o.material or Enum.Material.Plastic
	if EFFECT_MATERIAL[material] then
		studded = false
	elseif studded then
		material = Enum.Material.Plastic
	end
	p.Material = material
	local surface = if studded then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	for _, face in ipairs(FACES) do
		(p :: any)[face] = surface
	end
	p.Parent = o.parent
	return p
end

local function cylinder(o: Opts): BasePart
	local p = part(o)
	p.Shape = Enum.PartType.Cylinder
	-- A cylinder's studs land on its flat ends only, which reads as a machined
	-- roller rather than as a brick. Left on deliberately.
	return p
end

--==============================================================================
-- THE DECK, THE BELT AND THE THING THAT MAKES IT LOOK LIKE IT MOVES
--
-- Geometry is identical at every tier. A player who upgrades has to be able to
-- stand in the same place and press the same key; a mill that changed shape
-- under them would be a different mill.
--==============================================================================
local DECK = Vector3.new(11, 1.2, 19)
local BELT = Vector3.new(8, 1.4, 16)
--==============================================================================
-- ARROWS YES, TREADS NO
--
-- The running surface carries chevrons and nothing else. No slats, no paint, no
-- studs -- the arrows and the bare plate they ride on, and that is the whole of
-- it.
--
-- Treads were the wrong instinct: a slat with thickness sells motion on a belt
-- you are looking at side-on, and pays for it by being an opaque bar across the
-- one surface every per-tier effect has to read across. The arrows sell the same
-- motion and leave the plate clear, which is what the ladder needs.
--
-- How many arrows, and what they do once they are moving, is GameConfig.Mill.
-- Belt -- one row per tier. This module reads two columns of it (the count and
-- whether they are neon) and Ambience reads the rest.
--
-- `slats` stays wired for the same reason it always was: turning treads back on
-- should cost a number, not a rewrite.
--==============================================================================

--==============================================================================
-- SEVEN MACHINES, NOT ONE MACHINE IN SEVEN PAINTS
--
-- One function per tier, and each one owns everything a player recognises that
-- mill by: its handrail, its silhouette, the big thing on the side of it.
--
-- The rule these are written to is that NO TWO TIERS SHARE A SHAPE. Not a
-- recoloured one, not a scaled one -- tier 4 has a grinding stone and tier 6 has
-- a sun and neither of them is the other one in a different palette. The old
-- build had a single paddle wheel bolted to tiers 4, 5, 6 and 7, and once you
-- have seen that you cannot unsee that the top half of the game is one machine.
--
-- What they may share is a VOCABULARY -- planks, stone, glass, neon, leaves --
-- because they are all mills in the same allotment. Sharing the language is what
-- keeps them a family. Sharing the parts is what made them quadruplets.
--
-- Each also occupies a different volume, which is what makes them tell apart at
-- a distance where no detail survives: tier 1 is all below waist height, tier 3
-- is a tunnel, tier 4 is a mass on the right, tier 5 is a roof, tier 6 is a disc
-- behind the console, tier 7 is a tree growing out of the left.
--==============================================================================
type Signature = {
	cf: CFrame,
	model: Model,
	deck: BasePart,
	belt: BasePart,
	look: Dressing,
}

--==============================================================================
-- TWO SHAPES WORTH SHARING, BECAUSE THEY ARE GEOMETRY AND NOT DESIGN
--
-- An arc and a hanging line. Both are "how do I make a curve out of boxes",
-- which is a maths answer, not a look -- the tiers that use them use them at
-- different radii, thicknesses, counts and materials, and read as a pergola and
-- as a gilded rib and as a branch.
--==============================================================================
local function arc(
	model: Model, cf: CFrame, z: number, radius: number, baseY: number,
	segments: number, thickness: number, colour: Color3, material: Enum.Material,
	name: string
)
	-- Tangent at angle `a` is (-sin a, cos a), so the segment's own X axis has
	-- to be turned a quarter past `a`. Getting this wrong gives a ring of boxes
	-- all facing the same way, which reads as a fence bent into a circle.
	local step = math.pi / segments
	for i = 1, segments do
		local a = step * (i - 0.5)
		part({
			name = name,
			size = Vector3.new(math.pi * radius / segments * 1.08, thickness, thickness),
			cframe = cf
				* CFrame.new(math.cos(a) * radius, baseY + math.sin(a) * radius, z)
				* CFrame.Angles(0, 0, a + math.pi * 0.5),
			color = colour,
			material = material,
			collide = false,
			parent = model,
		})
	end
end

local function slack(
	model: Model, cf: CFrame, x: number, z1: number, z2: number, y: number,
	sag: number, thickness: number, colour: Color3, material: Enum.Material,
	name: string
): { BasePart }
	-- A rope between two posts in two straight pieces that meet lower in the
	-- middle. Two is the whole trick: one is a bar, three is not any better, and
	-- two is the fewest that stops reading as rigid.
	local made = {}
	local mid = (z1 + z2) * 0.5
	local half = math.abs(z2 - z1) * 0.5
	local drop = math.atan2(sag, half)
	for _, leg in ipairs({ { z1, mid, -1 }, { mid, z2, 1 } }) do
		local piece = part({
			name = name,
			size = Vector3.new(thickness, thickness, math.sqrt(half * half + sag * sag) * 1.04),
			cframe = cf
				* CFrame.new(x, y - sag * 0.5, (leg[1] + leg[2]) * 0.5)
				* CFrame.Angles(drop * leg[3], 0, 0),
			color = colour,
			material = material,
			collide = false,
			parent = model,
		})
		table.insert(made, piece)
	end
	return made
end

--==============================================================================
-- PARTICLES ARE A TIER REWARD, AND THEY ARE GATED ON USE
--
-- Tiers 1 to 3 have none at all. That is deliberate and it is what makes tier 4
-- land: three mills that are only ever wood and paint, and then the first one
-- that is machinery throws something off itself.
--
--   4  stone dust ....... at the grind, and at the chute mouth
--   5  glasshouse air ... vent steam, and warm haze under the roof
--   6  gold ............. sparks off the sun, motes up both flanks
--   7  the whole thing .. a rainbow curtain around the entire mill
--
-- Every one of them carries WhenWorking, so it is off until somebody is on the
-- belt and its rate rides the same eased number the belt's paint does. A mill
-- that threw dust at an empty garden would be a mill that never stops, and the
-- thing a player buys at tier 7 has to be something they can SET OFF.
--
-- The exception is tier 7's pollen, which stays ungated: a Heartroot is alive
-- whether or not anybody is using it, and the aura is the part that answers to
-- being used.
--==============================================================================
local function whenRunning(e: ParticleEmitter)
	e:SetAttribute("WhenWorking", true)
	-- The rate it wants at full tilt. Ambience scales down from this rather than
	-- up from nothing, so the number a designer picked here is the number that
	-- shows when the mill is being driven properly.
	e:SetAttribute("BaseRate", e.Rate)
	e.Enabled = false
end

--==============================================================================
-- AN EMITTER FILLS THE PART IT IS IN, SO THE PART IS THE EFFECT
--
-- Which is the whole reason these are hollow arrangements rather than one big
-- box. Four thin slabs down the sides and ends give a curtain around the mill's
-- EDGES -- particles where the eye reads an outline. A single box the size of
-- the machine would spawn just as many in the middle of it, fogging the belt,
-- the console and the plant you are standing next to.
--==============================================================================
local function shell(model: Model, cf: CFrame, at: Vector3, size: Vector3, name: string): BasePart
	local p = part({
		name = name,
		size = size,
		cframe = cf * CFrame.new(at),
		color = Color3.new(1, 1, 1),
		material = Enum.Material.SmoothPlastic,
		transparency = 1,
		collide = false,
		studs = false,
		parent = model,
	})
	p.CanQuery = false
	p.CastShadow = false
	return p
end

-- Every hue in order, walked once over a particle's life. A ColorSequence does
-- this for free on the GPU -- driving it from a Heartbeat instead would be
-- sixty writes a second per emitter to arrive at the same picture.
local SPECTRUM = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 104, 104)),
	ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 196, 88)),
	ColorSequenceKeypoint.new(0.34, Color3.fromRGB(148, 240, 112)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(94, 226, 226)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(122, 152, 255)),
	ColorSequenceKeypoint.new(0.84, Color3.fromRGB(212, 122, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 112, 190)),
})

--==============================================================================
-- 1. COMPOST WALK -- what you could build yourself in a weekend
--
-- Everything is below waist height and nothing is square to anything else. The
-- silhouette is a heap and a barrow, which is the point: this is the only tier
-- that should look like it was ASSEMBLED rather than bought, and the way you say
-- that in blocky parts is with one rail instead of two and a couple of degrees
-- of lean on everything.
--==============================================================================
local function compostWalk(s: Signature)
	local cf, model, look = s.cf, s.model, s.look

	-- One rail, on one side, slightly off true. Nobody's first treadmill has a
	-- matching pair -- you nail a plank to two posts on the side you fall off.
	for _, spec in ipairs({ { -6.4, 4.6, 3 }, { 2.2, 4.2, -2.5 } }) do
		part({
			name = "RailPost",
			size = Vector3.new(0.5, spec[2], 0.5),
			cframe = cf * CFrame.new(-4.9, spec[2] * 0.5, spec[1])
				* CFrame.Angles(0, 0, math.rad(spec[3])),
			color = look.rail,
			material = look.railMaterial,
			collide = false,
			parent = model,
		})
	end
	part({
		name = "RailPlank",
		size = Vector3.new(0.65, 0.42, 9.8),
		cframe = cf * CFrame.new(-4.95, 4.25, -2.1)
			* CFrame.Angles(math.rad(1.8), 0, math.rad(2)),
		color = look.rail,
		material = look.railMaterial,
		collide = false,
		parent = model,
	})

	--==========================================================================
	-- THE HEAP
	--
	-- A slatted bin with gaps you can see the earth through. The gaps are the
	-- whole reason it is four planks a side instead of one box: a solid crate is
	-- a crate, and a crate with daylight in it is compost.
	--==========================================================================
	local bin = Vector3.new(-8.4, 0, 3.4)
	for _, corner in ipairs({
		Vector3.new(-1.75, 0, -1.75), Vector3.new(1.75, 0, -1.75),
		Vector3.new(-1.75, 0, 1.75), Vector3.new(1.75, 0, 1.75),
	}) do
		part({
			name = "BinPost",
			size = Vector3.new(0.45, 3, 0.45),
			cframe = cf * CFrame.new(bin + corner + Vector3.new(0, 1.5, 0)),
			color = OAK_DARK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
	end
	for _, y in ipairs({ 0.55, 1.5, 2.45 }) do
		for _, side in ipairs({ -1, 1 }) do
			part({
				name = "BinSlat",
				size = Vector3.new(3.9, 0.6, 0.3),
				cframe = cf * CFrame.new(bin + Vector3.new(0, y, side * 1.8)),
				color = OAK,
				material = Enum.Material.Wood,
				collide = false,
				parent = model,
			})
			part({
				name = "BinSlat",
				size = Vector3.new(0.3, 0.6, 3.9),
				cframe = cf * CFrame.new(bin + Vector3.new(side * 1.8, y, 0)),
				color = OAK,
				material = Enum.Material.Wood,
				collide = false,
				parent = model,
			})
		end
	end
	part({
		name = "Compost",
		size = Vector3.new(3.3, 0.7, 3.3),
		cframe = cf * CFrame.new(bin + Vector3.new(0, 2.3, 0)),
		color = EARTH_DARK,
		material = Enum.Material.Ground,
		collide = false,
		parent = model,
	})
	-- Peelings on top, because a heap of flat brown is a box of soil.
	for _, spot in ipairs({
		Vector3.new(-0.8, 2.75, 0.5), Vector3.new(0.6, 2.8, -0.7),
		Vector3.new(0.9, 2.72, 0.9),
	}) do
		part({
			name = "Scrap",
			size = Vector3.new(0.8, 0.25, 0.6),
			cframe = cf * CFrame.new(bin + spot) * CFrame.Angles(0, math.rad(24), 0),
			color = MOSS,
			material = Enum.Material.Grass,
			collide = false,
			parent = model,
		})
	end
	-- A fork left standing in it. Left, not stored: this mill is mid-job.
	part({
		name = "ForkShaft",
		size = Vector3.new(0.22, 4.2, 0.22),
		cframe = cf * CFrame.new(bin + Vector3.new(1, 3.9, -0.6))
			* CFrame.Angles(math.rad(9), 0, math.rad(-13)),
		color = OAK,
		material = Enum.Material.Wood,
		collide = false,
		parent = model,
	})
	for _, dx in ipairs({ -0.35, 0, 0.35 }) do
		part({
			name = "ForkTine",
			size = Vector3.new(0.12, 1, 0.12),
			cframe = cf * CFrame.new(bin + Vector3.new(1.45 + dx * 0.9, 2.3, -0.45))
				* CFrame.Angles(math.rad(9), 0, math.rad(-13)),
			color = STONE,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
	end

	--==========================================================================
	-- THE BARROW
	--
	-- Parked, tipped forward on its nose the way one is when it is empty. One
	-- wheel, two handles, two legs -- and the tip is what makes those five parts
	-- read as a barrow instead of a box with sticks.
	--==========================================================================
	local barrow = Vector3.new(7.9, 0, 2.8)
	local tip = CFrame.Angles(math.rad(-19), 0, 0)
	part({
		name = "BarrowTray",
		size = Vector3.new(1.75, 0.95, 2.4),
		cframe = cf * CFrame.new(barrow + Vector3.new(0, 1.5, 0.1)) * tip,
		color = Color3.fromRGB(122, 138, 112),
		material = Enum.Material.Metal,
		collide = false,
		parent = model,
	})
	-- The nose. A barrow is a box that narrows to the wheel, and without this
	-- the whole prop is a bin someone left a wheel behind.
	part({
		name = "BarrowNose",
		size = Vector3.new(1.1, 0.7, 1),
		cframe = cf * CFrame.new(barrow + Vector3.new(0, 1.05, -1.25)) * tip,
		color = Color3.fromRGB(110, 126, 100),
		material = Enum.Material.Metal,
		collide = false,
		parent = model,
	})
	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "BarrowHandle",
			size = Vector3.new(0.2, 0.2, 3),
			cframe = cf * CFrame.new(barrow + Vector3.new(side * 0.8, 2.05, 2.6))
				* CFrame.Angles(math.rad(13), 0, 0),
			color = OAK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
		part({
			name = "BarrowLeg",
			size = Vector3.new(0.2, 1.5, 0.2),
			cframe = cf * CFrame.new(barrow + Vector3.new(side * 0.75, 0.75, 1.7)),
			color = STONE,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
	end
	-- Out in front of the tray where it can be SEEN, not tucked under it.
	cylinder({
		name = "BarrowWheel",
		size = Vector3.new(0.34, 1.7, 1.7),
		cframe = cf * CFrame.new(barrow + Vector3.new(0, 0.85, -2.3)),
		color = EARTH_DARK,
		material = Enum.Material.SmoothPlastic,
		collide = false,
		parent = model,
	})
	cylinder({
		name = "BarrowHub",
		size = Vector3.new(0.4, 0.6, 0.6),
		cframe = cf * CFrame.new(barrow + Vector3.new(0, 0.85, -2.3)),
		color = STONE,
		material = Enum.Material.Metal,
		collide = false,
		parent = model,
	})

	-- The sack and the trowel that were always here. They belong to this tier
	-- and only this one now.
	part({
		name = "SackBody",
		size = Vector3.new(1.6, 2, 1.4),
		cframe = cf * CFrame.new(-6.6, 1, -5.6) * CFrame.Angles(0, math.rad(14), math.rad(7)),
		color = Color3.fromRGB(176, 158, 116),
		material = Enum.Material.Fabric,
		collide = false,
		parent = model,
	})
	part({
		name = "SackNeck",
		size = Vector3.new(0.9, 0.5, 0.9),
		cframe = cf * CFrame.new(-6.5, 2.2, -5.6),
		color = Color3.fromRGB(150, 132, 94),
		material = Enum.Material.Fabric,
		collide = false,
		parent = model,
	})
end

--==============================================================================
-- 2. GARDEN PATH -- somebody tidied it
--
-- Still low, still wood, and now everything lines up. The whole tier is the
-- difference between a heap and an edge: a picket run down both sides, brick
-- kerbs, stones laid to the step, trays in rows. Nothing here is taller than
-- tier 1 -- it is better KEPT, not bigger, which is the only honest thing a
-- ten-thousand upgrade buys.
--==============================================================================
local function gardenPath(s: Signature)
	local cf, model, look = s.cf, s.model, s.look

	--==========================================================================
	-- A PICKET RUN, WHICH IS A RAIL THAT HAS BEEN CARED ABOUT
	--==========================================================================
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -8, -5.4, -2.8, -0.2, 2.4, 5, 7.6 }) do
			part({
				name = "Picket",
				size = Vector3.new(0.32, 2.3, 0.46),
				cframe = cf * CFrame.new(side * 5.15, 1.55, z),
				color = look.rail,
				material = look.railMaterial,
				collide = false,
				parent = model,
			})
			-- A diamond on top: the cheapest point a box can be given, and the
			-- thing that stops a picket fence reading as a row of sticks.
			part({
				name = "PicketCap",
				size = Vector3.new(0.34, 0.42, 0.42),
				cframe = cf * CFrame.new(side * 5.15, 2.85, z)
					* CFrame.Angles(math.rad(45), 0, 0),
				color = look.rail,
				material = look.railMaterial,
				collide = false,
				parent = model,
			})
		end
		for _, y in ipairs({ 1.1, 2.2 }) do
			part({
				name = "PicketRail",
				size = Vector3.new(0.24, 0.3, 16.4),
				cframe = cf * CFrame.new(side * 5.15, y, -0.2),
				color = look.rail,
				material = look.railMaterial,
				collide = false,
				parent = model,
			})
		end
	end

	-- Brick kerbs down the deck edges, alternating so the courses read.
	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 9 do
			part({
				name = "Kerb",
				size = Vector3.new(0.7, 0.5, 1.8),
				cframe = cf * CFrame.new(side * 5.15, 0.85, -8.6 + i * 1.9),
				color = if i % 2 == 0
					then Color3.fromRGB(178, 106, 84)
					else Color3.fromRGB(160, 92, 72),
				material = Enum.Material.SmoothPlastic,
				collide = false,
				parent = model,
			})
		end
	end

	-- Stones laid up to the step, drifting off the centreline the way laid
	-- stones do.
	for i, spot in ipairs({
		Vector3.new(-0.4, 0, 12.2), Vector3.new(0.7, 0, 14.1), Vector3.new(-0.5, 0, 16),
	}) do
		cylinder({
			name = "SteppingStone",
			size = Vector3.new(0.35, 2.6, 2.6),
			cframe = cf * CFrame.new(spot + Vector3.new(0, 0.15, 0))
				* CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(0, math.rad(i * 23), 0),
			color = STONE,
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = model,
		})
	end

	--==========================================================================
	-- A POTTING BENCH, WHICH IS WHERE THE NEXT CROP COMES FROM
	--==========================================================================
	local bench = Vector3.new(-8.2, 0, -1)
	part({
		name = "BenchTop",
		size = Vector3.new(2.6, 0.3, 5),
		cframe = cf * CFrame.new(bench + Vector3.new(0, 2.1, 0)),
		color = OAK,
		material = Enum.Material.WoodPlanks,
		collide = false,
		parent = model,
	})
	for _, corner in ipairs({
		Vector3.new(-1, 0, -2.2), Vector3.new(1, 0, -2.2),
		Vector3.new(-1, 0, 2.2), Vector3.new(1, 0, 2.2),
	}) do
		part({
			name = "BenchLeg",
			size = Vector3.new(0.3, 2.1, 0.3),
			cframe = cf * CFrame.new(bench + corner + Vector3.new(0, 1.05, 0)),
			color = OAK_DARK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
	end
	for _, z in ipairs({ -1.5, 0, 1.5 }) do
		part({
			name = "SeedTray",
			size = Vector3.new(1.9, 0.4, 1.2),
			cframe = cf * CFrame.new(bench + Vector3.new(0, 2.45, z)),
			color = EARTH_DARK,
			material = Enum.Material.Ground,
			collide = false,
			parent = model,
		})
		for _, dx in ipairs({ -0.55, 0, 0.55 }) do
			part({
				name = "Seedling",
				size = Vector3.new(0.22, 0.6, 0.22),
				cframe = cf * CFrame.new(bench + Vector3.new(dx, 2.9, z))
					* CFrame.Angles(math.rad(6), 0, math.rad(dx * 12)),
				color = STEM,
				material = Enum.Material.Grass,
				collide = false,
				parent = model,
			})
		end
	end

	--==========================================================================
	-- A WATERING CAN, AND A PINWHEEL THAT ACTUALLY TURNS
	--
	-- The pinwheel is the one moving thing on this tier. It rides the belt tag
	-- like every other spinner, which means it slows to a crawl when nobody is
	-- training -- a toy in a garden with nobody in it.
	--==========================================================================
	local can = Vector3.new(7.5, 0, -3.6)
	local tin = Color3.fromRGB(126, 156, 148)
	cylinder({
		name = "CanBody",
		size = Vector3.new(1.45, 1.35, 1.35),
		cframe = cf * CFrame.new(can + Vector3.new(0, 0.72, 0))
			* CFrame.Angles(0, 0, math.rad(90)),
		color = tin,
		material = Enum.Material.Metal,
		collide = false,
		parent = model,
	})
	part({
		name = "CanSpout",
		size = Vector3.new(0.24, 0.24, 1.5),
		cframe = cf * CFrame.new(can + Vector3.new(0, 1.02, -1))
			* CFrame.Angles(math.rad(-20), 0, 0),
		color = tin,
		material = Enum.Material.Metal,
		collide = false,
		parent = model,
	})
	cylinder({
		name = "CanRose",
		size = Vector3.new(0.22, 0.62, 0.62),
		cframe = cf * CFrame.new(can + Vector3.new(0, 1.3, -1.65))
			* CFrame.Angles(0, 0, math.rad(90)) * CFrame.Angles(math.rad(70), 0, 0),
		color = tin,
		material = Enum.Material.Metal,
		collide = false,
		parent = model,
	})
	-- A handle over the top in three pieces, because a straight bar floating
	-- above a cylinder is not a handle, it is a bar floating above a cylinder.
	for _, hoop in ipairs({ { 0.55, 1.5, 0 }, { 0, 1.72, 0.42 }, { -0.55, 1.5, 0 } }) do
		part({
			name = "CanHandle",
			size = Vector3.new(0.18, 0.6, 0.18),
			cframe = cf * CFrame.new(can + Vector3.new(0, hoop[2], hoop[1]))
				* CFrame.Angles(math.rad(hoop[1] * 62 + hoop[3] * 90), 0, 0),
			color = tin,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
	end

	part({
		name = "PinwheelPost",
		size = Vector3.new(0.26, 5, 0.26),
		cframe = cf * CFrame.new(6.6, 2.5, 6.4),
		color = OAK,
		material = Enum.Material.Wood,
		collide = false,
		parent = model,
	})
	local hub = cylinder({
		name = "Pinwheel",
		size = Vector3.new(0.3, 0.6, 0.6),
		cframe = cf * CFrame.new(6.6, 5.1, 6.4),
		color = OAK_DARK,
		material = Enum.Material.SmoothPlastic,
		collide = false,
		parent = model,
	})
	CollectionService:AddTag(hub, GameConfig.Tags.MillWheel)
	for i = 1, 4 do
		local a = (i / 4) * math.pi * 2
		part({
			name = "PinwheelVane",
			size = Vector3.new(0.14, 1.5, 0.9),
			cframe = cf * CFrame.new(6.6, 5.1, 6.4) * CFrame.Angles(a, 0, 0)
				* CFrame.new(0, 0.95, 0) * CFrame.Angles(0, 0, math.rad(18)),
			color = if i % 2 == 0
				then Color3.fromRGB(240, 150, 168)
				else CREAM,
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = hub,
		})
	end

	-- Corner planters. Tier 2 is the tier that starts growing things ON the
	-- machine, which is why they arrive here and not earlier.
	for _, corner in ipairs({ Vector3.new(-4.6, 0, 8.4), Vector3.new(4.6, 0, 8.4) }) do
		part({
			name = "Planter",
			size = Vector3.new(1.9, 1.5, 1.9),
			cframe = cf * CFrame.new(corner + Vector3.new(0, 1.35, 0)),
			color = OAK_DARK,
			material = Enum.Material.WoodPlanks,
			collide = false,
			parent = model,
		})
		part({
			name = "PlanterSoil",
			size = Vector3.new(1.6, 0.4, 1.6),
			cframe = cf * CFrame.new(corner + Vector3.new(0, 2.1, 0)),
			color = EARTH,
			material = Enum.Material.Ground,
			collide = false,
			parent = model,
		})
		part({
			name = "BloomCentre",
			size = Vector3.new(0.5, 0.5, 0.5),
			cframe = cf * CFrame.new(corner + Vector3.new(0, 2.9, 0)),
			color = CREAM,
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = model,
		})
		for i = 1, 4 do
			local a = (i / 4) * math.pi * 2
			part({
				name = "Petal",
				size = Vector3.new(0.55, 0.2, 0.55),
				cframe = cf * CFrame.new(corner + Vector3.new(0, 2.9, 0))
					* CFrame.Angles(0, a, 0) * CFrame.new(0, 0, -0.45),
				color = Color3.fromRGB(240, 150, 168),
				material = Enum.Material.SmoothPlastic,
				collide = false,
				parent = model,
			})
		end
	end
end

--==============================================================================
-- 3. TRELLIS TROT -- it grew a roof
--
-- The first tier with anything ABOVE the walker, and that is the entire upgrade:
-- you buy a tunnel. Four ribs arching the full width, stringers tying them, and
-- enough ivy on it to say the garden got there first.
--
-- The rail stops being carpentry and becomes rope, which is the other half of
-- the read -- tier 2 was tidy, tier 3 is overgrown, and rope sags where a picket
-- cannot.
--==============================================================================
local function trellisTrot(s: Signature)
	local cf, model, look = s.cf, s.model, s.look

	--== 1. ROPE HANDRAILS ==--
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -7.6, -1.2, 5.2 }) do
			part({
				name = "RopePost",
				size = Vector3.new(0.44, 3.6, 0.44),
				cframe = cf * CFrame.new(side * 5.1, 2.2, z),
				color = look.rail,
				material = look.railMaterial,
				collide = false,
				parent = model,
			})
		end
		for _, span in ipairs({ { -7.6, -1.2 }, { -1.2, 5.2 } }) do
			slack(model, cf, side * 5.1, span[1], span[2], 3.6, 0.8, 0.19,
				Color3.fromRGB(146, 122, 82), Enum.Material.Fabric, "Rope")
		end
	end

	--== 2. OPEN SIDE TRELLIS LATTICE SCREENS (FLANKS ONLY, NO OVERHEAD ROOF) ==--
	for _, side in ipairs({ -1, 1 }) do
		-- Upright trellis posts
		for _, z in ipairs({ -7.4, -2.6, 2.2, 7.0 }) do
			part({
				name = "TrellisPost",
				size = Vector3.new(0.45, 4.4, 0.45),
				cframe = cf * CFrame.new(side * 5.5, 2.6, z),
				color = OAK_DARK,
				material = Enum.Material.WoodPlanks,
				collide = false,
				parent = model,
			})
			-- Post finial cap
			part({
				name = "PostCap",
				size = Vector3.new(0.65, 0.4, 0.65),
				cframe = cf * CFrame.new(side * 5.5, 4.9, z),
				color = OAK,
				material = Enum.Material.WoodPlanks,
				collide = false,
				parent = model,
			})
		end

		-- Horizontal top and bottom guide rails along flank
		part({
			name = "TrellisTopRail",
			size = Vector3.new(0.35, 0.35, 15.2),
			cframe = cf * CFrame.new(side * 5.5, 4.6, -0.2),
			color = OAK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
		part({
			name = "TrellisBottomRail",
			size = Vector3.new(0.35, 0.35, 15.2),
			cframe = cf * CFrame.new(side * 5.5, 1.2, -0.2),
			color = OAK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})

		-- Diagonal lattice cross-slats forming open garden mesh
		for i = 0, 6 do
			local zCenter = -6.5 + i * 2.1
			part({
				name = "LatticeSlatA",
				size = Vector3.new(0.18, 3.8, 0.22),
				cframe = cf * CFrame.new(side * 5.5, 2.9, zCenter) * CFrame.Angles(math.rad(35), 0, 0),
				color = OAK_DARK,
				material = Enum.Material.Wood,
				collide = false,
				parent = model,
			})
			part({
				name = "LatticeSlatB",
				size = Vector3.new(0.18, 3.8, 0.22),
				cframe = cf * CFrame.new(side * 5.5, 2.9, zCenter) * CFrame.Angles(math.rad(-35), 0, 0),
				color = OAK_DARK,
				material = Enum.Material.Wood,
				collide = false,
				parent = model,
			})
		end
	end

	--== 3. CLIMBING IVY & FOLIAGE ON FLANK SCREENS ==--
	for _, side in ipairs({ -1, 1 }) do
		for _, z in ipairs({ -6.0, -1.5, 3.5 }) do
			local vine = part({
				name = "Ivy",
				size = Vector3.new(0.5, 2.2, 1.4),
				cframe = cf * CFrame.new(side * 5.4, 2.8, z)
					* CFrame.Angles(0, math.rad(side * 12), math.rad(side * 6)),
				color = LEAF,
				material = Enum.Material.Grass,
				collide = false,
				parent = model,
			})
			vine:SetAttribute("SwaySide", side)
			CollectionService:AddTag(vine, GameConfig.Tags.MillBanner)
		end

		for i = 1, 3 do
			part({
				name = "Climber",
				size = Vector3.new(0.7, 0.7, 0.7),
				cframe = cf * CFrame.new(side * 5.3, 0.9 + i * 0.9, -7.4)
					* CFrame.Angles(0, math.rad(i * 40), 0),
				color = STEM,
				material = Enum.Material.Grass,
				collide = false,
				parent = model,
			})
		end
	end

	--== 4. LONG PLANTER TROUGHS ALONG OUTER FLANKS ==--
	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "Trough",
			size = Vector3.new(1.5, 1.1, 8.4),
			cframe = cf * CFrame.new(side * 6.8, 0.55, 2.6),
			color = OAK_DARK,
			material = Enum.Material.WoodPlanks,
			collide = false,
			parent = model,
		})
		part({
			name = "TroughSoil",
			size = Vector3.new(1.2, 0.3, 8.0),
			cframe = cf * CFrame.new(side * 6.8, 1.2, 2.6),
			color = EARTH,
			material = Enum.Material.Ground,
			collide = false,
			parent = model,
		})
		for i = 0, 4 do
			part({
				name = "Sprig",
				size = Vector3.new(0.8, 1.2, 0.8),
				cframe = cf * CFrame.new(side * 6.8, 1.8, -0.6 + i * 1.6)
					* CFrame.Angles(0, math.rad(i * 30), 0),
				color = if i % 2 == 0 then LEAF else STEM,
				material = Enum.Material.Grass,
				collide = false,
				parent = model,
			})
		end
	end
end

--==============================================================================
local function millstone(s: Signature)
	local cf, model, look = s.cf, s.model, s.look

	-- Stone kerb and iron pipe. Everything a hand touches on this tier is
	-- metal and everything it stands on is rock.
	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 7 do
			part({
				name = "Kerb",
				size = Vector3.new(0.9, if i % 2 == 0 then 0.7 else 0.55, 2.3),
				cframe = cf * CFrame.new(side * 5.1, 0.95, -8.4 + i * 2.4),
				color = STONE,
				material = Enum.Material.Slate,
				collide = false,
				parent = model,
			})
		end
		for _, z in ipairs({ -7.4, -2.5, 2.4, 7.3 }) do
			cylinder({
				name = "Stanchion",
				size = Vector3.new(2.9, 0.34, 0.34),
				cframe = cf * CFrame.new(side * 5.1, 2.7, z)
					* CFrame.Angles(0, 0, math.rad(90)),
				color = look.rail,
				material = Enum.Material.Metal,
				collide = false,
				parent = model,
			})
		end
		cylinder({
			name = "PipeRail",
			size = Vector3.new(15.6, 0.36, 0.36),
			cframe = cf * CFrame.new(side * 5.1, 4.1, -0.05)
				* CFrame.Angles(0, math.rad(90), 0),
			color = look.rail,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
	end

	--==========================================================================
	-- THE STONE
	--
	-- Sat on the mill's own axis so it turns with the belt rather than beside
	-- it. Its ridges are parented to the disc, which is what makes it read as
	-- one turning object instead of a disc with a ring of blocks near it.
	--==========================================================================
	local hubAt = CFrame.new(8.4, 4.6, 0)
	local stone = cylinder({
		name = "Millstone",
		size = Vector3.new(1.7, 8.2, 8.2),
		cframe = cf * hubAt,
		color = STONE,
		material = Enum.Material.Slate,
		collide = false,
		parent = model,
	})
	CollectionService:AddTag(stone, GameConfig.Tags.MillWheel)
	for i = 1, 12 do
		local a = (i / 12) * math.pi * 2
		part({
			name = "Ridge",
			size = Vector3.new(0.45, 1.5, 0.55),
			cframe = cf * hubAt * CFrame.Angles(a, 0, 0) * CFrame.new(0.9, 3.2, 0),
			color = STONE:Lerp(Color3.new(0, 0, 0), 0.22),
			material = Enum.Material.Slate,
			collide = false,
			parent = stone,
		})
	end
	part({
		name = "Pier",
		size = Vector3.new(2, 5, 2),
		cframe = cf * CFrame.new(6.2, 2.5, 0),
		color = STONE,
		material = Enum.Material.Slate,
		collide = false,
		parent = model,
	})
	cylinder({
		name = "Axle",
		size = Vector3.new(3.4, 0.85, 0.85),
		cframe = cf * CFrame.new(7.1, 4.6, 0),
		color = OAK_DARK,
		material = Enum.Material.Wood,
		collide = false,
		parent = model,
	})

	--==========================================================================
	-- THE GANTRY AND THE HOPPER
	--
	-- The answer to "what is it grinding". A stone with nothing feeding it is a
	-- wheel; a stone with a chute over it is a mill.
	--==========================================================================
	for _, z in ipairs({ -1.9, 1.9 }) do
		part({
			name = "GantryPost",
			size = Vector3.new(0.55, 10.6, 0.55),
			cframe = cf * CFrame.new(6.4, 5.3, z),
			color = OAK_DARK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
	end
	part({
		name = "GantryBeam",
		size = Vector3.new(4.6, 0.55, 0.55),
		cframe = cf * CFrame.new(8.2, 10.9, 0),
		color = OAK_DARK,
		material = Enum.Material.Wood,
		collide = false,
		parent = model,
	})
	part({
		name = "Hopper",
		size = Vector3.new(3.2, 2.2, 3.2),
		cframe = cf * CFrame.new(8.4, 9.5, 0),
		color = OAK,
		material = Enum.Material.WoodPlanks,
		collide = false,
		parent = model,
	})
	part({
		name = "HopperThroat",
		size = Vector3.new(1.7, 1.3, 1.7),
		cframe = cf * CFrame.new(8.4, 8.1, 0),
		color = OAK_DARK,
		material = Enum.Material.Wood,
		collide = false,
		parent = model,
	})
	part({
		name = "Chute",
		size = Vector3.new(1.1, 0.3, 2.4),
		cframe = cf * CFrame.new(8.4, 7.4, -0.9) * CFrame.Angles(math.rad(34), 0, 0),
		color = OAK,
		material = Enum.Material.Wood,
		collide = false,
		parent = model,
	})
	-- Grain in the hopper, and dust where it lands.
	part({
		name = "Grain",
		size = Vector3.new(2.9, 0.4, 2.9),
		cframe = cf * CFrame.new(8.4, 10.5, 0),
		color = Color3.fromRGB(216, 188, 128),
		material = Enum.Material.Ground,
		collide = false,
		parent = model,
	})

	--==========================================================================
	-- THE GEAR TRAIN
	--
	-- Two of them, and the client turns the second the other way at its own
	-- ratio. Everything on the lower tiers span the same direction, which reads
	-- as decoration; a pair meshing reads as drive.
	--==========================================================================
	for index, spec in ipairs({ { 2, 2.9 }, { 3.9, 1.9 } }) do
		local gear = cylinder({
			name = "Gear",
			size = Vector3.new(0.6, spec[2], spec[2]),
			cframe = cf * CFrame.new(-6.6, spec[1], -4.6),
			color = STONE,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
		gear:SetAttribute("GearIndex", index)
		CollectionService:AddTag(gear, GameConfig.Tags.MillGear)
		for i = 1, 8 do
			local a = (i / 8) * math.pi * 2
			part({
				name = "Tooth",
				size = Vector3.new(0.5, 0.5, 0.4),
				cframe = cf * CFrame.new(-6.6, spec[1], -4.6)
					* CFrame.Angles(a, 0, 0) * CFrame.new(0, spec[2] * 0.5 + 0.15, 0),
				color = STONE:Lerp(Color3.new(0, 0, 0), 0.25),
				material = Enum.Material.Metal,
				collide = false,
				parent = gear,
			})
		end
	end
	local crank = part({
		name = "Crank",
		size = Vector3.new(0.4, 2.4, 0.4),
		cframe = cf * CFrame.new(-6.6, 2, 3.4),
		color = OAK_DARK,
		material = Enum.Material.Wood,
		collide = false,
		parent = model,
	})
	CollectionService:AddTag(crank, GameConfig.Tags.MillCrank)

	--==========================================================================
	-- THE FIRST PARTICLES IN THE GAME'S MILLS
	--
	-- Grit where the stone meets the bed, and finer stuff falling out of the
	-- chute. Two emitters and not one, because a mill that only smoked at the
	-- top would be a chimney and a mill that only smoked at the bottom would be
	-- a fire -- it is the pair, at both ends of the same process, that reads as
	-- something being ground.
	--==========================================================================
	--
	-- BOTH OF THESE SIT CLEAR OF THE STONE ON PURPOSE. The disc is four studs of
	-- solid radius centred at head height, and an emitter placed at the contact
	-- point is an emitter placed INSIDE it -- every mote born occluded by the
	-- very thing it is meant to be coming off. The bed is below the disc and
	-- wider than it is thick, so plumes show either side; the chute's is out past
	-- the disc's outer face.
	local bed = shell(model, cf, Vector3.new(8.4, 0.35, 0), Vector3.new(5.2, 0.6, 4.6), "GrindBed")
	local grit = Instance.new("ParticleEmitter")
	grit.Name = "StoneDust"
	grit.Texture = "rbxasset://textures/particles/smoke_main.dds"
	grit.Rate = 20
	grit.Lifetime = NumberRange.new(0.7, 1.4)
	grit.Speed = NumberRange.new(2, 4)
	grit.SpreadAngle = Vector2.new(38, 26)
	grit.EmissionDirection = Enum.NormalId.Top
	grit.Acceleration = Vector3.new(0, -1.4, 0)
	-- Big enough and dark enough to be seen against BOTH things it sits in front
	-- of -- pale stone and bright grass. The first pass was a 1.5-stud light grey
	-- puff at 40% transparency, which is a cloud you can prove exists and cannot
	-- point at.
	grit.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.9),
		NumberSequenceKeypoint.new(1, 3),
	})
	grit.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	grit.Color = ColorSequence.new(Color3.fromRGB(164, 156, 140))
	grit.Parent = bed
	whenRunning(grit)

	local mouth = shell(model, cf, Vector3.new(9.9, 6.5, -1.5), Vector3.new(1.3, 0.8, 1.6), "ChuteMouth")
	local flour = Instance.new("ParticleEmitter")
	flour.Name = "FlourFall"
	flour.Texture = "rbxasset://textures/particles/smoke_main.dds"
	flour.Rate = 10
	flour.Lifetime = NumberRange.new(1, 1.8)
	flour.Speed = NumberRange.new(0.4, 1.1)
	flour.SpreadAngle = Vector2.new(14, 14)
	flour.EmissionDirection = Enum.NormalId.Bottom
	flour.Acceleration = Vector3.new(0, -3.2, 0)
	flour.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(1, 2),
	})
	flour.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	flour.Color = ColorSequence.new(Color3.fromRGB(224, 208, 176))
	flour.Parent = mouth
	whenRunning(flour)

	-- Sacks of what came out of it.
	for i, spot in ipairs({
		Vector3.new(-7.8, 1, 6.2), Vector3.new(-7.4, 1, 8), Vector3.new(-8.4, 2.6, 7.1),
	}) do
		part({
			name = "FlourSack",
			size = Vector3.new(1.5, 1.9, 1.3),
			cframe = cf * CFrame.new(spot) * CFrame.Angles(0, math.rad(i * 27), math.rad(i * 4)),
			color = Color3.fromRGB(214, 204, 178),
			material = Enum.Material.Fabric,
			collide = false,
			parent = model,
		})
	end
end

--==============================================================================
-- 5. GLASSHOUSE -- weather stopped mattering
--
-- A gable. That is the whole silhouette and it is unmistakable from any distance
-- at which a mill is a shape: two slopes and a ridge, which is a building, and
-- nothing below tier 5 is a building.
--
-- No wheel of any kind. Tiers 4 and 6 both have a big round thing on them and
-- putting a third between them would flatten all three -- the glasshouse earns
-- its place by being the one you go INSIDE.
--==============================================================================
local function glasshouse(s: Signature)
	local cf, model, look = s.cf, s.model, s.look

	--== 1. WHITE METAL BALUSTRADE ==--
	for _, side in ipairs({ -1, 1 }) do
		cylinder({
			name = "HandRail",
			size = Vector3.new(16.2, 0.3, 0.3),
			cframe = cf * CFrame.new(side * 4.7, 3.3, -0.05)
				* CFrame.Angles(0, math.rad(90), 0),
			color = look.rail,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
		for i = 0, 6 do
			cylinder({
				name = "Baluster",
				size = Vector3.new(3.1, 0.22, 0.22),
				cframe = cf * CFrame.new(side * 4.7, 1.75, -7.8 + i * 2.6)
					* CFrame.Angles(0, 0, math.rad(90)),
				color = look.rail,
				material = Enum.Material.Metal,
				collide = false,
				parent = model,
			})
		end
	end

	--== 2. CRYSTAL GLASS FLANK SCREENS & CORNER POSTS (OPEN TO SKY) ==--
	for _, side in ipairs({ -1, 1 }) do
		-- Flank eave framing rail at balustrade height
		part({
			name = "EaveBeam",
			size = Vector3.new(0.45, 0.45, 18.8),
			cframe = cf * CFrame.new(side * 5.4, 4.4, 0),
			color = look.rail,
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = model,
		})

		-- Corner cast-iron posts with brass caps
		for _, corner in ipairs({ -9.2, 9.2 }) do
			part({
				name = "CornerPost",
				size = Vector3.new(0.55, 4.6, 0.55),
				cframe = cf * CFrame.new(side * 5.4, 2.5, corner),
				color = look.rail,
				material = Enum.Material.SmoothPlastic,
				collide = false,
				parent = model,
			})
			part({
				name = "CornerFinial",
				size = Vector3.new(0.75, 0.4, 0.75),
				cframe = cf * CFrame.new(side * 5.4, 4.9, corner),
				color = GOLD,
				material = Enum.Material.Metal,
				collide = false,
				parent = model,
			})
		end

		-- Clear crystal glass flank screen
		part({
			name = "SidePane",
			size = Vector3.new(0.14, 3.8, 18.0),
			cframe = cf * CFrame.new(side * 5.42, 2.5, 0),
			color = GLASS,
			material = Enum.Material.Glass,
			transparency = 0.55,
			collide = false,
			studs = false,
			parent = model,
		})

		-- Vertical glazing mullion bars
		for _, z in ipairs({ -6.2, -2.1, 2.1, 6.2 }) do
			part({
				name = "GlazingBar",
				size = Vector3.new(0.22, 3.8, 0.22),
				cframe = cf * CFrame.new(side * 5.42, 2.5, z),
				color = look.rail,
				material = Enum.Material.SmoothPlastic,
				collide = false,
				parent = model,
			})
		end

		-- Decorative cresting along the top rail
		for i = 0, 8 do
			part({
				name = "Cresting",
				size = Vector3.new(0.2, 0.4, 0.2),
				cframe = cf * CFrame.new(side * 5.4, 4.75, -8.0 + i * 2.0)
					* CFrame.Angles(0, math.rad(45), 0),
				color = GOLD,
				material = Enum.Material.Metal,
				collide = false,
				parent = model,
			})
		end
	end

	--== 3. CONSERVATORY FLANK PLANTER TERRACES ==--
	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "PlanterTerrace",
			size = Vector3.new(1.8, 1.2, 12.0),
			cframe = cf * CFrame.new(side * 6.8, 0.6, 0),
			color = CREAM,
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = model,
		})
		part({
			name = "PlanterSoil",
			size = Vector3.new(1.4, 0.3, 11.6),
			cframe = cf * CFrame.new(side * 6.8, 1.3, 0),
			color = EARTH,
			material = Enum.Material.Ground,
			collide = false,
			parent = model,
		})
		for i = 0, 5 do
			local z = -5.0 + i * 2.0
			part({
				name = "ExoticFern",
				size = Vector3.new(1.0, 1.5, 1.0),
				cframe = cf * CFrame.new(side * 6.8, 2.1, z)
					* CFrame.Angles(0, math.rad(i * 45), 0),
				color = if i % 2 == 0 then HEART else LEAF,
				material = Enum.Material.Grass,
				collide = false,
				parent = model,
			})
		end
	end

	--== 4. FRONT CONSERVATORY STREETLAMPS ==--
	for _, side in ipairs({ -1, 1 }) do
		local lampPost = part({
			name = "LampPost",
			size = Vector3.new(0.5, 5.0, 0.5),
			cframe = cf * CFrame.new(side * 5.4, 2.7, -9.2),
			color = look.rail,
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = model,
		})
		local lampGlobe = part({
			name = "LampGlobe",
			size = Vector3.new(0.8, 0.8, 0.8),
			cframe = cf * CFrame.new(side * 5.4, 5.3, -9.2),
			color = CREAM,
			material = Enum.Material.Neon,
			collide = false,
			parent = model,
		})
		local light = Instance.new("PointLight")
		light.Brightness = 0.5
		light.Range = 8
		light.Color = Color3.fromRGB(255, 240, 205)
		light.Parent = lampGlobe
	end

	--== 5. MIST EXHAUST VENTS & AMBIENT HAZE ==--
	for _, side in ipairs({ -1, 1 }) do
		local vent = part({
			name = "Vent",
			size = Vector3.new(1, 0.8, 1),
			cframe = cf * CFrame.new(side * 4.9, 1.5, -8.2),
			color = look.rail,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
		local puff = Instance.new("ParticleEmitter")
		puff.Name = "Steam"
		puff.Texture = "rbxasset://textures/particles/smoke_main.dds"
		puff.Rate = 9
		puff.Lifetime = NumberRange.new(1.1, 1.9)
		puff.Speed = NumberRange.new(2.5, 4)
		puff.SpreadAngle = Vector2.new(12, 12)
		puff.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(1, 3.4),
		})
		puff.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})
		puff.Color = ColorSequence.new(Color3.fromRGB(238, 244, 238))
		puff.Parent = vent
		whenRunning(puff)
	end

	local air = shell(model, cf, Vector3.new(0, 2.5, 0), Vector3.new(8.4, 2.4, 16.5), "GlassAir")
	local haze = Instance.new("ParticleEmitter")
	haze.Name = "GrowHaze"
	haze.Texture = "rbxasset://textures/particles/smoke_main.dds"
	haze.Rate = 5
	haze.Lifetime = NumberRange.new(2.6, 4.4)
	haze.Speed = NumberRange.new(0.3, 0.9)
	haze.SpreadAngle = Vector2.new(80, 80)
	haze.EmissionDirection = Enum.NormalId.Top
	haze.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 2),
		NumberSequenceKeypoint.new(1, 5),
	})
	haze.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.35, 0.66),
		NumberSequenceKeypoint.new(1, 1),
	})
	haze.Color = ColorSequence.new(Color3.fromRGB(236, 250, 240))
	haze.Parent = air
	whenRunning(haze)

	for _, side in ipairs({ -1, 1 }) do
		local strip = part({
			name = "GlowStrip",
			size = Vector3.new(0.4, 0.3, 16),
			cframe = cf * CFrame.new(side * 4.3, 1.2, 0),
			color = CREAM,
			material = Enum.Material.Neon,
			collide = false,
			studs = false,
			parent = model,
		})
		CollectionService:AddTag(strip, GameConfig.Tags.MillPulse)
	end
end

--==============================================================================
local function sunwheel(s: Signature)
	local cf, model, look = s.cf, s.model, s.look

	--== 1. TURNED GILT BALUSTRADE ==--
	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 6 do
			local z = -7.8 + i * 2.6
			cylinder({
				name = "Baluster",
				size = Vector3.new(2.2, 0.28, 0.28),
				cframe = cf * CFrame.new(side * 4.9, 1.7, z) * CFrame.Angles(0, 0, math.rad(90)),
				color = look.rail,
				material = Enum.Material.Metal,
				collide = false,
				parent = model,
			})
			cylinder({
				name = "Bead",
				size = Vector3.new(0.4, 0.62, 0.62),
				cframe = cf * CFrame.new(side * 4.9, 1.7, z) * CFrame.Angles(0, 0, math.rad(90)),
				color = GOLD_DARK,
				material = Enum.Material.Metal,
				collide = false,
				parent = model,
			})
		end
		part({
			name = "RailMoulding",
			size = Vector3.new(0.75, 0.3, 16.4),
			cframe = cf * CFrame.new(side * 4.9, 2.9, -0.05),
			color = look.rail,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
		part({
			name = "RailCap",
			size = Vector3.new(0.45, 0.22, 16.4),
			cframe = cf * CFrame.new(side * 4.9, 3.15, -0.05),
			color = GOLD_DARK,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
	end

	--== 2. THE GRAND RADIANT SUNWHEEL (FRONT FOCUS) ==--
	local hubAt = CFrame.new(0, 11.2, -9.6) * CFrame.Angles(0, math.rad(90), 0)
	local disc = cylinder({
		name = "SunDisc",
		size = Vector3.new(0.85, 9.2, 9.2),
		cframe = cf * hubAt,
		color = GOLD,
		material = Enum.Material.Metal,
		collide = false,
		parent = model,
	})
	CollectionService:AddTag(disc, GameConfig.Tags.MillWheel)

	cylinder({
		name = "SunCore",
		size = Vector3.new(1, 2.7, 2.7),
		cframe = cf * hubAt,
		color = Color3.fromRGB(255, 238, 176),
		material = Enum.Material.Neon,
		collide = false,
		parent = disc,
	})
	cylinder({
		name = "SunRim",
		size = Vector3.new(0.7, 7.4, 7.4),
		cframe = cf * hubAt,
		color = GOLD_DARK,
		material = Enum.Material.Metal,
		collide = false,
		parent = disc,
	})
	for i = 1, 12 do
		local a = (i / 12) * math.pi * 2
		part({
			name = "Ray",
			size = Vector3.new(0.45, 2.9, 0.45),
			cframe = cf * hubAt * CFrame.Angles(a, 0, 0) * CFrame.new(0, 5.7, 0),
			color = GOLD,
			material = Enum.Material.Neon,
			collide = false,
			parent = disc,
		})
	end
	for i = 1, 16 do
		local a = (i / 16) * math.pi * 2
		part({
			name = "RingStud",
			size = Vector3.new(0.5, 0.7, 0.7),
			cframe = cf * hubAt * CFrame.Angles(a, 0, 0) * CFrame.new(0, 4.2, 0),
			color = GOLD_DARK,
			material = Enum.Material.Metal,
			collide = false,
			parent = disc,
		})
	end
	local sunLight = Instance.new("PointLight")
	sunLight.Brightness = 0.45
	sunLight.Range = 11
	sunLight.Color = Color3.fromRGB(255, 224, 150)
	sunLight.Parent = disc

	-- A-frame support structure
	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "SunLeg",
			size = Vector3.new(0.65, 11.6, 0.65),
			cframe = cf * CFrame.new(side * 1.8, 5.9, -9.6)
				* CFrame.Angles(0, 0, math.rad(side * 18.8)),
			color = look.rail,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
	end
	part({
		name = "SunBrace",
		size = Vector3.new(7.2, 0.4, 0.4),
		cframe = cf * CFrame.new(0, 6.4, -9.6),
		color = GOLD_DARK,
		material = Enum.Material.Metal,
		collide = false,
		parent = model,
	})

	--== 3. SWAYING GILT BANNERS ON FLANKS ==--
	for _, side in ipairs({ -1, 1 }) do
		local post = part({
			name = "BannerPost",
			size = Vector3.new(0.4, 4.8, 0.4),
			cframe = cf * CFrame.new(side * 4.9, 2.6, 2.4),
			color = GOLD_DARK,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
		local banner = part({
			name = "Banner",
			size = Vector3.new(0.22, 3.2, 2.2),
			cframe = cf * CFrame.new(side * 4.9, 3.6, 2.4),
			color = GOLD,
			material = Enum.Material.Fabric,
			collide = false,
			parent = model,
		})
		banner:SetAttribute("SwaySide", side)
		CollectionService:AddTag(banner, GameConfig.Tags.MillBanner)
	end

	--== 4. ROTATING FLANK SPUR GEARS ==--
	for index, spec in ipairs({ { 2.1, 2.6 }, { 3.8, 1.7 } }) do
		local gear = cylinder({
			name = "Gear",
			size = Vector3.new(0.55, spec[2], spec[2]),
			cframe = cf * CFrame.new(-6.7, spec[1], -5),
			color = GOLD,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
		gear:SetAttribute("GearIndex", index)
		CollectionService:AddTag(gear, GameConfig.Tags.MillGear)
	end

	--== 5. CEREMONIAL GOLDEN URNS AT ENTRANCE ==--
	for _, side in ipairs({ -1, 1 }) do
		cylinder({
			name = "UrnBowl",
			size = Vector3.new(1.7, 2.3, 2.3),
			cframe = cf * CFrame.new(side * 4.7, 1.9, 8.6) * CFrame.Angles(0, 0, math.rad(90)),
			color = GOLD,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
		cylinder({
			name = "UrnFoot",
			size = Vector3.new(0.9, 1.2, 1.2),
			cframe = cf * CFrame.new(side * 4.7, 0.6, 8.6) * CFrame.Angles(0, 0, math.rad(90)),
			color = GOLD_DARK,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
		part({
			name = "UrnBloom",
			size = Vector3.new(1.8, 1.4, 1.8),
			cframe = cf * CFrame.new(side * 4.7, 3.4, 8.6),
			color = CREAM,
			material = Enum.Material.Grass,
			collide = false,
			parent = model,
		})
	end

	--== 6. STEAM VENTS, SPARKS & GILT MOTES ==--
	for _, side in ipairs({ -1, 1 }) do
		local vent = part({
			name = "Vent",
			size = Vector3.new(1, 0.8, 1),
			cframe = cf * CFrame.new(side * 4.9, 1.5, -7.6),
			color = GOLD_DARK,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
		local puff = Instance.new("ParticleEmitter")
		puff.Name = "Steam"
		puff.Texture = "rbxasset://textures/particles/smoke_main.dds"
		puff.Rate = 9
		puff.Lifetime = NumberRange.new(1.1, 1.9)
		puff.Speed = NumberRange.new(2.5, 4)
		puff.SpreadAngle = Vector2.new(12, 12)
		puff.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(1, 3.4),
		})
		puff.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})
		puff.Color = ColorSequence.new(Color3.fromRGB(252, 238, 206))
		puff.Parent = vent
		whenRunning(puff)
	end

	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "SunSparks"
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Rate = 12
	sparks.Lifetime = NumberRange.new(0.8, 1.6)
	sparks.Speed = NumberRange.new(3, 7)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Acceleration = Vector3.new(0, -6, 0)
	sparks.LightEmission = 0.8
	sparks.LightInfluence = 0
	sparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.1),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	sparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	sparks.Color = ColorSequence.new(Color3.fromRGB(255, 226, 140))
	sparks.Parent = disc
	whenRunning(sparks)

	for _, side in ipairs({ -1, 1 }) do
		local flank = shell(model, cf, Vector3.new(side * 6.9, 4.2, 0),
			Vector3.new(0.6, 8, 20), "GoldFlank")
		local motes = Instance.new("ParticleEmitter")
		motes.Name = "GildMotes"
		motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		motes.Rate = 9
		motes.Lifetime = NumberRange.new(1.6, 3)
		motes.Speed = NumberRange.new(1.2, 2.6)
		motes.SpreadAngle = Vector2.new(24, 24)
		motes.EmissionDirection = Enum.NormalId.Top
		motes.Acceleration = Vector3.new(0, 1.2, 0)
		motes.LightEmission = 0.6
		motes.LightInfluence = 0
		motes.Rotation = NumberRange.new(0, 360)
		motes.RotSpeed = NumberRange.new(-45, 45)
		motes.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(0.4, 1.3),
			NumberSequenceKeypoint.new(1, 0.35),
		})
		motes.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(0.65, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		})
		motes.Color = ColorSequence.new(Color3.fromRGB(255, 218, 128))
		motes.Parent = flank
		whenRunning(motes)
	end

	for _, side in ipairs({ -1, 1 }) do
		local strip = part({
			name = "GlowStrip",
			size = Vector3.new(0.4, 0.3, 16),
			cframe = cf * CFrame.new(side * 4.3, 1.2, 0),
			color = GOLD,
			material = Enum.Material.Neon,
			collide = false,
			studs = false,
			parent = model,
		})
		CollectionService:AddTag(strip, GameConfig.Tags.MillPulse)
	end
end

--==============================================================================
local function heartroot(s: Signature)
	local cf, model, deck = s.cf, s.model, s.deck

	-- A rail of living posts, no two the same height, with vine slung between.
	for _, side in ipairs({ -1, 1 }) do
		local heights = { 3.4, 4.2, 3, 3.9 }
		local zs = { -7.6, -2.8, 2, 6.8 }
		for i, z in ipairs(zs) do
			part({
				name = "LivePost",
				size = Vector3.new(0.5, heights[i], 0.5),
				cframe = cf * CFrame.new(side * 5.1, heights[i] * 0.5, z)
					* CFrame.Angles(math.rad(i * 2 - 4), 0, math.rad(side * (i % 3))),
				color = OAK_DARK,
				material = Enum.Material.Wood,
				collide = false,
				parent = model,
			})
			part({
				name = "PostLeaf",
				size = Vector3.new(0.9, 0.9, 0.9),
				cframe = cf * CFrame.new(side * 5.1, heights[i] + 0.3, z),
				color = LEAF,
				material = Enum.Material.Grass,
				collide = false,
				parent = model,
			})
		end
		for i = 1, 3 do
			slack(model, cf, side * 5.1, zs[i], zs[i + 1],
				math.min(heights[i], heights[i + 1]) - 0.5, 0.5, 0.24,
				MOSS, Enum.Material.Grass, "Vine")
		end
	end

	--==========================================================================
	-- THE TRUNK
	--
	-- Five segments leaning out of the left flank, each narrower than the one
	-- below. The taper is the whole illusion: a stack of equal boxes is a
	-- column, and a stack that narrows is a thing that grew.
	--==========================================================================
	local base = Vector3.new(-6.5, 0.4, -1.6)
	local top = Vector3.new(-3.4, 12.6, -0.6)
	for i = 1, 5 do
		local t = (i - 0.5) / 5
		local wide = 3.1 - t * 1.7
		part({
			name = "Trunk",
			size = Vector3.new(wide, 2.85, wide),
			cframe = cf * CFrame.new(base:Lerp(top, t))
				* CFrame.Angles(math.rad(-4.5), 0, math.rad(-13.8)),
			color = OAK_DARK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
	end
	-- Roots gripping the ground around it.
	for i, deg in ipairs({ -68, -26, 14, 52, 96 }) do
		part({
			name = "Root",
			size = Vector3.new(1, 0.8, 3.6),
			cframe = cf * CFrame.new(base + Vector3.new(0, 0.2, 0))
				* CFrame.Angles(0, math.rad(deg), 0)
				* CFrame.new(0, -0.2 - i * 0.05, 1.9)
				* CFrame.Angles(math.rad(9), 0, 0),
			color = OAK_DARK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
	end

	--==========================================================================
	-- THE HEARTWOOD
	--
	-- Bright, not blinding. At 2.2 over a range of 22 the top tier washed the
	-- whole plot flat green -- the mill stopped having edges and so did the
	-- grass around it. A premium mill should be the brightest thing on the plot,
	-- not the only thing.
	--==========================================================================
	local core = part({
		name = "Heartroot",
		size = Vector3.new(1.6, 2.1, 1.6),
		cframe = cf * CFrame.new(-5.6, 4.4, -1.3) * CFrame.Angles(0, 0, math.rad(-13.8)),
		color = HEART,
		material = Enum.Material.Neon,
		collide = false,
		parent = model,
	})
	CollectionService:AddTag(core, GameConfig.Tags.MillPulse)
	local light = Instance.new("PointLight")
	light.Brightness = 1.1
	light.Range = 14
	light.Color = HEART
	light.Parent = core

	--==========================================================================
	-- THE BRANCH
	--
	-- Thrown across the belt and lifting in the middle, built by pointing each
	-- segment at the next one. lookAt is doing the work a pile of hand-written
	-- angles would otherwise do badly.
	--==========================================================================
	local from = Vector3.new(-4, 10.4, -0.8)
	local to = Vector3.new(4.9, 7.4, 2.2)
	local function along(t: number): Vector3
		return from:Lerp(to, t) + Vector3.new(0, math.sin(t * math.pi) * 1.7, 0)
	end
	for i = 1, 6 do
		local a = along((i - 1) / 6)
		local b = along(i / 6)
		local mid = a:Lerp(b, 0.5)
		part({
			name = "Branch",
			size = Vector3.new(0.95 - i * 0.07, 0.95 - i * 0.07, (b - a).Magnitude * 1.1),
			cframe = CFrame.lookAt(cf:PointToWorldSpace(mid), cf:PointToWorldSpace(b)),
			color = OAK_DARK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
	end

	--==========================================================================
	-- THE CANOPY
	--
	-- Overlapping slabs at broken angles. Every one shares an edge with another
	-- so there is no sky between them from below, which is the only test a
	-- canopy has to pass.
	--==========================================================================
	for _, leaf in ipairs({
		-- The mass, sat on the top of the trunk.
		{ -3.4, 12.8, -0.6, 5.2, 18 }, { -1.6, 12.3, 1.2, 4.6, -34 },
		{ -5.2, 12.1, 0.9, 4.4, 58 }, { -2.4, 12.2, -2.6, 4.3, -12 },
		{ -4.8, 12.6, -2.2, 3.8, 42 }, { -3.1, 13.9, -0.3, 3.9, -6 },
		-- The skirt, low enough to close the gap to the trunk.
		{ -0.6, 11.3, -0.2, 3.6, 8 }, { -3.2, 11, 2.8, 3.4, -52 },
		{ -6, 11.2, -0.4, 3.2, 70 }, { -4.4, 10.6, -3, 3, 26 },
		{ -1.4, 10.8, -3.2, 2.9, -22 },
		-- And along the branch, so it arrives somewhere instead of stopping.
		{ 1.4, 10.4, 1.4, 3, 34 }, { 3.4, 9.3, 2, 2.6, -18 },
		{ 4.9, 8.2, 2.4, 2.2, 48 },
	}) do
		part({
			name = "Canopy",
			size = Vector3.new(leaf[4], 0.85, leaf[4] * 0.86),
			cframe = cf * CFrame.new(leaf[1], leaf[2], leaf[3])
				* CFrame.Angles(math.rad(leaf[5] * 0.16), math.rad(leaf[5]), math.rad(leaf[5] * 0.1)),
			color = if leaf[2] > 12.8 then LEAF elseif leaf[5] > 0 then MOSS else STEM,
			material = Enum.Material.Grass,
			collide = false,
			parent = model,
		})
	end
	for _, spot in ipairs({
		{ -2.4, 14.1, 0.8 }, { -4.4, 13.2, -1.6 }, { -0.6, 12.4, 2 },
		{ 1.8, 11, 1.4 }, { -5.4, 12.2, 1 }, { -1.4, 13.6, -2.4 },
	}) do
		part({
			name = "Blossom",
			size = Vector3.new(0.75, 0.75, 0.75),
			cframe = cf * CFrame.new(spot[1], spot[2], spot[3]),
			color = Color3.fromRGB(246, 186, 206),
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = model,
		})
	end

	-- The ring Ambience makes orbit, hung under the canopy rather than out in
	-- front of the mill where it used to be.
	for i = 1, 9 do
		local floater = part({
			name = "FloatLeaf",
			size = Vector3.new(1, 0.3, 1.6),
			cframe = cf * CFrame.new(-2.4, 9.4, 0.4),
			color = LEAF,
			material = Enum.Material.Grass,
			collide = false,
			parent = model,
		})
		floater:SetAttribute("OrbitIndex", i)
		floater:SetAttribute("OrbitCount", 9)
		CollectionService:AddTag(floater, GameConfig.Tags.MillLeaf)
	end

	for _, side in ipairs({ -1, 1 }) do
		local cloth = part({
			name = "Banner",
			size = Vector3.new(0.2, 2.8, 1.8),
			cframe = cf * CFrame.new(side * 2.2, 8.4, 1.6),
			color = HEART,
			material = Enum.Material.Fabric,
			collide = false,
			parent = model,
		})
		cloth:SetAttribute("SwaySide", side)
		CollectionService:AddTag(cloth, GameConfig.Tags.MillBanner)
		local strip = part({
			name = "GlowStrip",
			size = Vector3.new(0.4, 0.3, 16),
			cframe = cf * CFrame.new(side * 4.3, 1.2, 0),
			color = HEART,
			material = Enum.Material.Neon,
			collide = false,
			studs = false,
			parent = model,
		})
		CollectionService:AddTag(strip, GameConfig.Tags.MillPulse)
	end

	--==========================================================================
	-- THE RAINBOW, ALL THE WAY ROUND IT
	--
	-- Four curtains -- both flanks, both ends -- so the mill is ringed rather
	-- than dusted. Each mote walks the entire spectrum over its own life, which
	-- is what makes the curtain read as a rainbow standing in the air instead of
	-- as coloured sparks: at any instant the column has every hue in it at once,
	-- in order, because the motes in it are at different ages.
	--
	-- Off until somebody steps on. This is the thing a hundred and fifty million
	-- buys, and a reward you cannot switch on is scenery.
	--==========================================================================
	for _, wall in ipairs({
		{ Vector3.new(-7.3, 4.6, 0), Vector3.new(0.6, 9, 22) },
		{ Vector3.new(7.3, 4.6, 0), Vector3.new(0.6, 9, 22) },
		{ Vector3.new(0, 4.6, -10.9), Vector3.new(15.4, 9, 0.6) },
		{ Vector3.new(0, 4.6, 10.9), Vector3.new(15.4, 9, 0.6) },
	}) do
		local curtain = shell(model, cf, wall[1], wall[2], "AuraWall")
		local bow = Instance.new("ParticleEmitter")
		bow.Name = "RainbowAura"
		bow.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		bow.Rate = 18
		bow.Lifetime = NumberRange.new(1.6, 2.9)
		bow.Speed = NumberRange.new(1.4, 3.2)
		bow.SpreadAngle = Vector2.new(26, 26)
		bow.EmissionDirection = Enum.NormalId.Top
		bow.Acceleration = Vector3.new(0, 1.6, 0)
		bow.LightEmission = 1
		bow.LightInfluence = 0
		bow.Rotation = NumberRange.new(0, 360)
		bow.RotSpeed = NumberRange.new(-70, 70)
		-- Density over size. Eighteen a second at 1.5 studs rings the machine;
		-- the same count at 1.9 was a screenful of stars with a mill somewhere
		-- behind it, which is a worse version of the same idea.
		bow.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.45, 1.5),
			NumberSequenceKeypoint.new(1, 0.4),
		})
		-- Opaque as soon as it exists. Fading IN as well as out halves the life
		-- a mote is actually visible for, which is how eighty particles a second
		-- managed to read as none.
		bow.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.7, 0.15),
			NumberSequenceKeypoint.new(1, 1),
		})
		bow.Color = SPECTRUM
		bow.Parent = curtain
		whenRunning(bow)
	end

	-- Slow gold motes over the whole deck. Always on, unlike the aura: a
	-- Heartroot mill is alive whether or not anybody is using it.
	local motes = Instance.new("ParticleEmitter")
	motes.Name = "Pollen"
	motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	motes.Rate = 9
	motes.Lifetime = NumberRange.new(2.4, 4)
	motes.Speed = NumberRange.new(0.6, 1.6)
	motes.SpreadAngle = Vector2.new(180, 180)
	motes.Size = NumberSequence.new(0.55)
	motes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.3, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	motes.Color = ColorSequence.new(Color3.fromRGB(214, 246, 190))
	motes.Parent = deck
end


--==============================================================================
-- 8. INFERNO FORGE -- hellish volcanic forge
--
-- Volcanic obsidian and molten magma chassis. Massive jagged obsidian horns
-- frame the front console with an open burning magma forge core pulsing with heat.
-- Jagged obsidian spires with dark iron chains along the flanks, dual flaming
-- brimstone cauldrons, rising smoke and fiery sparks, with zero overhead roofs!
--==============================================================================
local function infernoForge(s: Signature)
	local cf, model, look, belt = s.cf, s.model, s.look, s.belt

	--== 1. RADIANT MOLTEN LAVA ILLUMINATION & HEAT GLOW ==--
	local lavaGlow = Instance.new("PointLight")
	lavaGlow.Name = "LavaHeatLight"
	lavaGlow.Brightness = 1.4
	lavaGlow.Range = 16
	lavaGlow.Color = Color3.fromRGB(255, 90, 15)
	lavaGlow.Parent = belt

	-- Lava bed glow underneath the belt
	part({
		name = "LavaBed",
		size = Vector3.new(belt.Size.X + 0.6, 0.2, belt.Size.Z + 0.6),
		cframe = cf * CFrame.new(0, 0.25, 0),
		color = Color3.fromRGB(180, 30, 5),
		material = Enum.Material.Neon,
		studs = false,
		collide = false,
		parent = model,
	})

	--== 2. FLOATING CHARRED MAGMA CRUST ISLANDS ON THE LAVA BELT ==--
	local crustFolder = Instance.new("Folder")
	crustFolder.Name = "MagmaCrusts"
	crustFolder.Parent = belt

	local crustCount = 7
	local beltSpan = belt.Size.Z
	for c = 1, crustCount do
		local zOffset = ((c - 1) / crustCount) * beltSpan - beltSpan * 0.5
		for _, xSide in ipairs({ -1, 1 }) do
			local crustWidth = if (c + xSide) % 2 == 0 then 2.3 else 1.7
			local crustLen = 1.6 + ((c * 2) % 3) * 0.3
			local xOffset = xSide * (belt.Size.X * 0.26 + ((c % 3) * 0.15 - 0.15))
			local rotY = math.rad((c * 43 + xSide * 29) % 24 - 12)

			local slab = part({
				name = "CrustIsland",
				size = Vector3.new(crustWidth, 0.16, crustLen),
				cframe = cf * CFrame.new(xOffset, 0.49, zOffset) * CFrame.Angles(0, rotY, 0),
				color = Color3.fromRGB(24, 18, 16),
				material = Enum.Material.Slate,
				studs = false,
				collide = false,
				parent = crustFolder,
			})
			slab:SetAttribute("ChevronSpan", beltSpan)
			slab:SetAttribute("ChevronIndex", c)
			slab:SetAttribute("SlatCount", crustCount)
			CollectionService:AddTag(slab, GameConfig.Tags.MillSlat)

			-- Molten crack in the center of the crust slab
			part({
				name = "CrustFissure",
				size = Vector3.new(crustWidth * 0.65, 0.18, 0.22),
				cframe = slab.CFrame * CFrame.new(0, 0.02, 0) * CFrame.Angles(0, math.rad(22), 0),
				color = Color3.fromRGB(255, 140, 20),
				material = Enum.Material.Neon,
				studs = false,
				collide = false,
				parent = slab,
			})
		end
	end

	--== 3. LAVA BUBBLES & POPPING SPATTER PARTICLES ==--
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "LavaBubbles"
	bubbles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	bubbles.Rate = 18
	bubbles.Lifetime = NumberRange.new(0.6, 1.4)
	bubbles.Speed = NumberRange.new(1.0, 2.6)
	bubbles.SpreadAngle = Vector2.new(24, 24)
	bubbles.EmissionDirection = Enum.NormalId.Top
	bubbles.Acceleration = Vector3.new(0, 2.0, 0)
	bubbles.LightEmission = 0.95
	bubbles.LightInfluence = 0
	bubbles.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.6, 0.9),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	bubbles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.1),
		NumberSequenceKeypoint.new(0.8, 0.25),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	bubbles.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 80)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 100, 15)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 20, 5)),
	})
	bubbles.Parent = belt
	whenRunning(bubbles)

	-- Steam / heat haze rising off the molten lava river
	local steam = Instance.new("ParticleEmitter")
	steam.Name = "LavaSteam"
	steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
	steam.Rate = 10
	steam.Lifetime = NumberRange.new(1.5, 2.8)
	steam.Speed = NumberRange.new(0.8, 2.0)
	steam.SpreadAngle = Vector2.new(15, 15)
	steam.EmissionDirection = Enum.NormalId.Top
	steam.Acceleration = Vector3.new(0, 1.0, 0)
	steam.LightEmission = 0.2
	steam.LightInfluence = 0.1
	steam.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.0),
		NumberSequenceKeypoint.new(0.5, 2.4),
		NumberSequenceKeypoint.new(1, 3.8),
	})
	steam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.85),
		NumberSequenceKeypoint.new(0.3, 0.55),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	steam.Color = ColorSequence.new(Color3.fromRGB(50, 40, 38))
	steam.Parent = belt
	whenRunning(steam)

	--== 4. JAGGED OBSIDIAN SPIRE BALUSTRADE WITH DARK CHAINS ==--
	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 5 do
			local z = -7.5 + i * 3.0
			part({
				name = "ObsidianSpire",
				size = Vector3.new(0.65, 3.4, 0.65),
				cframe = cf * CFrame.new(side * 4.9, 1.8, z) * CFrame.Angles(0, math.rad(side * (i * 15)), math.rad(side * 5)),
				color = OBSIDIAN,
				material = Enum.Material.Slate,
				collide = false,
				parent = model,
			})
			part({
				name = "MagmaVein",
				size = Vector3.new(0.2, 2.2, 0.2),
				cframe = cf * CFrame.new(side * 4.9, 1.8, z),
				color = LAVA_ORANGE,
				material = Enum.Material.Neon,
				collide = false,
				parent = model,
			})
		end
		for i = 0, 4 do
			local z1 = -7.5 + i * 3.0
			local z2 = -7.5 + (i + 1) * 3.0
			slack(model, cf, side * 4.9, z1, z2, 3.2, 0.5, 0.22,
				Color3.fromRGB(30, 28, 32), Enum.Material.Metal, "IronChain")
		end
	end

	--== 5. THE HEAD OF THE DEVIL (FRONT CONSOLE) ==--
	local devilOrigin = cf * CFrame.new(0, 5.4, -9.2)

	-- 5A. Cranium & Demonic Skull Structure
	local skull = part({
		name = "DevilSkull",
		size = Vector3.new(4.6, 3.6, 3.6),
		cframe = devilOrigin * CFrame.new(0, 0.8, 0),
		color = Color3.fromRGB(24, 16, 18),
		material = Enum.Material.Slate,
		collide = false,
		parent = model,
	})

	-- Menacing Angular Brow Ridge
	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "DevilBrow",
			size = Vector3.new(2.1, 0.8, 1.4),
			cframe = devilOrigin * CFrame.new(side * 1.05, 1.7, 1.3) * CFrame.Angles(math.rad(18), math.rad(side * -15), math.rad(side * -12)),
			color = Color3.fromRGB(38, 14, 16),
			material = Enum.Material.Slate,
			collide = false,
			parent = model,
		})

		-- Jagged Cheekbones
		part({
			name = "Cheekbone",
			size = Vector3.new(1.2, 1.6, 1.6),
			cframe = devilOrigin * CFrame.new(side * 2.3, 0.2, 0.8) * CFrame.Angles(math.rad(15), math.rad(side * 25), math.rad(side * 10)),
			color = Color3.fromRGB(28, 16, 18),
			material = Enum.Material.Slate,
			collide = false,
			parent = model,
		})
	end

	-- Snout & Upper Mandible
	local snout = part({
		name = "DevilSnout",
		size = Vector3.new(3.2, 1.4, 2.4),
		cframe = devilOrigin * CFrame.new(0, 0.2, 1.6),
		color = Color3.fromRGB(26, 14, 16),
		material = Enum.Material.Slate,
		collide = false,
		parent = model,
	})

	-- Demonic Nostrils with glowing heat
	for _, nx in ipairs({ -0.5, 0.5 }) do
		part({
			name = "NostrilGlow",
			size = Vector3.new(0.35, 0.25, 0.35),
			cframe = snout.CFrame * CFrame.new(nx, -0.2, 1.15) * CFrame.Angles(math.rad(-30), 0, 0),
			color = Color3.fromRGB(255, 90, 15),
			material = Enum.Material.Neon,
			collide = false,
			parent = snout,
		})
	end

	-- Upper Sharp Fangs (Hanging menacingly from top jaw)
	for _, fx in ipairs({ -1.3, -0.85, -0.4, 0.4, 0.85, 1.3 }) do
		local isCanine = math.abs(fx) > 0.7
		local fangLen = if isCanine then 1.35 else 0.85
		local fang = part({
			name = "DevilFangUpper",
			size = Vector3.new(0.26, fangLen, 0.26),
			cframe = snout.CFrame * CFrame.new(fx, -0.65 - fangLen * 0.4, 1.0) * CFrame.Angles(math.rad(-18), 0, math.rad(fx * 8)),
			color = if isCanine then Color3.fromRGB(255, 230, 160) else Color3.fromRGB(240, 200, 150),
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = snout,
		})
	end

	-- 5B. EYES ON FIRE (Blazing Eye Sockets)
	for _, eyeX in ipairs({ -1.2, 1.2 }) do
		-- Deep dark socket
		local eyeSocket = part({
			name = "DevilEyeSocket",
			size = Vector3.new(1.3, 0.85, 0.6),
			cframe = devilOrigin * CFrame.new(eyeX, 1.1, 1.5) * CFrame.Angles(math.rad(15), math.rad(eyeX * -20), math.rad(eyeX * 16)),
			color = Color3.fromRGB(12, 6, 8),
			material = Enum.Material.Slate,
			collide = false,
			parent = model,
		})

		-- Glowing molten fiery eye orb
		local eyeOrb = part({
			name = "DevilEyeFire",
			size = Vector3.new(0.85, 0.5, 0.4),
			cframe = eyeSocket.CFrame * CFrame.new(0, 0, 0.25),
			color = Color3.fromRGB(255, 235, 60),
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			collide = false,
			parent = eyeSocket,
		})

		-- REAL BLAZING EYE FIRE
		local eyeFire = Instance.new("Fire")
		eyeFire.Name = "EyeFire"
		eyeFire.Size = 4.0
		eyeFire.Heat = 9
		eyeFire.Color = Color3.fromRGB(255, 140, 20)
		eyeFire.SecondaryColor = Color3.fromRGB(255, 30, 0)
		eyeFire.Parent = eyeOrb

		-- Eye Fire Sparks shooting forward out of pupils
		local eyeSparks = Instance.new("ParticleEmitter")
		eyeSparks.Name = "EyeSparks"
		eyeSparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		eyeSparks.Rate = 24
		eyeSparks.Lifetime = NumberRange.new(0.5, 1.2)
		eyeSparks.Speed = NumberRange.new(3.0, 6.5)
		eyeSparks.SpreadAngle = Vector2.new(20, 20)
		eyeSparks.EmissionDirection = Enum.NormalId.Front
		eyeSparks.LightEmission = 1.0
		eyeSparks.LightInfluence = 0
		eyeSparks.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.6),
			NumberSequenceKeypoint.new(0.5, 1.1),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		eyeSparks.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 160)),
			ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 130, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 20, 5)),
		})
		eyeSparks.Parent = eyeOrb
		whenRunning(eyeSparks)
	end

	-- 5C. GRAND CURVED DEMONIC HORNS (Sweeping outward and upward!)
	for _, side in ipairs({ -1, 1 }) do
		-- Horn Root (Out and back)
		local hornRoot = part({
			name = "DevilHornRoot",
			size = Vector3.new(1.3, 3.2, 1.3),
			cframe = devilOrigin * CFrame.new(side * 2.1, 2.2, -0.4) * CFrame.Angles(math.rad(-15), math.rad(side * 35), math.rad(side * 42)),
			color = Color3.fromRGB(20, 14, 16),
			material = Enum.Material.Slate,
			collide = false,
			parent = model,
		})

		-- Horn Mid (Sweeping up and curving)
		local hornMid = part({
			name = "DevilHornMid",
			size = Vector3.new(0.95, 3.4, 0.95),
			cframe = hornRoot.CFrame * CFrame.new(0, 2.7, 0) * CFrame.Angles(math.rad(35), math.rad(side * -18), math.rad(side * -25)),
			color = Color3.fromRGB(26, 16, 18),
			material = Enum.Material.Slate,
			collide = false,
			parent = model,
		})

		-- Horn Sharp Glowing Fiery Tip (Pointing majestically skyward)
		part({
			name = "DevilHornTip",
			size = Vector3.new(0.6, 2.8, 0.6),
			cframe = hornMid.CFrame * CFrame.new(0, 2.6, 0) * CFrame.Angles(math.rad(30), 0, math.rad(side * -15)),
			color = Color3.fromRGB(255, 80, 15),
			material = Enum.Material.Neon,
			collide = false,
			parent = model,
		})

		-- Temple Blade Spikes
		part({
			name = "TempleBlade",
			size = Vector3.new(0.4, 1.8, 0.7),
			cframe = devilOrigin * CFrame.new(side * 2.5, 1.0, 0.6) * CFrame.Angles(math.rad(10), math.rad(side * 40), math.rad(side * 35)),
			color = Color3.fromRGB(24, 14, 16),
			material = Enum.Material.Slate,
			collide = false,
			parent = model,
		})
	end

	-- Scalp Crown Spikes along centerline
	for i = 1, 3 do
		part({
			name = "CrownSpike",
			size = Vector3.new(0.45, 1.4 + i * 0.4, 0.45),
			cframe = devilOrigin * CFrame.new(0, 2.3 + i * 0.2, -1.0 + i * 0.9) * CFrame.Angles(math.rad(-20 + i * 12), 0, 0),
			color = Color3.fromRGB(255, 75, 15),
			material = Enum.Material.Neon,
			collide = false,
			parent = model,
		})
	end

	-- 5D. MOVING / CHOMPING ANIMATED LOWER JAW (Tagged MillJaw)
	local jawRoot = part({
		name = "DevilJaw",
		size = Vector3.new(3.0, 1.2, 2.8),
		cframe = devilOrigin * CFrame.new(0, -1.2, 1.4) * CFrame.Angles(math.rad(-12), 0, 0),
		color = Color3.fromRGB(24, 14, 16),
		material = Enum.Material.Slate,
		collide = false,
		parent = model,
	})
	CollectionService:AddTag(jawRoot, (GameConfig.Tags and GameConfig.Tags.MillJaw) or "MillJaw")

	-- Jagged Chin Spikes on moving jaw
	for _, cx in ipairs({ -0.6, 0, 0.6 }) do
		part({
			name = "ChinSpike",
			size = Vector3.new(0.4, 1.2, 0.4),
			cframe = jawRoot.CFrame * CFrame.new(cx, -0.6, 1.1) * CFrame.Angles(math.rad(-28), 0, math.rad(cx * 15)),
			color = Color3.fromRGB(255, 75, 15),
			material = Enum.Material.Neon,
			collide = false,
			parent = jawRoot,
		})
	end

	-- Lower Sharp Fangs (Pointing up on moving jaw)
	for _, fx in ipairs({ -1.15, -0.7, -0.25, 0.25, 0.7, 1.15 }) do
		local isCanine = math.abs(fx) > 0.6
		local fangLen = if isCanine then 1.25 else 0.75
		part({
			name = "DevilFangLower",
			size = Vector3.new(0.24, fangLen, 0.24),
			cframe = jawRoot.CFrame * CFrame.new(fx, 0.55 + fangLen * 0.35, 1.1) * CFrame.Angles(math.rad(18), 0, math.rad(fx * -8)),
			color = if isCanine then Color3.fromRGB(255, 230, 160) else Color3.fromRGB(240, 200, 150),
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = jawRoot,
		})
	end

	-- 5E. THROAT FIRE & MOLTEN LAVA TONGUE CASCADE
	local throatFirePart = part({
		name = "ThroatFireCore",
		size = Vector3.new(2.2, 1.4, 1.4),
		cframe = devilOrigin * CFrame.new(0, -0.3, 0.5),
		color = Color3.fromRGB(255, 95, 10),
		material = Enum.Material.Neon,
		collide = false,
		parent = model,
	})
	local throatLight = Instance.new("PointLight")
	throatLight.Name = "ThroatLight"
	throatLight.Color = Color3.fromRGB(255, 110, 20)
	throatLight.Brightness = 2.8
	throatLight.Range = 16
	throatLight.Parent = throatFirePart

	local throatFire = Instance.new("Fire")
	throatFire.Name = "ThroatFlames"
	throatFire.Size = 4.5
	throatFire.Heat = 7
	throatFire.Color = Color3.fromRGB(255, 130, 20)
	throatFire.SecondaryColor = Color3.fromRGB(180, 20, 5)
	throatFire.Parent = throatFirePart

	-- Molten lava tongue pouring down into the treadmill
	part({
		name = "DevilLavaTongue",
		size = Vector3.new(2.6, 2.4, 1.4),
		cframe = devilOrigin * CFrame.new(0, -2.0, 1.8) * CFrame.Angles(math.rad(-25), 0, 0),
		color = Color3.fromRGB(240, 65, 10),
		material = Enum.Material.Neon,
		studs = false,
		collide = false,
		parent = model,
	})

	--== 6. FLANK MAGMA CAULDRONS / BRAZIERS ==--
	for _, side in ipairs({ -1, 1 }) do
		cylinder({
			name = "Cauldron",
			size = Vector3.new(1.6, 2.4, 2.4),
			cframe = cf * CFrame.new(side * 6.8, 1.2, 3.0) * CFrame.Angles(0, 0, math.rad(90)),
			color = OBSIDIAN,
			material = Enum.Material.Slate,
			collide = false,
			parent = model,
		})
		local lavaPool = cylinder({
			name = "CauldronLava",
			size = Vector3.new(0.3, 2.0, 2.0),
			cframe = cf * CFrame.new(side * 6.8, 2.0, 3.0) * CFrame.Angles(0, 0, math.rad(90)),
			color = LAVA_ORANGE,
			material = Enum.Material.Neon,
			collide = false,
			parent = model,
		})

		local fire = Instance.new("Fire")
		fire.Size = 4
		fire.Heat = 6
		fire.Color = Color3.fromRGB(255, 100, 20)
		fire.SecondaryColor = Color3.fromRGB(180, 20, 10)
		fire.Parent = lavaPool
	end

	--== 7. VOLCANIC SMOKE & EMBER VENTS ==--
	for _, side in ipairs({ -1, 1 }) do
		local vent = part({
			name = "MagmaVent",
			size = Vector3.new(1.1, 0.9, 1.1),
			cframe = cf * CFrame.new(side * 4.9, 1.4, -7.8),
			color = OBSIDIAN,
			material = Enum.Material.Slate,
			collide = false,
			parent = model,
		})
		local embers = Instance.new("ParticleEmitter")
		embers.Name = "Embers"
		embers.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		embers.Rate = 14
		embers.Lifetime = NumberRange.new(1.2, 2.2)
		embers.Speed = NumberRange.new(2.5, 5.0)
		embers.SpreadAngle = Vector2.new(20, 20)
		embers.EmissionDirection = Enum.NormalId.Top
		embers.Acceleration = Vector3.new(0, 2, 0)
		embers.LightEmission = 0.9
		embers.LightInfluence = 0
		embers.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.8),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		embers.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 50)),
			ColorSequenceKeypoint.new(0.6, Color3.fromRGB(255, 80, 20)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 20, 10)),
		})
		embers.Parent = vent
		whenRunning(embers)
	end
end

local function celestialAscent(s: Signature)
	local cf, model, look, belt = s.cf, s.model, s.look, s.belt

	--== 1. POLISHED ALABASTER FLANK COLUMNS WITH GOLD TRIM ==--
	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 5 do
			local z = -7.5 + i * 3.0
			cylinder({
				name = "AlabasterColumn",
				size = Vector3.new(3.4, 0.75, 0.75),
				cframe = cf * CFrame.new(side * 4.9, 1.8, z) * CFrame.Angles(0, 0, math.rad(90)),
				color = ALABASTER,
				material = Enum.Material.SmoothPlastic,
				studs = false,
				collide = false,
				parent = model,
			})
			part({
				name = "GoldCapital",
				size = Vector3.new(0.95, 0.35, 0.95),
				cframe = cf * CFrame.new(side * 4.9, 3.5, z),
				color = CELESTIAL_GOLD,
				material = Enum.Material.Metal,
				studs = false,
				collide = false,
				parent = model,
			})
			part({
				name = "GoldBase",
				size = Vector3.new(0.95, 0.35, 0.95),
				cframe = cf * CFrame.new(side * 4.9, 0.3, z),
				color = CELESTIAL_GOLD,
				material = Enum.Material.Metal,
				studs = false,
				collide = false,
				parent = model,
			})
		end
		cylinder({
			name = "CelestialArchitrave",
			size = Vector3.new(16.2, 0.35, 0.35),
			cframe = cf * CFrame.new(side * 4.9, 3.7, -0.05) * CFrame.Angles(0, math.rad(90), 0),
			color = CELESTIAL_GOLD,
			material = Enum.Material.Metal,
			studs = false,
			collide = false,
			parent = model,
		})
	end

	--== 2. REAL LAYERED ANGEL WINGS (FLAPS SLOWLY WHEN USED) ==--
	for _, side in ipairs({ -1, 1 }) do
		local wingModel = Instance.new("Model")
		wingModel.Name = if side == -1 then "AngelWing_Left" else "AngelWing_Right"
		wingModel.Parent = model

		-- Wing Pivot / Root Part
		local wingOrigin = cf * CFrame.new(side * 2.2, 6.2, -9.2)
		local wingRoot = part({
			name = "WingRoot",
			size = Vector3.new(0.5, 0.5, 0.5),
			cframe = wingOrigin,
			color = ALABASTER,
			transparency = 1,
			collide = false,
			parent = wingModel,
		})
		wingModel.PrimaryPart = wingRoot
		wingModel:SetAttribute("WingSide", side)
		CollectionService:AddTag(wingModel, (GameConfig.Tags and GameConfig.Tags.MillWing) or "MillWing")

		-- Wing Bone / Shoulder Arch
		local wingBone = part({
			name = "WingBone",
			size = Vector3.new(0.65, 3.8, 0.65),
			cframe = wingOrigin * CFrame.new(side * 1.4, 1.4, 0) * CFrame.Angles(math.rad(-10), 0, math.rad(side * 40)),
			color = ALABASTER,
			material = Enum.Material.SmoothPlastic,
			studs = false,
			collide = false,
			parent = wingModel,
		})

		-- Weld all feathers to wingRoot for smooth performant client rotation
		local function weldToRoot(p: BasePart)
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = wingRoot
			weld.Part1 = p
			weld.Parent = wingRoot
		end
		weldToRoot(wingBone)

		-- Layer 1: Inner Covert Feathers (4 sleek soft feathers)
		for f = 1, 4 do
			local cov = part({
				name = "CovertFeather",
				size = Vector3.new(0.35, 2.2 + f * 0.4, 0.9),
				cframe = wingOrigin * CFrame.new(side * (0.8 + f * 0.5), 0.4 + f * 0.5, -0.1)
					* CFrame.Angles(math.rad(-5), 0, math.rad(side * (15 + f * 7))),
				color = ALABASTER,
				material = Enum.Material.SmoothPlastic,
				studs = false,
				collide = false,
				parent = wingModel,
			})
			weldToRoot(cov)
		end

		-- Layer 2: Middle Secondary Feathers (5 sweeping flight feathers)
		for f = 1, 5 do
			local sec = part({
				name = "SecondaryFeather",
				size = Vector3.new(0.38, 3.2 + f * 0.6, 1.1),
				cframe = wingOrigin * CFrame.new(side * (1.6 + f * 0.75), 1.2 + f * 0.7, -0.2)
					* CFrame.Angles(math.rad(-12), math.rad(side * -8), math.rad(side * (28 + f * 9))),
				color = ALABASTER,
				material = Enum.Material.SmoothPlastic,
				studs = false,
				collide = false,
				parent = wingModel,
			})
			weldToRoot(sec)

			-- Golden Feather Spine Accent
			local spine = part({
				name = "FeatherSpine",
				size = Vector3.new(0.18, 3.0 + f * 0.6, 0.22),
				cframe = sec.CFrame * CFrame.new(side * 0.12, 0, -0.4),
				color = CELESTIAL_GOLD,
				material = Enum.Material.Metal,
				studs = false,
				collide = false,
				parent = wingModel,
			})
			weldToRoot(spine)
		end

		-- Layer 3: Outer Primary Wingtips (6 grand sweeping flight feathers with glowing gold tips)
		for f = 1, 6 do
			local prim = part({
				name = "PrimaryFeather",
				size = Vector3.new(0.4, 4.4 + f * 0.7, 1.25),
				cframe = wingOrigin * CFrame.new(side * (2.8 + f * 0.9), 2.2 + f * 0.95, -0.3)
					* CFrame.Angles(math.rad(-18), math.rad(side * -12), math.rad(side * (40 + f * 8))),
				color = ALABASTER,
				material = Enum.Material.SmoothPlastic,
				studs = false,
				collide = false,
				parent = wingModel,
			})
			weldToRoot(prim)

			-- Radiant Glowing Wingtip
			local tip = part({
				name = "WingTipGlow",
				size = Vector3.new(0.42, 1.6, 1.28),
				cframe = prim.CFrame * CFrame.new(0, (4.4 + f * 0.7) * 0.5 - 0.7, 0),
				color = Color3.fromRGB(255, 235, 120),
				material = Enum.Material.Neon,
				studs = false,
				collide = false,
				parent = wingModel,
			})
			weldToRoot(tip)
		end
	end

	--== 3. ROTATING GOLDEN HALO DISC & CELESTIAL RADIANCE ==--
	local haloAt = CFrame.new(0, 7.5, -9.4) * CFrame.Angles(0, math.rad(90), 0)
	local halo = cylinder({
		name = "HaloDisc",
		size = Vector3.new(0.5, 6.2, 6.2),
		cframe = cf * haloAt,
		color = CELESTIAL_GOLD,
		material = Enum.Material.Metal,
		studs = false,
		collide = false,
		parent = model,
	})
	CollectionService:AddTag(halo, GameConfig.Tags.MillWheel)

	cylinder({
		name = "HaloGlow",
		size = Vector3.new(0.65, 4.4, 4.4),
		cframe = cf * haloAt,
		color = Color3.fromRGB(255, 255, 255),
		material = Enum.Material.Neon,
		studs = false,
		collide = false,
		parent = halo,
	})

	local haloLight = Instance.new("PointLight")
	haloLight.Brightness = 1.6
	haloLight.Range = 16
	haloLight.Color = Color3.fromRGB(255, 245, 210)
	haloLight.Parent = halo

	--== 4. SCULPTED CUMULUS CLOUD TERRACES ALONG FLANKS ==--
	for _, side in ipairs({ -1, 1 }) do
		for c = 0, 4 do
			local z = -6.0 + c * 3.0
			part({
				name = "CloudPuff",
				size = Vector3.new(1.8, 1.2, 2.2),
				cframe = cf * CFrame.new(side * 6.5, 0.8, z) * CFrame.Angles(0, math.rad(c * 35), 0),
				color = ALABASTER,
				material = Enum.Material.SmoothPlastic,
				shape = Enum.PartType.Ball,
				studs = false,
				collide = false,
				parent = model,
			})
		end
	end

	--== 5. CELESTIAL FEATHER PARTICLES (ACTIVATES WHEN USED) ==--
	local featherEmitter = Instance.new("ParticleEmitter")
	featherEmitter.Name = "AngelFeathers"
	featherEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	featherEmitter.Rate = 22
	featherEmitter.Lifetime = NumberRange.new(2.0, 4.0)
	featherEmitter.Speed = NumberRange.new(1.5, 3.5)
	featherEmitter.SpreadAngle = Vector2.new(45, 45)
	featherEmitter.EmissionDirection = Enum.NormalId.Top
	featherEmitter.Acceleration = Vector3.new(0, -0.6, 1.2)
	featherEmitter.Rotation = NumberRange.new(0, 360)
	featherEmitter.RotSpeed = NumberRange.new(-45, 45)
	featherEmitter.LightEmission = 0.9
	featherEmitter.LightInfluence = 0
	featherEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(0.3, 0.85),
		NumberSequenceKeypoint.new(0.8, 0.7),
		NumberSequenceKeypoint.new(1, 0.1),
	})
	featherEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1.0),
	})
	featherEmitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 245, 180)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 110)),
	})
	featherEmitter.Parent = s.deck
	whenRunning(featherEmitter)

	-- Holy light motes
	local stardust = Instance.new("ParticleEmitter")
	stardust.Name = "HolyMotes"
	stardust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	stardust.Rate = 14
	stardust.Lifetime = NumberRange.new(1.8, 3.2)
	stardust.Speed = NumberRange.new(1.2, 2.8)
	stardust.SpreadAngle = Vector2.new(30, 30)
	stardust.EmissionDirection = Enum.NormalId.Top
	stardust.Acceleration = Vector3.new(0, 1.5, 0)
	stardust.LightEmission = 0.95
	stardust.LightInfluence = 0
	stardust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(0.5, 1.2),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	stardust.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 235, 140)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 235, 255)),
	})
	stardust.Parent = s.deck
	whenRunning(stardust)

	for _, side in ipairs({ -1, 1 }) do
		local strip = part({
			name = "CelestialStrip",
			size = Vector3.new(0.4, 0.3, 16),
			cframe = cf * CFrame.new(side * 4.3, 1.2, 0),
			color = CELESTIAL_GOLD,
			material = Enum.Material.Neon,
			collide = false,
			studs = false,
			parent = model,
		})
		CollectionService:AddTag(strip, GameConfig.Tags.MillPulse)
	end
end

local function astralSingularity(s: Signature)
	local cf, model, look, belt = s.cf, s.model, s.look, s.belt

	--== 1. FLOATING OBSIDIAN OBELISKS & CONSTELLATION BEAMS ==--
	for _, side in ipairs({ -1, 1 }) do
		for i = 0, 5 do
			local z = -7.5 + i * 3.0
			part({
				name = "VoidObelisk",
				size = Vector3.new(0.6, 3.2, 0.6),
				cframe = cf * CFrame.new(side * 4.9, 2.0, z) * CFrame.Angles(0, math.rad(i * 30), 0),
				color = VOID_BLACK,
				material = Enum.Material.SmoothPlastic,
				collide = false,
				parent = model,
			})
			part({
				name = "ObeliskGem",
				size = Vector3.new(0.4, 0.6, 0.4),
				cframe = cf * CFrame.new(side * 4.9, 3.9, z) * CFrame.Angles(0, math.rad(i * 30), 0),
				color = ASTRAL_CYAN,
				material = Enum.Material.Neon,
				collide = false,
				parent = model,
			})
		end
		cylinder({
			name = "ConstellationBeam",
			size = Vector3.new(16.2, 0.25, 0.25),
			cframe = cf * CFrame.new(side * 4.9, 3.2, -0.05) * CFrame.Angles(0, math.rad(90), 0),
			color = ASTRAL_CYAN,
			material = Enum.Material.Neon,
			collide = false,
			parent = model,
		})
	end

	--== 2. GRAND CELESTIAL ASTROLABE ORBIT RINGS & SINGULARITY CORE ==--
	local coreAt = CFrame.new(0, 7.8, -9.4)

	local singularity = part({
		name = "SingularityCore",
		size = Vector3.new(3.2, 3.2, 3.2),
		cframe = cf * coreAt,
		color = NEBULA_PURPLE,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		collide = false,
		parent = model,
	})
	local singLight = Instance.new("PointLight")
	singLight.Brightness = 1.8
	singLight.Range = 16
	singLight.Color = Color3.fromRGB(180, 80, 255)
	singLight.Parent = singularity

	local ringA = cylinder({
		name = "OrbitRingA",
		size = Vector3.new(0.4, 7.8, 7.8),
		cframe = cf * coreAt * CFrame.Angles(0, math.rad(90), 0),
		color = ASTRAL_CYAN,
		material = Enum.Material.Metal,
		collide = false,
		parent = model,
	})
	CollectionService:AddTag(ringA, GameConfig.Tags.MillWheel)

	part({
		name = "OrbitNode",
		size = Vector3.new(1.1, 1.1, 1.1),
		cframe = ringA.CFrame * CFrame.new(0, 3.9, 0),
		color = COSMIC_MAGENTA,
		material = Enum.Material.Neon,
		shape = Enum.PartType.Ball,
		collide = false,
		parent = ringA,
	})

	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "AstrolabeStrut",
			size = Vector3.new(0.6, 8.4, 0.6),
			cframe = cf * CFrame.new(side * 2.2, 4.4, -9.4) * CFrame.Angles(0, 0, math.rad(side * 18)),
			color = VOID_BLACK,
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = model,
		})
	end

	--== 3. HOVERING ANTIMATTER CRYSTAL PYLONS ON FLANKS ==--
	for _, side in ipairs({ -1, 1 }) do
		cylinder({
			name = "MagPedestal",
			size = Vector3.new(1.2, 2.6, 2.6),
			cframe = cf * CFrame.new(side * 6.8, 0.8, 2.0) * CFrame.Angles(0, 0, math.rad(90)),
			color = VOID_BLACK,
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = model,
		})
		part({
			name = "AstralCrystal",
			size = Vector3.new(1.4, 2.8, 1.4),
			cframe = cf * CFrame.new(side * 6.8, 2.8, 2.0) * CFrame.Angles(math.rad(15), math.rad(45), math.rad(side * 15)),
			color = COSMIC_MAGENTA,
			material = Enum.Material.Neon,
			collide = false,
			parent = model,
		})
	end

	--== 4. HOLOGRAPHIC CYBER SCREENS (ACTIVATE WHEN USED) ==--
	local holoFolder = Instance.new("Folder")
	holoFolder.Name = "CyberHolograms"
	holoFolder.Parent = model

	-- Helper to build a cyber screen
	local function makeHoloScreen(props: {
		name: string,
		cf: CFrame,
		size: Vector3,
		title: string,
		subtitle: string,
		isMain: boolean,
	})
		-- Glowing Projector Base Node
		cylinder({
			name = props.name .. "_Projector",
			size = Vector3.new(0.3, 1.2, 1.2),
			cframe = props.cf * CFrame.new(0, -props.size.Y * 0.5 - 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)),
			color = ASTRAL_CYAN,
			material = Enum.Material.Neon,
			collide = false,
			parent = holoFolder,
		})

		-- Holographic Light Emitter Beam
		part({
			name = props.name .. "_Beam",
			size = Vector3.new(props.size.X * 0.8, 1.2, 0.05),
			cframe = props.cf * CFrame.new(0, -props.size.Y * 0.5 - 0.6, 0),
			color = ASTRAL_CYAN,
			material = Enum.Material.Neon,
			transparency = 0.65,
			collide = false,
			parent = holoFolder,
		})

		-- Holographic Screen Pane
		local pane = part({
			name = props.name,
			size = props.size,
			cframe = props.cf,
			color = ASTRAL_CYAN,
			material = Enum.Material.Glass,
			transparency = 0.45,
			collide = false,
			parent = holoFolder,
		})
		CollectionService:AddTag(pane, (GameConfig.Tags and GameConfig.Tags.MillHolo) or "MillHolo")

		-- Corner Neon Cyber Brackets
		for _, cx in ipairs({ -props.size.X * 0.5, props.size.X * 0.5 }) do
			for _, cy in ipairs({ -props.size.Y * 0.5, props.size.Y * 0.5 }) do
				part({
					name = "CyberBracket",
					size = Vector3.new(0.35, 0.35, 0.12),
					cframe = props.cf * CFrame.new(cx, cy, 0),
					color = if props.isMain then COSMIC_MAGENTA else ASTRAL_CYAN,
					material = Enum.Material.Neon,
					collide = false,
					parent = pane,
				})
			end
		end

		-- Double-Sided SurfaceGui Interfaces (Front and Back so visible from every angle)
		for _, face in ipairs({ Enum.NormalId.Back, Enum.NormalId.Front }) do
			local sg = Instance.new("SurfaceGui")
			sg.Name = "CyberHUD_" .. face.Name
			sg.Face = face
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			sg.PixelsPerStud = 55
			sg.LightInfluence = 0
			sg.Parent = pane

			local rootFrame = Instance.new("Frame")
			rootFrame.Size = UDim2.new(1, 0, 1, 0)
			rootFrame.BackgroundColor3 = Color3.fromRGB(8, 20, 36)
			rootFrame.BackgroundTransparency = 0.55
			rootFrame.BorderSizePixel = 0
			rootFrame.Parent = sg

			local stroke = Instance.new("UIStroke")
			stroke.Color = if props.isMain then Color3.fromRGB(0, 240, 255) else Color3.fromRGB(220, 80, 255)
			stroke.Thickness = 2.5
			stroke.Parent = rootFrame

			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 10)
			pad.PaddingRight = UDim.new(0, 10)
			pad.PaddingTop = UDim.new(0, 8)
			pad.PaddingBottom = UDim.new(0, 8)
			pad.Parent = rootFrame

			-- Title Header
			local title = Instance.new("TextLabel")
			title.Size = UDim2.new(1, 0, 0, 24)
			title.BackgroundTransparency = 1
			title.Font = Enum.Font.FredokaOne
			title.Text = props.title
			title.TextColor3 = stroke.Color
			title.TextSize = 14
			title.TextXAlignment = Enum.TextXAlignment.Left
			title.Parent = rootFrame

			-- Status Subtitle
			local status = Instance.new("TextLabel")
			status.Size = UDim2.new(1, 0, 0, 18)
			status.Position = UDim2.new(0, 0, 0, 24)
			status.BackgroundTransparency = 1
			status.Font = Enum.Font.GothamBold
			status.Text = props.subtitle
			status.TextColor3 = Color3.fromRGB(120, 255, 180)
			status.TextSize = 11
			status.TextXAlignment = Enum.TextXAlignment.Left
			status.Parent = rootFrame

			if props.isMain then
				-- Center Big Velocity Readout
				local speedLabel = Instance.new("TextLabel")
				speedLabel.Name = "SpeedVal"
				speedLabel.Size = UDim2.new(1, 0, 0, 36)
				speedLabel.Position = UDim2.new(0, 0, 0, 42)
				speedLabel.BackgroundTransparency = 1
				speedLabel.Font = Enum.Font.FredokaOne
				speedLabel.Text = "160 STUDS/S"
				speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				speedLabel.TextSize = 22
				speedLabel.TextXAlignment = Enum.TextXAlignment.Center
				speedLabel.Parent = rootFrame

				-- Equalizer Waveform Visualizer
				local eqHolder = Instance.new("Frame")
				eqHolder.Name = "EqHolder"
				eqHolder.Size = UDim2.new(0.9, 0, 0, 24)
				eqHolder.Position = UDim2.new(0.05, 0, 0, 78)
				eqHolder.BackgroundTransparency = 1
				eqHolder.Parent = rootFrame

				local barCount = 12
				for b = 1, barCount do
					local bar = Instance.new("Frame")
					bar.Name = "EqBar_" .. b
					bar.Size = UDim2.new(1 / barCount - 0.02, 0, 0.4 + (b % 4) * 0.18, 0)
					bar.Position = UDim2.new((b - 1) / barCount, 0, 1, 0)
					bar.AnchorPoint = Vector2.new(0, 1)
					bar.BackgroundColor3 = Color3.fromHSV((b / barCount) * 0.4 + 0.5, 0.9, 1.0)
					bar.BorderSizePixel = 0
					bar.Parent = eqHolder
				end

				-- Main Hacker Command Line Ticker
				local ticker = Instance.new("TextLabel")
				ticker.Name = "HackerTicker"
				ticker.Size = UDim2.new(1, 0, 0, 24)
				ticker.Position = UDim2.new(0, 0, 1, -26)
				ticker.BackgroundTransparency = 1
				ticker.Font = Enum.Font.Code
				ticker.Text = "> root@cosmos: bypass_gravity --force"
				ticker.TextColor3 = Color3.fromRGB(0, 255, 170)
				ticker.TextSize = 11
				ticker.TextXAlignment = Enum.TextXAlignment.Left
				ticker.Parent = rootFrame
			else
				-- Full Streaming Hacker Terminal Console
				local terminal = Instance.new("TextLabel")
				terminal.Name = "HackerTerminal"
				terminal.Size = UDim2.new(1, 0, 1, -44)
				terminal.Position = UDim2.new(0, 0, 0, 44)
				terminal.BackgroundTransparency = 1
				terminal.Font = Enum.Font.Code
				terminal.Text = if props.name:find("Left")
					then "> INITIATING_QUANTUM_CORE...\n> 0x7F4A :: TACHYON_FLOW = 99.8%\n> BYPASSING_GRAVITY_MATRIX [OK]\n> OVERCLOCKING_DRIVE: 160 STUDS/S\n> [ROOT@COSMOS] sudo inject_flux"
					else "> 0x88B2A90F :: CORE_LOCK [OK]\n> 0x8F 0x3B 0xA1 0xFE 0x00 0x9C\n> 01000001 01010011 01010100\n> DECRYPTING_SECTOR_EPSILON...\n> GRAVITATIONAL_WELL: STABLE"
				terminal.TextColor3 = if props.name:find("Left") then Color3.fromRGB(0, 255, 170) else Color3.fromRGB(0, 230, 255)
				terminal.TextSize = 9.5
				terminal.TextXAlignment = Enum.TextXAlignment.Left
				terminal.TextYAlignment = Enum.TextYAlignment.Top
				terminal.TextWrapped = true
				terminal.Parent = rootFrame
			end
		end

		-- Scanline motes on hologram
		local scanEmitter = Instance.new("ParticleEmitter")
		scanEmitter.Name = "HoloScanlines"
		scanEmitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		scanEmitter.Rate = 12
		scanEmitter.Lifetime = NumberRange.new(0.8, 1.5)
		scanEmitter.Speed = NumberRange.new(1.0, 2.5)
		scanEmitter.SpreadAngle = Vector2.new(10, 10)
		scanEmitter.EmissionDirection = Enum.NormalId.Top
		scanEmitter.LightEmission = 1.0
		scanEmitter.LightInfluence = 0
		scanEmitter.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(0.5, 0.5),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		scanEmitter.Color = ColorSequence.new(Color3.fromRGB(0, 240, 255))
		scanEmitter.Parent = pane
		whenRunning(scanEmitter)
	end

	-- 1. Main Center Hologram HUD (Eye-level in front of runner, angled back 14 deg toward runner)
	makeHoloScreen({
		name = "CenterCyberHUD",
		cf = cf * CFrame.new(0, 5.5, -6.2) * CFrame.Angles(math.rad(14), 0, 0),
		size = Vector3.new(5.4, 3.0, 0.06),
		title = "⚡ ASTRAL QUANTUM DRIVE // T10",
		subtitle = "● WARP SINGULARITY ACTIVE",
		isMain = true,
	})

	-- 2. Left Flank Auxiliary Cyber HUD (Angled 30 deg inward toward runner)
	makeHoloScreen({
		name = "LeftCyberHUD",
		cf = cf * CFrame.new(-3.6, 4.8, -4.4) * CFrame.Angles(math.rad(10), math.rad(30), 0),
		size = Vector3.new(3.6, 2.4, 0.06),
		title = "◈ DIAGNOSTICS",
		subtitle = "● CORE EFFICIENCY 100%",
		isMain = false,
	})

	-- 3. Right Flank Celestial Navigation HUD (Angled -30 deg inward toward runner)
	makeHoloScreen({
		name = "RightCyberHUD",
		cf = cf * CFrame.new(3.6, 4.8, -4.4) * CFrame.Angles(math.rad(10), math.rad(-30), 0),
		size = Vector3.new(3.6, 2.4, 0.06),
		title = "✦ NAV-MATRIX",
		subtitle = "● SECTOR: EPSILON-9",
		isMain = false,
	})

	--== 5. SWIRLING GALAXY NEBULA DUST PARTICLES ==--
	local galaxyDust = Instance.new("ParticleEmitter")
	galaxyDust.Name = "CosmicDust"
	galaxyDust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	galaxyDust.Rate = 18
	galaxyDust.Lifetime = NumberRange.new(2.0, 3.8)
	galaxyDust.Speed = NumberRange.new(1.5, 3.5)
	galaxyDust.SpreadAngle = Vector2.new(180, 180)
	galaxyDust.LightEmission = 1.0
	galaxyDust.LightInfluence = 0
	galaxyDust.Rotation = NumberRange.new(0, 360)
	galaxyDust.RotSpeed = NumberRange.new(-60, 60)
	galaxyDust.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
		NumberSequenceKeypoint.new(0.5, 1.6),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	galaxyDust.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 220, 255)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 60, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 180)),
	})
	galaxyDust.Parent = singularity
	whenRunning(galaxyDust)

	for _, side in ipairs({ -1, 1 }) do
		local strip = part({
			name = "CosmicStrip",
			size = Vector3.new(0.45, 0.3, 16),
			cframe = cf * CFrame.new(side * 4.3, 1.2, 0),
			color = ASTRAL_CYAN,
			material = Enum.Material.Neon,
			collide = false,
			studs = false,
			parent = model,
		})
		CollectionService:AddTag(strip, GameConfig.Tags.MillPulse)
	end
end

local SIGNATURE: { (Signature) -> () } = {
	compostWalk, gardenPath, trellisTrot, millstone, glasshouse, sunwheel, heartroot,
	infernoForge, celestialAscent, astralSingularity,
}

function MillModel.Build(tier: number, cf: CFrame, parent: Instance): (Model, BasePart)
	local index = math.clamp(math.floor(tier), 1, #DRESSING)
	local look = DRESSING[index]
	local currentMill = GameConfig.Mill
	local spec = currentMill.Tiers[index] or { name = 'Tier ' .. index, speed = index * 10, cost = 0, beltStuds = 16 }
	local beltStyle = currentMill.Belt[index] or currentMill.Belt[1]

	local model = Instance.new("Model")
	model.Name = "Mill"
	model:SetAttribute("MillTier", index)
	model.Parent = parent

	local deck = part({
		name = "Deck",
		size = DECK,
		cframe = cf,
		color = look.deck,
		material = look.deckMaterial,
		parent = model,
	})
	model.PrimaryPart = deck

	--==========================================================================
	-- THE BELT KEEPS ITS NAME AND ITS TAG
	--
	-- TreadmillService finds a mill by the tag and matches it to a plot by the
	-- PlotId on the model above it. Renaming either would silently stop the
	-- faucet, so both are set by the caller and this only builds the surface.
	--==========================================================================
	--==========================================================================
	-- THE BELT IS THE ONE SMOOTH THING
	--
	-- Everything else on a mill is studded plastic. The running surface is not,
	-- and deliberately: it is the only part of the machine that MOVES under the
	-- player, and a field of studs is a fixed pattern -- it reads as a floor
	-- exactly when the belt most needs to read as a moving band. It would also
	-- fight whatever goes on this belt tier by tier, which is the whole reason
	-- the surface is being kept clear.
	--
	-- Smooth is also just what a belt is. Nothing else gets this exemption.
	--==========================================================================
	local belt = part({
		name = PLOT.TreadmillName,
		size = BELT,
		cframe = cf * CFrame.new(0, 0.4, 0),
		color = look.belt,
		material = look.beltMaterial or (if beltStyle.Neon then Enum.Material.Neon else Enum.Material.SmoothPlastic),
		studs = false,
		parent = model,
	})

	-- Rollers at both ends. They do not turn on the server -- Ambience spins
	-- them client-side off the same belt speed the chevrons use.
	for _, side in ipairs({ -1, 1 }) do
		--======================================================================
		-- A ROBLOX CYLINDER POINTS ALONG ITS OWN X, AND NOTHING ELSE
		--
		-- Size is (length, diameter, diameter) with the flat faces on X. The
		-- first pass wrote (1.6, 8.4, 1.6) and then rotated it upright, which
		-- built a 1.6-long roller 8.4 across standing on its end in the middle
		-- of the belt -- a stump, not a roller.
		--
		-- Length across the belt, no rotation. That also puts the spin axis
		-- where Ambience already turns it: about the part's own X.
		--======================================================================
		local roller = cylinder({
			name = "Roller",
			size = Vector3.new(BELT.X + 0.4, 1.5, 1.5),
			cframe = cf * CFrame.new(0, 0.6, side * (BELT.Z * 0.5)),
			color = look.roller,
			material = look.railMaterial,
			collide = false,
			parent = model,
		})
		CollectionService:AddTag(roller, GameConfig.Tags.MillRoller)
	end

	--==========================================================================
	-- THE ARROWS, AND THE THREE NUMBERS THEY CARRY
	--
	-- Span, index and count are stamped on every arm here because Ambience
	-- cannot know a belt's length or how many arrows share it without being
	-- told, and must not measure geometry on a Heartbeat to find out. Everything
	-- the client does to a belt -- the wrap, the chase, the fade at the ends --
	-- is arithmetic on these three.
	--
	-- Both arms of a pair carry the SAME index, so a chevron lights as one V
	-- rather than as two independent sticks.
	--==========================================================================
	local arrowCount = beltStyle.Arrows or 0
	if arrowCount > 0 then
		local chevronHolder = Instance.new("Folder")
		chevronHolder.Name = "Chevrons"
		chevronHolder.Parent = belt

		for i = 1, arrowCount do
			local z = ((i - 1) / arrowCount) * BELT.Z - BELT.Z * 0.5
			for _, side in ipairs({ -1, 1 }) do
				local arm = part({
					name = "Chevron",
					size = Vector3.new(3.2, 0.24, 0.9),
					cframe = cf * CFrame.new(side * 1.5, 1.15, z)
						* CFrame.Angles(0, math.rad(side * 28), 0),
					color = look.chevron,
					-- Painted on the belt, so it is finished like the belt --
					-- until the top tiers, where the arrows stop being paint and
					-- start being the light source.
					material = if beltStyle.Neon
						then Enum.Material.Neon
						else Enum.Material.SmoothPlastic,
					studs = false,
					collide = false,
					parent = chevronHolder,
				})
				arm:SetAttribute("ChevronSpan", BELT.Z)
				arm:SetAttribute("ChevronIndex", i)
				arm:SetAttribute("SlatCount", arrowCount)
				CollectionService:AddTag(arm, GameConfig.Tags.MillChevron)
			end
		end
	end

	--==========================================================================
	-- THE BANDS, WHICH ARE HOW A BELT IS ACTUALLY A RAINBOW
	--
	-- Flat strips lying flush on the plate, a hair below the arrows so the
	-- arrows still read on top of them. They ride the same tag and the same
	-- scroll as everything else on a belt, and the client gives each one its hue
	-- from where it currently IS -- so the spectrum stays laid out in the world
	-- while the strips travel through it. That is what a moving rainbow looks
	-- like; hue keyed to the strip instead gives coloured sticks going round,
	-- which is the version that looks cheap.
	--
	-- Flagged, because a band lies ON the surface and must never take the bob or
	-- the rake the arrows do. A band that lifted off the belt would stop being
	-- part of it.
	--==========================================================================
	local bandCount = beltStyle.Bands or 0
	if bandCount > 0 then
		local bandHolder = Instance.new("Folder")
		bandHolder.Name = "Bands"
		bandHolder.Parent = belt

		for i = 1, bandCount do
			local z = ((i - 1) / bandCount) * BELT.Z - BELT.Z * 0.5
			local band = part({
				name = "Band",
				size = Vector3.new(BELT.X - 0.4, 0.08, BELT.Z / bandCount * 0.82),
				cframe = cf * CFrame.new(0, 1.11, z),
				color = look.belt,
				material = if beltStyle.Neon
					then Enum.Material.Neon
					else Enum.Material.SmoothPlastic,
				studs = false,
				collide = false,
				parent = bandHolder,
			})
			band:SetAttribute("ChevronSpan", BELT.Z)
			band:SetAttribute("ChevronIndex", i)
			band:SetAttribute("SlatCount", bandCount)
			band:SetAttribute("BeltBand", true)
			CollectionService:AddTag(band, GameConfig.Tags.MillSlat)
		end
	end

	local slatCount = look.slats or 0
	if slatCount > 0 then
		local slatHolder = Instance.new("Folder")
		slatHolder.Name = "Slats"
		slatHolder.Parent = belt

		for i = 1, slatCount do
			local z = ((i - 1) / slatCount) * BELT.Z - BELT.Z * 0.5
			local slat = part({
				name = "Slat",
				size = Vector3.new(BELT.X - 0.5, 0.34, BELT.Z / slatCount * 0.62),
				cframe = cf * CFrame.new(0, 1.16, z),
				color = look.belt:Lerp(Color3.new(0, 0, 0), 0.30),
				-- Part of the running surface, so smooth with the belt it rides.
				material = Enum.Material.SmoothPlastic,
				studs = false,
				collide = false,
				parent = slatHolder,
			})
			slat:SetAttribute("ChevronSpan", BELT.Z)
			slat:SetAttribute("ChevronIndex", i)
			slat:SetAttribute("SlatCount", slatCount)
			CollectionService:AddTag(slat, GameConfig.Tags.MillSlat)
		end
	end

	--==========================================================================
	-- THE FRAME AROUND IT
	--
	-- Skirts down the long sides with bolts in them, and braces at the corners.
	-- The old mill was a slab with a belt on it and nothing explaining how the
	-- two were attached; this is the answer to that, and it is what gives the
	-- silhouette a middle rather than just a top and a bottom.
	--==========================================================================
	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "Skirt",
			size = Vector3.new(0.6, 1.5, DECK.Z - 1),
			cframe = cf * CFrame.new(side * (DECK.X * 0.5 - 0.3), 0.15, 0),
			color = look.rail,
			material = look.railMaterial,
			collide = false,
			parent = model,
		})
		for _, z in ipairs({ -6.5, -2.2, 2.2, 6.5 }) do
			part({
				name = "Bolt",
				size = Vector3.new(0.34, 0.5, 0.5),
				cframe = cf * CFrame.new(side * (DECK.X * 0.5 - 0.1), 0.3, z),
				color = look.roller,
				material = look.railMaterial,
				collide = false,
				parent = model,
			})
		end
		for _, z in ipairs({ -1, 1 }) do
			part({
				name = "Brace",
				size = Vector3.new(0.5, 0.5, 2.6),
				cframe = cf * CFrame.new(side * 4.7, -0.2, z * 8.2)
					* CFrame.Angles(math.rad(z * 34), 0, 0),
				color = look.rail,
				material = look.railMaterial,
				collide = false,
				parent = model,
			})
		end
	end

	--==========================================================================
	-- THE CONSOLE
	--
	-- Angled up at whoever is standing on it, because that is the one surface a
	-- player looks straight at while they train. Its face is the tier's colour:
	-- the quickest read of which mill you are on, from on top of it, where you
	-- cannot see the sign.
	--==========================================================================
	part({
		name = "ConsolePost",
		size = Vector3.new(0.6, 3.2, 0.6),
		cframe = cf * CFrame.new(0, 2.2, -8.4),
		color = look.rail,
		material = look.railMaterial,
		collide = false,
		parent = model,
	})
	local console = part({
		name = "Console",
		size = Vector3.new(5.6, 0.5, 2.4),
		cframe = cf * CFrame.new(0, 3.9, -8.4) * CFrame.Angles(math.rad(-34), 0, 0),
		color = look.rail,
		material = look.railMaterial,
		collide = false,
		parent = model,
	})
	-- Smaller than it started. At 4.4 by 1.4 in neon it was the brightest thing
	-- on the plot and it sat dead centre of the machine, which put a white slab
	-- where the belt should be reading.
	local readout = part({
		name = "Readout",
		size = Vector3.new(3.4, 0.14, 0.95),
		cframe = console.CFrame * CFrame.new(0, 0.33, 0),
		color = look.console,
		-- Lit on the tiers whose BELTS are lit, read off the one ladder rather
		-- than a second flag here. Two places to say "this tier glows" is two
		-- places for it to stop agreeing.
		material = if beltStyle.Neon
			then Enum.Material.Neon
			else Enum.Material.SmoothPlastic,
		collide = false,
		studs = false,
		parent = model,
	})
	if beltStyle.Neon then
		CollectionService:AddTag(readout, GameConfig.Tags.MillPulse)
	end

	--==========================================================================
	-- NO TEXT ON THE MACHINE
	--
	-- This carried a SurfaceGui reading "+N/s". It was a floating white card in
	-- front of every mill and it was the wrong answer to the right question --
	-- the rate belongs on the SIGN, which is a board on a post and exists to be
	-- read. A console is an instrument; it can be a coloured face without
	-- spelling anything.
	--==========================================================================

	-- A step at the back, so getting on is a step up rather than a hop.
	part({
		name = "Step",
		size = Vector3.new(6.5, 0.7, 2.2),
		cframe = cf * CFrame.new(0, -0.5, 10.4),
		color = look.deck,
		material = look.deckMaterial,
		parent = model,
	})

	--==========================================================================
	-- AND THEN THE PART THAT MAKES IT THIS MILL
	--
	-- Everything above is chassis: a deck, a belt that moves, a frame holding
	-- the two together, somewhere to stand and something to read. Every mill in
	-- the game needs all of it and none of it tells one tier from another.
	--
	-- Everything a player actually recognises a mill BY -- its rail, its
	-- silhouette, the big thing on the side of it -- is below, and it is a
	-- different function per tier. Including the rails: a handrail is at eye
	-- level for somebody standing on the belt, so seven identical ones was seven
	-- chances to notice these were all the same machine.
	--==========================================================================
	SIGNATURE[index]({ cf = cf, model = model, deck = deck, belt = belt, look = look })

	model:SetAttribute("MillSpeed", spec.speed)
	model:SetAttribute("MillName", spec.name)
	return model, belt
end

--==============================================================================
-- THE UPGRADE SIGN
--
-- A post and a board beside the mill, not a floating panel. The layout is the
-- reference's -- a title, the step you are buying, and one big price button --
-- and the dressing is this game's: planks, studs, LuckiestGuy with a black
-- stroke, the same face the rest of the HUD uses.
--
-- The Robux button in the reference is NOT here. This place has no Developer
-- Products, and a button that takes a currency the game cannot charge is worse
-- than no button. Cash works end to end; that is the whole purchase path.
--
-- The FACE is a SurfaceGui rather than a BillboardGui: a billboard turns to
-- follow you, which is right for a floating readout and wrong for a board
-- nailed to a post. This one has a back and you can walk behind it.
--==============================================================================
export type SignFace = {
	title: TextLabel,
	step: TextLabel,
	rate: TextLabel,
	price: TextLabel,
	button: Frame,
	prompt: ProximityPrompt,
}

local function label(parent: Instance, name: string, size: number,
	colour: Color3): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.LuckiestGuy
	t.TextSize = size
	t.TextColor3 = colour
	t.TextScaled = false
	t.Text = ""
	t.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(0, 0, 0)
	stroke.Thickness = 2.5
	stroke.Parent = t
	return t
end

function MillModel.BuildSign(cf: CFrame, parent: Instance): (Model, SignFace)
	local model = Instance.new("Model")
	model.Name = "MillSign"
	model.Parent = parent

	--==========================================================================
	-- ONE SCALAR, APPLIED TO EVERY SIZE AND EVERY OFFSET
	--
	-- Sizes AND positions, because they are the same fact: a board at three
	-- quarters that still floats at its old height is a board that has come off
	-- its post. See GameConfig.Mill.Sign.Scale.
	--==========================================================================
	local S = MILL.Sign.Scale

	--==========================================================================
	-- NOTHING CATCHES A RUNNER, AND THAT NOW INCLUDES THIS
	--
	-- The post and the board were both solid, which did not matter while the
	-- sign stood off to one side -- the map's own note said it was "far enough
	-- out that it is not something you catch with a shoulder getting on". At the
	-- FRONT of the mill it is in the walking line, and the board sits between
	-- 2.9 and 7.2 studs up: chest to overhead on a five-stud character. Solid,
	-- that is a wall across the way in to your own machine.
	--
	-- The field's rule is that nothing catches a runner -- the fence is
	-- non-collidable for exactly this reason, and MapService calls the one
	-- collidable prop out as "the exception". A sign is signage. You read it and
	-- hold E at it; you never need to bump into it.
	--==========================================================================
	local post = part({
		name = "Post",
		size = Vector3.new(0.8, 5.2, 0.8) * S,
		cframe = cf * CFrame.new(0, 2.6 * S, 0),
		color = OAK_DARK,
		material = Enum.Material.Wood,
		collide = false,
		parent = model,
	})
	model.PrimaryPart = post

	local board = part({
		name = "Board",
		size = Vector3.new(9, 5.6, 0.6) * S,
		cframe = cf * CFrame.new(0, 7.4 * S, 0),
		-- Dark enough for white type to sit on, warm enough to be a plank
		-- rather than a hole cut in the world.
		color = Color3.fromRGB(72, 54, 40),
		material = Enum.Material.WoodPlanks,
		-- See the post above: signage, in the walking line, at chest height.
		collide = false,
		parent = model,
	})

	-- Four bolts, because the reference board has them and they are what stops a
	-- dark rectangle reading as a hole.
	for _, corner in ipairs({ Vector3.new(-3.9, 2.2, 0), Vector3.new(3.9, 2.2, 0),
		Vector3.new(-3.9, -2.2, 0), Vector3.new(3.9, -2.2, 0) }) do
		part({
			name = "Bolt",
			size = Vector3.new(0.5, 0.5, 0.7) * S,
			cframe = cf * CFrame.new(0, 7.4 * S, 0) * CFrame.new(corner * S),
			color = OAK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
	end

	--==========================================================================
	-- LETTERED ON BOTH FACES
	--
	-- The two people who need this board are on OPPOSITE SIDES of it. Somebody
	-- walking up from their own gate is at (-35, -27) in the mill's frame; a
	-- player standing on the belt is at (0, 0); and the sign is between them.
	-- Those bearings are 178 degrees apart, so no single facing serves both --
	-- pointing it at the approach shows its back to the belt, and pointing it at
	-- the belt hides it behind the mill from everywhere else.
	--
	-- The biome arches already solved this: "Named on BOTH faces. You read it
	-- going out, and going home it tells you how much further there is to run."
	-- Same answer here. The board is 0.46 studs thick and a SurfaceGui costs
	-- nothing to leave on the other side of it.
	--
	-- BOTH ARE RETURNED, and refreshSign writes to both -- a back face that
	-- silently stopped updating would be a board advertising last hour's price
	-- to everybody standing on the machine.
	--==========================================================================
	local function buildFace(which: Enum.NormalId): SignFace
		local surface = Instance.new("SurfaceGui")
		surface.Name = if which == Enum.NormalId.Front then "Face" else "FaceBack"
		surface.Face = which
		surface.CanvasSize = Vector2.new(360, 224)
		surface.LightInfluence = 0
		surface.MaxDistance = 90
		surface.Parent = board

		local title = label(surface, "Title", 34, Color3.fromRGB(255, 255, 255))
		title.Size = UDim2.new(1, 0, 0, 44)
		title.Position = UDim2.fromOffset(0, 8)
		title.Text = "UPGRADE"

		local step = label(surface, "Step", 26, Color3.fromRGB(142, 214, 86))
		step.Size = UDim2.new(1, 0, 0, 34)
		step.Position = UDim2.fromOffset(0, 54)

		local rate = label(surface, "Rate", 20, Color3.fromRGB(226, 214, 176))
		rate.Size = UDim2.new(1, 0, 0, 28)
		rate.Position = UDim2.fromOffset(0, 88)

		local button = Instance.new("Frame")
		button.Name = "Buy"
		button.AnchorPoint = Vector2.new(0.5, 0)
		button.Position = UDim2.new(0.5, 0, 0, 126)
		button.Size = UDim2.fromOffset(300, 74)
		button.BackgroundColor3 = Color3.fromRGB(214, 78, 66)
		button.BorderSizePixel = 0
		button.Parent = surface
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = button
		local edge = Instance.new("UIStroke")
		edge.Color = Color3.new(0, 0, 0)
		edge.Thickness = 4
		edge.Parent = button

		local price = label(button, "Price", 32, Color3.fromRGB(255, 255, 255))
		price.Size = UDim2.fromScale(1, 1)
		price.Position = UDim2.fromOffset(0, 2)

		return {
			title = title, step = step, rate = rate,
			price = price, button = button, prompt = nil :: any,
		}
	end

	local front = buildFace(Enum.NormalId.Front)
	buildFace(Enum.NormalId.Back)
	local title, step, rate = front.title, front.step, front.rate
	local price, button = front.price, front.button

	--==========================================================================
	-- ONE PROMPT, DRAWN BY PromptUI LIKE EVERY OTHER PROMPT
	--
	-- Style Custom because that is the rule in this game -- PromptUI draws them
	-- all -- and a prompt rather than a ClickDetector because a prompt works
	-- with a thumb on a phone without any extra code.
	--==========================================================================
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "UpgradePrompt"
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.ActionText = "Upgrade"
	prompt.ObjectText = "Mill"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.HoldDuration = 0.35
	-- Reaches the belt: the sign moved to the fence line and is 15.3 studs from
	-- where a mounted player stands, and the mount holds them at WalkSpeed zero.
	prompt.MaxActivationDistance = MILL.Sign.PromptRange
	prompt.RequiresLineOfSight = false
	prompt.Parent = board

	CollectionService:AddTag(model, GameConfig.Tags.MillSign)

	return model, {
		title = title,
		step = step,
		rate = rate,
		price = price,
		button = button,
		prompt = prompt,
	}
end

return MillModel
