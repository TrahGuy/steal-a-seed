--!strict
-- Steal a Seed :: BramblebackModel
--
-- The DUSTBOWL nest guardian. Approved and locked as a Studio preview; this is
-- that geometry with a real rig under it.
--
-- NOT a *Service. Geometry only, like CreatureModel, ParentModel and HubFairy.
--
--==============================================================================
-- WHY THIS IS ITS OWN FILE
--
-- ParentModel is the GREENHOLLOW brute and nothing else. Its `biomeId` argument
-- only ever named the model, which is why every biome raised a mossy bark ogre
-- -- including the Dustbowl, standing on sand in Greenhollow green. Rather than
-- grow one 463-line file into a two-creature switch, ParentModel keeps its own
-- shape and dispatches here, the same way CreatureModel, MillModel and
-- HubFairy are separate geometry modules.
--
--==============================================================================
-- THE SIX SEAMS ARE THE CONTRACT, AND THE PREVIEW ALREADY HONOURED THEM
--
-- ParentAnim.client.luau finds joints BY NAME: Neck, JawJoint, LeftShoulder,
-- RightShoulder, LeftHip, RightHip. It multiplies onto each joint's stored REST
-- C0, so the rest pose authored here survives the walk cycle.
--
-- The approved preview declared exactly those six names and gave each a socket
-- position -- it was designed to drop into this rig. What it did NOT have was a
-- single Motor6D: it faked the seams with preview Models and drove them from
-- its own Heartbeat. That is the only structural difference between the preview
-- and this file. Same 83 parts, same sockets, real joints.
--
-- The preview's other six groups -- BodyCore, BackPlateL/R and the three crown
-- bristles -- are cosmetic. ParentAnim does not drive them, so they weld solid.
-- Their independent motion was preview-only and does not survive integration,
-- exactly as the plants' did not.
--
--==============================================================================
-- MASS, AND THE BUG IT FIXES
--
-- Every part is Massless EXCEPT the root. A massless part cannot root an
-- assembly, so making the HumanoidRootPart massless quietly promoted the Torso
-- to assembly root -- and Roblox rotates an assembly about its root, so the
-- creature walked home backwards with AutoRotate on. `Humanoid.RootPart` said
-- HumanoidRootPart while `root.AssemblyRootPart` said Torso; those two
-- disagreeing IS the bug. Do not make the root massless.
--==============================================================================

local BramblebackModel = {}

-- Sampled from the approved preview. Root/Sage/Husk are the Dustbowl biome
-- constants the five plants share -- that shared family is why the parent reads
-- as belonging to the biome rather than visiting it.
local COLORS = {
	Root = Color3.fromRGB(124, 76, 50),
	RootDark = Color3.fromRGB(95, 54, 32),
	Sage = Color3.fromRGB(128, 122, 78),
	SageDark = Color3.fromRGB(99, 96, 59),
	Husk = Color3.fromRGB(178, 158, 106),
	Ochre = Color3.fromRGB(206, 176, 122),
	-- Confined to the eyes. The one cool colour on the creature, and the reason
	-- it reads as awake at fifty studs.
	Eye = Color3.fromRGB(91, 222, 226),
	-- Only under moving plates: a bright underside revealed by movement adds
	-- life without making the resting silhouette noisy.
	Coral = Color3.fromRGB(222, 101, 66),
	Mouth = Color3.fromRGB(68, 26, 35),
	White = Color3.fromRGB(235, 229, 206),
}

--==============================================================================
-- THE PREVIEW WAS AUTHORED AT A FIXED SIZE
--
-- Every coordinate below is in the preview's own studs, where the creature
-- stands 14.9 tall. NestService asks for a height, so everything is scaled by
-- height/14.9 -- positions and sizes together. At the shipped PARENT_HEIGHT of
-- 15 that factor is 1.007, so the approved proportions are what ships.
--==============================================================================
local AUTHORED_HEIGHT = 14.9

local STUD_FACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}

