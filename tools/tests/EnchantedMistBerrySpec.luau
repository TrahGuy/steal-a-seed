--!nocheck
--==============================================================================
-- Steal a Seed :: EnchantedMistBerrySpec (2026-10-11, Enchanted Mist stage 2)
--
-- The shared Dewberries, in Edit: EnchantedMistBerryService loaded from its
-- source with a stand-in coordinator, players, profiles and clock, and the
-- client's EnchantedMistBerries with a stand-in Players and Workspace.
--
--   1. the numbers: the draft tuning, the racing line and the Pod Guide kept
--      clear, the supply against six players' demand (a NOTE, for the owner)
--   2. a berry: its model and prompt, its notice (nobody full or loading told),
--      one opportunity every IntervalSeconds (the owner's 3 s), at most 6, 60 s
--      each, no catch-up burst after
--      a stall, nothing in the last 10 s, a skipped opportunity never made up
--   3. a pick: every refusal (no hold, a short hold, dead, far, a pod in hand,
--      not loaded, full, expired, the Mist over, nothing credited, a throwing
--      save), the credit and the removal, the 5/5 words, a duplicate, two
--      players racing, a full player leaving the berry for another, a player
--      who left, a hold begun before expiry and finished after
--   4. the end: every berry removed, no pick after; a step after the Mist
--      stopped elsewhere; one start heard twice
--   5. where: the real map's spots (on a floor, off the plots, the props, the
--      hub, the shop row and the racing line; inside the zones; about 60/40),
--      spacing from berries and room around pods
--   6. the client: a full player's berry prompts out of reach, only theirs, put
--      out again after somebody else's write, given back under the cap
--   7. the saves and the wiring: the sanitiser, a rebirth never touching the
--      counts, the reset publishing them, the order, the switch still off
--==============================================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local BiomeData = require(Shared:WaitForChild("BiomeData"))
local Notice = require(Shared:WaitForChild("Notice"))
local EnchantedMistConfig = require(Shared:WaitForChild("EnchantedMistConfig"))
local EnchantedMistData = require(Shared:WaitForChild("EnchantedMistData"))

local SPAWN = EnchantedMistData.Spawn
local CAP = EnchantedMistData.CarryCap
local B = EnchantedMistConfig.Berries
local W = B.Words
local MAP = GameConfig.Map

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
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local Server = ServerScriptService:WaitForChild("SeedGameServer")
local POD_TAG = "EnchantedMistBerrySpecPod"

local stage = Instance.new("Folder")
stage.Name = "EnchantedMistBerrySpecStage"
stage.Parent = Workspace
local fakeWorkspace = nil

