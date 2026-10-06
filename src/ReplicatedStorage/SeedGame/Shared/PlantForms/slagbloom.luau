--!strict
--==============================================================================
-- PLANT FORM: Slagbloom (Emberroot)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Emberroot/Slagbloom" by a read-only generator on 2026-10-03. The original
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
	Source = "Emberroot/Slagbloom", Kind = "plant", Yaw = 0,
	Size = Vector3.new(6.784226, 8.587091, 3.249409), Height = 8.587091, PartCount = 49,
	Base = 2,
	Unit = 4.5, ModelScale = 1.131803,
	Attributes = {},
	Parts = {
		{ n = "RootFoot3", s = "Wedge", z = Vector3.new(1.273279, 0.713036, 1.527934), cf = CFrame.new(-0.91676, 0.356518, 1.120485, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(73, 61, 51), m = Enum.Material.Plastic }, -- 1
		{ n = "Footing", s = "Block", z = Vector3.new(1.426072, 0.203725, 1.426072), cf = CFrame.new(0, 0.101862, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.Plastic, t = 1, cs = false }, -- 2
		{ n = "StonePetal6", s = "Block", z = Vector3.new(1.477003, 2.139108, 1.018623), cf = CFrame.new(-1.296495, 3.898481, -0.814899, -0.707107, -0.707107, 0, 0.707107, -0.707107, 0, 0, 0, 1), c = Color3.fromRGB(113, 103, 90), m = Enum.Material.Plastic }, -- 3
		{ n = "HeavyStem", s = "Block", z = Vector3.new(1.477003, 1.833521, 1.477003), cf = CFrame.new(0, 1.477003, 0.356518, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(73, 61, 51), m = Enum.Material.Plastic }, -- 4
		{ n = "UpperStem", s = "Block", z = Vector3.new(1.273279, 1.629797, 1.273279), cf = CFrame.new(0, 3.1068, 0.305586, 0.996195, -0.087156, 0, 0.086678, 0.990737, 0.104528, -0.00911, -0.104131, 0.994522), c = Color3.fromRGB(73, 61, 51), m = Enum.Material.Plastic }, -- 5
		{ n = "HeadBack", s = "Block", z = Vector3.new(2.801213, 2.801213, 0.814898), cf = CFrame.new(0, 5.194977, 0.152792, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.Plastic }, -- 6
		{ n = "PetalChip6", s = "Wedge", z = Vector3.new(1.222347, 0.713036, 0.865829), cf = CFrame.new(-2.178832, 3.196213, -0.814899, -0.798635, -0.601815, 0, 0.601815, -0.798636, 0, 0, 0, 1), c = Color3.fromRGB(133, 120, 100), m = Enum.Material.Plastic }, -- 7
		{ n = "PetalChip5", s = "Wedge", z = Vector3.new(1.222347, 0.713036, 0.865829), cf = CFrame.new(-0.127328, 2.24097, -0.814899, -0.990268, 0.139173, 0, -0.139173, -0.990268, 0, 0, 0, 1), c = Color3.fromRGB(133, 120, 100), m = Enum.Material.Plastic }, -- 8
		{ n = "StonePetal5", s = "Block", z = Vector3.new(1.477003, 2.139108, 1.018623), cf = CFrame.new(0, 3.361455, -0.814899, -1, 0, 0, 0, -1, 0, 0, 0, 1), c = Color3.fromRGB(91, 88, 83), m = Enum.Material.Plastic }, -- 9
		{ n = "StonePetal7", s = "Block", z = Vector3.new(1.477003, 2.139108, 1.018623), cf = CFrame.new(-1.833521, 5.194977, -0.814899, 0, -1, 0, 1, 0, 0, 0, 0, 1), c = Color3.fromRGB(91, 88, 83), m = Enum.Material.Plastic }, -- 10
		{ n = "PetalChip2", s = "Wedge", z = Vector3.new(1.222347, 0.713036, 0.865829), cf = CFrame.new(2.178833, 7.193741, -0.814899, 0.798635, 0.601815, 0, -0.601815, 0.798635, 0, 0, 0, 1), c = Color3.fromRGB(133, 120, 100), m = Enum.Material.Plastic }, -- 11
		{ n = "StonePetal2", s = "Block", z = Vector3.new(1.477003, 2.139108, 1.018623), cf = CFrame.new(1.296495, 6.491472, -0.814899, 0.707107, 0.707107, 0, -0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(113, 103, 90), m = Enum.Material.Plastic }, -- 12
		{ n = "RootFoot2", s = "Wedge", z = Vector3.new(1.273279, 0.713036, 1.527934), cf = CFrame.new(0.916761, 0.356518, -0.509312, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(73, 61, 51), m = Enum.Material.Plastic }, -- 13
		{ n = "StonePetal8", s = "Block", z = Vector3.new(1.477003, 2.139108, 1.018623), cf = CFrame.new(-1.296495, 6.491473, -0.814899, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(113, 103, 90), m = Enum.Material.Plastic }, -- 14
		{ n = "Crack8A", s = "Block", z = Vector3.new(0.091676, 0.814898, 0.061117), cf = CFrame.new(-1.289292, 6.246579, -1.334396, 0.965926, -0.258819, 0, 0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 15
		{ n = "RootFoot4", s = "Wedge", z = Vector3.new(1.273279, 0.713036, 1.527934), cf = CFrame.new(0.916761, 0.356518, 1.120485, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(73, 61, 51), m = Enum.Material.Plastic }, -- 16
		{ n = "Crack6B", s = "Block", z = Vector3.new(0.086583, 0.662105, 0.061117), cf = CFrame.new(-1.501774, 3.491526, -1.334396, -0.984808, -0.173648, 0, 0.173648, -0.984808, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 17
		{ n = "Crack7A", s = "Block", z = Vector3.new(0.091676, 0.814898, 0.061117), cf = CFrame.new(-1.655262, 5.026904, -1.334396, 0.5, -0.866025, 0, 0.866026, 0.5, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 18
		{ n = "PetalChip1", s = "Wedge", z = Vector3.new(1.222347, 0.713036, 0.865829), cf = CFrame.new(0.127328, 8.148984, -0.814899, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c = Color3.fromRGB(133, 120, 100), m = Enum.Material.Plastic }, -- 19
		{ n = "StonePetal1", s = "Block", z = Vector3.new(1.477003, 2.139108, 1.018623), cf = CFrame.new(0, 7.028499, -0.814899, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(91, 88, 83), m = Enum.Material.Plastic }, -- 20
		{ n = "LeafArm1", s = "Wedge", z = Vector3.new(0.662105, 1.527934, 0.611174), cf = CFrame.new(-1.262176, 2.877306, 0.203724, 0.422618, -0.906308, 0, 0.906308, 0.422618, 0, 0, 0, 1), c = Color3.fromRGB(62, 49, 39), m = Enum.Material.Plastic }, -- 21
		{ n = "StonePetal4", s = "Block", z = Vector3.new(1.477003, 2.139108, 1.018623), cf = CFrame.new(1.296495, 3.898482, -0.814899, -0.707107, 0.707107, 0, -0.707107, -0.707107, 0, 0, 0, 1), c = Color3.fromRGB(113, 103, 90), m = Enum.Material.Plastic }, -- 22
		{ n = "Crack4B", s = "Block", z = Vector3.new(0.086583, 0.662105, 0.061117), cf = CFrame.new(1.703451, 3.693203, -1.334396, -0.173648, 0.984808, 0, -0.984808, -0.173648, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 23
		{ n = "MoltenCentre", s = "Block", z = Vector3.new(1.78259, 1.78259, 0.178259), cf = CFrame.new(0, 5.194977, -0.376892, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 116, 23), m = Enum.Material.Neon, st = false, cs = false }, -- 24
		{ n = "EyeL", s = "Block", z = Vector3.new(0.341239, 0.122235, 0.061117), cf = CFrame.new(0.443102, 5.373236, -0.504219, 0.951057, -0.309017, 0, 0.309017, 0.951057, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false, a = { Blink = true } }, -- 25
		{ n = "PetalChip8", s = "Wedge", z = Vector3.new(1.222347, 0.713036, 0.865829), cf = CFrame.new(-1.998764, 7.37381, -0.814899, 0.601815, -0.798636, 0, 0.798636, 0.601815, 0, 0, 0, 1), c = Color3.fromRGB(133, 120, 100), m = Enum.Material.Plastic }, -- 26
		{ n = "Mouth", s = "Block", z = Vector3.new(0.37689, 0.076397, 0.061117), cf = CFrame.new(0, 4.838459, -0.504219, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 27
		{ n = "Crack5A", s = "Block", z = Vector3.new(0.091676, 0.814898, 0.061117), cf = CFrame.new(0.168073, 3.539714, -1.334396, -0.866025, -0.5, 0, 0.5, -0.866025, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 28
		{ n = "PetalChip3", s = "Wedge", z = Vector3.new(1.222347, 0.713036, 0.865829), cf = CFrame.new(2.954006, 5.067649, -0.814899, 0.139173, 0.990268, 0, -0.990268, 0.139173, 0, 0, 0, 1), c = Color3.fromRGB(133, 120, 100), m = Enum.Material.Plastic }, -- 29
		{ n = "StonePetal3", s = "Block", z = Vector3.new(1.477003, 2.139108, 1.018623), cf = CFrame.new(1.833521, 5.194977, -0.814899, 0, 1, 0, -1, 0, 0, 0, 0, 1), c = Color3.fromRGB(91, 88, 83), m = Enum.Material.Plastic }, -- 30
		{ n = "LeafArm2", s = "Wedge", z = Vector3.new(0.662105, 1.527934, 0.611174), cf = CFrame.new(1.262177, 2.877306, 0.203724, 0.422618, 0.906308, 0, -0.906308, 0.422618, 0, 0, 0, 1), c = Color3.fromRGB(62, 49, 39), m = Enum.Material.Plastic }, -- 31
		{ n = "PetalChip4", s = "Wedge", z = Vector3.new(1.222347, 0.713036, 0.865829), cf = CFrame.new(1.998764, 3.016145, -0.814899, -0.601815, 0.798635, 0, -0.798635, -0.601815, 0, 0, 0, 1), c = Color3.fromRGB(133, 120, 100), m = Enum.Material.Plastic }, -- 32
		{ n = "Crack2A", s = "Block", z = Vector3.new(0.091676, 0.814898, 0.061117), cf = CFrame.new(1.051601, 6.48427, -1.334396, 0.258819, 0.965926, 0, -0.965926, 0.258819, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 33
		{ n = "Crack2B", s = "Block", z = Vector3.new(0.086583, 0.662105, 0.061117), cf = CFrame.new(1.501774, 6.898428, -1.334396, 0.984808, 0.173648, 0, -0.173648, 0.984808, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 34
		{ n = "Crack7B", s = "Block", z = Vector3.new(0.086583, 0.662105, 0.061117), cf = CFrame.new(-2.266436, 5.05237, -1.334396, -0.573576, -0.819152, 0, 0.819152, -0.573577, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 35
		{ n = "RootFoot1", s = "Wedge", z = Vector3.new(1.273279, 0.713036, 1.527934), cf = CFrame.new(-0.91676, 0.356518, -0.509312, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(73, 61, 51), m = Enum.Material.Plastic }, -- 36
		{ n = "ArmChip1", s = "Wedge", z = Vector3.new(0.509311, 0.509311, 0.509311), cf = CFrame.new(-2.046884, 3.243221, 0.203724, 0.422618, -0.906308, 0, 0.906308, 0.422618, 0, 0, 0, 1), c = Color3.fromRGB(113, 103, 90), m = Enum.Material.Plastic }, -- 37
		{ n = "ArmChip2", s = "Wedge", z = Vector3.new(0.509311, 0.509311, 0.509311), cf = CFrame.new(2.046885, 3.243221, 0.203724, 0.422618, 0.906308, 0, -0.906308, 0.422618, 0, 0, 0, 1), c = Color3.fromRGB(113, 103, 90), m = Enum.Material.Plastic }, -- 38
		{ n = "Crack5B", s = "Block", z = Vector3.new(0.086583, 0.662105, 0.061117), cf = CFrame.new(0.142607, 2.928541, -1.334396, -0.819152, 0.573576, 0, -0.573576, -0.819152, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 39
		{ n = "PetalChip7", s = "Wedge", z = Vector3.new(1.222347, 0.713036, 0.865829), cf = CFrame.new(-2.954006, 5.322305, -0.814899, -0.139173, -0.990268, 0, 0.990268, -0.139173, 0, 0, 0, 1), c = Color3.fromRGB(133, 120, 100), m = Enum.Material.Plastic }, -- 40
		{ n = "Crack6A", s = "Block", z = Vector3.new(0.091676, 0.814898, 0.061117), cf = CFrame.new(-1.051601, 3.905684, -1.334396, -0.258819, -0.965926, 0, 0.965926, -0.258819, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 41
		{ n = "EyeR", s = "Block", z = Vector3.new(0.341239, 0.122235, 0.061117), cf = CFrame.new(-0.443101, 5.373236, -0.504219, 0.951057, 0.309017, 0, -0.309017, 0.951057, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false, a = { Blink = true } }, -- 42
		{ n = "Crack3B", s = "Block", z = Vector3.new(0.086583, 0.662105, 0.061117), cf = CFrame.new(2.266436, 5.337584, -1.334396, 0.573576, 0.819152, 0, -0.819152, 0.573576, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 43
		{ n = "StoneCollar", s = "Block", z = Vector3.new(1.833521, 0.611174, 1.731659), cf = CFrame.new(0, 3.667043, 0.203724, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(113, 103, 90), m = Enum.Material.Plastic }, -- 44
		{ n = "Crack1A", s = "Block", z = Vector3.new(0.091676, 0.814898, 0.061117), cf = CFrame.new(-0.168073, 6.85024, -1.334396, 0.866025, 0.5, 0, -0.5, 0.866026, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 45
		{ n = "Crack4A", s = "Block", z = Vector3.new(0.091676, 0.814898, 0.061117), cf = CFrame.new(1.289293, 4.143375, -1.334396, -0.965926, 0.258819, 0, -0.258819, -0.965926, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 46
		{ n = "Crack8B", s = "Block", z = Vector3.new(0.086583, 0.662105, 0.061117), cf = CFrame.new(-1.703451, 6.696751, -1.334396, 0.173648, -0.984808, 0, 0.984808, 0.173648, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 47
		{ n = "Crack1B", s = "Block", z = Vector3.new(0.086583, 0.662105, 0.061117), cf = CFrame.new(-0.142607, 7.461414, -1.334396, 0.819152, -0.573576, 0, 0.573577, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 48
		{ n = "Crack3A", s = "Block", z = Vector3.new(0.091676, 0.814898, 0.061117), cf = CFrame.new(1.655262, 5.36305, -1.334396, -0.5, 0.866025, 0, -0.866026, -0.5, 0, 0, 0, 1), c = Color3.fromRGB(30, 27, 25), m = Enum.Material.SmoothPlastic, st = false }, -- 49
	},
	Joints = {
		{ k = "Motor6D", n = "Foot3", h = 2, a = 2, b = 1, c0 = CFrame.new(-0.916761, 0.509311, 1.120485, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.254656, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 0.509311, 0.356518, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.865829, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Foot2", h = 2, a = 2, b = 13, c0 = CFrame.new(0.916761, 0.509311, -0.509311, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.254656, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Foot4", h = 2, a = 2, b = 16, c0 = CFrame.new(0.916761, 0.509311, 1.120485, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.254656, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Foot1", h = 2, a = 2, b = 36, c0 = CFrame.new(-0.916761, 0.509311, -0.509311, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.254656, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalChip6", h = 3, a = 3, b = 7, c0 = CFrame.new(0.127328, 1.120485, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack6B", h = 3, a = 3, b = 17, c0 = CFrame.new(-0.142607, 0.432915, -0.519498, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack6A", h = 3, a = 3, b = 41, c0 = CFrame.new(-0.168073, -0.178259, -0.519498, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Stem", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 0.865829, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.066683, -0.762195, -0.029204, 0.996195, 0.086678, -0.00911, -0.087156, 0.990737, -0.104131, 0, 0.104528, 0.994522) },
		{ k = "Motor6D", n = "Arm1", h = 4, a = 4, b = 21, c0 = CFrame.new(-0.662105, 1.120485, -0.152793, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.662105, 0, 0.422618, 0.906308, 0, -0.906308, 0.422618, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Arm2", h = 4, a = 4, b = 31, c0 = CFrame.new(0.662105, 1.120485, -0.152793, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.662105, 0, 0.422618, -0.906308, 0, 0.906308, 0.422618, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Head", h = 5, a = 5, b = 6, c0 = CFrame.new(0.062733, 0.717039, -0.026772, 0.996195, 0.086678, -0.00911, -0.087156, 0.990737, -0.104131, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.375141, 0.050931, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_StoneCollar", h = 5, a = 5, b = 44, c0 = CFrame.new(0.049489, 0.565661, -0.042743, 0.996195, 0.086678, -0.00911, -0.087156, 0.990737, -0.104131, 0, 0.104528, 0.994522), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal6", h = 6, a = 6, b = 3, c0 = CFrame.new(-0.684261, -0.684262, -0.763967, -0.707107, -0.707107, 0, 0.707107, -0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, -0.86583, 0.203725, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal5", h = 6, a = 6, b = 9, c0 = CFrame.new(0, -0.967692, -0.763967, -1, 0, 0, 0, -1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.86583, 0.203725, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal7", h = 6, a = 6, b = 10, c0 = CFrame.new(-0.967692, 0, -0.763967, 0, -1, 0, 1, 0, 0, 0, 0, 1), c1 = CFrame.new(0, -0.86583, 0.203725, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal2", h = 6, a = 6, b = 12, c0 = CFrame.new(0.684261, 0.684261, -0.763967, 0.707107, 0.707107, 0, -0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, -0.865829, 0.203725, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal8", h = 6, a = 6, b = 14, c0 = CFrame.new(-0.684261, 0.684261, -0.763967, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, -0.86583, 0.203725, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal1", h = 6, a = 6, b = 20, c0 = CFrame.new(0, 0.967692, -0.763967, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.865829, 0.203725, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal4", h = 6, a = 6, b = 22, c0 = CFrame.new(0.684261, -0.684262, -0.763967, -0.707107, 0.707107, 0, -0.707107, -0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, -0.86583, 0.203725, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MoltenCentre", h = 6, a = 6, b = 24, c0 = CFrame.new(0, 0, -0.529684, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Petal3", h = 6, a = 6, b = 30, c0 = CFrame.new(0.967692, 0, -0.763967, 0, 1, 0, -1, 0, 0, 0, 0, 1), c1 = CFrame.new(0, -0.86583, 0.203725, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalChip5", h = 9, a = 9, b = 8, c0 = CFrame.new(0.127328, 1.120485, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack5A", h = 9, a = 9, b = 28, c0 = CFrame.new(-0.168073, -0.178259, -0.519498, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack5B", h = 9, a = 9, b = 39, c0 = CFrame.new(-0.142607, 0.432915, -0.519498, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack7A", h = 10, a = 10, b = 18, c0 = CFrame.new(-0.168073, -0.178259, -0.519498, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack7B", h = 10, a = 10, b = 35, c0 = CFrame.new(-0.142608, 0.432915, -0.519498, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalChip7", h = 10, a = 10, b = 40, c0 = CFrame.new(0.127328, 1.120485, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalChip2", h = 12, a = 12, b = 11, c0 = CFrame.new(0.127328, 1.120486, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack2A", h = 12, a = 12, b = 33, c0 = CFrame.new(-0.168073, -0.178259, -0.519498, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack2B", h = 12, a = 12, b = 34, c0 = CFrame.new(-0.142607, 0.432915, -0.519498, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack8A", h = 14, a = 14, b = 15, c0 = CFrame.new(-0.168073, -0.178259, -0.519498, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalChip8", h = 14, a = 14, b = 26, c0 = CFrame.new(0.127328, 1.120486, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack8B", h = 14, a = 14, b = 47, c0 = CFrame.new(-0.142607, 0.432914, -0.519498, 0.819152, -0.573577, 0, 0.573577, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalChip1", h = 20, a = 20, b = 19, c0 = CFrame.new(0.127328, 1.120486, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack1A", h = 20, a = 20, b = 45, c0 = CFrame.new(-0.168073, -0.178259, -0.519498, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack1B", h = 20, a = 20, b = 48, c0 = CFrame.new(-0.142607, 0.432915, -0.519498, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ArmChip1", h = 21, a = 21, b = 37, c0 = CFrame.new(0, 0.86583, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack4B", h = 22, a = 22, b = 23, c0 = CFrame.new(-0.142607, 0.432915, -0.519498, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalChip4", h = 22, a = 22, b = 32, c0 = CFrame.new(0.127328, 1.120485, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack4A", h = 22, a = 22, b = 46, c0 = CFrame.new(-0.168072, -0.178259, -0.519498, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeL", h = 24, a = 24, b = 25, c0 = CFrame.new(0.443101, 0.178259, -0.127328, 0.951057, -0.309017, 0, 0.309017, 0.951057, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Mouth", h = 24, a = 24, b = 27, c0 = CFrame.new(0, -0.356518, -0.127328, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeR", h = 24, a = 24, b = 42, c0 = CFrame.new(-0.443101, 0.178259, -0.127328, 0.951057, 0.309017, 0, -0.309017, 0.951057, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_PetalChip3", h = 30, a = 30, b = 29, c0 = CFrame.new(0.127328, 1.120485, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack3B", h = 30, a = 30, b = 43, c0 = CFrame.new(-0.142607, 0.432915, -0.519498, 0.819152, -0.573576, 0, 0.573576, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Crack3A", h = 30, a = 30, b = 49, c0 = CFrame.new(-0.168072, -0.178259, -0.519498, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ArmChip2", h = 31, a = 31, b = 38, c0 = CFrame.new(0, 0.86583, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
