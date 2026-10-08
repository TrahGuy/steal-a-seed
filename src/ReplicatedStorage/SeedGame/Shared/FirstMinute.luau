--!strict
--==============================================================================
-- THE FIRST MINUTE (owner, 2026-10-08) -- data and pure rules only.
--
-- A new player should see their garden earning inside their first minute and
-- reach the first steal in under half the time it took. Four changes, each of
-- them once per profile:
--
--   1. THE STARTER POD. A brand-new profile finds ONE Tiny Petalpip -- a
--      Greenhollow Common -- already planted in its own soil, on the normal
--      30 s Tiny timer. It hatches BY ITSELF where it stands, with the normal
--      roll reveal and a notice, and from then on it is an ordinary plant: it
--      earns, walks, and can be lifted or sold. PlantService plants and hatches
--      it; this file says who is owed one and what is said about it.
--   2. THE TRAINING GOAL is 400 Speed (TutorialData.SpeedTarget).
--   3. THE FIRST RAID is fair at 400: BiomeData Greenhollow's
--      FirstRaidChaseSpeed, which NestService runs only for a thief whose
--      `steal` step is not done, on that first theft.
--   4. THE FIRST CATCH -- the pod taken while `steal` is not done -- is at
--      least Big (catchTier, CarryService), and its reveal says so
--      (catchWords, HatchFX). Words only; nothing new is drawn.
--
--==============================================================================
-- THE STARTER IS NEVER TUTORIAL PROGRESS
--
-- It records no milestone (PlantService hatches it without RecordTutorial),
-- proves no step (TutorialData.Sanitise stops reading possessions as proof the
-- moment a profile has had one -- every step it has done since was RECORDED),
-- is not a pod the beginner "already has" (TutorialData.HasOutstandingPod's
-- starterAt, so the reserved pod is still offered), opens no Bonus Chest
-- (that reads the recorded first loop) and earns no hatch-bonus spin (its
-- reveal goes to the clients and not to PlantService.OnRevealed's listeners).
-- The guide's own hatch step still teaches holding Hatch, on the stolen pod.
--==============================================================================
local SeedData = require(script.Parent:WaitForChild("SeedData"))

local FirstMinute = {}

--==============================================================================
-- THE STARTER
--
-- Petalpip, the second of Greenhollow's two Commons -- not Nubkin, because
-- Nubkin is the reserved pod (TutorialPodService) and the guide's own hatch, on
-- the stolen pod, should still be able to say NEW DISCOVERY.
--==============================================================================
FirstMinute.StarterSpecies = "petalpip"
FirstMinute.StarterTier = 1

-- The step words the guide adds while it grows (TutorialUI, steps 1 and 2).
FirstMinute.GrowingWords = "Your first pod is growing!"
-- The notice at its reveal, sent by the server (Notice.ServerNotice).
FirstMinute.HatchedTitle = "Your first plant hatched!"
FirstMinute.NoticeKey = "first-plant"

-- "It earns $5/s": the reveal's own figure (SeedData.IncomePerSecond), in the
-- HUD's own compact form, so the notice and the label above the plant agree.
function FirstMinute.hatchedDetail(income: number, compact: (number) -> string): string
	return "It earns $" .. compact(income) .. "/s"
end

-- The species the starter is, or nil when the sheet no longer has it -- which
-- turns the feature off rather than planting nothing with a name.
function FirstMinute.starter(): SeedData.Species?
	local species = SeedData.Get(FirstMinute.StarterSpecies)
	if species and species.Biome == "greenhollow" and species.Rarity == "Common" then
		return species
	end
	return nil
end

--==============================================================================
-- WHO IS OWED ONE: A BRAND-NEW PROFILE, ONCE EVER
--
-- The owner's list, every item of it: no Plants, no Held, no Almanac, Speed 0,
-- nothing done in the tutorial, and no starter given before (StarterAt, which
-- a progress reset keeps). Anybody who has played at all fails one of them, so
-- an existing player never gets one, and a rejoin finds StarterAt set.
--
-- Read off the sanitised profile, which has every field; anything else -- no
-- profile, a junk one -- is owed nothing.
--==============================================================================
function FirstMinute.owed(profile: any): boolean
	if type(profile) ~= "table" then
		return false
	end
	if tonumber(profile.StarterAt) ~= 0 then
		return false
	end
	if tonumber(profile.Speed) ~= 0 then
		return false
	end
	for _, field in { "Plants", "Held", "Almanac" } do
		local list = profile[field]
		if type(list) ~= "table" or next(list) ~= nil then
			return false
		end
	end
	local tutorial = profile.Tutorial
	if type(tutorial) ~= "table" or type(tutorial.Done) ~= "table" then
		return false
	end
	for _, done in tutorial.Done do
		if done == true then
			return false
		end
	end
	return true
end

--==============================================================================
-- THE FIRST CATCH
--
-- A Tiny becomes Big when it is taken; anything bigger stays as it rolled. The
-- size is the pod's whole identity from then on -- the model in the arms, the
-- carry weight, the banked row, Big's 60 s on the owner's ladder, its income.
--==============================================================================
FirstMinute.CatchTier = 2

function FirstMinute.catchTier(tier: number): number
	local whole = math.floor(tonumber(tier) or SeedData.BaseTier)
	return math.max(math.clamp(whole, 1, SeedData.TierCount), FirstMinute.CatchTier)
end

-- "BIG! Your first catch." -- the size it hatched at, in its own word.
function FirstMinute.catchWords(tier: number): string
	return string.upper(SeedData.TierName(tier)) .. "! Your first catch."
end

--==============================================================================
-- IS THIS HATCH THE FIRST CATCH COMING UP
--
-- The take writes down what was caught (FirstCatchSpecies, FirstCatchTier); the
-- first hatch of that species at that size is the one whose reveal says so, and
-- answering yes clears the note so it is said once. A pod has no identity that
-- survives the bag and the soil (see TutorialPodService), so this matches by
-- what it IS -- and the words are all that ride on it.
--==============================================================================
function FirstMinute.takeCatch(profile: any, speciesId: string, tier: number): boolean
	if type(profile) ~= "table" then
		return false
	end
	local waiting = profile.FirstCatchSpecies
	if type(waiting) ~= "string" or waiting == "" then
		return false
	end
	if waiting ~= speciesId or tonumber(profile.FirstCatchTier) ~= tier then
		return false
	end
	profile.FirstCatchSpecies = ""
	profile.FirstCatchTier = 0
	return true
end

return FirstMinute
