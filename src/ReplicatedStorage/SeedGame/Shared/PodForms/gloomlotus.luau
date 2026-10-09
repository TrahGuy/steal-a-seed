--!strict
--==============================================================================
-- POD FORM: Gloomlotus (tanglemire pods/GloomlotusPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "tanglemire pods/GloomlotusPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "tanglemire pods/GloomlotusPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(2.332343, 4.287829, 2.332336), Height = 4.287829, PartCount = 42,
	Base = 0, Root = 23,
	Attributes = {},
	Owner = { Biome = "tanglemire", BottomOffset = 0, ClosedDepth = 0.739971, ClosedHeight = 1.394091, ClosedWidth = 0.739971, IsPod = true, MythicLightEnabled = true, OpenAmount = 0, OpenDuration = 0.45, PartCount = 43, Rarity = "Mythic", RulesVersion = "2026-10-09", ShellCentre = Vector3.new(0, 0.731974, 0), SizeSeamRole = "Seam", Species = "Gloomlotus", Unit = 1, WidthClassUnit = 1 },
	Removed = { "SeedBase" },
	Parts = {
		{ n = "Seam_01", s = "Block", z = Vector3.new(0.141837, 0.141837, 0.720681), cf = CFrame.new(-0.73125, 2.36801, -0.731262, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "Seam" } }, -- 1
		{ n = "Seam_02", s = "Block", z = Vector3.new(0.141837, 0.141837, 1.087419), cf = CFrame.new(0, 2.36801, -0.958191, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "Seam" } }, -- 2
		{ n = "Seam_03", s = "Block", z = Vector3.new(0.141837, 0.141837, 0.720681), cf = CFrame.new(0.73125, 2.36801, -0.731262, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "Seam" } }, -- 3
		{ n = "Seam_04", s = "Block", z = Vector3.new(0.141837, 0.141837, 1.087419), cf = CFrame.new(0.95819, 2.36801, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "Seam" } }, -- 4
		{ n = "Seam_05", s = "Block", z = Vector3.new(0.141837, 0.141837, 0.720681), cf = CFrame.new(0.73125, 2.36801, 0.731262, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "Seam" } }, -- 5
		{ n = "Seam_06", s = "Block", z = Vector3.new(0.141837, 0.141837, 1.087419), cf = CFrame.new(0, 2.36801, 0.958191, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "Seam" } }, -- 6
		{ n = "Seam_07", s = "Block", z = Vector3.new(0.141837, 0.141837, 0.720681), cf = CFrame.new(-0.73125, 2.36801, 0.731262, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "Seam" } }, -- 7
		{ n = "Seam_08", s = "Block", z = Vector3.new(0.141837, 0.141837, 1.087419), cf = CFrame.new(-0.95819, 2.36801, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "Seam" } }, -- 8
		{ n = "WispJewel", s = "Block", z = Vector3.new(0.409752, 0.53583, 0.409752), cf = CFrame.new(0, 3.644546, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(194, 255, 231), m = Enum.Material.Neon, t = 0.1, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.760784, 1, 0.905882), TintRole = "Glow" } }, -- 9
		{ n = "WispTip", s = "Wedge", z = Vector3.new(0.283675, 0.472791, 0.267915), cf = CFrame.new(0, 4.022779, 0, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 0, 0, 1), c = Color3.fromRGB(194, 255, 231), m = Enum.Material.Neon, t = 0.1, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.760784, 1, 0.905882), TintRole = "Glow" } }, -- 10
		{ n = "MangroveRoot1_1", s = "Block", z = Vector3.new(0.378233, 0.267915, 0.862392), cf = CFrame.new(0.713202, 0.208931, 0.713196, -0.707107, -0.126491, -0.695701, 0, 0.98387, -0.178885, 0.707107, -0.126491, -0.695701), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 11
		{ n = "MangroveRoot1_2", s = "Block", z = Vector3.new(0.299434, 0.267915, 0.795037), cf = CFrame.new(0.924934, 0.587164, 0.924927, -0.707107, -0.699284, 0.104893, 0, -0.148341, -0.988936, 0.707107, -0.699284, 0.104893), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 12
		{ n = "MangroveRoot1_3", s = "Block", z = Vector3.new(0.299434, 0.267915, 0.85174), cf = CFrame.new(0.702059, 1.122994, 0.702057, -0.707107, -0.449513, 0.545837, 0, -0.77193, -0.635707, 0.707107, -0.449513, 0.545837), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 13
		{ n = "MangroveRoot2_1", s = "Block", z = Vector3.new(0.378233, 0.267915, 0.862392), cf = CFrame.new(0.713202, 0.208931, -0.713196, 0.707107, -0.126491, -0.695701, 0, 0.98387, -0.178885, 0.707107, 0.126491, 0.695701), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 14
		{ n = "MangroveRoot2_2", s = "Block", z = Vector3.new(0.299434, 0.267915, 0.795037), cf = CFrame.new(0.924934, 0.587164, -0.924927, 0.707107, -0.699284, 0.104893, 0, -0.148341, -0.988936, 0.707107, 0.699284, -0.104893), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 15
		{ n = "MangroveRoot2_3", s = "Block", z = Vector3.new(0.299434, 0.267915, 0.85174), cf = CFrame.new(0.702059, 1.122994, -0.702057, 0.707107, -0.449513, 0.545837, 0, -0.77193, -0.635707, 0.707107, 0.449513, -0.545837), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 16
		{ n = "MangroveRoot3_1", s = "Block", z = Vector3.new(0.378233, 0.267915, 0.862392), cf = CFrame.new(-0.713202, 0.208931, -0.713196, 0.707107, 0.126491, 0.695701, 0, 0.98387, -0.178885, -0.707107, 0.126491, 0.695701), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 17
		{ n = "MangroveRoot3_2", s = "Block", z = Vector3.new(0.299434, 0.267915, 0.795037), cf = CFrame.new(-0.924934, 0.587164, -0.924927, 0.707107, 0.699284, -0.104893, 0, -0.148341, -0.988936, -0.707107, 0.699284, -0.104893), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 18
		{ n = "MangroveRoot3_3", s = "Block", z = Vector3.new(0.299434, 0.267915, 0.85174), cf = CFrame.new(-0.702059, 1.122994, -0.702057, 0.707107, 0.449513, -0.545837, 0, -0.77193, -0.635707, -0.707107, 0.449513, -0.545837), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 19
		{ n = "MangroveRoot4_1", s = "Block", z = Vector3.new(0.378233, 0.267915, 0.862392), cf = CFrame.new(-0.713202, 0.208931, 0.713196, -0.707107, 0.126491, 0.695701, 0, 0.98387, -0.178885, -0.707107, -0.126491, -0.695701), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 20
		{ n = "MangroveRoot4_2", s = "Block", z = Vector3.new(0.299434, 0.267915, 0.795037), cf = CFrame.new(-0.924934, 0.587164, 0.924927, -0.707107, 0.699284, -0.104893, 0, -0.148341, -0.988936, -0.707107, -0.699284, 0.104893), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 21
		{ n = "MangroveRoot4_3", s = "Block", z = Vector3.new(0.299434, 0.267915, 0.85174), cf = CFrame.new(-0.702059, 1.122994, 0.702057, -0.707107, 0.449513, -0.545837, 0, -0.77193, -0.635707, -0.707107, -0.449513, 0.545837), c = Color3.fromRGB(39, 65, 56), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.152941, 0.254902, 0.219608), TintRole = "Roots" } }, -- 22
		{ n = "PodCore", s = "Block", z = Vector3.new(1.891164, 1.04014, 1.386853), cf = CFrame.new(0, 1.832181, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 23
		{ n = "CrossHusk", s = "Block", z = Vector3.new(1.386853, 1.04014, 1.891164), cf = CFrame.new(0, 1.832181, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 24
		{ n = "LowerPetal1", s = "Wedge", z = Vector3.new(1.166218, 0.914062, 0.472791), cf = CFrame.new(0, 1.753382, 0.835266, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(101, 185, 159), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.396078, 0.72549, 0.623529), TintRole = "Shell" } }, -- 25
		{ n = "LowerPetal2", s = "Wedge", z = Vector3.new(1.166218, 0.914062, 0.472791), cf = CFrame.new(0.835264, 1.753382, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 26
		{ n = "LowerPetal3", s = "Wedge", z = Vector3.new(1.166218, 0.914062, 0.472791), cf = CFrame.new(0, 1.753382, -0.835266, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(101, 185, 159), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.396078, 0.72549, 0.623529), TintRole = "Shell" } }, -- 27
		{ n = "LowerPetal4", s = "Wedge", z = Vector3.new(1.166218, 0.914062, 0.472791), cf = CFrame.new(-0.835264, 1.753382, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 28
		{ n = "SeedCap", s = "Block", z = Vector3.new(1.386853, 0.914062, 1.386853), cf = CFrame.new(0, 2.698964, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 29
		{ n = "UpperPetal1", s = "Block", z = Vector3.new(1.008621, 1.04014, 0.441272), cf = CFrame.new(0, 2.843783, 0.588165, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 30
		{ n = "PetalPoint1", s = "Wedge", z = Vector3.new(0.851024, 0.53583, 0.441272), cf = CFrame.new(0, 3.472241, 0.295105, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 31
		{ n = "LimePetalRim1", s = "Block", z = Vector3.new(0.078798, 0.882543, 0.078798), cf = CFrame.new(0.466487, 2.941024, 0.796692, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "PetalEdge" } }, -- 32
		{ n = "UpperPetal2", s = "Block", z = Vector3.new(1.008621, 1.04014, 0.441272), cf = CFrame.new(0.588175, 2.843783, 0, 0, -0.422618, 0.906308, 0, 0.906308, 0.422618, -1, 0, 0), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 33
		{ n = "PetalPoint2", s = "Wedge", z = Vector3.new(0.851024, 0.53583, 0.441272), cf = CFrame.new(0.29512, 3.472241, 0, 0, -0.422618, 0.906308, 0, 0.906308, 0.422618, -1, 0, 0), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 34
		{ n = "LimePetalRim2", s = "Block", z = Vector3.new(0.078798, 0.882543, 0.078798), cf = CFrame.new(0.796709, 2.941024, -0.466492, 0, -0.422618, 0.906308, 0, 0.906308, 0.422618, -1, 0, 0), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "PetalEdge" } }, -- 35
		{ n = "UpperPetal3", s = "Block", z = Vector3.new(1.008621, 1.04014, 0.441272), cf = CFrame.new(0, 2.843783, -0.588165, -1, 0, 0, 0, 0.906308, 0.422618, 0, 0.422618, -0.906308), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 36
		{ n = "PetalPoint3", s = "Wedge", z = Vector3.new(0.851024, 0.53583, 0.441272), cf = CFrame.new(0, 3.472241, -0.295105, -1, 0, 0, 0, 0.906308, 0.422618, 0, 0.422618, -0.906308), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 37
		{ n = "LimePetalRim3", s = "Block", z = Vector3.new(0.078798, 0.882543, 0.078798), cf = CFrame.new(-0.466487, 2.941024, -0.796692, -1, 0, 0, 0, 0.906308, 0.422618, 0, 0.422618, -0.906308), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "PetalEdge" } }, -- 38
		{ n = "UpperPetal4", s = "Block", z = Vector3.new(1.008621, 1.04014, 0.441272), cf = CFrame.new(-0.588175, 2.843783, 0, 0, 0.422618, -0.906308, 0, 0.906308, 0.422618, 1, 0, 0), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 39
		{ n = "PetalPoint4", s = "Wedge", z = Vector3.new(0.851024, 0.53583, 0.441272), cf = CFrame.new(-0.29512, 3.472241, 0, 0, 0.422618, -0.906308, 0, 0.906308, 0.422618, 1, 0, 0), c = Color3.fromRGB(146, 232, 204), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.572549, 0.909804, 0.8), TintRole = "Shell" } }, -- 40
		{ n = "LimePetalRim4", s = "Block", z = Vector3.new(0.078798, 0.882543, 0.078798), cf = CFrame.new(-0.796709, 2.941024, 0.466492, 0, 0.422618, -0.906308, 0, 0.906308, 0.422618, 1, 0, 0), c = Color3.fromRGB(188, 224, 108), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.737255, 0.878431, 0.423529), TintRole = "PetalEdge" } }, -- 41
		{ n = "JewelCalyx", s = "Block", z = Vector3.new(0.378233, 0.378233, 0.378233), cf = CFrame.new(0, 3.282073, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(101, 185, 159), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.396078, 0.72549, 0.623529), TintRole = "Shell" } }, -- 42
	},
	Joints = {
		{ k = "Weld", n = "WispTipWeld", h = 9, a = 9, b = 10, c0 = CFrame.new(0, 0.378232, 0, 0.965926, 0.258819, 0, -0.258819, 0.965926, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MangroveRoot1_2Weld", h = 11, a = 11, b = 12, c0 = CFrame.new(0, 0.318567, -0.362265, 1, 0, 0, 0, 0.030958, -0.999521, 0, 0.999521, 0.030958), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MangroveRoot1_3Weld", h = 12, a = 12, b = 13, c0 = CFrame.new(0, 0.232221, -0.576658, 1, 0, 0, 0, 0.743183, -0.669089, 0, 0.669089, 0.743183), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PodCoreWeld", h = 13, a = 13, b = 23, c0 = CFrame.new(0, 0.083726, -1.217254, -0.707107, 0, 0.707107, -0.449513, -0.77193, -0.449513, 0.545837, -0.635707, 0.545837), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MangroveRoot2_2Weld", h = 14, a = 14, b = 15, c0 = CFrame.new(0, 0.318567, -0.362265, 1, 0, 0, 0, 0.030958, -0.999521, 0, 0.999521, 0.030958), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MangroveRoot2_3Weld", h = 15, a = 15, b = 16, c0 = CFrame.new(0, 0.232221, -0.576658, 1, 0, 0, 0, 0.743183, -0.669089, 0, 0.669089, 0.743183), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MangroveRoot3_2Weld", h = 17, a = 17, b = 18, c0 = CFrame.new(0, 0.318567, -0.362265, 1, 0, 0, 0, 0.030958, -0.999521, 0, 0.999521, 0.030958), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MangroveRoot3_3Weld", h = 18, a = 18, b = 19, c0 = CFrame.new(0, 0.232221, -0.576658, 1, 0, 0, 0, 0.743183, -0.669089, 0, 0.669089, 0.743183), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MangroveRoot4_2Weld", h = 20, a = 20, b = 21, c0 = CFrame.new(0, 0.318567, -0.362265, 1, 0, 0, 0, 0.030958, -0.999521, 0, 0.999521, 0.030958), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MangroveRoot4_3Weld", h = 21, a = 21, b = 22, c0 = CFrame.new(0, 0.232221, -0.576658, 1, 0, 0, 0, 0.743183, -0.669089, 0, 0.669089, 0.743183), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "CrossHuskWeld", h = 23, a = 23, b = 24, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerPetal2Weld", h = 23, a = 23, b = 26, c0 = CFrame.new(0.835264, -0.078799, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerPetal4Weld", h = 23, a = 23, b = 28, c0 = CFrame.new(-0.835264, -0.078799, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_01Weld", h = 23, a = 23, b = 1, c0 = CFrame.new(-0.73125, 0.53583, -0.73125, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_03Weld", h = 23, a = 23, b = 3, c0 = CFrame.new(0.73125, 0.53583, -0.73125, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_04Weld", h = 23, a = 23, b = 4, c0 = CFrame.new(0.95819, 0.53583, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_05Weld", h = 23, a = 23, b = 5, c0 = CFrame.new(0.73125, 0.53583, 0.73125, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_07Weld", h = 23, a = 23, b = 7, c0 = CFrame.new(-0.73125, 0.53583, 0.73125, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_08Weld", h = 23, a = 23, b = 8, c0 = CFrame.new(-0.95819, 0.53583, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidHinge", h = 23, a = 23, b = 29, c0 = CFrame.new(0, 0.457031, 0.630388, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.409752, 0.630388, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerPetal1Weld", h = 24, a = 24, b = 25, c0 = CFrame.new(0, -0.078799, 0.835264, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerPetal3Weld", h = 24, a = 24, b = 27, c0 = CFrame.new(0, -0.078799, -0.835264, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_02Weld", h = 24, a = 24, b = 2, c0 = CFrame.new(0, 0.53583, -0.95819, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_06Weld", h = 24, a = 24, b = 6, c0 = CFrame.new(0, 0.53583, 0.95819, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "UpperPetal1Weld", h = 29, a = 29, b = 30, c0 = CFrame.new(0, 0.14482, 0.588175, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "UpperPetal2Weld", h = 29, a = 29, b = 33, c0 = CFrame.new(0.588175, 0.14482, 0, 0, -0.422618, 0.906308, 0, 0.906308, 0.422618, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "UpperPetal3Weld", h = 29, a = 29, b = 36, c0 = CFrame.new(0, 0.14482, -0.588175, -1, 0, 0, 0, 0.906308, 0.422618, 0, 0.422618, -0.906308), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "UpperPetal4Weld", h = 29, a = 29, b = 39, c0 = CFrame.new(-0.588175, 0.14482, 0, 0, 0.422618, -0.906308, 0, 0.906308, 0.422618, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "JewelCalyxWeld", h = 29, a = 29, b = 42, c0 = CFrame.new(0, 0.583109, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PetalPoint1Weld", h = 30, a = 30, b = 31, c0 = CFrame.new(0, 0.693427, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LimePetalRim1Weld", h = 30, a = 30, b = 32, c0 = CFrame.new(0.466487, 0, 0.230092, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PetalPoint2Weld", h = 33, a = 33, b = 34, c0 = CFrame.new(0, 0.693427, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LimePetalRim2Weld", h = 33, a = 33, b = 35, c0 = CFrame.new(0.466487, 0, 0.230092, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PetalPoint3Weld", h = 36, a = 36, b = 37, c0 = CFrame.new(0, 0.693427, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LimePetalRim3Weld", h = 36, a = 36, b = 38, c0 = CFrame.new(0.466487, 0, 0.230092, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PetalPoint4Weld", h = 39, a = 39, b = 40, c0 = CFrame.new(0, 0.693427, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LimePetalRim4Weld", h = 39, a = 39, b = 41, c0 = CFrame.new(0.466487, 0, 0.230092, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WispJewelWeld", h = 42, a = 42, b = 9, c0 = CFrame.new(0, 0.362473, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "MythicLight", p = 9, range = 2.4, brightness = 0.4, color = Color3.new(0.760784, 1, 0.905882), shadows = false, enabled = true, a = { TintRole = "GlowLight" } },
	},
	Emitters = {},
	Textures = {
	},
}

return spec
