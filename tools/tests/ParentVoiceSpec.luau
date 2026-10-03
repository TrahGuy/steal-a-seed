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

-- Rows that exist with a blank id because their recording is waiting for an
-- upload. A row here plays nothing and replaces nothing until its id is pasted
-- in; this list is the only place a blank row is allowed. Empty since the seven
-- 2026-09-24 recordings were uploaded and wired, 2026-09-27; the Rain event's
-- Stormstrider had two hooks waiting (2026-10-02) -- its wake is recorded now,
-- its hit still waits.
local PENDING = { StormstriderHit = true }

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
	--
	-- 2026-09-27: each also has its own sleep and walk home, and Astralmaw its
	-- rage, uploaded and wired that day -- so the generic breath is no longer
	-- theirs, and Astralmaw's one roar is the rage, not its old wake as well.
	{ "emberroot", "Sleep", "ParentSleepEmberroot" },
	{ "emberroot", "Step", "ChaseStep" },
	{ "emberroot", "Hit", "ParentHit" },
	{ "emberroot", "Wake", "ParentWakeEmberroot" },
	{ "emberroot", "Return", "ParentReturnEmberroot" },
	{ "starbloom", "Sleep", "ParentSleepStarbloom" },
	{ "starbloom", "Wake", "ParentRageStarbloom" },
	{ "starbloom", "Return", "ParentReturnStarbloom" },
	{ "dustbowl", "Return", "ParentReturnDustbowl" },
	{ "tanglemire", "Return", "ParentReturnTanglemire" },
	-- Greenhollow's brute has no walk-home recording: it goes home in silence.
	{ "greenhollow", "Return", false },

	-- The Rain event's Stormstrider (2026-10-02): its own growl and its own
	-- sleeping breath; its hit is still a hook, so a catch keeps the generic claw.
	{ "rain", "Wake", "StormstriderWake" },
	{ "rain", "Sleep", "StormstriderSleep" },
	{ "rain", "Hit", "ParentHit" },
	{ "rain", "Step", "ChaseStep" },
	{ "rain", "Return", false },

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

local ROLES = { Sleep = true, Step = true, Wake = true, Hit = true, Return = true }
local bad = {}
local rows = 0
for biome, voice in pairs(VOICES) do
	for role, entry in pairs(voice) do
		rows += 1
		if not ROLES[role] then
			table.insert(bad, string.format("%s has role %q, which nothing reads", biome, role))
		end
		-- A role is a name or a list of names in order of preference (2026-09-27).
		local names = if type(entry) == "table" then entry else { entry }
		local playable = 0
		for _, name in ipairs(names) do
			if type(name) ~= "string" or CUES[name] == nil then
				table.insert(bad, string.format("%s.%s -> %s, which is not a row", biome, role, tostring(name)))
			elseif SoundKit.cue(name) ~= nil then
				playable += 1
			elseif not PENDING[name] then
				table.insert(bad, string.format("%s.%s -> %s, a blank row nobody is waiting on",
					biome, role, name))
			end
		end
		if type(entry) == "table" and playable == 0 then
			table.insert(bad, string.format("%s.%s lists no playable cue at all", biome, role))
		end
	end
end
check(#bad == 0, string.format("all %d entries name rows; blank ones only where an upload is pending", rows),
	table.concat(bad, "; "))
local stray = {}
for name in pairs(PENDING) do
	if CUES[name] == nil then
		table.insert(stray, name)
	end
