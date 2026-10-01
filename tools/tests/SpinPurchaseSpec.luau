--!nocheck
--==============================================================================
-- Steal a Seed :: SpinPurchaseSpec
--
-- BUYING WHEEL SPINS, END TO END (2026-09-29): the REAL StoreService and the
-- REAL WheelService running together, from the request for a purchase prompt to
-- a bought spin being spent. Edit mode:
--
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("SpinPurchaseSpec"))
--
-- NOTHING REAL IS BOUGHT, SAVED OR SENT. Around the two services stand:
--
--   MarketplaceService   catches the receipt callback, and records every
--                        purchase prompt instead of opening one
--   PolicyService        answers what the spec tells it to, or throws
--   PlayerDataService    profiles in memory, and a "disk" that a Save copies to:
--                        a crash puts the disk's copy back, which is what a
--                        rejoin after a lost server reads
--   the faucets          cash, Speed, pods and boosts, recording what was paid
--
-- What it proves:
--
--   1. switched off  a copy (as shipped they are ON since 2026-10-01): no
--                    prompt, and no receipt grants
--  1b. as shipped    ON: x5 prompted and paid for an eligible player, nothing for
--                    a restricted one, an old receipt still paid once
--   2. the purchase  the key picks the product, the server opens the prompt,
--                    the prompt grants nothing, the receipt grants 1 or 10
--   3. the ledger    a receipt delivered twice, an interrupted grant, a failed
--                    save, a crash before and after the save, a rejoin
--   4. who may       a restricted player, a PolicyService that will not answer,
--                    a receipt with no prompt behind it (bought outside the
--                    game), a balance with no room, a profile that is not saving
--   5. spending      earned first, bought only by name, never against the five
--   6. the free path untouched by any of it
--
-- Not here: a real purchase prompt and Roblox's own receipt delivery, which
-- only a live server has; the panel (WheelSpec reads its source; Play shows it).
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))

local A = WheelData.Attributes
local ONE, TEN = WheelData.ProductByKey.spin1, WheelData.ProductByKey.spin10
local GRANTED = Enum.ProductPurchaseDecision.PurchaseGranted
local RETRY = Enum.ProductPurchaseDecision.NotProcessedYet

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
		say(string.format("  FAIL  %s%s", label, if detail ~= nil then "  <- " .. tostring(detail) else ""))
	end
end

--==============================================================================
-- THE STAND-INS
--==============================================================================
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = { ... } })
end
local function count(name)
	local n = 0
	for _, t in ipairs(trace) do
		if t.name == name then
			n += 1
		end
	end
	return n
end
local function indexOf(name)
	for i, t in ipairs(trace) do
		if t.name == name then
			return i
		end
	end
	return nil
end

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end
	return copy
end

-- The players in the server, by UserId.
local inServer = {}
local fakePlayers = {}
local noSignal = {
	Connect = function()
		return { Disconnect = function() end }
	end,
}
fakePlayers.PlayerAdded = noSignal
fakePlayers.PlayerRemoving = noSignal
function fakePlayers:GetPlayers()
	local list = {}
	for _, p in pairs(inServer) do
		table.insert(list, p)
	end
	return list
end
function fakePlayers:GetPlayerByUserId(id)
	return inServer[id]
end

local function makePlayer(name, userId)
	local attrs = {}
	local p = { Name = name, UserId = userId, Parent = fakePlayers }
	function p:GetAttribute(key)
		return attrs[key]
	end
	function p:SetAttribute(key, value)
		attrs[key] = value
	end
	-- No Backpack: WheelService's Spin Ticket has nowhere to go (CommunitySpec
	-- holds the tickets).
	function p:FindFirstChildOfClass()
		return nil
	end
	inServer[userId] = p
	return p
end

-- Profiles in memory, and the disk a Save copies them to.
local profiles = {}
local disk = {}
local persistent = {}
local saveWorks = true
-- True: the next change to a profile's wheel fields throws.
local updateThrows = false
local PlayerDataService = {
	Get = function(player)
		return profiles[player]
	end,
	IsPersistent = function(player)
		return persistent[player] ~= false
	end,
	IsReady = function(player)
		return profiles[player] ~= nil
	end,
	UpdateWheel = function(player, change)
		if updateThrows then
			error("spec: the profile store threw")
		end
		local p = profiles[player]
		if not p then
			return false
		end
		return change(p) == true
	end,
	Save = function(player)
		record("Save", player)
		if not saveWorks or persistent[player] == false or profiles[player] == nil then
			return false
		end
		disk[player.UserId] = deepCopy(profiles[player])
		return true
	end,
	AddCash = function(player, amount)
		profiles[player].Cash += amount
		return profiles[player].Cash
	end,
	AddSpeed = function(player, amount)
		profiles[player].Speed += amount
		return profiles[player].Speed
	end,
}
-- What the disk holds for a player: an empty profile's worth if nothing was ever saved, so a
-- check that reads it FAILS rather than throws.
local function saved(player)
	return disk[player.UserId] or { WheelBought = -1, Receipts = {} }
