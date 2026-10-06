--!nocheck
--==============================================================================
-- Steal a Seed :: BatHitSpec (2026-10-04, the owner's combat brief)
--
-- Edit mode, no Play:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("BatHitSpec"))
--
-- The REAL CombatService, on the spec's clock and the spec's Heartbeat (the
-- TrapSystemSpec harness): stand-in players with real bodies, a stand-in
-- CarryService that records every drop, and the ThrowVictim remote stood in so
-- each launch is observed.
--
--   1. WeaponData.SweepContact, the pure geometry: a body crossing the swing
--      between two frames is struck where both instant checks miss; a jump is
--      never swept; height, arc and reach still bound it; the rewind is small.
--   2. The swing on the server: the window opens at Windup - Lead and closes at
--      Windup + Trail and resolves nothing outside it; a fast crossing target is
--      hit; a wall, the safe field and a teleport-sized jump are refused; one hit
--      per target per swing; a held pod comes off BEFORE the ragdoll, for a raid
--      carry and a banked Tool; two swings landing together launch the victim
--      once; a slowed player may swing, a rooted one may not; a swing whose bat
--      was put away, or whose swinger went away, strikes nobody.
--
-- NOT here: a real two-client fight (Play with two people), the arm drawn by
-- WeaponFX, the victim's client ragdoll (ThrowFX) and real latency.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local WeaponModel = require(Shared:WaitForChild("WeaponModel"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")

local ATTR = GameConfig.Attributes
local C = WeaponData.Combat

local out = {}
local pass, fail = 0, 0
local function say(line)
	table.insert(out, line)
end
local function check(ok, label, detail)
	if ok then
		pass += 1
		say("  PASS  " .. label)
	else
		fail += 1
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

--==============================================================================
-- 1. THE GEOMETRY, BY ITSELF
--==============================================================================
say("\n-- the swept contact --")
do
	local rootwood = WeaponData.Get("rootwood_bat")
	local reach = rootwood.Reach + C.HitReachSlack
	local cosLimit = math.cos(math.rad(C.ArcDegrees + C.HitArcSlack))
	local look = Vector3.new(0, 0, -1)
	local H = C.HeightTolerance
	local S = C.SweepSubSamples
	-- Crossing the far edge of the swing between two frames: 13 studs ahead,
	-- from 6 left to 4 right.
	local from, to = Vector3.new(-6, 0, -13), Vector3.new(4, 0, -13)
	local swept = WeaponData.SweepContact(from, to, Vector3.zero, look, reach, cosLimit, H, S)
	local instantFrom = WeaponData.SweepContact(nil, from, Vector3.zero, look, reach, cosLimit, H, S)
	local instantTo = WeaponData.SweepContact(nil, to, Vector3.zero, look, reach, cosLimit, H, S)
	check(swept ~= nil and instantFrom == nil and instantTo == nil,
		"a body that crosses the swing BETWEEN two frames is struck, where an instant check at either frame misses",
		tostring(swept))
	check(WeaponData.SweepContact(nil, from, Vector3.zero, look, reach, cosLimit, H, S) == nil,
		"and with no previous frame (a jump, or the window's first frame) only where it IS counts")
	check(WeaponData.SweepContact(Vector3.new(0, 0, -6), Vector3.new(0, 8, -6), Vector3.zero, look, reach,
			cosLimit, H, S) ~= nil
			and WeaponData.SweepContact(nil, Vector3.new(0, H + 0.5, -6), Vector3.zero, look, reach, cosLimit, H, S) == nil,
		"height still bounds it: in reach at chest height, not on a roof")
	check(WeaponData.SweepContact(nil, Vector3.new(0, 0, 6), Vector3.zero, look, reach, cosLimit, H, S) == nil
			and WeaponData.SweepContact(nil, Vector3.new(10, 0, -0.5), Vector3.zero, look, reach, cosLimit, H, S) == nil,
		"and the arc: nothing behind the swinger, nothing square to their side")
	check(WeaponData.SweepContact(nil, Vector3.new(0, 0, -(reach + 0.4)), Vector3.zero, look, reach, cosLimit, H, S) == nil
			and WeaponData.SweepContact(nil, Vector3.new(0, 0, -(reach - 0.2)), Vector3.zero, look, reach, cosLimit, H, S) ~= nil,
		string.format("and reach: %.1f studs (the bat's %.1f plus %.1f of slack), not an aura", reach,
			rootwood.Reach, C.HitReachSlack))
	-- The rewind: a target the swinger saw 3 studs back along its own run.
	local justOut = Vector3.new(0, 0, -(reach + 2))
	check(WeaponData.SweepContact(nil, justOut, Vector3.new(0, 0, -3), look, reach, cosLimit, H, S) ~= nil
			and WeaponData.SweepContact(nil, justOut, Vector3.zero, look, reach, cosLimit, H, S) == nil,
		"a little of what the swinger saw: a target 2 studs past reach that was inside it a moment ago")
	check(C.HitRewindMaxStuds <= 8 and C.HitRewindMaxSeconds <= 0.2,
		string.format("and the rewind is capped at %.0f studs / %.2fs", C.HitRewindMaxStuds, C.HitRewindMaxSeconds))
	check(C.HitWindowLead + C.HitWindowTrail <= 0.25,
		string.format("the window is short: %.2fs before the visible contact, %.2fs after", C.HitWindowLead,
			C.HitWindowTrail))
