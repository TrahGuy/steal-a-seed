--!strict
--==============================================================================
-- RAIN EVENT 2 FORM: the Big pod (tier 2), 2026-10-05
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/Pod (big)" by a read-only generator on
-- 2026-10-05. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-05-rain-event-2-originals.
--
-- ONE OF SEVEN. The owner supplied a pod for each size, already at that size,
-- and this is the Big one: it is replayed at exactly the size supplied and
-- NEVER multiplied by the tier ladder (SeedData species PodForms says which
-- size uses which). It shows its size; nothing about it says which creature,
-- or which rarity, is inside.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the pod's BASE: its
-- root part's x/z at the lowest drawn point), colour, material, surface,
-- attribute and joint is the supplied number. See RainForms (the parent).
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "Rain Event 2/Pod (big)", Kind = "pod", Yaw = 0,
	Size = Vector3.new(5.560711, 7.551898, 5.560791), Height = 7.551898, PartCount = 38,
	Base = 0,
	Unit = 1, ModelScale = 1.230593,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(6.152964, 0.246119, 6.152964), cf = CFrame.new(0, -0.03019, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 70, 90), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "RootLeaf", s = "Block", z = Vector3.new(1.599771, 0.147671, 0.861415), cf = CFrame.new(-1.914366, 0.265152, 1.914398, -0.686103, 0.171065, -0.707107, 0.241922, 0.970296, 0, 0.686103, -0.171065, -0.707107), c = Color3.fromRGB(40, 116, 92), m = Enum.Material.Plastic }, -- 2
		{ n = "RootLeaf", s = "Block", z = Vector3.new(1.599771, 0.147671, 0.861415), cf = CFrame.new(-1.914366, 0.265152, -1.914398, -0.686103, 0.171065, 0.707107, 0.241922, 0.970296, 0, -0.686103, 0.171065, -0.707107), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 3
		{ n = "Pod", s = "Block", z = Vector3.new(2.461185, 0.689132, 2.461185), cf = CFrame.new(0, 0.363597, 0, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c = Color3.fromRGB(30, 48, 92), m = Enum.Material.Plastic }, -- 4
		{ n = "Pod", s = "Block", z = Vector3.new(3.691778, 0.984474, 2.131449), cf = CFrame.new(0, 1.2004, 0, 0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, 0.866027), c = Color3.fromRGB(44, 82, 132), m = Enum.Material.Plastic }, -- 5
		{ n = "Pod", s = "Block", z = Vector3.new(3.691778, 0.984474, 2.131449), cf = CFrame.new(0, 1.2004, 0, 0, 0, 1.000002, 0, 1, 0, -1.000002, 0, 0), c = Color3.fromRGB(44, 82, 132), m = Enum.Material.Plastic }, -- 6
		{ n = "Pod", s = "Block", z = Vector3.new(3.691778, 0.984474, 2.131449), cf = CFrame.new(0, 1.2004, 0, -0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, -0.866027), c = Color3.fromRGB(44, 82, 132), m = Enum.Material.Plastic }, -- 7
		{ n = "Pod", s = "Block", z = Vector3.new(4.676252, 1.230593, 2.699835), cf = CFrame.new(0, 2.307934, 0, 0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, 0.866027), c = Color3.fromRGB(60, 108, 166), m = Enum.Material.Plastic }, -- 8
		{ n = "Pod", s = "Block", z = Vector3.new(4.676252, 1.230593, 2.699835), cf = CFrame.new(0, 2.307934, 0, 0, 0, 1.000002, 0, 1, 0, -1.000002, 0, 0), c = Color3.fromRGB(60, 108, 166), m = Enum.Material.Plastic }, -- 9
		{ n = "Pod", s = "Block", z = Vector3.new(4.676252, 1.230593, 2.699835), cf = CFrame.new(0, 2.307934, 0, -0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, -0.866027), c = Color3.fromRGB(60, 108, 166), m = Enum.Material.Plastic }, -- 10
		{ n = "Pod", s = "Block", z = Vector3.new(4.553193, 1.107533, 2.628787), cf = CFrame.new(0, 3.476997, 0, 0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, 0.866027), c = Color3.fromRGB(80, 132, 190), m = Enum.Material.Plastic }, -- 11
		{ n = "Pod", s = "Block", z = Vector3.new(4.553193, 1.107533, 2.628787), cf = CFrame.new(0, 3.476997, 0, 0, 0, 1.000002, 0, 1, 0, -1.000002, 0, 0), c = Color3.fromRGB(80, 132, 190), m = Enum.Material.Plastic }, -- 12
		{ n = "Pod", s = "Block", z = Vector3.new(4.553193, 1.107533, 2.628787), cf = CFrame.new(0, 3.476997, 0, -0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, -0.866027), c = Color3.fromRGB(80, 132, 190), m = Enum.Material.Plastic }, -- 13
		{ n = "Pod", s = "Block", z = Vector3.new(3.44566, 0.984474, 1.989353), cf = CFrame.new(0, 4.523001, 0, 0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, 0.866027), c = Color3.fromRGB(108, 164, 214), m = Enum.Material.Plastic }, -- 14
		{ n = "Pod", s = "Block", z = Vector3.new(3.44566, 0.984474, 1.989353), cf = CFrame.new(0, 4.523001, 0, 0, 0, 1.000002, 0, 1, 0, -1.000002, 0, 0), c = Color3.fromRGB(108, 164, 214), m = Enum.Material.Plastic }, -- 15
		{ n = "Pod", s = "Block", z = Vector3.new(3.44566, 0.984474, 1.989353), cf = CFrame.new(0, 4.523001, 0, -0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, -0.866027), c = Color3.fromRGB(108, 164, 214), m = Enum.Material.Plastic }, -- 16
		{ n = "Pod", s = "Block", z = Vector3.new(2.215067, 0.861415, 1.278869), cf = CFrame.new(0, 5.445945, 0, 0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, 0.866027), c = Color3.fromRGB(140, 196, 234), m = Enum.Material.Plastic }, -- 17
		{ n = "Pod", s = "Block", z = Vector3.new(2.215067, 0.861415, 1.278869), cf = CFrame.new(0, 5.445945, 0, 0, 0, 1.000002, 0, 1, 0, -1.000002, 0, 0), c = Color3.fromRGB(140, 196, 234), m = Enum.Material.Plastic }, -- 18
		{ n = "Pod", s = "Block", z = Vector3.new(2.215067, 0.861415, 1.278869), cf = CFrame.new(0, 5.445945, 0, -0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, -0.866027), c = Color3.fromRGB(140, 196, 234), m = Enum.Material.Plastic }, -- 19
		{ n = "Pod", s = "Block", z = Vector3.new(0.984474, 0.615296, 0.984474), cf = CFrame.new(0, 6.184301, 0, 0.707108, 0, 0.707108, 0, 1, 0, -0.707108, 0, 0.707108), c = Color3.fromRGB(182, 230, 250), m = Enum.Material.Plastic }, -- 20
		{ n = "Crack", s = "Block", z = Vector3.new(0.369178, 1.062269, 0.123059), cf = CFrame.new(-0.030766, 2.554052, -2.399658, -0.524098, -0.85166, 0, 0.851658, -0.524097, 0, 0, 0, 1.000002), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 21
		{ n = "Crack", s = "Block", z = Vector3.new(0.369178, 0.925307, 0.123059), cf = CFrame.new(-0.092295, 2.09258, -2.399658, -0.536876, 0.843663, 0, -0.843662, -0.536875, 0, 0, 0, 1.000002), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 22
		{ n = "Crack", s = "Block", z = Vector3.new(0.369178, 0.874124, 0.123059), cf = CFrame.new(0.12306, 3.692351, -2.338135, -0.573463, 0.819233, 0, -0.819232, -0.573462, 0, 0, 0, 1.000002), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 23
		{ n = "Crack", s = "Block", z = Vector3.new(0.369178, 0.824605, 0.123059), cf = CFrame.new(0.153824, 3.261643, -2.338135, -0.613942, -0.789353, 0, 0.789352, -0.613941, 0, 0, 0, 1.000002), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 24
		{ n = "Streak", s = "Block", z = Vector3.new(0.295342, 1.107533, 0.123059), cf = CFrame.new(-0.861416, 2.492523, 2.399658, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 25
		{ n = "Streak", s = "Block", z = Vector3.new(0.295342, 1.107533, 0.123059), cf = CFrame.new(0, 2.246404, 2.399658, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 26
		{ n = "Streak", s = "Block", z = Vector3.new(0.295342, 1.107533, 0.123059), cf = CFrame.new(0.861416, 2.492523, 2.399658, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 27
		{ n = "Drop", s = "Block", z = Vector3.new(0.762967, 0.762967, 0.123059), cf = CFrame.new(-2.078106, 2.307934, -1.199829, -0.353562, 0.353562, -0.86602, 0.707107, 0.707107, 0, 0.612369, -0.612369, -0.500012), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 28
		{ n = "Drop", s = "Block", z = Vector3.new(0.762967, 0.762967, 0.123059), cf = CFrame.new(2.078104, 2.307934, -1.199829, -0.353562, 0.353562, 0.86602, 0.707107, 0.707107, 0, -0.612369, 0.612369, -0.500012), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 29
		{ n = "Sepal", s = "Block", z = Vector3.new(0.738356, 1.398143, 0.172283), cf = CFrame.new(-1.199829, 5.753593, 0, 0.507021, -0.861936, 0, 0.861934, 0.50702, 0, 0, 0, 1.000002), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 30
		{ n = "Sepal", s = "Block", z = Vector3.new(0.738356, 1.398143, 0.172283), cf = CFrame.new(1.199831, 5.753593, 0, 0.507021, 0.861936, 0, -0.861934, 0.50702, 0, 0, 0, 1.000002), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 31
		{ n = "Sepal", s = "Block", z = Vector3.new(0.738356, 1.398143, 0.172283), cf = CFrame.new(0, 5.753593, -1.199829, 0, 0, 1.000002, -0.861934, 0.50702, 0, -0.507021, -0.861935, 0), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 32
		{ n = "Sepal", s = "Block", z = Vector3.new(0.738356, 1.398143, 0.172283), cf = CFrame.new(0, 5.753593, 1.199829, 0, 0, 1.000002, 0.861934, 0.50702, 0, -0.507021, 0.861936, 0), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 33
		{ n = "Sprout", s = "Block", z = Vector3.new(0.27073, 1.046004, 0.27073), cf = CFrame.new(0, 6.861127, 0, 1.000002, 0, 0, 0, 1, 0, 0, 0, 1.000002), c = Color3.fromRGB(40, 116, 92), m = Enum.Material.Plastic }, -- 34
		{ n = "SproutLeaf", s = "Block", z = Vector3.new(1.046004, 0.172283, 0.615296), cf = CFrame.new(-0.492237, 7.230305, 0, 0.882949, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1.000002), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 35
		{ n = "SproutLeaf", s = "Block", z = Vector3.new(1.046004, 0.172283, 0.615296), cf = CFrame.new(0.492237, 7.230305, 0, 0.882949, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1.000002), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 36
		{ n = "RootLeaf", s = "Block", z = Vector3.new(1.599771, 0.147671, 0.861415), cf = CFrame.new(1.914366, 0.265152, -1.914398, 0.686103, -0.171065, 0.707107, 0.241922, 0.970296, 0, -0.686103, 0.171065, 0.707107), c = Color3.fromRGB(40, 116, 92), m = Enum.Material.Plastic }, -- 37
		{ n = "RootLeaf", s = "Block", z = Vector3.new(1.599771, 0.147671, 0.861415), cf = CFrame.new(1.914366, 0.265152, 1.914398, 0.686103, -0.171065, -0.707107, 0.241922, 0.970296, 0, 0.686103, -0.171065, 0.707107), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 38
	},
	Joints = {
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 0.836803, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 6, c0 = CFrame.new(0, 0.836803, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 7, c0 = CFrame.new(0, 0.836803, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 8, c0 = CFrame.new(0, 1.944337, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 9, c0 = CFrame.new(0, 1.944337, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 10, c0 = CFrame.new(0, 1.944337, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 11, c0 = CFrame.new(0, 3.1134, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 12, c0 = CFrame.new(0, 3.1134, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 13, c0 = CFrame.new(0, 3.1134, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 14, c0 = CFrame.new(0, 4.159403, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 15, c0 = CFrame.new(0, 4.159403, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 16, c0 = CFrame.new(0, 4.159403, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 17, c0 = CFrame.new(0, 5.082348, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 18, c0 = CFrame.new(0, 5.082348, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 19, c0 = CFrame.new(0, 5.082348, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 20, c0 = CFrame.new(0, 5.820704, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 21, c0 = CFrame.new(-0.030765, 2.190455, -2.399656, -0.524097, -0.851658, 0, 0.851658, -0.524097, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 22, c0 = CFrame.new(-0.092294, 1.728983, -2.399656, -0.536875, 0.843662, 0, -0.843662, -0.536875, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 23, c0 = CFrame.new(0.123059, 3.328753, -2.338126, -0.573462, 0.819232, 0, -0.819232, -0.573462, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 24, c0 = CFrame.new(0.153824, 2.898046, -2.338126, -0.613941, -0.789352, 0, 0.789352, -0.613941, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 25, c0 = CFrame.new(-0.861415, 2.128925, 2.399656, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 26, c0 = CFrame.new(0, 1.882807, 2.399656, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 27, c0 = CFrame.new(0.861415, 2.128925, 2.399656, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 28, c0 = CFrame.new(-2.078102, 1.944337, -1.199828, -0.353561, 0.353561, -0.866019, 0.707107, 0.707107, 0, 0.612368, -0.612368, -0.500011), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 29, c0 = CFrame.new(2.078102, 1.944337, -1.199828, -0.353561, 0.353561, 0.866019, 0.707107, 0.707107, 0, -0.612368, 0.612368, -0.500011), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalR", h = 17, a = 17, b = 30, c0 = CFrame.new(-0.586149, 0, -0.338413, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.606777, 0, 0.50702, 0.861934, 0, -0.861934, 0.50702, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalL", h = 17, a = 17, b = 31, c0 = CFrame.new(0.586149, 0, 0.338413, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.606777, 0, 0.50702, -0.861934, 0, 0.861934, 0.50702, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalF", h = 17, a = 17, b = 32, c0 = CFrame.new(0.338413, 0, -0.586149, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.606777, 0, 0, -0.861934, -0.50702, 0, 0.50702, -0.861934, 1, 0, 0) },
		{ k = "Motor6D", n = "SepalB", h = 17, a = 17, b = 33, c0 = CFrame.new(-0.338413, 0, 0.586149, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.606777, 0, 0, 0.861934, -0.50702, 0, 0.50702, 0.861934, 1, 0, 0) },
		{ k = "Motor6D", n = "Sprout", h = 20, a = 20, b = 34, c0 = CFrame.new(0, 0.307648, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, -0.369178, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 35, c0 = CFrame.new(-0.492237, 0.369178, 0, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 36, c0 = CFrame.new(0.492237, 0.369178, 0, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "PodGlow", p = 8, range = 9, brightness = 0.7, color = Color3.new(0.55, 0.85, 1), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Drizzle", p = 34, rate = 5, enabled = true, lifetime = NumberRange.new(1.2, 1.8), speed = NumberRange.new(1.230593, 3.076482), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.27073, 0), NumberSequenceKeypoint.new(1, 0.073836, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.74902, 0.94902, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.7, 1)) }), lightEmission = 0.7, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(80, 80), acceleration = Vector3.new(0, -12.305927, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
