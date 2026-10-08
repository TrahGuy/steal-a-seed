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
--
--==============================================================================
-- ONE LESSON AFTER THE HATCH: THE TRAVEL BUTTONS (owner, 2026-10-08; Version 3)
--
-- Step 7, `travel`, teaches OBBY and TELEPORT TO PLOT. It is recorded only on a
-- successful PlotService.TeleportHome while the hatch is already done (Needs,
-- below) -- never by a client, never before the hatch. It pays nothing, so the
-- FIRST LOOP still ends at the hatch: the Bonus Chest opens there and the
-- TutorialCompleted analytics event is counted there (FirstLoopDone), exactly
-- as under Version 2. IsComplete -- every step, travel included -- is only
-- what decides that the guide is finished and stands down.
--==============================================================================
local Tutorial = {}

export type Progress = {
	Version: number,
	Done: { [string]: boolean },
	Skipped: boolean,
	--==========================================================================
	-- HOW MANY RESERVED PODS THIS PLAYER HAS BEEN GIVEN
	--
	-- The public Greenhollow nest is ONE nest of five pods that only restocks at
	-- dawn, so a beginner can arrive at "Take a pod!" and find it stripped. A
	-- reserved pod is the answer, and this is the thing that stops the answer
	-- becoming a tap: banked pods can be SOLD (EconomyService.SellHeld takes
	-- every Tool in the backpack), so "give them one whenever they have none"
	-- is a loop that mints Tiny Commons for as long as somebody keeps selling
	-- them. Absent on every existing save, which reads as zero.
	--==========================================================================
	PodGrants: number,
}
export type Step = { Id: string, Title: string, Detail: string }

Tutorial.Action = "BeginnerGuide"
Tutorial.Version = 3

--==============================================================================
-- THREE, WHICH IS GENEROUS AND STILL BOUNDED
--
-- One is the honest number -- the feature is "you always have a pod to start
-- with" -- but a beginner can lose one to a guardian, to a mistimed drop, or to
-- a loose pod despawning while they run back for it, and being told to wait
-- until dawn is exactly the wall this exists to remove. Three covers those and
-- caps the sell-loop at three of the cheapest item in the game.
--
-- Past it they are not stuck: the public nest still restocks every dawn, and by
-- then they have been shown where it is.
--==============================================================================
Tutorial.MaxPodGrants = 3

--==============================================================================
-- THE READINESS TARGET, AND WHAT IT IS NOT
--
-- 400 Speed (owner, 2026-10-08; it was 1,000): about 20 s on a tier-1 mill
-- instead of 50. It is the TUTORIAL'S readiness bar and NOTHING ELSE: no biome
-- checks it, no gate reads it, and BiomeData's RecommendedSpeed is untouched.
-- The road stays open at any score.
--
-- 400 is not an anchor. GameConfig.Speed's log curve walks it at 21.2 (1,000
-- walks at 22), which is why the guide's promise -- "this is enough to get the
-- pod home" -- is kept by the first raid's own chase speed (BiomeData
-- Greenhollow, FirstRaidChaseSpeed) rather than by the number alone. Lowering
-- it sends nobody backwards: Sanitise credits `speed` at or above the target.
--==============================================================================
Tutorial.SpeedTarget = 400

-- The target as the guide writes it: whole, with thousands commas ("400",
-- "1,000"). Every word about the goal is built from this, so the title, the
-- pointer's count and the spotlight cannot disagree with the number.
local function whole(n: number): string
	local digits = tostring(math.floor(n))
	local out = digits
	repeat
		local before = out
		out = string.gsub(out, "^(%d+)(%d%d%d)", "%1,%2")
	until out == before
	return out
end
Tutorial.SpeedTargetText = whole(Tutorial.SpeedTarget)

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
		Title = "Reach " .. Tutorial.SpeedTargetText .. " speed!",
		Detail = "Keep training until you hit " .. Tutorial.SpeedTargetText
			.. ". That is roughly what it takes to outrun Greenhollow's guardian while carrying a pod.",
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
	{
		Id = "travel",
		Title = "Get around fast!",
		Detail = "From the Safe Zone, OBBY takes you to the Floating Garden and TELEPORT TO PLOT takes you home.",
	},
} :: { Step }

local keys: { [string]: boolean } = {}
-- Each step's place in the list, so nothing below hard-codes a number.
local indexOf: { [string]: number } = {}
for i, step in Tutorial.Steps do
	keys[step.Id] = true
	indexOf[step.Id] = i
end

