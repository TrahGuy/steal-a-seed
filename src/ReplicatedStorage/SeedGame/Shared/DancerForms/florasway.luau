--!strict
--==============================================================================
-- DANCER FORM: Florasway (a Ticket Disco / Disco Only dancer)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "disco Dancers/Florasway" by a read-only generator on 2026-10-03. The
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
	Source = "disco Dancers/Florasway", Kind = "dancer", Yaw = 0,
	Size = Vector3.new(4.401306, 7.967451, 2.314621), Height = 7.967451, PartCount = 29,
	Base = 1,
	ModelScale = 2.008204,
	Attributes = { AutoDance = true, DanceBPM = 120, DanceEnergy = 1, ProceduralDance = true, RateScale = 1, Unit = "FlowerDancer" },
	Parts = {
		{ n = "Pelvis", s = "Block", z = Vector3.new(1.907794, 1.104512, 1.706974), cf = CFrame.new(0, 2.309435, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 155, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "PelvisCross", s = "Block", z = Vector3.new(1.706974, 1.004102, 1.566399), cf = CFrame.new(0, 2.309435, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(38, 108, 48), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "LeafSkirt", s = "Block", z = Vector3.new(2.309435, 0.321313, 2.108614), cf = CFrame.new(0, 1.86763, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(98, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "LowerStem", s = "Block", z = Vector3.new(1.104512, 1.305333, 1.104512), cf = CFrame.new(0, 3.514357, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 155, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "StemSproutL", s = "Block", z = Vector3.new(0.843446, 0.361477, 0.240984), cf = CFrame.new(-0.70285, 3.614767, -0.000008, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(98, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "UpperStem", s = "Block", z = Vector3.new(1.004102, 1.305333, 1.004102), cf = CFrame.new(0, 4.799608, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 155, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "StemSproutR", s = "Block", z = Vector3.new(0.843446, 0.361477, 0.240984), cf = CFrame.new(0.702881, 4.699198, 0, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c = Color3.fromRGB(98, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "HeadCore", s = "Block", z = Vector3.new(1.807384, 1.606563, 1.566399), cf = CFrame.new(0, 6.265597, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 92, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "FacePlate", s = "Block", z = Vector3.new(1.566399, 1.365579, 0.20082), cf = CFrame.new(0.000015, 5.924202, -0.763119, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 244, 226), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 9
		{ n = "EyeL", s = "Block", z = Vector3.new(0.441805, 0.481969, 0.160656), cf = CFrame.new(-0.401634, 6.044694, -0.923771, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 10
		{ n = "EyeR", s = "Block", z = Vector3.new(0.441805, 0.481969, 0.160656), cf = CFrame.new(0.401634, 6.044694, -0.923779, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 215, 45), m = Enum.Material.Neon, st = false }, -- 11
		{ n = "BlushL", s = "Block", z = Vector3.new(0.281149, 0.160656, 0.120492), cf = CFrame.new(-0.562294, 5.763546, -0.903702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 138, 150), m = Enum.Material.Plastic, st = false }, -- 12
		{ n = "BlushR", s = "Block", z = Vector3.new(0.281149, 0.160656, 0.120492), cf = CFrame.new(0.562294, 5.763546, -0.903694, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 138, 150), m = Enum.Material.Plastic, st = false }, -- 13
		{ n = "Smile", s = "Block", z = Vector3.new(0.361477, 0.120492, 0.120492), cf = CFrame.new(0, 5.602889, -0.903694, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(42, 52, 36), m = Enum.Material.Plastic, st = false }, -- 14
		{ n = "PetalCollar", s = "Block", z = Vector3.new(1.405743, 0.401641, 1.004102), cf = CFrame.new(0, 6.265597, -0.200821, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(246, 92, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "PetalTop", s = "Block", z = Vector3.new(1.104512, 1.445907, 0.301231), cf = CFrame.new(0, 7.229535, -0.301239, 1, 0, 0, 0, 0.970296, 0.241922, 0, -0.241922, 0.970296), c = Color3.fromRGB(255, 188, 32), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "PetalBtm", s = "Block", z = Vector3.new(1.104512, 1.305333, 0.301231), cf = CFrame.new(0, 4.679116, -0.301239, 1, 0, 0, 0, 0.970296, -0.241922, 0, 0.241922, 0.970296), c = Color3.fromRGB(255, 188, 32), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 17
		{ n = "PetalL", s = "Block", z = Vector3.new(1.445907, 1.104512, 0.301231), cf = CFrame.new(-1.365578, 5.924202, -0.301239, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c = Color3.fromRGB(255, 188, 32), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 18
		{ n = "PetalR", s = "Block", z = Vector3.new(1.445907, 1.104512, 0.301231), cf = CFrame.new(1.365562, 5.924202, -0.301247, 0.970296, 0.241922, 0, -0.241922, 0.970296, 0, 0, 0, 1), c = Color3.fromRGB(255, 188, 32), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 19
		{ n = "PetalTL", s = "Block", z = Vector3.new(1.044266, 1.245087, 0.281149), cf = CFrame.new(-1.044273, 6.968468, -0.361488, 0.707107, -0.707107, 0, 0.700225, 0.700225, 0.139173, -0.09841, -0.09841, 0.990268), c = Color3.fromRGB(246, 92, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 20
		{ n = "PetalTR", s = "Block", z = Vector3.new(1.044266, 1.245087, 0.281149), cf = CFrame.new(1.044273, 6.968468, -0.361473, 0.707107, 0.707107, 0, -0.700225, 0.700225, 0.139173, 0.09841, -0.09841, 0.990268), c = Color3.fromRGB(246, 92, 54), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "ArmL", s = "Block", z = Vector3.new(0.522133, 1.104512, 0.522133), cf = CFrame.new(-0.903694, 4.518459, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 155, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "LeafHandL", s = "Block", z = Vector3.new(1.245087, 1.305333, 0.20082), cf = CFrame.new(-1.265175, 3.815591, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(98, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "ArmR", s = "Block", z = Vector3.new(0.522133, 1.104512, 0.522133), cf = CFrame.new(0.903694, 4.518459, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 155, 68), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "LeafHandR", s = "Block", z = Vector3.new(1.245087, 1.305333, 0.20082), cf = CFrame.new(1.265175, 3.815591, 0, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(98, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "LegL", s = "Block", z = Vector3.new(0.642625, 1.104512, 0.642625), cf = CFrame.new(-0.722954, 1.144676, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(72, 56, 46), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "FootL", s = "Block", z = Vector3.new(0.88361, 0.441805, 1.164758), cf = CFrame.new(-0.722954, 0.220902, -0.080322, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(98, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "LegR", s = "Block", z = Vector3.new(0.642625, 1.104512, 0.642625), cf = CFrame.new(0.722954, 1.144676, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(72, 56, 46), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
		{ n = "FootR", s = "Block", z = Vector3.new(0.88361, 0.441805, 1.164758), cf = CFrame.new(0.722969, 0.220902, -0.080322, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(98, 195, 78), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 29
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 3, c0 = CFrame.new(0, -0.441805, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Waist", h = 1, a = 1, b = 4, c0 = CFrame.new(0, 0.562297, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.642625, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 26, c0 = CFrame.new(-0.722954, -0.602461, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.562297, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 28, c0 = CFrame.new(0.722954, -0.602461, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.562297, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 4, a = 4, b = 5, c0 = CFrame.new(-0.70285, 0.10041, -0.000008, 0.882948, -0.469472, 0, 0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Chest", h = 4, a = 4, b = 6, c0 = CFrame.new(0, 0.642625, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.642625, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 7, c0 = CFrame.new(0.702881, -0.10041, 0, 0.882948, 0.469472, 0, -0.469472, 0.882948, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 6, a = 6, b = 8, c0 = CFrame.new(0, 0.702871, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.763118, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderL", h = 6, a = 6, b = 22, c0 = CFrame.new(-0.903692, 0.240984, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.522133, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 6, a = 6, b = 24, c0 = CFrame.new(0.903692, 0.240984, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.522133, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 9, c0 = CFrame.new(0.000015, -0.341395, -0.763119, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 10, c0 = CFrame.new(-0.401634, -0.220903, -0.923771, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 11, c0 = CFrame.new(0.401634, -0.220903, -0.923779, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 12, c0 = CFrame.new(-0.562294, -0.502051, -0.903702, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 13, c0 = CFrame.new(0.562294, -0.502051, -0.903694, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 8, a = 8, b = 14, c0 = CFrame.new(0, -0.662708, -0.903694, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "PetalJoint", h = 8, a = 8, b = 15, c0 = CFrame.new(0, 0, -0.20082, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 16, c0 = CFrame.new(0, 0.963938, -0.100418, 1, 0, 0, 0, 0.970296, 0.241922, 0, -0.241922, 0.970296), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 17, c0 = CFrame.new(0, -1.586481, -0.100418, 1, 0, 0, 0, 0.970296, -0.241922, 0, 0.241922, 0.970296), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 18, c0 = CFrame.new(-1.365578, -0.341395, -0.100418, 0.970296, -0.241922, 0, 0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 19, c0 = CFrame.new(1.365562, -0.341395, -0.100426, 0.970296, 0.241922, 0, -0.241922, 0.970296, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 20, c0 = CFrame.new(-1.044273, 0.702871, -0.160667, 0.707107, -0.707107, 0, 0.700225, 0.700225, 0.139173, -0.09841, -0.09841, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 21, c0 = CFrame.new(1.044273, 0.702871, -0.160652, 0.707107, 0.707107, 0, -0.700225, 0.700225, 0.139173, 0.09841, -0.09841, 0.990268), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 22, a = 22, b = 23, c0 = CFrame.new(-0.361481, -0.702868, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 24, a = 24, b = 25, c0 = CFrame.new(0.361481, -0.702868, 0, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 26, a = 26, b = 27, c0 = CFrame.new(0, -0.923774, -0.080322, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 28, a = 28, b = 29, c0 = CFrame.new(0.000015, -0.923774, -0.080322, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 8, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 9, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 17, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 18, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 19, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 20, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 23, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 25, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 28, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 29, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.008204, v = 2.008204, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
