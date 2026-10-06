--!strict
--==============================================================================
-- DANCER FORM: Pricklepop (a Ticket Disco / Disco Only dancer)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "disco Dancers/Pricklepop" by a read-only generator on 2026-10-03. The
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
	Source = "disco Dancers/Pricklepop", Kind = "dancer", Yaw = 0,
	Size = Vector3.new(2.440002, 2.98, 1.555634), Height = 2.98, PartCount = 28,
	Base = 1,
	ModelScale = 1,
	Attributes = { AutoDance = true, DanceBPM = 124, DanceEnergy = 1, ProceduralDance = true, RateScale = 1, Unit = "CactusDancer" },
	Parts = {
		{ n = "Pelvis", s = "Block", z = Vector3.new(1.25, 0.72, 1.15), cf = CFrame.new(0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "PelvisCross", s = "Block", z = Vector3.new(1.15, 0.68, 1.05), cf = CFrame.new(0, 1, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(36, 122, 60), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "PurpleRibBelt", s = "Block", z = Vector3.new(1.32, 0.18, 1.22), cf = CFrame.new(0, 0.78, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(158, 62, 212), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "Torso", s = "Block", z = Vector3.new(1.18, 0.65, 1.08), cf = CFrame.new(0, 1.6, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "TorsoCross", s = "Block", z = Vector3.new(1.08, 0.6, 0.98), cf = CFrame.new(0, 1.6, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(36, 122, 60), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "ChestRib", s = "Block", z = Vector3.new(0.24, 0.6, 0.12), cf = CFrame.new(-0.000008, 1.6, -0.550003, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(36, 122, 60), m = Enum.Material.Plastic, st = false }, -- 6
		{ n = "Head", s = "Block", z = Vector3.new(1.12, 0.72, 1.02), cf = CFrame.new(0, 2.27, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "HeadCross", s = "Block", z = Vector3.new(1.02, 0.68, 0.92), cf = CFrame.new(0, 2.27, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(36, 122, 60), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "FacePlate", s = "Block", z = Vector3.new(0.85, 0.58, 0.1), cf = CFrame.new(0, 2.23, -0.459999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 246, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "EyeL", s = "Block", z = Vector3.new(0.22, 0.24, 0.08), cf = CFrame.new(-0.220001, 2.32, -0.529999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 10
		{ n = "EyeR", s = "Block", z = Vector3.new(0.22, 0.24, 0.08), cf = CFrame.new(0.220001, 2.32, -0.530006, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 11
		{ n = "BlushL", s = "Block", z = Vector3.new(0.16, 0.09, 0.06), cf = CFrame.new(-0.320007, 2.19, -0.520004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 62, 138), m = Enum.Material.Plastic, st = false }, -- 12
		{ n = "BlushR", s = "Block", z = Vector3.new(0.16, 0.09, 0.06), cf = CFrame.new(0.319992, 2.19, -0.520004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 62, 138), m = Enum.Material.Plastic, st = false }, -- 13
		{ n = "Smile", s = "Block", z = Vector3.new(0.24, 0.1, 0.06), cf = CFrame.new(0, 2.11, -0.520004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 32, 40), m = Enum.Material.Plastic, st = false }, -- 14
		{ n = "CrownStem", s = "Block", z = Vector3.new(0.38, 0.14, 0.38), cf = CFrame.new(0, 2.69, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(36, 122, 60), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "CrownPetalL", s = "Block", z = Vector3.new(0.36, 0.14, 0.62), cf = CFrame.new(0, 2.77, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 62, 138), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "CrownPetalR", s = "Block", z = Vector3.new(0.62, 0.14, 0.36), cf = CFrame.new(0, 2.77, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 62, 138), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "CrownCore", s = "Block", z = Vector3.new(0.28, 0.22, 0.28), cf = CFrame.new(0, 2.87, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 18
		{ n = "BranchArmL_H", s = "Block", z = Vector3.new(0.55, 0.38, 0.38), cf = CFrame.new(-0.780001, 1.68, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "BranchArmL_V", s = "Block", z = Vector3.new(0.38, 0.62, 0.38), cf = CFrame.new(-1.030001, 2.04, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "SpineBudL", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(-1.030001, 2.36, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(158, 62, 212), m = Enum.Material.Neon, st = false }, -- 21
		{ n = "BranchArmR_H", s = "Block", z = Vector3.new(0.55, 0.38, 0.38), cf = CFrame.new(0.780001, 1.68, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "BranchArmR_V", s = "Block", z = Vector3.new(0.38, 0.62, 0.38), cf = CFrame.new(1.030001, 2.04, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "SpineBudR", s = "Block", z = Vector3.new(0.2, 0.2, 0.2), cf = CFrame.new(1.030001, 2.36, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(158, 62, 212), m = Enum.Material.Neon, st = false }, -- 24
		{ n = "LegL", s = "Block", z = Vector3.new(0.42, 0.44, 0.42), cf = CFrame.new(-0.4, 0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "FootL", s = "Block", z = Vector3.new(0.5, 0.22, 0.6), cf = CFrame.new(-0.4, 0.11, -0.050003, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(45, 135, 70), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "LegR", s = "Block", z = Vector3.new(0.42, 0.44, 0.42), cf = CFrame.new(0.4, 0.5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 82), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "FootR", s = "Block", z = Vector3.new(0.5, 0.22, 0.6), cf = CFrame.new(0.4, 0.11, -0.050003, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(45, 135, 70), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, -0.22, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Waist", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 0.32, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.28, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 25, c0 = CFrame.new(-0.4, -0.28, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.22, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 27, c0 = CFrame.new(0.4, -0.28, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.22, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 6, c0 = CFrame.new(-0.000008, 0, -0.550003, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 4, a = 4, b = 7, c0 = CFrame.new(0, 0.35, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.32, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderL", h = 4, a = 4, b = 19, c0 = CFrame.new(-0.58, 0.08, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0.2, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 4, a = 4, b = 22, c0 = CFrame.new(0.58, 0.08, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-0.2, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 8, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 9, c0 = CFrame.new(0, -0.04, -0.459999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 10, c0 = CFrame.new(-0.220001, 0.05, -0.529999, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 11, c0 = CFrame.new(0.220001, 0.05, -0.530006, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 12, c0 = CFrame.new(-0.320007, -0.08, -0.520004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 13, c0 = CFrame.new(0.319992, -0.08, -0.520004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 14, c0 = CFrame.new(0, -0.16, -0.520004, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CrownJoint", h = 7, a = 7, b = 15, c0 = CFrame.new(0, 0.36, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.06, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 16, c0 = CFrame.new(0, 0.08, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 17, c0 = CFrame.new(0, 0.08, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 18, c0 = CFrame.new(0, 0.18, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 20, c0 = CFrame.new(-0.25, 0.36, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 20, a = 20, b = 21, c0 = CFrame.new(0, 0.32, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 23, c0 = CFrame.new(0.25, 0.36, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 24, c0 = CFrame.new(0, 0.32, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 25, a = 25, b = 26, c0 = CFrame.new(0, -0.39, -0.050003, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 28, c0 = CFrame.new(0, -0.39, -0.050003, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 8, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 17, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 23, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 25, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 28, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1, v = 1, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