local ok, err = pcall(function()
	--==========================================================================
	-- THE SERVICE, FROM ITS SOURCE
	--==========================================================================
	local function thaw(value)
		if type(value) ~= "table" then
			return value
		end
		local copy = {}
		for k, x in pairs(value) do
			copy[k] = thaw(x)
		end
		return setmetatable(copy, getmetatable(value))
	end
	local config = thaw(GameConfig)
	config.Tags.SeedPod = POD_TAG
	local configScript = Shared:WaitForChild("GameConfig")
	local mist = { id = nil }
	function mist.EventId()
		return mist.id
	end
	function mist.OnStart()
		return function() end
	end
	function mist.OnEnd()
		return function() end
	end
	local moduleScript = Server:WaitForChild("EnchantedMistBerryService")
	local chunk = loadstring(moduleScript.Source, "=EnchantedMistBerryService")
	setfenv(chunk, setmetatable({ script = moduleScript, require = function(target)
		if target == configScript then
			return config
		elseif target.Name == "EnchantedMistService" then
			return mist
		elseif target.Name == "PlayerDataService" then
			return {}
		end
		return require(target)
	end }, { __index = getfenv(1) }))
	local M = chunk()

	local clock = 1000
	local sent = {}
	local A = { Name = "SpecA", UserId = 90000000001 }
	local Bp = { Name = "SpecB", UserId = 90000000002 }
	local C = { Name = "SpecFull", UserId = 90000000003 }
	local D = { Name = "SpecLoading", UserId = 90000000004 }
	local players = { A, Bp, C, D }
	local profiles = { [A] = { DewberriesCarried = 0 }, [Bp] = { DewberriesCarried = 0 },
		[C] = { DewberriesCarried = CAP } }
	local roots = {}
	local pods = {}
	local updateMode = "ok"
	local rng = Random.new(20261012)
	local spots = {}
	M.Hooks.now = function()
		return clock
	end
	M.Hooks.random = function()
		return rng:NextNumber()
	end
	M.Hooks.eventId = function()
		return mist.id
	end
	M.Hooks.players = function()
		return players
	end
	M.Hooks.send = function(player, action, payload)
		table.insert(sent, { player = player, action = action, payload = payload })
	end
	M.Hooks.profile = function(player)
		return profiles[player]
	end
	M.Hooks.update = function(player, change)
		if updateMode == "throw" then
			error("EnchantedMistBerrySpec: a save that throws")
		elseif updateMode == "refuse" then
			return false
		end
		local profile = profiles[player]
		if not profile then
			return false
		end
		return change(profile)
	end
	M.Hooks.root = function(player)
		return roots[player]
	end
	M.Hooks.carryingPod = function(player)
		return pods[player] == true
	end
	M.Hooks.parent = function()
		return stage
	end
	M.Hooks.spot = function()
		local at = table.remove(spots, 1)
		if at then
			return at, W.NearPlots
		end
		return nil, nil
	end
	M.Init()

	-- Spots high over the map, 20 studs apart.
	local serial = 0
	local function nextSpot()
		serial += 1
		return Vector3.new(serial * 20, 400, 900)
	end
	local function fill(n)
		for _ = 1, n do
			table.insert(spots, nextSpot())
		end
	end
	local function begin(id, at)
		mist.id = id
		clock = at
		M._begin({ eventId = id, startedAt = at, endsAt = at + EnchantedMistData.Schedule.ActiveSeconds }, at)
	end
	local function stepTo(t)
		for s = math.floor(clock) + 1, t do
			clock = s
			M._step(s)
		end
	end
	local function listed(id)
		for _, b in ipairs(M.List()) do
			if b.id == id then
				return b
			end
		end
		return nil
	end
	local function sentTo(player, key)
		local n, last = 0, nil
		for _, s in ipairs(sent) do
			if s.player == player and s.payload.key == key then
				n += 1
				last = s
			end
		end
		return n, last
	end

	--==========================================================================
	-- 1. THE NUMBERS
	--==========================================================================
	say("-- the numbers --")
	check(SPAWN.MaxActive == 6 and SPAWN.LifetimeSeconds == 60 and SPAWN.SafeShare == 0.6 and SPAWN.HoldSeconds == 0.75,
		"the brief's proposal: 6 at once, 60 s each, 60% near the plots, a 0.75 s hold")
	check(SPAWN.IntervalSeconds == 3, "the owner's spawn rate (2026-10-11): one chance every 3 s")
	check(SPAWN.HoldTolerance > 0 and SPAWN.HoldSeconds - SPAWN.HoldTolerance >= 0.5 and SPAWN.ReachSlack > 0
			and SPAWN.QuietEndSeconds < SPAWN.LifetimeSeconds,
		"the server's slack: a hold of at least 0.5 s, a little reach, a quiet end shorter than a berry's life")
	local guideFar = 0
	for _, s in pairs(GameConfig.PodGuide.Spots) do
		guideFar = math.max(guideFar, s.In + GameConfig.PodGuide.BoardSize.X / 2)
	end
	check(SPAWN.BiomeX[1] >= 24 and SPAWN.BiomeX[2] <= MAP.CorridorWidth / 2 - 10
			and SPAWN.BiomeNearMargin > guideFar,
		"biome berries off the racing line (|X| 24 up), 10 off the walls, past the Pod Guide stand and its board",
		string.format("X %d..%d, near margin %d vs %.1f", SPAWN.BiomeX[1], SPAWN.BiomeX[2], SPAWN.BiomeNearMargin,
			guideFar))
	local chances = math.floor((EnchantedMistData.Schedule.ActiveSeconds - SPAWN.QuietEndSeconds)
		/ SPAWN.IntervalSeconds) + 1
	say(string.format("  NOTE  supply: at most %d berries a Mist (one per %d s, none in the last %d s); six players "
		.. "earning a pod each need %d -- carried berries and progress persist across Mists", chances,
		SPAWN.IntervalSeconds, SPAWN.QuietEndSeconds, 6 * EnchantedMistData.BerriesPerPod))

	--==========================================================================
	-- 2. A BERRY
	--==========================================================================
	say("-- a berry --")
	fill(40)
	local first = spots[1]
	begin("spec-1", 1000)
	local list = M.List()
	check(#list == 1 and list[1].id == "spec-1-b1" and list[1].at == first and list[1].expiresAt == 1060,
		"the Mist's start offers the first berry at once: its own id, its spot, 60 s to live", #list)
	local model = M.Model("spec-1-b1")
	local prompt = model and model:FindFirstChild(B.PromptName, true)
	check(model ~= nil and model.Parent == stage and model:GetAttribute(B.BerryAttribute) == "spec-1-b1"
			and (model:GetPivot().Position - first).Magnitude < 0.01
			and model.ModelStreamingMode == Enum.ModelStreamingMode.Atomic,
		"its model stands at the spot, marked with its id, and streams in whole")
	local still = model ~= nil
	if model then
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") and (not part.Anchored or part.CanCollide or part.CanTouch or part.CanQuery) then
				still = false
			end
		end
	end
	check(still, "every part anchored; nothing to bump, touch or hit")
	check(prompt ~= nil and prompt:IsA("ProximityPrompt") and prompt.ActionText == "Collect Dewberry"
			and prompt.HoldDuration == SPAWN.HoldSeconds and prompt.MaxActivationDistance == SPAWN.Reach
			and prompt.KeyboardKeyCode == Enum.KeyCode.E and prompt.Style == Enum.ProximityPromptStyle.Custom
			and prompt:GetAttribute(B.BerryAttribute) == "spec-1-b1" and prompt.Parent.Name == "PickupAnchor",
		"hold E -- Collect Dewberry, 0.75 s, 10 studs, drawn by PromptUI, on the berry's pickup point")
	local nA, lastA = sentTo(A, B.NoticeKeys.Appeared)
	local nC = sentTo(C, B.NoticeKeys.Appeared)
	local nD = sentTo(D, B.NoticeKeys.Appeared)
	check(nA == 1 and sentTo(Bp, B.NoticeKeys.Appeared) == 1 and nC == 0 and nD == 0
			and lastA.action == Notice.ServerNotice and lastA.payload.title == "A Dewberry appeared!"
			and lastA.payload.detail == "Near the plots",
		"everybody who could take it is told, once, where; nobody full or still loading")
	local post = lastA and Notice.readServerNotice(lastA.payload)
	check(post ~= nil and post.key == "server:" .. B.NoticeKeys.Appeared,
		"one key for every berry: the next one says its place in the notice already up")
	local I = SPAWN.IntervalSeconds
	stepTo(1000 + I - 1)
	check(#M.List() == 1, "a second short of the next chance: still one")
	stepTo(1000 + I)
	check(#M.List() == 2, "at the next chance: the second")
	stepTo(1000 + 5 * I)
	check(#M.List() == SPAWN.MaxActive, "then one a chance, up to six", #M.List())
	stepTo(1059)
	check(#M.List() == SPAWN.MaxActive and listed("spec-1-b1") ~= nil, "never a seventh; the first still there at 59 s")
	local firstModel = M.Model("spec-1-b1")
	stepTo(1060)
	check(listed("spec-1-b1") == nil and firstModel.Parent == nil, "at 60 s the first goes, model and all")
	stepTo(1000 + math.ceil(SPAWN.LifetimeSeconds / I) * I)
	check(#M.List() == SPAWN.MaxActive and M.List()[1].id == "spec-1-b2",
		"and the first chance from then on replaces it", #M.List())
	M._stop("spec")
	begin("stall", 2000)
	clock = 2050
	M._step(2050)
	stepTo(2050 + I - 1)
	check(#M.List() == 2, "after a 50-second stall: ONE more berry, never a burst to make up", #M.List())
	stepTo(2050 + I)
	check(#M.List() == 3, "and the next one a whole interval after it", #M.List())
	-- A spawn at exactly `t`, on a fresh Mist that began at 5000 (ends 5300).
	local function spawnsAt(t)
		M._stop("spec")
		fill(2)
		begin("quiet", 5000)
		clock = t
		M._step(t)
		for _, b in ipairs(M.List()) do
			if b.bornAt == t then
				return true
			end
		end
		return false
	end
	local quietAt = 5300 - SPAWN.QuietEndSeconds
	check(spawnsAt(quietAt) and not spawnsAt(quietAt + 1) and not spawnsAt(5299),
		"ten seconds left: still a berry; nine: none -- nobody could reach it before the end")
	M._stop("spec")
	table.clear(spots)
	local told = #sent
	begin("skip", 6000)
	check(#M.List() == 0 and #sent == told, "an opportunity with no spot is skipped: no berry, no notice")
	fill(5)
	clock = 6000 + I - 1
	M._step(6000 + I - 1)
	check(#M.List() == 0, "and never made up: a spot found a second later waits for the next chance")
	clock = 6000 + I
	M._step(6000 + I)
	check(#M.List() == 1, "the next chance, an interval after the last, takes it", #M.List())

	--==========================================================================
	-- 3. A PICK
	--==========================================================================
	say("-- a pick --")
	M._stop("spec")
	table.clear(spots)
	fill(30)
	begin("pick", 7000)
	stepTo(7030)
	local ids = {}
	for _, b in ipairs(M.List()) do
		table.insert(ids, b.id)
	end
	local function berryAt(id)
		return listed(id).at
	end
	local function near(player, id, dx)
		roots[player] = berryAt(id) + Vector3.new(dx or 4, 3, 0)
	end
	local b1 = ids[1]
	near(A, b1)
	local okA, why = M._claim(A, b1, clock)
	check(not okA and why == "NO_HOLD", "no hold the server saw: refused", why)
	M._holdBegan(A, b1, clock)
	okA, why = M._claim(A, b1, clock + 0.4)
	check(not okA and why == "NO_HOLD", "a 0.4 s hold: refused", why)
	clock += 1
	roots[A] = nil
	okA, why = M._claim(A, b1, clock)
	check(not okA and why == "DEAD", "no living body: refused", why)
	near(A, b1, SPAWN.Reach + SPAWN.ReachSlack + 0.5)
	okA, why = M._claim(A, b1, clock)
	check(not okA and why == "FAR", "out of reach (past reach + slack): refused", why)
	near(A, b1)
	pods[A] = true
	okA, why = M._claim(A, b1, clock)
	check(not okA and why == "CARRYING", "a pod in hand: refused", why)
	pods[A] = nil
	local saved = profiles[A]
	profiles[A] = nil
	okA, why = M._claim(A, b1, clock)
	check(not okA and why == "NOT_LOADED", "no profile yet: refused", why)
	profiles[A] = saved
	mist.id = "some-other-mist"
	okA, why = M._claim(A, b1, clock)
	mist.id = "pick"
	check(not okA and why == "EVENT_OVER", "the Mist this berry belongs to is over: refused", why)
	updateMode = "refuse"
	okA, why = M._claim(A, b1, clock)
	updateMode = "ok"
	check(not okA and why == "NOT_CREDITED" and listed(b1) ~= nil and profiles[A].DewberriesCarried == 0,
		"nothing credited: refused, and the berry stays for anybody", why)
	check(#sent > 0 and select(1, sentTo(A, B.NoticeKeys.Picked)) == 0, "no refusal tells a count")
	near(A, b1, SPAWN.Reach + SPAWN.ReachSlack - 0.5)
	local m1 = M.Model(b1)
	okA, why = M._claim(A, b1, clock)
	local nP, lastP = sentTo(A, B.NoticeKeys.Picked)
	check(okA and why == "OK" and profiles[A].DewberriesCarried == 1 and listed(b1) == nil and m1.Parent == nil,
		"a held, reachable pick: one berry credited, the berry gone for everybody", why)
	check(nP == 1 and lastP.payload.title == "Dewberry picked! 1/5" and lastP.payload.detail == nil,
		"the picker hears the count", lastP and lastP.payload.title)
	okA, why = M._claim(A, b1, clock)
	check(not okA and why == "GONE" and profiles[A].DewberriesCarried == 1, "the same pick again: GONE, no second credit",
		why)

	-- Two players, one berry.
	local b2 = ids[2]
	near(A, b2)
	near(Bp, b2, -4)
	M._holdBegan(A, b2, clock)
	M._holdBegan(Bp, b2, clock)
	clock += 1
	local first1, w1 = M._claim(A, b2, clock)
	local second1, w2 = M._claim(Bp, b2, clock)
	check(first1 and not second1 and w2 == "GONE" and profiles[A].DewberriesCarried == 2
			and profiles[Bp].DewberriesCarried == 0,
		"two players finishing the same hold at once: one credit, the other told it is gone", w1 .. "/" .. w2)

	-- A full player leaves the berry for another.
	local b3 = ids[3]
	near(C, b3)
	near(Bp, b3, -4)
	M._holdBegan(C, b3, clock)
	M._holdBegan(Bp, b3, clock)
	clock += 1
	local fullOk, fullWhy = M._claim(C, b3, clock)
	check(not fullOk and fullWhy == "FULL" and listed(b3) ~= nil and profiles[C].DewberriesCarried == CAP,
		"5/5: refused WITHOUT using the berry", fullWhy)
	local otherOk = M._claim(Bp, b3, clock)
	check(otherOk and profiles[Bp].DewberriesCarried == 1, "and another player still takes it")

	-- The fifth berry's words.
	profiles[A].DewberriesCarried = CAP - 1
	local b4 = ids[4]
	near(A, b4)
	M._holdBegan(A, b4, clock)
	clock += 1
	M._claim(A, b4, clock)
	local _, lastFull = sentTo(A, B.NoticeKeys.Picked)
	check(profiles[A].DewberriesCarried == CAP and lastFull.payload.title == "Dewberries full! 5/5"
			and lastFull.payload.detail == "Bring them to the Mosskeeper",
		"the fifth: full, and where to take them", lastFull.payload.title)
	profiles[A].DewberriesCarried = 0

	-- A new hold measures again; a player who left takes their hold with them.
	local b5 = ids[5]
	near(A, b5)
	M._holdBegan(A, b5, clock)
	M._holdBegan(A, b5, clock + 0.7)
	okA, why = M._claim(A, b5, clock + 0.75)
	check(not okA and why == "NO_HOLD", "let go and held again: measured from the new hold", why)
	M._left(A)
	okA, why = M._claim(A, b5, clock + 2)
	check(not okA and why == "NO_HOLD" and listed(b5) ~= nil, "a player who left: their hold is gone", why)

	-- A save that throws: the berry is never offered again.
	local b6 = ids[6]
	near(A, b6)
	near(Bp, b6, -4)
	M._holdBegan(A, b6, clock)
	M._holdBegan(Bp, b6, clock)
	clock += 1
	updateMode = "throw"
	okA, why = M._claim(A, b6, clock)
	updateMode = "ok"
	local afterThrow = M._claim(Bp, b6, clock)
	check(not okA and why == "ERROR" and listed(b6) == nil and not afterThrow and profiles[Bp].DewberriesCarried == 1,
		"an uncertain credit: the berry removed, never handed to anybody else", why)

	-- A hold begun before expiry, finished after.
	M._stop("spec")
	table.clear(spots)
	fill(3)
	begin("expiry", 8000)
	local bx = M.List()[1]
	near(A, bx.id)
	clock = bx.expiresAt - 0.6
	M._holdBegan(A, bx.id, clock)
	okA, why = M._claim(A, bx.id, bx.expiresAt + 0.2)
	check(not okA and why == "EXPIRED" and profiles[A].DewberriesCarried == 0,
		"a hold begun before the berry's end and finished after: refused, nothing credited", why)
	-- And one begun before the MIST's end.
	clock = 8040
	stepTo(8041)
	local by = M.List()[#M.List()]
	near(A, by.id)
	M._holdBegan(A, by.id, clock)
	mist.id = nil
	okA, why = M._claim(A, by.id, clock + 0.8)
	check(not okA and why == "EVENT_OVER", "a hold finished after the Mist ended: refused", why)
	mist.id = "expiry"

	--==========================================================================
	-- 4. THE END
	--==========================================================================
	say("-- the end --")
	M._stop("spec")
	table.clear(spots)
	fill(10)
	begin("end", 9000)
	stepTo(9010)
	local models = {}
	for _, b in ipairs(M.List()) do
		table.insert(models, M.Model(b.id))
	end
	local lastId = M.List()[1].id
	local before = #M.List()
	begin("end", 9010)
	check(before > 0 and #M.List() == before, "the same start heard twice changes nothing", #M.List())
	M._stop("time")
	local gone = true
	for _, mdl in ipairs(models) do
		if mdl.Parent ~= nil then
			gone = false
		end
	end
	check(#M.List() == 0 and gone and #stage:GetChildren() == 0, "the Mist's end removes every berry, model and all",
		#stage:GetChildren())
	roots[A] = Vector3.new(0, 400, 900)
	check(select(2, M._claim(A, lastId, 9011)) == "GONE", "a pick after the end: GONE")
	fill(5)
	begin("elsewhere", 9100)
	stepTo(9110)
	mist.id = nil
	M._step(9111)
	check(#M.List() == 0, "the coordinator says no Mist: the next step clears everything")

	--==========================================================================
	-- 5. WHERE
	--==========================================================================
	say("-- where --")
	local MiniEventService = require(Server:WaitForChild("MiniEventService"))
	M._stop("spec")
	M.Hooks.spot = nil
	table.clear(spots)
	local map = Workspace:FindFirstChild("SeedMap")
	if not map then
		say("  NOTE  no SeedMap in this place: the map's spots were not walked")
	elseif not GameConfig.isDay() then
		say("  NOTE  the place says Night: biome spots were not walked")
	else
		local safe, biome, none = 0, 0, 0
		local bad = {}
		local hub = MAP.EventHub
		local row = MAP.ShopRow
		for i = 1, 80 do
			local at, where = M._pickSpot()
			if not at then
				none += 1
			else
				local why = nil
				if MiniEventService.InPlot(at) then
					why = "plot"
				elseif not MiniEventService.ClearOfKept(at) then
					why = "kept"
				elseif MiniEventService.PropAt(at) then
					why = "prop"
				elseif where == W.NearPlots and math.abs(at.Y - MAP.GroundY) > 1.5
					or at.Y < MAP.GroundY - 10 or at.Y > MAP.GroundY + 30 then
					why = string.format("floor %.1f", at.Y)
				elseif hub and flat(at - hub.Centre).Magnitude < hub.Radius then
					why = "hub"
				elseif row and at.X >= row.From.X - 3 and at.X <= row.To.X + 3 and at.Z >= row.From.Y - 3
					and at.Z <= row.To.Y + 3 then
					why = "shop row"
				end
				if where == W.NearPlots then
					safe += 1
					local r = flat(at).Magnitude
					local front = at.X >= -62 and at.X <= 62 and at.Z >= -160 and at.Z <= -54
					if not (front or (r >= 56 and r <= 98)) then
						why = why or "outside Field/Front"
					end
				else
					biome += 1
					local inside = false
					for _, b in ipairs(BiomeData.Biomes) do
						local nearZ, farZ = BiomeData.SegmentBounds(b)
						if at.Z <= nearZ - SPAWN.BiomeNearMargin + 0.01 and at.Z >= farZ + SPAWN.BiomeFarMargin - 0.01
							and where == string.format(W.InBiome, b.DisplayName or b.Id) then
							inside = true
						end
					end
					if math.abs(at.X) < SPAWN.BiomeX[1] - 0.01 or math.abs(at.X) > SPAWN.BiomeX[2] + 0.01 then
						why = why or string.format("|X| %.1f", math.abs(at.X))
					elseif not inside then
						why = why or "not inside its named biome"
					end
				end
				if why then
					table.insert(bad, string.format("#%d %s (%.0f, %.0f) %s", i, tostring(why), at.X, at.Z,
						tostring(where)))
				end
			end
		end
		check(#bad == 0, "every spot on a floor, off the plots, the props, the hub, the shop row and the racing line, "
			.. "inside its zone and named for it", table.concat(bad, "; "))
		check(none <= 8 and safe >= 36 and safe <= 60 and biome >= 20,
			"80 chances: nearly all find a spot, about 60% near the plots",
			string.format("%d near the plots, %d in biomes, %d none", safe, biome, none))
	end
	-- Spacing and pods.
	table.insert(spots, Vector3.new(0, 400, 900))
	M.Hooks.spot = function()
		local at = table.remove(spots, 1)
		if at then
			return at, W.NearPlots
		end
		return nil, nil
	end
	begin("room", 11000)
	local S = Vector3.new(0, 400, 900)
	check(not M._roomAt(S + Vector3.new(SPAWN.Spacing - 1, 0, 0)) and M._roomAt(S + Vector3.new(SPAWN.Spacing + 1, 0, 0)),
		"14 studs between berries")
	local pod = Instance.new("Part")
	pod.Anchored = true
	pod.CanCollide = false
	pod.Transparency = 1
	pod.Position = Vector3.new(500, 400, 900)
	pod.Parent = stage
	CollectionService:AddTag(pod, POD_TAG)
	local P = pod.Position
	check(not M._roomAt(P + Vector3.new(SPAWN.PodClear - 1, 0, 0)) and M._roomAt(P + Vector3.new(SPAWN.PodClear + 1, 0, 0)),
		"10 studs from any pod: no two prompts share ground")
	M._stop("spec")

	--==========================================================================
	-- 6. THE CLIENT
	--==========================================================================
	say("-- the client --")
	local clientScript = StarterPlayer:WaitForChild("StarterPlayerScripts"):WaitForChild("EnchantedMistBerries")
	check(clientScript:IsA("LocalScript"), "EnchantedMistBerries is a LocalScript in StarterPlayerScripts")
	local me = Instance.new("Configuration")
	me.Name = "SpecClientPlayer"
	fakeWorkspace = Instance.new("Folder")
	fakeWorkspace.Name = "EnchantedMistBerrySpecWorkspace"
	local fakeGame = {}
	function fakeGame:GetService(name)
		if name == "Players" then
			return { LocalPlayer = me }
		elseif name == "Workspace" then
			return fakeWorkspace
		end
		return game:GetService(name)
	end
	local function runClient()
		local c = loadstring(clientScript.Source, "=EnchantedMistBerries")
		setfenv(c, setmetatable({ game = fakeGame, script = clientScript }, { __index = getfenv(1) }))
		c()
	end
	local function berryPrompt(parent, id)
		local mdl = Instance.new("Model")
		local part = Instance.new("Part")
		part.Anchored = true
		part.Parent = mdl
		local p = Instance.new("ProximityPrompt")
		p.Name = B.PromptName
		p.MaxActivationDistance = SPAWN.Reach
		if id then
			p:SetAttribute(B.BerryAttribute, id)
		end
		p.Parent = part
		mdl.Parent = parent
		return p
	end
	runClient()
	local folder = Instance.new("Folder")
	folder.Name = B.FolderName
	folder.Parent = fakeWorkspace
	task.wait()
	local p1 = berryPrompt(folder, "c-1")
	local p2 = berryPrompt(folder, "c-2")
	local plain = berryPrompt(folder, nil)
	local outside = berryPrompt(fakeWorkspace, "c-x")
	task.wait()
	check(p1.MaxActivationDistance == SPAWN.Reach and p2.MaxActivationDistance == SPAWN.Reach,
		"under the cap: every berry in reach")
	me:SetAttribute(EnchantedMistConfig.PlayerAttributes.Carried, CAP)
	task.wait()
	check(p1.MaxActivationDistance == 0 and p2.MaxActivationDistance == 0 and plain.MaxActivationDistance == SPAWN.Reach
			and outside.MaxActivationDistance == SPAWN.Reach,
		"at 5/5: every berry out of reach on this client -- and only berries in the server's folder")
	p1.MaxActivationDistance = SPAWN.Reach
	task.wait()
	task.wait()
	check(p1.MaxActivationDistance == 0, "a reach somebody else gives back while full (a hold lock's end) is put out again")
	local p3 = berryPrompt(folder, "c-3")
	task.wait()
	check(p3.MaxActivationDistance == 0, "a berry arriving while full: out of reach at once")
	me:SetAttribute(EnchantedMistConfig.PlayerAttributes.Carried, 3)
	task.wait()
	check(p1.MaxActivationDistance == SPAWN.Reach and p2.MaxActivationDistance == SPAWN.Reach
			and p3.MaxActivationDistance == SPAWN.Reach,
		"a delivery under the cap: every berry back in reach")
	p2.Parent.Parent:Destroy()
	task.wait()
	me:SetAttribute(EnchantedMistConfig.PlayerAttributes.Carried, CAP)
	task.wait()
	check(p1.MaxActivationDistance == 0 and p3.MaxActivationDistance == 0, "a berry taken away is forgotten, cleanly")
	-- A client that joins with the folder already there, full.
	local again = Instance.new("Folder")
	again.Name = "EnchantedMistBerrySpecWorkspace2"
	local old = fakeWorkspace
	fakeWorkspace = again
	local folder2 = Instance.new("Folder")
	folder2.Name = B.FolderName
	folder2.Parent = again
	local q1 = berryPrompt(folder2, "j-1")
	runClient()
	check(q1.MaxActivationDistance == 0, "a late join, already full: the berries already there are out of reach")
	again:Destroy()
	fakeWorkspace = old

	--==========================================================================
	-- 7. THE SAVES AND THE WIRING
	--==========================================================================
	say("-- the saves and the wiring --")
	local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))
	local d = ProfileSchema.Default()
	check(d.DewberriesCarried == 0 and d.DewberryProgress == 0, "a new profile: 0 carried, 0 toward a pod")
	local s1 = ProfileSchema.Sanitise({ DewberriesCarried = 9, DewberryProgress = 12.7 })
	local s2 = ProfileSchema.Sanitise({ DewberriesCarried = -3, DewberryProgress = "x" })
	local s3 = ProfileSchema.Sanitise({ DewberriesCarried = 0 / 0, DewberryProgress = 3.6 })
	local s4 = ProfileSchema.Sanitise({})
	check(s1.DewberriesCarried == CAP and s1.DewberryProgress == EnchantedMistData.BerriesPerPod - 1
			and s2.DewberriesCarried == 0 and s2.DewberryProgress == 0 and s3.DewberriesCarried == 0
			and s3.DewberryProgress == 3 and s4.DewberriesCarried == 0 and s4.DewberryProgress == 0,
		"a save is cleaned: whole, 0..5 carried, 0..9 toward a pod; old saves 0, 0")
	local function strip(src)
		return (string.gsub(src, "%-%-[^\n]*", ""))
	end
	local rebirth = strip(Server:WaitForChild("RebirthService").Source)
	check(not string.find(rebirth, "Dewberr", 1, true), "a rebirth never touches the berries")
	local pds = strip(Server:WaitForChild("PlayerDataService").Source)
	local resetAt = string.find(pds, "function PlayerDataService.ResetProgress", 1, true)
	local nextFn = resetAt and string.find(pds, "\nfunction ", resetAt + 10, true)
	local resetBody = resetAt and string.sub(pds, resetAt, nextFn or #pds) or ""
	check(string.find(resetBody, "PublishDewberries(player)", 1, true) ~= nil
			and string.find(pds, "function PlayerDataService.UpdateDewberries", 1, true) ~= nil,
		"an admin progress reset clears them and says so; one writer for a pick or a delivery")
	local src = strip(moduleScript.Source)
	check(string.find(src, "prompt.Triggered:Connect(function(player)\n\t\tEnchantedMistBerryService._claim(player, "
			.. "berry.id, Hooks.now())", 1, true) ~= nil,
		"a trigger carries only who pressed: the berry, the time and the reach are the server's")
	local mistSrc = strip(Server:WaitForChild("EnchantedMistService").Source)
	check(M.Priority == 76 and string.find(mistSrc, "EnchantedMistService.Priority = 75", 1, true) ~= nil
			and string.find(mistSrc, "Berries = true", 1, true) ~= nil,
		"started after the coordinator it listens to; the berries counted as built")
	check(EnchantedMistConfig.Enabled == false, "the event itself still off")
end)

if not ok then
	fail += 1
	say("  FAIL  the spec threw  <- " .. tostring(err))
end
stage:Destroy()
if fakeWorkspace then
	fakeWorkspace:Destroy()
end
say(string.format("\nEnchantedMistBerrySpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
