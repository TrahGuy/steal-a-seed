--!strict
--==============================================================================
-- PLANT FORM: Raincup (Dustbowl plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Dustbowl plants/Raincup" by a read-only generator on 2026-10-03. The original
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
	Source = "Dustbowl plants/Raincup", Kind = "plant", Yaw = 0,
	Size = Vector3.new(6.538967, 7.230999, 5.316458), Height = 7.230999, PartCount = 68,
	Base = 5,
	Unit = 4.5, ModelScale = 1,
	Attributes = {},
	Parts = {
		{ n = "CupBowl", s = "Block", z = Vector3.new(2.43, 0.45, 2.43), cf = CFrame.new(0, 5.850001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 1
		{ n = "CupRim2", s = "Block", z = Vector3.new(2.025, 0.3375, 0.54), cf = CFrame.new(1.654631, 6.930001, 1.654629, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 2
		{ n = "StemBody", s = "Block", z = Vector3.new(2.25, 2.385, 1.89), cf = CFrame.new(0, 3.915001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(166, 204, 179), m = Enum.Material.Plastic }, -- 3
		{ n = "CupWall2", s = "Block", z = Vector3.new(1.755, 0.63, 1.746074), cf = CFrame.new(1.304615, 6.367501, 1.304611, -0.707107, -0.530835, -0.467135, 0, 0.660628, -0.750713, 0.707107, -0.530835, -0.467135), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 4
		{ n = "Footing", s = "Block", z = Vector3.new(0.54, 0.54, 0.54), cf = CFrame.new(0, 0.000001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(43, 94, 88), m = Enum.Material.Plastic, t = 1 }, -- 5
		{ n = "UpperStem", s = "Block", z = Vector3.new(0.9, 1.575, 0.9), cf = CFrame.new(0, 5.220001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 177, 156), m = Enum.Material.Plastic }, -- 6
		{ n = "SmileL", s = "Block", z = Vector3.new(0.1935, 0.054, 0.063), cf = CFrame.new(-0.080999, 3.996001, -1.106998, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(43, 94, 88), m = Enum.Material.Plastic }, -- 7
		{ n = "FaceCore", s = "Block", z = Vector3.new(1.44, 1.17, 0.27), cf = CFrame.new(0.000002, 4.275001, -0.9585, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 8
		{ n = "CupWall1", s = "Block", z = Vector3.new(1.755, 0.63, 1.746074), cf = CFrame.new(0, 6.367501, 1.845001, -1, 0, 0, 0, 0.660628, -0.750714, 0, -0.750714, -0.660628), c = Color3.fromRGB(166, 204, 179), m = Enum.Material.Plastic }, -- 9
		{ n = "RootUpper2", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(1.200676, 2.498075, -0.845615, 0.4809, 0.546655, -0.685495, -0.064976, 0.801907, 0.593905, 0.874365, -0.241069, 0.421157), c = Color3.fromRGB(106, 146, 127), m = Enum.Material.Plastic }, -- 10
		{ n = "RootFoot2", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(1.035, 0.2925, -0.900002, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(106, 146, 127), m = Enum.Material.Plastic }, -- 11
		{ n = "RootLower2", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(1.403175, 1.271824, -1.048115, 0.4809, 0.757065, 0.442252, -0.064976, -0.472248, 0.879068, 0.874364, -0.45148, -0.177913), c = Color3.fromRGB(130, 177, 156), m = Enum.Material.Plastic }, -- 12
		{ n = "RootToe2", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(1.035002, 0.5625, -1.057503, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 13
		{ n = "LeafBranch2", s = "Block", z = Vector3.new(0.3375, 0.3375, 1.111033), cf = CFrame.new(1.35, 4.252501, 0.134998, 0, -0.33035, -0.943859, 0, 0.943859, -0.33035, 1, 0, 0), c = Color3.fromRGB(106, 146, 127), m = Enum.Material.Plastic }, -- 14
		{ n = "LeafBlade2", s = "Block", z = Vector3.new(0.63, 1.305, 0.405), cf = CFrame.new(2.126272, 4.562143, 0.134995, 0.422618, 0.906308, 0, -0.906308, 0.422618, 0, 0, 0, 1), c = Color3.fromRGB(166, 204, 179), m = Enum.Material.Plastic }, -- 15
		{ n = "CupRim3", s = "Block", z = Vector3.new(2.025, 0.3375, 0.54), cf = CFrame.new(2.340002, 6.930001, 0.000004, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 16
		{ n = "CupWall3", s = "Block", z = Vector3.new(1.755, 0.63, 1.746074), cf = CFrame.new(1.845001, 6.367501, 0, 0, -0.750714, -0.660628, 0, 0.660628, -0.750714, 1, 0, 0), c = Color3.fromRGB(166, 204, 179), m = Enum.Material.Plastic }, -- 17
		{ n = "RootUpper4", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(1.200674, 2.498075, 0.845615, -0.4809, 0.546655, -0.685495, 0.064976, 0.801907, 0.593905, 0.874364, 0.241069, -0.421157), c = Color3.fromRGB(106, 146, 127), m = Enum.Material.Plastic }, -- 18
		{ n = "BrowL", s = "Block", z = Vector3.new(0.3645, 0.0855, 0.1125), cf = CFrame.new(-0.359997, 4.770001, -1.0755, 0.987688, -0.156434, 0, 0.156434, 0.987688, 0, 0, 0, 1), c = Color3.fromRGB(130, 177, 156), m = Enum.Material.Plastic }, -- 19
		{ n = "PoolCore", s = "Block", z = Vector3.new(2.97, 0.1575, 2.97), cf = CFrame.new(0, 6.693751, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(35, 219, 216), m = Enum.Material.Neon, st = false, cs = false }, -- 20
		{ n = "BasinWater", s = "Block", z = Vector3.new(2.16, 0.72, 2.16), cf = CFrame.new(0, 6.390001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(35, 219, 216), m = Enum.Material.Neon, st = false, cs = false }, -- 21
		{ n = "PoolArm3", s = "Block", z = Vector3.new(1.935, 0.1575, 0.63), cf = CFrame.new(0, 6.693751, 1.710003, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(35, 219, 216), m = Enum.Material.Neon, st = false, cs = false }, -- 22
		{ n = "PoolArm4", s = "Block", z = Vector3.new(1.935, 0.1575, 0.63), cf = CFrame.new(0, 6.693751, -1.709999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(35, 219, 216), m = Enum.Material.Neon, st = false, cs = false }, -- 23
		{ n = "CupRim7", s = "Block", z = Vector3.new(2.025, 0.3375, 0.54), cf = CFrame.new(-2.340002, 6.930001, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 24
		{ n = "CupWall7", s = "Block", z = Vector3.new(1.755, 0.63, 1.746074), cf = CFrame.new(-1.845001, 6.367501, 0, 0, 0.750714, 0.660628, 0, 0.660628, -0.750714, -1, 0, 0), c = Color3.fromRGB(166, 204, 179), m = Enum.Material.Plastic }, -- 25
		{ n = "RootFoot4", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(1.034998, 0.2925, 0.899998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(106, 146, 127), m = Enum.Material.Plastic }, -- 26
		{ n = "RootLower4", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(1.403173, 1.271824, 1.048115, -0.4809, 0.757065, 0.442252, 0.064976, -0.472248, 0.879068, 0.874364, 0.45148, 0.177913), c = Color3.fromRGB(130, 177, 156), m = Enum.Material.Plastic }, -- 27
		{ n = "RootToe4", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(1.035, 0.5625, 0.7425, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 28
		{ n = "LeafBranch1", s = "Block", z = Vector3.new(0.3375, 0.3375, 1.111033), cf = CFrame.new(-1.349998, 4.252501, 0.135002, 0, 0.33035, 0.943859, 0, 0.943859, -0.33035, -1, 0, 0), c = Color3.fromRGB(106, 146, 127), m = Enum.Material.Plastic }, -- 29
		{ n = "LeafBlade1", s = "Block", z = Vector3.new(0.63, 1.305, 0.405), cf = CFrame.new(-2.12627, 4.562143, 0.135002, 0.422618, -0.906308, 0, 0.906308, 0.422618, 0, 0, 0, 1), c = Color3.fromRGB(166, 204, 179), m = Enum.Material.Plastic }, -- 30
		{ n = "CupRim6", s = "Block", z = Vector3.new(2.025, 0.3375, 0.54), cf = CFrame.new(-1.654629, 6.930001, -1.654625, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 31
		{ n = "CupWall6", s = "Block", z = Vector3.new(1.755, 0.63, 1.746074), cf = CFrame.new(-1.304611, 6.367501, -1.304611, 0.707107, 0.530835, 0.467135, 0, 0.660628, -0.750713, -0.707107, 0.530835, 0.467135), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 32
		{ n = "RootUpper3", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(-1.200674, 2.498075, 0.845615, -0.4809, -0.546655, 0.685495, -0.064976, 0.801907, 0.593905, -0.874365, 0.241069, -0.421157), c = Color3.fromRGB(106, 146, 127), m = Enum.Material.Plastic }, -- 33
		{ n = "EyeL", s = "Block", z = Vector3.new(0.297, 0.252, 0.0855), cf = CFrame.new(-0.359999, 4.567501, -1.120502, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 121, 126), m = Enum.Material.Plastic, st = false, sf = { "Smooth", "Studs", "Studs", "Studs", "Smooth", "Studs" } }, -- 34
		{ n = "RootLower3", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(-1.403175, 1.271824, 1.048115, -0.4809, -0.757065, -0.442252, -0.064976, -0.472248, 0.879068, -0.874364, 0.45148, 0.177913), c = Color3.fromRGB(130, 177, 156), m = Enum.Material.Plastic }, -- 35
		{ n = "LeafPoint2", s = "Wedge", z = Vector3.new(0.585, 0.72, 0.4275), cf = CFrame.new(2.819597, 4.885447, 0.134998, 0.422618, 0.906308, 0, -0.906308, 0.422618, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 36
		{ n = "Ripple3", s = "Block", z = Vector3.new(0.0495, 0.054, 0.9), cf = CFrame.new(-0.18, 6.786001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(160, 250, 233), m = Enum.Material.Neon, st = false, cs = false }, -- 37
		{ n = "RootUpper1", s = "Block", z = Vector3.new(0.495, 0.495, 1.8), cf = CFrame.new(-1.200672, 2.498075, -0.845612, 0.4809, -0.546655, 0.685495, 0.064976, 0.801907, 0.593905, -0.874364, -0.241069, 0.421157), c = Color3.fromRGB(106, 146, 127), m = Enum.Material.Plastic }, -- 38
		{ n = "RootFoot1", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(-1.034998, 0.2925, -0.899998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(106, 146, 127), m = Enum.Material.Plastic }, -- 39
		{ n = "RootLower1", s = "Block", z = Vector3.new(0.45, 0.45, 1.8), cf = CFrame.new(-1.403173, 1.271824, -1.048111, 0.4809, -0.757065, -0.442252, 0.064976, -0.472248, 0.879068, -0.874364, -0.45148, -0.177913), c = Color3.fromRGB(130, 177, 156), m = Enum.Material.Plastic }, -- 40
		{ n = "RootFoot3", s = "Block", z = Vector3.new(0.675, 0.585, 0.99), cf = CFrame.new(-1.035, 0.2925, 0.900005, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(106, 146, 127), m = Enum.Material.Plastic }, -- 41
		{ n = "CupRim1", s = "Block", z = Vector3.new(2.025, 0.3375, 0.54), cf = CFrame.new(0, 6.930001, 2.34, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 42
		{ n = "BrowR", s = "Block", z = Vector3.new(0.3645, 0.0855, 0.1125), cf = CFrame.new(0.360003, 4.770001, -1.0755, 0.987688, 0.156434, 0, -0.156434, 0.987688, 0, 0, 0, 1), c = Color3.fromRGB(130, 177, 156), m = Enum.Material.Plastic }, -- 43
		{ n = "PoolArm2", s = "Block", z = Vector3.new(0.63, 0.1575, 1.935), cf = CFrame.new(-1.709999, 6.693751, 0.000004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(35, 219, 216), m = Enum.Material.Neon, st = false, cs = false }, -- 44
		{ n = "Ripple2", s = "Block", z = Vector3.new(0.9, 0.054, 0.0495), cf = CFrame.new(0.27, 6.786001, 0.450001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(160, 250, 233), m = Enum.Material.Neon, st = false, cs = false }, -- 45
		{ n = "PoolArm1", s = "Block", z = Vector3.new(0.63, 0.1575, 1.935), cf = CFrame.new(1.709999, 6.693751, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(35, 219, 216), m = Enum.Material.Neon, st = false, cs = false }, -- 46
		{ n = "TearL", s = "Block", z = Vector3.new(0.063, 0.2835, 0.0675), cf = CFrame.new(-0.463499, 4.212001, -1.106998, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(35, 219, 216), m = Enum.Material.Neon, st = false, cs = false }, -- 47
		{ n = "EyeR", s = "Block", z = Vector3.new(0.297, 0.252, 0.0855), cf = CFrame.new(0.360001, 4.567501, -1.120499, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 121, 126), m = Enum.Material.Plastic, st = false, sf = { "Smooth", "Studs", "Studs", "Studs", "Smooth", "Studs" } }, -- 48
		{ n = "BodyRib3", s = "Block", z = Vector3.new(0.3375, 1.8, 0.18), cf = CFrame.new(0.675001, 3.870001, 0.913502, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 49
		{ n = "PoolSparkle1", s = "Block", z = Vector3.new(0.2925, 0.045, 0.0585), cf = CFrame.new(-0.585001, 6.786001, -0.314999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Neon, st = false, cs = false }, -- 50
		{ n = "TearR", s = "Block", z = Vector3.new(0.063, 0.2835, 0.0675), cf = CFrame.new(0.463501, 4.212001, -1.107002, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(35, 219, 216), m = Enum.Material.Neon, st = false, cs = false }, -- 51
		{ n = "LeafPoint1", s = "Wedge", z = Vector3.new(0.585, 0.72, 0.4275), cf = CFrame.new(-2.819595, 4.885447, 0.135002, 0.422618, -0.906308, 0, 0.906308, 0.422618, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 52
		{ n = "Ripple4", s = "Block", z = Vector3.new(0.0495, 0.054, 0.9), cf = CFrame.new(0.719999, 6.786001, -0.000004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(160, 250, 233), m = Enum.Material.Neon, st = false, cs = false }, -- 53
		{ n = "PoolSparkle2", s = "Block", z = Vector3.new(0.0585, 0.045, 0.2925), cf = CFrame.new(-0.585001, 6.786001, -0.314999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Neon, st = false, cs = false }, -- 54
		{ n = "CupWall5", s = "Block", z = Vector3.new(1.755, 0.63, 1.746074), cf = CFrame.new(0.000002, 6.367501, -1.845001, 1, 0, 0, 0, 0.660628, -0.750714, 0, 0.750714, 0.660628), c = Color3.fromRGB(166, 204, 179), m = Enum.Material.Plastic }, -- 55
		{ n = "SmileR", s = "Block", z = Vector3.new(0.1935, 0.054, 0.063), cf = CFrame.new(0.081001, 3.996001, -1.107002, 0.965926, -0.258819, 0, 0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(43, 94, 88), m = Enum.Material.Plastic }, -- 56
		{ n = "CupWall8", s = "Block", z = Vector3.new(1.755, 0.63, 1.746074), cf = CFrame.new(-1.304611, 6.367501, 1.304611, -0.707107, 0.530835, 0.467135, 0, 0.660628, -0.750713, -0.707107, -0.530835, -0.467135), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 57
		{ n = "CupRim8", s = "Block", z = Vector3.new(2.025, 0.3375, 0.54), cf = CFrame.new(-1.654631, 6.930001, 1.654625, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 58
		{ n = "RootToe1", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(-1.034998, 0.5625, -1.057499, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 59
		{ n = "RootToe3", s = "Block", z = Vector3.new(0.18, 0.1125, 0.72), cf = CFrame.new(-1.035, 0.5625, 0.742504, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 60
		{ n = "EyeShineL", s = "Block", z = Vector3.new(0.054, 0.072, 0.063), cf = CFrame.new(-0.287998, 4.603501, -1.165504, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(160, 250, 233), m = Enum.Material.Neon, st = false, cs = false }, -- 61
		{ n = "CupRim5", s = "Block", z = Vector3.new(2.025, 0.3375, 0.54), cf = CFrame.new(0.000002, 6.930001, -2.34, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 62
		{ n = "BodyRib1", s = "Block", z = Vector3.new(0.3375, 1.8, 0.18), cf = CFrame.new(-0.674999, 3.870001, 0.913498, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 63
		{ n = "Ripple1", s = "Block", z = Vector3.new(0.9, 0.054, 0.0495), cf = CFrame.new(0.270002, 6.786001, -0.450001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(160, 250, 233), m = Enum.Material.Neon, st = false, cs = false }, -- 64
		{ n = "CupRim4", s = "Block", z = Vector3.new(2.025, 0.3375, 0.54), cf = CFrame.new(1.654633, 6.930001, -1.654629, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 65
		{ n = "CupWall4", s = "Block", z = Vector3.new(1.755, 0.63, 1.746074), cf = CFrame.new(1.304613, 6.367501, -1.304611, 0.707107, -0.530835, -0.467135, 0, 0.660628, -0.750713, 0.707107, 0.530835, 0.467135), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 66
		{ n = "BodyRib2", s = "Block", z = Vector3.new(0.3375, 1.8, 0.18), cf = CFrame.new(0, 3.870001, 0.913502, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(225, 237, 210), m = Enum.Material.Plastic }, -- 67
		{ n = "EyeShineR", s = "Block", z = Vector3.new(0.054, 0.072, 0.063), cf = CFrame.new(0.288002, 4.603501, -1.165501, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(160, 250, 233), m = Enum.Material.Neon, st = false, cs = false }, -- 68
	},
	Joints = {
		{ k = "Weld", n = "CupWall2Weld", h = 1, a = 1, b = 4, c0 = CFrame.new(1.304612, 0.5175, 1.304612, -0.707107, -0.530835, -0.467135, 0, 0.660628, -0.750713, 0.707107, -0.530835, -0.467135), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupWall1Weld", h = 1, a = 1, b = 9, c0 = CFrame.new(0, 0.5175, 1.845, -1, 0, 0, 0, 0.660628, -0.750714, 0, -0.750714, -0.660628), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupWall3Weld", h = 1, a = 1, b = 17, c0 = CFrame.new(1.845, 0.5175, 0, 0, -0.750714, -0.660628, 0, 0.660628, -0.750714, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BasinWaterWeld", h = 1, a = 1, b = 21, c0 = CFrame.new(0, 0.54, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupWall7Weld", h = 1, a = 1, b = 25, c0 = CFrame.new(-1.845, 0.5175, 0, 0, 0.750714, 0.660628, 0, 0.660628, -0.750714, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupWall6Weld", h = 1, a = 1, b = 32, c0 = CFrame.new(-1.304612, 0.5175, -1.304612, 0.707107, 0.530835, 0.467135, 0, 0.660628, -0.750713, -0.707107, 0.530835, 0.467135), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupWall5Weld", h = 1, a = 1, b = 55, c0 = CFrame.new(0, 0.5175, -1.845, 1, 0, 0, 0, 0.660628, -0.750714, 0, 0.750714, 0.660628), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupWall8Weld", h = 1, a = 1, b = 57, c0 = CFrame.new(-1.304612, 0.5175, 1.304612, -0.707107, 0.530835, 0.467135, 0, 0.660628, -0.750713, -0.707107, -0.530835, -0.467135), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupWall4Weld", h = 1, a = 1, b = 66, c0 = CFrame.new(1.304612, 0.5175, -1.304612, 0.707107, -0.530835, -0.467135, 0, 0.660628, -0.750713, 0.707107, 0.530835, 0.467135), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Stem", h = 3, a = 3, b = 6, c0 = CFrame.new(0, 0.8325, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.4725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FaceCoreWeld", h = 3, a = 3, b = 8, c0 = CFrame.new(0, 0.36, -0.9585, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip2", h = 3, a = 3, b = 10, c0 = CFrame.new(1.200675, -1.416926, -0.845613, 0.4809, 0.546655, -0.685495, -0.064976, 0.801907, 0.593905, 0.874364, -0.241069, 0.421157), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LeafJoint2", h = 3, a = 3, b = 14, c0 = CFrame.new(0.9, 0.18, 0.135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.476766, 0, 0, 1, -0.33035, 0.943859, 0, -0.943859, -0.33035, 0) },
		{ k = "Motor6D", n = "Hip4", h = 3, a = 3, b = 18, c0 = CFrame.new(1.200675, -1.416926, 0.845613, -0.4809, 0.546655, -0.685495, 0.064976, 0.801907, 0.593905, 0.874364, 0.241069, -0.421157), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LeafJoint1", h = 3, a = 3, b = 29, c0 = CFrame.new(-0.9, 0.18, 0.135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.476766, 0, 0, -1, 0.33035, 0.943859, 0, 0.943859, -0.33035, 0) },
		{ k = "Motor6D", n = "Hip3", h = 3, a = 3, b = 33, c0 = CFrame.new(-1.200675, -1.416926, 0.845613, -0.4809, -0.546655, 0.685495, -0.064976, 0.801907, 0.593905, -0.874364, 0.241069, -0.421157), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip1", h = 3, a = 3, b = 38, c0 = CFrame.new(-1.200675, -1.416926, -0.845613, 0.4809, -0.546655, 0.685495, 0.064976, 0.801907, 0.593905, -0.874364, -0.241069, 0.421157), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BodyRib3Weld", h = 3, a = 3, b = 49, c0 = CFrame.new(0.675, -0.045, 0.9135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BodyRib1Weld", h = 3, a = 3, b = 63, c0 = CFrame.new(-0.675, -0.045, 0.9135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BodyRib2Weld", h = 3, a = 3, b = 67, c0 = CFrame.new(0, -0.045, 0.9135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupRim2Weld", h = 4, a = 4, b = 2, c0 = CFrame.new(0, 0, -0.749287, -1, 0, 0, 0, 0.660628, -0.750714, 0, -0.750713, -0.660628), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 5, a = 5, b = 3, c0 = CFrame.new(0, 3.915, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Cup", h = 6, a = 6, b = 1, c0 = CFrame.new(0, 0.5175, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.1125, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SmileLWeld", h = 8, a = 8, b = 7, c0 = CFrame.new(-0.081, -0.279, -0.1485, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowLWeld", h = 8, a = 8, b = 19, c0 = CFrame.new(-0.36, 0.495, -0.117, 0.987688, -0.156434, 0, 0.156434, 0.987688, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "EyeLWeld", h = 8, a = 8, b = 34, c0 = CFrame.new(-0.36, 0.2925, -0.162, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowRWeld", h = 8, a = 8, b = 43, c0 = CFrame.new(0.36, 0.495, -0.117, 0.987688, 0.156434, 0, -0.156434, 0.987688, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "TearLWeld", h = 8, a = 8, b = 47, c0 = CFrame.new(-0.4635, -0.063, -0.1485, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "EyeRWeld", h = 8, a = 8, b = 48, c0 = CFrame.new(0.36, 0.2925, -0.162, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "TearRWeld", h = 8, a = 8, b = 51, c0 = CFrame.new(0.4635, -0.063, -0.1485, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SmileRWeld", h = 8, a = 8, b = 56, c0 = CFrame.new(0.081, -0.279, -0.1485, 0.965926, -0.258819, 0, 0.258819, 0.965926, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupRim1Weld", h = 9, a = 9, b = 42, c0 = CFrame.new(0, 0, -0.749287, -1, 0, 0, 0, 0.660628, -0.750714, 0, -0.750714, -0.660628), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee2", h = 10, a = 10, b = 12, c0 = CFrame.new(0, -0.823825, -0.952374, 1, 0, 0, 0, 0.143992, 0.989579, 0, -0.989579, 0.143992), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe2Weld", h = 11, a = 11, b = 13, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle2", h = 12, a = 12, b = 11, c0 = CFrame.new(0.016081, 0.116881, -1.050069, 0.4809, -0.064976, 0.874364, 0.757065, -0.472248, -0.45148, 0.442252, 0.879068, -0.177913), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LeafBlade2Weld", h = 14, a = 14, b = 15, c0 = CFrame.new(0, 0.035818, -0.83498, 0, 0, 1, -0.995038, 0.099493, 0, -0.099493, -0.995038, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LeafPoint2Weld", h = 15, a = 15, b = 36, c0 = CFrame.new(-0.000001, 0.765, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupRim3Weld", h = 17, a = 17, b = 16, c0 = CFrame.new(0, 0, -0.749287, -1, 0, 0, 0, 0.660628, -0.750714, 0, -0.750714, -0.660628), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee4", h = 18, a = 18, b = 27, c0 = CFrame.new(0, -0.823825, -0.952374, 1, 0, 0, 0, 0.143992, 0.989579, 0, -0.989579, 0.143992), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PoolArm3Weld", h = 20, a = 20, b = 22, c0 = CFrame.new(0, 0, 1.71, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PoolArm4Weld", h = 20, a = 20, b = 23, c0 = CFrame.new(0, 0, -1.71, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Ripple3Weld", h = 20, a = 20, b = 37, c0 = CFrame.new(-0.18, 0.09225, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PoolArm2Weld", h = 20, a = 20, b = 44, c0 = CFrame.new(-1.71, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Ripple2Weld", h = 20, a = 20, b = 45, c0 = CFrame.new(0.27, 0.09225, 0.45, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PoolArm1Weld", h = 20, a = 20, b = 46, c0 = CFrame.new(1.71, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PoolSparkle1Weld", h = 20, a = 20, b = 50, c0 = CFrame.new(-0.585, 0.09225, -0.315, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Ripple4Weld", h = 20, a = 20, b = 53, c0 = CFrame.new(0.72, 0.09225, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PoolSparkle2Weld", h = 20, a = 20, b = 54, c0 = CFrame.new(-0.585, 0.09225, -0.315, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Ripple1Weld", h = 20, a = 20, b = 64, c0 = CFrame.new(0.27, 0.09225, -0.45, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PoolCoreWeld", h = 21, a = 21, b = 20, c0 = CFrame.new(0, 0.30375, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupRim7Weld", h = 25, a = 25, b = 24, c0 = CFrame.new(0, 0, -0.749287, -1, 0, 0, 0, 0.660628, -0.750714, 0, -0.750714, -0.660628), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe4Weld", h = 26, a = 26, b = 28, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle4", h = 27, a = 27, b = 26, c0 = CFrame.new(-0.016081, 0.116881, -1.050069, -0.4809, 0.064976, 0.874364, 0.757065, -0.472248, 0.45148, 0.442252, 0.879068, 0.177913), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LeafBlade1Weld", h = 29, a = 29, b = 30, c0 = CFrame.new(0, 0.035818, -0.83498, 0, 0, -1, 0.995038, 0.099493, 0, 0.099493, -0.995038, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LeafPoint1Weld", h = 30, a = 30, b = 52, c0 = CFrame.new(0.000001, 0.765, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupRim6Weld", h = 32, a = 32, b = 31, c0 = CFrame.new(0, 0, -0.749287, -1, 0, 0, 0, 0.660628, -0.750713, 0, -0.750713, -0.660628), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee3", h = 33, a = 33, b = 35, c0 = CFrame.new(0, -0.823825, -0.952374, 1, 0, 0, 0, 0.143992, 0.989579, 0, -0.989579, 0.143992), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "EyeShineLWeld", h = 34, a = 34, b = 61, c0 = CFrame.new(0.072, 0.036, -0.045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle3", h = 35, a = 35, b = 41, c0 = CFrame.new(0.016081, 0.116881, -1.050069, -0.4809, -0.064976, -0.874364, -0.757065, -0.472248, 0.45148, -0.442252, 0.879068, 0.177913), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee1", h = 38, a = 38, b = 40, c0 = CFrame.new(0, -0.823825, -0.952374, 1, 0, 0, 0, 0.143992, 0.989579, 0, -0.989579, 0.143992), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe1Weld", h = 39, a = 39, b = 59, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle1", h = 40, a = 40, b = 39, c0 = CFrame.new(-0.016081, 0.116881, -1.050069, 0.4809, 0.064976, -0.874364, -0.757065, -0.472248, -0.45148, -0.442252, 0.879068, -0.177913), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe3Weld", h = 41, a = 41, b = 60, c0 = CFrame.new(0, 0.27, -0.1575, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "EyeShineRWeld", h = 48, a = 48, b = 68, c0 = CFrame.new(-0.072, 0.036, -0.045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupRim5Weld", h = 55, a = 55, b = 62, c0 = CFrame.new(0, 0, -0.749287, -1, 0, 0, 0, 0.660628, -0.750714, 0, -0.750714, -0.660628), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupRim8Weld", h = 57, a = 57, b = 58, c0 = CFrame.new(0, 0, -0.749287, -1, 0, 0, 0, 0.660628, -0.750714, 0, -0.750713, -0.660628), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CupRim4Weld", h = 66, a = 66, b = 65, c0 = CFrame.new(0, 0, -0.749287, -1, 0, 0, 0, 0.660628, -0.750714, 0, -0.750713, -0.660628), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
