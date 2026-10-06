--!strict
--==============================================================================
-- DANCER FORM: Shroomhop (a Ticket Disco / Disco Only dancer)
--
-- Lifted part for part, joint for joint, from the owner's Workspace model
-- "disco Dancers/Shroomhop" by a read-only generator on 2026-10-03. The
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
	Source = "disco Dancers/Shroomhop", Kind = "dancer", Yaw = 0,
	Size = Vector3.new(5.945831, 7.460002, 5.945827), Height = 7.460002, PartCount = 28,
	Base = 1,
	ModelScale = 2.156069,
	Attributes = { AutoDance = true, DanceBPM = 128, DanceEnergy = 1, ProceduralDance = true, RateScale = 1, Unit = "MushroomDancer" },
	Parts = {
		{ n = "Pelvis", s = "Block", z = Vector3.new(2.371676, 1.401445, 2.048265), cf = CFrame.new(0, 2.263875, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 242, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 1
		{ n = "PelvisCross", s = "Block", z = Vector3.new(2.156069, 1.293641, 1.897341), cf = CFrame.new(0, 2.263875, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(224, 216, 202), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 2
		{ n = "Torso", s = "Block", z = Vector3.new(1.940462, 1.185838, 1.767976), cf = CFrame.new(0, 3.514395, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 242, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 3
		{ n = "TorsoCross", s = "Block", z = Vector3.new(1.767976, 1.078034, 1.595491), cf = CFrame.new(0, 3.514395, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(224, 216, 202), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 4
		{ n = "StalkCollar", s = "Block", z = Vector3.new(2.587283, 0.388092, 2.371676), cf = CFrame.new(0, 3.040065, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 205, 135), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 5
		{ n = "Head", s = "Block", z = Vector3.new(2.048265, 1.25052, 1.832659), cf = CFrame.new(0, 4.851157, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 242, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 6
		{ n = "HeadCross", s = "Block", z = Vector3.new(1.897341, 1.164277, 1.681734), cf = CFrame.new(0, 4.851157, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(224, 216, 202), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 7
		{ n = "FacePlate", s = "Block", z = Vector3.new(1.767976, 1.121156, 0.215607), cf = CFrame.new(0, 4.808035, -0.862415, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(252, 248, 240), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 8
		{ n = "EyeL", s = "Block", z = Vector3.new(0.517456, 0.560578, 0.172486), cf = CFrame.new(-0.474335, 4.980516, -1.034904, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(70, 235, 255), m = Enum.Material.Neon, st = false }, -- 9
		{ n = "EyeR", s = "Block", z = Vector3.new(0.517456, 0.560578, 0.172486), cf = CFrame.new(0.474319, 4.980516, -1.03492, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(70, 235, 255), m = Enum.Material.Neon, st = false }, -- 10
		{ n = "BlushL", s = "Block", z = Vector3.new(0.344971, 0.215607, 0.129364), cf = CFrame.new(-0.689926, 4.678668, -1.013355, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 142), m = Enum.Material.Plastic, st = false }, -- 11
		{ n = "BlushR", s = "Block", z = Vector3.new(0.344971, 0.215607, 0.129364), cf = CFrame.new(0.689957, 4.678668, -1.013355, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 128, 142), m = Enum.Material.Plastic, st = false }, -- 12
		{ n = "Smile", s = "Block", z = Vector3.new(0.388092, 0.172486, 0.129364), cf = CFrame.new(0, 4.506186, -1.013355, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(48, 40, 46), m = Enum.Material.Plastic, st = false }, -- 13
		{ n = "CapGills", s = "Block", z = Vector3.new(5.282369, 0.539017, 4.958958), cf = CFrame.new(0, 5.799828, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(242, 235, 218), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 14
		{ n = "CapDome", s = "Block", z = Vector3.new(4.635548, 1.401445, 4.419941), cf = CFrame.new(0, 6.554457, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(230, 48, 110), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 15
		{ n = "CapCross", s = "Block", z = Vector3.new(4.312138, 1.293641, 4.09653), cf = CFrame.new(0, 6.554457, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(188, 32, 88), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 16
		{ n = "SpotTop", s = "Block", z = Vector3.new(1.401445, 0.30185, 1.401445), cf = CFrame.new(0, 7.309078, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 205, 45), m = Enum.Material.Plastic, st = false }, -- 17
		{ n = "SpotL", s = "Block", z = Vector3.new(0.991792, 0.258728, 0.991792), cf = CFrame.new(-1.509254, 6.985664, 0.323414, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(255, 205, 45), m = Enum.Material.Plastic, st = false }, -- 18
		{ n = "SpotR", s = "Block", z = Vector3.new(0.991792, 0.258728, 0.991792), cf = CFrame.new(1.509239, 6.985664, 0.323414, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.fromRGB(255, 205, 45), m = Enum.Material.Plastic, st = false }, -- 19
		{ n = "SpotF", s = "Block", z = Vector3.new(0.905549, 0.258728, 0.905549), cf = CFrame.new(0, 6.985664, -1.509241, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c = Color3.fromRGB(255, 205, 45), m = Enum.Material.Plastic, st = false }, -- 20
		{ n = "ArmL", s = "Block", z = Vector3.new(0.603699, 0.905549, 0.603699), cf = CFrame.new(-1.034912, 3.255666, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 242, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 21
		{ n = "HandL", s = "Block", z = Vector3.new(0.776185, 0.646821, 0.603699), cf = CFrame.new(-1.034912, 2.738231, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 205, 135), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 22
		{ n = "ArmR", s = "Block", z = Vector3.new(0.603699, 0.905549, 0.603699), cf = CFrame.new(1.034912, 3.255666, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 242, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 23
		{ n = "HandR", s = "Block", z = Vector3.new(0.776185, 0.646821, 0.603699), cf = CFrame.new(1.034912, 2.738231, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(115, 205, 135), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 24
		{ n = "LegL", s = "Block", z = Vector3.new(0.776185, 1.078034, 0.776185), cf = CFrame.new(-0.819305, 1.078037, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 242, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 25
		{ n = "FootL", s = "Block", z = Vector3.new(1.034913, 0.517456, 1.25052), cf = CFrame.new(-0.819305, 0.258728, -0.107794, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(120, 195, 125), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 26
		{ n = "LegR", s = "Block", z = Vector3.new(0.776185, 1.078034, 0.776185), cf = CFrame.new(0.819305, 1.078037, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(248, 242, 230), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 27
		{ n = "FootR", s = "Block", z = Vector3.new(1.034913, 0.517456, 1.25052), cf = CFrame.new(0.819305, 0.258728, -0.107811, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(120, 195, 125), m = Enum.Material.Plastic, sf = { "Studs", "Inlet", "Studs", "Studs", "Studs", "Studs" } }, -- 28
	},
	Joints = {
		{ k = "Weld", n = "WeldConstraint", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Waist", h = 1, a = 1, b = 3, c0 = CFrame.new(0, 0.646821, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.603699, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipL", h = 1, a = 1, b = 25, c0 = CFrame.new(-0.819306, -0.646821, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.539017, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "HipR", h = 1, a = 1, b = 27, c0 = CFrame.new(0.819306, -0.646821, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.539017, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 4, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 3, a = 3, b = 5, c0 = CFrame.new(0, -0.474329, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Neck", h = 3, a = 3, b = 6, c0 = CFrame.new(0, 0.689942, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.646821, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderL", h = 3, a = 3, b = 21, c0 = CFrame.new(-1.034913, 0.172486, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.431214, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ShoulderR", h = 3, a = 3, b = 23, c0 = CFrame.new(1.034913, 0.172486, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.431214, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 7, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 8, c0 = CFrame.new(0, -0.043122, -0.862415, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 9, c0 = CFrame.new(-0.474335, 0.129359, -1.034904, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 10, c0 = CFrame.new(0.474319, 0.129359, -1.03492, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 11, c0 = CFrame.new(-0.689926, -0.17249, -1.013355, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 12, c0 = CFrame.new(0.689957, -0.17249, -1.013355, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 6, a = 6, b = 13, c0 = CFrame.new(0, -0.344971, -1.013355, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "CapJoint", h = 6, a = 6, b = 14, c0 = CFrame.new(0, 0.689942, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.258728, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 14, a = 14, b = 15, c0 = CFrame.new(0, 0.754629, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 16, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 17, c0 = CFrame.new(0, 0.754621, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 18, c0 = CFrame.new(-1.509254, 0.431207, 0.323414, 0.906308, -0.422618, 0, 0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 19, c0 = CFrame.new(1.509239, 0.431207, 0.323414, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 15, a = 15, b = 20, c0 = CFrame.new(0, 0.431207, -1.509241, 1, 0, 0, 0, 0.906308, 0.422618, 0, -0.422618, 0.906308), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 21, a = 21, b = 22, c0 = CFrame.new(0, -0.517436, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 23, a = 23, b = 24, c0 = CFrame.new(0, -0.517436, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 25, a = 25, b = 26, c0 = CFrame.new(0, -0.819308, -0.107794, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "WeldConstraint", h = 27, a = 27, b = 28, c0 = CFrame.new(0, -0.819308, -0.107811, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
		{ n = "Studs_Top", p = 1, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 2, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 3, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 4, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 5, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 6, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 7, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 8, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 14, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 15, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 16, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 21, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 22, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 23, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 24, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 25, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 26, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 27, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
		{ n = "Studs_Top", p = 28, face = Enum.NormalId.Top, texture = "rbxasset://textures/studs.png", u = 2.156069, v = 2.156069, ou = 0, ov = 0, color = Color3.new(1, 1, 1), t = 0.15, z = 1 },
	},
}

return spec
