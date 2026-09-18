--!strict
-- Steal a Seed :: ReachPoint
--
-- Where something you interact with should sit against an object that can be
-- far bigger than you are: a pod's hatch timer, the prompt stacked above it, and
-- a grown plant's PICK UP button.
--
--==============================================================================
-- WHY THIS IS ONE MODULE AND NOTHING BUT NUMBERS
--
-- Three scripts have to agree about these positions to the pixel, and none of
-- them owns the other two:
--
--   PlantUI      draws the pod's countdown
--   PromptUI     draws the Instant Hatch prompt stacked on top of it
--   PlantPickUI  draws the PICK UP button beside a grown plant
--
-- On a touch device the timer and the prompt are clamped back onto the screen
-- AS ONE GROUP, from two different LocalScripts, every frame. The only way two
-- scripts land on the same answer without talking to each other is to ask the
-- same function the same question -- so the function lives here, it takes
-- plain values rather than instances, and it builds nothing. That is also what
-- lets ReachPointSpec drive every branch of it without a Play session.
--
--==============================================================================
-- THE MEASUREMENTS THAT STARTED IT, 2026-09-18, PRODUCTION BUILDER
--
--   pod timer centre, studs above the soil     Tiny 3.6   Colossal 15.6
--   PICK UP button, Colossal Nubkin            36.6
--   PICK UP button, Colossal Bellchime         48.0
--   PICK UP button, Colossal Supernovus        68.2  (footprint radius 41.8)
--
-- Every one of those was placed ABOVE THE OBJECT'S TOP -- right for something
-- you look down at, and off the top of the screen for something you stand next
-- to and look up at. That is the whole defect this module exists to undo.
--==============================================================================

local ReachPoint = {}

--==============================================================================
-- THE BOX, REDUCED TO WHAT IS NEEDED
--
-- An oriented box's extent along any direction is the sum of its three half
-- sizes, each weighted by how far that axis leans into the direction -- the
-- same identity GameConfig.topOfModel uses for height. No corners are built and
-- nothing is allocated, which matters because PlantUI and PromptUI call into
-- this every frame on a phone.
--
-- IT DOES NOT CARE HOW THE BOX IS ROLLED. A pod's pivot is a cylinder turned
-- ninety degrees, so its box comes back with X and Y swapped; weighting every
-- axis by its projection gives the right answer either way.
--==============================================================================
local function extentAlong(boxCF: CFrame, boxSize: Vector3, dir: Vector3): number
	return math.abs(boxCF.RightVector:Dot(dir)) * boxSize.X * 0.5
		+ math.abs(boxCF.UpVector:Dot(dir)) * boxSize.Y * 0.5
		+ math.abs(boxCF.LookVector:Dot(dir)) * boxSize.Z * 0.5
end

-- The lowest point of the box -- for anything standing in a bed, the soil.
function ReachPoint.lowestY(boxCF: CFrame, boxSize: Vector3): number
	return boxCF.Position.Y - extentAlong(boxCF, boxSize, Vector3.yAxis)
end

-- How far the box reaches from its centre along a HORIZONTAL unit direction:
-- the edge of its footprint on that side.
function ReachPoint.reachAlong(boxCF: CFrame, boxSize: Vector3, dir: Vector3): number
	return extentAlong(boxCF, boxSize, dir)
end

--==============================================================================
-- THE POD'S TIMER: A CEILING ON HOW HIGH IT SITS
--
-- `topAboveAnchor` is GameConfig.topOfModel -- the model's top, measured from
-- its anchor part -- and `anchorAboveSoil` is how high that anchor stands. The
-- old rule was the first plus LiftStuds; the new one is that, or the ceiling,
-- whichever is LOWER, so no pod that already fitted under the ceiling moves by
-- so much as a hundredth of a stud.
--
-- Floored at the anchor itself. A pod whose anchor stood above the ceiling --
-- none does -- would get its label on its centre, not under it.
--==============================================================================
function ReachPoint.podLabelLift(topAboveAnchor: number, anchorAboveSoil: number,
	liftStuds: number, maxAboveSoil: number): number
	local wanted = topAboveAnchor + liftStuds
	local ceiling = maxAboveSoil - anchorAboveSoil
	return math.max(0, math.min(wanted, ceiling))
end

--==============================================================================
-- THE TIMER AND THE PROMPT ABOVE IT, ON A TOUCH SCREEN, AS ONE GROUP
--
-- `anchor` is where the timer's centre projects to, in WINDOW space (both
-- touch layers are IgnoreGuiInset, so the topbar is inside these numbers and
-- `topInset` says how much of the window it takes). The prompt stands above the
-- timer by half of each and a gap -- the stack PromptUI has always drawn.
--
-- CLAMPED TOGETHER, NEVER APART. If the group would leave the top of the screen
-- -- the tall-pod case -- the whole group comes down until the prompt clears the
-- topbar; if it would leave the bottom, the whole group goes up. Moving them as
-- one is the entire guarantee that the timer never lands on the prompt: they
-- keep their stacked distance whatever the clamp does.
--
-- Across, each keeps itself on screen by its own width. They share a centre
-- line unless one of them is pressed against a side edge, and even then the
-- vertical stack keeps them apart.
--
-- Returns the timer's centre and the prompt's centre, both window space.
--==============================================================================
local function clampAxis(x: number, half: number, span: number, margin: number): number
	local lo, hi = half + margin, span - half - margin
	if lo > hi then
		return span * 0.5
	end
	return math.clamp(x, lo, hi)
