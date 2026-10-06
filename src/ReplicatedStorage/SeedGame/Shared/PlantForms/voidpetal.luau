--!strict
--==============================================================================
-- PLANT FORM: Voidpetal (Starbloom plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Starbloom plants/Voidpetal" by a read-only generator on 2026-10-03. The original
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
	Source = "Starbloom plants/Voidpetal", Kind = "plant", Yaw = 0,
	Size = Vector3.new(4.576263, 3.95537, 4.169655), Height = 3.95537, PartCount = 47,
	Base = 4,
	Unit = 4.5, ModelScale = 1,
	Attributes = {},
	Parts = {
		{ n = "CrouchedBody", s = "Block", z = Vector3.new(1.89, 1.125, 1.575), cf = CFrame.new(0, 2.07, 0.18, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(51, 36, 87), m = Enum.Material.Plastic }, -- 1
		{ n = "PetalPoint6", s = "Wedge", z = Vector3.new(0.9, 0.72, 0.45), cf = CFrame.new(1.735542, 2.835, -0.901688, -0.34202, 0.813798, -0.469846, 0, -0.5, -0.866025, -0.939692, -0.296198, 0.17101), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 2
		{ n = "CloakPetal6", s = "Block", z = Vector3.new(1.035, 1.8, 0.405), cf = CFrame.new(0.929886, 3.33, -0.608452, -0.34202, 0.813798, -0.469846, 0, -0.5, -0.866025, -0.939693, -0.296198, 0.17101), c = Color3.fromRGB(51, 36, 87), m = Enum.Material.Plastic }, -- 3
		{ n = "Footing", s = "Block", z = Vector3.new(1.17, 0.18, 1.17), cf = CFrame.new(0, 0.09, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 23, 42), m = Enum.Material.Plastic, t = 1, cs = false }, -- 4
		{ n = "ShadowHead", s = "Block", z = Vector3.new(1.395, 1.44, 1.17), cf = CFrame.new(0, 3.15, -0.27, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 23, 42), m = Enum.Material.Plastic }, -- 5
		{ n = "CloakPetal1", s = "Block", z = Vector3.new(1.035, 1.8, 0.405), cf = CFrame.new(-0.929886, 3.33, -0.608452, -0.34202, -0.813798, 0.469846, 0, -0.5, -0.866025, 0.939693, -0.296198, 0.17101), c = Color3.fromRGB(42, 30, 70), m = Enum.Material.Plastic }, -- 6
		{ n = "PetalVein1", s = "Block", z = Vector3.new(0.081, 1.305, 0.081), cf = CFrame.new(-0.986298, 3.523973, -0.628983, -0.34202, -0.813798, 0.469846, 0, -0.5, -0.866025, 0.939692, -0.296198, 0.17101), c = Color3.fromRGB(117, 220, 250), m = Enum.Material.Neon, st = false, cs = false }, -- 7
		{ n = "CloakPetal5", s = "Block", z = Vector3.new(1.035, 1.8, 0.405), cf = CFrame.new(0.904015, 3.33, 0.132492, 0.406737, 0.791154, -0.456773, 0, -0.5, -0.866025, -0.913545, 0.352244, -0.203368), c = Color3.fromRGB(42, 30, 70), m = Enum.Material.Plastic }, -- 8
		{ n = "LeafArm2", s = "Block", z = Vector3.new(0.315, 0.3825, 0.867892), cf = CFrame.new(1.136253, 2.1825, -0.404999, 0.624695, 0.143838, -0.767507, 0, 0.982888, 0.184202, 0.780869, -0.11507, 0.614006), c = Color3.fromRGB(75, 45, 121), m = Enum.Material.Plastic }, -- 9
		{ n = "GoldHook2", s = "Wedge", z = Vector3.new(0.585, 0.99, 0.63), cf = CFrame.new(1.485001, 1.8225, -0.674999, 0.965926, -0.258819, 0, 0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 10
		{ n = "EyeR", s = "Block", z = Vector3.new(0.4275, 0.108, 0.09), cf = CFrame.new(-0.337502, 3.285, -0.875252, 0.939693, 0.34202, 0, -0.34202, 0.939693, 0, 0, 0, 1), c = Color3.fromRGB(117, 220, 250), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 11
		{ n = "RootFoot2", s = "Block", z = Vector3.new(0.81, 0.54, 1.08), cf = CFrame.new(1.620003, 0.27, -0.922501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 12
		{ n = "UpperRoot2", s = "Block", z = Vector3.new(0.36, 0.4275, 1.194652), cf = CFrame.new(1.057503, 1.56375, -0.57375, -0.416655, 0.752798, 0.509601, 0, 0.560577, -0.828102, -0.909065, -0.345033, -0.233567), c = Color3.fromRGB(51, 36, 87), m = Enum.Material.Plastic }, -- 13
		{ n = "LowerRoot2", s = "Block", z = Vector3.new(0.2925, 0.3825, 0.944062), cf = CFrame.new(1.473755, 0.765, -0.810001, -0.609711, 0.705371, 0.36153, 0, 0.456118, -0.889919, -0.792624, -0.542593, -0.2781), c = Color3.fromRGB(75, 45, 121), m = Enum.Material.Plastic }, -- 14
		{ n = "RootFoot4", s = "Block", z = Vector3.new(0.81, 0.54, 1.08), cf = CFrame.new(1.620003, 0.27, 1.282501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 15
		{ n = "LowerRoot4", s = "Block", z = Vector3.new(0.2925, 0.3825, 0.944062), cf = CFrame.new(1.473755, 0.765, 1.170002, 0.609711, 0.705372, 0.36153, 0, 0.456118, -0.88992, -0.792624, 0.542593, 0.2781), c = Color3.fromRGB(75, 45, 121), m = Enum.Material.Plastic }, -- 16
		{ n = "CloakPetal4", s = "Block", z = Vector3.new(1.035, 1.8, 0.405), cf = CFrame.new(0.370697, 3.33, 0.647511, 0.927184, 0.324419, -0.187303, 0, -0.5, -0.866025, -0.374607, 0.802965, -0.463592), c = Color3.fromRGB(51, 36, 87), m = Enum.Material.Plastic }, -- 17
		{ n = "PetalPoint4", s = "Wedge", z = Vector3.new(0.9, 0.72, 0.45), cf = CFrame.new(0.691872, 2.835, 1.442448, 0.927184, 0.324419, -0.187303, 0, -0.5, -0.866025, -0.374607, 0.802965, -0.463592), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 18
		{ n = "PetalPoint1", s = "Wedge", z = Vector3.new(0.9, 0.72, 0.45), cf = CFrame.new(-1.735542, 2.835, -0.901688, -0.34202, -0.813798, 0.469846, 0, -0.5, -0.866025, 0.939692, -0.296198, 0.17101), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 19
		{ n = "CloakPetal2", s = "Block", z = Vector3.new(1.035, 1.8, 0.405), cf = CFrame.new(-0.904015, 3.33, 0.132492, 0.406737, -0.791154, 0.456773, 0, -0.5, -0.866025, 0.913545, 0.352244, -0.203368), c = Color3.fromRGB(51, 36, 87), m = Enum.Material.Plastic }, -- 20
		{ n = "RootFoot1", s = "Block", z = Vector3.new(0.81, 0.54, 1.08), cf = CFrame.new(-1.620003, 0.27, -0.922501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 21
		{ n = "LowerRoot1", s = "Block", z = Vector3.new(0.2925, 0.3825, 0.944062), cf = CFrame.new(-1.473755, 0.765, -0.810001, -0.609711, -0.705371, -0.36153, 0, 0.456118, -0.889919, 0.792624, -0.542593, -0.2781), c = Color3.fromRGB(75, 45, 121), m = Enum.Material.Plastic }, -- 22
		{ n = "UpperRoot1", s = "Block", z = Vector3.new(0.36, 0.4275, 1.194652), cf = CFrame.new(-1.057503, 1.56375, -0.57375, -0.416655, -0.752798, -0.509601, 0, 0.560577, -0.828102, 0.909065, -0.345033, -0.233567), c = Color3.fromRGB(51, 36, 87), m = Enum.Material.Plastic }, -- 23
		{ n = "PetalPoint5", s = "Wedge", z = Vector3.new(0.9, 0.72, 0.45), cf = CFrame.new(1.687256, 2.835, 0.481213, 0.406737, 0.791154, -0.456773, 0, -0.5, -0.866026, -0.913545, 0.352244, -0.203368), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 24
		{ n = "EyeShine1", s = "Block", z = Vector3.new(0.0585, 0.054, 0.0405), cf = CFrame.new(-0.337502, 3.2895, -0.93375, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(215, 250, 255), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 25
		{ n = "MaskCheek2", s = "Wedge", z = Vector3.new(0.495, 1.26, 0.72), cf = CFrame.new(0.720001, 3.015, -0.517502, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(75, 45, 121), m = Enum.Material.Plastic }, -- 26
		{ n = "CloakPetal3", s = "Block", z = Vector3.new(1.035, 1.8, 0.405), cf = CFrame.new(-0.370697, 3.33, 0.647511, 0.927184, -0.324419, 0.187303, 0, -0.5, -0.866025, 0.374607, 0.802965, -0.463592), c = Color3.fromRGB(42, 30, 70), m = Enum.Material.Plastic }, -- 27
		{ n = "PetalPoint3", s = "Wedge", z = Vector3.new(0.9, 0.72, 0.45), cf = CFrame.new(-0.691872, 2.835, 1.442448, 0.927184, -0.324419, 0.187303, 0, -0.5, -0.866025, 0.374607, 0.802965, -0.463592), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 28
		{ n = "PetalVein4", s = "Block", z = Vector3.new(0.081, 1.305, 0.081), cf = CFrame.new(0.393181, 3.523973, 0.703167, 0.927184, 0.324419, -0.187303, 0, -0.5, -0.866025, -0.374607, 0.802965, -0.463592), c = Color3.fromRGB(117, 220, 250), m = Enum.Material.Neon, st = false, cs = false }, -- 29
		{ n = "EyeL", s = "Block", z = Vector3.new(0.4275, 0.108, 0.09), cf = CFrame.new(0.337502, 3.285, -0.875252, 0.939693, -0.34202, 0, 0.34202, 0.939693, 0, 0, 0, 1), c = Color3.fromRGB(117, 220, 250), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 30
		{ n = "PetalVein5", s = "Block", z = Vector3.new(0.081, 1.305, 0.081), cf = CFrame.new(0.958855, 3.523973, 0.156906, 0.406737, 0.791154, -0.456773, 0, -0.5, -0.866026, -0.913545, 0.352244, -0.203368), c = Color3.fromRGB(117, 220, 250), m = Enum.Material.Neon, st = false, cs = false }, -- 31
		{ n = "LowerRoot3", s = "Block", z = Vector3.new(0.2925, 0.3825, 0.944062), cf = CFrame.new(-1.473755, 0.765, 1.170002, 0.609711, -0.705372, -0.36153, 0, 0.456118, -0.88992, 0.792624, 0.542593, 0.2781), c = Color3.fromRGB(75, 45, 121), m = Enum.Material.Plastic }, -- 32
		{ n = "RootFoot3", s = "Block", z = Vector3.new(0.81, 0.54, 1.08), cf = CFrame.new(-1.620003, 0.27, 1.282501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 33
		{ n = "UpperRoot3", s = "Block", z = Vector3.new(0.36, 0.4275, 1.194652), cf = CFrame.new(-1.057503, 1.56375, 0.93375, 0.416655, -0.752798, -0.509601, 0, 0.560578, -0.828102, 0.909065, 0.345033, 0.233567), c = Color3.fromRGB(51, 36, 87), m = Enum.Material.Plastic }, -- 34
		{ n = "LeafArm1", s = "Block", z = Vector3.new(0.315, 0.3825, 0.867892), cf = CFrame.new(-1.136253, 2.1825, -0.404999, 0.624695, -0.143838, 0.767507, 0, 0.982888, 0.184202, -0.780869, -0.11507, 0.614006), c = Color3.fromRGB(75, 45, 121), m = Enum.Material.Plastic }, -- 35
		{ n = "GoldHook1", s = "Wedge", z = Vector3.new(0.585, 0.99, 0.63), cf = CFrame.new(-1.485001, 1.8225, -0.674999, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 36
		{ n = "TailLeaf", s = "Block", z = Vector3.new(0.675, 0.54, 0.99), cf = CFrame.new(0, 2.115, 1.799999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(51, 36, 87), m = Enum.Material.Plastic }, -- 37
		{ n = "TailStem", s = "Block", z = Vector3.new(0.3375, 0.405, 1.129082), cf = CFrame.new(0, 2.07, 1.259998, -1, 0, 0, 0, 0.995893, -0.090536, 0, -0.090536, -0.995893), c = Color3.fromRGB(75, 45, 121), m = Enum.Material.Plastic }, -- 38
		{ n = "TailPoint", s = "Wedge", z = Vector3.new(0.585, 0.54, 0.81), cf = CFrame.new(0, 2.115, 2.294998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 39
		{ n = "PetalVein6", s = "Block", z = Vector3.new(0.081, 1.305, 0.081), cf = CFrame.new(0.986298, 3.523973, -0.628983, -0.34202, 0.813798, -0.469846, 0, -0.5, -0.866025, -0.939692, -0.296198, 0.17101), c = Color3.fromRGB(117, 220, 250), m = Enum.Material.Neon, st = false, cs = false }, -- 40
		{ n = "EyeShine2", s = "Block", z = Vector3.new(0.0585, 0.054, 0.0405), cf = CFrame.new(0.337502, 3.2895, -0.93375, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(215, 250, 255), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 41
		{ n = "PetalVein2", s = "Block", z = Vector3.new(0.081, 1.305, 0.081), cf = CFrame.new(-0.958855, 3.523973, 0.156906, 0.406737, -0.791154, 0.456773, 0, -0.5, -0.866026, 0.913545, 0.352244, -0.203368), c = Color3.fromRGB(117, 220, 250), m = Enum.Material.Neon, st = false, cs = false }, -- 42
		{ n = "GoldKeel", s = "Wedge", z = Vector3.new(0.198, 0.54, 0.2475), cf = CFrame.new(0, 2.925, -0.810001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 43
		{ n = "PetalPoint2", s = "Wedge", z = Vector3.new(0.9, 0.72, 0.45), cf = CFrame.new(-1.687256, 2.835, 0.481213, 0.406737, -0.791154, 0.456773, 0, -0.5, -0.866026, 0.913545, 0.352244, -0.203368), c = Color3.fromRGB(227, 204, 145), m = Enum.Material.Plastic }, -- 44
		{ n = "UpperRoot4", s = "Block", z = Vector3.new(0.36, 0.4275, 1.194652), cf = CFrame.new(1.057503, 1.56375, 0.93375, 0.416655, 0.752798, 0.509601, 0, 0.560578, -0.828102, -0.909065, 0.345033, 0.233567), c = Color3.fromRGB(51, 36, 87), m = Enum.Material.Plastic }, -- 45
		{ n = "MaskCheek1", s = "Wedge", z = Vector3.new(0.495, 1.26, 0.72), cf = CFrame.new(-0.720001, 3.015, -0.517502, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(75, 45, 121), m = Enum.Material.Plastic }, -- 46
		{ n = "PetalVein3", s = "Block", z = Vector3.new(0.081, 1.305, 0.081), cf = CFrame.new(-0.393181, 3.523973, 0.703167, 0.927184, -0.324419, 0.187303, 0, -0.5, -0.866025, 0.374607, 0.802965, -0.463592), c = Color3.fromRGB(117, 220, 250), m = Enum.Material.Neon, st = false, cs = false }, -- 47
	},
	Joints = {
		{ k = "Motor6D", n = "Head", h = 1, a = 1, b = 5, c0 = CFrame.new(0, 0.405, -0.2925, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.675, 0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Arm2", h = 1, a = 1, b = 9, c0 = CFrame.new(0.855, 0.18, -0.36, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.366446, 0.624695, 0, 0.780869, 0.143838, 0.982888, -0.11507, -0.767507, 0.184202, 0.614006) },
		{ k = "Motor6D", n = "Arm1", h = 1, a = 1, b = 35, c0 = CFrame.new(-0.855, 0.18, -0.36, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.366446, 0.624695, 0, -0.780869, -0.143838, 0.982888, -0.11507, 0.767507, 0.184202, 0.614006) },
		{ k = "Motor6D", n = "Tail", h = 1, a = 1, b = 38, c0 = CFrame.new(0, -0.045, 0.585, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.497041, -1, 0, 0, 0, 0.995893, -0.090536, 0, -0.090536, -0.995893) },
		{ k = "Weld", n = "Hold_PetalPoint6", h = 3, a = 3, b = 2, c0 = CFrame.new(0, 0.99, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalVein6", h = 3, a = 3, b = 40, c0 = CFrame.new(0, -0.045, -0.198, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 4, a = 4, b = 1, c0 = CFrame.new(0, 1.485, 0.18, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.495, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot2", h = 4, a = 4, b = 12, c0 = CFrame.new(1.62, 0.18, -0.9225, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot4", h = 4, a = 4, b = 15, c0 = CFrame.new(1.62, 0.18, 1.2825, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot1", h = 4, a = 4, b = 21, c0 = CFrame.new(-1.62, 0.18, -0.9225, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot3", h = 4, a = 4, b = 33, c0 = CFrame.new(-1.62, 0.18, 1.2825, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal6", h = 5, a = 5, b = 3, c0 = CFrame.new(0.380576, 0.5175, -0.138518, -0.34202, 0, 0.939693, 0, 1, 0, -0.939693, 0, -0.34202), c1 = CFrame.new(0, -0.675, 0, 1, 0, 0, 0, -0.5, 0.866025, 0, -0.866025, -0.5) },
		{ k = "Motor6D", n = "Petal1", h = 5, a = 5, b = 6, c0 = CFrame.new(-0.380576, 0.5175, -0.138518, -0.34202, 0, -0.939693, 0, 1, 0, 0.939693, 0, -0.34202), c1 = CFrame.new(0, -0.675, 0, 1, 0, 0, 0, -0.5, 0.866025, 0, -0.866025, -0.5) },
		{ k = "Motor6D", n = "Petal5", h = 5, a = 5, b = 8, c0 = CFrame.new(0.369986, 0.5175, 0.164728, 0.406737, 0, 0.913545, 0, 1, 0, -0.913545, 0, 0.406737), c1 = CFrame.new(0, -0.675, 0, 1, 0, 0, 0, -0.5, 0.866025, 0, -0.866025, -0.5) },
		{ k = "Weld", n = "Hold_EyeR", h = 5, a = 5, b = 11, c0 = CFrame.new(-0.3375, 0.135, -0.60525, 0.939693, 0.34202, 0, -0.34202, 0.939693, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal4", h = 5, a = 5, b = 17, c0 = CFrame.new(0.151716, 0.5175, 0.375509, 0.927184, 0, 0.374607, 0, 1, 0, -0.374607, 0, 0.927184), c1 = CFrame.new(0, -0.675, 0, 1, 0, 0, 0, -0.5, 0.866025, 0, -0.866025, -0.5) },
		{ k = "Motor6D", n = "Petal2", h = 5, a = 5, b = 20, c0 = CFrame.new(-0.369986, 0.5175, 0.164728, 0.406737, 0, -0.913545, 0, 1, 0, 0.913545, 0, 0.406737), c1 = CFrame.new(0, -0.675, 0, 1, 0, 0, 0, -0.5, 0.866025, 0, -0.866025, -0.5) },
		{ k = "Weld", n = "Hold_MaskCheek2", h = 5, a = 5, b = 26, c0 = CFrame.new(0.72, -0.135, -0.2475, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal3", h = 5, a = 5, b = 27, c0 = CFrame.new(-0.151716, 0.5175, 0.375509, 0.927184, 0, -0.374607, 0, 1, 0, 0.374607, 0, 0.927184), c1 = CFrame.new(0, -0.675, 0, 1, 0, 0, 0, -0.5, 0.866025, 0, -0.866025, -0.5) },
		{ k = "Weld", n = "Hold_EyeL", h = 5, a = 5, b = 30, c0 = CFrame.new(0.3375, 0.135, -0.60525, 0.939693, -0.34202, 0, 0.34202, 0.939693, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldKeel", h = 5, a = 5, b = 43, c0 = CFrame.new(0, -0.225, -0.54, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MaskCheek1", h = 5, a = 5, b = 46, c0 = CFrame.new(-0.72, -0.135, -0.2475, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalVein1", h = 6, a = 6, b = 7, c0 = CFrame.new(0, -0.045, -0.198, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalPoint1", h = 6, a = 6, b = 19, c0 = CFrame.new(0, 0.99, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalPoint5", h = 8, a = 8, b = 24, c0 = CFrame.new(0, 0.99, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalVein5", h = 8, a = 8, b = 31, c0 = CFrame.new(0, -0.045, -0.198, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldHook2", h = 9, a = 9, b = 10, c0 = CFrame.new(0.007028, -0.272608, -0.499762, 0.603409, -0.161683, 0.780869, 0.393327, 0.912169, -0.11507, -0.69368, 0.376571, 0.614006), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShine1", h = 11, a = 11, b = 25, c0 = CFrame.new(-0.001539, 0.004229, -0.0585, 0.939693, -0.34202, 0, 0.34202, 0.939693, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LowerLeg2", h = 12, a = 12, b = 14, c0 = CFrame.new(0, 0.135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.404531, -0.609711, 0, -0.792624, 0.705371, 0.456118, -0.542593, 0.36153, -0.889919, -0.2781) },
		{ k = "Motor6D", n = "UpperLeg2", h = 14, a = 14, b = 13, c0 = CFrame.new(0, 0, -0.404531, -0.609711, 0, -0.792624, 0.705371, 0.456118, -0.542593, 0.36153, -0.889919, -0.2781), c1 = CFrame.new(0, 0, 0.529826, -0.416655, 0, -0.909065, 0.752798, 0.560578, -0.345033, 0.509601, -0.828102, -0.233567) },
		{ k = "Motor6D", n = "LowerLeg4", h = 15, a = 15, b = 16, c0 = CFrame.new(0, 0.135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.404531, 0.609711, 0, -0.792624, 0.705372, 0.456118, 0.542593, 0.36153, -0.88992, 0.2781) },
		{ k = "Motor6D", n = "UpperLeg4", h = 16, a = 16, b = 45, c0 = CFrame.new(0, 0, -0.404531, 0.609711, 0, -0.792624, 0.705372, 0.456118, 0.542593, 0.36153, -0.88992, 0.2781), c1 = CFrame.new(0, 0, 0.529826, 0.416655, 0, -0.909065, 0.752798, 0.560578, 0.345033, 0.509601, -0.828102, 0.233567) },
		{ k = "Weld", n = "Hold_PetalPoint4", h = 17, a = 17, b = 18, c0 = CFrame.new(0, 0.99, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalVein4", h = 17, a = 17, b = 29, c0 = CFrame.new(0, -0.045, -0.198, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalVein2", h = 20, a = 20, b = 42, c0 = CFrame.new(0, -0.045, -0.198, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalPoint2", h = 20, a = 20, b = 44, c0 = CFrame.new(0, 0.99, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LowerLeg1", h = 21, a = 21, b = 22, c0 = CFrame.new(0, 0.135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.404531, -0.609711, 0, 0.792624, -0.705371, 0.456118, -0.542593, -0.36153, -0.889919, -0.2781) },
		{ k = "Motor6D", n = "UpperLeg1", h = 22, a = 22, b = 23, c0 = CFrame.new(0, 0, -0.404531, -0.609711, 0, 0.792624, -0.705371, 0.456118, -0.542593, -0.36153, -0.889919, -0.2781), c1 = CFrame.new(0, 0, 0.529826, -0.416655, 0, 0.909065, -0.752798, 0.560578, -0.345033, -0.509601, -0.828102, -0.233567) },
		{ k = "Weld", n = "Hold_PetalPoint3", h = 27, a = 27, b = 28, c0 = CFrame.new(0, 0.99, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalVein3", h = 27, a = 27, b = 47, c0 = CFrame.new(0, -0.045, -0.198, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShine2", h = 30, a = 30, b = 41, c0 = CFrame.new(0.001539, 0.004229, -0.0585, 0.939693, 0.34202, 0, -0.34202, 0.939693, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "UpperLeg3", h = 32, a = 32, b = 34, c0 = CFrame.new(0, 0, -0.404531, 0.609711, 0, 0.792624, -0.705372, 0.456118, 0.542593, -0.36153, -0.88992, 0.2781), c1 = CFrame.new(0, 0, 0.529826, 0.416655, 0, 0.909065, -0.752798, 0.560578, 0.345033, -0.509601, -0.828102, 0.233567) },
		{ k = "Motor6D", n = "LowerLeg3", h = 33, a = 33, b = 32, c0 = CFrame.new(0, 0.135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.404531, 0.609711, 0, 0.792624, -0.705372, 0.456118, 0.542593, -0.36153, -0.88992, 0.2781) },
		{ k = "Weld", n = "Hold_GoldHook1", h = 35, a = 35, b = 36, c0 = CFrame.new(-0.007028, -0.272608, -0.499762, 0.603409, 0.161683, -0.780869, -0.393327, 0.912169, -0.11507, 0.69368, 0.376571, 0.614006), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_TailPoint", h = 37, a = 37, b = 39, c0 = CFrame.new(0, 0, 0.495, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_TailLeaf", h = 38, a = 38, b = 37, c0 = CFrame.new(0, -0.004074, -0.541857, -1, 0, 0, 0, 0.995893, -0.090536, 0, -0.090536, -0.995893), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
