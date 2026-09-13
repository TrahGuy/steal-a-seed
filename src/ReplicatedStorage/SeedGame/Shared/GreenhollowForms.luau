--!strict
--==============================================================================
-- GREENHOLLOW, AS BUILT
--
-- Bellchime, the porcelain dusk-chime. Authored in tools/art/bellchime_bloom.luau
-- against art/creatures/bellchime/reference/bellchime-concept-porcelain-chime.jpg,
-- previewed in Edit, and lifted here part for part. Change the tool, re-run its
-- serialize(), paste the result over the table below -- never the other way
-- round, because the tool is where the geometry is reasoned about and this is
-- only where it is kept.
--
-- WHAT IT REPLACES, AND IT IS NOT WHAT ANYONE THOUGHT. Bellchime carried
-- Form = "bell", and there is no "bell" arm in CreatureModel's head chain --
-- cube, orb, teardrop, mushroom, husk, pad, whorl and cup, and then the chain
-- ends. So the Epic of the starter biome fell straight through it and shipped as
-- 26 parts with NO FLOWER AT ALL: a bare stem, seven soil clods, four leaves and
-- a face, standing 4.78 studs against a 6.20 frame. It has been a headless stalk
-- for as long as the form chain has had that shape.
--
-- IT IS DATA, NOT ART DIRECTION, replayed by the same CreatureModel player
-- Tanglemire and Dustbowl use: one factor hs = FrameHeight / PreviewHeight
-- conforms the mockup to the tier frame, and girth spreads the parts apart
-- horizontally rather than scaling them.
--
-- CFRAMES CARRY ALL TWELVE COMPONENTS. Thirty of the forty-six parts are rotated
-- off-axis -- every leaf, sepal, bell panel and rim lobe -- and Euler angles
-- would read better without round-tripping exactly.
--
-- WHY ONLY ONE SPECIES IS IN HERE. Greenhollow's other four still come out of
-- the shared stem-and-footing builder and they are not broken -- they have head
-- branches that match. CreatureModel asks this file by species id rather than by
-- biome for exactly that reason: an id with no entry falls through to the
-- builder that already serves it.
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
	-- Studded unless this says otherwise. Only the two glowing parts turn them
	-- off: neon takes its light from the material, and a studded neon face reads
	-- as a dirty one.
	studs: boolean?,
}

local GreenhollowForms = {}

--==============================================================================
-- What the mockup WAS, in its own studs, from its lowest leaf tip to the top of
-- the arching stem. It never changes: the species Height in SeedData is what it
-- SHIPS at, and hs reconciles the two.
--==============================================================================
GreenhollowForms.PreviewHeight = {
	bellchime = 6.2204,
} :: { [string]: number }

