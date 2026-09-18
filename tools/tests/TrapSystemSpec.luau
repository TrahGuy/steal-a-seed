--!nocheck
--==============================================================================
-- Steal a Seed :: TrapSystemSpec
--
-- Five traps, one service, and every shared rule the brief fixes. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("TrapSystemSpec"))
--
--==============================================================================
-- HOW A TRAP IS TESTED WITHOUT A PLAYER AND WITHOUT WAITING
--
-- THE CLOCK IS THE SPEC'S. CombatService reads `os.clock()`, and this spec hands
-- it an `os` whose clock is a number this file moves. So a 30-second cooldown, a
-- 28-second expiry and a 4-second slow are all checked in the same instant, and
-- every assertion is deterministic rather than a race against a wait.
--
-- THE TICK IS THE SPEC'S TOO. RunService is stood in for, so the Heartbeat the
-- service connects is captured rather than fired sixty times a second: this file
-- advances the clock and calls it, which is what makes "arm, then catch, then
-- expire" three separate facts instead of one lucky frame.
--
-- THE PLAYERS ARE TABLES WITH REAL BODIES. A stand-in player carries its own
-- attribute dictionary -- the service sets Trapped, TrapSlow, TrappedKind and
-- TrappedUntil on it, and this file reads them back -- and a REAL Model with a
-- real Humanoid and root, because the service moves it, disables its jump and
-- measures distances to it. Those are the parts that cannot be faked usefully.
--
-- Not here: what any of it LOOKS like, the ragdoll itself (the victim's client
-- owns that, and ThrowFX is checked in Play), the purchase flow (WeaponShopService
-- and its own spec), and the two-player case (Play, with two people).
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")

local ATTR = GameConfig.Attributes
local T = WeaponData.Trap

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
-- 1. THE APPROVED SHELF
--==============================================================================
say("\n-- the five traps --")
local APPROVED = {
	{ "bramblejaw_trap", "Bramblejaw Trap", 150000, "root", 1.0, 15, 2.0 },
	{ "dunesnap_trap", "Dunesnap Plate", 750000, "trip", 0.8, 16, 1.1 },
	{ "mirecoil_trap", "Mirecoil Snare", 3500000, "slow", 1.2, 19, 4.0 },
	{ "cinderburst_trap", "Cinderburst Mine", 15000000, "blast", 1.4, 25, 1.4 },
	{ "starlock_trap", "Starlock Anchor", 60000000, "pull", 1.5, 30, 3.0 },
}
do
	local allOk, climbOk = true, true
	local detail = ""
	local previous = -1
	for _, row in ipairs(APPROVED) do
		local id, name, price, effect, arm, cooldown, duration = row[1], row[2], row[3], row[4], row[5], row[6], row[7]
		local item = WeaponData.Get(id)
		local spec = WeaponData.TrapSpec(id)
		if not (item and spec) then
			allOk = false
			detail ..= " missing " .. id
		else
			if item.Name ~= name or item.Price ~= price or item.Category ~= "trap"
				or spec.Effect ~= effect or spec.ArmSeconds ~= arm
				or spec.PlaceCooldownSeconds ~= cooldown or spec.EffectSeconds ~= duration then
				allOk = false
				detail ..= string.format(" %s(%s $%d %s arm %.1f cd %.0f dur %.1f)", id,
					item.Name, item.Price, spec.Effect, spec.ArmSeconds,
					spec.PlaceCooldownSeconds, spec.EffectSeconds)
			end
			if item.Price <= previous then
				climbOk = false
			end
			previous = item.Price
		end
	end
	check(allOk, "every trap's price, effect, arm time, cooldown and duration are the approved ones", detail)
	check(climbOk, "and the shelf climbs in price, Greenhollow to Starbloom")

	local traps = 0
	for _, item in ipairs(WeaponData.Items) do
		if item.Category == "trap" then
			traps += 1
		end
	end
	check(traps == 5, "five traps, no more", traps)

	-- 2. BRAMBLEJAW IS UNTOUCHED. Every number it shipped with, by value.
	local jaw = WeaponData.TrapSpec("bramblejaw_trap")
	check(jaw.Effect == "root" and jaw.ArmSeconds == 1.0 and jaw.EffectSeconds == 2.0
			and jaw.ExpireSeconds == 20 and jaw.PlaceCooldownSeconds == 15
			and jaw.TriggerRadius == 4.0 and jaw.TriggerHeight == 4.5
			and jaw.MoveMultiplier == 0 and jaw.DropsPod == false and jaw.Model == "jaw",
		"the Bramblejaw's own numbers are exactly what they were")
	check(T.ImmunitySeconds == 4.0, "four seconds of immunity after any trap", T.ImmunitySeconds)

	-- 14. AND NO TRAP OUT-FLINGS THE CHEAPEST BAT.
	local rootwood = WeaponData.Get("rootwood_bat")
	local batSpeed = WeaponData.LaunchSpeed(rootwood)
	local mine = WeaponData.TrapSpec("cinderburst_trap")
	local plate = WeaponData.TrapSpec("dunesnap_trap")
	check(mine.LaunchSpeed < batSpeed and plate.LaunchSpeed < mine.LaunchSpeed,
		string.format("Cinderburst launches at %.0f and Dunesnap at %.0f, both under the "
			.. "Rootwood's %.0f", mine.LaunchSpeed, plate.LaunchSpeed, batSpeed))
	check(mine.DropsPod and not plate.DropsPod and not jaw.DropsPod,
		"only the Cinderburst takes a pod")
