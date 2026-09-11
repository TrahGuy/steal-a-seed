--!strict
--==============================================================================
-- Steal a Seed :: GuardianConfiscateSpec
--
-- The permanent leave-behind for the three confiscating guardians. Run with the
-- shared runner, Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("GuardianConfiscateSpec"))
--
-- THREE LAYERS, all against the shipped code:
--
--   CONFIG    Which biomes confiscate, and the chance and its bounds.
--   PURE      GuardianCatch.Resolve with counted, forced draws: the boundary,
--             the one-roll-per-pod rule, and what a full-handed guardian does.
--   PIPELINE  The real CarryService, fresh-required, driven with stand-in
--             players and real bodies on a floor in a throwaway folder: TryTake,
--             ResolveGuardianCatch, Drop and SpawnLoose run as shipped, and every
--             loose pod they make is counted. NestService.Provoke is spied on the
--             SAME module instance CarryService calls, so every re-pick's
--             provoke is seen with its nest id.
--
-- NOT HERE, verified in Play instead: the guardian's chase, rage and speed
-- (NestService's unchanged provoke, reached through the Provoke call counted
-- here), the throw and its ragdoll watcher, the haul walk and deposit, banking,
-- and real clients.
--==============================================================================
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = game.ReplicatedStorage.SeedGame.Shared
local GameConfig = require(Shared.GameConfig)
local Server = ServerScriptService.SeedGameServer
local GuardianCatch = require(Server.GuardianCatch)
local CarryService = require(Server.CarryService)
local NestService = require(Server.NestService)

local ATTR = GameConfig.Attributes
local CHANCE = GameConfig.Parent.Confiscate.LeaveBehindChance
local ORIGIN_NEST = "Nest_tanglemire_01"

local pass = 0
local fails: { string } = {}
local function check(ok: boolean, label: string)
	if ok then
		pass += 1
	else
		table.insert(fails, label)
	end
end

local function counted(value: number): (() -> number, () -> number)
	local n = 0
	return function(): number
		n += 1
		return value
	end, function(): number
		return n
	end
end

--==============================================================================
-- 1. CONFIG
--==============================================================================
check(CHANCE == 0.40, "LeaveBehindChance is 0.40")
check(CHANCE >= 0 and CHANCE <= 1, "LeaveBehindChance is within 0..1")
for _, biome in ipairs({ "tanglemire", "emberroot", "starbloom" }) do
	check(type(GameConfig.confiscateProfile(biome)) == "table", biome .. " confiscates")
end
for _, biome in ipairs({ "greenhollow", "dustbowl" }) do
	check(GameConfig.confiscateProfile(biome) == nil,
		biome .. " has no profile, so its catch returns before any roll")
end
check(GameConfig.confiscateProfile("LeaveBehindChance") == nil,
	"the chance can never be read back as a biome profile")

--==============================================================================
-- 2. THE DECISION, PURE
--==============================================================================
check(GuardianCatch.Leaves(0.3999, CHANCE), "roll 0.3999 leaves")
check(not GuardianCatch.Leaves(0.40, CHANCE), "roll 0.40 confiscates: the boundary is strict")
check(GuardianCatch.Leaves(0, CHANCE), "roll 0 leaves")
check(not GuardianCatch.Leaves(0.9999, CHANCE), "roll 0.9999 confiscates")

