--!nocheck
--==============================================================================
-- Steal a Seed :: WheelScaleSpec
-- WHEEL SCALES WITH THE PLAYER and INVITE PLANTS ON THE WHEEL (the owner's
-- brief, 2026-10-08; Michael's suggestions). Edit mode:
--     local run = loadstring(game:GetService("HttpService"):GetAsync(
--         "http://127.0.0.1:8731/tools/tests/run.luau", true))()
--     print(run("WheelScaleSpec"))
--
-- The owner's checks:
--   scaled      the cash and Speed prizes at a new, a mid and a late profile;
--               the floors hold; two significant figures, so the words are exact
--   shown=paid  the amounts the server publishes are the amounts a spin pays,
--               even when the garden grew since; the reply says the amount
--   odds        the weights sum to 10,000 and rarity follows odds
--   invite      the prize gives the next plant not owned; with every one owned
--               it pays its swap; a full Bag waits, and a plant a milestone gave
--               meanwhile is not given twice
-- THE REAL WheelService, loaded from its Source with its services stood in, as
-- WheelSpec does (that spec is at Luau's 200 locals). Simulated user ids only.
--==============================================================================

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Shared = ReplicatedStorage:WaitForChild("SeedGame"):WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local WheelData = require(Shared:WaitForChild("WheelData"))
local SeedData = require(Shared:WaitForChild("SeedData"))
local Server = ServerScriptService:WaitForChild("SeedGameServer")
local ProfileSchema = require(Server:WaitForChild("ProfileSchema"))

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

local B = WheelData.ById
local A = WheelData.Attributes
local FORMS = GameConfig.InviteRewards.Forms
local TIERS = GameConfig.Mill.Tiers

local ok, err = pcall(function()

--==============================================================================
-- 1. THE AMOUNTS (pure)
--==============================================================================
say("-- 1. the amounts --")
check(WheelData.niceDown(1234567) == 1200000 and WheelData.niceDown(99) == 99 and WheelData.niceDown(100) == 100
		and WheelData.niceDown(1999) == 1900 and WheelData.niceDown(0) == 0 and WheelData.niceDown(0 / 0) == 0,
	"rounded DOWN to two significant figures")
-- Gardens the game can grow: a new player's starter pays next to nothing; mid
-- is about fifteen Legendary/Epic plants (plot level 4) beside a tier-7 mill;
-- late is plot level 7's thirty slots of the top plants (the Secrets, at
-- $155K-$189K/s each: about $5M/s, no pass) beside a tier-13 mill.
local profiles = {
	{ name = "new", income = 0, tier = 1 },
	{ name = "mid", income = 25000, tier = 7 },
	{ name = "late", income = 5e6, tier = 13 },
}
local table1 = {}
for _, pf in ipairs(profiles) do
	pf.amounts = WheelData.amountsFor(pf.income, TIERS[pf.tier].speed)
	local row = {}
	for _, id in ipairs({ "cash_small", "cash_medium", "cash_jackpot", "speed_small", "speed_large" }) do
		table.insert(row, string.format("%s %s", id, (WheelData.wordsFor(B[id], pf.amounts[id]))))
	end
	table.insert(table1, string.format("%s (income $%s/s, mill tier %d %s/s): %s", pf.name,
		GameConfig.compact(pf.income), pf.tier, GameConfig.compact(TIERS[pf.tier].speed), table.concat(row, ", ")))
end
local new, mid, late = profiles[1].amounts, profiles[2].amounts, profiles[3].amounts
check(new.cash_small == 5000 and new.cash_medium == 20000 and new.cash_jackpot == 75000
		and new.speed_small == 1200 and new.speed_large == 10000,
	"a new player: the cash floors ($5,000 / $20,000 / $75,000); Speed +1,200 (60 s of a tier-1 mill beats 1,000) and +10,000")
check(mid.cash_small == 3000000 and mid.cash_medium == 9000000 and mid.cash_jackpot == 30000000
		and mid.speed_small == WheelData.niceDown(TIERS[7].speed * 60) and mid.speed_large == WheelData.niceDown(TIERS[7].speed * 300),
	"mid game ($25K/s, tier 7): $3M / $9M / $30M, and 60 s / 5 min of the mill")
check(late.cash_small == 6e8 and late.cash_medium == 1.8e9 and late.cash_jackpot == 6e9
		and late.speed_large == WheelData.niceDown(TIERS[13].speed * 300),
	"late game ($5M/s, tier 13): $600M / $1.8B / $6B, and 5 min of the mill")
for _, line in ipairs(table1) do
	say("        " .. line)
end
local floorsHold = true
for _, rate in ipairs({ 0, 0.5, -10, 0 / 0, math.huge, 3 }) do
	for _, reward in ipairs(WheelData.Rewards) do
		if reward.scale and WheelData.amountFor(reward, rate, rate) < (reward.amount or 0) then
			floorsHold = false
		end
	end
end
check(floorsHold, "the floors hold at every rate: none, tiny, negative, NaN, infinite")
local exact = true
for _, pf in ipairs(profiles) do
	for id, amount in pairs(pf.amounts) do
		local label = WheelData.wordsFor(B[id], amount)
		if WheelData.niceDown(amount) ~= amount and amount ~= B[id].amount then
			exact = false
		end
		if not string.find(label, WheelData.amountWords(amount), 1, true) then
			exact = false
		end
	end
end
check(exact and WheelData.amountWords(1200000) == "1.2M" and WheelData.amountWords(73000) == "73,000"
		and WheelData.amountWords(6e11) == "600B",
	"every amount has two figures, which the wheel's words print exactly ($1.2M is 1,200,000)")
check(select(1, WheelData.wordsFor(B.cash_small, 5000)) == B.cash_small.label
		and select(2, WheelData.wordsFor(B.speed_large, 10000)) == B.speed_large.short
		and select(3, WheelData.wordsFor(B.cash_jackpot, 75000)) == B.cash_jackpot.title,
	"at its floor a prize says exactly what it always said")
local enc = WheelData.encodeAmounts(mid)
local dec = WheelData.decodeAmounts(enc)
local round = true
for id, amount in pairs(mid) do
	if dec[id] ~= amount then
		round = false
	end
end
check(round and next(WheelData.decodeAmounts("cash_small=;bogus=5;speed_small=-3")) == nil
		and next(WheelData.decodeAmounts(nil)) == nil,
	"the published amounts travel as one attribute and back; anything malformed reads as missing (the floors)")

--==============================================================================
-- 2. THE ODDS
--==============================================================================
say("\n-- 2. the odds --")
local total = 0
for _, r in ipairs(WheelData.Rewards) do
	total += r.weight
end
check(total == 10000 and B.invite.weight == 20 and B.cash_small.weight == 2180,
	"the weights sum to 10,000: the invite plant's 20 came off cash_small (2200 -> 2180)")
local byOdds = true
for _, a in ipairs(WheelData.Rewards) do
	for _, b in ipairs(WheelData.Rewards) do
		if a.weight < b.weight and GameConfig.RarityTier[a.rarity] < GameConfig.RarityTier[b.rarity] then
			byOdds = false
		end
	end
end
check(byOdds and B.invite.rarity == "Mythic", "rarity follows odds: the invite plant (0.2%) is Mythic, never below a likelier prize")
local outcomes = WheelData.outcomes(false, true, mid)
local swapLine = nil
for _, o in ipairs(outcomes) do
	if o.prize == B.invite.title then
		swapLine = o.line
	end
end
check(swapLine == "You own every invite plant, so this pays $30M Cash Jackpot instead",
	"the odds list says what the invite slice pays an owner of every plant -- at their own amount", swapLine)

--==============================================================================
-- 3. THE SERVICE: SHOWN IS PAID, AND THE INVITE PLANT
--==============================================================================
say("\n-- 3. the service --")
local trace = {}
local function record(name, ...)
	table.insert(trace, { name = name, args = { ... } })
end
local function lastArgs(name)
	for i = #trace, 1, -1 do
		if trace[i].name == name then
			return trace[i].args
		end
	end
	return nil
end
local fakePlayers = {}
local noSignal = { Connect = function()
	return { Disconnect = function() end }
end }
fakePlayers.PlayerAdded = noSignal
fakePlayers.PlayerRemoving = noSignal
function fakePlayers:GetPlayers()
	return {}
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
	function p:FindFirstChildOfClass()
		return nil
	end
	return p
end
local profilesOf = {}
local rates = {}
local stand = {
	PlayerDataService = {
		Get = function(player)
			return profilesOf[player]
		end,
		IsPersistent = function()
			return true
		end,
		IsReady = function(player)
			return profilesOf[player] ~= nil
		end,
		UpdateWheel = function(player, change)
			local p = profilesOf[player]
			return p ~= nil and change(p) == true
		end,
		Save = function()
			return true
		end,
		PublishInvites = function(player)
			record("PublishInvites", player)
		end,
	},
	EconomyService = {
		RateFor = function(player)
			return rates[player] or 0
		end,
		PayReward = function(player, amount)
			record("PayCash", player, amount)
			profilesOf[player].Cash += amount
			return true
		end,
	},
	TreadmillService = {
		PayReward = function(player, amount)
			record("PaySpeed", player, amount)
			profilesOf[player].Speed += amount
			return true
		end,
	},
	CarryService = {
		IsHeldRestored = function()
			return true
		end,
		HeldRoom = function(player)
			local n = #profilesOf[player].Held
			return math.max(GameConfig.Save.MaxHeld - n, 0), n, true
		end,
		GivePod = function(player, species, tier)
			table.insert(profilesOf[player].Held, { Id = species, Tier = tier, Hatched = false })
			return true
		end,
		GiveHatched = function(player, species, tier, equipAfter, revealAt, onRecord)
			if onRecord and GameConfig.Save.MaxHeld - #profilesOf[player].Held < 1 then
				record("GiveHatchedFull", player, species.Id)
				return false, "STORAGE_FULL"
			end
			record("GiveHatched", player, species.Id, tier)
			table.insert(profilesOf[player].Held, { Id = species.Id, Tier = tier, Hatched = true })
			return true
		end,
	},
	BonusChestService = { GrantBoost = function()
		return true
	end },
	Metrics = { wheelSpun = function() end, wheelSpinEarned = function() end },
	WheelModel = { build = function()
		return nil
	end },
	PlantService = { OnRevealed = function()
		return function() end
	end },
}
local fakeGame = {}
function fakeGame:GetService(name)
	if name == "Players" then
		return fakePlayers
	elseif name == "PolicyService" then
		return { GetPolicyInfoForPlayerAsync = function()
			return { ArePaidRandomItemsRestricted = true }
		end }
	end
	return game:GetService(name)
end
local module = Server:WaitForChild("WheelService")
local chunk, cerr = loadstring(module.Source, "=WheelService")
assert(chunk, tostring(cerr))
local parent = {}
function parent:WaitForChild(name)
	local sibling = stand[name]
	assert(sibling ~= nil, "WheelService asked for an unexpected sibling " .. name)
	return { __standIn = sibling }
end
local outerRequire = require
setfenv(chunk, setmetatable({
	game = fakeGame,
	script = { Name = "WheelService", Parent = parent },
	require = function(target)
		if type(target) == "table" and target.__standIn ~= nil then
			return target.__standIn
		end
		return outerRequire(target)
	end,
}, { __index = getfenv(1) }))
local W = chunk()
W.Init()
W.useClock(function()
	return 2000000
end)
local replies = {}
W.useReply(function(_, payload)
	table.insert(replies, payload)
end)
local function lastReply()
	return replies[#replies]
end

-- Shown is paid: published at $25K/s and a tier-7 mill, then the garden grows.
local p = makePlayer("SpecScale", 90000000001)
profilesOf[p] = ProfileSchema.Default()
local pr = profilesOf[p]
pr.WheelEarned = 30
pr.MillTier = 7
rates[p] = 25000
local published = W.PublishAmounts(p)
local shown = WheelData.decodeAmounts(p:GetAttribute(A.Amounts))
check(shown.cash_medium == 9000000 and published.cash_medium == 9000000
		and shown.speed_large == WheelData.niceDown(TIERS[7].speed * 300),
	"the server publishes this player's amounts, from its own numbers: $9M, +" .. WheelData.amountWords(shown.speed_large))
rates[p] = 80000
W.DebugForce(p, "cash_medium")
W.Spin(p, "earned")
local paid = lastArgs("PayCash")
check(paid and paid[2] == shown.cash_medium and lastReply().amount == shown.cash_medium,
	"a spin pays the amount the wheel showed ($9M) even though the garden grew since -- and says so",
	paid and paid[2])
local again = WheelData.decodeAmounts(p:GetAttribute(A.Amounts))
check(again.cash_medium == WheelData.niceDown(80000 * 360),
	"after the spin the next amounts are published ($" .. WheelData.amountWords(again.cash_medium or 0) .. ")")
W.DebugForce(p, "speed_large")
W.Spin(p, "earned")
check(lastArgs("PaySpeed") and lastArgs("PaySpeed")[2] == again.speed_large and lastReply().amount == again.speed_large,
	"a Speed prize: 5 min of this player's own mill tier, as shown")

-- The invite plant: the first not owned, recorded as owned.
table.clear(trace)
pr.InviteOwned = { FORMS[1] }
W.DebugForce(p, "invite")
W.Spin(p, "earned")
local give = lastArgs("GiveHatched")
check(give and give[2] == FORMS[2] and give[3] == SeedData.InviteTier and table.find(pr.InviteOwned, FORMS[2]) ~= nil
		and lastReply().species == FORMS[2] and lastReply().swapped == false and lastArgs("PublishInvites") ~= nil,
	"the invite prize gives the next plant NOT owned (" .. FORMS[2] .. "), grown, and marks it owned")

-- Every plant owned: the swap, at this player's jackpot.
table.clear(trace)
pr.InviteOwned = table.clone(FORMS)
W.PublishAmounts(p)
local jackpot = WheelData.decodeAmounts(p:GetAttribute(A.Amounts)).cash_jackpot
W.DebugForce(p, "invite")
W.Spin(p, "earned")
check(lastReply().swapped == true and lastReply().prize == "cash_jackpot" and lastReply().rolled == "invite"
		and lastArgs("PayCash") and lastArgs("PayCash")[2] == jackpot and lastArgs("GiveHatched") == nil,
	"with every invite plant owned it pays its swap, the jackpot -- this player's $" .. WheelData.amountWords(jackpot or 0))

-- A full Bag waits; and a plant a milestone gave meanwhile is not given twice.
table.clear(trace)
pr.InviteOwned = {}
while #pr.Held < GameConfig.Save.MaxHeld do
	table.insert(pr.Held, { Id = "nubkin", Tier = 1, Hatched = true })
end
W.DebugForce(p, "invite")
W.Spin(p, "earned")
local row = pr.WheelPending[#pr.WheelPending]
check(lastReply().owed == true and row and row.Prize == "invite" and row.Species == FORMS[1]
		and lastArgs("GiveHatchedFull") ~= nil and #pr.InviteOwned == 0,
	"a full Bag: the invite plant waits, owed (" .. FORMS[1] .. "), nothing marked owned")
table.insert(pr.InviteOwned, FORMS[1]) -- an invite milestone gave it while it waited
table.remove(pr.Held)
table.clear(trace)
W.DeliverPending(p)
check(#pr.WheelPending == 0 and lastArgs("GiveHatched") and lastArgs("GiveHatched")[2] == FORMS[2]
		and table.find(pr.InviteOwned, FORMS[2]) ~= nil,
	"room made: it is handed over -- the next plant not owned, as the first was given meanwhile")
-- Every plant given while it waited: the swap, at this player's jackpot now.
table.clear(trace)
pr.InviteOwned = {}
while #pr.Held < GameConfig.Save.MaxHeld do
	table.insert(pr.Held, { Id = "nubkin", Tier = 1, Hatched = true })
end
W.DebugForce(p, "invite")
W.Spin(p, "earned")
pr.InviteOwned = table.clone(FORMS) -- milestones gave every plant while it waited
table.remove(pr.Held)
table.clear(trace)
W.DeliverPending(p)
local owedJackpot = WheelData.amountFor(B.cash_jackpot, rates[p], TIERS[pr.MillTier].speed)
check(#pr.WheelPending == 0 and lastArgs("PayCash") and lastArgs("PayCash")[2] == owedJackpot
		and owedJackpot > B.cash_jackpot.amount and lastArgs("GiveHatched") == nil,
	"every plant given while it waited: the swap, at this player's own jackpot ($"
		.. WheelData.amountWords(owedJackpot) .. "), never its floor")

-- The saved row keeps the amount it was rolled at.
local saved = ProfileSchema.Sanitise({ Version = GameConfig.Save.CurrentVersion, WheelPending = {
	{ Id = "a-1-1", Rolled = "cash_small", Prize = "cash_small", Species = "", Source = "earned", At = 1, Amount = 3000000 },
	{ Id = "a-1-2", Rolled = "cash_small", Prize = "cash_small", Species = "", Source = "earned", At = 1, Amount = 10 },
	{ Id = "a-1-3", Rolled = "invite", Prize = "invite", Species = "heliothorn", Source = "earned", At = 1 },
	{ Id = "a-1-4", Rolled = "invite", Prize = "invite", Species = "nubkin", Source = "earned", At = 1 },
	{ Id = "a-1-5", Rolled = "invite", Prize = "cash_jackpot", Species = "", Source = "earned", At = 1 },
} })
local rows = saved.WheelPending
check(#rows == 4 and rows[1].Amount == 3000000 and rows[2].Amount == B.cash_small.amount
		and rows[3].Species == "heliothorn" and rows[4].Prize == "cash_jackpot",
	"a saved row keeps its rolled amount (never under the floor), an invite row its own plant (never another species), "
		.. "and an invite swap is a valid row", #rows)
local old = ProfileSchema.Sanitise({ Version = GameConfig.Save.CurrentVersion, InviteGranted = 2 })
check(#old.InviteOwned == 2 and old.InviteOwned[1] == FORMS[1] and old.InviteOwned[2] == FORMS[2]
		and #old.InviteReturnIds == 0,
	"an old save owns the plants its milestones gave, and has paid for no returning friend")

end)
if not ok then
	fail += 1
	say("  FAIL  THREW: " .. tostring(err))
end

say(string.format("\nWheelScaleSpec: %d passed, %d failed", pass, fail))
return table.concat(out, "\n")
