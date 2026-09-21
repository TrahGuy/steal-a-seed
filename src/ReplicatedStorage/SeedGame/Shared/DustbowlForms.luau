--!strict
--==============================================================================
-- DUSTBOWL, AS BUILT
--
-- Suncrown, the Solar Cactus Golem. Authored in tools/art/suncrown_golem.luau
-- against art/creatures/suncrown/reference/suncrown-concept2-solar-golem.jpg,
-- previewed in Edit, and lifted here part for part. Change the tool, re-run its
-- serialize(), paste the result over the table below -- never the other way
-- round, because the tool is where the geometry is reasoned about and this is
-- only where it is kept.
--
-- IT IS DATA, NOT ART DIRECTION, and it is replayed by the same CreatureModel
-- player Tanglemire uses: one factor hs = FrameHeight(sp, tier) / PreviewHeight
-- conforms the mockup to the tier frame, and girth spreads the parts apart
-- horizontally rather than scaling them, so a Colossal is broader without being
-- sheared.
--
-- CFRAMES CARRY ALL TWELVE COMPONENTS. Fifty of the sixty-three parts are
-- rotated off-axis -- every crown blade, every claw, every plate -- and Euler
-- angles would read better without round-tripping exactly.
--
-- WHY ONLY ONE SPECIES IS IN HERE. Dustbowl's other four still come out of the
-- shared stem-and-footing builder in CreatureModel, and they are not broken.
-- This file exists for the ones that have been rebuilt as assembled forms, and
-- CreatureModel asks it by species id rather than by biome for exactly that
-- reason: an id with no entry here falls through to the builder that already
-- serves it.
--==============================================================================

export type PartSpec = {
	name: string,
	shape: string,
	size: Vector3,
	cf: CFrame,
	color: Color3?,
	material: Enum.Material,
	transparency: number?,
	reflectance: number?,
	-- Studded unless this says otherwise. Neon takes its light from the material
	-- and a studded neon face reads as a dirty one, so the eight glowing parts
	-- turn them off and nothing else does.
	studs: boolean?,
}

local PlantSculpt = require(script.Parent:WaitForChild("PlantSculpt"))
local SeedData = require(script.Parent:WaitForChild("SeedData"))

local DustbowlForms = {}

local rad = math.rad
local V3 = Vector3.new

--==============================================================================
-- What the mockup WAS, in its own studs, measured from its lowest vertex to the
-- tip of its tallest crown blade. It never changes: the species Height in
-- SeedData is what it SHIPS at, and hs reconciles the two.
--==============================================================================
DustbowlForms.PreviewHeight = {
	suncrown = 6.9419,
} :: { [string]: number }