end

--==============================================================================
-- THE HARNESS (TrapSystemSpec's)
--==============================================================================
local clock = 1000
local fakeOs = setmetatable({ clock = function()
	return clock
end }, { __index = os })

local function signal()
	return { Connect = function()
		return { Disconnect = function() end }
	end }
end

local fakePlayers = {}
fakePlayers.PlayerRemoving = signal()
fakePlayers.PlayerAdded = signal()
local roster = {}
function fakePlayers:GetPlayers()
	return roster
end

local fixture = Instance.new("Folder")
fixture.Name = "BatHitSpecFixture"
fixture.Parent = Workspace

local GROUND_Y = 940
local ground = Instance.new("Part")
ground.Name = "SpecGround"
ground.Size = Vector3.new(240, 4, 240)
ground.Position = Vector3.new(4000, GROUND_Y - 2, 4000)
ground.Anchored = true
ground.Parent = fixture

local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = { ... } })
end
local function count(name)
	local n = 0
	for _, e in ipairs(trace) do
		if e.name == name then
			n += 1
		end
	end
	return n
end
local function first(name)
	for i, e in ipairs(trace) do
		if e.name == name then
			return i, e
		end
	end
	return nil, nil
end

local Y = GROUND_Y + 3
local function makeCharacter(at: Vector3, facing: Vector3?): Model
	local character = Instance.new("Model")
	character.Name = "SpecBody"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = CFrame.lookAt(at, at + (facing or Vector3.new(0, 0, -1)))
	root.Anchored = true
	root.CanCollide = false
	root.Parent = character
	character.PrimaryPart = root
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	character.Parent = fixture
	return character
end

local function makePlayer(name, userId, at, facing)
	local attributes = {}
	local player
	player = {
		Name = name,
		UserId = userId,
		Parent = fakePlayers,
		Character = makeCharacter(at, facing),
		CharacterRemoving = signal(),
		CharacterAdded = signal(),
		ChildAdded = signal(),
		GetAttribute = function(_, key)
			return attributes[key]
		end,
		SetAttribute = function(_, key, value)
			attributes[key] = value
		end,
		FindFirstChildOfClass = function()
			return nil
		end,
	}
	player.attributes = attributes
	player.MoveTo = function(where: Vector3, facing: Vector3?)
		local root = player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.lookAt(where, where + (facing or root.CFrame.LookVector))
		end
	end
	player.Root = function()
		return player.Character:FindFirstChild("HumanoidRootPart")
	end
	table.insert(roster, player)
	return player
end

local safeRule: ((Vector3) -> boolean)? = nil
local MapService = {
	IsInSafeZone = function(at)
		return safeRule ~= nil and safeRule(at)
	end,
	GetMap = function()
		return fixture
	end,
}

