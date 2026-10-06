--!strict
--==============================================================================
-- PLANT FORM: Crookreed (Tanglemire)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Tanglemire/Crookreed" by a read-only generator on 2026-10-03. The original
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
	Source = "Tanglemire/Crookreed", Kind = "plant", Yaw = 0,
	Size = Vector3.new(2.326332, 3.069885, 1.399315), Height = 3.069885, PartCount = 36,
	Base = 2,
	Unit = 4.5, ModelScale = 0.434787,
	Attributes = {},
	Parts = {
		{ n = "LeafArmR", s = "Wedge", z = Vector3.new(0.068479, 0.684789, 0.136958), cf = CFrame.new(-0.816368, 1.422732, -0.02935, 0, -0.951056, 0.309017, 0, 0.309017, 0.951056, -1, 0, 0), c = Color3.fromRGB(112, 167, 82), m = Enum.Material.Plastic }, -- 1
		{ n = "Footing", s = "Block", z = Vector3.new(0.430439, 0.078262, 0.430439), cf = CFrame.new(0, 0.03204, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(39, 67, 36), m = Enum.Material.Plastic, t = 1, cs = false }, -- 2
		{ n = "ArmStemR", s = "Block", z = Vector3.new(0.066522, 0.066522, 0.41728), cf = CFrame.new(-0.269024, 1.430967, 0.000977, 0.14952, -0.231805, 0.961203, 0, 0.972131, 0.23444, -0.988759, -0.035053, 0.145353), c = Color3.fromRGB(129, 151, 76), m = Enum.Material.Plastic }, -- 3
		{ n = "LeafArmHalfR", s = "Wedge", z = Vector3.new(0.068479, 0.684789, 0.136958), cf = CFrame.new(-0.774044, 1.552986, -0.02935, 0, -0.951056, -0.309017, 0, 0.309017, -0.951056, 1, 0, 0), c = Color3.fromRGB(158, 188, 103), m = Enum.Material.Plastic }, -- 4
		{ n = "MainReed", s = "Block", z = Vector3.new(0.146741, 0.146741, 1.29191), cf = CFrame.new(0, 0.990745, 0.019566, 1, 0, 0, 0, -0.030289, -0.999541, 0, 0.999541, -0.030289), c = Color3.fromRGB(100, 126, 63), m = Enum.Material.Plastic }, -- 5
		{ n = "CrookedStalk", s = "Block", z = Vector3.new(0.131088, 0.131088, 1.095313), cf = CFrame.new(0.17609, 2.154886, 0.048912, -0.05547, -0.945273, -0.321531, 0, 0.322027, -0.94673, 0.99846, -0.052515, -0.017863), c = Color3.fromRGB(129, 151, 76), m = Enum.Material.Plastic }, -- 6
		{ n = "NeckKnot", s = "Block", z = Vector3.new(0.166306, 0.117392, 0.166306), cf = CFrame.new(0.35218, 2.67337, 0.058693, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(176, 177, 104), m = Enum.Material.Plastic }, -- 7
		{ n = "NodeRing1", s = "Cylinder", z = Vector3.new(0.088044, 0.234785, 0.234785), cf = CFrame.new(0, 0.892918, 0.016602, 0, -1, 0, 1, 0, 0, 0, 0, 1), c = Color3.fromRGB(176, 177, 104), m = Enum.Material.Plastic }, -- 8
		{ n = "RootFoot4", s = "Block", z = Vector3.new(0.088044, 0.088044, 0.521795), cf = CFrame.new(-0.1591, 0.21302, 0.1591, -0.707107, -0.357938, 0.60982, 0, 0.862416, 0.506201, -0.707107, 0.357938, -0.60982), c = Color3.fromRGB(99, 89, 57), m = Enum.Material.Plastic }, -- 9
		{ n = "RootToe4R", s = "Block", z = Vector3.new(0.058696, 0.048914, 0.403664), cf = CFrame.new(-0.501511, 0.052584, 0.397751, -0.398093, -0.128944, 0.908238, 0, 0.990072, 0.140561, -0.917345, 0.055957, -0.394141), c = Color3.fromRGB(135, 116, 73), m = Enum.Material.Plastic }, -- 10
		{ n = "Head", s = "Wedge", z = Vector3.new(0.127175, 0.743486, 0.273916), cf = CFrame.new(0.569084, 2.20566, -0.332615, 0, 0.156435, 0.987688, 0, 0.987688, -0.156434, -1, 0, 0), c = Color3.fromRGB(93, 149, 74), m = Enum.Material.Plastic }, -- 11
		{ n = "FaceHalf", s = "Wedge", z = Vector3.new(0.127175, 0.743486, 0.273916), cf = CFrame.new(0.839626, 2.16281, -0.332615, 0, 0.156435, -0.987688, 0, 0.987688, 0.156434, 1, 0, 0), c = Color3.fromRGB(112, 167, 82), m = Enum.Material.Plastic }, -- 12
		{ n = "BentNeck", s = "Block", z = Vector3.new(0.111523, 0.111523, 0.547132), cf = CFrame.new(0.528267, 2.507064, -0.068481, 0.58549, 0.492827, -0.643678, 0, 0.793999, 0.607919, 0.810679, -0.355931, 0.464879), c = Color3.fromRGB(100, 126, 63), m = Enum.Material.Plastic }, -- 13
		{ n = "LowerKnot", s = "Block", z = Vector3.new(0.185871, 0.10761, 0.166306), cf = CFrame.new(0, 1.636403, 0.039131, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(176, 177, 104), m = Enum.Material.Plastic }, -- 14
		{ n = "EyeShineR", s = "Block", z = Vector3.new(0.021522, 0.025435, 0.015652), cf = CFrame.new(0.617989, 2.164238, -0.438267, 0.987688, 0.156435, 0, -0.156434, 0.987688, 0, 0, 0, 1), c = Color3.fromRGB(253, 245, 185), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 15
		{ n = "ArmStemL", s = "Block", z = Vector3.new(0.066522, 0.066522, 0.41728), cf = CFrame.new(0.269024, 1.430967, 0.000977, 0.14952, 0.231805, -0.961203, 0, 0.972131, 0.23444, 0.988759, -0.035053, 0.145353), c = Color3.fromRGB(129, 151, 76), m = Enum.Material.Plastic }, -- 16
		{ n = "RootFoot1", s = "Block", z = Vector3.new(0.088044, 0.088044, 0.521795), cf = CFrame.new(0.1591, 0.21302, 0.1591, -0.707107, 0.357938, -0.60982, 0, 0.862416, 0.506201, 0.707107, 0.357938, -0.60982), c = Color3.fromRGB(99, 89, 57), m = Enum.Material.Plastic }, -- 17
		{ n = "EyeR", s = "Block", z = Vector3.new(0.072392, 0.080218, 0.023478), cf = CFrame.new(0.609745, 2.149697, -0.416748, 0.987688, 0.156435, 0, -0.156434, 0.987688, 0, 0, 0, 1), c = Color3.fromRGB(220, 216, 122), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 18
		{ n = "RootToe4L", s = "Block", z = Vector3.new(0.058696, 0.048914, 0.403664), cf = CFrame.new(-0.397751, 0.052584, 0.501511, -0.917345, -0.055957, 0.394141, 0, 0.990072, 0.140562, -0.398093, 0.128944, -0.908238), c = Color3.fromRGB(135, 116, 73), m = Enum.Material.Plastic }, -- 19
		{ n = "NodeRing2", s = "Cylinder", z = Vector3.new(0.088044, 0.234785, 0.234785), cf = CFrame.new(0, 1.597273, 0.037945, 0, -1, 0, 1, 0, 0, 0, 0, 1), c = Color3.fromRGB(176, 177, 104), m = Enum.Material.Plastic }, -- 20
		{ n = "EyeShineL", s = "Block", z = Vector3.new(0.021522, 0.025435, 0.015652), cf = CFrame.new(0.780315, 2.138528, -0.438267, 0.987688, 0.156435, 0, -0.156434, 0.987688, 0, 0, 0, 1), c = Color3.fromRGB(253, 245, 185), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 21
		{ n = "SeedStalk", s = "Block", z = Vector3.new(0.058696, 0.058696, 0.246128), cf = CFrame.new(0.303265, 2.78098, 0.092934, -0.573462, 0.716354, 0.397464, 0, 0.485166, -0.874422, -0.819232, -0.501448, -0.278225), c = Color3.fromRGB(176, 177, 104), m = Enum.Material.Plastic }, -- 22
		{ n = "RootToe1L", s = "Block", z = Vector3.new(0.058696, 0.048914, 0.403664), cf = CFrame.new(0.501511, 0.052584, 0.397751, -0.398093, 0.128944, -0.908238, 0, 0.990072, 0.140561, 0.917345, 0.055957, -0.394141), c = Color3.fromRGB(135, 116, 73), m = Enum.Material.Plastic }, -- 23
		{ n = "RootFoot2", s = "Block", z = Vector3.new(0.088044, 0.088044, 0.521795), cf = CFrame.new(0.1591, 0.21302, -0.1591, 0.707107, 0.357938, -0.60982, 0, 0.862416, 0.506201, 0.707107, -0.357938, 0.60982), c = Color3.fromRGB(99, 89, 57), m = Enum.Material.Plastic }, -- 24
		{ n = "LeafArmL", s = "Wedge", z = Vector3.new(0.068479, 0.684789, 0.136958), cf = CFrame.new(0.774044, 1.552986, -0.02935, 0, 0.951056, 0.309017, 0, 0.309017, -0.951056, -1, 0, 0), c = Color3.fromRGB(112, 167, 82), m = Enum.Material.Plastic }, -- 25
		{ n = "RootToe2R", s = "Block", z = Vector3.new(0.058696, 0.048914, 0.403664), cf = CFrame.new(0.501511, 0.052584, -0.397751, 0.398093, 0.128944, -0.908238, 0, 0.990072, 0.140561, 0.917345, -0.055957, 0.394141), c = Color3.fromRGB(135, 116, 73), m = Enum.Material.Plastic }, -- 26
		{ n = "FaceVein", s = "Block", z = Vector3.new(0.029348, 0.46957, 0.027392), cf = CFrame.new(0.690582, 2.097275, -0.414791, 0.987688, 0.156435, 0, -0.156434, 0.987688, 0, 0, 0, 1), c = Color3.fromRGB(181, 199, 115), m = Enum.Material.Plastic }, -- 27
		{ n = "EyeL", s = "Block", z = Vector3.new(0.072392, 0.080218, 0.023478), cf = CFrame.new(0.783665, 2.12215, -0.416744, 0.987688, 0.156435, 0, -0.156434, 0.987688, 0, 0, 0, 1), c = Color3.fromRGB(220, 216, 122), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 28
		{ n = "RootToe2L", s = "Block", z = Vector3.new(0.058696, 0.048914, 0.403664), cf = CFrame.new(0.397751, 0.052584, -0.501511, 0.917345, 0.055957, -0.394141, 0, 0.990072, 0.140562, 0.398093, -0.128944, 0.908238), c = Color3.fromRGB(135, 116, 73), m = Enum.Material.Plastic }, -- 29
		{ n = "LeafArmHalfL", s = "Wedge", z = Vector3.new(0.068479, 0.684789, 0.136958), cf = CFrame.new(0.816368, 1.422732, -0.02935, 0, 0.951056, -0.309017, 0, 0.309017, 0.951056, 1, 0, 0), c = Color3.fromRGB(158, 188, 103), m = Enum.Material.Plastic }, -- 30
		{ n = "RootFoot3", s = "Block", z = Vector3.new(0.088044, 0.088044, 0.521795), cf = CFrame.new(-0.1591, 0.21302, -0.1591, 0.707107, -0.357938, 0.60982, 0, 0.862416, 0.506201, -0.707107, -0.357938, 0.60982), c = Color3.fromRGB(99, 89, 57), m = Enum.Material.Plastic }, -- 31
		{ n = "RootToe3L", s = "Block", z = Vector3.new(0.058696, 0.048914, 0.403664), cf = CFrame.new(-0.501511, 0.052584, -0.397751, 0.398093, -0.128944, 0.908238, 0, 0.990072, 0.140561, -0.917345, -0.055957, 0.394141), c = Color3.fromRGB(135, 116, 73), m = Enum.Material.Plastic }, -- 32
		{ n = "RootToe3R", s = "Block", z = Vector3.new(0.058696, 0.048914, 0.403664), cf = CFrame.new(-0.397751, 0.052584, -0.501511, 0.917345, -0.055957, 0.394141, 0, 0.990072, 0.140562, -0.398093, -0.128944, 0.908238), c = Color3.fromRGB(135, 116, 73), m = Enum.Material.Plastic }, -- 33
		{ n = "SeedTuft", s = "Wedge", z = Vector3.new(0.146741, 0.234785, 0.088044), cf = CFrame.new(0.244568, 2.937503, 0.127174, 0.965926, -0.258819, 0, 0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(189, 155, 92), m = Enum.Material.Plastic }, -- 34
		{ n = "Mouth", s = "Block", z = Vector3.new(0.074349, 0.027392, 0.023478), cf = CFrame.new(0.672829, 1.985192, -0.43631, 0.987688, 0.156435, 0, -0.156434, 0.987688, 0, 0, 0, 1), c = Color3.fromRGB(39, 67, 36), m = Enum.Material.SmoothPlastic, st = false }, -- 35
		{ n = "RootToe1R", s = "Block", z = Vector3.new(0.058696, 0.048914, 0.403664), cf = CFrame.new(0.397751, 0.052584, 0.501511, -0.917345, 0.055957, -0.394141, 0, 0.990072, 0.140562, 0.398093, 0.128944, -0.908238), c = Color3.fromRGB(135, 116, 73), m = Enum.Material.Plastic }, -- 36
	},
	Joints = {
		{ k = "Weld", n = "Hold_LeafArmHalfR", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 0, 0.136958, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 2, a = 2, b = 5, c0 = CFrame.new(0, 0.313047, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.645955, 1, 0, 0, 0, -0.030289, 0.999541, 0, -0.999541, -0.030289) },
		{ k = "Motor6D", n = "Foot4", h = 2, a = 2, b = 9, c0 = CFrame.new(0, 0.313047, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.260898, -0.707107, 0, -0.707107, -0.357938, 0.862416, 0.357938, 0.60982, 0.506201, -0.60982) },
		{ k = "Motor6D", n = "Foot1", h = 2, a = 2, b = 17, c0 = CFrame.new(0, 0.313047, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.260898, -0.707107, 0, 0.707107, 0.357938, 0.862416, 0.357938, -0.60982, 0.506201, -0.60982) },
		{ k = "Motor6D", n = "Foot2", h = 2, a = 2, b = 24, c0 = CFrame.new(0, 0.313047, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.260898, 0.707107, 0, 0.707107, 0.357938, 0.862416, -0.357938, -0.60982, 0.506201, 0.60982) },
		{ k = "Motor6D", n = "Foot3", h = 2, a = 2, b = 31, c0 = CFrame.new(0, 0.313047, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.260898, 0.707107, 0, -0.707107, -0.357938, 0.862416, -0.357938, 0.60982, 0.506201, 0.60982) },
		{ k = "Motor6D", n = "LeafR", h = 3, a = 3, b = 1, c0 = CFrame.new(0, 0, -0.20864, 0.046204, -0.142202, -0.988759, 0.85292, 0.520864, -0.035053, 0.519994, -0.841712, 0.145353), c1 = CFrame.new(0, -0.342395, 0.068479, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
		{ k = "Motor6D", n = "ShoulderR", h = 5, a = 5, b = 3, c0 = CFrame.new(-0.068479, -0.003082, -0.489266, 1, 0, 0, 0, -0.030289, 0.999541, 0, -0.999541, -0.030289), c1 = CFrame.new(0, 0, 0.20864, 0.14952, 0, -0.988759, -0.231805, 0.972131, -0.035053, 0.961203, 0.23444, 0.145353) },
		{ k = "Motor6D", n = "Stem2", h = 5, a = 5, b = 6, c0 = CFrame.new(0, 0, -0.645955, 1, 0, 0, 0, -0.030289, 0.999541, 0, -0.999541, -0.030289), c1 = CFrame.new(0, 0, 0.547657, -0.05547, 0, 0.99846, -0.945273, 0.322027, -0.052515, -0.321531, -0.94673, -0.017863) },
		{ k = "Weld", n = "Hold_NodeRing1", h = 5, a = 5, b = 8, c0 = CFrame.new(0, 0, 0.097872, 0, -1, 0, -0.030289, 0, 0.999541, -0.999541, 0, -0.030289), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LowerKnot", h = 5, a = 5, b = 14, c0 = CFrame.new(0, 0, -0.645955, 1, 0, 0, 0, -0.030289, 0.999541, 0, -0.999541, -0.030289), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderL", h = 5, a = 5, b = 16, c0 = CFrame.new(0.068479, -0.003082, -0.489266, 1, 0, 0, 0, -0.030289, 0.999541, 0, -0.999541, -0.030289), c1 = CFrame.new(0, 0, 0.20864, 0.14952, 0, 0.988759, 0.231805, 0.972131, -0.035053, -0.961203, 0.23444, 0.145353) },
		{ k = "Weld", n = "Hold_NodeRing2", h = 5, a = 5, b = 20, c0 = CFrame.new(0, 0, -0.606806, 0, -1, 0, -0.030289, 0, 0.999541, -0.999541, 0, -0.030289), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_NeckKnot", h = 6, a = 6, b = 7, c0 = CFrame.new(0, 0, -0.547657, -0.05547, 0, 0.99846, -0.945273, 0.322027, -0.052515, -0.321531, -0.94673, -0.017863), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 6, a = 6, b = 13, c0 = CFrame.new(0, 0, -0.547657, -0.05547, 0, 0.99846, -0.945273, 0.322027, -0.052515, -0.321531, -0.94673, -0.017863), c1 = CFrame.new(0, 0, 0.273566, 0.585491, 0, 0.810679, 0.492827, 0.793999, -0.355931, -0.643679, 0.607919, 0.464879) },
		{ k = "Motor6D", n = "Crest", h = 6, a = 6, b = 22, c0 = CFrame.new(0, 0, -0.547657, -0.05547, 0, 0.99846, -0.945273, 0.322027, -0.052515, -0.321531, -0.94673, -0.017863), c1 = CFrame.new(0, 0, 0.123064, -0.573462, 0, -0.819232, 0.716354, 0.485166, -0.501448, 0.397464, -0.874422, -0.278225) },
		{ k = "Weld", n = "Hold_RootToe4R", h = 9, a = 9, b = 10, c0 = CFrame.new(0.07337, 0.069622, -0.435557, 0.930155, 0.05161, -0.363521, -0.18586, 0.920036, -0.344948, 0.31665, 0.388419, 0.865369), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootToe4L", h = 9, a = 9, b = 19, c0 = CFrame.new(-0.07337, 0.069622, -0.435557, 0.930155, -0.05161, 0.363521, 0.18586, 0.920036, -0.344948, -0.31665, 0.388419, 0.865369), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_FaceHalf", h = 11, a = 11, b = 12, c0 = CFrame.new(0, 0, 0.273916, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShineR", h = 11, a = 11, b = 15, c0 = CFrame.new(0.105653, -0.033261, 0.054783, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeR", h = 11, a = 11, b = 18, c0 = CFrame.new(0.084131, -0.048914, 0.048914, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShineL", h = 11, a = 11, b = 21, c0 = CFrame.new(0.105653, -0.033261, 0.219133, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_FaceVein", h = 11, a = 11, b = 27, c0 = CFrame.new(0.082175, -0.088045, 0.136958, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeL", h = 11, a = 11, b = 28, c0 = CFrame.new(0.084131, -0.048914, 0.225002, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Mouth", h = 11, a = 11, b = 35, c0 = CFrame.new(0.103697, -0.201524, 0.136958, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Head", h = 13, a = 13, b = 11, c0 = CFrame.new(0, 0, -0.273566, 0.585491, 0, 0.810679, 0.492827, 0.793999, -0.355931, -0.643679, 0.607919, 0.464879), c1 = CFrame.new(-0.136958, 0.154596, 0.112472, 0, 0, -1, 0.156434, 0.987688, 0, 0.987688, -0.156434, 0) },
		{ k = "Motor6D", n = "LeafL", h = 16, a = 16, b = 25, c0 = CFrame.new(0, 0, -0.20864, 0.046204, 0.142202, 0.988759, -0.85292, 0.520864, -0.035053, -0.519994, -0.841712, 0.145353), c1 = CFrame.new(0, -0.342395, 0.068479, 0, 0, -1, 0, 1, 0, 1, 0, 0) },
		{ k = "Weld", n = "Hold_RootToe1L", h = 17, a = 17, b = 23, c0 = CFrame.new(-0.07337, 0.069622, -0.435557, 0.930155, -0.05161, 0.363521, 0.18586, 0.920036, -0.344948, -0.31665, 0.388419, 0.865369), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootToe1R", h = 17, a = 17, b = 36, c0 = CFrame.new(0.07337, 0.069622, -0.435557, 0.930155, 0.05161, -0.363521, -0.18586, 0.920036, -0.344948, 0.31665, 0.388419, 0.865369), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_SeedTuft", h = 22, a = 22, b = 34, c0 = CFrame.new(0.00561, 0.016723, -0.169723, -0.553922, 0.148423, -0.819232, 0.817515, 0.283229, -0.501448, 0.157604, -0.947498, -0.278225), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootToe2R", h = 24, a = 24, b = 26, c0 = CFrame.new(0.07337, 0.069622, -0.435557, 0.930155, 0.05161, -0.363521, -0.18586, 0.920036, -0.344948, 0.31665, 0.388419, 0.865369), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootToe2L", h = 24, a = 24, b = 29, c0 = CFrame.new(-0.07337, 0.069622, -0.435557, 0.930155, -0.05161, 0.363521, 0.18586, 0.920036, -0.344948, -0.31665, 0.388419, 0.865369), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafArmHalfL", h = 25, a = 25, b = 30, c0 = CFrame.new(0, 0, 0.136958, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootToe3L", h = 31, a = 31, b = 32, c0 = CFrame.new(-0.07337, 0.069622, -0.435557, 0.930155, -0.05161, 0.363521, 0.18586, 0.920036, -0.344948, -0.31665, 0.388419, 0.865369), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootToe3R", h = 31, a = 31, b = 33, c0 = CFrame.new(0.07337, 0.069622, -0.435557, 0.930155, 0.05161, -0.363521, -0.18586, 0.920036, -0.344948, 0.31665, 0.388419, 0.865369), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
