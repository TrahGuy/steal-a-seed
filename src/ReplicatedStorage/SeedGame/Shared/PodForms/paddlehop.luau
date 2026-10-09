--!strict
--==============================================================================
-- POD FORM: Paddlehop (dustbowl pods/PaddlehopPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "dustbowl pods/PaddlehopPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "dustbowl pods/PaddlehopPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(3.380005, 4.633438, 1.840027), Height = 4.633438, PartCount = 34,
	Base = 0, Root = 1,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Uncommon", Style = "CactusPad", TextureStyle = "Studded", UnitType = "PaddlehopPod" },
	Removed = { "FlatBase" },
	Parts = {
		{ n = "PadCore", s = "Block", z = Vector3.new(3, 3.2, 1.45), cf = CFrame.new(0.000004, 1.740003, 0, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(168, 180, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 1
		{ n = "PadFrontFace", s = "Block", z = Vector3.new(2.6, 2.8, 0.35), cf = CFrame.new(0, 1.740003, -0.649994, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(168, 180, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "PadBackFace", s = "Block", z = Vector3.new(2.6, 2.8, 0.35), cf = CFrame.new(0, 1.740003, 0.649994, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(168, 180, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "RimLeft", s = "Block", z = Vector3.new(0.42, 2.9, 1.48), cf = CFrame.new(1.480001, 1.740003, 0, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(122, 134, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 4
		{ n = "RimRight", s = "Block", z = Vector3.new(0.42, 2.9, 1.48), cf = CFrame.new(-1.480001, 1.740003, 0, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(122, 134, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 5
		{ n = "RimTop", s = "Block", z = Vector3.new(2.7, 0.42, 1.48), cf = CFrame.new(0.000004, 3.290004, 0, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(122, 134, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "RimBottom", s = "Block", z = Vector3.new(2.4, 0.38, 1.42), cf = CFrame.new(0.000004, 0.19, 0, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(122, 134, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "SpineDotF_1", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(0.720005, 2.590004, -0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 8
		{ n = "SpineDotB_1", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(0.720005, 2.590004, 0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 9
		{ n = "SpineDotF_2", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(0.000004, 2.590004, -0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 10
		{ n = "SpineDotB_2", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(0.000004, 2.590004, 0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 11
		{ n = "SpineDotF_3", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(-0.719997, 2.590004, -0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 12
		{ n = "SpineDotB_3", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(-0.719994, 2.590004, 0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 13
		{ n = "SpineDotF_4", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(1.050003, 1.740003, -0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 14
		{ n = "SpineDotB_4", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(1.050003, 1.740003, 0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 15
		{ n = "SpineDotF_5", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(0.350002, 1.740003, -0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 16
		{ n = "SpineDotB_5", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(0.350006, 1.740003, 0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 17
		{ n = "SpineDotF_6", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(-0.349995, 1.740003, -0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 18
		{ n = "SpineDotB_6", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(-0.349995, 1.740003, 0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 19
		{ n = "SpineDotF_7", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(-1.049999, 1.740003, -0.849976, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 20
		{ n = "SpineDotB_7", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(-1.049995, 1.740003, 0.849976, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 21
		{ n = "SpineDotF_8", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(0.720005, 0.890001, -0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 22
		{ n = "SpineDotB_8", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(0.720005, 0.890001, 0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 23
		{ n = "SpineDotF_9", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(0.000004, 0.890001, -0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 24
		{ n = "SpineDotB_9", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(0.000004, 0.890001, 0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 25
		{ n = "SpineDotF_10", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(-0.719997, 0.890001, -0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 26
		{ n = "SpineDotB_10", s = "Block", z = Vector3.new(0.28, 0.28, 0.14), cf = CFrame.new(-0.719994, 0.890001, 0.850006, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(246, 242, 214), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 27
		{ n = "BloomHinge", s = "Block", z = Vector3.new(0.3, 0.3, 0.3), cf = CFrame.new(0.000004, 3.490005, 0, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(122, 134, 68), m = Enum.Material.Plastic, t = 1, st = false }, -- 28
		{ n = "SepalCollar", s = "Block", z = Vector3.new(0.95, 0.28, 0.95), cf = CFrame.new(0.000004, 3.610005, 0, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(122, 134, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 29
		{ n = "BloomBulb", s = "Block", z = Vector3.new(0.92, 0.85, 0.92), cf = CFrame.new(0.000004, 4.010006, 0, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(228, 92, 66), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 30
		{ n = "BloomPetal1", s = "Wedge", z = Vector3.new(0.38, 0.45, 0.32), cf = CFrame.new(0.000004, 4.370007, -0.220001, -1.000001, 0, 0, 0, -0.951058, 0.309018, 0, 0.309017, 0.951057), c = Color3.fromRGB(228, 92, 66), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "BloomPetal2", s = "Wedge", z = Vector3.new(0.38, 0.45, 0.32), cf = CFrame.new(-0.220001, 4.370007, 0, 0, 0.309017, 0.951057, 0, -0.951058, 0.309018, 1.000001, 0, 0), c = Color3.fromRGB(228, 92, 66), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "BloomPetal3", s = "Wedge", z = Vector3.new(0.38, 0.45, 0.32), cf = CFrame.new(0.000004, 4.370007, 0.220001, 1.000001, 0, 0, 0, -0.951058, 0.309018, 0, -0.309017, -0.951057), c = Color3.fromRGB(228, 92, 66), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
		{ n = "BloomPetal4", s = "Wedge", z = Vector3.new(0.38, 0.45, 0.32), cf = CFrame.new(0.220001, 4.370007, 0, 0, -0.309017, -0.951057, 0, -0.951058, 0.309018, -1.000001, 0, 0), c = Color3.fromRGB(228, 92, 66), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 34
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0.000004, 0, 0.649994, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0.000004, 0, -0.650024, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 4, c0 = CFrame.new(-1.48, 0, 0, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 5, c0 = CFrame.new(1.480005, 0, 0, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 6, c0 = CFrame.new(0, 1.550004, 0, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 7, c0 = CFrame.new(0, -1.550004, 0, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Motor6D", n = "BloomJoint", h = 1, a = 1, b = 28, c0 = CFrame.new(0, 1.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 8, c0 = CFrame.new(-0.720007, 0.850003, 0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 10, c0 = CFrame.new(-0.000004, 0.850003, 0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 12, c0 = CFrame.new(0.719997, 0.850003, 0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 14, c0 = CFrame.new(-1.050005, 0, 0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 16, c0 = CFrame.new(-0.350004, 0, 0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 18, c0 = CFrame.new(0.349995, 0, 0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 20, c0 = CFrame.new(1.049999, 0, 0.199982, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 22, c0 = CFrame.new(-0.720007, -0.850002, 0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 24, c0 = CFrame.new(-0.000004, -0.850002, 0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 26, c0 = CFrame.new(0.719997, -0.850002, 0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 9, c0 = CFrame.new(-0.720007, 0.850003, -0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 11, c0 = CFrame.new(-0.000004, 0.850003, -0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 13, c0 = CFrame.new(0.719994, 0.850003, -0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 15, c0 = CFrame.new(-1.050005, 0, -0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 17, c0 = CFrame.new(-0.350008, 0, -0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 19, c0 = CFrame.new(0.349995, 0, -0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 21, c0 = CFrame.new(1.049995, 0, -0.199982, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 23, c0 = CFrame.new(-0.720007, -0.850002, -0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 25, c0 = CFrame.new(-0.000004, -0.850002, -0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 27, c0 = CFrame.new(0.719994, -0.850002, -0.200012, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 29, c0 = CFrame.new(0, 0.12, 0, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 30, c0 = CFrame.new(0, 0.520002, 0, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 30, a = 30, b = 31, c0 = CFrame.new(0, 0.360001, 0.220001, 1.000001, 0, 0, 0, -0.951059, 0.309018, 0, -0.309018, -0.951058), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 30, a = 30, b = 32, c0 = CFrame.new(0.220005, 0.360001, 0, 0, -0.309018, -0.951058, 0, -0.951059, 0.309018, -1.000001, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 30, a = 30, b = 33, c0 = CFrame.new(0, 0.360001, -0.220001, -1.000001, 0, 0, 0, -0.951059, 0.309018, 0, 0.309018, 0.951058), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 30, a = 30, b = 34, c0 = CFrame.new(-0.219997, 0.360001, 0, 0, 0.309018, 0.951058, 0, -0.951059, 0.309018, 1.000001, 0, 0), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StudioFillLight", p = 1, range = 12, brightness = 0.85, color = Color3.new(1, 0.988235, 0.941176), shadows = true, enabled = true },
	},
	Emitters = {},
	Textures = {
		{ n = "Studs_%s", p = 1, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 2, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 3, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 4, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 5, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 6, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 7, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 8, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 9, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 10, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 11, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 12, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 13, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 14, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 15, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 16, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 17, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 18, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 19, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 20, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 21, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 22, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 23, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 24, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 25, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 26, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 27, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 29, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 30, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 31, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 32, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 33, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 34, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
