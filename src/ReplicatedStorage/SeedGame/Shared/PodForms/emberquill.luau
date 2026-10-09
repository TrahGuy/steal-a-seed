--!strict
--==============================================================================
-- POD FORM: Emberquill (emberroot pods/EmberquillPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "emberroot pods/EmberquillPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "emberroot pods/EmberquillPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(2.739857, 7.531592, 2.739868), Height = 7.531592, PartCount = 66,
	Base = 0, Root = 1,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Rare", Style = "IncenseQuillSpire", TextureStyle = "Studded", UnitType = "EmberquillPod" },
	Removed = { "FlatBase", "PlinthBase" },
	Parts = {
		{ n = "PodRoot", s = "Block", z = Vector3.new(1.3, 1.9, 1.3), cf = CFrame.new(0, 1.240988, 0, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Cylinder", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 1
		{ n = "CalyxBlade1", s = "Wedge", z = Vector3.new(0.62, 0.55, 0.32), cf = CFrame.new(0.000002, 0.310984, -1.049988, -1.000002, 0, 0, 0, 0.95106, -0.309018, 0, -0.309018, -0.951058), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "CalyxBlade2", s = "Wedge", z = Vector3.new(0.62, 0.55, 0.32), cf = CFrame.new(-0.909327, 0.310984, -0.524994, -0.500001, -0.267617, -0.823641, 0, 0.95106, -0.309018, 0.866027, -0.154509, -0.475529), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "CalyxBlade3", s = "Wedge", z = Vector3.new(0.62, 0.55, 0.32), cf = CFrame.new(-0.909327, 0.310984, 0.525024, 0.500001, -0.267617, -0.823641, 0, 0.95106, -0.309018, 0.866027, 0.154509, 0.475529), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "CalyxBlade4", s = "Wedge", z = Vector3.new(0.62, 0.55, 0.32), cf = CFrame.new(0.000002, 0.310984, 1.050018, 1.000002, 0, 0, 0, 0.95106, -0.309018, 0, 0.309018, 0.951058), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "CalyxBlade5", s = "Wedge", z = Vector3.new(0.62, 0.55, 0.32), cf = CFrame.new(0.90933, 0.310984, 0.524994, 0.500001, 0.267617, 0.823641, 0, 0.95106, -0.309018, -0.866027, 0.154509, 0.475529), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "CalyxBlade6", s = "Wedge", z = Vector3.new(0.62, 0.55, 0.32), cf = CFrame.new(0.90933, 0.310984, -0.524994, -0.500001, 0.267617, 0.823641, 0, 0.95106, -0.309018, -0.866027, -0.154509, -0.475529), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "OuterQuillShaft_1", s = "Block", z = Vector3.new(0.34, 2.55, 0.3), cf = CFrame.new(0.000002, 1.459004, -1.013275, -1.000002, 0, 0, 0, 0.994526, -0.104529, 0, -0.104529, -0.994524), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "OuterQuillSpine_1", s = "Block", z = Vector3.new(0.14, 2.4225, 0.08), cf = CFrame.new(0, 1.444369, -1.152527, -1.000002, 0, 0, 0, 0.994526, -0.104529, 0, -0.104529, -0.994524), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "OuterQuillTip_1", s = "Wedge", z = Vector3.new(0.32, 0.805, 0.28), cf = CFrame.new(-0.000002, 3.127322, -1.188629, 1.000002, 0, 0, 0, -0.994526, -0.104529, 0, 0.104529, -0.994524), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "OuterGoldBand_1", s = "Block", z = Vector3.new(0.36, 0.12, 0.32), cf = CFrame.new(0, 2.727025, -1.146576, -1.000002, 0, 0, 0, 0.994526, -0.104529, 0, -0.104529, -0.994524), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "OuterQuillShaft_2", s = "Block", z = Vector3.new(0.34, 2.95, 0.3), cf = CFrame.new(-0.704086, 1.661443, -0.704102, -0.707108, -0.055479, -0.704928, 0, 0.996921, -0.078459, 0.707108, -0.055479, -0.704928), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "OuterQuillSpine_2", s = "Block", z = Vector3.new(0.14, 2.8025, 0.08), cf = CFrame.new(-0.802778, 1.650458, -0.802795, -0.707108, -0.055479, -0.704928, 0, 0.996921, -0.078459, 0.707108, -0.055479, -0.704928), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "OuterQuillTip_2", s = "Wedge", z = Vector3.new(0.32, 0.925, 0.28), cf = CFrame.new(-0.811579, 3.592977, -0.811584, 0.707108, 0.055479, -0.704928, 0, -0.996921, -0.078459, -0.707108, 0.055479, -0.704928), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "OuterGoldBand_2", s = "Block", z = Vector3.new(0.36, 0.12, 0.32), cf = CFrame.new(-0.785917, 3.131903, -0.785919, -0.707108, -0.055479, -0.704928, 0, 0.996921, -0.078459, 0.707108, -0.055479, -0.704928), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "OuterQuillShaft_3", s = "Block", z = Vector3.new(0.34, 2.55, 0.3), cf = CFrame.new(-1.013273, 1.459004, 0, 0, -0.104529, -0.994524, 0, 0.994526, -0.104529, 1.000002, 0, 0), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "OuterQuillSpine_3", s = "Block", z = Vector3.new(0.14, 2.4225, 0.08), cf = CFrame.new(-1.152508, 1.44437, 0, 0, -0.104529, -0.994524, 0, 0.994526, -0.104529, 1.000002, 0, 0), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "OuterQuillTip_3", s = "Wedge", z = Vector3.new(0.32, 0.805, 0.28), cf = CFrame.new(-1.188622, 3.127322, 0, 0, 0.104529, -0.994524, 0, -0.994526, -0.104529, -1.000002, 0, 0), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "OuterGoldBand_3", s = "Block", z = Vector3.new(0.36, 0.12, 0.32), cf = CFrame.new(-1.146549, 2.727025, 0, 0, -0.104529, -0.994524, 0, 0.994526, -0.104529, 1.000002, 0, 0), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "OuterQuillShaft_4", s = "Block", z = Vector3.new(0.34, 2.95, 0.3), cf = CFrame.new(-0.704086, 1.661443, 0.704102, 0.707108, -0.055479, -0.704928, 0, 0.996921, -0.078459, 0.707108, 0.055479, 0.704928), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "OuterQuillSpine_4", s = "Block", z = Vector3.new(0.14, 2.8025, 0.08), cf = CFrame.new(-0.802776, 1.650458, 0.802795, 0.707108, -0.055479, -0.704928, 0, 0.996921, -0.078459, 0.707108, 0.055479, 0.704928), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "OuterQuillTip_4", s = "Wedge", z = Vector3.new(0.32, 0.925, 0.28), cf = CFrame.new(-0.811575, 3.592978, 0.811584, -0.707108, 0.055479, -0.704928, 0, -0.996921, -0.078459, -0.707108, -0.055479, 0.704928), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "OuterGoldBand_4", s = "Block", z = Vector3.new(0.36, 0.12, 0.32), cf = CFrame.new(-0.785917, 3.131902, 0.785919, 0.707108, -0.055479, -0.704928, 0, 0.996921, -0.078459, 0.707108, 0.055479, 0.704928), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "OuterQuillShaft_5", s = "Block", z = Vector3.new(0.34, 2.55, 0.3), cf = CFrame.new(0.000002, 1.459004, 1.013275, 1.000002, 0, 0, 0, 0.994526, -0.104529, 0, 0.104529, 0.994524), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "OuterQuillSpine_5", s = "Block", z = Vector3.new(0.14, 2.4225, 0.08), cf = CFrame.new(0, 1.444371, 1.152496, 1.000002, 0, 0, 0, 0.994526, -0.104529, 0, 0.104529, 0.994524), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "OuterQuillTip_5", s = "Wedge", z = Vector3.new(0.32, 0.805, 0.28), cf = CFrame.new(0, 3.127322, 1.188629, -1.000002, 0, 0, 0, -0.994526, -0.104529, 0, -0.104529, 0.994524), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "OuterGoldBand_5", s = "Block", z = Vector3.new(0.36, 0.12, 0.32), cf = CFrame.new(0, 2.727026, 1.146545, 1.000002, 0, 0, 0, 0.994526, -0.104529, 0, 0.104529, 0.994524), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "OuterQuillShaft_6", s = "Block", z = Vector3.new(0.34, 2.95, 0.3), cf = CFrame.new(0.704088, 1.661443, 0.704102, 0.707108, 0.055479, 0.704928, 0, 0.996921, -0.078459, -0.707108, 0.055479, 0.704928), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "OuterQuillSpine_6", s = "Block", z = Vector3.new(0.14, 2.8025, 0.08), cf = CFrame.new(0.80278, 1.650458, 0.802795, 0.707108, 0.055479, 0.704928, 0, 0.996921, -0.078459, -0.707108, 0.055479, 0.704928), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "OuterQuillTip_6", s = "Wedge", z = Vector3.new(0.32, 0.925, 0.28), cf = CFrame.new(0.811579, 3.592978, 0.811584, -0.707108, -0.055479, 0.704928, 0, -0.996921, -0.078459, 0.707108, -0.055479, 0.704928), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "OuterGoldBand_6", s = "Block", z = Vector3.new(0.36, 0.12, 0.32), cf = CFrame.new(0.785917, 3.131902, 0.785919, 0.707108, 0.055479, 0.704928, 0, 0.996921, -0.078459, -0.707108, 0.055479, 0.704928), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
		{ n = "OuterQuillShaft_7", s = "Block", z = Vector3.new(0.34, 2.55, 0.3), cf = CFrame.new(1.013277, 1.459004, 0, 0, 0.104529, 0.994524, 0, 0.994526, -0.104529, -1.000002, 0, 0), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 32
		{ n = "OuterQuillSpine_7", s = "Block", z = Vector3.new(0.14, 2.4225, 0.08), cf = CFrame.new(1.152508, 1.44437, -0.000031, 0, 0.104529, 0.994524, 0, 0.994526, -0.104529, -1.000002, 0, 0), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 33
		{ n = "OuterQuillTip_7", s = "Wedge", z = Vector3.new(0.32, 0.805, 0.28), cf = CFrame.new(1.188622, 3.127323, -0.000031, 0, -0.104529, 0.994524, 0, -0.994526, -0.104529, 1.000002, 0, 0), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 34
		{ n = "OuterGoldBand_7", s = "Block", z = Vector3.new(0.36, 0.12, 0.32), cf = CFrame.new(1.146549, 2.727025, 0, 0, 0.104529, 0.994524, 0, 0.994526, -0.104529, -1.000002, 0, 0), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 35
		{ n = "OuterQuillShaft_8", s = "Block", z = Vector3.new(0.34, 2.95, 0.3), cf = CFrame.new(0.704088, 1.661443, -0.704071, -0.707108, 0.055479, 0.704928, 0, 0.996921, -0.078459, -0.707108, -0.055479, -0.704928), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 36
		{ n = "OuterQuillSpine_8", s = "Block", z = Vector3.new(0.14, 2.8025, 0.08), cf = CFrame.new(0.802774, 1.650458, -0.802765, -0.707108, 0.055479, 0.704928, 0, 0.996921, -0.078459, -0.707108, -0.055479, -0.704928), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 37
		{ n = "OuterQuillTip_8", s = "Wedge", z = Vector3.new(0.32, 0.925, 0.28), cf = CFrame.new(0.811577, 3.592978, -0.811554, 0.707108, -0.055479, 0.704928, 0, -0.996921, -0.078459, 0.707108, 0.055479, -0.704928), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 38
		{ n = "OuterGoldBand_8", s = "Block", z = Vector3.new(0.36, 0.12, 0.32), cf = CFrame.new(0.785919, 3.131902, -0.785889, -0.707108, 0.055479, 0.704928, 0, 0.996921, -0.078459, -0.707108, -0.055479, -0.704928), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 39
		{ n = "MidQuillShaft_1", s = "Block", z = Vector3.new(0.38, 3.7, 0.34), cf = CFrame.new(-0.223701, 2.189864, -0.54007, -0.923881, -0.013355, -0.382451, 0, 0.999395, -0.0349, 0.382684, -0.032243, -0.923318), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 40
		{ n = "MidQuillTip_1", s = "Wedge", z = Vector3.new(0.36, 1.06, 0.32), cf = CFrame.new(-0.255487, 4.568423, -0.616821, 0.923881, 0.013356, -0.382451, 0, -0.999395, -0.0349, -0.382684, 0.032243, -0.923319), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 41
		{ n = "MidTipFacet_1", s = "Block", z = Vector3.new(0.2, 0.742, 0.1), cf = CFrame.new(-0.234661, 4.729423, -0.566528, 0.923881, 0.013356, -0.382451, 0, -0.999395, -0.0349, -0.382684, 0.032243, -0.923319), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 42
		{ n = "MidQuillShaft_2", s = "Block", z = Vector3.new(0.38, 4.2, 0.34), cf = CFrame.new(-0.588213, 2.439714, -0.077454, -0.130526, -0.034601, -0.990843, 0, 0.999395, -0.0349, 0.991447, -0.004555, -0.130447), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 43
		{ n = "MidQuillTip_2", s = "Wedge", z = Vector3.new(0.36, 1.16, 0.32), cf = CFrame.new(-0.680944, 5.118092, -0.089661, 0.130527, 0.034601, -0.990843, 0, -0.999395, -0.0349, -0.991447, 0.004555, -0.130447), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 44
		{ n = "MidTipFacet_2", s = "Block", z = Vector3.new(0.2, 0.812, 0.1), cf = CFrame.new(-0.627516, 5.29408, -0.082642, 0.130527, 0.034601, -0.990843, 0, -0.999395, -0.0349, -0.991447, 0.004555, -0.130447), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 45
		{ n = "MidQuillShaft_3", s = "Block", z = Vector3.new(0.38, 3.7, 0.34), cf = CFrame.new(-0.355858, 2.189864, 0.463776, 0.793355, -0.021246, -0.608392, 0, 0.999395, -0.0349, 0.608763, 0.027688, 0.792872), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 46
		{ n = "MidQuillTip_3", s = "Wedge", z = Vector3.new(0.36, 1.06, 0.32), cf = CFrame.new(-0.406427, 4.568424, 0.529663, -0.793355, 0.021246, -0.608392, 0, -0.999395, -0.0349, -0.608763, -0.027688, 0.792871), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 47
		{ n = "MidTipFacet_3", s = "Block", z = Vector3.new(0.2, 0.742, 0.1), cf = CFrame.new(-0.373304, 4.729423, 0.486511, -0.793355, 0.021246, -0.608392, 0, -0.999395, -0.0349, -0.608763, -0.027688, 0.792871), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 48
		{ n = "MidQuillShaft_4", s = "Block", z = Vector3.new(0.38, 4.2, 0.34), cf = CFrame.new(0.227043, 2.439714, 0.548157, 0.923881, 0.013355, 0.382451, 0, 0.999395, -0.0349, -0.382684, 0.032243, 0.923318), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 49
		{ n = "MidQuillTip_4", s = "Wedge", z = Vector3.new(0.36, 1.16, 0.32), cf = CFrame.new(0.262836, 5.118093, 0.634552, -0.923881, -0.013356, 0.382451, 0, -0.999395, -0.0349, 0.382684, -0.032243, 0.923319), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 50
		{ n = "MidTipFacet_4", s = "Block", z = Vector3.new(0.2, 0.812, 0.1), cf = CFrame.new(0.242212, 5.294081, 0.584747, -0.923881, -0.013356, 0.382451, 0, -0.999395, -0.0349, 0.382684, -0.032243, 0.923319), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 51
		{ n = "MidQuillShaft_5", s = "Block", z = Vector3.new(0.38, 3.7, 0.34), cf = CFrame.new(0.579567, 2.189864, 0.076294, 0.130527, 0.034601, 0.990843, 0, 0.999395, -0.0349, -0.991447, 0.004555, 0.130447), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 52
		{ n = "MidQuillTip_5", s = "Wedge", z = Vector3.new(0.36, 1.06, 0.32), cf = CFrame.new(0.661915, 4.568425, 0.087128, -0.130527, -0.034601, 0.990843, 0, -0.999395, -0.0349, 0.991447, -0.004555, 0.130447), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 53
		{ n = "MidTipFacet_5", s = "Block", z = Vector3.new(0.2, 0.742, 0.1), cf = CFrame.new(0.607965, 4.729423, 0.080048, -0.130527, -0.034601, 0.990843, 0, -0.999395, -0.0349, 0.991447, -0.004555, 0.130447), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 54
		{ n = "MidQuillShaft_6", s = "Block", z = Vector3.new(0.38, 4.2, 0.34), cf = CFrame.new(0.361172, 2.439714, -0.470673, -0.793355, 0.021246, 0.608392, 0, 0.999395, -0.0349, -0.608763, -0.027688, -0.792872), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 55
		{ n = "MidQuillTip_6", s = "Wedge", z = Vector3.new(0.36, 1.16, 0.32), cf = CFrame.new(0.418112, 5.118093, -0.544891, 0.793355, -0.021246, 0.608392, 0, -0.999395, -0.0349, 0.608763, 0.027688, -0.792872), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 56
		{ n = "MidTipFacet_6", s = "Block", z = Vector3.new(0.2, 0.812, 0.1), cf = CFrame.new(0.385305, 5.294081, -0.502136, 0.793355, -0.021246, 0.608392, 0, -0.999395, -0.0349, 0.608763, 0.027688, -0.792872), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 57
		{ n = "CenterSpireHinge", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(0, 0.490985, 0, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(68, 54, 44), m = Enum.Material.Plastic, t = 1, st = false }, -- 58
		{ n = "CentralQuillLower", s = "Block", z = Vector3.new(0.48, 3.2, 0.48), cf = CFrame.new(0, 2.090991, 0, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 59
		{ n = "CentralQuillUpper", s = "Block", z = Vector3.new(0.42, 1.8, 0.42), cf = CFrame.new(0, 4.591001, 0, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(96, 78, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 60
		{ n = "CentralGoldStylus", s = "Block", z = Vector3.new(0.36, 1.25, 0.36), cf = CFrame.new(0, 6.116006, 0, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 61
		{ n = "StylusFacetE", s = "Wedge", z = Vector3.new(0.28, 1.125, 0.12), cf = CFrame.new(-0.139999, 6.116006, 0, 0, 0, -1.000002, 0, 1.000004, 0, 1.000002, 0, 0), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 62
		{ n = "StylusFacetW", s = "Wedge", z = Vector3.new(0.28, 1.125, 0.12), cf = CFrame.new(0.140001, 6.116006, 0, 0, 0, 1.000002, 0, 1.000004, 0, -1.000002, 0, 0), c = Color3.fromRGB(255, 175, 55), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 63
		{ n = "CandleWick", s = "Block", z = Vector3.new(0.12, 0.28, 0.12), cf = CFrame.new(0, 6.881009, 0, -0.996919, 0.078459, 0, 0.078459, 0.996921, 0, 0, 0, -1.000002), c = Color3.fromRGB(42, 34, 30), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 64
		{ n = "CandleFlame", s = "Block", z = Vector3.new(0.32, 0.54, 0.32), cf = CFrame.new(0.029032, 7.24987, 0, -0.996919, 0.078459, 0, 0.078459, 0.996921, 0, 0, 0, -1.000002), c = Color3.fromRGB(255, 200, 92), m = Enum.Material.Neon, st = false, sm = { t = "Sphere", s = Vector3.new(1, 1.45, 1), o = Vector3.new(0, 0, 0) } }, -- 65
		{ n = "FlameKernel", s = "Block", z = Vector3.new(0.208, 0.324, 0.208), cf = CFrame.new(0.024323, 7.190055, 0, -0.996919, 0.078459, 0, 0.078459, 0.996921, 0, 0, 0, -1.000002), c = Color3.fromRGB(255, 235, 150), m = Enum.Material.Neon, st = false, sm = { t = "Sphere", s = Vector3.new(0.9, 1.3, 0.9), o = Vector3.new(0, 0, 0) } }, -- 66
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(-0.000002, -0.930007, 1.050018, 1.000004, 0, 0, 0, 0.951064, -0.309019, 0, 0.309018, 0.95106), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0.909328, -0.930007, 0.525024, 0.500002, 0.267618, 0.823642, 0, 0.951063, -0.309019, -0.866028, 0.154509, 0.47553), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 4, c0 = CFrame.new(0.909328, -0.930007, -0.525024, -0.500002, 0.267618, 0.823642, 0, 0.951064, -0.309019, -0.866029, -0.154509, -0.47553), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 5, c0 = CFrame.new(-0.000002, -0.930007, -1.050018, -1.000004, 0, 0, 0, 0.951064, -0.309019, 0, -0.309018, -0.95106), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 6, c0 = CFrame.new(-0.909332, -0.930007, -0.524994, -0.500002, -0.267618, -0.823642, 0, 0.951063, -0.309019, 0.866029, -0.154509, -0.47553), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 7, c0 = CFrame.new(-0.909332, -0.930007, 0.525024, 0.500002, -0.267618, -0.823642, 0, 0.951063, -0.309019, 0.866029, 0.154509, 0.47553), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 8, c0 = CFrame.new(-0.000002, 0.218017, 1.013306, 1.000004, 0, 0, 0, 0.994529, -0.104529, 0, 0.104529, 0.994526), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 12, c0 = CFrame.new(0.704088, 0.420456, 0.704132, 0.707109, 0.055479, 0.70493, 0, 0.996925, -0.07846, -0.707109, 0.055479, 0.70493), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 16, c0 = CFrame.new(1.013275, 0.218017, 0, 0, 0.104529, 0.994526, 0, 0.994529, -0.104529, -1.000004, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 20, c0 = CFrame.new(0.704088, 0.420456, -0.704102, -0.707109, 0.055479, 0.70493, 0, 0.996925, -0.07846, -0.707109, -0.055479, -0.70493), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 24, c0 = CFrame.new(-0.000002, 0.218017, -1.013275, -1.000004, 0, 0, 0, 0.994529, -0.104529, 0, -0.104529, -0.994526), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 28, c0 = CFrame.new(-0.70409, 0.420456, -0.704102, -0.707109, -0.055479, -0.704929, 0, 0.996925, -0.07846, 0.707109, -0.055479, -0.70493), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 32, c0 = CFrame.new(-1.013279, 0.218017, 0, 0, -0.104529, -0.994526, 0, 0.994529, -0.104529, 1.000004, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 36, c0 = CFrame.new(-0.70409, 0.420456, 0.704102, 0.707109, -0.055479, -0.70493, 0, 0.996925, -0.07846, 0.70711, 0.055479, 0.704929), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 40, c0 = CFrame.new(0.223701, 0.948879, 0.5401, 0.923883, 0.013356, 0.382452, 0, 0.999398, -0.0349, -0.382685, 0.032243, 0.92332), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 43, c0 = CFrame.new(0.588215, 1.19873, 0.077454, 0.130527, 0.034601, 0.990845, 0, 0.999398, -0.0349, -0.991449, 0.004555, 0.130447), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 46, c0 = CFrame.new(0.355858, 0.948879, -0.463776, -0.793356, 0.021246, 0.608393, 0, 0.999398, -0.0349, -0.608764, -0.027688, -0.792873), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 49, c0 = CFrame.new(-0.227043, 1.19873, -0.548157, -0.923883, -0.013356, -0.382452, 0, 0.999398, -0.0349, 0.382685, -0.032243, -0.92332), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 52, c0 = CFrame.new(-0.579569, 0.948879, -0.076294, -0.130527, -0.034601, -0.990845, 0, 0.999398, -0.0349, 0.991449, -0.004555, -0.130447), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 55, c0 = CFrame.new(-0.361172, 1.19873, 0.470703, 0.793356, -0.021246, -0.608393, 0, 0.999398, -0.0349, 0.608764, 0.027688, 0.792873), c1 = CFrame.new() },
		{ k = "Motor6D", n = "CenterSpireJoint", h = 1, a = 1, b = 58, c0 = CFrame.new(0, -0.75, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 9, c0 = CFrame.new(0.000002, 0.000002, 0.140015, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 10, c0 = CFrame.new(0.000004, 1.677515, 0.000031, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 11, c0 = CFrame.new(0.000002, 1.275013, 0.000031, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 13, c0 = CFrame.new(0, 0, 0.139999, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 14, c0 = CFrame.new(0.000015, 1.937513, 0, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 12, a = 12, b = 15, c0 = CFrame.new(0.000015, 1.475012, -0.000015, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 16, a = 16, b = 17, c0 = CFrame.new(0, 0, 0.140001, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 16, a = 16, b = 18, c0 = CFrame.new(0, 1.677514, -0.000002, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 16, a = 16, b = 19, c0 = CFrame.new(0, 1.275011, 0, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 21, c0 = CFrame.new(0.000015, 0.000002, 0.139999, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 22, c0 = CFrame.new(0, 1.937515, 0, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 23, c0 = CFrame.new(0, 1.475012, 0, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 24, a = 24, b = 25, c0 = CFrame.new(-0.000002, 0, 0.139984, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 24, a = 24, b = 26, c0 = CFrame.new(-0.000002, 1.677517, 0.000031, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 24, a = 24, b = 27, c0 = CFrame.new(-0.000002, 1.275013, 0, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 29, c0 = CFrame.new(-0.000015, 0, 0.140015, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 30, c0 = CFrame.new(0, 1.937513, 0.000015, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 31, c0 = CFrame.new(0.000015, 1.475012, 0, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 32, a = 32, b = 33, c0 = CFrame.new(0.000031, 0, 0.139997, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 32, a = 32, b = 34, c0 = CFrame.new(0.000031, 1.677515, -0.000006, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 32, a = 32, b = 35, c0 = CFrame.new(0, 1.27501, -0.000004, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 37, c0 = CFrame.new(0, -0.000001, 0.139999, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 38, c0 = CFrame.new(0, 1.937514, 0, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 36, a = 36, b = 39, c0 = CFrame.new(-0.000015, 1.47501, -0.000015, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 40, a = 40, b = 41, c0 = CFrame.new(0, 2.380019, 0, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 40, a = 40, b = 42, c0 = CFrame.new(0, 2.539021, -0.060028, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 43, a = 43, b = 44, c0 = CFrame.new(-0.000031, 2.68002, 0, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 43, a = 43, b = 45, c0 = CFrame.new(-0.000031, 2.854022, -0.059998, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 46, a = 46, b = 47, c0 = CFrame.new(0, 2.38002, 0, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 46, a = 46, b = 48, c0 = CFrame.new(0, 2.539022, -0.059998, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 49, a = 49, b = 50, c0 = CFrame.new(0, 2.680021, -0.000031, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 49, a = 49, b = 51, c0 = CFrame.new(0.000015, 2.854023, -0.060059, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 52, a = 52, b = 53, c0 = CFrame.new(0, 2.38002, 0, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 52, a = 52, b = 54, c0 = CFrame.new(0, 2.539021, -0.059998, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 55, a = 55, b = 56, c0 = CFrame.new(0, 2.680022, 0.000015, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 55, a = 55, b = 57, c0 = CFrame.new(0, 2.854023, -0.059982, -1.000004, 0, 0, 0, -1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 58, a = 58, b = 59, c0 = CFrame.new(0, 1.600011, 0, 1.000004, 0, 0, 0, 1.000007, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 58, a = 58, b = 60, c0 = CFrame.new(0, 4.10003, 0, 1.000004, 0, 0, 0, 1.000007, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 58, a = 58, b = 61, c0 = CFrame.new(0, 5.625041, 0, 1.000004, 0, 0, 0, 1.000007, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 58, a = 58, b = 62, c0 = CFrame.new(0.139999, 5.625041, 0, 0, 0, 1.000004, 0, 1.000007, 0, -1.000004, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 58, a = 58, b = 63, c0 = CFrame.new(-0.140001, 5.625041, 0, 0, 0, -1.000004, 0, 1.000007, 0, 1.000004, 0, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 58, a = 58, b = 64, c0 = CFrame.new(0, 6.390047, 0, 0.996921, -0.078459, 0, 0.07846, 0.996925, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 58, a = 58, b = 65, c0 = CFrame.new(-0.029032, 6.758909, 0, 0.996921, -0.078459, 0, 0.07846, 0.996925, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 58, a = 58, b = 66, c0 = CFrame.new(-0.024323, 6.699094, 0, 0.996921, -0.078459, 0, 0.07846, 0.996925, 0, 0, 0, 1.000004), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "CandleLight", p = 65, range = 15, brightness = 2.65, color = Color3.new(1, 0.803922, 0.431373), shadows = true, enabled = true },
		{ n = "CoreHaloLight", p = 65, range = 8, brightness = 1.35, color = Color3.new(1, 0.54902, 0.156863), shadows = false, enabled = true },
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
		{ n = "Studs_%s", p = 59, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 60, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 61, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 62, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 63, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 64, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
