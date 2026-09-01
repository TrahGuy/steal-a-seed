--!strict
--==============================================================================
-- ASTRALMAW -- THE STARBLOOM GUARDIAN (BIOME 5)
--
-- A colossal cosmic behemoth with midnight-indigo carapace plates, glowing
-- starlight constellation seams, triple star horns, stardust tail, void eyes,
-- and crystalline astral claws.
--
-- Adheres strictly to the 7-seam parent contract:
--   RootJoint, Neck, JawJoint, LeftShoulder, RightShoulder, LeftHip, RightHip
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local AstralmawModel = {}

local AUTHORED_HEIGHT = 16.0
local ROOT_SIZE = Vector3.new(5.2, 4.2, 5.4)

-- Palette Tokens
local COLORS = {
	Midnight = Color3.fromRGB(24, 18, 46),
	MidnightDark = Color3.fromRGB(16, 12, 32),
	Void = Color3.fromRGB(14, 12, 20),
	Amethyst = Color3.fromRGB(68, 44, 106),
	AmethystDark = Color3.fromRGB(48, 30, 78),
	SlateDark = Color3.fromRGB(20, 16, 38),
	NebulaViolet = Color3.fromRGB(168, 138, 255),
	NebulaCyan = Color3.fromRGB(110, 230, 255),
	NebulaDeep = Color3.fromRGB(90, 50, 160),
	StarIvory = Color3.fromRGB(242, 238, 255),
	MouthDark = Color3.fromRGB(42, 14, 38),
}

local STUD_FACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}

type Ctx = {
	model: Model,
	base: CFrame,
	s: number,
	parts: { [string]: BasePart },
	seams: { [string]: { BasePart } },
}

local function scaled(c: CFrame, s: number): CFrame
	local p = c.Position
	return CFrame.new(p.X * s, p.Y * s, p.Z * s) * (c - p)
end

local function mk(ctx: Ctx, seam: string, name: string, size: Vector3,
	localCF: CFrame, color: Color3, kind: string?, mat: Enum.Material?, smooth: boolean?): BasePart
	local p: BasePart
	if kind == "Wedge" then
		p = Instance.new("WedgePart")
	else
		local b = Instance.new("Part")
		b.Shape = Enum.PartType.Block
		p = b
	end
	p.Name = name
	p.Size = size * ctx.s
	p.CFrame = ctx.base * scaled(localCF, ctx.s)
	p.Color = color
	p.Material = mat or Enum.Material.Plastic
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true

	local face = if (smooth or mat == Enum.Material.Neon) then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
	for _, f in ipairs(STUD_FACES) do
		pcall(function()
			(p :: any)[f] = face
		end)
	end
	p.Parent = ctx.model
	ctx.parts[name] = p

	local bucket = ctx.seams[seam]
	if not bucket then
		bucket = {}
		ctx.seams[seam] = bucket
	end
	table.insert(bucket, p)
	return p
end

local function weldTo(anchor: BasePart, piece: BasePart)
	if piece == anchor then return end
	local w = Instance.new("WeldConstraint")
	w.Part0 = anchor
	w.Part1 = piece
	w.Parent = anchor
end

local function socketMotor(name: string, part0: BasePart, part1: BasePart, socket: CFrame): Motor6D
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = part0.CFrame:ToObjectSpace(socket)
	m.C1 = part1.CFrame:ToObjectSpace(socket)
	m.Parent = part0
	return m
end

local function motor(name: string, part0: BasePart, part1: BasePart): Motor6D
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
	m.C1 = CFrame.new()
	m.Parent = part0
	return m
end

local SEAM_DRIVER = {
	LeftHip = "LeftUpperLeg",
	RightHip = "RightUpperLeg",
	LeftShoulder = "LeftUpperArm",
	RightShoulder = "RightUpperArm",
	Neck = "Head",
	JawJoint = "LowerJaw",
}

