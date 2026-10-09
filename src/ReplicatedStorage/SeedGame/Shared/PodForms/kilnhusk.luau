--!strict
--==============================================================================
-- POD FORM: Kilnhusk (emberroot pods/KilnhuskPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "emberroot pods/KilnhuskPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "emberroot pods/KilnhuskPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(2.68108, 3.704117, 2.734955), Height = 3.704117, PartCount = 46,
	Base = 0, Root = 12,
	Attributes = {},
	Owner = { Biome = "emberroot", BottomOffset = 0, ClosedDepth = 0.971874, ClosedHeight = 1.436275, ClosedWidth = 0.952733, IsPod = true, OpenAmount = 0, OpenDuration = 0.45, PartCount = 47, Rarity = "Legendary", RulesVersion = "2026-10-09", ShellCentre = Vector3.new(0, 0.489664, 0), SizeSeamRole = "Seam", SpawnMode = "CameraFloor", Species = "Kilnhusk", Unit = 1, WidthClassUnit = 1 },
	Removed = { "SeedBase" },
	Parts = {
		{ n = "Seam_01", s = "Block", z = Vector3.new(0.154775, 0.196986, 1.11495), cf = CFrame.new(0.891624, 1.181918, 0.918579, 0.707107, 0, -0.707107, 0, 1.000001, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(138, 106, 78), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.541176, 0.415686, 0.305882), TintRole = "Seam" } }, -- 1
		{ n = "Seam_02", s = "Block", z = Vector3.new(0.154775, 0.196986, 1.11495), cf = CFrame.new(1.260949, 1.181918, 0.026947, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(138, 106, 78), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.541176, 0.415686, 0.305882), TintRole = "Seam" } }, -- 2
		{ n = "Seam_03", s = "Block", z = Vector3.new(0.154775, 0.196986, 1.11495), cf = CFrame.new(0.891623, 1.181918, -0.864716, 0.707107, 0, 0.707107, 0, 1.000001, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(138, 106, 78), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.541176, 0.415686, 0.305882), TintRole = "Seam" } }, -- 3
		{ n = "Seam_04", s = "Block", z = Vector3.new(0.154775, 0.196986, 1.11495), cf = CFrame.new(0.000007, 1.181918, -1.233978, 0, 0, 1, 0, 1.000001, 0, -1, 0, 0), c = Color3.fromRGB(138, 106, 78), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.541176, 0.415686, 0.305882), TintRole = "Seam" } }, -- 4
		{ n = "Seam_05", s = "Block", z = Vector3.new(0.154775, 0.196986, 1.11495), cf = CFrame.new(-0.891624, 1.181918, -0.864685, -0.707107, 0, 0.707107, 0, 1.000001, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(138, 106, 78), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.541176, 0.415686, 0.305882), TintRole = "Seam" } }, -- 5
		{ n = "Seam_06", s = "Block", z = Vector3.new(0.154775, 0.196986, 1.11495), cf = CFrame.new(-1.260942, 1.181918, 0.026917, -1, 0, 0, 0, 1.000001, 0, 0, 0, -1), c = Color3.fromRGB(138, 106, 78), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.541176, 0.415686, 0.305882), TintRole = "Seam" } }, -- 6
		{ n = "Seam_07", s = "Block", z = Vector3.new(0.154775, 0.196986, 1.11495), cf = CFrame.new(-0.891609, 1.181918, 0.918549, -0.707107, 0, -0.707107, 0, 1.000001, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(138, 106, 78), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.541176, 0.415686, 0.305882), TintRole = "Seam" } }, -- 7
		{ n = "Seam_08", s = "Block", z = Vector3.new(0.154775, 0.196986, 1.11495), cf = CFrame.new(0.000007, 1.181918, 1.287872, 0, 0, -1, 0, 1.000001, 0, 1, 0, 0), c = Color3.fromRGB(138, 106, 78), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.541176, 0.415686, 0.305882), TintRole = "Seam" } }, -- 8
		{ n = "FurnaceGlow", s = "Block", z = Vector3.new(0.506536, 0.576888, 0.039397), cf = CFrame.new(0.000007, 0.661311, -1.273132, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 148, 40), m = Enum.Material.Neon, t = 0.25, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.580392, 0.156863), TintRole = "Glow" } }, -- 9
		{ n = "ChimneyGlow", s = "Wedge", z = Vector3.new(0.281409, 0.408043, 0.253268), cf = CFrame.new(0.000007, 3.299521, 0.026917, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 148, 40), m = Enum.Material.Neon, t = 0.25, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.580392, 0.156863), TintRole = "Glow" } }, -- 10
		{ n = "GlowCurl", s = "Wedge", z = Vector3.new(0.211057, 0.225127, 0.211057), cf = CFrame.new(0.028143, 3.551382, 0.026917, 0.819153, -0.573577, 0, 0.573577, 0.819153, 0, 0, 0, 1.000001), c = Color3.fromRGB(255, 148, 40), m = Enum.Material.Neon, t = 0.25, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.580392, 0.156863), TintRole = "Glow" } }, -- 11
		{ n = "PodCore", s = "Block", z = Vector3.new(2.026144, 2.138707, 1.407044), cf = CFrame.new(0.000007, 1.069354, 0.026917, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 12
		{ n = "CrossBarrel", s = "Block", z = Vector3.new(1.407044, 2.138707, 2.026144), cf = CFrame.new(0.000007, 1.069354, 0.026917, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 13
		{ n = "KilnStave1", s = "Block", z = Vector3.new(1.013072, 2.082426, 0.281409), cf = CFrame.new(0.789977, 1.069354, 0.816925, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 14
		{ n = "KilnStave2", s = "Block", z = Vector3.new(1.013072, 2.082426, 0.281409), cf = CFrame.new(1.117198, 1.069354, 0.026917, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 15
		{ n = "KilnStave3", s = "Block", z = Vector3.new(1.013072, 2.082426, 0.281409), cf = CFrame.new(0.789983, 1.069354, -0.763062, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 16
		{ n = "KilnStave4", s = "Block", z = Vector3.new(1.013072, 2.082426, 0.281409), cf = CFrame.new(0.000007, 1.069354, -1.090271, -1, 0, 0, 0, 1.000001, 0, 0, 0, -1), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 17
		{ n = "KilnStave5", s = "Block", z = Vector3.new(1.013072, 2.082426, 0.281409), cf = CFrame.new(-0.789969, 1.069354, -0.763062, -0.707107, 0, -0.707107, 0, 1.000001, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 18
		{ n = "KilnStave6", s = "Block", z = Vector3.new(1.013072, 2.082426, 0.281409), cf = CFrame.new(-1.11719, 1.069354, 0.026917, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 19
		{ n = "KilnStave7", s = "Block", z = Vector3.new(1.013072, 2.082426, 0.281409), cf = CFrame.new(-0.789969, 1.069354, 0.816895, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 20
		{ n = "KilnStave8", s = "Block", z = Vector3.new(1.013072, 2.082426, 0.281409), cf = CFrame.new(0.000007, 1.069354, 1.144104, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 21
		{ n = "FoundationBand01", s = "Block", z = Vector3.new(0.126634, 0.126634, 1.11495), cf = CFrame.new(0.891624, 0.168845, 0.918579, 0.707107, 0, -0.707107, 0, 1.000001, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(82, 76, 69), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.298039, 0.270588), TintRole = "Trim" } }, -- 22
		{ n = "FoundationBand02", s = "Block", z = Vector3.new(0.126634, 0.126634, 1.11495), cf = CFrame.new(1.260949, 0.168845, 0.026947, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(82, 76, 69), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.298039, 0.270588), TintRole = "Trim" } }, -- 23
		{ n = "FoundationBand03", s = "Block", z = Vector3.new(0.126634, 0.126634, 1.11495), cf = CFrame.new(0.891623, 0.168845, -0.864716, 0.707107, 0, 0.707107, 0, 1.000001, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(82, 76, 69), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.298039, 0.270588), TintRole = "Trim" } }, -- 24
		{ n = "FoundationBand04", s = "Block", z = Vector3.new(0.126634, 0.126634, 1.11495), cf = CFrame.new(0.000007, 0.168845, -1.233978, 0, 0, 1, 0, 1.000001, 0, -1, 0, 0), c = Color3.fromRGB(82, 76, 69), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.298039, 0.270588), TintRole = "Trim" } }, -- 25
		{ n = "FoundationBand05", s = "Block", z = Vector3.new(0.126634, 0.126634, 1.11495), cf = CFrame.new(-0.891624, 0.168845, -0.864685, -0.707107, 0, 0.707107, 0, 1.000001, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(82, 76, 69), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.298039, 0.270588), TintRole = "Trim" } }, -- 26
		{ n = "FoundationBand06", s = "Block", z = Vector3.new(0.126634, 0.126634, 1.11495), cf = CFrame.new(-1.260942, 0.168845, 0.026917, -1, 0, 0, 0, 1.000001, 0, 0, 0, -1), c = Color3.fromRGB(82, 76, 69), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.298039, 0.270588), TintRole = "Trim" } }, -- 27
		{ n = "FoundationBand07", s = "Block", z = Vector3.new(0.126634, 0.126634, 1.11495), cf = CFrame.new(-0.891609, 0.168845, 0.918549, -0.707107, 0, -0.707107, 0, 1.000001, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(82, 76, 69), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.298039, 0.270588), TintRole = "Trim" } }, -- 28
		{ n = "FoundationBand08", s = "Block", z = Vector3.new(0.126634, 0.126634, 1.11495), cf = CFrame.new(0.000007, 0.168845, 1.287872, 0, 0, -1, 0, 1.000001, 0, 1, 0, 0), c = Color3.fromRGB(82, 76, 69), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.298039, 0.270588), TintRole = "Trim" } }, -- 29
		{ n = "SeedCap", s = "Block", z = Vector3.new(2.194989, 0.281409, 2.194989), cf = CFrame.new(0.000007, 2.209061, 0.026917, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 30
		{ n = "LegendaryRim01", s = "Block", z = Vector3.new(0.126634, 0.154775, 1.013721), cf = CFrame.new(0.805221, 2.223131, 0.832123, 0.707107, 0, -0.707107, 0, 1.000001, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 31
		{ n = "LegendaryRim02", s = "Block", z = Vector3.new(0.126634, 0.154775, 1.013721), cf = CFrame.new(1.138754, 2.223131, 0.026917, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 32
		{ n = "LegendaryRim03", s = "Block", z = Vector3.new(0.126634, 0.154775, 1.013721), cf = CFrame.new(0.805221, 2.223131, -0.778259, 0.707107, 0, 0.707107, 0, 1.000001, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 33
		{ n = "LegendaryRim04", s = "Block", z = Vector3.new(0.126634, 0.154775, 1.013721), cf = CFrame.new(0.000007, 2.223131, -1.111847, 0, 0, 1, 0, 1.000001, 0, -1, 0, 0), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 34
		{ n = "LegendaryRim05", s = "Block", z = Vector3.new(0.126634, 0.154775, 1.013721), cf = CFrame.new(-0.805213, 2.223131, -0.77829, -0.707107, 0, 0.707107, 0, 1.000001, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 35
		{ n = "LegendaryRim06", s = "Block", z = Vector3.new(0.126634, 0.154775, 1.013721), cf = CFrame.new(-1.138746, 2.223131, 0.026917, -1, 0, 0, 0, 1.000001, 0, 0, 0, -1), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 36
		{ n = "LegendaryRim07", s = "Block", z = Vector3.new(0.126634, 0.154775, 1.013721), cf = CFrame.new(-0.805207, 2.223131, 0.832153, -0.707107, 0, -0.707107, 0, 1.000001, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 37
		{ n = "LegendaryRim08", s = "Block", z = Vector3.new(0.126634, 0.154775, 1.013721), cf = CFrame.new(0.000007, 2.223131, 1.16571, 0, 0, -1, 0, 1.000001, 0, 1, 0, 0), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 38
		{ n = "FurnaceInset", s = "Block", z = Vector3.new(0.675381, 0.816086, 0.084423), cf = CFrame.new(0.000007, 0.703522, -1.225311, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(31, 30, 28), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.121569, 0.117647, 0.109804), TintRole = "Trim" } }, -- 39
		{ n = "ChimneyRim", s = "Block", z = Vector3.new(0.675381, 0.211057, 0.675381), cf = CFrame.new(0.000007, 3.011077, 0.026917, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 40
		{ n = "DoorJamb1", s = "Block", z = Vector3.new(0.126634, 0.605029, 0.121006), cf = CFrame.new(-0.323619, 0.619099, -1.306946, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 41
		{ n = "DoorArch1", s = "Block", z = Vector3.new(0.211057, 0.196986, 0.121006), cf = CFrame.new(-0.211052, 0.984931, -1.306915, 0.819152, 0.573577, 0, -0.573577, 0.819153, 0, 0, 0, 1), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 42
		{ n = "DoorJamb2", s = "Block", z = Vector3.new(0.126634, 0.605029, 0.121006), cf = CFrame.new(0.323627, 0.619099, -1.306946, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 43
		{ n = "DoorArch2", s = "Block", z = Vector3.new(0.211057, 0.196986, 0.121006), cf = CFrame.new(0.211065, 0.984931, -1.306946, 0.819152, -0.573577, 0, 0.573577, 0.819153, 0, 0, 0, 1), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 44
		{ n = "DoorKeystone", s = "Block", z = Vector3.new(0.281409, 0.121006, 0.121006), cf = CFrame.new(0.000007, 1.083425, -1.306915, 1.000001, 0, 0, 0, 1.000001, 0, 0, 0, 1.000001), c = Color3.fromRGB(196, 164, 100), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.768627, 0.643137, 0.392157), TintRole = "LegendaryTrim" } }, -- 45
		{ n = "StubChimney", s = "Block", z = Vector3.new(0.506536, 0.675381, 0.506536), cf = CFrame.new(0.000007, 2.659316, 0.026917, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c = Color3.fromRGB(60, 58, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.227451, 0.219608), TintRole = "Shell" } }, -- 46
	},
	Joints = {
		{ k = "Weld", n = "GlowCurlWeld", h = 10, a = 10, b = 11, c0 = CFrame.new(0.028136, 0.251861, 0, 0.819152, -0.573577, 0, 0.573577, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrossBarrelWeld", h = 12, a = 12, b = 13, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "KilnStave1Weld", h = 12, a = 12, b = 14, c0 = CFrame.new(0.78997, 0, 0.790003, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "KilnStave2Weld", h = 12, a = 12, b = 15, c0 = CFrame.new(1.117191, 0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "KilnStave3Weld", h = 12, a = 12, b = 16, c0 = CFrame.new(0.789976, 0, -0.789981, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "KilnStave6Weld", h = 12, a = 12, b = 19, c0 = CFrame.new(-1.117197, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "KilnStave7Weld", h = 12, a = 12, b = 20, c0 = CFrame.new(-0.789976, 0, 0.789981, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidHinge", h = 12, a = 12, b = 30, c0 = CFrame.new(0, 1.055284, 0.64725, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.084423, 0.64725, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "KilnStave4Weld", h = 13, a = 13, b = 17, c0 = CFrame.new(0, 0, -1.117202, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "KilnStave5Weld", h = 13, a = 13, b = 18, c0 = CFrame.new(-0.789976, 0, -0.789981, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "KilnStave8Weld", h = 13, a = 13, b = 21, c0 = CFrame.new(0, 0, 1.117202, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FoundationBand01Weld", h = 14, a = 14, b = 22, c0 = CFrame.new(0, -0.900509, 0.143751, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_01Weld", h = 14, a = 14, b = 1, c0 = CFrame.new(0, 0.112564, 0.143751, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FoundationBand02Weld", h = 15, a = 15, b = 23, c0 = CFrame.new(-0.000021, -0.900509, 0.143751, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_02Weld", h = 15, a = 15, b = 2, c0 = CFrame.new(-0.000021, 0.112564, 0.143751, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FoundationBand03Weld", h = 16, a = 16, b = 24, c0 = CFrame.new(0, -0.900509, 0.14374, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_03Weld", h = 16, a = 16, b = 3, c0 = CFrame.new(0, 0.112564, 0.14374, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FoundationBand04Weld", h = 17, a = 17, b = 25, c0 = CFrame.new(0, -0.900509, 0.143719, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_04Weld", h = 17, a = 17, b = 4, c0 = CFrame.new(0, 0.112564, 0.143719, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FurnaceInsetWeld", h = 17, a = 17, b = 39, c0 = CFrame.new(0, -0.365832, 0.135045, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FoundationBand05Weld", h = 18, a = 18, b = 26, c0 = CFrame.new(0.000021, -0.900509, 0.14374, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_05Weld", h = 18, a = 18, b = 5, c0 = CFrame.new(0.000021, 0.112564, 0.14374, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FoundationBand06Weld", h = 19, a = 19, b = 27, c0 = CFrame.new(0, -0.900509, 0.143751, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_06Weld", h = 19, a = 19, b = 6, c0 = CFrame.new(0, 0.112564, 0.143751, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FoundationBand07Weld", h = 20, a = 20, b = 28, c0 = CFrame.new(0, -0.900509, 0.14374, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_07Weld", h = 20, a = 20, b = 7, c0 = CFrame.new(0, 0.112564, 0.14374, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FoundationBand08Weld", h = 21, a = 21, b = 29, c0 = CFrame.new(0, -0.900509, 0.143762, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_08Weld", h = 21, a = 21, b = 8, c0 = CFrame.new(0, 0.112564, 0.143762, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LegendaryRim01Weld", h = 30, a = 30, b = 31, c0 = CFrame.new(0.805214, 0.014071, 0.805203, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LegendaryRim02Weld", h = 30, a = 30, b = 32, c0 = CFrame.new(1.138747, 0.014071, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LegendaryRim03Weld", h = 30, a = 30, b = 33, c0 = CFrame.new(0.805214, 0.014071, -0.805182, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LegendaryRim04Weld", h = 30, a = 30, b = 34, c0 = CFrame.new(0, 0.014071, -1.138758, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LegendaryRim05Weld", h = 30, a = 30, b = 35, c0 = CFrame.new(-0.805219, 0.014071, -0.805203, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LegendaryRim06Weld", h = 30, a = 30, b = 36, c0 = CFrame.new(-1.138752, 0.014071, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LegendaryRim07Weld", h = 30, a = 30, b = 37, c0 = CFrame.new(-0.805214, 0.014071, 0.805225, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LegendaryRim08Weld", h = 30, a = 30, b = 38, c0 = CFrame.new(0, 0.014071, 1.138779, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "StubChimneyWeld", h = 30, a = 30, b = 46, c0 = CFrame.new(0, 0.450254, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FurnaceGlowWeld", h = 39, a = 39, b = 9, c0 = CFrame.new(0, -0.042211, -0.047835, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DoorJamb1Weld", h = 39, a = 39, b = 41, c0 = CFrame.new(-0.323625, -0.084423, -0.081628, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DoorArch1Weld", h = 39, a = 39, b = 42, c0 = CFrame.new(-0.211059, 0.281409, -0.081607, 0.819152, 0.573577, 0, -0.573577, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DoorJamb2Weld", h = 39, a = 39, b = 43, c0 = CFrame.new(0.32362, -0.084423, -0.081628, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DoorArch2Weld", h = 39, a = 39, b = 44, c0 = CFrame.new(0.211059, 0.281409, -0.081628, 0.819152, -0.573577, 0, 0.573577, 0.819152, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "DoorKeystoneWeld", h = 39, a = 39, b = 45, c0 = CFrame.new(0, 0.379902, -0.081607, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "ChimneyGlowWeld", h = 40, a = 40, b = 10, c0 = CFrame.new(0, 0.288444, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "ChimneyRimWeld", h = 46, a = 46, b = 40, c0 = CFrame.new(0, 0.351761, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {},
	Textures = {
	},
}

return spec
