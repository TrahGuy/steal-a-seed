--!strict
--==============================================================================
-- RAIN EVENT 2 FORM: the Mega pod (tier 4), 2026-10-05
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/Pod (Mega)" by a read-only generator on
-- 2026-10-05. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-05-rain-event-2-originals.
--
-- ONE OF SEVEN. The owner supplied a pod for each size, already at that size,
-- and this is the Mega one: it is replayed at exactly the size supplied and
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
	Source = "Rain Event 2/Pod (Mega)", Kind = "pod", Yaw = 0,
	Size = Vector3.new(9.983678, 12.510274, 8.673096), Height = 12.510274, PartCount = 43,
	Base = 0,
	Unit = 1, ModelScale = 1.47002,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(5.88008, 0.294004, 5.88008), cf = CFrame.new(0, 0.147002, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 70, 90), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "Pod", s = "Block", z = Vector3.new(4.41006, 1.176016, 4.41006), cf = CFrame.new(0, 0.588008, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(50, 58, 82), m = Enum.Material.Plastic }, -- 2
		{ n = "Pod", s = "Block", z = Vector3.new(7.056097, 1.617022, 2.922731), cf = CFrame.new(0, 1.984527, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(64, 74, 102), m = Enum.Material.Plastic }, -- 3
		{ n = "Pod", s = "Block", z = Vector3.new(7.056097, 1.617022, 2.922731), cf = CFrame.new(0, 1.984527, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(64, 74, 102), m = Enum.Material.Plastic }, -- 4
		{ n = "Pod", s = "Block", z = Vector3.new(7.056097, 1.617022, 2.922731), cf = CFrame.new(0, 1.984527, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(64, 74, 102), m = Enum.Material.Plastic }, -- 5
		{ n = "Pod", s = "Block", z = Vector3.new(7.056097, 1.617022, 2.922731), cf = CFrame.new(0, 1.984527, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(64, 74, 102), m = Enum.Material.Plastic }, -- 6
		{ n = "Pod", s = "Block", z = Vector3.new(8.379114, 1.911026, 3.470742), cf = CFrame.new(0, 3.748551, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 7
		{ n = "Pod", s = "Block", z = Vector3.new(8.379114, 1.911026, 3.470742), cf = CFrame.new(0, 3.748551, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 8
		{ n = "Pod", s = "Block", z = Vector3.new(8.379114, 1.911026, 3.470742), cf = CFrame.new(0, 3.748551, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 9
		{ n = "Pod", s = "Block", z = Vector3.new(8.379114, 1.911026, 3.470742), cf = CFrame.new(0, 3.748551, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 10
		{ n = "Pod", s = "Block", z = Vector3.new(7.203098, 1.617022, 2.98362), cf = CFrame.new(0, 5.512576, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(96, 110, 140), m = Enum.Material.Plastic }, -- 11
		{ n = "Pod", s = "Block", z = Vector3.new(7.203098, 1.617022, 2.98362), cf = CFrame.new(0, 5.512576, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(96, 110, 140), m = Enum.Material.Plastic }, -- 12
		{ n = "Pod", s = "Block", z = Vector3.new(7.203098, 1.617022, 2.98362), cf = CFrame.new(0, 5.512576, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(96, 110, 140), m = Enum.Material.Plastic }, -- 13
		{ n = "Pod", s = "Block", z = Vector3.new(7.203098, 1.617022, 2.98362), cf = CFrame.new(0, 5.512576, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(96, 110, 140), m = Enum.Material.Plastic }, -- 14
		{ n = "Pod", s = "Block", z = Vector3.new(4.851066, 1.47002, 2.800765), cf = CFrame.new(0, 7.056097, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c = Color3.fromRGB(114, 128, 158), m = Enum.Material.Plastic }, -- 15
		{ n = "Pod", s = "Block", z = Vector3.new(4.851066, 1.47002, 2.800765), cf = CFrame.new(0, 7.056097, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(114, 128, 158), m = Enum.Material.Plastic }, -- 16
		{ n = "Pod", s = "Block", z = Vector3.new(4.851066, 1.47002, 2.800765), cf = CFrame.new(0, 7.056097, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c = Color3.fromRGB(114, 128, 158), m = Enum.Material.Plastic }, -- 17
		{ n = "Pod", s = "Block", z = Vector3.new(4.41006, 1.029014, 2.54615), cf = CFrame.new(0, 8.305613, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c = Color3.fromRGB(132, 146, 176), m = Enum.Material.Plastic }, -- 18
		{ n = "Pod", s = "Block", z = Vector3.new(4.41006, 1.029014, 2.54615), cf = CFrame.new(0, 8.305613, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(132, 146, 176), m = Enum.Material.Plastic }, -- 19
		{ n = "Pod", s = "Block", z = Vector3.new(4.41006, 1.029014, 2.54615), cf = CFrame.new(0, 8.305613, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c = Color3.fromRGB(132, 146, 176), m = Enum.Material.Plastic }, -- 20
		{ n = "Pod", s = "Block", z = Vector3.new(6.027082, 0.882012, 2.4965), cf = CFrame.new(0, 9.261127, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 160, 140), m = Enum.Material.Plastic }, -- 21
		{ n = "Pod", s = "Block", z = Vector3.new(6.027082, 0.882012, 2.4965), cf = CFrame.new(0, 9.261127, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 160, 140), m = Enum.Material.Plastic }, -- 22
		{ n = "Pod", s = "Block", z = Vector3.new(6.027082, 0.882012, 2.4965), cf = CFrame.new(0, 9.261127, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(255, 160, 140), m = Enum.Material.Plastic }, -- 23
		{ n = "Pod", s = "Block", z = Vector3.new(6.027082, 0.882012, 2.4965), cf = CFrame.new(0, 9.261127, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(255, 160, 140), m = Enum.Material.Plastic }, -- 24
		{ n = "Mouth", s = "Block", z = Vector3.new(3.381046, 0.058801, 3.381046), cf = CFrame.new(0, 9.731533, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(20, 16, 28), m = Enum.Material.SmoothPlastic, st = false }, -- 25
		{ n = "Water", s = "Block", z = Vector3.new(2.646036, 0.058801, 2.646036), cf = CFrame.new(0, 9.775633, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 26
		{ n = "PouringLip", s = "Block", z = Vector3.new(2.058028, 0.441006, 1.617022), cf = CFrame.new(0, 9.775633, -3.234039, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 27
		{ n = "Hinge", s = "Block", z = Vector3.new(1.47002, 0.588008, 0.73501), cf = CFrame.new(0, 9.922636, 2.719543, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(214, 70, 70), m = Enum.Material.SmoothPlastic, st = false }, -- 28
		{ n = "Lid", s = "Block", z = Vector3.new(3.67505, 0.352805, 2.793038), cf = CFrame.new(0, 11.194405, 2.219666, 1, 0, 0, 0, 0.469472, -0.882948, 0, 0.882948, 0.469472), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 29
		{ n = "LidGem", s = "Block", z = Vector3.new(1.029014, 0.147002, 1.029014), cf = CFrame.new(0, 10.994267, 1.843262, 0.707107, 0, 0.707107, 0.624338, 0.469472, -0.624338, -0.331967, 0.882948, 0.331967), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 30
		{ n = "Rib", s = "Block", z = Vector3.new(0.499807, 1.47002, 0.147002), cf = CFrame.new(0, 3.748551, -4.263062, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 31
		{ n = "Rib", s = "Block", z = Vector3.new(0.499807, 1.029014, 0.147002), cf = CFrame.new(3.014439, 3.969054, -3.014435, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 32
		{ n = "Rib", s = "Block", z = Vector3.new(0.499807, 1.47002, 0.147002), cf = CFrame.new(4.263058, 3.748551, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 33
		{ n = "Rib", s = "Block", z = Vector3.new(0.499807, 1.029014, 0.147002), cf = CFrame.new(3.014439, 3.969054, 3.014435, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 34
		{ n = "Rib", s = "Block", z = Vector3.new(0.499807, 1.47002, 0.147002), cf = CFrame.new(0, 3.748551, 4.263062, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 35
		{ n = "Rib", s = "Block", z = Vector3.new(0.499807, 1.029014, 0.147002), cf = CFrame.new(-3.014438, 3.969054, 3.014435, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 36
		{ n = "Rib", s = "Block", z = Vector3.new(0.499807, 1.47002, 0.147002), cf = CFrame.new(-4.263058, 3.748551, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 37
		{ n = "Rib", s = "Block", z = Vector3.new(0.499807, 1.029014, 0.147002), cf = CFrame.new(-3.014438, 3.969054, -3.014435, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 38
		{ n = "FrontGem", s = "Block", z = Vector3.new(1.176016, 1.176016, 0.147002), cf = CFrame.new(0, 5.512576, -3.675049, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 39
		{ n = "RimPetal", s = "Block", z = Vector3.new(1.249517, 2.638227, 0.220503), cf = CFrame.new(-3.711801, 9.371378, -1.396515, 0, -0.942428, -0.33441, 0, -0.33441, 0.942428, -1, 0, 0), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 40
		{ n = "RimPetal", s = "Block", z = Vector3.new(1.249517, 2.638227, 0.220503), cf = CFrame.new(-3.711801, 9.371378, 1.396515, 0, -0.942428, -0.33441, 0, -0.33441, 0.942428, -1, 0, 0), c = Color3.fromRGB(214, 70, 70), m = Enum.Material.Plastic }, -- 41
		{ n = "RimPetal", s = "Block", z = Vector3.new(1.249517, 2.638227, 0.220503), cf = CFrame.new(3.7118, 9.371378, -1.396515, 0, 0.942428, 0.33441, 0, -0.33441, 0.942428, 1, 0, 0), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 42
		{ n = "RimPetal", s = "Block", z = Vector3.new(1.249517, 2.638227, 0.220503), cf = CFrame.new(3.7118, 9.371378, 1.396515, 0, 0.942428, 0.33441, 0, -0.33441, 0.942428, 1, 0, 0), c = Color3.fromRGB(214, 70, 70), m = Enum.Material.Plastic }, -- 43
	},
	Joints = {
		{ k = "Motor6D", n = "Pod", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.441006, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 3, c0 = CFrame.new(0, 1.396519, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 1.396519, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 5, c0 = CFrame.new(0, 1.396519, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 6, c0 = CFrame.new(0, 1.396519, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 7, c0 = CFrame.new(0, 3.160543, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 8, c0 = CFrame.new(0, 3.160543, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 9, c0 = CFrame.new(0, 3.160543, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 10, c0 = CFrame.new(0, 3.160543, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 11, c0 = CFrame.new(0, 4.924567, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 12, c0 = CFrame.new(0, 4.924567, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 13, c0 = CFrame.new(0, 4.924567, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 14, c0 = CFrame.new(0, 4.924567, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 15, c0 = CFrame.new(0, 6.468088, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 16, c0 = CFrame.new(0, 6.468088, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 17, c0 = CFrame.new(0, 6.468088, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 18, c0 = CFrame.new(0, 7.717605, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 19, c0 = CFrame.new(0, 7.717605, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 20, c0 = CFrame.new(0, 7.717605, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 21, c0 = CFrame.new(0, 8.673119, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 22, c0 = CFrame.new(0, 8.673119, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 23, c0 = CFrame.new(0, 8.673119, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 24, c0 = CFrame.new(0, 8.673119, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 25, c0 = CFrame.new(0, 9.143524, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 27, c0 = CFrame.new(0, 9.187625, -3.234044, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 28, c0 = CFrame.new(0, 9.334627, 2.719537, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Lid", h = 2, a = 2, b = 29, c0 = CFrame.new(0, 9.290527, 2.719537, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.176402, 1.396519, 1, 0, 0, 0, 0.469472, 0.882948, 0, -0.882948, 0.469472) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 31, c0 = CFrame.new(0, 3.160543, -4.263058, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 32, c0 = CFrame.new(3.014438, 3.381046, -3.014438, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 33, c0 = CFrame.new(4.263058, 3.160543, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 34, c0 = CFrame.new(3.014438, 3.381046, 3.014438, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 35, c0 = CFrame.new(0, 3.160543, 4.263058, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 36, c0 = CFrame.new(-3.014438, 3.381046, 3.014438, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 37, c0 = CFrame.new(-4.263058, 3.160543, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 38, c0 = CFrame.new(-3.014438, 3.381046, -3.014438, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 39, c0 = CFrame.new(0, 4.924567, -3.67505, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "PetalR0", h = 2, a = 2, b = 40, c0 = CFrame.new(-2.572535, 9.187625, -1.396519, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.208862, 0, 0, 0, -1, -0.942428, -0.33441, 0, -0.33441, 0.942428, 0) },
		{ k = "Motor6D", n = "PetalR1", h = 2, a = 2, b = 41, c0 = CFrame.new(-2.572535, 9.187625, 1.396519, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.208862, 0, 0, 0, -1, -0.942428, -0.33441, 0, -0.33441, 0.942428, 0) },
		{ k = "Motor6D", n = "PetalL0", h = 2, a = 2, b = 42, c0 = CFrame.new(2.572535, 9.187625, -1.396519, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.208862, 0, 0, 0, 1, 0.942428, -0.33441, 0, 0.33441, 0.942428, 0) },
		{ k = "Motor6D", n = "PetalL1", h = 2, a = 2, b = 43, c0 = CFrame.new(2.572535, 9.187625, 1.396519, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.208862, 0, 0, 0, 1, 0.942428, -0.33441, 0, 0.33441, 0.942428, 0) },
		{ k = "Weld", n = "Hold", h = 25, a = 25, b = 26, c0 = CFrame.new(0, 0.044101, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 29, a = 29, b = 30, c0 = CFrame.new(0, -0.426306, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "PodGlow", p = 26, range = 12, brightness = 1, color = Color3.new(0.431373, 0.901961, 1), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Spout", p = 26, rate = 12, enabled = true, lifetime = NumberRange.new(1.4, 2.2), speed = NumberRange.new(7.350101, 11.76016), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.441006, 0), NumberSequenceKeypoint.new(1, 0.147002, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.8, 0.98, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.3, 0.7, 1)) }), lightEmission = 0.7, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(14, 14), acceleration = Vector3.new(0, -26.460361, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
