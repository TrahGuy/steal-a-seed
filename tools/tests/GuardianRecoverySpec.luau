--!nocheck
--==============================================================================
-- Steal a Seed :: GuardianRecoverySpec (2026-10-04, the owner's report: a
-- long-lived live server had no guardian at any nest; a restart brought them)
--
-- NestService now rebuilds a guardian whose rig is genuinely gone, dead or out
-- of the world, from the same builder at the same spot. This drives the REAL
-- tick (NestService.SpecStep) on nests raised the way buildNest raises them --
-- a real rig from ParentModel.Build, its recipe kept -- in a Workspace fixture
-- far above the preview map, and checks the owner's safeguards:
--
--   * a lost rig, a dead one, a missing root, a fall out of the world: rebuilt,
--     one rig in the nest, the record on the new one; a healthy guardian --
--     asleep, or awake and far away -- is never replaced
--   * a haul goes home exactly once through the deposit path (ring, or loose
--     when the ring is full), never lost, never doubled, never rolled again
--   * pods, the secret encounter and the event id are untouched
--   * repeated ticks change nothing; a stray rig in the folder is removed
--   * a failing build backs off and warns sparingly, then succeeds
--   * a throw in flight is waited for, up to the cap
--   * an awake guardian lets go of its chase, keeps a still-eligible thief and
--     resumes from its own nest with no sweep sample (no teleport catch)
--   * the weather's guardian: rebuilt while its weather stands; never after the
--     weather ends or its terrain goes, even mid-backoff
--
-- NOT here: a live server's physics (the Play check moves a real guardian out
-- of the world), and what took the guardians on the owner's server -- unknown.
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local ParentModel = require(Server:WaitForChild("ParentModel"))
local NestService = require(Server:WaitForChild("NestService"))

local P = GameConfig.Parent
local R = P.Recovery
local TAG = GameConfig.Tags.NestParent
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

-- In the Workspace (a rig outside it reads as gone), far above the preview map,
-- on the road side of the Safe Zone so a chase can run.
local fixture = Instance.new("Folder")
fixture.Name = "ZZGuardianRecoverySpec"
fixture.Parent = workspace
local HIGH = 4000
local nestCount = 0

