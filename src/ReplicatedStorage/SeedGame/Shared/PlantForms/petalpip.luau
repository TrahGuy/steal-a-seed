--!strict
--==============================================================================
-- PLANT FORM: Petalpip (Greenhollow Plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Greenhollow Plants/Petalpip" by a read-only generator on 2026-10-03. The original
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
	Source = "Greenhollow Plants/Petalpip", Kind = "plant", Yaw = 0,
	Size = Vector3.new(2.986299, 3.762145, 2.536024), Height = 3.762145, PartCount = 32,
	Base = 3,
	Unit = 2, ModelScale = 1.362037,
	Attributes = {},
	Parts = {
		{ n = "FootR", s = "Block", z = Vector3.new(0.408611, 0.476713, 0.408611), cf = CFrame.new(0.476715, 0.34732, 0.02724, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(126, 88, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "ToeR", s = "Block", z = Vector3.new(0.299648, 0.204306, 0.572056), cf = CFrame.new(0.476715, 0.102153, -0.204309, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(126, 88, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "Body", s = "Block", z = Vector3.new(1.157732, 1.08963, 1.157732), cf = CFrame.new(0, 1.137301, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 184, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "GlintR", s = "Block", z = Vector3.new(0.108963, 0.108963, 0.068102), cf = CFrame.new(0.490334, 2.635542, -0.871702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 4
		{ n = "Head", s = "Block", z = Vector3.new(1.566343, 1.430139, 1.566343), cf = CFrame.new(0, 2.499339, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 238, 175), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "PetalL", s = "Block", z = Vector3.new(0.272407, 1.498241, 1.566343), cf = CFrame.new(-0.980667, 2.90795, -0.000006, 0.848048, -0.529919, 0, 0.529919, 0.848048, 0, 0, 0, 1), c = Color3.fromRGB(254, 250, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "PetalCupF", s = "Block", z = Vector3.new(1.225834, 0.572056, 0.299648), cf = CFrame.new(0.000004, 1.995384, -0.78998, 1, 0, 0, 0, 0.809017, 0.587785, 0, -0.587785, 0.809017), c = Color3.fromRGB(254, 250, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "ArmL_Upper", s = "Block", z = Vector3.new(0.299648, 0.885324, 0.435852), cf = CFrame.new(-0.572056, 1.069199, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 172, 70), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "FootL", s = "Block", z = Vector3.new(0.408611, 0.476713, 0.408611), cf = CFrame.new(-0.476715, 0.34732, 0.02724, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(126, 88, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "CheekL", s = "Block", z = Vector3.new(0.38137, 0.190685, 0.108963), cf = CFrame.new(-0.572056, 2.295033, -0.817221, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 150, 150), m = Enum.Material.Plastic, st = false }, -- 10
		{ n = "Mouth", s = "Block", z = Vector3.new(0.217926, 0.095343, 0.081722), cf = CFrame.new(0, 2.240551, -0.817226, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(180, 80, 75), m = Enum.Material.Plastic, st = false }, -- 11
		{ n = "CheekR", s = "Block", z = Vector3.new(0.38137, 0.190685, 0.108963), cf = CFrame.new(0.57206, 2.295033, -0.817221, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 150, 150), m = Enum.Material.Plastic, st = false }, -- 12
		{ n = "ArmR_Upper", s = "Block", z = Vector3.new(0.299648, 0.885324, 0.435852), cf = CFrame.new(0.57206, 1.069199, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 172, 70), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "GlintL", s = "Block", z = Vector3.new(0.108963, 0.108963, 0.068102), cf = CFrame.new(-0.381363, 2.635542, -0.871709, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 14
		{ n = "LidR", s = "Block", z = Vector3.new(0.340509, 0.190685, 0.122583), cf = CFrame.new(0.435852, 2.690024, -0.844464, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(254, 250, 230), m = Enum.Material.Plastic, st = false }, -- 15
		{ n = "PetalBR", s = "Block", z = Vector3.new(0.953426, 1.293935, 0.245167), cf = CFrame.new(0.789982, 3.044153, 0.708259, 0.742404, 0.346189, 0.573576, -0.16333, 0.923838, -0.346189, -0.649738, 0.16333, 0.742404), c = Color3.fromRGB(246, 238, 205), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "SepalF", s = "Block", z = Vector3.new(0.681019, 0.190685, 0.476713), cf = CFrame.new(0.000004, 1.545912, -0.612917, 1, 0, 0, 0, 0.819152, 0.573577, 0, -0.573576, 0.819152), c = Color3.fromRGB(118, 184, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "BodyCross", s = "Block", z = Vector3.new(1.116871, 1.062389, 1.116871), cf = CFrame.new(0, 1.137301, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(118, 184, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "ArmR_Blade", s = "Block", z = Vector3.new(0.708259, 0.38137, 0.299648), cf = CFrame.new(0.10474, 0.886592, -0.368771, 0.701968, 0.644813, -0.302417, -0.461615, 0.735279, 0.496263, 0.542358, -0.208761, 0.813798), c = Color3.fromRGB(100, 172, 70), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "ArmL_Blade", s = "Block", z = Vector3.new(0.708259, 0.38137, 0.299648), cf = CFrame.new(-0.104736, 0.886591, -0.36877, 0.701968, -0.644813, 0.302417, 0.461615, 0.735279, 0.496263, -0.542358, -0.208761, 0.813798), c = Color3.fromRGB(100, 172, 70), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "PetalR", s = "Block", z = Vector3.new(0.272407, 1.498241, 1.566343), cf = CFrame.new(0.980671, 2.90795, 0, 0.848048, 0.529919, 0, -0.529919, 0.848048, 0, 0, 0, 1), c = Color3.fromRGB(254, 250, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "Stamen", s = "Block", z = Vector3.new(0.340509, 0.476713, 0.340509), cf = CFrame.new(0, 3.411904, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 95), m = Enum.Material.Neon, st = false }, -- 22
		{ n = "PetalB", s = "Block", z = Vector3.new(1.634445, 1.566343, 0.272407), cf = CFrame.new(0, 2.976052, 0.926186, 1, 0, 0, 0, 0.848048, -0.529919, 0, 0.529919, 0.848048), c = Color3.fromRGB(254, 250, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "ToeL", s = "Block", z = Vector3.new(0.299648, 0.204306, 0.572056), cf = CFrame.new(-0.476711, 0.102153, -0.204309, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(126, 88, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "EyeR", s = "Block", z = Vector3.new(0.299648, 0.326889, 0.108963), cf = CFrame.new(0.435852, 2.5402, -0.817221, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(28, 30, 28), m = Enum.Material.Neon, st = false }, -- 25
		{ n = "HeadCross", s = "Block", z = Vector3.new(1.471, 1.389278, 1.471), cf = CFrame.new(0, 2.499339, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 238, 175), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "SepalR", s = "Block", z = Vector3.new(0.476713, 0.190685, 0.681019), cf = CFrame.new(0.612915, 1.545912, -0.000001, 0.819152, 0.573576, 0, -0.573577, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(118, 184, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "EyeL", s = "Block", z = Vector3.new(0.299648, 0.326889, 0.108963), cf = CFrame.new(-0.435852, 2.5402, -0.817222, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(28, 30, 28), m = Enum.Material.Neon, st = false }, -- 28
		{ n = "StemTail", s = "Block", z = Vector3.new(0.272407, 0.476713, 0.272407), cf = CFrame.new(0.000004, 0.864894, 0.817222, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 184, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "LidL", s = "Block", z = Vector3.new(0.340509, 0.190685, 0.122583), cf = CFrame.new(-0.435852, 2.690024, -0.844464, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(254, 250, 230), m = Enum.Material.Plastic, st = false }, -- 30
		{ n = "SepalL", s = "Block", z = Vector3.new(0.476713, 0.190685, 0.681019), cf = CFrame.new(-0.612915, 1.545912, -0.000006, 0.819152, -0.573576, 0, 0.573577, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(118, 184, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "PetalBL", s = "Block", z = Vector3.new(0.953426, 1.293935, 0.245167), cf = CFrame.new(-0.789978, 3.044153, 0.70826, 0.742404, -0.346189, -0.573576, 0.16333, 0.923838, -0.346189, 0.649738, 0.16333, 0.742404), c = Color3.fromRGB(246, 238, 205), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, -0.245167, -0.231549, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "HipR", h = 3, a = 3, b = 1, c0 = CFrame.new(0.476713, -0.572056, 0.027241, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.217926, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 3, a = 3, b = 5, c0 = CFrame.new(0, 0.681019, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.681019, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderL", h = 3, a = 3, b = 8, c0 = CFrame.new(-0.572056, 0.272407, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.340509, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 3, a = 3, b = 9, c0 = CFrame.new(-0.476713, -0.572056, 0.027241, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.217926, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 3, a = 3, b = 13, c0 = CFrame.new(0.572056, 0.272407, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.340509, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 17, c0 = CFrame.new(0.000004, 0.408611, -0.612917, 1, 0, 0, 0, 0.819152, 0.573577, 0, -0.573576, 0.819152), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 18, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 27, c0 = CFrame.new(0.612915, 0.408611, -0.000001, 0.819152, 0.573576, 0, -0.573577, 0.819152, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TailJoint", h = 3, a = 3, b = 29, c0 = CFrame.new(0, -0.272407, 0.612917, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, -0.204306, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 31, c0 = CFrame.new(-0.612915, 0.408611, -0.000006, 0.819152, -0.573576, 0, 0.573577, 0.819152, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 4, c0 = CFrame.new(0.490334, 0.136204, -0.871702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 6, c0 = CFrame.new(-0.980667, 0.408611, -0.000006, 0.848048, -0.529919, 0, 0.529919, 0.848048, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 7, c0 = CFrame.new(0.000004, -0.503954, -0.78998, 1, 0, 0, 0, 0.809017, 0.587785, 0, -0.587785, 0.809017), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 10, c0 = CFrame.new(-0.572056, -0.204306, -0.817221, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 11, c0 = CFrame.new(0, -0.258787, -0.817226, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 12, c0 = CFrame.new(0.57206, -0.204306, -0.817221, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 14, c0 = CFrame.new(-0.381363, 0.136204, -0.871709, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "RightEyelid", h = 5, a = 5, b = 15, c0 = CFrame.new(0.435852, 0.190685, -0.844463, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 16, c0 = CFrame.new(0.789982, 0.544815, 0.708259, 0.742404, 0.346189, 0.573576, -0.16333, 0.923838, -0.346189, -0.649738, 0.16333, 0.742404), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 21, c0 = CFrame.new(0.980671, 0.408611, 0, 0.848048, 0.529919, 0, -0.529919, 0.848048, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 22, c0 = CFrame.new(0, 0.912565, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 23, c0 = CFrame.new(0, 0.476713, 0.926186, 1, 0, 0, 0, 0.848048, -0.529919, 0, 0.529919, 0.848048), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 25, c0 = CFrame.new(0.435852, 0.040861, -0.817221, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 26, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 28, c0 = CFrame.new(-0.435852, 0.040861, -0.817222, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "LeftEyelid", h = 5, a = 5, b = 30, c0 = CFrame.new(-0.435852, 0.190685, -0.844463, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 32, c0 = CFrame.new(-0.789978, 0.544815, 0.70826, 0.742404, -0.346189, -0.573576, 0.16333, 0.923838, -0.346189, 0.649738, 0.16333, 0.742404), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 20, c0 = CFrame.new(0.467319, -0.182608, -0.36877, 0.701968, -0.644813, 0.302417, 0.461615, 0.735279, 0.496263, -0.542358, -0.208761, 0.813798), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 9, a = 9, b = 24, c0 = CFrame.new(0.000004, -0.245167, -0.231549, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 19, c0 = CFrame.new(-0.467319, -0.182608, -0.368771, 0.701968, 0.644813, -0.302417, -0.461615, 0.735279, 0.496263, 0.542358, -0.208761, 0.813798), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
		{ n = "NectarGlow", p = 5, rate = 3.5, enabled = true, lifetime = NumberRange.new(1.4, 2.2), speed = NumberRange.new(0.544815, 1.225834), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.163444, 0), NumberSequenceKeypoint.new(1, 0.040861, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8, 0), NumberSequenceKeypoint.new(0.5, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 0.960784, 0.705882)), ColorSequenceKeypoint.new(1, Color3.new(1, 0.960784, 0.705882)) }), lightEmission = 0, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(65, 65), acceleration = Vector3.new(0, 0, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 8, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 13, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 17, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 18, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 23, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 29, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 31, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 32, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