end

--==============================================================================
-- THE HARNESS
--==============================================================================
local clock = 1000
local fakeOs = setmetatable({
	clock = function()
		return clock
	end,
}, { __index = os })

local function signal()
	return {
		Connect = function()
			return { Disconnect = function() end }
		end,
	}
end

local fakePlayers = {}
fakePlayers.PlayerRemoving = signal()
fakePlayers.PlayerAdded = signal()
local roster: { any } = {}
function fakePlayers:GetPlayers()
	return roster
end

local fixture = Instance.new("Folder")
fixture.Name = "TrapSystemSpecFixture"
fixture.Parent = Workspace

-- Ground, well above the map and well clear of anything tagged, because placement
-- refuses a trap near a plot, a pod, a nest, a mill or a gate -- which is one of
-- the things being tested, and not something to fight while testing the rest.
local GROUND_Y = 940
local ground = Instance.new("Part")
ground.Name = "SpecGround"
ground.Size = Vector3.new(240, 4, 240)
ground.Position = Vector3.new(4000, GROUND_Y - 2, 4000)
ground.Anchored = true
ground.Parent = fixture

local function makeCharacter(at: Vector3): Model
	local character = Instance.new("Model")
	character.Name = "SpecBody"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.Position = at
	root.Anchored = true
	root.Parent = character
	character.PrimaryPart = root
	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = character
	character.Parent = fixture
	return character
end

local function makePlayer(name: string, userId: number, at: Vector3)
	local attributes = {}
	local player
	player = {
		Name = name,
		UserId = userId,
		Parent = fakePlayers,
		Character = makeCharacter(at),
		CharacterRemoving = signal(),
		CharacterAdded = signal(),
		ChildAdded = signal(),
		GetAttribute = function(_, key)
			return attributes[key]
		end,
		SetAttribute = function(_, key, value)
			attributes[key] = value
		end,
		FindFirstChildOfClass = function(_, className)
			return nil
		end,
	}
	player.attributes = attributes
	player.MoveTo = function(where: Vector3)
		local root = player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			root.Position = where
		end
	end
	table.insert(roster, player)
	return player
end

--==============================================================================
-- THE STAND-IN SERVICES
--==============================================================================
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = { ... } })
end
local function count(name)
	local total = 0
	for _, entry in ipairs(trace) do
		if entry.name == name then
			total += 1
		end
	end
	return total
end
local function last(name)
	for i = #trace, 1, -1 do
		if trace[i].name == name then
			return trace[i]
		end
	end
	return nil
end

