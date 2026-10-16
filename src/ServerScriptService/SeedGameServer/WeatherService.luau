--!strict
-- Steal a Seed :: WeatherService
--
-- The Rain event (2026-10-02): an admin starts it from the console -- any of
-- the three allowlisted accounts since 2026-10-07, the owner's alone before --
-- or, since 2026-10-05, this file's own scheduler does (AUTOMATIC WEATHER, below:
-- every hour on the hour since 2026-10-16);
-- this server's garden earns a quarter more while it falls, fog closes round the
-- island, a temporary biome is uncovered off the east edge, and when the rain
-- stops everyone inside is put back at its entrance and it fades away.
--
--==============================================================================
-- ONE EVENT, ONE OWNER OF ITS STATE
--
-- There is at most one event, and this file holds it: an id, a state, and a
-- deadline. The state is explicit --
--
--   opening   the rain is falling and the bonus is paying; the terrain is
--             built with its entrance SHUT, so there is nothing to walk onto
--             before it exists
--   active    the entrance is open; everyone here at that moment is told once
--   closing   the bonus is over, the entrance is shut again, those inside have
--             been put back on the island; the fog thickens, the biome fades,
--             and the terrain is removed only after the fade AND only once
--             nobody is on it
--
-- -- and published as workspace attributes (GameConfig.Weather.Attributes), so
-- a player who joins mid-event is right on their first frame and nothing is
-- replayed at them. The opening toast goes out by remote, once, to whoever is
-- here when the entrance opens.
--
-- A second START while an event exists is refused and changes nothing: no
-- second terrain, no restart, no bonus on a bonus. A second END is harmless.
-- The admin who started it leaving changes nothing either: the deadline is the
-- server's.
--
-- THE INCOME is one factor, SeedData.Rain.IncomeFactor, answered by
-- IncomeFactor() while the rain pays and 1 otherwise. EconomyService.RateFor
-- multiplies by it once, after the pass and the temporary boosts; the Factor
-- attribute mirrors it for every display. Sales, base rates, offline earnings
-- and saved items never see it.
--
-- THE SEAMS -- the clock, the player list, the terrain, the mover and the
-- remote -- are swappable so RainEventSpec can run the whole event in Edit
-- with stand-ins; every default is the real thing.
--==============================================================================
-- TWO MODES, ONE EVENT (2026-10-02)
--
-- "rain" and "thunder" (a Thunderstorm) are the SAME event with the same one
-- income factor, biome, duration box and closing: the console's START RAIN or
-- START THUNDERSTORM picks the mode, published as the Mode attribute, and only
-- one runs at a time -- a start while either is opening, active or closing is
-- refused, never converted, never a second batch. A Thunderstorm only looks
-- heavier (Weather.client, WorldClock, RainClouds read the mode) and stocks
-- differently.
--
-- THE BATCH. When the terrain is built, NestService raises the event's nest at
-- its centre with ONE batch (SeedData.RollRainBatch: for the rain three pods
-- and one Colossal draw, 5% a Rain since 2026-10-06 -- a hit makes one slot
-- Colossal, the others ordinary; one Pod 3 for a thunderstorm),
-- guarded by Stormstrider. Nothing restocks it. When the event closes, the
-- unclaimed pods -- in the nest and on the ground -- and the guardian go with
-- it (the nest seam); a pod in somebody's arms is evacuated with them and
-- banks at the landing, and everything banked or planted is untouched.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local Notice = require(Shared:WaitForChild("Notice"))
local RainBiome = require(script.Parent:WaitForChild("RainBiome"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
-- The event's nest and guardian (2026-10-02). No cycle: NestService has never
-- heard of the weather.
local NestService = require(script.Parent:WaitForChild("NestService"))

local WeatherService = {}
-- After the faucet (55): it needs nothing of the others to start, and nothing
-- below needs it to have started -- EconomyService asks IncomeFactor, which
-- answers 1 until an event exists.
WeatherService.Priority = 65

local W = GameConfig.Weather
local ATTR = W.Attributes
local EVENTS = W.Events
local TICK = 0.25

export type Event = {
	id: number,
	-- "rain" or "thunder" (GameConfig.Weather.Modes).
	mode: string,
	-- How many pods its nest laid (the one batch).
	laid: number,
	state: string,
	startedAt: number,
	endsAt: number,
	openedAt: number?,
	closingAt: number?,
	warned: boolean,
	terrain: Instance?,
	ready: boolean,
	-- Who has been put back at the entrance this event, told once.
	evacuated: { [any]: boolean },
}

local current: Event? = nil
local nextId = 0
local generation = 0
local running = false

local function log(message: string)
	print("[Seed/WeatherService] " .. message)
end

local function nameOf(who: any): string
	local ok, name = pcall(function()
		return who.Name
	end)
	return if ok and type(name) == "string" then name else "?"
end

local function mmss(seconds: number): string
	local whole = math.max(0, math.floor(seconds + 0.5))
	return string.format("%d:%02d", whole // 60, whole % 60)
end

--==============================================================================
-- THE SEAMS
--==============================================================================
export type Terrain = {
	build: (parent: Instance) -> Instance?,
	setEntry: (terrain: Instance?, open: boolean) -> (),
	destroy: (terrain: Instance?) -> (),
}

local clock: () -> number = function()
	return Workspace:GetServerTimeNow()
end

local playersNow: () -> { any } = function()
	return Players:GetPlayers()
end

local realTerrain: Terrain = {
	build = function(parent: Instance): Instance?
		return RainBiome.Build(parent)
	end,
	setEntry = function(terrain: Instance?, open: boolean)
		if terrain then
			RainBiome.SetEntry(terrain, open)
		end
	end,
	destroy = function(terrain: Instance?)
		if terrain then
			terrain:Destroy()
		end
	end,
}
local terrainMaker: Terrain = realTerrain

-- The event's nest: `open` lays the one batch and raises the guardian (answers
-- how many pods); `close` takes down whatever is unclaimed -- the nest's pods,
-- the guardian, the event's pods lying on the ground. The real one runs only
-- in a running game: a spec in Edit raises no guardian unless it says so.
export type NestSeam = {
	open: (eventId: number, mode: string, terrain: Instance?) -> number,
	close: (eventId: number) -> number,
	-- At the opening (2026-10-05): the Secret egg toast for a special egg the
	-- batch laid (the Thunderstorm's Pod 3), once; the nest decides.
	announce: ((eventId: number) -> boolean)?,
}
local realNest: NestSeam = {
	open = function(eventId: number, mode: string, terrain: Instance?): number
		if not (terrain and RunService:IsRunning()) then
			return 0
		end
		local laid, why = NestService.OpenEventNest(eventId, mode, RainBiome.NestSite(terrain))
		if laid == 0 then
			warn("[Seed/WeatherService] the event's nest did not go up: " .. tostring(why))
		end
		return laid
	end,
	close = function(eventId: number): number
		return NestService.CloseEventNest(eventId) + CarryService.ClearEventPods(eventId)
	end,
	announce = function(eventId: number): boolean
		return NestService.AnnounceEventEgg(eventId)
	end,
}
local nestMaker: NestSeam = realNest

-- Puts a character down at a landing spot, momentum off, and tells the carry
-- guard: a carrier moved by the server keeps the pod in their arms rather than
-- being put back on terrain that is about to go.
local function moveCharacter(player: any, cf: CFrame): boolean
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not (character and root and root:IsA("BasePart")) then
		return false
	end
	local ok = pcall(function()
		character:PivotTo(cf)
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)
	if not ok then
		return false
	end
	if typeof(player) == "Instance" then
		CarryService.NoteServerMove(player :: Player, cf.Position)
	end
	return true
end
local mover: (any, CFrame) -> boolean = moveCharacter

--==============================================================================
-- LOST IN THE RAIN (2026-10-11, the owner: "A pod carried inside the rain
-- biome is LOST, not banked, if its carrier never went through the safe zone")
--
-- The evacuation puts a carrier down on the landing grass, inside the safe
-- zone, and CarryService's poll would bank the pod in their arms there -- a
-- pod home without the walk over the bridge's red line. So a carrier the
-- evacuation moves loses it, as one caught in a biome at nightfall does
-- (CarryService.ForfeitCarry): the pod in their arms only, never the Backpack
-- or the plot. Called in the same resumption as the move, with nothing that
-- yields between, so the bank poll can never run in between. A pod carried
-- over the line was banked long before the end and is never in arms here.
-- True when there was a pod to lose.
--==============================================================================
local function forfeitPod(player: any): boolean
	if typeof(player) ~= "Instance" or not player:IsA("Player") then
		return false
	end
	local species = CarryService.ForfeitCarry(player :: Player, "carried out of the rain biome by its end, "
		.. "never over the safe line")
	return species ~= nil
end
local forfeiter: (any) -> boolean = forfeitPod

--==============================================================================
-- WHO IS DOWN (2026-10-10, Michael on v1047: "In the rain biome I got hit right
-- at the timer and wasn't teleported out ... def can get ragdolled and skip the
-- teleport")
--
-- A knocked-down body -- a guardian's throw or a bat's hit, both NestService's
-- ragdoll -- is moved by its own player's computer: the ragdoll hands every
-- assembly to the victim, and ThrowFX keeps setting the body where it landed
-- until its joints are back. A server move made while it is down is undone, and
-- a body in the air over the void is not "on" the terrain for a tick, which let
-- the terrain go while it was still coming down.
--
-- So the evacuation leaves a player who is down alone -- no move, no word --
-- and moves them on the first tick they are up; and the terrain is kept while
-- anybody is still down, LimpHoldSeconds past the fade at the most. Anybody:
-- a throw can carry a body far off the terrain and the nest can set it back on
-- it, and a knock-down elsewhere only keeps a faded biome a few seconds longer.
--==============================================================================
local function isDown(player: any): boolean
	local character = player.Character
	if typeof(character) ~= "Instance" or not character:IsA("Model") then
		return false
	end
	if NestService.IsRagdolled(character) then
		return true
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.PlatformStand
end
local limp: (any) -> boolean = isDown

local function anyDown(): boolean
	for _, player in ipairs(playersNow()) do
		if limp(player) then
			return true
		end
	end
	return false
end

local function remote(): RemoteEvent?
	local seedGame = ReplicatedStorage:FindFirstChild("SeedGame")
	local remotes = if seedGame then seedGame:FindFirstChild("Remotes") else nil
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	return if found and found:IsA("RemoteEvent") then found else nil
end

-- To everyone in the server, or to `to` alone.
local function sendEvent(action: string, payload: any, to: { any }?)
	local event = remote()
	if not event then
		return
	end
	if to then
		for _, player in ipairs(to) do
			if typeof(player) == "Instance" and player:IsA("Player") then
				event:FireClient(player, action, payload)
			end
		end
	else
		event:FireAllClients(action, payload)
	end
end
local broadcast: (string, any, { any }?) -> () = sendEvent

function WeatherService.useClock(fn: (() -> number)?)
	clock = fn or function()
		return Workspace:GetServerTimeNow()
	end
end

function WeatherService.usePlayers(fn: (() -> { any })?)
	playersNow = fn or function()
		return Players:GetPlayers()
	end
end

function WeatherService.useTerrain(maker: Terrain?)
	terrainMaker = maker or realTerrain
end

function WeatherService.useMover(fn: ((any, CFrame) -> boolean)?)
	mover = fn or moveCharacter
end

-- Who is knocked down (WHO IS DOWN); a spec stands in its own.
-- What a moved carrier loses (LOST IN THE RAIN); a spec stands in its own.
function WeatherService.useForfeit(fn: ((any) -> boolean)?)
	forfeiter = fn or forfeitPod
end

function WeatherService.useLimp(fn: ((any) -> boolean)?)
	limp = fn or isDown
end

function WeatherService.useBroadcast(fn: ((string, any, { any }?) -> ())?)
	broadcast = fn or sendEvent
end

function WeatherService.useNest(seam: NestSeam?)
	nestMaker = seam or realNest
end

--==============================================================================
-- PUBLISHING
--
-- Every attribute, State last: a client that sees the state finds the rest
-- already in place. The factor is written from the same state the faucet
-- reads, in the same frame, so the chip and the payout cannot disagree.
--==============================================================================
local function publish(event: Event?)
	if not event then
		Workspace:SetAttribute(ATTR.State, nil)
		Workspace:SetAttribute(ATTR.Factor, nil)
		Workspace:SetAttribute(ATTR.EventId, nil)
		Workspace:SetAttribute(ATTR.StartedAt, nil)
		Workspace:SetAttribute(ATTR.EndsAt, nil)
		Workspace:SetAttribute(ATTR.OpenedAt, nil)
		Workspace:SetAttribute(ATTR.ClosingAt, nil)
		Workspace:SetAttribute(ATTR.Mode, nil)
		return
	end
	Workspace:SetAttribute(ATTR.Mode, event.mode)
	Workspace:SetAttribute(ATTR.EventId, event.id)
	Workspace:SetAttribute(ATTR.StartedAt, event.startedAt)
	Workspace:SetAttribute(ATTR.EndsAt, event.endsAt)
	Workspace:SetAttribute(ATTR.OpenedAt, event.openedAt)
	Workspace:SetAttribute(ATTR.ClosingAt, event.closingAt)
	Workspace:SetAttribute(ATTR.Factor, WeatherService.IncomeFactor())
	Workspace:SetAttribute(ATTR.State, event.state)
end

--==============================================================================
-- READ API
--==============================================================================
function WeatherService.IncomeFactor(): number
	local event = current
	if event and (event.state == "opening" or event.state == "active") then
		return SeedData.Rain.IncomeFactor
	end
	return 1
end

-- A copy of the event, or nil.
function WeatherService.State(): Event?
	local event = current
	if not event then
		return nil
	end
	return {
		id = event.id,
		mode = event.mode,
		laid = event.laid,
		state = event.state,
		startedAt = event.startedAt,
		endsAt = event.endsAt,
		openedAt = event.openedAt,
		closingAt = event.closingAt,
		warned = event.warned,
		terrain = event.terrain,
		ready = event.ready,
		evacuated = event.evacuated,
	}
end

function WeatherService.IsOnTerrain(position: Vector3): boolean
	return current ~= nil and RainBiome.Contains(position)
end

-- Everyone whose character stands on the event's terrain right now.
function WeatherService.Occupants(): { any }
	local list: { any } = {}
	if not current then
		return list
	end
	for _, player in ipairs(playersNow()) do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") and RainBiome.Contains(root.Position) then
			table.insert(list, player)
		end
	end
	return list
end

--==============================================================================
-- THE EVACUATION
--
-- Only those on the terrain, only to the grass before the ramp: the next clear
-- spot in the landing grid for each, so nobody lands in anything or on anyone.
-- Each is told once. Run at the close and again every tick of the closing, so
-- anyone who was still on the bridge, or who got past the gate, is put back --
-- and anyone who was down is moved the tick they stand (WHO IS DOWN).
--==============================================================================
local function evacuate(event: Event): number
	local occupants = WeatherService.Occupants()
	if #occupants == 0 then
		return 0
	end
	local moved = 0
	local slot = 0
	for _, player in ipairs(occupants) do
		if limp(player) then
			-- Down: their own computer would undo the move. Not told either: they
			-- are told when they are really moved.
			continue
		end
		local own: { Instance } = {}
		if typeof(player.Character) == "Instance" then
			table.insert(own, player.Character)
		end
		local chosen: CFrame? = nil
		for _ = 1, RainBiome.LandingCount() do
			slot += 1
			local candidate = RainBiome.LandingSpot(slot)
			if RainBiome.SpotClear(candidate, own) then
				chosen = candidate
				break
			end
		end
		if not chosen then
			-- Nowhere in the grid is clear: the next spot anyway, on the grass.
			slot += 1
			chosen = RainBiome.LandingSpot(slot)
		end
		if mover(player, chosen :: CFrame) then
			moved += 1
			-- LOST IN THE RAIN: right after the move, before anything can yield.
			if forfeiter(player) then
				local words = W.PodLost
				broadcast(Notice.ServerNotice, { title = words.Title, detail = words.Detail,
					key = "rain:podlost:" .. tostring(event.id), icon = if event.mode == "thunder" then "thunder" else "rain" },
					{ player })
			end
			if not event.evacuated[player] then
				event.evacuated[player] = true
				broadcast(EVENTS.Evacuated, event.id, { player })
			end
		end
	end
	return moved
end

--==============================================================================
-- THE TRANSITIONS
--==============================================================================
local function close(event: Event, now: number, why: string)
	event.state = "closing"
	event.closingAt = now
	-- Shut first, then publish: the bonus is over and nobody new gets in before
	-- anyone is moved.
	pcall(terrainMaker.setEntry, event.terrain, false)
	publish(event)
	local moved = evacuate(event)
	-- Then the unclaimed: the nest's pods, the guardian, the event's pods on
	-- the ground. Those in the arms of the carriers just moved were lost with
	-- the move (LOST IN THE RAIN).
	local okNest, gone = pcall(nestMaker.close, event.id)
	log(string.format("%s ending (%s, event %d): the bonus is off, the entrance is shut, %d put back at it, "
		.. "%s unclaimed pod(s) and the guardian gone; the biome fades over %d s.", W.Modes[event.mode].Name, why,
		event.id, moved, if okNest then tostring(gone) else "?", W.ThickenSeconds + W.FadeSeconds))
end

local function finish(event: Event)
	-- Again, for anything dropped during the closing (a carrier who fell).
	pcall(nestMaker.close, event.id)
	local ok, err = pcall(terrainMaker.destroy, event.terrain)
	if not ok then
		warn("[Seed/WeatherService] could not remove the rain biome: " .. tostring(err))
	end
	event.terrain = nil
	current = nil
	publish(nil)
	log(string.format("%s over (event %d): the biome is gone.", W.Modes[event.mode].Name, event.id))
end

-- Marks the current event's terrain ready to open. The real build is ready as
-- it returns; a stand-in may become ready later.
function WeatherService.TerrainReady()
	local event = current
	if event then
		event.ready = true
	end
end

--==============================================================================
-- ONE STEP OF THE EVENT
--
-- Public and pure in `now`, so the spec can walk an event through every state
-- on its own clock; the loop below calls it on the server's.
--==============================================================================
function WeatherService.Step(now: number)
	local event = current
	if not event then
		return
	end
	if event.state == "opening" then
		-- The announcement waits for the delay AND for the terrain: never an
		-- entrance that is not there.
		if event.ready and now >= event.startedAt + W.ToastDelaySeconds then
			event.state = "active"
			event.openedAt = now
			pcall(terrainMaker.setEntry, event.terrain, true)
			publish(event)
			broadcast(EVENTS.Opened, event.id, nil)
			-- Then its special egg's toast, after the opening's (2026-10-05): the
			-- same moment for the console's storm and an automatic one.
			local announce = nestMaker.announce
			if announce then
				pcall(announce, event.id)
			end
			log(string.format("The rain biome is open (%s, event %d), %s left.", event.mode, event.id,
				mmss(event.endsAt - now)))
		end
	end
	if event.state == "opening" or event.state == "active" then
		if not event.warned and now >= event.endsAt - W.WarnSeconds then
			event.warned = true
			local inside = WeatherService.Occupants()
			if #inside > 0 then
				broadcast(EVENTS.Warning, math.ceil(event.endsAt - now), inside)
			end
		end
		if now >= event.endsAt then
			close(event, now, "the timer")
		end
		return
	end
	if event.state == "closing" then
		-- Anyone still on the terrain is put back; the terrain goes only on a
		-- step that found it empty AND moved nobody -- a straggler put back this
		-- step keeps it one more tick, so they are off it before it is gone --
		-- and nobody is still down (WHO IS DOWN), LimpHoldSeconds at the most.
		local moved = evacuate(event)
		local closingAt = event.closingAt or now
		local faded = closingAt + W.ThickenSeconds + W.FadeSeconds
		local held = now < faded + W.LimpHoldSeconds and anyDown()
		if moved == 0 and now >= faded and not held and #WeatherService.Occupants() == 0 then
			finish(event)
		end
	end
end

--==============================================================================
-- START AND END
--
-- Reached from AdminService, after ITS checks: the allowlist -- any of its
-- accounts since 2026-10-07, the owner's alone before -- and the one-a-second
-- limit; and StartWeather from
-- this file's own scheduler (AutoStep), which no client can reach. What is
-- checked here is the event's own rule, whoever asks: one at a time.
--==============================================================================
function WeatherService.StartWeather(by: any, seconds: any, mode: any): (boolean, string)
	if type(mode) ~= "string" or not W.Modes[mode] then
		return false, "Unknown weather. Nothing changed."
	end
	if type(seconds) ~= "number" or seconds ~= seconds or seconds ~= math.floor(seconds)
		or seconds < W.MinSeconds or seconds > W.MaxSeconds then
		return false, string.format("Duration must be a whole number of seconds from %d to %d. Nothing changed.",
			W.MinSeconds, W.MaxSeconds)
	end
	local now = clock()
	local existing = current
	if existing then
		-- ONE AT A TIME, WHICHEVER IT IS: never converted, never a second batch.
		local name = W.Modes[existing.mode].Name
		if existing.state == "closing" then
			return false, string.format("The %s is still clearing. Wait for the biome to fade, then start it again.",
				string.lower(name))
		end
		return false, string.format("%s (%s left). Nothing changed.",
			if existing.mode == "thunder" then "A thunderstorm is already raging" else "Rain is already falling",
			mmss(existing.endsAt - now))
	end
	nextId += 1
	local event: Event = {
		id = nextId,
		mode = mode,
		laid = 0,
		state = "opening",
		startedAt = now,
		endsAt = now + seconds,
		openedAt = nil,
		closingAt = nil,
		warned = false,
		terrain = nil,
		ready = false,
		evacuated = setmetatable({}, { __mode = "k" }) :: any,
	}
	current = event
	-- The terrain first, with its entrance shut: the surfaces exist before
	-- anything can be announced or walked on. A build that fails leaves the
	-- rain and the bonus running and the entrance shut for good.
	local ok, built = pcall(terrainMaker.build, Workspace)
	if ok then
		event.terrain = built
		event.ready = built ~= nil
	else
		warn("[Seed/WeatherService] the rain biome did not build: " .. tostring(built))
	end
	-- Shut, in so many words, whatever the builder did: entry opens only from
	-- Step, after the delay.
	pcall(terrainMaker.setEntry, event.terrain, false)
	-- The one batch, inside the shut biome, before anybody can walk in.
	local okNest, laid = pcall(nestMaker.open, event.id, mode, event.terrain)
	event.laid = if okNest and type(laid) == "number" then laid else 0
	if not okNest then
		warn("[Seed/WeatherService] the event's nest failed: " .. tostring(laid))
	end
	publish(event)
	local name = W.Modes[mode].Name
	log(string.format("%s started by %s for %s (event %d), %d pod(s) laid%s.", name, nameOf(by), mmss(seconds),
		event.id, event.laid, if event.ready then "" else " -- NO BIOME; the entrance stays shut"))
	return true, string.format("%s started for %s. The biome opens in about %d s; the +%d%% is on now.",
		name, mmss(seconds), W.ToastDelaySeconds, math.round((SeedData.Rain.IncomeFactor - 1) * 100))
end

function WeatherService.StartRain(by: any, seconds: any): (boolean, string)
	return WeatherService.StartWeather(by, seconds, "rain")
end

function WeatherService.StartThunderstorm(by: any, seconds: any): (boolean, string)
	return WeatherService.StartWeather(by, seconds, "thunder")
end

-- The third answer: whether this call ended anything (for the record).
-- Ends whichever is running, rain or thunderstorm.
function WeatherService.EndRain(by: any): (boolean, string, boolean)
	local event = current
	if not event then
		return true, "No rain or thunderstorm is running. Nothing changed.", false
	end
	local name = W.Modes[event.mode].Name
	if event.state == "closing" then
		return true, string.format("The %s is already ending and the biome is fading. Nothing more to do.",
			string.lower(name)), false
	end
	close(event, clock(), "ended by " .. nameOf(by))
	return true, string.format("%s ended. Anyone inside is back at the entrance; the biome is fading.", name), true
end

--==============================================================================
-- AUTOMATIC WEATHER, ON THE HOUR (2026-10-16, the owner; GameConfig.Weather
-- .Auto says why). It replaced the 2026-10-05 draws, which no sign could count
-- down to.
--
-- A scheduler, not a second event: state here, advanced by AutoStep from the
-- SAME loop that steps the event (so a re-run, a Stop or an Init can never
-- leave two of them), and it starts weather through StartWeather -- the
-- console's own path, with its one-at-a-time rule, terrain, nest, toasts,
-- attributes, icons, bonus and cleanup. Nothing a client can send reaches it,
-- and it is no admin: its starts are logged as "automatic weather".
--
--   THE MARKS: OffsetSeconds + k * PeriodSeconds of the server clock -- every
--   hour on the hour, the same moment on every server.
--   ONE START PER MARK, inside its WINDOW (the mark to the mark +
--   DurationSeconds): at the mark when it can; later, for what is left of the
--   window, when the weather was busy (the console's, a summon), nobody was
--   here, or the server had only just started -- so it ends with every other
--   server's. With under Weather.MinSeconds left the mark is MISSED (logged)
--   and the next one is next. A server's first step takes the latest mark as
--   it finds it -- inside its window or past it, never a catch-up for an hour
--   it was not up for -- and so does a step after a loop held up past a whole
--   mark.
--   THE MODE comes from ModeWeights with a draw SEEDED BY THE MARK: every
--   server picks the same weather for the same hour.
--   THE NEXT MARK is published (Auto.NextAtAttribute) for the RAIN BIOME
--   sign's countdown: the mark still due while its window waits, the one after
--   once it has had its start; gone while the scheduler is off.
--   A START THAT FAILS uses its mark all the same: one warning, no retry spam.
--   A start whose biome does not build is not a failure: the existing event
--   runs and cleans up as it always has.
--
-- The draw, the settings and the clock are seams (useRandom, useAutoConfig,
-- useClock) so AutoWeatherSpec can walk days of marks on its own clock.
--==============================================================================
export type AutoConfig = {
	Enabled: boolean,
	PeriodSeconds: number,
	OffsetSeconds: number,
	ModeWeights: { [string]: number },
	DurationSeconds: number,
}

-- What a start by the scheduler is logged as: a name, not a player or an admin.
local AUTOMATIC = { Name = "automatic weather" }
-- Where the next mark is published, for the sign.
local NEXT_AT: string = W.Auto.NextAtAttribute

-- The mode draw for a mark, in [0, 1): the same number on every server.
local function seeded(mark: number): number
	return Random.new(mark):NextNumber()
end
local draw: (number) -> number = seeded
local autoConfig: AutoConfig = W.Auto :: any

-- The last mark that had its one start (or was missed), what the sign was
-- told, and what the marks did.
local auto = {
	usedMark = nil :: number?,
	nextAt = nil :: number?,
	starts = 0,
	missed = 0,
	failures = 0,
	lastFailure = nil :: string?,
}

local function finiteNumber(v: any): boolean
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

-- A mark as the log says it: its UTC hour and minute (os.date's "!*t", the
-- only kind Roblox has).
local function stamp(mark: number): string
	local t = os.date("!*t", math.floor(mark))
	return string.format("%02d:%02d UTC", t.hour, t.min)
end

-- Whether `cfg` is usable, and why not. Pure.
function WeatherService.ValidateAuto(cfg: any): (boolean, string)
	if type(cfg) ~= "table" then
		return false, "no settings"
	end
	if type(cfg.Enabled) ~= "boolean" then
		return false, "Enabled must be true or false"
	end
	local period = cfg.PeriodSeconds
	if not finiteNumber(period) or period <= 0 then
		return false, "PeriodSeconds must be a positive number"
	end
	local offset = cfg.OffsetSeconds
	if not finiteNumber(offset) or offset < 0 or offset >= period then
		return false, "OffsetSeconds must be from 0 to under PeriodSeconds"
	end
	if type(cfg.ModeWeights) ~= "table" then
		return false, "ModeWeights must be a table"
	end
	local total = 0
	for mode, weight in pairs(cfg.ModeWeights) do
		if type(mode) ~= "string" or not W.Modes[mode] then
			return false, "ModeWeights names an unknown weather: " .. tostring(mode)
		end
		if not finiteNumber(weight) or weight < 0 then
			return false, "every ModeWeights weight must be a number of 0 or more"
		end
		total += weight
	end
	if total <= 0 then
		return false, "ModeWeights must give some weather a weight"
	end
	local d = cfg.DurationSeconds
	if not finiteNumber(d) or d ~= math.floor(d) or d < W.MinSeconds or d > W.MaxSeconds then
		return false, string.format("DurationSeconds must be a whole number from %d to %d", W.MinSeconds, W.MaxSeconds)
	end
	if d >= period then
		return false, "DurationSeconds must be shorter than PeriodSeconds"
	end
	return true, "ok"
end

local autoValid, autoWhy = WeatherService.ValidateAuto(autoConfig)

-- What the sign counts down to: written only when it changes.
local function publishNext(at: number?)
	if auto.nextAt ~= at then
		auto.nextAt = at
		Workspace:SetAttribute(NEXT_AT, at)
	end
end

-- Forgets the marks and takes the countdown down: Init, Start, Stop, and a
-- scheduler switched off.
local function resetWindow()
	auto.usedMark = nil
	auto.nextAt = nil
	if Workspace:GetAttribute(NEXT_AT) ~= nil then
		Workspace:SetAttribute(NEXT_AT, nil)
	end
end

-- The mode draw for a mark; a spec stands in its own.
function WeatherService.useRandom(fn: ((number) -> number)?)
	draw = fn or seeded
end

function WeatherService.useAutoConfig(cfg: AutoConfig?)
	autoConfig = cfg or (W.Auto :: any)
	autoValid, autoWhy = WeatherService.ValidateAuto(autoConfig)
	resetWindow()
	auto.starts, auto.missed, auto.failures, auto.lastFailure = 0, 0, 0, nil
end

-- A copy of the scheduler's state, for the spec and the command bar.
function WeatherService.AutoState(): { [string]: any }
	return {
		enabled = autoValid and autoConfig.Enabled == true,
		valid = autoValid,
		why = autoWhy,
		usedMark = auto.usedMark,
		nextAt = auto.nextAt,
		starts = auto.starts,
		missed = auto.missed,
		failures = auto.failures,
		lastFailure = auto.lastFailure,
	}
end

-- The latest mark at or before `now`. Pure.
function WeatherService.MarkAt(now: number, cfg: AutoConfig?): number
	local c = cfg or autoConfig
	local period, offset = c.PeriodSeconds, c.OffsetSeconds
	return offset + math.floor((now - offset) / period) * period
end

-- The mode for a draw in [0, 1): the weights in a fixed order, so one draw is
-- always the same mode.
function WeatherService.PickMode(r: number, weights: { [string]: number }?): string
	local w = weights or autoConfig.ModeWeights
	local modes: { string } = {}
	local total = 0
	for mode, weight in pairs(w) do
		if W.Modes[mode] and weight > 0 then
			table.insert(modes, mode)
			total += weight
		end
	end
	table.sort(modes)
	local at = r * total
	local acc = 0
	for _, mode in ipairs(modes) do
		acc += w[mode]
		if at < acc then
			return mode
		end
	end
	return modes[#modes]
end

-- One step of the scheduler at `now`. Answers what it did: nil (nothing),
-- "started:<mode>", "missed" or "failed".
function WeatherService.AutoStep(now: number): string?
	local cfg = autoConfig
	if not (autoValid and cfg.Enabled) then
		resetWindow()
		return nil
	end
	local period = cfg.PeriodSeconds
	local mark = WeatherService.MarkAt(now, cfg)
	local first = auto.usedMark == nil
	if first or (auto.usedMark :: number) < mark - period then
		-- The first step, or a loop held up past a whole mark: the marks before
		-- this one are gone, never caught up; this one is due while its window is.
		auto.usedMark = mark - period
	end
	if (auto.usedMark :: number) >= mark then
		publishNext(mark + period)
		return nil
	end
	-- This mark is due: what is left of its window, in whole seconds.
	local left = math.floor(mark + cfg.DurationSeconds - now + 0.5)
	if left < W.MinSeconds then
		auto.usedMark = mark
		publishNext(mark + period)
		if first then
			-- A server that came up after this mark's window: nothing was missed.
			return nil
		end
		auto.missed += 1
		log(string.format("Automatic weather: the %s mark was missed (%s); the next is in %s.", stamp(mark),
			if current ~= nil then "weather was still running" else "nobody was here", mmss(mark + period - now)))
		return "missed"
	end
	publishNext(mark)
	if current ~= nil or #playersNow() == 0 then
		-- Weather in any state, or nobody here: it waits inside its window.
		return nil
	end
	auto.usedMark = mark
	publishNext(mark + period)
	local mode = WeatherService.PickMode(draw(mark), cfg.ModeWeights)
	local seconds = math.min(left, cfg.DurationSeconds)
	local ok, started, message = pcall(WeatherService.StartWeather, AUTOMATIC, seconds, mode)
	if ok and started then
		auto.starts += 1
		log(string.format("Automatic weather: %s for %s, the %s mark%s.", W.Modes[mode].Name, mmss(seconds), stamp(mark),
			if now - mark >= 1
				then string.format(" (%s late; it ends with every other server's)", mmss(now - mark))
				else ""))
		return "started:" .. mode
	end
	auto.failures += 1
	auto.lastFailure = tostring(if ok then message else started)
	warn(string.format("[Seed/WeatherService] automatic %s for the %s mark did not start (%s); the next mark is in %s.",
		string.lower(W.Modes[mode].Name), stamp(mark), auto.lastFailure, mmss(mark + period - now)))
	return "failed"
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function WeatherService.Init()
	-- A re-run in one Studio: nothing of a previous session's event survives.
	local stale = Workspace:FindFirstChild(W.Biome.FolderName)
	if stale then
		stale:Destroy()
	end
	pcall(NestService.CloseEventNest, nil)
	current = nil
	publish(nil)
	-- Nor any of its scheduler's window.
	resetWindow()
end

function WeatherService.Start()
	generation += 1
	local mine = generation
	running = true
	resetWindow()
	if not autoValid then
		warn("[Seed/WeatherService] automatic weather is OFF: GameConfig.Weather.Auto is not usable -- " .. autoWhy)
	end
	-- ONE loop for the event and its scheduler: a new generation retires the
	-- old one, so a re-run never runs two.
	task.spawn(function()
		local warnedAt = -math.huge
		while running and mine == generation do
			local now = clock()
			local ok, err = pcall(WeatherService.Step, now)
			if not ok then
				warn("[Seed/WeatherService] step failed: " .. tostring(err))
			end
			local okAuto, errAuto = pcall(WeatherService.AutoStep, now)
			if not okAuto and os.clock() - warnedAt >= 60 then
				warnedAt = os.clock()
				warn("[Seed/WeatherService] automatic weather step failed: " .. tostring(errAuto))
			end
			task.wait(TICK)
		end
	end)
	local A = autoConfig
	log(string.format("Ready. Rain is any admin's to start, %d to %d s, %d s by default; +%d%% online plant income "
		.. "while it falls; the biome opens %d s in and fades %d s after the end. Automatic weather %s.",
		W.MinSeconds, W.MaxSeconds, W.DefaultSeconds, math.round((SeedData.Rain.IncomeFactor - 1) * 100),
		W.ToastDelaySeconds, W.ThickenSeconds + W.FadeSeconds,
		if autoValid and A.Enabled
			then string.format("ON: every %s of the server clock from %s past (every hour on the hour), the same moment "
				.. "and the same weather on every server, %s each", mmss(A.PeriodSeconds), mmss(A.OffsetSeconds),
				mmss(A.DurationSeconds))
			else "OFF"))
end

function WeatherService.Stop()
	running = false
	generation += 1
	resetWindow()
end

return WeatherService
