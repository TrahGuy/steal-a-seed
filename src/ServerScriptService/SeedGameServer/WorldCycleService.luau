--!strict
-- Steal a Seed :: WorldCycleService
--
-- The day, and the night that restocks it.
--
--==============================================================================
-- WHY THE SUPPLY HAD TO BECOME A BATCH
--
-- Greenhollow holds ONE nest of five pods. Under the old rule a taken slot grew
-- a new one 22 seconds later, which meant the nest was never actually empty:
-- take a pod, wait, take it again, forever, from the same spot. Clearing a ring
-- meant nothing. The scarcity the entire road is built around -- distance is
-- difficulty, the run home is the price -- existed on the map and not in the
-- game.
--
-- So the supply is a BATCH. Every live nest is stocked once at dawn, a taken
-- slot stays empty for the rest of the day, an emptied nest stays emptied, and
-- whatever is left at dusk is destroyed rather than carried over -- because a
-- hoarded nest would otherwise be a way to start tomorrow ahead of everybody.
--
--     420s DAY     five pods for up to six players
--      15s NIGHT   the road is shut and the world is reset
--      45s WARNING enough time to decide whether to go in or turn round
--
-- The night was 60 s until 2026-09-23. Nothing below waits on its length: the
-- dusk teardown finishes before the night's single wait starts, and the dawn
-- batch is built and counted before Day is published, so 15 s is enough for
-- every step however short it gets.
--
--==============================================================================
-- ONE OWNER, AND IT IS THIS FILE
--
-- Four systems change at dusk -- pods, parents, the gate, the barrier -- and if
-- each one had its own timer they would drift apart within an hour and the
-- failure would look like a different bug every time. This holds the only clock.
-- NestService owns what happens to a nest, CarryService owns what a carry is,
-- MapService owns the barrier; this owns WHEN, and nothing else does.
--
--==============================================================================
-- THE PHASE IS AN ATTRIBUTE, AND THE COUNTDOWN IS A SUBTRACTION
--
--     WorldPhase        "Day" or "Night"
--     WorldPhaseEndsAt  the workspace:GetServerTimeNow() of the next change
--     WorldCycleIndex   bumped at every dawn
--
-- Three writes per phase instead of a remote every second. The client works the
-- number out on its own clock, so a seven-minute day costs nothing per player,
-- and somebody who joins at 03:12 is correct on their FIRST FRAME with nothing
-- sent to them -- which is the property a broadcast could not give without a
-- join handshake.
--
-- Read-only by convention and by construction: a client writing these changes
-- only its own view, and nothing here ever reads them back off a client. There
-- is no remote in this file in either direction.
--
--==============================================================================
-- THE ORDER OF A TRANSITION IS THE WHOLE CORRECTNESS ARGUMENT
--
-- DUSK   phase first, so every take in flight is refused from that instant;
--        then shut the road; then eject; then clear the world.
--
-- DAWN   stock the nests while it is STILL NIGHT, prove the batch exists, set
--        Day, and only then open the barrier.
--
-- Both orders exist to close one race each. Clearing before setting the phase
-- would let a hold that completes mid-teardown succeed into a nest that no
-- longer exists. Opening before setting Day would have the gate eject -- and
-- therefore FORFEIT the carry of -- anybody who stepped through in that gap.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local MapService = require(script.Parent:WaitForChild("MapService"))
local NestService = require(script.Parent:WaitForChild("NestService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))

local WorldCycleService = {}
-- Last. It drives MapService (1), BiomeGateService (25), NestService (40) and
-- CarryService (45), so every one of them has to have Started before the first
-- transition can be asked of it.
WorldCycleService.Priority = 70

local CYCLE = GameConfig.WorldCycle
local ATTR = GameConfig.Attributes

local running = false
local serviceConnections: { RBXScriptConnection } = {}
-- Bumped every time the loop is (re)started. The running loop checks it and
-- exits if it is not the newest -- see Start.
local generation = 0

local function log(message: string)
	print("[Seed/WorldCycleService] " .. message)
end

--==============================================================================
-- READ API
--==============================================================================
function WorldCycleService.Phase(): string
	local phase = Workspace:GetAttribute(ATTR.WorldPhase)
	return if type(phase) == "string" then phase else CYCLE.PhaseDay
end

function WorldCycleService.IsDay(): boolean
	return WorldCycleService.Phase() ~= CYCLE.PhaseNight
end

function WorldCycleService.SecondsLeft(): number
	local endsAt = Workspace:GetAttribute(ATTR.WorldPhaseEndsAt)
	if type(endsAt) ~= "number" then
		return 0
	end
	return math.max(0, endsAt - Workspace:GetServerTimeNow())
end

function WorldCycleService.CycleIndex(): number
	local index = Workspace:GetAttribute(ATTR.WorldCycleIndex)
	return if type(index) == "number" then index else 0
end

--==============================================================================
-- PUBLISHING A PHASE
--
-- The deadline is absolute and on the SERVER'S clock. Not "15 seconds from now"
-- sent to each client to count down locally -- those drift, and two players
-- would see the road shut at different moments.
--
-- Both attributes are written in the same frame, deadline first. WorldClock
-- holds its last words for the rare frame in which only one of the pair has
-- arrived, so a boundary never shows the old phase with the new time.
--==============================================================================
local function publish(phase: string, seconds: number)
	Workspace:SetAttribute(ATTR.WorldPhaseEndsAt, Workspace:GetServerTimeNow() + seconds)
	Workspace:SetAttribute(ATTR.WorldPhase, phase)
end

--==============================================================================
-- LOOSE PODS
--
-- The nests clear themselves; this is for the ones lying on the road -- dropped
-- when somebody was ragdolled, or thrown down on purpose. Both are unbanked
-- wild pods and both go.
--
-- BY TAG, WHICH IS AN INDEX AND NOT A SCAN. CollectionService hands back the
-- tagged set directly; nothing here walks the workspace.
--
-- A CARRIED pod is not in this set. CarryService deliberately tags a pod in
-- somebody's hands `CarriedPod` and strips `SeedPod` from it -- "a pod on the
-- road is scenery you may take and a pod being carried is a target" -- so this
-- cannot reach into anybody's hands. A planted one is `Planted`, and is not in
-- this set either.
--==============================================================================
local function clearLoosePods(): number
	local removed = 0
	for _, pod in ipairs(CollectionService:GetTagged(GameConfig.Tags.SeedPod)) do
		if pod.Parent then
			pod:Destroy()
			removed += 1
		end
	end
	return removed
end

--==============================================================================
-- EVERYBODY OUT
--
-- BiomeGateService's poll does this on its own within a tenth of a second, and
-- would do it correctly if this did not exist. It runs anyway, immediately,
-- because "the road shut and a moment later you were moved" and "the road shut
-- and you were moved" are different experiences at the exact moment a player is
-- watching for it -- and because the ejection forfeits a carry, which should
-- happen on the frame the rule changed rather than on the next poll.
--
-- The push and the forfeit are the road service's, not this file's. Asking it keeps one
-- definition of where the safe side is.
--==============================================================================
local function ejectEveryone(): (number, number)
	local moved, forfeited = 0, 0
	local roadService = script.Parent:FindFirstChild("BiomeGateService")
	local Road = if roadService then require(roadService) :: any else nil
	if not Road then
		return 0, 0
	end
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") and Road.OrderAt(root.Position) >= 1 then
			if CarryService.IsCarrying(player) then
				forfeited += 1
			end
			moved += 1
		end
	end
	-- One tick of the road service's logic, rather than a second copy here.
	if Road.SweepNow then
		Road.SweepNow()
	end
	return moved, forfeited
end

--==============================================================================
-- DUSK
--==============================================================================
local function toNight()
	--== 1. THE RULE, FIRST ==--
	-- Every take from this instant is refused. CarryService checks the phase
	-- above all its other refusals for exactly this moment.
	publish(CYCLE.PhaseNight, CYCLE.NightSeconds)

	--== 2. THE WALL ==--
	MapService.SetNightBarrier(true)

	--== 3. THE PEOPLE ==--
	local moved, forfeited = ejectEveryone()

	--== 4. THE WORLD ==--
	local nestPods = NestService.ClearForNight()
	local loose = clearLoosePods()
	local parents = NestService.ResetParents()

	log(string.format(
		"NIGHT. %ds. Removed %d nest pod(s) and %d loose pod(s), reset %d parent(s), "
			.. "moved %d player(s) out (%d carry forfeited).",
		CYCLE.NightSeconds, nestPods, loose, parents, moved, forfeited))
end

--==============================================================================
-- DAWN
--
-- The batch is built while it is still NIGHT and the road is still shut, and the
-- result is checked before anything opens. If a nest somehow came up short the
-- day still starts -- a server that refused to open because one slot failed to
-- roll would be a server nobody can play -- but it says so, loudly, with the
-- numbers, because "the nests are stocked" is a claim and "5 of 5" is a fact.
--==============================================================================
local function toDay(): (number, number)
	local built, wanted = NestService.StockAll()
	if built < wanted then
		warn(string.format(
			"[Seed/WorldCycleService] dawn batch is short: %d of %d slot(s) filled. "
				.. "The day is starting anyway; a closed road is worse than a thin nest.",
			built, wanted))
	end

	-- Day BEFORE the barrier: the gate stops ejecting the moment the phase
	-- changes, so nobody who steps through the opening gap has their carry
	-- forfeited by a rule that is already over.
	publish(CYCLE.PhaseDay, CYCLE.DaySeconds)
	Workspace:SetAttribute(ATTR.WorldCycleIndex, WorldCycleService.CycleIndex() + 1)
	MapService.SetNightBarrier(false)

	local live, capacity = NestService.PodCount()
	log(string.format("DAY %d. %ds. %d nest(s) stocked, %d of %d pod(s) standing.",
		WorldCycleService.CycleIndex(), CYCLE.DaySeconds,
		NestService.NestCount(), live, capacity))
	return built, wanted
end

--==============================================================================
-- ONE TRANSITION AT A TIME
--
-- Dusk and dawn each run to the end before another may start, whoever asked --
-- the loop at a deadline, or an admin's console. Neither yields today, so in
-- practice this never refuses anything; it is here so that the day either one
-- starts to (a restock that waits on something, an ejection that animates) two
-- overlapping requests still cannot stock the nests twice or reset the parents
-- in the middle of a restock. A request that finds one running is told BUSY and
-- changes nothing.
--==============================================================================
local transitioning = false

local function transition(toNightNow: boolean): (boolean, string, number?, number?)
	if transitioning then
		return false, "BUSY", nil, nil
	end
	transitioning = true
	local ok: boolean, built: any, wanted: any
	if toNightNow then
		ok, built = pcall(toNight)
	else
		ok, built, wanted = pcall(toDay)
	end
	transitioning = false
	if not ok then
		warn("[Seed/WorldCycleService] transition failed: " .. tostring(built))
		-- Never leave the world stuck in a phase with no deadline: a night that
		-- never ends is a server nobody can play.
		publish(WorldCycleService.Phase(),
			if WorldCycleService.IsDay() then CYCLE.DaySeconds else CYCLE.NightSeconds)
		return false, "FAILED", nil, nil
	end
	return true, "OK", built, wanted
end

--==============================================================================
-- ONE LOOP, AND IT SLEEPS
--
-- Not a Heartbeat and not a per-second tick: it waits out the phase in a
-- single task.wait and does its work at the boundary. A seven-minute day is
-- one wait. Nothing on the server counts down -- the clients each subtract
-- from the deadline, which is what a countdown is.
--
-- The generation check is what makes re-running safe. A Rojo sync re-runs
-- Init and Start while the previous loop is still asleep inside its wait;
-- when it wakes it finds it is not the newest and returns, so two cycles can
-- never both be driving the world.
--
-- AND IT IS WHAT MAKES A FORCED CHANGE RESUME THE CYCLE. The loop sleeps
-- until the deadline it read when it last woke, so a night started by hand
-- would otherwise last as long as the day it replaced had left. StartNight and
-- StartDay start a NEW loop on the new deadline; the old one wakes at its stale
-- deadline, finds it is not the newest, and goes -- so the 15-second night and
-- the 420-second day carry on from the forced change exactly as configured.
--==============================================================================
local function runLoop()
	generation += 1
	local mine = generation
	running = true
	task.spawn(function()
		while running and generation == mine do
			local left = WorldCycleService.SecondsLeft()
			if left > 0 then
				task.wait(left)
			end
			if not running or generation ~= mine then
				return
			end
			local _, why = transition(WorldCycleService.IsDay())
			if why == "BUSY" then
				-- A forced change is part-way through. It starts its own loop when
				-- it lands; this looks again in a moment in case it did not.
				task.wait(0.25)
			end
		end
	end)
end

--==============================================================================
-- FORCED CHANGES: THE ADMIN CONSOLE, AND THE COMMAND BAR
--
-- Not a remote and not reachable by a client: module functions on the server,
-- which AdminService calls only after it has checked who asked. Each is the
-- NORMAL transition -- the same toNight / toDay the loop runs, with the barrier,
-- the ejection and its carry forfeits, the pod clear, the guardian reset, the
-- dawn restock and the published deadline that the clock, the music and the
-- lighting all read -- and then a fresh loop on the new deadline.
--
-- Asking for the phase that is already running does nothing at all: Start Day
-- by day restocks nothing, which is what keeps a button from being a pod tap.
--==============================================================================
-- The loop is restarted whether the transition finished or failed part-way:
-- either way a fresh deadline has been published (see transition), and the loop
-- has to be the one sleeping on it, not the old one on the day's stale deadline.
function WorldCycleService.StartNight(): (boolean, string)
	if transitioning then
		return false, "BUSY"
	end
	if not WorldCycleService.IsDay() then
		return false, "ALREADY_NIGHT"
	end
	local ok, why = transition(true)
	runLoop()
	return ok, why
end

function WorldCycleService.StartDay(): (boolean, string, number?, number?)
	if transitioning then
		return false, "BUSY", nil, nil
	end
	if WorldCycleService.IsDay() then
		return false, "ALREADY_DAY", nil, nil
	end
	local ok, why, built, wanted = transition(false)
	runLoop()
	return ok, why, built, wanted
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function WorldCycleService.Init()
	running = false
	generation += 1
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)

	--==========================================================================
	-- A FRESH SERVER STARTS IN DAY, STOCKED
	--
	-- Set in Init rather than Start so that every service which reads the phase
	-- during its own Start -- and CarryService reads it on the first take --
	-- finds Day rather than nil. GameConfig.isDay treats nil as Day for the same
	-- reason, but a real value is better than a lenient default.
	--==========================================================================
	Workspace:SetAttribute(ATTR.WorldCycleIndex, 0)
	publish(CYCLE.PhaseDay, CYCLE.DaySeconds)
end

function WorldCycleService.Start()
	-- NestService.Start has already stocked every nest it built, so the first
	-- day begins full without this doing anything. Said out loud because the
	-- rule is "one batch per day" and boot is the first day's batch.
	local live, capacity = NestService.PodCount()
	MapService.SetNightBarrier(false)
	publish(CYCLE.PhaseDay, CYCLE.DaySeconds)

	log(string.format(
		"Ready. Day %ds, night %ds, warning at %ds. Fresh server starts in DAY with "
			.. "%d of %d pod(s) across %d nest(s). "
			.. "Phase is an attribute on the Workspace; there is no remote.",
		CYCLE.DaySeconds, CYCLE.NightSeconds, CYCLE.WarnSeconds,
		live, capacity, NestService.NestCount()))

	-- The loop, on the deadline just published. See ONE LOOP, AND IT SLEEPS.
	runLoop()
end

-- The command bar's old name for whichever of the two is next. It used to run
-- the transition and leave the loop asleep on the OLD deadline; it is the forced
-- change now, loop and all.
function WorldCycleService.ForcePhaseNow()
	if WorldCycleService.IsDay() then
		WorldCycleService.StartNight()
	else
		WorldCycleService.StartDay()
	end
end

function WorldCycleService.Snapshot(): string
	local live, capacity = NestService.PodCount()
	return string.format("%s, %.1fs left, cycle %d, %d/%d pods, barrier %s",
		WorldCycleService.Phase(), WorldCycleService.SecondsLeft(),
		WorldCycleService.CycleIndex(), live, capacity,
		(function()
			local b = MapService.GetNightBarrier()
			return if b then (if b.CanCollide then "shut" else "open") else "missing"
		end)())
end

return WorldCycleService
