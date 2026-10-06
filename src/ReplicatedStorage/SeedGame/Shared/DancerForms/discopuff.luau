--!strict
--==============================================================================
-- DANCER FORM: Discopuff (a Ticket Disco / Disco Only dancer)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "disco Dancers/Discopuff" by a read-only generator on 2026-10-03. The
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
	Source = "disco Dancers/Discopuff", Kind = "dancer", Yaw = 0,
	Size = Vector3.new(3.519385, 5.545, 3.36235), Height = 5.545, PartCount = 28,
	Base = 1,
	ModelScale = 1.564175,
	Attributes = { AutoDance = true, DanceBPM = 124, DanceEnergy = 1, ProceduralDance = true, RateScale = 1, Unit = "DiscoDancer" },
	Parts = {
		{ n = "Pelvis", s = "Block", z = Vector3.new(1.720592, 1.016713, 1.485966), cf = CFrame.new(0, 1.564175, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(54, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "PelvisCross", s = "Block", z = Vector3.new(1.564175, 0.938505, 1.376474), cf = CFrame.new(0, 1.564175, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(36, 118, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "DiscoBelt", s = "Block", z = Vector3.new(1.845726, 0.250268, 1.595458), cf = CFrame.new(0, 1.220056, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 3
		{ n = "Torso", s = "Block", z = Vector3.new(1.376474, 0.938505, 1.220056), cf = CFrame.new(0, 2.471396, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(54, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "Lapels", s = "Block", z = Vector3.new(1.642383, 0.656953, 0.250268), cf = CFrame.new(-0.000006, 2.59653, -0.656937, 1, 0, 0, 0, 0.970296, 0.241922, 0, -0.241922, 0.970296), c = Color3.fromRGB(246, 58, 136), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "Head", s = "Block", z = Vector3.new(1.485966, 0.969788, 1.376474), cf = CFrame.new(0, 3.441185, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(54, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "FacePlate", s = "Block", z = Vector3.new(1.25134, 0.813371, 0.156417), cf = CFrame.new(-0.000006, 3.409901, -0.656937, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 246, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "ShadesFrame", s = "Block", z = Vector3.new(1.188773, 0.375402, 0.125134), cf = CFrame.new(-0.000006, 3.535035, -0.750809, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 34, 58), m = Enum.Material.Plastic, st = false }, -- 8
		{ n = "LensL", s = "Block", z = Vector3.new(0.391044, 0.281551, 0.09385), cf = CFrame.new(-0.312836, 3.535035, -0.829002, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 9
		{ n = "LensR", s = "Block", z = Vector3.new(0.391044, 0.281551, 0.09385), cf = CFrame.new(0.312836, 3.535035, -0.82901, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 10
		{ n = "BlushL", s = "Block", z = Vector3.new(0.218984, 0.09385, 0.09385), cf = CFrame.new(-0.437967, 3.300409, -0.735153, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 58, 136), m = Enum.Material.Plastic, st = false }, -- 11
		{ n = "BlushR", s = "Block", z = Vector3.new(0.218984, 0.09385, 0.09385), cf = CFrame.new(0.43797, 3.300409, -0.735153, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 58, 136), m = Enum.Material.Plastic, st = false }, -- 12
		{ n = "Smile", s = "Block", z = Vector3.new(0.344118, 0.09385, 0.09385), cf = CFrame.new(0.062569, 3.190917, -0.735161, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 28, 40), m = Enum.Material.Plastic, st = false }, -- 13
		{ n = "AfroBase", s = "Block", z = Vector3.new(2.580888, 1.798801, 2.580888), cf = CFrame.new(0, 4.254555, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(156, 52, 198), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "AfroCross", s = "Block", z = Vector3.new(2.377545, 1.689309, 2.377545), cf = CFrame.new(0, 4.254555, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(246, 58, 136), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "PuffTop", s = "Block", z = Vector3.new(1.329548, 0.547461, 1.329548), cf = CFrame.new(0, 5.271269, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Plastic, st = false }, -- 16
		{ n = "PuffL", s = "Block", z = Vector3.new(0.860296, 0.860296, 0.860296), cf = CFrame.new(-1.329546, 4.410973, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 58, 136), m = Enum.Material.Plastic, st = false }, -- 17
		{ n = "PuffR", s = "Block", z = Vector3.new(0.860296, 0.860296, 0.860296), cf = CFrame.new(1.329543, 4.410973, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 58, 136), m = Enum.Material.Plastic, st = false }, -- 18
		{ n = "ArmL", s = "Block", z = Vector3.new(0.406685, 0.813371, 0.406685), cf = CFrame.new(-0.719521, 2.205486, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(54, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "PointHandL", s = "Block", z = Vector3.new(0.500536, 0.813371, 0.312835), cf = CFrame.new(-0.875941, 1.704953, -0.000015, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 58, 136), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "ArmR", s = "Block", z = Vector3.new(0.406685, 0.813371, 0.406685), cf = CFrame.new(0.71952, 2.205486, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(54, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "PointHandR", s = "Block", z = Vector3.new(0.500536, 0.813371, 0.312835), cf = CFrame.new(0.875938, 1.704953, 0.000015, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 58, 136), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "LegL", s = "Block", z = Vector3.new(0.531819, 0.750804, 0.531819), cf = CFrame.new(-0.594386, 0.782088, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(54, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "BellBottomL", s = "Block", z = Vector3.new(1.016713, 0.437969, 1.016713), cf = CFrame.new(-0.594386, 0.547461, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(54, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "FootL", s = "Block", z = Vector3.new(0.750804, 0.344118, 0.938505), cf = CFrame.new(-0.594386, 0.172059, -0.062569, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(45, 138, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "LegR", s = "Block", z = Vector3.new(0.531819, 0.750804, 0.531819), cf = CFrame.new(0.594386, 0.782088, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(54, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "BellBottomR", s = "Block", z = Vector3.new(1.016713, 0.437969, 1.016713), cf = CFrame.new(0.594386, 0.547461, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(54, 168, 76), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "FootR", s = "Block", z = Vector3.new(0.750804, 0.344118, 0.938505), cf = CFrame.new(0.594386, 0.172059, -0.062553, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(45, 138, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, -0.344118, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Waist", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 0.469252, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.437969, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 23, c0 = CFrame.new(-0.594386, -0.437969, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.344118, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 26, c0 = CFrame.new(0.594386, -0.437969, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.344118, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(-0.000006, 0.125134, -0.656937, 1, 0, 0, 0, 0.970296, 0.241922, 0, -0.241922, 0.970296), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 4, a = 4, b = 6, c0 = CFrame.new(0, 0.500536, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.469252, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderL", h = 4, a = 4, b = 19, c0 = CFrame.new(-0.71952, 0.125134, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.391044, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 4, a = 4, b = 21, c0 = CFrame.new(0.71952, 0.125134, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.391044, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 7, c0 = CFrame.new(-0.000006, -0.031283, -0.656937, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 8, c0 = CFrame.new(-0.000006, 0.09385, -0.750809, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 9, c0 = CFrame.new(-0.312836, 0.09385, -0.829002, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 10, c0 = CFrame.new(0.312836, 0.09385, -0.82901, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 11, c0 = CFrame.new(-0.437967, -0.140776, -0.735153, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 12, c0 = CFrame.new(0.43797, -0.140776, -0.735153, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 13, c0 = CFrame.new(0.062569, -0.250268, -0.735161, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "AfroJoint", h = 6, a = 6, b = 14, c0 = CFrame.new(0, 0.500536, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.312835, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 15, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 16, c0 = CFrame.new(0, 1.016714, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 17, c0 = CFrame.new(-1.329546, 0.156417, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 18, c0 = CFrame.new(1.329543, 0.156417, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 19, a = 19, b = 20, c0 = CFrame.new(-0.156421, -0.500534, -0.000015, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 21, a = 21, b = 22, c0 = CFrame.new(0.156418, -0.500534, 0.000015, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 24, c0 = CFrame.new(0, -0.234626, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 25, c0 = CFrame.new(0, -0.610028, -0.062569, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 27, c0 = CFrame.new(0, -0.234626, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 28, c0 = CFrame.new(0, -0.610028, -0.062553, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 14, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 23, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 25, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 28, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 1.564175, v = 1.564175, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
