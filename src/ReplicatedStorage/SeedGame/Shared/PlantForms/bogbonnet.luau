--!strict
--==============================================================================
-- PLANT FORM: Bogbonnet (Tanglemire)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Tanglemire/Bogbonnet" by a read-only generator on 2026-10-03. The original
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
	Source = "Tanglemire/Bogbonnet", Kind = "plant", Yaw = 0,
	Size = Vector3.new(3.280864, 3.709868, 3.280864), Height = 3.709868, PartCount = 28,
	Base = 3,
	Unit = 1, ModelScale = 0.999965,
	Attributes = {},
	Parts = {
		{ n = "CapBase", s = "Block", z = Vector3.new(2.399916, 0.649977, 2.399916), cf = CFrame.new(0.000004, 2.759903, -0.299988, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(122, 94, 130), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "MossTop", s = "Block", z = Vector3.new(1.799937, 0.449984, 1.799937), cf = CFrame.new(0, 3.179887, -0.299995, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(94, 126, 72), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "Body", s = "Block", z = Vector3.new(1.299954, 1.049963, 1.249956), cf = CFrame.new(0, 0.85997, 0, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(68, 82, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "Head", s = "Block", z = Vector3.new(1.199958, 0.949967, 1.14996), cf = CFrame.new(0.000004, 1.859935, -0.299988, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(68, 82, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "EyeR", s = "Block", z = Vector3.new(0.299989, 0.319989, 0.099996), cf = CFrame.new(0.319988, 1.839936, -0.919968, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(240, 245, 110), m = Enum.Material.Neon, st = false }, -- 5
		{ n = "SporeNodule", s = "Block", z = Vector3.new(0.349988, 0.399986, 0.349988), cf = CFrame.new(0.149998, 3.509875, -0.399986, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(180, 235, 150), m = Enum.Material.Neon, st = false }, -- 6
		{ n = "CapCross", s = "Block", z = Vector3.new(2.319919, 0.619978, 2.319919), cf = CFrame.new(0.000004, 2.759903, -0.299988, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(98, 72, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "GlintR", s = "Block", z = Vector3.new(0.089997, 0.089997, 0.049998), cf = CFrame.new(0.359989, 1.909933, -0.979961, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 8
		{ n = "MudBelly", s = "Block", z = Vector3.new(0.899969, 0.799972, 0.299989), cf = CFrame.new(0, 0.809971, -0.579979, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(152, 142, 114), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "LidL", s = "Block", z = Vector3.new(0.319989, 0.179994, 0.119996), cf = CFrame.new(-0.319992, 1.979931, -0.949966, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(68, 82, 54), m = Enum.Material.Plastic, st = false }, -- 10
		{ n = "EyeL", s = "Block", z = Vector3.new(0.299989, 0.319989, 0.099996), cf = CFrame.new(-0.319988, 1.839936, -0.919964, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(240, 245, 110), m = Enum.Material.Neon, st = false }, -- 11
		{ n = "GlintL", s = "Block", z = Vector3.new(0.089997, 0.089997, 0.049998), cf = CFrame.new(-0.279991, 1.909933, -0.979961, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 12
		{ n = "DroopRight", s = "Block", z = Vector3.new(0.349988, 0.549981, 1.899933), cf = CFrame.new(1.249958, 2.439913, -0.299995, 0.927185, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1.000001), c = Color3.fromRGB(122, 94, 130), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "LidR", s = "Block", z = Vector3.new(0.319989, 0.179994, 0.119996), cf = CFrame.new(0.319988, 1.979931, -0.949963, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(68, 82, 54), m = Enum.Material.Plastic, st = false }, -- 14
		{ n = "TailSprout", s = "Block", z = Vector3.new(0.349988, 0.349988, 0.449984), cf = CFrame.new(0, 0.609979, 0.849976, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(94, 126, 72), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "Mouth", s = "Block", z = Vector3.new(0.239992, 0.099996, 0.079997), cf = CFrame.new(0, 1.579945, -0.899963, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(42, 34, 38), m = Enum.Material.Plastic, st = false }, -- 16
		{ n = "DroopBack", s = "Block", z = Vector3.new(1.899933, 0.549981, 0.349988), cf = CFrame.new(0, 2.439911, 0.949966, 1.000001, 0, 0, 0, 0.927184, 0.374607, 0, -0.374607, 0.927185), c = Color3.fromRGB(122, 94, 130), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "HeadCross", s = "Block", z = Vector3.new(1.13996, 0.899969, 1.079962), cf = CFrame.new(0.000004, 1.859935, -0.299988, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(46, 56, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "FootR", s = "Block", z = Vector3.new(0.649977, 0.419985, 0.899969), cf = CFrame.new(0.549984, 0.209993, 0, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(58, 46, 34), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "MossPatchL", s = "Block", z = Vector3.new(0.699975, 0.299989, 0.899969), cf = CFrame.new(-0.849972, 3.039892, -0.499985, 0.951057, -0.309017, 0, 0.309017, 0.951057, 0, 0, 0, 1.000001), c = Color3.fromRGB(76, 104, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "ToeR", s = "Block", z = Vector3.new(0.499982, 0.299989, 0.399986), cf = CFrame.new(0.54998, 0.149995, -0.499977, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(58, 46, 34), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "MossPatchR", s = "Block", z = Vector3.new(0.799972, 0.299989, 0.699975), cf = CFrame.new(0.849972, 3.039891, -0.099998, 0.951057, 0.309017, 0, -0.309017, 0.951056, 0, 0, 0, 1.000001), c = Color3.fromRGB(94, 126, 72), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "DroopLeft", s = "Block", z = Vector3.new(0.349988, 0.549981, 1.899933), cf = CFrame.new(-1.249958, 2.439913, -0.299992, 0.927185, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1.000001), c = Color3.fromRGB(122, 94, 130), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "FootL", s = "Block", z = Vector3.new(0.649977, 0.419985, 0.899969), cf = CFrame.new(-0.549984, 0.209993, 0, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(58, 46, 34), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "StemHunch", s = "Block", z = Vector3.new(1.099962, 0.549981, 0.799972), cf = CFrame.new(0, 1.359952, 0.25, 1.000001, 0, 0, 0, 0.965926, 0.258819, 0, -0.258819, 0.965927), c = Color3.fromRGB(76, 104, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "BodyCross", s = "Block", z = Vector3.new(1.239956, 0.999965, 1.179959), cf = CFrame.new(0, 0.85997, 0, 0.707108, 0, 0.707108, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(46, 56, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "ToeL", s = "Block", z = Vector3.new(0.499982, 0.299989, 0.399986), cf = CFrame.new(-0.549984, 0.149995, -0.499977, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(58, 46, 34), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "DroopFront", s = "Block", z = Vector3.new(1.899933, 0.549981, 0.349988), cf = CFrame.new(0.000004, 2.439913, -1.54995, 1.000001, 0, 0, 0, 0.927184, -0.374607, 0, 0.374607, 0.927185), c = Color3.fromRGB(158, 128, 168), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(-0.000004, 0.419983, -0.000008, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 6, c0 = CFrame.new(0.149998, 0.749972, -0.099998, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 7, c0 = CFrame.new(0, 0, 0, 0.707108, 0, 0.707108, 0, 1, 0, -0.707108, 0, 0.707108), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 13, c0 = CFrame.new(1.249958, -0.31999, 0, 0.927185, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 17, c0 = CFrame.new(0, -0.319992, 1.249954, 1.000002, 0, 0, 0, 0.927184, 0.374607, 0, -0.374607, 0.927186), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 20, c0 = CFrame.new(-0.849976, 0.279989, -0.199997, 0.951058, -0.309018, 0, 0.309017, 0.951057, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 22, c0 = CFrame.new(0.849968, 0.279987, 0.199989, 0.951058, 0.309018, 0, -0.309017, 0.951056, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 23, c0 = CFrame.new(-1.249962, -0.31999, -0.000004, 0.927185, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 28, c0 = CFrame.new(-0.000004, -0.31999, -1.249962, 1.000002, 0, 0, 0, 0.927184, -0.374607, 0, 0.374607, 0.927186), c1 = CFrame.new() },
		{ k = "Motor6D", n = "Neck", h = 3, a = 3, b = 4, c0 = CFrame.new(0, 0.599979, -0.299989, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.399986, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 9, c0 = CFrame.new(-0.000004, -0.049999, -0.579987, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TailJoint", h = 3, a = 3, b = 15, c0 = CFrame.new(0, -0.249991, 0.649977, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, -0.199993, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 3, a = 3, b = 19, c0 = CFrame.new(0.549981, -0.449984, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.199993, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 3, a = 3, b = 24, c0 = CFrame.new(-0.549981, -0.449984, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.199993, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 25, c0 = CFrame.new(0, 0.499982, 0.25, 1.000002, 0, 0, 0, 0.965926, 0.258819, 0, -0.258819, 0.965928), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 26, c0 = CFrame.new(0, 0, 0, 0.707108, 0, 0.707108, 0, 1, 0, -0.707108, 0, 0.707108), c1 = CFrame.new() },
		{ k = "Motor6D", n = "CapJoint", h = 4, a = 4, b = 1, c0 = CFrame.new(0, 0.649977, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.249991, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(0.319988, -0.019999, -0.61998, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 8, c0 = CFrame.new(0.359989, 0.049998, -0.679974, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Motor6D", n = "LeftEyelid", h = 4, a = 4, b = 10, c0 = CFrame.new(-0.319989, 0.119996, -0.649977, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 11, c0 = CFrame.new(-0.319988, -0.019999, -0.619976, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 12, c0 = CFrame.new(-0.279991, 0.049998, -0.679974, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Motor6D", n = "RightEyelid", h = 4, a = 4, b = 14, c0 = CFrame.new(0.319989, 0.119996, -0.649977, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 16, c0 = CFrame.new(0, -0.27999, -0.599976, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 18, c0 = CFrame.new(0, 0, 0, 0.707108, 0, 0.707108, 0, 1, 0, -0.707108, 0, 0.707108), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 21, c0 = CFrame.new(0, -0.059998, -0.499985, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 24, a = 24, b = 27, c0 = CFrame.new(0, -0.059998, -0.499977, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 13, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 17, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 18, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 23, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 25, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 28, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
