--!strict
--==============================================================================
-- PLANT FORM: SuperNovus (Starbloom plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Starbloom plants/SuperNovus" by a read-only generator on 2026-10-03. The original
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
	Source = "Starbloom plants/SuperNovus", Kind = "plant", Yaw = 0,
	Size = Vector3.new(6.520477, 10.837941, 6.52047), Height = 10.837941, PartCount = 96,
	Base = 1,
	Unit = 4.5, ModelScale = 1,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(0.54, 0.54, 0.54), cf = CFrame.new(0, 0.000001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(29, 25, 58), m = Enum.Material.Plastic, t = 1 }, -- 1
		{ n = "StemBody", s = "Block", z = Vector3.new(1.395, 2.34, 1.395), cf = CFrame.new(0, 3.870001, 0.157501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(61, 39, 108), m = Enum.Material.Plastic }, -- 2
		{ n = "RootUpper4", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(1.205284, 2.483862, 0.974041, -0.4819, 0.538743, -0.691035, 0.008842, 0.791599, 0.610978, 0.876182, 0.28832, -0.386235), c = Color3.fromRGB(61, 39, 108), m = Enum.Material.Plastic }, -- 3
		{ n = "UpperStem", s = "Block", z = Vector3.new(0.9, 1.665, 0.99), cf = CFrame.new(0.135002, 5.692501, 0.022503, 0.996195, 0.087156, 0, -0.087156, 0.996195, 0, 0, 0, 1), c = Color3.fromRGB(82, 46, 137), m = Enum.Material.Plastic }, -- 4
		{ n = "BlossomHub", s = "Block", z = Vector3.new(1.395, 0.81, 1.395), cf = CFrame.new(0.000008, 8.37, 0.000004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(47, 33, 86), m = Enum.Material.Plastic }, -- 5
		{ n = "OuterPetal12", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(-0.675468, 8.670616, 1.16996, 0.866025, -0.475528, -0.154509, 0, 0.309017, -0.951057, 0.5, 0.823639, 0.267617), c = Color3.fromRGB(102, 63, 157), m = Enum.Material.Plastic }, -- 6
		{ n = "CrownStem", s = "Block", z = Vector3.new(0.81, 1.8, 0.855), cf = CFrame.new(-0.035995, 7.357501, 0.054005, 0.992546, -0.121869, 0, 0.121869, 0.992546, 0, 0, 0, 1), c = Color3.fromRGB(87, 49, 138), m = Enum.Material.Plastic }, -- 7
		{ n = "OuterGlow12", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(-0.713707, 8.435228, 1.236195, 0.866025, -0.475528, -0.154509, 0, 0.309017, -0.951057, 0.5, 0.823639, 0.267617), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 8
		{ n = "OuterPetal6", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(0.675484, 8.670616, -1.169952, -0.866025, 0.475528, 0.154509, 0, 0.309017, -0.951057, -0.5, -0.823639, -0.267617), c = Color3.fromRGB(102, 63, 157), m = Enum.Material.Plastic }, -- 9
		{ n = "OuterGlow6", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(0.713722, 8.435228, -1.236187, -0.866025, 0.475528, 0.154509, 0, 0.309017, -0.951057, -0.5, -0.823639, -0.267617), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 10
		{ n = "CrystalCore", s = "Block", z = Vector3.new(0.72, 1.395, 0.72), cf = CFrame.new(0.000008, 9.045, 0.000004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 11
		{ n = "CrystalRib2", s = "Block", z = Vector3.new(0.117, 1.17, 0.135), cf = CFrame.new(-0.337494, 8.9775, 0.000004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 12
		{ n = "GoldRidge3_1", s = "Block", z = Vector3.new(0.108, 1.395, 0.099), cf = CFrame.new(-0.281654, 7.327338, 0.459003, 0.992546, -0.121869, 0, 0.121869, 0.992546, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 13
		{ n = "OuterPetal2", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(0.675484, 8.670616, 1.16996, 0.866025, 0.475528, 0.154508, 0, 0.309017, -0.951057, -0.5, 0.823639, 0.267617), c = Color3.fromRGB(102, 63, 157), m = Enum.Material.Plastic }, -- 14
		{ n = "OuterGlow2", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(0.713722, 8.435228, 1.236195, 0.866025, 0.475528, 0.154508, 0, 0.309017, -0.951057, -0.5, 0.823639, 0.267617), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 15
		{ n = "RootLower2", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(1.396507, 1.283769, -0.995792, 0.478407, 0.763255, 0.434245, -0.120499, -0.432769, 0.893416, 0.869831, -0.479743, -0.115068), c = Color3.fromRGB(87, 49, 138), m = Enum.Material.Plastic }, -- 16
		{ n = "RootUpper2", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(1.194008, 2.510019, -0.714542, 0.478407, 0.558692, -0.677488, -0.1205, 0.805974, 0.579557, 0.869831, -0.195627, 0.452906), c = Color3.fromRGB(61, 39, 108), m = Enum.Material.Plastic }, -- 17
		{ n = "RootFoot2", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(1.034996, 0.2925, -0.899998, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(61, 39, 108), m = Enum.Material.Plastic }, -- 18
		{ n = "CrystalRib4", s = "Block", z = Vector3.new(0.117, 1.17, 0.135), cf = CFrame.new(0.000008, 8.9775, -0.337498, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 19
		{ n = "InnerPetal4", s = "Block", z = Vector3.new(0.9, 1.71, 0.4725), cf = CFrame.new(-0.192253, 9.252752, -0.717533, -0.965926, -0.105271, -0.236443, 0, 0.913545, -0.406737, 0.258819, -0.392877, -0.882417), c = Color3.fromRGB(47, 33, 86), m = Enum.Material.Plastic }, -- 20
		{ n = "InnerTip4", s = "Wedge", z = Vector3.new(0.81, 0.99, 0.5175), cf = CFrame.new(-0.310684, 10.280491, -1.159519, -0.965926, -0.105271, -0.236443, 0, 0.913545, -0.406737, 0.258819, -0.392877, -0.882417), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 21
		{ n = "InnerGlow2", s = "Block", z = Vector3.new(0.585, 1.215, 0.09), cf = CFrame.new(0.916092, 9.161238, 0.245468, 0.258819, 0.392877, 0.882417, 0, 0.913545, -0.406737, -0.965926, 0.105271, 0.236443), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 22
		{ n = "InnerPetal2", s = "Block", z = Vector3.new(0.9, 1.71, 0.4725), cf = CFrame.new(0.717545, 9.252753, 0.192268, 0.258819, 0.392877, 0.882417, 0, 0.913545, -0.406737, -0.965926, 0.105271, 0.236443), c = Color3.fromRGB(47, 33, 86), m = Enum.Material.Plastic }, -- 23
		{ n = "CoronaSepal4", s = "Wedge", z = Vector3.new(0.3375, 1.35, 0.27), cf = CFrame.new(0.000008, 9.289108, -0.626602, -1, 0, 0, 0, 0.707107, -0.707107, 0, -0.707107, -0.707107), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 24
		{ n = "InnerGlow4", s = "Block", z = Vector3.new(0.585, 1.215, 0.09), cf = CFrame.new(-0.245453, 9.161237, -0.916077, -0.965926, -0.105271, -0.236443, 0, 0.913545, -0.406737, 0.258819, -0.392877, -0.882417), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 25
		{ n = "OuterPetal10", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(-1.350945, 8.670615, 0.000004, 0, -0.951057, -0.309017, 0, 0.309017, -0.951057, 1, 0, 0), c = Color3.fromRGB(102, 63, 157), m = Enum.Material.Plastic }, -- 26
		{ n = "OuterGlow10", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(-1.427429, 8.435227, 0.000004, 0, -0.951057, -0.309017, 0, 0.309017, -0.951057, 1, 0, 0), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 27
		{ n = "OuterPetal7", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(0.000008, 8.670615, -1.350948, -1, 0, 0, 0, 0.309017, -0.951057, 0, -0.951057, -0.309017), c = Color3.fromRGB(82, 46, 137), m = Enum.Material.Plastic }, -- 28
		{ n = "OuterPetal8", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(-0.675468, 8.670616, -1.169952, -0.866025, -0.475528, -0.154508, 0, 0.309017, -0.951057, 0.5, -0.823639, -0.267617), c = Color3.fromRGB(102, 63, 157), m = Enum.Material.Plastic }, -- 29
		{ n = "OuterGlow8", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(-0.713707, 8.435228, -1.236187, -0.866025, -0.475528, -0.154508, 0, 0.309017, -0.951057, 0.5, -0.823639, -0.267617), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 30
		{ n = "InnerPetal6", s = "Block", z = Vector3.new(0.9, 1.71, 0.4725), cf = CFrame.new(-0.525269, 9.252754, 0.52528, 0.707107, -0.287606, -0.645974, 0, 0.913545, -0.406737, 0.707107, 0.287606, 0.645974), c = Color3.fromRGB(47, 33, 86), m = Enum.Material.Plastic }, -- 31
		{ n = "OuterPetal3", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(1.169968, 8.670615, 0.67548, 0.5, 0.823639, 0.267617, 0, 0.309017, -0.951057, -0.866025, 0.475528, 0.154508), c = Color3.fromRGB(82, 46, 137), m = Enum.Material.Plastic }, -- 32
		{ n = "CoronaSepal3", s = "Wedge", z = Vector3.new(0.3375, 1.35, 0.27), cf = CFrame.new(0.542664, 9.289108, -0.313301, -0.5, 0.612372, 0.612372, 0, 0.707107, -0.707107, -0.866025, -0.353553, -0.353553), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 33
		{ n = "RootLower1", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(-1.396507, 1.283769, -0.995792, 0.478407, -0.763255, -0.434245, 0.120499, -0.432769, 0.893416, -0.869831, -0.479743, -0.115068), c = Color3.fromRGB(87, 49, 138), m = Enum.Material.Plastic }, -- 34
		{ n = "RootUpper1", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(-1.194008, 2.510019, -0.714542, 0.478407, -0.558692, 0.677488, 0.1205, 0.805974, 0.579557, -0.869831, -0.195627, 0.452906), c = Color3.fromRGB(61, 39, 108), m = Enum.Material.Plastic }, -- 35
		{ n = "OuterGlow7", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(0.000008, 8.435227, -1.427429, -1, 0, 0, 0, 0.309017, -0.951057, 0, -0.951057, -0.309017), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 36
		{ n = "OuterPetal9", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(-1.169952, 8.670615, -0.675472, -0.5, -0.823639, -0.267617, 0, 0.309017, -0.951057, 0.866025, -0.475528, -0.154508), c = Color3.fromRGB(82, 46, 137), m = Enum.Material.Plastic }, -- 37
		{ n = "OuterTip9", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(-2.3004, 9.094741, -1.328136, -0.5, -0.823639, -0.267617, 0, 0.309017, -0.951057, 0.866025, -0.475528, -0.154508), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 38
		{ n = "GoldRidge1_1", s = "Block", z = Vector3.new(0.108, 1.89, 0.099), cf = CFrame.new(-0.360001, 3.870001, 0.810001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 39
		{ n = "CrystalRib1", s = "Block", z = Vector3.new(0.117, 1.17, 0.135), cf = CFrame.new(0.337509, 8.9775, 0.000004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 40
		{ n = "RootToe2", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(1.034996, 0.562501, -1.057499, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 41
		{ n = "InnerPetal1", s = "Block", z = Vector3.new(0.9, 1.71, 0.4725), cf = CFrame.new(0.192268, 9.252752, 0.717541, 0.965926, 0.105271, 0.236443, 0, 0.913545, -0.406737, -0.258819, 0.392877, 0.882417), c = Color3.fromRGB(47, 33, 86), m = Enum.Material.Plastic }, -- 42
		{ n = "InnerGlow1", s = "Block", z = Vector3.new(0.585, 1.215, 0.09), cf = CFrame.new(0.245468, 9.161237, 0.916084, 0.965926, 0.105271, 0.236443, 0, 0.913545, -0.406737, -0.258819, 0.392877, 0.882417), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 43
		{ n = "OuterPetal4", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(1.35096, 8.670615, 0.000004, 0, 0.951057, 0.309017, 0, 0.309017, -0.951057, -1, 0, 0), c = Color3.fromRGB(102, 63, 157), m = Enum.Material.Plastic }, -- 44
		{ n = "CoronaSepal5", s = "Wedge", z = Vector3.new(0.3375, 1.35, 0.27), cf = CFrame.new(-0.542648, 9.289108, -0.313301, -0.5, -0.612372, -0.612372, 0, 0.707107, -0.707107, 0.866025, -0.353553, -0.353553), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 45
		{ n = "InnerTip6", s = "Wedge", z = Vector3.new(0.81, 0.99, 0.5175), cf = CFrame.new(-0.848824, 10.280492, 0.848835, 0.707107, -0.287606, -0.645974, 0, 0.913545, -0.406737, 0.707107, 0.287606, 0.645974), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 46
		{ n = "OuterPetal11", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(-1.169952, 8.670615, 0.67548, 0.5, -0.823639, -0.267617, 0, 0.309017, -0.951057, 0.866025, 0.475528, 0.154508), c = Color3.fromRGB(82, 46, 137), m = Enum.Material.Plastic }, -- 47
		{ n = "OuterTip11", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(-2.3004, 9.094741, 1.328144, 0.5, -0.823639, -0.267617, 0, 0.309017, -0.951057, 0.866025, 0.475528, 0.154508), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 48
		{ n = "StemSeam2", s = "Block", z = Vector3.new(0.0585, 1.188, 0.063), cf = CFrame.new(0.135002, 5.692501, -0.458996, 0.996195, 0.087156, 0, -0.087156, 0.996195, 0, 0, 0, 1), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 49
		{ n = "OuterTip6", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(1.328148, 9.094741, -2.300396, -0.866025, 0.475528, 0.154509, 0, 0.309017, -0.951057, -0.5, -0.823639, -0.267617), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 50
		{ n = "CrystalRib3", s = "Block", z = Vector3.new(0.117, 1.17, 0.135), cf = CFrame.new(0.000008, 8.9775, 0.337505, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 51
		{ n = "CrystalTip", s = "Wedge", z = Vector3.new(0.63, 0.675, 0.72), cf = CFrame.new(0.000008, 9.9225, 0.000004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(213, 248, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 52
		{ n = "InnerTip1", s = "Wedge", z = Vector3.new(0.81, 0.99, 0.5175), cf = CFrame.new(0.310699, 10.280491, 1.159527, 0.965926, 0.105271, 0.236443, 0, 0.913545, -0.406737, -0.258819, 0.392877, 0.882417), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 53
		{ n = "GoldRidge1_2", s = "Block", z = Vector3.new(0.108, 1.89, 0.099), cf = CFrame.new(0.360001, 3.870001, 0.810001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 54
		{ n = "InnerGlow5", s = "Block", z = Vector3.new(0.585, 1.215, 0.09), cf = CFrame.new(-0.916069, 9.161238, -0.245461, -0.258819, -0.392877, -0.882417, 0, 0.913545, -0.406737, 0.965926, -0.105271, -0.236443), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 55
		{ n = "InnerPetal5", s = "Block", z = Vector3.new(0.9, 1.71, 0.4725), cf = CFrame.new(-0.717529, 9.252753, -0.192261, -0.258819, -0.392877, -0.882417, 0, 0.913545, -0.406737, 0.965926, -0.105271, -0.236443), c = Color3.fromRGB(47, 33, 86), m = Enum.Material.Plastic }, -- 56
		{ n = "InnerPetal3", s = "Block", z = Vector3.new(0.9, 1.71, 0.4725), cf = CFrame.new(0.525284, 9.252754, -0.525272, -0.707107, 0.287606, 0.645974, 0, 0.913545, -0.406737, -0.707107, -0.287606, -0.645974), c = Color3.fromRGB(47, 33, 86), m = Enum.Material.Plastic }, -- 57
		{ n = "InnerTip3", s = "Wedge", z = Vector3.new(0.81, 0.99, 0.5175), cf = CFrame.new(0.848839, 10.280492, -0.848827, -0.707107, 0.287606, 0.645974, 0, 0.913545, -0.406737, -0.707107, -0.287606, -0.645974), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 58
		{ n = "OuterTip4", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(2.656288, 9.09474, 0.000004, 0, 0.951057, 0.309017, 0, 0.309017, -0.951057, -1, 0, 0), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 59
		{ n = "InnerGlow6", s = "Block", z = Vector3.new(0.585, 1.215, 0.09), cf = CFrame.new(-0.670616, 9.161238, 0.670624, 0.707107, -0.287606, -0.645974, 0, 0.913545, -0.406737, 0.707107, 0.287606, 0.645974), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 60
		{ n = "OuterGlow4", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(1.427444, 8.435227, 0.000004, 0, 0.951057, 0.309017, 0, 0.309017, -0.951057, -1, 0, 0), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 61
		{ n = "StemSeam3", s = "Block", z = Vector3.new(0.0585, 1.2276, 0.063), cf = CFrame.new(-0.035995, 7.357501, -0.359997, 0.992546, -0.121869, 0, 0.121869, 0.992546, 0, 0, 0, 1), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 62
		{ n = "RootLower3", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(-1.407784, 1.257612, 1.09779, -0.4819, -0.753164, -0.447792, -0.008842, -0.50684, 0.861996, -0.876182, 0.419355, 0.237586), c = Color3.fromRGB(87, 49, 138), m = Enum.Material.Plastic }, -- 63
		{ n = "RootToe3", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(-1.034996, 0.5625, 0.742496, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 64
		{ n = "RootUpper3", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(-1.205284, 2.483862, 0.974041, -0.4819, -0.538743, 0.691035, -0.008842, 0.791599, 0.610978, -0.876182, 0.28832, -0.386235), c = Color3.fromRGB(61, 39, 108), m = Enum.Material.Plastic }, -- 65
		{ n = "RootFoot3", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(-1.034996, 0.2925, 0.899998, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(61, 39, 108), m = Enum.Material.Plastic }, -- 66
		{ n = "InnerTip5", s = "Wedge", z = Vector3.new(0.81, 0.99, 0.5175), cf = CFrame.new(-1.159515, 10.280492, -0.310692, -0.258819, -0.392877, -0.882417, 0, 0.913545, -0.406737, 0.965926, -0.105271, -0.236443), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 67
		{ n = "OuterTip12", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(-1.328133, 9.094741, 2.300404, 0.866025, -0.475528, -0.154509, 0, 0.309017, -0.951057, 0.5, 0.823639, 0.267617), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 68
		{ n = "OuterPetal5", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(1.169968, 8.670615, -0.675472, -0.5, 0.823639, 0.267617, 0, 0.309017, -0.951057, -0.866025, -0.475528, -0.154509), c = Color3.fromRGB(82, 46, 137), m = Enum.Material.Plastic }, -- 69
		{ n = "OuterPetal1", s = "Block", z = Vector3.new(1.035, 2.16, 0.5175), cf = CFrame.new(0.000008, 8.670615, 1.350956, 1, 0, 0, 0, 0.309017, -0.951057, 0, 0.951057, 0.309017), c = Color3.fromRGB(82, 46, 137), m = Enum.Material.Plastic }, -- 70
		{ n = "OuterGlow1", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(0.000008, 8.435227, 1.427437, 1, 0, 0, 0, 0.309017, -0.951057, 0, 0.951057, 0.309017), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 71
		{ n = "InnerGlow3", s = "Block", z = Vector3.new(0.585, 1.215, 0.09), cf = CFrame.new(0.670624, 9.161238, -0.670616, -0.707107, 0.287606, 0.645974, 0, 0.913545, -0.406737, -0.707107, -0.287606, -0.645974), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 72
		{ n = "RootFoot1", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(-1.034996, 0.2925, -0.899998, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(61, 39, 108), m = Enum.Material.Plastic }, -- 73
		{ n = "OuterTip8", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(-1.328133, 9.094741, -2.300396, -0.866025, -0.475528, -0.154508, 0, 0.309017, -0.951057, 0.5, -0.823639, -0.267617), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 74
		{ n = "CoronaSepal6", s = "Wedge", z = Vector3.new(0.3375, 1.35, 0.27), cf = CFrame.new(-0.542648, 9.289108, 0.313309, 0.5, -0.612372, -0.612372, 0, 0.707107, -0.707107, 0.866025, 0.353553, 0.353553), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 75
		{ n = "RootLower4", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(1.407784, 1.257612, 1.09779, -0.4819, 0.753164, 0.447792, 0.008842, -0.50684, 0.861996, 0.876182, 0.419355, 0.237586), c = Color3.fromRGB(87, 49, 138), m = Enum.Material.Plastic }, -- 76
		{ n = "RootToe4", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(1.034996, 0.5625, 0.742496, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 77
		{ n = "RootFoot4", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(1.034996, 0.2925, 0.899998, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(61, 39, 108), m = Enum.Material.Plastic }, -- 78
		{ n = "StemSeam1", s = "Block", z = Vector3.new(0.0585, 1.6632, 0.063), cf = CFrame.new(0, 3.870001, -0.526497, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 79
		{ n = "OuterGlow11", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(-1.236191, 8.435227, 0.713722, 0.5, -0.823639, -0.267617, 0, 0.309017, -0.951057, 0.866025, 0.475528, 0.154508), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 80
		{ n = "OuterTip7", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(0.000008, 9.09474, -2.656273, -1, 0, 0, 0, 0.309017, -0.951057, 0, -0.951057, -0.309017), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 81
		{ n = "OuterTip1", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(0.000008, 9.09474, 2.656281, 1, 0, 0, 0, 0.309017, -0.951057, 0, 0.951057, 0.309017), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 82
		{ n = "OuterTip2", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(1.328148, 9.094741, 2.300404, 0.866025, 0.475528, 0.154508, 0, 0.309017, -0.951057, -0.5, 0.823639, 0.267617), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 83
		{ n = "RootToe1", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(-1.034996, 0.562501, -1.057499, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 84
		{ n = "GoldRidge2_1", s = "Block", z = Vector3.new(0.108, 1.35, 0.099), cf = CFrame.new(-0.156387, 5.717994, 0.495003, 0.996195, 0.087156, 0, -0.087156, 0.996195, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 85
		{ n = "OuterTip3", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(2.300415, 9.094741, 1.328144, 0.5, 0.823639, 0.267617, 0, 0.309017, -0.951057, -0.866025, 0.475528, 0.154508), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 86
		{ n = "OuterTip10", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(-2.656273, 9.09474, 0.000004, 0, -0.951057, -0.309017, 0, 0.309017, -0.951057, 1, 0, 0), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 87
		{ n = "CoronaSepal2", s = "Wedge", z = Vector3.new(0.3375, 1.35, 0.27), cf = CFrame.new(0.542664, 9.289108, 0.313309, 0.5, 0.612372, 0.612372, 0, 0.707107, -0.707107, -0.866025, 0.353553, 0.353553), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 88
		{ n = "OuterGlow5", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(1.236206, 8.435227, -0.713715, -0.5, 0.823639, 0.267617, 0, 0.309017, -0.951057, -0.866025, -0.475528, -0.154509), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 89
		{ n = "OuterGlow9", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(-1.236191, 8.435227, -0.713715, -0.5, -0.823639, -0.267617, 0, 0.309017, -0.951057, 0.866025, -0.475528, -0.154508), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 90
		{ n = "GoldRidge2_2", s = "Block", z = Vector3.new(0.108, 1.35, 0.099), cf = CFrame.new(0.426392, 5.667008, 0.495003, 0.996195, 0.087156, 0, -0.087156, 0.996195, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 91
		{ n = "InnerTip2", s = "Wedge", z = Vector3.new(0.81, 0.99, 0.5175), cf = CFrame.new(1.159531, 10.280492, 0.310699, 0.258819, 0.392877, 0.882417, 0, 0.913545, -0.406737, -0.965926, 0.105271, 0.236443), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 92
		{ n = "CoronaSepal1", s = "Wedge", z = Vector3.new(0.3375, 1.35, 0.27), cf = CFrame.new(0.000008, 9.289108, 0.62661, 1, 0, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107), c = Color3.fromRGB(253, 234, 182), m = Enum.Material.Plastic }, -- 93
		{ n = "OuterGlow3", s = "Block", z = Vector3.new(0.72, 1.665, 0.09), cf = CFrame.new(1.236206, 8.435227, 0.713722, 0.5, 0.823639, 0.267617, 0, 0.309017, -0.951057, -0.866025, 0.475528, 0.154508), c = Color3.fromRGB(108, 218, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 94
		{ n = "GoldRidge3_2", s = "Block", z = Vector3.new(0.108, 1.395, 0.099), cf = CFrame.new(0.209663, 7.387664, 0.459003, 0.992546, -0.121869, 0, 0.121869, 0.992546, 0, 0, 0, 1), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 95
		{ n = "OuterTip5", s = "Wedge", z = Vector3.new(0.945, 1.08, 0.585), cf = CFrame.new(2.300415, 9.094741, -1.328136, -0.5, 0.823639, 0.267617, 0, 0.309017, -0.951057, -0.866025, -0.475528, -0.154509), c = Color3.fromRGB(237, 211, 147), m = Enum.Material.Plastic }, -- 96
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 3.87, 0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip4", h = 2, a = 2, b = 3, c0 = CFrame.new(1.205286, -1.386139, 0.81654, -0.4819, 0.538743, -0.691035, 0.008842, 0.791598, 0.610978, 0.876182, 0.28832, -0.386235), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Stem", h = 2, a = 2, b = 4, c0 = CFrame.new(0.054, 1.08, -0.0675, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.015979, -0.746734, 0.0675, 0.996195, -0.087156, 0, 0.087156, 0.996195, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip2", h = 2, a = 2, b = 17, c0 = CFrame.new(1.194008, -1.359982, -0.872044, 0.478407, 0.558692, -0.677488, -0.1205, 0.805973, 0.579557, 0.869831, -0.195627, 0.452906), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip1", h = 2, a = 2, b = 35, c0 = CFrame.new(-1.194008, -1.359982, -0.872044, 0.478407, -0.558692, 0.677488, 0.1205, 0.805973, 0.579557, -0.869831, -0.195627, 0.452906), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GoldRidge1_1Weld", h = 2, a = 2, b = 39, c0 = CFrame.new(-0.36, 0, 0.6525, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GoldRidge1_2Weld", h = 2, a = 2, b = 54, c0 = CFrame.new(0.36, 0, 0.6525, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip3", h = 2, a = 2, b = 65, c0 = CFrame.new(-1.205286, -1.386139, 0.81654, -0.4819, -0.538743, 0.691035, -0.008842, 0.791598, 0.610978, -0.876182, 0.28832, -0.386235), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StemSeam1Weld", h = 2, a = 2, b = 79, c0 = CFrame.new(0, 0, -0.684, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee4", h = 3, a = 3, b = 76, c0 = CFrame.new(0, -0.825922, -0.936943, 1, 0, 0, 0, 0.125456, 0.992099, 0, -0.992099, 0.125456), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Stem2", h = 4, a = 4, b = 7, c0 = CFrame.new(-0.148543, 0.768478, 0.018, 0.996195, -0.087156, 0, 0.087156, 0.996195, 0, 0, 0, 1), c1 = CFrame.new(-0.018708, -0.89086, -0.0135, 0.992546, 0.121869, 0, -0.121869, 0.992546, 0, 0, 0, 1) },
		{ k = "Weld", n = "StemSeam2Weld", h = 4, a = 4, b = 49, c0 = CFrame.new(0, 0, -0.4815, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GoldRidge2_1Weld", h = 4, a = 4, b = 85, c0 = CFrame.new(-0.2925, 0, 0.4725, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GoldRidge2_2Weld", h = 4, a = 4, b = 91, c0 = CFrame.new(0.2925, 0, 0.4725, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint12", h = 5, a = 5, b = 6, c0 = CFrame.new(-0.2475, 0.0225, 0.428683, 0.866025, -0.475528, -0.154509, 0, 0.309017, -0.951057, 0.5, 0.823639, 0.267617), c1 = CFrame.new(0, -0.9, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint6", h = 5, a = 5, b = 9, c0 = CFrame.new(0.2475, 0.0225, -0.428683, -0.866025, 0.475528, 0.154509, 0, 0.309017, -0.951057, -0.5, -0.823639, -0.267617), c1 = CFrame.new(0, -0.9, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Crystal", h = 5, a = 5, b = 11, c0 = CFrame.new(0, 0.18, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.495, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint2", h = 5, a = 5, b = 14, c0 = CFrame.new(0.2475, 0.0225, 0.428683, 0.866025, 0.475528, 0.154508, 0, 0.309017, -0.951057, -0.5, 0.823639, 0.267617), c1 = CFrame.new(0, -0.9, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint4", h = 5, a = 5, b = 20, c0 = CFrame.new(-0.116469, 0.225, -0.434667, -0.965926, -0.105271, -0.236443, 0, 0.913545, -0.406737, 0.258819, -0.392877, -0.882417), c1 = CFrame.new(0, -0.719999, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint2", h = 5, a = 5, b = 23, c0 = CFrame.new(0.434667, 0.225, 0.116469, 0.258819, 0.392877, 0.882417, 0, 0.913545, -0.406737, -0.965926, 0.105271, 0.236443), c1 = CFrame.new(0, -0.72, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint10", h = 5, a = 5, b = 26, c0 = CFrame.new(-0.495, 0.0225, 0, 0, -0.951057, -0.309017, 0, 0.309017, -0.951057, 1, 0, 0), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint7", h = 5, a = 5, b = 28, c0 = CFrame.new(0, 0.0225, -0.495, -1, 0, 0, 0, 0.309017, -0.951057, 0, -0.951057, -0.309017), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint8", h = 5, a = 5, b = 29, c0 = CFrame.new(-0.2475, 0.0225, -0.428683, -0.866025, -0.475528, -0.154508, 0, 0.309017, -0.951057, 0.5, -0.823639, -0.267617), c1 = CFrame.new(0, -0.9, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint6", h = 5, a = 5, b = 31, c0 = CFrame.new(-0.318198, 0.225, 0.318198, 0.707107, -0.287606, -0.645974, 0, 0.913545, -0.406737, 0.707107, 0.287606, 0.645974), c1 = CFrame.new(0, -0.720001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint3", h = 5, a = 5, b = 32, c0 = CFrame.new(0.428683, 0.0225, 0.2475, 0.5, 0.823639, 0.267617, 0, 0.309017, -0.951057, -0.866025, 0.475528, 0.154508), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint9", h = 5, a = 5, b = 37, c0 = CFrame.new(-0.428683, 0.0225, -0.2475, -0.5, -0.823639, -0.267617, 0, 0.309017, -0.951057, 0.866025, -0.475528, -0.154508), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint1", h = 5, a = 5, b = 42, c0 = CFrame.new(0.116469, 0.225, 0.434667, 0.965926, 0.105271, 0.236443, 0, 0.913545, -0.406737, -0.258819, 0.392877, 0.882417), c1 = CFrame.new(0, -0.719999, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint4", h = 5, a = 5, b = 44, c0 = CFrame.new(0.495, 0.0225, 0, 0, 0.951057, 0.309017, 0, 0.309017, -0.951057, -1, 0, 0), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint11", h = 5, a = 5, b = 47, c0 = CFrame.new(-0.428683, 0.0225, 0.2475, 0.5, -0.823639, -0.267617, 0, 0.309017, -0.951057, 0.866025, 0.475528, 0.154508), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint5", h = 5, a = 5, b = 56, c0 = CFrame.new(-0.434667, 0.225, -0.116469, -0.258819, -0.392877, -0.882417, 0, 0.913545, -0.406737, 0.965926, -0.105271, -0.236443), c1 = CFrame.new(0, -0.72, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint3", h = 5, a = 5, b = 57, c0 = CFrame.new(0.318198, 0.225, -0.318198, -0.707107, 0.287606, 0.645974, 0, 0.913545, -0.406737, -0.707107, -0.287606, -0.645974), c1 = CFrame.new(0, -0.720001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint5", h = 5, a = 5, b = 69, c0 = CFrame.new(0.428683, 0.0225, -0.2475, -0.5, 0.823639, 0.267617, 0, 0.309017, -0.951057, -0.866025, -0.475528, -0.154509), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint1", h = 5, a = 5, b = 70, c0 = CFrame.new(0, 0.0225, 0.495, 1, 0, 0, 0, 0.309017, -0.951057, 0, 0.951057, 0.309017), c1 = CFrame.new(0, -0.9, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow12Weld", h = 6, a = 6, b = 8, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip12Weld", h = 6, a = 6, b = 68, c0 = CFrame.new(0, 1.3725, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Blossom", h = 7, a = 7, b = 5, c0 = CFrame.new(0.128962, 0.754911, -0.054, 0.992546, 0.121869, 0, -0.121869, 0.992546, 0, 0, 0, 1), c1 = CFrame.new(0, -0.247499, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GoldRidge3_1Weld", h = 7, a = 7, b = 13, c0 = CFrame.new(-0.2475, 0, 0.405, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StemSeam3Weld", h = 7, a = 7, b = 62, c0 = CFrame.new(0, 0, -0.414, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GoldRidge3_2Weld", h = 7, a = 7, b = 95, c0 = CFrame.new(0.2475, 0, 0.405, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow6Weld", h = 9, a = 9, b = 10, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip6Weld", h = 9, a = 9, b = 50, c0 = CFrame.new(0, 1.3725, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrystalRib2Weld", h = 11, a = 11, b = 12, c0 = CFrame.new(-0.3375, -0.0675, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrystalRib4Weld", h = 11, a = 11, b = 19, c0 = CFrame.new(0, -0.0675, -0.3375, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CoronaJoint4", h = 11, a = 11, b = 24, c0 = CFrame.new(0, -0.09, -0.2925, -1, 0, 0, 0, 0.707107, -0.707107, 0, -0.707107, -0.707107), c1 = CFrame.new(0, -0.4725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CoronaJoint3", h = 11, a = 11, b = 33, c0 = CFrame.new(0.253312, -0.09, -0.14625, -0.5, 0.612372, 0.612372, 0, 0.707107, -0.707107, -0.866025, -0.353553, -0.353553), c1 = CFrame.new(0, -0.472501, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrystalRib1Weld", h = 11, a = 11, b = 40, c0 = CFrame.new(0.3375, -0.0675, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CoronaJoint5", h = 11, a = 11, b = 45, c0 = CFrame.new(-0.253312, -0.09, -0.14625, -0.5, -0.612372, -0.612372, 0, 0.707107, -0.707107, 0.866025, -0.353553, -0.353553), c1 = CFrame.new(0, -0.4725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrystalRib3Weld", h = 11, a = 11, b = 51, c0 = CFrame.new(0, -0.0675, 0.3375, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrystalTipWeld", h = 11, a = 11, b = 52, c0 = CFrame.new(0, 0.8775, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CoronaJoint6", h = 11, a = 11, b = 75, c0 = CFrame.new(-0.253312, -0.09, 0.14625, 0.5, -0.612372, -0.612372, 0, 0.707107, -0.707107, 0.866025, 0.353553, 0.353553), c1 = CFrame.new(0, -0.4725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CoronaJoint2", h = 11, a = 11, b = 88, c0 = CFrame.new(0.253312, -0.09, 0.14625, 0.5, 0.612372, 0.612372, 0, 0.707107, -0.707107, -0.866025, 0.353553, 0.353553), c1 = CFrame.new(0, -0.4725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CoronaJoint1", h = 11, a = 11, b = 93, c0 = CFrame.new(0, -0.09, 0.2925, 1, 0, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107), c1 = CFrame.new(0, -0.4725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow2Weld", h = 14, a = 14, b = 15, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip2Weld", h = 14, a = 14, b = 83, c0 = CFrame.new(0, 1.3725, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle2", h = 16, a = 16, b = 18, c0 = CFrame.new(0.029824, 0.10711, -1.05362, 0.478407, -0.120499, 0.869831, 0.763255, -0.432769, -0.479743, 0.434244, 0.893416, -0.115068), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee2", h = 17, a = 17, b = 16, c0 = CFrame.new(0, -0.820169, -0.975253, 1, 0, 0, 0, 0.171475, 0.985189, 0, -0.985188, 0.171475), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe2Weld", h = 18, a = 18, b = 41, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip4Weld", h = 20, a = 20, b = 21, c0 = CFrame.new(0, 1.125, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow4Weld", h = 20, a = 20, b = 25, c0 = CFrame.new(0, 0, 0.225, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow2Weld", h = 23, a = 23, b = 22, c0 = CFrame.new(0, 0, 0.225, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip2Weld", h = 23, a = 23, b = 92, c0 = CFrame.new(0, 1.125, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow10Weld", h = 26, a = 26, b = 27, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip10Weld", h = 26, a = 26, b = 87, c0 = CFrame.new(0, 1.3725, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow7Weld", h = 28, a = 28, b = 36, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip7Weld", h = 28, a = 28, b = 81, c0 = CFrame.new(0, 1.3725, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow8Weld", h = 29, a = 29, b = 30, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip8Weld", h = 29, a = 29, b = 74, c0 = CFrame.new(0, 1.3725, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip6Weld", h = 31, a = 31, b = 46, c0 = CFrame.new(0, 1.124999, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow6Weld", h = 31, a = 31, b = 60, c0 = CFrame.new(0, -0.000001, 0.225, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip3Weld", h = 32, a = 32, b = 86, c0 = CFrame.new(0, 1.3725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow3Weld", h = 32, a = 32, b = 94, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle1", h = 34, a = 34, b = 73, c0 = CFrame.new(-0.029824, 0.10711, -1.05362, 0.478407, 0.120499, -0.869831, -0.763255, -0.432769, -0.479743, -0.434244, 0.893416, -0.115068), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee1", h = 35, a = 35, b = 34, c0 = CFrame.new(0, -0.820169, -0.975253, 1, 0, 0, 0, 0.171475, 0.985189, 0, -0.985188, 0.171475), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip9Weld", h = 37, a = 37, b = 38, c0 = CFrame.new(0, 1.3725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow9Weld", h = 37, a = 37, b = 90, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow1Weld", h = 42, a = 42, b = 43, c0 = CFrame.new(0, 0, 0.224999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip1Weld", h = 42, a = 42, b = 53, c0 = CFrame.new(0, 1.125, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip4Weld", h = 44, a = 44, b = 59, c0 = CFrame.new(0, 1.3725, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow4Weld", h = 44, a = 44, b = 61, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip11Weld", h = 47, a = 47, b = 48, c0 = CFrame.new(0, 1.3725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow11Weld", h = 47, a = 47, b = 80, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow5Weld", h = 56, a = 56, b = 55, c0 = CFrame.new(0, 0, 0.225, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip5Weld", h = 56, a = 56, b = 67, c0 = CFrame.new(0, 1.125, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip3Weld", h = 57, a = 57, b = 58, c0 = CFrame.new(0, 1.124999, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow3Weld", h = 57, a = 57, b = 72, c0 = CFrame.new(0, -0.000001, 0.225, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle3", h = 63, a = 63, b = 66, c0 = CFrame.new(0.002188, 0.125443, -1.045844, -0.4819, -0.008842, -0.876182, -0.753164, -0.506839, 0.419355, -0.447791, 0.861995, 0.237586), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee3", h = 65, a = 65, b = 63, c0 = CFrame.new(0, -0.825922, -0.936943, 1, 0, 0, 0, 0.125456, 0.992099, 0, -0.992099, 0.125456), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe3Weld", h = 66, a = 66, b = 64, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow5Weld", h = 69, a = 69, b = 89, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip5Weld", h = 69, a = 69, b = 96, c0 = CFrame.new(0, 1.3725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow1Weld", h = 70, a = 70, b = 71, c0 = CFrame.new(0, 0, 0.247501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip1Weld", h = 70, a = 70, b = 82, c0 = CFrame.new(0, 1.3725, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe1Weld", h = 73, a = 73, b = 84, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle4", h = 76, a = 76, b = 78, c0 = CFrame.new(-0.002188, 0.125443, -1.045844, -0.4819, 0.008842, 0.876182, 0.753164, -0.506839, 0.419355, 0.447791, 0.861995, 0.237586), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe4Weld", h = 78, a = 78, b = 77, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
