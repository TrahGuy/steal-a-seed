--!strict
--==============================================================================
-- PLANT FORM: Bellchime (Greenhollow Plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Greenhollow Plants/Bellchime" by a read-only generator on 2026-10-03. The original
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
	Source = "Greenhollow Plants/Bellchime", Kind = "plant", Yaw = 0,
	Size = Vector3.new(4.544998, 6.3, 4.545), Height = 6.3, PartCount = 58,
	Base = 3,
	Unit = 4.5, ModelScale = 1,
	Attributes = {},
	Parts = {
		{ n = "Stem1", s = "Block", z = Vector3.new(0.63, 0.63, 1.755), cf = CFrame.new(0, 1.1025, 0, 1, 0, 0, 0, 0, -1, 0, 1, 0), c = Color3.fromRGB(69, 128, 137), m = Enum.Material.Plastic }, -- 1
		{ n = "CollarTip4", s = "Block", z = Vector3.new(0.4725, 0.4725, 0.1935), cf = CFrame.new(0, 3.478704, -1.401439, -0.707107, 0.707107, 0, -0.241845, -0.241845, -0.939692, -0.664463, -0.664463, 0.34202), c = Color3.fromRGB(250, 178, 211), m = Enum.Material.Plastic }, -- 2
		{ n = "Footing", s = "Block", z = Vector3.new(1.125, 0.18, 1.125), cf = CFrame.new(0, 0.09, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(45, 83, 112), m = Enum.Material.Plastic, t = 1, cs = false }, -- 3
		{ n = "Stem2", s = "Block", z = Vector3.new(0.4725, 0.4725, 3.735), cf = CFrame.new(0, 3.8475, 0, 1, 0, 0, 0, 0, -1, 0, 1, 0), c = Color3.fromRGB(94, 160, 165), m = Enum.Material.Plastic }, -- 4
		{ n = "CollarPetal4", s = "Block", z = Vector3.new(0.72, 0.81, 0.2025), cf = CFrame.new(0, 3.686482, -0.830576, -1, 0, 0, 0, -0.34202, -0.939693, 0, -0.939693, 0.34202), c = Color3.fromRGB(250, 178, 211), m = Enum.Material.Plastic }, -- 5
		{ n = "RootLeafL", s = "Wedge", z = Vector3.new(0.72, 0.36, 1.53), cf = CFrame.new(0.3825, 0.18, 0.225, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c = Color3.fromRGB(103, 174, 171), m = Enum.Material.Plastic }, -- 6
		{ n = "FacePlate", s = "Block", z = Vector3.new(1.1025, 0.72, 0.18), cf = CFrame.new(0, 5.4225, -1.1115, 1, 0, 0, 0, 0.848048, -0.529919, 0, 0.529919, 0.848048), c = Color3.fromRGB(218, 235, 250), m = Enum.Material.Plastic }, -- 7
		{ n = "EyeShineL", s = "Block", z = Vector3.new(0.063, 0.063, 0.036), cf = CFrame.new(0.27, 5.598026, -1.214071, 1, 0, 0, 0, 0.848048, -0.529919, 0, 0.529919, 0.848048), c = Color3.fromRGB(231, 249, 255), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 8
		{ n = "Head", s = "Ball", z = Vector3.new(1.395, 0.72, 1.395), cf = CFrame.new(0, 5.94, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(165, 207, 237), m = Enum.Material.Plastic }, -- 9
		{ n = "HandPointRR", s = "Wedge", z = Vector3.new(0.1935, 0.72, 0.3825), cf = CFrame.new(-1.86277, 1.08872, -0.09, 0, -0.173648, 0.984808, 0, -0.984808, -0.173648, 1, 0, 0), c = Color3.fromRGB(147, 206, 193), m = Enum.Material.Plastic }, -- 10
		{ n = "LeafHandR", s = "Block", z = Vector3.new(0.765, 0.99, 0.2025), cf = CFrame.new(-1.525955, 1.89752, -0.09, -0.984808, -0.173648, 0, 0.173648, -0.984808, 0, 0, 0, 1), c = Color3.fromRGB(103, 174, 171), m = Enum.Material.Plastic }, -- 11
		{ n = "ArmStemR", s = "Block", z = Vector3.new(0.2475, 0.2475, 1.516206), cf = CFrame.new(-0.93375, 2.9475, -0.045, 0.08854, -0.739069, 0.667785, 0, 0.670418, 0.741983, -0.996073, -0.065695, 0.059359), c = Color3.fromRGB(69, 128, 137), m = Enum.Material.Plastic }, -- 12
		{ n = "BellFlare8", s = "Block", z = Vector3.new(1.53, 0.2475, 1.337946), cf = CFrame.new(-1.145515, 4.5, 1.145513, -0.707107, -0.523217, 0.475652, 0, 0.672673, 0.73994, -0.707107, 0.523217, -0.475652), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 13
		{ n = "BellUpper8", s = "Block", z = Vector3.new(0.945, 0.2475, 1.111418), cf = CFrame.new(-0.620487, 5.4675, 0.620486, -0.707107, -0.601228, 0.372189, 0, 0.526355, 0.850265, -0.707107, 0.601228, -0.372189), c = Color3.fromRGB(165, 207, 237), m = Enum.Material.Plastic }, -- 14
		{ n = "BellRim8", s = "Block", z = Vector3.new(1.7325, 0.2475, 0.405), cf = CFrame.new(-1.463715, 4.005, 1.463711, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(196, 225, 246), m = Enum.Material.Plastic }, -- 15
		{ n = "BellUpper7", s = "Block", z = Vector3.new(0.945, 0.2475, 1.111418), cf = CFrame.new(-0.877499, 5.4675, 0, 0, -0.850265, 0.526354, 0, 0.526354, 0.850265, -1, 0, 0), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 16
		{ n = "BellRim7", s = "Block", z = Vector3.new(1.7325, 0.2475, 0.405), cf = CFrame.new(-2.07, 4.004999, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(196, 225, 246), m = Enum.Material.Plastic }, -- 17
		{ n = "BellFlare7", s = "Block", z = Vector3.new(1.53, 0.2475, 1.337946), cf = CFrame.new(-1.619999, 4.499999, 0, 0, -0.73994, 0.672673, 0, 0.672673, 0.73994, -1, 0, 0), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 18
		{ n = "BellFlare4", s = "Block", z = Vector3.new(1.53, 0.2475, 1.337946), cf = CFrame.new(1.145515, 4.5, -1.145513, 0.707107, 0.523217, -0.475652, 0, 0.672673, 0.73994, 0.707107, -0.523217, 0.475652), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 19
		{ n = "BellUpper4", s = "Block", z = Vector3.new(0.945, 0.2475, 1.111418), cf = CFrame.new(0.620487, 5.4675, -0.620486, 0.707107, 0.601228, -0.372189, 0, 0.526355, 0.850265, 0.707107, -0.601228, 0.372189), c = Color3.fromRGB(165, 207, 237), m = Enum.Material.Plastic }, -- 20
		{ n = "BellRim4", s = "Block", z = Vector3.new(1.7325, 0.2475, 0.405), cf = CFrame.new(1.463715, 4.005, -1.463711, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(196, 225, 246), m = Enum.Material.Plastic }, -- 21
		{ n = "ArmStemL", s = "Block", z = Vector3.new(0.2475, 0.2475, 1.516206), cf = CFrame.new(0.93375, 2.9475, -0.045, 0.08854, 0.739069, -0.667785, 0, 0.670418, 0.741983, 0.996073, -0.065695, 0.059359), c = Color3.fromRGB(69, 128, 137), m = Enum.Material.Plastic }, -- 22
		{ n = "LeafHandL", s = "Block", z = Vector3.new(0.765, 0.99, 0.2025), cf = CFrame.new(1.525955, 1.89752, -0.09, -0.984808, 0.173648, 0, -0.173648, -0.984807, 0, 0, 0, 1), c = Color3.fromRGB(103, 174, 171), m = Enum.Material.Plastic }, -- 23
		{ n = "LowerGrowth", s = "Block", z = Vector3.new(0.9, 0.54, 0.81), cf = CFrame.new(0, 1.035, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(94, 160, 165), m = Enum.Material.Plastic }, -- 24
		{ n = "BellFlare6", s = "Block", z = Vector3.new(1.53, 0.2475, 1.337946), cf = CFrame.new(-1.145515, 4.5, -1.145513, 0.707107, -0.523217, 0.475652, 0, 0.672673, 0.73994, -0.707107, -0.523217, 0.475652), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 25
		{ n = "BellUpper6", s = "Block", z = Vector3.new(0.945, 0.2475, 1.111418), cf = CFrame.new(-0.620487, 5.4675, -0.620486, 0.707107, -0.601228, 0.372189, 0, 0.526355, 0.850265, -0.707107, -0.601228, 0.372189), c = Color3.fromRGB(165, 207, 237), m = Enum.Material.Plastic }, -- 26
		{ n = "BellRim6", s = "Block", z = Vector3.new(1.7325, 0.2475, 0.405), cf = CFrame.new(-1.463715, 4.005, -1.463711, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(196, 225, 246), m = Enum.Material.Plastic }, -- 27
		{ n = "CollarPetal6", s = "Block", z = Vector3.new(0.72, 0.81, 0.2025), cf = CFrame.new(-0.719299, 3.686482, 0.415288, 0.5, -0.813798, 0.296198, 0, -0.34202, -0.939693, 0.866025, 0.469846, -0.17101), c = Color3.fromRGB(250, 178, 211), m = Enum.Material.Plastic }, -- 28
		{ n = "HandPointLR", s = "Wedge", z = Vector3.new(0.1935, 0.72, 0.3825), cf = CFrame.new(1.48608, 1.0223, -0.09, 0, 0.173648, 0.984807, 0, -0.984807, 0.173648, 1, 0, 0), c = Color3.fromRGB(147, 206, 193), m = Enum.Material.Plastic }, -- 29
		{ n = "CollarPetal2", s = "Block", z = Vector3.new(0.72, 0.81, 0.2025), cf = CFrame.new(0.719299, 3.686482, 0.415288, 0.5, 0.813798, -0.296198, 0, -0.34202, -0.939693, -0.866025, 0.469846, -0.17101), c = Color3.fromRGB(250, 178, 211), m = Enum.Material.Plastic }, -- 30
		{ n = "Clapper", s = "Block", z = Vector3.new(0.4725, 0.81, 0.4725), cf = CFrame.new(0, 4.657499, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 178, 211), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.980392, 0.698039, 0.827451), HotColor = Color3.new(0.958039, 0.781569, 0.879216) } }, -- 31
		{ n = "BellUpper3", s = "Block", z = Vector3.new(0.945, 0.2475, 1.111418), cf = CFrame.new(0.877499, 5.4675, 0, 0, 0.850265, -0.526354, 0, 0.526354, 0.850265, 1, 0, 0), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 32
		{ n = "BellFlare3", s = "Block", z = Vector3.new(1.53, 0.2475, 1.337946), cf = CFrame.new(1.619999, 4.499999, 0, 0, 0.73994, -0.672673, 0, 0.672673, 0.73994, 1, 0, 0), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 33
		{ n = "CollarTip6", s = "Block", z = Vector3.new(0.4725, 0.4725, 0.1935), cf = CFrame.new(-1.21368, 3.478704, 0.70072, -0.221888, -0.928995, 0.296198, -0.241845, -0.241845, -0.939692, 0.944604, -0.280141, -0.17101), c = Color3.fromRGB(250, 178, 211), m = Enum.Material.Plastic }, -- 34
		{ n = "HandPointLL", s = "Wedge", z = Vector3.new(0.1935, 0.72, 0.3825), cf = CFrame.new(1.862768, 1.08872, -0.09, 0, 0.173648, -0.984807, 0, -0.984807, -0.173648, -1, 0, 0), c = Color3.fromRGB(147, 206, 193), m = Enum.Material.Plastic }, -- 35
		{ n = "BellUpper1", s = "Block", z = Vector3.new(0.945, 0.2475, 1.111418), cf = CFrame.new(0, 5.4675, 0.8775, -1, 0, 0, 0, 0.526354, 0.850265, 0, 0.850265, -0.526354), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 36
		{ n = "BellFlare1", s = "Block", z = Vector3.new(1.53, 0.2475, 1.337946), cf = CFrame.new(0, 4.499999, 1.62, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 37
		{ n = "Mouth", s = "Block", z = Vector3.new(0.2115, 0.0675, 0.0585), cf = CFrame.new(0, 5.333758, -1.32614, 1, 0, 0, 0, 0.848048, -0.529919, 0, 0.529919, 0.848048), c = Color3.fromRGB(45, 83, 112), m = Enum.Material.SmoothPlastic, st = false }, -- 38
		{ n = "BellRim5", s = "Block", z = Vector3.new(1.7325, 0.2475, 0.405), cf = CFrame.new(0, 4.004999, -2.07, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(196, 225, 246), m = Enum.Material.Plastic }, -- 39
		{ n = "BellUpper5", s = "Block", z = Vector3.new(0.945, 0.2475, 1.111418), cf = CFrame.new(0, 5.4675, -0.8775, 1, 0, 0, 0, 0.526354, 0.850265, 0, -0.850265, 0.526354), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 40
		{ n = "BellFlare5", s = "Block", z = Vector3.new(1.53, 0.2475, 1.337946), cf = CFrame.new(0, 4.499999, -1.62, 1, 0, 0, 0, 0.672673, 0.73994, 0, -0.73994, 0.672673), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 41
		{ n = "RootLeafR", s = "Wedge", z = Vector3.new(0.72, 0.36, 1.53), cf = CFrame.new(-0.3825, 0.18, 0.225, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c = Color3.fromRGB(103, 174, 171), m = Enum.Material.Plastic }, -- 42
		{ n = "BellRim1", s = "Block", z = Vector3.new(1.7325, 0.2475, 0.405), cf = CFrame.new(0, 4.004999, 2.07, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(196, 225, 246), m = Enum.Material.Plastic }, -- 43
		{ n = "HandPointRL", s = "Wedge", z = Vector3.new(0.1935, 0.72, 0.3825), cf = CFrame.new(-1.48608, 1.0223, -0.09, 0, -0.173648, -0.984808, 0, -0.984808, 0.173648, -1, 0, 0), c = Color3.fromRGB(147, 206, 193), m = Enum.Material.Plastic }, -- 44
		{ n = "BellFlare2", s = "Block", z = Vector3.new(1.53, 0.2475, 1.337946), cf = CFrame.new(1.145515, 4.5, 1.145513, -0.707107, 0.523217, -0.475652, 0, 0.672673, 0.73994, 0.707107, 0.523217, -0.475652), c = Color3.fromRGB(137, 190, 230), m = Enum.Material.Plastic }, -- 45
		{ n = "BellUpper2", s = "Block", z = Vector3.new(0.945, 0.2475, 1.111418), cf = CFrame.new(0.620487, 5.4675, 0.620486, -0.707107, 0.601228, -0.372189, 0, 0.526355, 0.850265, 0.707107, 0.601228, -0.372189), c = Color3.fromRGB(165, 207, 237), m = Enum.Material.Plastic }, -- 46
		{ n = "CollarTip5", s = "Block", z = Vector3.new(0.4725, 0.4725, 0.1935), cf = CFrame.new(-1.21368, 3.478704, -0.70072, -0.928995, -0.221888, 0.296198, -0.241845, -0.241845, -0.939692, 0.280141, -0.944604, 0.17101), c = Color3.fromRGB(250, 178, 211), m = Enum.Material.Plastic }, -- 47
		{ n = "CollarPetal5", s = "Block", z = Vector3.new(0.72, 0.81, 0.2025), cf = CFrame.new(-0.719299, 3.686482, -0.415288, -0.5, -0.813798, 0.296198, 0, -0.34202, -0.939693, 0.866025, -0.469846, 0.17101), c = Color3.fromRGB(232, 136, 182), m = Enum.Material.Plastic }, -- 48
		{ n = "EyeR", s = "Block", z = Vector3.new(0.225, 0.1665, 0.0585), cf = CFrame.new(-0.287998, 5.54365, -1.194985, 1, 0, 0, 0, 0.848048, -0.529919, 0, 0.529919, 0.848048), c = Color3.fromRGB(45, 83, 112), m = Enum.Material.SmoothPlastic, st = false, a = { Blink = true } }, -- 49
		{ n = "CollarTip3", s = "Block", z = Vector3.new(0.4725, 0.4725, 0.1935), cf = CFrame.new(1.21368, 3.478704, -0.70072, 0.221888, 0.928995, -0.296198, -0.241845, -0.241845, -0.939692, -0.944604, 0.280141, 0.17101), c = Color3.fromRGB(250, 178, 211), m = Enum.Material.Plastic }, -- 50
		{ n = "CollarPetal3", s = "Block", z = Vector3.new(0.72, 0.81, 0.2025), cf = CFrame.new(0.719299, 3.686482, -0.415288, -0.5, 0.813798, -0.296198, 0, -0.34202, -0.939693, -0.866025, -0.469846, 0.17101), c = Color3.fromRGB(232, 136, 182), m = Enum.Material.Plastic }, -- 51
		{ n = "EyeL", s = "Block", z = Vector3.new(0.225, 0.1665, 0.0585), cf = CFrame.new(0.287998, 5.54365, -1.194985, 1, 0, 0, 0, 0.848048, -0.529919, 0, 0.529919, 0.848048), c = Color3.fromRGB(45, 83, 112), m = Enum.Material.SmoothPlastic, st = false, a = { Blink = true } }, -- 52
		{ n = "EyeShineR", s = "Block", z = Vector3.new(0.063, 0.063, 0.036), cf = CFrame.new(-0.27, 5.598026, -1.214071, 1, 0, 0, 0, 0.848048, -0.529919, 0, 0.529919, 0.848048), c = Color3.fromRGB(231, 249, 255), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 53
		{ n = "BellRim2", s = "Block", z = Vector3.new(1.7325, 0.2475, 0.405), cf = CFrame.new(1.463715, 4.005, 1.463711, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(196, 225, 246), m = Enum.Material.Plastic }, -- 54
		{ n = "CollarTip2", s = "Block", z = Vector3.new(0.4725, 0.4725, 0.1935), cf = CFrame.new(1.21368, 3.478704, 0.70072, 0.928995, 0.221889, -0.296198, -0.241845, -0.241845, -0.939692, -0.280141, 0.944604, -0.17101), c = Color3.fromRGB(250, 178, 211), m = Enum.Material.Plastic }, -- 55
		{ n = "CollarTip1", s = "Block", z = Vector3.new(0.4725, 0.4725, 0.1935), cf = CFrame.new(0, 3.478704, 1.401439, 0.707107, -0.707107, 0, -0.241845, -0.241845, -0.939692, 0.664463, 0.664463, -0.34202), c = Color3.fromRGB(250, 178, 211), m = Enum.Material.Plastic }, -- 56
		{ n = "CollarPetal1", s = "Block", z = Vector3.new(0.72, 0.81, 0.2025), cf = CFrame.new(0, 3.686482, 0.830576, 1, 0, 0, 0, -0.34202, -0.939693, 0, 0.939693, -0.34202), c = Color3.fromRGB(232, 136, 182), m = Enum.Material.Plastic }, -- 57
		{ n = "BellRim3", s = "Block", z = Vector3.new(1.7325, 0.2475, 0.405), cf = CFrame.new(2.07, 4.004999, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(196, 225, 246), m = Enum.Material.Plastic }, -- 58
	},
	Joints = {
		{ k = "Motor6D", n = "Stem2", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 0, -0.8775, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new(0, 0, 1.8675, 1, 0, 0, 0, 0, 1, 0, -1, 0) },
		{ k = "Weld", n = "Hold_LowerGrowth", h = 1, a = 1, b = 24, c0 = CFrame.new(0, 0, 0.0675, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 3, a = 3, b = 1, c0 = CFrame.new(0, 0.135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.8775, 1, 0, 0, 0, 0, 1, 0, -1, 0) },
		{ k = "Weld", n = "Hold_RootLeafL", h = 3, a = 3, b = 6, c0 = CFrame.new(0.3825, 0.09, 0.225, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootLeafR", h = 3, a = 3, b = 42, c0 = CFrame.new(-0.3825, 0.09, 0.225, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Collar4", h = 4, a = 4, b = 5, c0 = CFrame.new(0, -0.45, 0.0225, -1, 0, 0, 0, -0.939693, 0.34202, 0, 0.34202, 0.939693), c1 = CFrame.new(0, -0.405, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Head", h = 4, a = 4, b = 9, c0 = CFrame.new(0, 0, -1.8675, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new(0, -0.225, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 4, a = 4, b = 12, c0 = CFrame.new(-0.4275, 0, 0.3375, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new(0, 0, 0.758103, 0.08854, 0, -0.996073, -0.739069, 0.670418, -0.065695, 0.667785, 0.741983, 0.059359) },
		{ k = "Motor6D", n = "ShoulderL", h = 4, a = 4, b = 22, c0 = CFrame.new(0.4275, 0, 0.3375, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new(0, 0, 0.758103, 0.08854, 0, 0.996073, 0.739069, 0.670418, -0.065695, -0.667785, 0.741983, 0.059359) },
		{ k = "Motor6D", n = "Collar6", h = 4, a = 4, b = 28, c0 = CFrame.new(-0.389711, 0.225, 0.0225, 0.5, -0.813798, 0.296198, 0.866025, 0.469846, -0.17101, 0, 0.34202, 0.939693), c1 = CFrame.new(0, -0.405, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Collar2", h = 4, a = 4, b = 30, c0 = CFrame.new(0.389711, 0.225, 0.0225, 0.5, 0.813798, -0.296198, -0.866025, 0.469846, -0.17101, 0, 0.34202, 0.939693), c1 = CFrame.new(0, -0.405, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Collar5", h = 4, a = 4, b = 48, c0 = CFrame.new(-0.389711, -0.225, 0.0225, -0.5, -0.813798, 0.296198, 0.866025, -0.469846, 0.17101, 0, 0.34202, 0.939693), c1 = CFrame.new(0, -0.405, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Collar3", h = 4, a = 4, b = 51, c0 = CFrame.new(0.389711, -0.225, 0.0225, -0.5, 0.813798, -0.296198, -0.866025, -0.469846, 0.17101, 0, 0.34202, 0.939693), c1 = CFrame.new(0, -0.405, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Collar1", h = 4, a = 4, b = 57, c0 = CFrame.new(0, 0.45, 0.0225, 1, 0, 0, 0, 0.939693, -0.34202, 0, 0.34202, 0.939693), c1 = CFrame.new(0, -0.405, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_CollarTip4", h = 5, a = 5, b = 2, c0 = CFrame.new(0, 0.6075, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShineL", h = 7, a = 7, b = 8, c0 = CFrame.new(0.27, 0.094501, -0.18, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Mouth", h = 7, a = 7, b = 38, c0 = CFrame.new(0, -0.189, -0.135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeR", h = 7, a = 7, b = 49, c0 = CFrame.new(-0.288, 0.0585, -0.135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeL", h = 7, a = 7, b = 52, c0 = CFrame.new(0.288, 0.0585, -0.135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShineR", h = 7, a = 7, b = 53, c0 = CFrame.new(-0.27, 0.094501, -0.18, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_FacePlate", h = 9, a = 9, b = 7, c0 = CFrame.new(0, -0.5175, -1.1115, 1, 0, 0, 0, 0.848048, -0.529919, 0, 0.529919, 0.848048), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellUpper8", h = 9, a = 9, b = 14, c0 = CFrame.new(-0.620486, -0.4725, 0.620486, -0.707107, -0.601228, 0.372189, 0, 0.526355, 0.850265, -0.707107, 0.601228, -0.372189), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellUpper7", h = 9, a = 9, b = 16, c0 = CFrame.new(-0.8775, -0.4725, 0, 0, -0.850265, 0.526354, 0, 0.526354, 0.850265, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellUpper4", h = 9, a = 9, b = 20, c0 = CFrame.new(0.620486, -0.4725, -0.620486, 0.707107, 0.601228, -0.372189, 0, 0.526355, 0.850265, 0.707107, -0.601228, 0.372189), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellUpper6", h = 9, a = 9, b = 26, c0 = CFrame.new(-0.620486, -0.4725, -0.620486, 0.707107, -0.601228, 0.372189, 0, 0.526355, 0.850265, -0.707107, -0.601228, 0.372189), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Clapper", h = 9, a = 9, b = 31, c0 = CFrame.new(0, -0.36, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.9225, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellUpper3", h = 9, a = 9, b = 32, c0 = CFrame.new(0.8775, -0.4725, 0, 0, 0.850265, -0.526354, 0, 0.526354, 0.850265, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellUpper1", h = 9, a = 9, b = 36, c0 = CFrame.new(0, -0.4725, 0.8775, -1, 0, 0, 0, 0.526354, 0.850265, 0, 0.850265, -0.526354), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellUpper5", h = 9, a = 9, b = 40, c0 = CFrame.new(0, -0.4725, -0.8775, 1, 0, 0, 0, 0.526354, 0.850265, 0, -0.850265, 0.526354), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellUpper2", h = 9, a = 9, b = 46, c0 = CFrame.new(0.620486, -0.4725, 0.620486, -0.707107, 0.601228, -0.372189, 0, 0.526355, 0.850265, 0.707107, 0.601228, -0.372189), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_HandPointRR", h = 11, a = 11, b = 10, c0 = CFrame.new(0.19125, 0.855, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_HandPointRL", h = 11, a = 11, b = 44, c0 = CFrame.new(-0.19125, 0.855, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HandR", h = 12, a = 12, b = 11, c0 = CFrame.new(0, 0, -0.758103, -0.087195, -0.015375, -0.996073, 0.844258, -0.531895, -0.065695, -0.528796, -0.846671, 0.059359), c1 = CFrame.new(0, -0.495, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellRim8", h = 13, a = 13, b = 15, c0 = CFrame.new(0, 0, -0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Flare8", h = 14, a = 14, b = 13, c0 = CFrame.new(0, 0, -0.555709, -1, 0, 0, 0, 0.526355, 0.850265, 0, 0.850265, -0.526355), c1 = CFrame.new(0, 0, 0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673) },
		{ k = "Motor6D", n = "Flare7", h = 16, a = 16, b = 18, c0 = CFrame.new(0, 0, -0.555709, -1, 0, 0, 0, 0.526354, 0.850265, 0, 0.850265, -0.526354), c1 = CFrame.new(0, 0, 0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673) },
		{ k = "Weld", n = "Hold_BellRim7", h = 18, a = 18, b = 17, c0 = CFrame.new(0, 0, -0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellRim4", h = 19, a = 19, b = 21, c0 = CFrame.new(0, 0, -0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Flare4", h = 20, a = 20, b = 19, c0 = CFrame.new(0, 0, -0.555709, -1, 0, 0, 0, 0.526355, 0.850265, 0, 0.850265, -0.526355), c1 = CFrame.new(0, 0, 0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673) },
		{ k = "Motor6D", n = "HandL", h = 22, a = 22, b = 23, c0 = CFrame.new(0, 0, -0.758103, -0.087195, 0.015375, 0.996073, -0.844258, -0.531895, -0.065695, 0.528796, -0.846671, 0.059359), c1 = CFrame.new(0, -0.495, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_HandPointLR", h = 23, a = 23, b = 29, c0 = CFrame.new(0.19125, 0.855, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_HandPointLL", h = 23, a = 23, b = 35, c0 = CFrame.new(-0.19125, 0.855, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellRim6", h = 25, a = 25, b = 27, c0 = CFrame.new(0, 0, -0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Flare6", h = 26, a = 26, b = 25, c0 = CFrame.new(0, 0, -0.555709, -1, 0, 0, 0, 0.526355, 0.850265, 0, 0.850265, -0.526355), c1 = CFrame.new(0, 0, 0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673) },
		{ k = "Weld", n = "Hold_CollarTip6", h = 28, a = 28, b = 34, c0 = CFrame.new(0, 0.6075, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_CollarTip2", h = 30, a = 30, b = 55, c0 = CFrame.new(0, 0.6075, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Flare3", h = 32, a = 32, b = 33, c0 = CFrame.new(0, 0, -0.555709, -1, 0, 0, 0, 0.526354, 0.850265, 0, 0.850265, -0.526354), c1 = CFrame.new(0, 0, 0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673) },
		{ k = "Weld", n = "Hold_BellRim3", h = 33, a = 33, b = 58, c0 = CFrame.new(0, 0, -0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Flare1", h = 36, a = 36, b = 37, c0 = CFrame.new(0, 0, -0.555709, -1, 0, 0, 0, 0.526354, 0.850265, 0, 0.850265, -0.526354), c1 = CFrame.new(0, 0, 0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673) },
		{ k = "Weld", n = "Hold_BellRim1", h = 37, a = 37, b = 43, c0 = CFrame.new(0, 0, -0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Flare5", h = 40, a = 40, b = 41, c0 = CFrame.new(0, 0, -0.555709, -1, 0, 0, 0, 0.526354, 0.850265, 0, 0.850265, -0.526354), c1 = CFrame.new(0, 0, 0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673) },
		{ k = "Weld", n = "Hold_BellRim5", h = 41, a = 41, b = 39, c0 = CFrame.new(0, 0, -0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BellRim2", h = 45, a = 45, b = 54, c0 = CFrame.new(0, 0, -0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Flare2", h = 46, a = 46, b = 45, c0 = CFrame.new(0, 0, -0.555709, -1, 0, 0, 0, 0.526355, 0.850265, 0, 0.850265, -0.526355), c1 = CFrame.new(0, 0, 0.668973, -1, 0, 0, 0, 0.672673, 0.73994, 0, 0.73994, -0.672673) },
		{ k = "Weld", n = "Hold_CollarTip5", h = 48, a = 48, b = 47, c0 = CFrame.new(0, 0.6075, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_CollarTip3", h = 51, a = 51, b = 50, c0 = CFrame.new(0, 0.6075, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_CollarTip1", h = 57, a = 57, b = 56, c0 = CFrame.new(0, 0.6075, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
