--!nocheck
--==============================================================================
-- Steal a Seed :: StoreSpec
--
-- The Robux receipt handler: what each product gives, that a Speed pack speeds
-- the player up the moment it lands, and the ledger that stops a double grant.
-- Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("StoreSpec"))
--
-- The REAL StoreService and the REAL TreadmillService, loaded from their Source
-- with the services around them stood in: MarketplaceService (so the receipt
-- callback can be caught and called), Players, PlayerDataService, CarryService,
-- PlantService and PlotService. The stand-ins only RECORD what they are asked to
-- do, so the order of those calls is the evidence.
--
-- StoreService sees the manifest through a copy whose Instant Hatch product has
-- a made-up id, so the spec never depends on the live id (3713212811) staying
-- what it is, and still covers the rule that a product id of 0 is never indexed.
-- InstantHatchSpec covers what PlantService does with the receipt.
--
-- Not here: a real purchase prompt, which only a client can open. Studio test
-- purchases are the Play-side check.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")

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
			if detail then "  <- " .. tostring(detail) else ""))
	end
end

local GRANTED = Enum.ProductPurchaseDecision.PurchaseGranted
local RETRY = Enum.ProductPurchaseDecision.NotProcessedYet

--==============================================================================
-- THE STAND-INS
--==============================================================================
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = { ... } })
end

local fakePlayers = {}
local buyer = { Name = "SpecBuyer", UserId = 4242, Parent = fakePlayers }
function fakePlayers:GetPlayerByUserId(id)
	return if id == buyer.UserId and buyer.Parent == fakePlayers then buyer else nil
end

local profile = { Receipts = {}, Speed = 0, Cash = 0 }
local profileLoaded = true
local saveWorks = true

local PlayerDataService = {
	Get = function(player)
		return if player == buyer and profileLoaded then profile else nil
	end,
	Save = function(player)
		record("Save", player)
		return saveWorks
	end,
	AddCash = function(player, amount)
		record("AddCash", player, amount)
		profile.Cash += amount
		return profile.Cash
	end,
	AddSpeed = function(player, amount)
		record("AddSpeed", player, amount)
		profile.Speed += amount
		return profile.Speed
	end,
}

local CarryService = {
	GivePod = function(player, species, tier)
		record("GivePod", player, species, tier)
		return true
	end,
	RefreshWalkSpeed = function(player)
		record("RefreshWalkSpeed", player)
	end,
}

local PlotService = {}

local hatchWorks = true
local PlantService = {
	InstantHatch = function(player)
		record("InstantHatch", player)
		return hatchWorks
	end,
}

-- The manifest as StoreService sees it: the real one, except that the Instant
-- Hatch product carries a spec id instead of the live one.
local LIVE_HATCH_ID = 990001
local realHatch = nil
for _, item in ipairs(GameConfig.Store.InWorld or {}) do
	if item.kind == "hatch" then
		realHatch = item
	end
end
local liveHatch = if realHatch then table.clone(realHatch) else nil
if liveHatch then
	liveHatch.product = LIVE_HATCH_ID
end
local liveConfig = setmetatable({
	Store = setmetatable({ InWorld = { liveHatch } }, { __index = GameConfig.Store }),
}, { __index = GameConfig })

local receiptCallback = nil
local fakeMarket = setmetatable({}, {
	__newindex = function(t, key, value)
		if key == "ProcessReceipt" then
			receiptCallback = value
		else
			rawset(t, key, value)
		end
	end,
})

local fakeGame = {}
function fakeGame:GetService(name)
	if name == "MarketplaceService" then
		return fakeMarket
	elseif name == "Players" then
		return fakePlayers
	end
	return game:GetService(name)
end

-- Loads a real server module with its siblings replaced by stand-ins. Anything
-- it requires from Shared is the real thing, through the runner's fresh require,
-- unless `overrides` names that module.
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

