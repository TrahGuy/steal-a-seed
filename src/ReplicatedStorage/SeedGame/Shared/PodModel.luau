--!strict
-- Steal a Seed :: PodModel
--
-- Builds one of the owner's 25 pods (PodForms) at a tier's size, for
-- CreatureModel.BuildPod -- the one pod builder every nest, loose pod, carry,
-- bank, Bag, hatch, haul and debug call goes through.
--
-- NOT a *Service. Geometry only, like SecretModel, whose replay it uses.
--
--==============================================================================
-- THE CONTRACT EVERY POD KEEPS (CreatureModel.BuildPod's)
--
--   * named Pod_<id>, with SpeciesId, Rarity, Tier and Stage = 1 (the caller
--     writes them before this runs);
--   * `cf` is the BASE: the bottom centre;
--   * the PrimaryPart is an invisible upright part called "Shell", standing
--     where the old pods' shell stood: its centre half a D up (the carry grip
--     holds it D/2 + 0.85 in front of the body, the guardian haul builds the pod
--     D/2 below it, the prompts hang 2.4 above it), or the pod's middle when the
--     pod is shorter than D. It is the pod's footprint wide and min(D, height)
--     tall, so the hold's dust and the nest's queries fill the pod's body. The
--     carry pose is its axes;
--   * every part anchored, with CanCollide, CanQuery and CanTouch off (the nest
--     turns CanQuery on for taking; carrying unanchors, welds and makes massless);
--   * no text anywhere; PickupSound "ColossalPickup" at Colossal.
--
-- THE SIZE COLOUR. A lid pod's own SizeSeam parts take the tier's colour. A pod
-- with none (the 12 studded pods and Bogbonnet) shows its size by its scale
-- alone: the slim ring planned round its foot would read as the base the owner
-- had taken off (2026-10-09), so there is none. The pod itself is not touched.
--
-- THE TOP TWO TIERS keep what they had: Titan the vent's trail and the aura,
-- Colossal a glowing Neon core with its light and the stronger aura (the core at
-- the Shell's centre, inside the pod, so the owner's outline is unchanged). A
-- pale pod's Colossal lights are softer (GameConfig.PodModels.PaleGlow).
--
-- NO SHADOWS (2026-10-09, the owner's approval): no light on a built pod casts
-- them. Sixteen of the owner's did (ten fill lights, six of the pods' own); the
-- data keeps the owner's record.
--
-- IT MOVES ON THE CLIENT. The owner's per-pod Scripts were not imported; this
-- tags the model for PodMotion (client) LAST, with the form, the factor and the
-- root's rest written on it first.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local SecretModel = require(Shared:WaitForChild("SecretModel"))
local PodForms = require(Shared:WaitForChild("PodForms"))

local CFG = GameConfig.PodModels

local PodModel = {}

-- The tag PodMotion animates by, put on last.
PodModel.TAG = CFG.Tag :: string
-- On the model: which PodForms pod, and the whole-model factor it was built at.
PodModel.FORM_ATTRIBUTE = CFG.FormAttribute :: string
PodModel.SCALE_ATTRIBUTE = "PodScale"
-- On the owner's root part (the one its idle moved), and on the model the root's
-- rest in the Shell's frame: what PodMotion poses from, never a pose it wrote.
PodModel.ROOT_ATTRIBUTE = "PodRoot"
PodModel.REST_ATTRIBUTE = "PodRootRest"
-- The Colossal's core.
PodModel.CORE = "Core"

-- The colours a tier wears, from CreatureModel (which owns the biome palette).
export type Look = {
	color: Color3, -- the tier's colour (SeedData.ColorForTier)
	accent: Color3, -- the biome's accent: the aura's tail
	focal: Color3, -- the biome's focal: the vent trail's tail
	coreColor: Color3, -- the Colossal core's colour
	coreGlow: Color3, -- its light's and aura's colour
}

function PodModel.Has(id: string?): boolean
	return PodForms.Has(id)
end

local function inert(p: BasePart)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
end

