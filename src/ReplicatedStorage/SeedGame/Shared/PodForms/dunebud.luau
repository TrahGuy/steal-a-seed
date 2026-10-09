--!strict
--==============================================================================
-- POD FORM: Dunebud (dustbowl pods/DunebudPod)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "dustbowl pods/DunebudPod" by a read-only generator on 2026-10-09. The original was
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
	Source = "dustbowl pods/DunebudPod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(3.376427, 3.785015, 4.198608), Height = 3.785015, PartCount = 18,
	Base = 0, Root = 1,
	Attributes = {},
	Owner = { AutoIdle = true, IdleSpeed = 1, Rarity = "Uncommon", Style = "HuskBud", TextureStyle = "Studded", UnitType = "DunebudPod" },
	Removed = { "FlatBase" },
	Parts = {
		{ n = "BudCore", s = "Block", z = Vector3.new(2.75, 2.75, 2.75), cf = CFrame.new(0, 1.425006, 0.426941, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(246, 220, 152), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 1
		{ n = "ShadowPocket", s = "Block", z = Vector3.new(1.45, 1.35, 0.42), cf = CFrame.new(0, 1.275005, -0.79306, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(48, 32, 22), m = Enum.Material.Plastic, st = false }, -- 2
		{ n = "RearHuskPlate", s = "Block", z = Vector3.new(2.45, 2.65, 0.42), cf = CFrame.new(-0.000002, 1.475006, 1.70694, -1.000002, 0, 0, 0, 0.990272, -0.139174, 0, -0.139173, -0.99027), c = Color3.fromRGB(198, 124, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "LeftHuskPlate", s = "Block", z = Vector3.new(0.42, 2.55, 2.35), cf = CFrame.new(1.260002, 1.475006, 0.546936, -0.98481, 0.173649, 0, 0.173649, 0.984811, 0, 0, 0, -1.000002), c = Color3.fromRGB(198, 124, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "RightHuskPlate", s = "Block", z = Vector3.new(0.42, 2.55, 2.35), cf = CFrame.new(-1.260002, 1.475006, 0.546936, -0.98481, -0.173649, 0, -0.173649, 0.984811, 0, 0, 0, -1.000002), c = Color3.fromRGB(198, 124, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "CrossingStrap1", s = "Block", z = Vector3.new(0.72, 0.34, 2.65), cf = CFrame.new(0, 2.845011, 0.426941, -0.882949, 0, -0.469472, 0, 1.000004, 0, 0.469472, 0, -0.882949), c = Color3.fromRGB(198, 124, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "CrossingStrap2", s = "Block", z = Vector3.new(0.72, 0.34, 2.65), cf = CFrame.new(0, 2.865011, 0.426941, -0.882949, 0, 0.469472, 0, 1.000004, 0, -0.469472, 0, -0.882949), c = Color3.fromRGB(198, 124, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "FrontBaseRim", s = "Block", z = Vector3.new(1.85, 0.55, 0.42), cf = CFrame.new(-0.000002, 0.275001, -0.823059, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(198, 124, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "LiftedPlateHinge", s = "Block", z = Vector3.new(0.3, 0.3, 0.3), cf = CFrame.new(0, 0.675003, -0.923065, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(198, 124, 62), m = Enum.Material.Plastic, t = 1, st = false }, -- 9
		{ n = "LiftedFrontPlate", s = "Block", z = Vector3.new(1.75, 1.75, 0.36), cf = CFrame.new(0.000002, 1.525006, -1.243073, -1.000002, 0, 0, 0, 0.927187, 0.374608, 0, 0.374607, -0.927186), c = Color3.fromRGB(198, 124, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "LiftedWedgeL", s = "Wedge", z = Vector3.new(0.24, 1.75, 0.36), cf = CFrame.new(0.880003, 1.525005, -1.243073, 0, 0, 1.000002, 0.927188, -0.374608, 0, 0.374607, 0.927186, 0), c = Color3.fromRGB(198, 124, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "LiftedWedgeR", s = "Wedge", z = Vector3.new(0.24, 1.75, 0.36), cf = CFrame.new(-0.880001, 1.525004, -1.243073, 0, 0, -1.000002, -0.927188, -0.374608, 0, -0.374607, 0.927186, 0), c = Color3.fromRGB(198, 124, 62), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "PaleKnotCenter", s = "Block", z = Vector3.new(0.92, 0.72, 0.92), cf = CFrame.new(0, 3.045012, 0.426941, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(246, 228, 182), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 13
		{ n = "KnotLobe1", s = "Block", z = Vector3.new(0.55, 0.58, 0.65), cf = CFrame.new(-0.157333, 3.125012, 0.037506, -0.927186, -0.164217, -0.336695, 0, 0.898798, -0.438373, 0.374607, -0.406451, -0.833349), c = Color3.fromRGB(246, 228, 182), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 14
		{ n = "KnotLobe2", s = "Block", z = Vector3.new(0.55, 0.58, 0.65), cf = CFrame.new(-0.389416, 3.125012, 0.58429, 0.374607, -0.406451, -0.833349, 0, 0.898798, -0.438373, 0.927186, 0.164217, 0.336695), c = Color3.fromRGB(246, 228, 182), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 15
		{ n = "KnotLobe3", s = "Block", z = Vector3.new(0.55, 0.58, 0.65), cf = CFrame.new(0.157333, 3.125012, 0.816345, 0.927186, 0.164217, 0.336695, 0, 0.898798, -0.438373, -0.374607, 0.406451, 0.833349), c = Color3.fromRGB(246, 228, 182), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 16
		{ n = "KnotLobe4", s = "Block", z = Vector3.new(0.55, 0.58, 0.65), cf = CFrame.new(0.389418, 3.125012, 0.269592, -0.374608, 0.406451, 0.833349, 0, 0.898798, -0.438373, -0.927186, -0.164217, -0.336695), c = Color3.fromRGB(246, 228, 182), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" }, sm = { t = "Sphere", s = Vector3.new(1, 1, 1), o = Vector3.new(0, 0, 0) } }, -- 17
		{ n = "KnotTip", s = "Wedge", z = Vector3.new(0.48, 0.52, 0.48), cf = CFrame.new(0, 3.525014, 0.426941, -1.000002, 0, 0, 0, 1.000004, 0, 0, 0, -1.000002), c = Color3.fromRGB(246, 228, 182), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, -0.150001, 1.220001, 1.000004, 0, 0, 0, 1.000007, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0.000002, 0.05, -1.279999, 1.000004, 0, 0, 0, 0.990275, -0.139174, 0, 0.139174, 0.990272), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 4, c0 = CFrame.new(-1.260004, 0.05, -0.119995, 0.984811, -0.173649, 0, 0.173649, 0.984815, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 5, c0 = CFrame.new(1.260004, 0.05, -0.119995, 0.984811, 0.173649, 0, -0.173649, 0.984815, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 6, c0 = CFrame.new(0, 1.420011, 0, 0.882951, 0, 0.469473, 0, 1.000007, 0, -0.469473, 0, 0.882951), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 7, c0 = CFrame.new(0, 1.440011, 0, 0.882951, 0, -0.469473, 0, 1.000007, 0, 0.469473, 0, 0.882951), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 8, c0 = CFrame.new(0.000002, -1.150009, 1.25, 1.000004, 0, 0, 0, 1.000007, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Motor6D", n = "LiftedHuskJoint", h = 1, a = 1, b = 9, c0 = CFrame.new(0, -0.75, 1.35, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 13, c0 = CFrame.new(0, 1.620012, 0, 1.000004, 0, 0, 0, 1.000007, 0, 0, 0, 1.000004), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 9, a = 9, b = 10, c0 = CFrame.new(-0.000002, 0.850006, 0.320007, 1.000004, 0, 0, 0, 0.927191, 0.374609, 0, -0.374608, 0.927187), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 11, c0 = CFrame.new(-0.880003, 0, 0, 0, 0, -1.000004, 1.000007, -0.000001, 0, 0.000002, -1.000004, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 12, c0 = CFrame.new(0.880003, 0, 0, 0, 0, 1.000004, -1.000007, -0.000001, 0, -0.000002, -1.000004, 0), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 14, c0 = CFrame.new(0.157333, 0.08, 0.389435, 0.927187, 0.164217, 0.336696, 0, 0.898801, -0.438374, -0.374608, 0.406452, 0.833351), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 15, c0 = CFrame.new(0.389416, 0.08, -0.157349, -0.374608, 0.406452, 0.833351, 0, 0.898801, -0.438374, -0.927187, -0.164217, -0.336696), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 16, c0 = CFrame.new(-0.157335, 0.08, -0.389404, -0.927187, -0.164217, -0.336696, 0, 0.898801, -0.438374, 0.374608, -0.406452, -0.833351), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 17, c0 = CFrame.new(-0.38942, 0.08, 0.157349, 0.374608, -0.406452, -0.833351, 0, 0.898801, -0.438374, 0.927187, 0.164217, 0.336696), c1 = CFrame.new() },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 18, c0 = CFrame.new(0, 0.480003, 0, 1.000004, 0, 0, 0, 1.000008, 0, 0, 0, 1.000004), c1 = CFrame.new() },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StudioFillLight", p = 1, range = 12, brightness = 0.85, color = Color3.new(1, 0.972549, 0.921569), shadows = true, enabled = true },
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
		{ n = "Studs_%s", p = 10, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 11, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 12, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 13, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 14, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 15, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 16, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 17, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_%s", p = 18, faces = { "Top", "Front", "Back", "Left", "Right", "Bottom" }, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
