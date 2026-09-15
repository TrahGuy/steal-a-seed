--!strict
-- Steal a Seed :: PlantWander
--
-- Where a grown creature may walk on its owner's plot, and where it walks next.
--
-- NOT a *Service. There is no lifecycle here, no state and no Instance writes:
-- geometry and one decision, which PlantService calls on its existing tick. It
-- is its own module so that tools/tests/PlantWanderSpec.luau can drive the exact
-- code the server runs, on real plot geometry, without a live server.
--
--==============================================================================
-- WHERE A CREATURE MAY WALK
--
-- Not the beds -- the whole fenced interior, both beds and the grass between
-- them, because a garden where everything stands on the dirt and nothing ever
-- crosses the lawn is a garden nobody is living in.
--
-- The shape is the plot's L: the main rectangle, plus the wing when the level
-- has one. Expressed as two rectangles that SHARE an edge, so the union is
-- connected and a creature can walk from one into the other without a corridor
-- being described anywhere.
--
-- Kept clear of three things:
--   * the fence, by FenceMargin, so a body never overlaps a board;
--   * the gateway, by GateMargin, so nothing loiters in the doorway looking
--     like it is about to leave the plot;
--   * anything outside, by construction -- the region is bounded by the plot's
--     own dimensions, so no point can name another player's ground.
--
-- All of it in the plot's own frame: X across, Z from the gate (-Z) to the back.
--
--==============================================================================
-- THE ROUTE STAYS INSIDE, NOT ONLY THE DESTINATION
--
-- The L is not convex, and neither is the main rectangle once the gateway is
-- cut out of its front edge. A straight walk between two legal points could
-- still cut the missing corner of the L -- straight through the step in the
-- fence -- or pass through the doorway. Measured on the chooser this replaced:
-- 657 of 21,839 simulated legs did exactly that, 216 across the L's corner and
-- 441 through the gateway.
--
-- So a destination is never clamped into the region any more. A direction is
-- chosen first, `Room` measures how far a straight line may run that way before
-- it leaves the region, and the destination is picked on that stretch. Every
-- point of every leg is inside by construction; nothing is checked afterwards
-- because there is nothing to find. A trip from the front of the main bed into
-- the wing takes two legs, the first to where the wing can be seen.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))

local PLOT = GameConfig.Plot
local WANDER = GameConfig.Plant.Wander

local PlantWander = {}

-- A closed rectangle in the plot's frame.
export type Box = { x0: number, x1: number, z0: number, z1: number }

export type Region = {
	main: Box,
	wing: Box?,
	-- The doorway: its sides and back are open, so standing exactly on its edge
	-- is allowed; it runs out through the front fence.
	gate: Box,
}

-- What Choose needs to know about the other plants on the plot. PlantService's
-- own entries already have this shape.
export type Walker = { offset: Vector3, legTo: Vector3? }

local EPS = 1e-6
local TAU = math.pi * 2

--==============================================================================
-- THE REGION, FROM THE NUMBERS A PLOT REPLICATES ABOUT ITSELF
--
-- `depth`, `wingWidth` and `wingFrontZ` are exactly what MapService stamps as
-- the plot's Depth, WingWidth and WingFrontZ attributes. A wing whose front is
-- at or behind its back has no room in it and is left out.
--==============================================================================
function PlantWander.RegionOf(depth: number, wingWidth: number, wingFrontZ: number): Region
	local halfW = PLOT.Width * 0.5
	local halfD = depth * 0.5
	local m = WANDER.FenceMargin
	local main: Box = { x0 = -halfW + m, x1 = halfW - m, z0 = -halfD + m, z1 = halfD - m }
	local wing: Box? = nil
	if wingWidth > 0 and wingFrontZ + m < halfD - m then
		wing = { x0 = halfW - m, x1 = halfW + wingWidth - m, z0 = wingFrontZ + m, z1 = halfD - m }
	end
	local gateHalf = PLOT.GateWidth * 0.5 + 2
	local gate: Box = { x0 = -gateHalf, x1 = gateHalf, z0 = -math.huge, z1 = -halfD + WANDER.GateMargin }
	return { main = main, wing = wing, gate = gate }
end

function PlantWander.RegionFor(plot: Model): Region
	local depth = tonumber(plot:GetAttribute("Depth"))
		or GameConfig.plotDepthFor(GameConfig.plotRowsForTier(plot:GetAttribute("Level")))
	return PlantWander.RegionOf(depth,
		tonumber(plot:GetAttribute("WingWidth")) or 0,
		tonumber(plot:GetAttribute("WingFrontZ")) or 0)
end

