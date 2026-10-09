--!strict
--==============================================================================
-- POD FORM: Raincup (dustbowl pods/RaincupPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "dustbowl pods/RaincupPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "dustbowl pods/RaincupPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(3.476379, 4.546124, 3.476379), Height = 4.546124, PartCount = 36,
	Base = 0, Root = 5,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Epic", Style = "RainGoblet", TextureStyle = "Studded", UnitType = "RaincupPod" },
	Removed = { "FlatBase" },
	Parts = {
		{ n = "GobletFoot", s = "Block", z = Vector3.new(2.19357, 0.261362, 2.19357), cf = CFrame.new(0.000002, 0.130681, 0, -1.000001, 0, 0, 0, 1.000003, 0, 0, 0, -1.000001), c = Color3.fromRGB(92, 154, 212), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, an = true, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 1
		{ n = "GobletStem", s = "Block", z = Vector3.new(1.260136, 0.410711, 1.260136), cf = CFrame.new(0.000002, 0.457384, 0, -1.000002, 0, 0, 0, 1.000003, 0, 0, 0, -1.000002), c = Color3.fromRGB(92, 154, 212), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 2
		{ n = "StemKnop", s = "Block", z = Vector3.new(1.726853, 0.224024, 1.726853), cf = CFrame.new(0.000002, 0.756084, 0, -1.000002, 0, 0, 0, 1.000003, 0, 0, 0, -1.000002), c = Color3.fromRGB(255, 216, 84), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 3
		{ n = "ChaliceBasin", s = "Block", z = Vector3.new(2.4736, 0.42938, 2.4736), cf = CFrame.new(0.000001, 1.083073, 0, -1.000001, 0, 0, 0, 1.000003, 0, 0, 0, -1.000001), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 4
		{ n = "GobletCore", s = "Block", z = Vector3.new(2.566944, 2.4736, 2.566944), cf = CFrame.new(0.000001, 2.249869, 0, -1.000001, 0, 0, 0, 1.000003, 0, 0, 0, -1.000001), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 5
		{ n = "Lobe1_Hinge", s = "Block", z = Vector3.new(0.28003, 0.28003, 0.28003), cf = CFrame.new(0.000001, 1.363104, -1.194794, -1.000001, 0, 0, 0, 1.000003, 0, 0, 0, -1.000001), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, t = 1, st = false }, -- 6
		{ n = "Lobe1_Lower", s = "Block", z = Vector3.new(1.726853, 1.446823, 0.336036), cf = CFrame.new(0.000001, 2.063181, -1.400146, -1.000002, 0, 0, 0, 0.970299, 0.241923, 0, 0.241922, -0.970297), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "Lobe1_Upper", s = "Block", z = Vector3.new(1.605507, 1.446823, 0.317368), cf = CFrame.new(0.000001, 3.249758, -0.950378, -1.000002, 0, 0, 0, 0.970299, -0.241923, 0, -0.241922, -0.970297), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "Lobe1_Crest", s = "Wedge", z = Vector3.new(1.260136, 0.513389, 0.317368), cf = CFrame.new(0.000001, 4.110184, -1.164917, -1.000002, 0, 0, 0, -0.970299, 0.241923, 0, 0.241922, 0.970297), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "Lobe1_PinkThroat", s = "Block", z = Vector3.new(1.353479, 1.260136, 0.205355), cf = CFrame.new(-0.000001, 3.163582, -0.717255, -1.000002, 0, 0, 0, 0.990271, -0.139173, 0, -0.139173, -0.99027), c = Color3.fromRGB(226, 100, 142), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "Lobe1_PinkLip", s = "Block", z = Vector3.new(1.381482, 0.205355, 0.224024), cf = CFrame.new(0.000001, 3.865569, -0.988464, -1.000002, 0, 0, 0, 0.970299, -0.241923, 0, -0.241922, -0.970297), c = Color3.fromRGB(226, 100, 142), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "Lobe2_Hinge", s = "Block", z = Vector3.new(0.28003, 0.28003, 0.28003), cf = CFrame.new(-1.194797, 1.363104, 0, 0, 0, -1.000001, 0, 1.000003, 0, 1.000001, 0, 0), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, t = 1, st = false }, -- 12
		{ n = "Lobe2_Lower", s = "Block", z = Vector3.new(1.726853, 1.446823, 0.336036), cf = CFrame.new(-1.400153, 2.063181, 0, 0, 0.241922, -0.970297, 0, 0.970299, 0.241923, 1.000002, 0, 0), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "Lobe2_Upper", s = "Block", z = Vector3.new(1.605507, 1.446823, 0.317368), cf = CFrame.new(-0.950385, 3.249758, 0, 0, -0.241922, -0.970297, 0, 0.970299, -0.241923, 1.000002, 0, 0), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "Lobe2_Crest", s = "Wedge", z = Vector3.new(1.260136, 0.513389, 0.317368), cf = CFrame.new(-1.164911, 4.110184, 0, 0, 0.241922, 0.970297, 0, -0.970299, 0.241923, 1.000002, 0, 0), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "Lobe2_PinkThroat", s = "Block", z = Vector3.new(1.353479, 1.260136, 0.205355), cf = CFrame.new(-0.717257, 3.163582, 0, 0, -0.139173, -0.99027, 0, 0.990271, -0.139174, 1.000002, 0, 0), c = Color3.fromRGB(226, 100, 142), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "Lobe2_PinkLip", s = "Block", z = Vector3.new(1.381482, 0.205355, 0.224024), cf = CFrame.new(-0.988482, 3.865568, 0, 0, -0.241922, -0.970297, 0, 0.970299, -0.241923, 1.000002, 0, 0), c = Color3.fromRGB(226, 100, 142), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "Lobe3_Hinge", s = "Block", z = Vector3.new(0.28003, 0.28003, 0.28003), cf = CFrame.new(0.000001, 1.363104, 1.194794, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, t = 1, st = false }, -- 18
		{ n = "Lobe3_Lower", s = "Block", z = Vector3.new(1.726853, 1.446823, 0.336036), cf = CFrame.new(0.000001, 2.063181, 1.400146, 1.000002, 0, 0, 0, 0.970299, 0.241923, 0, -0.241922, 0.970297), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "Lobe3_Upper", s = "Block", z = Vector3.new(1.605507, 1.446823, 0.317368), cf = CFrame.new(0.000001, 3.249758, 0.950378, 1.000002, 0, 0, 0, 0.970299, -0.241923, 0, 0.241922, 0.970297), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "Lobe3_Crest", s = "Wedge", z = Vector3.new(1.260136, 0.513389, 0.317368), cf = CFrame.new(0.000003, 4.110183, 1.164917, 1.000002, 0, 0, 0, -0.970299, 0.241923, 0, -0.241922, -0.970297), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "Lobe4_Hinge", s = "Block", z = Vector3.new(0.28003, 0.28003, 0.28003), cf = CFrame.new(1.194798, 1.363104, 0, 0, 0, 1.000001, 0, 1.000003, 0, -1.000001, 0, 0), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, t = 1, st = false }, -- 22
		{ n = "Lobe4_Lower", s = "Block", z = Vector3.new(1.726853, 1.446823, 0.336036), cf = CFrame.new(1.400153, 2.063181, 0, 0, -0.241922, 0.970297, 0, 0.970299, 0.241923, -1.000002, 0, 0), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "Lobe4_Upper", s = "Block", z = Vector3.new(1.605507, 1.446823, 0.317368), cf = CFrame.new(0.950387, 3.249758, 0, 0, 0.241922, 0.970297, 0, 0.970299, -0.241923, -1.000002, 0, 0), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "Lobe4_Crest", s = "Wedge", z = Vector3.new(1.260136, 0.513389, 0.317368), cf = CFrame.new(1.164914, 4.110183, 0, 0, -0.241922, -0.970297, 0, -0.970299, 0.241923, -1.000002, 0, 0), c = Color3.fromRGB(124, 188, 242), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "GoldBoss", s = "Block", z = Vector3.new(1.073449, 0.886762, 1.073449), cf = CFrame.new(0.000001, 3.762037, 0, -1.000002, 0, 0, 0, 1.000003, 0, 0, 0, -1.000002), c = Color3.fromRGB(255, 216, 84), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 26
		{ n = "BossFacet1", s = "Wedge", z = Vector3.new(0.392042, 0.578729, 0.317368), cf = CFrame.new(-0.000001, 3.762036, -0.485382, -1.000002, 0, 0, 0, -0.927187, 0.374608, 0, 0.374607, 0.927185), c = Color3.fromRGB(255, 216, 84), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "BossFacet2", s = "Wedge", z = Vector3.new(0.392042, 0.578729, 0.317368), cf = CFrame.new(-0.420358, 3.762036, -0.242706, -0.500001, 0.324419, 0.802966, 0, -0.927187, 0.374608, 0.866027, 0.187304, 0.463593), c = Color3.fromRGB(255, 216, 84), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "BossFacet3", s = "Wedge", z = Vector3.new(0.392042, 0.578729, 0.317368), cf = CFrame.new(-0.420359, 3.762036, 0.242706, 0.500001, 0.324419, 0.802966, 0, -0.927187, 0.374608, 0.866027, -0.187304, -0.463593), c = Color3.fromRGB(255, 216, 84), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "BossFacet4", s = "Wedge", z = Vector3.new(0.392042, 0.578729, 0.317368), cf = CFrame.new(-0.000001, 3.762036, 0.485382, 1.000002, 0, 0, 0, -0.927187, 0.374608, 0, -0.374607, -0.927185), c = Color3.fromRGB(255, 216, 84), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "BossFacet5", s = "Wedge", z = Vector3.new(0.392042, 0.578729, 0.317368), cf = CFrame.new(0.420356, 3.762036, 0.242706, 0.500001, -0.324419, -0.802966, 0, -0.927187, 0.374608, -0.866027, -0.187303, -0.463593), c = Color3.fromRGB(255, 216, 84), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "BossFacet6", s = "Wedge", z = Vector3.new(0.392042, 0.578729, 0.317368), cf = CFrame.new(0.420358, 3.762036, -0.242706, -0.500001, -0.324419, -0.802966, 0, -0.927187, 0.374608, -0.866027, 0.187304, 0.463593), c = Color3.fromRGB(255, 216, 84), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "ApexGlint", s = "Block", z = Vector3.new(0.392042, 0.485386, 0.392042), cf = CFrame.new(0.000001, 4.30343, 0, -1.000002, 0, 0, 0, 1.000003, 0, 0, 0, -1.000002), c = Color3.fromRGB(255, 216, 84), m = Enum.Material.Neon, st = false, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 33
		{ n = "DewDropHinge", s = "Block", z = Vector3.new(0.186687, 0.186687, 0.186687), cf = CFrame.new(1.138792, 2.884606, -0.672089, -1.000001, 0, 0, 0, 1.000003, 0, 0, 0, -1.000001), c = Color3.fromRGB(210, 245, 255), m = Enum.Material.Plastic, t = 1, st = false }, -- 34
		{ n = "WaterDropBody", s = "Block", z = Vector3.new(0.410711, 0.448048, 0.410711), cf = CFrame.new(1.138792, 3.024621, -0.672089, -1.000002, 0, 0, 0, 1.000003, 0, 0, 0, -1.000002), c = Color3.fromRGB(210, 245, 255), m = Enum.Material.Glass, t = 0.28, st = false, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 35
		{ n = "WaterDropTail", s = "Wedge", z = Vector3.new(0.242693, 0.336036, 0.242693), cf = CFrame.new(1.13879, 3.239312, -0.634735, -0.970297, -0.241922, 0, -0.230082, 0.922809, -0.309018, 0.074758, -0.299838, -0.951058), c = Color3.fromRGB(210, 245, 255), m = Enum.Material.Glass, t = 0.32, st = false }, -- 36
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0.326704, 0, 1.000003, 0, 0, 0, 1.000006, 0, 0, 0, 1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, 0.625405, 0, 1.000003, 0, 0, 0, 1.000006, 0, 0, 0, 1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 4, c0 = CFrame.new(0.000001, 0.952394, 0, 1.000003, 0, 0, 0, 1.000006, 0, 0, 0, 1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 1.166799, 0, 1.000003, 0, 0, 0, 1.000006, 0, 0, 0, 1.000003), c1 = CFrame.new() },
		{ k = "Motor6D", n = "LobeJoint1", h = 5, a = 5, b = 6, c0 = CFrame.new(0, -0.886762, 1.194796, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LobeJoint2", h = 5, a = 5, b = 12, c0 = CFrame.new(1.194796, -0.886762, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LobeJoint3", h = 5, a = 5, b = 18, c0 = CFrame.new(0, -0.886762, -1.194796, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LobeJoint4", h = 5, a = 5, b = 22, c0 = CFrame.new(-1.194796, -0.886762, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 26, c0 = CFrame.new(0, 1.512172, 0, 1.000003, 0, 0, 0, 1.000006, 0, 0, 0, 1.000003), c1 = CFrame.new() },
		{ k = "Motor6D", n = "DewDropJoint", h = 5, a = 5, b = 34, c0 = CFrame.new(-1.13879, 0.634735, 0.672073, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 7, c0 = CFrame.new(0, 0.70008, 0.205353, 1.000003, 0, 0, 0, 0.970302, 0.241923, 0, -0.241923, 0.970299), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 8, c0 = CFrame.new(0, 1.88666, -0.244415, 1.000003, 0, 0, 0, 0.970302, -0.241923, 0, 0.241923, 0.970299), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 9, c0 = CFrame.new(0, 0.886772, 0, 1.000003, 0, 0, 0, -1.000006, 0.000001, 0, 0.000001, -1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 10, c0 = CFrame.new(0.000002, -0.140015, -0.205353, 1.000003, 0, 0, 0, 0.994528, 0.104528, 0, -0.10453, 0.994525), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 11, c0 = CFrame.new(0, 0.606735, -0.11203, 1.000003, 0, 0, 0, 1.000006, -0.000001, 0, -0.000001, 1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 13, c0 = CFrame.new(0, 0.70008, 0.205357, 1.000003, 0, 0, 0, 0.970302, 0.241923, 0, -0.241923, 0.970299), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 14, c0 = CFrame.new(0, 1.88666, -0.244412, 1.000003, 0, 0, 0, 0.970302, -0.241923, 0, 0.241923, 0.970299), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 15, c0 = CFrame.new(0, 0.886768, -0.000003, 1.000003, 0, 0, 0, -1.000006, 0.000001, 0, 0.000001, -1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 16, c0 = CFrame.new(0, -0.140016, -0.205356, 1.000003, 0, 0, 0, 0.994528, 0.104528, 0, -0.10453, 0.994525), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 17, c0 = CFrame.new(0, 0.606735, -0.112014, 1.000003, 0, 0, 0, 1.000006, -0.000001, 0, -0.000001, 1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 19, c0 = CFrame.new(0, 0.70008, 0.205353, 1.000003, 0, 0, 0, 0.970302, 0.241923, 0, -0.241923, 0.970299), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 20, c0 = CFrame.new(0, 1.88666, -0.244415, 1.000003, 0, 0, 0, 0.970302, -0.241923, 0, 0.241923, 0.970299), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 21, c0 = CFrame.new(0.000002, 0.886765, 0, 1.000003, 0, 0, 0, -1.000006, 0.000001, 0, 0.000001, -1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 23, c0 = CFrame.new(0, 0.70008, 0.205355, 1.000003, 0, 0, 0, 0.970302, 0.241923, 0, -0.241923, 0.970299), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 24, c0 = CFrame.new(0, 1.88666, -0.244411, 1.000003, 0, 0, 0, 0.970302, -0.241923, 0, 0.241923, 0.970299), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 24, a = 24, b = 25, c0 = CFrame.new(0, 0.886767, 0, 1.000003, 0, 0, 0, -1.000006, 0.000001, 0, 0.000001, -1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 27, c0 = CFrame.new(0.000002, 0, 0.485382, 1.000003, 0, 0, 0, -0.92719, 0.374609, 0, -0.374608, -0.927187), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 28, c0 = CFrame.new(0.420359, 0, 0.242706, 0.500001, -0.32442, -0.802967, 0, -0.92719, 0.374609, -0.866028, -0.187304, -0.463593), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 29, c0 = CFrame.new(0.42036, 0, -0.242706, -0.500002, -0.32442, -0.802967, 0, -0.92719, 0.374609, -0.866028, 0.187304, 0.463593), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 30, c0 = CFrame.new(0.000002, 0, -0.485382, -1.000003, 0, 0, 0, -0.92719, 0.374609, 0, 0.374608, 0.927187), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 31, c0 = CFrame.new(-0.420356, 0, -0.242706, -0.500001, 0.32442, 0.802967, 0, -0.92719, 0.374609, 0.866028, 0.187304, 0.463593), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 32, c0 = CFrame.new(-0.420358, 0, 0.242706, 0.500001, 0.32442, 0.802967, 0, -0.92719, 0.374609, 0.866028, -0.187304, -0.463593), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 33, c0 = CFrame.new(0, 0.541395, 0, 1.000003, 0, 0, 0, 1.000006, 0, 0, 0, 1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 34, a = 34, b = 35, c0 = CFrame.new(0, 0.140016, 0, 1.000003, 0, 0, 0, 1.000006, 0, 0, 0, 1.000003), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 35, a = 35, b = 36, c0 = CFrame.new(0.000002, 0.214691, -0.037354, 0.970299, 0.241923, 0, -0.230083, 0.922812, -0.309019, -0.074758, 0.299839, 0.95106), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StudioFillLight", p = 5, range = 12, brightness = 0.85, color = Color3.new(0.960784, 0.980392, 1), shadows = true, enabled = true },
		{ n = "GoldGlow", p = 26, range = 8.5, brightness = 1.45, color = Color3.new(1, 0.882353, 0.470588), shadows = true, enabled = true },
	},
	Emitters = {},
	Textures = {
		{ n = "Studs_%s", p = 1, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 2, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 3, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 4, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 5, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 7, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 8, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 9, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 10, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 11, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 13, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 14, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 15, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 16, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 17, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 19, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 20, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 21, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 23, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 24, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 25, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 26, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 27, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 28, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 29, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 30, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 31, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 32, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 4.431507, v = 4.431507, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
