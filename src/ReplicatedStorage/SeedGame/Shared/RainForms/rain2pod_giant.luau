--!strict
--==============================================================================
-- RAIN EVENT 2 FORM: the Giant pod (tier 5), 2026-10-05
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/Pod (Giant)" by a read-only generator on
-- 2026-10-05. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-05-rain-event-2-originals.
--
-- ONE OF SEVEN. The owner supplied a pod for each size, already at that size,
-- and this is the Giant one: it is replayed at exactly the size supplied and
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
	Source = "Rain Event 2/Pod (Giant)", Kind = "pod", Yaw = 0,
	Size = Vector3.new(13.175831, 16.510273, 11.446289), Height = 16.510273, PartCount = 43,
	Base = 0,
	Unit = 1, ModelScale = 1.94004,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(7.76016, 0.388008, 7.76016), cf = CFrame.new(0, 0.194004, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 70, 90), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "Pod", s = "Block", z = Vector3.new(5.82012, 1.552032, 5.82012), cf = CFrame.new(0, 0.776016, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(50, 58, 82), m = Enum.Material.Plastic }, -- 2
		{ n = "Pod", s = "Block", z = Vector3.new(9.312194, 2.134044, 3.857236), cf = CFrame.new(0, 2.619054, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(64, 74, 102), m = Enum.Material.Plastic }, -- 3
		{ n = "Pod", s = "Block", z = Vector3.new(9.312194, 2.134044, 3.857236), cf = CFrame.new(0, 2.619054, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(64, 74, 102), m = Enum.Material.Plastic }, -- 4
		{ n = "Pod", s = "Block", z = Vector3.new(9.312194, 2.134044, 3.857236), cf = CFrame.new(0, 2.619054, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(64, 74, 102), m = Enum.Material.Plastic }, -- 5
		{ n = "Pod", s = "Block", z = Vector3.new(9.312194, 2.134044, 3.857236), cf = CFrame.new(0, 2.619054, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(64, 74, 102), m = Enum.Material.Plastic }, -- 6
		{ n = "Pod", s = "Block", z = Vector3.new(11.058228, 2.522052, 4.580468), cf = CFrame.new(0, 4.947103, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 7
		{ n = "Pod", s = "Block", z = Vector3.new(11.058228, 2.522052, 4.580468), cf = CFrame.new(0, 4.947103, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 8
		{ n = "Pod", s = "Block", z = Vector3.new(11.058228, 2.522052, 4.580468), cf = CFrame.new(0, 4.947103, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 9
		{ n = "Pod", s = "Block", z = Vector3.new(11.058228, 2.522052, 4.580468), cf = CFrame.new(0, 4.947103, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 10
		{ n = "Pod", s = "Block", z = Vector3.new(9.506196, 2.134044, 3.937595), cf = CFrame.new(0, 7.275151, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(96, 110, 140), m = Enum.Material.Plastic }, -- 11
		{ n = "Pod", s = "Block", z = Vector3.new(9.506196, 2.134044, 3.937595), cf = CFrame.new(0, 7.275151, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(96, 110, 140), m = Enum.Material.Plastic }, -- 12
		{ n = "Pod", s = "Block", z = Vector3.new(9.506196, 2.134044, 3.937595), cf = CFrame.new(0, 7.275151, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(96, 110, 140), m = Enum.Material.Plastic }, -- 13
		{ n = "Pod", s = "Block", z = Vector3.new(9.506196, 2.134044, 3.937595), cf = CFrame.new(0, 7.275151, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(96, 110, 140), m = Enum.Material.Plastic }, -- 14
		{ n = "Pod", s = "Block", z = Vector3.new(6.402133, 1.94004, 3.696273), cf = CFrame.new(0, 9.312193, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c = Color3.fromRGB(114, 128, 158), m = Enum.Material.Plastic }, -- 15
		{ n = "Pod", s = "Block", z = Vector3.new(6.402133, 1.94004, 3.696273), cf = CFrame.new(0, 9.312193, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(114, 128, 158), m = Enum.Material.Plastic }, -- 16
		{ n = "Pod", s = "Block", z = Vector3.new(6.402133, 1.94004, 3.696273), cf = CFrame.new(0, 9.312193, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c = Color3.fromRGB(114, 128, 158), m = Enum.Material.Plastic }, -- 17
		{ n = "Pod", s = "Block", z = Vector3.new(5.82012, 1.358028, 3.360248), cf = CFrame.new(0, 10.961226, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c = Color3.fromRGB(132, 146, 176), m = Enum.Material.Plastic }, -- 18
		{ n = "Pod", s = "Block", z = Vector3.new(5.82012, 1.358028, 3.360248), cf = CFrame.new(0, 10.961226, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(132, 146, 176), m = Enum.Material.Plastic }, -- 19
		{ n = "Pod", s = "Block", z = Vector3.new(5.82012, 1.358028, 3.360248), cf = CFrame.new(0, 10.961226, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c = Color3.fromRGB(132, 146, 176), m = Enum.Material.Plastic }, -- 20
		{ n = "Pod", s = "Block", z = Vector3.new(7.954165, 1.164024, 3.294724), cf = CFrame.new(0, 12.222254, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 160, 140), m = Enum.Material.Plastic }, -- 21
		{ n = "Pod", s = "Block", z = Vector3.new(7.954165, 1.164024, 3.294724), cf = CFrame.new(0, 12.222254, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 160, 140), m = Enum.Material.Plastic }, -- 22
		{ n = "Pod", s = "Block", z = Vector3.new(7.954165, 1.164024, 3.294724), cf = CFrame.new(0, 12.222254, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(255, 160, 140), m = Enum.Material.Plastic }, -- 23
		{ n = "Pod", s = "Block", z = Vector3.new(7.954165, 1.164024, 3.294724), cf = CFrame.new(0, 12.222254, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(255, 160, 140), m = Enum.Material.Plastic }, -- 24
		{ n = "Mouth", s = "Block", z = Vector3.new(4.462092, 0.077602, 4.462092), cf = CFrame.new(0, 12.843065, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(20, 16, 28), m = Enum.Material.SmoothPlastic, st = false }, -- 25
		{ n = "Water", s = "Block", z = Vector3.new(3.492072, 0.077602, 3.492072), cf = CFrame.new(0, 12.901266, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 26
		{ n = "PouringLip", s = "Block", z = Vector3.new(2.716056, 0.582012, 2.134044), cf = CFrame.new(0, 12.901266, -4.268097, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 27
		{ n = "Hinge", s = "Block", z = Vector3.new(1.94004, 0.776016, 0.97002), cf = CFrame.new(0, 13.09527, 3.589081, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(214, 70, 70), m = Enum.Material.SmoothPlastic, st = false }, -- 28
		{ n = "Lid", s = "Block", z = Vector3.new(4.850101, 0.46561, 3.686076), cf = CFrame.new(0, 14.773672, 2.929382, 1, 0, 0, 0, 0.469472, -0.882948, 0, 0.882948, 0.469472), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 29
		{ n = "LidGem", s = "Block", z = Vector3.new(1.358028, 0.194004, 1.358028), cf = CFrame.new(0, 14.509542, 2.432617, 0.707107, 0, 0.707107, 0.624338, 0.469472, -0.624338, -0.331967, 0.882948, 0.331967), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 30
		{ n = "Rib", s = "Block", z = Vector3.new(0.659614, 1.94004, 0.194004), cf = CFrame.new(0, 4.947103, -5.626129, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 31
		{ n = "Rib", s = "Block", z = Vector3.new(0.659614, 1.358028, 0.194004), cf = CFrame.new(3.978266, 5.238108, -3.978271, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 32
		{ n = "Rib", s = "Block", z = Vector3.new(0.659614, 1.94004, 0.194004), cf = CFrame.new(5.626116, 4.947103, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 33
		{ n = "Rib", s = "Block", z = Vector3.new(0.659614, 1.358028, 0.194004), cf = CFrame.new(3.978266, 5.238108, 3.978271, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 34
		{ n = "Rib", s = "Block", z = Vector3.new(0.659614, 1.94004, 0.194004), cf = CFrame.new(0, 4.947103, 5.626129, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 35
		{ n = "Rib", s = "Block", z = Vector3.new(0.659614, 1.358028, 0.194004), cf = CFrame.new(-3.978266, 5.238108, 3.978271, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 36
		{ n = "Rib", s = "Block", z = Vector3.new(0.659614, 1.94004, 0.194004), cf = CFrame.new(-5.626116, 4.947103, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 37
		{ n = "Rib", s = "Block", z = Vector3.new(0.659614, 1.358028, 0.194004), cf = CFrame.new(-3.978266, 5.238108, -3.978271, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 38
		{ n = "FrontGem", s = "Block", z = Vector3.new(1.552032, 1.552032, 0.194004), cf = CFrame.new(0, 7.275151, -4.850098, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 39
		{ n = "RimPetal", s = "Block", z = Vector3.new(1.649034, 3.481767, 0.291006), cf = CFrame.new(-4.898601, 12.367756, -1.843048, 0, -0.942428, -0.33441, 0, -0.33441, 0.942428, -1, 0, 0), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 40
		{ n = "RimPetal", s = "Block", z = Vector3.new(1.649034, 3.481767, 0.291006), cf = CFrame.new(-4.898601, 12.367756, 1.843048, 0, -0.942428, -0.33441, 0, -0.33441, 0.942428, -1, 0, 0), c = Color3.fromRGB(214, 70, 70), m = Enum.Material.Plastic }, -- 41
		{ n = "RimPetal", s = "Block", z = Vector3.new(1.649034, 3.481767, 0.291006), cf = CFrame.new(4.898601, 12.367756, -1.843048, 0, 0.942428, 0.33441, 0, -0.33441, 0.942428, 1, 0, 0), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 42
		{ n = "RimPetal", s = "Block", z = Vector3.new(1.649034, 3.481767, 0.291006), cf = CFrame.new(4.898601, 12.367756, 1.843048, 0, 0.942428, 0.33441, 0, -0.33441, 0.942428, 1, 0, 0), c = Color3.fromRGB(214, 70, 70), m = Enum.Material.Plastic }, -- 43
	},
	Joints = {
		{ k = "Motor6D", n = "Pod", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.582012, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 3, c0 = CFrame.new(0, 1.843038, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 1.843038, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 5, c0 = CFrame.new(0, 1.843038, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 6, c0 = CFrame.new(0, 1.843038, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 7, c0 = CFrame.new(0, 4.171087, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 8, c0 = CFrame.new(0, 4.171087, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 9, c0 = CFrame.new(0, 4.171087, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 10, c0 = CFrame.new(0, 4.171087, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 11, c0 = CFrame.new(0, 6.499135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 12, c0 = CFrame.new(0, 6.499135, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 13, c0 = CFrame.new(0, 6.499135, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 14, c0 = CFrame.new(0, 6.499135, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 15, c0 = CFrame.new(0, 8.536177, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 16, c0 = CFrame.new(0, 8.536177, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 17, c0 = CFrame.new(0, 8.536177, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 18, c0 = CFrame.new(0, 10.18521, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 19, c0 = CFrame.new(0, 10.18521, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 20, c0 = CFrame.new(0, 10.18521, 0, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 21, c0 = CFrame.new(0, 11.446238, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 22, c0 = CFrame.new(0, 11.446238, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 23, c0 = CFrame.new(0, 11.446238, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 24, c0 = CFrame.new(0, 11.446238, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 25, c0 = CFrame.new(0, 12.067049, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 27, c0 = CFrame.new(0, 12.125251, -4.268088, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 28, c0 = CFrame.new(0, 12.319254, 3.589074, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Lid", h = 2, a = 2, b = 29, c0 = CFrame.new(0, 12.261055, 3.589074, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.232805, 1.843038, 1, 0, 0, 0, 0.469472, 0.882948, 0, -0.882948, 0.469472) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 31, c0 = CFrame.new(0, 4.171087, -5.626116, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 32, c0 = CFrame.new(3.978266, 4.462092, -3.978266, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 33, c0 = CFrame.new(5.626116, 4.171087, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 34, c0 = CFrame.new(3.978266, 4.462092, 3.978266, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 35, c0 = CFrame.new(0, 4.171087, 5.626116, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 36, c0 = CFrame.new(-3.978266, 4.462092, 3.978266, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 37, c0 = CFrame.new(-5.626116, 4.171087, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 38, c0 = CFrame.new(-3.978266, 4.462092, -3.978266, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 39, c0 = CFrame.new(0, 6.499135, -4.850101, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "PetalR0", h = 2, a = 2, b = 40, c0 = CFrame.new(-3.39507, 12.125251, -1.843038, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.59538, 0, 0, 0, -1, -0.942428, -0.33441, 0, -0.33441, 0.942428, 0) },
		{ k = "Motor6D", n = "PetalR1", h = 2, a = 2, b = 41, c0 = CFrame.new(-3.39507, 12.125251, 1.843038, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.59538, 0, 0, 0, -1, -0.942428, -0.33441, 0, -0.33441, 0.942428, 0) },
		{ k = "Motor6D", n = "PetalL0", h = 2, a = 2, b = 42, c0 = CFrame.new(3.39507, 12.125251, -1.843038, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.59538, 0, 0, 0, 1, 0.942428, -0.33441, 0, 0.33441, 0.942428, 0) },
		{ k = "Motor6D", n = "PetalL1", h = 2, a = 2, b = 43, c0 = CFrame.new(3.39507, 12.125251, 1.843038, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.59538, 0, 0, 0, 1, 0.942428, -0.33441, 0, 0.33441, 0.942428, 0) },
		{ k = "Weld", n = "Hold", h = 25, a = 25, b = 26, c0 = CFrame.new(0, 0.058201, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 29, a = 29, b = 30, c0 = CFrame.new(0, -0.562612, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "PodGlow", p = 26, range = 12, brightness = 1, color = Color3.new(0.431373, 0.901961, 1), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Spout", p = 26, rate = 12, enabled = true, lifetime = NumberRange.new(1.4, 2.2), speed = NumberRange.new(9.700201, 15.520321), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.582012, 0), NumberSequenceKeypoint.new(1, 0.194004, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.8, 0.98, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.3, 0.7, 1)) }), lightEmission = 0.7, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(14, 14), acceleration = Vector3.new(0, -34.920723, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
