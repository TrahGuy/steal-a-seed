--!strict
--==============================================================================
-- THE RESERVED BEGINNER POD
--
-- Two kinds of check, kept apart on purpose:
--
--   PURE      the entitlement rule, the possession rule, the grant counter and
--             the save migration. No world, no Play session, no DataStore.
--
--   FIXTURE   real Instances in a throwaway folder under Workspace, tagged the
--             way the game tags pods, so the world-side lookup is exercised
--             against actual CollectionService behaviour rather than a mock of
--             it. The folder is destroyed at the end.
--
-- WHAT THIS FILE CANNOT COVER, and does not claim to:
--
--   * A SECOND REAL CLIENT. Everything here runs on one datamodel. A fake
--     `{ UserId = n }` table is not a Player and pressing a prompt is not a
--     remote, so the refusal path is asserted at the level it is WRITTEN --
--     an attribute compared against a user id -- and the actual two-client
--     theft attempt is a live test recorded in KB/HANDOFF.md.
--   * The guardian chase, the carry pipeline and the hatch, which are live
--     gameplay and are verified in Play.
--
-- NOTHING HERE TOUCHES A SAVE. No profile is loaded, no DataStore is opened,
-- and every profile below comes from ProfileSchema.Default() in memory.
--==============================================================================
local CollectionService = game:GetService("CollectionService")

local Shared = game.ReplicatedStorage.SeedGame.Shared
local Data = require(Shared.TutorialData)
local Config = require(Shared.GameConfig)
local SeedData = require(Shared.SeedData)
local Schema = require(game.ServerScriptService.SeedGameServer.ProfileSchema)
local PodService = require(game.ServerScriptService.SeedGameServer.TutorialPodService)

local pass = 0
local function check(ok: boolean, label: string)
	assert(ok, label)
	pass += 1
end

--==============================================================================
-- A BEGINNER WHO HAS DONE THE TRAINING AND NOTHING ELSE
--==============================================================================
local function beginner(): any
	local p = Schema.Default()
	p.Tutorial.Done.train = true
	p.Tutorial.Done.speed = true
	return p
end

local NOTHING: Data.Possessions = {
	carrying = false, inWorld = false, held = {}, plants = {},
}

--==============================================================================
-- WHAT IS RESERVED, AND WHETHER IT IS REAL
--
-- The service names a species and a tier. If either drifts out of the data the
-- feature would spawn nothing at all, silently, and the only symptom would be a
-- tutorial that is blocked again.
--==============================================================================
local nubkin = SeedData.Get("nubkin") :: any
check(nubkin ~= nil, "the reserved species is registered")
check(nubkin.Biome == "greenhollow", "it belongs to the biome the guide sends them to")
check(SeedData.TierName(1) == "Tiny", "tier 1 is the floor of the ladder")
--==============================================================================
-- AND THAT IT IS A COMMON, WHICH IS THE RARITY CLAIM IN THE BRIEF.
-- Read off the drop table rather than asserted about a name: a species promoted
-- out of Common later must fail here rather than quietly become a free Epic.
--==============================================================================
check(nubkin.Rarity == "Common", "the reserved species is a Common")

--==============================================================================
-- 1. AN EMPTY PUBLIC NEST STILL PROVIDES AN ELIGIBLE BEGINNER'S POD
--
-- Entitlement is a property of the RECORD. It cannot depend on how many pods
-- happen to be standing, which is exactly the coupling that blocked the guide.
--==============================================================================
local fresh = beginner()
check(Data.PodEligible(fresh.Tutorial), "a trained beginner is owed a pod")
check(not Data.HasOutstandingPod(NOTHING), "with nothing in hand, one is owed")

local untrained = Schema.Default()
check(not Data.PodEligible(untrained.Tutorial), "before training, nothing is owed")
untrained.Tutorial.Done.train = true
check(not Data.PodEligible(untrained.Tutorial), "training alone is not the bar")
untrained.Tutorial.Done.speed = true
check(Data.PodEligible(untrained.Tutorial), "the readiness bar is both milestones")

