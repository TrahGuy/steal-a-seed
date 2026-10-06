--!strict
--==============================================================================
-- PLANT FORM: Suncrown (Dustbowl plants)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Dustbowl plants/Suncrown" by a read-only generator on 2026-10-03. The original
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
	Source = "Dustbowl plants/Suncrown", Kind = "plant", Yaw = 0,
	Size = Vector3.new(10.409291, 17.157019, 5.025585), Height = 17.157019, PartCount = 92,
	Base = 1,
	Unit = 4.5, ModelScale = 1.660051,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(0.896428, 0.896428, 0.896428), cf = CFrame.new(0, 0.000001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 29, 31), m = Enum.Material.Plastic, t = 1 }, -- 1
		{ n = "UpperStem", s = "Block", z = Vector3.new(1.494046, 2.988092, 1.643451), cf = CFrame.new(0, 9.599249, 0.112053, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(93, 68, 42), m = Enum.Material.Plastic }, -- 2
		{ n = "BarkUpper1", s = "Block", z = Vector3.new(0.298809, 2.166367, 0.194226), cf = CFrame.new(-0.532927, 9.599249, -0.64991, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(137, 104, 60), m = Enum.Material.Plastic }, -- 3
		{ n = "StemBody", s = "Block", z = Vector3.new(1.718153, 3.88452, 1.867558), cf = CFrame.new(0, 6.4244, 0.261459, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(93, 68, 42), m = Enum.Material.Plastic }, -- 4
		{ n = "RootUpper1", s = "Block", z = Vector3.new(0.821725, 0.821725, 2.988092), cf = CFrame.new(-1.982116, 4.166761, -1.18618, 0.478407, -0.558692, 0.677488, 0.1205, 0.805974, 0.579557, -0.869831, -0.195627, 0.452906), c = Color3.fromRGB(93, 68, 42), m = Enum.Material.Plastic }, -- 5
		{ n = "RootUpper3", s = "Block", z = Vector3.new(0.821725, 0.821725, 2.988092), cf = CFrame.new(-2.000837, 4.123338, 1.616959, -0.4819, -0.538743, 0.691035, -0.008842, 0.791599, 0.610978, -0.876182, 0.28832, -0.386235), c = Color3.fromRGB(93, 68, 42), m = Enum.Material.Plastic }, -- 6
		{ n = "FaceCore", s = "Block", z = Vector3.new(2.988092, 2.988092, 1.045832), cf = CFrame.new(0, 11.952372, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 29, 31), m = Enum.Material.Plastic }, -- 7
		{ n = "SunRay3", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(2.160696, 13.19985, 0.144459, 0.5, 0.861281, -0.090524, -0.866025, 0.497261, -0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 8
		{ n = "RayGlow3", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(2.183687, 13.213125, -0.108139, 0.5, 0.861282, -0.090524, -0.866025, 0.497261, -0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 9
		{ n = "SunRay6", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(1.247478, 9.791675, 0.144459, -0.866025, 0.497261, -0.052264, -0.5, -0.861281, 0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 10
		{ n = "RayGlow6", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(1.260753, 9.768682, -0.108139, -0.866025, 0.497261, -0.052264, -0.5, -0.861281, 0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 11
		{ n = "SunRay1", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(0, 14.447329, 0.144459, 1, 0, 0, 0, 0.994522, -0.104528, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 12
		{ n = "RootLower3", s = "Block", z = Vector3.new(0.747023, 0.747023, 2.988092), cf = CFrame.new(-2.336998, 2.0877, 1.822392, -0.4819, -0.753164, -0.447792, -0.008842, -0.50684, 0.861996, -0.876182, 0.419355, 0.237586), c = Color3.fromRGB(137, 104, 60), m = Enum.Material.Plastic }, -- 13
		{ n = "RootToe3", s = "Block", z = Vector3.new(0.298809, 0.186756, 1.195237), cf = CFrame.new(-1.718153, 0.933779, 1.23259, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 14
		{ n = "RootFoot3", s = "Block", z = Vector3.new(1.120535, 0.97113, 1.643451), cf = CFrame.new(-1.718153, 0.485565, 1.494049, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(93, 68, 42), m = Enum.Material.Plastic }, -- 15
		{ n = "SunRay2", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(1.247478, 14.113069, 0.144459, 0.866025, 0.497261, -0.052264, -0.5, 0.861281, -0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 16
		{ n = "RayGlow2", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(1.260753, 14.136061, -0.108139, 0.866025, 0.497261, -0.052264, -0.5, 0.861281, -0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 17
		{ n = "RootLower2", s = "Block", z = Vector3.new(0.747023, 0.747023, 2.988092), cf = CFrame.new(2.318275, 2.131123, -1.653069, 0.478407, 0.763255, 0.434245, -0.120499, -0.432769, 0.893416, 0.869831, -0.479743, -0.115068), c = Color3.fromRGB(137, 104, 60), m = Enum.Material.Plastic }, -- 18
		{ n = "RootUpper2", s = "Block", z = Vector3.new(0.821725, 0.821725, 2.988092), cf = CFrame.new(1.982115, 4.166761, -1.18618, 0.478407, 0.558692, -0.677488, -0.1205, 0.805974, 0.579557, 0.869831, -0.195627, 0.452906), c = Color3.fromRGB(93, 68, 42), m = Enum.Material.Plastic }, -- 19
		{ n = "RootLower1", s = "Block", z = Vector3.new(0.747023, 0.747023, 2.988092), cf = CFrame.new(-2.318276, 2.131123, -1.653069, 0.478407, -0.763255, -0.434245, 0.120499, -0.432769, 0.893416, -0.869831, -0.479743, -0.115068), c = Color3.fromRGB(137, 104, 60), m = Enum.Material.Plastic }, -- 20
		{ n = "RootToe1", s = "Block", z = Vector3.new(0.298809, 0.186756, 1.195237), cf = CFrame.new(-1.718153, 0.93378, -1.755505, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 21
		{ n = "RootFoot1", s = "Block", z = Vector3.new(1.120535, 0.97113, 1.643451), cf = CFrame.new(-1.718153, 0.485566, -1.494045, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(93, 68, 42), m = Enum.Material.Plastic }, -- 22
		{ n = "SunRay7", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(0, 9.457416, 0.144459, -1, 0, 0, 0, -0.994522, 0.104528, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 23
		{ n = "RayGlow7", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(0, 9.430867, -0.108139, -1, 0, 0, 0, -0.994522, 0.104528, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 24
		{ n = "SunRay9", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(-2.160696, 10.704894, 0.144459, -0.5, -0.861281, 0.090524, 0.866025, -0.497261, 0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 25
		{ n = "StemScar2", s = "Block", z = Vector3.new(0.687261, 0.164345, 0.104583), cf = CFrame.new(0, 6.499102, -0.664848, 0.956305, 0.292372, 0, -0.292372, 0.956305, 0, 0, 0, 1), c = Color3.fromRGB(42, 29, 31), m = Enum.Material.Plastic }, -- 26
		{ n = "RootUpper4", s = "Block", z = Vector3.new(0.821725, 0.821725, 2.988092), cf = CFrame.new(2.000837, 4.123338, 1.616959, -0.4819, 0.538743, -0.691035, 0.008842, 0.791599, 0.610978, 0.876182, 0.28832, -0.386235), c = Color3.fromRGB(93, 68, 42), m = Enum.Material.Plastic }, -- 27
		{ n = "RayGlow9", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(-2.183688, 10.691619, -0.108139, -0.5, -0.861281, 0.090524, 0.866025, -0.497261, 0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 28
		{ n = "InnerPetal1", s = "Block", z = Vector3.new(0.97113, 2.091665, 0.522916), cf = CFrame.new(0.477022, 13.732642, 0.158268, 0.965926, 0.253163, -0.053812, -0.258819, 0.944818, -0.200827, 0, 0.207912, 0.978148), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 29
		{ n = "RayPoint9", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(-3.833529, 9.739084, 0.347481, -0.5, -0.861281, 0.090524, 0.866025, -0.497261, 0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 30
		{ n = "BrowL", s = "Block", z = Vector3.new(0.97113, 0.186756, 0.246518), cf = CFrame.new(-0.6275, 12.908562, -0.545326, 0.990268, 0.139173, 0, -0.139173, 0.990268, 0, 0, 0, 1), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 31
		{ n = "InnerPoint5", s = "Wedge", z = Vector3.new(0.821725, 0.97113, 0.597618), cf = CFrame.new(-2.697812, 11.229496, 0.36018, -0.258819, -0.944818, 0.200827, 0.965926, -0.253163, 0.053812, 0, 0.207912, 0.978148), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 32
		{ n = "InnerPetal5", s = "Block", z = Vector3.new(0.97113, 2.091665, 0.522916), cf = CFrame.new(-1.780271, 11.475349, 0.158272, -0.258819, -0.944818, 0.200827, 0.965926, -0.253163, 0.053812, 0, 0.207912, 0.978148), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 33
		{ n = "Mouth", s = "Block", z = Vector3.new(0.507976, 0.089643, 0.104583), cf = CFrame.new(0, 11.317403, -0.537857, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(137, 104, 60), m = Enum.Material.Plastic }, -- 34
		{ n = "LeafPoint1", s = "Wedge", z = Vector3.new(0.784374, 1.045832, 0.672321), cf = CFrame.new(-3.759087, 8.729396, 0.149406, 0.642788, -0.766044, 0, 0.766044, 0.642788, 0, 0, 0, 1), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 35
		{ n = "LeafBlade1", s = "Block", z = Vector3.new(0.821725, 1.718153, 0.63497), cf = CFrame.new(-3.015158, 8.105165, 0.149406, 0.642788, -0.766044, 0, 0.766044, 0.642788, 0, 0, 0, 1), c = Color3.fromRGB(120, 112, 52), m = Enum.Material.Plastic }, -- 36
		{ n = "LeafBranch1", s = "Block", z = Vector3.new(0.522916, 0.522916, 2.166), cf = CFrame.new(-1.680801, 7.582286, 0.149406, 0, 0.196116, 0.980581, 0, 0.980581, -0.196116, -1, 0, 0), c = Color3.fromRGB(120, 112, 52), m = Enum.Material.Plastic }, -- 37
		{ n = "RootLower4", s = "Block", z = Vector3.new(0.747023, 0.747023, 2.988092), cf = CFrame.new(2.336998, 2.0877, 1.822392, -0.4819, 0.753164, 0.447792, 0.008842, -0.50684, 0.861996, 0.876182, 0.419355, 0.237586), c = Color3.fromRGB(137, 104, 60), m = Enum.Material.Plastic }, -- 38
		{ n = "RootFoot4", s = "Block", z = Vector3.new(1.120535, 0.97113, 1.643451), cf = CFrame.new(1.718153, 0.485565, 1.494049, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(93, 68, 42), m = Enum.Material.Plastic }, -- 39
		{ n = "SunRay5", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(2.160696, 10.704893, 0.144459, -0.5, 0.861281, -0.090524, -0.866025, -0.497261, 0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 40
		{ n = "InnerPetal2", s = "Block", z = Vector3.new(0.97113, 2.091665, 0.522916), cf = CFrame.new(1.78027, 12.429394, 0.158272, 0.258819, 0.944818, -0.200827, -0.965926, 0.253163, -0.053812, 0, 0.207912, 0.978148), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 41
		{ n = "InnerPoint2", s = "Wedge", z = Vector3.new(0.821725, 0.97113, 0.597618), cf = CFrame.new(2.697811, 12.675248, 0.36018, 0.258819, 0.944818, -0.200827, -0.965926, 0.253163, -0.053812, 0, 0.207912, 0.978148), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 42
		{ n = "SunRay11", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(-2.160696, 13.19985, 0.144459, 0.5, -0.861281, 0.090524, 0.866025, 0.497261, -0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 43
		{ n = "RayPoint11", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(-3.833528, 14.165661, 0.347481, 0.5, -0.861281, 0.090524, 0.866025, 0.497261, -0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 44
		{ n = "SunRay10", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(-2.494957, 11.952372, 0.144459, 0, -0.994522, 0.104528, 1, 0, 0, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 45
		{ n = "SunRay4", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(2.494957, 11.952372, 0.144459, 0, 0.994522, -0.104528, -1, 0, 0, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 46
		{ n = "InnerPetal4", s = "Block", z = Vector3.new(0.97113, 2.091665, 0.522916), cf = CFrame.new(-0.477022, 10.172102, 0.158268, -0.965926, -0.253163, 0.053812, 0.258819, -0.944818, 0.200827, 0, 0.207912, 0.978148), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 47
		{ n = "RayGlow12", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(-1.260754, 14.136061, -0.108139, 0.866025, -0.497261, 0.052264, 0.5, 0.861281, -0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 48
		{ n = "SunRay12", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(-1.247479, 14.113069, 0.144459, 0.866025, -0.497261, 0.052264, 0.5, 0.861281, -0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 49
		{ n = "CheekL", s = "Block", z = Vector3.new(0.597618, 2.166367, 0.97113), cf = CFrame.new(-1.419344, 11.728265, -0.112053, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 50
		{ n = "RootToe4", s = "Block", z = Vector3.new(0.298809, 0.186756, 1.195237), cf = CFrame.new(1.718153, 0.933779, 1.23259, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 51
		{ n = "GoldenCollar", s = "Block", z = Vector3.new(1.94226, 0.672321, 1.867558), cf = CFrame.new(0, 10.757135, 0.03735, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 52
		{ n = "RootToe2", s = "Block", z = Vector3.new(0.298809, 0.186756, 1.195237), cf = CFrame.new(1.718152, 0.93378, -1.755505, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 53
		{ n = "RootFoot2", s = "Block", z = Vector3.new(1.120535, 0.97113, 1.643451), cf = CFrame.new(1.718152, 0.485566, -1.494045, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(93, 68, 42), m = Enum.Material.Plastic }, -- 54
		{ n = "InnerPetal6", s = "Block", z = Vector3.new(0.97113, 2.091665, 0.522916), cf = CFrame.new(-1.303249, 13.255621, 0.158268, 0.707107, -0.691655, 0.147016, 0.707107, 0.691655, -0.147016, 0, 0.207912, 0.978148), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 55
		{ n = "InnerPoint1", s = "Wedge", z = Vector3.new(0.821725, 0.97113, 0.597618), cf = CFrame.new(0.722877, 14.650184, 0.360176, 0.965926, 0.253163, -0.053812, -0.258819, 0.944818, -0.200827, 0, 0.207912, 0.978148), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 56
		{ n = "InnerPetal3", s = "Block", z = Vector3.new(0.97113, 2.091665, 0.522916), cf = CFrame.new(1.303248, 10.649124, 0.158272, -0.707107, 0.691655, -0.147016, -0.707107, -0.691655, 0.147016, 0, 0.207912, 0.978148), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 57
		{ n = "InnerPoint3", s = "Wedge", z = Vector3.new(0.821725, 0.97113, 0.597618), cf = CFrame.new(1.974936, 9.977437, 0.36018, -0.707107, 0.691655, -0.147016, -0.707107, -0.691655, 0.147016, 0, 0.207912, 0.978148), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 58
		{ n = "CheekR", s = "Block", z = Vector3.new(0.597618, 2.166367, 0.97113), cf = CFrame.new(1.419344, 11.728265, -0.112053, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 59
		{ n = "LeafBranch2", s = "Block", z = Vector3.new(0.522916, 0.522916, 2.166), cf = CFrame.new(1.680801, 7.582286, 0.149406, 0, -0.196116, -0.980581, 0, 0.980581, -0.196116, 1, 0, 0), c = Color3.fromRGB(120, 112, 52), m = Enum.Material.Plastic }, -- 60
		{ n = "LeafPoint2", s = "Wedge", z = Vector3.new(0.784374, 1.045832, 0.672321), cf = CFrame.new(3.759087, 8.729396, 0.149406, 0.642788, 0.766044, 0, -0.766044, 0.642788, 0, 0, 0, 1), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 61
		{ n = "LeafBlade2", s = "Block", z = Vector3.new(0.821725, 1.718153, 0.63497), cf = CFrame.new(3.015158, 8.105165, 0.149406, 0.642788, 0.766044, 0, -0.766044, 0.642788, 0, 0, 0, 1), c = Color3.fromRGB(120, 112, 52), m = Enum.Material.Plastic }, -- 62
		{ n = "RayGlow4", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(2.521505, 11.952372, -0.108139, 0, 0.994522, -0.104528, -1, 0, 0, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 63
		{ n = "RayPoint10", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(-4.426577, 11.952372, 0.347481, 0, -0.994522, 0.104528, 1, 0, 0, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 64
		{ n = "BarkLower1", s = "Block", z = Vector3.new(0.343631, 2.988092, 0.224107), cf = CFrame.new(-0.64991, 6.349698, -0.634968, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(137, 104, 60), m = Enum.Material.Plastic }, -- 65
		{ n = "RayPoint3", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(3.833529, 14.16566, 0.347481, 0.5, 0.861282, -0.090524, -0.866025, 0.497261, -0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 66
		{ n = "LeafVein1", s = "Block", z = Vector3.new(0.126994, 1.269939, 0.104583), cf = CFrame.new(-3.015158, 8.105165, -0.13446, 0.642788, -0.766044, 0, 0.766044, 0.642788, 0, 0, 0, 1), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 67
		{ n = "RayPoint2", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(2.213289, 15.7859, 0.347481, 0.866025, 0.497261, -0.052264, -0.5, 0.861281, -0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 68
		{ n = "RayPoint5", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(3.833529, 9.739083, 0.347481, -0.5, 0.861281, -0.090524, -0.866025, -0.497261, 0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 69
		{ n = "LeafVein2", s = "Block", z = Vector3.new(0.126994, 1.269939, 0.104583), cf = CFrame.new(3.015158, 8.105165, -0.13446, 0.642788, 0.766044, 0, -0.766044, 0.642788, 0, 0, 0, 1), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 70
		{ n = "SunRay8", s = "Block", z = Vector3.new(1.195237, 3.436306, 0.597618), cf = CFrame.new(-1.247478, 9.791676, 0.144459, -0.866025, -0.497261, 0.052264, 0.5, -0.861281, 0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 71
		{ n = "RayPoint8", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(-2.213288, 8.118844, 0.347481, -0.866025, -0.497261, 0.052264, 0.5, -0.861281, 0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 72
		{ n = "EyeL", s = "Block", z = Vector3.new(0.418333, 0.201696, 0.164345), cf = CFrame.new(-0.620029, 12.475287, -0.552795, 0.990268, 0.139173, 0, -0.139173, 0.990268, 0, 0, 0, 1), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 73
		{ n = "Nose", s = "Wedge", z = Vector3.new(0.283869, 0.522916, 0.224107), cf = CFrame.new(0, 11.802967, -0.567738, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 74
		{ n = "RayPoint6", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(2.213289, 8.118843, 0.347481, -0.866025, 0.497261, -0.052264, -0.5, -0.861281, 0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 75
		{ n = "InnerPoint6", s = "Wedge", z = Vector3.new(0.821725, 0.97113, 0.597618), cf = CFrame.new(-1.974936, 13.927307, 0.360176, 0.707107, -0.691655, 0.147016, 0.707107, 0.691655, -0.147016, 0, 0.207912, 0.978148), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 76
		{ n = "RayGlow8", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(-1.260753, 9.768683, -0.108139, -0.866025, -0.497261, 0.052264, 0.5, -0.861281, 0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 77
		{ n = "StemScar1", s = "Block", z = Vector3.new(0.687261, 0.164345, 0.104583), cf = CFrame.new(0, 5.938835, -0.664848, 0.956305, 0.292372, 0, -0.292372, 0.956305, 0, 0, 0, 1), c = Color3.fromRGB(42, 29, 31), m = Enum.Material.Plastic }, -- 78
		{ n = "RayGlow1", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(0, 14.473878, -0.108139, 1, 0, 0, 0, 0.994522, -0.104528, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 79
		{ n = "BarkUpper2", s = "Block", z = Vector3.new(0.298809, 2.166367, 0.194226), cf = CFrame.new(0.532927, 9.599249, -0.64991, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(137, 104, 60), m = Enum.Material.Plastic }, -- 80
		{ n = "EyeR", s = "Block", z = Vector3.new(0.418333, 0.201696, 0.164345), cf = CFrame.new(0.620029, 12.475287, -0.552795, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 81
		{ n = "RayGlow10", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(-2.521506, 11.952372, -0.108139, 0, -0.994522, 0.104528, 1, 0, 0, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 82
		{ n = "StemScar3", s = "Block", z = Vector3.new(0.687261, 0.164345, 0.104583), cf = CFrame.new(0, 7.05937, -0.664848, 0.956305, 0.292372, 0, -0.292372, 0.956305, 0, 0, 0, 1), c = Color3.fromRGB(42, 29, 31), m = Enum.Material.Plastic }, -- 83
		{ n = "RayPoint4", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(4.426577, 11.952372, 0.347481, 0, 0.994522, -0.104528, -1, 0, 0, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 84
		{ n = "BarkLower2", s = "Block", z = Vector3.new(0.343631, 2.988092, 0.224107), cf = CFrame.new(0.64991, 6.349698, -0.634968, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(137, 104, 60), m = Enum.Material.Plastic }, -- 85
		{ n = "RayPoint12", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(-2.21329, 15.785902, 0.347481, 0.866025, -0.497261, 0.052264, 0.5, 0.861281, -0.090524, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 86
		{ n = "RayPoint1", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(0, 16.37895, 0.347481, 1, 0, 0, 0, 0.994522, -0.104528, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 87
		{ n = "RayPoint7", s = "Wedge", z = Vector3.new(0.97113, 1.494046, 0.672321), cf = CFrame.new(0, 7.525795, 0.347481, -1, 0, 0, 0, -0.994522, 0.104528, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 88
		{ n = "BrowR", s = "Block", z = Vector3.new(0.97113, 0.186756, 0.246518), cf = CFrame.new(0.6275, 12.908562, -0.545326, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c = Color3.fromRGB(255, 216, 104), m = Enum.Material.Plastic }, -- 89
		{ n = "InnerPoint4", s = "Wedge", z = Vector3.new(0.821725, 0.97113, 0.597618), cf = CFrame.new(-0.722877, 9.25456, 0.360176, -0.965926, -0.253163, 0.053812, 0.258819, -0.944818, 0.200827, 0, 0.207912, 0.978148), c = Color3.fromRGB(218, 155, 43), m = Enum.Material.Plastic }, -- 90
		{ n = "RayGlow5", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(2.183687, 10.69162, -0.108139, -0.5, 0.861281, -0.090524, -0.866025, -0.497261, 0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 91
		{ n = "RayGlow11", s = "Block", z = Vector3.new(0.097113, 2.390474, 0.112053), cf = CFrame.new(-2.183688, 13.213125, -0.108139, 0.5, -0.861281, 0.090524, 0.866025, 0.497261, -0.052264, 0, 0.104528, 0.994522), c = Color3.fromRGB(255, 179, 47), m = Enum.Material.Neon, st = false, cs = false }, -- 92
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 6.424398, 0.261458, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BarkUpper1Weld", h = 2, a = 2, b = 3, c0 = CFrame.new(-0.532926, 0, -0.761964, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Blossom", h = 2, a = 2, b = 7, c0 = CFrame.new(0, 1.083184, -0.112053, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.269939, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GoldenCollarWeld", h = 2, a = 2, b = 52, c0 = CFrame.new(0, 1.157886, -0.074702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BarkUpper2Weld", h = 2, a = 2, b = 80, c0 = CFrame.new(0.532926, 0, -0.761964, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Stem", h = 4, a = 4, b = 2, c0 = CFrame.new(0, 1.792855, -0.074702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.381993, 0.074702, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip1", h = 4, a = 4, b = 5, c0 = CFrame.new(-1.982115, -2.257639, -1.447638, 0.478407, -0.558692, 0.677488, 0.1205, 0.805973, 0.579557, -0.869831, -0.195627, 0.452906), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip3", h = 4, a = 4, b = 6, c0 = CFrame.new(-2.000837, -2.301062, 1.355499, -0.4819, -0.538743, 0.691035, -0.008842, 0.791598, 0.610978, -0.876182, 0.28832, -0.386235), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip2", h = 4, a = 4, b = 19, c0 = CFrame.new(1.982115, -2.257639, -1.447638, 0.478407, 0.558692, -0.677488, -0.1205, 0.805973, 0.579557, 0.869831, -0.195627, 0.452906), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StemScar2Weld", h = 4, a = 4, b = 26, c0 = CFrame.new(0, 0.074702, -0.926309, 0.956305, 0.292372, 0, -0.292372, 0.956305, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip4", h = 4, a = 4, b = 27, c0 = CFrame.new(2.000837, -2.301062, 1.355499, -0.4819, 0.538743, -0.691035, 0.008842, 0.791598, 0.610978, 0.876182, 0.28832, -0.386235), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LeafJoint1", h = 4, a = 4, b = 37, c0 = CFrame.new(-0.747023, 0.97113, -0.112053, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.000002, 0.952271, 0, 0, -1, 0.196116, 0.980581, 0, 0.980581, -0.196116, 0) },
		{ k = "Motor6D", n = "LeafJoint2", h = 4, a = 4, b = 60, c0 = CFrame.new(0.747023, 0.97113, -0.112053, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.000002, 0.952271, 0, 0, 1, -0.196116, 0.980581, 0, -0.980581, -0.196116, 0) },
		{ k = "Weld", n = "BarkLower1Weld", h = 4, a = 4, b = 65, c0 = CFrame.new(-0.64991, -0.074702, -0.896428, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StemScar1Weld", h = 4, a = 4, b = 78, c0 = CFrame.new(0, -0.485565, -0.926309, 0.956305, 0.292372, 0, -0.292372, 0.956305, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StemScar3Weld", h = 4, a = 4, b = 83, c0 = CFrame.new(0, 0.63497, -0.926309, 0.956305, 0.292372, 0, -0.292372, 0.956305, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BarkLower2Weld", h = 4, a = 4, b = 85, c0 = CFrame.new(0.64991, -0.074702, -0.896428, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee1", h = 5, a = 5, b = 20, c0 = CFrame.new(0, -1.361523, -1.61897, 1, 0, 0, 0, 0.171475, 0.985189, 0, -0.985188, 0.171475), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee3", h = 6, a = 6, b = 13, c0 = CFrame.new(0, -1.371074, -1.555373, 1, 0, 0, 0, 0.125456, 0.992099, 0, -0.992099, 0.125456), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint3", h = 7, a = 7, b = 8, c0 = CFrame.new(0.970411, 0.560268, 0, 0.5, 0.861281, -0.090524, -0.866025, 0.497261, -0.052264, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381994, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint6", h = 7, a = 7, b = 10, c0 = CFrame.new(0.560267, -0.970411, 0, -0.866025, 0.497261, -0.052264, -0.5, -0.861281, 0.090524, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381994, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint1", h = 7, a = 7, b = 12, c0 = CFrame.new(0, 1.120535, 0, 1, 0, 0, 0, 0.994522, -0.104528, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381993, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint2", h = 7, a = 7, b = 16, c0 = CFrame.new(0.560267, 0.970412, 0, 0.866025, 0.497261, -0.052264, -0.5, 0.861281, -0.090524, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381994, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint7", h = 7, a = 7, b = 23, c0 = CFrame.new(0, -1.120534, 0, -1, 0, 0, 0, -0.994522, 0.104528, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381993, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint9", h = 7, a = 7, b = 25, c0 = CFrame.new(-0.970411, -0.560267, 0, -0.5, -0.861281, 0.090524, 0.866025, -0.497261, 0.052264, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381993, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalJoint1", h = 7, a = 7, b = 29, c0 = CFrame.new(0.193344, 0.721569, -0.074702, 0.965926, 0.253163, -0.053812, -0.258819, 0.944818, -0.200827, 0, 0.207912, 0.978148), c1 = CFrame.new(0, -1.120535, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowLWeld", h = 7, a = 7, b = 31, c0 = CFrame.new(-0.627499, 0.95619, -0.545327, 0.990268, 0.139173, 0, -0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalJoint5", h = 7, a = 7, b = 33, c0 = CFrame.new(-0.721569, -0.193344, -0.074702, -0.258819, -0.944818, 0.200827, 0.965926, -0.253163, 0.053811, 0, 0.207912, 0.978148), c1 = CFrame.new(0.000001, -1.120535, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MouthWeld", h = 7, a = 7, b = 34, c0 = CFrame.new(0, -0.634969, -0.537857, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint5", h = 7, a = 7, b = 40, c0 = CFrame.new(0.970411, -0.560267, 0, -0.5, 0.861281, -0.090524, -0.866025, -0.497261, 0.052264, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381994, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalJoint2", h = 7, a = 7, b = 41, c0 = CFrame.new(0.721569, 0.193344, -0.074702, 0.258819, 0.944818, -0.200827, -0.965926, 0.253163, -0.053812, 0, 0.207912, 0.978148), c1 = CFrame.new(0, -1.120535, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint11", h = 7, a = 7, b = 43, c0 = CFrame.new(-0.970411, 0.560268, 0, 0.5, -0.861281, 0.090524, 0.866025, 0.497261, -0.052264, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381993, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint10", h = 7, a = 7, b = 45, c0 = CFrame.new(-1.120535, 0, 0, 0, -0.994522, 0.104528, 1, 0, 0, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381993, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint4", h = 7, a = 7, b = 46, c0 = CFrame.new(1.120535, 0, 0, 0, 0.994522, -0.104528, -1, 0, 0, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381993, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalJoint4", h = 7, a = 7, b = 47, c0 = CFrame.new(-0.193344, -0.721569, -0.074702, -0.965926, -0.253163, 0.053812, 0.258819, -0.944818, 0.200827, 0, 0.207912, 0.978148), c1 = CFrame.new(0, -1.120534, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint12", h = 7, a = 7, b = 49, c0 = CFrame.new(-0.560267, 0.970412, 0, 0.866025, -0.497261, 0.052264, 0.5, 0.861281, -0.090524, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381994, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CheekLWeld", h = 7, a = 7, b = 50, c0 = CFrame.new(-1.419344, -0.224107, -0.112053, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalJoint6", h = 7, a = 7, b = 55, c0 = CFrame.new(-0.528225, 0.528225, -0.074702, 0.707107, -0.691655, 0.147016, 0.707107, 0.691655, -0.147016, 0, 0.207912, 0.978148), c1 = CFrame.new(0, -1.120535, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalJoint3", h = 7, a = 7, b = 57, c0 = CFrame.new(0.528225, -0.528225, -0.074702, -0.707107, 0.691655, -0.147016, -0.707107, -0.691655, 0.147016, 0, 0.207912, 0.978148), c1 = CFrame.new(0, -1.120535, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CheekRWeld", h = 7, a = 7, b = 59, c0 = CFrame.new(1.419344, -0.224107, -0.112053, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "RayJoint8", h = 7, a = 7, b = 71, c0 = CFrame.new(-0.560267, -0.970411, 0, -0.866025, -0.497261, 0.052264, 0.5, -0.861281, 0.090524, 0, 0.104528, 0.994522), c1 = CFrame.new(0, -1.381994, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "EyeLWeld", h = 7, a = 7, b = 73, c0 = CFrame.new(-0.620029, 0.522916, -0.552797, 0.990268, 0.139173, 0, -0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "NoseWeld", h = 7, a = 7, b = 74, c0 = CFrame.new(0, -0.149404, -0.567738, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "EyeRWeld", h = 7, a = 7, b = 81, c0 = CFrame.new(0.620029, 0.522916, -0.552797, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowRWeld", h = 7, a = 7, b = 89, c0 = CFrame.new(0.627499, 0.95619, -0.545327, 0.990268, -0.139173, 0, 0.139173, 0.990268, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow3Weld", h = 8, a = 8, b = 9, c0 = CFrame.new(-0.000001, -0.000001, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint3Weld", h = 8, a = 8, b = 66, c0 = CFrame.new(0, 1.94226, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow6Weld", h = 10, a = 10, b = 11, c0 = CFrame.new(0, 0, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint6Weld", h = 10, a = 10, b = 75, c0 = CFrame.new(0, 1.94226, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow1Weld", h = 12, a = 12, b = 79, c0 = CFrame.new(0, 0, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint1Weld", h = 12, a = 12, b = 87, c0 = CFrame.new(0, 1.942262, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle3", h = 13, a = 13, b = 15, c0 = CFrame.new(0.003633, 0.208241, -1.736155, -0.4819, -0.008842, -0.876182, -0.753164, -0.506839, 0.419355, -0.447791, 0.861995, 0.237586), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe3Weld", h = 15, a = 15, b = 14, c0 = CFrame.new(0, 0.448214, -0.261458, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow2Weld", h = 16, a = 16, b = 17, c0 = CFrame.new(0, 0, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint2Weld", h = 16, a = 16, b = 68, c0 = CFrame.new(0, 1.94226, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle2", h = 18, a = 18, b = 54, c0 = CFrame.new(0.049509, 0.177808, -1.749064, 0.478407, -0.120499, 0.869831, 0.763255, -0.432769, -0.479743, 0.434244, 0.893416, -0.115068), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee2", h = 19, a = 19, b = 18, c0 = CFrame.new(0, -1.361523, -1.61897, 1, 0, 0, 0, 0.171475, 0.985189, 0, -0.985188, 0.171475), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle1", h = 20, a = 20, b = 22, c0 = CFrame.new(-0.049509, 0.177808, -1.749064, 0.478407, 0.120499, -0.869831, -0.763255, -0.432769, -0.479743, -0.434244, 0.893416, -0.115068), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe1Weld", h = 22, a = 22, b = 21, c0 = CFrame.new(0, 0.448214, -0.261458, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow7Weld", h = 23, a = 23, b = 24, c0 = CFrame.new(0, -0.000001, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint7Weld", h = 23, a = 23, b = 88, c0 = CFrame.new(0, 1.942259, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow9Weld", h = 25, a = 25, b = 28, c0 = CFrame.new(-0.000001, 0, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint9Weld", h = 25, a = 25, b = 30, c0 = CFrame.new(0, 1.94226, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee4", h = 27, a = 27, b = 38, c0 = CFrame.new(0, -1.371074, -1.555373, 1, 0, 0, 0, 0.125456, 0.992099, 0, -0.992099, 0.125456), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerPoint1Weld", h = 29, a = 29, b = 56, c0 = CFrame.new(0, 0.971131, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerPoint5Weld", h = 33, a = 33, b = 32, c0 = CFrame.new(0.000001, 0.97113, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LeafPoint1Weld", h = 36, a = 36, b = 35, c0 = CFrame.new(0, 0.97113, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LeafVein1Weld", h = 36, a = 36, b = 67, c0 = CFrame.new(0, 0, -0.283869, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LeafBlade1Weld", h = 37, a = 37, b = 36, c0 = CFrame.new(0, 0.251037, -1.410988, 0, 0, -1, 0.877229, 0.480072, 0, 0.480072, -0.877229, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle4", h = 38, a = 38, b = 39, c0 = CFrame.new(-0.003633, 0.208241, -1.736155, -0.4819, 0.008842, 0.876182, 0.753164, -0.506839, 0.419355, 0.447791, 0.861995, 0.237586), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe4Weld", h = 39, a = 39, b = 51, c0 = CFrame.new(0, 0.448214, -0.261458, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint5Weld", h = 40, a = 40, b = 69, c0 = CFrame.new(0, 1.94226, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow5Weld", h = 40, a = 40, b = 91, c0 = CFrame.new(-0.000001, 0, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerPoint2Weld", h = 41, a = 41, b = 42, c0 = CFrame.new(0, 0.97113, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint11Weld", h = 43, a = 43, b = 44, c0 = CFrame.new(0.000001, 1.94226, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow11Weld", h = 43, a = 43, b = 92, c0 = CFrame.new(0.000001, 0, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint10Weld", h = 45, a = 45, b = 64, c0 = CFrame.new(0, 1.94226, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow10Weld", h = 45, a = 45, b = 82, c0 = CFrame.new(0, 0, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow4Weld", h = 46, a = 46, b = 63, c0 = CFrame.new(0, 0, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint4Weld", h = 46, a = 46, b = 84, c0 = CFrame.new(0, 1.94226, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerPoint4Weld", h = 47, a = 47, b = 90, c0 = CFrame.new(0, 0.97113, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow12Weld", h = 49, a = 49, b = 48, c0 = CFrame.new(0, 0, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint12Weld", h = 49, a = 49, b = 86, c0 = CFrame.new(0, 1.942261, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe2Weld", h = 54, a = 54, b = 53, c0 = CFrame.new(0, 0.448214, -0.261458, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerPoint6Weld", h = 55, a = 55, b = 76, c0 = CFrame.new(0, 0.971129, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerPoint3Weld", h = 57, a = 57, b = 58, c0 = CFrame.new(0.000001, 0.97113, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LeafBlade2Weld", h = 60, a = 60, b = 62, c0 = CFrame.new(0, 0.251037, -1.410988, 0, 0, 1, -0.877229, 0.480072, 0, -0.480072, -0.877229, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LeafPoint2Weld", h = 62, a = 62, b = 61, c0 = CFrame.new(0, 0.97113, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LeafVein2Weld", h = 62, a = 62, b = 70, c0 = CFrame.new(0, 0, -0.283869, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayPoint8Weld", h = 71, a = 71, b = 72, c0 = CFrame.new(0, 1.942259, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RayGlow8Weld", h = 71, a = 71, b = 77, c0 = CFrame.new(0, 0, -0.253988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
