--!nocheck
--==============================================================================
-- Steal a Seed :: ObbySpec
--
-- The Floating Garden's server rules, driven end to end without a Play
-- session: the REAL ObbyService, loaded from its Source with the services
-- around it stood in (Players, PlayerDataService, PlotService, CarryService,
-- TreadmillService, Metrics, ObbyCourse, WheelService). The stand-ins only
-- RECORD, so the count of PayReward calls is the evidence that a run pays once.
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("ObbySpec"))
--
-- Time is the spec's: ObbyService.useClock hands it a clock the spec steps,
-- and ManualTick stops Start from spawning the 10 Hz loop, so every tick here
-- is one ObbyService.Tick() at a known moment. The runner is a table with a
-- real Model for a Character -- a real anchored root and a real Humanoid -- so
-- PivotTo, JumpHeight and UnequipTools are the engine's own. Bodies move in
-- steps short enough never to trip the teleport check, except where a test
-- means to trip it.
--
-- Not here: the platforms moving, the springs throwing, the HUD, the prompts
-- and two real people on the course at once (Play; see KB/HANDOFF.md and the
-- physics-bot runs recorded there).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local ObbyData = require(Shared:WaitForChild("ObbyData"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")

local OA = ObbyData.Attributes
local ATTR = GameConfig.Attributes

local out = {}
local pass, fail = 0, 0

local function say(line)
	table.insert(out, line)
end

local function check(ok, label, detail)
	if ok then
		pass += 1
		say(string.format("  PASS  %s", label))
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label,
			if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

--==============================================================================
-- THE STAND-INS
--==============================================================================
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = { ... } })
end
local function count(name, arg2)
	local n = 0
	for _, t in ipairs(trace) do
		if t.name == name and (arg2 == nil or t.args[2] == arg2) then
			n += 1
		end
	end
	return n
end
local function lastArgs(name)
	for i = #trace, 1, -1 do
		if trace[i].name == name then
			return trace[i].args
		end
	end
	return nil
end

local scratch = Instance.new("Folder")
scratch.Name = "ObbySpecScratch"
scratch.Archivable = false
scratch.Parent = Workspace

local character = Instance.new("Model")
character.Name = "SpecRunner"
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Anchored = true
root.CanCollide = false
root.Size = Vector3.new(2, 2, 1)
root.Parent = character
character.PrimaryPart = root
local humanoid = Instance.new("Humanoid")
-- As every character in the game: jump HEIGHT, not power.
humanoid.UseJumpPower = false
humanoid.Parent = character
character.Parent = scratch

local removingEvent = Instance.new("BindableEvent")
-- PlayerRemoving hands its listeners the Player itself. A BindableEvent would
-- deep-copy a table player, and the service would be told about a stranger, so
-- this one is a plain list of listeners called directly.
local leaving = {}
local fakePlayers = {}
fakePlayers.PlayerRemoving = {
	Connect = function(_, fn)
		table.insert(leaving, fn)
		return {
			Disconnect = function()
				local i = table.find(leaving, fn)
				if i then
					table.remove(leaving, i)
				end
			end,
		}
	end,
}
local attrs = {}
local runner = { Name = "SpecRunner", UserId = 4244, Parent = fakePlayers, Character = character }
runner.CharacterRemoving = removingEvent.Event
function runner:GetAttribute(name)
	return attrs[name]
end
function runner:SetAttribute(name, value)
	attrs[name] = value
end
function runner:RequestStreamAroundAsync()
	-- Nothing to stream in Edit mode.
end
function fakePlayers:GetPlayers()
	return { runner }
end

