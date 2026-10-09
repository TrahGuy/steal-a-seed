--!strict
--==============================================================================
-- POD FORM: Cinderpaw (emberroot pods/CinderpawPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "emberroot pods/CinderpawPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "emberroot pods/CinderpawPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(5.326504, 1.531573, 4.210052), Height = 1.531573, PartCount = 52,
	Base = 0, Root = 1,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Rare", Style = "VolcanicPaw", TextureStyle = "Studded", UnitType = "CinderpawPod" },
	Removed = { "FlatBase", "BaseRim" },
	Parts = {
		{ n = "PawCore", s = "Block", z = Vector3.new(2.4, 0.82, 1.8), cf = CFrame.new(-0.000002, 0.488191, 0.555023, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(36, 28, 26), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "MagmaHeart", s = "Block", z = Vector3.new(1.6, 0.65, 1.3), cf = CFrame.new(-0.000002, 0.488191, 0.555023, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 2
		{ n = "MagmaCoreHot", s = "Block", z = Vector3.new(0.85, 0.45, 0.85), cf = CFrame.new(-0.000002, 0.488191, 0.555023, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(255, 175, 60), m = Enum.Material.Neon, st = false, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 3
		{ n = "CarpalHeelPad", s = "Block", z = Vector3.new(3, 0.95, 1.6), cf = CFrame.new(-0.000002, 0.608191, 1.305023, -1.000001, 0, 0, 0, 1.000002, 0, 0, 0, -1.000001), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 4
		{ n = "DorsalHood", s = "Block", z = Vector3.new(3.2, 0.44, 1.4), cf = CFrame.new(-0.000002, 1.008192, 0.975037, -1.000001, 0, 0, 0, 0.978149, 0.207912, 0, 0.207912, -0.978148), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "DorsalRidge", s = "Block", z = Vector3.new(0.85, 0.26, 1.4), cf = CFrame.new(-0.000002, 1.202593, 1.118591, -1.000001, 0, 0, 0, 0.956306, 0.292372, 0, 0.292372, -0.956305), c = Color3.fromRGB(72, 58, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "TransverseMagmaCrack", s = "Block", z = Vector3.new(2.8, 0.12, 0.22), cf = CFrame.new(-0.000002, 0.968192, 0.705017, -1.000001, 0, 0, 0, 1.000002, 0, 0, 0, -1.000001), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 7
		{ n = "Digit1Root", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(1.349998, 0.638191, 0.405029, -0.743145, 0, 0.669131, 0, 1.000001, 0, -0.669131, 0, -0.743145), c = Color3.fromRGB(36, 28, 26), m = Enum.Material.Plastic, t = 1, st = false }, -- 8
		{ n = "Digit1_KnucklePlate", s = "Block", z = Vector3.new(0.72, 0.48, 0.651), cf = CFrame.new(1.53331, 0.697899, 0.143768, -0.758977, -0.049232, 0.649255, -0.26745, 0.93271, -0.241922, -0.593655, -0.357256, -0.721071), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "Digit1_MidPlate", s = "Block", z = Vector3.new(0.6336, 0.4, 0.682), cf = CFrame.new(1.840582, 0.528543, -0.17276, -0.723082, -0.308474, 0.618059, -0.398945, 0.916932, -0.009093, -0.563912, -0.253146, -0.78608), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "Digit1_Ridge", s = "Block", z = Vector3.new(0.34848, 0.18, 0.5797), cf = CFrame.new(1.793694, 0.667916, -0.211243, -0.723082, -0.308474, 0.618059, -0.398945, 0.916932, -0.009093, -0.563912, -0.253146, -0.78608), c = Color3.fromRGB(72, 58, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "Digit1_EmberTip", s = "Block", z = Vector3.new(0.5184, 0.34, 0.589), cf = CFrame.new(2.20186, 0.377244, -0.528992, -0.723082, -0.589123, 0.360677, -0.398945, 0.782421, 0.478188, -0.563912, 0.201879, -0.800781), c = Color3.fromRGB(198, 68, 24), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "Digit1_TalonHook", s = "Wedge", z = Vector3.new(0.46656, 0.28, 0.36), cf = CFrame.new(2.347172, 0.421052, -0.746307, 0.723082, 0.589122, 0.360678, 0.398945, -0.782421, 0.478188, 0.563912, -0.201879, -0.800781), c = Color3.fromRGB(198, 68, 24), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "Digit1_GlowVein", s = "Block", z = Vector3.new(0.23328, 0.08, 0.38285), cf = CFrame.new(2.145594, 0.490262, -0.536774, -0.723082, -0.589123, 0.360677, -0.398945, 0.782421, 0.478188, -0.563912, 0.201879, -0.800781), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 14
		{ n = "Digit2Root", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(0.699999, 0.638191, 0.155029, -0.933581, 0, 0.358368, 0, 1.000001, 0, -0.358368, 0, -0.933581), c = Color3.fromRGB(36, 28, 26), m = Enum.Material.Plastic, t = 1, st = false }, -- 15
		{ n = "Digit2_KnucklePlate", s = "Block", z = Vector3.new(0.78, 0.48, 0.756), cf = CFrame.new(0.810966, 0.709368, -0.188416, -0.934012, -0.062215, 0.351784, -0.136616, 0.972076, -0.190809, -0.330089, -0.226277, -0.916429), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "Digit2_MidPlate", s = "Block", z = Vector3.new(0.6864, 0.4, 0.792), cf = CFrame.new(1.00618, 0.547182, -0.673676, -0.921589, -0.21027, 0.326283, -0.205298, 0.977422, 0.050025, -0.329435, -0.020883, -0.943948), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "Digit2_Ridge", s = "Block", z = Vector3.new(0.37752, 0.18, 0.6732), cf = CFrame.new(0.974218, 0.69575, -0.676849, -0.921589, -0.21027, 0.326283, -0.205298, 0.977422, 0.050025, -0.329435, -0.020883, -0.943948), c = Color3.fromRGB(72, 58, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "Digit2_EmberTip", s = "Block", z = Vector3.new(0.5616, 0.34, 0.684), cf = CFrame.new(1.231052, 0.420113, -1.223572, -0.921589, -0.351223, 0.165278, -0.205298, 0.802392, 0.560378, -0.329435, 0.482507, -0.81158), c = Color3.fromRGB(198, 68, 24), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "Digit2_TalonHook", s = "Wedge", z = Vector3.new(0.50544, 0.28, 0.36), cf = CFrame.new(1.31197, 0.504711, -1.502625, 0.921589, 0.351223, 0.165278, 0.205298, -0.802392, 0.560378, 0.329435, -0.482507, -0.81158), c = Color3.fromRGB(198, 68, 24), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "Digit2_GlowVein", s = "Block", z = Vector3.new(0.25272, 0.08, 0.4446), cf = CFrame.new(1.195518, 0.538815, -1.19812, -0.921589, -0.351223, 0.165278, -0.205298, 0.802392, 0.560378, -0.329435, 0.482507, -0.81158), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 21
		{ n = "Digit3Root", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(-0.000002, 0.638191, 0.035034, -1.000001, 0, 0, 0, 1.000001, 0, 0, 0, -1.000001), c = Color3.fromRGB(36, 28, 26), m = Enum.Material.Plastic, t = 1, st = false }, -- 22
		{ n = "Digit3_KnucklePlate", s = "Block", z = Vector3.new(0.84, 0.48, 0.819), cf = CFrame.new(-0.000002, 0.725536, -0.349426, -1.000001, 0, 0, 0, 0.99027, -0.139173, 0, -0.139173, -0.990269), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "Digit3_MidPlate", s = "Block", z = Vector3.new(0.7392, 0.4, 0.858), cf = CFrame.new(-0.000004, 0.584053, -0.925018, -1.000001, 0, 0, 0, 0.994524, 0.104529, 0, 0.104529, -0.994523), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "Digit3_Ridge", s = "Block", z = Vector3.new(0.40656, 0.18, 0.7293), cf = CFrame.new(-0.000002, 0.73522, -0.909119, -1.000001, 0, 0, 0, 0.994524, 0.104529, 0, 0.104529, -0.994523), c = Color3.fromRGB(72, 58, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "Digit3_EmberTip", s = "Block", z = Vector3.new(0.6048, 0.34, 0.741), cf = CFrame.new(-0.000002, 0.491296, -1.573181, -1.000001, 0, 0, 0, 0.788012, 0.615662, 0, 0.615662, -0.788011), c = Color3.fromRGB(198, 68, 24), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "Digit3_TalonHook", s = "Wedge", z = Vector3.new(0.54432, 0.28, 0.36), cf = CFrame.new(-0.000004, 0.607884, -1.877014, 1.000001, 0, 0, 0, -0.788012, 0.615662, 0, -0.615662, -0.788011), c = Color3.fromRGB(198, 68, 24), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "Digit3_GlowVein", s = "Block", z = Vector3.new(0.27216, 0.08, 0.48165), cf = CFrame.new(-0.000004, 0.610484, -1.530823, -1.000001, 0, 0, 0, 0.788012, 0.615662, 0, 0.615662, -0.788011), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 28
		{ n = "Digit4Root", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(-0.700003, 0.638191, 0.155029, -0.933581, 0, -0.358368, 0, 1.000001, 0, 0.358368, 0, -0.933581), c = Color3.fromRGB(36, 28, 26), m = Enum.Material.Plastic, t = 1, st = false }, -- 29
		{ n = "Digit4_KnucklePlate", s = "Block", z = Vector3.new(0.78, 0.48, 0.756), cf = CFrame.new(-0.810966, 0.709368, -0.188416, -0.934012, 0.062215, -0.351784, 0.136616, 0.972076, -0.190809, 0.330089, -0.226277, -0.916429), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "Digit4_MidPlate", s = "Block", z = Vector3.new(0.6864, 0.4, 0.792), cf = CFrame.new(-1.006182, 0.547182, -0.673676, -0.921589, 0.21027, -0.326283, 0.205298, 0.977422, 0.050025, 0.329435, -0.020883, -0.943948), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "Digit4_Ridge", s = "Block", z = Vector3.new(0.37752, 0.18, 0.6732), cf = CFrame.new(-0.97422, 0.69575, -0.676849, -0.921589, 0.21027, -0.326283, 0.205298, 0.977422, 0.050025, 0.329435, -0.020883, -0.943948), c = Color3.fromRGB(72, 58, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "Digit4_EmberTip", s = "Block", z = Vector3.new(0.5616, 0.34, 0.684), cf = CFrame.new(-1.231052, 0.420113, -1.223541, -0.921589, 0.351223, -0.165278, 0.205298, 0.802392, 0.560378, 0.329435, 0.482507, -0.81158), c = Color3.fromRGB(198, 68, 24), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
		{ n = "Digit4_TalonHook", s = "Wedge", z = Vector3.new(0.50544, 0.28, 0.36), cf = CFrame.new(-1.31197, 0.504711, -1.502625, 0.921589, -0.351223, -0.165278, -0.205298, -0.802392, 0.560378, -0.329435, -0.482507, -0.81158), c = Color3.fromRGB(198, 68, 24), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 34
		{ n = "Digit4_GlowVein", s = "Block", z = Vector3.new(0.25272, 0.08, 0.4446), cf = CFrame.new(-1.195517, 0.538815, -1.19812, -0.921589, 0.351223, -0.165278, 0.205298, 0.802392, 0.560378, 0.329435, 0.482507, -0.81158), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 35
		{ n = "Digit5Root", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(-1.350002, 0.638191, 0.405029, -0.743145, 0, -0.669131, 0, 1.000001, 0, 0.669131, 0, -0.743145), c = Color3.fromRGB(36, 28, 26), m = Enum.Material.Plastic, t = 1, st = false }, -- 36
		{ n = "Digit5_KnucklePlate", s = "Block", z = Vector3.new(0.72, 0.48, 0.651), cf = CFrame.new(-1.533316, 0.697899, 0.143768, -0.758977, 0.049232, -0.649255, 0.26745, 0.93271, -0.241922, 0.593655, -0.357256, -0.721071), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 37
		{ n = "Digit5_MidPlate", s = "Block", z = Vector3.new(0.6336, 0.4, 0.682), cf = CFrame.new(-1.840586, 0.528543, -0.17276, -0.723082, 0.308474, -0.618059, 0.398945, 0.916932, -0.009093, 0.563912, -0.253146, -0.78608), c = Color3.fromRGB(52, 40, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 38
		{ n = "Digit5_Ridge", s = "Block", z = Vector3.new(0.34848, 0.18, 0.5797), cf = CFrame.new(-1.793695, 0.667916, -0.211243, -0.723082, 0.308474, -0.618059, 0.398945, 0.916932, -0.009093, 0.563912, -0.253146, -0.78608), c = Color3.fromRGB(72, 58, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 39
		{ n = "Digit5_EmberTip", s = "Block", z = Vector3.new(0.5184, 0.34, 0.589), cf = CFrame.new(-2.201857, 0.377244, -0.528992, -0.723082, 0.589122, -0.360677, 0.398945, 0.782421, 0.478188, 0.563912, 0.201879, -0.800781), c = Color3.fromRGB(198, 68, 24), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 40
		{ n = "Digit5_TalonHook", s = "Wedge", z = Vector3.new(0.46656, 0.28, 0.36), cf = CFrame.new(-2.347172, 0.421052, -0.746307, 0.723082, -0.589122, -0.360677, -0.398945, -0.782421, 0.478188, -0.563912, -0.201879, -0.800781), c = Color3.fromRGB(198, 68, 24), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 41
		{ n = "Digit5_GlowVein", s = "Block", z = Vector3.new(0.23328, 0.08, 0.38285), cf = CFrame.new(-2.145592, 0.490262, -0.536774, -0.723082, 0.589122, -0.360677, 0.398945, 0.782421, 0.478188, 0.563912, 0.201879, -0.800781), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 42
		{ n = "MagmaSeam12", s = "Block", z = Vector3.new(0.18, 0.32, 1.45), cf = CFrame.new(0.949999, 0.508191, -0.044983, -0.857168, 0, 0.515038, 0.089436, 0.984809, 0.148846, -0.507214, 0.173648, -0.844146), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 43
		{ n = "MagmaSeam12_Vent", s = "Block", z = Vector3.new(0.108, 0.16, 0.87), cf = CFrame.new(0.846991, 0.379941, 0.106506, -0.857168, 0, 0.515038, 0.089436, 0.984809, 0.148846, -0.507214, 0.173648, -0.844146), c = Color3.fromRGB(255, 175, 60), m = Enum.Material.Neon, st = false }, -- 44
		{ n = "MagmaSeam23", s = "Block", z = Vector3.new(0.2, 0.34, 1.65), cf = CFrame.new(0.359997, 0.508191, -0.224976, -0.981628, 0, 0.190809, 0.033134, 0.984809, 0.170458, -0.18791, 0.173648, -0.966715), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 45
		{ n = "MagmaSeam23_Vent", s = "Block", z = Vector3.new(0.12, 0.16, 0.99), cf = CFrame.new(0.321835, 0.375618, -0.048981, -0.981628, 0, 0.190809, 0.033134, 0.984809, 0.170458, -0.18791, 0.173648, -0.966715), c = Color3.fromRGB(255, 175, 60), m = Enum.Material.Neon, st = false }, -- 46
		{ n = "MagmaSeam34", s = "Block", z = Vector3.new(0.2, 0.34, 1.65), cf = CFrame.new(-0.360001, 0.508191, -0.224976, -0.981628, 0, -0.190809, -0.033134, 0.984809, 0.170458, 0.18791, 0.173648, -0.966715), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 47
		{ n = "MagmaSeam34_Vent", s = "Block", z = Vector3.new(0.12, 0.16, 0.99), cf = CFrame.new(-0.32184, 0.375618, -0.048981, -0.981628, 0, -0.190809, -0.033134, 0.984809, 0.170458, 0.18791, 0.173648, -0.966715), c = Color3.fromRGB(255, 175, 60), m = Enum.Material.Neon, st = false }, -- 48
		{ n = "MagmaSeam45", s = "Block", z = Vector3.new(0.18, 0.32, 1.45), cf = CFrame.new(-0.950003, 0.508191, -0.044983, -0.857168, 0, -0.515038, -0.089436, 0.984809, 0.148846, 0.507214, 0.173648, -0.844146), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 49
		{ n = "MagmaSeam45_Vent", s = "Block", z = Vector3.new(0.108, 0.16, 0.87), cf = CFrame.new(-0.846992, 0.379941, 0.106506, -0.857168, 0, -0.515038, -0.089436, 0.984809, 0.148846, 0.507214, 0.173648, -0.844146), c = Color3.fromRGB(255, 175, 60), m = Enum.Material.Neon, st = false }, -- 50
		{ n = "FlankGlowL", s = "Block", z = Vector3.new(0.18, 0.26, 1.25), cf = CFrame.new(1.75, 0.33819, 0.305023, -0.573577, 0, 0.819153, 0, 1.000002, 0, -0.819153, 0, -0.573577), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 51
		{ n = "FlankGlowR", s = "Block", z = Vector3.new(0.18, 0.26, 1.25), cf = CFrame.new(-1.750004, 0.33819, 0.305023, -0.573577, 0, -0.819153, 0, 1.000002, 0, 0.819153, 0, -0.573577), c = Color3.fromRGB(255, 118, 44), m = Enum.Material.Neon, st = false }, -- 52
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, 0, 0, 1.000001, 0, 0, 0, 1.000003, 0, 0, 0, 1.000001), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 0.12, -0.75, 1.000002, 0, 0, 0, 1.000003, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 5, c0 = CFrame.new(0, 0.520002, -0.420013, 1.000002, 0, 0, 0, 0.978151, 0.207912, 0, -0.207912, 0.978149), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 6, c0 = CFrame.new(0, 0.714403, -0.563568, 1.000001, 0, 0, 0, 0.956308, 0.292373, 0, -0.292372, 0.956306), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 7, c0 = CFrame.new(0, 0.480002, -0.149994, 1.000002, 0, 0, 0, 1.000003, 0, 0, 0, 1.000002), c1 = CFrame.new() },
		{ k = "Motor6D", n = "Digit1Joint", h = 1, a = 1, b = 8, c0 = CFrame.new(-1.35, 0.15, 0.15, 0.743145, 0, -0.669131, 0, 1, 0, 0.669131, 0, 0.743145), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Digit2Joint", h = 1, a = 1, b = 15, c0 = CFrame.new(-0.7, 0.15, 0.4, 0.93358, 0, -0.358368, 0, 1, 0, 0.358368, 0, 0.93358), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Digit3Joint", h = 1, a = 1, b = 22, c0 = CFrame.new(0, 0.15, 0.52, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Digit4Joint", h = 1, a = 1, b = 29, c0 = CFrame.new(0.7, 0.15, 0.4, 0.93358, 0, 0.358368, 0, 1, 0, -0.358368, 0, 0.93358), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Digit5Joint", h = 1, a = 1, b = 36, c0 = CFrame.new(1.35, 0.15, 0.15, 0.743145, 0, 0.669131, 0, 1, 0, -0.669131, 0, 0.743145), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 43, c0 = CFrame.new(-0.950001, 0.02, 0.600006, 0.857168, 0, -0.515039, 0.089436, 0.984811, 0.148846, 0.507214, -0.173648, 0.844146), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 44, c0 = CFrame.new(-0.846992, -0.10825, 0.448517, 0.857168, 0, -0.515039, 0.089436, 0.984811, 0.148846, 0.507214, -0.173648, 0.844146), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 45, c0 = CFrame.new(-0.359999, 0.02, 0.779999, 0.981629, 0, -0.190809, 0.033134, 0.984811, 0.170458, 0.18791, -0.173648, 0.966716), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 46, c0 = CFrame.new(-0.321836, -0.112573, 0.604004, 0.981629, 0, -0.190809, 0.033134, 0.984811, 0.170458, 0.18791, -0.173648, 0.966716), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 47, c0 = CFrame.new(0.359999, 0.02, 0.779999, 0.981629, 0, 0.190809, -0.033134, 0.984811, 0.170458, -0.18791, -0.173648, 0.966716), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 48, c0 = CFrame.new(0.321838, -0.112573, 0.604004, 0.981629, 0, 0.190809, -0.033134, 0.984811, 0.170458, -0.18791, -0.173648, 0.966716), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 49, c0 = CFrame.new(0.950003, 0.02, 0.600006, 0.857168, 0, 0.515039, -0.089436, 0.984811, 0.148846, -0.507214, -0.173648, 0.844146), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 50, c0 = CFrame.new(0.846992, -0.10825, 0.448517, 0.857168, 0, 0.515039, -0.089436, 0.984811, 0.148846, -0.507214, -0.173648, 0.844146), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 51, c0 = CFrame.new(-1.750002, -0.15, 0.25, 0.573577, 0, -0.819153, 0, 1.000003, 0, 0.819153, 0, 0.573577), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 52, c0 = CFrame.new(1.750004, -0.15, 0.25, 0.573577, 0, 0.819153, 0, 1.000003, 0, -0.819153, 0, 0.573577), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 9, c0 = CFrame.new(0.038605, 0.059708, 0.316818, 0.961263, 0.275638, 0, -0.267451, 0.932711, -0.241923, -0.066683, 0.232551, 0.970297), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 10, c0 = CFrame.new(0.022049, -0.109648, 0.757645, 0.914686, 0.398629, 0.066683, -0.398945, 0.916933, -0.009093, -0.064768, -0.018285, 0.997734), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 11, c0 = CFrame.new(0.082642, 0.029725, 0.754868, 0.914686, 0.398629, 0.066683, -0.398945, 0.916933, -0.009093, -0.064768, -0.018285, 0.997734), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 12, c0 = CFrame.new(-0.008072, -0.260947, 1.26413, 0.914686, 0.30272, 0.267792, -0.398945, 0.782422, 0.478189, -0.064768, -0.544225, 0.836437), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 13, c0 = CFrame.new(0.029358, -0.217139, 1.522858, -0.914686, -0.30272, 0.267791, 0.398945, -0.782422, 0.478189, 0.064768, 0.544225, 0.836437), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 14, c0 = CFrame.new(0.038956, -0.147929, 1.232269, 0.914686, 0.30272, 0.267792, -0.398945, 0.782422, 0.478189, -0.064768, -0.544225, 0.836437), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 16, c0 = CFrame.new(0.019478, 0.071177, 0.360382, 0.990269, 0.139173, 0, -0.136617, 0.972077, -0.19081, -0.026556, 0.188952, 0.981629), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 17, c0 = CFrame.new(0.011131, -0.091009, 0.883377, 0.978437, 0.203788, 0.033669, -0.205298, 0.977423, 0.050025, -0.022714, -0.055858, 0.998182), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 18, c0 = CFrame.new(0.042107, 0.05756, 0.874878, 0.978437, 0.203788, 0.033669, -0.205298, 0.977423, 0.050025, -0.022714, -0.055858, 0.998182), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 19, c0 = CFrame.new(-0.00174, -0.218078, 1.477325, 0.978437, 0.15498, 0.136544, -0.205298, 0.802393, 0.560379, -0.022714, -0.576326, 0.816906), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 20, c0 = CFrame.new(0.02272, -0.13348, 1.766861, -0.978437, -0.15498, 0.136544, 0.205298, -0.802393, 0.560379, 0.022714, 0.576326, 0.816906), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 21, c0 = CFrame.new(0.022308, -0.099376, 1.440857, 0.978437, 0.15498, 0.136544, -0.205298, 0.802393, 0.560379, -0.022714, -0.576326, 0.816906), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 23, c0 = CFrame.new(0, 0.087346, 0.38446, 1.000002, 0, 0, 0, 0.990271, -0.139174, 0, 0.139173, 0.99027), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 24, c0 = CFrame.new(0.000002, -0.054138, 0.960052, 1.000002, 0, 0, 0, 0.994525, 0.104529, 0, -0.104529, 0.994523), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 25, c0 = CFrame.new(0, 0.097029, 0.944153, 1.000002, 0, 0, 0, 0.994525, 0.104529, 0, -0.104529, 0.994523), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 26, c0 = CFrame.new(0, -0.146895, 1.608215, 1.000002, 0, 0, 0, 0.788013, 0.615663, 0, -0.615662, 0.788012), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 27, c0 = CFrame.new(0.000002, -0.030307, 1.912048, -1.000002, 0, 0, 0, -0.788013, 0.615663, 0, 0.615662, 0.788012), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 28, c0 = CFrame.new(0.000002, -0.027707, 1.565857, 1.000002, 0, 0, 0, 0.788013, 0.615663, 0, -0.615662, 0.788012), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 30, c0 = CFrame.new(-0.019478, 0.071177, 0.360382, 0.990269, -0.139173, 0, 0.136617, 0.972077, -0.19081, 0.026556, 0.188952, 0.981629), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 31, c0 = CFrame.new(-0.011139, -0.091009, 0.883392, 0.978437, -0.203788, -0.033669, 0.205298, 0.977423, 0.050025, 0.022714, -0.055858, 0.998182), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 32, c0 = CFrame.new(-0.042114, 0.05756, 0.874878, 0.978437, -0.203788, -0.033669, 0.205298, 0.977423, 0.050025, 0.022714, -0.055858, 0.998182), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 33, c0 = CFrame.new(0.001747, -0.218078, 1.477295, 0.978437, -0.15498, -0.136544, 0.205298, 0.802393, 0.560379, 0.022714, -0.576326, 0.816906), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 34, c0 = CFrame.new(-0.02272, -0.13348, 1.766846, -0.978437, 0.15498, -0.136544, -0.205298, -0.802393, 0.560379, -0.022714, 0.576326, 0.816906), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 35, c0 = CFrame.new(-0.022316, -0.099376, 1.440857, 0.978437, -0.15498, -0.136544, 0.205298, 0.802393, 0.560379, 0.022714, -0.576326, 0.816906), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 37, c0 = CFrame.new(-0.038589, 0.059708, 0.316803, 0.961263, -0.275638, 0, 0.267451, 0.932711, -0.241923, 0.066683, 0.232551, 0.970297), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 38, c0 = CFrame.new(-0.022034, -0.109648, 0.757645, 0.914686, -0.398629, -0.066683, 0.398945, 0.916933, -0.009093, 0.064768, -0.018285, 0.997734), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 39, c0 = CFrame.new(-0.082642, 0.029725, 0.754868, 0.914686, -0.398629, -0.066683, 0.398945, 0.916933, -0.009093, 0.064768, -0.018285, 0.997734), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 40, c0 = CFrame.new(0.008072, -0.260947, 1.264114, 0.914686, -0.30272, -0.267792, 0.398945, 0.782422, 0.478189, 0.064768, -0.544225, 0.836437), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 41, c0 = CFrame.new(-0.029358, -0.217139, 1.522842, -0.914686, 0.30272, -0.267792, -0.398946, -0.782422, 0.478189, -0.064768, 0.544225, 0.836437), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 42, c0 = CFrame.new(-0.038956, -0.147929, 1.232254, 0.914686, -0.30272, -0.267792, 0.398945, 0.782422, 0.478189, 0.064768, -0.544225, 0.836437), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "EmberCoreLight", p = 1, range = 14, brightness = 2.6, color = Color3.new(1, 0.501961, 0.188235), shadows = true, enabled = true },
		{ n = "WarmFillLight", p = 1, range = 8, brightness = 1.2, color = Color3.new(0.941176, 0.376471, 0.12549), shadows = false, enabled = true },
	},
	Emitters = {},
	Textures = {
		{ n = "Studs_%s", p = 1, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 4, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 5, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 6, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 9, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 10, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 11, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 12, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 13, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 16, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 17, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 18, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 19, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 20, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 23, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 24, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 25, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 26, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 27, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 30, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 31, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 32, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 33, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 34, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 37, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 38, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 39, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 40, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 41, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