--==============================================================================
-- THE TIER EFFECTS, SHARED WITH CreatureModel's OWN PODS
--
-- An aura is a field, not a sparkle: a slow wide swell that breathes on its own
-- (no driver, so it cannot stop when a script does) and a light that makes the
-- pod affect the ground it sits on. Sized off D, so a Colossal's aura is a
-- Colossal's. ONE recipe for every pod, at two strengths: two hand-rolled
-- emitters drifted apart once already.
--==============================================================================
-- `lightReach` scales the light's reach alone (a pale pod's, PaleGlow); 1 if
-- left out.
function PodModel.AddAura(host: BasePart, D: number, hue: Color3, tail: Color3, reach: number, rate: number,
	bright: number, lightReach: number?): ParticleEmitter
	local att = Instance.new("Attachment")
	att.Name = "AuraAttachment"
	att.Position = Vector3.new(0, 0, 0)
	att.Parent = host

	local halo = Instance.new("ParticleEmitter")
	halo.Name = "AuraPulse"
	halo.Color = ColorSequence.new(hue, tail)
	halo.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, D * 0.30 * reach),
		NumberSequenceKeypoint.new(1, D * 1.30 * reach),
	})
	-- In at the start, out at the end: a swell, not a pop.
	halo.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0.62),
		NumberSequenceKeypoint.new(1, 1),
	})
	halo.Lifetime = NumberRange.new(2.2, 2.6)
	-- Slow. One swell a second is a heartbeat; five is a strobe.
	halo.Rate = rate
	halo.Speed = NumberRange.new(0, 0)
	halo.LightEmission = 1
	halo.LightInfluence = 0
	halo.Parent = att

	local glow = Instance.new("PointLight")
	glow.Name = "AuraGlow"
	glow.Color = hue
	glow.Brightness = bright
	glow.Range = D * 2.0 * reach * (lightReach or 1)
	glow.Shadows = false
	glow.Parent = host
	return halo
end

-- A pod's own brightness: the mean luminance (Rec. 709 weights) of its visible
-- parts, each weighed by its surface area and opacity. 0 is black, 1 white.
function PodModel.Brightness(parts: { BasePart }): number
	local sum, weight = 0, 0
	for _, p in ipairs(parts) do
		if p.Transparency < 0.99 then
			local s = p.Size
			local area = 2 * (s.X * s.Y + s.Y * s.Z + s.Z * s.X) * (1 - p.Transparency)
			local c = p.Color
			sum += (0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B) * area
			weight += area
		end
	end
	return if weight > 0 then sum / weight else 0
end

-- What a Colossal's lights keep at a brightness (PaleGlow): their strength's
-- share and their reach's.
function PodModel.GlowFor(brightness: number): (number, number)
	local P = CFG.PaleGlow
	local t = math.clamp((brightness - P.From) / (P.To - P.From), 0, 1)
	return 1 - t * (1 - P.Floor), 1 - t * (1 - P.RangeFloor)
end

-- The Titan's vent: a restrained trail rising off the top, punctuation rather
-- than a fire. An emitter animates itself, so the pod needs no driver.
function PodModel.AddVent(host: BasePart, position: Vector3, D: number, color: ColorSequence): ParticleEmitter
	local att = Instance.new("Attachment")
	att.Name = "EmberVent"
	att.Position = position
	att.Parent = host
	local em = Instance.new("ParticleEmitter")
	em.Name = "EmberTrail"
	em.Color = color
	em.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, D * 0.05),
		NumberSequenceKeypoint.new(0.4, D * 0.11),
		NumberSequenceKeypoint.new(1, 0),
	})
	em.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	em.Lifetime = NumberRange.new(0.9, 1.6)
	em.Rate = 7
	em.Speed = NumberRange.new(D * 0.10, D * 0.22)
	em.Acceleration = Vector3.new(0, D * 0.30, 0)
	em.SpreadAngle = Vector2.new(16, 16)
	em.LightEmission = 1
	em.LightInfluence = 0
	em.Parent = att
	return em
end

