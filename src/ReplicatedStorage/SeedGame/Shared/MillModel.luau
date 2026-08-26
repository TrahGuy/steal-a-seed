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
	-- 7. Heartroot -- the machine has gone green. Living wood, a lit core, and a
	-- ring of leaves that never lands.
	{
		deck = HEART, deckMaterial = Enum.Material.Grass,
		belt = LEAF, chevron = HEART,
		rail = HEART, railMaterial = Enum.Material.Grass,
		roller = GOLD,
		slats = 0, console = HEART,
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

	--==========================================================================
	-- THE TUNNEL
	--
	-- Four ribs, seven segments each. Seven is where a boxy arc stops having
	-- corners you can count from the belt -- five reads as a hexagon, and nine
	-- costs twenty-eight parts across the tier for a curve nobody gets closer to.
	--==========================================================================
	--
	-- TIMBER, NOT GREEN TIMBER. The tier's rail colour is STEM, and ribs in STEM
	-- under ivy in LEAF under sprigs in STEM gave one green mass with no read at
	-- all. A trellis has to be a DIFFERENT material from the thing growing on
	-- it, or there is no "growing on" to see.
	for _, z in ipairs({ -7.4, -2.6, 2.2, 7 }) do
		arc(model, cf, z, 5.3, 0.7, 7, 0.45, OAK_DARK, Enum.Material.Wood, "Rib")
	end
	-- Stringers tying the ribs together, at the crown and at both shoulders.
	for _, a in ipairs({ math.rad(38), math.rad(90), math.rad(142) }) do
		part({
			name = "Stringer",
			size = Vector3.new(0.34, 0.34, 15.2),
			cframe = cf * CFrame.new(math.cos(a) * 5.3, 0.7 + math.sin(a) * 5.3, -0.2),
			color = OAK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
	end

	--==========================================================================
	-- THE IVY, WHICH IS THE PART THAT MOVES
	--
	-- Hung off the ribs and tagged as cloth, so it sways on its own slow cycle
	-- rather than the belt's. A garden moves because there is weather, not
	-- because somebody is training -- and on a tier with no machinery at all,
	-- this is the only motion the mill has when it is empty.
	--==========================================================================
	for _, hang in ipairs({
		{ -4.3, 4, -7.4 }, { 3.1, 5, -2.6 }, { -2.2, 5.6, 2.2 },
		{ 4.6, 3.4, 7 }, { 0.6, 6, -7.4 }, { -4.9, 3, 2.2 },
	}) do
		local vine = part({
			name = "Ivy",
			size = Vector3.new(1.3, 2.2, 0.5),
			cframe = cf * CFrame.new(hang[1], hang[2], hang[3])
				* CFrame.Angles(0, math.rad(hang[1] * 8), 0),
			color = if hang[2] > 5 then MOSS else LEAF,
			material = Enum.Material.Grass,
			collide = false,
			parent = model,
		})
		vine:SetAttribute("SwaySide", if hang[1] < 0 then -1 else 1)
		CollectionService:AddTag(vine, GameConfig.Tags.MillBanner)
	end
	-- Vines climbing the rope posts, which is how the ivy got up there.
	for _, side in ipairs({ -1, 1 }) do
		for i = 1, 3 do
			part({
				name = "Climber",
				size = Vector3.new(0.7, 0.7, 0.7),
				cframe = cf * CFrame.new(side * 5.1, 0.9 + i * 0.9, -7.6)
					* CFrame.Angles(0, math.rad(i * 40), 0),
				color = STEM,
				material = Enum.Material.Grass,
				collide = false,
				parent = model,
			})
		end
	end

	-- Long troughs instead of tier 2's corner boxes: the planting followed the
	-- tunnel and became a run down both sides.
	for _, side in ipairs({ -1, 1 }) do
		part({
			name = "Trough",
			size = Vector3.new(1.5, 1.1, 7.4),
			cframe = cf * CFrame.new(side * 6.7, 0.55, 3),
			color = OAK_DARK,
			material = Enum.Material.WoodPlanks,
			collide = false,
			parent = model,
		})
		part({
			name = "TroughSoil",
			size = Vector3.new(1.2, 0.3, 7),
			cframe = cf * CFrame.new(side * 6.7, 1.2, 3),
			color = EARTH,
			material = Enum.Material.Ground,
			collide = false,
			parent = model,
		})
		for i = 0, 3 do
			part({
				name = "Sprig",
				size = Vector3.new(0.8, 1.2, 0.8),
				cframe = cf * CFrame.new(side * 6.7, 1.8, 0.2 + i * 1.9)
					* CFrame.Angles(0, math.rad(i * 30), 0),
				color = LEAF,
				material = Enum.Material.Grass,
				collide = false,
				parent = model,
			})
		end
	end
end

--==============================================================================
-- 4. MILLSTONE -- it stopped being furniture
--
-- The first tier that is MACHINERY, and the way you say that is mass. A grinding
-- stone four studs across on the right-hand side, a gantry and a hopper feeding
-- it, a gear train on the left turning against itself.
--
-- Specifically NOT a paddle wheel. A paddle wheel is a water mill, this game has
-- no river, and the old build put the same one on this tier and the three above
-- it -- which is how four different mills ended up being one mill you could buy
-- four times. A millstone is what a mill called Millstone has.
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

	-- White metal balustrade, inside the glazing.
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

	--==========================================================================
	-- THE GABLE
	--
	-- Ridge, rafters, and a pane per slope per half. The rafters are what make
	-- the glass read as glazed rather than as two floating sheets -- a pane with
	-- no frame is a window in nothing.
	--==========================================================================
	part({
		name = "Ridge",
		size = Vector3.new(0.6, 0.6, 19.4),
		cframe = cf * CFrame.new(0, 8.6, 0),
		color = look.rail,
		material = Enum.Material.SmoothPlastic,
		collide = false,
		parent = model,
	})
	for _, side in ipairs({ -1, 1 }) do
		local ang = math.atan2(3.2, -side * 5.4)
		part({
			name = "EaveBeam",
			size = Vector3.new(0.45, 0.45, 19.4),
			cframe = cf * CFrame.new(side * 5.4, 5.4, 0),
			color = look.rail,
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = model,
		})
		for _, z in ipairs({ -9.2, -4.6, 0, 4.6, 9.2 }) do
			part({
				name = "Rafter",
				size = Vector3.new(6.4, 0.32, 0.32),
				cframe = cf * CFrame.new(side * 2.7, 7, z) * CFrame.Angles(0, 0, ang),
				color = look.rail,
				material = Enum.Material.SmoothPlastic,
				collide = false,
				parent = model,
			})
		end
		for _, z in ipairs({ -4.75, 4.75 }) do
			part({
				name = "RoofPane",
				size = Vector3.new(6.3, 0.12, 9.3),
				cframe = cf * CFrame.new(side * 2.7, 7, z) * CFrame.Angles(0, 0, ang),
				color = GLASS,
				material = Enum.Material.Glass,
				transparency = 0.58,
				collide = false,
				studs = false,
				parent = model,
			})
		end
		for _, corner in ipairs({ -9.2, 9.2 }) do
			part({
				name = "CornerPost",
				size = Vector3.new(0.45, 4.9, 0.45),
				cframe = cf * CFrame.new(side * 5.4, 3, corner),
				color = look.rail,
				material = Enum.Material.SmoothPlastic,
				collide = false,
				parent = model,
			})
		end
		part({
			name = "SidePane",
			size = Vector3.new(0.14, 4.4, 18.4),
			cframe = cf * CFrame.new(side * 5.42, 3.2, 0),
			color = GLASS,
			material = Enum.Material.Glass,
			transparency = 0.6,
			collide = false,
			studs = false,
			parent = model,
		})
		for _, z in ipairs({ -6.2, -2.1, 2.1, 6.2 }) do
			part({
				name = "GlazingBar",
				size = Vector3.new(0.22, 4.4, 0.22),
				cframe = cf * CFrame.new(side * 5.42, 3.2, z),
				color = look.rail,
				material = Enum.Material.SmoothPlastic,
				collide = false,
				parent = model,
			})
		end
	end

	-- Two roof lights propped open on the sunny slope. The prop is one part and
	-- it is the difference between a vent and a crooked pane.
	for _, z in ipairs({ -3.6, 3.6 }) do
		part({
			name = "RoofVent",
			size = Vector3.new(3, 0.12, 3.4),
			cframe = cf * CFrame.new(-1.9, 8.3, z) * CFrame.Angles(0, 0, math.rad(8)),
			color = GLASS,
			material = Enum.Material.Glass,
			transparency = 0.5,
			collide = false,
			studs = false,
			parent = model,
		})
		part({
			name = "VentStay",
			size = Vector3.new(0.16, 1.4, 0.16),
			cframe = cf * CFrame.new(-3.2, 7.7, z) * CFrame.Angles(0, 0, math.rad(22)),
			color = look.rail,
			material = Enum.Material.SmoothPlastic,
			collide = false,
			parent = model,
		})
	end

	--==========================================================================
	-- BASKETS, WHICH ARE THE REASON TO HAVE A ROOF
	--==========================================================================
	for _, z in ipairs({ -5.4, 0, 5.4 }) do
		part({
			name = "BasketChain",
			size = Vector3.new(0.12, 1.9, 0.12),
			cframe = cf * CFrame.new(0, 7.5, z),
			color = look.rail,
			material = Enum.Material.Metal,
			collide = false,
			parent = model,
		})
		cylinder({
			name = "Basket",
			size = Vector3.new(1, 2.1, 2.1),
			cframe = cf * CFrame.new(0, 6.2, z) * CFrame.Angles(0, 0, math.rad(90)),
			color = OAK_DARK,
			material = Enum.Material.Wood,
			collide = false,
			parent = model,
		})
		for i = 1, 4 do
			local a = (i / 4) * math.pi * 2
			part({
				name = "Trailer",
				size = Vector3.new(0.7, 1.6, 0.7),
				cframe = cf * CFrame.new(0, 5.4, z) * CFrame.Angles(0, a, 0)
					* CFrame.new(0, 0, -0.75),
				color = if i % 2 == 0 then LEAF else MOSS,
				material = Enum.Material.Grass,
				collide = false,
				parent = model,
			})
		end
	end

	--==========================================================================
	-- VENTS THAT ONLY BREATHE UNDER LOAD
	--
	-- Built here and switched on by the client when the belt speeds up, so an
	-- occupied mill is doing something an empty one is not. A ParticleEmitter
	-- costs one instance and no per-frame work.
	--==========================================================================
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

	--==========================================================================
	-- AND THE AIR INSIDE IT
	--
	-- The vents say the machine is working. This says the ROOM is: a slow warm
	-- haze gathering under the glass, which is the only thing on this tier that
	-- uses the fact that tier 5 is the one you go inside.
	--==========================================================================
	local air = shell(model, cf, Vector3.new(0, 6.5, 0), Vector3.new(8.4, 2.4, 16.5), "GlassAir")
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
	-- Stays the faintest thing on any mill. It is the ROOM being warm, not the
	-- machine working, and the vents two studs away are already saying the loud
	-- half of that.
	haze.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.35, 0.66),
		NumberSequenceKeypoint.new(1, 1),
	})
	haze.Color = ColorSequence.new(Color3.fromRGB(236, 250, 240))
	haze.Parent = air
	whenRunning(haze)

	local lamp = part({
		name = "Lamp",
		size = Vector3.new(1.3, 1.3, 1.3),
		cframe = cf * CFrame.new(0, 7.3, -8.2),
		color = CREAM,
		material = Enum.Material.Neon,
		collide = false,
		parent = model,
	})
	local light = Instance.new("PointLight")
	light.Brightness = 0.9
	light.Range = 12
	light.Color = Color3.fromRGB(255, 236, 190)
	light.Parent = lamp

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
-- 6. SUNWHEEL -- gilded
--
-- One enormous disc, standing on its own A-frame directly behind the console --
-- which is to say, in the face of whoever is on the belt. Nothing else on the
-- mill is allowed to compete with it: the ribs are thin, the rails are fine, and
-- the disc is nine studs across.
--
-- It is round and so is tier 4's millstone, and they are not confusable: one is
-- grey rock lying against the right flank at head height, the other is gold neon
-- eleven studs up at the far end. Same primitive, opposite reading.
--==============================================================================
local function sunwheel(s: Signature)
	local cf, model, look = s.cf, s.model, s.look

	-- Turned balusters: a shaft with a bead on it. Two parts each instead of
	-- one is what separates gilt from a gold-painted fence.
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

	--==========================================================================
	-- THE SUN
	--==========================================================================
	local hubAt = CFrame.new(0, 11.2, -9.6) * CFrame.Angles(0, math.rad(90), 0)
	-- Solid metal, not neon. The face is what gives the disc an EDGE, and an
	-- edge is the entire reason a nine-stud circle reads as a sun.
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
	-- The glow lives in the middle and in the rays, where it has something dark
	-- to be bright against.
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

	-- Slim gilt ribs. Thinner than the tier-3 pergola on purpose: at this tier
	-- the arches are jewellery, not structure.
	for _, z in ipairs({ -3, 2.4, 7.4 }) do
		arc(model, cf, z, 5.2, 0.8, 6, 0.32, GOLD, Enum.Material.Metal, "GiltRib")
	end
	for _, side in ipairs({ -1, 1 }) do
		local banner = part({
			name = "Banner",
			size = Vector3.new(0.22, 3.2, 2),
			cframe = cf * CFrame.new(side * 4.5, 3.8, 2.4),
			color = GOLD,
			material = Enum.Material.Fabric,
			collide = false,
			parent = model,
		})
		banner:SetAttribute("SwaySide", side)
		CollectionService:AddTag(banner, GameConfig.Tags.MillBanner)
	end

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

	-- Urns at the entry, because a gilded thing has an entrance.
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

	--==========================================================================
	-- SPARKS OFF THE SUN, AND MOTES UP THE FLANKS
	--
	-- The sparks live ON the disc, so they come off the thing that is turning
	-- rather than out of the air near it. The motes are the rehearsal for tier
	-- 7: one colour, two sides, and half the rate -- so that when the rainbow
	-- arrives it arrives as MORE of something the player has already seen and
	-- not as a different game.
	--==========================================================================
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
-- 7. HEARTROOT -- the machine went alive
--
-- A tree has grown up through the left flank, thrown a branch across the belt,
-- and roofed the whole thing in canopy. The mill is still under there; it is no
-- longer the thing you notice first.
--
-- This is the only tier with an ASYMMETRIC silhouette, and that is what buys the
-- top of the ladder. Every mill below it is a mirror down the centreline, which
-- is what "manufactured" looks like. Growth is not symmetrical, and after six
-- machines that are, one that is not reads as a different KIND of object rather
-- than a more expensive one.
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

local SIGNATURE: { (Signature) -> () } = {
	compostWalk, gardenPath, trellisTrot, millstone, glasshouse, sunwheel, heartroot,
}

function MillModel.Build(tier: number, cf: CFrame, parent: Instance): (Model, BasePart)
	local index = math.clamp(math.floor(tier), 1, #DRESSING)
	local look = DRESSING[index]
	local spec = MILL.Tiers[index]
	local beltStyle = MILL.Belt[index] or MILL.Belt[1]

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
		material = Enum.Material.SmoothPlastic,
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

	local post = part({
		name = "Post",
		size = Vector3.new(0.8, 5.2, 0.8) * S,
		cframe = cf * CFrame.new(0, 2.6 * S, 0),
		color = OAK_DARK,
		material = Enum.Material.Wood,
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