local holding = {}
local CarryService = {
	IsCarrying = function(p)
		return holding[p] == "carry"
	end,
	HoldsPod = function(p)
		return holding[p] ~= nil
	end,
	DropHeldPod = function(p, at)
		local kind = holding[p]
		record("Drop", p, at, kind)
		if not kind then
			return false, nil
		end
		holding[p] = nil
		return true, kind
	end,
	Drop = function()
		return false
	end,
	RefreshWalkSpeed = function(p)
		record("RefreshWalkSpeed", p)
	end,
}
local bridge = nil
local NestService = {
	SetCombatBridge = function(given)
		bridge = given
	end,
	RagdollOn = function(character)
		record("RagdollOn", character)
		return { character }
	end,
	RagdollOff = function(set)
		record("RagdollOff", set)
	end,
}
local held = {}
local WeaponShopService = {
	HeldItem = function(p)
		return held[p]
	end,
}
local SoundKit = { emit = function() end, play = function() end }

local heartbeat = nil
local fakeRun = { Heartbeat = { Connect = function(_, fn)
	heartbeat = fn
	return { Disconnect = function()
		heartbeat = nil
	end }
end } }

local throwSent = {}
local fakeThrow = {
	IsA = function(_, className)
		return className == "RemoteEvent"
	end,
	FireClient = function(_, victim, dir, speed, lift, clear, hold, style)
		table.insert(throwSent, { victim = victim, dir = dir, speed = speed, style = style })
		record("Throw", victim, speed)
	end,
	OnServerEvent = signal(),
}
local realSeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local fakeRemotes = { FindFirstChild = function(_, name)
	return if name == GameConfig.Remotes.ThrowVictim then fakeThrow else nil
end }
local fakeSeedGame = {
	WaitForChild = function(_, name)
		return realSeedGame:WaitForChild(name)
	end,
	FindFirstChild = function(_, name)
		if name == "Remotes" then
			return fakeRemotes
		end
		return realSeedGame:FindFirstChild(name)
	end,
}
local fakeReplicated = { WaitForChild = function(_, name)
	return if name == "SeedGame" then fakeSeedGame else ReplicatedStorage:WaitForChild(name)
end }
local fakeGame = {}
function fakeGame:GetService(name)
	if name == "Players" then
		return fakePlayers
	elseif name == "RunService" then
		return fakeRun
	elseif name == "ReplicatedStorage" then
		return fakeReplicated
	end
	return game:GetService(name)
end

local outerRequire = require
local function loadWith(module, siblings)
	local chunk, err = loadstring(module.Source, "=" .. module.Name)
	assert(chunk, tostring(err))
	local parent = {}
	function parent:WaitForChild(name)
		local sibling = siblings[name]
		assert(sibling ~= nil, module.Name .. " asked for an unexpected sibling " .. name)
		return { __standIn = sibling }
	end
	setfenv(chunk, setmetatable({
		game = fakeGame,
		os = fakeOs,
		script = { Name = module.Name, Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) }))
	return chunk()
end

local FRAME = 1 / 60
local function step(by: number)
	clock += by
	if heartbeat then
		heartbeat()
	end
end
-- Runs frames until `seconds` have passed, calling `each(t)` before every frame
-- with the time since `t0`.
local function frames(seconds: number, dt: number, each: ((number) -> ())?)
	local t0 = clock
	while clock - t0 < seconds - 1e-9 do
		if each then
			each(clock - t0 + dt)
		end
		step(dt)
	end
end
local function settle()
	step(4)
	task.wait(0.75)
	step(0.1)
end

local CombatService = nil
local swinger, victim, third = nil, nil, nil
local refusals = {}

local function batTool(player, id)
	local item = WeaponData.Get(id or "rootwood_bat")
	local t = Instance.new("Tool")
	t.Name = item.Name
	t.RequiresHandle = false
	t:SetAttribute(WeaponModel.ItemAttribute, item.Id)
	t.Parent = player.Character
	held[player] = item
	return t, item
end

local function swing(player, tool, item)
	CombatService.RequestSwing(player, item, tool)
end

-- Clears every clock between cases: cooldowns, immunity, a launch's backstop --
-- and every trap a case set, since a trap no longer expires (2026-10-04).
local function fresh()
	if CombatService and victim then
		CombatService.ClearTrap(victim)
	end
	settle()
	step(10)
	trace = {}
	throwSent = {}
	refusals = {}
	safeRule = nil
