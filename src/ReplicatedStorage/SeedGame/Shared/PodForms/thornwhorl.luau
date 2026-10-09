--!strict
--==============================================================================
-- POD FORM: Thornwhorl (dustbowl pods/ThornwhorlPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "dustbowl pods/ThornwhorlPod" by a read-only generator on 2026-10-09. The original was
-- not changed (moved, intact, to ServerStorage that day); a verified .rbxm of it is in
-- output/model-backups/2026-10-09-pod-originals.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the model's BASE:
-- the drawn bounding box's bottom centre, its -Z the pod's front -- a lid pod's
-- root looks that way, a studded pod's root the other), colour, material,
-- surface, SpecialMesh, stud texture, light,
-- attribute and joint is the supplied number, at the size it was supplied.
-- WeldConstraints are recorded as Welds (C0 = Part1 in Part0's frame, C1 =
-- identity), which hold the same parts in the same place. Joints point at
-- parts by INDEX, because names repeat.
--
--   g    the owner's folder the part sat in (SizeSeam, GlowAccents)
--   an   a part the owner anchored besides the root: it stood still while the
--        idle moved the root, so PodMotion keeps it still
--   sm   its SpecialMesh: type, scale and offset
--   Textures  one record per part and setting, its faces listed ("Studs_%s"
--        names each texture after its face, as the owner did)
--   Owner     the owner's model attributes, kept apart from the ones the game
--        writes on a pod
--   Removed   the base the pod stood on, left out (the owner, 2026-10-09:
--        "remove the base if there is a base below the pods"): measured from
--        what stays, so the pod's own lowest point is its base
--
-- The pod's own Script is not here: PodMotion (client) plays its idle. The
-- size a tier builds it at is PodForms' (the parent module); see there.
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "dustbowl pods/ThornwhorlPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(4.606509, 3.819568, 4.494232), Height = 3.819568, PartCount = 42,
	Base = 0, Root = 1,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Rare", Style = "BladeWhorl", TextureStyle = "Studded", UnitType = "ThornwhorlPod" },
	Removed = { "FlatBase" },
	Parts = {
		{ n = "TanCore", s = "Block", z = Vector3.new(2.7, 2.85, 2.7), cf = CFrame.new(-0.000601, 1.425, -0.053253, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(206, 184, 138), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 1
		{ n = "ApexCore", s = "Block", z = Vector3.new(1.15, 0.65, 1.15), cf = CFrame.new(-0.000601, 2.875, -0.053253, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(206, 184, 138), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 2
		{ n = "RustBlade1_Root", s = "Block", z = Vector3.new(0.4, 0.4, 0.4), cf = CFrame.new(-0.000601, 0.475, -1.403259, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, t = 1, st = false }, -- 3
		{ n = "RustBlade1_Lower", s = "Block", z = Vector3.new(1.35, 1.65, 0.38), cf = CFrame.new(-0.000601, 1.195, -1.62326, -0.886409, -0.221007, -0.406737, -0.306778, 0.938468, 0.158636, 0.34665, 0.265394, -0.899667), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "RustBlade1_LowerEdge", s = "Wedge", z = Vector3.new(0.32, 1.65, 0.38), cf = CFrame.new(-0.638817, 0.974121, -1.373657, 0.221007, 0.406737, -0.886409, -0.938468, -0.158635, -0.306778, -0.265394, 0.899667, 0.34665), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "RustBlade1_Upper", s = "Block", z = Vector3.new(1.15, 1.65, 0.34), cf = CFrame.new(-0.016346, 2.514831, -1.216705, -0.511018, -0.571997, -0.641623, -0.402503, 0.818787, -0.409364, 0.759508, 0.049063, -0.648645), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "RustBlade1_Tip", s = "Wedge", z = Vector3.new(0.95, 0.65, 0.34), cf = CFrame.new(-0.559744, 3.292679, -1.170105, -0.511018, 0.571997, 0.641623, -0.402503, -0.818787, 0.409364, 0.759508, -0.049063, 0.648646), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "RustBlade1_Hook1", s = "Wedge", z = Vector3.new(0.26, 0.38, 0.28), cf = CFrame.new(-0.698796, 0.699624, -1.394958, -0.546666, -0.764687, -0.341189, -0.795604, 0.601389, -0.073113, 0.261095, 0.231483, -0.937147), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "RustBlade1_Hook2", s = "Wedge", z = Vector3.new(0.24, 0.36, 0.26), cf = CFrame.new(-0.793217, 1.463942, -1.161926, -0.491713, -0.810404, -0.318535, -0.821425, 0.553086, -0.139131, 0.28893, 0.19324, -0.937645), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "RustBlade1_Hook3", s = "Wedge", z = Vector3.new(0.24, 0.34, 0.24), cf = CFrame.new(-0.531957, 2.548173, -0.650635, 0.135941, -0.914682, -0.380629, -0.704488, 0.180881, -0.686279, 0.696575, 0.361441, -0.619793), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "DarkBlade2_Root", s = "Block", z = Vector3.new(0.4, 0.4, 0.4), cf = CFrame.new(-1.284527, 0.475, -0.470428, -0.309017, 0, -0.951057, 0, 1, 0, 0.951057, 0, -0.309017), c = Color3.fromRGB(138, 78, 48), m = Enum.Material.Plastic, t = 1, st = false }, -- 11
		{ n = "DarkBlade2_Lower", s = "Block", z = Vector3.new(1.35, 1.65, 0.38), cf = CFrame.new(-1.493761, 1.195, -0.538422, 0.055768, 0.18411, -0.981322, -0.306778, 0.938468, 0.158636, 0.950146, 0.292201, 0.108817), c = Color3.fromRGB(138, 78, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "DarkBlade2_LowerEdge", s = "Wedge", z = Vector3.new(0.32, 1.65, 0.38), cf = CFrame.new(-1.453609, 0.97412, 0.145691, -0.18411, 0.981322, 0.055768, -0.938468, -0.158635, -0.306778, -0.292201, -0.108817, 0.950146), c = Color3.fromRGB(138, 78, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "DarkBlade2_Upper", s = "Block", z = Vector3.new(1.15, 1.65, 0.34), cf = CFrame.new(-1.111955, 2.514831, -0.397797, 0.564422, -0.130095, -0.815171, -0.402503, 0.818787, -0.409364, 0.720708, 0.559163, 0.409777), c = Color3.fromRGB(138, 78, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "DarkBlade2_Tip", s = "Wedge", z = Vector3.new(0.95, 0.65, 0.34), cf = CFrame.new(-1.235545, 3.292679, 0.133423, 0.564422, 0.130095, 0.815171, -0.402503, -0.818787, 0.409364, 0.720708, -0.559163, -0.409777), c = Color3.fromRGB(138, 78, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "DarkBlade2_Hook1", s = "Wedge", z = Vector3.new(0.26, 0.38, 0.28), cf = CFrame.new(-1.492385, 0.699621, 0.196167, 0.079387, -0.016148, -0.996713, -0.795604, 0.601389, -0.073113, 0.600593, 0.798793, 0.034895), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "DarkBlade2_Hook2", s = "Wedge", z = Vector3.new(0.24, 0.36, 0.26), cf = CFrame.new(-1.299936, 1.463939, 0.357971, 0.122841, -0.066647, -0.990186, -0.821425, 0.553086, -0.139131, 0.556931, 0.830454, 0.013196), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "DarkBlade2_Hook3", s = "Wedge", z = Vector3.new(0.24, 0.34, 0.24), cf = CFrame.new(-0.732921, 2.548174, 0.267517, 0.70449, 0.061099, -0.707079, -0.704488, 0.180881, -0.686279, 0.085966, 0.981605, 0.170473), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "RustBlade3_Root", s = "Block", z = Vector3.new(0.4, 0.4, 0.4), cf = CFrame.new(-0.794111, 0.475, 1.03891, 0.809017, 0, -0.587785, 0, 1, 0, 0.587785, 0, 0.809017), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, t = 1, st = false }, -- 19
		{ n = "RustBlade3_Lower", s = "Block", z = Vector3.new(1.35, 1.65, 0.38), cf = CFrame.new(-0.923421, 1.195, 1.216888, 0.920876, 0.334793, -0.199754, -0.306778, 0.938468, 0.158636, 0.240573, -0.084804, 0.96692), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "RustBlade3_LowerEdge", s = "Wedge", z = Vector3.new(0.32, 1.65, 0.38), cf = CFrame.new(-0.260393, 0.97412, 1.390106, -0.334793, 0.199754, 0.920876, -0.938468, -0.158635, -0.306778, 0.084804, -0.96692, 0.240573), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "RustBlade3_Upper", s = "Block", z = Vector3.new(1.15, 1.65, 0.34), cf = CFrame.new(-0.671709, 2.514831, 0.897217, 0.85985, 0.491594, 0.13782, -0.402503, 0.818787, -0.409364, -0.314086, 0.296519, 0.901902), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "RustBlade3_Tip", s = "Wedge", z = Vector3.new(0.95, 0.65, 0.34), cf = CFrame.new(-0.204697, 3.292682, 1.178925, 0.85985, -0.491594, -0.13782, -0.402504, -0.818787, 0.409364, -0.314086, -0.296519, -0.901902), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "RustBlade3_Hook1", s = "Wedge", z = Vector3.new(0.26, 0.38, 0.28), cf = CFrame.new(-0.224377, 0.699622, 1.442566, 0.59573, 0.754707, -0.274814, -0.795604, 0.601389, -0.073113, 0.110092, 0.262198, 0.958714), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "RustBlade3_Hook2", s = "Wedge", z = Vector3.new(0.24, 0.36, 0.26), cf = CFrame.new(-0.011018, 1.46394, 1.30954, 0.567632, 0.769214, -0.293434, -0.821425, 0.553086, -0.139131, 0.055272, 0.320009, 0.945801), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "RustBlade3_Hook3", s = "Wedge", z = Vector3.new(0.24, 0.34, 0.24), cf = CFrame.new(0.078156, 2.548172, 0.74234, 0.299458, 0.952443, -0.05637, -0.704488, 0.180881, -0.686279, -0.643445, 0.245224, 0.725151), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "DarkBlade4_Root", s = "Block", z = Vector3.new(0.4, 0.4, 0.4), cf = CFrame.new(0.79291, 0.475, 1.03891, 0.809017, 0, 0.587785, 0, 1, 0, -0.587785, 0, 0.809017), c = Color3.fromRGB(138, 78, 48), m = Enum.Material.Plastic, t = 1, st = false }, -- 27
		{ n = "DarkBlade4_Lower", s = "Block", z = Vector3.new(1.35, 1.65, 0.38), cf = CFrame.new(0.922222, 1.195, 1.216888, 0.513364, 0.022804, 0.857868, -0.306778, 0.938468, 0.158636, -0.801464, -0.344613, 0.488772), c = Color3.fromRGB(138, 78, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "DarkBlade4_LowerEdge", s = "Wedge", z = Vector3.new(0.32, 1.65, 0.38), cf = CFrame.new(1.291847, 0.97412, 0.639832, -0.022804, -0.857868, 0.513365, -0.938468, -0.158636, -0.306778, 0.344613, -0.488772, -0.801464), c = Color3.fromRGB(138, 78, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "DarkBlade4_Upper", s = "Block", z = Vector3.new(1.15, 1.65, 0.34), cf = CFrame.new(0.695986, 2.514831, 0.878723, -0.033006, 0.433917, 0.900348, -0.402503, 0.818787, -0.409364, -0.914823, -0.375904, 0.147629), c = Color3.fromRGB(138, 78, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "DarkBlade4_Tip", s = "Wedge", z = Vector3.new(0.95, 0.65, 0.34), cf = CFrame.new(1.108208, 3.292678, 0.521606, -0.033005, -0.433917, -0.900348, -0.402503, -0.818787, 0.409364, -0.914823, 0.375905, -0.147629), c = Color3.fromRGB(138, 78, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "DarkBlade4_Hook1", s = "Wedge", z = Vector3.new(0.26, 0.38, 0.28), cf = CFrame.new(1.352882, 0.699621, 0.621796, 0.288794, 0.482583, 0.826869, -0.795604, 0.60139, -0.073113, -0.532553, -0.636746, 0.557623), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "DarkBlade4_Hook2", s = "Wedge", z = Vector3.new(0.24, 0.36, 0.26), cf = CFrame.new(1.292295, 1.463939, 0.377777, 0.227975, 0.542047, 0.808834, -0.821425, 0.553086, -0.139131, -0.52277, -0.632678, 0.571341), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
		{ n = "DarkBlade4_Hook3", s = "Wedge", z = Vector3.new(0.24, 0.34, 0.24), cf = CFrame.new(0.780396, 2.548174, 0.117706, -0.519415, 0.527543, 0.67224, -0.704488, 0.180881, -0.686279, -0.483637, -0.830049, 0.277695), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 34
		{ n = "RustBlade5_Root", s = "Block", z = Vector3.new(0.4, 0.4, 0.4), cf = CFrame.new(1.283325, 0.475, -0.470428, -0.309017, 0, 0.951056, 0, 1, 0, -0.951056, 0, -0.309017), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, t = 1, st = false }, -- 35
		{ n = "RustBlade5_Lower", s = "Block", z = Vector3.new(1.35, 1.65, 0.38), cf = CFrame.new(1.492559, 1.195, -0.538422, -0.603599, -0.320699, 0.729945, -0.306778, 0.938468, 0.158636, -0.735905, -0.128179, -0.664842), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 36
		{ n = "RustBlade5_LowerEdge", s = "Wedge", z = Vector3.new(0.32, 1.65, 0.38), cf = CFrame.new(1.057965, 0.97412, -1.068268, 0.320699, -0.729945, -0.603599, -0.938468, -0.158635, -0.306778, 0.128179, 0.664842, -0.735905), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 37
		{ n = "RustBlade5_Upper", s = "Block", z = Vector3.new(1.15, 1.65, 0.34), cf = CFrame.new(1.101024, 2.514831, -0.427765, -0.880248, -0.223419, 0.418626, -0.402503, 0.818787, -0.409364, -0.251306, -0.52884, -0.810662), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 38
		{ n = "RustBlade5_Tip", s = "Wedge", z = Vector3.new(0.95, 0.65, 0.34), cf = CFrame.new(0.888776, 3.29268, -0.930145, -0.880248, 0.223418, -0.418626, -0.402504, -0.818787, 0.409365, -0.251306, 0.52884, 0.810662), c = Color3.fromRGB(172, 104, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 39
		{ n = "RustBlade5_Hook1", s = "Wedge", z = Vector3.new(0.26, 0.38, 0.28), cf = CFrame.new(1.059676, 0.699622, -1.131897, -0.417246, -0.456455, 0.785847, -0.795604, 0.601389, -0.073113, -0.439227, -0.655729, -0.614084), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 40
		{ n = "RustBlade5_Hook2", s = "Wedge", z = Vector3.new(0.24, 0.36, 0.26), cf = CFrame.new(0.80887, 1.463939, -1.149689, -0.426736, -0.434211, 0.793321, -0.821425, 0.553086, -0.139131, -0.378362, -0.711026, -0.592693), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 41
		{ n = "RustBlade5_Hook3", s = "Wedge", z = Vector3.new(0.24, 0.34, 0.24), cf = CFrame.new(0.403326, 2.54817, -0.743225, -0.620474, -0.626403, 0.471837, -0.704488, 0.180881, -0.686279, 0.344541, -0.758222, -0.553526), c = Color3.fromRGB(230, 194, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 42
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 1.450001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "BladeJoint1", h = 1, a = 1, b = 3, c0 = CFrame.new(0, -0.95, 1.35, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "BladeJoint2", h = 1, a = 1, b = 11, c0 = CFrame.new(1.283926, -0.95, 0.417173, 0.309017, 0, 0.951057, 0, 1, 0, -0.951057, 0, 0.309017), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "BladeJoint3", h = 1, a = 1, b = 19, c0 = CFrame.new(0.79351, -0.95, -1.092173, -0.809017, 0, 0.587785, 0, 1, 0, -0.587785, 0, -0.809017), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "BladeJoint4", h = 1, a = 1, b = 27, c0 = CFrame.new(-0.79351, -0.95, -1.092173, -0.809017, 0, -0.587785, 0, 1, 0, 0.587785, 0, -0.809017), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "BladeJoint5", h = 1, a = 1, b = 35, c0 = CFrame.new(-1.283926, -0.95, 0.417173, 0.309017, 0, -0.951056, 0, 1, 0, 0.951056, 0, 0.309017), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 4, c0 = CFrame.new(0, 0.72, 0.220001, 0.886409, 0.221007, 0.406737, -0.306778, 0.938468, 0.158636, -0.34665, -0.265394, 0.899667), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 6, c0 = CFrame.new(0.015745, 2.039831, -0.186554, 0.511018, 0.571997, 0.641623, -0.402503, 0.818787, -0.409364, -0.759508, -0.049063, 0.648645), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(0.720009, 0.000008, 0, 0, 0, 1, -1, 0, 0, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 8, c0 = CFrame.new(0.849998, -0.249992, 0, 0.819152, 0.573577, 0, -0.556539, 0.79482, -0.241922, -0.138761, 0.198171, 0.970296), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 9, c0 = CFrame.new(0.779999, 0.550003, -0.049988, 0.788011, 0.615662, 0, -0.585529, 0.749443, -0.309017, -0.19025, 0.243509, 0.951057), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 7, c0 = CFrame.new(0, 0.950002, 0, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 10, c0 = CFrame.new(0.680008, 0.35, -0.050003, 0.743145, 0.669131, 0, -0.620408, 0.689032, -0.374607, -0.25066, 0.278387, 0.927184), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 12, c0 = CFrame.new(-0.000031, 0.72, 0.220009, 0.886409, 0.221007, 0.406737, -0.306778, 0.938468, 0.158636, -0.34665, -0.265394, 0.899667), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 14, c0 = CFrame.new(0.015717, 2.039831, -0.186569, 0.511018, 0.571997, 0.641623, -0.402503, 0.818787, -0.409364, -0.759508, -0.049063, 0.648645), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 13, c0 = CFrame.new(0.720032, 0, 0.000004, 0, 0, 1, -1, 0, 0, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 16, c0 = CFrame.new(0.850006, -0.25, 0.000002, 0.819152, 0.573577, 0, -0.556539, 0.79482, -0.241922, -0.138761, 0.198171, 0.970296), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 17, c0 = CFrame.new(0.779999, 0.550003, -0.049995, 0.788011, 0.615662, 0, -0.585529, 0.749443, -0.309017, -0.19025, 0.243509, 0.951057), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 15, c0 = CFrame.new(0.000015, 0.949997, 0.000008, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 18, c0 = CFrame.new(0.680008, 0.349991, -0.049995, 0.743145, 0.669131, 0, -0.620408, 0.689032, -0.374607, -0.250661, 0.278387, 0.927184), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 20, c0 = CFrame.new(0, 0.72, 0.220001, 0.886409, 0.221007, 0.406737, -0.306778, 0.938468, 0.158636, -0.34665, -0.265394, 0.899667), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 22, c0 = CFrame.new(0.015747, 2.039831, -0.1866, 0.511018, 0.571997, 0.641623, -0.402503, 0.818787, -0.409364, -0.759508, -0.049063, 0.648645), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 21, c0 = CFrame.new(0.720001, -0.000004, 0, 0, 0, 1, -1, 0, 0, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 24, c0 = CFrame.new(0.849998, -0.25, 0, 0.819152, 0.573577, 0, -0.556539, 0.79482, -0.241922, -0.138761, 0.198171, 0.970296), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 25, c0 = CFrame.new(0.779991, 0.549999, -0.049988, 0.788011, 0.615662, 0, -0.585529, 0.749443, -0.309017, -0.19025, 0.243509, 0.951057), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 23, c0 = CFrame.new(0, 0.950005, 0, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 26, c0 = CFrame.new(0.68, 0.350006, -0.049988, 0.743145, 0.669131, 0, -0.620408, 0.689032, -0.374607, -0.25066, 0.278387, 0.927184), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 28, c0 = CFrame.new(0, 0.72, 0.220001, 0.886409, 0.221007, 0.406737, -0.306778, 0.938468, 0.158636, -0.34665, -0.265394, 0.899667), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 30, c0 = CFrame.new(0.015747, 2.039831, -0.186554, 0.511018, 0.571997, 0.641623, -0.402503, 0.818787, -0.409364, -0.759508, -0.049063, 0.648645), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 29, c0 = CFrame.new(0.720001, 0, -0.000015, 0, 0, 1, -1, 0, 0, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 32, c0 = CFrame.new(0.850021, -0.25, 0, 0.819152, 0.573577, 0, -0.556539, 0.79482, -0.241922, -0.138761, 0.198171, 0.970296), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 33, c0 = CFrame.new(0.779999, 0.550003, -0.050003, 0.788011, 0.615662, 0, -0.585529, 0.749443, -0.309017, -0.19025, 0.243509, 0.951057), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 30, a = 30, b = 31, c0 = CFrame.new(0, 0.950005, -0.000004, 1, 0, 0, 0, -1.000001, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 30, a = 30, b = 34, c0 = CFrame.new(0.679993, 0.349998, -0.050003, 0.743145, 0.669131, 0, -0.620408, 0.689032, -0.374607, -0.250661, 0.278387, 0.927184), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 35, a = 35, b = 36, c0 = CFrame.new(0, 0.72, 0.220001, 0.886409, 0.221007, 0.406737, -0.306778, 0.938468, 0.158636, -0.34665, -0.265394, 0.899667), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 35, a = 35, b = 38, c0 = CFrame.new(0.015747, 2.039831, -0.186562, 0.511018, 0.571997, 0.641623, -0.402503, 0.818787, -0.409364, -0.759508, -0.049063, 0.648645), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 37, c0 = CFrame.new(0.720001, 0, 0, 0, 0, 1, -1, 0, 0, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 40, c0 = CFrame.new(0.850006, -0.25, 0.000015, 0.819152, 0.573577, 0, -0.556539, 0.79482, -0.241922, -0.138761, 0.198171, 0.970296), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 41, c0 = CFrame.new(0.780014, 0.549999, -0.049988, 0.788011, 0.615662, 0, -0.585529, 0.749443, -0.309017, -0.19025, 0.243509, 0.951057), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 38, a = 38, b = 39, c0 = CFrame.new(-0.000008, 0.949982, -0.000015, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 38, a = 38, b = 42, c0 = CFrame.new(0.68, 0.350006, -0.049973, 0.743145, 0.669131, 0, -0.620408, 0.689032, -0.374607, -0.25066, 0.278387, 0.927184), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StudioFillLight", p = 1, range = 12, brightness = 0.85, color = Color3.new(1, 0.972549, 0.921569), shadows = true, enabled = true },
	},
	Emitters = {},
	Textures = {
		{ n = "Studs_%s", p = 1, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 2, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 4, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 5, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 6, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 7, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 8, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 9, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 10, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 12, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 13, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 14, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 15, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 16, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 17, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 18, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 20, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 21, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 22, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 23, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 24, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 25, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 26, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 28, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 29, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 30, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 31, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 32, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 33, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 34, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 36, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 37, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 38, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 39, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 40, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 41, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 42, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.159497, v = 4.159497, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
