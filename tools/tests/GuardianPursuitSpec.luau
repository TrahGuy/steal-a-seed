--!nocheck
--==============================================================================
-- Steal a Seed :: GuardianPursuitSpec
--
-- THE GUARDIAN CHASE FIXES (2026-10-01, the owner's brief). Edit mode: the pure
-- GuardianPursuit, and the REAL NestService's provoke and tick (SpecProvoke,
-- SpecStep, Studio-only) on a nest record built here, with stand-in players
-- whose bodies are real Models in ServerStorage and a stand-in carry bridge.
-- The owner's checks:
--
--   moving contact       both bodies move: a mid-tick crossing hits, a spot
--                        left before the guardian got there does not
--   stale samples        another target, a respawn, a teleport of either body
--                        or an old sample falls back to the plain distance
--   multiple thieves     remembered, not obeyed; the nearest eligible is next
--                        when the chase ends; dropped on safety, death,
--                        leaving and losing the pod; kept through the red line
--   after a hit          (2026-10-01) it stops where it hit, and from past the
--                        road's mouth walks home through it, clear of the walls
--
-- The orbit's measured cause -- the chased player's client simulating the
-- guardian -- is a Play fact; this checks only that the nest pins it.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local GP = require(Server:WaitForChild("GuardianPursuit"))
local NestService = require(Server:WaitForChild("NestService"))

local P = GameConfig.Parent
local GRAB = P.GrabStuds
local V = Vector3.new

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
local function near(a, b, eps)
	return (a - b).Magnitude <= (eps or 1e-3)
end

-- The sweep this replaced: the guardian's END position against the target's path.
local function oldSweep(parentNow, targetWas, targetNow)
	local p = V(parentNow.X, 0, parentNow.Z)
	local a, b = V(targetWas.X, 0, targetWas.Z), V(targetNow.X, 0, targetNow.Z)
	local ab = b - a
	local len2 = ab:Dot(ab)
	if len2 < 1e-6 then
		return (p - a).Magnitude
	end
	local t = math.clamp((p - a):Dot(ab) / len2, 0, 1)
	return (p - (a + ab * t)).Magnitude
end

local fixture = Instance.new("Folder")
fixture.Name = "GuardianPursuitSpecFixture"
fixture.Parent = game:GetService("ServerStorage")