--==============================================================================
-- THE PORCELAIN DUSK-CHIME, 46 PARTS
--
--    8  the arching stem in five walked segments, its collar, and two sprouts
--    3  the calyx gripping the top of the bell
--   13  the corolla: a cap, six porcelain panels, six scalloped pink lobes
--    3  the lit throat, the filament and the pearl clapper hung below the hem
--    6  the little face that looks out from under it
--    5  two sweeping leaves and three low ones
--    8  two hanging chime buds, each a stalk, a bud, a lip and a brass clapper
--
-- Two names are load-bearing. The two big leaves are called `Leaf`, which is the
-- only name PlantSway swings as an arm; Left/Right Eye and Pupil are what its
-- gaze rig pairs by prefix. Nothing here carries a LEG_WORD, which is correct --
-- this one sways, it does not walk.
--==============================================================================
GreenhollowForms.Plants = {
	bellchime = {
		{
			name = "StemBase",
			shape = "Block",
			size = Vector3.new(0.58, 0.58, 1.980562),
			cf = CFrame.new(0.01, 0.999741, 0.32, 0.999937, 0.000252, -0.011232, -0.011235, 0.022463, -0.999685, 0, 0.999748, 0.022465),
			color = Color3.fromRGB(124, 182, 92),
			material = Enum.Material.Plastic,
		},
		{
			name = "StemMid",
			shape = "Block",
			size = Vector3.new(0.5, 0.5, 1.81046),
			cf = CFrame.new(0.04, 2.699741, 0.21, 0.999695, 0.002725, -0.024533, -0.024684, 0.110365, -0.993585, 0, 0.993887, 0.110398),
			color = Color3.fromRGB(124, 182, 92),
			material = Enum.Material.Plastic,
		},
		{
			name = "StemArch1",
			shape = "Block",
			size = Vector3.new(0.44, 0.44, 1.552983),
			cf = CFrame.new(0.07, 4.159741, -0.13, 0.999201, -0.0373, -0.014358, 0, 0.359229, -0.933249, 0.039968, 0.932504, 0.358942),
			color = Color3.fromRGB(124, 182, 92),
			material = Enum.Material.Plastic,
		},
		{
			name = "StemArch2",
			shape = "Block",
			size = Vector3.new(0.38, 0.38, 1.397497),
			cf = CFrame.new(0.07, 5.294741, -0.78, 0.999688, 0.019278, 0.015905, 0, 0.636383, -0.771373, -0.024992, 0.771132, 0.636184),
			color = Color3.fromRGB(124, 182, 92),
			material = Enum.Material.Plastic,
		},
		{
			name = "StemArch3",
			shape = "Block",
			size = Vector3.new(0.32, 0.32, 1.003233),
			cf = CFrame.new(0.04, 5.914741, -1.6, 0.998868, 0.01454, 0.045288, 0, 0.95213, -0.305695, -0.047565, 0.305349, 0.951052),
			color = Color3.fromRGB(124, 182, 92),
			material = Enum.Material.Plastic,
		},
		{
			name = "Collar",
			shape = "Block",
			size = Vector3.new(0.5, 0.28, 0.48),
			cf = CFrame.new(0.02, 5.929741, -2.1, 0.939693, 0, 0.34202, 0.082742, 0.970296, -0.227332, -0.331861, 0.241922, 0.91178),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "Sprout1",
			shape = "Wedge",
			size = Vector3.new(0.1, 0.26, 0.809197),
			cf = CFrame.new(-0.472806, 0.399741, -0.129397, 0.615662, 0.603767, 0.506385, 0, 0.642612, -0.766192, -0.788011, 0.471715, 0.395632),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "Sprout2",
			shape = "Wedge",
			size = Vector3.new(0.1, 0.26, 0.666033),
			cf = CFrame.new(0.494451, 0.339741, 0.502904, -0.469472, -0.662841, -0.5833, 0, 0.660628, -0.750714, 0.882948, -0.352439, -0.310146),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "Sepal1",
			shape = "Wedge",
			size = Vector3.new(0.14, 0.34, 0.707672),
			cf = CFrame.new(0.198964, 5.609741, -1.69804, 0.275881, 0.913545, -0.298872, 0.734804, 0, 0.67828, 0.619639, -0.406737, -0.671277),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "Sepal2",
			shape = "Wedge",
			size = Vector3.new(0.14, 0.34, 0.707672),
			cf = CFrame.new(0.253164, 5.609741, -2.473141, 0.359434, -0.848048, -0.389387, 0.734804, 0, 0.67828, -0.575214, -0.529919, 0.623149),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "Sepal3",
			shape = "Wedge",
			size = Vector3.new(0.14, 0.34, 0.707672),
			cf = CFrame.new(-0.415718, 5.609741, -2.161236, -0.671679, -0.139173, 0.727653, 0.734804, 0, 0.67828, -0.094398, 0.990268, 0.102265),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "BellCap",
			shape = "Ball",
			size = Vector3.new(1.12, 1.12, 1.12),
			cf = CFrame.new(0.02, 5.549741, -2.1, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(214, 226, 242),
			material = Enum.Material.Plastic,
		},
		{
			name = "BellPanel1",
			shape = "Block",
			size = Vector3.new(0.86, 0.18, 1.460588),
			cf = CFrame.new(-0.014542, 4.869741, -1.440904, -0.99863, -0.047697, 0.021541, 0, 0.411586, 0.911371, -0.052336, 0.910122, -0.411022),
			color = Color3.fromRGB(214, 226, 242),
			material = Enum.Material.Plastic,
		},
		{
			name = "BellPanel2",
			shape = "Block",
			size = Vector3.new(0.86, 0.18, 1.460588),
			cf = CFrame.new(0.613204, 4.869741, -1.810675, -0.438371, 0.819135, -0.369931, 0, 0.411586, 0.911371, 0.898794, 0.399518, -0.180428),
			color = Color3.fromRGB(214, 226, 242),
			material = Enum.Material.Plastic,
		},
		{
			name = "BellPanel3",
			shape = "Block",
			size = Vector3.new(0.86, 0.18, 1.460588),
			cf = CFrame.new(0.608064, 4.869741, -2.399634, 0.453991, 0.812037, -0.366726, 0, 0.411586, 0.911371, 0.891006, -0.413754, 0.186856),
			color = Color3.fromRGB(182, 198, 224),
			material = Enum.Material.Plastic,
		},
		{
			name = "BellPanel4",
			shape = "Block",
			size = Vector3.new(0.86, 0.18, 1.460588),
			cf = CFrame.new(-0.026039, 4.869741, -2.758392, 0.997564, -0.063574, 0.028711, 0, 0.411586, 0.911371, -0.069756, -0.909151, 0.410584),
			color = Color3.fromRGB(214, 226, 242),
			material = Enum.Material.Plastic,
		},
		{
			name = "BellPanel5",
			shape = "Block",
			size = Vector3.new(0.86, 0.18, 1.460588),
			cf = CFrame.new(-0.533523, 4.869741, -2.459462, 0.544639, -0.76434, 0.345185, 0, 0.411587, 0.911371, -0.83867, -0.496368, 0.224166),
			color = Color3.fromRGB(214, 226, 242),
			material = Enum.Material.Plastic,
		},
		{
			name = "BellPanel6",
			shape = "Block",
			size = Vector3.new(0.86, 0.18, 1.460588),
			cf = CFrame.new(-0.527165, 4.869741, -1.730933, -0.559193, -0.755561, 0.341221, 0, 0.411587, 0.911371, -0.829038, 0.509632, -0.230156),
			color = Color3.fromRGB(182, 198, 224),
			material = Enum.Material.Plastic,
		},
		{
			name = "RimPetal1",
			shape = "Block",
			size = Vector3.new(0.72, 0.2, 0.624059),
			cf = CFrame.new(0.601561, 4.209741, -1.237801, -0.829038, 0.328902, -0.452239, 0, 0.808735, 0.588172, 0.559193, 0.487617, -0.670472),
			color = Color3.fromRGB(240, 150, 168),
			material = Enum.Material.Plastic,
		},
		{
			name = "RimPetal2",
			shape = "Block",
			size = Vector3.new(0.72, 0.2, 0.624059),
			cf = CFrame.new(1.056042, 4.209741, -2.009358, -0.087156, 0.585934, -0.805658, 0, 0.808736, 0.588173, 0.996195, 0.051262, -0.070486),
			color = Color3.fromRGB(240, 150, 168),
			material = Enum.Material.Plastic,
		},
		{
			name = "RimPetal3",
			shape = "Block",
			size = Vector3.new(0.72, 0.2, 0.624059),
			cf = CFrame.new(0.475906, 4.209741, -3.034746, 0.898794, 0.257838, -0.354526, 0, 0.808736, 0.588172, 0.438371, -0.528646, 0.726887),
			color = Color3.fromRGB(240, 150, 168),
			material = Enum.Material.Plastic,
		},
		{
			name = "RimPetal4",
			shape = "Block",
			size = Vector3.new(0.72, 0.2, 0.624059),
			cf = CFrame.new(-0.419523, 4.209741, -3.04256, 0.906308, -0.248573, 0.341787, 0, 0.808735, 0.588173, -0.422619, -0.533065, 0.732963),
			color = Color3.fromRGB(240, 150, 168),
			material = Enum.Material.Plastic,
		},
		{
			name = "RimPetal5",
			shape = "Block",
			size = Vector3.new(0.72, 0.2, 0.624059),
			cf = CFrame.new(-1.017467, 4.209741, -2.027453, -0.069757, -0.58674, 0.806765, 0, 0.808735, 0.588173, -0.997564, 0.041029, -0.056415),
			color = Color3.fromRGB(240, 150, 168),
			material = Enum.Material.Plastic,
		},
		{
			name = "RimPetal6",
			shape = "Block",
			size = Vector3.new(0.72, 0.2, 0.624059),
			cf = CFrame.new(-0.576519, 4.209741, -1.248082, -0.819152, -0.337362, 0.463872, 0, 0.808736, 0.588172, -0.573577, 0.481803, -0.662477),
			color = Color3.fromRGB(240, 150, 168),
			material = Enum.Material.Plastic,
		},
		{
			name = "BellThroat",
			shape = "Cylinder",
			size = Vector3.new(0.16, 1.3, 1.3),
			cf = CFrame.new(0.02, 4.609741, -2.1, 0, -1, 0, 1, 0, 0, 0, 0, 1),
			color = Color3.fromRGB(255, 212, 150),
			material = Enum.Material.Neon,
			studs = false,
		},
		{
			name = "PearlStem",
			shape = "Cylinder",
			size = Vector3.new(1.1, 0.12, 0.12),
			cf = CFrame.new(0.02, 5.049741, -2.1, 0, -1, 0, 1, 0, 0, 0, 0, 1),
			color = Color3.fromRGB(246, 240, 224),
			material = Enum.Material.Plastic,
		},
		{
			name = "Pearl",
			shape = "Ball",
			size = Vector3.new(0.84, 0.84, 0.84),
			cf = CFrame.new(0.02, 4.169741, -2.1, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(255, 228, 156),
			material = Enum.Material.Neon,
			studs = false,
		},
		{
			name = "FaceOrb",
			shape = "Ball",
			size = Vector3.new(0.84, 0.84, 0.84),
			cf = CFrame.new(0.02, 3.329741, -2.3, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(246, 240, 224),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftEye",
			shape = "Ball",
			size = Vector3.new(0.23, 0.23, 0.23),
			cf = CFrame.new(-0.19, 3.389741, -2.66, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(58, 48, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeftPupil",
			shape = "Ball",
			size = Vector3.new(0.09, 0.09, 0.09),
			cf = CFrame.new(-0.22, 3.439741, -2.74, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(255, 255, 255),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightEye",
			shape = "Ball",
			size = Vector3.new(0.23, 0.23, 0.23),
			cf = CFrame.new(0.23, 3.389741, -2.66, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(58, 48, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "RightPupil",
			shape = "Ball",
			size = Vector3.new(0.09, 0.09, 0.09),
			cf = CFrame.new(0.26, 3.439741, -2.74, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(255, 255, 255),
			material = Enum.Material.Plastic,
		},
		{
			name = "Smile",
			shape = "Block",
			size = Vector3.new(0.2, 0.05, 0.06),
			cf = CFrame.new(0.02, 3.149741, -2.7, 1, 0, 0, 0, 0.990268, 0.139173, 0, -0.139173, 0.990268),
			color = Color3.fromRGB(58, 48, 54),
			material = Enum.Material.Plastic,
		},
		{
			name = "Leaf",
			shape = "Wedge",
			size = Vector3.new(0.13, 0.62, 3.418888),
			cf = CFrame.new(-0.89, 3.069741, 0.41, -0.260523, 0.89236, 0.368541, 0, 0.381723, -0.924277, -0.965468, -0.240795, -0.099448),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "Leaf",
			shape = "Wedge",
			size = Vector3.new(0.13, 0.56, 2.804354),
			cf = CFrame.new(0.84, 2.609741, -0.03, 0.331906, -0.861118, -0.385115, 0, 0.408259, -0.912866, 0.943312, 0.302986, 0.135504),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeafLow1",
			shape = "Wedge",
			size = Vector3.new(0.11, 0.46, 1.324538),
			cf = CFrame.new(-0.73, 1.139741, -0.26, 0.546789, 0.391916, 0.739881, 0, 0.883682, -0.468088, -0.837271, 0.255945, 0.483187),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeafLow2",
			shape = "Wedge",
			size = Vector3.new(0.11, 0.44, 1.23499),
			cf = CFrame.new(0.78, 0.959741, -0.16, 0.488603, -0.324985, -0.809723, 0, 0.928043, -0.372473, 0.872506, 0.181991, 0.453445),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "LeafLow3",
			shape = "Wedge",
			size = Vector3.new(0.1, 0.4, 1.109414),
			cf = CFrame.new(0.21, 0.909741, 0.8, -0.942627, -0.132406, -0.306468, 0, 0.917989, -0.396606, 0.333847, -0.373851, -0.865321),
			color = Color3.fromRGB(86, 150, 66),
			material = Enum.Material.Plastic,
		},
		{
			name = "BudStalk1",
			shape = "Block",
			size = Vector3.new(0.12, 0.12, 1.283047),
			cf = CFrame.new(-0.73, 4.459741, 0.11, -0.087384, 0.252612, 0.963614, 0, 0.967314, -0.253582, -0.996175, -0.022159, -0.084528),
			color = Color3.fromRGB(124, 182, 92),
			material = Enum.Material.Plastic,
		},
		{
			name = "BudBody1",
			shape = "Ball",
			size = Vector3.new(0.36, 0.36, 0.36),
			cf = CFrame.new(-1.34, 4.209741, 0.17, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(214, 226, 242),
			material = Enum.Material.Plastic,
		},
		{
			name = "BudTip1",
			shape = "Block",
			size = Vector3.new(0.3096, 0.1584, 0.3096),
			cf = CFrame.new(-1.34, 4.022541, 0.17, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(240, 150, 168),
			material = Enum.Material.Plastic,
		},
		{
			name = "BudBell1",
			shape = "Ball",
			size = Vector3.new(0.1296, 0.1296, 0.1296),
			cf = CFrame.new(-1.34, 3.900141, 0.17, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(226, 186, 96),
			material = Enum.Material.Plastic,
		},
		{
			name = "BudStalk2",
			shape = "Block",
			size = Vector3.new(0.12, 0.12, 0.73435),
			cf = CFrame.new(-0.44, 4.739741, 0.07, -0.164399, 0.279895, 0.94585, 0, 0.958897, -0.283755, -0.986394, -0.046649, -0.157642),
			color = Color3.fromRGB(124, 182, 92),
			material = Enum.Material.Plastic,
		},
		{
			name = "BudBody2",
			shape = "Ball",
			size = Vector3.new(0.29, 0.29, 0.29),
			cf = CFrame.new(-0.78, 4.529741, 0.13, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(214, 226, 242),
			material = Enum.Material.Plastic,
		},
		{
			name = "BudTip2",
			shape = "Block",
			size = Vector3.new(0.2494, 0.1276, 0.2494),
			cf = CFrame.new(-0.78, 4.378941, 0.13, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(240, 150, 168),
			material = Enum.Material.Plastic,
		},
		{
			name = "BudBell2",
			shape = "Ball",
			size = Vector3.new(0.1044, 0.1044, 0.1044),
			cf = CFrame.new(-0.78, 4.280341, 0.13, 1, 0, 0, 0, 1, 0, 0, 0, 1),
			color = Color3.fromRGB(226, 186, 96),
			material = Enum.Material.Plastic,
		},
	},
} :: { [string]: { PartSpec } }

return GreenhollowForms