function AstralmawModel.Build(cf: CFrame, height: number, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Parent_starbloom"
	model:SetAttribute("BiomeId", "starbloom")
	model:SetAttribute("Species", "astralmaw")
	model:SetAttribute("Asleep", true)
	model:SetAttribute("RigSeams", "Neck, JawJoint, LeftShoulder, RightShoulder, LeftHip, RightHip")
	model.Parent = parent

	local s = height / AUTHORED_HEIGHT
	local ctx: Ctx = {
		model = model,
		base = cf,
		s = s,
		parts = {},
		seams = {},
	}
	local rad = math.rad

	--== ROOT ==--
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = ROOT_SIZE * s
	root.CFrame = cf * scaled(CFrame.new(0, 7.2, 0), s)
	root.Transparency = 1
	root.Anchored = false
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Massless = false
	root.Parent = model
	model.PrimaryPart = root

	--== BODYCORE / TORSO ==--
	local torsoY = 7.35
	local torso = mk(ctx, "BodyCore", "Torso", Vector3.new(6.4, 5.0, 5.6),
		CFrame.new(0, torsoY, 0) * CFrame.Angles(rad(-8), 0, 0), COLORS.Midnight)
	mk(ctx, "BodyCore", "Pelvis", Vector3.new(5.6, 3.6, 4.6),
		CFrame.new(0, torsoY - 2.4, 0.6) * CFrame.Angles(rad(6), 0, 0), COLORS.MidnightDark)

	-- Glowing Multi-Layered Constellation Heart
	local chestCore = mk(ctx, "BodyCore", "ChestNebula", Vector3.new(4.5, 3.2, 1.2),
		CFrame.new(0, torsoY + 0.6, -2.7) * CFrame.Angles(rad(-8), 0, 0), COLORS.NebulaViolet, nil, Enum.Material.Neon, true)
	local chestSeamL = mk(ctx, "BodyCore", "ChestSeamL", Vector3.new(1.2, 2.4, 0.4),
		CFrame.new(-1.8, torsoY + 0.4, -2.8) * CFrame.Angles(0, 0, rad(-25)), COLORS.NebulaCyan, "Wedge", Enum.Material.Neon, true)
	local chestSeamR = mk(ctx, "BodyCore", "ChestSeamR", Vector3.new(1.2, 2.4, 0.4),
		CFrame.new(1.8, torsoY + 0.4, -2.8) * CFrame.Angles(0, math.pi, rad(25)), COLORS.NebulaCyan, "Wedge", Enum.Material.Neon, true)

	local chestLight = Instance.new("PointLight", chestCore)
	chestLight.Color, chestLight.Brightness, chestLight.Range = COLORS.NebulaViolet, 2.8, 22 * s

	-- Stepped Carapace Spine Plates & Constellation Runes
	for i = 0, 3 do
		mk(ctx, "BodyCore", "SpinePlate" .. i, Vector3.new(5.6 - i * 0.9, 1.8, 2.2),
			CFrame.new(0, torsoY + 2.2 - i * 1.5, 2.8 + i * 0.7) * CFrame.Angles(rad(-16), 0, 0), COLORS.Amethyst)
		mk(ctx, "BodyCore", "PlateSeam" .. i, Vector3.new(4.2 - i * 0.7, 0.45, 2.4),
			CFrame.new(0, torsoY + 2.2 - i * 1.5, 2.8 + i * 0.7) * CFrame.Angles(rad(-16), 0, 0), COLORS.NebulaCyan, nil, Enum.Material.Neon, true)
		-- Radiant Stardust Spines
		mk(ctx, "BodyCore", "DorsalSpike" .. i, Vector3.new(0.8, 2.2 - i * 0.3, 0.8),
			CFrame.new(0, torsoY + 3.2 - i * 1.5, 3.4 + i * 0.7) * CFrame.Angles(rad(-28), 0, 0), COLORS.StarIvory, "Wedge")
	end

	-- Segmented Stardust Tail
	for t = 1, 3 do
		local tz = 5.2 + (t - 1) * 2.2
		local ty = torsoY - 1.8 - (t - 1) * 0.8
		mk(ctx, "BodyCore", "TailSeg" .. t, Vector3.new(3.8 - t * 0.8, 2.2 - t * 0.4, 2.4),
			CFrame.new(0, ty, tz) * CFrame.Angles(rad(12 - t * 6), 0, 0), COLORS.AmethystDark)
		mk(ctx, "BodyCore", "TailSpine" .. t, Vector3.new(0.6, 1.4, 0.6),
			CFrame.new(0, ty + 1.2, tz) * CFrame.Angles(rad(25), 0, 0), COLORS.NebulaCyan, "Wedge", Enum.Material.Neon, true)
	end
	-- Glowing Crescent Stardust Tail Barb
	mk(ctx, "BodyCore", "TailBarb", Vector3.new(1.8, 2.6, 2.8),
		CFrame.new(0, torsoY - 3.8, 11.2) * CFrame.Angles(rad(35), 0, 0), COLORS.NebulaCyan, "Wedge", Enum.Material.Neon, true)

	--== HIPS (Hind Legs) ==--
	for _, side in ipairs({ { "Left", -1 }, { "Right", 1 } }) do
		local nm, sign = side[1] :: string, side[2] :: number
		local g = nm .. "Hip"
		local hx = 2.6 * sign
		mk(ctx, g, nm .. "UpperLeg", Vector3.new(2.6, 4.4, 3.0),
			CFrame.new(hx, 4.2, 0.8) * CFrame.Angles(rad(10), 0, rad(-6 * sign)), COLORS.Midnight)
		mk(ctx, g, nm .. "KneeArmor", Vector3.new(2.8, 1.8, 1.2),
			CFrame.new(hx, 3.6, -0.6) * CFrame.Angles(rad(-15), 0, 0), COLORS.Amethyst, "Wedge")
		mk(ctx, g, nm .. "LowerLeg", Vector3.new(2.4, 3.4, 2.6),
			CFrame.new(hx + 0.3 * sign, 1.8, 0.3) * CFrame.Angles(rad(-14), 0, 0), COLORS.AmethystDark)
		for toe = 1, 3 do
			mk(ctx, g, nm .. "Toe" .. toe, Vector3.new(0.75, 0.95, 2.4),
				CFrame.new(hx + (toe - 2) * 0.75, 0.55, -0.95) * CFrame.Angles(rad(-10), 0, 0), COLORS.NebulaCyan, "Wedge", Enum.Material.Neon, true)
		end
	end

	--== SHOULDERS (Front Arms, Layered Pauldrons & Crystal Claws) ==--
	local shoulderY = 9.4
	for _, side in ipairs({ { "Left", -1 }, { "Right", 1 } }) do
		local nm, sign = side[1] :: string, side[2] :: number
		local g = nm .. "Shoulder"
		local ax = 4.4 * sign
		mk(ctx, g, nm .. "UpperArm", Vector3.new(2.6, 4.6, 2.8),
			CFrame.new(ax, shoulderY - 1.8, -0.6) * CFrame.Angles(rad(-12), 0, rad(-10 * sign)), COLORS.Amethyst)
		mk(ctx, g, nm .. "Forearm", Vector3.new(2.4, 4.6, 2.6),
			CFrame.new(ax + 0.6 * sign, shoulderY - 5.6, -1.9) * CFrame.Angles(rad(-15), 0, 0), COLORS.Midnight)

		-- Triple-Tiered Constellation Pauldrons
		mk(ctx, g, nm .. "PauldronTop", Vector3.new(3.2, 1.8, 3.2),
			CFrame.new(ax, shoulderY + 0.8, -0.6) * CFrame.Angles(0, 0, rad(-18 * sign)), COLORS.SlateDark)
		mk(ctx, g, nm .. "PauldronRune", Vector3.new(2.4, 0.4, 2.4),
			CFrame.new(ax, shoulderY + 1.8, -0.6) * CFrame.Angles(0, 0, rad(-18 * sign)), COLORS.NebulaCyan, nil, Enum.Material.Neon, true)
		mk(ctx, g, nm .. "PauldronMid", Vector3.new(2.8, 1.6, 2.8),
			CFrame.new(ax + 0.4 * sign, shoulderY - 0.6, -0.6) * CFrame.Angles(0, 0, rad(-25 * sign)), COLORS.AmethystDark)

		-- 4 Graduated Crystalline Claws
		for claw = 1, 4 do
			local clen = (claw == 2 or claw == 3) and 2.6 or 2.1
			mk(ctx, g, nm .. "Claw" .. claw, Vector3.new(0.6, clen, 0.95),
				CFrame.new(ax + 0.6 * sign + (claw - 2.5) * 0.65, shoulderY - 8.0, -3.0) * CFrame.Angles(rad(24), 0, (claw - 2.5) * rad(12)), COLORS.NebulaCyan, "Wedge", Enum.Material.Neon, true)
		end
	end

	--== HEAD, VOID EYES, TRIPLE STAR HORNS & GAPE MAW ==--
	local headZ = -2.6
	local skullY = 12.8
	local headW = 5.8
	local headFrame = CFrame.new(0, skullY, headZ) * CFrame.Angles(rad(-8), 0, 0)

	local head = mk(ctx, "Neck", "Head", Vector3.new(headW, 3.2, 4.6),
		headFrame, COLORS.Midnight)
	mk(ctx, "Neck", "BrowArmor", Vector3.new(headW * 1.05, 1.2, 3.2),
		CFrame.new(0, skullY + 1.4, headZ - 0.8) * CFrame.Angles(rad(-14), 0, 0), COLORS.AmethystDark)

	-- The shared Starbloom face vocabulary is VOID: a tall dark eye sunk halfway
	-- into the skull, one cold pinprick, and a heavy moulded lid. There is no
	-- glint -- two highlights would turn the pinprick into an ordinary cute eye.
	for _, side in ipairs({ { "Left", -1 }, { "Right", 1 } }) do
		local nm, sign = side[1] :: string, side[2] :: number
		local eyeRoll = rad(10 * sign)
		mk(ctx, "Neck", nm .. "Eye", Vector3.new(0.88, 1.20, 0.58),
			headFrame * CFrame.new(1.45 * sign, 0.20, -2.30)
				* CFrame.Angles(0, rad(-4 * sign), eyeRoll),
			COLORS.Void)
		mk(ctx, "Neck", nm .. "Pupil", Vector3.new(0.24, 0.32, 0.24),
			headFrame * CFrame.new(1.45 * sign, 0.20, -2.64)
				* CFrame.Angles(0, rad(-4 * sign), eyeRoll),
			COLORS.StarIvory, nil, Enum.Material.Neon, true)
		mk(ctx, "Neck", nm .. "Lid", Vector3.new(1.16, 0.42, 0.64),
			headFrame * CFrame.new(1.45 * sign, 0.78, -2.23)
				* CFrame.Angles(rad(-7), rad(-4 * sign), eyeRoll),
			COLORS.AmethystDark)
	end

	-- Triple Star Horn Crown (Left, Center Star Crest, Right)
	for _, side in ipairs({ { "Left", -1 }, { "Right", 1 } }) do
		local nm, sign = side[1] :: string, side[2] :: number
		mk(ctx, "Neck", nm .. "HornBase", Vector3.new(1.1, 3.2, 1.1),
			CFrame.new(2.1 * sign, skullY + 2.8, headZ + 0.4) * CFrame.Angles(rad(-22), rad(18 * sign), rad(28 * sign)), COLORS.StarIvory)
		mk(ctx, "Neck", nm .. "HornTip", Vector3.new(0.9, 3.8, 0.9),
			CFrame.new(2.9 * sign, skullY + 5.2, headZ - 0.4) * CFrame.Angles(rad(32), rad(-15 * sign), rad(18 * sign)), COLORS.NebulaCyan, "Wedge", Enum.Material.Neon, true)
	end
	-- Center Star Horn
	mk(ctx, "Neck", "HornCenterBase", Vector3.new(1.2, 3.6, 1.2),
		CFrame.new(0, skullY + 3.2, headZ - 0.2) * CFrame.Angles(rad(-16), 0, 0), COLORS.StarIvory)
	mk(ctx, "Neck", "HornCenterTip", Vector3.new(1.0, 3.8, 1.0),
		CFrame.new(0, skullY + 5.8, headZ - 0.8) * CFrame.Angles(rad(24), 0, 0), COLORS.NebulaViolet, "Wedge", Enum.Material.Neon, true)

	-- Deep Glowing Nebula Throat & Jaw
	local throat = mk(ctx, "Neck", "MawThroat", Vector3.new(4.8, 1.6, 2.8),
		CFrame.new(0, skullY - 1.2, headZ - 0.6), COLORS.NebulaViolet, nil, Enum.Material.Neon, true)
	local throatLight = Instance.new("PointLight", throat)
	throatLight.Color, throatLight.Brightness, throatLight.Range = COLORS.NebulaCyan, 3.2, 22 * s

	-- Upper Serrated Fangs
	for t = 1, 6 do
		local big = (t == 2 or t == 5)
		local toothLen = big and 1.3 or 0.9
		mk(ctx, "Neck", "UpperTooth" .. t, Vector3.new(0.55, toothLen, 0.55),
			CFrame.new((t - 3.5) * 0.85, skullY - 1.2, headZ - 2.1) * CFrame.Angles(math.pi, 0, 0), COLORS.StarIvory, "Wedge")
	end

	-- Lower Jaw (Motor6D Driven)
	local jaw = mk(ctx, "JawJoint", "LowerJaw", Vector3.new(headW * 0.90, 1.4, 3.8),
		CFrame.new(0, skullY - 2.6, headZ + 0.3), COLORS.Amethyst)
	for t = 1, 6 do
		local big = (t == 2 or t == 5)
		local toothLen = big and 1.3 or 0.9
		mk(ctx, "JawJoint", "LowerTooth" .. t, Vector3.new(0.55, toothLen, 0.55),
			CFrame.new((t - 3.5) * 0.85, skullY - 2.0, headZ - 1.8), COLORS.StarIvory, "Wedge")
	end

	-- Dual Floating Nebula Emitters
	local stardust = Instance.new("ParticleEmitter", head)
	stardust.Name = "StardustEmitter"
	stardust.Rate, stardust.Lifetime, stardust.Speed = 26, NumberRange.new(2.2, 3.8), NumberRange.new(2.2, 4.8)
	stardust.SpreadAngle, stardust.Acceleration, stardust.LightEmission = Vector2.new(45, 45), Vector3.new(0, 2.2, 0), 1
	stardust.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, COLORS.NebulaCyan), ColorSequenceKeypoint.new(0.5, COLORS.NebulaViolet), ColorSequenceKeypoint.new(1, COLORS.Midnight)})
	stardust.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.25 * s), NumberSequenceKeypoint.new(0.6, 0.6 * s), NumberSequenceKeypoint.new(1, 0)})

	-- Cosmic Aura Highlight
	local aura = Instance.new("Highlight", model)
	aura.Name = "CosmicAura"
	aura.OutlineColor, aura.OutlineTransparency = COLORS.NebulaCyan, 0.25
	aura.FillColor, aura.FillTransparency = COLORS.NebulaDeep, 0.92

	--==============================================================================
	-- MOTORS & WELDS
	--==============================================================================
	socketMotor("RootJoint", root, torso, cf)
	local driven: { [BasePart]: boolean } = {}
	for seam, driverName in pairs(SEAM_DRIVER) do
		local driver = ctx.parts[driverName]
		if driver then
			if seam == "Neck" or seam == "JawJoint" then
				motor(seam, if seam == "JawJoint" then head else torso, driver)
			else
				motor(seam, torso, driver)
			end
			driven[driver] = true
			for _, p in ipairs(ctx.seams[seam] or {}) do
				if p ~= driver then
					weldTo(driver, p)
				end
			end
		end
	end
	for seam, bucket in pairs(ctx.seams) do
		if not SEAM_DRIVER[seam] then
			for _, p in ipairs(bucket) do
				weldTo(torso, p)
			end
		end
	end

	--== HUMANOID CONTRACT ==--
	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = true
	humanoid.HipHeight = 5.2 * s
	humanoid.MaxHealth = math.huge
	humanoid.Health = math.huge
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	torso.CanCollide = true
	torso.Massless = true

	model:SetAttribute("SleepBodyPose",
		CFrame.new(0, 2.8 * s, 2.2 * s) * CFrame.Angles(math.rad(-65), math.rad(5), 0))

	CollectionService:AddTag(model, GameConfig.Tags.NestParent)
	return model
end

return AstralmawModel