--==============================================================================
-- THE SOLAR CACTUS GOLEM, 63 PARTS
--
--   14  two pillar legs -- thigh, shin, knee guard, sole, two talons each --
--       and the two-segment tail that counterweights them
--   16  the saguaro carapace: four trunk courses, two barrel shoulders, two rib
--       lobes, two rock mantles, two chest jambs, and the four-part furnace
--    4  the solar core, framed and recessed
--   14  two arms: bicep, plated forearm, two elbow thorns, palm, two claws
--    5  the cyclopean mask and its eye
--   14  the sunburst crown, eight long blades and six short
--
-- The names are load-bearing. Thigh / Shin / Knee / Foot / Toe put the legs in
-- PlantSway LEG_WORDS so the walker strides them; the two biceps are called
-- "Leaf" because that is the only name PlantSway swings as an arm; Eye and
-- Pupil are what its gaze rig matches by suffix.
--==============================================================================
DustbowlForms.Plants = {
	suncrown = {
		{
			name = "LeftThigh",
			shape = "Block",
			size = Vector3.new(0.74, 1.16, 0.8),
			cf = CFrame.new(-0.78, 1.54, -0.1, 0.994522, -0.104528, 0, 0.104528, 0.994522, 0, 0, 0, 1),
			color = Color3.fromRGB(118, 132, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftShin",
			shape = "Block",
			size = Vector3.new(0.64, 1.04, 0.7),
			cf = CFrame.new(-0.82, 0.72, -0.06, 0.999391, -0.034899, 0, 0.034852, 0.998021, -0.052336, 0.001826, 0.052304, 0.99863),
			color = Color3.fromRGB(88, 102, 44),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftKneeGuard",
			shape = "Block",
			size = Vector3.new(0.82, 0.56, 0.86),
			cf = CFrame.new(-0.78, 1.22, -0.09, 0.994522, 0, -0.104528, 0.021733, 0.978148, 0.206773, 0.102244, -0.207912, 0.972789),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftFoot",
			shape = "Block",
			size = Vector3.new(1.02, 0.38, 1.16),
			cf = CFrame.new(-0.83, 0.19, -0.06, 0.990268, 0, -0.139173, 0, 1, 0, 0.139173, 0, 0.990268),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftToe1",
			shape = "Wedge",
			size = Vector3.new(0.28, 0.34, 0.461411),
			cf = CFrame.new(-1.195, 0.17984, -0.77, 0.911108, -0.017866, 0.411781, 0, 0.99906, 0.043345, -0.412168, -0.039492, 0.910252),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftToe2",
			shape = "Wedge",
			size = Vector3.new(0.28, 0.34, 0.43),
			cf = CFrame.new(-0.515, 0.179816, -0.77, 0.977802, 0.009746, -0.209302, 0, 0.998918, 0.046512, 0.209529, -0.045479, 0.976744),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightThigh",
			shape = "Block",
			size = Vector3.new(0.74, 1.16, 0.8),
			cf = CFrame.new(0.78, 1.54, -0.1, 0.994522, 0.104528, 0, -0.104528, 0.994522, 0, 0, 0, 1),
			color = Color3.fromRGB(118, 132, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightShin",
			shape = "Block",
			size = Vector3.new(0.64, 1.04, 0.7),
			cf = CFrame.new(0.82, 0.72, -0.06, 0.999391, 0.034899, 0, -0.034852, 0.998021, -0.052336, -0.001826, 0.052304, 0.99863),
			color = Color3.fromRGB(88, 102, 44),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightKneeGuard",
			shape = "Block",
			size = Vector3.new(0.82, 0.56, 0.86),
			cf = CFrame.new(0.78, 1.22, -0.09, 0.994522, 0, 0.104528, -0.021733, 0.978148, 0.206773, -0.102244, -0.207912, 0.972789),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightFoot",
			shape = "Block",
			size = Vector3.new(1.02, 0.38, 1.16),
			cf = CFrame.new(0.83, 0.19, -0.06, 0.990268, 0, 0.139173, 0, 1, 0, -0.139173, 0, 0.990268),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightToe1",
			shape = "Wedge",
			size = Vector3.new(0.28, 0.34, 0.43),
			cf = CFrame.new(0.515, 0.179816, -0.77, 0.977802, -0.009746, 0.209302, 0, 0.998918, 0.046512, -0.209529, -0.045479, 0.976744),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightToe2",
			shape = "Wedge",
			size = Vector3.new(0.28, 0.34, 0.461411),
			cf = CFrame.new(1.195, 0.17984, -0.77, 0.911108, 0.017866, -0.411781, 0, 0.99906, 0.043345, 0.412168, -0.039492, 0.910252),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "TailBase",
			shape = "Block",
			size = Vector3.new(0.54, 0.54, 1.402905),
			cf = CFrame.new(0.04, 1.67, 0.92, -0.995893, 0.054178, -0.072536, 0, 0.801183, 0.59842, 0.090536, 0.595962, -0.797893),
			color = Color3.fromRGB(118, 132, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "TailTip",
			shape = "Block",
			size = Vector3.new(0.38, 0.38, 1.105318),
			cf = CFrame.new(0.16, 1.02, 1.67, -0.968277, 0.176647, -0.176734, 0, 0.707279, 0.706934, 0.249878, 0.684508, -0.684842),
			color = Color3.fromRGB(88, 102, 44),
			material = Enum.Material.Plastic,
		},
		{
			name = "TorsoLower",
			shape = "Block",
			size = Vector3.new(1.42, 0.86, 1),
			cf = CFrame.new(0, 2.16, 0.04, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(88, 102, 44),
			material = Enum.Material.Plastic,
		},
		{
			name = "TorsoMid",
			shape = "Block",
			size = Vector3.new(1.56, 0.92, 1.08),
			cf = CFrame.new(0, 2.86, 0.01, 1, 0, 0, 0, 0.99863, 0.052336, 0, -0.052336, 0.99863),
			color = Color3.fromRGB(118, 132, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "TorsoUpper",
			shape = "Block",
			size = Vector3.new(1.64, 1.16, 1.1),
			cf = CFrame.new(0, 3.98, -0.04, 1, 0, 0, 0, 0.994522, 0.104528, 0, -0.104528, 0.994522),
			color = Color3.fromRGB(118, 132, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "Belly",
			shape = "Block",
			size = Vector3.new(1.18, 0.94, 0.5),
			cf = CFrame.new(0, 2.5, -0.6, 1, 0, 0, 0, 0.992546, -0.121869, 0, 0.121869, 0.992546),
			color = Color3.fromRGB(118, 132, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "ShoulderLobeL",
			shape = "Ball",
			size = Vector3.new(1.18, 1.18, 1.18),
			cf = CFrame.new(-1.04, 3.62, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(118, 132, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "RibLobeL",
			shape = "Block",
			size = Vector3.new(0.36, 0.86, 0.88),
			cf = CFrame.new(-0.8, 2.72, 0.02, 0.990268, 0.139173, 0, -0.139173, 0.990268, 0, 0, 0, 1),
			color = Color3.fromRGB(88, 102, 44),
			material = Enum.Material.Plastic,
		},
		{
			name = "ShoulderLobeR",
			shape = "Ball",
			size = Vector3.new(1.18, 1.18, 1.18),
			cf = CFrame.new(1.04, 3.62, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(118, 132, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "RibLobeR",
			shape = "Block",
			size = Vector3.new(0.36, 0.86, 0.88),
			cf = CFrame.new(0.8, 2.72, 0.02, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1),
			color = Color3.fromRGB(88, 102, 44),
			material = Enum.Material.Plastic,
		},
		{
			name = "SandstoneMantleL",
			shape = "Block",
			size = Vector3.new(1.04, 0.46, 1.1),
			cf = CFrame.new(-1.1, 4.02, 0, 0.882948, 0.469472, 0, -0.4669, 0.878111, 0.104528, 0.049073, -0.092293, 0.994522),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "ChestCrustL",
			shape = "Block",
			size = Vector3.new(0.58, 1.26, 0.38),
			cf = CFrame.new(-0.72, 3.16, -0.66, 0.994522, 0, 0.104528, 0, 1, 0, -0.104528, 0, 0.994522),
			color = Color3.fromRGB(120, 96, 76),
			material = Enum.Material.Plastic,
		},
		{
			name = "SandstoneMantleR",
			shape = "Block",
			size = Vector3.new(1.04, 0.46, 1.1),
			cf = CFrame.new(1.1, 4.02, 0, 0.882948, -0.469472, 0, 0.4669, 0.878111, 0.104528, -0.049073, -0.092293, 0.994522),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "ChestCrustR",
			shape = "Block",
			size = Vector3.new(0.58, 1.26, 0.38),
			cf = CFrame.new(0.72, 3.16, -0.66, 0.994522, 0, -0.104528, 0, 1, 0, 0.104528, 0, 0.994522),
			color = Color3.fromRGB(120, 96, 76),
			material = Enum.Material.Plastic,
		},
		{
			name = "SolarCore",
			shape = "Block",
			size = Vector3.new(0.58, 0.58, 0.34),
			cf = CFrame.new(0, 3.14, -0.52, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1),
			color = Color3.fromRGB(255, 170, 32),
			material = Enum.Material.Neon,
			studs = false,
		},
		{
			name = "CoreBack",
			shape = "Block",
			size = Vector3.new(0.54, 0.54, 0.16),
			cf = CFrame.new(0, 3.14, -0.26, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1),
			color = Color3.fromRGB(239, 116, 25),
			material = Enum.Material.Neon,
			studs = false,
		},
		{
			name = "CoreRimL",
			shape = "Block",
			size = Vector3.new(0.86, 0.24, 0.34),
			cf = CFrame.new(0, 2.54, -0.64, 1, 0, 0, 0, 0.987688, 0.156434, 0, -0.156434, 0.987688),
			color = Color3.fromRGB(120, 96, 76),
			material = Enum.Material.Plastic,
		},
		{
			name = "CoreRimR",
			shape = "Block",
			size = Vector3.new(0.86, 0.24, 0.34),
			cf = CFrame.new(0, 3.74, -0.64, 1, 0, 0, 0, 0.987688, -0.156434, 0, 0.156434, 0.987688),
			color = Color3.fromRGB(120, 96, 76),
			material = Enum.Material.Plastic,
		},
		{
			name = "Leaf",
			shape = "Block",
			size = Vector3.new(0.58, 1.34, 0.6),
			cf = CFrame.new(-1.4, 3.14, 0.02, 0.990268, 0.139173, 0, -0.139173, 0.990268, 0, 0, 0, 1),
			color = Color3.fromRGB(118, 132, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftForearm",
			shape = "Block",
			size = Vector3.new(0.54, 1.62, 0.56),
			cf = CFrame.new(-1.52, 2.04, -0.06, 0.997564, 0.069756, 0, -0.069491, 0.993768, -0.087156, -0.00608, 0.086943, 0.996195),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftElbowThorn1",
			shape = "Wedge",
			size = Vector3.new(0.22, 0.28, 0.647765),
			cf = CFrame.new(-1.8, 2.94, 0.05, -0.259973, 0.536647, 0.80276, 0, 0.831345, -0.555756, -0.965616, -0.144482, -0.216128),
			color = Color3.fromRGB(255, 170, 32),
			material = Enum.Material.Neon,
			studs = false,
		},
		{
			name = "LeftElbowThorn2",
			shape = "Wedge",
			size = Vector3.new(0.18, 0.24, 0.612862),
			cf = CFrame.new(-1.77, 2.53, -0.21, 0.636881, 0.176116, 0.750577, 0, 0.973559, -0.228436, -0.770962, 0.145487, 0.620042),
			color = Color3.fromRGB(255, 170, 32),
			material = Enum.Material.Neon,
			studs = false,
		},
		{
			name = "LeftHand",
			shape = "Block",
			size = Vector3.new(0.68, 0.56, 0.74),
			cf = CFrame.new(-1.56, 1.18, -0.14, 1, 0, 0, 0, 0.990268, 0.139173, 0, -0.139173, 0.990268),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftClaw1",
			shape = "Wedge",
			size = Vector3.new(0.24, 0.28, 0.63726),
			cf = CFrame.new(-1.805, 0.71, -0.56, 0.945687, -0.275465, 0.172614, 0, 0.53099, 0.847378, -0.325079, -0.801354, 0.50215),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftClaw2",
			shape = "Wedge",
			size = Vector3.new(0.24, 0.28, 0.63726),
			cf = CFrame.new(-1.315, 0.71, -0.56, 0.945686, 0.275466, -0.172614, 0, 0.53099, 0.847378, 0.32508, -0.801354, 0.50215),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "Leaf",
			shape = "Block",
			size = Vector3.new(0.58, 1.34, 0.6),
			cf = CFrame.new(1.4, 3.14, 0.02, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1),
			color = Color3.fromRGB(118, 132, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightForearm",
			shape = "Block",
			size = Vector3.new(0.54, 1.62, 0.56),
			cf = CFrame.new(1.52, 2.04, -0.06, 0.997564, -0.069756, 0, 0.069491, 0.993768, -0.087156, 0.00608, 0.086943, 0.996195),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightElbowThorn1",
			shape = "Wedge",
			size = Vector3.new(0.22, 0.28, 0.647765),
			cf = CFrame.new(1.8, 2.94, 0.05, -0.259973, -0.536647, -0.80276, 0, 0.831345, -0.555756, 0.965616, -0.144482, -0.216128),
			color = Color3.fromRGB(255, 170, 32),
			material = Enum.Material.Neon,
			studs = false,
		},
		{
			name = "RightElbowThorn2",
			shape = "Wedge",
			size = Vector3.new(0.18, 0.24, 0.612862),
			cf = CFrame.new(1.77, 2.53, -0.21, 0.636881, -0.176116, -0.750577, 0, 0.973559, -0.228436, 0.770962, 0.145487, 0.620042),
			color = Color3.fromRGB(255, 170, 32),
			material = Enum.Material.Neon,
			studs = false,
		},
		{
			name = "RightHand",
			shape = "Block",
			size = Vector3.new(0.68, 0.56, 0.74),
			cf = CFrame.new(1.56, 1.18, -0.14, 1, 0, 0, 0, 0.990268, 0.139173, 0, -0.139173, 0.990268),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightClaw1",
			shape = "Wedge",
			size = Vector3.new(0.24, 0.28, 0.63726),
			cf = CFrame.new(1.315, 0.71, -0.56, 0.945686, -0.275466, 0.172614, 0, 0.53099, 0.847378, -0.32508, -0.801354, 0.50215),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightClaw2",
			shape = "Wedge",
			size = Vector3.new(0.24, 0.28, 0.63726),
			cf = CFrame.new(1.805, 0.71, -0.56, 0.945687, 0.275465, -0.172614, 0, 0.53099, 0.847378, 0.325079, -0.801354, 0.50215),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "HeadBase",
			shape = "Block",
			size = Vector3.new(1.22, 1.12, 0.94),
			cf = CFrame.new(0, 5.05, 0.06, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(176, 156, 132),
			material = Enum.Material.Plastic,
		},
		{
			name = "BrowPlate",
			shape = "Block",
			size = Vector3.new(1.14, 0.38, 0.44),
			cf = CFrame.new(0, 5.45, -0.32, 1, 0, 0, 0, 0.927184, -0.374607, 0, 0.374607, 0.927184),
			color = Color3.fromRGB(120, 96, 76),
			material = Enum.Material.Plastic,
		},
		{
			name = "JawCrust",
			shape = "Block",
			size = Vector3.new(1.02, 0.36, 0.42),
			cf = CFrame.new(0, 4.67, -0.3, 1, 0, 0, 0, 0.951057, 0.309017, 0, -0.309017, 0.951057),
			color = Color3.fromRGB(120, 96, 76),
			material = Enum.Material.Plastic,
		},
		{
			name = "Eye",
			shape = "Ball",
			size = Vector3.new(0.52, 0.52, 0.52),
			cf = CFrame.new(0, 5.06, -0.26, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(255, 170, 32),
			material = Enum.Material.Neon,
			studs = false,
		},
		{
			name = "Pupil",
			shape = "Block",
			size = Vector3.new(0.1, 0.3, 0.1),
			cf = CFrame.new(0, 5.06, -0.47, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(210, 61, 45),
			material = Enum.Material.Neon,
			studs = false,
		},
		{
			name = "CrownRay1",
			shape = "Wedge",
			size = Vector3.new(0.26, 0.88, 1.4),
			cf = CFrame.new(0.376222, 6.133662, 0.16, 0, -0.939693, -0.34202, 0, 0.34202, -0.939693, 1, 0, 0),
			color = Color3.fromRGB(210, 61, 45),
			material = Enum.Material.Plastic,
		},
		{
			name = "CrownRay2",
			shape = "Wedge",
			size = Vector3.new(0.26, 0.88, 1.4),
			cf = CFrame.new(-0.376222, 6.133662, 0.16, 0, 0.939693, 0.34202, 0, 0.34202, -0.939693, -1, 0, 0),
			color = Color3.fromRGB(210, 61, 45),
			material = Enum.Material.Plastic,
		},
		{
			name = "CrownRay3",
			shape = "Wedge",
			size = Vector3.new(0.26, 0.88, 1.4),
			cf = CFrame.new(0.952628, 5.650001, 0.16, 0, -0.5, -0.866025, 0, 0.866025, -0.5, 1, 0, 0),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "CrownRay4",
			shape = "Wedge",
			size = Vector3.new(0.26, 0.88, 1.4),
			cf = CFrame.new(-0.952628, 5.650001, 0.16, 0, 0.5, 0.866025, 0, 0.866025, -0.5, -1, 0, 0),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "CrownRay5",
			shape = "Wedge",
			size = Vector3.new(0.26, 0.88, 1.4),
			cf = CFrame.new(1.083288, 4.908987, 0.16, 0, 0.173648, -0.984808, 0, 0.984808, 0.173648, 1, 0, 0),
			color = Color3.fromRGB(210, 61, 45),
			material = Enum.Material.Plastic,
		},
		{
			name = "CrownRay6",
			shape = "Wedge",
			size = Vector3.new(0.26, 0.88, 1.4),
			cf = CFrame.new(-1.083288, 4.908987, 0.16, 0, -0.173648, 0.984808, 0, 0.984808, 0.173648, -1, 0, 0),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "CrownRay7",
			shape = "Wedge",
			size = Vector3.new(0.26, 0.88, 1.4),
			cf = CFrame.new(0.817459, 4.363957, 0.16, 0, 0.669131, -0.743145, 0, 0.743145, 0.669131, 1, 0, 0),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "CrownRay8",
			shape = "Wedge",
			size = Vector3.new(0.26, 0.88, 1.4),
			cf = CFrame.new(-0.817459, 4.363957, 0.16, 0, -0.669131, 0.743145, 0, 0.743145, 0.669131, -1, 0, 0),
			color = Color3.fromRGB(255, 198, 38),
			material = Enum.Material.Plastic,
		},
		{
			name = "InnerRay1",
			shape = "Wedge",
			size = Vector3.new(0.22, 0.64, 0.96),
			cf = CFrame.new(0, 5.920001, 0.4, 0, -1, 0, 0, 0, -1, 1, 0, 0),
			color = Color3.fromRGB(239, 116, 25),
			material = Enum.Material.Plastic,
		},
		{
			name = "InnerRay2",
			shape = "Wedge",
			size = Vector3.new(0.22, 0.64, 0.96),
			cf = CFrame.new(0.527086, 5.728157, 0.4, 0, 0.766044, -0.642788, 0, -0.642788, -0.766044, -1, 0, 0),
			color = Color3.fromRGB(239, 116, 25),
			material = Enum.Material.Plastic,
		},
		{
			name = "InnerRay3",
			shape = "Wedge",
			size = Vector3.new(0.22, 0.64, 0.96),
			cf = CFrame.new(-0.527086, 5.728157, 0.4, 0, -0.766044, 0.642788, 0, -0.642788, -0.766044, 1, 0, 0),
			color = Color3.fromRGB(239, 116, 25),
			material = Enum.Material.Plastic,
		},
		{
			name = "InnerRay4",
			shape = "Wedge",
			size = Vector3.new(0.22, 0.64, 0.96),
			cf = CFrame.new(0.807542, 5.242392, 0.4, 0, 0.173648, -0.984808, 0, -0.984808, -0.173648, -1, 0, 0),
			color = Color3.fromRGB(239, 116, 25),
			material = Enum.Material.Plastic,
		},
		{
			name = "InnerRay5",
			shape = "Wedge",
			size = Vector3.new(0.22, 0.64, 0.96),
			cf = CFrame.new(-0.807542, 5.242392, 0.4, 0, -0.173648, 0.984808, 0, -0.984808, -0.173648, 1, 0, 0),
			color = Color3.fromRGB(239, 116, 25),
			material = Enum.Material.Plastic,
		},
		{
			name = "InnerRay6",
			shape = "Wedge",
			size = Vector3.new(0.22, 0.64, 0.96),
			cf = CFrame.new(0.710141, 4.690001, 0.4, 0, -0.5, -0.866025, 0, -0.866025, 0.5, -1, 0, 0),
			color = Color3.fromRGB(239, 116, 25),
			material = Enum.Material.Plastic,
		},
	},
} :: { [string]: { PartSpec } }

--==============================================================================
-- THE OTHER FOUR, AUTHORED AS BUILDERS -- 2026-09-18
--
-- Dunebud, Paddlehop, Thornwhorl and Raincup were rebuilt from the approved
-- sheet `art/creatures/dustbowl/reference/dustbowl-design-proposals.png` (the
-- owner's concept render), as builders rather than serialized tables for the
-- reason GreenhollowForms gives. Suncrown above is untouched.
--
-- Authored in MOCKUP SPACE -- ground at Y = 0, front toward -Z, roughly the
-- Tiny frame's own studs -- and placed by PlantSculpt through replayPart's
-- arithmetic, so hs = FrameHeight / AuthoredHeight lands every one exactly on
-- its SeedData frame at every tier, as Suncrown already does.
--
-- WHAT IS SHARED. Every one of the four stands on tan root feet -- the biome's
-- stem colour, the way the old footing's roots were -- and every face is
-- CreatureModel.addFace's squint on a surface the builder points at.
--
-- THE NAMES ARE THE RIG, as in GreenhollowForms: `Leaf` arms swung about their
-- own centres; Thigh / Shin / Foot / Toe legs swung about the top of the thigh;
-- and Thornwhorl on the ROOT walker because its legs brace out sideways.
--==============================================================================

-- A stubby root foot, the Greenhollow one in the desert's tan.
local function rootFoot(k: PlantSculpt.Kit, prefix: string, side: number, hip: Vector3,
	sole: Vector3, thighW: number, footW: number, footL: number, thighColor: Color3,
	footColor: Color3, yawDeg: number, toes: number?)
	local footH = footW * 0.48
	local thighH = hip.Y - footH * 0.55
	k.block(prefix .. "Thigh", V3(thighW, thighH, thighW),
		CFrame.new((hip.X + sole.X) * 0.5, footH * 0.55 + thighH * 0.5, (hip.Z + sole.Z) * 0.5)
			* CFrame.Angles(0, 0, side * rad(-3)),
		thighColor)
	local footCF = CFrame.new(sole + V3(0, footH * 0.5, 0)) * CFrame.Angles(0, rad(yawDeg), 0)
	k.block(prefix .. "Foot", V3(footW, footH, footL), footCF, footColor)
	local spread = if toes == 3 then { -0.32, 0.32, 0 } else { -0.30, 0.30 }
	for i, dx in ipairs(spread) do
		local long = if i == 3 then 0.56 else 0.42
		k.wedge(prefix .. "Toe", V3(footW * 0.34, footH * 0.82, footL * long),
			footCF * CFrame.new(dx * footW, -footH * 0.09, -footL * (0.36 + long * 0.5))
				* CFrame.Angles(0, (if i == 1 then 1 elseif i == 2 then -1 else 0) * rad(11), 0),
			footColor)
	end
end

-- A limb segment as an upright-ish block: its Y runs from `bottom` up to
-- `top`, so PlantSway's hip -- the top of the highest leg part -- is the top
-- of the thigh and not the middle of a beam.
local function limb(k: PlantSculpt.Kit, name: string, top: Vector3, bottom: Vector3,
	w: number, d: number, color: Color3, overrun: number?)
	local o = overrun or 0
	local up = (top - bottom).Unit
	local len = (top - bottom).Magnitude + o * 2
	local fwd = Vector3.new(0, 0, -1)
	local right = up:Cross(fwd)
	if right.Magnitude < 1e-3 then
		right = Vector3.new(1, 0, 0)
	end
	right = right.Unit
	local back = right:Cross(up)
	return k.block(name, V3(w, len, d),
		CFrame.fromMatrix((top + bottom) * 0.5, right, up, back), color)
end

-- A flat slab from a to b whose thin axis is `normal`.
local function slab(k: PlantSculpt.Kit, name: string, a: Vector3, b: Vector3, w: number,
	thick: number, normal: Vector3, color: Color3, overrun: number?)
	local o = overrun or 0
	return k.block(name, V3(w, thick, (b - a).Magnitude + o * 2),
		PlantSculpt.look((a + b) * 0.5, b, normal), color)
end

-- A symmetric petal: two mirrored fins on one spine -- see GreenhollowForms.
local function petal(k: PlantSculpt.Kit, name: string, root: Vector3, tip: Vector3,
	halfW: number, thick: number, normal: Vector3, color: Color3)
	k.fin(name, root, tip, halfW, thick, normal, 1, color)
	k.fin(name, root, tip, halfW, thick, normal, -1, color)
end

-- One root of the ROOT WALKER -- see GreenhollowForms.rootLeg.
local function rootLeg(k: PlantSculpt.Kit, slot: number, socket: Vector3, knee: Vector3,
	anchor: Vector3, legW: number, footW: number, footL: number, legColor: Color3,
	footColor: Color3)
	local n = tostring(slot)
	local footH = footW * 0.46
	k.beam("RootRise" .. n, socket, knee, legW, legW * 0.9, legColor, nil, legW * 0.3)
	k.beam("RootKnuckle" .. n, knee, anchor + V3(0, footH * 0.7, 0), legW * 0.88, legW * 0.8,
		legColor, nil, legW * 0.25)
	local out = Vector3.new(anchor.X - socket.X, 0, anchor.Z - socket.Z)
	local footCF = PlantSculpt.look(anchor + V3(0, footH * 0.5, 0),
		anchor + V3(0, footH * 0.5, 0) + out.Unit)
	k.block("RootAnchor" .. n, V3(footW, footH, footL), footCF, footColor)
	for i, dx in ipairs({ -0.30, 0.30 }) do
		k.wedge("RootToe" .. (if i == 1 then "A" else "B") .. n,
			V3(footW * 0.36, footH * 0.82, footL * 0.44),
			footCF * CFrame.new(dx * footW, -footH * 0.09, -footL * 0.66)
				* CFrame.Angles(0, (if i == 1 then 1 else -1) * rad(12), 0),
			footColor)
	end
end

--==============================================================================
-- DUNEBUD -- a bud that peeks
--
-- One sentence: a cream bud sealed inside seven rust husk leaves that lean up
-- to a knot, one plate peeled down at the front so the face looks out of a
-- window, folded husk hands and short tan root feet -- shy. The husks are the
-- body; the cream is what shows through them.
--==============================================================================
local function dunebud(k: PlantSculpt.Kit, sp: SeedData.Species): PlantSculpt.Face
	local BODY, HUSK, KNOT = sp.Body, sp.Crown, sp.Accent
	local TAN, SOIL = sp.Stem, sp.Soil
	local FOOT = TAN:Lerp(SOIL, 0.30)
	local HUSK_DEEP = HUSK:Lerp(Color3.new(0, 0, 0), 0.16)

	for _, side in ipairs({ -1, 1 }) do
		local pre = if side < 0 then "Left" else "Right"
		rootFoot(k, pre, side, V3(side * 0.48, 0.95, 0), V3(side * 0.55, 0, -0.05),
			0.40, 0.58, 0.78, TAN, FOOT, side * -8)
	end

	-- THE BUD inside.
	k.ball("Belly", 1.75, CFrame.new(0, 1.45, 0.05), BODY)
	k.ball("Bud", 2.10, CFrame.new(0, 2.05, 0), BODY)

	-- FIVE HUSKS round the back and sides, each a KITE of two mirrored petals
	-- that meet at the widest ring: the upper one leans in to the knot, the
	-- lower one narrows down toward the feet. Widest in the middle is what
	-- makes the bud round-shouldered rather than a tepee or a basket. The front
	-- pair are single fins framing the window.
	-- Yaw runs (sin a, cos a): 0 is the BACK (+Z) and 180 the front (-Z). The
	-- window is the gap between the two front fins at 130 and 230.
	local HUSKS = {
		-- yaw, tip height, half width, deep
		{ 256, 3.52, 0.58, true }, { 308, 3.58, 0.60, false }, { 0, 3.64, 0.62, true },
		{ 52, 3.58, 0.60, false }, { 104, 3.52, 0.58, true },
	}
	for _, h in ipairs(HUSKS) do
		local a = rad(h[1] :: number)
		local sx, cz = math.sin(a), math.cos(a)
		local hw = h[3] :: number
		local color = if h[4] then HUSK_DEEP else HUSK
		local normal = V3(sx, 0.1, cz)
		local waist = V3(sx * 1.34, 1.90, cz * 1.34)
		petal(k, "Husk", waist, V3(sx * 0.52, h[2] :: number, cz * 0.52), hw, 0.20, normal, color)
		petal(k, "Husk", waist, V3(sx * 0.90, 0.92, cz * 0.90), hw * 0.90, 0.20, normal, color)
	end
	for _, side in ipairs({ -1, 1 }) do
		local a = rad(180 + side * 50)
		local sx, cz = math.sin(a), math.cos(a)
		k.fin("Husk", V3(sx * 1.16, 0.95, cz * 1.16), V3(sx * 0.62, 3.30, cz * 0.62),
			0.80, 0.20, V3(sx, 0.1, cz), -side, HUSK)
	end
	-- Seated ON THE BUD (its top is 3.10), among the husk tips rather than on
	-- them: the tips move outward with girth and the knot does not, so a knot
	-- resting on the tips at Tiny is a knot in the air at Colossal (0.63 studs
	-- of daylight, PlantFormsSpec). The bud is on the axis and scales exactly
	-- as the knot does, so this contact holds at every tier.
	k.ball("Knot", 0.60, CFrame.new(0, 3.35, 0.06), KNOT)
	-- THE PEEL: the front plate folded down and out.
	k.block("Peel", V3(1.16, 0.92, 0.20), CFrame.new(0, 1.02, -1.02) * CFrame.Angles(rad(28), 0, 0), HUSK)

	-- THE HANDS: folded husk, one each side of the window.
	for _, side in ipairs({ -1, 1 }) do
		k.blade("Leaf", V3(side * 0.96, 1.52, -0.52), V3(side * 0.74, 0.96, -1.16),
			0.46, 0.20, V3(side * 0.3, 0.6, -0.75), HUSK)
	end

	return k.face(CFrame.new(0, 2.10, 0), 1.20, 0.98, BODY)
end

--==============================================================================
-- PADDLEHOP -- a pad on legs, and a cactus first
--
-- One sentence: one flat sage prickly-pear pad is the whole face and torso,
-- rimmed in dark olive, with a smaller pad budding off its top corner that
-- carries the single coral bloom, two side pads for arms, sparse cream thorns,
-- and two bent tan root legs in a hopping stance. The pad reads as a pad from
-- the side because its rims are rounds and its thorns are on the edges.
--==============================================================================
local function paddlehop(k: PlantSculpt.Kit, sp: SeedData.Species): PlantSculpt.Face
	local PAD, RIM, BLOOM = sp.Body, sp.Crown, sp.Accent
	local TAN, SOIL = sp.Stem, sp.Soil
	local FOOT = TAN:Lerp(SOIL, 0.30)
	local THORN = BLOOM:Lerp(Color3.new(1, 1, 1), 0.62)
	local BUD = PAD:Lerp(RIM, 0.30)

	-- THE LEGS: thigh out, shin back under, foot forward. A hop about to happen.
	for _, side in ipairs({ -1, 1 }) do
		local pre = if side < 0 then "Left" else "Right"
		limb(k, pre .. "Thigh", V3(side * 0.44, 1.42, 0), V3(side * 0.88, 0.78, -0.12), 0.36, 0.36, TAN, 0.10)
		limb(k, pre .. "Shin", V3(side * 0.88, 0.78, -0.12), V3(side * 0.78, 0.26, -0.42), 0.30, 0.30, TAN, 0.08)
		local footCF = CFrame.new(side * 0.80, 0.13, -0.50) * CFrame.Angles(0, side * rad(-12), 0)
		k.block(pre .. "Foot", V3(0.56, 0.26, 0.82), footCF, FOOT)
		for i, dx in ipairs({ -0.30, 0.30 }) do
			k.wedge(pre .. "Toe", V3(0.20, 0.22, 0.36),
				footCF * CFrame.new(dx * 0.56, -0.02, -0.47) * CFrame.Angles(0, (if i == 1 then 1 else -1) * rad(11), 0),
				FOOT)
		end
	end

	-- THE PAD and its rim.
	k.block("PadCore", V3(2.10, 2.90, 0.66), CFrame.new(0, 2.95, 0), PAD)
	k.coin("PadRim", 2.10, 0.60, CFrame.new(0, 4.40, 0), RIM)
	k.coin("PadRim", 2.10, 0.60, CFrame.new(0, 1.50, 0), RIM)
	for _, side in ipairs({ -1, 1 }) do
		k.block("PadRim", V3(0.28, 2.74, 0.60), CFrame.new(side * 1.12, 2.95, 0), RIM)
	end

	-- THE BUD off the top corner, carrying the bloom.
	k.block("PadBud", V3(0.90, 1.10, 0.50), CFrame.new(0.76, 4.78, 0.04) * CFrame.Angles(0, 0, rad(-22)), BUD)
	k.coin("PadRim", 0.90, 0.46, CFrame.new(0.98, 5.30, 0.04) * CFrame.Angles(0, 0, rad(-22)), RIM)
	k.ball("Bloom", 0.52, CFrame.new(1.04, 5.62, 0.02), BLOOM)
	for i, yaw in ipairs({ 20, 140, 260 }) do
		local a = rad(yaw)
		local sx, cz = math.sin(a), math.cos(a)
		k.fin("Petal", V3(1.04 + sx * 0.12, 5.56, 0.02 + cz * 0.12), V3(1.04 + sx * 0.46, 5.82, 0.02 + cz * 0.46),
			0.30, 0.10, V3(sx, 0.8, cz), if i % 2 == 0 then 1 else -1, BLOOM)
	end

	-- THE SIDE PADS are the arms: one round each.
	for _, side in ipairs({ -1, 1 }) do
		k.coin("Leaf", 1.06, 0.42,
			CFrame.new(side * 1.38, 2.78, -0.08) * CFrame.Angles(0, side * rad(-24), side * rad(-16)),
			PAD)
	end

	-- FIVE THORNS on the edges, nowhere else.
	local THORNS = {
		{ V3(-1.02, 3.92, -0.20), V3(-1.34, 4.22, -0.30) },
		{ V3(1.06, 2.14, -0.18), V3(1.42, 1.98, -0.28) },
		{ V3(-1.06, 2.40, 0.12), V3(-1.42, 2.30, 0.16) },
		{ V3(0.56, 4.56, -0.28), V3(0.72, 4.96, -0.44) },
		{ V3(0.30, 5.40, 0.20), V3(0.34, 5.86, 0.30) },
	}
	for _, t in ipairs(THORNS) do
		k.blade("Thorn", t[1], t[2], 0.16, 0.16, V3(0, 1, 0), THORN)
	end

	return k.face(CFrame.new(0, 3.18, 0), 1.56, 0.33, PAD)
end

--==============================================================================
-- THORNWHORL -- five blades, one spiral
--
-- One sentence: a small sandy face in front of a hub, five unequal rust blades
-- sweeping out of the hub in a counter-clockwise spiral that curls toward the
-- viewer, each ending in a pale hooked tip, on four tan roots braced wide and
-- low. The spiral holds from every side because the blades curl in DEPTH as
-- well as in angle: each one starts behind the head and its hook ends in front
-- of it. Nothing sits in the front cone, so the face stays visible.
--
-- ROOT WALKER: the roots brace out sideways, which the hip rig cannot step.
--==============================================================================
local function thornwhorl(k: PlantSculpt.Kit, sp: SeedData.Species): PlantSculpt.Face
	local SAND, BLADE, HOOK = sp.Body, sp.Crown, sp.Accent
	local TAN, SOIL = sp.Stem, sp.Soil
	local FOOT = TAN:Lerp(SOIL, 0.30)
	local BLADE_DEEP = BLADE:Lerp(Color3.new(0, 0, 0), 0.16)

	local LEGS = {
		-- slot, sx, sz
		{ 1, -1, -1 }, { 2, 1, -1 }, { 3, 1, 1 }, { 4, -1, 1 },
	}
	for _, leg in ipairs(LEGS) do
		local slot, sx, sz = leg[1], leg[2], leg[3]
		rootLeg(k, slot,
			V3(sx * 0.40, 1.40, sz * 0.30),
			V3(sx * 1.14, 0.90, sz * 0.78),
			V3(sx * 1.52, 0, sz * 1.08),
			0.34, 0.60, 0.80, TAN, FOOT)
	end

	-- THE HUB and the face in front of it.
	k.ball("Hub", 1.34, CFrame.new(0, 2.40, 0.74), BLADE_DEEP)
	k.disc("Collar", 1.62, 0.52, CFrame.new(0, 2.32, 0.52), BLADE)
	k.ball("Head", 1.90, CFrame.new(0, 2.35, -0.22), SAND)

	-- FIVE BLADES. Each is two slabs sweeping round the hub in the frontal
	-- plane and a pale fin hooking off the end.
	local BLADES = {
		-- start angle, length scale, deep
		{ 28, 1.15, false }, { 88, 0.94, true }, { 146, 1.06, false },
		{ 236, 0.84, true }, { 318, 1.00, false },
	}
	local function onWhorl(deg: number, r: number, z: number): Vector3
		local a = rad(deg)
		return V3(math.cos(a) * r, 2.40 + math.sin(a) * r, z)
	end
	for i, b in ipairs(BLADES) do
		local a0, L = b[1] :: number, b[2] :: number
		local color = if b[3] then BLADE_DEEP else BLADE
		local p0 = onWhorl(a0, 0.50, 0.72)
		local p1 = onWhorl(a0 + 24, 1.40 * L, 0.52)
		local p2 = onWhorl(a0 + 50, 2.16 * L, 0.26)
		local p3 = onWhorl(a0 + 66, 2.58 * L, -0.02)
		local normal = V3(0, 0, 1)
		slab(k, "Blade", p0, p1, 0.92 * L, 0.24, normal, color, 0.14)
		slab(k, "Blade", p1, p2, 0.80 * L, 0.24, normal, color, 0.12)
		k.fin("Hook", p2, p3, 0.52 * L, 0.22, normal, if i % 2 == 0 then 1 else -1, HOOK)
	end

	return k.face(CFrame.new(0, 2.35, -0.22), 1.30, 0.90, SAND)
end

--==============================================================================
-- RAINCUP -- a cup you can see into
--
-- One sentence: a blue cupped flower on a short curved stalk, six unequal
-- petals rising from the rim of a round blue bowl around a yellow floor, one
-- blue droplet caught inside, gentle eyes on the outside of the bowl under the
-- rim, two supporting leaves and branching tan root feet. The floor sits AT the
-- bowl's top, the front petals are the short ones, and the back petals the
-- tall ones -- so from player height the eye looks over the front rim onto
-- yellow, and the cavity is real rather than a colour buried in a cylinder.
--==============================================================================
local function raincup(k: PlantSculpt.Kit, sp: SeedData.Species): PlantSculpt.Face
	local BLUE, YELLOW, PINK = sp.Body, sp.Crown, sp.Accent
	local LEAF, TAN, SOIL = sp.Leaf, sp.Stem, sp.Soil
	local FOOT = TAN:Lerp(SOIL, 0.30)
	local BLUE_DEEP = BLUE:Lerp(Color3.new(0, 0, 0), 0.22)
	local DROP = Color3.fromRGB(74, 172, 246)
	local DROP_GLINT = Color3.fromRGB(206, 236, 248)

	for _, side in ipairs({ -1, 1 }) do
		local pre = if side < 0 then "Left" else "Right"
		rootFoot(k, pre, side, V3(side * 0.38, 1.05, 0), V3(side * 0.52, 0, -0.05),
			0.32, 0.54, 0.82, TAN, FOOT, side * -9, 3)
	end

	-- THE STALK, curved, and the two leaves off it.
	k.chain("Stalk", { V3(0, 0.80, 0), V3(0.06, 1.90, -0.10), V3(-0.04, 3.00, -0.02) }, 0.44, 0.44, 0.88, LEAF)
	for _, side in ipairs({ -1, 1 }) do
		k.blade("Leaf", V3(side * 0.14, 1.66, -0.02), V3(side * 1.18, 1.04, -0.38),
			0.56, 0.16, V3(side * 0.2, 0.95, -0.1), LEAF)
	end

	-- THE BOWL: a calyx, the round the face sits on, the yellow floor at its top.
	k.disc("Calyx", 1.30, 0.56, CFrame.new(0, 2.92, 0), BLUE_DEEP)
	k.ball("Cup", 2.00, CFrame.new(0, 3.55, 0), BLUE)
	k.disc("Floor", 1.92, 0.30, CFrame.new(0, 4.34, 0), YELLOW)
	k.ball("Throat", 0.54, CFrame.new(0.10, 4.50, 0.08), YELLOW)

	-- FIVE BROAD PETALS, mirrored pairs, short in front and tall behind, all
	-- leaning out so the cup opens.
	local PETALS = {
		-- yaw (180 is the front), tip height, half width, reach
		{ 156, 5.28, 0.50, 1.50 }, { 228, 5.34, 0.48, 1.52 }, { 300, 5.86, 0.56, 1.50 },
		{ 12, 6.06, 0.58, 1.48 }, { 84, 5.78, 0.54, 1.50 },
	}
	for _, pt in ipairs(PETALS) do
		local a = rad(pt[1] :: number)
		local sx, cz = math.sin(a), math.cos(a)
		local out = pt[4] :: number
		petal(k, "Petal", V3(sx * 0.80, 4.06, cz * 0.80), V3(sx * out, pt[2] :: number, cz * out),
			pt[3] :: number, 0.18, V3(sx, 0.25, cz), BLUE)
	end
	-- PINK on two petals only, on their inner faces.
	for _, i in ipairs({ 3, 5 }) do
		local pt = PETALS[i]
		local a = rad(pt[1] :: number)
		local sx, cz = math.sin(a), math.cos(a)
		local out = (pt[4] :: number) * 0.84
		slab(k, "PetalBlush", V3(sx * 0.88, 4.40, cz * 0.88), V3(sx * out, (pt[2] :: number) - 0.40, cz * out),
			0.40, 0.06, V3(sx, 0.25, cz), PINK)
	end

	-- THE DROPLET, opaque, sitting in the bowl.
	k.ball("Bead", 0.46, CFrame.new(-0.34, 4.70, -0.20), DROP, { smooth = true })
	k.ball("BeadGlint", 0.16, CFrame.new(-0.45, 4.82, -0.32), DROP_GLINT, { smooth = true })

	return k.face(CFrame.new(0, 3.50, 0), 1.26, 0.92, BLUE)
end

--==============================================================================
-- THE TABLE THE PLAYER ASKS -- see GreenhollowForms.AuthoredHeight.
--==============================================================================
DustbowlForms.AuthoredHeight = {
	dunebud = 3.68,
	paddlehop = 5.89,
	thornwhorl = 5.86,
	raincup = 6.08,
} :: { [string]: number }

local BUILDERS: { [string]: (PlantSculpt.Kit, SeedData.Species) -> PlantSculpt.Face? } = {
	dunebud = dunebud,
	paddlehop = paddlehop,
	thornwhorl = thornwhorl,
	raincup = raincup,
}

function DustbowlForms.Build(model: Model, id: string, at: CFrame, hs: number,
	gs: number, sp: SeedData.Species): PlantSculpt.Face?
	local builder = BUILDERS[id]
	if not builder then
		return nil
	end
	return builder(PlantSculpt.new(model, at, hs, gs), sp)
end

return DustbowlForms
