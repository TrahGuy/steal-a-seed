--!strict
--==============================================================================
-- POD FORM: Spiretip (greenhollow pods/SpiretipPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "greenhollow pods/SpiretipPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "greenhollow pods/SpiretipPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(3.977515, 5.403224, 3.977539), Height = 5.403224, PartCount = 32,
	Base = 0, Root = 1,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Uncommon", Style = "TeardropPlant", TextureStyle = "Studded", UnitType = "SpiretipPod" },
	Removed = { "FlatBase" },
	Parts = {
		{ n = "LowerCore", s = "Block", z = Vector3.new(2.8, 2.1, 2.8), cf = CFrame.new(0, 1.22038, 0, -1.000001, 0, 0, 0, 1.000002, 0, 0, 0, -1.000001), c = Color3.fromRGB(68, 114, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 1
		{ n = "LowerSpiralPlate1", s = "Block", z = Vector3.new(1.85, 1.95, 0.34), cf = CFrame.new(-0.000002, 1.22038, -1.220001, -0.922807, -0.230082, -0.309017, -0.298976, 0.933551, 0.197736, 0.242988, 0.27486, -0.930275), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "LowerSeamWedge1", s = "Wedge", z = Vector3.new(0.32, 1.95, 0.34), cf = CFrame.new(-0.848978, 0.945321, -0.99646, 0.230082, 0.309017, -0.922807, -0.933551, -0.197736, -0.298976, -0.27486, 0.930275, 0.242988), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "LowerSpiralPlate2", s = "Block", z = Vector3.new(1.85, 1.95, 0.34), cf = CFrame.new(-1.220002, 1.22038, 0, 0.242988, 0.27486, -0.930275, -0.298976, 0.933551, 0.197736, 0.922807, 0.230082, 0.309017), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "LowerSeamWedge2", s = "Wedge", z = Vector3.new(0.32, 1.95, 0.34), cf = CFrame.new(-0.996453, 0.945322, 0.848969, -0.27486, 0.930275, 0.242988, -0.933551, -0.197736, -0.298976, -0.230082, -0.309017, 0.922807), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "LowerSpiralPlate3", s = "Block", z = Vector3.new(1.85, 1.95, 0.34), cf = CFrame.new(0.000002, 1.22038, 1.220001, 0.922807, 0.230082, 0.309017, -0.298976, 0.933551, 0.197736, -0.242988, -0.274861, 0.930275), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "LowerSeamWedge3", s = "Wedge", z = Vector3.new(0.32, 1.95, 0.34), cf = CFrame.new(0.848984, 0.945316, 0.99646, -0.230082, -0.309017, 0.922807, -0.933551, -0.197736, -0.298976, 0.27486, -0.930275, -0.242988), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "LowerSpiralPlate4", s = "Block", z = Vector3.new(1.85, 1.95, 0.34), cf = CFrame.new(1.220002, 1.22038, 0, -0.242988, -0.274861, 0.930275, -0.298976, 0.933551, 0.197736, -0.922807, -0.230082, -0.309017), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "LowerSeamWedge4", s = "Wedge", z = Vector3.new(0.32, 1.95, 0.34), cf = CFrame.new(0.996454, 0.945321, -0.848969, 0.27486, -0.930275, -0.242988, -0.933551, -0.197736, -0.298976, 0.230082, 0.309017, -0.922807), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "WaistHub", s = "Block", z = Vector3.new(0.5, 0.5, 0.5), cf = CFrame.new(0, 2.370383, 0, -1.000001, 0, 0, 0, 1.000002, 0, 0, 0, -1.000001), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, t = 1, st = false }, -- 10
		{ n = "CollarRing", s = "Block", z = Vector3.new(3.05, 0.38, 3.05), cf = CFrame.new(0, 2.370383, 0, -1.000001, 0, 0, 0, 1.000002, 0, 0, 0, -1.000001), c = Color3.fromRGB(236, 242, 206), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 11
		{ n = "CollarFacet1", s = "Block", z = Vector3.new(1.25, 0.34, 0.22), cf = CFrame.new(0.000002, 2.370383, -1.480011, -1.000001, 0, 0, 0, 1.000002, 0, 0, 0, -1.000001), c = Color3.fromRGB(236, 242, 206), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "CollarFacet2", s = "Block", z = Vector3.new(1.25, 0.34, 0.22), cf = CFrame.new(-1.281718, 2.370383, -0.73999, -0.5, 0, -0.866026, 0, 1.000002, 0, 0.866026, 0, -0.5), c = Color3.fromRGB(236, 242, 206), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "CollarFacet3", s = "Block", z = Vector3.new(1.25, 0.34, 0.22), cf = CFrame.new(-1.28172, 2.370383, 0.73999, 0.500001, 0, -0.866026, 0, 1.000002, 0, 0.866026, 0, 0.500001), c = Color3.fromRGB(236, 242, 206), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "CollarFacet4", s = "Block", z = Vector3.new(1.25, 0.34, 0.22), cf = CFrame.new(0, 2.370383, 1.480011, 1.000001, 0, 0, 0, 1.000002, 0, 0, 0, 1.000001), c = Color3.fromRGB(236, 242, 206), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "CollarFacet5", s = "Block", z = Vector3.new(1.25, 0.34, 0.22), cf = CFrame.new(1.28172, 2.370383, 0.73999, 0.5, 0, 0.866026, 0, 1.000002, 0, -0.866026, 0, 0.5), c = Color3.fromRGB(236, 242, 206), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "CollarFacet6", s = "Block", z = Vector3.new(1.25, 0.34, 0.22), cf = CFrame.new(1.281722, 2.370383, -0.73999, -0.5, 0, 0.866026, 0, 1.000002, 0, -0.866026, 0, -0.5), c = Color3.fromRGB(236, 242, 206), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "SpireCore", s = "Block", z = Vector3.new(1.8, 1.9, 1.8), cf = CFrame.new(0, 3.420388, 0, -1.000001, 0, 0, 0, 1.000002, 0, 0, 0, -1.000001), c = Color3.fromRGB(68, 114, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "UpperSpiralPlate1", s = "Block", z = Vector3.new(1.42, 1.85, 0.28), cf = CFrame.new(-0.422523, 3.420386, -0.794647, -0.586174, -0.319004, -0.744741, -0.150872, 0.946124, -0.286516, 0.796015, -0.055588, -0.60272), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "UpperSeamWedge1", s = "Wedge", z = Vector3.new(0.24, 1.85, 0.28), cf = CFrame.new(-0.844574, 3.311757, -0.221497, 0.319004, 0.744741, -0.586174, -0.946124, 0.286516, -0.150872, 0.055588, 0.60272, 0.796015), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "UpperSpiralPlate2", s = "Block", z = Vector3.new(1.42, 1.85, 0.28), cf = CFrame.new(-0.794656, 3.420386, 0.422516, 0.796015, -0.055588, -0.60272, -0.150872, 0.946124, -0.286516, 0.586174, 0.319004, 0.744741), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "UpperSeamWedge2", s = "Wedge", z = Vector3.new(0.24, 1.85, 0.28), cf = CFrame.new(-0.221525, 3.311757, 0.844574, 0.055588, 0.60272, 0.796015, -0.946124, 0.286516, -0.150872, -0.319004, -0.744741, 0.586174), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "UpperSpiralPlate3", s = "Block", z = Vector3.new(1.42, 1.85, 0.28), cf = CFrame.new(0.422523, 3.420386, 0.794647, 0.586174, 0.319004, 0.744741, -0.150872, 0.946124, -0.286516, -0.796015, 0.055588, 0.60272), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "UpperSeamWedge3", s = "Wedge", z = Vector3.new(0.24, 1.85, 0.28), cf = CFrame.new(0.844572, 3.311757, 0.221527, -0.319004, -0.744741, 0.586174, -0.946124, 0.286516, -0.150872, -0.055588, -0.60272, -0.796015), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "UpperSpiralPlate4", s = "Block", z = Vector3.new(1.42, 1.85, 0.28), cf = CFrame.new(0.794654, 3.420386, -0.422516, -0.796015, 0.055588, 0.60272, -0.150872, 0.946124, -0.286516, -0.586174, -0.319004, -0.744741), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "UpperSeamWedge4", s = "Wedge", z = Vector3.new(0.24, 1.85, 0.28), cf = CFrame.new(0.221519, 3.311757, -0.844574, -0.055588, -0.60272, -0.796015, -0.946124, 0.286516, -0.150872, 0.319004, 0.744741, -0.586174), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "TipRoot", s = "Block", z = Vector3.new(0.3, 0.3, 0.3), cf = CFrame.new(0, 4.470389, 0, -1.000001, 0, 0, 0, 1.000002, 0, 0, 0, -1.000001), c = Color3.fromRGB(242, 246, 220), m = Enum.Material.Plastic, t = 1, st = false }, -- 27
		{ n = "TipCollar", s = "Block", z = Vector3.new(1.18, 0.32, 1.18), cf = CFrame.new(0, 4.470389, 0, -1.000001, 0, 0, 0, 1.000002, 0, 0, 0, -1.000001), c = Color3.fromRGB(242, 246, 220), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 28
		{ n = "ApexPointWedge1", s = "Wedge", z = Vector3.new(0.6175, 0.72, 0.456), cf = CFrame.new(-0.000002, 4.990387, -0.209015, 1.000001, 0, 0, 0, 0.951059, 0.309018, 0, -0.309017, 0.951058), c = Color3.fromRGB(242, 246, 220), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "ApexPointWedge2", s = "Wedge", z = Vector3.new(0.6175, 0.72, 0.456), cf = CFrame.new(-0.209002, 4.990387, 0, 0, -0.309017, 0.951058, 0, 0.951059, 0.309018, -1.000001, 0, 0), c = Color3.fromRGB(242, 246, 220), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "ApexPointWedge3", s = "Wedge", z = Vector3.new(0.6175, 0.72, 0.456), cf = CFrame.new(0.000002, 4.990387, 0.208984, -1.000001, 0, 0, 0, 0.951059, 0.309018, 0, 0.309017, -0.951057), c = Color3.fromRGB(242, 246, 220), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "ApexPointWedge4", s = "Wedge", z = Vector3.new(0.6175, 0.72, 0.456), cf = CFrame.new(0.209, 4.990387, 0, 0, 0.309017, -0.951058, 0, 0.951059, 0.309018, 1.000001, 0, 0), c = Color3.fromRGB(242, 246, 220), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0.000002, 0, 1.220001, 0.922808, 0.230082, 0.309018, -0.298976, 0.933553, 0.197737, -0.242988, -0.274861, 0.930276), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 4, c0 = CFrame.new(1.220003, 0, 0, -0.242988, -0.274861, 0.930276, -0.298976, 0.933553, 0.197737, -0.922808, -0.230082, -0.309018), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 6, c0 = CFrame.new(-0.000002, 0, -1.220001, -0.922808, -0.230082, -0.309018, -0.298976, 0.933553, 0.197737, 0.242988, 0.274861, -0.930276), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 8, c0 = CFrame.new(-1.220004, 0, 0, 0.242988, 0.274861, -0.930276, -0.298976, 0.933553, 0.197737, 0.922808, 0.230082, 0.309018), c1 = CFrame.new() },
		{ k = "Motor6D", n = "WaistJoint", h = 1, a = 1, b = 10, c0 = CFrame.new(0, 1.15, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 2, a = 2, b = 3, c0 = CFrame.new(0.919998, 0, 0.000031, 0.000001, 0, 1.000003, -1.000004, 0, -0.000001, -0.000001, -1.000002, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(0.920013, -0.000015, 0, 0.000001, 0, 1.000002, -1.000004, 0, -0.000001, 0, -1.000002, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 7, c0 = CFrame.new(0.919998, -0.000015, -0.000031, 0.000001, 0, 1.000003, -1.000004, 0, -0.000001, 0, -1.000002, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 9, c0 = CFrame.new(0.920013, -0.000008, -0.000008, 0.000001, 0, 1.000003, -1.000004, 0, -0.000001, 0, -1.000002, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 11, c0 = CFrame.new(0, 0, 0, 1.000002, 0, 0, 0, 1.000004, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 18, c0 = CFrame.new(0, 1.050007, 0, 1.000002, 0, 0, 0, 1.000004, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 12, c0 = CFrame.new(-0.000002, 0, 1.480011, 1.000002, 0, 0, 0, 1.000004, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 13, c0 = CFrame.new(1.281719, 0, 0.73999, 0.500001, 0, 0.866027, 0, 1.000004, 0, -0.866027, 0, 0.500001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 14, c0 = CFrame.new(1.281721, 0, -0.73999, -0.500001, 0, 0.866027, 0, 1.000004, 0, -0.866027, 0, -0.500001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 15, c0 = CFrame.new(0, 0, -1.480011, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 16, c0 = CFrame.new(-1.281722, 0, -0.73999, -0.500001, 0, -0.866027, 0, 1.000004, 0, 0.866027, 0, -0.500001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 17, c0 = CFrame.new(-1.281724, 0, 0.73999, 0.500001, 0, -0.866027, 0, 1.000004, 0, 0.866027, 0, 0.500001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 19, c0 = CFrame.new(0.422523, -0.000002, 0.794647, 0.586174, 0.319004, 0.744742, -0.150872, 0.946126, -0.286517, -0.796016, 0.055588, 0.602721), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 21, c0 = CFrame.new(0.794657, -0.000002, -0.422516, -0.796016, 0.055588, 0.602721, -0.150872, 0.946126, -0.286517, -0.586174, -0.319004, -0.744742), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 23, c0 = CFrame.new(-0.422524, -0.000002, -0.794647, -0.586175, -0.319004, -0.744742, -0.150872, 0.946126, -0.286517, 0.796016, -0.055588, -0.602721), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 25, c0 = CFrame.new(-0.794655, -0.000002, 0.422516, 0.796016, -0.055588, -0.602721, -0.150872, 0.946126, -0.286517, 0.586174, 0.319004, 0.744742), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TipJoint", h = 18, a = 18, b = 27, c0 = CFrame.new(0, 1.05, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 20, c0 = CFrame.new(0.720001, 0, 0, 0, 0, 1.000002, -1.000004, 0.000001, 0, 0.000001, -1.000002, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 21, a = 21, b = 22, c0 = CFrame.new(0.720001, 0.000008, 0.000015, 0, 0, 1.000002, -1.000004, 0.000001, 0, 0.000001, -1.000002, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 24, c0 = CFrame.new(0.720001, 0, 0, 0, 0, 1.000002, -1.000004, 0.000001, 0, 0.000001, -1.000002, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 25, a = 25, b = 26, c0 = CFrame.new(0.720001, 0, -0.000015, 0, 0, 1.000002, -1.000004, 0.000001, 0, 0.000001, -1.000002, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 28, c0 = CFrame.new(0, 0, 0, 1.000002, 0, 0, 0, 1.000004, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 29, c0 = CFrame.new(0.000002, 0.519999, 0.209015, -1.000002, 0, 0, 0, 0.951061, 0.309018, 0, 0.309018, -0.951059), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 30, c0 = CFrame.new(0.209002, 0.519999, 0, 0, 0.309018, -0.951059, 0, 0.951061, 0.309018, 1.000002, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 31, c0 = CFrame.new(-0.000002, 0.519999, -0.208984, 1.000002, 0, 0, 0, 0.951061, 0.309018, 0, -0.309018, 0.951059), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 32, c0 = CFrame.new(-0.209, 0.519999, 0, 0, -0.309018, 0.951059, 0, 0.951061, 0.309018, -1.000002, 0, 0), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StudioFillLight", p = 1, range = 12, brightness = 0.85, color = Color3.new(1, 0.988235, 0.94902), shadows = true, enabled = true },
	},
	Emitters = {},
	Textures = {
		{ n = "Studs_%s", p = 1, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 2, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 3, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 4, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 5, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 6, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 7, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 8, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 9, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 11, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 12, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 13, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 14, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 15, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 16, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 17, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 18, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 19, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 20, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 21, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 22, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 23, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 24, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 25, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 26, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 28, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 29, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 30, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 31, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 32, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 8.702407, v = 8.702407, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
