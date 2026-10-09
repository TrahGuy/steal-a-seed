--!nocheck
--==============================================================================
-- Steal a Seed :: GuardianHandOffSpec
--
-- THE GUARDIAN TURNS ON THE NEXT THIEF AT THE LAUNCH (2026-10-09, the owner:
-- "we gotta fix guardians first"). Their report: player 1 steals and is
-- chased, player 2 steals, the guardian catches player 1 -- and "seems
-- stopping for a while then chase" player 2. The throw yielded through the
-- victim's whole flight with the guardian `busy`.
--
-- Edit mode, the REAL NestService (SpecProvoke, SpecStep, Studio-only) and its
-- real throw, on a nest record built here and stand-in players whose bodies
-- are real Models in ServerStorage:
--
--   1. two thieves   a catch of A while B is remembered: within a couple of
--                    frames of A's launch the guardian is chasing B, free, at
--                    the ramp's top -- while A is still in the air; A is never
--                    re-targeted mid-flight, and is chased once landed; A's
--                    throw still completes and puts A back on their feet
--   2. nobody else   unchanged: busy through the flight, then home
--   3. a late thief  robbing it while the victim is in the air: chased at once
--   4. the ramp      a hand-off runs at the profile's top speed; a chase
--                    started any other way still opens at its opening speed
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local NestService = require(Server:WaitForChild("NestService"))

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

local fixture = Instance.new("Folder")
fixture.Name = "GuardianHandOffSpecFixture"
fixture.Parent = game:GetService("ServerStorage")

local function biomeOf(id)
	for _, b in ipairs(BiomeData.Biomes) do
		if b.Id == id then
			return b
		end
	end
	return nil
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
local function makeNest(biomeId, species)
	local model = Instance.new("Model")
	model.Name = "SpecGuardian"
	if species then
		model:SetAttribute("Species", species)
	end
	model.Parent = fixture
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.Position = HOME
	root.Parent = model
	return {
		id = "Nest_spec_handoff", biome = biomeOf(biomeId), origin = HOME, homeCFrame = CFrame.new(HOME),
		parent = model, root = root, folder = fixture, slots = {}, pods = {},
		humanoid = { WalkSpeed = 0, moves = {}, MoveTo = function(self, p)
			table.insert(self.moves, p)
		end },
		state = "chasing", target = nil, stateUntil = 0, busy = false, rage = 0, calmSince = 0,
		chaseSince = os.clock(), haul = nil, sample = nil, thieves = {}, marked = {},
	}
end
local carrying = {}
local clock = 100
local function tick(nest)
	clock += 0.12
	NestService.SpecStep(nest, clock)
end
-- Polled every frame until `cond` holds or `seconds` pass; answers whether it held and how long it took.
local function waitFor(cond, seconds)
	local t0 = os.clock()
	while not cond() do
		if os.clock() - t0 > seconds then
			return false, os.clock() - t0
		end
		task.wait()
	end
	return true, os.clock() - t0
