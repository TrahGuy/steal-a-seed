--!strict
--==============================================================================
-- POD FORM: Slagbloom (emberroot pods/SlagbloomPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "emberroot pods/SlagbloomPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "emberroot pods/SlagbloomPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(3.039825, 3.879798, 3.206074), Height = 3.879798, PartCount = 42,
	Base = 0, Root = 21,
	Attributes = {},
	Owner = { Biome = "emberroot", BottomOffset = 0, ClosedDepth = 0.98978, ClosedHeight = 1.347766, ClosedWidth = 0.938469, EpicLightEnabled = true, IsPod = true, OpenAmount = 0, OpenDuration = 0.45, PartCount = 44, Rarity = "Epic", RulesVersion = "2026-10-09", ShellCentre = Vector3.new(0, 0.415367, 0.000231), SizeSeamRole = "Seam", SpawnMode = "CameraAir", Species = "Slagbloom", Unit = 1, WidthClassUnit = 1 },
	Removed = { "SeedBase", "PlinthBevel" },
	Parts = {
		{ n = "Seam_01", s = "Block", z = Vector3.new(0.178156, 0.210548, 1.155619), cf = CFrame.new(0.503906, 1.004155, 1.200834, 0.382683, 0, -0.923879, 0, 1, 0, 0.92388, 0, 0.382684), c = Color3.fromRGB(130, 32, 28), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.509804, 0.12549, 0.109804), TintRole = "Seam" } }, -- 1
		{ n = "Seam_02", s = "Block", z = Vector3.new(0.178156, 0.210548, 1.155619), cf = CFrame.new(1.216492, 1.004153, 0.488226, 0.923879, 0, -0.382683, 0, 1, 0, 0.382684, 0, 0.92388), c = Color3.fromRGB(130, 32, 28), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.509804, 0.12549, 0.109804), TintRole = "Seam" } }, -- 2
		{ n = "Seam_03", s = "Block", z = Vector3.new(0.178156, 0.210548, 1.155619), cf = CFrame.new(1.216492, 1.004156, -0.519574, 0.923879, 0, 0.382683, 0, 1, 0, -0.382684, 0, 0.92388), c = Color3.fromRGB(130, 32, 28), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.509804, 0.12549, 0.109804), TintRole = "Seam" } }, -- 3
		{ n = "Seam_04", s = "Block", z = Vector3.new(0.178156, 0.210548, 1.155619), cf = CFrame.new(0.503906, 1.004153, -1.232213, 0.382683, 0, 0.923879, 0, 1, 0, -0.92388, 0, 0.382684), c = Color3.fromRGB(130, 32, 28), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.509804, 0.12549, 0.109804), TintRole = "Seam" } }, -- 4
		{ n = "Seam_05", s = "Block", z = Vector3.new(0.178156, 0.210548, 1.155619), cf = CFrame.new(-0.503937, 1.004154, -1.232206, -0.382683, 0, 0.923879, 0, 1, 0, -0.92388, 0, -0.382684), c = Color3.fromRGB(130, 32, 28), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.509804, 0.12549, 0.109804), TintRole = "Seam" } }, -- 5
		{ n = "Seam_06", s = "Block", z = Vector3.new(0.178156, 0.210548, 1.155619), cf = CFrame.new(-1.216522, 1.004153, -0.519586, -0.923879, 0, 0.382683, 0, 1, 0, -0.382684, 0, -0.92388), c = Color3.fromRGB(130, 32, 28), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.509804, 0.12549, 0.109804), TintRole = "Seam" } }, -- 6
		{ n = "Seam_07", s = "Block", z = Vector3.new(0.178156, 0.210548, 1.155619), cf = CFrame.new(-1.216492, 1.004151, 0.488226, -0.923879, 0, -0.382683, 0, 1, 0, 0.382684, 0, -0.92388), c = Color3.fromRGB(130, 32, 28), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.509804, 0.12549, 0.109804), TintRole = "Seam" } }, -- 7
		{ n = "Seam_08", s = "Block", z = Vector3.new(0.178156, 0.210548, 1.155619), cf = CFrame.new(-0.503906, 1.004153, 1.200841, -0.382683, 0, -0.923879, 0, 1, 0, 0.92388, 0, -0.382684), c = Color3.fromRGB(130, 32, 28), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.509804, 0.12549, 0.109804), TintRole = "Seam" } }, -- 8
		{ n = "MagmaCrack_01", s = "Block", z = Vector3.new(0.194352, 0.518271, 0.129568), cf = CFrame.new(0, 0.745018, 1.247598, 1, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 110, 35), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.431373, 0.137255), TintRole = "Gem" } }, -- 9
		{ n = "MagmaCrack_02", s = "Block", z = Vector3.new(0.194352, 0.518271, 0.129568), cf = CFrame.new(0.89328, 1.263288, 0.877593, 0.707107, 0, 0.707106, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 110, 35), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.431373, 0.137255), TintRole = "Gem" } }, -- 10
		{ n = "MagmaCrack_03", s = "Block", z = Vector3.new(0.194352, 0.518271, 0.129568), cf = CFrame.new(1.263245, 0.745018, -0.015686, 0, 0, 1, 0, 1, 0, -1.000001, 0, 0), c = Color3.fromRGB(255, 110, 35), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.431373, 0.137255), TintRole = "Gem" } }, -- 11
		{ n = "MagmaCrack_04", s = "Block", z = Vector3.new(0.194352, 0.518271, 0.129568), cf = CFrame.new(0.89325, 1.263288, -0.908965, -0.707106, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(255, 110, 35), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.431373, 0.137255), TintRole = "Gem" } }, -- 12
		{ n = "MagmaCrack_05", s = "Block", z = Vector3.new(0.194352, 0.518271, 0.129568), cf = CFrame.new(-0.000031, 0.745018, -1.278957, -1, 0, 0, 0, 1, 0, 0, 0, -1.000001), c = Color3.fromRGB(255, 110, 35), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.431373, 0.137255), TintRole = "Gem" } }, -- 13
		{ n = "MagmaCrack_06", s = "Block", z = Vector3.new(0.194352, 0.518271, 0.129568), cf = CFrame.new(-0.89328, 1.263288, -0.908965, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(255, 110, 35), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.431373, 0.137255), TintRole = "Gem" } }, -- 14
		{ n = "MagmaCrack_07", s = "Block", z = Vector3.new(0.194352, 0.518271, 0.129568), cf = CFrame.new(-1.263306, 0.745018, -0.015674, 0, 0, -1, 0, 1, 0, 1.000001, 0, 0), c = Color3.fromRGB(255, 110, 35), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.431373, 0.137255), TintRole = "Gem" } }, -- 15
		{ n = "MagmaCrack_08", s = "Block", z = Vector3.new(0.194352, 0.518271, 0.129568), cf = CFrame.new(-0.89328, 1.263288, 0.877593, 0.707106, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(255, 110, 35), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.431373, 0.137255), TintRole = "Gem" } }, -- 16
		{ n = "DripStem", s = "Block", z = Vector3.new(0.155481, 0.388703, 0.155481), cf = CFrame.new(0, 0.421095, -1.376126, 0.999999, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 84, 26), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.329412, 0.101961), TintRole = "Glow" } }, -- 17
		{ n = "DripBead", s = "Wedge", z = Vector3.new(0.259135, 0.323919, 0.259135), cf = CFrame.new(0, 0.16196, -1.376126, 0.999999, 0, 0, 0, 1, 0, 0, 0, 1.000002), c = Color3.fromRGB(255, 84, 26), m = Enum.Material.Neon, t = 0.04, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.329412, 0.101961), TintRole = "Glow" } }, -- 18
		{ n = "MagmaHearth", s = "Block", z = Vector3.new(0.777406, 0.777406, 0.777406), cf = CFrame.new(0, 1.716777, -0.015686, 0.999999, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 84, 26), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.329412, 0.101961), TintRole = "Gem" } }, -- 19
		{ n = "HearthFilament", s = "Block", z = Vector3.new(0.453487, 0.518271, 0.453487), cf = CFrame.new(0, 1.716777, -0.015686, 0.999999, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Neon, t = 0.08, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.686275, 0.215686), TintRole = "Glow" } }, -- 20
		{ n = "PodCore", s = "Block", z = Vector3.new(2.137867, 1.68438, 2.137867), cf = CFrame.new(0, 0.939368, -0.015686, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Shell" } }, -- 21
		{ n = "CoreCross", s = "Block", z = Vector3.new(1.68438, 1.749164, 1.68438), cf = CFrame.new(0, 0.939368, -0.015686, 1, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(24, 12, 12), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.094118, 0.047059, 0.047059), TintRole = "Shell" } }, -- 22
		{ n = "LowerFlank1", s = "Block", z = Vector3.new(0.906974, 1.554812, 0.259135), cf = CFrame.new(0, 0.874586, 1.150426, 1, 0, 0, 0, 0.997564, 0.069756, 0, -0.069757, 0.997565), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Plate" } }, -- 23
		{ n = "LowerFlank2", s = "Block", z = Vector3.new(0.906974, 1.554812, 0.259135), cf = CFrame.new(1.166077, 0.874586, -0.015686, 0, -0.069756, 0.997564, 0, 0.997564, 0.069756, -1.000001, 0, 0), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Plate" } }, -- 24
		{ n = "LowerFlank3", s = "Block", z = Vector3.new(0.906974, 1.554812, 0.259135), cf = CFrame.new(0, 0.874586, -1.181786, -1, 0, 0, 0, 0.997564, 0.069756, 0, 0.069757, -0.997565), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Plate" } }, -- 25
		{ n = "LowerFlank4", s = "Block", z = Vector3.new(0.906974, 1.554812, 0.259135), cf = CFrame.new(-1.166107, 0.874586, -0.015686, 0, 0.069756, -0.997564, 0, 0.997564, 0.069756, 1.000001, 0, 0), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Plate" } }, -- 26
		{ n = "CornerButtress1", s = "Block", z = Vector3.new(0.647839, 1.166109, 0.259135), cf = CFrame.new(0.778748, 0.680233, 0.763073, 0.707107, 0.073913, 0.703233, 0, 0.994522, -0.104528, -0.707107, 0.073913, 0.703234), c = Color3.fromRGB(24, 12, 12), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.094118, 0.047059, 0.047059), TintRole = "Plate" } }, -- 27
		{ n = "CornerButtress2", s = "Block", z = Vector3.new(0.647839, 1.166109, 0.259135), cf = CFrame.new(0.778748, 0.680233, -0.794433, -0.707106, 0.073913, 0.703233, 0, 0.994522, -0.104528, -0.707107, -0.073913, -0.703234), c = Color3.fromRGB(24, 12, 12), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.094118, 0.047059, 0.047059), TintRole = "Plate" } }, -- 28
		{ n = "CornerButtress3", s = "Block", z = Vector3.new(0.647839, 1.166109, 0.259135), cf = CFrame.new(-0.778778, 0.680233, -0.794433, -0.707107, -0.073913, -0.703233, 0, 0.994522, -0.104528, 0.707107, -0.073913, -0.703234), c = Color3.fromRGB(24, 12, 12), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.094118, 0.047059, 0.047059), TintRole = "Plate" } }, -- 29
		{ n = "CornerButtress4", s = "Block", z = Vector3.new(0.647839, 1.166109, 0.259135), cf = CFrame.new(-0.778748, 0.680233, 0.763073, 0.707106, -0.073913, -0.703233, 0, 0.994522, -0.104528, 0.707107, 0.073913, 0.703234), c = Color3.fromRGB(24, 12, 12), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.094118, 0.047059, 0.047059), TintRole = "Plate" } }, -- 30
		{ n = "UpperDome", s = "Block", z = Vector3.new(2.008299, 0.453487, 2.008299), cf = CFrame.new(0, 1.911126, -0.015686, 1, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Shell" } }, -- 31
		{ n = "DroopPetal1_Front", s = "Block", z = Vector3.new(1.036542, 1.813948, 0.356311), cf = CFrame.new(0, 1.328074, -1.181787, 0.999999, 0, 0, 0, 0.961262, -0.275637, 0, 0.275638, 0.961263), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Plate" } }, -- 32
		{ n = "PetalEdge1_Front", s = "Block", z = Vector3.new(1.101326, 0.388703, 0.388703), cf = CFrame.new(0, 0.550665, -1.311356, 0.999999, 0, 0, 0, 0.927184, -0.374607, 0, 0.374607, 0.927185), c = Color3.fromRGB(168, 38, 30), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.14902, 0.117647), TintRole = "Plate" } }, -- 33
		{ n = "DroopPetal2", s = "Block", z = Vector3.new(0.971758, 1.619596, 0.323919), cf = CFrame.new(1.166077, 1.587209, -0.015686, 0, 0.241922, 0.970295, 0, 0.970296, -0.241922, -1.000001, 0, 0), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Plate" } }, -- 34
		{ n = "PetalEdge2", s = "Block", z = Vector3.new(1.036542, 0.323919, 0.323919), cf = CFrame.new(1.295654, 0.939379, -0.015686, 0, 0.34202, 0.939692, 0, 0.939693, -0.34202, -1.000001, 0, 0), c = Color3.fromRGB(168, 38, 30), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.14902, 0.117647), TintRole = "Plate" } }, -- 35
		{ n = "DroopPetal4", s = "Block", z = Vector3.new(0.971758, 1.619596, 0.323919), cf = CFrame.new(-1.166107, 1.587209, -0.015686, 0, -0.241922, -0.970295, 0, 0.970296, -0.241922, 1.000001, 0, 0), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Plate" } }, -- 36
		{ n = "PetalEdge4", s = "Block", z = Vector3.new(1.036542, 0.323919, 0.323919), cf = CFrame.new(-1.295685, 0.939367, -0.015674, 0, -0.34202, -0.939692, 0, 0.939693, -0.34202, 1.000001, 0, 0), c = Color3.fromRGB(168, 38, 30), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.14902, 0.117647), TintRole = "Plate" } }, -- 37
		{ n = "DroopPetal3_Back", s = "Block", z = Vector3.new(1.036542, 1.68438, 0.323919), cf = CFrame.new(0, 1.522424, 1.215212, -0.999999, 0, 0, 0, 0.961262, -0.275637, 0, -0.275638, -0.961263), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Plate" } }, -- 38
		{ n = "PetalEdge3_Back", s = "Block", z = Vector3.new(1.101326, 0.356311, 0.356311), cf = CFrame.new(0, 0.809802, 1.344766, -0.999999, 0, 0, 0, 0.927184, -0.374607, 0, -0.374607, -0.927185), c = Color3.fromRGB(168, 38, 30), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.14902, 0.117647), TintRole = "Plate" } }, -- 39
		{ n = "ApexCap", s = "Wedge", z = Vector3.new(0.647839, 0.583055, 0.647839), cf = CFrame.new(0, 3.401155, -0.015686, 0.999999, 0, 0, 0, 1, 0, 0, 0, 1.000001), c = Color3.fromRGB(38, 18, 18), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.14902, 0.070588, 0.070588), TintRole = "Shell" } }, -- 40
		{ n = "DorsalCap_1", s = "Wedge", z = Vector3.new(0.388703, 0.388703, 0.388703), cf = CFrame.new(-0.000031, 3.66029, -0.145245, 0.999999, 0, 0, 0, 0.990268, 0.139173, 0, -0.139173, 0.990269), c = Color3.fromRGB(168, 38, 30), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.14902, 0.117647), TintRole = "Plate" } }, -- 41
		{ n = "DorsalCap_2", s = "Wedge", z = Vector3.new(0.388703, 0.388703, 0.388703), cf = CFrame.new(-0.000031, 3.66029, 0.113885, 0.999999, 0, 0, 0, 0.990268, -0.139173, 0, 0.139173, 0.990269), c = Color3.fromRGB(168, 38, 30), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.14902, 0.117647), TintRole = "Plate" } }, -- 42
	},
	Joints = {
		{ k = "Weld", n = "DripBeadWeld", h = 17, a = 17, b = 18, c0 = CFrame.new(0, -0.259135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HearthFilamentWeld", h = 19, a = 19, b = 20, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CoreCrossWeld", h = 21, a = 21, b = 22, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerFlank1Weld", h = 21, a = 21, b = 23, c0 = CFrame.new(0, -0.064782, 1.166111, 1, 0, 0, 0, 0.997564, 0.069756, 0, -0.069756, 0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerFlank2Weld", h = 21, a = 21, b = 24, c0 = CFrame.new(1.166087, -0.064782, 0, 0, -0.069756, 0.997564, 0, 0.997564, 0.069756, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerFlank3Weld", h = 21, a = 21, b = 25, c0 = CFrame.new(0, -0.064782, -1.166099, -1, 0, 0, 0, 0.997564, 0.069756, 0, 0.069756, -0.997564), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerFlank4Weld", h = 21, a = 21, b = 26, c0 = CFrame.new(-1.166111, -0.064782, 0, 0, 0.069756, -0.997564, 0, 0.997564, 0.069756, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CornerButtress1Weld", h = 21, a = 21, b = 27, c0 = CFrame.new(0.778759, -0.259135, 0.778759, 0.707107, 0.073913, 0.703233, 0, 0.994522, -0.104528, -0.707107, 0.073913, 0.703233), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CornerButtress2Weld", h = 21, a = 21, b = 28, c0 = CFrame.new(0.778734, -0.259135, -0.778746, -0.707107, 0.073913, 0.703233, 0, 0.994522, -0.104528, -0.707107, -0.073913, -0.703233), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CornerButtress3Weld", h = 21, a = 21, b = 29, c0 = CFrame.new(-0.778783, -0.259135, -0.778746, -0.707107, -0.073913, -0.703233, 0, 0.994522, -0.104528, 0.707107, -0.073913, -0.703233), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CornerButtress4Weld", h = 21, a = 21, b = 30, c0 = CFrame.new(-0.778759, -0.259135, 0.778759, 0.707107, -0.073913, -0.703233, 0, 0.994522, -0.104528, 0.707107, 0.073913, 0.703233), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_02Weld", h = 21, a = 21, b = 2, c0 = CFrame.new(1.216501, 0.064785, 0.503912, 0.92388, 0, -0.382683, 0, 1, 0, 0.382683, 0, 0.92388), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_04Weld", h = 21, a = 21, b = 4, c0 = CFrame.new(0.5039, 0.064785, -1.216526, 0.382683, 0, 0.92388, 0, 1, 0, -0.92388, 0, 0.382683), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_06Weld", h = 21, a = 21, b = 6, c0 = CFrame.new(-1.216526, 0.064785, -0.5039, -0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, -0.92388), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_08Weld", h = 21, a = 21, b = 8, c0 = CFrame.new(-0.5039, 0.064785, 1.216526, -0.382683, 0, -0.92388, 0, 1, 0, 0.92388, 0, -0.382683), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MagmaCrack_01Weld", h = 21, a = 21, b = 9, c0 = CFrame.new(0, -0.19435, 1.263283, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MagmaCrack_02Weld", h = 21, a = 21, b = 10, c0 = CFrame.new(0.893279, 0.32392, 0.893279, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MagmaCrack_03Weld", h = 21, a = 21, b = 11, c0 = CFrame.new(1.263258, -0.19435, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MagmaCrack_04Weld", h = 21, a = 21, b = 12, c0 = CFrame.new(0.893254, 0.32392, -0.893279, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MagmaCrack_05Weld", h = 21, a = 21, b = 13, c0 = CFrame.new(-0.000025, -0.19435, -1.263271, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MagmaCrack_06Weld", h = 21, a = 21, b = 14, c0 = CFrame.new(-0.893279, 0.32392, -0.893279, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MagmaCrack_07Weld", h = 21, a = 21, b = 15, c0 = CFrame.new(-1.263308, -0.19435, 0.000012, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MagmaCrack_08Weld", h = 21, a = 21, b = 16, c0 = CFrame.new(-0.893279, 0.32392, 0.893279, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidHinge", h = 21, a = 21, b = 31, c0 = CFrame.new(-0.000025, 0.842191, 0.712626, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.000025, -0.129568, 0.712626, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_01Weld", h = 23, a = 23, b = 1, c0 = CFrame.new(0.5039, 0.125737, 0.059324, 0.382683, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_03Weld", h = 24, a = 24, b = 3, c0 = CFrame.new(0.503887, 0.125737, 0.059336, 0.382684, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_05Weld", h = 25, a = 25, b = 5, c0 = CFrame.new(0.503924, 0.125736, 0.059336, 0.382683, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_07Weld", h = 26, a = 26, b = 7, c0 = CFrame.new(0.503912, 0.125734, 0.059311, 0.382684, 0, -0.92388, -0.064447, 0.997564, -0.026695, 0.921629, 0.069756, 0.381751), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DroopPetal1_FrontWeld", h = 31, a = 31, b = 32, c0 = CFrame.new(0, -0.583053, -1.166099, 1, 0, 0, 0, 0.961262, -0.275637, 0, 0.275637, 0.961262), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DroopPetal2Weld", h = 31, a = 31, b = 34, c0 = CFrame.new(1.166087, -0.323917, 0, 0, 0.241922, 0.970296, 0, 0.970296, -0.241922, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DroopPetal4Weld", h = 31, a = 31, b = 36, c0 = CFrame.new(-1.166111, -0.323917, 0, 0, -0.241922, -0.970296, 0, 0.970296, -0.241922, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DroopPetal3_BackWeld", h = 31, a = 31, b = 38, c0 = CFrame.new(0, -0.388703, 1.230897, -1, 0, 0, 0, 0.961262, -0.275637, 0, -0.275637, -0.961262), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "ApexCapWeld", h = 31, a = 31, b = 40, c0 = CFrame.new(0, 1.490029, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MagmaHearthWeld", h = 31, a = 31, b = 19, c0 = CFrame.new(0, -0.19435, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PetalEdge1_FrontWeld", h = 32, a = 32, b = 33, c0 = CFrame.new(0, -0.783008, 0.089733, 1, 0, 0, 0, 0.994522, -0.104528, 0, 0.104529, 0.994522), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DripStemWeld", h = 33, a = 33, b = 17, c0 = CFrame.new(0, -0.144399, -0.011516, 1, 0, 0, 0, 0.927184, 0.374607, 0, -0.374607, 0.927184), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PetalEdge2Weld", h = 34, a = 34, b = 35, c0 = CFrame.new(0, -0.597241, 0.282446, 1, 0, 0, 0, 0.994522, -0.104528, 0, 0.104528, 0.994522), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PetalEdge4Weld", h = 36, a = 36, b = 37, c0 = CFrame.new(0.000012, -0.597253, 0.282446, 1, 0, 0, 0, 0.994522, -0.104528, 0, 0.104528, 0.994522), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PetalEdge3_BackWeld", h = 38, a = 38, b = 39, c0 = CFrame.new(0, -0.720726, 0.07189, 1, 0, 0, 0, 0.994522, -0.104528, 0, 0.104529, 0.994522), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DorsalCap_1Weld", h = 40, a = 40, b = 41, c0 = CFrame.new(-0.000025, 0.259135, -0.129558, 1, 0, 0, 0, 0.990268, 0.139173, 0, -0.139173, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DorsalCap_2Weld", h = 40, a = 40, b = 42, c0 = CFrame.new(-0.000025, 0.259135, 0.129571, 1, 0, 0, 0, 0.990268, -0.139173, 0, 0.139173, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "EpicLight", p = 19, range = 2.6, brightness = 0.4, color = Color3.new(1, 0.329412, 0.101961), shadows = false, enabled = true, a = { TintRole = "GlowLight" } },
	},
	Emitters = {},
	Textures = {
	},
}

return spec
