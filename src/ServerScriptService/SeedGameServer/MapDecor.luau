--!strict
-- Steal a Seed :: MapDecor
--
-- Dresses the map. MapService decides where the road IS; this decides what
-- grows beside it.
--
-- NOT NAMED "*Service" ON PURPOSE. ServerMain auto-requires and starts every
-- ModuleScript in this folder whose name ends in Service. This is a helper with
-- no lifecycle of its own -- MapService calls it during its own Init -- so it
-- must stay outside that convention. Same reason the previous project called
-- its ore builder `OreModelFactory` rather than `OreService`.
--
--==============================================================================
-- THREE RULES, ALL OF THEM LOAD-BEARING
--
-- 1. NOTHING IS COLLIDABLE. Every prop here is CanCollide = false, CanTouch =
--    false, CanQuery = false. A player sprinting home at WalkSpeed 150 who
--    catches on a mushroom has been robbed by the scenery, and in a game whose
--    entire tension is a chase, that is not a small bug. It is the same reason
--    the plot fences are non-collidable.
--
--    Decoration that blocks is a DESIGN decision for a later phase, made
--    deliberately, prop by prop -- not something that happens because a builder
--    forgot a flag.
--
-- 2. HEIGHT FALLS OFF TOWARD THE CENTRE. Tall props only near the walls; the
--    middle of the road gets ground cover and nothing else. Being able to stand
--    at the red line and see all five biomes receding is the entire progression
--    display -- it is WHY the map is one corridor -- and a row of trees down the
--    middle deletes it.
--
-- 3. PLACEMENT IS DETERMINISTIC. Every scatter runs off a Random seeded from
--    the biome's own name, so every server in the game builds the identical
--    world. `math.random` would give each server its own map, which breaks
--    "the third pod past the big mushroom" as a thing anybody can say.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))

local MapDecor = {}

local MAP = GameConfig.Map
local Y = MAP.GroundY

--==============================================================================
-- THE PART HELPER
--
-- Deliberately a second one rather than sharing MapService's. Its defaults are
-- the inverse: solid and studded there, because that is the world; ghostly and
-- smooth here, because this is dressing. Sharing one helper would mean every
-- call site here passing three flags and one day forgetting.
--==============================================================================
local function prop(parent: Instance, name: string, size: Vector3, cf: CFrame,
	color: Color3, material: Enum.Material?): BasePart
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Plastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function ball(parent: Instance, name: string, size: Vector3, cf: CFrame,
	color: Color3, material: Enum.Material?): BasePart
	local p = prop(parent, name, size, cf, color, material)
	p.Shape = Enum.PartType.Ball
	return p
end

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
-- THE PROPS
--
-- Every one is a handful of boxes and balls. Blocky and studded is the brief,
-- and it is also what keeps a five-biome map inside a mobile part budget.
--==============================================================================

-- Trunk plus two or three offset leaf clusters. The offsets are what stop a row
-- of trees reading as a row of identical trees.
local function tree(parent: Instance, cf: CFrame, scale: number,
	trunkColor: Color3, leafColor: Color3, leafMaterial: Enum.Material?)
	local h = 10 * scale
	prop(parent, "Trunk", Vector3.new(1.8 * scale, h, 1.8 * scale),
		cf * CFrame.new(0, h * 0.5, 0), trunkColor, Enum.Material.Wood)
	local canopy = {
		{ Vector3.new(9, 5, 9) * scale, CFrame.new(0, h + 1.5 * scale, 0) },
		{ Vector3.new(7, 4, 7) * scale, CFrame.new(1.5 * scale, h + 4 * scale, -1 * scale) },
		{ Vector3.new(5, 3.5, 5) * scale, CFrame.new(-1.5 * scale, h + 6 * scale, 1 * scale) },
	}
	for i, spec in ipairs(canopy) do
		prop(parent, "Leaves" .. i, spec[1], cf * spec[2], leafColor,
			leafMaterial or Enum.Material.Grass)
	end
