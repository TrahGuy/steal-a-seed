--!strict
--==============================================================================
-- MARIGOLD'S FIRST GARDEN -- data and pure state transitions only.
--
-- Never rewards, never remotes, never a client claim. The server records a
-- milestone when a real action succeeds; everything here is the ordered copy and
-- the arithmetic that decides which step a saved record is on.
--
--==============================================================================
-- THE GUIDE ENDS AT THE HATCH, AND THAT IS A DELIBERATE CUT
--
-- Version 1 ran seven steps: steal -> bank -> place -> hatch -> PLANT the
-- hatchling -> receive earnings -> buy a bat. The last three are real gameplay
-- and still exist; they are no longer things a beginner is HELD in a tutorial
-- until they do. Buying a $5,000 bat is twenty minutes of garden income, which
-- is a strange thing to call "still in the tutorial".
--
-- What replaced them at the FRONT is the part a new player actually cannot
-- guess: that the treadmill is what makes a raid survivable. A fresh player
-- walks at 16 and Greenhollow's guardian runs at 20, so leaving without
-- training is losing the pod. Two steps now teach that before the first theft.
--==============================================================================
local Tutorial = {}

export type Progress = { Version: number, Done: { [string]: boolean }, Skipped: boolean }
export type Step = { Id: string, Title: string, Detail: string }

Tutorial.Action = "BeginnerGuide"
Tutorial.Version = 2

--==============================================================================
-- THE READINESS TARGET, AND WHAT IT IS NOT
--
-- 1,000 Speed is an exact anchor on GameConfig.Speed.Anchors -- WalkSpeed 22
-- against Greenhollow's guardian. It is the TUTORIAL'S readiness bar and
-- NOTHING ELSE: no biome checks it, no gate reads it, and BiomeData's
-- RecommendedSpeed is untouched. The road stays open at any score.
--==============================================================================
Tutorial.SpeedTarget = 1000

--==============================================================================
-- Titles are the ON-SCREEN INSTRUCTION and are meant to be read at a glance
-- while running. Details are the fallback prose: recovery states, the skip
-- card, and anywhere the visual guidance cannot reach.
--==============================================================================
Tutorial.Steps = {
	{
		Id = "train",
		Title = "Train your speed!",
		Detail = "Stand on your own treadmill and keep running. It is the only thing in the game that raises Speed.",
	},
	{
		Id = "speed",
		Title = "Reach 1,000 speed!",
		Detail = "Keep training until you hit 1,000. That is roughly what it takes to outrun Greenhollow's guardian while carrying a pod.",
	},
	{
		Id = "steal",
		Title = "Take a pod!",
		Detail = "Go to Greenhollow's nest and hold the Take prompt on a pod. Taking one wakes the guardian.",
	},
	{
		Id = "bank",
		Title = "Bring it to your plot!",
		Detail = "Run back across the red line. Crossing it banks the pod into your hotbar.",
	},
	{
		Id = "place",
		Title = "Place your pod here!",
		Detail = "Equip the pod from your hotbar, then tap or click an empty spot on your own soil.",
	},
	{
		Id = "hatch",
		Title = "Hatch your first plant!",
		Detail = "Wait for the pod's timer, then hold its Hatch prompt.",
	},
} :: { Step }

local keys: { [string]: boolean } = {}
for _, step in Tutorial.Steps do
	keys[step.Id] = true
end

--==============================================================================
-- WHAT VERSION 1 CALLED ITS STEPS
--
-- Kept so a saved v1 record can be READ. They are deliberately NOT in `keys`:
-- the gameplay services still call RecordTutorial("plant"/"earn"/"buy") on
-- success, and those calls are now harmless no-ops rather than edits to three
-- more files. If the guide ever wants those steps back, they still work.
--==============================================================================
local LEGACY_PAST_HATCH = { "hatch", "plant", "earn", "buy" }
local LEGACY_ANY = { "steal", "bank", "place", "hatch", "plant", "earn", "buy" }

function Tutorial.Default(): Progress
	return { Version = Tutorial.Version, Done = {}, Skipped = false }
end

function Tutorial.Record(progress: Progress, milestone: string): boolean
	if not keys[milestone] or progress.Done[milestone] then
		return false
	end
	progress.Done[milestone] = true
	return true
end

function Tutorial.Current(progress: Progress): (number, number)
	local first, count = #Tutorial.Steps + 1, 0
	for i, step in Tutorial.Steps do
		if progress.Done[step.Id] then
			count += 1
		elseif first > #Tutorial.Steps then
			first = i
		end
	end
	return first, count
end

function Tutorial.SetSkipped(progress: Progress, skipped: boolean): boolean
	if progress.Skipped == skipped then
		return false
	end
	progress.Skipped = skipped
	return true
end

--==============================================================================
-- MIGRATION, CALLED AFTER PROFILE VALIDATION
--
-- Two rules, and they are the whole of it:
--
--   1. NOBODY IS SENT BACKWARDS. A player who already stole, banked, placed or
--      hatched under version 1 is credited with the two new front steps as
--      well. They demonstrably got past that part of the game; re-teaching them
--      the treadmill because the step list changed underneath them would be the
--      update punishing them for having played.
--
--   2. ANYONE PAST THE OLD HATCH IS FINISHED. The guide now ENDS at the hatch,
--      so a v1 record carrying hatch/plant/earn/buy is a completed record. This
--      is what keeps finished players out of a tutorial they already did.
--
-- Possessions still prove steps, because a save is evidence: a planted pod
-- means it was placed, a grown plant or a hatched Tool or an Almanac entry
-- means it was hatched. Cash proves nothing and never did.
--==============================================================================
function Tutorial.Sanitise(raw: any, profile: any): Progress
	local p = Tutorial.Default()
	local legacy: { [string]: boolean } = {}
	if type(raw) == "table" then
		p.Skipped = raw.Skipped == true
		if type(raw.Done) == "table" then
			for _, key in LEGACY_ANY do
				if raw.Done[key] == true then
					legacy[key] = true
					if keys[key] then
						p.Done[key] = true
					end
				end
			end
			for key in keys do
				if raw.Done[key] == true then
					p.Done[key] = true
				end
			end
		end
	end

	-- How far the profile's own contents prove they got, as a step index.
	local through = 0
	for _, row in profile.Plants or {} do
		if type(row) == "table" then
			through = math.max(through, if row.Stage == 3 then 6 else 5)
		end
	end
	for _, row in profile.Held or {} do
		if type(row) == "table" then
			through = math.max(through, if row.Hatched == true then 6 else 4)
		end
	end
	if next(profile.Almanac or {}) then
		through = math.max(through, 6)
	end
	for _, key in LEGACY_PAST_HATCH do
		if legacy[key] then
			through = #Tutorial.Steps
		end
	end
	for i = 1, through do
		p.Done[Tutorial.Steps[i].Id] = true
	end

	--==========================================================================
	-- THE TWO NEW FRONT STEPS
	--
	-- Speed is server-owned and only the treadmill raises it, so a non-zero
	-- score IS proof of training -- there is no other faucet it could have come
	-- from. Rule 1 above then credits both to anybody already deeper in.
	--==========================================================================
	local speed = tonumber(profile.Speed) or 0
	if speed > 0 then
		p.Done.train = true
	end
	if speed >= Tutorial.SpeedTarget then
		p.Done.train = true
		p.Done.speed = true
	end
	for _, key in LEGACY_ANY do
		if legacy[key] or p.Done[key] then
			p.Done.train = true
			p.Done.speed = true
			break
		end
	end
	return p
end

return Tutorial
