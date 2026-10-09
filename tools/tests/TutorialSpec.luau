--!strict
--==============================================================================
-- Fresh-source progression, MIGRATION, the readiness race, and isolated request
-- validation. Pure state and arithmetic only -- no live profiles, no remotes, no
-- Play session. The visual guide itself is not testable here and is verified in
-- Play; this file guards the parts that decide what a saved record MEANS.
--==============================================================================
local Shared = game.ReplicatedStorage.SeedGame.Shared
local Data = require(Shared.TutorialData)
local Config = require(Shared.GameConfig)
local BiomeData = require(Shared.BiomeData)
local Schema = require(game.ServerScriptService.SeedGameServer.ProfileSchema)

local pass = 0
local function check(ok: boolean, label: string)
	assert(ok, label)
	pass += 1
end

local STEPS = #Data.Steps
local DONE = STEPS + 1

--==============================================================================
-- THE SHAPE OF THE GUIDE
--==============================================================================
check(STEPS == 7, "seven steps")
check(Data.Steps[1].Id == "train" and Data.Steps[2].Id == "speed", "training comes first")
check(Data.Steps[3].Id == "steal" and Data.Steps[4].Id == "bank" and Data.Steps[5].Id == "hatch"
		and Data.Steps[6].Id == "place" and Data.Steps[STEPS].Id == "travel",
	"steal, bank, then the hatch (step 5) and the place (step 6) -- pods hatch in the Bag (2026-10-09) -- and the "
		.. "guide ends with the travel lesson (2026-10-08)")
check(string.find(Data.Steps[5].Detail, "Bag", 1, true) ~= nil and string.find(Data.Steps[5].Detail, "HATCH", 1, true) ~= nil
		and Data.Steps[6].Title == "Place your plant!",
	"the hatch step says to hold HATCH in the Bag; the place step places a plant")
check(Data.Steps[STEPS].Title == "Get around fast!", "titled Get around fast!")
check(Data.SpeedTarget == 400 and Data.SpeedTargetText == "400",
	"readiness target is 400 (FIRST MINUTE, 2026-10-08; it was 1,000)")
check(Data.Steps[2].Title == "Reach 400 speed!" and string.find(Data.Steps[2].Detail, "hit 400", 1, true) ~= nil,
	"the speed step's title and words say 400")
check(Data.Version == 3, "schema version 3")

local p = Schema.Default()
check(Data.Current(p.Tutorial) == 1, "a new player starts at the treadmill")
check(not p.Tutorial.Skipped, "a new player is shown the guide")
for i, step in Data.Steps do
	check(Data.Record(p.Tutorial, step.Id), "server event advances " .. step.Id)
	check(not Data.Record(p.Tutorial, step.Id), "repeat is idempotent " .. step.Id)
	local index, count = Data.Current(p.Tutorial)
	check(index == i + 1 and count == i, "ordered progress " .. step.Id)
	local restored = Schema.Sanitise(p)
	-- A Version 3 record is never credited the travel step at load (the owner's
	-- call, 2026-10-08): a rejoin after the hatch comes back to step 7.
	check(Data.Current(restored.Tutorial) == i + 1, "rejoin after " .. step.Id)