-- Position scales; rotation does not. Subtracting a CFrame's own position
-- leaves the rotation-only CFrame.
local function scaled(c: CFrame, s: number): CFrame
	local p = c.Position
	return CFrame.new(p.X * s, p.Y * s, p.Z * s) * (c - p)
end

type Ctx = {
	model: Model,
	base: CFrame,
	s: number,
	parts: { [string]: BasePart },
	seams: { [string]: { BasePart } },
}

local function mk(ctx: Ctx, seam: string, name: string, size: Vector3,
	localCF: CFrame, color: Color3, kind: string?, smooth: boolean?): BasePart
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
	p.Material = Enum.Material.Plastic
	p.Anchored = false
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	local face = if smooth then Enum.SurfaceType.Smooth else Enum.SurfaceType.Studs
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
	if piece == anchor then
		return
	end
	local w = Instance.new("WeldConstraint")
	w.Part0 = anchor
	w.Part1 = piece
	w.Parent = anchor
end

local function motor(name: string, part0: BasePart, part1: BasePart): Motor6D
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	-- C0 is the socket in part0's space, C1 the same point in part1's. Deriving
	-- both from the parts' built positions means the rest pose IS the authored
	-- pose: ParentAnim multiplies onto C0, so a joint that starts wrong stays
	-- wrong for the whole walk cycle.
	m.C0 = part0.CFrame:ToObjectSpace(part1.CFrame)
	m.C1 = CFrame.new()
	m.Parent = part0
	return m
end

--==============================================================================
-- THE SOCKETS, IN PREVIEW STUDS
--
-- Which part each seam drives. The preview's `rests` table gave a socket
-- POSITION per group; what a Motor6D needs is the driven part, so these name it
-- directly. Everything else in the group welds to that part and rides along.
--==============================================================================
local SEAM_DRIVER = {
	LeftHip = "LeftUpperLeg",
	RightHip = "RightUpperLeg",
	LeftShoulder = "LeftUpperArm",
	RightShoulder = "RightUpperArm",
	Neck = "HeadHusk",
	JawJoint = "LowerJaw",
}

