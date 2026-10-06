--!strict
--==============================================================================
-- PLANT FORM: Dunebud (Dustbowl plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Dustbowl plants/Dunebud" by a read-only generator on 2026-10-03. The original
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
	Source = "Dustbowl plants/Dunebud", Kind = "plant", Yaw = 0,
	Size = Vector3.new(2.15728, 3.154598, 1.844238), Height = 3.154598, PartCount = 27,
	Base = 1,
	Unit = 1, ModelScale = 1,
	Attributes = {},
	Parts = {
		{ n = "Body", s = "Block", z = Vector3.new(1.3, 0.95, 1.3), cf = CFrame.new(0, 0.76, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 172, 130), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "Head", s = "Block", z = Vector3.new(1.38, 1.15, 1.38), cf = CFrame.new(0, 1.86, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 172, 130), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "CheekL", s = "Block", z = Vector3.new(0.3, 0.15, 0.08), cf = CFrame.new(-0.460003, 1.67, -0.700001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(235, 148, 118), m = Enum.Material.Plastic, st = false }, -- 3
		{ n = "FlowerStem", s = "Block", z = Vector3.new(0.22, 0.28, 0.22), cf = CFrame.new(0.650002, 2.63, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 172, 130), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "FlowerCore", s = "Block", z = Vector3.new(0.35, 0.18, 0.35), cf = CFrame.new(0.710587, 2.892163, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(205, 125, 42), m = Enum.Material.Neon, st = false }, -- 5
		{ n = "BodyCross", s = "Block", z = Vector3.new(1.26, 0.92, 1.26), cf = CFrame.new(0, 0.76, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(132, 158, 118), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "ToeL1", s = "Block", z = Vector3.new(0.16, 0.16, 0.32), cf = CFrame.new(-0.549999, 0.08, -0.239998, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c = Color3.fromRGB(134, 92, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "FootL", s = "Block", z = Vector3.new(0.42, 0.3, 0.52), cf = CFrame.new(-0.459999, 0.16, 0.049999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(134, 92, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "PetalMain", s = "Block", z = Vector3.new(0.95, 0.14, 0.38), cf = CFrame.new(0.710587, 2.892163, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 214, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "ToeL2", s = "Block", z = Vector3.new(0.16, 0.16, 0.3), cf = CFrame.new(-0.379997, 0.08, -0.23, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c = Color3.fromRGB(134, 92, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "GlintR", s = "Block", z = Vector3.new(0.08, 0.08, 0.05), cf = CFrame.new(0.399998, 1.93, -0.739998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 11
		{ n = "FootR", s = "Block", z = Vector3.new(0.42, 0.3, 0.52), cf = CFrame.new(0.459999, 0.16, 0.049999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(134, 92, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "ToeR1", s = "Block", z = Vector3.new(0.16, 0.16, 0.32), cf = CFrame.new(0.550003, 0.08, -0.240002, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c = Color3.fromRGB(134, 92, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "ToeR2", s = "Block", z = Vector3.new(0.16, 0.16, 0.3), cf = CFrame.new(0.380001, 0.08, -0.230007, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c = Color3.fromRGB(134, 92, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "HeadCross", s = "Block", z = Vector3.new(1.3, 1.12, 1.3), cf = CFrame.new(0, 1.86, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(132, 158, 118), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "LidR", s = "Block", z = Vector3.new(0.27, 0.15, 0.09), cf = CFrame.new(0.360001, 1.99, -0.720001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 172, 130), m = Enum.Material.Plastic, st = false }, -- 16
		{ n = "LidL", s = "Block", z = Vector3.new(0.27, 0.15, 0.09), cf = CFrame.new(-0.360001, 1.99, -0.720001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 172, 130), m = Enum.Material.Plastic, st = false }, -- 17
		{ n = "EyeL", s = "Block", z = Vector3.new(0.24, 0.26, 0.08), cf = CFrame.new(-0.360001, 1.86, -0.699997, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(28, 28, 26), m = Enum.Material.Neon, st = false }, -- 18
		{ n = "EyeR", s = "Block", z = Vector3.new(0.24, 0.26, 0.08), cf = CFrame.new(0.360001, 1.86, -0.700001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(28, 28, 26), m = Enum.Material.Neon, st = false }, -- 19
		{ n = "SandBelly", s = "Block", z = Vector3.new(0.9, 0.72, 0.25), cf = CFrame.new(-0.000004, 0.73, -0.579994, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(218, 196, 152), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "PetalCross", s = "Block", z = Vector3.new(0.38, 0.14, 0.95), cf = CFrame.new(0.710587, 2.892163, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 214, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "GlintL", s = "Block", z = Vector3.new(0.08, 0.08, 0.05), cf = CFrame.new(-0.320004, 1.93, -0.739998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 22
		{ n = "CheekR", s = "Block", z = Vector3.new(0.3, 0.15, 0.08), cf = CFrame.new(0.459999, 1.67, -0.700001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(235, 148, 118), m = Enum.Material.Plastic, st = false }, -- 23
		{ n = "Mouth", s = "Block", z = Vector3.new(0.18, 0.07, 0.06), cf = CFrame.new(-0.000004, 1.63, -0.699997, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(75, 95, 65), m = Enum.Material.Plastic, st = false }, -- 24
		{ n = "PetalAngle", s = "Block", z = Vector3.new(0.75, 0.13, 0.75), cf = CFrame.new(0.710587, 2.892163, 0, 0.803466, -0.137615, 0.579228, -0.137615, 0.903641, 0.40558, -0.579228, -0.40558, 0.707107), c = Color3.fromRGB(252, 214, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "TailBud", s = "Block", z = Vector3.new(0.28, 0.28, 0.35), cf = CFrame.new(0, 0.59, 0.75, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 172, 130), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "SandBrow", s = "Block", z = Vector3.new(0.85, 0.18, 0.22), cf = CFrame.new(0, 2.16, -0.649998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(218, 196, 152), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
	},
	Joints = {
		{ k = "Motor6D", n = "Neck", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0.55, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.55, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 6, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 8, c0 = CFrame.new(-0.46, -0.45, 0.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.15, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 12, c0 = CFrame.new(0.46, -0.45, 0.05, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.15, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 20, c0 = CFrame.new(-0.000004, -0.03, -0.579994, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TailJoint", h = 1, a = 1, b = 26, c0 = CFrame.new(0, -0.17, 0.6, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, -0.15, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 3, c0 = CFrame.new(-0.460003, -0.19, -0.700001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "FlowerJoint", h = 2, a = 2, b = 4, c0 = CFrame.new(0.55, 0.62, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.1, -0.15, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 11, c0 = CFrame.new(0.399998, 0.07, -0.739998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 15, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Motor6D", n = "RightEyelid", h = 2, a = 2, b = 16, c0 = CFrame.new(0.36, 0.13, -0.72, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LeftEyelid", h = 2, a = 2, b = 17, c0 = CFrame.new(-0.36, 0.13, -0.72, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 18, c0 = CFrame.new(-0.360001, 0, -0.699997, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 19, c0 = CFrame.new(0.360001, 0, -0.700001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 22, c0 = CFrame.new(-0.320004, 0.07, -0.739998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 23, c0 = CFrame.new(0.459999, -0.19, -0.700001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 24, c0 = CFrame.new(-0.000004, -0.23, -0.699997, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 27, c0 = CFrame.new(0, 0.3, -0.649998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(0.060585, 0.262163, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 9, c0 = CFrame.new(0.060585, 0.262163, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 21, c0 = CFrame.new(0.060585, 0.262163, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 25, c0 = CFrame.new(0.060585, 0.262163, 0, 0.803466, -0.137615, 0.579228, -0.137615, 0.903641, 0.40558, -0.579228, -0.40558, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 7, c0 = CFrame.new(-0.09, -0.08, -0.289997, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 10, c0 = CFrame.new(0.080002, -0.08, -0.279999, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 13, c0 = CFrame.new(0.090004, -0.08, -0.290001, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 14, c0 = CFrame.new(-0.079998, -0.08, -0.280006, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
		{ n = "DesertPollen", p = 4, rate = 2.8, enabled = true, lifetime = NumberRange.new(1.4, 2.2), speed = NumberRange.new(0.4, 0.9), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12, 0), NumberSequenceKeypoint.new(1, 0.03, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8, 0), NumberSequenceKeypoint.new(0.5, 0.15, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 0.882353, 0.509804)), ColorSequenceKeypoint.new(1, Color3.new(1, 0.882353, 0.509804)) }), lightEmission = 0, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(50, 50), acceleration = Vector3.new(0, 0, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 8, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 10, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 12, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 13, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 14, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 25, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