--==============================================================================
-- 2. TWO BEGINNERS EACH RECEIVE THEIR OWN
--
-- Pure half: two records are independent, and one player's grant does not
-- consume another's. The world half -- two pods, two spots, no overlap -- is the
-- geometry check further down.
--==============================================================================
local a, b = beginner(), beginner()
a.Tutorial.PodGrants = 1
check(Data.PodEligible(a.Tutorial) and Data.PodEligible(b.Tutorial),
	"two beginners are owed one each")
check(a.Tutorial.PodGrants ~= b.Tutorial.PodGrants, "their counters are their own")

--==============================================================================
-- 3. ANOTHER PLAYER CANNOT TAKE A RESERVED POD
--
-- The rule as CarryService.TryTake writes it: an owner attribute that is set and
-- does not match the taker refuses, and one that is absent lets everybody
-- through. Asserted here on the values; asserted for real with two clients in
-- Play, because a forged request is a remote and this file has none.
--==============================================================================
local function takeAllowed(owner: number?, taker: number): boolean
	return owner == nil or owner == taker
end
check(takeAllowed(nil, 7), "an ordinary pod is takeable by anybody")
check(takeAllowed(7, 7), "the owner may take their own")
check(not takeAllowed(7, 8), "a stranger may not")
check(not takeAllowed(7, 0), "nor may an unauthenticated id")

--==============================================================================
-- 4. REPEATED REQUESTS PRODUCE NO EXTRA COPIES
--
-- The service places only when the possession rule says nothing is outstanding,
-- and a placed pod IS possession -- so the second pass through the same state
-- is a no-op. Modelled here as the exact sequence the tick runs.
--==============================================================================
local world = { inWorld = false }
local placed = 0
local function tick(progress: any, have: Data.Possessions)
	if not Data.PodEligible(progress) then return end
	if Data.HasOutstandingPod(have) then return end
	placed += 1
	progress.PodGrants += 1
	world.inWorld = true
end

local spam = beginner()
local have: Data.Possessions = { carrying = false, inWorld = false, held = {}, plants = {} }
for _ = 1, 50 do
	have.inWorld = world.inWorld
	tick(spam.Tutorial, have)
end
check(placed == 1, "fifty passes place exactly one pod")
check(spam.Tutorial.PodGrants == 1, "and count exactly one grant")

--==============================================================================
-- 5. CARRY -> DROP -> RECOVER -> BANK -> PLACE -> HATCH IS ONE POD THROUGHOUT
--
-- Every intermediate state has to read as "already has one", or the run would
-- mint a second pod partway through it. Walked one state at a time.
--==============================================================================
local carried: Data.Possessions = { carrying = true, inWorld = false, held = {}, plants = {} }
check(Data.HasOutstandingPod(carried), "carrying counts")

local dropped: Data.Possessions = { carrying = false, inWorld = true, held = {}, plants = {} }
check(Data.HasOutstandingPod(dropped), "dropped on the road counts")

local banked: Data.Possessions = { carrying = false, inWorld = false,
	held = { { Id = "nubkin", Tier = 1, Hatched = false } }, plants = {} }
check(Data.HasOutstandingPod(banked), "banked in the hotbar counts")

local planted: Data.Possessions = { carrying = false, inWorld = false, held = {},
	plants = { { SpeciesId = "nubkin", Tier = 1, Stage = 1 } } }
check(Data.HasOutstandingPod(planted), "planted and unhatched counts")

local sprouting: Data.Possessions = { carrying = false, inWorld = false, held = {},
	plants = { { SpeciesId = "nubkin", Tier = 1, Stage = 2 } } }
check(Data.HasOutstandingPod(sprouting), "mid-growth counts")

local grown: Data.Possessions = { carrying = false, inWorld = false, held = {},
	plants = { { SpeciesId = "nubkin", Tier = 1, Stage = 3 } } }