--==============================================================================
-- ONE POD
--
-- Returns the Shell (the PrimaryPart to be), or nil for a species with no
-- owner's pod. `look` is the tier's colours (CreatureModel.BuildPod's).
--==============================================================================
function PodModel.Build(sp: SeedData.Species, tier: number, cf: CFrame, model: Model, look: Look): BasePart?
	local id = sp.Id
	local spec = PodForms.Pods[id]
	local scale = PodForms.Scale(id, tier)
	if not (spec and scale) then
		return nil
	end
	local D = SeedData.PodDiameter(tier)
	local size = spec.Size * scale

	-- The owner's pod, part for part, at the tier's size (stud tiles too).
	local parts = SecretModel.Replay(spec, cf, model, nil, scale, true)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("Light") then
			d.Shadows = false
		end
	end

	local tall = math.min(D, size.Y)
	local shell = Instance.new("Part")
	shell.Name = "Shell"
	shell.Size = Vector3.new(size.X, tall, size.Z)
	shell.CFrame = cf * CFrame.new(0, tall * 0.5, 0)
	shell.Transparency = 1
	shell.CastShadow = false
	inert(shell)
	shell.Parent = model

	-- What PodMotion poses from: the root, and where it rests in the Shell's frame.
	local root = parts[spec.Root or 1]
	if root then
		root:SetAttribute(PodModel.ROOT_ATTRIBUTE, true)
		model:SetAttribute(PodModel.REST_ATTRIBUTE, shell.CFrame:ToObjectSpace(root.CFrame))
	end
	model:SetAttribute(PodModel.FORM_ATTRIBUTE, id)
	model:SetAttribute(PodModel.SCALE_ATTRIBUTE, scale)

	--== THE SIZE COLOUR: a lid pod's own seam, and nothing added ==--
	for _, p in ipairs(parts) do
		if p:GetAttribute(SecretModel.GROUP_ATTRIBUTE) == "SizeSeam" then
			p.Color = look.color
		end
	end

	--== THE TOP TWO TIERS ==--
	if tier == 6 then
		-- Off the pod's top, in the Shell's frame.
		PodModel.AddVent(shell, Vector3.new(0, size.Y - tall * 0.5 + D * 0.03, 0), D,
			ColorSequence.new(look.color, look.focal))
		PodModel.AddAura(shell, D, look.color, look.accent, 0.78, 0.8, 1.1)
	elseif tier == 7 then
		local core = Instance.new("Part")
		core.Name = PodModel.CORE
		core.Shape = Enum.PartType.Ball
		local dia = D * CFG.CoreDiameter
		core.Size = Vector3.new(dia, dia, dia)
		core.CFrame = shell.CFrame
		core.Color = look.coreColor
		core.Material = Enum.Material.Neon
		core.TopSurface = Enum.SurfaceType.Smooth
		core.BottomSurface = Enum.SurfaceType.Smooth
		core.CastShadow = false
		inert(core)
		core.Parent = model
		-- Softer on a pale pod: both lights' strength and reach (PaleGlow).
		local strength, lightReach = PodModel.GlowFor(PodModel.Brightness(parts))
		local glow = Instance.new("PointLight")
		glow.Name = "CoreGlow"
		glow.Color = look.coreGlow
		glow.Brightness = 1.6 * strength
		glow.Range = D * 2.4 * lightReach
		glow.Shadows = false
		glow.Parent = core
		PodModel.AddAura(core, D, look.coreGlow, look.accent, 1.0, 1.4, 2.2 * strength, lightReach)
		-- For CarryService and SoundCues to read.
		model:SetAttribute("PickupSound", "ColossalPickup")
	end

	-- A client animates it, so it streams in and out whole, never part by part
	-- (2026-09-23: a part-by-part stream-out left walking plants' parts at the
	-- server's pose). A caller may set its own mode after.
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	-- The PrimaryPart before any tag: a tag's listener may read it at once.
	model.PrimaryPart = shell
	CollectionService:AddTag(model, PodModel.TAG)
	return shell
end

return PodModel
