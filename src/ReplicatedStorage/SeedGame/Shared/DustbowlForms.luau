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

local DustbowlForms = {}

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

return DustbowlForms
