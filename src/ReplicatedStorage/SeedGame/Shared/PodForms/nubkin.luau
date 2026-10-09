--!strict
--==============================================================================
-- POD FORM: Nubkin (greenhollow pods/NubkinPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "greenhollow pods/NubkinPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "greenhollow pods/NubkinPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(4.039978, 4.582042, 4.039999), Height = 4.582042, PartCount = 60,
	Base = 0, Root = 1,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Style = "RoundedCubePod", TextureStyle = "Studded", UnitType = "ChunkySeedPod" },
	Removed = { "FlatBase" },
	Parts = {
		{ n = "PodCore", s = "Block", z = Vector3.new(3.128, 3.128, 3.128), cf = CFrame.new(0, 2.02, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(105, 148, 75), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "Front_Plate", s = "Block", z = Vector3.new(2.384, 2.384, 0.28), cf = CFrame.new(0, 2.02, -1.799999, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(146, 196, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "Front_BevelTop", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(0, 3.432, -1.799999, -1, 0, 0, 0, 0, 1, 0, 1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "Front_BevelBottom", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(0, 0.608, -1.799999, -1, 0, 0, 0, 0, -1, 0, -1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "Front_BevelLeft", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(1.411987, 2.02, -1.799999, 0, 0, 1, 1, 0, 0, 0, 1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "Front_BevelRight", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(-1.411987, 2.02, -1.800001, 0, 0, -1, -1, 0, 0, 0, 1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "Front_Corner1", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.411987, 3.432, -1.780001, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "Front_Corner2", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.411987, 3.432, -1.780001, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "Front_Corner3", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.411987, 0.608, -1.780001, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "Front_Corner4", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.411987, 0.608, -1.780001, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "Back_Plate", s = "Block", z = Vector3.new(2.384, 2.384, 0.28), cf = CFrame.new(0, 2.02, 1.799999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 196, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "Back_BevelTop", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(0, 3.432, 1.799999, 1, 0, 0, 0, 0, 1, 0, -1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "Back_BevelBottom", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(0, 0.608, 1.799999, 1, 0, 0, 0, 0, -1, 0, 1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "Back_BevelLeft", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(-1.411987, 2.02, 1.799999, 0, 0, -1, 1, 0, 0, 0, -1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "Back_BevelRight", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(1.411987, 2.02, 1.799999, 0, 0, 1, -1, 0, 0, 0, -1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "Back_Corner1", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.411987, 3.432, 1.780001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "Back_Corner2", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.411987, 3.432, 1.779999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "Back_Corner3", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.411987, 0.608, 1.780001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "Back_Corner4", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.411987, 0.608, 1.779999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "Right_Plate", s = "Block", z = Vector3.new(2.384, 2.384, 0.28), cf = CFrame.new(-1.799988, 2.02, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(146, 196, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "Right_BevelTop", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(-1.799988, 3.432, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "Right_BevelBottom", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(-1.799988, 0.608, 0, 0, -1, 0, 0, 0, -1, 1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "Right_BevelLeft", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(-1.799988, 2.02, -1.412001, 0, 1, 0, 1, 0, 0, 0, 0, -1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "Right_BevelRight", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(-1.799988, 2.02, 1.412001, 0, 1, 0, -1, 0, 0, 0, 0, 1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "Right_Corner1", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.779999, 3.432, -1.411999, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "Right_Corner2", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.779999, 3.432, 1.411999, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "Right_Corner3", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.779999, 0.608, -1.411999, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "Right_Corner4", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.779999, 0.608, 1.411999, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "Left_Plate", s = "Block", z = Vector3.new(2.384, 2.384, 0.28), cf = CFrame.new(1.799988, 2.02, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(146, 196, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "Left_BevelTop", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(1.799988, 3.432, 0, 0, -1, 0, 0, 0, 1, -1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "Left_BevelBottom", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(1.799988, 0.608, 0, 0, 1, 0, 0, 0, -1, -1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "Left_BevelLeft", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(1.799988, 2.02, 1.412001, 0, -1, 0, 1, 0, 0, 0, 0, 1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "Left_BevelRight", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(1.799988, 2.02, -1.412001, 0, -1, 0, -1, 0, 0, 0, 0, -1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
		{ n = "Left_Corner1", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.779999, 3.432, 1.412001, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 34
		{ n = "Left_Corner2", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.779999, 3.432, -1.412001, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 35
		{ n = "Left_Corner3", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.779999, 0.608, 1.412001, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 36
		{ n = "Left_Corner4", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.779999, 0.608, -1.412001, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 37
		{ n = "Top_PlateL", s = "Block", z = Vector3.new(1.112, 2.384, 0.28), cf = CFrame.new(0.635986, 3.82, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), c = Color3.fromRGB(146, 196, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 38
		{ n = "Top_PlateR", s = "Block", z = Vector3.new(1.112, 2.384, 0.28), cf = CFrame.new(-0.636017, 3.82, 0, -1, 0, 0, 0, 0, 1, 0, 1, 0), c = Color3.fromRGB(146, 196, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 39
		{ n = "Top_BevelTop", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(0, 3.82, 1.412001, -1, 0, 0, 0, -1, 0, 0, 0, 1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 40
		{ n = "Top_BevelBottom", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(0, 3.82, -1.412001, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 41
		{ n = "Top_BevelLeft", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(1.411987, 3.82, 0, 0, 0, 1, 0, -1, 0, 1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 42
		{ n = "Top_BevelRight", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(-1.411987, 3.82, 0, 0, 0, -1, 0, -1, 0, -1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 43
		{ n = "Top_Corner1", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.411987, 3.8, 1.412001, -1, 0, 0, 0, 0, 1, 0, 1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 44
		{ n = "Top_Corner2", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.411987, 3.8, 1.412001, -1, 0, 0, 0, 0, 1, 0, 1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 45
		{ n = "Top_Corner3", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.411987, 3.8, -1.412001, -1, 0, 0, 0, 0, 1, 0, 1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 46
		{ n = "Top_Corner4", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.411987, 3.8, -1.412001, -1, 0, 0, 0, 0, 1, 0, 1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 47
		{ n = "Bottom_Plate", s = "Block", z = Vector3.new(2.384, 2.384, 0.28), cf = CFrame.new(0, 0.22, 0, -1, 0, 0, 0, 0, -1, 0, -1, 0), c = Color3.fromRGB(146, 196, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 48
		{ n = "Bottom_BevelTop", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(0, 0.22, -1.412001, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 49
		{ n = "Bottom_BevelBottom", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(0, 0.22, 1.412001, -1, 0, 0, 0, -1, 0, 0, 0, 1), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 50
		{ n = "Bottom_BevelLeft", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(1.411987, 0.22, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 51
		{ n = "Bottom_BevelRight", s = "Wedge", z = Vector3.new(2.384, 0.44, 0.28), cf = CFrame.new(-1.411987, 0.22, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 52
		{ n = "Bottom_Corner1", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.411987, 0.24, -1.412001, -1, 0, 0, 0, 0, -1, 0, -1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 53
		{ n = "Bottom_Corner2", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.411987, 0.24, -1.412001, -1, 0, 0, 0, 0, -1, 0, -1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 54
		{ n = "Bottom_Corner3", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(1.411987, 0.24, 1.412001, -1, 0, 0, 0, 0, -1, 0, -1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 55
		{ n = "Bottom_Corner4", s = "Block", z = Vector3.new(0.44, 0.44, 0.238), cf = CFrame.new(-1.411987, 0.24, 1.412001, -1, 0, 0, 0, 0, -1, 0, -1, 0), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 56
		{ n = "SproutStemL", s = "Block", z = Vector3.new(0.24, 0.48, 0.34), cf = CFrame.new(0.149994, 3.94, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(146, 196, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 57
		{ n = "SproutTipL", s = "Wedge", z = Vector3.new(0.22, 0.42, 0.32), cf = CFrame.new(0.186279, 4.349015, 0.037287, -0.978148, 0.204753, -0.036103, 0.205888, 0.97808, -0.031142, 0.028936, -0.037895, -0.998863), c = Color3.fromRGB(242, 238, 206), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 58
		{ n = "SproutStemR", s = "Block", z = Vector3.new(0.24, 0.48, 0.34), cf = CFrame.new(-0.149994, 3.94, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(146, 196, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 59
		{ n = "SproutTipR", s = "Wedge", z = Vector3.new(0.22, 0.42, 0.32), cf = CFrame.new(-0.186279, 4.349014, -0.037287, -0.978148, -0.204753, -0.036103, -0.205888, 0.97808, 0.031142, 0.028936, 0.037895, -0.998863), c = Color3.fromRGB(242, 238, 206), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 60
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 1.799999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, 1.412, 1.799999, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 4, c0 = CFrame.new(0, -1.412, 1.799999, 1, 0, 0, 0, 0, -1, 0, 1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 5, c0 = CFrame.new(-1.411987, 0, 1.799999, 0, 0, -1, 1, 0, 0, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 6, c0 = CFrame.new(1.411987, 0, 1.800001, 0, 0, 1, -1, 0, 0, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 7, c0 = CFrame.new(-1.411987, 1.412, 1.780001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 8, c0 = CFrame.new(1.411987, 1.412, 1.780001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 9, c0 = CFrame.new(-1.411987, -1.412, 1.780001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 10, c0 = CFrame.new(1.411987, -1.412, 1.780001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 11, c0 = CFrame.new(0, 0, -1.799999, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 12, c0 = CFrame.new(0, 1.412, -1.799999, -1, 0, 0, 0, 0, 1, 0, 1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 13, c0 = CFrame.new(0, -1.412, -1.799999, -1, 0, 0, 0, 0, -1, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 14, c0 = CFrame.new(1.411987, 0, -1.799999, 0, 0, 1, 1, 0, 0, 0, 1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 15, c0 = CFrame.new(-1.411987, 0, -1.799999, 0, 0, -1, -1, 0, 0, 0, 1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 16, c0 = CFrame.new(1.411987, 1.412, -1.780001, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 17, c0 = CFrame.new(-1.411987, 1.412, -1.779999, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 18, c0 = CFrame.new(1.411987, -1.412, -1.780001, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 19, c0 = CFrame.new(-1.411987, -1.412, -1.779999, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 20, c0 = CFrame.new(1.799988, 0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 21, c0 = CFrame.new(1.799988, 1.412, 0, 0, -1, 0, 0, 0, 1, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 22, c0 = CFrame.new(1.799988, -1.412, 0, 0, 1, 0, 0, 0, -1, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 23, c0 = CFrame.new(1.799988, 0, 1.412001, 0, -1, 0, 1, 0, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 24, c0 = CFrame.new(1.799988, 0, -1.412001, 0, -1, 0, -1, 0, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 25, c0 = CFrame.new(1.779999, 1.412, 1.411999, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 26, c0 = CFrame.new(1.779999, 1.412, -1.411999, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 27, c0 = CFrame.new(1.779999, -1.412, 1.411999, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 28, c0 = CFrame.new(1.779999, -1.412, -1.411999, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 29, c0 = CFrame.new(-1.799988, 0, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 30, c0 = CFrame.new(-1.799988, 1.412, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 31, c0 = CFrame.new(-1.799988, -1.412, 0, 0, -1, 0, 0, 0, -1, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 32, c0 = CFrame.new(-1.799988, 0, -1.412001, 0, 1, 0, 1, 0, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 33, c0 = CFrame.new(-1.799988, 0, 1.412001, 0, 1, 0, -1, 0, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 34, c0 = CFrame.new(-1.779999, 1.412, -1.412001, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 35, c0 = CFrame.new(-1.779999, 1.412, 1.412001, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 36, c0 = CFrame.new(-1.779999, -1.412, -1.412001, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 37, c0 = CFrame.new(-1.779999, -1.412, 1.412001, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 38, c0 = CFrame.new(-0.635986, 1.8, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 39, c0 = CFrame.new(0.636017, 1.8, 0, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 40, c0 = CFrame.new(0, 1.8, -1.412001, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 41, c0 = CFrame.new(0, 1.8, 1.412001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 42, c0 = CFrame.new(-1.411987, 1.8, 0, 0, 0, -1, 0, -1, 0, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 43, c0 = CFrame.new(1.411987, 1.8, 0, 0, 0, 1, 0, -1, 0, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 44, c0 = CFrame.new(-1.411987, 1.78, -1.412001, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 45, c0 = CFrame.new(1.411987, 1.78, -1.412001, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 46, c0 = CFrame.new(-1.411987, 1.78, 1.412001, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 47, c0 = CFrame.new(1.411987, 1.78, 1.412001, 1, 0, 0, 0, 0, 1, 0, -1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 48, c0 = CFrame.new(0, -1.8, 0, 1, 0, 0, 0, 0, -1, 0, 1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 49, c0 = CFrame.new(0, -1.8, 1.412001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 50, c0 = CFrame.new(0, -1.8, -1.412001, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 51, c0 = CFrame.new(-1.411987, -1.8, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 52, c0 = CFrame.new(1.411987, -1.8, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 53, c0 = CFrame.new(-1.411987, -1.78, 1.412001, 1, 0, 0, 0, 0, -1, 0, 1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 54, c0 = CFrame.new(1.411987, -1.78, 1.412001, 1, 0, 0, 0, 0, -1, 0, 1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 55, c0 = CFrame.new(-1.411987, -1.78, -1.412001, 1, 0, 0, 0, 0, -1, 0, 1, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 56, c0 = CFrame.new(1.411987, -1.78, -1.412001, 1, 0, 0, 0, 0, -1, 0, 1, 0), c1 = CFrame.new() },
		{ k = "Motor6D", n = "SproutJointL", h = 1, a = 1, b = 57, c0 = CFrame.new(-0.15, 1.7, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.22, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SproutJointR", h = 1, a = 1, b = 59, c0 = CFrame.new(0.15, 1.7, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.22, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 57, a = 57, b = 58, c0 = CFrame.new(-0.036285, 0.409015, -0.037287, 0.978148, -0.204753, 0.036103, 0.205888, 0.97808, -0.031142, -0.028936, 0.037895, 0.998863), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 59, a = 59, b = 60, c0 = CFrame.new(0.036285, 0.409014, 0.037287, 0.978148, 0.204753, 0.036103, -0.205888, 0.97808, 0.031142, -0.028936, -0.037895, 0.998863), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StudioFillLight", p = 1, range = 12, brightness = 0.85, color = Color3.new(1, 0.988235, 0.960784), shadows = true, enabled = true },
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
		{ n = "Studs_%s", p = 48, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 49, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 50, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 51, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 52, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 53, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 54, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 55, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 56, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 57, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 58, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 59, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 60, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
