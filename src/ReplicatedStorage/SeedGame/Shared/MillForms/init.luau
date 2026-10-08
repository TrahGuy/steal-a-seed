--!strict
--==============================================================================
-- THE MILL TIERS THE OWNER SUPPLIED, AS DATA (2026-10-06)
--
-- Four mills the owner placed in the Workspace as finished models -- tiers 11
-- to 14 -- lifted part for part, light and emitter, with every collision flag,
-- into one child module each by a read-only generator. The originals were not
-- moved or changed; verified .rbxm copies are in
-- output/model-backups/2026-10-06-mill-originals.
--
--     tier  model                      form
--     11    MillTier11AbyssalTrench    abyssaltrench   163 parts
--     12    MillTier12VolcanicForge    volcanicforge   127 parts
--     13    MillTier13FrozenAurora     frozenaurora    210 parts
--     14    MillTier14EventHorizon     eventhorizon    185 parts
--
-- THE SAME CHASSIS AS TIERS 1-10, EXACTLY: the Deck (11 x 1.2 x 19) at the
-- frame and the PrimaryPart, the belt `Treadmill` (8 x 1.4 x 16) at (0, 0.4,
-- 0), rollers at z +-8, the console and readout at -Z, the step at +Z. So the
-- mount, the payout's region test, the run cycle and the upgrade sign work on
-- them unchanged; what differs is everything bolted round that chassis.
--
-- THEIR MOTION. Each came with a client script (AbyssBrain, ForgeBrain,
-- GlacierBrain, SingularityBrain) that moved its decor every frame. Those are
-- not replayed: MillFormMotion plays the same motion from Ambience, only while
-- the mill is on screen, its chevrons at the belt's real speed.
--==============================================================================

local MillForms = {}

export type PartSpec = {
	n: string, -- name
	s: string, -- shape: Block | Ball | Cylinder
	z: Vector3, -- size
	cf: CFrame, -- relative to the Deck
	c: Color3,
	m: Enum.Material,
	t: number?, -- transparency, 0 when absent
	r: number?, -- reflectance, 0 when absent
	sf: { string }?, -- every face by name (Top Bottom Left Right Front Back) when they differ
	su: string?, -- the one SurfaceType of every face, when it is not Studs
	cs: boolean?, -- CastShadow unless false
	cc: boolean?, -- CanCollide when true
	ct: boolean?, -- CanTouch unless false
	cq: boolean?, -- CanQuery unless false
	an: boolean?, -- Anchored unless false
	mv: string?, -- MaterialVariant
	a: { [string]: any }?, -- attributes
}

export type LightSpec = {
	n: string, p: number, range: number, brightness: number, color: Color3, shadows: boolean, enabled: boolean,
	a: { [string]: any }?,
}

export type FormSpec = {
	Source: string,
	Tier: number,
	Script: string,
	Size: Vector3,
	Low: Vector3,
	High: Vector3,
	PartCount: number,
	Attributes: { [string]: any },
	Parts: { PartSpec },
	Lights: { LightSpec },
	Emitters: { { [string]: any } },
}

local function load(name: string): FormSpec
	return (require :: any)(script:WaitForChild(name))
end

-- Which tier replays which form. A tier with no entry here is built by
-- MillModel's own builders (1 to 10).
MillForms.ByTier = {
	[11] = "abyssaltrench",
	[12] = "volcanicforge",
	[13] = "frozenaurora",
	[14] = "eventhorizon",
} :: { [number]: string }

MillForms.Forms = {
	abyssaltrench = load("abyssaltrench"),
	volcanicforge = load("volcanicforge"),
	frozenaurora = load("frozenaurora"),
	eventhorizon = load("eventhorizon"),
} :: { [string]: FormSpec }

-- The attribute a replayed mill carries, so the client animator can find it.
MillForms.FORM_ATTRIBUTE = "MillForm"

function MillForms.FormOf(tier: number): string?
	return MillForms.ByTier[tier]
end

local SHAPES: { [string]: Enum.PartType } = {
	Block = Enum.PartType.Block,
	Ball = Enum.PartType.Ball,
	Cylinder = Enum.PartType.Cylinder,
}
local FACES = { "TopSurface", "BottomSurface", "LeftSurface", "RightSurface", "FrontSurface", "BackSurface" }

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
-- Parts in the order they were lifted (lights and emitters point at them by
-- index), each exactly as supplied -- flags included: the Deck, the belt and
-- the step collide and can be touched, as on every mill; most decor neither
-- collides nor takes touches. Then lights, emitters and the model's own
-- attributes. Returns the parts, index-aligned with the spec.
--==============================================================================
function MillForms.Build(formId: string, cf: CFrame, model: Model): { BasePart }
	local spec = MillForms.Forms[formId]
	assert(spec, "MillForms: no form " .. tostring(formId))
	local parts: { BasePart } = table.create(#spec.Parts)
	for i, p in ipairs(spec.Parts) do
		local part = Instance.new("Part")
		part.Shape = SHAPES[p.s] or Enum.PartType.Block
		part.Name = p.n
		part.Size = p.z
		part.CFrame = cf * p.cf
		part.Color = p.c
		part.Material = p.m
		if p.mv then
			part.MaterialVariant = p.mv
		end
		part.Transparency = p.t or 0
		part.Reflectance = p.r or 0
		part.CastShadow = p.cs ~= false
		if p.sf then
			for k, prop in ipairs(FACES) do
				local kind = (Enum.SurfaceType :: any)[p.sf[k]]
				if kind then
					(part :: any)[prop] = kind
				end
			end
		else
			local kind = if p.su then (Enum.SurfaceType :: any)[p.su] else Enum.SurfaceType.Studs
			for _, prop in ipairs(FACES) do
				(part :: any)[prop] = kind
			end
		end
		part.Anchored = p.an ~= false
		part.CanCollide = p.cc == true
		part.CanTouch = p.ct ~= false
		part.CanQuery = p.cq ~= false
		if p.a then
			for key, value in pairs(p.a) do
				part:SetAttribute(key, value)
			end
		end
		part.Parent = model
		parts[i] = part
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
		local host = parts[e.p]
		if host then
			local emitter = Instance.new("ParticleEmitter") :: any
			emitter.Name = e.n
			for _, pair in ipairs(EMITTER_FIELDS) do
				local value = e[pair[1]]
				if value ~= nil then
					emitter[pair[2]] = value
				end
			end
			if e.a then
				for key, value in pairs(e.a) do
					emitter:SetAttribute(key, value)
				end
			end
			emitter.Parent = host
		end
	end
	for key, value in pairs(spec.Attributes) do
		model:SetAttribute(key, value)
	end
	model:SetAttribute(MillForms.FORM_ATTRIBUTE, formId)
	return parts
end

-- Every form is the shared chassis: one Deck, one belt, one step, rollers at
-- its ends. Checked on load, because MillModel, TreadmillService and the mount
-- find these by name.
do
	for formId, spec in pairs(MillForms.Forms) do
		local counts: { [string]: number } = {}
		for _, p in ipairs(spec.Parts) do
			counts[p.n] = (counts[p.n] or 0) + 1
		end
		assert(counts.Deck == 1 and counts.Treadmill == 1 and counts.Step == 1,
			"MillForms." .. formId .. " needs exactly one Deck, one Treadmill and one Step")
		assert(#spec.Parts == spec.PartCount, "MillForms." .. formId .. " part count")
	end
end

return MillForms
