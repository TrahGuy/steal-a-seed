--!strict
--==============================================================================
-- PLANT FORM: Squallsnapper (Epic), the Rain event's second family (2026-10-05)
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/SquallsnapLow (epic) (Tiny)" by a read-only generator on
-- 2026-10-05. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-05-rain-event-2-originals.
--
-- A RAIN CREATURE, NOT A ROAD SPECIES. It is built the way PlantForms' rigs
-- are -- whole, at its tier's size -- and nothing else about PlantForms is
-- asked of it: it is in no biome pool, shelf or reward (SeedData.RainSpecies).
-- The SUPPLIED model is its Tiny (PlantForms.Supplied): every tier builds it
-- at exactly that size times the tier ladder.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the model's BASE:
-- its root part's x/z at the lowest drawn point, facing the way the root
-- faces), colour, material, surface, attribute and joint is the supplied
-- number, at the size it was supplied. Joints point at parts by INDEX, because
-- names repeat.
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "Rain Event 2/SquallsnapLow (epic) (Tiny)", Kind = "plant", Yaw = 0,
	Size = Vector3.new(2.322229, 4.943014, 2.429352), Height = 4.943014, PartCount = 46,
	Base = 1,
	Unit = 1, ModelScale = 0.563648,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(1.240025, 0.11273, 1.240025), cf = CFrame.new(0, 0.056365, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 70, 90), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "Pelvis", s = "Block", z = Vector3.new(1.07093, 0.417099, 0.901836), cf = CFrame.new(0, 1.116023, 0.028168, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 92, 142), m = Enum.Material.Plastic }, -- 2
		{ n = "Torso", s = "Block", z = Vector3.new(1.296389, 1.042748, 1.07093), cf = CFrame.new(0, 1.803673, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(70, 118, 172), m = Enum.Material.Plastic }, -- 3
		{ n = "BellyPatch", s = "Block", z = Vector3.new(0.732742, 0.563648, 0.056365), cf = CFrame.new(0, 1.690943, -0.558014, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(196, 228, 242), m = Enum.Material.SmoothPlastic, st = false }, -- 4
		{ n = "BellyDrop", s = "Block", z = Vector3.new(0.236732, 0.236732, 0.045092), cf = CFrame.new(0, 1.690943, -0.603119, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 5
		{ n = "Leg", s = "Block", z = Vector3.new(0.372007, 0.760924, 0.372007), cf = CFrame.new(-0.349462, 0.563648, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(46, 86, 134), m = Enum.Material.Plastic }, -- 6
		{ n = "Foot", s = "Block", z = Vector3.new(0.450918, 0.19164, 0.676377), cf = CFrame.new(-0.349462, 0.09582, -0.123993, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(34, 58, 96), m = Enum.Material.Plastic }, -- 7
		{ n = "Arm", s = "Block", z = Vector3.new(0.310006, 0.965476, 0.310006), cf = CFrame.new(-0.845471, 1.775491, -0.126831, -0.985622, -0.164057, -0.040425, 0.168964, -0.956998, -0.23581, 0, -0.23925, 0.970958), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 8
		{ n = "Hand", s = "Block", z = Vector3.new(0.450918, 0.281824, 0.450918), cf = CFrame.new(-0.935656, 1.240025, -0.28183, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 9
		{ n = "Leg", s = "Block", z = Vector3.new(0.372007, 0.760924, 0.372007), cf = CFrame.new(0.349462, 0.563648, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(46, 86, 134), m = Enum.Material.Plastic }, -- 10
		{ n = "Foot", s = "Block", z = Vector3.new(0.450918, 0.19164, 0.676377), cf = CFrame.new(0.349462, 0.09582, -0.123993, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(34, 58, 96), m = Enum.Material.Plastic }, -- 11
		{ n = "Arm", s = "Block", z = Vector3.new(0.310006, 0.965476, 0.310006), cf = CFrame.new(0.845471, 1.775491, -0.126831, -0.985622, 0.164057, 0.040425, -0.168964, -0.956998, -0.23581, 0, -0.23925, 0.970958), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 12
		{ n = "Hand", s = "Block", z = Vector3.new(0.450918, 0.281824, 0.450918), cf = CFrame.new(0.935655, 1.240025, -0.28183, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 13
		{ n = "Head", s = "Block", z = Vector3.new(1.521849, 1.18366, 1.296389), cf = CFrame.new(0, 3.156427, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(58, 128, 160), m = Enum.Material.Plastic }, -- 14
		{ n = "LowerJaw", s = "Block", z = Vector3.new(1.409119, 0.310006, 1.409119), cf = CFrame.new(0, 2.440595, -0.056366, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(46, 104, 138), m = Enum.Material.Plastic }, -- 15
		{ n = "Mouth", s = "Block", z = Vector3.new(1.352754, 0.349462, 0.045092), cf = CFrame.new(0, 2.761874, -0.659454, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(40, 14, 34), m = Enum.Material.SmoothPlastic, st = false }, -- 16
		{ n = "UpperLip", s = "Block", z = Vector3.new(1.465484, 0.078911, 0.11273), cf = CFrame.new(0, 2.97606, -0.676392, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(28, 64, 96), m = Enum.Material.SmoothPlastic, st = false }, -- 17
		{ n = "Fang", s = "Block", z = Vector3.new(0.169094, 0.338189, 0.11273), cf = CFrame.new(-0.563647, 2.773147, -0.710205, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 252, 238), m = Enum.Material.SmoothPlastic, st = false }, -- 18
		{ n = "Tooth", s = "Block", z = Vector3.new(0.19164, 0.214186, 0.101457), cf = CFrame.new(-0.214186, 2.829512, -0.704559, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 248, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 19
		{ n = "Tooth", s = "Block", z = Vector3.new(0.169094, 0.202913, 0.101457), cf = CFrame.new(-0.372007, 2.694236, -0.704559, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 248, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 20
		{ n = "Fang", s = "Block", z = Vector3.new(0.169094, 0.338189, 0.11273), cf = CFrame.new(0.563648, 2.773147, -0.710205, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 252, 238), m = Enum.Material.SmoothPlastic, st = false }, -- 21
		{ n = "Tooth", s = "Block", z = Vector3.new(0.19164, 0.214186, 0.101457), cf = CFrame.new(0.214186, 2.829512, -0.704559, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 248, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 22
		{ n = "Tooth", s = "Block", z = Vector3.new(0.169094, 0.202913, 0.101457), cf = CFrame.new(0.372007, 2.694236, -0.704559, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 248, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 23
		{ n = "Tongue", s = "Block", z = Vector3.new(0.349462, 0.090184, 0.507283), cf = CFrame.new(0, 2.637871, -0.507294, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 140), m = Enum.Material.SmoothPlastic, st = false }, -- 24
		{ n = "Nose", s = "Block", z = Vector3.new(0.281824, 0.19164, 0.11273), cf = CFrame.new(0, 3.111336, -0.704559, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(96, 168, 190), m = Enum.Material.SmoothPlastic, st = false }, -- 25
		{ n = "Eye", s = "Block", z = Vector3.new(0.462191, 0.462191, 0.056365), cf = CFrame.new(-0.450918, 3.370614, -0.676392, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(244, 248, 252), m = Enum.Material.SmoothPlastic, st = false }, -- 26
		{ n = "Iris", s = "Block", z = Vector3.new(0.326916, 0.326916, 0.045092), cf = CFrame.new(-0.450918, 3.370614, -0.721497, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 214, 70), m = Enum.Material.Neon, st = false, cs = false }, -- 27
		{ n = "Pupil", s = "Block", z = Vector3.new(0.078911, 0.293097, 0.033819), cf = CFrame.new(-0.450918, 3.370614, -0.760956, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(14, 10, 24), m = Enum.Material.SmoothPlastic, st = false }, -- 28
		{ n = "Brow", s = "Block", z = Vector3.new(0.59183, 0.124002, 0.135275), cf = CFrame.new(-0.450918, 3.66371, -0.670746, 0.961262, 0.275637, 0, -0.275637, 0.961262, 0, 0, 0, 1), c = Color3.fromRGB(26, 70, 80), m = Enum.Material.SmoothPlastic, st = false }, -- 29
		{ n = "Eye", s = "Block", z = Vector3.new(0.462191, 0.462191, 0.056365), cf = CFrame.new(0.450918, 3.370614, -0.676392, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(244, 248, 252), m = Enum.Material.SmoothPlastic, st = false }, -- 30
		{ n = "Iris", s = "Block", z = Vector3.new(0.326916, 0.326916, 0.045092), cf = CFrame.new(0.450918, 3.370614, -0.721497, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 214, 70), m = Enum.Material.Neon, st = false, cs = false }, -- 31
		{ n = "Pupil", s = "Block", z = Vector3.new(0.078911, 0.293097, 0.033819), cf = CFrame.new(0.450918, 3.370614, -0.760956, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(14, 10, 24), m = Enum.Material.SmoothPlastic, st = false }, -- 32
		{ n = "Brow", s = "Block", z = Vector3.new(0.59183, 0.124002, 0.135275), cf = CFrame.new(0.450918, 3.66371, -0.670746, 0.961262, -0.275637, 0, 0.275637, 0.961262, 0, 0, 0, 1), c = Color3.fromRGB(26, 70, 80), m = Enum.Material.SmoothPlastic, st = false }, -- 33
		{ n = "Cloud", s = "Block", z = Vector3.new(1.296389, 0.281824, 1.127295), cf = CFrame.new(0, 3.889169, 0.028168, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(172, 186, 212), m = Enum.Material.Plastic }, -- 34
		{ n = "CloudPuff", s = "Block", z = Vector3.new(0.676377, 0.507283, 0.676377), cf = CFrame.new(-0.450918, 4.114628, 0, 0.951057, 0, 0.309017, 0, 1, 0, -0.309017, 0, 0.951057), c = Color3.fromRGB(212, 223, 238), m = Enum.Material.Plastic }, -- 35
		{ n = "CloudPuff", s = "Block", z = Vector3.new(0.676377, 0.563648, 0.676377), cf = CFrame.new(0.422736, 4.142811, -0.028198, 0.965926, 0, -0.258819, 0, 1, 0, 0.258819, 0, 0.965926), c = Color3.fromRGB(236, 242, 250), m = Enum.Material.Plastic }, -- 36
		{ n = "CloudPuff", s = "Block", z = Vector3.new(0.789107, 0.507283, 0.732742), cf = CFrame.new(0, 4.283722, 0.056335, 0.990268, 0, 0.139173, 0, 1, 0, -0.139173, 0, 0.990268), c = Color3.fromRGB(236, 242, 250), m = Enum.Material.Plastic }, -- 37
		{ n = "Bolt", s = "Block", z = Vector3.new(0.169094, 0.51859, 0.090184), cf = CFrame.new(0.930018, 3.649619, -0.084564, -0.792624, 0.609711, 0, -0.609711, -0.792624, 0, 0, 0, 1), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 38
		{ n = "Bolt", s = "Block", z = Vector3.new(0.169094, 0.447887, 0.090184), cf = CFrame.new(0.972292, 3.297339, -0.084564, -0.863779, -0.503871, 0, 0.503871, -0.863779, 0, 0, 0, 1), c = Color3.fromRGB(255, 226, 80), m = Enum.Material.Neon, st = false, cs = false }, -- 39
		{ n = "Drop", s = "Block", z = Vector3.new(0.11273, 0.236732, 0.11273), cf = CFrame.new(-0.986383, 3.66371, -0.225464, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 40
		{ n = "Drop", s = "Block", z = Vector3.new(0.101457, 0.202913, 0.101457), cf = CFrame.new(-1.099113, 3.269157, 0.169067, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 41
		{ n = "Sprout", s = "Block", z = Vector3.new(0.11273, 0.310006, 0.11273), cf = CFrame.new(0.084547, 4.621911, 0.056335, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 42
		{ n = "SproutLeaf", s = "Block", z = Vector3.new(0.507283, 0.078911, 0.253641), cf = CFrame.new(0.084547, 4.819188, 0.056335, 0.939693, -0.34202, 0, 0.34202, 0.939693, 0, 0, 0, 1), c = Color3.fromRGB(78, 176, 128), m = Enum.Material.Plastic }, -- 43
		{ n = "Frill", s = "Block", z = Vector3.new(0.958201, 1.127295, 0.11273), cf = CFrame.new(0, 3.240974, 0.732727, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 150, 110), m = Enum.Material.Plastic }, -- 44
		{ n = "Tail", s = "Block", z = Vector3.new(0.310006, 1.288111, 0.310006), cf = CFrame.new(0, 1.310481, 0.958191, 1, 0, 0, 0, 0.466759, -0.884385, 0, 0.884385, 0.466759), c = Color3.fromRGB(40, 116, 92), m = Enum.Material.Plastic }, -- 45
		{ n = "TailDrop", s = "Block", z = Vector3.new(0.236732, 0.338189, 0.236732), cf = CFrame.new(0, 1.690944, 1.533112, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 46
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 1.059657, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, -0.028182, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Waist", h = 2, a = 2, b = 3, c0 = CFrame.new(0, 0.20855, -0.028182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.4791, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 2, a = 2, b = 6, c0 = CFrame.new(-0.349462, -0.180367, -0.028182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.372007, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 2, a = 2, b = 10, c0 = CFrame.new(0.349462, -0.180367, -0.028182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.372007, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail1", h = 2, a = 2, b = 45, c0 = CFrame.new(0, -0.073274, 0.422736, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.5736, 0, 1, 0, 0, 0, 0.466759, 0.884385, 0, -0.884385, 0.466759) },
		{ k = "Weld", n = "Hold", h = 3, a = 3, b = 4, c0 = CFrame.new(0, -0.11273, -0.558011, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 3, a = 3, b = 8, c0 = CFrame.new(-0.777834, 0.366371, -0.028182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.412282, 0, -0.985622, 0.168964, 0, -0.164057, -0.956998, -0.23925, -0.040425, -0.23581, 0.970958) },
		{ k = "Motor6D", n = "ShoulderL", h = 3, a = 3, b = 12, c0 = CFrame.new(0.777834, 0.366371, -0.028182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.412282, 0, -0.985622, -0.168964, 0, 0.164057, -0.956998, -0.23925, 0.040425, -0.23581, 0.970958) },
		{ k = "Motor6D", n = "Neck", h = 3, a = 3, b = 14, c0 = CFrame.new(0, 0.507283, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.845471, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 0, -0.045092, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 6, a = 6, b = 7, c0 = CFrame.new(0, -0.467827, -0.124002, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 8, a = 8, b = 9, c0 = CFrame.new(-0.001587, 0.564319, -0.020588, -0.985622, 0.168964, 0, -0.164057, -0.956998, -0.23925, -0.040425, -0.23581, 0.970958), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 10, a = 10, b = 11, c0 = CFrame.new(0, -0.467827, -0.124002, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 12, a = 12, b = 13, c0 = CFrame.new(0.001587, 0.564319, -0.020588, -0.985622, -0.168964, 0, 0.164057, -0.956998, -0.23925, 0.040425, -0.23581, 0.970958), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Jaw", h = 14, a = 14, b = 15, c0 = CFrame.new(0, -0.563648, 0.507283, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.152185, 0.563648, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 16, c0 = CFrame.new(0, -0.394553, -0.659468, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 17, c0 = CFrame.new(0, -0.180367, -0.676377, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 18, c0 = CFrame.new(-0.563648, -0.38328, -0.710196, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 19, c0 = CFrame.new(-0.214186, -0.326916, -0.70456, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 21, c0 = CFrame.new(0.563648, -0.38328, -0.710196, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 22, c0 = CFrame.new(0.214186, -0.326916, -0.70456, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 25, c0 = CFrame.new(0, -0.045092, -0.70456, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 26, c0 = CFrame.new(-0.450918, 0.214186, -0.676377, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 29, c0 = CFrame.new(-0.450918, 0.507283, -0.670741, 0.961262, 0.275637, 0, -0.275637, 0.961262, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 30, c0 = CFrame.new(0.450918, 0.214186, -0.676377, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 33, c0 = CFrame.new(0.450918, 0.507283, -0.670741, 0.961262, -0.275637, 0, 0.275637, 0.961262, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Cloud", h = 14, a = 14, b = 34, c0 = CFrame.new(0, 0.59183, 0.028182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.140912, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Frill", h = 14, a = 14, b = 44, c0 = CFrame.new(0, -0.338189, 0.648195, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.422736, -0.084547, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 15, a = 15, b = 20, c0 = CFrame.new(-0.372007, 0.253641, -0.648195, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 15, a = 15, b = 23, c0 = CFrame.new(0.372007, 0.253641, -0.648195, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 15, a = 15, b = 24, c0 = CFrame.new(0, 0.197277, -0.450918, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 26, a = 26, b = 27, c0 = CFrame.new(0, 0, -0.045092, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 27, a = 27, b = 28, c0 = CFrame.new(0, 0, -0.039455, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 30, a = 30, b = 31, c0 = CFrame.new(0, 0, -0.045092, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 31, a = 31, b = 32, c0 = CFrame.new(0, 0, -0.039455, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 35, c0 = CFrame.new(-0.450918, 0.225459, -0.028182, 0.951057, 0, 0.309017, 0, 1, 0, -0.309017, 0, 0.951057), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 36, c0 = CFrame.new(0.422736, 0.253641, -0.056365, 0.965926, 0, -0.258819, 0, 1, 0, 0.258819, 0, 0.965926), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 37, c0 = CFrame.new(0, 0.394553, 0.028182, 0.990268, 0, 0.139173, 0, 1, 0, -0.139173, 0, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 38, c0 = CFrame.new(0.930019, -0.23955, -0.11273, -0.792624, 0.609711, 0, -0.609711, -0.792624, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 39, c0 = CFrame.new(0.972292, -0.59183, -0.11273, -0.863779, -0.503871, 0, 0.503871, -0.863779, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 40, c0 = CFrame.new(-0.986383, -0.225459, -0.253641, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 41, c0 = CFrame.new(-1.099113, -0.620012, 0.140912, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 42, c0 = CFrame.new(0.084547, 0.732742, 0.028182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 42, a = 42, b = 43, c0 = CFrame.new(0, 0.197277, 0, 0.939693, -0.34202, 0, 0.34202, 0.939693, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 45, a = 45, b = 46, c0 = CFrame.new(0, 0.686035, -0.068126, 1, 0, 0, 0, 0.466759, 0.884385, 0, -0.884385, 0.466759), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StormGlow", p = 34, range = 9, brightness = 0.8, color = Color3.new(0.588235, 0.784314, 1), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Drizzle", p = 34, rate = 8, enabled = true, lifetime = NumberRange.new(1, 1.7), speed = NumberRange.new(0, 0.563648), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.124002, 0), NumberSequenceKeypoint.new(1, 0.045092, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.74902, 0.94902, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.7, 1)) }), lightEmission = 0.7, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(70, 70), acceleration = Vector3.new(0, -7.891067, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Bottom, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
