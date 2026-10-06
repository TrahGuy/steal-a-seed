--!nocheck
--==============================================================================
-- Steal a Seed :: ActionRefusalSpec
--
-- The blocked-action toasts: which refusals are named, which stay silent, and
-- that naming one changed nothing about the refusal itself. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("ActionRefusalSpec"))
--
-- The four distinctions the brief asked to be pinned, each through the REAL
-- guard that makes it:
--
--   a Safe Zone target vs a missed swing      CombatService.RequestSwing
--   a trap in the Safe Zone vs its cooldown   CombatService.RequestPlace
--   out of reach vs a full plot               PlantService.PlaceAt
--   a full hotbar vs a full inventory         CarryService.GivePod / GiveHatched
--
-- ActionRefusal.capture routes every named refusal here instead of down the
-- wire, so stand-in players need no client. CombatService runs on this file's
-- clock, as in TrapSystemSpec, with a Safe Zone that is simply "X at or below
-- EDGE"; the one real wait is a bat's wind-up. PlantService is loaded as in
-- HatchTimerSpec, into a real Level 1 plot dressed by MapService above the map.
--
-- Not here: what the toast looks like and where it sits (HudLayoutSpec places
-- it; Play shows it), a swing at a second real person (Play, two people), and
-- the carry refusal end to end -- a raided pod in real arms (Play). The carry
-- lines are read from source in section 9.
--==============================================================================

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WeaponData = require(Shared:WaitForChild("WeaponData"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local ActionRefusal = require(Shared:WaitForChild("ActionRefusal"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local MapService = require(Server:WaitForChild("MapService"))
local PlantWander = require(Server:WaitForChild("PlantWander"))

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

local function sourceOf(instance)
	if instance == nil then
		return nil
	end
	local ok, src = pcall(function()
		return instance.Source
	end)
	return if ok then src else nil
end

local TEXT = ActionRefusal.Text

--==============================================================================
-- 1. THE WORDS
--==============================================================================
say("-- the words --")
do
	local BRIEF = {
		SAFE_ZONE_TARGET = "Players are protected in the Safe Zone.",
		TRAP_SAFE_ZONE = "Place traps outside the Safe Zone.",
		PLANT_OUT_OF_RANGE = "Move closer to your plot.",
		PLOT_FULL = "Your plot is full.",
		CARRYING_POD = "Bank your pod before doing that.",
	}
	local wrong = {}
	for code, line in pairs(BRIEF) do
		if TEXT[code] ~= line then
			table.insert(wrong, code .. "=" .. tostring(TEXT[code]))
		end
	end
	table.sort(wrong)
	check(#wrong == 0, "the brief's lines, word for word", table.concat(wrong, ", "))
	-- Its sixth, "Trap recharging...", went with the placement recharge
	-- (2026-10-04); the code came back for the TRIGGER cooldown (2026-10-05),
	-- with its own words.
	check(TEXT.TRAP_COOLDOWN == "Your traps are cooling down."
			and ActionRefusal.Notices.TRAP_COOLDOWN ~= nil
			and ActionRefusal.Notices.TRAP_COOLDOWN.title == "TRAP COOLING DOWN"
			and not string.find(TEXT.TRAP_COOLDOWN, "recharg", 1, true),
		"and TRAP_COOLDOWN is the trigger cooldown's (2026-10-05), not the old placement recharge's")

	local bag, belongs, long = {}, {}, {}
	for code, line in pairs(TEXT) do
		local lower = string.lower(line)
		if string.find(lower, "bag", 1, true) or string.find(lower, "inventory", 1, true) then
			table.insert(bag, code)
		end
		if string.find(lower, "belongs to", 1, true) or string.find(lower, "another player", 1, true) then
			table.insert(belongs, code)
		end
		if type(line) ~= "string" or line == "" or (utf8.len(line) or 99) > 40 then
			table.insert(long, code)
		end
	end
	check(#bag == 0, "no \"Bag is full\": the one refusal for room is a hatch's, and says PLANT STORAGE (section 8)",
		table.concat(bag, ", "))
	check(#belongs == 0,
		"no \"That plant belongs to another player.\": nothing lets a player try to take one",
		table.concat(belongs, ", "))
	check(#long == 0, "every line is one short sentence, 40 characters at most",
		table.concat(long, ", "))
	check(type(ActionRefusal.Action) == "string" and ActionRefusal.Action ~= ""
			and ActionRefusal.Action ~= GameConfig.Plant.PlaceAction
			and ActionRefusal.Action ~= GameConfig.Plot.TeleportAction,
		"the toast's verb is its own on GameEvent", ActionRefusal.Action)
end

--==============================================================================
-- 2. THE MAPPING
--==============================================================================
say("\n-- the mapping --")
check(ActionRefusal.fromPlacement("OUT_OF_RANGE") == "PLANT_OUT_OF_RANGE",
	"out of reach is \"Move closer to your plot.\"")
check(ActionRefusal.fromPlacement("BED_FULL") == "PLOT_FULL", "a full bed is \"Your plot is full.\"")
do
	local spoke = {}
	for _, code in ipairs({ "NO_PLOT", "NO_PROFILE", "NO_SOIL", "NO_CHARACTER", "NO_TOOL",
		"UNKNOWN_SPECIES" }) do
		if ActionRefusal.fromPlacement(code) ~= nil then
			table.insert(spoke, code)
		end
	end
	check(#spoke == 0, "every other PlaceAt refusal is internal and says nothing",
		table.concat(spoke, ", "))
end
check(ActionRefusal.fromPlacement(nil) == nil and ActionRefusal.fromPlacement(42) == nil,
	"and nothing that is not a code maps to anything")
check(ActionRefusal.forSwing(0, true) == "SAFE_ZONE_TARGET",
	"a swing the Safe Zone withheld from somebody says so")
check(ActionRefusal.forSwing(0, false) == nil,
	"a swing that reached nobody -- a miss or a wall -- says nothing")
check(ActionRefusal.forSwing(1, true) == nil and ActionRefusal.forSwing(2, false) == nil,
	"a swing that struck somebody says nothing, even with somebody else spared")

--==============================================================================
-- 3. ONE NOTICE PER REASON (Notice.step since 2026-09-27)
--
-- The rule moved into the shared Notice module; a refusal is one of its posts,
-- keyed by code (ActionRefusal.notice). The same promises as the old toast.
--==============================================================================
say("\n-- one notice per reason --")
do
	local Notice = require(Shared:WaitForChild("Notice"))
	local full, range = ActionRefusal.notice("PLOT_FULL"), ActionRefusal.notice("PLANT_OUT_OF_RANGE")
	local life = Notice.lifeOf(full)
	local stack = {}
	local verb1 = Notice.step(stack, full, 100, 3)
	check(verb1 == "show" and #stack == 1 and stack[1].hideAt == 100 + life,
		"the first refusal puts its notice up")
	local verb2 = Notice.step(stack, full, 101, 3)
	check(verb2 == "refresh" and #stack == 1 and stack[1].count == 2,
		"the same refusal again while it is up only stays longer: no sound, nothing stacked", verb2)
	check(stack[1].hideAt == 101 + life, "counted from the latest press", stack[1].hideAt)
	local verb3 = Notice.step(stack, range, 101.5, 3)
	check(verb3 == "show" and #stack == 2, "a different refusal goes up beside it", verb3)
	local late = { { key = "refusal:PLOT_FULL", kind = "blocked", bornAt = 100, hideAt = 100 + life, count = 1 } }
	local verb4 = Notice.step(late, full, 100 + life + 0.01, 3)
	check(verb4 == "show", "the same refusal after it has gone is a new notice", verb4)

	local mash, shows = {}, 0
	local sounds, played = Notice.newSoundState(), 0
	for i = 0, 59 do
		local cooldown = ActionRefusal.notice("TELEPORT_COOLDOWN")
		local verb = Notice.step(mash, cooldown, 200 + i / 30, 3)
		if verb == "show" then
			shows += 1
			if Notice.soundFor(sounds, cooldown, 200 + i / 30) then
				played += 1
			end
		end
	end
	check(shows == 1 and played == 1, "sixty presses in two seconds put up ONE notice and play ONE denial",
		shows .. " / " .. played)
	check(Notice.Styles.blocked.sound == "NoticeBlocked", "a refusal sounds the blocked notice's own cue")
	check(Notice.holdFor(full) >= 1.5 and Notice.holdFor(full) <= 5 and Notice.ExitSeconds > 0
			and Notice.ExitSeconds < 0.5,
		"up for a couple of seconds, with a quick fade",
		string.format("%.2f / %.2f", Notice.holdFor(full), Notice.ExitSeconds))
end

--==============================================================================
-- 4. SENDING
--==============================================================================
say("\n-- sending --")
local captured = {}
ActionRefusal.capture(function(player, code)
	table.insert(captured, { player = player, code = code })
end)

local function codesFor(player, since)
	local list = {}
	for i = (since or 0) + 1, #captured do
		if captured[i].player == player then
			table.insert(list, captured[i].code)
		end
	end
	return list
end

do
	local someone = { Name = "RefusalSpecProbe" }
	ActionRefusal.send(someone, "PLOT_FULL")
	ActionRefusal.send(someone, "NOT_A_CODE")
	ActionRefusal.send(someone, "NO_PLOT")
	local got = codesFor(someone)
	check(#got == 1 and got[1] == "PLOT_FULL",
		"a named code goes out; a code nobody named is dropped before the wire",
		table.concat(got, ","))

	ActionRefusal.capture(nil)
	local wireOk = pcall(ActionRefusal.send, { Name = "NotAPlayer" }, "PLOT_FULL")
	ActionRefusal.capture(function(player, code)
		table.insert(captured, { player = player, code = code })
	end)
	check(wireOk, "on the wire, anything that is not a player in the server is dropped quietly")

	-- A client raise goes straight to the one notice renderer (Notice, 2026-09-27).
	local Notice = require(Shared:WaitForChild("Notice"))
	local heard = {}
	Notice.setRenderer(function(post)
		table.insert(heard, post.key)
	end)
	ActionRefusal.raise("CARRYING_POD")
	ActionRefusal.raise("NOT_A_CODE")
	task.wait(0.05)
	Notice.setRenderer(nil)
	check(#heard == 1 and heard[1] == "refusal:CARRYING_POD",
		"the client's own raise carries a named code and drops the rest", table.concat(heard, ","))
end

--==============================================================================
-- THE COMBAT HARNESS (TrapSystemSpec's, cut down)
--==============================================================================
local clock = 5000
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
local roster = {}
function fakePlayers:GetPlayers()
	return roster
end

-- The Heartbeat is captured (2026-10-04): a swing is resolved by it now, over a
-- short window, so the swing cases below step it on the spec's clock.
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

local fakeMarket = {}
function fakeMarket:PromptProductPurchase() end

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "Players" then
		return fakePlayers
	elseif name == "RunService" then
		return fakeRun
	elseif name == "MarketplaceService" then
		return fakeMarket
	end
	return game:GetService(name)
end

local outerRequire = require
local function loadWith(module, siblings, osTable)
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
		os = osTable or os,
		script = { Name = module.Name, Parent = parent },
		require = function(target)
			if type(target) == "table" and target.__standIn ~= nil then
				return target.__standIn
			end
			return outerRequire(target)
		end,
	}, { __index = getfenv(1) })
	setfenv(chunk, env)
	return chunk()
end

local fixture = Instance.new("Folder")
fixture.Name = "ActionRefusalSpecFixture"
fixture.Archivable = false
fixture.Parent = Workspace

-- Everything at X <= EDGE is "the field" for this spec's MapService.
local EDGE = 5000
local GY = 980
local ground = Instance.new("Part")
ground.Name = "SpecGround"
ground.Anchored = true
ground.Size = Vector3.new(240, 4, 240)
ground.Position = Vector3.new(EDGE, GY - 2, 5000)
ground.Parent = fixture

local WEST, EAST = Vector3.new(-1, 0, 0), Vector3.new(1, 0, 0)

local function makeBody(name, cf)
	local character = Instance.new("Model")
	character.Name = name
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 2, 1)
	root.CFrame = cf
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
	local p = {
		Name = name,
		UserId = userId,
		Parent = fakePlayers,
		CharacterRemoving = signal(),
		CharacterAdded = signal(),
		ChildAdded = signal(),
	}
	p.Character = makeBody(name .. "Body", CFrame.lookAt(at, at + (facing or WEST)))
	function p.GetAttribute(_, key)
		return attributes[key]
	end
	function p.SetAttribute(_, key, value)
		attributes[key] = value
	end
	function p.FindFirstChildOfClass()
		return nil
	end
	table.insert(roster, p)
	return p
end

local function standAt(p, at, facing)
	p.Character:PivotTo(CFrame.lookAt(at, at + (facing or WEST)))
end

local function tool(item, parent)
	local t = Instance.new("Tool")
	t.Name = item.Name
	t.RequiresHandle = false
	t:SetAttribute("WeaponItem", item.Id)
	t.Parent = parent or fixture
	return t
end

-- How many traps the trap-setter has down. A placed trap is server state now,
-- drawn for its owner alone (2026-10-04), so it is counted by the service.
local CombatService = nil
local trapsFor = nil
local function trapsDown()
	return if trapsFor then CombatService.TrapCount(trapsFor) else 0
end

local MapStub = {
	IsInSafeZone = function(position)
		return position.X <= EDGE
	end,
	GetMap = function()
		return fixture
	end,
}

local PlantService = nil
local plantPlot = nil

local function combat()
	local loadOk, loadErr = pcall(function()
		CombatService = loadWith(Server.CombatService, {
			MapService = MapStub,
			CarryService = {
				IsCarrying = function()
					return false
				end,
				HoldsPod = function()
					return false
				end,
				DropHeldPod = function()
					return false, nil
				end,
				Drop = function()
					return false
				end,
				RefreshWalkSpeed = function() end,
			},
			NestService = {
				SetCombatBridge = function() end,
				RagdollOn = function(character)
					return { character }
				end,
				RagdollOff = function() end,
			},
			WeaponShopService = {
				HeldItem = function()
					return nil
				end,
			},
		}, fakeOs)
		CombatService.Init()
		CombatService.Start()
	end)
	check(loadOk, "CombatService loads and starts against the stand-ins", loadErr)
	if not loadOk then
		return
	end

	--==========================================================================
	-- 5. TRAPS: THE SAFE ZONE AND THE LIMIT (no recharge since 2026-10-04)
	--==========================================================================
	say("\n-- traps --")
	local jaw = WeaponData.Get("bramblejaw_trap")
	local setter = makePlayer("RefusalTrapper", 5101, Vector3.new(EDGE - 20, GY + 3, 4900))
	trapsFor = setter

	local mark = #captured
	CombatService.RequestPlace(setter, jaw, tool(jaw))
	local got = codesFor(setter, mark)
	check(#got == 1 and got[1] == "TRAP_SAFE_ZONE" and trapsDown() == 0,
		"a trap set in the Safe Zone is refused: \"Place traps outside the Safe Zone.\"",
		table.concat(got, ","))

	standAt(setter, Vector3.new(EDGE + 30, GY + 3, 4900))
	mark = #captured
	CombatService.RequestPlace(setter, jaw, tool(jaw))
	got = codesFor(setter, mark)
	check(trapsDown() == 1 and #got == 0, "on the road it goes down, and says nothing",
		table.concat(got, ","))

	standAt(setter, Vector3.new(EDGE - 20, GY + 3, 4900))
	mark = #captured
	CombatService.RequestPlace(setter, jaw, tool(jaw))
	got = codesFor(setter, mark)
	check(#got == 1 and got[1] == "TRAP_SAFE_ZONE" and trapsDown() == 1,
		"straight back into the field, it says the field -- there is no recharge to say first (2026-10-04)",
		table.concat(got, ","))

	--==========================================================================
	-- THREE PER OWNER, AND THEN A LINE (2026-10-04)
	--
	-- No placement recharge since the reusable-trap brief: the next two go down
	-- at once, at the same instant, as long as each stands clear of the last.
	-- The fourth is refused WITH a reason -- TRAP_LIMIT -- because "nothing
	-- happened" is not an answer a player can act on.
	--==========================================================================
	standAt(setter, Vector3.new(EDGE + 60, GY + 3, 4900))
	mark = #captured
	CombatService.RequestPlace(setter, jaw, tool(jaw))
	got = codesFor(setter, mark)
	check(#got == 0 and trapsDown() == 2,
		"another Bramblejaw straight away, a few steps on: it goes down (no recharge), silently",
		table.concat(got, ","))
	standAt(setter, Vector3.new(EDGE + 90, GY + 3, 4900))
	CombatService.RequestPlace(setter, jaw, tool(jaw))
	standAt(setter, Vector3.new(EDGE + 110, GY + 3, 4900))
	mark = #captured
	CombatService.RequestPlace(setter, jaw, tool(jaw))
	got = codesFor(setter, mark)
	check(#got == 1 and got[1] == "TRAP_LIMIT" and trapsDown() == 3,
		"a FOURTH while three are down: \"You already have 3 traps out.\"", table.concat(got, ","))

	local neighbour = makePlayer("RefusalNeighbour", 5102, Vector3.new(EDGE + 30, GY + 3, 4960))
	local spawnPad = Instance.new("Part")
	spawnPad.Name = "SpecSpawnPad"
	spawnPad.Anchored = true
	spawnPad.CanCollide = false
	spawnPad.CanQuery = false
	spawnPad.Transparency = 1
	spawnPad.Size = Vector3.new(2, 1, 2)
	spawnPad.Position = Vector3.new(EDGE + 34, GY + 0.5, 4960)
	spawnPad.Parent = fixture
	CollectionService:AddTag(spawnPad, GameConfig.Tags.PlotSpawn)
	mark = #captured
	CombatService.RequestPlace(neighbour, jaw, tool(jaw))
	got = codesFor(neighbour, mark)
	check(#got == 0 and CombatService.TrapCount(neighbour) == 0,
		"beside a plot's spawn pad: refused, and silent -- that is not the Safe Zone",
		table.concat(got, ","))
	spawnPad:Destroy()

	local ghost = makePlayer("RefusalGhost", 5103, Vector3.new(EDGE + 30, GY + 3, 5040))
	ghost.Character:FindFirstChildOfClass("Humanoid").Health = 0
	mark = #captured
	CombatService.RequestPlace(ghost, jaw, tool(jaw))
	got = codesFor(ghost, mark)
	check(#got == 0 and CombatService.TrapCount(ghost) == 0,
		"a dead body's trap: refused, and silent -- a respawn is not a player's action",
		table.concat(got, ","))

	--==========================================================================
	-- 6. SWINGS: A PROTECTED TARGET vs A MISS
	--==========================================================================
	say("\n-- swings --")
	local bat = WeaponData.Get("rootwood_bat")
	local SZ = 5080
	local swinger = makePlayer("RefusalSwinger", 5111, Vector3.new(EDGE + 3, GY + 3, SZ))
	local target = makePlayer("RefusalTarget", 5112, Vector3.new(EDGE - 2, GY + 3, SZ))
	local batTool = tool(bat, swinger.Character)

	-- The swing's window, frame by frame on the spec's clock (2026-10-04).
	local function frames(seconds)
		local t0 = clock
		while clock - t0 < seconds do
			clock += 1 / 60
			if heartbeat then
				heartbeat()
			end
		end
	end

	local function swing()
		clock += bat.Cooldown + 0.05
		local before = #captured
		CombatService.RequestSwing(swinger, bat, batTool)
		frames(bat.Windup + WeaponData.Combat.HitWindowTrail + 0.05)
		return codesFor(swinger, before)
	end

	standAt(swinger, Vector3.new(EDGE + 3, GY + 3, SZ), WEST)
	standAt(target, Vector3.new(EDGE - 2, GY + 3, SZ))
	got = swing()
	check(#got == 1 and got[1] == "SAFE_ZONE_TARGET",
		"a swing that reaches a player standing in the field: \"Players are protected in the Safe Zone.\"",
		table.concat(got, ","))

	mark = #captured
	CombatService.RequestSwing(swinger, bat, batTool)
	frames(bat.Windup + WeaponData.Combat.HitWindowTrail + 0.05)
	got = codesFor(swinger, mark)
	check(#got == 0, "the same swing again inside its cooldown never starts, and says nothing",
		table.concat(got, ","))

	standAt(target, Vector3.new(EDGE - bat.Reach - 10, GY + 3, SZ))
	got = swing()
	check(#got == 0, "a miss -- nobody in reach -- says nothing, even at the red line",
		table.concat(got, ","))

	standAt(target, Vector3.new(EDGE - 2, GY + 3, SZ))
	standAt(swinger, Vector3.new(EDGE + 3, GY + 3, SZ), EAST)
	got = swing()
	check(#got == 0, "a protected player in reach but behind the swing was never swung at: nothing",
		table.concat(got, ","))

	standAt(swinger, Vector3.new(EDGE + 3, GY + 3, SZ), WEST)
	local wall = Instance.new("Part")
	wall.Name = "SpecWall"
	wall.Anchored = true
	wall.Size = Vector3.new(0.6, 12, 12)
	wall.Position = Vector3.new(EDGE + 0.5, GY + 5, SZ)
	wall.Parent = fixture
	got = swing()
	check(#got == 0, "a protected player behind a wall: the wall stopped the bat, so nothing",
		table.concat(got, ","))
	wall:Destroy()

	standAt(swinger, Vector3.new(EDGE - 2, GY + 3, SZ), EAST)
	standAt(target, Vector3.new(EDGE + 3, GY + 3, SZ))
	got = swing()
	check(#got == 1 and got[1] == "SAFE_ZONE_TARGET",
		"swinging from inside the field at a player in reach: the same line", table.concat(got, ","))

	standAt(target, Vector3.new(EDGE + bat.Reach + 20, GY + 3, SZ))
	got = swing()
	check(#got == 0, "a swing at the air from inside the field says nothing", table.concat(got, ","))

	pcall(CombatService.Init)
end

--==============================================================================
-- 7. PLANTING: OUT OF REACH vs A FULL PLOT
--==============================================================================
local function planting()
	say("\n-- planting --")
	local planter = { Name = "RefusalPlanter", UserId = 5121, Parent = fakePlayers }
	local leases = {}
	local profileReady = true
	local assignPlot = nil
	local savedPlants = 0
	local PlotStub = {
		OwnerOf = function(plot)
			return if plot ~= nil and plot == plantPlot then planter else nil
		end,
		PlotOf = function(player)
			return leases[player]
		end,
		OnAssigned = function(fn)
			assignPlot = fn
		end,
		OnReleased = function() end,
		OnResizing = function() end,
		OnResized = function() end,
	}
	local DataStub = {
		IsReady = function()
			return profileReady
		end,
		Get = function()
			return { Plants = {} }
		end,
		SetPlants = function()
			savedPlants += 1
		end,
		MarkSeen = function() end,
		RecordTutorial = function() end,
	}
	local CarryStub = {
		GiveHatched = function()
			return true
		end,
		SyncHeldNow = function() end,
	}

	local loadOk, loadErr = pcall(function()
		plantPlot = Instance.new("Model")
		plantPlot.Name = "ActionRefusalSpecPlot"
		plantPlot.Archivable = false
		plantPlot:SetAttribute("PreviewOnly", true)
		plantPlot:SetAttribute(GameConfig.Attributes.PlotId, 94)
		plantPlot.Parent = fixture
		local depth = GameConfig.plotDepthFor(GameConfig.plotRowsForTier(1))
		local centreR = GameConfig.Map.PlotRingInner + depth * 0.5
		plantPlot:SetAttribute("PlotCF",
			CFrame.lookAt(Vector3.new(0, 860, centreR), Vector3.new(0, 860, 0)))
		plantPlot:SetAttribute("Depth", depth)
		MapService.ResizePlot(plantPlot, 1)
		-- ONE plant fills it, so "full" is one planting away.
		plantPlot:SetAttribute("Capacity", 1)

		PlantService = loadWith(Server.PlantService, {
			PlotService = PlotStub,
			PlayerDataService = DataStub,
			CarryService = CarryStub,
			PlantWander = PlantWander,
		}, nil)
		PlantService.Init()
		PlantService.Start()
	end)
	check(loadOk, "PlantService loads and starts against the stand-ins", loadErr)
	if not loadOk then
		return
	end

	local soil = plantPlot:FindFirstChild(GameConfig.Plot.PlanterName)
	check(soil ~= nil and soil:IsA("BasePart"), "(the fixture plot has its bed)")
	if not soil then
		return
	end
	local click = soil.Position + Vector3.new(0, soil.Size.Y * 0.5, 0)
	local near = click + Vector3.new(0, 3, 0)
	local far = click + Vector3.new(GameConfig.Plant.RangeStuds + 40, 3, 0)

	local body = makeBody("RefusalPlanterBody", CFrame.new(far))
	planter.Character = body
	leases[planter] = plantPlot

	-- Stamped the way CarryService stamps a banked pod: the species, and the
	-- weight class it travelled with.
	local function pod()
		local t = Instance.new("Tool")
		t.Name = "Nubkin"
		t.RequiresHandle = false
		t:SetAttribute("SpeciesId", "nubkin")
		t:SetAttribute(GameConfig.Attributes.CarryingKg, 1)
		t.Parent = body
		return t
	end

	local function plant(from)
		body:PivotTo(CFrame.new(from))
		local placed, code = PlantService.PlaceAt(planter, click)
		return placed, code, ActionRefusal.fromPlacement(code)
	end

	--==========================================================================
	-- A BED WHOSE GARDEN HAS NOT ARRIVED PLANTS NOTHING AND SAVES NOTHING
	-- (2026-09-26). The plot is leased but restore() has not put the saved
	-- garden back -- the state a slow profile load leaves a rejoining player
	-- in. Planting there used to save a one-plant garden over the real one.
	--==========================================================================
	local early = pod()
	local ep, ec, el = plant(near)
	check(not ep and ec == "NO_PROFILE" and el == nil and early.Parent == body and savedPlants == 0,
		"a plot whose saved garden is still loading refuses the pod, keeps it in your hands, and saves nothing",
		string.format("%s, %d save(s)", tostring(ec), savedPlants))
	early:Destroy()
	-- Handed over the way PlotService does it: restore puts the (empty) garden
	-- back, and that is what opens the bed.
	if assignPlot then
		assignPlot(planter, plantPlot)
	end
	local opened = os.clock() + 2
	while not PlantService.GardenRestored(plantPlot) and os.clock() < opened do
		task.wait()
	end
	check(PlantService.GardenRestored(plantPlot), "(the fixture's garden is restored, so its bed opens)")

	local held = pod()
	local placed, code, line = plant(far)
	check(not placed and code == "OUT_OF_RANGE" and line == "PLANT_OUT_OF_RANGE",
		"clicking your own bed from across the plot: \"Move closer to your plot.\"", tostring(code))
	check(held.Parent == body, "and the pod is still in your hands")

	placed, code = plant(near)
	check(placed == true and code == nil, "from beside it, the pod goes in", tostring(code))
	check(held.Parent == nil, "and is used up")

	held = pod()
	placed, code, line = plant(near)
	check(not placed and code == "BED_FULL" and line == "PLOT_FULL",
		"another into a plot that holds one: \"Your plot is full.\"", tostring(code))
	check(held.Parent == body, "and nothing was used up")

	placed, code, line = plant(far)
	check(not placed and code == "OUT_OF_RANGE" and line == "PLANT_OUT_OF_RANGE",
		"full AND out of reach says \"Move closer\": reach is checked first, as it always was",
		tostring(code))

	held:Destroy()
	placed, code, line = plant(near)
	check(not placed and code == "NO_TOOL" and line == nil, "empty hands: refused, and silent",
		tostring(code))

	local odd = pod()
	odd:SetAttribute("SpeciesId", "no_such_species")
	placed, code, line = plant(near)
	check(not placed and code == "UNKNOWN_SPECIES" and line == nil,
		"a Tool naming no species: refused, and silent", tostring(code))
	odd:Destroy()

	planter.Character = nil
	local p1, c1 = PlantService.PlaceAt(planter, click)
	check(not p1 and c1 == "NO_CHARACTER" and ActionRefusal.fromPlacement(c1) == nil,
		"no body (mid-respawn): refused, and silent", tostring(c1))
	planter.Character = body

	leases[planter] = nil
	local p2, c2 = PlantService.PlaceAt(planter, click)
	profileReady = false
	local p3, c3 = PlantService.PlaceAt(planter, click)
	profileReady = true
	leases[planter] = plantPlot
	check(not p2 and c2 == "NO_PLOT" and ActionRefusal.fromPlacement(c2) == nil,
		"no plot: refused, and silent", tostring(c2))
	check(not p3 and c3 == "NO_PROFILE" and ActionRefusal.fromPlacement(c3) == nil,
		"no profile yet: refused, and silent", tostring(c3))

	local src = sourceOf(Server:FindFirstChild("PlantService"))
	local handler = src and string.match(src,
		"if action == PLACE_ACTION then(.-)elseif action == PICKUP_ACTION then")
	local _, sends = string.gsub(handler or "", "ActionRefusal%.send%(", "")
	local guardAt = handler and string.find(handler, "typeof(payload) ~= \"Vector3\"", 1, true)
	local placeAt = handler and string.find(handler, "PlantService.PlaceAt(player, payload)", 1, true)
	local mapAt = handler and string.find(handler, "ActionRefusal.fromPlacement(code)", 1, true)
	check(guardAt ~= nil and placeAt ~= nil and mapAt ~= nil and guardAt < placeAt
			and placeAt < mapAt and sends == 1,
		"the click's handler: a malformed click never reaches PlaceAt, and only what "
			.. "fromPlacement maps is said, after PlaceAt has decided")

	pcall(PlantService.Init)
end

--==============================================================================
-- 8. THE BAG: A FULL HOTBAR IS NOT A FULL INVENTORY
--
-- The belt shows ten slots on a desktop and five on a phone; that is a picture
-- of the Backpack, not a limit on it. Nothing is refused for what is in the
-- bag, and there is no "Bag is full".
--
-- WHAT IS COUNTED IS THE SAVED RECORD (2026-09-29, the owner's decisions),
-- which holds Save.MaxHeld plants and pods: a hatch, a pickup, a pod taken and
-- a pod banked are refused when it has no room, and the line is PLANT STORAGE
-- FULL. HatchStorageSpec and StorageDoorsSpec have all of it; here, that the
-- BAG is still not counted and a rebuild is not either, while a pod given now
-- counts the record like everything else (2026-09-30).
--==============================================================================
local function theBag()
	say("\n-- the bag --")
	local CarryService = require(Server:WaitForChild("CarryService"))
	local PlayerDataService = require(Server:WaitForChild("PlayerDataService"))
	local real = {
		IsReady = PlayerDataService.IsReady,
		Get = PlayerDataService.Get,
		SetHeld = PlayerDataService.SetHeld,
	}
	PlayerDataService.IsReady = function()
		return false
	end
	PlayerDataService.Get = function()
		return nil
	end
	PlayerDataService.SetHeld = function()
		return true
	end

	local ok, err = pcall(function()
		local backpack = Instance.new("Backpack")
		backpack.Parent = fixture
		local attrs = {}
		local p = {
			Name = "RefusalHoarder",
			UserId = 5131,
			Parent = game:GetService("Players"),
			Character = nil,
		}
		function p.SetAttribute(_, k, v)
			attrs[k] = v
		end
		function p.GetAttribute(_, k)
			return attrs[k]
		end
		function p.FindFirstChildOfClass(_, className)
			if className == "Backpack" and backpack.Parent then
				return backpack
			end
			return nil
		end

		local nubkin = SeedData.Get("nubkin")
		local plants = 0
		for _ = 1, 12 do
			if CarryService.GiveHatched(p, nubkin, 1) then
				plants += 1
			end
		end
		check(plants == 12, "twelve plants in a row are all accepted -- past a full ten-slot strip",
			plants)

		-- A pod given is counted against the saved RECORD since 2026-09-30, and
		-- here there is no record to write on: none is handed over. (Its full
		-- story is StorageDoorsSpec's.)
		local pods = 0
		for _ = 1, 3 do
			if CarryService.GivePod(p, "nubkin", 1) then
				pods += 1
			end
		end
		check(pods == 0, "a pod given is counted against the saved record: with none to write on, none is given",
			pods)

		local tools = 0
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") then
				tools += 1
			end
		end
		check(tools == 12, "the bag holds every plant it was handed, and nothing that was refused", tools)

		-- A hatch and a pickup are counted (onRecord), and here there is no
		-- record to count: refused, with the reason, and nothing added to the bag.
		local hatched, why = CarryService.GiveHatched(p, nubkin, 1, nil, nil, true)
		local after = 0
		for _, t in ipairs(backpack:GetChildren()) do
			if t:IsA("Tool") then
				after += 1
			end
		end
		check(hatched == false and why == "NO_RECORD" and after == tools,
			"a hatch or a pickup is counted: with no record to write on it is refused, and makes no Tool",
			tostring(hatched) .. " / " .. tostring(why))
	end)
	PlayerDataService.IsReady = real.IsReady
	PlayerDataService.Get = real.Get
	PlayerDataService.SetHeld = real.SetHeld
	check(ok, "(the bag section ran)", err)

	local carrySrc = sourceOf(Server:FindFirstChild("CarryService"))
	local give = carrySrc and string.match(carrySrc, "function CarryService%.GiveHatched(.-)\nend\n")
	check(give ~= nil and string.find(give, "GetChildren", 1, true) == nil
			and string.find(give, "MaxHeld", 1, true) == nil,
		"GiveHatched never counts the BAG: nothing is refused for what is in it")
	local countAt = give and string.find(give, "CarryService.HeldRoom(player)", 1, true)
	local gateAt = give and string.find(give, "if onRecord == true then", 1, true)
	check(countAt ~= nil and gateAt ~= nil and gateAt < countAt and countAt - gateAt < 60,
		"it counts the saved RECORD, and only when asked to (onRecord): a rebuild is never refused")
end

--==============================================================================
-- 9. CARRYING A POD, AND 10. THE TOAST ITSELF -- source, because each needs a
-- running client or a real raided pod
--==============================================================================
local function carryingAndToast()
	say("\n-- carrying --")
	local carrySrc = sourceOf(Server:FindFirstChild("CarryService")) or ""
	local sendAt = string.find(carrySrc, "ActionRefusal.send(player, \"CARRYING_POD\")", 1, true)
	local refuseAt = string.find(carrySrc,
		"return refuseTake(player, pod, \"ALREADY_CARRYING\")", 1, true)
	local nightAt = string.find(carrySrc, "return refuseTake(player, pod, \"NIGHT\")", 1, true)
	check(sendAt ~= nil and refuseAt ~= nil and sendAt < refuseAt and refuseAt - sendAt < 120,
		"a second pod while carrying: the refusal that already happens says "
			.. "\"Bank your pod before doing that.\"")
	check(nightAt ~= nil and sendAt ~= nil and nightAt < sendAt,
		"after the night refusal, which stays first and silent")
	-- And one more since 2026-09-29: plant storage full, for a pod that may not
	-- be taken or banked, said from one place that holds it to its quiet time.
	local _, carrySends = string.gsub(carrySrc, "ActionRefusal%.send%(", "")
	local teller = string.match(carrySrc, "local function tellStorageFull(.-)\nend\n") or ""
	local _, tellerSends = string.gsub(teller, "ActionRefusal%.send%(player, code%)", "")
	local quietAt = string.find(teller, "< quiet then", 1, true)
	local saidAt = string.find(teller, "ActionRefusal.send(player, code)", 1, true)
	check(carrySends == 2 and tellerSends == 1 and quietAt ~= nil and saidAt ~= nil and quietAt < saidAt,
		"the only other line CarryService says is plant storage full, from one place, after its quiet time",
		carrySends)

	local scripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")
	local loadout = sourceOf(scripts and scripts:FindFirstChild("LoadoutUI")) or ""
	local _, raises = string.gsub(loadout, "raise%(\"CARRYING_POD\"%)", "")
	check(raises == 1,
		"the plant the carry rule keeps out of your hands raises the same line on the client, once",
		raises)

	say("\n-- the toast --")
	local toast = sourceOf(scripts and scripts:FindFirstChild("ActionToastUI"))
	check(toast ~= nil, "ActionToastUI is in the tree")
	check(toast ~= nil and string.find(toast, "Notice.setRenderer(show)", 1, true) ~= nil
			and string.find(toast, "action == ActionRefusal.Action", 1, true) ~= nil,
		"it hears the server's verb, and is the renderer every client raise reaches")
	check(toast ~= nil and string.find(toast, "local post = ActionRefusal.notice(code)", 1, true) ~= nil,
		"and shows only a code that has a notice")
	local _, named = string.gsub(toast or "", "SoundKit%.play%(\"", "")
	check(toast ~= nil and named == 0
			and string.find(toast, "local cue = Notice.soundFor(sounds, post, now)", 1, true) ~= nil,
		"its only sound is the one Notice.soundFor allows, for a notice that just went up", named)
	check(toast ~= nil and string.find(toast, "while true", 1, true) == nil
			and string.find(toast, "Heartbeat", 1, true) == nil
			and string.find(toast, "RenderStepped", 1, true) == nil,
		"no loop and no per-frame hook: a toast is an event")
	local _, sets = string.gsub(toast or "", "SetAttribute%(", "")
	local _, fires = string.gsub(toast or "", "FireServer%(", "")
	check(sets == 0 and fires == 0, "and it tells nobody anything back: nothing reads a toast")
end

local ok, err = pcall(function()
	combat()
	planting()
	theBag()
	carryingAndToast()
end)
if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end

ActionRefusal.capture(nil)
fixture:Destroy()

say(string.format("\nActionRefusalSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