end
check(#stray == 0, "every pending recording has its row waiting", table.concat(stray, ", "))
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

--==============================================================================
-- 7. A ONE-SHOT STEP IS A FOOTFALL, ONE AT A TIME (reported 2026-09-26)
--
-- The Brambleback -- Dustbowl, the second guardian, and the only one whose
-- step is a one-shot -- stomped every 2.2 studs, three and a half times per
-- real footfall, and at chase speed that was a fresh overlapping Sound nearly
-- every frame. The spacing now comes from ParentAnim's own stride, a voice
-- waits between stomps, and the stomp still ringing is cut when the next lands
-- or the parent sleeps. Source-level: hearing it takes a live raid.
--==============================================================================
say("\n-- one-shot steps --")
local anim = sourceOf(scripts and scripts:FindFirstChild("ParentAnim"))
local swing = anim and tonumber(anim:match("local SWING_PER_STUD = ([%d%.]+)"))
local perStep = cues and cues:match("local STUDS_PER_STEP = math%.pi / ([%d%.]+)")
check(swing ~= nil and perStep ~= nil and tonumber(perStep) == swing,
	"a step is every pi / SWING_PER_STUD studs -- one footfall of ParentAnim's stride",
	string.format("SWING_PER_STUD %s, step divisor %s", tostring(swing), tostring(perStep)))
check(swing ~= nil and math.pi / swing > 7,
	"which is ~7.85 studs, not the 2.2 that stomped three times a footfall",
	swing and string.format("%.2f", math.pi / swing) or "?")
local minStep = cues and tonumber(cues:match("local MIN_STEP_SECONDS = ([%d%.]+)"))
local stepCue = GameConfig.Sfx.Cues.ParentStepDustbowl
check(minStep ~= nil and minStep >= 0.2 and 1 / minStep <= 5,
	"a voice stomps at most five times a second, however fast the chase", minStep)
check(stepCue ~= nil and stepCue.looped == false,
	"Dustbowl's step is still the one-shot the recording is")
check(cues ~= nil and cues:find("voice.stomp = SoundKit.emit(voice.stepName, voice.root)", 1, true) ~= nil
		and cues:find("hush(voice)\n\t\t\t\t\tvoice.stomp = SoundKit.emit(", 1, true) ~= nil,
	"and the stomp still ringing is cut when the next lands -- never two from one parent")
check(cues ~= nil and cues:find("voice.walked = 0\n\t\t\t\thush(voice)", 1, true) ~= nil
		and cues:find("if voice then\n\t\thush(voice)", 1, true) ~= nil,
	"asleep, streamed out or forgotten, a parent's stomp stops there")
check(cues ~= nil and cues:find("local moved = math.sqrt(dx * dx + dz * dz)", 1, true) ~= nil,
	"ground covered is measured flat, as the stride is")

--==============================================================================
-- 8. THE 2026-09-24 RECORDINGS: SLEEPS, WALKS HOME AND ASTRALMAW'S RAGE
--    (rows 2026-09-27, uploaded and wired the same day)
--
-- The rules are pure (SoundKit.returnCueStep) and the rows are data, so both are
-- checked here; hearing them takes the experience's permission on each upload
-- (see GameConfig) and a live raid.
--==============================================================================
say("\n-- sleeps, walks home and the rage --")
local STEP_TABLE = {
	-- old, new, at, want
	{ nil, "returning", "leave", nil },
	{ "chasing", "returning", "leave", "play" },
	{ "chasing", "hauling", "leave", "play" },
	{ "waking", "returning", "leave", "play" },
	{ "returning", "hauling", "leave", nil },
	{ "hauling", "returning", "leave", nil },
	{ "returning", "chasing", "leave", "fade" },
	{ "hauling", "waking", "leave", "fade" },
	{ "returning", "asleep", "leave", "fade" },
	{ "returning", "asleep", "arrive", "play" },
	{ "hauling", "asleep", "arrive", "play" },
	{ "chasing", "returning", "arrive", nil },
	{ "chasing", "asleep", "leave", "fade" },
	{ "asleep", "waking", "leave", "fade" },
	{ "returning", "returning", "leave", nil },
}
local wrongSteps = {}
for _, row in ipairs(STEP_TABLE) do
	local got = SoundKit.returnCueStep(row[1], row[2], row[3])
	if got ~= row[4] then
		table.insert(wrongSteps, string.format("%s->%s (%s): %s", tostring(row[1]), row[2], row[3], tostring(got)))
	end
end
check(#wrongSteps == 0, "one walk-home cue per trip: played as it turns for home, never again on a "
	.. "walk becoming a haul, cut off by a fresh chase or a lie-down, and never on first sight",
	table.concat(wrongSteps, "; "))
check(GameConfig.Sfx.ReturnCueAt == "leave" or GameConfig.Sfx.ReturnCueAt == "arrive",
	"the moment it plays is one word in the config", GameConfig.Sfx.ReturnCueAt)
check(cues ~= nil and cues:find('returnName = SoundKit.parentCue(biomeId, "Return")', 1, true) ~= nil
		and cues:find("SoundKit.returnCueStep(voice.state, state, RETURN_AT)", 1, true) ~= nil
		and cues:find("if typeof(state) == \"string\" and state ~= voice.state then", 1, true) ~= nil,
	"SoundCues asks for the biome's walk home and decides on a state CHANGE only")
check(cues ~= nil and cues:find("quietBack(voice, 0)\n\t\tif voice.sleep then", 1, true) ~= nil,
	"streamed out or forgotten, a walk-home cue stops with its parent")
check(cues ~= nil and cues:find("voice.sleepFade = fadeAway(sleep, SLEEP_FADE_SECONDS)", 1, true) ~= nil
		and cues:find("sleep.Playing = not awake", 1, true) == nil,
	"waking lets the breath die away rather than cutting it, and it is no longer toggled every frame")

-- The rage REPLACES the old wake: listed first, and only one of them is a roar.
local starWake = VOICES.starbloom and VOICES.starbloom.Wake
check(type(starWake) == "table" and starWake[1] == "ParentRageStarbloom" and starWake[2] == "ParentWakeStarbloom",
	"Astralmaw's roar is its rage when it has one, the old wake until then -- never both")
local rage = CUES.ParentRageStarbloom
check(rage ~= nil and rage.clip ~= nil and rage.clip >= 3.5 and rage.clip <= 4,
	"the rage keeps its whole first roar (to 3.9 s) and drops the cut-off second take", rage and rage.clip)
check(rage ~= nil and (rage.group or "World") == "World" and (rage.range or 0) >= 170,
	"and carries at least as far as every other roar", rage and rage.range)
local ember = CUES.ParentSleepEmberroot
check(ember ~= nil and ember.looped == true and ember.loopStart == 1.4 and ember.loopEnd == 4.8,
	"Emberroot's breathing loops its clean breath only (1.4 to 4.8 s), not the render's cut-off first one")
local star = CUES.ParentSleepStarbloom
check(star ~= nil and star.looped == true and star.loopStart == nil and (star.range or 0) <= 80,
	"Starbloom's hum loops as it is, close by, like every other sleep")
local shortRange = true
for _, name in ipairs({ "ParentSleepEmberroot", "ParentSleepStarbloom", "StormstriderSleep" }) do
	local cue = CUES[name]
	if not cue or (cue.range or 999) > (CUES.ParentSleep.range or 70) then
		shortRange = false
	end
end
check(shortRange, "no sleeping guardian carries further than the generic breath: the map is not filled")
for _, name in ipairs({ "ParentReturnDustbowl", "ParentReturnTanglemire", "ParentReturnEmberroot", "ParentReturnStarbloom" }) do
	local cue = CUES[name]
	check(cue ~= nil and cue.looped ~= true and (cue.group or "World") == "World"
			and (cue.range or 0) >= 60 and (cue.range or 0) <= 170,
		name .. " is a positional one-shot with a guardian's range")
end

--==============================================================================
-- 9. THE SEVEN UPLOADS, AND THE ASSET EACH ONE NAMES (2026-09-27; the group's
--    copies since 2026-09-28)
--
-- As in section 1: the id is written here as well as in GameConfig, so pointing
-- a guardian at a different upload is a deliberate change in two places, and no
-- two rows may share one -- a paste into the wrong row is a Starbloom that
-- breathes Emberroot's breath with no error anywhere. Seconds are the WAVs' in
-- sfx/, and the CrazyCozy Games group's uploads loaded in Podnappers at exactly
-- these lengths (Studio Edit load test, 2026-09-28).
--==============================================================================
say("\n-- the seven uploads --")
local UPLOADS = {
	{ "ParentSleepEmberroot", "140647760739270", 4.80 },
	{ "ParentSleepStarbloom", "120712332842926", 4.80 },
	{ "ParentReturnStarbloom", "139199037963607", 2.76 },
	{ "ParentReturnEmberroot", "76853063080329", 2.00 },
	{ "ParentReturnTanglemire", "95499040809968", 2.28 },
	{ "ParentReturnDustbowl", "107688968177239", 2.28 },
	{ "ParentRageStarbloom", "108747837024365", 6.00 },
	-- Stormstrider's two (2026-10-02): group uploads, loaded in Podnappers at
	-- exactly the WAVs' lengths (Studio Edit load test).
	{ "StormstriderWake", "113193227101300", 2.88 },
	{ "StormstriderSleep", "82607848172654", 11.88 },
}
-- The first uploads, on the owner's own account: Podnappers may not use them
-- (refused even after a grant, 2026-09-28), and a row that names one plays
-- SILENCE where a sound used to be. No row may go back to one.
local UNUSABLE = {
	"136756415808327", "131278197709092", "100144774034643", "116190097842912",
	"93033126566750", "92575459486923", "121932932319379", "123803156310043",
}
do
	local back = {}
	for name, cue in pairs(CUES) do
		if type(cue) == "table" then
			for _, id in ipairs(UNUSABLE) do
				if tostring(cue.id) == "rbxassetid://" .. id then
					table.insert(back, name .. " -> " .. id)
				end
			end
		end
	end
	check(#back == 0, "no cue row names one of the eight own-account uploads Podnappers cannot use",
		table.concat(back, ", "))
end
local rowsById = {}
for name, cue in pairs(CUES) do
	if type(cue.id) == "string" and cue.id ~= "" then
		rowsById[cue.id] = rowsById[cue.id] or {}
		table.insert(rowsById[cue.id], name)
	end
end
for _, row in ipairs(UPLOADS) do
	local name, id, seconds = row[1], row[2], row[3]
	local cue = CUES[name]
	check(cue ~= nil and cue.id == "rbxassetid://" .. id and SoundKit.cue(name) ~= nil,
		name .. " plays its own upload, " .. id, cue and cue.id)
	local sharing = if cue then rowsById[cue.id] else nil
	check(sharing ~= nil and #sharing == 1, name .. "'s id is no other row's",
		sharing and table.concat(sharing, ", "))
	if cue then
		local ends = math.max((cue.start or 0) + (cue.clip or 0), cue.loopEnd or 0)
		check(ends <= seconds + 0.001,
			string.format("%s's window ends inside its %.2f s (%.2f)", name, seconds, ends))
		check(type(cue.volume) == "number" and cue.volume > 0 and cue.volume <= 10,
			name .. " has a level the engine takes", cue.volume)
	end
end

if #fails > 0 then
	return ("ParentVoiceSpec: %d passed, %d FAILED\n  %s"):format(pass, #fails,
		table.concat(fails, "\n  "))
end
return ("ParentVoiceSpec: %d passed, 0 failed"):format(pass)
