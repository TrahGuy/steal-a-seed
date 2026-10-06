--!strict
--==============================================================================
-- PLANT FORM: Cinderpaw (Emberroot)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Emberroot/Cinderpaw" by a read-only generator on 2026-10-03. The original
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
	Source = "Emberroot/Cinderpaw", Kind = "plant", Yaw = 0,
	Size = Vector3.new(2.992499, 5.453444, 6.575697), Height = 5.453444, PartCount = 58,
	Base = 1,
	Unit = 3.5, ModelScale = 1,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(0.875, 0.14, 0.875), cf = CFrame.new(0, 0.07, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(22, 18, 17), m = Enum.Material.Plastic, t = 1, cs = false }, -- 1
		{ n = "UpperLegBackL", s = "Block", z = Vector3.new(0.595, 0.595, 0.727882), cf = CFrame.new(0.93625, 1.33, 1.356251, -0.613941, 0.759115, -0.216381, 0, 0.274125, 0.961694, 0.789352, 0.590423, -0.168297), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 2
		{ n = "Body", s = "Block", z = Vector3.new(2.17, 1.505, 2.905), cf = CFrame.new(0, 1.995, 0.245001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 3
		{ n = "ShinBackL", s = "Block", z = Vector3.new(0.49, 0.49, 0.566525), cf = CFrame.new(1.0325, 0.7175, 1.3125, 0.986394, 0.152349, -0.06178, 0, 0.375794, 0.926703, 0.164399, -0.914094, 0.370681), c = Color3.fromRGB(164, 65, 24), m = Enum.Material.Plastic }, -- 4
		{ n = "TwigWhiskerR", s = "Block", z = Vector3.new(0.07, 0.07, 0.790132), cf = CFrame.new(-0.98, 2.9925, -2.988998, -0.036339, 0.221335, 0.97452, 0, 0.975164, -0.221482, -0.999339, -0.008048, -0.035437), c = Color3.fromRGB(81, 65, 55), m = Enum.Material.Plastic }, -- 5
		{ n = "Head", s = "Block", z = Vector3.new(2.38, 1.925, 1.785), cf = CFrame.new(0, 3.29, -1.714998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 6
		{ n = "MuzzleR", s = "Block", z = Vector3.new(0.7, 0.49, 0.5075), cf = CFrame.new(-0.3395, 2.905, -2.719498, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(81, 65, 55), m = Enum.Material.Plastic }, -- 7
		{ n = "Belly", s = "Block", z = Vector3.new(1.715, 0.315, 2.31), cf = CFrame.new(0, 1.26, 0.245001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(57, 47, 42), m = Enum.Material.Plastic }, -- 8
		{ n = "ShinFrontL", s = "Block", z = Vector3.new(0.49, 0.49, 0.566525), cf = CFrame.new(1.0325, 0.7175, -0.805, 0.986394, 0.152349, -0.06178, 0, 0.375794, 0.926703, 0.164399, -0.914094, 0.370681), c = Color3.fromRGB(164, 65, 24), m = Enum.Material.Plastic }, -- 9
		{ n = "UpperLegFrontL", s = "Block", z = Vector3.new(0.595, 0.595, 0.727882), cf = CFrame.new(0.93625, 1.33, -0.76125, -0.61394, 0.759115, -0.216381, 0, 0.274125, 0.961694, 0.789352, 0.590423, -0.168296), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 10
		{ n = "PawFrontL", s = "Block", z = Vector3.new(0.8925, 0.42, 1.015), cf = CFrame.new(1.05, 0.21, -1.085001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(215, 87, 25), m = Enum.Material.Plastic }, -- 11
		{ n = "BudStem", s = "Block", z = Vector3.new(0.385, 0.875, 0.385), cf = CFrame.new(0, 2.9925, 0.560001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(164, 65, 24), m = Enum.Material.Plastic }, -- 12
		{ n = "UpperLegBackR", s = "Block", z = Vector3.new(0.595, 0.595, 0.727882), cf = CFrame.new(-0.93625, 1.33, 1.356251, -0.613941, -0.759115, 0.216381, 0, 0.274125, 0.961694, -0.789352, 0.590423, -0.168297), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 13
		{ n = "PupilR", s = "Block", z = Vector3.new(0.0875, 0.378, 0.042), cf = CFrame.new(-0.6545, 3.5175, -2.701998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(22, 18, 17), m = Enum.Material.SmoothPlastic, st = false, a = { Blink = true } }, -- 14
		{ n = "BudHeart", s = "Block", z = Vector3.new(0.7, 1.085, 0.7), cf = CFrame.new(0, 3.7275, 0.560001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 15
		{ n = "ChestLeafL", s = "Wedge", z = Vector3.new(0.665, 0.91, 0.315), cf = CFrame.new(0.35, 1.96, -1.259998, 0.951057, 0.309017, 0, -0.302264, 0.930274, 0.207912, 0.064248, -0.197736, 0.978148), c = Color3.fromRGB(164, 65, 24), m = Enum.Material.Plastic }, -- 16
		{ n = "ChestLeafR", s = "Wedge", z = Vector3.new(0.665, 0.91, 0.315), cf = CFrame.new(-0.35, 1.96, -1.259998, 0.951057, -0.309017, 0, 0.302264, 0.930274, 0.207912, -0.064248, -0.197736, 0.978148), c = Color3.fromRGB(164, 65, 24), m = Enum.Material.Plastic }, -- 17
		{ n = "ShinFrontR", s = "Block", z = Vector3.new(0.49, 0.49, 0.566525), cf = CFrame.new(-1.0325, 0.7175, -0.805, 0.986394, -0.152349, 0.06178, 0, 0.375794, 0.926703, -0.164399, -0.914094, 0.370681), c = Color3.fromRGB(164, 65, 24), m = Enum.Material.Plastic }, -- 18
		{ n = "ToeEmberFrontR1", s = "Block", z = Vector3.new(0.196, 0.175, 0.063), cf = CFrame.new(-1.2565, 0.224, -1.624001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 19
		{ n = "UpperLegFrontR", s = "Block", z = Vector3.new(0.595, 0.595, 0.727882), cf = CFrame.new(-0.93625, 1.33, -0.76125, -0.61394, -0.759115, 0.216381, 0, 0.274125, 0.961694, -0.789352, 0.590423, -0.168296), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 20
		{ n = "PawFrontR", s = "Block", z = Vector3.new(0.8925, 0.42, 1.015), cf = CFrame.new(-1.05, 0.21, -1.085001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(215, 87, 25), m = Enum.Material.Plastic }, -- 21
		{ n = "PawBackR", s = "Block", z = Vector3.new(0.8925, 0.42, 1.015), cf = CFrame.new(-1.05, 0.21, 1.032499, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(215, 87, 25), m = Enum.Material.Plastic }, -- 22
		{ n = "ShinBackR", s = "Block", z = Vector3.new(0.49, 0.49, 0.566525), cf = CFrame.new(-1.0325, 0.7175, 1.3125, 0.986394, -0.152349, 0.06178, 0, 0.375794, 0.926703, -0.164399, -0.914094, 0.370681), c = Color3.fromRGB(164, 65, 24), m = Enum.Material.Plastic }, -- 23
		{ n = "PawBackL", s = "Block", z = Vector3.new(0.8925, 0.42, 1.015), cf = CFrame.new(1.05, 0.21, 1.032499, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(215, 87, 25), m = Enum.Material.Plastic }, -- 24
		{ n = "ToeEmberBackL1", s = "Block", z = Vector3.new(0.196, 0.175, 0.063), cf = CFrame.new(0.8435, 0.224, 0.4935, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 25
		{ n = "BudSepal4", s = "Wedge", z = Vector3.new(0.735, 1.12, 0.455), cf = CFrame.new(-0.3675, 3.762501, 0.560001, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(57, 47, 42), m = Enum.Material.Plastic }, -- 26
		{ n = "ToeEmberBackR2", s = "Block", z = Vector3.new(0.196, 0.175, 0.063), cf = CFrame.new(-0.8435, 0.224, 0.4935, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 27
		{ n = "ToeEmberFrontL2", s = "Block", z = Vector3.new(0.196, 0.175, 0.063), cf = CFrame.new(1.2565, 0.224, -1.624001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 28
		{ n = "BudSepal1", s = "Wedge", z = Vector3.new(0.735, 1.12, 0.455), cf = CFrame.new(0, 3.762501, 0.927502, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 29
		{ n = "LeafEarR", s = "Wedge", z = Vector3.new(0.35, 1.33, 0.42), cf = CFrame.new(-1.127286, 4.675044, -1.709642, 0, -0.173648, 0.984808, -0.104528, 0.979413, 0.172697, -0.994522, -0.10294, -0.018151), c = Color3.fromRGB(57, 47, 42), m = Enum.Material.Plastic }, -- 30
		{ n = "LeafEarHalfR", s = "Wedge", z = Vector3.new(0.35, 1.33, 0.42), cf = CFrame.new(-0.713667, 4.747576, -1.717266, 0, -0.173648, -0.984808, 0.104528, 0.979413, -0.172697, 0.994522, -0.10294, 0.018151), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 31
		{ n = "EyeR", s = "Block", z = Vector3.new(0.4725, 0.5075, 0.077), cf = CFrame.new(-0.6545, 3.5175, -2.638998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 182, 65), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 32
		{ n = "ToeEmberFrontL1", s = "Block", z = Vector3.new(0.196, 0.175, 0.063), cf = CFrame.new(0.8435, 0.224, -1.624001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 33
		{ n = "BarkPlateL", s = "Block", z = Vector3.new(0.1925, 0.875, 1.575), cf = CFrame.new(1.127, 2.1, 0.42, 0.994522, 0.104528, 0, -0.103511, 0.984843, 0.139173, 0.014548, -0.138411, 0.990268), c = Color3.fromRGB(57, 47, 42), m = Enum.Material.Plastic }, -- 34
		{ n = "MuzzleL", s = "Block", z = Vector3.new(0.7, 0.49, 0.5075), cf = CFrame.new(0.3395, 2.905, -2.719498, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(81, 65, 55), m = Enum.Material.Plastic }, -- 35
		{ n = "BarkPlateR", s = "Block", z = Vector3.new(0.1925, 0.875, 1.575), cf = CFrame.new(-1.127, 2.1, 0.42, 0.994522, -0.104528, 0, 0.103511, 0.984843, 0.139173, -0.014548, -0.138411, 0.990268), c = Color3.fromRGB(57, 47, 42), m = Enum.Material.Plastic }, -- 36
		{ n = "ToeEmberBackL2", s = "Block", z = Vector3.new(0.196, 0.175, 0.063), cf = CFrame.new(1.2565, 0.224, 0.4935, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 37
		{ n = "PupilL", s = "Block", z = Vector3.new(0.0875, 0.378, 0.042), cf = CFrame.new(0.6545, 3.5175, -2.701998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(22, 18, 17), m = Enum.Material.SmoothPlastic, st = false, a = { Blink = true } }, -- 38
		{ n = "AmberCrackL", s = "Block", z = Vector3.new(0.063, 0.049, 0.720056), cf = CFrame.new(1.2425, 2.1175, 0.13125, -1, 0, 0, 0, 0.899235, -0.437465, 0, -0.437465, -0.899235), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 39
		{ n = "EarVeinR", s = "Block", z = Vector3.new(0.0875, 0.875, 0.0525), cf = CFrame.new(-0.902243, 4.587252, -1.904533, 0.984808, -0.173648, 0, 0.172697, 0.979413, 0.104528, -0.018151, -0.10294, 0.994522), c = Color3.fromRGB(215, 87, 25), m = Enum.Material.Plastic }, -- 40
		{ n = "TailLeaf", s = "Wedge", z = Vector3.new(0.63, 0.7, 0.245), cf = CFrame.new(0, 3.762501, 3.244501, 0.951056, -0.309017, 0, 0.293893, 0.904508, -0.309017, 0.095492, 0.293893, 0.951056), c = Color3.fromRGB(164, 65, 24), m = Enum.Material.Plastic }, -- 41
		{ n = "TailTwig", s = "Block", z = Vector3.new(0.273, 0.273, 1.26872), cf = CFrame.new(0, 2.9575, 2.922501, -1, 0, 0, 0, 0.413803, -0.910367, 0, -0.910366, -0.413803), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 42
		{ n = "TailStem", s = "Block", z = Vector3.new(0.3675, 0.3675, 1.163454), cf = CFrame.new(0, 2.17, 2.1175, -1, 0, 0, 0, 0.932568, -0.360994, 0, -0.360994, -0.932568), c = Color3.fromRGB(57, 47, 42), m = Enum.Material.Plastic }, -- 43
		{ n = "BudSepal3", s = "Wedge", z = Vector3.new(0.735, 1.12, 0.455), cf = CFrame.new(0, 3.762501, 0.192501, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 44
		{ n = "BudSepal2", s = "Wedge", z = Vector3.new(0.735, 1.12, 0.455), cf = CFrame.new(0.3675, 3.762501, 0.560001, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(57, 47, 42), m = Enum.Material.Plastic }, -- 45
		{ n = "ToeEmberBackR1", s = "Block", z = Vector3.new(0.196, 0.175, 0.063), cf = CFrame.new(-1.2565, 0.224, 0.4935, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 46
		{ n = "BudEmber", s = "Block", z = Vector3.new(0.2975, 0.42, 0.2975), cf = CFrame.new(0, 4.3925, 0.560001, 0.691655, -0.147016, 0.707107, -0.015997, 0.975704, 0.218508, -0.722051, -0.162444, 0.672499), c = Color3.fromRGB(255, 182, 65), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.713726, 0.254902), HotColor = Color3.new(1, 0.87451, 0.537255) } }, -- 47
		{ n = "EyeShineR", s = "Block", z = Vector3.new(0.098, 0.112, 0.042), cf = CFrame.new(-0.5985, 3.6505, -2.747498, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 223, 137), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 48
		{ n = "AmberCrackR", s = "Block", z = Vector3.new(0.063, 0.049, 0.720056), cf = CFrame.new(-1.2425, 2.1175, 0.13125, -1, 0, 0, 0, 0.899235, -0.437465, 0, -0.437465, -0.899235), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 49
		{ n = "EyeShineL", s = "Block", z = Vector3.new(0.098, 0.112, 0.042), cf = CFrame.new(0.5985, 3.6505, -2.747498, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 223, 137), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 50
		{ n = "EyeL", s = "Block", z = Vector3.new(0.4725, 0.5075, 0.077), cf = CFrame.new(0.6545, 3.5175, -2.638998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 182, 65), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 51
		{ n = "EarVeinL", s = "Block", z = Vector3.new(0.0875, 0.875, 0.0525), cf = CFrame.new(0.902243, 4.587252, -1.904533, 0.984808, 0.173648, 0, -0.172697, 0.979413, 0.104528, 0.018151, -0.10294, 0.994522), c = Color3.fromRGB(215, 87, 25), m = Enum.Material.Plastic }, -- 52
		{ n = "LeafEarL", s = "Wedge", z = Vector3.new(0.35, 1.33, 0.42), cf = CFrame.new(0.713666, 4.747576, -1.717266, 0, 0.173648, 0.984808, -0.104528, 0.979413, -0.172697, -0.994522, -0.10294, 0.018151), c = Color3.fromRGB(57, 47, 42), m = Enum.Material.Plastic }, -- 53
		{ n = "Nose", s = "Block", z = Vector3.new(0.28, 0.21, 0.1225), cf = CFrame.new(0, 3.0695, -3.020498, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(164, 65, 24), m = Enum.Material.Plastic }, -- 54
		{ n = "TwigWhiskerL", s = "Block", z = Vector3.new(0.07, 0.07, 0.790132), cf = CFrame.new(0.98, 2.9925, -2.988998, -0.036339, -0.221335, -0.97452, 0, 0.975164, -0.221482, 0.999339, -0.008048, -0.035437), c = Color3.fromRGB(81, 65, 55), m = Enum.Material.Plastic }, -- 55
		{ n = "Mouth", s = "Block", z = Vector3.new(0.0875, 0.168, 0.0525), cf = CFrame.new(0, 2.821, -3.002998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(22, 18, 17), m = Enum.Material.SmoothPlastic, st = false }, -- 56
		{ n = "LeafEarHalfL", s = "Wedge", z = Vector3.new(0.35, 1.33, 0.42), cf = CFrame.new(1.127285, 4.675044, -1.709642, 0, 0.173648, -0.984808, 0.104528, 0.979413, 0.172697, 0.994522, -0.10294, -0.018151), c = Color3.fromRGB(39, 35, 33), m = Enum.Material.Plastic }, -- 57
		{ n = "ToeEmberFrontR2", s = "Block", z = Vector3.new(0.196, 0.175, 0.063), cf = CFrame.new(-0.8435, 0.224, -1.624001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 32), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.501961, 0.12549), HotColor = Color3.new(1, 0.713726, 0.254902) } }, -- 58
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 3, c0 = CFrame.new(0, 1.855, 0.245, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.07, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeBackL", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 0, -0.363941, -0.613941, 0, 0.789352, 0.759115, 0.274125, 0.590423, -0.216381, 0.961694, -0.168297), c1 = CFrame.new(0, 0, 0.283262, 0.986394, 0, 0.164399, 0.152349, 0.375794, -0.914094, -0.06178, 0.926703, 0.370681) },
		{ k = "Motor6D", n = "HipBackL", h = 3, a = 3, b = 2, c0 = CFrame.new(0.8575, -0.315, 1.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.363941, -0.613941, 0, 0.789352, 0.759115, 0.274125, 0.590423, -0.216381, 0.961694, -0.168297) },
		{ k = "Motor6D", n = "Neck", h = 3, a = 3, b = 6, c0 = CFrame.new(0, 0.56, -1.295, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.735, 0.665, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Belly", h = 3, a = 3, b = 8, c0 = CFrame.new(0, -0.735, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipFrontL", h = 3, a = 3, b = 10, c0 = CFrame.new(0.8575, -0.315, -1.0675, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.363941, -0.61394, 0, 0.789352, 0.759115, 0.274125, 0.590423, -0.216381, 0.961694, -0.168296) },
		{ k = "Motor6D", n = "Bud", h = 3, a = 3, b = 12, c0 = CFrame.new(0, 0.7, 0.315, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.2975, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipBackR", h = 3, a = 3, b = 13, c0 = CFrame.new(-0.8575, -0.315, 1.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.363941, -0.613941, 0, -0.789352, -0.759115, 0.274125, 0.590423, 0.216381, 0.961694, -0.168297) },
		{ k = "Weld", n = "Hold_ChestLeafL", h = 3, a = 3, b = 16, c0 = CFrame.new(0.35, -0.035, -1.505, 0.951057, 0.309017, 0, -0.302264, 0.930274, 0.207912, 0.064248, -0.197736, 0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ChestLeafR", h = 3, a = 3, b = 17, c0 = CFrame.new(-0.35, -0.035, -1.505, 0.951057, -0.309017, 0, 0.302264, 0.930274, 0.207912, -0.064248, -0.197736, 0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipFrontR", h = 3, a = 3, b = 20, c0 = CFrame.new(-0.8575, -0.315, -1.0675, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.363941, -0.61394, 0, -0.789352, -0.759115, 0.274125, 0.590423, 0.216381, 0.961694, -0.168296) },
		{ k = "Weld", n = "Hold_BarkPlateL", h = 3, a = 3, b = 34, c0 = CFrame.new(1.127, 0.105, 0.175, 0.994522, 0.104528, 0, -0.103511, 0.984843, 0.139173, 0.014548, -0.138411, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BarkPlateR", h = 3, a = 3, b = 36, c0 = CFrame.new(-1.127, 0.105, 0.175, 0.994522, -0.104528, 0, 0.103511, 0.984843, 0.139173, -0.014548, -0.138411, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AmberCrackL", h = 3, a = 3, b = 39, c0 = CFrame.new(1.2425, 0.1225, -0.11375, -1, 0, 0, 0, 0.899235, -0.437465, 0, -0.437465, -0.899235), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail1", h = 3, a = 3, b = 43, c0 = CFrame.new(0, -0.035, 1.33, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.581727, -1, 0, 0, 0, 0.932568, -0.360994, 0, -0.360994, -0.932568) },
		{ k = "Weld", n = "Hold_AmberCrackR", h = 3, a = 3, b = 49, c0 = CFrame.new(-1.2425, 0.1225, -0.11375, -1, 0, 0, 0, 0.899235, -0.437465, 0, -0.437465, -0.899235), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AnkleBackL", h = 4, a = 4, b = 24, c0 = CFrame.new(0, 0, -0.283262, 0.986394, 0, 0.164399, 0.152349, 0.375794, -0.914094, -0.06178, 0.926703, 0.370681), c1 = CFrame.new(0, 0.245, 0.175, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_TwigWhiskerR", h = 6, a = 6, b = 5, c0 = CFrame.new(-0.98, -0.2975, -1.274, -0.036339, 0.221335, 0.97452, 0, 0.975164, -0.221482, -0.999339, -0.008048, -0.035437), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MuzzleR", h = 6, a = 6, b = 7, c0 = CFrame.new(-0.3395, -0.385, -1.0045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PupilR", h = 6, a = 6, b = 14, c0 = CFrame.new(-0.6545, 0.2275, -0.987, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "EarR", h = 6, a = 6, b = 30, c0 = CFrame.new(-0.805, 0.77, 0.07, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.665, 0.21, 0, -0.104528, -0.994522, -0.173648, 0.979413, -0.10294, 0.984808, 0.172697, -0.018151) },
		{ k = "Weld", n = "Hold_EyeR", h = 6, a = 6, b = 32, c0 = CFrame.new(-0.6545, 0.2275, -0.924, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MuzzleL", h = 6, a = 6, b = 35, c0 = CFrame.new(0.3395, -0.385, -1.0045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PupilL", h = 6, a = 6, b = 38, c0 = CFrame.new(0.6545, 0.2275, -0.987, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShineR", h = 6, a = 6, b = 48, c0 = CFrame.new(-0.5985, 0.3605, -1.0325, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShineL", h = 6, a = 6, b = 50, c0 = CFrame.new(0.5985, 0.3605, -1.0325, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeL", h = 6, a = 6, b = 51, c0 = CFrame.new(0.6545, 0.2275, -0.924, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "EarL", h = 6, a = 6, b = 53, c0 = CFrame.new(0.805, 0.77, 0.07, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.665, 0.21, 0, -0.104528, -0.994522, 0.173648, 0.979413, -0.10294, 0.984808, -0.172697, 0.018151) },
		{ k = "Weld", n = "Hold_Nose", h = 6, a = 6, b = 54, c0 = CFrame.new(0, -0.2205, -1.3055, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_TwigWhiskerL", h = 6, a = 6, b = 55, c0 = CFrame.new(0.98, -0.2975, -1.274, -0.036339, -0.221335, -0.97452, 0, 0.975164, -0.221482, 0.999339, -0.008048, -0.035437), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Mouth", h = 6, a = 6, b = 56, c0 = CFrame.new(0, -0.469, -1.288, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AnkleFrontL", h = 9, a = 9, b = 11, c0 = CFrame.new(0, 0, -0.283262, 0.986394, 0, 0.164399, 0.152349, 0.375794, -0.914094, -0.06178, 0.926703, 0.370681), c1 = CFrame.new(0, 0.245, 0.175, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeFrontL", h = 10, a = 10, b = 9, c0 = CFrame.new(0, 0, -0.363941, -0.61394, 0, 0.789352, 0.759115, 0.274125, 0.590423, -0.216381, 0.961694, -0.168296), c1 = CFrame.new(0, 0, 0.283262, 0.986394, 0, 0.164399, 0.152349, 0.375794, -0.914094, -0.06178, 0.926703, 0.370681) },
		{ k = "Weld", n = "Hold_ToeEmberFrontL2", h = 11, a = 11, b = 28, c0 = CFrame.new(0.2065, 0.014, -0.539, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ToeEmberFrontL1", h = 11, a = 11, b = 33, c0 = CFrame.new(-0.2065, 0.014, -0.539, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BudHeart", h = 12, a = 12, b = 15, c0 = CFrame.new(0, 0.735, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Sepal4", h = 12, a = 12, b = 26, c0 = CFrame.new(-0.3675, 0.21, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.56, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0) },
		{ k = "Motor6D", n = "Sepal1", h = 12, a = 12, b = 29, c0 = CFrame.new(0, 0.21, 0.3675, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.56, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Sepal3", h = 12, a = 12, b = 44, c0 = CFrame.new(0, 0.21, -0.3675, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.56, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1) },
		{ k = "Motor6D", n = "Sepal2", h = 12, a = 12, b = 45, c0 = CFrame.new(0.3675, 0.21, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.56, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
		{ k = "Weld", n = "Hold_BudEmber", h = 12, a = 12, b = 47, c0 = CFrame.new(0, 1.4, 0, 0.691655, -0.147016, 0.707107, -0.015997, 0.975704, 0.218508, -0.722051, -0.162444, 0.672499), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeBackR", h = 13, a = 13, b = 23, c0 = CFrame.new(0, 0, -0.363941, -0.613941, 0, -0.789352, -0.759115, 0.274125, 0.590423, 0.216381, 0.961694, -0.168297), c1 = CFrame.new(0, 0, 0.283262, 0.986394, 0, -0.164399, -0.152349, 0.375794, -0.914094, 0.06178, 0.926703, 0.370681) },
		{ k = "Motor6D", n = "AnkleFrontR", h = 18, a = 18, b = 21, c0 = CFrame.new(0, 0, -0.283262, 0.986394, 0, -0.164399, -0.152349, 0.375794, -0.914094, 0.06178, 0.926703, 0.370681), c1 = CFrame.new(0, 0.245, 0.175, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeFrontR", h = 20, a = 20, b = 18, c0 = CFrame.new(0, 0, -0.363941, -0.61394, 0, -0.789352, -0.759115, 0.274125, 0.590423, 0.216381, 0.961694, -0.168296), c1 = CFrame.new(0, 0, 0.283262, 0.986394, 0, -0.164399, -0.152349, 0.375794, -0.914094, 0.06178, 0.926703, 0.370681) },
		{ k = "Weld", n = "Hold_ToeEmberFrontR1", h = 21, a = 21, b = 19, c0 = CFrame.new(-0.2065, 0.014, -0.539, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ToeEmberFrontR2", h = 21, a = 21, b = 58, c0 = CFrame.new(0.2065, 0.014, -0.539, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ToeEmberBackR2", h = 22, a = 22, b = 27, c0 = CFrame.new(0.2065, 0.014, -0.539, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ToeEmberBackR1", h = 22, a = 22, b = 46, c0 = CFrame.new(-0.2065, 0.014, -0.539, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AnkleBackR", h = 23, a = 23, b = 22, c0 = CFrame.new(0, 0, -0.283262, 0.986394, 0, -0.164399, -0.152349, 0.375794, -0.914094, 0.06178, 0.926703, 0.370681), c1 = CFrame.new(0, 0.245, 0.175, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ToeEmberBackL1", h = 24, a = 24, b = 25, c0 = CFrame.new(-0.2065, 0.014, -0.539, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ToeEmberBackL2", h = 24, a = 24, b = 37, c0 = CFrame.new(0.2065, 0.014, -0.539, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafEarHalfR", h = 30, a = 30, b = 31, c0 = CFrame.new(0, 0, 0.42, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EarVeinR", h = 30, a = 30, b = 40, c0 = CFrame.new(0.203, -0.105, 0.21, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_TailLeaf", h = 42, a = 42, b = 41, c0 = CFrame.new(0, 0.039974, -0.86609, -0.951056, 0.309017, 0, 0.034681, 0.106738, -0.993682, -0.307065, -0.945048, -0.112231), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail2", h = 43, a = 43, b = 42, c0 = CFrame.new(0, 0, -0.581727, -1, 0, 0, 0, 0.932568, -0.360994, 0, -0.360994, -0.932568), c1 = CFrame.new(0, 0, 0.63436, -1, 0, 0, 0, 0.413803, -0.910366, 0, -0.910366, -0.413803) },
		{ k = "Weld", n = "Hold_EarVeinL", h = 53, a = 53, b = 52, c0 = CFrame.new(0.203, -0.105, 0.21, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafEarHalfL", h = 53, a = 53, b = 57, c0 = CFrame.new(0, 0, 0.42, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
		{ n = "SmoulderTip", p = 15, cf = CFrame.new(0, 0.665, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Lights = {
		{ n = "BudLight", p = 15, range = 5.95, brightness = 0.65, color = Color3.new(1, 0.713726, 0.254902), shadows = false, enabled = true, a = { BaseBrightness = 0.65 } },
	},
	Emitters = {
		{ n = "BudSmoulder", at = 1, rate = 2, enabled = true, lifetime = NumberRange.new(0.8, 1.3), speed = NumberRange.new(0.21, 0.42), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.175, 0), NumberSequenceKeypoint.new(1, 0.525, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.82, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.317647, 0.254902, 0.215686)), ColorSequenceKeypoint.new(1, Color3.new(0.152941, 0.137255, 0.129412)) }), lightEmission = 0, lightInfluence = 0, texture = "rbxasset://textures/particles/smoke_main.dds", spread = Vector2.new(15, 15), acceleration = Vector3.new(0, 0.35, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(-15, 15), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
