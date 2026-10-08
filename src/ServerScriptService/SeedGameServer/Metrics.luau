--!strict
--==============================================================================
-- Steal a Seed :: Metrics
--
-- Launch analytics (2026-09-27): the one server-side layer between the game's
-- own success points and Roblox's AnalyticsService. MEASUREMENT ONLY -- nothing
-- here decides, grants, blocks or waits for anything. KB/ANALYTICS.md is the
-- reader's guide: every event, its trigger, its fields and its report.
--
--==============================================================================
-- CALLED FROM SUCCESS POINTS THAT ALREADY EXIST, AFTER THEY SUCCEED
--
--   PlayerDataService   a profile loaded (new or not), a tutorial milestone
--                       recorded for the FIRST time, the guide skipped
--   EconomyService      the one positive AddCash (garden income) that landed
--   CarryService        a nest pod taken; a carry ending -- banked, knocked
--                       down, died, confiscated, forfeited at night, left
--   NestService         a guardian's swing landing on a carrier
--   BonusChestService   a claim whose save was confirmed
--
-- Every public function is safe to call anywhere: it never yields, never
-- throws, and a failure inside it (a bad argument, AnalyticsService erroring)
-- is swallowed here -- gameplay, saving and purchases never see it.
--
--==============================================================================
-- NEVER FROM STUDIO, NEVER FOR A TEST PROFILE, NEVER FOR STAFF
--
-- Roblox sends nothing from Studio anyway; here Studio uses the DRY-RUN sink,
-- which only remembers the last events for a spec or a curious developer, so a
-- disposable-profile Play test cannot reach a report by any route. The two
-- admin accounts (AdminService's allowlist) are left out on a live server, and
-- with GameConfig.Metrics.StaffValidation they send one labelled
-- MetricsValidation event instead, for watching delivery in Creator Hub.
--
-- NOTHING PERSONAL GOES OUT. Event names are fixed words; every custom field is
-- one of a few fixed values (a biome id, a speed band, an outcome, a reward
-- id). No names, UserIds, plant ids, timestamps or free text. Roblox attaches
-- the player to an event itself, which is what makes a count "unique users".
--==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local TutorialData = require(Shared:WaitForChild("TutorialData"))

local Metrics = {}

export type Fields = { [string]: string }

-- Where an event goes. The live one is AnalyticsService; the dry run and the
-- specs' mock record instead.
export type Sink = {
	onboarding: (player: any, step: number, stepName: string, fields: Fields?) -> (),
	funnel: (player: any, funnel: string, session: string, step: number, stepName: string, fields: Fields?) -> (),
	custom: (player: any, name: string, value: number, fields: Fields?) -> (),
}

--==============================================================================
-- THE NAMES. Stable: renaming one starts a new series in Creator Hub.
--==============================================================================
type OnboardingRow = { step: number, name: string, milestone: string?, after: string? }

Metrics.Onboarding = {
	{ step = 1, name = "Session Ready" },
	{ step = 2, name = "First Pod Stolen", milestone = "steal" },
	{ step = 3, name = "First Pod Banked", milestone = "bank", after = "steal" },
	{ step = 4, name = "First Pod Planted", milestone = "place", after = "bank" },
	{ step = 5, name = "First Plant Hatched", milestone = "hatch", after = "place" },
	{ step = 6, name = "First Plant Income", after = "hatch" },
} :: { OnboardingRow }

Metrics.RaidFunnel = "GuardianRaid"
Metrics.ObbyFunnel = "ObbyRun"
Metrics.Events = {
	RaidEnded = "GuardianRaidEnded",
	TutorialStep = "TutorialStepDone",
	TutorialCompleted = "TutorialCompleted",
	TutorialSkipped = "TutorialSkipped",
	ChestClaimed = "BonusChestClaimed",
	Validation = "MetricsValidation",
	-- The obby's, inactive until GameConfig.Metrics.Obby (see THE OBBY below).
	ObbyEnded = "ObbyRunEnded",
	ObbyCheckpoint = "ObbyCheckpoint",
	-- The reward wheel's (2026-09-27, see THE WHEEL below).
	WheelSpinEarned = "WheelSpinEarned",
	WheelSpun = "WheelSpun",
}

-- The custom-field keys Roblox reads (Enum.AnalyticsCustomFieldKeys), by name.
local F1 = "CustomField01"
local F2 = "CustomField02"
local F3 = "CustomField03"

-- The only values a raid's outcome field may carry.
Metrics.Outcomes = {
	banked = true, -- crossed the red line with it: the raid paid
	captured = true, -- a guardian's swing landed (it took the pod, or threw the carrier and the pod fell)
	died = true, -- the carrier died holding it
	knocked = true, -- knocked down some other way (a bat, a trap) and the pod fell
	night = true, -- still out in a biome when night fell
	left = true, -- left the game holding it
	other = true, -- anything else that took it (an admin progress reset)
} :: { [string]: boolean }
Metrics.ObbyExits = { completed = true, exited = true, left = true } :: { [string]: boolean }

local BIOMES: { [string]: number } = {}
for _, biome in ipairs(BiomeData.Biomes) do
	BIOMES[biome.Id] = tonumber(biome.RecommendedSpeed) or 0
end

--==============================================================================
-- CONFIGURATION: GameConfig.Metrics, or a spec's overrides
--==============================================================================
local CONFIG: any = GameConfig.Metrics
local overrides: { [string]: any } = {}

local function setting(key: string): any
	local value = overrides[key]
	if value ~= nil then
		return value
	end
	return CONFIG[key]
end

--==============================================================================
-- THE SINKS
--==============================================================================
local LIVE: Sink = {
	onboarding = function(player, step, stepName, fields)
		game:GetService("AnalyticsService"):LogOnboardingFunnelStepEvent(player, step, stepName, fields)
	end,
	funnel = function(player, funnel, session, step, stepName, fields)
		game:GetService("AnalyticsService"):LogFunnelStepEvent(player, funnel, session, step, stepName, fields)
	end,
	custom = function(player, name, value, fields)
		game:GetService("AnalyticsService"):LogCustomEvent(player, name, value, fields)
	end,
}

-- The dry run: the last events, in memory only, bounded.
local KEEP = 200
local recorded: { any } = {}

local function remember(entry: any)
	table.insert(recorded, entry)
	if #recorded > KEEP then
		table.remove(recorded, 1)
	end
end

local DRY: Sink = {
	onboarding = function(player, step, stepName, fields)
		remember({ kind = "onboarding", player = player, step = step, name = stepName, fields = fields })
	end,
	funnel = function(player, funnel, session, step, stepName, fields)
		remember({ kind = "funnel", player = player, funnel = funnel, session = session, step = step,
			name = stepName, fields = fields })
	end,
	custom = function(player, name, value, fields)
		remember({ kind = "custom", player = player, name = name, value = value, fields = fields })
	end,
}

local sinkOverride: Sink? = nil

local function sink(): Sink
	local chosen = sinkOverride
	if chosen then
		return chosen
	end
	return if RunService:IsStudio() then DRY else LIVE
end

--==============================================================================
-- THE BUDGET: a per-server bucket, refilled continuously. A call over it is
-- dropped and counted, never queued -- nothing waits, nothing arrives late.
--==============================================================================
local clock: () -> number = os.clock
local tokens = 0
local refilledAt = -math.huge
local dropped = 0
local failures = 0

local function spend(): boolean
	local cap = math.max(1, tonumber(setting("PerMinute")) or 60)
	local now = clock()
	if refilledAt == -math.huge then
		tokens, refilledAt = cap, now
	else
		tokens = math.min(cap, tokens + (now - refilledAt) * cap / 60)
		refilledAt = now
	end
	if tokens < 1 then
		dropped += 1
		return false
	end
	tokens -= 1
	return true
end

--==============================================================================
-- WHO IS COUNTED
--==============================================================================
local function isStaff(player: any): boolean
	-- Asked lazily: AdminService requires PlayerDataService, which requires this,
	-- so a load-time require would be a cycle. By the time anybody plays, every
	-- service has loaded and this is a table lookup.
	local ok, admin = pcall(function(): any
		local found = script.Parent:FindFirstChild("AdminService")
		return if found and found:IsA("ModuleScript") then require(found) :: any else nil
	end)
	if ok and type(admin) == "table" and type(admin.IsAdmin) == "function" then
		local okAsk, answer = pcall(admin.IsAdmin, player)
		return okAsk and answer == true
	end
	return false
end

local staffOverride: ((any) -> boolean)? = nil

-- "count" (send for real), "validate" (staff: send the validation stand-in) or
-- nil (send nothing).
local function audience(player: any): string?
	if setting("Enabled") ~= true then
		return nil
	end
	-- A real Player; a spec's stand-in table only while a spec's sink is set.
	if typeof(player) ~= "Instance" and not (type(player) == "table" and sinkOverride ~= nil) then
		return nil
	end
	local check = staffOverride
	local staff = if check then check(player) else isStaff(player)
	if staff and setting("ExcludeStaff") == true then
		return if setting("StaffValidation") == true then "validate" else nil
	end
	return "count"
end

-- One call into the sink, budgeted and fenced. Returns whether it went out.
local function send(kind: string, player: any, ...: any): boolean
	if not spend() then
		return false
	end
	local out = sink() :: any
	local ok = pcall(out[kind], player, ...)
	if not ok then
		failures += 1
	end
	return ok
end

local function validation(player: any, stands: string)
	send("custom", player, Metrics.Events.Validation, 1, { [F1] = stands })
end

--==============================================================================
-- PER PLAYER, FOR THIS SESSION ONLY. Nothing here is saved: what must survive
-- a rejoin (which guide steps are done) is already in the profile, and the
-- cohort is read off the profile's CreatedAt.
--==============================================================================
type Raid = {
	session: string,
	biome: string,
	band: string,
	startedAt: number,
	ended: boolean,
}

type State = {
	cohort: boolean,
	-- Onboarding steps already sent this session.
	onboarded: { [number]: boolean },
	-- Milestones already reported this session: a repeated callback is ignored
	-- even if a caller ever sends one twice.
	seen: { [string]: boolean },
	hatchedThisSession: boolean,
	incomeLogged: boolean,
	skipLogged: boolean,
	raid: Raid?,
}

local states: { [any]: State } = setmetatable({}, { __mode = "k" }) :: any

local function stateOf(player: any): State
	local s = states[player]
	if not s then
		s = { cohort = false, onboarded = {}, seen = {}, hatchedThisSession = false, incomeLogged = false,
			skipLogged = false, raid = nil }
		states[player] = s
	end
	return s :: State
end

local function inCohort(profile: any): boolean
	local created = if type(profile) == "table" then tonumber(profile.CreatedAt) else nil
	local since = tonumber(setting("CohortSince")) or math.huge
	return created ~= nil and created >= since
end

function Metrics.speedBand(speed: number?, recommended: number?): string
	local rec = tonumber(recommended) or 0
	local s = tonumber(speed) or 0
	if rec <= 0 then
		return "none"
	end
	if s < rec * (tonumber(setting("BelowShare")) or 0.8) then
		return "below"
	end
	if s < rec * (tonumber(setting("AboveShare")) or 1.25) then
		return "near"
	end
	return "above"
end

--==============================================================================
-- THE ONBOARDING FUNNEL (one per user; Roblox ignores a repeated step)
--
-- ORDER IS ENFORCED HERE, NOT LEFT TO ROBLOX. A funnel credits every step below
-- one that is logged, so logging "First Pod Planted" for somebody who never
-- banked would imply they did. So when a milestone is recorded for the first
-- time, the chain is walked from step 2: each step goes out while every
-- milestone up to it is done in the player's own profile, and the walk stops
-- at the first gap. A plant that came BEFORE any bank (a pod from elsewhere)
-- is therefore reported when the bank catches up, never ahead of it. A step
-- already sent this session is not sent again; one sent in an earlier session
-- may be, and Roblox counts only a user's first instance of a step.
--==============================================================================
local function onboard(player: any, index: number)
	local row = Metrics.Onboarding[index]
	local s = states[player]
	if s then
		if s.onboarded[index] then
			return
		end
		s.onboarded[index] = true
	end
	local who = audience(player)
	if who == "count" then
		send("onboarding", player, row.step, row.name)
	elseif who == "validate" then
		validation(player, "onboarding " .. row.step)
	end
end

-- A profile is ready. `isNew`: no save existed ("new" from SaveService.Load);
-- `persistent`: the save can be written (a temporary profile never counts).
function Metrics.profileReady(player: any, profile: any, isNew: boolean, persistent: boolean)
	pcall(function()
		local s = stateOf(player)
		s.cohort = persistent == true and inCohort(profile)
		if s.cohort and isNew == true then
			onboard(player, 1)
		end
	end)
end

-- A tutorial milestone was recorded for the FIRST time (PlayerDataService.
-- RecordTutorial returned true). `progress` is the profile's Tutorial record,
-- already updated.
function Metrics.milestone(player: any, milestone: string, progress: any)
	pcall(function()
		local s = states[player]
		if not s or not s.cohort or s.seen[milestone] then
			return
		end
		s.seen[milestone] = true
		local done = if type(progress) == "table" and type(progress.Done) == "table" then progress.Done else {}
		-- Walk the chain: steps 2..5, each while its own milestone and every one
		-- before it are done, stopping at the first gap.
		for index, row in ipairs(Metrics.Onboarding) do
			local needs = row.milestone
			if needs then
				if done[needs] ~= true then
					break
				end
				onboard(player, index)
			end
		end
		-- Step 5 went out this session (whichever milestone completed the chain):
		-- the first income from here on is the funnel's last step.
		if s.onboarded[5] then
			s.hatchedThisSession = true
		end
		local who = audience(player)
		if who == "count" then
			send("custom", player, Metrics.Events.TutorialStep, 1, { [F1] = milestone })
			-- THE FIRST LOOP, train through hatch (2026-10-08): Version 2's whole
			-- guide, so the series keeps its meaning and nothing is renumbered.
			-- The guide's step 7, `travel`, goes out as its own TutorialStepDone
			-- above and never sends this a second time.
			if TutorialData.InFirstLoop(milestone) and TutorialData.FirstLoopDone(progress) then
				send("custom", player, Metrics.Events.TutorialCompleted, 1)
			end
		elseif who == "validate" then
			validation(player, "tutorial " .. milestone)
		end
	end)
end

-- Garden income landed (EconomyService, the one positive AddCash). The funnel's
-- last step: only in the session the first plant hatched, once.
function Metrics.income(player: any)
	pcall(function()
		local s = states[player]
		if not s or not s.cohort or not s.hatchedThisSession or s.incomeLogged then
			return
		end
		s.incomeLogged = true
		onboard(player, 6)
	end)
end

-- The guide was hidden (PlayerDataService.SetTutorialSkipped succeeded).
function Metrics.tutorialSkipped(player: any, skipped: boolean)
	pcall(function()
		local s = states[player]
		if skipped ~= true or not s or not s.cohort or s.skipLogged then
			return
		end
		s.skipLogged = true
		local who = audience(player)
		if who == "count" then
			send("custom", player, Metrics.Events.TutorialSkipped, 1)
		elseif who == "validate" then
			validation(player, "tutorial skipped")
		end
	end)
end

--==============================================================================
-- GUARDIAN RAIDS: A RECURRING FUNNEL AND ONE ENDING EACH
--
-- A raid starts when a pod is TAKEN FROM A NEST (not when a dropped one is
-- picked back up) and ends the first time that pod leaves the thief's hands --
-- banked, or lost one of five ways. Its funnel session is a fresh GUID, never
-- anything about the player.
--
--   GuardianRaid        step 1 "Pod Stolen" (fields: biome, speed band)
--                       step 2 "Pod Banked" -- only on a bank, never on "no
--                       longer chased"
--   GuardianRaidEnded   once per raid: value = seconds from theft to ending,
--                       fields: biome, speed band, outcome
--==============================================================================
function Metrics.raidEnded(player: any, outcome: string)
	pcall(function()
		local s = states[player]
		local raid = if s then s.raid else nil
		if not raid or raid.ended then
			return
		end
		raid.ended = true
		local why = if Metrics.Outcomes[outcome] then outcome else "left"
		local seconds = math.max(0, math.floor((clock() - raid.startedAt) * 10 + 0.5) / 10)
		local who = audience(player)
		if who == "count" then
			if why == "banked" then
				send("funnel", player, Metrics.RaidFunnel, raid.session, 2, "Pod Banked")
			end
			send("custom", player, Metrics.Events.RaidEnded, seconds,
				{ [F1] = raid.biome, [F2] = raid.band, [F3] = why })
		elseif who == "validate" then
			validation(player, "raid " .. why)
		end
	end)
end

function Metrics.raidStarted(player: any, biomeId: string?, speed: number?)
	pcall(function()
		local s = stateOf(player)
		local open = s.raid
		if open and not open.ended then
			-- A second theft while the first is still open cannot happen with one
			-- pod in the hands; if it ever does, the first is closed rather than
			-- left to be counted with the second.
			Metrics.raidEnded(player, "left")
		end
		local biome = if type(biomeId) == "string" and BIOMES[biomeId] ~= nil then biomeId else "other"
		local raid: Raid = {
			session = HttpService:GenerateGUID(false),
			biome = biome,
			band = Metrics.speedBand(speed, BIOMES[biome]),
			startedAt = clock(),
			ended = false,
		}
		s.raid = raid
		local who = audience(player)
		if who == "count" then
			send("funnel", player, Metrics.RaidFunnel, raid.session, 1, "Pod Stolen",
				{ [F1] = raid.biome, [F2] = raid.band })
		elseif who == "validate" then
			validation(player, "raid stolen")
		end
	end)
end

-- A guardian's swing landed on this player. Ends their open raid as captured;
-- the drop the throw causes a moment later then finds nothing open.
function Metrics.guardianCaught(player: any)
	Metrics.raidEnded(player, "captured")
end

--==============================================================================
-- THE BONUS CHEST: a CONFIRMED grant only (the claim's save succeeded).
--==============================================================================
function Metrics.chestClaimed(player: any, rewardId: string)
	pcall(function()
		local reward = if type(rewardId) == "string" and GameConfig.bonusChestReward(rewardId) ~= nil
			then rewardId
			else nil
		if not reward then
			return
		end
		local who = audience(player)
		if who == "count" then
			send("custom", player, Metrics.Events.ChestClaimed, 1, { [F1] = reward })
		elseif who == "validate" then
			validation(player, "chest " .. reward)
		end
	end)
end

--==============================================================================
-- THE OBBY: WRITTEN, AND INACTIVE UNTIL GameConfig.Metrics.Obby
--
-- The course does not exist yet. These are the calls it will make at its own
-- server-validated moments; with the switch off (and nothing calling them) they
-- send nothing, so no report shows a run nobody could start.
--
--   ObbyRun             recurring funnel, one GUID per run: 1 "Run Started",
--                       2 "Checkpoint 1", 3 "Checkpoint 2", 4 "Finished"
--   ObbyCheckpoint      field: which checkpoint (main1, main2, challenge)
--   ObbyRunEnded        once per run; value = seconds; fields: how it ended
--                       (completed, exited, left), route (main, challenge),
--                       falls bucket (0, 1-2, 3-5, 6+)
--==============================================================================
type Run = {
	session: string,
	startedAt: number,
	falls: number,
	route: string,
	ended: boolean,
	reached: { [string]: boolean },
}
local runs: { [any]: Run } = setmetatable({}, { __mode = "k" }) :: any
local CHECKPOINT_STEP: { [string]: number } = { main1 = 2, main2 = 3 }

local function obbyOn(): boolean
	return setting("Obby") == true
end

function Metrics.obbyStarted(player: any)
	pcall(function()
		if not obbyOn() then
			return
		end
		local run: Run = {
			session = HttpService:GenerateGUID(false),
			startedAt = clock(),
			falls = 0,
			route = "main",
			ended = false,
			reached = {},
		}
		runs[player] = run
		if audience(player) == "count" then
			send("funnel", player, Metrics.ObbyFunnel, run.session, 1, "Run Started")
		end
	end)
end

function Metrics.obbyCheckpoint(player: any, which: string)
	pcall(function()
		local run = runs[player]
		if not obbyOn() or not run or run.ended or run.reached[which] then
			return
		end
		if which ~= "main1" and which ~= "main2" and which ~= "challenge" then
			return
		end
		-- In order: the second only after the first, like the course itself.
		if which == "main2" and not run.reached.main1 then
			return
		end
		run.reached[which] = true
		if which == "challenge" then
			run.route = "challenge"
		end
		if audience(player) == "count" then
			local step = CHECKPOINT_STEP[which]
			if step then
				send("funnel", player, Metrics.ObbyFunnel, run.session, step, "Checkpoint " .. (step - 1))
			end
			send("custom", player, Metrics.Events.ObbyCheckpoint, 1, { [F1] = which })
		end
	end)
end

function Metrics.obbyFell(player: any)
	local run = runs[player]
	if run and not run.ended then
		run.falls += 1
	end
end

local function fallsBucket(n: number): string
	if n <= 0 then
		return "0"
	elseif n <= 2 then
		return "1-2"
	elseif n <= 5 then
		return "3-5"
	end
	return "6+"
end

-- `how`: "completed" (the server validated the finish), "exited" (Exit/Return
-- to Plot), "left" (disconnected mid-run).
function Metrics.obbyEnded(player: any, how: string)
	pcall(function()
		local run = runs[player]
		if not obbyOn() or not run or run.ended then
			return
		end
		run.ended = true
		local why = if Metrics.ObbyExits[how] then how else "left"
		local seconds = math.max(0, math.floor((clock() - run.startedAt) * 10 + 0.5) / 10)
		if audience(player) == "count" then
			if why == "completed" and run.reached.main2 then
				send("funnel", player, Metrics.ObbyFunnel, run.session, 4, "Finished")
			end
			send("custom", player, Metrics.Events.ObbyEnded, seconds,
				{ [F1] = why, [F2] = run.route, [F3] = fallsBucket(run.falls) })
		end
	end)
end

--==============================================================================
-- THE WHEEL (2026-09-27)
--
-- Two moments, each sent only after the change it reports is on the profile:
--
--   WheelSpinEarned  a completion earned a spin; value 1, field 1 the window's
--                    count after it, "1".."5" (never a player detail)
--   WheelSpun        a spin was spent and its prize recorded and SAVED; value
--                    1, field 1 the prize id paid (WheelData's twelve), field 2
--                    "earned" or "bought"
--==============================================================================
function Metrics.wheelSpinEarned(player: any, count: number)
	pcall(function()
		local n = math.floor(tonumber(count) or 0)
		if n < 1 or n > 9 then
			return
		end
		local who = audience(player)
		if who == "count" then
			send("custom", player, Metrics.Events.WheelSpinEarned, 1, { [F1] = tostring(n) })
		elseif who == "validate" then
			validation(player, "wheel spin earned " .. n)
		end
	end)
end

function Metrics.wheelSpun(player: any, prizeId: string, source: string)
	pcall(function()
		local WheelData = require(Shared:WaitForChild("WheelData")) :: any
		if type(prizeId) ~= "string" or WheelData.ById[prizeId] == nil then
			return
		end
		local from = if source == "bought" then "bought" else "earned"
		local who = audience(player)
		if who == "count" then
			send("custom", player, Metrics.Events.WheelSpun, 1, { [F1] = prizeId, [F2] = from })
		elseif who == "validate" then
			validation(player, "wheel " .. prizeId .. " " .. from)
		end
	end)
end

--==============================================================================
-- LEAVING
--==============================================================================
function Metrics.playerLeft(player: any)
	Metrics.raidEnded(player, "left")
	Metrics.obbyEnded(player, "left")
	states[player] = nil
	runs[player] = nil
end

--==============================================================================
-- FOR SPECS AND FOR LOOKING: a sink, overrides, a staff check, a clock, and
-- what went out
--==============================================================================
function Metrics.useSink(fake: Sink?)
	sinkOverride = fake
end

function Metrics.configure(values: { [string]: any }?)
	overrides = values or {}
end

function Metrics.useStaffCheck(fn: ((any) -> boolean)?)
	staffOverride = fn
end

function Metrics.useClock(fn: (() -> number)?)
	clock = fn or os.clock
end

function Metrics.reset()
	table.clear(states)
	table.clear(runs)
	table.clear(recorded)
	tokens, refilledAt, dropped, failures = 0, -math.huge, 0, 0
end

-- The dry run's memory, newest last (Studio only; a live server keeps none).
function Metrics.recent(): { any }
	return table.clone(recorded)
end

-- Calls dropped by the budget, and sink calls that errored (and were ignored).
function Metrics.health(): (number, number)
	return dropped, failures
end

Players.PlayerRemoving:Connect(function(player)
	Metrics.playerLeft(player)
end)

return Metrics
