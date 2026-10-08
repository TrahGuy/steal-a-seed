--!strict
-- Steal a Seed :: GardenFrame
--
-- Where a SAVED garden's X and Z are measured, and how plot 6 reads them back
-- at Levels 6-7 (2026-10-07).
--
-- NOT a *Service: two pure functions. PlantService calls ToSaved when it
-- writes a garden into the profile and FromSaved when it puts one back;
-- tools/tests/PlotLevelsSpec drives both directly.
--
--==============================================================================
-- WHY A SAVED GARDEN NEEDS A FRAME
--
-- A planted thing is saved as an offset in the main soil's frame: X across the
-- plot, Z from the gate (-Z) to the back, measured from the plot's CENTRE
-- (ProfileSchema's v1 -> v2 notes say why). At Levels 1-5 every plot is the
-- same shape, so those numbers mean the same ground on whichever plot a player
-- is given next -- and a player is given whichever plot is free on the server
-- they join.
--
-- At Levels 6-7 they are not. Plots 1-5 grow their wing forward toward the
-- gate; plot 6, whose mill stands in that strip, keeps its Level 5 wing and
-- grows deeper instead (GameConfig.Plot.Beside). Saved in each plot's own
-- frame, a garden would come back somewhere else on the other shape: slid
-- toward the gate or away from it by half the difference in depth, and its
-- forward wing piled against a fence.
--
-- So a garden is ALWAYS SAVED IN THE FRONT SHAPE'S FRAME -- plots 1-5's, which
-- is every plot's at Levels 1-5 -- and only plot 6 at Levels 6-7 converts:
--
--   * the ground both shapes share is the same ground, the same distance from
--     the gate, and keeps its exact place;
--   * the Front plots' forward wing -- the part in front of plot 6's wing -- is
--     plot 6's extra depth at the back, turned end for end so that wing's front
--     lawn is that bed's back lawn and its soil is soil;
--   * at Level 7, the Front wing's last row, behind where plot 6's wing ends,
--     is the strip of plot 6's extra depth just behind the Front plots' back.
--
-- Plot 6's extra depth is exactly that ground (Plot.Beside's rows are chosen
-- so), so every point of a Front garden has one place on plot 6 and comes back
-- to the same place on a Front plot. The only ground with no twin is a 4-stud
-- strip down each side of plot 6's extra depth (the wing is 40 wide, the bed
-- 48): a creature standing there is saved at the nearest edge of the wing.
--
-- Nothing at Levels 1-5 and nothing on plots 1-5 goes through any of this:
-- their saved numbers ARE their live numbers, bit for bit.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

local GardenFrame = {}

-- Both shapes at one level, in gate distances (studs behind the gate line).
type Pair = {
	frontDepth: number, -- the Front plot's depth: its main bed and its wing end here
	frontWing: number, -- the Front wing's front fence
	ownDepth: number, -- this plot's depth
	ownWingFront: number, -- this plot's wing, front fence
	ownWingBack: number, -- this plot's wing, back fence
	halfW: number, -- the main rectangle's half width: the wing starts past it
	shift: number, -- from the wing's middle to the plot's
	half: number, -- half the wing's width
}

--==============================================================================
-- THE TWO SHAPES, OR NIL WHEN THIS PLOT IS THE FRONT SHAPE
--
-- Nil is "nothing to convert" -- every plot at Levels 1-5 and plots 1-5 at
-- every level -- and also a pair this file's arithmetic was not written for
-- (no wing, or ground that does not fit), which PlotLevelsSpec holds never to
-- be the case at a real level. A nil there degrades to today's rule: the
-- garden is clamped onto the plot it lands on, and nothing is lost.
--==============================================================================
local function pairAt(level: number?, plotId: number?): Pair?
	if GameConfig.plotLayoutFor(plotId) == "Front" then
		return nil
	end
	local front = GameConfig.plotFootprint(level)
	local own = GameConfig.plotFootprint(level, plotId)
	local frontDepth, ownDepth = front[1].d1, own[1].d1
	local fw, ow = front[2], own[2]
	if fw == nil and ow == nil and frontDepth == ownDepth then
		return nil
	end
	if not (fw and ow) then
		return nil
	end
	if frontDepth == ownDepth and fw.d0 == ow.d0 and fw.d1 == ow.d1 then
		return nil
	end
	local behind = frontDepth - ow.d1
	local ahead = ow.d0 - fw.d0
	if fw.d0 > ow.d0 or ow.d1 > frontDepth or ownDepth - frontDepth < ahead + behind - 1e-6
		or fw.x0 ~= ow.x0 or fw.x1 ~= ow.x1 then
		return nil
	end
	return {
		frontDepth = frontDepth,
		frontWing = fw.d0,
		ownDepth = ownDepth,
		ownWingFront = ow.d0,
		ownWingBack = ow.d1,
		halfW = fw.x0,
		shift = (fw.x0 + fw.x1) * 0.5,
		half = (fw.x1 - fw.x0) * 0.5,
	}
end

--==============================================================================
-- LIVE -> SAVED
--
-- `offset` is a planted thing's offset on this plot (its main soil's frame),
-- exactly as PlantService holds it; the answer is what the profile stores.
--==============================================================================
function GardenFrame.ToSaved(level: number?, plotId: number?, offset: Vector3): Vector3
	local p = pairAt(level, plotId)
	if not p then
		return offset
	end
	local x, d = offset.X, offset.Z + p.ownDepth * 0.5
	if d > p.frontDepth then
		-- This plot's extra depth: back to the Front wing it stands for.
		local behind = p.frontDepth - p.ownWingBack
		x = math.clamp(x, -p.half, p.half) + p.shift
		if d <= p.frontDepth + behind then
			d = d - p.frontDepth + p.ownWingBack
		else
			d = math.clamp(p.frontWing + p.ownDepth - d, p.frontWing, p.ownWingFront)
		end
	end
	return Vector3.new(x, offset.Y, d - p.frontDepth * 0.5)
end

--==============================================================================
-- SAVED -> LIVE
--
-- `saved` is a profile's X/Z; the answer is the offset on this plot.
-- PlantService still clamps it into the plot's walkable region afterwards, as
-- it always has, so a number that was never legal cannot stand anywhere it
-- should not.
--==============================================================================
function GardenFrame.FromSaved(level: number?, plotId: number?, saved: Vector3): Vector3
	local p = pairAt(level, plotId)
	if not p then
		return saved
	end
	local x, d = saved.X, saved.Z + p.frontDepth * 0.5
	if x > p.halfW then
		if d < p.ownWingFront then
			-- The Front plots' forward wing: this plot's back, end for end.
			x, d = x - p.shift, p.ownDepth - (math.max(d, p.frontWing) - p.frontWing)
		elseif d > p.ownWingBack then
			-- The Front wing's last row, behind this plot's wing.
			x, d = x - p.shift, d - p.ownWingBack + p.frontDepth
		end
	end
	return Vector3.new(x, saved.Y, d - p.ownDepth * 0.5)
end

return GardenFrame
