--==============================================================================
-- SUNCROWN, THE SOLAR CACTUS GOLEM -- PREVIEW AND DATA GENERATOR
--
-- A Studio authoring tool, not game code. Loaded in Edit with
--
--     loadstring(HttpService:GetAsync("http://127.0.0.1:8731/tools/art/suncrown_golem.luau"))()
--
-- it returns { specs, build, effects, measure, serialize }.
--
-- `specs` IS DustbowlForms.Plants.suncrown. `build` replays it the way
-- CreatureModel.replayPart does at hs = gs = 1, `effects` mirrors
-- CreatureModel.retrofitSolarAura, and `serialize` prints the list in the
-- PartSpec format Dustbowl and Tanglemire share. Change the numbers here,
-- preview, then paste the serialized table over the old one.
--
-- Authored in the mockup's own studs: ground at Y = 0, front toward -Z.
--
-- WHAT A WEDGE ACTUALLY IS, since every claw and every ray is one. Measured by
-- raycast rather than recalled: a WedgePart is FULL HEIGHT at its local +Z and
-- tapers to a knife edge at local -Z, flat along the bottom, constant across X.
-- So `CFrame.lookAt(mid, tip, widthAxis)` -- which puts local -Z on the look
-- direction -- gives a blade that comes to a point at `tip`, tapering across the
-- axis handed in as the up hint. That one fact places all 22 tapered parts.
--==============================================================================

local rad = math.rad
local UP = Vector3.new(0, 1, 0)

--==============================================================================
-- THE PALETTE
--
-- Three of these are the species' own: Body, Crown and Accent come straight out
-- of SeedData.suncrown, so the golem is painted in the colours the Almanac, the
-- shop tile and the sell board already show for it. The cactus flesh and the
-- sandstone are new and belong to this form.
--==============================================================================
-- THE TWO FLESH TONES ARE ROTATED TOWARD GREEN, AND THE SANDSTONE AWAY FROM IT.
-- The brief's #858032 and #6A6828 are olive with R above G, which is a YELLOW
-- olive; against #9E8062 sandstone that is 54 apart in RGB, and the two sit
-- against each other at every joint on the creature -- thigh to knee guard,
-- bicep to forearm, barrel to mantle. Built in those exact values the golem
-- came out one flat butter-yellow silhouette with no readable anatomy. Holding
-- the same VALUE and turning the hue -- G above R for the flesh, and a cooler,
-- paler rock -- takes the nearest pair to 100 apart and the cactus reads as
-- cactus. Same two families the brief names; enough daylight between them to
-- tell which is which.
local CACTUS = Color3.fromRGB(118, 132, 54) -- olive saguaro flesh
local CACTUS_DEEP = Color3.fromRGB(88, 102, 44) -- shaded flutes and lobes
local SAND = Color3.fromRGB(176, 156, 132) -- weathered desert sandstone
local CLAY = Color3.fromRGB(120, 96, 76) -- baked clay, the deep crust
local GOLD = Color3.fromRGB(255, 198, 38) -- SeedData.Body
local ORANGE = Color3.fromRGB(239, 116, 25) -- SeedData.Crown
local CRIMSON = Color3.fromRGB(210, 61, 45) -- SeedData.Accent
local SOLAR = Color3.fromRGB(255, 170, 32) -- incandescent core and eye

local PLASTIC = Enum.Material.Plastic
local NEON = Enum.Material.Neon

type Spec = {
	name: string,
	shape: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	material: Enum.Material,
	studs: boolean?,
}

local specs: { Spec } = {}

local function add(name: string, shape: string, size: Vector3, cf: CFrame, color: Color3,
	material: Enum.Material?): Spec
	local mat = material or PLASTIC
	local s: Spec = {
		name = name,
		shape = shape,
		size = size,
		cf = cf,
		color = color,
		material = mat,
		-- Neon takes its light from the material and not from a surface, and a
		-- studded neon face reads as a dirty one. Everything else keeps its
		-- studs: the contrast between matte studded plastic and smooth neon IS
		-- the look.
		studs = if mat == NEON then false else nil,
	}
	table.insert(specs, s)
	return s
end

--==============================================================================
-- PLACEMENT HELPERS
--==============================================================================

