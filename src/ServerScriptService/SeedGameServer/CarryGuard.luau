--!strict
--==============================================================================
-- CARRY GUARD: A POD CANNOT TRAVEL FASTER THAN ITS CARRIER IS ALLOWED TO RUN
--
-- A player's character is simulated on THEIR machine, so its position reaches
-- the server as a claim. Banking only asked "is the carrier standing in the safe
-- zone?", which an exploiter answers by teleporting there from any nest -- the
-- whole run, the guardian and every rival on the road skipped in one frame.
--
-- This is the rule that closes it, kept pure so it can be tested without a
-- character: a travel BUDGET that fills at the carrier's own server-set
-- WalkSpeed (with headroom) and is spent by how far they actually moved on the
-- ground. A legitimate run never overdraws it; a teleport overdraws it at once,
-- and a speed hack overdraws it within a few seconds.
--
-- WHY A BUDGET AND NOT A PER-FRAME SPEED LIMIT
--
-- Positions arrive in bursts. A network stall of two seconds delivers two
-- seconds of honest running in one update, and a per-frame check would call
-- that a teleport. The budget keeps filling while no movement arrives, up to
-- CapSeconds of travel, so the burst is paid for by the time that passed.
--
-- WHY THE SLACK
--
-- The server itself moves a carrier a little: a Starlock Anchor pulls up to 8
-- studs (WeaponData asserts at most 12) and a Dunesnap trip tumbles one at 7
-- studs a second for about a second. Both keep the pod, both fit inside the
-- slack, so no mover has to tell this module anything. Everything that moves a
-- carrier further -- a bat, a blast, a guardian's throw, nightfall -- ends the
-- carry first.
--
-- Horizontal only: falling is not travel, and the road is flat.
--==============================================================================

local CarryGuard = {}

-- Headroom over the server's WalkSpeed: client physics, replication jitter and
-- a WalkSpeed change that has not reached the client yet.
CarryGuard.Tolerance = 1.35
-- What a fresh carry starts with, and the most the server's own small moves
-- (a trap pull, a trip) ever need. NOT refilled by a correction -- see reset.
CarryGuard.SlackStuds = 24
-- How much unspent travel may be saved up: the longest network stall a carrier
-- can come back from without being put back.
CarryGuard.CapSeconds = 4
-- A carry that starts this soon after the same player's last one gets no slack,
-- so dropping and re-taking a pod cannot mint 24 free studs every cycle.
CarryGuard.SlackCooldownSeconds = 10

export type State = {
	at: Vector3,
	budget: number,
}

-- `recent`: this player carried something within SlackCooldownSeconds.
function CarryGuard.new(at: Vector3, recent: boolean?): State
	return { at = at, budget = if recent then 0 else CarryGuard.SlackStuds }
end

-- The cap for a carrier at this WalkSpeed, for the spec and the log.
function CarryGuard.capFor(walkSpeed: number): number
	local speed = if walkSpeed == walkSpeed and walkSpeed > 0 then walkSpeed else 0
	return speed * CarryGuard.Tolerance * CarryGuard.CapSeconds + CarryGuard.SlackStuds
end

--==============================================================================
-- ONE OBSERVATION
--
-- Adds dt seconds of travel at the carrier's current WalkSpeed, then spends the
-- ground distance from the last accepted position to `pos`. True and the state
-- advances if it fits. False and the anchor stays where it was, so the caller
-- can put the carrier back at `state.at` -- the last place the server saw them
-- honestly -- and call `reset`.
--
-- Travel already saved is kept if WalkSpeed drops (a snare, a heavier pod): it
-- was earned at the old speed. Only new saving is capped at the new one.
--==============================================================================
function CarryGuard.step(state: State, pos: Vector3, walkSpeed: number, dt: number): (boolean, number)
	local speed = if walkSpeed == walkSpeed and walkSpeed > 0 then walkSpeed else 0
	local elapsed = if dt == dt and dt > 0 then dt else 0
	local allowed = speed * CarryGuard.Tolerance
	local cap = allowed * CarryGuard.CapSeconds + CarryGuard.SlackStuds
	local budget = math.min(state.budget + allowed * elapsed, math.max(cap, state.budget))
	local d = pos - state.at
	local moved = Vector3.new(d.X, 0, d.Z).Magnitude
	if moved ~= moved then
		return false, math.huge
	end
	if moved <= budget then
		state.budget = budget - moved
		state.at = pos
		return true, moved
	end
	state.budget = budget
	return false, moved
end

--==============================================================================
-- AFTER A CORRECTION: ANCHORED WHERE THE CARRIER NOW STANDS, WITH NOTHING SAVED
--
-- Zero, not the slack. Refilling the slack here was a hole: a speed hacker put
-- back to their last ACCEPTED position -- which the accepted steps had already
-- advanced -- would get another 24 free studs every time, and a loop of "run 24
-- studs, get put back to 24 studs further on" averages whatever speed the hack
-- is set to. From zero, the budget refills at the allowed rate only, so a
-- corrected carrier can never outpace the rule again.
--==============================================================================
function CarryGuard.reset(state: State, at: Vector3)
	state.at = at
	state.budget = 0
end

return CarryGuard
