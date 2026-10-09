--!strict
--==============================================================================
-- POD FORM: Astralhorn (starbloom pods/AstralhornPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "starbloom pods/AstralhornPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "starbloom pods/AstralhornPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(2.857625, 3.593766, 2.668549), Height = 3.593766, PartCount = 42,
	Base = 0, Root = 18,
	Attributes = {},
	Owner = { Biome = "starbloom", BottomOffset = 0, ClosedDepth = 0.898462, ClosedHeight = 1.369959, ClosedWidth = 0.96211, IsPod = true, LegendaryLightEnabled = true, OpenAmount = 0, OpenDuration = 0.45, PartCount = 44, Rarity = "Legendary", RulesVersion = "2026-10-09", ShellCentre = Vector3.new(0, 0.401353, 0), SizeSeamRole = "Seam", SpawnMode = "CameraAir", Species = "Astralhorn", Unit = 1, WidthClassUnit = 1 },
	Removed = { "SeedBase", "PlinthBevel" },
	Parts = {
		{ n = "Seam_01", s = "Block", z = Vector3.new(0.163358, 0.19306, 1.014169), cf = CFrame.new(0.441058, 0.891047, 1.064789, 0.382684, 0, -0.92388, 0, 1.000001, 0, 0.92388, 0, 0.382684), c = Color3.fromRGB(98, 82, 145), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.384314, 0.321569, 0.568627), TintRole = "Seam" } }, -- 1
		{ n = "Seam_02", s = "Block", z = Vector3.new(0.163358, 0.19306, 1.014169), cf = CFrame.new(1.064779, 0.891048, 0.44104, 0.92388, 0, -0.382683, 0, 1.000001, 0, 0.382683, 0, 0.92388), c = Color3.fromRGB(98, 82, 145), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.384314, 0.321569, 0.568627), TintRole = "Seam" } }, -- 2
		{ n = "Seam_03", s = "Block", z = Vector3.new(0.163358, 0.19306, 1.014169), cf = CFrame.new(1.064772, 0.891048, -0.44104, 0.92388, 0, 0.382684, 0, 1.000001, 0, -0.382684, 0, 0.92388), c = Color3.fromRGB(98, 82, 145), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.384314, 0.321569, 0.568627), TintRole = "Seam" } }, -- 3
		{ n = "Seam_04", s = "Block", z = Vector3.new(0.163358, 0.19306, 1.014169), cf = CFrame.new(0.441057, 0.891048, -1.064728, 0.382683, 0, 0.92388, 0, 1.000001, 0, -0.92388, 0, 0.382683), c = Color3.fromRGB(98, 82, 145), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.384314, 0.321569, 0.568627), TintRole = "Seam" } }, -- 4
		{ n = "Seam_05", s = "Block", z = Vector3.new(0.163358, 0.19306, 1.014169), cf = CFrame.new(-0.441045, 0.891045, -1.064758, -0.382684, 0, 0.92388, 0, 1.000001, 0, -0.92388, 0, -0.382684), c = Color3.fromRGB(98, 82, 145), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.384314, 0.321569, 0.568627), TintRole = "Seam" } }, -- 5
		{ n = "Seam_06", s = "Block", z = Vector3.new(0.163358, 0.19306, 1.014169), cf = CFrame.new(-1.064774, 0.891047, -0.44104, -0.92388, 0, 0.382683, 0, 1.000001, 0, -0.382683, 0, -0.92388), c = Color3.fromRGB(98, 82, 145), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.384314, 0.321569, 0.568627), TintRole = "Seam" } }, -- 6
		{ n = "Seam_07", s = "Block", z = Vector3.new(0.163358, 0.19306, 1.014169), cf = CFrame.new(-1.064758, 0.891044, 0.441071, -0.92388, 0, -0.382684, 0, 1.000001, 0, 0.382684, 0, -0.92388), c = Color3.fromRGB(98, 82, 145), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.384314, 0.321569, 0.568627), TintRole = "Seam" } }, -- 7
		{ n = "Seam_08", s = "Block", z = Vector3.new(0.163358, 0.19306, 1.014169), cf = CFrame.new(-0.441017, 0.891045, 1.064789, -0.382683, 0, -0.92388, 0, 1.000001, 0, 0.92388, 0, -0.382683), c = Color3.fromRGB(98, 82, 145), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.384314, 0.321569, 0.568627), TintRole = "Seam" } }, -- 8
		{ n = "Star_ChestLow", s = "Block", z = Vector3.new(0.237612, 0.356418, 0.148507), cf = CFrame.new(0.000007, 0.594037, -1.247406, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(115, 235, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.45098, 0.921569, 1), TintRole = "Gem" } }, -- 9
		{ n = "Star_ChestHigh", s = "Block", z = Vector3.new(0.267313, 0.415821, 0.148507), cf = CFrame.new(0.000007, 1.128659, -1.217743, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(115, 235, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.45098, 0.921569, 1), TintRole = "Gem" } }, -- 10
		{ n = "Star_FlankLF", s = "Block", z = Vector3.new(0.148507, 0.267313, 0.267313), cf = CFrame.new(-1.247445, 0.772239, -0.178192, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(115, 235, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.45098, 0.921569, 1), TintRole = "Gem" } }, -- 11
		{ n = "Star_FlankLR", s = "Block", z = Vector3.new(0.148507, 0.267313, 0.267313), cf = CFrame.new(-1.247433, 0.772231, 0.178223, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(115, 235, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.45098, 0.921569, 1), TintRole = "Gem" } }, -- 12
		{ n = "Star_FlankRF", s = "Block", z = Vector3.new(0.148507, 0.267313, 0.267313), cf = CFrame.new(1.247469, 0.772247, -0.178162, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(115, 235, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.45098, 0.921569, 1), TintRole = "Gem" } }, -- 13
		{ n = "Star_FlankRR", s = "Block", z = Vector3.new(0.148507, 0.267313, 0.267313), cf = CFrame.new(1.247458, 0.772237, 0.178253, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(115, 235, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.45098, 0.921569, 1), TintRole = "Gem" } }, -- 14
		{ n = "AstralCore", s = "Block", z = Vector3.new(0.653433, 0.653433, 0.653433), cf = CFrame.new(0.000007, 2.019704, 0, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(115, 235, 255), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.45098, 0.921569, 1), TintRole = "Gem" } }, -- 15
		{ n = "MoonSpark", s = "Block", z = Vector3.new(0.415821, 0.415821, 0.415821), cf = CFrame.new(0.000007, 2.019704, 0, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(185, 245, 255), m = Enum.Material.Neon, t = 0.08, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.72549, 0.960784, 1), TintRole = "Glow" } }, -- 16
		{ n = "CrownSpireGlow", s = "Wedge", z = Vector3.new(0.178209, 0.712836, 0.178209), cf = CFrame.new(0.000007, 2.554332, 0, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(225, 250, 255), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.882353, 0.980392, 1), TintRole = "Glow" } }, -- 17
		{ n = "PodCore", s = "Block", z = Vector3.new(1.722686, 1.60388, 1.722686), cf = CFrame.new(0.000007, 0.831642, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(26, 22, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.101961, 0.086275, 0.219608), TintRole = "Shell" } }, -- 18
		{ n = "CrossCore", s = "Block", z = Vector3.new(1.366268, 1.663283, 1.366268), cf = CFrame.new(0.000007, 0.831642, 0, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(36, 30, 72), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.141176, 0.117647, 0.282353), TintRole = "Shell" } }, -- 19
		{ n = "StagFlank1", s = "Block", z = Vector3.new(0.712836, 1.485074, 0.237612), cf = CFrame.new(0.000007, 0.831642, 1.039581, 1, 0, 0, 0, 0.997565, 0.069756, 0, -0.069756, 0.997564), c = Color3.fromRGB(30, 26, 62), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.101961, 0.243137), TintRole = "Plate" } }, -- 20
		{ n = "StagFlank2", s = "Block", z = Vector3.new(0.712836, 1.485074, 0.237612), cf = CFrame.new(0.735077, 0.831642, 0.735077, 0.707107, -0.049325, 0.705384, 0, 0.997565, 0.069756, -0.707107, -0.049325, 0.705384), c = Color3.fromRGB(36, 30, 72), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.141176, 0.117647, 0.282353), TintRole = "Plate" } }, -- 21
		{ n = "StagFlank3", s = "Block", z = Vector3.new(0.712836, 1.485074, 0.237612), cf = CFrame.new(1.039554, 0.831642, 0.000031, 0, -0.069756, 0.997564, 0, 0.997565, 0.069756, -1, 0, 0), c = Color3.fromRGB(30, 26, 62), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.101961, 0.243137), TintRole = "Plate" } }, -- 22
		{ n = "StagFlank4", s = "Block", z = Vector3.new(0.712836, 1.485074, 0.237612), cf = CFrame.new(0.735088, 0.831642, -0.735046, -0.707107, -0.049325, 0.705384, 0, 0.997565, 0.069756, -0.707107, 0.049325, -0.705384), c = Color3.fromRGB(36, 30, 72), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.141176, 0.117647, 0.282353), TintRole = "Plate" } }, -- 23
		{ n = "StagFlank5", s = "Block", z = Vector3.new(0.712836, 1.485074, 0.237612), cf = CFrame.new(0.000007, 0.831642, -1.039551, -1, 0, 0, 0, 0.997565, 0.069756, 0, 0.069756, -0.997564), c = Color3.fromRGB(30, 26, 62), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.101961, 0.243137), TintRole = "Plate" } }, -- 24
		{ n = "StagFlank6", s = "Block", z = Vector3.new(0.712836, 1.485074, 0.237612), cf = CFrame.new(-0.735064, 0.831642, -0.735046, -0.707107, 0.049325, -0.705384, 0, 0.997565, 0.069756, 0.707107, 0.049325, -0.705385), c = Color3.fromRGB(36, 30, 72), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.141176, 0.117647, 0.282353), TintRole = "Plate" } }, -- 25
		{ n = "StagFlank7", s = "Block", z = Vector3.new(0.712836, 1.485074, 0.237612), cf = CFrame.new(-1.039541, 0.831642, 0.000031, 0, 0.069756, -0.997564, 0, 0.997565, 0.069756, 1, 0, 0), c = Color3.fromRGB(30, 26, 62), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.101961, 0.243137), TintRole = "Plate" } }, -- 26
		{ n = "StagFlank8", s = "Block", z = Vector3.new(0.712836, 1.485074, 0.237612), cf = CFrame.new(-0.735064, 0.831642, 0.735107, 0.707107, 0.049325, -0.705385, 0, 0.997565, 0.069757, 0.707107, -0.049325, 0.705384), c = Color3.fromRGB(36, 30, 72), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.141176, 0.117647, 0.282353), TintRole = "Plate" } }, -- 27
		{ n = "Breastplate_Low", s = "Block", z = Vector3.new(0.772238, 0.653433, 0.237612), cf = CFrame.new(0.000007, 0.594035, -1.098907, 1, 0, 0, 0, 0.990269, -0.139173, 0, 0.139173, 0.990268), c = Color3.fromRGB(168, 148, 240), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.580392, 0.941176), TintRole = "Plate" } }, -- 28
		{ n = "Breastplate_High", s = "Block", z = Vector3.new(0.653433, 0.653433, 0.237612), cf = CFrame.new(0.000007, 1.128658, -1.069244, 1, 0, 0, 0, 0.994522, 0.104528, 0, -0.104528, 0.994522), c = Color3.fromRGB(168, 148, 240), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.580392, 0.941176), TintRole = "Plate" } }, -- 29
		{ n = "HaunchPlate_L", s = "Block", z = Vector3.new(0.237612, 0.891044, 0.59403), cf = CFrame.new(-1.098939, 0.77224, 0, 0, 0, -1, 0.104529, 0.994522, 0, 0.994522, -0.104529, 0), c = Color3.fromRGB(30, 26, 62), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.101961, 0.243137), TintRole = "Plate" } }, -- 30
		{ n = "HaunchPlate_R", s = "Block", z = Vector3.new(0.237612, 0.891044, 0.59403), cf = CFrame.new(1.098953, 0.77224, 0.000031, 0, 0, 1, -0.104529, 0.994522, 0, -0.994522, -0.104529, 0), c = Color3.fromRGB(30, 26, 62), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.101961, 0.243137), TintRole = "Plate" } }, -- 31
		{ n = "UpperMantle", s = "Block", z = Vector3.new(1.663283, 0.415821, 1.663283), cf = CFrame.new(0.000007, 1.722688, 0, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(26, 22, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.101961, 0.086275, 0.219608), TintRole = "Shell" } }, -- 32
		{ n = "StagBrow", s = "Block", z = Vector3.new(0.950447, 0.475224, 0.356418), cf = CFrame.new(0.000007, 2.079105, -0.653412, 1.000001, 0, 0, 0, 0.984809, -0.173648, 0, 0.173648, 0.984808), c = Color3.fromRGB(168, 148, 240), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.580392, 0.941176), TintRole = "Plate" } }, -- 33
		{ n = "CrestFinial", s = "Wedge", z = Vector3.new(0.356418, 0.653433, 0.356418), cf = CFrame.new(0.000007, 2.554332, -0.415802, 1.000001, 0, 0, 0, 0.994523, -0.104529, 0, 0.104529, 0.994522), c = Color3.fromRGB(36, 30, 72), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.141176, 0.117647, 0.282353), TintRole = "Plate" } }, -- 34
		{ n = "AntlerBeam_L1", s = "Block", z = Vector3.new(0.19306, 0.19306, 0.907918), cf = CFrame.new(-0.86134, 2.316717, -0.089111, -0.316228, 0.688248, 0.652929, 0, 0.688248, -0.725477, -0.948684, -0.229416, -0.217643), c = Color3.fromRGB(240, 228, 168), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.658824), TintRole = "Tusk" } }, -- 35
		{ n = "AntlerBeam_L2", s = "Block", z = Vector3.new(0.178209, 0.178209, 0.655773), cf = CFrame.new(-1.217767, 2.881044, 0.029694, -0.316228, 0.895042, 0.314485, 0, 0.331497, -0.943458, -0.948684, -0.298347, -0.104828), c = Color3.fromRGB(240, 228, 168), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.658824), TintRole = "Tusk" } }, -- 36
		{ n = "AntlerTip_L", s = "Wedge", z = Vector3.new(0.154448, 0.154448, 0.734386), cf = CFrame.new(-1.039565, 3.326563, 0.029694, 0.110432, -0.548967, -0.828517, 0, 0.833617, -0.552346, 0.993884, 0.060996, 0.092057), c = Color3.fromRGB(240, 228, 168), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.658824), TintRole = "Tusk" } }, -- 37
		{ n = "BrowTine_L", s = "Wedge", z = Vector3.new(0.142567, 0.142567, 0.682427), cf = CFrame.new(-0.980142, 2.673146, -0.267334, 0.874158, -0.092609, -0.476731, 0, 0.981651, -0.190694, 0.485643, 0.166696, 0.858117), c = Color3.fromRGB(240, 228, 168), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.658824), TintRole = "Tusk" } }, -- 38
		{ n = "AntlerBeam_R1", s = "Block", z = Vector3.new(0.19306, 0.19306, 0.907918), cf = CFrame.new(0.861341, 2.316717, -0.089111, -0.316228, -0.688248, -0.652929, 0, 0.688248, -0.725477, 0.948684, -0.229416, -0.217643), c = Color3.fromRGB(240, 228, 168), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.658824), TintRole = "Tusk" } }, -- 39
		{ n = "AntlerBeam_R2", s = "Block", z = Vector3.new(0.178209, 0.178209, 0.655773), cf = CFrame.new(1.217767, 2.881048, 0.029663, -0.316228, -0.895042, -0.314486, 0, 0.331497, -0.943458, 0.948684, -0.298347, -0.104829), c = Color3.fromRGB(240, 228, 168), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.658824), TintRole = "Tusk" } }, -- 40
		{ n = "AntlerTip_R", s = "Wedge", z = Vector3.new(0.154448, 0.154448, 0.734386), cf = CFrame.new(1.039558, 3.326574, 0.029663, 0.110432, 0.548967, 0.828517, 0, 0.833617, -0.552346, -0.993884, 0.060996, 0.092057), c = Color3.fromRGB(240, 228, 168), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.658824), TintRole = "Tusk" } }, -- 41
		{ n = "BrowTine_R", s = "Wedge", z = Vector3.new(0.142567, 0.142567, 0.682427), cf = CFrame.new(0.980149, 2.673139, -0.267334, 0.874158, 0.092609, 0.476731, 0, 0.981651, -0.190694, -0.485643, 0.166696, 0.858117), c = Color3.fromRGB(240, 228, 168), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.658824), TintRole = "Tusk" } }, -- 42
	},
	Joints = {
		{ k = "Weld", n = "MoonSparkWeld", h = 15, a = 15, b = 16, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrownSpireGlowWeld", h = 15, a = 15, b = 17, c0 = CFrame.new(0, 0.534628, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrossCoreWeld", h = 18, a = 18, b = 19, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StagFlank1Weld", h = 18, a = 18, b = 20, c0 = CFrame.new(0, 0, 1.03957, 1, 0, 0, 0, 0.997564, 0.069756, 0, -0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StagFlank2Weld", h = 18, a = 18, b = 21, c0 = CFrame.new(0.73507, 0, 0.735082, 0.707107, -0.049325, 0.705384, 0, 0.997564, 0.069756, -0.707107, -0.049325, 0.705384), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StagFlank3Weld", h = 18, a = 18, b = 22, c0 = CFrame.new(1.039547, 0, 0.000023, 0, -0.069756, 0.997564, 0, 0.997564, 0.069756, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StagFlank4Weld", h = 18, a = 18, b = 23, c0 = CFrame.new(0.735082, 0, -0.735059, -0.707107, -0.049325, 0.705384, 0, 0.997564, 0.069756, -0.707107, 0.049325, -0.705384), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StagFlank5Weld", h = 18, a = 18, b = 24, c0 = CFrame.new(0, 0, -1.039547, -1, 0, 0, 0, 0.997564, 0.069756, 0, 0.069756, -0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StagFlank6Weld", h = 18, a = 18, b = 25, c0 = CFrame.new(-0.73507, 0, -0.735059, -0.707107, 0.049325, -0.705384, 0, 0.997564, 0.069756, 0.707107, 0.049325, -0.705384), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StagFlank7Weld", h = 18, a = 18, b = 26, c0 = CFrame.new(-1.039547, 0, 0.000023, 0, 0.069756, -0.997564, 0, 0.997564, 0.069756, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StagFlank8Weld", h = 18, a = 18, b = 27, c0 = CFrame.new(-0.73507, 0, 0.735104, 0.707107, 0.049325, -0.705384, 0, 0.997564, 0.069756, 0.707107, -0.049325, 0.705384), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidHinge", h = 18, a = 18, b = 32, c0 = CFrame.new(0, 0.831644, 0.594066, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.059401, 0.594066, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Breastplate_LowWeld", h = 20, a = 20, b = 28, c0 = CFrame.new(0, -0.087854, -2.149863, 1, 0, 0, 0, 0.978148, -0.207912, 0, 0.207912, 0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Breastplate_HighWeld", h = 20, a = 20, b = 29, c0 = CFrame.new(0, 0.443397, -2.082969, 1, 0, 0, 0, 0.999391, 0.034899, 0, -0.034899, 0.999391), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_01Weld", h = 20, a = 20, b = 1, c0 = CFrame.new(0.441051, 0.057501, 0.0293, 0.382683, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_02Weld", h = 21, a = 21, b = 2, c0 = CFrame.new(0.44104, 0.057501, 0.029311, 0.382684, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HaunchPlate_RWeld", h = 22, a = 22, b = 31, c0 = CFrame.new(0, -0.063401, 0.05511, 0.994522, 0.104528, 0, -0.104274, 0.992099, -0.069756, -0.007291, 0.069374, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_03Weld", h = 22, a = 22, b = 3, c0 = CFrame.new(0.441063, 0.057502, 0.0293, 0.382683, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_04Weld", h = 23, a = 23, b = 4, c0 = CFrame.new(0.44104, 0.057502, 0.0293, 0.382684, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_05Weld", h = 24, a = 24, b = 5, c0 = CFrame.new(0.441051, 0.057501, 0.029277, 0.382683, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_06Weld", h = 25, a = 25, b = 6, c0 = CFrame.new(0.44104, 0.057499, 0.029323, 0.382684, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HaunchPlate_LWeld", h = 26, a = 26, b = 30, c0 = CFrame.new(-0.000023, -0.063401, 0.05511, 0.994522, -0.104529, 0, 0.104274, 0.992099, -0.069756, 0.007292, 0.069374, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_07Weld", h = 26, a = 26, b = 7, c0 = CFrame.new(0.44104, 0.057498, 0.0293, 0.382683, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_08Weld", h = 27, a = 27, b = 8, c0 = CFrame.new(0.44104, 0.057501, 0.029277, 0.382684, 0, -0.923879, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Star_ChestLowWeld", h = 28, a = 28, b = 9, c0 = CFrame.new(0, -0.020666, -0.147066, 1, 0, 0, 0, 0.990268, 0.139173, 0, -0.139173, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Star_ChestHighWeld", h = 29, a = 29, b = 10, c0 = CFrame.new(0, 0.015522, -0.147678, 1, 0, 0, 0, 0.994522, -0.104528, 0, 0.104528, 0.994522), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Star_FlankLFWeld", h = 30, a = 30, b = 11, c0 = CFrame.new(-0.177227, 0.018627, 0.148505, 0, 0.104528, 0.994522, 0, 0.994522, -0.104528, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Star_FlankLRWeld", h = 30, a = 30, b = 12, c0 = CFrame.new(0.17725, -0.018638, 0.148494, 0, 0.104528, 0.994522, 0, 0.994522, -0.104528, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Star_FlankRFWeld", h = 31, a = 31, b = 13, c0 = CFrame.new(0.177205, 0.018633, 0.148516, 0, -0.104528, -0.994522, 0, 0.994522, -0.104528, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Star_FlankRRWeld", h = 31, a = 31, b = 14, c0 = CFrame.new(-0.17725, -0.018633, 0.148505, 0, -0.104528, -0.994522, 0, 0.994522, -0.104528, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StagBrowWeld", h = 32, a = 32, b = 33, c0 = CFrame.new(0, 0.356417, -0.653414, 1, 0, 0, 0, 0.984808, -0.173648, 0, 0.173648, 0.984808), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrestFinialWeld", h = 32, a = 32, b = 34, c0 = CFrame.new(0, 0.831644, -0.415796, 1, 0, 0, 0, 0.994522, -0.104528, 0, 0.104528, 0.994522), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "AntlerBeam_L1Weld", h = 32, a = 32, b = 35, c0 = CFrame.new(-0.861346, 0.594029, -0.089101, -0.316228, 0.688247, 0.652929, 0, 0.688247, -0.725476, -0.948683, -0.229416, -0.217643), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "AntlerBeam_R1Weld", h = 32, a = 32, b = 39, c0 = CFrame.new(0.861334, 0.594029, -0.089101, -0.316228, -0.688247, -0.652929, 0, 0.688247, -0.725476, 0.948683, -0.229416, -0.217643), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "AstralCoreWeld", h = 32, a = 32, b = 15, c0 = CFrame.new(0, 0.297016, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "AntlerBeam_L2Weld", h = 35, a = 35, b = 36, c0 = CFrame.new(0, 0.115829, -0.667984, 1, 0, 0, 0, 0.912607, -0.408838, 0, 0.408838, 0.912607), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowTine_LWeld", h = 35, a = 35, b = 38, c0 = CFrame.new(0.20664, 0.204431, -0.297362, -0.737154, -0.128856, -0.663325, 0.490222, 0.573637, -0.656218, 0.465066, -0.808911, -0.359691), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "AntlerTip_LWeld", h = 36, a = 36, b = 37, c0 = CFrame.new(-0.056356, 0.307185, -0.364286, -0.977802, 0.115732, 0.174667, -0.197682, -0.233205, -0.952123, -0.069458, -0.965516, 0.250907), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "AntlerBeam_R2Weld", h = 39, a = 39, b = 40, c0 = CFrame.new(-0.000023, 0.115839, -0.667981, 1, 0, 0, 0, 0.912607, -0.408838, 0, 0.408838, 0.912607), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BrowTine_RWeld", h = 39, a = 39, b = 42, c0 = CFrame.new(-0.20664, 0.204423, -0.29736, -0.737154, 0.128856, 0.663325, -0.490222, 0.573637, -0.656218, -0.465066, -0.808911, -0.359691), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "AntlerTip_RWeld", h = 40, a = 40, b = 41, c0 = CFrame.new(0.056356, 0.307193, -0.364289, -0.977802, -0.115732, -0.174667, 0.197682, -0.233205, -0.952123, 0.069458, -0.965516, 0.250907), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "LegendaryLight", p = 15, range = 2.6, brightness = 0.4, color = Color3.new(0.45098, 0.921569, 1), shadows = false, enabled = true, a = { TintRole = "GlowLight" } },
	},
	Emitters = {},
	Textures = {
	},
}

return spec
