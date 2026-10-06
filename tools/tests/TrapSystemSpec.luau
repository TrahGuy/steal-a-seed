--!nocheck
--==============================================================================
-- Steal a Seed :: TrapSystemSpec
--
-- Five traps, one service, and every shared rule the briefs fix. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("TrapSystemSpec"))
--
--==============================================================================
-- HOW A TRAP IS TESTED WITHOUT A PLAYER AND WITHOUT WAITING
--
-- THE CLOCK IS THE SPEC'S. CombatService reads `os.clock()`, and this spec hands
-- it an `os` whose clock is a number this file moves. So two minutes without an
-- expiry, a re-arm and a 7-second slow are all checked in the same instant, and
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
-- measures distances to it. The OWNER also has a stand-in PlayerGui, because
-- that is where a hidden trap's record goes (2026-10-04).
--
-- THE 2026-10-04 BRIEF, checked here: every trap drops the pod BEFORE its
-- effect; three traps out per owner, any mix, the fourth refused and nothing
-- spent; the spec kept from the placement; a trap drawn for its owner only (no
-- model in the world until it springs); five-second immunity; effects of five
-- to seven seconds on the server's own deadline; a trip and a blast as a short
-- knockdown and a slow.
--
-- AND ITS FOLLOW-UP, THE SAME DAY: no placement recharge -- three in a row,
-- the fourth refused; no expiry; the owner's count (Placed / Capacity / Newest)
-- after every confirmed placement and removal; REMOVE newest first, idempotent,
-- and never another owner's trap; an effect already applied runs to its
-- deadline after its trap is gone; a respawn keeps the traps; a floor that goes
-- away, the owner leaving, a reset and a restart each clear them.
--
-- AND 2026-10-05 (the trigger cooldown, which replaces that day's re-arm): a
-- catch CONSUMES its trap -- one victim, its record gone, its slot back, never
-- re-armed -- and starts its owner's ten-second cooldown, ONE deadline across
-- every trap type, refused through the one placement path every slot and the
-- Bag reach; two bodies in one tick are one catch; the owner's other traps stay
-- live; a later catch refreshes the deadline; REMOVE, a death and a respawn
-- keep it; another owner is untouched; it runs out on time and its published
-- deadline is the server's own wait; and the hotbar counts it down on every
-- trap slot.
--
-- Not here: what any of it LOOKS like, the ragdoll itself (the victim's client
-- owns that, and ThrowFX is checked in Play), the purchase flow, a second REAL
-- client looking at the owner's trap (Play with two people), and bats
-- (BatHitSpec).
--==============================================================================

local CollectionService = game:GetService("CollectionService")
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

local function near(a, b, tol)
	return type(a) == "number" and type(b) == "number" and math.abs(a - b) <= (tol or 0.05)
end

--==============================================================================
-- 1. THE APPROVED SHELF, ON THE 2026-10-04 CLOCKS
--==============================================================================
say("\n-- the five traps --")
local APPROVED = {
	-- id, name, price, effect, arm, duration, slow
	{ "bramblejaw_trap", "Bramblejaw Trap", 150000, "root", 1.0, 5.0, 0 },
	{ "dunesnap_trap", "Dunesnap Plate", 750000, "trip", 0.8, 5.0, 0.60 },
	{ "mirecoil_trap", "Mirecoil Snare", 3500000, "slow", 1.2, 6.0, 0.35 },
	{ "cinderburst_trap", "Cinderburst Mine", 15000000, "blast", 1.4, 6.0, 0.50 },
	{ "starlock_trap", "Starlock Anchor", 60000000, "pull", 1.5, 7.0, 0.40 },
}
do
	local allOk, climbOk = true, true
	local detail = ""
	local previous = -1
	for _, row in ipairs(APPROVED) do
		local id, name, price, effect, arm, duration, slow =
			row[1], row[2], row[3], row[4], row[5], row[6], row[7]
		local item = WeaponData.Get(id)
		local spec = WeaponData.TrapSpec(id)
		if not (item and spec) then
			allOk = false
			detail ..= " missing " .. id
		else
			if item.Name ~= name or item.Price ~= price or item.Category ~= "trap"
				or spec.Effect ~= effect or spec.ArmSeconds ~= arm or spec.EffectSeconds ~= duration
				or (spec.MoveMultiplier or 0) ~= slow or spec.DropsPod ~= true then
				allOk = false
				detail ..= string.format(" %s(%s $%d %s arm %.1f dur %.1f x%.2f drop %s)", id,
					item.Name, item.Price, spec.Effect, spec.ArmSeconds, spec.EffectSeconds,
					spec.MoveMultiplier or 0, tostring(spec.DropsPod))
			end
			if item.Price <= previous then
				climbOk = false
			end
			previous = item.Price
		end
	end
	check(allOk, "every trap's price, effect, arm, duration (5/5/6/6/7s), slow and pod drop are "
		.. "the approved ones", detail)
	check(climbOk, "and the shelf climbs in price, Greenhollow to Starbloom")

	local count = 0
	local everyFive, everyDrops, noClock, everyClear = true, true, true, true
	for _, item in ipairs(WeaponData.Items) do
		if item.Category == "trap" then
			count += 1
			local spec = WeaponData.TrapSpec(item)
			everyFive = everyFive and spec.EffectSeconds >= 5
			everyDrops = everyDrops and spec.DropsPod == true
			noClock = noClock and spec.ExpireSeconds == nil and spec.PlaceCooldownSeconds == nil
			-- The anti-chain rule now: a re-armed trap is under a released victim's
			-- feet, and the immunity at base speed must carry them well clear.
			everyClear = everyClear and T.ImmunitySeconds * GameConfig.Speed.BaseWalkSpeed
				>= 4 * spec.TriggerRadius * T.SeparationRadiusScale
		end
	end
	check(count == 5, "five traps, no more", count)
	check(everyFive, "EVERY trap effect lasts at least five seconds")
	check(everyDrops, "EVERY trap drops the victim's pod (it used to be the Cinderburst alone)")
	check(noClock, "NO trap has a lifetime or a placement recharge any more (ExpireSeconds and "
		.. "PlaceCooldownSeconds are gone)")
	check(everyClear, "and the five-second immunity carries a released victim well clear of any re-armed "
		.. "trigger (the anti-chain rule, with no recharge left to lean on)")
	check(T.ImmunitySeconds == 5.0, "five seconds of immunity after any trap", T.ImmunitySeconds)
	check(T.MaxActivePerPlayer == 3, "three traps out per player", T.MaxActivePerPlayer)
	check(T.SprungSeconds > 0 and T.SprungSeconds <= 1, "the public sprung picture stays brief",
		T.SprungSeconds)
	check(T.PlacedAttribute == "Placed" and T.CapacityAttribute == "Capacity" and T.NewestAttribute == "Newest"
			and type(T.RemoveGapSeconds) == "number" and T.RemoveGapSeconds > 0 and T.RemoveGapSeconds < 0.5,
		"the owner's count has its three attribute names, and REMOVE a short request gap")
	check(WeaponData.TrapsLeftText(WeaponData.TrapsLeft(0, 3)) == "3\u{00D7}"
			and WeaponData.TrapsLeftText(WeaponData.TrapsLeft(1, 3)) == "2\u{00D7}"
			and WeaponData.TrapsLeftText(WeaponData.TrapsLeft(3, 3)) == "0\u{00D7}"
			and WeaponData.TrapsLeft(5, 3) == 0 and WeaponData.TrapsLeft(nil, nil) == 3
			and WeaponData.TrapsLeft(0 / 0, 3) == 3,
		"the count reads 3x / 2x / 0x, never below 0, and an unread count is the full three")

	local jaw = WeaponData.TrapSpec("bramblejaw_trap")
	check(jaw.Effect == "root" and jaw.ArmSeconds == 1.0
			and jaw.TriggerRadius == 4.0 and jaw.TriggerHeight == 4.5
			and jaw.MoveMultiplier == 0 and jaw.JumpLockSeconds == 5.0 and jaw.Model == "jaw",
		"the Bramblejaw is still a root with its placement numbers; the jump is gone for all five seconds")

	-- NO TRAP OUT-FLINGS THE CHEAPEST BAT, and the knockdown stays the short part.
	local rootwood = WeaponData.Get("rootwood_bat")
	local batSpeed = WeaponData.LaunchSpeed(rootwood)
	local mine = WeaponData.TrapSpec("cinderburst_trap")
	local plate = WeaponData.TrapSpec("dunesnap_trap")
	check(mine.LaunchSpeed < batSpeed and plate.LaunchSpeed < mine.LaunchSpeed,
		string.format("Cinderburst launches at %.0f and Dunesnap at %.0f, both under the "
			.. "Rootwood's %.0f", mine.LaunchSpeed, plate.LaunchSpeed, batSpeed))
	check(plate.LaunchMinLimp == 1.1 and mine.LaunchMinLimp == 1.4
			and plate.Status == "slow" and mine.Status == "slow",
		"a trip and a blast keep their 1.1s / 1.4s knockdown and spend the rest of the window slowed")
	local lines = WeaponData.StatLines(WeaponData.Get("starlock_trap"))
	check(#lines == 4 and lines[2].value == "7.0s",
		"the shop card prints the real duration", lines[2] and lines[2].value)
	local noCooldownRow = true
	for _, row in ipairs(APPROVED) do
		for _, line in ipairs(WeaponData.StatLines(WeaponData.Get(row[1]))) do
			noCooldownRow = noCooldownRow and line.label ~= "COOLDOWN"
		end
	end
	check(noCooldownRow and lines[4].label == "PLACE" and lines[4].value == "3 at once",
		"no trap card prints a cooldown; the fourth row says three go down at once",
		lines[4] and (lines[4].label .. " " .. lines[4].value))
	local blurbs = true
	for _, row in ipairs(APPROVED) do
		local b = string.lower(WeaponData.Get(row[1]).Blurb)
		blurbs = blurbs and string.find(b, "hidden", 1, true) ~= nil and string.find(b, "pod", 1, true) ~= nil
			and string.find(b, "once", 1, true) ~= nil and string.find(b, "return", 1, true) ~= nil
			and string.find(b, "re-arm", 1, true) == nil
	end
	check(blurbs, "every trap's card says it is hidden, springs once and comes back, and takes the pod -- "
		.. "and no card promises a re-arm")
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

--==============================================================================
-- THE TRACE: what the service did, in order
--
-- A pod drop, a ragdoll and the attributes a restraint writes all land here,
-- so "the pod came off BEFORE the effect" is an ordering, read back.
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
local function first(name)
	for i, entry in ipairs(trace) do
		if entry.name == name then
			return i, entry
		end
	end
	return nil, nil
end

local function makePlayer(name: string, userId: number, at: Vector3, withGui: boolean?)
	local attributes = {}
	local gui = nil
	if withGui then
		gui = Instance.new("Folder")
		gui.Name = name .. "PlayerGui"
		gui.Parent = fixture
	end
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
			if key == ATTR.Trapped or key == ATTR.TrapSlow or key == ATTR.TrappedUntil then
				record("Attr:" .. key, player, value)
			end
		end,
		FindFirstChildOfClass = function(_, className)
			if className == "PlayerGui" then
				return gui
			end
			return nil
		end,
	}
	player.attributes = attributes
	player.gui = gui
	player.MoveTo = function(where: Vector3)
		local root = player.Character:FindFirstChild("HumanoidRootPart")
		if root then
			root.Position = where
		end
	end
	player.Root = function()
		return player.Character:FindFirstChild("HumanoidRootPart")
	end
	table.insert(roster, player)
	return player
