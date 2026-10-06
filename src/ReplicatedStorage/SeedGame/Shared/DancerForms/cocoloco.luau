--!strict
--==============================================================================
-- DANCER FORM: Cocoloco (a Ticket Disco / Disco Only dancer)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "disco Dancers/Cocoloco" by a read-only generator on 2026-10-03. The
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
	Source = "disco Dancers/Cocoloco", Kind = "dancer", Yaw = 0,
	Size = Vector3.new(7.122292, 7.094264, 4.700458), Height = 7.094264, PartCount = 30,
	Base = 1,
	ModelScale = 2.281111,
	Attributes = { AutoDance = true, DanceBPM = 124, DanceEnergy = 1, ProceduralDance = true, RateScale = 1, Unit = "CoconutDancer" },
	Parts = {
		{ n = "Pelvis", s = "Block", z = Vector3.new(2.395166, 1.6424, 2.167055), cf = CFrame.new(0, 2.281109, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 82, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "PelvisCross", s = "Block", z = Vector3.new(2.167055, 1.551155, 2.007377), cf = CFrame.new(0, 2.281109, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(86, 60, 42), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "TrunkRing1", s = "Block", z = Vector3.new(2.623277, 0.319355, 2.395166), cf = CFrame.new(0, 1.824885, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "Torso", s = "Block", z = Vector3.new(2.098622, 1.482722, 1.938944), cf = CFrame.new(0, 3.604153, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 82, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "TorsoCross", s = "Block", z = Vector3.new(1.870511, 1.368666, 1.710833), cf = CFrame.new(0, 3.604153, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(86, 60, 42), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "TrunkRing2", s = "Block", z = Vector3.new(2.326733, 0.319355, 2.098622), cf = CFrame.new(0, 3.718207, 0.000017, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(152, 52, 196), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "Head", s = "Block", z = Vector3.new(2.007377, 1.414289, 1.870511), cf = CFrame.new(0, 5.018442, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 82, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "FacePlate", s = "Block", z = Vector3.new(1.733644, 1.186177, 0.228111), cf = CFrame.new(-0.000015, 4.972823, -0.912465, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 246, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "EyeL", s = "Block", z = Vector3.new(0.501844, 0.547467, 0.182489), cf = CFrame.new(-0.433418, 5.155312, -1.072133, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 9
		{ n = "EyeR", s = "Block", z = Vector3.new(0.501844, 0.547467, 0.182489), cf = CFrame.new(0.433395, 5.155307, -1.072133, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 10
		{ n = "BlushL", s = "Block", z = Vector3.new(0.319355, 0.182489, 0.136867), cf = CFrame.new(-0.593094, 4.835953, -1.049317, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, st = false }, -- 11
		{ n = "BlushR", s = "Block", z = Vector3.new(0.319355, 0.182489, 0.136867), cf = CFrame.new(0.593079, 4.835953, -1.049326, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, st = false }, -- 12
		{ n = "Smile", s = "Block", z = Vector3.new(0.501844, 0.182489, 0.136867), cf = CFrame.new(-0.000015, 4.653464, -1.049326, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 28, 38), m = Enum.Material.Plastic, st = false }, -- 13
		{ n = "CanopyHub", s = "Block", z = Vector3.new(1.254611, 0.501844, 1.254611), cf = CFrame.new(0, 5.976508, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(86, 60, 42), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "Coconut1", s = "Block", z = Vector3.new(0.866822, 0.866822, 0.866822), cf = CFrame.new(-0.570274, 5.634347, -0.57026, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(105, 68, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "Coconut2", s = "Block", z = Vector3.new(0.866822, 0.866822, 0.866822), cf = CFrame.new(0.570274, 5.634347, -0.57026, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(105, 68, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "Coconut3", s = "Block", z = Vector3.new(0.798389, 0.798389, 0.798389), cf = CFrame.new(-0.000015, 5.702778, 0.638725, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(105, 68, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "FrondL", s = "Block", z = Vector3.new(3.30761, 0.319355, 1.254611), cf = CFrame.new(-1.938942, 6.295871, 0.000009, 0.951056, -0.309017, 0, 0.309017, 0.951057, 0, 0, 0, 1), c = Color3.fromRGB(48, 168, 72), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "FrondR", s = "Block", z = Vector3.new(3.30761, 0.319355, 1.254611), cf = CFrame.new(1.938942, 6.295871, 0.000017, 0.951057, 0.309017, 0, -0.309017, 0.951057, 0, 0, 0, 1), c = Color3.fromRGB(48, 168, 72), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "FrondB", s = "Block", z = Vector3.new(1.254611, 0.319355, 3.079499), cf = CFrame.new(0, 6.318687, 1.710841, 1, 0, 0, 0, 0.951056, -0.309017, 0, 0.309017, 0.951056), c = Color3.fromRGB(48, 168, 72), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "Hibiscus", s = "Block", z = Vector3.new(0.958066, 0.501844, 0.958066), cf = CFrame.new(0.45623, 6.615225, -0.456206, 0.965926, -0.258819, 0, 0.25, 0.933013, 0.258819, -0.066987, -0.25, 0.965926), c = Color3.fromRGB(246, 62, 138), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "Stamen", s = "Block", z = Vector3.new(0.4106, 0.501844, 0.4106), cf = CFrame.new(0.45623, 6.843342, -0.456215, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 22
		{ n = "ArmL", s = "Block", z = Vector3.new(0.593089, 1.140555, 0.593089), cf = CFrame.new(-1.049309, 3.239176, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 82, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "PalmHandL", s = "Block", z = Vector3.new(1.254611, 1.414289, 0.228111), cf = CFrame.new(-1.414276, 2.509221, -0.000009, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(85, 205, 95), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "ArmR", s = "Block", z = Vector3.new(0.593089, 1.140555, 0.593089), cf = CFrame.new(1.049309, 3.239176, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 82, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "PalmHandR", s = "Block", z = Vector3.new(1.254611, 1.414289, 0.228111), cf = CFrame.new(1.414276, 2.509225, -0.000009, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c = Color3.fromRGB(85, 205, 95), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "LegL", s = "Block", z = Vector3.new(0.798389, 1.094933, 0.798389), cf = CFrame.new(-0.821198, 1.140554, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 82, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "FootL", s = "Block", z = Vector3.new(1.049311, 0.501844, 1.368666), cf = CFrame.new(-0.821198, 0.250922, -0.091229, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 138, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "LegR", s = "Block", z = Vector3.new(0.798389, 1.094933, 0.798389), cf = CFrame.new(0.821198, 1.140554, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 82, 58), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
		{ n = "FootR", s = "Block", z = Vector3.new(1.049311, 0.501844, 1.368666), cf = CFrame.new(0.821182, 0.250922, -0.091229, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 138, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 30
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, -0.456224, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Waist", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 0.684333, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.638711, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 27, c0 = CFrame.new(-0.8212, -0.638711, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.501844, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 29, c0 = CFrame.new(0.8212, -0.638711, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.501844, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 6, c0 = CFrame.new(0, 0.114054, 0.000017, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 4, a = 4, b = 7, c0 = CFrame.new(0, 0.729955, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.684333, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderL", h = 4, a = 4, b = 23, c0 = CFrame.new(-1.049311, 0.182489, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.547467, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 4, a = 4, b = 25, c0 = CFrame.new(1.049311, 0.182489, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.547467, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 8, c0 = CFrame.new(-0.000015, -0.045619, -0.912465, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 9, c0 = CFrame.new(-0.433418, 0.13687, -1.072133, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 10, c0 = CFrame.new(0.433395, 0.136865, -1.072133, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 11, c0 = CFrame.new(-0.593094, -0.182489, -1.049317, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 12, c0 = CFrame.new(0.593079, -0.182489, -1.049326, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 7, a = 7, b = 13, c0 = CFrame.new(-0.000015, -0.364977, -1.049326, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CanopyJoint", h = 7, a = 7, b = 14, c0 = CFrame.new(0, 0.729955, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.228111, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 15, c0 = CFrame.new(-0.570274, -0.342161, -0.57026, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 16, c0 = CFrame.new(0.570274, -0.342161, -0.57026, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 17, c0 = CFrame.new(-0.000015, -0.273731, 0.638725, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 18, c0 = CFrame.new(-1.938942, 0.319363, 0.000009, 0.951056, -0.309017, 0, 0.309017, 0.951057, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 19, c0 = CFrame.new(1.938942, 0.319363, 0.000017, 0.951057, 0.309017, 0, -0.309017, 0.951057, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 20, c0 = CFrame.new(0, 0.342179, 1.710841, 1, 0, 0, 0, 0.951056, -0.309017, 0, 0.309017, 0.951056), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 21, c0 = CFrame.new(0.45623, 0.638717, -0.456206, 0.965926, -0.258819, 0, 0.25, 0.933013, 0.258819, -0.066987, -0.25, 0.965926), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 22, c0 = CFrame.new(0.45623, 0.866833, -0.456215, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 24, c0 = CFrame.new(-0.364967, -0.729955, -0.000009, 0.927184, 0.374607, 0, -0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 25, a = 25, b = 26, c0 = CFrame.new(0.364967, -0.72995, -0.000009, 0.927184, -0.374607, 0, 0.374607, 0.927184, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 28, c0 = CFrame.new(0, -0.889632, -0.091229, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 29, a = 29, b = 30, c0 = CFrame.new(-0.000015, -0.889632, -0.091229, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 8, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 14, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 17, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 18, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 23, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 25, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 28, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 29, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 30, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.281111, v = 2.281111, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
