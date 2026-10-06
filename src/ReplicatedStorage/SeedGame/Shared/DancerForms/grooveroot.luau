--!strict
--==============================================================================
-- DANCER FORM: Grooveroot (a Ticket Disco / Disco Only dancer)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "disco Dancers/Grooveroot" by a read-only generator on 2026-10-03. The
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
	Source = "disco Dancers/Grooveroot", Kind = "dancer", Yaw = 0,
	Size = Vector3.new(3.898396, 7.089999, 2.365738), Height = 7.089999, PartCount = 22,
	Base = 1,
	ModelScale = 1.733496,
	Attributes = { AutoDance = true, DanceBPM = 124, DanceEnergy = 1, ProceduralDance = true, RateScale = 1, Unit = "Dancer" },
	Parts = {
		{ n = "Pelvis", s = "Block", z = Vector3.new(1.993521, 1.300122, 1.646822), cf = CFrame.new(0, 2.288216, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(68, 142, 64), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "PelvisCross", s = "Block", z = Vector3.new(1.820171, 1.213447, 1.525477), cf = CFrame.new(0, 2.288216, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(44, 98, 42), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "LeafSkirt", s = "Block", z = Vector3.new(2.34022, 0.346699, 1.993521), cf = CFrame.new(0, 1.802832, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(105, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "Torso", s = "Block", z = Vector3.new(1.560147, 1.300122, 1.386797), cf = CFrame.new(0, 3.501663, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(68, 142, 64), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "TorsoCross", s = "Block", z = Vector3.new(1.386797, 1.213447, 1.248117), cf = CFrame.new(0, 3.501663, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(44, 98, 42), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "Head", s = "Block", z = Vector3.new(1.993521, 1.646822, 1.646822), cf = CFrame.new(0, 5.06181, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 175, 35), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "HeadCross", s = "Block", z = Vector3.new(1.820171, 1.560147, 1.525477), cf = CFrame.new(0, 5.06181, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(245, 92, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "PetalCrown", s = "Block", z = Vector3.new(2.426895, 0.381369, 2.166871), cf = CFrame.new(0, 5.789882, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(245, 92, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "FacePlate", s = "Block", z = Vector3.new(1.352127, 1.178778, 0.20802), cf = CFrame.new(0, 4.992475, -0.762741, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(244, 236, 218), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "MouthBud", s = "Block", z = Vector3.new(0.416039, 0.10401, 0.10401), cf = CFrame.new(0, 4.680445, -0.866737, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(36, 48, 32), m = Enum.Material.Plastic, st = false }, -- 10
		{ n = "EyeL", s = "Block", z = Vector3.new(0.346699, 0.346699, 0.13868), cf = CFrame.new(-0.416042, 5.200493, -0.866745, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 40), m = Enum.Material.Neon, st = false }, -- 11
		{ n = "EyeR", s = "Block", z = Vector3.new(0.346699, 0.346699, 0.13868), cf = CFrame.new(0.416042, 5.200493, -0.866745, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 40), m = Enum.Material.Neon, st = false }, -- 12
		{ n = "StamenStalk", s = "Block", z = Vector3.new(0.312029, 0.780073, 0.312029), cf = CFrame.new(0, 6.240588, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(68, 142, 64), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 13
		{ n = "StamenBloom", s = "Block", z = Vector3.new(0.728068, 0.728068, 0.728068), cf = CFrame.new(0, 6.725965, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(245, 92, 54), m = Enum.Material.Neon, st = false }, -- 14
		{ n = "ArmL", s = "Block", z = Vector3.new(0.520049, 1.040098, 0.520049), cf = CFrame.new(-0.901417, 3.276309, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(68, 142, 64), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "LeafHandL", s = "Block", z = Vector3.new(1.126773, 0.901418, 0.20802), cf = CFrame.new(-1.248119, 2.721591, 0.000015, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(105, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "ArmR", s = "Block", z = Vector3.new(0.520049, 1.040098, 0.520049), cf = CFrame.new(0.901417, 3.276309, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(68, 142, 64), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "LeafHandR", s = "Block", z = Vector3.new(1.126773, 0.901418, 0.20802), cf = CFrame.new(1.248116, 2.721591, 0, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(105, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "LegL", s = "Block", z = Vector3.new(0.658729, 1.126773, 0.658729), cf = CFrame.new(-0.728069, 1.126773, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(88, 64, 50), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "FootL", s = "Block", z = Vector3.new(0.901418, 0.450709, 1.178778), cf = CFrame.new(-0.728069, 0.225354, -0.086678, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(105, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "LegR", s = "Block", z = Vector3.new(0.658729, 1.126773, 0.658729), cf = CFrame.new(0.728069, 1.126773, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(88, 64, 50), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "FootR", s = "Block", z = Vector3.new(0.901418, 0.450709, 1.178778), cf = CFrame.new(0.728077, 0.225354, -0.086678, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(105, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, -0.485384, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Waist", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 0.606724, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.606724, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 19, c0 = CFrame.new(-0.728068, -0.606724, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.554719, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 21, c0 = CFrame.new(0.728068, -0.606724, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.554719, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 4, a = 4, b = 6, c0 = CFrame.new(0, 0.780073, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.780073, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderL", h = 4, a = 4, b = 15, c0 = CFrame.new(-0.901418, 0.260024, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.485379, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 4, a = 4, b = 17, c0 = CFrame.new(0.901418, 0.260024, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.485379, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 7, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 8, c0 = CFrame.new(0, 0.728072, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 9, c0 = CFrame.new(0, -0.069335, -0.762741, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 10, c0 = CFrame.new(0, -0.381365, -0.866737, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 11, c0 = CFrame.new(-0.416042, 0.138683, -0.866745, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 12, c0 = CFrame.new(0.416042, 0.138683, -0.866745, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "StamenJoint", h = 6, a = 6, b = 13, c0 = CFrame.new(0, 0.832078, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.346699, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 13, a = 13, b = 14, c0 = CFrame.new(0, 0.485377, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 16, c0 = CFrame.new(-0.346703, -0.554718, 0.000015, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 17, a = 17, b = 18, c0 = CFrame.new(0.346699, -0.554718, 0, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 20, c0 = CFrame.new(0, -0.901419, -0.086678, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 21, a = 21, b = 22, c0 = CFrame.new(0.000008, -0.901419, -0.086678, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 8, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 13, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 17, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 18, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.733496, v = 1.733496, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
