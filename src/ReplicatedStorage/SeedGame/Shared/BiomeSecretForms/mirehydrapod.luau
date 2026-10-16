--!strict
--==============================================================================
-- BIOME SECRET FORM: Mirehydra's pod (Tanglemire's secret pod), 2026-10-16
--
-- Lifted part for part, joint for joint, light, emitter and attribute
-- from the owner's ServerStorage model "Tanglemire Secret/Tanglemire Secret Pod" by a read-only generator on
-- 2026-10-16. The original was not moved or changed; a verified .rbxm of it is
-- in output/model-backups/2026-10-16-biome-secrets-originals. It carried
-- plain parts, no script.
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
	Source = "Tanglemire Secret/Tanglemire Secret Pod", Kind = "pod", Yaw = 0,
	Size = Vector3.new(20.157501, 30.475895, 20.915531), Height = 30.475895, PartCount = 29,
	Base = 0,
	Unit = 1, ModelScale = 4.435931,
	Attributes = {},
	Pivot = CFrame.new(0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1),
	Parts = {
		{ n = "Frond", s = "Block", z = Vector3.new(1.774372, 0.532312, 6.032866), cf = CFrame.new(2.649963, 28.824764, -0.964505, 0.34202, -0.441159, -0.829699, 0, 0.882948, -0.469472, 0.939693, 0.160569, 0.301986), c = Color3.fromRGB(110, 176, 96), m = Enum.Material.Plastic }, -- 1
		{ n = "HollowVine", s = "Block", z = Vector3.new(0.709749, 4.968243, 0.532312), cf = CFrame.new(1.596924, 9.936485, -10.912392, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(110, 170, 84), m = Enum.Material.Plastic }, -- 2
		{ n = "Frond", s = "Block", z = Vector3.new(1.774372, 0.532312, 6.032866), cf = CFrame.new(-2.649963, 28.824764, 0.964505, -0.34202, 0.441159, 0.829699, 0, 0.882948, -0.469472, -0.939693, -0.160569, -0.301986), c = Color3.fromRGB(110, 176, 96), m = Enum.Material.Plastic }, -- 3
		{ n = "ToadstoolCap", s = "Block", z = Vector3.new(3.193871, 1.242061, 3.193871), cf = CFrame.new(8.162109, 2.750277, -5.323124, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(214, 70, 60), m = Enum.Material.Plastic }, -- 4
		{ n = "Frond", s = "Block", z = Vector3.new(1.774372, 0.532312, 6.032866), cf = CFrame.new(0.964508, 28.824764, 2.649945, -0.939693, -0.160569, -0.301986, 0, 0.882948, -0.469472, 0.34202, -0.441159, -0.829699), c = Color3.fromRGB(80, 150, 84), m = Enum.Material.Plastic }, -- 5
		{ n = "Toadstool", s = "Block", z = Vector3.new(0.931545, 1.596935, 0.931545), cf = CFrame.new(-7.452362, 0.798468, -4.613366, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(240, 230, 200), m = Enum.Material.Plastic }, -- 6
		{ n = "Frond", s = "Block", z = Vector3.new(1.774372, 0.532312, 6.032866), cf = CFrame.new(-0.964508, 28.824764, -2.649945, 0.939693, 0.160569, 0.301986, 0, 0.882948, -0.469472, -0.34202, 0.441159, 0.829699), c = Color3.fromRGB(80, 150, 84), m = Enum.Material.Plastic }, -- 7
		{ n = "FernBase", s = "Block", z = Vector3.new(2.129247, 1.064623, 2.129247), cf = CFrame.new(0, 26.615587, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(70, 122, 62), m = Enum.Material.Plastic }, -- 8
		{ n = "Layer", s = "Block", z = Vector3.new(14.549853, 3.726182, 14.549853), cf = CFrame.new(0, 13.041636, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(104, 78, 56), m = Enum.Material.Plastic }, -- 9
		{ n = "Layer", s = "Block", z = Vector3.new(9.226737, 3.726182, 9.226737), cf = CFrame.new(0, 20.494001, 0, 0.382683, 0, 0.92388, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.fromRGB(70, 122, 62), m = Enum.Material.Plastic }, -- 10
		{ n = "Layer", s = "Block", z = Vector3.new(9.226737, 3.726182, 9.226737), cf = CFrame.new(0, 20.494001, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(70, 122, 62), m = Enum.Material.Plastic }, -- 11
		{ n = "HollowDark", s = "Block", z = Vector3.new(5.323118, 7.09749, 0.709749), cf = CFrame.new(0, 8.162113, -10.380082, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(30, 28, 22), m = Enum.Material.Plastic }, -- 12
		{ n = "HollowPost", s = "Block", z = Vector3.new(1.242061, 8.162113, 1.064623), cf = CFrame.new(-3.371307, 8.162113, -10.291365, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(84, 60, 42), m = Enum.Material.Plastic }, -- 13
		{ n = "Toadstool", s = "Block", z = Vector3.new(1.242061, 2.129247, 1.242061), cf = CFrame.new(8.162109, 1.064623, -5.323124, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(240, 230, 200), m = Enum.Material.Plastic }, -- 14
		{ n = "Layer", s = "Block", z = Vector3.new(12.420606, 3.726182, 12.420606), cf = CFrame.new(0, 16.76782, 0, 0.382683, 0, 0.92388, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.fromRGB(92, 150, 76), m = Enum.Material.Plastic }, -- 15
		{ n = "ToadstoolCap", s = "Block", z = Vector3.new(2.395403, 0.931545, 2.395403), cf = CFrame.new(-7.452362, 2.062708, -4.613366, 0.707107, 0, 0.707107, 0, 1, 0, -0.707107, 0, 0.707107), c = Color3.fromRGB(230, 130, 60), m = Enum.Material.Plastic }, -- 16
		{ n = "Layer", s = "Block", z = Vector3.new(14.549853, 3.726182, 14.549853), cf = CFrame.new(0, 13.041636, 0, 0.382683, 0, 0.92388, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.fromRGB(104, 78, 56), m = Enum.Material.Plastic }, -- 17
		{ n = "Layer", s = "Block", z = Vector3.new(12.420606, 3.726182, 12.420606), cf = CFrame.new(0, 16.76782, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(92, 150, 76), m = Enum.Material.Plastic }, -- 18
		{ n = "Layer", s = "Block", z = Vector3.new(13.485229, 3.726182, 13.485229), cf = CFrame.new(0, 5.589273, 0, 0.382683, 0, 0.92388, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.fromRGB(104, 78, 56), m = Enum.Material.Plastic }, -- 19
		{ n = "Layer", s = "Block", z = Vector3.new(4.968243, 3.726182, 4.968243), cf = CFrame.new(0, 24.220186, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(92, 150, 76), m = Enum.Material.Plastic }, -- 20
		{ n = "FrontPlate", s = "Block", z = Vector3.new(8.162113, 11.178547, 2.484121), cf = CFrame.new(0, 9.315454, -8.871864, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(74, 54, 40), m = Enum.Material.Plastic }, -- 21
		{ n = "HollowSill", s = "Block", z = Vector3.new(7.09749, 0.887186, 1.242061), cf = CFrame.new(0, 3.992337, -10.380082, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(84, 60, 42), m = Enum.Material.Plastic }, -- 22
		{ n = "HollowLintel", s = "Block", z = Vector3.new(8.162113, 1.419498, 1.064623), cf = CFrame.new(0, 12.598043, -10.291365, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(84, 60, 42), m = Enum.Material.Plastic }, -- 23
		{ n = "HollowPost", s = "Block", z = Vector3.new(1.242061, 8.162113, 1.064623), cf = CFrame.new(3.371307, 8.162113, -10.291365, 1, 0, 0, 0, 1, 0, 0, 0, 1), c = Color3.fromRGB(84, 60, 42), m = Enum.Material.Plastic }, -- 24
		{ n = "Layer", s = "Block", z = Vector3.new(14.904727, 3.726182, 14.904727), cf = CFrame.new(0, 9.315454, 0, 0.382683, 0, 0.92388, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.fromRGB(122, 92, 64), m = Enum.Material.Plastic }, -- 25
		{ n = "Layer", s = "Block", z = Vector3.new(14.904727, 3.726182, 14.904727), cf = CFrame.new(0, 9.315454, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(122, 92, 64), m = Enum.Material.Plastic }, -- 26
		{ n = "Layer", s = "Block", z = Vector3.new(9.581611, 3.726182, 9.581611), cf = CFrame.new(0, 1.863091, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(92, 150, 76), m = Enum.Material.Plastic }, -- 27
		{ n = "Layer", s = "Block", z = Vector3.new(9.581611, 3.726182, 9.581611), cf = CFrame.new(0, 1.863091, 0, 0.382683, 0, 0.92388, 0, 1, 0, -0.92388, 0, 0.382683), c = Color3.fromRGB(92, 150, 76), m = Enum.Material.Plastic }, -- 28
		{ n = "Layer", s = "Block", z = Vector3.new(13.485229, 3.726182, 13.485229), cf = CFrame.new(0, 5.589273, 0, 0.92388, 0, 0.382683, 0, 1, 0, -0.382683, 0, 0.92388), c = Color3.fromRGB(104, 78, 56), m = Enum.Material.Plastic }, -- 29
	},
	Joints = {
	},
	Attachments = {
	},
	Lights = {
	},
	Emitters = {
	},
	Textures = {
	},
	Beams = {
	},
}

return spec
