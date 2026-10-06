--!strict
--==============================================================================
-- PLANT FORM: Kilnhusk (Emberroot)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Emberroot/Kilnhusk" by a read-only generator on 2026-10-03. The original
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
	Source = "Emberroot/Kilnhusk", Kind = "plant", Yaw = 0,
	Size = Vector3.new(11.163258, 13.610935, 2.658001), Height = 13.610935, PartCount = 49,
	Base = 3,
	Unit = 4.5, ModelScale = 1.282727,
	Attributes = {},
	Parts = {
		{ n = "ChestBack", s = "Block", z = Vector3.new(3.8097, 4.906431, 0.808118), cf = CFrame.new(0, 7.099895, 0.808119, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(64, 46, 35), m = Enum.Material.Plastic }, -- 1
		{ n = "ChestHearth", s = "Block", z = Vector3.new(3.694254, 1.2699, 2.193463), cf = CFrame.new(0, 4.733263, -0.086584, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 2
		{ n = "Footing", s = "Block", z = Vector3.new(2.020295, 0.230891, 1.731682), cf = CFrame.new(0, 0.115446, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(28, 25, 24), m = Enum.Material.Plastic, t = 1, cs = false }, -- 3
		{ n = "EmberScar1_1", s = "Block", z = Vector3.new(0.098129, 0.865841, 0.080812), cf = CFrame.new(-1.962572, 6.234055, -1.171772, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(255, 115, 24), m = Enum.Material.Neon, st = false, cs = false }, -- 4
		{ n = "ChestSide1", s = "Block", z = Vector3.new(0.808118, 4.964154, 2.193463), cf = CFrame.new(-1.962572, 7.099895, -0.086584, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 5
		{ n = "ShoulderCap2", s = "Wedge", z = Vector3.new(1.847127, 1.673959, 2.078018), cf = CFrame.new(2.308908, 8.773855, 0.173168, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 6
		{ n = "ChestSide2", s = "Block", z = Vector3.new(0.808118, 4.964154, 2.193463), cf = CFrame.new(1.962572, 7.099895, -0.086584, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 7
		{ n = "UpperRoot2", s = "Block", z = Vector3.new(1.558514, 1.789404, 2.823082), cf = CFrame.new(2.871704, 7.446231, 0.173168, 0, 0.811308, -0.584619, 0, 0.584619, 0.811308, 1, 0, 0), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 8
		{ n = "RootLeg2", s = "Block", z = Vector3.new(1.443068, 1.673959, 4.344876), cf = CFrame.new(1.212177, 3.001582, 0.086584, -0.99613, 0.001287, -0.087884, -0.087894, -0.014591, 0.996023, 0, 0.999893, 0.014647), c = Color3.fromRGB(64, 46, 35), m = Enum.Material.Plastic }, -- 9
		{ n = "ForeRoot2", s = "Block", z = Vector3.new(1.673959, 1.847127, 2.991461), cf = CFrame.new(4.011728, 5.252768, 0.043293, 0.287348, 0.897468, -0.334637, 0, 0.349372, 0.936984, 0.957826, -0.26924, 0.100391), c = Color3.fromRGB(64, 46, 35), m = Enum.Material.Plastic }, -- 10
		{ n = "TimberHead", s = "Block", z = Vector3.new(2.251186, 2.078018, 1.847127), cf = CFrame.new(0, 10.534398, 0.115446, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 91, 56), m = Enum.Material.Plastic }, -- 11
		{ n = "Brow1", s = "Block", z = Vector3.new(1.039009, 0.317475, 0.43292), cf = CFrame.new(-0.577227, 11.134714, -0.836979, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(64, 46, 35), m = Enum.Material.Plastic }, -- 12
		{ n = "RootFinger2_2", s = "Wedge", z = Vector3.new(0.577227, 1.789404, 0.923563), cf = CFrame.new(5.050737, 2.828414, -0.346336, 0.987688, -0.156434, 0, 0.151104, 0.954034, -0.258819, 0.040488, 0.255633, 0.965926), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 13
		{ n = "RootHand2", s = "Block", z = Vector3.new(1.962572, 1.558514, 1.962572), cf = CFrame.new(4.560095, 3.521087, -0.086584, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 14
		{ n = "EmberScar2_1", s = "Block", z = Vector3.new(0.098129, 0.865841, 0.080812), cf = CFrame.new(1.962572, 6.234055, -1.171772, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(255, 115, 24), m = Enum.Material.Neon, st = false, cs = false }, -- 15
		{ n = "CrownSplinter5", s = "Wedge", z = Vector3.new(0.375198, 1.385345, 0.577227), cf = CFrame.new(0.413282, 11.96998, -0.152996, 0.993758, 0.111556, 0, -0.110724, 0.986351, 0.121869, 0.013595, -0.121109, 0.992546), c = Color3.fromRGB(28, 25, 24), m = Enum.Material.Plastic }, -- 16
		{ n = "ForeRoot1", s = "Block", z = Vector3.new(1.673959, 1.847127, 2.991461), cf = CFrame.new(-4.011728, 5.252768, 0.043293, 0.287348, -0.897468, 0.334637, 0, 0.349372, 0.936984, -0.957826, -0.26924, 0.100391), c = Color3.fromRGB(64, 46, 35), m = Enum.Material.Plastic }, -- 17
		{ n = "ShoulderCap1", s = "Wedge", z = Vector3.new(1.847127, 1.673959, 2.078018), cf = CFrame.new(-2.308908, 8.773855, 0.173168, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 18
		{ n = "RootFinger1_2", s = "Wedge", z = Vector3.new(0.577227, 1.789404, 0.923563), cf = CFrame.new(-4.069452, 2.828414, -0.346336, 0.987688, -0.156434, 0, 0.151104, 0.954034, -0.258819, 0.040488, 0.255633, 0.965926), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 19
		{ n = "UpperRoot1", s = "Block", z = Vector3.new(1.558514, 1.789404, 2.823082), cf = CFrame.new(-2.871704, 7.446231, 0.173168, 0, -0.811308, 0.584619, 0, 0.584619, 0.811308, -1, 0, 0), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 20
		{ n = "RootHand1", s = "Block", z = Vector3.new(1.962572, 1.558514, 1.962572), cf = CFrame.new(-4.560095, 3.521087, -0.086584, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 21
		{ n = "BarkRidge2_3", s = "Wedge", z = Vector3.new(0.375198, 1.327623, 0.375198), cf = CFrame.new(2.297363, 8.485241, -0.750395, 0.992546, 0.121869, 0, -0.121869, 0.992546, 0, 0, 0, 1), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 22
		{ n = "BarkRidge1_3", s = "Wedge", z = Vector3.new(0.375198, 1.327623, 0.375198), cf = CFrame.new(-2.297363, 8.485241, -0.750395, 0.992546, -0.121869, 0, 0.121869, 0.992546, 0, 0, 0, 1), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 23
		{ n = "BarkRidge2_1", s = "Wedge", z = Vector3.new(0.375198, 1.327623, 0.375198), cf = CFrame.new(2.297363, 5.599105, -0.750395, 0.992546, 0.121869, 0, -0.121869, 0.992546, 0, 0, 0, 1), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 24
		{ n = "RootFinger1_1", s = "Wedge", z = Vector3.new(0.577227, 1.789404, 0.923563), cf = CFrame.new(-5.050737, 2.828414, -0.346336, 0.987688, 0.156434, 0, -0.151104, 0.954034, -0.258819, -0.040488, 0.255633, 0.965926), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 25
		{ n = "Brow2", s = "Block", z = Vector3.new(1.039009, 0.317475, 0.43292), cf = CFrame.new(0.577227, 11.134714, -0.836979, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(64, 46, 35), m = Enum.Material.Plastic }, -- 26
		{ n = "NoseRidge", s = "Wedge", z = Vector3.new(0.375198, 1.039009, 0.548366), cf = CFrame.new(0, 10.430497, -0.946651, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 27
		{ n = "EyeR", s = "Block", z = Vector3.new(0.519505, 0.144307, 0.092356), cf = CFrame.new(-0.577227, 10.851872, -0.836979, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(255, 193, 66), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 28
		{ n = "BarkRidge1_2", s = "Wedge", z = Vector3.new(0.375198, 1.327623, 0.375198), cf = CFrame.new(-2.297363, 7.042173, -0.750395, 0.984808, 0.173648, 0, -0.173648, 0.984808, 0, 0, 0, 1), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 29
		{ n = "EmberScar1_2", s = "Block", z = Vector3.new(0.098129, 0.865841, 0.080812), cf = CFrame.new(-1.962572, 8.023459, -1.171772, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(255, 115, 24), m = Enum.Material.Neon, st = false, cs = false }, -- 30
		{ n = "EyeL", s = "Block", z = Vector3.new(0.519505, 0.144307, 0.092356), cf = CFrame.new(0.577227, 10.851872, -0.836979, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(255, 193, 66), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 31
		{ n = "Grate3", s = "Block", z = Vector3.new(0.144307, 4.271481, 0.259752), cf = CFrame.new(0.692673, 7.099895, -0.43292, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(28, 25, 24), m = Enum.Material.SmoothPlastic, st = false }, -- 32
		{ n = "RootLeg1", s = "Block", z = Vector3.new(1.443068, 1.673959, 4.344876), cf = CFrame.new(-1.212177, 3.001582, 0.086584, -0.99613, -0.001287, 0.087884, 0.087894, -0.014591, 0.996023, 0, 0.999893, 0.014647), c = Color3.fromRGB(64, 46, 35), m = Enum.Material.Plastic }, -- 33
		{ n = "BarkRidge2_2", s = "Wedge", z = Vector3.new(0.375198, 1.327623, 0.375198), cf = CFrame.new(2.297363, 7.042173, -0.750395, 0.984808, -0.173648, 0, 0.173648, 0.984808, 0, 0, 0, 1), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 34
		{ n = "CrownSplinter7", s = "Wedge", z = Vector3.new(0.375198, 1.212177, 0.577227), cf = CFrame.new(1.208303, 11.861903, -0.139725, 0.94429, 0.329114, 0, -0.326661, 0.937252, 0.121869, 0.040109, -0.11508, 0.992546), c = Color3.fromRGB(28, 25, 24), m = Enum.Material.Plastic }, -- 35
		{ n = "RootBoot1", s = "Block", z = Vector3.new(2.020295, 1.385345, 2.655245), cf = CFrame.new(-1.385345, 0.692673, -0.086584, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 36
		{ n = "CrownSplinter4", s = "Wedge", z = Vector3.new(0.375198, 2.308909, 0.577227), cf = CFrame.new(0, 12.423903, 0.521748, 1, 0, 0, 0, 0.984808, -0.173648, 0, 0.173648, 0.984808), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 37
		{ n = "Grate2", s = "Block", z = Vector3.new(0.144307, 4.271481, 0.259752), cf = CFrame.new(0, 7.099895, -0.43292, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(28, 25, 24), m = Enum.Material.SmoothPlastic, st = false }, -- 38
		{ n = "CrownSplinter2", s = "Wedge", z = Vector3.new(0.375198, 2.078018, 0.577227), cf = CFrame.new(-0.90259, 12.288279, 0.497833, 0.975111, -0.221719, 0, 0.21835, 0.960296, -0.173648, 0.038501, 0.169326, 0.984808), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 39
		{ n = "RootFinger2_1", s = "Wedge", z = Vector3.new(0.577227, 1.789404, 0.923563), cf = CFrame.new(4.069452, 2.828414, -0.346336, 0.987688, 0.156434, 0, -0.151104, 0.954034, -0.258819, -0.040488, 0.255633, 0.965926), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 40
		{ n = "EmberScar2_2", s = "Block", z = Vector3.new(0.098129, 0.865841, 0.080812), cf = CFrame.new(1.962572, 8.023459, -1.171772, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(255, 115, 24), m = Enum.Material.Neon, st = false, cs = false }, -- 41
		{ n = "CrownSplinter3", s = "Wedge", z = Vector3.new(0.375198, 1.616236, 0.577227), cf = CFrame.new(-0.426161, 12.083849, -0.166977, 0.993758, -0.111556, 0, 0.110724, 0.986351, 0.121869, -0.013595, -0.121109, 0.992546), c = Color3.fromRGB(28, 25, 24), m = Enum.Material.Plastic }, -- 42
		{ n = "ChestLintel", s = "Block", z = Vector3.new(3.17475, 0.808118, 2.193463), cf = CFrame.new(0, 9.293359, -0.086584, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 43
		{ n = "BarkRidge1_1", s = "Wedge", z = Vector3.new(0.375198, 1.327623, 0.375198), cf = CFrame.new(-2.297363, 5.599105, -0.750395, 0.992546, -0.121869, 0, 0.121869, 0.992546, 0, 0, 0, 1), c = Color3.fromRGB(115, 77, 47), m = Enum.Material.Plastic }, -- 44
		{ n = "RootBoot2", s = "Block", z = Vector3.new(2.020295, 1.385345, 2.655245), cf = CFrame.new(1.385345, 0.692673, -0.086584, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 45
		{ n = "Grate1", s = "Block", z = Vector3.new(0.144307, 4.271481, 0.259752), cf = CFrame.new(-0.692673, 7.099895, -0.43292, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(28, 25, 24), m = Enum.Material.SmoothPlastic, st = false }, -- 46
		{ n = "CrownSplinter6", s = "Wedge", z = Vector3.new(0.375198, 1.90485, 0.577227), cf = CFrame.new(0.883392, 12.205132, 0.483171, 0.975111, 0.221719, 0, -0.21835, 0.960296, -0.173648, -0.038501, 0.169326, 0.984808), c = Color3.fromRGB(87, 59, 39), m = Enum.Material.Plastic }, -- 47
		{ n = "FurnaceCore", s = "Block", z = Vector3.new(2.77069, 3.232472, 0.230891), cf = CFrame.new(0, 7.099895, 0.375198, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 115, 24), m = Enum.Material.Neon, st = false, cs = false }, -- 48
		{ n = "CrownSplinter1", s = "Wedge", z = Vector3.new(0.375198, 1.327623, 0.577227), cf = CFrame.new(-1.227301, 11.916004, -0.146368, 0.94429, -0.329114, 0, 0.326661, 0.937252, 0.121869, -0.040109, -0.11508, 0.992546), c = Color3.fromRGB(28, 25, 24), m = Enum.Material.Plastic }, -- 49
	},
	Joints = {
		{ k = "Weld", n = "Hold_ChestHearth", h = 1, a = 1, b = 2, c0 = CFrame.new(0, -2.366631, -0.894702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ChestSide1", h = 1, a = 1, b = 5, c0 = CFrame.new(-1.962572, 0, -0.894702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ChestSide2", h = 1, a = 1, b = 7, c0 = CFrame.new(1.962572, 0, -0.894702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Head", h = 1, a = 1, b = 11, c0 = CFrame.new(0, 2.5398, -0.692673, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.894703, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ChestLintel", h = 1, a = 1, b = 43, c0 = CFrame.new(0, 2.193463, -0.894702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_FurnaceCore", h = 1, a = 1, b = 48, c0 = CFrame.new(0, 0, -0.43292, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Grate3", h = 2, a = 2, b = 32, c0 = CFrame.new(0.692673, 2.366631, -0.346336, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Grate2", h = 2, a = 2, b = 38, c0 = CFrame.new(0, 2.366631, -0.346336, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Grate1", h = 2, a = 2, b = 46, c0 = CFrame.new(-0.692673, 2.366631, -0.346336, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 3, a = 3, b = 1, c0 = CFrame.new(0, 4.386927, 0.461782, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -2.597522, -0.346336, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Leg2", h = 3, a = 3, b = 9, c0 = CFrame.new(1.039009, 4.848709, 0.115445, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.970409, -0.99613, -0.087894, 0, 0.001287, -0.014591, 0.999893, -0.087884, 0.996023, 0.014647) },
		{ k = "Motor6D", n = "Leg1", h = 3, a = 3, b = 33, c0 = CFrame.new(-1.039009, 4.848709, 0.115445, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.970409, -0.99613, 0.087894, 0, -0.001287, -0.014591, 0.999893, 0.087884, 0.996023, 0.014647) },
		{ k = "Weld", n = "Hold_EmberScar1_1", h = 5, a = 5, b = 4, c0 = CFrame.new(0, -0.86584, -1.085187, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ShoulderCap1", h = 5, a = 5, b = 18, c0 = CFrame.new(-0.346336, 1.673959, 0.259752, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BarkRidge1_3", h = 5, a = 5, b = 23, c0 = CFrame.new(-0.334792, 1.385346, -0.663811, 0.992546, -0.121869, 0, 0.121869, 0.992546, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BarkRidge1_2", h = 5, a = 5, b = 29, c0 = CFrame.new(-0.334792, -0.057722, -0.663811, 0.984808, 0.173648, 0, -0.173648, 0.984808, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EmberScar1_2", h = 5, a = 5, b = 30, c0 = CFrame.new(0, 0.923564, -1.085187, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BarkRidge1_1", h = 5, a = 5, b = 44, c0 = CFrame.new(-0.334792, -1.50079, -0.663811, 0.992546, -0.121869, 0, 0.121869, 0.992546, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "UpperArm2", h = 6, a = 6, b = 8, c0 = CFrame.new(-0.213161, -0.308765, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0.000001, 1.209512, 0, 0, 1, 0.811308, 0.584619, 0, -0.584619, 0.811308, 0) },
		{ k = "Weld", n = "Hold_ShoulderCap2", h = 7, a = 7, b = 6, c0 = CFrame.new(0.346336, 1.673959, 0.259752, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EmberScar2_1", h = 7, a = 7, b = 15, c0 = CFrame.new(0, -0.86584, -1.085187, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BarkRidge2_3", h = 7, a = 7, b = 22, c0 = CFrame.new(0.334792, 1.385346, -0.663811, 0.992546, 0.121869, 0, -0.121869, 0.992546, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BarkRidge2_1", h = 7, a = 7, b = 24, c0 = CFrame.new(0.334792, -1.50079, -0.663811, 0.992546, 0.121869, 0, -0.121869, 0.992546, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BarkRidge2_2", h = 7, a = 7, b = 34, c0 = CFrame.new(0.334792, -0.057722, -0.663811, 0.984808, -0.173648, 0, 0.173648, 0.984808, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EmberScar2_2", h = 7, a = 7, b = 41, c0 = CFrame.new(0, 0.923564, -1.085187, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Forearm2", h = 8, a = 8, b = 10, c0 = CFrame.new(0, 0, -1.209511, 0, 0, 1, 0.811308, 0.584619, 0, -0.584619, 0.811308, 0), c1 = CFrame.new(0, 0.000001, 1.293701, 0.287348, 0, 0.957826, 0.897468, 0.349372, -0.26924, -0.334637, 0.936984, 0.100391) },
		{ k = "Motor6D", n = "Foot2", h = 9, a = 9, b = 45, c0 = CFrame.new(0, 0, -1.970409, -0.99613, -0.087894, 0, 0.001287, -0.014591, 0.999893, -0.087884, 0.996023, 0.014647), c1 = CFrame.new(0, 0.346336, 0.144307, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hand2", h = 10, a = 10, b = 14, c0 = CFrame.new(0, 0, -1.293701, 0.287348, 0, 0.957826, 0.897468, 0.349372, -0.26924, -0.334637, 0.936984, 0.100391), c1 = CFrame.new(-0.115446, 0.519504, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Brow1", h = 11, a = 11, b = 12, c0 = CFrame.new(-0.577227, 0.600316, -0.952425, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Crown5", h = 11, a = 11, b = 16, c0 = CFrame.new(0.352109, 0.894701, -0.20203, 0.993758, 0.111556, 0, -0.110724, 0.986351, 0.121869, 0.013595, -0.121109, 0.992546), c1 = CFrame.new(0, -0.548366, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Brow2", h = 11, a = 11, b = 26, c0 = CFrame.new(0.577227, 0.600316, -0.952425, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_NoseRidge", h = 11, a = 11, b = 27, c0 = CFrame.new(0, -0.103901, -1.062098, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeR", h = 11, a = 11, b = 28, c0 = CFrame.new(-0.577227, 0.317474, -0.952425, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeL", h = 11, a = 11, b = 31, c0 = CFrame.new(0.577227, 0.317474, -0.952425, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Crown7", h = 11, a = 11, b = 35, c0 = CFrame.new(1.056326, 0.894701, -0.20203, 0.94429, 0.329114, 0, -0.326661, 0.937252, 0.121869, 0.040109, -0.11508, 0.992546), c1 = CFrame.new(0, -0.46178, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Crown4", h = 11, a = 11, b = 37, c0 = CFrame.new(0, 0.894701, 0.230891, 1, 0, 0, 0, 0.984808, -0.173648, 0, 0.173648, 0.984808), c1 = CFrame.new(0, -1.010149, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Crown2", h = 11, a = 11, b = 39, c0 = CFrame.new(-0.704217, 0.894701, 0.230891, 0.975111, -0.221719, 0, 0.21835, 0.960297, -0.173648, 0.038501, 0.169326, 0.984808), c1 = CFrame.new(0, -0.894702, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Crown3", h = 11, a = 11, b = 42, c0 = CFrame.new(-0.352109, 0.894701, -0.20203, 0.993758, -0.111556, 0, 0.110724, 0.986351, 0.121869, -0.013595, -0.121109, 0.992546), c1 = CFrame.new(0, -0.66381, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Crown6", h = 11, a = 11, b = 47, c0 = CFrame.new(0.704217, 0.894701, 0.230891, 0.975111, 0.221719, 0, -0.21835, 0.960297, -0.173648, -0.038501, 0.169326, 0.984808), c1 = CFrame.new(0, -0.808118, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Crown1", h = 11, a = 11, b = 49, c0 = CFrame.new(-1.056326, 0.894701, -0.20203, 0.94429, -0.329114, 0, 0.326661, 0.937252, 0.121869, -0.040109, -0.11508, 0.992546), c1 = CFrame.new(0, -0.519503, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFinger2_2", h = 14, a = 14, b = 13, c0 = CFrame.new(0.490643, -0.692673, -0.259752, 0.987688, -0.156434, 0, 0.151104, 0.954034, -0.258819, 0.040488, 0.255633, 0.965926), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFinger2_1", h = 14, a = 14, b = 40, c0 = CFrame.new(-0.490643, -0.692673, -0.259752, 0.987688, 0.156434, 0, -0.151104, 0.954034, -0.258819, -0.040488, 0.255633, 0.965926), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hand1", h = 17, a = 17, b = 21, c0 = CFrame.new(0, 0, -1.293701, 0.287348, 0, -0.957826, -0.897468, 0.349372, -0.26924, 0.334637, 0.936984, 0.100391), c1 = CFrame.new(0.115446, 0.519504, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "UpperArm1", h = 18, a = 18, b = 20, c0 = CFrame.new(0.213161, -0.308765, 0, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0.000001, 1.209512, 0, 0, -1, -0.811308, 0.584619, 0, 0.584619, 0.811308, 0) },
		{ k = "Motor6D", n = "Forearm1", h = 20, a = 20, b = 17, c0 = CFrame.new(0, 0, -1.209511, 0, 0, -1, -0.811308, 0.584619, 0, 0.584619, 0.811308, 0), c1 = CFrame.new(0, 0.000001, 1.293701, 0.287348, 0, -0.957826, -0.897468, 0.349372, -0.26924, 0.334637, 0.936984, 0.100391) },
		{ k = "Weld", n = "Hold_RootFinger1_2", h = 21, a = 21, b = 19, c0 = CFrame.new(0.490643, -0.692673, -0.259752, 0.987688, -0.156434, 0, 0.151104, 0.954034, -0.258819, 0.040488, 0.255633, 0.965926), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFinger1_1", h = 21, a = 21, b = 25, c0 = CFrame.new(-0.490643, -0.692673, -0.259752, 0.987688, 0.156434, 0, -0.151104, 0.954034, -0.258819, -0.040488, 0.255633, 0.965926), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Foot1", h = 33, a = 33, b = 36, c0 = CFrame.new(0, 0, -1.970409, -0.99613, 0.087894, 0, -0.001287, -0.014591, 0.999893, 0.087884, 0.996023, 0.014647), c1 = CFrame.new(0, 0.346336, 0.144307, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
