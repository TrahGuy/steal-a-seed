--!strict
--==============================================================================
-- Steal a Seed :: EnchantedMistService (2026-10-11)
--
-- THE ONE COORDINATOR for Enchanted Mist's schedule: when it is eligible, when
-- it starts, when it ends. Everything else of the event (berries, Mosskeeper,
-- the pods, the look) follows the state this publishes.
--
-- THE SCHEDULE (the owner, 2026-10-11 -- EnchantedMistData.Schedule):
--   * A new server becomes ELIGIBLE a random 10-30 minutes after it starts
--     (20-60 until 2026-10-16, the owner: "from 1 hour to 30mins").
--   * Once eligible it waits for the next COMPLETED NATURAL RESET --
--     WorldCycleService.OnDawn with source "cycle": the nests stocked (a short
--     batch is reported, not waited out), Day published, the road reopened.
--     It never forces a reset, never interrupts a raid, never skips a Pod
--     Rush's hold: it only waits for the dawn the cycle makes anyway.
--   * It is ACTIVE for 300 seconds: a night LOOK, gameplay in Day, biomes open.
--   * Its next eligibility is measured from that START: 30 minutes on (60
--     until 2026-10-16). With the unchanged 435-second cycle that is about
--     35:15 between starts.
--   * Its end triggers no reset and no restock.
--
-- NOT A NEW EVENT: boot (no dawn happens at boot), an admin-forced dawn
-- (source "admin"), a dawn whose barrier did not open, a duplicate callback for
-- a dawn already used. A forced NIGHT during the Mist ends it early -- the
-- road closes, so its biome berries could not be reached.
--
-- OFF UNTIL APPROVED: with EnchantedMistConfig.Enabled false, or any binding
-- MissingBindings lists, the state is "disabled" and nothing is scheduled.
--
-- AN ADMIN'S MIST (the owner, 2026-10-11: START MIST NOW / END MIST NOW on the
-- admin console, AdminService): a normal Mist -- 300 s (or 2 or 10 minutes,
-- 2026-10-12), the berries, the deliveries, the look, the sign's ACTIVE
-- countdown -- started at once, EVEN WITH Enabled FALSE (every binding built).
-- MAKE ELIGIBLE NOW (2026-10-12) cuts the schedule's cooldown short while it
-- runs, and never starts a Mist itself.
-- Refused while one runs, while a binding is missing, and at Night (the road
-- is shut, and a forced Night ends a Mist). Source "admin" in the log. With
-- the schedule off it leaves the schedule untouched -- at its end the state
-- is "disabled" again, the sign back to COMING SOON. With it on, it counts as
-- a start: the next eligibility 30 minutes from it, as for any Mist.
--
-- Published as Workspace attributes (EnchantedMistConfig.Attributes), times as
-- Workspace:GetServerTimeNow() values, the state written last. Clients count
-- down locally; nothing is sent every second.
--==============================================================================
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local WorldCycleService = require(script.Parent:WaitForChild("WorldCycleService"))

local EnchantedMistService = {}
-- After WorldCycleService (70): its OnDawn must exist when this hooks it.
EnchantedMistService.Priority = 75

local CFG = EnchantedMistConfig
local ATTR = CFG.Attributes
local STATES = CFG.States
local SCHEDULE = EnchantedMistData.Schedule

local function log(message: string)
	print("[Seed/EnchantedMistService] " .. message)
end

