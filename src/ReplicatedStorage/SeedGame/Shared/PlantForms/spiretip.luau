--!strict
--==============================================================================
-- PLANT FORM: Spiretip (Greenhollow Plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Greenhollow Plants/Spiretip" by a read-only generator on 2026-10-03. The original
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
	Source = "Greenhollow Plants/Spiretip", Kind = "plant", Yaw = 0,
	Size = Vector3.new(2.220871, 8.055, 2.321475), Height = 8.055, PartCount = 33,
	Base = 2,
	Unit = 3, ModelScale = 1.593472,
	Attributes = {},
	Parts = {
		{ n = "Mouth", s = "Block", z = Vector3.new(0.254956, 0.111543, 0.095608), cf = CFrame.new(0.000004, 3.569378, -0.876412, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(35, 60, 38), m = Enum.Material.Plastic, st = false }, -- 1
		{ n = "Body", s = "Block", z = Vector3.new(1.434125, 1.99184, 1.434125), cf = CFrame.new(0, 2.135253, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 88, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "Head", s = "Block", z = Vector3.new(1.673145, 1.673145, 1.673145), cf = CFrame.new(0, 3.967746, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 88, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "HeadCross", s = "Block", z = Vector3.new(1.561602, 1.625341, 1.561602), cf = CFrame.new(0, 3.967746, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(48, 88, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "ToeL1", s = "Block", z = Vector3.new(0.254956, 0.254956, 0.605519), cf = CFrame.new(-0.605518, 0.127478, -0.239021, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c = Color3.fromRGB(98, 70, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "LegL", s = "Block", z = Vector3.new(0.446172, 1.035757, 0.446172), cf = CFrame.new(-0.557713, 0.637389, -0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(98, 70, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "LidL", s = "Block", z = Vector3.new(0.398368, 0.223086, 0.143412), cf = CFrame.new(-0.478039, 4.190832, -0.908279, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 88, 54), m = Enum.Material.Plastic, st = false }, -- 7
		{ n = "GlintL", s = "Block", z = Vector3.new(0.127478, 0.127478, 0.079674), cf = CFrame.new(-0.414303, 3.999615, -0.940149, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 8
		{ n = "LegR", s = "Block", z = Vector3.new(0.446172, 1.035757, 0.446172), cf = CFrame.new(0.557716, 0.637389, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(98, 70, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "ToeR1", s = "Block", z = Vector3.new(0.254956, 0.254956, 0.605519), cf = CFrame.new(0.605515, 0.127478, -0.239021, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c = Color3.fromRGB(98, 70, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "CollarR", s = "Block", z = Vector3.new(0.669258, 0.223086, 1.035757), cf = CFrame.new(0.764866, 3.091336, 0, 0.866026, 0.5, 0, -0.5, 0.866026, 0, 0, 0, 1), c = Color3.fromRGB(224, 238, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "BodyCross", s = "Block", z = Vector3.new(1.370386, 1.944036, 1.370386), cf = CFrame.new(0, 2.135253, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(48, 88, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "CheekR", s = "Block", z = Vector3.new(0.414303, 0.191217, 0.111543), cf = CFrame.new(0.605518, 3.649051, -0.876411, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(235, 155, 145), m = Enum.Material.Plastic, st = false }, -- 13
		{ n = "ArmL", s = "Block", z = Vector3.new(0.318694, 1.354451, 0.446172), cf = CFrame.new(-0.764866, 2.214926, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(62, 112, 70), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "SpireCross", s = "Block", z = Vector3.new(1.179169, 1.402255, 1.179169), cf = CFrame.new(0, 5.46561, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(58, 104, 65), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "SpireMid", s = "Block", z = Vector3.new(1.242908, 1.434125, 1.242908), cf = CFrame.new(0, 5.46561, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(58, 104, 65), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "ToeL2", s = "Block", z = Vector3.new(0.254956, 0.254956, 0.557715), cf = CFrame.new(-0.446167, 0.127478, -0.223089, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c = Color3.fromRGB(98, 70, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "EyeR", s = "Block", z = Vector3.new(0.350564, 0.398368, 0.127478), cf = CFrame.new(0.478043, 3.888072, -0.87641, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 30, 24), m = Enum.Material.Neon, st = false }, -- 18
		{ n = "LidR", s = "Block", z = Vector3.new(0.398368, 0.223086, 0.143412), cf = CFrame.new(0.478043, 4.190832, -0.908279, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 88, 54), m = Enum.Material.Plastic, st = false }, -- 19
		{ n = "SpireFinial", s = "Block", z = Vector3.new(0.446172, 0.717062, 0.446172), cf = CFrame.new(0, 7.696471, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(132, 192, 108), m = Enum.Material.Neon, st = false }, -- 20
		{ n = "ToeR2", s = "Block", z = Vector3.new(0.254956, 0.254956, 0.557715), cf = CFrame.new(0.446175, 0.127478, -0.223085, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c = Color3.fromRGB(98, 70, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "CollarL", s = "Block", z = Vector3.new(0.669258, 0.223086, 1.035757), cf = CFrame.new(-0.764866, 3.091336, 0, 0.866026, -0.5, 0, 0.5, 0.866026, 0, 0, 0, 1), c = Color3.fromRGB(224, 238, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "HandR", s = "Block", z = Vector3.new(0.286825, 0.557715, 0.350564), cf = CFrame.new(0.712574, 1.404096, -0.127478, 0.965926, 0.25, -0.066987, -0.258819, 0.933013, -0.25, 0, 0.258819, 0.965926), c = Color3.fromRGB(132, 192, 108), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "ArmR", s = "Block", z = Vector3.new(0.318694, 1.354451, 0.446172), cf = CFrame.new(0.764866, 2.214926, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(62, 112, 70), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "CollarF", s = "Block", z = Vector3.new(1.035757, 0.223086, 0.669258), cf = CFrame.new(0, 3.091336, -0.764866, 1, 0, 0, 0, 0.866026, 0.5, 0, -0.5, 0.866026), c = Color3.fromRGB(224, 238, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "HandL", s = "Block", z = Vector3.new(0.286825, 0.557715, 0.350564), cf = CFrame.new(-0.712574, 1.404096, -0.127481, 0.965926, -0.25, 0.066987, 0.258819, 0.933013, -0.25, 0, 0.258819, 0.965926), c = Color3.fromRGB(132, 192, 108), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "CollarB", s = "Block", z = Vector3.new(1.035757, 0.223086, 0.669258), cf = CFrame.new(0, 3.091336, 0.764862, 1, 0, 0, 0, 0.866026, -0.5, 0, 0.5, 0.866026), c = Color3.fromRGB(224, 238, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "GlintR", s = "Block", z = Vector3.new(0.127478, 0.127478, 0.079674), cf = CFrame.new(0.541782, 3.999615, -0.940153, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false }, -- 28
		{ n = "CheekL", s = "Block", z = Vector3.new(0.414303, 0.191217, 0.111543), cf = CFrame.new(-0.605518, 3.649051, -0.876409, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(235, 155, 145), m = Enum.Material.Plastic, st = false }, -- 29
		{ n = "TailVine", s = "Block", z = Vector3.new(0.318694, 0.796736, 0.318694), cf = CFrame.new(0, 1.529734, 1.051691, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(98, 70, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "EyeL", s = "Block", z = Vector3.new(0.350564, 0.398368, 0.127478), cf = CFrame.new(-0.478043, 3.888072, -0.876411, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 30, 24), m = Enum.Material.Neon, st = false }, -- 31
		{ n = "Belly", s = "Block", z = Vector3.new(1.035757, 1.434125, 0.350564), cf = CFrame.new(0, 2.055579, -0.732996, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(58, 104, 65), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "SpireTop", s = "Block", z = Vector3.new(0.796736, 1.354451, 0.796736), cf = CFrame.new(0, 6.740387, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 88, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
	},
	Joints = {
		{ k = "Motor6D", n = "Neck", h = 2, a = 2, b = 3, c0 = CFrame.new(0, 1.035757, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.796736, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 2, a = 2, b = 6, c0 = CFrame.new(-0.557715, -0.987953, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.509911, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 2, a = 2, b = 9, c0 = CFrame.new(0.557715, -0.987953, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.509911, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 11, c0 = CFrame.new(0.764866, 0.956083, 0, 0.866026, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 12, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Motor6D", n = "ShoulderL", h = 2, a = 2, b = 14, c0 = CFrame.new(-0.764866, 0.717062, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.637389, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 22, c0 = CFrame.new(-0.764866, 0.956083, 0, 0.866026, -0.5, 0, 0.5, 0.866025, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "ShoulderR", h = 2, a = 2, b = 24, c0 = CFrame.new(0.764866, 0.717062, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.637389, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 25, c0 = CFrame.new(0, 0.956083, -0.764866, 1, 0, 0, 0, 0.866025, 0.5, 0, -0.5, 0.866026), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 27, c0 = CFrame.new(0, 0.956083, 0.764862, 1, 0, 0, 0, 0.866025, -0.5, 0, 0.5, 0.866026), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TailJoint", h = 2, a = 2, b = 30, c0 = CFrame.new(0, -0.605519, 0.732997, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, -0.318694, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 32, c0 = CFrame.new(0, -0.079674, -0.732996, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 1, c0 = CFrame.new(0.000004, -0.398368, -0.876412, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 4, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Motor6D", n = "LeftEyelid", h = 3, a = 3, b = 7, c0 = CFrame.new(-0.478042, 0.223086, -0.908279, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 8, c0 = CFrame.new(-0.414303, 0.031869, -0.940149, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 13, c0 = CFrame.new(0.605518, -0.318694, -0.876411, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "SpireTipJoint", h = 3, a = 3, b = 16, c0 = CFrame.new(0, 0.828605, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.669258, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 18, c0 = CFrame.new(0.478043, -0.079674, -0.87641, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "RightEyelid", h = 3, a = 3, b = 19, c0 = CFrame.new(0.478042, 0.223086, -0.908279, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 28, c0 = CFrame.new(0.541782, 0.031869, -0.940153, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 29, c0 = CFrame.new(-0.605518, -0.318694, -0.876409, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 31, c0 = CFrame.new(-0.478043, -0.079674, -0.876411, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 5, c0 = CFrame.new(-0.047806, -0.509911, -0.23902, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 17, c0 = CFrame.new(0.111546, -0.509911, -0.223088, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 9, a = 9, b = 10, c0 = CFrame.new(0.047798, -0.509911, -0.239021, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 9, a = 9, b = 21, c0 = CFrame.new(-0.111542, -0.509911, -0.223085, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 26, c0 = CFrame.new(0.052292, -0.81083, -0.127481, 0.965926, -0.25, 0.066987, 0.258819, 0.933013, -0.25, 0, 0.258819, 0.965926), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 16, a = 16, b = 15, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 16, a = 16, b = 20, c0 = CFrame.new(0, 2.230861, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 16, a = 16, b = 33, c0 = CFrame.new(0, 1.274777, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 24, a = 24, b = 23, c0 = CFrame.new(-0.052292, -0.81083, -0.127478, 0.965926, 0.25, -0.066987, -0.258819, 0.933013, -0.25, 0, 0.258819, 0.965926), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
		{ n = "PineSpores", p = 16, rate = 2.8, enabled = true, lifetime = NumberRange.new(1.4, 2.4), speed = NumberRange.new(0.478042, 1.274778), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.191217, 0), NumberSequenceKeypoint.new(1, 0.031869, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8, 0), NumberSequenceKeypoint.new(0.5, 0.15, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.705882, 0.941176, 0.627451)), ColorSequenceKeypoint.new(1, Color3.new(0.705882, 0.941176, 0.627451)) }), lightEmission = 0, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(50, 50), acceleration = Vector3.new(0, 0, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 10, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 11, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 12, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 14, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 17, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 23, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 25, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 30, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 32, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 33, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