local PlayerDataService = {
	Get = function()
		return { Speed = 0 }
	end,
}
local plotCF = CFrame.new(0, 3, 40)
local hasPlot = false
-- What PlotService.TeleportTo answers the OBBY button: its own checks are
-- PlotTeleportSpec's; here only that ObbyService goes through it.
local teleportAnswer = { true }
local PlotService = {
	PlotOf = function()
		return if hasPlot then {} else nil
	end,
	SpawnCFrameFor = function()
		return plotCF
	end,
	TeleportTo = function(player, target, blocked)
		record("TeleportTo", player, target, blocked)
		return teleportAnswer[1], teleportAnswer[2]
	end,
}
local CarryService = {
	RefreshWalkSpeed = function(player)
		record("RefreshWalkSpeed", player)
	end,
}
local rate = 20
local TreadmillService = {
	RateOf = function()
		return rate
	end,
	PayReward = function(player, amount, reason)
		record("PayReward", player, amount, reason)
		return true
	end,
}
local Metrics = {
	obbyStarted = function(p) record("obbyStarted", p) end,
	obbyCheckpoint = function(p, which) record("obbyCheckpoint", p, which) end,
	obbyFell = function(p) record("obbyFell", p) end,
	obbyEnded = function(p, how) record("obbyEnded", p, how) end,
}
-- THE REWARD WHEEL (2026-09-27): ObbyService hands every paid run to
-- WheelService.AwardCompletion, which pays either a spin or the run's Speed.
-- This one decides by `wheelMode`: "speed" pays through the TreadmillService
-- stand-in (so every Speed pin below still counts PayReward), "spin" pays no
-- Speed, "none" is a completion already credited. The real rules are WheelSpec's.
local wheelMode = "speed"
local wheelCount = 0
local WheelService = {
	AwardCompletion = function(player, runId, speed)
		record("AwardCompletion", player, runId, speed)
		if wheelMode == "spin" then
			wheelCount += 1
			return "spin", wheelCount
		elseif wheelMode == "none" then
			return "none", 0
		end
		TreadmillService.PayReward(player, speed, "the Floating Garden")
		return "speed", speed
	end,
}

-- A course with only its three prompts: nothing else is ObbyService's business.
local course = Instance.new("Folder")
course.Name = "SeedObbySpec"
local function promptAt(path)
	local node = course
	for i, name in ipairs(path) do
		local child = node:FindFirstChild(name)
		if not child then
			child = if i == #path then Instance.new("ProximityPrompt")
				elseif i == #path - 1 then Instance.new("Part") else Instance.new("Model")
			child.Name = name
			if child:IsA("BasePart") then
				child.Anchored = true
			end
			child.Parent = node
		end
		node = child
	end
	return node
end
promptAt({ "Entrance", "StartStep", "StartPrompt" })
promptAt({ "Finish", "ReplayPlinth", "ReplayPrompt" })
promptAt({ "Finish", "ReturnPlinth", "ReturnPrompt" })
course.Parent = scratch
local ObbyCourse = {
	Build = function()
		record("Build")
		return course
	end,
	Remove = function()
		record("Remove")
	end,
}

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "Players" then
		return fakePlayers
	end
	return game:GetService(name)
end

local outerRequire = require
local function loadWith(module, siblings, overrides)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, module.Name .. " asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	local env = setmetatable({
		game = fakeGame,
		script = { Name = module.Name, Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			if overrides and typeof(target) == "Instance" and overrides[target.Name] ~= nil then
				return overrides[target.Name]
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) })
	setfenv(chunk, env)
	return chunk()
end

