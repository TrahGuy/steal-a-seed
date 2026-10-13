--!strict
--==============================================================================
-- Steal a Seed :: EquipBestPad
--
-- EQUIP BEST WITHOUT THE MENUS (2026-10-13; Michael's console feedback, the
-- owner's backlog item 1): a step pad on the owner's own plot. Stand on it a
-- second, its ring fills, and the Garden menu's own EQUIP BEST is asked for.
--
-- Arithmetic and one builder, shared by EquipBestPad.client (which draws it on
-- this player's plot and sends the verb) and EquipBestPadSpec (which grows
-- every plot through every level around it):
--
--   localCFrame / cframeFor   where it stands, in the plot's frame / the world
--   onPad                     whether a root counts as standing on it
--   new / step / progress     the hold: fill, run once, cool down, and arm
--                             again only after the body has stepped off
--   lit                       how many of the ring's segments a fill lights
--   build                     its parts: anchored, and never collides, is
--                             touched, is queried or casts a shadow
--
-- Numbers: GameConfig.EquipBestPad.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local PAD = GameConfig.EquipBestPad
local PLOT = GameConfig.Plot

local EquipBestPad = {}

--==============================================================================
-- WHERE
--
-- In the plot's own frame (its centre; -Z faces the gate, +X is the wing's
-- side): on the left grass strip, halfway along the main bed. The bed is
-- centred on the frame at every level of every plot, so neither the level nor
-- the plot changes this; an upgrade moves the pad only by moving the frame
-- (the plot's PlotCF attribute).
--==============================================================================
function EquipBestPad.localCFrame(): CFrame
	return CFrame.new(-PLOT.Width * 0.5 + PAD.InsetX, 0, 0)
end

-- The pad's centre on the ground, in the world, for a plot centred at `plotCF`.
function EquipBestPad.cframeFor(plotCF: CFrame): CFrame
	return plotCF * EquipBestPad.localCFrame()
end

-- A root at `root` stands on the pad at `pad`: within TriggerRadius of its
-- centre across the ground, and no further under or over it than its reach.
function EquipBestPad.onPad(root: Vector3, pad: CFrame): boolean
	local d = pad:PointToObjectSpace(root)
	return Vector2.new(d.X, d.Z).Magnitude <= PAD.TriggerRadius
		and d.Y >= -PAD.ReachBelow and d.Y <= PAD.ReachAbove
end

--==============================================================================
-- THE HOLD
--
-- `held` is how long the body has stood on it this time; `spent` says it ran
-- and the body has not stepped off since; `coolUntil` is when it may run
-- again, on the caller's clock.
--==============================================================================
export type Hold = { held: number, spent: boolean, coolUntil: number }

function EquipBestPad.new(): Hold
	return { held = 0, spent = false, coolUntil = -math.huge }
end

-- One tick: whether the body is `on` the pad, `dt` since the last tick, `now`
-- on any steady clock. True exactly once per hold, when the fill reaches
-- HoldSeconds. Then nothing until the cooldown is over and the body has
-- stepped off and on again. Stepping off empties the fill; a slow frame adds
-- at most MaxStep to it.
function EquipBestPad.step(hold: Hold, on: boolean, dt: number, now: number): boolean
	if not on then
		hold.held = 0
		hold.spent = false
		return false
	end
	if hold.spent or now < hold.coolUntil then
		hold.held = 0
		return false
	end
	local add = if dt == dt then math.clamp(dt, 0, PAD.MaxStep) else 0
	hold.held += add
	if hold.held >= PAD.HoldSeconds then
		hold.held = 0
		hold.spent = true
		hold.coolUntil = now + PAD.CooldownSeconds
		return true
	end
	return false
end

-- How full the ring is (0 to 1), and how much of the cooldown is still to
-- run (0 to 1; 0 when it is not cooling).
function EquipBestPad.progress(hold: Hold, now: number): (number, number)
	local fill = math.clamp(hold.held / PAD.HoldSeconds, 0, 1)
	local cooling = if now < hold.coolUntil then math.clamp((hold.coolUntil - now) / PAD.CooldownSeconds, 0, 1) else 0
	return fill, cooling
end

-- How many of `segments` (the ring's own by default) a fill of 0 to 1 lights.
function EquipBestPad.lit(fill: number, segments: number?): number
	local n = segments or PAD.Segments
	local f = if fill == fill then fill else 0
	return math.clamp(math.floor(f * n + 1e-6), 0, n)
end

--==============================================================================
-- THE PARTS
--
-- A lit disc in EQUIP BEST's green, a dark band round it, and the ring's
-- segments on that band, first to last clockwise seen from above.
-- Flat on the ground (the plot has no floor of its own: the field's top is the
-- frame's Y). Every part is anchored and inert, so it never stops a runner or
-- catches a planting click, a prompt's line of sight or a camera ray.
--==============================================================================
export type Built = {
	model: Model,
	pad: BasePart,
	rim: BasePart,
	segments: { BasePart },
}

local function inert(name: string, size: Vector3, cframe: CFrame, colour: Color3, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = colour
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

function EquipBestPad.build(at: CFrame, parent: Instance): Built
	local model = Instance.new("Model")
	model.Name = "EquipBestPad"

	-- A Cylinder's axis is its X: a quarter turn about Z stands it up.
	local flat = CFrame.Angles(0, 0, math.rad(90))
	local rim = inert("Rim", Vector3.new(0.1, PAD.RimRadius * 2, PAD.RimRadius * 2),
		at * CFrame.new(0, 0.05, 0) * flat, PAD.RimColour, model)
	rim.Shape = Enum.PartType.Cylinder
	rim.Material = Enum.Material.SmoothPlastic
	local pad = inert("Pad", Vector3.new(0.14, PAD.PadRadius * 2, PAD.PadRadius * 2),
		at * CFrame.new(0, 0.07, 0) * flat, PAD.Colour, model)
	pad.Shape = Enum.PartType.Cylinder

	-- The segments stand on the band between the disc's edge and the rim's.
	local band = PAD.RimRadius - PAD.PadRadius
	local mid = PAD.PadRadius + band * 0.5
	local arc = math.pi * 2 * mid / PAD.Segments
	local segments: { BasePart } = {}
	for i = 1, PAD.Segments do
		local a = (i - 0.5) / PAD.Segments * math.pi * 2
		local seg = inert("Segment" .. i, Vector3.new(band * 0.75, 0.06, arc * 0.7),
			at * CFrame.Angles(0, -a, 0) * CFrame.new(mid, 0.13, 0), PAD.IdleColour, model)
		seg.Transparency = 0.55
		table.insert(segments, seg)
	end

	model.PrimaryPart = pad
	model.Parent = parent
	return { model = model, pad = pad, rim = rim, segments = segments }
end

return EquipBestPad
