--!strict
--==============================================================================
-- PLANT FORM: Astralhorn (Starbloom plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Starbloom plants/Astralhorn" by a read-only generator on 2026-10-03. The original
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
	Source = "Starbloom plants/Astralhorn", Kind = "plant", Yaw = 0,
	Size = Vector3.new(3.262512, 8.3925, 5.672253), Height = 8.3925, PartCount = 49,
	Base = 3,
	Unit = 4.5, ModelScale = 1,
	Attributes = {},
	Parts = {
		{ n = "AntlerLower2", s = "Block", z = Vector3.new(0.2475, 0.3375, 1.317053), cf = CFrame.new(0.584999, 6.412499, -0.720001, -0.496139, -0.826337, -0.266486, 0, 0.306925, -0.951734, 0.868243, -0.472192, -0.152277), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 1
		{ n = "AntlerFork2", s = "Block", z = Vector3.new(0.2025, 0.27, 1.257522), cf = CFrame.new(1.028252, 6.885, -0.576, -0.292617, -0.613338, -0.733616, 0, 0.767196, -0.641413, 0.95623, -0.187688, -0.224494), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 2
		{ n = "Footing", s = "Block", z = Vector3.new(1.26, 0.18, 1.35), cf = CFrame.new(0, 0.09, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(29, 27, 54), m = Enum.Material.Plastic, t = 1, cs = false }, -- 3
		{ n = "ForkTip2", s = "Wedge", z = Vector3.new(0.3825, 0.585, 0.405), cf = CFrame.new(1.440002, 7.3125, -0.450001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(88, 54, 136), m = Enum.Material.Plastic }, -- 4
		{ n = "LeafNeck", s = "Block", z = Vector3.new(1.125, 1.62, 1.215), cf = CFrame.new(0, 4.23, -0.450001, 1, 0, 0, 0, 0.990268, 0.139173, 0, -0.139173, 0.990268), c = Color3.fromRGB(50, 38, 91), m = Enum.Material.Plastic }, -- 5
		{ n = "CarvedHead", s = "Block", z = Vector3.new(1.305, 1.305, 1.44), cf = CFrame.new(0, 5.31, -0.810001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(50, 38, 91), m = Enum.Material.Plastic }, -- 6
		{ n = "GuardianBody", s = "Block", z = Vector3.new(1.89, 1.62, 2.79), cf = CFrame.new(0, 2.97, 0.630001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(65, 43, 111), m = Enum.Material.Plastic }, -- 7
		{ n = "ArmourPlate2", s = "Block", z = Vector3.new(1.125, 0.45, 1.35), cf = CFrame.new(0.720001, 3.465, -0.022499, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(88, 54, 136), m = Enum.Material.Plastic }, -- 8
		{ n = "ArmourSeam2", s = "Block", z = Vector3.new(0.108, 0.081, 1.08), cf = CFrame.new(0.620705, 3.651743, -0.022499, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(130, 230, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 9
		{ n = "RootFoot1", s = "Block", z = Vector3.new(0.81, 0.63, 1.17), cf = CFrame.new(-1.102501, 0.315, -0.404999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 10
		{ n = "ArmourPlate4", s = "Block", z = Vector3.new(1.125, 0.45, 1.35), cf = CFrame.new(0.720001, 3.465, 1.170002, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(65, 43, 111), m = Enum.Material.Plastic }, -- 11
		{ n = "GoldBrow1", s = "Block", z = Vector3.new(0.4725, 0.1125, 0.2925), cf = CFrame.new(-0.323997, 5.7645, -1.516502, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 12
		{ n = "TailStem", s = "Block", z = Vector3.new(0.315, 0.3825, 1.268071), cf = CFrame.new(0, 3.3075, 2.272503, -1, 0, 0, 0, 0.992877, -0.119145, 0, -0.119145, -0.992877), c = Color3.fromRGB(50, 38, 91), m = Enum.Material.Plastic }, -- 13
		{ n = "TailLeaf", s = "Wedge", z = Vector3.new(0.81, 0.585, 1.08), cf = CFrame.new(0, 3.51, 2.790001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 14
		{ n = "EyeL", s = "Block", z = Vector3.new(0.2475, 0.126, 0.09), cf = CFrame.new(0.328499, 5.5575, -1.561501, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(130, 230, 255), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 15
		{ n = "AntlerUpper2", s = "Block", z = Vector3.new(0.2115, 0.3015, 1.171222), cf = CFrame.new(0.618752, 7.469999, -0.540001, -0.588172, 0.772661, 0.238848, 0, 0.295336, -0.955394, -0.808736, -0.561935, -0.173708), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 16
		{ n = "AntlerTip2", s = "Wedge", z = Vector3.new(0.405, 0.72, 0.405), cf = CFrame.new(0.495003, 8.0325, -0.450001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(88, 54, 136), m = Enum.Material.Plastic }, -- 17
		{ n = "GoldBrow2", s = "Block", z = Vector3.new(0.4725, 0.1125, 0.2925), cf = CFrame.new(0.323997, 5.7645, -1.516502, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 18
		{ n = "AntlerLower1", s = "Block", z = Vector3.new(0.2475, 0.3375, 1.317053), cf = CFrame.new(-0.584999, 6.412499, -0.720001, -0.496139, 0.826337, 0.266486, 0, 0.306925, -0.951734, -0.868243, -0.472192, -0.152277), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 19
		{ n = "AntlerUpper1", s = "Block", z = Vector3.new(0.2115, 0.3015, 1.171222), cf = CFrame.new(-0.618752, 7.469999, -0.540001, -0.588172, -0.772661, -0.238848, 0, 0.295336, -0.955394, 0.808736, -0.561935, -0.173708), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 20
		{ n = "ArmourPlate3", s = "Block", z = Vector3.new(1.125, 0.45, 1.35), cf = CFrame.new(-0.720001, 3.465, 1.170002, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(65, 43, 111), m = Enum.Material.Plastic }, -- 21
		{ n = "AntlerFork1", s = "Block", z = Vector3.new(0.2025, 0.27, 1.257522), cf = CFrame.new(-1.028252, 6.885, -0.576, -0.292617, 0.613338, 0.733616, 0, 0.767196, -0.641413, -0.95623, -0.187688, -0.224494), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 22
		{ n = "ForkTip1", s = "Wedge", z = Vector3.new(0.3825, 0.585, 0.405), cf = CFrame.new(-1.440002, 7.3125, -0.450001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(88, 54, 136), m = Enum.Material.Plastic }, -- 23
		{ n = "RootFoot3", s = "Block", z = Vector3.new(0.81, 0.63, 1.17), cf = CFrame.new(-1.102501, 0.315, 1.575001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 24
		{ n = "UpperRoot3", s = "Block", z = Vector3.new(0.5175, 0.63, 1.416118), cf = CFrame.new(-0.888748, 2.295, 1.69875, 0.98733, 0.013934, -0.158065, -0.158678, 0.086701, -0.983516, 0, 0.996137, 0.087814), c = Color3.fromRGB(65, 43, 111), m = Enum.Material.Plastic }, -- 25
		{ n = "LowerRoot3", s = "Block", z = Vector3.new(0.3825, 0.495, 1.368402), cf = CFrame.new(-1.046249, 1.0575, 1.665001, 0.995741, -0.013455, -0.091211, -0.092198, -0.145316, -0.98508, 0, 0.989294, -0.145938), c = Color3.fromRGB(50, 38, 91), m = Enum.Material.Plastic }, -- 26
		{ n = "AntlerVein1", s = "Block", z = Vector3.new(0.0765, 0.081, 0.851078), cf = CFrame.new(-0.718864, 6.362778, -0.643505, -0.496139, 0.826337, 0.266486, 0, 0.306925, -0.951734, -0.868243, -0.472192, -0.152277), c = Color3.fromRGB(130, 230, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 27
		{ n = "LowerRoot4", s = "Block", z = Vector3.new(0.3825, 0.495, 1.368402), cf = CFrame.new(1.046249, 1.0575, 1.665001, 0.995741, 0.013455, 0.091211, 0.092198, -0.145316, -0.98508, 0, 0.989294, -0.145938), c = Color3.fromRGB(50, 38, 91), m = Enum.Material.Plastic }, -- 28
		{ n = "RootFoot4", s = "Block", z = Vector3.new(0.81, 0.63, 1.17), cf = CFrame.new(1.102501, 0.315, 1.575001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 29
		{ n = "UpperRoot4", s = "Block", z = Vector3.new(0.5175, 0.63, 1.416118), cf = CFrame.new(0.888748, 2.295, 1.69875, 0.98733, -0.013934, 0.158065, 0.158678, 0.086701, -0.983516, 0, 0.996137, 0.087814), c = Color3.fromRGB(65, 43, 111), m = Enum.Material.Plastic }, -- 30
		{ n = "ArmourPlate1", s = "Block", z = Vector3.new(1.125, 0.45, 1.35), cf = CFrame.new(-0.720001, 3.465, -0.022499, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(88, 54, 136), m = Enum.Material.Plastic }, -- 31
		{ n = "ArmourSeam1", s = "Block", z = Vector3.new(0.108, 0.081, 1.08), cf = CFrame.new(-0.620705, 3.651743, -0.022499, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(130, 230, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 32
		{ n = "AntlerTip1", s = "Wedge", z = Vector3.new(0.405, 0.72, 0.405), cf = CFrame.new(-0.495003, 8.0325, -0.450001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(88, 54, 136), m = Enum.Material.Plastic }, -- 33
		{ n = "LowerRoot2", s = "Block", z = Vector3.new(0.3825, 0.495, 1.368402), cf = CFrame.new(1.046249, 1.0575, -0.314999, 0.995741, 0.013455, 0.091211, 0.092198, -0.145316, -0.98508, 0, 0.989294, -0.145938), c = Color3.fromRGB(50, 38, 91), m = Enum.Material.Plastic }, -- 34
		{ n = "RootFoot2", s = "Block", z = Vector3.new(0.81, 0.63, 1.17), cf = CFrame.new(1.102501, 0.315, -0.404999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 35
		{ n = "UpperRoot2", s = "Block", z = Vector3.new(0.5175, 0.63, 1.416118), cf = CFrame.new(0.888748, 2.295001, -0.28125, 0.98733, -0.013934, 0.158065, 0.158678, 0.086701, -0.983516, 0, 0.996137, 0.087814), c = Color3.fromRGB(65, 43, 111), m = Enum.Material.Plastic }, -- 36
		{ n = "GoldCollar", s = "Block", z = Vector3.new(1.35, 0.315, 1.35), cf = CFrame.new(0, 4.095001, -0.450001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 37
		{ n = "AntlerVein2", s = "Block", z = Vector3.new(0.0765, 0.081, 0.851078), cf = CFrame.new(0.718864, 6.362778, -0.643505, -0.496139, -0.826337, -0.266486, 0, 0.306925, -0.951734, 0.868243, -0.472192, -0.152277), c = Color3.fromRGB(130, 230, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 38
		{ n = "LeafEar1", s = "Block", z = Vector3.new(0.405, 0.81, 0.495), cf = CFrame.new(-0.764999, 5.445, -0.450001, 0.573576, -0.819152, 0, 0.819152, 0.573576, 0, 0, 0, 1), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 39
		{ n = "ArmourSeam4", s = "Block", z = Vector3.new(0.108, 0.081, 1.08), cf = CFrame.new(0.620705, 3.651743, 1.170002, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(130, 230, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 40
		{ n = "LongMuzzle", s = "Block", z = Vector3.new(0.99, 0.72, 1.125), cf = CFrame.new(0, 4.9725, -1.642502, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(65, 43, 111), m = Enum.Material.Plastic }, -- 41
		{ n = "DarkNose", s = "Block", z = Vector3.new(0.81, 0.405, 0.2475), cf = CFrame.new(0, 5.04, -2.218502, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(29, 27, 54), m = Enum.Material.SmoothPlastic, st = false }, -- 42
		{ n = "LeafEar2", s = "Block", z = Vector3.new(0.405, 0.81, 0.495), cf = CFrame.new(0.764999, 5.445, -0.450001, 0.573576, 0.819152, 0, -0.819152, 0.573576, 0, 0, 0, 1), c = Color3.fromRGB(239, 215, 151), m = Enum.Material.Plastic }, -- 43
		{ n = "EarVein2", s = "Block", z = Vector3.new(0.081, 0.54, 0.081), cf = CFrame.new(0.764999, 5.445, -0.684002, 0.573576, 0.819152, 0, -0.819152, 0.573576, 0, 0, 0, 1), c = Color3.fromRGB(130, 230, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 44
		{ n = "LowerRoot1", s = "Block", z = Vector3.new(0.3825, 0.495, 1.368402), cf = CFrame.new(-1.046249, 1.0575, -0.314999, 0.995741, -0.013455, -0.091211, -0.092198, -0.145316, -0.98508, 0, 0.989294, -0.145938), c = Color3.fromRGB(50, 38, 91), m = Enum.Material.Plastic }, -- 45
		{ n = "ArmourSeam3", s = "Block", z = Vector3.new(0.108, 0.081, 1.08), cf = CFrame.new(-0.620705, 3.651743, 1.170002, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(130, 230, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 46
		{ n = "EarVein1", s = "Block", z = Vector3.new(0.081, 0.54, 0.081), cf = CFrame.new(-0.764999, 5.445, -0.684002, 0.573576, -0.819152, 0, 0.819152, 0.573576, 0, 0, 0, 1), c = Color3.fromRGB(130, 230, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 47
		{ n = "UpperRoot1", s = "Block", z = Vector3.new(0.5175, 0.63, 1.416118), cf = CFrame.new(-0.888748, 2.295001, -0.28125, 0.98733, 0.013934, -0.158065, -0.158678, 0.086701, -0.983516, 0, 0.996137, 0.087814), c = Color3.fromRGB(65, 43, 111), m = Enum.Material.Plastic }, -- 48
		{ n = "EyeR", s = "Block", z = Vector3.new(0.2475, 0.126, 0.09), cf = CFrame.new(-0.328499, 5.5575, -1.561501, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(130, 230, 255), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 49
	},
	Joints = {
		{ k = "Motor6D", n = "HornFork2", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, -0.118206, -0.496139, 0, 0.868243, -0.826337, 0.306925, -0.472192, -0.266486, -0.951734, -0.152277), c1 = CFrame.new(0, 0, 0.561262, -0.292617, 0, 0.95623, -0.613338, 0.767196, -0.187688, -0.733616, -0.641413, -0.224494) },
		{ k = "Motor6D", n = "HornUpper2", h = 1, a = 1, b = 16, c0 = CFrame.new(0, 0, -0.591027, -0.496139, 0, 0.868243, -0.826337, 0.306925, -0.472192, -0.266486, -0.951734, -0.152277), c1 = CFrame.new(0, 0, 0.518111, -0.588172, 0, -0.808736, 0.772661, 0.295335, -0.561935, 0.238848, -0.955394, -0.173708) },
		{ k = "Weld", n = "Hold_AntlerVein2", h = 1, a = 1, b = 38, c0 = CFrame.new(0, -0.162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ForkTip2", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 0.051786, -0.604557, -0.292617, 0, 0.95623, -0.613338, 0.767196, -0.187688, -0.733616, -0.641413, -0.224494), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 3, a = 3, b = 7, c0 = CFrame.new(0, 2.115, 0.63, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.765, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot1", h = 3, a = 3, b = 10, c0 = CFrame.new(-1.1025, 0.225, -0.405, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot3", h = 3, a = 3, b = 24, c0 = CFrame.new(-1.1025, 0.225, 1.575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot4", h = 3, a = 3, b = 29, c0 = CFrame.new(1.1025, 0.225, 1.575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot2", h = 3, a = 3, b = 35, c0 = CFrame.new(1.1025, 0.225, -0.405, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Head", h = 5, a = 5, b = 6, c0 = CFrame.new(0, 0.58834, -0.144525, 1, 0, 0, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268), c1 = CFrame.new(0, -0.517499, 0.135, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldCollar", h = 5, a = 5, b = 37, c0 = CFrame.new(0, -0.133686, -0.018788, 1, 0, 0, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HornLower2", h = 6, a = 6, b = 1, c0 = CFrame.new(0.4275, 0.54, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.591026, -0.496139, 0, 0.868243, -0.826337, 0.306925, -0.472192, -0.266486, -0.951734, -0.152277) },
		{ k = "Weld", n = "Hold_GoldBrow1", h = 6, a = 6, b = 12, c0 = CFrame.new(-0.324, 0.4545, -0.7065, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeL", h = 6, a = 6, b = 15, c0 = CFrame.new(0.3285, 0.2475, -0.7515, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldBrow2", h = 6, a = 6, b = 18, c0 = CFrame.new(0.324, 0.4545, -0.7065, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HornLower1", h = 6, a = 6, b = 19, c0 = CFrame.new(-0.4275, 0.54, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.591026, -0.496139, 0, -0.868243, 0.826337, 0.306925, -0.472192, 0.266486, -0.951734, -0.152277) },
		{ k = "Motor6D", n = "Ear1", h = 6, a = 6, b = 39, c0 = CFrame.new(-0.585, 0.1125, 0.36, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.084813, -0.160353, 0, 0.573576, 0.819152, 0, -0.819152, 0.573576, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LongMuzzle", h = 6, a = 6, b = 41, c0 = CFrame.new(0, -0.3375, -0.8325, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ear2", h = 6, a = 6, b = 43, c0 = CFrame.new(0.585, 0.1125, 0.36, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.084813, -0.160353, 0, 0.573576, -0.819152, 0, 0.819152, 0.573576, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeR", h = 6, a = 6, b = 49, c0 = CFrame.new(-0.3285, 0.2475, -0.7515, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 7, a = 7, b = 5, c0 = CFrame.new(0, 0.6075, -0.945, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.664938, 0.042876, 1, 0, 0, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268) },
		{ k = "Motor6D", n = "Armour2", h = 7, a = 7, b = 8, c0 = CFrame.new(0.315, 0.4725, -0.6525, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.368157, 0.17027, 0, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Armour4", h = 7, a = 7, b = 11, c0 = CFrame.new(0.315, 0.4725, 0.54, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.368157, 0.17027, 0, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail", h = 7, a = 7, b = 13, c0 = CFrame.new(0, 0.27, 1.08, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.566535, -1, 0, 0, 0, 0.992877, -0.119145, 0, -0.119145, -0.992877) },
		{ k = "Motor6D", n = "Armour3", h = 7, a = 7, b = 21, c0 = CFrame.new(-0.315, 0.4725, 0.54, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.368157, 0.17027, 0, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Armour1", h = 7, a = 7, b = 31, c0 = CFrame.new(-0.315, 0.4725, -0.6525, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.368157, 0.17027, 0, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ArmourSeam2", h = 8, a = 8, b = 9, c0 = CFrame.new(0, 0.2115, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LowerLeg1", h = 10, a = 10, b = 45, c0 = CFrame.new(0, 0.135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.616701, 0.995741, -0.092198, 0, -0.013455, -0.145316, 0.989294, -0.091211, -0.98508, -0.145938) },
		{ k = "Weld", n = "Hold_ArmourSeam4", h = 11, a = 11, b = 40, c0 = CFrame.new(0, 0.2115, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_TailLeaf", h = 13, a = 13, b = 14, c0 = CFrame.new(0, 0.1394, -0.537941, -1, 0, 0, 0, 0.992877, -0.119145, 0, -0.119145, -0.992877), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AntlerTip2", h = 16, a = 16, b = 17, c0 = CFrame.new(0, 0.019935, -0.582601, -0.588172, 0, -0.808736, 0.772661, 0.295335, -0.561935, 0.238848, -0.955394, -0.173708), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HornUpper1", h = 19, a = 19, b = 20, c0 = CFrame.new(0, 0, -0.591027, -0.496139, 0, -0.868243, 0.826337, 0.306925, -0.472192, 0.266486, -0.951734, -0.152277), c1 = CFrame.new(0, 0, 0.518111, -0.588172, 0, 0.808736, -0.772661, 0.295335, -0.561935, -0.238848, -0.955394, -0.173708) },
		{ k = "Motor6D", n = "HornFork1", h = 19, a = 19, b = 22, c0 = CFrame.new(0, 0, -0.118206, -0.496139, 0, -0.868243, 0.826337, 0.306925, -0.472192, 0.266486, -0.951734, -0.152277), c1 = CFrame.new(0, 0, 0.561262, -0.292617, 0, -0.95623, 0.613338, 0.767196, -0.187688, 0.733616, -0.641413, -0.224494) },
		{ k = "Weld", n = "Hold_AntlerVein1", h = 19, a = 19, b = 27, c0 = CFrame.new(0, -0.162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AntlerTip1", h = 20, a = 20, b = 33, c0 = CFrame.new(0, 0.019935, -0.582601, -0.588172, 0, 0.808736, -0.772661, 0.295335, -0.561935, -0.238848, -0.955394, -0.173708), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ArmourSeam3", h = 21, a = 21, b = 46, c0 = CFrame.new(0, 0.2115, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ForkTip1", h = 22, a = 22, b = 23, c0 = CFrame.new(0, 0.051786, -0.604557, -0.292617, 0, -0.95623, 0.613338, 0.767196, -0.187688, 0.733616, -0.641413, -0.224494), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LowerLeg3", h = 24, a = 24, b = 26, c0 = CFrame.new(0, 0.135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.616701, 0.995741, -0.092198, 0, -0.013455, -0.145316, 0.989294, -0.091211, -0.98508, -0.145938) },
		{ k = "Motor6D", n = "UpperLeg3", h = 26, a = 26, b = 25, c0 = CFrame.new(0, 0, -0.616701, 0.995741, -0.092198, 0, -0.013455, -0.145316, 0.989294, -0.091211, -0.98508, -0.145938), c1 = CFrame.new(0, 0, 0.640559, 0.98733, -0.158678, 0, 0.013934, 0.086701, 0.996137, -0.158065, -0.983516, 0.087814) },
		{ k = "Motor6D", n = "UpperLeg4", h = 28, a = 28, b = 30, c0 = CFrame.new(0, 0, -0.616701, 0.995741, 0.092198, 0, 0.013455, -0.145316, 0.989294, 0.091211, -0.98508, -0.145938), c1 = CFrame.new(0, 0, 0.640559, 0.98733, 0.158678, 0, -0.013934, 0.086701, 0.996137, 0.158065, -0.983516, 0.087814) },
		{ k = "Motor6D", n = "LowerLeg4", h = 29, a = 29, b = 28, c0 = CFrame.new(0, 0.135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.616701, 0.995741, 0.092198, 0, 0.013455, -0.145316, 0.989294, 0.091211, -0.98508, -0.145938) },
		{ k = "Weld", n = "Hold_ArmourSeam1", h = 31, a = 31, b = 32, c0 = CFrame.new(0, 0.2115, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "UpperLeg2", h = 34, a = 34, b = 36, c0 = CFrame.new(0, 0, -0.616701, 0.995741, 0.092198, 0, 0.013455, -0.145316, 0.989294, 0.091211, -0.98508, -0.145938), c1 = CFrame.new(0, 0, 0.640559, 0.98733, 0.158678, 0, -0.013934, 0.086701, 0.996137, 0.158065, -0.983516, 0.087814) },
		{ k = "Motor6D", n = "LowerLeg2", h = 35, a = 35, b = 34, c0 = CFrame.new(0, 0.135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.616701, 0.995741, 0.092198, 0, 0.013455, -0.145316, 0.989294, 0.091211, -0.98508, -0.145938) },
		{ k = "Weld", n = "Hold_EarVein1", h = 39, a = 39, b = 47, c0 = CFrame.new(0, 0, -0.234, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_DarkNose", h = 41, a = 41, b = 42, c0 = CFrame.new(0, 0.0675, -0.576, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EarVein2", h = 43, a = 43, b = 44, c0 = CFrame.new(0, 0, -0.234, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "UpperLeg1", h = 45, a = 45, b = 48, c0 = CFrame.new(0, 0, -0.616701, 0.995741, -0.092198, 0, -0.013455, -0.145316, 0.989294, -0.091211, -0.98508, -0.145938), c1 = CFrame.new(0, 0, 0.640559, 0.98733, -0.158678, 0, 0.013934, 0.086701, 0.996137, -0.158065, -0.983516, 0.087814) },
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