end
-- Ends a victim's flight now, as its client's answer would (AcceptThrowAnswer with the throw's own token).
local function land(player)
	local token = NestService.SpecThrowState(player)
	if token then
		NestService.AcceptThrowAnswer(player, token, nil)
	end
	return waitFor(function()
		return NestService.SpecThrowState(player) == nil
	end, 2)
end
-- The guardian's root right beside a thief: the next tick's contact.
local function closeOn(nest, player)
	nest.root.Position = player.Character.HumanoidRootPart.Position + V(0, 0, 1)
end

local ok, err = pcall(function()
	NestService.SetCarryBridge({ CarriedFrom = function(p)
		return carrying[p]
	end })

	--==========================================================================
	say("1. Two thieves")
	--==========================================================================
	local nest = makeNest("dustbowl")
	local a = makePlayer("ThiefA", V(38, 3, -650))
	local b = makePlayer("ThiefB", V(38, 3, -590))
	carrying[a], carrying[b] = nest.id, nest.id
	nest.target = a
	NestService.SpecProvoke(nest, b)
	check(nest.target == a and nest.thieves[b] ~= nil, "chasing A; B robbed it too and is remembered")
	closeOn(nest, a)
	tick(nest)
	check(nest.busy == true and nest.target == a, "the guardian reaches A: the catch")
	local handed, took = waitFor(function()
		return nest.target == b
	end, 1)
	local aloft = NestService.SpecThrowState(a) ~= nil
	check(handed and took < 0.5 and nest.state == "chasing" and nest.busy == false and nest.rampDone == true,
		"at A's launch it is already chasing B, free, at the ramp's top", string.format("%.2fs", took))
	check(aloft, "while A is still in the air (the flight runs on by itself)")
	-- A, still flying, is a thief it would otherwise chase: marked by the secret encounter.
	nest.marked[a] = true
	nest.thieves[a] = os.clock()
	moveTo(b, SAFE)
	tick(nest)
	check(nest.target ~= a and NestService.SpecThrowState(a) ~= nil and nest.thieves[a] ~= nil,
		"B reaches safety: A, still in the air, is not chased -- and is still remembered",
		tostring(nest.target and nest.target.Name))
	local landed = land(a)
	local hum = a.Character:FindFirstChildOfClass("Humanoid")
	check(landed and hum.PlatformStand == false and hum.WalkSpeed > 0,
		"A's throw completes: back on their feet, walking again", string.format("%s %s", tostring(hum.PlatformStand),
			tostring(hum.WalkSpeed)))
	tick(nest)
	check(nest.target == a and nest.state == "chasing", "and once landed, A is chased")

	--==========================================================================
	say("\n2. Nobody else: unchanged")
	--==========================================================================
	local nest2 = makeNest("dustbowl")
	local c = makePlayer("ThiefC", V(38, 3, -650))
	carrying[c] = nest2.id
	nest2.target = c
	closeOn(nest2, c)
	tick(nest2)
	task.wait(0.4)
	check(nest2.busy == true and nest2.target == c and NestService.SpecThrowState(c) ~= nil,
		"a catch with no other thief: busy through the flight, as before")
	land(c)
	waitFor(function()
		return nest2.busy == false
	end, 1)
	check(nest2.busy == false and nest2.target == nil and (nest2.state == "returning" or nest2.state == "hauling"),
		"then home, as before", nest2.state)

	--==========================================================================
	say("\n3. A thief while the victim is in the air")
	--==========================================================================
	local nest3 = makeNest("dustbowl")
	local d = makePlayer("ThiefD", V(38, 3, -650))
	local e = makePlayer("ThiefE", V(38, 3, -600))
	carrying[d], carrying[e] = nest3.id, nest3.id
	nest3.target = d
	closeOn(nest3, d)
	tick(nest3)
	task.wait(0.3)
	check(nest3.busy == true and nest3.handOff ~= nil, "D thrown, nobody else yet: held, the release ready")
	NestService.SpecProvoke(nest3, e)
	check(nest3.target == e and nest3.busy == false and nest3.state == "chasing" and nest3.rampDone == true
			and NestService.SpecThrowState(d) ~= nil and nest3.handOff == nil,
		"E robs it while D is in the air: E is chased at once, at the ramp's top")
	land(d)
	task.wait(0.15)
	check(nest3.target == e and nest3.state == "chasing", "D's landing later does not end E's chase")

	--==========================================================================
	say("\n4. The ramp")
	--==========================================================================
	local prof = GameConfig.guardianProfile("astralmaw")
	local nest4 = makeNest("starbloom", "astralmaw")
	local f = makePlayer("ThiefF", V(38, 3, -650))
	local g = makePlayer("ThiefG", V(38, 3, -600))
	carrying[f], carrying[g] = nest4.id, nest4.id
	nest4.target = f
	NestService.SpecProvoke(nest4, g)
	closeOn(nest4, f)
	tick(nest4)
	waitFor(function()
		return nest4.target == g
	end, 1)
	local handSpeed = NestService.SpecChaseSpeed(nest4)
	nest4.rampDone = nil
	nest4.chaseSince = os.clock() - 100
	local topSpeed = NestService.SpecChaseSpeed(nest4)
	nest4.chaseSince = os.clock()
	local openSpeed = NestService.SpecChaseSpeed(nest4)
	check(prof ~= nil and prof.OpeningSpeed < prof.TopSpeed and handSpeed ~= nil
			and math.abs(handSpeed - topSpeed) < 1e-6 and openSpeed < topSpeed - 1,
		"a hand-off runs at the ramp's top; a fresh chase still opens lower",
		string.format("hand-off %.1f, top %.1f, opening %.1f", handSpeed or -1, topSpeed or -1, openSpeed or -1))
	land(f)
	-- A chase started from asleep (a fresh raid) clears the hand-off's ramp.
	local nest5 = makeNest("starbloom", "astralmaw")
	nest5.state = "asleep"
	nest5.rampDone = true
	local h = makePlayer("ThiefH", V(38, 3, -650))
	carrying[h] = nest5.id
	NestService.SpecProvoke(nest5, h)
	nest5.state = "waking"
	nest5.stateUntil = 0
	tick(nest5)
	check(nest5.rampDone == nil and nest5.state == "chasing", "a chase from asleep starts its own ramp again")
end)
NestService.SetCarryBridge(nil)
fixture:Destroy()
if not ok then
	check(false, "the spec ran to the end", tostring(err))
end

say(string.format("\nGuardianHandOffSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