--==============================================================================
-- A MILESTONE THAT WAITS FOR ANOTHER
--
-- `travel` is recorded on any successful teleport home, and a beginner may press
-- TELEPORT TO PLOT long before their first hatch. Recorded then, it would tick
-- off a lesson they were never given -- so Record refuses it until the hatch is
-- done, and the teleport that follows the hatch is the one that counts.
--==============================================================================
Tutorial.Needs = { travel = "hatch" } :: { [string]: string }

--==============================================================================
-- THE FIRST LOOP: EVERY STEP UP TO AND INCLUDING THE HATCH
--
-- The six steps Version 2 called the whole guide. The Bonus Chest opens when
-- they are done and Metrics counts TutorialCompleted then, so step 7 delays
-- neither and the analytics series keeps its meaning.
--==============================================================================
local FIRST_LOOP = indexOf.hatch

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
	return { Version = Tutorial.Version, Done = {}, Skipped = false, PodGrants = 0 }
end

--==============================================================================
-- WHO IS OWED A RESERVED POD
--
-- Pure, and deliberately says nothing about the world: whether one should be
-- STANDING somewhere also depends on daylight and on what the player already
-- has, and those are TutorialPodService's business. This is only the record's
-- opinion.
--
-- SKIPPED IS NOT CONSULTED, ON PURPOSE. Skip hides the guide; it does not
-- surrender anything, and a player who skips, gets stuck at an empty nest and
-- presses Resume must not have been quietly disinherited in between.
--
-- It ends at the HATCH rather than at the steal, because the run this protects
-- is the whole first loop -- take, bank, place, hatch -- and losing the pod at
-- any point before the end leaves a beginner in exactly the state the feature
-- exists to prevent.
--==============================================================================
function Tutorial.PodEligible(progress: Progress): boolean
	if progress.Done.hatch == true then
		return false
	end
	if progress.Done.train ~= true or progress.Done.speed ~= true then
		return false
	end
	return (progress.PodGrants or 0) < Tutorial.MaxPodGrants
end

--==============================================================================
-- DOES THIS PLAYER ALREADY HAVE A FIRST POD, IN ANY STATE AT ALL
--
-- The four places one can be, and any of them means the tutorial is not blocked
-- and nothing is owed:
--
--   carrying    on their head, right now
--   inWorld     standing where it was reserved, or dropped on the road
--   held        an unhatched pod row in the hotbar (a BANKED one)
--   plants      a row still below Stage 3, which is planted and not yet hatched
--
-- AN ORDINARY POD COUNTS. If a beginner got one off the public nest they do not
-- need a reserved one, and handing them a second is the duplicate the whole
-- feature has to avoid. That is also why this asks about POSSESSION rather than
-- about a particular pod's identity: what a beginner is owed is A pod.
--
-- Pure, and takes the facts rather than a Player, so the decision can be tested
-- without a world -- and so that the one place that gathers them is the one
-- place a fact can be gathered wrongly.
--
-- THE STARTER POD IS NOT ONE OF THEM (FirstMinute, 2026-10-08). `starterAt` is
-- the profile's StarterAt -- the PlantedAt of the pod the game planted for a
-- brand-new player -- and that row, still growing, is skipped: it was given,
-- not stolen, and counting it would hold back the reserved pod the steal step
-- needs. 0 or absent means no starter and skips nothing.
--==============================================================================
export type Possessions = {
	carrying: boolean,
	inWorld: boolean,
	held: { any },
	plants: { any },
	starterAt: number?,
}

function Tutorial.HasOutstandingPod(have: Possessions): boolean
	if have.carrying or have.inWorld then
		return true
	end
	for _, row in have.held or {} do
		if type(row) == "table" and row.Hatched ~= true then
			return true
		end
	end
	local starterAt = tonumber(have.starterAt) or 0
	for _, row in have.plants or {} do
		-- Stage 3 is grown. Anything below it is still waiting to hatch, which is
		-- the same reading Sanitise uses below to credit the `place` step.
		if type(row) == "table" and (tonumber(row.Stage) or 3) < 3
			and not (starterAt > 0 and tonumber(row.PlantedAt) == starterAt) then
			return true
		end
	end
	return false
end

function Tutorial.Record(progress: Progress, milestone: string): boolean
	if not keys[milestone] or progress.Done[milestone] then
		return false
	end
	local needs = Tutorial.Needs[milestone]
	if needs and progress.Done[needs] ~= true then
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

