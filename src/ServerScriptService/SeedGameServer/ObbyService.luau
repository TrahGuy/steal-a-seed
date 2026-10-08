--!strict
--==============================================================================
-- Steal a Seed :: ObbyService
--
-- Runs the Floating Garden (2026-09-27): who may start, where each runner is,
-- whether a finish is real, and the one reward a real finish pays. ObbyCourse
-- builds the islands; ObbyUI moves the platforms and draws the run.
--
--==============================================================================
-- A RUN, START TO END, ALL OF IT DECIDED HERE
--
--   1. START. The entrance's prompt, or the pavilion's Replay. Refused while
--      chased or waking a guardian, carrying a raided pod, trapped, knocked
--      down or dead -- each with the line that says what to do about it.
--      The reward basis is SNAPSHOT now: TreadmillService.RateOf, the belt's
--      1x rate for this player's mill tier and rebirth. The Bonus
--      Chest's training boost is never in it -- only the belt's own tick
--      applies that -- and an upgrade bought mid-run changes nothing.
--   2. ON THE COURSE. The Course attribute fixes the walk speed (CarryService)
--      and spares the runner every swing and trap (CombatService); the jump
--      height is fixed here. Tools go back in the Backpack, untouched, so the
--      inventory and every hotbar assignment are exactly as they were.
--   3. EVERY TENTH OF A SECOND. Gates in order, the two checkpoints, falls,
--      and a body that moved further than anything on the course can throw it.
--      A fall is a teleport back to the last checkpoint -- never a death, so
--      nothing held is lost.
--   4. THE FINISH. Inside the pavilion, after g5 or after both twilight
--      stages, no sooner than MinRunSeconds, and never flagged. PAID ONCE: the
--      run is marked paid before the single PayReward, so nothing -- a second
--      tick, a duplicate prompt, a Replay -- can pay it twice.
--   5. OUT. Return, the Exit button, death, leaving, or this service rerunning.
--      Every way out ends in `release`: attributes off, jump height back to
--      StarterPlayer's, walk speed recomputed from the profile. Return and Exit
--      carry the player home first, still protected until they land.
--
-- The reward is Speed, through PayReward -- the one Speed faucet -- so it is
-- saved exactly like belt Speed: with the profile, on SaveService's schedule
-- and when the player leaves. Nothing here keeps a second copy of it.
--==============================================================================

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local SeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local Shared = SeedGame:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local PlayerDataService = require(script.Parent:WaitForChild("PlayerDataService"))
local PlotService = require(script.Parent:WaitForChild("PlotService"))
local CarryService = require(script.Parent:WaitForChild("CarryService"))
local TreadmillService = require(script.Parent:WaitForChild("TreadmillService"))
local WheelService = require(script.Parent:WaitForChild("WheelService"))
local Metrics = require(script.Parent:WaitForChild("Metrics"))
local ObbyCourse = require(script.Parent:WaitForChild("ObbyCourse"))

local ATTR = GameConfig.Attributes
local OA = ObbyData.Attributes
local VALID = ObbyData.Validation

local ObbyService = {}
-- After TreadmillService (60), whose rate it snapshots and whose faucet pays,
-- and CombatService (70), which reads the attribute this sets.
ObbyService.Priority = 72

local TICK_SECONDS = 0.1
local PREVIEW_SECONDS = 2
-- Faster than anything on the course can carry a body: a spring cap's throw
-- peaks near 100 studs/s, a walk is 24, a drifting pad 13. A tick that moved
-- further than this, plus slack for a replication hiccup, was a teleport.
local MAX_STUDS_PER_SECOND = 140
local MOVE_SLACK = 24
-- How far from the arch a start may be asked from (the prompt reaches 12).
local START_REACH = ObbyData.Entrance.PromptDistance + 10
-- How many main-route gates are behind a runner put back at each respawn.
local RESUME_AT: { [string]: number } = {
	start = 0,
	cp1 = 2,
	cp2 = 4,
	finished = #ObbyData.MainGates,
}

