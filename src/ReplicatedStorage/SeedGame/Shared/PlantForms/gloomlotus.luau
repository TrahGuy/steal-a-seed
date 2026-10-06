--!strict
--==============================================================================
-- PLANT FORM: Gloomlotus (Tanglemire)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Tanglemire/Gloomlotus" by a read-only generator on 2026-10-03. The original
-- was not moved or changed; a verified .rbxm of it is in
-- output/model-backups/2026-10-03-plant-originals.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the model's BASE:
-- its root part's x/z at the lowest drawn point, facing the way the root
-- faces), colour, material, surface, attribute and joint is the supplied
-- number, at the size it was supplied. WeldConstraints are recorded as Welds
-- (C0 = Part1 in Part0's frame, C1 = identity), which hold the same parts in
-- the same place. The size a tier builds it at is PlantForms' (the parent
-- module); see there. Joints point at parts by INDEX, because names repeat.
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "Tanglemire/Gloomlotus", Kind = "plant", Yaw = 0,
	Size = Vector3.new(5.791634, 9.672864, 6.24892), Height = 9.672864, PartCount = 96,
	Base = 3,
	Unit = 4.5, ModelScale = 1,
	Attributes = {},
	Parts = {
		{ n = "StemBody", s = "Block", z = Vector3.new(1.35, 2.25, 1.35), cf = CFrame.new(0, 3.87, 0.157501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(43, 32, 60), m = Enum.Material.Plastic }, -- 1
		{ n = "DrapeVein2", s = "Block", z = Vector3.new(0.054, 0.081, 1.321124), cf = CFrame.new(0.998908, 2.65664, 0.85305, -0.494261, 0.753441, -0.433628, 0.151074, 0.565672, 0.810674, 0.856085, 0.335175, -0.393415), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 2
		{ n = "Footing", s = "Block", z = Vector3.new(0.54, 0.54, 0.54), cf = CFrame.new(0, 0.000001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 19, 34), m = Enum.Material.Plastic, t = 1 }, -- 3
		{ n = "DrapeRoot2", s = "Block", z = Vector3.new(0.3825, 0.3825, 2.067319), cf = CFrame.new(0.876851, 2.565001, 0.798752, -0.494261, 0.753441, -0.433628, 0.151074, 0.565672, 0.810673, 0.856086, 0.335175, -0.393415), c = Color3.fromRGB(24, 19, 34), m = Enum.Material.Plastic }, -- 4
		{ n = "RootUpper4", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(1.205286, 2.483861, 0.974041, -0.4819, 0.538743, -0.691035, 0.008842, 0.791598, 0.610978, 0.876182, 0.28832, -0.386235), c = Color3.fromRGB(43, 32, 60), m = Enum.Material.Plastic }, -- 5
		{ n = "RootFoot4", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(1.035, 0.2925, 0.899998, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(43, 32, 60), m = Enum.Material.Plastic }, -- 6
		{ n = "RootLower4", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(1.407786, 1.257612, 1.09779, -0.4819, 0.753164, 0.447792, 0.008842, -0.50684, 0.861995, 0.876182, 0.419355, 0.237586), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 7
		{ n = "RootToe4", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(1.035, 0.5625, 0.742496, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 8
		{ n = "BlossomHub", s = "Block", z = Vector3.new(1.62, 1.71, 1.26), cf = CFrame.new(0, 6.66, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 19, 34), m = Enum.Material.Plastic }, -- 9
		{ n = "FaceCore", s = "Block", z = Vector3.new(1.26, 1.44, 0.225), cf = CFrame.new(0, 6.615, -0.661499, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(231, 225, 240), m = Enum.Material.Plastic }, -- 10
		{ n = "UpperStem", s = "Block", z = Vector3.new(1.08, 1.44, 1.08), cf = CFrame.new(0, 5.5575, 0.067501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 19, 34), m = Enum.Material.Plastic }, -- 11
		{ n = "Mouth", s = "Block", z = Vector3.new(0.072, 0.126, 0.054), cf = CFrame.new(0, 6.1425, -0.787498, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 12
		{ n = "HoodPetal1", s = "Block", z = Vector3.new(0.81, 2.52, 0.495), cf = CFrame.new(-0.880717, 7.620742, 0.235989, 0.258819, -0.298488, -0.91865, 0, 0.951057, -0.309017, 0.965926, 0.07998, 0.246152), c = Color3.fromRGB(160, 119, 209), m = Enum.Material.Plastic }, -- 13
		{ n = "HoodTip1", s = "Wedge", z = Vector3.new(0.765, 0.99, 0.54), cf = CFrame.new(-1.350835, 9.118657, 0.361958, 0.258819, -0.298488, -0.91865, 0, 0.951057, -0.309017, 0.965926, 0.07998, 0.246152), c = Color3.fromRGB(190, 153, 228), m = Enum.Material.Plastic }, -- 14
		{ n = "OuterPetal7", s = "Block", z = Vector3.new(1.215, 2.16, 0.45), cf = CFrame.new(-1.274441, 5.416009, 0.157501, 0, -0.766044, -0.642788, 0, 0.642788, -0.766044, 1, 0, 0), c = Color3.fromRGB(68, 40, 109), m = Enum.Material.Plastic }, -- 15
		{ n = "OuterTip7", s = "Wedge", z = Vector3.new(1.17, 1.08, 0.54), cf = CFrame.new(-2.3086, 6.283773, 0.157501, 0, -0.766044, -0.642788, 0, 0.642788, -0.766044, 1, 0, 0), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 16
		{ n = "HoodPetal3", s = "Block", z = Vector3.new(0.81, 2.52, 0.495), cf = CFrame.new(-0.385337, 7.620742, 0.826359, 0.906308, -0.130596, -0.401934, 0, 0.951056, -0.309017, 0.422618, 0.280064, 0.86195), c = Color3.fromRGB(160, 119, 209), m = Enum.Material.Plastic }, -- 17
		{ n = "HoodVein3", s = "Block", z = Vector3.new(0.0495, 1.89, 0.072), cf = CFrame.new(-0.291285, 7.693053, 0.624664, 0.906308, -0.130596, -0.401934, 0, 0.951056, -0.309017, 0.422618, 0.280064, 0.86195), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 18
		{ n = "HemTip4", s = "Wedge", z = Vector3.new(0.3825, 0.36, 0.585), cf = CFrame.new(0, 0.990001, -1.327496, 1, 0, 0, 0, 0.316227, 0.948683, 0, -0.948683, 0.316227), c = Color3.fromRGB(68, 40, 109), m = Enum.Material.Plastic }, -- 19
		{ n = "DrapeRoot4", s = "Block", z = Vector3.new(0.3825, 0.3825, 1.852281), cf = CFrame.new(0, 2.565001, -0.719997, 1, 0, 0, 0, 0.40364, 0.914918, 0, -0.914918, 0.40364), c = Color3.fromRGB(24, 19, 34), m = Enum.Material.Plastic }, -- 20
		{ n = "HemRoot4", s = "Block", z = Vector3.new(0.2925, 0.2925, 1.011315), cf = CFrame.new(0, 1.395001, -1.192497, 1, 0, 0, 0, 0.316227, 0.948683, 0, -0.948683, 0.316227), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 21
		{ n = "OuterTip8", s = "Wedge", z = Vector3.new(1.17, 1.08, 0.54), cf = CFrame.new(-1.632426, 6.283773, 1.789928, 0.707107, -0.541675, -0.45452, 0, 0.642788, -0.766044, 0.707107, 0.541675, 0.454519), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 22
		{ n = "OuterPetal8", s = "Block", z = Vector3.new(1.215, 2.16, 0.45), cf = CFrame.new(-0.901165, 5.416009, 1.058666, 0.707107, -0.541675, -0.45452, 0, 0.642788, -0.766044, 0.707107, 0.541675, 0.454519), c = Color3.fromRGB(87, 48, 134), m = Enum.Material.Plastic }, -- 23
		{ n = "HoodPetal2", s = "Block", z = Vector3.new(0.81, 2.52, 0.495), cf = CFrame.new(0.880717, 7.620742, 0.235989, 0.258819, 0.298488, 0.91865, 0, 0.951057, -0.309017, -0.965926, 0.07998, 0.246152), c = Color3.fromRGB(160, 119, 209), m = Enum.Material.Plastic }, -- 24
		{ n = "HoodTip2", s = "Wedge", z = Vector3.new(0.765, 0.99, 0.54), cf = CFrame.new(1.350835, 9.118657, 0.361958, 0.258819, 0.298488, 0.91865, 0, 0.951057, -0.309017, -0.965926, 0.07998, 0.246152), c = Color3.fromRGB(190, 153, 228), m = Enum.Material.Plastic }, -- 25
		{ n = "HemRoot2", s = "Block", z = Vector3.new(0.2925, 0.2925, 1.2375), cf = CFrame.new(1.519875, 1.395001, 1.440002, -0.480384, 0.762713, -0.433013, 0.27735, 0.60048, 0.75, 0.83205, 0.240192, -0.5), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 26
		{ n = "MiddlePetal1", s = "Block", z = Vector3.new(0.99, 1.71, 0.495), cf = CFrame.new(0.403077, 6.728863, 0.698151, 0.866025, 0.203368, 0.456773, 0, 0.913545, -0.406737, -0.5, 0.352244, 0.791154), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 27
		{ n = "HemTip2", s = "Wedge", z = Vector3.new(0.3825, 0.36, 0.585), cf = CFrame.new(1.753701, 0.990001, 1.710003, -0.480385, 0.762713, -0.433013, 0.27735, 0.60048, 0.75, 0.83205, 0.240192, -0.5), c = Color3.fromRGB(68, 40, 109), m = Enum.Material.Plastic }, -- 28
		{ n = "OuterTip5", s = "Wedge", z = Vector3.new(1.17, 1.08, 0.54), cf = CFrame.new(0, 5.419844, -2.600834, -1, 0, 0, 0, 0.258819, -0.965926, 0, -0.965926, -0.258819), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 29
		{ n = "OuterPetal5", s = "Block", z = Vector3.new(1.215, 2.16, 0.45), cf = CFrame.new(0, 5.070438, -1.296833, -1, 0, 0, 0, 0.258819, -0.965926, 0, -0.965926, -0.258819), c = Color3.fromRGB(68, 40, 109), m = Enum.Material.Plastic }, -- 30
		{ n = "RootUpper1", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(-1.194009, 2.510019, -0.714542, 0.478407, -0.558692, 0.677488, 0.1205, 0.805973, 0.579557, -0.869831, -0.195627, 0.452906), c = Color3.fromRGB(43, 32, 60), m = Enum.Material.Plastic }, -- 31
		{ n = "RootLower1", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(-1.396509, 1.283769, -0.995792, 0.478407, -0.763255, -0.434245, 0.120499, -0.432769, 0.893416, -0.869831, -0.479743, -0.115068), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 32
		{ n = "RootUpper3", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(-1.205286, 2.483861, 0.974041, -0.4819, -0.538743, 0.691035, -0.008842, 0.791598, 0.610978, -0.876182, 0.28832, -0.386235), c = Color3.fromRGB(43, 32, 60), m = Enum.Material.Plastic }, -- 33
		{ n = "RootLower3", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(-1.407786, 1.257612, 1.09779, -0.4819, -0.753164, -0.447792, -0.008842, -0.50684, 0.861995, -0.876182, 0.419355, 0.237586), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 34
		{ n = "MiddlePetal4", s = "Block", z = Vector3.new(0.99, 1.71, 0.495), cf = CFrame.new(-0.626278, 5.563533, -1.084743, -0.866025, -0.495134, 0.069587, 0, -0.139173, -0.990268, 0.5, -0.857597, 0.120527), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 35
		{ n = "RootUpper2", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(1.194009, 2.510019, -0.714542, 0.478407, 0.558692, -0.677488, -0.1205, 0.805973, 0.579557, 0.869831, -0.195627, 0.452906), c = Color3.fromRGB(43, 32, 60), m = Enum.Material.Plastic }, -- 36
		{ n = "RootFoot2", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(1.035001, 0.2925, -0.899998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(43, 32, 60), m = Enum.Material.Plastic }, -- 37
		{ n = "RootLower2", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(1.396509, 1.283769, -0.995792, 0.478407, 0.763255, 0.434245, -0.120499, -0.432769, 0.893416, 0.869831, -0.479743, -0.115068), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 38
		{ n = "RootToe2", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(1.035001, 0.5625, -1.057499, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 39
		{ n = "DrapeRoot3", s = "Block", z = Vector3.new(0.3825, 0.3825, 1.926904), cf = CFrame.new(0.87685, 2.565001, -0.213749, 0.494261, 0.732277, -0.468482, 0.151074, 0.458355, 0.875835, 0.856086, -0.503667, 0.115919), c = Color3.fromRGB(24, 19, 34), m = Enum.Material.Plastic }, -- 40
		{ n = "OuterPetal6", s = "Block", z = Vector3.new(1.215, 2.16, 0.45), cf = CFrame.new(-1.028368, 5.070438, -0.870869, -0.707107, -0.683013, -0.183013, 0, 0.258819, -0.965926, 0.707107, -0.683013, -0.183013), c = Color3.fromRGB(87, 48, 134), m = Enum.Material.Plastic }, -- 41
		{ n = "HemRoot3", s = "Block", z = Vector3.new(0.2925, 0.2925, 1.092807), cf = CFrame.new(1.519874, 1.395001, -0.314999, 0.480385, 0.720577, -0.5, 0.27735, 0.416025, 0.866025, 0.83205, -0.5547, 0), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 42
		{ n = "HemTip3", s = "Wedge", z = Vector3.new(0.3825, 0.36, 0.585), cf = CFrame.new(1.7537, 0.990001, -0.314999, 0.480385, 0.720577, -0.5, 0.27735, 0.416025, 0.866025, 0.832051, -0.5547, 0), c = Color3.fromRGB(68, 40, 109), m = Enum.Material.Plastic }, -- 43
		{ n = "ForeheadMark", s = "Block", z = Vector3.new(0.099, 0.216, 0.0675), cf = CFrame.new(0, 7.1505, -0.7785, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 44
		{ n = "BrowL", s = "Block", z = Vector3.new(0.387, 0.0675, 0.081), cf = CFrame.new(-0.306, 6.988501, -0.760498, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 45
		{ n = "DrapeRoot1", s = "Block", z = Vector3.new(0.3825, 0.3825, 2.133746), cf = CFrame.new(0, 2.565001, 1.305, -1, 0, 0, 0, 0.621882, 0.783111, 0, 0.783111, -0.621882), c = Color3.fromRGB(24, 19, 34), m = Enum.Material.Plastic }, -- 46
		{ n = "DrapeRoot5", s = "Block", z = Vector3.new(0.3825, 0.3825, 1.926904), cf = CFrame.new(-0.87685, 2.565001, -0.213749, 0.494261, -0.732277, 0.468482, -0.151074, 0.458355, 0.875835, -0.856086, -0.503667, 0.115919), c = Color3.fromRGB(24, 19, 34), m = Enum.Material.Plastic }, -- 47
		{ n = "HemRoot5", s = "Block", z = Vector3.new(0.2925, 0.2925, 1.092807), cf = CFrame.new(-1.519874, 1.395001, -0.314999, 0.480385, -0.720577, 0.5, -0.27735, 0.416025, 0.866025, -0.83205, -0.5547, 0), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 48
		{ n = "RootFoot1", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(-1.035001, 0.2925, -0.899998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(43, 32, 60), m = Enum.Material.Plastic }, -- 49
		{ n = "OuterPetal4", s = "Block", z = Vector3.new(1.215, 2.16, 0.45), cf = CFrame.new(1.028369, 5.070438, -0.870869, -0.707107, 0.683013, 0.183013, 0, 0.258819, -0.965926, -0.707107, -0.683013, -0.183013), c = Color3.fromRGB(87, 48, 134), m = Enum.Material.Plastic }, -- 50
		{ n = "MiddlePetal3", s = "Block", z = Vector3.new(0.99, 1.71, 0.495), cf = CFrame.new(0.626278, 5.563533, -1.084743, -0.866025, 0.495134, -0.069587, 0, -0.139173, -0.990268, -0.5, -0.857597, 0.120527), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 51
		{ n = "MiddlePetal5", s = "Block", z = Vector3.new(0.99, 1.71, 0.495), cf = CFrame.new(-0.806153, 6.728863, 0, 0, -0.406737, -0.913545, 0, 0.913545, -0.406737, 1, 0, 0), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 52
		{ n = "DrapeVein3", s = "Block", z = Vector3.new(0.054, 0.081, 1.222833), cf = CFrame.new(0.995479, 2.639255, -0.295341, 0.494261, 0.732277, -0.468482, 0.151074, 0.458355, 0.875835, 0.856086, -0.503667, 0.115919), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 53
		{ n = "DrapeVein1", s = "Block", z = Vector3.new(0.054, 0.081, 1.367622), cf = CFrame.new(0, 2.665745, 1.431866, -1, 0, 0, 0, 0.621882, 0.783111, 0, 0.783111, -0.621882), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 54
		{ n = "DrapeVein6", s = "Block", z = Vector3.new(0.054, 0.081, 1.321124), cf = CFrame.new(-0.998908, 2.65664, 0.85305, -0.494261, -0.753441, 0.433628, -0.151074, 0.565672, 0.810674, -0.856085, 0.335175, -0.393415), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 55
		{ n = "DrapeRoot6", s = "Block", z = Vector3.new(0.3825, 0.3825, 2.067319), cf = CFrame.new(-0.876851, 2.565001, 0.798752, -0.494261, -0.753441, 0.433628, -0.151074, 0.565672, 0.810673, -0.856086, 0.335175, -0.393415), c = Color3.fromRGB(24, 19, 34), m = Enum.Material.Plastic }, -- 56
		{ n = "HoodVein1", s = "Block", z = Vector3.new(0.0495, 1.89, 0.072), cf = CFrame.new(-0.665753, 7.693053, 0.178391, 0.258819, -0.298488, -0.91865, 0, 0.951057, -0.309017, 0.965926, 0.07998, 0.246152), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 57
		{ n = "OuterTip1", s = "Wedge", z = Vector3.new(1.17, 1.08, 0.54), cf = CFrame.new(0, 6.283773, 2.466103, 1, 0, 0, 0, 0.642788, -0.766044, 0, 0.766044, 0.642788), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 58
		{ n = "OuterPetal1", s = "Block", z = Vector3.new(1.215, 2.16, 0.45), cf = CFrame.new(0, 5.416009, 1.431942, 1, 0, 0, 0, 0.642788, -0.766044, 0, 0.766044, 0.642788), c = Color3.fromRGB(68, 40, 109), m = Enum.Material.Plastic }, -- 59
		{ n = "DrapeVein5", s = "Block", z = Vector3.new(0.054, 0.081, 1.222833), cf = CFrame.new(-0.995479, 2.639255, -0.295341, 0.494261, -0.732277, 0.468482, -0.151074, 0.458355, 0.875835, -0.856086, -0.503667, 0.115919), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 60
		{ n = "MiddleTip6", s = "Wedge", z = Vector3.new(0.945, 0.945, 0.54), cf = CFrame.new(-0.641018, 7.797711, 1.110275, 0.866025, -0.203368, -0.456773, 0, 0.913545, -0.406737, 0.5, 0.352244, 0.791153), c = Color3.fromRGB(160, 119, 209), m = Enum.Material.Plastic }, -- 61
		{ n = "MiddlePetal6", s = "Block", z = Vector3.new(0.99, 1.71, 0.495), cf = CFrame.new(-0.403077, 6.728863, 0.698151, 0.866025, -0.203368, -0.456773, 0, 0.913545, -0.406737, 0.5, 0.352244, 0.791153), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 62
		{ n = "MiddlePetal2", s = "Block", z = Vector3.new(0.99, 1.71, 0.495), cf = CFrame.new(0.806153, 6.728863, 0, 0, 0.406737, 0.913545, 0, 0.913545, -0.406737, -1, 0, 0), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 63
		{ n = "RootFoot3", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(-1.035, 0.2925, 0.899998, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(43, 32, 60), m = Enum.Material.Plastic }, -- 64
		{ n = "RootToe3", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(-1.035, 0.5625, 0.742496, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 65
		{ n = "BarkRidge3", s = "Block", z = Vector3.new(0.162, 1.575, 0.1575), cf = CFrame.new(0.45, 3.825001, 0.796501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 66
		{ n = "MaskCheekR", s = "Wedge", z = Vector3.new(0.18, 0.765, 0.2925), cf = CFrame.new(0.576, 6.520501, -0.616501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(231, 225, 240), m = Enum.Material.Plastic }, -- 67
		{ n = "HoodTip3", s = "Wedge", z = Vector3.new(0.765, 0.99, 0.54), cf = CFrame.new(-0.591026, 9.118657, 1.26746, 0.906308, -0.130596, -0.401934, 0, 0.951056, -0.309017, 0.422618, 0.280064, 0.86195), c = Color3.fromRGB(190, 153, 228), m = Enum.Material.Plastic }, -- 68
		{ n = "MiddleTip4", s = "Wedge", z = Vector3.new(0.945, 0.945, 0.54), cf = CFrame.new(-1.205585, 5.400701, -2.088131, -0.866025, -0.495134, 0.069587, 0, -0.139173, -0.990268, 0.5, -0.857597, 0.120527), c = Color3.fromRGB(160, 119, 209), m = Enum.Material.Plastic }, -- 69
		{ n = "HemTip6", s = "Wedge", z = Vector3.new(0.3825, 0.36, 0.585), cf = CFrame.new(-1.753701, 0.990001, 1.710003, -0.480385, -0.762713, 0.433013, -0.27735, 0.60048, 0.75, -0.83205, 0.240192, -0.5), c = Color3.fromRGB(68, 40, 109), m = Enum.Material.Plastic }, -- 70
		{ n = "HemRoot6", s = "Block", z = Vector3.new(0.2925, 0.2925, 1.2375), cf = CFrame.new(-1.519875, 1.395001, 1.440002, -0.480384, -0.762713, 0.433013, -0.27735, 0.60048, 0.75, -0.83205, 0.240192, -0.5), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 71
		{ n = "EyeL", s = "Block", z = Vector3.new(0.1485, 0.27, 0.09), cf = CFrame.new(-0.2925, 6.75, -0.800999, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 72
		{ n = "MiddleTip2", s = "Wedge", z = Vector3.new(0.945, 0.945, 0.54), cf = CFrame.new(1.282035, 7.797711, 0, 0, 0.406737, 0.913545, 0, 0.913545, -0.406737, -1, 0, 0), c = Color3.fromRGB(160, 119, 209), m = Enum.Material.Plastic }, -- 73
		{ n = "MiddleTip1", s = "Wedge", z = Vector3.new(0.945, 0.945, 0.54), cf = CFrame.new(0.641018, 7.79771, 1.110275, 0.866025, 0.203368, 0.456773, 0, 0.913545, -0.406737, -0.5, 0.352244, 0.791153), c = Color3.fromRGB(160, 119, 209), m = Enum.Material.Plastic }, -- 74
		{ n = "HoodPetal4", s = "Block", z = Vector3.new(0.81, 2.52, 0.495), cf = CFrame.new(0.385337, 7.620742, 0.826359, 0.906308, 0.130596, 0.401934, 0, 0.951056, -0.309017, -0.422618, 0.280064, 0.86195), c = Color3.fromRGB(160, 119, 209), m = Enum.Material.Plastic }, -- 75
		{ n = "DrapeVein4", s = "Block", z = Vector3.new(0.054, 0.081, 1.170597), cf = CFrame.new(0, 2.630391, -0.868214, 1, 0, 0, 0, 0.40364, 0.914917, 0, -0.914918, 0.40364), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 76
		{ n = "BrowR", s = "Block", z = Vector3.new(0.387, 0.0675, 0.081), cf = CFrame.new(0.306, 6.988501, -0.760498, 0.990268, 0.139173, 0, -0.139173, 0.990268, 0, 0, 0, 1), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 77
		{ n = "HoodVein4", s = "Block", z = Vector3.new(0.0495, 1.89, 0.072), cf = CFrame.new(0.291285, 7.693053, 0.624664, 0.906308, 0.130596, 0.401934, 0, 0.951056, -0.309017, -0.422618, 0.280064, 0.86195), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 78
		{ n = "OuterTip3", s = "Wedge", z = Vector3.new(1.17, 1.08, 0.54), cf = CFrame.new(2.3086, 6.283773, 0.157501, 0, 0.766044, 0.642788, 0, 0.642788, -0.766044, -1, 0, 0), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 79
		{ n = "OuterPetal3", s = "Block", z = Vector3.new(1.215, 2.16, 0.45), cf = CFrame.new(1.274441, 5.416009, 0.157501, 0, 0.766044, 0.642788, 0, 0.642788, -0.766044, -1, 0, 0), c = Color3.fromRGB(68, 40, 109), m = Enum.Material.Plastic }, -- 80
		{ n = "MiddleTip5", s = "Wedge", z = Vector3.new(0.945, 0.945, 0.54), cf = CFrame.new(-1.282035, 7.797711, 0, 0, -0.406737, -0.913545, 0, 0.913545, -0.406737, 1, 0, 0), c = Color3.fromRGB(160, 119, 209), m = Enum.Material.Plastic }, -- 81
		{ n = "BarkRidge2", s = "Block", z = Vector3.new(0.162, 1.575, 0.1575), cf = CFrame.new(0, 3.825001, 0.796501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 82
		{ n = "MaskCheekL", s = "Wedge", z = Vector3.new(0.18, 0.765, 0.2925), cf = CFrame.new(-0.576, 6.520501, -0.616501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(231, 225, 240), m = Enum.Material.Plastic }, -- 83
		{ n = "HoodTip4", s = "Wedge", z = Vector3.new(0.765, 0.99, 0.54), cf = CFrame.new(0.591026, 9.118657, 1.26746, 0.906308, 0.130596, 0.401934, 0, 0.951056, -0.309017, -0.422618, 0.280064, 0.86195), c = Color3.fromRGB(190, 153, 228), m = Enum.Material.Plastic }, -- 84
		{ n = "OuterTip4", s = "Wedge", z = Vector3.new(1.17, 1.08, 0.54), cf = CFrame.new(1.950436, 5.419844, -1.792934, -0.707107, 0.683013, 0.183013, 0, 0.258819, -0.965926, -0.707107, -0.683013, -0.183013), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 85
		{ n = "HoodVein2", s = "Block", z = Vector3.new(0.0495, 1.89, 0.072), cf = CFrame.new(0.665753, 7.693053, 0.178391, 0.258819, 0.298488, 0.91865, 0, 0.951057, -0.309017, -0.965926, 0.07998, 0.246152), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 86
		{ n = "HemRoot1", s = "Block", z = Vector3.new(0.2925, 0.2925, 1.303013), cf = CFrame.new(0, 1.395001, 2.317501, -1, 0, 0, 0, 0.707107, 0.707107, 0, 0.707107, -0.707107), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 87
		{ n = "HemTip1", s = "Wedge", z = Vector3.new(0.3825, 0.36, 0.585), cf = CFrame.new(0, 0.990001, 2.7225, -1, 0, 0, 0, 0.707107, 0.707107, 0, 0.707107, -0.707107), c = Color3.fromRGB(68, 40, 109), m = Enum.Material.Plastic }, -- 88
		{ n = "BarkRidge1", s = "Block", z = Vector3.new(0.162, 1.575, 0.1575), cf = CFrame.new(-0.45, 3.825001, 0.796501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(65, 43, 88), m = Enum.Material.Plastic }, -- 89
		{ n = "HemTip5", s = "Wedge", z = Vector3.new(0.3825, 0.36, 0.585), cf = CFrame.new(-1.7537, 0.990001, -0.314999, 0.480385, -0.720577, 0.5, -0.27735, 0.416025, 0.866025, -0.832051, -0.5547, 0), c = Color3.fromRGB(68, 40, 109), m = Enum.Material.Plastic }, -- 90
		{ n = "MiddleTip3", s = "Wedge", z = Vector3.new(0.945, 0.945, 0.54), cf = CFrame.new(1.205585, 5.4007, -2.088131, -0.866025, 0.495134, -0.069587, 0, -0.139173, -0.990268, -0.5, -0.857597, 0.120527), c = Color3.fromRGB(160, 119, 209), m = Enum.Material.Plastic }, -- 91
		{ n = "OuterPetal2", s = "Block", z = Vector3.new(1.215, 2.16, 0.45), cf = CFrame.new(0.901165, 5.416009, 1.058666, 0.707107, 0.541675, 0.454519, 0, 0.642788, -0.766044, -0.707107, 0.541675, 0.454519), c = Color3.fromRGB(87, 48, 134), m = Enum.Material.Plastic }, -- 92
		{ n = "OuterTip6", s = "Wedge", z = Vector3.new(1.17, 1.08, 0.54), cf = CFrame.new(-1.950435, 5.419844, -1.792934, -0.707107, -0.683012, -0.183013, 0, 0.258819, -0.965926, 0.707107, -0.683013, -0.183013), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 93
		{ n = "RootToe1", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(-1.035001, 0.5625, -1.057499, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 94
		{ n = "OuterTip2", s = "Wedge", z = Vector3.new(1.17, 1.08, 0.54), cf = CFrame.new(1.632426, 6.283772, 1.789928, 0.707107, 0.541675, 0.454519, 0, 0.642788, -0.766044, -0.707107, 0.541675, 0.454519), c = Color3.fromRGB(122, 76, 173), m = Enum.Material.Plastic }, -- 95
		{ n = "EyeR", s = "Block", z = Vector3.new(0.1485, 0.27, 0.09), cf = CFrame.new(0.2925, 6.75, -0.800999, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(148, 110, 202), m = Enum.Material.Neon, st = false, cs = false }, -- 96
	},
	Joints = {
		{ k = "Motor6D", n = "DrapeJoint2", h = 1, a = 1, b = 4, c0 = CFrame.new(0.467654, -0.54, 0.27, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.94366, -0.494261, 0.151074, 0.856086, 0.753441, 0.565672, 0.335175, -0.433628, 0.810674, -0.393415) },
		{ k = "Motor6D", n = "Hip4", h = 1, a = 1, b = 5, c0 = CFrame.new(1.205286, -1.386139, 0.81654, -0.4819, 0.538743, -0.691035, 0.008842, 0.791598, 0.610978, 0.876182, 0.28832, -0.386235), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Stem", h = 1, a = 1, b = 11, c0 = CFrame.new(0, 1.035, -0.045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.6525, 0.045, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint7", h = 1, a = 1, b = 15, c0 = CFrame.new(-0.585, 0.9675, 0, 0, -0.766044, -0.642788, 0, 0.642788, -0.766044, 1, 0, 0), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "DrapeJoint4", h = 1, a = 1, b = 20, c0 = CFrame.new(0, -0.54, -0.54, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.83614, 1, 0, 0, 0, 0.40364, -0.914918, 0, 0.914918, 0.40364) },
		{ k = "Motor6D", n = "OuterJoint8", h = 1, a = 1, b = 23, c0 = CFrame.new(-0.413657, 0.9675, 0.413657, 0.707107, -0.541675, -0.45452, 0, 0.642788, -0.766044, 0.707107, 0.541675, 0.454519), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint5", h = 1, a = 1, b = 30, c0 = CFrame.new(0, 0.9675, -0.585, -1, 0, 0, 0, 0.258819, -0.965926, 0, -0.965926, -0.258819), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip1", h = 1, a = 1, b = 31, c0 = CFrame.new(-1.194008, -1.359982, -0.872044, 0.478407, -0.558692, 0.677488, 0.1205, 0.805973, 0.579557, -0.869831, -0.195627, 0.452906), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip3", h = 1, a = 1, b = 33, c0 = CFrame.new(-1.205286, -1.386139, 0.81654, -0.4819, -0.538743, 0.691035, -0.008842, 0.791598, 0.610978, -0.876182, 0.28832, -0.386235), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip2", h = 1, a = 1, b = 36, c0 = CFrame.new(1.194008, -1.359982, -0.872044, 0.478407, 0.558692, -0.677488, -0.1205, 0.805973, 0.579557, 0.869831, -0.195627, 0.452906), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "DrapeJoint3", h = 1, a = 1, b = 40, c0 = CFrame.new(0.467654, -0.54, -0.27, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.873452, 0.494261, 0.151074, 0.856086, 0.732277, 0.458355, -0.503667, -0.468482, 0.875835, 0.115919) },
		{ k = "Motor6D", n = "OuterJoint6", h = 1, a = 1, b = 41, c0 = CFrame.new(-0.413657, 0.9675, -0.413657, -0.707107, -0.683013, -0.183013, 0, 0.258819, -0.965926, 0.707107, -0.683013, -0.183013), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "DrapeJoint1", h = 1, a = 1, b = 46, c0 = CFrame.new(0, -0.54, 0.54, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.976873, -1, 0, 0, 0, 0.621882, 0.783111, 0, 0.783111, -0.621882) },
		{ k = "Motor6D", n = "DrapeJoint5", h = 1, a = 1, b = 47, c0 = CFrame.new(-0.467654, -0.54, -0.27, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.873452, 0.494261, -0.151074, -0.856086, -0.732277, 0.458355, -0.503667, 0.468482, 0.875835, 0.115919) },
		{ k = "Motor6D", n = "OuterJoint4", h = 1, a = 1, b = 50, c0 = CFrame.new(0.413657, 0.9675, -0.413657, -0.707107, 0.683013, 0.183013, 0, 0.258819, -0.965926, -0.707107, -0.683013, -0.183013), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "DrapeJoint6", h = 1, a = 1, b = 56, c0 = CFrame.new(-0.467654, -0.54, 0.27, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.94366, -0.494261, -0.151074, -0.856086, -0.753441, 0.565672, 0.335175, 0.433628, 0.810674, -0.393415) },
		{ k = "Motor6D", n = "OuterJoint1", h = 1, a = 1, b = 59, c0 = CFrame.new(0, 0.9675, 0.585, 1, 0, 0, 0, 0.642788, -0.766044, 0, 0.766044, 0.642788), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BarkRidge3Weld", h = 1, a = 1, b = 66, c0 = CFrame.new(0.45, -0.045, 0.639, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint3", h = 1, a = 1, b = 80, c0 = CFrame.new(0.585, 0.9675, 0, 0, 0.766044, 0.642788, 0, 0.642788, -0.766044, -1, 0, 0), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BarkRidge2Weld", h = 1, a = 1, b = 82, c0 = CFrame.new(0, -0.045, 0.639, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BarkRidge1Weld", h = 1, a = 1, b = 89, c0 = CFrame.new(-0.45, -0.045, 0.639, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint2", h = 1, a = 1, b = 92, c0 = CFrame.new(0.413657, 0.9675, 0.413657, 0.707107, 0.541675, 0.454519, 0, 0.642788, -0.766044, -0.707107, 0.541675, 0.454519), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 3, a = 3, b = 1, c0 = CFrame.new(0, 3.87, 0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DrapeVein2Weld", h = 4, a = 4, b = 2, c0 = CFrame.new(0, 0.162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HemJoint2", h = 4, a = 4, b = 26, c0 = CFrame.new(0, 0, -0.94366, -0.494261, 0.151074, 0.856086, 0.753441, 0.565672, 0.335175, -0.433628, 0.810674, -0.393415), c1 = CFrame.new(0, 0, 0.54, -0.480384, 0.27735, 0.83205, 0.762713, 0.60048, 0.240192, -0.433013, 0.75, -0.5) },
		{ k = "Motor6D", n = "Knee4", h = 5, a = 5, b = 7, c0 = CFrame.new(0, -0.825922, -0.936943, 1, 0, 0, 0, 0.125456, 0.992099, 0, -0.992099, 0.125456), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe4Weld", h = 6, a = 6, b = 8, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle4", h = 7, a = 7, b = 6, c0 = CFrame.new(-0.002188, 0.125443, -1.045844, -0.4819, 0.008842, 0.876182, 0.753164, -0.506839, 0.419355, 0.447791, 0.861995, 0.237586), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FaceCoreWeld", h = 9, a = 9, b = 10, c0 = CFrame.new(0, -0.045, -0.6615, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HoodJoint1", h = 9, a = 9, b = 13, c0 = CFrame.new(-0.565067, -0.045, 0.151409, 0.258819, -0.298488, -0.91865, 0, 0.951057, -0.309017, 0.965926, 0.079979, 0.246152), c1 = CFrame.new(0, -1.0575, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HoodJoint3", h = 9, a = 9, b = 17, c0 = CFrame.new(-0.247232, -0.045, 0.53019, 0.906308, -0.130596, -0.401934, 0, 0.951057, -0.309017, 0.422618, 0.280064, 0.86195), c1 = CFrame.new(0, -1.057499, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HoodJoint2", h = 9, a = 9, b = 24, c0 = CFrame.new(0.565067, -0.045, 0.151409, 0.258819, 0.298488, 0.91865, 0, 0.951057, -0.309017, -0.965926, 0.079979, 0.246152), c1 = CFrame.new(0, -1.0575, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddlePetal1Weld", h = 9, a = 9, b = 27, c0 = CFrame.new(0.403077, 0.068862, 0.698149, 0.866025, 0.203368, 0.456773, 0, 0.913545, -0.406737, -0.5, 0.352244, 0.791154), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddlePetal4Weld", h = 9, a = 9, b = 35, c0 = CFrame.new(-0.626278, -1.096467, -1.084744, -0.866025, -0.495134, 0.069587, 0, -0.139173, -0.990268, 0.5, -0.857597, 0.120527), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddlePetal3Weld", h = 9, a = 9, b = 51, c0 = CFrame.new(0.626278, -1.096467, -1.084744, -0.866025, 0.495134, -0.069587, 0, -0.139173, -0.990268, -0.5, -0.857597, 0.120527), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddlePetal5Weld", h = 9, a = 9, b = 52, c0 = CFrame.new(-0.806154, 0.068862, 0, 0, -0.406737, -0.913545, 0, 0.913545, -0.406737, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddlePetal6Weld", h = 9, a = 9, b = 62, c0 = CFrame.new(-0.403077, 0.068862, 0.698149, 0.866025, -0.203368, -0.456773, 0, 0.913545, -0.406737, 0.5, 0.352244, 0.791153), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddlePetal2Weld", h = 9, a = 9, b = 63, c0 = CFrame.new(0.806154, 0.068862, 0, 0, 0.406737, 0.913545, 0, 0.913545, -0.406737, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HoodJoint4", h = 9, a = 9, b = 75, c0 = CFrame.new(0.247232, -0.045, 0.53019, 0.906308, 0.130596, 0.401934, 0, 0.951057, -0.309017, -0.422618, 0.280064, 0.86195), c1 = CFrame.new(0, -1.057499, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MouthWeld", h = 10, a = 10, b = 12, c0 = CFrame.new(0, -0.4725, -0.126, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "ForeheadMarkWeld", h = 10, a = 10, b = 44, c0 = CFrame.new(0, 0.5355, -0.117, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowLWeld", h = 10, a = 10, b = 45, c0 = CFrame.new(-0.306, 0.3735, -0.099, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MaskCheekRWeld", h = 10, a = 10, b = 67, c0 = CFrame.new(0.576, -0.0945, 0.045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "EyeLWeld", h = 10, a = 10, b = 72, c0 = CFrame.new(-0.2925, 0.135, -0.1395, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowRWeld", h = 10, a = 10, b = 77, c0 = CFrame.new(0.306, 0.3735, -0.099, 0.990268, 0.139173, 0, -0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MaskCheekLWeld", h = 10, a = 10, b = 83, c0 = CFrame.new(-0.576, -0.0945, 0.045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "EyeRWeld", h = 10, a = 10, b = 96, c0 = CFrame.new(0.2925, 0.135, -0.1395, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Blossom", h = 11, a = 11, b = 9, c0 = CFrame.new(0, 0.45, -0.0675, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.6525, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodTip1Weld", h = 13, a = 13, b = 14, c0 = CFrame.new(0, 1.575, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodVein1Weld", h = 13, a = 13, b = 57, c0 = CFrame.new(0, 0, -0.234, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip7Weld", h = 15, a = 15, b = 16, c0 = CFrame.new(0, 1.35, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodVein3Weld", h = 17, a = 17, b = 18, c0 = CFrame.new(0, 0.000001, -0.234, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodTip3Weld", h = 17, a = 17, b = 68, c0 = CFrame.new(0, 1.575001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HemJoint4", h = 20, a = 20, b = 21, c0 = CFrame.new(0, 0, -0.836141, 1, 0, 0, 0, 0.40364, -0.914918, 0, 0.914918, 0.40364), c1 = CFrame.new(0, 0, 0.426908, 1, 0, 0, 0, 0.316227, -0.948683, 0, 0.948683, 0.316227) },
		{ k = "Weld", n = "DrapeVein4Weld", h = 20, a = 20, b = 76, c0 = CFrame.new(0, 0.162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HemTip4Weld", h = 21, a = 21, b = 19, c0 = CFrame.new(0, 0, -0.426907, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip8Weld", h = 23, a = 23, b = 22, c0 = CFrame.new(0, 1.35, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodTip2Weld", h = 24, a = 24, b = 25, c0 = CFrame.new(0, 1.575, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodVein2Weld", h = 24, a = 24, b = 86, c0 = CFrame.new(0, 0, -0.234, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HemTip2Weld", h = 26, a = 26, b = 28, c0 = CFrame.new(0, 0, -0.54, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddleTip1Weld", h = 27, a = 27, b = 74, c0 = CFrame.new(0, 1.17, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip5Weld", h = 30, a = 30, b = 29, c0 = CFrame.new(0, 1.35, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee1", h = 31, a = 31, b = 32, c0 = CFrame.new(0, -0.820169, -0.975253, 1, 0, 0, 0, 0.171475, 0.985189, 0, -0.985188, 0.171475), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle1", h = 32, a = 32, b = 49, c0 = CFrame.new(-0.029824, 0.10711, -1.05362, 0.478407, 0.120499, -0.869831, -0.763255, -0.432769, -0.479743, -0.434244, 0.893416, -0.115068), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee3", h = 33, a = 33, b = 34, c0 = CFrame.new(0, -0.825922, -0.936943, 1, 0, 0, 0, 0.125456, 0.992099, 0, -0.992099, 0.125456), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle3", h = 34, a = 34, b = 64, c0 = CFrame.new(0.002188, 0.125443, -1.045844, -0.4819, -0.008842, -0.876182, -0.753164, -0.506839, 0.419355, -0.447791, 0.861995, 0.237586), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddleTip4Weld", h = 35, a = 35, b = 69, c0 = CFrame.new(0, 1.17, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee2", h = 36, a = 36, b = 38, c0 = CFrame.new(0, -0.820169, -0.975253, 1, 0, 0, 0, 0.171475, 0.985189, 0, -0.985188, 0.171475), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe2Weld", h = 37, a = 37, b = 39, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle2", h = 38, a = 38, b = 37, c0 = CFrame.new(0.029824, 0.10711, -1.05362, 0.478407, -0.120499, 0.869831, 0.763255, -0.432769, -0.479743, 0.434244, 0.893416, -0.115068), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HemJoint3", h = 40, a = 40, b = 42, c0 = CFrame.new(0, 0, -0.873452, 0.494261, 0.151074, 0.856086, 0.732277, 0.458355, -0.503667, -0.468482, 0.875835, 0.115919), c1 = CFrame.new(0, 0, 0.467654, 0.480384, 0.27735, 0.83205, 0.720577, 0.416025, -0.5547, -0.5, 0.866026, 0) },
		{ k = "Weld", n = "DrapeVein3Weld", h = 40, a = 40, b = 53, c0 = CFrame.new(0, 0.162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip6Weld", h = 41, a = 41, b = 93, c0 = CFrame.new(0, 1.35, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HemTip3Weld", h = 42, a = 42, b = 43, c0 = CFrame.new(0, 0, -0.467654, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DrapeVein1Weld", h = 46, a = 46, b = 54, c0 = CFrame.new(0, 0.162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HemJoint1", h = 46, a = 46, b = 87, c0 = CFrame.new(0, 0, -0.976873, -1, 0, 0, 0, 0.621882, 0.783111, 0, 0.783111, -0.621882), c1 = CFrame.new(0, 0, 0.572757, -1, 0, 0, 0, 0.707107, 0.707107, 0, 0.707107, -0.707107) },
		{ k = "Motor6D", n = "HemJoint5", h = 47, a = 47, b = 48, c0 = CFrame.new(0, 0, -0.873452, 0.494261, -0.151074, -0.856086, -0.732277, 0.458355, -0.503667, 0.468482, 0.875835, 0.115919), c1 = CFrame.new(0, 0, 0.467654, 0.480384, -0.27735, -0.83205, -0.720577, 0.416025, -0.5547, 0.5, 0.866026, 0) },
		{ k = "Weld", n = "DrapeVein5Weld", h = 47, a = 47, b = 60, c0 = CFrame.new(0, 0.162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HemTip5Weld", h = 48, a = 48, b = 90, c0 = CFrame.new(0, 0, -0.467654, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe1Weld", h = 49, a = 49, b = 94, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip4Weld", h = 50, a = 50, b = 85, c0 = CFrame.new(0, 1.35, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddleTip3Weld", h = 51, a = 51, b = 91, c0 = CFrame.new(0, 1.17, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddleTip5Weld", h = 52, a = 52, b = 81, c0 = CFrame.new(0, 1.17, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DrapeVein6Weld", h = 56, a = 56, b = 55, c0 = CFrame.new(0, 0.162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HemJoint6", h = 56, a = 56, b = 71, c0 = CFrame.new(0, 0, -0.94366, -0.494261, -0.151074, -0.856086, -0.753441, 0.565672, 0.335175, 0.433628, 0.810674, -0.393415), c1 = CFrame.new(0, 0, 0.54, -0.480384, -0.27735, -0.83205, -0.762713, 0.60048, 0.240192, 0.433013, 0.75, -0.5) },
		{ k = "Weld", n = "OuterTip1Weld", h = 59, a = 59, b = 58, c0 = CFrame.new(0, 1.35, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddleTip6Weld", h = 62, a = 62, b = 61, c0 = CFrame.new(0, 1.17, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MiddleTip2Weld", h = 63, a = 63, b = 73, c0 = CFrame.new(0, 1.17, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe3Weld", h = 64, a = 64, b = 65, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HemTip6Weld", h = 71, a = 71, b = 70, c0 = CFrame.new(0, 0, -0.54, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodVein4Weld", h = 75, a = 75, b = 78, c0 = CFrame.new(0, 0.000001, -0.234, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodTip4Weld", h = 75, a = 75, b = 84, c0 = CFrame.new(0, 1.575001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip3Weld", h = 80, a = 80, b = 79, c0 = CFrame.new(0, 1.35, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HemTip1Weld", h = 87, a = 87, b = 88, c0 = CFrame.new(0, 0, -0.572756, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip2Weld", h = 92, a = 92, b = 95, c0 = CFrame.new(0, 1.35, -0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
	},
}

return spec
