--!strict
--==============================================================================
-- BIOME SECRET FORM: Grovemaw's pod (Greenhollow's secret pod), 2026-10-16
--
-- Lifted part for part, joint for joint, light, emitter and attribute
-- from the owner's ServerStorage model "Greenhollow Secret/Secret Grenhollow Pod" by a read-only generator on
-- 2026-10-16. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-16-biome-secrets-originals. It carried
-- a LidHinge Motor6D and its PodOpening script (ported, not run).
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
	Source = "Greenhollow Secret/Secret Grenhollow Pod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(29.706665, 30.220221, 29.657639), Height = 30.220221, PartCount = 30,
	Base = 0,
	Unit = 1, ModelScale = 24.371147,
	Attributes = {},
	Owner = { Biome = "greenhollow", BottomOffset = 0, ClosedDepth = 1.216916, ClosedHeight = 1.24, ClosedWidth = 1.218926, EpicLightEnabled = true, IsPod = true, OpenAmount = 0, OpenDuration = 0.45, PartCount = 30, Rarity = "Epic", RulesVersion = "2026-10-09", ShellCentre = Vector3.new(0, 0.549393, 0), SizeSeamRole = "Seam", SpawnMode = "CameraFloor", Species = "Grovemaw", Unit = 1, WidthClassUnit = 1 },
	Pivot = CFrame.new(0, -0.000002, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	Parts = {
		{ n = "Blossom_01", s = "Block", z = Vector3.new(3.655672, 2.437115, 3.655672), cf = CFrame.new(6.622955, 24.235683, -6.622948, 0.90518, 0.264887, 0.332392, -0.333777, 0.927184, 0.170068, -0.26314, -0.264887, 0.927681), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Seam" } }, -- 1
		{ n = "Blossom_02", s = "Block", z = Vector3.new(3.655672, 2.437115, 3.655672), cf = CFrame.new(-6.622955, 24.235683, -6.622955, 0.394725, -0.264887, 0.879788, -0.14637, 0.927184, 0.344827, -0.907066, -0.264887, 0.327211), c = Color3.fromRGB(240, 150, 168), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.941176, 0.588235, 0.658824), TintRole = "Seam" } }, -- 2
		{ n = "Blossom_03", s = "Block", z = Vector3.new(3.655672, 2.437115, 3.655672), cf = CFrame.new(6.622955, 24.235683, 6.622955, 0.405022, 0.264887, -0.875096, -0.356272, 0.927184, 0.11576, 0.842038, 0.264887, 0.469901), c = Color3.fromRGB(240, 150, 168), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.941176, 0.588235, 0.658824), TintRole = "Seam" } }, -- 3
		{ n = "Blossom_04", s = "Block", z = Vector3.new(3.655672, 2.437115, 3.655672), cf = CFrame.new(-6.622955, 24.235683, 6.622955, -0.950105, -0.264887, 0.16473, -0.204025, 0.927184, 0.314172, -0.235954, 0.264887, -0.934966), c = Color3.fromRGB(240, 228, 198), m = Enum.Material.Plastic, g = "SizeSeam", a = { BaseColor = Color3.new(0.941176, 0.894118, 0.776471), TintRole = "Seam" } }, -- 4
		{ n = "SapFront", s = "Block", z = Vector3.new(1.218557, 6.58021, 0.974846), cf = CFrame.new(0.487427, 10.479591, -6.458351, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.fromRGB(196, 255, 110), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(0.768627, 1, 0.431373), TintRole = "Gem" } }, -- 5
		{ n = "SapBack", s = "Block", z = Vector3.new(1.218557, 5.605364, 0.974846), cf = CFrame.new(-0.73114, 11.210726, 6.458351, 0.984808, 0.173648, 0, -0.173648, 0.984808, 0, 0, 0, 1), c = Color3.fromRGB(196, 255, 110), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(0.768627, 1, 0.431373), TintRole = "Gem" } }, -- 6
		{ n = "BurlSeed", s = "Ball", z = Vector3.new(4.874229, 4.874229, 4.874229), cf = CFrame.new(0, 19.009491, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(220, 255, 160), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(0.862745, 1, 0.627451), TintRole = "Glow" } }, -- 7
		{ n = "HeartBud", s = "Ball", z = Vector3.new(5.361652, 5.361652, 5.361652), cf = CFrame.new(0, 27.539394, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(196, 255, 110), m = Enum.Material.Neon, g = "GlowAccents", a = { BaseColor = Color3.new(0.768627, 1, 0.431373), TintRole = "Gem" } }, -- 8
		{ n = "SeedBase", s = "Block", z = Vector3.new(7.311345, 0.974846, 7.311345), cf = CFrame.new(0, 10.723303, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(82, 54, 40), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.211765, 0.156863), TintRole = "Shell" } }, -- 9
		{ n = "PodCore", s = "Block", z = Vector3.new(7.035344, 11.698151, 12.185574), cf = CFrame.new(0, 10.723303, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(92, 60, 44), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.360784, 0.235294, 0.172549), TintRole = "Shell" } }, -- 10
		{ n = "BurlFacetsA", s = "Block", z = Vector3.new(7.035344, 10.235882, 12.185574), cf = CFrame.new(0, 10.723303, 0, 0.5, 0, 0.866026, 0, 1, 0, -0.866026, 0, 0.5), c = Color3.fromRGB(82, 54, 40), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.211765, 0.156863), TintRole = "Shell" } }, -- 11
		{ n = "BurlFacetsB", s = "Block", z = Vector3.new(7.035344, 10.723305, 12.185574), cf = CFrame.new(0, 10.479591, 0, 0.5, 0, -0.866026, 0, 1, 0, 0.866026, 0, 0.5), c = Color3.fromRGB(100, 66, 48), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.392157, 0.258824, 0.188235), TintRole = "Shell" } }, -- 12
		{ n = "FrontLeftRoot", s = "Block", z = Vector3.new(2.924538, 8.765485, 2.924538), cf = CFrame.new(3.68042, 10.18749, -6.374657, 0.866026, 0.450501, -0.216908, 0, 0.433815, 0.901001, 0.5, -0.78029, 0.375695), c = Color3.fromRGB(92, 60, 44), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.360784, 0.235294, 0.172549), TintRole = "Shell" } }, -- 13
		{ n = "FrontLeftClaw", s = "Wedge", z = Vector3.new(2.680826, 12.216608, 2.193403), cf = CFrame.new(6.33905, 5.968336, -10.97953, -0.866026, 0.219856, -0.449069, 0, -0.898138, -0.439713, -0.5, -0.380802, 0.777811), c = Color3.fromRGB(82, 54, 40), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.211765, 0.156863), TintRole = "Shell" } }, -- 14
		{ n = "MidLeftRoot", s = "Block", z = Vector3.new(2.924538, 8.546689, 2.924538), cf = CFrame.new(7.234161, 10.197285, 0, 0, 0.894427, -0.447214, 0, 0.447213, 0.894427, 1, 0, 0), c = Color3.fromRGB(92, 60, 44), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.360784, 0.235294, 0.172549), TintRole = "Shell" } }, -- 15
		{ n = "MidLeftClaw", s = "Wedge", z = Vector3.new(2.680826, 11.801777, 2.193403), cf = CFrame.new(11.786285, 5.916586, 0, 0, 0.34534, -0.938478, 0, -0.938478, -0.34534, -1, 0, 0), c = Color3.fromRGB(82, 54, 40), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.211765, 0.156863), TintRole = "Shell" } }, -- 16
		{ n = "RearLeftRoot", s = "Block", z = Vector3.new(2.924538, 8.765485, 2.924538), cf = CFrame.new(3.68042, 10.18749, 6.374657, -0.866026, 0.450501, -0.216908, 0, 0.433815, 0.901001, 0.5, 0.78029, -0.375695), c = Color3.fromRGB(92, 60, 44), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.360784, 0.235294, 0.172549), TintRole = "Shell" } }, -- 17
		{ n = "RearLeftClaw", s = "Wedge", z = Vector3.new(2.680826, 12.216608, 2.193403), cf = CFrame.new(6.33905, 5.968336, 10.97953, 0.866026, 0.219856, -0.449069, 0, -0.898138, -0.439713, -0.5, 0.380802, -0.777811), c = Color3.fromRGB(82, 54, 40), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.211765, 0.156863), TintRole = "Shell" } }, -- 18
		{ n = "FrontRightRoot", s = "Block", z = Vector3.new(2.924538, 8.765485, 2.924538), cf = CFrame.new(-3.68042, 10.18749, -6.374657, 0.866026, -0.450501, 0.216908, 0, 0.433815, 0.901001, -0.5, -0.78029, 0.375695), c = Color3.fromRGB(92, 60, 44), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.360784, 0.235294, 0.172549), TintRole = "Shell" } }, -- 19
		{ n = "FrontRightClaw", s = "Wedge", z = Vector3.new(2.680826, 12.216608, 2.193403), cf = CFrame.new(-6.33905, 5.968336, -10.97953, -0.866026, -0.219856, 0.449069, 0, -0.898138, -0.439713, 0.5, -0.380802, 0.777811), c = Color3.fromRGB(82, 54, 40), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.211765, 0.156863), TintRole = "Shell" } }, -- 20
		{ n = "MidRightRoot", s = "Block", z = Vector3.new(2.924538, 8.546689, 2.924538), cf = CFrame.new(-7.234161, 10.197285, 0, 0, -0.894427, 0.447214, 0, 0.447213, 0.894427, -1, 0, 0), c = Color3.fromRGB(92, 60, 44), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.360784, 0.235294, 0.172549), TintRole = "Shell" } }, -- 21
		{ n = "MidRightClaw", s = "Wedge", z = Vector3.new(2.680826, 11.801777, 2.193403), cf = CFrame.new(-11.786285, 5.916586, 0, 0, -0.34534, 0.938478, 0, -0.938478, -0.34534, 1, 0, 0), c = Color3.fromRGB(82, 54, 40), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.211765, 0.156863), TintRole = "Shell" } }, -- 22
		{ n = "RearRightRoot", s = "Block", z = Vector3.new(2.924538, 8.765485, 2.924538), cf = CFrame.new(-3.68042, 10.18749, 6.374657, -0.866026, -0.450501, 0.216908, 0, 0.433815, 0.901001, -0.5, 0.78029, -0.375695), c = Color3.fromRGB(92, 60, 44), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.360784, 0.235294, 0.172549), TintRole = "Shell" } }, -- 23
		{ n = "RearRightClaw", s = "Wedge", z = Vector3.new(2.680826, 12.216608, 2.193403), cf = CFrame.new(-6.33905, 5.968336, 10.97953, 0.866026, -0.219856, 0.449069, 0, -0.898138, -0.439713, 0.5, 0.380802, -0.777811), c = Color3.fromRGB(82, 54, 40), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.321569, 0.211765, 0.156863), TintRole = "Shell" } }, -- 24
		{ n = "UpperMantle", s = "Block", z = Vector3.new(18.034649, 3.411961, 18.034649), cf = CFrame.new(0, 18.278358, 0, 0.978148, 0, 0.207912, 0, 1, 0, -0.207912, 0, 0.978148), c = Color3.fromRGB(60, 118, 62), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.235294, 0.462745, 0.243137), TintRole = "Plate" } }, -- 25
		{ n = "CanopyTop", s = "Block", z = Vector3.new(11.210728, 5.849075, 11.210728), cf = CFrame.new(0, 22.908876, 0, 0.866025, 0, -0.5, 0, 1, 0, 0.5, 0, 0.866025), c = Color3.fromRGB(124, 182, 92), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.486275, 0.713726, 0.360784), TintRole = "Plate" } }, -- 26
		{ n = "FrontLeftClump", s = "Block", z = Vector3.new(7.311345, 4.874229, 7.311345), cf = CFrame.new(5.68689, 20.959185, -5.68689, 0.875096, 0.264887, -0.405022, -0.11576, 0.927184, 0.356272, 0.469901, -0.264887, 0.842038), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.368627, 0.596078, 0.407843), TintRole = "Halo" } }, -- 27
		{ n = "FrontRightClump", s = "Block", z = Vector3.new(7.311345, 4.874229, 7.311345), cf = CFrame.new(-5.68689, 20.959185, -5.68689, 0.901217, -0.264887, 0.342992, 0.14033, 0.927184, 0.347329, -0.410019, -0.264887, 0.872765), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.690196, 0.839216, 0.501961), TintRole = "Halo" } }, -- 28
		{ n = "RearLeftClump", s = "Block", z = Vector3.new(7.311345, 4.874229, 7.311345), cf = CFrame.new(5.68689, 20.959185, 5.68689, -0.332392, 0.264887, -0.90518, -0.170068, 0.927184, 0.333777, 0.927681, 0.264887, -0.26314), c = Color3.fromRGB(176, 214, 128), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.690196, 0.839216, 0.501961), TintRole = "Halo" } }, -- 29
		{ n = "RearRightClump", s = "Block", z = Vector3.new(7.311345, 4.874229, 7.311345), cf = CFrame.new(-5.68689, 20.959185, 5.68689, -0.555344, -0.264887, 0.788307, 0.077885, 0.927184, 0.366421, -0.827965, 0.264887, -0.494275), c = Color3.fromRGB(94, 152, 104), m = Enum.Material.Plastic, a = { BaseColor = Color3.new(0.368627, 0.596078, 0.407843), TintRole = "Halo" } }, -- 30
	},
	Joints = {
		{ k = "Weld", n = "Weld", h = 9, a = 9, b = 10, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 11, c0 = CFrame.new(0, 0, 0, 0.5, 0, 0.866025, 0, 1, 0, -0.866025, 0, 0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 12, c0 = CFrame.new(0, -0.243711, 0, 0.5, 0, -0.866025, 0, 1, 0, 0.866025, 0, 0.5), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 5, c0 = CFrame.new(0.487423, -0.243711, -6.458354, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 6, c0 = CFrame.new(-0.731134, 0.487423, 6.458354, 0.984808, 0.173648, 0, -0.173648, 0.984808, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 13, c0 = CFrame.new(3.680409, -0.535813, -6.374656, 0.866025, 0.450501, -0.216908, 0, 0.433816, 0.901002, 0.5, -0.78029, 0.375695), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 15, c0 = CFrame.new(7.234156, -0.526017, 0, 0, 0.894427, -0.447214, 0, 0.447214, 0.894427, 1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 17, c0 = CFrame.new(3.680409, -0.535813, 6.374656, -0.866025, 0.450501, -0.216908, 0, 0.433816, 0.901002, 0.5, 0.78029, -0.375695), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 19, c0 = CFrame.new(-3.680409, -0.535813, -6.374656, 0.866025, -0.450501, 0.216908, 0, 0.433816, 0.901002, -0.5, -0.78029, 0.375695), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 21, c0 = CFrame.new(-7.234156, -0.526017, 0, 0, -0.894427, 0.447214, 0, 0.447214, 0.894427, -1, 0, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 23, c0 = CFrame.new(-3.680409, -0.535813, 6.374656, -0.866025, -0.450501, 0.216908, 0, 0.433816, 0.901002, -0.5, 0.78029, -0.375695), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 10, a = 10, b = 7, c0 = CFrame.new(0, 8.286189, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "LidHinge", h = 10, a = 10, b = 25, c0 = CFrame.new(0, 5.849075, 11.16613, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(-2.321569, -1.70598, 10.922124, 0.978148, 0, -0.207912, 0, 1, 0, 0.207912, 0, 0.978148) },
		{ k = "Weld", n = "Weld", h = 13, a = 13, b = 14, c0 = CFrame.new(0, 2.960516, -6.108171, -1, 0, 0, 0, 0.006555, -0.999978, 0, -0.999978, -0.006555), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 15, a = 15, b = 16, c0 = CFrame.new(0, 2.157148, -5.864542, -1, 0, 0, 0, -0.110819, -0.993841, 0, -0.993841, 0.110819), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 17, a = 17, b = 18, c0 = CFrame.new(0, 2.960516, -6.108171, -1, 0, 0, 0, 0.006555, -0.999978, 0, -0.999978, -0.006555), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 19, a = 19, b = 20, c0 = CFrame.new(0, 2.960516, -6.108171, -1, 0, 0, 0, 0.006555, -0.999978, 0, -0.999978, -0.006555), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 21, a = 21, b = 22, c0 = CFrame.new(0, 2.157148, -5.864542, -1, 0, 0, 0, -0.110819, -0.993841, 0, -0.993841, 0.110819), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 23, a = 23, b = 24, c0 = CFrame.new(0, 2.960516, -6.108171, -1, 0, 0, 0, 0.006555, -0.999978, 0, -0.999978, -0.006555), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 25, a = 25, b = 26, c0 = CFrame.new(0, 4.630518, 0, 0.743145, 0, -0.669131, 0, 1, 0, 0.669131, 0, 0.743145), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 25, a = 25, b = 27, c0 = CFrame.new(6.74499, 2.680826, -4.380248, 0.758275, 0.314172, -0.571241, -0.11576, 0.927184, 0.356272, 0.641576, -0.204025, 0.739428), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 25, a = 25, b = 28, c0 = CFrame.new(-4.380248, 2.680826, -6.74499, 0.966771, -0.204025, 0.154038, 0.14033, 0.927184, 0.347329, -0.213686, -0.314172, 0.925005), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 25, a = 25, b = 29, c0 = CFrame.new(4.380248, 2.680826, 6.74499, -0.518005, 0.204025, -0.830689, -0.170068, 0.927184, 0.333777, 0.838301, 0.314172, -0.445587), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 25, a = 25, b = 30, c0 = CFrame.new(-6.74499, 2.680826, 4.380248, -0.371065, -0.314172, 0.873846, 0.077885, 0.927184, 0.366421, -0.925335, 0.204025, -0.319576), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 26, a = 26, b = 8, c0 = CFrame.new(0, 4.630518, 0, 0.866025, 0, 0.5, 0, 1, 0, -0.5, 0, 0.866025), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 27, a = 27, b = 1, c0 = CFrame.new(0, 3.533817, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 28, a = 28, b = 2, c0 = CFrame.new(0, 3.533817, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 29, a = 29, b = 3, c0 = CFrame.new(0.000001, 3.533817, 0, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Weld", h = 30, a = 30, b = 4, c0 = CFrame.new(0, 3.533817, -0.000001, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
		{ n = "EpicLight", p = 7, range = 2.6, brightness = 0.4, color = Color3.new(0.768627, 1, 0.431373), shadows = false, enabled = true, a = { TintRole = "GlowLight" } },
	},
	Emitters = {
	},
	Textures = {
	},
	Beams = {
	},
}

return spec
