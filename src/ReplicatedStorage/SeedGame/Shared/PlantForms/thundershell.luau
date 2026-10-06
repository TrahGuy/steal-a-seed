--!strict
--==============================================================================
-- PLANT FORM: Thundershell (Legendary), the Rain event's second family (2026-10-05)
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/Thundershell (tiny)(Legendary)" by a read-only generator on
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
	Source = "Rain Event 2/Thundershell (tiny)(Legendary)", Kind = "plant", Yaw = 0,
	Size = Vector3.new(3.277184, 4.968073, 9.097107), Height = 4.968073, PartCount = 79,
	Base = 1,
	Unit = 1, ModelScale = 0.506946,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(3.041677, 0.101389, 4.05557), cf = CFrame.new(0, 0.050695, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 80, 70), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "Sole", s = "Block", z = Vector3.new(2.230563, 0.354862, 5.779187), cf = CFrame.new(0, 0.177431, -0.354858, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(206, 226, 160), m = Enum.Material.Plastic }, -- 2
		{ n = "Mantle", s = "Block", z = Vector3.new(2.331953, 0.760419, 3.650012), cf = CFrame.new(0, 0.735072, 0.760437, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 134, 80), m = Enum.Material.Plastic }, -- 3
		{ n = "Neck", s = "Block", z = Vector3.new(1.723617, 1.216671, 1.216671), cf = CFrame.new(0, 0.963198, -1.622223, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 134, 80), m = Enum.Material.Plastic }, -- 4
		{ n = "Head", s = "Block", z = Vector3.new(1.825006, 1.216671, 1.31806), cf = CFrame.new(0, 1.672923, -2.382629, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(112, 178, 100), m = Enum.Material.Plastic }, -- 5
		{ n = "Jaw", s = "Block", z = Vector3.new(1.723617, 0.811114, 1.31806), cf = CFrame.new(0, 0.65903, -2.382629, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 134, 80), m = Enum.Material.Plastic }, -- 6
		{ n = "Tail", s = "Block", z = Vector3.new(1.622228, 0.709725, 1.723617), cf = CFrame.new(0, 0.354862, 3.396545, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 134, 80), m = Enum.Material.Plastic }, -- 7
		{ n = "Tail", s = "Block", z = Vector3.new(1.013892, 0.506946, 1.115282), cf = CFrame.new(0, 0.253473, 4.562531, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(112, 178, 100), m = Enum.Material.Plastic }, -- 8
		{ n = "TailStem", s = "Block", z = Vector3.new(0.253473, 0.886772, 0.253473), cf = CFrame.new(0, 0.861809, 4.866699, 1, 0, 0, 0, 0.970142, -0.242536, 0, 0.242536, 0.970142), c = Color3.fromRGB(40, 92, 62), m = Enum.Material.Plastic }, -- 9
		{ n = "TailBud", s = "Block", z = Vector3.new(0.557641, 0.557641, 0.557641), cf = CFrame.new(0, 1.520839, 5.018768, 1, 0, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 10
		{ n = "Shell", s = "Block", z = Vector3.new(1.723617, 1.469888, 3.548623), cf = CFrame.new(0, 2.63612, 0.709747, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 56, 128), m = Enum.Material.Plastic }, -- 11
		{ n = "Shell", s = "Block", z = Vector3.new(1.662784, 1.469888, 3.548623), cf = CFrame.new(0, 2.63612, 0.709747, 1, 0, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107), c = Color3.fromRGB(38, 32, 82), m = Enum.Material.Plastic }, -- 12
		{ n = "Shell", s = "Block", z = Vector3.new(1.723617, 1.469888, 3.548623), cf = CFrame.new(0, 2.63612, 0.709747, 1, 0, 0, 0, 0, -1, 0, 1, 0), c = Color3.fromRGB(66, 56, 128), m = Enum.Material.Plastic }, -- 13
		{ n = "Shell", s = "Block", z = Vector3.new(1.662784, 1.469888, 3.548623), cf = CFrame.new(0, 2.63612, 0.709747, 1, 0, 0, 0, -0.707107, -0.707107, 0, 0.707107, -0.707107), c = Color3.fromRGB(38, 32, 82), m = Enum.Material.Plastic }, -- 14
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 1.750449, 0.111528), cf = CFrame.new(-0.887156, 1.967711, -0.181183, 0, 0, 1, -0.478062, 0.878326, 0, -0.878326, -0.478062, 0), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 15
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 1.540261, 0.111528), cf = CFrame.new(-0.887156, 3.193953, -0.083344, 0, 0, 1, 0.687608, 0.726082, 0, -0.726082, 0.687608, 0), c = Color3.fromRGB(104, 92, 176), m = Enum.Material.Plastic }, -- 16
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 1.357281, 0.111528), cf = CFrame.new(-0.887156, 3.44281, 0.958252, 0, 0, 1, 0.903028, -0.429582, 0, 0.429582, 0.903028, 0), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 17
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 1.197987, 0.111528), cf = CFrame.new(-0.887156, 2.647385, 1.444489, 0, 0, 1, -0.129506, -0.991579, 0, 0.991579, -0.129506, 0), c = Color3.fromRGB(104, 92, 176), m = Enum.Material.Plastic }, -- 18
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 1.059315, 0.111528), cf = CFrame.new(-0.887156, 2.030825, 0.916718, 0, 0, 1, -0.983067, -0.183247, 0, 0.183247, -0.983067, 0), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 19
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 0.938593, 0.111528), cf = CFrame.new(-0.887156, 2.301916, 0.264282, 0, 0, 1, -0.478062, 0.878326, 0, -0.878326, -0.478062, 0), c = Color3.fromRGB(104, 92, 176), m = Enum.Material.Plastic }, -- 20
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 1.750449, 0.111528), cf = CFrame.new(0.887156, 1.967711, -0.181183, 0, 0, 1, -0.478062, 0.878326, 0, -0.878326, -0.478062, 0), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 21
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 1.540261, 0.111528), cf = CFrame.new(0.887156, 3.193953, -0.083344, 0, 0, 1, 0.687608, 0.726082, 0, -0.726082, 0.687608, 0), c = Color3.fromRGB(104, 92, 176), m = Enum.Material.Plastic }, -- 22
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 1.357281, 0.111528), cf = CFrame.new(0.887156, 3.44281, 0.958252, 0, 0, 1, 0.903028, -0.429582, 0, 0.429582, 0.903028, 0), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 23
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 1.197987, 0.111528), cf = CFrame.new(0.887156, 2.647385, 1.444489, 0, 0, 1, -0.129506, -0.991579, 0, 0.991579, -0.129506, 0), c = Color3.fromRGB(104, 92, 176), m = Enum.Material.Plastic }, -- 24
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 1.059315, 0.111528), cf = CFrame.new(0.887156, 2.030825, 0.916718, 0, 0, 1, -0.983067, -0.183247, 0, 0.183247, -0.983067, 0), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 25
		{ n = "ShellArm", s = "Block", z = Vector3.new(0.253473, 0.938593, 0.111528), cf = CFrame.new(0.887156, 2.301916, 0.264282, 0, 0, 1, -0.478062, 0.878326, 0, -0.878326, -0.478062, 0), c = Color3.fromRGB(104, 92, 176), m = Enum.Material.Plastic }, -- 26
		{ n = "ShellBoss", s = "Block", z = Vector3.new(0.557641, 0.557641, 0.304168), cf = CFrame.new(-0.861809, 2.63612, 0.709747, 1, 0, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 27
		{ n = "ShellBoss", s = "Block", z = Vector3.new(0.557641, 0.557641, 0.304168), cf = CFrame.new(0.861809, 2.63612, 0.709747, 1, 0, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 28
		{ n = "ShellBolt", s = "Block", z = Vector3.new(0.212917, 1.210193, 0.223056), cf = CFrame.new(-0.887156, 3.776749, 0.760437, 0, 0, 1, 0.533993, -0.845489, 0, 0.845489, 0.533993, 0), c = Color3.fromRGB(255, 232, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 29
		{ n = "ShellBolt", s = "Block", z = Vector3.new(0.212917, 1.155885, 0.223056), cf = CFrame.new(-0.887156, 2.864246, 0.735107, 0, 0, 1, -0.60745, -0.794358, 0, 0.794358, -0.60745, 0), c = Color3.fromRGB(255, 232, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 30
		{ n = "ShellBolt", s = "Block", z = Vector3.new(0.212917, 1.296063, 0.223056), cf = CFrame.new(-0.887156, 1.875701, 0.659058, 0, 0, 1, 0.413803, -0.910366, 0, 0.910366, 0.413803, 0), c = Color3.fromRGB(255, 232, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 31
		{ n = "ShellBolt", s = "Block", z = Vector3.new(0.212917, 1.210193, 0.223056), cf = CFrame.new(0.887156, 3.776749, 0.659058, 0, 0, 1, -0.533993, -0.845489, 0, 0.845489, -0.533993, 0), c = Color3.fromRGB(255, 232, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 32
		{ n = "ShellBolt", s = "Block", z = Vector3.new(0.212917, 1.155885, 0.223056), cf = CFrame.new(0.887156, 2.864246, 0.684387, 0, 0, 1, 0.60745, -0.794358, 0, 0.794358, 0.60745, 0), c = Color3.fromRGB(255, 232, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 33
		{ n = "ShellBolt", s = "Block", z = Vector3.new(0.212917, 1.296063, 0.223056), cf = CFrame.new(0.887156, 1.875701, 0.760437, 0, 0, 1, -0.413803, -0.910366, 0, 0.910366, -0.413803, 0), c = Color3.fromRGB(255, 232, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 34
		{ n = "RainCrystal", s = "Block", z = Vector3.new(0.354862, 0.608335, 0.354862), cf = CFrame.new(0, 3.998288, -0.652435, 0.707107, 0, 0.707107, -0.5, 0.707107, 0.5, -0.5, -0.707107, 0.5), c = Color3.fromRGB(70, 170, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 35
		{ n = "RainCrystal", s = "Block", z = Vector3.new(0.354862, 0.811114, 0.354862), cf = CFrame.new(0, 4.562516, 0.709747, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(190, 235, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 36
		{ n = "RainCrystal", s = "Block", z = Vector3.new(0.354862, 0.608335, 0.354862), cf = CFrame.new(0, 3.998288, 2.07193, 0.707107, 0, 0.707107, 0.5, 0.707107, -0.5, -0.5, 0.707107, 0.5), c = Color3.fromRGB(70, 170, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 37
		{ n = "FootFrill", s = "Block", z = Vector3.new(0.557641, 0.081111, 1.115282), cf = CFrame.new(-1.368755, 0.278821, -0.202789, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(112, 178, 100), m = Enum.Material.Plastic }, -- 38
		{ n = "FootFrill", s = "Block", z = Vector3.new(0.557641, 0.081111, 1.115282), cf = CFrame.new(-1.368755, 0.278821, 1.368744, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(150, 205, 104), m = Enum.Material.Plastic }, -- 39
		{ n = "FootFrill", s = "Block", z = Vector3.new(0.557641, 0.081111, 1.115282), cf = CFrame.new(1.368755, 0.278821, -0.202789, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(112, 178, 100), m = Enum.Material.Plastic }, -- 40
		{ n = "FootFrill", s = "Block", z = Vector3.new(0.557641, 0.081111, 1.115282), cf = CFrame.new(1.368755, 0.278821, 1.368744, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(150, 205, 104), m = Enum.Material.Plastic }, -- 41
		{ n = "EyeStalk", s = "Block", z = Vector3.new(0.430904, 0.946499, 0.430904), cf = CFrame.new(-0.671703, 2.560079, -2.712158, 0.986394, -0.141478, -0.083732, 0.164399, 0.848868, 0.502391, 0, -0.509321, 0.860577), c = Color3.fromRGB(66, 134, 80), m = Enum.Material.Plastic }, -- 42
		{ n = "Eyeball", s = "Block", z = Vector3.new(0.963198, 0.963198, 0.861809), cf = CFrame.new(-0.785766, 3.244456, -3.041687, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(112, 178, 100), m = Enum.Material.Plastic }, -- 43
		{ n = "EyePetal", s = "Block", z = Vector3.new(0.354862, 0.532293, 0.121667), cf = CFrame.new(-0.274953, 3.755269, -2.990997, 0.707107, 0.707107, 0, -0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 44
		{ n = "EyePetal", s = "Block", z = Vector3.new(0.354862, 0.532293, 0.121667), cf = CFrame.new(-1.296578, 3.755269, -2.990997, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(255, 160, 40), m = Enum.Material.Plastic }, -- 45
		{ n = "EyePetal", s = "Block", z = Vector3.new(0.354862, 0.532293, 0.121667), cf = CFrame.new(-1.296578, 2.733643, -2.990997, -0.707107, -0.707107, 0, 0.707107, -0.707107, 0, 0, 0, 1), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 46
		{ n = "EyePetal", s = "Block", z = Vector3.new(0.354862, 0.532293, 0.121667), cf = CFrame.new(-0.274953, 2.733643, -2.990997, -0.707107, 0.707107, 0, -0.707107, -0.707107, 0, 0, 0, 1), c = Color3.fromRGB(255, 160, 40), m = Enum.Material.Plastic }, -- 47
		{ n = "Eye", s = "Block", z = Vector3.new(0.811114, 0.811114, 0.050695), cf = CFrame.new(-0.785766, 3.244456, -3.497925, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 248, 240), m = Enum.Material.SmoothPlastic, st = false }, -- 48
		{ n = "Eye", s = "Block", z = Vector3.new(0.405557, 0.405557, 0.040556), cf = CFrame.new(-0.785766, 3.244456, -3.543549, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(255, 232, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 49
		{ n = "Pupil", s = "Block", z = Vector3.new(0.101389, 0.223338, 0.030417), cf = CFrame.new(-0.785766, 3.310359, -3.584106, -0.83205, 0.5547, 0, -0.5547, -0.83205, 0, 0, 0, 1), c = Color3.fromRGB(24, 16, 26), m = Enum.Material.SmoothPlastic, st = false }, -- 50
		{ n = "Pupil", s = "Block", z = Vector3.new(0.101389, 0.240527, 0.030417), cf = CFrame.new(-0.785766, 3.148136, -3.584106, -0.861934, -0.50702, 0, 0.50702, -0.861934, 0, 0, 0, 1), c = Color3.fromRGB(24, 16, 26), m = Enum.Material.SmoothPlastic, st = false }, -- 51
		{ n = "EyeLid", s = "Block", z = Vector3.new(1.115282, 0.314307, 0.152084), cf = CFrame.new(-0.785766, 3.579041, -3.584106, 0.970296, 0.241922, 0, -0.241922, 0.970296, 0, 0, 0, 1), c = Color3.fromRGB(40, 92, 62), m = Enum.Material.SmoothPlastic, st = false }, -- 52
		{ n = "EyeStalk", s = "Block", z = Vector3.new(0.430904, 0.946499, 0.430904), cf = CFrame.new(0.671703, 2.560079, -2.712158, 0.986394, 0.141478, 0.083732, -0.164399, 0.848868, 0.502391, 0, -0.509321, 0.860577), c = Color3.fromRGB(66, 134, 80), m = Enum.Material.Plastic }, -- 53
		{ n = "Eyeball", s = "Block", z = Vector3.new(0.963198, 0.963198, 0.861809), cf = CFrame.new(0.785766, 3.244456, -3.041687, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(112, 178, 100), m = Enum.Material.Plastic }, -- 54
		{ n = "EyePetal", s = "Block", z = Vector3.new(0.354862, 0.532293, 0.121667), cf = CFrame.new(1.296578, 3.755269, -2.990997, 0.707107, 0.707107, 0, -0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 55
		{ n = "EyePetal", s = "Block", z = Vector3.new(0.354862, 0.532293, 0.121667), cf = CFrame.new(0.274953, 3.755269, -2.990997, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(255, 160, 40), m = Enum.Material.Plastic }, -- 56
		{ n = "EyePetal", s = "Block", z = Vector3.new(0.354862, 0.532293, 0.121667), cf = CFrame.new(0.274953, 2.733643, -2.990997, -0.707107, -0.707107, 0, 0.707107, -0.707107, 0, 0, 0, 1), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 57
		{ n = "EyePetal", s = "Block", z = Vector3.new(0.354862, 0.532293, 0.121667), cf = CFrame.new(1.296578, 2.733643, -2.990997, -0.707107, 0.707107, 0, -0.707107, -0.707107, 0, 0, 0, 1), c = Color3.fromRGB(255, 160, 40), m = Enum.Material.Plastic }, -- 58
		{ n = "Eye", s = "Block", z = Vector3.new(0.811114, 0.811114, 0.050695), cf = CFrame.new(0.785766, 3.244456, -3.497925, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 248, 240), m = Enum.Material.SmoothPlastic, st = false }, -- 59
		{ n = "Eye", s = "Block", z = Vector3.new(0.405557, 0.405557, 0.040556), cf = CFrame.new(0.785766, 3.244456, -3.543549, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(255, 232, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 60
		{ n = "Pupil", s = "Block", z = Vector3.new(0.101389, 0.223338, 0.030417), cf = CFrame.new(0.785766, 3.310359, -3.584106, -0.83205, -0.5547, 0, 0.5547, -0.83205, 0, 0, 0, 1), c = Color3.fromRGB(24, 16, 26), m = Enum.Material.SmoothPlastic, st = false }, -- 61
		{ n = "Pupil", s = "Block", z = Vector3.new(0.101389, 0.240527, 0.030417), cf = CFrame.new(0.785766, 3.148136, -3.584106, -0.861934, 0.50702, 0, -0.50702, -0.861934, 0, 0, 0, 1), c = Color3.fromRGB(24, 16, 26), m = Enum.Material.SmoothPlastic, st = false }, -- 62
		{ n = "EyeLid", s = "Block", z = Vector3.new(1.115282, 0.314307, 0.152084), cf = CFrame.new(0.785766, 3.579041, -3.584106, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c = Color3.fromRGB(40, 92, 62), m = Enum.Material.SmoothPlastic, st = false }, -- 63
		{ n = "Brow", s = "Block", z = Vector3.new(0.963198, 0.228126, 0.27882), cf = CFrame.new(-0.481599, 2.119035, -3.143036, 0.970296, 0.241922, 0, -0.241922, 0.970296, 0, 0, 0, 1), c = Color3.fromRGB(40, 92, 62), m = Enum.Material.SmoothPlastic, st = false }, -- 64
		{ n = "Brow", s = "Block", z = Vector3.new(0.963198, 0.228126, 0.27882), cf = CFrame.new(0.481599, 2.119035, -3.143036, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c = Color3.fromRGB(40, 92, 62), m = Enum.Material.SmoothPlastic, st = false }, -- 65
		{ n = "Nose", s = "Block", z = Vector3.new(0.506946, 0.456252, 0.253473), cf = CFrame.new(0, 1.69827, -3.168396, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(196, 218, 118), m = Enum.Material.SmoothPlastic, st = false }, -- 66
		{ n = "Moustache", s = "Block", z = Vector3.new(0.253473, 0.852247, 0.172362), cf = CFrame.new(-0.456251, 1.292713, -3.203888, -0.56921, -0.822192, 0, 0.822192, -0.56921, 0, 0, 0, 1), c = Color3.fromRGB(238, 230, 192), m = Enum.Material.SmoothPlastic, st = false }, -- 67
		{ n = "Moustache", s = "Block", z = Vector3.new(0.253473, 0.852247, 0.172362), cf = CFrame.new(0.456251, 1.292713, -3.203888, -0.56921, 0.822192, 0, -0.822192, -0.56921, 0, 0, 0, 1), c = Color3.fromRGB(238, 230, 192), m = Enum.Material.SmoothPlastic, st = false }, -- 68
		{ n = "Mouth", s = "Block", z = Vector3.new(1.013892, 0.354862, 0.050695), cf = CFrame.new(0, 1.03924, -3.067017, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(24, 16, 26), m = Enum.Material.SmoothPlastic, st = false }, -- 69
		{ n = "Lip", s = "Block", z = Vector3.new(0.152084, 0.639952, 0.152084), cf = CFrame.new(-0.266147, 1.203997, -3.102478, 0.393919, 0.919145, 0, -0.919145, 0.393919, 0, 0, 0, 1), c = Color3.fromRGB(150, 62, 58), m = Enum.Material.SmoothPlastic, st = false }, -- 70
		{ n = "Tusk", s = "Block", z = Vector3.new(0.162223, 0.506946, 0.162223), cf = CFrame.new(-0.415696, 1.074726, -3.193756, 0.987688, -0.156434, 0, 0.156434, 0.987688, 0, 0, 0, 1), c = Color3.fromRGB(252, 248, 228), m = Enum.Material.SmoothPlastic, st = false }, -- 71
		{ n = "Lip", s = "Block", z = Vector3.new(0.152084, 0.639952, 0.152084), cf = CFrame.new(0.266147, 1.203997, -3.102478, 0.393919, -0.919145, 0, 0.919145, 0.393919, 0, 0, 0, 1), c = Color3.fromRGB(150, 62, 58), m = Enum.Material.SmoothPlastic, st = false }, -- 72
		{ n = "Tusk", s = "Block", z = Vector3.new(0.162223, 0.506946, 0.162223), cf = CFrame.new(0.415696, 1.074726, -3.193756, 0.987688, 0.156434, 0, -0.156434, 0.987688, 0, 0, 0, 1), c = Color3.fromRGB(252, 248, 228), m = Enum.Material.SmoothPlastic, st = false }, -- 73
		{ n = "Lip", s = "Block", z = Vector3.new(1.115282, 0.141945, 0.152084), cf = CFrame.new(0, 0.800975, -3.102478, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 62, 58), m = Enum.Material.SmoothPlastic, st = false }, -- 74
		{ n = "Tongue", s = "Block", z = Vector3.new(0.253473, 0.506946, 0.101389), cf = CFrame.new(0.177431, 0.608335, -3.21402, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(238, 104, 128), m = Enum.Material.SmoothPlastic, st = false }, -- 75
		{ n = "CheekBolt", s = "Block", z = Vector3.new(0.141945, 0.573243, 0.050695), cf = CFrame.new(-0.646357, 1.723617, -3.077148, -0.970142, -0.242536, 0, 0.242536, -0.970142, 0, 0, 0, 1), c = Color3.fromRGB(255, 232, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 76
		{ n = "Feeler", s = "Block", z = Vector3.new(0.253473, 0.902846, 0.253473), cf = CFrame.new(-0.861809, 1.723617, -3.219086, -0.624695, -0.30657, -0.718172, 0.780869, -0.245256, -0.574538, 0, -0.919709, 0.392601), c = Color3.fromRGB(70, 170, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 77
		{ n = "CheekBolt", s = "Block", z = Vector3.new(0.141945, 0.573243, 0.050695), cf = CFrame.new(0.646357, 1.723617, -3.077148, -0.970142, 0.242536, 0, -0.242536, -0.970142, 0, 0, 0, 1), c = Color3.fromRGB(255, 232, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 78
		{ n = "Feeler", s = "Block", z = Vector3.new(0.253473, 0.902846, 0.253473), cf = CFrame.new(0.861809, 1.723617, -3.219086, -0.624695, 0.30657, 0.718172, -0.780869, -0.245256, -0.574538, 0, -0.919709, 0.392601), c = Color3.fromRGB(70, 170, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 79
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0.126737, -0.354862, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 3, c0 = CFrame.new(0, 0.557641, 1.115282, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 0.329515, -0.963198, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.456252, 0.304168, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FrillR0", h = 2, a = 2, b = 38, c0 = CFrame.new(-1.115282, 0.126737, 0.152084, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.240437, -0.08415, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FrillR1", h = 2, a = 2, b = 39, c0 = CFrame.new(-1.115282, 0.126737, 1.723617, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.240437, -0.08415, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FrillL0", h = 2, a = 2, b = 40, c0 = CFrame.new(1.115282, 0.126737, 0.152084, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.240437, -0.08415, 0, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FrillL1", h = 2, a = 2, b = 41, c0 = CFrame.new(1.115282, 0.126737, 1.723617, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.240437, -0.08415, 0, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail1", h = 3, a = 3, b = 7, c0 = CFrame.new(0, -0.228126, 1.774312, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.152084, -0.861809, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Shell", h = 3, a = 3, b = 11, c0 = CFrame.new(0, 0.329515, -0.050695, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.571533, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Head", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 0.304168, -0.202778, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.405557, 0.557641, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Jaw", h = 5, a = 5, b = 6, c0 = CFrame.new(0, -0.760419, 0.506946, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.253473, 0.506946, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "StalkR", h = 5, a = 5, b = 42, c0 = CFrame.new(-0.608335, 0.557641, -0.101389, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.008334, -0.404869, 0.025468, 0.986394, 0.164399, 0, -0.141478, 0.848868, -0.509321, -0.083732, 0.502391, 0.860577) },
		{ k = "Motor6D", n = "StalkL", h = 5, a = 5, b = 53, c0 = CFrame.new(0.608335, 0.557641, -0.101389, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.008334, -0.404869, 0.025468, 0.986394, -0.164399, 0, 0.141478, 0.848868, -0.509321, 0.083732, 0.502391, 0.860577) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 64, c0 = CFrame.new(-0.481599, 0.446113, -0.760419, 0.970296, 0.241922, 0, -0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 65, c0 = CFrame.new(0.481599, 0.446113, -0.760419, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 66, c0 = CFrame.new(0, 0.025347, -0.785767, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 67, c0 = CFrame.new(-0.456252, -0.38021, -0.821253, -0.56921, -0.822192, 0, 0.822192, -0.56921, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 68, c0 = CFrame.new(0.456252, -0.38021, -0.821253, -0.56921, 0.822192, 0, -0.822192, -0.56921, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 69, c0 = CFrame.new(0, -0.633683, -0.684377, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 70, c0 = CFrame.new(-0.266147, -0.468925, -0.719864, 0.393919, 0.919145, 0, -0.919145, 0.393919, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 72, c0 = CFrame.new(0.266147, -0.468925, -0.719864, 0.393919, -0.919145, 0, 0.919145, 0.393919, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 76, c0 = CFrame.new(-0.646356, 0.050695, -0.694516, -0.970142, -0.242536, 0, 0.242536, -0.970142, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FeelerR", h = 5, a = 5, b = 77, c0 = CFrame.new(-0.735072, 0.152084, -0.456252, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.413402, 0, -0.624695, 0.780869, 0, -0.30657, -0.245256, -0.919709, -0.718172, -0.574538, 0.392601) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 78, c0 = CFrame.new(0.646356, 0.050695, -0.694516, -0.970142, 0.242536, 0, -0.242536, -0.970142, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FeelerL", h = 5, a = 5, b = 79, c0 = CFrame.new(0.735072, 0.152084, -0.456252, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.413402, 0, -0.624695, -0.780869, 0, 0.30657, -0.245256, -0.919709, 0.718172, -0.574538, 0.392601) },
		{ k = "Weld", n = "Hold", h = 6, a = 6, b = 71, c0 = CFrame.new(-0.415696, 0.415696, -0.811114, 0.987688, -0.156434, 0, 0.156434, 0.987688, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 6, a = 6, b = 73, c0 = CFrame.new(0.415696, 0.415696, -0.811114, 0.987688, 0.156434, 0, -0.156434, 0.987688, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 6, a = 6, b = 74, c0 = CFrame.new(0, 0.141945, -0.719864, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tongue", h = 6, a = 6, b = 75, c0 = CFrame.new(0.177431, 0.202778, -0.811114, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.253473, 0.020278, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail2", h = 7, a = 7, b = 8, c0 = CFrame.new(0, 0.050695, 0.760419, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.152084, -0.405557, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 8, a = 8, b = 9, c0 = CFrame.new(0, 0.608335, 0.304168, 1, 0, 0, 0, 0.970142, -0.242536, 0, 0.242536, 0.970142), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Bud", h = 9, a = 9, b = 10, c0 = CFrame.new(0, 0.418038, 0, 1, 0, 0, 0, 0.970142, 0.242536, 0, -0.242536, 0.970142), c1 = CFrame.new(0, -0.215079, 0.143386, 1, 0, 0, 0, 0.707107, 0.707107, 0, -0.707107, 0.707107) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 12, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 13, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 0, -1, 0, 1, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 14, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, -0.707107, -0.707107, 0, 0.707107, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 15, c0 = CFrame.new(-0.887156, -0.668409, -0.890937, 0, 0, 1, -0.478062, 0.878326, 0, -0.878326, -0.478062, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 16, c0 = CFrame.new(-0.887156, 0.557833, -0.79308, 0, 0, 1, 0.687608, 0.726082, 0, -0.726082, 0.687608, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 17, c0 = CFrame.new(-0.887156, 0.80669, 0.248504, 0, 0, 1, 0.903028, -0.429582, 0, 0.429582, 0.903028, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 18, c0 = CFrame.new(-0.887156, 0.011265, 0.734745, 0, 0, 1, -0.129506, -0.991579, 0, 0.991579, -0.129506, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 19, c0 = CFrame.new(-0.887156, -0.605296, 0.206984, 0, 0, 1, -0.983067, -0.183247, 0, 0.183247, -0.983067, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 20, c0 = CFrame.new(-0.887156, -0.334204, -0.445468, 0, 0, 1, -0.478062, 0.878326, 0, -0.878326, -0.478062, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 21, c0 = CFrame.new(0.887156, -0.668409, -0.890937, 0, 0, 1, -0.478062, 0.878326, 0, -0.878326, -0.478062, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 22, c0 = CFrame.new(0.887156, 0.557833, -0.79308, 0, 0, 1, 0.687608, 0.726082, 0, -0.726082, 0.687608, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 23, c0 = CFrame.new(0.887156, 0.80669, 0.248504, 0, 0, 1, 0.903028, -0.429582, 0, 0.429582, 0.903028, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 24, c0 = CFrame.new(0.887156, 0.011265, 0.734745, 0, 0, 1, -0.129506, -0.991579, 0, 0.991579, -0.129506, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 25, c0 = CFrame.new(0.887156, -0.605296, 0.206984, 0, 0, 1, -0.983067, -0.183247, 0, 0.183247, -0.983067, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 26, c0 = CFrame.new(0.887156, -0.334204, -0.445468, 0, 0, 1, -0.478062, 0.878326, 0, -0.878326, -0.478062, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 27, c0 = CFrame.new(-0.861809, 0, 0, 1, 0, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 28, c0 = CFrame.new(0.861809, 0, 0, 1, 0, 0, 0, 0.707107, -0.707107, 0, 0.707107, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 29, c0 = CFrame.new(-0.887156, 1.140629, 0.050695, 0, 0, 1, 0.533993, -0.845489, 0, 0.845489, 0.533993, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 30, c0 = CFrame.new(-0.887156, 0.228126, 0.025347, 0, 0, 1, -0.60745, -0.794358, 0, 0.794358, -0.60745, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 31, c0 = CFrame.new(-0.887156, -0.760419, -0.050695, 0, 0, 1, 0.413803, -0.910366, 0, 0.910366, 0.413803, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 32, c0 = CFrame.new(0.887156, 1.140629, -0.050695, 0, 0, 1, -0.533993, -0.845489, 0, 0.845489, -0.533993, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 33, c0 = CFrame.new(0.887156, 0.228126, -0.025347, 0, 0, 1, 0.60745, -0.794358, 0, 0.794358, 0.60745, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 34, c0 = CFrame.new(0.887156, -0.760419, 0.050695, 0, 0, 1, -0.413803, -0.910366, 0, 0.910366, -0.413803, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 35, c0 = CFrame.new(0, 1.362167, -1.362167, 0.707107, 0, 0.707107, -0.5, 0.707107, 0.5, -0.5, -0.707107, 0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 36, c0 = CFrame.new(0, 1.926396, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 11, a = 11, b = 37, c0 = CFrame.new(0, 1.362167, 1.362167, 0.707107, 0, 0.707107, 0.5, 0.707107, -0.5, -0.5, 0.707107, 0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "EyeR", h = 42, a = 42, b = 43, c0 = CFrame.new(0.025003, 0.444316, -0.002123, 0.986394, 0.164399, 0, -0.141478, 0.848868, -0.509321, -0.083732, 0.502391, 0.860577), c1 = CFrame.new(0.076042, -0.304168, 0.101389, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 43, a = 43, b = 44, c0 = CFrame.new(0.510813, 0.510813, 0.050695, 0.707107, 0.707107, 0, -0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 43, a = 43, b = 45, c0 = CFrame.new(-0.510813, 0.510813, 0.050695, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 43, a = 43, b = 46, c0 = CFrame.new(-0.510813, -0.510813, 0.050695, -0.707107, -0.707107, 0, 0.707107, -0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 43, a = 43, b = 47, c0 = CFrame.new(0.510813, -0.510813, 0.050695, -0.707107, 0.707107, 0, -0.707107, -0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 43, a = 43, b = 48, c0 = CFrame.new(0, 0, -0.456252, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 43, a = 43, b = 52, c0 = CFrame.new(0, 0.334585, -0.542432, 0.970296, 0.241922, 0, -0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 48, a = 48, b = 49, c0 = CFrame.new(0, 0, -0.045625, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 49, a = 49, b = 50, c0 = CFrame.new(0.046601, 0.046601, -0.040556, -0.980581, -0.196116, 0, 0.196116, -0.980581, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 49, a = 49, b = 51, c0 = CFrame.new(-0.068108, -0.068108, -0.040556, -0.250962, -0.967997, 0, 0.967997, -0.250962, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "EyeL", h = 53, a = 53, b = 54, c0 = CFrame.new(-0.025003, 0.444316, -0.002123, 0.986394, -0.164399, 0, 0.141478, 0.848868, -0.509321, 0.083732, 0.502391, 0.860577), c1 = CFrame.new(-0.076042, -0.304168, 0.101389, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 55, c0 = CFrame.new(0.510813, 0.510813, 0.050695, 0.707107, 0.707107, 0, -0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 56, c0 = CFrame.new(-0.510813, 0.510813, 0.050695, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 57, c0 = CFrame.new(-0.510813, -0.510813, 0.050695, -0.707107, -0.707107, 0, 0.707107, -0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 58, c0 = CFrame.new(0.510813, -0.510813, 0.050695, -0.707107, 0.707107, 0, -0.707107, -0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 59, c0 = CFrame.new(0, 0, -0.456252, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 63, c0 = CFrame.new(0, 0.334585, -0.542432, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 59, a = 59, b = 60, c0 = CFrame.new(0, 0, -0.045625, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 60, a = 60, b = 61, c0 = CFrame.new(0.046601, 0.046601, -0.040556, -0.196116, -0.980581, 0, 0.980581, -0.196116, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 60, a = 60, b = 62, c0 = CFrame.new(-0.068108, -0.068108, -0.040556, -0.967997, -0.250962, 0, 0.250962, -0.967997, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StormGlow", p = 28, range = 14, brightness = 1, color = Color3.new(1, 0.85, 0.42), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Drip", p = 36, rate = 10, enabled = true, lifetime = NumberRange.new(1.4, 2.1), speed = NumberRange.new(1.013892, 2.027785), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.141945, 0), NumberSequenceKeypoint.new(1, 0.050695, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.78, 0.94, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.27, 0.67, 1)) }), lightEmission = 0.7, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(60, 60), acceleration = Vector3.new(0, -8.111139, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
