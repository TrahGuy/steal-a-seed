--!strict
--==============================================================================
-- PLANT FORM: Cosmospire (Starbloom plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Starbloom plants/Cosmospire" by a read-only generator on 2026-10-03. The original
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
	Source = "Starbloom plants/Cosmospire", Kind = "plant", Yaw = 0,
	Size = Vector3.new(8.894142, 14.882832, 5.149548), Height = 14.882832, PartCount = 47,
	Base = 6,
	Unit = 4.5, ModelScale = 1.888006,
	Attributes = {},
	Parts = {
		{ n = "Stalk1", s = "Block", z = Vector3.new(1.699205, 3.058569, 1.699205), cf = CFrame.new(-0.169922, 2.973608, 0, 0.99863, -0.052336, 0, 0.052336, 0.99863, 0, 0, 0, 1), c = Color3.fromRGB(67, 43, 115), m = Enum.Material.Plastic }, -- 1
		{ n = "Stalk2", s = "Block", z = Vector3.new(1.486804, 2.888649, 1.486804), cf = CFrame.new(0.212402, 5.522416, 0.084961, 0.949753, 0.049774, 0.309017, -0.052336, 0.998629, 0, -0.308594, -0.016173, 0.951057), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 2
		{ n = "Stalk3", s = "Block", z = Vector3.new(1.274404, 2.888649, 1.274404), cf = CFrame.new(-0.127441, 7.986263, 0, 0.807908, -0.042341, 0.587785, 0.052336, 0.998629, 0, -0.58698, 0.030762, 0.809017), c = Color3.fromRGB(67, 43, 115), m = Enum.Material.Plastic }, -- 3
		{ n = "SeedHead", s = "Block", z = Vector3.new(1.996566, 2.293927, 1.699205), cf = CFrame.new(0, 10.152749, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(31, 28, 62), m = Enum.Material.Plastic }, -- 4
		{ n = "Pupil", s = "Block", z = Vector3.new(0.118944, 0.637202, 0.08496), cf = CFrame.new(0, 10.28019, -1.01952, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(31, 28, 62), m = Enum.Material.SmoothPlastic, st = false, a = { HideOnBlink = true } }, -- 5
		{ n = "Footing", s = "Block", z = Vector3.new(2.124006, 0.339841, 2.124006), cf = CFrame.new(0, 0.169921, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(31, 28, 62), m = Enum.Material.Plastic, t = 1, cs = false }, -- 6
		{ n = "Eye", s = "Block", z = Vector3.new(0.365329, 0.892083, 0.186913), cf = CFrame.new(0, 10.28019, -0.909073, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 7
		{ n = "LeafStem2", s = "Block", z = Vector3.new(0.467281, 0.637202, 2.124006), cf = CFrame.new(1.529289, 6.159617, 0.212402, 0, -0.6, -0.8, 0, 0.8, -0.6, 1, 0, 0), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 8
		{ n = "LeafBlade2", s = "Block", z = Vector3.new(1.019523, 2.293927, 0.849603), cf = CFrame.new(2.817474, 7.423177, 0.212402, 0.819152, 0.573576, 0, -0.573577, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 9
		{ n = "GoldRidge3_2", s = "Block", z = Vector3.new(0.339841, 2.081526, 0.509761), cf = CFrame.new(0.325584, 8.015608, -0.329144, 0.807908, -0.042341, 0.587785, 0.052336, 0.998629, 0, -0.58698, 0.030762, 0.809017), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 10
		{ n = "LeafStem3", s = "Block", z = Vector3.new(0.467281, 0.637202, 2.262241), cf = CFrame.new(-1.529282, 8.623464, 0.127441, 0, 0.563337, 0.826227, 0, 0.826227, -0.563337, -1, 0, 0), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 11
		{ n = "LeafVein2", s = "Block", z = Vector3.new(0.144432, 1.699205, 0.152928), cf = CFrame.new(2.817474, 7.423177, -0.178413, 0.819152, 0.573576, 0, -0.573577, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 12
		{ n = "CrownPoint1", s = "Wedge", z = Vector3.new(0.722162, 1.529285, 0.892083), cf = CFrame.new(-1.155952, 13.541025, 0.127441, 0.965926, -0.258819, 0, 0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 13
		{ n = "CrownStem1", s = "Block", z = Vector3.new(0.66269, 0.807122, 2.359464), cf = CFrame.new(-0.802872, 12.106833, 0.127441, 0, 0.972223, 0.234054, 0, 0.234054, -0.972223, -1, 0, 0), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 14
		{ n = "RootStem1", s = "Block", z = Vector3.new(0.849603, 0.849603, 2.163152), cf = CFrame.new(0, 0.913323, 1.019524, -1, 0, 0, 0, 0.942627, 0.333847, 0, 0.333847, -0.942627), c = Color3.fromRGB(67, 43, 115), m = Enum.Material.Plastic }, -- 15
		{ n = "RootFoot1", s = "Block", z = Vector3.new(1.444324, 1.019523, 1.954086), cf = CFrame.new(0, 0.509761, 2.039047, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 16
		{ n = "GoldRidge3_1", s = "Block", z = Vector3.new(0.339841, 2.081526, 0.509761), cf = CFrame.new(-0.580467, 7.956917, 0.329144, 0.807908, -0.042341, 0.587785, 0.052336, 0.998629, 0, -0.58698, 0.030762, 0.809017), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 17
		{ n = "LeafBlade3", s = "Block", z = Vector3.new(1.019523, 2.293927, 0.849603), cf = CFrame.new(-2.902428, 9.887024, 0.127441, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 18
		{ n = "LeafVein3", s = "Block", z = Vector3.new(0.144432, 1.699205, 0.152928), cf = CFrame.new(-2.902428, 9.887024, -0.263374, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 19
		{ n = "CrownBrow1", s = "Block", z = Vector3.new(0.849603, 0.220897, 0.382321), cf = CFrame.new(-0.450287, 10.908895, -0.77314, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 20
		{ n = "RootStem2", s = "Block", z = Vector3.new(0.849603, 0.849603, 2.163152), cf = CFrame.new(0.882935, 0.913323, -0.509762, 0.5, 0.28912, -0.816339, 0, 0.942627, 0.333847, 0.866025, -0.166924, 0.471314), c = Color3.fromRGB(67, 43, 115), m = Enum.Material.Plastic }, -- 21
		{ n = "RootFoot2", s = "Block", z = Vector3.new(1.444324, 1.019523, 1.954086), cf = CFrame.new(1.765869, 0.509761, -1.019524, -0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, -0.5), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 22
		{ n = "LeafStem4", s = "Block", z = Vector3.new(0.467281, 0.637202, 2.262241), cf = CFrame.new(1.274399, 8.623464, 0.127441, 0, -0.563337, -0.826227, 0, 0.826227, -0.563337, 1, 0, 0), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 23
		{ n = "CyanInlay1", s = "Block", z = Vector3.new(0.144432, 2.039046, 0.152928), cf = CFrame.new(-0.169922, 2.973608, -0.824116, 0.99863, -0.052336, 0, 0.052336, 0.99863, 0, 0, 0, 1), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 24
		{ n = "LeafPoint3", s = "Wedge", z = Vector3.new(1.019523, 1.274404, 0.892083), cf = CFrame.new(-3.70649, 11.035347, 0.127441, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 25
		{ n = "GoldRidge2_2", s = "Block", z = Vector3.new(0.339841, 2.081526, 0.509761), cf = CFrame.new(0.845825, 5.487511, -0.120853, 0.949753, 0.049774, 0.309017, -0.052336, 0.998629, 0, -0.308594, -0.016173, 0.951057), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 26
		{ n = "LeafStem1", s = "Block", z = Vector3.new(0.467281, 0.637202, 2.124006), cf = CFrame.new(-1.104485, 6.159618, 0.212402, 0, 0.6, 0.8, 0, 0.8, -0.6, -1, 0, 0), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 27
		{ n = "LeafPoint1", s = "Wedge", z = Vector3.new(1.019523, 1.274404, 0.892083), cf = CFrame.new(-3.196732, 8.571501, 0.212402, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 28
		{ n = "LeafBlade1", s = "Block", z = Vector3.new(1.019523, 2.293927, 0.849603), cf = CFrame.new(-2.39267, 7.423178, 0.212402, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 29
		{ n = "EyeShine", s = "Block", z = Vector3.new(0.08496, 0.152928, 0.076464), cf = CFrame.new(-0.016991, 10.450109, -1.078991, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(227, 253, 255), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 30
		{ n = "RootStem3", s = "Block", z = Vector3.new(0.849603, 0.849603, 2.163152), cf = CFrame.new(-0.882935, 0.913323, -0.509762, 0.5, -0.28912, 0.816339, 0, 0.942627, 0.333847, -0.866025, -0.166924, 0.471314), c = Color3.fromRGB(67, 43, 115), m = Enum.Material.Plastic }, -- 31
		{ n = "CrownStem2", s = "Block", z = Vector3.new(0.66269, 0.807122, 2.857558), cf = CFrame.new(0.802872, 12.361714, 0.127441, 0.981148, 0, -0.193256, -0.193256, 0, -0.981148, 0, 1, 0), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 32
		{ n = "CrownVein2", s = "Block", z = Vector3.new(0.152928, 0.144432, 2.018656), cf = CFrame.new(0.802872, 12.361714, -0.254879, 0.981148, 0, -0.193256, -0.193256, 0, -0.981148, 0, 1, 0), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 33
		{ n = "GoldRidge1_1", s = "Block", z = Vector3.new(0.339841, 2.081526, 0.509761), cf = CFrame.new(-0.942001, 2.933146, 0, 0.99863, -0.052336, 0, 0.052336, 0.99863, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 34
		{ n = "CrownPoint2", s = "Wedge", z = Vector3.new(0.722162, 1.529285, 0.892083), cf = CFrame.new(1.155952, 14.050788, 0.127441, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 35
		{ n = "LeafVein4", s = "Block", z = Vector3.new(0.144432, 1.699205, 0.152928), cf = CFrame.new(2.647545, 9.887024, -0.263374, 0.819152, 0.573576, 0, -0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 36
		{ n = "LeafBlade4", s = "Block", z = Vector3.new(1.019523, 2.293927, 0.849603), cf = CFrame.new(2.647545, 9.887024, 0.127441, 0.819152, 0.573576, 0, -0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 37
		{ n = "CyanInlay2", s = "Block", z = Vector3.new(0.144432, 2.039046, 0.152928), cf = CFrame.new(-0.009445, 5.522416, -0.597816, 0.949753, 0.049774, 0.309017, -0.052336, 0.998629, 0, -0.308594, -0.016173, 0.951057), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 38
		{ n = "GoldRidge1_2", s = "Block", z = Vector3.new(0.339841, 2.081526, 0.509761), cf = CFrame.new(0.602158, 3.014072, 0, 0.99863, -0.052336, 0, 0.052336, 0.99863, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 39
		{ n = "RootFoot3", s = "Block", z = Vector3.new(1.444324, 1.019523, 1.954086), cf = CFrame.new(-1.765869, 0.509761, -1.019524, -0.5, 0, -0.866025, 0, 1, 0, 0.866025, 0, -0.5), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 40
		{ n = "CyanInlay3", s = "Block", z = Vector3.new(0.144432, 2.039046, 0.152928), cf = CFrame.new(-0.487, 7.986263, -0.494888, 0.807908, -0.042341, 0.587785, 0.052336, 0.998629, 0, -0.58698, 0.030762, 0.809017), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 41
		{ n = "LeafVein1", s = "Block", z = Vector3.new(0.144432, 1.699205, 0.152928), cf = CFrame.new(-2.39267, 7.423178, -0.178413, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 42
		{ n = "LeafPoint2", s = "Wedge", z = Vector3.new(1.019523, 1.274404, 0.892083), cf = CFrame.new(3.621536, 8.5715, 0.212402, 0.819152, 0.573576, 0, -0.573577, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 43
		{ n = "CrownBrow2", s = "Block", z = Vector3.new(0.849603, 0.220897, 0.382321), cf = CFrame.new(0.450287, 10.908895, -0.77314, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 44
		{ n = "GoldRidge2_1", s = "Block", z = Vector3.new(0.339841, 2.081526, 0.509761), cf = CFrame.new(-0.421021, 5.557321, 0.290775, 0.949753, 0.049774, 0.309017, -0.052336, 0.998629, 0, -0.308594, -0.016173, 0.951057), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 45
		{ n = "CrownVein1", s = "Block", z = Vector3.new(0.152928, 0.144432, 1.651627), cf = CFrame.new(-1.174576, 12.01735, 0.127441, 0, 0.972223, 0.234054, 0, 0.234054, -0.972223, -1, 0, 0), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 46
		{ n = "LeafPoint4", s = "Wedge", z = Vector3.new(1.019523, 1.274404, 0.892083), cf = CFrame.new(3.451607, 11.035346, 0.127441, 0.819152, 0.573576, 0, -0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 47
	},
	Joints = {
		{ k = "Motor6D", n = "Spine2", h = 1, a = 1, b = 2, c0 = CFrame.new(0.257596, 1.262653, 0.04248, 0.99863, 0.052336, 0, -0.052336, 0.99863, 0, 0, 0, 1), c1 = CFrame.new(-0.101749, -1.281485, -0.099473, 0.949753, -0.052336, -0.308594, 0.049774, 0.99863, -0.016173, 0.309017, 0, 0.951057) },
		{ k = "Weld", n = "Hold_CyanInlay1", h = 1, a = 1, b = 24, c0 = CFrame.new(0, 0, -0.824115, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldRidge1_1", h = 1, a = 1, b = 34, c0 = CFrame.new(-0.773138, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldRidge1_2", h = 1, a = 1, b = 39, c0 = CFrame.new(0.773138, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Spine3", h = 2, a = 2, b = 3, c0 = CFrame.new(-0.212747, 1.222464, -0.092909, 0.949753, -0.052336, -0.308594, 0.049774, 0.99863, -0.016173, 0.309017, 0, 0.951057), c1 = CFrame.new(0.047871, -1.236123, 0.134244, 0.807908, 0.052336, -0.58698, -0.042341, 0.99863, 0.030762, 0.587785, 0, 0.809017) },
		{ k = "Motor6D", n = "Leaf2", h = 2, a = 2, b = 8, c0 = CFrame.new(0.404475, 0.021197, 0.265601, 0.949753, -0.052336, -0.308594, 0.049774, 0.99863, -0.016173, 0.309017, 0, 0.951057), c1 = CFrame.new(0, 0, 1.062003, 0, 0, 1, -0.6, 0.8, 0, -0.8, -0.6, 0) },
		{ k = "Weld", n = "Hold_GoldRidge2_2", h = 2, a = 2, b = 26, c0 = CFrame.new(0.666938, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Leaf1", h = 2, a = 2, b = 27, c0 = CFrame.new(-0.483129, -0.02532, -0.023195, 0.949753, -0.052336, -0.308594, 0.049774, 0.99863, -0.016173, 0.309017, 0, 0.951057), c1 = CFrame.new(0, 0, 1.062003, 0, 0, -1, 0.6, 0.8, 0, 0.8, -0.6, 0) },
		{ k = "Weld", n = "Hold_CyanInlay2", h = 2, a = 2, b = 38, c0 = CFrame.new(0, 0, -0.717914, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldRidge2_1", h = 2, a = 2, b = 45, c0 = CFrame.new(-0.666938, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Head", h = 3, a = 3, b = 4, c0 = CFrame.new(0.167434, 1.22484, 0.074908, 0.807908, 0.052336, -0.58698, -0.042341, 0.99863, 0.030762, 0.587785, 0, 0.809017), c1 = CFrame.new(0, -0.934563, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldRidge3_2", h = 3, a = 3, b = 10, c0 = CFrame.new(0.560738, -0.000001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Leaf3", h = 3, a = 3, b = 11, c0 = CFrame.new(-0.452325, 0.023705, -0.17156, 0.807908, 0.052336, -0.58698, -0.042341, 0.99863, 0.030762, 0.587785, 0, 0.809017), c1 = CFrame.new(0, 0, 1.13112, 0, 0, -1, 0.563337, 0.826227, 0, 0.826227, -0.563337, 0) },
		{ k = "Weld", n = "Hold_GoldRidge3_1", h = 3, a = 3, b = 17, c0 = CFrame.new(-0.560738, 0.000001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Leaf4", h = 3, a = 3, b = 23, c0 = CFrame.new(0.302716, -0.015865, 0.377763, 0.807908, 0.052336, -0.58698, -0.042341, 0.99863, 0.030762, 0.587785, 0, 0.809017), c1 = CFrame.new(0, 0, 1.13112, 0, 0, 1, -0.563337, 0.826227, 0, -0.826227, -0.563337, 0) },
		{ k = "Weld", n = "Hold_CyanInlay3", h = 3, a = 3, b = 41, c0 = CFrame.new(0, 0, -0.611714, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Eye", h = 4, a = 4, b = 7, c0 = CFrame.new(0, 0.127441, -0.909075, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Crown1", h = 4, a = 4, b = 14, c0 = CFrame.new(-0.526754, 0.807122, 0.12744, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.179732, 0, 0, -1, 0.972224, 0.234054, 0, 0.234054, -0.972224, 0) },
		{ k = "Weld", n = "Hold_CrownBrow1", h = 4, a = 4, b = 20, c0 = CFrame.new(-0.450289, 0.756147, -0.773138, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Crown2", h = 4, a = 4, b = 32, c0 = CFrame.new(0.526754, 0.807122, 0.12744, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.428779, 0.981148, -0.193256, 0, 0, 0, 1, -0.193256, -0.981148, 0) },
		{ k = "Weld", n = "Hold_CrownBrow2", h = 4, a = 4, b = 44, c0 = CFrame.new(0.450289, 0.756147, -0.773138, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShine", h = 5, a = 5, b = 30, c0 = CFrame.new(-0.016992, 0.16992, -0.059472, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 6, a = 6, b = 1, c0 = CFrame.new(0, 1.274404, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.089651, -1.536081, 0, 0.99863, 0.052336, 0, -0.052336, 0.99863, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootStem1", h = 6, a = 6, b = 15, c0 = CFrame.new(0, 0.743402, 1.019523, -1, 0, 0, 0, 0.942627, 0.333847, 0, 0.333847, -0.942627), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootStem2", h = 6, a = 6, b = 21, c0 = CFrame.new(0.882933, 0.743402, -0.509761, 0.5, 0.28912, -0.816339, 0, 0.942627, 0.333847, 0.866025, -0.166924, 0.471314), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootStem3", h = 6, a = 6, b = 31, c0 = CFrame.new(-0.882933, 0.743402, -0.509761, 0.5, -0.28912, 0.816339, 0, 0.942627, 0.333847, -0.866025, -0.166924, 0.471314), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Pupil", h = 7, a = 7, b = 5, c0 = CFrame.new(0, 0, -0.110448, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafBlade2", h = 8, a = 8, b = 9, c0 = CFrame.new(0, 0.237938, -1.788683, 0, 0, 1, -0.950352, 0.311176, 0, -0.311176, -0.950352, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafVein2", h = 9, a = 9, b = 12, c0 = CFrame.new(0, 0, -0.390817, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafPoint2", h = 9, a = 9, b = 43, c0 = CFrame.new(0, 1.401844, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafBlade3", h = 11, a = 11, b = 18, c0 = CFrame.new(0, 0.270446, -1.846339, 0, 0, -1, 0.935363, 0.353689, 0, 0.353689, -0.935363, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_CrownPoint1", h = 14, a = 14, b = 13, c0 = CFrame.new(0, -0.007598, -1.476996, 0, 0, -1, 0.999673, -0.025551, 0, -0.025551, -0.999673, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_CrownVein1", h = 14, a = 14, b = 46, c0 = CFrame.new(0, -0.382321, -0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot1", h = 15, a = 15, b = 16, c0 = CFrame.new(0, -0.040043, -1.095758, -1, 0, 0, 0, 0.942627, 0.333847, 0, 0.333847, -0.942627), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafVein3", h = 18, a = 18, b = 19, c0 = CFrame.new(0, 0, -0.390817, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafPoint3", h = 18, a = 18, b = 25, c0 = CFrame.new(0, 1.401844, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot2", h = 21, a = 21, b = 22, c0 = CFrame.new(0, -0.040043, -1.095758, -1, 0, 0, 0, 0.942627, 0.333847, 0, 0.333847, -0.942627), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafBlade4", h = 23, a = 23, b = 37, c0 = CFrame.new(0, 0.270446, -1.846339, 0, 0, 1, -0.935363, 0.353689, 0, -0.353689, -0.935363, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafBlade1", h = 27, a = 27, b = 29, c0 = CFrame.new(0, 0.237938, -1.788683, 0, 0, -1, 0.950352, 0.311176, 0, 0.311176, -0.950352, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafPoint1", h = 29, a = 29, b = 28, c0 = CFrame.new(0, 1.401844, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafVein1", h = 29, a = 29, b = 42, c0 = CFrame.new(0, 0, -0.390817, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot3", h = 31, a = 31, b = 40, c0 = CFrame.new(0, -0.040043, -1.095758, -1, 0, 0, 0, 0.942627, 0.333847, 0, 0.333847, -0.942627), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_CrownVein2", h = 32, a = 32, b = 33, c0 = CFrame.new(0, -0.382321, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_CrownPoint2", h = 32, a = 32, b = 35, c0 = CFrame.new(0.020003, 0, -1.725467, 0.997735, 0.067269, 0, 0, 0, 1, 0.067269, -0.997735, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafVein4", h = 37, a = 37, b = 36, c0 = CFrame.new(0, 0, -0.390817, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafPoint4", h = 37, a = 37, b = 47, c0 = CFrame.new(0, 1.401843, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