do
	local rec = {}
	local draw, calls = counted(0.3999)
	check(GuardianCatch.Resolve(rec, false, draw, CHANCE) == "left", "first catch, low roll -> left")
	check(rec.guardianAbandoned == true, "left marks the record")
	check(calls() == 1, "the first catch draws exactly once")
	for i = 2, 4 do
		check(GuardianCatch.Resolve(rec, false, draw, CHANCE) == "abandoned",
			("catch %d of a left pod -> abandoned"):format(i))
	end
	check(calls() == 1, "an abandoned pod is never drawn for again")

	local fresh = {}
	local hi, hiCalls = counted(0.40)
	check(GuardianCatch.Resolve(fresh, false, hi, CHANCE) == "confiscated", "roll 0.40 -> confiscated")
	check(fresh.guardianAbandoned == nil and hiCalls() == 1, "confiscation draws once and marks nothing")

	local other = {}
	local d3, c3 = counted(0.01)
	check(GuardianCatch.Resolve(other, true, d3, CHANCE) == "hauling", "hands full -> hauling")
	check(other.guardianAbandoned == nil and c3() == 0,
		"a hauling guardian neither draws for nor marks somebody else's pod")

	local d4, c4 = counted(0.01)
	check(GuardianCatch.Resolve(nil, false, d4, CHANCE) == "none" and c4() == 0,
		"nothing carried -> none, no draw")

	check(GuardianCatch.GuardianHolds("confiscated") and GuardianCatch.GuardianHolds("hauling"),
		"confiscated and hauling walk home holding")
	check(not GuardianCatch.GuardianHolds("left") and not GuardianCatch.GuardianHolds("abandoned")
		and not GuardianCatch.GuardianHolds("none"), "left, abandoned and none leave the pod to the throw")

	-- A uniform [0, 1) draw under the strict boundary leaves exactly CHANCE of pods.
	local rng = Random.new(20260911)
	local leaves, n = 0, 20000
	for _ = 1, n do
		if GuardianCatch.Resolve({}, false, function(): number
			return rng:NextNumber()
		end, CHANCE) == "left" then
			leaves += 1
		end
	end
	check(math.abs(leaves / n - CHANCE) < 0.015,
		("a seeded uniform draw leaves %.3f of pods (want 0.40)"):format(leaves / n))
end

--==============================================================================
-- 3. THE REAL CARRY PIPELINE
--==============================================================================
local map = Workspace:FindFirstChild(GameConfig.Map.FolderName)
local ORIGIN = Vector3.new(0, 900, 0)

local fixture = Instance.new("Folder")
fixture.Name = "GuardianConfiscateSpecFixture"
fixture.Parent = Workspace

-- Something for groundUnder to land dropped pods on, well away from the map.
local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Anchored = true
floor.Size = Vector3.new(80, 1, 80)
floor.CFrame = CFrame.new(ORIGIN - Vector3.new(0, 0.5, 0))
floor.Parent = fixture

-- What the map held before, so what this spec adds can be counted and removed.
local before: { [Instance]: boolean } = {}
local seen: { [Instance]: boolean } = {}
if map then
	for _, d in ipairs(map:GetChildren()) do
		before[d] = true
		seen[d] = true
	end
end

-- Loose pods that appeared in the map since the last call.
local function newPods(): { Model }
	local out: { Model } = {}
	if not map then
		return out
	end
	for _, d in ipairs(map:GetChildren()) do
		if not seen[d] then
			seen[d] = true
			if d:IsA("Model") and CollectionService:HasTag(d, GameConfig.Tags.SeedPod) then
				table.insert(out, d)
			end
		end
	end
	return out
end

local function place(model: Model, at: Vector3)
	local root = model:FindFirstChild("HumanoidRootPart") :: BasePart
	local head = model:FindFirstChild("Head") :: BasePart
	root.CFrame = CFrame.new(at + Vector3.new(0, 3, 0))
	head.CFrame = CFrame.new(at + Vector3.new(0, 4.5, 0))
end

-- A real body TryTake accepts: living Humanoid, Head, HumanoidRootPart.
local function body(name: string, at: Vector3): Model
	local model = Instance.new("Model")
	model.Name = name
	for _, spec in ipairs({ { "HumanoidRootPart", Vector3.new(2, 2, 1) }, { "Head", Vector3.new(1, 1, 1) } }) do
		local part = Instance.new("Part")
		part.Name = spec[1]
		part.Size = spec[2]
		part.Anchored = true
		part.CanCollide = false
		part.Parent = model
	end
	Instance.new("Humanoid").Parent = model
	model.PrimaryPart = model:FindFirstChild("HumanoidRootPart") :: BasePart
	model.Parent = fixture
	place(model, at)
	return model
end