end
check(Data.Current(p.Tutorial) == DONE, "seven steps finish")
check(p.Cash == 0 and p.Speed == 0 and #p.Plants == 0, "the guide creates no rewards or plants")

--==============================================================================
-- WHAT IS NO LONGER A STEP
--
-- The gameplay hooks for these still fire on success. They must be harmless.
--==============================================================================
local other = Schema.Default()
for _, retired in { "plant", "earn", "buy" } do
	check(not Data.Record(other.Tutorial, retired), retired .. " is no longer a milestone")
end
check(not Data.Record(other.Tutorial, "complete"), "unknown milestone refused")
check(not Data.Record(other.Tutorial, "999"), "forged step refused")
check(Data.Current(other.Tutorial) == 1, "retired milestones advance nothing")

--==============================================================================
-- MIGRATION -- NOBODY IS SENT BACKWARDS, AND NOBODY REPEATS A GUIDE THEY FINISHED
--==============================================================================
local function v1(done: { [string]: boolean }, extra: any?): any
	local profile = Schema.Default() :: any
	profile.Tutorial = { Version = 1, Done = done, Skipped = false }
	if extra then
		for key, value in pairs(extra) do
			profile[key] = value
		end
	end
	return Schema.Sanitise(profile)
end

local finished = v1({ steal = true, bank = true, place = true, hatch = true,
	plant = true, earn = true, buy = true })
check(Data.Current(finished.Tutorial) == DONE, "a finished v1 player is finished, not restarted")

local hatchedOnly = v1({ steal = true, bank = true, place = true, hatch = true })
check(Data.Current(hatchedOnly.Tutorial) == DONE, "reaching the old hatch completes the new guide")

local boughtBat = v1({ buy = true })
check(Data.Current(boughtBat.Tutorial) == DONE, "past the old hatch by any milestone completes it")

local halfway = v1({ steal = true, bank = true })
check(halfway.Tutorial.Done.steal and halfway.Tutorial.Done.bank, "partial progress is kept")
check(halfway.Tutorial.Done.train and halfway.Tutorial.Done.speed,
	"a player who already stole is not sent back to the treadmill")
check(Data.Current(halfway.Tutorial) == 5, "and resumes at the next real step")

check(Data.Current(Schema.Sanitise(nil).Tutorial) == 1, "a missing save gets the whole guide")
check(Schema.Sanitise(nil).Tutorial.Version == 3, "and is stamped version 3")

--==============================================================================
-- SPEED IS EVIDENCE, BECAUSE THE TREADMILL IS THE ONLY FAUCET
--==============================================================================
local untrained = v1({}, { Speed = 0 })
check(Data.Current(untrained.Tutorial) == 1, "no speed means start at the treadmill")
-- Half the target (it was 500 against 1,000; 400 since 2026-10-08).
local training = v1({}, { Speed = math.floor(Data.SpeedTarget / 2) })
check(training.Tutorial.Done.train and not training.Tutorial.Done.speed,
	"any speed proves training but not readiness")
check(Data.Current(training.Tutorial) == 2, "and the next step is the target")
local ready = v1({}, { Speed = Data.SpeedTarget })
check(ready.Tutorial.Done.speed and Data.Current(ready.Tutorial) == 3,
	"meeting the target skips both speed steps")
local rich = v1({}, { Speed = Data.SpeedTarget * 1000 })
check(Data.Current(rich.Tutorial) == 3, "an established player is not made to train again")

--==============================================================================
-- POSSESSIONS STILL PROVE STEPS
--==============================================================================
local carrying = v1({}, { Held = { { Id = "nubkin", Tier = 1, Hatched = false } } })
check(Data.Current(carrying.Tutorial) == 5, "a banked pod starts at the hatch (step 5 since 2026-10-09)")
check(#carrying.Held == 1, "and the pod is still there")
local hatchling = v1({}, { Held = { { Id = "nubkin", Tier = 1, Hatched = true } } })
check(Data.Current(hatchling.Tutorial) == DONE, "a hatchling means the guide is done")
local planted = v1({}, { Plants = { { SpeciesId = "nubkin", Tier = 1, Stage = 1, X = 0, Z = 0,
	PlantedAt = os.time() } } })
check(Data.Current(planted.Tutorial) == 5, "a planted pod proves the bank, and starts at the hatch")
local grown = v1({}, { Plants = { { SpeciesId = "nubkin", Tier = 1, Stage = 3, X = 0, Z = 0,
	PlantedAt = os.time() } } })
check(Data.Current(grown.Tutorial) == DONE, "a grown garden is past the guide")
local seen = v1({}, { Almanac = { nubkin = true } })
check(Data.Current(seen.Tutorial) == DONE, "an almanac entry only comes from a hatch")

--==============================================================================
-- STEP 7, THE TRAVEL LESSON (owner, 2026-10-08)
--
-- Recorded only after the hatch (on a successful TeleportHome -- the server's
-- path is pinned in TutorialSpotlightSpec), credited at load to every record
-- past the hatch, and it moves neither the first loop's end nor the chest.
--==============================================================================
local early = Schema.Default()
for _, id in { "train", "speed", "steal", "bank", "hatch" } do
	Data.Record(early.Tutorial, id)
end
check(not Data.Record(early.Tutorial, "travel") and early.Tutorial.Done.travel == nil,
	"a teleport home before the first plant is placed records nothing (the hatch alone is not enough)")
check(not Data.FirstLoopDone(early.Tutorial), "at the hatch the first loop is not done yet: its plant is still to place")
check(Data.Record(early.Tutorial, "place"), "placing the first plant records")
check(Data.FirstLoopDone(early.Tutorial) and not Data.IsComplete(early.Tutorial) and Data.Current(early.Tutorial) == 7,
	"with the first plant placed the first loop is done and the guide is not: it stands on step 7")
check(Data.Record(early.Tutorial, "travel") and Data.IsComplete(early.Tutorial)
	and Data.Current(early.Tutorial) == DONE, "a teleport home after that records travel and finishes the guide")
check(not Data.Record(early.Tutorial, "travel"), "travel is recorded once")
check(Data.InFirstLoop("train") and Data.InFirstLoop("hatch") and Data.InFirstLoop("place")
	and not Data.InFirstLoop("travel") and not Data.InFirstLoop("plant"), "the first loop is train through place")

local function v2(done: { [string]: boolean }, extra: any?): any
	local profile = Schema.Default() :: any
	profile.Tutorial = { Version = 2, Done = done, Skipped = false, PodGrants = 1 }
	if extra then
		for key, value in pairs(extra) do
			profile[key] = value
		end
	end
	return Schema.Sanitise(profile)
end
local doneV2 = v2({ train = true, speed = true, steal = true, bank = true, place = true, hatch = true })
check(doneV2.Tutorial.Done.travel == true and Data.IsComplete(doneV2.Tutorial),
	"a complete v2 save stays complete: travel is credited at load")
check(doneV2.Tutorial.Version == 3 and doneV2.Tutorial.PodGrants == 1, "restamped version 3, its pod grants kept")
local midV2 = v2({ train = true, speed = true, steal = true, bank = true, place = true })
check(not midV2.Tutorial.Done.travel and Data.Current(midV2.Tutorial) == 5,
	"a v2 player mid-guide (a pod planted, not hatched) is not credited travel: they stand at the hatch")
local credited = 0
for _, record in { finished, hatchedOnly, boughtBat, hatchling, grown, seen } do
	if record.Tutorial.Done.travel == true and Data.IsComplete(record.Tutorial) then
		credited += 1
	end
end
check(credited == 6, "every past-hatch v1 record, and every possession past the hatch, is credited travel (6 of 6)")
-- Only a record saved BEFORE Version 3 is credited (the owner's call, 2026-10-08).
local v3 = Schema.Default() :: any
v3.Tutorial = { Version = 3, Done = { train = true, speed = true, steal = true, bank = true, place = true,
	hatch = true }, Skipped = false }
local v3Loaded = Schema.Sanitise(v3).Tutorial
check(v3Loaded.Done.travel ~= true and v3Loaded.Done.hatch == true and Data.Current(v3Loaded) == 7,
	"a v3 save with hatch done and travel not done loads with travel NOT done: step 7 is still to come")
local v3Grown = Schema.Default() :: any
v3Grown.Tutorial = { Version = 3, Done = {}, Skipped = false }
v3Grown.Plants = { { SpeciesId = "nubkin", Tier = 1, Stage = 3, X = 0, Z = 0, PlantedAt = os.time() } }
local v3GrownLoaded = Schema.Sanitise(v3Grown).Tutorial
check(v3GrownLoaded.Done.hatch == true and v3GrownLoaded.Done.travel ~= true,
	"and a v3 save proven past the hatch by its garden is not credited travel either")
local v3Done = Schema.Default() :: any
v3Done.Tutorial = { Version = 3, Done = { train = true, speed = true, steal = true, bank = true, place = true,
	hatch = true, travel = true }, Skipped = false }
check(Data.IsComplete(Schema.Sanitise(v3Done).Tutorial), "a v3 save that did travel stays complete")
local v1Hatch = v1({ hatch = true })
check(v1Hatch.Tutorial.Done.travel == true and Data.IsComplete(v1Hatch.Tutorial),
	"a v1 save past the hatch is credited travel")
local unversioned = Schema.Default() :: any
unversioned.Tutorial = nil
unversioned.Almanac = { nubkin = true }
check(Data.IsComplete(Schema.Sanitise(unversioned).Tutorial),
	"a save from before the guide had a record, past the hatch by its Almanac, is credited too")

--==============================================================================
-- THE BONUS CHEST STILL OPENS AT THE HATCH
--
-- The real BonusChestService, loadstring'd with a stand-in profile store and
-- analytics (no live profile, save, attribute or remote is touched): locked
-- before the hatch, open at it -- before the travel step.
--==============================================================================
local chestModule = game.ServerScriptService.SeedGameServer.BonusChestService
local chestChunk, chestErr = loadstring(chestModule.Source)
assert(chestChunk, chestErr)
local chestProfile = Schema.Default() :: any
local fakeData = {
	Get = function()
		return chestProfile
	end,
	IsPersistent = function()
		return true
	end,
	SetChest = function(_: any, nextAt: number, boost: string?, endsAt: number?)
		chestProfile.ChestNextAt, chestProfile.ChestBoost, chestProfile.ChestBoostEndsAt = nextAt, boost, endsAt
		return true
	end,
	Save = function()
		return true
	end,
}
local fakeMetrics = { chestClaimed = function() end }
local chestEnv = {
	script = chestModule,
	print = function() end,
	require = function(target: any): any
		if target.Name == "PlayerDataService" then
			return fakeData
		end
		if target.Name == "Metrics" then
			return fakeMetrics
		end
		return require(target)
	end,
}
setmetatable(chestEnv, { __index = getfenv(1) })
setfenv(chestChunk, chestEnv)
local Chest = chestChunk()
local chestPlayer = {
	Parent = game:GetService("Players"),
	Name = "SpecChest",
	GetAttribute = function()
		return nil
	end,
	SetAttribute = function() end,
} :: any
if Config.BonusChest.Enabled then
	for _, id in { "train", "speed", "steal", "bank", "hatch" } do
		Data.Record(chestProfile.Tutorial, id)
	end
	local _, lockedCode = Chest.Claim(chestPlayer)
	check(lockedCode == "LOCKED", "before the first plant is placed the chest is locked")
	Data.Record(chestProfile.Tutorial, "place")
	local opened, code = Chest.Claim(chestPlayer)
	check(opened == true and code == "OK" and chestProfile.Tutorial.Done.travel == nil,
		"with the first plant placed -- the travel step still to come -- it opens, at the first loop's end as before")
end
local chestSource = chestModule.Source
check(select(2, string.gsub(chestSource, "TutorialData%.FirstLoopDone%(profile%.Tutorial%)", "")) == 2
	and not string.find(chestSource, "IsComplete(", 1, true),
	"BonusChestService reads the first loop in both places, never IsComplete")

local valuables = v1({ steal = true }, { Cash = 12345, Speed = 67890,
	Weapons = { rootwood_bat = true }, EquippedBat = "rootwood_bat" })
check(valuables.Cash == 12345 and valuables.Speed == 67890
	and valuables.EquippedBat == "rootwood_bat" and valuables.Weapons.rootwood_bat == true,
	"migration touches no cash, speed, weapon or loadout")

--==============================================================================
-- MALFORMED RECORDS
--==============================================================================
-- Deliberately NOTHING later than the fields under test: a valid `steal` here
-- would credit train and speed through the no-going-backwards rule and the
-- boolean check would pass for the wrong reason.
local malformed = Schema.Default() :: any
malformed.Tutorial = { Version = math.huge, Skipped = "true",
	Done = { train = "true", speed = 1, evil = true } }
local clean = Schema.Sanitise(malformed)
check(not clean.Tutorial.Skipped, "a string is not true")
check(not clean.Tutorial.Done.train, "a string is not true in Done either")
check(not clean.Tutorial.Done.speed, "a number is not true")
check(clean.Tutorial.Done.evil == nil, "unknown keys are dropped")
check(clean.Tutorial.Version == 3, "version is restamped, never trusted")
check(Data.Current(clean.Tutorial) == 1, "a junk record is just a new player")

local realStep = Schema.Default() :: any
realStep.Tutorial = { Version = 1, Done = { steal = true }, Skipped = false }
local kept = Schema.Sanitise(realStep)
check(kept.Tutorial.Done.steal, "a genuine true is kept")

local skipping = Schema.Default()
Data.Record(skipping.Tutorial, "train")
Data.SetSkipped(skipping.Tutorial, true)
local resumed = Schema.Sanitise(skipping)
check(resumed.Tutorial.Skipped and Data.Current(resumed.Tutorial) == 2, "skip survives a save with progress")
Data.SetSkipped(resumed.Tutorial, false)
check(not resumed.Tutorial.Skipped, "resume restores the guide")
check(not Data.SetSkipped(resumed.Tutorial, false), "a repeat resume is a no-op")

--==============================================================================
-- THE READINESS RACE
--
-- The guide asks a beginner to reach the target (400 since 2026-10-08) and then
-- rob Greenhollow. That is only an honest instruction if the run home can
-- actually be made, so the race is asserted here rather than left to a comment
-- that can rot. Their FIRST raid runs at FirstRaidChaseSpeed (19); every other
-- chase at the numbers below.
--
-- Simulated from the SHIPPED functions and the SHIPPED map geometry at 50Hz --
-- the same rate the guardian's own tick note quotes. It is arithmetic, not a
-- playtest: a real escape also involves corners, jumps and other players.
--==============================================================================
local green
for _, biome in BiomeData.Biomes do
	if biome.Id == "greenhollow" then
		green = biome
	end
end
check(green ~= nil, "greenhollow exists")
check(green.GuardianChaseSpeed == 15, "greenhollow states its own chase speed")
for _, biome in BiomeData.Biomes do
	if biome.Id ~= "greenhollow" then
		check(biome.GuardianChaseSpeed == nil, biome.Id .. " keeps the shared formula")
	end
end
check(green.RecommendedSpeed == 0, "greenhollow still recommends nothing -- no new gate")

local runHome = 0
for _, cf in BiomeData.NestCFrames(green) do
	runHome = math.max(runHome, math.abs(cf.Position.Z + Config.Map.FieldFront))
end
check(runHome > 200, "greenhollow's nest is a real run from safety: " .. math.floor(runHome))

--==============================================================================
-- EVERY CHASE CARRIES AT LEAST ONE RAGE STACK
--
-- NestService's `provoke` does `nest.rage += 1` BEFORE the chase starts, so the
-- speed a first-time thief actually meets is the stated base PLUS
-- RageSpeedPerTake. There is no rage-0 chase in the game.
--
-- This is not a detail. Modelled without it, 26 looks like the old speed and 20
-- like a fix; in the running game those were 31 and 25, and a trained beginner
-- lost the pod to both. Measured live at 25.00 and then at 20.00.
--==============================================================================
local FIRST = green.GuardianChaseSpeed + Config.Parent.RageSpeedPerTake
local SECOND = green.GuardianChaseSpeed + Config.Parent.RageSpeedPerTake * 2
check(FIRST == 20, "a first theft is chased at 20")
check(SECOND == 25, "a second theft before the nest calms is chased at 25")

local function escapes(speedScore: number, guardian: number): boolean
	local carry = Config.carryMultiplierFor(30) -- a light greenhollow pod
	local mine = Config.walkSpeedFor(speedScore) * carry
	local gap = mine * Config.Parent.WakeDelaySeconds
	local travelled = gap
	local dt, t = 1 / 50, 0
	while travelled < runHome and gap > Config.Parent.GrabStuds and t < 200 do
		gap += (mine - guardian) * dt
		travelled += mine * dt
		t += dt
	end
	return travelled >= runHome
end

check(escapes(Data.SpeedTarget, FIRST),
	"a player who reached the target can actually get the pod home")
local FAIR = green.FirstRaidChaseSpeed
check(FAIR == 19 and escapes(Data.SpeedTarget, FAIR),
	"and on their first raid, chased at most at 19, they get it home too")
check(not escapes(0, FAIR),
	"a first raid untrained, at 16 against 19, still loses the pod")
check(not escapes(0, FIRST),
	"turning up untrained still loses the pod -- the lesson survives")
check(not escapes(Data.SpeedTarget, SECOND),
	"going straight back to the same nest still loses it -- rage still bites")
check(not escapes(Data.SpeedTarget, Config.parentWalkSpeedFor(0) + Config.Parent.RageSpeedPerTake),
	"and the shipped formula's 31 was genuinely impossible, which is why this changed")


--==============================================================================
-- THE REQUEST SURFACE, IN AN ISOLATED ENVIRONMENT
--
-- A fake profile owner in a loadstring'd copy of the service. NOT a real Player
-- and NOT a multiplayer test; no live profile, save or remote is touched.
--==============================================================================
local source = game.ServerScriptService.SeedGameServer.TutorialService
local chunk, err = loadstring(source.Source)
assert(chunk, err)
local requestProfile = Schema.Default()
local fakeProfiles = {
	Get = function()
		return requestProfile
	end,
	SetTutorialSkipped = function(_: any, value: boolean)
		return Data.SetSkipped(requestProfile.Tutorial, value)
	end,
}
local environment = { script = source, require = function(target: any): any
	if target.Name == "PlayerDataService" then
		return fakeProfiles
	end
	return require(target)
end }
setmetatable(environment, { __index = getfenv(1) })
setfenv(chunk, environment)
local service = chunk()
local fake = { Parent = game:GetService("Players") } :: any
check(not service.Request(fake, {}), "a non-string command is refused")
check(not service.Request(fake, "train"), "the client cannot claim training")
check(not service.Request(fake, "speed"), "the client cannot claim readiness")
check(not service.Request(fake, "hatch"), "the client cannot claim a hatch")
check(not service.Request(fake, "complete"), "the client cannot finish the guide")
check(service.Request(fake, "skip") and requestProfile.Tutorial.Skipped, "skip only hides")
check(not service.Request(fake, "resume"), "rapid requests are throttled")
service.Init()
check(service.Request(fake, "resume") and not requestProfile.Tutorial.Skipped, "resume restores")
service.Init()
check(service.Request(fake, "snapshot") and Data.Current(requestProfile.Tutorial) == 1,
	"a snapshot advances nothing")
check(not service.Request({ Parent = nil }, "skip"), "a departed owner is refused")

return string.format(
	"TutorialSpec: %d passed, 0 failed. Pure progression/migration (seven steps, Version 3), the readiness race" ..
	"\nas arithmetic, the Bonus Chest at the hatch and an isolated request harness. The visual guide and real" ..
	"\ngameplay require Play.", pass)
