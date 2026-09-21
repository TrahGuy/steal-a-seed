--!strict
--==============================================================================
-- OFFLINE EARNINGS: THE ARITHMETIC, AND NOTHING ELSE
--
-- Not a service. PlayerDataService calls `accrue` once, at the moment a saved
-- profile is loaded -- the only moment LastSeen still says when the player left,
-- because the first write of the new session overwrites it. EconomyService pays
-- the claim; this file never touches cash, a player or an Instance, so the whole
-- rule can be tested on a table.
--
-- THE RULE (numbers in SeedData.Offline)
--
--   * Gone less than MinAwaySeconds: nothing. A server hop is not "away".
--   * Otherwise every GROWN plant saved in the ground pays Efficiency of its
--     normal IncomePerSecond for the time away. Pods pay nothing, as online.
--   * Unclaimed credit carries over to the next visit, and the carried total
--     is capped at MaxCreditSeconds -- leaving a claim unopened for a week does
--     not stack a week of nights.
--   * The pending sum is stored BEFORE the x2 pass; the pass is applied when
--     the claim is paid, exactly as it is applied to income online.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local CreatureModel = require(Shared:WaitForChild("CreatureModel"))

local OFF = SeedData.Offline
local GROWN = CreatureModel.STAGE_GROWN

local OfflineEarnings = {}

export type Garden = {
	-- Summed IncomePerSecond of every grown plant, before the pass.
	rate: number,
	grown: number,
	-- The single best earner, for the claim card's portrait.
	best: string?,
	bestTier: number?,
}

-- What the saved garden earns per second, read from profile rows alone.
function OfflineEarnings.garden(plants: any): Garden
	local out: Garden = { rate = 0, grown = 0, best = nil, bestTier = nil }
	if type(plants) ~= "table" then
		return out
	end
	local bestIncome = -1
	for _, row in ipairs(plants) do
		if type(row) == "table" and tonumber(row.Stage) == GROWN then
			local species = SeedData.Get(tostring(row.SpeciesId))
			local tier = tonumber(row.Tier)
			if species and tier and tier == tier then
				local income = SeedData.IncomePerSecond(species, tier)
				out.rate += income
				out.grown += 1
				if income > bestIncome then
					bestIncome = income
					out.best = species.Id
					out.bestTier = math.floor(tier)
				end
			end
		end
	end
	return out
end

--==============================================================================
-- CREDIT ONE ABSENCE
--
-- Mutates the profile's OfflineCash / OfflineSeconds / OfflineAway and returns
-- the cash and seconds it added (0, 0 when the absence does not qualify or the
-- garden earns nothing). `now` is os.time() on the server; LastSeen was written
-- by the server that saved the last session. A LastSeen in the future (clock
-- skew between servers) is an absence of less than zero and credits nothing.
--==============================================================================
function OfflineEarnings.accrue(profile: any, now: number): (number, number)
	local last = tonumber(profile.LastSeen)
	if last == nil or last ~= last or now ~= now then
		return 0, 0
	end
	local away = now - last
	if away < OFF.MinAwaySeconds then
		return 0, 0
	end
	local already = math.clamp(tonumber(profile.OfflineSeconds) or 0, 0, OFF.MaxCreditSeconds)
	local credit = math.floor(math.min(away, OFF.MaxCreditSeconds - already))
	if credit <= 0 then
		return 0, 0
	end
	local garden = OfflineEarnings.garden(profile.Plants)
	local cash = math.floor(garden.rate * credit * OFF.Efficiency)
	if cash <= 0 then
		return 0, 0
	end
	local pending = math.max(tonumber(profile.OfflineCash) or 0, 0)
	profile.OfflineCash = math.min(pending + cash, GameConfig.Save.MaxCash)
	profile.OfflineSeconds = already + credit
	profile.OfflineAway = math.max(tonumber(profile.OfflineAway) or 0, 0) + math.floor(away)
	return cash, credit
end

return OfflineEarnings
