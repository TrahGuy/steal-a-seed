--!strict
--==============================================================================
-- Steal a Seed :: GardenPlan (2026-10-04, the owner's MY PLANTS)
--
-- THE ARITHMETIC OF "WHAT SHOULD BE IN THE GROUND". Pure: candidates in, a plan
-- out -- so GardenPlanSpec drives every rule without a server, and PlantService
-- only carries the plan out.
--
--   best      EQUIP BEST: every grown creature the player owns -- planted, or
--             stored with a live Tool -- ranked by what it earns
--             (SeedData.IncomePerSecond, the number the faucet sums BEFORE the
--             pass, the boosts and the rain multiply the whole garden, so no
--             boost is counted twice). The plot's capacity less its growing
--             pods is how many may stand; the best that many stay or go in,
--             the rest of the planted come out.
--   ties      equal incomes keep what is already planted, then the lower item
--             id, then the lower placement id -- so pressing EQUIP BEST again
--             on an unchanged lineup moves nothing.
--   room      a whole change is checked against the plot AND the bag before
--             anything moves: the bag after the change (stored rows, less what
--             goes in, plus what comes out, plus a raid pod's kept place) must
--             fit, or the change is refused whole.
--   spots     where newcomers stand: points on the player's own beds, spread
--             out (each the free point farthest from everything standing),
--             deterministic for the same garden. The small base circle is the
--             only placement rule (the owner's 2026-10-02 rule): nothing here
--             measures a model.
--==============================================================================
local GardenPlan = {}

export type Candidate = {
	-- "p:<placementId>" for a planted one, "i:<item>" for a stored one.
	key: string,
	income: number,
	planted: boolean,
	item: string?,
	placementId: number?,
}

export type Plan = {
	keep: { Candidate },
	plant: { Candidate },
	ret: { Candidate },
	-- How many grown creatures the plot has room for, its pods counted.
	slots: number,
}

-- The order EQUIP BEST ranks in: income, then planted first, then the stable ids.
function GardenPlan.before(a: Candidate, b: Candidate): boolean
	if a.income ~= b.income then
		return a.income > b.income
	end
	if a.planted ~= b.planted then
		return a.planted
	end
	local ia, ib = tonumber(a.item), tonumber(b.item)
	if ia and ib and ia ~= ib then
		return ia < ib
	end
	local sa, sb = a.item or "", b.item or ""
	if sa ~= sb then
		-- An id before no id; two that are not numbers by their text.
		if sa == "" or sb == "" then
			return sb == ""
		end
		return sa < sb
	end
	local pa, pb = a.placementId or math.huge, b.placementId or math.huge
	if pa ~= pb then
		return pa < pb
	end
	return a.key < b.key
end

function GardenPlan.best(candidates: { Candidate }, capacity: number, pods: number): Plan
	local slots = math.max(0, math.floor(capacity) - math.max(0, math.floor(pods)))
	local ranked = table.clone(candidates)
	table.sort(ranked, GardenPlan.before)
	local plan: Plan = { keep = {}, plant = {}, ret = {}, slots = slots }
	for i, c in ipairs(ranked) do
		if i <= slots then
			table.insert(if c.planted then plan.keep else plan.plant, c)
		elseif c.planted then
			table.insert(plan.ret, c)
		end
	end
	return plan
end

-- Whether a plan changes anything at all.
function GardenPlan.changes(plan: Plan): boolean
	return #plan.plant > 0 or #plan.ret > 0
end

-- How many rows the bag holds after a change: what it has, less what goes into
-- the ground, plus what comes out of it, plus a raid pod's kept place.
function GardenPlan.bagAfter(heldRows: number, carrying: boolean, goingIn: number, comingOut: number): number
	return heldRows - goingIn + comingOut + (if carrying then 1 else 0)
end

function GardenPlan.fits(heldRows: number, carrying: boolean, goingIn: number, comingOut: number,
	maxHeld: number): boolean
	return GardenPlan.bagAfter(heldRows, carrying, goingIn, comingOut) <= maxHeld
end

--==============================================================================
-- WHERE NEWCOMERS STAND
--
-- `beds` are rectangles in the plot's own frame (the main bed's object space,
-- which every saved offset is in): a centre and half-extents along that
-- frame's X and Z, the edge margin already taken off. `taken` is where every
-- planted thing stands. Candidates are a grid `step` apart over every bed, in a
-- fixed order (bed by bed, row by row), and each new spot is the candidate
-- farthest from everything already standing or already chosen -- the first such
-- in that order on a tie -- so the same garden always gets the same spots, and
-- they spread across the soil rather than stacking at a corner.
--==============================================================================
export type Bed = { cx: number, cz: number, hx: number, hz: number }

function GardenPlan.grid(beds: { Bed }, step: number): { Vector2 }
	local out: { Vector2 } = {}
	for _, bed in ipairs(beds) do
		local nx = math.max(0, math.floor((bed.hx * 2) / step))
		local nz = math.max(0, math.floor((bed.hz * 2) / step))
		local x0 = bed.cx - (nx * step) / 2
		local z0 = bed.cz - (nz * step) / 2
		for ix = 0, nx do
			for iz = 0, nz do
				table.insert(out, Vector2.new(x0 + ix * step, z0 + iz * step))
			end
		end
	end
	return out
end

function GardenPlan.spots(beds: { Bed }, taken: { Vector2 }, count: number, step: number): { Vector2 }
	local candidates = GardenPlan.grid(beds, step)
	local standing = table.clone(taken)
	local chosen: { Vector2 } = {}
	local used: { [number]: boolean } = {}
	for _ = 1, count do
		local best: number? = nil
		local bestD = -1
		for i, p in ipairs(candidates) do
			if not used[i] then
				local d = math.huge
				for _, q in ipairs(standing) do
					local e = (p - q).Magnitude
					if e < d then
						d = e
					end
				end
				if d > bestD + 1e-6 then
					best, bestD = i, d
				end
			end
		end
		if not best then
			break
		end
		used[best] = true
		local p = candidates[best]
		table.insert(chosen, p)
		table.insert(standing, p)
	end
	return chosen
end

return GardenPlan
