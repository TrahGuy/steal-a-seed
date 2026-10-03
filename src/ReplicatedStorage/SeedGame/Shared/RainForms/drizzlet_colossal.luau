--!strict
--==============================================================================
-- RAIN EVENT FORM: Pod 2's larger Drizzlet (the model is labelled "POD 3"; the owner confirmed it is Pod 2's, 2026-10-02)
--
-- Lifted part for part, joint for joint, light, emitter, trail and billboard
-- for each, from the owner's supplied Workspace model "Drizzlet POD 3" (folder
-- "Rain Event") by a read-only generator on 2026-10-02. The original was not
-- moved or changed; a verified .rbxm of it is in
-- output/model-backups/2026-10-02-rain-event-originals.
--
-- DATA, NOT ART DIRECTION. Every size, CFrame (relative to the model's BASE:
-- its root part's x/z at the lowest drawn point), colour, material, surface,
-- attribute, Motor6D and Weld (C0 and C1) is the supplied number, at the size
-- it was supplied. Nothing is scaled, normalised or stripped. Joints point at
-- parts by INDEX, because names repeat. See RainForms (the parent module).
--==============================================================================
local SecretForms = require(script.Parent.Parent:WaitForChild("SecretForms"))

local spec: SecretForms.FormSpec = {
	Source = "Drizzlet POD 3", Kind = "plant", Yaw = 0,
	Size = Vector3.new(25.722744, 48.145269, 22.970738), Height = 48.145269, PartCount = 68,
	Base = 1,
	Attributes = { ProceduralIdle = true, Unit = 3 },
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(10.819161, 2.163832, 10.819161), cf = CFrame.new(0, 1.081917, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.337255, 0.643137, 0.901961), m = Enum.Material.Plastic, t = 1, cs = false }, -- 1
		{ n = "Body", s = "Block", z = Vector3.new(14.42555, 4.327664, 14.42555), cf = CFrame.new(0, 8.655329, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.337255, 0.643137, 0.901961), m = Enum.Material.Plastic }, -- 2
		{ n = "Drop", s = "Block", z = Vector3.new(12.261715, 4.327664, 12.261715), cf = CFrame.new(0, 4.327664, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.235294, 0.517647, 0.807843), m = Enum.Material.Plastic }, -- 3
		{ n = "Drop", s = "Block", z = Vector3.new(12.982993, 3.606387, 12.982993), cf = CFrame.new(0, 12.622355, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.337255, 0.643137, 0.901961), m = Enum.Material.Plastic }, -- 4
		{ n = "Drop", s = "Block", z = Vector3.new(10.097884, 3.245748, 10.097884), cf = CFrame.new(0, 16.048424, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 5
		{ n = "Drop", s = "Block", z = Vector3.new(6.491497, 2.88511, 6.491497), cf = CFrame.new(0, 19.11385, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 6
		{ n = "Drop", s = "Block", z = Vector3.new(3.606387, 2.524471, 3.606387), cf = CFrame.new(0, 21.818642, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.768627, 0.901961, 0.988235), m = Enum.Material.Plastic }, -- 7
		{ n = "Belly", s = "Block", z = Vector3.new(7.934051, 5.770219, 0.901597), cf = CFrame.new(0, 6.852135, -7.663574, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.768627, 0.901961, 0.988235), m = Enum.Material.Plastic }, -- 8
		{ n = "Band", s = "Block", z = Vector3.new(14.786187, 0.721277, 14.786187), cf = CFrame.new(0, 6.852135, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 9
		{ n = "Highlight", s = "Block", z = Vector3.new(0.721277, 2.524471, 0.721277), cf = CFrame.new(3.24575, 16.048424, -5.409576, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 1, 1), m = Enum.Material.SmoothPlastic, st = false }, -- 10
		{ n = "Highlight", s = "Block", z = Vector3.new(0.721277, 1.442555, 0.721277), cf = CFrame.new(1.803192, 19.11385, -3.606384, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 1, 1), m = Enum.Material.SmoothPlastic, st = false }, -- 11
		{ n = "Bump", s = "Block", z = Vector3.new(0.721277, 1.803194, 2.524471), cf = CFrame.new(-7.57341, 9.015968, 2.524475, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 12
		{ n = "Bump", s = "Block", z = Vector3.new(0.721277, 1.442555, 2.163832), cf = CFrame.new(-6.852135, 12.622355, -1.081909, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 13
		{ n = "Bump", s = "Block", z = Vector3.new(0.721277, 1.803194, 2.524471), cf = CFrame.new(7.57341, 9.015968, 2.524475, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 14
		{ n = "Bump", s = "Block", z = Vector3.new(0.721277, 1.442555, 2.163832), cf = CFrame.new(6.852135, 12.622355, -1.081909, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 15
		{ n = "Eye", s = "Block", z = Vector3.new(3.065429, 3.606387, 0.721277), cf = CFrame.new(-2.812981, 12.442035, -6.852142, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.101961, 0.133333, 0.219608), m = Enum.Material.SmoothPlastic, st = false }, -- 16
		{ n = "Shine", s = "Block", z = Vector3.new(1.081916, 1.081916, 0.360639), cf = CFrame.new(-2.199898, 13.343632, -7.302948, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 1, 1), m = Enum.Material.SmoothPlastic, st = false }, -- 17
		{ n = "Brow", s = "Block", z = Vector3.new(1.622874, 0.540958, 0.360639), cf = CFrame.new(-2.812981, 14.786186, -6.671814, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.new(0.101961, 0.133333, 0.219608), m = Enum.Material.SmoothPlastic, st = false }, -- 18
		{ n = "Blush", s = "Block", z = Vector3.new(1.442555, 0.793405, 0.360639), cf = CFrame.new(-5.229263, 11.1798, -6.671814, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 0.588235, 0.690196), m = Enum.Material.SmoothPlastic, st = false }, -- 19
		{ n = "Eye", s = "Block", z = Vector3.new(3.065429, 3.606387, 0.721277), cf = CFrame.new(2.812981, 12.442035, -6.852142, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.101961, 0.133333, 0.219608), m = Enum.Material.SmoothPlastic, st = false }, -- 20
		{ n = "Shine", s = "Block", z = Vector3.new(1.081916, 1.081916, 0.360639), cf = CFrame.new(3.426071, 13.343632, -7.302948, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 1, 1), m = Enum.Material.SmoothPlastic, st = false }, -- 21
		{ n = "Brow", s = "Block", z = Vector3.new(1.622874, 0.540958, 0.360639), cf = CFrame.new(2.812981, 14.786186, -6.671814, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.new(0.101961, 0.133333, 0.219608), m = Enum.Material.SmoothPlastic, st = false }, -- 22
		{ n = "Blush", s = "Block", z = Vector3.new(1.442555, 0.793405, 0.360639), cf = CFrame.new(5.229263, 11.1798, -6.671814, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 0.588235, 0.690196), m = Enum.Material.SmoothPlastic, st = false }, -- 23
		{ n = "Mouth", s = "Block", z = Vector3.new(1.803194, 0.540958, 0.360639), cf = CFrame.new(0, 10.999481, -6.671814, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.101961, 0.133333, 0.219608), m = Enum.Material.SmoothPlastic, st = false }, -- 24
		{ n = "Foot", s = "Block", z = Vector3.new(4.327664, 2.163832, 5.409581), cf = CFrame.new(-3.606384, 1.081917, -1.081909, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 25
		{ n = "Toe", s = "Block", z = Vector3.new(1.262236, 1.081916, 1.081916), cf = CFrame.new(-4.688301, 0.540959, -4.147339, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 26
		{ n = "Toe", s = "Block", z = Vector3.new(1.262236, 1.081916, 1.081916), cf = CFrame.new(-2.524467, 0.540959, -4.147339, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 27
		{ n = "Arm", s = "Block", z = Vector3.new(2.524471, 0.721277, 5.11779), cf = CFrame.new(-9.015968, 8.11437, -0.901611, 0.447214, -0.474644, 0.758098, 0, 0.84758, 0.530669, -0.894427, -0.237322, 0.379049), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 28
		{ n = "ArmTip", s = "Block", z = Vector3.new(1.442555, 0.64915, 2.703151), cf = CFrame.new(-11.360123, 6.401337, -2.0737, 0.447213, -0.474644, 0.758098, 0, 0.84758, 0.530669, -0.894427, -0.237322, 0.379049), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 29
		{ n = "Foot", s = "Block", z = Vector3.new(4.327664, 2.163832, 5.409581), cf = CFrame.new(3.606384, 1.081917, -1.081909, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 30
		{ n = "Toe", s = "Block", z = Vector3.new(1.262236, 1.081916, 1.081916), cf = CFrame.new(2.524467, 0.540959, -4.147339, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 31
		{ n = "Toe", s = "Block", z = Vector3.new(1.262236, 1.081916, 1.081916), cf = CFrame.new(4.688301, 0.540959, -4.147339, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 32
		{ n = "Arm", s = "Block", z = Vector3.new(2.524471, 0.721277, 5.11779), cf = CFrame.new(9.015968, 8.11437, -0.901611, 0.447214, 0.474644, -0.758098, 0, 0.84758, 0.530669, 0.894427, -0.237322, 0.379049), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 33
		{ n = "ArmTip", s = "Block", z = Vector3.new(1.442555, 0.64915, 2.703151), cf = CFrame.new(11.360123, 6.401337, -2.0737, 0.447213, 0.474644, -0.758098, 0, 0.84758, 0.530669, 0.894427, -0.237322, 0.379049), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 34
		{ n = "BackLeaf", s = "Block", z = Vector3.new(2.524471, 0.721277, 7.010486), cf = CFrame.new(0, 18.753212, 6.852142, -1, 0, 0, 0, 0.759257, -0.650791, 0, -0.650791, -0.759257), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 35
		{ n = "BackLeafTip", s = "Block", z = Vector3.new(1.442555, 0.64915, 2.887395), cf = CFrame.new(0, 21.548161, 10.188049, -1, 0, 0, 0, 0.773957, -0.633238, 0, -0.633238, -0.773957), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 36
		{ n = "BackDrip", s = "Ball", z = Vector3.new(2.344151, 2.344151, 2.344151), cf = CFrame.new(0, 5.409581, 8.222565, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false }, -- 37
		{ n = "BackDripNeck", s = "Block", z = Vector3.new(1.081916, 1.622874, 1.081916), cf = CFrame.new(0, 6.960327, 8.006195, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false }, -- 38
		{ n = "Stem", s = "Block", z = Vector3.new(1.262236, 1.262236, 4.308926), cf = CFrame.new(0, 24.884071, 0.360626, -1, 0, 0, 0, 0.196116, -0.980581, 0, -0.980581, -0.196116), c = Color3.new(0.27451, 0.54902, 0.27451), m = Enum.Material.Plastic }, -- 39
		{ n = "Collar", s = "Block", z = Vector3.new(2.524471, 0.721277, 2.524471), cf = CFrame.new(0, 23.261198, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 40
		{ n = "Stem", s = "Block", z = Vector3.new(1.081916, 1.081916, 4.218764), cf = CFrame.new(0, 28.490459, 0.360626, 1, 0, 0, 0, 0.196116, -0.980581, 0, 0.980581, 0.196116), c = Color3.new(0.27451, 0.54902, 0.27451), m = Enum.Material.Plastic }, -- 41
		{ n = "Leaflet", s = "Block", z = Vector3.new(1.442555, 0.540958, 3.200321), cf = CFrame.new(-1.262238, 26.687265, 0.540955, -0.141421, 0.487417, 0.861641, 0, 0.870389, -0.492366, -0.98995, -0.069631, -0.123092), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 42
		{ n = "Leaflet", s = "Block", z = Vector3.new(1.442555, 0.540958, 3.200321), cf = CFrame.new(1.262238, 26.687265, 0.540955, -0.141421, -0.487417, -0.861641, 0, 0.870389, -0.492366, 0.98995, -0.069631, -0.123092), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 43
		{ n = "Canopy", s = "Block", z = Vector3.new(2.88511, 1.081916, 2.88511), cf = CFrame.new(0, 30.654293, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 44
		{ n = "Blade", s = "Block", z = Vector3.new(7.212775, 0.901597, 10.509967), cf = CFrame.new(2.975266, 29.392057, -5.15332, 0.866025, 0.125481, -0.483998, 0, 0.967997, 0.250962, 0.5, -0.21734, 0.83831), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 45
		{ n = "Vein", s = "Block", z = Vector3.new(0.432766, 0.216383, 8.047337), cf = CFrame.new(3.04541, 29.933161, -5.274811, 0.866025, 0.125481, -0.483998, 0, 0.967997, 0.250962, 0.5, -0.21734, 0.83831), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 46
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(1.622874, 1.622874, 1.622874), cf = CFrame.new(5.589897, 27.228222, -9.682007, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 0 } }, -- 47
		{ n = "Blade", s = "Block", z = Vector3.new(7.212775, 0.901597, 10.509967), cf = CFrame.new(5.950539, 29.392059, 0, 0, 0.250962, -0.967997, 0, 0.967997, 0.250962, 1, 0, 0), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 48
		{ n = "Vein", s = "Block", z = Vector3.new(0.432766, 0.216383, 8.047337), cf = CFrame.new(6.090828, 29.933159, 0, 0, 0.250962, -0.967997, 0, 0.967997, 0.250962, 1, 0, 0), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 49
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(1.622874, 1.622874, 1.622874), cf = CFrame.new(11.179802, 27.22822, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 0.9 } }, -- 50
		{ n = "Blade", s = "Block", z = Vector3.new(7.212775, 0.901597, 10.509967), cf = CFrame.new(2.975266, 29.392057, 5.15332, -0.866025, 0.125481, -0.483998, 0, 0.967997, 0.250962, 0.5, 0.21734, -0.83831), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 51
		{ n = "Vein", s = "Block", z = Vector3.new(0.432766, 0.216383, 8.047337), cf = CFrame.new(3.04541, 29.933161, 5.274811, -0.866025, 0.125481, -0.483998, 0, 0.967997, 0.250962, 0.5, 0.21734, -0.83831), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 52
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(1.622874, 1.622874, 1.622874), cf = CFrame.new(5.589897, 27.228222, 9.682007, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 1.8 } }, -- 53
		{ n = "Blade", s = "Block", z = Vector3.new(7.212775, 0.901597, 10.509967), cf = CFrame.new(-2.975266, 29.392057, 5.15332, -0.866025, -0.125481, 0.483998, 0, 0.967997, 0.250962, -0.5, 0.21734, -0.83831), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 54
		{ n = "Vein", s = "Block", z = Vector3.new(0.432766, 0.216383, 8.047337), cf = CFrame.new(-3.04541, 29.933161, 5.274811, -0.866025, -0.125481, 0.483998, 0, 0.967997, 0.250962, -0.5, 0.21734, -0.83831), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 55
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(1.622874, 1.622874, 1.622874), cf = CFrame.new(-5.589897, 27.228222, 9.682007, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 2.7 } }, -- 56
		{ n = "Blade", s = "Block", z = Vector3.new(7.212775, 0.901597, 10.509967), cf = CFrame.new(-5.950539, 29.392059, 0, 0, -0.250962, 0.967997, 0, 0.967997, 0.250962, -1, 0, 0), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 57
		{ n = "Vein", s = "Block", z = Vector3.new(0.432766, 0.216383, 8.047337), cf = CFrame.new(-6.090828, 29.933159, 0, 0, -0.250962, 0.967997, 0, 0.967997, 0.250962, -1, 0, 0), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 58
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(1.622874, 1.622874, 1.622874), cf = CFrame.new(-11.179802, 27.22822, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 3.6 } }, -- 59
		{ n = "Blade", s = "Block", z = Vector3.new(7.212775, 0.901597, 10.509967), cf = CFrame.new(-2.975266, 29.392057, -5.15332, 0.866025, -0.125481, 0.483998, 0, 0.967997, 0.250962, -0.5, -0.21734, 0.83831), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 60
		{ n = "Vein", s = "Block", z = Vector3.new(0.432766, 0.216383, 8.047337), cf = CFrame.new(-3.04541, 29.933161, -5.274811, 0.866025, -0.125481, 0.483998, 0, 0.967997, 0.250962, -0.5, -0.21734, 0.83831), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 61
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(1.622874, 1.622874, 1.622874), cf = CFrame.new(-5.589897, 27.228222, -9.682007, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 4.5 } }, -- 62
		{ n = "CloudHub", s = "Block", z = Vector3.new(0.721277, 0.721277, 0.721277), cf = CFrame.new(0, 43.997929, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.337255, 0.643137, 0.901961), m = Enum.Material.Plastic, t = 1, cs = false }, -- 63
		{ n = "Cloud", s = "Block", z = Vector3.new(9.376606, 3.245748, 5.770219), cf = CFrame.new(0, 43.997929, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.94902, 0.964706, 0.988235), m = Enum.Material.Plastic }, -- 64
		{ n = "Cloud", s = "Block", z = Vector3.new(5.048942, 3.606387, 4.327664), cf = CFrame.new(-2.885109, 46.161758, 0.360626, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.94902, 0.964706, 0.988235), m = Enum.Material.Plastic }, -- 65
		{ n = "Cloud", s = "Block", z = Vector3.new(4.327664, 3.245748, 3.967026), cf = CFrame.new(2.524467, 46.522396, -0.360626, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.94902, 0.964706, 0.988235), m = Enum.Material.Plastic }, -- 66
		{ n = "Cloud", s = "Block", z = Vector3.new(2.88511, 2.163832, 2.88511), cf = CFrame.new(5.409584, 44.719204, 0.721283, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.94902, 0.964706, 0.988235), m = Enum.Material.Plastic }, -- 67
		{ n = "CloudBase", s = "Block", z = Vector3.new(6.491497, 1.803194, 4.327664), cf = CFrame.new(0.721275, 42.194733, 0.721283, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.776471, 0.823529, 0.894118), m = Enum.Material.Plastic }, -- 68
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 5.409581, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -2.163832, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FootR", h = 1, a = 1, b = 25, c0 = CFrame.new(-3.606387, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.081916, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FootL", h = 1, a = 1, b = 30, c0 = CFrame.new(3.606387, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.081916, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Cloud", h = 1, a = 1, b = 63, c0 = CFrame.new(0, 42.916012, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 3, c0 = CFrame.new(0, -4.327664, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 3.967026, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 5, c0 = CFrame.new(0, 7.393094, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 6, c0 = CFrame.new(0, 10.458522, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 7, c0 = CFrame.new(0, 13.163313, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 8, c0 = CFrame.new(0, -1.803194, -7.663574, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 9, c0 = CFrame.new(0, -1.803194, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 10, c0 = CFrame.new(3.245748, 7.393094, -5.409581, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 11, c0 = CFrame.new(1.803194, 10.458522, -3.606387, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 12, c0 = CFrame.new(-7.573412, 0.360639, 2.524471, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 13, c0 = CFrame.new(-6.852135, 3.967026, -1.081916, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 14, c0 = CFrame.new(7.573412, 0.360639, 2.524471, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 15, c0 = CFrame.new(6.852135, 3.967026, -1.081916, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 16, c0 = CFrame.new(-2.812982, 3.786706, -6.852135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 17, c0 = CFrame.new(-2.199896, 4.688303, -7.302935, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 18, c0 = CFrame.new(-2.812982, 6.130858, -6.671817, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 19, c0 = CFrame.new(-5.229261, 2.524471, -6.671817, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 20, c0 = CFrame.new(2.812982, 3.786706, -6.852135, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 21, c0 = CFrame.new(3.426068, 4.688303, -7.302935, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 22, c0 = CFrame.new(2.812982, 6.130858, -6.671817, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 23, c0 = CFrame.new(5.229261, 2.524471, -6.671817, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 24, c0 = CFrame.new(0, 2.344152, -6.671817, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ArmR", h = 2, a = 2, b = 28, c0 = CFrame.new(-7.212775, 0.721277, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.000001, 2.378575, 0.447214, 0, -0.894427, -0.474644, 0.84758, -0.237322, 0.758098, 0.530669, 0.379049) },
		{ k = "Motor6D", n = "ArmL", h = 2, a = 2, b = 33, c0 = CFrame.new(7.212775, 0.721277, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.000001, 2.378575, 0.447214, 0, 0.894427, 0.474644, 0.84758, -0.237322, -0.758098, 0.530669, 0.379049) },
		{ k = "Motor6D", n = "BackLeaf", h = 2, a = 2, b = 35, c0 = CFrame.new(0, 7.934052, 4.327664, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.000001, 3.324924, -1, 0, 0, 0, 0.759257, -0.650791, 0, -0.650791, -0.759257) },
		{ k = "Motor6D", n = "TailDrip", h = 2, a = 2, b = 37, c0 = CFrame.new(0, -0.721277, 7.393094, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 2.52447, -0.829469, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Umbrella", h = 2, a = 2, b = 39, c0 = CFrame.new(0, 14.42555, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.838903, -1, 0, 0, 0, 0.196116, -0.980581, 0, -0.980581, -0.196116) },
		{ k = "Weld", n = "Hold", h = 25, a = 25, b = 26, c0 = CFrame.new(-1.081916, -0.540958, -3.065429, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 25, a = 25, b = 27, c0 = CFrame.new(1.081916, -0.540958, -3.065429, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 28, a = 28, b = 29, c0 = CFrame.new(0, -0.061134, -3.130424, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 30, a = 30, b = 31, c0 = CFrame.new(-1.081916, -0.540958, -3.065429, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 30, a = 30, b = 32, c0 = CFrame.new(1.081916, -0.540958, -3.065429, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 33, a = 33, b = 34, c0 = CFrame.new(0, -0.061134, -3.130424, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 35, a = 35, b = 36, c0 = CFrame.new(0, -0.048896, -4.351737, 1, 0, 0, 0, 0.999738, 0.022894, 0, -0.022894, 0.999738), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 37, a = 37, b = 38, c0 = CFrame.new(0, 1.550746, -0.216383, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 39, a = 39, b = 40, c0 = CFrame.new(0, 0.035364, 1.662085, -1, 0, 0, 0, 0.196116, -0.980581, 0, -0.980581, -0.196116), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 39, a = 39, b = 41, c0 = CFrame.new(0, 0.70727, -3.536354, -1, 0, 0, 0, -0.923077, -0.384615, 0, -0.384615, 0.923077), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 39, a = 39, b = 42, c0 = CFrame.new(1.262236, 0.176818, -1.803541, 0.141421, -0.487417, -0.861641, 0.970725, 0.238976, 0.02414, 0.194145, -0.839831, 0.506944), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 39, a = 39, b = 43, c0 = CFrame.new(-1.262236, 0.176818, -1.803541, 0.141421, 0.487417, 0.861641, -0.970725, 0.238976, 0.02414, -0.194145, -0.839831, 0.506944), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Canopy", h = 39, a = 39, b = 44, c0 = CFrame.new(0, 1.414541, -5.233803, -1, 0, 0, 0, 0.196116, -0.980581, 0, -0.980581, -0.196116), c1 = CFrame.new(0, -0.360641, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Blade1", h = 44, a = 44, b = 45, c0 = CFrame.new(0.540958, 0, -0.936967, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 5.029583, 0.866025, 0, 0.5, 0.125481, 0.967997, -0.21734, -0.483998, 0.250962, 0.83831) },
		{ k = "Motor6D", n = "Blade2", h = 44, a = 44, b = 48, c0 = CFrame.new(1.081916, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.000003, 5.029584, 0, 0, 1, 0.250962, 0.967997, 0, -0.967997, 0.250962, 0) },
		{ k = "Motor6D", n = "Blade3", h = 44, a = 44, b = 51, c0 = CFrame.new(0.540958, 0, 0.936967, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 5.029583, -0.866025, 0, 0.5, 0.125481, 0.967997, 0.21734, -0.483998, 0.250962, -0.83831) },
		{ k = "Motor6D", n = "Blade4", h = 44, a = 44, b = 54, c0 = CFrame.new(-0.540958, 0, 0.936967, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 5.029583, -0.866025, 0, -0.5, -0.125481, 0.967997, 0.21734, 0.483998, 0.250962, -0.83831) },
		{ k = "Motor6D", n = "Blade5", h = 44, a = 44, b = 57, c0 = CFrame.new(-1.081916, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.000003, 5.029584, 0, 0, -1, -0.250962, 0.967997, 0, 0.967997, 0.250962, 0) },
		{ k = "Motor6D", n = "Blade6", h = 44, a = 44, b = 60, c0 = CFrame.new(-0.540958, 0, -0.936967, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 5.029583, 0.866025, 0, -0.5, -0.125481, 0.967997, -0.21734, 0.483998, 0.250962, 0.83831) },
		{ k = "Weld", n = "Hold", h = 45, a = 45, b = 46, c0 = CFrame.new(0, 0.558992, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 45, a = 45, b = 47, c0 = CFrame.new(0, -0.782239, -5.604949, 0.866025, 0, 0.5, 0.125481, 0.967997, -0.21734, -0.483998, 0.250962, 0.83831), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 48, a = 48, b = 49, c0 = CFrame.new(0, 0.55899, -0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 48, a = 48, b = 50, c0 = CFrame.new(0, -0.782241, -5.60495, 0, 0, 1, 0.250962, 0.967997, 0, -0.967997, 0.250962, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 51, a = 51, b = 52, c0 = CFrame.new(0, 0.558992, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 51, a = 51, b = 53, c0 = CFrame.new(0, -0.782239, -5.604949, -0.866025, 0, 0.5, 0.125481, 0.967997, 0.21734, -0.483998, 0.250962, -0.83831), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 55, c0 = CFrame.new(0, 0.558992, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 56, c0 = CFrame.new(0, -0.782239, -5.604949, -0.866025, 0, -0.5, -0.125481, 0.967997, 0.21734, 0.483998, 0.250962, -0.83831), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 57, a = 57, b = 58, c0 = CFrame.new(0, 0.55899, -0.000001, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 57, a = 57, b = 59, c0 = CFrame.new(0, -0.782241, -5.60495, 0, 0, -1, -0.250962, 0.967997, 0, 0.967997, 0.250962, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 60, a = 60, b = 61, c0 = CFrame.new(0, 0.558992, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 60, a = 60, b = 62, c0 = CFrame.new(0, -0.782239, -5.604949, 0.866025, 0, -0.5, -0.125481, 0.967997, -0.21734, 0.483998, 0.250962, 0.83831), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 63, a = 63, b = 64, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 63, a = 63, b = 65, c0 = CFrame.new(-2.88511, 2.16383, 0.360639, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 63, a = 63, b = 66, c0 = CFrame.new(2.524471, 2.524468, -0.360639, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 63, a = 63, b = 67, c0 = CFrame.new(5.409581, 0.721277, 0.721277, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 63, a = 63, b = 68, c0 = CFrame.new(0.721277, -1.803198, 0.721277, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
		{ n = "Splash", p = 44, rate = 6, enabled = true, lifetime = NumberRange.new(0.3, 0.5), speed = NumberRange.new(12.02129, 30.053225), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.601065, 0), NumberSequenceKeypoint.new(1, 0, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.666667, 0.862745, 1)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)) }), lightEmission = 0.3, lightInfluence = 0.6, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(60, 60), acceleration = Vector3.new(0, -144.255493, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
		{ n = "Rain", p = 68, rate = 30, enabled = true, lifetime = NumberRange.new(0.1, 0.13), speed = NumberRange.new(84.149033, 96.170319), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.721277, 0), NumberSequenceKeypoint.new(1, 0.721277, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15, 0), NumberSequenceKeypoint.new(1, 0.5, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.666667, 0.862745, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.666667, 0.862745, 1)) }), lightEmission = 0.3, lightInfluence = 0.6, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(6, 6), acceleration = Vector3.new(0, -240.425797, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Bottom, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6, 0), NumberSequenceKeypoint.new(1, 1.6, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Trails = {
	},
	Billboards = {
	},
}

return spec