end

-- A trunk with no canopy and two stubs for branches. Reads as dead from any
-- distance, which is the whole job.
local function deadTree(parent: Instance, cf: CFrame, scale: number, color: Color3)
	local h = 11 * scale
	prop(parent, "DeadTrunk", Vector3.new(1.6 * scale, h, 1.6 * scale),
		cf * CFrame.new(0, h * 0.5, 0), color, Enum.Material.Wood)
	prop(parent, "Branch", Vector3.new(5 * scale, 1.1 * scale, 1.1 * scale),
		cf * CFrame.new(2 * scale, h * 0.72, 0) * CFrame.Angles(0, 0, math.rad(28)),
		color, Enum.Material.Wood)
	prop(parent, "Branch", Vector3.new(4 * scale, 1 * scale, 1 * scale),
		cf * CFrame.new(-1.8 * scale, h * 0.88, 0) * CFrame.Angles(0, 0, math.rad(-34)),
		color, Enum.Material.Wood)
end

local function bush(parent: Instance, cf: CFrame, scale: number, color: Color3)
	ball(parent, "Bush", Vector3.new(6, 4.5, 6) * scale, cf * CFrame.new(0, 2 * scale, 0),
		color, Enum.Material.Grass)
	ball(parent, "Bush", Vector3.new(4.5, 3.5, 4.5) * scale,
		cf * CFrame.new(2.2 * scale, 1.4 * scale, 1 * scale), color, Enum.Material.Grass)
end

local function rock(parent: Instance, cf: CFrame, scale: number, color: Color3)
	prop(parent, "Rock", Vector3.new(5, 3.6, 4.4) * scale,
		cf * CFrame.new(0, 1.6 * scale, 0) * CFrame.Angles(math.rad(6), 0, math.rad(9)),
		color, Enum.Material.Slate)
	prop(parent, "Rock", Vector3.new(3, 2.2, 2.8) * scale,
		cf * CFrame.new(2.4 * scale, 0.9 * scale, 1.2 * scale) * CFrame.Angles(0, math.rad(30), 0),
		color, Enum.Material.Slate)
end

-- A thin stem and a bright head. The single cheapest prop that says "plant
-- game" -- three studs tall, two parts, and it does more for the theme per part
-- than anything else here.
local function flower(parent: Instance, cf: CFrame, scale: number,
	stemColor: Color3, headColor: Color3, glow: boolean?)
	prop(parent, "Stem", Vector3.new(0.35, 3 * scale, 0.35),
		cf * CFrame.new(0, 1.5 * scale, 0), stemColor, Enum.Material.Grass)
	ball(parent, "Bloom", Vector3.new(1.9, 1.9, 1.9) * scale,
		cf * CFrame.new(0, 3.2 * scale, 0), headColor,
		glow and Enum.Material.Neon or Enum.Material.Plastic)
end

local function mushroom(parent: Instance, cf: CFrame, scale: number,
	stemColor: Color3, capColor: Color3, glow: boolean?)
	prop(parent, "Stalk", Vector3.new(1.4 * scale, 3.4 * scale, 1.4 * scale),
		cf * CFrame.new(0, 1.7 * scale, 0), stemColor, Enum.Material.SmoothPlastic)
	ball(parent, "Cap", Vector3.new(5.4, 3.2, 5.4) * scale,
		cf * CFrame.new(0, 3.6 * scale, 0), capColor,
		glow and Enum.Material.Neon or Enum.Material.SmoothPlastic)
end

-- Segmented column with two arms. Botanical, and the only thing that grows in a
-- dustbowl -- which is why Dustbowl is not simply an empty biome.
local function cactus(parent: Instance, cf: CFrame, scale: number, color: Color3)
	prop(parent, "CactusBody", Vector3.new(2.4 * scale, 9 * scale, 2.4 * scale),
		cf * CFrame.new(0, 4.5 * scale, 0), color, Enum.Material.Grass)
	prop(parent, "CactusArm", Vector3.new(1.7 * scale, 4 * scale, 1.7 * scale),
		cf * CFrame.new(2 * scale, 5.4 * scale, 0), color, Enum.Material.Grass)
	prop(parent, "CactusArm", Vector3.new(1.7 * scale, 3 * scale, 1.7 * scale),
		cf * CFrame.new(-1.9 * scale, 6.4 * scale, 0), color, Enum.Material.Grass)