local ok, err = pcall(function()
	--==========================================================================
	-- 1. MOVING CONTACT
	--==========================================================================
	say("-- moving contact --")
	-- Crossing at right angles, meeting mid-tick; 14 studs apart at both ends.
	local cross = GP.closestApproach(V(0, 0, -10), V(0, 0, 10), V(-10, 0, 0), V(10, 0, 0))
	check(cross <= GRAB and oldSweep(V(0, 0, 10), V(-10, 0, 0), V(10, 0, 0)) > GRAB,
		"two bodies crossing mid-tick are a hit (the old sweep, end against path, missed it)", cross)
	-- The guardian reaches a spot the player left a tick earlier.
	local left = GP.closestApproach(V(0, 0, 0), V(0, 0, 12), V(0, 0, 13), V(18, 0, 13))
	check(left > GRAB and oldSweep(V(0, 0, 12), V(0, 0, 13), V(18, 0, 13)) <= GRAB,
		"a spot the player left before the guardian got there is not a hit (the old sweep hit it)", left)
	check(GP.closestApproach(V(0, 0, 0), V(0, 0, 6.8), V(0, 0, 12), V(0, 0, 17.04)) > GRAB,
		"a straight chase still closing (12 -> 10.2) is not a hit yet")
	check(GP.closestApproach(V(0, 0, 10), V(0, 0, 16.8), V(0, 0, 17), V(0, 0, 22.04)) <= GRAB,
		"and is one the tick the gap closes inside GrabStuds")
	check(GP.closestApproach(V(0, 0, 0), V(0, 0, 7), V(0, 3, 20), V(0, 3, 2)) <= GRAB,
		"running head-on through each other between two ticks is a hit")
	check(GP.closestApproach(V(0, 0, 0), V(9, 0, 0), V(0, 0, 9), V(9, 0, 9)) > GRAB,
		"two bodies moving together keep their gap")
	check(GP.closestApproach(V(0, 0, 0), V(0, 0, 0), V(0, 40, 5), V(0, 40, 5)) <= GRAB,
		"height is ignored: a jump does not read as distance")

	--==========================================================================
	-- 2. STALE AND BROKEN SAMPLES
	--==========================================================================
	say("\n-- stale and broken samples --")
	local A, B = {}, {}
	local bodyA, bodyA2 = {}, {}
	local S = { target = A, body = bodyA, parentAt = V(0, 0, 0), targetAt = V(0, 0, 12), at = 10 }
	local function usable(sample, target, body, parentNow, targetNow, now)
		return GP.sampleUsable(sample, target, body, parentNow, targetNow, now, 40, 0.5)
	end
	check(usable(S, A, bodyA, V(0, 0, 6.8), V(0, 0, 17), 10.12), "a sample one tick old, same target and body, is used")
	check(not usable(nil, A, bodyA, V(0, 0, 6.8), V(0, 0, 17), 10.12), "no sample: the plain distance")
	check(not usable(S, B, bodyA, V(0, 0, 6.8), V(0, 0, 17), 10.12), "another target: refused")
	check(not usable(S, A, bodyA2, V(0, 0, 6.8), V(0, 0, 17), 10.12), "the same player's new body (a respawn): refused")
	check(not usable(S, A, bodyA, V(0, 0, 6.8), V(0, 0, 72), 10.12), "the target teleported 60 studs: refused")
	check(not usable(S, A, bodyA, V(0, 0, 50), V(0, 0, 17), 10.12), "the guardian put back home (50 studs): refused")
	check(not usable(S, A, bodyA, V(0, 0, 6.8), V(0, 0, 17), 10.61), "older than half a second: refused")
	check(not usable(S, A, bodyA, V(0, 0, 6.8), V(0, 0, 17), 10), "not older than this tick: refused")
	local through = GP.closestApproach(V(0, 0, 0), V(0, 0, 0), V(-100, 0, 0), V(100, 0, 0))
	local T = { target = A, body = bodyA, parentAt = V(0, 0, 0), targetAt = V(-100, 0, 0), at = 10 }
	check(through == 0 and not usable(T, A, bodyA, V(0, 0, 0), V(100, 0, 0), 10.12),
		"a teleport straight through the guardian would sweep a hit, and is refused instead")

	--==========================================================================
	-- 3. WHICH WAY IT RUNS
	--==========================================================================
	say("\n-- steering --")
	local LEAD, CLOSE = 0.12, P.ChaseLeadStuds
	local look = V(0, 0, -1)
	check(near(GP.heading(V(0, 0, 0), V(0, 0, 50), V(0, 0, 42), LEAD, CLOSE, look), V(0, 0, 1)),
		"a target running straight away at range: straight at them")
	check(near(GP.heading(V(0, 0, 0), V(0, 0, 12), V(0, 0, 42), LEAD, CLOSE, look), V(0, 0, 1)),
		"and close in: still straight at them (the lead lies along the line)")
	local strafe = GP.heading(V(0, 0, 0), V(0, 0, 10), V(42, 0, 0), LEAD, CLOSE, look)
	check(strafe.X > 0.3 and strafe.Z > 0.8,
		"a target strafing at 10 studs: the line bends toward where they will be", strafe)
	check(near(GP.heading(V(0, 0, 0), V(0, 0, 60), V(42, 0, 0), LEAD, CLOSE, look), V(0, 0, 1)),
		"the same strafe at 60 studs: no lead, the old straight line")
	check(near(GP.heading(V(0, 0, 0), V(0, 0, 10), nil, LEAD, CLOSE, look), V(0, 0, 1)),
		"no usable sample (no velocity): no lead")
	local capped = GP.heading(V(0, 0, 0), V(0, 0, 5), V(150, 0, 0), LEAD, CLOSE, look)
	check(near(capped, V(1, 0, 1).Unit), "the lead is never longer than the gap (45 degrees at most)", capped)
	check(near(GP.heading(V(0, 0, 0), V(0, 0, 0), nil, LEAD, CLOSE, look), look),
		"standing on top of them: keeps facing forward")

	--==========================================================================
	-- 4. THE MEMORY, PURE
	--==========================================================================
	say("\n-- the memory --")
	check(GP.takesOver(nil, A, false) and GP.takesOver(A, A, true) and not GP.takesOver(A, B, true)
			and GP.takesOver(A, B, false),
		"a new thief takes over only from nobody, from themselves, or from a target that cannot be chased")
	local C, D = {}, {}
	local where = { [B] = V(0, 0, 50), [C] = V(0, 0, 20) }
	local list = { [B] = 1, [C] = 2, [D] = 3 }
	local picked = GP.nextThief(list, V(0, 0, 0), function(p)
		return where[p]
	end)
	check(picked == C and list[C] == nil and list[D] == nil and list[B] == 1,
		"the nearest eligible is taken out; the ineligible are dropped; the rest stay")
	check(GP.nextThief({}, V(0, 0, 0), function()
		return V(0, 0, 0)
	end) == nil, "nobody left: nil")

	--==========================================================================
	-- 5. THE REAL NESTSERVICE: PROVOKE, THE TICK, THE EXITS
	--==========================================================================
	say("\n-- NestService --")
	local dustbowl
	for _, b in ipairs(BiomeData.Biomes) do
		if b.Id == "dustbowl" then
			dustbowl = b
		end
	end
	local HOME = V(38, 3, -715)
	local SAFE = V(0, 3, 40)
	local function makeBody(name, at)
		local model = Instance.new("Model")
		model.Name = name
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Anchored = true
		root.Position = at
		root.Parent = model
		Instance.new("Humanoid").Parent = model
		model.Parent = fixture
		return model
	end
	local function makePlayer(name, at)
		return { Name = name, UserId = 0, Parent = Players, Character = makeBody(name, at) }
	end
	local function moveTo(player, at)
		player.Character.HumanoidRootPart.Position = at
	end
	local function makeNest()
		local model = Instance.new("Model")
		model.Name = "SpecGuardian"
		model.Parent = fixture
		local root = Instance.new("Part")
		root.Name = "HumanoidRootPart"
		root.Anchored = true
		root.Position = HOME
		root.Parent = model
		return {
			id = "Nest_spec_01", biome = dustbowl, origin = HOME, homeCFrame = CFrame.new(HOME),
			parent = model, root = root, folder = fixture, slots = {}, pods = {},
			humanoid = { WalkSpeed = 0, moves = {}, MoveTo = function(self, p)
				table.insert(self.moves, p)
			end },
			state = "chasing", target = nil, stateUntil = 0, busy = false, rage = 0, calmSince = 0,
			chaseSince = os.clock(), haul = nil, sample = nil, thieves = {},
		}
	end
	local carrying = {}
	NestService.SetCarryBridge({ CarriedFrom = function(p)
		return carrying[p]
	end })
	local clock = 100
	local function tick(nest)
		clock += 0.12
		NestService.SpecStep(nest, clock)
	end

	local nest = makeNest()
	local p1 = makePlayer("Thief1", V(38, 3, -650))
	local p2 = makePlayer("Thief2", V(38, 3, -600))
	local p3 = makePlayer("Thief3", V(38, 3, -680))
	carrying[p1], carrying[p2], carrying[p3] = nest.id, nest.id, nest.id
	nest.target = p1

	NestService.SpecProvoke(nest, p2)
	check(nest.target == p1 and nest.thieves[p2] ~= nil and nest.rage == 1,
		"a second thief mid-chase is remembered; the chase stays on the first; rage still stacks")
	NestService.SpecProvoke(nest, p1)
	check(nest.target == p1 and nest.thieves[p1] == nil and nest.rage == 2, "the same thief again is still the target")

	tick(nest)
	local s = nest.sample
	check(s ~= nil and s.target == p1 and s.body == p1.Character and s.parentAt == nest.root.Position
			and s.targetAt == p1.Character.HumanoidRootPart.Position and s.at == clock,
		"a tick samples both bodies at the same moment, on the nest")
	local aim = nest.humanoid.moves[#nest.humanoid.moves]
	check(aim ~= nil and near(aim, V(38, 3, -650) + V(0, 0, 1) * P.ChaseOvershootStuds),
		"at range it aims ChaseOvershootStuds past them, straight along the line", aim)

	moveTo(p1, SAFE)
	tick(nest)
	check(nest.target == p2 and nest.state == "chasing" and nest.sample == nil and next(nest.thieves) == nil,
		"the first reaches safety: the remembered thief is chased at once, with a fresh sweep")

	-- The nearest of two goes first.
	nest = makeNest()
	moveTo(p1, V(38, 3, -650))
	nest.target = p1
	NestService.SpecProvoke(nest, p2)
	NestService.SpecProvoke(nest, p3)
	moveTo(p1, SAFE)
	tick(nest)
	check(nest.target == p3 and nest.thieves[p2] ~= nil, "two remembered: the nearer (35 studs) before the farther (115)")

	-- Clearing: no pod, death, leaving, safety.
	carrying[p2] = nil
	tick(nest)
	check(nest.thieves[p2] == nil, "a remembered thief who no longer carries this nest's pod is dropped")
	local p4 = makePlayer("Thief4", V(38, 3, -640))
	local p5 = makePlayer("Thief5", V(38, 3, -630))
	local p6 = makePlayer("Thief6", V(38, 3, -620))
	carrying[p4], carrying[p5], carrying[p6] = nest.id, nest.id, nest.id
	NestService.SpecProvoke(nest, p4)
	NestService.SpecProvoke(nest, p5)
	NestService.SpecProvoke(nest, p6)
	p4.Character:FindFirstChildOfClass("Humanoid").Health = 0
	p5.Parent = nil
	moveTo(p6, SAFE)
	tick(nest)
	check(nest.thieves[p4] == nil and nest.thieves[p5] == nil and nest.thieves[p6] == nil and nest.target == p3,
		"dead, gone and safe thieves are dropped; the current chase is untouched")
	carrying[p2] = "Nest_other_02"
	NestService.SpecProvoke(nest, p2)
	tick(nest)
	check(nest.thieves[p2] == nil, "carrying another nest's pod is not this nest's thief")

	-- The red line still ends a chase, and memory survives it.
	carrying[p2] = nest.id
	NestService.SpecProvoke(nest, p2)
	nest.root.Position = SAFE
	tick(nest)
	check(nest.target == nil and nest.state == "returning" and nest.thieves[p2] ~= nil,
		"a guardian that crosses the red line still gives up -- and keeps who it remembered")
	tick(nest)
	check(nest.target == nil and nest.state == "returning", "and does not turn on them from inside the Safe Zone")
	nest.root.Position = V(38, 3, -700)
	tick(nest)
	check(nest.target == p2 and nest.state == "chasing", "once back out on the road it does")

	-- A theft during a throw (busy, the target still being thrown).
	nest = makeNest()
	moveTo(p1, V(38, 3, -650))
	nest.target = p1
	nest.busy = true
	nest.state = "hauling"
	local p7 = makePlayer("Thief7", V(38, 3, -690))
	carrying[p7] = nest.id
	NestService.SpecProvoke(nest, p7)
	check(nest.target == p1 and nest.state == "hauling" and nest.thieves[p7] ~= nil,
		"a theft mid-throw is remembered and does not take the thrown player's place")
	-- What the throw's end leaves when its victim is still the target: endChase.
	nest.busy = false
	nest.target = nil
	nest.state = "returning"
	tick(nest)
	check(nest.target == p7 and nest.state == "chasing", "and is chased once the throw is over, before home")

	-- A theft during the walk home takes the chase at once.
	nest = makeNest()
	nest.state = "returning"
	NestService.SpecProvoke(nest, p3)
	check(nest.target == p3 and nest.state == "chasing", "a theft during the walk home is chased at once")

	-- A respawn mid-chase is a new body: no sweep from the old one, no lead.
	nest = makeNest()
	moveTo(p3, V(33, 3, -703))
	nest.target = p3
	tick(nest)
	moveTo(p3, V(38, 3, -703))
	tick(nest)
	local led = nest.humanoid.moves[#nest.humanoid.moves]
	check(led ~= nil and led.X > 38.5, "strafing 12 studs off, the order leads them", led)
	nest = makeNest()
	moveTo(p3, V(33, 3, -703))
	nest.target = p3
	tick(nest)
	local old = p3.Character
	p3.Character = makeBody("Thief3Respawned", V(38, 3, -703))
	tick(nest)
	local plain = nest.humanoid.moves[#nest.humanoid.moves]
	check(plain ~= nil and math.abs(plain.X - 38) < 1e-3 and nest.sample.body == p3.Character,
		"after a respawn the old body's sample is refused: no lead, a new sample", plain)
	old:Destroy()

	-- A guardian walking home with nobody eligible lies down with nothing remembered.
	nest = makeNest()
	nest.state = "returning"
	nest.thieves[p6] = 1
	tick(nest)
	check(nest.state == "asleep" and next(nest.thieves) == nil and nest.target == nil and nest.sample == nil,
		"home with nobody eligible: asleep, memory and sample clear")

	--==========================================================================
	-- 5b. THE WAY HOME AFTER A HIT AT THE ROAD'S MOUTH (2026-10-01)
	--
	-- Measured in Play before the fix: the hit left the chase's overshoot order
	-- standing, the guardian ran on through the throw into the field, and the
	-- straight walk home stood against the right wall's end at (76.1, -168.4).
	--==========================================================================
	say("\n-- the way home --")
	local MAP = GameConfig.Map
	local MOUTH, HALF = -MAP.FieldFront, MAP.CorridorWidth * 0.5
	local WALL_T = MAP.WallThickness
	local REACH = 4
	local CLEAR, INSET = HALF - REACH - 1.5, REACH + 4
	local function route(at, home)
		return GP.routeHome(at, home, MOUTH, CLEAR, INSET)
	end
	-- How far a body centred here is from either wall (the walls end at MOUTH).
	local function wallGap(at)
		local gap = math.huge
		for _, side in ipairs({ -1, 1 }) do
			local lo, hi = math.min(side * HALF, side * (HALF + WALL_T)), math.max(side * HALF, side * (HALF + WALL_T))
			local dx = math.max(lo - at.X, 0, at.X - hi)
			local dz = math.max(at.Z - MOUTH, 0)
			gap = math.min(gap, math.sqrt(dx * dx + dz * dz))
		end
		return gap
	end
	-- Follows the orders a stud at a time; the closest it came to a wall, and
	-- whether it got home. A Humanoid stops short of its MoveTo point and
	-- stands, so arriving within a stud of any order but home is a deadlock:
	-- every other order has to be replaced on the way (measured in Play).
	local function walk(from, home)
		local at, closest = from, wallGap(from)
		for _ = 1, 4000 do
			local goal = route(at, home)
			local step = V(goal.X - at.X, 0, goal.Z - at.Z)
			if step.Magnitude < 1 then
				return closest, goal == home
			end
			at += step.Unit
			closest = math.min(closest, wallGap(at))
		end
		return closest, false
	end
	local HOME_R, HOME_L = V(38, 3, -715), V(-38, 3, -415)
	check(route(V(60, 3, -200), HOME_R) == HOME_R and route(V(-69, 3, -171), HOME_L) == HOME_L,
		"inside the corridor the way home is the straight line it always was")
	local stuck = V(76.1, 3, -168.4)
	local first = route(stuck, HOME_R)
	check(first.Z > MOUTH and math.abs(first.X - (CLEAR - 1)) < 1e-6,
		"from the spot it stood stuck at, it first lines up in front of the mouth, clear of the wall", first)
	local second = route(V(first.X, 3, first.Z), HOME_R)
	check(second.Z < MOUTH and second.X == first.X and route(V(second.X, 3, second.Z), HOME_R) == HOME_R,
		"then walks straight in, then home", second)
	local short = route(V(CLEAR + 0.6, 3, first.Z + 0.3), HOME_R)
	check(short.Z < MOUTH,
		"stopping short of the lined-up spot (0.6 studs wide, as a hauler did in Play) still counts as lined up",
		short)
	local leftFirst = route(V(-73.8, 3, -131.2), HOME_L)
	check(leftFirst.Z > MOUTH and math.abs(leftFirst.X + (CLEAR - 1)) < 1e-6,
		"the same at the left wall, where the measured guardian ran 40 studs into the field", leftFirst)
	local worst, allHome, spots = math.huge, true, 0
	for x = -110, 110, 11 do
		for _, z in ipairs({ MOUTH + REACH, MOUTH + 25, MOUTH + 60 }) do
			local from = V(x, 3, z)
			if wallGap(from) > REACH then
				spots += 1
				for _, home in ipairs({ HOME_R, HOME_L }) do
					local closest, arrived = walk(from, home)
					worst = math.min(worst, closest)
					allHome = allHome and arrived
				end
			end
		end
	end
	check(spots > 50 and allHome and worst > REACH,
		string.format("from %d spots in front of the mouth, to either nest: always home, never within its reach of a "
			.. "wall", spots),
		string.format("closest %.2f, home %s", worst, tostring(allHome)))
	local straightGap = math.huge
	for i = 0, 200 do
		local t = i / 200
		straightGap = math.min(straightGap, wallGap(stuck:Lerp(HOME_R, t)))
	end
	check(straightGap < REACH, "and the straight line it used to walk from there does run into the wall's end",
		straightGap)

	-- The real tick, on a guardian walking home from that spot.
	nest = makeNest()
	nest.state = "returning"
	nest.root.Position = V(76.1, 3, -168.4)
	tick(nest)
	local order1 = nest.humanoid.moves[#nest.humanoid.moves]
	local nestReach = nest.reach or -1
	check(order1 ~= nil and order1.Z > MOUTH and math.abs(order1.X) <= HALF - nestReach - 1.5 + 1e-6
			and nestReach > 0,
		"NestService: a guardian walking home from past the mouth is sent in front of it first, not at its nest",
		order1)
	nest.root.Position = order1
	tick(nest)
	local order2 = nest.humanoid.moves[#nest.humanoid.moves]
	nest.root.Position = V(order2.X, 3, MOUTH - 1)
	tick(nest)
	local order3 = nest.humanoid.moves[#nest.humanoid.moves]
	check(order2.Z < MOUTH and math.abs(order2.X - order1.X) < 1e-6 and order3.X == HOME.X and order3.Z == HOME.Z,
		"then inside, then home", tostring(order2) .. " / " .. tostring(order3))

	--==========================================================================
	-- 6. THE WIRING THAT A TICK CANNOT REACH
	--==========================================================================
	say("\n-- wiring --")
	local src = Server:WaitForChild("NestService").Source
	local function body(name)
		local at = string.find(src, "local function " .. name .. "(", 1, true) or 0
		return string.sub(src, at, (string.find(src, "\nend\n", at, true) or at))
	end
	check(string.find(body("pinToServer"), "pcall(root.SetNetworkOwner, root, nil)", 1, true) ~= nil
			and string.find(body("buildNest"), "pinToServer(nest)", 1, true) ~= nil
			and string.find(body("takeNextThief"), "pinToServer(nest)", 1, true) ~= nil
			and string.find(body("provoke"), "pinToServer(nest)", 1, true) ~= nil,
		"the server owns every guardian: pinned at build and at the start of every chase")
	check(string.find(src, "nest.busy = false\n\t\t\t\tif nest.target == victim or nest.target == nil then\n"
			.. "\t\t\t\t\tendChase(nest)", 1, true) ~= nil,
		"the throw's end goes through endChase, so the next thief comes before home")
	check(string.find(src, "lastTargetAt", 1, true) == nil and string.find(src, "distanceToSegment(", 1, true) == nil,
		"no player-keyed sample and no end-against-path sweep is left")
	local hitAt = string.find(src, "if reach <= P.GrabStuds then", 1, true)
	local halt = hitAt and string.find(src, "nest.humanoid:MoveTo(nest.root.Position)", hitAt, true)
	local throwAt = hitAt and string.find(src, "task.spawn(function()", hitAt, true)
	check(halt ~= nil and throwAt ~= nil and halt < throwAt
			and string.find(string.sub(src, halt, throwAt), "AssemblyLinearVelocity = Vector3.new(0, drift.Y, 0)", 1, true)
				~= nil,
		"a hit stops the guardian where it stands, momentum and all, before the throw starts")
	check(string.find(body("walkHome"), "GuardianPursuit.routeHome(", 1, true) ~= nil,
		"the walk home (and the haul, which walks the same way) goes through routeHome")
end)

NestService.SetCarryBridge(nil)
fixture:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nGuardianPursuitSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