--==============================================================================
-- IS THE GUIDE FINISHED
--
-- Every step recorded, travel included, and nothing else. Skipping HIDES the
-- guide -- see PodEligible for why it surrenders nothing -- so it does not
-- finish it either, and Skipped is not consulted. The Bonus Chest does NOT
-- open here: it opens at FirstLoopDone, below, as it always has.
--==============================================================================
function Tutorial.IsComplete(progress: Progress): boolean
	for _, step in Tutorial.Steps do
		if progress.Done[step.Id] ~= true then
			return false
		end
	end
	return true
end

--==============================================================================
-- IS THE FIRST LOOP DONE: train through hatch, every one of them
--
-- What Version 2's IsComplete answered, kept as its own question so that adding
-- a step after the hatch moves neither the Bonus Chest (BonusChestService) nor
-- the TutorialCompleted event (Metrics). Skipped is not consulted.
--==============================================================================
function Tutorial.FirstLoopDone(progress: Progress): boolean
	for i = 1, FIRST_LOOP do
		if progress.Done[Tutorial.Steps[i].Id] ~= true then
			return false
		end
	end
	return true
end

-- Whether `milestone` is one of the first loop's steps (train..hatch).
function Tutorial.InFirstLoop(milestone: string): boolean
	local i = indexOf[milestone]
	return i ~= nil and i <= FIRST_LOOP
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
--   3. A RECORD SAVED BEFORE VERSION 3 THAT IS PAST THE HATCH HAS TRAVELLED
--      (2026-10-08, the owner's call). Step 7 came after every v1 and v2 player
--      had finished, so such a record -- its hatch done, or proven by anything
--      below -- is credited `travel` at load: nobody finished is put back into
--      the guide for a lesson about buttons. A Version 3 record is NOT credited:
--      one that hatched and left before teleporting home keeps step 7 open and
--      meets it on its return. A player still before the hatch meets it at the
--      end either way.
--
-- Possessions still prove steps, because a save is evidence: a planted pod
-- means it was placed, a grown plant or a hatched Tool or an Almanac entry
-- means it was hatched. Cash proves nothing and never did.
--
-- EXCEPT ON A PROFILE THAT WAS GIVEN THE STARTER POD (FirstMinute, 2026-10-08).
-- Its first garden is a gift -- a pod in the soil, then a grown plant, an
-- Almanac entry, perhaps a lifted Tool -- and every one of those would "prove"
-- the whole first loop at the next load. Such a profile was created under the
-- guide that records every step as it happens, so its record is the evidence
-- and its possessions prove nothing. Every older save reads exactly as before:
-- no starter, StarterAt 0, the same proofs.
--==============================================================================
function Tutorial.Sanitise(raw: any, profile: any): Progress
	local p = Tutorial.Default()
	local legacy: { [string]: boolean } = {}
	-- Saved before Version 3 (rule 3): an older stamp, or none at all -- a record
	-- from before the guide had versions, or no record, which only possessions
	-- can speak for. A stamp that is not a number is no stamp.
	local version = if type(raw) == "table" then tonumber(raw.Version) else nil
	local beforeTravel = version == nil or version ~= version or version < 3
	if type(raw) == "table" then
		p.Skipped = raw.Skipped == true
		--======================================================================
		-- A COUNT OFF THE WIRE IS A CLAIM. Absent, a string, a float, NaN or a
		-- negative all read as zero, and it is clamped to the cap so a corrupted
		-- save can neither mint grants nor lock somebody out of them for ever.
		--======================================================================
		local grants = tonumber(raw.PodGrants)
		if grants and grants == grants then
			p.PodGrants = math.clamp(math.floor(grants), 0, Tutorial.MaxPodGrants)
		end
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

	-- How far the profile's own contents prove they got, as a step index -- on a
	-- profile that never had the starter pod (above).
	local through = 0
	if (tonumber(profile.StarterAt) or 0) <= 0 then
		for _, row in profile.Plants or {} do
			if type(row) == "table" then
				through = math.max(through, if row.Stage == 3 then indexOf.hatch else indexOf.place)
			end
		end
		for _, row in profile.Held or {} do
			if type(row) == "table" then
				through = math.max(through, if row.Hatched == true then indexOf.hatch else indexOf.bank)
			end
		end
		if next(profile.Almanac or {}) then
			through = math.max(through, indexOf.hatch)
		end
	end
	-- Past the old hatch by any milestone: the first loop is done. Whether that
	-- also finishes the guide is rule 3's question, below.
	for _, key in LEGACY_PAST_HATCH do
		if legacy[key] then
			through = math.max(through, indexOf.hatch)
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

	-- Rule 3: a record saved before Version 3 and past the hatch has travelled.
	if beforeTravel and p.Done.hatch then
		p.Done.travel = true
	end
	return p
end

return Tutorial
