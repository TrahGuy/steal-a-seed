--!strict
--==============================================================================
-- POD FORM: Crookreed (tanglemire pods/CrookreedPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "tanglemire pods/CrookreedPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "tanglemire pods/CrookreedPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(3.012976, 5.843298, 3.019318), Height = 5.843298, PartCount = 61,
	Base = 0, Root = 1,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Rare", Style = "CrookedReed", TextureStyle = "Studded", UnitType = "CrookreedPod" },
	Removed = { "FlatBase" },
	Parts = {
		{ n = "SheafCore", s = "Block", z = Vector3.new(1.85, 2.85, 1.85), cf = CFrame.new(-0.019581, 1.865804, 0.070312, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(86, 56, 38), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 1
		{ n = "PollenHeart", s = "Block", z = Vector3.new(0.95, 0.95, 0.95), cf = CFrame.new(-0.019581, 2.065804, 0.070312, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(95, 175, 120), m = Enum.Material.Neon, st = false, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 2
		{ n = "LowerReed1", s = "Block", z = Vector3.new(0.55, 1.75, 0.52), cf = CFrame.new(-0.019583, 1.015804, -0.8797, -0.999391, 0, -0.034899, 0.004857, 0.990268, -0.139088, 0.03456, -0.139173, -0.989665), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "ReedFoot1", s = "Wedge", z = Vector3.new(0.52, 0.45, 0.38), cf = CFrame.new(-0.024813, 0.25224, -0.923767, -0.999391, 0, 0.034899, 0.004857, -0.990268, 0.139088, 0.03456, 0.139173, 0.989665), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "LowerReed2", s = "Block", z = Vector3.new(0.55, 1.75, 0.52), cf = CFrame.new(-0.691334, 1.015804, -0.60144, -0.731113, -0.09841, -0.675121, -0.004857, 0.990268, -0.139088, 0.682239, -0.09841, -0.724476), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "ReedFoot2", s = "Wedge", z = Vector3.new(0.52, 0.45, 0.38), cf = CFrame.new(-0.718798, 0.25224, -0.636292, -0.731113, 0.09841, 0.675121, -0.004857, -0.990268, 0.139088, 0.682239, 0.09841, 0.724476), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "LowerReed3", s = "Block", z = Vector3.new(0.55, 1.75, 0.52), cf = CFrame.new(-0.969582, 1.015804, 0.070312, 0.086308, -0.139173, -0.9865, 0.01213, 0.990268, -0.138644, 0.996195, 0, 0.087156), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "ReedFoot3", s = "Wedge", z = Vector3.new(0.52, 0.45, 0.38), cf = CFrame.new(-1.013174, 0.252306, 0.083374, 0.086308, 0.139173, 0.9865, 0.01213, -0.990268, 0.138644, 0.996195, 0, -0.087156), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "LowerReed4", s = "Block", z = Vector3.new(0.55, 1.75, 0.52), cf = CFrame.new(-0.69133, 1.015804, 0.742065, 0.71922, -0.09841, -0.687778, 0.002429, 0.990268, -0.139152, 0.694778, 0.09841, 0.712459), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "ReedFoot4", s = "Wedge", z = Vector3.new(0.52, 0.45, 0.38), cf = CFrame.new(-0.720688, 0.25223, 0.775116, 0.71922, 0.09841, 0.687778, 0.002429, -0.990268, 0.139152, 0.694778, -0.09841, -0.712459), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "LowerReed5", s = "Block", z = Vector3.new(0.55, 1.75, 0.52), cf = CFrame.new(-0.019583, 1.015804, 1.020325, 0.998629, 0, -0.052336, -0.007284, 0.990268, -0.138982, 0.051827, 0.139173, 0.988911), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "ReedFoot5", s = "Wedge", z = Vector3.new(0.52, 0.45, 0.38), cf = CFrame.new(-0.027433, 0.252255, 1.06427, 0.998629, 0, 0.052336, -0.007284, -0.990268, 0.138982, 0.051827, -0.139173, -0.988911), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "LowerReed6", s = "Block", z = Vector3.new(0.55, 1.75, 0.52), cf = CFrame.new(0.652168, 1.015804, 0.742065, 0.656539, 0.09841, 0.747845, 0.009708, 0.990268, -0.138834, -0.754229, 0.09841, 0.649194), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "ReedFoot6", s = "Wedge", z = Vector3.new(0.52, 0.45, 0.38), cf = CFrame.new(0.690538, 0.252278, 0.765625, 0.656539, -0.09841, -0.747845, 0.009708, -0.990268, 0.138834, -0.754229, -0.09841, -0.649194), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "LowerReed7", s = "Block", z = Vector3.new(0.55, 1.75, 0.52), cf = CFrame.new(0.93042, 1.015804, 0.070312, 0, 0.139173, 0.990268, 0, 0.990268, -0.139173, -1, 0, 0), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "ReedFoot7", s = "Wedge", z = Vector3.new(0.52, 0.45, 0.38), cf = CFrame.new(0.974581, 0.252227, 0.070312, 0, -0.139173, -0.990268, 0, -0.990268, 0.139173, -1, 0, 0), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "LowerReed8", s = "Block", z = Vector3.new(0.55, 1.75, 0.52), cf = CFrame.new(0.65217, 1.015804, -0.60144, -0.656539, 0.09841, 0.747845, -0.009708, 0.990268, -0.138834, -0.75423, -0.09841, -0.649194), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "ReedFoot8", s = "Wedge", z = Vector3.new(0.52, 0.45, 0.38), cf = CFrame.new(0.690542, 0.252278, -0.625, -0.656539, -0.09841, -0.747845, -0.009708, -0.990268, 0.138834, -0.75423, 0.09841, 0.649194), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "BindingBandRing", s = "Block", z = Vector3.new(2.45, 0.48, 2.45), cf = CFrame.new(-0.019581, 1.865804, 0.070312, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 19
		{ n = "CordFacet1", s = "Block", z = Vector3.new(1.15, 0.42, 0.24), cf = CFrame.new(-0.019581, 1.865804, -1.1297, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "CordFacet2", s = "Block", z = Vector3.new(1.15, 0.42, 0.24), cf = CFrame.new(-1.058813, 1.865804, -0.529694, -0.5, 0, -0.866025, 0, 1, 0, 0.866025, 0, -0.5), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "CordFacet3", s = "Block", z = Vector3.new(1.15, 0.42, 0.24), cf = CFrame.new(-1.058813, 1.865804, 0.670319, 0.5, 0, -0.866025, 0, 1, 0, 0.866025, 0, 0.5), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "CordFacet4", s = "Block", z = Vector3.new(1.15, 0.42, 0.24), cf = CFrame.new(-0.019579, 1.865804, 1.270325, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "CordFacet5", s = "Block", z = Vector3.new(1.15, 0.42, 0.24), cf = CFrame.new(1.01965, 1.865804, 0.670288, 0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, 0.5), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "CordFacet6", s = "Block", z = Vector3.new(1.15, 0.42, 0.24), cf = CFrame.new(1.01965, 1.865804, -0.529694, -0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, -0.5), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "KnotClasp", s = "Block", z = Vector3.new(0.68, 0.62, 0.48), cf = CFrame.new(-0.019581, 1.865804, -1.269684, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 26
		{ n = "KnotFiber1", s = "Block", z = Vector3.new(0.22, 0.72, 0.18), cf = CFrame.new(0.140417, 1.445804, -1.319672, -0.970296, 0.241922, 0, 0.241922, 0.970296, 0, 0, 0, -1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "KnotFiber2", s = "Block", z = Vector3.new(0.22, 0.65, 0.18), cf = CFrame.new(-0.179581, 1.485804, -1.319672, -0.961262, -0.275637, 0, -0.275637, 0.961262, 0, 0, 0, -1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "CrownHinge", s = "Block", z = Vector3.new(0.3, 0.3, 0.3), cf = CFrame.new(-0.019581, 2.515804, 0.070312, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, t = 1, st = false }, -- 29
		{ n = "UpperShaft1", s = "Block", z = Vector3.new(0.48, 1.67, 0.46), cf = CFrame.new(-0.019583, 3.450804, -0.749695, -1, 0, 0, 0, 0.984808, 0.173648, 0, 0.173648, -0.984808), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "TipHinge1", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(-0.019583, 4.273118, -0.604706, -1, 0, 0, 0, 0.984808, 0.173648, 0, 0.173648, -0.984808), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, t = 1, st = false }, -- 31
		{ n = "GreenTipStem1", s = "Block", z = Vector3.new(0.42, 0.95, 0.4), cf = CFrame.new(-0.23958, 4.766663, -0.639526, -0.945519, -0.325568, 0, -0.279066, 0.810468, -0.515038, 0.16768, -0.486978, -0.857167), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "GreenHook1", s = "Wedge", z = Vector3.new(0.38, 0.72, 0.36), cf = CFrame.new(-0.598604, 5.217407, -0.840363, -0.810412, 0.565572, -0.152845, -0.411822, -0.364379, 0.835243, 0.416696, 0.739836, 0.528211), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
		{ n = "UpperShaft2", s = "Block", z = Vector3.new(0.48, 1.89, 0.46), cf = CFrame.new(-0.599411, 3.560804, -0.509521, -0.707107, 0.122788, -0.696364, 0, 0.984808, 0.173648, 0.707107, 0.122788, -0.696364), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 34
		{ n = "TipHinge2", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(-0.483377, 4.491447, -0.393494, -0.707107, 0.122788, -0.696364, 0, 0.984808, 0.173648, 0.707107, 0.122788, -0.696364), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, t = 1, st = false }, -- 35
		{ n = "GreenTipStem2", s = "Block", z = Vector3.new(0.42, 0.95, 0.4), cf = CFrame.new(-0.663565, 4.984993, -0.262543, -0.565152, -0.594431, -0.572061, -0.222995, 0.777677, -0.587785, 0.794277, -0.204621, -0.572061), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 36
		{ n = "GreenHook2", s = "Wedge", z = Vector3.new(0.38, 0.72, 0.36), cf = CFrame.new(-1.075743, 5.431174, -0.203918, -0.292312, 0.929227, 0.226031, -0.338994, -0.321689, 0.884081, 0.894224, 0.181804, 0.409036), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 37
		{ n = "UpperShaft3", s = "Block", z = Vector3.new(0.48, 1.45, 0.46), cf = CFrame.new(-0.839579, 3.340804, 0.070312, 0, 0.173648, -0.984808, 0, 0.984808, 0.173648, 1, 0, 0), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 38
		{ n = "TipHinge3", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(-0.713684, 4.05479, 0.070312, 0, 0.173648, -0.984808, 0, 0.984808, 0.173648, 1, 0, 0), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, t = 1, st = false }, -- 39
		{ n = "GreenTipStem3", s = "Block", z = Vector3.new(0.42, 0.95, 0.4), cf = CFrame.new(-0.74851, 4.548335, 0.290314, 0.147581, -0.639244, -0.75471, -0.169773, 0.735366, -0.656059, 0.97437, 0.224951, 0), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 40
		{ n = "GreenHook3", s = "Wedge", z = Vector3.new(0.38, 0.72, 0.36), cf = CFrame.new(-1.047426, 4.983653, 0.596161, 0.424263, 0.828163, 0.366262, -0.266927, -0.272122, 0.924499, 0.865304, -0.489996, 0.105608), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 41
		{ n = "UpperShaft4", s = "Block", z = Vector3.new(0.48, 1.67, 0.46), cf = CFrame.new(-0.599413, 3.450804, 0.650146, 0.707107, 0.122788, -0.696364, 0, 0.984808, 0.173648, 0.707107, -0.122788, 0.696364), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 42
		{ n = "TipHinge4", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(-0.496885, 4.273118, 0.547607, 0.707107, 0.122788, -0.696364, 0, 0.984808, 0.173648, 0.707107, -0.122788, 0.696364), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, t = 1, st = false }, -- 43
		{ n = "GreenTipStem4", s = "Block", z = Vector3.new(0.42, 0.95, 0.4), cf = CFrame.new(-0.365938, 4.766663, 0.727814, 0.75401, -0.204135, -0.624338, -0.153322, 0.869534, -0.469472, 0.638719, 0.449711, 0.624338), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 44
		{ n = "GreenHook4", s = "Wedge", z = Vector3.new(0.38, 0.72, 0.36), cf = CFrame.new(-0.311157, 5.271564, 1.066162, 0.863379, 0.217181, 0.455422, -0.314958, -0.473181, 0.82274, 0.39418, -0.853776, -0.340131), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 45
		{ n = "UpperShaft5", s = "Block", z = Vector3.new(0.48, 1.89, 0.46), cf = CFrame.new(-0.019581, 3.560804, 0.89032, 1, 0, 0, 0, 0.984808, 0.173648, 0, -0.173648, 0.984808), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 46
		{ n = "TipHinge5", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(-0.019581, 4.491447, 0.726227, 1, 0, 0, 0, 0.984808, 0.173648, 0, -0.173648, 0.984808), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, t = 1, st = false }, -- 47
		{ n = "GreenTipStem5", s = "Block", z = Vector3.new(0.42, 0.95, 0.4), cf = CFrame.new(0.200418, 4.984993, 0.761078, 0.93358, 0.358368, 0, -0.300553, 0.782966, -0.544639, -0.195181, 0.508464, 0.83867), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 48
		{ n = "GreenHook5", s = "Wedge", z = Vector3.new(0.38, 0.72, 0.36), cf = CFrame.new(0.576321, 5.417694, 0.970551, 0.790109, -0.589426, 0.168244, -0.420458, -0.321429, 0.848468, -0.44603, -0.741121, -0.501793), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 49
		{ n = "UpperShaft6", s = "Block", z = Vector3.new(0.48, 1.45, 0.46), cf = CFrame.new(0.560247, 3.340804, 0.650146, 0.707107, -0.122788, 0.696364, 0, 0.984808, 0.173648, -0.707107, -0.122788, 0.696364), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 50
		{ n = "TipHinge6", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(0.471226, 4.05479, 0.561127, 0.707107, -0.122788, 0.696364, 0, 0.984808, 0.173648, -0.707107, -0.122788, 0.696364), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, t = 1, st = false }, -- 51
		{ n = "GreenTipStem6", s = "Block", z = Vector3.new(0.42, 0.95, 0.4), cf = CFrame.new(0.651415, 4.548335, 0.430176, 0.537971, 0.63254, 0.557208, -0.243509, 0.749443, -0.615661, -0.807025, 0.195524, 0.557208), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 52
		{ n = "GreenHook6", s = "Wedge", z = Vector3.new(0.38, 0.72, 0.36), cf = CFrame.new(1.08169, 4.976119, 0.364899, 0.258219, -0.946196, -0.195026, -0.346756, -0.279194, 0.895439, -0.901711, -0.163593, -0.400192), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 53
		{ n = "UpperShaft7", s = "Block", z = Vector3.new(0.48, 1.67, 0.46), cf = CFrame.new(0.800419, 3.450804, 0.070312, 0, -0.173648, 0.984808, 0, 0.984808, 0.173648, -1, 0, 0), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 54
		{ n = "TipHinge7", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(0.655422, 4.273118, 0.070312, 0, -0.173648, 0.984808, 0, 0.984808, 0.173648, -1, 0, 0), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, t = 1, st = false }, -- 55
		{ n = "GreenTipStem7", s = "Block", z = Vector3.new(0.42, 0.95, 0.4), cf = CFrame.new(0.690248, 4.766664, -0.149689, -0.176514, 0.65876, 0.731354, -0.189288, 0.706433, -0.681998, -0.965926, -0.258819, 0), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 56
		{ n = "GreenHook7", s = "Wedge", z = Vector3.new(0.38, 0.72, 0.36), cf = CFrame.new(0.996677, 5.183245, -0.473663, -0.453716, -0.825181, -0.336478, -0.273831, -0.230214, 0.933819, -0.848032, 0.515826, -0.121508), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 57
		{ n = "UpperShaft8", s = "Block", z = Vector3.new(0.48, 1.89, 0.46), cf = CFrame.new(0.560247, 3.560804, -0.509521, -0.707107, -0.122788, 0.696364, 0, 0.984808, 0.173648, -0.707107, 0.122788, -0.696364), c = Color3.fromRGB(144, 98, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 58
		{ n = "TipHinge8", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(0.444214, 4.491447, -0.393494, -0.707107, -0.122788, 0.696364, 0, 0.984808, 0.173648, -0.707107, 0.122788, -0.696364), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, t = 1, st = false }, -- 59
		{ n = "GreenTipStem8", s = "Block", z = Vector3.new(0.42, 0.95, 0.4), cf = CFrame.new(0.313274, 4.984993, -0.573669, -0.765163, 0.198812, 0.612373, -0.180057, 0.847101, -0.5, -0.618147, -0.492843, -0.612372), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 60
		{ n = "GreenHook8", s = "Wedge", z = Vector3.new(0.38, 0.72, 0.36), cf = CFrame.new(0.254112, 5.473897, -0.934052, -0.870798, -0.203921, -0.447356, -0.329835, -0.432451, 0.839163, -0.364583, 0.878295, 0.309317), c = Color3.fromRGB(70, 128, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 61
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0.2, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0.000002, -0.85, 0.950012, 0.999391, 0, 0.034899, 0.004857, 0.990268, -0.139088, -0.03456, 0.139173, 0.989665), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 5, c0 = CFrame.new(0.671753, -0.85, 0.671753, 0.731113, 0.09841, 0.675121, -0.004857, 0.990268, -0.139088, -0.682239, 0.09841, 0.724476), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 7, c0 = CFrame.new(0.950001, -0.85, 0, -0.086308, 0.139173, 0.9865, 0.01213, 0.990268, -0.138644, -0.996195, 0, -0.087156), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 9, c0 = CFrame.new(0.671749, -0.85, -0.671753, -0.71922, 0.09841, 0.687778, 0.002429, 0.990268, -0.139152, -0.694778, -0.09841, -0.712459), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 11, c0 = CFrame.new(0.000002, -0.85, -0.950012, -0.998629, 0, 0.052336, -0.007284, 0.990268, -0.138982, -0.051827, -0.139173, -0.988911), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 13, c0 = CFrame.new(-0.671749, -0.85, -0.671753, -0.656539, -0.09841, -0.747845, 0.009708, 0.990268, -0.138834, 0.754229, -0.09841, -0.649194), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 15, c0 = CFrame.new(-0.950001, -0.85, 0, 0, -0.139173, -0.990268, 0, 0.990268, -0.139173, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 17, c0 = CFrame.new(-0.671751, -0.85, 0.671753, 0.656539, -0.09841, -0.747845, -0.009708, 0.990268, -0.138834, 0.75423, 0.09841, 0.649194), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 19, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Motor6D", n = "CrownJoint", h = 1, a = 1, b = 29, c0 = CFrame.new(0, 0.65, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 4, c0 = CFrame.new(-0.000007, -0.749996, 0.149994, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 6, c0 = CFrame.new(0.000015, -0.750002, 0.149979, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 8, c0 = CFrame.new(0, -0.750001, 0.149998, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 9, a = 9, b = 10, c0 = CFrame.new(0, -0.750002, 0.149994, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 11, a = 11, b = 12, c0 = CFrame.new(-0.000004, -0.75, 0.149994, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 14, c0 = CFrame.new(0.000015, -0.749998, 0.150009, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 16, c0 = CFrame.new(0, -0.75, 0.150002, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 17, a = 17, b = 18, c0 = CFrame.new(-0.000015, -0.750002, 0.149994, 1, 0, 0, 0, -1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 20, c0 = CFrame.new(0, 0, 1.200012, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 21, c0 = CFrame.new(1.039232, 0, 0.600006, 0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, 0.5), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 22, c0 = CFrame.new(1.039232, 0, -0.600006, -0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, -0.5), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 23, c0 = CFrame.new(-0.000002, 0, -1.200012, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 24, c0 = CFrame.new(-1.03923, 0, -0.599976, -0.5, 0, -0.866025, 0, 1, 0, 0.866025, 0, -0.5), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 25, c0 = CFrame.new(-1.03923, 0, 0.600006, 0.5, 0, -0.866025, 0, 1, 0, 0.866025, 0, 0.5), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 26, c0 = CFrame.new(0, 0, 1.339996, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 27, c0 = CFrame.new(-0.159998, -0.42, 0.049988, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 28, c0 = CFrame.new(0.16, -0.38, 0.049988, 0.961262, 0.275637, 0, -0.275637, 0.961262, 0, 0, 0, 1), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 30, c0 = CFrame.new(0.000002, 0.935, 0.820007, 1, 0, 0, 0, 0.984808, 0.173648, 0, -0.173648, 0.984808), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 34, c0 = CFrame.new(0.57983, 1.045, 0.579834, 0.707107, -0.122788, 0.696364, 0, 0.984808, 0.173648, -0.707107, -0.122788, 0.696364), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 38, c0 = CFrame.new(0.819998, 0.825, 0, 0, -0.173648, 0.984808, 0, 0.984808, 0.173648, -1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 42, c0 = CFrame.new(0.579832, 0.935, -0.579834, -0.707107, -0.122788, 0.696364, 0, 0.984808, 0.173648, -0.707107, 0.122788, -0.696364), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 46, c0 = CFrame.new(0, 1.045, -0.820007, -1, 0, 0, 0, 0.984808, 0.173648, 0, 0.173648, -0.984808), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 50, c0 = CFrame.new(-0.579828, 0.825, -0.579834, -0.707107, 0.122788, -0.696364, 0, 0.984808, 0.173648, 0.707107, 0.122788, -0.696364), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 54, c0 = CFrame.new(-0.82, 0.935, 0, 0, 0.173648, -0.984808, 0, 0.984808, 0.173648, 1, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 58, c0 = CFrame.new(-0.579828, 1.045, 0.579834, 0.707107, 0.122788, -0.696364, 0, 0.984808, 0.173648, 0.707107, -0.122788, 0.696364), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TipJoint1", h = 30, a = 30, b = 31, c0 = CFrame.new(0, 0.835, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 31, a = 31, b = 32, c0 = CFrame.new(0.219997, 0.48, 0.119995, 0.945519, 0.325568, 0, -0.245709, 0.713592, -0.656059, -0.213592, 0.620316, 0.75471), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 32, a = 32, b = 33, c0 = CFrame.new(0.18, 0.580017, -0.059998, 0.951057, -0.309017, 0, -0.272846, -0.839733, 0.469472, -0.145075, -0.446494, -0.882947), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TipJoint2", h = 34, a = 34, b = 35, c0 = CFrame.new(0, 0.945, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 35, a = 35, b = 36, c0 = CFrame.new(0.220001, 0.48, 0.119995, 0.961262, 0.275637, 0, -0.191474, 0.667749, -0.71934, -0.198277, 0.691474, 0.694658), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 37, c0 = CFrame.new(0.179993, 0.580002, -0.060013, 0.951057, -0.309017, 0, -0.272846, -0.839733, 0.469472, -0.145075, -0.446494, -0.882947), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TipJoint3", h = 38, a = 38, b = 39, c0 = CFrame.new(0, 0.725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 39, a = 39, b = 40, c0 = CFrame.new(0.220001, 0.48, 0.120001, 0.97437, 0.224951, 0, -0.141566, 0.613191, -0.777146, -0.17482, 0.757228, 0.62932), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 40, a = 40, b = 41, c0 = CFrame.new(0.180023, 0.579998, -0.060001, 0.951057, -0.309017, 0, -0.272846, -0.839733, 0.469472, -0.145075, -0.446494, -0.882947), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TipJoint4", h = 42, a = 42, b = 43, c0 = CFrame.new(0, 0.835, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 43, a = 43, b = 44, c0 = CFrame.new(0.220016, 0.479996, 0.119995, 0.984808, 0.173648, 0, -0.136837, 0.776039, -0.615661, -0.106909, 0.606308, 0.788011), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 44, a = 44, b = 45, c0 = CFrame.new(0.180008, 0.580017, -0.059998, 0.951057, -0.309017, 0, -0.272846, -0.839733, 0.469472, -0.145075, -0.446494, -0.882948), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TipJoint5", h = 46, a = 46, b = 47, c0 = CFrame.new(0, 0.945, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 47, a = 47, b = 48, c0 = CFrame.new(0.219999, 0.479996, 0.119995, 0.93358, 0.358368, 0, -0.262094, 0.682777, -0.681998, -0.244406, 0.6367, 0.731354), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 48, a = 48, b = 49, c0 = CFrame.new(0.18, 0.580002, -0.059982, 0.951057, -0.309017, 0, -0.272846, -0.839733, 0.469471, -0.145075, -0.446494, -0.882947), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TipJoint6", h = 50, a = 50, b = 51, c0 = CFrame.new(0, 0.725, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 51, a = 51, b = 52, c0 = CFrame.new(0.220016, 0.480003, 0.119995, 0.951056, 0.309017, 0, -0.206773, 0.636381, -0.743145, -0.229644, 0.706773, 0.669131), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 52, a = 52, b = 53, c0 = CFrame.new(0.179977, 0.580009, -0.059982, 0.951056, -0.309017, 0, -0.272846, -0.839733, 0.469472, -0.145075, -0.446494, -0.882947), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TipJoint7", h = 54, a = 54, b = 55, c0 = CFrame.new(0, 0.835, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 55, a = 55, b = 56, c0 = CFrame.new(0.220001, 0.48, 0.120001, 0.965926, 0.258819, 0, -0.155761, 0.581309, -0.798636, -0.206702, 0.771423, 0.601815), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 56, a = 56, b = 57, c0 = CFrame.new(0.179993, 0.579998, -0.059999, 0.951056, -0.309017, 0, -0.272846, -0.839733, 0.469471, -0.145075, -0.446494, -0.882947), c1 = CFrame.new() },
		{ k = "Motor6D", n = "TipJoint8", h = 58, a = 58, b = 59, c0 = CFrame.new(0, 0.945, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 59, a = 59, b = 60, c0 = CFrame.new(0.219971, 0.48, 0.119995, 0.978148, 0.207912, 0, -0.15927, 0.749304, -0.642788, -0.133643, 0.628741, 0.766045), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 60, a = 60, b = 61, c0 = CFrame.new(0.179993, 0.580017, -0.059998, 0.951057, -0.309017, 0, -0.272846, -0.839733, 0.469471, -0.145075, -0.446494, -0.882948), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StudioFillLight", p = 1, range = 12, brightness = 0.85, color = Color3.new(0.960784, 0.988235, 0.941176), shadows = true, enabled = true },
		{ n = "MarshGlow", p = 2, range = 9, brightness = 1.45, color = Color3.new(0.372549, 0.686275, 0.470588), shadows = true, enabled = true },
	},
	Emitters = {},
	Textures = {
		{ n = "Studs_%s", p = 1, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
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
		{ n = "Studs_%s", p = 30, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 32, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 33, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 34, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 36, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 37, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 38, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 40, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 41, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 42, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 44, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 45, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 46, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 48, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 49, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 50, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 52, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 53, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 54, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 56, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 57, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 58, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 60, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 61, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
