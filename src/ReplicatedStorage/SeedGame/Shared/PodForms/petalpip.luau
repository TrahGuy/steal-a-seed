--!strict
--==============================================================================
-- POD FORM: Petalpip (greenhollow pods/PetalpipPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "greenhollow pods/PetalpipPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "greenhollow pods/PetalpipPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(5.065622, 3.634244, 4.817659), Height = 3.634244, PartCount = 42,
	Base = 0, Root = 1,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Common", Style = "OrbPlantBud", TextureStyle = "Studded", UnitType = "PetalpipPod" },
	Removed = { "FlatBase" },
	Parts = {
		{ n = "InnerOrb", s = "Block", z = Vector3.new(2.8, 2.9, 2.8), cf = CFrame.new(0.000002, 1.45, -0.106323, -0.999999, 0, 0, 0, 1, 0, -0.000002, 0, -1), c = Color3.fromRGB(124, 158, 86), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 1
		{ n = "ApexBudPeek", s = "Block", z = Vector3.new(0.55, 0.65, 0.55), cf = CFrame.new(0.000002, 3.199999, -0.106323, -0.999999, 0, 0, 0, 1, 0, -0.000002, 0, -1), c = Color3.fromRGB(232, 132, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 2
		{ n = "CoralPetal1_Root", s = "Block", z = Vector3.new(0.4, 0.4, 0.4), cf = CFrame.new(0.000002, 0.45, -1.456329, -0.999999, 0, 0, 0, 1, 0, -0.000002, 0, -1), c = Color3.fromRGB(232, 132, 106), m = Enum.Material.Plastic, t = 1, st = false }, -- 3
		{ n = "CoralPetal1_LowerPlate", s = "Block", z = Vector3.new(1.85, 1.45, 0.32), cf = CFrame.new(0.000002, 1.2, -1.676331, -0.999999, 0, 0, 0, 0.970295, 0.241922, -0.000002, 0.241922, -0.970296), c = Color3.fromRGB(232, 132, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "CoralPetal1_RimL1", s = "Wedge", z = Vector3.new(0.24, 1.45, 0.32), cf = CFrame.new(0.950003, 1.200001, -1.6763, 0, 0, 0.999999, 0.970295, -0.241922, 0, 0.241922, 0.970296, 0.000002), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "CoralPetal1_RimR1", s = "Wedge", z = Vector3.new(0.24, 1.45, 0.32), cf = CFrame.new(-0.949999, 1.200001, -1.676331, 0, 0, -0.999999, -0.970295, -0.241922, 0, -0.241922, 0.970296, -0.000002), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "CoralPetal1_UpperPlate", s = "Block", z = Vector3.new(1.7, 1.55, 0.32), cf = CFrame.new(0.000002, 2.376581, -1.228394, -0.999999, 0, 0, 0, 0.970295, -0.241922, -0.000002, -0.241922, -0.970296), c = Color3.fromRGB(232, 132, 106), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "CoralPetal1_RimL2", s = "Wedge", z = Vector3.new(0.24, 1.55, 0.32), cf = CFrame.new(0.880003, 2.376581, -1.228363, 0, 0, 0.999999, 0.970295, 0.241922, 0, -0.241922, 0.970296, 0.000002), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "CoralPetal1_RimR2", s = "Wedge", z = Vector3.new(0.24, 1.55, 0.32), cf = CFrame.new(-0.879997, 2.37658, -1.228394, 0, 0, -0.999999, -0.970295, 0.241922, 0, 0.241922, 0.970296, -0.000002), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "CoralPetal1_Crest", s = "Wedge", z = Vector3.new(1.4, 0.55, 0.34), cf = CFrame.new(0.000006, 3.312876, -1.399994, -0.999999, 0, 0, 0, -0.78801, 0.615661, -0.000002, 0.615662, 0.788011), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "Petal2_Root", s = "Block", z = Vector3.new(0.4, 0.4, 0.4), cf = CFrame.new(-1.283924, 0.45, -0.523499, -0.309017, 0, -0.951056, 0, 1, 0, 0.951056, 0, -0.309018), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, t = 1, st = false }, -- 11
		{ n = "Petal2_LowerPlate", s = "Block", z = Vector3.new(1.85, 1.45, 0.32), cf = CFrame.new(-1.493156, 1.2, -0.591492, -0.309017, 0.230081, -0.922805, 0, 0.970296, 0.241922, 0.951056, 0.074758, -0.299839), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "Petal2_RimL1", s = "Wedge", z = Vector3.new(0.24, 1.45, 0.32), cf = CFrame.new(-1.199591, 1.2, -1.494995, 0.230081, 0.922805, 0.309017, 0.970296, -0.241922, 0, 0.074758, 0.299839, -0.951056), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "Petal2_RimR1", s = "Wedge", z = Vector3.new(0.24, 1.45, 0.32), cf = CFrame.new(-1.786724, 1.199999, 0.312012, -0.230081, 0.922805, -0.309017, -0.970296, -0.241922, 0, -0.074758, 0.299839, 0.951056), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "Petal2_UpperPlate", s = "Block", z = Vector3.new(1.7, 1.55, 0.32), cf = CFrame.new(-1.067131, 2.376581, -0.453064, -0.309017, -0.230081, -0.922805, 0, 0.970295, -0.241922, 0.951056, -0.074758, -0.299839), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "Petal2_RimL2", s = "Wedge", z = Vector3.new(0.24, 1.55, 0.32), cf = CFrame.new(-0.795195, 2.376581, -1.290009, -0.230081, 0.922805, 0.309017, 0.970295, 0.241922, 0, -0.074758, 0.299839, -0.951056), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "Petal2_RimR2", s = "Wedge", z = Vector3.new(0.24, 1.55, 0.32), cf = CFrame.new(-1.339067, 2.376581, 0.383881, 0.230081, 0.922805, -0.309017, -0.970295, 0.241922, 0, 0.074758, 0.299839, 0.951056), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "Petal2_Crest", s = "Wedge", z = Vector3.new(1.4, 0.55, 0.34), cf = CFrame.new(-1.230345, 3.312877, -0.506104, -0.309017, 0.585528, 0.749442, 0, -0.78801, 0.615662, 0.951056, 0.190251, 0.24351), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "Petal3_Root", s = "Block", z = Vector3.new(0.4, 0.4, 0.4), cf = CFrame.new(-0.793507, 0.45, 0.98584, 0.809016, 0, -0.587785, 0, 1, 0, 0.587786, 0, 0.809016), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, t = 1, st = false }, -- 19
		{ n = "Petal3_LowerPlate", s = "Block", z = Vector3.new(1.85, 1.45, 0.32), cf = CFrame.new(-0.922815, 1.2, 1.163818, 0.809017, 0.142198, -0.570325, 0, 0.970295, 0.241922, 0.587786, -0.195719, 0.784985), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "Petal3_RimL1", s = "Wedge", z = Vector3.new(0.24, 1.45, 0.32), cf = CFrame.new(-1.691385, 1.199999, 0.605408, 0.142198, 0.570325, -0.809017, 0.970295, -0.241922, 0, -0.195719, -0.784985, -0.587787), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "Petal3_RimR1", s = "Wedge", z = Vector3.new(0.24, 1.45, 0.32), cf = CFrame.new(-0.154257, 1.2, 1.722198, -0.142198, 0.570325, 0.809017, -0.970295, -0.241922, 0, 0.195719, -0.784985, 0.587786), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "Petal3_UpperPlate", s = "Block", z = Vector3.new(1.7, 1.55, 0.32), cf = CFrame.new(-0.659519, 2.376581, 0.801422, 0.809017, -0.142198, -0.570325, 0, 0.970295, -0.241922, 0.587786, 0.195719, 0.784985), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "Petal3_RimL2", s = "Wedge", z = Vector3.new(0.24, 1.55, 0.32), cf = CFrame.new(-1.371458, 2.376581, 0.28418, -0.142198, 0.570325, -0.809017, 0.970295, 0.241922, 0, 0.195719, -0.784985, -0.587787), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "Petal3_RimR2", s = "Wedge", z = Vector3.new(0.24, 1.55, 0.32), cf = CFrame.new(0.052414, 2.376582, 1.318665, 0.142198, 0.570325, 0.809017, -0.970295, 0.241922, 0, -0.195719, -0.784985, 0.587786), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "Petal3_Crest", s = "Wedge", z = Vector3.new(1.4, 0.55, 0.34), cf = CFrame.new(-0.760393, 3.312876, 0.940247, 0.809017, 0.361876, 0.463181, 0, -0.78801, 0.615662, 0.587787, -0.49808, -0.637513), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "Petal4_Root", s = "Block", z = Vector3.new(0.4, 0.4, 0.4), cf = CFrame.new(0.793512, 0.45, 0.98587, 0.809016, 0, 0.587785, 0, 1, 0, -0.587784, 0, 0.809018), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, t = 1, st = false }, -- 27
		{ n = "Petal4_LowerPlate", s = "Block", z = Vector3.new(1.85, 1.45, 0.32), cf = CFrame.new(0.922825, 1.2, 1.163849, 0.809016, -0.142198, 0.570325, 0, 0.970295, 0.241922, -0.587784, -0.195719, 0.784986), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "Petal4_RimL1", s = "Wedge", z = Vector3.new(0.24, 1.45, 0.32), cf = CFrame.new(0.154261, 1.200001, 1.722198, -0.142198, -0.570325, -0.809016, 0.970295, -0.241922, 0, -0.195719, -0.784986, 0.587784), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "Petal4_RimR1", s = "Wedge", z = Vector3.new(0.24, 1.45, 0.32), cf = CFrame.new(1.691391, 1.2, 0.605438, 0.142198, -0.570325, 0.809016, -0.970295, -0.241922, 0, 0.195719, -0.784987, -0.587784), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "Petal4_UpperPlate", s = "Block", z = Vector3.new(1.7, 1.55, 0.32), cf = CFrame.new(0.659531, 2.376581, 0.801453, 0.809016, 0.142198, 0.570325, 0, 0.970295, -0.241922, -0.587784, 0.195719, 0.784986), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "Petal4_RimL2", s = "Wedge", z = Vector3.new(0.24, 1.55, 0.32), cf = CFrame.new(-0.052408, 2.376581, 1.318665, 0.142198, -0.570325, -0.809016, 0.970295, 0.241922, 0, 0.195719, -0.784986, 0.587784), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "Petal4_RimR2", s = "Wedge", z = Vector3.new(0.24, 1.55, 0.32), cf = CFrame.new(1.371462, 2.376581, 0.28421, -0.142198, -0.570325, 0.809016, -0.970295, 0.241922, 0, -0.195719, -0.784987, -0.587784), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
		{ n = "Petal4_Crest", s = "Wedge", z = Vector3.new(1.4, 0.55, 0.34), cf = CFrame.new(0.760395, 3.312877, 0.940277, 0.809016, -0.361877, -0.463181, 0, -0.78801, 0.615661, -0.587784, -0.498081, -0.637515), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 34
		{ n = "Petal5_Root", s = "Block", z = Vector3.new(0.4, 0.4, 0.4), cf = CFrame.new(1.283926, 0.45, -0.523468, -0.309017, 0, 0.951056, 0, 1, 0, -0.951057, 0, -0.309016), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, t = 1, st = false }, -- 35
		{ n = "Petal5_LowerPlate", s = "Block", z = Vector3.new(1.85, 1.45, 0.32), cf = CFrame.new(1.493158, 1.2, -0.591461, -0.309017, -0.230081, 0.922805, 0, 0.970295, 0.241922, -0.951057, 0.074758, -0.299836), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 36
		{ n = "Petal5_RimL1", s = "Wedge", z = Vector3.new(0.24, 1.45, 0.32), cf = CFrame.new(1.786726, 1.200001, 0.312042, -0.230081, -0.922805, 0.309017, 0.970295, -0.241922, 0, 0.074758, 0.299836, 0.951057), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 37
		{ n = "Petal5_RimR1", s = "Wedge", z = Vector3.new(0.24, 1.45, 0.32), cf = CFrame.new(1.199596, 1.2, -1.494965, 0.230081, -0.922805, -0.309017, -0.970295, -0.241922, 0, -0.074758, 0.299836, -0.951057), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 38
		{ n = "Petal5_UpperPlate", s = "Block", z = Vector3.new(1.7, 1.55, 0.32), cf = CFrame.new(1.067137, 2.376581, -0.453033, -0.309017, 0.230081, 0.922805, 0, 0.970296, -0.241922, -0.951057, -0.074758, -0.299836), c = Color3.fromRGB(206, 224, 132), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 39
		{ n = "Petal5_RimL2", s = "Wedge", z = Vector3.new(0.24, 1.55, 0.32), cf = CFrame.new(1.339071, 2.376582, 0.383881, 0.230081, -0.922805, 0.309017, 0.970295, 0.241922, 0, -0.074758, 0.299836, 0.951057), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 40
		{ n = "Petal5_RimR2", s = "Wedge", z = Vector3.new(0.24, 1.55, 0.32), cf = CFrame.new(0.795202, 2.376582, -1.289978, -0.230081, -0.922805, -0.309017, -0.970296, 0.241922, 0, 0.074758, 0.299836, -0.951057), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 41
		{ n = "Petal5_Crest", s = "Wedge", z = Vector3.new(1.4, 0.55, 0.34), cf = CFrame.new(1.230345, 3.312879, -0.506073, -0.309017, -0.585529, -0.749442, 0, -0.788011, 0.615661, -0.951057, 0.190249, 0.243508), c = Color3.fromRGB(250, 246, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 42
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 1.749999, 0, 0.999999, 0, 0.000002, 0, 1, 0, 0.000002, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "PetalJoint1", h = 1, a = 1, b = 3, c0 = CFrame.new(0, -1, 1.35, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "PetalJoint2", h = 1, a = 1, b = 11, c0 = CFrame.new(1.283926, -1, 0.417173, 0.309017, 0, 0.951057, 0, 1, 0, -0.951057, 0, 0.309017), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "PetalJoint3", h = 1, a = 1, b = 19, c0 = CFrame.new(0.79351, -1, -1.092173, -0.809017, 0, 0.587785, 0, 1, 0, -0.587785, 0, -0.809017), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "PetalJoint4", h = 1, a = 1, b = 27, c0 = CFrame.new(-0.79351, -1, -1.092173, -0.809017, 0, -0.587785, 0, 1, 0, 0.587785, 0, -0.809017), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "PetalJoint5", h = 1, a = 1, b = 35, c0 = CFrame.new(-1.283926, -1, 0.417173, 0.309017, 0, -0.951056, 0, 1, 0, 0.951056, 0, 0.309017), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 4, c0 = CFrame.new(0, 0.75, 0.220001, 0.999999, -0.000001, 0.000001, 0, 0.970295, 0.241922, 0.000002, -0.241922, 0.970295), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 7, c0 = CFrame.new(0, 1.926581, -0.227936, 0.999999, 0, 0.000002, 0, 0.970295, -0.241922, 0.000002, 0.241922, 0.970295), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(-0.950001, 0, 0, -0.000001, -0.000001, -0.999999, 1, 0, 0.000001, 0, -1, -0.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 6, c0 = CFrame.new(0.950001, 0, 0, 0.000001, -0.000002, 0.999999, -1, 0, -0.000001, 0, -1, 0.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 8, c0 = CFrame.new(-0.880001, 0, 0, 0, -0.000002, -0.999999, 1, 0, 0, 0, -1, -0.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 9, c0 = CFrame.new(0.879999, 0, 0, 0, -0.000002, 0.999999, -1, 0, 0, 0, -1, 0.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 10, c0 = CFrame.new(-0.000004, 0.949997, -0.060028, 0.999999, -0.000001, -0.000002, 0, -0.913545, 0.406736, 0.000002, -0.406737, -0.913545), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 12, c0 = CFrame.new(0, 0.75, 0.220001, 0.999999, 0, -0.000002, 0, 0.970295, 0.241921, -0.000002, -0.241922, 0.970295), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 15, c0 = CFrame.new(0, 1.926581, -0.227951, 0.999999, -0.000001, -0.000001, 0, 0.970295, -0.241922, -0.000002, 0.241922, 0.970295), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 13, c0 = CFrame.new(-0.950012, 0, 0, 0, 0.000002, -0.999999, 1, 0, 0, 0, -0.999999, 0.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 14, c0 = CFrame.new(0.950012, -0.000002, 0, 0, 0.000002, 0.999999, -1, 0, 0, 0, -0.999999, -0.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 16, c0 = CFrame.new(-0.880005, 0.000002, 0, -0.000001, 0.000002, -0.999999, 0.999999, 0, 0.000001, 0, -1, 0.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 17, c0 = CFrame.new(0.880035, -0.000002, -0.000008, 0, 0.000001, 0.999999, -0.999999, 0, -0.000001, 0, -1, -0.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 18, c0 = CFrame.new(0, 0.950001, -0.05999, 0.999999, 0.000001, 0.000001, -0.000001, -0.913545, 0.406737, -0.000001, -0.406736, -0.913545), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 20, c0 = CFrame.new(0, 0.75, 0.220001, 1.000001, 0, 0.000001, 0, 0.970295, 0.241922, 0.000001, -0.241922, 0.970294), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 23, c0 = CFrame.new(0, 1.926581, -0.227936, 1.000001, 0.000001, 0.000001, 0, 0.970295, -0.241922, 0.000001, 0.241921, 0.970294), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 21, c0 = CFrame.new(-0.950012, 0, -0.000031, 0, -0.000001, -1.000001, 1, 0, 0, 0, -0.999998, -0.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 22, c0 = CFrame.new(0.949982, 0.000004, 0, 0, -0.000001, 1.000001, -0.999999, 0, 0, 0, -0.999998, 0.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 24, c0 = CFrame.new(-0.880005, 0, 0, 0.000001, -0.000001, -1.000001, 0.999999, 0.000001, -0.000001, -0.000001, -0.999998, -0.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 25, c0 = CFrame.new(0.880005, 0, 0, -0.000001, -0.000001, 1.000001, -0.999999, 0.000001, 0.000001, 0.000001, -0.999998, 0.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 26, c0 = CFrame.new(0, 0.949989, -0.059998, 1.000001, -0.000001, -0.000001, 0.000001, -0.913545, 0.406737, 0.000001, -0.406735, -0.913544), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 28, c0 = CFrame.new(0, 0.75, 0.219971, 0.999997, 0, 0, 0, 0.970295, 0.241922, 0, -0.241922, 0.970297), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 31, c0 = CFrame.new(0, 1.92658, -0.227966, 0.999997, 0, 0, 0, 0.970295, -0.241922, 0, 0.241922, 0.970297), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 29, c0 = CFrame.new(-0.949982, 0, 0, 0, 0, -0.999997, 1, 0, 0, 0, -1.000001, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 30, c0 = CFrame.new(0.950012, 0, 0.000031, 0, 0, 0.999997, -1, 0, 0, 0, -1.000001, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 31, a = 31, b = 32, c0 = CFrame.new(-0.880005, 0, -0.000031, 0, 0, -0.999997, 1, 0, 0, 0.000001, -1.000001, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 31, a = 31, b = 33, c0 = CFrame.new(0.87999, 0, 0, 0, 0, 0.999997, -1, -0.000001, 0, -0.000001, -1.000001, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 31, a = 31, b = 34, c0 = CFrame.new(0, 0.950005, -0.059998, 0.999997, 0, 0, 0, -0.913545, 0.406736, 0, -0.406737, -0.913546), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 35, a = 35, b = 36, c0 = CFrame.new(0, 0.75, 0.220001, 1.000001, 0, -0.000001, 0, 0.970295, 0.241922, -0.000001, -0.241921, 0.970294), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 35, a = 35, b = 39, c0 = CFrame.new(0, 1.926581, -0.227943, 1.000001, 0, -0.000001, 0, 0.970295, -0.241921, -0.000001, 0.241922, 0.970293), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 37, c0 = CFrame.new(-0.950012, 0.000002, 0, 0, 0.000001, -1.000001, 0.999999, -0.000001, 0, 0.000001, -0.999998, 0.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 38, c0 = CFrame.new(0.950012, 0.000002, 0, 0, 0.000001, 1.000001, -0.999999, -0.000001, 0, -0.000001, -0.999998, -0.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 40, c0 = CFrame.new(-0.880005, 0, 0, 0, 0.000001, -1.000001, 1, 0, 0, 0, -0.999998, 0.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 41, c0 = CFrame.new(0.880005, 0.000002, 0, 0, 0.000001, 1.000001, -1, 0, 0, 0, -0.999998, -0.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 42, c0 = CFrame.new(0, 0.950003, -0.059998, 1.000001, 0.000001, 0.000001, 0, -0.913545, 0.406737, -0.000001, -0.406736, -0.913543), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StudioFillLight", p = 1, range = 12, brightness = 0.85, color = Color3.new(1, 0.988235, 0.94902), shadows = true, enabled = true },
	},
	Emitters = {},
	Textures = {
		{ n = "Studs_%s", p = 1, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 2, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 4, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 5, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 6, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 7, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 8, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 9, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 10, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 12, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 13, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 14, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 15, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 16, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 17, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 18, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 20, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 21, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 22, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 23, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 24, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 25, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 26, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 28, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 29, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 30, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 31, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 32, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 33, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 34, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 36, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 37, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 38, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 39, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 40, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 41, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 42, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 6.641425, v = 6.641425, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