local MapService = {
	IsInSafeZone = function()
		return false
	end,
	GetMap = function()
		return fixture
	end,
}

local carrying: { [any]: boolean } = {}
local refreshes = 0
local CarryService = {
	IsCarrying = function(player)
		return carrying[player] == true
	end,
	Drop = function(player, at)
		record("Drop", player, at)
		if not carrying[player] then
			return false
		end
		carrying[player] = nil
		return true
	end,
	RefreshWalkSpeed = function(player)
		refreshes += 1
		record("RefreshWalkSpeed", player)
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

local held: { [any]: any } = {}
local WeaponShopService = {
	HeldItem = function(player)
		return held[player]
	end,
}

local SoundKit = {
	emit = function() end,
	play = function() end,
}

local heartbeat: (() -> ())? = nil
local fakeRun = {
	Heartbeat = {
		Connect = function(_, fn)
			heartbeat = fn
			return { Disconnect = function()
				heartbeat = nil
			end }
		end,
	},
}

local throwSent = {}
local fakeThrow = {
	ClassName = "RemoteEvent",
	IsA = function(_, className)
		return className == "RemoteEvent"
	end,
	FireClient = function(_, victim, dir, speed, lift, clear, hold, style)
		table.insert(throwSent, { victim = victim, dir = dir, speed = speed, lift = lift, style = style })
		record("Throw", victim, speed, lift)
	end,
	OnServerEvent = signal(),
}

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "Players" then
		return fakePlayers
	elseif name == "RunService" then
		return fakeRun
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
		os = fakeOs,
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

--==============================================================================
-- THE SPEC PROPER
--==============================================================================
local CombatService = nil
local owner, victim, second = nil, nil, nil

local function tool(item)
	local t = Instance.new("Tool")
	t.Name = item.Name
	t.RequiresHandle = false
	t:SetAttribute("WeaponItem", item.Id)
	t.Parent = fixture
	return t
end

local function step(by: number)
	clock += by
	if heartbeat then
		heartbeat()
	end
end

--==============================================================================
-- TWO THINGS IN THIS SERVICE RUN ON THE REAL CLOCK, AND BOTH HAVE TO BE LET GO
--
-- A LAUNCH SPAWNS THE BACKSTOP LOOP, which compares the SPEC'S clock against its
-- own deadline while yielding on the real one. A spec that advanced the clock and
-- never yielded would leave that loop parked forever -- `flying` still set, the
-- victim untargetable, and every later catch silently skipped.
--
-- A SPRUNG TRAP IS DESTROYED ON A task.delay(0.6), so the shut jaws are on screen
-- for a moment before the model goes. Until that fires, the owner still HAS a
-- trap -- and one trap per owner means their next placement is refused.
--
-- So this advances the clock past the backstop and then yields for longer than
-- that delay. It is the one place this spec waits on real time, and it waits
-- three quarters of a second rather than the twenty-eight a Starlock's expiry
-- would cost.
--==============================================================================
local function settle()
	step(4)
	task.wait(0.75)
	step(0.1)
end

local function place(player, id)
	local item = WeaponData.Get(id)
	CombatService.RequestPlace(player, item, tool(item))
	return item
end

local function trapsInWorld(): number
	local n = 0
	for _, d in ipairs(fixture:GetDescendants()) do
		if d:IsA("Model") and CollectionService:HasTag(d, GameConfig.Tags.Trap) then
			n += 1
		end
	end
	return n
end

local function body()
end

local function run()
	owner = makePlayer("SpecOwner", 4001, Vector3.new(4000, GROUND_Y + 3, 4000))
	victim = makePlayer("SpecVictim", 4002, Vector3.new(4060, GROUND_Y + 3, 4060))
	second = makePlayer("SpecSecond", 4003, Vector3.new(4080, GROUND_Y + 3, 4080))

	local ok, err = pcall(function()
		CombatService = loadWith(Server.CombatService, {
			GameConfig = GameConfig,
			SoundKit = SoundKit,
			WeaponData = WeaponData,
			WeaponModel = outerRequire(Shared.WeaponModel),
			MapService = MapService,
			CarryService = CarryService,
			NestService = NestService,
			WeaponShopService = WeaponShopService,
		})
		-- Init resolves the throw remote through ReplicatedStorage, which this spec
		-- does not have; Start connects the tick and hands NestService the bridge.
		CombatService.Init()
		CombatService.Start()
	end)
	check(ok and heartbeat ~= nil, "CombatService loads, starts and connects ONE heartbeat", err)
	if not ok then
		return
	end
	check(bridge ~= nil and type(bridge.ReleaseTrap) == "function",
		"and hands NestService the release bridge")

	--==========================================================================
	-- 3, 4, 6. PLACEMENT: ONE TRAP, ITS OWN COOLDOWN, AND ITS OWN ARM TIME
	--==========================================================================
	say("\n-- placement --")
	place(owner, "bramblejaw_trap")
	check(trapsInWorld() == 1, "the owner sets a Bramblejaw", trapsInWorld())
	place(owner, "bramblejaw_trap")
	check(trapsInWorld() == 1, "and a second placement is refused: one trap per owner",
		trapsInWorld())

	-- 6. The cooldown is this trap's own, and it is counted from the placement.
	step(14)
	place(owner, "bramblejaw_trap")
	check(trapsInWorld() == 1, "still refused 14s later, because one is already down")

	--==========================================================================
	-- 3. THE OWNER WALKS OVER THEIR OWN TRAP
	--==========================================================================
	say("\n-- owner immunity --")
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	step(1.1)
	check(owner.attributes[ATTR.Trapped] ~= true,
		"the owner standing on their own armed trap is not caught")
	check(trapsInWorld() == 1, "and the trap is still there")

	--==========================================================================
	-- 5, 7. ONE VICTIM, AND JUMPING CLEARS IT
	--==========================================================================
	say("\n-- the catch --")
	-- Above the trigger ceiling: a jump clears a trap, which is the counterplay.
	victim.MoveTo(Vector3.new(4000, GROUND_Y + 3 + 6.0, 4000))
	step(0.1)
	check(victim.attributes[ATTR.Trapped] ~= true,
		"a player passing over the trap above its ceiling is not caught")

	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	step(0.1)
	check(victim.attributes[ATTR.Trapped] == true, "stepping in it roots them")
	check(victim.attributes[ATTR.TrappedKind] == "root", "labelled as a root",
		tostring(victim.attributes[ATTR.TrappedKind]))
	check(victim.attributes[ATTR.TrapSlow] == nil,
		"and a root sets no movement fraction: it is zero, not a percentage")
	local humanoid = victim.Character:FindFirstChildOfClass("Humanoid")
	check(humanoid ~= nil and humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) == false,
		"their jump is gone")

	-- 5. One trap, one victim: the second player standing in the same spot is not
	-- caught, because the trap has already sprung.
	second.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	step(0.1)
	check(second.attributes[ATTR.Trapped] ~= true, "one trap catches one victim")

	--==========================================================================
	-- 8. AND NOTHING STACKS
	--
	-- The snare goes down TWELVE STUDS AWAY, because placement refuses a trap
	-- inside another one's separation ring -- which is itself the first half of
	-- the no-stacking rule, and is asserted below. The victim is dragged into it
	-- while the root still has them, which is the second half.
	--==========================================================================
	second.MoveTo(Vector3.new(4012, GROUND_Y + 3, 4000))
	place(second, "mirecoil_trap")
	second.MoveTo(Vector3.new(4080, GROUND_Y + 3, 4080))
	step(1.3)
	victim.MoveTo(Vector3.new(4012, GROUND_Y + 3, 4000))
	step(0.1)
	check(victim.attributes[ATTR.TrappedKind] == "root",
		"a second trap cannot convert a rooted player into a slowed one",
		tostring(victim.attributes[ATTR.TrappedKind]))
	check(victim.attributes[ATTR.TrapSlow] == nil,
		"and cannot add its fraction on top of the root")
	-- And a trap inside another's ring is refused outright.
	local before = trapsInWorld()
	second.MoveTo(Vector3.new(4013, GROUND_Y + 3, 4000))
	place(second, "dunesnap_trap")
	check(trapsInWorld() == before,
		"a trap placed inside another trap's ring is refused", trapsInWorld())
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))

	--==========================================================================
	-- 6, 9. THE HOLD ENDS ON TIME, AND LEAVES FOUR SECONDS OF IMMUNITY
	--==========================================================================
	say("\n-- release and immunity --")
	step(2.1)
	check(victim.attributes[ATTR.Trapped] == nil, "the root ends after its two seconds")
	check(victim.attributes[ATTR.TrappedUntil] == nil, "and the countdown goes with it")
	check(humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) == true,
		"and their jump comes back")

	--==========================================================================
	-- AND FOUR SECONDS IN WHICH NOTHING CAN TOUCH THEM
	--
	-- The snare twelve studs away is armed and live. The victim walks into it
	-- INSIDE their immunity and is not caught; they stand in it until the immunity
	-- runs out, and then they are.
	--==========================================================================
	-- NO settle() HERE, on purpose: settling advances the clock past the very four
	-- seconds this is about to test.
	victim.MoveTo(Vector3.new(4012, GROUND_Y + 3, 4000))
	step(0.2)
	check(victim.attributes[ATTR.TrapSlow] == nil,
		"a trap they are standing in cannot catch them inside the immunity")
	step(4.0)
	check(victim.attributes[ATTR.TrapSlow] ~= nil,
		"and once it expires, the same trap does catch them",
		tostring(victim.attributes[ATTR.TrapSlow]))

	--==========================================================================
	-- 16. A SLOW IS A FRACTION, AND NOTHING CAPTURES A SPEED
	--==========================================================================
	say("\n-- the slow --")
	check(victim.attributes[ATTR.TrapSlow] == 0.35,
		"the Mirecoil leaves them 35% of their own speed",
		tostring(victim.attributes[ATTR.TrapSlow]))
	check(victim.attributes[ATTR.Trapped] ~= true, "they are not rooted: they can still walk")
	check(victim.attributes[ATTR.TrappedKind] == "slow",
		"and the countdown over them says so")
	check(humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) == false,
		"jumping is gone for the first second")
	step(1.1)
	check(humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) == true,
		"and back a second in, while the slow runs on")
	check(victim.attributes[ATTR.TrapSlow] == 0.35, "which it does")
	local before = count("RefreshWalkSpeed")
	step(3.0)
	check(victim.attributes[ATTR.TrapSlow] == nil, "the slow ends after its four seconds")
	check(count("RefreshWalkSpeed") > before,
		"and the release RECOMPUTES the speed rather than restoring a captured one")

	--==========================================================================
	-- 11. A GUARDIAN RELEASES A TRAP EFFECT
	--==========================================================================
	say("\n-- a guardian, and a bat --")
	settle()
	step(20)
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "bramblejaw_trap")
	step(1.1)
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	step(0.1)
	check(victim.attributes[ATTR.Trapped] == true, "the victim is rooted again")
	check(bridge.ReleaseTrap(victim, "guardian") == true,
		"the guardian bridge releases the root and says it did")
	check(victim.attributes[ATTR.Trapped] == nil and victim.attributes[ATTR.TrapSlow] == nil,
		"leaving no restraint attribute behind")
	check(bridge.ReleaseTrap(victim, "guardian") == false,
		"and a second release is a harmless no-op")
	settle()

	--==========================================================================
	-- 12, 13. THE CINDERBURST TAKES THE POD, AND ONLY IF THERE IS ONE
	--==========================================================================
	--==========================================================================
	-- WHAT A LAUNCH LOOKS LIKE FROM THE SERVER
	--
	-- The impulse itself goes to the VICTIM'S CLIENT down the ThrowVictim remote,
	-- which does not exist in an Edit session -- and could not be fired at a
	-- stand-in player if it did. So the launch is observed by the three things the
	-- server does around it: the pod comes off through CarryService.Drop, the rig
	-- is loosened through NestService.RagdollOn, and it is restored exactly once.
	--
	-- The numbers on the wire -- speed, lift, the trap's own limp floor -- are
	-- asserted against the spec in section 1, and read back off the victim's own
	-- console in Play, where the client prints "HIT received: trap ...".
	--==========================================================================
	say("\n-- the blast --")
	step(30)
	trace = {}
	carrying[victim] = true
	place(owner, "cinderburst_trap")
	step(1.5)
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	step(0.1)
	check(count("Drop") == 1, "exactly one pod is dropped", count("Drop"))
	check(count("RagdollOn") == 1, "and the victim is ragdolled once", count("RagdollOn"))
	check(carrying[victim] ~= true, "and the pod is no longer theirs")
	settle()
	check(count("RagdollOff") == 1, "the rig is restored exactly once", count("RagdollOff"))

	step(30)
	trace = {}
	place(owner, "cinderburst_trap")
	step(1.5)
	-- Immunity from the last blast has to be over, or this proves nothing.
	step(6)
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	step(0.1)
	check(count("RagdollOn") == 1, "a victim with no pod is still launched", count("RagdollOn"))
	check(count("Drop") == 0, "and no pod is created or dropped", count("Drop"))
	settle()

	--==========================================================================
	-- 15. THE STARLOCK PULL STOPS AT A WALL
	--==========================================================================
	say("\n-- the pull --")
	settle()
	step(35)

	--==========================================================================
	-- THE VICTIM STANDS WELL CLEAR WHILE THE ANCHOR ARMS
	--
	-- This is the mistake this spec made first and it is worth writing down: the
	-- victim was left standing a stud from where the trap was about to go, so it
	-- caught them the moment it armed -- and every assertion after that was about
	-- an effect that had already ended. A trap test has to arm the trap with
	-- nobody in it.
	--==========================================================================
	local AWAY = Vector3.new(4050, GROUND_Y + 3, 4050)

	--== WITH A WALL BETWEEN THEM AND IT ==--
	local wall = Instance.new("Part")
	wall.Name = "SpecWall"
	wall.Size = Vector3.new(1, 12, 30)
	wall.Anchored = true
	wall.Position = Vector3.new(4002, GROUND_Y + 6, 4000)
	wall.Parent = fixture

	victim.MoveTo(AWAY)
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "starlock_trap")
	step(1.6)
	step(5)
	victim.MoveTo(Vector3.new(4003.6, GROUND_Y + 3, 4000))
	step(0.1)
	local pulledTo = victim.Character:FindFirstChild("HumanoidRootPart").Position
	check(victim.attributes[ATTR.TrapSlow] == 0.40,
		"the anchor slows them to 40%", tostring(victim.attributes[ATTR.TrapSlow]))
	check(victim.attributes[ATTR.TrappedKind] == "slow",
		"and labels itself a slow, not a root")
	check(pulledTo.X > 4002.4, string.format(
		"the pull stopped at the wall rather than dragging them through it (x %.2f)",
		pulledTo.X))
	wall:Destroy()

	--== AND WITH NOTHING IN THE WAY ==--
	settle()
	step(40)
	victim.MoveTo(AWAY)
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "starlock_trap")
	step(1.6)
	step(5)
	victim.MoveTo(Vector3.new(4004, GROUND_Y + 3, 4000))
	step(0.1)
	local after = victim.Character:FindFirstChild("HumanoidRootPart").Position
	check(after.X < 4003.0, string.format(
		"a clear pull drags them toward the anchor (x %.2f from x 4004.00)", after.X))
	check(after.X >= 4000.0,
		string.format("and never past it (x %.2f, anchor at 4000)", after.X))
	check(victim.attributes[ATTR.TrapSlow] == 0.40, "and they arrive slowed")
	local humanoidNow = victim.Character:FindFirstChildOfClass("Humanoid")
	check(humanoidNow ~= nil
			and humanoidNow:GetStateEnabled(Enum.HumanoidStateType.Jumping) == false,
		"with their jump gone for the first six tenths")
	step(0.7)
	check(humanoidNow:GetStateEnabled(Enum.HumanoidStateType.Jumping) == true,
		"and back after it, while the slow runs on")
	step(2.5)
	check(victim.attributes[ATTR.TrapSlow] == nil,
		"the slow ends after its three seconds",
		tostring(victim.attributes[ATTR.TrapSlow]))

	say("\n-- expiry --")
	settle()
	step(40)
	place(owner, "dunesnap_trap")
	check(trapsInWorld() >= 1, "a Dunesnap goes down")
	step(24.5)
	check(trapsInWorld() == 0, "and expires after its own 24 seconds", trapsInWorld())

	--==========================================================================
	-- 10. EVERY WAY A TRAP AND A RESTRAINT GO AWAY
	--==========================================================================
	say("\n-- cleanup --")
	settle()
	step(40)
	place(owner, "bramblejaw_trap")
	step(1.1)
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	step(0.1)
	check(victim.attributes[ATTR.Trapped] == true, "a victim is rooted")
	-- The body goes away, which is what a death and a respawn both look like from
	-- here. The tick is the backstop for the signals.
	victim.Character:Destroy()
	step(0.1)
	check(victim.attributes[ATTR.Trapped] == nil,
		"and losing their body releases the restraint and clears the attribute")
	victim.Character = makeCharacter(Vector3.new(4060, GROUND_Y + 3, 4060))

	-- The owner leaving takes their trap with it.
	settle()
	step(40)
	place(owner, "mirecoil_trap")
	check(trapsInWorld() >= 1, "the owner sets a snare")
	owner.Parent = nil
	step(0.1)
	check(trapsInWorld() == 0, "and it is removed when they leave the server", trapsInWorld())
	owner.Parent = fakePlayers
