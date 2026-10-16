--!strict
--==============================================================================
-- BIOME SECRET FORM: Cinderdrake's pod (Emberroot's secret pod), 2026-10-16
--
-- Lifted part for part, joint for joint, light, emitter and attribute
-- from the owner's ServerStorage model "Emberroot Secret/Emberroot Secret Pod" by a read-only generator on
-- 2026-10-16. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-16-biome-secrets-originals. It carried
-- plain parts and one attachment, no script.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the form's BASE:
-- the pod's pivot or root's x/z at the lowest drawn point, facing the way it faces),
-- colour, material, surface, attribute and joint is the supplied number, at the
-- size it was supplied (the owner: full size everywhere). Owner holds the
-- model's own attributes and Pivot its pivot in this frame, for the ported
-- script. Joints point at parts by INDEX, because names repeat. See
-- BiomeSecretForms (the parent).
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "Emberroot Secret/Emberroot Secret Pod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(21.12854, 31.612194, 18.386719), Height = 31.612194, PartCount = 78,
	Base = 0,
	Unit = 1, ModelScale = 4.032167,
	Attributes = {},
	Pivot = CFrame.new(0, 0.000005, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	Parts = {
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(1.935425, 9.032055, 8.870789, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 1
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(-0.806427, 12.257792, 7.74173, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 2
		{ n = "Tier", s = "Block", z = Vector3.new(15.806097, 3.225734, 15.806097), cf = CFrame.new(0, 8.386915, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 3
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(2.903168, 5.16118, 7.903046, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 4
		{ n = "Column", s = "Block", z = Vector3.new(2.096727, 3.225734, 1.290293), cf = CFrame.new(3.225739, 5.16118, -7.58046, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 5
		{ n = "ShoulderFlame", s = "Block", z = Vector3.new(1.45158, 1.93544, 1.45158), cf = CFrame.new(9.193329, 14.677099, 1.612915, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 6
		{ n = "ShoulderFlame", s = "Block", z = Vector3.new(1.93544, 2.258014, 2.258014), cf = CFrame.new(9.51593, 14.83839, -0.967697, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 7
		{ n = "ShoulderFlame", s = "Block", z = Vector3.new(0.96772, 1.612867, 0.96772), cf = CFrame.new(9.999756, 19.031824, -0.967697, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 8
		{ n = "ShoulderFlame", s = "Block", z = Vector3.new(1.45158, 2.258014, 1.612867), cf = CFrame.new(9.83847, 17.096388, -0.967697, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 9
		{ n = "HornStud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(-5.322479, 21.612423, -1.209641, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 10
		{ n = "ShoulderFlame", s = "Block", z = Vector3.new(0.96772, 1.290293, 0.96772), cf = CFrame.new(9.354645, 16.289957, 1.612915, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 11
		{ n = "Shoulder", s = "Block", z = Vector3.new(2.580587, 3.225734, 7.096614), cf = CFrame.new(9.273987, 7.903046, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 12
		{ n = "Column", s = "Block", z = Vector3.new(1.93544, 7.096614, 1.290293), cf = CFrame.new(3.225739, 10.322353, -8.548218, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 13
		{ n = "Tier", s = "Block", z = Vector3.new(7.096614, 1.612867, 7.096614), cf = CFrame.new(0, 17.902838, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 14
		{ n = "Column", s = "Block", z = Vector3.new(2.096727, 3.225734, 1.290293), cf = CFrame.new(-3.225739, 5.16118, 7.580505, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 15
		{ n = "ShoulderFlame", s = "Block", z = Vector3.new(0.96772, 1.290293, 0.96772), cf = CFrame.new(-9.354645, 16.289957, 1.612915, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 16
		{ n = "ShoulderFlame", s = "Block", z = Vector3.new(1.45158, 1.93544, 1.45158), cf = CFrame.new(-9.193329, 14.677099, 1.612915, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 17
		{ n = "Shoulder", s = "Block", z = Vector3.new(2.580587, 4.193453, 6.451468), cf = CFrame.new(9.032043, 11.612654, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 18
		{ n = "Horn", s = "Block", z = Vector3.new(2.096727, 3.87088, 1.93544), cf = CFrame.new(5.96759, 24.838137, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 19
		{ n = "Tier", s = "Block", z = Vector3.new(12.902936, 2.258014, 12.902936), cf = CFrame.new(0, 14.03194, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 20
		{ n = "Tier", s = "Block", z = Vector3.new(10.322348, 1.93544, 10.322348), cf = CFrame.new(0, 16.128666, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 21
		{ n = "Plate", s = "Block", z = Vector3.new(0.806433, 2.580587, 2.903161), cf = CFrame.new(-7.983673, 11.773943, 4.838608, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(44, 30, 32), m = Enum.Material.Plastic }, -- 22
		{ n = "Plate", s = "Block", z = Vector3.new(4.838601, 3.548307, 0.806433), cf = CFrame.new(2.903168, 5.806318, 7.338562, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(44, 30, 32), m = Enum.Material.Plastic }, -- 23
		{ n = "Tier", s = "Block", z = Vector3.new(13.870654, 3.225734, 13.870654), cf = CFrame.new(0, 5.16118, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 24
		{ n = "ShoulderFlame", s = "Block", z = Vector3.new(1.93544, 2.258014, 2.258014), cf = CFrame.new(-9.51593, 14.83839, -0.967697, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 25
		{ n = "HornFlame", s = "Block", z = Vector3.new(0.96772, 3.225734, 1.774153), cf = CFrame.new(-7.499847, 24.354288, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 26
		{ n = "Horn", s = "Block", z = Vector3.new(1.774153, 3.225734, 1.612867), cf = CFrame.new(-5.322479, 28.225163, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(44, 30, 32), m = Enum.Material.Plastic }, -- 27
		{ n = "ShoulderFlame", s = "Block", z = Vector3.new(0.96772, 1.612867, 0.96772), cf = CFrame.new(-9.999756, 19.031824, -0.967697, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 28
		{ n = "ShoulderFlame", s = "Block", z = Vector3.new(1.45158, 2.258014, 1.612867), cf = CFrame.new(-9.83847, 17.096388, -0.967697, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 29
		{ n = "Horn", s = "Block", z = Vector3.new(2.096727, 3.87088, 1.93544), cf = CFrame.new(-5.96759, 24.838137, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 30
		{ n = "Shoulder", s = "Block", z = Vector3.new(2.580587, 3.225734, 7.096614), cf = CFrame.new(-9.273987, 7.903046, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 31
		{ n = "HornStud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(-5.96759, 25.160717, -1.128967, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 32
		{ n = "Shoulder", s = "Block", z = Vector3.new(2.580587, 4.193453, 6.451468), cf = CFrame.new(-9.032043, 11.612654, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 33
		{ n = "ColumnFlame", s = "Block", z = Vector3.new(1.612867, 3.225734, 1.129007), cf = CFrame.new(3.225739, 15.48353, -8.548218, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 34
		{ n = "HornFlame", s = "Block", z = Vector3.new(0.806433, 1.290293, 1.290293), cf = CFrame.new(-7.903076, 26.612307, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 35
		{ n = "Plate", s = "Block", z = Vector3.new(4.838601, 3.548307, 0.806433), cf = CFrame.new(-2.903168, 5.806318, -7.338531, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(44, 30, 32), m = Enum.Material.Plastic }, -- 36
		{ n = "Plate", s = "Block", z = Vector3.new(0.806433, 2.580587, 2.903161), cf = CFrame.new(7.983673, 11.773943, -4.838577, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(44, 30, 32), m = Enum.Material.Plastic }, -- 37
		{ n = "Tier", s = "Block", z = Vector3.new(10.644922, 1.93544, 10.644922), cf = CFrame.new(0, 2.580581, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 38
		{ n = "Plate", s = "Block", z = Vector3.new(5.483747, 3.87088, 0.806433), cf = CFrame.new(-3.225739, 9.677216, -8.306229, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 39
		{ n = "Tier", s = "Block", z = Vector3.new(7.096614, 1.612867, 7.096614), cf = CFrame.new(0, 0.806433, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 40
		{ n = "Plate", s = "Block", z = Vector3.new(5.483747, 3.87088, 0.806433), cf = CFrame.new(3.225739, 9.677216, 8.306305, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 41
		{ n = "Tier", s = "Block", z = Vector3.new(15.160951, 2.903161, 15.160951), cf = CFrame.new(0, 11.451365, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 42
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(0.806427, 12.257792, -7.741745, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 43
		{ n = "Horn", s = "Block", z = Vector3.new(2.258014, 3.548307, 2.096727), cf = CFrame.new(5.322479, 21.289845, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 44
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(-1.935425, 9.032055, -8.870773, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 45
		{ n = "HornTip", s = "Block", z = Vector3.new(1.129007, 1.93544, 1.129007), cf = CFrame.new(-4.516022, 30.644472, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 46
		{ n = "HornStud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(5.322479, 21.612423, -1.209641, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 47
		{ n = "LowFlame", s = "Block", z = Vector3.new(0.806433, 1.129007, 0.806433), cf = CFrame.new(7.096619, 4.274106, -7.096588, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 48
		{ n = "Horn", s = "Block", z = Vector3.new(1.774153, 3.225734, 1.612867), cf = CFrame.new(5.322479, 28.225163, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(44, 30, 32), m = Enum.Material.Plastic }, -- 49
		{ n = "LowFlame", s = "Block", z = Vector3.new(1.290293, 1.93544, 1.290293), cf = CFrame.new(-7.096619, 5.806318, -7.096588, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 50
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(-4.516022, 12.257792, -7.741745, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 51
		{ n = "LowFlame", s = "Block", z = Vector3.new(0.806433, 1.129007, 0.806433), cf = CFrame.new(-7.096619, 4.274106, -7.096588, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 52
		{ n = "LowFlame", s = "Block", z = Vector3.new(0.806433, 1.129007, 0.806433), cf = CFrame.new(-7.096619, 4.274106, 7.096649, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 53
		{ n = "LowFlame", s = "Block", z = Vector3.new(0.806433, 1.129007, 0.806433), cf = CFrame.new(7.096619, 4.274106, 7.096649, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 54
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(-1.612885, 12.257792, -7.741745, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 55
		{ n = "LowFlame", s = "Block", z = Vector3.new(1.290293, 1.93544, 1.290293), cf = CFrame.new(7.096619, 5.806318, -7.096588, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 56
		{ n = "HornFlame", s = "Block", z = Vector3.new(0.96772, 3.548307, 1.93544), cf = CFrame.new(6.935333, 21.128551, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 57
		{ n = "Horn", s = "Block", z = Vector3.new(2.258014, 3.548307, 2.096727), cf = CFrame.new(-5.322479, 21.289845, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 58
		{ n = "Horn", s = "Block", z = Vector3.new(2.258014, 2.580587, 2.258014), cf = CFrame.new(-4.193451, 18.386684, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 59
		{ n = "HornFlame", s = "Block", z = Vector3.new(0.96772, 3.548307, 1.93544), cf = CFrame.new(-6.935333, 21.128551, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 60
		{ n = "Column", s = "Block", z = Vector3.new(1.93544, 7.096614, 1.290293), cf = CFrame.new(-3.225739, 10.322353, 8.548218, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 61
		{ n = "ColumnFlame", s = "Block", z = Vector3.new(1.612867, 3.225734, 1.129007), cf = CFrame.new(-3.225739, 15.48353, 8.548218, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 62
		{ n = "Horn", s = "Block", z = Vector3.new(2.258014, 2.580587, 2.258014), cf = CFrame.new(4.193451, 18.386684, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 63
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(1.612885, 12.257792, 7.74173, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 64
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(-4.516022, 9.032055, -8.870773, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 65
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(4.516022, 12.257792, 7.74173, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 66
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(4.516022, 9.032055, 8.870789, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(100, 28, 32), m = Enum.Material.Plastic }, -- 67
		{ n = "ColumnFlame", s = "Block", z = Vector3.new(0.96772, 1.290293, 0.806433), cf = CFrame.new(-3.225739, 17.741547, 8.548218, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 68
		{ n = "LowFlame", s = "Block", z = Vector3.new(1.290293, 1.93544, 1.290293), cf = CFrame.new(-7.096619, 5.806318, 7.096649, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 69
		{ n = "LowFlame", s = "Block", z = Vector3.new(1.290293, 1.93544, 1.290293), cf = CFrame.new(7.096619, 5.806318, 7.096649, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 70
		{ n = "HornTip", s = "Block", z = Vector3.new(1.129007, 1.93544, 1.129007), cf = CFrame.new(4.516022, 30.644472, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 71
		{ n = "HornFlame", s = "Block", z = Vector3.new(0.96772, 2.258014, 1.93544), cf = CFrame.new(-5.806305, 18.547976, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 72
		{ n = "HornFlame", s = "Block", z = Vector3.new(0.96772, 2.258014, 1.93544), cf = CFrame.new(5.806305, 18.547976, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 64, 64), m = Enum.Material.Neon, st = false, cs = false }, -- 73
		{ n = "Stud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(-2.903168, 5.16118, -7.903061, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(32, 22, 24), m = Enum.Material.Plastic }, -- 74
		{ n = "HornStud", s = "Block", z = Vector3.new(0.806433, 0.806433, 0.322573), cf = CFrame.new(5.96759, 25.160717, -1.128967, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(118, 36, 40), m = Enum.Material.Plastic }, -- 75
		{ n = "HornFlame", s = "Block", z = Vector3.new(0.96772, 3.225734, 1.774153), cf = CFrame.new(7.499847, 24.354288, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 76
		{ n = "HornFlame", s = "Block", z = Vector3.new(0.806433, 1.290293, 1.290293), cf = CFrame.new(7.903046, 26.612307, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 77
		{ n = "ColumnFlame", s = "Block", z = Vector3.new(0.96772, 1.290293, 0.806433), cf = CFrame.new(3.225739, 17.741547, -8.548218, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(255, 124, 104), m = Enum.Material.Neon, st = false, cs = false }, -- 78
	},
	Joints = {
	},
	Attachments = {
		{ n = "HornGlowAt", p = 14, cf = CFrame.new(0, 5.645034, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Lights = {
		{ n = "PointLight", p = 0, range = 7, brightness = 0.8, color = Color3.new(1, 0.25098, 0.25098), shadows = false, enabled = true },
	},
	Emitters = {
	},
	Textures = {
	},
	Beams = {
	},
}

return spec
