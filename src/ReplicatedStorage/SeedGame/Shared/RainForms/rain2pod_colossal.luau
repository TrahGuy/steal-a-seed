--!strict
--==============================================================================
-- RAIN EVENT 2 FORM: the Colossal pod (tier 7), 2026-10-05
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/Pod (Colossal)" by a read-only generator on
-- 2026-10-05. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-05-rain-event-2-originals.
--
-- ONE OF SEVEN. The owner supplied a pod for each size, already at that size,
-- and this is the Colossal one: it is replayed at exactly the size supplied and
-- NEVER multiplied by the tier ladder (SeedData species PodForms says which
-- size uses which). It shows its size; nothing about it says which creature,
-- or which rarity, is inside.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the pod's BASE: its
-- root part's x/z at the lowest drawn point), colour, material, surface,
-- attribute and joint is the supplied number. See RainForms (the parent).
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "Rain Event 2/Pod (Colossal)", Kind = "pod", Yaw = 0,
	Size = Vector3.new(16.539841, 22.5, 16.539856), Height = 22.5, PartCount = 70,
	Base = 0,
	Unit = 1, ModelScale = 1.451613,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(5.806451, 0.290323, 5.806451), cf = CFrame.new(0, 0.145161, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 56, 84), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "Pod", s = "Block", z = Vector3.new(5.516129, 1.306452, 2.284856), cf = CFrame.new(0, 0.653226, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(44, 40, 64), m = Enum.Material.Plastic }, -- 2
		{ n = "Pod", s = "Block", z = Vector3.new(5.516129, 1.306452, 2.284856), cf = CFrame.new(0, 0.653226, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(44, 40, 64), m = Enum.Material.Plastic }, -- 3
		{ n = "Pod", s = "Block", z = Vector3.new(5.516129, 1.306452, 2.284856), cf = CFrame.new(0, 0.653226, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(44, 40, 64), m = Enum.Material.Plastic }, -- 4
		{ n = "Pod", s = "Block", z = Vector3.new(5.516129, 1.306452, 2.284856), cf = CFrame.new(0, 0.653226, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(44, 40, 64), m = Enum.Material.Plastic }, -- 5
		{ n = "Pod", s = "Block", z = Vector3.new(4.5, 3.048387, 1.863961), cf = CFrame.new(0, 2.830645, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(56, 50, 80), m = Enum.Material.Plastic }, -- 6
		{ n = "Pod", s = "Block", z = Vector3.new(4.5, 3.048387, 1.863961), cf = CFrame.new(0, 2.830645, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(56, 50, 80), m = Enum.Material.Plastic }, -- 7
		{ n = "Pod", s = "Block", z = Vector3.new(4.5, 3.048387, 1.863961), cf = CFrame.new(0, 2.830645, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(56, 50, 80), m = Enum.Material.Plastic }, -- 8
		{ n = "Pod", s = "Block", z = Vector3.new(4.5, 3.048387, 1.863961), cf = CFrame.new(0, 2.830645, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(56, 50, 80), m = Enum.Material.Plastic }, -- 9
		{ n = "Pod", s = "Block", z = Vector3.new(4.209677, 2.903226, 1.743705), cf = CFrame.new(0, 5.806451, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(68, 62, 96), m = Enum.Material.Plastic }, -- 10
		{ n = "Pod", s = "Block", z = Vector3.new(4.209677, 2.903226, 1.743705), cf = CFrame.new(0, 5.806451, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(68, 62, 96), m = Enum.Material.Plastic }, -- 11
		{ n = "Pod", s = "Block", z = Vector3.new(4.209677, 2.903226, 1.743705), cf = CFrame.new(0, 5.806451, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(68, 62, 96), m = Enum.Material.Plastic }, -- 12
		{ n = "Pod", s = "Block", z = Vector3.new(4.209677, 2.903226, 1.743705), cf = CFrame.new(0, 5.806451, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(68, 62, 96), m = Enum.Material.Plastic }, -- 13
		{ n = "Pod", s = "Block", z = Vector3.new(6.677419, 1.451613, 2.765877), cf = CFrame.new(0, 7.983871, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(82, 74, 112), m = Enum.Material.Plastic }, -- 14
		{ n = "Pod", s = "Block", z = Vector3.new(6.677419, 1.451613, 2.765877), cf = CFrame.new(0, 7.983871, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(82, 74, 112), m = Enum.Material.Plastic }, -- 15
		{ n = "Pod", s = "Block", z = Vector3.new(6.677419, 1.451613, 2.765877), cf = CFrame.new(0, 7.983871, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(82, 74, 112), m = Enum.Material.Plastic }, -- 16
		{ n = "Pod", s = "Block", z = Vector3.new(6.677419, 1.451613, 2.765877), cf = CFrame.new(0, 7.983871, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(82, 74, 112), m = Enum.Material.Plastic }, -- 17
		{ n = "Pod", s = "Block", z = Vector3.new(9.870968, 1.451613, 4.088688), cf = CFrame.new(0, 9.435484, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(96, 88, 128), m = Enum.Material.Plastic }, -- 18
		{ n = "Pod", s = "Block", z = Vector3.new(9.870968, 1.451613, 4.088688), cf = CFrame.new(0, 9.435484, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(96, 88, 128), m = Enum.Material.Plastic }, -- 19
		{ n = "Pod", s = "Block", z = Vector3.new(9.870968, 1.451613, 4.088688), cf = CFrame.new(0, 9.435484, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(96, 88, 128), m = Enum.Material.Plastic }, -- 20
		{ n = "Pod", s = "Block", z = Vector3.new(9.870968, 1.451613, 4.088688), cf = CFrame.new(0, 9.435484, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(96, 88, 128), m = Enum.Material.Plastic }, -- 21
		{ n = "Pod", s = "Block", z = Vector3.new(14.225806, 2.032258, 5.892521), cf = CFrame.new(0, 11.177418, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(122, 114, 154), m = Enum.Material.Plastic }, -- 22
		{ n = "Pod", s = "Block", z = Vector3.new(14.225806, 2.032258, 5.892521), cf = CFrame.new(0, 11.177418, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(122, 114, 154), m = Enum.Material.Plastic }, -- 23
		{ n = "Pod", s = "Block", z = Vector3.new(14.225806, 2.032258, 5.892521), cf = CFrame.new(0, 11.177418, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(122, 114, 154), m = Enum.Material.Plastic }, -- 24
		{ n = "Pod", s = "Block", z = Vector3.new(14.225806, 2.032258, 5.892521), cf = CFrame.new(0, 11.177418, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(122, 114, 154), m = Enum.Material.Plastic }, -- 25
		{ n = "Pod", s = "Block", z = Vector3.new(15.967741, 2.032258, 6.614054), cf = CFrame.new(0, 13.209677, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(146, 138, 176), m = Enum.Material.Plastic }, -- 26
		{ n = "Pod", s = "Block", z = Vector3.new(15.967741, 2.032258, 6.614054), cf = CFrame.new(0, 13.209677, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(146, 138, 176), m = Enum.Material.Plastic }, -- 27
		{ n = "Pod", s = "Block", z = Vector3.new(15.967741, 2.032258, 6.614054), cf = CFrame.new(0, 13.209677, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(146, 138, 176), m = Enum.Material.Plastic }, -- 28
		{ n = "Pod", s = "Block", z = Vector3.new(15.967741, 2.032258, 6.614054), cf = CFrame.new(0, 13.209677, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(146, 138, 176), m = Enum.Material.Plastic }, -- 29
		{ n = "Pod", s = "Block", z = Vector3.new(13.064515, 1.741935, 5.4115), cf = CFrame.new(0, 15.096773, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(172, 164, 200), m = Enum.Material.Plastic }, -- 30
		{ n = "Pod", s = "Block", z = Vector3.new(13.064515, 1.741935, 5.4115), cf = CFrame.new(0, 15.096773, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(172, 164, 200), m = Enum.Material.Plastic }, -- 31
		{ n = "Pod", s = "Block", z = Vector3.new(13.064515, 1.741935, 5.4115), cf = CFrame.new(0, 15.096773, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(172, 164, 200), m = Enum.Material.Plastic }, -- 32
		{ n = "Pod", s = "Block", z = Vector3.new(13.064515, 1.741935, 5.4115), cf = CFrame.new(0, 15.096773, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(172, 164, 200), m = Enum.Material.Plastic }, -- 33
		{ n = "Pod", s = "Block", z = Vector3.new(8.709677, 1.306452, 3.607666), cf = CFrame.new(0, 16.620968, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(198, 192, 222), m = Enum.Material.Plastic }, -- 34
		{ n = "Pod", s = "Block", z = Vector3.new(8.709677, 1.306452, 3.607666), cf = CFrame.new(0, 16.620968, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(198, 192, 222), m = Enum.Material.Plastic }, -- 35
		{ n = "Pod", s = "Block", z = Vector3.new(8.709677, 1.306452, 3.607666), cf = CFrame.new(0, 16.620968, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(198, 192, 222), m = Enum.Material.Plastic }, -- 36
		{ n = "Pod", s = "Block", z = Vector3.new(8.709677, 1.306452, 3.607666), cf = CFrame.new(0, 16.620968, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(198, 192, 222), m = Enum.Material.Plastic }, -- 37
		{ n = "Pod", s = "Block", z = Vector3.new(4.645161, 0.870968, 1.924088), cf = CFrame.new(0, 17.709677, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(224, 220, 238), m = Enum.Material.Plastic }, -- 38
		{ n = "Pod", s = "Block", z = Vector3.new(4.645161, 0.870968, 1.924088), cf = CFrame.new(0, 17.709677, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(224, 220, 238), m = Enum.Material.Plastic }, -- 39
		{ n = "Pod", s = "Block", z = Vector3.new(4.645161, 0.870968, 1.924088), cf = CFrame.new(0, 17.709677, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(224, 220, 238), m = Enum.Material.Plastic }, -- 40
		{ n = "Pod", s = "Block", z = Vector3.new(4.645161, 0.870968, 1.924088), cf = CFrame.new(0, 17.709677, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(224, 220, 238), m = Enum.Material.Plastic }, -- 41
		{ n = "Mammatus", s = "Block", z = Vector3.new(3.483871, 1.596774, 3.483871), cf = CFrame.new(0, 9.435484, -5.806458, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(112, 104, 144), m = Enum.Material.Plastic }, -- 42
		{ n = "Mammatus", s = "Block", z = Vector3.new(3.483871, 1.596774, 3.483871), cf = CFrame.new(5.806452, 9.435484, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(112, 104, 144), m = Enum.Material.Plastic }, -- 43
		{ n = "Mammatus", s = "Block", z = Vector3.new(3.483871, 1.596774, 3.483871), cf = CFrame.new(0, 9.435484, 5.806458, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(112, 104, 144), m = Enum.Material.Plastic }, -- 44
		{ n = "Mammatus", s = "Block", z = Vector3.new(3.483871, 1.596774, 3.483871), cf = CFrame.new(-5.806452, 9.435484, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(112, 104, 144), m = Enum.Material.Plastic }, -- 45
		{ n = "Crack", s = "Block", z = Vector3.new(0.609677, 1.355721, 0.203226), cf = CFrame.new(0, 15.495968, -6.619354, 0.675725, -0.737154, 0, -0.737154, -0.675725, 0, 0, 0, -1), c = Color3.fromRGB(255, 214, 70), m = Enum.Material.Neon, st = false, cs = false }, -- 46
		{ n = "Crack", s = "Block", z = Vector3.new(0.609677, 1.303283, 0.203226), cf = CFrame.new(-0.036291, 14.69758, -6.619354, 0.707107, 0.707107, 0, 0.707107, -0.707107, 0, 0, 0, -1), c = Color3.fromRGB(255, 214, 70), m = Enum.Material.Neon, st = false, cs = false }, -- 47
		{ n = "Crack", s = "Block", z = Vector3.new(0.609677, 1.508573, 0.203226), cf = CFrame.new(0.036291, 13.681452, -8.070953, 0.707107, -0.707107, 0, -0.707107, -0.707107, 0, 0, 0, -1), c = Color3.fromRGB(255, 214, 70), m = Enum.Material.Neon, st = false, cs = false }, -- 48
		{ n = "Crack", s = "Block", z = Vector3.new(0.609677, 1.458276, 0.203226), cf = CFrame.new(0, 12.737902, -8.070953, 0.734803, 0.67828, 0, 0.67828, -0.734803, 0, 0, 0, -1), c = Color3.fromRGB(255, 214, 70), m = Enum.Material.Neon, st = false, cs = false }, -- 49
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.51018, 0.63871), cf = CFrame.new(5.695997, 9.254032, -2.618103, 0.430146, 0.254901, 0.866025, 0.509802, -0.860292, 0, 0.745034, 0.441502, -0.5), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 50
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.9089, 0.63871), cf = CFrame.new(5.478254, 7.403225, -2.995239, 0.325396, -0.379628, 0.866026, -0.759257, -0.650791, 0, 0.563602, -0.657536, -0.5), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 51
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 3.113627, 0.63871), cf = CFrame.new(5.441965, 5.443548, -3.058105, 0.377845, 0.327465, 0.866025, 0.654931, -0.755689, 0, 0.654446, 0.567187, -0.5), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 52
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.9089, 0.63871), cf = CFrame.new(5.478254, 3.338709, -2.995239, 0.379628, -0.325396, 0.866026, -0.650791, -0.759257, 0, 0.657536, -0.563601, -0.5), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 53
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.401145, 0.63871), cf = CFrame.new(5.296803, 1.364516, -3.30954, 0.441731, 0.234251, 0.866026, 0.468503, -0.883462, 0, 0.765101, 0.405735, -0.5), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 54
		{ n = "StrikeSplash", s = "Block", z = Vector3.new(2.758064, 0.087097, 2.758064), cf = CFrame.new(5.550836, 0.058064, -2.869537, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 55
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.51018, 0.63871), cf = CFrame.new(0.580645, 9.254032, 6.241943, -0.860292, 0.509802, 0, -0.509802, -0.860292, 0, 0, 0, 1), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 56
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.9089, 0.63871), cf = CFrame.new(0.145161, 7.403225, 6.241943, -0.650791, -0.759257, 0, 0.759257, -0.650791, 0, 0, 0, 1), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 57
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 3.113627, 0.63871), cf = CFrame.new(0.07258, 5.443548, 6.241943, -0.755689, 0.654931, 0, -0.654931, -0.755689, 0, 0, 0, 1), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 58
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.9089, 0.63871), cf = CFrame.new(0.145161, 3.338709, 6.241943, -0.759257, -0.650791, 0, 0.650791, -0.759257, 0, 0, 0, 1), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 59
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.401145, 0.63871), cf = CFrame.new(-0.217741, 1.364516, 6.241943, -0.883462, 0.468503, 0, -0.468503, -0.883462, 0, 0, 0, 1), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 60
		{ n = "StrikeSplash", s = "Block", z = Vector3.new(2.758064, 0.087097, 2.758064), cf = CFrame.new(0.290323, 0.058064, 6.241943, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 61
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.51018, 0.63871), cf = CFrame.new(-5.115351, 9.254032, -3.62381, 0.430146, 0.254901, -0.866025, 0.509802, -0.860292, 0, -0.745034, -0.441502, -0.5), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 62
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.9089, 0.63871), cf = CFrame.new(-5.333094, 7.403225, -3.246674, 0.325396, -0.379628, -0.866026, -0.759257, -0.650791, 0, -0.563602, 0.657536, -0.5), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 63
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 3.113627, 0.63871), cf = CFrame.new(-5.369383, 5.443548, -3.183838, 0.377845, 0.327465, -0.866025, 0.654931, -0.755689, 0, -0.654446, -0.567187, -0.5), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 64
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.9089, 0.63871), cf = CFrame.new(-5.333094, 3.338709, -3.246674, 0.379628, -0.325396, -0.866026, -0.650791, -0.759257, 0, -0.657536, 0.563601, -0.5), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 65
		{ n = "LightningBolt", s = "Block", z = Vector3.new(0.63871, 2.401145, 0.63871), cf = CFrame.new(-5.514545, 1.364516, -2.932404, 0.441731, 0.234251, -0.866026, 0.468503, -0.883462, 0, -0.765101, -0.405735, -0.5), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 66
		{ n = "StrikeSplash", s = "Block", z = Vector3.new(2.758064, 0.087097, 2.758064), cf = CFrame.new(-5.260513, 0.058064, -3.372406, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 67
		{ n = "LightningRod", s = "Block", z = Vector3.new(1.016129, 3.193548, 1.016129), cf = CFrame.new(0, 19.669355, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 240, 110), m = Enum.Material.Neon, st = false, cs = false }, -- 68
		{ n = "LightningRodTip", s = "Block", z = Vector3.new(0.580645, 1.306452, 0.580645), cf = CFrame.new(0, 21.846775, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(255, 252, 215), m = Enum.Material.Neon, st = false, cs = false }, -- 69
		{ n = "RainPlate", s = "Block", z = Vector3.new(10.741935, 0.145161, 10.741935), cf = CFrame.new(0, 10.088709, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(122, 114, 154), m = Enum.Material.SmoothPlastic, t = 1, st = false, cs = false }, -- 70
	},
	Joints = {
		{ k = "Motor6D", n = "Pod", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.508065, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 3, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 5, c0 = CFrame.new(0, 0, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 6, c0 = CFrame.new(0, 2.177419, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 7, c0 = CFrame.new(0, 2.177419, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 8, c0 = CFrame.new(0, 2.177419, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 9, c0 = CFrame.new(0, 2.177419, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 10, c0 = CFrame.new(0, 5.153225, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 11, c0 = CFrame.new(0, 5.153225, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 12, c0 = CFrame.new(0, 5.153225, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 13, c0 = CFrame.new(0, 5.153225, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 14, c0 = CFrame.new(0, 7.330645, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 15, c0 = CFrame.new(0, 7.330645, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 16, c0 = CFrame.new(0, 7.330645, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 17, c0 = CFrame.new(0, 7.330645, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 18, c0 = CFrame.new(0, 8.782258, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 19, c0 = CFrame.new(0, 8.782258, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 20, c0 = CFrame.new(0, 8.782258, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 21, c0 = CFrame.new(0, 8.782258, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 22, c0 = CFrame.new(0, 10.524193, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 23, c0 = CFrame.new(0, 10.524193, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 24, c0 = CFrame.new(0, 10.524193, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 25, c0 = CFrame.new(0, 10.524193, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 26, c0 = CFrame.new(0, 12.556451, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 27, c0 = CFrame.new(0, 12.556451, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 28, c0 = CFrame.new(0, 12.556451, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 29, c0 = CFrame.new(0, 12.556451, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 30, c0 = CFrame.new(0, 14.443547, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 31, c0 = CFrame.new(0, 14.443547, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 32, c0 = CFrame.new(0, 14.443547, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 33, c0 = CFrame.new(0, 14.443547, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 34, c0 = CFrame.new(0, 15.967741, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 35, c0 = CFrame.new(0, 15.967741, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 36, c0 = CFrame.new(0, 15.967741, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 37, c0 = CFrame.new(0, 15.967741, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 38, c0 = CFrame.new(0, 17.05645, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 39, c0 = CFrame.new(0, 17.05645, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 40, c0 = CFrame.new(0, 17.05645, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 41, c0 = CFrame.new(0, 17.05645, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Lobe0", h = 2, a = 2, b = 42, c0 = CFrame.new(0, 9.508064, -5.806451, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.725806, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107) },
		{ k = "Motor6D", n = "Lobe1", h = 2, a = 2, b = 43, c0 = CFrame.new(5.806451, 9.508064, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.725806, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107) },
		{ k = "Motor6D", n = "Lobe2", h = 2, a = 2, b = 44, c0 = CFrame.new(0, 9.508064, 5.806451, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.725806, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107) },
		{ k = "Motor6D", n = "Lobe3", h = 2, a = 2, b = 45, c0 = CFrame.new(-5.806451, 9.508064, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.725806, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 46, c0 = CFrame.new(0, 14.842742, -6.619354, 0.675725, -0.737154, 0, -0.737154, -0.675725, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 47, c0 = CFrame.new(-0.03629, 14.044354, -6.619354, 0.707107, 0.707107, 0, 0.707107, -0.707107, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 48, c0 = CFrame.new(0.03629, 13.028226, -8.070968, 0.707107, -0.707107, 0, -0.707107, -0.707107, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 49, c0 = CFrame.new(0, 12.084677, -8.070968, 0.734803, 0.67828, 0, 0.67828, -0.734803, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 50, c0 = CFrame.new(5.695997, 8.600806, -2.618114, 0.430146, 0.254901, 0.866025, 0.509802, -0.860292, 0, 0.745034, 0.441502, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 51, c0 = CFrame.new(5.478255, 6.75, -2.995254, 0.325396, -0.379628, 0.866026, -0.759257, -0.650791, 0, 0.563602, -0.657536, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 52, c0 = CFrame.new(5.441965, 4.790322, -3.058111, 0.377845, 0.327465, 0.866025, 0.654931, -0.755689, 0, 0.654446, 0.567187, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 53, c0 = CFrame.new(5.478255, 2.685484, -2.995254, 0.379628, -0.325396, 0.866026, -0.650791, -0.759257, 0, 0.657536, -0.563601, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 54, c0 = CFrame.new(5.296803, 0.71129, -3.309538, 0.441731, 0.234251, 0.866026, 0.468503, -0.883462, 0, 0.765101, 0.405735, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 55, c0 = CFrame.new(5.550836, -0.595161, -2.869541, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 56, c0 = CFrame.new(0.580645, 8.600806, 6.241935, -0.860292, 0.509802, 0, -0.509802, -0.860292, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 57, c0 = CFrame.new(0.145161, 6.75, 6.241935, -0.650791, -0.759257, 0, 0.759257, -0.650791, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 58, c0 = CFrame.new(0.072581, 4.790322, 6.241935, -0.755689, 0.654931, 0, -0.654931, -0.755689, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 59, c0 = CFrame.new(0.145161, 2.685484, 6.241935, -0.759257, -0.650791, 0, 0.650791, -0.759257, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 60, c0 = CFrame.new(-0.217742, 0.71129, 6.241935, -0.883462, 0.468503, 0, -0.468503, -0.883462, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 61, c0 = CFrame.new(0.290323, -0.595161, 6.241935, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 62, c0 = CFrame.new(-5.115352, 8.600806, -3.623821, 0.430146, 0.254901, -0.866025, 0.509802, -0.860292, 0, -0.745034, -0.441502, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 63, c0 = CFrame.new(-5.333093, 6.75, -3.246682, 0.325396, -0.379628, -0.866026, -0.759257, -0.650791, 0, -0.563602, 0.657536, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 64, c0 = CFrame.new(-5.369384, 4.790322, -3.183824, 0.377845, 0.327465, -0.866025, 0.654931, -0.755689, 0, -0.654446, -0.567187, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 65, c0 = CFrame.new(-5.333093, 2.685484, -3.246682, 0.379628, -0.325396, -0.866026, -0.650791, -0.759257, 0, -0.657536, 0.563601, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 66, c0 = CFrame.new(-5.514545, 0.71129, -2.932397, 0.441731, 0.234251, -0.866026, 0.468503, -0.883462, 0, -0.765101, -0.405735, -0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 67, c0 = CFrame.new(-5.260513, -0.595161, -3.372394, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Rod", h = 2, a = 2, b = 68, c0 = CFrame.new(0, 17.419353, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.596774, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 70, c0 = CFrame.new(0, 9.435483, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 68, a = 68, b = 69, c0 = CFrame.new(0, 2.177419, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StrikeGlow", p = 68, range = 26, brightness = 1, color = Color3.new(1, 0.95, 0.6), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Crackle", p = 68, rate = 18, enabled = true, lifetime = NumberRange.new(0.2, 0.45), speed = NumberRange.new(11.612903, 23.225805), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.551613, 0), NumberSequenceKeypoint.new(1, 0, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(1, 1, 0.85)), ColorSequenceKeypoint.new(1, Color3.new(1, 0.85, 0.25)) }), lightEmission = 1, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(180, 180), acceleration = Vector3.new(0, 0, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
		{ n = "Rain", p = 70, rate = 55, enabled = true, lifetime = NumberRange.new(0.45, 0.55), speed = NumberRange.new(7.258064, 11.612903), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.290323, 0), NumberSequenceKeypoint.new(1, 0.145161, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2, 0), NumberSequenceKeypoint.new(1, 0.9, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.78, 0.9, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.45, 0.7, 1)) }), lightEmission = 0.5, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(6, 6), acceleration = Vector3.new(0, -58.064514, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Bottom, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