-- A block spanning a to b, overrunning both ends so neither joint is a visible
-- butt seam. Local -Z runs along it.
local function beam(name: string, a: Vector3, b: Vector3, w: number, h: number, overrun: number,
	color: Color3, hint: Vector3?): Spec
	local dir = b - a
	local up = hint or UP
	if math.abs(dir.Unit:Dot(up)) > 0.98 then
		up = Vector3.new(0, 0, 1)
	end
	return add(name, "Block", Vector3.new(w, h, dir.Magnitude + overrun * 2),
		CFrame.lookAt((a + b) * 0.5, b, up), color)
end

-- A wedge that comes to a point at `tip`, tapering across `widthAxis`. `thick`
-- is the axis the taper never touches, so a blade keeps its thickness and loses
-- its width -- which is what makes a petal read as a petal rather than a spine.
local function blade(name: string, from: Vector3, tip: Vector3, width: number, thick: number,
	color: Color3, widthAxis: Vector3, material: Enum.Material?): Spec
	local len = (tip - from).Magnitude
	return add(name, "Wedge", Vector3.new(thick, width, len),
		CFrame.lookAt((from + tip) * 0.5, tip, widthAxis), color, material)
end

local function lowestOf(s: Spec): number
	local h = s.size * 0.5
	local y = math.huge
	for sx = -1, 1, 2 do
		for sy = -1, 1, 2 do
			for sz = -1, 1, 2 do
				y = math.min(y, (s.cf * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position.Y)
			end
		end
	end
	return y
end

-- Sits a part on the plane: its lowest corner at exactly Y = 0. A wedge's
-- bottom is flat, so a planted claw lies ON the ground and not on its point.
local function plant(s: Spec)
	s.cf = s.cf + Vector3.new(0, -lowestOf(s), 0)
end

--==============================================================================
-- SUPPORTING MASS: TWO PILLAR LEGS
--
-- Short and heavy on purpose. The concept's golem is squat -- hip at a quarter
-- of its height, not at half -- and everything the silhouette has goes into the
-- shoulders and the crown above them.
--
-- Thigh into shin into sole, each joint swallowed by the next part rather than
-- butted against it, and a sandstone guard over the knee where the two cactus
-- columns meet. Every name here carries a word out of PlantSway's LEG_WORDS --
-- Thigh, Shin, Knee, Foot, Toe -- which is the whole rigging contract: the
-- walker finds them by name, clusters them by where they stand in plan view,
-- and strides the two sides in opposition.
--==============================================================================
local STANCE = 0.78

for _, side in ipairs({ -1, 1 }) do
	local tag = if side < 0 then "Left" else "Right"

	add(tag .. "Thigh", "Block", Vector3.new(0.74, 1.16, 0.80),
		CFrame.new(side * STANCE, 1.54, -0.10) * CFrame.Angles(0, 0, rad(-side * 6)), CACTUS)

	add(tag .. "Shin", "Block", Vector3.new(0.64, 1.04, 0.70),
		CFrame.new(side * (STANCE + 0.04), 0.72, -0.06) * CFrame.Angles(rad(3), 0, rad(-side * 2)),
		CACTUS_DEEP)

	-- Sandstone over the knee, pitched forward so it reads as armour lying on
	-- the joint rather than a ring around it.
	add(tag .. "KneeGuard", "Block", Vector3.new(0.82, 0.56, 0.86),
		CFrame.new(side * STANCE, 1.22, -0.09) * CFrame.Angles(rad(-12), rad(side * 6), 0), SAND)

	-- The sole. Yawed out a few degrees so the stance splays like a beast's and
	-- not like a mannequin's.
	local foot = add(tag .. "Foot", "Block", Vector3.new(1.02, 0.38, 1.16),
		CFrame.new(side * (STANCE + 0.05), 0.19, -0.06) * CFrame.Angles(0, rad(side * 8), 0), SAND)
	plant(foot)

	-- Two golden talons off the front of each sole, KEPT SHORT AND KEPT BACK.
	-- The leg rig swings a whole leg rigidly about one hip with no ankle in it,
	-- so anything reaching forward of that hip scoops DOWN through the soil as
	-- the leg swings back -- and girth spreads horizontal offsets without
	-- lengthening the drop, so the scoop gets worse with every tier. At a toe
	-- tip 1.32 studs proud of the hip this dug 5.9% of body height in at
	-- Colossal, against 2.7% for a species nobody had touched. Pulling the sole
	-- back under the hip and cropping the talon to 0.88 halves the lever.
	--
	-- Planted flat: a wedge's
	-- bottom face is flat, so the claw lies ON the ground along its whole length
	-- and only its silhouette comes to a point.
	for i = 1, 2 do
		local lean = if i == 1 then -1 else 1
		local root = Vector3.new(side * (STANCE + 0.05) + lean * 0.27, 0.17, -0.56)
		local tip = root + Vector3.new(lean * 0.14 + side * 0.05, -0.02, -0.42)
		local claw = blade(tag .. "Toe" .. i, root, tip, 0.34, 0.28, GOLD, UP)
		plant(claw)
	end
end

--==============================================================================
-- THE TAIL, WHICH IS THE COUNTERWEIGHT
--
-- Two segments turning about thirty degrees at the joint, out of the pelvis and
-- down behind the heels. It carries no leg word on purpose: it must not join
-- the gait, it must hang off the back of it.
--==============================================================================
local TAIL_HIP = Vector3.new(0, 2.00, 0.48)
local TAIL_KNEE = Vector3.new(0.08, 1.34, 1.36)
local TAIL_END = Vector3.new(0.24, 0.70, 1.98)
beam("TailBase", TAIL_HIP, TAIL_KNEE, 0.54, 0.54, 0.15, CACTUS)
beam("TailTip", TAIL_KNEE, TAIL_END, 0.38, 0.38, 0.10, CACTUS_DEEP)

--==============================================================================
-- DOMINANT MASS: THE VAULTED SAGUARO CARAPACE
--
-- Three fluted cactus courses that widen as they rise and lean forward as they
-- go, a belly that hangs out over the pelvis, and -- the concept's loudest
-- silhouette note after the crown -- two BARREL CACTUS SHOULDERS, round lobes
-- the arms hang out of and the rock mantles cap.
--==============================================================================
add("TorsoLower", "Block", Vector3.new(1.42, 0.86, 1.00), CFrame.new(0, 2.16, 0.04), CACTUS_DEEP)
add("TorsoMid", "Block", Vector3.new(1.56, 0.92, 1.08),
	CFrame.new(0, 2.86, 0.01) * CFrame.Angles(rad(-3), 0, 0), CACTUS)
add("TorsoUpper", "Block", Vector3.new(1.64, 1.16, 1.10),
	CFrame.new(0, 3.98, -0.04) * CFrame.Angles(rad(-6), 0, 0), CACTUS)
add("Belly", "Block", Vector3.new(1.18, 0.94, 0.50),
	CFrame.new(0, 2.50, -0.60) * CFrame.Angles(rad(7), 0, 0), CACTUS)

for _, side in ipairs({ -1, 1 }) do
	local tag = if side < 0 then "L" else "R"
	-- The barrel. A Ball, because a barrel cactus is the one thing on this
	-- creature that has no flat side anywhere on it.
	add("ShoulderLobe" .. tag, "Ball", Vector3.new(1.18, 1.18, 1.18),
		CFrame.new(side * 1.04, 3.62, 0.00), CACTUS)
	add("RibLobe" .. tag, "Block", Vector3.new(0.36, 0.86, 0.88),
		CFrame.new(side * 0.80, 2.72, 0.02) * CFrame.Angles(0, 0, rad(side * 8)), CACTUS_DEEP)
end

--==============================================================================
-- THE SANDSTONE CRUST, AND THE CAVITY IT LEAVES
--
-- The mantles are rock caps lying over the barrels, sloping down and out, which
-- is what stops two spheres reading as two balloons. The two chest plates stand
-- PROUD of the trunk and stop short of each other, and the gap between them is
-- the furnace -- negative space framed by rock, not a bright sticker laid on a
-- flat chest.
--==============================================================================
local CAVITY_Z = -0.52
local CAVITY_Y = 3.14

for _, side in ipairs({ -1, 1 }) do
	local tag = if side < 0 then "L" else "R"
	add("SandstoneMantle" .. tag, "Block", Vector3.new(1.04, 0.46, 1.10),
		CFrame.new(side * 1.10, 4.02, 0.00) * CFrame.Angles(rad(-6), 0, rad(side * 28)), SAND)
	-- The jambs of the furnace door. Square to the chest rather than splayed:
	-- angled, the pair leaves a V and the light pours out of it in a triangle,
	-- which reads as a crack and not as a socket.
	add("ChestCrust" .. tag, "Block", Vector3.new(0.58, 1.26, 0.38),
		CFrame.new(side * 0.72, CAVITY_Y + 0.02, -0.66) * CFrame.Angles(0, rad(-side * 6), 0), CLAY)
end

--==============================================================================
-- THE SOLAR CORE
--
-- A faceted diamond -- a block rolled 45 degrees -- set back behind the front
-- face of the crust plates, so the light climbs out of a hole rather than
-- sitting on a wall. The rims are the cracked lip of that hole; the backing
-- plate is the glow leaking around the diamond through the gap they leave.
--==============================================================================
add("SolarCore", "Block", Vector3.new(0.58, 0.58, 0.34),
	CFrame.new(0, CAVITY_Y, CAVITY_Z) * CFrame.Angles(0, 0, rad(45)), SOLAR, NEON)
add("CoreBack", "Block", Vector3.new(0.54, 0.54, 0.16),
	CFrame.new(0, CAVITY_Y, CAVITY_Z + 0.26) * CFrame.Angles(0, 0, rad(45)), ORANGE, NEON)
-- The lintel and the sill. With the two jambs above, the diamond is framed on
-- all four sides and sits 0.2 studs back from the frame, so it is a hole in the
-- chest with a light at the bottom of it rather than a badge stuck on the front.
for _, sign in ipairs({ -1, 1 }) do
	local tag = if sign < 0 then "L" else "R"
	add("CoreRim" .. tag, "Block", Vector3.new(0.86, 0.24, 0.34),
		CFrame.new(0, CAVITY_Y + sign * 0.60, -0.64) * CFrame.Angles(rad(sign * 9), 0, 0), CLAY)
end

--==============================================================================
-- ARTICULATED ARMS
--
-- Long, the way the concept hangs them: the palms finish level with the knees.
--
-- THE UPPER ARMS ARE NAMED `Leaf`, AND THAT IS THE RIG, NOT A COMPROMISE OF IT.
-- PlantSway swings a part called Leaf about its OWN centre, in opposition on
-- either side of the stem -- so the one part in an arm that can carry the swing
-- is a segment whose two ends are both buried. This one is: it runs up inside
-- the barrel shoulder and down inside the forearm, both by more than twice the
-- 0.21 studs its ends travel at the full nineteen degrees. The bicep swings,
-- both joints stay shut, and the forearm below reads as an elbow that is simply
-- heavier than the shoulder -- which, on a rock-and-cactus golem, it is.
--==============================================================================
for _, side in ipairs({ -1, 1 }) do
	local tag = if side < 0 then "Left" else "Right"

	add("Leaf", "Block", Vector3.new(0.58, 1.34, 0.60),
		CFrame.new(side * 1.40, 3.14, 0.02) * CFrame.Angles(0, 0, rad(side * 8)), CACTUS)

	-- Rock, not flesh. The concept plates the forearm and leaves the bicep
	-- bare, and that alternation is what keeps a limb of four parts from
	-- reading as one long sausage.
	add(tag .. "Forearm", "Block", Vector3.new(0.54, 1.62, 0.56),
		CFrame.new(side * 1.52, 2.04, -0.06) * CFrame.Angles(rad(5), 0, rad(side * 4)), SAND)

	-- Amber crystal thorns out of the elbow, the one place on the limb where
	-- the cactus has broken through its own crust.
	local elbow = Vector3.new(side * 1.54, 2.76, -0.02)
	blade(tag .. "ElbowThorn1", elbow, elbow + Vector3.new(side * 0.52, 0.36, 0.14), 0.28, 0.22,
		SOLAR, UP, NEON)
	blade(tag .. "ElbowThorn2", elbow + Vector3.new(0, -0.30, 0),
		elbow + Vector3.new(side * 0.46, -0.16, -0.38), 0.24, 0.18, SOLAR, UP, NEON)

	add(tag .. "Hand", "Block", Vector3.new(0.68, 0.56, 0.74),
		CFrame.new(side * 1.56, 1.18, -0.14) * CFrame.Angles(rad(-8), 0, 0), SAND)

	-- Two golden claws curling down and forward out of the palm.
	for i = 1, 2 do
		local lean = if i == 1 then -1 else 1
		local knuckle = Vector3.new(side * 1.56 + lean * 0.19, 0.98, -0.40)
		local tip = knuckle + Vector3.new(lean * 0.11, -0.54, -0.32)
		blade(tag .. "Claw" .. i, knuckle, tip, 0.28, 0.24, GOLD, UP)
	end
end

--==============================================================================
-- THE CYCLOPEAN MASK
--
-- Set down BETWEEN the shoulders with no neck, the way the concept sits it, so
-- the crown behind it reads as a disc the head is in front of rather than a
-- headdress balanced on top.
--
-- A carved sandstone monolith with the brow pitched down over it and the jaw
-- crust pitched up under it. The eye is not ON the face, it is BEHIND it: the
-- two plates stand proud of the eyeball, so the socket is a real hole and the
-- amber sits at the bottom of it.
--==============================================================================
local HEAD = Vector3.new(0, 5.05, 0.06)

add("HeadBase", "Block", Vector3.new(1.22, 1.12, 0.94), CFrame.new(HEAD), SAND)
add("BrowPlate", "Block", Vector3.new(1.14, 0.38, 0.44),
	CFrame.new(HEAD + Vector3.new(0, 0.40, -0.38)) * CFrame.Angles(rad(22), 0, 0), CLAY)
add("JawCrust", "Block", Vector3.new(1.02, 0.36, 0.42),
	CFrame.new(HEAD + Vector3.new(0, -0.38, -0.36)) * CFrame.Angles(rad(-18), 0, 0), CLAY)

-- Eye and Pupil, the two names PlantSway's gaze rig matches by suffix. The
-- pupil rides the eyeball as the gaze turns it, so it is placed ON the sphere
-- rather than floating in front of the face.
local EYE = HEAD + Vector3.new(0, 0.01, -0.32)
add("Eye", "Ball", Vector3.new(0.52, 0.52, 0.52), CFrame.new(EYE), SOLAR, NEON)
add("Pupil", "Block", Vector3.new(0.10, 0.30, 0.10), CFrame.new(EYE + Vector3.new(0, 0, -0.21)),
	CRIMSON, NEON)

--==============================================================================
-- SIGNATURE SHAPE: THE SUNBURST CROWN
--
-- Fourteen blades radiating in the plane of the face, in two layers.
--
-- WIDE AT THE ROOT, which is the whole difference between a sun and a mohawk.
-- At 0.88 across, the eight long blades are wider than the arc each one owns at
-- the hub, so they OVERLAP into a solid rosette there and only come apart as
-- they taper -- the way the concept's petals do. Eight narrow spokes at the
-- same length read as a punk fringe, which is what the first pass of this
-- crown was.
--
-- NOTHING IS SPENT ON THE ARC THAT CANNOT BE SEEN. A ray pointing straight down
-- from the hub ends up inside the chest, and the second pass of this crown put
-- three of its fourteen blades there. The ring stops at 140 degrees either side
-- of vertical and the freed blades go into the top instead, which lands one
-- every twenty degrees across the whole visible sweep: long, short, long,
-- short, out to the tips. The bottom eighty degrees is the neck, and the body
-- fills it.
--==============================================================================
local CROWN = HEAD + Vector3.new(0, 0.05, 0.10)

local OUTER = { 20, -20, 60, -60, 100, -100, 132, -132 }
for i, deg in ipairs(OUTER) do
	local a = rad(deg)
	local dir = Vector3.new(math.sin(a), math.cos(a), 0)
	local tangent = Vector3.new(math.cos(a), -math.sin(a), 0)
	-- Handedness alternates so the petals overlap in both directions instead of
	-- all leaning the same way like a cog.
	local hand = if i % 2 == 0 then 1 else -1
	-- The crimson accent lands on three of the eight, the way the nine-ray sun
	-- this replaces spent its accent.
	local shade = if i == 1 or i == 2 or i == 5 then CRIMSON else GOLD
	blade("CrownRay" .. i, CROWN + dir * 0.40, CROWN + dir * 1.80, 0.88, 0.26, shade, tangent * hand)
end

local INNER = { 0, 40, -40, 80, -80, 120 }
for i, deg in ipairs(INNER) do
	local a = rad(deg)
	local dir = Vector3.new(math.sin(a), math.cos(a), 0)
	local tangent = Vector3.new(math.cos(a), -math.sin(a), 0)
	local hand = if i % 2 == 0 then 1 else -1
	-- A quarter stud behind the long blades, so the two layers read as depth
	-- rather than as one ring with uneven teeth.
	local back = Vector3.new(0, 0, 0.24)
	blade("InnerRay" .. i, CROWN + dir * 0.34 + back, CROWN + dir * 1.30 + back, 0.64, 0.22,
		ORANGE, tangent * hand)
end

-- The one odd blade out: -120 would be the sixth short ray, but the fifteenth
-- slot is not in the budget, so the ring is deliberately asymmetric by one and
-- the missing petal sits on the side the tail already unbalances. Controlled
-- asymmetry, which is the fifth thing the sculpting skill asks for.

--==============================================================================
-- PREVIEW, EFFECTS, MEASUREMENT, SERIALIZATION
--==============================================================================
local FACES = { "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface",
	"BackSurface" }

local function build(parent: Instance, base: CFrame): Model
	local model = Instance.new("Model")
	model.Name = "SuncrownGolem"
	model.Archivable = false
	for _, s in ipairs(specs) do
		local p: BasePart
		if s.shape == "Wedge" then
			p = Instance.new("WedgePart")
		else
			local block = Instance.new("Part")
			block.Shape = (Enum.PartType :: any)[s.shape]
			p = block
		end
		p.Name = s.name
		p.Size = s.size
		p.CFrame = base * s.cf
		p.Color = s.color
		p.Anchored = true
		p.CanCollide = false
		local surface = if s.studs == false then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
		for _, face in ipairs(FACES) do
			pcall(function()
				(p :: any)[face] = surface
			end)
		end
		p.Material = s.material
		p.Archivable = false
		p.Parent = model
	end
	model.Parent = parent
	return model
end

local function effects(model: Model, hs: number)
	local core = model:FindFirstChild("SolarCore")
	if not (core and core:IsA("BasePart")) then
		return
	end
	local glow = Instance.new("PointLight")
	glow.Name = "SolarGlow"
	glow.Color = Color3.fromRGB(255, 190, 40)
	glow.Brightness = 2.4
	glow.Range = 16 * hs
	glow.Shadows = false
	glow.Parent = core

	-- World-aligned, so the embers rise whatever the diamond's 45 degree roll is
	-- doing and whichever way the golem happens to be facing.
	local att = Instance.new("Attachment")
	att.Name = "SolarAttachment"
	att.CFrame = core.CFrame:ToObjectSpace(CFrame.new(core.Position))
	att.Parent = core

	local motes = Instance.new("ParticleEmitter")
	motes.Name = "SolarMotes"
	motes.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	motes.Color = ColorSequence.new(Color3.fromRGB(255, 214, 96), Color3.fromRGB(239, 116, 25))
	motes.LightEmission = 1
	motes.LightInfluence = 0
	motes.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.07 * hs),
		NumberSequenceKeypoint.new(0.3, 0.28 * hs),
		NumberSequenceKeypoint.new(1, 0),
	})
	motes.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.25),
		NumberSequenceKeypoint.new(0.6, 0.55),
		NumberSequenceKeypoint.new(1, 1),
	})
	motes.Lifetime = NumberRange.new(1.4, 2.8)
	motes.Rate = 14
	motes.Speed = NumberRange.new(0.6 * hs, 1.5 * hs)
	motes.Drag = 1.2
	motes.Acceleration = Vector3.new(0, 0.9 * hs, 0)
	motes.EmissionDirection = Enum.NormalId.Top
	motes.SpreadAngle = Vector2.new(45, 45)
	motes.Rotation = NumberRange.new(0, 360)
	motes.RotSpeed = NumberRange.new(-50, 50)
	motes.Parent = att