--==============================================================================
-- THE GATES, IN WORLD SPACE
--==============================================================================
type Gate = { id: string, at: Vector3, radius: number }

local gates: { [string]: Gate } = {}
-- The main route's stages in order: MAIN_STAGES[n + 1] is the stage being run
-- with n main gates behind you.
local MAIN_STAGES: { string } = {}
for _, stage in ipairs(ObbyData.Stages) do
	gates[stage.gate.id] = { id = stage.gate.id, at = ObbyData.world(stage.gate.at), radius = stage.gate.radius }
	if stage.route == "main" then
		table.insert(MAIN_STAGES, stage.id)
	end
end

-- Standing in it: within the radius (and the slack) across, and on it rather
-- than falling past it -- the root rides about three studs over the floor.
local function inside(gate: Gate, pos: Vector3): boolean
	local across = Vector3.new(pos.X - gate.at.X, 0, pos.Z - gate.at.Z).Magnitude
	local up = pos.Y - gate.at.Y
	return across <= gate.radius + VALID.GateSlack and up >= -1 and up <= 12
end

--==============================================================================
-- STATE
--==============================================================================
type Run = {
	-- "running", "finished" (waiting on the summit) or "leaving".
	phase: string,
	-- clock() when the runner landed on the start island.
	startedAt: number,
	-- The reward basis, snapshot at the start.
	basis: number,
	-- Main-route gates passed, in order.
	main: number,
	-- 0, 1 after challenge stage A, 2 after both.
	challenge: number,
	-- Where a fall puts you back: a key of ObbyData.Respawns.
	respawn: string,
	falls: number,
	lastPos: Vector3?,
	lastAt: number,
	-- Why this run can no longer pay, or nil.
	flagged: string?,
	paid: boolean,
	-- A server teleport is in flight: no gates, no falls, no speed check.
	moving: boolean,
	stage: string,
	route: string,
	-- This run's own id: what the reward wheel remembers so a completion can
	-- never be credited twice (WheelService.AwardCompletion).
	id: string,
}

local runs: { [Player]: Run } = {}
local readyAt: { [Player]: number } = {}
local bodyConnections: { [Player]: { RBXScriptConnection } } = {}
local serviceConnections: { RBXScriptConnection } = {}
local channel: RemoteEvent? = nil
local running = false
local generation = 0

local function log(message: string)
	print("[Seed/ObbyService] " .. message)
end

-- The clock every run is timed by, and whether Start drives the tick itself.
-- Both are seams for ObbySpec, which steps time and ticks by hand; in the game
-- they are os.clock and the 10 Hz loop, and nothing else sets them.
local clockFn: () -> number = os.clock
local function clock(): number
	return clockFn()
end
ObbyService.ManualTick = false

local function bodyOf(player: Player): (Model?, Humanoid?, BasePart?)
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if character and character.Parent and humanoid and humanoid.Health > 0 and root and root:IsA("BasePart") then
		return character, humanoid, root
	end
	return nil, nil, nil
end

