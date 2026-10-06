--!strict
--==============================================================================
-- RAIN EVENT 2 FORM: the Titan pod (tier 6), 2026-10-05
--
-- Lifted part for part, joint for joint, light and emitter, from the owner's
-- supplied Workspace model "Rain Event 2/Pod (Titan)" by a read-only generator on
-- 2026-10-05. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-05-rain-event-2-originals.
--
-- ONE OF SEVEN. The owner supplied a pod for each size, already at that size,
-- and this is the Titan one: it is replayed at exactly the size supplied and
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
	Source = "Rain Event 2/Pod (Titan)", Kind = "pod", Yaw = 0,
	Size = Vector3.new(14.346905, 19.300003, 14.491974), Height = 19.300003, PartCount = 62,
	Base = 0,
	Unit = 1, ModelScale = 1.707965,
	Attributes = {},
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(8.539824, 0.341593, 8.539824), cf = CFrame.new(0, 0.170796, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(60, 80, 70), m = Enum.Material.Plastic, t = 1, st = false, cs = false }, -- 1
		{ n = "Pod", s = "Block", z = Vector3.new(7.515045, 1.537168, 3.112834), cf = CFrame.new(0, 0.768584, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(40, 92, 62), m = Enum.Material.Plastic }, -- 2
		{ n = "Pod", s = "Block", z = Vector3.new(7.515045, 1.537168, 3.112834), cf = CFrame.new(0, 0.768584, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(40, 92, 62), m = Enum.Material.Plastic }, -- 3
		{ n = "Pod", s = "Block", z = Vector3.new(7.515045, 1.537168, 3.112834), cf = CFrame.new(0, 0.768584, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(40, 92, 62), m = Enum.Material.Plastic }, -- 4
		{ n = "Pod", s = "Block", z = Vector3.new(7.515045, 1.537168, 3.112834), cf = CFrame.new(0, 0.768584, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(40, 92, 62), m = Enum.Material.Plastic }, -- 5
		{ n = "Pod", s = "Block", z = Vector3.new(10.247788, 1.878761, 4.244772), cf = CFrame.new(0, 2.476549, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(52, 112, 72), m = Enum.Material.Plastic }, -- 6
		{ n = "Pod", s = "Block", z = Vector3.new(10.247788, 1.878761, 4.244772), cf = CFrame.new(0, 2.476549, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(52, 112, 72), m = Enum.Material.Plastic }, -- 7
		{ n = "Pod", s = "Block", z = Vector3.new(10.247788, 1.878761, 4.244772), cf = CFrame.new(0, 2.476549, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(52, 112, 72), m = Enum.Material.Plastic }, -- 8
		{ n = "Pod", s = "Block", z = Vector3.new(10.247788, 1.878761, 4.244772), cf = CFrame.new(0, 2.476549, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(52, 112, 72), m = Enum.Material.Plastic }, -- 9
		{ n = "Pod", s = "Block", z = Vector3.new(12.297346, 2.049558, 5.093728), cf = CFrame.new(0, 4.440708, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 134, 80), m = Enum.Material.Plastic }, -- 10
		{ n = "Pod", s = "Block", z = Vector3.new(12.297346, 2.049558, 5.093728), cf = CFrame.new(0, 4.440708, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(66, 134, 80), m = Enum.Material.Plastic }, -- 11
		{ n = "Pod", s = "Block", z = Vector3.new(12.297346, 2.049558, 5.093728), cf = CFrame.new(0, 4.440708, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(66, 134, 80), m = Enum.Material.Plastic }, -- 12
		{ n = "Pod", s = "Block", z = Vector3.new(12.297346, 2.049558, 5.093728), cf = CFrame.new(0, 4.440708, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(66, 134, 80), m = Enum.Material.Plastic }, -- 13
		{ n = "Pod", s = "Block", z = Vector3.new(13.663718, 3.757523, 5.659697), cf = CFrame.new(0, 7.344248, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(66, 56, 128), m = Enum.Material.Plastic }, -- 14
		{ n = "Pod", s = "Block", z = Vector3.new(13.663718, 3.757523, 5.659697), cf = CFrame.new(0, 7.344248, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(66, 56, 128), m = Enum.Material.Plastic }, -- 15
		{ n = "Pod", s = "Block", z = Vector3.new(13.663718, 3.757523, 5.659697), cf = CFrame.new(0, 7.344248, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(66, 56, 128), m = Enum.Material.Plastic }, -- 16
		{ n = "Pod", s = "Block", z = Vector3.new(13.663718, 3.757523, 5.659697), cf = CFrame.new(0, 7.344248, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(66, 56, 128), m = Enum.Material.Plastic }, -- 17
		{ n = "Pod", s = "Block", z = Vector3.new(11.614161, 2.049558, 4.810742), cf = CFrame.new(0, 10.247789, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(82, 72, 152), m = Enum.Material.Plastic }, -- 18
		{ n = "Pod", s = "Block", z = Vector3.new(11.614161, 2.049558, 4.810742), cf = CFrame.new(0, 10.247789, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(82, 72, 152), m = Enum.Material.Plastic }, -- 19
		{ n = "Pod", s = "Block", z = Vector3.new(11.614161, 2.049558, 4.810742), cf = CFrame.new(0, 10.247789, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(82, 72, 152), m = Enum.Material.Plastic }, -- 20
		{ n = "Pod", s = "Block", z = Vector3.new(11.614161, 2.049558, 4.810742), cf = CFrame.new(0, 10.247789, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(82, 72, 152), m = Enum.Material.Plastic }, -- 21
		{ n = "Pod", s = "Block", z = Vector3.new(8.881416, 1.707965, 3.678804), cf = CFrame.new(0, 12.12655, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(104, 92, 176), m = Enum.Material.Plastic }, -- 22
		{ n = "Pod", s = "Block", z = Vector3.new(8.881416, 1.707965, 3.678804), cf = CFrame.new(0, 12.12655, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(104, 92, 176), m = Enum.Material.Plastic }, -- 23
		{ n = "Pod", s = "Block", z = Vector3.new(8.881416, 1.707965, 3.678804), cf = CFrame.new(0, 12.12655, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(104, 92, 176), m = Enum.Material.Plastic }, -- 24
		{ n = "Pod", s = "Block", z = Vector3.new(8.881416, 1.707965, 3.678804), cf = CFrame.new(0, 12.12655, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(104, 92, 176), m = Enum.Material.Plastic }, -- 25
		{ n = "Pod", s = "Block", z = Vector3.new(6.148673, 1.195575, 2.546864), cf = CFrame.new(0, 13.578321, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(124, 110, 198), m = Enum.Material.Plastic }, -- 26
		{ n = "Pod", s = "Block", z = Vector3.new(6.148673, 1.195575, 2.546864), cf = CFrame.new(0, 13.578321, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(124, 110, 198), m = Enum.Material.Plastic }, -- 27
		{ n = "Pod", s = "Block", z = Vector3.new(6.148673, 1.195575, 2.546864), cf = CFrame.new(0, 13.578321, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(124, 110, 198), m = Enum.Material.Plastic }, -- 28
		{ n = "Pod", s = "Block", z = Vector3.new(6.148673, 1.195575, 2.546864), cf = CFrame.new(0, 13.578321, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(124, 110, 198), m = Enum.Material.Plastic }, -- 29
		{ n = "Pod", s = "Block", z = Vector3.new(7.173452, 0.426991, 2.971341), cf = CFrame.new(0, 14.389603, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 30
		{ n = "Pod", s = "Block", z = Vector3.new(7.173452, 0.426991, 2.971341), cf = CFrame.new(0, 14.389603, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 31
		{ n = "Pod", s = "Block", z = Vector3.new(7.173452, 0.426991, 2.971341), cf = CFrame.new(0, 14.389603, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 32
		{ n = "Pod", s = "Block", z = Vector3.new(7.173452, 0.426991, 2.971341), cf = CFrame.new(0, 14.389603, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 33
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 4.237179, 0.341593), cf = CFrame.new(0, 2.476549, -5.294678, -0.377055, 0.926191, 0, 0.926191, 0.377055, 0, 0, 0, -1), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 34
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 4.237179, 0.341593), cf = CFrame.new(0, 2.476549, 5.294678, 0.377055, -0.926191, 0, 0.926191, 0.377055, 0, 0, 0, 1), c = Color3.fromRGB(200, 188, 252), m = Enum.Material.Plastic }, -- 35
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 4.971331, 0.341593), cf = CFrame.new(4.46854, 4.440708, -4.468536, -0.250426, 0.661277, 0.707107, 0.935187, 0.354156, 0, -0.250426, 0.661277, -0.707107), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 36
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 4.971331, 0.341593), cf = CFrame.new(-4.468539, 4.440708, 4.468536, 0.250426, -0.661277, -0.707107, 0.935187, 0.354156, 0, 0.250426, -0.661277, 0.707107), c = Color3.fromRGB(200, 188, 252), m = Enum.Material.Plastic }, -- 37
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 5.37158, 0.341593), cf = CFrame.new(7.002656, 6.404868, 0, 0, 0, 1, 0.956413, 0.292019, 0, -0.292019, 0.956413, 0), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 38
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 5.37158, 0.341593), cf = CFrame.new(-7.002656, 6.404868, 0, 0, 0, -1, 0.956413, 0.292019, 0, 0.292019, -0.956413, 0), c = Color3.fromRGB(200, 188, 252), m = Enum.Material.Plastic }, -- 39
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 5.37158, 0.341593), cf = CFrame.new(4.951625, 8.283629, 4.95163, 0.206488, -0.676286, 0.707107, 0.956413, 0.292018, 0, -0.206488, 0.676286, 0.707107), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 40
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 5.37158, 0.341593), cf = CFrame.new(-4.951625, 8.283629, -4.95163, -0.206488, 0.676286, -0.707107, 0.956413, 0.292018, 0, 0.206488, -0.676286, -0.707107), c = Color3.fromRGB(200, 188, 252), m = Enum.Material.Plastic }, -- 41
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 4.747208, 0.341593), cf = CFrame.new(0, 10.247789, 5.977875, 0.372172, -0.928164, 0, 0.928164, 0.372172, 0, 0, 0, 1), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 42
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 4.747208, 0.341593), cf = CFrame.new(0, 10.247789, -5.977875, -0.372172, 0.928164, 0, 0.928164, 0.372172, 0, 0, 0, -1), c = Color3.fromRGB(200, 188, 252), m = Enum.Material.Plastic }, -- 43
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 3.727293, 0.341593), cf = CFrame.new(-3.260826, 12.12655, 3.260834, 0.2711, -0.653073, -0.707107, 0.923585, 0.383393, 0, 0.2711, -0.653073, 0.707107), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 44
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 3.727293, 0.341593), cf = CFrame.new(3.260826, 12.12655, -3.260834, -0.2711, 0.653073, 0.707107, 0.923585, 0.383393, 0, -0.2711, 0.653073, -0.707107), c = Color3.fromRGB(200, 188, 252), m = Enum.Material.Plastic }, -- 45
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 2.644585, 0.341593), cf = CFrame.new(-3.245133, 13.578321, 0, 0, 0, -1, 0.940009, 0.341149, 0, 0.341149, -0.940009, 0), c = Color3.fromRGB(150, 136, 226), m = Enum.Material.Plastic }, -- 46
		{ n = "SpiralRib", s = "Block", z = Vector3.new(0.853982, 2.644585, 0.341593), cf = CFrame.new(3.245133, 13.578321, 0, 0, 0, 1, 0.940009, 0.341149, 0, -0.341149, 0.940009, 0), c = Color3.fromRGB(200, 188, 252), m = Enum.Material.Plastic }, -- 47
		{ n = "EmblemPetal", s = "Block", z = Vector3.new(1.058938, 1.571328, 0.341593), cf = CFrame.new(1.328484, 8.672732, -7.002655, -0.707107, 0.707107, 0, 0.707107, 0.707107, 0, 0, 0, -1), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 48
		{ n = "EmblemPetal", s = "Block", z = Vector3.new(1.058938, 1.571328, 0.341593), cf = CFrame.new(-1.328484, 8.672732, -7.002655, -0.707107, -0.707107, 0, -0.707107, 0.707107, 0, 0, 0, -1), c = Color3.fromRGB(255, 160, 40), m = Enum.Material.Plastic }, -- 49
		{ n = "EmblemPetal", s = "Block", z = Vector3.new(1.058938, 1.571328, 0.341593), cf = CFrame.new(-1.328484, 6.015764, -7.002655, 0.707107, -0.707107, 0, -0.707107, -0.707107, 0, 0, 0, -1), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 50
		{ n = "EmblemPetal", s = "Block", z = Vector3.new(1.058938, 1.571328, 0.341593), cf = CFrame.new(1.328484, 6.015764, -7.002655, 0.707107, 0.707107, 0, 0.707107, -0.707107, 0, 0, 0, -1), c = Color3.fromRGB(255, 160, 40), m = Enum.Material.Plastic }, -- 51
		{ n = "EmblemBoss", s = "Block", z = Vector3.new(1.878761, 1.878761, 0.512389), cf = CFrame.new(0, 7.344248, -7.088043, -0.707107, 0.707107, 0, 0.707107, 0.707107, 0, 0, 0, -1), c = Color3.fromRGB(244, 192, 50), m = Enum.Material.Plastic }, -- 52
		{ n = "EmblemGem", s = "Block", z = Vector3.new(1.024779, 1.024779, 0.204956), cf = CFrame.new(0, 7.344248, -7.412567, -0.707107, 0.707107, 0, 0.707107, 0.707107, 0, 0, 0, -1), c = Color3.fromRGB(190, 235, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 53
		{ n = "LightningRod", s = "Block", z = Vector3.new(1.707965, 4.782301, 1.707965), cf = CFrame.new(0, 16.908852, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(190, 235, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 54
		{ n = "RainCrystal", s = "Block", z = Vector3.new(1.195575, 3.41593, 1.195575), cf = CFrame.new(0, 16.174931, -2.633545, -0.707107, 0, -0.707107, 0.171065, 0.970296, -0.171065, 0.686103, -0.241922, -0.686103), c = Color3.fromRGB(70, 170, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 55
		{ n = "RainCrystal", s = "Block", z = Vector3.new(1.195575, 2.391151, 1.195575), cf = CFrame.new(1.966919, 15.57333, -1.966919, -0.941474, 0.331967, -0.058526, 0.331967, 0.882947, -0.331967, -0.058527, -0.331967, -0.941474), c = Color3.fromRGB(190, 235, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 56
		{ n = "RainCrystal", s = "Block", z = Vector3.new(1.195575, 3.41593, 1.195575), cf = CFrame.new(2.633548, 16.174932, 0, -0.686103, 0.241922, 0.686103, 0.171065, 0.970296, -0.171065, -0.707107, 0, -0.707107), c = Color3.fromRGB(70, 170, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 57
		{ n = "RainCrystal", s = "Block", z = Vector3.new(1.195575, 2.391151, 1.195575), cf = CFrame.new(1.966919, 15.57333, 1.966919, 0.058526, 0.331967, 0.941474, 0.331967, 0.882947, -0.331967, -0.941474, 0.331967, -0.058527), c = Color3.fromRGB(190, 235, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 58
		{ n = "RainCrystal", s = "Block", z = Vector3.new(1.195575, 3.41593, 1.195575), cf = CFrame.new(0, 16.174931, 2.633545, 0.707107, 0, 0.707107, 0.171065, 0.970296, -0.171065, -0.686103, 0.241922, 0.686103), c = Color3.fromRGB(70, 170, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 59
		{ n = "RainCrystal", s = "Block", z = Vector3.new(1.195575, 2.391151, 1.195575), cf = CFrame.new(-1.966919, 15.57333, 1.966919, 0.941474, -0.331967, 0.058526, 0.331967, 0.882947, -0.331967, 0.058527, 0.331967, 0.941474), c = Color3.fromRGB(190, 235, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 60
		{ n = "RainCrystal", s = "Block", z = Vector3.new(1.195575, 3.41593, 1.195575), cf = CFrame.new(-2.633548, 16.174932, 0, 0.686103, -0.241922, -0.686103, 0.171065, 0.970296, -0.171065, 0.707107, 0, 0.707107), c = Color3.fromRGB(70, 170, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 61
		{ n = "RainCrystal", s = "Block", z = Vector3.new(1.195575, 2.391151, 1.195575), cf = CFrame.new(-1.966919, 15.57333, -1.966919, -0.058526, -0.331967, -0.941474, 0.331967, 0.882947, -0.331967, 0.941474, -0.331967, 0.058527), c = Color3.fromRGB(190, 235, 255), m = Enum.Material.Neon, st = false, cs = false }, -- 62
	},
	Joints = {
		{ k = "Motor6D", n = "Pod", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.597788, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 3, c0 = CFrame.new(0, 0, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 0, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 5, c0 = CFrame.new(0, 0, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 6, c0 = CFrame.new(0, 1.707965, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 7, c0 = CFrame.new(0, 1.707965, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 8, c0 = CFrame.new(0, 1.707965, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 9, c0 = CFrame.new(0, 1.707965, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 10, c0 = CFrame.new(0, 3.672124, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 11, c0 = CFrame.new(0, 3.672124, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 12, c0 = CFrame.new(0, 3.672124, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 13, c0 = CFrame.new(0, 3.672124, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 14, c0 = CFrame.new(0, 6.575664, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 15, c0 = CFrame.new(0, 6.575664, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 16, c0 = CFrame.new(0, 6.575664, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 17, c0 = CFrame.new(0, 6.575664, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 18, c0 = CFrame.new(0, 9.479205, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 19, c0 = CFrame.new(0, 9.479205, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 20, c0 = CFrame.new(0, 9.479205, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 21, c0 = CFrame.new(0, 9.479205, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 22, c0 = CFrame.new(0, 11.357965, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 23, c0 = CFrame.new(0, 11.357965, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 24, c0 = CFrame.new(0, 11.357965, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 25, c0 = CFrame.new(0, 11.357965, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 26, c0 = CFrame.new(0, 12.809736, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 27, c0 = CFrame.new(0, 12.809736, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 28, c0 = CFrame.new(0, 12.809736, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 29, c0 = CFrame.new(0, 12.809736, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 30, c0 = CFrame.new(0, 13.621019, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 31, c0 = CFrame.new(0, 13.621019, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 32, c0 = CFrame.new(0, 13.621019, 0, 0, 0, 1, 0, 1, 0, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 33, c0 = CFrame.new(0, 13.621019, 0, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 34, c0 = CFrame.new(0, 1.707965, -5.294691, -0.377055, 0.926191, 0, 0.926191, 0.377055, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 35, c0 = CFrame.new(0, 1.707965, 5.294691, 0.377055, -0.926191, 0, 0.926191, 0.377055, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 36, c0 = CFrame.new(4.46854, 3.672124, -4.46854, -0.250426, 0.661277, 0.707107, 0.935187, 0.354156, 0, -0.250426, 0.661277, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 37, c0 = CFrame.new(-4.46854, 3.672124, 4.46854, 0.250426, -0.661277, -0.707107, 0.935187, 0.354156, 0, 0.250426, -0.661277, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 38, c0 = CFrame.new(7.002656, 5.636284, 0, 0, 0, 1, 0.956413, 0.292019, 0, -0.292019, 0.956413, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 39, c0 = CFrame.new(-7.002656, 5.636284, 0, 0, 0, -1, 0.956413, 0.292019, 0, 0.292019, -0.956413, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 40, c0 = CFrame.new(4.951625, 7.515045, 4.951625, 0.206488, -0.676286, 0.707107, 0.956413, 0.292018, 0, -0.206488, 0.676286, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 41, c0 = CFrame.new(-4.951625, 7.515045, -4.951625, -0.206488, 0.676286, -0.707107, 0.956413, 0.292018, 0, 0.206488, -0.676286, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 42, c0 = CFrame.new(0, 9.479205, 5.977877, 0.372172, -0.928164, 0, 0.928164, 0.372172, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 43, c0 = CFrame.new(0, 9.479205, -5.977877, -0.372172, 0.928164, 0, 0.928164, 0.372172, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 44, c0 = CFrame.new(-3.260826, 11.357965, 3.260826, 0.2711, -0.653073, -0.707107, 0.923585, 0.383393, 0, 0.2711, -0.653073, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 45, c0 = CFrame.new(3.260826, 11.357965, -3.260826, -0.2711, 0.653073, 0.707107, 0.923585, 0.383393, 0, -0.2711, 0.653073, -0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 46, c0 = CFrame.new(-3.245133, 12.809736, 0, 0, 0, -1, 0.940009, 0.341149, 0, 0.341149, -0.940009, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 47, c0 = CFrame.new(3.245133, 12.809736, 0, 0, 0, 1, 0.940009, 0.341149, 0, -0.341149, 0.940009, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 48, c0 = CFrame.new(1.328484, 7.904149, -7.002656, -0.707107, 0.707107, 0, 0.707107, 0.707107, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 49, c0 = CFrame.new(-1.328484, 7.904149, -7.002656, -0.707107, -0.707107, 0, -0.707107, 0.707107, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 50, c0 = CFrame.new(-1.328484, 5.24718, -7.002656, 0.707107, -0.707107, 0, -0.707107, -0.707107, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 51, c0 = CFrame.new(1.328484, 5.24718, -7.002656, 0.707107, 0.707107, 0, 0.707107, -0.707107, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 52, c0 = CFrame.new(0, 6.575664, -7.088054, -0.707107, 0.707107, 0, 0.707107, 0.707107, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 53, c0 = CFrame.new(0, 6.575664, -7.412568, -0.707107, 0.707107, 0, 0.707107, 0.707107, 0, 0, 0, -1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Rod", h = 2, a = 2, b = 54, c0 = CFrame.new(0, 13.749117, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -2.391151, 0, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107) },
		{ k = "Motor6D", n = "Spike0", h = 2, a = 2, b = 55, c0 = CFrame.new(0, 13.749117, -2.220354, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.707965, 0, -0.707107, 0.171065, 0.686103, 0, 0.970296, -0.241922, -0.707107, -0.171065, -0.686103) },
		{ k = "Motor6D", n = "Spike1", h = 2, a = 2, b = 56, c0 = CFrame.new(1.570028, 13.749117, -1.570028, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.195575, 0, -0.941474, 0.331967, -0.058527, 0.331967, 0.882947, -0.331967, -0.058526, -0.331967, -0.941474) },
		{ k = "Motor6D", n = "Spike2", h = 2, a = 2, b = 57, c0 = CFrame.new(2.220354, 13.749117, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.707965, 0, -0.686103, 0.171065, -0.707107, 0.241922, 0.970296, 0, 0.686103, -0.171065, -0.707107) },
		{ k = "Motor6D", n = "Spike3", h = 2, a = 2, b = 58, c0 = CFrame.new(1.570028, 13.749117, 1.570028, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.195575, 0, 0.058526, 0.331967, -0.941474, 0.331967, 0.882947, 0.331967, 0.941474, -0.331967, -0.058527) },
		{ k = "Motor6D", n = "Spike4", h = 2, a = 2, b = 59, c0 = CFrame.new(0, 13.749117, 2.220354, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.707965, 0, 0.707107, 0.171065, -0.686103, 0, 0.970296, 0.241922, 0.707107, -0.171065, 0.686103) },
		{ k = "Motor6D", n = "Spike5", h = 2, a = 2, b = 60, c0 = CFrame.new(-1.570028, 13.749117, 1.570028, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.195575, 0, 0.941474, 0.331967, 0.058527, -0.331967, 0.882947, 0.331967, 0.058526, -0.331967, 0.941474) },
		{ k = "Motor6D", n = "Spike6", h = 2, a = 2, b = 61, c0 = CFrame.new(-2.220354, 13.749117, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.707965, 0, 0.686103, 0.171065, 0.707107, -0.241922, 0.970296, 0, -0.686103, -0.171065, 0.707107) },
		{ k = "Motor6D", n = "Spike7", h = 2, a = 2, b = 62, c0 = CFrame.new(-1.570028, 13.749117, -1.570028, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -1.195575, 0, -0.058526, 0.331967, 0.941474, -0.331967, 0.882947, -0.331967, -0.941474, -0.331967, 0.058527) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "StormGlow", p = 53, range = 15, brightness = 1, color = Color3.new(1, 0.85, 0.42), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Drip", p = 54, rate = 10, enabled = true, lifetime = NumberRange.new(1.4, 2.1), speed = NumberRange.new(3.41593, 6.831859), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.47823, 0), NumberSequenceKeypoint.new(1, 0.170796, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.78, 0.94, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.27, 0.67, 1)) }), lightEmission = 0.7, lightInfluence = 0, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(45, 45), acceleration = Vector3.new(0, -27.327436, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Textures = {
	},
}

return spec
