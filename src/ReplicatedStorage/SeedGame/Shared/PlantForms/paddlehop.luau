--!strict
--==============================================================================
-- PLANT FORM: Paddlehop (Dustbowl plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Dustbowl plants/Paddlehop" by a read-only generator on 2026-10-03. The original
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
	Source = "Dustbowl plants/Paddlehop", Kind = "plant", Yaw = 0,
	Size = Vector3.new(3.870205, 3.553473, 1.703255), Height = 3.553473, PartCount = 29,
	Base = 3,
	Unit = 2, ModelScale = 1.08503,
	Attributes = {},
	Parts = {
		{ n = "Head", s = "Block", z = Vector3.new(1.356288, 1.08503, 0.813773), cf = CFrame.new(0, 2.088683, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "PadUpperL", s = "Block", z = Vector3.new(0.70527, 1.030779, 0.325509), cf = CFrame.new(-0.813772, 2.848204, 0.054256, 0.898794, -0.438371, 0, 0.438371, 0.898794, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "Body", s = "Block", z = Vector3.new(1.736048, 1.139282, 0.781222), cf = CFrame.new(0, 1.003653, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "LegL", s = "Block", z = Vector3.new(0.520814, 0.488264, 0.564216), cf = CFrame.new(-0.542515, 0.244132, 0.021702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 88, 52), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "LidR", s = "Block", z = Vector3.new(0.292958, 0.162755, 0.097653), cf = CFrame.new(0.379761, 2.229737, -0.455711, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, st = false }, -- 5
		{ n = "PaddleR", s = "Block", z = Vector3.new(0.922276, 1.030779, 0.303808), cf = CFrame.new(1.356285, 0.949401, 0, 0.965926, -0.258819, 0, 0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "ArmR", s = "Block", z = Vector3.new(0.238707, 0.434012, 0.238707), cf = CFrame.new(0.922276, 1.057904, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "BudR", s = "Block", z = Vector3.new(0.325509, 0.325509, 0.271258), cf = CFrame.new(1.030781, 3.390719, 0.054256, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 210, 65), m = Enum.Material.Neon, st = false }, -- 8
		{ n = "LegR", s = "Block", z = Vector3.new(0.520814, 0.488264, 0.564216), cf = CFrame.new(0.542515, 0.244132, 0.021702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 88, 52), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "CheekR", s = "Block", z = Vector3.new(0.303808, 0.151904, 0.086802), cf = CFrame.new(0.477409, 1.882527, -0.43401, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(235, 142, 115), m = Enum.Material.Plastic, st = false }, -- 10
		{ n = "ToeR2", s = "Block", z = Vector3.new(0.217006, 0.173605, 0.325509), cf = CFrame.new(0.434011, 0.092228, -0.227856, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c = Color3.fromRGB(130, 88, 52), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "PadUpperR", s = "Block", z = Vector3.new(0.70527, 1.030779, 0.325509), cf = CFrame.new(0.81377, 2.848204, 0.054256, 0.898794, 0.438371, 0, -0.438371, 0.898794, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "SandBelly", s = "Block", z = Vector3.new(1.247785, 0.813773, 0.238707), cf = CFrame.new(0, 0.949401, -0.412308, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(222, 202, 158), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "ArmL", s = "Block", z = Vector3.new(0.238707, 0.434012, 0.238707), cf = CFrame.new(-0.922276, 1.057904, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "LidL", s = "Block", z = Vector3.new(0.292958, 0.162755, 0.097653), cf = CFrame.new(-0.379761, 2.229737, -0.455711, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, st = false }, -- 15
		{ n = "ToeL1", s = "Block", z = Vector3.new(0.217006, 0.173605, 0.34721), cf = CFrame.new(-0.651018, 0.092228, -0.238708, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c = Color3.fromRGB(130, 88, 52), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "HeadCross", s = "Block", z = Vector3.new(1.280335, 1.041629, 0.781222), cf = CFrame.new(0, 2.088683, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(124, 154, 108), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "EyeR", s = "Block", z = Vector3.new(0.260407, 0.282108, 0.086802), cf = CFrame.new(0.379759, 2.088683, -0.43401, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(26, 28, 26), m = Enum.Material.Neon, st = false }, -- 18
		{ n = "TailPad", s = "Block", z = Vector3.new(0.488264, 0.379761, 0.271258), cf = CFrame.new(0, 0.786647, 0.520813, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "PaddleL", s = "Block", z = Vector3.new(0.922276, 1.030779, 0.303808), cf = CFrame.new(-1.356285, 0.949401, 0.000004, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(138, 168, 120), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "CheekL", s = "Block", z = Vector3.new(0.303808, 0.151904, 0.086802), cf = CFrame.new(-0.477419, 1.882527, -0.43401, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(235, 142, 115), m = Enum.Material.Plastic, st = false }, -- 21
		{ n = "BudL", s = "Block", z = Vector3.new(0.325509, 0.325509, 0.271258), cf = CFrame.new(-1.030777, 3.390719, 0.054249, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 210, 65), m = Enum.Material.Neon, st = false }, -- 22
		{ n = "GlintR", s = "Block", z = Vector3.new(0.086802, 0.086802, 0.054252), cf = CFrame.new(0.423161, 2.164635, -0.477413, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 23
		{ n = "Smirk", s = "Block", z = Vector3.new(0.238707, 0.075952, 0.065102), cf = CFrame.new(0.065102, 1.860826, -0.444862, 0.965926, -0.258819, 0, 0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(55, 75, 48), m = Enum.Material.Plastic, st = false }, -- 24
		{ n = "EyeL", s = "Block", z = Vector3.new(0.260407, 0.282108, 0.086802), cf = CFrame.new(-0.379761, 2.088683, -0.43401, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(26, 28, 26), m = Enum.Material.Neon, st = false }, -- 25
		{ n = "ToeL2", s = "Block", z = Vector3.new(0.217006, 0.173605, 0.325509), cf = CFrame.new(-0.434008, 0.092228, -0.227856, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c = Color3.fromRGB(130, 88, 52), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "GlintL", s = "Block", z = Vector3.new(0.086802, 0.086802, 0.054252), cf = CFrame.new(-0.336359, 2.164635, -0.477413, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 27
		{ n = "ToeR1", s = "Block", z = Vector3.new(0.217006, 0.173605, 0.34721), cf = CFrame.new(0.651018, 0.092228, -0.238705, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c = Color3.fromRGB(130, 88, 52), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "BodyCross", s = "Block", z = Vector3.new(1.649246, 1.106731, 0.759521), cf = CFrame.new(0, 1.003653, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(124, 154, 108), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(-0.813772, 0.759521, 0.054256, 0.898794, -0.438371, 0, 0.438371, 0.898794, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "RightEyelid", h = 1, a = 1, b = 5, c0 = CFrame.new(0.379761, 0.141054, -0.455713, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 8, c0 = CFrame.new(1.030781, 1.302036, 0.054256, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 10, c0 = CFrame.new(0.477409, -0.206156, -0.43401, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 12, c0 = CFrame.new(0.81377, 0.759521, 0.054256, 0.898794, 0.438371, 0, -0.438371, 0.898794, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "LeftEyelid", h = 1, a = 1, b = 15, c0 = CFrame.new(-0.379761, 0.141054, -0.455713, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 17, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 18, c0 = CFrame.new(0.379759, 0, -0.43401, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 21, c0 = CFrame.new(-0.477419, -0.206156, -0.43401, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 22, c0 = CFrame.new(-1.030777, 1.302036, 0.054249, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 23, c0 = CFrame.new(0.423161, 0.075952, -0.477413, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 24, c0 = CFrame.new(0.065102, -0.227856, -0.444862, 0.965926, -0.258819, 0, 0.258819, 0.965926, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 25, c0 = CFrame.new(-0.379761, 0, -0.43401, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 27, c0 = CFrame.new(-0.336359, 0.075952, -0.477413, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "Neck", h = 3, a = 3, b = 1, c0 = CFrame.new(0, 0.596767, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.488264, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 3, a = 3, b = 4, c0 = CFrame.new(-0.542515, -0.542515, 0.021701, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.217006, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 3, a = 3, b = 7, c0 = CFrame.new(0.922276, 0.217006, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.162755, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 3, a = 3, b = 9, c0 = CFrame.new(0.542515, -0.542515, 0.021701, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.217006, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 13, c0 = CFrame.new(0, -0.054251, -0.412308, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "ShoulderL", h = 3, a = 3, b = 14, c0 = CFrame.new(-0.922276, 0.217006, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.162755, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "TailJoint", h = 3, a = 3, b = 19, c0 = CFrame.new(0, -0.217006, 0.390611, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, -0.130204, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 29, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 16, c0 = CFrame.new(-0.108503, -0.151904, -0.26041, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 26, c0 = CFrame.new(0.108507, -0.151904, -0.249557, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 6, c0 = CFrame.new(0.43401, -0.108503, 0, 0.965926, -0.258819, 0, 0.258819, 0.965926, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 9, a = 9, b = 11, c0 = CFrame.new(-0.108503, -0.151904, -0.249557, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 9, a = 9, b = 28, c0 = CFrame.new(0.108503, -0.151904, -0.260406, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 20, c0 = CFrame.new(-0.43401, -0.108503, 0.000004, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 0, 0, 1), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
		{ n = "DesertSpores", p = 1, rate = 2.8, enabled = true, lifetime = NumberRange.new(1.4, 2.2), speed = NumberRange.new(0.434012, 0.976527), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.130204, 0), NumberSequenceKeypoint.new(1, 0.032551, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8, 0), NumberSequenceKeypoint.new(0.5, 0.15, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.980392, 0.862745, 0.54902)), ColorSequenceKeypoint.new(1, Color3.new(0.980392, 0.862745, 0.54902)) }), lightEmission = 0, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(50, 50), acceleration = Vector3.new(0, 0, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 11, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 12, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 13, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 14, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 17, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 28, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 29, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