local function put(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

-- nil puts back StarterPlayer's own value, which is what every character in
-- this game spawns with -- nothing else writes a jump.
local function setJump(humanoid: Humanoid, height: number?)
	if humanoid.UseJumpPower then
		humanoid.JumpPower = if height then math.sqrt(2 * Workspace.Gravity * height)
			else StarterPlayer.CharacterJumpPower
	else
		humanoid.JumpHeight = height or StarterPlayer.CharacterJumpHeight
	end
end

local function respawnFrame(key: string): CFrame
	local spot = ObbyData.Respawns[key] or ObbyData.Respawns.start
	return CFrame.new(ObbyData.world(spot.at) + Vector3.new(0, 3.5, 0)) * CFrame.Angles(0, math.rad(spot.facing), 0)
end

-- In front of the arch on the field side, facing it: where somebody with no
-- plot yet (queued behind a full server) is put back.
local function entranceFrame(): CFrame
	local E = ObbyData.Entrance
	return CFrame.new(E.At) * CFrame.Angles(0, math.rad(E.FacingDegrees), 0) * CFrame.new(0, 3.5, 6)
end

local function stageOf(run: Run, pos: Vector3?): string
	if run.phase ~= "running" then
		return "finished"
	end
	if run.challenge == 1 then
		return "challengeB"
	end
	if run.challenge == 2 then
		return "summit"
	end
	-- Past the second checkpoint and south of the rest island: on twilight A.
	if run.main == 4 and pos and pos.Z - ObbyData.Origin.Z < -24 then
		return "challengeA"
	end
	return MAIN_STAGES[math.min(run.main + 1, #MAIN_STAGES)]
end

--==============================================================================
-- MOVING A BODY: stream the destination in, then put it there, stopped
--
-- Yields -- RequestStreamAroundAsync asks the client to load where it is
-- going, so nobody lands on an island that has not arrived yet. Callers run
-- it in their own task and mark the run `moving` meanwhile.
--==============================================================================
local function carryTo(player: Player, cf: CFrame): boolean
	pcall(function()
		player:RequestStreamAroundAsync(cf.Position, 2)
	end)
	local character, humanoid, root = bodyOf(player)
	if not (character and humanoid and root) then
		return false
	end
	if humanoid.Sit then
		humanoid.Sit = false
	end
	character:PivotTo(cf)
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	return true
end

local function unbind(player: Player)
	local list = bodyConnections[player]
	if list then
		for _, c in ipairs(list) do
			c:Disconnect()
		end
	end
	bodyConnections[player] = nil
end

--==============================================================================
-- EVERY WAY OUT ENDS HERE
--==============================================================================
local function release(player: Player, how: string)
	local run = runs[player]
	if not run then
		return
	end
	runs[player] = nil
	unbind(player)
	readyAt[player] = clock() + ObbyData.ReplaySeconds
	for _, name in ipairs({ OA.Course, OA.Stage, OA.StartedAt, OA.EndedAt, OA.Route, OA.Falls, OA.Checkpoint }) do
		player:SetAttribute(name, nil)
	end
	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if humanoid then
		setJump(humanoid, nil)
	end
	pcall(CarryService.RefreshWalkSpeed, player)
	Metrics.obbyEnded(player, how)
	log(string.format("%s left the course (%s) after %d fall(s).", player.Name, how, run.falls))
end

-- Death or a new body mid-run: the run is over where it stands. The respawn
-- goes to the plot the ordinary way, with ordinary movement.
local function bind(player: Player, run: Run)
	unbind(player)
	local list = {}
	local _, humanoid = bodyOf(player)
	if humanoid then
		table.insert(list, humanoid.Died:Connect(function()
			if runs[player] == run then
				release(player, "exited")
			end
		end))
	end
	table.insert(list, player.CharacterRemoving:Connect(function()
		if runs[player] == run then
			release(player, "exited")
		end
	end))
	bodyConnections[player] = list
end

local function answer(player: Player, payload: { [string]: any })
	local remote = channel
	if not remote or player.Parent ~= Players then
		return
	end
	pcall(function()
		remote:FireClient(player, ObbyData.Actions.Result, payload)
	end)
end

--==============================================================================
-- STARTING
--
-- `how` is "start" (the arch's prompt) or "replay" (the pavilion's, only for
-- somebody who has finished and is still up there). Returns whether a run
-- began, and a refusal code the player can act on, or nil.
--==============================================================================
function ObbyService.Begin(player: Player, how: string): (boolean, string?)
	if not running or not GameConfig.Obby.Enabled or player.Parent ~= Players then
		return false, nil
	end
	local character, humanoid, root = bodyOf(player)
	if not (character and humanoid and root) or not PlayerDataService.Get(player) then
		return false, nil
	end
	local current = runs[player]
	if how == "replay" then
		if not current or current.phase ~= "finished" then
			return false, nil
		end
	else
		if current or (readyAt[player] or 0) > clock() then
			return false, nil
		end
		if (root.Position - ObbyData.Entrance.At).Magnitude > START_REACH then
			return false, nil
		end
		if (tonumber(player:GetAttribute(ATTR.PursuedBy)) or 0) > 0
			or (tonumber(player:GetAttribute(ATTR.WakingBy)) or 0) > 0 then
			return false, "OBBY_CHASED"
		end
		if player:GetAttribute(ATTR.CarryingSpecies) ~= nil then
			return false, "CARRYING_POD"
		end
		if player:GetAttribute(ATTR.Trapped) == true or humanoid.PlatformStand then
			return false, "OBBY_STUNNED"
		end
	end
	local ok, rate = pcall(TreadmillService.RateOf, player)
	local basis = if ok and type(rate) == "number" and rate == rate and rate > 0 then rate else 0

	local run: Run = {
		phase = "running",
		startedAt = clock(),
		basis = basis,
		main = 0,
		challenge = 0,
		respawn = "start",
		falls = 0,
		lastPos = nil,
		lastAt = clock(),
		flagged = nil,
		paid = false,
		moving = true,
		stage = MAIN_STAGES[1],
		route = "main",
		id = HttpService:GenerateGUID(false),
	}
	if current then
		-- A Replay. The finished run was paid (or refused) at its finish; this
		-- only closes it for the analytics, which ignore a second close.
		Metrics.obbyEnded(player, "exited")
	end
	runs[player] = run
	bind(player, run)

	put(player, OA.Course, true)
	put(player, OA.Stage, run.stage)
	put(player, OA.Route, "main")
	put(player, OA.Falls, 0)
	put(player, OA.Checkpoint, "start")
	player:SetAttribute(OA.StartedAt, nil)
	player:SetAttribute(OA.EndedAt, nil)
	humanoid:UnequipTools()
	setJump(humanoid, ObbyData.JumpHeight)
	pcall(CarryService.RefreshWalkSpeed, player)
	Metrics.obbyStarted(player)
	log(string.format("%s started the course (%s); basis %s Speed/s.", player.Name, how,
		GameConfig.compact(basis)))

	task.spawn(function()
		carryTo(player, respawnFrame("start"))
		if runs[player] ~= run then
			return
		end
		-- The clock starts on the island, not in the stream-in before it.
		run.startedAt = clock()
		run.lastPos = nil
		run.lastAt = clock()
		run.moving = false
		put(player, OA.StartedAt, Workspace:GetServerTimeNow())
	end)
	return true, nil
end

--==============================================================================
-- LEAVING: Return, or the Exit button. Carried home first, still on the
-- course's rules until they land, then released.
--==============================================================================
--==============================================================================
-- THE OBBY BUTTON: to the course's ENTRANCE, never onto the course
--
-- Where Return and a death already land (entranceFrame), in front of the arch:
-- no checkpoint, no finish, no progress and no reward -- the run still starts
-- at the Start prompt like any other. PlotService.TeleportTo applies TELEPORT
-- TO PLOT's own rules and cooldown; on top of those, never while running the
-- course, never while a guardian is still after the player, and never with
-- the obby switched off. The verb carries nothing else.
--==============================================================================
function ObbyService.TeleportToEntrance(player: Player): boolean
	if not running or not GameConfig.Obby.Enabled or runs[player] ~= nil then
		return false
	end
	if (tonumber(player:GetAttribute(ATTR.PursuedBy)) or 0) > 0
		or (tonumber(player:GetAttribute(ATTR.WakingBy)) or 0) > 0 then
		ActionRefusal.send(player, "OBBY_CHASED")
		return false
	end
	local ok, why = PlotService.TeleportTo(player, entranceFrame(), "OBBY_BLOCKED")
	if not ok and why then
		ActionRefusal.send(player, why)
	end
	return ok
end

function ObbyService.Leave(player: Player): boolean
	local run = runs[player]
	if not run or run.phase == "leaving" then
		return false
	end
	run.phase = "leaving"
	run.moving = true
	task.spawn(function()
		local plot = PlotService.PlotOf(player)
		carryTo(player, if plot then PlotService.SpawnCFrameFor(plot) else entranceFrame())
		if runs[player] == run then
			release(player, "exited")
		end
	end)
	return true
end

--==============================================================================
-- THE TICK
--==============================================================================
local function fell(player: Player, run: Run)
	run.falls += 1
	run.moving = true
	if run.phase == "running" then
		run.main = RESUME_AT[run.respawn] or 0
		run.challenge = 0
		if run.route ~= "main" then
			run.route = "main"
			put(player, OA.Route, "main")
		end
	end
	put(player, OA.Falls, run.falls)
	Metrics.obbyFell(player)
	task.spawn(function()
		carryTo(player, respawnFrame(run.respawn))
		if runs[player] == run then
			run.lastPos = nil
			run.lastAt = clock()
			run.moving = false
		end
	end)
end

local function finish(player: Player, run: Run)
	local seconds = clock() - run.startedAt
	local challenge = run.challenge == 2
	run.phase = "finished"
	run.respawn = "finished"
	run.main = #ObbyData.MainGates
	put(player, OA.Checkpoint, "finished")
	local why: string? = run.flagged
	if not why and seconds < VALID.MinRunSeconds then
		why = string.format("finished in %.1f s, under the %d s floor", seconds, VALID.MinRunSeconds)
	end
	local reward = 0
	-- A WHEEL SPIN OR THE SPEED, NEVER BOTH (2026-09-27): the first five paid
	-- runs in a player's 24-hour window earn a spin in place of the Speed;
	-- after that the run pays its Speed exactly as before. WheelService decides
	-- and pays in one step, and remembers this run's id.
	local spinCount = 0
	if not why and not run.paid then
		run.paid = true
		local amount = run.basis * (ObbyData.Reward.MainSeconds
			+ (if challenge then ObbyData.Reward.ChallengeSeconds else 0))
		local kind, count = WheelService.AwardCompletion(player, run.id, amount)
		if kind == "spin" then
			spinCount = count
		elseif kind == "speed" then
			reward = count
		end
	end
	put(player, OA.EndedAt, Workspace:GetServerTimeNow())
	run.stage = "finished"
	put(player, OA.Stage, "finished")
	if why then
		log(string.format("%s reached the finish, NOT COUNTED: %s.", player.Name, why))
	else
		Metrics.obbyEnded(player, "completed")
		log(string.format("%s finished the %s route in %.1f s with %d fall(s): %s.", player.Name,
			if challenge then "challenge" else "main", seconds, run.falls,
			if spinCount > 0 then string.format("a wheel spin (%d/%d today)", spinCount, WheelData.Daily.Limit)
				else "+" .. GameConfig.compact(reward) .. " Speed"))
	end
	answer(player, {
		ok = why == nil,
		seconds = math.floor(seconds * 10 + 0.5) / 10,
		reward = reward,
		challenge = challenge,
		-- The window's count after this run when it earned a spin; 0 otherwise.
		spin = spinCount,
		limit = WheelData.Daily.Limit,
	})
end

local function advance(player: Player, run: Run, pos: Vector3)
	-- The twilight route, between the second checkpoint and the finish.
	if run.main >= 4 then
		if run.challenge == 0 and inside(gates.ca, pos) then
			run.challenge = 1
			run.route = "challenge"
			put(player, OA.Route, "challenge")
		elseif run.challenge == 1 and inside(gates.cb, pos) then
			run.challenge = 2
			Metrics.obbyCheckpoint(player, "challenge")
		end
	end
	local nextId = ObbyData.MainGates[run.main + 1]
	if nextId == "finish" or (run.main == 4 and run.challenge == 2) then
		if inside(gates.finish, pos) then
			finish(player, run)
			return
		end
	end
	if nextId and nextId ~= "finish" and inside(gates[nextId], pos) then
		run.main += 1
		if nextId == "cp1" then
			run.respawn = "cp1"
			put(player, OA.Checkpoint, "cp1")
			Metrics.obbyCheckpoint(player, "main1")
		elseif nextId == "cp2" then
			run.respawn = "cp2"
			put(player, OA.Checkpoint, "cp2")
			Metrics.obbyCheckpoint(player, "main2")
		elseif nextId == "g5" and run.challenge < 2 and run.route ~= "main" then
			-- Changed their mind on the twilight route and came back: the
			-- normal route, and the normal reward.
			run.challenge = 0
			run.route = "main"
			put(player, OA.Route, "main")
		end
	end
end

local function tick(now: number)
	for player, run in pairs(runs) do
		if run.moving or run.phase == "leaving" then
			continue
		end
		local _, _, root = bodyOf(player)
		if not root then
			continue
		end
		local pos = root.Position
		local last = run.lastPos
		if last and not run.flagged then
			local allowed = MAX_STUDS_PER_SECOND * (now - run.lastAt) + MOVE_SLACK
			local moved = (pos - last).Magnitude
			if moved > allowed then
				local why = string.format("moved %.0f studs in %.2f s", moved, now - run.lastAt)
				run.flagged = why
				log(string.format("%s's run is flagged: %s.", player.Name, why))
			end
		end
		run.lastPos = pos
		run.lastAt = now

		local floor = ObbyData.world((ObbyData.Respawns[run.respawn] or ObbyData.Respawns.start).at).Y
		if pos.Y < floor + ObbyData.KillBelow then
			fell(player, run)
			continue
		end
		if run.phase == "running" then
			advance(player, run, pos)
		end
		local stage = stageOf(run, pos)
		if stage ~= run.stage then
			run.stage = stage
			put(player, OA.Stage, stage)
		end
	end
end

--==============================================================================
-- THE PREVIEW ON THE ARCH: what a run started now would pay
--==============================================================================
local function preview(player: Player)
	if not PlayerDataService.Get(player) then
		return
	end
	local rate = TreadmillService.RateOf(player)
	if type(rate) ~= "number" or rate ~= rate or rate < 0 then
		return
	end
	put(player, OA.RewardMain, math.floor(rate * ObbyData.Reward.MainSeconds + 0.5))
	put(player, OA.RewardChallenge, math.floor(rate * ObbyData.Reward.ChallengeSeconds + 0.5))
end

--==============================================================================
-- FOR HARNESSES AND FOR LOOKING
--==============================================================================
function ObbyService.useClock(fn: (() -> number)?)
	clockFn = fn or os.clock
end

-- One tick, now, and the preview for every player: what the loop does every
-- tenth of a second.
function ObbyService.Tick()
	tick(clock())
	for _, player in ipairs(Players:GetPlayers()) do
		pcall(preview, player)
	end
end

function ObbyService.RunOf(player: Player): { [string]: any }?
	local run = runs[player]
	if not run then
		return nil
	end
	return table.clone(run) :: any
end

function ObbyService.Snapshot(): string
	local rows = {}
	for player, run in pairs(runs) do
		table.insert(rows, string.format("%s: %s stage=%s main=%d challenge=%d respawn=%s falls=%d paid=%s%s",
			player.Name, run.phase, run.stage, run.main, run.challenge, run.respawn, run.falls,
			tostring(run.paid), if run.flagged then " FLAGGED(" .. run.flagged .. ")" else ""))
	end
	return if #rows > 0 then table.concat(rows, "\n") else "nobody on the course"
end

--==============================================================================
-- LIFECYCLE
--==============================================================================
function ObbyService.Init()
	running = false
	generation += 1
	for _, c in ipairs(serviceConnections) do
		c:Disconnect()
	end
	table.clear(serviceConnections)
	-- A rerun puts every runner back to normal and home; the course they
	-- stood on is about to be rebuilt under them.
	for player in pairs(runs) do
		release(player, "exited")
		task.spawn(function()
			local plot = PlotService.PlotOf(player)
			carryTo(player, if plot then PlotService.SpawnCFrameFor(plot) else entranceFrame())
		end)
	end
	table.clear(readyAt)
	channel = nil
end

function ObbyService.Start()
	local remotes = SeedGame:FindFirstChild("Remotes")
	local found = if remotes then remotes:FindFirstChild(GameConfig.Remotes.GameEvent) else nil
	channel = if found and found:IsA("RemoteEvent") then found else nil

	if not GameConfig.Obby.Enabled then
		ObbyCourse.Remove()
		for _, player in ipairs(Players:GetPlayers()) do
			player:SetAttribute(OA.RewardMain, nil)
			player:SetAttribute(OA.RewardChallenge, nil)
		end
		log("Ready. The Floating Garden is SWITCHED OFF (GameConfig.Obby.Enabled = false).")
		return
	end

	local course = ObbyCourse.Build()
	local function hook(path: { string }, fn: (Player) -> ())
		local node: Instance? = course
		for _, name in ipairs(path) do
			node = if node then node:FindFirstChild(name) else nil
		end
		if node and node:IsA("ProximityPrompt") then
			table.insert(serviceConnections, node.Triggered:Connect(fn))
		else
			warn("[Seed/ObbyService] Missing prompt " .. table.concat(path, "."))
		end
	end
	hook({ "Entrance", "StartStep", "StartPrompt" }, function(player: Player)
		local _, code = ObbyService.Begin(player, "start")
		if code then
			ActionRefusal.send(player, code)
		end
	end)
	hook({ "Finish", "ReplayPlinth", "ReplayPrompt" }, function(player: Player)
		ObbyService.Begin(player, "replay")
	end)
	hook({ "Finish", "ReturnPlinth", "ReturnPrompt" }, function(player: Player)
		local run = runs[player]
		if run and run.phase == "finished" then
			ObbyService.Leave(player)
		end
	end)

	local remote = channel
	if remote then
		table.insert(serviceConnections, remote.OnServerEvent:Connect(function(player: Player, action: any)
			if action == ObbyData.Actions.Exit then
				ObbyService.Leave(player)
			elseif action == WheelData.Actions.ObbyTeleport then
				ObbyService.TeleportToEntrance(player)
			end
		end))
	else
		warn("[Seed/ObbyService] No GameEvent remote; the Exit button will do nothing.")
	end

	table.insert(serviceConnections, Players.PlayerRemoving:Connect(function(player: Player)
		release(player, "left")
		readyAt[player] = nil
	end))

	running = true
	if ObbyService.ManualTick then
		log("Ready (manual tick).")
		return
	end
	local mine = generation
	task.spawn(function()
		local nextPreview = 0
		while running and generation == mine do
			local now = clock()
			local ok, err = pcall(tick, now)
			if not ok then
				warn("[Seed/ObbyService] tick: " .. tostring(err))
			end
			if now >= nextPreview then
				nextPreview = now + PREVIEW_SECONDS
				for _, player in ipairs(Players:GetPlayers()) do
					pcall(preview, player)
				end
			end
			task.wait(TICK_SECONDS)
		end
	end)

	local start = ObbyData.world(ObbyData.Start.at)
	log(string.format("Ready. The Floating Garden starts at (%.0f, %.0f, %.0f); %d main gates, %d challenge gates, "
		.. "a run pays %d s (+%d s challenge) of the belt's 1x rate.", start.X, start.Y, start.Z,
		#ObbyData.MainGates, #ObbyData.ChallengeGates, ObbyData.Reward.MainSeconds, ObbyData.Reward.ChallengeSeconds))
end

return ObbyService
