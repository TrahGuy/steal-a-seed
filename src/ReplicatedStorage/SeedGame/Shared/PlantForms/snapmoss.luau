--!strict
--==============================================================================
-- PLANT FORM: Snapmoss (Tanglemire)
--
-- Lifted part for part, joint for joint, from the owner's supplied Workspace
-- model "Tanglemire/Snapmoss" by a read-only generator on 2026-10-03. The original
-- was not moved or changed; a verified .rbxm of it is in
-- output/model-backups/2026-10-03-plant-originals.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the model's BASE:
-- its root part's x/z at the lowest drawn point, facing the way the root
-- faces), colour, material, surface, attribute and joint is the supplied
-- number, at the size it was supplied. WeldConstraints are recorded as Welds
-- (C0 = Part1 in Part0's frame, C1 = identity), which hold the same parts in
-- the same place. The size a tier builds it at is PlantForms' (the parent
-- module); see there. Joints point at parts by INDEX, because names repeat.
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "Tanglemire/Snapmoss", Kind = "plant", Yaw = 0,
	Size = Vector3.new(6.966896, 3.171251, 13.744385), Height = 3.171251, PartCount = 47,
	Base = 3,
	Unit = 4.5, ModelScale = 1.460564,
	Attributes = {},
	Parts = {
		{ n = "Body", s = "Block", z = Vector3.new(4.206425, 1.445958, 5.520933), cf = CFrame.new(0, 1.906037, 0.394352, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(58, 85, 51), m = Enum.Material.Plastic }, -- 1
		{ n = "Head", s = "Block", z = Vector3.new(3.680622, 1.183057, 1.906036), cf = CFrame.new(0, 2.037488, -2.826191, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(79, 104, 57), m = Enum.Material.Plastic }, -- 2
		{ n = "Footing", s = "Block", z = Vector3.new(1.70886, 0.262902, 1.70886), cf = CFrame.new(0, 0.131451, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 39, 27), m = Enum.Material.Plastic, t = 1, cs = false }, -- 3
		{ n = "UpperSnout", s = "Block", z = Vector3.new(4.206425, 0.722979, 2.760466), cf = CFrame.new(0.000002, 1.741723, -4.469322, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(58, 85, 51), m = Enum.Material.Plastic }, -- 4
		{ n = "MossPatch3", s = "Block", z = Vector3.new(3.614897, 0.558666, 1.314508), cf = CFrame.new(0.000002, 2.891917, 1.840309, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(81, 129, 47), m = Enum.Material.Plastic }, -- 5
		{ n = "LegFrontR", s = "Block", z = Vector3.new(0.690117, 0.690117, 1.693625), cf = CFrame.new(-2.300388, 1.051607, -1.183056, -0.216931, -0.681901, 0.698536, 0, 0.715576, 0.698536, -0.976187, 0.151534, -0.15523), c = Color3.fromRGB(79, 104, 57), m = Enum.Material.Plastic }, -- 6
		{ n = "MossBrowL", s = "Block", z = Vector3.new(0.821567, 0.295764, 0.657254), cf = CFrame.new(1.347372, 2.780185, -3.614899, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(81, 129, 47), m = Enum.Material.Plastic }, -- 7
		{ n = "MossStrand4", s = "Wedge", z = Vector3.new(0.427215, 1.183057, 0.230039), cf = CFrame.new(2.694742, 1.281646, -0.657253, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(148, 178, 77), m = Enum.Material.Plastic }, -- 8
		{ n = "MossFrond4", s = "Block", z = Vector3.new(0.788705, 0.230039, 1.783388), cf = CFrame.new(1.971764, 2.382546, -1.051609, -0.371391, 0.564602, -0.737085, 0, 0.793864, 0.608095, 0.928477, 0.225841, -0.294834), c = Color3.fromRGB(113, 153, 58), m = Enum.Material.Plastic }, -- 9
		{ n = "TailTip", s = "Block", z = Vector3.new(0.722979, 0.525803, 2.088786), cf = CFrame.new(0, 1.21592, 6.013878, -1, 0, 0, 0, 0.975441, 0.220261, 0, 0.220261, -0.975441), c = Color3.fromRGB(79, 104, 57), m = Enum.Material.Plastic }, -- 10
		{ n = "TailStem", s = "Block", z = Vector3.new(1.183057, 0.788705, 2.104239), cf = CFrame.new(0, 1.708861, 3.976387, -1, 0, 0, 0, 0.968277, 0.249878, 0, 0.249878, -0.968277), c = Color3.fromRGB(58, 85, 51), m = Enum.Material.Plastic }, -- 11
		{ n = "MossFrond2", s = "Block", z = Vector3.new(0.788705, 0.230039, 1.783388), cf = CFrame.new(-1.97176, 2.382546, 0.525803, -0.371391, -0.564602, 0.737085, 0, 0.793864, 0.608095, -0.928477, 0.225841, -0.294834), c = Color3.fromRGB(148, 178, 77), m = Enum.Material.Plastic }, -- 12
		{ n = "FootBackR", s = "Block", z = Vector3.new(1.183057, 0.525803, 1.445958), cf = CFrame.new(-2.891918, 0.262902, 2.168938, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 127, 68), m = Enum.Material.Plastic }, -- 13
		{ n = "LegBackR", s = "Block", z = Vector3.new(0.690117, 0.690117, 1.693625), cf = CFrame.new(-2.300386, 1.051607, 2.168938, -0.216931, -0.681901, 0.698536, 0, 0.715576, 0.698536, -0.976187, 0.151534, -0.15523), c = Color3.fromRGB(79, 104, 57), m = Enum.Material.Plastic }, -- 14
		{ n = "LowerToothR1", s = "Wedge", z = Vector3.new(0.302337, 0.302337, 0.36149), cf = CFrame.new(-1.728579, 1.367088, -4.107838, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(211, 214, 163), m = Enum.Material.SmoothPlastic, st = false }, -- 15
		{ n = "Jaw", s = "Block", z = Vector3.new(4.206425, 0.460078, 3.351995), cf = CFrame.new(0, 1.117332, -4.107838, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 127, 68), m = Enum.Material.Plastic }, -- 16
		{ n = "UpperToothR1", s = "Wedge", z = Vector3.new(0.302337, 0.315482, 0.36149), cf = CFrame.new(-1.728577, 1.367088, -3.713486, -1, 0, 0, 0, -1, 0, 0, 0, 1), c = Color3.fromRGB(211, 214, 163), m = Enum.Material.SmoothPlastic, st = false }, -- 17
		{ n = "MossFrond3", s = "Block", z = Vector3.new(0.788705, 0.230039, 1.783388), cf = CFrame.new(-1.97176, 2.382545, 2.103214, -0.371391, -0.564602, 0.737085, 0, 0.793865, 0.608095, -0.928477, 0.225841, -0.294834), c = Color3.fromRGB(113, 153, 58), m = Enum.Material.Plastic }, -- 18
		{ n = "MossStrand3", s = "Wedge", z = Vector3.new(0.427215, 1.183057, 0.230039), cf = CFrame.new(-2.694738, 1.281645, 2.497566, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(148, 178, 77), m = Enum.Material.Plastic }, -- 19
		{ n = "NostrilR", s = "Block", z = Vector3.new(0.322054, 0.07887, 0.427215), cf = CFrame.new(-1.248783, 2.129503, -5.218597, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 39, 27), m = Enum.Material.SmoothPlastic, st = false }, -- 20
		{ n = "UpperToothR2", s = "Wedge", z = Vector3.new(0.302337, 0.315482, 0.36149), cf = CFrame.new(-1.728577, 1.367088, -5.027992, -1, 0, 0, 0, -1, 0, 0, 0, 1), c = Color3.fromRGB(211, 214, 163), m = Enum.Material.SmoothPlastic, st = false }, -- 21
		{ n = "MossBrowR", s = "Block", z = Vector3.new(0.821567, 0.295764, 0.657254), cf = CFrame.new(-1.347368, 2.780185, -3.614895, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(81, 129, 47), m = Enum.Material.Plastic }, -- 22
		{ n = "EyeL", s = "Block", z = Vector3.new(0.558666, 0.49294, 0.243184), cf = CFrame.new(1.347372, 2.464703, -3.884369, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(227, 187, 66), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 23
		{ n = "EyeR", s = "Block", z = Vector3.new(0.558666, 0.49294, 0.243184), cf = CFrame.new(-1.34737, 2.464703, -3.884369, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(227, 187, 66), m = Enum.Material.Neon, st = false, cs = false, a = { Blink = true } }, -- 24
		{ n = "LowerToothR2", s = "Wedge", z = Vector3.new(0.302337, 0.302337, 0.36149), cf = CFrame.new(-1.728579, 1.367088, -5.422342, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(211, 214, 163), m = Enum.Material.SmoothPlastic, st = false }, -- 25
		{ n = "UpperToothL1", s = "Wedge", z = Vector3.new(0.302337, 0.315482, 0.36149), cf = CFrame.new(1.728577, 1.367088, -3.713482, -1, 0, 0, 0, -1, 0, 0, 0, 1), c = Color3.fromRGB(211, 214, 163), m = Enum.Material.SmoothPlastic, st = false }, -- 26
		{ n = "MouthFloor", s = "Block", z = Vector3.new(3.220544, 0.118306, 2.629016), cf = CFrame.new(0, 1.373661, -4.272148, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(70, 45, 40), m = Enum.Material.SmoothPlastic, st = false }, -- 27
		{ n = "MossFrond5", s = "Block", z = Vector3.new(0.788705, 0.230039, 1.783388), cf = CFrame.new(1.971762, 2.382546, 0.525803, -0.371391, 0.564602, -0.737085, 0, 0.793864, 0.608095, 0.928477, 0.225841, -0.294834), c = Color3.fromRGB(148, 178, 77), m = Enum.Material.Plastic }, -- 28
		{ n = "MossStrand6", s = "Wedge", z = Vector3.new(0.427215, 1.183057, 0.230039), cf = CFrame.new(2.694744, 1.281645, 2.49757, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(148, 178, 77), m = Enum.Material.Plastic }, -- 29
		{ n = "MossFrond6", s = "Block", z = Vector3.new(0.788705, 0.230039, 1.783388), cf = CFrame.new(1.971764, 2.382545, 2.103214, -0.371391, 0.564602, -0.737085, 0, 0.793865, 0.608095, 0.928477, 0.225841, -0.294834), c = Color3.fromRGB(113, 153, 58), m = Enum.Material.Plastic }, -- 30
		{ n = "LowerToothL1", s = "Wedge", z = Vector3.new(0.302337, 0.302337, 0.36149), cf = CFrame.new(1.728577, 1.367088, -4.107838, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(211, 214, 163), m = Enum.Material.SmoothPlastic, st = false }, -- 31
		{ n = "FootFrontR", s = "Block", z = Vector3.new(1.183057, 0.525803, 1.445958), cf = CFrame.new(-2.891918, 0.262902, -1.183056, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 127, 68), m = Enum.Material.Plastic }, -- 32
		{ n = "MossPatch2", s = "Block", z = Vector3.new(3.614897, 0.558666, 1.314508), cf = CFrame.new(0, 2.891917, 0.328629, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(113, 153, 58), m = Enum.Material.Plastic }, -- 33
		{ n = "MossStrand1", s = "Wedge", z = Vector3.new(0.427215, 1.183057, 0.230039), cf = CFrame.new(-2.69474, 1.281646, -0.657249, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(148, 178, 77), m = Enum.Material.Plastic }, -- 34
		{ n = "MossFrond1", s = "Block", z = Vector3.new(0.788705, 0.230039, 1.783388), cf = CFrame.new(-1.97176, 2.382546, -1.051605, -0.371391, -0.564602, 0.737085, 0, 0.793864, 0.608095, -0.928477, 0.225841, -0.294834), c = Color3.fromRGB(113, 153, 58), m = Enum.Material.Plastic }, -- 35
		{ n = "LowerToothL2", s = "Wedge", z = Vector3.new(0.302337, 0.302337, 0.36149), cf = CFrame.new(1.728579, 1.367088, -5.422344, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(211, 214, 163), m = Enum.Material.SmoothPlastic, st = false }, -- 36
		{ n = "TailLeaf", s = "Wedge", z = Vector3.new(0.985881, 1.117332, 0.328627), cf = CFrame.new(0, 1.183058, 7.361244, 1, 0, 0, 0, 0.642788, -0.766044, 0, 0.766044, 0.642788), c = Color3.fromRGB(113, 153, 58), m = Enum.Material.Plastic }, -- 37
		{ n = "EyeShineL", s = "Block", z = Vector3.new(0.144596, 0.144596, 0.07887), cf = CFrame.new(1.288219, 2.596153, -4.048683, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 236, 154), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 38
		{ n = "EyeShineR", s = "Block", z = Vector3.new(0.144596, 0.144596, 0.07887), cf = CFrame.new(-1.288218, 2.596153, -4.048687, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 236, 154), m = Enum.Material.Neon, st = false, cs = false, a = { HideOnBlink = true } }, -- 39
		{ n = "LegFrontL", s = "Block", z = Vector3.new(0.690117, 0.690117, 1.693625), cf = CFrame.new(2.30039, 1.051607, -1.18306, -0.216931, 0.681901, -0.698536, 0, 0.715576, 0.698536, 0.976187, 0.151534, -0.15523), c = Color3.fromRGB(79, 104, 57), m = Enum.Material.Plastic }, -- 40
		{ n = "UpperToothL2", s = "Wedge", z = Vector3.new(0.302337, 0.315482, 0.36149), cf = CFrame.new(1.728579, 1.367088, -5.027992, -1, 0, 0, 0, -1, 0, 0, 0, 1), c = Color3.fromRGB(211, 214, 163), m = Enum.Material.SmoothPlastic, st = false }, -- 41
		{ n = "NostrilL", s = "Block", z = Vector3.new(0.322054, 0.07887, 0.427215), cf = CFrame.new(1.248785, 2.129503, -5.218594, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(25, 39, 27), m = Enum.Material.SmoothPlastic, st = false }, -- 42
		{ n = "FootBackL", s = "Block", z = Vector3.new(1.183057, 0.525803, 1.445958), cf = CFrame.new(2.89192, 0.262902, 2.168938, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 127, 68), m = Enum.Material.Plastic }, -- 43
		{ n = "LegBackL", s = "Block", z = Vector3.new(0.690117, 0.690117, 1.693625), cf = CFrame.new(2.30039, 1.051607, 2.168938, -0.216931, 0.681901, -0.698536, 0, 0.715576, 0.698536, 0.976187, 0.151534, -0.15523), c = Color3.fromRGB(79, 104, 57), m = Enum.Material.Plastic }, -- 44
		{ n = "MossPatch1", s = "Block", z = Vector3.new(3.614897, 0.558666, 1.314508), cf = CFrame.new(0.000002, 2.891917, -1.183056, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(81, 129, 47), m = Enum.Material.Plastic }, -- 45
		{ n = "FootFrontL", s = "Block", z = Vector3.new(1.183057, 0.525803, 1.445958), cf = CFrame.new(2.89192, 0.262902, -1.18306, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 127, 68), m = Enum.Material.Plastic }, -- 46
		{ n = "Belly", s = "Block", z = Vector3.new(3.746347, 0.460078, 4.99513), cf = CFrame.new(0, 1.117332, 0.394352, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 127, 68), m = Enum.Material.Plastic }, -- 47
	},
	Joints = {
		{ k = "Motor6D", n = "Head", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0.065726, -2.56329, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.065725, 0.657254, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MossPatch3", h = 1, a = 1, b = 5, c0 = CFrame.new(0, 0.985881, 1.445958, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipFrontR", h = 1, a = 1, b = 6, c0 = CFrame.new(-1.70886, -0.262901, -1.70886, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.846813, -0.216931, 0, -0.976187, -0.681901, 0.715576, 0.151534, 0.698536, 0.698536, -0.15523) },
		{ k = "Motor6D", n = "Moss4", h = 1, a = 1, b = 9, c0 = CFrame.new(1.314508, 1.018744, -1.70886, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.891694, -0.371391, 0, 0.928477, 0.564602, 0.793864, 0.225841, -0.737085, 0.608095, -0.294834) },
		{ k = "Motor6D", n = "Tail1", h = 1, a = 1, b = 11, c0 = CFrame.new(0, 0.065726, 2.56329, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.05212, -1, 0, 0, 0, 0.968277, 0.249878, 0, 0.249878, -0.968277) },
		{ k = "Motor6D", n = "Moss2", h = 1, a = 1, b = 12, c0 = CFrame.new(-1.314508, 1.018744, -0.131451, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.891694, -0.371391, 0, -0.928477, -0.564602, 0.793864, 0.225841, 0.737085, 0.608095, -0.294834) },
		{ k = "Motor6D", n = "HipBackR", h = 1, a = 1, b = 14, c0 = CFrame.new(-1.70886, -0.262901, 1.643135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.846813, -0.216931, 0, -0.976187, -0.681901, 0.715576, 0.151534, 0.698536, 0.698536, -0.15523) },
		{ k = "Motor6D", n = "Moss3", h = 1, a = 1, b = 18, c0 = CFrame.new(-1.314508, 1.018744, 1.445958, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.891694, -0.371391, 0, -0.928477, -0.564602, 0.793864, 0.225841, 0.737085, 0.608095, -0.294834) },
		{ k = "Motor6D", n = "Moss5", h = 1, a = 1, b = 28, c0 = CFrame.new(1.314508, 1.018744, -0.131451, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.891694, -0.371391, 0, 0.928477, 0.564602, 0.793864, 0.225841, -0.737085, 0.608095, -0.294834) },
		{ k = "Motor6D", n = "Moss6", h = 1, a = 1, b = 30, c0 = CFrame.new(1.314508, 1.018744, 1.445958, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.891694, -0.371391, 0, 0.928477, 0.564602, 0.793864, 0.225841, -0.737085, 0.608095, -0.294834) },
		{ k = "Weld", n = "Hold_MossPatch2", h = 1, a = 1, b = 33, c0 = CFrame.new(0, 0.985881, -0.065725, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Moss1", h = 1, a = 1, b = 35, c0 = CFrame.new(-1.314508, 1.018744, -1.70886, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.891694, -0.371391, 0, -0.928477, -0.564602, 0.793864, 0.225841, 0.737085, 0.608095, -0.294834) },
		{ k = "Motor6D", n = "HipFrontL", h = 1, a = 1, b = 40, c0 = CFrame.new(1.70886, -0.262901, -1.70886, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.846813, -0.216931, 0, 0.976187, 0.681901, 0.715576, 0.151534, -0.698536, 0.698536, -0.15523) },
		{ k = "Motor6D", n = "HipBackL", h = 1, a = 1, b = 44, c0 = CFrame.new(1.70886, -0.262901, 1.643135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.846813, -0.216931, 0, 0.976187, 0.681901, 0.715576, 0.151534, -0.698536, 0.698536, -0.15523) },
		{ k = "Weld", n = "Hold_MossPatch1", h = 1, a = 1, b = 45, c0 = CFrame.new(0, 0.985881, -1.57741, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_Belly", h = 1, a = 1, b = 47, c0 = CFrame.new(0, -0.788705, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_UpperSnout", h = 2, a = 2, b = 4, c0 = CFrame.new(0, -0.295764, -1.643135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MossBrowL", h = 2, a = 2, b = 7, c0 = CFrame.new(1.347371, 0.742697, -0.788705, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Jaw", h = 2, a = 2, b = 16, c0 = CFrame.new(0, -0.690117, 0.328627, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.230039, 1.610272, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_UpperToothR1", h = 2, a = 2, b = 17, c0 = CFrame.new(-1.728578, -0.670399, -0.887293, -1, 0, 0, 0, -1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_NostrilR", h = 2, a = 2, b = 20, c0 = CFrame.new(-1.248783, 0.092015, -2.392405, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_UpperToothR2", h = 2, a = 2, b = 21, c0 = CFrame.new(-1.728578, -0.670399, -2.2018, -1, 0, 0, 0, -1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MossBrowR", h = 2, a = 2, b = 22, c0 = CFrame.new(-1.347371, 0.742697, -0.788705, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeL", h = 2, a = 2, b = 23, c0 = CFrame.new(1.347371, 0.427215, -1.058179, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeR", h = 2, a = 2, b = 24, c0 = CFrame.new(-1.347371, 0.427215, -1.058179, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_UpperToothL1", h = 2, a = 2, b = 26, c0 = CFrame.new(1.728578, -0.670399, -0.887293, -1, 0, 0, 0, -1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShineL", h = 2, a = 2, b = 38, c0 = CFrame.new(1.288218, 0.558666, -1.222492, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_EyeShineR", h = 2, a = 2, b = 39, c0 = CFrame.new(-1.288218, 0.558666, -1.222492, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_UpperToothL2", h = 2, a = 2, b = 41, c0 = CFrame.new(1.728578, -0.670399, -2.2018, -1, 0, 0, 0, -1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_NostrilL", h = 2, a = 2, b = 42, c0 = CFrame.new(1.248783, 0.092015, -2.392405, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Root", h = 3, a = 3, b = 1, c0 = CFrame.new(0, 1.643135, 0.394352, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.131451, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AnkleFrontR", h = 6, a = 6, b = 32, c0 = CFrame.new(0, 0, -0.846813, -0.216931, 0, -0.976187, -0.681901, 0.715576, 0.151534, 0.698536, 0.698536, -0.15523), c1 = CFrame.new(0, 0.197176, 0.131451, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MossStrand4", h = 9, a = 9, b = 8, c0 = CFrame.new(0.097639, -0.376709, -1.318617, -0.363275, -0.077216, 0.928477, 0.38721, 0.893904, 0.225841, -0.847408, 0.441558, -0.294834), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_TailLeaf", h = 10, a = 10, b = 37, c0 = CFrame.new(0, 0.264717, -1.321517, -1, 0, 0, 0, 0.795731, -0.60565, 0, -0.60565, -0.795731), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Tail2", h = 11, a = 11, b = 10, c0 = CFrame.new(0, 0, -1.05212, -1, 0, 0, 0, 0.968277, 0.249878, 0, 0.249878, -0.968277), c1 = CFrame.new(0, 0, 1.044394, -1, 0, 0, 0, 0.975441, 0.220261, 0, 0.220261, -0.975441) },
		{ k = "Motor6D", n = "AnkleBackR", h = 14, a = 14, b = 13, c0 = CFrame.new(0, 0, -0.846813, -0.216931, 0, -0.976187, -0.681901, 0.715576, 0.151534, 0.698536, 0.698536, -0.15523), c1 = CFrame.new(0, 0.197176, 0.131451, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LowerToothR1", h = 16, a = 16, b = 15, c0 = CFrame.new(-1.728578, 0.249757, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LowerToothR2", h = 16, a = 16, b = 25, c0 = CFrame.new(-1.728578, 0.249757, -1.314507, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MouthFloor", h = 16, a = 16, b = 27, c0 = CFrame.new(0, 0.256329, -0.164313, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LowerToothL1", h = 16, a = 16, b = 31, c0 = CFrame.new(1.728578, 0.249757, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_LowerToothL2", h = 16, a = 16, b = 36, c0 = CFrame.new(1.728578, 0.249757, -1.314507, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MossStrand3", h = 18, a = 18, b = 19, c0 = CFrame.new(-0.097639, -0.376709, -1.318617, -0.363275, 0.077217, -0.928477, -0.38721, 0.893904, 0.225841, 0.847408, 0.441558, -0.294834), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MossStrand6", h = 30, a = 30, b = 29, c0 = CFrame.new(0.097639, -0.376709, -1.318617, -0.363275, -0.077217, 0.928477, 0.38721, 0.893904, 0.225841, -0.847408, 0.441558, -0.294834), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold_MossStrand1", h = 35, a = 35, b = 34, c0 = CFrame.new(-0.097639, -0.376709, -1.318617, -0.363275, 0.077216, -0.928477, -0.38721, 0.893904, 0.225841, 0.847408, 0.441558, -0.294834), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AnkleFrontL", h = 40, a = 40, b = 46, c0 = CFrame.new(0, 0, -0.846813, -0.216931, 0, 0.976187, 0.681901, 0.715576, 0.151534, -0.698536, 0.698536, -0.15523), c1 = CFrame.new(0, 0.197176, 0.131451, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AnkleBackL", h = 44, a = 44, b = 43, c0 = CFrame.new(0, 0, -0.846813, -0.216931, 0, 0.976187, 0.681901, 0.715576, 0.151534, -0.698536, 0.698536, -0.15523), c1 = CFrame.new(0, 0.197176, 0.131451, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
	},
}

return spec
