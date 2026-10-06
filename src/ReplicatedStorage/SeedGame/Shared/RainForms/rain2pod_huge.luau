--!strict
--==============================================================================
-- RAIN EVENT 2 FORM: the Huge pod (tier 3), 2026-10-05
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/Pod (huge)" by a read-only generator on
-- 2026-10-05. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-05-rain-event-2-originals.
--
-- ONE OF SEVEN. The owner supplied a pod for each size, already at that size,
-- and this is the Huge one: it is replayed at exactly the size supplied and
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
	Source = "Rain Event 2/Pod (huge)", Kind = "pod", Yaw = 0,
	Size = Vector3.new(7.004089, 9.512118, 7.00415), Height = 9.512118, PartCount = 38,
	Base = 0,
	Unit = 1, ModelScale = 1.550014,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(7.750068, 0.310003, 7.750068), cf = CFrame.new(0, -0.038027, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 70, 90), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "RootLeaf", s = "Block", z = Vector3.new(2.015018, 0.186002, 1.08501), cf = CFrame.new(-2.411272, 0.333977, 2.411316, -0.686103, 0.171065, -0.707107, 0.241922, 0.970296, 0, 0.686103, -0.171065, -0.707107), c = Color3.fromRGB(40, 116, 92), m = Enum.Material.Plastic }, -- 2
		{ n = "RootLeaf", s = "Block", z = Vector3.new(2.015018, 0.186002, 1.08501), cf = CFrame.new(-2.411272, 0.333977, -2.411316, -0.686103, 0.171065, 0.707107, 0.241922, 0.970296, 0, -0.686103, 0.171065, -0.707107), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 3
		{ n = "Pod", s = "Block", z = Vector3.new(3.100027, 0.868008, 3.100027), cf = CFrame.new(0, 0.457975, 0, 1.000003, 0, 0, 0, 1, 0, 0, 0, 1.000002), c = Color3.fromRGB(30, 48, 92), m = Enum.Material.Plastic }, -- 4
		{ n = "Pod", s = "Block", z = Vector3.new(4.650041, 1.240011, 2.684703), cf = CFrame.new(0, 1.511984, 0, 0.866028, 0, 0.500001, 0, 1, 0, -0.500001, 0, 0.866027), c = Color3.fromRGB(44, 82, 132), m = Enum.Material.Plastic }, -- 5
		{ n = "Pod", s = "Block", z = Vector3.new(4.650041, 1.240011, 2.684703), cf = CFrame.new(0, 1.511984, 0, 0, 0, 1.000003, 0, 1, 0, -1.000002, 0, 0), c = Color3.fromRGB(44, 82, 132), m = Enum.Material.Plastic }, -- 6
		{ n = "Pod", s = "Block", z = Vector3.new(4.650041, 1.240011, 2.684703), cf = CFrame.new(0, 1.511984, 0, -0.866028, 0, 0.500001, 0, 1, 0, -0.500001, 0, -0.866028), c = Color3.fromRGB(44, 82, 132), m = Enum.Material.Plastic }, -- 7
		{ n = "Pod", s = "Block", z = Vector3.new(5.890052, 1.550014, 3.400623), cf = CFrame.new(0, 2.906997, 0, 0.866028, 0, 0.500001, 0, 1, 0, -0.500001, 0, 0.866027), c = Color3.fromRGB(60, 108, 166), m = Enum.Material.Plastic }, -- 8
		{ n = "Pod", s = "Block", z = Vector3.new(5.890052, 1.550014, 3.400623), cf = CFrame.new(0, 2.906997, 0, 0, 0, 1.000003, 0, 1, 0, -1.000002, 0, 0), c = Color3.fromRGB(60, 108, 166), m = Enum.Material.Plastic }, -- 9
		{ n = "Pod", s = "Block", z = Vector3.new(5.890052, 1.550014, 3.400623), cf = CFrame.new(0, 2.906997, 0, -0.866027, 0, 0.500001, 0, 1, 0, -0.500001, 0, -0.866027), c = Color3.fromRGB(60, 108, 166), m = Enum.Material.Plastic }, -- 10
		{ n = "Pod", s = "Block", z = Vector3.new(5.735051, 1.395012, 3.311133), cf = CFrame.new(0, 4.37951, 0, 0.866028, 0, 0.500001, 0, 1, 0, -0.500001, 0, 0.866027), c = Color3.fromRGB(80, 132, 190), m = Enum.Material.Plastic }, -- 11
		{ n = "Pod", s = "Block", z = Vector3.new(5.735051, 1.395012, 3.311133), cf = CFrame.new(0, 4.37951, 0, 0, 0, 1.000003, 0, 1, 0, -1.000002, 0, 0), c = Color3.fromRGB(80, 132, 190), m = Enum.Material.Plastic }, -- 12
		{ n = "Pod", s = "Block", z = Vector3.new(5.735051, 1.395012, 3.311133), cf = CFrame.new(0, 4.37951, 0, -0.866028, 0, 0.500001, 0, 1, 0, -0.500001, 0, -0.866028), c = Color3.fromRGB(80, 132, 190), m = Enum.Material.Plastic }, -- 13
		{ n = "Pod", s = "Block", z = Vector3.new(4.340038, 1.240011, 2.505723), cf = CFrame.new(0, 5.697021, 0, 0.866028, 0, 0.500001, 0, 1, 0, -0.500001, 0, 0.866027), c = Color3.fromRGB(108, 164, 214), m = Enum.Material.Plastic }, -- 14
		{ n = "Pod", s = "Block", z = Vector3.new(4.340038, 1.240011, 2.505723), cf = CFrame.new(0, 5.697021, 0, 0, 0, 1.000003, 0, 1, 0, -1.000002, 0, 0), c = Color3.fromRGB(108, 164, 214), m = Enum.Material.Plastic }, -- 15
		{ n = "Pod", s = "Block", z = Vector3.new(4.340038, 1.240011, 2.505723), cf = CFrame.new(0, 5.697021, 0, -0.866028, 0, 0.500001, 0, 1, 0, -0.500001, 0, -0.866028), c = Color3.fromRGB(108, 164, 214), m = Enum.Material.Plastic }, -- 16
		{ n = "Pod", s = "Block", z = Vector3.new(2.790025, 1.08501, 1.610821), cf = CFrame.new(0, 6.859531, 0, 0.866028, 0, 0.500001, 0, 1, 0, -0.500001, 0, 0.866027), c = Color3.fromRGB(140, 196, 234), m = Enum.Material.Plastic }, -- 17
		{ n = "Pod", s = "Block", z = Vector3.new(2.790025, 1.08501, 1.610821), cf = CFrame.new(0, 6.859531, 0, 0, 0, 1.000003, 0, 1, 0, -1.000002, 0, 0), c = Color3.fromRGB(140, 196, 234), m = Enum.Material.Plastic }, -- 18
		{ n = "Pod", s = "Block", z = Vector3.new(2.790025, 1.08501, 1.610821), cf = CFrame.new(0, 6.859531, 0, -0.866028, 0, 0.500001, 0, 1, 0, -0.500001, 0, -0.866028), c = Color3.fromRGB(140, 196, 234), m = Enum.Material.Plastic }, -- 19
		{ n = "Pod", s = "Block", z = Vector3.new(1.240011, 0.775007, 1.240011), cf = CFrame.new(0, 7.789539, 0, 0.707109, 0, 0.707109, 0, 1, 0, -0.707109, 0, 0.707108), c = Color3.fromRGB(182, 230, 250), m = Enum.Material.Plastic }, -- 20
		{ n = "Crack", s = "Block", z = Vector3.new(0.465004, 1.337998, 0.155001), cf = CFrame.new(-0.03875, 3.217, -3.022522, -0.524099, -0.851661, 0, 0.851658, -0.524097, 0, 0, 0, 1.000002), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 21
		{ n = "Crack", s = "Block", z = Vector3.new(0.465004, 1.165486, 0.155001), cf = CFrame.new(-0.116251, 2.635745, -3.022522, -0.536877, 0.843664, 0, -0.843662, -0.536875, 0, 0, 0, 1.000002), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 22
		{ n = "Crack", s = "Block", z = Vector3.new(0.465004, 1.101018, 0.155001), cf = CFrame.new(0.155003, 4.650762, -2.945038, -0.573463, 0.819234, 0, -0.819232, -0.573462, 0, 0, 0, 1.000002), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 23
		{ n = "Crack", s = "Block", z = Vector3.new(0.465004, 1.038646, 0.155001), cf = CFrame.new(0.193752, 4.108257, -2.945038, -0.613943, -0.789354, 0, 0.789352, -0.613941, 0, 0, 0, 1.000002), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 24
		{ n = "Streak", s = "Block", z = Vector3.new(0.372003, 1.395012, 0.155001), cf = CFrame.new(-1.085012, 3.139499, 3.022522, 1.000003, 0, 0, 0, 1, 0, 0, 0, 1.000002), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 25
		{ n = "Streak", s = "Block", z = Vector3.new(0.372003, 1.395012, 0.155001), cf = CFrame.new(0, 2.829495, 3.022522, 1.000003, 0, 0, 0, 1, 0, 0, 0, 1.000002), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 26
		{ n = "Streak", s = "Block", z = Vector3.new(0.372003, 1.395012, 0.155001), cf = CFrame.new(1.085012, 3.139499, 3.022522, 1.000003, 0, 0, 0, 1, 0, 0, 0, 1.000002), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 27
		{ n = "Drop", s = "Block", z = Vector3.new(0.961008, 0.961008, 0.155001), cf = CFrame.new(-2.617514, 2.906997, -1.511261, -0.353562, 0.353562, -0.866021, 0.707107, 0.707107, 0, 0.612369, -0.612369, -0.500012), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 28
		{ n = "Drop", s = "Block", z = Vector3.new(0.961008, 0.961008, 0.155001), cf = CFrame.new(2.617514, 2.906997, -1.511261, -0.353562, 0.353562, 0.866021, 0.707107, 0.707107, 0, -0.612369, 0.612369, -0.500012), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 29
		{ n = "Sepal", s = "Block", z = Vector3.new(0.930008, 1.761054, 0.217002), cf = CFrame.new(-1.511267, 7.247035, 0, 0.507021, -0.861936, 0, 0.861934, 0.50702, 0, 0, 0, 1.000003), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 30
		{ n = "Sepal", s = "Block", z = Vector3.new(0.930008, 1.761054, 0.217002), cf = CFrame.new(1.511267, 7.247035, 0, 0.507021, 0.861936, 0, -0.861934, 0.50702, 0, 0, 0, 1.000003), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 31
		{ n = "Sepal", s = "Block", z = Vector3.new(0.930008, 1.761054, 0.217002), cf = CFrame.new(0, 7.247035, -1.511261, 0, 0, 1.000003, -0.861934, 0.50702, 0, -0.507021, -0.861936, 0), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 32
		{ n = "Sepal", s = "Block", z = Vector3.new(0.930008, 1.761054, 0.217002), cf = CFrame.new(0, 7.247035, 1.511261, 0, 0, 1.000003, 0.861934, 0.50702, 0, -0.507021, 0.861936, 0), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 33
		{ n = "Sprout", s = "Block", z = Vector3.new(0.341003, 1.317512, 0.341003), cf = CFrame.new(0, 8.642047, 0, 1.000003, 0, 0, 0, 1, 0, 0, 0, 1.000003), c = Color3.fromRGB(40, 116, 92), m = Enum.Material.Plastic }, -- 34
		{ n = "SproutLeaf", s = "Block", z = Vector3.new(1.317512, 0.217002, 0.775007), cf = CFrame.new(-0.620007, 9.107051, 0, 0.88295, -0.469473, 0, 0.469472, 0.882948, 0, 0, 0, 1.000003), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 35
		{ n = "SproutLeaf", s = "Block", z = Vector3.new(1.317512, 0.217002, 0.775007), cf = CFrame.new(0.620007, 9.107051, 0, 0.88295, 0.469473, 0, -0.469472, 0.882948, 0, 0, 0, 1.000003), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 36
		{ n = "RootLeaf", s = "Block", z = Vector3.new(2.015018, 0.186002, 1.08501), cf = CFrame.new(2.411272, 0.333977, -2.411316, 0.686103, -0.171065, 0.707107, 0.241922, 0.970296, 0, -0.686103, 0.171065, 0.707107), c = Color3.fromRGB(40, 116, 92), m = Enum.Material.Plastic }, -- 37
		{ n = "RootLeaf", s = "Block", z = Vector3.new(2.015018, 0.186002, 1.08501), cf = CFrame.new(2.411272, 0.333977, 2.411316, 0.686103, -0.171065, -0.707107, 0.241922, 0.970296, 0, 0.686103, -0.171065, 0.707107), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 38
	},
	Joints = {
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 1.054009, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 6, c0 = CFrame.new(0, 1.054009, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 7, c0 = CFrame.new(0, 1.054009, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 8, c0 = CFrame.new(0, 2.449022, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 9, c0 = CFrame.new(0, 2.449022, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 10, c0 = CFrame.new(0, 2.449022, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 11, c0 = CFrame.new(0, 3.921535, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 12, c0 = CFrame.new(0, 3.921535, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 13, c0 = CFrame.new(0, 3.921535, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 14, c0 = CFrame.new(0, 5.239046, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 15, c0 = CFrame.new(0, 5.239046, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 16, c0 = CFrame.new(0, 5.239046, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 17, c0 = CFrame.new(0, 6.401556, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 18, c0 = CFrame.new(0, 6.401556, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 19, c0 = CFrame.new(0, 6.401556, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 20, c0 = CFrame.new(0, 7.331564, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 21, c0 = CFrame.new(-0.03875, 2.759024, -3.022527, -0.524097, -0.851658, 0, 0.851658, -0.524097, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 22, c0 = CFrame.new(-0.116251, 2.177769, -3.022527, -0.536875, 0.843662, 0, -0.843662, -0.536875, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 23, c0 = CFrame.new(0.155001, 4.192787, -2.945026, -0.573462, 0.819232, 0, -0.819232, -0.573462, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 24, c0 = CFrame.new(0.193752, 3.650282, -2.945026, -0.613941, -0.789352, 0, 0.789352, -0.613941, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 25, c0 = CFrame.new(-1.08501, 2.681524, 3.022527, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 26, c0 = CFrame.new(0, 2.371521, 3.022527, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 27, c0 = CFrame.new(1.08501, 2.681524, 3.022527, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 28, c0 = CFrame.new(-2.617508, 2.449022, -1.511263, -0.353561, 0.353561, -0.866019, 0.707107, 0.707107, 0, 0.612368, -0.612368, -0.500011), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 29, c0 = CFrame.new(2.617508, 2.449022, -1.511263, -0.353561, 0.353561, 0.866019, 0.707107, 0.707107, 0, -0.612368, 0.612368, -0.500011), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalR", h = 17, a = 17, b = 30, c0 = CFrame.new(-0.738293, 0, -0.426254, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.764276, 0, 0.50702, 0.861934, 0, -0.861934, 0.50702, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalL", h = 17, a = 17, b = 31, c0 = CFrame.new(0.738293, 0, 0.426254, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.764276, 0, 0.50702, -0.861934, 0, 0.861934, 0.50702, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SepalF", h = 17, a = 17, b = 32, c0 = CFrame.new(0.426254, 0, -0.738293, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.764276, 0, 0, -0.861934, -0.50702, 0, 0.50702, -0.861934, 1, 0, 0) },
		{ k = "Motor6D", n = "SepalB", h = 17, a = 17, b = 33, c0 = CFrame.new(-0.426254, 0, 0.738293, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, -0.764276, 0, 0, 0.861934, -0.50702, 0, 0.50702, 0.861934, 1, 0, 0) },
		{ k = "Motor6D", n = "Sprout", h = 20, a = 20, b = 34, c0 = CFrame.new(0, 0.387503, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, -0.465004, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 35, c0 = CFrame.new(-0.620005, 0.465004, 0, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 36, c0 = CFrame.new(0.620005, 0.465004, 0, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "PodGlow", p = 8, range = 9, brightness = 0.7, color = Color3.new(0.55, 0.85, 1), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Drizzle", p = 34, rate = 5, enabled = true, lifetime = NumberRange.new(1.2, 1.8), speed = NumberRange.new(1.550014, 3.875034), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.341003, 0), NumberSequenceKeypoint.new(1, 0.093001, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.74902, 0.94902, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.7, 1)) }), lightEmission = 0.7, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(80, 80), acceleration = Vector3.new(0, -15.500136, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