end

local LEG_WORDS = { "Thigh", "Femur", "Haunch", "Shin", "Tibia", "Knee", "Hock", "Foot", "Hoof",
	"Paw", "Toe", "Stilt", "Pillar" }

local function measure(): string
	local lo = Vector3.new(math.huge, math.huge, math.huge)
	local hi = -lo
	local counts = { Block = 0, Wedge = 0, Cylinder = 0, Ball = 0 }
	local neon, leaves, legParts = 0, 0, 0
	local names: { [string]: number } = {}
	for _, s in ipairs(specs) do
		counts[s.shape] = (counts[s.shape] or 0) + 1
		names[s.name] = (names[s.name] or 0) + 1
		if s.material == NEON then
			neon += 1
		end
		if s.name == "Leaf" then
			leaves += 1
		end
		for _, w in ipairs(LEG_WORDS) do
			if string.find(s.name, w) then
				legParts += 1
				break
			end
		end
		local h = s.size * 0.5
		for sx = -1, 1, 2 do
			for sy = -1, 1, 2 do
				for sz = -1, 1, 2 do
					local q = (s.cf * CFrame.new(h.X * sx, h.Y * sy, h.Z * sz)).Position
					lo = Vector3.new(math.min(lo.X, q.X), math.min(lo.Y, q.Y), math.min(lo.Z, q.Z))
					hi = Vector3.new(math.max(hi.X, q.X), math.max(hi.Y, q.Y), math.max(hi.Z, q.Z))
				end
			end
		end
	end
	local dupes = {}
	for name, n in pairs(names) do
		if n > 1 and name ~= "Leaf" then
			table.insert(dupes, string.format("%s x%d", name, n))
		end
	end
	return string.format(
		"%d parts (%d block, %d wedge, %d ball; %d neon, %d Leaf, %d leg-word) | x %.3f..%.3f  y %.4f..%.4f  z %.3f..%.3f | %.2f w x %.4f h x %.2f d%s",
		#specs, counts.Block, counts.Wedge, counts.Ball, neon, leaves, legParts,
		lo.X, hi.X, lo.Y, hi.Y, lo.Z, hi.Z, hi.X - lo.X, hi.Y - lo.Y, hi.Z - lo.Z,
		if #dupes > 0 then "\nDUPLICATE NAMES: " .. table.concat(dupes, ", ") else "")
end

local function num(v: number): string
	local s = string.format("%.6f", v)
	s = string.gsub(s, "0+$", "")
	s = string.gsub(s, "%.$", "")
	if s == "-0" then
		s = "0"
	end
	return s
end

local function serialize(): string
	local out = {}
	for _, s in ipairs(specs) do
		local comps = { s.cf:GetComponents() }
		local text = {}
		for i, v in ipairs(comps) do
			text[i] = num(v)
		end
		table.insert(out, "\t\t{")
		table.insert(out, string.format('\t\t\tname = "%s",', s.name))
		table.insert(out, string.format('\t\t\tshape = "%s",', s.shape))
		table.insert(out, string.format("\t\t\tsize = Vector3.new(%s, %s, %s),", num(s.size.X),
			num(s.size.Y), num(s.size.Z)))
		table.insert(out, string.format("\t\t\tcf = CFrame.new(%s),", table.concat(text, ", ")))
		table.insert(out, string.format("\t\t\tcolor = Color3.fromRGB(%d, %d, %d),",
			math.round(s.color.R * 255), math.round(s.color.G * 255), math.round(s.color.B * 255)))
		table.insert(out, string.format("\t\t\tmaterial = Enum.Material.%s,", s.material.Name))
		if s.studs == false then
			table.insert(out, "\t\t\tstuds = false,")
		end
		table.insert(out, "\t\t},")
	end
	return table.concat(out, "\n")
end

return {
	specs = specs,
	build = build,
	effects = effects,
	measure = measure,
	serialize = serialize,
}
