--!strict
--==============================================================================
-- PLANT FORM: Monsoad (Legendary), the Rain event's second family (2026-10-05)
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/Monsoad (Legendary) (tiny)" by a read-only generator on
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
	Source = "Rain Event 2/Monsoad (Legendary) (tiny)", Kind = "plant", Yaw = 0,
	Size = Vector3.new(5.6173, 4.990437, 6.819775), Height = 4.990437, PartCount = 96,
	Base = 1,
	Unit = 1, ModelScale = 0.761899,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(3.352355, 0.15238, 4.114254), cf = CFrame.new(0, 0.07619, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 50, 80), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "Torso", s = "Block", z = Vector3.new(3.047595, 1.523798, 3.199975), cf = CFrame.new(0, 1.828557, 0.152374, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(92, 66, 150), m = Enum.Material.Plastic }, -- 2
		{ n = "Flank", s = "Block", z = Vector3.new(0.07619, 0.838089, 1.980937), cf = CFrame.new(-1.546654, 1.828557, 0.228546, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(158, 118, 206), m = Enum.Material.SmoothPlastic, st = false }, -- 3
		{ n = "Flank", s = "Block", z = Vector3.new(0.07619, 0.838089, 1.980937), cf = CFrame.new(1.546654, 1.828557, 0.228546, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(158, 118, 206), m = Enum.Material.SmoothPlastic, st = false }, -- 4
		{ n = "Wart", s = "Block", z = Vector3.new(0.380949, 0.30476, 0.380949), cf = CFrame.new(-0.990468, 2.704741, -0.609528, 0.939693, 0, 0.34202, 0, 1, 0, -0.34202, 0, 0.939693), c = Color3.fromRGB(132, 100, 194), m = Enum.Material.Plastic }, -- 5
		{ n = "Wart", s = "Block", z = Vector3.new(0.380949, 0.30476, 0.380949), cf = CFrame.new(0.914279, 2.704741, -0.304779, 0.965926, 0, -0.258819, 0, 1, 0, 0.258819, 0, 0.965926), c = Color3.fromRGB(132, 100, 194), m = Enum.Material.Plastic }, -- 6
		{ n = "Wart", s = "Block", z = Vector3.new(0.380949, 0.30476, 0.380949), cf = CFrame.new(-0.685709, 2.704741, 0.990479, 0.819152, 0, 0.573576, 0, 1, 0, -0.573576, 0, 0.819152), c = Color3.fromRGB(132, 100, 194), m = Enum.Material.Plastic }, -- 7
		{ n = "Wart", s = "Block", z = Vector3.new(0.380949, 0.30476, 0.380949), cf = CFrame.new(1.066658, 2.704741, 0.914276, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c = Color3.fromRGB(132, 100, 194), m = Enum.Material.Plastic }, -- 8
		{ n = "Head", s = "Block", z = Vector3.new(2.742836, 1.142848, 1.980937), cf = CFrame.new(0, 2.095222, -2.361877, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(132, 100, 194), m = Enum.Material.Plastic }, -- 9
		{ n = "LowerJaw", s = "Block", z = Vector3.new(2.514266, 0.380949, 1.942842), cf = CFrame.new(0, 1.333323, -2.38092, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(92, 66, 150), m = Enum.Material.Plastic }, -- 10
		{ n = "ThroatSac", s = "Block", z = Vector3.new(1.676177, 0.609519, 1.066658), cf = CFrame.new(0, 0.990469, -2.742828, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 176, 148), m = Enum.Material.SmoothPlastic, st = false }, -- 11
		{ n = "ThroatStripe", s = "Block", z = Vector3.new(1.142848, 0.07619, 0.045714), cf = CFrame.new(0, 1.081897, -3.299011, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(226, 120, 100), m = Enum.Material.SmoothPlastic, st = false }, -- 12
		{ n = "ThroatStripe", s = "Block", z = Vector3.new(1.142848, 0.07619, 0.045714), cf = CFrame.new(0, 0.876184, -3.299011, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(226, 120, 100), m = Enum.Material.SmoothPlastic, st = false }, -- 13
		{ n = "Drop", s = "Block", z = Vector3.new(0.167618, 0.319997, 0.167618), cf = CFrame.new(0, 0.518091, -2.742828, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 14
		{ n = "Mouth", s = "Block", z = Vector3.new(2.361886, 0.319997, 0.060952), cf = CFrame.new(0, 1.523798, -3.367584, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 12, 34), m = Enum.Material.SmoothPlastic, st = false }, -- 15
		{ n = "SmileCorner", s = "Block", z = Vector3.new(0.22857, 0.22857, 0.07619), cf = CFrame.new(-1.234276, 1.691416, -3.367615, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(24, 12, 34), m = Enum.Material.SmoothPlastic, st = false }, -- 16
		{ n = "SmileCorner", s = "Block", z = Vector3.new(0.22857, 0.22857, 0.07619), cf = CFrame.new(1.234276, 1.691416, -3.367584, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(24, 12, 34), m = Enum.Material.SmoothPlastic, st = false }, -- 17
		{ n = "Tooth", s = "Block", z = Vector3.new(0.22857, 0.198094, 0.106666), cf = CFrame.new(-0.914279, 1.58475, -3.40567, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 244, 224), m = Enum.Material.SmoothPlastic, st = false }, -- 18
		{ n = "Tooth", s = "Block", z = Vector3.new(0.22857, 0.198094, 0.106666), cf = CFrame.new(-0.457139, 1.58475, -3.40567, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 244, 224), m = Enum.Material.SmoothPlastic, st = false }, -- 19
		{ n = "Tooth", s = "Block", z = Vector3.new(0.22857, 0.198094, 0.106666), cf = CFrame.new(0, 1.58475, -3.40567, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 244, 224), m = Enum.Material.SmoothPlastic, st = false }, -- 20
		{ n = "Tooth", s = "Block", z = Vector3.new(0.22857, 0.198094, 0.106666), cf = CFrame.new(0.457139, 1.58475, -3.40567, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 244, 224), m = Enum.Material.SmoothPlastic, st = false }, -- 21
		{ n = "Tooth", s = "Block", z = Vector3.new(0.22857, 0.198094, 0.106666), cf = CFrame.new(0.914279, 1.58475, -3.40567, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 244, 224), m = Enum.Material.SmoothPlastic, st = false }, -- 22
		{ n = "Tooth", s = "Block", z = Vector3.new(0.22857, 0.167618, 0.106666), cf = CFrame.new(-0.685709, 1.447608, -3.40567, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 244, 224), m = Enum.Material.SmoothPlastic, st = false }, -- 23
		{ n = "Tooth", s = "Block", z = Vector3.new(0.22857, 0.167618, 0.106666), cf = CFrame.new(-0.22857, 1.447608, -3.40567, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 244, 224), m = Enum.Material.SmoothPlastic, st = false }, -- 24
		{ n = "Tooth", s = "Block", z = Vector3.new(0.22857, 0.167618, 0.106666), cf = CFrame.new(0.22857, 1.447608, -3.40567, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 244, 224), m = Enum.Material.SmoothPlastic, st = false }, -- 25
		{ n = "Tooth", s = "Block", z = Vector3.new(0.22857, 0.167618, 0.106666), cf = CFrame.new(0.685709, 1.447608, -3.40567, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 244, 224), m = Enum.Material.SmoothPlastic, st = false }, -- 26
		{ n = "Tongue", s = "Block", z = Vector3.new(0.609519, 0.106666, 0.685709), cf = CFrame.new(0, 1.539036, -3.619019, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 98, 150), m = Enum.Material.SmoothPlastic, st = false }, -- 27
		{ n = "Tongue", s = "Block", z = Vector3.new(0.571424, 0.609519, 0.121904), cf = CFrame.new(0, 1.2038, -3.961884, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 120, 170), m = Enum.Material.SmoothPlastic, st = false }, -- 28
		{ n = "Tongue", s = "Block", z = Vector3.new(0.07619, 0.457139, 0.045714), cf = CFrame.new(0, 1.2038, -4.038086, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(210, 60, 110), m = Enum.Material.SmoothPlastic, st = false }, -- 29
		{ n = "Nostril", s = "Block", z = Vector3.new(0.243808, 0.121904, 0.243808), cf = CFrame.new(-0.30476, 2.727598, -3.199951, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(68, 48, 118), m = Enum.Material.Plastic }, -- 30
		{ n = "NostrilHole", s = "Block", z = Vector3.new(0.121904, 0.038095, 0.121904), cf = CFrame.new(-0.30476, 2.796169, -3.199951, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 12, 34), m = Enum.Material.SmoothPlastic, st = false }, -- 31
		{ n = "Cheek", s = "Block", z = Vector3.new(0.533329, 0.419044, 0.060952), cf = CFrame.new(-1.066658, 2.133317, -3.382843, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 146, 66), m = Enum.Material.SmoothPlastic, st = false }, -- 32
		{ n = "Freckle", s = "Block", z = Vector3.new(0.091428, 0.091428, 0.045714), cf = CFrame.new(-1.173324, 2.209507, -3.428558, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(214, 96, 40), m = Enum.Material.SmoothPlastic, st = false }, -- 33
		{ n = "Freckle", s = "Block", z = Vector3.new(0.091428, 0.091428, 0.045714), cf = CFrame.new(-0.959992, 2.057127, -3.428528, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(214, 96, 40), m = Enum.Material.SmoothPlastic, st = false }, -- 34
		{ n = "Nostril", s = "Block", z = Vector3.new(0.243808, 0.121904, 0.243808), cf = CFrame.new(0.30476, 2.727598, -3.199982, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(68, 48, 118), m = Enum.Material.Plastic }, -- 35
		{ n = "NostrilHole", s = "Block", z = Vector3.new(0.121904, 0.038095, 0.121904), cf = CFrame.new(0.30476, 2.796169, -3.199982, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 12, 34), m = Enum.Material.SmoothPlastic, st = false }, -- 36
		{ n = "Cheek", s = "Block", z = Vector3.new(0.533329, 0.419044, 0.060952), cf = CFrame.new(1.066658, 2.133317, -3.382812, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 146, 66), m = Enum.Material.SmoothPlastic, st = false }, -- 37
		{ n = "Freckle", s = "Block", z = Vector3.new(0.091428, 0.091428, 0.045714), cf = CFrame.new(0.959992, 2.209507, -3.428528, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(214, 96, 40), m = Enum.Material.SmoothPlastic, st = false }, -- 38
		{ n = "Freckle", s = "Block", z = Vector3.new(0.091428, 0.091428, 0.045714), cf = CFrame.new(1.173324, 2.057127, -3.428528, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(214, 96, 40), m = Enum.Material.SmoothPlastic, st = false }, -- 39
		{ n = "EyeDome", s = "Block", z = Vector3.new(0.990468, 0.761899, 0.990468), cf = CFrame.new(-0.838089, 2.933311, -2.819, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(132, 100, 194), m = Enum.Material.Plastic }, -- 40
		{ n = "EyeSocket", s = "Block", z = Vector3.new(0.761899, 0.685709, 0.07619), cf = CFrame.new(-0.838089, 2.933311, -3.352325, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 146, 66), m = Enum.Material.SmoothPlastic, st = false }, -- 41
		{ n = "Eye", s = "Block", z = Vector3.new(0.639995, 0.548567, 0.07619), cf = CFrame.new(-0.838089, 2.933311, -3.40567, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 246, 255), m = Enum.Material.SmoothPlastic, st = false }, -- 42
		{ n = "Eye", s = "Block", z = Vector3.new(0.487615, 0.472377, 0.060952), cf = CFrame.new(-0.838089, 2.887597, -3.459015, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(240, 60, 170), m = Enum.Material.Neon, st = false, cs = false }, -- 43
		{ n = "Eye", s = "Block", z = Vector3.new(0.380949, 0.350473, 0.053333), cf = CFrame.new(-0.838089, 2.887597, -3.497101, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 170, 224), m = Enum.Material.Neon, st = false, cs = false }, -- 44
		{ n = "Pupil", s = "Block", z = Vector3.new(0.319997, 0.099047, 0.045714), cf = CFrame.new(-0.838089, 2.857121, -3.535187, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(16, 8, 28), m = Enum.Material.SmoothPlastic, st = false }, -- 45
		{ n = "EyeShine", s = "Block", z = Vector3.new(0.091428, 0.091428, 0.038095), cf = CFrame.new(-0.723804, 2.918072, -3.558044, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 46
		{ n = "Lid", s = "Block", z = Vector3.new(0.853326, 0.243808, 0.15238), cf = CFrame.new(-0.838089, 3.16188, -3.580902, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(68, 48, 118), m = Enum.Material.SmoothPlastic, st = false }, -- 47
		{ n = "Lash", s = "Block", z = Vector3.new(0.853326, 0.053333, 0.167618), cf = CFrame.new(-0.838089, 3.036167, -3.580902, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 12, 34), m = Enum.Material.SmoothPlastic, st = false }, -- 48
		{ n = "EyeDome", s = "Block", z = Vector3.new(0.990468, 0.761899, 0.990468), cf = CFrame.new(0.838089, 2.933311, -2.819031, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(132, 100, 194), m = Enum.Material.Plastic }, -- 49
		{ n = "EyeSocket", s = "Block", z = Vector3.new(0.761899, 0.685709, 0.07619), cf = CFrame.new(0.838088, 2.933311, -3.352356, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 146, 66), m = Enum.Material.SmoothPlastic, st = false }, -- 50
		{ n = "Eye", s = "Block", z = Vector3.new(0.639995, 0.548567, 0.07619), cf = CFrame.new(0.838089, 2.933311, -3.405701, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 246, 255), m = Enum.Material.SmoothPlastic, st = false }, -- 51
		{ n = "Eye", s = "Block", z = Vector3.new(0.487615, 0.472377, 0.060952), cf = CFrame.new(0.838089, 2.887597, -3.459045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(240, 60, 170), m = Enum.Material.Neon, st = false, cs = false }, -- 52
		{ n = "Eye", s = "Block", z = Vector3.new(0.380949, 0.350473, 0.053333), cf = CFrame.new(0.838089, 2.887597, -3.497131, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 170, 224), m = Enum.Material.Neon, st = false, cs = false }, -- 53
		{ n = "Pupil", s = "Block", z = Vector3.new(0.319997, 0.099047, 0.045714), cf = CFrame.new(0.838088, 2.857121, -3.535217, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(16, 8, 28), m = Enum.Material.SmoothPlastic, st = false }, -- 54
		{ n = "EyeShine", s = "Block", z = Vector3.new(0.091428, 0.091428, 0.038095), cf = CFrame.new(0.952373, 2.918072, -3.558075, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 55
		{ n = "Lid", s = "Block", z = Vector3.new(0.853326, 0.243808, 0.15238), cf = CFrame.new(0.838089, 3.16188, -3.580933, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(68, 48, 118), m = Enum.Material.SmoothPlastic, st = false }, -- 56
		{ n = "Lash", s = "Block", z = Vector3.new(0.853326, 0.053333, 0.167618), cf = CFrame.new(0.838089, 3.036167, -3.580933, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 12, 34), m = Enum.Material.SmoothPlastic, st = false }, -- 57
		{ n = "UpperArm", s = "Block", z = Vector3.new(0.685709, 0.96229, 0.685709), cf = CFrame.new(-1.599987, 1.676178, -1.028595, -0.980581, -0.188144, -0.055347, 0.196116, -0.940721, -0.276736, 0, -0.282216, 0.959351), c = Color3.fromRGB(68, 48, 118), m = Enum.Material.Plastic }, -- 58
		{ n = "Forearm", s = "Block", z = Vector3.new(0.609519, 0.929367, 0.609519), cf = CFrame.new(-1.676177, 0.914279, -1.219055, -1, 0, 0, 0, -0.980581, -0.196116, 0, -0.196116, 0.980581), c = Color3.fromRGB(92, 66, 150), m = Enum.Material.Plastic }, -- 59
		{ n = "Foot", s = "Block", z = Vector3.new(1.066658, 0.22857, 0.990468), cf = CFrame.new(-1.676177, 0.114286, -1.56192, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(116, 194, 72), m = Enum.Material.Plastic }, -- 60
		{ n = "Toe", s = "Block", z = Vector3.new(0.30476, 0.167618, 0.380949), cf = CFrame.new(-1.942842, 0.08381, -2.209534, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 218, 96), m = Enum.Material.Plastic }, -- 61
		{ n = "Toe", s = "Block", z = Vector3.new(0.30476, 0.167618, 0.380949), cf = CFrame.new(-1.409512, 0.08381, -2.209534, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 218, 96), m = Enum.Material.Plastic }, -- 62
		{ n = "Thigh", s = "Block", z = Vector3.new(0.990468, 1.880327, 0.990468), cf = CFrame.new(-1.790462, 1.599988, 1.714233, -0.743294, -0.415139, 0.52457, 0.668965, -0.461266, 0.582855, 0, 0.784151, 0.62057), c = Color3.fromRGB(92, 66, 150), m = Enum.Material.Plastic }, -- 63
		{ n = "Shin", s = "Block", z = Vector3.new(0.685709, 1.168673, 0.685709), cf = CFrame.new(-1.980937, 0.895231, 2.057098, -0.904819, 0.324176, 0.276067, -0.425797, -0.688875, -0.586642, 0, -0.648353, 0.76134), c = Color3.fromRGB(68, 48, 118), m = Enum.Material.Plastic }, -- 64
		{ n = "Foot", s = "Block", z = Vector3.new(1.066658, 0.22857, 1.523798), cf = CFrame.new(-1.828558, 0.114285, 1.06662, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(116, 194, 72), m = Enum.Material.Plastic }, -- 65
		{ n = "Toe", s = "Block", z = Vector3.new(0.319997, 0.167618, 0.457139), cf = CFrame.new(-2.133317, 0.083809, 0.076141, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 218, 96), m = Enum.Material.Plastic }, -- 66
		{ n = "Toe", s = "Block", z = Vector3.new(0.319997, 0.167618, 0.457139), cf = CFrame.new(-1.523798, 0.083809, 0.076141, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 218, 96), m = Enum.Material.Plastic }, -- 67
		{ n = "UpperArm", s = "Block", z = Vector3.new(0.685709, 0.96229, 0.685709), cf = CFrame.new(1.599987, 1.676178, -1.028564, -0.980581, 0.188144, 0.055347, -0.196116, -0.940721, -0.276736, 0, -0.282216, 0.959351), c = Color3.fromRGB(68, 48, 118), m = Enum.Material.Plastic }, -- 68
		{ n = "Forearm", s = "Block", z = Vector3.new(0.609519, 0.929367, 0.609519), cf = CFrame.new(1.676177, 0.914279, -1.219025, -1, 0, 0, 0, -0.980581, -0.196116, 0, -0.196116, 0.980581), c = Color3.fromRGB(92, 66, 150), m = Enum.Material.Plastic }, -- 69
		{ n = "Foot", s = "Block", z = Vector3.new(1.066658, 0.22857, 0.990468), cf = CFrame.new(1.676177, 0.114286, -1.56189, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(116, 194, 72), m = Enum.Material.Plastic }, -- 70
		{ n = "Toe", s = "Block", z = Vector3.new(0.30476, 0.167618, 0.380949), cf = CFrame.new(1.409513, 0.08381, -2.209503, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 218, 96), m = Enum.Material.Plastic }, -- 71
		{ n = "Toe", s = "Block", z = Vector3.new(0.30476, 0.167618, 0.380949), cf = CFrame.new(1.942842, 0.08381, -2.209503, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 218, 96), m = Enum.Material.Plastic }, -- 72
		{ n = "Thigh", s = "Block", z = Vector3.new(0.990468, 1.880327, 0.990468), cf = CFrame.new(1.790462, 1.599988, 1.714264, -0.743294, 0.415139, -0.52457, -0.668965, -0.461266, 0.582855, 0, 0.784151, 0.62057), c = Color3.fromRGB(92, 66, 150), m = Enum.Material.Plastic }, -- 73
		{ n = "Shin", s = "Block", z = Vector3.new(0.685709, 1.168673, 0.685709), cf = CFrame.new(1.980937, 0.895231, 2.057129, -0.904819, -0.324176, -0.276067, 0.425797, -0.688875, -0.586642, 0, -0.648353, 0.76134), c = Color3.fromRGB(68, 48, 118), m = Enum.Material.Plastic }, -- 74
		{ n = "Foot", s = "Block", z = Vector3.new(1.066658, 0.22857, 1.523798), cf = CFrame.new(1.828557, 0.114285, 1.06665, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(116, 194, 72), m = Enum.Material.Plastic }, -- 75
		{ n = "Toe", s = "Block", z = Vector3.new(0.319997, 0.167618, 0.457139), cf = CFrame.new(1.523798, 0.083809, 0.076172, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 218, 96), m = Enum.Material.Plastic }, -- 76
		{ n = "Toe", s = "Block", z = Vector3.new(0.319997, 0.167618, 0.457139), cf = CFrame.new(2.133317, 0.083809, 0.076172, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 218, 96), m = Enum.Material.Plastic }, -- 77
		{ n = "Stem", s = "Block", z = Vector3.new(0.380949, 1.866652, 0.380949), cf = CFrame.new(0, 3.409497, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(58, 126, 58), m = Enum.Material.Plastic }, -- 78
		{ n = "StemLeaf", s = "Block", z = Vector3.new(0.609519, 0.07619, 0.380949), cf = CFrame.new(0.457139, 3.428545, 0.304749, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(116, 194, 72), m = Enum.Material.Plastic }, -- 79
		{ n = "StemLeaf", s = "Block", z = Vector3.new(0.609519, 0.07619, 0.380949), cf = CFrame.new(-0.457139, 3.428545, 0.304749, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(116, 194, 72), m = Enum.Material.Plastic }, -- 80
		{ n = "Canopy", s = "Block", z = Vector3.new(3.199975, 0.22857, 3.199975), cf = CFrame.new(0, 4.380918, 0.304749, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(116, 194, 72), m = Enum.Material.Plastic }, -- 81
		{ n = "Canopy", s = "Block", z = Vector3.new(2.590456, 0.22857, 2.590456), cf = CFrame.new(0, 4.586631, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 218, 96), m = Enum.Material.Plastic }, -- 82
		{ n = "CanopyKnob", s = "Block", z = Vector3.new(0.685709, 0.30476, 0.685709), cf = CFrame.new(0, 4.838058, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 146, 66), m = Enum.Material.Plastic }, -- 83
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.30476, 0.038095, 2.438076), cf = CFrame.new(-0.914279, 4.719963, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 70, 70), m = Enum.Material.Neon, st = false, cs = false }, -- 84
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.30476, 0.038095, 2.438076), cf = CFrame.new(-0.609519, 4.719963, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 150, 50), m = Enum.Material.Neon, st = false, cs = false }, -- 85
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.30476, 0.038095, 2.438076), cf = CFrame.new(-0.30476, 4.719963, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 232, 60), m = Enum.Material.Neon, st = false, cs = false }, -- 86
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.30476, 0.038095, 2.438076), cf = CFrame.new(0, 4.719963, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(80, 232, 112), m = Enum.Material.Neon, st = false, cs = false }, -- 87
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.30476, 0.038095, 2.438076), cf = CFrame.new(0.304759, 4.719963, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(70, 172, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 88
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.30476, 0.038095, 2.438076), cf = CFrame.new(0.609519, 4.719963, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(112, 100, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 89
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.30476, 0.038095, 2.438076), cf = CFrame.new(0.914279, 4.719963, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(192, 100, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 90
		{ n = "Drop", s = "Block", z = Vector3.new(0.15238, 0.457139, 0.15238), cf = CFrame.new(2.171411, 4.038064, 0.304749, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 91
		{ n = "Drop", s = "Block", z = Vector3.new(0.15238, 0.342854, 0.15238), cf = CFrame.new(-2.171411, 4.095206, 0.304718, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 92
		{ n = "Drop", s = "Block", z = Vector3.new(0.15238, 0.419044, 0.15238), cf = CFrame.new(0, 4.057111, 2.476166, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 93
		{ n = "Drop", s = "Block", z = Vector3.new(0.15238, 0.380949, 0.15238), cf = CFrame.new(0, 4.076159, -1.866669, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 94
		{ n = "Drop", s = "Block", z = Vector3.new(0.15238, 0.30476, 0.15238), cf = CFrame.new(1.142848, 4.114254, 1.295197, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 95
		{ n = "Drop", s = "Block", z = Vector3.new(0.15238, 0.319997, 0.15238), cf = CFrame.new(-1.142848, 4.106635, -0.68573, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(130, 222, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 96
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 1.752367, 0.15238, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 3, c0 = CFrame.new(-1.546654, 0, 0.07619, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 4, c0 = CFrame.new(1.546654, 0, 0.07619, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 5, c0 = CFrame.new(-0.990468, 0.876184, -0.761899, 0.939693, 0, 0.34202, 0, 1, 0, -0.34202, 0, 0.939693), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 6, c0 = CFrame.new(0.914279, 0.876184, -0.457139, 0.965926, 0, -0.258819, 0, 1, 0, 0.258819, 0, 0.965926), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 7, c0 = CFrame.new(-0.685709, 0.876184, 0.838089, 0.819152, 0, 0.573576, 0, 1, 0, -0.573576, 0, 0.819152), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 8, c0 = CFrame.new(1.066658, 0.876184, 0.761899, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 2, a = 2, b = 9, c0 = CFrame.new(0, 0.22857, -1.599987, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.038095, 0.914279, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 2, a = 2, b = 58, c0 = CFrame.new(-1.523798, 0.22857, -1.066658, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.404955, 0, -0.980581, 0.196116, 0, -0.188144, -0.940721, -0.282216, -0.055347, -0.276736, 0.959351) },
		{ k = "Motor6D", n = "HipR", h = 2, a = 2, b = 63, c0 = CFrame.new(-1.447608, 0.15238, 0.914279, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.825878, 0, -0.743294, 0.668965, 0, -0.415139, -0.461266, 0.784151, 0.52457, 0.582855, 0.62057) },
		{ k = "Motor6D", n = "ShoulderL", h = 2, a = 2, b = 68, c0 = CFrame.new(1.523798, 0.22857, -1.066658, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.404955, 0, -0.980581, -0.196116, 0, 0.188144, -0.940721, -0.282216, 0.055347, -0.276736, 0.959351) },
		{ k = "Motor6D", n = "HipL", h = 2, a = 2, b = 73, c0 = CFrame.new(1.447608, 0.15238, 0.914279, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.825878, 0, -0.743294, -0.668965, 0, 0.415139, -0.461266, 0.784151, -0.52457, 0.582855, 0.62057) },
		{ k = "Motor6D", n = "Stem", h = 2, a = 2, b = 78, c0 = CFrame.new(0, 0.685709, 0.15238, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.895231, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Jaw", h = 9, a = 9, b = 10, c0 = CFrame.new(0, -0.571424, 0.914279, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.190475, 0.933326, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 15, c0 = CFrame.new(0, -0.571424, -1.005706, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 16, c0 = CFrame.new(-1.234276, -0.403806, -1.005706, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 17, c0 = CFrame.new(1.234276, -0.403806, -1.005706, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 18, c0 = CFrame.new(-0.914279, -0.510472, -1.043801, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 19, c0 = CFrame.new(-0.457139, -0.510472, -1.043801, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 20, c0 = CFrame.new(0, -0.510472, -1.043801, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 21, c0 = CFrame.new(0.457139, -0.510472, -1.043801, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 22, c0 = CFrame.new(0.914279, -0.510472, -1.043801, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 30, c0 = CFrame.new(-0.30476, 0.632376, -0.838089, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 32, c0 = CFrame.new(-1.066658, 0.038095, -1.020944, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 35, c0 = CFrame.new(0.30476, 0.632376, -0.838089, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 9, a = 9, b = 37, c0 = CFrame.new(1.066658, 0.038095, -1.020944, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "EyeR", h = 9, a = 9, b = 40, c0 = CFrame.new(-0.838089, 0.838089, -0.457139, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "EyeL", h = 9, a = 9, b = 49, c0 = CFrame.new(0.838089, 0.838089, -0.457139, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 10, a = 10, b = 11, c0 = CFrame.new(0, -0.342854, -0.361902, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 10, a = 10, b = 23, c0 = CFrame.new(-0.685709, 0.114285, -1.024754, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 10, a = 10, b = 24, c0 = CFrame.new(-0.22857, 0.114285, -1.024754, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 10, a = 10, b = 25, c0 = CFrame.new(0.22857, 0.114285, -1.024754, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 10, a = 10, b = 26, c0 = CFrame.new(0.685709, 0.114285, -1.024754, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tongue", h = 10, a = 10, b = 27, c0 = CFrame.new(0, 0.205713, -0.895231, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.342854, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 12, c0 = CFrame.new(0, 0.091428, -0.556186, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 13, c0 = CFrame.new(0, -0.114285, -0.556186, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 14, c0 = CFrame.new(0, -0.472377, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "TongueTip", h = 27, a = 27, b = 28, c0 = CFrame.new(0, -0.015238, -0.342854, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.319997, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 28, a = 28, b = 29, c0 = CFrame.new(0, 0, -0.07619, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 30, a = 30, b = 31, c0 = CFrame.new(0, 0.068571, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 32, a = 32, b = 33, c0 = CFrame.new(-0.106666, 0.07619, -0.045714, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 32, a = 32, b = 34, c0 = CFrame.new(0.106666, -0.07619, -0.045714, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 35, a = 35, b = 36, c0 = CFrame.new(0, 0.068571, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 37, a = 37, b = 38, c0 = CFrame.new(-0.106666, 0.07619, -0.045714, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 37, a = 37, b = 39, c0 = CFrame.new(0.106666, -0.07619, -0.045714, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 40, a = 40, b = 41, c0 = CFrame.new(0, 0, -0.533329, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 40, a = 40, b = 42, c0 = CFrame.new(0, 0, -0.586662, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidR", h = 40, a = 40, b = 47, c0 = CFrame.new(0, 0.22857, -0.761899, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 42, a = 42, b = 43, c0 = CFrame.new(0, -0.045714, -0.053333, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 43, a = 43, b = 44, c0 = CFrame.new(0, 0, -0.038095, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 44, a = 44, b = 45, c0 = CFrame.new(0, -0.030476, -0.038095, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 45, a = 45, b = 46, c0 = CFrame.new(0.114285, 0.060952, -0.022857, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 47, a = 47, b = 48, c0 = CFrame.new(0, -0.125713, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 49, a = 49, b = 50, c0 = CFrame.new(0, 0, -0.533329, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 49, a = 49, b = 51, c0 = CFrame.new(0, 0, -0.586662, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidL", h = 49, a = 49, b = 56, c0 = CFrame.new(0, 0.22857, -0.761899, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 51, a = 51, b = 52, c0 = CFrame.new(0, -0.045714, -0.053333, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 52, a = 52, b = 53, c0 = CFrame.new(0, 0, -0.038095, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 53, a = 53, b = 54, c0 = CFrame.new(0, -0.030476, -0.038095, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 55, c0 = CFrame.new(0.114285, 0.060952, -0.022857, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 56, a = 56, b = 57, c0 = CFrame.new(0, -0.125713, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ElbowR", h = 58, a = 58, b = 59, c0 = CFrame.new(0, 0.404955, 0, -0.980581, 0.196116, 0, -0.188144, -0.940721, -0.282216, -0.055347, -0.276736, 0.959351), c1 = CFrame.new(0, -0.388494, 0, -1, 0, 0, 0, -0.980581, -0.196116, 0, -0.196116, 0.980581) },
		{ k = "Motor6D", n = "WristR", h = 59, a = 59, b = 60, c0 = CFrame.new(0, 0.388494, 0, -1, 0, 0, 0, -0.980581, -0.196116, 0, -0.196116, 0.980581), c1 = CFrame.new(0, 0.419044, 0.266665, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 60, a = 60, b = 61, c0 = CFrame.new(-0.266665, -0.030476, -0.647614, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 60, a = 60, b = 62, c0 = CFrame.new(0.266665, -0.030476, -0.647614, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeR", h = 63, a = 63, b = 64, c0 = CFrame.new(0, 0.825878, 0, -0.743294, 0.668965, 0, -0.415139, -0.461266, 0.784151, 0.52457, 0.582855, 0.62057), c1 = CFrame.new(0, -0.470052, 0, -0.904819, -0.425797, 0, 0.324176, -0.688875, -0.648353, 0.276067, -0.586642, 0.76134) },
		{ k = "Motor6D", n = "AnkleR", h = 64, a = 64, b = 65, c0 = CFrame.new(0, 0.470052, 0, -0.904819, -0.425797, 0, 0.324176, -0.688875, -0.648353, 0.276067, -0.586642, 0.76134), c1 = CFrame.new(0, 0.457139, 0.685709, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 65, a = 65, b = 66, c0 = CFrame.new(-0.30476, -0.030476, -0.990468, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 65, a = 65, b = 67, c0 = CFrame.new(0.30476, -0.030476, -0.990468, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ElbowL", h = 68, a = 68, b = 69, c0 = CFrame.new(0, 0.404955, 0, -0.980581, -0.196116, 0, 0.188144, -0.940721, -0.282216, 0.055347, -0.276736, 0.959351), c1 = CFrame.new(0, -0.388494, 0, -1, 0, 0, 0, -0.980581, -0.196116, 0, -0.196116, 0.980581) },
		{ k = "Motor6D", n = "WristL", h = 69, a = 69, b = 70, c0 = CFrame.new(0, 0.388494, 0, -1, 0, 0, 0, -0.980581, -0.196116, 0, -0.196116, 0.980581), c1 = CFrame.new(0, 0.419044, 0.266665, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 70, a = 70, b = 71, c0 = CFrame.new(-0.266665, -0.030476, -0.647614, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 70, a = 70, b = 72, c0 = CFrame.new(0.266665, -0.030476, -0.647614, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeL", h = 73, a = 73, b = 74, c0 = CFrame.new(0, 0.825878, 0, -0.743294, -0.668965, 0, 0.415139, -0.461266, 0.784151, -0.52457, 0.582855, 0.62057), c1 = CFrame.new(0, -0.470052, 0, -0.904819, 0.425797, 0, -0.324176, -0.688875, -0.648353, -0.276067, -0.586642, 0.76134) },
		{ k = "Motor6D", n = "AnkleL", h = 74, a = 74, b = 75, c0 = CFrame.new(0, 0.470052, 0, -0.904819, 0.425797, 0, -0.324176, -0.688875, -0.648353, -0.276067, -0.586642, 0.76134), c1 = CFrame.new(0, 0.457139, 0.685709, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 75, a = 75, b = 76, c0 = CFrame.new(-0.30476, -0.030476, -0.990468, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 75, a = 75, b = 77, c0 = CFrame.new(0.30476, -0.030476, -0.990468, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 78, a = 78, b = 79, c0 = CFrame.new(0.457139, 0.019047, 0, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 78, a = 78, b = 80, c0 = CFrame.new(-0.457139, 0.019047, 0, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Canopy", h = 78, a = 78, b = 81, c0 = CFrame.new(0, 0.895231, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.07619, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107) },
		{ k = "Weld", n = "Hold", h = 81, a = 81, b = 82, c0 = CFrame.new(0, 0.205713, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 81, a = 81, b = 91, c0 = CFrame.new(1.53542, -0.342854, 1.53542, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 81, a = 81, b = 92, c0 = CFrame.new(-1.53542, -0.285712, -1.53542, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 81, a = 81, b = 93, c0 = CFrame.new(-1.53542, -0.323807, 1.53542, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 81, a = 81, b = 94, c0 = CFrame.new(1.53542, -0.30476, -1.53542, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 81, a = 81, b = 95, c0 = CFrame.new(0.107748, -0.266665, 1.508483, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 81, a = 81, b = 96, c0 = CFrame.new(-0.107748, -0.274284, -1.508483, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 82, a = 82, b = 83, c0 = CFrame.new(0, 0.251427, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 82, a = 82, b = 84, c0 = CFrame.new(-0.914279, 0.133332, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 82, a = 82, b = 85, c0 = CFrame.new(-0.609519, 0.133332, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 82, a = 82, b = 86, c0 = CFrame.new(-0.30476, 0.133332, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 82, a = 82, b = 87, c0 = CFrame.new(0, 0.133332, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 82, a = 82, b = 88, c0 = CFrame.new(0.30476, 0.133332, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 82, a = 82, b = 89, c0 = CFrame.new(0.609519, 0.133332, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 82, a = 82, b = 90, c0 = CFrame.new(0.914279, 0.133332, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "MonsoonGlow", p = 82, range = 10, brightness = 0.7, color = Color3.new(1, 0.745098, 0.901961), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Downpour", p = 82, rate = 12, enabled = true, lifetime = NumberRange.new(1.1, 1.8), speed = NumberRange.new(0, 0.761899), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.198094, 0), NumberSequenceKeypoint.new(1, 0.07619, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.74902, 0.94902, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.4, 0.7, 1)) }), lightEmission = 0.7, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(20, 20), acceleration = Vector3.new(0, -12.19038, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Bottom, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