--==============================================================================
-- 1. LOADING THE REAL THING
--==============================================================================
say("\n-- load --")
local TreadmillService, StoreService
local ok, err = pcall(function()
	TreadmillService = loadWith(Server.TreadmillService, {
		PlotService = PlotService,
		PlayerDataService = PlayerDataService,
		CarryService = CarryService,
	})
	-- Watch the faucet being used, without replacing what it does.
	local realPayReward = TreadmillService.PayReward
	TreadmillService.PayReward = function(player, amount, reason)
		record("PayReward", player, amount, reason)
		return realPayReward(player, amount, reason)
	end
	StoreService = loadWith(Server.StoreService, {
		PlayerDataService = PlayerDataService,
		CarryService = CarryService,
		TreadmillService = TreadmillService,
		PlantService = PlantService,
	}, { GameConfig = liveConfig })
	StoreService.Init()
	StoreService.Start()
end)
check(ok, "StoreService and TreadmillService load and start against the stand-ins", err)
check(type(receiptCallback) == "function", "Start takes MarketplaceService.ProcessReceipt")

local function items(kind)
	local list = {}
	for _, section in ipairs(GameConfig.Store.Sections) do
		for _, item in ipairs(GameConfig.Store.Items[section.id] or {}) do
			if item.kind == kind and (tonumber(item.product) or 0) > 0 then
				table.insert(list, item)
			end
		end
	end
	return list
end

local nextPurchase = 0
local function buy(item, purchaseId)
	nextPurchase += 1
	return receiptCallback({
		PlayerId = buyer.UserId,
		ProductId = item.product,
		PurchaseId = purchaseId or ("spec-" .. nextPurchase),
		CurrencySpent = item.robux,
	})
end

local function indexOf(name, from)
	for i = from or 1, #trace do
		if trace[i].name == name then
			return i
		end
	end
	return nil
end

