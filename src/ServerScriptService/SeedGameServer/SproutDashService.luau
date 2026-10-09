--!strict
--==============================================================================
-- Steal a Seed :: SproutDashService (2026-10-08)
--
-- The mill's minigame, counted (GameConfig.SproutDash, Shared/SproutDash). The
-- owner: "when player rides the mill, a play minigame button appears, then when
-- opened, a screen of the game will open, so it will not affect the jump".
--
-- THE CLIENT IS NEVER BELIEVED.
--   start    a player riding their OWN mill (not the Disco Mill), at most every
--            StartEvery s, gets a run: an id and a seed from this server's own
--            random. One run at a time; a new start drops the old one.
--   off      getting off the mill mid-run -- a jump, a death, a teleport --
--            breaks the run and tells the client, which closes its screen.
--   finish   the client sends the run's id, the ticks it hopped on and the tick
--            it stopped at; nothing else is read. The run must still be ridden
--            on the own mill, its sim time must fit in the wall clock since the
--            start (SproutDash.timely), and the server REPLAYS it from the seed
--            and those hops (SproutDash.replay): an impossible list -- a hop in
--            the air, out of order, too long -- is refused and pays nothing.
--   reward   what the replay ran earns its minutes of +25% training
--            (SproutDash.minutesFor), capped at BankMax banked and HourMax an
--            hour (SproutDash.grant), saved with the profile; TreadmillService
--            adds it to the chest's boost while it runs.
--==============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local SproutDash = require(Shared:WaitForChild("SproutDash"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local TreadmillService = require(script.Parent:WaitForChild("TreadmillService"))

local CFG = GameConfig.SproutDash
local ATTR = GameConfig.Attributes

local SproutDashService = { Priority = 61 }

type Run = { id: number, seed: number, startedAt: number, broken: boolean }

local runs: { [Player]: Run } = {}
local lastStart: { [Player]: number } = {}
local nextRunId = 0
local rng = Random.new()
local connections: { RBXScriptConnection } = {}
local watching: { [Player]: RBXScriptConnection } = {}
local channel: RemoteEvent? = nil

local function log(message: string)
	print("[Seed/SproutDashService] " .. message)
end

-- What a spec stands in: the clocks, the reply, and "riding their own mill".
SproutDashService.Hooks = {
	clock = os.clock,
	now = os.time,
	onOwnMill = function(player: Player): boolean
		return TreadmillService.OnOwnMill(player)
	end,
	reply = function(player: Player, payload: { [string]: any })
		local remote = channel
		if remote and player.Parent == Players then
			remote:FireClient(player, CFG.Action, payload)
		end
	end,
}

local function reply(player: Player, payload: { [string]: any })
	SproutDashService.Hooks.reply(player, payload)
end

local function refuse(player: Player, verb: string, why: string)
	reply(player, { verb = verb, ok = false, why = why })
end

--==============================================================================
-- START
--==============================================================================
function SproutDashService.Begin(player: Player): boolean
	if not CFG.Enabled then
		refuse(player, "started", "DISABLED")
		return false
	end
	if not PlayerDataService.IsReady(player) then
		refuse(player, "started", "NOT_READY")
		return false
	end
	local now = SproutDashService.Hooks.clock()
	local last = lastStart[player]
	if last and now - last < CFG.StartEvery then
		refuse(player, "started", "TOO_SOON")
		return false
	end
	if not SproutDashService.Hooks.onOwnMill(player) then
		refuse(player, "started", "NOT_ON_MILL")
		return false
	end
	lastStart[player] = now
	nextRunId += 1
	local run: Run = { id = nextRunId, seed = rng:NextInteger(1, 2147483646), startedAt = now, broken = false }
	runs[player] = run
	reply(player, { verb = "started", ok = true, id = run.id, seed = run.seed })
	return true
end

--==============================================================================
-- OFF THE MILL MID-RUN: the run is over and counts nothing
--==============================================================================
function SproutDashService.Break(player: Player, why: string)
	local run = runs[player]
	if run and not run.broken then
		run.broken = true
		reply(player, { verb = "ended", ok = false, id = run.id, why = why })
	end
end

local function watch(player: Player)
	if watching[player] then
		return
	end
	watching[player] = player:GetAttributeChangedSignal(ATTR.MillMounted):Connect(function()
		if player:GetAttribute(ATTR.MillMounted) ~= true then
			SproutDashService.Break(player, "OFF_MILL")
		end
	end)
end

--==============================================================================
-- FINISH: replayed here, paid from what the replay ran
--==============================================================================
function SproutDashService.Finish(player: Player, payload: any): boolean
	local run = runs[player]
	if not run or type(payload) ~= "table" or payload.id ~= run.id then
		refuse(player, "counted", "NO_RUN")
		return false
	end
	runs[player] = nil
	if run.broken or not SproutDashService.Hooks.onOwnMill(player) then
		refuse(player, "counted", "OFF_MILL")
		return false
	end
	local endTick = payload.ticks
	if type(endTick) ~= "number" or not SproutDash.timely(endTick, SproutDashService.Hooks.clock() - run.startedAt) then
		log(string.format("%s's run %d claims more sim time than the clock allowed: refused.", player.Name, run.id))
		refuse(player, "counted", "TOO_FAST")
		return false
	end
	local result = SproutDash.replay(run.seed, payload.hops, endTick)
	if not result.ok then
		log(string.format("%s's run %d did not replay (%s): refused, nothing paid.", player.Name, run.id,
			tostring(result.why)))
		refuse(player, "counted", result.why or "REFUSED")
		return false
	end
	local minutes = SproutDash.minutesFor(result.distance)
	local granted, cut, best, endsAt = 0, nil :: string?, result.distance, 0
	local now = SproutDashService.Hooks.now()
	PlayerDataService.UpdateSprout(player, function(profile: any): boolean
		local seconds, ends, earned, why = SproutDash.grant(minutes, profile.SproutBoostEndsAt or 0,
			profile.SproutEarned or {}, now)
		granted, cut, endsAt = seconds, why, ends
		profile.SproutBoostEndsAt = ends
		profile.SproutEarned = earned
		local day = SproutDash.day(now)
		if profile.SproutBestDay ~= day then
			profile.SproutBestDay = day
			profile.SproutBest = 0
		end
		profile.SproutBest = math.max(profile.SproutBest or 0, result.distance)
		best = profile.SproutBest
		return true
	end)
	if granted > 0 then
		task.spawn(PlayerDataService.Save, player)
	end
	log(string.format("%s ran %d m (%d coins, %d hits): %d boost s of %d min%s.", player.Name, result.distance,
		result.coins, result.hits, granted, minutes, if cut then " (" .. cut .. " cap)" else ""))
	reply(player, {
		verb = "counted",
		ok = true,
		id = run.id,
		distance = result.distance,
		coins = result.coins,
		hits = result.hits,
		minutes = minutes,
		granted = granted,
		cut = cut,
		best = best,
		endsAt = endsAt,
	})
	return true
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function SproutDashService.Init()
	for _, c in ipairs(connections) do
		c:Disconnect()
	end
	table.clear(connections)
	for _, c in pairs(watching) do
		c:Disconnect()
	end
	table.clear(watching)
	table.clear(runs)
	table.clear(lastStart)
	channel = nil
end

function SproutDashService.Start()
	if channel then
		return
	end
	local folder = Shared.Parent:FindFirstChild("Remotes")
	local remote = folder and folder:FindFirstChild(GameConfig.Remotes.GameEvent)
	if not remote or not remote:IsA("RemoteEvent") then
		warn("[Seed/SproutDashService] no GameEvent remote: the minigame is off.")
		return
	end
	channel = remote
	table.insert(connections, remote.OnServerEvent:Connect(function(player: Player, action: any, verb: any, payload: any)
		if action ~= CFG.Action then
			return
		end
		if verb == "start" then
			SproutDashService.Begin(player)
		elseif verb == "finish" then
			SproutDashService.Finish(player, payload)
		end
	end))
	for _, player in ipairs(Players:GetPlayers()) do
		watch(player)
	end
	table.insert(connections, Players.PlayerAdded:Connect(watch))
	table.insert(connections, Players.PlayerRemoving:Connect(function(player: Player)
		runs[player] = nil
		lastStart[player] = nil
		local c = watching[player]
		if c then
			c:Disconnect()
			watching[player] = nil
		end
	end))
	log(string.format("Ready. Runs on the own mill; %d m earns a %.0f%% training boost; %d s banked, %d s an hour at most.",
		SproutDash.firstTier(), (CFG.Boost.Multiplier - 1) * 100, CFG.Boost.BankMax, CFG.Boost.HourMax))
end

return SproutDashService
