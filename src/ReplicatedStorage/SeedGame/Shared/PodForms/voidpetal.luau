--!strict
--==============================================================================
-- POD FORM: Voidpetal (starbloom pods/VoidpetalPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "starbloom pods/VoidpetalPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "starbloom pods/VoidpetalPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(3.365919, 3.554182, 3.265015), Height = 3.554182, PartCount = 54,
	Base = 0, Root = 18,
	Attributes = {},
	Owner = { Biome = "starbloom", BottomOffset = 0, ClosedDepth = 1.174922, ClosedHeight = 1.418983, ClosedWidth = 1.211236, IsPod = true, OpenAmount = 0, OpenDuration = 0.45, PartCount = 55, Rarity = "Epic", RulesVersion = "2026-10-09", ShellCentre = Vector3.new(0, 0.538396, 0.001114), SizeSeamRole = "Seam", SpawnMode = "CameraFloor", Species = "Voidpetal", Unit = 1, WidthClassUnit = 1 },
	Removed = { "SeedBase" },
	Parts = {
		{ n = "Seam_01", s = "Block", z = Vector3.new(0.222313, 1.389456, 0.222313), cf = CFrame.new(1.570086, 1.055987, 0.013611, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(196, 112, 232), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.768627, 0.439216, 0.909804), TintRole = "Seam" } }, -- 1
		{ n = "Seam_02", s = "Block", z = Vector3.new(0.222313, 1.389456, 0.222313), cf = CFrame.new(0.785043, 1.055987, 1.373352, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c = Color3.fromRGB(196, 112, 232), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.768627, 0.439216, 0.909804), TintRole = "Seam" } }, -- 2
		{ n = "Seam_03", s = "Block", z = Vector3.new(0.222313, 1.389456, 0.222313), cf = CFrame.new(-0.785043, 1.055987, 1.373352, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c = Color3.fromRGB(196, 112, 232), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.768627, 0.439216, 0.909804), TintRole = "Seam" } }, -- 3
		{ n = "Seam_04", s = "Block", z = Vector3.new(0.222313, 1.389456, 0.222313), cf = CFrame.new(-1.570086, 1.055987, 0.013611, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(196, 112, 232), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.768627, 0.439216, 0.909804), TintRole = "Seam" } }, -- 4
		{ n = "Seam_05", s = "Block", z = Vector3.new(0.222313, 1.389456, 0.222313), cf = CFrame.new(-0.785043, 1.055987, -1.34613, -0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, -0.866025), c = Color3.fromRGB(196, 112, 232), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.768627, 0.439216, 0.909804), TintRole = "Seam" } }, -- 5
		{ n = "Seam_06", s = "Block", z = Vector3.new(0.222313, 1.389456, 0.222313), cf = CFrame.new(0.785043, 1.055987, -1.34613, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c = Color3.fromRGB(196, 112, 232), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.768627, 0.439216, 0.909804), TintRole = "Seam" } }, -- 6
		{ n = "PantherSpot1", s = "Block", z = Vector3.new(0.30568, 0.30568, 0.111157), cf = CFrame.new(1.325179, 1.10688, 0.778717, 0.257757, -0.44935, 0.855363, 0.698401, 0.698401, 0.156434, -0.66768, 0.557065, 0.493844), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 7
		{ n = "PantherSpot2", s = "Block", z = Vector3.new(0.30568, 0.30568, 0.111157), cf = CFrame.new(0, 0.995724, 1.543793, 0.707107, -0.707107, 0, 0.698401, 0.698401, 0.156434, -0.110616, -0.110616, 0.987688), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 8
		{ n = "PantherSpot3", s = "Block", z = Vector3.new(0.30568, 0.30568, 0.111157), cf = CFrame.new(-1.325179, 1.10688, 0.778717, 0.44935, -0.257757, -0.855363, 0.698401, 0.698401, 0.156434, 0.557065, -0.66768, 0.493844), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 9
		{ n = "PantherSpot4", s = "Block", z = Vector3.new(0.30568, 0.30568, 0.111157), cf = CFrame.new(-1.325179, 0.995724, -0.751495, -0.257757, 0.44935, -0.855363, 0.698401, 0.698401, 0.156434, 0.66768, -0.557064, -0.493844), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 10
		{ n = "PantherSpot5", s = "Block", z = Vector3.new(0.30568, 0.30568, 0.111157), cf = CFrame.new(0, 1.10688, -1.516571, -0.707107, 0.707107, 0, 0.698401, 0.698401, 0.156434, 0.110616, 0.110616, -0.987688), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 11
		{ n = "PantherSpot6", s = "Block", z = Vector3.new(0.30568, 0.30568, 0.111157), cf = CFrame.new(1.325179, 0.995724, -0.751495, -0.449349, 0.257757, 0.855363, 0.698401, 0.698401, 0.156434, -0.557065, 0.66768, -0.493844), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 12
		{ n = "LipGlow", s = "Block", z = Vector3.new(0.94483, 0.138946, 0.138946), cf = CFrame.new(0, 2.181447, -1.250793, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Glow" } }, -- 13
		{ n = "WispJewel", s = "Block", z = Vector3.new(0.30568, 0.30568, 0.30568), cf = CFrame.new(0, 3.293012, -0.43103, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Glow" } }, -- 14
		{ n = "LowerCore1", s = "Block", z = Vector3.new(1.222722, 0.555783, 2.117816), cf = CFrame.new(0, 0.277891, 0.013611, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(30, 19, 52), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.07451, 0.203922), TintRole = "Shell" } }, -- 15
		{ n = "LowerCore2", s = "Block", z = Vector3.new(1.222722, 0.555783, 2.117816), cf = CFrame.new(0, 0.277891, 0.013611, 0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, 0.5), c = Color3.fromRGB(30, 19, 52), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.07451, 0.203922), TintRole = "Shell" } }, -- 16
		{ n = "LowerCore3", s = "Block", z = Vector3.new(1.222722, 0.555783, 2.117816), cf = CFrame.new(0, 0.277891, 0.013611, -0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, -0.5), c = Color3.fromRGB(30, 19, 52), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.07451, 0.203922), TintRole = "Shell" } }, -- 17
		{ n = "PodCore", s = "Block", z = Vector3.new(1.556191, 0.94483, 2.695402), cf = CFrame.new(0, 1.028198, 0.013611, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 30, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.117647, 0.305882), TintRole = "Shell" } }, -- 18
		{ n = "CrossCore1", s = "Block", z = Vector3.new(1.556191, 0.94483, 2.695402), cf = CFrame.new(0, 1.028198, 0.013611, 0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, 0.5), c = Color3.fromRGB(48, 30, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.117647, 0.305882), TintRole = "Shell" } }, -- 19
		{ n = "CrossCore2", s = "Block", z = Vector3.new(1.556191, 0.94483, 2.695402), cf = CFrame.new(0, 1.028198, 0.013611, -0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, -0.5), c = Color3.fromRGB(48, 30, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.117647, 0.305882), TintRole = "Shell" } }, -- 20
		{ n = "NeckCore1", s = "Block", z = Vector3.new(1.167143, 0.611361, 2.021552), cf = CFrame.new(0, 1.806293, 0.013611, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 30, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.117647, 0.305882), TintRole = "Shell" } }, -- 21
		{ n = "NeckCore2", s = "Block", z = Vector3.new(1.167143, 0.611361, 2.021552), cf = CFrame.new(0, 1.806293, 0.013611, 0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, 0.5), c = Color3.fromRGB(48, 30, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.117647, 0.305882), TintRole = "Shell" } }, -- 22
		{ n = "NeckCore3", s = "Block", z = Vector3.new(1.167143, 0.611361, 2.021552), cf = CFrame.new(0, 1.806293, 0.013611, -0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, -0.5), c = Color3.fromRGB(48, 30, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.117647, 0.305882), TintRole = "Shell" } }, -- 23
		{ n = "PetalSepal1", s = "Block", z = Vector3.new(1.167143, 1.722926, 0.194524), cf = CFrame.new(1.191272, 1.194933, 0.701385, 0.5, -0.135476, 0.855363, 0, 0.987688, 0.156434, -0.866025, -0.078217, 0.493844), c = Color3.fromRGB(64, 41, 104), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.25098, 0.160784, 0.407843), TintRole = "Plate" } }, -- 24
		{ n = "PetalSepal2", s = "Block", z = Vector3.new(1.167143, 1.445035, 0.194524), cf = CFrame.new(0, 1.083776, 1.38916, 1, 0, 0, 0, 0.987688, 0.156434, 0, -0.156434, 0.987688), c = Color3.fromRGB(52, 33, 87), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.203922, 0.129412, 0.341176), TintRole = "Plate" } }, -- 25
		{ n = "PetalSepal3", s = "Block", z = Vector3.new(1.167143, 1.722926, 0.194524), cf = CFrame.new(-1.191272, 1.194933, 0.701385, 0.5, 0.135476, -0.855363, 0, 0.987688, 0.156434, 0.866025, -0.078217, 0.493844), c = Color3.fromRGB(64, 41, 104), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.25098, 0.160784, 0.407843), TintRole = "Plate" } }, -- 26
		{ n = "PetalSepal4", s = "Block", z = Vector3.new(1.167143, 1.445035, 0.194524), cf = CFrame.new(-1.191272, 1.083776, -0.674164, -0.5, 0.135476, -0.855363, 0, 0.987688, 0.156434, 0.866025, 0.078217, -0.493844), c = Color3.fromRGB(52, 33, 87), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.203922, 0.129412, 0.341176), TintRole = "Plate" } }, -- 27
		{ n = "PetalSepal5", s = "Block", z = Vector3.new(1.167143, 1.722926, 0.194524), cf = CFrame.new(0, 1.194933, -1.361938, -1, 0, 0, 0, 0.987688, 0.156434, 0, 0.156434, -0.987688), c = Color3.fromRGB(64, 41, 104), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.25098, 0.160784, 0.407843), TintRole = "Plate" } }, -- 28
		{ n = "PetalSepal6", s = "Block", z = Vector3.new(1.167143, 1.445035, 0.194524), cf = CFrame.new(1.191272, 1.083776, -0.674164, -0.5, -0.135476, 0.855363, 0, 0.987688, 0.156434, -0.866025, 0.078217, -0.493844), c = Color3.fromRGB(52, 33, 87), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.203922, 0.129412, 0.341176), TintRole = "Plate" } }, -- 29
		{ n = "UpperMantle", s = "Block", z = Vector3.new(1.445035, 0.250102, 2.502873), cf = CFrame.new(0, 2.237025, 0.013611, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(30, 19, 52), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.07451, 0.203922), TintRole = "Shell" } }, -- 30
		{ n = "HoodRing1", s = "Block", z = Vector3.new(1.445035, 0.250102, 2.502873), cf = CFrame.new(0, 2.237025, 0.013611, 0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, 0.5), c = Color3.fromRGB(30, 19, 52), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.07451, 0.203922), TintRole = "Shell" } }, -- 31
		{ n = "HoodRing2", s = "Block", z = Vector3.new(1.445035, 0.250102, 2.502873), cf = CFrame.new(0, 2.237025, 0.013611, -0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, -0.5), c = Color3.fromRGB(30, 19, 52), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.117647, 0.07451, 0.203922), TintRole = "Shell" } }, -- 32
		{ n = "HoodPetal1", s = "Block", z = Vector3.new(0.833674, 1.000409, 0.166735), cf = CFrame.new(0.672275, 2.776764, 0.401764, 0.5, -0.484275, 0.717968, 0, 0.829038, 0.559193, -0.866025, -0.279596, 0.414519), c = Color3.fromRGB(214, 140, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.839216, 0.54902, 1), TintRole = "Halo" } }, -- 33
		{ n = "HoodVein1", s = "Block", z = Vector3.new(0.138946, 0.800327, 0.083367), cf = CFrame.new(0.752082, 2.838922, 0.447815, 0.5, -0.484275, 0.717968, 0, 0.829038, 0.559193, -0.866025, -0.279596, 0.414519), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 34
		{ n = "HoodPetal2", s = "Block", z = Vector3.new(0.833674, 1.000409, 0.166735), cf = CFrame.new(0, 2.776764, 0.789886, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c = Color3.fromRGB(178, 106, 226), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.698039, 0.415686, 0.886275), TintRole = "Halo" } }, -- 35
		{ n = "HoodVein2", s = "Block", z = Vector3.new(0.138946, 0.800327, 0.083367), cf = CFrame.new(0, 2.838922, 0.88205, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 36
		{ n = "HoodPetal3", s = "Block", z = Vector3.new(0.833674, 1.000409, 0.166735), cf = CFrame.new(-0.672275, 2.776764, 0.401764, 0.5, 0.484275, -0.717968, 0, 0.829038, 0.559193, 0.866025, -0.279596, 0.414519), c = Color3.fromRGB(214, 140, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.839216, 0.54902, 1), TintRole = "Halo" } }, -- 37
		{ n = "HoodVein3", s = "Block", z = Vector3.new(0.138946, 0.800327, 0.083367), cf = CFrame.new(-0.752082, 2.838922, 0.447815, 0.5, 0.484275, -0.717968, 0, 0.829038, 0.559193, 0.866025, -0.279596, 0.414519), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 38
		{ n = "HoodPetal4", s = "Block", z = Vector3.new(0.833674, 1.000409, 0.166735), cf = CFrame.new(-0.672275, 2.776764, -0.374542, -0.5, 0.484275, -0.717968, 0, 0.829038, 0.559193, 0.866025, 0.279596, -0.414519), c = Color3.fromRGB(178, 106, 226), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.698039, 0.415686, 0.886275), TintRole = "Halo" } }, -- 39
		{ n = "HoodVein4", s = "Block", z = Vector3.new(0.138946, 0.800327, 0.083367), cf = CFrame.new(-0.752082, 2.838922, -0.420593, -0.5, 0.484275, -0.717968, 0, 0.829038, 0.559193, 0.866025, 0.279596, -0.414519), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 40
		{ n = "HoodPetal5", s = "Block", z = Vector3.new(0.833674, 1.000409, 0.166735), cf = CFrame.new(0, 2.776764, -0.762665, -1, 0, 0, 0, 0.829038, 0.559193, 0, 0.559193, -0.829038), c = Color3.fromRGB(214, 140, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.839216, 0.54902, 1), TintRole = "Halo" } }, -- 41
		{ n = "HoodVein5", s = "Block", z = Vector3.new(0.138946, 0.800327, 0.083367), cf = CFrame.new(0, 2.838922, -0.854828, -1, 0, 0, 0, 0.829038, 0.559193, 0, 0.559193, -0.829038), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 42
		{ n = "HoodPetal6", s = "Block", z = Vector3.new(0.833674, 1.000409, 0.166735), cf = CFrame.new(0.672275, 2.776764, -0.374542, -0.5, -0.484275, 0.717968, 0, 0.829038, 0.559193, -0.866025, 0.279596, -0.414519), c = Color3.fromRGB(178, 106, 226), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.698039, 0.415686, 0.886275), TintRole = "Halo" } }, -- 43
		{ n = "HoodVein6", s = "Block", z = Vector3.new(0.138946, 0.800327, 0.083367), cf = CFrame.new(0.752082, 2.838922, -0.420593, -0.5, -0.484275, 0.717968, 0, 0.829038, 0.559193, -0.866025, 0.279596, -0.414519), c = Color3.fromRGB(255, 140, 180), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(1, 0.54902, 0.705882), TintRole = "Gem" } }, -- 44
		{ n = "EarPetalL", s = "Wedge", z = Vector3.new(0.555783, 1.000409, 0.194524), cf = CFrame.new(-0.861463, 2.834491, 0.402649, 0.97437, -0.224951, 0, 0.222762, 0.964888, -0.139173, 0.031307, 0.135606, 0.990268), c = Color3.fromRGB(48, 30, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.117647, 0.305882), TintRole = "Shell" } }, -- 45
		{ n = "EarPetalR", s = "Wedge", z = Vector3.new(0.555783, 1.000409, 0.194524), cf = CFrame.new(0.861463, 2.834491, 0.402649, 0.97437, 0.224951, 0, -0.222762, 0.964888, -0.139173, -0.031307, 0.135606, 0.990268), c = Color3.fromRGB(48, 30, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.188235, 0.117647, 0.305882), TintRole = "Shell" } }, -- 46
		{ n = "PantherFangL_1", s = "Block", z = Vector3.new(0.208418, 0.208418, 0.585113), cf = CFrame.new(-0.917041, 2.014712, -1.306366, 0.877896, -0.344775, 0.332309, 0, 0.693971, 0.720003, -0.478852, -0.632088, 0.609234), c = Color3.fromRGB(238, 224, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.933333, 0.878431, 1), TintRole = "Tusk" } }, -- 47
		{ n = "PantherFangL_2", s = "Block", z = Vector3.new(0.166735, 0.166735, 0.508459), cf = CFrame.new(-1.000409, 1.625664, -1.500885, 1, 0, 0, 0, 0.196117, 0.980581, 0, -0.980581, 0.196117), c = Color3.fromRGB(238, 224, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.933333, 0.878431, 1), TintRole = "Tusk" } }, -- 48
		{ n = "PantherFangL_3", s = "Block", z = Vector3.new(0.111157, 0.111157, 0.633564), cf = CFrame.new(-0.861463, 1.194933, -1.459198, -0.514495, 0.692959, -0.505076, 0, 0.589015, 0.808122, 0.857493, 0.415775, -0.303046), c = Color3.fromRGB(238, 224, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.933333, 0.878431, 1), TintRole = "Tusk" } }, -- 49
		{ n = "PantherFangR_1", s = "Block", z = Vector3.new(0.208418, 0.208418, 0.585113), cf = CFrame.new(0.917041, 2.014712, -1.306366, 0.877896, 0.344775, -0.332309, 0, 0.693971, 0.720003, 0.478852, -0.632088, 0.609234), c = Color3.fromRGB(238, 224, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.933333, 0.878431, 1), TintRole = "Tusk" } }, -- 50
		{ n = "PantherFangR_2", s = "Block", z = Vector3.new(0.166735, 0.166735, 0.508459), cf = CFrame.new(1.000409, 1.625664, -1.500885, 1, 0, 0, 0, 0.196117, 0.980581, 0, -0.980581, 0.196117), c = Color3.fromRGB(238, 224, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.933333, 0.878431, 1), TintRole = "Tusk" } }, -- 51
		{ n = "PantherFangR_3", s = "Block", z = Vector3.new(0.111157, 0.111157, 0.633564), cf = CFrame.new(0.861463, 1.194933, -1.459198, -0.514495, -0.692959, 0.505076, 0, 0.589015, 0.808122, -0.857493, 0.415775, -0.303046), c = Color3.fromRGB(238, 224, 255), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.933333, 0.878431, 1), TintRole = "Tusk" } }, -- 52
		{ n = "TendrilRoot", s = "Block", z = Vector3.new(0.250102, 0.555783, 0.250102), cf = CFrame.new(0, 3.029015, 0.013611, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(178, 106, 226), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.698039, 0.415686, 0.886275), TintRole = "Halo" } }, -- 53
		{ n = "TendrilCurl", s = "Block", z = Vector3.new(0.194524, 0.194524, 0.555783), cf = CFrame.new(0, 3.34859, -0.180908, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c = Color3.fromRGB(178, 106, 226), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.698039, 0.415686, 0.886275), TintRole = "Halo" } }, -- 54
	},
	Joints = {
		{ k = "Motor6D", n = "LidHinge", h = 18, a = 18, b = 30, c0 = CFrame.new(0, 1.083776, 1.251437, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.125051, 1.251437, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 31, c0 = CFrame.new(0, 0, 0, 0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, 0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 32, c0 = CFrame.new(0, 0, 0, -0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 33, c0 = CFrame.new(0.672275, 0.539739, 0.388138, 0.5, -0.484275, 0.717968, 0, 0.829038, 0.559193, -0.866025, -0.279596, 0.414519), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 34, c0 = CFrame.new(0.752082, 0.601897, 0.434215, 0.5, -0.484275, 0.717968, 0, 0.829038, 0.559193, -0.866025, -0.279596, 0.414519), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 35, c0 = CFrame.new(0, 0.539739, 0.776276, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 36, c0 = CFrame.new(0, 0.601897, 0.868429, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 37, c0 = CFrame.new(-0.672275, 0.539739, 0.388138, 0.5, 0.484275, -0.717968, 0, 0.829038, 0.559193, 0.866025, -0.279596, 0.414519), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 38, c0 = CFrame.new(-0.752082, 0.601897, 0.434215, 0.5, 0.484275, -0.717968, 0, 0.829038, 0.559193, 0.866025, -0.279596, 0.414519), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 39, c0 = CFrame.new(-0.672275, 0.539739, -0.388138, -0.5, 0.484275, -0.717968, 0, 0.829038, 0.559193, 0.866025, 0.279596, -0.414519), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 40, c0 = CFrame.new(-0.752082, 0.601897, -0.434215, -0.5, 0.484275, -0.717968, 0, 0.829038, 0.559193, 0.866025, 0.279596, -0.414519), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 41, c0 = CFrame.new(0, 0.539739, -0.776276, -1, 0, 0, 0, 0.829038, 0.559193, 0, 0.559193, -0.829038), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 42, c0 = CFrame.new(0, 0.601897, -0.868429, -1, 0, 0, 0, 0.829038, 0.559193, 0, 0.559193, -0.829038), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 43, c0 = CFrame.new(0.672275, 0.539739, -0.388138, -0.5, -0.484275, 0.717968, 0, 0.829038, 0.559193, -0.866025, 0.279596, -0.414519), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 44, c0 = CFrame.new(0.752082, 0.601897, -0.434215, -0.5, -0.484275, 0.717968, 0, 0.829038, 0.559193, -0.866025, 0.279596, -0.414519), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 45, c0 = CFrame.new(-0.861463, 0.597466, 0.389048, 0.97437, -0.224951, 0, 0.222762, 0.964888, -0.139173, 0.031307, 0.135606, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 46, c0 = CFrame.new(0.861463, 0.597466, 0.389048, 0.97437, 0.224951, 0, -0.222762, 0.964888, -0.139173, -0.031307, 0.135606, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 47, c0 = CFrame.new(-0.917041, -0.222313, -1.319983, 0.877896, -0.344775, 0.332309, 0, 0.693971, 0.720003, -0.478852, -0.632088, 0.609234), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 48, c0 = CFrame.new(-1.000409, -0.611361, -1.514507, 1, 0, 0, 0, 0.196117, 0.980581, 0, -0.980581, 0.196117), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 49, c0 = CFrame.new(-0.861463, -1.042092, -1.472824, -0.514495, 0.692959, -0.505076, 0, 0.589015, 0.808122, 0.857493, 0.415775, -0.303046), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 50, c0 = CFrame.new(0.917041, -0.222313, -1.319983, 0.877896, 0.344775, -0.332309, 0, 0.693971, 0.720003, 0.478852, -0.632088, 0.609234), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 51, c0 = CFrame.new(1.000409, -0.611361, -1.514507, 1, 0, 0, 0, 0.196117, 0.980581, 0, -0.980581, 0.196117), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 52, c0 = CFrame.new(0.861463, -1.042092, -1.472824, -0.514495, -0.692959, 0.505076, 0, 0.589015, 0.808122, -0.857493, 0.415775, -0.303046), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 13, c0 = CFrame.new(0, -0.055578, -1.264405, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 53, c0 = CFrame.new(0, 0.79199, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 54, c0 = CFrame.new(0, 1.111565, -0.194524, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 14, c0 = CFrame.new(0, 1.055987, -0.444626, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
