--!strict
--==============================================================================
-- PLANT FORM: Pyrelotus (Emberroot)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Emberroot/Pyrelotus" by a read-only generator on 2026-10-03. The original
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
	Source = "Emberroot/Pyrelotus", Kind = "plant", Yaw = 0,
	Size = Vector3.new(10.714979, 15.319989, 10.960577), Height = 15.319989, PartCount = 82,
	Base = 4,
	Unit = 4.5, ModelScale = 1.795035,
	Attributes = {},
	Parts = {
		{ n = "RootUpper2", s = "Block", z = Vector3.new(0.888542, 0.888542, 3.231062), cf = CFrame.new(2.143288, 4.505571, -1.282631, 0.478407, 0.558692, -0.677488, -0.1205, 0.805974, 0.579557, 0.869831, -0.195627, 0.452906), c = Color3.fromRGB(43, 38, 36), m = Enum.Material.Plastic }, -- 1
		{ n = "StemBody", s = "Block", z = Vector3.new(1.938637, 4.200381, 1.938637), cf = CFrame.new(0, 6.946785, 0.282719, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(43, 38, 36), m = Enum.Material.Plastic }, -- 2
		{ n = "RootLower2", s = "Block", z = Vector3.new(0.807766, 0.807766, 3.231062), cf = CFrame.new(2.506783, 2.30441, -1.787485, 0.478407, 0.763255, 0.434245, -0.120499, -0.432769, 0.893416, 0.869831, -0.479743, -0.115068), c = Color3.fromRGB(76, 51, 41), m = Enum.Material.Plastic }, -- 3
		{ n = "Footing", s = "Block", z = Vector3.new(0.969319, 0.969319, 0.969319), cf = CFrame.new(0, 0.000001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 24, 27), m = Enum.Material.Plastic, t = 1 }, -- 4
		{ n = "BlossomHub", s = "Block", z = Vector3.new(2.180967, 2.423297, 2.180967), cf = CFrame.new(0, 12.197262, 0.000002, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 24, 27), m = Enum.Material.Plastic }, -- 5
		{ n = "OuterTip2", s = "Wedge", z = Vector3.new(2.423297, 1.938637, 1.090484), cf = CFrame.new(3.004189, 12.953578, 3.004189, 0.707107, 0.640856, 0.298836, 0, 0.422618, -0.906308, -0.707107, 0.640856, 0.298836), c = Color3.fromRGB(213, 137, 79), m = Enum.Material.Plastic }, -- 6
		{ n = "OuterPetal2", s = "Block", z = Vector3.new(2.665627, 3.554169, 0.969319), cf = CFrame.new(1.502968, 11.963586, 1.50297, 0.707107, 0.640856, 0.298836, 0, 0.422618, -0.906308, -0.707107, 0.640856, 0.298836), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 7
		{ n = "UpperStem", s = "Block", z = Vector3.new(1.373201, 2.665627, 1.534755), cf = CFrame.new(0, 10.177848, 0.121166, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 24, 27), m = Enum.Material.Plastic }, -- 8
		{ n = "BarkRidge2", s = "Block", z = Vector3.new(0.27464, 3.150285, 0.258485), cf = CFrame.new(0.484661, 6.866009, 1.171261, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(76, 51, 41), m = Enum.Material.Plastic }, -- 9
		{ n = "InnerPetal4", s = "Block", z = Vector3.new(1.898249, 2.746403, 0.807766), cf = CFrame.new(-0.952522, 10.994747, -1.649815, -0.866025, -0.485148, 0.120961, 0, -0.241922, -0.970296, 0.5, -0.840301, 0.20951), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 10
		{ n = "InnerGlow4", s = "Block", z = Vector3.new(1.373201, 2.10019, 0.161553), cf = CFrame.new(-0.907578, 10.634212, -1.571966, -0.866025, -0.485148, 0.120961, 0, -0.241922, -0.970296, 0.5, -0.840301, 0.20951), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 11
		{ n = "RootUpper3", s = "Block", z = Vector3.new(0.888542, 0.888542, 3.231062), cf = CFrame.new(-2.16353, 4.458618, 1.748438, -0.4819, -0.538743, 0.691035, -0.008842, 0.791599, 0.610978, -0.876182, 0.28832, -0.386235), c = Color3.fromRGB(43, 38, 36), m = Enum.Material.Plastic }, -- 12
		{ n = "RootFoot3", s = "Block", z = Vector3.new(1.211648, 1.050095, 1.777084), cf = CFrame.new(-1.857861, 0.525048, 1.615532, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(43, 38, 36), m = Enum.Material.Plastic }, -- 13
		{ n = "RootLower3", s = "Block", z = Vector3.new(0.807766, 0.807766, 3.231062), cf = CFrame.new(-2.527025, 2.257457, 1.970573, -0.4819, -0.753164, -0.447792, -0.008842, -0.50684, 0.861996, -0.876182, 0.419355, 0.237586), c = Color3.fromRGB(76, 51, 41), m = Enum.Material.Plastic }, -- 14
		{ n = "InnerPetal2", s = "Block", z = Vector3.new(1.898249, 2.746403, 0.807766), cf = CFrame.new(1.231396, 12.599576, 0.000002, 0, 0.374607, 0.927184, 0, 0.927184, -0.374607, -1, 0, 0), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 15
		{ n = "InnerTip2", s = "Wedge", z = Vector3.new(1.696308, 1.615531, 0.92893), cf = CFrame.new(1.957623, 14.39705, 0.000002, 0, 0.374607, 0.927184, 0, 0.927184, -0.374607, -1, 0, 0), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 16
		{ n = "OuterPetal4", s = "Block", z = Vector3.new(2.665627, 3.554169, 0.969319), cf = CFrame.new(1.589287, 10.9852, -1.589287, -0.707107, 0.700225, -0.09841, 0, -0.139173, -0.990268, -0.707107, -0.700225, 0.09841), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 17
		{ n = "OuterVein4", s = "Block", z = Vector3.new(0.121165, 2.423297, 0.121165), cf = CFrame.new(1.634598, 11.441144, -1.634598, -0.707107, 0.700225, -0.09841, 0, -0.139173, -0.990268, -0.707107, -0.700225, 0.09841), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 18
		{ n = "OuterPetal3", s = "Block", z = Vector3.new(2.665627, 3.554169, 0.969319), cf = CFrame.new(2.125515, 11.963587, 0.000002, 0, 0.906308, 0.422618, 0, 0.422618, -0.906308, -1, 0, 0), c = Color3.fromRGB(148, 77, 48), m = Enum.Material.Plastic }, -- 19
		{ n = "OuterGlow3", s = "Block", z = Vector3.new(2.10019, 2.746403, 0.210019), cf = CFrame.new(2.320099, 11.546298, 0.000002, 0, 0.906308, 0.422618, 0, 0.422618, -0.906308, -1, 0, 0), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 20
		{ n = "OuterTip1", s = "Wedge", z = Vector3.new(2.423297, 1.938637, 1.090484), cf = CFrame.new(0, 12.953578, 4.248564, 1, 0, 0, 0, 0.422618, -0.906308, 0, 0.906308, 0.422618), c = Color3.fromRGB(213, 137, 79), m = Enum.Material.Plastic }, -- 21
		{ n = "OuterPetal1", s = "Block", z = Vector3.new(2.665627, 3.554169, 0.969319), cf = CFrame.new(0, 11.963587, 2.125519, 1, 0, 0, 0, 0.422618, -0.906308, 0, 0.906308, 0.422618), c = Color3.fromRGB(148, 77, 48), m = Enum.Material.Plastic }, -- 22
		{ n = "OuterPetal8", s = "Block", z = Vector3.new(2.665627, 3.554169, 0.969319), cf = CFrame.new(-1.502968, 11.963586, 1.50297, 0.707107, -0.640857, -0.298836, 0, 0.422618, -0.906308, 0.707107, 0.640856, 0.298836), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 23
		{ n = "OuterVein8", s = "Block", z = Vector3.new(0.121165, 2.423297, 0.121165), cf = CFrame.new(-1.365376, 12.380874, 1.365377, 0.707107, -0.640857, -0.298836, 0, 0.422618, -0.906308, 0.707107, 0.640856, 0.298836), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 24
		{ n = "InnerPetal5", s = "Block", z = Vector3.new(1.898249, 2.746403, 0.807766), cf = CFrame.new(-1.231398, 12.599576, 0.000002, 0, -0.374607, -0.927184, 0, 0.927184, -0.374607, 1, 0, 0), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 25
		{ n = "RootFoot2", s = "Block", z = Vector3.new(1.211648, 1.050095, 1.777084), cf = CFrame.new(1.857861, 0.525048, -1.615532, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(43, 38, 36), m = Enum.Material.Plastic }, -- 26
		{ n = "FaceCore", s = "Block", z = Vector3.new(1.777084, 2.180967, 0.726989), cf = CFrame.new(0, 12.116485, -1.187414, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 24, 27), m = Enum.Material.Plastic }, -- 27
		{ n = "Iris", s = "Block", z = Vector3.new(0.096932, 0.27464, 0.210019), cf = CFrame.new(0, 12.197262, -1.736694, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 24, 27), m = Enum.Material.Plastic, st = false, sf = { "Smooth", "Studs", "Studs", "Studs", "Smooth", "Studs" } }, -- 28
		{ n = "EyeLens", s = "Block", z = Vector3.new(1.009707, 0.218097, 0.177708), cf = CFrame.new(0, 12.197262, -1.607452, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 193, 95), m = Enum.Material.Neon, st = false, cs = false }, -- 29
		{ n = "OuterTip8", s = "Wedge", z = Vector3.new(2.423297, 1.938637, 1.090484), cf = CFrame.new(-3.004187, 12.953577, 3.004189, 0.707107, -0.640857, -0.298836, 0, 0.422618, -0.906308, 0.707107, 0.640856, 0.298836), c = Color3.fromRGB(213, 137, 79), m = Enum.Material.Plastic }, -- 30
		{ n = "InnerPetal1", s = "Block", z = Vector3.new(1.898249, 2.746403, 0.807766), cf = CFrame.new(0.6157, 12.599575, 1.066423, 0.866025, 0.187303, 0.463592, 0, 0.927184, -0.374607, -0.5, 0.324419, 0.802965), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 31
		{ n = "OuterTip4", s = "Wedge", z = Vector3.new(2.423297, 1.938637, 1.090484), cf = CFrame.new(3.22958, 10.659184, -3.229578, -0.707107, 0.700225, -0.09841, 0, -0.139173, -0.990268, -0.707107, -0.700225, 0.09841), c = Color3.fromRGB(213, 137, 79), m = Enum.Material.Plastic }, -- 32
		{ n = "OuterVein3", s = "Block", z = Vector3.new(0.121165, 2.423297, 0.121165), cf = CFrame.new(1.930931, 12.380875, 0.000002, 0, 0.906308, 0.422618, 0, 0.422618, -0.906308, -1, 0, 0), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 33
		{ n = "OuterTip6", s = "Wedge", z = Vector3.new(2.423297, 1.938637, 1.090484), cf = CFrame.new(-3.22958, 10.659184, -3.229578, -0.707107, -0.700225, 0.09841, 0, -0.139173, -0.990268, 0.707107, -0.700225, 0.09841), c = Color3.fromRGB(213, 137, 79), m = Enum.Material.Plastic }, -- 34
		{ n = "OuterPetal6", s = "Block", z = Vector3.new(2.665627, 3.554169, 0.969319), cf = CFrame.new(-1.589289, 10.9852, -1.589287, -0.707107, -0.700225, 0.09841, 0, -0.139173, -0.990268, 0.707107, -0.700225, 0.09841), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 35
		{ n = "OuterVein1", s = "Block", z = Vector3.new(0.121165, 2.423297, 0.121165), cf = CFrame.new(0, 12.380875, 1.930935, 1, 0, 0, 0, 0.422618, -0.906308, 0, 0.906308, 0.422618), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 36
		{ n = "InnerPetal6", s = "Block", z = Vector3.new(1.898249, 2.746403, 0.807766), cf = CFrame.new(-0.6157, 12.599575, 1.066423, 0.866025, -0.187303, -0.463592, 0, 0.927184, -0.374607, 0.5, 0.324419, 0.802965), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 37
		{ n = "InnerGlow6", s = "Block", z = Vector3.new(1.373201, 2.10019, 0.161553), cf = CFrame.new(-0.787958, 12.460381, 1.364782, 0.866025, -0.187303, -0.463592, 0, 0.927184, -0.374607, 0.5, 0.324419, 0.802965), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 38
		{ n = "RootUpper1", s = "Block", z = Vector3.new(0.888542, 0.888542, 3.231062), cf = CFrame.new(-2.143286, 4.505571, -1.282631, 0.478407, -0.558692, 0.677488, 0.1205, 0.805974, 0.579557, -0.869831, -0.195627, 0.452906), c = Color3.fromRGB(43, 38, 36), m = Enum.Material.Plastic }, -- 39
		{ n = "OuterPetal7", s = "Block", z = Vector3.new(2.665627, 3.554169, 0.969319), cf = CFrame.new(-2.125517, 11.963587, 0.000002, 0, -0.906308, -0.422618, 0, 0.422618, -0.906308, 1, 0, 0), c = Color3.fromRGB(148, 77, 48), m = Enum.Material.Plastic }, -- 40
		{ n = "InnerGlow1", s = "Block", z = Vector3.new(1.373201, 2.10019, 0.161553), cf = CFrame.new(0.787956, 12.460381, 1.364782, 0.866025, 0.187303, 0.463592, 0, 0.927184, -0.374607, -0.5, 0.324419, 0.802965), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 41
		{ n = "EmberBud", s = "Wedge", z = Vector3.new(0.646212, 0.807766, 0.686601), cf = CFrame.new(0, 13.71586, 0.282721, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 42
		{ n = "OuterGlow8", s = "Block", z = Vector3.new(2.10019, 2.746403, 0.210019), cf = CFrame.new(-1.64056, 11.546297, 1.640562, 0.707107, -0.640857, -0.298836, 0, 0.422618, -0.906308, 0.707107, 0.640856, 0.298836), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 43
		{ n = "InnerTip3", s = "Wedge", z = Vector3.new(1.696308, 1.615531, 0.92893), cf = CFrame.new(1.893047, 10.525749, -3.278854, -0.866025, 0.485148, -0.120961, 0, -0.241922, -0.970296, -0.5, -0.840301, 0.209511), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 44
		{ n = "InnerPetal3", s = "Block", z = Vector3.new(1.898249, 2.746403, 0.807766), cf = CFrame.new(0.952522, 10.994747, -1.649817, -0.866025, 0.485148, -0.120961, 0, -0.241922, -0.970296, -0.5, -0.840301, 0.209511), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 45
		{ n = "RootToe2", s = "Block", z = Vector3.new(0.323106, 0.201941, 1.292425), cf = CFrame.new(1.857861, 1.009708, -1.898251, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 46
		{ n = "InnerGlow3", s = "Block", z = Vector3.new(1.373201, 2.10019, 0.161553), cf = CFrame.new(0.907578, 10.634212, -1.571968, -0.866025, 0.485148, -0.120961, 0, -0.241922, -0.970296, -0.5, -0.840301, 0.209511), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 47
		{ n = "RootLower1", s = "Block", z = Vector3.new(0.807766, 0.807766, 3.231062), cf = CFrame.new(-2.506781, 2.30441, -1.787485, 0.478407, -0.763255, -0.434245, 0.120499, -0.432769, 0.893416, -0.869831, -0.479743, -0.115068), c = Color3.fromRGB(76, 51, 41), m = Enum.Material.Plastic }, -- 48
		{ n = "CopperCollar", s = "Block", z = Vector3.new(1.938637, 0.403883, 2.019414), cf = CFrame.new(0, 11.389496, 0.080778, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(148, 77, 48), m = Enum.Material.Plastic }, -- 49
		{ n = "OuterVein6", s = "Block", z = Vector3.new(0.121165, 2.423297, 0.121165), cf = CFrame.new(-1.6346, 11.441144, -1.634598, -0.707107, -0.700225, 0.09841, 0, -0.139173, -0.990268, 0.707107, -0.700225, 0.09841), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 50
		{ n = "OuterGlow4", s = "Block", z = Vector3.new(2.10019, 2.746403, 0.210019), cf = CFrame.new(1.543976, 10.529253, -1.543976, -0.707107, 0.700225, -0.09841, 0, -0.139173, -0.990268, -0.707107, -0.700225, 0.09841), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 51
		{ n = "RootFoot1", s = "Block", z = Vector3.new(1.211648, 1.050095, 1.777084), cf = CFrame.new(-1.857861, 0.525048, -1.615532, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(43, 38, 36), m = Enum.Material.Plastic }, -- 52
		{ n = "BrowL", s = "Block", z = Vector3.new(0.710834, 0.24233, 0.201941), cf = CFrame.new(-0.363495, 12.5446, -1.534754, 0.970296, 0.241922, 0, -0.241922, 0.970296, 0, 0, 0, 1), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 53
		{ n = "OuterGlow7", s = "Block", z = Vector3.new(2.10019, 2.746403, 0.210019), cf = CFrame.new(-2.320101, 11.546298, 0.000002, 0, -0.906308, -0.422618, 0, 0.422618, -0.906308, 1, 0, 0), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 54
		{ n = "RootUpper4", s = "Block", z = Vector3.new(0.888542, 0.888542, 3.231062), cf = CFrame.new(2.163532, 4.458618, 1.748438, -0.4819, 0.538743, -0.691035, 0.008842, 0.791599, 0.610978, 0.876182, 0.28832, -0.386235), c = Color3.fromRGB(43, 38, 36), m = Enum.Material.Plastic }, -- 55
		{ n = "RootFoot4", s = "Block", z = Vector3.new(1.211648, 1.050095, 1.777084), cf = CFrame.new(1.857861, 0.525048, 1.615532, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(43, 38, 36), m = Enum.Material.Plastic }, -- 56
		{ n = "RootLower4", s = "Block", z = Vector3.new(0.807766, 0.807766, 3.231062), cf = CFrame.new(2.527027, 2.257457, 1.970573, -0.4819, 0.753164, 0.447792, 0.008842, -0.50684, 0.861996, 0.876182, 0.419355, 0.237586), c = Color3.fromRGB(76, 51, 41), m = Enum.Material.Plastic }, -- 57
		{ n = "RootToe4", s = "Block", z = Vector3.new(0.323106, 0.201941, 1.292425), cf = CFrame.new(1.857861, 1.009708, 1.332813, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 58
		{ n = "OuterPetal5", s = "Block", z = Vector3.new(2.665627, 3.554169, 0.969319), cf = CFrame.new(0, 10.9852, -2.247591, -1, 0, 0, 0, -0.139173, -0.990268, 0, -0.990268, 0.139173), c = Color3.fromRGB(148, 77, 48), m = Enum.Material.Plastic }, -- 59
		{ n = "OuterVein5", s = "Block", z = Vector3.new(0.121165, 2.423297, 0.121165), cf = CFrame.new(0, 11.441145, -2.31167, -1, 0, 0, 0, -0.139173, -0.990268, 0, -0.990268, 0.139173), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 60
		{ n = "OuterTip3", s = "Wedge", z = Vector3.new(2.423297, 1.938637, 1.090484), cf = CFrame.new(4.248558, 12.953578, 0.000002, 0, 0.906308, 0.422618, 0, 0.422618, -0.906308, -1, 0, 0), c = Color3.fromRGB(213, 137, 79), m = Enum.Material.Plastic }, -- 61
		{ n = "StemSeam1", s = "Block", z = Vector3.new(0.096932, 2.907956, 0.096932), cf = CFrame.new(0, 6.785233, -0.662367, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 62
		{ n = "OuterGlow2", s = "Block", z = Vector3.new(2.10019, 2.746403, 0.210019), cf = CFrame.new(1.64056, 11.546298, 1.640562, 0.707107, 0.640856, 0.298836, 0, 0.422618, -0.906308, -0.707107, 0.640856, 0.298836), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 63
		{ n = "RootToe1", s = "Block", z = Vector3.new(0.323106, 0.201941, 1.292425), cf = CFrame.new(-1.857861, 1.009708, -1.898251, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 64
		{ n = "MaskKeel", s = "Wedge", z = Vector3.new(0.565436, 0.848154, 0.298873), cf = CFrame.new(0, 11.349108, -1.429745, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(148, 77, 48), m = Enum.Material.Plastic }, -- 65
		{ n = "OuterVein7", s = "Block", z = Vector3.new(0.121165, 2.423297, 0.121165), cf = CFrame.new(-1.930933, 12.380875, 0.000002, 0, -0.906308, -0.422618, 0, 0.422618, -0.906308, 1, 0, 0), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 66
		{ n = "OuterTip5", s = "Wedge", z = Vector3.new(2.423297, 1.938637, 1.090484), cf = CFrame.new(0, 10.659184, -4.567314, -1, 0, 0, 0, -0.139173, -0.990268, 0, -0.990268, 0.139173), c = Color3.fromRGB(213, 137, 79), m = Enum.Material.Plastic }, -- 67
		{ n = "InnerTip4", s = "Wedge", z = Vector3.new(1.696308, 1.615531, 0.92893), cf = CFrame.new(-1.893047, 10.525749, -3.278854, -0.866025, -0.485148, 0.120961, 0, -0.241922, -0.970296, 0.5, -0.840301, 0.20951), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 68
		{ n = "OuterVein2", s = "Block", z = Vector3.new(0.121165, 2.423297, 0.121165), cf = CFrame.new(1.365376, 12.380874, 1.365377, 0.707107, 0.640856, 0.298836, 0, 0.422618, -0.906308, -0.707107, 0.640856, 0.298836), c = Color3.fromRGB(75, 44, 37), m = Enum.Material.Plastic }, -- 69
		{ n = "BrowR", s = "Block", z = Vector3.new(0.710834, 0.24233, 0.201941), cf = CFrame.new(0.363495, 12.5446, -1.534754, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 70
		{ n = "InnerGlow2", s = "Block", z = Vector3.new(1.373201, 2.10019, 0.161553), cf = CFrame.new(1.575912, 12.460382, 0.000002, 0, 0.374607, 0.927184, 0, 0.927184, -0.374607, -1, 0, 0), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 71
		{ n = "StemSeam2", s = "Block", z = Vector3.new(0.096932, 1.938637, 0.096932), cf = CFrame.new(0, 10.177848, -0.630056, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 72
		{ n = "InnerTip1", s = "Wedge", z = Vector3.new(1.696308, 1.615531, 0.92893), cf = CFrame.new(0.978813, 14.397049, 1.695354, 0.866025, 0.187303, 0.463592, 0, 0.927184, -0.374607, -0.5, 0.324419, 0.802965), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 73
		{ n = "BarkRidge1", s = "Block", z = Vector3.new(0.27464, 3.150285, 0.258485), cf = CFrame.new(-0.484661, 6.866009, 1.171261, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(76, 51, 41), m = Enum.Material.Plastic }, -- 74
		{ n = "InnerTip6", s = "Wedge", z = Vector3.new(1.696308, 1.615531, 0.92893), cf = CFrame.new(-0.978813, 14.397049, 1.695354, 0.866025, -0.187303, -0.463592, 0, 0.927184, -0.374607, 0.5, 0.324419, 0.802965), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 75
		{ n = "OuterGlow5", s = "Block", z = Vector3.new(2.10019, 2.746403, 0.210019), cf = CFrame.new(0, 10.529254, -2.183512, -1, 0, 0, 0, -0.139173, -0.990268, 0, -0.990268, 0.139173), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 76
		{ n = "OuterGlow1", s = "Block", z = Vector3.new(2.10019, 2.746403, 0.210019), cf = CFrame.new(0, 11.546298, 2.320103, 1, 0, 0, 0, 0.422618, -0.906308, 0, 0.906308, 0.422618), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 77
		{ n = "OuterTip7", s = "Wedge", z = Vector3.new(2.423297, 1.938637, 1.090484), cf = CFrame.new(-4.248562, 12.953578, 0.000002, 0, -0.906308, -0.422618, 0, 0.422618, -0.906308, 1, 0, 0), c = Color3.fromRGB(213, 137, 79), m = Enum.Material.Plastic }, -- 78
		{ n = "OuterGlow6", s = "Block", z = Vector3.new(2.10019, 2.746403, 0.210019), cf = CFrame.new(-1.543978, 10.529253, -1.543976, -0.707107, -0.700225, 0.09841, 0, -0.139173, -0.990268, 0.707107, -0.700225, 0.09841), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 79
		{ n = "InnerTip5", s = "Wedge", z = Vector3.new(1.696308, 1.615531, 0.92893), cf = CFrame.new(-1.957624, 14.39705, 0.000002, 0, -0.374607, -0.927184, 0, 0.927184, -0.374607, 1, 0, 0), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 80
		{ n = "InnerGlow5", s = "Block", z = Vector3.new(1.373201, 2.10019, 0.161553), cf = CFrame.new(-1.575912, 12.460382, 0.000002, 0, -0.374607, -0.927184, 0, 0.927184, -0.374607, 1, 0, 0), c = Color3.fromRGB(255, 111, 28), m = Enum.Material.Neon, st = false, cs = false }, -- 81
		{ n = "RootToe3", s = "Block", z = Vector3.new(0.323106, 0.201941, 1.292425), cf = CFrame.new(-1.857861, 1.009708, 1.332813, 1.000001, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(176, 100, 57), m = Enum.Material.Plastic }, -- 82
	},
	Joints = {
		{ k = "Motor6D", n = "Knee2", h = 1, a = 1, b = 3, c0 = CFrame.new(0, -1.472232, -1.750613, 1, 0, 0, 0, 0.171475, 0.985189, 0, -0.985188, 0.171475), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip2", h = 2, a = 2, b = 1, c0 = CFrame.new(2.143286, -2.441214, -1.565349, 0.478407, 0.558692, -0.677488, -0.1205, 0.805973, 0.579557, 0.869831, -0.195627, 0.452906), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Stem", h = 2, a = 2, b = 8, c0 = CFrame.new(0, 1.938637, -0.080777, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.292425, 0.080777, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BarkRidge2Weld", h = 2, a = 2, b = 9, c0 = CFrame.new(0.484659, -0.080776, 0.888542, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip3", h = 2, a = 2, b = 12, c0 = CFrame.new(-2.163531, -2.488167, 1.465719, -0.4819, -0.538743, 0.691035, -0.008842, 0.791598, 0.610978, -0.876182, 0.28832, -0.386235), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip1", h = 2, a = 2, b = 39, c0 = CFrame.new(-2.143286, -2.441214, -1.565349, 0.478407, -0.558692, 0.677488, 0.1205, 0.805973, 0.579557, -0.869831, -0.195627, 0.452906), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Hip4", h = 2, a = 2, b = 55, c0 = CFrame.new(2.163531, -2.488167, 1.465719, -0.4819, 0.538743, -0.691035, 0.008842, 0.791598, 0.610978, 0.876182, 0.28832, -0.386235), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StemSeam1Weld", h = 2, a = 2, b = 62, c0 = CFrame.new(0, -0.161553, -0.945086, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BarkRidge1Weld", h = 2, a = 2, b = 74, c0 = CFrame.new(-0.484659, -0.080776, 0.888542, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle2", h = 3, a = 3, b = 26, c0 = CFrame.new(0.053534, 0.192266, -1.891285, 0.478407, -0.120499, 0.869831, 0.763255, -0.432769, -0.479743, 0.434244, 0.893416, -0.115068), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 4, a = 4, b = 2, c0 = CFrame.new(0, 6.946784, 0.282718, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint2", h = 5, a = 5, b = 7, c0 = CFrame.new(0.571177, -0.848154, 0.571177, 0.707107, 0.640856, 0.298836, 0, 0.422618, -0.906308, -0.707107, 0.640856, 0.298836), c1 = CFrame.new(0, -1.453978, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint4", h = 5, a = 5, b = 10, c0 = CFrame.new(-0.403883, -0.92893, -0.699546, -0.866025, -0.485148, 0.120961, 0, -0.241922, -0.970296, 0.5, -0.840301, 0.20951), c1 = CFrame.new(0, -1.130872, -0.000002, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint2", h = 5, a = 5, b = 15, c0 = CFrame.new(0.807766, -0.646213, 0, 0, 0.374607, 0.927184, 0, 0.927184, -0.374607, -1, 0, 0), c1 = CFrame.new(0, -1.130872, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint4", h = 5, a = 5, b = 17, c0 = CFrame.new(0.571177, -1.009707, -0.571177, -0.707107, 0.700225, -0.09841, 0, -0.139173, -0.990268, -0.707107, -0.700225, 0.09841), c1 = CFrame.new(0, -1.453978, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint3", h = 5, a = 5, b = 19, c0 = CFrame.new(0.807766, -0.848154, 0, 0, 0.906308, 0.422618, 0, 0.422618, -0.906308, -1, 0, 0), c1 = CFrame.new(0, -1.453978, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint1", h = 5, a = 5, b = 22, c0 = CFrame.new(0, -0.848154, 0.807766, 1, 0, 0, 0, 0.422618, -0.906308, 0, 0.906308, 0.422618), c1 = CFrame.new(0, -1.453978, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint8", h = 5, a = 5, b = 23, c0 = CFrame.new(-0.571177, -0.848154, 0.571177, 0.707107, -0.640857, -0.298836, 0, 0.422618, -0.906308, 0.707107, 0.640856, 0.298836), c1 = CFrame.new(0, -1.453978, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint5", h = 5, a = 5, b = 25, c0 = CFrame.new(-0.807766, -0.646213, 0, 0, -0.374607, -0.927184, 0, 0.927184, -0.374607, 1, 0, 0), c1 = CFrame.new(0, -1.130872, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FaceCoreWeld", h = 5, a = 5, b = 27, c0 = CFrame.new(0, -0.080777, -1.187415, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint1", h = 5, a = 5, b = 31, c0 = CFrame.new(0.403883, -0.646213, 0.699546, 0.866025, 0.187303, 0.463592, 0, 0.927184, -0.374607, -0.5, 0.324419, 0.802965), c1 = CFrame.new(0, -1.130872, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint6", h = 5, a = 5, b = 35, c0 = CFrame.new(-0.571177, -1.009707, -0.571177, -0.707107, -0.700225, 0.09841, 0, -0.139173, -0.990268, 0.707107, -0.700225, 0.09841), c1 = CFrame.new(0, -1.453978, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint6", h = 5, a = 5, b = 37, c0 = CFrame.new(-0.403883, -0.646213, 0.699546, 0.866025, -0.187303, -0.463592, 0, 0.927184, -0.374607, 0.5, 0.324419, 0.802965), c1 = CFrame.new(0, -1.130872, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint7", h = 5, a = 5, b = 40, c0 = CFrame.new(-0.807766, -0.848154, 0, 0, -0.906308, -0.422618, 0, 0.422618, -0.906308, 1, 0, 0), c1 = CFrame.new(0, -1.453978, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "EmberBudWeld", h = 5, a = 5, b = 42, c0 = CFrame.new(0, 1.518599, 0.282718, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "InnerJoint3", h = 5, a = 5, b = 45, c0 = CFrame.new(0.403883, -0.92893, -0.699546, -0.866025, 0.485148, -0.120961, 0, -0.241922, -0.970296, -0.5, -0.840301, 0.20951), c1 = CFrame.new(0, -1.130872, -0.000002, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "OuterJoint5", h = 5, a = 5, b = 59, c0 = CFrame.new(0, -1.009707, -0.807766, -1, 0, 0, 0, -0.139173, -0.990268, 0, -0.990268, 0.139173), c1 = CFrame.new(0, -1.453978, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip2Weld", h = 7, a = 7, b = 6, c0 = CFrame.new(0, 2.34252, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow2Weld", h = 7, a = 7, b = 63, c0 = CFrame.new(0, 0.000001, 0.460427, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterVein2Weld", h = 7, a = 7, b = 69, c0 = CFrame.new(0, 0, -0.460426, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Blossom", h = 8, a = 8, b = 5, c0 = CFrame.new(0, 1.009707, -0.121165, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.009707, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CopperCollarWeld", h = 8, a = 8, b = 49, c0 = CFrame.new(0, 1.211648, -0.040388, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StemSeam2Weld", h = 8, a = 8, b = 72, c0 = CFrame.new(0, 0, -0.751222, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow4Weld", h = 10, a = 10, b = 11, c0 = CFrame.new(0, 0, 0.371572, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip4Weld", h = 10, a = 10, b = 68, c0 = CFrame.new(0, 1.938637, -0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee3", h = 12, a = 12, b = 14, c0 = CFrame.new(0, -1.482559, -1.681844, 1, 0, 0, 0, 0.125456, 0.992099, 0, -0.992099, 0.125456), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe3Weld", h = 13, a = 13, b = 82, c0 = CFrame.new(0, 0.484659, -0.282718, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle3", h = 14, a = 14, b = 13, c0 = CFrame.new(0.003928, 0.225174, -1.877326, -0.4819, -0.008842, -0.876182, -0.753164, -0.506839, 0.419355, -0.447791, 0.861995, 0.237586), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip2Weld", h = 15, a = 15, b = 16, c0 = CFrame.new(0, 1.938638, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow2Weld", h = 15, a = 15, b = 71, c0 = CFrame.new(0, -0.000001, 0.371572, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterVein4Weld", h = 17, a = 17, b = 18, c0 = CFrame.new(0, 0, -0.460425, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip4Weld", h = 17, a = 17, b = 32, c0 = CFrame.new(0, 2.34252, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow4Weld", h = 17, a = 17, b = 51, c0 = CFrame.new(0, 0, 0.460428, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow3Weld", h = 19, a = 19, b = 20, c0 = CFrame.new(0, 0, 0.460427, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterVein3Weld", h = 19, a = 19, b = 33, c0 = CFrame.new(0, 0, -0.460426, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip3Weld", h = 19, a = 19, b = 61, c0 = CFrame.new(0, 2.34252, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip1Weld", h = 22, a = 22, b = 21, c0 = CFrame.new(0, 2.34252, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterVein1Weld", h = 22, a = 22, b = 36, c0 = CFrame.new(0, 0, -0.460426, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow1Weld", h = 22, a = 22, b = 77, c0 = CFrame.new(0, 0, 0.460427, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterVein8Weld", h = 23, a = 23, b = 24, c0 = CFrame.new(0, 0, -0.460426, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip8Weld", h = 23, a = 23, b = 30, c0 = CFrame.new(0, 2.34252, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow8Weld", h = 23, a = 23, b = 43, c0 = CFrame.new(0, 0, 0.460427, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip5Weld", h = 25, a = 25, b = 80, c0 = CFrame.new(0, 1.938638, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow5Weld", h = 25, a = 25, b = 81, c0 = CFrame.new(0, -0.000001, 0.371572, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe2Weld", h = 26, a = 26, b = 46, c0 = CFrame.new(0, 0.484659, -0.282718, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "EyeLensWeld", h = 27, a = 27, b = 29, c0 = CFrame.new(0, 0.080777, -0.420038, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowLWeld", h = 27, a = 27, b = 53, c0 = CFrame.new(-0.363495, 0.428116, -0.347339, 0.970296, 0.241922, 0, -0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MaskKeelWeld", h = 27, a = 27, b = 65, c0 = CFrame.new(0, -0.767377, -0.24233, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowRWeld", h = 27, a = 27, b = 70, c0 = CFrame.new(0.363495, 0.428116, -0.347339, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "IrisWeld", h = 29, a = 29, b = 28, c0 = CFrame.new(0, 0, -0.129242, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow1Weld", h = 31, a = 31, b = 41, c0 = CFrame.new(0, -0.000001, 0.371572, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip1Weld", h = 31, a = 31, b = 73, c0 = CFrame.new(0, 1.938638, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip6Weld", h = 35, a = 35, b = 34, c0 = CFrame.new(0, 2.34252, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterVein6Weld", h = 35, a = 35, b = 50, c0 = CFrame.new(0, 0, -0.460425, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow6Weld", h = 35, a = 35, b = 79, c0 = CFrame.new(0, 0, 0.460428, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow6Weld", h = 37, a = 37, b = 38, c0 = CFrame.new(0, -0.000001, 0.371572, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip6Weld", h = 37, a = 37, b = 75, c0 = CFrame.new(0, 1.938638, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee1", h = 39, a = 39, b = 48, c0 = CFrame.new(0, -1.472232, -1.750613, 1, 0, 0, 0, 0.171475, 0.985189, 0, -0.985188, 0.171475), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow7Weld", h = 40, a = 40, b = 54, c0 = CFrame.new(0, 0, 0.460427, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterVein7Weld", h = 40, a = 40, b = 66, c0 = CFrame.new(0, 0, -0.460426, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip7Weld", h = 40, a = 40, b = 78, c0 = CFrame.new(0, 2.34252, 0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerTip3Weld", h = 45, a = 45, b = 44, c0 = CFrame.new(0, 1.938637, -0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "InnerGlow3Weld", h = 45, a = 45, b = 47, c0 = CFrame.new(0, 0, 0.371572, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle1", h = 48, a = 48, b = 52, c0 = CFrame.new(-0.053534, 0.192266, -1.891285, 0.478407, 0.120499, -0.869831, -0.763255, -0.432769, -0.479743, -0.434244, 0.893416, -0.115068), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe1Weld", h = 52, a = 52, b = 64, c0 = CFrame.new(0, 0.484659, -0.282718, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Knee4", h = 55, a = 55, b = 57, c0 = CFrame.new(0, -1.482559, -1.681844, 1, 0, 0, 0, 0.125456, 0.992099, 0, -0.992099, 0.125456), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RootToe4Weld", h = 56, a = 56, b = 58, c0 = CFrame.new(0, 0.484659, -0.282718, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Ankle4", h = 57, a = 57, b = 56, c0 = CFrame.new(-0.003928, 0.225174, -1.877326, -0.4819, 0.008842, 0.876182, 0.753164, -0.506839, 0.419355, 0.447791, 0.861995, 0.237586), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterVein5Weld", h = 59, a = 59, b = 60, c0 = CFrame.new(0, 0, -0.460426, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterTip5Weld", h = 59, a = 59, b = 67, c0 = CFrame.new(0, 2.34252, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "OuterGlow5Weld", h = 59, a = 59, b = 76, c0 = CFrame.new(0, 0, 0.460427, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
