--!strict
--==============================================================================
-- RAIN EVENT FORM: Pod 1's Drizzlet
--
-- Lifted part for part, joint for joint, light, emitter, trail and billboard
-- for each, from the owner's supplied Workspace model "Drizzlet POD1" (folder
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
	Source = "Drizzlet POD1", Kind = "plant", Yaw = 0,
	Size = Vector3.new(8.551043, 16.005001, 7.636187), Height = 16.005001, PartCount = 68,
	Base = 1,
	Attributes = { ProceduralIdle = true, Unit = 3 },
	Parts = {
		{ n = "Footing", s = "Block", z = Vector3.new(3.596629, 0.719326, 3.596629), cf = CFrame.new(0, 0.359663, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.337255, 0.643137, 0.901961), m = Enum.Material.Plastic, t = 1, cs = false }, -- 1
		{ n = "Body", s = "Block", z = Vector3.new(4.795506, 1.438652, 4.795506), cf = CFrame.new(0, 2.877303, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.337255, 0.643137, 0.901961), m = Enum.Material.Plastic }, -- 2
		{ n = "Drop", s = "Block", z = Vector3.new(4.07618, 1.438652, 4.07618), cf = CFrame.new(0, 1.438652, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.235294, 0.517647, 0.807843), m = Enum.Material.Plastic }, -- 3
		{ n = "Drop", s = "Block", z = Vector3.new(4.315955, 1.198877, 4.315955), cf = CFrame.new(0, 4.196067, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.337255, 0.643137, 0.901961), m = Enum.Material.Plastic }, -- 4
		{ n = "Drop", s = "Block", z = Vector3.new(3.356854, 1.078989, 3.356854), cf = CFrame.new(0, 5.335, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 5
		{ n = "Drop", s = "Block", z = Vector3.new(2.157978, 0.959101, 2.157978), cf = CFrame.new(0, 6.354045, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 6
		{ n = "Drop", s = "Block", z = Vector3.new(1.198877, 0.839213, 1.198877), cf = CFrame.new(0, 7.253201, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.768627, 0.901961, 0.988235), m = Enum.Material.Plastic }, -- 7
		{ n = "Belly", s = "Block", z = Vector3.new(2.637528, 1.918202, 0.299719), cf = CFrame.new(0, 2.277865, -2.547607, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.768627, 0.901961, 0.988235), m = Enum.Material.Plastic }, -- 8
		{ n = "Band", s = "Block", z = Vector3.new(4.915393, 0.239775, 4.915393), cf = CFrame.new(0, 2.277865, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 9
		{ n = "Highlight", s = "Block", z = Vector3.new(0.239775, 0.839213, 0.239775), cf = CFrame.new(1.078987, 5.335, -1.798309, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 1, 1), m = Enum.Material.SmoothPlastic, st = false }, -- 10
		{ n = "Highlight", s = "Block", z = Vector3.new(0.239775, 0.479551, 0.239775), cf = CFrame.new(0.599442, 6.354045, -1.198883, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 1, 1), m = Enum.Material.SmoothPlastic, st = false }, -- 11
		{ n = "Bump", s = "Block", z = Vector3.new(0.239775, 0.599438, 0.839213), cf = CFrame.new(-2.517639, 2.997191, 0.839203, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 12
		{ n = "Bump", s = "Block", z = Vector3.new(0.239775, 0.479551, 0.719326), cf = CFrame.new(-2.277863, 4.196067, -0.35965, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 13
		{ n = "Bump", s = "Block", z = Vector3.new(0.239775, 0.599438, 0.839213), cf = CFrame.new(2.517639, 2.997191, 0.839203, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 14
		{ n = "Bump", s = "Block", z = Vector3.new(0.239775, 0.479551, 0.719326), cf = CFrame.new(2.277863, 4.196067, -0.35965, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.54902, 0.784314, 0.964706), m = Enum.Material.Plastic }, -- 15
		{ n = "Eye", s = "Block", z = Vector3.new(1.019045, 1.198877, 0.239775), cf = CFrame.new(-0.935127, 4.136123, -2.277863, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.101961, 0.133333, 0.219608), m = Enum.Material.SmoothPlastic, st = false }, -- 16
		{ n = "Shine", s = "Block", z = Vector3.new(0.359663, 0.359663, 0.119888), cf = CFrame.new(-0.731316, 4.435843, -2.427734, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 1, 1), m = Enum.Material.SmoothPlastic, st = false }, -- 17
		{ n = "Brow", s = "Block", z = Vector3.new(0.539494, 0.179831, 0.119888), cf = CFrame.new(-0.935127, 4.915393, -2.217926, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c = Color3.new(0.101961, 0.133333, 0.219608), m = Enum.Material.SmoothPlastic, st = false }, -- 18
		{ n = "Blush", s = "Block", z = Vector3.new(0.479551, 0.263753, 0.119888), cf = CFrame.new(-1.738373, 3.716516, -2.217926, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 0.588235, 0.690196), m = Enum.Material.SmoothPlastic, st = false }, -- 19
		{ n = "Eye", s = "Block", z = Vector3.new(1.019045, 1.198877, 0.239775), cf = CFrame.new(0.935127, 4.136123, -2.277863, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.101961, 0.133333, 0.219608), m = Enum.Material.SmoothPlastic, st = false }, -- 20
		{ n = "Shine", s = "Block", z = Vector3.new(0.359663, 0.359663, 0.119888), cf = CFrame.new(1.138931, 4.435843, -2.427734, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 1, 1), m = Enum.Material.SmoothPlastic, st = false }, -- 21
		{ n = "Brow", s = "Block", z = Vector3.new(0.539494, 0.179831, 0.119888), cf = CFrame.new(0.935127, 4.915393, -2.217926, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c = Color3.new(0.101961, 0.133333, 0.219608), m = Enum.Material.SmoothPlastic, st = false }, -- 22
		{ n = "Blush", s = "Block", z = Vector3.new(0.479551, 0.263753, 0.119888), cf = CFrame.new(1.738373, 3.716516, -2.217926, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 0.588235, 0.690196), m = Enum.Material.SmoothPlastic, st = false }, -- 23
		{ n = "Mouth", s = "Block", z = Vector3.new(0.599438, 0.179831, 0.119888), cf = CFrame.new(0, 3.656573, -2.217926, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.101961, 0.133333, 0.219608), m = Enum.Material.SmoothPlastic, st = false }, -- 24
		{ n = "Foot", s = "Block", z = Vector3.new(1.438652, 0.719326, 1.798315), cf = CFrame.new(-1.198875, 0.359663, -0.35965, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 25
		{ n = "Toe", s = "Block", z = Vector3.new(0.419607, 0.359663, 0.359663), cf = CFrame.new(-1.55854, 0.179832, -1.378693, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 26
		{ n = "Toe", s = "Block", z = Vector3.new(0.419607, 0.359663, 0.359663), cf = CFrame.new(-0.839211, 0.179832, -1.378693, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 27
		{ n = "Arm", s = "Block", z = Vector3.new(0.839213, 0.239775, 1.701314), cf = CFrame.new(-2.997192, 2.697472, -0.299713, 0.447214, -0.474644, 0.758098, 0, 0.84758, 0.530669, -0.894427, -0.237322, 0.379049), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 28
		{ n = "ArmTip", s = "Block", z = Vector3.new(0.479551, 0.215798, 0.898612), cf = CFrame.new(-3.776459, 2.128006, -0.689362, 0.447213, -0.474644, 0.758098, 0, 0.84758, 0.530669, -0.894427, -0.237322, 0.379049), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 29
		{ n = "Foot", s = "Block", z = Vector3.new(1.438652, 0.719326, 1.798315), cf = CFrame.new(1.198875, 0.359663, -0.35965, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 30
		{ n = "Toe", s = "Block", z = Vector3.new(0.419607, 0.359663, 0.359663), cf = CFrame.new(0.839211, 0.179832, -1.378693, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 31
		{ n = "Toe", s = "Block", z = Vector3.new(0.419607, 0.359663, 0.359663), cf = CFrame.new(1.55854, 0.179832, -1.378693, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.196078, 0.431373, 0.705882), m = Enum.Material.Plastic }, -- 32
		{ n = "Arm", s = "Block", z = Vector3.new(0.839213, 0.239775, 1.701314), cf = CFrame.new(2.997192, 2.697472, -0.299713, 0.447214, 0.474644, -0.758098, 0, 0.84758, 0.530669, 0.894427, -0.237322, 0.379049), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 33
		{ n = "ArmTip", s = "Block", z = Vector3.new(0.479551, 0.215798, 0.898612), cf = CFrame.new(3.776459, 2.128006, -0.689362, 0.447213, 0.474644, -0.758098, 0, 0.84758, 0.530669, 0.894427, -0.237322, 0.379049), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 34
		{ n = "BackLeaf", s = "Block", z = Vector3.new(0.839213, 0.239775, 2.330506), cf = CFrame.new(0, 6.234157, 2.277863, -1, 0, 0, 0, 0.759257, -0.650791, 0, -0.650791, -0.759257), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 35
		{ n = "BackLeafTip", s = "Block", z = Vector3.new(0.479551, 0.215798, 0.959861), cf = CFrame.new(0, 7.163285, 3.38681, -1, 0, 0, 0, 0.773957, -0.633238, 0, -0.633238, -0.773957), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 36
		{ n = "BackDrip", s = "Ball", z = Vector3.new(0.77927, 0.77927, 0.77927), cf = CFrame.new(0, 1.798315, 2.733429, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false }, -- 37
		{ n = "BackDripNeck", s = "Block", z = Vector3.new(0.359663, 0.539494, 0.359663), cf = CFrame.new(0, 2.313831, 2.661499, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false }, -- 38
		{ n = "Stem", s = "Block", z = Vector3.new(0.419607, 0.419607, 1.432422), cf = CFrame.new(0, 8.272247, 0.119873, -1, 0, 0, 0, 0.196116, -0.980581, 0, -0.980581, -0.196116), c = Color3.new(0.27451, 0.54902, 0.27451), m = Enum.Material.Plastic }, -- 39
		{ n = "Collar", s = "Block", z = Vector3.new(0.839213, 0.239775, 0.839213), cf = CFrame.new(0, 7.732753, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 40
		{ n = "Stem", s = "Block", z = Vector3.new(0.359663, 0.359663, 1.40245), cf = CFrame.new(0, 9.471124, 0.119873, 1, 0, 0, 0, 0.196116, -0.980581, 0, 0.980581, 0.196116), c = Color3.new(0.27451, 0.54902, 0.27451), m = Enum.Material.Plastic }, -- 41
		{ n = "Leaflet", s = "Block", z = Vector3.new(0.479551, 0.179831, 1.063887), cf = CFrame.new(-0.419609, 8.871686, 0.17981, -0.141421, 0.487417, 0.861641, 0, 0.870389, -0.492366, -0.98995, -0.069631, -0.123092), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 42
		{ n = "Leaflet", s = "Block", z = Vector3.new(0.479551, 0.179831, 1.063887), cf = CFrame.new(0.419609, 8.871686, 0.17981, -0.141421, -0.487417, -0.861641, 0, 0.870389, -0.492366, 0.98995, -0.069631, -0.123092), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 43
		{ n = "Canopy", s = "Block", z = Vector3.new(0.959101, 0.359663, 0.959101), cf = CFrame.new(0, 10.190451, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 44
		{ n = "Blade", s = "Block", z = Vector3.new(2.397753, 0.299719, 3.493844), cf = CFrame.new(0.989075, 9.770844, -1.713135, 0.866025, 0.125481, -0.483998, 0, 0.967997, 0.250962, 0.5, -0.21734, 0.83831), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 45
		{ n = "Vein", s = "Block", z = Vector3.new(0.143865, 0.071933, 2.675188), cf = CFrame.new(1.01239, 9.950723, -1.75351, 0.866025, 0.125481, -0.483998, 0, 0.967997, 0.250962, 0.5, -0.21734, 0.83831), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 46
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(0.539494, 0.539494, 0.539494), cf = CFrame.new(1.858261, 9.051517, -3.218597, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 0 } }, -- 47
		{ n = "Blade", s = "Block", z = Vector3.new(2.397753, 0.299719, 3.493844), cf = CFrame.new(1.978149, 9.770844, 0, 0, 0.250962, -0.967997, 0, 0.967997, 0.250962, 1, 0, 0), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 48
		{ n = "Vein", s = "Block", z = Vector3.new(0.143865, 0.071933, 2.675188), cf = CFrame.new(2.024788, 9.950723, 0, 0, 0.250962, -0.967997, 0, 0.967997, 0.250962, 1, 0, 0), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 49
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(0.539494, 0.539494, 0.539494), cf = CFrame.new(3.716522, 9.051517, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 0.9 } }, -- 50
		{ n = "Blade", s = "Block", z = Vector3.new(2.397753, 0.299719, 3.493844), cf = CFrame.new(0.989075, 9.770844, 1.713135, -0.866025, 0.125481, -0.483998, 0, 0.967997, 0.250962, 0.5, 0.21734, -0.83831), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 51
		{ n = "Vein", s = "Block", z = Vector3.new(0.143865, 0.071933, 2.675188), cf = CFrame.new(1.01239, 9.950723, 1.75351, -0.866025, 0.125481, -0.483998, 0, 0.967997, 0.250962, 0.5, 0.21734, -0.83831), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 52
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(0.539494, 0.539494, 0.539494), cf = CFrame.new(1.858261, 9.051517, 3.218597, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 1.8 } }, -- 53
		{ n = "Blade", s = "Block", z = Vector3.new(2.397753, 0.299719, 3.493844), cf = CFrame.new(-0.989075, 9.770844, 1.713135, -0.866025, -0.125481, 0.483998, 0, 0.967997, 0.250962, -0.5, 0.21734, -0.83831), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 54
		{ n = "Vein", s = "Block", z = Vector3.new(0.143865, 0.071933, 2.675188), cf = CFrame.new(-1.01239, 9.950723, 1.75351, -0.866025, -0.125481, 0.483998, 0, 0.967997, 0.250962, -0.5, 0.21734, -0.83831), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 55
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(0.539494, 0.539494, 0.539494), cf = CFrame.new(-1.858261, 9.051517, 3.218597, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 2.7 } }, -- 56
		{ n = "Blade", s = "Block", z = Vector3.new(2.397753, 0.299719, 3.493844), cf = CFrame.new(-1.978149, 9.770844, 0, 0, -0.250962, 0.967997, 0, 0.967997, 0.250962, -1, 0, 0), c = Color3.new(0.329412, 0.690196, 0.360784), m = Enum.Material.Plastic }, -- 57
		{ n = "Vein", s = "Block", z = Vector3.new(0.143865, 0.071933, 2.675188), cf = CFrame.new(-2.024788, 9.950723, 0, 0, -0.250962, 0.967997, 0, 0.967997, 0.250962, -1, 0, 0), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 58
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(0.539494, 0.539494, 0.539494), cf = CFrame.new(-3.716522, 9.051517, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 3.6 } }, -- 59
		{ n = "Blade", s = "Block", z = Vector3.new(2.397753, 0.299719, 3.493844), cf = CFrame.new(-0.989075, 9.770844, -1.713135, 0.866025, -0.125481, 0.483998, 0, 0.967997, 0.250962, -0.5, -0.21734, 0.83831), c = Color3.new(0.462745, 0.784314, 0.407843), m = Enum.Material.Plastic }, -- 60
		{ n = "Vein", s = "Block", z = Vector3.new(0.143865, 0.071933, 2.675188), cf = CFrame.new(-1.01239, 9.950723, -1.75351, 0.866025, -0.125481, 0.483998, 0, 0.967997, 0.250962, -0.5, -0.21734, 0.83831), c = Color3.new(0.203922, 0.501961, 0.258824), m = Enum.Material.SmoothPlastic, st = false }, -- 61
		{ n = "LeafDrop", s = "Ball", z = Vector3.new(0.539494, 0.539494, 0.539494), cf = CFrame.new(-1.858261, 9.051517, -3.218597, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.666667, 0.862745, 1), m = Enum.Material.Glass, t = 0.3, st = false, cs = false, a = { BaseSize = Vector3.new(0.135, 0.135, 0.135), Phase = 4.5 } }, -- 62
		{ n = "CloudHub", s = "Block", z = Vector3.new(0.239775, 0.239775, 0.239775), cf = CFrame.new(0, 14.626294, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.337255, 0.643137, 0.901961), m = Enum.Material.Plastic, t = 1, cs = false }, -- 63
		{ n = "Cloud", s = "Block", z = Vector3.new(3.117079, 1.078989, 1.918202), cf = CFrame.new(0, 14.626294, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.94902, 0.964706, 0.988235), m = Enum.Material.Plastic }, -- 64
		{ n = "Cloud", s = "Block", z = Vector3.new(1.678427, 1.198877, 1.438652), cf = CFrame.new(-0.959099, 15.34562, 0.119873, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.94902, 0.964706, 0.988235), m = Enum.Material.Plastic }, -- 65
		{ n = "Cloud", s = "Block", z = Vector3.new(1.438652, 1.078989, 1.318764), cf = CFrame.new(0.839211, 15.465507, -0.119873, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.94902, 0.964706, 0.988235), m = Enum.Material.Plastic }, -- 66
		{ n = "Cloud", s = "Block", z = Vector3.new(0.959101, 0.719326, 0.959101), cf = CFrame.new(1.798317, 14.866069, 0.239777, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.94902, 0.964706, 0.988235), m = Enum.Material.Plastic }, -- 67
		{ n = "CloudBase", s = "Block", z = Vector3.new(2.157978, 0.599438, 1.438652), cf = CFrame.new(0.239777, 14.026855, 0.239777, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.776471, 0.823529, 0.894118), m = Enum.Material.Plastic }, -- 68
	},
	Joints = {
		{ k = "Motor6D", n = "Root", h = 1, a = 1, b = 2, c0 = CFrame.new(0, 1.798315, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.719326, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FootR", h = 1, a = 1, b = 25, c0 = CFrame.new(-1.198877, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.359663, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "FootL", h = 1, a = 1, b = 30, c0 = CFrame.new(1.198877, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.359663, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Cloud", h = 1, a = 1, b = 63, c0 = CFrame.new(0, 14.26663, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 3, c0 = CFrame.new(0, -1.438652, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 4, c0 = CFrame.new(0, 1.318764, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 5, c0 = CFrame.new(0, 2.457697, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 6, c0 = CFrame.new(0, 3.476741, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 7, c0 = CFrame.new(0, 4.375899, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 8, c0 = CFrame.new(0, -0.599438, -2.547613, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 9, c0 = CFrame.new(0, -0.599438, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 10, c0 = CFrame.new(1.078989, 2.457697, -1.798315, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 11, c0 = CFrame.new(0.599438, 3.476741, -1.198877, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 12, c0 = CFrame.new(-2.51764, 0.119888, 0.839213, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 13, c0 = CFrame.new(-2.277865, 1.318764, -0.359663, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 14, c0 = CFrame.new(2.51764, 0.119888, 0.839213, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 15, c0 = CFrame.new(2.277865, 1.318764, -0.359663, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 16, c0 = CFrame.new(-0.935124, 1.25882, -2.277865, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 17, c0 = CFrame.new(-0.731315, 1.55854, -2.427725, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 18, c0 = CFrame.new(-0.935124, 2.03809, -2.217921, 0.978148, 0.207912, 0, -0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 19, c0 = CFrame.new(-1.738371, 0.839214, -2.217921, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 20, c0 = CFrame.new(0.935124, 1.25882, -2.277865, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 21, c0 = CFrame.new(1.138933, 1.55854, -2.427725, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 22, c0 = CFrame.new(0.935124, 2.03809, -2.217921, 0.978148, -0.207912, 0, 0.207912, 0.978148, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 23, c0 = CFrame.new(1.738371, 0.839214, -2.217921, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 2, a = 2, b = 24, c0 = CFrame.new(0, 0.77927, -2.217921, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "ArmR", h = 2, a = 2, b = 28, c0 = CFrame.new(-2.397753, 0.239775, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.790713, 0.447214, 0, -0.894427, -0.474644, 0.84758, -0.237322, 0.758098, 0.530669, 0.379049) },
		{ k = "Motor6D", n = "ArmL", h = 2, a = 2, b = 33, c0 = CFrame.new(2.397753, 0.239775, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.790713, 0.447214, 0, 0.894427, 0.474644, 0.84758, -0.237322, -0.758098, 0.530669, 0.379049) },
		{ k = "Motor6D", n = "BackLeaf", h = 2, a = 2, b = 35, c0 = CFrame.new(0, 2.637528, 1.438652, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.105309, -1, 0, 0, 0, 0.759257, -0.650791, 0, -0.650791, -0.759257) },
		{ k = "Motor6D", n = "TailDrip", h = 2, a = 2, b = 37, c0 = CFrame.new(0, -0.239775, 2.457697, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0.839213, -0.275742, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Umbrella", h = 2, a = 2, b = 39, c0 = CFrame.new(0, 4.795506, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0.611309, -1, 0, 0, 0, 0.196116, -0.980581, 0, -0.980581, -0.196116) },
		{ k = "Weld", n = "Hold", h = 25, a = 25, b = 26, c0 = CFrame.new(-0.359663, -0.179831, -1.019045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 25, a = 25, b = 27, c0 = CFrame.new(0.359663, -0.179831, -1.019045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 28, a = 28, b = 29, c0 = CFrame.new(0, -0.020323, -1.040651, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 30, a = 30, b = 31, c0 = CFrame.new(-0.359663, -0.179831, -1.019045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 30, a = 30, b = 32, c0 = CFrame.new(0.359663, -0.179831, -1.019045, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 33, a = 33, b = 34, c0 = CFrame.new(0, -0.020323, -1.040651, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 35, a = 35, b = 36, c0 = CFrame.new(0, -0.016255, -1.446654, 1, 0, 0, 0, 0.999738, 0.022894, 0, -0.022894, 0.999738), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 37, a = 37, b = 38, c0 = CFrame.new(0, 0.515517, -0.071933, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 39, a = 39, b = 40, c0 = CFrame.new(0, 0.011756, 0.552529, -1, 0, 0, 0, 0.196116, -0.980581, 0, -0.980581, -0.196116), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 39, a = 39, b = 41, c0 = CFrame.new(0, 0.235119, -1.175595, -1, 0, 0, 0, -0.923077, -0.384615, 0, -0.384615, 0.923077), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 39, a = 39, b = 42, c0 = CFrame.new(0.419607, 0.05878, -0.599554, 0.141421, -0.487417, -0.861641, 0.970725, 0.238976, 0.02414, 0.194145, -0.839831, 0.506944), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 39, a = 39, b = 43, c0 = CFrame.new(-0.419607, 0.05878, -0.599554, 0.141421, 0.487417, 0.861641, -0.970725, 0.238976, 0.02414, -0.194145, -0.839831, 0.506944), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Canopy", h = 39, a = 39, b = 44, c0 = CFrame.new(0, 0.470238, -1.739881, -1, 0, 0, 0, 0.196116, -0.980581, 0, -0.980581, -0.196116), c1 = CFrame.new(0, -0.119888, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Motor6D", n = "Blade1", h = 44, a = 44, b = 45, c0 = CFrame.new(0.179831, 0, -0.311477, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.671992, 0.866025, 0, 0.5, 0.125481, 0.967997, -0.21734, -0.483998, 0.250962, 0.83831) },
		{ k = "Motor6D", n = "Blade2", h = 44, a = 44, b = 48, c0 = CFrame.new(0.359663, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.000001, 1.671992, 0, 0, 1, 0.250962, 0.967997, 0, -0.967997, 0.250962, 0) },
		{ k = "Motor6D", n = "Blade3", h = 44, a = 44, b = 51, c0 = CFrame.new(0.179831, 0, 0.311477, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.671992, -0.866025, 0, 0.5, 0.125481, 0.967997, 0.21734, -0.483998, 0.250962, -0.83831) },
		{ k = "Motor6D", n = "Blade4", h = 44, a = 44, b = 54, c0 = CFrame.new(-0.179831, 0, 0.311477, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.671992, -0.866025, 0, -0.5, -0.125481, 0.967997, 0.21734, 0.483998, 0.250962, -0.83831) },
		{ k = "Motor6D", n = "Blade5", h = 44, a = 44, b = 57, c0 = CFrame.new(-0.359663, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, -0.000001, 1.671992, 0, 0, -1, -0.250962, 0.967997, 0, 0.967997, 0.250962, 0) },
		{ k = "Motor6D", n = "Blade6", h = 44, a = 44, b = 60, c0 = CFrame.new(-0.179831, 0, -0.311477, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 1.671992, 0.866025, 0, -0.5, -0.125481, 0.967997, -0.21734, 0.483998, 0.250962, 0.83831) },
		{ k = "Weld", n = "Hold", h = 45, a = 45, b = 46, c0 = CFrame.new(0, 0.185827, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 45, a = 45, b = 47, c0 = CFrame.new(0, -0.260041, -1.863261, 0.866025, 0, 0.5, 0.125481, 0.967997, -0.21734, -0.483998, 0.250962, 0.83831), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 48, a = 48, b = 49, c0 = CFrame.new(0, 0.185826, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 48, a = 48, b = 50, c0 = CFrame.new(0, -0.260042, -1.863262, 0, 0, 1, 0.250962, 0.967997, 0, -0.967997, 0.250962, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 51, a = 51, b = 52, c0 = CFrame.new(0, 0.185827, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 51, a = 51, b = 53, c0 = CFrame.new(0, -0.260041, -1.863261, -0.866025, 0, 0.5, 0.125481, 0.967997, 0.21734, -0.483998, 0.250962, -0.83831), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 55, c0 = CFrame.new(0, 0.185827, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 54, a = 54, b = 56, c0 = CFrame.new(0, -0.260041, -1.863261, -0.866025, 0, -0.5, -0.125481, 0.967997, 0.21734, 0.483998, 0.250962, -0.83831), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 57, a = 57, b = 58, c0 = CFrame.new(0, 0.185826, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 57, a = 57, b = 59, c0 = CFrame.new(0, -0.260042, -1.863262, 0, 0, -1, -0.250962, 0.967997, 0, 0.967997, 0.250962, 0), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 60, a = 60, b = 61, c0 = CFrame.new(0, 0.185827, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 60, a = 60, b = 62, c0 = CFrame.new(0, -0.260041, -1.863261, 0.866025, 0, -0.5, -0.125481, 0.967997, -0.21734, 0.483998, 0.250962, 0.83831), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 63, a = 63, b = 64, c0 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 63, a = 63, b = 65, c0 = CFrame.new(-0.959101, 0.719325, 0.119888, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 63, a = 63, b = 66, c0 = CFrame.new(0.839213, 0.839213, -0.119888, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 63, a = 63, b = 67, c0 = CFrame.new(1.798315, 0.239775, 0.239775, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
		{ k = "Weld", n = "Hold", h = 63, a = 63, b = 68, c0 = CFrame.new(0.239775, -0.59944, 0.239775, 1, 0, 0, 0, 1, 0, 0, 0, 1), c1 = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1) },
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
		{ n = "Splash", p = 44, rate = 6, enabled = true, lifetime = NumberRange.new(0.3, 0.5), speed = NumberRange.new(3.996255, 9.990637), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.199813, 0), NumberSequenceKeypoint.new(1, 0, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.666667, 0.862745, 1)), ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)) }), lightEmission = 0.3, lightInfluence = 0.6, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(60, 60), acceleration = Vector3.new(0, -47.955055, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
		{ n = "Rain", p = 68, rate = 30, enabled = true, lifetime = NumberRange.new(0.1, 0.13), speed = NumberRange.new(27.973783, 31.970037), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.239775, 0), NumberSequenceKeypoint.new(1, 0.239775, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15, 0), NumberSequenceKeypoint.new(1, 0.5, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.666667, 0.862745, 1)), ColorSequenceKeypoint.new(1, Color3.new(0.666667, 0.862745, 1)) }), lightEmission = 0.3, lightInfluence = 0.6, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(6, 6), acceleration = Vector3.new(0, -79.925095, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Bottom, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6, 0), NumberSequenceKeypoint.new(1, 1.6, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Trails = {
	},
	Billboards = {
	},
}

return spec