--==============================================================================
-- THE NEAREST LEGAL POINT, THE WAY IT HAS ALWAYS BEEN WORKED OUT
--
-- Clamp into whichever rectangle is nearer, then out of the doorway -- only the
-- mouth of the gate, not the whole front edge: a creature may stand along the
-- front fence, just not in the gap. A point in the shared edge lands in both
-- rectangles and either answer is the same point.
--
-- Used where a point has to BECOME legal -- a garden rebased onto a smaller
-- plot, a creature somehow standing outside -- and never to pick a walk.
--==============================================================================
function PlantWander.Clamp(region: Region, p: Vector3): Vector3
	local x, z = p.X, p.Z
	local main = region.main
	local mainX = math.clamp(x, main.x0, main.x1)
	local mainZ = math.clamp(z, main.z0, main.z1)
	local bx, bz = mainX, mainZ
	local wing = region.wing
	if wing then
		local wx = math.clamp(x, wing.x0, wing.x1)
		local wz = math.clamp(z, wing.z0, wing.z1)
		-- Vector2, exactly as it shipped: a tie between the two rectangles breaks
		-- the same way it always has.
		local dMain = (Vector2.new(x, z) - Vector2.new(mainX, mainZ)).Magnitude
		local dWing = (Vector2.new(x, z) - Vector2.new(wx, wz)).Magnitude
		if dWing < dMain then
			bx, bz = wx, wz
		end
	end
	local gate = region.gate
	if bz < gate.z1 and bx > gate.x0 and bx < gate.x1 then
		bz = gate.z1
	end
	return Vector3.new(bx, 0, bz)
end

local function inBox(b: Box, x: number, z: number): boolean
	return x >= b.x0 - EPS and x <= b.x1 + EPS and z >= b.z0 - EPS and z <= b.z1 + EPS
end

function PlantWander.Inside(region: Region, p: Vector3): boolean
	local x, z = p.X, p.Z
	local wing = region.wing
	if not (inBox(region.main, x, z) or (wing ~= nil and inBox(wing, x, z))) then
		return false
	end
	local g = region.gate
	return not (x > g.x0 + EPS and x < g.x1 - EPS and z < g.z1 - EPS)
end

--==============================================================================
-- HOW FAR A STRAIGHT LINE MAY RUN
--
-- The slab method: along p + t*d, each rectangle is entered and left at two
-- values of t. The walk starts in whichever rectangle holds `p`, carries on
-- into the other where the two meet at the shared edge, and stops at the first
-- t where the line would step into the doorway. Exact, and no sampling -- a
-- sampled check can step over the corner of the doorway between two samples.
--==============================================================================
local function slab(lo: number, hi: number, p: number, d: number, open: boolean): (number, number)
	if math.abs(d) < 1e-9 then
		local inside = if open then p > lo + EPS and p < hi - EPS else p >= lo - EPS and p <= hi + EPS
		if inside then
			return -math.huge, math.huge
		end
		return math.huge, -math.huge
	end
	local a, b = (lo - p) / d, (hi - p) / d
	if a > b then
		a, b = b, a
	end
	return a, b
end

local function span(box: Box, px: number, pz: number, dx: number, dz: number, open: boolean): (number, number)
	local ax, bx = slab(box.x0, box.x1, px, dx, open)
	local az, bz = slab(box.z0, box.z1, pz, dz, open)
	return math.max(ax, az), math.min(bx, bz)
end

function PlantWander.Room(region: Region, p: Vector3, dx: number, dz: number): number
	local px, pz = p.X, p.Z
	local a0, a1 = span(region.main, px, pz, dx, dz, false)
	local inMain = a0 <= EPS and a1 >= -EPS
	local wing = region.wing
	local b0, b1 = math.huge, -math.huge
	if wing then
		b0, b1 = span(wing, px, pz, dx, dz, false)
	end
	local inWing = b0 <= EPS and b1 >= -EPS
	if not (inMain or inWing) then
		return 0
	end

	local reach = math.max(if inMain then a1 else 0, if inWing then b1 else 0)
	-- Across the shared edge: whichever rectangle begins before the walk leaves
	-- the other takes it on. Twice covers main -> wing -> main as well.
	for _ = 1, 2 do
		if a1 > reach and a0 <= reach + EPS then
			reach = a1
		end
		if b1 > reach and b0 <= reach + EPS then
			reach = b1
		end
	end

	-- The doorway is open-edged: arriving on its boundary is fine, entering is
	-- not. A line that only grazes it spends no length inside it.
	local g0, g1 = span(region.gate, px, pz, dx, dz, true)
	if g1 > g0 + EPS and g1 > EPS and g0 < reach then
		reach = math.max(g0, 0)
	end
	return math.max(reach, 0)
end

--==============================================================================
-- HOW LONG A LEG TAKES
--
-- Its length over the tier's walking speed, and never less than 0.4 s so a
-- client always has a leg long enough to ease into and out of.
--==============================================================================
function PlantWander.LegSeconds(tier: number, distance: number): number
	return math.max(distance / math.max(SeedData.WanderSpeed(tier), 0.05), 0.4)