end
-- A join: the profile is whatever the disk holds, or a new one.
local function join(name, userId)
	local p = makePlayer(name, userId)
	profiles[p] = ProfileSchema.Sanitise(deepCopy(disk[userId]) or ProfileSchema.Default())
	return p, profiles[p]
end
-- The server is lost with everything it held in memory; the player comes back
-- to another one, which reads the disk.
local function crashAndRejoin(player)
	profiles[player] = nil
	inServer[player.UserId] = nil
	player.Parent = nil
	return join(player.Name, player.UserId)
end
local function leave(player)
	inServer[player.UserId] = nil
	player.Parent = nil
end

local EconomyService = {
	PayReward = function(player, amount, reason)
		record("PayCash", player, amount, reason)
		profiles[player].Cash += amount
		return true
	end,
}
local TreadmillService = {
	PayReward = function(player, amount, reason)
		record("PaySpeed", player, amount, reason)
		profiles[player].Speed += amount
		return true
	end,
}
local CarryService = {
	IsHeldRestored = function()
		return true
	end,
	-- The room CarryService counts, which the wheel asks before a pod (2026-09-30).
	HeldRoom = function(player)
		local count = #profiles[player].Held
		return math.max(GameConfig.Save.MaxHeld - count, 0), count, true
	end,
	GivePod = function(player, species, tier)
		record("GivePod", player, species, tier)
		table.insert(profiles[player].Held, { Id = species, Tier = tier, Hatched = false })
		return true
	end,
	RefreshWalkSpeed = function() end,
}
local BonusChestService = {
	GrantBoost = function(player, id)
		record("GrantBoost", player, id)
		return true
	end,
}
local Metrics = {
	wheelSpun = function(p, prize, source)
		record("wheelSpun", p, prize, source)
	end,
	wheelSpinEarned = function(p, n)
		record("wheelSpinEarned", p, n)
	end,
}
local WheelModel = {
	build = function()
		return nil
	end,
}
local PlantService = {
	InstantHatch = function()
		return true
	end,
	-- WheelService hooks the hatch reveal for the hatch bonus (2026-10-01).
	OnRevealed = function()
		return function() end
	end,
}

-- PolicyService: one answer for everybody unless a player has their own.
local policyFor = {}
local policyDefault = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
-- UserId -> true: the next answer about them is slow, as the real call is. It
-- yields, and the spec resumes it when it chooses.
local policyWaits = {}
local fakePolicy = {}
function fakePolicy:GetPolicyInfoForPlayerAsync(player)
	record("Policy", player)
	if policyWaits[player.UserId] then
		policyWaits[player.UserId] = nil
		coroutine.yield()
	end
	local answer = policyFor[player.UserId] or policyDefault
	if not answer.ok then
		error("spec: PolicyService is unavailable")
	end
	return answer.info
end