end

--==============================================================================
-- THE STAND-IN SERVICES
--==============================================================================
local MapService = {
	IsInSafeZone = function()
		return false
	end,
	GetMap = function()
		return fixture
	end,
}

-- What CarryService would say is in each player's hands: "carry", "tool" or nil.
local holding: { [any]: string } = {}
local refreshes = 0
local CarryService = {
	IsCarrying = function(player)
		return holding[player] == "carry"
	end,
	HoldsPod = function(player)
		return holding[player] ~= nil
	end,
	DropHeldPod = function(player, at)
		local kind = holding[player]
		record("Drop", player, at, kind)
		if not kind then
			return false, nil
		end
		holding[player] = nil
		return true, kind
	end,
	Drop = function(player, at)
		record("LegacyDrop", player, at)
		return false
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

local cues = {}
local SoundKit = {
	emit = function(name)
		table.insert(cues, name)
	end,
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

--==============================================================================
-- THE THROW REMOTE, WHICH AN EDIT SESSION DOES NOT HAVE
--
-- Remotes are made at runtime by ServerMain. The service finds them through
-- ReplicatedStorage.SeedGame.Remotes, so that one lookup is stood in -- the
-- shared modules still come from the real Shared folder -- and a launch's
-- impulse lands in `throwSent`, where its speed and knockdown floor are read.
--==============================================================================
local realSeedGame = ReplicatedStorage:WaitForChild("SeedGame")
local fakeRemotes = {
	FindFirstChild = function(_, name)
		if name == GameConfig.Remotes.ThrowVictim then
			return fakeThrow
		end
		return nil
	end,
}
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
local fakeReplicated = {
	WaitForChild = function(_, name)
		if name == "SeedGame" then
			return fakeSeedGame
		end
		return ReplicatedStorage:WaitForChild(name)
	end,
}

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
local refusals = {}

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
-- A LAUNCH SPAWNS THE BACKSTOP LOOP, which compares the SPEC'S clock against
-- its own deadline while yielding on the real one. A spec that advanced the
-- clock and never yielded would leave that loop parked forever -- `flying`
-- still set, the victim untargetable, and every later catch silently skipped.
-- And a sprung trap's public picture goes on a task.delay(0.6). So this
-- advances the clock past the backstop and yields for longer than both.
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

local function marksOf(player)
	local gui = player.gui
	local marks = gui and gui:FindFirstChild(T.MarksGuiName)
	local list = {}
	if marks then
		for _, child in ipairs(marks:GetChildren()) do
			if child:IsA("Configuration") then
				table.insert(list, child)
			end
		end
	end
	return list, marks
end

-- Trap models anywhere under the fixture (which is the stand-in map): the
-- public SPRUNG picture, and nothing else may ever be there.
local function modelsInWorld(): number
	local n = 0
	for _, d in ipairs(fixture:GetDescendants()) do
		if d:IsA("Model") and d:GetAttribute(WeaponModel.TrapModelAttribute) ~= nil then
			n += 1
		end
	end
	return n
end

local function lastRefusal()
	return refusals[#refusals]
end

-- The owner's count, as the hotbar reads it: Placed, Capacity, Newest on the
-- records' own gui (2026-10-04).
local function slots(player)
	local _, holder = marksOf(player)
	if not holder then
		return nil, nil, nil
	end
	return holder:GetAttribute(T.PlacedAttribute), holder:GetAttribute(T.CapacityAttribute),
		holder:GetAttribute(T.NewestAttribute)
end

local function idsOf(player)
	local ids = {}
	for _, row in ipairs(CombatService.TrapsOf(player)) do
		table.insert(ids, row.id)
	end
	return ids
end

-- A clean start for the next case: none of the owner's traps out (nothing
-- expires any more, so each case clears what the last one set), the victim's
-- immunity behind them, and the victim well away.
local AWAY = Vector3.new(4050, GROUND_Y + 3, 4050)
local function fresh()
	CombatService.ClearTrap(owner)
	settle()
	-- A second at a time, as a server's Heartbeat would: one 40-second step
	-- would release a hold 34 seconds late, and the immunity counted from that
	-- release would reach into the next case.
	for _ = 1, 40 do
		step(1)
	end
	victim.MoveTo(AWAY)
	trace = {}
	throwSent = {}
end

local function run()
	owner = makePlayer("SpecOwner", 4001, Vector3.new(4000, GROUND_Y + 3, 4000), true)
	victim = makePlayer("SpecVictim", 4002, Vector3.new(4060, GROUND_Y + 3, 4060), true)
	second = makePlayer("SpecSecond", 4003, Vector3.new(4080, GROUND_Y + 3, 4080))

	ActionRefusal.capture(function(player, code)
		table.insert(refusals, { player = player, code = code })
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
		}, {
			-- SoundKit comes from Shared, not a sibling: overridden by name so the
			-- cues the service plays are the spec's to read.
			SoundKit = SoundKit,
		})
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
	-- THREE TRAPS OUT, ANY MIX; THE FOURTH REFUSED; NOTHING SPENT
	--==========================================================================
	say("\n-- three in a row, any mix, no recharge --")
	local p0, c0, n0 = slots(owner)
	check(p0 == 0 and c0 == 3 and n0 == 0,
		"before any trap is set the owner's count is already the server's: 0 of 3 out (3x)",
		string.format("%s/%s newest %s", tostring(p0), tostring(c0), tostring(n0)))
	local refusedBefore = #refusals
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "bramblejaw_trap")
	local p1, _, n1 = slots(owner)
	check(CombatService.TrapCount(owner) == 1 and p1 == 1 and n1 == idsOf(owner)[1],
		"the owner sets a Bramblejaw, and the count says so at once (2x left)", p1)
	-- The same instant, no clock moved: nothing recharges between them.
	owner.MoveTo(Vector3.new(4020, GROUND_Y + 3, 4000))
	place(owner, "mirecoil_trap")
	owner.MoveTo(Vector3.new(4040, GROUND_Y + 3, 4000))
	place(owner, "dunesnap_trap")
	local ids = idsOf(owner)
	local p3, c3, n3 = slots(owner)
	check(CombatService.TrapCount(owner) == 3 and #refusals == refusedBefore,
		"a Mirecoil and a Dunesnap go down right after it, in the same instant: three out, none refused",
		CombatService.TrapCount(owner))
	check(p3 == 3 and c3 == 3 and n3 == ids[3] and ids[1] < ids[2] and ids[2] < ids[3],
		"the count reads 3 of 3 (0x) and names the Dunesnap as the newest", string.format("%s/%s newest %s",
			tostring(p3), tostring(c3), tostring(n3)))
	owner.MoveTo(Vector3.new(4060, GROUND_Y + 3, 4000))
	local before = #refusals
	place(owner, "cinderburst_trap")
	check(CombatService.TrapCount(owner) == 3 and #refusals == before + 1
			and lastRefusal().code == "TRAP_LIMIT",
		"the FOURTH is refused with TRAP_LIMIT", lastRefusal() and lastRefusal().code)
	local marks = marksOf(owner)
	check(#marks == 3 and select(1, slots(owner)) == 3 and select(3, slots(owner)) == ids[3],
		"and nothing is lost: three records stand and the count is unchanged", #marks)
	check(ActionRefusal.Text.TRAP_LIMIT == "You already have 3 traps out."
			and ActionRefusal.Notices.TRAP_LIMIT ~= nil
			and string.find(ActionRefusal.Notices.TRAP_LIMIT.detail or "", "REMOVE", 1, true) ~= nil
			and ActionRefusal.Text.TRAP_COOLDOWN ~= nil and ActionRefusal.Notices.TRAP_COOLDOWN ~= nil
			and ActionRefusal.Notices.TRAP_COOLDOWN.title == "TRAP COOLING DOWN",
		"the refusal says why and points at REMOVE; TRAP_COOLDOWN names the trigger cooldown (2026-10-05)",
		ActionRefusal.Notices.TRAP_LIMIT and ActionRefusal.Notices.TRAP_LIMIT.detail)

	--==========================================================================
	-- HIDDEN: A RECORD FOR THE OWNER, NOTHING IN THE WORLD
	--==========================================================================
	say("\n-- hidden from everybody but the owner --")
	local _, holder = marksOf(owner)
	check(holder ~= nil and holder:IsA("ScreenGui") and holder.ResetOnSpawn == false and holder.Enabled == false,
		"the owner's PlayerGui holds the records in a disabled, respawn-proof ScreenGui")
	local rec = marks[1]
	local attrsOk = true
	for _, m in ipairs(marks) do
		attrsOk = attrsOk and WeaponData.Get(m:GetAttribute("ItemId")) ~= nil
			and type(m:GetAttribute("Id")) == "number"
			and typeof(m:GetAttribute("At")) == "Vector3"
			and type(m:GetAttribute("PlacedAt")) == "number"
			and near(m:GetAttribute("ArmFrom"), m:GetAttribute("PlacedAt"), 0.01)
			and m:GetAttribute("ArmsAt") > m:GetAttribute("PlacedAt")
			and m:GetAttribute("ExpiresAt") == nil and m:GetAttribute("SprungAt") == nil
			and m:GetAttribute("Springs") == nil
	end
	check(rec ~= nil and attrsOk, "each record names its id, item, spot and server-time arming -- and no "
		.. "expiry, because there is none")
	check(holder ~= nil and holder:GetAttribute(T.CooldownAttribute) == nil and CombatService.TrapCooldown(owner) == 0,
		"three placements in a row started no wait: setting a trap costs nothing")
	check(modelsInWorld() == 0, "and there is NO trap model in the world: nothing for another client to see",
		modelsInWorld())
	check(#marksOf(victim) == 0, "the victim's own PlayerGui holds nothing of the owner's traps")
	local placeCues = 0
	for _, name in ipairs(cues) do
		if name == "TrapPlace" or name == "TrapArmed" then
			placeCues += 1
		end
	end
	check(placeCues == 0, "and the server plays no placement or arming sound the road could hear")

	--==========================================================================
	-- THE OWNER WALKS OVER THEIR OWN TRAP; JUMPING CLEARS ONE
	--==========================================================================
	say("\n-- the catch --")
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	step(1.1)
	check(owner.attributes[ATTR.Trapped] ~= true and CombatService.TrapCount(owner) == 3,
		"the owner standing on their own armed trap is not caught, and it stays")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	victim.MoveTo(Vector3.new(4000, GROUND_Y + 3 + 6.0, 4000))
	step(0.1)
	check(victim.attributes[ATTR.Trapped] ~= true, "a player passing over above its ceiling is not caught")

	-- THE BRAMBLEJAW: the pod first, then the root, on the server's deadline.
	trace = {}
	holding[victim] = "tool"
	local standing = Vector3.new(4001, GROUND_Y + 3, 4000)
	victim.MoveTo(standing)
	local catchServer = Workspace:GetServerTimeNow()
	step(0.1)
	local dropAt, dropEntry = first("Drop")
	local rootAt = first("Attr:" .. ATTR.Trapped)
	check(dropAt ~= nil and rootAt ~= nil and dropAt < rootAt,
		"the Bramblejaw drops the pod BEFORE it roots", string.format("drop %s root %s", tostring(dropAt), tostring(rootAt)))
	check(dropEntry and dropEntry.args[3] == "tool" and dropEntry.args[2] == standing and count("Drop") == 1,
		"exactly one pod -- a banked one held in the hands -- at the feet they stood on")
	check(victim.attributes[ATTR.Trapped] == true and victim.attributes[ATTR.TrappedKind] == "root",
		"they are rooted, labelled as a root")
	check(near(victim.attributes[ATTR.TrappedUntil], catchServer + 5.0, 0.2),
		"the countdown is the server's own five-second deadline",
		string.format("%.2f vs %.2f", victim.attributes[ATTR.TrappedUntil] or -1, catchServer + 5.0))
	local humanoid = victim.Character:FindFirstChildOfClass("Humanoid")
	check(humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) == false, "their jump is gone")
	check(CombatService.TrapCount(owner) == 2 and #marksOf(owner) == 2 and select(1, slots(owner)) == 2
			and select(3, slots(owner)) == ids[3],
		"and the trap is CONSUMED (2026-10-05): two out, two records, its slot back (1x), the Dunesnap still the newest",
		CombatService.TrapCount(owner))
	local jawGone = true
	for _, m in ipairs(marksOf(owner)) do
		jawGone = jawGone and m:GetAttribute("Id") ~= ids[1]
	end
	check(jawGone and #CombatService.TrapsOf(owner) == 2, "its record went with it: nothing left to re-arm")
	local _, holderNow = marksOf(owner)
	local coolAttr = holderNow and holderNow:GetAttribute(T.CooldownAttribute)
	check(T.TriggerCooldownSeconds == 10 and near(CombatService.TrapCooldown(owner), 10, 0.15)
			and near(coolAttr, catchServer + 10, 0.3),
		"and the owner's trigger cooldown starts: ten seconds, published on the records as a SERVER-time deadline",
		string.format("%.2f left, deadline %.2f vs %.2f", CombatService.TrapCooldown(owner), coolAttr or -1,
			catchServer + 10))
	check(near((coolAttr or 0) - Workspace:GetServerTimeNow(), CombatService.TrapCooldown(owner), 0.3),
		"the deadline the hotbar counts against GetServerTimeNow is the server's own wait")
	check(modelsInWorld() == 1, "the sprung trap is shown to everybody, built on the server now",
		modelsInWorld())
	local springCue = false
	for _, name in ipairs(cues) do
		springCue = springCue or name == "TrapSpringBramblejaw"
	end
	check(springCue, "with its own spring sound")

	-- THE COOLDOWN HOLDS THE SLOT THE CATCH GAVE BACK: every trap type refused,
	-- through the one placement path every hotbar slot and the Bag reach.
	local refusedAll = true
	for i, id in ipairs({ "bramblejaw_trap", "dunesnap_trap", "mirecoil_trap", "cinderburst_trap", "starlock_trap" }) do
		owner.MoveTo(Vector3.new(4060 + i * 14, GROUND_Y + 3, 4030))
		before = #refusals
		place(owner, id)
		refusedAll = refusedAll and #refusals == before + 1 and lastRefusal().code == "TRAP_COOLDOWN"
	end
	check(refusedAll and CombatService.TrapCount(owner) == 2,
		"inside the ten seconds EVERY trap type is refused with TRAP_COOLDOWN, the free slot notwithstanding -- "
			.. "one wait for every trap, whichever slot or the Bag asks", CombatService.TrapCount(owner))
	local coolBefore = CombatService.TrapCooldown(owner)
	check(CombatService.RequestRemove(owner, ids[3]) == true and CombatService.TrapCount(owner) == 2 - 1
			and select(1, slots(owner)) == 1 and select(3, slots(owner)) == ids[2]
			and near(CombatService.TrapCooldown(owner), coolBefore, 0.001)
			and holderNow:GetAttribute(T.CooldownAttribute) == coolAttr,
		"REMOVE takes the newest (the Dunesnap) -- 2x left -- and leaves the cooldown exactly as it was",
		CombatService.TrapCount(owner))
	owner.MoveTo(Vector3.new(4060, GROUND_Y + 3, 4000))
	before = #refusals
	place(owner, "cinderburst_trap")
	check(CombatService.TrapCount(owner) == 1 and #refusals == before + 1 and lastRefusal().code == "TRAP_COOLDOWN",
		"so the slot REMOVE gave back is no way round it either")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))

	--==========================================================================
	-- NOTHING STACKS, AND AN IMMUNE VICTIM DOES NOT USE A TRAP UP
	--==========================================================================
	victim.MoveTo(Vector3.new(4020, GROUND_Y + 3, 4000))
	step(0.1)
	check(victim.attributes[ATTR.TrappedKind] == "root" and victim.attributes[ATTR.TrapSlow] == nil,
		"a rooted player stepping into the snare is not converted or stacked")
	check(CombatService.TrapCount(owner) == 1 and holderNow:GetAttribute(T.CooldownAttribute) == coolAttr,
		"and the snare is still there, armed, for the next body -- no catch, no new cooldown")
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))

	say("\n-- release and immunity --")
	step(4.7)
	check(victim.attributes[ATTR.Trapped] == true, "still rooted at 4.8s of 5")
	step(0.3)
	check(victim.attributes[ATTR.Trapped] == nil and victim.attributes[ATTR.TrappedUntil] == nil,
		"released at five seconds, and the countdown goes with it")
	check(humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) == true, "their jump comes back")
	local lastRefresh = 0
	for i, entry in ipairs(trace) do
		if entry.name == "RefreshWalkSpeed" then
			lastRefresh = i
		end
	end
	check(lastRefresh > rootAt, "and the release RECOMPUTES movement through CarryService")

	-- FIVE SECONDS in which the armed snare cannot catch them.
	victim.MoveTo(Vector3.new(4020, GROUND_Y + 3, 4000))
	step(0.2)
	check(victim.attributes[ATTR.TrapSlow] == nil and CombatService.TrapCount(owner) == 1,
		"the snare they stand in cannot catch them inside the immunity, and is not used up")
	step(4.6)
	check(victim.attributes[ATTR.TrapSlow] == nil, "still immune at 4.8s")
	owner.MoveTo(Vector3.new(4060, GROUND_Y + 3, 4000))
	before = #refusals
	place(owner, "cinderburst_trap")
	check(#refusals == before + 1 and lastRefusal().code == "TRAP_COOLDOWN" and CombatService.TrapCount(owner) == 1,
		"9.9 seconds after the catch, a placement is still refused", CombatService.TrapCooldown(owner))
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	local secondCatch = Workspace:GetServerTimeNow()
	step(0.3)
	check(victim.attributes[ATTR.TrapSlow] == 0.35,
		"and once the five seconds are over, the same snare catches them",
		tostring(victim.attributes[ATTR.TrapSlow]))
	local refreshed = holderNow:GetAttribute(T.CooldownAttribute)
	check(CombatService.TrapCount(owner) == 0 and #marksOf(owner) == 0 and select(1, slots(owner)) == 0
			and select(3, slots(owner)) == 0,
		"the snare is consumed too: nothing out, no records, 3x -- and no REMOVE to show")
	check(near(CombatService.TrapCooldown(owner), 10, 0.15) and type(refreshed) == "number" and refreshed > coolAttr
			and near(refreshed, secondCatch + 10, 0.4),
		"the later catch REFRESHES the deadline to ten seconds after itself -- the later of the two, never a sum",
		string.format("%.2f left, %.2f -> %.2f", CombatService.TrapCooldown(owner), coolAttr or -1, refreshed or -1))

	--==========================================================================
	-- THE SNARE: SIX SECONDS AT 35%, JUMP BACK AFTER ONE
	--==========================================================================
	say("\n-- the slow --")
	check(victim.attributes[ATTR.Trapped] ~= true and victim.attributes[ATTR.TrappedKind] == "slow",
		"they are slowed, not rooted, and the countdown says so")
	check(humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) == false,
		"jumping is gone for the first second")
	step(1.1)
	check(humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) == true
			and victim.attributes[ATTR.TrapSlow] == 0.35,
		"and back a second in, while the slow runs on")
	step(4.7)
	check(victim.attributes[ATTR.TrapSlow] == 0.35, "still slowed at 5.8s of 6")
	step(0.3)
	check(victim.attributes[ATTR.TrapSlow] == nil, "the slow ends after its six seconds")

	--==========================================================================
	-- A GUARDIAN RELEASES A TRAP EFFECT
	--==========================================================================
	say("\n-- a guardian --")
	fresh()
	owner.MoveTo(Vector3.new(4040, GROUND_Y + 3, 4040))
	place(owner, "mirecoil_trap")
	owner.MoveTo(Vector3.new(4060, GROUND_Y + 3, 4040))
	place(owner, "dunesnap_trap")
	check(CombatService.TrapCount(owner) == 2, "two traps out", CombatService.TrapCount(owner))
	CombatService.ClearTrap(owner)
	check(CombatService.TrapCount(owner) == 0 and #marksOf(owner) == 0,
		"a progress reset clears every trap the owner had out, records and all")
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "bramblejaw_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	step(1.1)
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	step(0.1)
	check(victim.attributes[ATTR.Trapped] == true, "the victim is rooted again")
	check(bridge.ReleaseTrap(victim, "guardian") == true,
		"the guardian bridge releases the root and says it did")
	check(victim.attributes[ATTR.Trapped] == nil and victim.attributes[ATTR.TrapSlow] == nil,
		"leaving no restraint attribute behind")
	check(bridge.ReleaseTrap(victim, "guardian") == false, "and a second release is a harmless no-op")

	--==========================================================================
	-- THE TRIP: POD, SHORT KNOCKDOWN, THEN A SLOW FOR THE REST OF FIVE SECONDS
	--==========================================================================
	say("\n-- the trip --")
	fresh()
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "dunesnap_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	step(0.9)
	holding[victim] = "carry"
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	catchServer = Workspace:GetServerTimeNow()
	step(0.1)
	local d1 = first("Drop")
	local r1 = first("RagdollOn")
	local s1 = first("Attr:" .. ATTR.TrapSlow)
	check(d1 and r1 and s1 and d1 < r1 and d1 < s1 and count("Drop") == 1,
		"the pod comes off first, then the knockdown and the slow", string.format("%s %s %s",
			tostring(d1), tostring(r1), tostring(s1)))
	check(count("RagdollOn") == 1 and #throwSent == 1 and throwSent[1].style.minLimp == 1.1
			and throwSent[1].speed == 7,
		"ONE short knockdown: the 1.1s floor, the 7-stud trip, never a five-second ragdoll")
	check(victim.attributes[ATTR.TrapSlow] == 0.60 and victim.attributes[ATTR.TrappedKind] == "slow"
			and near(victim.attributes[ATTR.TrappedUntil], catchServer + 5.0, 0.2),
		"and a 60% slow under ONE countdown for the whole five seconds",
		string.format("%s %s", tostring(victim.attributes[ATTR.TrapSlow]),
			tostring((victim.attributes[ATTR.TrappedUntil] or 0) - catchServer)))
	settle() -- 4.1s: the knockdown has ended, the slow has not
	check(count("RagdollOff") == 1 and victim.attributes[ATTR.TrapSlow] == 0.60,
		"the body is up (restored once) and still slowed")
	step(1.0)
	check(victim.attributes[ATTR.TrapSlow] == nil and victim.attributes[ATTR.TrappedUntil] == nil,
		"and the slow ends at five seconds")

	--==========================================================================
	-- THE BLAST: SIX SECONDS, HALF SPEED AFTER THE KNOCKDOWN
	--==========================================================================
	say("\n-- the blast --")
	fresh()
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "cinderburst_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	step(1.5)
	holding[victim] = "carry"
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	catchServer = Workspace:GetServerTimeNow()
	step(0.1)
	d1, r1 = first("Drop"), first("RagdollOn")
	check(d1 and r1 and d1 < r1 and count("Drop") == 1 and count("RagdollOn") == 1,
		"exactly one pod, dropped before the one blast")
	check(throwSent[1] and throwSent[1].style.minLimp == 1.4 and throwSent[1].speed == 16,
		"a 1.4s knockdown at 16 studs a second")
	check(victim.attributes[ATTR.TrapSlow] == 0.50
			and near(victim.attributes[ATTR.TrappedUntil], catchServer + 6.0, 0.2),
		"then half speed, on a six-second countdown")
	settle()
	step(1.7)
	check(victim.attributes[ATTR.TrapSlow] == 0.50, "still slowed at 5.8s")
	step(0.3)
	check(victim.attributes[ATTR.TrapSlow] == nil, "free at six")

	-- A victim with no pod is still blasted, and nothing is created.
	fresh()
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "cinderburst_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	step(1.5)
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	step(0.1)
	check(count("RagdollOn") == 1 and count("Drop") == 1 and holding[victim] == nil,
		"a victim with no pod is still launched; the drop asks and finds nothing")

	--==========================================================================
	-- THE PULL: POD OFF WHERE THEY STOOD, THEN DRAGGED, THEN SEVEN SECONDS
	--==========================================================================
	say("\n-- the pull --")
	fresh()
	local wall = Instance.new("Part")
	wall.Name = "SpecWall"
	wall.Size = Vector3.new(1, 12, 30)
	wall.Anchored = true
	wall.Position = Vector3.new(4002, GROUND_Y + 6, 4000)
	wall.Parent = fixture
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "starlock_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	step(1.6)
	holding[victim] = "tool"
	victim.MoveTo(Vector3.new(4003.6, GROUND_Y + 3, 4000))
	step(0.1)
	local pulledTo = victim.Root().Position
	check(victim.attributes[ATTR.TrapSlow] == 0.40, "the anchor slows them to 40%")
	check(pulledTo.X > 4002.4, string.format("the pull stopped at the wall (x %.2f)", pulledTo.X))
	local _, drop = first("Drop")
	check(drop and drop.args[2] == Vector3.new(4003.6, GROUND_Y + 3, 4000),
		"and the pod came off where they stood, before the pull moved them")
	wall:Destroy()

	fresh()
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "starlock_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	step(1.6)
	victim.MoveTo(Vector3.new(4004, GROUND_Y + 3, 4000))
	catchServer = Workspace:GetServerTimeNow()
	step(0.1)
	local after = victim.Root().Position
	check(after.X < 4003.0 and after.X >= 4000.0,
		string.format("a clear pull drags them toward the anchor and never past it (x %.2f)", after.X))
	check(near(victim.attributes[ATTR.TrappedUntil], catchServer + 7.0, 0.2),
		"on a seven-second countdown")
	step(6.7)
	check(victim.attributes[ATTR.TrapSlow] == 0.40, "still slowed at 6.8s")
	step(0.4)
	check(victim.attributes[ATTR.TrapSlow] == nil, "free at seven")

	--==========================================================================
	-- THE SPECIFICATION IS THE ONE IT WAS SET WITH
	--==========================================================================
	say("\n-- kept from the placement --")
	fresh()
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	held[owner] = WeaponData.Get("bramblejaw_trap")
	place(owner, "bramblejaw_trap")
	-- The owner switches to a Starlock and walks away.
	held[owner] = WeaponData.Get("starlock_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	step(1.1)
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	step(0.1)
	check(victim.attributes[ATTR.Trapped] == true and victim.attributes[ATTR.TrappedKind] == "root",
		"a Bramblejaw set before the owner switched to a Starlock still roots")
	held[owner] = nil

	--==========================================================================
	-- ONE CATCH CONSUMES ONE TRAP; THE OWNER'S COOLDOWN (2026-10-05)
	--==========================================================================
	say("\n-- consumed, and the trigger cooldown --")
	fresh()
	do
		local _, rec0 = marksOf(owner)
		check(CombatService.TrapCooldown(owner) == 0 and rec0 ~= nil and rec0:GetAttribute(T.CooldownAttribute) == nil,
			"forty seconds on, every earlier cooldown has run out and its deadline is gone from the records")
	end
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "bramblejaw_trap")
	owner.MoveTo(Vector3.new(4020, GROUND_Y + 3, 4000))
	place(owner, "mirecoil_trap")
	owner.MoveTo(Vector3.new(4040, GROUND_Y + 3, 4000))
	place(owner, "dunesnap_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	local _, mire, sand = table.unpack(idsOf(owner))
	step(1.1)
	-- Two bodies on the jaws in the same tick.
	victim.MoveTo(Vector3.new(4000.5, GROUND_Y + 3, 4000))
	second.MoveTo(Vector3.new(3999.5, GROUND_Y + 3, 4000.5))
	step(0.1)
	local rows = CombatService.TrapsOf(owner)
	check(victim.attributes[ATTR.Trapped] == true and second.attributes[ATTR.Trapped] ~= true
			and second.attributes[ATTR.TrapSlow] == nil,
		"two bodies on the jaws in the same frame: ONE is caught -- the trap is claimed before the second is looked at")
	check(#rows == 2 and rows[1].id == mire and rows[2].id == sand and select(1, slots(owner)) == 2,
		"exactly one trap consumed: the Mirecoil and the Dunesnap are still down")
	check(modelsInWorld() == 1, "one public snap", modelsInWorld())
	for _ = 1, 30 do
		step(0.1)
	end
	check(second.attributes[ATTR.Trapped] ~= true and second.attributes[ATTR.TrapSlow] == nil,
		"three seconds standing where the jaws were: never caught -- nothing re-arms there")
	check(near(CombatService.TrapCooldown(owner), 7, 0.15), "the cooldown runs: seven seconds left",
		CombatService.TrapCooldown(owner))
	-- Another owner's traps and cooldown are their own.
	second.MoveTo(Vector3.new(4100, GROUND_Y + 3, 4100))
	before = #refusals
	place(second, "mirecoil_trap")
	check(CombatService.TrapCount(second) == 1 and CombatService.TrapCooldown(second) == 0 and #refusals == before,
		"another player sets a trap at once: this owner's cooldown is this owner's", CombatService.TrapCount(second))
	CombatService.ClearTrap(second)
	-- A second catch while the first cooldown still runs: the deadline moves to
	-- ten seconds after IT -- the later of the two, never the sum.
	local _, recNow = marksOf(owner)
	local firstDeadline = recNow:GetAttribute(T.CooldownAttribute)
	second.MoveTo(Vector3.new(4020.5, GROUND_Y + 3, 4000))
	local overlapCatch = Workspace:GetServerTimeNow()
	step(0.1)
	local refreshedDeadline = recNow:GetAttribute(T.CooldownAttribute)
	check(second.attributes[ATTR.TrapSlow] ~= nil and CombatService.TrapCount(owner) == 1
			and near(CombatService.TrapCooldown(owner), 10, 0.15)
			and near(refreshedDeadline, overlapCatch + 10, 0.4) and refreshedDeadline > firstDeadline
			and refreshedDeadline - firstDeadline < 4,
		"a catch on the Mirecoil 3.1s into the cooldown: consumed, and the wait is ten seconds from IT -- "
			.. "not twenty, not what was left", string.format("%.2f left", CombatService.TrapCooldown(owner)))
	second.MoveTo(Vector3.new(4080, GROUND_Y + 3, 4080))
	-- A death and a respawn keep it.
	local deadline = recNow:GetAttribute(T.CooldownAttribute)
	owner.Character:Destroy()
	step(0.1)
	owner.Character = makeCharacter(AWAY + Vector3.new(30, 0, 30))
	step(0.1)
	check(type(deadline) == "number" and recNow:GetAttribute(T.CooldownAttribute) == deadline
			and CombatService.TrapCooldown(owner) > 6,
		"a death and a respawn keep the deadline: it is the owner's, not their body's", CombatService.TrapCooldown(owner))
	owner.MoveTo(Vector3.new(4060, GROUND_Y + 3, 4060))
	before = #refusals
	place(owner, "starlock_trap")
	check(#refusals == before + 1 and lastRefusal().code == "TRAP_COOLDOWN" and CombatService.TrapCount(owner) == 1,
		"and the new body is refused all the same")
	for _ = 1, 9 do
		step(1)
	end
	check(CombatService.TrapCooldown(owner) > 0 and CombatService.TrapCooldown(owner) < 1,
		"a second before the deadline it is still running", CombatService.TrapCooldown(owner))
	step(1)
	check(CombatService.TrapCooldown(owner) == 0 and recNow:GetAttribute(T.CooldownAttribute) == nil,
		"ten seconds after the catch it is over, and its deadline is cleared from the records")
	before = #refusals
	place(owner, "starlock_trap")
	owner.MoveTo(Vector3.new(4060, GROUND_Y + 3, 4085))
	place(owner, "cinderburst_trap")
	check(#refusals == before and CombatService.TrapCount(owner) == 3 and select(1, slots(owner)) == 3,
		"and the slots the catches gave back take traps again -- three out, the shared limit")
	owner.MoveTo(Vector3.new(4085, GROUND_Y + 3, 4060))
	place(owner, "bramblejaw_trap")
	check(lastRefusal().code == "TRAP_LIMIT" and CombatService.TrapCount(owner) == 3,
		"and a fourth is the limit's again, not the cooldown's")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	victim.MoveTo(AWAY)

	--==========================================================================
	-- REMOVE: NEWEST FIRST, THE OWNER'S ALONE, ONCE PER PRESS (2026-10-04)
	--==========================================================================
	say("\n-- REMOVE --")
	fresh()
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "bramblejaw_trap")
	owner.MoveTo(Vector3.new(4020, GROUND_Y + 3, 4000))
	place(owner, "mirecoil_trap")
	owner.MoveTo(Vector3.new(4040, GROUND_Y + 3, 4000))
	place(owner, "dunesnap_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	local a, b, c = table.unpack(idsOf(owner))
	check(CombatService.TrapCount(owner) == 3, "three out", CombatService.TrapCount(owner))
	check(CombatService.RequestRemove(victim, c) == false and CombatService.TrapCount(owner) == 3
			and select(1, slots(owner)) == 3,
		"ANOTHER player naming the owner's newest trap removes nothing")
	local junkOk = true
	for _, junk in ipairs({ tostring(c), 0, -1, c + 0.5, 0 / 0, math.huge, c + 100, true, {} }) do
		step(0.3)
		junkOk = junkOk and CombatService.RequestRemove(owner, junk) == false
	end
	step(0.3)
	check(junkOk and CombatService.RequestRemove(owner, nil) == false and CombatService.TrapCount(owner) == 3,
		"nor does a string, zero, a negative, a fraction, NaN, infinity, an id never minted or a table")
	step(0.3)
	check(CombatService.RequestRemove(owner, a) == false and CombatService.TrapCount(owner) == 3,
		"nor does the owner naming an OLDER trap of their own: newest first, always")
	step(0.3)
	check(CombatService.RequestRemove(owner, c) == true and CombatService.TrapCount(owner) == 2
			and select(1, slots(owner)) == 2 and select(3, slots(owner)) == b and #marksOf(owner) == 2,
		"the newest (the Dunesnap) comes off: two out, its record gone, the count 1x at once")
	step(0.3)
	check(CombatService.RequestRemove(owner, c) == false and CombatService.TrapCount(owner) == 2,
		"the same press arriving again removes nothing more: idempotent")
	step(0.3)
	check(CombatService.RequestRemove(owner, b) == true and CombatService.TrapCount(owner) == 1,
		"the next press takes the next newest (the Mirecoil)")
	check(CombatService.RequestRemove(owner, a) == false and CombatService.TrapCount(owner) == 1,
		"a press inside the request gap is dropped unanswered (protection, not a recharge)")
	step(0.3)
	check(CombatService.RequestRemove(owner, a) == true and CombatService.TrapCount(owner) == 0
			and select(1, slots(owner)) == 0 and select(3, slots(owner)) == 0 and #marksOf(owner) == 0,
		"and the last: nothing out, no records, the count 3x again")
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "bramblejaw_trap")
	place(owner, "bramblejaw_trap")
	check(CombatService.TrapCount(owner) == 1,
		"a removed trap's own type goes straight back down -- once: the second is refused by separation alone",
		CombatService.TrapCount(owner))
	owner.MoveTo(Vector3.new(4020, GROUND_Y + 3, 4000))
	place(owner, "bramblejaw_trap")
	check(CombatService.TrapCount(owner) == 2, "and a second Bramblejaw a few steps on goes down at once",
		CombatService.TrapCount(owner))
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))

	-- THE TRAP GOING DOES NOT CUT SHORT WHAT IT ALREADY DID: it is gone the
	-- moment it catches (2026-10-05), and the effect runs to its own deadline.
	say("\n-- consumed mid-effect --")
	fresh()
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "bramblejaw_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	step(1.1)
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	local rootServer = Workspace:GetServerTimeNow()
	step(0.1)
	step(0.3)
	check(victim.attributes[ATTR.Trapped] == true and CombatService.TrapCount(owner) == 0 and #marksOf(owner) == 0,
		"the trap that has the victim is already gone -- consumed by the catch, its record with it")
	check(victim.attributes[ATTR.Trapped] == true and near(victim.attributes[ATTR.TrappedUntil], rootServer + 5.0, 0.2),
		"the root it put on them runs on, on its own five-second deadline")
	step(4.2)
	check(victim.attributes[ATTR.Trapped] == true, "still rooted 4.5s in")
	step(0.6)
	check(victim.attributes[ATTR.Trapped] == nil, "released at five, as if the trap were still there")

	--==========================================================================
	-- NOTHING EXPIRES; WHAT CLEARS THEM IS LEAVING, A RESET, A LOST FLOOR OR A
	-- RESTART -- NEVER A DEATH
	--==========================================================================
	say("\n-- no expiry, and cleanup --")
	fresh()
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "dunesnap_trap")
	owner.MoveTo(Vector3.new(4020, GROUND_Y + 3, 4000))
	place(owner, "bramblejaw_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	check(CombatService.TrapCount(owner) == 2, "two down")
	for _ = 1, 120 do
		step(1)
	end
	check(CombatService.TrapCount(owner) == 2 and #marksOf(owner) == 2 and select(1, slots(owner)) == 2,
		"two minutes on -- far past the old 20 and 24 seconds -- both are still out: nothing expires")

	-- The owner dies and comes back: the traps are theirs, not their body's.
	owner.Character:Destroy()
	step(0.1)
	owner.Character = makeCharacter(AWAY + Vector3.new(30, 0, 30))
	step(0.1)
	check(CombatService.TrapCount(owner) == 2 and #marksOf(owner) == 2 and select(1, slots(owner)) == 2,
		"a death and a respawn take nothing: two traps, two records, the same count")
	victim.MoveTo(Vector3.new(4021, GROUND_Y + 3, 4000))
	step(0.1)
	check(victim.attributes[ATTR.Trapped] == true and CombatService.TrapCount(owner) == 1,
		"and a trap set before the death still catches after it -- and is consumed, one left")
	step(5.2)
	victim.MoveTo(AWAY)
	-- The catch's cooldown, waited out a second at a time.
	for _ = 1, 6 do
		step(1)
	end

	-- A floor that goes away takes its trap: nothing is left floating.
	local tempFloor = Instance.new("Part")
	tempFloor.Name = "SpecTemporaryFloor"
	tempFloor.Size = Vector3.new(40, 4, 40)
	tempFloor.Position = Vector3.new(4200, GROUND_Y - 2, 4200)
	tempFloor.Anchored = true
	tempFloor.Parent = fixture
	owner.MoveTo(Vector3.new(4200, GROUND_Y + 3, 4200))
	place(owner, "mirecoil_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	local floorIds = idsOf(owner)
	check(CombatService.TrapCount(owner) == 2, "a second trap goes down on a temporary floor",
		CombatService.TrapCount(owner))
	tempFloor:Destroy()
	step(0.1)
	check(CombatService.TrapCount(owner) == 1 and #marksOf(owner) == 1 and select(1, slots(owner)) == 1
			and select(3, slots(owner)) == floorIds[1],
		"the floor goes (as the Rain biome does when the rain ends): the trap goes with it -- record, slot "
			.. "and all -- and the one on the road stays")

	fresh()
	place(owner, "mirecoil_trap")
	victim.MoveTo(AWAY)
	check(CombatService.TrapCount(owner) == 1, "the owner sets a snare")
	owner.Parent = nil
	step(0.1)
	check(CombatService.TrapCount(owner) == 0, "and it is removed when they leave the server")
	owner.Parent = fakePlayers

	fresh()
	owner.MoveTo(Vector3.new(4000, GROUND_Y + 3, 4000))
	place(owner, "starlock_trap")
	owner.MoveTo(AWAY + Vector3.new(30, 0, 30))
	step(1.6)
	-- The body goes away mid-hold: released, attribute cleared.
	victim.MoveTo(Vector3.new(4001, GROUND_Y + 3, 4000))
	step(0.1)
	check(victim.attributes[ATTR.TrapSlow] == 0.40, "a victim is held")
	victim.Character:Destroy()
	step(0.1)
	check(victim.attributes[ATTR.TrapSlow] == nil and victim.attributes[ATTR.TrappedUntil] == nil,
		"losing their body (death, respawn) releases the restraint and clears the countdown")
	victim.Character = makeCharacter(AWAY)

	fresh()
	place(owner, "bramblejaw_trap")
	CombatService.Init()
	check(CombatService.TrapCount(owner) == 0 and #marksOf(owner) == 0,
		"a service restart removes every trap and every record")
	CombatService.Start()
end

local ok, err = pcall(run)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
ActionRefusal.capture(nil)

--==============================================================================
-- THE RULES THAT ARE READ RATHER THAN DRIVEN
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
	check(combat ~= nil and combat:find('releaseHold(victim, "hit by a bat")', 1, true)
			and combat:find("releaseHold(victim, \"a trap launched them\")", 1, true)
			and combat:find("releaseHold(victim, \"a trap pulled them\")", 1, true),
		"a bat hit, a trap launch and a trap pull each release a restraint before they begin")
	check(combat ~= nil and select(2, combat:gsub("RunService.Heartbeat:Connect", "")) == 1,
		"there is exactly one Heartbeat in the service, whatever the trap count")
	check(combat ~= nil and not combat:find("Instance.new(\"AlignPosition", 1, true)
			and not combat:find("Instance.new(\"BodyPosition", 1, true)
			and not combat:find("Instance.new(\"RopeConstraint", 1, true)
			and not combat:find("Instance.new(\"LinearVelocity", 1, true),
		"and the pull builds no constraint that could outlive the body")
	check(combat ~= nil and not combat:find("CarryService.IsCarrying", 1, true)
			and combat:find("CarryService.DropHeldPod", 1, true),
		"nothing in combat asks IsCarrying any more: every drop goes through DropHeldPod")
	check(combat ~= nil and not combat:find("BuildTrapWorld(item, cf", 1, true)
			and select(2, combat:gsub("WeaponModel.BuildTrapWorld", "")) == 1,
		"the server builds a trap model only once: the sprung picture")

	local carry = sourceOf(Server:FindFirstChild("CarryService"))
	check(carry ~= nil and carry:find("ATTR.TrapSlow", 1, true) == nil
			and carry:find("Attributes.TrapSlow", 1, true),
		"CarryService reads the slow as a fraction of the speed it just computed")
	check(carry ~= nil and not carry:find("previousWalkSpeed", 1, true)
			and not carry:find("restoreWalkSpeed", 1, true),
		"and nothing anywhere captures a WalkSpeed to put back")

	check(combat ~= nil and not combat:find("ExpireSeconds", 1, true) and not combat:find("PlaceCooldownSeconds", 1, true)
			and not combat:find("placeReadyAt", 1, true)
			and select(2, combat:gsub('deny%(player, "TRAP_COOLDOWN"%)', "")) == 1
			and combat:find("clock + T.TriggerCooldownSeconds", 1, true) ~= nil
			and combat:find("table.clear(placeCooldownUntil)", 1, true) ~= nil
			and combat:find("placeCooldownUntil[player] = nil", 1, true) ~= nil,
		"no trap lifetime and no per-placement recharge; ONE trigger cooldown per owner, started by a catch, "
			.. "refused in one place, dropped on leaving and on a restart")
	check(combat ~= nil and not combat:find("springTrap", 1, true) and not combat:find("sprungAt", 1, true)
			and combat:find("consumeTrap(trap, clock)\n\t\t\t\t\t\tapplyTrapEffect(trap, victim, body)", 1, true) ~= nil,
		"a catch is consumed BEFORE its effect is applied, and nothing re-arms anywhere in the service")
	check(combat ~= nil and select(2, combat:gsub("removeTrapsOf%(", "")) == 3
			and select(2, combat:gsub("ClearTrap", "")) >= 1,
		"traps are cleared in bulk only when the owner leaves or is reset (one definition, two callers) -- "
			.. "nothing on a death or a respawn")
	check(combat ~= nil and combat:find("W.TrapRemoveAction", 1, true)
			and combat:find("trap.owner ~= player", 1, true) and combat:find("newestOf(player) ~= id", 1, true),
		"REMOVE is one verb on GameEvent, checked for the sender's own newest trap")

	local marksClient = sourceOf(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("TrapMarks"))
	check(marksClient ~= nil and marksClient:find("WaitForChild(\"PlayerGui\")", 1, true)
			and marksClient:find("WeaponModel.BuildTrapWorld", 1, true)
			and marksClient:find("FireServer", 1, true) == nil
			and marksClient:find("InvokeServer", 1, true) == nil,
		"TrapMarks draws the owner's records from their own PlayerGui and sends nothing")
	check(marksClient ~= nil and marksClient:find("ArmFrom", 1, true) and marksClient:find("if drawn[mark]", 1, true)
			and not marksClient:find("SprungAt", 1, true) and not marksClient:find("SNAP_GRACE", 1, true)
			and select(2, marksClient:gsub("WeaponModel.BuildTrapWorld", "")) == 1,
		"and draws each record ONCE, arming from ArmFrom to ArmsAt -- never a re-arming: a consumed record is erased "
			.. "with its drawing")

	--==========================================================================
	-- THE HOTBAR'S COUNTDOWN (2026-10-05): the deadline read off the records,
	-- every trap slot dimmed and counting
	--==========================================================================
	local TrapRemove = require(Shared:WaitForChild("TrapRemove"))
	local HotbarCard = require(Shared:WaitForChild("HotbarCard"))
	local recs = Instance.new("Configuration")
	recs:SetAttribute(T.PlacedAttribute, 1)
	recs:SetAttribute(T.CapacityAttribute, 3)
	recs:SetAttribute(T.NewestAttribute, 4)
	local quiet = TrapRemove.read(recs)
	recs:SetAttribute(T.CooldownAttribute, 12345.5)
	local cooling = TrapRemove.read(recs)
	recs:SetAttribute(T.CooldownAttribute, 0 / 0)
	local junk = TrapRemove.read(recs)
	check(quiet.cooldownUntil == nil and cooling.cooldownUntil == 12345.5 and junk.cooldownUntil == nil
			and cooling.left == 2 and cooling.placed == 1,
		"TrapRemove reads the deadline beside the count, which it leaves alone (2x left); junk reads as none")
	recs:Destroy()
	local strip = Instance.new("ScreenGui")
	local H = GameConfig.Hotbar
	local card = HotbarCard.build(strip, 1, H, 4)
	HotbarCard.cool(card, H, 7.3, 10)
	local shownCool = card.timer.Visible and card.timer.Text == "8" and card.cooling
		and near(card.cooldown.Size.Y.Scale, 0.73, 0.001) and near(card.preview.hero.ImageTransparency, H.TrapCoolDim, 1e-4)
	HotbarCard.paint(card, H, { empty = false, held = false, number = "1", name = "", uses = "2\u{00D7}" })
	local keptDim = near(card.preview.hero.ImageTransparency, H.TrapCoolDim, 1e-4) and card.uses.Visible and card.uses.Text == "2\u{00D7}"
	HotbarCard.cool(card, H, 0.4, 10)
	local lastSecond = card.timer.Text == "1"
	HotbarCard.cool(card, H, 0, 10)
	local cleared = not card.timer.Visible and not card.cooling and card.cooldown.Size.Y.Scale == 0
		and card.preview.hero.ImageTransparency == 0
	check(shownCool and keptDim and lastSecond and cleared,
		"a slot cooling down: the seconds left over the picture (7.3 reads 8, 0.4 reads 1), the shade at its share, "
			.. "the picture dimmed through a repaint while the count still reads 2x -- and all of it gone at 0")
	strip:Destroy()
	local loadout = sourceOf(game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("LoadoutUI"))
	check(loadout ~= nil and loadout:find("HotbarCard.cool(slot.card, HOT, if isTrap and slot.button.Visible then trapLeft else 0,", 1, true)
			and loadout:find("traps.cooldownUntil - now", 1, true),
		"LoadoutUI's one Heartbeat counts the server's deadline down on EVERY trap slot")
end

fixture:Destroy()

say(string.format("\nTrapSystemSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
