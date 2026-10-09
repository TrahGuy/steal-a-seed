--!strict
--==============================================================================
-- POD FORM: Suncrown (dustbowl pods/SuncrownPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "dustbowl pods/SuncrownPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "dustbowl pods/SuncrownPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(5.777265, 6.756146, 5.777283), Height = 6.756146, PartCount = 77,
	Base = 0, Root = 1,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Legendary", Style = "SolarCactusGolem", TextureStyle = "Studded", UnitType = "SuncrownPod" },
	Removed = { "FlatBase" },
	Parts = {
		{ n = "SunCore", s = "Block", z = Vector3.new(4.32461, 4.32461, 4.32461), cf = CFrame.new(0.000002, 2.162305, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 1
		{ n = "SolarHeart", s = "Block", z = Vector3.new(2.511064, 2.511064, 2.511064), cf = CFrame.new(0.000002, 2.162305, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Neon, st = false, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 2
		{ n = "CactusRib1", s = "Block", z = Vector3.new(0.948624, 3.836348, 0.585915), cf = CFrame.new(0.000002, 2.162305, -2.064667, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "RibRidge1", s = "Wedge", z = Vector3.new(0.669617, 3.836348, 0.446411), cf = CFrame.new(0.000003, 2.162305, -2.399475, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "RibSpine1_1", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(0.000002, 3.348086, -2.566895, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "RibSpine1_2", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(0.000002, 2.162305, -2.594788, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "RibSpine1_3", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(0.000002, 0.976524, -2.566895, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "CactusRib2", s = "Block", z = Vector3.new(0.948624, 3.836348, 0.585915), cf = CFrame.new(-1.459927, 2.162305, -1.45993, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "RibRidge2", s = "Wedge", z = Vector3.new(0.669617, 3.836348, 0.446411), cf = CFrame.new(-1.69667, 2.162305, -1.696686, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "RibSpine2_1", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(-1.815042, 3.348086, -1.815033, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "RibSpine2_2", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(-1.834771, 2.162305, -1.834778, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "RibSpine2_3", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(-1.815042, 0.976524, -1.815033, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "CactusRib3", s = "Block", z = Vector3.new(0.948624, 3.836348, 0.585915), cf = CFrame.new(-2.06465, 2.162305, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "RibRidge3", s = "Wedge", z = Vector3.new(0.669617, 3.836348, 0.446411), cf = CFrame.new(-2.39946, 2.162305, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "RibSpine3_1", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(-2.566865, 3.348086, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "RibSpine3_2", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(-2.594764, 2.162305, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "RibSpine3_3", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(-2.566865, 0.976524, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "CactusRib4", s = "Block", z = Vector3.new(0.948624, 3.836348, 0.585915), cf = CFrame.new(-1.459928, 2.162305, 1.45993, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "RibRidge4", s = "Wedge", z = Vector3.new(0.669617, 3.836348, 0.446411), cf = CFrame.new(-1.696668, 2.162305, 1.696686, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "RibSpine4_1", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(-1.815043, 3.348086, 1.815033, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "RibSpine4_2", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(-1.834769, 2.162305, 1.834778, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "RibSpine4_3", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(-1.815043, 0.976524, 1.815033, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "CactusRib5", s = "Block", z = Vector3.new(0.948624, 3.836348, 0.585915), cf = CFrame.new(0.000003, 2.162305, 2.064667, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "RibRidge5", s = "Wedge", z = Vector3.new(0.669617, 3.836348, 0.446411), cf = CFrame.new(0.000001, 2.162305, 2.399475, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "RibSpine5_1", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(0.000001, 3.348086, 2.566864, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "RibSpine5_2", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(0.000001, 2.162305, 2.594788, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "RibSpine5_3", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(0.000001, 0.976524, 2.566864, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "CactusRib6", s = "Block", z = Vector3.new(0.948624, 3.836348, 0.585915), cf = CFrame.new(1.459932, 2.162305, 1.45993, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "RibRidge6", s = "Wedge", z = Vector3.new(0.669617, 3.836348, 0.446411), cf = CFrame.new(1.69668, 2.162305, 1.696686, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "RibSpine6_1", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(1.815053, 3.348086, 1.815063, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "RibSpine6_2", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(1.83478, 2.162305, 1.834778, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "RibSpine6_3", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(1.815053, 0.976524, 1.815063, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "CactusRib7", s = "Block", z = Vector3.new(0.948624, 3.836348, 0.585915), cf = CFrame.new(2.064656, 2.162305, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
		{ n = "RibRidge7", s = "Wedge", z = Vector3.new(0.669617, 3.836348, 0.446411), cf = CFrame.new(2.399466, 2.162305, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 34
		{ n = "RibSpine7_1", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(2.566869, 3.348086, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 35
		{ n = "RibSpine7_2", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(2.594773, 2.162305, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 36
		{ n = "RibSpine7_3", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(2.566869, 0.976524, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 37
		{ n = "CactusRib8", s = "Block", z = Vector3.new(0.948624, 3.836348, 0.585915), cf = CFrame.new(1.459933, 2.162305, -1.45993, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 38
		{ n = "RibRidge8", s = "Wedge", z = Vector3.new(0.669617, 3.836348, 0.446411), cf = CFrame.new(1.696681, 2.162305, -1.696655, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 39
		{ n = "RibSpine8_1", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(1.815052, 3.348086, -1.815033, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 40
		{ n = "RibSpine8_2", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(1.834781, 2.162305, -1.834778, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 41
		{ n = "RibSpine8_3", s = "Block", z = Vector3.new(0.334809, 0.334809, 0.195305), cf = CFrame.new(1.815052, 0.976524, -1.815033, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 42
		{ n = "GoldTrimBand", s = "Block", z = Vector3.new(3.975851, 0.306908, 3.975851), cf = CFrame.new(0.000002, 4.226959, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 43
		{ n = "CrownHub", s = "Block", z = Vector3.new(3.417837, 0.488262, 3.417837), cf = CFrame.new(0.000002, 4.478065, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(255, 198, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 44
		{ n = "SolarApexGem", s = "Block", z = Vector3.new(1.18578, 1.18578, 1.18578), cf = CFrame.new(0.000002, 4.994227, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(255, 222, 90), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 45
		{ n = "SpikeHinge1", s = "Block", z = Vector3.new(0.279007, 0.279007, 0.279007), cf = CFrame.new(0.000002, 4.575716, -1.743805, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, t = 1, st = false }, -- 46
		{ n = "SpikeShaft1", s = "Block", z = Vector3.new(0.585915, 1.325284, 0.530113), cf = CFrame.new(0, 5.161631, -2.078613, -1, 0, 0, 0, 0.829038, 0.559193, 0, 0.559193, -0.829038), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 47
		{ n = "ShaftWedge1", s = "Wedge", z = Vector3.new(0.530113, 1.325284, 0.446411), cf = CFrame.new(0.000002, 5.333253, -2.333038, -1, 0, 0, 0, -0.829038, -0.559193, 0, -0.559193, 0.829038), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 48
		{ n = "RedSpikeTip1", s = "Wedge", z = Vector3.new(0.502213, 1.143929, 0.474312), cf = CFrame.new(0.000002, 6.1724, -1.531464, -1, 0, 0, 0, -0.743145, -0.669131, 0, -0.669131, 0.743145), c = Color3.fromRGB(210, 61, 45), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 49
		{ n = "SpikeHinge2", s = "Block", z = Vector3.new(0.279007, 0.279007, 0.279007), cf = CFrame.new(-1.233047, 4.575716, -1.233063, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, t = 1, st = false }, -- 50
		{ n = "SpikeShaft2", s = "Block", z = Vector3.new(0.585915, 1.325284, 0.530113), cf = CFrame.new(-1.469792, 5.161631, -1.469818, -0.707107, 0.395409, -0.586218, 0, 0.829038, 0.559193, 0.707107, 0.395409, -0.586218), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 51
		{ n = "ShaftWedge2", s = "Wedge", z = Vector3.new(0.530113, 1.325284, 0.446411), cf = CFrame.new(-1.649703, 5.333251, -1.64975, -0.707107, -0.395409, 0.586218, 0, -0.829038, -0.559193, 0.707107, -0.395409, 0.586218), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 52
		{ n = "RedSpikeTip2", s = "Wedge", z = Vector3.new(0.502213, 1.143929, 0.474312), cf = CFrame.new(-1.082897, 6.1724, -1.082916, -0.707107, -0.473147, 0.525483, 0, -0.743145, -0.669131, 0.707107, -0.473147, 0.525483), c = Color3.fromRGB(210, 61, 45), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 53
		{ n = "SpikeHinge3", s = "Block", z = Vector3.new(0.279007, 0.279007, 0.279007), cf = CFrame.new(-1.743793, 4.575716, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, t = 1, st = false }, -- 54
		{ n = "SpikeShaft3", s = "Block", z = Vector3.new(0.585915, 1.325284, 0.530113), cf = CFrame.new(-2.078602, 5.161631, 0, 0, 0.559193, -0.829038, 0, 0.829038, 0.559193, 1, 0, 0), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 55
		{ n = "ShaftWedge3", s = "Wedge", z = Vector3.new(0.530113, 1.325284, 0.446411), cf = CFrame.new(-2.333042, 5.333253, 0, 0, -0.559193, 0.829038, 0, -0.829038, -0.559193, 1, 0, 0), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 56
		{ n = "RedSpikeTip3", s = "Wedge", z = Vector3.new(0.502213, 1.143929, 0.474312), cf = CFrame.new(-1.531447, 6.1724, 0, 0, -0.669131, 0.743145, 0, -0.743145, -0.669131, 1, 0, 0), c = Color3.fromRGB(210, 61, 45), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 57
		{ n = "SpikeHinge4", s = "Block", z = Vector3.new(0.279007, 0.279007, 0.279007), cf = CFrame.new(-1.233047, 4.575716, 1.233063, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, t = 1, st = false }, -- 58
		{ n = "SpikeShaft4", s = "Block", z = Vector3.new(0.585915, 1.325284, 0.530113), cf = CFrame.new(-1.469794, 5.161631, 1.469818, 0.707107, 0.395409, -0.586218, 0, 0.829038, 0.559193, 0.707107, -0.395409, 0.586218), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 59
		{ n = "ShaftWedge4", s = "Wedge", z = Vector3.new(0.530113, 1.325284, 0.446411), cf = CFrame.new(-1.64971, 5.333253, 1.649719, 0.707107, -0.395409, 0.586218, 0, -0.829038, -0.559193, 0.707107, 0.395409, -0.586218), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 60
		{ n = "RedSpikeTip4", s = "Wedge", z = Vector3.new(0.502213, 1.143929, 0.474312), cf = CFrame.new(-1.082898, 6.172399, 1.082916, 0.707107, -0.473147, 0.525483, 0, -0.743145, -0.669131, 0.707107, 0.473147, -0.525483), c = Color3.fromRGB(210, 61, 45), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 61
		{ n = "SpikeHinge5", s = "Block", z = Vector3.new(0.279007, 0.279007, 0.279007), cf = CFrame.new(0.000002, 4.575716, 1.743805, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, t = 1, st = false }, -- 62
		{ n = "SpikeShaft5", s = "Block", z = Vector3.new(0.585915, 1.325284, 0.530113), cf = CFrame.new(0.000004, 5.161631, 2.078613, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 63
		{ n = "ShaftWedge5", s = "Wedge", z = Vector3.new(0.530113, 1.325284, 0.446411), cf = CFrame.new(0.000002, 5.333253, 2.333038, 1, 0, 0, 0, -0.829038, -0.559193, 0, 0.559193, -0.829038), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 64
		{ n = "RedSpikeTip5", s = "Wedge", z = Vector3.new(0.502213, 1.143929, 0.474312), cf = CFrame.new(0.000002, 6.172405, 1.531464, 1, 0, 0, 0, -0.743145, -0.669131, 0, 0.669131, -0.743145), c = Color3.fromRGB(210, 61, 45), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 65
		{ n = "SpikeHinge6", s = "Block", z = Vector3.new(0.279007, 0.279007, 0.279007), cf = CFrame.new(1.23305, 4.575716, 1.233063, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, t = 1, st = false }, -- 66
		{ n = "SpikeShaft6", s = "Block", z = Vector3.new(0.585915, 1.325284, 0.530113), cf = CFrame.new(1.469794, 5.161631, 1.469818, 0.707107, -0.395409, 0.586218, 0, 0.829038, 0.559193, -0.707107, -0.395409, 0.586218), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 67
		{ n = "ShaftWedge6", s = "Wedge", z = Vector3.new(0.530113, 1.325284, 0.446411), cf = CFrame.new(1.649716, 5.333252, 1.649719, 0.707107, 0.395409, -0.586218, 0, -0.829038, -0.559193, -0.707107, 0.395409, -0.586218), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 68
		{ n = "RedSpikeTip6", s = "Wedge", z = Vector3.new(0.502213, 1.143929, 0.474312), cf = CFrame.new(1.0829, 6.172401, 1.082916, 0.707107, 0.473147, -0.525483, 0, -0.743145, -0.669131, -0.707107, 0.473147, -0.525483), c = Color3.fromRGB(210, 61, 45), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 69
		{ n = "SpikeHinge7", s = "Block", z = Vector3.new(0.279007, 0.279007, 0.279007), cf = CFrame.new(1.743796, 4.575716, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, t = 1, st = false }, -- 70
		{ n = "SpikeShaft7", s = "Block", z = Vector3.new(0.585915, 1.325284, 0.530113), cf = CFrame.new(2.078607, 5.161631, 0, 0, -0.559193, 0.829038, 0, 0.829038, 0.559193, -1, 0, 0), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 71
		{ n = "ShaftWedge7", s = "Wedge", z = Vector3.new(0.530113, 1.325284, 0.446411), cf = CFrame.new(2.333042, 5.333251, 0, 0, 0.559193, -0.829038, 0, -0.829038, -0.559193, -1, 0, 0), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 72
		{ n = "RedSpikeTip7", s = "Wedge", z = Vector3.new(0.502213, 1.143929, 0.474312), cf = CFrame.new(1.53145, 6.172399, 0, 0, 0.669131, -0.743145, 0, -0.743145, -0.669131, -1, 0, 0), c = Color3.fromRGB(210, 61, 45), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 73
		{ n = "SpikeHinge8", s = "Block", z = Vector3.new(0.279007, 0.279007, 0.279007), cf = CFrame.new(1.233051, 4.575716, -1.233063, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, t = 1, st = false }, -- 74
		{ n = "SpikeShaft8", s = "Block", z = Vector3.new(0.585915, 1.325284, 0.530113), cf = CFrame.new(1.469798, 5.161631, -1.469818, -0.707107, -0.395409, 0.586218, 0, 0.829038, 0.559193, -0.707107, 0.395409, -0.586218), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 75
		{ n = "ShaftWedge8", s = "Wedge", z = Vector3.new(0.530113, 1.325284, 0.446411), cf = CFrame.new(1.649714, 5.333248, -1.649719, -0.707107, 0.395409, -0.586218, 0, -0.829038, -0.559193, -0.707107, -0.395409, 0.586218), c = Color3.fromRGB(239, 116, 25), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 76
		{ n = "RedSpikeTip8", s = "Wedge", z = Vector3.new(0.502213, 1.143929, 0.474312), cf = CFrame.new(1.082898, 6.172397, -1.082916, -0.707107, 0.473147, -0.525483, 0, -0.743145, -0.669131, -0.707107, -0.473147, 0.525483), c = Color3.fromRGB(210, 61, 45), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 77
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, 0, 2.064667, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 8, c0 = CFrame.new(1.459929, 0, 1.45993, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 13, c0 = CFrame.new(2.064652, 0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 18, c0 = CFrame.new(1.45993, 0, -1.45993, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 23, c0 = CFrame.new(-0.000001, 0, -2.064667, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 28, c0 = CFrame.new(-1.45993, 0, -1.45993, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 33, c0 = CFrame.new(-2.064654, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 38, c0 = CFrame.new(-1.459931, 0, 1.45993, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 43, c0 = CFrame.new(0, 2.064654, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 44, c0 = CFrame.new(0, 2.315761, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "SpikeJoint1", h = 1, a = 1, b = 46, c0 = CFrame.new(0, 2.413411, 1.743794, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SpikeJoint2", h = 1, a = 1, b = 50, c0 = CFrame.new(1.233049, 2.413411, 1.233049, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SpikeJoint3", h = 1, a = 1, b = 54, c0 = CFrame.new(1.743794, 2.413411, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SpikeJoint4", h = 1, a = 1, b = 58, c0 = CFrame.new(1.233049, 2.413411, -1.233049, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SpikeJoint5", h = 1, a = 1, b = 62, c0 = CFrame.new(0, 2.413411, -1.743794, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SpikeJoint6", h = 1, a = 1, b = 66, c0 = CFrame.new(-1.233049, 2.413411, -1.233049, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SpikeJoint7", h = 1, a = 1, b = 70, c0 = CFrame.new(-1.743794, 2.413411, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SpikeJoint8", h = 1, a = 1, b = 74, c0 = CFrame.new(-1.233049, 2.413411, 1.233049, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 4, c0 = CFrame.new(-0.000001, 0, 0.334808, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 5, c0 = CFrame.new(0, 1.185782, 0.502228, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 6, c0 = CFrame.new(0, 0, 0.530121, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 7, c0 = CFrame.new(0, -1.185781, 0.502228, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 9, c0 = CFrame.new(0, 0, 0.334808, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 10, c0 = CFrame.new(0.000015, 1.185782, 0.502182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 11, c0 = CFrame.new(0.000015, 0, 0.530106, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 12, c0 = CFrame.new(0.000015, -1.185781, 0.502182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 14, c0 = CFrame.new(0, 0, 0.33481, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 15, c0 = CFrame.new(0, 1.185782, 0.502215, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 16, c0 = CFrame.new(0, 0, 0.530114, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 17, c0 = CFrame.new(0, -1.185781, 0.502215, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 19, c0 = CFrame.new(0, 0, 0.334808, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 20, c0 = CFrame.new(-0.000015, 1.185782, 0.502182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 21, c0 = CFrame.new(-0.000015, 0, 0.530106, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 22, c0 = CFrame.new(-0.000015, -1.185781, 0.502182, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 24, c0 = CFrame.new(-0.000003, 0, 0.334808, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 25, c0 = CFrame.new(-0.000003, 1.185782, 0.502197, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 26, c0 = CFrame.new(-0.000003, 0, 0.530121, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 27, c0 = CFrame.new(-0.000003, -1.185781, 0.502197, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 29, c0 = CFrame.new(-0.000015, 0, 0.334808, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 30, c0 = CFrame.new(0, 1.185782, 0.502228, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 31, c0 = CFrame.new(0, 0, 0.530121, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 32, c0 = CFrame.new(0, -1.185781, 0.502228, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 33, a = 33, b = 34, c0 = CFrame.new(0, 0, 0.33481, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 33, a = 33, b = 35, c0 = CFrame.new(0, 1.185782, 0.502213, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 33, a = 33, b = 36, c0 = CFrame.new(0, 0, 0.530117, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 33, a = 33, b = 37, c0 = CFrame.new(0, -1.185781, 0.502213, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 38, a = 38, b = 39, c0 = CFrame.new(-0.000015, 0, 0.334793, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 38, a = 38, b = 40, c0 = CFrame.new(-0.000015, 1.185782, 0.502213, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 38, a = 38, b = 41, c0 = CFrame.new(0, 0, 0.530121, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 38, a = 38, b = 42, c0 = CFrame.new(-0.000015, -1.185781, 0.502213, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 44, a = 44, b = 45, c0 = CFrame.new(0, 0.516162, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 46, a = 46, b = 47, c0 = CFrame.new(0.000001, 0.585915, 0.334808, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 47, a = 47, b = 48, c0 = CFrame.new(-0.000001, 0, 0.306885, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 47, a = 47, b = 49, c0 = CFrame.new(-0.000001, 1.143936, 0.111603, 1, 0, 0, 0, -0.990269, -0.139173, 0, 0.139173, -0.990269), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 50, a = 50, b = 51, c0 = CFrame.new(0, 0.585915, 0.334808, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 51, a = 51, b = 52, c0 = CFrame.new(-0.000015, 0, 0.306915, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 51, a = 51, b = 53, c0 = CFrame.new(0, 1.143936, 0.111603, 1, 0, 0, 0, -0.990269, -0.139173, 0, 0.139173, -0.990268), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 54, a = 54, b = 55, c0 = CFrame.new(0, 0.585915, 0.334809, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 55, a = 55, b = 56, c0 = CFrame.new(0, 0, 0.30691, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 55, a = 55, b = 57, c0 = CFrame.new(0, 1.143931, 0.111603, 1, 0, 0, 0, -0.990269, -0.139173, 0, 0.139173, -0.990268), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 58, a = 58, b = 59, c0 = CFrame.new(0, 0.585915, 0.334808, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 59, a = 59, b = 60, c0 = CFrame.new(-0.000015, 0, 0.306885, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 59, a = 59, b = 61, c0 = CFrame.new(0, 1.143929, 0.111603, 1, 0, 0, 0, -0.990269, -0.139173, 0, 0.139173, -0.990268), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 62, a = 62, b = 63, c0 = CFrame.new(0.000001, 0.585915, 0.334808, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 63, a = 63, b = 64, c0 = CFrame.new(-0.000001, 0, 0.306915, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 63, a = 63, b = 65, c0 = CFrame.new(-0.000001, 1.143921, 0.111603, 1, 0, 0, 0, -0.990269, -0.139173, 0, 0.139173, -0.990269), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 66, a = 66, b = 67, c0 = CFrame.new(-0.000015, 0.585915, 0.334808, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 67, a = 67, b = 68, c0 = CFrame.new(0.000015, 0, 0.3069, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 67, a = 67, b = 69, c0 = CFrame.new(0, 1.143929, 0.111603, 1, 0, 0, 0, -0.990269, -0.139173, 0, 0.139173, -0.990269), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 70, a = 70, b = 71, c0 = CFrame.new(0, 0.585915, 0.334811, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 71, a = 71, b = 72, c0 = CFrame.new(0, 0.000001, 0.306904, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 71, a = 71, b = 73, c0 = CFrame.new(0, 1.143931, 0.1116, 1, 0, 0, 0, -0.990269, -0.139173, 0, 0.139173, -0.990268), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 74, a = 74, b = 75, c0 = CFrame.new(0.000015, 0.585915, 0.334824, 1, 0, 0, 0, 0.829038, 0.559193, 0, -0.559193, 0.829038), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 75, a = 75, b = 76, c0 = CFrame.new(-0.000015, 0, 0.3069, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 75, a = 75, b = 77, c0 = CFrame.new(0, 1.143936, 0.111603, 1, 0, 0, 0, -0.990269, -0.139173, 0, 0.139173, -0.990269), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StudioFillLight", p = 1, range = 12, brightness = 0.85, color = Color3.new(1, 0.972549, 0.921569), shadows = true, enabled = true },
		{ n = "SolarGlow", p = 2, range = 14, brightness = 2.45, color = Color3.new(1, 0.658824, 0.137255), shadows = true, enabled = true },
	},
	Emitters = {},
	Textures = {
		{ n = "Studs_%s", p = 1, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 3, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 4, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 5, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 6, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 7, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 8, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 9, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 10, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 11, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 12, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 13, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 14, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 15, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 16, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 17, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 18, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 19, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 20, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 21, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 22, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 23, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 24, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 25, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 26, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 27, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 28, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 29, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 30, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 31, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 32, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 33, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 34, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 35, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 36, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 37, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 38, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 39, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 40, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 41, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 42, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 43, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 44, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 45, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 47, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 48, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 49, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 51, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 52, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 53, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 55, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 56, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 57, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 59, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 60, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 61, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 63, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 64, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 65, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 67, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 68, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 69, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 71, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 72, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 73, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 75, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 76, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 77, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1.395036, v = 1.395036, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
