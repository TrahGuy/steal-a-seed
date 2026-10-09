--!strict
--==============================================================================
-- POD FORM: Toadcap (greenhollow pods/ToadcapPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "greenhollow pods/ToadcapPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "greenhollow pods/ToadcapPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(3.623899, 4.035575, 3.623932), Height = 4.035575, PartCount = 46,
	Base = 0, Root = 15,
	Attributes = {},
	Owner = { Biome = "greenhollow", BottomOffset = 0, ClosedDepth = 0.996773, ClosedHeight = 1.27, ClosedWidth = 0.996767, IsPod = true, OpenAmount = 0, OpenDuration = 0.45, PartCount = 48, RareLightEnabled = true, Rarity = "Rare", RulesVersion = "2026-10-09", ShellCentre = Vector3.new(0, 0.422431, 0), SizeSeamRole = "Seam", SpawnMode = "CameraAir", Species = "Toadcap", Unit = 1, WidthClassUnit = 1 },
	Removed = { "SeedBase", "BasePlinth" },
	Parts = {
		{ n = "Seam_01", s = "Block", z = Vector3.new(0.199961, 0.236317, 1.185756), cf = CFrame.new(0.514162, 1.090696, 1.241272, 0.382684, 0, -0.92388, 0, 1.000001, 0, 0.92388, 0, 0.382684), c = Color3.fromRGB(192, 176, 144), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.752941, 0.690196, 0.564706), TintRole = "Seam" } }, -- 1
		{ n = "Seam_02", s = "Block", z = Vector3.new(0.199961, 0.236317, 1.185756), cf = CFrame.new(1.241324, 1.090698, 0.51413, 0.92388, 0, -0.382684, 0, 1.000001, 0, 0.382683, 0, 0.92388), c = Color3.fromRGB(192, 176, 144), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.752941, 0.690196, 0.564706), TintRole = "Seam" } }, -- 2
		{ n = "Seam_03", s = "Block", z = Vector3.new(0.199961, 0.236317, 1.185756), cf = CFrame.new(1.2413, 1.090697, -0.514191, 0.92388, 0, 0.382684, 0, 1.000001, 0, -0.382684, 0, 0.92388), c = Color3.fromRGB(192, 176, 144), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.752941, 0.690196, 0.564706), TintRole = "Seam" } }, -- 3
		{ n = "Seam_04", s = "Block", z = Vector3.new(0.199961, 0.236317, 1.185756), cf = CFrame.new(0.51417, 1.0907, -1.241272, 0.382683, 0, 0.92388, 0, 1.000001, 0, -0.92388, 0, 0.382684), c = Color3.fromRGB(192, 176, 144), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.752941, 0.690196, 0.564706), TintRole = "Seam" } }, -- 4
		{ n = "Seam_05", s = "Block", z = Vector3.new(0.199961, 0.236317, 1.185756), cf = CFrame.new(-0.514162, 1.090701, -1.241333, -0.382684, 0, 0.92388, 0, 1.000001, 0, -0.92388, 0, -0.382684), c = Color3.fromRGB(192, 176, 144), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.752941, 0.690196, 0.564706), TintRole = "Seam" } }, -- 5
		{ n = "Seam_06", s = "Block", z = Vector3.new(0.199961, 0.236317, 1.185756), cf = CFrame.new(-1.241269, 1.090697, -0.514191, -0.92388, 0, 0.382683, 0, 1.000001, 0, -0.382683, 0, -0.92388), c = Color3.fromRGB(192, 176, 144), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.752941, 0.690196, 0.564706), TintRole = "Seam" } }, -- 6
		{ n = "Seam_07", s = "Block", z = Vector3.new(0.199961, 0.236317, 1.185756), cf = CFrame.new(-1.241285, 1.090693, 0.51416, -0.92388, 0, -0.382684, 0, 1.000001, 0, 0.382684, 0, -0.92388), c = Color3.fromRGB(192, 176, 144), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.752941, 0.690196, 0.564706), TintRole = "Seam" } }, -- 7
		{ n = "Seam_08", s = "Block", z = Vector3.new(0.199961, 0.236317, 1.185756), cf = CFrame.new(-0.514163, 1.090696, 1.241241, -0.382683, 0, -0.92388, 0, 1.000001, 0, 0.92388, 0, -0.382684), c = Color3.fromRGB(192, 176, 144), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.752941, 0.690196, 0.564706), TintRole = "Seam" } }, -- 8
		{ n = "CapSpot1", s = "Block", z = Vector3.new(0.581704, 0.290852, 0.581704), cf = CFrame.new(0, 2.835811, 1.163391, 1.000001, 0, 0, 0, 0.927185, 0.374607, 0, -0.374607, 0.927184), c = Color3.fromRGB(246, 240, 222), m = Enum.Material.Plastic, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.964706, 0.941176, 0.870588), TintRole = "Gem" } }, -- 9
		{ n = "CapSpot2", s = "Block", z = Vector3.new(0.581704, 0.290852, 0.581704), cf = CFrame.new(1.163415, 2.835811, -0.000031, 0, -0.374607, 0.927184, 0, 0.927185, 0.374607, -1.000001, 0, 0), c = Color3.fromRGB(246, 240, 222), m = Enum.Material.Plastic, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.964706, 0.941176, 0.870588), TintRole = "Gem" } }, -- 10
		{ n = "CapSpot3", s = "Block", z = Vector3.new(0.581704, 0.290852, 0.581704), cf = CFrame.new(0, 2.835811, -1.163452, -1.000001, 0, 0, 0, 0.927185, 0.374607, 0, 0.374607, -0.927184), c = Color3.fromRGB(246, 240, 222), m = Enum.Material.Plastic, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.964706, 0.941176, 0.870588), TintRole = "Gem" } }, -- 11
		{ n = "CapSpot4", s = "Block", z = Vector3.new(0.581704, 0.290852, 0.581704), cf = CFrame.new(-1.163408, 2.835811, 0, 0, 0.374607, -0.927184, 0, 0.927185, 0.374607, 1.000001, 0, 0), c = Color3.fromRGB(246, 240, 222), m = Enum.Material.Plastic, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.964706, 0.941176, 0.870588), TintRole = "Gem" } }, -- 12
		{ n = "SporeHearth", s = "Block", z = Vector3.new(0.799844, 0.799844, 0.799844), cf = CFrame.new(0, 2.035966, -0.000031, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 230, 170), m = Enum.Material.Neon, t = 0.05, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.901961, 0.666667), TintRole = "Gem" } }, -- 13
		{ n = "SporeFilament", s = "Block", z = Vector3.new(0.508991, 0.508991, 0.508991), cf = CFrame.new(0, 2.035966, -0.000031, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 245, 205), m = Enum.Material.Neon, t = 0.08, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.960784, 0.803922), TintRole = "Glow" } }, -- 14
		{ n = "PodCore", s = "Block", z = Vector3.new(2.035966, 1.963253, 2.035966), cf = CFrame.new(0, 1.017984, -0.000031, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Shell" } }, -- 15
		{ n = "CrossCore", s = "Block", z = Vector3.new(1.599687, 2.035966, 1.599687), cf = CFrame.new(0, 1.017984, -0.000031, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Shell" } }, -- 16
		{ n = "StipeFlank1", s = "Block", z = Vector3.new(0.799844, 1.817827, 0.290852), cf = CFrame.new(0, 1.017984, 1.199738, 1, 0, 0, 0, 0.99863, 0.052336, 0, -0.052336, 0.99863), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Plate" } }, -- 17
		{ n = "StipeFlank2", s = "Block", z = Vector3.new(0.799844, 1.817827, 0.290852), cf = CFrame.new(0.848369, 1.017984, 0.848328, 0.707107, -0.037007, 0.706138, 0, 0.99863, 0.052336, -0.707107, -0.037007, 0.706138), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Plate" } }, -- 18
		{ n = "StipeFlank3", s = "Block", z = Vector3.new(0.799844, 1.817827, 0.290852), cf = CFrame.new(1.199773, 1.017984, -0.000031, 0, -0.052336, 0.99863, 0, 0.99863, 0.052336, -1, 0, 0), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Plate" } }, -- 19
		{ n = "StipeFlank4", s = "Block", z = Vector3.new(0.799844, 1.817827, 0.290852), cf = CFrame.new(0.848369, 1.017984, -0.848358, -0.707107, -0.037007, 0.706138, 0, 0.99863, 0.052336, -0.707107, 0.037007, -0.706138), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Plate" } }, -- 20
		{ n = "StipeFlank5", s = "Block", z = Vector3.new(0.799844, 1.817827, 0.290852), cf = CFrame.new(0, 1.017984, -1.199799, -1, 0, 0, 0, 0.99863, 0.052336, 0, 0.052336, -0.99863), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Plate" } }, -- 21
		{ n = "StipeFlank6", s = "Block", z = Vector3.new(0.799844, 1.817827, 0.290852), cf = CFrame.new(-0.848362, 1.017984, -0.848358, -0.707107, 0.037007, -0.706138, 0, 0.99863, 0.052336, 0.707107, 0.037007, -0.706138), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Plate" } }, -- 22
		{ n = "StipeFlank7", s = "Block", z = Vector3.new(0.799844, 1.817827, 0.290852), cf = CFrame.new(-1.199765, 1.017984, 0, 0, 0.052336, -0.99863, 0, 0.99863, 0.052336, 1, 0, 0), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Plate" } }, -- 23
		{ n = "StipeFlank8", s = "Block", z = Vector3.new(0.799844, 1.817827, 0.290852), cf = CFrame.new(-0.848362, 1.017984, 0.848328, 0.707107, 0.037007, -0.706138, 0, 0.99863, 0.052336, 0.707107, -0.037007, 0.706138), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Plate" } }, -- 24
		{ n = "GillRidge1", s = "Block", z = Vector3.new(0.290852, 0.436278, 0.508991), cf = CFrame.new(0.000007, 1.89054, 1.454224, 1, 0, 0, 0, 0.978148, -0.207912, 0, 0.207912, 0.978148), c = Color3.fromRGB(246, 238, 214), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.964706, 0.933333, 0.839216), TintRole = "Plate" } }, -- 25
		{ n = "GillRidge2", s = "Block", z = Vector3.new(0.290852, 0.436278, 0.508991), cf = CFrame.new(1.028325, 1.89054, 1.02829, 0.707107, 0.147016, 0.691655, 0, 0.978148, -0.207912, -0.707107, 0.147016, 0.691655), c = Color3.fromRGB(246, 238, 214), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.964706, 0.933333, 0.839216), TintRole = "Plate" } }, -- 26
		{ n = "GillRidge3", s = "Block", z = Vector3.new(0.290852, 0.436278, 0.508991), cf = CFrame.new(1.45426, 1.89054, -0.000031, 0, 0.207912, 0.978148, 0, 0.978148, -0.207912, -1, 0, 0), c = Color3.fromRGB(246, 238, 214), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.964706, 0.933333, 0.839216), TintRole = "Plate" } }, -- 27
		{ n = "GillRidge4", s = "Block", z = Vector3.new(0.290852, 0.436278, 0.508991), cf = CFrame.new(1.028317, 1.89054, -1.02832, -0.707107, 0.147016, 0.691655, 0, 0.978148, -0.207912, -0.707107, -0.147016, -0.691655), c = Color3.fromRGB(246, 238, 214), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.964706, 0.933333, 0.839216), TintRole = "Plate" } }, -- 28
		{ n = "GillRidge5", s = "Block", z = Vector3.new(0.290852, 0.436278, 0.508991), cf = CFrame.new(0, 1.89054, -1.454285, -1, 0, 0, 0, 0.978148, -0.207912, 0, -0.207912, -0.978148), c = Color3.fromRGB(246, 238, 214), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.964706, 0.933333, 0.839216), TintRole = "Plate" } }, -- 29
		{ n = "GillRidge6", s = "Block", z = Vector3.new(0.290852, 0.436278, 0.508991), cf = CFrame.new(-1.028318, 1.89054, -1.02832, -0.707107, -0.147016, -0.691655, 0, 0.978148, -0.207912, 0.707107, -0.147016, -0.691655), c = Color3.fromRGB(246, 238, 214), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.964706, 0.933333, 0.839216), TintRole = "Plate" } }, -- 30
		{ n = "GillRidge7", s = "Block", z = Vector3.new(0.290852, 0.436278, 0.508991), cf = CFrame.new(-1.45426, 1.89054, -0.000031, 0, -0.207912, -0.978148, 0, 0.978148, -0.207912, 1, 0, 0), c = Color3.fromRGB(246, 238, 214), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.964706, 0.933333, 0.839216), TintRole = "Plate" } }, -- 31
		{ n = "GillRidge8", s = "Block", z = Vector3.new(0.290852, 0.436278, 0.508991), cf = CFrame.new(-1.028318, 1.89054, 1.02829, 0.707107, -0.147016, -0.691655, 0, 0.978148, -0.207912, 0.707107, 0.147016, 0.691655), c = Color3.fromRGB(246, 238, 214), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.964706, 0.933333, 0.839216), TintRole = "Plate" } }, -- 32
		{ n = "UpperDome", s = "Block", z = Vector3.new(2.181392, 0.508991, 2.181392), cf = CFrame.new(0, 2.108677, -0.000031, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Shell" } }, -- 33
		{ n = "CapRim1", s = "Block", z = Vector3.new(0.94527, 0.799844, 0.363565), cf = CFrame.new(0, 2.181392, 1.526978, 1.000001, 0, 0, 0, 0.961263, -0.275638, 0, 0.275638, 0.961262), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 34
		{ n = "CapRim2", s = "Block", z = Vector3.new(0.94527, 0.799844, 0.363565), cf = CFrame.new(1.079738, 2.181392, 1.079681, 0.707107, 0.194905, 0.679715, 0, 0.961263, -0.275638, -0.707107, 0.194905, 0.679715), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 35
		{ n = "CapRim3", s = "Block", z = Vector3.new(0.94527, 0.799844, 0.363565), cf = CFrame.new(1.526976, 2.181392, -0.000031, 0, 0.275638, 0.961262, 0, 0.961263, -0.275638, -1.000001, 0, 0), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 36
		{ n = "CapRim4", s = "Block", z = Vector3.new(0.94527, 0.799844, 0.363565), cf = CFrame.new(1.07973, 2.181392, -1.079742, -0.707107, 0.194905, 0.679715, 0, 0.961263, -0.275638, -0.707107, -0.194905, -0.679715), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 37
		{ n = "CapRim5", s = "Block", z = Vector3.new(0.94527, 0.799844, 0.363565), cf = CFrame.new(0, 2.181392, -1.527008, -1.000001, 0, 0, 0, 0.961263, -0.275638, 0, -0.275638, -0.961262), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 38
		{ n = "CapRim6", s = "Block", z = Vector3.new(0.94527, 0.799844, 0.363565), cf = CFrame.new(-1.079737, 2.181392, -1.079742, -0.707107, -0.194905, -0.679715, 0, 0.961263, -0.275638, 0.707107, -0.194905, -0.679715), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 39
		{ n = "CapRim7", s = "Block", z = Vector3.new(0.94527, 0.799844, 0.363565), cf = CFrame.new(-1.526975, 2.181392, -0.000031, 0, -0.275638, -0.961262, 0, 0.961263, -0.275638, 1.000001, 0, 0), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 40
		{ n = "CapRim8", s = "Block", z = Vector3.new(0.94527, 0.799844, 0.363565), cf = CFrame.new(-1.07973, 2.181392, 1.079681, 0.707107, -0.194905, -0.679715, 0, 0.961263, -0.275638, 0.707107, 0.194905, 0.679715), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 41
		{ n = "CapDome1", s = "Block", z = Vector3.new(1.017983, 1.308835, 0.363565), cf = CFrame.new(0.668406, 2.981237, 0.668396, 0.707107, -0.241845, 0.664463, 0, 0.939694, 0.342021, -0.707107, -0.241845, 0.664463), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 42
		{ n = "CapDome2", s = "Block", z = Vector3.new(1.017983, 1.308835, 0.363565), cf = CFrame.new(0.668406, 2.981237, -0.668427, -0.707107, -0.241845, 0.664463, 0, 0.939694, 0.342021, -0.707107, 0.241845, -0.664463), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 43
		{ n = "CapDome3", s = "Block", z = Vector3.new(1.017983, 1.308835, 0.363565), cf = CFrame.new(-0.668406, 2.981237, -0.668457, -0.707107, 0.241845, -0.664463, 0, 0.939694, 0.342021, 0.707107, 0.241845, -0.664463), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 44
		{ n = "CapDome4", s = "Block", z = Vector3.new(1.017983, 1.308835, 0.363565), cf = CFrame.new(-0.668406, 2.981237, 0.668396, 0.707107, 0.241845, -0.664463, 0, 0.939694, 0.342021, 0.707107, -0.241845, 0.664463), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Plate" } }, -- 45
		{ n = "CapApex", s = "Block", z = Vector3.new(0.94527, 0.508991, 0.94527), cf = CFrame.new(0, 3.781079, -0.000031, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(216, 112, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.847059, 0.439216, 0.392157), TintRole = "Shell" } }, -- 46
	},
	Joints = {
		{ k = "Weld", n = "SporeFilamentWeld", h = 13, a = 13, b = 14, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrossCoreWeld", h = 15, a = 15, b = 16, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StipeFlank1Weld", h = 15, a = 15, b = 17, c0 = CFrame.new(0, 0, 1.199772, 1, 0, 0, 0, 0.99863, 0.052336, 0, -0.052336, 0.99863), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StipeFlank2Weld", h = 15, a = 15, b = 18, c0 = CFrame.new(0.848369, 0, 0.848362, 0.707107, -0.037007, 0.706138, 0, 0.99863, 0.052336, -0.707107, -0.037007, 0.706138), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StipeFlank3Weld", h = 15, a = 15, b = 19, c0 = CFrame.new(1.199772, 0, 0, 0, -0.052336, 0.99863, 0, 0.99863, 0.052336, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StipeFlank4Weld", h = 15, a = 15, b = 20, c0 = CFrame.new(0.848369, 0, -0.848334, -0.707107, -0.037007, 0.706138, 0, 0.99863, 0.052336, -0.707107, 0.037007, -0.706138), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StipeFlank5Weld", h = 15, a = 15, b = 21, c0 = CFrame.new(0, 0, -1.199772, -1, 0, 0, 0, 0.99863, 0.052336, 0, 0.052336, -0.99863), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StipeFlank6Weld", h = 15, a = 15, b = 22, c0 = CFrame.new(-0.848362, 0, -0.848334, -0.707107, 0.037007, -0.706138, 0, 0.99863, 0.052336, 0.707107, 0.037007, -0.706138), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StipeFlank7Weld", h = 15, a = 15, b = 23, c0 = CFrame.new(-1.199765, 0, 0.000028, 0, 0.052336, -0.99863, 0, 0.99863, 0.052336, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StipeFlank8Weld", h = 15, a = 15, b = 24, c0 = CFrame.new(-0.848362, 0, 0.848362, 0.707107, 0.037007, -0.706138, 0, 0.99863, 0.052336, 0.707107, -0.037007, 0.706138), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GillRidge1Weld", h = 15, a = 15, b = 25, c0 = CFrame.new(0.000007, 0.872556, 1.454267, 1, 0, 0, 0, 0.978148, -0.207912, 0, 0.207912, 0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GillRidge2Weld", h = 15, a = 15, b = 26, c0 = CFrame.new(1.028325, 0.872556, 1.028325, 0.707107, 0.147016, 0.691655, 0, 0.978148, -0.207912, -0.707107, 0.147016, 0.691655), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GillRidge3Weld", h = 15, a = 15, b = 27, c0 = CFrame.new(1.45426, 0.872556, 0, 0, 0.207912, 0.978148, 0, 0.978148, -0.207912, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GillRidge4Weld", h = 15, a = 15, b = 28, c0 = CFrame.new(1.028318, 0.872556, -1.028297, -0.707107, 0.147016, 0.691655, 0, 0.978148, -0.207912, -0.707107, -0.147016, -0.691655), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GillRidge5Weld", h = 15, a = 15, b = 29, c0 = CFrame.new(0, 0.872556, -1.454239, -1, 0, 0, 0, 0.978148, -0.207912, 0, -0.207912, -0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GillRidge6Weld", h = 15, a = 15, b = 30, c0 = CFrame.new(-1.028318, 0.872556, -1.028297, -0.707107, -0.147016, -0.691655, 0, 0.978148, -0.207912, 0.707107, -0.147016, -0.691655), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GillRidge7Weld", h = 15, a = 15, b = 31, c0 = CFrame.new(-1.45426, 0.872556, 0, 0, -0.207912, -0.978148, 0, 0.978148, -0.207912, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "GillRidge8Weld", h = 15, a = 15, b = 32, c0 = CFrame.new(-1.028318, 0.872556, 1.028325, 0.707107, -0.147016, -0.691655, 0, 0.978148, -0.207912, 0.707107, 0.147016, 0.691655), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidHinge", h = 15, a = 15, b = 33, c0 = CFrame.new(0, 0.945267, 0.799848, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.145426, 0.799848, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_01Weld", h = 17, a = 17, b = 1, c0 = CFrame.new(0.514162, 0.07044, 0.045268, 0.382683, 0, -0.92388, -0.048352, 0.99863, -0.020028, 0.922613, 0.052336, 0.382159), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_02Weld", h = 18, a = 18, b = 2, c0 = CFrame.new(0.514176, 0.07044, 0.045296, 0.382683, 0, -0.92388, -0.048352, 0.99863, -0.020028, 0.922613, 0.052336, 0.382159), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_03Weld", h = 19, a = 19, b = 3, c0 = CFrame.new(0.514148, 0.07044, 0.045275, 0.382683, 0, -0.92388, -0.048352, 0.99863, -0.020028, 0.922613, 0.052336, 0.382159), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_04Weld", h = 20, a = 20, b = 4, c0 = CFrame.new(0.514148, 0.070444, 0.045268, 0.382683, 0, -0.92388, -0.048352, 0.99863, -0.020028, 0.922613, 0.052336, 0.382159), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_05Weld", h = 21, a = 21, b = 5, c0 = CFrame.new(0.514162, 0.070444, 0.045296, 0.382683, 0, -0.92388, -0.048352, 0.99863, -0.020028, 0.922613, 0.052336, 0.382159), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_06Weld", h = 22, a = 22, b = 6, c0 = CFrame.new(0.514121, 0.07044, 0.045282, 0.382684, 0, -0.923879, -0.048352, 0.99863, -0.020028, 0.922613, 0.052336, 0.382159), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_07Weld", h = 23, a = 23, b = 7, c0 = CFrame.new(0.514148, 0.070437, 0.045268, 0.382683, 0, -0.92388, -0.048352, 0.99863, -0.020028, 0.922613, 0.052336, 0.382159), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_08Weld", h = 24, a = 24, b = 8, c0 = CFrame.new(0.514148, 0.07044, 0.045268, 0.382684, 0, -0.923879, -0.048352, 0.99863, -0.020028, 0.922613, 0.052336, 0.382159), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapRim1Weld", h = 33, a = 33, b = 34, c0 = CFrame.new(0, 0.072715, 1.526995, 1, 0, 0, 0, 0.961262, -0.275637, 0, 0.275637, 0.961262), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapRim2Weld", h = 33, a = 33, b = 35, c0 = CFrame.new(1.079737, 0.072715, 1.079723, 0.707107, 0.194905, 0.679715, 0, 0.961262, -0.275637, -0.707107, 0.194905, 0.679715), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapRim3Weld", h = 33, a = 33, b = 36, c0 = CFrame.new(1.526975, 0.072715, 0, 0, 0.275637, 0.961262, 0, 0.961262, -0.275637, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapRim4Weld", h = 33, a = 33, b = 37, c0 = CFrame.new(1.07973, 0.072715, -1.079723, -0.707107, 0.194905, 0.679715, 0, 0.961262, -0.275637, -0.707107, -0.194905, -0.679715), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapRim5Weld", h = 33, a = 33, b = 38, c0 = CFrame.new(0, 0.072715, -1.526968, -1, 0, 0, 0, 0.961262, -0.275637, 0, -0.275637, -0.961262), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapRim6Weld", h = 33, a = 33, b = 39, c0 = CFrame.new(-1.079737, 0.072715, -1.079723, -0.707107, -0.194905, -0.679715, 0, 0.961262, -0.275637, 0.707107, -0.194905, -0.679715), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapRim7Weld", h = 33, a = 33, b = 40, c0 = CFrame.new(-1.526975, 0.072715, 0, 0, -0.275637, -0.961262, 0, 0.961262, -0.275637, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapRim8Weld", h = 33, a = 33, b = 41, c0 = CFrame.new(-1.07973, 0.072715, 1.079723, 0.707107, -0.194905, -0.679715, 0, 0.961262, -0.275637, 0.707107, 0.194905, 0.679715), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapDome1Weld", h = 33, a = 33, b = 42, c0 = CFrame.new(0.668405, 0.872559, 0.668426, 0.707107, -0.241845, 0.664463, 0, 0.939693, 0.34202, -0.707107, -0.241845, 0.664463), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapDome2Weld", h = 33, a = 33, b = 43, c0 = CFrame.new(0.668405, 0.872559, -0.668398, -0.707107, -0.241845, 0.664463, 0, 0.939693, 0.34202, -0.707107, 0.241845, -0.664463), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapDome3Weld", h = 33, a = 33, b = 44, c0 = CFrame.new(-0.668405, 0.872559, -0.668426, -0.707107, 0.241845, -0.664463, 0, 0.939693, 0.34202, 0.707107, 0.241845, -0.664463), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapDome4Weld", h = 33, a = 33, b = 45, c0 = CFrame.new(-0.668405, 0.872559, 0.668426, 0.707107, 0.241845, -0.664463, 0, 0.939693, 0.34202, 0.707107, -0.241845, 0.664463), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapApexWeld", h = 33, a = 33, b = 46, c0 = CFrame.new(0, 1.6724, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapSpot1Weld", h = 33, a = 33, b = 9, c0 = CFrame.new(0, 0.727133, 1.163436, 1, 0, 0, 0, 0.927184, 0.374607, 0, -0.374607, 0.927184), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapSpot2Weld", h = 33, a = 33, b = 10, c0 = CFrame.new(1.163415, 0.727133, 0, 0, -0.374607, 0.927184, 0, 0.927184, 0.374607, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapSpot3Weld", h = 33, a = 33, b = 11, c0 = CFrame.new(0, 0.727133, -1.163408, -1, 0, 0, 0, 0.927184, 0.374607, 0, 0.374607, -0.927184), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CapSpot4Weld", h = 33, a = 33, b = 12, c0 = CFrame.new(-1.163408, 0.727133, 0.000028, 0, 0.374607, -0.927184, 0, 0.927184, 0.374607, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SporeHearthWeld", h = 33, a = 33, b = 13, c0 = CFrame.new(0, -0.072711, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "RareLight", p = 13, range = 2.4, brightness = 0.35, color = Color3.new(1, 0.901961, 0.666667), shadows = false, enabled = true, a = { TintRole = "GlowLight" } },
	},
	Emitters = {},
	Textures = {
	},
}

return spec
