--!strict
--==============================================================================
-- PLANT FORM: Nubkin (Greenhollow Plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Greenhollow Plants/Nubkin" by a read-only generator on 2026-10-03. The original
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
	Source = "Greenhollow Plants/Nubkin", Kind = "plant", Yaw = 0,
	Size = Vector3.new(1.925868, 4.065992, 1.984594), Height = 4.065992, PartCount = 30,
	Base = 1,
	Unit = 1, ModelScale = 1,
	Attributes = {},
	Parts = {
		{ n = "Body", s = "Block", z = Vector3.new(1.3, 0.95, 1.3), cf = CFrame.new(0, 0.78, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(135, 196, 95), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "Head", s = "Block", z = Vector3.new(1.45, 1.25, 1.45), cf = CFrame.new(0, 1.940001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(145, 208, 105), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "GlintL", s = "Block", z = Vector3.new(0.08, 0.08, 0.05), cf = CFrame.new(-0.340004, 2.03, -0.779997, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 3
		{ n = "CheekL", s = "Block", z = Vector3.new(0.32, 0.16, 0.08), cf = CFrame.new(-0.480003, 1.760001, -0.739999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 162, 158), m = Enum.Material.Plastic, st = false }, -- 4
		{ n = "EarStemR", s = "Block", z = Vector3.new(0.18, 0.3, 0.18), cf = CFrame.new(0.499996, 2.690001, -0.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(128, 195, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "EarTipR", s = "Block", z = Vector3.new(0.38, 0.32, 0.12), cf = CFrame.new(0.695755, 3.414003, -0.080002, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(145, 208, 105), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "GlintR", s = "Block", z = Vector3.new(0.08, 0.08, 0.05), cf = CFrame.new(0.419998, 2.03, -0.779997, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 7
		{ n = "ToeL1", s = "Block", z = Vector3.new(0.18, 0.18, 0.34), cf = CFrame.new(-0.580002, 0.09, -0.260002, 0.965926, 0, -0.258819, 0, 1, 0, 0.258819, 0, 0.965926), c = Color3.fromRGB(122, 86, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "FootL", s = "Block", z = Vector3.new(0.44, 0.32, 0.58), cf = CFrame.new(-0.480003, 0.17, 0.049999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(122, 86, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "CollarF", s = "Block", z = Vector3.new(0.45, 0.15, 0.35), cf = CFrame.new(0, 1.25, -0.48, 1, 0, 0, 0, 0.927184, 0.374607, 0, -0.374607, 0.927184), c = Color3.fromRGB(248, 244, 218), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "FootR", s = "Block", z = Vector3.new(0.44, 0.32, 0.58), cf = CFrame.new(0.479996, 0.17, 0.050001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(122, 86, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "ToeR1", s = "Block", z = Vector3.new(0.18, 0.18, 0.34), cf = CFrame.new(0.579998, 0.09, -0.260001, 0.965926, 0, 0.258819, 0, 1, 0, -0.258819, 0, 0.965926), c = Color3.fromRGB(122, 86, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "LidR", s = "Block", z = Vector3.new(0.28, 0.16, 0.1), cf = CFrame.new(0.380001, 2.12, -0.77, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(145, 208, 105), m = Enum.Material.Plastic, st = false }, -- 13
		{ n = "EarBladeR", s = "Block", z = Vector3.new(0.64, 0.62, 0.16), cf = CFrame.new(0.593815, 3.105933, -0.070002, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(128, 195, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "CheekR", s = "Block", z = Vector3.new(0.32, 0.16, 0.08), cf = CFrame.new(0.479996, 1.760001, -0.74, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 162, 158), m = Enum.Material.Plastic, st = false }, -- 15
		{ n = "EarStemL", s = "Block", z = Vector3.new(0.18, 0.38, 0.18), cf = CFrame.new(-0.52, 2.78, 0.049999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 182, 80), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "EarTipL", s = "Block", z = Vector3.new(0.34, 0.45, 0.12), cf = CFrame.new(-0.566002, 3.801121, 0.100005, 0.956305, -0.292372, 0, 0.292372, 0.956305, 0, 0, 0, 1), c = Color3.fromRGB(248, 244, 218), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "ToeR2", s = "Block", z = Vector3.new(0.18, 0.18, 0.32), cf = CFrame.new(0.379997, 0.09, -0.249997, 0.984808, 0, -0.173648, 0, 1, 0, 0.173648, 0, 0.984808), c = Color3.fromRGB(122, 86, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "HeadCross", s = "Block", z = Vector3.new(1.35, 1.24, 1.35), cf = CFrame.new(0, 1.940001, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(145, 208, 105), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "CollarR", s = "Block", z = Vector3.new(0.35, 0.15, 0.45), cf = CFrame.new(0.549995, 1.25, 0.000003, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(248, 244, 218), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "BodyCross", s = "Block", z = Vector3.new(1.3, 0.95, 1.3), cf = CFrame.new(0, 0.78, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(135, 196, 95), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "EarBladeL", s = "Block", z = Vector3.new(0.52, 0.85, 0.16), cf = CFrame.new(-0.541885, 3.335268, 0.080007, 0.992546, -0.121869, 0, 0.121869, 0.992546, 0, 0, 0, 1), c = Color3.fromRGB(115, 182, 80), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "LidL", s = "Block", z = Vector3.new(0.28, 0.16, 0.1), cf = CFrame.new(-0.380001, 2.12, -0.77, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(145, 208, 105), m = Enum.Material.Plastic, st = false }, -- 23
		{ n = "TailRoot", s = "Block", z = Vector3.new(0.28, 0.28, 0.42), cf = CFrame.new(0, 0.58, 0.82, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(122, 86, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "EyeL", s = "Block", z = Vector3.new(0.25, 0.28, 0.08), cf = CFrame.new(-0.380005, 1.960001, -0.74, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 32, 25), m = Enum.Material.Neon, st = false }, -- 25
		{ n = "Belly", s = "Block", z = Vector3.new(0.92, 0.72, 0.25), cf = CFrame.new(0, 0.75, -0.58, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(216, 240, 185), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "CollarL", s = "Block", z = Vector3.new(0.35, 0.15, 0.45), cf = CFrame.new(-0.549999, 1.25, 0, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(248, 244, 218), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "Mouth", s = "Block", z = Vector3.new(0.18, 0.08, 0.06), cf = CFrame.new(0, 1.720001, -0.739999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(70, 105, 45), m = Enum.Material.Plastic, st = false }, -- 28
		{ n = "ToeL2", s = "Block", z = Vector3.new(0.18, 0.18, 0.32), cf = CFrame.new(-0.380001, 0.09, -0.249997, 0.984808, 0, 0.173648, 0, 1, 0, -0.173648, 0, 0.984808), c = Color3.fromRGB(122, 86, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "EyeR", s = "Block", z = Vector3.new(0.25, 0.28, 0.08), cf = CFrame.new(0.379997, 1.960001, -0.74, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 32, 25), m = Enum.Material.Neon, st = false }, -- 30
	},
	Joints = {
		{ k = "Motor6D", n = "Neck", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0.58, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.58, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 9, c0 = CFrame.new(-0.48, -0.46, 0.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.15, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 10, c0 = CFrame.new(0, 0.47, -0.48, 1, 0, 0, 0, 0.927184, 0.374607, 0, -0.374607, 0.927184), c1 = CFrame.new() },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 11, c0 = CFrame.new(0.48, -0.46, 0.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.15, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 20, c0 = CFrame.new(0.549995, 0.47, 0.000003, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 21, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TailJoint", h = 1, a = 1, b = 24, c0 = CFrame.new(0, -0.2, 0.62, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, -0.2, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 26, c0 = CFrame.new(0, -0.03, -0.58, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 27, c0 = CFrame.new(-0.549999, 0.47, 0, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 3, c0 = CFrame.new(-0.340004, 0.09, -0.779997, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 4, c0 = CFrame.new(-0.480003, -0.18, -0.739999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "RightEar", h = 2, a = 2, b = 5, c0 = CFrame.new(0.5, 0.6, -0.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.15, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 7, c0 = CFrame.new(0.419998, 0.09, -0.779997, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "RightEyelid", h = 2, a = 2, b = 13, c0 = CFrame.new(0.38, 0.18, -0.77, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 15, c0 = CFrame.new(0.479996, -0.18, -0.74, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "LeftEar", h = 2, a = 2, b = 16, c0 = CFrame.new(-0.52, 0.65, 0.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.19, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 19, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Motor6D", n = "LeftEyelid", h = 2, a = 2, b = 23, c0 = CFrame.new(-0.38, 0.18, -0.77, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 25, c0 = CFrame.new(-0.380005, 0.02, -0.74, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 28, c0 = CFrame.new(0, -0.22, -0.739999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 30, c0 = CFrame.new(0.379997, 0.02, -0.74, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 6, c0 = CFrame.new(0.195759, 0.724002, -0.030002, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 14, c0 = CFrame.new(0.093819, 0.415933, -0.020001, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 9, a = 9, b = 8, c0 = CFrame.new(-0.099998, -0.08, -0.310001, 0.965926, 0, -0.258819, 0, 1, 0, 0.258819, 0, 0.965926), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 9, a = 9, b = 29, c0 = CFrame.new(0.100002, -0.08, -0.299996, 0.984808, 0, 0.173648, 0, 1, 0, -0.173648, 0, 0.984808), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 12, c0 = CFrame.new(0.100002, -0.08, -0.310002, 0.965926, 0, 0.258819, 0, 1, 0, -0.258819, 0, 0.965926), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 18, c0 = CFrame.new(-0.099998, -0.08, -0.299998, 0.984808, 0, -0.173648, 0, 1, 0, 0.173648, 0, 0.984808), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 16, a = 16, b = 17, c0 = CFrame.new(-0.046001, 1.02112, 0.050006, 0.956305, -0.292372, 0, 0.292372, 0.956305, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 16, a = 16, b = 22, c0 = CFrame.new(-0.021885, 0.555268, 0.030007, 0.992546, -0.121869, 0, 0.121869, 0.992546, 0, 0, 0, 1), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
		{ n = "PollenSpore", p = 2, rate = 2.5, enabled = true, lifetime = NumberRange.new(1.2, 2), speed = NumberRange.new(0.4, 1), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.14, 0), NumberSequenceKeypoint.new(1, 0.04, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8, 0), NumberSequenceKeypoint.new(0.5, 0.2, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.862745, 1, 0.705882)), ColorSequenceKeypoint.new(1, Color3.new(0.862745, 1, 0.705882)) }), lightEmission = 0, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(45, 45), acceleration = Vector3.new(0, 0, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 8, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 10, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 11, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 12, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 14, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 17, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 18, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 29, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
