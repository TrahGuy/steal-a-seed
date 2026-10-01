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

-- The reward wheel's bought spins (2026-09-27). False stands for a profile that
-- cannot take them now (WheelService refuses past MaxBoughtHeld).
local grantWorks = true
local WheelService = {
	GrantBought = function(player, quantity)
		record("GrantBought", player, quantity)
		if grantWorks then
			profile.WheelBought = (profile.WheelBought or 0) + quantity
		end
		return grantWorks
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
		-- The Bonus Chest's training boost (2026-09-27), neutral here: this spec
		-- checks the store's payouts, not a boost.
		BonusChestService = {
			Multiplier = function()
				return 1
			end,
		},
	})
	-- Watch the faucet being used, without replacing what it does.
	local realPayReward = TreadmillService.PayReward
	TreadmillService.PayReward = function(player, amount, reason)
		record("PayReward", player, amount, reason)
		return realPayReward(player, amount, reason)
	end
	-- Paid spins are ON as shipped (2026-10-01). This copy sees them switched
	-- OFF, so every other section tests the store alone and section 5 can show
	-- what off means; section 5's second copy runs the shipped WheelData.
	local ShippedWheelData = require(Shared:WaitForChild("WheelData"))
	local wheelOff = setmetatable({
		Paid = { Enabled = false, PromptCooldown = ShippedWheelData.Paid.PromptCooldown },
		paidLive = function()
			return false
		end,
	}, { __index = ShippedWheelData })
	StoreService = loadWith(Server.StoreService, {
		PlayerDataService = PlayerDataService,
		CarryService = CarryService,
		TreadmillService = TreadmillService,
		PlantService = PlantService,
		WheelService = WheelService,
	}, { GameConfig = liveConfig, WheelData = wheelOff })
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

	--==========================================================================
	-- 5. THE REWARD WHEEL'S SPIN PRODUCTS (2026-09-29; ON SINCE 2026-10-01)
	--
	-- As shipped WheelData.Paid.Enabled is TRUE: the owner switched it on on
	-- 2026-10-01. The first copy of StoreService above sees it switched OFF, so
	-- no product is indexed and no receipt can grant a spin -- even one that
	-- names a real id. A second copy then runs the SHIPPED WheelData: each id
	-- pays its own quantity through WheelService.GrantBought, once per receipt,
	-- recoverably. WheelService here is a stand-in that records;
	-- SpinPurchaseSpec runs the two real services together, PolicyService and all.
	--==========================================================================
	say("\n-- the wheel's spin products --")
	local WheelData = require(Shared:WaitForChild("WheelData"))
	local ONE, TEN = WheelData.ProductByKey.spin1, WheelData.ProductByKey.spin10
	check(WheelData.Paid.Enabled == true and WheelData.paidLive() and ONE ~= nil and TEN ~= nil and ONE.spins == 1
			and TEN.spins == 10,
		"as shipped paid spins are switched ON (the owner's word, 2026-10-01), x1 granting 1 spin and x10 granting 10")
	check(string.find(snapshot, "OFF (WheelData.Paid.Enabled is false)", 1, true) ~= nil
			and string.find(snapshot, "spin1=" .. ONE.productId .. " x1", 1, true) ~= nil
			and string.find(snapshot, "spin10=" .. TEN.productId .. " x10", 1, true) ~= nil,
		"the switched-off copy's snapshot names them and says they are off", snapshot)
	local function grants()
		local n = 0
		for _, t in ipairs(trace) do
			if t.name == "GrantBought" then
				n += 1
			end
		end
		return n
	end
	table.clear(trace)
	local strayOne = receiptCallback({ PlayerId = buyer.UserId, ProductId = ONE.productId,
		PurchaseId = "spec-spins-off-1", CurrencySpent = ONE.robux })
	local strayTen = receiptCallback({ PlayerId = buyer.UserId, ProductId = TEN.productId,
		PurchaseId = "spec-spins-off-10", CurrencySpent = TEN.robux })
	local strayAgain = receiptCallback({ PlayerId = buyer.UserId, ProductId = ONE.productId,
		PurchaseId = "spec-spins-off-1", CurrencySpent = ONE.robux })
	check(strayOne == RETRY and strayTen == RETRY and strayAgain == RETRY and grants() == 0
			and indexOf("Save") == nil and (profile.WheelBought or 0) == 0
			and table.find(profile.Receipts, "spec-spins-off-1") == nil,
		"switched off, a receipt naming either REAL product grants nothing, is not acknowledged and is not "
			.. "remembered -- so Roblox returns the Robux",
		string.format("%s/%s/%s, %d grant(s)", tostring(strayOne), tostring(strayTen), tostring(strayAgain), grants()))

	local onOk, OnStore = pcall(loadWith, Server.StoreService, {
		PlayerDataService = PlayerDataService,
		CarryService = CarryService,
		TreadmillService = TreadmillService,
		PlantService = PlantService,
		WheelService = WheelService,
	}, { GameConfig = liveConfig })
	check(onOk, "a copy with the shipped WheelData (switched on) loads", if onOk then nil else OnStore)
	if onOk then
		OnStore.Init()
		OnStore.Start()
		local one = { product = ONE.productId, robux = ONE.robux }
		local ten = { product = TEN.productId, robux = TEN.robux }
		local base = profile.WheelBought or 0
		table.clear(trace)
		local first = buy(one, "spec-spins-1")
		local g, s = indexOf("GrantBought"), indexOf("Save")
		check(first == GRANTED and g ~= nil and s ~= nil and g < s and trace[g].args[2] == 1
			and profile.WheelBought == base + 1,
			"a +1 Spin receipt grants exactly 1 through WheelService.GrantBought, then saves", tostring(first))
		table.clear(trace)
		local big = buy(ten, "spec-spins-10")
		local g10 = indexOf("GrantBought")
		check(big == GRANTED and g10 ~= nil and trace[g10].args[2] == 10 and grants() == 1
			and profile.WheelBought == base + 11,
			"a +10 Spins receipt grants exactly 10, in one grant", tostring(big))
		-- The quantity is the ROW's, whatever the receipt claims to have spent.
		table.clear(trace)
		local cheap = receiptCallback({ PlayerId = buyer.UserId, ProductId = TEN.productId,
			PurchaseId = "spec-spins-10-cheap", CurrencySpent = 1 })
		local dear = receiptCallback({ PlayerId = buyer.UserId, ProductId = ONE.productId,
			PurchaseId = "spec-spins-1-dear", CurrencySpent = 99999 })
		local amounts = {}
		for _, t in ipairs(trace) do
			if t.name == "GrantBought" then
				table.insert(amounts, t.args[2])
			end
		end
		check(cheap == GRANTED and dear == GRANTED and #amounts == 2 and amounts[1] == 10 and amounts[2] == 1
			and profile.WheelBought == base + 22,
			"the product id alone decides the quantity: 10 for one id, 1 for the other, whatever was spent",
			table.concat(amounts, ","))
		table.clear(trace)
		local repeated = buy(ten, "spec-spins-10")
		local repeatedOne = buy(one, "spec-spins-1")
		check(repeated == GRANTED and repeatedOne == GRANTED and grants() == 0 and profile.WheelBought == base + 22,
			"the same receipts again are acknowledged and grant nothing more",
			tostring(repeated) .. "/" .. tostring(repeatedOne))
		table.clear(trace)
		grantWorks = false
		local refused = buy(ten, "spec-spins-2")
		local refusedAgain = buy(ten, "spec-spins-2")
		grantWorks = true
		local retried = buy(ten, "spec-spins-2")
		check(refused == RETRY and refusedAgain == RETRY and retried == GRANTED and grants() == 3
			and profile.WheelBought == base + 32 and table.find(profile.Receipts, "spec-spins-2") ~= nil,
			"spins that cannot be granted now (no room, a restricted player, PolicyService silent): not acknowledged "
				.. "and not remembered, so a later delivery can still pay",
			string.format("%s, %s then %s", tostring(refused), tostring(refusedAgain), tostring(retried)))
		table.clear(trace)
		saveWorks = false
		local unsaved = buy(ten, "spec-spins-3")
		local unsavedAgain = buy(ten, "spec-spins-3")
		saveWorks = true
		local saved = buy(ten, "spec-spins-3")
		check(unsaved == RETRY and unsavedAgain == RETRY and saved == GRANTED and grants() == 1
			and profile.WheelBought == base + 42,
			"granted but not saved: retried until it saves, and never granted twice",
			string.format("%s, %s then %s, %d grant(s)", tostring(unsaved), tostring(unsavedAgain), tostring(saved),
				grants()))
		-- REJOINING: the buyer left before the receipt landed. Nothing is granted
		-- to nobody; when they are back the same receipt pays, once.
		table.clear(trace)
		buyer.Parent = nil
		local away = buy(one, "spec-spins-rejoin")
		buyer.Parent = fakePlayers
		profileLoaded = false
		local loading = buy(one, "spec-spins-rejoin")
		profileLoaded = true
		local back = buy(one, "spec-spins-rejoin")
		local backAgain = buy(one, "spec-spins-rejoin")
		check(away == RETRY and loading == RETRY and back == GRANTED and backAgain == GRANTED and grants() == 1
			and profile.WheelBought == base + 43,
			"the buyer gone, then back with a save still loading: not processed; once loaded it pays, and only once",
			string.format("%s, %s, %s, %s", tostring(away), tostring(loading), tostring(back), tostring(backAgain)))
		local shot = OnStore.Snapshot()
		check(string.find(shot, "spin1=" .. ONE.productId .. " x1", 1, true) ~= nil
				and string.find(shot, "spin10=" .. TEN.productId .. " x10", 1, true) ~= nil
				and string.find(shot, "OFF", 1, true) == nil,
			"and its snapshot names both products, live", shot)
	end
end

say(string.format("\nStoreSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
