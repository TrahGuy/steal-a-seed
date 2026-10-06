--!strict
--==============================================================================
-- PLANT FORM: Toadcap (Greenhollow Plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Greenhollow Plants/Toadcap" by a read-only generator on 2026-10-03. The original
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
	Source = "Greenhollow Plants/Toadcap", Kind = "plant", Yaw = 0,
	Size = Vector3.new(7.416595, 7.700001, 7.416595), Height = 7.700001, PartCount = 33,
	Base = 1,
	Unit = 4, ModelScale = 2.081081,
	Attributes = {},
	Parts = {
		{ n = "Body", s = "Block", z = Vector3.new(2.913514, 2.185135, 2.913514), cf = CFrame.new(0, 2.164324, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(230, 220, 194), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "Head", s = "Block", z = Vector3.new(2.705405, 1.977027, 2.601351), cf = CFrame.new(0, 4.245405, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 238, 212), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "CapGills", s = "Block", z = Vector3.new(4.994595, 0.728378, 4.994595), cf = CFrame.new(0, 5.556487, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(236, 226, 196), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "CapDomeT", s = "Block", z = Vector3.new(3.641892, 0.936486, 3.641892), cf = CFrame.new(0, 7.013244, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 76, 65), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "GlintR", s = "Block", z = Vector3.new(0.166486, 0.166486, 0.104054), cf = CFrame.new(0.811615, 4.287027, -1.373513, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 5
		{ n = "LegR", s = "Block", z = Vector3.new(1.352703, 1.144595, 1.352703), cf = CFrame.new(1.144596, 0.707567, 0.104054, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 80, 50), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "ArmR", s = "Block", z = Vector3.new(0.728378, 1.040541, 0.728378), cf = CFrame.new(1.456757, 1.956216, -0.104054, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(230, 220, 194), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "LidR", s = "Block", z = Vector3.new(0.582703, 0.332973, 0.208108), cf = CFrame.new(0.728378, 4.453513, -1.331892, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 238, 212), m = Enum.Material.Plastic, st = false }, -- 8
		{ n = "CapGillsCross", s = "Block", z = Vector3.new(4.828108, 0.686757, 4.828108), cf = CFrame.new(0, 5.556487, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(236, 226, 196), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "ToeL1", s = "Block", z = Vector3.new(0.582703, 0.457838, 0.874054), cf = CFrame.new(-1.415138, 0.228919, -0.520276, 0.965926, 0, -0.258819, 0, 1, 0, 0.258819, 0, 0.965926), c = Color3.fromRGB(115, 80, 50), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "LegL", s = "Block", z = Vector3.new(1.352703, 1.144595, 1.352703), cf = CFrame.new(-1.144596, 0.707567, 0.104054, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 80, 50), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "SpotF", s = "Block", z = Vector3.new(0.874054, 0.24973, 0.874054), cf = CFrame.new(0, 7.158919, -1.352706, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c = Color3.fromRGB(252, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "CheekR", s = "Block", z = Vector3.new(0.665946, 0.312162, 0.166486), cf = CFrame.new(0.957298, 3.829189, -1.269461, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(240, 160, 150), m = Enum.Material.Plastic, st = false }, -- 13
		{ n = "Belly", s = "Block", z = Vector3.new(2.081081, 1.664865, 0.582703), cf = CFrame.new(0, 2.06027, -1.415136, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 238, 212), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "CapDomeTCross", s = "Block", z = Vector3.new(3.496216, 0.894865, 3.496216), cf = CFrame.new(0, 7.013244, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(225, 76, 65), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "ToeL2", s = "Block", z = Vector3.new(0.582703, 0.457838, 0.790811), cf = CFrame.new(-0.874054, 0.228919, -0.499465, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c = Color3.fromRGB(115, 80, 50), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "Mouth", s = "Block", z = Vector3.new(0.457838, 0.166486, 0.124865), cf = CFrame.new(0.000004, 3.725135, -1.269461, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 95, 75), m = Enum.Material.Plastic, st = false }, -- 17
		{ n = "ArmL", s = "Block", z = Vector3.new(0.728378, 1.040541, 0.728378), cf = CFrame.new(-1.456757, 1.956216, -0.104054, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(230, 220, 194), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "ToeR2", s = "Block", z = Vector3.new(0.582703, 0.457838, 0.790811), cf = CFrame.new(0.874054, 0.228919, -0.499461, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c = Color3.fromRGB(115, 80, 50), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "LidL", s = "Block", z = Vector3.new(0.582703, 0.332973, 0.208108), cf = CFrame.new(-0.728378, 4.453513, -1.331892, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 238, 212), m = Enum.Material.Plastic, st = false }, -- 20
		{ n = "CapDomeLCross", s = "Block", z = Vector3.new(5.244325, 1.102973, 5.244325), cf = CFrame.new(0, 6.180812, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(225, 76, 65), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "CapDomeL", s = "Block", z = Vector3.new(5.410811, 1.144595, 5.410811), cf = CFrame.new(0, 6.180812, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 76, 65), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "HeadCross", s = "Block", z = Vector3.new(2.580541, 1.914595, 2.497298), cf = CFrame.new(0, 4.245405, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(246, 238, 212), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "BodyCross", s = "Block", z = Vector3.new(2.80946, 2.122703, 2.80946), cf = CFrame.new(0, 2.164324, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(230, 220, 194), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "EyeR", s = "Block", z = Vector3.new(0.499459, 0.541081, 0.166486), cf = CFrame.new(0.728378, 4.182973, -1.290272, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 28, 25), m = Enum.Material.Neon, st = false }, -- 25
		{ n = "EyeL", s = "Block", z = Vector3.new(0.499459, 0.541081, 0.166486), cf = CFrame.new(-0.728378, 4.182973, -1.290272, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 28, 25), m = Enum.Material.Neon, st = false }, -- 26
		{ n = "SpotR", s = "Block", z = Vector3.new(0.874054, 0.24973, 0.874054), cf = CFrame.new(1.560806, 6.742703, 0, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(252, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "SpotCenter", s = "Block", z = Vector3.new(1.144595, 0.24973, 1.144595), cf = CFrame.new(0, 7.575136, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "GlintL", s = "Block", z = Vector3.new(0.166486, 0.166486, 0.104054), cf = CFrame.new(-0.645134, 4.287027, -1.373513, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 29
		{ n = "ToeR1", s = "Block", z = Vector3.new(0.582703, 0.457838, 0.874054), cf = CFrame.new(1.415134, 0.228919, -0.520268, 0.965926, 0, 0.258819, 0, 1, 0, -0.258819, 0, 0.965926), c = Color3.fromRGB(115, 80, 50), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "CheekL", s = "Block", z = Vector3.new(0.665946, 0.312162, 0.166486), cf = CFrame.new(-0.957294, 3.829189, -1.269461, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(240, 160, 150), m = Enum.Material.Plastic, st = false }, -- 31
		{ n = "SpotL", s = "Block", z = Vector3.new(0.874054, 0.24973, 0.874054), cf = CFrame.new(-1.56081, 6.742703, 0, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(252, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "ShelfFungus", s = "Block", z = Vector3.new(1.352703, 0.416216, 0.936486), cf = CFrame.new(0, 1.78973, 1.727297, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 76, 65), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
	},
	Joints = {
		{ k = "Motor6D", n = "Neck", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 1.144595, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.936486, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 6, c0 = CFrame.new(1.144595, -0.998919, 0.104054, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.457838, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 1, a = 1, b = 7, c0 = CFrame.new(1.456757, 0.208108, -0.104054, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.416216, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 11, c0 = CFrame.new(-1.144595, -0.998919, 0.104054, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.457838, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 14, c0 = CFrame.new(0, -0.104054, -1.415136, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "ShoulderL", h = 1, a = 1, b = 18, c0 = CFrame.new(-1.456757, 0.208108, -0.104054, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.416216, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 24, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TailJoint", h = 1, a = 1, b = 33, c0 = CFrame.new(0, -0.374595, 1.352703, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, -0.374595, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CapJoint", h = 2, a = 2, b = 3, c0 = CFrame.new(0, 0.998919, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.312162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 5, c0 = CFrame.new(0.811615, 0.041622, -1.373513, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "RightEyelid", h = 2, a = 2, b = 8, c0 = CFrame.new(0.728378, 0.208108, -1.331892, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 13, c0 = CFrame.new(0.957298, -0.416216, -1.269461, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 17, c0 = CFrame.new(0.000004, -0.52027, -1.269461, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "LeftEyelid", h = 2, a = 2, b = 20, c0 = CFrame.new(-0.728378, 0.208108, -1.331892, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 23, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 25, c0 = CFrame.new(0.728378, -0.062432, -1.290272, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 26, c0 = CFrame.new(-0.728378, -0.062432, -1.290272, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 29, c0 = CFrame.new(-0.645134, 0.041622, -1.373513, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 31, c0 = CFrame.new(-0.957294, -0.416216, -1.269461, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 4, c0 = CFrame.new(0, 1.456757, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 9, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 12, c0 = CFrame.new(0, 1.602432, -1.352706, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 15, c0 = CFrame.new(0, 1.456757, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 21, c0 = CFrame.new(0, 0.624325, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 22, c0 = CFrame.new(0, 0.624325, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 27, c0 = CFrame.new(1.560806, 1.186216, 0, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 28, c0 = CFrame.new(0, 2.018649, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 32, c0 = CFrame.new(-1.56081, 1.186216, 0, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 19, c0 = CFrame.new(-0.270542, -0.478649, -0.603516, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 30, c0 = CFrame.new(0.270538, -0.478649, -0.624323, 0.965926, 0, 0.258819, 0, 1, 0, -0.258819, 0, 0.965926), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 10, c0 = CFrame.new(-0.270542, -0.478649, -0.624331, 0.965926, 0, -0.258819, 0, 1, 0, 0.258819, 0, 0.965926), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 16, c0 = CFrame.new(0.270542, -0.478649, -0.603519, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
		{ n = "MushroomSpores", p = 3, rate = 3.2, enabled = true, lifetime = NumberRange.new(1.5, 2.5), speed = NumberRange.new(0.624324, 1.456757), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.291351, 0), NumberSequenceKeypoint.new(1, 0.062432, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8, 0), NumberSequenceKeypoint.new(0.5, 0.12, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 0.764706, 0.627451)), ColorSequenceKeypoint.new(1, Color3.new(1, 0.764706, 0.627451)) }), lightEmission = 0, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(70, 70), acceleration = Vector3.new(0, 0, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 10, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 11, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 12, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 14, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 18, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 23, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 28, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 30, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 32, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 33, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
