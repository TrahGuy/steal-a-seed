--!strict
-- Steal The Artifact :: EconomyService
--
-- The one place an artifact turns into coins and experience.
--
--==============================================================================
-- WHY THIS EXISTS ALREADY, WITH ONLY ONE CALLER COMING
--
-- Because the moment a second place can mint coins, the economy stops being
-- something anybody can reason about. Cloud Cafe's audit names this as the
-- invariant that kept its economy sane: cash only mints from one call, and
-- everything that pays out goes through it.
--
-- So Phase 2's deposit, Phase 4's passive income and Phase 5's events all call
-- Award*. None of them touch PlayerDataService.AddCoins directly, and the day a
-- rate needs changing there is one file to change.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArtifactGame = ReplicatedStorage:WaitForChild("ArtifactGame")
local Shared = ArtifactGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ArtifactData = require(Shared:WaitForChild("ArtifactData"))

local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))

local EconomyService = {}
EconomyService.Priority = 25

local ECONOMY = ArtifactData.Economy

local function log(message: string)
	print("[Artifact/EconomyService] " .. message)
end

--==============================================================================
-- WHAT AN ARTIFACT IS WORTH
--
-- Pure, and separate from paying it out, so a UI can show a player what a
-- deposit WILL earn using the identical arithmetic that will earn it. A preview
-- computed a second way is a preview that eventually lies.
--==============================================================================
function EconomyService.ValueOf(artifactId: string): (number, number)
	local artifact = ArtifactData.ById[artifactId]
	if not artifact then
		return 0, 0
	end
	local coins = math.floor(artifact.Value * ECONOMY.DepositMultiplier)
	local experience = math.max(1, math.floor(artifact.Value * ECONOMY.ExperiencePerValue))
	return coins, experience
end

--==============================================================================
-- THE ONLY FAUCET
--
-- Returns (ok, coins, experience). Every failure is a refusal with a reason in
-- the log, never a silent zero -- a payout that quietly did not happen is the
-- hardest kind of economy bug to find, because the player reports it and the
-- server has nothing to show.
--==============================================================================
function EconomyService.AwardArtifact(player: Player, artifactId: string): (boolean, number, number)
	local artifact = ArtifactData.ById[artifactId]
	if not artifact then
		warn(string.format("[Artifact/EconomyService] %s: unknown artifact '%s'. Nothing awarded.",
			player.Name, tostring(artifactId)))
		return false, 0, 0
	end
	if not PlayerDataService.IsLoaded(player) then
		-- Refused rather than queued. Paying into a profile that has not loaded
		-- means paying into a default one, which is then either overwritten by
		-- the real load or written OVER the real save.
		warn(string.format("[Artifact/EconomyService] %s: profile not loaded, award refused.", player.Name))
		return false, 0, 0
	end

	local coins, experience = EconomyService.ValueOf(artifactId)

	local paid = PlayerDataService.AddCoins(player, coins)
	if not paid then
		return false, 0, 0
	end
	PlayerDataService.AddExperience(player, experience)
	PlayerDataService.RecordArtifact(player, artifactId)

	log(string.format("%s deposited %s (%s) for %d coins, %d xp.",
		player.Name, artifact.DisplayName, artifact.Rarity, coins, experience))
	return true, coins, experience
end

--==============================================================================
-- SPENDING
--
-- Checked and debited in ONE call. A caller that reads a balance, decides, then
-- debits has a window between the two, and two upgrades bought in the same
-- frame both pass the check.
--==============================================================================
function EconomyService.TrySpend(player: Player, amount: number, reason: string): boolean
	if type(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return false
	end
	local view = PlayerDataService.GetView(player)
	if not view or view.coins < amount then
		return false
	end
	local ok = PlayerDataService.AddCoins(player, -math.floor(amount))
	if ok then
		log(string.format("%s spent %d on %s.", player.Name, math.floor(amount), reason))
	end
	return ok
end

function EconomyService.Start()
	log(string.format("Ready. Deposit x%.2f, %.3f xp per coin of value, %d xp per level.",
		ECONOMY.DepositMultiplier, ECONOMY.ExperiencePerValue, ECONOMY.ExperiencePerLevel))
end

return EconomyService