--==============================================================================
-- SPEC-REPLACEABLE HOOKS: the clock and where the state is published.
--==============================================================================
EnchantedMistService.Hooks = {
	now = function(): number
		return Workspace:GetServerTimeNow()
	end,
	publish = function(values: { [string]: any })
		-- The deadlines first (a nil clears one), the state last.
		for _, name in ipairs({ ATTR.EligibleAt, ATTR.StartedAt, ATTR.EndsAt, ATTR.EventId }) do
			Workspace:SetAttribute(name, values[name])
		end
		Workspace:SetAttribute(ATTR.State, values[ATTR.State])
	end,
	random = function(min: number, max: number): number
		return Random.new():NextInteger(min, max)
	end,
	-- Whether the world is at Night now (an admin's Mist waits for the day).
	isNight = function(): boolean
		return Workspace:GetAttribute(GameConfig.Attributes.WorldPhase) == GameConfig.WorldCycle.PhaseNight
	end,
}

--==============================================================================
-- WHAT IS STILL MISSING (the owner's list of bindings and approvals)
--
-- The event can be switched on only when this is empty. Each line names the
-- exact thing to supply or approve.
--==============================================================================
-- Pieces of the event built in code so far (the staged build).
EnchantedMistService.Built = {
	Berries = true, -- stage 2: EnchantedMistBerryService, EnchantedMistBerries.client
	Mosskeeper = true, -- stage 3: MosskeeperService (shown once ShowMosskeeper is on)
	MysteriousPod = true, -- stage 4: MysteryPodService, MysteryRevealUI.client
	-- The night over the day (2026-10-11): MistLook, through WorldClock's light,
	-- Weather.client's wisps and fireflies and EnchantedMistBerries.client's glints.
	Look = true,
}

function EnchantedMistService.MissingBindings(): { string }
	local missing: { string } = {}
	for _, piece in ipairs({ "Berries", "Mosskeeper", "MysteriousPod", "Look" }) do
		if not EnchantedMistService.Built[piece] then
			table.insert(missing, "code: " .. piece .. " not built yet")
		end
	end
	-- The Mysterious Pod's one shell (stage 4): bound and real.
	local shell = EnchantedMistData.Shell.Id
	if type(shell) ~= "string" or SeedData.Get(shell) == nil then
		table.insert(missing, "binding: the Mysterious Pod's shell (EnchantedMistData.Shell.Id)")
	end
	for _, entry in ipairs(EnchantedMistData.Pool.Entries) do
		if SeedData.Get(entry.Id) == nil then
			table.insert(missing, "creature not registered: " .. entry.Name .. " (" .. entry.Id .. ")")
		end
	end
	if not EnchantedMistData.Pool.Approved then
		table.insert(missing, "approval: creature odds (EnchantedMistData.Pool)")
	end
	if not EnchantedMistData.Sizes.Approved then
		table.insert(missing, "approval: size odds (EnchantedMistData.Sizes)")
	end
	return missing
end

--==============================================================================
-- THE STATE
--==============================================================================
type State = {
	running: boolean,
	boot: string,
	phase: string,
	eligibleAt: number,
	startedAt: number?,
	endsAt: number?,
	eventId: string?,
	usedDawn: string?,
	events: number,
}
local st: State = {
	running = false,
	boot = "",
	phase = STATES.Disabled,
	eligibleAt = 0,
	startedAt = nil,
	endsAt = nil,
	eventId = nil,
	usedDawn = nil,
	events = 0,
}

local startListeners: { [number]: (any) -> () } = {}
local endListeners: { [number]: (any) -> () } = {}
local listenerCount = 0

local function listen(list: { [number]: (any) -> () }, fn: (any) -> ()): () -> ()
	listenerCount += 1
	local id = listenerCount
	list[id] = fn
	return function()
		list[id] = nil
	end
end

local function tell(list: { [number]: (any) -> () }, info: any)
	for _, fn in pairs(list) do
		task.spawn(function()
			local ok, err = pcall(fn, info)
			if not ok then
				warn("[Seed/EnchantedMistService] a listener failed: " .. tostring(err))
			end
		end)
	end
end

-- The berries, Mosskeeper and the look hear a start and an end here, once each.
function EnchantedMistService.OnStart(fn: (any) -> ()): () -> ()
	return listen(startListeners, fn)
end
function EnchantedMistService.OnEnd(fn: (any) -> ()): () -> ()
	return listen(endListeners, fn)
end

local function publish()
	EnchantedMistService.Hooks.publish({
		-- None while the schedule is off, an admin's Mist included.
		[ATTR.EligibleAt] = if st.phase == STATES.Disabled or not st.running then nil else st.eligibleAt,
		[ATTR.StartedAt] = if st.phase == STATES.Active then st.startedAt else nil,
		[ATTR.EndsAt] = if st.phase == STATES.Active then st.endsAt else nil,
		[ATTR.EventId] = if st.phase == STATES.Active then st.eventId else nil,
		[ATTR.State] = st.phase,
	})
end

function EnchantedMistService.State(): string
	return st.phase
end

function EnchantedMistService.IsActive(): boolean
	return st.phase == STATES.Active
end

function EnchantedMistService.EventId(): string?
	return if st.phase == STATES.Active then st.eventId else nil
end

function EnchantedMistService.EligibleAt(): number
	return st.eligibleAt
end

function EnchantedMistService.EndsAt(): number?
	return if st.phase == STATES.Active then st.endsAt else nil
end

--==============================================================================
-- START AND END -- each idempotent
--==============================================================================
local function finish(reason: string, now: number)
	if st.phase ~= STATES.Active then
		return
	end
	local id = st.eventId
	-- An admin's Mist with the schedule off goes back to off.
	st.phase = if not st.running then STATES.Disabled
		elseif now >= st.eligibleAt then STATES.Eligible
		else STATES.Cooldown
	publish()
	if st.running then
		log(string.format("MIST %s ended (%s). Next eligible in %ds.", tostring(id), reason,
			math.max(0, math.floor(st.eligibleAt - now))))
	else
		log(string.format("MIST %s ended (%s). The schedule stays off.", tostring(id), reason))
	end
	tell(endListeners, { eventId = id, reason = reason, at = now })
end

local function start(dawn: WorldCycleService.Dawn, now: number)
	st.events += 1
	st.eventId = string.format("%s-%d-%d", st.boot, dawn.cycleIndex, st.events)
	st.startedAt = now
	st.endsAt = now + SCHEDULE.ActiveSeconds
	-- Measured from the START, not the end (the owner's rule).
	st.eligibleAt = now + SCHEDULE.CooldownSeconds
	st.phase = STATES.Active
	publish()
	log(string.format("MIST %s started after dawn %d%s; ends in %ds.", st.eventId, dawn.cycleIndex,
		if dawn.short then string.format(" (degraded stock: %s of %s)", tostring(dawn.built), tostring(dawn.wanted))
			else "", SCHEDULE.ActiveSeconds))
	tell(startListeners, { eventId = st.eventId, startedAt = now, endsAt = st.endsAt, cycleIndex = dawn.cycleIndex,
		degraded = dawn.short })
end

-- A completed dawn. Starts the Mist only when this is the one it waits for.
function EnchantedMistService._onDawn(dawn: WorldCycleService.Dawn, now: number): string
	if not st.running then
		return "OFF"
	end
	if dawn.source ~= "cycle" then
		return "NOT_NATURAL"
	end
	if st.phase == STATES.Active then
		return "ALREADY_ACTIVE"
	end
	local key = st.boot .. ":" .. tostring(dawn.cycleIndex)
	if st.usedDawn == key then
		return "DUPLICATE"
	end
	if now < st.eligibleAt then
		return "NOT_ELIGIBLE"
	end
	if not dawn.barrierOpen then
		warn("[Seed/EnchantedMistService] dawn " .. dawn.cycleIndex .. " left the road shut; waiting for the next.")
		return "ROAD_SHUT"
	end
	st.usedDawn = key
	start(dawn, now)
	return "STARTED"
end

-- The clock's step: cooldown becomes eligible, an active Mist ends on time.
-- An admin's Mist ends on time with the schedule off too.
function EnchantedMistService._tick(now: number)
	if st.phase == STATES.Active then
		if st.endsAt and now >= (st.endsAt :: number) then
			finish("time", now)
		end
	elseif st.running and st.phase == STATES.Cooldown and now >= st.eligibleAt then
		st.phase = STATES.Eligible
		publish()
	end
end

-- A forced Night (the admin console, the command bar) while the Mist runs --
-- an admin's too, with the schedule off.
function EnchantedMistService._onNight(now: number)
	if st.phase == STATES.Active then
		finish("night", now)
	end
end

--==============================================================================
-- AN ADMIN'S MIST (AdminService: the console's START MIST NOW, END MIST NOW)
--==============================================================================
-- Starts a Mist at once for `by` (an admin's name, for the log), `seconds`
-- long (2026-10-12, the console's 2 / 5 / 10 MIN: one of SCHEDULE.AdminSeconds,
-- the normal ActiveSeconds without one). Returns whether it started and why
-- not: ALREADY_ACTIVE, NOT_BUILT (a binding missing), NIGHT, BAD_LENGTH. Runs
-- with the schedule off.
function EnchantedMistService.AdminStart(now: number, by: string?, seconds: number?): (boolean, string)
	local length = seconds or SCHEDULE.ActiveSeconds
	if table.find(SCHEDULE.AdminSeconds, length) == nil then
		return false, "BAD_LENGTH"
	end
	if st.phase == STATES.Active then
		return false, "ALREADY_ACTIVE"
	end
	local missing = EnchantedMistService.MissingBindings()
	if #missing > 0 then
		warn("[Seed/EnchantedMistService] an admin start refused: " .. table.concat(missing, "; "))
		return false, "NOT_BUILT"
	end
	if EnchantedMistService.Hooks.isNight() then
		return false, "NIGHT"
	end
	st.events += 1
	st.eventId = string.format("%s-admin-%d", st.boot, st.events)
	st.startedAt = now
	st.endsAt = now + length
	-- The schedule's next eligibility only while it runs: with it off, none.
	if st.running then
		st.eligibleAt = now + SCHEDULE.CooldownSeconds
	end
	st.phase = STATES.Active
	publish()
	log(string.format("MIST %s started (source admin%s)%s; ends in %ds.", st.eventId,
		if by then ", by " .. by else "", if st.running then "" else " with the schedule off", length))
	tell(startListeners, { eventId = st.eventId, startedAt = now, endsAt = st.endsAt, source = "admin",
		degraded = false })
	return true, "STARTED"
end

-- Ends the running Mist at once, the way its time running out does (reason
-- "admin"). NOT_ACTIVE when none runs.
function EnchantedMistService.AdminEnd(now: number, by: string?): (boolean, string)
	if st.phase ~= STATES.Active then
		return false, "NOT_ACTIVE"
	end
	if by then
		log("MIST " .. tostring(st.eventId) .. " ended by admin " .. by .. ".")
	end
	finish("admin", now)
	return true, "ENDED"
end

-- MAKE ELIGIBLE NOW (2026-10-12, the console): the schedule's cooldown cut
-- short, so the next completed natural reset starts a Mist -- it never starts
-- one itself, nor forces a reset. Only while the schedule runs (OFF with
-- EnchantedMistConfig.Enabled false: the console greys it out) and cools down:
-- ACTIVE while a Mist runs, ALREADY_ELIGIBLE when there is nothing to cut.
function EnchantedMistService.MakeEligible(now: number, by: string?): (boolean, string)
	if not st.running then
		return false, "OFF"
	end
	if st.phase == STATES.Active then
		return false, "ACTIVE"
	end
	if st.phase ~= STATES.Cooldown then
		return false, "ALREADY_ELIGIBLE"
	end
	st.eligibleAt = now
	st.phase = STATES.Eligible
	publish()
	log("MIST eligible now" .. (if by then " (admin " .. by .. ")" else "") .. ": the next completed reset starts one.")
	return true, "ELIGIBLE"
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local unhooks: { () -> () } = {}
local generation = 0

-- (Re)starts the schedule from scratch: a fresh boot id, the first eligibility
-- a random 10-30 minutes on, nothing active. Off with the switch off or any
-- binding missing.
function EnchantedMistService._boot(now: number)
	st.boot = string.sub(HttpService:GenerateGUID(false), 1, 8)
	st.startedAt, st.endsAt, st.eventId, st.usedDawn = nil, nil, nil, nil
	local missing = EnchantedMistService.MissingBindings()
	st.running = CFG.Enabled and #missing == 0
	if st.running then
		st.eligibleAt = now + EnchantedMistService.Hooks.random(SCHEDULE.FirstEligibleMin, SCHEDULE.FirstEligibleMax)
		st.phase = STATES.Cooldown
		log(string.format("ON. First eligible in %ds, then after the next completed reset.",
			math.floor(st.eligibleAt - now)))
	else
		st.eligibleAt = 0
		st.phase = STATES.Disabled
		log(string.format("off (%s).", if not CFG.Enabled then "EnchantedMistConfig.Enabled is false"
			else #missing .. " binding(s) missing"))
	end
	publish()
end

function EnchantedMistService.Init()
	for _, unhook in ipairs(unhooks) do
		unhook()
	end
	table.clear(unhooks)
	generation += 1
	EnchantedMistService._boot(EnchantedMistService.Hooks.now())
end

function EnchantedMistService.Start()
	local mine = generation
	table.insert(unhooks, WorldCycleService.OnDawn(function(dawn)
		if generation == mine then
			EnchantedMistService._onDawn(dawn, EnchantedMistService.Hooks.now())
		end
	end))
	local phaseName = GameConfig.Attributes.WorldPhase
	local phaseConn = Workspace:GetAttributeChangedSignal(phaseName):Connect(function()
		if generation == mine and Workspace:GetAttribute(phaseName) == GameConfig.WorldCycle.PhaseNight then
			EnchantedMistService._onNight(EnchantedMistService.Hooks.now())
		end
	end)
	table.insert(unhooks, function()
		phaseConn:Disconnect()
	end)
	-- One step a second, and only while on: the cooldown's end and the Mist's.
	task.spawn(function()
		while generation == mine do
			task.wait(1)
			if generation == mine then
				EnchantedMistService._tick(EnchantedMistService.Hooks.now())
			end
		end
	end)
end

return EnchantedMistService
