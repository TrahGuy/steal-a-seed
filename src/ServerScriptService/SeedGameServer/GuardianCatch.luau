--!strict
--==============================================================================
-- WHAT A CONFISCATING GUARDIAN DOES WITH THE POD IT CATCHES
--
-- Pure: no Instances, no services, no clock. CarryService owns the carried pod
-- and applies the outcome; NestService owns the guardian and acts on it. This
-- file only decides, so the decision can be tested without either of them.
--
-- NOT a *Service. ServerMain auto-loads files ending in Service; this one is
-- required, never started.
--
--==============================================================================
-- THE STATE TRANSITION
--
--   guardian already hauling   -> "hauling"     nothing read, nothing marked
--   nobody is carrying          -> "none"        the throw is the whole catch
--   pod already abandoned       -> "abandoned"   NO roll; never confiscated
--   roll <  LeaveBehindChance   -> "left"        pod marked abandoned, for good
--   roll >= LeaveBehindChance   -> "confiscated" the old haul-home path
--
-- THE ROLL IS DRAWN ONLY ON THE LAST TWO LINES. A pod is rolled exactly once in
-- its life on the road: the first confirmed catch of a pod that is not already
-- abandoned. After a "left" the flag is permanent, so later catches land on
-- "abandoned" and never draw again. A "confiscated" pod leaves the world; if it
-- is later stolen back out of its ring it is a NEW pod with no flag and may roll
-- again, which is the intended fresh attempt.
--
-- THE BOUNDARY IS STRICT: leave iff roll < chance, with roll in [0, 1). So at
-- chance 0.40 a roll of 0.3999 leaves and a roll of exactly 0.40 confiscates,
-- and with a uniform [0, 1) draw the leave probability is exactly the chance.
--==============================================================================
local GuardianCatch = {}

GuardianCatch.None = "none"
GuardianCatch.Hauling = "hauling"
GuardianCatch.Abandoned = "abandoned"
GuardianCatch.Left = "left"
GuardianCatch.Confiscated = "confiscated"

-- The only shape this needs from CarryService's Held record.
export type Record = {
	guardianAbandoned: boolean?,
}

function GuardianCatch.Leaves(roll: number, chance: number): boolean
	return roll < chance
end

--==============================================================================
-- DECIDE, AND MARK THE RECORD ON A LEAVE
--
-- `draw` is called at most once, and only when a roll is genuinely owed -- which
-- is what lets a spec prove "never rerolls" by counting calls rather than by
-- hoping a random number cooperates.
--
-- Marks the record in place on "left". That write is part of the decision on
-- purpose: the mark and the choice must happen in the same resumption, or a
-- second guardian arriving in the same frame could roll the same pod again.
--==============================================================================
function GuardianCatch.Resolve(record: Record?, hauling: boolean,
	draw: () -> number, chance: number): string
	if hauling then
		return GuardianCatch.Hauling
	end
	if not record then
		return GuardianCatch.None
	end
	if record.guardianAbandoned == true then
		return GuardianCatch.Abandoned
	end
	if GuardianCatch.Leaves(draw(), chance) then
		record.guardianAbandoned = true
		return GuardianCatch.Left
	end
	return GuardianCatch.Confiscated
end

--==============================================================================
-- WHETHER THE GUARDIAN WALKS HOME HOLDING SOMETHING
--
-- NestService's `confiscateFrom` returns this. "hauling" is true because its
-- hands were ALREADY full -- the existing behaviour, where the victim keeps
-- their pod until the throw knocks it onto the road. Every other outcome except
-- a fresh confiscation leaves the pod with the victim, so the throw drops it.
--==============================================================================
function GuardianCatch.GuardianHolds(outcome: string): boolean
	return outcome == GuardianCatch.Confiscated or outcome == GuardianCatch.Hauling
end

return GuardianCatch