check(not Data.HasOutstandingPod(grown), "a GROWN plant is a finished pod, not an outstanding one")

--==============================================================================
-- ...AND THE FINISHED RUN CLOSES ENTITLEMENT ANYWAY, so the grown case above
-- can never actually ask for a replacement. Both belts, on purpose: the
-- possession rule alone would hand a pod to somebody who sold theirs, and the
-- entitlement rule alone would hand one to somebody still carrying it.
--==============================================================================
local finished = beginner()
for _, step in Data.Steps do
	finished.Tutorial.Done[step.Id] = true
end
check(not Data.PodEligible(finished.Tutorial), "a hatched beginner is owed nothing")

--==============================================================================
-- 6. DEATH, RESPAWN, DISCONNECT AND REJOIN DUPLICATE NOTHING AND LOSE NOTHING
--
-- A rejoin is a save round trip, so this is the round trip: build a profile
-- mid-run, sanitise it as a load would, and check both that the entitlement
-- survives and that everything else on the profile does.
--==============================================================================
local mid = beginner()
mid.Tutorial.PodGrants = 1
mid.Cash = 4321
mid.Speed = 1500
mid.Held = { { Id = "nubkin", Tier = 1, Hatched = false } }
mid.Plants = { { SpeciesId = "petalpip", PlantedAt = 100, Tier = 2, X = 1, Z = 2, Stage = 1, Facing = 0 } }
mid.MillTier = 3
mid.Weapons = { rootwood_bat = true }

