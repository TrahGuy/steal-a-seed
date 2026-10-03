--!strict
-- Steal a Seed :: SecretModel
--
-- Replays a SecretForms entry -- the owner's hand-inserted secret pods and
-- plants -- part for part, joint for joint, at the size it was authored.
--
-- NOT a *Service. Geometry only, like CreatureModel, which is the one caller:
-- BuildCreature routes Snarlbloom and Petalfawn here by species id, BuildPod
-- routes their two pods.
--
--==============================================================================
-- ANCHORED, AND THE JOINTS ARE DATA
--
-- Every part comes out anchored with collisions, queries and touches off, which
-- is the contract every plant in this game already keeps (PlantFormsSpec,
-- HatchFX's scrub, giveTool's welds, PlantSway's CFrame writes all assume it).
-- The Motor6Ds and Welds are replayed with the inserted C0/C1 so the joint
-- relationships survive verbatim -- but between anchored parts they move
-- nothing. SecretIdle (client) reads them as a kinematic tree and poses the
-- parts itself, so the idle the owner authored plays on every client without
-- a physics assembly, a server script, or Motor6D.Transform (which does not
-- replicate and which any Animator overwrites -- see ParentAnim's banner).
--
-- ONE SIZE. The spec is replayed at scale 1 whatever the tier: random sizes are
-- a later feature. The CFrame handed in is the BASE, the same contract as both
-- CreatureModel builders.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local SecretForms = require(Shared:WaitForChild("SecretForms"))
-- The Rain Event's supplied pods, creatures and guardian (2026-10-02): the same
-- kind of data, replayed by the same code. A form id is looked up in both.
local RainForms = require(Shared:WaitForChild("RainForms"))

local SecretModel = {}

local function plantSpec(formId: string): SecretForms.FormSpec?
	return SecretForms.Plants[formId] or RainForms.Plants[formId]
end

local function podSpec(formId: string): SecretForms.FormSpec?
	return SecretForms.Pods[formId] or RainForms.Pods[formId]
end

-- The tag SecretIdle animates by. HatchFX's scrub and the hotbar's preview strip
-- every tag, which is right: a reveal copy and a viewport copy stay still.
SecretModel.RIG_TAG = "SecretRig"
-- The attribute that says which spec a model came from, for specs and the client.
SecretModel.FORM_ATTRIBUTE = "SecretForm"
-- The attribute on the one part a plant's joint tree is rooted at (BuildPlant).
SecretModel.ROOT_ATTRIBUTE = "RigRoot"

local SHAPES: { [string]: Enum.PartType } = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}

local function surfaces(part: BasePart, studs: boolean)
	local kind = if studs then Enum.SurfaceType.Studs else Enum.SurfaceType.Smooth
	part.TopSurface = kind
	part.BottomSurface = kind
	part.LeftSurface = kind
	part.RightSurface = kind
	part.FrontSurface = kind
	part.BackSurface = kind
end

-- `loose`: unanchored and massless, for a rig a Humanoid moves (the Rain Event's
-- guardian). Everything else is anchored, the plant contract.
local function makePart(spec: SecretForms.PartSpec, cf: CFrame, parent: Instance, loose: boolean?): BasePart
	local part: BasePart
	if spec.s == "Wedge" then
		part = Instance.new("WedgePart")
	else
		local p = Instance.new("Part")
		p.Shape = SHAPES[spec.s] or Enum.PartType.Block
		part = p
	end
	part.Name = spec.n
	part.Size = spec.z
	part.CFrame = cf * spec.cf
	part.Color = spec.c
	part.Material = spec.m
	part.Transparency = spec.t or 0
	part.Reflectance = spec.r or 0
	part.CastShadow = spec.cs ~= false
	surfaces(part, spec.st ~= false)
	part.Anchored = loose ~= true
	if loose == true then
		part.Massless = true
	end
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	if spec.a then
		for key, value in pairs(spec.a) do
			part:SetAttribute(key, value)
		end
	end
	part.Parent = parent
	return part
end

-- Every emitter property the generator recorded, by its spec key.
local EMITTER_FIELDS: { { string } } = {
	{ "rate", "Rate" }, { "enabled", "Enabled" }, { "lifetime", "Lifetime" }, { "speed", "Speed" },
	{ "size", "Size" }, { "transparency", "Transparency" }, { "color", "Color" },
	{ "lightEmission", "LightEmission" }, { "lightInfluence", "LightInfluence" }, { "texture", "Texture" },
	{ "spread", "SpreadAngle" }, { "acceleration", "Acceleration" }, { "rotation", "Rotation" },
	{ "rotSpeed", "RotSpeed" }, { "drag", "Drag" }, { "emissionDirection", "EmissionDirection" },
	{ "zOffset", "ZOffset" }, { "brightness", "Brightness" }, { "squash", "Squash" },
	{ "orientation", "Orientation" }, { "lockedToPart", "LockedToPart" },
	{ "velocityInheritance", "VelocityInheritance" }, { "shape", "Shape" }, { "shapeInOut", "ShapeInOut" },
	{ "shapeStyle", "ShapeStyle" }, { "timeScale", "TimeScale" },
}

--==============================================================================
-- THE REPLAY
--
-- Parts in index order (joints point at them by index), then the joints inside
-- the parts they were authored in, then attachments, lights and emitters, then
-- the model's own attributes. Returns the parts, index-aligned with the spec.
--==============================================================================
function SecretModel.Replay(spec: SecretForms.FormSpec, cf: CFrame, model: Model, loose: boolean?): { BasePart }
	local parts: { BasePart } = table.create(#spec.Parts)
	for i, p in ipairs(spec.Parts) do
		parts[i] = makePart(p, cf, model, loose)
	end
	for _, j in ipairs(spec.Joints) do
		local a, b = parts[j.a], parts[j.b]
		if a and b then
			local joint = Instance.new(j.k) :: any
			joint.Name = j.n
			joint.Part0 = a
			joint.Part1 = b
			joint.C0 = j.c0
			joint.C1 = j.c1
			joint.Parent = parts[j.h] or model
		end
	end
	local attachments: { Attachment } = {}
	for i, at in ipairs(spec.Attachments) do
		local host = parts[at.p]
		if host then
			local inst = Instance.new("Attachment")
			inst.Name = at.n
			inst.CFrame = at.cf
			inst.Parent = host
			attachments[i] = inst
		end
	end
	for _, l in ipairs(spec.Lights) do
		local host = parts[l.p]
		if host then
			local light = Instance.new("PointLight")
			light.Name = l.n
			light.Range = l.range
			light.Brightness = l.brightness
			light.Color = l.color
			light.Shadows = l.shadows
			light.Enabled = l.enabled
			if l.a then
				for key, value in pairs(l.a) do
					light:SetAttribute(key, value)
				end
			end
			light.Parent = host
		end
	end
	for _, e in ipairs(spec.Emitters) do
		local host: Instance? = if e.at then attachments[e.at] else parts[e.p]
		if host then
			local emitter = Instance.new("ParticleEmitter") :: any
			emitter.Name = e.n
			for _, pair in ipairs(EMITTER_FIELDS) do
				local value = e[pair[1]]
				if value ~= nil then
					emitter[pair[2]] = value
				end
			end
			emitter.Parent = host
		end
	end
	-- Trails and billboards: only the Rain Event's guardian has them (its run
	-- trails and its snore). Off and hidden as supplied; its animator turns them.
	for _, tr in ipairs(spec.Trails or {}) do
		local a0, a1 = attachments[tr.a0], attachments[tr.a1]
		local host = parts[tr.h] or (if a0 then a0.Parent else nil)
		if a0 and a1 and host then
			local trail = Instance.new("Trail")
			trail.Name = tr.n
			trail.Attachment0 = a0
			trail.Attachment1 = a1
			trail.Lifetime = tr.lifetime
			trail.MinLength = tr.minLength
			trail.MaxLength = tr.maxLength
			trail.Color = tr.color
			trail.Transparency = tr.transparency
			trail.WidthScale = tr.widthScale
			trail.LightEmission = tr.lightEmission
			trail.LightInfluence = tr.lightInfluence
			trail.Brightness = tr.brightness
			trail.FaceCamera = tr.faceCamera
			trail.Texture = tr.texture
			trail.TextureLength = tr.textureLength
			trail.TextureMode = tr.textureMode
			trail.Enabled = tr.enabled
			trail.Parent = host
		end
	end
	for _, b in ipairs(spec.Billboards or {}) do
		local host = parts[b.p]
		if host then
			local gui = Instance.new("BillboardGui")
			gui.Name = b.n
			gui.Size = b.size
			gui.StudsOffset = b.offset
			gui.StudsOffsetWorldSpace = b.worldOffset
			gui.AlwaysOnTop = b.alwaysOnTop
			gui.MaxDistance = b.maxDistance
			gui.LightInfluence = b.lightInfluence
			gui.Enabled = b.enabled
			for _, l in ipairs(b.labels) do
				local label = Instance.new("TextLabel")
				label.Name = l.n
				label.Text = l.text
				label.Size = l.size
				label.Position = l.position
				label.AnchorPoint = l.anchor
				label.TextSize = l.textSize
				label.Font = l.font
				label.TextColor3 = l.color
				label.TextTransparency = l.transparency
				label.TextStrokeColor3 = l.strokeColor
				label.TextStrokeTransparency = l.strokeTransparency
				label.BackgroundTransparency = l.background
				label.TextScaled = l.scaled
				label.ZIndex = l.z
				label.Parent = gui
			end
			gui.Parent = host
		end
	end
	for key, value in pairs(spec.Attributes) do
		model:SetAttribute(key, value)
	end
	return parts
end

--==============================================================================
-- A PLANT: the parts hang off the invisible contract Base that BuildCreature
-- already made at `cf`; the authored plate is a part called Footing. Tagged for
-- the client animator LAST, like every tag in this project.
--==============================================================================
function SecretModel.BuildPlant(formId: string, cf: CFrame, model: Model): boolean
	local spec = plantSpec(formId)
	if not spec then
		return false
	end
	local parts = SecretModel.Replay(spec, cf, model)
	-- THE AUTHORED ROOT, MARKED (2026-10-02). SecretIdle builds its joint tree
	-- from this part. It used to look for a part called Footing and otherwise take
	-- the first jointed part in GetDescendants order -- an order a client receives
	-- however replication delivered it: in Play a Tempestoak's tree started at an
	-- antler, and its legs flailed. The attribute travels with the part.
	local root = parts[if spec.Base and spec.Base > 0 then spec.Base else 1]
	if root then
		root:SetAttribute(SecretModel.ROOT_ATTRIBUTE, true)
	end
	model:SetAttribute(SecretModel.FORM_ATTRIBUTE, formId)
	CollectionService:AddTag(model, SecretModel.RIG_TAG)
	return true
end

--==============================================================================
-- A POD: the same, plus an invisible Shell AT THE BASE as the PrimaryPart. Every
-- pod consumer hangs off the PrimaryPart -- the Take prompt (11 studs from it),
-- the carry weld, the hatch hold -- and the authored pods are 21 and 40 studs
-- tall, so a shell at their centre would put the prompt out of reach and the
-- grip through the roof. At the base, the overhead carry lifts the whole thing
-- by its foot and the prompt is where the player stands.
--==============================================================================
function SecretModel.BuildPod(formId: string, cf: CFrame, model: Model): BasePart?
	local spec = podSpec(formId)
	if not spec then
		return nil
	end
	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Size = Vector3.new(1, 0.2, 1)
	shell.CFrame = cf * CFrame.new(0, 0.1, 0)
	shell.Transparency = 1
	shell.Anchored = true
	shell.CanCollide = false
	shell.CanQuery = false
	shell.CanTouch = false
	shell.Parent = model
	SecretModel.Replay(spec, cf, model)
	model:SetAttribute(SecretModel.FORM_ATTRIBUTE, formId)
	return shell
end

-- The authored height and footprint of a form, for the carry camera and the
-- placement checks; nil for an id this file does not know.
function SecretModel.Size(formId: string): Vector3?
	local spec = plantSpec(formId) or podSpec(formId)
	return if spec then spec.Size else nil
end

-- Whether a form id names one of the Rain Event's (for the client animator,
-- which drives these and the Secrets with different tables).
function SecretModel.IsRainForm(formId: string): boolean
	return RainForms.Plants[formId] ~= nil
end

-- Whether this file can build a plant, or a pod, for the id: CreatureModel's
-- routing question, asked of both supplied sets.
function SecretModel.HasPlant(formId: string): boolean
	return plantSpec(formId) ~= nil
end

function SecretModel.HasPod(formId: string): boolean
	return podSpec(formId) ~= nil
end

return SecretModel