end

local function reeds(parent: Instance, cf: CFrame, scale: number, color: Color3)
	for i = 1, 5 do
		local lean = math.rad((i - 3) * 7)
		prop(parent, "Reed", Vector3.new(0.4, (5 + i % 3 * 2) * scale, 0.4),
			cf * CFrame.new((i - 3) * 1.1 * scale, 3 * scale, (i % 2) * 0.8 * scale)
				* CFrame.Angles(0, 0, lean),
			color, Enum.Material.Grass)
	end
end

-- Tapered stack. Reads as a crystal without needing a cone primitive, which
-- Roblox does not have.
local function crystal(parent: Instance, cf: CFrame, scale: number, color: Color3)
	for i = 1, 3 do
		local w = (3.4 - i * 0.8) * scale
		prop(parent, "Shard" .. i, Vector3.new(w, 3.4 * scale, w),
			cf * CFrame.new(0, (i - 0.5) * 3.2 * scale, 0)
				* CFrame.Angles(0, math.rad(i * 22), 0),
			color, Enum.Material.Neon)
	end
end

local function stump(parent: Instance, cf: CFrame, scale: number, color: Color3)
	prop(parent, "Stump", Vector3.new(4.2 * scale, 3.4 * scale, 4.2 * scale),
		cf * CFrame.new(0, 1.7 * scale, 0), color, Enum.Material.Wood)
end

--==============================================================================
-- SCATTER
--
-- Places `count` props inside the two side bands of the road, alternating
-- sides, never in the middle, and never on top of a pod.
--
-- `tallOnly` props are pushed to the outer half of the band, which is what
-- enforces rule 2 -- the sightline down the centre stays open because anything
-- with height is physically unable to be placed near it.
--==============================================================================
type Ctx = {
	parent: Instance,
	rng: Random,
	nearZ: number,
	farZ: number,
	taken: { { x: number, z: number, r: number } },
}

local CENTRE_CLEAR = 24   -- studs either side of the road's centre line

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
	place: (Instance, CFrame, number) -> ())
	local halfW = MAP.CorridorWidth * 0.5
	-- Tall props live in the outer third of the half-width; low props may come
	-- as far in as CENTRE_CLEAR.
	--
	-- PLUS THE PROP'S OWN RADIUS, and that is not a fudge factor. A prop is
	-- placed by its ANCHOR, but its pieces are offset from that anchor -- a rock
	-- carries a second block three studs to one side. Guarding only the anchor
	-- lets a prop sitting exactly on the boundary spill its far half over it,
	-- which is precisely what a check caught: a rock anchored at X=24 with a
	-- block at X=22.9, inside the racing line.
	--
	-- `radius` already describes the prop's footprint, because the scatter needs
	-- it for spacing. Reusing it here means the margin can never drift out of
	-- step with the prop it is protecting against.
	local minX = (tall and (halfW * 0.62) or CENTRE_CLEAR) + radius
	local maxX = halfW - 6

	for i = 1, count do
		local placed = false
		-- Bounded retries. A scatter that cannot find room must give up rather
		-- than spin -- a map that sometimes takes four seconds to build is
		-- worse than a map with one fewer bush.
		for _ = 1, 12 do
			local side = (i % 2 == 0) and 1 or -1
			local x = side * ctx.rng:NextNumber(minX, maxX)
			local z = ctx.rng:NextNumber(ctx.farZ + 12, ctx.nearZ - 12)
			if not tooClose(ctx, x, z, radius) then
				table.insert(ctx.taken, { x = x, z = z, r = radius })
				local scale = ctx.rng:NextNumber(0.8, 1.25)
				place(ctx.parent, CFrame.new(x, Y, z)
					* CFrame.Angles(0, ctx.rng:NextNumber(0, math.pi * 2), 0), scale)
				placed = true
				break
			end
		end
		if not placed then
			break
		end
	end
