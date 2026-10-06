--!strict
--==============================================================================
-- DANCER FORM: Bananabop (a Ticket Disco / Disco Only dancer)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "disco Dancers/Bananabop" by a read-only generator on 2026-10-03. The
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
	Source = "disco Dancers/Bananabop", Kind = "dancer", Yaw = 0,
	Size = Vector3.new(14.988716, 16.289995, 13.044509), Height = 16.289995, PartCount = 31,
	Base = 1,
	ModelScale = 4.951366,
	Attributes = { AutoDance = true, DanceBPM = 124, DanceEnergy = 1, ProceduralDance = true, RateScale = 1, Unit = "BananaDancer" },
	Parts = {
		{ n = "Pelvis", s = "Block", z = Vector3.new(5.694071, 3.564984, 5.198935), cf = CFrame.new(0, 4.951367, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "PelvisCross", s = "Block", z = Vector3.new(5.198935, 3.366929, 4.703798), cf = CFrame.new(0, 4.951367, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(36, 120, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "RootSkirt", s = "Block", z = Vector3.new(6.189208, 0.792219, 5.694071), cf = CFrame.new(0, 3.862066, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(92, 205, 85), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "Torso", s = "Block", z = Vector3.new(4.951366, 3.218388, 4.555257), cf = CFrame.new(0, 7.82316, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "TorsoCross", s = "Block", z = Vector3.new(4.45623, 2.97082, 4.060121), cf = CFrame.new(0, 7.82316, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(36, 120, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "BunchStem", s = "Block", z = Vector3.new(1.584437, 1.089301, 1.089301), cf = CFrame.new(0, 7.575591, -2.574694, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(152, 48, 185), m = Enum.Material.Plastic, st = false }, -- 6
		{ n = "Banana1", s = "Block", z = Vector3.new(0.990273, 2.57471, 0.990273), cf = CFrame.new(-0.891289, 6.733858, -2.772715, 0.965926, -0.258819, 0, 0.246152, 0.91865, -0.309017, 0.07998, 0.298488, 0.951057), c = Color3.fromRGB(255, 215, 38), m = Enum.Material.Neon, st = false }, -- 7
		{ n = "Banana2", s = "Block", z = Vector3.new(0.990273, 2.673738, 0.990273), cf = CFrame.new(-0.000038, 6.63483, -2.871802, 1, 0, 0, 0, 0.927184, -0.374607, 0, 0.374607, 0.927184), c = Color3.fromRGB(255, 215, 38), m = Enum.Material.Neon, st = false }, -- 8
		{ n = "Banana3", s = "Block", z = Vector3.new(0.990273, 2.57471, 0.990273), cf = CFrame.new(0.891212, 6.733858, -2.772753, 0.965926, 0.258819, 0, -0.246152, 0.91865, -0.309017, -0.079979, 0.298487, 0.951057), c = Color3.fromRGB(255, 215, 38), m = Enum.Material.Neon, st = false }, -- 9
		{ n = "Head", s = "Block", z = Vector3.new(4.703798, 3.218388, 4.357203), cf = CFrame.new(0, 10.893007, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 10
		{ n = "HeadCross", s = "Block", z = Vector3.new(4.208662, 2.97082, 3.862066), cf = CFrame.new(0, 10.893007, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(36, 120, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 11
		{ n = "FacePlate", s = "Block", z = Vector3.new(3.961093, 2.57471, 0.495137), cf = CFrame.new(-0.000038, 10.79398, -2.079565, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 246, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 12
		{ n = "EyeL", s = "Block", z = Vector3.new(1.089301, 1.188328, 0.396109), cf = CFrame.new(-0.990295, 11.190088, -2.426121, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 38), m = Enum.Material.Neon, st = false }, -- 13
		{ n = "EyeR", s = "Block", z = Vector3.new(1.089301, 1.188328, 0.396109), cf = CFrame.new(0.990219, 11.190088, -2.426159, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 38), m = Enum.Material.Neon, st = false }, -- 14
		{ n = "BlushL", s = "Block", z = Vector3.new(0.742705, 0.396109, 0.297082), cf = CFrame.new(-1.386375, 10.496899, -2.376673, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, st = false }, -- 15
		{ n = "BlushR", s = "Block", z = Vector3.new(0.742705, 0.396109, 0.297082), cf = CFrame.new(1.386375, 10.496899, -2.376635, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, st = false }, -- 16
		{ n = "Smile", s = "Block", z = Vector3.new(1.089301, 0.396109, 0.297082), cf = CFrame.new(0, 10.100788, -2.376635, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(38, 28, 38), m = Enum.Material.Plastic, st = false }, -- 17
		{ n = "CanopyHub", s = "Block", z = Vector3.new(2.723252, 1.089301, 2.723252), cf = CFrame.new(0, 12.97258, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(36, 120, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "FrondLeft", s = "Block", z = Vector3.new(6.684345, 0.693191, 3.218388), cf = CFrame.new(-4.208694, 13.566744, 0.000038, 0.951057, -0.309017, 0, 0.309017, 0.951057, 0, 0, 0, 1), c = Color3.fromRGB(92, 205, 85), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "FrondRight", s = "Block", z = Vector3.new(6.684345, 0.693191, 3.218388), cf = CFrame.new(4.208618, 13.566744, 0.000038, 0.951056, 0.309017, 0, -0.309017, 0.951056, 0, 0, 0, 1), c = Color3.fromRGB(92, 205, 85), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "FrondBack", s = "Block", z = Vector3.new(3.218388, 0.693191, 6.189208), cf = CFrame.new(-0.000076, 13.665771, 3.713562, 1, 0, 0, 0, 0.951057, -0.309017, 0, 0.309017, 0.951057), c = Color3.fromRGB(92, 205, 85), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "FrondFront", s = "Block", z = Vector3.new(3.218388, 0.693191, 5.694071), cf = CFrame.new(-0.000076, 13.566744, -3.465904, 1, 0, 0, 0, 0.951057, 0.309017, 0, -0.309017, 0.951057), c = Color3.fromRGB(92, 205, 85), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "BananaHeart", s = "Block", z = Vector3.new(1.881519, 2.871793, 1.881519), cf = CFrame.new(-0.000038, 14.854099, 0.000038, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(152, 48, 185), m = Enum.Material.Plastic, st = false }, -- 23
		{ n = "ArmL", s = "Block", z = Vector3.new(1.287355, 2.475683, 1.287355), cf = CFrame.new(-2.376656, 7.030941, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "LeafHandL", s = "Block", z = Vector3.new(2.723252, 3.069847, 0.495137), cf = CFrame.new(-3.168854, 5.446505, 0, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(92, 205, 85), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "ArmR", s = "Block", z = Vector3.new(1.287355, 2.475683, 1.287355), cf = CFrame.new(2.376656, 7.030941, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "LeafHandR", s = "Block", z = Vector3.new(2.723252, 3.069847, 0.495137), cf = CFrame.new(3.168816, 5.446505, 0, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(92, 205, 85), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "LegL", s = "Block", z = Vector3.new(1.782492, 2.376656, 1.782492), cf = CFrame.new(-1.881516, 2.475684, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "FootL", s = "Block", z = Vector3.new(2.376656, 1.089301, 3.069847), cf = CFrame.new(-1.881516, 0.54465, -0.198059, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 136, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "LegR", s = "Block", z = Vector3.new(1.782492, 2.376656, 1.782492), cf = CFrame.new(1.881516, 2.475684, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
		{ n = "FootR", s = "Block", z = Vector3.new(2.376656, 1.089301, 3.069847), cf = CFrame.new(1.881554, 0.54465, -0.198097, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 136, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 31
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, -1.089301, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Waist", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 1.48541, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.386383, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 28, c0 = CFrame.new(-1.881519, -1.386383, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 1.089301, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 30, c0 = CFrame.new(1.881519, -1.386383, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 1.089301, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 6, c0 = CFrame.new(0, -0.247569, -2.574694, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 7, c0 = CFrame.new(-0.891289, -1.089302, -2.772715, 0.965926, -0.258819, 0, 0.246152, 0.91865, -0.309017, 0.07998, 0.298488, 0.951057), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 8, c0 = CFrame.new(-0.000038, -1.188329, -2.871802, 1, 0, 0, 0, 0.927184, -0.374607, 0, 0.374607, 0.927184), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 9, c0 = CFrame.new(0.891212, -1.089302, -2.772753, 0.965926, 0.258819, 0, -0.246152, 0.91865, -0.309017, -0.079979, 0.298487, 0.951057), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 4, a = 4, b = 10, c0 = CFrame.new(0, 1.584437, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.48541, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderL", h = 4, a = 4, b = 24, c0 = CFrame.new(-2.376656, 0.396109, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 1.188328, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 4, a = 4, b = 26, c0 = CFrame.new(2.376656, 0.396109, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 1.188328, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 11, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 12, c0 = CFrame.new(-0.000038, -0.099028, -2.079565, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 13, c0 = CFrame.new(-0.990295, 0.297082, -2.426121, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 14, c0 = CFrame.new(0.990219, 0.297082, -2.426159, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 15, c0 = CFrame.new(-1.386375, -0.396109, -2.376673, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 16, c0 = CFrame.new(1.386375, -0.396109, -2.376635, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 10, a = 10, b = 17, c0 = CFrame.new(0, -0.792218, -2.376635, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CanopyJoint", h = 10, a = 10, b = 18, c0 = CFrame.new(0, 1.584437, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.495137, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 19, c0 = CFrame.new(-4.208694, 0.594164, 0.000038, 0.951057, -0.309017, 0, 0.309017, 0.951057, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 20, c0 = CFrame.new(4.208618, 0.594164, 0.000038, 0.951056, 0.309017, 0, -0.309017, 0.951056, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 21, c0 = CFrame.new(-0.000076, 0.693192, 3.713562, 1, 0, 0, 0, 0.951057, -0.309017, 0, 0.309017, 0.951057), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 22, c0 = CFrame.new(-0.000076, 0.594164, -3.465904, 1, 0, 0, 0, 0.951057, 0.309017, 0, -0.309017, 0.951057), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 18, a = 18, b = 23, c0 = CFrame.new(-0.000038, 1.881518, 0.000038, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 24, a = 24, b = 25, c0 = CFrame.new(-0.792198, -1.584436, 0, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 27, c0 = CFrame.new(0.79216, -1.584436, 0, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 29, c0 = CFrame.new(0, -1.931033, -0.198059, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 30, a = 30, b = 31, c0 = CFrame.new(0.000038, -1.931033, -0.198097, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 10, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 11, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 12, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 18, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 25, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 28, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 29, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 30, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 31, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 4.951366, v = 4.951366, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
