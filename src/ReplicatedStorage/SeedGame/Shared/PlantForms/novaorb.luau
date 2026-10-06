--!strict
--==============================================================================
-- PLANT FORM: Novaorb (Starbloom plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Starbloom plants/Novaorb" by a read-only generator on 2026-10-03. The original
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
	Source = "Starbloom plants/Novaorb", Kind = "plant", Yaw = 0,
	Size = Vector3.new(4.475571, 7.284927, 3.659744), Height = 7.284927, PartCount = 32,
	Base = 4,
	Unit = 4.5, ModelScale = 1.378434,
	Attributes = {},
	Parts = {
		{ n = "HoodHead", s = "Block", z = Vector3.new(2.7293, 1.984946, 1.984946), cf = CFrame.new(0, 3.659744, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(31, 28, 62), m = Enum.Material.Plastic }, -- 1
		{ n = "HoodCheek2", s = "Wedge", z = Vector3.new(0.620296, 1.550739, 0.744355), cf = CFrame.new(1.128937, 3.659744, -0.899429, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 2
		{ n = "SproutBody", s = "Block", z = Vector3.new(1.860886, 1.984946, 1.550739), cf = CFrame.new(0, 1.922916, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(67, 43, 115), m = Enum.Material.Plastic }, -- 3
		{ n = "Footing", s = "Block", z = Vector3.new(1.550739, 0.248118, 1.550739), cf = CFrame.new(0, 0.124059, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(31, 28, 62), m = Enum.Material.Plastic, t = 1, cs = false }, -- 4
		{ n = "GoldBrow", s = "Block", z = Vector3.new(1.054502, 0.217103, 0.403192), cf = CFrame.new(0, 4.124965, -0.930443, 0.996195, 0.087156, 0, -0.087156, 0.996195, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 5
		{ n = "LeafHand2", s = "Wedge", z = Vector3.new(0.682325, 1.116532, 0.682325), cf = CFrame.new(1.221985, 1.395665, -0.031013, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 6
		{ n = "LeafArm2", s = "Block", z = Vector3.new(0.465222, 1.054502, 0.558266), cf = CFrame.new(1.073112, 2.01596, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 7
		{ n = "RootLeg1", s = "Block", z = Vector3.new(0.806384, 0.930443, 0.992473), cf = CFrame.new(-0.539658, 0.744354, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(31, 28, 62), m = Enum.Material.Plastic }, -- 8
		{ n = "GoldEar1", s = "Block", z = Vector3.new(0.71334, 1.302621, 0.527251), cf = CFrame.new(-1.419296, 6.001388, 0.155075, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 9
		{ n = "EarStem1", s = "Block", z = Vector3.new(0.403192, 0.465222, 1.071245), cf = CFrame.new(-1.00798, 5.055408, 0.155075, 0, 0.926466, 0.376377, 0, 0.376377, -0.926466, -1, 0, 0), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 10
		{ n = "EarVein1", s = "Block", z = Vector3.new(0.111653, 0.992473, 0.10545), cf = CFrame.new(-1.432404, 6.029497, -0.099247, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 11
		{ n = "EarStem2", s = "Block", z = Vector3.new(0.403192, 0.465222, 1.071245), cf = CFrame.new(1.00798, 5.055408, 0.155075, 0, -0.926466, -0.376377, 0, 0.376377, -0.926466, 1, 0, 0), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 12
		{ n = "EarVein2", s = "Block", z = Vector3.new(0.111653, 0.992473, 0.10545), cf = CFrame.new(1.432404, 6.029497, -0.099247, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 13
		{ n = "GoldEar2", s = "Block", z = Vector3.new(0.71334, 1.302621, 0.527251), cf = CFrame.new(1.419296, 6.001388, 0.155075, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 14
		{ n = "Pupil", s = "Block", z = Vector3.new(0.173683, 0.384583, 0.055827), cf = CFrame.new(0.074432, 3.752788, -1.085518, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(31, 28, 62), m = Enum.Material.SmoothPlastic, st = false, a = { HideOnBlink = true } }, -- 15
		{ n = "Eye", s = "Block", z = Vector3.new(0.744355, 0.465222, 0.10545), cf = CFrame.new(0, 3.752788, -1.017284, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(128, 231, 255), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 16
		{ n = "BackRidge1", s = "Wedge", z = Vector3.new(0.372177, 1.302621, 0.403192), cf = CFrame.new(-0.465225, 1.922916, 0.787777, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 17
		{ n = "EarPoint2", s = "Wedge", z = Vector3.new(0.620296, 0.806384, 0.527251), cf = CFrame.new(1.786301, 6.788437, 0.155075, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 18
		{ n = "TailLeaf", s = "Wedge", z = Vector3.new(0.930443, 0.806384, 1.36465), cf = CFrame.new(0, 2.14002, 1.705814, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 19
		{ n = "TailStem", s = "Block", z = Vector3.new(0.434207, 0.465222, 0.992957), cf = CFrame.new(0, 1.798857, 1.101025, -1, 0, 0, 0, 0.968277, -0.249878, 0, -0.249878, -0.968277), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 20
		{ n = "EyeShine", s = "Block", z = Vector3.new(0.086841, 0.111653, 0.055827), cf = CFrame.new(0.031013, 3.845832, -1.122734, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(227, 253, 255), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 21
		{ n = "EarPoint1", s = "Wedge", z = Vector3.new(0.620296, 0.806384, 0.527251), cf = CFrame.new(-1.786301, 6.788437, 0.155075, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 22
		{ n = "RootLeg2", s = "Block", z = Vector3.new(0.806384, 0.930443, 0.992473), cf = CFrame.new(0.539658, 0.744354, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(31, 28, 62), m = Enum.Material.Plastic }, -- 23
		{ n = "RootFoot2", s = "Block", z = Vector3.new(1.116532, 0.806384, 1.550739), cf = CFrame.new(0.589279, 0.403192, -0.217102, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(67, 43, 115), m = Enum.Material.Plastic }, -- 24
		{ n = "BackRidge2", s = "Wedge", z = Vector3.new(0.372177, 1.302621, 0.403192), cf = CFrame.new(0.465225, 1.922916, 0.787777, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 25
		{ n = "HoodCheek1", s = "Wedge", z = Vector3.new(0.620296, 1.550739, 0.744355), cf = CFrame.new(-1.128937, 3.659744, -0.899429, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 26
		{ n = "ChestStar2", s = "Block", z = Vector3.new(0.142668, 0.71334, 0.086841), cf = CFrame.new(0, 1.984946, -0.79398, 0.766044, -0.642788, 0, 0.642788, 0.766044, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 27
		{ n = "LeafHand1", s = "Wedge", z = Vector3.new(0.682325, 1.116532, 0.682325), cf = CFrame.new(-1.221985, 1.395665, -0.031013, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 28
		{ n = "LeafArm1", s = "Block", z = Vector3.new(0.465222, 1.054502, 0.558266), cf = CFrame.new(-1.073112, 2.01596, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 29
		{ n = "HoodTop", s = "Wedge", z = Vector3.new(2.977418, 0.868414, 2.109005), cf = CFrame.new(0, 4.652216, 0, 0.997564, 0.069756, 0, -0.069756, 0.997564, 0, 0, 0, 1), c = Color3.fromRGB(91, 55, 143), m = Enum.Material.Plastic }, -- 30
		{ n = "ChestStar1", s = "Block", z = Vector3.new(0.142668, 0.71334, 0.086841), cf = CFrame.new(0, 1.984946, -0.79398, 0.766044, 0.642788, 0, -0.642788, 0.766044, 0, 0, 0, 1), c = Color3.fromRGB(239, 214, 149), m = Enum.Material.Plastic }, -- 31
		{ n = "RootFoot1", s = "Block", z = Vector3.new(1.116532, 0.806384, 1.550739), cf = CFrame.new(-0.589279, 0.403192, -0.217102, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(67, 43, 115), m = Enum.Material.Plastic }, -- 32
	},
	Joints = {
		{ k = "Weld", n = "Hold_HoodCheek2", h = 1, a = 1, b = 2, c0 = CFrame.new(1.128938, 0, -0.899428, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldBrow", h = 1, a = 1, b = 5, c0 = CFrame.new(0, 0.465222, -0.930443, 0.996195, 0.087156, 0, -0.087156, 0.996195, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ear1", h = 1, a = 1, b = 10, c0 = CFrame.new(-0.806384, 0.899429, 0.155074, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.535622, 0, 0, -1, 0.926466, 0.376377, 0, 0.376377, -0.926466, 0) },
		{ k = "Motor6D", n = "Ear2", h = 1, a = 1, b = 12, c0 = CFrame.new(0.806384, 0.899429, 0.155074, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.535622, 0, 0, 1, -0.926466, 0.376377, 0, -0.376377, -0.926466, 0) },
		{ k = "Weld", n = "Hold_Eye", h = 1, a = 1, b = 16, c0 = CFrame.new(0, 0.093044, -1.017285, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_HoodCheek1", h = 1, a = 1, b = 26, c0 = CFrame.new(-1.128938, 0, -0.899428, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_HoodTop", h = 1, a = 1, b = 30, c0 = CFrame.new(0, 0.992473, 0, 0.997564, 0.069756, 0, -0.069756, 0.997564, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Head", h = 3, a = 3, b = 1, c0 = CFrame.new(0, 0.837399, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.899428, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Arm2", h = 3, a = 3, b = 7, c0 = CFrame.new(0.868414, 0.527251, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.204697, 0.434207, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_BackRidge1", h = 3, a = 3, b = 17, c0 = CFrame.new(-0.465222, 0, 0.787775, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail", h = 3, a = 3, b = 20, c0 = CFrame.new(0, -0.248118, 0.620296, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.496479, -1, 0, 0, 0, 0.968277, -0.249878, 0, -0.249878, -0.968277) },
		{ k = "Weld", n = "Hold_BackRidge2", h = 3, a = 3, b = 25, c0 = CFrame.new(0.465222, 0, 0.787775, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ChestStar2", h = 3, a = 3, b = 27, c0 = CFrame.new(0, 0.062029, -0.793978, 0.766044, -0.642788, 0, 0.642788, 0.766044, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Arm1", h = 3, a = 3, b = 29, c0 = CFrame.new(-0.868414, 0.527251, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.204697, 0.434207, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_ChestStar1", h = 3, a = 3, b = 31, c0 = CFrame.new(0, 0.062029, -0.793978, 0.766044, 0.642788, 0, -0.642788, 0.766044, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 4, a = 4, b = 3, c0 = CFrame.new(0, 0.992473, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.806384, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootLeg1", h = 4, a = 4, b = 8, c0 = CFrame.new(-0.539657, 0.620295, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootLeg2", h = 4, a = 4, b = 23, c0 = CFrame.new(0.539657, 0.620295, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafHand2", h = 7, a = 7, b = 6, c0 = CFrame.new(0.148871, -0.620296, -0.031015, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot1", h = 8, a = 8, b = 32, c0 = CFrame.new(-0.049624, -0.341162, -0.217103, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EarVein1", h = 9, a = 9, b = 11, c0 = CFrame.new(0, 0.031015, -0.254321, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EarPoint1", h = 9, a = 9, b = 22, c0 = CFrame.new(0, 0.868413, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldEar1", h = 10, a = 10, b = 9, c0 = CFrame.new(0, -0.025024, -1.031228, 0, 0, -1, 0.998728, -0.050428, 0, -0.050428, -0.998728, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_GoldEar2", h = 12, a = 12, b = 14, c0 = CFrame.new(0, -0.025024, -1.031228, 0, 0, 1, -0.998728, -0.050428, 0, 0.050428, -0.998728, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EarVein2", h = 14, a = 14, b = 13, c0 = CFrame.new(0, 0.031015, -0.254321, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EarPoint2", h = 14, a = 14, b = 18, c0 = CFrame.new(0, 0.868413, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShine", h = 15, a = 15, b = 21, c0 = CFrame.new(-0.043421, 0.093044, -0.037218, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Pupil", h = 16, a = 16, b = 15, c0 = CFrame.new(0.074435, 0, -0.068232, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_TailLeaf", h = 20, a = 20, b = 19, c0 = CFrame.new(0, 0.179217, -0.670852, -1, 0, 0, 0, 0.968277, -0.249878, 0, -0.249878, -0.968277), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootFoot2", h = 23, a = 23, b = 24, c0 = CFrame.new(0.049624, -0.341162, -0.217103, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LeafHand1", h = 29, a = 29, b = 28, c0 = CFrame.new(-0.148871, -0.620296, -0.031015, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
