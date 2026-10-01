--!strict
--==============================================================================
-- WHAT A CHASING GUARDIAN MEASURES, AND WHO IT REMEMBERS (2026-10-01)
--
-- Pure: no services, no clock, no Instance is touched beyond comparing two by
-- identity. NestService owns the guardian and calls these; they live here so the
-- geometry and the memory can be tested without a guardian, a map or a Play
-- session. NOT a *Service: ServerMain auto-loads files ending in Service, and
-- this one is required, never started.
--
-- THREE QUESTIONS, ALL ASKED ONCE PER NEST TICK:
--
--   closestApproach   did the two bodies touch BETWEEN this tick and the last?
--   sampleUsable      is the last tick's sample a fair start for that sweep?
--   heading           which way should the guardian run this tick?
--
-- AND ONE MEMORY: every thief who robbed this nest while it was already busy
-- with somebody else, so finishing one chase is not forgetting the rest.
--
-- AND THE WAY HOME (routeHome): through the road's mouth, never into a wall.
--==============================================================================
local GuardianPursuit = {}

-- Where both bodies were at one tick, taken at the SAME moment. Belongs to the
-- nest, not to the player: two guardians after one thief each keep their own.
export type Sample = {
	target: any,
	-- The target's Character at the time. A respawn is a new body, and a sweep
	-- from the old body's last spot to the new one's first is not running.
	body: any,
	parentAt: Vector3,
	targetAt: Vector3,
	at: number,
}

local function flat(v: Vector3): Vector3
	return Vector3.new(v.X, 0, v.Z)
end
GuardianPursuit.flat = flat

--==============================================================================
-- CLOSEST APPROACH OF TWO BODIES MOVING AT ONCE
--
-- Both moved during the tick, at the same time, so the question is about their
-- RELATIVE position: where the target stood relative to the guardian at the
-- start (a), and at the end (b). With both treated as moving in straight lines
-- across the tick, the relative position runs straight from a to b, and the
-- closest it came is that segment's distance from the origin. Flattened to the
-- ground plane, so a jump does not read as distance.
--
-- The test it replaces put the guardian's END position against the target's
-- whole path: two different moments compared as if they were one. It missed two
-- bodies crossing mid-tick (each end of the tick apart) and it hit a target who
-- had left a spot before the guardian reached it.
--==============================================================================
function GuardianPursuit.closestApproach(parentWas: Vector3, parentNow: Vector3,
	targetWas: Vector3, targetNow: Vector3): number
	local a = flat(targetWas - parentWas)
	local b = flat(targetNow - parentNow)
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-6 then
		-- They moved together, or neither moved: the gap never changed.
		return a.Magnitude
	end
	local t = math.clamp(-a:Dot(ab) / len2, 0, 1)
	return (a + ab * t).Magnitude
end

--==============================================================================
-- A SAMPLE IS ONLY A SWEEP'S START IF NOTHING BROKE IN BETWEEN
--
-- Thrown away, so the tick falls back to the plain distance between the two
-- bodies now, when:
--   * it is about somebody else (the target changed), or another body of theirs
--     (a respawn);
--   * it is old (a hitch, or a chase that stopped and started again);
--   * either body covered more than `maxTravel` since -- a teleport, a throw, a
--     CarryGuard put-back, a guardian reset. Sweeping across that would be a line
--     over half the map, and everything near it would count as a hit.
--==============================================================================
function GuardianPursuit.sampleUsable(sample: Sample?, target: any, body: any, parentNow: Vector3,
	targetNow: Vector3, now: number, maxTravel: number, maxAge: number): boolean
	if not sample then
		return false
	end
	if sample.target ~= target or sample.body ~= body then
		return false
	end
	local age = now - sample.at
	if age <= 0 or age > maxAge then
		return false
	end
	if flat(targetNow - sample.targetAt).Magnitude > maxTravel then
		return false
	end
	if flat(parentNow - sample.parentAt).Magnitude > maxTravel then
		return false
	end
	return true
end

