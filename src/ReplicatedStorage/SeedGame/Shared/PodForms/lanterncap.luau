--!strict
--==============================================================================
-- POD FORM: Lanterncap (tanglemire pods/LanterncapPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "tanglemire pods/LanterncapPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "tanglemire pods/LanterncapPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(3.385143, 4.390006, 3.421967), Height = 4.390006, PartCount = 52,
	Base = 0, Root = 7,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Legendary", Style = "LanternPlant", TextureStyle = "Studded", UnitType = "LanterncapPod" },
	Removed = { "FlatBase", "PlinthBase" },
	Parts = {
		{ n = "LimeMossCushion1", s = "Block", z = Vector3.new(0.95, 0.32, 0.75), cf = CFrame.new(-0.323525, 0.16, -1.207428, -0.965927, 0, -0.258819, 0, 1.000002, 0, 0.258819, 0, -0.965925), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 1
		{ n = "LimeMossCushion2", s = "Block", z = Vector3.new(0.95, 0.32, 0.75), cf = CFrame.new(-1.20741, 0.16, -0.323547, -0.258819, 0, -0.965927, 0, 1.000002, 0, 0.965925, 0, -0.258819), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 2
		{ n = "LimeMossCushion3", s = "Block", z = Vector3.new(0.95, 0.32, 0.75), cf = CFrame.new(-0.883883, 0.16, 0.88385, 0.707108, 0, -0.707108, 0, 1.000002, 0, 0.707106, 0, 0.707107), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 3
		{ n = "LimeMossCushion4", s = "Block", z = Vector3.new(0.95, 0.32, 0.75), cf = CFrame.new(0.323527, 0.16, 1.207367, 0.965927, 0, 0.25882, 0, 1.000002, 0, -0.258819, 0, 0.965925), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 4
		{ n = "LimeMossCushion5", s = "Block", z = Vector3.new(0.95, 0.32, 0.75), cf = CFrame.new(1.20741, 0.16, 0.323486, 0.258819, 0, 0.965927, 0, 1.000002, 0, -0.965925, 0, 0.258819), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 5
		{ n = "LimeMossCushion6", s = "Block", z = Vector3.new(0.95, 0.32, 0.75), cf = CFrame.new(0.883884, 0.16, -0.883911, -0.707108, 0, 0.707108, 0, 1.000002, 0, -0.707107, 0, -0.707106), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 6
		{ n = "LanternCore", s = "Block", z = Vector3.new(2.1, 2.2, 2.1), cf = CFrame.new(-0.000001, 1.330002, -0.000031, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1), c = Color3.fromRGB(238, 188, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 7
		{ n = "FlameHeart", s = "Block", z = Vector3.new(1.2, 1.4, 1.2), cf = CFrame.new(-0.000001, 1.330002, -0.000031, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1), c = Color3.fromRGB(238, 188, 78), m = Enum.Material.Neon, st = false, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 8
		{ n = "BonePillar1", s = "Block", z = Vector3.new(0.32, 2.35, 0.32), cf = CFrame.new(-0.000001, 1.330002, -1.280029, -1.000002, 0, 0, 0, 1.000002, 0, 0, 0, -1), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "MossFoot1", s = "Block", z = Vector3.new(0.38, 0.36, 0.38), cf = CFrame.new(-0.000001, 0.28, -1.330048, -1.000002, 0, 0, 0, 1.000002, 0, 0, 0, -1), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "AmberPanel1", s = "Block", z = Vector3.new(0.98, 1.95, 0.22), cf = CFrame.new(-0.5888, 1.330002, -1.019867, -0.866027, 0, -0.500001, 0, 1.000002, 0, 0.5, 0, -0.866025), c = Color3.fromRGB(238, 188, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "BoneTopSill1", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(-0.608801, 2.380003, -1.054504, -0.866027, 0, -0.500001, 0, 1.000002, 0, 0.5, 0, -0.866025), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "BoneBotSill1", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(-0.608801, 0.28, -1.054504, -0.866027, 0, -0.500001, 0, 1.000002, 0, 0.5, 0, -0.866025), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "BonePillar2", s = "Block", z = Vector3.new(0.32, 2.35, 0.32), cf = CFrame.new(-1.108514, 1.330002, -0.640045, -0.500001, 0, -0.866027, 0, 1.000002, 0, 0.866025, 0, -0.5), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "MossFoot2", s = "Block", z = Vector3.new(0.38, 0.36, 0.38), cf = CFrame.new(-1.151819, 0.28, -0.665039, -0.500001, 0, -0.866027, 0, 1.000002, 0, 0.866025, 0, -0.5), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "AmberPanel2", s = "Block", z = Vector3.new(0.98, 1.95, 0.22), cf = CFrame.new(-1.177602, 1.330002, -0.000031, 0, 0, -1.000002, 0, 1.000002, 0, 1, 0, 0), c = Color3.fromRGB(238, 188, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "BoneTopSill2", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(-1.217603, 2.380003, -0.000031, 0, 0, -1.000002, 0, 1.000002, 0, 1, 0, 0), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "BoneBotSill2", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(-1.217603, 0.28, -0.000031, 0, 0, -1.000002, 0, 1.000002, 0, 1, 0, 0), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "BonePillar3", s = "Block", z = Vector3.new(0.32, 2.35, 0.32), cf = CFrame.new(-1.108516, 1.330002, 0.639954, 0.500001, 0, -0.866027, 0, 1.000002, 0, 0.866025, 0, 0.5), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "MossFoot3", s = "Block", z = Vector3.new(0.38, 0.36, 0.38), cf = CFrame.new(-1.15182, 0.28, 0.664978, 0.500001, 0, -0.866027, 0, 1.000002, 0, 0.866025, 0, 0.5), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "AmberPanel3", s = "Block", z = Vector3.new(0.98, 1.95, 0.22), cf = CFrame.new(-0.5888, 1.330002, 1.019806, 0.866027, 0, -0.500001, 0, 1.000002, 0, 0.5, 0, 0.866025), c = Color3.fromRGB(238, 188, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "BoneTopSill3", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(-0.608801, 2.380003, 1.054443, 0.866027, 0, -0.500001, 0, 1.000002, 0, 0.5, 0, 0.866025), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "BoneBotSill3", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(-0.608801, 0.28, 1.054443, 0.866027, 0, -0.500001, 0, 1.000002, 0, 0.5, 0, 0.866025), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "BonePillar4", s = "Block", z = Vector3.new(0.32, 2.35, 0.32), cf = CFrame.new(-0.000001, 1.330002, 1.279968, 1.000002, 0, 0, 0, 1.000002, 0, 0, 0, 1), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "MossFoot4", s = "Block", z = Vector3.new(0.38, 0.36, 0.38), cf = CFrame.new(-0.000001, 0.28, 1.329956, 1.000002, 0, 0, 0, 1.000002, 0, 0, 0, 1), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "AmberPanel4", s = "Block", z = Vector3.new(0.98, 1.95, 0.22), cf = CFrame.new(0.588802, 1.330002, 1.019806, 0.866027, 0, 0.500001, 0, 1.000002, 0, -0.5, 0, 0.866025), c = Color3.fromRGB(238, 188, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "BoneTopSill4", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(0.608803, 2.380003, 1.054443, 0.866027, 0, 0.500001, 0, 1.000002, 0, -0.5, 0, 0.866025), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "BoneBotSill4", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(0.608803, 0.28, 1.054443, 0.866027, 0, 0.500001, 0, 1.000002, 0, -0.5, 0, 0.866025), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "BonePillar5", s = "Block", z = Vector3.new(0.32, 2.35, 0.32), cf = CFrame.new(1.108514, 1.330002, 0.639954, 0.500001, 0, 0.866027, 0, 1.000002, 0, -0.866025, 0, 0.5), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "MossFoot5", s = "Block", z = Vector3.new(0.38, 0.36, 0.38), cf = CFrame.new(1.151814, 0.28, 0.664948, 0.500001, 0, 0.866027, 0, 1.000002, 0, -0.866025, 0, 0.5), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "AmberPanel5", s = "Block", z = Vector3.new(0.98, 1.95, 0.22), cf = CFrame.new(1.177602, 1.330002, -0.000031, 0, 0, 1.000002, 0, 1.000002, 0, -1, 0, 0), c = Color3.fromRGB(238, 188, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "BoneTopSill5", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(1.217607, 2.380003, -0.000031, 0, 0, 1.000002, 0, 1.000002, 0, -1, 0, 0), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "BoneBotSill5", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(1.217607, 0.28, -0.000031, 0, 0, 1.000002, 0, 1.000002, 0, -1, 0, 0), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
		{ n = "BonePillar6", s = "Block", z = Vector3.new(0.32, 2.35, 0.32), cf = CFrame.new(1.108514, 1.330002, -0.640015, -0.500001, 0, 0.866027, 0, 1.000002, 0, -0.866025, 0, -0.5), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 34
		{ n = "MossFoot6", s = "Block", z = Vector3.new(0.38, 0.36, 0.38), cf = CFrame.new(1.151814, 0.28, -0.665009, -0.500001, 0, 0.866027, 0, 1.000002, 0, -0.866025, 0, -0.5), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 35
		{ n = "AmberPanel6", s = "Block", z = Vector3.new(0.98, 1.95, 0.22), cf = CFrame.new(0.588802, 1.330002, -1.019867, -0.866027, 0, 0.500001, 0, 1.000002, 0, -0.5, 0, -0.866025), c = Color3.fromRGB(238, 188, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 36
		{ n = "BoneTopSill6", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(0.608799, 2.380003, -1.054504, -0.866027, 0, 0.500001, 0, 1.000002, 0, -0.5, 0, -0.866025), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 37
		{ n = "BoneBotSill6", s = "Block", z = Vector3.new(1.05, 0.22, 0.26), cf = CFrame.new(0.608799, 0.28, -1.054504, -0.866027, 0, 0.500001, 0, 1.000002, 0, -0.5, 0, -0.866025), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 38
		{ n = "RoofPlinth", s = "Block", z = Vector3.new(3.05, 0.32, 3.05), cf = CFrame.new(-0.000001, 2.580004, -0.000031, -1.000002, 0, 0, 0, 1.000002, 0, 0, 0, -1), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 39
		{ n = "RoofDome", s = "Block", z = Vector3.new(2.35, 0.65, 2.35), cf = CFrame.new(-0.000001, 2.930005, -0.000031, -1.000002, 0, 0, 0, 1.000002, 0, 0, 0, -1), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 40
		{ n = "RoofEave1", s = "Wedge", z = Vector3.new(0.65, 0.34, 0.42), cf = CFrame.new(-0.000001, 2.700004, -1.450012, -1.000002, 0, 0, 0, -0.913547, 0.406737, 0, 0.406736, 0.913545), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 41
		{ n = "RoofEave2", s = "Wedge", z = Vector3.new(0.65, 0.34, 0.42), cf = CFrame.new(-1.25574, 2.700004, -0.725037, -0.500001, 0.352245, 0.791155, 0, -0.913547, 0.406737, 0.866025, 0.203368, 0.456773), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 42
		{ n = "RoofEave3", s = "Wedge", z = Vector3.new(0.65, 0.34, 0.42), cf = CFrame.new(-1.25574, 2.700004, 0.724976, 0.500001, 0.352245, 0.791155, 0, -0.913547, 0.406737, 0.866025, -0.203368, -0.456773), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 43
		{ n = "RoofEave4", s = "Wedge", z = Vector3.new(0.65, 0.34, 0.42), cf = CFrame.new(-0.000001, 2.700004, 1.449982, 1.000002, 0, 0, 0, -0.913547, 0.406737, 0, -0.406736, -0.913545), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 44
		{ n = "RoofEave5", s = "Wedge", z = Vector3.new(0.65, 0.34, 0.42), cf = CFrame.new(1.255738, 2.700004, 0.724976, 0.500001, -0.352245, -0.791155, 0, -0.913547, 0.406737, -0.866025, -0.203368, -0.456773), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 45
		{ n = "RoofEave6", s = "Wedge", z = Vector3.new(0.65, 0.34, 0.42), cf = CFrame.new(1.255742, 2.700004, -0.725006, -0.500001, -0.352245, -0.791155, 0, -0.913547, 0.406737, -0.866025, 0.203368, 0.456773), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 46
		{ n = "HandleSocket", s = "Block", z = Vector3.new(0.65, 0.32, 0.65), cf = CFrame.new(-0.000001, 3.300005, -0.000031, -1.000002, 0, 0, 0, 1.000002, 0, 0, 0, -1), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 47
		{ n = "HandleHinge", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(-0.000001, 3.480005, -0.000031, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, t = 1, st = false }, -- 48
		{ n = "HandlePostL", s = "Block", z = Vector3.new(0.18, 0.62, 0.18), cf = CFrame.new(0.420002, 3.800005, -0.000031, -0.970297, -0.241922, 0, -0.241922, 0.970297, 0, 0, 0, -1), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 49
		{ n = "HandlePostR", s = "Block", z = Vector3.new(0.18, 0.62, 0.18), cf = CFrame.new(-0.42, 3.800005, -0.000031, -0.970297, 0.241922, 0, 0.241922, 0.970297, 0, 0, 0, -1), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 50
		{ n = "HandleCrossbar", s = "Block", z = Vector3.new(0.78, 0.18, 0.18), cf = CFrame.new(-0.000001, 4.160006, -0.000031, -1.000002, 0, 0, 0, 1.000002, 0, 0, 0, -1), c = Color3.fromRGB(220, 218, 176), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 51
		{ n = "HandleKnot", s = "Block", z = Vector3.new(0.26, 0.26, 0.26), cf = CFrame.new(-0.000001, 4.260006, -0.000031, -1.000002, 0, 0, 0, 1.000002, 0, 0, 0, -1), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 52
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 8, c0 = CFrame.new(0, 0, 0, 1.000003, 0, 0, 0, 1.000003, 0, 0, 0, 0.999999), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 9, c0 = CFrame.new(0, 0, 1.279999, 1.000003, 0, 0, 0, 1.000003, 0, 0, 0, 0.999999), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 11, c0 = CFrame.new(0.5888, 0, 1.019836, 0.866028, 0, 0.500002, 0, 1.000003, 0, -0.5, 0, 0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 12, c0 = CFrame.new(0.608801, 1.050003, 1.054474, 0.866028, 0, 0.500002, 0, 1.000003, 0, -0.5, 0, 0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 13, c0 = CFrame.new(0.608801, -1.050003, 1.054474, 0.866028, 0, 0.500002, 0, 1.000003, 0, -0.5, 0, 0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 14, c0 = CFrame.new(1.108514, 0, 0.640015, 0.500002, 0, 0.866028, 0, 1.000003, 0, -0.866025, 0, 0.5), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 16, c0 = CFrame.new(1.177602, 0, 0, 0, 0, 1.000003, 0, 1.000003, 0, -0.999999, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 17, c0 = CFrame.new(1.217603, 1.050003, 0, 0, 0, 1.000003, 0, 1.000003, 0, -0.999999, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 18, c0 = CFrame.new(1.217603, -1.050003, 0, 0, 0, 1.000003, 0, 1.000003, 0, -0.999999, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 19, c0 = CFrame.new(1.108516, 0, -0.639984, -0.500002, 0, 0.866028, 0, 1.000003, 0, -0.866025, 0, -0.5), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 21, c0 = CFrame.new(0.5888, 0, -1.019836, -0.866028, 0, 0.500002, 0, 1.000003, 0, -0.5, 0, -0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 22, c0 = CFrame.new(0.608801, 1.050003, -1.054474, -0.866028, 0, 0.500002, 0, 1.000003, 0, -0.5, 0, -0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 23, c0 = CFrame.new(0.608801, -1.050003, -1.054474, -0.866028, 0, 0.500002, 0, 1.000003, 0, -0.5, 0, -0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 24, c0 = CFrame.new(0, 0, -1.279999, -1.000003, 0, 0, 0, 1.000003, 0, 0, 0, -0.999999), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 26, c0 = CFrame.new(-0.588804, 0, -1.019836, -0.866028, 0, -0.500002, 0, 1.000003, 0, 0.5, 0, -0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 27, c0 = CFrame.new(-0.608805, 1.050003, -1.054474, -0.866028, 0, -0.500002, 0, 1.000003, 0, 0.5, 0, -0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 28, c0 = CFrame.new(-0.608805, -1.050003, -1.054474, -0.866028, 0, -0.500002, 0, 1.000003, 0, 0.5, 0, -0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 29, c0 = CFrame.new(-1.108517, 0, -0.639984, -0.500001, 0, -0.866028, 0, 1.000003, 0, 0.866025, 0, -0.5), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 31, c0 = CFrame.new(-1.177605, 0, 0, 0, 0, -1.000003, 0, 1.000003, 0, 0.999999, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 32, c0 = CFrame.new(-1.217609, 1.050003, 0, 0, 0, -1.000003, 0, 1.000003, 0, 0.999999, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 33, c0 = CFrame.new(-1.217609, -1.050003, 0, 0, 0, -1.000003, 0, 1.000003, 0, 0.999999, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 34, c0 = CFrame.new(-1.108517, 0, 0.639984, 0.500001, 0, -0.866028, 0, 1.000003, 0, 0.866025, 0, 0.5), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 36, c0 = CFrame.new(-0.588804, 0, 1.019836, 0.866028, 0, -0.500002, 0, 1.000003, 0, 0.5, 0, 0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 37, c0 = CFrame.new(-0.608801, 1.050003, 1.054474, 0.866028, 0, -0.500002, 0, 1.000003, 0, 0.5, 0, 0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 38, c0 = CFrame.new(-0.608801, -1.050003, 1.054474, 0.866028, 0, -0.500002, 0, 1.000003, 0, 0.5, 0, 0.866025), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 39, c0 = CFrame.new(0, 1.250003, 0, 1.000003, 0, 0, 0, 1.000003, 0, 0, 0, 0.999999), c1 = CFrame.new() },
		{ k = "Motor6D", n = "HandleJoint", h = 7, a = 7, b = 48, c0 = CFrame.new(0, 2.15, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 9, a = 9, b = 10, c0 = CFrame.new(0, -1.050004, 0.050018, 1.000003, 0, 0, 0, 1.000003, 0, 0, 0, 0.999999), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 15, c0 = CFrame.new(0.000015, -1.050004, 0.049988, 1, 0, 0.000002, 0, 1.000003, 0, 0.000002, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 20, c0 = CFrame.new(0.000031, -1.050004, 0.050003, 1, 0, -0.000002, 0, 1.000003, 0, -0.000002, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 24, a = 24, b = 25, c0 = CFrame.new(0, -1.050004, 0.049988, 1.000003, 0, 0, 0, 1.000003, 0, 0, 0, 0.999999), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 30, c0 = CFrame.new(0.000015, -1.050004, 0.050003, 1, 0, 0.000002, 0, 1.000003, 0, 0.000002, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 34, a = 34, b = 35, c0 = CFrame.new(0.000031, -1.050004, 0.050003, 1, 0, -0.000002, 0, 1.000003, 0, -0.000002, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 40, c0 = CFrame.new(0, 0.350001, 0, 1.000003, 0, 0, 0, 1.000003, 0, 0, 0, 0.999999), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 41, c0 = CFrame.new(0, 0.12, 1.449982, 1.000003, 0, 0, 0, -0.913549, 0.406738, 0, -0.406736, -0.913545), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 42, c0 = CFrame.new(1.255741, 0.12, 0.725006, 0.500002, -0.352245, -0.791156, 0, -0.913549, 0.406738, -0.866025, -0.203368, -0.456773), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 43, c0 = CFrame.new(1.255741, 0.12, -0.725006, -0.500002, -0.352245, -0.791156, 0, -0.913549, 0.406738, -0.866025, 0.203368, 0.456773), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 44, c0 = CFrame.new(0, 0.12, -1.450012, -1.000003, 0, 0, 0, -0.913549, 0.406738, 0, 0.406736, 0.913545), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 45, c0 = CFrame.new(-1.255742, 0.12, -0.725006, -0.500002, 0.352245, 0.791156, 0, -0.913549, 0.406738, 0.866025, 0.203368, 0.456772), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 46, c0 = CFrame.new(-1.255746, 0.12, 0.724976, 0.500002, 0.352246, 0.791156, 0, -0.913549, 0.406738, 0.866025, -0.203368, -0.456772), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 40, a = 40, b = 47, c0 = CFrame.new(0, 0.370001, 0, 1.000003, 0, 0, 0, 1.000003, 0, 0, 0, 0.999999), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 48, a = 48, b = 49, c0 = CFrame.new(-0.420004, 0.32, 0, 0.970299, 0.241923, 0, -0.241923, 0.970299, 0, 0, 0, 0.999999), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 48, a = 48, b = 50, c0 = CFrame.new(0.419999, 0.32, 0, 0.970299, -0.241923, 0, 0.241923, 0.970299, 0, 0, 0, 0.999999), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 48, a = 48, b = 51, c0 = CFrame.new(0, 0.680001, 0, 1.000003, 0, 0, 0, 1.000003, 0, 0, 0, 0.999999), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 51, a = 51, b = 52, c0 = CFrame.new(0, 0.1, 0, 1.000003, 0, 0, 0, 1.000003, 0, 0, 0, 0.999999), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StudioFillLight", p = 7, range = 12, brightness = 0.85, color = Color3.new(1, 0.980392, 0.941176), shadows = true, enabled = true },
		{ n = "LanternLight", p = 8, range = 14, brightness = 2.45, color = Color3.new(1, 0.764706, 0.313726), shadows = true, enabled = true },
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
		{ n = "Studs_%s", p = 28, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 29, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 30, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 31, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 32, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 33, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 34, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 35, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 36, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 37, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 38, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 39, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 40, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 41, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 42, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 43, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 44, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 45, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 46, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 47, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 49, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 50, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 51, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 52, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