end

local function run()
	local origin = Vector3.new(4000, Y, 4000)
	swinger = makePlayer("SpecSwinger", 5001, origin, Vector3.new(0, 0, -1))
	victim = makePlayer("SpecVictim", 5002, origin + Vector3.new(30, 0, -30))
	third = makePlayer("SpecThird", 5003, origin + Vector3.new(-30, 0, -30))
	ActionRefusal.capture(function(p, code)
		table.insert(refusals, { player = p, code = code })
	end)

	local ok, err = pcall(function()
		CombatService = loadWith(Server.CombatService, {
			GameConfig = GameConfig,
			SoundKit = SoundKit,
			WeaponData = WeaponData,
			WeaponModel = WeaponModel,
			MapService = MapService,
			CarryService = CarryService,
			NestService = NestService,
			WeaponShopService = WeaponShopService,
		})
		CombatService.Init()
		CombatService.Start()
	end)
	check(ok and heartbeat ~= nil, "CombatService loads and starts", err)
	if not ok then
		return
	end
	local tool, item = batTool(swinger, "rootwood_bat")

	--==========================================================================
	say("\n-- the window --")
	--==========================================================================
	-- The victim stands square in front, in reach, the whole time.
	victim.MoveTo(origin + Vector3.new(0, 0, -6))
	swing(swinger, tool, item)
	check(type(tool:GetAttribute("SwingAt")) == "number" and tool:GetAttribute("SwingWindup") == item.Windup,
		"the press publishes the tell (SwingAt, Windup) for every client to draw")
	frames(item.Windup - C.HitWindowLead - 0.02, FRAME)
	check(count("Throw") == 0, "nothing is struck before the window opens")
	frames(0.05, FRAME)
	check(count("Throw") == 1 and throwSent[1].victim == victim,
		"a body in front is struck inside the window, around the visible contact")
	check(type(tool:GetAttribute("HitAt")) == "number",
		"and the impact burst is stamped at the accepted hit")
	frames(0.3, FRAME)
	check(count("Throw") == 1, "ONE hit per target per swing, however long they stay in front")

	--==========================================================================
	say("\n-- a fast crossing target --")
	--==========================================================================
	fresh()
	-- A slow server frame (0.1s) and a fast crossing (100 studs/s): the body is
	-- outside the swing on both frames and inside it in between. 13 studs ahead,
	-- from 6 left to 4 right -- the geometry section's case, on the server.
	victim.MoveTo(origin + Vector3.new(-6, 0, -13))
	swing(swinger, tool, item)
	frames(item.Windup - C.HitWindowLead + FRAME, FRAME)
	check(count("Throw") == 0, "(on the window's first frame the victim is just outside the swing)")
	victim.MoveTo(origin + Vector3.new(4, 0, -13))
	step(0.1)
	check(count("Throw") == 1, "a target crossing the front between two slow frames is HIT by the sweep",
		count("Throw"))
	frames(0.2, FRAME)

	--==========================================================================
	say("\n-- refused --")
	--==========================================================================
	-- A teleport-sized jump straight through the swing.
	fresh()
	victim.MoveTo(origin + Vector3.new(-40, 0, -8))
	swing(swinger, tool, item)
	frames(item.Windup - C.HitWindowLead + FRAME, FRAME)
	victim.MoveTo(origin + Vector3.new(40, 0, -8))
	frames(C.HitWindowLead + C.HitWindowTrail, FRAME)
	check(count("Throw") == 0, "a body that JUMPED 80 studs through the swing in one frame is not swept: no hit")

	-- A wall between them.
	fresh()
	local wall = Instance.new("Part")
	wall.Name = "SpecWall"
	wall.Size = Vector3.new(30, 12, 1)
	wall.Anchored = true
	wall.Position = origin + Vector3.new(0, 3, -3)
	wall.Parent = fixture
	victim.MoveTo(origin + Vector3.new(0, 0, -6))
	swing(swinger, tool, item)
	frames(item.Windup + C.HitWindowTrail + 0.05, FRAME)
	check(count("Throw") == 0, "a wall between them: no hit through it")
	wall:Destroy()

	-- The safe field, at the victim's end.
	fresh()
	safeRule = function(at)
		return at.Z < 3994
	end
	victim.MoveTo(origin + Vector3.new(0, 0, -7))
	swing(swinger, tool, item)
	frames(item.Windup + C.HitWindowTrail + 0.05, FRAME)
	check(count("Throw") == 0 and #refusals == 1 and refusals[1].code == "SAFE_ZONE_TARGET",
		"a target in the safe field is spared, and the swinger is told why", refusals[1] and refusals[1].code)
	-- And at the swinger's end.
	fresh()
	safeRule = function(at)
		return math.abs(at.Z - 4000) < 1
	end
	victim.MoveTo(origin + Vector3.new(0, 0, -7))
	swing(swinger, tool, item)
	frames(item.Windup + C.HitWindowTrail + 0.05, FRAME)
	check(count("Throw") == 0, "nobody is struck FROM the safe field either")

	-- An immune target (just hit, or under a trap's effect) is left alone.
	fresh()
	victim.MoveTo(origin + Vector3.new(0, 0, -6))
	swing(swinger, tool, item)
	frames(item.Windup + C.HitWindowTrail + 0.05, FRAME)
	check(count("Throw") == 1, "(a hit)")
	step(item.Cooldown)
	swing(swinger, tool, item)
	frames(item.Windup + C.HitWindowTrail + 0.05, FRAME)
	check(count("Throw") == 1, "a second swing on a body still flying from the first strikes nothing")

	-- The bat put away mid-swing.
	fresh()
	victim.MoveTo(origin + Vector3.new(0, 0, -6))
	swing(swinger, tool, item)
	frames(0.05, FRAME)
	tool.Parent = fixture
	frames(item.Windup + C.HitWindowTrail, FRAME)
	check(count("Throw") == 0, "a bat put away during the wind-up strikes nobody")
	tool.Parent = swinger.Character

	-- A swing on cooldown is not registered at all.
	fresh()
	swing(swinger, tool, item)
	local stamped = tool:GetAttribute("SwingAt")
	step(0.1)
	swing(swinger, tool, item)
	check(tool:GetAttribute("SwingAt") == stamped, "a press inside the cooldown starts nothing")
	frames(1, FRAME)

	--==========================================================================
	say("\n-- the pod comes off first --")
	--==========================================================================
	for _, kind in ipairs({ "carry", "tool" }) do
		fresh()
		holding[victim] = kind
		victim.MoveTo(origin + Vector3.new(0, 0, -6))
		swing(swinger, tool, item)
		frames(item.Windup + C.HitWindowTrail + 0.05, FRAME)
		local d, entry = first("Drop")
		local r = first("RagdollOn")
		local t = first("Throw")
		check(d ~= nil and r ~= nil and t ~= nil and d < r and d < t and count("Drop") == 1
				and entry.args[3] == kind and holding[victim] == nil,
			string.format("a %s pod comes off BEFORE the ragdoll and the launch, exactly once",
				if kind == "carry" then "raid-carried" else "banked, held"),
			string.format("drop %s ragdoll %s throw %s", tostring(d), tostring(r), tostring(t)))
	end

	--==========================================================================
	say("\n-- two swings at once --")
	--==========================================================================
	fresh()
	holding[victim] = "carry"
	-- Facing the victim from the other side, 15 studs from the first swinger, so
	-- neither attacker is inside the other's swing.
	third.MoveTo(origin + Vector3.new(0, 0, -15), Vector3.new(0, 0, 1))
	local tool3, item3 = batTool(third, "rootwood_bat")
	victim.MoveTo(origin + Vector3.new(0, 0, -6))
	swing(swinger, tool, item)
	swing(third, tool3, item3)
	frames(item.Windup + C.HitWindowTrail + 0.05, FRAME)
	check(count("Throw") == 1 and count("RagdollOn") == 1 and count("Drop") == 1,
		"two swings landing on one victim in the same frame: ONE launch, ONE pod, never two",
		string.format("throws %d drops %d", count("Throw"), count("Drop")))
	third.MoveTo(origin + Vector3.new(-30, 0, -30))
	tool3:Destroy()
	held[third] = nil

	--==========================================================================
	say("\n-- slowed swings, rooted does not --")
	--==========================================================================
	-- Hold the swinger with a real trap the victim owns.
	fresh()
	victim.MoveTo(origin + Vector3.new(0, 0, 20))
	local snare = WeaponData.Get("mirecoil_trap")
	local snareTool = Instance.new("Tool")
	snareTool:SetAttribute(WeaponModel.ItemAttribute, snare.Id)
	snareTool.Parent = fixture
	CombatService.RequestPlace(victim, snare, snareTool)
	victim.MoveTo(origin + Vector3.new(0, 0, -6))
	swinger.MoveTo(origin + Vector3.new(0, 0, 25))
	step(1.3)
	swinger.MoveTo(origin + Vector3.new(0, 0, 20.5))
	step(FRAME)
	check(swinger.attributes[ATTR.TrapSlow] == 0.35, "the swinger walks into a snare and is slowed")
	-- Turn to face the victim and swing.
	swinger.MoveTo(origin + Vector3.new(0, 0, 20.5), Vector3.new(0, 0, -1))
	local before = tool:GetAttribute("SwingAt")
	swing(swinger, tool, item)
	check(tool:GetAttribute("SwingAt") ~= before,
		"a SLOWED player can still swing (the snare's own design: still steer, still swing, still fight)")
	frames(1, FRAME)

	fresh()
	settle()
	step(25)
	swinger.MoveTo(origin)
	victim.MoveTo(origin + Vector3.new(0, 0, 20))
	local jaw = WeaponData.Get("bramblejaw_trap")
	local jawTool = Instance.new("Tool")
	jawTool:SetAttribute(WeaponModel.ItemAttribute, jaw.Id)
	jawTool.Parent = fixture
	CombatService.RequestPlace(victim, jaw, jawTool)
	victim.MoveTo(origin + Vector3.new(0, 0, -6))
	swinger.MoveTo(origin + Vector3.new(0, 0, 25))
	step(1.1)
	swinger.MoveTo(origin + Vector3.new(0, 0, 20.5), Vector3.new(0, 0, -1))
	step(FRAME)
	check(swinger.attributes[ATTR.Trapped] == true, "the swinger walks into a Bramblejaw and is rooted")
	before = tool:GetAttribute("SwingAt")
	swing(swinger, tool, item)
	check(tool:GetAttribute("SwingAt") == before, "a ROOTED player cannot swing")
	frames(1, FRAME)

	--==========================================================================
	say("\n-- a swinger who goes away --")
	--==========================================================================
	fresh()
	settle()
	step(10)
	swinger.MoveTo(origin, Vector3.new(0, 0, -1))
	victim.MoveTo(origin + Vector3.new(0, 0, -6))
	swing(swinger, tool, item)
	frames(0.05, FRAME)
	local body = swinger.Character
	swinger.Character = nil
	frames(item.Windup + C.HitWindowTrail, FRAME)
	check(count("Throw") == 0, "a swinger whose body went away mid-swing (death, respawn) strikes nobody")
	swinger.Character = body
end

local okRun, errRun = pcall(run)
if not okRun then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(errRun))
end
ActionRefusal.capture(nil)

say("\n-- read off the source --")
do
	local okRead, src = pcall(function()
		return Server.CombatService.Source
	end)
	src = if okRead then src else ""
	check(select(2, src:gsub(":LoadAnimation%(", "")) == 1 and not src:find("track.Stopped:Connect", 1, true),
		"the swing track is loaded once per body and no per-swing connection is made")
	check(not src:find("task.wait(item.Windup)", 1, true) and src:find("stepSwings(clock)", 1, true) ~= nil,
		"the hit is swept by the one Heartbeat, not resolved once after a wait")
	check(src:find("held ~= tool", 1, true) ~= nil and src:find("WeaponShopService.HeldItem(player)", 1, true) ~= nil,
		"the Tool that fired must be the one in the swinger's hands, re-read on the server")
	check(not src:find("OnServerEvent:Connect(function(player, target", 1, true),
		"and no client ever names a target")
end

fixture:Destroy()
say(string.format("\nBatHitSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