function BramblebackModel.Build(cf: CFrame, height: number, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Parent_dustbowl"
	model:SetAttribute("BiomeId", "dustbowl")
	model:SetAttribute("Asleep", true)
	model:SetAttribute("Species", "brambleback")
	model:SetAttribute("RigSeams", "Neck, JawJoint, LeftShoulder, RightShoulder, LeftHip, RightHip")
	model.Parent = parent

	local ctx: Ctx = {
		model = model,
		base = cf,
		s = height / AUTHORED_HEIGHT,
		parts = {},
		seams = {},
	}
	local rad = math.rad

	--== ROOT ==--
	-- Invisible, and the ONLY part with mass. See the header.
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(4.0, 3.0, 3.2) * ctx.s
	root.CFrame = cf * scaled(CFrame.new(0, 6.4, 0.15), ctx.s)
	root.Transparency = 1
	root.Anchored = false
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Massless = false
	root.Parent = model
	model.PrimaryPart = root

	--== BODYCORE : 14 ==--
	local pelvis = mk(ctx, "BodyCore", "Pelvis", Vector3.new(3.9, 2.1, 3.1),
		CFrame.new(0, 4.55, 0.25), COLORS.RootDark)
	mk(ctx, "BodyCore", "Abdomen", Vector3.new(4.65, 2.9, 3.45),
		CFrame.new(0, 6.25, 0.2) * CFrame.Angles(rad(-4), 0, 0), COLORS.Root)
	local torso = mk(ctx, "BodyCore", "Torso", Vector3.new(5.9, 3.15, 3.55),
		CFrame.new(0, 8.1, 0.12) * CFrame.Angles(rad(-7), 0, 0), COLORS.Root)
	mk(ctx, "BodyCore", "ChestRidge", Vector3.new(5.25, 0.65, 3.75),
		CFrame.new(0, 9.55, 0.2) * CFrame.Angles(rad(-7), 0, 0), COLORS.Husk)
	mk(ctx, "BodyCore", "BellyPlate", Vector3.new(3.65, 2.5, 0.5),
		CFrame.new(0, 6.85, -1.7) * CFrame.Angles(rad(-5), 0, 0), COLORS.Husk)
	mk(ctx, "BodyCore", "LeftRib", Vector3.new(1.0, 2.8, 0.65),
		CFrame.new(-2.45, 7.25, -1.25) * CFrame.Angles(0, 0, rad(-13)), COLORS.SageDark, "Wedge")
	mk(ctx, "BodyCore", "RightRib", Vector3.new(1.0, 2.8, 0.65),
		CFrame.new(2.45, 7.25, -1.25) * CFrame.Angles(0, math.pi, rad(13)), COLORS.SageDark, "Wedge")
	mk(ctx, "BodyCore", "BackSpine", Vector3.new(1.05, 4.8, 1.0),
		CFrame.new(0, 8.1, 1.92) * CFrame.Angles(rad(-8), 0, 0), COLORS.RootDark)
	mk(ctx, "BodyCore", "BackPlateCenter", Vector3.new(2.45, 5.85, 0.86),
		CFrame.new(0, 11.55, 1.82) * CFrame.Angles(rad(-18), 0, 0), COLORS.Sage, "Wedge")
	local centreGlow = mk(ctx, "BodyCore", "CenterUnderGlow", Vector3.new(1.8, 3.95, 0.24),
		CFrame.new(0, 11.25, 1.36) * CFrame.Angles(rad(-18), 0, 0), COLORS.Coral, nil, true)
	centreGlow.Transparency = 0.34
	mk(ctx, "BodyCore", "LeftRootKnot", Vector3.new(0.85, 0.85, 0.85),
		CFrame.new(-2.55, 5.3, 0.85) * CFrame.Angles(0, rad(18), rad(20)), COLORS.RootDark)
	mk(ctx, "BodyCore", "RightRootKnot", Vector3.new(0.85, 0.85, 0.85),
		CFrame.new(2.55, 5.3, 0.85) * CFrame.Angles(0, rad(-18), rad(-20)), COLORS.RootDark)
	mk(ctx, "BodyCore", "TailRoot", Vector3.new(1.55, 1.25, 2.1),
		CFrame.new(0, 4.75, 2.25) * CFrame.Angles(rad(18), 0, 0), COLORS.RootDark, "Wedge")
	mk(ctx, "BodyCore", "BrokenThornC", Vector3.new(0.82, 1.65, 0.8),
		CFrame.new(0.2, 12.65, 2.25) * CFrame.Angles(rad(8), 0, rad(8)), COLORS.Ochre, "Wedge")

	--== HIPS : 9 each ==--
	-- Root-toe asymmetry: the right foot's outer toe is short. One chipped toe
	-- is the whole reason the stance reads as grown rather than moulded.
	for _, side in ipairs({ { "Left", -1 }, { "Right", 1 } }) do
		local nm, sign = side[1] :: string, side[2] :: number
		local g = nm .. "Hip"
		local x = 1.35 * sign
		mk(ctx, g, nm .. "UpperLeg", Vector3.new(1.7, 2.7, 1.85),
			CFrame.new(x, 3.15, 0.25) * CFrame.Angles(rad(5), 0, rad(-5 * sign)), COLORS.RootDark)
		mk(ctx, g, nm .. "LowerLeg", Vector3.new(1.55, 2.35, 1.65),
			CFrame.new(x + 0.08 * sign, 1.45, -0.05) * CFrame.Angles(rad(-6), 0, rad(3 * sign)), COLORS.Root)
		mk(ctx, g, nm .. "KneeArmor", Vector3.new(1.82, 1.1, 0.62),
			CFrame.new(x, 2.25, -0.92) * CFrame.Angles(rad(-11), 0, 0), COLORS.Sage, "Wedge")
		mk(ctx, g, nm .. "AnkleBand", Vector3.new(1.7, 0.48, 1.72),
			CFrame.new(x + 0.08 * sign, 0.72, -0.1), COLORS.Husk)
		mk(ctx, g, nm .. "FootPad", Vector3.new(2.1, 0.55, 2.45),
			CFrame.new(x + 0.08 * sign, 0.38, -0.52), COLORS.RootDark)
		for toe = 1, 3 do
			local len = if nm == "Right" and toe == 3 then 1.2 else 1.7
			mk(ctx, g, nm .. "Toe" .. toe, Vector3.new(0.55, 0.5, len),
				CFrame.new(x + (toe - 2) * 0.62 + 0.08 * sign, 0.36, -1.72 - (len - 1.2) * 0.25)
					* CFrame.Angles(rad(-5), 0, 0), COLORS.Ochre, "Wedge")
		end
		mk(ctx, g, nm .. "RearHeel", Vector3.new(1.15, 0.58, 1.05),
			CFrame.new(x + 0.08 * sign, 0.4, 0.98) * CFrame.Angles(0, math.pi, 0),
			COLORS.RootDark, "Wedge")
	end

	--== SHOULDERS : 10 each ==--
	-- Long, front-heavy arms that end close to the knees. That reach is what
	-- makes the hunch read as a hunch instead of a slouch.
	for _, side in ipairs({ { "Left", -1 }, { "Right", 1 } }) do
		local nm, sign = side[1] :: string, side[2] :: number
		local g = nm .. "Shoulder"
		local x = 3.0 * sign
		mk(ctx, g, nm .. "UpperArm", Vector3.new(1.75, 3.55, 1.75),
			CFrame.new(x + 0.18 * sign, 6.75, -0.18) * CFrame.Angles(rad(-7), 0, rad(-8 * sign)), COLORS.Root)
		mk(ctx, g, nm .. "Elbow", Vector3.new(1.85, 1.15, 1.75),
			CFrame.new(x + 0.42 * sign, 5.05, -0.42) * CFrame.Angles(0, 0, rad(-12 * sign)), COLORS.RootDark)
		mk(ctx, g, nm .. "Forearm", Vector3.new(1.9, 3.25, 1.85),
			CFrame.new(x + 0.55 * sign, 3.65, -0.72) * CFrame.Angles(rad(-10), 0, rad(-5 * sign)), COLORS.RootDark)
		mk(ctx, g, nm .. "ForeArmor", Vector3.new(2.1, 2.35, 0.65),
			CFrame.new(x + 0.55 * sign, 4.05, -1.63) * CFrame.Angles(rad(-10), 0, 0), COLORS.Sage, "Wedge")
		mk(ctx, g, nm .. "WristBand", Vector3.new(2.0, 0.5, 1.9),
			CFrame.new(x + 0.62 * sign, 2.18, -0.82), COLORS.Husk)
		mk(ctx, g, nm .. "Palm", Vector3.new(2.15, 1.1, 2.05),
			CFrame.new(x + 0.65 * sign, 1.55, -1.0) * CFrame.Angles(rad(-8), 0, 0), COLORS.RootDark)
		for claw = 1, 3 do
			mk(ctx, g, nm .. "Claw" .. claw, Vector3.new(0.5, 0.52, 1.45),
				CFrame.new(x + 0.65 * sign + (claw - 2) * 0.62, 1.12, -2.22)
					* CFrame.Angles(rad(-8), 0, 0), COLORS.Ochre, "Wedge")
		end
		mk(ctx, g, nm .. "ShoulderBud", Vector3.new(1.15, 1.7, 1.2),
			CFrame.new(x + 0.12 * sign, 8.35, 0.1) * CFrame.Angles(rad(-8), 0, rad(-22 * sign)),
			COLORS.SageDark, "Wedge")
	end

	--== NECK / HEAD : 13 ==--
	-- The eyes and the mouth interior are the ONLY smooth structural surfaces on
	-- the creature. Everything else is studded plastic.
	mk(ctx, "Neck", "HeadHusk", Vector3.new(5.8, 3.25, 3.25),
		CFrame.new(0, 10.72, -1.14) * CFrame.Angles(rad(-5), 0, 0), COLORS.Husk)
	mk(ctx, "Neck", "NeckBase", Vector3.new(2.65, 2.25, 2.4),
		CFrame.new(0, 9.85, 0.08) * CFrame.Angles(rad(-12), 0, 0), COLORS.RootDark)
	mk(ctx, "Neck", "UpperHuskBrow", Vector3.new(5.45, 1.05, 0.72),
		CFrame.new(0, 11.35, -2.72) * CFrame.Angles(rad(-9), 0, 0), COLORS.SageDark, "Wedge")
	mk(ctx, "Neck", "LeftEye", Vector3.new(1.18, 0.32, 0.19),
		CFrame.new(-1.28, 10.88, -2.79) * CFrame.Angles(0, 0, rad(-5)), COLORS.Eye, nil, true)
	mk(ctx, "Neck", "RightEye", Vector3.new(1.18, 0.32, 0.19),
		CFrame.new(1.28, 10.88, -2.79) * CFrame.Angles(0, 0, rad(5)), COLORS.Eye, nil, true)
	for _, ck in ipairs({
		{ "LeftCheekUpper", -2.7, 10.45, 24 },
		{ "LeftCheekLower", -2.55, 9.82, 42 },
		{ "RightCheekUpper", 2.7, 10.45, -24 },
		{ "RightCheekLower", 2.55, 9.82, -42 },
	}) do
		mk(ctx, "Neck", ck[1] :: string, Vector3.new(0.62, 1.35, 0.62),
			CFrame.new(ck[2] :: number, ck[3] :: number, -2.05)
				* CFrame.Angles(rad(-8), 0, rad(ck[4] :: number)), COLORS.Sage, "Wedge")
	end
	local mouth = mk(ctx, "Neck", "MouthInterior", Vector3.new(4.05, 0.72, 0.22),
		CFrame.new(0, 10.03, -2.82), COLORS.Mouth, nil, true)
	mouth.Transparency = 0.02
	for t = 1, 3 do
		mk(ctx, "Neck", "UpperTooth" .. t, Vector3.new(0.72, 0.68 + 0.12 * (t % 2), 0.48),
			CFrame.new((t - 2) * 1.18, 10.18, -2.97) * CFrame.Angles(0, 0, math.pi),
			COLORS.White, "Wedge")
	end

	--== JAW : 5 ==--
	-- Deliberately smaller than the broad upper husk. The snap is the whole
	-- character: a monster that charges with a closed mouth is a shrub in a hurry.
	mk(ctx, "JawJoint", "LowerJaw", Vector3.new(4.25, 0.82, 1.25),
		CFrame.new(0, 9.64, -2.42) * CFrame.Angles(rad(4), 0, 0), COLORS.RootDark, "Wedge")
	mk(ctx, "JawJoint", "JawChin", Vector3.new(3.35, 0.62, 0.52),
		CFrame.new(0, 9.42, -2.94), COLORS.Husk)
	for t = 1, 3 do
		mk(ctx, "JawJoint", "LowerTooth" .. t,
			Vector3.new(0.68, 0.62 + 0.1 * ((t + 1) % 2), 0.48),
			CFrame.new((t - 2) * 1.1 + (if t == 2 then 0.12 else 0), 9.95, -3.02),
			COLORS.White, "Wedge")
	end

	--== BACK PLATES : 4 each, plus one broken thorn each ==--
	-- Four side plates and the centre plate above make exactly five broad armour
	-- forms. The coral undersides are the concealed colour -- visible when the
	-- creature moves, invisible when it sleeps.
	for _, side in ipairs({ { "L", -1 }, { "R", 1 } }) do
		local sfx, sign = side[1] :: string, side[2] :: number
		local g = "BackPlate" .. sfx
		mk(ctx, g, "BackPlate" .. sfx .. "Upper", Vector3.new(2.4, 4.9, 0.78),
			CFrame.new(2.05 * sign, 11.25, 1.58) * CFrame.Angles(rad(-22), 0, rad(-12 * sign)),
			COLORS.Sage, "Wedge")
		mk(ctx, g, "BackPlate" .. sfx .. "Lower", Vector3.new(2.55, 3.75, 0.74),
			CFrame.new(3.55 * sign, 9.65, 1.22) * CFrame.Angles(rad(-19), 0, rad(-26 * sign)),
			COLORS.SageDark, "Wedge")
		local uu = mk(ctx, g, "CoralUnder" .. sfx .. "Upper", Vector3.new(1.75, 3.2, 0.22),
			CFrame.new(2.05 * sign, 10.98, 1.15) * CFrame.Angles(rad(-22), 0, rad(-12 * sign)),
			COLORS.Coral, nil, true)
		uu.Transparency = 0.3
		local ul = mk(ctx, g, "CoralUnder" .. sfx .. "Lower", Vector3.new(1.85, 2.35, 0.2),
			CFrame.new(3.4 * sign, 9.45, 0.82) * CFrame.Angles(rad(-19), 0, rad(-26 * sign)),
			COLORS.Coral, nil, true)
		ul.Transparency = 0.38
	end
	mk(ctx, "BackPlateL", "BrokenThornL", Vector3.new(0.72, 1.8, 0.72),
		CFrame.new(-3.35, 12.1, 1.45) * CFrame.Angles(rad(-18), 0, rad(-31)), COLORS.Ochre, "Wedge")
	mk(ctx, "BackPlateR", "BrokenThornR", Vector3.new(0.68, 1.35, 0.7),
		CFrame.new(3.55, 10.7, 1.28) * CFrame.Angles(rad(-15), 0, rad(34)), COLORS.Ochre, "Wedge")

	--== CROWN BRISTLES : 3 ==--
	for _, b in ipairs({
		{ "CrownBristleL", -1.25, 14.0, 1.72, -9 },
		{ "CrownBristleC", 0, 14.2, 1.82, 0 },
		{ "CrownBristleR", 1.25, 14.0, 1.72, 9 },
	}) do
		mk(ctx, "Bristle", b[1] :: string, Vector3.new(0.58, 1.8, 0.62),
			CFrame.new(b[2] :: number, b[3] :: number, b[4] :: number)
				* CFrame.Angles(rad(-13), 0, rad(b[5] :: number)), COLORS.SageDark, "Wedge")
	end

	--==========================================================================
	-- JOINTS WHERE SOMETHING MOVES, WELDS EVERYWHERE ELSE
	--
	-- Six Motor6Ds, then every remaining part welded to the torso. Order
	-- matters: the motor has to exist before its group is welded, or the weld
	-- would fight the joint for the same part.
	--==========================================================================
	weldTo(root, torso)
	weldTo(torso, pelvis)

	local driven: { [BasePart]: boolean } = {}
	for seam, driverName in pairs(SEAM_DRIVER) do
		local driver = ctx.parts[driverName]
		if driver then
			motor(seam, torso, driver)
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

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	--==========================================================================
	-- COUNTED, NOT ASSUMED
	--
	-- The approved preview is 83 parts and warns loudly if it ever is not. Same
	-- guard here, and for the same reason: this file is a transcription, and a
	-- transcription that silently drops a claw is the kind of thing nobody
	-- notices until the art looks subtly wrong six weeks later.
	--==========================================================================
	local built = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			built += 1
		end
	end
	if built ~= 83 then
		warn(("[Seed/BramblebackModel] expected 83 parts, built %d"):format(built))
	end
	model:SetAttribute("MeasuredPartCount", built)

	return model
end

return BramblebackModel