-- What NestService prints and warns, caught at its own globals while the spec
-- runs (LogService's history does not have a line yet when the spec reads it).
local said = {}
local env = getfenv(NestService.SpecStep)
local function catch(kind)
	return function(...)
		local parts = table.pack(...)
		for i = 1, parts.n do
			parts[i] = tostring(parts[i])
		end
		table.insert(said, kind .. ": " .. table.concat(parts, " ", 1, parts.n))
	end
end
rawset(env, "print", catch("print"))
rawset(env, "warn", catch("warn"))

-- A position the way the log writes one.
local function fmt(v)
	return string.format("(%d, %d, %d)", math.floor(v.X), math.floor(v.Y), math.floor(v.Z))
end

-- How many of those lines name this nest and say this.
local function logLines(nestId, needle)
	local n = 0
	for _, line in ipairs(said) do
		if string.find(line, nestId, 1, true) and string.find(line, needle, 1, true) then
			n += 1
		end
	end
	return n
end

local function biomeOf(id)
	for _, b in ipairs(BiomeData.Biomes) do
		if b.Id == id then
			return b
		end
	end
	return nil
end

-- A nest raised the way buildNest raises one: its own folder, the real rig at
-- its build spot, a ring of slots, the recipe kept on the record.
local function raise(biome, rigId, opts)
	opts = opts or {}
	nestCount += 1
	local at = V(38, HIGH, -700 - nestCount * 90)
	local folder = Instance.new("Folder")
	folder.Name = string.format("Nest_spec_%s_%02d", biome.Id, nestCount)
	folder.Parent = fixture
	local buildAt = CFrame.new(at) * CFrame.Angles(0, -math.pi * 0.5, 0)
	local model = ParentModel.Build(buildAt, 15, rigId, folder)
	local slots = {}
	for i = 1, biome.PodsPerNest or 5 do
		local a = (i - 1) / (biome.PodsPerNest or 5) * math.pi * 2
		slots[i] = CFrame.new(at + V(math.sin(a) * 16, 0, math.cos(a) * 16))
	end
	return {
		id = folder.Name, biome = biome, origin = at, homeCFrame = model.PrimaryPart.CFrame,
		parent = model, humanoid = model:FindFirstChildOfClass("Humanoid"), root = model.PrimaryPart,
		folder = folder, slots = slots, pods = {}, state = "asleep", target = nil, stateUntil = 0,
		busy = false, rage = 0, calmSince = 0, chaseSince = 0, haul = nil, sample = nil, thieves = {},
		secret = nil, marked = {}, buildAt = buildAt, rigId = rigId, lastSeen = model.PrimaryPart.Position,
		event = opts.event, route = opts.route, setDown = opts.setDown,
	}
end

local function rigsIn(folder)
	local n = 0
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") and CollectionService:HasTag(child, TAG) then
			n += 1
		end
	end
	return n
end

local function podCount(nest)
	local n = 0
	for _, pod in pairs(nest.pods) do
		if pod then
			n += 1
		end
	end
	return n
end

-- Whole and standing: in the folder, tagged, a Humanoid and a root, at home.
local function sound(nest, old)
	local model = nest.parent
	return model ~= old and model.Parent == nest.folder and CollectionService:HasTag(model, TAG)
		and nest.humanoid and nest.humanoid.Parent == model and nest.root == model.PrimaryPart
		and nest.root:IsDescendantOf(model) and (nest.root.Position - nest.homeCFrame.Position).Magnitude < 0.01
		and rigsIn(nest.folder) == 1 and nest.recovery == nil
end

local clock = 5000
local function tick(nest, seconds)
	clock += seconds or 0.12
	NestService.SpecStep(nest, clock)
end

local function makePlayer(name, at)
	local model = Instance.new("Model")
	model.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Anchored = true
	root.Position = at
	root.Parent = model
	Instance.new("Humanoid").Parent = model
	model.Parent = fixture
	return { Name = name, UserId = 0, Parent = Players, Character = model }
end

local carrying = {}
local loose = {}

local ok, err = pcall(function()
	local greenhollow = biomeOf("greenhollow")
	local dustbowl = biomeOf("dustbowl")
	-- One of the three that confiscate (GameConfig.Parent.Confiscate).
	local tanglemire = biomeOf("tanglemire")
	NestService.SetCarryBridge({
		CarriedFrom = function(p)
			return carrying[p]
		end,
		SpawnLoose = function(speciesId, tier, cf, nestId)
			table.insert(loose, { species = speciesId, tier = tier, nest = nestId })
			return true
		end,
	})

	--==========================================================================
	-- 1. A HEALTHY GUARDIAN IS NEVER REPLACED
	--==========================================================================
	say("-- healthy --")
	local calm = raise(greenhollow, "greenhollow")
	local first = calm.parent
	for _ = 1, 10 do
		tick(calm)
	end
	check(calm.parent == first and rigsIn(calm.folder) == 1 and calm.recovery == nil and calm.state == "asleep",
		"asleep and whole: ten ticks leave the same rig")
	-- Awake, chasing a thief who carries its pod, 300 studs down the road.
	local runner = makePlayer("SpecRunner", calm.origin - V(0, 0, 340))
	carrying[runner] = calm.id
	calm.root.CFrame = calm.root.CFrame - V(0, 0, 300)
	calm.state = "chasing"
	calm.target = runner
	calm.chaseSince = clock
	tick(calm)
	tick(calm)
	check(calm.parent == first and calm.recovery == nil and calm.state == "chasing" and calm.target == runner,
		"chasing a thief 300 studs from its nest: the same rig, still after them",
		string.format("%s, recovery %s", calm.state, tostring(calm.recovery and calm.recovery.reason)))
	-- Low, but not out of the world.
	calm.root.CFrame = calm.root.CFrame - V(0, R.FallStuds - 10, 0)
	tick(calm)
	check(calm.parent == first and calm.recovery == nil and calm.target == runner,
		string.format("%d studs under its nest: still in the world, not replaced", R.FallStuds - 10))
	-- Then lost out there: rebuilt at its nest, after the same thief, and the log
	-- has where it last stood -- not where it sleeps.
	local lastPos = calm.root.Position
	first:Destroy()
	tick(calm)
	check(sound(calm, first) and calm.state == "chasing" and calm.target == runner,
		"lost mid-chase 300 studs out: rebuilt at its nest, and after the same thief")
	local fromWhere = logLines(calm.id, "lost its guardian -- its rig is gone; it was chasing at " .. fmt(lastPos) .. ".")
	check(fromWhere == 1, "the log has the chase and the spot it was last seen", tostring(fromWhere))
	carrying[runner] = nil
	calm.target = nil
	calm.state = "asleep"

	--==========================================================================
	-- 2. GONE, DEAD, NO ROOT, FALLEN: REBUILT, ONE RIG, THE RECORD ON IT
	--==========================================================================
	say("-- lost --")
	local lost = raise(greenhollow, "greenhollow")
	local fakePod = Instance.new("Model")
	fakePod.Name = "SpecPod"
	fakePod.Parent = lost.folder
	lost.pods[2] = fakePod
	lost.secret = { id = "spec:secret:7", speciesId = "snarlbloom", pod = nil, platform = nil, spawnedAt = 1 }
	lost.rage = 3
	local secretBefore = lost.secret

	local old = lost.parent
	old:Destroy()
	tick(lost)
	check(sound(lost, old), "its rig destroyed: rebuilt once, in its folder, tagged, a Humanoid and a root, at home")
	check(lost.parent:GetAttribute("Asleep") == true and lost.state == "asleep",
		"it was asleep, and is asleep again")
	check(lost.pods[2] == fakePod and fakePod.Parent == lost.folder and podCount(lost) == 1
			and lost.secret == secretBefore and lost.secret.id == "spec:secret:7" and lost.rage == 3,
		"its pods, its secret encounter (same id) and its rage are untouched")

	old = lost.parent
	lost.humanoid.Health = 0
	tick(lost)
	check(sound(lost, old) and old.Parent == nil, "dead: rebuilt, and the dead rig is gone from the world")

	old = lost.parent
	lost.root:Destroy()
	tick(lost)
	check(sound(lost, old) and old.Parent == nil, "its root gone (as under FallenPartsDestroyHeight): rebuilt, the rest removed")

	old = lost.parent
	local before = lost.root.Position
	lost.root.CFrame = lost.root.CFrame - V(0, R.FallStuds + 10, 0)
	tick(lost)
	check(sound(lost, old) and old.Parent == nil,
		string.format("%d studs under its nest: out of the world, rebuilt at home", R.FallStuds + 10))
	local why = logLines(lost.id, "(greenhollow) lost its guardian -- it fell out of the world, ")
	local whereFrom = logLines(lost.id, "under its nest; it was asleep at " .. fmt(before) .. ". Rebuilt at its nest.")
	check(why == 1 and whereFrom == 1, "the log says why, in what state and from where it was last seen",
		string.format("%d / %d", why, whereFrom))

	old = lost.parent
	lost.humanoid:Destroy()
	tick(lost)
	check(sound(lost, old), "its Humanoid gone: rebuilt")

	--==========================================================================
	-- 3. REPEATED CHECKS, AND A STRAY RIG
	--==========================================================================
	say("-- no duplicates --")
	local steady = lost.parent
	for _ = 1, 20 do
		tick(lost)
	end
	check(lost.parent == steady and rigsIn(lost.folder) == 1, "twenty more ticks: the same rig, still one")
	local stray = ParentModel.Build(lost.buildAt, 15, "greenhollow", lost.folder)
	check(rigsIn(lost.folder) == 2, "(a stray second rig in the folder, for the test)")
	old = lost.parent
	old:Destroy()
	tick(lost)
	check(sound(lost, old) and stray.Parent == nil, "the next rebuild leaves one rig: the stray is removed too")

	--==========================================================================
	-- 4. A HAUL GOES HOME ONCE, THROUGH THE DEPOSIT PATH
	--==========================================================================
	say("-- the haul --")
	local hauler = raise(tanglemire, "tanglemire")
	local filler = {}
	for i = 1, 2 do
		local m = Instance.new("Model")
		m.Name = "SpecPod" .. i
		m.Parent = hauler.folder
		hauler.pods[i] = m
		filler[i] = m
	end
	local before = podCount(hauler)
	hauler.haul = { speciesId = "bogbonnet", tier = 3, fromNest = hauler.id, model = nil, since = clock }
	hauler.state = "hauling"
	local looseBefore = #loose
	old = hauler.parent
	old:Destroy()
	tick(hauler)
	local placed = nil
	for i = 1, tanglemire.PodsPerNest do
		local pod = hauler.pods[i]
		if pod and pod ~= filler[1] and pod ~= filler[2] then
			placed = pod
		end
	end
	check(hauler.haul == nil and podCount(hauler) == before + 1 and placed ~= nil
			and placed:GetAttribute("SpeciesId") == "bogbonnet" and tonumber(placed:GetAttribute("Tier")) == 3
			and #loose == looseBefore,
		"the confiscated pod is back in its ring: the same species and tier, once, nothing spawned loose",
		string.format("pods %d -> %d, loose %d", before, podCount(hauler), #loose - looseBefore))
	check(sound(hauler, old) and (hauler.state == "asleep" or hauler.state == "returning"),
		"and the guardian is rebuilt, home, done hauling", hauler.state)
	for _ = 1, 10 do
		tick(hauler)
	end
	check(podCount(hauler) == before + 1 and hauler.haul == nil, "ten more ticks: still exactly one pod back")

	-- A full ring: loose at the nest, through CarryService's own call, once.
	for i = 1, tanglemire.PodsPerNest do
		if not hauler.pods[i] then
			local m = Instance.new("Model")
			m.Parent = hauler.folder
			hauler.pods[i] = m
		end
	end
	local full = podCount(hauler)
	hauler.haul = { speciesId = "snapmoss", tier = 5, fromNest = hauler.id, model = nil, since = clock }
	hauler.state = "hauling"
	looseBefore = #loose
	hauler.parent:Destroy()
	tick(hauler)
	local spawned = loose[#loose]
	check(hauler.haul == nil and podCount(hauler) == full and #loose == looseBefore + 1
			and spawned.species == "snapmoss" and spawned.tier == 5 and spawned.nest == hauler.id,
		"a full ring: the pod goes loose at its nest, once, the same species and tier")

	-- The rebuild failing: the pod goes home at once all the same, and only once.
	hauler.pods[1]:Destroy()
	hauler.pods[1] = nil
	local ringBefore = podCount(hauler)
	looseBefore = #loose
	NestService.SpecRigBuilder(function()
		error("spec: the builder failed")
	end)
	hauler.haul = { speciesId = "crookreed", tier = 4, fromNest = hauler.id, model = nil, since = clock }
	hauler.state = "hauling"
	old = hauler.parent
	old:Destroy()
	tick(hauler)
	local back = hauler.pods[1]
	check(hauler.haul == nil and podCount(hauler) == ringBefore + 1 and back ~= nil
			and back:GetAttribute("SpeciesId") == "crookreed" and tonumber(back:GetAttribute("Tier")) == 4
			and #loose == looseBefore and hauler.recovery ~= nil and hauler.recovery.failures == 1,
		"the rebuild failing: the pod is back in its ring at once all the same")
	NestService.SpecRigBuilder(nil)
	tick(hauler, R.RetrySeconds[1])
	check(sound(hauler, old) and hauler.pods[1] == back and podCount(hauler) == ringBefore + 1 and #loose == looseBefore,
		"and the rebuild that follows puts nothing back a second time")

	--==========================================================================
	-- 5. A FAILING BUILD BACKS OFF, THEN SUCCEEDS
	--==========================================================================
	say("-- backoff --")
	local shaky = raise(greenhollow, "greenhollow")
	local calls = 0
	NestService.SpecRigBuilder(function()
		calls += 1
		error("spec: the builder failed")
	end)
	old = shaky.parent
	old:Destroy()
	tick(shaky)
	local rec = shaky.recovery
	local firstWait = R.RetrySeconds[1]
	check(rec ~= nil and rec.failures == 1 and calls == 1 and rigsIn(shaky.folder) == 0
			and math.abs(rec.nextAt - clock - firstWait) < 1e-6,
		string.format("a failed build: nothing stands, one try, the next in %d s", firstWait))
	for _ = 1, 8 do
		tick(shaky)
	end
	check(calls == 1 and shaky.recovery.failures == 1, "inside the wait no build is tried (8 ticks, 0.96 s)")
	tick(shaky, firstWait)
	check(calls == 2 and shaky.recovery.failures == 2
			and math.abs(shaky.recovery.nextAt - clock - R.RetrySeconds[2]) < 1e-6,
		string.format("after it: one more try, and the next wait is %d s", R.RetrySeconds[2]))
	local warnedAt = shaky.recovery.warnedAt
	-- A builder that answers without a Humanoid is a failure too, and its model goes.
	NestService.SpecRigBuilder(function(cf, h, id, parent)
		calls += 1
		local m = Instance.new("Model")
		m.Parent = parent
		return m
	end)
	tick(shaky, R.RetrySeconds[2])
	check(calls == 3 and shaky.recovery.failures == 3 and #shaky.folder:GetChildren() == 0
			and shaky.recovery.warnedAt == warnedAt,
		"a rig with no Humanoid: removed, counted, and not warned again inside WarnEverySeconds")
	NestService.SpecRigBuilder(nil)
	tick(shaky, R.RetrySeconds[3])
	check(sound(shaky, old), "the builder back: rebuilt, one rig, the episode closed")
	local warned = logLines(shaky.id, "could not rebuild its guardian")
	local closed = logLines(shaky.id, "Rebuilt at its nest after 3 failed try(s).")
	check(warned == 1 and closed == 1,
		"the log: one warning for three failures inside a minute, one line for the rebuild that ended them",
		string.format("warnings %s, rebuilt lines %s", tostring(warned), tostring(closed)))

	--==========================================================================
	-- 6. A THROW IN FLIGHT IS WAITED FOR, UP TO THE CAP
	--==========================================================================
	say("-- busy --")
	local thrower = raise(greenhollow, "greenhollow")
	thrower.busy = true
	thrower.busySince = clock
	thrower.state = "chasing"
	old = thrower.parent
	old:Destroy()
	tick(thrower)
	check(thrower.parent == old and thrower.busy == true, "mid-throw: not rebuilt while the throw holds the nest")
	tick(thrower, R.BusyCapSeconds)
	check(sound(thrower, old) and thrower.busy == false, "past BusyCapSeconds: rebuilt anyway, and no longer busy")

	--==========================================================================
	-- 7. AN AWAKE GUARDIAN: THE CHASE LET GO, AN ELIGIBLE THIEF KEPT, NO
	--    TELEPORT CATCH
	--==========================================================================
	say("-- the chase --")
	local chaser = raise(dustbowl, "dustbowl")
	local thief = makePlayer("SpecThief", chaser.origin + V(0, 0, 120))
	carrying[thief] = chaser.id
	chaser.state = "chasing"
	chaser.target = thief
	chaser.chaseSince = clock
	-- A sample from where the OLD body was, beside the thief: a sweep from here
	-- to home would pass through them.
	chaser.sample = { target = thief, body = thief.Character, parentAt = thief.Character.HumanoidRootPart.Position,
		targetAt = thief.Character.HumanoidRootPart.Position, at = clock }
	-- The first build fails: a guardian that is not there chases nobody meanwhile.
	NestService.SpecRigBuilder(function()
		error("spec: the builder failed")
	end)
	old = chaser.parent
	old:Destroy()
	tick(chaser)
	check(chaser.target == nil and chaser.state == "returning" and chaser.sample == nil and chaser.thieves[thief] ~= nil
			and chaser.recovery ~= nil and chaser.recovery.failures == 1,
		"while it cannot be rebuilt it chases nobody: the chase let go, the thief remembered, the old sweep dropped",
		string.format("state %s target %s", chaser.state, tostring(chaser.target and chaser.target.Name)))
	NestService.SpecRigBuilder(nil)
	tick(chaser, R.RetrySeconds[1])
	check(chaser.parent ~= old and chaser.target == thief and chaser.state == "chasing" and chaser.sample == nil
			and chaser.busy == false and chaser.recovery == nil,
		"rebuilt at its nest and back after the thief who still carries its pod -- with no sample from the old body",
		string.format("state %s target %s", chaser.state, tostring(chaser.target and chaser.target.Name)))
	tick(chaser)
	check(chaser.busy == false and chaser.state == "chasing", "the next tick catches nobody 120 studs away (no teleport catch)")
	-- A thief who dropped the pod is not chased by the new rig.
	carrying[thief] = nil
	chaser.state = "chasing"
	chaser.target = thief
	old = chaser.parent
	old:Destroy()
	tick(chaser)
	check(chaser.parent ~= old and chaser.target == nil and next(chaser.thieves) == nil and chaser.state == "asleep",
		"a target no longer a thief is let go: the rebuilt guardian lies down at home", chaser.state)

	--==========================================================================
	-- 8. THE WEATHER'S GUARDIAN, ONLY WHILE ITS WEATHER STANDS
	--==========================================================================
	say("-- the weather --")
	check(NestService.EventOpenFor(7, 7, "active") and NestService.EventOpenFor(7, 7, "opening")
			and not NestService.EventOpenFor(7, 7, "closing") and not NestService.EventOpenFor(7, 8, "active")
			and not NestService.EventOpenFor(7, nil, nil) and not NestService.EventOpenFor(nil, nil, nil),
		"the weather stands for an event only while it publishes that id as opening or active")
	local rainBiome = { Id = "rain", PodsPerNest = 3, RecommendedSpeed = 0 }
	local standing = true
	NestService.SpecWeather(function(nest)
		return standing and nest.event == 41
	end)
	-- The real builder, counted: "never rebuilt" means it is never even asked.
	local builds = 0
	local function counting(cf, h, id, parent)
		builds += 1
		return ParentModel.Build(cf, h, id, parent)
	end
	local storm = raise(rainBiome, "rain", { event = 41 })
	local species = storm.parent:GetAttribute("Species")
	NestService.SpecRigBuilder(counting)
	old = storm.parent
	old:Destroy()
	tick(storm)
	check(sound(storm, old) and builds == 1 and storm.event == 41 and storm.parent:GetAttribute("Species") == species,
		"while its weather stands: Stormstrider rebuilt once, the same event id, the same creature", species)
	local said = logLines(storm.id, "(rain) lost its guardian -- its rig is gone; it was asleep at (")
	local evented = logLines(storm.id, ", event 41. Rebuilt at its nest.")
	check(said == 1 and evented == 1,
		"the log names the nest, the biome, the reason, the state it was in, where it was and the event",
		string.format("%s / %s", tostring(said), tostring(evented)))

	-- Lost, the build failing, then the weather ends before the retry.
	NestService.SpecRigBuilder(function()
		error("spec: the builder failed")
	end)
	old = storm.parent
	old:Destroy()
	tick(storm)
	check(storm.recovery ~= nil and storm.recovery.failures == 1, "(a failed build, waiting to try again)")
	standing = false
	builds = 0
	NestService.SpecRigBuilder(counting)
	tick(storm, 120)
	tick(storm, 120)
	local held = storm.recovery
	check(builds == 0 and rigsIn(storm.folder) == 0 and held ~= nil and held.refused ~= nil and held.failures == 1,
		"the weather ended during the wait: the builder is never asked again",
		string.format("builds %d, refused %s", builds, tostring(held and held.refused)))

	-- Standing again in name, but its terrain is gone: still never.
	standing = true
	storm.folder:Destroy()
	tick(storm, 120)
	tick(storm, 120)
	local anywhere = 0
	for _, d in ipairs(fixture:GetDescendants()) do
		if d:IsA("Model") and CollectionService:HasTag(d, TAG) and d:GetAttribute("Species") == species then
			anywhere += 1
		end
	end
	check(builds == 0 and anywhere == 0 and storm.recovery ~= nil,
		"its terrain removed: the builder is never asked, no Stormstrider anywhere")
	local refusals = logLines(storm.id, "will not rebuild it")
	check(refusals == 2, "each refusal is said once: the weather over, then the nest gone", tostring(refusals))

	--==========================================================================
	-- 9. THE SOURCE: ONLY THE RIG, THROUGH THE BUILDER; THE RECIPE KEPT
	--==========================================================================
	say("-- the source --")
	local src = (Server:FindFirstChild("NestService") :: any).Source:gsub("\r\n", "\n")
	local from = string.find(src, "local function recoverGuardian", 1, true)
	local to = from and string.find(src, "\nend\n", from, true)
	local body = if from and to then string.sub(src, from, to) else ""
	check(body ~= "" and string.find(body, "rigBuilder", 1, true) ~= nil and string.find(body, "depositHaul(", 1, true) ~= nil
			and not string.find(body, "buildNest", 1, true) and not string.find(body, "growPod", 1, true)
			and not string.find(body, "placePod", 1, true) and not string.find(body, "OpenEventNest", 1, true)
			and not string.find(body, "rollSecret", 1, true) and not string.find(body, "StockAll", 1, true),
		"a rebuild builds the rig and deposits a haul -- it never raises a nest, rolls a pod or opens a weather nest")
	check(string.find(body, "pcall(publishPursuit)", 1, true) ~= nil and string.find(body, "pinToServer(nest)", 1, true) ~= nil
			and string.find(body, "nest.sample = nil", 1, true) ~= nil,
		"it re-pins the rig to the server, drops the sweep sample and republishes who is being chased")
	check(string.find(src, "buildAt = buildAt,\n\t\trigId = biome.Id,", 1, true) ~= nil
			and string.find(src, "buildAt = buildAt,\n\t\trigId = \"rain\",", 1, true) ~= nil,
		"buildNest and OpenEventNest keep the recipe a rebuild uses")
	local stepAt = string.find(src, "local function step(nest: Nest, now: number)", 1, true)
	local recoverAt = stepAt and string.find(src, "recoverGuardian(nest, lost, now)", stepAt, true)
	local publishAt = stepAt and string.find(src, "nest.parent:SetAttribute(\"ParentState\", nest.state)", stepAt, true)
	check(recoverAt ~= nil and publishAt ~= nil and recoverAt < publishAt,
		"the tick checks the rig before it touches it")
end)

NestService.SpecRigBuilder(nil)
NestService.SpecWeather(nil)
NestService.SetCarryBridge(nil)
rawset(env, "print", nil)
rawset(env, "warn", nil)
fixture:Destroy()
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
say(string.format("\nGuardianRecoverySpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
