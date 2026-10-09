--!strict
--==============================================================================
-- POD FORM: Snapmoss (tanglemire pods/SnapmossPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "tanglemire pods/SnapmossPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "tanglemire pods/SnapmossPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(2.561681, 3.056167, 2.512146), Height = 3.056167, PartCount = 43,
	Base = 0, Root = 22,
	Attributes = {},
	Owner = { Biome = "tanglemire", BottomOffset = 0, ClosedDepth = 1.013909, ClosedHeight = 1.353487, ClosedWidth = 1.03391, IsPod = true, OpenAmount = 0, OpenDuration = 0.45, PartCount = 44, Rarity = "Epic", RulesVersion = "2026-10-09", ShellCentre = Vector3.new(0, 0.562734, 0), SizeSeamRole = "Seam", Species = "Snapmoss", Unit = 1, WidthClassUnit = 1 },
	Removed = { "SeedBase" },
	Parts = {
		{ n = "Seam_01", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.648396), cf = CFrame.new(-0.834354, 1.418463, -1.087708, -0.316862, 0, -0.948472, 0.948472, 0, -0.316862, 0, -1, 0), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 1
		{ n = "Seam_02", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.648396), cf = CFrame.new(-0.278119, 1.418463, -1.087708, 0.316862, 0, -0.948472, 0.948472, 0, 0.316862, 0, -1, 0), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 2
		{ n = "Seam_03", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.648396), cf = CFrame.new(0.278117, 1.418463, -1.087708, -0.316862, 0, -0.948472, 0.948472, 0, -0.316862, 0, -1, 0), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 3
		{ n = "Seam_04", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.648396), cf = CFrame.new(0.834352, 1.418463, -1.087708, 0.316862, 0, -0.948472, 0.948472, 0, 0.316862, 0, -1, 0), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 4
		{ n = "Seam_05", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.63666), cf = CFrame.new(1.112471, 1.418463, -0.815765, 0, 1, 0, 0.946286, 0, -0.323332, -0.323332, 0, -0.946285), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 5
		{ n = "Seam_06", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.63666), cf = CFrame.new(1.112471, 1.418463, -0.271912, 0, 1, 0, 0.946286, 0, 0.323332, 0.323332, 0, -0.946285), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 6
		{ n = "Seam_07", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.63666), cf = CFrame.new(1.112471, 1.418463, 0.271912, 0, 1, 0, 0.946286, 0, -0.323332, -0.323332, 0, -0.946285), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 7
		{ n = "Seam_08", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.63666), cf = CFrame.new(1.112471, 1.418463, 0.815765, 0, 1, 0, 0.946286, 0, 0.323332, 0.323332, 0, -0.946285), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 8
		{ n = "Seam_09", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.648396), cf = CFrame.new(0.834352, 1.418463, 1.087708, 0.316862, 0, 0.948472, 0.948472, 0, -0.316862, 0, 1, 0), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 9
		{ n = "Seam_10", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.648396), cf = CFrame.new(0.278117, 1.418463, 1.087708, -0.316862, 0, 0.948472, 0.948472, 0, 0.316862, 0, 1, 0), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 10
		{ n = "Seam_11", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.648396), cf = CFrame.new(-0.278119, 1.418463, 1.087708, 0.316862, 0, 0.948472, 0.948472, 0, -0.316862, 0, 1, 0), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 11
		{ n = "Seam_12", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.648396), cf = CFrame.new(-0.834354, 1.418463, 1.087708, -0.316862, 0, 0.948472, 0.948472, 0, 0.316862, 0, 1, 0), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 12
		{ n = "Seam_13", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.63666), cf = CFrame.new(-1.112473, 1.418463, 0.815765, 0, -1, 0, 0.946286, 0, -0.323332, 0.323332, 0, 0.946285), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 13
		{ n = "Seam_14", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.63666), cf = CFrame.new(-1.112473, 1.418463, 0.271912, 0, -1, 0, 0.946286, 0, 0.323332, -0.323332, 0, 0.946285), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 14
		{ n = "Seam_15", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.63666), cf = CFrame.new(-1.112473, 1.418463, -0.271912, 0, -1, 0, 0.946286, 0, -0.323332, 0.323332, 0, 0.946285), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 15
		{ n = "Seam_16", s = "Block", z = Vector3.new(0.111495, 0.111495, 0.63666), cf = CFrame.new(-1.112473, 1.418463, -0.815765, 0, -1, 0, 0.946286, 0, 0.323332, -0.323332, 0, 0.946285), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Seam" } }, -- 16
		{ n = "SeamGlow1", s = "Block", z = Vector3.new(0.024777, 0.044598, 0.29732), cf = CFrame.new(-0.278119, 1.418463, -1.147186, 0.316862, 0, -0.948472, 0.948472, 0, 0.316862, 0, -1, 0), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Neon, t = 0.45, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Glow" } }, -- 17
		{ n = "SeamGlow2", s = "Block", z = Vector3.new(0.024777, 0.044598, 0.29732), cf = CFrame.new(1.171934, 1.418463, -0.271912, 0, 1, 0, 0.946286, 0, 0.323332, 0.323332, 0, -0.946285), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Neon, t = 0.45, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Glow" } }, -- 18
		{ n = "SeamGlow3", s = "Block", z = Vector3.new(0.024777, 0.044598, 0.29732), cf = CFrame.new(0.278117, 1.418463, 1.147186, -0.316862, 0, 0.948472, 0.948472, 0, 0.316862, 0, 1, 0), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Neon, t = 0.45, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Glow" } }, -- 19
		{ n = "SeamGlow4", s = "Block", z = Vector3.new(0.024777, 0.044598, 0.29732), cf = CFrame.new(-1.171936, 1.418463, 0.271912, 0, -1, 0, 0.946286, 0, 0.323332, -0.323332, 0, 0.946285), c = Color3.fromRGB(204, 94, 88), m = Enum.Material.Neon, t = 0.45, st = false, g = "GlowAccents", a = { BaseColor = Color3.new(0.8, 0.368627, 0.345098), TintRole = "Glow" } }, -- 20
		{ n = "LowerHusk", s = "Block", z = Vector3.new(1.932578, 0.545086, 1.883025), cf = CFrame.new(-0.000001, 0.272543, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.164706, 0.360784, 0.290196), TintRole = "Shell" } }, -- 21
		{ n = "PodCore", s = "Block", z = Vector3.new(2.229898, 1.164502, 2.180345), cf = CFrame.new(-0.000001, 0.891959, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.164706, 0.360784, 0.290196), TintRole = "Shell" } }, -- 22
		{ n = "LowerFold1", s = "Block", z = Vector3.new(1.387492, 0.768076, 0.272543), cf = CFrame.new(-0.000001, 0.830018, 1.028229, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.164706, 0.360784, 0.290196), TintRole = "Shell" } }, -- 23
		{ n = "LowerFold2", s = "Block", z = Vector3.new(1.387492, 0.768076, 0.272543), cf = CFrame.new(1.053007, 0.830018, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(59, 111, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.231373, 0.435294, 0.305882), TintRole = "Shell" } }, -- 24
		{ n = "LowerFold3", s = "Block", z = Vector3.new(1.387492, 0.768076, 0.272543), cf = CFrame.new(-0.000001, 0.830018, -1.028229, -1, 0, 0, 0, 1, 0, 0, 0, -1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.164706, 0.360784, 0.290196), TintRole = "Shell" } }, -- 25
		{ n = "LowerFold4", s = "Block", z = Vector3.new(1.387492, 0.768076, 0.272543), cf = CFrame.new(-1.053008, 0.830018, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.fromRGB(59, 111, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.231373, 0.435294, 0.305882), TintRole = "Shell" } }, -- 26
		{ n = "SeedCap", s = "Block", z = Vector3.new(2.180345, 1.090172, 2.130791), cf = CFrame.new(-0.000001, 1.883025, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.164706, 0.360784, 0.290196), TintRole = "Shell" } }, -- 27
		{ n = "UpperFold1", s = "Wedge", z = Vector3.new(1.412269, 0.792853, 0.29732), cf = CFrame.new(-0.000001, 1.982131, 1.028229, 1, 0, 0, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.164706, 0.360784, 0.290196), TintRole = "Shell" } }, -- 28
		{ n = "UpperFold2", s = "Wedge", z = Vector3.new(1.412269, 0.792853, 0.29732), cf = CFrame.new(1.053007, 1.982131, 0, 0, -0.207912, 0.978148, 0, 0.978148, 0.207912, -1, 0, 0), c = Color3.fromRGB(59, 111, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.231373, 0.435294, 0.305882), TintRole = "Shell" } }, -- 29
		{ n = "UpperFold3", s = "Wedge", z = Vector3.new(1.412269, 0.792853, 0.29732), cf = CFrame.new(-0.000001, 1.982131, -1.028229, -1, 0, 0, 0, 0.978148, 0.207912, 0, 0.207912, -0.978148), c = Color3.fromRGB(42, 92, 74), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.164706, 0.360784, 0.290196), TintRole = "Shell" } }, -- 30
		{ n = "UpperFold4", s = "Wedge", z = Vector3.new(1.412269, 0.792853, 0.29732), cf = CFrame.new(-1.053008, 1.982131, 0, 0, 0.207912, -0.978148, 0, 0.978148, 0.207912, 1, 0, 0), c = Color3.fromRGB(59, 111, 78), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.231373, 0.435294, 0.305882), TintRole = "Shell" } }, -- 31
		{ n = "MossRoot1", s = "Block", z = Vector3.new(0.44598, 0.272543, 0.470756), cf = CFrame.new(-0.545087, 2.415723, -0.545074, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 32
		{ n = "MossCrest1", s = "Wedge", z = Vector3.new(0.346873, 0.594639, 0.272543), cf = CFrame.new(-0.545087, 2.713042, -0.545074, 0.990983, 0.133986, 0, -0.128796, 0.952594, 0.275637, 0.036932, -0.273152, 0.961262), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 33
		{ n = "MossRoot2", s = "Block", z = Vector3.new(0.44598, 0.272543, 0.470756), cf = CFrame.new(-0.000001, 2.415723, -0.545074, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 34
		{ n = "MossCrest2", s = "Wedge", z = Vector3.new(0.346873, 0.594639, 0.272543), cf = CFrame.new(-0.000001, 2.713042, -0.545074, 1, 0, 0, 0, 0.961262, 0.275637, 0, -0.275637, 0.961262), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 35
		{ n = "MossRoot3", s = "Block", z = Vector3.new(0.44598, 0.272543, 0.470756), cf = CFrame.new(0.545086, 2.415723, -0.545074, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 36
		{ n = "MossCrest3", s = "Wedge", z = Vector3.new(0.346873, 0.594639, 0.272543), cf = CFrame.new(0.545086, 2.713042, -0.545074, 0.990983, -0.133986, 0, 0.128796, 0.952594, 0.275637, -0.036932, -0.273152, 0.961262), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 37
		{ n = "MossRoot4", s = "Block", z = Vector3.new(0.44598, 0.272543, 0.470756), cf = CFrame.new(-0.545087, 2.415723, 0.545074, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 38
		{ n = "MossCrest4", s = "Wedge", z = Vector3.new(0.346873, 0.594639, 0.272543), cf = CFrame.new(-0.545087, 2.713042, 0.545074, 0.990983, 0.133986, 0, -0.128796, 0.952594, -0.275637, -0.036932, 0.273152, 0.961262), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 39
		{ n = "MossRoot5", s = "Block", z = Vector3.new(0.44598, 0.272543, 0.470756), cf = CFrame.new(-0.000001, 2.415723, 0.545074, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 40
		{ n = "MossCrest5", s = "Wedge", z = Vector3.new(0.346873, 0.594639, 0.272543), cf = CFrame.new(-0.000001, 2.713042, 0.545074, 1, 0, 0, 0, 0.961262, -0.275637, 0, 0.275637, 0.961262), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 41
		{ n = "MossRoot6", s = "Block", z = Vector3.new(0.44598, 0.272543, 0.470756), cf = CFrame.new(0.545086, 2.415723, 0.545074, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 42
		{ n = "MossCrest6", s = "Wedge", z = Vector3.new(0.346873, 0.594639, 0.272543), cf = CFrame.new(0.545086, 2.713042, 0.545074, 0.990983, -0.133986, 0, 0.128796, 0.952594, -0.275637, 0.036932, 0.273152, 0.961262), c = Color3.fromRGB(168, 214, 96), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.658824, 0.839216, 0.376471), TintRole = "Moss" } }, -- 43
	},
	Joints = {
		{ k = "Weld", n = "SeamGlow1Weld", h = 2, a = 2, b = 17, c0 = CFrame.new(0, 0.059464, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SeamGlow2Weld", h = 6, a = 6, b = 18, c0 = CFrame.new(0, 0.059464, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SeamGlow3Weld", h = 10, a = 10, b = 19, c0 = CFrame.new(0, 0.059464, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "SeamGlow4Weld", h = 14, a = 14, b = 20, c0 = CFrame.new(0, 0.059464, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "PodCoreWeld", h = 21, a = 21, b = 22, c0 = CFrame.new(0, 0.619416, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerFold1Weld", h = 22, a = 22, b = 23, c0 = CFrame.new(0, -0.061942, 1.028231, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerFold2Weld", h = 22, a = 22, b = 24, c0 = CFrame.new(1.053007, -0.061942, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerFold3Weld", h = 22, a = 22, b = 25, c0 = CFrame.new(0, -0.061942, -1.028231, -1, 0, 0, 0, 1, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "LowerFold4Weld", h = 22, a = 22, b = 26, c0 = CFrame.new(-1.053007, -0.061942, 0, 0, 0, -1, 0, 1, 0, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidHinge", h = 22, a = 22, b = 27, c0 = CFrame.new(0, 0.52031, 0.941512, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.470756, 0.941512, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_01Weld", h = 22, a = 22, b = 1, c0 = CFrame.new(-0.834354, 0.526504, -1.087695, -0.316862, 0, -0.948472, 0.948472, 0, -0.316862, 0, -1, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_02Weld", h = 22, a = 22, b = 2, c0 = CFrame.new(-0.278118, 0.526504, -1.087695, 0.316862, 0, -0.948472, 0.948472, 0, 0.316862, 0, -1, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_03Weld", h = 22, a = 22, b = 3, c0 = CFrame.new(0.278118, 0.526504, -1.087695, -0.316862, 0, -0.948472, 0.948472, 0, -0.316862, 0, -1, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_04Weld", h = 22, a = 22, b = 4, c0 = CFrame.new(0.834354, 0.526504, -1.087695, 0.316862, 0, -0.948472, 0.948472, 0, 0.316862, 0, -1, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_05Weld", h = 22, a = 22, b = 5, c0 = CFrame.new(1.112471, 0.526504, -0.815771, 0, 1, 0, 0.946286, 0, -0.323332, -0.323332, 0, -0.946285), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_06Weld", h = 22, a = 22, b = 6, c0 = CFrame.new(1.112471, 0.526504, -0.271924, 0, 1, 0, 0.946286, 0, 0.323332, 0.323332, 0, -0.946285), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_07Weld", h = 22, a = 22, b = 7, c0 = CFrame.new(1.112471, 0.526504, 0.271924, 0, 1, 0, 0.946286, 0, -0.323332, -0.323332, 0, -0.946285), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_08Weld", h = 22, a = 22, b = 8, c0 = CFrame.new(1.112471, 0.526504, 0.815771, 0, 1, 0, 0.946286, 0, 0.323332, 0.323332, 0, -0.946285), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_09Weld", h = 22, a = 22, b = 9, c0 = CFrame.new(0.834354, 0.526504, 1.087695, 0.316862, 0, 0.948472, 0.948472, 0, -0.316862, 0, 1, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_10Weld", h = 22, a = 22, b = 10, c0 = CFrame.new(0.278118, 0.526504, 1.087695, -0.316862, 0, 0.948472, 0.948472, 0, 0.316862, 0, 1, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_11Weld", h = 22, a = 22, b = 11, c0 = CFrame.new(-0.278118, 0.526504, 1.087695, 0.316862, 0, 0.948472, 0.948472, 0, -0.316862, 0, 1, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_12Weld", h = 22, a = 22, b = 12, c0 = CFrame.new(-0.834354, 0.526504, 1.087695, -0.316862, 0, 0.948472, 0.948472, 0, 0.316862, 0, 1, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_13Weld", h = 22, a = 22, b = 13, c0 = CFrame.new(-1.112471, 0.526504, 0.815771, 0, -1, 0, 0.946286, 0, -0.323332, 0.323332, 0, 0.946285), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_14Weld", h = 22, a = 22, b = 14, c0 = CFrame.new(-1.112471, 0.526504, 0.271924, 0, -1, 0, 0.946286, 0, 0.323332, -0.323332, 0, 0.946285), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_15Weld", h = 22, a = 22, b = 15, c0 = CFrame.new(-1.112471, 0.526504, -0.271924, 0, -1, 0, 0.946286, 0, -0.323332, 0.323332, 0, 0.946285), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Seam_16Weld", h = 22, a = 22, b = 16, c0 = CFrame.new(-1.112471, 0.526504, -0.815771, 0, -1, 0, 0.946286, 0, 0.323332, -0.323332, 0, 0.946285), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "UpperFold1Weld", h = 27, a = 27, b = 28, c0 = CFrame.new(0, 0.099107, 1.028231, 1, 0, 0, 0, 0.978148, 0.207912, 0, -0.207912, 0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "UpperFold2Weld", h = 27, a = 27, b = 29, c0 = CFrame.new(1.053007, 0.099107, 0, 0, -0.207912, 0.978148, 0, 0.978148, 0.207912, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "UpperFold3Weld", h = 27, a = 27, b = 30, c0 = CFrame.new(0, 0.099107, -1.028231, -1, 0, 0, 0, 0.978148, 0.207912, 0, 0.207912, -0.978148), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "UpperFold4Weld", h = 27, a = 27, b = 31, c0 = CFrame.new(-1.053007, 0.099107, 0, 0, 0.207912, -0.978148, 0, 0.978148, 0.207912, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossRoot1Weld", h = 27, a = 27, b = 32, c0 = CFrame.new(-0.545086, 0.532698, -0.545086, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossRoot2Weld", h = 27, a = 27, b = 34, c0 = CFrame.new(0, 0.532698, -0.545086, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossRoot3Weld", h = 27, a = 27, b = 36, c0 = CFrame.new(0.545086, 0.532698, -0.545086, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossRoot4Weld", h = 27, a = 27, b = 38, c0 = CFrame.new(-0.545086, 0.532698, 0.545086, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossRoot5Weld", h = 27, a = 27, b = 40, c0 = CFrame.new(0, 0.532698, 0.545086, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossRoot6Weld", h = 27, a = 27, b = 42, c0 = CFrame.new(0.545086, 0.532698, 0.545086, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossCrest1Weld", h = 32, a = 32, b = 33, c0 = CFrame.new(0, 0.29732, 0, 0.990983, 0.133986, 0, -0.128796, 0.952594, 0.275637, 0.036932, -0.273152, 0.961262), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossCrest2Weld", h = 34, a = 34, b = 35, c0 = CFrame.new(0, 0.29732, 0, 1, 0, 0, 0, 0.961262, 0.275637, 0, -0.275637, 0.961262), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossCrest3Weld", h = 36, a = 36, b = 37, c0 = CFrame.new(0, 0.29732, 0, 0.990983, -0.133986, 0, 0.128796, 0.952594, 0.275637, -0.036932, -0.273152, 0.961262), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossCrest4Weld", h = 38, a = 38, b = 39, c0 = CFrame.new(0, 0.29732, 0, 0.990983, 0.133986, 0, -0.128796, 0.952594, -0.275637, -0.036932, 0.273152, 0.961262), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossCrest5Weld", h = 40, a = 40, b = 41, c0 = CFrame.new(0, 0.29732, 0, 1, 0, 0, 0, 0.961262, -0.275637, 0, 0.275637, 0.961262), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "MossCrest6Weld", h = 42, a = 42, b = 43, c0 = CFrame.new(0, 0.29732, 0, 0.990983, -0.133986, 0, 0.128796, 0.952594, -0.275637, 0.036932, 0.273152, 0.961262), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
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