end

-- Flat markings on the floor. Allowed across the FULL width including the
-- centre, and that is the one deliberate exception to rule 2: a glowing crack
-- is 0.2 studs tall, so it cannot obscure a sightline or catch a runner, and
-- running over one is most of what makes Emberroot feel like Emberroot.
local function groundStreaks(ctx: Ctx, count: number, color: Color3, material: Enum.Material)
	local halfW = MAP.CorridorWidth * 0.5 - 8
	for i = 1, count do
		local x = ctx.rng:NextNumber(-halfW, halfW)
		local z = ctx.rng:NextNumber(ctx.farZ + 10, ctx.nearZ - 10)
		prop(ctx.parent, "Streak",
			Vector3.new(ctx.rng:NextNumber(6, 26), 0.2, ctx.rng:NextNumber(1.4, 3.4)),
			CFrame.new(x, Y + 0.15, z) * CFrame.Angles(0, ctx.rng:NextNumber(0, math.pi), 0),
			color, material)
	end
end

-- Hung on the inside face of both walls. Cheap, and it is what stops a
-- 46-stud wall of flat colour being the largest thing in every screenshot.
local function wallGrowth(ctx: Ctx, count: number, color: Color3,
	material: Enum.Material, fromTop: boolean)
	local innerX = MAP.CorridorWidth * 0.5 - 0.6
	for i = 1, count do
		local side = (i % 2 == 0) and 1 or -1
		local z = ctx.rng:NextNumber(ctx.farZ + 6, ctx.nearZ - 6)
		local length = ctx.rng:NextNumber(8, 26)
		local y = fromTop and (MAP.WallHeight - length * 0.5) or (length * 0.5)
		prop(ctx.parent, "Growth",
			Vector3.new(1.2, length, ctx.rng:NextNumber(2.5, 6)),
			CFrame.new(side * innerX, Y + y, z),
			color, material)
	end
end

--==============================================================================
-- THE KITS
--
-- One per biome. Each is a short recipe rather than a list of coordinates,
-- which is what keeps a biome's identity readable in ten lines and re-tunable
-- without moving anything by hand.
--==============================================================================
local KITS: { [string]: (Ctx, BiomeData.Biome) -> () } = {}

