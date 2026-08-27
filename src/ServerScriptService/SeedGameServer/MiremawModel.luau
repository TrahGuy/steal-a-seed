--!strict
--==============================================================================
-- MIREMAW -- THE TANGLEMIRE GUARDIAN
--
-- Seventy-three parts, built from the approved geometry in TanglemireForms and
-- articulated across fifteen seams. Nothing here decides what it looks like:
-- this file decides what MOVES, and the shape it moves is the shape that was
-- signed off in Edit.
--
-- Same contract as BramblebackModel, and deliberately not folded into it. Two
-- guardians that look nothing alike sharing one recoloured builder is how a
-- biome stops being its own place, which the Dustbowl pass already settled.
--
--==============================================================================
-- THE SEAMS, AND WHY THERE ARE FIFTEEN
--
-- Seven are the parent contract -- RootJoint, Neck, JawJoint, LeftShoulder,
-- RightShoulder, LeftHip, RightHip -- because ParentAnim and SoundCues find
-- them by those names and nothing may rename them.
--
-- The other eight exist because the two approved poses DISAGREE across them:
-- four fronds that lag independently, a throat that moves, and three throat
-- ribs. Every one was measured, not invented.
--
-- What is NOT a seam matters as much. The hood and the eyelids are welded to
-- the head, because between the approved sleeping and waking poses they do not
-- move relative to it by a thousandth of a stud -- the hood "opening" is the
-- whole head-and-hood assembly rising on the neck, and the eyes close by
-- transparency and lid colour rather than by a lid that swings. Giving either
-- one a joint would be inventing articulation the approval does not contain.
--
--==============================================================================
-- THE JAW AND THE HOOD HANG OFF THE HEAD, NOT THE TORSO
--
-- Brambleback drives all six of its seams from the torso, which is fine for a
-- creature whose head barely moves. Miremaw's head rises 0.87 studs and pitches
-- ten degrees on waking, and a torso-driven mouth would visibly slide off the
-- face while it did it. The Motor6D names are what the contract fixes; which
-- part is Part0 is anatomy, and anatomy wins.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local TanglemireForms = require(Shared:WaitForChild("TanglemireForms"))

local MiremawModel = {}

--==============================================================================
-- THE AUTHORED FRAME
--
-- Everything below is in the mockup's own studs and is conformed to whatever
-- height NestService asks for by a single factor. AUTHORED_HEIGHT is the true
-- silhouette height -- the highest of the eight ROTATED corners, not an
-- axis-aligned half-extent, because sixty-seven of the parts are rotated and
-- the cheap measurement over-reads by nearly two studs.
--==============================================================================
local AUTHORED_HEIGHT = TanglemireForms.MiremawPreviewHeight

-- The root sits at the torso's own centre, inside a body 7.0 x 5.6 x 4.5, so
-- the assembly root is buried in mass rather than floating in the silhouette.
local ROOT_SIZE = Vector3.new(4.4, 3.2, 3.4)

local STUD_FACES = {
	"TopSurface", "BottomSurface", "LeftSurface",
	"RightSurface", "FrontSurface", "BackSurface",
}

local SHAPE_BY_NAME: { [string]: Enum.PartType } = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}

-- Scale the translation, never the rotation. A scaled angle is a different
-- pose; a scaled offset is the same pose on a bigger creature.
local function scaled(c: CFrame, s: number): CFrame
	local p = c.Position
	return CFrame.new(p.X * s, p.Y * s, p.Z * s) * (c - p)
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

--==============================================================================
-- BOTH JOINT FRAMES COME FROM ONE SOCKET
--
-- C0 is the socket in Part0's space and C1 the same point in Part1's, both
-- derived from where the parts were actually built. That is what makes the rest
-- pose the AUTHORED pose: ParentAnim composes onto C0, so a joint that starts
-- wrong stays wrong for the whole cycle, and no amount of animation fixes it.
--==============================================================================
local function socketMotor(name: string, part0: BasePart, part1: BasePart,
	socket: CFrame): Motor6D
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

