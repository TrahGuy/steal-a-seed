--!strict
-- Steal a Seed :: BloomTrail (2026-10-04, the owner's Bloomrunner brief)
--
-- THE BLOOMRUNNER TRAIL'S LOOK AND ITS ARITHMETIC -- the pure half of TrailFX.
-- No instance is touched here: what each FX setting draws, how big one wearer's
-- pool is, where the two ribbons weave at a given distance travelled, the
-- shimmer's colour frames, when a petal or a bloom is due, and the curves they
-- fly and open by. TrailFX owns the instances and the one loop; BloomTrailSpec
-- checks every number here in Edit.
--
-- WHAT IT IS (the owner's art direction, in the Bloomrunner's own mint, gold
-- and leaf green, WheelData.Trail):
--
--   * two ribbons behind the runner -- one mint, one warm gold -- weaving gently
--     round each other. The weave is laid out by DISTANCE, so it is a shape on
--     the road behind them rather than a wobble in time, and it holds still when
--     they do;
--   * a soft band of light travelling along each ribbon, like sun on silk: one
--     slow continuous pass, never a flash;
--   * gold and mint petals that flutter, turn and fade behind them, laid by road
--     covered and capped in rate;
--   * now and then a small flower that opens on the wake, sheds its petals and
--     is gone.
--
-- All of it between the ankle and the waist, behind the body: clear of the
-- face, a carried pod, other players and anything on the ground ahead.
--==============================================================================

local BloomTrail = {}

--==============================================================================
-- WHAT EACH SETTING DRAWS, PER WEARER (every number is a ceiling)
--
--   Full      both ribbons, weaving and shimmering; up to 12 petals and 2
--             blooms (5 petals and a heart each) in the air at once.
--   Reduced   ONE shorter ribbon, still and unweaving -- no petals, no blooms.
--             Also what a player with reduced motion switched on gets.
--   Off       nothing is built at all.
--==============================================================================
BloomTrail.Budget = {
	Full = { Ribbons = 2, Petals = 12, Blooms = 2, BloomPetals = 5 },
	Reduced = { Ribbons = 1, Petals = 0, Blooms = 0, BloomPetals = 0 },
	Off = { Ribbons = 0, Petals = 0, Blooms = 0, BloomPetals = 0 },
}

-- The parts one wearer's pool holds in a mode: the loose petals, and each
-- bloom's petals plus its heart. Built once, when the trail goes on a body.
function BloomTrail.partsFor(mode: string): number
	local b = (BloomTrail.Budget :: any)[mode] or BloomTrail.Budget.Off
	return b.Petals + b.Blooms * (b.BloomPetals + 1)
end

-- Which of the three a player sees, from the Settings panel's FX quality and
-- the reduced-motion switch (StatusText.reducedMotion).
function BloomTrail.mode(quality: any, reducedMotion: boolean): string
	if quality == "Off" then
		return "Off"
	end
	if quality == "Reduced" or reducedMotion then
		return "Reduced"
	end
	return "Full"
end

BloomTrail.Look = {
	--== the ribbons ==--
	-- How long a ribbon's segment lasts, and its length cap in studs however
	-- fast the runner goes.
	RibbonSeconds = { Full = 0.75, Reduced = 0.42 },
	RibbonMaxLength = { Full = 24, Reduced = 10 },
	-- Root space, for a body whose root stands 3 studs off the floor (TrailFX
	-- scales by the real one): the band's centre is at mid-thigh, behind the
	-- body (+Z is behind).
	RibbonHeight = -1.3,
	RibbonBehind = 0.55,
	-- Half a ribbon's width at full presence, and how much wider at full
	-- energy; Reduced's one ribbon is a little wider, being alone.
	RibbonHalf = 0.34,
	RibbonHalfEnergy = 0.2,
	ReducedHalf = 0.42,
	-- The weave: one full turn of the pair every WeaveStuds of road, this far
	-- out from the centre line sideways (and 0.6 of it up and down).
	WeaveStuds = 9,
	WeaveAmplitude = 0.42,
	WeaveAmplitudeEnergy = 0.2,
	-- How fast the trail grows in when running starts and narrows away when it
	-- stops (presence per second).
	PresenceIn = 6,
	PresenceOut = 4,
	-- A turn swings the pair a little to the outside of it, as cloth would: this
	-- many studs per radian a second of turn, never more than TurnSwingMax.
	TurnSwingPerRad = 0.06,
	TurnSwingMax = 0.35,
	-- The shimmer: one slow pass of light along a ribbon every ShimmerSeconds,
	-- in ShimmerFrames precomputed steps; the light lifts the ribbon's own colour
	-- this far toward white, over this much of its length either side.
	ShimmerSeconds = 1.8,
	ShimmerFrames = 32,
	ShimmerLift = 0.38,
	ShimmerWidth = 0.14,

	--== energy: modest, bounded -- 0 at a walk, 1 at a sprint ==--
	EnergyFromSpeed = 18,
	EnergyToSpeed = 90,

	--== loose petals ==--
	-- One every PetalStuds of road (PetalStudsEnergy at full energy), never
	-- more than PetalMaxPerSecond, each living PetalLife seconds.
	PetalStuds = 2.6,
	PetalStudsEnergy = 1.8,
	PetalMaxPerSecond = 9,
	PetalLife = { 0.9, 1.3 },
	PetalSize = Vector3.new(0.5, 0.06, 0.3),
	-- The flight: a puff back and up as it leaves, a slow fall, a flutter
	-- sideways, and a turn about all three axes.
	PetalPuff = { 0.4, 1.1 },
	PetalSideways = 0.7,
	PetalLift = { 0.3, 0.8 },
	PetalDrag = 1.6,
	PetalFall = 1.4,
	PetalFlutter = 0.16,
	PetalFlutterRate = 7,
	PetalSpin = 4,

	--== blooms ==--
	-- One every BloomStuds of road (BloomStudsEnergy at full energy, give or
	-- take BloomJitterStuds), at least BloomMinSeconds apart; it opens, holds,
	-- and sheds, BloomBehindStuds behind the runner and BloomFloorHeight off the
	-- floor (ankle height).
	BloomStuds = 18,
	BloomStudsEnergy = 14,
	BloomJitterStuds = 6,
	BloomMinSeconds = 0.8,
	BloomOpen = 0.3,
	BloomHold = 0.25,
	BloomShed = 0.55,
	BloomBehindStuds = 3,
	BloomFloorHeight = 0.55,
	BloomPetalSize = Vector3.new(0.3, 0.05, 0.52),
	BloomHeart = 0.22,
	-- A bud's petals stand this far off flat; an open flower's this far.
	BloomClosedTilt = math.rad(75),
	BloomOpenTilt = math.rad(14),
	BloomSpin = 0.7,
	BloomRise = 0.12,
	BloomShedOut = 0.9,
	BloomShedFall = 0.7,
}
local L = BloomTrail.Look

function BloomTrail.bloomSeconds(): number
	return L.BloomOpen + L.BloomHold + L.BloomShed
end

--==============================================================================
-- ENERGY: HOW MUCH LIVELIER THE TRAIL IS AT SPEED, 0..1 AND NO MORE
--==============================================================================
function BloomTrail.energy(speed: number): number
	if speed ~= speed then
		return 0
	end
	return math.clamp((speed - L.EnergyFromSpeed) / (L.EnergyToSpeed - L.EnergyFromSpeed), 0, 1)
end

--==============================================================================
-- THE WEAVE: WHERE A RIBBON'S BAND IS, AND HOW WIDE
--
-- `which` is 1 for the mint ribbon and 2 for the gold one, half a turn apart, so
-- they cross and re-cross -- one passing over while the other passes under.
-- `distance` is road travelled, so the pattern is laid on the ground behind the
-- runner and stands still when they do. `still` (Reduced, reduced motion) puts
-- the one band on the centre line with no weave at all. Returns the band's
-- centre in root space, for a body standing 3 studs high, and its half-width.
--==============================================================================
function BloomTrail.weave(distance: number, presence: number, energy: number, which: number,
	still: boolean): (Vector3, number)
	local p = math.clamp(presence, 0, 1)
	local e = math.clamp(energy, 0, 1)
	if still then
		return Vector3.new(0, L.RibbonHeight, L.RibbonBehind), L.ReducedHalf * p
	end
	local half = L.RibbonHalf * (1 + L.RibbonHalfEnergy * e) * p
	local turn = (distance / L.WeaveStuds) * math.pi * 2 + (if which == 2 then math.pi else 0)
	local amp = L.WeaveAmplitude * (1 + L.WeaveAmplitudeEnergy * e) * p
	return Vector3.new(math.sin(turn) * amp, L.RibbonHeight + math.cos(turn) * amp * 0.6,
		L.RibbonBehind + (if which == 2 then 0.08 else 0)), half
end

-- How far a turn swings the pair to its outside: `yawRate` in radians a
-- second, positive to the left, giving studs toward the body's right.
function BloomTrail.swing(yawRate: number): number
	if yawRate ~= yawRate then
		return 0
	end
	return math.clamp(yawRate * L.TurnSwingPerRad, -L.TurnSwingMax, L.TurnSwingMax)
end

--==============================================================================
-- THE SHIMMER, PRECOMPUTED
--
-- A ribbon's colour runs from its fresh end (0, at the runner) to its old end
-- (1). Frame k puts a soft lift toward white k/frames of the way along, so
-- stepping through the frames moves the light down the ribbon -- one slow pass
-- per ShimmerSeconds. Built once at start: nothing is made while anybody runs.
--==============================================================================
local function lift(c: Color3, by: number): Color3
	return c:Lerp(Color3.new(1, 1, 1), by)
end

function BloomTrail.shimmerFrames(from: Color3, to: Color3, frames: number): { ColorSequence }
	local out = {}
	local n = math.max(1, math.floor(frames))
	local w = L.ShimmerWidth
	for k = 0, n - 1 do
		-- The light enters just before the fresh end and leaves past the old one.
		local at = -w + (1 + 2 * w) * (k / n)
		local function glow(t: number): number
			return L.ShimmerLift * math.max(0, 1 - math.abs(t - at) / w)
		end
		local points = { ColorSequenceKeypoint.new(0, lift(from, glow(0))) }
		for _, t in ipairs({ at - w, at, at + w }) do
			if t > 0.001 and t < 0.999 then
				table.insert(points, ColorSequenceKeypoint.new(t, lift(from:Lerp(to, t), glow(t))))
			end
		end
		table.insert(points, ColorSequenceKeypoint.new(1, lift(to, glow(1))))
		out[k + 1] = ColorSequence.new(points)
	end
	return out
end

-- Which shimmer frame shows at time `t` (seconds), 1-based.
function BloomTrail.shimmerIndex(t: number, frames: number): number
	local n = math.max(1, math.floor(frames))
	local phase = (t / L.ShimmerSeconds) % 1
	return math.clamp(math.floor(phase * n) + 1, 1, n)
end

-- The one still ribbon of Reduced and reduced motion: the original Bloomrunner
-- band, mint into gold into leaf.
function BloomTrail.stillColour(mint: Color3, gold: Color3, leaf: Color3): ColorSequence
	return ColorSequence.new({
		ColorSequenceKeypoint.new(0, mint),
		ColorSequenceKeypoint.new(0.5, gold),
		ColorSequenceKeypoint.new(1, leaf),
	})
end

--==============================================================================
-- WHEN A PETAL OR A BLOOM IS DUE -- BY THE ROAD, NOT THE CLOCK
--
-- One Emitter per wearer: road left until the next petal and the next bloom,
-- and when each was last laid. `step` is horizontal road covered this frame;
-- TrailFX passes it only while the wearer is really running, so standing still,
-- pushing into a wall or riding a mill lays nothing however long it lasts. The
-- caps hold however fast they go: at most one petal a frame and
-- PetalMaxPerSecond a second, at most one bloom per BloomMinSeconds. Road owed
-- beyond a cap is dropped, never queued up for later.
--==============================================================================
export type Emitter = {
	petalIn: number,
	bloomIn: number,
	lastPetal: number,
	lastBloom: number,
}

function BloomTrail.newEmitter(roll: number?): Emitter
	return {
		petalIn = L.PetalStuds * 0.5,
		bloomIn = L.BloomStuds * (0.6 + 0.4 * math.clamp(roll or 0.5, 0, 1)),
		lastPetal = -math.huge,
		lastBloom = -math.huge,
	}
end

function BloomTrail.emit(state: Emitter, step: number, now: number, energy: number, mode: string,
	roll: number): (number, boolean)
	local budget = (BloomTrail.Budget :: any)[mode] or BloomTrail.Budget.Off
	if not (step > 0) or step == math.huge then
		return 0, false
	end
	local e = math.clamp(energy, 0, 1)
	local petals = 0
	if budget.Petals > 0 then
		local spacing = L.PetalStuds + (L.PetalStudsEnergy - L.PetalStuds) * e
		state.petalIn -= step
		if state.petalIn <= 0 and now - state.lastPetal >= 1 / L.PetalMaxPerSecond then
			petals = 1
			state.lastPetal = now
			state.petalIn += spacing
		end
		if state.petalIn < 0 then
			state.petalIn = 0
		end
	end
	local bloom = false
	if budget.Blooms > 0 then
		state.bloomIn -= step
		if state.bloomIn <= 0 and now - state.lastBloom >= L.BloomMinSeconds then
			bloom = true
			state.lastBloom = now
			local spacing = L.BloomStuds + (L.BloomStudsEnergy - L.BloomStuds) * e
			state.bloomIn = spacing + L.BloomJitterStuds * (math.clamp(roll, 0, 1) - 0.5)
		elseif state.bloomIn < 0 then
			state.bloomIn = 0
		end
	end
	return petals, bloom
end

--==============================================================================
-- THE CURVES A PETAL AND A BLOOM ARE DRAWN BY
--==============================================================================
-- A loose petal's transparency over its life (0..1 of it): there at once,
-- holding for the first 40%, then thinning to nothing at the end.
function BloomTrail.petalFade(u: number): number
	local t = math.clamp(u, 0, 1)
	if t < 0.4 then
		return 0.2
	end
	return 0.2 + 0.8 * ((t - 0.4) / 0.6)
end

-- How far a loose petal has drifted `age` seconds after leaving, as multiples
-- of its puff (slowing under drag) and of the fall (gathering).
function BloomTrail.petalTravel(age: number): (number, number)
	local a = math.max(0, age)
	return (1 - math.exp(-a * L.PetalDrag)) / L.PetalDrag, 0.5 * L.PetalFall * a * a
end

-- A bloom at `age` seconds: how open (0..1, eased), how far into shedding
-- (0..1), and whether it is over.
function BloomTrail.bloomPhase(age: number): (number, number, boolean)
	local open = math.clamp(age / L.BloomOpen, 0, 1)
	open = open * open * (3 - 2 * open)
	local shedStart = L.BloomOpen + L.BloomHold
	local shed = math.clamp((age - shedStart) / L.BloomShed, 0, 1)
	return open, shed, age >= shedStart + L.BloomShed
end

return BloomTrail