--==============================================================================
-- WHICH WAY TO RUN
--
-- At range: straight at the target, exactly as before -- NestService aims
-- ChaseOvershootStuds PAST them along this line so the Humanoid never brakes.
--
-- Close in (`leadStuds`): at where the target will be when the next order goes
-- out, `leadSeconds` from now, from the velocity the last usable sample gives.
-- An order is a tick old before the next one replaces it; at ten studs a
-- strafing player has moved a long way round in that time, and a guardian
-- aimed at where they WERE is a guardian circling behind them. The lead is
-- never longer than the gap itself, so it bends the line rather than replacing
-- it, and with no usable sample (a fresh chase, a teleport, a respawn) there is
-- no lead at all.
--
-- `fallback` is the way the guardian already faces, for the moment it stands on
-- top of the target and there is no line to follow.
--==============================================================================
function GuardianPursuit.heading(parentNow: Vector3, targetNow: Vector3, velocity: Vector3?,
	leadSeconds: number, leadStuds: number, fallback: Vector3): Vector3
	local toTarget = flat(targetNow - parentNow)
	local gap = toTarget.Magnitude
	local aim = toTarget
	if velocity and gap <= leadStuds then
		local lead = flat(velocity) * leadSeconds
		if lead.Magnitude > gap then
			lead = if lead.Magnitude > 1e-6 then lead.Unit * gap else Vector3.zero
		end
		aim = toTarget + lead
	end
	if aim.Magnitude > 0.05 then
		return aim.Unit
	end
	local look = flat(fallback)
	return if look.Magnitude > 0.05 then look.Unit else Vector3.new(0, 0, -1)
end

--==============================================================================
-- MORE THAN ONE THIEF
--
-- A guardian chases one player at a time and keeps chasing them: a second
-- theft while it is busy with a valid target is REMEMBERED, not obeyed, so two
-- players cannot swap the chase back and forth between them. It takes over only
-- when there is nobody to chase, when it is the same thief, or when the current
-- target can no longer be chased.
--
-- `thieves` maps each remembered player to when they were remembered. Whoever
-- asks passes `positionOf`, which answers where an ELIGIBLE thief stands and nil
-- for anybody who is not one any more -- safe, dead, gone, or no longer carrying
-- this nest's pod. A nil answer drops them for good.
--==============================================================================
function GuardianPursuit.takesOver(current: any?, thief: any, currentChaseable: boolean): boolean
	return current == nil or current == thief or not currentChaseable
end

function GuardianPursuit.prune(thieves: { [any]: number }, positionOf: (any) -> Vector3?): number
	local left = 0
	for thief in pairs(thieves) do
		if positionOf(thief) == nil then
			thieves[thief] = nil
		else
			left += 1
		end
	end
	return left
end

-- The nearest eligible thief to `from`, taken OUT of the memory (it is about to
-- become the target); everybody ineligible is dropped on the way. Nil when
-- nobody is left.
function GuardianPursuit.nextThief(thieves: { [any]: number }, from: Vector3,
	positionOf: (any) -> Vector3?): any?
	local best, bestGap = nil, math.huge
	for thief in pairs(thieves) do
		local at = positionOf(thief)
		if at == nil then
			thieves[thief] = nil
		else
			local gap = flat(at - from).Magnitude
			if gap < bestGap then
				best, bestGap = thief, gap
			end
		end
	end
	if best ~= nil then
		thieves[best] = nil
	end
	return best
end

--==============================================================================
-- THE WAY HOME GOES THROUGH THE MOUTH (2026-10-01)
--
-- The road is one straight corridor, so from anywhere inside it the nest is a
-- straight walk. Past the mouth, in the field, it is not: the walls end there,
-- and a straight line to a nest deeper in can run into a wall's END FACE
-- head-on. Measured in Play: a guardian carried out past the mouth stood against
-- the right wall's end, 548 studs from home, for good.
--
-- So from the field the order is first a point in front of the mouth, at an X
-- its body clears both walls by; then a point inside; then home. Worked out
-- afresh from where it stands on every tick, so there is nothing to remember
-- and nothing to go stale.
--
-- Every order but home is replaced BEFORE it is reached. A Humanoid stops a
-- little short of the point it was sent to and then stands, so an order that
-- only changes on arrival never changes: measured in Play, a hauler lined up
-- 0.5 studs short of a too-tight test and stood there. The point in front is
-- aimed a stud inside the clear line and "lined up" allows a stud either side
-- of it; the point inside is past the mouth, and the mouth is where it turns.
--
--   at, home    where it stands and where it lives (home inside the corridor)
--   mouthZ      where the walls end; the field is at higher Z
--   halfClear   how far off the centre line it may stand and clear a wall:
--               half the corridor less its own reach
--   inset       how far out in front of the mouth it lines up, and how far
--               in it walks before turning for home
--==============================================================================
function GuardianPursuit.routeHome(at: Vector3, home: Vector3, mouthZ: number, halfClear: number,
	inset: number): Vector3
	if at.Z < mouthZ then
		return home
	end
	if math.abs(at.X) <= halfClear + 1 then
		return Vector3.new(math.clamp(at.X, -halfClear, halfClear), at.Y, mouthZ - inset)
	end
	local side = if at.X < 0 then -1 else 1
	return Vector3.new(side * (halfClear - 1), at.Y, mouthZ + inset)
end

return GuardianPursuit