end

local ok, err = pcall(run)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

--==============================================================================
-- 11 (THE BAT HALF), AND THE RULES THAT ARE READ RATHER THAN DRIVEN
--==============================================================================
say("\n-- read off the source --")
do
	local function sourceOf(instance)
		if instance == nil then
			return nil
		end
		local okRead, src = pcall(function()
			return (instance :: any).Source
		end)
		return if okRead then src else nil
	end
	local combat = sourceOf(Server:FindFirstChild("CombatService"))
	check(combat ~= nil and combat:find('releaseHold(hit.player, "hit by a bat")', 1, true),
		"a bat hit releases a trap restraint before its own launch begins")
	check(combat ~= nil and combat:find("releaseHold(victim, \"a trap launched them\")", 1, true)
			and combat:find("releaseHold(victim, \"a trap pulled them\")", 1, true),
		"and so does a trap that launches or pulls")
	check(combat ~= nil and select(2, combat:gsub("RunService.Heartbeat:Connect", "")) == 1,
		"there is exactly one Heartbeat in the service, whatever the trap count")
	--======================================================================
	-- CONSTRUCTION, NOT MENTIONS
	--
	-- The words appear in the banner over the pull, which explains why none of
	-- them is used. What matters is that none of them is CREATED.
	--======================================================================
	check(combat ~= nil and not combat:find("Instance.new(\"AlignPosition", 1, true)
			and not combat:find("Instance.new(\"BodyPosition", 1, true)
			and not combat:find("Instance.new(\"RopeConstraint", 1, true)
			and not combat:find("Instance.new(\"LinearVelocity", 1, true),
		"and the pull builds no constraint that could outlive the body")

	local carry = sourceOf(Server:FindFirstChild("CarryService"))
	check(carry ~= nil and carry:find("ATTR.TrapSlow", 1, true) == nil
			and carry:find("Attributes.TrapSlow", 1, true),
		"CarryService reads the slow as a fraction of the speed it just computed")
	check(carry ~= nil and not carry:find("previousWalkSpeed", 1, true)
			and not carry:find("restoreWalkSpeed", 1, true),
		"and nothing anywhere captures a WalkSpeed to put back")
end

fixture:Destroy()

say(string.format("\nTrapSystemSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
