--!strict
--==============================================================================
-- POD FORM: Bogbonnet (tanglemire pods/BogbonnetPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "tanglemire pods/BogbonnetPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "tanglemire pods/BogbonnetPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(2.746292, 3.556721, 3.213898), Height = 3.556721, PartCount = 31,
	Base = 0, Root = 2,
	Attributes = {},
	Owner = { IsPod = true, OpenAmount = 0, OpenDuration = 0.45, PartCount = 32, Rarity = "Rare", Species = "Bogbonnet", Unit = 2.4 },
	Removed = { "SeedBase" },
	Parts = {
		{ n = "RootHusk", s = "Block", z = Vector3.new(2.016265, 0.834317, 1.842449), cf = CFrame.new(0, 0.660501, 0.355469, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(70, 113, 87), m = Enum.Material.Plastic }, -- 1
		{ n = "PodCore", s = "Block", z = Vector3.new(2.051028, 2.363897, 1.946739), cf = CFrame.new(0, 1.877212, 0.355469, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic }, -- 2
		{ n = "SideLeafFold1", s = "Wedge", z = Vector3.new(0.417158, 1.668633, 1.703397), cf = CFrame.new(-0.97337, 1.668633, 0.355469, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(70, 113, 87), m = Enum.Material.Plastic }, -- 3
		{ n = "SideLeafFold2", s = "Wedge", z = Vector3.new(0.417158, 1.668633, 1.703397), cf = CFrame.new(0.97337, 1.668633, 0.355469, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(70, 113, 87), m = Enum.Material.Plastic }, -- 4
		{ n = "BackLeafFold", s = "Block", z = Vector3.new(1.73816, 1.772923, 0.312869), cf = CFrame.new(0, 1.842449, 1.311462, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(53, 100, 80), m = Enum.Material.Plastic }, -- 5
		{ n = "ClosedLeafFlap1", s = "Block", z = Vector3.new(1.077659, 1.599107, 0.347632), cf = CFrame.new(-0.417158, 1.703396, -0.687439, 0.970296, 0.241922, 0, -0.241922, 0.970296, 0, 0, 0, 1), c = Color3.fromRGB(70, 113, 87), m = Enum.Material.Plastic }, -- 6
		{ n = "ClosedLeafFlap2", s = "Block", z = Vector3.new(1.077659, 1.599107, 0.347632), cf = CFrame.new(0.417158, 1.703396, -0.687439, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic }, -- 7
		{ n = "ClosureStitch", s = "Block", z = Vector3.new(0.086908, 1.008132, 0.382395), cf = CFrame.new(0, 1.668633, -0.687439, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(196, 210, 162), m = Enum.Material.Plastic }, -- 8
		{ n = "SeedCap", s = "Block", z = Vector3.new(2.572476, 0.417158, 2.50295), cf = CFrame.new(0, 3.163451, 0.355469, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic }, -- 9
		{ n = "FoldedHoodFront", s = "Block", z = Vector3.new(2.711529, 0.417158, 1.460054), cf = CFrame.new(0, 3.059161, -0.687439, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic }, -- 10
		{ n = "HoodCurtain1", s = "Block", z = Vector3.new(0.382395, 1.460054, 2.363897), cf = CFrame.new(-1.181948, 2.537713, -0.131226, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic }, -- 11
		{ n = "SageBrimSide1", s = "Block", z = Vector3.new(0.312869, 1.042896, 0.312869), cf = CFrame.new(-1.181948, 2.433424, -1.347931, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(196, 210, 162), m = Enum.Material.Plastic }, -- 12
		{ n = "SageBrimArch1", s = "Block", z = Vector3.new(1.390528, 0.260724, 0.312869), cf = CFrame.new(-0.660501, 2.743293, -1.364807, 0.987688, -0.156434, 0, 0.141778, 0.89515, 0.422618, -0.066112, -0.417415, 0.906308), c = Color3.fromRGB(196, 210, 162), m = Enum.Material.Plastic }, -- 13
		{ n = "HoodCurtain2", s = "Block", z = Vector3.new(0.382395, 1.460054, 2.363897), cf = CFrame.new(1.181948, 2.537713, -0.131226, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic }, -- 14
		{ n = "SageBrimSide2", s = "Block", z = Vector3.new(0.312869, 1.042896, 0.312869), cf = CFrame.new(1.181948, 2.433424, -1.347931, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(196, 210, 162), m = Enum.Material.Plastic }, -- 15
		{ n = "SageBrimArch2", s = "Block", z = Vector3.new(1.390528, 0.260724, 0.312869), cf = CFrame.new(0.660501, 2.743293, -1.364807, 0.987688, 0.156434, 0, -0.141778, 0.89515, 0.422618, 0.066112, -0.417415, 0.906308), c = Color3.fromRGB(196, 210, 162), m = Enum.Material.Plastic }, -- 16
		{ n = "HoodPleat1", s = "Block", z = Vector3.new(0.086908, 0.062574, 1.042896), cf = CFrame.new(-0.695263, 3.260801, -0.781464, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c = Color3.fromRGB(53, 100, 80), m = Enum.Material.Plastic }, -- 17
		{ n = "HoodPleat2", s = "Block", z = Vector3.new(0.086908, 0.062574, 1.042896), cf = CFrame.new(0, 3.260801, -0.781464, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c = Color3.fromRGB(53, 100, 80), m = Enum.Material.Plastic }, -- 18
		{ n = "HoodPleat3", s = "Block", z = Vector3.new(0.086908, 0.062574, 1.042896), cf = CFrame.new(0.695263, 3.260801, -0.781464, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c = Color3.fromRGB(53, 100, 80), m = Enum.Material.Plastic }, -- 19
		{ n = "MossRoot1", s = "Block", z = Vector3.new(0.590974, 0.486685, 0.590974), cf = CFrame.new(0.460611, 0.243342, 1.153259, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 20
		{ n = "MossTuft1", s = "Wedge", z = Vector3.new(0.486685, 0.660501, 0.347632), cf = CFrame.new(0.504065, 0.625737, 1.228516, 0.814977, 0.331189, 0.475528, -0.197736, 0.930274, -0.309017, -0.544714, 0.157813, 0.823639), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 21
		{ n = "MossRoot2", s = "Block", z = Vector3.new(0.590974, 0.486685, 0.590974), cf = CFrame.new(0.921225, 0.243342, 0.355469, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 22
		{ n = "MossTuft2", s = "Wedge", z = Vector3.new(0.486685, 0.660501, 0.347632), cf = CFrame.new(1.008133, 0.625737, 0.355469, 0.064248, 0.302264, 0.951057, 0.197736, 0.930274, -0.309017, -0.978148, 0.207912, 0), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 23
		{ n = "MossRoot3", s = "Block", z = Vector3.new(0.590974, 0.486685, 0.590974), cf = CFrame.new(0.460611, 0.243342, -0.442322, -0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 24
		{ n = "MossTuft3", s = "Wedge", z = Vector3.new(0.486685, 0.660501, 0.347632), cf = CFrame.new(0.504065, 0.625737, -0.517578, -0.879225, -0.028925, 0.475528, -0.197736, 0.930274, -0.309017, -0.433433, -0.365724, -0.823639), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 25
		{ n = "MossRoot4", s = "Block", z = Vector3.new(0.590974, 0.486685, 0.590974), cf = CFrame.new(-0.460611, 0.243342, -0.442322, -0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, -0.866025), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 26
		{ n = "MossTuft4", s = "Wedge", z = Vector3.new(0.486685, 0.660501, 0.347632), cf = CFrame.new(-0.504065, 0.625737, -0.517578, -0.879225, 0.028925, -0.475528, 0.197736, 0.930274, -0.309017, 0.433433, -0.365724, -0.823639), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 27
		{ n = "MossRoot5", s = "Block", z = Vector3.new(0.590974, 0.486685, 0.590974), cf = CFrame.new(-0.921225, 0.243342, 0.355469, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 28
		{ n = "MossTuft5", s = "Wedge", z = Vector3.new(0.486685, 0.660501, 0.347632), cf = CFrame.new(-1.008133, 0.625737, 0.355469, 0.064248, -0.302264, -0.951057, -0.197736, 0.930274, -0.309017, 0.978148, 0.207912, 0), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 29
		{ n = "MossRoot6", s = "Block", z = Vector3.new(0.590974, 0.486685, 0.590974), cf = CFrame.new(-0.460611, 0.243342, 1.153259, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 30
		{ n = "MossTuft6", s = "Wedge", z = Vector3.new(0.486685, 0.660501, 0.347632), cf = CFrame.new(-0.504065, 0.625737, 1.228516, 0.814976, -0.331189, -0.475528, 0.197736, 0.930274, -0.309017, 0.544715, 0.157813, 0.823639), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic }, -- 31
	},
	Joints = {
		{ k = "Weld", n = "PodCoreWeld", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 1.216712, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SideLeafFold1Weld", h = 2, a = 2, b = 3, c0 = CFrame.new(-0.973369, -0.208579, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SideLeafFold2Weld", h = 2, a = 2, b = 4, c0 = CFrame.new(0.973369, -0.208579, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "BackLeafFoldWeld", h = 2, a = 2, b = 5, c0 = CFrame.new(0, -0.034763, 0.955988, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "ClosedLeafFlap1Weld", h = 2, a = 2, b = 6, c0 = CFrame.new(-0.417158, -0.173816, -1.042896, 0.970296, 0.241922, 0, -0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "ClosedLeafFlap2Weld", h = 2, a = 2, b = 7, c0 = CFrame.new(0.417158, -0.173816, -1.042896, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "ClosureStitchWeld", h = 2, a = 2, b = 8, c0 = CFrame.new(0, -0.208579, -1.042896, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidHinge", h = 2, a = 2, b = 9, c0 = CFrame.new(0, 1.147185, 1.042896, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.139053, 1.042896, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "FoldedHoodFrontWeld", h = 9, a = 9, b = 10, c0 = CFrame.new(0, -0.10429, -1.042896, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodCurtain1Weld", h = 9, a = 9, b = 11, c0 = CFrame.new(-1.181948, -0.625737, -0.486685, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodCurtain2Weld", h = 9, a = 9, b = 14, c0 = CFrame.new(1.181948, -0.625737, -0.486685, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SageBrimArch1Weld", h = 10, a = 10, b = 13, c0 = CFrame.new(-0.660501, 0, -0.747408, 0.987688, -0.156434, 0, 0.156434, 0.987688, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SageBrimArch2Weld", h = 10, a = 10, b = 16, c0 = CFrame.new(0.660501, 0, -0.747408, 0.987688, 0.156434, 0, -0.156434, 0.987688, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodPleat1Weld", h = 10, a = 10, b = 17, c0 = CFrame.new(-0.695264, 0.222484, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodPleat2Weld", h = 10, a = 10, b = 18, c0 = CFrame.new(0, 0.222484, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "HoodPleat3Weld", h = 10, a = 10, b = 19, c0 = CFrame.new(0.695264, 0.222484, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SageBrimSide1Weld", h = 11, a = 11, b = 12, c0 = CFrame.new(0, -0.10429, -1.216712, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SageBrimSide2Weld", h = 14, a = 14, b = 15, c0 = CFrame.new(0, -0.10429, -1.216712, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossTuft1Weld", h = 20, a = 20, b = 21, c0 = CFrame.new(0, 0.382395, 0.086908, 0.978148, 0.207912, 0, -0.197736, 0.930274, -0.309017, -0.064248, 0.302264, 0.951056), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossTuft2Weld", h = 22, a = 22, b = 23, c0 = CFrame.new(0, 0.382395, 0.086908, 0.978148, -0.207912, 0, 0.197736, 0.930274, -0.309017, 0.064248, 0.302264, 0.951057), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossTuft3Weld", h = 24, a = 24, b = 25, c0 = CFrame.new(0, 0.382395, 0.086908, 0.978148, 0.207912, 0, -0.197736, 0.930274, -0.309017, -0.064248, 0.302264, 0.951057), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossTuft4Weld", h = 26, a = 26, b = 27, c0 = CFrame.new(0, 0.382395, 0.086908, 0.978148, -0.207912, 0, 0.197736, 0.930274, -0.309017, 0.064248, 0.302264, 0.951056), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossTuft5Weld", h = 28, a = 28, b = 29, c0 = CFrame.new(0, 0.382395, 0.086908, 0.978148, 0.207912, 0, -0.197736, 0.930274, -0.309017, -0.064248, 0.302264, 0.951057), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossTuft6Weld", h = 30, a = 30, b = 31, c0 = CFrame.new(0, 0.382395, 0.086908, 0.978148, -0.207912, 0, 0.197736, 0.930274, -0.309017, 0.064248, 0.302264, 0.951057), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
