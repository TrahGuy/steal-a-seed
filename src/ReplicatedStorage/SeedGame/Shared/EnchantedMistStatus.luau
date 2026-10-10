--!strict
--==============================================================================
-- Steal a Seed :: EnchantedMistStatus (2026-10-11)
--
-- What the shared ENCHANTED MIST sign says at a moment, from what the server
-- has published -- pure, so a spec can step it through every state without a
-- server. The sign calls it at most once a second with
-- Workspace:GetServerTimeNow(); nothing is networked to count down.
--
-- TRUTHFUL (the owner's brief): an eligible Mist waits for the next completed
-- reset, so its start is never shown as a guaranteed "Starts in" -- only as an
-- ESTIMATE, which moves when a Pod Rush holds dusk back.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))

local EnchantedMistStatus = {}

local STATES = EnchantedMistConfig.States
local WORDS = EnchantedMistConfig.Sign.Words

export type View = {
	state: string?,
	eligibleAt: number?,
	endsAt: number?,
	worldPhase: string?,
	worldPhaseEndsAt: number?,
	nightPhase: string,
	nightSeconds: number,
}

-- "05:00": minutes and seconds, rounded UP (a timer never reads 00:00 while
-- time is left), minutes as many digits as they need.
function EnchantedMistStatus.clock(seconds: number): string
	local s = math.max(0, math.ceil(seconds - 1e-6))
	return string.format("%02d:%02d", math.floor(s / 60), s % 60)
end

-- The sign's second line and its note (or nil), at `now`.
function EnchantedMistStatus.describe(v: View, now: number): (string, string?)
	local state = v.state
	if state == STATES.Disabled then
		return WORDS.ComingSoon, nil
	end
	if state == STATES.Active then
		local endsAt = v.endsAt
		if type(endsAt) ~= "number" or endsAt <= now then
			return WORDS.Syncing, nil
		end
		return string.format(WORDS.Active, EnchantedMistStatus.clock(endsAt - now)), nil
	end
	if state == STATES.Cooldown or state == STATES.Eligible then
		local eligibleAt = v.eligibleAt
		if type(eligibleAt) ~= "number" then
			return WORDS.Syncing, nil
		end
		if eligibleAt > now then
			return string.format(WORDS.Cooldown, EnchantedMistStatus.clock(eligibleAt - now)), WORDS.CooldownNote
		end
		-- Eligible: the next completed reset starts it.
		local phaseEnds = v.worldPhaseEndsAt
		if v.worldPhase == v.nightPhase and type(phaseEnds) == "number" then
			return string.format(WORDS.Resetting, EnchantedMistStatus.clock(math.max(0, phaseEnds - now))), nil
		end
		if type(phaseEnds) == "number" and phaseEnds > now then
			-- Dusk, the night, then the start: an estimate, never a promise.
			return WORDS.Eligible, string.format(WORDS.EstimateNote,
				EnchantedMistStatus.clock(phaseEnds - now + v.nightSeconds))
		end
		return WORDS.Eligible, nil
	end
	return WORDS.Syncing, nil
end

return EnchantedMistStatus
