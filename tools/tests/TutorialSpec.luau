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
check(STEPS == 6, "six steps")
check(Data.Steps[1].Id == "train" and Data.Steps[2].Id == "speed", "training comes first")
check(Data.Steps[STEPS].Id == "hatch", "the guide ends at the hatch")
check(Data.SpeedTarget == 1000, "readiness target is 1,000")
check(Data.Version == 2, "schema version 2")

local p = Schema.Default()
check(Data.Current(p.Tutorial) == 1, "a new player starts at the treadmill")
check(not p.Tutorial.Skipped, "a new player is shown the guide")
for i, step in Data.Steps do
	check(Data.Record(p.Tutorial, step.Id), "server event advances " .. step.Id)
	check(not Data.Record(p.Tutorial, step.Id), "repeat is idempotent " .. step.Id)
	local index, count = Data.Current(p.Tutorial)
	check(index == i + 1 and count == i, "ordered progress " .. step.Id)
	local restored = Schema.Sanitise(p)
	check(Data.Current(restored.Tutorial) == i + 1, "rejoin after " .. step.Id)
end
check(Data.Current(p.Tutorial) == DONE, "six steps finish")
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
check(Schema.Sanitise(nil).Tutorial.Version == 2, "and is stamped version 2")

--==============================================================================
-- SPEED IS EVIDENCE, BECAUSE THE TREADMILL IS THE ONLY FAUCET
--==============================================================================
local untrained = v1({}, { Speed = 0 })
check(Data.Current(untrained.Tutorial) == 1, "no speed means start at the treadmill")
local training = v1({}, { Speed = 500 })
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
check(Data.Current(carrying.Tutorial) == 5, "a banked pod starts at placement")
check(#carrying.Held == 1, "and the pod is still there")
local hatchling = v1({}, { Held = { { Id = "nubkin", Tier = 1, Hatched = true } } })
check(Data.Current(hatchling.Tutorial) == DONE, "a hatchling means the guide is done")
local planted = v1({}, { Plants = { { SpeciesId = "nubkin", Tier = 1, Stage = 1, X = 0, Z = 0,
	PlantedAt = os.time() } } })
check(Data.Current(planted.Tutorial) == 6, "a planted pod starts at the hatch")
local grown = v1({}, { Plants = { { SpeciesId = "nubkin", Tier = 1, Stage = 3, X = 0, Z = 0,
	PlantedAt = os.time() } } })
check(Data.Current(grown.Tutorial) == DONE, "a grown garden is past the guide")
local seen = v1({}, { Almanac = { nubkin = true } })
check(Data.Current(seen.Tutorial) == DONE, "an almanac entry only comes from a hatch")

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
check(clean.Tutorial.Version == 2, "version is restamped, never trusted")
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
-- The guide asks a beginner to reach 1,000 and then rob Greenhollow. That is
-- only an honest instruction if the run home can actually be made, so the race
-- is asserted here rather than left to a comment that can rot.
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
	"TutorialSpec: %d passed, 0 failed. Pure progression/migration, the readiness race as arithmetic," ..
	"\nand an isolated request harness. The visual guide and real gameplay require Play.", pass)
