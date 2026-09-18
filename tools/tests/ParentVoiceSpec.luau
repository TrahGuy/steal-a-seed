--!nocheck
--==============================================================================
-- Steal a Seed :: ParentVoiceSpec
--
-- The eight cues the owner added on 2026-09-17 are the first sounds in this game
-- that belong to ONE CREATURE, and this is the spec that keeps them attached to
-- the right one. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("ParentVoiceSpec"))
--
-- WHAT IT ACTUALLY CHECKS. Three things, in order of how badly they would hurt:
--
--   1. THE WINDOWS. Every one of these rows is a raw render with a usable hit
--      somewhere inside it and air -- or a second take -- after. start and clip
--      are measured numbers, and a clip past the end of the asset is a cue that
--      plays a silence nobody can hear the end of. The durations below came off
--      the WAVs in sfx/ AND off the uploaded assets' own TimeLength, which
--      agreed to the hundredth on all eight.
--
--   2. THE FALL-THROUGH. Three recordings cover two creatures, and the other
--      three biomes have to keep the generic voice rather than going quiet. That
--      is SoundKit.parentCue's whole job and it is asserted per biome, per role.
--
--   3. THAT EVERY NAME ANYBODY PLAYS EXISTS. A cue with a blank id is silent on
--      purpose; a cue NAME THAT IS NOT IN THE TABLE is a typo that nothing
--      reports, because SoundKit.report only walks rows that exist. UIClick was
--      exactly that for four call sites, and the last section of this spec is
--      the check that would have caught it the day it was written.
--
-- Not here: whether they SOUND right (that is the owner's ears), and whether the
-- roar fires at the right moment in a live raid (Play, and NestService owns it).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SoundKit = require(Shared:WaitForChild("SoundKit"))

local pass, fails = 0, {}
local out = {}

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		table.insert(fails, label)
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

local CUES = GameConfig.Sfx.Cues
local VOICES = GameConfig.Sfx.ParentVoices

--==============================================================================
-- 1. THE EIGHT ROWS, AND THE ASSET EACH ONE NAMES
--
-- The id is written down here as well as in GameConfig so that re-pointing a
-- creature's voice at a different upload has to be a deliberate change in two
-- places. Duration is the measured length of both the WAV and the asset.
--==============================================================================
say("-- the eight rows --")

local ROWS = {
	{ "ParentHit", "135685020427303", 3.00, "Attack Claw Swipe & Jaw Snap.wav" },
	{ "ParentHitGreenhollow", "76475963669343", 2.00, "attack hit biome 1.wav" },
	{ "ParentHitTanglemire", "89258109602305", 2.00, "attack hit miremaw.wav" },
	{ "ParentWakeGreenhollow", "124160507544069", 2.00, "biome 1 aggro trigger.wav" },
	{ "ParentWakeDustbowl", "132556773572810", 2.00, "brambleback aggro wake up.wav" },
	{ "ParentWakeTanglemire", "102762735296089", 2.00, "miremaw aggro trigger.wav" },
	{ "ParentStepDustbowl", "126905642164896", 1.00, "brambleback heavy stomp chasegait.wav" },
	{ "ParentSleepDustbowl", "89288684316602", 1.00, "brambleback sleeping.wav" },
}

local seenId = {}
for _, row in ipairs(ROWS) do
	local name, id, seconds = row[1], row[2], row[3]
	local cue = CUES[name]
	check(cue ~= nil, name .. " has a row of its own")
	if cue then
		check(cue.id == "rbxassetid://" .. id,
			name .. " names the asset it was measured from", cue.id)
		check(SoundKit.cue(name) ~= nil,
			name .. " resolves -- an id this shape is one SoundKit will play")
		check(cue.group == "World",
			name .. " is on the World bus, because a monster has a place", cue.group)

		--======================================================================
		-- A WINDOW THAT RUNS OFF THE END OF THE ASSET
		--
		-- SoundKit schedules the Stop by wall clock, so a clip longer than what
		-- is left plays silence and then stops nothing. Not an error anywhere --
		-- which is why it is an assertion here.
		--======================================================================
		local start = cue.start or 0
		local clip = cue.clip
		check(start >= 0 and start < seconds,
			name .. " starts inside its own asset", start)
		if clip then
			check(start + clip <= seconds + 0.001,
				string.format("%s's window ends inside the asset (%.2f + %.2f <= %.2f)",
					name, start, clip, seconds))
			check(clip > 0.3, name .. " keeps enough of the take to be a sound", clip)
		end
		check(type(cue.volume) == "number" and cue.volume > 0 and cue.volume <= 2,
			name .. " has a sane level", cue.volume)
		check(type(cue.range) == "number" and cue.range >= 60 and cue.range <= 200,
			name .. " carries a sensible distance", cue.range)

		check(seenId[cue.id] == nil, name .. " is not a duplicate of another row",
			seenId[cue.id])
		seenId[cue.id] = name
	end
end

--==============================================================================
-- 2. THE TWO THAT ARE NOT ONE-SHOTS
--
-- Which of these is a loop is a FACT ABOUT THE RECORDING and nothing else: the
-- stomp is 0.44s of one foot landing, so looping it would be a machine; the
-- breath is a second long with the gap between breaths built into it, so
-- clipping it would be a pant.
--==============================================================================
say("\n-- the loop and the footfall --")

local step = CUES.ParentStepDustbowl
local sleep = CUES.ParentSleepDustbowl
check(step ~= nil and step.looped == false,
	"the Brambleback's stomp is a single step, not a gait",
	step and tostring(step.looped))
check(step ~= nil and step.clip ~= nil and step.clip <= 0.6,
	"and it is clipped to the stomp", step and step.clip)
check(sleep ~= nil and sleep.looped == true,
	"the Brambleback's breathing loops", sleep and tostring(sleep.looped))
check(sleep ~= nil and sleep.clip == nil,
	"and is NOT clipped -- the silence after the breath is the next breath",
	sleep and sleep.clip)
check(sleep ~= nil and CUES.ParentSleep ~= nil
		and math.abs((sleep.range or 0) - (CUES.ParentSleep.range or 0)) < 0.001,
	"it breathes at the same range the generic sleep does")

--==============================================================================
-- 3. WHO HEARS WHAT, AND WHO FALLS THROUGH
--
-- The point of the table: three recordings for two creatures, five biomes, and
-- nothing silent that was not silent before.
--==============================================================================
say("\n-- the fall-through --")

local EXPECTED = {
	-- biome, role, cue name or false for "nothing"
	{ "greenhollow", "Wake", "ParentWakeGreenhollow" },
	{ "greenhollow", "Hit", "ParentHitGreenhollow" },
	{ "greenhollow", "Sleep", "ParentSleep" },
	{ "greenhollow", "Step", "ChaseStep" },

	{ "dustbowl", "Wake", "ParentWakeDustbowl" },
	{ "dustbowl", "Sleep", "ParentSleepDustbowl" },
	{ "dustbowl", "Step", "ParentStepDustbowl" },
	-- The Brambleback has no hit of its own: it swings the generic claw.
	{ "dustbowl", "Hit", "ParentHit" },

	{ "tanglemire", "Wake", "ParentWakeTanglemire" },
	{ "tanglemire", "Hit", "ParentHitTanglemire" },
	{ "tanglemire", "Sleep", "ParentSleep" },
	{ "tanglemire", "Step", "ChaseStep" },

	-- These two had no recording of their own for a few hours on 2026-09-17 and
	-- kept every generic sound; the owner then recorded both roars. They still
	-- breathe the generic breath, walk the generic step and swing the generic
	-- claw -- only the wake is theirs, which is the whole point of the table.
	{ "emberroot", "Sleep", "ParentSleep" },
	{ "emberroot", "Step", "ChaseStep" },
	{ "emberroot", "Hit", "ParentHit" },
	{ "emberroot", "Wake", "ParentWakeEmberroot" },
	{ "starbloom", "Sleep", "ParentSleep" },
	{ "starbloom", "Wake", "ParentWakeStarbloom" },

	-- A biome that does not exist, and a parent whose attribute never arrived.
	{ "not_a_biome", "Hit", "ParentHit" },
	{ "not_a_biome", "Wake", false },
	{ nil, "Sleep", "ParentSleep" },
	{ nil, "Wake", false },
}

for _, row in ipairs(EXPECTED) do
	local biome, role, want = row[1], row[2], row[3]
	local got = SoundKit.parentCue(biome, role)
	local label = string.format("%s / %s -> %s", biome or "(no biome)", role,
		if want == false then "nothing" else want)
	if want == false then
		check(got == nil, label, got)
	else
		check(got == want, label, got)
	end
end

--==============================================================================
-- 4. THE TABLE ITSELF POINTS AT ROWS THAT EXIST
--
-- A name in ParentVoices that is not in Cues is silence with no symptom, which
-- is the exact failure this whole section exists to make loud.
--==============================================================================
say("\n-- every name in the table is a row --")

local ROLES = { Sleep = true, Step = true, Wake = true, Hit = true }
local bad = {}
local rows = 0
for biome, voice in pairs(VOICES) do
	for role, name in pairs(voice) do
		rows += 1
		if not ROLES[role] then
			table.insert(bad, string.format("%s has role %q, which nothing reads", biome, role))
		end
		if SoundKit.cue(name) == nil then
			table.insert(bad, string.format("%s.%s -> %s, which is not a playable row",
				biome, role, name))
		end
	end
end
check(#bad == 0, string.format("all %d entries name a playable cue", rows),
	table.concat(bad, "; "))
check(VOICES.Default ~= nil and VOICES.Default.Wake == nil,
	"there is no default roar -- a creature nobody has recorded stays quiet")

--==============================================================================
-- AND SINCE THE EVENING OF 2026-09-17, ALL FIVE ROAR
--
-- Kept as its own assertion rather than folded into the table above: "every
-- guardian in the game answers being robbed" is a claim about the GAME, and a
-- sixth biome arriving without a roar should fail this line and make somebody
-- decide, rather than quietly shipping one silent creature.
--==============================================================================
local BIOMES = { "greenhollow", "dustbowl", "tanglemire", "emberroot", "starbloom" }
local mute = {}
for _, biome in ipairs(BIOMES) do
	if SoundKit.parentCue(biome, "Wake") == nil then
		table.insert(mute, biome)
	end
end
check(#mute == 0, "all five guardians have a roar of their own",
	table.concat(mute, ", "))

--==============================================================================
-- 5. NOBODY PLAYS A CUE THAT DOES NOT EXIST
--
-- Walks every script in the game for SoundKit.play/emit/attach/cue with a
-- literal name and checks the table has it. This is the check that was missing:
-- "UIClick" was asked for in four places for weeks and no row was ever added, so
-- four button presses were silent and nothing anywhere said so.
--==============================================================================
say("\n-- every name anybody plays is a row --")

local ROOTS = {
	ReplicatedStorage:FindFirstChild("SeedGame"),
	ServerScriptService:FindFirstChild("SeedGameServer"),
	StarterPlayer:FindFirstChild("StarterPlayerScripts"),
}

local missing, callSites, scanned = {}, 0, 0
for _, root in ipairs(ROOTS) do
	if root then
		for _, inst in ipairs(root:GetDescendants()) do
			if inst:IsA("LuaSourceContainer") then
				local ok, src = pcall(function()
					return (inst :: any).Source
				end)
				if ok and type(src) == "string" then
					scanned += 1
					for verb, name in string.gmatch(src,
						"SoundKit%.(%a+)%(%s*\"([%w_]+)\"") do
						if verb == "play" or verb == "emit" or verb == "attach"
							or verb == "cue" or verb == "stop" or verb == "has" then
							callSites += 1
							if CUES[name] == nil then
								table.insert(missing, string.format("%s: %s(%q)",
									inst.Name, verb, name))
							end
						end
					end
				end
			end
		end
	end
end

check(scanned > 40, string.format("scanned %d scripts", scanned))
check(#missing == 0,
	string.format("all %d literal cue names across the game are rows in the table",
		callSites),
	table.concat(missing, ", "))

check(CUES.UIClick ~= nil and CUES.CardClick ~= nil
		and CUES.UIClick.id == CUES.CardClick.id,
	"UIClick is wired, as a pointer at the card click rather than a silence")
check(CUES.UIClick ~= nil and CUES.CardClick ~= nil
		and CUES.UIClick.start == CUES.CardClick.start
		and CUES.UIClick.clip == CUES.CardClick.clip,
	"and it carries the same window, because it is the same asset")

--==============================================================================
-- 6. THE CALL SITES ASK THE TABLE, RATHER THAN NAMING A ROW
--
-- Source-level, because the moments themselves need a live raid: a parent
-- waking, and a parent's swing landing. What CAN be checked from here is that
-- neither one has a creature's cue name written into it.
--==============================================================================
say("\n-- the call sites --")

local function sourceOf(instance)
	if not instance then
		return nil
	end
	local ok, src = pcall(function()
		return (instance :: any).Source
	end)
	return if ok then src else nil
end

local server = ServerScriptService:FindFirstChild("SeedGameServer")
local nest = sourceOf(server and server:FindFirstChild("NestService"))
check(nest ~= nil and nest:find('SoundKit.parentCue(nest.biome.Id, "Wake")', 1, true) ~= nil,
	"NestService roars with the biome's own cue when a nest is robbed")
check(nest ~= nil and nest:find('SoundKit.parentCue(nest.biome.Id, "Hit") or "Grab"', 1, true) ~= nil,
	"and swings with the biome's own cue, falling back to Grab")

local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
local cues = sourceOf(scripts and scripts:FindFirstChild("SoundCues"))
check(cues ~= nil and cues:find('SoundKit.parentCue(biomeId, "Sleep")', 1, true) ~= nil
		and cues:find('SoundKit.parentCue(biomeId, "Step")', 1, true) ~= nil,
	"SoundCues dresses a parent from its biome")
check(cues ~= nil and cues:find('SoundKit.attach("ParentSleep"', 1, true) == nil
		and cues:find('SoundKit.emit("ChaseStep"', 1, true) == nil,
	"and no longer names either generic row directly")

--==============================================================================
-- AND IT KEEPS WATCHING, BECAUSE THIS PLACE STREAMS
--
-- Found in Play on 2026-09-17: Starbloom's parent was a tagged Model with NO
-- PARTS on the client, because it was outside the streaming radius at join. The
-- old ten-second WaitForChild had long since given up on it, so that creature
-- would have been silent for that player for the whole session no matter how
-- close they walked. A cue nobody can hear is not wired.
--==============================================================================
check(cues ~= nil and cues:find("ChildAdded:Connect", 1, true) ~= nil,
	"a parent's body arriving is watched for, not waited on")
check(cues ~= nil and cues:find('WaitForChild("HumanoidRootPart", 10)', 1, true) == nil,
	"and the ten-second deadline that gave up on it is gone")
check(cues ~= nil and cues:find("local watching", 1, true) ~= nil
		and cues:find("local pending", 1, true) == nil,
	"one live connection per tagged parent, in place of the waiting flag")

if #fails > 0 then
	return ("ParentVoiceSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails,
		table.concat(fails, "\n  "))
end
return ("ParentVoiceSpec: %d passed, 0 failed"):format(pass)