end

--==============================================================================
-- PICK SOMEWHERE, PREFERRING WHEREVER NOBODY ELSE IS
--
-- A direction, then how far a straight line may run that way (`Room`), then a
-- distance on that stretch between the tier's minimum leg and its reach. A
-- direction without the room for the minimum is thrown away rather than
-- shortened: shortening it is exactly how a Colossal against a fence used to be
-- handed a two-stud shuffle. Bounded: at most `Attempts` directions, and it
-- stops early once it holds `Candidates` good ones.
--
-- Scored on DISTANCE FROM EVERYONE ELSE, counting both where other plants are
-- and where they have already said they are going. Reserved destinations matter
-- as much as current positions: without them, five creatures deciding in the
-- same tick all pick the same empty corner and arrive as the pile they were
-- supposed to stop being.
--
-- The separation target is BOUNDED and logical, not physical. A Colossal is
-- hundreds of studs of silhouette -- scoring against real sizes would make every
-- candidate illegal at once and the whole thing would deadlock. This promises
-- visible distribution, not non-overlap; the creatures do not collide and at the
-- top of the size ladder they never will.
--
-- WHEN NO DIRECTION HAS THE ROOM, a fixed sweep of sixteen finds the longest
-- straight line on offer and the creature takes that, however short. Only a
-- line under `SeedData.WanderStallStuds` is refused, and then it rests instead
-- of twitching. A creature somehow standing OUTSIDE the region is walked
-- straight back to the nearest legal point; that leg is the one kind whose
-- route cannot be inside, because it starts out of bounds.
--
-- Returns the destination and how it was reached:
--   "leg"      a normal choice
--   "longest"  nothing met the minimum; the longest line on offer
--   "recover"  started outside the region; back to the nearest legal point
--   "stay"     nothing worth walking to; the destination is `here`
--==============================================================================
local function loneliness(x: number, z: number, others: { [number]: Walker }, selfId: number): number
	local nearest = math.huge
	for id, other in pairs(others) do
		if id ~= selfId then
			local o = other.offset
			local d = math.sqrt((x - o.X) ^ 2 + (z - o.Z) ^ 2)
			if d < nearest then
				nearest = d
			end
			local claim = other.legTo
			if claim then
				local dc = math.sqrt((x - claim.X) ^ 2 + (z - claim.Z) ^ 2)
				if dc < nearest then
					nearest = dc
				end
			end
		end
	end
	return nearest
end

function PlantWander.Choose(region: Region, here: Vector3, tier: number,
	others: { [number]: Walker }, selfId: number, rng: Random): (Vector3, string)
	local home = Vector3.new(here.X, 0, here.Z)
	if not PlantWander.Inside(region, home) then
		return PlantWander.Clamp(region, home), "recover"
	end

	local reach = SeedData.WanderReach(tier)
	local minLeg = math.min(SeedData.WanderMinLeg(tier), reach)
	local best: Vector3? = nil
	local bestScore = -math.huge
	local found = 0

	for _ = 1, WANDER.Attempts do
		local a = rng:NextNumber(0, TAU)
		local dx, dz = math.cos(a), math.sin(a)
		local far = math.min(reach, PlantWander.Room(region, home, dx, dz))
		if far >= minLeg then
			-- sqrt spreads the choice over the ring's AREA, so a candidate is not
			-- biased toward the short end of the stretch.
			local r = minLeg + (far - minLeg) * math.sqrt(rng:NextNumber())
			local cx, cz = home.X + dx * r, home.Z + dz * r
			-- Past the separation target there is nothing more to gain, so a
			-- candidate 40 studs from anybody does not beat one at 15 purely for
			-- being further out at the fence. Ties break on the trip being worth
			-- taking at all.
			local score = math.min(loneliness(cx, cz, others, selfId), WANDER.SeparationStuds)
				+ r * 0.05
			if score > bestScore then
				best, bestScore = Vector3.new(cx, 0, cz), score
			end
			found += 1
			if found >= WANDER.Candidates then
				break
			end
		end
	end
	if best then
		return best, "leg"
	end

	local longest, lx, lz = 0, 0, 0
	for i = 0, 15 do
		local a = i * TAU / 16
		local dx, dz = math.cos(a), math.sin(a)
		local room = PlantWander.Room(region, home, dx, dz)
		if room > longest then
			longest, lx, lz = room, dx, dz
		end
	end
	local r = math.min(reach, longest)
	if r < SeedData.WanderStallStuds then
		return home, "stay"
	end
	return Vector3.new(home.X + lx * r, 0, home.Z + lz * r), "longest"
end

return PlantWander
