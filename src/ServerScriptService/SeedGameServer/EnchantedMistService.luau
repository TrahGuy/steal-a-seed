--!strict
--==============================================================================
-- Steal a Seed :: EnchantedMistService (2026-10-11)
--
-- THE ONE COORDINATOR for Enchanted Mist's schedule: when it is eligible, when
-- it starts, when it ends. Everything else of the event (berries, Mosskeeper,
-- the pods, the look) follows the state this publishes.
--
-- THE SCHEDULE (the owner, 2026-10-11 -- EnchantedMistData.Schedule):
--   * A new server becomes ELIGIBLE a random 20-60 minutes after it starts.
--   * Once eligible it waits for the next COMPLETED NATURAL RESET --
--     WorldCycleService.OnDawn with source "cycle": the nests stocked (a short
--     batch is reported, not waited out), Day published, the road reopened.
--     It never forces a reset, never interrupts a raid, never skips a Pod
--     Rush's hold: it only waits for the dawn the cycle makes anyway.
--   * It is ACTIVE for 300 seconds: a night LOOK, gameplay in Day, biomes open.
--   * Its next eligibility is measured from that START: 60 minutes on. With
--     the unchanged 435-second cycle that is about 65:15 between starts.
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
}

--==============================================================================
-- WHAT IS STILL MISSING (the owner's list of bindings and approvals)
--
-- The event can be switched on only when this is empty. Each line names the
-- exact thing to supply or approve.
--==============================================================================
-- Pieces of the event built in code so far (the staged build).
EnchantedMistService.Built = {
	Berries = false, -- stage 2 (EnchantedMistBerryService) in progress: client + spec to come
	Mosskeeper = false,
	MysteriousPod = false,
	Look = false,
}

function EnchantedMistService.MissingBindings(): { string }
	local missing: { string } = {}
	for _, piece in ipairs({ "Berries", "Mosskeeper", "MysteriousPod", "Look" }) do
		if not EnchantedMistService.Built[piece] then
			table.insert(missing, "code: " .. piece .. " not built yet")
		end
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
		[ATTR.EligibleAt] = if st.phase == STATES.Disabled then nil else st.eligibleAt,
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
	st.phase = if now >= st.eligibleAt then STATES.Eligible else STATES.Cooldown
	publish()
	log(string.format("MIST %s ended (%s). Next eligible in %ds.", tostring(id), reason,
		math.max(0, math.floor(st.eligibleAt - now))))
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
function EnchantedMistService._tick(now: number)
	if not st.running then
		return
	end
	if st.phase == STATES.Active then
		if st.endsAt and now >= (st.endsAt :: number) then
			finish("time", now)
		end
	elseif st.phase == STATES.Cooldown and now >= st.eligibleAt then
		st.phase = STATES.Eligible
		publish()
	end
end

-- A forced Night (the admin console, the command bar) while the Mist runs.
function EnchantedMistService._onNight(now: number)
	if st.running and st.phase == STATES.Active then
		finish("night", now)
	end
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
local unhooks: { () -> () } = {}
local generation = 0

-- (Re)starts the schedule from scratch: a fresh boot id, the first eligibility
-- a random 20-60 minutes on, nothing active. Off with the switch off or any
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
