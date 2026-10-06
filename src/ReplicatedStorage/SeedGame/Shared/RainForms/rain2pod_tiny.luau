--!strict
--==============================================================================
-- RAIN EVENT 2 FORM: the Tiny pod (tier 1), 2026-10-05
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/Pod (Tiny)" by a read-only generator on
-- 2026-10-05. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-05-rain-event-2-originals.
--
-- ONE OF SEVEN. The owner supplied a pod for each size, already at that size,
-- and this is the Tiny one: it is replayed at exactly the size supplied and
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
	Source = "Rain Event 2/Pod (Tiny)", Kind = "pod", Yaw = 0,
	Size = Vector3.new(1.945732, 2.642461, 1.94574), Height = 2.642461, PartCount = 38,
	Base = 0,
	Unit = 1, ModelScale = 0.430593,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(2.152964, 0.086119, 2.152964), cf = CFrame.new(0, -0.010564, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 70, 90), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "RootLeaf", s = "Block", z = Vector3.new(0.559771, 0.051671, 0.301415), cf = CFrame.new(-0.669849, 0.092778, 0.669861, -0.686103, 0.171065, -0.707107, 0.241922, 0.970296, 0, 0.686103, -0.171065, -0.707107), c = Color3.fromRGB(40, 116, 92), m = Enum.Material.Plastic }, -- 2
		{ n = "RootLeaf", s = "Block", z = Vector3.new(0.559771, 0.051671, 0.301415), cf = CFrame.new(-0.669849, 0.092778, -0.669861, -0.686103, 0.171065, 0.707107, 0.241922, 0.970296, 0, -0.686103, 0.171065, -0.707107), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 3
		{ n = "Pod", s = "Block", z = Vector3.new(0.861185, 0.241132, 0.861185), cf = CFrame.new(0, 0.127226, 0.000031, 1.000004, 0, -0.000001, 0, 1, 0, 0.000001, 0, 1.000004), c = Color3.fromRGB(30, 48, 92), m = Enum.Material.Plastic }, -- 4
		{ n = "Pod", s = "Block", z = Vector3.new(1.291778, 0.344474, 0.745809), cf = CFrame.new(0, 0.420029, 0.000031, 0.866029, 0, 0.500002, 0, 1, 0, -0.500001, 0, 0.866029), c = Color3.fromRGB(44, 82, 132), m = Enum.Material.Plastic }, -- 5
		{ n = "Pod", s = "Block", z = Vector3.new(1.291778, 0.344474, 0.745809), cf = CFrame.new(0, 0.420029, 0.000031, 0.000001, 0, 1.000004, 0, 1, 0, -1.000004, 0, 0.000001), c = Color3.fromRGB(44, 82, 132), m = Enum.Material.Plastic }, -- 6
		{ n = "Pod", s = "Block", z = Vector3.new(1.291778, 0.344474, 0.745809), cf = CFrame.new(0, 0.420029, 0.000031, -0.866028, 0, 0.500003, 0, 1, 0, -0.500003, 0, -0.866028), c = Color3.fromRGB(44, 82, 132), m = Enum.Material.Plastic }, -- 7
		{ n = "Pod", s = "Block", z = Vector3.new(1.636252, 0.430593, 0.944691), cf = CFrame.new(0, 0.807562, 0.000031, 0.866029, 0, 0.500002, 0, 1, 0, -0.500001, 0, 0.866029), c = Color3.fromRGB(60, 108, 166), m = Enum.Material.Plastic }, -- 8
		{ n = "Pod", s = "Block", z = Vector3.new(1.636252, 0.430593, 0.944691), cf = CFrame.new(0, 0.807562, 0.000031, 0.000001, 0, 1.000004, 0, 1, 0, -1.000004, 0, 0.000001), c = Color3.fromRGB(60, 108, 166), m = Enum.Material.Plastic }, -- 9
		{ n = "Pod", s = "Block", z = Vector3.new(1.636252, 0.430593, 0.944691), cf = CFrame.new(0, 0.807562, 0.000031, -0.866028, 0, 0.500003, 0, 1, 0, -0.500002, 0, -0.866028), c = Color3.fromRGB(60, 108, 166), m = Enum.Material.Plastic }, -- 10
		{ n = "Pod", s = "Block", z = Vector3.new(1.593193, 0.387533, 0.91983), cf = CFrame.new(0, 1.216625, 0.000031, 0.866029, 0, 0.500002, 0, 1, 0, -0.500001, 0, 0.866029), c = Color3.fromRGB(80, 132, 190), m = Enum.Material.Plastic }, -- 11
		{ n = "Pod", s = "Block", z = Vector3.new(1.593193, 0.387533, 0.91983), cf = CFrame.new(0, 1.216625, 0.000031, 0.000001, 0, 1.000004, 0, 1, 0, -1.000004, 0, 0.000001), c = Color3.fromRGB(80, 132, 190), m = Enum.Material.Plastic }, -- 12
		{ n = "Pod", s = "Block", z = Vector3.new(1.593193, 0.387533, 0.91983), cf = CFrame.new(0, 1.216625, 0.000031, -0.866028, 0, 0.500003, 0, 1, 0, -0.500003, 0, -0.866028), c = Color3.fromRGB(80, 132, 190), m = Enum.Material.Plastic }, -- 13
		{ n = "Pod", s = "Block", z = Vector3.new(1.20566, 0.344474, 0.696088), cf = CFrame.new(0, 1.582629, 0.000031, 0.866029, 0, 0.500002, 0, 1, 0, -0.500001, 0, 0.866029), c = Color3.fromRGB(108, 164, 214), m = Enum.Material.Plastic }, -- 14
		{ n = "Pod", s = "Block", z = Vector3.new(1.20566, 0.344474, 0.696088), cf = CFrame.new(0, 1.582629, 0.000031, 0.000001, 0, 1.000004, 0, 1, 0, -1.000004, 0, 0.000001), c = Color3.fromRGB(108, 164, 214), m = Enum.Material.Plastic }, -- 15
		{ n = "Pod", s = "Block", z = Vector3.new(1.20566, 0.344474, 0.696088), cf = CFrame.new(0, 1.582629, 0.000031, -0.866028, 0, 0.500003, 0, 1, 0, -0.500003, 0, -0.866028), c = Color3.fromRGB(108, 164, 214), m = Enum.Material.Plastic }, -- 16
		{ n = "Pod", s = "Block", z = Vector3.new(0.775067, 0.301415, 0.447485), cf = CFrame.new(0, 1.905574, 0.000031, 0.866029, 0, 0.500002, 0, 1, 0, -0.500001, 0, 0.866029), c = Color3.fromRGB(140, 196, 234), m = Enum.Material.Plastic }, -- 17
		{ n = "Pod", s = "Block", z = Vector3.new(0.775067, 0.301415, 0.447485), cf = CFrame.new(0, 1.905574, 0.000031, 0.000001, 0, 1.000004, 0, 1, 0, -1.000004, 0, 0.000001), c = Color3.fromRGB(140, 196, 234), m = Enum.Material.Plastic }, -- 18
		{ n = "Pod", s = "Block", z = Vector3.new(0.775067, 0.301415, 0.447485), cf = CFrame.new(0, 1.905574, 0.000031, -0.866028, 0, 0.500003, 0, 1, 0, -0.500003, 0, -0.866028), c = Color3.fromRGB(140, 196, 234), m = Enum.Material.Plastic }, -- 19
		{ n = "Pod", s = "Block", z = Vector3.new(0.344474, 0.215296, 0.344474), cf = CFrame.new(0, 2.163929, 0.000031, 0.70711, 0, 0.707109, 0, 1, 0, -0.707109, 0, 0.70711), c = Color3.fromRGB(182, 230, 250), m = Enum.Material.Plastic }, -- 20
		{ n = "Crack", s = "Block", z = Vector3.new(0.129178, 0.371695, 0.043059), cf = CFrame.new(-0.010765, 0.893681, -0.83963, -0.524099, -0.851662, -0.000001, 0.851658, -0.524097, 0, 0, -0.000001, 1.000004), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 21
		{ n = "Crack", s = "Block", z = Vector3.new(0.129178, 0.323771, 0.043059), cf = CFrame.new(-0.032295, 0.732208, -0.83963, -0.536877, 0.843665, -0.000001, -0.843662, -0.536875, 0, 0, 0.000001, 1.000004), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 22
		{ n = "Crack", s = "Block", z = Vector3.new(0.129178, 0.305862, 0.043059), cf = CFrame.new(0.04306, 1.291979, -0.818085, -0.573464, 0.819235, -0.000001, -0.819232, -0.573462, 0, 0, 0.000001, 1.000004), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 23
		{ n = "Crack", s = "Block", z = Vector3.new(0.129178, 0.288535, 0.043059), cf = CFrame.new(0.053825, 1.141272, -0.818085, -0.613943, -0.789355, -0.000001, 0.789352, -0.613941, 0, 0, 0, 1.000004), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 24
		{ n = "Streak", s = "Block", z = Vector3.new(0.103342, 0.387533, 0.043059), cf = CFrame.new(-0.301418, 0.872151, 0.839691, 1.000004, 0, -0.000001, 0, 1, 0, 0.000001, 0, 1.000004), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 25
		{ n = "Streak", s = "Block", z = Vector3.new(0.103342, 0.387533, 0.043059), cf = CFrame.new(0, 0.786032, 0.839691, 1.000004, 0, -0.000001, 0, 1, 0, 0.000001, 0, 1.000004), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 26
		{ n = "Streak", s = "Block", z = Vector3.new(0.103342, 0.387533, 0.043059), cf = CFrame.new(0.301414, 0.872151, 0.839691, 1.000004, 0, -0.000001, 0, 1, 0, 0.000001, 0, 1.000004), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 27
		{ n = "Drop", s = "Block", z = Vector3.new(0.266968, 0.266968, 0.043059), cf = CFrame.new(-0.727146, 0.807562, -0.4198, -0.353563, 0.353563, -0.866022, 0.707107, 0.707107, 0, 0.61237, -0.61237, -0.500013), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 28
		{ n = "Drop", s = "Block", z = Vector3.new(0.266968, 0.266968, 0.043059), cf = CFrame.new(0.727146, 0.807562, -0.4198, -0.353562, 0.353562, 0.866023, 0.707107, 0.707107, 0, -0.61237, 0.61237, -0.500012), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 29
		{ n = "Sepal", s = "Block", z = Vector3.new(0.258356, 0.48922, 0.060283), cf = CFrame.new(-0.41983, 2.013222, 0.000031, 0.507022, -0.861937, -0.000001, 0.861934, 0.50702, 0, 0, -0.000001, 1.000004), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 30
		{ n = "Sepal", s = "Block", z = Vector3.new(0.258356, 0.48922, 0.060283), cf = CFrame.new(0.41983, 2.013222, 0.000031, 0.507022, 0.861937, -0.000001, -0.861934, 0.50702, 0, 0, 0.000001, 1.000004), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 31
		{ n = "Sepal", s = "Block", z = Vector3.new(0.258356, 0.48922, 0.060283), cf = CFrame.new(0, 2.013222, -0.4198, 0, 0, 1.000004, -0.861934, 0.50702, 0, -0.507022, -0.861937, 0.000001), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 32
		{ n = "Sepal", s = "Block", z = Vector3.new(0.258356, 0.48922, 0.060283), cf = CFrame.new(0, 2.013222, 0.419861, 0, 0, 1.000004, 0.861934, 0.50702, 0, -0.507022, 0.861937, 0.000001), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 33
		{ n = "Sprout", s = "Block", z = Vector3.new(0.09473, 0.366004, 0.09473), cf = CFrame.new(0, 2.400755, 0.000031, 1.000004, 0, -0.000001, 0, 1, 0, 0.000001, 0, 1.000004), c = Color3.fromRGB(40, 116, 92), m = Enum.Material.Plastic }, -- 34
		{ n = "SproutLeaf", s = "Block", z = Vector3.new(0.366004, 0.060283, 0.215296), cf = CFrame.new(-0.172237, 2.529933, 0.000031, 0.882951, -0.469474, -0.000001, 0.469472, 0.882948, 0, 0.000001, 0, 1.000004), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 35
		{ n = "SproutLeaf", s = "Block", z = Vector3.new(0.366004, 0.060283, 0.215296), cf = CFrame.new(0.172237, 2.529933, 0.000031, 0.882951, 0.469474, -0.000001, -0.469472, 0.882948, 0, 0.000001, 0, 1.000004), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 36
		{ n = "RootLeaf", s = "Block", z = Vector3.new(0.559771, 0.051671, 0.301415), cf = CFrame.new(0.669849, 0.092778, -0.669861, 0.686103, -0.171065, 0.707107, 0.241922, 0.970296, 0, -0.686103, 0.171065, 0.707107), c = Color3.fromRGB(40, 116, 92), m = Enum.Material.Plastic }, -- 37
		{ n = "RootLeaf", s = "Block", z = Vector3.new(0.559771, 0.051671, 0.301415), cf = CFrame.new(0.669849, 0.092778, 0.669861, 0.686103, -0.171065, -0.707107, 0.241922, 0.970296, 0, 0.686103, -0.171065, 0.707107), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 38
	},
	Joints = {
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 0.292803, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 6, c0 = CFrame.new(0, 0.292803, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 7, c0 = CFrame.new(0, 0.292803, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 8, c0 = CFrame.new(0, 0.680337, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 9, c0 = CFrame.new(0, 0.680337, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 10, c0 = CFrame.new(0, 0.680337, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 11, c0 = CFrame.new(0, 1.0894, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 12, c0 = CFrame.new(0, 1.0894, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 13, c0 = CFrame.new(0, 1.0894, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 14, c0 = CFrame.new(0, 1.455404, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 15, c0 = CFrame.new(0, 1.455404, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 16, c0 = CFrame.new(0, 1.455404, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 17, c0 = CFrame.new(0, 1.778348, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 18, c0 = CFrame.new(0, 1.778348, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 19, c0 = CFrame.new(0, 1.778348, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 20, c0 = CFrame.new(0, 2.036704, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 21, c0 = CFrame.new(-0.010765, 0.766455, -0.839656, -0.524097, -0.851658, 0, 0.851658, -0.524097, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 22, c0 = CFrame.new(-0.032294, 0.604983, -0.839656, -0.536875, 0.843662, 0, -0.843662, -0.536875, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 23, c0 = CFrame.new(0.043059, 1.164753, -0.818126, -0.573462, 0.819232, 0, -0.819232, -0.573462, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 24, c0 = CFrame.new(0.053824, 1.014046, -0.818126, -0.613941, -0.789352, 0, 0.789352, -0.613941, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 25, c0 = CFrame.new(-0.301415, 0.744925, 0.839656, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 26, c0 = CFrame.new(0, 0.658807, 0.839656, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 27, c0 = CFrame.new(0.301415, 0.744925, 0.839656, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 28, c0 = CFrame.new(-0.727142, 0.680337, -0.419828, -0.353561, 0.353561, -0.866019, 0.707107, 0.707107, 0, 0.612368, -0.612368, -0.500011), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 29, c0 = CFrame.new(0.727142, 0.680337, -0.419828, -0.353561, 0.353561, 0.866019, 0.707107, 0.707107, 0, -0.612368, 0.612368, -0.500011), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalR", h = 17, a = 17, b = 30, c0 = CFrame.new(-0.205097, 0, -0.118413, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.212315, 0, 0.50702, 0.861934, 0, -0.861934, 0.50702, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalL", h = 17, a = 17, b = 31, c0 = CFrame.new(0.205097, 0, 0.118413, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.212315, 0, 0.50702, -0.861934, 0, 0.861934, 0.50702, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalF", h = 17, a = 17, b = 32, c0 = CFrame.new(0.118413, 0, -0.205097, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.212315, 0, 0, -0.861934, -0.50702, 0, 0.50702, -0.861934, 1, 0, 0) },
		{ k = "Motor6D", n = "SepalB", h = 17, a = 17, b = 33, c0 = CFrame.new(-0.118413, 0, 0.205097, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.212315, 0, 0, 0.861934, -0.50702, 0, 0.50702, 0.861934, 1, 0, 0) },
		{ k = "Motor6D", n = "Sprout", h = 20, a = 20, b = 34, c0 = CFrame.new(0, 0.107648, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, -0.129178, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 35, c0 = CFrame.new(-0.172237, 0.129178, 0, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 36, c0 = CFrame.new(0.172237, 0.129178, 0, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "PodGlow", p = 8, range = 9, brightness = 0.7, color = Color3.new(0.55, 0.85, 1), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Drizzle", p = 34, rate = 5, enabled = true, lifetime = NumberRange.new(1.2, 1.8), speed = NumberRange.new(0.430593, 1.076482), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.09473, 0), NumberSequenceKeypoint.new(1, 0.025836, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.74902, 0.94902, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.7, 1)) }), lightEmission = 0.7, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(80, 80), acceleration = Vector3.new(0, -4.305927, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