local rejoined = Schema.Sanitise(mid)
check(rejoined.Cash == 4321, "cash survives the round trip")
check(rejoined.Speed == 1500, "speed survives")
check(#rejoined.Held == 1 and rejoined.Held[1].Id == "nubkin", "the banked pod survives")
check(#rejoined.Plants == 1 and rejoined.Plants[1].SpeciesId == "petalpip", "the plant survives")
check(rejoined.MillTier == 3, "the mill level survives")
check(rejoined.Weapons.rootwood_bat == true, "the weapon survives")
check(rejoined.Tutorial.PodGrants == 1, "the grant count survives")
check(Data.HasOutstandingPod({ carrying = false, inWorld = false,
	held = rejoined.Held, plants = rejoined.Plants }),
	"a rejoiner holding their pod is owed no second one")

--==============================================================================
-- 7. STREAMING LOSS DOES NOT TRIGGER A REPLACEMENT
--
-- Streaming is a CLIENT fact. The service's `inWorld` is answered by a server
-- tag sweep, so the check that proves this is: a tagged pod in Workspace is
-- found no matter what any client can see. The fixture below does that against
-- real Instances. What is asserted HERE is the shape of the mistake -- that
-- "the client cannot see it" is never an input to the rule at all.
--==============================================================================
local fields = 0
for key in pairs(NOTHING :: any) do
	check(key == "carrying" or key == "inWorld" or key == "held" or key == "plants",
		"the possession rule takes only server-side facts, not " .. tostring(key))
	fields += 1
end
check(fields == 4, "four facts, and none of them is what a client can see")

--==============================================================================
-- 8. GENUINE LOSS PERMITS RECOVERY, WITHOUT REWARD FARMING
--
-- A guardian confiscation, or a loose pod expiring while they run back, empties
-- every state -- and THEN a replacement is owed. The cap is what stops that from
-- being a faucet, because EconomyService.SellHeld will sell a banked pod.
--==============================================================================
local lost = beginner()
local sold = 0
for _ = 1, 20 do
	if Data.PodEligible(lost.Tutorial) and not Data.HasOutstandingPod(NOTHING) then
		lost.Tutorial.PodGrants += 1
		sold += 1 -- they bank it and sell it, emptying every state again
	end
end
check(sold == Data.MaxPodGrants, "the sell loop stops at the cap")
check(Data.MaxPodGrants == 3, "the cap is three")
check(not Data.PodEligible(lost.Tutorial), "past the cap, nothing more is owed")
--==============================================================================
-- AND THE CAP IS NOT A WALL. The public nest restocks every dawn, which is the
-- route out; this only asserts that the FREE route is bounded.
--==============================================================================
check(Config.WorldCycle.NightSeconds > 0, "there is a night for the nest to restock after")

--==============================================================================
-- 9. NIGHT AND DAWN PRESERVE OWNED ITEMS AND NORMAL PUBLIC RESTOCKING
--
-- The service's night branch clears only the pod it is holding a handle to. It
-- never reads Held or Plants, so nothing banked or planted can be reached by it
-- -- which is asserted here by running the possession rule across the phase
-- change and requiring it to be unmoved.
--==============================================================================
local overnight: Data.Possessions = { carrying = false, inWorld = true,
	held = { { Id = "nubkin", Tier = 1, Hatched = false } },
	plants = { { SpeciesId = "nubkin", Tier = 1, Stage = 1 } } }
check(Data.HasOutstandingPod(overnight), "they own things at dusk")
overnight.inWorld = false -- night takes the unclaimed one back
check(Data.HasOutstandingPod(overnight), "and still own them at dawn")

local emptyHanded: Data.Possessions = { carrying = false, inWorld = true, held = {}, plants = {} }
check(Data.HasOutstandingPod(emptyHanded), "an unclaimed pod stands during the day")
emptyHanded.inWorld = false
check(not Data.HasOutstandingPod(emptyHanded), "cleared at dusk, a fresh one is owed at dawn")

--==============================================================================
-- 10. COMPLETION AND SKIP/RESUME CANNOT RENEW ENTITLEMENT
--
-- Skip is a VIEW setting. It hides the guide and surrenders nothing, because a
-- player who skips, walks into an empty nest and presses Resume must not have
-- been disinherited in between -- and equally must not have been re-entitled.
--==============================================================================
local skipper = beginner()
skipper.Tutorial.PodGrants = 2
local before = Data.PodEligible(skipper.Tutorial)
Data.SetSkipped(skipper.Tutorial, true)
check(Data.PodEligible(skipper.Tutorial) == before, "skipping changes nothing")
Data.SetSkipped(skipper.Tutorial, false)
check(Data.PodEligible(skipper.Tutorial) == before, "resuming changes nothing")
check(skipper.Tutorial.PodGrants == 2, "and neither resets the counter")

local done = beginner()
done.Tutorial.Done.hatch = true
done.Tutorial.PodGrants = 0
check(not Data.PodEligible(done.Tutorial),
	"a completed hatch ends entitlement even with grants unspent")
Data.SetSkipped(done.Tutorial, false)
check(not Data.PodEligible(done.Tutorial), "and Resume does not reopen it")

--==============================================================================
-- 11. ORDINARY PODS AND EXISTING SAVES ARE UNAFFECTED
--
-- The migration is the whole risk here: a new field on a record every existing
-- player already has.
--==============================================================================
local legacy = Schema.Default() :: any
legacy.Tutorial = { Version = 1, Done = { steal = true, bank = true }, Skipped = false }
legacy.Cash = 999999
legacy.Speed = 250000
local migrated = Schema.Sanitise(legacy)
check(migrated.Tutorial.PodGrants == 0, "a save with no counter reads as zero")
check(migrated.Cash == 999999 and migrated.Speed == 250000, "and keeps everything else")

local completed = Schema.Default() :: any
completed.Tutorial = { Version = 1,
	Done = { steal = true, bank = true, place = true, hatch = true }, Skipped = false }
local completedOut = Schema.Sanitise(completed)
check(not Data.PodEligible(completedOut.Tutorial), "a finished existing player gets no reservation")

--== A COUNT OFF A CORRUPTED SAVE IS A CLAIM ==--
for _, bad in { "3", -5, 0 / 0, math.huge, 99, {}, true } do
	local junk = Schema.Default() :: any
	junk.Tutorial = { Version = 2, Done = {}, Skipped = false, PodGrants = bad }
	local out = Schema.Sanitise(junk)
	check(type(out.Tutorial.PodGrants) == "number"
		and out.Tutorial.PodGrants == out.Tutorial.PodGrants
		and out.Tutorial.PodGrants >= 0
		and out.Tutorial.PodGrants <= Data.MaxPodGrants,
		"PodGrants is clamped for " .. tostring(bad))
end
-- "3" is a number to tonumber and IS honoured, which is deliberate: the risk is
-- an out-of-range value, not a stringified one.
local stringy = Schema.Default() :: any
stringy.Tutorial = { Version = 2, Done = {}, Skipped = false, PodGrants = "3" }
check(Schema.Sanitise(stringy).Tutorial.PodGrants == 3, "a numeric string is read as its number")

--==============================================================================
-- FIXTURE: THE WORLD-SIDE LOOKUP, AGAINST REAL INSTANCES
--
-- Throwaway Models in a throwaway folder, tagged exactly as CarryService tags a
-- loose pod. This is the half that cannot be reasoned about -- CollectionService
-- and IsDescendantOf either behave or they do not.
--==============================================================================
local ME, STRANGER = 111111, 222222

local stage = Instance.new("Folder")
stage.Name = "TutorialPodSpecFixture"
stage.Parent = workspace

local function fixturePod(name: string, owner: number?, planted: boolean?): Model
	local model = Instance.new("Model")
	model.Name = name
	local part = Instance.new("Part")
	part.Anchored = true
	part.Size = Vector3.one
	part.Parent = model
	model.PrimaryPart = part
	model.Parent = stage
	CollectionService:AddTag(model, Config.Tags.SeedPod)
	if planted then
		CollectionService:AddTag(model, Config.Tags.Planted)
	end
	if owner then
		model:SetAttribute("ReservedFor", owner)
	end
	return model
end

local ok, err = pcall(function()
	check(PodService.WorldPodFor(ME) == nil, "an empty world holds no reservation")

	local ordinary = fixturePod("Ordinary", nil)
	check(PodService.WorldPodFor(ME) == nil, "an ordinary pod is nobody's reservation")

	local theirs = fixturePod("Theirs", STRANGER)
	check(PodService.WorldPodFor(ME) == nil, "a stranger's reservation is not mine")
	check(PodService.WorldPodFor(STRANGER) == theirs, "it is theirs")

	local mine = fixturePod("Mine", ME)
	check(PodService.WorldPodFor(ME) == mine, "mine is found")
	check(PodService.WorldPodFor(STRANGER) == theirs, "and does not displace theirs")

	--== PLANTED IS NOT A POD IN THE WORLD ==--
	-- A hatching pod in somebody's soil is property, not supply. If the sweep
	-- counted it the owner would be told they still have a pod standing at the
	-- nest, and if it did not exclude it by TAG it would count the same row
	-- twice -- once here and once through Plants.
	local sown = fixturePod("Sown", ME, true)
	check(PodService.WorldPodFor(ME) == mine, "a planted pod is skipped by the world sweep")
	sown:Destroy()

	--== DESTROYED MEANS DESTROYED, AND ONLY THEN ==--
	mine:Destroy()
	check(PodService.WorldPodFor(ME) == nil, "a destroyed reservation is gone")

	--== PARENTED OUT OF WORKSPACE IS GONE TOO ==--
	-- This is the shape of a streaming mistake, inverted: the model still exists
	-- and is still tagged, but it is not in the world. The sweep must agree with
	-- the world, not with the tag.
	local stashed = fixturePod("Stashed", ME)
	check(PodService.WorldPodFor(ME) == stashed, "in the world, found")
	stashed.Parent = game:GetService("ServerStorage")
	check(PodService.WorldPodFor(ME) == nil, "out of the world, not found")
	stashed:Destroy()

	ordinary:Destroy()
	theirs:Destroy()
end)

stage:Destroy()
assert(ok, "fixture: " .. tostring(err))

--==============================================================================
-- THE SPOT IT STANDS IN
--
-- Reproduces the service's own arithmetic -- there is no way to call it without
-- a built map -- and checks the two things the numbers have to guarantee: clear
-- of the public ring at every angle, and inside the corridor walls.
--==============================================================================
local RESERVE_RADIUS, SPREAD_DEGREES, NEST_RADIUS = 24, 26, 16
check(RESERVE_RADIUS > NEST_RADIUS, "reservations stand outside the public ring")
--==============================================================================
-- CASE 2, WORLD HALF. The service hands each player the LOWEST slot index
-- nobody else holds, so two beginners never share one. What that guarantee is
-- worth is whether two different indices are actually two different places --
-- which is the pairwise separation asserted in the loop below.
--==============================================================================

local nestX = Config.Map.CorridorWidth * 0.5 - Config.Map.PodInset - 6
local halfCorridor = Config.Map.CorridorWidth * 0.5
local minGap, worstX = math.huge, 0
for slot = 0, 13 do
	local angle = math.rad(SPREAD_DEGREES * slot)
	local dx, dz = math.sin(angle) * RESERVE_RADIUS, math.cos(angle) * RESERVE_RADIUS
	-- Distance to the nearest of the five public pods, which sit on a ring of
	-- NEST_RADIUS at any rotation. The closest a point at RESERVE_RADIUS can
	-- ever be to that ring is the difference of the radii.
	local reach = math.sqrt(dx * dx + dz * dz)
	minGap = math.min(minGap, reach - NEST_RADIUS)
	worstX = math.max(worstX, math.abs(-nestX + dx))

	for other = 0, 13 do
		if other ~= slot then
			local oa = math.rad(SPREAD_DEGREES * other)
			local sep = (Vector3.new(dx, 0, dz)
				- Vector3.new(math.sin(oa) * RESERVE_RADIUS, 0, math.cos(oa) * RESERVE_RADIUS)).Magnitude
			check(sep > 4, string.format("slots %d and %d are %.1f studs apart", slot, other, sep))
		end
	end
end
check(minGap >= 8 - 1e-6, string.format("clear of the public ring by %.2f studs", minGap))
check(worstX < halfCorridor - 6,
	string.format("inside the corridor wall, worst case X %.1f of %.1f", worstX, halfCorridor))

--==============================================================================
-- IT IS ADDITIONAL SUPPLY, NOT A PUBLIC SLOT
--
-- The claim that public scarcity is untouched rests on the reserved pod having
-- no NestId, which is what keeps CarryService.TryTake off the slot-based path.
-- Read straight out of the service's source, because the alternative is
-- believing a comment.
--==============================================================================
--== READ THE CODE, NOT THE COMMENTS THAT EXPLAIN IT ==--
-- The header says all three of these things in prose, so a naive search would
-- match its own explanation and pass for the wrong reason.
local source = game.ServerScriptService.SeedGameServer.TutorialPodService.Source
local code = {}
for line in string.gmatch(source .. "\n", "([^\n]*)\n") do
	if not string.match(line, "^%s*%-%-") then
		table.insert(code, line)
	end
end
local body = table.concat(code, "\n")
check(#body > 0 and #body < #source, "the comment stripper found both code and comments")
check(not string.find(body, "NestId"), "the service never sets a NestId")
check(not string.find(body, "PodsPerNest"), "and never touches the public pod count")
check(not string.find(body, "StockAll") and not string.find(body, "ClearForNight"),
	"and never reaches into the dusk clear or the dawn restock")
check(not string.find(body, "LocalPlayer") and not string.find(body, "Stream"),
	"and never asks what a client can see")

local greenhollow
for _, biome in require(Shared.BiomeData).Biomes do
	if biome.Id == "greenhollow" then greenhollow = biome end
end
check(greenhollow ~= nil, "greenhollow exists")
check(greenhollow.PodsPerNest == 5, "the public nest still holds five")

return string.format("TutorialPodSpec: %d checks passed", pass)