end

function ReachPoint.stack(anchor: Vector2, viewport: Vector2, topInset: number,
	label: Vector2, prompt: Vector2, gap: number, margin: number): (Vector2, Vector2)
	local raise = label.Y * 0.5 + gap + prompt.Y * 0.5
	local groupTop = anchor.Y - raise - prompt.Y * 0.5
	local groupBottom = anchor.Y + label.Y * 0.5
	local minTop = topInset + margin
	local maxBottom = viewport.Y - margin

	local shift = 0
	if groupTop < minTop then
		shift = minTop - groupTop
	elseif groupBottom > maxBottom then
		shift = maxBottom - groupBottom
	end
	local y = anchor.Y + shift

	local labelX = clampAxis(anchor.X, label.X * 0.5, viewport.X, margin)
	local promptX = clampAxis(anchor.X, prompt.X * 0.5, viewport.X, margin)
	return Vector2.new(labelX, y), Vector2.new(promptX, y - raise)
end

--==============================================================================
-- WHICH SIDE OF THE PLANT, WITHOUT FLICKING
--
-- `prev` is the bearing the button is on now and `want` is the bearing to the
-- player now, both horizontal unit vectors or nil. The button only follows once
-- the player has come round by more than the dead band, so walking straight
-- through the plant's centreline -- where the bearing swings half a circle in a
-- stride -- moves it once instead of every poll.
--==============================================================================
function ReachPoint.bearing(prev: Vector3?, want: Vector3?, deadbandDegrees: number): Vector3?
	if want == nil then
		return prev
	end
	if prev == nil then
		return want
	end
	if prev:Dot(want) >= math.cos(math.rad(deadbandDegrees)) then
		return prev
	end
	return want
end

-- The horizontal unit vector from `from` toward `to`, or nil when they are
-- stacked on top of each other and there is no "toward".
function ReachPoint.toward(from: Vector3, to: Vector3): Vector3?
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if flat.Magnitude < 0.01 then
		return nil
	end
	return flat.Unit
end

--==============================================================================
-- THE PICK UP BUTTON
--
-- SHORT PLANTS KEEP WHAT THEY HAD: base + height + 0.8, straight up, centred.
-- "Short" is exactly that point landing at or under InteractHeight above the
-- soil -- a head the player can already see over.
--
-- TALL PLANTS get it at the edge of their footprint on the player's side, at a
-- person's height above the soil:
--
--   * the edge comes from the plant's OWN box, measured every poll, so a wide
--     Supernovus and a narrow Bellchime each get their own distance and a plant
--     turning in place is re-measured as it turns;
--   * never beyond the player -- somebody standing inside a huge footprint gets
--     it StandOff in front of them, not behind them;
--   * and never off the bed: it is clamped inside the soil's own rectangle, so
--     it cannot sit on a fence, the road or a neighbour's plot however the
--     player is standing.
--
-- `dir` is already the dead-banded bearing; this does not choose sides, it only
-- measures along the one it is given.
--==============================================================================
export type Reach = {
	InteractHeight: number,
	EdgeMargin: number,
	StandOff: number,
	SoilInset: number,
}

local function clampToSoil(point: Vector3, soilCF: CFrame, soilSize: Vector3,
	inset: number): Vector3
	-- A bed is a flat, upright slab. One that is not is not something to clamp
	-- against, and leaving the point alone is better than folding it.
	if math.abs(soilCF.UpVector.Y) < 0.9 then
		return point
	end
	local here = soilCF:PointToObjectSpace(point)
	local hx = math.max(soilSize.X * 0.5 - inset, 0)
	local hz = math.max(soilSize.Z * 0.5 - inset, 0)
	local held = soilCF:PointToWorldSpace(Vector3.new(
		math.clamp(here.X, -hx, hx), here.Y, math.clamp(here.Z, -hz, hz)))
	return Vector3.new(held.X, point.Y, held.Z)
end

function ReachPoint.pickupPoint(boxCF: CFrame, boxSize: Vector3, height: number,
	base: Vector3, playerAt: Vector3?, dir: Vector3, soilCF: CFrame?, soilSize: Vector3?,
	reach: Reach): (Vector3, boolean)
	local soilY = ReachPoint.lowestY(boxCF, boxSize)
	local overHead = base.Y + height + 0.8
	if overHead - soilY <= reach.InteractHeight then
		return Vector3.new(base.X, overHead, base.Z), false
	end

	local centre = boxCF.Position
	local out = ReachPoint.reachAlong(boxCF, boxSize, dir) + reach.EdgeMargin
	if playerAt then
		local apart = Vector3.new(playerAt.X - centre.X, 0, playerAt.Z - centre.Z).Magnitude
		out = math.min(out, math.max(apart - reach.StandOff, 0))
	end
	local point = Vector3.new(centre.X + dir.X * out, soilY + reach.InteractHeight,
		centre.Z + dir.Z * out)
	if soilCF and soilSize then
		point = clampToSoil(point, soilCF, soilSize, reach.SoilInset)
	end
	return point, true
end

return ReachPoint