--==============================================================================
-- 2. A SPEED PACK SPEEDS THE PLAYER UP NOW
--
-- The reported bug: the score went up and WalkSpeed did not, until a mill or a
-- pod made CarryService recompute. The fix routes the grant through the Speed
-- faucet, which asks CarryService straight away.
--==============================================================================
if ok and receiptCallback then
	say("\n-- speed --")
	local speedItems = items("speed")
	check(#speedItems > 0, "the store sells Speed packs", #speedItems)
	local allRefresh, detail = true, ""
	for _, item in ipairs(speedItems) do
		table.clear(trace)
		local before = profile.Speed
		local decision = buy(item)
		local pay = indexOf("PayReward")
		local add = indexOf("AddSpeed")
		local refresh = indexOf("RefreshWalkSpeed")
		local save = indexOf("Save")
		local good = decision == GRANTED
			and pay ~= nil and add ~= nil and refresh ~= nil and save ~= nil
			and pay < add and add < refresh and refresh < save
			and trace[add].args[2] == item.amount
			and trace[refresh].args[1] == buyer
			and profile.Speed == before + item.amount
		if not good then
			allRefresh = false
			detail ..= string.format(" %s: %s pay=%s add=%s refresh=%s save=%s",
				item.key, tostring(decision), tostring(pay), tostring(add),
				tostring(refresh), tostring(save))
		end
	end
	check(allRefresh, string.format(
		"every Speed pack (%d) is paid through the Speed faucet and WalkSpeed is recomputed before the receipt is saved",
		#speedItems), detail)

	--==========================================================================
	-- 3. CASH, AND THE LEDGER
	--==========================================================================
	say("\n-- ledger --")
	local cashItems = items("cash")
	table.clear(trace)
	local cashBefore = profile.Cash
	local cashDecision = buy(cashItems[1])
	check(cashDecision == GRANTED and profile.Cash == cashBefore + cashItems[1].amount
		and indexOf("RefreshWalkSpeed") == nil,
		"a Cash pack pays its amount and leaves WalkSpeed alone",
		string.format("%s, cash %s", tostring(cashDecision), tostring(profile.Cash)))

	table.clear(trace)
	local speedBefore = profile.Speed
	local first = buy(speedItems[1], "spec-repeat")
	local again = buy(speedItems[1], "spec-repeat")
	local adds = 0
	for _, t in ipairs(trace) do
		if t.name == "AddSpeed" then adds += 1 end
	end
	check(first == GRANTED and again == GRANTED and adds == 1
		and profile.Speed == speedBefore + speedItems[1].amount,
		"a receipt delivered twice is acknowledged twice and granted once",
		string.format("%s/%s, %d grant(s)", tostring(first), tostring(again), adds))

	table.clear(trace)
	profileLoaded = false
	local early = buy(speedItems[1])
	profileLoaded = true
	check(early == RETRY and indexOf("AddSpeed") == nil,
		"no profile yet: not processed, nothing granted", tostring(early))

	table.clear(trace)
	buyer.Parent = nil
	local gone = buy(speedItems[1])
	buyer.Parent = fakePlayers
	check(gone == RETRY and indexOf("AddSpeed") == nil,
		"the buyer has left: not processed, nothing granted", tostring(gone))

	table.clear(trace)
	local unknown = receiptCallback({ PlayerId = buyer.UserId, ProductId = 1,
		PurchaseId = "spec-unknown", CurrencySpent = 1 })
	check(unknown == RETRY and indexOf("AddSpeed") == nil and indexOf("AddCash") == nil,
		"a product this build does not know: not processed, nothing granted", tostring(unknown))

	table.clear(trace)
	saveWorks = false
	local unsaved = buy(speedItems[1], "spec-unsaved")
	saveWorks = true
	check(unsaved == RETRY, "granted but not saved: not acknowledged, so Roblox retries",
		tostring(unsaved))

	--==========================================================================
	-- THE RETRY OF AN UNSAVED GRANT
	--
	-- `remember` put the id in the in-memory ledger before the save failed, so
	-- the re-delivered receipt finds it there. That alone used to answer
	-- GRANTED (2026-09-19 audit): a purchase acknowledged that was never on
	-- disk. The retry is acknowledged only once a save succeeds, and the grant
	-- itself is never repeated.
	--==========================================================================
	table.clear(trace)
	saveWorks = false
	local stillUnsaved = buy(speedItems[1], "spec-unsaved")
	saveWorks = true
	local savedNow = buy(speedItems[1], "spec-unsaved")
	local regrants = 0
	for _, t in ipairs(trace) do
		if t.name == "AddSpeed" then regrants += 1 end
	end
	check(stillUnsaved == RETRY and savedNow == GRANTED and regrants == 0
		and indexOf("Save") ~= nil,
		"a retry of an unsaved grant is not acknowledged until the save succeeds, and grants nothing again",
		string.format("%s then %s, %d regrant(s)", tostring(stillUnsaved), tostring(savedNow), regrants))

	--==========================================================================
	-- 4. INSTANT HATCH
	--
	-- Sold from a prompt on the pod rather than from a shelf, and granted by the
	-- same receipt path: PlantService opens the pod, then the ledger and the save.
	--==========================================================================
	say("\n-- instant hatch --")
	check(realHatch ~= nil and realHatch.robux == 99,
		"the manifest sells Instant Hatch in Store.InWorld at 99 Robux",
		realHatch and realHatch.robux)
	local onShelf = false
	for _, section in ipairs(GameConfig.Store.Sections) do
		for _, item in ipairs(GameConfig.Store.Items[section.id] or {}) do
			if item.kind == "hatch" then
				onShelf = true
			end
		end
	end
	check(not onShelf, "no shop shelf carries it, so ShopUI never draws a tile for it")

	table.clear(trace)
	local hatchDecision = buy(liveHatch, "spec-hatch")
	local asked = indexOf("InstantHatch")
	local saved = indexOf("Save")
	check(hatchDecision == GRANTED and asked ~= nil and saved ~= nil and asked < saved
		and trace[asked].args[1] == buyer and indexOf("GivePod") == nil,
		"an Instant Hatch receipt asks PlantService to hatch for the buyer, then saves",
		string.format("%s ask=%s save=%s", tostring(hatchDecision), tostring(asked), tostring(saved)))

	table.clear(trace)
	hatchWorks = false
	local nothing = buy(liveHatch, "spec-hatch-empty")
	hatchWorks = true
	local retried = buy(liveHatch, "spec-hatch-empty")
	local asks = 0
	for _, t in ipairs(trace) do
		if t.name == "InstantHatch" then asks += 1 end
	end
	check(nothing == RETRY and retried == GRANTED and asks == 2,
		"nothing could hatch: not acknowledged and not remembered, so the retry still pays out",
		string.format("%s then %s, %d ask(s)", tostring(nothing), tostring(retried), asks))

	local snapshot = StoreService.Snapshot()
	check(string.find(snapshot, "instanthatch=" .. LIVE_HATCH_ID, 1, true) ~= nil,
		"the debug snapshot lists it with the world products", snapshot)
end

say(string.format("\nStoreSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
