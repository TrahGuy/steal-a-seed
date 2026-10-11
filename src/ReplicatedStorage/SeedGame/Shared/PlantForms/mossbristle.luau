--!strict
--==============================================================================
-- PLANT FORM: Mossbristle (Legendary), an Enchanted Mist creature (2026-10-11)
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "ENCHANTED MIST/Mossbristle (Legendary)" by a read-only generator
-- on 2026-10-11. The original was not changed; a verified .rbxm of it is in
-- output/model-backups/2026-10-11-enchanted-mist-originals. Its demo Script
-- (if it had one) and its AnimationController are not here.
--
-- AN ENCHANTED MIST CREATURE, NOT A ROAD SPECIES. It is built the way
-- PlantForms' rigs are -- whole, at its size -- and nothing else about
-- PlantForms is asked of it: it is in no biome pool, shelf, roll or reward
-- (SeedData.MistSpecies). Only the Mysterious Pod hatches it.
--
-- SIZED LIKE A ROAD PLANT (the owner, 2026-10-11): Tiny to Colossal on the
-- tier ladder every plant uses, from a Tiny on ONE factor shared by the four
-- sized Mist creatures, so they keep their sizes relative to each other
-- (PlantForms.TinyHeight, set in the parent).
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the model's BASE:
-- its root part's x/z at the lowest drawn point, facing the way the root
-- faces), colour, material, surface, attribute and joint is the supplied
-- number, at the size it was supplied. Joints point at parts by INDEX, because
-- names repeat.
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "ENCHANTED MIST/Mossbristle (Legendary)", Kind = "plant", Yaw = 0,
	Size = Vector3.new(18.84787, 19.02668, 35.000153), Height = 19.02668, PartCount = 60,
	Base = 1,
	-- Unit: the builder's `Scale` attribute (0.8), the unit its MossbristleIdle script's distances are written in (the
	-- generator looked for a `Unit` attribute, which these rigs do not carry).
	Unit = 0.8, ModelScale = 3.850957,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(7.393838, 0.616153, 7.393838), cf = CFrame.new(0, 0.000001, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(30, 24, 18), m = Enum.Material.Plastic, t = 1, cs = false }, -- 1
		{ n = "Torso", s = "Block", z = Vector3.new(11.090755, 7.393838, 13.55537), cf = CFrame.new(0, 8.318069, 0.616165, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 112, 60), m = Enum.Material.Plastic }, -- 2
		{ n = "Belly", s = "Block", z = Vector3.new(8.009991, 1.540383, 11.090755), cf = CFrame.new(0, 4.929225, 0.616165, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(238, 226, 192), m = Enum.Material.Plastic }, -- 3
		{ n = "MossPatch", s = "Block", z = Vector3.new(0.92423, 3.696919, 5.237302), cf = CFrame.new(-5.699402, 8.934222, -0.30806, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 4
		{ n = "Firefly", s = "Block", z = Vector3.new(1.386344, 1.386344, 1.386344), cf = CFrame.new(-6.099915, 6.469608, 4.004997, 0.707107, 0, 0.707107, 0.5, 0.707107, -0.5, -0.5, 0.707107, 0.5), c = Color3.fromRGB(255, 190, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 5
		{ n = "MossPatch", s = "Block", z = Vector3.new(0.92423, 3.696919, 5.237302), cf = CFrame.new(5.699341, 8.934222, -0.308083, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 6
		{ n = "Firefly", s = "Block", z = Vector3.new(1.386344, 1.386344, 1.386344), cf = CFrame.new(6.099915, 6.469608, 4.004997, 0.707107, 0, 0.707107, 0.5, 0.707107, -0.5, -0.5, 0.707107, 0.5), c = Color3.fromRGB(255, 190, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 7
		{ n = "BackPlate", s = "Block", z = Vector3.new(9.242298, 1.84846, 4.621149), cf = CFrame.new(0, 12.323064, -3.08078, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(104, 72, 48), m = Enum.Material.Plastic }, -- 8
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.978063), cf = CFrame.new(-4.039642, 15.634887, -1.386353, -0.83583, 0.438762, 0.329964, 0, 0.601039, -0.799219, -0.548988, -0.668012, -0.502367), c = Color3.fromRGB(52, 112, 60), m = Enum.Material.Plastic }, -- 9
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.531419), cf = CFrame.new(-6.200104, 14.787677, -1.078262, -0.785269, 0.363379, 0.501306, 0, 0.809663, -0.586895, -0.619155, -0.460871, -0.635803), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 10
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.978063), cf = CFrame.new(4.039642, 15.634887, -1.386322, -0.83583, -0.438762, -0.329964, 0, 0.601039, -0.799219, 0.548988, -0.668012, -0.502367), c = Color3.fromRGB(52, 112, 60), m = Enum.Material.Plastic }, -- 11
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.531419), cf = CFrame.new(6.200043, 14.787677, -1.078293, -0.785269, -0.363379, -0.501306, 0, 0.809663, -0.586895, 0.619155, -0.460871, -0.635803), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 12
		{ n = "BackPlate", s = "Block", z = Vector3.new(9.858452, 1.84846, 4.621149), cf = CFrame.new(0, 12.323064, 1.848473, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 108, 72), m = Enum.Material.Plastic }, -- 13
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.614779), cf = CFrame.new(-4.039642, 15.40383, 3.542877, -0.83583, 0.423987, 0.348745, 0, 0.63525, -0.772307, -0.548988, -0.645517, -0.530961), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 14
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.271807), cf = CFrame.new(-6.200043, 14.556619, 3.85096, -0.785269, 0.331624, 0.522855, 0, 0.844467, -0.535608, -0.619155, -0.420596, -0.663134), c = Color3.fromRGB(168, 220, 108), m = Enum.Material.Plastic }, -- 15
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.614779), cf = CFrame.new(4.039703, 15.40383, 3.542877, -0.83583, -0.423987, -0.348745, 0, 0.63525, -0.772307, 0.548988, -0.645517, -0.530961), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 16
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.271807), cf = CFrame.new(6.199982, 14.556619, 3.85096, -0.785269, -0.331624, -0.522855, 0, 0.844467, -0.535608, 0.619155, -0.420596, -0.663134), c = Color3.fromRGB(168, 220, 108), m = Enum.Material.Plastic }, -- 17
		{ n = "BackPlate", s = "Block", z = Vector3.new(8.009991, 1.84846, 4.313072), cf = CFrame.new(0, 12.323064, 6.161522, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(104, 72, 48), m = Enum.Material.Plastic }, -- 18
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.26503), cf = CFrame.new(-4.039642, 15.172773, 7.855949, -0.83583, 0.406515, 0.368963, 0, 0.672079, -0.74048, -0.548988, -0.618915, -0.561743), c = Color3.fromRGB(168, 220, 108), m = Enum.Material.Plastic }, -- 19
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.037426), cf = CFrame.new(-6.200043, 14.325561, 8.16404, -0.785269, 0.295726, 0.543966, 0, 0.878562, -0.477629, -0.619155, -0.375067, -0.689908), c = Color3.fromRGB(52, 112, 60), m = Enum.Material.Plastic }, -- 20
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.26503), cf = CFrame.new(4.039703, 15.172773, 7.855949, -0.83583, -0.406515, -0.368963, 0, 0.672079, -0.74048, 0.548988, -0.618915, -0.561743), c = Color3.fromRGB(168, 220, 108), m = Enum.Material.Plastic }, -- 21
		{ n = "Quill", s = "Block", z = Vector3.new(3.080766, 0.677768, 7.037426), cf = CFrame.new(6.200043, 14.325561, 8.16404, -0.785269, -0.295726, -0.543966, 0, 0.878562, -0.477629, 0.619155, -0.375067, -0.689907), c = Color3.fromRGB(52, 112, 60), m = Enum.Material.Plastic }, -- 22
		{ n = "Stem", s = "Block", z = Vector3.new(1.540383, 3.080766, 1.540383), cf = CFrame.new(0, 14.787677, 1.54039, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(238, 226, 192), m = Enum.Material.Plastic }, -- 23
		{ n = "Cap", s = "Block", z = Vector3.new(5.853455, 2.156536, 5.853455), cf = CFrame.new(0, 16.944212, 1.54039, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(214, 84, 58), m = Enum.Material.Plastic }, -- 24
		{ n = "CapSpot", s = "Block", z = Vector3.new(1.540383, 0.369692, 1.540383), cf = CFrame.new(1.23233, 18.114902, 0.616165, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(238, 226, 192), m = Enum.Material.Plastic }, -- 25
		{ n = "CapSpot", s = "Block", z = Vector3.new(1.386344, 0.369692, 1.386344), cf = CFrame.new(-1.386292, 18.114902, 2.618652, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(238, 226, 192), m = Enum.Material.Plastic }, -- 26
		{ n = "Stem", s = "Block", z = Vector3.new(1.232306, 2.156536, 1.232306), cf = CFrame.new(0.616165, 14.325562, 6.469604, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(238, 226, 192), m = Enum.Material.Plastic }, -- 27
		{ n = "Cap", s = "Block", z = Vector3.new(4.004995, 1.540383, 4.004995), cf = CFrame.new(0.616165, 16.019981, 6.469604, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(214, 84, 58), m = Enum.Material.Plastic }, -- 28
		{ n = "CapSpot", s = "Block", z = Vector3.new(1.232306, 0.369692, 1.232306), cf = CFrame.new(1.078262, 16.944212, 6.007477, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(238, 226, 192), m = Enum.Material.Plastic }, -- 29
		{ n = "Leg", s = "Block", z = Vector3.new(2.926728, 4.929226, 2.926728), cf = CFrame.new(-4.159042, 2.926727, -3.696915, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(104, 72, 48), m = Enum.Material.Plastic }, -- 30
		{ n = "Paw", s = "Block", z = Vector3.new(3.850957, 1.540383, 4.929226), cf = CFrame.new(-4.158981, 0.770191, -4.467094, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 44, 30), m = Enum.Material.Plastic }, -- 31
		{ n = "Leg", s = "Block", z = Vector3.new(2.926728, 4.929226, 2.926728), cf = CFrame.new(4.158981, 2.926727, -3.696915, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(104, 72, 48), m = Enum.Material.Plastic }, -- 32
		{ n = "Paw", s = "Block", z = Vector3.new(3.850957, 1.540383, 4.929226), cf = CFrame.new(4.159042, 0.770191, -4.467094, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 44, 30), m = Enum.Material.Plastic }, -- 33
		{ n = "Leg", s = "Block", z = Vector3.new(2.926728, 4.929226, 2.926728), cf = CFrame.new(-4.159042, 2.926727, 5.545418, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(104, 72, 48), m = Enum.Material.Plastic }, -- 34
		{ n = "Paw", s = "Block", z = Vector3.new(3.850957, 1.540383, 4.929226), cf = CFrame.new(-4.159103, 0.770191, 4.775177, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 44, 30), m = Enum.Material.Plastic }, -- 35
		{ n = "Leg", s = "Block", z = Vector3.new(2.926728, 4.929226, 2.926728), cf = CFrame.new(4.159042, 2.926727, 5.545357, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(104, 72, 48), m = Enum.Material.Plastic }, -- 36
		{ n = "Paw", s = "Block", z = Vector3.new(3.850957, 1.540383, 4.929226), cf = CFrame.new(4.159103, 0.770191, 4.775177, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 44, 30), m = Enum.Material.Plastic }, -- 37
		{ n = "Head", s = "Block", z = Vector3.new(8.009991, 6.777685, 6.777685), cf = CFrame.new(0, 8.934222, -9.242302, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 38
		{ n = "Snout", s = "Block", z = Vector3.new(4.929226, 3.080766, 3.696919), cf = CFrame.new(0, 7.393838, -13.863441, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 108, 72), m = Enum.Material.Plastic }, -- 39
		{ n = "Nose", s = "Block", z = Vector3.new(2.156536, 1.540383, 0.92423), cf = CFrame.new(0, 8.009992, -16.019966, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(30, 24, 18), m = Enum.Material.SmoothPlastic, st = false }, -- 40
		{ n = "Tuft", s = "Block", z = Vector3.new(5.545378, 1.232306, 3.696919), cf = CFrame.new(0, 12.631141, -10.782692, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(168, 220, 108), m = Enum.Material.Plastic }, -- 41
		{ n = "Tusk", s = "Block", z = Vector3.new(0.770191, 2.156536, 0.770191), cf = CFrame.new(-1.694427, 5.699417, -15.095741, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(238, 226, 192), m = Enum.Material.Plastic }, -- 42
		{ n = "Eye", s = "Block", z = Vector3.new(1.540383, 1.540383, 0.770191), cf = CFrame.new(-2.618683, 9.858452, -12.785179, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 190, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 43
		{ n = "Pupil", s = "Block", z = Vector3.new(0.616153, 1.04746, 0.308077), cf = CFrame.new(-2.618683, 9.858452, -13.247269, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(30, 24, 18), m = Enum.Material.SmoothPlastic, st = false }, -- 44
		{ n = "Brow", s = "Block", z = Vector3.new(2.926728, 0.770191, 0.92423), cf = CFrame.new(-2.618683, 11.244796, -12.785179, 0.951057, 0.309017, 0, -0.309017, 0.951057, 0, 0, 0, 1), c = Color3.fromRGB(34, 78, 46), m = Enum.Material.Plastic }, -- 45
		{ n = "Ear", s = "Block", z = Vector3.new(3.080766, 5.237302, 0.92423), cf = CFrame.new(-4.621185, 13.2473, -8.009964, 0.819152, -0.573577, 0, 0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 46
		{ n = "Tusk", s = "Block", z = Vector3.new(0.770191, 2.156536, 0.770191), cf = CFrame.new(1.694427, 5.699417, -15.095741, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(238, 226, 192), m = Enum.Material.Plastic }, -- 47
		{ n = "Eye", s = "Block", z = Vector3.new(1.540383, 1.540383, 0.770191), cf = CFrame.new(2.618622, 9.858452, -12.785179, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 190, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 48
		{ n = "Pupil", s = "Block", z = Vector3.new(0.616153, 1.04746, 0.308077), cf = CFrame.new(2.618683, 9.858452, -13.247269, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(30, 24, 18), m = Enum.Material.SmoothPlastic, st = false }, -- 49
		{ n = "Brow", s = "Block", z = Vector3.new(2.926728, 0.770191, 0.92423), cf = CFrame.new(2.618622, 11.244796, -12.785179, 0.951057, -0.309017, 0, 0.309017, 0.951057, 0, 0, 0, 1), c = Color3.fromRGB(34, 78, 46), m = Enum.Material.Plastic }, -- 50
		{ n = "Ear", s = "Block", z = Vector3.new(3.080766, 5.237302, 0.92423), cf = CFrame.new(4.621094, 13.247357, -8.009995, 0.819152, 0.573577, 0, -0.573576, 0.819152, 0, 0, 0, 1), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 51
		{ n = "SproutStem", s = "Block", z = Vector3.new(1.078268, 4.004995, 1.078268), cf = CFrame.new(0, 14.325562, -7.701912, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(34, 78, 46), m = Enum.Material.Plastic }, -- 52
		{ n = "SproutLeaf", s = "Block", z = Vector3.new(3.388843, 0.616153, 1.84846), cf = CFrame.new(-1.84845, 15.865947, -7.701942, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(168, 220, 108), m = Enum.Material.Plastic }, -- 53
		{ n = "SproutLeaf", s = "Block", z = Vector3.new(3.388843, 0.616153, 1.84846), cf = CFrame.new(1.848495, 15.865947, -7.701912, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(168, 220, 108), m = Enum.Material.Plastic }, -- 54
		{ n = "SproutBud", s = "Block", z = Vector3.new(1.540383, 1.540383, 1.540383), cf = CFrame.new(0, 16.790174, -7.701912, 0.707107, 0, 0.707107, 0.5, 0.707107, -0.5, -0.5, 0.707107, 0.5), c = Color3.fromRGB(255, 190, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 55
		{ n = "Tail", s = "Block", z = Vector3.new(3.080766, 3.080766, 5.28442), cf = CFrame.new(0, 8.626141, 9.088264, -1, 0, 0, 0, 0.988372, -0.152057, 0, -0.152057, -0.988372), c = Color3.fromRGB(104, 72, 48), m = Enum.Material.Plastic }, -- 56
		{ n = "Tail", s = "Block", z = Vector3.new(2.464613, 2.464613, 5.119126), cf = CFrame.new(0, 9.858447, 12.939178, -1, 0, 0, 0, 0.894427, -0.447213, 0, -0.447213, -0.894427), c = Color3.fromRGB(146, 108, 72), m = Enum.Material.Plastic }, -- 57
		{ n = "Bulb", s = "Block", z = Vector3.new(2.926728, 2.926728, 2.926728), cf = CFrame.new(0, 11.860942, 16.019951, 0.707107, 0, 0.707107, 0.5, 0.707107, -0.5, -0.5, 0.707107, 0.5), c = Color3.fromRGB(255, 190, 64), m = Enum.Material.Neon, st = false, cs = false, a = { ColA = Color3.new(1, 0.933333, 0.588235), ColB = Color3.new(1, 0.745098, 0.25098) } }, -- 58
		{ n = "BulbLeaf", s = "Block", z = Vector3.new(1.540383, 3.080766, 0.770191), cf = CFrame.new(-1.694427, 12.014987, 16.019958, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 59
		{ n = "BulbLeaf", s = "Block", z = Vector3.new(1.540383, 3.080766, 0.770191), cf = CFrame.new(1.694366, 12.014987, 16.019958, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(96, 176, 76), m = Enum.Material.Plastic }, -- 60
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 8.009991, 0.616167, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.308077, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 3, c0 = CFrame.new(0, -3.388843, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 4, c0 = CFrame.new(-5.6994, 0.616154, -0.924222, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 5, c0 = CFrame.new(-6.099915, -1.84846, 3.388831, 0.707107, 0, 0.707107, 0.5, 0.707107, -0.5, -0.5, 0.707107, 0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 6, c0 = CFrame.new(5.699342, 0.616154, -0.924251, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 7, c0 = CFrame.new(6.099915, -1.84846, 3.388831, 0.707107, 0, 0.707107, 0.5, 0.707107, -0.5, -0.5, 0.707107, 0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "BackA", h = 2, a = 2, b = 8, c0 = CFrame.new(0, 3.696919, -3.696945, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.308076, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "BackB", h = 2, a = 2, b = 13, c0 = CFrame.new(0, 3.696919, 1.232305, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.308076, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "BackC", h = 2, a = 2, b = 18, c0 = CFrame.new(0, 3.696919, 5.545359, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.308076, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipFL", h = 2, a = 2, b = 30, c0 = CFrame.new(-4.159041, -3.080766, -4.313083, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 2.310575, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipFR", h = 2, a = 2, b = 32, c0 = CFrame.new(4.158982, -3.080766, -4.313083, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 2.310575, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipHL", h = 2, a = 2, b = 34, c0 = CFrame.new(-4.159041, -3.080766, 4.92925, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 2.310575, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipHR", h = 2, a = 2, b = 36, c0 = CFrame.new(4.159041, -3.080766, 4.929192, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 2.310575, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Head", h = 2, a = 2, b = 38, c0 = CFrame.new(0, 0, -7.085776, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.616154, 2.772694, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail1", h = 2, a = 2, b = 56, c0 = CFrame.new(0, 0, 6.46958, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.000007, 2.026078, -1, 0, 0, 0, 0.988372, -0.152057, 0, -0.152057, -0.988372) },
		{ k = "Weld", n = "Hold", h = 8, a = 8, b = 9, c0 = CFrame.new(-4.039639, 3.311823, 1.694431, -0.83583, 0.438762, 0.329964, 0, 0.601039, -0.799219, -0.548988, -0.668012, -0.502367), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 8, a = 8, b = 10, c0 = CFrame.new(-6.200102, 2.464613, 2.002514, -0.785269, 0.363379, 0.501306, 0, 0.809663, -0.586895, -0.619155, -0.460871, -0.635803), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 8, a = 8, b = 11, c0 = CFrame.new(4.039639, 3.311823, 1.69446, -0.83583, -0.438762, -0.329964, 0, 0.601039, -0.799219, 0.548988, -0.668012, -0.502367), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 8, a = 8, b = 12, c0 = CFrame.new(6.200043, 2.464613, 2.002485, -0.785269, -0.363379, -0.501306, 0, 0.809663, -0.586895, 0.619155, -0.460871, -0.635803), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 13, a = 13, b = 14, c0 = CFrame.new(-4.039639, 3.080766, 1.694401, -0.83583, 0.423987, 0.348745, 0, 0.63525, -0.772307, -0.548988, -0.645517, -0.530961), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 13, a = 13, b = 15, c0 = CFrame.new(-6.200043, 2.233555, 2.002485, -0.785269, 0.331624, 0.522855, 0, 0.844467, -0.535608, -0.619155, -0.420596, -0.663134), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 13, a = 13, b = 16, c0 = CFrame.new(4.039698, 3.080766, 1.694401, -0.83583, -0.423987, -0.348745, 0, 0.63525, -0.772307, 0.548988, -0.645517, -0.530961), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 13, a = 13, b = 17, c0 = CFrame.new(6.199985, 2.233555, 2.002485, -0.785269, -0.331624, -0.522855, 0, 0.844467, -0.535608, 0.619155, -0.420596, -0.663134), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 13, a = 13, b = 23, c0 = CFrame.new(0, 2.464613, -0.308084, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 13, a = 13, b = 24, c0 = CFrame.new(0, 4.621149, -0.308084, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 13, a = 13, b = 25, c0 = CFrame.new(1.232334, 5.791839, -1.232305, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 13, a = 13, b = 26, c0 = CFrame.new(-1.386288, 5.791839, 0.77018, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 19, c0 = CFrame.new(-4.039639, 2.849709, 1.694431, -0.83583, 0.406515, 0.368963, 0, 0.672079, -0.74048, -0.548988, -0.618915, -0.561743), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 20, c0 = CFrame.new(-6.200043, 2.002497, 2.002514, -0.785269, 0.295726, 0.543966, 0, 0.878562, -0.477629, -0.619155, -0.375067, -0.689908), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 21, c0 = CFrame.new(4.039698, 2.849709, 1.694431, -0.83583, -0.406515, -0.368963, 0, 0.672079, -0.74048, 0.548988, -0.618915, -0.561743), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 22, c0 = CFrame.new(6.200043, 2.002497, 2.002514, -0.785269, -0.295726, -0.543966, 0, 0.878562, -0.477629, 0.619155, -0.375067, -0.689907), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 27, c0 = CFrame.new(0.616167, 2.002498, 0.308084, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 28, c0 = CFrame.new(0.616167, 3.696918, 0.308084, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 18, a = 18, b = 29, c0 = CFrame.new(1.078263, 4.621149, -0.154042, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AnkleFL", h = 30, a = 30, b = 31, c0 = CFrame.new(0, -1.694421, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.000059, 0.462115, 0.77018, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AnkleFR", h = 32, a = 32, b = 33, c0 = CFrame.new(0, -1.694421, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.000059, 0.462115, 0.77018, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AnkleHL", h = 34, a = 34, b = 35, c0 = CFrame.new(0, -1.694421, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.000059, 0.462115, 0.770238, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AnkleHR", h = 36, a = 36, b = 37, c0 = CFrame.new(0, -1.694421, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.000059, 0.462115, 0.77018, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 39, c0 = CFrame.new(0, -1.540383, -4.621137, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 40, c0 = CFrame.new(0, -0.924231, -6.777663, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 41, c0 = CFrame.new(0, 3.696918, -1.540389, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 42, c0 = CFrame.new(-1.694431, -3.234805, -5.853442, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 43, c0 = CFrame.new(-2.618682, 0.92423, -3.542874, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 44, c0 = CFrame.new(-2.618682, 0.92423, -4.00497, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 45, c0 = CFrame.new(-2.618682, 2.310574, -3.542874, 0.951057, 0.309017, 0, -0.309017, 0.951057, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "EarL", h = 38, a = 38, b = 46, c0 = CFrame.new(-3.696945, 2.464612, 1.232334, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.303148, -2.044293, 0, 0.819152, 0.573576, 0, -0.573577, 0.819152, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 47, c0 = CFrame.new(1.694431, -3.234805, -5.853442, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 48, c0 = CFrame.new(2.618623, 0.92423, -3.542874, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 49, c0 = CFrame.new(2.618682, 0.92423, -4.00497, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 38, a = 38, b = 50, c0 = CFrame.new(2.618623, 2.310574, -3.542874, 0.951057, -0.309017, 0, 0.309017, 0.951057, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "EarR", h = 38, a = 38, b = 51, c0 = CFrame.new(3.696886, 2.464612, 1.232305, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.303206, -2.044323, 0, 0.819152, -0.573576, 0, 0.573577, 0.819152, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Sprout", h = 38, a = 38, b = 52, c0 = CFrame.new(0, 3.388842, 1.540389, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -2.002498, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 52, a = 52, b = 53, c0 = CFrame.new(-1.848443, 1.540384, -0.000029, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 52, a = 52, b = 54, c0 = CFrame.new(1.848502, 1.540384, 0, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 52, a = 52, b = 55, c0 = CFrame.new(0, 2.464613, 0, 0.707107, 0, 0.707107, 0.5, 0.707107, -0.5, -0.5, 0.707107, 0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail2", h = 56, a = 56, b = 57, c0 = CFrame.new(0, 0.000004, -2.026048, -1, 0, 0, 0, 0.988372, -0.152057, 0, -0.152057, -0.988372), c1 = CFrame.new(0, -0.000015, 2.066607, -1, 0, 0, 0, 0.894427, -0.447213, 0, -0.447213, -0.894427) },
		{ k = "Weld", n = "Hold", h = 57, a = 57, b = 58, c0 = CFrame.new(0, 0.413325, -3.651067, -0.707107, 0, -0.707107, 0.67082, 0.316228, -0.67082, 0.223607, -0.948683, -0.223607), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 57, a = 57, b = 59, c0 = CFrame.new(1.694431, 0.551104, -3.719964, -0.906308, 0.422618, 0, 0.378001, 0.810626, -0.447213, -0.189001, -0.405313, -0.894427), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 57, a = 57, b = 60, c0 = CFrame.new(-1.694372, 0.551104, -3.719964, -0.906308, -0.422618, 0, -0.378001, 0.810626, -0.447213, 0.189001, -0.405313, -0.894427), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "BulbLight", p = 58, range = 11.2, brightness = 1.2, color = Color3.new(1, 0.745098, 0.25098), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Spores", p = 55, rate = 2, enabled = true, lifetime = NumberRange.new(1.5, 2.5), speed = NumberRange.new(1.232306, 3.080766), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(0.3, 0.770191, 0), NumberSequenceKeypoint.new(1, 0, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.658824, 0.862745, 0.423529)), ColorSequenceKeypoint.new(1, Color3.new(1, 0.933333, 0.588235)) }), lightEmission = 0.8, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(180, 180), acceleration = Vector3.new(0, 1.848459, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