local ok, ObbyService = pcall(loadWith, Server:WaitForChild("ObbyService"), {
	PlayerDataService = PlayerDataService,
	PlotService = PlotService,
	CarryService = CarryService,
	TreadmillService = TreadmillService,
	Metrics = Metrics,
	ObbyCourse = ObbyCourse,
	WheelService = WheelService,
})
check(ok, "ObbyService loads against the stand-ins", if ok then nil else ObbyService)
if not ok then
	scratch:Destroy()
	return string.format("ObbySpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
end

local now = 1000
ObbyService.useClock(function()
	return now
end)
ObbyService.ManualTick = true
ObbyService.Init()
ObbyService.Start()

local W = ObbyData.world
local function gate(id)
	for _, stage in ipairs(ObbyData.Stages) do
		if stage.gate.id == id then
			return W(stage.gate.at)
		end
	end
	error("no gate " .. id)
end
-- Walk the body to a floor point (root 3 above it) over `seconds`, ticking
-- every tenth: steps far too short to look like a teleport.
local function walkTo(floor, seconds)
	local target = floor + Vector3.new(0, 3, 0)
	local from = root.Position
	local steps = math.max(1, math.ceil(seconds / 0.1))
	for i = 1, steps do
		now += seconds / steps
		character:PivotTo(CFrame.new(from:Lerp(target, i / steps)))
		ObbyService.Tick()
	end
end
-- One move and one tick, `seconds` after the last.
local function tickAt(floor, seconds)
	now += seconds
	character:PivotTo(CFrame.new(floor + Vector3.new(0, 3, 0)))
	ObbyService.Tick()
end
local function atEntrance()
	character:PivotTo(CFrame.new(ObbyData.Entrance.At + Vector3.new(-3, 3, 0)))
end
local function reset()
	table.clear(trace)
	humanoid.PlatformStand = false
	for name in pairs(attrs) do
		attrs[name] = nil
	end
end
local function fresh()
	reset()
	ObbyService.Leave(runner)
	now += ObbyData.ReplaySeconds + 2
	atEntrance()
	return ObbyService.Begin(runner, "start")
end
local function finishRoute(challenge)
	walkTo(gate("g1"), 4)
	walkTo(gate("cp1"), 5)
	walkTo(gate("g3"), 6)
	walkTo(gate("cp2"), 8)
	if challenge then
		walkTo(gate("ca"), 6)
		walkTo(gate("cb"), 8)
	else
		walkTo(gate("g5"), 6)
	end
	walkTo(gate("finish"), 6)
end

--==============================================================================
-- 1. WHO MAY START
--==============================================================================
say("-- starting --")
reset()
character:PivotTo(CFrame.new(0, 3, 0))
local began, code = ObbyService.Begin(runner, "start")
check(not began and code == nil, "a start asked from across the map is refused, and says nothing", code)

atEntrance()
attrs[ATTR.PursuedBy] = 1
began, code = ObbyService.Begin(runner, "start")
check(not began and code == "OBBY_CHASED", "a chased player is told to wait for the chase to end", code)
attrs[ATTR.PursuedBy] = nil
attrs[ATTR.WakingBy] = 1
began, code = ObbyService.Begin(runner, "start")
check(not began and code == "OBBY_CHASED", "so is one a guardian is waking for", code)
attrs[ATTR.WakingBy] = nil
attrs[ATTR.CarryingSpecies] = "nubkin"
began, code = ObbyService.Begin(runner, "start")
check(not began and code == "CARRYING_POD", "carrying a raided pod: bank it first", code)
attrs[ATTR.CarryingSpecies] = nil
attrs[ATTR.Trapped] = true
began, code = ObbyService.Begin(runner, "start")
check(not began and code == "OBBY_STUNNED", "trapped: wait until you can move", code)
attrs[ATTR.Trapped] = nil
humanoid.PlatformStand = true
began, code = ObbyService.Begin(runner, "start")
check(not began and code == "OBBY_STUNNED", "knocked down (ragdolled): the same", code)
humanoid.PlatformStand = false
check(ActionRefusal.Text.OBBY_CHASED ~= nil and ActionRefusal.Notices.OBBY_STUNNED ~= nil
	and ActionRefusal.Notices.TRAP_OBBY ~= nil, "every obby refusal has words and a notice")

reset()
atEntrance()
humanoid.JumpHeight = StarterPlayer.CharacterJumpHeight
began, code = ObbyService.Begin(runner, "start")
check(began and code == nil, "a clear player at the arch starts", code)
check(attrs[OA.Course] == true and attrs[OA.Stage] == "sunpetal" and attrs[OA.Checkpoint] == "start"
	and attrs[OA.Falls] == 0 and attrs[OA.Route] == "main",
	"the run is published: on the course, Sunpetal, start checkpoint, no falls, main route")
check(math.abs(humanoid.JumpHeight - ObbyData.JumpHeight) < 1e-6, "the course's fixed jump is on",
	humanoid.JumpHeight)
check(count("RefreshWalkSpeed") >= 1, "and the walk speed was recomputed (CarryService reads the attribute)")
local startAt = W(ObbyData.Start.at)
check((root.Position - (startAt + Vector3.new(0, 3.5, 0))).Magnitude < 0.5, "carried to the start island",
	root.Position)
check(type(attrs[OA.StartedAt]) == "number", "and the clock started on landing")
check(count("obbyStarted") == 1, "analytics heard one start")
began = ObbyService.Begin(runner, "start")
check(not began, "a second start while running is ignored")

--==============================================================================
-- 2. ORDER, CHECKPOINTS AND FALLS
--==============================================================================
say("-- order --")
-- Over the top of g1 and cp1 (a gate only counts a body standing on it), and
-- down onto g3: the course in a straight line runs through the earlier gates.
local over = Vector3.new(0, 30, 0)
walkTo(startAt + over, 2)
walkTo(gate("g3") + over, 8)
walkTo(gate("g3"), 2)
check(ObbyService.RunOf(runner).main == 0, "reaching a later gate first counts for nothing")
walkTo(gate("g3") + over, 2)
walkTo(startAt + over, 8)
walkTo(startAt, 2)
walkTo(gate("g1"), 4)
check(ObbyService.RunOf(runner).main == 1 and attrs[OA.Stage] == "lilywater", "g1 opens Lilywater",
	attrs[OA.Stage])
walkTo(gate("cp1"), 5)
check(ObbyService.RunOf(runner).respawn == "cp1" and attrs[OA.Checkpoint] == "cp1",
	"the first checkpoint is reached and published")
check(count("obbyCheckpoint", "main1") == 1, "analytics heard checkpoint one")
walkTo(gate("g3"), 6)
check(ObbyService.RunOf(runner).main == 3 and attrs[OA.Stage] == "mushroom", "g3 in order opens Mushroom Springs",
	attrs[OA.Stage])

local cp1 = W(ObbyData.Respawns.cp1.at)
walkTo(cp1 + Vector3.new(15, 0, 0), 4)
tickAt(cp1 + Vector3.new(15, ObbyData.KillBelow - 5, 0), 0.3)
check(attrs[OA.Falls] == 1, "a fall is counted", attrs[OA.Falls])
check((root.Position - (cp1 + Vector3.new(0, 3.5, 0))).Magnitude < 0.5, "and puts the runner back on checkpoint one",
	root.Position)
check(ObbyService.RunOf(runner).main == 2, "progress goes back to the checkpoint's: g3 must be passed again")
check(count("obbyFell") == 1, "analytics heard the fall")
check(ObbyService.RunOf(runner).flagged == nil, "a fall is not a teleport")

--==============================================================================
-- 3. TOO FAST, AND A TELEPORT: the finish refuses to pay
--==============================================================================
say("-- timing --")
fresh()
for _, id in ipairs({ "g1", "cp1", "g3", "cp2", "g5", "finish" }) do
	walkTo(gate(id), 2.5)
end
check(attrs[OA.Stage] == "finished", "every gate in 15 s still reaches the finish", attrs[OA.Stage])
check(count("PayReward") == 0, "but a run under MinRunSeconds pays nothing", count("PayReward"))
check(count("obbyEnded", "completed") == 0, "and is not reported as a completion")

fresh()
walkTo(gate("g1"), 10)
tickAt(gate("cp1"), 0.1)
check(ObbyService.RunOf(runner).flagged ~= nil, "a body that moved further than anything can throw it is flagged",
	ObbyService.RunOf(runner).flagged)
walkTo(gate("g3"), 10)
walkTo(gate("cp2"), 10)
walkTo(gate("g5"), 10)
walkTo(gate("finish"), 10)
check(attrs[OA.Stage] == "finished" and count("PayReward") == 0, "a flagged run finishes and pays nothing")

--==============================================================================
-- 4. A REAL RUN PAYS ONCE; THE CHALLENGE PAYS MORE
--==============================================================================
say("-- paying --")
rate = 20
fresh()
rate = 999 -- an upgrade bought mid-run changes nothing
finishRoute(false)
local paid = lastArgs("PayReward")
check(count("PayReward") == 1 and paid and paid[2] == 20 * ObbyData.Reward.MainSeconds,
	"a clean main run pays the snapshot basis x MainSeconds, once", paid and paid[2])
check(count("obbyEnded", "completed") == 1, "and is reported completed once")
tickAt(gate("finish"), 1)
tickAt(gate("finish"), 1)
check(count("PayReward") == 1, "standing in the pavilion pays nothing more")
check(attrs[OA.Checkpoint] == "finished" and type(attrs[OA.EndedAt]) == "number",
	"the finish is published and the clock stops")
check(math.abs(humanoid.JumpHeight - ObbyData.JumpHeight) < 1e-6,
	"a finished runner keeps the course's movement while still up there")
local finishedAt = W(ObbyData.Respawns.finished.at)
tickAt(finishedAt + Vector3.new(0, ObbyData.KillBelow - 5, 0), 0.3)
check((root.Position - (finishedAt + Vector3.new(0, 3.5, 0))).Magnitude < 0.5 and count("PayReward") == 1,
	"a fall off the summit after finishing lands back at the pavilion, unpaid again")

rate = 30
local replayed = ObbyService.Begin(runner, "replay")
check(replayed and attrs[OA.Stage] == "sunpetal" and attrs[OA.EndedAt] == nil, "Replay starts a new run",
	attrs[OA.Stage])
finishRoute(true)
paid = lastArgs("PayReward")
check(count("PayReward") == 2 and paid
	and paid[2] == 30 * (ObbyData.Reward.MainSeconds + ObbyData.Reward.ChallengeSeconds),
	"the challenge route pays main + challenge seconds on the new run's basis", paid and paid[2])
check(count("obbyCheckpoint", "challenge") == 1, "analytics heard the challenge route completed")

-- Changing your mind: twilight A done, then back to Autumn Drift.
rate = 20
fresh()
walkTo(gate("g1"), 4)
walkTo(gate("cp1"), 5)
walkTo(gate("g3"), 6)
walkTo(gate("cp2"), 8)
walkTo(gate("ca"), 6)
check(attrs[OA.Route] == "challenge", "entering twilight A marks the challenge route")
walkTo(gate("cp2"), 6)
walkTo(gate("g5"), 8)
check(attrs[OA.Route] == "main", "turning back to Autumn Drift puts the run back on the main route")
walkTo(gate("finish"), 6)
paid = lastArgs("PayReward")
check(count("PayReward") == 1 and paid and paid[2] == 20 * ObbyData.Reward.MainSeconds,
	"and pays the main reward only -- the challenge needs both stages and the finish", paid and paid[2])

-- A fall on the twilight route resets it.
fresh()
walkTo(gate("g1"), 4)
walkTo(gate("cp1"), 5)
walkTo(gate("g3"), 6)
walkTo(gate("cp2"), 8)
walkTo(gate("ca"), 6)
local cp2 = W(ObbyData.Respawns.cp2.at)
tickAt(gate("ca") + Vector3.new(10, -35, 0), 0.3)
check(ObbyService.RunOf(runner).challenge == 0 and attrs[OA.Route] == "main"
	and (root.Position - (cp2 + Vector3.new(0, 3.5, 0))).Magnitude < 0.5,
	"a fall on the twilight route puts the runner back on the rest island with the route reset")

--==============================================================================
-- 5. EVERY WAY OUT PUTS MOVEMENT BACK
--==============================================================================
say("-- leaving --")
hasPlot = true
table.clear(trace)
ObbyService.Leave(runner)
check(attrs[OA.Course] == nil and attrs[OA.Stage] == nil and attrs[OA.Checkpoint] == nil and attrs[OA.Falls] == nil,
	"Return/Exit clears every run attribute")
check(math.abs(humanoid.JumpHeight - StarterPlayer.CharacterJumpHeight) < 1e-6,
	"and puts the jump back to StarterPlayer's", humanoid.JumpHeight)
check(count("RefreshWalkSpeed") >= 1, "and recomputes the walk speed from the profile")
check((root.Position - plotCF.Position).Magnitude < 0.5, "and carries the runner to their plot", root.Position)
check(count("obbyEnded", "exited") == 1, "an unfinished run is reported exited")
atEntrance()
began = ObbyService.Begin(runner, "start")
check(not began, "a new start inside ReplaySeconds is quietly refused")

now += ObbyData.ReplaySeconds + 1
atEntrance()
ObbyService.Begin(runner, "start")
table.clear(trace)
removingEvent:Fire()
task.wait() -- signals may be deferred
check(attrs[OA.Course] == nil and count("obbyEnded", "exited") == 1
	and math.abs(humanoid.JumpHeight - StarterPlayer.CharacterJumpHeight) < 1e-6,
	"a new body (death, respawn) ends the run where it stands, movement back")

now += ObbyData.ReplaySeconds + 1
atEntrance()
local rebegan, recode = ObbyService.Begin(runner, "start")
table.clear(trace)
for _, fn in ipairs(table.clone(leaving)) do
	fn(runner)
end
check(rebegan and attrs[OA.Course] == nil and count("obbyEnded", "left") == 1, "leaving the server ends the run as left",
	string.format("began=%s code=%s course=%s left=%d", tostring(rebegan), tostring(recode), tostring(attrs[OA.Course]),
		count("obbyEnded", "left")))

--==============================================================================
-- 5b. THE REWARD WHEEL (2026-09-27): A SPIN OR THE SPEED, NEVER BOTH
--
-- Every paid run goes to WheelService.AwardCompletion with the run's own id
-- and the Speed it would pay, and ObbyService pays nothing itself. The stand-in
-- decides here; the real allowance (five per 24-hour window) is WheelSpec's.
--==============================================================================
say("-- the reward wheel --")
wheelMode = "spin"
rate = 20
fresh()
finishRoute(false)
local award = lastArgs("AwardCompletion")
check(count("AwardCompletion") == 1 and count("PayReward") == 0, "a run that earns a wheel spin pays no Speed",
	string.format("award %d pay %d", count("AwardCompletion"), count("PayReward")))
check(award ~= nil and type(award[2]) == "string" and #award[2] >= 16 and award[3] == 20 * ObbyData.Reward.MainSeconds,
	"WheelService is handed the run's own id and the Speed it would otherwise pay", award and tostring(award[2]))
tickAt(gate("finish"), 1)
tickAt(gate("finish"), 1)
check(count("AwardCompletion") == 1, "standing in the pavilion offers the finished run nothing more")
local firstId = award and award[2]
ObbyService.Begin(runner, "replay")
finishRoute(true)
award = lastArgs("AwardCompletion")
check(count("AwardCompletion") == 2 and award ~= nil and award[2] ~= firstId
	and award[3] == 20 * (ObbyData.Reward.MainSeconds + ObbyData.Reward.ChallengeSeconds),
	"a replay is a new run with a new id; the challenge route hands over main + challenge", award and tostring(award[2]))
fresh()
for _, id in ipairs({ "g1", "cp1", "g3", "cp2", "g5", "finish" }) do
	walkTo(gate(id), 2.5)
end
check(count("AwardCompletion") == 0, "a run under MinRunSeconds is offered to nobody")
wheelMode = "none"
fresh()
finishRoute(false)
check(count("AwardCompletion") == 1 and count("PayReward") == 0, "a run WheelService says it already credited pays nothing")
wheelMode = "speed"

--==============================================================================
-- 5c. THE OBBY BUTTON (2026-09-27): TO THE ENTRANCE, THROUGH TELEPORT TO
-- PLOT'S OWN RULES, AND NOTHING MORE
--==============================================================================
say("-- the OBBY button --")
local refusals = {}
ActionRefusal.capture(function(_, code)
	table.insert(refusals, code)
end)
reset()
ObbyService.Leave(runner)
character:PivotTo(CFrame.new(0, 3, 0))
teleportAnswer = { true }
local went = ObbyService.TeleportToEntrance(runner)
local asked = lastArgs("TeleportTo")
local E = ObbyData.Entrance
check(went and count("TeleportTo") == 1 and asked ~= nil and asked[3] == "OBBY_BLOCKED"
	and typeof(asked[2]) == "CFrame" and (asked[2].Position - E.At).Magnitude < 10,
	"OBBY asks PlotService.TeleportTo for the arch's entrance, with its own code for a bad landing",
	asked and tostring(asked[2]))
check(attrs[OA.Course] == nil and count("obbyStarted") == 0 and count("AwardCompletion") == 0
	and count("PayReward") == 0, "and starts nothing: no run, no checkpoint, no reward")
attrs[ATTR.PursuedBy] = 1
table.clear(trace)
table.clear(refusals)
went = ObbyService.TeleportToEntrance(runner)
check(not went and count("TeleportTo") == 0 and refusals[1] == "OBBY_CHASED", "never during a chase", refusals[1])
attrs[ATTR.PursuedBy] = nil
attrs[ATTR.WakingBy] = 1
table.clear(refusals)
went = ObbyService.TeleportToEntrance(runner)
check(not went and count("TeleportTo") == 0 and refusals[1] == "OBBY_CHASED", "nor while a guardian wakes for them",
	refusals[1])
attrs[ATTR.WakingBy] = nil
teleportAnswer = { false, "CARRYING_POD" }
table.clear(trace)
table.clear(refusals)
went = ObbyService.TeleportToEntrance(runner)
check(not went and count("TeleportTo") == 1 and refusals[1] == "CARRYING_POD",
	"TELEPORT TO PLOT's own refusals (a raided pod here) reach the player as they are", refusals[1])
teleportAnswer = { true }
now += ObbyData.ReplaySeconds + 1
atEntrance()
ObbyService.Begin(runner, "start")
table.clear(trace)
went = ObbyService.TeleportToEntrance(runner)
check(not went and count("TeleportTo") == 0, "and never from the course itself")
ObbyService.Leave(runner)
ActionRefusal.capture(nil)
check(ActionRefusal.Text.OBBY_BLOCKED ~= nil and ActionRefusal.Notices.OBBY_BLOCKED ~= nil,
	"a blocked entrance has words and a notice")

--==============================================================================
-- 6. THE PREVIEW AND THE SWITCH
--==============================================================================
say("-- preview and switch --")
rate = 20
ObbyService.Tick()
check(attrs[OA.RewardMain] == 20 * ObbyData.Reward.MainSeconds
	and attrs[OA.RewardChallenge] == 20 * ObbyData.Reward.ChallengeSeconds,
	"the arch's preview is the server's own sum", attrs[OA.RewardMain])

-- GameConfig is frozen, so the switch is thrown on a second copy of the
-- service that sees a GameConfig whose Obby block says Enabled = false.
ObbyService.Init()
local offConfig = setmetatable({ Obby = { Enabled = false } }, { __index = GameConfig })
local offOk, Off = pcall(loadWith, Server:WaitForChild("ObbyService"), {
	PlayerDataService = PlayerDataService,
	PlotService = PlotService,
	CarryService = CarryService,
	TreadmillService = TreadmillService,
	Metrics = Metrics,
	ObbyCourse = ObbyCourse,
	WheelService = WheelService,
}, { GameConfig = offConfig })
check(offOk, "a switched-off copy loads", if offOk then nil else Off)
if offOk then
	Off.ManualTick = true
	Off.useClock(function()
		return now
	end)
	table.clear(trace)
	Off.Init()
	Off.Start()
	check(count("Remove") == 1 and count("Build") == 0, "switched off: no course is built")
	now += ObbyData.ReplaySeconds + 1
	atEntrance()
	began = Off.Begin(runner, "start")
	check(not began, "and nobody can start")
	Off.Init()
end

ObbyService.useClock(nil)
scratch:Destroy()
return string.format("ObbySpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
