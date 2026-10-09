--!strict
--==============================================================================
-- POD FORM: Novaorb (starbloom pods/NovaorbPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "starbloom pods/NovaorbPod" by a read-only generator on 2026-10-09. The original was
-- not changed (moved, intact, to ServerStorage that day); a verified .rbxm of it is in
-- output/model-backups/2026-10-09-pod-originals.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the model's BASE:
-- the drawn bounding box's bottom centre, its -Z the pod's front -- a lid pod's
-- root looks that way, a studded pod's root the other), colour, material,
-- surface, SpecialMesh, stud texture, light,
-- attribute and joint is the supplied number, at the size it was supplied.
-- WeldConstraints are recorded as Welds (C0 = Part1 in Part0's frame, C1 =
-- identity), which hold the same parts in the same place. Joints point at
-- parts by INDEX, because names repeat.
--
--   g    the owner's folder the part sat in (SizeSeam, GlowAccents)
--   an   a part the owner anchored besides the root: it stood still while the
--        idle moved the root, so PodMotion keeps it still
--   sm   its SpecialMesh: type, scale and offset
--   Textures  one record per part and setting, its faces listed ("Studs_%s"
--        names each texture after its face, as the owner did)
--   Owner     the owner's model attributes, kept apart from the ones the game
--        writes on a pod
--   Removed   the base the pod stood on, left out (the owner, 2026-10-09:
--        "remove the base if there is a base below the pods"): measured from
--        what stays, so the pod's own lowest point is its base
--
-- The pod's own Script is not here: PodMotion (client) plays its idle. The
-- size a tier builds it at is PodForms' (the parent module); see there.
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "starbloom pods/NovaorbPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(3.114372, 3.833224, 3.11441), Height = 3.833224, PartCount = 47,
	Base = 0, Root = 22,
	Attributes = {},
	Owner = { Biome = "starbloom", BottomOffset = 0, ClosedDepth = 0.978472, ClosedHeight = 1.374321, ClosedWidth = 0.978471, IsPod = true, OpenAmount = 0, OpenDuration = 0.45, PartCount = 49, RareLightEnabled = true, Rarity = "Rare", RulesVersion = "2026-10-09", ShellCentre = Vector3.new(0, 0.415568, 0.000161), SizeSeamRole = "Seam", SpawnMode = "CameraAir", Species = "Novaorb", Unit = 1, WidthClassUnit = 1 },
	Removed = { "SeedBase", "BulbPlinth" },
	Parts = {
		{ n = "Seam_01", s = "Block", z = Vector3.new(0.175059, 0.206888, 1.184255), cf = CFrame.new(0.517687, 0.92304, 1.249725, 0.382683, 0, -0.923879, 0, 1.000001, 0, 0.92388, 0, 0.382684), c = Color3.fromRGB(88, 72, 136), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.345098, 0.282353, 0.533333), TintRole = "Seam" } }, -- 1
		{ n = "Seam_02", s = "Block", z = Vector3.new(0.175059, 0.206888, 1.184255), cf = CFrame.new(1.249722, 0.923042, 0.517639, 0.92388, 0, -0.382683, 0, 1.000001, 0, 0.382684, 0, 0.92388), c = Color3.fromRGB(88, 72, 136), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.345098, 0.282353, 0.533333), TintRole = "Seam" } }, -- 2
		{ n = "Seam_03", s = "Block", z = Vector3.new(0.175059, 0.206888, 1.184255), cf = CFrame.new(1.24972, 0.923037, -0.51767, 0.92388, 0, 0.382683, 0, 1.000001, 0, -0.382684, 0, 0.92388), c = Color3.fromRGB(88, 72, 136), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.345098, 0.282353, 0.533333), TintRole = "Seam" } }, -- 3
		{ n = "Seam_04", s = "Block", z = Vector3.new(0.175059, 0.206888, 1.184255), cf = CFrame.new(0.517685, 0.923041, -1.249756, 0.382683, 0, 0.923879, 0, 1.000001, 0, -0.92388, 0, 0.382684), c = Color3.fromRGB(88, 72, 136), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.345098, 0.282353, 0.533333), TintRole = "Seam" } }, -- 4
		{ n = "Seam_05", s = "Block", z = Vector3.new(0.175059, 0.206888, 1.184255), cf = CFrame.new(-0.517639, 0.923037, -1.249725, -0.382683, 0, 0.923879, 0, 1.000001, 0, -0.92388, 0, -0.382684), c = Color3.fromRGB(88, 72, 136), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.345098, 0.282353, 0.533333), TintRole = "Seam" } }, -- 5
		{ n = "Seam_06", s = "Block", z = Vector3.new(0.175059, 0.206888, 1.184255), cf = CFrame.new(-1.249674, 0.923038, -0.51767, -0.92388, 0, 0.382683, 0, 1.000001, 0, -0.382684, 0, -0.92388), c = Color3.fromRGB(88, 72, 136), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.345098, 0.282353, 0.533333), TintRole = "Seam" } }, -- 6
		{ n = "Seam_07", s = "Block", z = Vector3.new(0.175059, 0.206888, 1.184255), cf = CFrame.new(-1.249722, 0.92304, 0.517609, -0.92388, 0, -0.382683, 0, 1.000001, 0, 0.382684, 0, -0.92388), c = Color3.fromRGB(88, 72, 136), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.345098, 0.282353, 0.533333), TintRole = "Seam" } }, -- 7
		{ n = "Seam_08", s = "Block", z = Vector3.new(0.175059, 0.206888, 1.184255), cf = CFrame.new(-0.517633, 0.923041, 1.249695, -0.382684, 0, -0.923879, 0, 1.000001, 0, 0.92388, 0, -0.382684), c = Color3.fromRGB(88, 72, 136), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.345098, 0.282353, 0.533333), TintRole = "Seam" } }, -- 8
		{ n = "FrontStar_Low", s = "Block", z = Vector3.new(0.254631, 0.254631, 0.159145), cf = CFrame.new(0.000011, 0.477437, 1.336823, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 9
		{ n = "FlankStar_RF1", s = "Block", z = Vector3.new(0.254631, 0.254631, 0.159145), cf = CFrame.new(0.967785, 0.668409, 0.967743, 0.707107, 0, 0.707107, 0, 1.000001, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 10
		{ n = "FlankStar_RF2", s = "Block", z = Vector3.new(0.254631, 0.254631, 0.159145), cf = CFrame.new(0.922756, 1.241326, 0.922729, 0.707107, 0, 0.707107, 0, 1.000001, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 11
		{ n = "SideStar_Right", s = "Block", z = Vector3.new(0.254631, 0.254631, 0.159145), cf = CFrame.new(1.400475, 0.923038, -0.000031, 0, 0, 1, 0, 1.000001, 0, -1, 0, 0), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 12
		{ n = "SideStar_Left", s = "Block", z = Vector3.new(0.254631, 0.254631, 0.159145), cf = CFrame.new(-1.400452, 0.92304, -0.000031, 0, 0, -1, 0, 1.000001, 0, 1, 0, 0), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 13
		{ n = "FlankStar_LF1", s = "Block", z = Vector3.new(0.254631, 0.254631, 0.159145), cf = CFrame.new(-0.967766, 0.66841, 0.967773, 0.707106, 0, -0.707107, 0, 1.000001, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 14
		{ n = "FlankStar_LF2", s = "Block", z = Vector3.new(0.254631, 0.254631, 0.159145), cf = CFrame.new(-0.92275, 1.241328, 0.922729, 0.707106, 0, -0.707107, 0, 1.000001, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 15
		{ n = "RearStar_R", s = "Block", z = Vector3.new(0.254631, 0.254631, 0.159145), cf = CFrame.new(0.967815, 1.050357, -0.967834, -0.707107, 0, 0.707107, 0, 1.000001, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 16
		{ n = "RearStar_L", s = "Block", z = Vector3.new(0.254631, 0.254631, 0.159145), cf = CFrame.new(-0.967751, 1.050356, -0.967834, -0.707107, 0, -0.707107, 0, 1.000001, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 17
		{ n = "SpineStar_Back", s = "Block", z = Vector3.new(0.254631, 0.254631, 0.159145), cf = CFrame.new(0.000011, 0.604749, -1.336823, -1, 0, 0, 0, 1.000001, 0, 0, 0, -1), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 18
		{ n = "NovaCore", s = "Block", z = Vector3.new(0.700236, 0.763894, 0.700236), cf = CFrame.new(0.000011, 2.068881, -0.12735, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(110, 230, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.431373, 0.901961, 1), TintRole = "Gem" } }, -- 19
		{ n = "NovaFilament", s = "Block", z = Vector3.new(0.445605, 0.509263, 0.445605), cf = CFrame.new(0.000011, 2.068881, -0.12735, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(185, 245, 255), m = Enum.Material.Neon, t = 0.08, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.72549, 0.960784, 1), TintRole = "Glow" } }, -- 20
		{ n = "NovaCrownGlow", s = "Wedge", z = Vector3.new(0.254631, 0.381947, 0.254631), cf = CFrame.new(0.000011, 2.578144, -0.12735, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(225, 250, 255), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.882353, 0.980392, 1), TintRole = "Glow" } }, -- 21
		{ n = "PodCore", s = "Block", z = Vector3.new(2.164366, 1.655103, 2.164366), cf = CFrame.new(0.000011, 0.859381, -0.000031, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(39, 37, 82), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.145098, 0.321569), TintRole = "Shell" } }, -- 22
		{ n = "BulbCross", s = "Block", z = Vector3.new(1.718761, 1.718761, 1.718761), cf = CFrame.new(0.000011, 0.859381, -0.000031, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(28, 26, 60), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.109804, 0.101961, 0.235294), TintRole = "Shell" } }, -- 23
		{ n = "CarapacePlate1", s = "Block", z = Vector3.new(0.89121, 1.591446, 0.28646), cf = CFrame.new(0.000011, 0.859381, 1.209473, 1, 0, 0, 0, 0.997565, 0.069757, 0, -0.069757, 0.997565), c = Color3.fromRGB(39, 37, 82), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.145098, 0.321569), TintRole = "Plate" } }, -- 24
		{ n = "CarapacePlate2", s = "Block", z = Vector3.new(0.89121, 1.591446, 0.28646), cf = CFrame.new(0.855253, 0.859381, 0.855225, 0.707107, -0.049325, 0.705384, 0, 0.997565, 0.069756, -0.707107, -0.049325, 0.705385), c = Color3.fromRGB(28, 26, 60), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.109804, 0.101961, 0.235294), TintRole = "Plate" } }, -- 25
		{ n = "CarapacePlate3", s = "Block", z = Vector3.new(0.89121, 1.591446, 0.28646), cf = CFrame.new(1.209526, 0.859381, -0.000031, 0, -0.069756, 0.997564, 0, 0.997565, 0.069756, -1, 0, 0), c = Color3.fromRGB(39, 37, 82), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.145098, 0.321569), TintRole = "Plate" } }, -- 26
		{ n = "CarapacePlate4", s = "Block", z = Vector3.new(0.89121, 1.591446, 0.28646), cf = CFrame.new(0.855278, 0.859381, -0.855286, -0.707107, -0.049325, 0.705384, 0, 0.997565, 0.069756, -0.707107, 0.049325, -0.705385), c = Color3.fromRGB(28, 26, 60), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.109804, 0.101961, 0.235294), TintRole = "Plate" } }, -- 27
		{ n = "CarapacePlate5", s = "Block", z = Vector3.new(0.89121, 1.591446, 0.28646), cf = CFrame.new(0.000036, 0.859381, -1.209534, -1, 0, 0, 0, 0.997565, 0.069757, 0, 0.069757, -0.997565), c = Color3.fromRGB(39, 37, 82), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.145098, 0.321569), TintRole = "Plate" } }, -- 28
		{ n = "CarapacePlate6", s = "Block", z = Vector3.new(0.89121, 1.591446, 0.28646), cf = CFrame.new(-0.85523, 0.859381, -0.855286, -0.707107, 0.049325, -0.705384, 0, 0.997565, 0.069756, 0.707107, 0.049325, -0.705385), c = Color3.fromRGB(28, 26, 60), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.109804, 0.101961, 0.235294), TintRole = "Plate" } }, -- 29
		{ n = "CarapacePlate7", s = "Block", z = Vector3.new(0.89121, 1.591446, 0.28646), cf = CFrame.new(-1.209503, 0.859381, -0.000031, 0, 0.069756, -0.997564, 0, 0.997565, 0.069756, 1, 0, 0), c = Color3.fromRGB(39, 37, 82), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.145098, 0.321569), TintRole = "Plate" } }, -- 30
		{ n = "CarapacePlate8", s = "Block", z = Vector3.new(0.89121, 1.591446, 0.28646), cf = CFrame.new(-0.85523, 0.859381, 0.855225, 0.707107, 0.049325, -0.705384, 0, 0.997565, 0.069756, 0.707107, -0.049325, 0.705384), c = Color3.fromRGB(28, 26, 60), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.109804, 0.101961, 0.235294), TintRole = "Plate" } }, -- 31
		{ n = "DorsalScale1", s = "Block", z = Vector3.new(0.57292, 0.89121, 0.222802), cf = CFrame.new(0.900299, 0.986698, -0.900299, -0.707107, 0.09841, 0.700225, 0, 0.990269, -0.139173, -0.707107, -0.09841, -0.700226), c = Color3.fromRGB(48, 44, 98), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.172549, 0.384314), TintRole = "Plate" } }, -- 32
		{ n = "DorsalScale2", s = "Block", z = Vector3.new(0.57292, 0.89121, 0.222802), cf = CFrame.new(0.000036, 0.986696, -1.273163, -1, 0, 0, 0, 0.990269, -0.139173, 0, -0.139173, -0.990269), c = Color3.fromRGB(48, 44, 98), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.172549, 0.384314), TintRole = "Plate" } }, -- 33
		{ n = "DorsalScale3", s = "Block", z = Vector3.new(0.57292, 0.89121, 0.222802), cf = CFrame.new(-0.900221, 0.986697, -0.900299, -0.707107, -0.09841, -0.700225, 0, 0.990269, -0.139173, 0.707107, -0.09841, -0.700226), c = Color3.fromRGB(48, 44, 98), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.172549, 0.384314), TintRole = "Plate" } }, -- 34
		{ n = "UpperCarapace", s = "Block", z = Vector3.new(1.973393, 0.445605, 1.973393), cf = CFrame.new(0.000011, 1.81425, -0.000031, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(39, 37, 82), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.145098, 0.321569), TintRole = "Shell" } }, -- 35
		{ n = "BrowArch", s = "Block", z = Vector3.new(1.209499, 0.509263, 0.445605), cf = CFrame.new(0.000036, 2.132539, -0.891235, 1, 0, 0, 0, 0.970297, -0.241922, 0, 0.241922, 0.970297), c = Color3.fromRGB(158, 128, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.619608, 0.501961, 1), TintRole = "Brow" } }, -- 36
		{ n = "BrowPeak", s = "Wedge", z = Vector3.new(0.763894, 0.57292, 0.318289), cf = CFrame.new(0.000011, 2.514491, -0.763947, 1, 0, 0, 0, 0.99027, -0.139173, 0, 0.139173, 0.990269), c = Color3.fromRGB(188, 162, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.737255, 0.635294, 1), TintRole = "Brow" } }, -- 37
		{ n = "BrowWing_L", s = "Block", z = Vector3.new(0.57292, 0.445605, 0.827552), cf = CFrame.new(-0.827522, 2.068883, -0.636627, 0.85672, -0.213604, 0.469471, 0.317348, 0.935834, -0.153322, -0.406597, 0.28034, 0.869535), c = Color3.fromRGB(158, 128, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.619608, 0.501961, 1), TintRole = "Brow" } }, -- 38
		{ n = "BrowCheek_L", s = "Block", z = Vector3.new(0.381947, 0.509263, 0.636578), cf = CFrame.new(-1.082159, 1.814251, -0.254669, 0.780342, -0.10967, 0.615661, 0.139173, 0.990269, 0, -0.609671, 0.085684, 0.788012), c = Color3.fromRGB(188, 162, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.737255, 0.635294, 1), TintRole = "Brow" } }, -- 39
		{ n = "BrowWing_R", s = "Block", z = Vector3.new(0.57292, 0.445605, 0.827552), cf = CFrame.new(0.82757, 2.068883, -0.636627, 0.85672, 0.213604, -0.469471, -0.317348, 0.935834, -0.153322, 0.406597, 0.28034, 0.869535), c = Color3.fromRGB(158, 128, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.619608, 0.501961, 1), TintRole = "Brow" } }, -- 40
		{ n = "BrowCheek_R", s = "Block", z = Vector3.new(0.381947, 0.509263, 0.636578), cf = CFrame.new(1.082184, 1.814254, -0.254669, 0.780342, 0.10967, -0.615661, -0.139173, 0.990269, 0, 0.609671, 0.085684, 0.788012), c = Color3.fromRGB(188, 162, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.737255, 0.635294, 1), TintRole = "Brow" } }, -- 41
		{ n = "DomePlate1", s = "Block", z = Vector3.new(0.763894, 1.145841, 0.254631), cf = CFrame.new(0.495153, 2.578144, 0.495117, 0.707107, -0.194905, 0.679714, 0, 0.961263, 0.275638, -0.707108, -0.194905, 0.679715), c = Color3.fromRGB(39, 37, 82), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.145098, 0.321569), TintRole = "Plate" } }, -- 42
		{ n = "DomePlate2", s = "Block", z = Vector3.new(0.763894, 1.145841, 0.254631), cf = CFrame.new(0.495153, 2.578144, -0.495178, -0.707107, -0.194905, 0.679715, 0, 0.961263, 0.275638, -0.707108, 0.194905, -0.679715), c = Color3.fromRGB(28, 26, 60), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.109804, 0.101961, 0.235294), TintRole = "Plate" } }, -- 43
		{ n = "DomePlate3", s = "Block", z = Vector3.new(0.763894, 1.145841, 0.254631), cf = CFrame.new(-0.495131, 2.578144, -0.495178, -0.707107, 0.194905, -0.679714, 0, 0.961263, 0.275638, 0.707107, 0.194905, -0.679716), c = Color3.fromRGB(39, 37, 82), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.145098, 0.321569), TintRole = "Plate" } }, -- 44
		{ n = "DomePlate4", s = "Block", z = Vector3.new(0.763894, 1.145841, 0.254631), cf = CFrame.new(-0.495131, 2.578144, 0.495117, 0.707107, 0.194905, -0.679715, 0, 0.961263, 0.275638, 0.707108, -0.194905, 0.679715), c = Color3.fromRGB(28, 26, 60), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.109804, 0.101961, 0.235294), TintRole = "Plate" } }, -- 45
		{ n = "BulbPeak", s = "Wedge", z = Vector3.new(0.57292, 0.57292, 0.57292), cf = CFrame.new(0.000011, 3.278381, -0.000031, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(39, 37, 82), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.145098, 0.321569), TintRole = "Shell" } }, -- 46
		{ n = "MooncrestFinial", s = "Wedge", z = Vector3.new(0.28646, 0.445605, 0.28646), cf = CFrame.new(0.000011, 3.596671, -0.000031, 1, 0, 0, 0, 0.994523, 0.104529, 0, -0.104529, 0.994523), c = Color3.fromRGB(48, 44, 98), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.172549, 0.384314), TintRole = "Plate" } }, -- 47
	},
	Joints = {
		{ k = "Weld", n = "NovaFilamentWeld", h = 19, a = 19, b = 20, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "NovaCrownGlowWeld", h = 19, a = 19, b = 21, c0 = CFrame.new(0, 0.509262, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BulbCrossWeld", h = 22, a = 22, b = 23, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CarapacePlate1Weld", h = 22, a = 22, b = 24, c0 = CFrame.new(0, 0, 1.209514, 1, 0, 0, 0, 0.997564, 0.069756, 0, -0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CarapacePlate2Weld", h = 22, a = 22, b = 25, c0 = CFrame.new(0.855242, 0, 0.855242, 0.707107, -0.049325, 0.705384, 0, 0.997564, 0.069756, -0.707107, -0.049325, 0.705384), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CarapacePlate3Weld", h = 22, a = 22, b = 26, c0 = CFrame.new(1.209514, 0, 0, 0, -0.069756, 0.997564, 0, 0.997564, 0.069756, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CarapacePlate4Weld", h = 22, a = 22, b = 27, c0 = CFrame.new(0.855266, 0, -0.855242, -0.707107, -0.049325, 0.705384, 0, 0.997564, 0.069756, -0.707107, 0.049325, -0.705384), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CarapacePlate5Weld", h = 22, a = 22, b = 28, c0 = CFrame.new(0.000024, 0, -1.20949, -1, 0, 0, 0, 0.997564, 0.069756, 0, 0.069756, -0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CarapacePlate6Weld", h = 22, a = 22, b = 29, c0 = CFrame.new(-0.855242, 0, -0.855242, -0.707107, 0.049325, -0.705384, 0, 0.997564, 0.069756, 0.707107, 0.049325, -0.705384), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CarapacePlate7Weld", h = 22, a = 22, b = 30, c0 = CFrame.new(-1.209514, 0, 0, 0, 0.069756, -0.997564, 0, 0.997564, 0.069756, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CarapacePlate8Weld", h = 22, a = 22, b = 31, c0 = CFrame.new(-0.855242, 0, 0.855242, 0.707107, 0.049325, -0.705385, 0, 0.997564, 0.069756, 0.707107, -0.049325, 0.705384), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidHinge", h = 22, a = 22, b = 35, c0 = CFrame.new(0.000024, 0.89121, 0.70024, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.000024, -0.063658, 0.70024, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_01Weld", h = 24, a = 24, b = 1, c0 = CFrame.new(0.517676, 0.060697, 0.044585, 0.382683, 0, -0.923879, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FrontStar_LowWeld", h = 24, a = 24, b = 9, c0 = CFrame.new(0, -0.389896, 0.100388, 1, 0, 0, 0, 0.997564, -0.069756, 0, 0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_02Weld", h = 25, a = 25, b = 2, c0 = CFrame.new(0.517646, 0.0607, 0.04456, 0.382683, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FlankStar_RF1Weld", h = 25, a = 25, b = 10, c0 = CFrame.new(0, -0.201608, 0.145434, 1, 0, 0, 0, 0.997564, -0.069756, 0, 0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FlankStar_RF2Weld", h = 25, a = 25, b = 11, c0 = CFrame.new(-0.000006, 0.374355, 0.121879, 1, 0, 0, 0, 0.997564, -0.069756, 0, 0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_03Weld", h = 26, a = 26, b = 3, c0 = CFrame.new(0.517652, 0.060697, 0.044536, 0.382684, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SideStar_RightWeld", h = 26, a = 26, b = 12, c0 = CFrame.new(0, 0.050182, 0.194924, 1, 0, 0, 0, 0.997564, -0.069756, 0, 0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DorsalScale1Weld", h = 27, a = 27, b = 32, c0 = CFrame.new(0, 0.122565, 0.072395, 1, 0, 0, 0, 0.978148, -0.207912, 0, 0.207912, 0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_04Weld", h = 27, a = 27, b = 4, c0 = CFrame.new(0.517652, 0.060698, 0.044566, 0.382684, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RearStar_RWeld", h = 27, a = 27, b = 16, c0 = CFrame.new(0, 0.179408, 0.172085, 1, 0, 0, 0, 0.997564, -0.069756, 0, 0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DorsalScale2Weld", h = 28, a = 28, b = 33, c0 = CFrame.new(0, 0.122565, 0.072365, 1, 0, 0, 0, 0.978148, -0.207912, 0, 0.207912, 0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_05Weld", h = 28, a = 28, b = 5, c0 = CFrame.new(0.517676, 0.060697, 0.044536, 0.382683, 0, -0.923879, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SpineStar_BackWeld", h = 28, a = 28, b = 18, c0 = CFrame.new(0.000024, -0.262892, 0.109227, 1, 0, 0, 0, 0.997564, -0.069756, 0, 0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DorsalScale3Weld", h = 29, a = 29, b = 34, c0 = CFrame.new(-0.000012, 0.122567, 0.072365, 1, 0, 0, 0, 0.978148, -0.207912, 0, 0.207912, 0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_06Weld", h = 29, a = 29, b = 6, c0 = CFrame.new(0.517634, 0.060698, 0.044536, 0.382683, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "RearStar_LWeld", h = 29, a = 29, b = 17, c0 = CFrame.new(-0.000012, 0.179408, 0.172073, 1, 0, 0, 0, 0.997564, -0.069756, 0, 0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_07Weld", h = 30, a = 30, b = 7, c0 = CFrame.new(0.517652, 0.060698, 0.04456, 0.382684, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SideStar_LeftWeld", h = 30, a = 30, b = 13, c0 = CFrame.new(0, 0.050183, 0.194924, 1, 0, 0, 0, 0.997564, -0.069756, 0, 0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_08Weld", h = 31, a = 31, b = 8, c0 = CFrame.new(0.517652, 0.060699, 0.04456, 0.382684, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FlankStar_LF1Weld", h = 31, a = 31, b = 14, c0 = CFrame.new(0, -0.201608, 0.14544, 1, 0, 0, 0, 0.997564, -0.069756, 0, 0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FlankStar_LF2Weld", h = 31, a = 31, b = 15, c0 = CFrame.new(0, 0.374356, 0.121897, 1, 0, 0, 0, 0.997564, -0.069756, 0, 0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowArchWeld", h = 35, a = 35, b = 36, c0 = CFrame.new(0.000024, 0.318289, -0.891206, 1, 0, 0, 0, 0.970296, -0.241922, 0, 0.241922, 0.970296), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DomePlate1Weld", h = 35, a = 35, b = 42, c0 = CFrame.new(0.495141, 0.763893, 0.495141, 0.707107, -0.194905, 0.679715, 0, 0.961262, 0.275637, -0.707107, -0.194905, 0.679715), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DomePlate2Weld", h = 35, a = 35, b = 43, c0 = CFrame.new(0.495141, 0.763893, -0.495141, -0.707107, -0.194905, 0.679715, 0, 0.961262, 0.275637, -0.707107, 0.194905, -0.679715), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DomePlate3Weld", h = 35, a = 35, b = 44, c0 = CFrame.new(-0.495141, 0.763893, -0.495141, -0.707107, 0.194905, -0.679715, 0, 0.961262, 0.275637, 0.707107, 0.194905, -0.679715), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DomePlate4Weld", h = 35, a = 35, b = 45, c0 = CFrame.new(-0.495141, 0.763893, 0.495141, 0.707107, 0.194905, -0.679715, 0, 0.961262, 0.275637, 0.707107, -0.194905, 0.679715), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BulbPeakWeld", h = 35, a = 35, b = 46, c0 = CFrame.new(0, 1.46413, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "NovaCoreWeld", h = 35, a = 35, b = 19, c0 = CFrame.new(0, 0.254631, -0.127319, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowPeakWeld", h = 36, a = 36, b = 37, c0 = CFrame.new(-0.000024, 0.401401, 0.031107, 1, 0, 0, 0, 0.994522, 0.104528, 0, -0.104528, 0.994522), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowWing_LWeld", h = 36, a = 36, b = 38, c0 = CFrame.new(-0.827559, -0.000167, 0.262456, 0.85672, -0.213604, 0.469472, 0.209557, 0.975855, 0.061591, -0.471292, 0.045614, 0.880797), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowCheek_LWeld", h = 36, a = 36, b = 39, c0 = CFrame.new(-1.082196, -0.154835, 0.694655, 0.780342, -0.10967, 0.615662, -0.012453, 0.981582, 0.190637, -0.625229, -0.156429, 0.764604), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowWing_RWeld", h = 36, a = 36, b = 40, c0 = CFrame.new(0.827534, -0.000167, 0.262456, 0.85672, 0.213604, -0.469472, -0.209557, 0.975855, 0.061591, 0.471292, 0.045614, 0.880797), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowCheek_RWeld", h = 36, a = 36, b = 41, c0 = CFrame.new(1.082147, -0.154832, 0.694655, 0.780342, 0.10967, -0.615662, 0.012453, 0.981582, 0.190637, 0.625229, -0.156429, 0.764604), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MooncrestFinialWeld", h = 46, a = 46, b = 47, c0 = CFrame.new(0, 0.318289, 0, 1, 0, 0, 0, 0.994522, 0.104528, 0, -0.104528, 0.994522), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "RareLight", p = 19, range = 2.4, brightness = 0.35, color = Color3.new(0.431373, 0.901961, 1), shadows = false, enabled = true, a = { TintRole = "GlowLight" } },
	},
	Emitters = {},
	Textures = {
	},
}

return spec