--==============================================================================
function MiremawModel.Build(cf: CFrame, height: number, parent: Instance): Model
	local model = Instance.new("Model")
	model.Name = "Parent_tanglemire"
	model:SetAttribute("BiomeId", "tanglemire")
	model:SetAttribute("Species", "miremaw")
	model:SetAttribute("Asleep", true)
	model:SetAttribute("RigSeams",
		"Neck, JawJoint, LeftShoulder, RightShoulder, LeftHip, RightHip")
	model.Parent = parent

	local s = height / AUTHORED_HEIGHT

	--== THE GEOMETRY ==--
	local built: { [string]: BasePart } = {}
	for _, spec in ipairs(TanglemireForms.Miremaw) do
		local p: BasePart
		if spec.shape == "Wedge" then
			p = Instance.new("WedgePart")
		else
			local b = Instance.new("Part")
			b.Shape = SHAPE_BY_NAME[spec.shape] or Enum.PartType.Block
			p = b
		end
		p.Name = spec.name
		p.Size = spec.size * s
		p.CFrame = cf * scaled(spec.cf, s)
		p.Color = spec.color or Color3.new(1, 1, 1)
		p.Material = spec.material
		p.Transparency = spec.transparency or 0
		p.Reflectance = spec.reflectance or 0
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		-- Massless everywhere except the root: a massless part cannot anchor an
		-- assembly, and letting one of these become the AssemblyRootPart is how
		-- a Humanoid ends up walking from its own elbow.
		p.Massless = true
		for _, face in ipairs(STUD_FACES) do
			pcall(function()
				(p :: any)[face] = Enum.SurfaceType.Studs
			end)
		end
		p.Parent = model
		built[spec.name] = p
	end

	local torso = built.Torso
	if not torso then
		warn("[Seed/MiremawModel] approved geometry has no Torso; rig abandoned")
		return model
	end

	--==========================================================================
	-- THE ROOT
	--
	-- Invisible, not massless, and the PrimaryPart. It is placed at the torso's
	-- own centre so the assembly root sits inside the body's mass.
	--==========================================================================
	local rootY = torso.CFrame.Position.Y - cf.Position.Y
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = ROOT_SIZE * s
	root.CFrame = cf * CFrame.new(0, rootY, 0)
	root.Transparency = 1
	root.Anchored = false
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.Massless = false
	root.Parent = model
	model.PrimaryPart = root

	--==========================================================================
	-- THE TORSO IS THE ONLY COLLIDER
	--
	-- Same call Brambleback makes, for the same reason: a guardian with seventy
	-- collidable parts catches on every fence post and pod in the biome. One
	-- intentional collider, and everything else is silhouette.
	--==========================================================================
	torso.CanCollide = true

	--==========================================================================
	-- JOINTS WHERE SOMETHING MOVES, WELDS EVERYWHERE ELSE
	--
	-- RootJoint first, socketed at the MODEL ORIGIN rather than the torso
	-- centre, because the approved whole-body settle is a transform about the
	-- point the creature stands on. Put the socket anywhere else and the sleep
	-- pose has to be re-derived.
	--
	-- Then every seam in declaration order, which is also parent-before-child --
	-- the Neck exists before the Jaw that hangs off the Head, and the Throat
	-- before the ribs that ride it. A motor must exist before its group is
	-- welded, or the weld and the joint fight over the same part.
	--==========================================================================
	socketMotor("RootJoint", root, torso, cf)

	local claimed: { [BasePart]: boolean } = { [torso] = true }
	local madeSeams = 0
	for _, seam in ipairs(TanglemireForms.MiremawSeams) do
		local part0 = built[seam.part0]
		local driver = built[seam.driver]
		if part0 and driver then
			motor(seam.seam, part0, driver)
			claimed[driver] = true
			madeSeams += 1
			for _, memberName in ipairs(seam.members) do
				local member = built[memberName]
				if member then
					weldTo(driver, member)
					claimed[member] = true
				end
			end
		else
			warn(string.format(
				"[Seed/MiremawModel] seam %q wants %s -> %s and one is missing",
				seam.seam, seam.part0, seam.driver))
		end
	end

	-- The body itself, plus anything the map above did not claim. Welding the
	-- remainder rather than listing it means a part added to the approved set
	-- later arrives rigid on the torso instead of floating at the world origin.
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p ~= root and not claimed[p] then
			weldTo(torso, p)
		end
	end

	--==========================================================================
	-- THE HUMANOID
	--
	-- HipHeight is what holds the rig off the floor. Every part is
	-- CanCollide = false except the torso, so with no HipHeight the Humanoid
	-- sinks until that one collider rests on the ground and the legs bury.
	-- Derived from the root's own geometry so moving the root moves this too.
	--
	-- WalkSpeed stays 0. NestService sets it when the nest wakes; a guardian
	-- that spawns able to run is one that eventually will.
	--==========================================================================
	local humanoid = Instance.new("Humanoid")
	humanoid.HipHeight = (rootY - ROOT_SIZE.Y * 0.5 * s)
	humanoid.WalkSpeed = 0
	humanoid.AutoRotate = true
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	--==========================================================================
	-- THE APPROVED SLEEP POSE TRAVELS ON THE MODEL
	--
	-- Its translation scales with the creature and its rotation must not, and
	-- this builder is the only place that knows the scale factor. ParentAnim
	-- reads these and blends toward identity on the wake scalar.
	--
	-- Brambleback ships one whole-body CFrame; Miremaw needs a per-seam table
	-- because its sleeping pose is not one transform of a rigid body -- the
	-- head tucks, the arms brace, the fronds fold and the throat closes by
	-- different amounts. Stored as an attribute-free module lookup keyed by
	-- Species so no third parent has to pay for it.
	--==========================================================================
	model:SetAttribute("SleepBodyPose",
		scaled(TanglemireForms.MiremawSleep.RootJoint, s))
	model:SetAttribute("RigScale", s)

	CollectionService:AddTag(model, GameConfig.Tags.NestParent)

	--==========================================================================
	-- COUNTED, NOT ASSUMED
	--
	-- Seventy-three is the number the art was approved at. This file is a
	-- transcription, and a transcription that silently drops a toe is the kind
	-- of thing nobody notices until the silhouette looks subtly wrong weeks
	-- later.
	--==========================================================================
	local count = 0
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			count += 1
		end
	end
	if count ~= 73 then
		warn(("[Seed/MiremawModel] expected 73 parts, built %d"):format(count))
	end
	if madeSeams ~= #TanglemireForms.MiremawSeams then
		warn(("[Seed/MiremawModel] expected %d seams, made %d")
			:format(#TanglemireForms.MiremawSeams, madeSeams))
	end
	model:SetAttribute("MeasuredPartCount", count)

	return model
end

return MiremawModel
