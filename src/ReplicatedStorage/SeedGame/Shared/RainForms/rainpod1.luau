--!strict
--==============================================================================
-- RAIN EVENT FORM: Pod 1, the pod itself
--
-- Lifted part for part, joint for joint, light, emitter, trail and billboard
-- for each, from the owner's supplied Workspace model "pod1" (folder
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
	Source = "pod1", Kind = "pod", Yaw = 0,
	Size = Vector3.new(6.858567, 11.682843, 7.191297), Height = 11.682843, PartCount = 93,
	Base = 0,
	Attributes = {},
	Parts = {
		{ n = "Layer", s = "Block", z = Vector3.new(4.374433, 0.874887, 4.374433), cf = CFrame.new(0, 1.312328, 0.166351, 0.382683, 0, 0.923879, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.new(0.345098, 0.447059, 0.580392), m = Enum.Material.Plastic }, -- 1
		{ n = "CloudPuff", s = "Ball", z = Vector3.new(1.224841, 1.224841, 1.224841), cf = CFrame.new(-0.437439, 10.06119, 0.166351, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.909804, 0.933333, 0.964706), m = Enum.Material.SmoothPlastic, st = false }, -- 2
		{ n = "Bolt", s = "Block", z = Vector3.new(0.30621, 0.962375, 0.437443), cf = CFrame.new(0.218719, 4.899363, 2.75882, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.new(1, 0.92549, 0.470588), m = Enum.Material.Neon, st = false }, -- 3
		{ n = "Streak", s = "Block", z = Vector3.new(0.174977, 0.962375, 0.349955), cf = CFrame.new(-1.802216, 4.811874, 1.968567, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.new(0.803922, 0.894118, 0.960784), m = Enum.Material.Plastic }, -- 4
		{ n = "Raindrop", s = "Block", z = Vector3.new(0.262466, 0.437443, 0.262466), cf = CFrame.new(-0.174988, 8.398911, -1.233459, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.509804, 0.745098, 0.941176), m = Enum.Material.SmoothPlastic, st = false }, -- 5
		{ n = "WindowGlass", s = "Block", z = Vector3.new(1.137353, 1.224841, 0.174977), cf = CFrame.new(0, 2.187213, -3.333191, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 0.839216, 0.509804), m = Enum.Material.Neon, st = false }, -- 6
		{ n = "WindowCross", s = "Block", z = Vector3.new(0.109361, 1.224841, 0.218722), cf = CFrame.new(0, 2.187213, -3.420685, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.27451, 0.219608, 0.188235), m = Enum.Material.Plastic }, -- 7
		{ n = "Layer", s = "Block", z = Vector3.new(1.92475, 0.874887, 1.92475), cf = CFrame.new(0, 7.436534, 0.166351, 0.923879, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.new(0.784314, 0.847059, 0.909804), m = Enum.Material.Plastic }, -- 8
		{ n = "RainGem", s = "Block", z = Vector3.new(0.437443, 0.437443, 0.30621), cf = CFrame.new(-2.069977, 3.280821, 2.236328, 0.5, -0.5, -0.707107, 0.707107, 0.707107, 0, 0.5, -0.5, 0.707107), c = Color3.new(0.588235, 0.862745, 1), m = Enum.Material.Neon, st = false }, -- 9
		{ n = "WindowFrame", s = "Block", z = Vector3.new(1.487307, 0.218722, 0.30621), cf = CFrame.new(0, 1.465433, -3.398804, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.27451, 0.219608, 0.188235), m = Enum.Material.Plastic }, -- 10
		{ n = "Shutter", s = "Block", z = Vector3.new(0.437443, 1.487307, 0.218722), cf = CFrame.new(1.13736, 2.187216, -3.355072, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.27451, 0.431373, 0.627451), m = Enum.Material.Plastic }, -- 11
		{ n = "Streak", s = "Block", z = Vector3.new(0.174977, 0.962375, 0.349955), cf = CFrame.new(2.832703, 3.936987, 0.166351, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.new(0.803922, 0.894118, 0.960784), m = Enum.Material.Plastic }, -- 12
		{ n = "RainGem", s = "Block", z = Vector3.new(0.437443, 0.437443, 0.30621), cf = CFrame.new(-2.069977, 2.62466, -1.903595, -0.5, 0.5, -0.707107, 0.707107, 0.707107, 0, 0.5, -0.5, -0.707107), c = Color3.new(0.588235, 0.862745, 1), m = Enum.Material.Neon, st = false }, -- 13
		{ n = "MistTile", s = "Block", z = Vector3.new(0.699909, 0.218722, 0.30621), cf = CFrame.new(1.649414, 6.561647, 0.166351, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.Plastic }, -- 14
		{ n = "RaindropTip", s = "Block", z = Vector3.new(0.196849, 0.196849, 0.196849), cf = CFrame.new(0.087494, 8.092699, 1.566162, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.new(0.509804, 0.745098, 0.941176), m = Enum.Material.SmoothPlastic, st = false }, -- 15
		{ n = "Streak", s = "Block", z = Vector3.new(0.174977, 0.962375, 0.349955), cf = CFrame.new(2.003021, 2.187214, -1.83667, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.new(0.803922, 0.894118, 0.960784), m = Enum.Material.Plastic }, -- 16
		{ n = "MistTile", s = "Block", z = Vector3.new(0.699909, 0.218722, 0.30621), cf = CFrame.new(0, 6.561647, 1.815765, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.Plastic }, -- 17
		{ n = "Layer", s = "Block", z = Vector3.new(3.762012, 0.874887, 3.762012), cf = CFrame.new(0, 5.686761, 0.166351, 0.923879, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.new(0.666667, 0.760784, 0.847059), m = Enum.Material.Plastic }, -- 18
		{ n = "Layer", s = "Block", z = Vector3.new(5.24932, 0.874887, 5.24932), cf = CFrame.new(0, 3.062102, 0.166351, 0.923879, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.new(0.345098, 0.447059, 0.580392), m = Enum.Material.Plastic }, -- 19
		{ n = "RaindropTip", s = "Block", z = Vector3.new(0.196849, 0.196849, 0.196849), cf = CFrame.new(-1.487305, 8.092697, 0.341339, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.new(0.509804, 0.745098, 0.941176), m = Enum.Material.SmoothPlastic, st = false }, -- 20
		{ n = "Layer", s = "Block", z = Vector3.new(3.762012, 0.874887, 3.762012), cf = CFrame.new(0, 5.686761, 0.166351, 0.382683, 0, 0.923879, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.new(0.666667, 0.760784, 0.847059), m = Enum.Material.Plastic }, -- 21
		{ n = "RainCrystalTip", s = "Block", z = Vector3.new(0.437443, 0.437443, 0.437443), cf = CFrame.new(0, 11.373524, 0.210083, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.new(0.588235, 0.862745, 1), m = Enum.Material.Neon, st = false }, -- 22
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.892384, 0.240594, 0.174977), cf = CFrame.new(-1.248108, 3.730101, -3.333191, -0.309017, 0.951056, 0, -0.951056, -0.309017, 0, 0, 0, 1), c = Color3.new(0.980392, 0.839216, 0.352941), m = Enum.Material.Plastic }, -- 23
		{ n = "DripTile", s = "Block", z = Vector3.new(0.874887, 0.262466, 0.349955), cf = CFrame.new(0, 1.312329, 2.620392, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.227451, 0.290196, 0.392157), m = Enum.Material.Plastic }, -- 24
		{ n = "Bolt", s = "Block", z = Vector3.new(0.30621, 0.962375, 0.437443), cf = CFrame.new(-0.131226, 3.849499, 2.75882, 0.906308, 0.422618, 0, -0.422618, 0.906308, 0, 0, 0, 1), c = Color3.new(1, 0.92549, 0.470588), m = Enum.Material.Neon, st = false }, -- 25
		{ n = "CloudPuff", s = "Ball", z = Vector3.new(0.962375, 0.962375, 0.962375), cf = CFrame.new(0.743652, 9.273796, 1.041229, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.SmoothPlastic, st = false }, -- 26
		{ n = "Layer", s = "Block", z = Vector3.new(5.074342, 0.874887, 5.074342), cf = CFrame.new(0, 2.187213, 0.166351, 0.923879, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.new(0.431373, 0.54902, 0.690196), m = Enum.Material.Plastic }, -- 27
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.892384, 0.240594, 0.174977), cf = CFrame.new(-0.771362, 4.386266, -3.333191, -0.809017, 0.587785, 0, -0.587785, -0.809017, 0, 0, 0, 1), c = Color3.new(0.980392, 0.839216, 0.352941), m = Enum.Material.Plastic }, -- 28
		{ n = "Rainbow", s = "Block", z = Vector3.new(1.070861, 0.240594, 0.174977), cf = CFrame.new(1.497711, 3.811206, -3.333191, -0.309017, -0.951056, 0, 0.951056, -0.309017, 0, 0, 0, 1), c = Color3.new(0.909804, 0.329412, 0.329412), m = Enum.Material.Plastic }, -- 29
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.713907, 0.240594, 0.174977), cf = CFrame.new(0.998474, 3.648994, -3.333191, -0.309017, -0.951056, 0, 0.951056, -0.309017, 0, 0, 0, 1), c = Color3.new(0.352941, 0.588235, 0.901961), m = Enum.Material.Plastic }, -- 30
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.892384, 0.240594, 0.174977), cf = CFrame.new(1.248108, 3.730101, -3.333191, -0.309017, -0.951056, 0, 0.951056, -0.309017, 0, 0, 0, 1), c = Color3.new(0.980392, 0.839216, 0.352941), m = Enum.Material.Plastic }, -- 31
		{ n = "CloudPuff", s = "Ball", z = Vector3.new(1.399819, 1.399819, 1.399819), cf = CFrame.new(-1.13736, 9.186306, 0.341339, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.SmoothPlastic, st = false }, -- 32
		{ n = "RaindropTip", s = "Block", z = Vector3.new(0.196849, 0.196849, 0.196849), cf = CFrame.new(-0.174988, 8.092699, -1.233459, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.new(0.509804, 0.745098, 0.941176), m = Enum.Material.SmoothPlastic, st = false }, -- 33
		{ n = "Rainbow", s = "Block", z = Vector3.new(1.070861, 0.240594, 0.174977), cf = CFrame.new(0.925629, 4.598605, -3.333191, -0.809017, -0.587785, 0, 0.587785, -0.809017, 0, 0, 0, 1), c = Color3.new(0.909804, 0.329412, 0.329412), m = Enum.Material.Plastic }, -- 34
		{ n = "CloudPuff", s = "Ball", z = Vector3.new(1.487307, 1.487307, 1.487307), cf = CFrame.new(1.181091, 9.230051, -0.008636, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.SmoothPlastic, st = false }, -- 35
		{ n = "Streak", s = "Block", z = Vector3.new(0.174977, 0.962375, 0.349955), cf = CFrame.new(1.501007, 5.686761, 1.667358, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.new(0.803922, 0.894118, 0.960784), m = Enum.Material.Plastic }, -- 36
		{ n = "DripTile", s = "Block", z = Vector3.new(0.874887, 0.262466, 0.349955), cf = CFrame.new(-1.735291, 1.312328, 1.901642, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.new(0.227451, 0.290196, 0.392157), m = Enum.Material.Plastic }, -- 37
		{ n = "Layer", s = "Block", z = Vector3.new(2.974614, 0.874887, 2.974614), cf = CFrame.new(0, 0.437443, 0.166351, 0.382683, 0, 0.923879, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.new(0.258824, 0.345098, 0.470588), m = Enum.Material.Plastic }, -- 38
		{ n = "Streak", s = "Block", z = Vector3.new(0.174977, 0.962375, 0.349955), cf = CFrame.new(-2.003021, 1.968492, 2.169373, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.new(0.803922, 0.894118, 0.960784), m = Enum.Material.Plastic }, -- 39
		{ n = "DripTile", s = "Block", z = Vector3.new(0.874887, 0.262466, 0.349955), cf = CFrame.new(1.735291, 1.312329, 1.901642, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.new(0.227451, 0.290196, 0.392157), m = Enum.Material.Plastic }, -- 40
		{ n = "RaindropTip", s = "Block", z = Vector3.new(0.196849, 0.196849, 0.196849), cf = CFrame.new(1.487305, 8.092699, -0.008636, 0.707107, -0.707107, 0, 0.707107, 0.707107, 0, 0, 0, 1), c = Color3.new(0.509804, 0.745098, 0.941176), m = Enum.Material.SmoothPlastic, st = false }, -- 41
		{ n = "RainCrystal", s = "Block", z = Vector3.new(0.524932, 0.612421, 0.524932), cf = CFrame.new(0, 10.936081, 0.210114, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.588235, 0.862745, 1), m = Enum.Material.Neon, st = false }, -- 42
		{ n = "Rainbow", s = "Block", z = Vector3.new(1.070861, 0.240594, 0.174977), cf = CFrame.new(-1.497711, 3.811207, -3.333191, -0.309017, 0.951056, 0, -0.951056, -0.309017, 0, 0, 0, 1), c = Color3.new(0.909804, 0.329412, 0.329412), m = Enum.Material.Plastic }, -- 43
		{ n = "Streak", s = "Block", z = Vector3.new(0.174977, 0.962375, 0.349955), cf = CFrame.new(-1.802216, 5.030597, -1.635864, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.new(0.803922, 0.894118, 0.960784), m = Enum.Material.Plastic }, -- 44
		{ n = "WindowFrame", s = "Block", z = Vector3.new(1.487307, 0.218722, 0.30621), cf = CFrame.new(0, 2.908996, -3.398804, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.27451, 0.219608, 0.188235), m = Enum.Material.Plastic }, -- 45
		{ n = "DripTile", s = "Block", z = Vector3.new(0.874887, 0.262466, 0.349955), cf = CFrame.new(-2.454071, 1.312328, 0.166351, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.new(0.227451, 0.290196, 0.392157), m = Enum.Material.Plastic }, -- 46
		{ n = "FrontPlate", s = "Block", z = Vector3.new(3.23708, 4.199455, 0.874887), cf = CFrame.new(0, 2.974614, -2.808258, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.227451, 0.290196, 0.392157), m = Enum.Material.Plastic }, -- 47
		{ n = "Raindrop", s = "Block", z = Vector3.new(0.262466, 0.437443, 0.262466), cf = CFrame.new(-1.487305, 8.398909, 0.341339, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.509804, 0.745098, 0.941176), m = Enum.Material.SmoothPlastic, st = false }, -- 48
		{ n = "CloudPuff", s = "Ball", z = Vector3.new(1.837262, 1.837262, 1.837262), cf = CFrame.new(0, 9.361284, 0.166351, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.909804, 0.933333, 0.964706), m = Enum.Material.SmoothPlastic, st = false }, -- 49
		{ n = "RainGem", s = "Block", z = Vector3.new(0.437443, 0.437443, 0.30621), cf = CFrame.new(1.501007, 5.468041, -1.334656, -0.5, 0.5, 0.707107, 0.707107, 0.707107, 0, -0.5, 0.5, -0.707107), c = Color3.new(0.588235, 0.862745, 1), m = Enum.Material.Neon, st = false }, -- 50
		{ n = "CloudPuff", s = "Ball", z = Vector3.new(1.137353, 1.137353, 1.137353), cf = CFrame.new(0.524933, 9.973705, 0.253845, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.SmoothPlastic, st = false }, -- 51
		{ n = "Layer", s = "Block", z = Vector3.new(4.54941, 0.874887, 4.54941), cf = CFrame.new(0, 4.811876, 0.166351, 0.382683, 0, 0.923879, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.new(0.54902, 0.666667, 0.784314), m = Enum.Material.Plastic }, -- 52
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.892384, 0.240594, 0.174977), cf = CFrame.new(0.771362, 4.386266, -3.333191, -0.809017, -0.587785, 0, 0.587785, -0.809017, 0, 0, 0, 1), c = Color3.new(0.980392, 0.839216, 0.352941), m = Enum.Material.Plastic }, -- 53
		{ n = "CloudPuff", s = "Ball", z = Vector3.new(1.224841, 1.224841, 1.224841), cf = CFrame.new(0.087494, 9.186308, 1.303711, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.909804, 0.933333, 0.964706), m = Enum.Material.SmoothPlastic, st = false }, -- 54
		{ n = "Streak", s = "Block", z = Vector3.new(0.174977, 0.962375, 0.349955), cf = CFrame.new(2.003021, 1.968493, 2.169373, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.new(0.803922, 0.894118, 0.960784), m = Enum.Material.Plastic }, -- 55
		{ n = "RainGem", s = "Block", z = Vector3.new(0.437443, 0.437443, 0.30621), cf = CFrame.new(2.003021, 3.499545, 2.169373, 0.5, -0.5, 0.707107, 0.707107, 0.707107, 0, -0.5, 0.5, 0.707107), c = Color3.new(0.588235, 0.862745, 1), m = Enum.Material.Neon, st = false }, -- 56
		{ n = "MistTile", s = "Block", z = Vector3.new(0.699909, 0.218722, 0.30621), cf = CFrame.new(1.166321, 6.56165, -0.999969, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.Plastic }, -- 57
		{ n = "Layer", s = "Block", z = Vector3.new(5.24932, 0.874887, 5.24932), cf = CFrame.new(0, 3.062102, 0.166351, 0.382683, 0, 0.923879, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.new(0.345098, 0.447059, 0.580392), m = Enum.Material.Plastic }, -- 58
		{ n = "Raindrop", s = "Block", z = Vector3.new(0.262466, 0.437443, 0.262466), cf = CFrame.new(0.087494, 8.398909, 1.566162, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.509804, 0.745098, 0.941176), m = Enum.Material.SmoothPlastic, st = false }, -- 59
		{ n = "MistTile", s = "Block", z = Vector3.new(0.699909, 0.218722, 0.30621), cf = CFrame.new(-1.166321, 6.561647, -0.999969, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.Plastic }, -- 60
		{ n = "DripTile", s = "Block", z = Vector3.new(0.874887, 0.262466, 0.349955), cf = CFrame.new(1.735291, 1.312329, -1.568939, -0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, -0.707107), c = Color3.new(0.227451, 0.290196, 0.392157), m = Enum.Material.Plastic }, -- 61
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.713907, 0.240594, 0.174977), cf = CFrame.new(0.617096, 4.173926, -3.333191, -0.809017, -0.587785, 0, 0.587785, -0.809017, 0, 0, 0, 1), c = Color3.new(0.352941, 0.588235, 0.901961), m = Enum.Material.Plastic }, -- 62
		{ n = "MistTile", s = "Block", z = Vector3.new(0.699909, 0.218722, 0.30621), cf = CFrame.new(1.166321, 6.561647, 1.332672, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.Plastic }, -- 63
		{ n = "Rainbow", s = "Block", z = Vector3.new(1.070861, 0.240594, 0.174977), cf = CFrame.new(0, 4.899363, -3.333191, -1, 0, 0, 0, -1, 0, 0, 0, 1), c = Color3.new(0.909804, 0.329412, 0.329412), m = Enum.Material.Plastic }, -- 64
		{ n = "WindowSill", s = "Block", z = Vector3.new(1.92475, 0.218722, 0.349955), cf = CFrame.new(0, 1.3342, -3.420685, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.27451, 0.219608, 0.188235), m = Enum.Material.Plastic }, -- 65
		{ n = "Layer", s = "Block", z = Vector3.new(1.049864, 0.874887, 1.049864), cf = CFrame.new(0, 8.311419, 0.166351, 0.923879, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.new(0.784314, 0.847059, 0.909804), m = Enum.Material.Plastic }, -- 66
		{ n = "Shutter", s = "Block", z = Vector3.new(0.437443, 1.487307, 0.218722), cf = CFrame.new(-1.13736, 2.187214, -3.355072, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.27451, 0.431373, 0.627451), m = Enum.Material.Plastic }, -- 67
		{ n = "WindowFrame", s = "Block", z = Vector3.new(0.218722, 1.224841, 0.30621), cf = CFrame.new(-0.67804, 2.187214, -3.398804, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.27451, 0.219608, 0.188235), m = Enum.Material.Plastic }, -- 68
		{ n = "MistTile", s = "Block", z = Vector3.new(0.699909, 0.218722, 0.30621), cf = CFrame.new(-1.649414, 6.561647, 0.166351, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.Plastic }, -- 69
		{ n = "Layer", s = "Block", z = Vector3.new(4.374433, 0.874887, 4.374433), cf = CFrame.new(0, 1.312328, 0.166351, 0.923879, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.new(0.345098, 0.447059, 0.580392), m = Enum.Material.Plastic }, -- 70
		{ n = "WindowFrame", s = "Block", z = Vector3.new(0.218722, 1.224841, 0.30621), cf = CFrame.new(0.67804, 2.187216, -3.398804, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.27451, 0.219608, 0.188235), m = Enum.Material.Plastic }, -- 71
		{ n = "Bolt", s = "Block", z = Vector3.new(0.699909, 0.262466, 0.437443), cf = CFrame.new(0, 4.374431, 2.75882, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(1, 0.92549, 0.470588), m = Enum.Material.Neon, st = false }, -- 72
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.713907, 0.240594, 0.174977), cf = CFrame.new(-0.998474, 3.648993, -3.333191, -0.309017, 0.951056, 0, -0.951056, -0.309017, 0, 0, 0, 1), c = Color3.new(0.352941, 0.588235, 0.901961), m = Enum.Material.Plastic }, -- 73
		{ n = "Layer", s = "Block", z = Vector3.new(5.074342, 0.874887, 5.074342), cf = CFrame.new(0, 3.936988, 0.166351, 0.382683, 0, 0.923879, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.new(0.431373, 0.54902, 0.690196), m = Enum.Material.Plastic }, -- 74
		{ n = "Rainbow", s = "Block", z = Vector3.new(1.070861, 0.240594, 0.174977), cf = CFrame.new(-0.925629, 4.598605, -3.333191, -0.809017, 0.587785, 0, -0.587785, -0.809017, 0, 0, 0, 1), c = Color3.new(0.909804, 0.329412, 0.329412), m = Enum.Material.Plastic }, -- 75
		{ n = "WindowCross", s = "Block", z = Vector3.new(1.137353, 0.109361, 0.218722), cf = CFrame.new(0, 2.187213, -3.420685, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.27451, 0.219608, 0.188235), m = Enum.Material.Plastic }, -- 76
		{ n = "Layer", s = "Block", z = Vector3.new(2.887125, 0.874887, 2.887125), cf = CFrame.new(0, 6.561647, 0.166351, 0.923879, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.new(0.666667, 0.760784, 0.847059), m = Enum.Material.Plastic }, -- 77
		{ n = "Layer", s = "Block", z = Vector3.new(4.54941, 0.874887, 4.54941), cf = CFrame.new(0, 4.811876, 0.166351, 0.923879, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.new(0.54902, 0.666667, 0.784314), m = Enum.Material.Plastic }, -- 78
		{ n = "Layer", s = "Block", z = Vector3.new(5.074342, 0.874887, 5.074342), cf = CFrame.new(0, 2.187213, 0.166351, 0.382683, 0, 0.923879, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.new(0.431373, 0.54902, 0.690196), m = Enum.Material.Plastic }, -- 79
		{ n = "CloudPuff", s = "Ball", z = Vector3.new(1.224841, 1.224841, 1.224841), cf = CFrame.new(-0.174988, 9.186304, -0.971008, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.909804, 0.933333, 0.964706), m = Enum.Material.SmoothPlastic, st = false }, -- 80
		{ n = "RainGem", s = "Block", z = Vector3.new(0.437443, 0.437443, 0.30621), cf = CFrame.new(2.832703, 1.968493, 0.166351, 0, 0, 1, 0.707107, 0.707107, 0, -0.707107, 0.707107, 0), c = Color3.new(0.588235, 0.862745, 1), m = Enum.Material.Neon, st = false }, -- 81
		{ n = "CloudPuff", s = "Ball", z = Vector3.new(0.962375, 0.962375, 0.962375), cf = CFrame.new(-0.874878, 9.273796, -0.621063, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.SmoothPlastic, st = false }, -- 82
		{ n = "RainGem", s = "Block", z = Vector3.new(0.437443, 0.437443, 0.30621), cf = CFrame.new(-2.122742, 5.905484, 0.166351, 0, 0, -1, 0.707107, 0.707107, 0, 0.707107, -0.707107, 0), c = Color3.new(0.588235, 0.862745, 1), m = Enum.Material.Neon, st = false }, -- 83
		{ n = "Raindrop", s = "Block", z = Vector3.new(0.262466, 0.437443, 0.262466), cf = CFrame.new(1.487305, 8.398907, -0.008636, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.new(0.509804, 0.745098, 0.941176), m = Enum.Material.SmoothPlastic, st = false }, -- 84
		{ n = "MistTile", s = "Block", z = Vector3.new(0.699909, 0.218722, 0.30621), cf = CFrame.new(-1.166321, 6.561647, 1.332672, 0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, 0.707107), c = Color3.new(0.784314, 0.823529, 0.878431), m = Enum.Material.Plastic }, -- 85
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.892384, 0.240594, 0.174977), cf = CFrame.new(0, 4.636899, -3.333191, -1, 0, 0, 0, -1, 0, 0, 0, 1), c = Color3.new(0.980392, 0.839216, 0.352941), m = Enum.Material.Plastic }, -- 86
		{ n = "Layer", s = "Block", z = Vector3.new(2.974614, 0.874887, 2.974614), cf = CFrame.new(0, 0.437443, 0.166351, 0.923879, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.new(0.258824, 0.345098, 0.470588), m = Enum.Material.Plastic }, -- 87
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.713907, 0.240594, 0.174977), cf = CFrame.new(0, 4.374432, -3.333191, -1, 0, 0, 0, -1, 0, 0, 0, 1), c = Color3.new(0.352941, 0.588235, 0.901961), m = Enum.Material.Plastic }, -- 88
		{ n = "Layer", s = "Block", z = Vector3.new(5.074342, 0.874887, 5.074342), cf = CFrame.new(0, 3.936988, 0.166351, 0.923879, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.new(0.431373, 0.54902, 0.690196), m = Enum.Material.Plastic }, -- 89
		{ n = "DripTile", s = "Block", z = Vector3.new(0.874887, 0.262466, 0.349955), cf = CFrame.new(-1.735291, 1.312328, -1.568939, -0.707107, 0, -0.707107, 0, 1, 0, 0.707107, 0, -0.707107), c = Color3.new(0.227451, 0.290196, 0.392157), m = Enum.Material.Plastic }, -- 90
		{ n = "DripTile", s = "Block", z = Vector3.new(0.874887, 0.262466, 0.349955), cf = CFrame.new(2.454071, 1.312329, 0.166351, 0, 0, 1, 0, 1, 0, -1, 0, 0), c = Color3.new(0.227451, 0.290196, 0.392157), m = Enum.Material.Plastic }, -- 91
		{ n = "Streak", s = "Block", z = Vector3.new(0.174977, 0.962375, 0.349955), cf = CFrame.new(-2.548706, 4.593152, 0.166351, 0, 0, -1, 0, 1, 0, 1, 0, 0), c = Color3.new(0.803922, 0.894118, 0.960784), m = Enum.Material.Plastic }, -- 92
		{ n = "Rainbow", s = "Block", z = Vector3.new(0.713907, 0.240594, 0.174977), cf = CFrame.new(-0.617096, 4.173926, -3.333191, -0.809017, 0.587785, 0, -0.587785, -0.809017, 0, 0, 0, 1), c = Color3.new(0.352941, 0.588235, 0.901961), m = Enum.Material.Plastic }, -- 93
	},
	Joints = {
	},
	Attachments = {
	},
	Lights = {
		{ n = "WindowLight", p = 6, range = 9, brightness = 0.8, color = Color3.new(1, 0.839216, 0.509804), shadows = false, enabled = true },
		{ n = "CrystalLight", p = 42, range = 10, brightness = 0.9, color = Color3.new(0.588235, 0.862745, 1), shadows = false, enabled = true },
	},
	Emitters = {
		{ n = "Drizzle", p = 2, rate = 6, enabled = true, lifetime = NumberRange.new(1.2, 1.8), speed = NumberRange.new(0.546804, 1.640412), size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.05468, 0), NumberSequenceKeypoint.new(1, 0.032808, 0) }), transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2, 0), NumberSequenceKeypoint.new(1, 1, 0) }), color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.new(0.509804, 0.745098, 0.941176)), ColorSequenceKeypoint.new(1, Color3.new(0.509804, 0.745098, 0.941176)) }), lightEmission = 0.3, lightInfluence = 1, texture = "rbxasset://textures/particles/sparkles_main.dds", spread = Vector2.new(180, 180), acceleration = Vector3.new(0, -8.748865, 0), rotation = NumberRange.new(0, 0), rotSpeed = NumberRange.new(0, 0), drag = 0, emissionDirection = Enum.NormalId.Top, zOffset = 0, brightness = 1, squash = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0, 0), NumberSequenceKeypoint.new(1, 0, 0) }), orientation = Enum.ParticleOrientation.FacingCamera, lockedToPart = false, velocityInheritance = 0, shape = Enum.ParticleEmitterShape.Box, shapeInOut = Enum.ParticleEmitterShapeInOut.Outward, shapeStyle = Enum.ParticleEmitterShapeStyle.Volume, timeScale = 1 },
	},
	Trails = {
	},
	Billboards = {
	},
}

return spec
