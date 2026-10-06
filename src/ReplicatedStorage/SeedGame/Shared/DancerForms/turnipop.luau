--!strict
--==============================================================================
-- DANCER FORM: Turnipop (a Ticket Disco / Disco Only dancer)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "disco Dancers/Turnipop" by a read-only generator on 2026-10-03. The
-- original (and its preview dance script) is backed up in
-- output/model-backups/2026-10-03-disco-dancers and was moved out of the live
-- map to ServerStorage.DiscoDancerOriginals, not deleted.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the model's BASE:
-- its Pelvis's x/z at the lowest drawn point, facing the way the Pelvis
-- faces -- the face looks along -Z), colour, material, surface, attribute,
-- joint and stud texture is the supplied number, at the size it was supplied
-- (ModelScale is what the owner's Scale tool left it at). WeldConstraints are
-- recorded as Welds (C0 = Part1 in Part0's frame, C1 = identity). Joints
-- point at parts by INDEX. DancerForms (the parent) lists the eight; the
-- dance is DancerMoves'.
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "disco Dancers/Turnipop", Kind = "dancer", Yaw = 0,
	Size = Vector3.new(6.340965, 12.623734, 5.631016), Height = 12.623734, PartCount = 27,
	Base = 1,
	ModelScale = 3.483624,
	Attributes = { AutoDance = true, DanceBPM = 124, DanceEnergy = 1, ProceduralDance = true, RateScale = 1, Unit = "TurnipDancer" },
	Parts = {
		{ n = "Pelvis", s = "Block", z = Vector3.new(4.250021, 2.508209, 3.901659), cf = CFrame.new(0, 3.379116, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(152, 52, 196), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "PelvisCross", s = "Block", z = Vector3.new(3.901659, 2.368864, 3.553296), cf = CFrame.new(0, 3.379116, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(118, 36, 155), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "RootBelt", s = "Block", z = Vector3.new(4.598384, 0.55738, 4.250021), cf = CFrame.new(0, 2.612718, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 175, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "TailRoot", s = "Block", z = Vector3.new(0.696725, 1.11476, 1.323777), cf = CFrame.new(0.000023, 2.856572, 2.159857, 1, 0, 0, 0, 0.906308, -0.422618, 0, 0.422618, 0.906308), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "Torso", s = "Block", z = Vector3.new(3.762314, 2.159847, 3.413952), cf = CFrame.new(0, 5.399617, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "TorsoCross", s = "Block", z = Vector3.new(3.413952, 2.020502, 3.065589), cf = CFrame.new(0, 5.399617, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(118, 36, 155), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "Head", s = "Block", z = Vector3.new(3.657805, 2.368864, 3.309443), cf = CFrame.new(0, 7.559464, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(152, 52, 196), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "HeadCross", s = "Block", z = Vector3.new(3.309443, 2.229519, 2.995917), cf = CFrame.new(0, 7.559464, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(118, 36, 155), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "FacePlate", s = "Block", z = Vector3.new(2.856572, 1.881157, 0.348362), cf = CFrame.new(-0.000023, 7.489792, -1.53279, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 246, 232), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "EyeL", s = "Block", z = Vector3.new(0.766397, 0.83607, 0.27869), cf = CFrame.new(-0.73156, 7.768481, -1.776643, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 10
		{ n = "EyeR", s = "Block", z = Vector3.new(0.766397, 0.83607, 0.27869), cf = CFrame.new(0.731583, 7.768481, -1.776629, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 11
		{ n = "BlushL", s = "Block", z = Vector3.new(0.522544, 0.27869, 0.209017), cf = CFrame.new(-1.045074, 7.315611, -1.741812, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, st = false }, -- 12
		{ n = "BlushR", s = "Block", z = Vector3.new(0.522544, 0.27869, 0.209017), cf = CFrame.new(1.045097, 7.315611, -1.741798, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, st = false }, -- 13
		{ n = "Smile", s = "Block", z = Vector3.new(0.766397, 0.27869, 0.209017), cf = CFrame.new(-0.000023, 7.036921, -1.741798, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 30, 42), m = Enum.Material.Plastic, st = false }, -- 14
		{ n = "SproutStem", s = "Block", z = Vector3.new(1.045087, 0.766397, 1.045087), cf = CFrame.new(0, 9.022586, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(38, 122, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "SproutLeafL", s = "Block", z = Vector3.new(1.11476, 2.961081, 0.487707), cf = CFrame.new(-1.114761, 10.590217, 0, 0.913545, -0.406737, 0, 0.406737, 0.913546, 0, 0, 0, 1), c = Color3.fromRGB(56, 175, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "SproutTipL", s = "Block", z = Vector3.new(0.766397, 0.766397, 0.766397), cf = CFrame.new(-1.794914, 12.117792, 0.000013, 0.913546, -0.406737, 0, 0.406737, 0.913546, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 17
		{ n = "SproutLeafR", s = "Block", z = Vector3.new(1.11476, 2.961081, 0.487707), cf = CFrame.new(1.114761, 10.590218, 0, 0.913545, 0.406737, 0, -0.406737, 0.913545, 0, 0, 0, 1), c = Color3.fromRGB(56, 175, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "SproutTipR", s = "Block", z = Vector3.new(0.766397, 0.766397, 0.766397), cf = CFrame.new(1.794861, 12.117803, 0, 0.913546, 0.406737, 0, -0.406737, 0.913546, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 19
		{ n = "ArmL", s = "Block", z = Vector3.new(0.975415, 1.602467, 0.975415), cf = CFrame.new(-1.811485, 4.91191, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 175, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "HandL", s = "Block", z = Vector3.new(1.323777, 1.254105, 0.627052), cf = CFrame.new(-2.334061, 3.9365, 0, 0.939693, 0.34202, 0, -0.34202, 0.939693, 0, 0, 0, 1), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "ArmR", s = "Block", z = Vector3.new(0.975415, 1.602467, 0.975415), cf = CFrame.new(1.811485, 4.91191, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 175, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "HandR", s = "Block", z = Vector3.new(1.323777, 1.254105, 0.627052), cf = CFrame.new(2.334038, 3.936486, 0, 0.939693, -0.34202, 0, 0.34202, 0.939693, 0, 0, 0, 1), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "LegL", s = "Block", z = Vector3.new(1.323777, 1.567631, 1.323777), cf = CFrame.new(-1.323776, 1.637304, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(152, 52, 196), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "FootL", s = "Block", z = Vector3.new(1.67214, 0.766397, 2.020502), cf = CFrame.new(-1.323776, 0.383199, -0.139335, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 140, 72), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "LegR", s = "Block", z = Vector3.new(1.323777, 1.567631, 1.323777), cf = CFrame.new(1.323776, 1.637304, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(152, 52, 196), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "FootR", s = "Block", z = Vector3.new(1.67214, 0.766397, 2.020502), cf = CFrame.new(1.323753, 0.383199, -0.139361, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 140, 72), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, -0.766397, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 4, c0 = CFrame.new(0.000023, -0.522544, 2.159857, 1, 0, 0, 0, 0.906308, -0.422618, 0, 0.422618, 0.906308), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Waist", h = 1, a = 1, b = 5, c0 = CFrame.new(0, 1.045087, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.975415, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 24, c0 = CFrame.new(-1.323777, -0.975415, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.766397, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 26, c0 = CFrame.new(1.323777, -0.975415, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.766397, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 5, a = 5, b = 6, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 5, a = 5, b = 7, c0 = CFrame.new(0, 1.11476, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.045087, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderL", h = 5, a = 5, b = 20, c0 = CFrame.new(-1.811484, 0.27869, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.766397, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 5, a = 5, b = 22, c0 = CFrame.new(1.811484, 0.27869, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.766397, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 8, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 9, c0 = CFrame.new(-0.000023, -0.069673, -1.53279, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 10, c0 = CFrame.new(-0.73156, 0.209017, -1.776643, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 11, c0 = CFrame.new(0.731583, 0.209017, -1.776629, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 12, c0 = CFrame.new(-1.045074, -0.243854, -1.741812, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 13, c0 = CFrame.new(1.045097, -0.243854, -1.741798, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 14, c0 = CFrame.new(-0.000023, -0.522543, -1.741798, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "SproutJoint", h = 7, a = 7, b = 15, c0 = CFrame.new(0, 1.184432, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.27869, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 16, c0 = CFrame.new(-1.114761, 1.567631, 0, 0.913545, -0.406737, 0, 0.406737, 0.913546, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 18, c0 = CFrame.new(1.114761, 1.567632, 0, 0.913545, 0.406737, 0, -0.406737, 0.913545, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 16, a = 16, b = 17, c0 = CFrame.new(-0.000038, 1.672153, 0.000013, 1, 0, 0, 0, 1.000001, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 19, c0 = CFrame.new(-0.000023, 1.672142, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 21, c0 = CFrame.new(-0.522575, -0.97541, 0, 0.939693, 0.34202, 0, -0.34202, 0.939693, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 23, c0 = CFrame.new(0.522552, -0.975424, 0, 0.939693, -0.34202, 0, 0.34202, 0.939693, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 24, a = 24, b = 25, c0 = CFrame.new(0, -1.254105, -0.139335, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 27, c0 = CFrame.new(-0.000023, -1.254105, -0.139361, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 8, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 18, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 23, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 25, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 3.483624, v = 3.483624, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
