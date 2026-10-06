--!strict
--==============================================================================
-- PLANT FORM: Emberquill (Emberroot)
--
-- Lifted part for part, joint for joint, from the owner's NEW supplied Workspace
-- model "Emberquill" (pasted 2026-10-03, replacing the earlier supplied rig) by a
-- read-only generator on 2026-10-03. The original was not moved or changed; a
-- verified .rbxm of it, its demo script and the data it replaced are in
-- output/model-backups/2026-10-03-emberquill-replacement.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the model's BASE:
-- its root part's x/z at the lowest drawn point, facing the way the root
-- faces), colour, material, surface, attribute and joint is the supplied
-- number, at the size it was supplied. The size a tier builds it at is
-- PlantForms' (the parent module; Emberquill is matched on its LONGEST side,
-- which for this rig is its height); see there. Joints point at parts by
-- INDEX, because names repeat (Quill, QuillTip, Eye, Pupil, Ear, Hold).
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "Workspace/Emberquill", Kind = "plant", Yaw = 0,
	Size = Vector3.new(2.119015, 7.979999, 4.995806), Height = 7.979999, PartCount = 49,
	Base = 1,
	Unit = 4, ModelScale = 1.334448,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(1.601338, 0.320268, 1.601338), cf = CFrame.new(0, 0.160134, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(178, 150, 114), m = Enum.Material.Plastic, t = 1, cs = false }, -- 1
		{ n = "Pelvis", s = "Block", z = Vector3.new(1.494582, 0.747291, 1.28107), cf = CFrame.new(0, 2.508763, 0.213512, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(140, 112, 84), m = Enum.Material.Plastic }, -- 2
		{ n = "Torso", s = "Block", z = Vector3.new(1.601338, 0.854047, 1.28107), cf = CFrame.new(0, 2.989164, 0.160134, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(178, 150, 114), m = Enum.Material.Plastic }, -- 3
		{ n = "Chest", s = "Block", z = Vector3.new(1.28107, 1.120937, 1.067559), cf = CFrame.new(0, 3.976656, 0.133445, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(208, 184, 148), m = Enum.Material.Plastic }, -- 4
		{ n = "Plate", s = "Block", z = Vector3.new(1.014181, 1.120937, 0.160134), cf = CFrame.new(0, 3.522943, -0.50709, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(238, 222, 188), m = Enum.Material.Plastic }, -- 5
		{ n = "Crack", s = "Block", z = Vector3.new(0.074729, 0.587157, 0.032027), cf = CFrame.new(0.106756, 3.549633, -0.592495, 0.961262, -0.275637, 0, 0.275637, 0.961262, 0, 0, 0, 1), c = Color3.fromRGB(255, 142, 46), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.556863, 0.180392), HotColor = Color3.new(1, 0.94902, 0.768627) } }, -- 6
		{ n = "Head", s = "Block", z = Vector3.new(1.067559, 0.800669, 1.067559), cf = CFrame.new(0, 5.017525, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(178, 150, 114), m = Enum.Material.Plastic }, -- 7
		{ n = "Snout", s = "Block", z = Vector3.new(0.533779, 0.427023, 0.747291), cf = CFrame.new(0, 4.910769, -0.854047, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(208, 184, 148), m = Enum.Material.Plastic }, -- 8
		{ n = "Nose", s = "Block", z = Vector3.new(0.240201, 0.186823, 0.160134), cf = CFrame.new(0, 4.990836, -1.28107, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 42, 38), m = Enum.Material.SmoothPlastic, st = false }, -- 9
		{ n = "Eye", s = "Block", z = Vector3.new(0.26689, 0.26689, 0.106756), cf = CFrame.new(-0.309592, 5.273739, -0.560468, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 206, 90), m = Enum.Material.Neon, st = false, cs = false }, -- 10
		{ n = "Pupil", s = "Block", z = Vector3.new(0.074729, 0.213512, 0.032027), cf = CFrame.new(-0.309592, 5.273739, -0.624522, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(44, 26, 18), m = Enum.Material.SmoothPlastic, st = false }, -- 11
		{ n = "Ear", s = "Block", z = Vector3.new(0.320268, 0.133445, 0.64224), cf = CFrame.new(-0.733946, 5.524616, 0.133445, -0.609711, 0.514598, 0.602861, 0, 0.760589, -0.649234, -0.792624, -0.395845, -0.463739), c = Color3.fromRGB(214, 120, 72), m = Enum.Material.Plastic }, -- 12
		{ n = "Eye", s = "Block", z = Vector3.new(0.26689, 0.26689, 0.106756), cf = CFrame.new(0.309592, 5.273739, -0.560468, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 206, 90), m = Enum.Material.Neon, st = false, cs = false }, -- 13
		{ n = "Pupil", s = "Block", z = Vector3.new(0.074729, 0.213512, 0.032027), cf = CFrame.new(0.309592, 5.273739, -0.624522, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(44, 26, 18), m = Enum.Material.SmoothPlastic, st = false }, -- 14
		{ n = "Ear", s = "Block", z = Vector3.new(0.320268, 0.133445, 0.64224), cf = CFrame.new(0.733946, 5.524616, 0.133445, -0.609711, -0.514598, -0.602861, 0, 0.760589, -0.649234, 0.792624, -0.395845, -0.463739), c = Color3.fromRGB(214, 120, 72), m = Enum.Material.Plastic }, -- 15
		{ n = "Quill", s = "Block", z = Vector3.new(0.213512, 0.213512, 1.26581), cf = CFrame.new(-0.342953, 5.636709, 0.69925, -0.97835, 0.106748, 0.177304, 0, 0.856713, -0.515794, -0.206959, -0.504627, -0.838165), c = Color3.fromRGB(246, 236, 212), m = Enum.Material.Plastic }, -- 16
		{ n = "QuillTip", s = "Block", z = Vector3.new(0.160134, 0.160134, 0.60992), cf = CFrame.new(-0.486807, 6.055191, 1.379286, -0.97835, 0.106748, 0.177304, 0, 0.856712, -0.515795, -0.206959, -0.504628, -0.838164), c = Color3.fromRGB(255, 196, 78), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.768627, 0.305882), HotColor = Color3.new(1, 0.94902, 0.768627) } }, -- 17
		{ n = "Quill", s = "Block", z = Vector3.new(0.213512, 0.213512, 1.26581), cf = CFrame.new(0.342953, 5.636709, 0.69925, -0.97835, -0.106748, -0.177304, 0, 0.856713, -0.515794, 0.206959, -0.504627, -0.838165), c = Color3.fromRGB(246, 236, 212), m = Enum.Material.Plastic }, -- 18
		{ n = "QuillTip", s = "Block", z = Vector3.new(0.160134, 0.160134, 0.60992), cf = CFrame.new(0.486807, 6.055191, 1.379286, -0.97835, -0.106748, -0.177304, 0, 0.856712, -0.515795, 0.206959, -0.504628, -0.838164), c = Color3.fromRGB(255, 196, 78), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.768627, 0.305882), HotColor = Color3.new(1, 0.94902, 0.768627) } }, -- 19
		{ n = "Wick", s = "Block", z = Vector3.new(0.240201, 0.240201, 2.068212), cf = CFrame.new(0, 6.298596, 0.320268, -1, 0, 0, 0, 0.164399, -0.986394, 0, -0.986394, -0.164399), c = Color3.fromRGB(246, 236, 212), m = Enum.Material.Plastic }, -- 20
		{ n = "WickBand", s = "Block", z = Vector3.new(0.298916, 0.298916, 0.402713), cf = CFrame.new(0, 6.999981, 0.437165, -1, 0, 0, 0, 0.164398, -0.986394, 0, -0.986394, -0.164398), c = Color3.fromRGB(184, 74, 30), m = Enum.Material.Plastic }, -- 21
		{ n = "WickCup", s = "Block", z = Vector3.new(0.346957, 0.160134, 0.346957), cf = CFrame.new(0, 7.232709, 0.480401, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(52, 42, 38), m = Enum.Material.Plastic }, -- 22
		{ n = "Flame", s = "Block", z = Vector3.new(0.373646, 0.373646, 0.373646), cf = CFrame.new(0, 7.552976, 0.501753, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 196, 78), m = Enum.Material.Neon, st = false, cs = false, a = { BaseSize = Vector3.new(0.28, 0.28, 0.28) } }, -- 23
		{ n = "FlameCore", s = "Block", z = Vector3.new(0.240201, 0.587157, 0.240201), cf = CFrame.new(0, 7.686421, 0.50709, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 242, 196), m = Enum.Material.Neon, st = false, cs = false, a = { BaseSize = Vector3.new(0.18, 0.44, 0.18) } }, -- 24
		{ n = "Quill", s = "Block", z = Vector3.new(0.293579, 0.293579, 1.467826), cf = CFrame.new(0, 4.587834, 1.059552, -1, 0, 0, 0, 0.876812, -0.480833, 0, -0.480832, -0.876812), c = Color3.fromRGB(246, 236, 212), m = Enum.Material.Plastic, a = { Side = 0 } }, -- 25
		{ n = "QuillTip", s = "Block", z = Vector3.new(0.220184, 0.220184, 0.713994), cf = CFrame.new(0, 5.032472, 1.870363, -1, 0, 0, 0, 0.876812, -0.480833, 0, -0.480832, -0.876812), c = Color3.fromRGB(255, 196, 78), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.768627, 0.305882), HotColor = Color3.new(1, 0.94902, 0.768627) } }, -- 26
		{ n = "Quill", s = "Block", z = Vector3.new(0.26689, 0.26689, 1.466579), cf = CFrame.new(-0.451043, 4.179492, 1.094248, -0.973841, 0.114637, 0.196193, 0, 0.863414, -0.504496, -0.22723, -0.491299, -0.840828), c = Color3.fromRGB(246, 236, 212), m = Enum.Material.Plastic, a = { Side = -1 } }, -- 27
		{ n = "QuillTip", s = "Block", z = Vector3.new(0.200167, 0.200167, 0.709516), cf = CFrame.new(-0.63413, 4.650285, 1.878903, -0.973841, 0.114637, 0.196193, 0, 0.863414, -0.504497, -0.227229, -0.4913, -0.840828), c = Color3.fromRGB(255, 142, 46), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.556863, 0.180392), HotColor = Color3.new(1, 0.94902, 0.768627) } }, -- 28
		{ n = "Quill", s = "Block", z = Vector3.new(0.26689, 0.26689, 1.466579), cf = CFrame.new(0.451043, 4.179492, 1.094248, -0.973841, -0.114637, -0.196193, 0, 0.863414, -0.504496, 0.22723, -0.491299, -0.840828), c = Color3.fromRGB(246, 236, 212), m = Enum.Material.Plastic, a = { Side = 1 } }, -- 29
		{ n = "QuillTip", s = "Block", z = Vector3.new(0.200167, 0.200167, 0.709516), cf = CFrame.new(0.63413, 4.650285, 1.878903, -0.973841, -0.114637, -0.196193, 0, 0.863414, -0.504497, 0.227229, -0.4913, -0.840828), c = Color3.fromRGB(255, 142, 46), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.556863, 0.180392), HotColor = Color3.new(1, 0.94902, 0.768627) } }, -- 30
		{ n = "Quill", s = "Block", z = Vector3.new(0.256214, 0.256214, 1.402342), cf = CFrame.new(-0.595164, 3.408181, 1.219686, -0.960346, 0.089931, 0.263908, 0, 0.946551, -0.322554, -0.27881, -0.309764, -0.909017), c = Color3.fromRGB(246, 236, 212), m = Enum.Material.Plastic, a = { Side = -1 } }, -- 31
		{ n = "QuillTip", s = "Block", z = Vector3.new(0.192161, 0.192161, 0.678588), cf = CFrame.new(-0.830561, 3.695888, 2.030496, -0.960346, 0.089931, 0.263908, 0, 0.946551, -0.322554, -0.27881, -0.309764, -0.909017), c = Color3.fromRGB(255, 196, 78), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.768627, 0.305882), HotColor = Color3.new(1, 0.94902, 0.768627) } }, -- 32
		{ n = "Quill", s = "Block", z = Vector3.new(0.256214, 0.256214, 1.402342), cf = CFrame.new(0.595164, 3.408181, 1.219686, -0.960346, -0.089931, -0.263908, 0, 0.946551, -0.322554, 0.27881, -0.309764, -0.909017), c = Color3.fromRGB(246, 236, 212), m = Enum.Material.Plastic, a = { Side = 1 } }, -- 33
		{ n = "QuillTip", s = "Block", z = Vector3.new(0.192161, 0.192161, 0.678588), cf = CFrame.new(0.830561, 3.695888, 2.030496, -0.960346, -0.089931, -0.263908, 0, 0.946551, -0.322554, 0.27881, -0.309764, -0.909017), c = Color3.fromRGB(255, 196, 78), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.768627, 0.305882), HotColor = Color3.new(1, 0.94902, 0.768627) } }, -- 34
		{ n = "UpperArm", s = "Block", z = Vector3.new(0.320268, 0.320268, 0.903602), cf = CFrame.new(-0.720602, 3.763144, -0.320268, 0.936329, -0.277301, 0.215387, 0, 0.613424, 0.789754, -0.351123, -0.73947, 0.574367), c = Color3.fromRGB(104, 80, 60), m = Enum.Material.Plastic }, -- 35
		{ n = "Forearm", s = "Block", z = Vector3.new(0.293579, 0.26689, 0.770635), cf = CFrame.new(-0.65388, 3.562977, -0.800669, 0.876216, -0.141297, -0.460739, 0, 0.956052, -0.293197, 0.481919, 0.256904, 0.837708), c = Color3.fromRGB(238, 222, 188), m = Enum.Material.Plastic }, -- 36
		{ n = "UpperArm", s = "Block", z = Vector3.new(0.320268, 0.320268, 0.903602), cf = CFrame.new(0.720602, 3.763144, -0.320268, 0.936329, 0.277301, -0.215387, 0, 0.613424, 0.789754, 0.351123, -0.73947, 0.574367), c = Color3.fromRGB(104, 80, 60), m = Enum.Material.Plastic }, -- 37
		{ n = "Forearm", s = "Block", z = Vector3.new(0.293579, 0.26689, 0.770635), cf = CFrame.new(0.65388, 3.562977, -0.800669, 0.876216, 0.141297, 0.460739, 0, 0.956052, -0.293197, -0.481919, 0.256904, 0.837708), c = Color3.fromRGB(238, 222, 188), m = Enum.Material.Plastic }, -- 38
		{ n = "Thigh", s = "Block", z = Vector3.new(0.587157, 0.693913, 1.355503), cf = CFrame.new(-0.667224, 1.921605, 0, 0.995037, -0.084261, 0.052926, 0, 0.531896, 0.84681, -0.099504, -0.842607, 0.529256), c = Color3.fromRGB(178, 150, 114), m = Enum.Material.Plastic }, -- 39
		{ n = "Shin", s = "Block", z = Vector3.new(0.320268, 0.320268, 1.497781), cf = CFrame.new(-0.693913, 0.907425, 0.053378, -1, 0, 0, 0, 0.478852, 0.877896, 0, 0.877895, -0.478852), c = Color3.fromRGB(104, 80, 60), m = Enum.Material.Plastic }, -- 40
		{ n = "Foot", s = "Block", z = Vector3.new(0.480401, 0.240201, 0.960803), cf = CFrame.new(-0.693913, 0.1201, -0.133445, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(140, 112, 84), m = Enum.Material.Plastic }, -- 41
		{ n = "Toe", s = "Block", z = Vector3.new(0.533779, 0.160134, 0.213512), cf = CFrame.new(-0.693913, 0.080067, -0.720602, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 42, 38), m = Enum.Material.Plastic }, -- 42
		{ n = "Thigh", s = "Block", z = Vector3.new(0.587157, 0.693913, 1.355503), cf = CFrame.new(0.667224, 1.921605, 0, 0.995037, 0.084261, -0.052926, 0, 0.531896, 0.84681, 0.099504, -0.842607, 0.529256), c = Color3.fromRGB(178, 150, 114), m = Enum.Material.Plastic }, -- 43
		{ n = "Shin", s = "Block", z = Vector3.new(0.320268, 0.320268, 1.497781), cf = CFrame.new(0.693913, 0.907425, 0.053378, -1, 0, 0, 0, 0.478852, 0.877896, 0, 0.877895, -0.478852), c = Color3.fromRGB(104, 80, 60), m = Enum.Material.Plastic }, -- 44
		{ n = "Foot", s = "Block", z = Vector3.new(0.480401, 0.240201, 0.960803), cf = CFrame.new(0.693913, 0.1201, -0.133445, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(140, 112, 84), m = Enum.Material.Plastic }, -- 45
		{ n = "Toe", s = "Block", z = Vector3.new(0.533779, 0.160134, 0.213512), cf = CFrame.new(0.693913, 0.080067, -0.720602, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 42, 38), m = Enum.Material.Plastic }, -- 46
		{ n = "Tail", s = "Block", z = Vector3.new(0.533779, 0.533779, 1.319667), cf = CFrame.new(0, 2.241873, 1.307759, -1, 0, 0, 0, 0.861934, 0.50702, 0, 0.50702, -0.861934), c = Color3.fromRGB(178, 150, 114), m = Enum.Material.Plastic }, -- 47
		{ n = "Tail", s = "Block", z = Vector3.new(0.400334, 0.373646, 1.213567), cf = CFrame.new(0, 1.894916, 2.268562, -1, 0, 0, 0, 0.987763, 0.155963, 0, 0.155963, -0.987763), c = Color3.fromRGB(140, 112, 84), m = Enum.Material.Plastic }, -- 48
		{ n = "TailTip", s = "Block", z = Vector3.new(0.240201, 0.240201, 0.980794), cf = CFrame.new(0, 2.028361, 3.149298, -1, 0, 0, 0, 0.868243, -0.496139, 0, -0.496139, -0.868243), c = Color3.fromRGB(255, 196, 78), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.768627, 0.305882), HotColor = Color3.new(1, 0.94902, 0.768627) } }, -- 49
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 2.241873, 0.213512, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.106756, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Waist", h = 2, a = 2, b = 3, c0 = CFrame.new(0, 0.26689, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.213512, 0.053378, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 2, a = 2, b = 39, c0 = CFrame.new(-0.640535, -0.160134, 0.053378, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.504273, 0.995037, 0, -0.099504, -0.084261, 0.531896, -0.842607, 0.052926, 0.84681, 0.529256) },
		{ k = "Motor6D", n = "HipL", h = 2, a = 2, b = 43, c0 = CFrame.new(0.640535, -0.160134, 0.053378, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.504273, 0.995037, 0, 0.099504, 0.084261, 0.531896, -0.842607, -0.052926, 0.84681, 0.529256) },
		{ k = "Motor6D", n = "Tail1", h = 2, a = 2, b = 47, c0 = CFrame.new(0, 0, 0.640535, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.526389, -1, 0, 0, 0, 0.861934, 0.50702, 0, 0.50702, -0.861934) },
		{ k = "Weld", n = "Hold", h = 3, a = 3, b = 4, c0 = CFrame.new(0, 0.987492, -0.026689, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 3, a = 3, b = 5, c0 = CFrame.new(0, 0.533779, -0.667224, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 3, a = 3, b = 7, c0 = CFrame.new(0, 1.601338, -0.053378, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.427023, 0.106756, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Back1", h = 3, a = 3, b = 25, c0 = CFrame.new(0, 1.28107, 0.320268, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.000001, 0.660518, -1, 0, 0, 0, 0.876812, -0.480832, 0, -0.480833, -0.876812) },
		{ k = "Motor6D", n = "Back2", h = 3, a = 3, b = 27, c0 = CFrame.new(-0.320268, 0.854047, 0.373646, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.666567, -0.973841, 0, -0.22723, 0.114637, 0.863414, -0.491299, 0.196193, -0.504496, -0.840828) },
		{ k = "Motor6D", n = "Back3", h = 3, a = 3, b = 29, c0 = CFrame.new(0.320268, 0.854047, 0.373646, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.666567, -0.973841, 0, 0.22723, -0.114637, 0.863414, -0.491299, -0.196193, -0.504496, -0.840828) },
		{ k = "Motor6D", n = "Back4", h = 3, a = 3, b = 31, c0 = CFrame.new(-0.427023, 0.213512, 0.480401, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.637118, -0.960346, 0, -0.27881, 0.089931, 0.946551, -0.309764, 0.263908, -0.322554, -0.909017) },
		{ k = "Motor6D", n = "Back5", h = 3, a = 3, b = 33, c0 = CFrame.new(0.427023, 0.213512, 0.480401, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.637118, -0.960346, 0, 0.27881, -0.089931, 0.946551, -0.309764, -0.263908, -0.322554, -0.909017) },
		{ k = "Motor6D", n = "ShoulderR", h = 3, a = 3, b = 35, c0 = CFrame.new(-0.640535, 1.067559, -0.26689, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.371734, 0.936329, 0, -0.351123, -0.277301, 0.613424, -0.73947, 0.215387, 0.789754, 0.574367) },
		{ k = "Motor6D", n = "ShoulderL", h = 3, a = 3, b = 37, c0 = CFrame.new(0.640535, 1.067559, -0.26689, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.371734, 0.936329, 0, 0.351123, 0.277301, 0.613424, -0.73947, -0.215387, 0.789754, 0.574367) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 6, c0 = CFrame.new(0.106756, 0.026689, -0.085405, 0.961262, -0.275637, 0, 0.275637, 0.961262, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 7, a = 7, b = 8, c0 = CFrame.new(0, -0.106756, -0.854047, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 7, a = 7, b = 9, c0 = CFrame.new(0, -0.026689, -1.28107, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 7, a = 7, b = 10, c0 = CFrame.new(-0.309592, 0.256214, -0.560468, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 7, a = 7, b = 11, c0 = CFrame.new(-0.309592, 0.256214, -0.624522, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "EarR", h = 7, a = 7, b = 12, c0 = CFrame.new(-0.560468, 0.320268, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.000001, 0.287759, -0.609711, 0, -0.792624, 0.514598, 0.760589, -0.395845, 0.602861, -0.649234, -0.463739) },
		{ k = "Weld", n = "Hold", h = 7, a = 7, b = 13, c0 = CFrame.new(0.309592, 0.256214, -0.560468, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 7, a = 7, b = 14, c0 = CFrame.new(0.309592, 0.256214, -0.624522, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "EarL", h = 7, a = 7, b = 15, c0 = CFrame.new(0.560468, 0.320268, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.000001, 0.287759, -0.609711, 0, 0.792624, -0.514598, 0.760589, -0.395845, -0.602861, -0.649234, -0.463739) },
		{ k = "Motor6D", n = "Crest1", h = 7, a = 7, b = 16, c0 = CFrame.new(-0.240201, 0.320268, 0.213512, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.579527, -0.97835, 0, -0.206959, 0.106748, 0.856713, -0.504627, 0.177304, -0.515794, -0.838165) },
		{ k = "Motor6D", n = "Crest2", h = 7, a = 7, b = 18, c0 = CFrame.new(0.240201, 0.320268, 0.213512, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.579527, -0.97835, 0, 0.206959, -0.106748, 0.856713, -0.504627, -0.177304, -0.515794, -0.838165) },
		{ k = "Motor6D", n = "Wick", h = 7, a = 7, b = 20, c0 = CFrame.new(0, 0.320268, 0.160134, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.974056, -1, 0, 0, 0, 0.164399, -0.986394, 0, -0.986394, -0.164399) },
		{ k = "Weld", n = "Hold", h = 16, a = 16, b = 17, c0 = CFrame.new(0, -0.000001, -0.811338, 1, 0, 0, 0, 1, -0.000001, 0, 0.000001, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 19, c0 = CFrame.new(0, -0.000001, -0.811338, 1, 0, 0, 0, 1, -0.000001, 0, 0.000001, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 20, a = 20, b = 21, c0 = CFrame.new(0, 0, -0.71106, 1, 0, 0, 0, 1, -0.000001, 0, 0.000001, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 20, a = 20, b = 22, c0 = CFrame.new(0, -0.004388, -0.947729, -0.707107, 0, -0.707107, 0.697486, 0.164399, -0.697486, 0.116248, -0.986394, -0.116248), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "WickFlame", h = 20, a = 20, b = 23, c0 = CFrame.new(0, 0, -0.974055, -1, 0, 0, 0, 0.164399, -0.986394, 0, -0.986394, -0.164399), c1 = CFrame.new(0.015098, -0.293578, -0.015098, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107) },
		{ k = "Weld", n = "Hold", h = 23, a = 23, b = 24, c0 = CFrame.new(-0.003774, 0.133445, 0.003774, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 25, a = 25, b = 26, c0 = CFrame.new(0, 0, -0.924726, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 27, a = 27, b = 28, c0 = CFrame.new(0, 0, -0.933194, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 29, a = 29, b = 30, c0 = CFrame.new(0, 0, -0.933194, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 31, a = 31, b = 32, c0 = CFrame.new(0, 0, -0.891965, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 33, a = 33, b = 34, c0 = CFrame.new(0, 0, -0.891965, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ElbowR", h = 35, a = 35, b = 36, c0 = CFrame.new(0, 0, -0.371734, 0.936329, 0, -0.351123, -0.277301, 0.613424, -0.73947, 0.215387, 0.789754, 0.574367), c1 = CFrame.new(0, 0, 0.318595, 0.876216, 0, 0.481919, -0.141297, 0.956052, 0.256904, -0.460739, -0.293197, 0.837708) },
		{ k = "Motor6D", n = "ElbowL", h = 37, a = 37, b = 38, c0 = CFrame.new(0, 0, -0.371734, 0.936329, 0, 0.351123, 0.277301, 0.613424, -0.73947, -0.215387, 0.789754, 0.574367), c1 = CFrame.new(0, 0, 0.318595, 0.876216, 0, -0.481919, 0.141297, 0.956052, 0.256904, 0.460739, -0.293197, 0.837708) },
		{ k = "Motor6D", n = "KneeR", h = 39, a = 39, b = 40, c0 = CFrame.new(0, 0, -0.504273, 0.995037, 0, -0.099504, -0.084261, 0.531896, -0.842607, 0.052926, 0.84681, 0.529256), c1 = CFrame.new(0, 0, 0.668823, -1, 0, 0, 0, 0.478852, 0.877896, 0, 0.877896, -0.478852) },
		{ k = "Motor6D", n = "AnkleR", h = 40, a = 40, b = 41, c0 = CFrame.new(0, 0, -0.668824, -1, 0, 0, 0, 0.478852, 0.877896, 0, 0.877896, -0.478852), c1 = CFrame.new(0, 0.200167, 0.50709, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 41, a = 41, b = 42, c0 = CFrame.new(0, -0.040033, -0.587157, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeL", h = 43, a = 43, b = 44, c0 = CFrame.new(0, 0, -0.504273, 0.995037, 0, 0.099504, 0.084261, 0.531896, -0.842607, -0.052926, 0.84681, 0.529256), c1 = CFrame.new(0, 0, 0.668823, -1, 0, 0, 0, 0.478852, 0.877896, 0, 0.877896, -0.478852) },
		{ k = "Motor6D", n = "AnkleL", h = 44, a = 44, b = 45, c0 = CFrame.new(0, 0, -0.668824, -1, 0, 0, 0, 0.478852, 0.877896, 0, 0.877896, -0.478852), c1 = CFrame.new(0, 0.200167, 0.50709, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 45, a = 45, b = 46, c0 = CFrame.new(0, -0.040033, -0.587157, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail2", h = 47, a = 47, b = 48, c0 = CFrame.new(0, 0, -0.526389, -1, 0, 0, 0, 0.861934, 0.50702, 0, 0.50702, -0.861934), c1 = CFrame.new(0, 0, 0.513373, -1, 0, 0, 0, 0.987763, 0.155963, 0, 0.155963, -0.987763) },
		{ k = "Weld", n = "Hold", h = 48, a = 48, b = 49, c0 = CFrame.new(0, 0.269174, -0.849146, 1, 0, 0, 0, 0.780239, -0.625481, 0, 0.625481, 0.780239), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "WickLight", p = 24, range = 10.666667, brightness = 1.2, color = Color3.new(1, 0.768627, 0.305882), shadows = false, enabled = true, a = { BaseBrightness = 1.2 } },
	},
	Emitters = {
		{ n = "Embers", p = 23, rate = 3, enabled = true, lifetime = NumberRange.new(0.8, 1.6), speed = NumberRange.new(1.779264, 4.448161), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.177926, 0), NumberSequenceKeypoint.new(1, 0, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 0.94902, 0.768627)), ColorSequenceKeypoint.new(1, Color3.new(1, 0.556863, 0.180392)) }), lightEmission = 1, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(25, 25), acceleration = Vector3.new(0, 2.668896, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 1, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