-- A stand-in Player: everything CarryService touches on one, and nothing else.
local function stand(name: string, userId: number, character: Model): any
	local attrs: { [string]: any } = {}
	return {
		Name = name,
		UserId = userId,
		Parent = Players,
		Character = character,
		SetAttribute = function(_, k: string, v: any)
			attrs[k] = v
		end,
		GetAttribute = function(_, k: string): any
			return attrs[k]
		end,
		FindFirstChildOfClass = function(): any
			return nil
		end,
	}
end

local provokes: { { nest: string, who: string } } = {}
local realProvoke = NestService.Provoke
;(NestService :: any).Provoke = function(nestId: string, thief: any): boolean
	table.insert(provokes, { nest = nestId, who = thief.Name })
	return true
end

-- The newest provoke is this thief on the origin nest, and it is provoke #count.
local function provokedBy(who: string, count: number): boolean
	local last = provokes[#provokes]
	return #provokes == count and last ~= nil and last.nest == ORIGIN_NEST and last.who == who
end

local ok, err = pcall(function()
	check(map ~= nil, "the map folder exists (loose pods are parented to it)")
	check(type(CarryService.ResolveGuardianCatch) == "function", "CarryService exposes ResolveGuardianCatch")
	if not map then
		return
	end
	local aliceBody = body("SpecAlice", ORIGIN)
	local bobBody = body("SpecBob", ORIGIN + Vector3.new(10, 0, 0))
	local alice = stand("SpecAlice", -101, aliceBody)
	local bob = stand("SpecBob", -102, bobBody)

	local function spawnNear(owner: Model, abandoned: boolean?): Model
		local root = owner:FindFirstChild("HumanoidRootPart") :: BasePart
		local pod = CarryService.SpawnLoose("nubkin", 1,
			CFrame.new(root.Position + Vector3.new(0, -3, -2)), ORIGIN_NEST, nil, true, abandoned) :: Model
		seen[pod] = true
		return pod
	end
	-- What the ragdoll watcher and a bat hit both do: Drop at the root.
	local function knock(player: any, bodyModel: Model): boolean
		local root = bodyModel:FindFirstChild("HumanoidRootPart") :: BasePart
		return CarryService.Drop(player, root.Position)
	end

	--== 3a. THE LEAVE ==========================================================
	local pod1 = spawnNear(aliceBody)
	check(CarryService.TryTake(alice, pod1), "alice takes a fresh loose pod")
	check(provokedBy("SpecAlice", 1), "taking it provokes its origin nest")
	local outcome, held = CarryService.ResolveGuardianCatch(alice, false, 0.3999)
	check(outcome == "left" and held == nil, "roll 0.3999 -> left, nothing handed to a haul")
	local inHand = CarryService.GetCarried(alice) :: any
	check(inHand ~= nil and inHand.guardianAbandoned == true, "the carried record is marked")
	check(inHand ~= nil and inHand.model:GetAttribute(ATTR.GuardianAbandoned) == true,
		"the carried model is marked, for inspection")
	check(#newPods() == 0, "nothing is on the ground before the throw")
	check(knock(alice, aliceBody), "the throw's ragdoll drops it")
	check(not knock(alice, aliceBody), "a second drop finds nothing")
	local left = newPods()
	check(#left == 1, ("exactly one loose pod after the leave (got %d)"):format(#left))
	local dropped = left[1]
	check(dropped ~= nil and dropped:GetAttribute(ATTR.GuardianAbandoned) == true,
		"the loose pod has GuardianAbandoned = true")
	check(dropped ~= nil and dropped:GetAttribute("FromNestId") == ORIGIN_NEST,
		"and still names the nest it came from")

	--== 3b. ANOTHER CARRIER, MORE CATCHES, A BAT, A THIRD CARRIER ==============
	if dropped then
		place(aliceBody, ORIGIN + Vector3.new(-10, 0, 0))
		place(bobBody, dropped:GetPivot().Position + Vector3.new(0, 0, 2))
		check(CarryService.TryTake(bob, dropped), "bob picks the abandoned pod up")
		check(provokedBy("SpecBob", 2), "bob's re-pick provokes the origin nest")
		local bobHeld = CarryService.GetCarried(bob) :: any
		check(bobHeld ~= nil and bobHeld.guardianAbandoned == true
			and bobHeld.model:GetAttribute(ATTR.GuardianAbandoned) == true,
			"the flag moved with the pod to a different carrier")
		-- Every confiscating biome resolves through this one call, whatever it rolls.
		for i, forced in ipairs({ 0.0, 0.3999, 0.40, 0.9999 }) do
			local o, h = CarryService.ResolveGuardianCatch(bob, false, forced)
			check(o == "abandoned" and h == nil,
				("catch %d (roll %.4f) -> abandoned: not rolled, not taken"):format(i, forced))
		end
		check(CarryService.IsCarrying(bob), "no catch took the abandoned pod off bob")

		-- CombatService's bat hit calls this same Drop.
		check(knock(bob, bobBody), "a bat hit knocks it out of bob's hands")
		local batDrop = newPods()
		check(#batDrop == 1 and batDrop[1]:GetAttribute(ATTR.GuardianAbandoned) == true,
			("after the bat, exactly one pod and still abandoned (got %d)"):format(#batDrop))

		if batDrop[1] then
			place(bobBody, ORIGIN + Vector3.new(10, 0, 0))
			place(aliceBody, batDrop[1]:GetPivot().Position + Vector3.new(0, 0, 2))
			check(CarryService.TryTake(alice, batDrop[1]), "alice takes it back")
			check(provokedBy("SpecAlice", 3), "that re-pick provokes the origin nest again")
			check((CarryService.GetCarried(alice) :: any).guardianAbandoned == true,
				"still abandoned in the next pair of hands")
			check(CarryService.ResolveGuardianCatch(alice, false, 0.01) == "abandoned",
				"caught again: still abandoned")
			check(knock(alice, aliceBody), "thrown again: dropped")
			local third = newPods()
			check(#third == 1 and third[1]:GetAttribute(ATTR.GuardianAbandoned) == true,
				"one pod again, flag intact after repeated drops")
		end
	end
	place(aliceBody, ORIGIN)
	place(bobBody, ORIGIN + Vector3.new(10, 0, 0))

	--== 3c. THE CONFISCATION ===================================================
	local pod2 = spawnNear(aliceBody)
	check(CarryService.TryTake(alice, pod2), "alice takes a fresh pod")
	local o2, h2 = CarryService.ResolveGuardianCatch(alice, false, 0.40)
	check(o2 == "confiscated", "roll 0.40 -> confiscated")
	check(h2 ~= nil and (h2 :: any).fromNest == ORIGIN_NEST and (h2 :: any).tier == 1,
		"the haul gets the whole record, origin nest included")
	check(h2 ~= nil and (h2 :: any).guardianAbandoned ~= true, "a confiscated pod is not marked")
	check(not CarryService.IsCarrying(alice), "the victim's hands are empty")
	check(not knock(alice, aliceBody), "the throw's drop finds nothing")
	check(#newPods() == 0, "a confiscation leaves no loose pod")

	--== 3d. CARRIED HOME, STOLEN AGAIN: A NEW ATTEMPT ==========================
	-- depositHaul's fallback when the ring is full is exactly this call.
	local deposited = CarryService.SpawnLoose("nubkin", 1,
		CFrame.new(ORIGIN + Vector3.new(0, 0, -2)), ORIGIN_NEST) :: Model
	seen[deposited] = true
	check(deposited:GetAttribute(ATTR.GuardianAbandoned) == nil, "a deposited pod carries no flag")
	check(CarryService.TryTake(alice, deposited), "alice steals it again")
	check(CarryService.ResolveGuardianCatch(alice, false, 0.10) == "left",
		"caught with it, it is rolled afresh (0.10 -> left)")
	knock(alice, aliceBody)
	newPods()

	--== 3e. TWO CONTACTS IN ONE FRAME ==========================================
	-- Nothing in ResolveGuardianCatch yields, so same-frame contacts run in turn.
	local pod3 = spawnNear(aliceBody)
	check(CarryService.TryTake(alice, pod3), "race: alice takes a fresh pod")
	local r1, rh1 = CarryService.ResolveGuardianCatch(alice, false, 0.90)
	local r2, rh2 = CarryService.ResolveGuardianCatch(alice, false, 0.10)
	check(r1 == "confiscated" and rh1 ~= nil and r2 == "none" and rh2 == nil,
		"confiscated, then the second contact finds an empty hand")
	check(not knock(alice, aliceBody) and #newPods() == 0, "and nothing drops")

	local pod4 = spawnNear(aliceBody)
	check(CarryService.TryTake(alice, pod4), "race: alice takes another fresh pod")
	local s1 = CarryService.ResolveGuardianCatch(alice, false, 0.10)
	local s2, sh2 = CarryService.ResolveGuardianCatch(alice, false, 0.90)
	check(s1 == "left" and s2 == "abandoned" and sh2 == nil,
		"left, then the second contact neither rerolls nor takes")
	check(knock(alice, aliceBody), "the first throw drops it")
	check(not knock(alice, aliceBody), "the second throw has nothing to drop")
	check(#newPods() == 1, "exactly one pod on the ground")

	--== 3f. A GUARDIAN ALREADY HAULING =========================================
	local pod5 = spawnNear(aliceBody)
	check(CarryService.TryTake(alice, pod5), "alice takes a pod near a guardian with full hands")
	local hOut, hHeld = CarryService.ResolveGuardianCatch(alice, true, 0.01)
	check(hOut == "hauling" and hHeld == nil, "hands full -> hauling, nothing taken")
	local still = CarryService.GetCarried(alice) :: any
	check(still ~= nil and still.guardianAbandoned ~= true
		and still.model:GetAttribute(ATTR.GuardianAbandoned) == nil,
		"the unrelated pod was neither rolled nor marked")
	check(CarryService.ResolveGuardianCatch(alice, false, 0.90) == "confiscated",
		"so a later free-handed guardian still gets its one roll")
	check(#newPods() == 0, "and nothing was dropped along the way")

	--== 3g. AN EMPTY-HANDED CATCH ==============================================
	local nOut, nHeld = CarryService.ResolveGuardianCatch(bob, false, 0.01)
	check(nOut == "none" and nHeld == nil, "a catch on somebody carrying nothing -> none")
	check(not knock(bob, bobBody) and #newPods() == 0, "and makes nothing")

	--== 3h. THE PLAY-TEST OVERRIDE AND THE SERVER'S OWN DRAW ===================
	check(CarryService.SetGuardianRollOverride(0.39), "override accepts 0.39")
	local pod6 = spawnNear(aliceBody)
	check(CarryService.TryTake(alice, pod6), "alice takes a pod with the override on")
	check(CarryService.ResolveGuardianCatch(alice, false) == "left", "no injected roll: the override decides")
	knock(alice, aliceBody)
	newPods()
	check(CarryService.SetGuardianRollOverride(nil), "override clears")
	check(not CarryService.SetGuardianRollOverride(1) and not CarryService.SetGuardianRollOverride(-0.01)
		and not CarryService.SetGuardianRollOverride(0 / 0), "override refuses anything outside [0, 1)")
	local pod7 = spawnNear(aliceBody)
	check(CarryService.TryTake(alice, pod7), "alice takes a pod with nothing forced")
	local own = CarryService.ResolveGuardianCatch(alice, false)
	check(own == "left" or own == "confiscated", "the server's own draw lands on one of the two ("
		.. tostring(own) .. ")")
	knock(alice, aliceBody)
	newPods()
end)

;(NestService :: any).Provoke = realProvoke
pcall(CarryService.SetGuardianRollOverride, nil)
if map then
	for _, d in ipairs(map:GetChildren()) do
		if not before[d] and d:GetAttribute("SpeciesId") ~= nil then
			d:Destroy()
		end
	end
end
fixture:Destroy()

if not ok then
	table.insert(fails, "THREW: " .. tostring(err))
end
if #fails > 0 then
	return ("GuardianConfiscateSpec: %d passed, %d FAILED\n  %s"):format(
		pass, #fails, table.concat(fails, "\n  "))
end
return ("GuardianConfiscateSpec: %d passed, 0 failed"):format(pass)