-- MarketplaceService: the receipt callback is caught, and a prompt is a record.
local receiptCallback = nil
local prompts = {}
local fakeMarket = setmetatable({
	PromptProductPurchase = function(_, player, productId)
		table.insert(prompts, { who = player, productId = productId })
	end,
}, {
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
	if name == "Players" then
		return fakePlayers
	elseif name == "PolicyService" then
		return fakePolicy
	elseif name == "MarketplaceService" then
		return fakeMarket
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

-- The store's manifest with its in-world product on a spec id, as StoreSpec has it.
local liveHatch = nil
for _, item in ipairs(GameConfig.Store.InWorld or {}) do
	if item.kind == "hatch" then
		liveHatch = table.clone(item)
		liveHatch.product = 990001
	end
end
local liveConfig = setmetatable({
	Store = setmetatable({ InWorld = { liveHatch } }, { __index = GameConfig.Store }),
}, { __index = GameConfig })

local replies = {}
local function last()
	return replies[#replies] or {}
end

-- One server: a WheelService and the StoreService that calls it, seeing the
-- same WheelData. Returns both and the receipt callback that StoreService took.
local function boot(wheelData)
	local overrides = { WheelData = wheelData, GameConfig = liveConfig }
	local W = loadWith(Server:WaitForChild("WheelService"), {
		PlayerDataService = PlayerDataService,
		EconomyService = EconomyService,
		TreadmillService = TreadmillService,
		CarryService = CarryService,
		BonusChestService = BonusChestService,
		Metrics = Metrics,
		WheelModel = WheelModel,
		PlantService = PlantService,
	}, { WheelData = wheelData })
	W.Init()
	W.useReply(function(_, payload)
		table.insert(replies, payload)
	end)
	receiptCallback = nil
	local S = loadWith(Server:WaitForChild("StoreService"), {
		PlayerDataService = PlayerDataService,
		CarryService = CarryService,
		TreadmillService = TreadmillService,
		PlantService = PlantService,
		WheelService = W,
	}, overrides)
	S.Init()
	S.Start()
	return W, S, receiptCallback
end

local nextPurchase = 0
local function receipt(callback, player, product, purchaseId)
	nextPurchase += 1
	return callback({
		PlayerId = player.UserId,
		ProductId = product.productId,
		PurchaseId = purchaseId or ("spin-spec-" .. nextPurchase),
		CurrencySpent = product.robux,
	})
end

local paidOn = setmetatable({
	Paid = { Enabled = true, PromptCooldown = 0 },
	paidLive = function()
		return true
	end,
}, { __index = WheelData })

-- As shipped paid spins are ON (2026-10-01); this copy sees them switched off.
local paidOff = setmetatable({
	Paid = { Enabled = false, PromptCooldown = 0 },
	paidLive = function()
		return false
	end,
}, { __index = WheelData })

--==============================================================================
-- 1. SWITCHED OFF (A COPY)
--==============================================================================
say("-- 1. switched off --")
local okOff, WOff, SOff, offReceipt = pcall(boot, paidOff)
check(okOff and type(offReceipt) == "function", "the two real services load together, and StoreService takes the "
	.. "receipt callback", if okOff then nil else WOff)
if not okOff then
	return string.format("SpinPurchaseSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
end
do
	local p, prof = join("SpecShipped", 7001)
	WOff.CheckPolicy(p)
	table.clear(prompts)
	table.clear(replies)
	WOff.Buy(p, "spin1")
	local why1 = last().reason
	WOff.Buy(p, "spin10")
	check(#prompts == 0 and why1 == "PAID_UNAVAILABLE" and last().reason == "PAID_UNAVAILABLE"
			and p:GetAttribute(A.PaidAllowed) == nil,
		"switched off, an ELIGIBLE player is offered nothing: no prompt for either product", tostring(why1))
	table.clear(trace)
	local a = receipt(offReceipt, p, ONE, "shipped-1")
	local b = receipt(offReceipt, p, TEN, "shipped-10")
	check(a == RETRY and b == RETRY and prof.WheelBought == 0 and #prof.Receipts == 0 and count("Save") == 0,
		"and a receipt for either product grants nothing and is not acknowledged",
		tostring(a) .. "/" .. tostring(b))
	local c = receipt(offReceipt, p, WheelData.ProductByKey.spin5, "shipped-5")
	local d = receipt(offReceipt, p, WheelData.RetiredProducts[1], "shipped-old")
	check(c == RETRY and d == RETRY and prof.WheelBought == 0 and #prof.Receipts == 0,
		"nor does the x5 pack's, or a retired product's: off is off for every spin product",
		tostring(c) .. "/" .. tostring(d))
	prof.WheelBought = 3
	table.clear(replies)
	WOff.Spin(p, "bought")
	check(last().ok == false and last().reason == "PAID_UNAVAILABLE" and prof.WheelBought == 3,
		"and a bought spin already held cannot be spent while paid spins are off")
	leave(p)
end
WOff.useReply(nil)

--==============================================================================
-- 1b. AS SHIPPED: ON (the owner's word, 2026-10-01)
--
-- The real WheelData, untouched: the x5 pack is prompted for an eligible
-- player and its receipt grants 5; a restricted player is offered nothing and
-- their receipt grants nothing; a retired product's receipt still pays once.
--==============================================================================
say("\n-- 1b. as shipped: on --")
check(WheelData.Paid.Enabled == true and WheelData.paidLive() == true,
	"as shipped, paid spins are switched ON (the owner's word, 2026-10-01)")
do
	local okShip, WShip, _, shipReceipt = pcall(boot, WheelData)
	check(okShip and type(shipReceipt) == "function", "the two real services boot with the shipped WheelData",
		if okShip then nil else WShip)
	if okShip then
		local FIVE = WheelData.ProductByKey.spin5
		local fan, fp = join("SpecShipFan", 7201)
		local barred, bp = join("SpecShipBarred", 7202)
		policyFor[barred.UserId] = { ok = true, info = { ArePaidRandomItemsRestricted = true } }
		WShip.CheckPolicy(fan)
		WShip.CheckPolicy(barred)
		table.clear(prompts)
		table.clear(replies)
		WShip.Buy(fan, "spin5")
		WShip.Buy(barred, "spin5")
		local barredWhy = last().reason
		check(#prompts == 1 and prompts[1].who == fan and prompts[1].productId == 3715745407
				and fan:GetAttribute(A.PaidAllowed) == true and barred:GetAttribute(A.PaidAllowed) == nil
				and barredWhy == "PAID_UNAVAILABLE" and fp.WheelBought == 0,
			"an eligible player is prompted for x5 (3715745407), and the prompt grants nothing; a restricted player "
				.. "is prompted for nothing", tostring(barredWhy))
		local paid = receipt(shipReceipt, fan, FIVE, "ship-5")
		local blocked = receipt(shipReceipt, barred, FIVE, "ship-5-barred")
		local old = receipt(shipReceipt, fan, WheelData.RetiredProducts[2], "ship-old-10")
		local oldAgain = receipt(shipReceipt, fan, WheelData.RetiredProducts[2], "ship-old-10")
		check(paid == GRANTED and blocked == RETRY and old == GRANTED and oldAgain == GRANTED
				and fp.WheelBought == 15 and saved(fan).WheelBought == 15 and bp.WheelBought == 0,
			"its receipt grants 5, saved; the restricted player's grants nothing and is not acknowledged; an old "
				.. "+10 Spins receipt pays 10, once",
			string.format("%s/%s/%s/%s, %d", tostring(paid), tostring(blocked), tostring(old), tostring(oldAgain),
				fp.WheelBought))
		policyFor[barred.UserId] = nil
		leave(fan)
		leave(barred)
		WShip.useReply(nil)
	end
end

--==============================================================================
-- 2. THE PURCHASE, SWITCHED ON
--==============================================================================
say("\n-- 2. the purchase --")
local okOn, W, S, deliver = pcall(boot, paidOn)
check(okOn and type(deliver) == "function", "a server that sees paid spins switched on boots",
	if okOn then nil else W)
if not okOn then
	return string.format("SpinPurchaseSpec: %d passed, %d failed\n%s", pass, fail, table.concat(out, "\n"))
end

local buyer, bp = join("SpecBuyer", 7002)
W.CheckPolicy(buyer)
check(W.PaidAllowed(buyer) and buyer:GetAttribute(A.PaidAllowed) == true,
	"an eligible player, once PolicyService has answered, may buy")

table.clear(prompts)
table.clear(replies)
table.clear(trace)
W.Buy(buyer, "spin1")
check(#prompts == 1 and prompts[1].who == buyer and prompts[1].productId == ONE.productId
		and last().ok == true and last().buy == true and last().key == "spin1",
	"asking for +1 Spin opens Roblox's prompt for product " .. ONE.productId .. ", on the server")
check(bp.WheelBought == 0 and #bp.Receipts == 0 and count("Save") == 0 and buyer:GetAttribute(A.Bought) == 0,
	"the prompt opening grants nothing, saves nothing and remembers nothing")
-- The player closes the prompt, or buys nothing: no receipt ever comes, and
-- nothing else in the game is listening for the prompt to end.
check(bp.WheelBought == 0, "a prompt that ends with no purchase leaves no spin behind")

table.clear(trace)
local first = receipt(deliver, buyer, ONE, "buy-1")
local g, s = indexOf("Save"), count("Save")
check(first == GRANTED and bp.WheelBought == 1 and buyer:GetAttribute(A.Bought) == 1
		and table.find(bp.Receipts, "buy-1") ~= nil and g ~= nil and s == 1
		and saved(buyer).WheelBought == 1
		and table.find(saved(buyer).Receipts, "buy-1") ~= nil,
	"the RECEIPT grants exactly 1 spin, writes the ledger, and is acknowledged only with both on disk",
	tostring(first))

table.clear(prompts)
W.Buy(buyer, "spin10")
local ten = receipt(deliver, buyer, TEN, "buy-10")
check(#prompts == 1 and prompts[1].productId == TEN.productId and ten == GRANTED and bp.WheelBought == 11
		and saved(buyer).WheelBought == 11,
	"+10 Spins: product " .. TEN.productId .. " is prompted, and its receipt grants exactly 10", tostring(ten))

--==============================================================================
-- 3. THE LEDGER
--==============================================================================
say("\n-- 3. the ledger --")
local again1 = receipt(deliver, buyer, ONE, "buy-1")
local again10 = receipt(deliver, buyer, TEN, "buy-10")
check(again1 == GRANTED and again10 == GRANTED and bp.WheelBought == 11,
	"both receipts delivered a second time: acknowledged, and nothing more granted")

-- A save that fails: the grant is in memory, the receipt stays open.
saveWorks = false
local unsaved = receipt(deliver, buyer, TEN, "buy-unsaved")
local unsavedAgain = receipt(deliver, buyer, TEN, "buy-unsaved")
check(unsaved == RETRY and unsavedAgain == RETRY and bp.WheelBought == 21 and saved(buyer).WheelBought == 11,
	"a grant whose save fails is not acknowledged, however often it is delivered -- and is granted once",
	string.format("%s/%s, %d in memory", tostring(unsaved), tostring(unsavedAgain), bp.WheelBought))
saveWorks = true
local savedLater = receipt(deliver, buyer, TEN, "buy-unsaved")
check(savedLater == GRANTED and bp.WheelBought == 21 and saved(buyer).WheelBought == 21,
	"the delivery after the save works is acknowledged, with no second grant", tostring(savedLater))

-- INTERRUPTED BEFORE THE SAVE: the server is lost with the grant only in
-- memory. The player comes back to what the disk held; the receipt, never
-- acknowledged, is delivered again and pays -- once.
saveWorks = false
local lost = receipt(deliver, buyer, ONE, "buy-crash-before")
saveWorks = true
local inMemory = bp.WheelBought
buyer, bp = crashAndRejoin(buyer)
W.CheckPolicy(buyer)
local afterCrash = bp.WheelBought
local redelivered = receipt(deliver, buyer, ONE, "buy-crash-before")
local redeliveredAgain = receipt(deliver, buyer, ONE, "buy-crash-before")
check(lost == RETRY and inMemory == 22 and afterCrash == 21 and redelivered == GRANTED
		and redeliveredAgain == GRANTED and bp.WheelBought == 22 and saved(buyer).WheelBought == 22,
	"a server lost before the save: the spin is not on disk, the receipt is delivered again on the rejoin, and "
		.. "pays exactly once",
	string.format("%d -> %d -> %d", inMemory, afterCrash, bp.WheelBought))

-- INTERRUPTED AFTER THE SAVE: granted, saved, and the acknowledgement never
-- reached Roblox. The rejoin's delivery finds the ledger on disk.
local paid = receipt(deliver, buyer, TEN, "buy-crash-after")
buyer, bp = crashAndRejoin(buyer)
W.CheckPolicy(buyer)
local held = bp.WheelBought
local replayed = receipt(deliver, buyer, TEN, "buy-crash-after")
check(paid == GRANTED and held == 32 and replayed == GRANTED and bp.WheelBought == 32,
	"a server lost after the save: the ledger came back with the profile, so the delivery is acknowledged and "
		.. "grants nothing again",
	string.format("%d then %d", held, bp.WheelBought))

-- THE BUYER LEAVES BEFORE THE RECEIPT IS PROCESSED, and comes back.
leave(buyer)
local gone = receipt(deliver, buyer, ONE, "buy-left")
buyer, bp = join(buyer.Name, buyer.UserId)
-- The save has not loaded yet.
local loadedProfile = profiles[buyer]
profiles[buyer] = nil
local loading = receipt(deliver, buyer, ONE, "buy-left")
profiles[buyer] = loadedProfile
-- The receipt lands on the join, before PolicyService was ever asked about them.
table.clear(trace)
local onJoin = receipt(deliver, buyer, ONE, "buy-left")
check(gone == RETRY and loading == RETRY and onJoin == GRANTED and bp.WheelBought == 33 and count("Policy") == 1,
	"the buyer gone, then back with the save still loading: not processed. Loaded, the receipt pays on the "
		.. "join -- the grant asks PolicyService itself",
	string.format("%s, %s, %s", tostring(gone), tostring(loading), tostring(onJoin)))

-- The ledger keeps only so many ids; an old acknowledged receipt is never
-- delivered again by Roblox, so rolling off the end costs nothing.
check(#bp.Receipts <= GameConfig.Save.MaxReceipts and table.find(bp.Receipts, "buy-left") ~= nil,
	"the ledger is on the profile, newest last, inside its cap", #bp.Receipts)

-- TWO DELIVERIES OF ONE RECEIPT AT THE SAME TIME. The first is still waiting
-- for PolicyService -- a player it has never been asked about -- when the
-- second arrives. The ledger has no entry yet, and only one of them may grant.
do
	local twin, wp = join("SpecTwin", 7010)
	policyWaits[twin.UserId] = true
	local firstAnswer = nil
	local running = coroutine.create(function()
		firstAnswer = receipt(deliver, twin, TEN, "twin-10")
	end)
	coroutine.resume(running)
	local waiting = coroutine.status(running) == "suspended" and wp.WheelBought == 0 and #wp.Receipts == 0
	local second = receipt(deliver, twin, TEN, "twin-10")
	coroutine.resume(running)
	check(waiting and second == RETRY and firstAnswer == GRANTED and wp.WheelBought == 10
			and saved(twin).WheelBought == 10 and #wp.Receipts == 1,
		"two deliveries of one receipt at once: the second is told \"not yet\" while the first is still asking "
			.. "PolicyService, and ten spins are granted, not twenty",
		string.format("%s then %s, %d spins, %d in the ledger", tostring(second), tostring(firstAnswer),
			wp.WheelBought, #wp.Receipts))
	local later = receipt(deliver, twin, TEN, "twin-10")
	check(later == GRANTED and wp.WheelBought == 10, "and a later delivery is acknowledged from the ledger",
		tostring(later))

	-- A grant that throws: not acknowledged, and not shut out either.
	updateThrows = true
	local okThrown, thrown = pcall(receipt, deliver, twin, ONE, "twin-thrown")
	updateThrows = false
	local retried = receipt(deliver, twin, ONE, "twin-thrown")
	check(okThrown and thrown == RETRY and retried == GRANTED and wp.WheelBought == 11,
		"a grant that throws leaves its receipt open: the next delivery pays, once",
		string.format("%s then %s, %d spins", tostring(thrown), tostring(retried), wp.WheelBought))
end

--==============================================================================
-- 3b. THE x5 PACK, AND THE RETIRED PRODUCTS' RECEIPTS (2026-10-01)
--
-- Three packs on sale now; the two first products are retired but a receipt
-- for one, already paid for, must still be honoured exactly once.
--==============================================================================
say("\n-- 3b. the x5 pack, and the retired products' receipts --")
do
	local FIVE = WheelData.ProductByKey.spin5
	local OLD1, OLD10 = WheelData.RetiredProducts[1], WheelData.RetiredProducts[2]
	local pack, pp = join("SpecPacks", 7100)
	W.CheckPolicy(pack)
	table.clear(prompts)
	table.clear(replies)
	W.Buy(pack, "spin5")
	local five = receipt(deliver, pack, FIVE, "pack-5")
	check(#prompts == 1 and prompts[1].productId == 3715745407 and five == GRANTED and pp.WheelBought == 5
			and saved(pack).WheelBought == 5 and table.find(saved(pack).Receipts, "pack-5") ~= nil,
		"x5: product 3715745407 is prompted, and its RECEIPT grants exactly 5, saved with its ledger entry",
		tostring(five))
	local fiveAgain = receipt(deliver, pack, FIVE, "pack-5")
	check(fiveAgain == GRANTED and pp.WheelBought == 5,
		"the x5 receipt delivered a second time: acknowledged, and nothing more granted")
	saveWorks = false
	local u1 = receipt(deliver, pack, FIVE, "pack-5-unsaved")
	local u2 = receipt(deliver, pack, FIVE, "pack-5-unsaved")
	saveWorks = true
	local u3 = receipt(deliver, pack, FIVE, "pack-5-unsaved")
	check(u1 == RETRY and u2 == RETRY and u3 == GRANTED and pp.WheelBought == 10 and saved(pack).WheelBought == 10,
		"an x5 grant whose save fails stays open until a save lands -- and pays 5, once",
		string.format("%s/%s/%s, %d", tostring(u1), tostring(u2), tostring(u3), pp.WheelBought))
	local old1 = receipt(deliver, pack, OLD1, "old-1")
	local old10 = receipt(deliver, pack, OLD10, "old-10")
	local old1Again = receipt(deliver, pack, OLD1, "old-1")
	check(old1 == GRANTED and old10 == GRANTED and old1Again == GRANTED and pp.WheelBought == 21
			and saved(pack).WheelBought == 21,
		"an outstanding receipt for a RETIRED product (+1 Spin 3715369823, +10 Spins 3715370108) still pays "
			.. "exactly 1 and 10 -- once, however often it is delivered", tostring(pp.WheelBought))
	table.clear(prompts)
	table.clear(replies)
	W.Buy(pack, OLD1.key)
	check(#prompts == 0 and last().ok == false and last().reason == "UNKNOWN_PRODUCT",
		"but a retired product cannot be asked for: no prompt", tostring(last().reason))
	leave(pack)
end

--==============================================================================
-- 4. WHO MAY
--==============================================================================
say("\n-- 4. who may --")
-- Bought outside the game: a receipt with no prompt of ours behind it.
local outside, op = join("SpecOutside", 7003)
table.clear(prompts)
table.clear(trace)
local external = receipt(deliver, outside, TEN, "outside-10")
check(#prompts == 0 and external == GRANTED and op.WheelBought == 10 and count("Policy") == 1,
	"a purchase made outside the game arrives as a receipt on the join: granted to an eligible player, with no "
		.. "prompt involved", tostring(external))

-- TWO POLICY CHECKS IN THE AIR FOR ONE PLAYER: the join's, still waiting, and
-- a receipt's, which comes back first and allows the grant. Then the join's
-- FAILS, late. It must not take back what PolicyService really said.
do
	local racer, qp = join("SpecRacer", 7011)
	policyWaits[racer.UserId] = true
	local joinCheck = coroutine.create(function()
		W.CheckPolicy(racer)
	end)
	coroutine.resume(joinCheck)
	local waiting = coroutine.status(joinCheck) == "suspended" and not W.PaidAllowed(racer)
	local paidFor = receipt(deliver, racer, TEN, "racer-10")
	local allowedThen = W.PaidAllowed(racer)
	policyFor[racer.UserId] = { ok = false }
	coroutine.resume(joinCheck)
	policyFor[racer.UserId] = nil
	table.clear(replies)
	W.DebugForce(racer, "cash_small")
	W.Spin(racer, "bought")
	check(waiting and paidFor == GRANTED and allowedThen and W.PaidAllowed(racer)
			and racer:GetAttribute(A.PaidAllowed) == true and last().ok == true and last().source == "bought"
			and qp.WheelBought == 9,
		"two policy checks in the air for one player: the one that fails late does not shut them out of the "
			.. "spins they were just allowed to buy",
		string.format("%s, allowed %s then %s, %s", tostring(paidFor), tostring(allowedThen),
			tostring(W.PaidAllowed(racer)), tostring(last().reason)))
end

-- Restricted: not offered, not prompted, not granted, cannot spend.
local barred, rp = join("SpecRestricted", 7004)
policyFor[barred.UserId] = { ok = true, info = { ArePaidRandomItemsRestricted = true } }
W.CheckPolicy(barred)
table.clear(prompts)
table.clear(replies)
W.Buy(barred, "spin1")
local refusedBuy = last().reason
local barredReceipt = receipt(deliver, barred, TEN, "barred-10")
local barredAgain = receipt(deliver, barred, TEN, "barred-10")
check(barred:GetAttribute(A.PaidAllowed) == nil and #prompts == 0 and refusedBuy == "PAID_UNAVAILABLE",
	"a restricted player is offered nothing and shown no prompt", tostring(refusedBuy))
check(barredReceipt == RETRY and barredAgain == RETRY and rp.WheelBought == 0 and #rp.Receipts == 0
		and saved(barred).WheelBought <= 0,
	"and a receipt in their name grants nothing, however often it comes: it is never acknowledged, so Roblox "
		.. "returns the Robux",
	tostring(barredReceipt) .. "/" .. tostring(barredAgain))
rp.WheelBought = 2
table.clear(replies)
W.Spin(barred, "bought")
local barredSpin = last().reason
W.Spin(barred, "earned")
check(barredSpin == "PAID_UNAVAILABLE" and last().reason == "NO_SPINS" and rp.WheelBought == 2,
	"nor can they spend a bought spin, or be asked to: with no earned spin the answer is NO SPINS, not a question",
	tostring(barredSpin) .. "/" .. tostring(last().reason))
rp.WheelBought = 0

-- PolicyService will not answer: closed, until it does.
local silent, sp = join("SpecSilent", 7005)
policyFor[silent.UserId] = { ok = false }
W.CheckPolicy(silent)
table.clear(prompts)
table.clear(replies)
W.Buy(silent, "spin10")
local silentBuy = last().reason
local silentReceipt = receipt(deliver, silent, ONE, "silent-1")
check(#prompts == 0 and silentBuy == "PAID_UNAVAILABLE" and silentReceipt == RETRY and sp.WheelBought == 0
		and silent:GetAttribute(A.PaidAllowed) == nil,
	"PolicyService failing: no prompt and no grant (fails closed)", tostring(silentBuy))
policyFor[silent.UserId] = { ok = true, info = {} }
local blankReceipt = receipt(deliver, silent, ONE, "silent-1")
check(blankReceipt == RETRY and sp.WheelBought == 0,
	"an answer without the field is not a yes either", tostring(blankReceipt))
policyFor[silent.UserId] = { ok = true, info = { ArePaidRandomItemsRestricted = false } }
W.CheckPolicy(silent)
local answered = receipt(deliver, silent, ONE, "silent-1")
check(answered == GRANTED and sp.WheelBought == 1,
	"once PolicyService says they may, the same receipt -- still open -- pays", tostring(answered))

-- A profile that is not saving.
local temp, tp = join("SpecTemporary", 7006)
persistent[temp] = false
W.CheckPolicy(temp)
table.clear(prompts)
table.clear(replies)
W.Buy(temp, "spin1")
local tempReceipt = receipt(deliver, temp, ONE, "temp-1")
check(#prompts == 0 and last().reason == "NOT_SAVED" and tempReceipt == RETRY and tp.WheelBought == 0,
	"a profile that cannot be saved is sold nothing and granted nothing", tostring(last().reason))
persistent[temp] = nil

-- No room.
local full, fp = join("SpecFull", 7007)
W.CheckPolicy(full)
fp.WheelBought = WheelData.MaxBoughtHeld - 4
table.clear(prompts)
table.clear(replies)
W.Buy(full, "spin10")
local fullBuy = last().reason
local fullReceipt = receipt(deliver, full, TEN, "full-10")
local smallReceipt = receipt(deliver, full, ONE, "full-1")
check(#prompts == 0 and fullBuy == "BALANCE_FULL" and fullReceipt == RETRY
		and smallReceipt == GRANTED and fp.WheelBought == WheelData.MaxBoughtHeld - 3,
	"a balance with no room for ten is not prompted for ten and not granted part of ten; one still fits",
	tostring(fullBuy))
fp.WheelBought = 100
local roomNow = receipt(deliver, full, TEN, "full-10")
check(roomNow == GRANTED and fp.WheelBought == 110,
	"and once there is room the open receipt pays all ten", tostring(roomNow))

--==============================================================================
-- 5. SPENDING
--==============================================================================
say("\n-- 5. spending --")
local spender, xp = join("SpecSpender", 7008)
W.CheckPolicy(spender)
receipt(deliver, spender, TEN, "spend-10")
xp.WheelEarned = 1
table.clear(replies)
W.DebugForce(spender, "cash_small")
W.Spin(spender, "earned")
check(last().ok == true and last().source == "earned" and xp.WheelEarned == 0 and xp.WheelBought == 10,
	"with an earned spin in hand, SPIN spends the earned one")
table.clear(replies)
W.Spin(spender, "earned")
check(last().ok == false and last().reason == "CONFIRM_BOUGHT" and xp.WheelBought == 10,
	"with only bought spins left, SPIN asks first and spends nothing")
W.DebugForce(spender, "speed_small")
W.Spin(spender, "bought")
check(last().ok == true and last().source == "bought" and xp.WheelBought == 9 and xp.WheelDayCount == 0
		and xp.WheelDayAt == 0,
	"the yes spends exactly one bought spin, and opens no earning window")
local kind, n = W.AwardCompletion(spender, "spin-spec-run-1", 1800)
check(kind == "spin" and n == 1 and xp.WheelEarned == 1 and xp.WheelDayCount == 1,
	"the day's first obby run still earns spin 1 of 5: buying and spending used none of the allowance")
for i = 2, 5 do
	W.AwardCompletion(spender, "spin-spec-run-" .. i, 1800)
end
local windowAt = xp.WheelDayAt
receipt(deliver, spender, TEN, "spend-10-more")
local sixth = W.AwardCompletion(spender, "spin-spec-run-6", 1800)
check(xp.WheelDayCount == 5 and xp.WheelEarned == 5 and sixth == "speed" and xp.WheelBought == 19
		and xp.WheelDayAt == windowAt,
	"five earned is still the limit with nineteen bought in hand, and a purchase does not move the reset",
	string.format("%d earned, %d bought", xp.WheelEarned, xp.WheelBought))

--==============================================================================
-- 6. THE FREE PATH
--==============================================================================
say("\n-- 6. the free path --")
local free, fr = join("SpecFree", 7009)
policyFor[free.UserId] = { ok = false }
W.CheckPolicy(free)
local freeKind = W.AwardCompletion(free, "free-run-1", 1800)
table.clear(replies)
W.DebugForce(free, "cash_small")
W.Spin(free, "earned")
check(freeKind == "spin" and last().ok == true and last().source == "earned" and fr.WheelEarned == 0,
	"a player PolicyService will not answer for still earns a spin from the obby and spins it")
policyFor[barred.UserId] = { ok = true, info = { ArePaidRandomItemsRestricted = true } }
local barredKind = W.AwardCompletion(barred, "free-run-2", 1800)
table.clear(replies)
W.DebugForce(barred, "speed_small")
W.Spin(barred, "earned")
check(barredKind == "spin" and last().ok == true and last().source == "earned",
	"and so does a restricted one: the earned path never reads the policy")

W.useReply(nil)
W.useClock(nil)
say(string.format("\nSpinPurchaseSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
