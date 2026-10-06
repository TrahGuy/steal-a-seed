--!strict
--==============================================================================
-- PLANT FORM: Lanterncap (Tanglemire)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Tanglemire/Lanterncap" by a read-only generator on 2026-10-03. The original
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
	Source = "Tanglemire/Lanterncap", Kind = "plant", Yaw = 0,
	Size = Vector3.new(2.537464, 4.604999, 3.148884), Height = 4.604999, PartCount = 49,
	Base = 1,
	Unit = 4.5, ModelScale = 0.605523,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(0.681213, 0.108994, 0.681213), cf = CFrame.new(0, 0.054497, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(29, 29, 38), m = Enum.Material.Plastic, t = 1, cs = false }, -- 1
		{ n = "Stalk2", s = "Block", z = Vector3.new(0.204364, 0.245237, 1.529718), cf = CFrame.new(0.020435, 2.465991, 0.463226, -0.136638, -0.949177, -0.283538, 0, 0.286223, -0.958163, 0.990621, -0.130921, -0.039109), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 2
		{ n = "CrookedArch", s = "Block", z = Vector3.new(0.177115, 0.245237, 0.985767), cf = CFrame.new(0.081745, 4.250769, -0.136242, 0.980581, 0.037743, 0.19245, 0, 0.981307, -0.192451, -0.196116, 0.188713, 0.96225), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 3
		{ n = "RootBulb", s = "Block", z = Vector3.new(0.681213, 0.599467, 0.681213), cf = CFrame.new(0, 0.354231, 0.245235, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 4
		{ n = "Stalk1", s = "Block", z = Vector3.new(0.204364, 0.245237, 1.496555), cf = CFrame.new(-0.088558, 1.130813, 0.340607, 0.991316, 0.018439, 0.130202, 0.131501, -0.139, -0.981523, 0, 0.990121, -0.140217), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 5
		{ n = "CapSector4", s = "Wedge", z = Vector3.new(0.790207, 0.245237, 1.198935), cf = CFrame.new(0.464478, 4.325909, -1.009449, -0.707107, 0.147016, 0.691655, 0, 0.978148, -0.207912, -0.707106, -0.147016, -0.691655), c = Color3.fromRGB(63, 55, 78), m = Enum.Material.Plastic }, -- 6
		{ n = "Stalk3", s = "Block", z = Vector3.new(0.204364, 0.245237, 1.195786), cf = CFrame.new(0.190739, 3.651301, 0.381481, 0.970143, 0.237019, 0.051434, 0, 0.21207, -0.977255, -0.242535, 0.948076, 0.205738), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 7
		{ n = "CapHub", s = "Block", z = Vector3.new(0.817456, 0.354231, 0.817456), cf = CFrame.new(0, 4.332514, -0.544971, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(47, 43, 62), m = Enum.Material.Plastic }, -- 8
		{ n = "VineCurl1", s = "Block", z = Vector3.new(0.108994, 0.149867, 0.651088), cf = CFrame.new(-0.789526, 2.671717, 0.365131, 0.099503, 0.842608, 0.529256, 0, 0.531896, -0.84681, -0.995037, 0.084261, 0.052925), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 9
		{ n = "VineLeaf1", s = "Wedge", z = Vector3.new(0.326982, 0.490473, 0.299734), cf = CFrame.new(-0.92577, 2.930579, 0.351505, 0.906308, -0.422619, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(95, 108, 69), m = Enum.Material.Plastic }, -- 10
		{ n = "SideVine1", s = "Block", z = Vector3.new(0.122618, 0.163491, 0.797546), cf = CFrame.new(-0.326302, 2.42648, 0.419628, 0.124035, 0.081772, 0.988903, 0, 0.996599, -0.082409, -0.992278, 0.010222, 0.123613), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 11
		{ n = "RootBlade2", s = "Wedge", z = Vector3.new(0.354231, 0.354231, 0.653964), cf = CFrame.new(0.66074, 0.177115, -0.136242, -0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, -0.5), c = Color3.fromRGB(95, 108, 69), m = Enum.Material.Plastic }, -- 12
		{ n = "RootBranch2", s = "Block", z = Vector3.new(0.204364, 0.258861, 0.919489), cf = CFrame.new(0.33037, 0.265673, 0.054497, 0.5, 0.195834, -0.843593, 0, 0.974097, 0.22613, 0.866025, -0.113065, 0.487049), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 13
		{ n = "CapSector6", s = "Wedge", z = Vector3.new(0.790207, 0.245237, 1.198935), cf = CFrame.new(-0.464478, 4.325909, -1.009449, -0.707107, -0.147016, -0.691655, 0, 0.978148, -0.207912, 0.707106, -0.147016, -0.691655), c = Color3.fromRGB(63, 55, 78), m = Enum.Material.Plastic }, -- 14
		{ n = "Lichen2", s = "Block", z = Vector3.new(0.122618, 0.059947, 0.136243), cf = CFrame.new(0.46608, 4.33657, -0.078892, 0.707107, 0.147016, 0.691655, 0, 0.978148, -0.207912, -0.707106, 0.147016, 0.691655), c = Color3.fromRGB(188, 145, 77), m = Enum.Material.Plastic }, -- 15
		{ n = "CapSector2", s = "Wedge", z = Vector3.new(0.790207, 0.245237, 1.198935), cf = CFrame.new(0.464478, 4.325909, -0.080494, 0.707107, 0.147016, 0.691655, 0, 0.978148, -0.207912, -0.707106, 0.147016, 0.691655), c = Color3.fromRGB(63, 55, 78), m = Enum.Material.Plastic }, -- 16
		{ n = "HangingVine", s = "Block", z = Vector3.new(0.122618, 0.163491, 0.73571), cf = CFrame.new(0, 3.910162, -0.544971, -1, 0, 0, 0, 0, 1, 0, 1, 0), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 17
		{ n = "AmberSeed", s = "Block", z = Vector3.new(0.463225, 0.585843, 0.326982), cf = CFrame.new(0, 3.242574, -0.544971, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 177, 51), m = Enum.Material.Neon, st = false, cs = false, a = { BaseColor = Color3.new(1, 0.694118, 0.2), HotColor = Color3.new(1, 0.898039, 0.568627) } }, -- 18
		{ n = "LanternRoof", s = "Block", z = Vector3.new(0.681213, 0.177115, 0.490473), cf = CFrame.new(0, 3.569556, -0.544971, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(29, 29, 38), m = Enum.Material.Plastic }, -- 19
		{ n = "LanternSill", s = "Block", z = Vector3.new(0.681213, 0.163491, 0.490473), cf = CFrame.new(0, 2.901968, -0.544971, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(29, 29, 38), m = Enum.Material.Plastic }, -- 20
		{ n = "CarvedBrow", s = "Block", z = Vector3.new(0.286109, 0.046322, 0.032698), cf = CFrame.new(0, 3.446938, -0.711185, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(29, 29, 38), m = Enum.Material.SmoothPlastic, st = false }, -- 21
		{ n = "CapSector7", s = "Wedge", z = Vector3.new(0.790207, 0.245237, 1.198935), cf = CFrame.new(-0.65687, 4.325909, -0.544971, 0, -0.207912, -0.978148, 0, 0.978148, -0.207912, 1, 0, 0), c = Color3.fromRGB(47, 43, 62), m = Enum.Material.Plastic }, -- 22
		{ n = "AmberGill4", s = "Block", z = Vector3.new(0.09537, 0.043598, 0.899201), cf = CFrame.new(0.476723, 4.210799, -1.021694, -0.707107, 0.147016, 0.691655, 0, 0.978148, -0.207912, -0.707106, -0.147016, -0.691655), c = Color3.fromRGB(255, 177, 51), m = Enum.Material.Neon, st = false, cs = false }, -- 23
		{ n = "CapSector1", s = "Wedge", z = Vector3.new(0.790207, 0.245237, 1.198935), cf = CFrame.new(0, 4.325909, 0.1119, 1, 0, 0, 0, 0.978148, -0.207912, 0, 0.207912, 0.978147), c = Color3.fromRGB(47, 43, 62), m = Enum.Material.Plastic }, -- 24
		{ n = "CapSector8", s = "Wedge", z = Vector3.new(0.790207, 0.245237, 1.198935), cf = CFrame.new(-0.464478, 4.325909, -0.080494, 0.707107, -0.147016, -0.691655, 0, 0.978148, -0.207912, 0.707107, 0.147016, 0.691655), c = Color3.fromRGB(63, 55, 78), m = Enum.Material.Plastic }, -- 25
		{ n = "EyeL", s = "Block", z = Vector3.new(0.057222, 0.136243, 0.032698), cf = CFrame.new(0.122618, 3.297071, -0.713913, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(29, 29, 38), m = Enum.Material.SmoothPlastic, st = false, a = { Blink = true } }, -- 26
		{ n = "AmberGill2", s = "Block", z = Vector3.new(0.09537, 0.043598, 0.899201), cf = CFrame.new(0.476723, 4.210799, -0.068249, 0.707107, 0.147016, 0.691655, 0, 0.978148, -0.207912, -0.707106, 0.147016, 0.691655), c = Color3.fromRGB(255, 177, 51), m = Enum.Material.Neon, st = false, cs = false }, -- 27
		{ n = "CapSector5", s = "Wedge", z = Vector3.new(0.790207, 0.245237, 1.198935), cf = CFrame.new(0, 4.325909, -1.201843, -1, 0, 0, 0, 0.978148, -0.207912, 0, -0.207912, -0.978147), c = Color3.fromRGB(47, 43, 62), m = Enum.Material.Plastic }, -- 28
		{ n = "AmberGill5", s = "Block", z = Vector3.new(0.09537, 0.043598, 0.899201), cf = CFrame.new(0, 4.210799, -1.219162, -1, 0, 0, 0, 0.978148, -0.207912, 0, -0.207912, -0.978147), c = Color3.fromRGB(255, 177, 51), m = Enum.Material.Neon, st = false, cs = false }, -- 29
		{ n = "VineCurl2", s = "Block", z = Vector3.new(0.108994, 0.149867, 0.651088), cf = CFrame.new(0.858055, 2.898697, 0.374397, 0.099504, -0.842607, -0.529256, 0, 0.531896, -0.84681, 0.995037, 0.084261, 0.052925), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 30
		{ n = "SideVine2", s = "Block", z = Vector3.new(0.122618, 0.163491, 0.797546), cf = CFrame.new(0.394831, 2.65346, 0.428894, 0.124035, -0.081772, -0.988903, 0, 0.996599, -0.082409, 0.992278, 0.010222, 0.123613), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 31
		{ n = "RootBranch3", s = "Block", z = Vector3.new(0.204364, 0.258861, 0.919489), cf = CFrame.new(-0.33037, 0.265673, 0.054497, 0.5, -0.195834, 0.843593, 0, 0.974097, 0.22613, -0.866025, -0.113065, 0.487049), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 32
		{ n = "RootBlade3", s = "Wedge", z = Vector3.new(0.354231, 0.354231, 0.653964), cf = CFrame.new(-0.66074, 0.177115, -0.136242, -0.5, 0, -0.866025, 0, 1, 0, 0.866025, 0, -0.5), c = Color3.fromRGB(95, 108, 69), m = Enum.Material.Plastic }, -- 33
		{ n = "AmberGill7", s = "Block", z = Vector3.new(0.09537, 0.043598, 0.899201), cf = CFrame.new(-0.674189, 4.210799, -0.544971, 0, -0.207912, -0.978148, 0, 0.978148, -0.207912, 1, 0, 0), c = Color3.fromRGB(255, 177, 51), m = Enum.Material.Neon, st = false, cs = false }, -- 34
		{ n = "VineLeaf2", s = "Wedge", z = Vector3.new(0.326982, 0.490473, 0.299734), cf = CFrame.new(0.994297, 3.157558, 0.360775, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(95, 108, 69), m = Enum.Material.Plastic }, -- 35
		{ n = "CapSector3", s = "Wedge", z = Vector3.new(0.790207, 0.245237, 1.198935), cf = CFrame.new(0.65687, 4.325909, -0.544971, 0, 0.207912, 0.978148, 0, 0.978148, -0.207912, -1, 0, 0), c = Color3.fromRGB(47, 43, 62), m = Enum.Material.Plastic }, -- 36
		{ n = "AmberGill1", s = "Block", z = Vector3.new(0.09537, 0.043598, 0.899201), cf = CFrame.new(0, 4.210798, 0.129219, 1, 0, 0, 0, 0.978148, -0.207912, 0, 0.207912, 0.978147), c = Color3.fromRGB(255, 177, 51), m = Enum.Material.Neon, st = false, cs = false }, -- 37
		{ n = "AmberGill3", s = "Block", z = Vector3.new(0.09537, 0.043598, 0.899201), cf = CFrame.new(0.674189, 4.210799, -0.544971, 0, 0.207912, 0.978148, 0, 0.978148, -0.207912, -1, 0, 0), c = Color3.fromRGB(255, 177, 51), m = Enum.Material.Neon, st = false, cs = false }, -- 38
		{ n = "LanternRail2", s = "Block", z = Vector3.new(0.09537, 0.667589, 0.435976), cf = CFrame.new(0.272486, 3.242574, -0.544971, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(63, 55, 78), m = Enum.Material.Plastic }, -- 39
		{ n = "SeedMouth", s = "Wedge", z = Vector3.new(0.09537, 0.065396, 0.038148), cf = CFrame.new(0, 3.119956, -0.705738, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(29, 29, 38), m = Enum.Material.SmoothPlastic, st = false }, -- 40
		{ n = "Lichen4", s = "Block", z = Vector3.new(0.122618, 0.059947, 0.136243), cf = CFrame.new(0.46608, 4.33657, -1.011051, -0.707107, 0.147016, 0.691655, 0, 0.978148, -0.207912, -0.707106, -0.147016, -0.691655), c = Color3.fromRGB(188, 145, 77), m = Enum.Material.Plastic }, -- 41
		{ n = "LanternRail1", s = "Block", z = Vector3.new(0.09537, 0.667589, 0.435976), cf = CFrame.new(-0.272486, 3.242574, -0.544971, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(63, 55, 78), m = Enum.Material.Plastic }, -- 42
		{ n = "AmberGill6", s = "Block", z = Vector3.new(0.09537, 0.043598, 0.899201), cf = CFrame.new(-0.476723, 4.210799, -1.021694, -0.707107, -0.147016, -0.691655, 0, 0.978148, -0.207912, 0.707106, -0.147016, -0.691655), c = Color3.fromRGB(255, 177, 51), m = Enum.Material.Neon, st = false, cs = false }, -- 43
		{ n = "RootBranch1", s = "Block", z = Vector3.new(0.204364, 0.258861, 0.919489), cf = CFrame.new(0, 0.265673, 0.626717, -1, 0, 0, 0, 0.974097, 0.22613, 0, 0.22613, -0.974097), c = Color3.fromRGB(55, 69, 54), m = Enum.Material.Plastic }, -- 44
		{ n = "AmberGill8", s = "Block", z = Vector3.new(0.09537, 0.043598, 0.899201), cf = CFrame.new(-0.476723, 4.210799, -0.068249, 0.707107, -0.147016, -0.691655, 0, 0.978148, -0.207912, 0.707107, 0.147016, 0.691655), c = Color3.fromRGB(255, 177, 51), m = Enum.Material.Neon, st = false, cs = false }, -- 45
		{ n = "CapNub", s = "Wedge", z = Vector3.new(0.326982, 0.272485, 0.326982), cf = CFrame.new(0, 4.468757, -0.544971, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(63, 55, 78), m = Enum.Material.Plastic }, -- 46
		{ n = "Lichen6", s = "Block", z = Vector3.new(0.122618, 0.059947, 0.136243), cf = CFrame.new(-0.46608, 4.33657, -1.011051, -0.707107, -0.147016, -0.691655, 0, 0.978148, -0.207912, 0.707106, -0.147016, -0.691655), c = Color3.fromRGB(188, 145, 77), m = Enum.Material.Plastic }, -- 47
		{ n = "EyeR", s = "Block", z = Vector3.new(0.057222, 0.136243, 0.032698), cf = CFrame.new(-0.122618, 3.297071, -0.713913, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(29, 29, 38), m = Enum.Material.SmoothPlastic, st = false, a = { Blink = true } }, -- 48
		{ n = "RootBlade1", s = "Wedge", z = Vector3.new(0.354231, 0.354231, 0.653964), cf = CFrame.new(0, 0.177115, 1.008198, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(95, 108, 69), m = Enum.Material.Plastic }, -- 49
	},
	Joints = {
		{ k = "Weld", n = "Hold_RootBulb", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 0.299734, 0.245237, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootBranch2", h = 1, a = 1, b = 13, c0 = CFrame.new(0.330371, 0.211176, 0.054497, 0.5, 0.195834, -0.843593, 0, 0.974097, 0.22613, 0.866025, -0.113065, 0.487049), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootBranch3", h = 1, a = 1, b = 32, c0 = CFrame.new(-0.330371, 0.211176, 0.054497, 0.5, -0.195834, 0.843593, 0, 0.974097, 0.22613, -0.866025, -0.113065, 0.487049), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootBranch1", h = 1, a = 1, b = 44, c0 = CFrame.new(0, 0.211176, 0.626716, -1, 0, 0, 0, 0.974097, 0.22613, 0, 0.22613, -0.974097), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Stem3", h = 2, a = 2, b = 7, c0 = CFrame.new(0, 0, -0.696738, -0.136638, 0, 0.990621, -0.949177, 0.286223, -0.130921, -0.283538, -0.958163, -0.039109), c1 = CFrame.new(0, 0, 0.529772, 0.970143, 0, -0.242535, 0.237019, 0.21207, 0.948076, 0.051434, -0.977255, 0.205738) },
		{ k = "Motor6D", n = "Vine1", h = 2, a = 2, b = 11, c0 = CFrame.new(0, 0, 0.069674, -0.136638, 0, 0.990621, -0.949177, 0.286223, -0.130921, -0.283538, -0.958163, -0.039109), c1 = CFrame.new(0, 0, 0.330652, 0.124035, 0, -0.992278, 0.081772, 0.996599, 0.010222, 0.988903, -0.082409, 0.123613) },
		{ k = "Motor6D", n = "Vine2", h = 2, a = 2, b = 31, c0 = CFrame.new(0, 0, -0.167217, -0.136638, 0, 0.990621, -0.949177, 0.286223, -0.130921, -0.283538, -0.958163, -0.039109), c1 = CFrame.new(0, 0, 0.330651, 0.124035, 0, 0.992278, -0.081772, 0.996599, 0.010222, -0.988903, -0.082409, 0.123613) },
		{ k = "Motor6D", n = "Cap", h = 3, a = 3, b = 8, c0 = CFrame.new(0, 0, -0.424762, 0.980581, 0, -0.196116, 0.037743, 0.981307, 0.188713, 0.19245, -0.192451, 0.96225), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 0.108994, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.680156, 0.991316, 0.131501, 0, 0.018439, -0.139, 0.990121, 0.130202, -0.981523, -0.140217) },
		{ k = "Motor6D", n = "Stem2", h = 5, a = 5, b = 2, c0 = CFrame.new(0, 0, -0.680156, 0.991316, 0.131501, 0, 0.018439, -0.139, 0.990121, 0.130202, -0.981523, -0.140217), c1 = CFrame.new(0, 0, 0.696738, -0.136638, 0, 0.990621, -0.949177, 0.286223, -0.130921, -0.283538, -0.958163, -0.039109) },
		{ k = "Weld", n = "Hold_AmberGill4", h = 6, a = 6, b = 23, c0 = CFrame.new(0, -0.108994, 0.040873, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Lichen4", h = 6, a = 6, b = 41, c0 = CFrame.new(0, 0.010899, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Arch", h = 7, a = 7, b = 3, c0 = CFrame.new(0, 0, -0.529772, 0.970143, 0, -0.242535, 0.237019, 0.21207, 0.948076, 0.051434, -0.977255, 0.205738), c1 = CFrame.new(0, 0, 0.424762, 0.980581, 0, -0.196116, 0.037743, 0.981307, 0.188713, 0.19245, -0.192451, 0.96225) },
		{ k = "Motor6D", n = "Gill4", h = 8, a = 8, b = 6, c0 = CFrame.new(0.125239, 0.09537, -0.125239, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, -0.490473, 1, 0, 0, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148) },
		{ k = "Motor6D", n = "Gill6", h = 8, a = 8, b = 14, c0 = CFrame.new(-0.125239, 0.09537, -0.125239, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, -0.490473, 1, 0, 0, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148) },
		{ k = "Motor6D", n = "Gill2", h = 8, a = 8, b = 16, c0 = CFrame.new(0.125239, 0.09537, 0.12524, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, -0.490473, 1, 0, 0, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148) },
		{ k = "Motor6D", n = "Pendant", h = 8, a = 8, b = 17, c0 = CFrame.new(0, -0.122619, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.299734, -1, 0, 0, 0, 0, 1, 0, 1, 0) },
		{ k = "Motor6D", n = "Gill7", h = 8, a = 8, b = 22, c0 = CFrame.new(-0.177115, 0.09537, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, -0.490473, 1, 0, 0, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148) },
		{ k = "Motor6D", n = "Gill1", h = 8, a = 8, b = 24, c0 = CFrame.new(0, 0.09537, 0.177115, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, -0.490473, 1, 0, 0, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148) },
		{ k = "Motor6D", n = "Gill8", h = 8, a = 8, b = 25, c0 = CFrame.new(-0.125239, 0.09537, 0.12524, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, -0.490473, 1, 0, 0, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148) },
		{ k = "Motor6D", n = "Gill5", h = 8, a = 8, b = 28, c0 = CFrame.new(0, 0.09537, -0.177115, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, -0.490473, 1, 0, 0, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148) },
		{ k = "Motor6D", n = "Gill3", h = 8, a = 8, b = 36, c0 = CFrame.new(0.177115, 0.09537, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, -0.490473, 1, 0, 0, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148) },
		{ k = "Weld", n = "Hold_CapNub", h = 8, a = 8, b = 46, c0 = CFrame.new(0, 0.136243, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_VineLeaf1", h = 9, a = 9, b = 10, c0 = CFrame.new(0, 0.02174, -0.292035, 0.090181, -0.042052, -0.995037, 0.98845, 0.12596, 0.084261, 0.121791, -0.991144, 0.052925), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Curl1", h = 11, a = 11, b = 9, c0 = CFrame.new(0, 0, -0.330651, 0.124035, 0, -0.992278, 0.081772, 0.996599, 0.010222, 0.988903, -0.082409, 0.123613), c1 = CFrame.new(0, 0, 0.257423, 0.099504, 0, -0.995037, 0.842607, 0.531896, 0.084261, 0.529256, -0.84681, 0.052925) },
		{ k = "Weld", n = "Hold_RootBlade2", h = 13, a = 13, b = 12, c0 = CFrame.new(0, 0, -0.391623, -1, 0, 0, 0, 0.974097, 0.22613, 0, 0.22613, -0.974097), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AmberGill6", h = 14, a = 14, b = 43, c0 = CFrame.new(0, -0.108994, 0.040873, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Lichen6", h = 14, a = 14, b = 47, c0 = CFrame.new(0, 0.010899, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Lichen2", h = 16, a = 16, b = 15, c0 = CFrame.new(0, 0.010899, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AmberGill2", h = 16, a = 16, b = 27, c0 = CFrame.new(0, -0.108994, 0.040873, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Lantern", h = 17, a = 17, b = 19, c0 = CFrame.new(0, 0, -0.286109, -1, 0, 0, 0, 0, 1, 0, 1, 0), c1 = CFrame.new(0, 0.054497, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LanternSill", h = 18, a = 18, b = 20, c0 = CFrame.new(0, -0.340606, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_CarvedBrow", h = 18, a = 18, b = 21, c0 = CFrame.new(0, 0.204364, -0.166216, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeL", h = 18, a = 18, b = 26, c0 = CFrame.new(0.122618, 0.054497, -0.168941, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_SeedMouth", h = 18, a = 18, b = 40, c0 = CFrame.new(0, -0.122619, -0.160766, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeR", h = 18, a = 18, b = 48, c0 = CFrame.new(-0.122618, 0.054497, -0.168941, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AmberSeed", h = 19, a = 19, b = 18, c0 = CFrame.new(0, -0.326982, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LanternRail2", h = 19, a = 19, b = 39, c0 = CFrame.new(0.272485, -0.326982, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LanternRail1", h = 19, a = 19, b = 42, c0 = CFrame.new(-0.272485, -0.326982, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AmberGill7", h = 22, a = 22, b = 34, c0 = CFrame.new(0, -0.108994, 0.040873, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AmberGill1", h = 24, a = 24, b = 37, c0 = CFrame.new(0, -0.108994, 0.040873, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AmberGill8", h = 25, a = 25, b = 45, c0 = CFrame.new(0, -0.108994, 0.040873, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AmberGill5", h = 28, a = 28, b = 29, c0 = CFrame.new(0, -0.108994, 0.040873, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_VineLeaf2", h = 30, a = 30, b = 35, c0 = CFrame.new(0, 0.02174, -0.292034, 0.090181, 0.042052, 0.995037, -0.98845, 0.12596, 0.084261, -0.121791, -0.991144, 0.052925), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Curl2", h = 31, a = 31, b = 30, c0 = CFrame.new(0, 0, -0.330652, 0.124035, 0, 0.992278, -0.081772, 0.996599, 0.010222, -0.988903, -0.082409, 0.123613), c1 = CFrame.new(0, 0, 0.257423, 0.099504, 0, 0.995037, -0.842607, 0.531896, 0.084261, -0.529256, -0.84681, 0.052925) },
		{ k = "Weld", n = "Hold_RootBlade3", h = 32, a = 32, b = 33, c0 = CFrame.new(0, 0, -0.391623, -1, 0, 0, 0, 0.974097, 0.22613, 0, 0.22613, -0.974097), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_AmberGill3", h = 36, a = 36, b = 38, c0 = CFrame.new(0, -0.108994, 0.040873, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_RootBlade1", h = 44, a = 44, b = 49, c0 = CFrame.new(0, 0, -0.391623, -1, 0, 0, 0, 0.974097, 0.22613, 0, 0.22613, -0.974097), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
