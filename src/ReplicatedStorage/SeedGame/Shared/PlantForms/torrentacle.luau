--!strict
--==============================================================================
-- PLANT FORM: Torrentacle (Mythic), the Rain event's second family (2026-10-05)
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/Torrentacle (tiny)(Mythic)" by a read-only generator on
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
	Source = "Rain Event 2/Torrentacle (tiny)(Mythic)", Kind = "plant", Yaw = 0,
	Size = Vector3.new(5.606754, 4.469683, 4.582123), Height = 4.469683, PartCount = 95,
	Base = 1,
	Unit = 1, ModelScale = 0.545275,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(2.726374, 0.109055, 2.726374), cf = CFrame.new(0, 0.054528, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 66, 84), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "Hub", s = "Block", z = Vector3.new(2.181099, 0.490747, 2.181099), cf = CFrame.new(0, 1.172342, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(54, 62, 86), m = Enum.Material.Plastic }, -- 2
		{ n = "Hub", s = "Block", z = Vector3.new(1.962989, 0.490747, 1.962989), cf = CFrame.new(0, 1.172342, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 3
		{ n = "Head", s = "Block", z = Vector3.new(1.962989, 1.744879, 1.635824), cf = CFrame.new(0, 2.290155, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 4
		{ n = "Dome", s = "Block", z = Vector3.new(1.635824, 0.381692, 1.417714), cf = CFrame.new(0, 3.353441, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 5
		{ n = "Dome", s = "Block", z = Vector3.new(1.09055, 0.299901, 0.981495), cf = CFrame.new(0, 3.696964, 0.027252, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 164, 190), m = Enum.Material.Plastic }, -- 6
		{ n = "Siphon", s = "Block", z = Vector3.new(0.490747, 0.245374, 0.490747), cf = CFrame.new(0, 3.969601, -0.136322, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 7
		{ n = "SiphonRim", s = "Block", z = Vector3.new(0.65433, 0.098149, 0.65433), cf = CFrame.new(0, 4.133183, -0.136322, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 172, 150), m = Enum.Material.Plastic }, -- 8
		{ n = "SiphonHole", s = "Block", z = Vector3.new(0.327165, 0.021811, 0.327165), cf = CFrame.new(0, 4.187711, -0.136322, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(20, 16, 28), m = Enum.Material.SmoothPlastic, st = false }, -- 9
		{ n = "PitcherLid", s = "Block", z = Vector3.new(1.09055, 0.076338, 0.981495), cf = CFrame.new(0, 4.156936, 0.76178, 1, 0, 0, 0, 0.819152, 0.573576, 0, -0.573576, 0.819152), c = Color3.fromRGB(214, 70, 70), m = Enum.Material.Plastic }, -- 10
		{ n = "LidSpot", s = "Block", z = Vector3.new(0.163582, 0.027264, 0.163582), cf = CFrame.new(-0.299901, 4.295429, 0.864502, 1, 0, 0, 0, 0.819152, 0.573576, 0, -0.573576, 0.819152), c = Color3.fromRGB(255, 236, 226), m = Enum.Material.SmoothPlastic, st = false }, -- 11
		{ n = "LidSpot", s = "Block", z = Vector3.new(0.130866, 0.027264, 0.130866), cf = CFrame.new(0.245374, 4.170326, 0.685852, 1, 0, 0, 0, 0.819152, 0.573576, 0, -0.573576, 0.819152), c = Color3.fromRGB(255, 236, 226), m = Enum.Material.SmoothPlastic, st = false }, -- 12
		{ n = "LidSpot", s = "Block", z = Vector3.new(0.152677, 0.027264, 0.152677), cf = CFrame.new(0, 4.373618, 0.976166, 1, 0, 0, 0, 0.819152, 0.573576, 0, -0.573576, 0.819152), c = Color3.fromRGB(255, 236, 226), m = Enum.Material.SmoothPlastic, st = false }, -- 13
		{ n = "Fin", s = "Block", z = Vector3.new(0.65433, 0.763385, 0.163582), cf = CFrame.new(-1.199605, 3.108067, 0, 0.866025, -0.5, 0, 0.5, 0.866025, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 14
		{ n = "Fin", s = "Block", z = Vector3.new(0.490747, 0.545275, 0.136319), cf = CFrame.new(-1.554034, 3.680606, 0, 0.766045, -0.642788, 0, 0.642788, 0.766045, 0, 0, 0, 1), c = Color3.fromRGB(255, 172, 150), m = Enum.Material.Plastic }, -- 15
		{ n = "Fin", s = "Block", z = Vector3.new(0.65433, 0.763385, 0.163582), cf = CFrame.new(1.199605, 3.108067, 0, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 16
		{ n = "Fin", s = "Block", z = Vector3.new(0.490747, 0.545275, 0.136319), cf = CFrame.new(1.554034, 3.680606, 0, 0.766045, 0.642788, 0, -0.642788, 0.766045, 0, 0, 0, 1), c = Color3.fromRGB(255, 172, 150), m = Enum.Material.Plastic }, -- 17
		{ n = "EyeSocket", s = "Block", z = Vector3.new(0.763385, 0.763385, 0.065433), cf = CFrame.new(-0.545275, 2.508265, -0.850616, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(36, 40, 58), m = Enum.Material.SmoothPlastic, st = false }, -- 18
		{ n = "Eye", s = "Block", z = Vector3.new(0.632519, 0.632519, 0.054527), cf = CFrame.new(-0.545275, 2.508265, -0.899689, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(240, 246, 252), m = Enum.Material.SmoothPlastic, st = false }, -- 19
		{ n = "Eye", s = "Block", z = Vector3.new(0.490747, 0.490747, 0.043622), cf = CFrame.new(-0.545275, 2.508265, -0.937866, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 20
		{ n = "Eye", s = "Block", z = Vector3.new(0.359881, 0.359881, 0.038169), cf = CFrame.new(-0.545275, 2.508265, -0.965118, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 21
		{ n = "Pupil", s = "Block", z = Vector3.new(0.21811, 0.21811, 0.032716), cf = CFrame.new(-0.545275, 2.508265, -0.992371, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(20, 16, 28), m = Enum.Material.SmoothPlastic, st = false }, -- 22
		{ n = "EyeShine", s = "Block", z = Vector3.new(0.109055, 0.109055, 0.027264), cf = CFrame.new(-0.452578, 2.590057, -1.008728, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 23
		{ n = "EyeShine", s = "Block", z = Vector3.new(0.049075, 0.049075, 0.027264), cf = CFrame.new(-0.610708, 2.431927, -1.008728, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 24
		{ n = "Lash", s = "Block", z = Vector3.new(0.05998, 0.250826, 0.05998), cf = CFrame.new(-0.866305, 2.993737, -0.872437, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 25
		{ n = "Lash", s = "Block", z = Vector3.new(0.05998, 0.250826, 0.05998), cf = CFrame.new(-1.014685, 2.88177, -0.872437, 0.642788, -0.766044, 0, 0.766044, 0.642788, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 26
		{ n = "Lash", s = "Block", z = Vector3.new(0.05998, 0.250826, 0.05998), cf = CFrame.new(-1.0921, 2.701484, -0.872437, 0.258819, -0.965926, 0, 0.965926, 0.258819, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 27
		{ n = "Brow", s = "Block", z = Vector3.new(0.109055, 0.421373, 0.109055), cf = CFrame.new(-0.354429, 3.075351, -0.872437, 0.249041, -0.968493, 0, 0.968493, 0.249041, 0, 0, 0, 1), c = Color3.fromRGB(40, 46, 66), m = Enum.Material.SmoothPlastic, st = false }, -- 28
		{ n = "Brow", s = "Block", z = Vector3.new(0.109055, 0.421373, 0.109055), cf = CFrame.new(-0.736121, 3.075351, -0.872437, -0.249041, -0.968493, 0, 0.968493, -0.249041, 0, 0, 0, 1), c = Color3.fromRGB(40, 46, 66), m = Enum.Material.SmoothPlastic, st = false }, -- 29
		{ n = "EyeSocket", s = "Block", z = Vector3.new(0.763385, 0.763385, 0.065433), cf = CFrame.new(0.545275, 2.508265, -0.850616, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(36, 40, 58), m = Enum.Material.SmoothPlastic, st = false }, -- 30
		{ n = "Eye", s = "Block", z = Vector3.new(0.632519, 0.632519, 0.054527), cf = CFrame.new(0.545275, 2.508265, -0.899689, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(240, 246, 252), m = Enum.Material.SmoothPlastic, st = false }, -- 31
		{ n = "Eye", s = "Block", z = Vector3.new(0.490747, 0.490747, 0.043622), cf = CFrame.new(0.545275, 2.508265, -0.937866, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 32
		{ n = "Eye", s = "Block", z = Vector3.new(0.359881, 0.359881, 0.038169), cf = CFrame.new(0.545275, 2.508265, -0.965118, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 245, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 33
		{ n = "Pupil", s = "Block", z = Vector3.new(0.21811, 0.21811, 0.032716), cf = CFrame.new(0.545275, 2.508265, -0.992371, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(20, 16, 28), m = Enum.Material.SmoothPlastic, st = false }, -- 34
		{ n = "EyeShine", s = "Block", z = Vector3.new(0.109055, 0.109055, 0.027264), cf = CFrame.new(0.637971, 2.590057, -1.008728, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 35
		{ n = "EyeShine", s = "Block", z = Vector3.new(0.049075, 0.049075, 0.027264), cf = CFrame.new(0.479842, 2.431927, -1.008728, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 255, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 36
		{ n = "Lash", s = "Block", z = Vector3.new(0.05998, 0.250826, 0.05998), cf = CFrame.new(0.866305, 2.993737, -0.872437, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 37
		{ n = "Lash", s = "Block", z = Vector3.new(0.05998, 0.250826, 0.05998), cf = CFrame.new(1.014685, 2.88177, -0.872437, 0.642788, 0.766044, 0, -0.766044, 0.642788, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 38
		{ n = "Lash", s = "Block", z = Vector3.new(0.05998, 0.250826, 0.05998), cf = CFrame.new(1.0921, 2.701484, -0.872437, 0.258819, 0.965926, 0, -0.965926, 0.258819, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 39
		{ n = "Brow", s = "Block", z = Vector3.new(0.109055, 0.421373, 0.109055), cf = CFrame.new(0.354429, 3.075351, -0.872437, 0.249041, 0.968493, 0, -0.968493, 0.249041, 0, 0, 0, 1), c = Color3.fromRGB(40, 46, 66), m = Enum.Material.SmoothPlastic, st = false }, -- 40
		{ n = "Brow", s = "Block", z = Vector3.new(0.109055, 0.421373, 0.109055), cf = CFrame.new(0.736121, 3.075351, -0.872437, -0.249041, 0.968493, 0, -0.968493, -0.249041, 0, 0, 0, 1), c = Color3.fromRGB(40, 46, 66), m = Enum.Material.SmoothPlastic, st = false }, -- 41
		{ n = "ForeheadGem", s = "Block", z = Vector3.new(0.185393, 0.185393, 0.054527), cf = CFrame.new(0, 2.699111, -0.845184, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.fromRGB(205, 255, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 42
		{ n = "Mouth", s = "Block", z = Vector3.new(0.708857, 0.490747, 0.054527), cf = CFrame.new(0, 1.772144, -0.845184, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(20, 16, 28), m = Enum.Material.SmoothPlastic, st = false }, -- 43
		{ n = "Lip", s = "Block", z = Vector3.new(1.036022, 0.109055, 0.109055), cf = CFrame.new(0, 2.072045, -0.872437, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 44
		{ n = "Lip", s = "Block", z = Vector3.new(1.036022, 0.109055, 0.109055), cf = CFrame.new(0, 1.472243, -0.872437, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 45
		{ n = "Lip", s = "Block", z = Vector3.new(0.109055, 0.708857, 0.109055), cf = CFrame.new(-0.408956, 1.772144, -0.872437, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 46
		{ n = "Lip", s = "Block", z = Vector3.new(0.109055, 0.708857, 0.109055), cf = CFrame.new(0.408956, 1.772144, -0.872437, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.SmoothPlastic, st = false }, -- 47
		{ n = "Tooth", s = "Block", z = Vector3.new(0.11996, 0.185393, 0.076338), cf = CFrame.new(-0.190846, 1.924821, -0.905151, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 246, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 48
		{ n = "Tooth", s = "Block", z = Vector3.new(0.11996, 0.185393, 0.076338), cf = CFrame.new(0, 1.924821, -0.905151, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 246, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 49
		{ n = "Tooth", s = "Block", z = Vector3.new(0.11996, 0.185393, 0.076338), cf = CFrame.new(0.190846, 1.924821, -0.905151, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 246, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 50
		{ n = "Tooth", s = "Block", z = Vector3.new(0.11996, 0.174488, 0.076338), cf = CFrame.new(-0.163582, 1.62492, -0.905151, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 246, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 51
		{ n = "Tooth", s = "Block", z = Vector3.new(0.11996, 0.174488, 0.076338), cf = CFrame.new(0.163582, 1.62492, -0.905151, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 246, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 52
		{ n = "Tooth", s = "Block", z = Vector3.new(0.163582, 0.11996, 0.076338), cf = CFrame.new(-0.256279, 1.772144, -0.905151, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 246, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 53
		{ n = "Tooth", s = "Block", z = Vector3.new(0.163582, 0.11996, 0.076338), cf = CFrame.new(0.256279, 1.772144, -0.905151, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(250, 246, 232), m = Enum.Material.SmoothPlastic, st = false }, -- 54
		{ n = "Tongue", s = "Block", z = Vector3.new(0.174488, 0.130866, 0.065433), cf = CFrame.new(0, 1.750333, -0.883331, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 110, 150), m = Enum.Material.SmoothPlastic, st = false }, -- 55
		{ n = "CheekDrop", s = "Block", z = Vector3.new(0.087244, 0.185393, 0.054527), cf = CFrame.new(-0.708857, 1.935727, -0.845184, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 56
		{ n = "CheekDrop", s = "Block", z = Vector3.new(0.087244, 0.185393, 0.054527), cf = CFrame.new(-0.845176, 1.788502, -0.845184, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 57
		{ n = "CheekDrop", s = "Block", z = Vector3.new(0.087244, 0.185393, 0.054527), cf = CFrame.new(-0.708857, 1.635825, -0.845184, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 58
		{ n = "Vein", s = "Block", z = Vector3.new(0.070886, 0.411476, 0.054527), cf = CFrame.new(-1.003306, 2.889958, -0.149963, 0, 0, 1, 0.503871, -0.863779, 0, 0.863779, 0.503871, 0), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 59
		{ n = "Vein", s = "Block", z = Vector3.new(0.070886, 0.289922, 0.054527), cf = CFrame.new(-1.003306, 2.658216, -0.163574, 0, 0, 1, -0.847998, -0.529999, 0, 0.529999, -0.847998, 0), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 60
		{ n = "Vein", s = "Block", z = Vector3.new(0.070886, 0.463794, 0.054527), cf = CFrame.new(-1.003306, 2.412842, -0.149963, 0, 0, 1, 0.56921, -0.822192, 0, 0.822192, 0.56921, 0), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 61
		{ n = "CheekDrop", s = "Block", z = Vector3.new(0.087244, 0.185393, 0.054527), cf = CFrame.new(0.708857, 1.935727, -0.845184, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 62
		{ n = "CheekDrop", s = "Block", z = Vector3.new(0.087244, 0.185393, 0.054527), cf = CFrame.new(0.845176, 1.788502, -0.845184, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 63
		{ n = "CheekDrop", s = "Block", z = Vector3.new(0.087244, 0.185393, 0.054527), cf = CFrame.new(0.708857, 1.635825, -0.845184, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 64
		{ n = "Vein", s = "Block", z = Vector3.new(0.070886, 0.411476, 0.054527), cf = CFrame.new(1.003306, 2.889958, -0.149963, 0, 0, 1, 0.503871, -0.863779, 0, 0.863779, 0.503871, 0), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 65
		{ n = "Vein", s = "Block", z = Vector3.new(0.070886, 0.289922, 0.054527), cf = CFrame.new(1.003306, 2.658216, -0.163574, 0, 0, 1, -0.847998, -0.529999, 0, 0.529999, -0.847998, 0), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 66
		{ n = "Vein", s = "Block", z = Vector3.new(0.070886, 0.463794, 0.054527), cf = CFrame.new(1.003306, 2.412842, -0.149963, 0, 0, 1, 0.56921, -0.822192, 0, 0.822192, 0.56921, 0), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 67
		{ n = "BackPanel", s = "Block", z = Vector3.new(1.30866, 1.199605, 0.065433), cf = CFrame.new(0, 2.344682, 0.850616, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(150, 164, 190), m = Enum.Material.Plastic }, -- 68
		{ n = "Vein", s = "Block", z = Vector3.new(0.076338, 0.56975, 0.054527), cf = CFrame.new(-0.136319, 2.726375, 0.905151, -0.406138, 0.913812, 0, -0.913812, -0.406138, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 69
		{ n = "Vein", s = "Block", z = Vector3.new(0.076338, 0.418284, 0.054527), cf = CFrame.new(-0.027264, 2.481001, 0.905151, -0.707107, -0.707107, 0, 0.707107, -0.707107, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 70
		{ n = "Vein", s = "Block", z = Vector3.new(0.076338, 0.622521, 0.054527), cf = CFrame.new(0.081791, 2.1811, 0.905151, -0.5547, 0.83205, 0, -0.83205, -0.5547, 0, 0, 0, 1), c = Color3.fromRGB(60, 200, 235), m = Enum.Material.Neon, st = false, cs = false }, -- 71
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.490747, 0.956047, 0.490747), cf = CFrame.new(-0.749654, 1.117814, -0.674988, 0.08935, -0.741499, -0.664978, 0.996, 0.066519, 0.059654, 0, -0.667648, 0.744477), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 72
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.381692, 1.002345, 0.381692), cf = CFrame.new(-1.33722, 0.9406, -1.204041, -0.584772, -0.655067, -0.478465, 0.811198, -0.472222, -0.344913, 0, -0.589825, 0.807531), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 73
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.299901, 0.7035, 0.299901), cf = CFrame.new(-1.762699, 0.490748, -1.587158, -0.865781, -0.456247, -0.205577, 0.500423, -0.789352, -0.355668, 0, -0.410806, 0.911723), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 74
		{ n = "TentaclePad", s = "Block", z = Vector3.new(0.43622, 0.109055, 0.43622), cf = CFrame.new(-1.924787, 0.054528, -1.733093, 0.669131, 0, 0.743145, 0, 1, 0, -0.743145, 0, 0.669131), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 75
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.490747, 0.956047, 0.490747), cf = CFrame.new(-0.993433, 1.117814, 0.175171, 0.067541, -0.982626, 0.172868, 0.997716, 0.06652, -0.011702, 0, 0.173264, 0.984876), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 76
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.381692, 1.002345, 0.381692), cf = CFrame.new(-1.77207, 0.9406, 0.312469, -0.477853, -0.868088, 0.134461, 0.87844, -0.472222, 0.073144, 0, 0.153068, 0.988216), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 77
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.299901, 0.7035, 0.299901), cf = CFrame.new(-2.33591, 0.490748, 0.411896, -0.793877, -0.604613, 0.064827, 0.608078, -0.789353, 0.084635, 0, 0.10661, 0.994301), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 78
		{ n = "TentaclePad", s = "Block", z = Vector3.new(0.43622, 0.109055, 0.43622), cf = CFrame.new(-2.550706, 0.054528, 0.449768, -0.173648, -0.000001, 0.984808, 0, 1, 0.000001, -0.984808, 0, -0.173648), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 79
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.490747, 0.956047, 0.490747), cf = CFrame.new(-0.504379, 1.117814, 0.873596, 0.132164, -0.498893, 0.856527, 0.991228, 0.066519, -0.114204, 0, 0.864107, 0.503308), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 80
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.381692, 1.002345, 0.381692), cf = CFrame.new(-0.899704, 0.9406, 1.558319, -0.731055, -0.44074, 0.520871, 0.682319, -0.472221, 0.558076, 0, 0.763384, 0.645944), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 81
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.299901, 0.7035, 0.299901), cf = CFrame.new(-1.185973, 0.490748, 2.054138, -0.932005, -0.30697, 0.192708, 0.362446, -0.789353, 0.495536, 0, 0.531688, 0.84694), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 82
		{ n = "TentaclePad", s = "Block", z = Vector3.new(0.43622, 0.109055, 0.43622), cf = CFrame.new(-1.295028, 0.054528, 2.243042, -0.866026, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866026), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 83
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.490747, 0.956047, 0.490747), cf = CFrame.new(0.749654, 1.117814, -0.674988, 0.08935, 0.741499, 0.664978, -0.996, 0.066519, 0.059654, 0, -0.667648, 0.744477), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 84
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.381692, 1.002345, 0.381692), cf = CFrame.new(1.33722, 0.9406, -1.204041, -0.584772, 0.655067, 0.478465, -0.811198, -0.472222, -0.344913, 0, -0.589825, 0.807531), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 85
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.299901, 0.7035, 0.299901), cf = CFrame.new(1.762699, 0.490748, -1.587158, -0.865781, 0.456247, 0.205577, -0.500423, -0.789352, -0.355668, 0, -0.410806, 0.911723), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 86
		{ n = "TentaclePad", s = "Block", z = Vector3.new(0.43622, 0.109055, 0.43622), cf = CFrame.new(1.924787, 0.054528, -1.733093, 0.669131, 0, -0.743145, 0, 1, 0, 0.743145, 0, 0.669131), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 87
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.490747, 0.956047, 0.490747), cf = CFrame.new(0.993433, 1.117814, 0.175171, 0.067541, 0.982626, -0.172868, -0.997716, 0.06652, -0.011702, 0, 0.173264, 0.984876), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 88
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.381692, 1.002345, 0.381692), cf = CFrame.new(1.77207, 0.9406, 0.312469, -0.477853, 0.868088, -0.134461, -0.87844, -0.472222, 0.073144, 0, 0.153068, 0.988216), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 89
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.299901, 0.7035, 0.299901), cf = CFrame.new(2.33591, 0.490748, 0.411896, -0.793877, 0.604613, -0.064827, -0.608078, -0.789353, 0.084635, 0, 0.10661, 0.994301), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 90
		{ n = "TentaclePad", s = "Block", z = Vector3.new(0.43622, 0.109055, 0.43622), cf = CFrame.new(2.550706, 0.054528, 0.449768, -0.173648, 0.000001, -0.984808, 0, 1, 0.000001, 0.984808, 0, -0.173648), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 91
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.490747, 0.956047, 0.490747), cf = CFrame.new(0.504379, 1.117814, 0.873596, 0.132164, 0.498893, -0.856527, -0.991228, 0.066519, -0.114204, 0, 0.864107, 0.503308), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 92
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.381692, 1.002345, 0.381692), cf = CFrame.new(0.899704, 0.9406, 1.558319, -0.731055, 0.44074, -0.520871, -0.682319, -0.472221, 0.558076, 0, 0.763384, 0.645944), c = Color3.fromRGB(78, 90, 118), m = Enum.Material.Plastic }, -- 93
		{ n = "Tentacle", s = "Block", z = Vector3.new(0.299901, 0.7035, 0.299901), cf = CFrame.new(1.185973, 0.490748, 2.054138, -0.932005, 0.30697, -0.192708, -0.362446, -0.789353, 0.495536, 0, 0.531688, 0.84694), c = Color3.fromRGB(110, 124, 152), m = Enum.Material.Plastic }, -- 94
		{ n = "TentaclePad", s = "Block", z = Vector3.new(0.43622, 0.109055, 0.43622), cf = CFrame.new(1.295028, 0.054528, 2.243042, -0.866026, 0, -0.5, 0, 1, 0, 0.5, 0, -0.866026), c = Color3.fromRGB(255, 108, 98), m = Enum.Material.Plastic }, -- 95
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 1.117813, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 3, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 0.245374, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.87244, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipFR", h = 2, a = 2, b = 72, c0 = CFrame.new(-0.44574, -0.081791, -0.401346, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.409864, 0, 0.08935, 0.996, 0, -0.741499, 0.066519, -0.667648, -0.664978, 0.059654, 0.744477) },
		{ k = "Motor6D", n = "HipSR", h = 2, a = 2, b = 76, c0 = CFrame.new(-0.59069, -0.081791, 0.104155, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.409864, 0, 0.067541, 0.997716, 0, -0.982626, 0.06652, 0.173264, 0.172868, -0.011702, 0.984876) },
		{ k = "Motor6D", n = "HipBR", h = 2, a = 2, b = 80, c0 = CFrame.new(-0.299901, -0.081791, 0.519444, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.409864, 0, 0.132164, 0.991228, 0, -0.498893, 0.066519, 0.864107, 0.856527, -0.114204, 0.503308) },
		{ k = "Motor6D", n = "HipFL", h = 2, a = 2, b = 84, c0 = CFrame.new(0.44574, -0.081791, -0.401346, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.409864, 0, 0.08935, -0.996, 0, 0.741499, 0.066519, -0.667648, 0.664978, 0.059654, 0.744477) },
		{ k = "Motor6D", n = "HipSL", h = 2, a = 2, b = 88, c0 = CFrame.new(0.59069, -0.081791, 0.104155, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.409864, 0, 0.067541, -0.997716, 0, 0.982626, 0.06652, 0.173264, -0.172868, -0.011702, 0.984876) },
		{ k = "Motor6D", n = "HipBL", h = 2, a = 2, b = 92, c0 = CFrame.new(0.299901, -0.081791, 0.519444, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.409864, 0, 0.132164, -0.991228, 0, 0.498893, 0.066519, 0.864107, -0.856527, -0.114204, 0.503308) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 1.063286, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FinR", h = 4, a = 4, b = 14, c0 = CFrame.new(-1.008758, 0.545275, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.028959, -0.331534, 0, 0.866025, 0.5, 0, -0.5, 0.866025, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FinL", h = 4, a = 4, b = 16, c0 = CFrame.new(1.008758, 0.545275, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.028959, -0.331534, 0, 0.866025, -0.5, 0, 0.5, 0.866025, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 18, c0 = CFrame.new(-0.545275, 0.21811, -0.850629, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 19, c0 = CFrame.new(-0.545275, 0.21811, -0.899703, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 28, c0 = CFrame.new(-0.354429, 0.785196, -0.87244, 0.249041, -0.968493, 0, 0.968493, 0.249041, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 29, c0 = CFrame.new(-0.736121, 0.785196, -0.87244, -0.249041, -0.968493, 0, 0.968493, -0.249041, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 30, c0 = CFrame.new(0.545275, 0.21811, -0.850629, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 31, c0 = CFrame.new(0.545275, 0.21811, -0.899703, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 40, c0 = CFrame.new(0.354429, 0.785196, -0.87244, 0.249041, 0.968493, 0, -0.968493, 0.249041, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 41, c0 = CFrame.new(0.736121, 0.785196, -0.87244, -0.249041, 0.968493, 0, -0.968493, -0.249041, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 42, c0 = CFrame.new(0, 0.408956, -0.845176, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 43, c0 = CFrame.new(0, -0.518011, -0.845176, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 44, c0 = CFrame.new(0, -0.21811, -0.87244, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 45, c0 = CFrame.new(0, -0.817912, -0.87244, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 46, c0 = CFrame.new(-0.408956, -0.518011, -0.87244, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 47, c0 = CFrame.new(0.408956, -0.518011, -0.87244, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 48, c0 = CFrame.new(-0.190846, -0.365334, -0.905156, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 49, c0 = CFrame.new(0, -0.365334, -0.905156, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 50, c0 = CFrame.new(0.190846, -0.365334, -0.905156, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 51, c0 = CFrame.new(-0.163582, -0.665235, -0.905156, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 52, c0 = CFrame.new(0.163582, -0.665235, -0.905156, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 53, c0 = CFrame.new(-0.256279, -0.518011, -0.905156, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 54, c0 = CFrame.new(0.256279, -0.518011, -0.905156, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tongue", h = 4, a = 4, b = 55, c0 = CFrame.new(0, -0.539822, -0.828818, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.054527, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 56, c0 = CFrame.new(-0.708857, -0.354429, -0.845176, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 57, c0 = CFrame.new(-0.845176, -0.501653, -0.845176, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 58, c0 = CFrame.new(-0.708857, -0.65433, -0.845176, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 59, c0 = CFrame.new(-1.003306, 0.599802, -0.149951, 0, 0, 1, 0.503871, -0.863779, 0, 0.863779, 0.503871, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 60, c0 = CFrame.new(-1.003306, 0.36806, -0.163582, 0, 0, 1, -0.847998, -0.529999, 0, 0.529999, -0.847998, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 61, c0 = CFrame.new(-1.003306, 0.122687, -0.149951, 0, 0, 1, 0.56921, -0.822192, 0, 0.822192, 0.56921, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 62, c0 = CFrame.new(0.708857, -0.354429, -0.845176, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 63, c0 = CFrame.new(0.845176, -0.501653, -0.845176, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 64, c0 = CFrame.new(0.708857, -0.65433, -0.845176, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 65, c0 = CFrame.new(1.003306, 0.599802, -0.149951, 0, 0, 1, 0.503871, -0.863779, 0, 0.863779, 0.503871, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 66, c0 = CFrame.new(1.003306, 0.36806, -0.163582, 0, 0, 1, -0.847998, -0.529999, 0, 0.529999, -0.847998, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 67, c0 = CFrame.new(1.003306, 0.122687, -0.149951, 0, 0, 1, 0.56921, -0.822192, 0, 0.822192, 0.56921, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 4, a = 4, b = 68, c0 = CFrame.new(0, 0.054527, 0.850629, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 5, a = 5, b = 6, c0 = CFrame.new(0, 0.343523, 0.027264, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 6, a = 6, b = 7, c0 = CFrame.new(0, 0.272637, -0.163582, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Lid", h = 6, a = 6, b = 10, c0 = CFrame.new(0, 0.147224, 0.354429, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.038169, -0.490747, 1, 0, 0, 0, 0.819152, -0.573576, 0, 0.573576, 0.819152) },
		{ k = "Weld", n = "Hold", h = 7, a = 7, b = 8, c0 = CFrame.new(0, 0.163582, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 8, a = 8, b = 9, c0 = CFrame.new(0, 0.054527, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 10, a = 10, b = 11, c0 = CFrame.new(-0.299901, 0.054527, 0.163582, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 10, a = 10, b = 12, c0 = CFrame.new(0.245374, 0.054527, -0.054527, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 10, a = 10, b = 13, c0 = CFrame.new(0, 0.054527, 0.299901, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 14, a = 14, b = 15, c0 = CFrame.new(-0.020675, 0.673047, 0, 0.984808, -0.173648, 0, 0.173648, 0.984808, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 16, a = 16, b = 17, c0 = CFrame.new(0.020675, 0.673047, 0, 0.984808, 0.173648, 0, -0.173648, 0.984808, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 25, c0 = CFrame.new(-0.321031, 0.485472, -0.021811, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 26, c0 = CFrame.new(-0.46941, 0.373505, -0.021811, 0.642788, -0.766044, 0, 0.766044, 0.642788, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 27, c0 = CFrame.new(-0.546826, 0.193219, -0.021811, 0.258819, -0.965926, 0, 0.965926, 0.258819, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 19, a = 19, b = 20, c0 = CFrame.new(0, 0, -0.038169, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 20, a = 20, b = 21, c0 = CFrame.new(0, 0, -0.027264, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 21, a = 21, b = 22, c0 = CFrame.new(0, 0, -0.027264, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 22, a = 22, b = 23, c0 = CFrame.new(0.092697, 0.081791, -0.016358, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 22, a = 22, b = 24, c0 = CFrame.new(-0.065433, -0.076338, -0.016358, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 30, a = 30, b = 37, c0 = CFrame.new(0.321031, 0.485472, -0.021811, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 30, a = 30, b = 38, c0 = CFrame.new(0.46941, 0.373505, -0.021811, 0.642788, 0.766044, 0, -0.766044, 0.642788, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 30, a = 30, b = 39, c0 = CFrame.new(0.546826, 0.193219, -0.021811, 0.258819, 0.965926, 0, -0.965926, 0.258819, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 31, a = 31, b = 32, c0 = CFrame.new(0, 0, -0.038169, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 32, a = 32, b = 33, c0 = CFrame.new(0, 0, -0.027264, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 33, a = 33, b = 34, c0 = CFrame.new(0, 0, -0.027264, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 35, c0 = CFrame.new(0.092697, 0.081791, -0.016358, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 34, a = 34, b = 36, c0 = CFrame.new(-0.065433, -0.076338, -0.016358, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 68, a = 68, b = 69, c0 = CFrame.new(-0.136319, 0.381692, 0.054527, -0.406138, 0.913812, 0, -0.913812, -0.406138, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 68, a = 68, b = 70, c0 = CFrame.new(-0.027264, 0.136319, 0.054527, -0.707107, -0.707107, 0, 0.707107, -0.707107, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 68, a = 68, b = 71, c0 = CFrame.new(0.081791, -0.163582, 0.054527, -0.5547, 0.83205, 0, -0.83205, -0.5547, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeFR", h = 72, a = 72, b = 73, c0 = CFrame.new(0, 0.409864, 0, 0.08935, 0.996, 0, -0.741499, 0.066519, -0.667648, -0.664978, 0.059654, 0.744477), c1 = CFrame.new(0, -0.433013, 0, -0.584772, 0.811198, 0, -0.655067, -0.472221, -0.589825, -0.478465, -0.344913, 0.807531) },
		{ k = "Motor6D", n = "AnkleFR", h = 73, a = 73, b = 74, c0 = CFrame.new(0, 0.433013, 0, -0.584772, 0.811198, 0, -0.655067, -0.472221, -0.589825, -0.478465, -0.344913, 0.807531), c1 = CFrame.new(0, -0.310855, 0, -0.865781, 0.500423, 0, -0.456247, -0.789352, -0.410806, -0.205577, -0.355668, 0.911723) },
		{ k = "Weld", n = "Hold", h = 74, a = 74, b = 75, c0 = CFrame.new(-0.077962, 0.478238, 0.055411, -0.579321, 0.500423, -0.643401, 0, -0.789352, -0.613941, -0.8151, -0.355669, 0.457288), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeSR", h = 76, a = 76, b = 77, c0 = CFrame.new(0, 0.409864, 0, 0.067541, 0.997716, 0, -0.982626, 0.06652, 0.173264, 0.172868, -0.011702, 0.984876), c1 = CFrame.new(0, -0.433013, 0, -0.477853, 0.87844, 0, -0.868088, -0.472222, 0.153068, 0.134461, 0.073144, 0.988216) },
		{ k = "Motor6D", n = "AnkleSR", h = 77, a = 77, b = 78, c0 = CFrame.new(0, 0.433013, 0, -0.477853, 0.87844, 0, -0.868088, -0.472222, 0.153068, 0.134461, 0.073144, 0.988216), c1 = CFrame.new(0, -0.310855, 0, -0.793877, 0.608078, 0, -0.604613, -0.789353, 0.10661, 0.064827, 0.084635, 0.994301) },
		{ k = "Weld", n = "Hold", h = 78, a = 78, b = 79, c0 = CFrame.new(-0.094734, 0.478238, -0.013185, 0.137855, 0.608079, -0.781816, 0, -0.789352, -0.613941, -0.990452, 0.084635, -0.108816), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeBR", h = 80, a = 80, b = 81, c0 = CFrame.new(0, 0.409864, 0, 0.132164, 0.991228, 0, -0.498893, 0.066519, 0.864107, 0.856527, -0.114204, 0.503308), c1 = CFrame.new(0, -0.433013, 0, -0.731055, 0.682318, 0, -0.44074, -0.472221, 0.763384, 0.520871, 0.558076, 0.645945) },
		{ k = "Motor6D", n = "AnkleBR", h = 81, a = 81, b = 82, c0 = CFrame.new(0, 0.433013, 0, -0.731055, 0.682318, 0, -0.44074, -0.472221, 0.763384, 0.520871, 0.558076, 0.645945), c1 = CFrame.new(0, -0.310855, 0, -0.932005, 0.362446, 0, -0.30697, -0.789352, 0.531688, 0.192708, 0.495536, 0.84694) },
		{ k = "Weld", n = "Hold", h = 82, a = 82, b = 83, c0 = CFrame.new(-0.056466, 0.478238, -0.077201, 0.80714, 0.362446, -0.466002, 0, -0.789352, -0.613941, -0.59036, 0.495536, -0.637118), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeFL", h = 84, a = 84, b = 85, c0 = CFrame.new(0, 0.409864, 0, 0.08935, -0.996, 0, 0.741499, 0.066519, -0.667648, 0.664978, 0.059654, 0.744477), c1 = CFrame.new(0, -0.433013, 0, -0.584772, -0.811198, 0, 0.655067, -0.472221, -0.589825, 0.478465, -0.344913, 0.807531) },
		{ k = "Motor6D", n = "AnkleFL", h = 85, a = 85, b = 86, c0 = CFrame.new(0, 0.433013, 0, -0.584772, -0.811198, 0, 0.655067, -0.472221, -0.589825, 0.478465, -0.344913, 0.807531), c1 = CFrame.new(0, -0.310855, 0, -0.865781, -0.500423, 0, 0.456247, -0.789352, -0.410806, 0.205577, -0.355668, 0.911723) },
		{ k = "Weld", n = "Hold", h = 86, a = 86, b = 87, c0 = CFrame.new(0.077962, 0.478238, 0.055411, -0.579321, -0.500423, 0.643401, 0, -0.789352, -0.613941, 0.8151, -0.355669, 0.457288), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeSL", h = 88, a = 88, b = 89, c0 = CFrame.new(0, 0.409864, 0, 0.067541, -0.997716, 0, 0.982626, 0.06652, 0.173264, -0.172868, -0.011702, 0.984876), c1 = CFrame.new(0, -0.433013, 0, -0.477853, -0.87844, 0, 0.868088, -0.472222, 0.153068, -0.134461, 0.073144, 0.988216) },
		{ k = "Motor6D", n = "AnkleSL", h = 89, a = 89, b = 90, c0 = CFrame.new(0, 0.433013, 0, -0.477853, -0.87844, 0, 0.868088, -0.472222, 0.153068, -0.134461, 0.073144, 0.988216), c1 = CFrame.new(0, -0.310855, 0, -0.793877, -0.608078, 0, 0.604613, -0.789353, 0.10661, -0.064827, 0.084635, 0.994301) },
		{ k = "Weld", n = "Hold", h = 90, a = 90, b = 91, c0 = CFrame.new(0.094734, 0.478238, -0.013185, 0.137855, -0.608079, 0.781816, 0, -0.789352, -0.613941, 0.990452, 0.084635, -0.108816), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "KneeBL", h = 92, a = 92, b = 93, c0 = CFrame.new(0, 0.409864, 0, 0.132164, -0.991228, 0, 0.498893, 0.066519, 0.864107, -0.856527, -0.114204, 0.503308), c1 = CFrame.new(0, -0.433013, 0, -0.731055, -0.682318, 0, 0.44074, -0.472221, 0.763384, -0.520871, 0.558076, 0.645945) },
		{ k = "Motor6D", n = "AnkleBL", h = 93, a = 93, b = 94, c0 = CFrame.new(0, 0.433013, 0, -0.731055, -0.682318, 0, 0.44074, -0.472221, 0.763384, -0.520871, 0.558076, 0.645945), c1 = CFrame.new(0, -0.310855, 0, -0.932005, -0.362446, 0, 0.30697, -0.789352, 0.531688, -0.192708, 0.495536, 0.84694) },
		{ k = "Weld", n = "Hold", h = 94, a = 94, b = 95, c0 = CFrame.new(0.056466, 0.478238, -0.077201, 0.80714, -0.362446, 0.466002, 0, -0.789352, -0.613941, 0.59036, 0.495536, -0.637118), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StormGlow", p = 6, range = 12, brightness = 0.9, color = Color3.new(0.431373, 0.901961, 1), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Spout", p = 6, rate = 14, enabled = true, lifetime = NumberRange.new(1.4, 2.2), speed = NumberRange.new(3.271649, 4.907473), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.163582, 0), NumberSequenceKeypoint.new(1, 0.054527, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.8, 0.98, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.3, 0.7, 1)) }), lightEmission = 0.7, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(15, 15), acceleration = Vector3.new(0, -9.814946, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