KITS.greenhollow = function(ctx, biome)
	scatter(ctx, 10, 7, true, function(p, cf, s)
		tree(p, cf, s, Color3.fromRGB(112, 78, 52), Color3.fromRGB(86, 176, 74))
	end)
	scatter(ctx, 12, 4, false, function(p, cf, s)
		bush(p, cf, s, Color3.fromRGB(96, 182, 88))
	end)
	scatter(ctx, 22, 2, false, function(p, cf, s)
		-- Four flower colours from one call, chosen off the scatter's own RNG
		-- so a meadow does not come out monochrome.
		local palette = {
			Color3.fromRGB(255, 226, 92), Color3.fromRGB(255, 138, 178),
			Color3.fromRGB(146, 186, 255), Color3.fromRGB(255, 255, 255),
		}
		flower(p, cf, s, Color3.fromRGB(84, 156, 74),
			palette[ctx.rng:NextInteger(1, #palette)])
	end)
	scatter(ctx, 6, 3, false, function(p, cf, s)
		mushroom(p, cf, s, Color3.fromRGB(232, 226, 206), Color3.fromRGB(214, 84, 74))
	end)
	wallGrowth(ctx, 14, Color3.fromRGB(78, 158, 70), Enum.Material.Grass, true)
end

KITS.dustbowl = function(ctx, biome)
	scatter(ctx, 9, 6, true, function(p, cf, s)
		cactus(p, cf, s, Color3.fromRGB(108, 152, 88))
	end)
	scatter(ctx, 5, 6, true, function(p, cf, s)
		deadTree(p, cf, s, Color3.fromRGB(148, 118, 84))
	end)
	scatter(ctx, 14, 4, false, function(p, cf, s)
		rock(p, cf, s, Color3.fromRGB(180, 148, 108))
	end)
	scatter(ctx, 12, 2, false, function(p, cf, s)
		-- Dry tufts. A flower with a drab head reads as dead grass, which is
		-- cheaper than a ninth prop builder for one biome.
		flower(p, cf, s * 0.8, Color3.fromRGB(186, 166, 112), Color3.fromRGB(200, 182, 130))
	end)
	groundStreaks(ctx, 16, Color3.fromRGB(196, 162, 116), Enum.Material.Sand)
end

KITS.tanglemire = function(ctx, biome)
	scatter(ctx, 8, 7, true, function(p, cf, s)
		tree(p, cf, s * 1.1, Color3.fromRGB(70, 58, 46), Color3.fromRGB(64, 122, 82))
	end)
	scatter(ctx, 11, 4, false, function(p, cf, s)
		mushroom(p, cf, s * 1.5, Color3.fromRGB(202, 208, 176), Color3.fromRGB(148, 196, 96), true)
	end)
	scatter(ctx, 10, 4, false, function(p, cf, s)
		reeds(p, cf, s, Color3.fromRGB(96, 138, 88))
	end)
	scatter(ctx, 6, 4, false, function(p, cf, s)
		stump(p, cf, s, Color3.fromRGB(62, 52, 42))
	end)
	-- Puddles. Flat, so they are allowed anywhere -- and a murky pool across
	-- the running line is the cheapest "this biome is unpleasant" there is.
	groundStreaks(ctx, 14, Color3.fromRGB(48, 82, 74), Enum.Material.Glass)
	wallGrowth(ctx, 20, Color3.fromRGB(78, 128, 74), Enum.Material.Grass, true)
end

KITS.emberroot = function(ctx, biome)
	scatter(ctx, 10, 6, true, function(p, cf, s)
		deadTree(p, cf, s, Color3.fromRGB(46, 38, 36))
	end)
	scatter(ctx, 12, 4, false, function(p, cf, s)
		stump(p, cf, s, Color3.fromRGB(38, 32, 30))
	end)
	scatter(ctx, 10, 4, false, function(p, cf, s)
		rock(p, cf, s, Color3.fromRGB(58, 46, 44))
	end)
	-- Ember blooms. The biome is called Emberroot, so something has to still be
	-- growing in it -- otherwise it is just a burnt corridor.
	scatter(ctx, 14, 2, false, function(p, cf, s)
		flower(p, cf, s, Color3.fromRGB(52, 40, 36), Color3.fromRGB(255, 128, 48), true)
	end)
	groundStreaks(ctx, 22, Color3.fromRGB(255, 104, 36), Enum.Material.Neon)
	wallGrowth(ctx, 12, Color3.fromRGB(255, 96, 40), Enum.Material.Neon, false)
end

KITS.starbloom = function(ctx, biome)
	scatter(ctx, 12, 6, true, function(p, cf, s)
		crystal(p, cf, s, Color3.fromRGB(158, 128, 255))
	end)
	scatter(ctx, 10, 4, false, function(p, cf, s)
		crystal(p, cf, s * 0.6, Color3.fromRGB(120, 236, 255))
	end)
	scatter(ctx, 18, 2, false, function(p, cf, s)
		local palette = {
			Color3.fromRGB(196, 156, 255), Color3.fromRGB(120, 236, 255),
			Color3.fromRGB(255, 214, 255),
		}
		flower(p, cf, s, Color3.fromRGB(72, 60, 118),
			palette[ctx.rng:NextInteger(1, #palette)], true)
	end)
	groundStreaks(ctx, 18, Color3.fromRGB(122, 96, 220), Enum.Material.Neon)
	-- Stars, on the walls, from the top. The reference game's dark biome had
	-- exactly this and it is the single detail that made it read as space
	-- rather than as a dark corridor.
	wallGrowth(ctx, 26, Color3.fromRGB(236, 232, 255), Enum.Material.Neon, true)
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

	-- The pods are claimed before anything scatters, so no decoration is ever
	-- placed on top of the thing the player is trying to reach.
	for _, podCF in ipairs(BiomeData.PodCFrames(biome)) do
		table.insert(ctx.taken, { x = podCF.X, z = podCF.Z, r = 9 })
	end

	kit(ctx, biome)

	--== SELF-CHECK ==--
	-- Rule 2 is easy to break by adding a prop whose pieces reach further from
	-- its anchor than its declared radius, and impossible to notice by reading.
	-- Checking the parts that were ACTUALLY placed is the only honest test.
	local intruders = 0
	local worst: string? = nil
	for _, d in ipairs(folder:GetDescendants()) do
		if d:IsA("BasePart") and d.Size.Y > 1 and math.abs(d.Position.X) < CENTRE_CLEAR then
			intruders += 1
			worst = string.format("%s at X=%.1f", d.Name, d.Position.X)
		end
	end
	if intruders > 0 then
		warn(string.format(
			"[Seed/MapDecor] %s: %d tall prop part(s) inside the %d-stud racing line (e.g. %s). " ..
			"Raise that prop's scatter radius -- its pieces reach further from its anchor than " ..
			"the radius claims.", biome.Id, intruders, CENTRE_CLEAR, worst or "?"))
	end
end

--==============================================================================
-- DRESS THE FIELD
--
-- The safe zone is a garden, not a lawn. It is also the first thing anybody
-- sees, and it has to say "plant game" before the player has read one word of
-- UI.
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
			prop(folder, "Hedge", Vector3.new(6, 7, len),
				CFrame.new(side * (halfW - 5), Y + 3.5, z + len * 0.5),
				Color3.fromRGB(72, 148, 76), Enum.Material.Grass)
			z += len + rng:NextNumber(2, 7)
		end
	end

	-- Corner trees, well clear of the plots and the run.
	for _, sx in ipairs({ -1, 1 }) do
		for _, z in ipairs({ front + 22, back - 22 }) do
			tree(folder, CFrame.new(sx * (halfW - 24), Y, z), 1.3,
				Color3.fromRGB(112, 78, 52), Color3.fromRGB(92, 178, 82))
		end
	end

	-- Flower beds in the strip between the plots and the red line, off to
	-- either side of the running lane. This is the stretch every player crosses
	-- twice a run, so it is the decoration with the most screen time in the
	-- whole game.
	for i = 1, 26 do
		local side = (i % 2 == 0) and 1 or -1
		local x = side * rng:NextNumber(46, halfW - 22)
		-- The strip between the red line and the plots, which is the ground
		-- every player crosses twice a run. Bounded by the plots' FIXED front
		-- edge, so beds never end up under a plot that grew.
		local z = rng:NextNumber(front + 20, GameConfig.Plot.FrontZ - 26)
		local palette = {
			Color3.fromRGB(255, 226, 92), Color3.fromRGB(255, 138, 178),
			Color3.fromRGB(146, 186, 255), Color3.fromRGB(255, 146, 96),
		}
		flower(folder, CFrame.new(x, Y, z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0),
			rng:NextNumber(0.9, 1.3), Color3.fromRGB(84, 156, 74),
			palette[rng:NextInteger(1, #palette)])
	end

	for i = 1, 8 do
		local side = (i % 2 == 0) and 1 or -1
		bush(folder, CFrame.new(side * rng:NextNumber(40, halfW - 26), Y,
			rng:NextNumber(front + 24, GameConfig.Plot.FrontZ - 30)),
			rng:NextNumber(0.9, 1.4), Color3.fromRGB(88, 172, 84))
	end
end

return MapDecor
